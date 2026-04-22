# test-response-module.R
# Unit tests for modules/response_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/response_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("response_measures_ui function exists", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  expect_true(is.function(response_measures_ui))
})

test_that("response_measures_ui returns valid shiny tags", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  params <- names(formals(response_measures_ui))
  ui <- if ("i18n" %in% params) response_measures_ui("test_rm", i18n) else response_measures_ui("test_rm")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "response_measures_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("response_measures_server function exists", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  expect_true(is.function(response_measures_server))
})

test_that("response_measures_server signature includes all required params", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  params <- names(formals(response_measures_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("response_measures_server event_bus defaults to NULL", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  default <- formals(response_measures_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
