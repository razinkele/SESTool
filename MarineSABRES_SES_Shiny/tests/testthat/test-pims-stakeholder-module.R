# test-pims-stakeholder-module.R
# Unit tests for modules/pims_stakeholder_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
.pst_test_dir <- getwd()
.pst_root <- if (basename(.pst_test_dir) == "testthat") dirname(dirname(.pst_test_dir)) else .pst_test_dir
.pst_module_path <- file.path(.pst_root, "modules", "pims_stakeholder_module.R")
if (file.exists(.pst_module_path)) {
  tryCatch(
    sys.source(.pst_module_path, envir = .GlobalEnv),
    error = function(e) message("Could not source pims_stakeholder_module.R: ", e$message)
  )
}
rm(.pst_test_dir, .pst_root, .pst_module_path)

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("pims_stakeholder_ui function exists", {
  skip_if_not(exists("pims_stakeholder_ui", mode = "function"),
              "pims_stakeholder_ui not available")
  expect_true(is.function(pims_stakeholder_ui))
})

test_that("pims_stakeholder_ui returns valid shiny tags", {
  skip_if_not(exists("pims_stakeholder_ui", mode = "function"),
              "pims_stakeholder_ui not available")
  params <- names(formals(pims_stakeholder_ui))
  ui <- if ("i18n" %in% params) pims_stakeholder_ui("test_pst", i18n) else pims_stakeholder_ui("test_pst")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "pims_stakeholder_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("pims_stakeholder_server function exists", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  expect_true(is.function(pims_stakeholder_server))
})

test_that("pims_stakeholder_server signature includes all required params", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  params <- names(formals(pims_stakeholder_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("pims_stakeholder_server event_bus defaults to NULL", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  default <- formals(pims_stakeholder_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
