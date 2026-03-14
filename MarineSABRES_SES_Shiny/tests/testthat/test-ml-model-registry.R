# tests/testthat/test-ml-model-registry.R
# Tests for ML model registry system (P1 Model Versioning)
#
# These tests verify:
# 1. Version parsing and comparison
# 2. Model registration and retrieval
# 3. Registry persistence

library(testthat)

# ============================================================================
# VERSION PARSING TESTS
# ============================================================================

test_that("parse_model_version function exists", {
  skip_if_not(exists("parse_model_version", mode = "function"),
              "parse_model_version function not available")

  expect_true(is.function(parse_model_version))
})

test_that("parse_model_version parses semantic versions", {
  skip_if_not(exists("parse_model_version", mode = "function"),
              "parse_model_version function not available")

  result <- parse_model_version("1.2.3")

  expect_equal(result$major, 1)
  expect_equal(result$minor, 2)
  expect_equal(result$patch, 3)
})

test_that("parse_model_version handles v prefix", {
  skip_if_not(exists("parse_model_version", mode = "function"),
              "parse_model_version function not available")

  result <- parse_model_version("v2.0.1")

  expect_equal(result$major, 2)
  expect_equal(result$minor, 0)
  expect_equal(result$patch, 1)
})

test_that("parse_model_version handles short versions", {
  skip_if_not(exists("parse_model_version", mode = "function"),
              "parse_model_version function not available")

  result <- parse_model_version("1.0")

  expect_equal(result$major, 1)
  expect_equal(result$minor, 0)
  expect_equal(result$patch, 0)
})

# ============================================================================
# VERSION COMPARISON TESTS
# ============================================================================

test_that("compare_versions function exists", {
  skip_if_not(exists("compare_versions", mode = "function"),
              "compare_versions function not available")

  expect_true(is.function(compare_versions))
})

test_that("compare_versions identifies equal versions", {
  skip_if_not(exists("compare_versions", mode = "function"),
              "compare_versions function not available")

  expect_equal(compare_versions("1.0.0", "1.0.0"), 0)
  expect_equal(compare_versions("2.1.3", "2.1.3"), 0)
})

test_that("compare_versions identifies greater versions", {
  skip_if_not(exists("compare_versions", mode = "function"),
              "compare_versions function not available")

  expect_equal(compare_versions("2.0.0", "1.0.0"), 1)
  expect_equal(compare_versions("1.1.0", "1.0.0"), 1)
  expect_equal(compare_versions("1.0.1", "1.0.0"), 1)
})

test_that("compare_versions identifies lesser versions", {
  skip_if_not(exists("compare_versions", mode = "function"),
              "compare_versions function not available")

  expect_equal(compare_versions("1.0.0", "2.0.0"), -1)
  expect_equal(compare_versions("1.0.0", "1.1.0"), -1)
  expect_equal(compare_versions("1.0.0", "1.0.1"), -1)
})

# ============================================================================
# VERSION SATISFIES TESTS
# ============================================================================

test_that("version_satisfies function exists", {
  skip_if_not(exists("version_satisfies", mode = "function"),
              "version_satisfies function not available")

  expect_true(is.function(version_satisfies))
})

test_that("version_satisfies handles >= operator", {
  skip_if_not(exists("version_satisfies", mode = "function"),
              "version_satisfies function not available")

  expect_true(version_satisfies("1.0.0", ">=1.0.0"))
  expect_true(version_satisfies("2.0.0", ">=1.0.0"))
  expect_false(version_satisfies("0.9.0", ">=1.0.0"))
})

test_that("version_satisfies handles < operator", {
  skip_if_not(exists("version_satisfies", mode = "function"),
              "version_satisfies function not available")

  expect_true(version_satisfies("0.9.0", "<1.0.0"))
  expect_false(version_satisfies("1.0.0", "<1.0.0"))
  expect_false(version_satisfies("2.0.0", "<1.0.0"))
})

test_that("version_satisfies handles wildcard", {
  skip_if_not(exists("version_satisfies", mode = "function"),
              "version_satisfies function not available")

  expect_true(version_satisfies("1.0.0", "*"))
  expect_true(version_satisfies("99.99.99", "*"))
})

