#!/usr/bin/env Rscript
# tests/ci_run_file.R — run ONE testthat file in this fresh R process and exit
# non-zero on any failure/error. Per-file process isolation is what makes the
# suite CI-stable: many test files pass individually but leak global state when
# run together in a single session (test_dir / a shared-session loop), causing
# order-dependent failures. A fresh process per file removes that entire class.
suppressMessages(library(testthat))
f <- commandArgs(trailingOnly = TRUE)[[1]]
# Source helper-*.R into the global env (helper-00 loads global.R; helper-source-grep
# defines expect_context_key_in_file, etc.), then run the file WITHOUT re-loading
# helpers. test_file's own load_helpers doesn't make all helper fns visible here.
for (h in sort(list.files(dirname(f), pattern = "^helper.*[.]R$", full.names = TRUE))) {
  try(sys.source(h, envir = globalenv()), silent = TRUE)
}
res <- tryCatch(
  as.data.frame(test_file(f, reporter = "summary", load_helpers = FALSE,
                          stop_on_failure = FALSE)),
  error = function(e) { message("LOAD/RUN ERROR: ", conditionMessage(e)); NULL }
)
if (is.null(res)) quit(status = 1L)
nfail <- sum(res[["failed"]]) + (if ("error" %in% names(res)) sum(res[["error"]]) else 0L)
cat(sprintf("%-52s PASS=%d FAIL=%d SKIP=%d\n",
            basename(f), sum(res[["passed"]]), nfail,
            if ("skipped" %in% names(res)) sum(res[["skipped"]]) else 0L))
quit(status = if (nfail > 0) 1L else 0L)
