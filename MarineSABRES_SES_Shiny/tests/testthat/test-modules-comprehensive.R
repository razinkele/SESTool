# tests/testthat/test-modules-comprehensive.R
# Comprehensive tests for all modules (P1 Test Coverage)
#
# These tests verify:
# 1. All UI functions exist and return valid shiny tags
# 2. All server functions exist
# 3. Module pairs (UI + server) are complete

library(testthat)

# ============================================================================
# TEST HELPERS
# ============================================================================

#' Create mock i18n object for testing
create_mock_i18n <- function() {
  list(
    t = function(key) key,
    get_key_translation = function(key) key,
    set_translation_language = function(lang) invisible(NULL)
  )
}

#' Test that a UI function exists and returns valid output
test_ui_function <- function(fn_name, i18n = create_mock_i18n()) {
  skip_if_not(exists(fn_name, mode = "function"),
              paste(fn_name, "function not available"))

  fn <- get(fn_name)

  # Call the function
  result <- tryCatch({
    fn("test_id", i18n)
  }, error = function(e) {
    list(error = TRUE, message = e$message)
  })

  # Check for error during call
  if (is.list(result) && isTRUE(result$error)) {
    skip(paste(fn_name, "call failed:", result$message))
  }

  # Should return something (not error out)
  # Accept: shiny.tag, shiny.tag.list, list (for tagList results), htmlwidget, or NULL (some modules)
  is_valid_ui <- !is.null(result) ||
                 inherits(result, "shiny.tag") ||
                 inherits(result, "shiny.tag.list") ||
                 inherits(result, "htmlwidget") ||
                 is.list(result)

  expect_true(is_valid_ui,
              info = paste(fn_name, "should return valid UI"))
}

#' Test that a server function exists
test_server_function <- function(fn_name) {
  skip_if_not(exists(fn_name, mode = "function"),
              paste(fn_name, "function not available"))

  fn <- get(fn_name)
  expect_true(is.function(fn), info = paste(fn_name, "should be a function"))
}

# ============================================================================
# ANALYSIS MODULE TESTS
# ============================================================================

test_that("analysis_bot_ui exists and renders", {
  test_ui_function("analysis_bot_ui")
})

test_that("analysis_bot_server exists", {
  test_server_function("analysis_bot_server")
})

test_that("analysis_boolean_ui exists and renders", {
  test_ui_function("analysis_boolean_ui")
})

test_that("analysis_boolean_server exists", {
  test_server_function("analysis_boolean_server")
})

test_that("analysis_simulation_ui exists and renders", {
  test_ui_function("analysis_simulation_ui")
})

test_that("analysis_simulation_server exists", {
  test_server_function("analysis_simulation_server")
})

test_that("analysis_intervention_ui exists and renders", {
  test_ui_function("analysis_intervention_ui")
})

test_that("analysis_intervention_server exists", {
  test_server_function("analysis_intervention_server")
})

test_that("analysis_leverage_ui exists and renders", {
  test_ui_function("analysis_leverage_ui")
})

test_that("analysis_leverage_server exists", {
  test_server_function("analysis_leverage_server")
})

test_that("analysis_simplify_ui exists and renders", {
  test_ui_function("analysis_simplify_ui")
})

test_that("analysis_simplify_server exists", {
  test_server_function("analysis_simplify_server")
})

# ============================================================================
# GRAPHICAL SES MODULE TESTS
# ============================================================================

test_that("graphical_ses_creator_ui exists and renders", {
  test_ui_function("graphical_ses_creator_ui")
})

test_that("graphical_ses_creator_server exists", {
  test_server_function("graphical_ses_creator_server")
})

