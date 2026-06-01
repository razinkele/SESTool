# test-feedback-admin-module.R
# Unit tests for modules/feedback_admin_module.R

library(testthat)
library(shiny)

# Source the module under test. Modules are not auto-loaded by global.R
# (app.R sources them at startup). helper-00-load-functions.R provides
# source_for_test() which handles path resolution + error recovery.
source_for_test("modules/feedback_admin_module.R")

# Mock i18n
i18n <- list(t = function(key) key)

# Re-bind the real server over the helper-stubs.R stub, which shadows the
# .GlobalEnv copy in testthat's helper env (see feedback_testserver_stub_shadowing).
if (exists("feedback_admin_server", envir = .GlobalEnv)) {
  feedback_admin_server <- get("feedback_admin_server", envir = .GlobalEnv)
}

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

# ============================================================================
# SERVER BEHAVIOR TESTS
# The module loads the feedback log on start and renders value boxes + tables.
# These read the real outputs, so they FAIL if the server body is NULL.
# ============================================================================

test_that("load-on-start renders the summary value boxes and feedback table", {
  testServer(feedback_admin_server, args = list(i18n = i18n), {
    session$flushReact()
    # value boxes are computed from the loaded feedback log (empty df in test env)
    expect_false(is.null(output$vbox_total))
    expect_false(is.null(output$vbox_bugs))
    expect_false(is.null(output$vbox_suggestions))
    # the feedback DataTable renders
    expect_false(is.null(output$feedback_table))
  })
})

test_that("find_duplicates observer runs and the duplicates table renders", {
  testServer(feedback_admin_server, args = list(i18n = i18n), {
    session$flushReact()
    session$setInputs(find_duplicates = 1)        # increments run_detection
    expect_false(is.null(output$duplicates_table))
  })
})

# ============================================================================
# RESOLUTION WORKFLOW TESTS (Task 3)
# Mark-addressed flips status; status_filter changes the displayed set;
# the Resolved value box renders. Uses the marinesabres.feedback_log_path
# seam + the recalculate observer to force the gated load against a fixture.
# ============================================================================

test_that("mark-addressed flips status to addressed and refreshes", {
  tmp <- tempfile(fileext = ".ndjson")
  writeLines('{"title":"Bug A","type":"bug","timestamp":"t1"}', tmp)
  withr::with_options(list(marinesabres.feedback_log_path = tmp), {
    testServer(feedback_admin_server, args = list(i18n = i18n), {
      session$setInputs(recalculate = 1); session$flushReact()
      expect_false(is.null(output$vbox_total))         # proves fixture loaded
      session$setInputs(mark_addr_click = list(line = 1, rand = 1))
      session$setInputs(mark_addressed_status = "addressed",
                        mark_addressed_note = "fixed in test",
                        mark_addressed_fix_ref = "pr1")
      session$setInputs(do_mark_addressed = 1); session$flushReact()
      p <- jsonlite::fromJSON(readLines(tmp)[1])
      expect_equal(p$status, "addressed"); expect_equal(p$fix_ref, "pr1")
      expect_false(is.null(output$vbox_resolved))
    })
  })
  unlink(tmp)
})

test_that("status_filter changes the displayed set", {
  tmp <- tempfile(fileext = ".ndjson")
  writeLines(c('{"title":"Open one","type":"bug","timestamp":"t1"}',
               '{"title":"Done one","type":"bug","timestamp":"t2","status":"addressed"}'), tmp)
  withr::with_options(list(marinesabres.feedback_log_path = tmp), {
    testServer(feedback_admin_server, args = list(i18n = i18n), {
      session$setInputs(recalculate = 1); session$flushReact()
      # DT serializes row data out-of-band (server-side processing), so the
      # rendered widget JSON cannot be grepped for row titles. Assert against
      # the production `filtered_feedback()` reactive that the render consumes,
      # and force the render so the reactive is exercised end-to-end.
      session$setInputs(status_filter = "open"); session$flushReact()
      invisible(output$feedback_table)
      t1 <- filtered_feedback()$title
      expect_true("Open one" %in% t1); expect_false("Done one" %in% t1)
      session$setInputs(status_filter = "resolved"); session$flushReact()
      invisible(output$feedback_table)
      t2 <- filtered_feedback()$title
      expect_true("Done one" %in% t2); expect_false("Open one" %in% t2)
    })
  })
  unlink(tmp)
})
