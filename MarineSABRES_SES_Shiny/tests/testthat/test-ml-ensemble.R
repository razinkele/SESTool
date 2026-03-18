# ==============================================================================
# Tests for ML Ensemble Module
# ==============================================================================

library(testthat)

skip_if_not_installed("torch")
library(torch)

# Source required modules
source("../../functions/ml_feature_engineering.R", chdir = TRUE)
source("../../functions/ml_context_embeddings.R", chdir = TRUE)
source("../../functions/ml_models.R", chdir = TRUE)
source("../../functions/ml_active_learning.R", chdir = TRUE)
source("../../functions/ml_ensemble.R", chdir = TRUE)

# ==============================================================================
# Test: Ensemble Environment
# ==============================================================================

test_that("Ensemble environment initializes correctly", {
  expect_true(exists("ensemble_env"))
  expect_true(is.environment(ensemble_env))
  expect_true(exists("models", envir = ensemble_env))
  expect_true(exists("loaded", envir = ensemble_env))
  expect_true(exists("n_models", envir = ensemble_env))
})

test_that("Ensemble availability check works", {
  # Initially not available
  initial_status <- ensemble_available()

  # Should return logical
  expect_type(initial_status, "logical")
})

# ==============================================================================
# Test: Mock Ensemble Creation
# ==============================================================================

# Helper: Create mock ensemble for testing
create_mock_ensemble <- function(n_models = 3) {
  # Clear existing
  ensemble_env$models <- list()
  ensemble_env$n_models <- 0
  ensemble_env$loaded <- FALSE

  # Create mock models
  for (i in 1:n_models) {
    model <- connection_predictor_v2(
      elem_input_dim = 270,
      graph_dim = 8,
      hidden_dim = 128,
      dropout = 0.3,
      use_embeddings = TRUE
    )
    model$eval()
    ensemble_env$models[[i]] <- model
  }

  ensemble_env$n_models <- n_models
  ensemble_env$loaded <- TRUE
  ensemble_env$metadata <- list(
    n_models = n_models,
    seeds = c(42, 123, 456)[1:n_models]
  )
}

test_that("Mock ensemble can be created", {
  create_mock_ensemble(n_models = 3)

  expect_equal(ensemble_env$n_models, 3)
  expect_true(ensemble_env$loaded)
  expect_length(ensemble_env$models, 3)
  expect_true(ensemble_available())
})

# ==============================================================================
# Test: Ensemble Predictions
# ==============================================================================

test_that("Predict ensemble with mean aggregation works", {
  create_mock_ensemble(n_models = 3)

  # Create mock input
  batch_size <- 5
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  # Predict
  result <- predict_ensemble(elem_features, context_data, graph_features, aggregation = "mean")

  # Check structure
  expect_true("aggregated" %in% names(result))
  expect_true("individual" %in% names(result))

  # Check aggregated predictions
  expect_true("existence" %in% names(result$aggregated))
  expect_true("strength" %in% names(result$aggregated))
  expect_true("confidence" %in% names(result$aggregated))
  expect_true("polarity" %in% names(result$aggregated))

  # Check individual predictions
  expect_length(result$individual$existence, 3)
  expect_length(result$individual$strength, 3)
  expect_length(result$individual$confidence, 3)
  expect_length(result$individual$polarity, 3)

  # Check shapes
  expect_equal(result$aggregated$existence$size(), c(batch_size, 1))
  expect_equal(result$aggregated$strength$size(), c(batch_size, 3))
})

test_that("Predict ensemble with vote aggregation works", {
  create_mock_ensemble(n_models = 3)

  batch_size <- 5
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  result <- predict_ensemble(elem_features, context_data, graph_features, aggregation = "vote")

  expect_true("aggregated" %in% names(result))
  expect_true("individual" %in% names(result))
})

test_that("Predict ensemble fails when ensemble not loaded", {
  # Unload ensemble
  ensemble_env$loaded <- FALSE

  elem_features <- torch_randn(1, 270)
  context_data <- list(
    sea_idx = torch_tensor(1L, dtype = torch_long()),
    eco_idx = torch_tensor(1L, dtype = torch_long()),
    issue_idx = torch_tensor(1L, dtype = torch_long())
  )
  graph_features <- torch_randn(1, 8)

  # predict_ensemble returns NULL gracefully when ensemble not loaded
  result <- predict_ensemble(elem_features, context_data, graph_features)
  expect_null(result)

  # Restore for other tests
  create_mock_ensemble(n_models = 3)
})

# ==============================================================================
# Test: Disagreement Calculation
# ==============================================================================

test_that("Calculate disagreement for binary task (existence)", {
  # Create mock predictions with known disagreement
  n_models <- 3
  batch_size <- 5

  # High agreement case: all models predict similar
  probs_agree <- list(
    torch_tensor(rep(0.8, batch_size))$view(c(batch_size, 1)),
    torch_tensor(rep(0.82, batch_size))$view(c(batch_size, 1)),
    torch_tensor(rep(0.79, batch_size))$view(c(batch_size, 1))
  )

  # Convert to logits
  logits_agree <- lapply(probs_agree, function(p) torch_log(p / (1 - p)))

  individual_preds <- list(existence = logits_agree)
  disagreement <- calculate_disagreement(individual_preds, task = "existence")

  # Low disagreement expected
  expect_true(all(as.numeric(disagreement) < 0.1))
})

