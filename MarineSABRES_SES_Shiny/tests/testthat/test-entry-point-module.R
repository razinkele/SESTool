# test-entry-point-module.R
# Unit tests for modules/entry_point_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# helper-stubs.R defines a minimal entry_point_server stub with outdated
# 3-arg signature; we source the real module AFTER helper load to override.
# Using sys.source() with explicit .GlobalEnv because source(local=FALSE)
# inside a test file has shown unreliable .GlobalEnv binding in testthat 3.
source_for_test("modules/entry_point_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("entry_point_ui function exists", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  expect_true(is.function(entry_point_ui))
})

test_that("entry_point_ui returns valid shiny tags", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  params <- names(formals(entry_point_ui))
  ui <- if ("i18n" %in% params) entry_point_ui("test_ep", i18n) else entry_point_ui("test_ep")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "entry_point_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("entry_point_ui uses namespaced IDs", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  params <- names(formals(entry_point_ui))
  ui <- if ("i18n" %in% params) entry_point_ui("test_ep", i18n) else entry_point_ui("test_ep")
  ui_html <- as.character(ui)
  expect_true(grepl("test_ep", ui_html), info = "UI must namespace IDs")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("entry_point_server function exists", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  expect_true(is.function(entry_point_server))
})

test_that("entry_point_server signature includes all required params", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  params <- names(formals(entry_point_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("entry_point_server event_bus defaults to NULL", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  default <- formals(entry_point_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL")
})

test_that("entry_point_server parent_session and user_level_reactive default to NULL", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  fmls <- formals(entry_point_server)
  for (p in c("parent_session", "user_level_reactive")) {
    if (p %in% names(fmls)) {
      default <- fmls[[p]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0(p, " should default to NULL for optional use"))
    }
  }
})
