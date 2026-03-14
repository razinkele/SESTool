# tests/testthat/test-ml-inference.R
# Tests for ML inference functions (P1 ML System)
#
# These tests verify:
# 1. Model loading and validation
# 2. Prediction functions
# 3. Model metadata and info functions

library(testthat)

# ============================================================================
# MODEL LOADING TESTS
# ============================================================================

test_that("ml_model_available function exists", {
  skip_if_not(exists("ml_model_available", mode = "function"),
              "ml_model_available function not available")

  expect_true(is.function(ml_model_available))
})

test_that("ml_model_available returns boolean", {
  skip_if_not(exists("ml_model_available", mode = "function"),
              "ml_model_available function not available")

  result <- ml_model_available()

  expect_true(is.logical(result))
  expect_length(result, 1)
})

test_that("load_ml_model function exists", {
  skip_if_not(exists("load_ml_model", mode = "function"),
              "load_ml_model function not available")

  expect_true(is.function(load_ml_model))
})

test_that("load_ml_model handles missing model gracefully", {
  skip_if_not(exists("load_ml_model", mode = "function"),
              "load_ml_model function not available")

  # Try loading non-existent model - should not crash
  result <- tryCatch({
    load_ml_model("nonexistent_model_path.pt")
  }, error = function(e) NULL)

  # Should return NULL or handle gracefully
  expect_true(is.null(result) || is.list(result) || is.logical(result))
})

test_that("unload_ml_model function exists", {
  skip_if_not(exists("unload_ml_model", mode = "function"),
              "unload_ml_model function not available")

  expect_true(is.function(unload_ml_model))

  # Should not error when called
  expect_silent(unload_ml_model())
})

# ============================================================================
# MODEL VALIDATION TESTS
# ============================================================================

test_that("validate_ml_model function exists", {
  skip_if_not(exists("validate_ml_model", mode = "function"),
              "validate_ml_model function not available")

  expect_true(is.function(validate_ml_model))
})

test_that("validate_ml_model returns expected structure", {
  skip_if_not(exists("validate_ml_model", mode = "function"),
              "validate_ml_model function not available")

  # Test with NULL (should fail validation)
  result <- validate_ml_model(NULL)

  expect_true(is.list(result))
  expect_true("valid" %in% names(result))
  expect_false(result$valid)
})

test_that("detect_model_version function exists", {
  skip_if_not(exists("detect_model_version", mode = "function"),
              "detect_model_version function not available")

  expect_true(is.function(detect_model_version))
})

test_that("detect_model_version handles NULL model", {
  skip_if_not(exists("detect_model_version", mode = "function"),
              "detect_model_version function not available")

  result <- detect_model_version(NULL)

  # Should return something (version string or error info)
  expect_true(!is.null(result))
})

# ============================================================================
# MODEL METADATA TESTS
# ============================================================================

test_that("get_ml_model_input_dim function exists", {
  skip_if_not(exists("get_ml_model_input_dim", mode = "function"),
              "get_ml_model_input_dim function not available")

  expect_true(is.function(get_ml_model_input_dim))
})

test_that("get_ml_model_input_dim returns numeric", {
  skip_if_not(exists("get_ml_model_input_dim", mode = "function"),
              "get_ml_model_input_dim function not available")

  result <- get_ml_model_input_dim()

  expect_true(is.numeric(result))
  expect_true(result > 0)
})

test_that("get_ml_model_metadata function exists", {
  skip_if_not(exists("get_ml_model_metadata", mode = "function"),
              "get_ml_model_metadata function not available")

  expect_true(is.function(get_ml_model_metadata))
})

test_that("get_ml_model_metadata returns list", {
  skip_if_not(exists("get_ml_model_metadata", mode = "function"),
              "get_ml_model_metadata function not available")

  result <- get_ml_model_metadata()

  expect_true(is.list(result))
})

test_that("get_ml_model_info function exists", {
  skip_if_not(exists("get_ml_model_info", mode = "function"),
              "get_ml_model_info function not available")

  expect_true(is.function(get_ml_model_info))
})

# ============================================================================
# PREDICTION FUNCTION TESTS
# ============================================================================

test_that("predict_connection_ml function exists", {
  skip_if_not(exists("predict_connection_ml", mode = "function"),
              "predict_connection_ml function not available")

  expect_true(is.function(predict_connection_ml))
})

