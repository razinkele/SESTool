# test-recent-projects-module.R
# Unit tests for modules/recent_projects_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/recent_projects_module.R")
i18n <- list(t = function(key) key)

# Re-bind the real server over the helper-stubs.R stub, which shadows the
# .GlobalEnv copy in testthat's helper env (see feedback_testserver_stub_shadowing).
if (exists("recent_projects_server", envir = .GlobalEnv)) {
  recent_projects_server <- get("recent_projects_server", envir = .GlobalEnv)
}

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

# ============================================================================
# SERVER BEHAVIOR TESTS
# The module returns list(get_projects, refresh, is_local_mode). These drive
# that real interface, so they FAIL if the server body is replaced with NULL.
# ============================================================================

test_that("server returns the documented project interface and computes state", {
  testServer(recent_projects_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$flushReact()
    ret <- session$getReturned()
    expect_true(is.list(ret))
    expect_true(all(c("get_projects", "refresh", "is_local_mode") %in% names(ret)))
    # init observe block populated state from the environment
    expect_s3_class(ret$get_projects(), "data.frame")
    expect_type(ret$is_local_mode(), "logical")
    expect_true(is.function(ret$refresh))
  })
})

test_that("refresh() reloads the projects data frame without error", {
  testServer(recent_projects_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$flushReact()
    ret <- session$getReturned()
    ret$refresh()                              # list_saved_projects(state$projects_folder)
    expect_s3_class(ret$get_projects(), "data.frame")
  })
})

test_that("dismiss_tip removes the onboarding tip output", {
  testServer(recent_projects_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$setInputs(dismiss_tip = 1)
    # show_onboarding flipped FALSE -> the renderUI short-circuits to NULL
    expect_null(output$onboarding_tip)
  })
})
