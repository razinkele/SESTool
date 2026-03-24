# tests/testthat/test-feedback-reporter.R
# Tests for functions/feedback_reporter.R

# Source feedback_reporter.R directly if not already available
# (global.R loaded by helper-00-load-functions.R normally covers this)
if (!exists("collect_system_context", mode = "function")) {
  pkg_root <- tryCatch(
    rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
    error = function(e) {
      d <- normalizePath(file.path(testthat::test_path(), "..", ".."),
                         mustWork = FALSE)
      d
    }
  )
  tryCatch(
    source(file.path(pkg_root, "functions", "feedback_reporter.R"),
           local = FALSE),
    error = function(e) NULL
  )
}

# Resolve project root for file-system tests
.pkg_root <- tryCatch(
  rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
  error = function(e) {
    normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  }
)

# ---------------------------------------------------------------------------
# Test 1: collect_system_context returns all expected fields
# ---------------------------------------------------------------------------
test_that("collect_system_context returns all expected fields", {
  skip_if_not(exists("collect_system_context", mode = "function"),
              "collect_system_context not available")

  mock_input <- list(
    sidebar              = "cld_visualization",
    feedback_browser_info = "Mozilla/5.0 (Test)"
  )

  mock_project <- list(
    data = list(
      isa_data = list(
        drivers    = data.frame(id = 1:2, name = c("d1", "d2")),
        activities = data.frame(id = 3:5, name = c("a1", "a2", "a3")),
        adjacency_matrices = list(
          m1 = matrix(c("", "+", "", "", "-", "", "", "", "+"),
                      nrow = 3, ncol = 3)
        )
      )
    )
  )

  ctx <- collect_system_context(
    session      = NULL,
    input        = mock_input,
    project_data = mock_project,
    user_level   = "beginner",
    language     = "en"
  )

  expected_fields <- c("app_version", "user_level", "current_tab",
                       "browser_info", "language",
                       "element_count", "connection_count", "timestamp")

  expect_true(is.list(ctx))
  expect_true(all(expected_fields %in% names(ctx)),
              info = paste("Missing fields:",
                           paste(setdiff(expected_fields, names(ctx)),
                                 collapse = ", ")))

  expect_equal(ctx$user_level,       "beginner")
  expect_equal(ctx$language,         "en")
  expect_equal(ctx$current_tab,      "cld_visualization")
  expect_equal(ctx$browser_info,     "Mozilla/5.0 (Test)")
  expect_equal(ctx$element_count,    5L)
  expect_equal(ctx$connection_count, 3L)

  # timestamp should look like ISO 8601 UTC
  expect_true(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$",
                    ctx$timestamp))
})

# ---------------------------------------------------------------------------
# Test 2: save_feedback_local writes valid NDJSON and returns TRUE
# ---------------------------------------------------------------------------
test_that("save_feedback_local writes valid NDJSON and returns TRUE", {
  skip_if_not(exists("save_feedback_local", mode = "function"),
              "save_feedback_local not available")

  tmp_file <- tempfile(fileext = ".ndjson")
  on.exit(unlink(tmp_file), add = TRUE)

  payload <- list(title = "Test entry", type = "bug", count = 1L)
  result  <- save_feedback_local(payload, path = tmp_file)

  expect_true(result)
  expect_true(file.exists(tmp_file))

  lines <- readLines(tmp_file, warn = FALSE)
  # Should have exactly one non-empty line
  non_empty <- lines[nzchar(trimws(lines))]
  expect_equal(length(non_empty), 1L)

  # Must be valid JSON
  parsed <- tryCatch(jsonlite::fromJSON(non_empty), error = function(e) NULL)
  expect_false(is.null(parsed),
               info = "NDJSON line should be parseable as JSON")
  expect_equal(parsed$title, "Test entry")
})

# ---------------------------------------------------------------------------
# Test 3: save_feedback_local appends without corrupting existing entries
# ---------------------------------------------------------------------------
test_that("save_feedback_local appends without corrupting existing entries", {
  skip_if_not(exists("save_feedback_local", mode = "function"),
              "save_feedback_local not available")

  tmp_file <- tempfile(fileext = ".ndjson")
  on.exit(unlink(tmp_file), add = TRUE)

  payload1 <- list(title = "First",  seq = 1L)
  payload2 <- list(title = "Second", seq = 2L)

  save_feedback_local(payload1, path = tmp_file)
  save_feedback_local(payload2, path = tmp_file)

  lines     <- readLines(tmp_file, warn = FALSE)
  non_empty <- lines[nzchar(trimws(lines))]
  expect_equal(length(non_empty), 2L)

  parsed1 <- jsonlite::fromJSON(non_empty[1])
  parsed2 <- jsonlite::fromJSON(non_empty[2])
  expect_equal(parsed1$title, "First")
  expect_equal(parsed2$title, "Second")
})

