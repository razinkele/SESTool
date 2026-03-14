# ==============================================================================
# Tests for Active Learning & Uncertainty Quantification Module
# ==============================================================================

library(testthat)

skip_if_not_installed("torch")
library(torch)

# Source the module
source("../../functions/ml_active_learning.R", chdir = TRUE)

# ==============================================================================
# Test: Temperature Scaling
# ==============================================================================

test_that("Temperature scaler initializes correctly", {
  scaler <- temperature_scaler(temperature = 1.5)

  expect_true(inherits(scaler, "nn_module"))
  expect_equal(as.numeric(scaler$temperature), 1.5, tolerance = 1e-6)
})

test_that("Temperature scaling modifies logits correctly", {
  scaler <- temperature_scaler(temperature = 2.0)
  logits <- torch_tensor(c(2.0, 4.0, 1.0))$view(c(1, 3))

  scaled <- scaler(logits)

  # Scaled logits should be halved
  expect_equal(as.numeric(scaled), c(1.0, 2.0, 0.5), tolerance = 1e-6)
})

test_that("Fit temperature scaling optimizes temperature", {
  # Create mock validation data
  set.seed(42)
  logits <- torch_randn(100, 3)
  targets <- torch_randint(1, 4, size = 100, dtype = torch_long())

  scaler <- fit_temperature_scaling(logits, targets, max_iter = 50)

  # Temperature should have changed from initial value
  temp <- as.numeric(scaler$temperature)
  expect_true(temp > 0)
  expect_true(temp != 1.5)  # Should have optimized away from initial
})

# ==============================================================================
# Test: Uncertainty Metrics - Entropy
# ==============================================================================

test_that("Entropy is zero for certain predictions", {
  # Certain prediction: p=1 for one class
  probs <- torch_tensor(c(1.0, 0.0, 0.0))$view(c(1, 3))
  entropy <- calculate_entropy(probs)

  expect_equal(as.numeric(entropy), 0.0, tolerance = 1e-4)
})

test_that("Entropy is maximum for uniform distribution", {
  # Uniform distribution over 2 classes
  probs <- torch_tensor(c(0.5, 0.5))$view(c(1, 2))
  entropy <- calculate_entropy(probs)

  # Max entropy for 2 classes is log(2)
  expect_equal(as.numeric(entropy), log(2), tolerance = 1e-4)
})

test_that("Entropy handles binary probabilities (N x 1)", {
  probs <- torch_tensor(c(0.7))$view(c(1, 1))
  entropy <- calculate_entropy(probs)

  # Should convert to [0.3, 0.7] and calculate entropy
  expected <- -(0.3 * log(0.3) + 0.7 * log(0.7))
  expect_equal(as.numeric(entropy), expected, tolerance = 1e-4)
})

test_that("Entropy handles batches correctly", {
  probs <- torch_tensor(matrix(c(
    0.8, 0.1, 0.1,
    0.5, 0.3, 0.2
  ), nrow = 2, byrow = TRUE))

  entropy <- calculate_entropy(probs)

  expect_equal(length(as.numeric(entropy)), 2)
  expect_true(all(as.numeric(entropy) >= 0))
})

# ==============================================================================
# Test: Uncertainty Metrics - Margin
# ==============================================================================

test_that("Margin is 1.0 for certain predictions", {
  # Certain: p=1 for one class, others 0
  probs <- torch_tensor(c(1.0, 0.0, 0.0))$view(c(1, 3))
  margin <- calculate_margin(probs)

  expect_equal(as.numeric(margin), 1.0, tolerance = 1e-4)
})

test_that("Margin is 0.0 for maximally uncertain binary prediction", {
  # Binary: p = 0.5
  probs <- torch_tensor(c(0.5))$view(c(1, 1))
  margin <- calculate_margin(probs)

  expect_equal(as.numeric(margin), 0.0, tolerance = 1e-4)
})

test_that("Margin is small for close predictions", {
  # Close top-2 classes
  probs <- torch_tensor(c(0.51, 0.49, 0.0))$view(c(1, 3))
  margin <- calculate_margin(probs)

  expect_equal(as.numeric(margin), 0.02, tolerance = 1e-4)
})

