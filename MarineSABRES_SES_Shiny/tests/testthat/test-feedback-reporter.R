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
        elements    = data.frame(id = 1:5),
        connections = data.frame(from = 1:3, to = 2:4)
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
