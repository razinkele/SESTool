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

# Test 3: testthat Test Suite (includes connection review tests)
cat("\n▶ Running: testthat Test Suite\n")
cat(strrep("─", 70), "\n")
start_time <- Sys.time()
tryCatch({
  library(testthat)
  test_results <- test_dir("testthat", reporter = "summary")
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")

  # Extract test counts from results
  if (!is.null(test_results)) {
    passed_count <- sum(sapply(test_results, function(r) sum(r$passed)))
    failed_count <- sum(sapply(test_results, function(r) sum(r$failed)))
    warning_count <- sum(sapply(test_results, function(r) sum(r$warning)))

    if (failed_count > 0) {
      results[["testthat Suite"]] <<- list(status = "FAIL", time = elapsed, error = paste(failed_count, "tests failed"))
      cat(sprintf("❌ testthat Suite failed in %.2fs (%d failed)\n", elapsed, failed_count))
    } else if (warning_count > 0) {
      results[["testthat Suite"]] <<- list(status = "WARN", time = elapsed, error = NULL)
      cat(sprintf("⚠️  testthat Suite completed with warnings in %.2fs\n", elapsed))
    } else {
      results[["testthat Suite"]] <<- list(status = "PASS", time = elapsed, error = NULL)
      cat(sprintf("✅ testthat Suite completed in %.2fs (%d tests passed)\n", elapsed, passed_count))
    }
  } else {
    results[["testthat Suite"]] <<- list(status = "PASS", time = elapsed, error = NULL)
    cat(sprintf("✅ testthat Suite completed in %.2fs\n", elapsed))
  }
}, error = function(e) {
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
  results[["testthat Suite"]] <<- list(status = "FAIL", time = elapsed, error = conditionMessage(e))
  cat(sprintf("❌ testthat Suite failed in %.2fs\n", elapsed))
  cat(sprintf("   Error: %s\n", conditionMessage(e)))
})

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
