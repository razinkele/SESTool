# test-scenario-builder-module.R
# Unit tests for modules/scenario_builder_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/scenario_builder_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("scenario_builder_ui function exists", {
  skip_if_not(exists("scenario_builder_ui", mode = "function"),
              "scenario_builder_ui not available")
  expect_true(is.function(scenario_builder_ui))
})

test_that("scenario_builder_ui returns valid shiny tags", {
  skip_if_not(exists("scenario_builder_ui", mode = "function"),
              "scenario_builder_ui not available")
  params <- names(formals(scenario_builder_ui))
  ui <- if ("i18n" %in% params) scenario_builder_ui("test_sb", i18n) else scenario_builder_ui("test_sb")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "scenario_builder_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("scenario_builder_server function exists", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  expect_true(is.function(scenario_builder_server))
})

test_that("scenario_builder_server signature includes all required params", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  params <- names(formals(scenario_builder_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("scenario_builder_server event_bus defaults to NULL", {
  skip_if_not(exists("scenario_builder_server", mode = "function"),
              "scenario_builder_server not available")
  default <- formals(scenario_builder_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
