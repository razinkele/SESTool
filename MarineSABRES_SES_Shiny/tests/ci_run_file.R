#!/usr/bin/env Rscript
# tests/ci_run_file.R — run ONE testthat file in this fresh R process and exit
# non-zero on any failure/error. Per-file process isolation is what makes the
# suite CI-stable: many test files pass individually but leak global state when
# run together in a single session (test_dir / a shared-session loop), causing
# order-dependent failures. A fresh process per file removes that entire class.
suppressMessages(library(testthat))
f <- commandArgs(trailingOnly = TRUE)[[1]]
# test_file's native load_helpers sources tests/testthat/helper-*.R (helper-00 ->
# global.R, helper-source-grep -> expect_context_key_in_file, etc.). Those helpers
# must be version-controlled to be present here in CI.
res <- tryCatch(
  as.data.frame(test_file(f, reporter = "summary", stop_on_failure = FALSE)),
  error = function(e) { message("LOAD/RUN ERROR: ", conditionMessage(e)); NULL }
)
if (is.null(res)) quit(status = 1L)
nfail <- sum(res[["failed"]]) + (if ("error" %in% names(res)) sum(res[["error"]]) else 0L)
npass <- sum(res[["passed"]])
nskip <- if ("skipped" %in% names(res)) sum(res[["skipped"]]) else 0L
cat(sprintf("%-52s PASS=%d FAIL=%d SKIP=%d\n", basename(f), npass, nfail, nskip))

# A file that produced ZERO passing expectations proves nothing: typically a
# skip_if_not(exists(...)) guard fired because a source() failed or a function
# is only loaded behind an optional dependency. Treat it as a failure unless the
# file is listed (with a reason) in the allowlist (review 2026-10-07 N44).
if (nfail == 0 && npass == 0) {
  allow_path <- Sys.getenv("CI_ALLOW_ZERO_PASS_FILE", "tests/ci_allow_zero_pass.txt")
  allowed <- if (file.exists(allow_path)) {
    l <- trimws(sub("#.*$", "", readLines(allow_path, warn = FALSE)))
    l[nzchar(l)]
  } else character(0)
  if (basename(f) %in% allowed) {
    cat(sprintf("  (zero passing expectations allowed by %s)\n", allow_path))
  } else {
    cat(sprintf("  ZERO PASSING EXPECTATIONS in %s -- every test skipped or none ran.\n", basename(f)))
    cat("  Fix the skip cause, or add the file to tests/ci_allow_zero_pass.txt with a reason.\n")
    quit(status = 1L)
  }
}
quit(status = if (nfail > 0) 1L else 0L)
