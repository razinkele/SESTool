# functions/feedback_reporter.R
# User Feedback Collection and Reporting
# Purpose: Collect system context, persist feedback locally as NDJSON, and optionally
#          create GitHub Issues via the GitHub REST API for triage.
#
# Public API:
#   collect_system_context()  - snapshot of session/project state
#   save_feedback_local()     - append one NDJSON line to the feedback log
#   create_github_issue()     - POST a new issue to GitHub (requires token)
#   submit_feedback()         - orchestrate local save + optional GitHub post

# ============================================================================
# collect_system_context
# ============================================================================

#' Collect system context for a feedback payload
#'
#' @param session  Shiny session object (or NULL in tests)
#' @param input    Shiny input object (or list-like mock)
#' @param project_data  Optional reactiveValues / plain list with $data$isa_data
#' @param user_level  Character string, e.g. "beginner" / "expert" / "unknown"
#' @param language  Two-letter language code, default "en"
#' @return Named list with app_version, user_level, current_tab,
#'         browser_info, language, element_count, connection_count, timestamp
collect_system_context <- function(session     = NULL,
                                   input       = NULL,
                                   project_data = NULL,
                                   user_level  = "unknown",
                                   language    = "en") {

  # --- app_version -----------------------------------------------------------
  app_version <- tryCatch({
    ver_file <- file.path(getwd(), "VERSION")
    if (file.exists(ver_file)) trimws(readLines(ver_file, n = 1L, warn = FALSE))
    else "unknown"
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("collect_system_context app_version:", e$message), "WARN")
    "unknown"
  })

  # --- current_tab -----------------------------------------------------------
  current_tab <- tryCatch({
    val <- if (!is.null(input)) input$sidebar else NULL
    if (is.null(val) || identical(val, "")) "unknown" else as.character(val)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("collect_system_context current_tab:", e$message), "WARN")
    "unknown"
  }) %||% "unknown"

  # --- browser_info ----------------------------------------------------------
  browser_info <- tryCatch({
    val <- if (!is.null(input)) input$feedback_browser_info else NULL
    if (is.null(val) || identical(val, "")) "unknown" else as.character(val)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("collect_system_context browser_info:", e$message), "WARN")
    "unknown"
  }) %||% "unknown"

  # --- element_count / connection_count -------------------------------------
  element_count <- tryCatch({
    isa <- project_data$data$isa_data
    if (is.null(isa)) 0L
    else {
      count <- 0L
      for (cat in c("drivers", "activities", "pressures", "marine_processes",
                     "ecosystem_services", "goods_benefits", "responses")) {
        if (!is.null(isa[[cat]]) && is.data.frame(isa[[cat]])) count <- count + nrow(isa[[cat]])
      }
      count
    }
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("collect_system_context element_count:", e$message), "WARN")
    0L
  }) %||% 0L

  connection_count <- tryCatch({
    isa <- project_data$data$isa_data
    if (is.null(isa) || is.null(isa$adjacency_matrices)) 0L
    else {
      sum(sapply(isa$adjacency_matrices, function(m) {
        if (is.matrix(m)) sum(m != "" & m != "0" & !is.na(m)) else 0L
      }))
    }
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("collect_system_context connection_count:", e$message), "WARN")
    0L
  }) %||% 0L

  # --- timestamp -------------------------------------------------------------
  timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  list(
    app_version      = app_version,
    user_level       = user_level,
    current_tab      = current_tab,
    browser_info     = browser_info,
    language         = language,
    element_count    = as.integer(element_count),
    connection_count = as.integer(connection_count),
    timestamp        = timestamp
  )
}


# ============================================================================
# save_feedback_local
# ============================================================================

#' Append one feedback payload as an NDJSON line to the local log
#'
#' @param payload  Named list to serialise as JSON
#' @param path     Path to the NDJSON log file
#' @return TRUE on success, FALSE on error
save_feedback_local <- function(payload,
                                 path = "data/user_feedback_log.ndjson") {
  tryCatch({
    dir_path <- dirname(path)
    if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)

    cat(
      jsonlite::toJSON(payload, auto_unbox = TRUE),
      "\n",
      file   = path,
      append = TRUE,
      sep    = ""
    )
    TRUE
  }, error = function(e) {
    debug_log(paste("save_feedback_local failed:", e$message), "ERROR")
    FALSE
  })
}


# ============================================================================
# create_github_issue
# ============================================================================

