# test-prepare-report-module.R
# Unit tests for modules/prepare_report_module.R

library(testthat)
library(shiny)

# Source the module file to make its functions available
source_for_test("modules/prepare_report_module.R")
# Mock i18n
i18n <- list(t = function(key) key)

# Re-bind the real server over the helper-stubs.R stub, which shadows the
# .GlobalEnv copy in testthat's helper env (see feedback_testserver_stub_shadowing).
if (exists("prepare_report_server", envir = .GlobalEnv)) {
  prepare_report_server <- get("prepare_report_server", envir = .GlobalEnv)
}

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("prepare_report_ui function exists", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")
  expect_true(is.function(prepare_report_ui))
})

test_that("prepare_report_ui returns valid shiny tags", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")

  ui <- prepare_report_ui("test_report", i18n)

  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "prepare_report_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("prepare_report_ui uses namespaced IDs", {
  skip_if_not(exists("prepare_report_ui", mode = "function"),
              "prepare_report_ui not available")

  ui <- prepare_report_ui("test_report", i18n)
  ui_html <- as.character(ui)

  expect_true(grepl("test_report", ui_html),
              info = "UI should contain namespaced IDs")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("prepare_report_server function exists", {
  skip_if_not(exists("prepare_report_server", mode = "function"),
              "prepare_report_server not available")
  expect_true(is.function(prepare_report_server))
})

test_that("prepare_report_server has correct parameters", {
  skip_if_not(exists("prepare_report_server", mode = "function"),
              "prepare_report_server not available")

  params <- names(formals(prepare_report_server))
  expect_true("id" %in% params)
  expect_true("project_data_reactive" %in% params)
  expect_true("i18n" %in% params)
})

# ============================================================================
# SERVER BEHAVIOR TESTS
# check_prerequisites() reads the project and prerequisite_status renders
# success/danger icons accordingly. These read the real output and differ by
# input, so they FAIL if the server body is replaced with NULL. (Report
# generation itself drives rmarkdown/officer and is covered by the helper
# tests below, not the server observers.)
# ============================================================================

test_that("prerequisite_status shows danger icons when loops/leverage are absent", {
  testServer(prepare_report_server,
             args = list(project_data_reactive = reactiveVal(list(data = list())),
                         i18n = i18n), {
    session$flushReact()
    html <- paste(as.character(output$prerequisite_status), collapse = "")
    expect_true(nzchar(html))
    expect_match(html, "text-danger")             # neither prerequisite met
    expect_false(grepl("text-success", html, fixed = TRUE))
  })
})

test_that("prerequisite_status shows success icons when loops + leverage are present", {
  ready <- reactiveVal(list(data = list(
    analysis = list(loops = list(list(1), list(2))),          # has_loops: length > 0
    cld = list(nodes = data.frame(leverage_score = c(0.5, 0.2)))  # has_leverage: any > 0
  )))
  testServer(prepare_report_server,
             args = list(project_data_reactive = ready, i18n = i18n), {
    session$flushReact()
    html <- paste(as.character(output$prerequisite_status), collapse = "")
    expect_match(html, "text-success")            # both prerequisites met
    expect_false(grepl("text-danger", html, fixed = TRUE))
  })
})

# ============================================================================
# HELPER FUNCTION TESTS: generate_word_report
# ============================================================================

test_that("generate_word_report function exists", {
  skip_if_not(exists("generate_word_report", mode = "function"),
              "generate_word_report not available")
  expect_true(is.function(generate_word_report))
})

test_that("generate_word_report has correct parameters", {
  skip_if_not(exists("generate_word_report", mode = "function"),
              "generate_word_report not available")

  params <- names(formals(generate_word_report))
  expect_true("data" %in% params)
  expect_true("title" %in% params)
  expect_true("author" %in% params)
  expect_true("sections" %in% params)
  expect_true("output_file" %in% params)
})

# ============================================================================
# HELPER FUNCTION TESTS: generate_ppt_report
# ============================================================================

test_that("generate_ppt_report function exists", {
  skip_if_not(exists("generate_ppt_report", mode = "function"),
              "generate_ppt_report not available")
  expect_true(is.function(generate_ppt_report))
})

test_that("generate_ppt_report has correct parameters", {
  skip_if_not(exists("generate_ppt_report", mode = "function"),
              "generate_ppt_report not available")

  params <- names(formals(generate_ppt_report))
  expect_true("data" %in% params)
  expect_true("title" %in% params)
  expect_true("author" %in% params)
  expect_true("sections" %in% params)
  expect_true("output_file" %in% params)
})

# ============================================================================
# User feedback 2026-06-15 "HTML report": the opened report's link stops
# working ("not found") once the session ends, and there was no way to keep
# the HTML: output$download_html existed but no button used it.
# ============================================================================

test_that("generating the HTML report offers a download and explains the link", {
  ready <- reactiveVal(list(data = list(
    analysis = list(loops = list(list(1))),
    cld = list(nodes = data.frame(leverage_score = 0.5))
  )))
  modal <- NULL
  # The module resolves these from .GlobalEnv (sourced, not a package), so
  # swap them there and restore them afterwards.
  stubs <- list(
    generate_report_content = function(...) "# Report",
    render_report_safely = function(md, file, ...) writeLines("<html></html>", file),
    register_session_report = function(session, path) "session/report.html"
  )
  saved <- mget(names(stubs), envir = globalenv(), ifnotfound = list(NULL))
  for (n in names(stubs)) assign(n, stubs[[n]], envir = globalenv())
  withr::defer(for (n in names(saved)) {
    if (is.null(saved[[n]])) rm(list = n, envir = globalenv()) else assign(n, saved[[n]], envir = globalenv())
  })
  local_mocked_bindings(showModal = function(ui, ...) modal <<- ui, .package = "shiny")
  testServer(prepare_report_server, args = list(project_data_reactive = ready, i18n = i18n), {
    session$setInputs(generate_html = 1)
    html <- paste(as.character(modal), collapse = "")
    expect_match(html, session$ns("download_html"), fixed = TRUE)
    expect_match(html, "common.messages.html_report_link_temporary", fixed = TRUE)
    expect_true(file.exists(rv$html_report_path))
  })
})

# ============================================================================
# User feedback 2026-10-18 "Word vs html report": the Word report was built by
# a separate officer builder with far less content (and it always reported
# "Detected 2 feedback loops"). It now renders the same content as HTML/PDF.
# ============================================================================

test_that("the Word report renders the same content as the HTML report", {
  skip_if_not(requireNamespace("officer", quietly = TRUE) && requireNamespace("flextable", quietly = TRUE),
              "officer/flextable not installed")
  ready <- reactiveVal(list(data = list(
    analysis = list(loops = list(list(1))),
    cld = list(nodes = data.frame(leverage_score = 0.5))
  )))
  calls <- list(); modal <- NULL
  stubs <- list(
    generate_report_content = function(data, report_type, ...) { calls$type <<- report_type; "# Report" },
    render_report_safely = function(md, file, format = "html", ...) {
      calls$format <<- format; calls$md <<- md; writeLines("docx", file)
    },
    generate_word_report = function(...) { calls$old_builder <<- TRUE; invisible(NULL) }
  )
  saved <- mget(names(stubs), envir = globalenv(), ifnotfound = list(NULL))
  for (n in names(stubs)) assign(n, stubs[[n]], envir = globalenv())
  withr::defer(for (n in names(saved)) {
    if (is.null(saved[[n]])) rm(list = n, envir = globalenv()) else assign(n, saved[[n]], envir = globalenv())
  })
  local_mocked_bindings(showModal = function(ui, ...) modal <<- ui, .package = "shiny")
  testServer(prepare_report_server, args = list(project_data_reactive = ready, i18n = i18n), {
    session$setInputs(generate_word = 1)
    expect_null(calls$old_builder)
    expect_identical(calls$type, "full")
    expect_identical(calls$format, "docx")
    expect_identical(calls$md, "# Report")
    expect_match(paste(as.character(modal), collapse = ""), session$ns("download_word"), fixed = TRUE)
  })
})
