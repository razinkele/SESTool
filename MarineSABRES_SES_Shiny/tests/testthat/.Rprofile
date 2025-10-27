# .Rprofile for test environment
# This file is loaded before running tests

# Suppress startup messages
options(
  repos = c(CRAN = "https://cloud.r-project.org/"),
  warn = 1,
  testthat.output_file = NULL
)

# Set test-specific options
Sys.setenv(TESTTHAT = "true")
Sys.setenv(MARINESABRES_TEST_MODE = "true")

# Print test environment info
cat("\n")
cat("==============================================\n")
cat("  MarineSABRES Test Environment Initialized\n")
cat("==============================================\n")
cat("R version:", R.version.string, "\n")
cat("Working directory:", getwd(), "\n")
cat("\n")