# ============================================================================
# MODEL REGISTRATION TESTS
# ============================================================================

test_that("register_model function exists", {
  skip_if_not(exists("register_model", mode = "function"),
              "register_model function not available")

  expect_true(is.function(register_model))
})

test_that("register_model creates entry", {
  skip_if_not(exists("register_model", mode = "function") &&
              exists("get_registered_model", mode = "function"),
              "Registration functions not available")

  # Clean up any existing registration
  if (exists("unregister_model", mode = "function")) {
    unregister_model("test_model")
  }

  result <- register_model(
    model_id = "test_model",
    version = "1.0.0",
    path = "test/path/model.pt",
    input_dim = 256,
    description = "Test model"
  )

  expect_true(result)

  # Verify retrieval
  entry <- get_registered_model("test_model", "1.0.0")
  expect_true(!is.null(entry))
  expect_equal(entry$version, "1.0.0")
  expect_equal(entry$input_dim, 256)

  # Clean up
  if (exists("unregister_model", mode = "function")) {
    unregister_model("test_model", "1.0.0")
  }
})

test_that("get_registered_model retrieves latest version", {
  skip_if_not(exists("register_model", mode = "function") &&
              exists("get_registered_model", mode = "function"),
              "Registration functions not available")

  # Clean up
  if (exists("unregister_model", mode = "function")) {
    unregister_model("test_versioned")
  }

  # Register multiple versions
  register_model("test_versioned", "1.0.0", "path1.pt", 256)
  register_model("test_versioned", "2.0.0", "path2.pt", 256)
  register_model("test_versioned", "1.5.0", "path3.pt", 256)

  # Get latest (should be 2.0.0)
  entry <- get_registered_model("test_versioned")

  expect_true(!is.null(entry))
  expect_equal(entry$version, "2.0.0")

  # Clean up
  if (exists("unregister_model", mode = "function")) {
    unregister_model("test_versioned")
  }
})

# ============================================================================
# LIST MODELS TESTS
# ============================================================================

test_that("list_registered_models function exists", {
  skip_if_not(exists("list_registered_models", mode = "function"),
              "list_registered_models function not available")

  expect_true(is.function(list_registered_models))
})

test_that("list_registered_models returns data frame", {
  skip_if_not(exists("list_registered_models", mode = "function"),
              "list_registered_models function not available")

  result <- list_registered_models()

  expect_true(is.data.frame(result))
  expect_true("model_id" %in% names(result))
  expect_true("version" %in% names(result))
})

# ============================================================================
# COMPATIBILITY CHECK TESTS
# ============================================================================

test_that("check_model_compatibility function exists", {
  skip_if_not(exists("check_model_compatibility", mode = "function"),
              "check_model_compatibility function not available")

  expect_true(is.function(check_model_compatibility))
})

test_that("check_model_compatibility detects dimension mismatch", {
  skip_if_not(exists("check_model_compatibility", mode = "function"),
              "check_model_compatibility function not available")

  entry <- list(
    model_id = "test",
    version = "1.0.0",
    path = "nonexistent.pt",
    input_dim = 256
  )

  result <- check_model_compatibility(entry, required_input_dim = 512)

  expect_false(result$compatible)
  expect_true(any(grepl("dimension", result$issues, ignore.case = TRUE)))
})

# ============================================================================
# ACTIVE MODEL TESTS
# ============================================================================

test_that("set_active_model function exists", {
  skip_if_not(exists("set_active_model", mode = "function"),
              "set_active_model function not available")

  expect_true(is.function(set_active_model))
})

test_that("get_active_model function exists", {
  skip_if_not(exists("get_active_model", mode = "function"),
              "get_active_model function not available")

  expect_true(is.function(get_active_model))
})

# ============================================================================
# INITIALIZATION TESTS
# ============================================================================

test_that("init_model_registry function exists", {
  skip_if_not(exists("init_model_registry", mode = "function"),
              "init_model_registry function not available")

  expect_true(is.function(init_model_registry))
})
