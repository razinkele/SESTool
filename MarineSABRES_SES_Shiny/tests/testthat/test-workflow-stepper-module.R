# test-workflow-stepper-module.R
# Unit tests for modules/workflow_stepper_module.R

library(testthat)
library(shiny)

# Source the module file to make its functions available
local({
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  module_path <- file.path(root, "modules", "workflow_stepper_module.R")
  if (file.exists(module_path)) {
    tryCatch(source(module_path, local = FALSE), error = function(e) {
      message("Could not source workflow_stepper_module.R: ", e$message)
    })
  }
})

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("workflow_stepper_ui function exists", {
  skip_if_not(exists("workflow_stepper_ui", mode = "function"),
              "workflow_stepper_ui not available")
  expect_true(is.function(workflow_stepper_ui))
})

test_that("workflow_stepper_ui returns valid shiny tags", {
  skip_if_not(exists("workflow_stepper_ui", mode = "function"),
              "workflow_stepper_ui not available")

  ui <- workflow_stepper_ui("test_stepper")

  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "workflow_stepper_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("workflow_stepper_ui uses namespaced IDs", {
  skip_if_not(exists("workflow_stepper_ui", mode = "function"),
              "workflow_stepper_ui not available")

  ui <- workflow_stepper_ui("test_stepper")
  ui_html <- as.character(ui)

  expect_true(grepl("test_stepper", ui_html),
              info = "UI should contain namespaced IDs")
})

test_that("workflow_stepper_ui does not require i18n parameter", {
  skip_if_not(exists("workflow_stepper_ui", mode = "function"),
              "workflow_stepper_ui not available")

  # workflow_stepper_ui only takes id, no i18n
  params <- names(formals(workflow_stepper_ui))
  expect_equal(params, "id")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("workflow_stepper_server function exists", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")
  expect_true(is.function(workflow_stepper_server))
})

test_that("workflow_stepper_server has correct parameters", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  params <- names(formals(workflow_stepper_server))
  expect_true("id" %in% params)
  expect_true("project_data_reactive" %in% params)
  expect_true("i18n" %in% params)
  expect_true("parent_session" %in% params)
  expect_true("user_level_reactive" %in% params)
  expect_true("sidebar_input" %in% params)
})

# ============================================================================
# STEP DEFINITIONS TESTS
# ============================================================================

test_that("workflow stepper defines 5 steps", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  # The STEPS list is defined inside the server function, so we check
  # that the function body contains the expected step keys
  fn_body <- deparse(body(workflow_stepper_server))
  fn_text <- paste(fn_body, collapse = "\n")

  expect_true(grepl("step_get_started", fn_text),
              info = "Step 1: Get Started should be defined")
  expect_true(grepl("step_create_ses", fn_text),
              info = "Step 2: Create SES should be defined")
  expect_true(grepl("step_visualize", fn_text),
              info = "Step 3: Visualize should be defined")
  expect_true(grepl("step_analyze", fn_text),
              info = "Step 4: Analyze should be defined")
  expect_true(grepl("step_report", fn_text),
              info = "Step 5: Report should be defined")
})

test_that("workflow stepper targets correct sidebar tabs", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  fn_body <- deparse(body(workflow_stepper_server))
  fn_text <- paste(fn_body, collapse = "\n")

  expect_true(grepl("entry_point", fn_text),
              info = "Step 1 should target entry_point tab")
  expect_true(grepl("create_ses_standard", fn_text),
              info = "Step 2 should target create_ses_standard tab")
  expect_true(grepl("cld_viz", fn_text),
              info = "Step 3 should target cld_viz tab")
  expect_true(grepl("analysis_loops", fn_text),
              info = "Step 4 should target analysis_loops tab")
  expect_true(grepl("prepare_report", fn_text),
              info = "Step 5 should target prepare_report tab")
})

test_that("workflow stepper initializes with correct defaults", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  fn_body <- deparse(body(workflow_stepper_server))
  fn_text <- paste(fn_body, collapse = "\n")

  # Check initial state: steps 1-2 enabled, 3-5 disabled
  # completed = c(FALSE, FALSE, FALSE, FALSE, FALSE)
  # enabled = c(TRUE, TRUE, FALSE, FALSE, FALSE)
  expect_true(grepl("completed.*FALSE.*FALSE.*FALSE.*FALSE.*FALSE", fn_text),
              info = "All steps should start as not completed")
  expect_true(grepl("enabled.*TRUE.*TRUE.*FALSE.*FALSE.*FALSE", fn_text),
              info = "Only steps 1-2 should start enabled")
})

# ============================================================================
# INTERNAL HELPER: count_isa_elements (tested via body inspection)
# ============================================================================

test_that("workflow stepper checks correct ISA categories", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  fn_body <- deparse(body(workflow_stepper_server))
  fn_text <- paste(fn_body, collapse = "\n")

  # count_isa_elements should check all 7 ISA categories
  expect_true(grepl("drivers", fn_text))
  expect_true(grepl("activities", fn_text))
  expect_true(grepl("pressures", fn_text))
  expect_true(grepl("marine_processes", fn_text))
  expect_true(grepl("ecosystem_services", fn_text))
  expect_true(grepl("goods_benefits", fn_text))
  expect_true(grepl("responses", fn_text))
})

test_that("workflow stepper requires 2+ elements for step 2 completion", {
  skip_if_not(exists("workflow_stepper_server", mode = "function"),
              "workflow_stepper_server not available")

  fn_body <- deparse(body(workflow_stepper_server))
  fn_text <- paste(fn_body, collapse = "\n")

  expect_true(grepl("n >= 2", fn_text),
              info = "Step 2 should require at least 2 ISA elements")
})

# ============================================================================
# CONFIGURATION TESTS
# ============================================================================

test_that("workflow stepper is enabled for all user levels in config", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  config_path <- file.path(root, "config", "user_level_config.R")

  expect_true(file.exists(config_path),
              info = "user_level_config.R should exist")

  # Source the config file
  source(config_path, local = TRUE)

  expect_true(USER_LEVEL_DEFAULTS$beginner$show_workflow_stepper,
              info = "Beginner level should show workflow stepper")
  expect_true(USER_LEVEL_DEFAULTS$intermediate$show_workflow_stepper,
              info = "Intermediate level should show workflow stepper")
  expect_true(USER_LEVEL_DEFAULTS$expert$show_workflow_stepper,
              info = "Expert level should show workflow stepper")
})
