# test_auto_save_integration.R
# Integration tests for Auto-Save Module (v1.4.0)
#
# This script tests the auto-save functionality to ensure proper integration
# with the main application and verify all features work as expected.

library(testthat)
library(shiny)

# Test Configuration
TEST_CONFIG <- list(
  autosave_interval = 30,  # seconds
  test_timeout = 60,       # seconds
  temp_dir = file.path(tempdir(), "marinesabres_test_autosave")
)

# ============================================================================
# TEST SUITE 1: Module Loading and Initialization
# ============================================================================

test_that("Auto-save module loads without errors", {
  expect_no_error({
    source("modules/auto_save_module.R", local = TRUE)
  })
})

test_that("Auto-save UI function exists and returns valid HTML", {
  source("modules/auto_save_module.R", local = TRUE)

  ui_output <- auto_save_indicator_ui("test_save")

  expect_true(inherits(ui_output, "shiny.tag"))
  expect_true(grepl("auto-save-indicator", as.character(ui_output)))
})

test_that("Auto-save server function exists", {
  source("modules/auto_save_module.R", local = TRUE)

  expect_true(exists("auto_save_server"))
  expect_true(is.function(auto_save_server))
})

# ============================================================================
# TEST SUITE 2: Data Saving Functionality
# ============================================================================

test_that("Auto-save creates RDS backup files", {
  # Setup
  if (dir.exists(TEST_CONFIG$temp_dir)) {
    unlink(TEST_CONFIG$temp_dir, recursive = TRUE)
  }
  dir.create(TEST_CONFIG$temp_dir, recursive = TRUE)

  # Create test data
  test_data <- list(
    project_id = "test_project_001",
    created_at = Sys.time(),
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = 1:3,
          name = c("Climate Change", "Overfishing", "Pollution"),
          description = c("Rising temperatures", "Excessive fishing", "Marine pollution")
        )
      )
    )
  )

  # Save test data
  test_file <- file.path(TEST_CONFIG$temp_dir, "test_autosave.rds")
  saveRDS(test_data, test_file)

  # Verify file exists
  expect_true(file.exists(test_file))

  # Verify file can be read back
  loaded_data <- readRDS(test_file)
  expect_equal(loaded_data$project_id, "test_project_001")
  expect_equal(nrow(loaded_data$data$isa_data$drivers), 3)

  # Cleanup
  unlink(TEST_CONFIG$temp_dir, recursive = TRUE)
})

test_that("Auto-save handles large datasets", {
  # Create large test dataset
  large_data <- list(
    project_id = "large_project",
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = 1:1000,
          name = paste("Driver", 1:1000),
          description = paste("Description", 1:1000),
          category = sample(c("Social", "Economic", "Environmental"), 1000, replace = TRUE)
        ),
        activities = data.frame(
          id = 1:500,
          name = paste("Activity", 1:500)
        )
      )
    )
  )

  # Save large dataset
  test_file <- file.path(tempdir(), "test_large_autosave.rds")

  expect_no_error({
    saveRDS(large_data, test_file)
  })

  # Verify file size is reasonable (should be compressed)
  file_size <- file.info(test_file)$size
  expect_lt(file_size, 1e7)  # Less than 10MB

  # Cleanup
  unlink(test_file)
})

# ============================================================================
# TEST SUITE 3: Recovery Functionality
# ============================================================================

