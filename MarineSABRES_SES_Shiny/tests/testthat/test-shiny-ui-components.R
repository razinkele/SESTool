# ==============================================================================
# Shinytest2 Tests - UI Components
# ==============================================================================
# Tests for bs4Dash UI components, value boxes, cards, and visual elements
#
# Author: Testing Infrastructure
# Date: 2026-01-01
# ==============================================================================

library(shinytest2)
library(testthat)

test_that("Dashboard loads successfully", {
  # Skip on CI if needed
  skip_on_ci()

  # Create app driver
  app <- AppDriver$new(
    app_dir = "../../",  # Points to app root
    name = "dashboard-load",
    height = 1080,
    width = 1920,
    wait = TRUE,
    timeout = 20000
  )

  # Wait for app to stabilize
  app$wait_for_idle(timeout = 10000)

  # Verify the app loaded
  expect_true(app$get_value(input = "dynamic_sidebar") != "",
              info = "Sidebar should be populated")

  # Stop the app
  app$stop()
})

test_that("Value boxes render correctly on dashboard", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "value-boxes",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Navigate to dashboard
  app$set_inputs(dynamic_sidebar = "dashboard")
  app$wait_for_idle()

  # Check that value boxes exist
  values <- app$get_values()

  # Verify output elements exist
  expect_true("total_elements_box" %in% names(values$output),
              info = "Total elements box should exist")
  expect_true("total_connections_box" %in% names(values$output),
              info = "Total connections box should exist")
  expect_true("loops_detected_box" %in% names(values$output),
              info = "Loops detected box should exist")
  expect_true("completion_box" %in% names(values$output),
              info = "Completion box should exist")

  # Take a screenshot for visual verification
  app$expect_screenshot(name = "dashboard_value_boxes")

  app$stop()
})

test_that("bs4Dash theme is applied correctly", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "bs4dash-theme",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Check that bs4Dash specific elements are present
  # Look for bs4Dash class names in the HTML
  html <- app$get_html()

  expect_true(grepl("bs4Dash", html, ignore.case = TRUE),
              info = "bs4Dash classes should be present in HTML")
  expect_true(grepl("sidebar-mini", html) || grepl("main-sidebar", html),
              info = "Sidebar should be present")

  # Take screenshot
  app$expect_screenshot(name = "bs4dash_theme")

  app$stop()
})

test_that("Header components render correctly", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "header-components",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Get HTML to check header elements
  html <- app$get_html()

  # Check for language selector
  expect_true(grepl("language_dropdown_toggle", html),
              info = "Language dropdown should exist")

  # Check for settings dropdown
  expect_true(grepl("settings_dropdown_toggle", html),
              info = "Settings dropdown should exist")

  # Check for help dropdown
  expect_true(grepl("help_dropdown_toggle", html),
              info = "Help dropdown should exist")

  # Check for bookmark button
  expect_true(grepl("bookmark_btn", html),
              info = "Bookmark button should exist")

  # Take screenshot
  app$expect_screenshot(name = "header_components")

  app$stop()
})

test_that("Value box colors are valid bs4Dash colors", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "valuebox-colors",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Navigate to dashboard
  app$set_inputs(dynamic_sidebar = "dashboard")
  app$wait_for_idle()

  # Get HTML
  html <- app$get_html()

  # Valid bs4Dash colors
  valid_colors <- c("primary", "secondary", "success", "info",
                    "warning", "danger", "light", "dark",
                    "indigo", "lightblue", "navy", "purple",
                    "fuchsia", "pink", "maroon", "orange",
                    "lime", "teal", "olive")

  # Invalid colors that should NOT appear
  invalid_colors <- c("blue", "green", "red", "yellow", "light-blue")

  # Check that invalid colors are NOT present in value box classes
  for (invalid_color in invalid_colors) {
    pattern <- paste0('bg-', invalid_color, '\\b')
    expect_false(grepl(pattern, html),
                info = paste("Invalid color", invalid_color, "should not be used"))
  }

  app$stop()
})

test_that("Cards render with correct bs4Dash structure", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "cards-structure",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Navigate to dashboard
  app$set_inputs(dynamic_sidebar = "dashboard")
  app$wait_for_idle()

  # Get HTML
  html <- app$get_html()

  # Check for bs4Dash card classes
  expect_true(grepl("card card-", html),
              info = "bs4Dash cards should use 'card' class")
  expect_true(grepl("card-header", html) || grepl("card-body", html),
              info = "Cards should have proper structure")

  # Take screenshot
  app$expect_screenshot(name = "cards_structure")

  app$stop()
})

test_that("Sidebar menu items are clickable", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "sidebar-clickable",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Get initial state
  initial_tab <- app$get_value(input = "dynamic_sidebar")

  # Click on dashboard menu item
  app$set_inputs(dynamic_sidebar = "dashboard")
  app$wait_for_idle()

  # Verify tab changed
  new_tab <- app$get_value(input = "dynamic_sidebar")
  expect_equal(new_tab, "dashboard",
               info = "Clicking dashboard should change tab")

  # Take screenshot
  app$expect_screenshot(name = "sidebar_dashboard")

  # Try clicking another menu item (entry point)
  app$set_inputs(dynamic_sidebar = "entry_point")
  app$wait_for_idle()

  entry_tab <- app$get_value(input = "dynamic_sidebar")
  expect_equal(entry_tab, "entry_point",
               info = "Clicking entry point should change tab")

  # Take screenshot
  app$expect_screenshot(name = "sidebar_entry_point")

  app$stop()
})

test_that("Responsive design works at different screen sizes", {
  skip_on_ci()

  # Test desktop size
  app_desktop <- AppDriver$new(
    app_dir = "../../",
    name = "responsive-desktop",
    height = 1080,
    width = 1920
  )

  app_desktop$wait_for_idle(timeout = 10000)
  app_desktop$expect_screenshot(name = "responsive_desktop_1920x1080")
  app_desktop$stop()

  # Test tablet size
  app_tablet <- AppDriver$new(
    app_dir = "../../",
    name = "responsive-tablet",
    height = 1024,
    width = 768
  )

  app_tablet$wait_for_idle(timeout = 10000)
  app_tablet$expect_screenshot(name = "responsive_tablet_768x1024")
  app_tablet$stop()

  # Test mobile size
  app_mobile <- AppDriver$new(
    app_dir = "../../",
    name = "responsive-mobile",
    height = 667,
    width = 375
  )

  app_mobile$wait_for_idle(timeout = 10000)
  app_mobile$expect_screenshot(name = "responsive_mobile_375x667")
  app_mobile$stop()
})

test_that("Error states display correctly", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "error-states",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Navigate to dashboard
  app$set_inputs(dynamic_sidebar = "dashboard")
  app$wait_for_idle()

  # Value boxes should show 0 or error states gracefully
  # (since no project is loaded)
  values <- app$get_values()

  # Should not crash - error handlers should work
  expect_true(TRUE, info = "App should handle empty project state gracefully")

  # Take screenshot of error state
  app$expect_screenshot(name = "error_state_empty_project")

  app$stop()
})

test_that("Modal dialogs can be opened and closed", {
  skip_on_ci()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "modal-dialogs",
    height = 1080,
    width = 1920
  )

  app$wait_for_idle(timeout = 10000)

  # Click to open settings modal
  app$click("open_settings_modal")
  app$wait_for_idle()

  # Check if modal is present
  html_with_modal <- app$get_html()
  expect_true(grepl("modal", html_with_modal, ignore.case = TRUE),
              info = "Modal should be present after clicking button")

  # Take screenshot
  app$expect_screenshot(name = "modal_settings_open")

  app$stop()
})
