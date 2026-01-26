# tests/testthat/test-ml-context-embeddings.R
# Tests for Context Embeddings Module (Phase 2)
# ==============================================================================

library(testthat)
library(torch)

# Load module
source("../../functions/ml_context_embeddings.R", chdir = TRUE)

# ==============================================================================
# Test: Context Vocabularies
# ==============================================================================

test_that("get_context_vocabularies returns correct structure", {
  vocabs <- get_context_vocabularies()

  expect_type(vocabs, "list")
  expect_true("regional_seas" %in% names(vocabs))
  expect_true("ecosystems" %in% names(vocabs))
  expect_true("focal_issues" %in% names(vocabs))

  # Check counts
  expect_equal(length(vocabs$regional_seas), 12)
  expect_equal(length(vocabs$ecosystems), 25)
  expect_equal(length(vocabs$focal_issues), 52)

  # Check specific values
  expect_true("Baltic Sea" %in% vocabs$regional_seas)
  expect_true("Coral reef" %in% vocabs$ecosystems)
  expect_true("Overfishing" %in% vocabs$focal_issues)
})

# ==============================================================================
# Test: Context to Indices Conversion
# ==============================================================================

test_that("context_to_indices converts strings to indices correctly", {
  result <- context_to_indices(
    regional_sea = "Baltic Sea",
    ecosystem_types = c("Coastal", "Open coast"),
    main_issues = c("Overfishing", "Eutrophication")
  )

  expect_type(result, "list")
  expect_true("sea_idx" %in% names(result))
  expect_true("eco_idx" %in% names(result))
  expect_true("issue_idx" %in% names(result))

  # Check tensor types
  expect_s3_class(result$sea_idx, "torch_tensor")
  expect_s3_class(result$eco_idx, "torch_tensor")
  expect_s3_class(result$issue_idx, "torch_tensor")

  # Check values
  expect_equal(result$sea_idx$item(), 1L)  # Baltic Sea is first
  expect_equal(length(result$eco_idx), 2)  # Two ecosystems
  expect_equal(length(result$issue_idx), 2)  # Two issues
})

test_that("context_to_indices handles unknown values gracefully", {
  result <- context_to_indices(
    regional_sea = "Unknown Sea",
    ecosystem_types = c("Unknown Ecosystem"),
    main_issues = c("Unknown Issue")
  )

  # Should default to last/first indices
  expect_equal(result$sea_idx$item(), 12L)  # Default to "Global"
  expect_equal(result$eco_idx$item(), 1L)   # Default to "Coastal"
  expect_equal(result$issue_idx$item(), 1L) # Default to "Overfishing"
})

test_that("context_to_indices handles empty/NULL values", {
  result <- context_to_indices(
    regional_sea = NULL,
    ecosystem_types = NULL,
    main_issues = NULL
  )

  expect_equal(result$sea_idx$item(), 12L)  # Default to "Global"
  expect_equal(result$eco_idx$item(), 1L)   # Default to "Coastal"
  expect_equal(result$issue_idx$item(), 1L) # Default to "Overfishing"
})

# ==============================================================================
# Test: Context Embeddings Module
# ==============================================================================

test_that("context_embeddings module initializes correctly", {
  model <- context_embeddings()

  expect_s3_class(model, "nn_module")
  expect_equal(model$n_seas, 12)
  expect_equal(model$n_ecosystems, 25)
  expect_equal(model$n_issues, 52)
  expect_equal(model$embed_dim_sea, 8)
  expect_equal(model$embed_dim_eco, 12)
  expect_equal(model$embed_dim_issue, 16)
  expect_equal(model$output_dim, 36)  # 8 + 12 + 16
})

test_that("context_embeddings forward pass works with single indices", {
  model <- context_embeddings()

  # Single example
  sea_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)  # (1, 1)
  eco_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)  # (1, 1)
  issue_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)  # (1, 1)

  output <- model(sea_idx, eco_idx, issue_idx)

  expect_s3_class(output, "torch_tensor")
  expect_equal(dim(output), c(1, 36))  # (batch=1, 36 dims)
})

