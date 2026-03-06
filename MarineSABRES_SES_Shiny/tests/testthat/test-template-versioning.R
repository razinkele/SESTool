# tests/testthat/test-template-versioning.R
# Tests for Template Versioning System (P2 #34)
#
# These tests verify:
# 1. Version metadata creation
# 2. Version persistence (save/load)
# 3. Version history retrieval
# 4. Version comparison
# 5. Backward compatibility

library(testthat)

# ============================================================================
# VERSION CREATION TESTS
# ============================================================================

test_that("create_template_version function exists", {
  skip_if_not(exists("create_template_version", mode = "function"),
              "create_template_version function not available")

  expect_true(is.function(create_template_version))
})

test_that("create_template_version returns correct structure", {
  skip_if_not(exists("create_template_version", mode = "function"),
              "create_template_version function not available")

  result <- create_template_version(
    template_name = "Test Template",
    version = "1.0.0",
    author = "Test Author",
    description = "Test description"
  )

  expect_true(is.list(result))
  expect_true("template_version" %in% class(result))

  # Check required fields
  expect_equal(result$template_name, "Test Template")
  expect_equal(result$version, "1.0.0")
  expect_equal(result$author, "Test Author")
  expect_equal(result$description, "Test description")
  expect_true(!is.null(result$created_date))
})

test_that("create_template_version includes system info", {
  skip_if_not(exists("create_template_version", mode = "function"),
              "create_template_version function not available")

  result <- create_template_version(
    template_name = "System Info Test",
    version = "1.0"
  )

  expect_true(!is.null(result$r_version))
  expect_true(!is.null(result$torch_version))
})

test_that("create_template_version handles optional parameters", {
  skip_if_not(exists("create_template_version", mode = "function"),
              "create_template_version function not available")

  # With optional parameters
  result <- create_template_version(
    template_name = "Full Template",
    version = "2.0",
    regional_sea = "Baltic Sea",
    ecosystem_types = "Coastal;Marine",
    main_issues = "Eutrophication;Overfishing",
    training_strategy = "finetune",
    source_template = "Base Template",
    performance = list(accuracy = 0.85, val_loss = 0.12),
    training_config = list(epochs = 100, learning_rate = 0.001)
  )

  expect_equal(result$regional_sea, "Baltic Sea")
  expect_equal(result$training_strategy, "finetune")
  expect_equal(result$source_template, "Base Template")
  expect_equal(result$performance$accuracy, 0.85)
  expect_equal(result$training_config$epochs, 100)
})

# ============================================================================
# VERSION PERSISTENCE TESTS
# ============================================================================

test_that("save_template_version function exists", {
  skip_if_not(exists("save_template_version", mode = "function"),
              "save_template_version function not available")

  expect_true(is.function(save_template_version))
})

test_that("load_template_version function exists", {
  skip_if_not(exists("load_template_version", mode = "function"),
              "load_template_version function not available")

  expect_true(is.function(load_template_version))
})

