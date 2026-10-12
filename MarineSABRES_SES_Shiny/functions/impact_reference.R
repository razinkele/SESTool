# functions/impact_reference.R
# WP5 impact-assessment reference data (spec 2026-10-11 WS-6; WS-6a).
# Read-only D5.2 reference: Macaronesia Table 21, Arctic Tables 2-8
# (data/wp5_impact_reference.json). Users copy reference cells into an
# editable assessment (functions/impact_assessment_model.R).

.impact_ref_env <- new.env(parent = emptyenv())
.impact_ref_env$db <- NULL
.impact_ref_env$loaded <- FALSE   # TRUE after any attempt, failed or not

#' Load the impact-assessment reference data (cached)
#' A failed load is cached too: the data stays "unavailable" (one warning)
#' until force_reload = TRUE, instead of re-reading the default path on
#' every getter call.
#' @return Parsed list, or NULL (with a warning) if missing/corrupt
load_impact_reference <- function(path = NULL, force_reload = FALSE) {
  if (isTRUE(.impact_ref_env$loaded) && !force_reload) return(invisible(.impact_ref_env$db))
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) {
      get_project_file("data", "wp5_impact_reference.json")
    } else {
      file.path("data", "wp5_impact_reference.json")
    }
  }
  db <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) {
    warning(sprintf("[WP5 impact] reference data not loaded (%s): %s", path, conditionMessage(e)),
            call. = FALSE)
    NULL
  })
  .impact_ref_env$db <- db
  .impact_ref_env$loaded <- TRUE
  invisible(db)
}

#' Version of the loaded reference data ("" when unavailable); stored on copied cells
impact_reference_version <- function() {
  db <- load_impact_reference()
  if (is.null(db)) return("")
  as.character(db$schema_version %||% "")
}

.impact_ref_da <- function(da) {
  if (!is.character(da) || length(da) != 1 || !da %in% WP5_DA_CONTEXTS) {
    stop("Unknown DA: ", paste(da, collapse = ","))
  }
  db <- load_impact_reference()
  if (is.null(db)) return(NULL)
  db$demonstration_areas[[da]]
}

#' Reference availability for a DA: "available", "valuation_only" or "unavailable"
impact_reference_status <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return("unavailable")
  as.character(b$status %||% "unavailable")
}

#' Reference scenarios for a DA; names come from the WS-2 mechanism KB
#' @return List of list(code, name, short_label, ambition_rank, confidence_text, confidence_codes)
impact_reference_scenarios <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(list())
  kb <- get_scenarios_for_da(da)
  kb_names <- setNames(vapply(kb, function(s) as.character(s$name %||% ""), character(1)),
                       vapply(kb, function(s) as.character(s$code %||% ""), character(1)))
  lapply(b$scenarios %||% list(), function(s) {
    code <- as.character(s$code)
    short <- as.character(s$short_label %||% code)
    nm <- if (code %in% names(kb_names)) kb_names[[code]] else ""
    list(code = code,
         name = if (nzchar(nm)) nm else short,
         short_label = short,
         ambition_rank = as.integer(s$ambition_rank %||% 0L),
         confidence_text = as.character(s$confidence_text %||% ""),
         confidence_codes = as.character(unlist(s$confidence_codes %||% list())))
  })
}

#' Baseline scenario code published for a DA ("" when none)
impact_reference_baseline <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return("")
  as.character(b$baseline_code %||% "")
}

#' One read-only reference cell, or NULL
#' @return list(criterion, scenario, rating_text, text, table, source_lines)
impact_reference_cell <- function(da, criterion, scenario_code) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(NULL)
  crit <- wp5_criterion_code(criterion)
  src <- b$cell_source %||% list()
  for (cl in b$cells %||% list()) {
    if (identical(cl$criterion, crit) && identical(cl$scenario, scenario_code)) {
      return(list(criterion = crit, scenario = scenario_code,
                  rating_text = as.character(cl$rating_text %||% ""),
                  text = as.character(cl$text %||% ""),
                  table = as.character(src$table %||% ""),
                  source_lines = as.integer(unlist(src$source_lines %||% list())),
                  provenance = as.character(b$provenance %||% "wp5_source")))
    }
  }
  NULL
}

#' Published revenue tables (Arctic) or NULL
impact_reference_revenue <- function(da) {
  b <- .impact_ref_da(da)
  if (is.null(b)) return(NULL)
  b$revenue
}
