# tests/testthat/test-accessibility.R
# Tests for ARIA accessibility features (P0 Accessibility)
#
# These tests verify:
# 1. ARIA helper functions work correctly
# 2. Screen reader text generation
# 3. Navigation landmarks
# 4. Focus management helpers

library(testthat)

# ============================================================================
# ARIA HELPER FUNCTION TESTS
# ============================================================================

test_that("add_aria_attributes function exists", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  expect_true(is.function(add_aria_attributes))
})

test_that("add_aria_attributes adds label attribute", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$button("Click me")
  result <- add_aria_attributes(tag, label = "Submit form button")

  html_str <- as.character(result)
  expect_true(grepl('aria-label="Submit form button"', html_str))
})

test_that("add_aria_attributes adds role attribute", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$div("Content")
  result <- add_aria_attributes(tag, role = "navigation")

  html_str <- as.character(result)
  expect_true(grepl('role="navigation"', html_str))
})

test_that("add_aria_attributes adds multiple attributes", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$section("Section content")
  result <- add_aria_attributes(
    tag,
    label = "Main content",
    role = "main",
    describedby = "section-desc"
  )

  html_str <- as.character(result)
  expect_true(grepl('aria-label="Main content"', html_str))
  expect_true(grepl('role="main"', html_str))
  expect_true(grepl('aria-describedby="section-desc"', html_str))
})

test_that("add_aria_attributes handles expanded state", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$button("Menu")

  # Expanded = true
  result1 <- add_aria_attributes(tag, expanded = TRUE)
  html_str1 <- as.character(result1)
  expect_true(grepl('aria-expanded="true"', html_str1))

  # Expanded = false
  result2 <- add_aria_attributes(tag, expanded = FALSE)
  html_str2 <- as.character(result2)
  expect_true(grepl('aria-expanded="false"', html_str2))
})

test_that("add_aria_attributes handles controls attribute", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$button("Toggle panel")
  result <- add_aria_attributes(tag, controls = "panel-content")

  html_str <- as.character(result)
  expect_true(grepl('aria-controls="panel-content"', html_str))
})

test_that("add_aria_attributes handles live region", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  tag <- tags$div("Status message")
  result <- add_aria_attributes(tag, live = "polite")

  html_str <- as.character(result)
  expect_true(grepl('aria-live="polite"', html_str))
})

test_that("add_aria_attributes returns unchanged non-tag input", {
  skip_if_not(exists("add_aria_attributes", mode = "function"),
              "add_aria_attributes function not available")

  # Should handle gracefully
  result <- add_aria_attributes("not a tag", label = "test")
  expect_equal(result, "not a tag")
})

# ============================================================================
# ARIA NAVIGATION TESTS
# ============================================================================

test_that("aria_nav function exists", {
  skip_if_not(exists("aria_nav", mode = "function"),
              "aria_nav function not available")

  expect_true(is.function(aria_nav))
})

test_that("aria_nav creates navigation element", {
  skip_if_not(exists("aria_nav", mode = "function"),
              "aria_nav function not available")

  nav <- aria_nav(tags$ul(tags$li("Item")), label = "Main navigation")

  html_str <- as.character(nav)
  expect_true(grepl("<nav", html_str))
  expect_true(grepl('role="navigation"', html_str))
  expect_true(grepl('aria-label="Main navigation"', html_str))
})

test_that("aria_nav accepts optional id", {
  skip_if_not(exists("aria_nav", mode = "function"),
              "aria_nav function not available")

  nav <- aria_nav(tags$a("Link"), label = "Secondary", id = "nav-secondary")

  html_str <- as.character(nav)
  expect_true(grepl('id="nav-secondary"', html_str))
})

# ============================================================================
# ARIA BUTTON TESTS
# ============================================================================

test_that("aria_button function exists", {
  skip_if_not(exists("aria_button", mode = "function"),
              "aria_button function not available")

  expect_true(is.function(aria_button))
})

test_that("aria_button creates accessible button", {
  skip_if_not(exists("aria_button", mode = "function"),
              "aria_button function not available")

  btn <- aria_button("my_btn", "Click me")

  expect_true(inherits(btn, "shiny.tag") || inherits(btn, "shiny.tag.list"))
  html_str <- as.character(btn)
  expect_true(grepl('aria-label', html_str))
})

test_that("aria_button uses custom aria_label", {
  skip_if_not(exists("aria_button", mode = "function"),
              "aria_button function not available")

  btn <- aria_button("save_btn", "Save", aria_label = "Save current document")

  html_str <- as.character(btn)
  expect_true(grepl('aria-label="Save current document"', html_str))
})