test_that("save and load round-trip preserves data", {
  skip_if_not(exists("save_template_version", mode = "function") &&
              exists("load_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version persistence functions not available")

  # Create temp directory for test
  temp_dir <- tempfile("version_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create and save version
  original <- create_template_version(
    template_name = "Round Trip Test",
    version = "1.0.0",
    author = "Tester",
    description = "Testing round trip",
    performance = list(accuracy = 0.92)
  )

  saved_path <- save_template_version(original, versions_dir = temp_dir)
  expect_true(file.exists(saved_path))

  # Load and compare
  loaded <- load_template_version(saved_path)

  expect_equal(loaded$template_name, original$template_name)
  expect_equal(loaded$version, original$version)
  expect_equal(loaded$author, original$author)
  expect_equal(loaded$performance$accuracy, original$performance$accuracy)
})

test_that("load_template_version handles missing file", {
  skip_if_not(exists("load_template_version", mode = "function"),
              "load_template_version function not available")

  expect_error(load_template_version("nonexistent_file.rds"))
})

# ============================================================================
# VERSION HISTORY TESTS
# ============================================================================

test_that("get_version_history function exists", {
  skip_if_not(exists("get_version_history", mode = "function"),
              "get_version_history function not available")

  expect_true(is.function(get_version_history))
})

test_that("get_version_history returns empty dataframe for missing dir", {
  skip_if_not(exists("get_version_history", mode = "function"),
              "get_version_history function not available")

  result <- get_version_history("Test Template", versions_dir = "nonexistent_dir_xyz")

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("get_version_history retrieves multiple versions", {
  skip_if_not(exists("get_version_history", mode = "function") &&
              exists("save_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version history functions not available")

  # Create temp directory
  temp_dir <- tempfile("history_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  template_name <- "History Test Template"

  # Save multiple versions
  v1 <- create_template_version(template_name, "1.0", performance = list(accuracy = 0.80))
  save_template_version(v1, temp_dir)

  Sys.sleep(0.1)  # Ensure different timestamps

  v2 <- create_template_version(template_name, "1.1", performance = list(accuracy = 0.85))
  save_template_version(v2, temp_dir)

  # Get history
  history <- get_version_history(template_name, temp_dir)

  expect_true(is.data.frame(history))
  expect_equal(nrow(history), 2)
  expect_true("version" %in% names(history))
  expect_true("accuracy" %in% names(history))
})

test_that("get_latest_version function exists", {
  skip_if_not(exists("get_latest_version", mode = "function"),
              "get_latest_version function not available")

  expect_true(is.function(get_latest_version))
})

test_that("get_latest_version returns NULL for no versions", {
  skip_if_not(exists("get_latest_version", mode = "function"),
              "get_latest_version function not available")

  result <- get_latest_version("Nonexistent Template", "nonexistent_dir_xyz")
  expect_null(result)
})

# ============================================================================
# VERSION COMPARISON TESTS
# ============================================================================

test_that("compare_versions function exists", {
  skip_if_not(exists("compare_versions", mode = "function"),
              "compare_versions function not available")

  expect_true(is.function(compare_versions))
})

test_that("compare_versions calculates differences", {
  skip_if_not(exists("compare_versions", mode = "function") &&
              exists("save_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version comparison functions not available")

  # Create temp directory
  temp_dir <- tempfile("compare_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create two versions with different performance
  v1 <- create_template_version(
    "Compare Template", "1.0",
    performance = list(accuracy = 0.80, val_loss = 0.20),
    training_strategy = "scratch"
  )
  path1 <- save_template_version(v1, temp_dir)

  v2 <- create_template_version(
    "Compare Template", "2.0",
    performance = list(accuracy = 0.90, val_loss = 0.10),
    training_strategy = "finetune"
  )
  path2 <- save_template_version(v2, temp_dir)

  # Compare
  comparison <- compare_versions(path1, path2)

  expect_true(is.list(comparison))
  expect_true("version1" %in% names(comparison))
  expect_true("version2" %in% names(comparison))
  expect_true("differences" %in% names(comparison))

  # Check accuracy improvement calculated
  expect_true(!is.null(comparison$differences$accuracy_change))
  expect_equal(comparison$differences$accuracy_change, 0.10, tolerance = 0.001)

  # Check strategy changed
  expect_true(comparison$differences$strategy_changed)
})

# ============================================================================
# VERSION MANAGEMENT TESTS
# ============================================================================

test_that("create_new_version_from_base function exists", {
  skip_if_not(exists("create_new_version_from_base", mode = "function"),
              "create_new_version_from_base function not available")

  expect_true(is.function(create_new_version_from_base))
})

test_that("create_new_version_from_base inherits from base", {
  skip_if_not(exists("create_new_version_from_base", mode = "function") &&
              exists("save_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version management functions not available")

  # Create temp directory
  temp_dir <- tempfile("inherit_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create base version
  base <- create_template_version(
    "Inheritance Test", "1.0",
    author = "Original Author",
    regional_sea = "North Sea",
    performance = list(accuracy = 0.75)
  )
  base_path <- save_template_version(base, temp_dir)

  # Create new version from base
  new_version <- create_new_version_from_base(
    base_path,
    new_version = "2.0",
    changes = "Improved training"
  )

  expect_equal(new_version$template_name, "Inheritance Test")
  expect_equal(new_version$version, "2.0")
  expect_equal(new_version$author, "Original Author")  # Inherited
  expect_equal(new_version$regional_sea, "North Sea")  # Inherited
  expect_true(grepl("Based on v1.0", new_version$notes))
})

# ============================================================================
# UTILITY FUNCTION TESTS
# ============================================================================

test_that("list_all_templates function exists", {
  skip_if_not(exists("list_all_templates", mode = "function"),
              "list_all_templates function not available")

  expect_true(is.function(list_all_templates))
})

test_that("list_all_templates returns empty for missing dir", {
  skip_if_not(exists("list_all_templates", mode = "function"),
              "list_all_templates function not available")

  result <- list_all_templates("nonexistent_dir_xyz")

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("print_version_summary function exists", {
  skip_if_not(exists("print_version_summary", mode = "function"),
              "print_version_summary function not available")

  expect_true(is.function(print_version_summary))
})

test_that("print_version_summary handles valid input", {
  skip_if_not(exists("print_version_summary", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version summary functions not available")

  version <- create_template_version(
    "Print Test", "1.0",
    author = "Test",
    performance = list(accuracy = 0.85)
  )

  # Should not error
  expect_silent(capture.output(print_version_summary(version)))
})

test_that("generate_version_report function exists", {
  skip_if_not(exists("generate_version_report", mode = "function"),
              "generate_version_report function not available")

  expect_true(is.function(generate_version_report))
})

# ============================================================================
# EDGE CASE TESTS
# ============================================================================

test_that("version with special characters in name is handled", {
  skip_if_not(exists("save_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version functions not available")

  temp_dir <- tempfile("special_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Template name with special characters
  version <- create_template_version(
    "Test Template (Special!)",
    "1.0"
  )

  # Should not error
  path <- save_template_version(version, temp_dir)
  expect_true(file.exists(path))
})

test_that("version comparison handles missing performance data", {
  skip_if_not(exists("compare_versions", mode = "function") &&
              exists("save_template_version", mode = "function") &&
              exists("create_template_version", mode = "function"),
              "Version functions not available")

  temp_dir <- tempfile("missing_perf_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Versions without performance data
  v1 <- create_template_version("No Perf Test", "1.0")
  path1 <- save_template_version(v1, temp_dir)

  v2 <- create_template_version("No Perf Test", "2.0")
  path2 <- save_template_version(v2, temp_dir)

  # Should not error
  comparison <- compare_versions(path1, path2)
  expect_true(is.list(comparison))
})
