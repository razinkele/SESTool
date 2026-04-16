# test-json-project-loading.R
# Tests for JSON project file loading and normalization
# Reproduces the "$ operator is invalid for atomic vectors" bug from
# connection_review_tabbed.R when simplifyVector = TRUE collapses connections
# into a data frame instead of a list-of-lists.

library(testthat)
library(jsonlite)

# Resolve project root and test fixture path
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

json_fixture <- file.path(
  project_root,
  "data",
  "PROJ_20260409223546_2227_20260410_012351.json"
)

# Source data_structure.R if normalize_json_project_data isn't already loaded
if (!exists("normalize_json_project_data", mode = "function")) {
  source(file.path(project_root, "functions", "data_structure.R"), local = FALSE)
}

# Ensure debug_log exists (may not be loaded outside full app bootstrap)
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = "") invisible(NULL)
}

# ============================================================================
# FIXTURE HELPERS
# ============================================================================

load_fixture_simplify_true <- function() {
  json_content <- paste(readLines(json_fixture, warn = FALSE), collapse = "\n")
  jsonlite::fromJSON(json_content, simplifyVector = TRUE)
}

load_fixture_simplify_false <- function() {
  json_content <- paste(readLines(json_fixture, warn = FALSE), collapse = "\n")
  jsonlite::fromJSON(json_content, simplifyVector = FALSE)
}


# ============================================================================
# TEST: RAW JSON PARSING (demonstrates the bug)
# ============================================================================

context("JSON project loading - raw parsing")

test_that("fixture file exists", {
  skip_if_not(file.exists(json_fixture), "Test fixture JSON not found in data/")
  expect_true(file.exists(json_fixture))
})

test_that("simplifyVector = TRUE turns connections into a data frame", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  suggested <- raw$data$isa_data$connections$suggested

  # This is the root cause of the bug: jsonlite simplifies
  # an array of uniform objects into a data frame

  expect_true(is.data.frame(suggested))
  expect_gt(nrow(suggested), 0)

  # Extracting a row gives a named vector, NOT a list
  first_row <- suggested[1, ]
  # $ works on a 1-row data frame, but [[i]] on the parent list would give

  # a character vector — demonstrate the problem that seq_along + [[ hits:
  first_elem <- suggested[1, , drop = TRUE]
  expect_true(is.atomic(first_elem) || is.data.frame(suggested[1, ]))
})

test_that("simplifyVector = FALSE keeps connections as list-of-lists", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_false()
  suggested <- raw$data$isa_data$connections$suggested

  expect_true(is.list(suggested))
  expect_false(is.data.frame(suggested))

  # Each element is a list — $ works
  first <- suggested[[1]]
  expect_type(first, "list")
  expect_true(!is.null(first$from_type))
})


# ============================================================================
# TEST: normalize_json_project_data fixes connections
# ============================================================================

context("JSON project loading - normalize_json_project_data")

test_that("normalize converts connection data frames to list-of-lists", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  # Confirm connections are a data frame before normalization
  expect_true(is.data.frame(raw$data$isa_data$connections$suggested))

  normalized <- normalize_json_project_data(raw)
  suggested <- normalized$data$isa_data$connections$suggested

  # After normalization, should be a list, not a data frame
  expect_true(is.list(suggested))
  expect_false(is.data.frame(suggested))
  expect_gt(length(suggested), 0)
})

test_that("each normalized connection is a list accessible with $", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  normalized <- normalize_json_project_data(raw)
  conns <- normalized$data$isa_data$connections$suggested

  for (i in seq_along(conns)) {
    conn <- conns[[i]]
    expect_type(conn, "list")

    # The exact operation that was failing in connection_review_tabbed.R:197
    expect_no_error(conn$from_type)
    expect_no_error(conn$to_type)
    expect_no_error(conn$polarity)
  }
})

test_that("normalized connection field values are scalars, not length-1 columns", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  normalized <- normalize_json_project_data(raw)
  conn <- normalized$data$isa_data$connections$suggested[[1]]

  # String fields should be plain character(1)
  expect_true(is.character(conn$from_type))
  expect_equal(length(conn$from_type), 1)

  expect_true(is.character(conn$to_type))
  expect_equal(length(conn$to_type), 1)

  expect_true(is.character(conn$polarity))
  expect_equal(length(conn$polarity), 1)

  # Numeric fields should be plain numeric(1)
  expect_true(is.numeric(conn$from_index))
  expect_equal(length(conn$from_index), 1)

  expect_true(is.numeric(conn$confidence))
  expect_equal(length(conn$confidence), 1)
})

test_that("normalized connections preserve all original fields", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  original_cols <- names(raw$data$isa_data$connections$suggested)

  normalized <- normalize_json_project_data(raw)
  conn <- normalized$data$isa_data$connections$suggested[[1]]

  for (field in original_cols) {
    expect_true(
      field %in% names(conn),
      info = paste("Missing field after normalization:", field)
    )
  }
})

