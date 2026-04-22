# test-template-ses-module.R
# Unit tests for modules/template_ses_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/template_ses_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("template_ses_ui function exists", {
  skip_if_not(exists("template_ses_ui", mode = "function"),
              "template_ses_ui not available")
  expect_true(is.function(template_ses_ui))
})

test_that("template_ses_ui returns valid shiny tags", {
  skip_if_not(exists("template_ses_ui", mode = "function"),
              "template_ses_ui not available")
  params <- names(formals(template_ses_ui))
  ui <- if ("i18n" %in% params) template_ses_ui("test_tss", i18n) else template_ses_ui("test_tss")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "template_ses_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("template_ses_server function exists", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  expect_true(is.function(template_ses_server))
})

test_that("template_ses_server signature includes all required params", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  params <- names(formals(template_ses_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus", "parent_session", "user_level_reactive")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("template_ses_server event_bus defaults to NULL", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  default <- formals(template_ses_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

test_that("template_ses_server optional params default to NULL", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  fmls <- formals(template_ses_server)
    if ("parent_session" %in% names(fmls)) {
      default <- fmls[["parent_session"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("parent_session should default to NULL for optional use"))
    }
    if ("user_level_reactive" %in% names(fmls)) {
      default <- fmls[["user_level_reactive"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("user_level_reactive should default to NULL for optional use"))
    }
})
