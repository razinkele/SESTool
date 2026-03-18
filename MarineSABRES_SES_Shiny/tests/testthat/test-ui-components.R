# tests/testthat/test-ui-components.R
# Tests for Shared UI Component Library
# ==============================================================================

library(testthat)

# Source the file under test (requires shiny and bs4Dash from global.R)
skip_if_not(requireNamespace("shiny", quietly = TRUE), "shiny not available")
skip_if_not(requireNamespace("bs4Dash", quietly = TRUE), "bs4Dash not available")

library(shiny)
library(bs4Dash)

source("../../functions/ui_components.R", chdir = TRUE)

# ==============================================================================
# Mock i18n
# ==============================================================================

mock_i18n <- list(t = function(key) key)

# ==============================================================================
# Test: ses_analysis_box
# ==============================================================================

test_that("ses_analysis_box returns a shiny tag", {
  result <- ses_analysis_box("Test Title", p("content"))
  expect_true(inherits(result, "shiny.tag") || inherits(result, "shiny.tag.list"))
})

test_that("ses_analysis_box uses i18n when provided", {
  result <- ses_analysis_box("my.key", p("content"), i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("my.key", html))
})

test_that("ses_analysis_box works without i18n", {
  result <- ses_analysis_box("Raw Title", p("body"))
  html <- as.character(result)
  expect_true(grepl("Raw Title", html))
})

test_that("ses_analysis_box omits icon when icon_name is NULL", {
  result <- ses_analysis_box("No Icon", icon_name = NULL)
  # Should not error

  expect_true(inherits(result, "shiny.tag") || inherits(result, "shiny.tag.list"))
})

# ==============================================================================
# Test: ses_empty_state
# ==============================================================================

test_that("ses_empty_state returns a div with alert class", {
  result <- ses_empty_state("No data available")
  html <- as.character(result)
  expect_true(grepl("alert alert-info", html))
})

test_that("ses_empty_state uses correct status class", {
  result <- ses_empty_state("Warning!", status = "warning")
  html <- as.character(result)
  expect_true(grepl("alert-warning", html))
})

test_that("ses_empty_state includes subtitle when provided", {
  result <- ses_empty_state("Main message", subtitle = "Extra detail")
  html <- as.character(result)
  expect_true(grepl("Extra detail", html))
})

test_that("ses_empty_state translates message with i18n", {
  result <- ses_empty_state("my.message.key", i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("my.message.key", html))
})

test_that("ses_empty_state works without subtitle", {
  result <- ses_empty_state("Just a message")
  expect_true(inherits(result, "shiny.tag"))
})

# ==============================================================================
# Test: ses_action_buttons
# ==============================================================================

test_that("ses_action_buttons returns a fluidRow", {
  ns <- NS("test")
  result <- ses_action_buttons(ns, "run", "Run Analysis")
  expect_true(inherits(result, "shiny.tag"))
  html <- as.character(result)
  expect_true(grepl("test-run", html))
})

test_that("ses_action_buttons includes secondary button when specified", {
  ns <- NS("test")
  result <- ses_action_buttons(ns, "run", "Run",
                                secondary_id = "reset",
                                secondary_label = "Reset")
  html <- as.character(result)
  expect_true(grepl("test-run", html))
  expect_true(grepl("test-reset", html))
})

test_that("ses_action_buttons translates labels with i18n", {
  ns <- NS("test")
  result <- ses_action_buttons(ns, "go", "common.go",
                                i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("common.go", html))
})

test_that("ses_action_buttons uses full width without secondary button", {
  ns <- NS("test")
  result <- ses_action_buttons(ns, "run", "Run")
  html <- as.character(result)
  # Without secondary, primary gets col-sm-12
  expect_true(grepl("col-sm-12", html))
})

# ==============================================================================
# Test: ses_status_badge
# ==============================================================================

test_that("ses_status_badge returns a span with badge class", {
  result <- ses_status_badge("ready")
  html <- as.character(result)
  expect_true(grepl("badge badge-success", html))
})

test_that("ses_status_badge applies correct status colors", {
  statuses <- list(
    ready = "success",
    stale = "warning",
    empty = "secondary",
    error = "danger",
    running = "info"
  )

  for (status in names(statuses)) {
    result <- ses_status_badge(status)
    html <- as.character(result)
    expect_true(grepl(paste0("badge-", statuses[[status]]), html),
                info = paste("Status", status, "should have color", statuses[[status]]))
  }
})

