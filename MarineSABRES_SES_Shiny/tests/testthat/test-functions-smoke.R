# test-functions-smoke.R
# Smoke test: every functions/*.R file parses without syntax errors and
# defines at least one top-level function. Catches outright breakage
# (orphan syntax from refactors, broken imports) without requiring each
# file to get its own bespoke test.
#
# Companion to the 21 module signature-contract tests under
# test-<module>-module.R - those assert module UI/server contracts;
# this asserts that utility files in functions/ at least parse and
# define exports.

library(testthat)

test_that("all functions/*.R files parse without syntax errors", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fn_dir <- file.path(root, "functions")
  skip_if_not(dir.exists(fn_dir), "functions/ directory not found")

  fn_files <- list.files(fn_dir, pattern = "\\.R$", full.names = TRUE)
  expect_true(length(fn_files) > 0, info = "functions/ directory should have .R files")

  for (fp in fn_files) {
    # parse() throws on syntax errors; NULL-safe wrapper captures them
    parse_ok <- tryCatch({
      parse(fp)
      TRUE
    }, error = function(e) {
      message("Parse error in ", basename(fp), ": ", e$message)
      FALSE
    })
    expect_true(parse_ok,
                info = paste0("functions/", basename(fp), " failed to parse"))
  }
})

test_that("every functions/*.R file defines at least one top-level function", {
  # Static check (does NOT source the file - avoids global.R load-order
  # issues). Scans the source text for lines matching "<name> <- function".
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fn_dir <- file.path(root, "functions")
  skip_if_not(dir.exists(fn_dir), "functions/ directory not found")

  fn_files <- list.files(fn_dir, pattern = "\\.R$", full.names = TRUE)

  for (fp in fn_files) {
    src <- paste(readLines(fp, warn = FALSE), collapse = "\n")
    # Match top-level function assignments: "<name> <- function" at start
    # of line, allowing indentation to ignore nested defs.
    has_function <- grepl("(?m)^[a-zA-Z_.][a-zA-Z0-9_.]*\\s*<-\\s*function",
                          src, perl = TRUE)
    expect_true(has_function,
                info = paste0("functions/", basename(fp),
                              " defines no top-level functions (pure constants? ",
                              "if so, consider moving to constants.R)"))
  }
})
