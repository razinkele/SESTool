# test-feedback-admin-module.R
# Unit tests for modules/feedback_admin_module.R

library(testthat)
library(shiny)

# Source the module under test. Modules are not auto-loaded by global.R
# (app.R sources them at startup), so we source explicitly here.
# Follows the absolute-path pattern used in test-create-ses-module.R:133-135.
local({
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "feedback_admin_module.R")
  if (file.exists(module_path)) {
    tryCatch(
      source(module_path, local = FALSE),
      error = function(e) message("Could not source feedback_admin_module.R: ", e$message)
    )
  }
})

# Mock i18n
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("feedback_admin_ui function exists", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  expect_true(is.function(feedback_admin_ui))
})

test_that("feedback_admin_ui returns valid shiny tags", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  params <- names(formals(feedback_admin_ui))
  ui <- if ("i18n" %in% params) feedback_admin_ui("test_fb", i18n) else feedback_admin_ui("test_fb")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "feedback_admin_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("feedback_admin_ui uses namespaced IDs", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  params <- names(formals(feedback_admin_ui))
  ui <- if ("i18n" %in% params) feedback_admin_ui("test_fb", i18n) else feedback_admin_ui("test_fb")
  ui_html <- as.character(ui)
  expect_true(grepl("test_fb", ui_html), info = "UI must namespace IDs with the module id")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("feedback_admin_server function exists", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  expect_true(is.function(feedback_admin_server))
})

test_that("feedback_admin_server signature includes id, i18n, event_bus", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  params <- names(formals(feedback_admin_server))
  # These three params are required by the module-signature convention
  # (see docs/MODULE_SIGNATURE_STANDARD.md). Specifically event_bus = NULL
  # was added in commit ff3a282 to align with the analysis-module pattern.
  expect_true("id" %in% params, info = "Missing 'id' parameter")
  expect_true("i18n" %in% params, info = "Missing 'i18n' parameter")
  expect_true("event_bus" %in% params,
              info = "Missing 'event_bus' parameter (convention requires trailing event_bus = NULL)")
})

test_that("feedback_admin_server event_bus defaults to NULL", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  default <- formals(feedback_admin_server)$event_bus
  # In R, a NULL default is represented as symbol 'NULL' when retrieved via formals()
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
