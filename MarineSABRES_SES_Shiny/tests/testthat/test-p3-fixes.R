# test-p3-fixes.R
# Verification tests for P3 (Priority 3) fixes from IMPROVEMENT_PLAN.md
#
# P3 Issues:
#   Issue #13: Server Function Extraction
#   Issue #14: Performance Optimization
#   Issue #15: Documentation Updates

# Helper to get project root
project_root <- if (exists("PROJECT_ROOT") && !is.null(PROJECT_ROOT)) {
  PROJECT_ROOT
} else {
  test_dir <- getwd()
  if (grepl("testthat$", test_dir)) {
    normalizePath(file.path(test_dir, "..", ".."), mustWork = FALSE)
  } else {
    test_dir
  }
}

# ============================================================================
# Issue #13: Server Function Extraction
# ============================================================================

test_that("P3 - server/session_management.R exists and has required functions", {
  file_path <- file.path(project_root, "server/session_management.R")
  expect_true(file.exists(file_path), info = "session_management.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key functions
  expect_true(grepl("init_session_isolation", content_text),
              info = "Should have init_session_isolation function")
  expect_true(grepl("init_session_reactive_values", content_text),
              info = "Should have init_session_reactive_values function")
  expect_true(grepl("clear_server_autosaves", content_text),
              info = "Should have clear_server_autosaves function")
  expect_true(grepl("log_session_diagnostics", content_text),
              info = "Should have log_session_diagnostics function")
})

test_that("P3 - server/language_handling.R exists and has required functions", {
  file_path <- file.path(project_root, "server/language_handling.R")
  expect_true(file.exists(file_path), info = "language_handling.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key functions
  expect_true(grepl("create_session_i18n", content_text),
              info = "Should have create_session_i18n function")
  expect_true(grepl("setup_language_restore_handler", content_text),
              info = "Should have setup_language_restore_handler function")
  expect_true(grepl("get_supported_languages", content_text),
              info = "Should have get_supported_languages function")
  expect_true(grepl("is_valid_language", content_text),
              info = "Should have is_valid_language function")
})

test_that("P3 - server/event_bus_setup.R exists and has required functions", {
  file_path <- file.path(project_root, "server/event_bus_setup.R")
  expect_true(file.exists(file_path), info = "event_bus_setup.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key functions
  expect_true(grepl("create_event_bus", content_text),
              info = "Should have create_event_bus function")
  expect_true(grepl("is_event_bus", content_text),
              info = "Should have is_event_bus function")
  expect_true(grepl("safe_emit_isa_change", content_text),
              info = "Should have safe_emit_isa_change function")
  expect_true(grepl("safe_emit_cld_update", content_text),
              info = "Should have safe_emit_cld_update function")
  expect_true(grepl("setup_navigation_handler", content_text),
              info = "Should have setup_navigation_handler function")
})

test_that("P3 - app.R includes new server files in critical_sources", {
  file_path <- file.path(project_root, "app.R")
  expect_true(file.exists(file_path), info = "app.R should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check that critical_sources includes the new files
  expect_true(grepl("server/session_management\\.R", content_text),
              info = "app.R should include session_management.R in critical_sources")
  expect_true(grepl("server/language_handling\\.R", content_text),
              info = "app.R should include language_handling.R in critical_sources")
  expect_true(grepl("server/event_bus_setup\\.R", content_text),
              info = "app.R should include event_bus_setup.R in critical_sources")
})

# ============================================================================
# Issue #14: Performance Optimization (Lazy Loading) - REMOVED
# Lazy loading infrastructure was removed as all modules are eagerly loaded.
# The lazy_loading.R file and its source line in global.R have been removed.
# ============================================================================

test_that("P3 - lazy_loading.R has been removed (modules are eagerly loaded)", {
  file_path <- file.path(project_root, "functions/lazy_loading.R")
  expect_false(file.exists(file_path),
               info = "lazy_loading.R should no longer exist - modules are eagerly loaded")

  # global.R should have a comment explaining removal
  global_content <- paste(readLines(file.path(project_root, "global.R"), warn = FALSE), collapse = "
")
  expect_true(grepl("Lazy loading infrastructure removed", global_content),
              info = "global.R should have comment about lazy loading removal")
})

# ============================================================================
# Issue #15: Documentation Updates
# ============================================================================

test_that("P3 - docs/ML_ARCHITECTURE.md exists and is comprehensive", {
  file_path <- file.path(project_root, "docs/ML_ARCHITECTURE.md")
  expect_true(file.exists(file_path), info = "ML_ARCHITECTURE.md should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key sections
  expect_true(grepl("## Overview", content_text),
              info = "Should have Overview section")
  expect_true(grepl("## File Structure", content_text),
              info = "Should have File Structure section")
  expect_true(grepl("## Feature Engineering", content_text),
              info = "Should have Feature Engineering section")
  expect_true(grepl("## Model Architecture", content_text),
              info = "Should have Model Architecture section")
  expect_true(grepl("## Ensemble System", content_text),
              info = "Should have Ensemble System section")
  expect_true(grepl("## API Reference", content_text),
              info = "Should have API Reference section")

  # Check for key technical content
  expect_true(grepl("ensemble_predict", content_text),
              info = "Should document ensemble_predict function")
  expect_true(grepl("ml_feature_engineering", content_text),
              info = "Should document feature engineering module")
})

test_that("P3 - docs/MOCKING_STRATEGY.md exists and is comprehensive", {
  file_path <- file.path(project_root, "docs/MOCKING_STRATEGY.md")
  expect_true(file.exists(file_path), info = "MOCKING_STRATEGY.md should exist")

  content <- readLines(file_path, warn = FALSE)
  content_text <- paste(content, collapse = "\n")

  # Check for key sections
  expect_true(grepl("## Overview", content_text),
              info = "Should have Overview section")
  expect_true(grepl("Mock Data Factories", content_text),
              info = "Should document Mock Data Factories")
  expect_true(grepl("Module Stubs", content_text),
              info = "Should document Module Stubs")
  expect_true(grepl("Session Mock", content_text),
              info = "Should document Session Mocks")
  expect_true(grepl("ReactiveVal", content_text),
              info = "Should document ReactiveVal override")

  # Check for code examples
  expect_true(grepl("create_mock_isa_data", content_text),
              info = "Should show create_mock_isa_data example")
  expect_true(grepl("MockShinySession", content_text),
              info = "Should show MockShinySession example")
})

# ============================================================================
# Server Function Tests (Functional)
# ============================================================================

test_that("P3 - session_management functions are syntactically correct", {
  file_path <- file.path(project_root, "server/session_management.R")
  skip_if_not(file.exists(file_path), "session_management.R not found")

  # Try to parse the file - will error if syntax is invalid
  result <- tryCatch({
    parse(file_path)
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "session_management.R should have valid R syntax")
})

test_that("P3 - language_handling functions are syntactically correct", {
  file_path <- file.path(project_root, "server/language_handling.R")
  skip_if_not(file.exists(file_path), "language_handling.R not found")

  # Try to parse the file - will error if syntax is invalid
  result <- tryCatch({
    parse(file_path)
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "language_handling.R should have valid R syntax")
})

test_that("P3 - event_bus_setup functions are syntactically correct", {
  file_path <- file.path(project_root, "server/event_bus_setup.R")
  skip_if_not(file.exists(file_path), "event_bus_setup.R not found")

  # Try to parse the file - will error if syntax is invalid
  result <- tryCatch({
    parse(file_path)
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "event_bus_setup.R should have valid R syntax")
})

# lazy_loading syntax test removed - file no longer exists (modules are eagerly loaded)

# ============================================================================
# Event Bus Functional Tests
# ============================================================================

test_that("P3 - Event bus can be created and used", {
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not loaded")

  # Create event bus
  event_bus <- create_event_bus(session_id = "test_session")

  # Verify structure - basic requirements for any event bus implementation
  expect_true(is.list(event_bus), info = "Event bus should be a list")
  expect_true("emit_isa_change" %in% names(event_bus),
              info = "Should have emit_isa_change")

  # Check for at least one of the CLD-related functions
  # (different implementations may use different names)
  has_cld_function <- "emit_cld_update" %in% names(event_bus) ||
                      "emit_cld_change" %in% names(event_bus) ||
                      "cld_changed" %in% names(event_bus)
  expect_true(has_cld_function,
              info = "Should have some CLD-related function")
})

test_that("P3 - is_event_bus correctly identifies event bus (if available)", {
  # This function is in the new event_bus_setup.R, may not be loaded
  # if the old reactive_pipeline.R is used
  skip_if_not(exists("is_event_bus", mode = "function"),
              "is_event_bus function not loaded (optional in older implementation)")
  skip_if_not(exists("create_event_bus", mode = "function"),
              "create_event_bus function not loaded")

  event_bus <- create_event_bus()

  expect_true(is_event_bus(event_bus))
  expect_false(is_event_bus(list()))
  expect_false(is_event_bus(NULL))
  expect_false(is_event_bus("not an event bus"))
})

# ============================================================================
# Lazy Loading Functional Tests
# ============================================================================

test_that("P3 - Lazy module registry can be initialized", {
  skip_if_not(exists("init_lazy_module_registry", mode = "function"),
              "init_lazy_module_registry function not loaded")

  # Should not error
  result <- tryCatch({
    init_lazy_module_registry()
    TRUE
  }, error = function(e) {
    FALSE
  })

  expect_true(result, info = "init_lazy_module_registry should execute without error")
})

test_that("P3 - get_lazy_load_stats returns data frame", {
  skip_if_not(exists("get_lazy_load_stats", mode = "function"),
              "get_lazy_load_stats function not loaded")

  stats <- get_lazy_load_stats()

  expect_true(is.data.frame(stats), info = "Should return data frame")
  expect_true("module_id" %in% names(stats), info = "Should have module_id column")
  expect_true("category" %in% names(stats), info = "Should have category column")
  expect_true("loaded" %in% names(stats), info = "Should have loaded column")
})

# ============================================================================
# ML Cache Functional Tests
# ============================================================================

test_that("P3 - ML feature cache functions work correctly", {
  skip_if_not(exists("cache_ml_features", mode = "function"),
              "cache_ml_features function not loaded")
  skip_if_not(exists("get_cached_ml_features", mode = "function"),
              "get_cached_ml_features function not loaded")
  skip_if_not(exists("clear_ml_feature_cache", mode = "function"),
              "clear_ml_feature_cache function not loaded")

  # Clear cache first
  clear_ml_feature_cache()

  # Test caching
  test_features <- c(1.0, 2.0, 3.0)
  cache_ml_features("test_element_1", test_features, ttl_seconds = 60)

  # Test retrieval
  cached <- get_cached_ml_features("test_element_1")
  expect_equal(cached, test_features, info = "Should retrieve cached features")

  # Test non-existent key
  non_existent <- get_cached_ml_features("non_existent_key")
  expect_null(non_existent, info = "Non-existent key should return NULL")

  # Clean up
  clear_ml_feature_cache()
})

test_that("P3 - get_ml_cache_stats returns cache statistics", {
  skip_if_not(exists("get_ml_cache_stats", mode = "function"),
              "get_ml_cache_stats function not loaded")

  stats <- get_ml_cache_stats()

  expect_true(is.list(stats), info = "Should return list")
  expect_true("cached_count" %in% names(stats), info = "Should have cached_count")
  expect_true("max_size" %in% names(stats), info = "Should have max_size")
})

# ============================================================================
# Integration Tests
# ============================================================================

test_that("P3 - All P3 files are valid R code", {
  p3_files <- c(
    "server/session_management.R",
    "server/language_handling.R",
    "server/event_bus_setup.R"
  )

  for (rel_path in p3_files) {
    file_path <- file.path(project_root, rel_path)
    skip_if_not(file.exists(file_path), paste(rel_path, "not found"))

    result <- tryCatch({
      parse(file_path)
      TRUE
    }, error = function(e) {
      message(sprintf("Parse error in %s: %s", rel_path, e$message))
      FALSE
    })

    expect_true(result, info = sprintf("%s should parse without errors", rel_path))
  }
})

test_that("P3 - Documentation files contain required metadata", {
  doc_files <- c(
    "docs/ML_ARCHITECTURE.md",
    "docs/MOCKING_STRATEGY.md"
  )

  for (rel_path in doc_files) {
    file_path <- file.path(project_root, rel_path)
    skip_if_not(file.exists(file_path), paste(rel_path, "not found"))

    content <- readLines(file_path, warn = FALSE)
    content_text <- paste(content, collapse = "\n")

    # Check for version info
    expect_true(grepl("Version", content_text, ignore.case = TRUE),
                info = sprintf("%s should have version info", rel_path))

    # Check for last updated
    expect_true(grepl("Updated", content_text, ignore.case = TRUE),
                info = sprintf("%s should have last updated info", rel_path))
  }
})