test_that("Margin handles batches correctly", {
  probs <- torch_tensor(matrix(c(
    0.8, 0.15, 0.05,
    0.4, 0.35, 0.25
  ), nrow = 2, byrow = TRUE))

  margin <- calculate_margin(probs)

  expect_equal(length(as.numeric(margin)), 2)
  # First sample more certain (larger margin)
  expect_true(as.numeric(margin)[1] > as.numeric(margin)[2])
})

# ==============================================================================
# Test: Uncertainty Metrics - Max Probability
# ==============================================================================

test_that("Max prob uncertainty is 0 for certain prediction", {
  probs <- torch_tensor(c(1.0, 0.0))$view(c(1, 2))
  unc <- calculate_max_prob_uncertainty(probs)

  expect_equal(as.numeric(unc), 0.0, tolerance = 1e-4)
})

test_that("Max prob uncertainty is 0.5 for binary p=0.5", {
  probs <- torch_tensor(c(0.5))$view(c(1, 1))
  unc <- calculate_max_prob_uncertainty(probs)

  expect_equal(as.numeric(unc), 0.5, tolerance = 1e-4)
})

test_that("Max prob uncertainty handles batches", {
  probs <- torch_tensor(c(0.9, 0.6, 0.5))$view(c(3, 1))
  unc <- calculate_max_prob_uncertainty(probs)

  expected <- c(0.1, 0.4, 0.5)
  expect_equal(as.numeric(unc), expected, tolerance = 1e-4)
})

# ==============================================================================
# Test: Combined Uncertainty Score
# ==============================================================================

test_that("Combined uncertainty score works with default weights", {
  probs <- torch_tensor(c(0.6, 0.4))$view(c(1, 2))
  score <- calculate_uncertainty_score(probs)

  expect_true(as.numeric(score) >= 0)
  expect_true(as.numeric(score) <= 1)
})

test_that("Combined uncertainty is higher for uncertain predictions", {
  certain_probs <- torch_tensor(c(0.95, 0.05))$view(c(1, 2))
  uncertain_probs <- torch_tensor(c(0.55, 0.45))$view(c(1, 2))

  certain_score <- calculate_uncertainty_score(certain_probs)
  uncertain_score <- calculate_uncertainty_score(uncertain_probs)

  expect_true(as.numeric(uncertain_score) > as.numeric(certain_score))
})

test_that("Combined uncertainty respects custom weights", {
  probs <- torch_tensor(c(0.7, 0.3))$view(c(1, 2))

  # Heavily weight entropy
  score1 <- calculate_uncertainty_score(probs, weights = list(entropy = 0.8, margin = 0.1, max_prob = 0.1))
  # Heavily weight max_prob
  score2 <- calculate_uncertainty_score(probs, weights = list(entropy = 0.1, margin = 0.1, max_prob = 0.8))

  # Scores should differ
  expect_false(abs(as.numeric(score1) - as.numeric(score2)) < 1e-6)
})

# ==============================================================================
# Test: Connection Uncertainty
# ==============================================================================

test_that("Connection uncertainty calculates all task uncertainties", {
  # Mock predictions
  predictions <- list(
    existence = torch_tensor(c(2.0, -1.0))$view(c(2, 1)),
    strength = torch_randn(2, 3),
    confidence = torch_tensor(c(4.0, 2.5))$view(c(2, 1)),
    polarity = torch_tensor(c(1.5, -0.5))$view(c(2, 1))
  )

  unc <- calculate_connection_uncertainty(predictions)

  expect_true("overall" %in% names(unc))
  expect_true("existence" %in% names(unc))
  expect_true("strength" %in% names(unc))
  expect_true("confidence" %in% names(unc))
  expect_true("polarity" %in% names(unc))

  expect_equal(length(as.numeric(unc$overall)), 2)
})