test_that("Calculate disagreement for binary task with high disagreement", {
  # High disagreement case: models predict differently
  batch_size <- 3
  probs_disagree <- list(
    torch_tensor(c(0.2, 0.5, 0.8))$view(c(batch_size, 1)),
    torch_tensor(c(0.8, 0.5, 0.2))$view(c(batch_size, 1)),
    torch_tensor(c(0.5, 0.8, 0.5))$view(c(batch_size, 1))
  )

  logits_disagree <- lapply(probs_disagree, function(p) torch_log(p / (1 - p)))

  individual_preds <- list(existence = logits_disagree)
  disagreement <- calculate_disagreement(individual_preds, task = "existence")

  # High disagreement expected (variance > 0)
  expect_true(all(as.numeric(disagreement) > 0))
})

test_that("Calculate disagreement for multi-class task (strength)", {
  n_models <- 3
  batch_size <- 4

  # Create predictions where models agree on class
  strength_logits_agree <- list(
    torch_tensor(matrix(c(5, -2, -3), nrow = batch_size, ncol = 3, byrow = TRUE)),
    torch_tensor(matrix(c(5, -2, -3), nrow = batch_size, ncol = 3, byrow = TRUE)),
    torch_tensor(matrix(c(5, -2, -3), nrow = batch_size, ncol = 3, byrow = TRUE))
  )

  individual_preds <- list(strength = strength_logits_agree)
  disagreement <- calculate_disagreement(individual_preds, task = "strength")

  # All models agree -> disagreement = 0
  expect_equal(as.numeric(disagreement), rep(0, batch_size))
})

test_that("Calculate disagreement for multi-class with disagreement", {
  batch_size <- 2

  # Models predict different classes
  strength_logits_disagree <- list(
    torch_tensor(matrix(c(5, -2, -3,   # Class 1
                         -3, 5, -2), nrow = 2, ncol = 3, byrow = TRUE)),  # Class 2
    torch_tensor(matrix(c(-2, 5, -3,   # Class 2
                         5, -2, -3), nrow = 2, ncol = 3, byrow = TRUE)),  # Class 1
    torch_tensor(matrix(c(-3, -2, 5,   # Class 3
                         -2, -3, 5), nrow = 2, ncol = 3, byrow = TRUE))   # Class 3
  )

  individual_preds <- list(strength = strength_logits_disagree)
  disagreement <- calculate_disagreement(individual_preds, task = "strength")

  # All models disagree -> high disagreement
  expect_true(all(as.numeric(disagreement) > 0.5))
})

test_that("Calculate disagreement for regression task (confidence)", {
  batch_size <- 3

  # Low disagreement: similar predictions
  confidence_agree <- list(
    torch_tensor(c(3.0, 4.0, 2.0))$view(c(batch_size, 1)),
    torch_tensor(c(3.1, 4.1, 2.1))$view(c(batch_size, 1)),
    torch_tensor(c(2.9, 3.9, 1.9))$view(c(batch_size, 1))
  )

  individual_preds <- list(confidence = confidence_agree)
  disagreement <- calculate_disagreement(individual_preds, task = "confidence")

  # Low std expected
  expect_true(all(as.numeric(disagreement) < 0.3))
})

# ==============================================================================
# Test: Overall Ensemble Disagreement
# ==============================================================================

test_that("Calculate overall ensemble disagreement", {
  create_mock_ensemble(n_models = 3)

  batch_size <- 5
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  ensemble_preds <- predict_ensemble(elem_features, context_data, graph_features)
  disagreement_info <- calculate_ensemble_disagreement(ensemble_preds$individual)

  # Check structure
  expect_true("overall" %in% names(disagreement_info))
  expect_true("existence" %in% names(disagreement_info))
  expect_true("strength" %in% names(disagreement_info))
  expect_true("confidence" %in% names(disagreement_info))
  expect_true("polarity" %in% names(disagreement_info))

  # Check shapes
  expect_equal(length(as.numeric(disagreement_info$overall)), batch_size)

  # Check range [0, 1]
  expect_true(all(as.numeric(disagreement_info$overall) >= 0))
  expect_true(all(as.numeric(disagreement_info$overall) <= 1))
})

