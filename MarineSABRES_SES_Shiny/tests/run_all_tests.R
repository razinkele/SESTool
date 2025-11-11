#!/usr/bin/env Rscript
# Master Test Runner for MarineSABRES SES Shiny Application
# Runs all test suites and generates a summary report

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  MarineSABRES SES Application - Comprehensive Test Suite\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Track results
results <- list()

# Helper function to run a test suite
run_test_suite <- function(name, file) {
  cat(sprintf("\n▶ Running: %s\n", name))
  cat(strrep("─", 70), "\n")

  start_time <- Sys.time()

  result <- tryCatch({
    source(file, local = TRUE)
    list(status = "PASS", error = NULL)
  }, error = function(e) {
    list(status = "FAIL", error = conditionMessage(e))
  }, warning = function(w) {
    list(status = "WARN", warning = conditionMessage(w))
  })

  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  results[[name]] <<- list(
    status = result$status,
    time = elapsed,
    error = result$error
  )

  if (result$status == "PASS") {
    cat(sprintf("✅ %s completed in %.2fs\n", name, elapsed))
  } else if (result$status == "WARN") {
    cat(sprintf("⚠️  %s completed with warnings in %.2fs\n", name, elapsed))
  } else {
    cat(sprintf("❌ %s failed in %.2fs\n", name, elapsed))
    if (!is.null(result$error)) {
      cat(sprintf("   Error: %s\n", result$error))
    }
  }
}

# ==============================================================================
# RUN TEST SUITES
# ==============================================================================

# Test 1: Loop Detection
run_test_suite(
  "Loop Detection Tests",
  "test_loop_detection_comprehensive.R"
)

# Test 2: Network Analysis Functions
run_test_suite(
  "Network Analysis Functions",
  "test_network_analysis_functions.R"
)

# ==============================================================================
# SUMMARY REPORT
# ==============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  TEST SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

total_tests <- length(results)
passed <- sum(sapply(results, function(r) r$status == "PASS"))
warned <- sum(sapply(results, function(r) r$status == "WARN"))
failed <- sum(sapply(results, function(r) r$status == "FAIL"))
total_time <- sum(sapply(results, function(r) r$time))

cat(sprintf("Total Test Suites: %d\n", total_tests))
cat(sprintf("Passed:            %d ✅\n", passed))
if (warned > 0) {
  cat(sprintf("Warnings:          %d ⚠️\n", warned))
}
if (failed > 0) {
  cat(sprintf("Failed:            %d ❌\n", failed))
}
cat(sprintf("Total Time:        %.2f seconds\n\n", total_time))

# Detailed results
cat("Detailed Results:\n")
cat(strrep("─", 70), "\n")
for (name in names(results)) {
  r <- results[[name]]
  status_icon <- switch(r$status,
                        "PASS" = "✅",
                        "WARN" = "⚠️",
                        "FAIL" = "❌")
  cat(sprintf("%s %-40s (%.2fs)\n", status_icon, name, r$time))
}

cat("\n")

# Exit code
if (failed > 0) {
  cat("❌ Some tests failed. Please review the errors above.\n\n")
  quit(status = 1)
} else if (warned > 0) {
  cat("⚠️  All tests passed but some had warnings.\n\n")
  quit(status = 0)
} else {
  cat("✅ All tests passed successfully!\n\n")
  quit(status = 0)
}