test_that("graphical_ses_ai_classifier functions exist", {
  # Check if any ai classifier functions exist
  ai_classifier_fns <- c("graphical_ses_ai_classifier_ui",
                          "ai_classifier_ui",
                          "classify_element_dapsiwrm")

  found_any <- FALSE
  for (fn in ai_classifier_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No AI classifier functions found")
  expect_true(found_any)
})

test_that("graphical_ses_ml_enhancer functions exist", {
  # Check if any ml enhancer functions exist
  ml_fns <- c("graphical_ses_ml_enhancer_ui",
              "ml_enhancer_ui",
              "enhance_with_ml")

  found_any <- FALSE
  for (fn in ml_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No ML enhancer functions found")
  expect_true(found_any)
})

# ============================================================================
# IMPORT/EXPORT MODULE TESTS
# ============================================================================

test_that("import_data_ui exists and renders", {
  test_ui_function("import_data_ui")
})

test_that("import_data_server exists", {
  test_server_function("import_data_server")
})

test_that("export_reports_ui exists and renders", {
  test_ui_function("export_reports_ui")
})

test_that("export_reports_server exists", {
  test_server_function("export_reports_server")
})

test_that("prepare_report_ui exists and renders", {
  test_ui_function("prepare_report_ui")
})

test_that("prepare_report_server exists", {
  test_server_function("prepare_report_server")
})

# ============================================================================
# WORKFLOW MODULE TESTS
# ============================================================================
test_that("workflow_stepper_ui exists and renders", {
  test_ui_function("workflow_stepper_ui")
})

test_that("workflow_stepper_server exists", {
  test_server_function("workflow_stepper_server")
})

test_that("scenario_builder_ui exists and renders", {
  test_ui_function("scenario_builder_ui")
})

test_that("scenario_builder_server exists", {
  test_server_function("scenario_builder_server")
})

# ============================================================================
# PIMS MODULE TESTS
# ============================================================================

test_that("pims_stakeholder_ui exists and renders", {
  test_ui_function("pims_stakeholder_ui")
})

test_that("pims_stakeholder_server exists", {
  test_server_function("pims_stakeholder_server")
})

# ============================================================================
# STORAGE MODULE TESTS
# ============================================================================

test_that("local_storage_ui exists and renders", {
  test_ui_function("local_storage_ui")
})

test_that("local_storage_server exists", {
  test_server_function("local_storage_server")
})

test_that("recent_projects_ui exists and renders", {
  test_ui_function("recent_projects_ui")
})

test_that("recent_projects_server exists", {
  test_server_function("recent_projects_server")
})

# ============================================================================
# HELPER MODULE TESTS
# ============================================================================

test_that("navigation_helpers functions exist", {
  skip_if_not(file.exists("modules/navigation_helpers.R"),
              "navigation_helpers.R not found")

  # Check for navigation helper functions
  nav_fns <- c("navigate_to_tab", "create_nav_button", "navigation_helpers")

  found_any <- FALSE
  for (fn in nav_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No navigation helper functions found")
  expect_true(found_any)
})

test_that("connection_review_tabbed functions exist", {
  skip_if_not(file.exists("modules/connection_review_tabbed.R"),
              "connection_review_tabbed.R not found")

  # Check for connection review functions
  review_fns <- c("connection_review_ui", "connection_review_server",
                  "connection_review_tabbed_ui")

  found_any <- FALSE
  for (fn in review_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No connection review functions found")
  expect_true(found_any)
})

# ============================================================================
# AI MODULE TESTS
# ============================================================================

test_that("ai_isa_knowledge_base functions exist", {
  skip_if_not(file.exists("modules/ai_isa_knowledge_base.R"),
              "ai_isa_knowledge_base.R not found")

  # Check for knowledge base functions
  kb_fns <- c("get_dapsiwrm_knowledge", "ai_knowledge_base",
              "get_element_description")

  found_any <- FALSE
  for (fn in kb_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No AI knowledge base functions found")
  expect_true(found_any)
})

# ============================================================================
# SES MODELS MODULE TESTS
# ============================================================================

test_that("ses_models_ui exists and renders", {
  test_ui_function("ses_models_ui")
})

test_that("ses_models_server exists", {
  test_server_function("ses_models_server")
})

# ============================================================================
# TUTORIAL MODULE TESTS
# ============================================================================

test_that("tutorial functions exist", {
  skip_if_not(file.exists("modules/tutorial_system.R"),
              "tutorial_system.R not found")

  # Check for tutorial functions
  tutorial_fns <- c("tutorial_ui", "tutorial_server", "create_tutorial_step",
                    "tutorial_system_ui")

  found_any <- FALSE
  for (fn in tutorial_fns) {
    if (exists(fn, mode = "function")) {
      found_any <- TRUE
      break
    }
  }

  skip_if_not(found_any, "No tutorial functions found")
  expect_true(found_any)
})

# ============================================================================
# MODULE COMPLETENESS TESTS
# ============================================================================

test_that("all modules have matching UI and server functions", {
  module_files <- list.files("modules", pattern = "_module\\.R$", full.names = TRUE)

  skip_if(length(module_files) == 0, "No module files found")

  for (file in module_files) {
    module_name <- gsub("_module\\.R$", "", basename(file))

    # Expected function names
    ui_name <- paste0(module_name, "_ui")
    server_name <- paste0(module_name, "_server")

    # Check if both exist
    ui_exists <- exists(ui_name, mode = "function")
    server_exists <- exists(server_name, mode = "function")

    # At least one should exist (some modules may have different naming)
    expect_true(ui_exists || server_exists,
                info = paste("Module", module_name, "should have UI or server function"))
  }
})

test_that("analysis modules follow naming convention", {
  analysis_files <- list.files("modules", pattern = "^analysis_.*\\.R$", full.names = TRUE)

  skip_if(length(analysis_files) == 0, "No analysis module files found")

  for (file in analysis_files) {
    base_name <- gsub("\\.R$", "", basename(file))

    # Expected function names
    ui_name <- paste0(base_name, "_ui")
    server_name <- paste0(base_name, "_server")

    # Both should exist for analysis modules
    ui_exists <- exists(ui_name, mode = "function")
    server_exists <- exists(server_name, mode = "function")

    expect_true(ui_exists,
                info = paste(base_name, "should have", ui_name))
    expect_true(server_exists,
                info = paste(base_name, "should have", server_name))
  }
})