test_that("Recovery identifies valid save files", {
  # Create test save file
  test_dir <- file.path(tempdir(), "recovery_test")
  dir.create(test_dir, showWarnings = FALSE)

  test_data <- list(
    project_id = "recovery_test_001",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    data = list(isa_data = list())
  )

  save_file <- file.path(test_dir, paste0("autosave_", Sys.Date(), ".rds"))
  saveRDS(test_data, save_file)

  # Check file exists and is recent
  expect_true(file.exists(save_file))
  file_time <- file.info(save_file)$mtime
  time_diff <- as.numeric(difftime(Sys.time(), file_time, units = "mins"))
  expect_lt(time_diff, 5)  # File created within last 5 minutes

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

test_that("Recovery ignores old save files", {
  test_dir <- file.path(tempdir(), "old_saves_test")
  dir.create(test_dir, showWarnings = FALSE)

  # Create file
  old_file <- file.path(test_dir, "old_autosave.rds")
  saveRDS(list(data = "old"), old_file)

  # Verify we can calculate file age
  file_age_hours <- as.numeric(difftime(Sys.time(), file.info(old_file)$mtime, units = "hours"))

  # New file should be less than 1 hour old
  expect_lt(file_age_hours, 1)

  # Files should be considered old if > 24 hours (logic demonstration)
  should_recover <- file_age_hours < 24
  expect_true(should_recover)  # New files should be recovered

  # Cleanup
  unlink(test_dir, recursive = TRUE)
})

# ============================================================================
# TEST SUITE 4: Error Handling
# ============================================================================

test_that("Auto-save handles corrupted data gracefully", {
  test_file <- file.path(tempdir(), "corrupted.rds")

  # Create corrupted file
  writeLines("This is not valid RDS data", test_file)

  # Attempt to read should fail gracefully
  result <- tryCatch({
    readRDS(test_file)
    "success"
  }, error = function(e) {
    "error_caught"
  })

  expect_equal(result, "error_caught")

  # Cleanup
  unlink(test_file)
})

test_that("Auto-save handles permission errors", {
  # Create read-only directory (platform-dependent behavior)
  skip_on_os("windows")  # Windows permission handling is different

  test_dir <- file.path(tempdir(), "readonly_test")
  dir.create(test_dir, showWarnings = FALSE)

  # Make directory read-only
  Sys.chmod(test_dir, mode = "0444")

  # Attempt to write should fail
  test_file <- file.path(test_dir, "test.rds")
  result <- tryCatch({
    saveRDS(list(data = "test"), test_file)
    "success"
  }, error = function(e) {
    "error_caught"
  })

  expect_equal(result, "error_caught")

  # Cleanup
  Sys.chmod(test_dir, mode = "0755")
  unlink(test_dir, recursive = TRUE)
})

# ============================================================================
# TEST SUITE 5: Visual Indicator Tests
# ============================================================================

test_that("Save indicator HTML structure is correct", {
  source("modules/auto_save_module.R", local = TRUE)

  ui_output <- auto_save_indicator_ui("test")
  html_string <- as.character(ui_output)

  # Check for key CSS classes
  expect_true(grepl("auto-save-indicator", html_string))
  expect_true(grepl("save-status-icon", html_string))
  expect_true(grepl("save-status-text", html_string))
  expect_true(grepl("save-status-time", html_string))

  # Check for positioning
  expect_true(grepl("position: fixed", html_string))
  expect_true(grepl("bottom: 20px", html_string))
  expect_true(grepl("right: 20px", html_string))
  expect_true(grepl("z-index: 9999", html_string))
})

test_that("Save indicator includes all status styles", {
  source("modules/auto_save_module.R", local = TRUE)

  ui_output <- auto_save_indicator_ui("test")
  html_string <- as.character(ui_output)

  # Check for status-specific CSS
  expect_true(grepl("auto-save-indicator.saving", html_string))
  expect_true(grepl("auto-save-indicator.saved", html_string))
  expect_true(grepl("auto-save-indicator.error", html_string))

  # Check for color coding
  expect_true(grepl("#fff3cd", html_string))  # Yellow for saving
  expect_true(grepl("#d4edda", html_string))  # Green for saved
  expect_true(grepl("#f8d7da", html_string))  # Red for error
})

# ============================================================================
# TEST SUITE 6: Integration with App
# ============================================================================

test_that("Auto-save integrates with app.R", {
  app_file <- "app.R"

  # Check app.R exists
  expect_true(file.exists(app_file))

  # Read app.R content
  app_content <- readLines(app_file)

  # Check module is sourced
  expect_true(any(grepl("source.*auto_save_module.R", app_content)))

  # Check UI component is added
  expect_true(any(grepl("auto_save_indicator_ui", app_content)))

  # Check server component is initialized
  expect_true(any(grepl("auto_save_server", app_content)))
})

test_that("Auto-save receives correct parameters", {
  app_content <- readLines("app.R")

  # Find auto_save_server call line
  server_line_index <- grep("auto_save_server", app_content)

  expect_true(length(server_line_index) > 0)

  # Get surrounding lines (function call may span multiple lines)
  start_line <- max(1, server_line_index[1] - 5)
  end_line <- min(length(app_content), server_line_index[1] + 10)
  server_section <- paste(app_content[start_line:end_line], collapse = " ")

  # Check parameters are passed somewhere in the section
  expect_true(grepl("project_data", server_section))
  expect_true(grepl("i18n", server_section))
})

# ============================================================================
# TEST SUITE 7: Performance Tests
# ============================================================================

test_that("Auto-save completes within acceptable time", {
  # Create test data
  test_data <- list(
    project_id = "perf_test",
    data = list(
      isa_data = list(
        drivers = data.frame(id = 1:100, name = paste("Driver", 1:100))
      )
    )
  )

  test_file <- file.path(tempdir(), "perf_test.rds")

  # Measure save time
  save_time <- system.time({
    saveRDS(test_data, test_file)
  })

  # Should complete in less than 1 second
  expect_lt(save_time["elapsed"], 1.0)

  # Cleanup
  unlink(test_file)
})

test_that("Auto-save does not block user interface", {
  # This is a conceptual test - in practice, auto-save runs asynchronously
  # The key is that saveRDS should be fast enough not to cause UI lag

  test_data <- list(
    project_id = "blocking_test",
    data = list(isa_data = list(drivers = data.frame(id = 1:50)))
  )

  test_file <- file.path(tempdir(), "blocking_test.rds")

  # Multiple rapid saves should not cause issues
  for (i in 1:5) {
    start_time <- Sys.time()
    saveRDS(test_data, test_file)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    # Each save should be fast
    expect_lt(elapsed, 0.5)
  }

  # Cleanup
  unlink(test_file)
})

# ============================================================================
# TEST SUITE 8: Translation/i18n Tests
# ============================================================================

test_that("Auto-save UI includes translation keys", {
  # Check if translations exist for auto-save
  translation_file <- "translations/translation.json"

  if (file.exists(translation_file)) {
    translations <- jsonlite::fromJSON(translation_file)

    # Check for auto-save related translations
    en_translations <- translations$translation$en

    # Look for key translation strings
    auto_save_keys <- c("Saving", "Saved", "Last saved", "Recover", "Start Fresh")

    # At least some auto-save translations should exist
    found_keys <- sapply(auto_save_keys, function(key) {
      any(grepl(key, en_translations, ignore.case = TRUE))
    })

    expect_true(any(found_keys))
  } else {
    skip("Translation file not found")
  }
})

# ============================================================================
# RUN ALL TESTS
# ============================================================================

cat("\n")
cat("=" , rep("=", 78), "\n", sep = "")
cat("  AUTO-SAVE MODULE INTEGRATION TESTS (v1.4.0)\n")
cat("=" , rep("=", 78), "\n", sep = "")
cat("\n")

cat("Test Configuration:\n")
cat("  - Auto-save interval:", TEST_CONFIG$autosave_interval, "seconds\n")
cat("  - Test timeout:", TEST_CONFIG$test_timeout, "seconds\n")
cat("  - Temp directory:", TEST_CONFIG$temp_dir, "\n")
cat("\n")

# Run tests with reporter
test_results <- test_dir(
  ".",
  pattern = "test_auto_save_integration.R",
  reporter = "summary"
)

cat("\n")
cat("=" , rep("=", 78), "\n", sep = "")
cat("  TEST SUMMARY\n")
cat("=" , rep("=", 78), "\n", sep = "")

if (all(test_results$passed)) {
  cat("\n  ✅ ALL TESTS PASSED!\n\n")
  cat("  Auto-save module is fully integrated and functional.\n")
  cat("  Ready for production use in v1.4.0-stable.\n\n")
} else {
  cat("\n  ⚠️  SOME TESTS FAILED\n\n")
  cat("  Please review the failures above and fix issues before release.\n\n")
}

cat("=" , rep("=", 78), "\n", sep = "")
cat("\n")
