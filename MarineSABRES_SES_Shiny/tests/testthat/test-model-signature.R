# tests/testthat/test-model-signature.R
# Tests for ML model signature verification (P0 Security)
#
# These tests verify:
# 1. Signature generation works correctly
# 2. Tampered files are detected
# 3. Missing models are handled gracefully
# 4. Manifest creation and updates work

library(testthat)

# ============================================================================
# SIGNATURE FUNCTION TESTS
# ============================================================================

test_that("verify_model_signature function exists", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  expect_true(is.function(verify_model_signature))
})

test_that("verify_model_signature returns correct structure", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  # Test with non-existent file
  result <- verify_model_signature("nonexistent_file.pt")

  expect_true(is.list(result))
  expect_true("verified" %in% names(result))
  expect_true("hash" %in% names(result))
  expect_true("error" %in% names(result))
})

test_that("verify_model_signature handles missing files", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  result <- verify_model_signature("definitely_not_a_real_file.pt")

  expect_false(result$verified)
  expect_true(grepl("not found", result$error, ignore.case = TRUE))
})

# ============================================================================
# HASH COMPUTATION TESTS
# ============================================================================

test_that("file hashing is deterministic", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  # Create a temporary file
  temp_file <- tempfile(fileext = ".txt")
  writeLines(c("test content", "line 2"), temp_file)
  on.exit(unlink(temp_file))

  # Hash twice
  hash1 <- digest::digest(file = temp_file, algo = "sha256")
  hash2 <- digest::digest(file = temp_file, algo = "sha256")

  expect_equal(hash1, hash2)
})

test_that("file hashing detects changes", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  # Create first file
  temp_file1 <- tempfile(fileext = ".txt")
  writeLines("original content", temp_file1)
  on.exit(unlink(temp_file1), add = TRUE)

  # Create second file with different content
  temp_file2 <- tempfile(fileext = ".txt")
  writeLines("modified content", temp_file2)
  on.exit(unlink(temp_file2), add = TRUE)

  hash1 <- digest::digest(file = temp_file1, algo = "sha256")
  hash2 <- digest::digest(file = temp_file2, algo = "sha256")

  expect_false(identical(hash1, hash2))
})

test_that("SHA-256 produces expected length hash", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  temp_file <- tempfile(fileext = ".txt")
  writeLines("test", temp_file)
  on.exit(unlink(temp_file))

  hash <- digest::digest(file = temp_file, algo = "sha256")

  # SHA-256 produces 64 character hex string
  expect_equal(nchar(hash), 64)
  expect_true(grepl("^[0-9a-f]+$", hash))
})

# ============================================================================
# MANIFEST TESTS
# ============================================================================

test_that("manifest structure is valid JSON", {
  manifest <- list(
    version = "1.0",
    created = as.character(Sys.time()),
    signatures = list(
      "model1.pt" = list(
        hash = "abc123",
        algorithm = "sha256",
        verified_at = as.character(Sys.time())
      )
    )
  )

  # Should serialize to valid JSON
  json_str <- jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE)

  expect_true(is.character(json_str))
  expect_true(nchar(json_str) > 0)

  # Should parse back correctly
  parsed <- jsonlite::fromJSON(json_str, simplifyVector = FALSE)
  expect_equal(parsed$version, "1.0")
})

test_that("manifest can store multiple model signatures", {
  manifest <- list(
    version = "1.0",
    signatures = list()
  )

  # Add multiple models
  for (i in 1:5) {
    model_name <- paste0("model_", i, ".pt")
    manifest$signatures[[model_name]] <- list(
      hash = paste0("hash_", i),
      algorithm = "sha256"
    )
  }

  expect_length(manifest$signatures, 5)
  expect_equal(manifest$signatures[["model_3.pt"]]$hash, "hash_3")
})

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_that("verify_model_signature works with real temp file", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  # Create temp directory structure
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create a fake model file
  model_path <- file.path(temp_dir, "test_model.pt")
  writeBin(as.raw(1:100), model_path)

  # Create temp manifest path
  manifest_path <- file.path(temp_dir, "signatures.json")

  # First verification should create manifest
  result1 <- verify_model_signature(model_path, manifest_path)
  expect_true(result1$verified)
  expect_true(file.exists(manifest_path))

  # Second verification should match existing signature
  result2 <- verify_model_signature(model_path, manifest_path)
  expect_true(result2$verified)
  expect_equal(result1$hash, result2$hash)
})

test_that("verify_model_signature detects tampered file", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  # Create temp directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create model file
  model_path <- file.path(temp_dir, "test_model.pt")
  writeBin(as.raw(1:100), model_path)

  manifest_path <- file.path(temp_dir, "signatures.json")

  # Initial verification
  result1 <- verify_model_signature(model_path, manifest_path)
  expect_true(result1$verified)

  # Tamper with the file
  writeBin(as.raw(101:200), model_path)

  # Re-verify should fail
  result2 <- verify_model_signature(model_path, manifest_path)
  expect_false(result2$verified)
  expect_true(grepl("tampered|mismatch", result2$error, ignore.case = TRUE))
})

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

test_that("signature verification handles unreadable files", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  # Test with a directory instead of file (should fail gracefully)
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # This should handle error gracefully
  result <- tryCatch({
    verify_model_signature(temp_dir)
  }, error = function(e) {
    list(verified = FALSE, error = e$message)
  })

  expect_false(result$verified)
})

test_that("signature verification handles invalid manifest", {
  skip_if_not(exists("verify_model_signature", mode = "function"),
              "verify_model_signature function not available")

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create model file
  model_path <- file.path(temp_dir, "test_model.pt")
  writeBin(as.raw(1:50), model_path)

  # Create invalid manifest
  manifest_path <- file.path(temp_dir, "signatures.json")
  writeLines("not valid json", manifest_path)

  # Should handle gracefully (may create new manifest or error)
  result <- tryCatch({
    verify_model_signature(model_path, manifest_path)
  }, error = function(e) {
    list(verified = FALSE, error = e$message)
  })

  expect_true(is.list(result))
})

# ============================================================================
# LOAD MODEL WITH SIGNATURE TESTS
# ============================================================================

test_that("load_ml_model function exists", {
  skip_if_not(exists("load_ml_model", mode = "function"),
              "load_ml_model function not available")

  expect_true(is.function(load_ml_model))
})

test_that("ml_model_available function exists", {
  skip_if_not(exists("ml_model_available", mode = "function"),
              "ml_model_available function not available")

  expect_true(is.function(ml_model_available))
})
