# tests/testthat/test-navigation-handler-wiring.R
#
# The event bus has had emit_navigation_request()/on_navigation_request() and
# server/event_bus_setup.R has had setup_navigation_handler() since the P3
# refactor, but app.R never called the handler. Every module that emitted a
# navigation request (analysis_loops / analysis_leverage / analysis_decision_lens
# recommendation links, the WP5 impact wizard's "open valuation calculator"
# button) was therefore inert. These tests pin both halves of the fix:
#   1. app.R wires the handler into the main server;
#   2. the handler really drives the sidebar when a request is emitted.

library(testthat)

source_for_test("server/event_bus_setup.R")

project_root <- normalizePath(file.path(getwd(), "..", ".."), winslash = "/", mustWork = TRUE)

test_that("app.R wires setup_navigation_handler into the main server", {
  app <- paste(readLines(file.path(project_root, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "setup_navigation_handler(event_bus, session)", fixed = TRUE)
})

# Record every sidebar update the handler issues. bs4Dash::updateTabItems()
# delegates to shiny::updateTabsetPanel(), and MockShinySession$sendInputMessage
# is a no-op, so the shiny binding is the observable seam.
with_recorded_tab_updates <- function(code) {
  calls <- list()
  testthat::local_mocked_bindings(
    updateTabsetPanel = function(session, inputId, selected = NULL, ...) {
      calls[[length(calls) + 1]] <<- list(inputId = inputId, selected = selected)
      invisible(NULL)
    },
    .package = "shiny"
  )
  force(code)
  calls
}

test_that("setup_navigation_handler navigates the sidebar on a navigation request", {
  bus <- create_event_bus(session_id = "nav")
  calls <- with_recorded_tab_updates(
    testServer(
      function(input, output, session) {
        setup_navigation_handler(bus, session)
      },
      {
        session$flushReact()
        bus$emit_navigation_request("response_valuation", source = "impact_assessment")
        session$flushReact()
      }
    )
  )
  expect_length(calls, 1L)
  expect_equal(calls[[1]]$inputId, "sidebar_menu")
  expect_equal(calls[[1]]$selected, "response_valuation")
})

test_that("setup_navigation_handler is silent until a request is emitted and ignores empty targets", {
  bus <- create_event_bus(session_id = "nav_idle")
  calls <- with_recorded_tab_updates(
    testServer(
      function(input, output, session) {
        setup_navigation_handler(bus, session)
      },
      {
        session$flushReact()
        bus$emit_navigation_request("", source = "test")
        session$flushReact()
      }
    )
  )
  expect_length(calls, 0L)
})

test_that("every repeated request navigates again, even to the same tab", {
  bus <- create_event_bus(session_id = "nav_repeat")
  calls <- with_recorded_tab_updates(
    testServer(
      function(input, output, session) {
        setup_navigation_handler(bus, session)
      },
      {
        bus$emit_navigation_request("analysis_loops", source = "analysis_leverage")
        session$flushReact()
        bus$emit_navigation_request("analysis_loops", source = "analysis_leverage")
        session$flushReact()
      }
    )
  )
  # The user may close the tab and click the link again; each click must work.
  expect_length(calls, 2L)
  expect_equal(vapply(calls, `[[`, "", "selected"), c("analysis_loops", "analysis_loops"))
})