test_that("Connection uncertainty is in valid range", {
  predictions <- list(
    existence = torch_tensor(c(0.5))$view(c(1, 1)),
    strength = torch_tensor(c(0.33, 0.33, 0.34))$view(c(1, 3)),
    confidence = torch_tensor(c(3.0))$view(c(1, 1)),
    polarity = torch_tensor(c(0.0))$view(c(1, 1))
  )

  unc <- calculate_connection_uncertainty(predictions)

  # All uncertainties should be [0, 1]
  expect_true(all(as.numeric(unc$overall) >= 0))
  expect_true(all(as.numeric(unc$overall) <= 1))
  expect_true(all(as.numeric(unc$existence) >= 0))
  expect_true(all(as.numeric(unc$strength) >= 0))
})

test_that("Connection uncertainty respects task weights", {
  predictions <- list(
    existence = torch_tensor(c(0.0))$view(c(1, 1)),  # Very uncertain
    strength = torch_tensor(c(5.0, -2.0, -3.0))$view(c(1, 3)),  # Very certain
    confidence = torch_tensor(c(3.0))$view(c(1, 1)),
    polarity = torch_tensor(c(0.0))$view(c(1, 1))
  )

  # Weight existence heavily
  unc1 <- calculate_connection_uncertainty(predictions,
                                          task_weights = list(existence = 0.9, strength = 0.03, confidence = 0.03, polarity = 0.04))
  # Weight strength heavily
  unc2 <- calculate_connection_uncertainty(predictions,
                                          task_weights = list(existence = 0.1, strength = 0.8, confidence = 0.05, polarity = 0.05))

  # First should have higher overall uncertainty (weighted by uncertain existence)
  expect_true(as.numeric(unc1$overall) > as.numeric(unc2$overall))
})

# ==============================================================================
# Test: Uncertainty Sampling
# ==============================================================================

test_that("Uncertainty sampling selects top-n samples", {
  scores <- c(0.1, 0.8, 0.3, 0.9, 0.2)
  selected <- uncertainty_sampling(scores, n_samples = 2)

  # Should select indices 4 and 2 (highest scores 0.9 and 0.8)
  expect_equal(sort(selected), c(2, 4))
})

test_that("Uncertainty sampling with threshold selects all above", {
  scores <- c(0.1, 0.8, 0.3, 0.9, 0.2)
  selected <- uncertainty_sampling(scores, threshold = 0.5)

  # Should select indices 2 and 4 (scores >= 0.5)
  expect_equal(sort(selected), c(2, 4))
})

test_that("Uncertainty sampling handles tensor input", {
  scores <- torch_tensor(c(0.1, 0.8, 0.3, 0.9, 0.2))
  selected <- uncertainty_sampling(scores, n_samples = 3)

  expect_equal(length(selected), 3)
  expect_true(all(selected %in% 1:5))
})

test_that("Uncertainty sampling respects n_samples limit", {
  scores <- c(0.1, 0.2, 0.3)
  selected <- uncertainty_sampling(scores, n_samples = 10)

  # Should only select 3 (total available)
  expect_equal(length(selected), 3)
})

# ==============================================================================
# Test: Random Sampling
# ==============================================================================

test_that("Random sampling selects correct number", {
  selected <- random_sampling(n_total = 100, n_samples = 10)

  expect_equal(length(selected), 10)
  expect_true(all(selected >= 1))
  expect_true(all(selected <= 100))
  expect_true(length(unique(selected)) == 10)  # No duplicates
})

test_that("Random sampling respects n_samples limit", {
  selected <- random_sampling(n_total = 5, n_samples = 10)

  expect_equal(length(selected), 5)
})

# ==============================================================================
# Test: Stratified Uncertainty Sampling
# ==============================================================================

test_that("Stratified sampling divides into strata", {
  scores <- runif(100)
  selected <- stratified_uncertainty_sampling(scores, n_samples = 30, n_strata = 3)

  expect_equal(length(selected), 30)
  expect_true(all(selected >= 1))
  expect_true(all(selected <= 100))
})

