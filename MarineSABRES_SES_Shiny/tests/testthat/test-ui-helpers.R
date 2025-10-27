# test-ui-helpers.R
# Unit tests for UI helper functions

library(testthat)
library(shiny)

# Source UI helpers if available
if (file.exists("../../functions/ui_helpers.R")) {
  source("../../functions/ui_helpers.R", local = TRUE)
}

test_that("create_info_box creates valid UI element", {
  skip_if_not(exists("create_info_box"))

  info_box <- create_info_box(
    title = "Test Title",
    content = "Test content",
    icon = "info-circle"
  )

  expect_shiny_tag(info_box)
})

test_that("create_value_card creates valid UI element", {
  skip_if_not(exists("create_value_card"))

  value_card <- create_value_card(
    value = 42,
    title = "Test Metric",
    icon = "chart-line"
  )

  expect_shiny_tag(value_card)
})

test_that("create_action_button_with_tooltip works", {
  skip_if_not(exists("create_action_button_with_tooltip"))

  button <- create_action_button_with_tooltip(
    inputId = "test_btn",
    label = "Click Me",
    tooltip = "This is a tooltip",
    icon = icon("save")
  )

  expect_shiny_tag(button)
})

test_that("format_number_display formats numbers correctly", {
  skip_if_not(exists("format_number_display"))

  expect_equal(format_number_display(1000), "1,000")
  expect_equal(format_number_display(1234567), "1,234,567")
  expect_equal(format_number_display(42.5), "42.5")
})

test_that("create_tooltip creates valid tooltip", {
  skip_if_not(exists("create_tooltip"))

  tooltip <- create_tooltip(
    element_id = "test_element",
    text = "Helpful tooltip text"
  )

  expect_shiny_tag(tooltip)
})

test_that("create_progress_indicator creates valid UI", {
  skip_if_not(exists("create_progress_indicator"))

  progress <- create_progress_indicator(
    current = 50,
    total = 100,
    label = "Progress"
  )

  expect_shiny_tag(progress)
})

test_that("create_notification_box creates valid notification", {
  skip_if_not(exists("create_notification_box"))

  notification <- create_notification_box(
    message = "Test notification",
    type = "info"
  )

  expect_shiny_tag(notification)
})

test_that("create_collapsible_section creates valid UI", {
  skip_if_not(exists("create_collapsible_section"))

  section <- create_collapsible_section(
    title = "Section Title",
    content = div("Content here")
  )

  expect_shiny_tag(section)
})

test_that("format_percentage formats percentages correctly", {
  skip_if_not(exists("format_percentage"))

  expect_equal(format_percentage(0.5), "50%")
  expect_equal(format_percentage(0.756), "75.6%")
  expect_equal(format_percentage(1), "100%")
})

test_that("create_help_text creates valid help element", {
  skip_if_not(exists("create_help_text"))

  help_text <- create_help_text("This is helpful information")

  expect_shiny_tag(help_text)
})
