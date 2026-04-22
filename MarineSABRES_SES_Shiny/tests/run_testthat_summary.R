# Runs the testthat suite and writes a structured per-file summary.
#
# Usage:   Rscript tests/run_testthat_summary.R
# Output:  tests/testthat_results.txt  (gitignored)
#
# Writes a per-file pass/fail/skip table plus a flat list of failed tests,
# useful for CI logs or local overview runs when `test_dir()`'s default
# progress reporter is too verbose.
.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
library(testthat)

r <- test_dir("tests/testthat", reporter = SilentReporter$new(), stop_on_failure = FALSE)
d <- as.data.frame(r)

out <- file("tests/testthat_results.txt", "w")
writeLines(sprintf("Total tests: %d", nrow(d)), out)
writeLines(sprintf("Passed: %d", sum(d$failed == 0 & !d$skipped)), out)
writeLines(sprintf("Failed: %d", sum(d$failed > 0)), out)
writeLines(sprintf("Skipped: %d", sum(d$skipped)), out)
writeLines(sprintf("Warnings: %d", sum(d$warning > 0)), out)
writeLines("", out)

if (any(d$failed > 0)) {
  writeLines("FAILED TESTS:", out)
  f <- d[d$failed > 0, ]
  for (i in seq_len(nrow(f))) {
    writeLines(sprintf("  %s :: %s", f$file[i], f$test[i]), out)
  }
  writeLines("", out)
}

# Group by file for a quick per-file view
files <- unique(d$file)
writeLines("PER-FILE SUMMARY:", out)
for (fn in files) {
  fd <- d[d$file == fn, ]
  p <- sum(fd$failed == 0 & !fd$skipped)
  fl <- sum(fd$failed > 0)
  s <- sum(fd$skipped)
  status <- if (fl > 0) "FAIL" else if (s == nrow(fd)) "SKIP" else "OK"
  writeLines(sprintf("  [%4s] %-55s pass=%d fail=%d skip=%d", status, fn, p, fl, s), out)
}
close(out)
writeLines("Done. Results in tests/testthat_results.txt")
