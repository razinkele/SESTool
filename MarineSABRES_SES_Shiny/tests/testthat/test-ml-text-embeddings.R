# tests/testthat/test-ml-text-embeddings.R
# Tests for advanced text embeddings module (P1 ML Embeddings)
#
# These tests verify:
# 1. Embedding strategy selection
# 2. Vocabulary-based embeddings
# 3. FastText integration (when available)
# 4. Caching behavior

library(testthat)

# ============================================================================
# STRATEGY SELECTION TESTS
# ============================================================================

test_that("set_embedding_strategy function exists", {
  skip_if_not(exists("set_embedding_strategy", mode = "function"),
              "set_embedding_strategy function not available")

  expect_true(is.function(set_embedding_strategy))
})

test_that("get_embedding_strategy function exists", {
  skip_if_not(exists("get_embedding_strategy", mode = "function"),
              "get_embedding_strategy function not available")

  expect_true(is.function(get_embedding_strategy))
})

test_that("set_embedding_strategy changes strategy", {
  skip_if_not(exists("set_embedding_strategy", mode = "function") &&
              exists("get_embedding_strategy", mode = "function"),
              "Strategy functions not available")

  # Save original
  original <- get_embedding_strategy()

  # Change strategy
  set_embedding_strategy("vocabulary")
  expect_equal(get_embedding_strategy(), "vocabulary")

  # Restore original
  set_embedding_strategy(original)
})

test_that("set_embedding_strategy rejects invalid strategy", {
  skip_if_not(exists("set_embedding_strategy", mode = "function"),
              "set_embedding_strategy function not available")

  expect_error(set_embedding_strategy("invalid_strategy"))
})

test_that("EMBEDDING_STRATEGIES contains valid options", {
  skip_if_not(exists("EMBEDDING_STRATEGIES"),
              "EMBEDDING_STRATEGIES not available")

  expect_true("vocabulary" %in% EMBEDDING_STRATEGIES)
  expect_true("fasttext" %in% EMBEDDING_STRATEGIES)
  expect_true(length(EMBEDDING_STRATEGIES) >= 2)
})

# ============================================================================
# FASTTEXT AVAILABILITY TESTS
# ============================================================================

test_that("fasttext_available function exists", {
  skip_if_not(exists("fasttext_available", mode = "function"),
              "fasttext_available function not available")

  expect_true(is.function(fasttext_available))
})

test_that("fasttext_available returns boolean", {
  skip_if_not(exists("fasttext_available", mode = "function"),
              "fasttext_available function not available")

  result <- fasttext_available()

  expect_true(is.logical(result))
  expect_length(result, 1)
})

test_that("load_fasttext_model function exists", {
  skip_if_not(exists("load_fasttext_model", mode = "function"),
              "load_fasttext_model function not available")

  expect_true(is.function(load_fasttext_model))
})

test_that("load_fasttext_model handles missing file", {
  skip_if_not(exists("load_fasttext_model", mode = "function"),
              "load_fasttext_model function not available")

  result <- load_fasttext_model("nonexistent_model.bin")

  expect_false(result)
})

# ============================================================================
# TEXT EMBEDDING TESTS
# ============================================================================

test_that("create_text_embedding function exists", {
  skip_if_not(exists("create_text_embedding", mode = "function"),
              "create_text_embedding function not available")

  expect_true(is.function(create_text_embedding))
})

test_that("create_text_embedding returns correct dimension", {
  skip_if_not(exists("create_text_embedding", mode = "function"),
              "create_text_embedding function not available")

  # Test default dimension
  result <- create_text_embedding("fishing pressure")
  expect_true(is.numeric(result))
  expect_length(result, 128)  # Default dim

  # Test custom dimension
  result64 <- create_text_embedding("fishing pressure", dim = 64)
  expect_length(result64, 64)

  result256 <- create_text_embedding("fishing pressure", dim = 256)
  expect_length(result256, 256)
})

test_that("create_text_embedding handles empty input", {
  skip_if_not(exists("create_text_embedding", mode = "function"),
              "create_text_embedding function not available")

  result <- create_text_embedding("")
  expect_true(is.numeric(result))
  expect_true(all(result == 0))

  result_null <- create_text_embedding(NULL)
  expect_true(is.numeric(result_null))
  expect_true(all(result_null == 0))
})

test_that("create_text_embedding produces consistent results", {
  skip_if_not(exists("create_text_embedding", mode = "function"),
              "create_text_embedding function not available")

  text <- "Marine ecosystem health indicator"

  result1 <- create_text_embedding(text)
  result2 <- create_text_embedding(text)

  expect_equal(result1, result2)
})

test_that("create_text_embedding differentiates different texts", {
  skip_if_not(exists("create_text_embedding", mode = "function"),
              "create_text_embedding function not available")

  result1 <- create_text_embedding("fishing activity")
  result2 <- create_text_embedding("climate change")

  # Should not be identical
  expect_false(identical(result1, result2))
})

