#!/usr/bin/env Rscript
# generate_coverage.R
# Generate test coverage report for MarineSABRES SES Shiny Application
#
# Usage:
#   Rscript tests/generate_coverage.R
#
# Or from R console:
#   source("tests/generate_coverage.R")

cat("=================================================================\n")
cat("MarineSABRES SES - Test Coverage Report Generator\n")
cat("=================================================================\n\n")

# Check for required packages
if (!require("covr", quietly = TRUE)) {
  cat("ERROR: covr package not found\n")
  cat("Install with: install.packages('covr')\n")
  quit(status = 1)
}

# Generate coverage
cat("Step 1/5: Generating test coverage...\n")
coverage <- covr::package_coverage(type = "tests", quiet = FALSE)

cat("\n")
cat("Step 2/5: Calculating coverage metrics...\n")
pct <- covr::percent_coverage(coverage)
cat(sprintf("Overall Coverage: %.2f%%\n", pct))

# Print detailed summary
cat("\n")
cat("Step 3/5: Coverage Summary\n")
cat("=================================================================\n")
print(coverage)

# Generate HTML report
cat("\n")
cat("Step 4/5: Generating HTML report...\n")
report_file <- "coverage-report.html"
covr::report(coverage, file = report_file, browse = FALSE)
cat(sprintf("HTML report saved to: %s\n", normalizePath(report_file)))

# Generate detailed CSV
cat("\n")
cat("Step 5/5: Generating detailed CSV...\n")
cov_df <- as.data.frame(coverage)
csv_file <- "coverage-details.csv"
write.csv(cov_df, csv_file, row.names = FALSE)
cat(sprintf("Detailed data saved to: %s\n", normalizePath(csv_file)))

# Coverage by file
cat("\n")
cat("=================================================================\n")
cat("Coverage by File\n")
cat("=================================================================\n")

if (nrow(cov_df) > 0) {
  # Aggregate by filename
  file_cov <- aggregate(value ~ filename, data = cov_df, FUN = function(x) mean(x > 0) * 100)
  file_cov <- file_cov[order(-file_cov$value), ]

  # Add basename for display
  file_cov$basename <- basename(file_cov$filename)

  # Print table
  cat(sprintf("%-50s %8s\n", "File", "Coverage"))
  cat(strrep("-", 60), "\n")

  for (i in 1:nrow(file_cov)) {
    fname <- file_cov$basename[i]
    fcov <- file_cov$value[i]

    # Color code
    status <- if (fcov >= 80) "✓" else if (fcov >= 70) "~" else "✗"

    cat(sprintf("%-50s %7.2f%% %s\n", fname, fcov, status))
  }

  cat(strrep("-", 60), "\n")
  cat("Legend: ✓ Good (≥80%)  ~ Acceptable (≥70%)  ✗ Needs Improvement (<70%)\n")
}

# Threshold check
cat("\n")
cat("=================================================================\n")
cat("Coverage Threshold Check\n")
cat("=================================================================\n")
threshold <- 70
cat(sprintf("Required Coverage: %d%%\n", threshold))
cat(sprintf("Actual Coverage:   %.2f%%\n", pct))
cat(sprintf("Status:            %s\n", if (pct >= threshold) "✅ PASS" else "❌ FAIL"))

if (pct >= 80) {
  cat("\n🎉 Excellent coverage!\n")
} else if (pct >= threshold) {
  cat("\n✓ Coverage meets minimum threshold.\n")
  cat(sprintf("  Consider improving to 80%% (current gap: %.2f%%)\n", 80 - pct))
} else {
  cat("\n⚠️  WARNING: Coverage below minimum threshold!\n")
  cat(sprintf("  Need to increase by %.2f%% to meet requirement.\n", threshold - pct))
}

# Files needing attention
cat("\n")
cat("=================================================================\n")
cat("Files Needing Attention (Coverage < 70%)\n")
cat("=================================================================\n")

if (nrow(cov_df) > 0) {
  low_cov <- file_cov[file_cov$value < 70, ]

  if (nrow(low_cov) > 0) {
    cat(sprintf("Found %d file(s) with low coverage:\n\n", nrow(low_cov)))

    for (i in 1:nrow(low_cov)) {
      fname <- low_cov$basename[i]
      fcov <- low_cov$value[i]
      gap <- 70 - fcov

      cat(sprintf("  • %s: %.2f%% (needs +%.2f%%)\n", fname, fcov, gap))
    }
  } else {
    cat("✓ All files meet minimum coverage threshold!\n")
  }
} else {
  cat("No coverage data available.\n")
}

# Next steps
cat("\n")
cat("=================================================================\n")
cat("Next Steps\n")
cat("=================================================================\n")
cat("1. Open coverage-report.html in your browser for detailed view\n")
cat("2. Review files with low coverage\n")
cat("3. Add tests for uncovered code paths\n")
cat("4. Re-run this script to verify improvements\n")

# Open HTML report automatically (if interactive)
if (interactive()) {
  cat("\nOpening HTML report in browser...\n")
  utils::browseURL(report_file)
}

cat("\n")
cat("=================================================================\n")
cat("Coverage report generation complete!\n")
cat("=================================================================\n")

# Return coverage object invisibly for further analysis
invisible(coverage)
