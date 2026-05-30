# test-pilot-study-module.R
# Unit + behavior tests for modules/pilot_study_module.R
#
# pilot_study_module had NO test (the lone uncovered modules/*_module.R file —
# a v1.15.0 addition). This adds the UI/signature contract checks plus behavior
# tests that drive the real server via testServer().

library(testthat)
library(shiny)

# Source the module (modules/ are not auto-loaded by global.R).
source_for_test("modules/pilot_study_module.R")
i18n <- list(t = function(key) key)

# Re-bind the real server over any helper-stubs.R stub, which shadows the
# .GlobalEnv copy in testthat's helper env (see feedback_testserver_stub_shadowing).
if (exists("pilot_study_server", envir = .GlobalEnv)) {
  pilot_study_server <- get("pilot_study_server", envir = .GlobalEnv)
}

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("pilot_study_ui function exists", {
  skip_if_not(exists("pilot_study_ui", mode = "function"),
              "pilot_study_ui not available")
  expect_true(is.function(pilot_study_ui))
})

test_that("pilot_study_ui returns valid shiny tags and namespaces the id", {
  skip_if_not(exists("pilot_study_ui", mode = "function"),
              "pilot_study_ui not available")
  params <- names(formals(pilot_study_ui))
  ui <- if ("i18n" %in% params) pilot_study_ui("test_pilot", i18n) else pilot_study_ui("test_pilot")
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("test_pilot", as.character(ui)),
              info = "UI must namespace IDs with the module id")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("pilot_study_server function exists", {
  skip_if_not(exists("pilot_study_server", mode = "function"),
              "pilot_study_server not available")
  expect_true(is.function(pilot_study_server))
})

test_that("pilot_study_server signature includes the required params", {
  skip_if_not(exists("pilot_study_server", mode = "function"),
              "pilot_study_server not available")
  params <- names(formals(pilot_study_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("pilot_study_server event_bus defaults to NULL", {
  skip_if_not(exists("pilot_study_server", mode = "function"),
              "pilot_study_server not available")
  default <- formals(pilot_study_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

# ============================================================================
# SERVER BEHAVIOR TESTS
# Without a ?pilot_condition=A|B URL param the module stays inactive (the
# default in testServer, where url_search is empty). These drive the real
# returned interface + outputs, so they FAIL if the server body is NULL.
# ============================================================================

test_that("module is inactive by default and exposes the is_active + trigger interface", {
  testServer(pilot_study_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$flushReact()
    ret <- session$getReturned()
    expect_true(is.list(ret))
    expect_true(all(c("is_active", "trigger_end_of_session") %in% names(ret)))
    expect_false(ret$is_active())                  # no ?pilot_condition -> inactive
    expect_true(is.function(ret$trigger_end_of_session))
    expect_null(output$banner)                     # banner renderUI returns NULL while inactive
    expect_silent(ret$trigger_end_of_session())    # no-op (no modal/error) while inactive
  })
})

test_that("save tracker takes the inactive early-return path without error", {
  pdr <- reactiveVal(init_session_data())
  testServer(pilot_study_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    session$flushReact()
    # A project_data change fires the save-tracker observer; while inactive it
    # must early-return (no recording, no error).
    pdr(list(isa_data = list(elements = data.frame(id = 1:6),
                             connections = data.frame(a = 1:4))))
    session$flushReact()
    expect_false(session$getReturned()$is_active())
  })
})