# ---------------------------------------------------------------------------
# Test 4: save_feedback_local returns FALSE on write error
# ---------------------------------------------------------------------------
test_that("save_feedback_local returns FALSE on write error", {
  skip_if_not(exists("save_feedback_local", mode = "function"),
              "save_feedback_local not available")

  # Create a real file, then use it AS a directory component so the path is
  # guaranteed to fail on every OS (file-as-dir is always an error).
  tmp_file <- tempfile(fileext = ".txt")
  writeLines("block", tmp_file)
  on.exit(unlink(tmp_file), add = TRUE)

  bad_path <- file.path(tmp_file, "subdir", "feedback.ndjson")
  result   <- save_feedback_local(list(x = 1), path = bad_path)
  expect_false(result)
})

# ---------------------------------------------------------------------------
# Test 5: create_github_issue returns NULL when token is empty
# ---------------------------------------------------------------------------
test_that("create_github_issue returns NULL when MARINESABRES_GITHUB_TOKEN is empty", {
  skip_if_not(exists("create_github_issue", mode = "function"),
              "create_github_issue not available")

  # Temporarily clear token
  old_token <- Sys.getenv("MARINESABRES_GITHUB_TOKEN", unset = "")
  Sys.setenv(MARINESABRES_GITHUB_TOKEN = "")
  on.exit(
    if (nchar(old_token) > 0) Sys.setenv(MARINESABRES_GITHUB_TOKEN = old_token)
    else Sys.unsetenv("MARINESABRES_GITHUB_TOKEN"),
    add = TRUE
  )

  result <- create_github_issue(
    title  = "Test issue",
    body   = "Test body",
    labels = c("bug")
  )
  expect_null(result)
})

# ---------------------------------------------------------------------------
# Test 6: submit_feedback falls back to local when GitHub token missing
# ---------------------------------------------------------------------------
test_that("submit_feedback falls back to local when GitHub token missing", {
  skip_if_not(exists("submit_feedback", mode = "function"),
              "submit_feedback not available")

  tmp_log <- tempfile(fileext = ".ndjson")
  on.exit(unlink(tmp_log), add = TRUE)

  old_token <- Sys.getenv("MARINESABRES_GITHUB_TOKEN", unset = "")
  Sys.setenv(MARINESABRES_GITHUB_TOKEN = "")
  on.exit(
    if (nchar(old_token) > 0) Sys.setenv(MARINESABRES_GITHUB_TOKEN = old_token)
    else Sys.unsetenv("MARINESABRES_GITHUB_TOKEN"),
    add = TRUE
  )

  result <- submit_feedback(
    title       = "Test feedback",
    description = "Something went wrong",
    type        = "bug",
    steps       = "1. Do this\n2. See error",
    context     = list(app_version = "1.10.2", user_level = "beginner"),
    log_path    = tmp_log
  )

  expect_true(is.list(result))
  expect_true(result$local_success,
              info = "local_success should be TRUE when path is writable")
  expect_false(result$github_success,
               info = "github_success should be FALSE when token is missing")
  expect_true(file.exists(tmp_log))
})

# ---------------------------------------------------------------------------
# Test 7: httr is listed in DESCRIPTION Imports
# ---------------------------------------------------------------------------
test_that("httr is listed in DESCRIPTION Imports", {
  desc_path <- file.path(.pkg_root, "DESCRIPTION")
  expect_true(file.exists(desc_path),
              info = paste("DESCRIPTION not found at", desc_path))

  desc_lines <- readLines(desc_path, warn = FALSE)
  # Grab lines in the Imports block (until next blank line or new field)
  in_imports <- FALSE
  import_lines <- character(0)
  for (line in desc_lines) {
    if (grepl("^Imports:", line)) {
      in_imports <- TRUE
      import_lines <- c(import_lines, line)
      next
    }
    if (in_imports) {
      if (grepl("^[A-Za-z]", line) && !grepl("^\\s", line)) break
      import_lines <- c(import_lines, line)
    }
  }
  imports_text <- paste(import_lines, collapse = " ")
  expect_true(grepl("\\bhttr\\b", imports_text),
              info = "httr must appear in DESCRIPTION Imports section")
})

