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
cat(sprintf("%-52s PASS=%d FAIL=%d SKIP=%d\n",
            basename(f), sum(res[["passed"]]), nfail,
            if ("skipped" %in% names(res)) sum(res[["skipped"]]) else 0L))
quit(status = if (nfail > 0) 1L else 0L)
