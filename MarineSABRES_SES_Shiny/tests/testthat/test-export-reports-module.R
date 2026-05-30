# test-export-reports-module.R
# Unit tests for modules/export_reports_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/export_reports_module.R")
i18n <- list(t = function(key) key)

# Re-bind the real server over the helper-stubs.R stub, which shadows the
# .GlobalEnv copy in testthat's helper env (see feedback_testserver_stub_shadowing).
if (exists("export_reports_server", envir = .GlobalEnv)) {
  export_reports_server <- get("export_reports_server", envir = .GlobalEnv)
}

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("export_reports_ui function exists", {
  skip_if_not(exists("export_reports_ui", mode = "function"),
              "export_reports_ui not available")
  expect_true(is.function(export_reports_ui))
})

test_that("export_reports_ui returns valid shiny tags", {
  skip_if_not(exists("export_reports_ui", mode = "function"),
              "export_reports_ui not available")
  params <- names(formals(export_reports_ui))
  ui <- if ("i18n" %in% params) export_reports_ui("test_expr", i18n) else export_reports_ui("test_expr")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "export_reports_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("export_reports_server function exists", {
  skip_if_not(exists("export_reports_server", mode = "function"),
              "export_reports_server not available")
  expect_true(is.function(export_reports_server))
})

test_that("export_reports_server signature includes all required params", {
  skip_if_not(exists("export_reports_server", mode = "function"),
              "export_reports_server not available")
  params <- names(formals(export_reports_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("export_reports_server event_bus defaults to NULL", {
  skip_if_not(exists("export_reports_server", mode = "function"),
              "export_reports_server not available")
  default <- formals(export_reports_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

# ============================================================================
# SERVER BEHAVIOR TESTS
# Actual report generation drives rmarkdown (heavy/pandoc) so we don't trigger
# it here; instead assert the server instantiates and renders its real output,
# which the stub cannot produce -> FAILS if the server body is NULL.
# ============================================================================

test_that("server instantiates and renders the namespaced report-status output", {
  testServer(export_reports_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$flushReact()
    rendered <- paste(as.character(output$report_status), collapse = "")
    expect_true(nzchar(rendered))
    # the real renderUI body builds a div with this namespaced id
    expect_match(rendered, "report_status_div")
  })
})
