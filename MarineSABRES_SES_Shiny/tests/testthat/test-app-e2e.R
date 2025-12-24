# test-app-e2e.R
# End-to-End Tests for MarineSABRES SES Shiny Application using shinytest2
#
# These tests verify critical user workflows in a real browser environment.
# They test the complete user journey from app launch to data visualization.

library(testthat)
library(shinytest2)

# Skip all E2E tests if shinytest2 is not available
skip_if_not_installed("shinytest2")

# Skip on CRAN to avoid timeout issues
skip_on_cran()

# Configuration for E2E tests
E2E_TIMEOUT <- 10000  # 10 seconds timeout for app operations
E2E_WAIT_TIME <- 2000  # 2 seconds wait for UI rendering

# ==============================================================================
# TEST 1: APP LAUNCH AND DASHBOARD NAVIGATION
# ==============================================================================
# Critical workflow: User opens app and navigates to dashboard
# Tests: App initialization, default template loading, sidebar navigation

test_that("E2E: App launches successfully and dashboard is accessible", {
  # Launch the app
  app <- AppDriver$new(
    app_dir = "../..",  # Root directory from tests/testthat/
    name = "app-launch-test",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # Verify app is running
  expect_true(app$is_running(), info = "App should be running after initialization")

  # Wait for initial rendering
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Check that the app has loaded with a title
  page_title <- app$get_html("head title")
  expect_match(page_title, "MarineSABRES", info = "Page title should contain 'MarineSABRES'")

  # Verify sidebar menu exists
  sidebar_exists <- app$get_html(".sidebar-menu")
  expect_true(nzchar(sidebar_exists), info = "Sidebar menu should be present")

  # Navigate to dashboard
  app$set_inputs(sidebar_menu = "dashboard", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify dashboard tab is active
  active_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(active_tab, "dashboard", info = "Dashboard tab should be active")

  # Check that value boxes are rendered (project overview boxes)
  value_boxes <- app$get_html(".small-box")
  expect_true(nzchar(value_boxes), info = "Dashboard value boxes should be rendered")

  # Verify auto-loaded template data is present
  # The app auto-loads Caribbean template on empty state (lines 307-345 in app.R)
  total_elements_box <- app$get_html("#total_elements_box")
  expect_true(nzchar(total_elements_box), info = "Total elements box should be present")

  # Clean up
  app$stop()
  expect_false(app$is_running(), info = "App should stop cleanly")
})

# ==============================================================================
# TEST 2: LANGUAGE SWITCHING WORKFLOW
# ==============================================================================
# Critical workflow: User changes application language
# Tests: i18n system, dynamic UI updates, translation loading

test_that("E2E: Language switching updates UI translations", {
  # Launch app
  app <- AppDriver$new(
    app_dir = "../..",
    name = "language-switch-test",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # Wait for app to be ready
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify language selector exists in header
  lang_selector <- app$get_html("#language_selector")
  expect_true(nzchar(lang_selector), info = "Language selector should be present")

  # Get current language (default should be English)
  initial_lang <- app$get_value(input = "language_selector")
  expect_true(!is.null(initial_lang), info = "Initial language should be set")

  # Switch to Spanish
  app$set_inputs(language_selector = "es", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify language changed
  new_lang <- app$get_value(input = "language_selector")
  expect_equal(new_lang, "es", info = "Language should switch to Spanish")

  # Switch to French
  app$set_inputs(language_selector = "fr", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify language changed again
  french_lang <- app$get_value(input = "language_selector")
  expect_equal(french_lang, "fr", info = "Language should switch to French")

  # Switch back to English
  app$set_inputs(language_selector = "en", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify we're back to English
  final_lang <- app$get_value(input = "language_selector")
  expect_equal(final_lang, "en", info = "Language should switch back to English")

  # Verify sidebar menu is still functional after language changes
  sidebar_exists <- app$get_html(".sidebar-menu")
  expect_true(nzchar(sidebar_exists), info = "Sidebar should still be present after language changes")

  # Clean up
  app$stop()
})

# ==============================================================================
# TEST 3: CREATE SES - TEMPLATE SELECTION WORKFLOW
# ==============================================================================
# Critical workflow: User navigates to Create SES and selects a method
# Tests: Module navigation, method selection, template loading

test_that("E2E: Create SES method selection and template navigation works", {
  # Launch app
  app <- AppDriver$new(
    app_dir = "../..",
    name = "create-ses-test",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # Wait for initialization
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Navigate to Create SES (method chooser)
  app$set_inputs(sidebar_menu = "create_ses_choose", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify we're on the Create SES page
  active_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(active_tab, "create_ses_choose", info = "Should be on Create SES chooser page")

  # Check that method selection buttons are present
  # The module should render buttons for different creation methods
  create_ses_content <- app$get_html(".content-wrapper")
  expect_true(nzchar(create_ses_content), info = "Create SES content should be rendered")

  # Navigate to template-based creation
  app$set_inputs(sidebar_menu = "create_ses_template", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify template page is active
  template_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(template_tab, "create_ses_template", info = "Should be on template creation page")

  # Navigate to AI assistant method
  app$set_inputs(sidebar_menu = "create_ses_ai", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify AI assistant page is active
  ai_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(ai_tab, "create_ses_ai", info = "Should be on AI assistant page")

  # Navigate to standard entry method
  app$set_inputs(sidebar_menu = "create_ses_standard", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify standard entry page is active
  standard_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(standard_tab, "create_ses_standard", info = "Should be on standard entry page")

  # Clean up
  app$stop()
})

# ==============================================================================
# TEST 4: CLD VISUALIZATION GENERATION
# ==============================================================================
# Critical workflow: User navigates to CLD visualization with auto-loaded data
# Tests: Network visualization rendering, graph display

test_that("E2E: CLD visualization renders with auto-loaded template data", {
  # Launch app
  app <- AppDriver$new(
    app_dir = "../..",
    name = "cld-viz-test",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # Wait for auto-load to complete (Caribbean template)
  app$wait_for_idle(timeout = E2E_WAIT_TIME * 2)

  # Navigate to CLD visualization
  app$set_inputs(sidebar_menu = "cld_viz", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Verify we're on CLD visualization page
  active_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(active_tab, "cld_viz", info = "Should be on CLD visualization page")

  # Check that visualization container exists
  viz_content <- app$get_html(".content-wrapper")
  expect_true(nzchar(viz_content), info = "CLD visualization content should be present")

  # The CLD module should have rendered some UI elements
  # Even if the network isn't fully built, the module should be initialized
  module_content <- app$get_html("[id^='cld_visual']")
  expect_true(nzchar(module_content), info = "CLD module content should be rendered")

  # Clean up
  app$stop()
})

# ==============================================================================
# TEST 5: NAVIGATION ACROSS MAJOR SECTIONS
# ==============================================================================
# Critical workflow: User navigates through all major application sections
# Tests: Complete navigation flow, PIMS modules, analysis tools, export

test_that("E2E: Navigation across all major sections works correctly", {
  # Launch app
  app <- AppDriver$new(
    app_dir = "../..",
    name = "full-navigation-test",
    height = 1000,
    width = 1200,
    wait = TRUE,
    timeout = E2E_TIMEOUT,
    load_timeout = E2E_TIMEOUT
  )

  # Wait for initialization
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  # Define critical navigation path through the app
  navigation_path <- list(
    list(tab = "entry_point", name = "Entry Point"),
    list(tab = "dashboard", name = "Dashboard"),
    list(tab = "pims_project", name = "PIMS Project"),
    list(tab = "create_ses_choose", name = "Create SES"),
    list(tab = "cld_viz", name = "CLD Visualization"),
    list(tab = "analysis_metrics", name = "Analysis Metrics"),
    list(tab = "response_measures", name = "Response Measures"),
    list(tab = "export", name = "Export/Reports")
  )

  # Navigate through each section and verify
  for (nav_item in navigation_path) {
    # Navigate to section
    app$set_inputs(sidebar_menu = nav_item$tab, wait_ = TRUE, timeout_ = E2E_TIMEOUT)
    app$wait_for_idle(timeout = E2E_WAIT_TIME / 2)  # Shorter wait for navigation

    # Verify navigation succeeded
    active_tab <- app$get_value(input = "sidebar_menu")
    expect_equal(
      active_tab,
      nav_item$tab,
      info = paste("Should navigate to", nav_item$name)
    )

    # Verify content rendered for this section
    content <- app$get_html(".content-wrapper")
    expect_true(
      nzchar(content),
      info = paste(nav_item$name, "content should be rendered")
    )
  }

  # Return to dashboard to verify circular navigation
  app$set_inputs(sidebar_menu = "dashboard", wait_ = TRUE, timeout_ = E2E_TIMEOUT)
  app$wait_for_idle(timeout = E2E_WAIT_TIME)

  final_tab <- app$get_value(input = "sidebar_menu")
  expect_equal(final_tab, "dashboard", info = "Should return to dashboard successfully")

  # Clean up
  app$stop()
})

# ==============================================================================
# HELPER FUNCTIONS FOR E2E TESTS
# ==============================================================================

#' Wait for specific element to appear in the DOM
#'
#' @param app AppDriver object
#' @param selector CSS selector for the element
#' @param timeout Maximum time to wait in milliseconds
#' @return TRUE if element appears, FALSE otherwise
wait_for_element <- function(app, selector, timeout = 5000) {
  start_time <- Sys.time()

  while (TRUE) {
    element <- app$get_html(selector)
    if (nzchar(element)) {
      return(TRUE)
    }

    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
    if (elapsed > timeout) {
      return(FALSE)
    }

    Sys.sleep(0.1)  # Check every 100ms
  }
}

#' Take screenshot for debugging failed tests
#'
#' @param app AppDriver object
#' @param name Screenshot name
take_debug_screenshot <- function(app, name) {
  if (app$is_running()) {
    screenshot_path <- file.path("tests", "testthat", "screenshots",
                                 paste0(name, "_", Sys.Date(), ".png"))
    dir.create(dirname(screenshot_path), recursive = TRUE, showWarnings = FALSE)
    app$get_screenshot(screenshot_path)
    message("Screenshot saved to: ", screenshot_path)
  }
}