test_that("Stratified sampling selects from all strata", {
  # Create clear strata: low, medium, high uncertainty
  scores <- c(rep(0.1, 30), rep(0.5, 30), rep(0.9, 30))
  selected <- stratified_uncertainty_sampling(scores, n_samples = 9, n_strata = 3)

  # Should select 3 from each stratum
  expect_equal(length(selected), 9)

  # Check that samples come from different ranges
  selected_scores <- scores[selected]
  expect_true(any(selected_scores < 0.3))  # Some from low
  expect_true(any(selected_scores >= 0.3 & selected_scores < 0.7))  # Some from medium
  expect_true(any(selected_scores >= 0.7))  # Some from high
})

# ==============================================================================
# Test: Filter High Confidence
# ==============================================================================

test_that("Filter high confidence removes uncertain predictions", {
  predictions <- data.frame(
    id = 1:5,
    value = c("a", "b", "c", "d", "e")
  )
  scores <- c(0.1, 0.8, 0.2, 0.9, 0.15)

  result <- filter_high_confidence(predictions, scores, threshold = 0.3)

  expect_equal(nrow(result$predictions), 3)  # Indices 1, 3, 5
  expect_equal(result$n_filtered, 3)
  expect_equal(result$n_total, 5)
  expect_true(all(result$predictions$id %in% c(1, 3, 5)))
})

test_that("Filter high confidence handles list input", {
  predictions <- list(
    ids = 1:5,
    values = c("a", "b", "c", "d", "e")
  )
  scores <- c(0.1, 0.8, 0.2, 0.9, 0.15)

  result <- filter_high_confidence(predictions, scores, threshold = 0.3)

  expect_equal(length(result$predictions$ids), 3)
  expect_equal(result$n_filtered, 3)
})

# ==============================================================================
# Test: Categorize Uncertainty
# ==============================================================================

test_that("Categorize uncertainty assigns correct categories", {
  scores <- c(0.1, 0.3, 0.6, 0.8)
  categories <- categorize_uncertainty(scores, thresholds = list(low = 0.2, medium = 0.5))

  expect_equal(categories[1], "high_confidence")      # 0.1 < 0.2
  expect_equal(categories[2], "medium_confidence")    # 0.2 <= 0.3 < 0.5
  expect_equal(categories[3], "low_confidence")       # 0.6 >= 0.5
  expect_equal(categories[4], "low_confidence")       # 0.8 >= 0.5
})

test_that("Categorize uncertainty handles custom thresholds", {
  scores <- c(0.1, 0.4, 0.7)
  categories <- categorize_uncertainty(scores, thresholds = list(low = 0.3, medium = 0.6))

  expect_equal(categories[1], "high_confidence")
  expect_equal(categories[2], "medium_confidence")
  expect_equal(categories[3], "low_confidence")
})

# ==============================================================================
# Test: Batch Uncertainty Scores
# ==============================================================================

test_that("Batch uncertainty scores returns data frame", {
  predictions <- list(
    existence = torch_randn(5, 1),
    strength = torch_randn(5, 3),
    confidence = torch_randn(5, 1),
    polarity = torch_randn(5, 1)
  )

  result <- batch_uncertainty_scores(predictions)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 5)
  expect_true("uncertainty_score" %in% colnames(result))
  expect_true("confidence_category" %in% colnames(result))
})

test_that("Batch uncertainty scores includes components when requested", {
  predictions <- list(
    existence = torch_randn(3, 1),
    strength = torch_randn(3, 3),
    confidence = torch_randn(3, 1),
    polarity = torch_randn(3, 1)
  )

  result <- batch_uncertainty_scores(predictions, return_components = TRUE)

  expect_true("existence_uncertainty" %in% colnames(result))
  expect_true("strength_uncertainty" %in% colnames(result))
  expect_true("confidence_uncertainty" %in% colnames(result))
  expect_true("polarity_uncertainty" %in% colnames(result))
})

# ==============================================================================
# Test: Recommend Review Samples
# ==============================================================================

