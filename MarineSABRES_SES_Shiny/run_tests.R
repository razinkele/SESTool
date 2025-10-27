#!/usr/bin/env Rscript
# run_tests.R
# Script to run all tests for MarineSABRES SES Shiny Application

# Load required packages
if (!require("testthat", quietly = TRUE)) {
  message("testthat package required but not installed.")
  message("Please install it with: install.packages('testthat')")
  quit(status = 1)
}

# Optional: Load other testing packages (don't fail if not available)
if (!require("shinytest2", quietly = TRUE)) {
  message("Note: shinytest2 not installed (optional for enhanced Shiny testing)")
}

# Print header
cat("\n")
cat("==============================================================\n")
cat("  MarineSABRES SES Testing Framework\n")
cat("==============================================================\n")
cat("\n")

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Function to run specific test file
run_specific_test <- function(test_name) {
  test_file <- file.path("tests/testthat", paste0("test-", test_name, ".R"))

  if (file.exists(test_file)) {
    cat(sprintf("\nRunning tests from: %s\n", test_file))
    test_file(test_file)
  } else {
    cat(sprintf("Test file not found: %s\n", test_file))
  }
}

# Function to run all tests
run_all_tests <- function() {
  cat("Running all tests...\n\n")

  # Run tests
  results <- test_dir("tests/testthat", reporter = "progress")

  # Print summary
  cat("\n")
  cat("==============================================================\n")
  cat("  Test Summary\n")
  cat("==============================================================\n")
  print(results)

  return(results)
}

# Function to run tests with coverage
run_with_coverage <- function() {
  if (!require("covr", quietly = TRUE)) {
    message("ERROR: covr package not installed.")
    message("Please install it with: install.packages('covr')")
    quit(status = 1)
  }

  cat("Running tests with coverage analysis...\n\n")

  # Calculate coverage
  coverage <- package_coverage(
    path = ".",
    type = "tests",
    quiet = FALSE
  )

  # Print coverage report
  cat("\n")
  cat("==============================================================\n")
  cat("  Coverage Report\n")
  cat("==============================================================\n")
  print(coverage)

  # Generate HTML report
  report_file <- file.path(tempdir(), "coverage_report.html")
  report(coverage, file = report_file)

  cat(sprintf("\nDetailed coverage report saved to: %s\n", report_file))

  return(coverage)
}

# Main execution
if (length(args) == 0) {
  # No arguments - run all tests
  run_all_tests()

} else if (args[1] == "--coverage" || args[1] == "-c") {
  # Run with coverage
  run_with_coverage()

} else if (args[1] == "--help" || args[1] == "-h") {
  # Display help
  cat("Usage: Rscript run_tests.R [OPTIONS] [TEST_NAME]\n\n")
  cat("Options:\n")
  cat("  (no args)         Run all tests\n")
  cat("  -c, --coverage    Run tests with coverage analysis\n")
  cat("  -h, --help        Display this help message\n")
  cat("  TEST_NAME         Run specific test file (e.g., 'global-utils')\n\n")
  cat("Examples:\n")
  cat("  Rscript run_tests.R                    # Run all tests\n")
  cat("  Rscript run_tests.R --coverage         # Run with coverage\n")
  cat("  Rscript run_tests.R global-utils       # Run specific test\n\n")

} else {
  # Run specific test
  run_specific_test(args[1])
}

cat("\n")
cat("==============================================================\n")
cat("  Testing Complete\n")
cat("==============================================================\n")
cat("\n")
