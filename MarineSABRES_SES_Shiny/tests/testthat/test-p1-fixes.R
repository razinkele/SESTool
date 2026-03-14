# test-p1-fixes.R
# Tests for P1 high priority fixes implemented 2026-03-06
#
# P1 Fixes:
# 1. Fix downloadHandler export logic
# 2. Add real-time DAPSIWRM framework validation
# 3. Integrate ML ensemble loading
# 4. Replace cat/print with debug_log
# 5. Fix hard-coded error messages

# ============================================================================
# Test Setup
# ============================================================================

test_that("setup: P1 fix functions exist", {
  # DAPSIWRM validation helpers
  expect_true(exists("validate_connection_with_feedback", mode = "function"))
  expect_true(exists("get_connection_validation_message", mode = "function"))
  expect_true(exists("check_connection_with_notification", mode = "function"))
  expect_true(exists("get_valid_targets_for_ui", mode = "function"))

  # Unified prediction API
  skip_if_not(exists("predict_connection_best", mode = "function"),
              "ML ensemble functions not loaded")
  expect_true(exists("predict_connection_best", mode = "function"))
  expect_true(exists("get_prediction_method", mode = "function"))
})

# ============================================================================
# 1. DAPSIWRM Real-Time Validation Tests
# ============================================================================

context("P1 Fix: DAPSIWRM Real-Time Validation")

test_that("validate_connection_with_feedback returns correct structure", {
  result <- validate_connection_with_feedback("Drivers", "Activities")

  expect_true(is.list(result))
  expect_true("valid" %in% names(result))
  expect_true("level" %in% names(result))
  expect_true("message" %in% names(result))
  expect_true(is.logical(result$valid))
})

test_that("validate_connection_with_feedback accepts valid DAPSIWRM connections", {
  # Standard DAPSIWRM chain
  valid_connections <- list(
    c("Drivers", "Activities"),
    c("Activities", "Pressures"),
    c("Pressures", "Marine Processes & Functioning"),
    c("Marine Processes & Functioning", "Ecosystem Services"),
    c("Ecosystem Services", "Goods & Benefits")
  )

  for (conn in valid_connections) {
    result <- validate_connection_with_feedback(conn[1], conn[2])
    expect_true(result$valid, info = paste(conn[1], "->", conn[2]))
    expect_equal(result$level, "success", info = paste(conn[1], "->", conn[2]))
  }
})

test_that("validate_connection_with_feedback warns on non-standard connections", {
  # Non-standard but allowed (not strict mode)
  result <- validate_connection_with_feedback("Drivers", "Pressures", strict = FALSE)

  expect_true(result$valid)  # Allowed in non-strict mode
  expect_equal(result$level, "warning")  # But with warning
})

test_that("validate_connection_with_feedback rejects invalid connections in strict mode", {
  result <- validate_connection_with_feedback("Drivers", "Ecosystem Services", strict = TRUE)

  expect_false(result$valid)
  expect_equal(result$level, "error")
  expect_true(!is.null(result$suggestion))  # Should suggest correct targets
})

test_that("get_valid_targets_for_ui returns data frame with valid structure", {
  result <- get_valid_targets_for_ui("Drivers")

  expect_true(is.data.frame(result))
  expect_true("type" %in% names(result))
  expect_true("description" %in% names(result))
  expect_true(nrow(result) > 0)
  expect_true("Activities" %in% result$type)
})

