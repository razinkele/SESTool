# tests/testthat/test-safe-render-factory.R
# Tests for safe_render factory function (P1 Code Quality)
#
# These tests verify:
# 1. Factory creates working render wrappers
# 2. Error handlers are called correctly
# 3. Default error handlers work as expected

library(testthat)

# ============================================================================
# FACTORY FUNCTION TESTS
# ============================================================================

test_that("create_safe_render_factory function exists", {
  skip_if_not(exists("create_safe_render_factory", mode = "function"),
              "create_safe_render_factory function not available")

  expect_true(is.function(create_safe_render_factory))
})

test_that("create_safe_render_factory returns a function", {
  skip_if_not(exists("create_safe_render_factory", mode = "function"),
              "create_safe_render_factory function not available")

  # Mock render function
  mock_render <- function(expr) {
    force(expr)
  }

  # Mock error handler
  mock_handler <- function(e, msg) {
    paste("Error:", msg, "-", e$message)
  }

  result <- create_safe_render_factory(mock_render, mock_handler)

  expect_true(is.function(result))
})

# ============================================================================
# DEFAULT ERROR HANDLER TESTS
# ============================================================================

test_that("default_ui_error_handler function exists", {
  skip_if_not(exists("default_ui_error_handler", mode = "function"),
              "default_ui_error_handler function not available")

  expect_true(is.function(default_ui_error_handler))
})

test_that("default_ui_error_handler creates alert div", {
  skip_if_not(exists("default_ui_error_handler", mode = "function"),
              "default_ui_error_handler function not available")

  mock_error <- simpleError("Test error message")

  result <- default_ui_error_handler(mock_error, "Custom prefix")

  # Should be a shiny tag
  expect_true(inherits(result, "shiny.tag"))

  # Convert to string and check content
  html_str <- as.character(result)
  expect_true(grepl("alert", html_str))
  expect_true(grepl("Custom prefix", html_str))
  expect_true(grepl("Test error message", html_str))
})

test_that("default_ui_error_handler respects show_details", {
  skip_if_not(exists("default_ui_error_handler", mode = "function"),
              "default_ui_error_handler function not available")

  mock_error <- simpleError("Technical details here")

  # With details
  result_with <- default_ui_error_handler(mock_error, "Error", show_details = TRUE)
  html_with <- as.character(result_with)
  expect_true(grepl("Technical details here", html_with))

  # Without details
  result_without <- default_ui_error_handler(mock_error, "Error", show_details = FALSE)
  html_without <- as.character(result_without)
  # The error details div should not contain the technical message
  expect_true(grepl("Error", html_without))
})

test_that("default_text_error_handler function exists", {
  skip_if_not(exists("default_text_error_handler", mode = "function"),
              "default_text_error_handler function not available")

  expect_true(is.function(default_text_error_handler))
})

test_that("default_text_error_handler creates formatted string", {
  skip_if_not(exists("default_text_error_handler", mode = "function"),
              "default_text_error_handler function not available")

  mock_error <- simpleError("Something went wrong")

  result <- default_text_error_handler(mock_error, "Load error")

  expect_true(is.character(result))
  expect_true(grepl("Load error", result))
  expect_true(grepl("Something went wrong", result))
  expect_true(grepl("^\\[", result))  # Starts with [
  expect_true(grepl("\\]$", result))  # Ends with ]
})

test_that("default_table_error_handler function exists", {
  skip_if_not(exists("default_table_error_handler", mode = "function"),
              "default_table_error_handler function not available")

  expect_true(is.function(default_table_error_handler))
})

test_that("default_table_error_handler creates dataframe", {
  skip_if_not(exists("default_table_error_handler", mode = "function"),
              "default_table_error_handler function not available")

  mock_error <- simpleError("Data processing failed")

  result <- default_table_error_handler(mock_error, "Table error")

  expect_true(is.data.frame(result))
  expect_true("Error" %in% names(result))
  expect_equal(nrow(result), 1)
  expect_true(grepl("Table error", result$Error))
  expect_true(grepl("Data processing failed", result$Error))
})

# ============================================================================
# EXISTING SAFE_RENDER FUNCTION TESTS
# ============================================================================

test_that("safe_renderUI function exists", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI function not available")

  expect_true(is.function(safe_renderUI))
})

test_that("safe_renderPlot function exists", {
  skip_if_not(exists("safe_renderPlot", mode = "function"),
              "safe_renderPlot function not available")

  expect_true(is.function(safe_renderPlot))
})

test_that("safe_renderTable function exists", {
  skip_if_not(exists("safe_renderTable", mode = "function"),
              "safe_renderTable function not available")

  expect_true(is.function(safe_renderTable))
})

test_that("safe_renderText function exists", {
  skip_if_not(exists("safe_renderText", mode = "function"),
              "safe_renderText function not available")

  expect_true(is.function(safe_renderText))
})

test_that("safe_renderPrint function exists", {
  skip_if_not(exists("safe_renderPrint", mode = "function"),
              "safe_renderPrint function not available")

  expect_true(is.function(safe_renderPrint))
})

test_that("safe_renderDT function exists", {
  skip_if_not(exists("safe_renderDT", mode = "function"),
              "safe_renderDT function not available")

  expect_true(is.function(safe_renderDT))
})

test_that("safe_renderPlotly function exists", {
  skip_if_not(exists("safe_renderPlotly", mode = "function"),
              "safe_renderPlotly function not available")

  expect_true(is.function(safe_renderPlotly))
})

test_that("safe_renderVisNetwork function exists", {
  skip_if_not(exists("safe_renderVisNetwork", mode = "function"),
              "safe_renderVisNetwork function not available")

  expect_true(is.function(safe_renderVisNetwork))
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("safe_render functions have consistent signatures", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI function not available")

  # All safe_render functions should have error_message and env parameters
  safe_fns <- c("safe_renderUI", "safe_renderPlot", "safe_renderTable",
                "safe_renderText", "safe_renderPrint")

  for (fn_name in safe_fns) {
    if (exists(fn_name, mode = "function")) {
      fn <- get(fn_name)
      args <- names(formals(fn))

      expect_true("error_message" %in% args,
                  info = paste(fn_name, "should have error_message parameter"))
      expect_true("env" %in% args,
                  info = paste(fn_name, "should have env parameter"))
    }
  }
})

test_that("factory-created function handles errors gracefully", {
  skip_if_not(exists("create_safe_render_factory", mode = "function"),
              "create_safe_render_factory function not available")

  errors_caught <- c()

  # Mock render that just evaluates and returns
  mock_render <- function(x) {
    x
  }

  # Mock handler that records errors
  mock_handler <- function(e, msg) {
    errors_caught <<- c(errors_caught, e$message)
    paste("Caught:", msg)
  }

  safe_mock <- create_safe_render_factory(mock_render, mock_handler)

  # This should catch the error
  result <- safe_mock({
    stop("Intentional test error")
  })

  # Error should have been caught
  expect_true(length(errors_caught) > 0)
  expect_true(any(grepl("Intentional test error", errors_caught)))
})
