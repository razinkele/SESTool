# test-prepare-report-module.R
# Unit tests for modules/prepare_report_module.R

library(testthat)
library(shiny)

# Source the module file to make its functions available
source_for_test("modules/prepare_report_module.R")
# Mock i18n
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("prepare_report_ui function exists", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")
  expect_true(is.function(prepare_report_ui))
})

test_that("prepare_report_ui returns valid shiny tags", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")

  ui <- prepare_report_ui("test_report", i18n)

  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "prepare_report_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("prepare_report_ui uses namespaced IDs", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")

  ui <- prepare_report_ui("test_report", i18n)
  ui_html <- as.character(ui)

  expect_true(grepl("test_report", ui_html),
              info = "UI should contain namespaced IDs")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("prepare_report_server function exists", {
  skip_if_not(exists("prepare_report_server", mode = "function"),
              "prepare_report_server not available")
  expect_true(is.function(prepare_report_server))
})

test_that("prepare_report_server has correct parameters", {
  skip_if_not(exists("prepare_report_server", mode = "function"),
              "prepare_report_server not available")

  params <- names(formals(prepare_report_server))
  expect_true("id" %in% params)
  expect_true("project_data_reactive" %in% params)
  expect_true("i18n" %in% params)
})

# ============================================================================
# HELPER FUNCTION TESTS: generate_html_report
# ============================================================================

test_that("generate_html_report function exists", {
  skip_if_not(exists("generate_html_report", mode = "function"),
              "generate_html_report not available")
  expect_true(is.function(generate_html_report))
})

test_that("generate_html_report produces valid HTML", {
  skip_if_not(exists("generate_html_report", mode = "function"),
              "generate_html_report not available")

  data <- list(
    data = list(
      metadata = list(project_name = "Test Project"),
      isa_data = list(
        drivers = data.frame(name = "D1", stringsAsFactors = FALSE),
        activities = data.frame(name = "A1", stringsAsFactors = FALSE),
        pressures = NULL,
        marine_processes = NULL,
        ecosystem_services = NULL,
        goods_benefits = NULL,
        responses = NULL
      ),
      cld = list(nodes = data.frame(), edges = data.frame()),
      analysis = list(loops = NULL, metrics = NULL)
    )
  )

  result <- generate_html_report(data, "Test Report", "Test Author", c("summary"))

  expect_true(is.character(result))
  expect_true(any(grepl("<!DOCTYPE html>", result)))
  expect_true(any(grepl("Test Report", result)))
  expect_true(any(grepl("Test Author", result)))
})

test_that("generate_html_report handles NULL author", {
  skip_if_not(exists("generate_html_report", mode = "function"),
              "generate_html_report not available")

  data <- list(
    data = list(
      metadata = list(project_name = "Test"),
      isa_data = list(),
      cld = list(nodes = data.frame(), edges = data.frame()),
      analysis = list(loops = NULL, metrics = NULL)
    )
  )

  result <- generate_html_report(data, "Test Report", NULL, c("summary"))

  expect_true(is.character(result))
  expect_true(any(grepl("Test Report", result)))
})

test_that("generate_html_report handles empty sections", {
  skip_if_not(exists("generate_html_report", mode = "function"),
              "generate_html_report not available")

  data <- list(
    data = list(
      metadata = list(project_name = "Test"),
      isa_data = list(),
      cld = list(nodes = data.frame(), edges = data.frame()),
      analysis = list(loops = NULL, metrics = NULL)
    )
  )

  result <- generate_html_report(data, "Test Report", "Author", character(0))

  expect_true(is.character(result))
  expect_true(any(grepl("<!DOCTYPE html>", result)))
})

# ============================================================================
# HELPER FUNCTION TESTS: generate_word_report
# ============================================================================

test_that("generate_word_report function exists", {
  skip_if_not(exists("generate_word_report", mode = "function"),
              "generate_word_report not available")
  expect_true(is.function(generate_word_report))
})

test_that("generate_word_report has correct parameters", {
  skip_if_not(exists("generate_word_report", mode = "function"),
              "generate_word_report not available")

  params <- names(formals(generate_word_report))
  expect_true("data" %in% params)
  expect_true("title" %in% params)
  expect_true("author" %in% params)
  expect_true("sections" %in% params)
  expect_true("output_file" %in% params)
})

# ============================================================================
# HELPER FUNCTION TESTS: generate_ppt_report
# ============================================================================

test_that("generate_ppt_report function exists", {
  skip_if_not(exists("generate_ppt_report", mode = "function"),
              "generate_ppt_report not available")
  expect_true(is.function(generate_ppt_report))
})

test_that("generate_ppt_report has correct parameters", {
  skip_if_not(exists("generate_ppt_report", mode = "function"),
              "generate_ppt_report not available")

  params <- names(formals(generate_ppt_report))
  expect_true("data" %in% params)
  expect_true("title" %in% params)
  expect_true("author" %in% params)
  expect_true("sections" %in% params)
  expect_true("output_file" %in% params)
})
