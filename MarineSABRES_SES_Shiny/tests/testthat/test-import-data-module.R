# test-import-data-module.R
# Unit tests for modules/import_data_module.R

library(testthat)
library(shiny)

# Source the module file to make its functions available
local({
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "import_data_module.R")
  if (file.exists(module_path)) {
    tryCatch(source(module_path, local = FALSE), error = function(e) {
      message("Could not source import_data_module.R: ", e$message)
    })
  }
})

# Mock i18n
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("import_data_ui function exists", {
  skip_if_not(exists("import_data_ui", mode = "function"),
              "import_data_ui not available")
  expect_true(is.function(import_data_ui))
})

test_that("import_data_ui returns valid shiny tags", {
  skip_if_not(exists("import_data_ui", mode = "function"),
              "import_data_ui not available")

  ui <- import_data_ui("test_import", i18n)

  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "import_data_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("import_data_ui uses namespaced IDs", {
  skip_if_not(exists("import_data_ui", mode = "function"),
              "import_data_ui not available")

  ui <- import_data_ui("test_import", i18n)
  ui_html <- as.character(ui)

  # Should contain namespaced file input

  expect_true(grepl("test_import", ui_html),
              info = "UI should contain namespaced IDs")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("import_data_server function exists", {
  skip_if_not(exists("import_data_server", mode = "function"),
              "import_data_server not available")
  expect_true(is.function(import_data_server))
})

# ============================================================================
# HELPER FUNCTION TESTS: validate_import_data
# ============================================================================

test_that("validate_import_data function exists", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")
  expect_true(is.function(validate_import_data))
})

test_that("validate_import_data detects empty elements", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = character(), type = character(),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("empty", errors, ignore.case = TRUE)))
})

test_that("validate_import_data detects NULL elements", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  errors <- validate_import_data(NULL, data.frame(From = "A", To = "B", Label = "+"))
  expect_true(length(errors) > 0)
})

test_that("validate_import_data detects missing Label column", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Name = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("Label", errors)))
})

test_that("validate_import_data detects missing type column", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), category = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("type", errors, ignore.case = TRUE)))
})

test_that("validate_import_data detects empty connections", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = character(), To = character(),
                            Label = character(), stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("empty", errors, ignore.case = TRUE)))
})

test_that("validate_import_data detects missing connection columns", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(Source = "A", Target = "B",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("missing", errors, ignore.case = TRUE)))
})

test_that("validate_import_data detects orphan connection nodes", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = c("A", "C"), To = c("B", "D"),
                            Label = c("+", "-"), stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_true(length(errors) > 0)
  expect_true(any(grepl("not found", errors, ignore.case = TRUE)))
})

test_that("validate_import_data returns NULL for valid data", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_null(errors)
})

test_that("validate_import_data handles type...2 column variant", {
  skip_if_not(exists("validate_import_data", mode = "function"),
              "validate_import_data not available")

  elements <- data.frame(Label = c("A", "B"), `type...2` = c("Driver", "Activity"),
                         stringsAsFactors = FALSE, check.names = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  errors <- validate_import_data(elements, connections)
  expect_null(errors)
})

# ============================================================================
# HELPER FUNCTION TESTS: parse_connections_for_review
# ============================================================================

test_that("parse_connections_for_review function exists", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")
  expect_true(is.function(parse_connections_for_review))
})

test_that("parse_connections_for_review returns correct structure", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  result <- parse_connections_for_review(elements, connections)

  expect_true(is.list(result))
  expect_equal(length(result), 1)

  conn <- result[[1]]
  expect_equal(conn$from_name, "A")
  expect_equal(conn$to_name, "B")
  expect_equal(conn$polarity, "+")
  expect_equal(conn$strength, "medium")  # default
  expect_equal(conn$confidence, 3)       # default
})

test_that("parse_connections_for_review handles Strength column", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            Strength = "Strong", stringsAsFactors = FALSE)

  result <- parse_connections_for_review(elements, connections)
  expect_equal(result[[1]]$strength, "strong")
})

test_that("parse_connections_for_review handles Confidence column", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")

  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "-",
                            Confidence = 5, stringsAsFactors = FALSE)

  result <- parse_connections_for_review(elements, connections)
  expect_equal(result[[1]]$confidence, 5L)
})

test_that("parse_connections_for_review handles multiple connections", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")

  elements <- data.frame(Label = c("A", "B", "C"),
                         type = c("Driver", "Activity", "Pressure"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = c("A", "B"), To = c("B", "C"),
                            Label = c("+", "-"), stringsAsFactors = FALSE)

  result <- parse_connections_for_review(elements, connections)
  expect_equal(length(result), 2)
  expect_equal(result[[1]]$from_name, "A")
  expect_equal(result[[2]]$from_name, "B")
})

test_that("parse_connections_for_review includes rationale with types", {
  skip_if_not(exists("parse_connections_for_review", mode = "function"),
              "parse_connections_for_review not available")

  elements <- data.frame(Label = c("A", "B"),
                         type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", Label = "+",
                            stringsAsFactors = FALSE)

  result <- parse_connections_for_review(elements, connections)
  expect_true(grepl("Driver", result[[1]]$rationale))
  expect_true(grepl("Activity", result[[1]]$rationale))
})
