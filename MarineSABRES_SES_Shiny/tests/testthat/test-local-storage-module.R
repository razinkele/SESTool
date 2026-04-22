# test-local-storage-module.R
# Unit tests for modules/local_storage_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
local({
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "local_storage_module.R")
  if (file.exists(module_path)) {
    tryCatch(
      source(module_path, local = FALSE),
      error = function(e) message("Could not source local_storage_module.R: ", e$message)
    )
  }
})

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("local_storage_ui function exists", {
  skip_if_not(exists("local_storage_ui", mode = "function"),
              "local_storage_ui not available")
  expect_true(is.function(local_storage_ui))
})

test_that("local_storage_ui returns valid shiny tags", {
  skip_if_not(exists("local_storage_ui", mode = "function"),
              "local_storage_ui not available")
  params <- names(formals(local_storage_ui))
  ui <- if ("i18n" %in% params) local_storage_ui("test_ls", i18n) else local_storage_ui("test_ls")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "local_storage_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("local_storage_server function exists", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  expect_true(is.function(local_storage_server))
})

test_that("local_storage_server signature includes all 4 required params", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  params <- names(formals(local_storage_server))
  # Actual signature at modules/local_storage_module.R:461 is
  #   local_storage_server(id, project_data_reactive, i18n, event_bus = NULL)
  # All 4 are load-bearing: id for namespacing, project_data_reactive for the
  # data pipeline, i18n for translator, event_bus for cross-module notification.
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("local_storage_server event_bus defaults to NULL", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  default <- formals(local_storage_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL")
})

# ============================================================================
# JS BRIDGE CONTRACT TESTS
# ============================================================================

test_that("local_storage_module wires session custom message handlers", {
  # This module communicates with the browser via session$sendCustomMessage.
  # Verify the SERVER source contains at least one sendCustomMessage call
  # (if it doesn't, the JS bridge is broken).
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fp <- file.path(root, "modules", "local_storage_module.R")
  skip_if_not(file.exists(fp), "local_storage_module.R not found")
  src <- paste(readLines(fp), collapse = "\n")
  expect_true(
    grepl("sendCustomMessage", src, fixed = TRUE),
    info = "local_storage_module must use session$sendCustomMessage for JS bridge"
  )
})
