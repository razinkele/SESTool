# run_ui_tests.R
# Script to run shinytest2 UI tests for the MarineSABRES SES Toolbox
#
# Usage:
#   source("run_ui_tests.R")
#   # Or from command line:
#   Rscript run_ui_tests.R

cat("\n")
cat("========================================\n")
cat(" MarineSABRES SES Toolbox UI Tests\n")
cat(" Using shinytest2\n")
cat("========================================\n\n")

# Check if shinytest2 is installed
if (!requireNamespace("shinytest2", quietly = TRUE)) {
  cat("ERROR: shinytest2 package is not installed.\n")
  cat("Install it with: install.packages('shinytest2')\n")
  quit(status = 1)
}

# Check if chromote is installed (required for shinytest2)
if (!requireNamespace("chromote", quietly = TRUE)) {
  cat("ERROR: chromote package is not installed.\n")
  cat("Install it with: install.packages('chromote')\n")
  quit(status = 1)
}

# Load packages
library(testthat)
library(shinytest2)

# Enable tests to run locally (not on CRAN)
Sys.setenv(NOT_CRAN = "true")

# Set working directory to app root
# Handle both RStudio and command line execution
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
} else {
  # When running from command line, assume we're already in the app root
  # or use the script's directory
  script_dir <- tryCatch({
    dirname(sys.frame(1)$ofile)
  }, error = function(e) {
    getwd()
  })
  if (!is.null(script_dir) && dir.exists(script_dir)) {
    setwd(script_dir)
  }
}

cat("Running UI tests...\n\n")

# Run all shinytest2 tests
test_results <- test_dir(
  "tests/shinytest2",
  reporter = "progress",
  stop_on_failure = FALSE
)

cat("\n")
cat("========================================\n")
cat(" Test Summary\n")
cat("========================================\n")

# Print summary
print(test_results)

# Check if all tests passed
if (any(test_results$failed > 0)) {
  cat("\n❌ Some tests FAILED. Please review the output above.\n")
  quit(status = 1)
} else {
  cat("\n✅ All tests PASSED!\n")
  quit(status = 0)
}