# ============================================================================
# VOCABULARY EMBEDDING TESTS
# ============================================================================

test_that("create_vocabulary_embedding function exists", {
  skip_if_not(exists("create_vocabulary_embedding", mode = "function"),
              "create_vocabulary_embedding function not available")

  expect_true(is.function(create_vocabulary_embedding))
})

test_that("create_vocabulary_embedding produces valid vectors", {
  skip_if_not(exists("create_vocabulary_embedding", mode = "function"),
              "create_vocabulary_embedding function not available")

  result <- create_vocabulary_embedding("coastal erosion")

  expect_true(is.numeric(result))
  expect_length(result, 128)
  expect_true(all(is.finite(result)))
})

# ============================================================================
# TOKENIZATION TESTS
# ============================================================================

test_that("tokenize_text function exists", {
  skip_if_not(exists("tokenize_text", mode = "function"),
              "tokenize_text function not available")

  expect_true(is.function(tokenize_text))
})

test_that("tokenize_text splits words correctly", {
  skip_if_not(exists("tokenize_text", mode = "function"),
              "tokenize_text function not available")

  result <- tokenize_text("Marine Protected Area")

  expect_true(is.character(result))
  expect_true(length(result) >= 2)
  expect_true(all(result == tolower(result)))  # Should be lowercase
})

test_that("tokenize_text handles empty input", {
  skip_if_not(exists("tokenize_text", mode = "function"),
              "tokenize_text function not available")

  expect_equal(tokenize_text(""), character())
  expect_equal(tokenize_text(NULL), character())
})

test_that("tokenize_text removes punctuation", {
  skip_if_not(exists("tokenize_text", mode = "function"),
              "tokenize_text function not available")

  result <- tokenize_text("Hello, World! How's it going?")

  # Should not contain punctuation
  expect_false(any(grepl("[,!?']", result)))
})

# ============================================================================
# CACHING TESTS
# ============================================================================

test_that("clear_embedding_cache function exists", {
  skip_if_not(exists("clear_embedding_cache", mode = "function"),
              "clear_embedding_cache function not available")

  expect_true(is.function(clear_embedding_cache))
})

test_that("clear_embedding_cache doesn't error", {
  skip_if_not(exists("clear_embedding_cache", mode = "function"),
              "clear_embedding_cache function not available")

  expect_silent(clear_embedding_cache())
})

test_that("get_embedding_stats function exists", {
  skip_if_not(exists("get_embedding_stats", mode = "function"),
              "get_embedding_stats function not available")

  expect_true(is.function(get_embedding_stats))
})

test_that("get_embedding_stats returns expected structure", {
  skip_if_not(exists("get_embedding_stats", mode = "function"),
              "get_embedding_stats function not available")

  result <- get_embedding_stats()

  expect_true(is.list(result))
  expect_true("strategy" %in% names(result))
  expect_true("fasttext_loaded" %in% names(result))
  expect_true("cache_size" %in% names(result))
})

# ============================================================================
# CUSTOM EMBEDDINGS TESTS
# ============================================================================

test_that("load_custom_embeddings function exists", {
  skip_if_not(exists("load_custom_embeddings", mode = "function"),
              "load_custom_embeddings function not available")

  expect_true(is.function(load_custom_embeddings))
})

test_that("load_custom_embeddings accepts matrix format", {
  skip_if_not(exists("load_custom_embeddings", mode = "function"),
              "load_custom_embeddings function not available")

  # Create sample embeddings
  embeddings <- matrix(runif(30), nrow = 3, ncol = 10)
  rownames(embeddings) <- c("fishing", "tourism", "conservation")

  result <- load_custom_embeddings(embeddings)

  expect_true(result)
})

# ============================================================================
# DIMENSION HELPER TESTS
# ============================================================================

test_that("ensure_dimension function exists", {
  skip_if_not(exists("ensure_dimension", mode = "function"),
              "ensure_dimension function not available")

  expect_true(is.function(ensure_dimension))
})

test_that("ensure_dimension pads short vectors", {
  skip_if_not(exists("ensure_dimension", mode = "function"),
              "ensure_dimension function not available")

  result <- ensure_dimension(c(1, 2, 3), 5)

  expect_length(result, 5)
  expect_equal(result[1:3], c(1, 2, 3))
  expect_equal(result[4:5], c(0, 0))
})

test_that("ensure_dimension truncates long vectors", {
  skip_if_not(exists("ensure_dimension", mode = "function"),
              "ensure_dimension function not available")

  result <- ensure_dimension(c(1, 2, 3, 4, 5), 3)

  expect_length(result, 3)
  expect_equal(result, c(1, 2, 3))
})

test_that("ensure_dimension preserves correct length vectors", {
  skip_if_not(exists("ensure_dimension", mode = "function"),
              "ensure_dimension function not available")

  result <- ensure_dimension(c(1, 2, 3), 3)

  expect_length(result, 3)
  expect_equal(result, c(1, 2, 3))
})