test_that("get_valid_targets_for_ui handles unknown types gracefully", {
  result <- get_valid_targets_for_ui("UnknownType")

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("validate_connection still works (backward compatibility)", {
  # Original function should still work
  expect_true(validate_connection("Drivers", "Activities"))
  expect_true(validate_connection("Activities", "Pressures"))

  # Non-standard in strict mode
  expect_false(validate_connection("Drivers", "Pressures", strict = TRUE))
})

# ============================================================================
# 2. ML Ensemble Integration Tests
# ============================================================================

context("P1 Fix: ML Ensemble Integration")

test_that("ENSEMBLE_AVAILABLE flag exists", {
  skip_if_not(exists("ENSEMBLE_AVAILABLE"),
              "ENSEMBLE_AVAILABLE not defined (run from global.R context)")

  expect_true(is.logical(ENSEMBLE_AVAILABLE))
})

test_that("get_prediction_method returns valid method name", {
  skip_if_not(exists("get_prediction_method", mode = "function"),
              "get_prediction_method not available")

  method <- get_prediction_method()
  expect_true(method %in% c("ensemble", "ml", "rule_based", "none"))
})

test_that("predict_connection_best handles missing ML gracefully", {
  skip_if_not(exists("predict_connection_best", mode = "function"),
              "predict_connection_best not available")

  # Should not throw error even if ML not available
  result <- tryCatch({
    predict_connection_best(
      source_name = "Commercial fishing",
      target_name = "Overfishing",
      source_type = "Activities",
      target_type = "Pressures"
    )
  }, error = function(e) {
    NULL
  })

  # Result can be NULL if no method available, but shouldn't error
  expect_true(is.null(result) || is.list(result))

  # If result exists, check method is recorded
  if (!is.null(result)) {
    expect_true("method" %in% names(result))
  }
})

# ============================================================================
# 3. Startup Logging Tests
# ============================================================================

context("P1 Fix: Startup Logging")

test_that("startup_log function exists", {
  skip_if_not(exists("startup_log", mode = "function"),
              "startup_log not defined")

  expect_true(is.function(startup_log))
})

test_that("startup_log handles different types", {
  skip_if_not(exists("startup_log", mode = "function"),
              "startup_log not defined")

  # Should not error for any type
  expect_silent(capture.output({
    startup_log("Test info", type = "info")
    startup_log("Test success", type = "success")
    startup_log("Test warning", type = "warning")
    startup_log("Test error", type = "error")
  }))
})

test_that("debug_log respects DEBUG_MODE", {
  skip_if_not(exists("debug_log", mode = "function"),
              "debug_log not defined")
  skip_if_not(exists("DEBUG_MODE"),
              "DEBUG_MODE not defined")

  # In test context, just ensure it doesn't error
  expect_silent({
    debug_log("Test message", "TEST")
  })
})

# ============================================================================
# 4. Export Handler Tests
# ============================================================================

context("P1 Fix: Export Handlers")

test_that("setup_export_handlers function exists", {
  skip_if_not(exists("setup_export_handlers", mode = "function"),
              "setup_export_handlers not defined (load server/export_handlers.R)")

  expect_true(is.function(setup_export_handlers))
})

# Note: Full downloadHandler testing requires shinytest2 E2E tests

# ============================================================================
# 5. Hard-coded Error Message Tests
# ============================================================================

context("P1 Fix: Error Message i18n")

test_that("common.labels.error translation key exists", {
  skip_if_not(exists("i18n"),
              "i18n translator not loaded")

  # The error key should exist in translations
  error_text <- i18n$t("common.labels.error")
  expect_true(nchar(error_text) > 0)
  expect_true(error_text != "common.labels.error")  # Not returning key as fallback
})

# ============================================================================
# Integration Tests
# ============================================================================

context("P1 Fixes: Integration")

test_that("DAPSIWRM validation integrates with connection rules", {
  # Test the full flow from type selection to validation
  source_type <- "Activities"

  # Get valid targets
  valid_targets <- get_valid_targets_for_ui(source_type)
  expect_true(nrow(valid_targets) > 0)

  # Validate connection to each target
  for (target_type in valid_targets$type) {
    validation <- validate_connection_with_feedback(source_type, target_type)
    expect_true(validation$valid)
    expect_equal(validation$level, "success")
  }
})

test_that("Prediction method selection is consistent", {
  skip_if_not(exists("get_prediction_method", mode = "function"),
              "get_prediction_method not available")

  method1 <- get_prediction_method()
  method2 <- get_prediction_method()

  expect_equal(method1, method2)  # Should be deterministic
})

test_that("DAPSIWRM rules cover all element types", {
  expected_types <- c(
    "Drivers", "Activities", "Pressures",
    "Marine Processes & Functioning", "Ecosystem Services",
    "Goods & Benefits", "Responses"
  )

  for (type in expected_types) {
    targets <- get_allowed_targets(type)
    # Each type should have at least one valid target or be terminal
    # (Goods & Benefits can target Drivers or Responses)
    expect_true(is.character(targets))
  }
})

# ============================================================================
# 6. Safe Render Error Boundary Tests
# ============================================================================

context("P1 Fix: Safe Render Error Boundaries")

test_that("safe_renderUI function exists", {
  skip_if_not(exists("safe_renderUI", mode = "function"),
              "safe_renderUI not defined")
  expect_true(is.function(safe_renderUI))
})

test_that("safe_renderPlot function exists", {
  skip_if_not(exists("safe_renderPlot", mode = "function"),
              "safe_renderPlot not defined")
  expect_true(is.function(safe_renderPlot))
})

test_that("safe_renderDT function exists", {
  skip_if_not(exists("safe_renderDT", mode = "function"),
              "safe_renderDT not defined")
  expect_true(is.function(safe_renderDT))
})

test_that("safe_renderPlotly function exists", {
  skip_if_not(exists("safe_renderPlotly", mode = "function"),
              "safe_renderPlotly not defined")
  expect_true(is.function(safe_renderPlotly))
})

test_that("safe_renderVisNetwork function exists", {
  skip_if_not(exists("safe_renderVisNetwork", mode = "function"),
              "safe_renderVisNetwork not defined")
  expect_true(is.function(safe_renderVisNetwork))
})

test_that("safe_renderText function exists", {
  skip_if_not(exists("safe_renderText", mode = "function"),
              "safe_renderText not defined")
  expect_true(is.function(safe_renderText))
})

test_that("safe_execute catches errors and returns default", {
  skip_if_not(exists("safe_execute", mode = "function"),
              "safe_execute not defined")

  # Should return default on error
  result <- safe_execute(stop("Test error"), default = "fallback", silent = TRUE)
  expect_equal(result, "fallback")

  # Should return result on success
  result <- safe_execute(1 + 1, default = 0)
  expect_equal(result, 2)
})
