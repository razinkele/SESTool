# tests/testthat/test-ml-explainability.R
# Tests for ML Explainability Module (P2 #35)

library(testthat)

# Source the explainability module
if (file.exists("functions/ml_explainability.R")) {
  tryCatch({
    source("functions/ml_explainability.R")
  }, error = function(e) {
    # May fail if torch not available
  })
}

# ============================================================================
# EXPLANATION OBJECT TESTS
# ============================================================================

test_that("create_explanation returns proper structure", {
  skip_if_not(exists("create_explanation", mode = "function"),
              "create_explanation function not available")

  elem1 <- list(type = "D", label = "Climate Change")
  elem2 <- list(type = "A", label = "Fishing Activity")
  prediction <- list(existence = 0.85, polarity = 0.7)

  explanation <- create_explanation(
    elem1 = elem1,
    elem2 = elem2,
    prediction = prediction,
    natural_language = "Test explanation"
  )

  expect_true(is.list(explanation))
  expect_true("ml_explanation" %in% class(explanation))
  expect_equal(explanation$elem1$type, "D")
  expect_equal(explanation$elem2$label, "Fishing Activity")
  expect_equal(explanation$prediction$existence, 0.85)
  expect_true(!is.null(explanation$timestamp))
})

# ============================================================================
# NATURAL LANGUAGE EXPLANATION TESTS
# ============================================================================

test_that("generate_prediction_explanation creates readable text", {
  skip_if_not(exists("generate_prediction_explanation", mode = "function"),
              "generate_prediction_explanation function not available")

  elem1 <- list(type = "D", label = "Economic Growth")
  elem2 <- list(type = "A", label = "Tourism Development")

  # High probability connection
  prediction_high <- list(existence = 0.9, polarity = 0.8)
  explanation_high <- generate_prediction_explanation(elem1, elem2, prediction_high)

  expect_true(is.character(explanation_high))
  expect_true(nchar(explanation_high) > 0)
  expect_true(grepl("strong likelihood", explanation_high, ignore.case = TRUE))

  # Low probability connection
  prediction_low <- list(existence = 0.2, polarity = 0.5)
  explanation_low <- generate_prediction_explanation(elem1, elem2, prediction_low)

  expect_true(grepl("no significant", explanation_low, ignore.case = TRUE))
})

test_that("generate_prediction_explanation includes polarity", {
  skip_if_not(exists("generate_prediction_explanation", mode = "function"),
              "generate_prediction_explanation function not available")

  elem1 <- list(type = "A", label = "Activity A")
  elem2 <- list(type = "P", label = "Pressure P")

  # Positive polarity
  pred_positive <- list(existence = 0.8, polarity = 0.9)
  exp_positive <- generate_prediction_explanation(elem1, elem2, pred_positive)
  expect_true(grepl("reinforcing", exp_positive, ignore.case = TRUE))

  # Negative polarity
  pred_negative <- list(existence = 0.8, polarity = 0.1)
  exp_negative <- generate_prediction_explanation(elem1, elem2, pred_negative)
  expect_true(grepl("opposing", exp_negative, ignore.case = TRUE))
})

# ============================================================================
# TYPE-BASED REASONING TESTS
# ============================================================================

test_that("get_type_based_reasoning returns DAPSIWRM context", {
  skip_if_not(exists("get_type_based_reasoning", mode = "function"),
              "get_type_based_reasoning function not available")

  # Driver -> Activity
  reason_da <- get_type_based_reasoning("D", "A")
  expect_true(is.character(reason_da) || is.null(reason_da))
  if (!is.null(reason_da)) {
    expect_true(nchar(reason_da) > 0)
  }

  # Activity -> Pressure
  reason_ap <- get_type_based_reasoning("A", "P")
  if (!is.null(reason_ap)) {
    expect_true(grepl("Pressure", reason_ap, ignore.case = TRUE) ||
                grepl("Activities", reason_ap, ignore.case = TRUE))
  }
})

# ============================================================================
# TOP FEATURES TESTS
# ============================================================================

test_that("get_top_important_features extracts top N", {
  skip_if_not(exists("get_top_important_features", mode = "function"),
              "get_top_important_features function not available")

  feature_importance <- list(
    importance = c(0.1, 0.5, 0.3, 0.2, 0.4)
  )

  top_3 <- get_top_important_features(feature_importance, n = 3)

  expect_true(is.character(top_3))
  expect_true(length(top_3) <= 3)
})

test_that("get_top_important_features handles empty input", {
  skip_if_not(exists("get_top_important_features", mode = "function"),
              "get_top_important_features function not available")

  empty_importance <- list(importance = numeric(0))
  result <- get_top_important_features(empty_importance)

  expect_true(length(result) == 0)
})

# ============================================================================
# GRADIENT IMPORTANCE TESTS (requires torch)
# ============================================================================

test_that("calculate_gradient_importance exists", {
  skip_if_not(exists("calculate_gradient_importance", mode = "function"),
              "calculate_gradient_importance function not available")

  expect_true(is.function(calculate_gradient_importance))
})

# ============================================================================
# PERMUTATION IMPORTANCE TESTS (requires torch)
# ============================================================================

test_that("calculate_permutation_importance exists", {
  skip_if_not(exists("calculate_permutation_importance", mode = "function"),
              "calculate_permutation_importance function not available")

  expect_true(is.function(calculate_permutation_importance))
})

# ============================================================================
# SHAP VALUES TESTS (requires torch)
# ============================================================================

test_that("approximate_shap_values exists", {
  skip_if_not(exists("approximate_shap_values", mode = "function"),
              "approximate_shap_values function not available")

  expect_true(is.function(approximate_shap_values))
})

# ============================================================================
# HIGH-LEVEL API TESTS
# ============================================================================

test_that("explain_connection_prediction exists", {
  skip_if_not(exists("explain_connection_prediction", mode = "function"),
              "explain_connection_prediction function not available")

  expect_true(is.function(explain_connection_prediction))
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

test_that("explanation handles missing optional fields", {
  skip_if_not(exists("create_explanation", mode = "function"),
              "create_explanation function not available")

  elem1 <- list(type = "D", label = "Driver")
  elem2 <- list(type = "A", label = "Activity")
  prediction <- list(existence = 0.5)

  # Create with minimal fields
  explanation <- create_explanation(
    elem1 = elem1,
    elem2 = elem2,
    prediction = prediction
  )

  expect_true(is.null(explanation$feature_importance))
  expect_true(is.null(explanation$shap_values))
  expect_true(is.null(explanation$natural_language))
})

test_that("generate_prediction_explanation handles missing polarity", {
  skip_if_not(exists("generate_prediction_explanation", mode = "function"),
              "generate_prediction_explanation function not available")

  elem1 <- list(type = "D", label = "Driver")
  elem2 <- list(type = "A", label = "Activity")
  prediction <- list(existence = 0.7)  # No polarity

  # Should not error
  explanation <- generate_prediction_explanation(elem1, elem2, prediction)
  expect_true(is.character(explanation))
})