#' POST a new issue to GitHub via the REST API
#'
#' Reads MARINESABRES_GITHUB_TOKEN from the environment. Returns NULL if the
#' token is absent or on any HTTP/network error.
#'
#' @param title   Issue title string
#' @param body    Issue body (Markdown)
#' @param labels  Character vector of label names
#' @return list(url, number) on success, NULL otherwise
create_github_issue <- function(title, body, labels = character(0)) {
  token <- Sys.getenv("MARINESABRES_GITHUB_TOKEN", unset = "")
  if (nchar(token) == 0L) {
    debug_log("create_github_issue: MARINESABRES_GITHUB_TOKEN not set", "INFO")
    return(NULL)
  }

  repo_owner <- Sys.getenv("MARINESABRES_GITHUB_OWNER", unset = "MarineSABRES")
  repo_name  <- Sys.getenv("MARINESABRES_GITHUB_REPO",  unset = "SESToolbox")
  api_url    <- paste0("https://api.github.com/repos/",
                       repo_owner, "/", repo_name, "/issues")

  payload <- list(
    title  = title,
    body   = body,
    labels = as.list(labels)
  )

  tryCatch({
    resp <- httr::POST(
      url    = api_url,
      httr::add_headers(
        Authorization = paste("Bearer", token),
        Accept        = "application/vnd.github+json"
      ),
      body   = jsonlite::toJSON(payload, auto_unbox = TRUE),
      encode = "raw",
      httr::timeout(10)
    )

    status <- httr::status_code(resp)
    if (status %in% c(200L, 201L)) {
      parsed <- httr::content(resp, as = "parsed", type = "application/json")
      list(
        url    = parsed$html_url %||% "unknown",
        number = parsed$number   %||% NA_integer_
      )
    } else {
      debug_log(paste("create_github_issue: HTTP", status), "ERROR")
      NULL
    }
  }, error = function(e) {
    debug_log(paste("create_github_issue error:", e$message), "ERROR")
    NULL
  })
}


# ============================================================================
# submit_feedback
# ============================================================================

#' Orchestrate local save and optional GitHub Issue creation
#'
#' @param title        Short summary string
#' @param description  Detailed description
#' @param type         One of "bug", "suggestion", "general"
#' @param steps        Reproduction steps (character string, may be empty)
#' @param context      Named list from collect_system_context()
#' @param log_path     Path to the local NDJSON log
#' @return list(local_success, github_success, github_url)
submit_feedback <- function(title,
                             description,
                             type      = "general",
                             steps     = "",
                             context   = list(),
                             log_path  = "data/user_feedback_log.ndjson") {

  # --- label mapping --------------------------------------------------------
  labels <- switch(type,
    bug        = c("bug", "user-reported"),
    suggestion = c("enhancement", "user-reported"),
    general    = c("feedback", "user-reported"),
    c("feedback", "user-reported")          # fallback
  )

  # --- build Markdown body --------------------------------------------------
  body_parts <- character(0)
  body_parts <- c(body_parts, paste0("## Description\n\n", description))

  if (nchar(trimws(steps)) > 0L) {
    body_parts <- c(body_parts,
                    paste0("\n\n## Steps to Reproduce\n\n", steps))
  }

  context_json <- tryCatch(
    jsonlite::toJSON(context, auto_unbox = TRUE, pretty = TRUE),
    error = function(e) "{}"
  )
  body_parts <- c(body_parts,
                  paste0("\n\n<details>\n<summary>System Context</summary>\n\n",
                         "```json\n", context_json, "\n```\n\n</details>"))

  issue_body <- paste(body_parts, collapse = "")

  # --- local payload --------------------------------------------------------
  local_payload <- c(
    list(
      title       = title,
      description = description,
      type        = type,
      steps       = steps,
      labels      = labels,
      github_url  = NA_character_
    ),
    context
  )

  # --- save locally first ---------------------------------------------------
  local_success <- save_feedback_local(local_payload, path = log_path)

  # --- attempt GitHub -------------------------------------------------------
  gh_result     <- create_github_issue(title, issue_body, labels)
  github_success <- !is.null(gh_result)
  github_url     <- if (github_success) gh_result$url else NA_character_

  # --- update local log entry with github_url if we got one ----------------
  if (github_success && local_success) {
    update_payload        <- local_payload
    update_payload$github_url <- github_url
    # Append a corrected entry; the original entry remains (acceptable for NDJSON)
    save_feedback_local(update_payload, path = log_path)
  }

  list(
    local_success  = local_success,
    github_success = github_success,
    github_url     = github_url
  )
}
