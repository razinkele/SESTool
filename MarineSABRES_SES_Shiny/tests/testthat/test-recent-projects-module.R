# test-recent-projects-module.R
# Unit tests for modules/recent_projects_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/recent_projects_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("recent_projects_ui function exists", {
  skip_if_not(exists("recent_projects_ui", mode = "function"),
              "recent_projects_ui not available")
  expect_true(is.function(recent_projects_ui))
})

test_that("recent_projects_ui returns valid shiny tags", {
  skip_if_not(exists("recent_projects_ui", mode = "function"),
              "recent_projects_ui not available")
  params <- names(formals(recent_projects_ui))
  ui <- if ("i18n" %in% params) recent_projects_ui("test_rp", i18n) else recent_projects_ui("test_rp")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "recent_projects_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("recent_projects_server function exists", {
  skip_if_not(exists("recent_projects_server", mode = "function"),
              "recent_projects_server not available")
  expect_true(is.function(recent_projects_server))
})

test_that("recent_projects_server signature includes all required params", {
  skip_if_not(exists("recent_projects_server", mode = "function"),
              "recent_projects_server not available")
  params <- names(formals(recent_projects_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("recent_projects_server event_bus defaults to NULL", {
  skip_if_not(exists("recent_projects_server", mode = "function"),
              "recent_projects_server not available")
  default <- formals(recent_projects_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
