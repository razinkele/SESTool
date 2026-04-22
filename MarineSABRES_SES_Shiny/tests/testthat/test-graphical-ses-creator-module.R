# test-graphical-ses-creator-module.R
# Unit tests for modules/graphical_ses_creator_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/graphical_ses_creator_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("graphical_ses_creator_ui function exists", {
  skip_if_not(exists("graphical_ses_creator_ui", mode = "function"),
              "graphical_ses_creator_ui not available")
  expect_true(is.function(graphical_ses_creator_ui))
})

test_that("graphical_ses_creator_ui returns valid shiny tags", {
  skip_if_not(exists("graphical_ses_creator_ui", mode = "function"),
              "graphical_ses_creator_ui not available")
  params <- names(formals(graphical_ses_creator_ui))
  ui <- if ("i18n" %in% params) graphical_ses_creator_ui("test_gsc", i18n) else graphical_ses_creator_ui("test_gsc")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "graphical_ses_creator_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("graphical_ses_creator_server function exists", {
  skip_if_not(exists("graphical_ses_creator_server", mode = "function"),
              "graphical_ses_creator_server not available")
  expect_true(is.function(graphical_ses_creator_server))
})

test_that("graphical_ses_creator_server signature includes all required params", {
  skip_if_not(exists("graphical_ses_creator_server", mode = "function"),
              "graphical_ses_creator_server not available")
  params <- names(formals(graphical_ses_creator_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus", "parent_session")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("graphical_ses_creator_server event_bus defaults to NULL", {
  skip_if_not(exists("graphical_ses_creator_server", mode = "function"),
              "graphical_ses_creator_server not available")
  default <- formals(graphical_ses_creator_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

test_that("graphical_ses_creator_server optional params default to NULL", {
  skip_if_not(exists("graphical_ses_creator_server", mode = "function"),
              "graphical_ses_creator_server not available")
  fmls <- formals(graphical_ses_creator_server)
    if ("parent_session" %in% names(fmls)) {
      default <- fmls[["parent_session"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("parent_session should default to NULL for optional use"))
    }
})