# ============================================================================
# ARIA STATUS TESTS
# ============================================================================

test_that("aria_status function exists", {
  skip_if_not(exists("aria_status", mode = "function"),
              "aria_status function not available")

  expect_true(is.function(aria_status))
})
test_that("aria_status creates live region", {
  skip_if_not(exists("aria_status", mode = "function"),
              "aria_status function not available")

  status <- aria_status("status_region", "Loading...")

  html_str <- as.character(status)
  expect_true(grepl('role="status"', html_str))
  expect_true(grepl('aria-live', html_str))
  expect_true(grepl('aria-atomic="true"', html_str))
})

test_that("aria_status supports assertive mode", {
  skip_if_not(exists("aria_status", mode = "function"),
              "aria_status function not available")

  status <- aria_status("alert_region", "", live = "assertive")

  html_str <- as.character(status)
  expect_true(grepl('aria-live="assertive"', html_str))
})

# ============================================================================
# SCREEN READER ONLY TESTS
# ============================================================================

test_that("sr_only function exists", {
  skip_if_not(exists("sr_only", mode = "function"),
              "sr_only function not available")

  expect_true(is.function(sr_only))
})

test_that("sr_only creates visually hidden span", {
  skip_if_not(exists("sr_only", mode = "function"),
              "sr_only function not available")

  element <- sr_only("Screen reader text")

  html_str <- as.character(element)
  expect_true(grepl('class="sr-only"', html_str))
  expect_true(grepl("Screen reader text", html_str))
})

# ============================================================================
# CSS CLASS TESTS
# ============================================================================

test_that("custom.css contains sr-only class", {
  css_path <- file.path(getwd(), "www", "custom.css")

  skip_if_not(file.exists(css_path),
              "custom.css file not found")

  css_content <- readLines(css_path)
  css_text <- paste(css_content, collapse = "\n")

  expect_true(grepl("\\.sr-only", css_text))
})

test_that("custom.css contains focus-visible styles", {
  css_path <- file.path(getwd(), "www", "custom.css")

  skip_if_not(file.exists(css_path),
              "custom.css file not found")

  css_content <- readLines(css_path)
  css_text <- paste(css_content, collapse = "\n")

  expect_true(grepl("focus-visible", css_text))
})

test_that("custom.css supports reduced motion", {
  css_path <- file.path(getwd(), "www", "custom.css")

  skip_if_not(file.exists(css_path),
              "custom.css file not found")

  css_content <- readLines(css_path)
  css_text <- paste(css_content, collapse = "\n")

  expect_true(grepl("prefers-reduced-motion", css_text))
})

test_that("custom.css supports high contrast", {
  css_path <- file.path(getwd(), "www", "custom.css")

  skip_if_not(file.exists(css_path),
              "custom.css file not found")

  css_content <- readLines(css_path)
  css_text <- paste(css_content, collapse = "\n")

  expect_true(grepl("prefers-contrast", css_text))
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("complete accessible form element", {
  skip_if_not(exists("add_aria_attributes", mode = "function") &&
              exists("sr_only", mode = "function"),
              "Accessibility functions not available")

  # Create accessible form field
  label_text <- sr_only("Email address input")
  input <- tags$input(type = "email", id = "email", placeholder = "Enter email")
  accessible_input <- add_aria_attributes(
    input,
    label = "Email address",
    describedby = "email-help"
  )

  # Verify structure
  expect_true(inherits(label_text, "shiny.tag"))
  expect_true(inherits(accessible_input, "shiny.tag"))

  # Verify ARIA attributes
  html_str <- as.character(accessible_input)
  expect_true(grepl('aria-label', html_str))
  expect_true(grepl('aria-describedby', html_str))
})

test_that("accessible navigation with multiple items", {
  skip_if_not(exists("aria_nav", mode = "function"),
              "aria_nav function not available")

  nav <- aria_nav(
    tags$ul(
      tags$li(tags$a(href = "#home", "Home")),
      tags$li(tags$a(href = "#about", "About")),
      tags$li(tags$a(href = "#contact", "Contact"))
    ),
    label = "Primary site navigation",
    id = "primary-nav"
  )

  html_str <- as.character(nav)

  # Should have proper ARIA attributes
  expect_true(grepl('role="navigation"', html_str))
  expect_true(grepl('aria-label="Primary site navigation"', html_str))
  expect_true(grepl('id="primary-nav"', html_str))

  # Should contain navigation items
  expect_true(grepl("Home", html_str))
  expect_true(grepl("About", html_str))
  expect_true(grepl("Contact", html_str))
})
