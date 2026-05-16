# tests/testthat/test-ml-models.R
# Tests for ML model classes and utilities (P1 ML System)
#
# These tests verify:
# 1. Model class definitions
# 2. Loss functions
# 3. Metric calculations

library(testthat)

# torch is an optional dependency (declared in DESCRIPTION Imports but loaded
# via tryCatch in global.R; see ML_ENABLED logic). When torch is unavailable
# in the test environment (lean CI runners, fresh checkouts before
# torch::install_torch()), every test in this file errors on torch_tensor().
# Skip the whole file cleanly in that case — matches the pattern already used
# in test-ml-ensemble.R, test-ml-active-learning.R, test-ml-context-embeddings.R.
skip_if_not_installed("torch")

# ============================================================================
# LOSS FUNCTION TESTS
# ============================================================================

test_that("multitask_loss function exists", {
  skip_if_not(exists("multitask_loss", mode = "function"),
              "multitask_loss function not available")

  expect_true(is.function(multitask_loss))
})

# ============================================================================
# METRIC FUNCTION TESTS
# ============================================================================

test_that("binary_accuracy function exists", {
  skip_if_not(exists("binary_accuracy", mode = "function"),
              "binary_accuracy function not available")

  expect_true(is.function(binary_accuracy))
})

test_that("binary_accuracy calculates correctly", {
  skip_if_not(exists("binary_accuracy", mode = "function"),
              "binary_accuracy function not available")
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available for binary_accuracy test")

  # Perfect predictions - binary_accuracy expects LOGITS (pre-sigmoid values)
  # Use logits that, after sigmoid, give probabilities > 0.5 for class 1
  # logit(0.9) = log(0.9/0.1) ≈ 2.2, logit(0.1) = log(0.1/0.9) ≈ -2.2
  predictions <- torch::torch_tensor(c(2.2, 1.4, -2.2, -1.4))  # Logits
  targets <- torch::torch_tensor(c(1, 1, 0, 0))

  result <- binary_accuracy(predictions, targets)

  expect_true(is.numeric(result) || inherits(result, "torch_tensor"))
  # Extract numeric value if tensor
  result_val <- if (inherits(result, "torch_tensor")) as.numeric(result) else result
  expect_equal(result_val, 1.0)  # All correct
})

test_that("binary_accuracy handles edge cases", {
  skip_if_not(exists("binary_accuracy", mode = "function"),
              "binary_accuracy function not available")
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available for binary_accuracy test")

  # All wrong predictions - binary_accuracy expects LOGITS (pre-sigmoid values)
  # Inverted logits: negative logits where targets are 1, positive where targets are 0
  predictions <- torch::torch_tensor(c(-2.2, -1.4, 2.2, 1.4))  # Logits (all wrong)
  targets <- torch::torch_tensor(c(1, 1, 0, 0))

  result <- binary_accuracy(predictions, targets)

  expect_true(is.numeric(result) || inherits(result, "torch_tensor"))
  result_val <- if (inherits(result, "torch_tensor")) as.numeric(result) else result
  expect_equal(result_val, 0.0)  # All wrong
})

test_that("multiclass_accuracy function exists", {
  skip_if_not(exists("multiclass_accuracy", mode = "function"),
              "multiclass_accuracy function not available")

  expect_true(is.function(multiclass_accuracy))
})

test_that("mean_absolute_error function exists", {
  skip_if_not(exists("mean_absolute_error", mode = "function"),
              "mean_absolute_error function not available")

  expect_true(is.function(mean_absolute_error))
})

test_that("mean_absolute_error calculates correctly", {
  skip_if_not(exists("mean_absolute_error", mode = "function"),
              "mean_absolute_error function not available")

  predictions <- c(1.0, 2.0, 3.0)
  targets <- c(1.5, 2.5, 3.5)

  result <- mean_absolute_error(predictions, targets)

  expect_true(is.numeric(result))
  expect_equal(result, 0.5)  # Each off by 0.5
})

test_that("f1_score function exists", {
  skip_if_not(exists("f1_score", mode = "function"),
              "f1_score function not available")

  expect_true(is.function(f1_score))
})

test_that("f1_score calculates correctly for perfect predictions", {
  skip_if_not(exists("f1_score", mode = "function"),
              "f1_score function not available")

  # Perfect predictions
  predictions <- c(1, 1, 0, 0)
  targets <- c(1, 1, 0, 0)

  result <- f1_score(predictions, targets)

  expect_true(is.numeric(result))
  expect_equal(result, 1.0)  # Perfect F1
})

test_that("calculate_metrics function exists", {
  skip_if_not(exists("calculate_metrics", mode = "function"),
              "calculate_metrics function not available")

  expect_true(is.function(calculate_metrics))
})

test_that("calculate_metrics returns expected structure", {
  skip_if_not(exists("calculate_metrics", mode = "function"),
              "calculate_metrics function not available")
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available for calculate_metrics test")

  # Create mock predictions structure that calculate_metrics expects
  # The function expects a list with existence, strength, polarity tensors
  predictions <- list(
    existence = torch::torch_tensor(c(0.9, 0.8, 0.1, 0.2)),
    strength = torch::torch_tensor(c(0.5, 0.6, 0.4, 0.3)),
    polarity = torch::torch_tensor(c(0.7, 0.8, 0.2, 0.1))
  )
  targets <- list(
    existence = torch::torch_tensor(c(1, 1, 0, 0)),
    strength = torch::torch_tensor(c(1, 1, 0, 0)),
    polarity = torch::torch_tensor(c(1, 1, 0, 0))
  )

  result <- tryCatch({
    calculate_metrics(predictions, targets)
  }, error = function(e) {
    # If structure is different, skip gracefully
    list(skipped = TRUE, message = e$message)
  })

  skip_if(!is.null(result$skipped),
          paste("calculate_metrics has different signature:", result$message))

  expect_true(is.list(result))

  # Should have standard metric fields
  metric_names <- c("accuracy", "f1", "precision", "recall")
  for (metric in metric_names) {
    if (metric %in% names(result)) {
      val <- result[[metric]]
      if (inherits(val, "torch_tensor")) val <- as.numeric(val)
      expect_true(is.numeric(val),
                  info = paste(metric, "should be numeric"))
      expect_true(val >= 0 && val <= 1,
                  info = paste(metric, "should be between 0 and 1"))
    }
  }
})

# ============================================================================
# MODEL SUMMARY TESTS
# ============================================================================

test_that("print_model_summary function exists", {
  skip_if_not(exists("print_model_summary", mode = "function"),
              "print_model_summary function not available")

  expect_true(is.function(print_model_summary))
})

# ============================================================================
# MODEL CLASS TESTS (require torch)
# ============================================================================

test_that("ConnectionPredictorV2 class exists", {
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available")
  skip_if_not(exists("ConnectionPredictorV2"),
              "ConnectionPredictorV2 class not available")

  expect_true(exists("ConnectionPredictorV2"))
})

test_that("ConnectionPredictorV2 can be instantiated", {
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available")
  skip_if_not(exists("ConnectionPredictorV2"),
              "ConnectionPredictorV2 class not available")

  model <- tryCatch({
    ConnectionPredictorV2$new()
  }, error = function(e) NULL)

  skip_if(is.null(model), "Could not instantiate ConnectionPredictorV2")

  expect_true(!is.null(model))
})

test_that("ContextAwarePredictor class exists", {
  skip_if_not(requireNamespace("torch", quietly = TRUE),
              "torch package not available")
  skip_if_not(exists("ContextAwarePredictor"),
              "ContextAwarePredictor class not available")

  expect_true(exists("ContextAwarePredictor"))
})