test_that("normalized connections preserve row count", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  n_original <- nrow(raw$data$isa_data$connections$suggested)

  normalized <- normalize_json_project_data(raw)
  n_normalized <- length(normalized$data$isa_data$connections$suggested)

  expect_equal(n_normalized, n_original)
})


# ============================================================================
# TEST: element data frames are normalized correctly
# ============================================================================

context("JSON project loading - element normalization")

test_that("element data frames get lowercase column names", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  # Raw JSON has uppercase: ID, Name, Type
  expect_true("ID" %in% names(raw$data$isa_data$drivers))

  normalized <- normalize_json_project_data(raw)
  drivers <- normalized$data$isa_data$drivers

  expect_true(is.data.frame(drivers))
  expect_true("id" %in% names(drivers))
  expect_true("name" %in% names(drivers))
  # No uppercase leftovers
  expect_false("ID" %in% names(drivers))
  expect_false("Name" %in% names(drivers))
})

test_that("all element types are data frames after normalization", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  normalized <- normalize_json_project_data(raw)
  isa <- normalized$data$isa_data

  element_types <- c("drivers", "activities", "pressures", "marine_processes",
                     "ecosystem_services", "goods_benefits", "responses")

  for (etype in element_types) {
    if (!is.null(isa[[etype]])) {
      expect_true(
        is.data.frame(isa[[etype]]),
        info = paste(etype, "should be a data frame")
      )
    }
  }
})


# ============================================================================
# TEST: normalize is idempotent and handles edge cases
# ============================================================================

context("JSON project loading - edge cases")

test_that("normalize is idempotent (double-normalize is safe)", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_true()
  once <- normalize_json_project_data(raw)
  twice <- normalize_json_project_data(once)

  conns_once <- once$data$isa_data$connections$suggested
  conns_twice <- twice$data$isa_data$connections$suggested

  expect_equal(length(conns_once), length(conns_twice))

  # Each connection should still be a list
  for (i in seq_along(conns_twice)) {
    expect_type(conns_twice[[i]], "list")
    expect_no_error(conns_twice[[i]]$from_type)
  }
})

test_that("normalize handles project with no connections", {
  project <- list(
    project_id = "TEST001",
    project_name = "Empty Test",
    data = list(
      isa_data = list(
        drivers = data.frame(ID = "D1", Name = "Test", stringsAsFactors = FALSE),
        connections = list(suggested = list(), approved = list())
      )
    )
  )

  result <- normalize_json_project_data(project)
  expect_type(result, "list")
  expect_equal(length(result$data$isa_data$connections$suggested), 0)
})

test_that("normalize handles project with NULL connections", {
  project <- list(
    project_id = "TEST002",
    project_name = "Null Conns Test",
    data = list(
      isa_data = list(
        drivers = data.frame(ID = "D1", Name = "Test", stringsAsFactors = FALSE),
        connections = NULL
      )
    )
  )

  result <- normalize_json_project_data(project)
  expect_type(result, "list")
  expect_null(result$data$isa_data$connections)
})

test_that("normalize handles non-list input gracefully", {
  expect_null(normalize_json_project_data("not a list"))
  expect_null(normalize_json_project_data(42))
  expect_null(normalize_json_project_data(NULL))
})

test_that("normalize handles simplifyVector = FALSE input (already list-of-lists)", {
  skip_if_not(file.exists(json_fixture))

  raw <- load_fixture_simplify_false()
  normalized <- normalize_json_project_data(raw)
  conns <- normalized$data$isa_data$connections$suggested

  expect_true(is.list(conns))
  expect_false(is.data.frame(conns))

  # $ access should work
  first <- conns[[1]]
  expect_type(first, "list")
  expect_no_error(first$from_type)
})


# ============================================================================
# TEST: full pipeline simulation (mimics project_io.R)
# ============================================================================

context("JSON project loading - full pipeline")

test_that("full load pipeline produces valid connections for connection_review", {
  skip_if_not(file.exists(json_fixture))

  # Simulate exactly what project_io.R does
  json_content <- paste(readLines(json_fixture, warn = FALSE), collapse = "\n")
  parsed <- jsonlite::fromJSON(json_content, simplifyVector = TRUE)
  loaded_data <- normalize_json_project_data(parsed)

  conns <- loaded_data$data$isa_data$connections$suggested

  # Simulate what connection_review_tabbed.R does at line 496-497
  for (i in seq_along(conns)) {
    conn <- conns[[i]]
    # These are the exact operations that were crashing
    expect_no_error({
      from_type <- tolower(trimws(conn$from_type %||% ""))
      to_type <- tolower(trimws(conn$to_type %||% ""))
      polarity <- conn$polarity %||% "+"
      strength <- conn$strength %||% "medium"
    })

    expect_true(nchar(from_type) > 0, info = paste("Connection", i, "has empty from_type"))
    expect_true(nchar(to_type) > 0, info = paste("Connection", i, "has empty to_type"))
  }
})
