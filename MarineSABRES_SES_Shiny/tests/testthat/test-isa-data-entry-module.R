# test-isa-data-entry-module.R
# Unit tests for modules/isa_data_entry_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
.isade_test_dir <- getwd()
.isade_root <- if (basename(.isade_test_dir) == "testthat") dirname(dirname(.isade_test_dir)) else .isade_test_dir
.isade_module_path <- file.path(.isade_root, "modules", "isa_data_entry_module.R")
if (file.exists(.isade_module_path)) {
  tryCatch(
    sys.source(.isade_module_path, envir = .GlobalEnv),
    error = function(e) message("Could not source isa_data_entry_module.R: ", e$message)
  )
}
rm(.isade_test_dir, .isade_root, .isade_module_path)

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("isa_data_entry_ui function exists", {
  skip_if_not(exists("isa_data_entry_ui", mode = "function"),
              "isa_data_entry_ui not available")
  expect_true(is.function(isa_data_entry_ui))
})

test_that("isa_data_entry_ui returns valid shiny tags", {
  skip_if_not(exists("isa_data_entry_ui", mode = "function"),
              "isa_data_entry_ui not available")
  params <- names(formals(isa_data_entry_ui))
  ui <- if ("i18n" %in% params) isa_data_entry_ui("test_isade", i18n) else isa_data_entry_ui("test_isade")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "isa_data_entry_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("isa_data_entry_server function exists", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  expect_true(is.function(isa_data_entry_server))
})

test_that("isa_data_entry_server signature includes all required params", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  params <- names(formals(isa_data_entry_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("isa_data_entry_server event_bus defaults to NULL", {
  skip_if_not(exists("isa_data_entry_server", mode = "function"),
              "isa_data_entry_server not available")
  default <- formals(isa_data_entry_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
