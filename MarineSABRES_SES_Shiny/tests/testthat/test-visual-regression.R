# test-visual-regression.R
# Visual regression tests for MarineSABRES SES Shiny Application
#
# These tests capture full-page screenshots and compare them against stored
# baselines. On the first run, baselines are created automatically and the
# tests skip. Subsequent runs detect pixel-level regressions.
#
# Run manually:
#   testthat::test_file("tests/testthat/test-visual-regression.R")
#
# Update baselines after intentional UI changes:
#   source("tests/testthat/helper-visual.R")
#   update_baselines()

library(testthat)

# Guard: skip the entire file when prerequisites are missing
skip_if_not_installed("shinytest2")
skip_on_ci()
skip_on_cran()

library(shinytest2)

# =============================================================================
# TEST 1: DASHBOARD / HOME PAGE
# =============================================================================

test_that("Visual: dashboard page renders consistently", {
  app <- setup_app_with_data(name = "visual-dashboard")
  on.exit(app$stop(), add = TRUE)

  # Navigate to dashboard (may already be there after auto-load)
  navigate_and_wait(app, "dashboard")

  compare_screenshot(app, "dashboard", threshold = 3)
})

# =============================================================================
# TEST 2: CLD VISUALIZATION (with sample data)
# =============================================================================

test_that("Visual: CLD visualization renders consistently", {
  app <- setup_app_with_data(name = "visual-cld")
  on.exit(app$stop(), add = TRUE)

  # The app auto-loads the Caribbean template, so CLD should have data

  navigate_and_wait(app, "cld_viz", wait_ms = 6000)

  # Allow extra time for the visNetwork widget to render
  Sys.sleep(2)
  app$wait_for_idle(timeout = VISUAL_IDLE_TIMEOUT)

  compare_screenshot(app, "cld_visualization", threshold = 5)
})

# =============================================================================
# TEST 3: ISA DATA ENTRY FORM
# =============================================================================

test_that("Visual: ISA data entry form renders consistently", {
  app <- setup_app_with_data(name = "visual-isa")
  on.exit(app$stop(), add = TRUE)

  navigate_and_wait(app, "create_ses_standard")

  compare_screenshot(app, "isa_data_entry", threshold = 3)
})

# =============================================================================
# TEST 4: ANALYSIS RESULTS (Network Metrics)
# =============================================================================

test_that("Visual: analysis metrics page renders consistently", {
  app <- setup_app_with_data(name = "visual-analysis")
  on.exit(app$stop(), add = TRUE)

  # Navigate to metrics analysis -- the auto-loaded template provides data
  navigate_and_wait(app, "analysis_metrics", wait_ms = 6000)

  # Analysis computation may take a moment
  Sys.sleep(1)
  app$wait_for_idle(timeout = VISUAL_IDLE_TIMEOUT)

  compare_screenshot(app, "analysis_metrics", threshold = 4)
})

# =============================================================================
# TEST 5: ANALYSIS RESULTS (Feedback Loops)
# =============================================================================

test_that("Visual: analysis loops page renders consistently", {
  app <- setup_app_with_data(name = "visual-loops")
  on.exit(app$stop(), add = TRUE)

  navigate_and_wait(app, "analysis_loops", wait_ms = 6000)

  Sys.sleep(1)
  app$wait_for_idle(timeout = VISUAL_IDLE_TIMEOUT)

  compare_screenshot(app, "analysis_loops", threshold = 4)
})

# =============================================================================
# TEST 6: REPORT GENERATION PAGE
# =============================================================================

test_that("Visual: report generation page renders consistently", {
  app <- setup_app_with_data(name = "visual-report")
  on.exit(app$stop(), add = TRUE)

  navigate_and_wait(app, "prepare_report")

  compare_screenshot(app, "report_generation", threshold = 3)
})

# =============================================================================
# TEST 7: EXPORT PAGE
# =============================================================================

test_that("Visual: export page renders consistently", {
  app <- setup_app_with_data(name = "visual-export")
  on.exit(app$stop(), add = TRUE)

  navigate_and_wait(app, "export")

  compare_screenshot(app, "export_page", threshold = 3)
})

# =============================================================================
# TEST 8: CREATE SES METHOD CHOOSER
# =============================================================================

test_that("Visual: create SES chooser page renders consistently", {
  app <- setup_app_with_data(name = "visual-create-ses")
  on.exit(app$stop(), add = TRUE)

  navigate_and_wait(app, "create_ses_choose")

  compare_screenshot(app, "create_ses_chooser", threshold = 3)
})
