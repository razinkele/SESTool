# test-ai-isa-assistant-module.R
# Unit tests for modules/ai_isa_assistant_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/ai_isa_assistant_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("ai_isa_assistant_ui function exists", {
  skip_if_not(exists("ai_isa_assistant_ui", mode = "function"),
              "ai_isa_assistant_ui not available")
  expect_true(is.function(ai_isa_assistant_ui))
})

test_that("ai_isa_assistant_ui returns valid shiny tags", {
  skip_if_not(exists("ai_isa_assistant_ui", mode = "function"),
              "ai_isa_assistant_ui not available")
  params <- names(formals(ai_isa_assistant_ui))
  ui <- if ("i18n" %in% params) ai_isa_assistant_ui("test_aiisa", i18n) else ai_isa_assistant_ui("test_aiisa")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "ai_isa_assistant_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("ai_isa_assistant_server function exists", {
  skip_if_not(exists("ai_isa_assistant_server", mode = "function"),
              "ai_isa_assistant_server not available")
  expect_true(is.function(ai_isa_assistant_server))
})

test_that("ai_isa_assistant_server signature includes all required params", {
  skip_if_not(exists("ai_isa_assistant_server", mode = "function"),
              "ai_isa_assistant_server not available")
  params <- names(formals(ai_isa_assistant_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus", "autosave_enabled_reactive", "user_level_reactive", "parent_session", "beginner_max_elements_reactive")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("ai_isa_assistant_server event_bus defaults to NULL", {
  skip_if_not(exists("ai_isa_assistant_server", mode = "function"),
              "ai_isa_assistant_server not available")
  default <- formals(ai_isa_assistant_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

test_that("ai_isa_assistant_server optional params default to NULL", {
  skip_if_not(exists("ai_isa_assistant_server", mode = "function"),
              "ai_isa_assistant_server not available")
  fmls <- formals(ai_isa_assistant_server)
    if ("autosave_enabled_reactive" %in% names(fmls)) {
      default <- fmls[["autosave_enabled_reactive"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("autosave_enabled_reactive should default to NULL for optional use"))
    }
    if ("user_level_reactive" %in% names(fmls)) {
      default <- fmls[["user_level_reactive"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("user_level_reactive should default to NULL for optional use"))
    }
    if ("parent_session" %in% names(fmls)) {
      default <- fmls[["parent_session"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("parent_session should default to NULL for optional use"))
    }
    if ("beginner_max_elements_reactive" %in% names(fmls)) {
      default <- fmls[["beginner_max_elements_reactive"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("beginner_max_elements_reactive should default to NULL for optional use"))
    }
})