# ---------------------------------------------------------------------------
# Test 8: feedback log file is gitignored
# ---------------------------------------------------------------------------
test_that("feedback log file is gitignored", {
  gitignore_path <- file.path(.pkg_root, ".gitignore")
  expect_true(file.exists(gitignore_path),
              info = paste(".gitignore not found at", gitignore_path))

  gitignore_lines <- readLines(gitignore_path, warn = FALSE)
  has_entry <- any(
    grepl("data/user_feedback_log\\.ndjson", gitignore_lines, fixed = FALSE) |
    grepl("data/user_feedback_log.ndjson",  gitignore_lines, fixed = TRUE)
  )
  expect_true(has_entry,
              info = "data/user_feedback_log.ndjson must be in .gitignore")
})

test_that("feedback button exists in ui_header.R", {
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  header_code <- paste(readLines(file.path(project_root, "functions/ui_header.R")), collapse = "\n")
  expect_true(grepl("show_feedback_modal", header_code),
              info = "ui_header.R must contain feedback button trigger")
  expect_true(grepl("comment-dots", header_code),
              info = "ui_header.R must use comment-dots icon for feedback")
})

test_that("setup_feedback_modal_handlers exists with correct signature", {
  skip_if_not(exists("setup_feedback_modal_handlers", mode = "function"),
              "setup_feedback_modal_handlers not available")
  params <- names(formals(setup_feedback_modal_handlers))
  expect_true("input" %in% params)
  expect_true("session" %in% params)
  expect_true("i18n" %in% params)
  expect_true("project_data" %in% params)
  expect_true("user_level" %in% params)
})

test_that("all feedback i18n keys exist in modals.json for all 9 languages", {
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  trans_path <- file.path(project_root, "translations/ui/modals.json")
  skip_if_not(file.exists(trans_path), "modals.json not found")

  trans <- jsonlite::fromJSON(trans_path, simplifyVector = FALSE)
  required_keys <- c(
    "ui.modals.feedback.button_label", "ui.modals.feedback.modal_title",
    "ui.modals.feedback.type_label", "ui.modals.feedback.type_bug",
    "ui.modals.feedback.type_suggestion", "ui.modals.feedback.type_general",
    "ui.modals.feedback.title_label", "ui.modals.feedback.title_placeholder",
    "ui.modals.feedback.description_label", "ui.modals.feedback.description_placeholder",
    "ui.modals.feedback.steps_label", "ui.modals.feedback.steps_placeholder",
    "ui.modals.feedback.context_label", "ui.modals.feedback.submit",
    "ui.modals.feedback.success_github", "ui.modals.feedback.success_local",
    "ui.modals.feedback.error_empty_title", "ui.modals.feedback.error_empty_desc",
    "ui.modals.feedback.rate_limited"
  )
  langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

  for (key in required_keys) {
    key_data <- trans$translation[[key]]
    expect_false(is.null(key_data), info = paste("Missing key:", key))
    if (!is.null(key_data)) {
      for (lang in langs) {
        expect_true(!is.null(key_data[[lang]]) && nchar(key_data[[lang]]) > 0,
                    info = paste("Missing", lang, "translation for", key))
      }
    }
  }
})

# ---------------------------------------------------------------------------
# Task 5: Hard-fail source loading test
# ---------------------------------------------------------------------------
test_that("source file loads without error", {
  project_root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = FALSE)
  expect_no_error(source(file.path(project_root, "functions/feedback_reporter.R"), local = FALSE))
})

# ---------------------------------------------------------------------------
# Task 4: Behavioral test — collect_system_context handles all NULL inputs
# ---------------------------------------------------------------------------
test_that("collect_system_context handles all NULL inputs gracefully", {
  skip_if_not(exists("collect_system_context", mode = "function"), "not available")
  ctx <- collect_system_context(session = NULL, input = NULL, project_data = NULL,
                                user_level = "unknown", language = "en")
  expect_true(is.list(ctx))
  expect_equal(ctx$element_count, 0L)
  expect_equal(ctx$connection_count, 0L)
})