test_that("ses_status_badge uses custom label when provided", {
  result <- ses_status_badge("ready", label = "All good")
  html <- as.character(result)
  expect_true(grepl("All good", html))
})

test_that("ses_status_badge uses default label when label is NULL", {
  result <- ses_status_badge("empty")
  html <- as.character(result)
  expect_true(grepl("No data", html))
})

test_that("ses_status_badge running status has spinner icon", {
  result <- ses_status_badge("running")
  html <- as.character(result)
  expect_true(grepl("fa-spin", html))
})

# ==============================================================================
# Test: ses_info_callout
# ==============================================================================

test_that("ses_info_callout returns a styled div", {
  result <- ses_info_callout(p("Some info"))
  html <- as.character(result)
  expect_true(grepl("border-left", html))
  expect_true(grepl("#e8f4f8", html))  # info background
})

test_that("ses_info_callout uses correct colors for each status", {
  result_warning <- ses_info_callout(p("warn"), status = "warning")
  html <- as.character(result_warning)
  expect_true(grepl("#fff3cd", html))

  result_danger <- ses_info_callout(p("danger"), status = "danger")
  html2 <- as.character(result_danger)
  expect_true(grepl("#f8d7da", html2))
})

test_that("ses_info_callout contains child elements", {
  result <- ses_info_callout(h5("Title"), p("Body text"))
  html <- as.character(result)
  expect_true(grepl("Title", html))
  expect_true(grepl("Body text", html))
})

# ==============================================================================
# Test: ses_well_section
# ==============================================================================

test_that("ses_well_section returns a wellPanel", {
  result <- ses_well_section("Section Title", p("content"))
  html <- as.character(result)
  expect_true(grepl("well", html))
  expect_true(grepl("Section Title", html))
})

test_that("ses_well_section includes subtitle when provided", {
  result <- ses_well_section("Title", p("body"), subtitle = "Description text")
  html <- as.character(result)
  expect_true(grepl("Description text", html))
  expect_true(grepl("text-muted", html))
})

test_that("ses_well_section includes icon when provided", {
  result <- ses_well_section("Title", icon_name = "chart-pie")
  html <- as.character(result)
  expect_true(grepl("chart-pie", html))
})

test_that("ses_well_section translates with i18n", {
  result <- ses_well_section("my.section.key", i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("my.section.key", html))
})

# ==============================================================================
# Test: ses_download_buttons
# ==============================================================================

test_that("ses_download_buttons creates download buttons", {
  ns <- NS("test")
  buttons <- list(
    list(id = "dl_excel", label = "Excel"),
    list(id = "dl_pdf", label = "PDF")
  )
  result <- ses_download_buttons(ns, buttons)
  html <- as.character(result)
  expect_true(grepl("test-dl_excel", html))
  expect_true(grepl("test-dl_pdf", html))
})

test_that("ses_download_buttons translates labels with i18n", {
  ns <- NS("mod")
  buttons <- list(
    list(id = "dl1", label = "common.download")
  )
  result <- ses_download_buttons(ns, buttons, i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("common.download", html))
})

# ==============================================================================
# Test: ses_ml_feedback_buttons
# ==============================================================================

test_that("ses_ml_feedback_buttons returns a span with two buttons", {
  ns <- NS("test")
  result <- ses_ml_feedback_buttons(ns, prediction_id = "pred_1")
  html <- as.character(result)
  expect_true(grepl("ml-feedback-buttons", html))
  expect_true(grepl("thumbs-up", html))
  expect_true(grepl("thumbs-down", html))
})

test_that("ses_ml_feedback_buttons includes prediction_id in onclick", {
  ns <- NS("test")
  result <- ses_ml_feedback_buttons(ns, prediction_id = "my_pred")
  html <- as.character(result)
  expect_true(grepl("my_pred", html))
})

test_that("ses_ml_feedback_buttons translates tooltips with i18n", {
  ns <- NS("test")
  result <- ses_ml_feedback_buttons(ns, "pred_1", i18n = mock_i18n)
  html <- as.character(result)
  expect_true(grepl("modules.graphical_ses_creator.feedback_correct", html))
  expect_true(grepl("modules.graphical_ses_creator.feedback_incorrect", html))
})
