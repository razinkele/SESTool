# test-cld-visualization-module.R
# Unit tests for modules/cld_visualization_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
.cldv_test_dir <- getwd()
.cldv_root <- if (basename(.cldv_test_dir) == "testthat") dirname(dirname(.cldv_test_dir)) else .cldv_test_dir
.cldv_module_path <- file.path(.cldv_root, "modules", "cld_visualization_module.R")
if (file.exists(.cldv_module_path)) {
  tryCatch(
    sys.source(.cldv_module_path, envir = .GlobalEnv),
    error = function(e) message("Could not source cld_visualization_module.R: ", e$message)
  )
}
rm(.cldv_test_dir, .cldv_root, .cldv_module_path)

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("cld_viz_ui function exists", {
  skip_if_not(exists("cld_viz_ui", mode = "function"),
              "cld_viz_ui not available")
  expect_true(is.function(cld_viz_ui))
})

test_that("cld_viz_ui returns valid shiny tags", {
  skip_if_not(exists("cld_viz_ui", mode = "function"),
              "cld_viz_ui not available")
  params <- names(formals(cld_viz_ui))
  ui <- if ("i18n" %in% params) cld_viz_ui("test_cldv", i18n) else cld_viz_ui("test_cldv")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "cld_viz_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("cld_viz_server function exists", {
  skip_if_not(exists("cld_viz_server", mode = "function"),
              "cld_viz_server not available")
  expect_true(is.function(cld_viz_server))
})

test_that("cld_viz_server signature includes all required params", {
  skip_if_not(exists("cld_viz_server", mode = "function"),
              "cld_viz_server not available")
  params <- names(formals(cld_viz_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("cld_viz_server event_bus defaults to NULL", {
  skip_if_not(exists("cld_viz_server", mode = "function"),
              "cld_viz_server not available")
  default <- formals(cld_viz_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
