#!/usr/bin/env Rscript
# Master Test Runner for MarineSABRES SES Shiny Application
#
# Run from the app root:   Rscript tests/run_all_tests.R
# Optional filter:         Rscript tests/run_all_tests.R <regex on file name>
#
# Runs the same way CI does (review 2026-10-07 N77): every
# tests/testthat/test-*.R in its OWN R process via tests/ci_run_file.R, so
# local and CI results agree. The earlier runner sourced the two standalone
# scripts by bare file name (always FAIL from the app root), aborted a suite on
# its first warning and used the single-session test_dir() mode CI abandoned
# because files leak global state into each other.

args <- commandArgs(trailingOnly = TRUE)
pattern <- if (length(args) >= 1) args[[1]] else NULL

if (!file.exists(file.path("tests", "ci_run_file.R"))) {
  stop("Run this from the app root (the directory containing app.R): Rscript tests/run_all_tests.R")
}

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")

cat("===================================================================\n")
cat("  MarineSABRES SES Application - Test Suite (per-file isolation)\n")
cat("===================================================================\n\n")

results <- list()

# --- Standalone scripts (not testthat files) ---------------------------------
# Warnings are recorded and the script keeps running (withCallingHandlers);
# only an error marks it FAIL.
run_script <- function(name, file) {
  cat(sprintf("\n> %s (%s)\n", name, file))
  warnings_seen <- character(0)
  start <- Sys.time()
  status <- tryCatch({
    withCallingHandlers(
      source(file, local = new.env()),
      warning = function(w) {
        warnings_seen <<- c(warnings_seen, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    if (length(warnings_seen)) "WARN" else "PASS"
  }, error = function(e) {
    cat(sprintf("   Error: %s\n", conditionMessage(e)))
    "FAIL"
  })
  results[[name]] <<- list(status = status, time = as.numeric(Sys.time() - start, units = "secs"))
  if (length(warnings_seen)) cat(sprintf("   %d warning(s), first: %s\n", length(warnings_seen), warnings_seen[1]))
}

if (is.null(pattern)) {
  run_script("Loop Detection Tests", file.path("tests", "test_loop_detection_comprehensive.R"))
  run_script("Network Analysis Functions", file.path("tests", "test_network_analysis_functions.R"))
}

# --- testthat files, one R process each (as CI) -------------------------------
files <- sort(list.files(file.path("tests", "testthat"), pattern = "^test-.*[.]R$", full.names = TRUE))
if (!is.null(pattern)) files <- files[grepl(pattern, basename(files))]
cat(sprintf("\n> testthat: %d file(s), each in its own R process\n", length(files)))

start <- Sys.time()
failed_files <- character(0)
for (f in files) {
  code <- system2(rscript, c(file.path("tests", "ci_run_file.R"), shQuote(f)))
  if (!identical(as.integer(code), 0L)) failed_files <- c(failed_files, basename(f))
}
results[["testthat files"]] <- list(
  status = if (length(failed_files)) "FAIL" else "PASS",
  time = as.numeric(Sys.time() - start, units = "secs")
)

# --- Summary --------------------------------------------------------------------
cat("\n===================================================================\n")
cat("  TEST SUMMARY\n")
cat("===================================================================\n")
for (name in names(results)) {
  r <- results[[name]]
  cat(sprintf("%-6s %-40s (%.1fs)\n", r$status, name, r$time))
}
if (length(failed_files)) {
  cat(sprintf("\nFailed test files (%d): %s\n", length(failed_files), paste(failed_files, collapse = ", ")))
}

failed <- any(vapply(results, function(r) r$status == "FAIL", logical(1)))
quit(status = if (failed) 1L else 0L)
