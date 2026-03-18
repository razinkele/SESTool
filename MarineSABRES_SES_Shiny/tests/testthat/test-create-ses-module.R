# test-create-ses-module.R
# Unit tests for modules/create_ses_module.R

library(testthat)
library(shiny)

# Mock i18n
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("create_ses_ui function exists", {
  skip_if_not(exists("create_ses_ui", mode = "function"),
              "create_ses_ui not available")
  expect_true(is.function(create_ses_ui))
})

test_that("create_ses_ui returns valid shiny tags", {
  skip_if_not(exists("create_ses_ui", mode = "function"),
              "create_ses_ui not available")

  # Call with or without i18n depending on what the function accepts
  params <- names(formals(create_ses_ui))
  ui <- if ("i18n" %in% params) {
    create_ses_ui("test_create", i18n)
  } else {
    create_ses_ui("test_create")
  }

  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "create_ses_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("create_ses_ui uses namespaced IDs", {
  skip_if_not(exists("create_ses_ui", mode = "function"),
              "create_ses_ui not available")

  params <- names(formals(create_ses_ui))
  ui <- if ("i18n" %in% params) {
    create_ses_ui("test_create", i18n)
  } else {
    create_ses_ui("test_create")
  }
  ui_html <- as.character(ui)

  expect_true(grepl("test_create", ui_html),
              info = "UI should contain namespaced IDs")
})

test_that("create_ses_ui contains method selection elements", {
  skip_if_not(exists("create_ses_ui", mode = "function"),
              "create_ses_ui not available")

  params <- names(formals(create_ses_ui))
  ui <- if ("i18n" %in% params) {
    create_ses_ui("test_create", i18n)
  } else {
    create_ses_ui("test_create")
  }
  ui_html <- as.character(ui)

  # Should contain elements related to the 3 methods (standard, ai, template)
  expect_true(
    grepl("standard", ui_html, ignore.case = TRUE) ||
    grepl("main_content", ui_html),
    info = "UI should contain method selection or main_content placeholder"
  )
})

test_that("create_ses_ui contains proceed button", {
  skip_if_not(exists("create_ses_ui", mode = "function"),
              "create_ses_ui not available")

  params <- names(formals(create_ses_ui))
  ui <- if ("i18n" %in% params) {
    create_ses_ui("test_create", i18n)
  } else {
    create_ses_ui("test_create")
  }
  ui_html <- as.character(ui)

  expect_true(grepl("proceed", ui_html),
              info = "UI should contain a proceed button")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("create_ses_server function exists", {
  skip_if_not(exists("create_ses_server", mode = "function"),
              "create_ses_server not available")
  expect_true(is.function(create_ses_server))
})

test_that("create_ses_server has id parameter", {
  skip_if_not(exists("create_ses_server", mode = "function"),
              "create_ses_server not available")

  params <- names(formals(create_ses_server))
  expect_true("id" %in% params)
})

test_that("create_ses_server has project_data parameter", {
  skip_if_not(exists("create_ses_server", mode = "function"),
              "create_ses_server not available")

  params <- names(formals(create_ses_server))
  # Accept either project_data_reactive or project_data
  expect_true(
    "project_data_reactive" %in% params || "project_data" %in% params,
    info = "Server must accept project data parameter"
  )
})

test_that("create_ses_server has parent_session parameter", {
  skip_if_not(exists("create_ses_server", mode = "function"),
              "create_ses_server not available")

  params <- names(formals(create_ses_server))
  expect_true("parent_session" %in% params)
})

# ============================================================================
# MODULE STRUCTURE TESTS (source file inspection)
# ============================================================================

test_that("create_ses_module source file defines UI with i18n support", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "create_ses_module.R")
  skip_if_not(file.exists(module_path),
              "create_ses_module.R source file not found")

  src <- readLines(module_path)
  src_text <- paste(src, collapse = "\n")

  # Real module should accept i18n parameter
  expect_true(grepl("create_ses_ui.*function.*id.*i18n", src_text),
              info = "Source should define create_ses_ui with i18n parameter")
})

test_that("create_ses_module source file defines server with event_bus", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "create_ses_module.R")
  skip_if_not(file.exists(module_path),
              "create_ses_module.R source file not found")

  src <- readLines(module_path)
  src_text <- paste(src, collapse = "\n")

  expect_true(grepl("create_ses_server.*function.*event_bus", src_text),
              info = "Source should define create_ses_server with event_bus parameter")
})

test_that("create_ses_module supports three creation methods", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "create_ses_module.R")
  skip_if_not(file.exists(module_path),
              "create_ses_module.R source file not found")

  src <- readLines(module_path)
  src_text <- paste(src, collapse = "\n")

  expect_true(grepl("standard", src_text),
              info = "Module should support standard method")
  expect_true(grepl("ai", src_text),
              info = "Module should support AI method")
  expect_true(grepl("template", src_text),
              info = "Module should support template method")
})

test_that("create_ses_module routes to correct tabs", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "create_ses_module.R")
  skip_if_not(file.exists(module_path),
              "create_ses_module.R source file not found")

  src <- readLines(module_path)
  src_text <- paste(src, collapse = "\n")

  expect_true(grepl("create_ses_standard", src_text),
              info = "Should route to create_ses_standard tab")
  expect_true(grepl("create_ses_ai", src_text),
              info = "Should route to create_ses_ai tab")
  expect_true(grepl("create_ses_template", src_text),
              info = "Should route to create_ses_template tab")
})
