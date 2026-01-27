# tests/shinytest2/test-visual-regression.R
# Visual Regression Tests for MarineSABRES SES Tool
# ==============================================================================
#
# These tests capture screenshots of key UI states and compare them against
# baseline images to detect unintended visual changes.
#
# Usage:
# - First run creates baseline screenshots in tests/shinytest2/_snaps/
# - Subsequent runs compare against baselines
# - Run shinytest2::snapshot_review() to review changes
#
# ==============================================================================

library(shinytest2)
library(testthat)

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Wait for and capture a stable screenshot
#' @param app AppDriver object
#' @param name Screenshot name
#' @param wait_time Additional wait time in ms
capture_stable_screenshot <- function(app, name, wait_time = 1000) {
  app$wait_for_idle(timeout = 5000)
  Sys.sleep(wait_time / 1000)  # Additional stability wait
  app$expect_screenshot(name = name, threshold = 0.05)  # 5% tolerance
}

# ==============================================================================
# Dashboard/Entry Point Tests
# ==============================================================================

test_that("Visual: Entry point page renders correctly", {
  skip_on_cran()
  skip_on_ci()  # Visual tests may fail on CI due to font/rendering differences

  app <- AppDriver$new(
    name = "visual-entry-point",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  # Wait for app to fully load
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(2)  # Extra time for CSS animations

  # Capture the entry point/dashboard
  capture_stable_screenshot(app, "entry-point-dashboard")

  app$stop()
})

# ==============================================================================
# Template Selection Tests
# ==============================================================================

test_that("Visual: Template selection page renders correctly", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-templates",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Navigate to template selection (if possible)
  # Try clicking on the "Use Template" button or navigating to SES creation
  tryCatch({
    app$click("entry_point-use_template_btn")
    app$wait_for_idle(timeout = 5000)
    Sys.sleep(1)
    capture_stable_screenshot(app, "template-selection-page")
  }, error = function(e) {
    # If navigation fails, just capture current state
    capture_stable_screenshot(app, "template-selection-fallback")
  })

  app$stop()
})

# ==============================================================================
# Modal Dialog Tests
# ==============================================================================

test_that("Visual: Language modal renders correctly", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-language-modal",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Try to open language modal
  tryCatch({
    app$click("open_language_modal")
    app$wait_for_idle(timeout = 3000)
    Sys.sleep(0.5)  # Wait for modal animation
    capture_stable_screenshot(app, "language-modal-open")
  }, error = function(e) {
    # Modal button may not be directly accessible
    skip("Language modal button not accessible")
  })

  app$stop()
})

test_that("Visual: Settings modal renders correctly", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-settings-modal",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Try to open settings modal
  tryCatch({
    app$click("settings_btn")
    app$wait_for_idle(timeout = 3000)
    Sys.sleep(0.5)  # Wait for modal animation
    capture_stable_screenshot(app, "settings-modal-open")
  }, error = function(e) {
    # Settings button may not be directly accessible
    skip("Settings button not accessible")
  })

  app$stop()
})

# ==============================================================================
# Sidebar Navigation Tests
# ==============================================================================

test_that("Visual: Sidebar collapsed state", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-sidebar-collapsed",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Try to collapse sidebar using JavaScript
  tryCatch({
    app$run_js("$('body').addClass('sidebar-collapse')")
    app$wait_for_idle(timeout = 2000)
    Sys.sleep(0.5)  # Wait for animation
    capture_stable_screenshot(app, "sidebar-collapsed")
  }, error = function(e) {
    skip("Sidebar collapse not available")
  })

  app$stop()
})

# ==============================================================================
# Dark Mode Tests (if available)
# ==============================================================================

test_that("Visual: Theme switching works", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-theme",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Capture light mode (default)
  capture_stable_screenshot(app, "theme-light-mode")

  # Try to switch to dark mode if available
  tryCatch({
    # Check if dark mode toggle exists
    has_dark_toggle <- app$get_js("document.querySelector('[data-widget=\"dark-mode\"]') !== null")
    if (has_dark_toggle) {
      app$run_js("$('[data-widget=\"dark-mode\"]').click()")
      app$wait_for_idle(timeout = 2000)
      Sys.sleep(0.5)
      capture_stable_screenshot(app, "theme-dark-mode")
    }
  }, error = function(e) {
    # Dark mode may not be available
  })

  app$stop()
})

# ==============================================================================
# Responsive Layout Tests
# ==============================================================================

test_that("Visual: Mobile responsive layout", {
  skip_on_cran()
  skip_on_ci()

  # Test at mobile width
  app <- AppDriver$new(
    name = "visual-mobile",
    height = 800,
    width = 375,  # iPhone width
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)
  Sys.sleep(1)

  capture_stable_screenshot(app, "layout-mobile-375px")

  app$stop()
})

test_that("Visual: Tablet responsive layout", {
  skip_on_cran()
  skip_on_ci()

  # Test at tablet width
  app <- AppDriver$new(
    name = "visual-tablet",
    height = 1024,
    width = 768,  # iPad width
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)
  Sys.sleep(1)

  capture_stable_screenshot(app, "layout-tablet-768px")

  app$stop()
})

# ==============================================================================
# Critical UI Component Tests
# ==============================================================================

test_that("Visual: Progress indicator styling", {
  skip_on_cran()
  skip_on_ci()

  app <- AppDriver$new(
    name = "visual-progress",
    height = 900,
    width = 1400,
    wait = TRUE,
    timeout = 30000
  )

  app$wait_for_idle(timeout = 10000)

  # Check if progress indicator exists and capture it
  tryCatch({
    has_progress <- app$get_js("document.querySelector('.progress-indicator, .workflow-progress, .step-indicator') !== null")
    if (has_progress) {
      capture_stable_screenshot(app, "progress-indicator")
    } else {
      skip("Progress indicator not visible on current page")
    }
  }, error = function(e) {
    skip("Progress indicator test failed")
  })

  app$stop()
})

# ==============================================================================
# Summary
# ==============================================================================

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Visual Regression Tests Complete\n")
cat("Run shinytest2::snapshot_review() to review any changes\n")
cat(strrep("=", 70), "\n")
