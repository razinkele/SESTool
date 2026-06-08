# tests/testthat/helper-source-grep.R
# Shared helper for source-level regression tests.
#
# Many Phase A/B/C regression tests assert that a specific i18n
# context_key (or other anchor string) appears in a specific source file —
# proving that the CLAUDE.md `format_user_error(context_key=...)` pattern
# is in place for a given error handler. This helper centralizes the
# path-resolution + grep dance.
#
# Limitations: source-level tests catch the pattern but NOT runtime
# behavior. A string in a comment or a dead branch passes. Pair with a
# `testServer()` behavior test when possible. See plan v2 risk section.

#' Assert a key appears in a project source file
#'
#' @param rel_path Project-relative path (e.g., "modules/foo.R")
#' @param key String to grep for (literal, not regex)
#' @param info Failure message to surface
#' @return TRUE invisibly on success; expect_match() fail on absence
expect_context_key_in_file <- function(rel_path, key, info = NULL) {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  full <- file.path(root, rel_path)
  testthat::expect_true(file.exists(full),
    info = sprintf("Source file '%s' must exist at %s", rel_path, full))
  src <- paste(readLines(full, warn = FALSE), collapse = "\n")
  testthat::expect_true(
    grepl(key, src, fixed = TRUE),
    info = info %||% sprintf("Expected key '%s' to appear in %s", key, rel_path)
  )
}