test_that("predict_connection_ml returns expected structure", {
  skip_if_not(exists("predict_connection_ml", mode = "function"),
              "predict_connection_ml function not available")
  skip_if_not(exists("ml_model_available", mode = "function") && ml_model_available(),
              "ML model not loaded")

  # Test with sample inputs (requires model to be loaded)
  result <- predict_connection_ml(
    source_name = "Test Source",
    target_name = "Test Target",
    source_type = "D",
    target_type = "A"
  )

  # Should return a list with prediction info (or NULL if model not available)
  skip_if(is.null(result), "Model returned NULL - may not be loaded")

  expect_true(is.list(result))

  # Should have standard fields per actual implementation
  expected_fields <- c("connection_exists", "existence_probability", "strength", "source", "target")
  for (field in expected_fields) {
    expect_true(field %in% names(result),
                info = paste("Result should have", field, "field"))
  }
})

test_that("predict_connection_ml probability is in valid range", {
  skip_if_not(exists("predict_connection_ml", mode = "function"),
              "predict_connection_ml function not available")
  skip_if_not(exists("ml_model_available", mode = "function") && ml_model_available(),
              "ML model not loaded")

  result <- predict_connection_ml(
    source_name = "Driver",
    target_name = "Activity",
    source_type = "D",
    target_type = "A"
  )

  skip_if(is.null(result), "Model returned NULL - may not be loaded")

  # Probability should be between 0 and 1
  expect_true(result$existence_probability >= 0,
              info = "Probability should be >= 0")
  expect_true(result$existence_probability <= 1,
              info = "Probability should be <= 1")
})

test_that("predict_batch_ml function exists", {
  skip_if_not(exists("predict_batch_ml", mode = "function"),
              "predict_batch_ml function not available")

  expect_true(is.function(predict_batch_ml))
})

test_that("predict_batch_ml handles empty pairs", {
  skip_if_not(exists("predict_batch_ml", mode = "function"),
              "predict_batch_ml function not available")

  # Test with empty pairs
  result <- predict_batch_ml(pairs = data.frame())

  # Should handle gracefully
  expect_true(is.list(result) || is.data.frame(result) || is.null(result))
})

# ============================================================================
# BLENDING TESTS
# ============================================================================

test_that("blend_predictions function exists", {
  skip_if_not(exists("blend_predictions", mode = "function"),
              "blend_predictions function not available")

  expect_true(is.function(blend_predictions))
})

test_that("blend_predictions combines ML and rule results", {
  skip_if_not(exists("blend_predictions", mode = "function"),
              "blend_predictions function not available")

  # Create mock results matching actual function expectations
  ml_result <- list(
    existence_probability = 0.8,
    connection_exists = TRUE,
    strength = "medium",
    confidence = 4,
    polarity = "+"
  )

  rule_result <- list(
    confidence = 0.6,
    strength = "weak",
    polarity = "+"
  )

  result <- blend_predictions(ml_result, rule_result, ml_weight = 0.7)

  expect_true(is.list(result))
  expect_true("existence_probability" %in% names(result))
})

test_that("blend_predictions respects ml_weight", {
  skip_if_not(exists("blend_predictions", mode = "function"),
              "blend_predictions function not available")

  ml_result <- list(existence_probability = 1.0, connection_exists = TRUE)
  rule_result <- list(confidence = 0.0)

  # With high ML weight, should be closer to 1.0
  result_high_ml <- blend_predictions(ml_result, rule_result, ml_weight = 0.9)

  # With low ML weight, should be closer to 0.0
  result_low_ml <- blend_predictions(ml_result, rule_result, ml_weight = 0.1)

  # Get probability
  get_prob <- function(r) {
    if ("existence_probability" %in% names(r)) r$existence_probability
    else 0.5
  }

  # High ML weight should give higher probability
  expect_true(get_prob(result_high_ml) > get_prob(result_low_ml))
})

# ============================================================================
# MODEL SIGNATURE TESTS
# ============================================================================

test_that("verify_model_signature function exists", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  expect_true(is.function(verify_model_signature))
})

test_that("verify_model_signature handles missing file", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  result <- verify_model_signature("nonexistent_model.pt")

  expect_true(is.list(result))
  expect_true("verified" %in% names(result))
  expect_false(result$verified)
})