test_that("context_embeddings forward pass works with batch", {
  model <- context_embeddings()

  # Batch of 32
  sea_idx <- torch_randint(1L, 12L, c(32, 1), dtype = torch_long())
  eco_idx <- torch_randint(1L, 25L, c(32, 1), dtype = torch_long())
  issue_idx <- torch_randint(1L, 51L, c(32, 1), dtype = torch_long())

  output <- model(sea_idx, eco_idx, issue_idx)

  expect_s3_class(output, "torch_tensor")
  expect_equal(dim(output), c(32, 36))  # (batch=32, 36 dims)
})

test_that("context_embeddings handles multi-hot ecosystems correctly", {
  model <- context_embeddings()

  # Single example with 3 ecosystems
  sea_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)
  eco_idx <- torch_tensor(c(1L, 2L, 3L), dtype = torch_long())$unsqueeze(1)  # (1, 3)
  issue_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)

  output <- model(sea_idx, eco_idx, issue_idx)

  expect_s3_class(output, "torch_tensor")
  expect_equal(dim(output), c(1, 36))  # Should average 3 ecosystems to 12 dims
})

test_that("context_embeddings handles multi-hot issues correctly", {
  model <- context_embeddings()

  # Single example with 5 issues
  sea_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)
  eco_idx <- torch_tensor(1L, dtype = torch_long())$unsqueeze(1)
  issue_idx <- torch_tensor(c(1L, 2L, 3L, 4L, 5L), dtype = torch_long())$unsqueeze(1)  # (1, 5)

  output <- model(sea_idx, eco_idx, issue_idx)

  expect_s3_class(output, "torch_tensor")
  expect_equal(dim(output), c(1, 36))  # Should average 5 issues to 16 dims
})

# ==============================================================================
# Test: Utility Functions
# ==============================================================================

test_that("get_context_embedding_dim returns correct value", {
  dim <- get_context_embedding_dim()
  expect_equal(dim, 36)
})

test_that("initialize_context_embeddings works with random init", {
  model <- context_embeddings()
  initialized <- initialize_context_embeddings(model, "random")

  expect_s3_class(initialized, "nn_module")
  # Weights should be non-zero (random)
  expect_true(initialized$sea_embed$weight$abs()$sum()$item() > 0)
})

test_that("initialize_context_embeddings works with onehot init", {
  model <- context_embeddings()
  initialized <- initialize_context_embeddings(model, "onehot")

  expect_s3_class(initialized, "nn_module")

  # Check that weights are initialized (truncated one-hot)
  sea_weights <- initialized$sea_embed$weight$to(dtype = torch_float())
  expect_equal(dim(sea_weights), c(12, 8))

  # First embedding should have 1 in first position (truncated one-hot)
  expect_equal(sea_weights[1, 1]$item(), 1.0, tolerance = 0.01)
})

# ==============================================================================
# Test: Integration
# ==============================================================================

test_that("context embeddings integrate with feature engineering", {
  # This test would require ml_feature_engineering.R
  # Skip if not available
  skip_if_not(file.exists("../../functions/ml_feature_engineering.R"))

  source("../../functions/ml_feature_engineering.R", chdir = TRUE)

  # Test prepare_context_indices
  # Use ecosystem types that exist in ECOSYSTEM_TYPES vocabulary
  indices <- prepare_context_indices(
    regional_sea = "Baltic Sea",
    ecosystem_types = "Open coast;Estuary",
    main_issues = "Overfishing;Eutrophication"
  )

  expect_type(indices, "list")
  expect_equal(indices$sea_idx, 1L)
  expect_equal(length(indices$eco_idx), 2)
  expect_equal(length(indices$issue_idx), 2)
})

# ==============================================================================
# Performance Test
# ==============================================================================

test_that("context embeddings are reasonably fast", {
  model <- context_embeddings()

  # Batch of 100
  sea_idx <- torch_randint(1L, 12L, c(100, 1), dtype = torch_long())
  eco_idx <- torch_randint(1L, 25L, c(100, 1), dtype = torch_long())
  issue_idx <- torch_randint(1L, 51L, c(100, 1), dtype = torch_long())

  # Measure time for 10 forward passes
  start_time <- Sys.time()
  for (i in 1:10) {
    output <- model(sea_idx, eco_idx, issue_idx)
  }
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in < 1 second for 10 batches
  expect_lt(elapsed, 1.0)
})

cat("\n✓ All context embedding tests passed!\n")