test_that("Calculate ensemble disagreement respects task weights", {
  batch_size <- 2

  # Create predictions with high existence disagreement, low others
  individual_preds <- list(
    existence = list(
      torch_tensor(c(0.2, 0.8))$view(c(2, 1))$logit(),
      torch_tensor(c(0.8, 0.2))$view(c(2, 1))$logit(),
      torch_tensor(c(0.5, 0.5))$view(c(2, 1))$logit()
    ),
    strength = list(
      torch_tensor(matrix(c(5, -2, -3), nrow = 2, ncol = 3, byrow = TRUE)),
      torch_tensor(matrix(c(5, -2, -3), nrow = 2, ncol = 3, byrow = TRUE)),
      torch_tensor(matrix(c(5, -2, -3), nrow = 2, ncol = 3, byrow = TRUE))
    ),
    confidence = list(
      torch_tensor(c(3.0, 4.0))$view(c(2, 1)),
      torch_tensor(c(3.0, 4.0))$view(c(2, 1)),
      torch_tensor(c(3.0, 4.0))$view(c(2, 1))
    ),
    polarity = list(
      torch_tensor(c(0.5, 0.5))$view(c(2, 1))$logit(),
      torch_tensor(c(0.5, 0.5))$view(c(2, 1))$logit(),
      torch_tensor(c(0.5, 0.5))$view(c(2, 1))$logit()
    )
  )

  # Weight existence heavily
  disagreement_high_existence <- calculate_ensemble_disagreement(
    individual_preds,
    task_weights = list(existence = 0.9, strength = 0.03, confidence = 0.03, polarity = 0.04)
  )

  # Weight strength heavily
  disagreement_high_strength <- calculate_ensemble_disagreement(
    individual_preds,
    task_weights = list(existence = 0.1, strength = 0.8, confidence = 0.05, polarity = 0.05)
  )

  # Existence-weighted should have higher overall disagreement
  mean_existence <- mean(as.numeric(disagreement_high_existence$overall))
  mean_strength <- mean(as.numeric(disagreement_high_strength$overall))

  expect_true(mean_existence > mean_strength)
})

# ==============================================================================
# Test: Disagreement Sampling
# ==============================================================================

test_that("Disagreement sampling selects top-n samples", {
  scores <- c(0.1, 0.8, 0.3, 0.9, 0.2)
  selected <- disagreement_sampling(scores, n_samples = 2)

  # Should select indices 4 and 2 (highest scores 0.9 and 0.8)
  expect_equal(sort(selected), c(2, 4))
})

test_that("Disagreement sampling with threshold", {
  scores <- c(0.1, 0.8, 0.3, 0.9, 0.2)
  selected <- disagreement_sampling(scores, threshold = 0.5)

  # Should select indices 2 and 4 (scores >= 0.5)
  expect_equal(sort(selected), c(2, 4))
})

test_that("Disagreement sampling handles tensor input", {
  scores <- torch_tensor(c(0.1, 0.8, 0.3, 0.9, 0.2))
  selected <- disagreement_sampling(scores, n_samples = 3)

  expect_length(selected, 3)
  expect_true(all(selected %in% 1:5))
})

test_that("Disagreement sampling with no candidates", {
  scores <- c(0.1, 0.2, 0.3)

  # Suppress message
  selected <- suppressMessages(disagreement_sampling(scores, threshold = 0.5))

  expect_length(selected, 0)
})

# ==============================================================================
# Test: Integration
# ==============================================================================

test_that("Full ensemble workflow works end-to-end", {
  create_mock_ensemble(n_models = 3)

  batch_size <- 10
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  # Step 1: Ensemble prediction
  ensemble_preds <- predict_ensemble(elem_features, context_data, graph_features)

  # Step 2: Calculate disagreement
  disagreement_info <- calculate_ensemble_disagreement(ensemble_preds$individual)

  # Step 3: Select samples with high disagreement
  high_disagreement <- disagreement_sampling(
    disagreement_info$overall,
    n_samples = 3,
    threshold = 0.3
  )

  # Verify workflow completed
  expect_true(!is.null(ensemble_preds))
  expect_true(!is.null(disagreement_info))
  expect_true(length(high_disagreement) <= 10)
})

# ==============================================================================
# Test: Unload Ensemble
# ==============================================================================

test_that("Unload ensemble clears environment", {
  create_mock_ensemble(n_models = 3)
  expect_true(ensemble_available())

  unload_ensemble()

  expect_false(ensemble_available())
  expect_equal(ensemble_env$n_models, 0)
  expect_length(ensemble_env$models, 0)
})

# ==============================================================================
# Performance Tests
# ==============================================================================

test_that("Ensemble prediction is reasonably fast", {
  create_mock_ensemble(n_models = 3)

  batch_size <- 100
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  start_time <- Sys.time()
  result <- predict_ensemble(elem_features, context_data, graph_features)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 5 seconds for 100 samples (3 models)
  expect_true(elapsed < 5.0)
})

test_that("Disagreement calculation is fast", {
  create_mock_ensemble(n_models = 3)

  batch_size <- 500
  elem_features <- torch_randn(batch_size, 270)
  context_data <- list(
    sea_idx = torch_randint(1, 13, size = batch_size, dtype = torch_long()),
    eco_idx = torch_randint(1, 26, size = batch_size, dtype = torch_long()),
    issue_idx = torch_randint(1, 52, size = batch_size, dtype = torch_long())
  )
  graph_features <- torch_randn(batch_size, 8)

  ensemble_preds <- predict_ensemble(elem_features, context_data, graph_features)

  start_time <- Sys.time()
  disagreement_info <- calculate_ensemble_disagreement(ensemble_preds$individual)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 1 second
  expect_true(elapsed < 1.0)
})