test_that("Recommend review samples returns top uncertain", {
  predictions <- data.frame(
    id = 1:10,
    source = paste0("S", 1:10),
    target = paste0("T", 1:10)
  )
  scores <- runif(10)

  recommended <- recommend_review_samples(predictions, scores, n_recommend = 3)

  expect_equal(nrow(recommended), 3)
  expect_true("uncertainty_score" %in% colnames(recommended))
  expect_true("review_priority" %in% colnames(recommended))

  # Should be sorted by uncertainty descending
  expect_true(all(diff(recommended$uncertainty_score) <= 0))
})

test_that("Recommend review samples respects min threshold", {
  predictions <- data.frame(id = 1:10)
  scores <- seq(0.1, 1.0, length.out = 10)

  recommended <- recommend_review_samples(predictions, scores,
                                         n_recommend = 5, min_threshold = 0.7)

  # Only scores >= 0.7 should be included
  expect_true(all(recommended$uncertainty_score >= 0.7))
})

test_that("Recommend review samples returns NULL when no candidates", {
  predictions <- data.frame(id = 1:5)
  scores <- rep(0.1, 5)  # All below threshold

  recommended <- recommend_review_samples(predictions, scores,
                                         n_recommend = 3, min_threshold = 0.5)

  expect_null(recommended)
})

test_that("Recommend review samples supports different methods", {
  predictions <- data.frame(id = 1:20)
  scores <- runif(20)

  rec_unc <- recommend_review_samples(predictions, scores, n_recommend = 5, method = "uncertainty")
  rec_strat <- recommend_review_samples(predictions, scores, n_recommend = 5, method = "stratified")
  rec_rand <- recommend_review_samples(predictions, scores, n_recommend = 5, method = "random")

  expect_equal(nrow(rec_unc), 5)
  expect_equal(nrow(rec_strat), 5)
  expect_equal(nrow(rec_rand), 5)
})

# ==============================================================================
# Test: Integration Example
# ==============================================================================

test_that("Full uncertainty workflow works end-to-end", {
  # Simulate model predictions
  set.seed(42)
  n <- 50
  predictions <- list(
    existence = torch_randn(n, 1),
    strength = torch_randn(n, 3),
    confidence = torch_tensor(runif(n, 1, 5))$view(c(n, 1)),
    polarity = torch_randn(n, 1)
  )

  # Calculate uncertainty
  unc <- calculate_connection_uncertainty(predictions)

  # Batch scores
  batch_scores <- batch_uncertainty_scores(predictions, return_components = TRUE)

  # Filter high confidence
  high_conf <- filter_high_confidence(
    data.frame(id = 1:n),
    batch_scores$uncertainty_score,
    threshold = 0.4
  )

  # Recommend samples for review
  pred_df <- data.frame(
    id = 1:n,
    source = paste0("S", 1:n),
    target = paste0("T", 1:n)
  )
  recommended <- recommend_review_samples(
    pred_df,
    batch_scores$uncertainty_score,
    n_recommend = 5,
    method = "stratified"
  )

  # Verify workflow completed
  expect_true(!is.null(unc))
  expect_equal(nrow(batch_scores), n)
  expect_true(high_conf$n_filtered < n)
  expect_equal(nrow(recommended), 5)
})

# ==============================================================================
# Performance Tests
# ==============================================================================

test_that("Uncertainty calculation is fast for large batches", {
  n <- 1000
  predictions <- list(
    existence = torch_randn(n, 1),
    strength = torch_randn(n, 3),
    confidence = torch_randn(n, 1),
    polarity = torch_randn(n, 1)
  )

  start_time <- Sys.time()
  unc <- calculate_connection_uncertainty(predictions)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 1 second
  expect_true(elapsed < 1.0)
})

test_that("Batch uncertainty scores is efficient", {
  n <- 500
  predictions <- list(
    existence = torch_randn(n, 1),
    strength = torch_randn(n, 3),
    confidence = torch_randn(n, 1),
    polarity = torch_randn(n, 1)
  )

  start_time <- Sys.time()
  result <- batch_uncertainty_scores(predictions, return_components = TRUE)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 1 second
  expect_true(elapsed < 1.0)
  expect_equal(nrow(result), n)
})
