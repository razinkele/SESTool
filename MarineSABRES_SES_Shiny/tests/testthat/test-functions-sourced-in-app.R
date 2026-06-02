# tests/testthat/test-functions-sourced-in-app.R
#
# Guard: every functions/*.R must be reachable from the app's startup source
# chain (global.R's source() calls + app.R's `critical_sources` list). A file
# that defines helpers but is never source()d is a runtime undefined-symbol
# risk — exactly the feedback-#1 bug, where functions/matrix_from_linked.R
# existed (v1.13.0) but was never sourced, so the N:M reconciler silently never
# ran. (A new functions/*.R was added in this line of work and wired into
# global.R by hand, which is precisely the kind of step this test backstops.)
#
# Pure text scan — sources nothing, so it is cheap and cannot segfault the way
# testServer/heavy-source tests can.
#
# Recognizes the three reference forms used here, with inline comments stripped
# so a prose mention ("# see functions/x.R") does NOT count as a real source:
#   source("functions/<name>.R")                        # literal path
#   source(get_project_file("functions", "<name>.R"))   # constructed path
#   critical_sources <- c("functions/<name>.R", ...)    # app.R vector + loop

# Resolve project root the same way helper-00-load-functions.R does.
.scc_root <- local({
  td <- getwd()
  if (basename(td) == "testthat") dirname(dirname(td)) else td
})

# Is `filename` (e.g. "async_helpers.R") referenced for sourcing in `code_lines`?
# Inline comments are stripped first.
.scc_is_sourced <- function(filename, code_lines) {
  code <- sub("#.*$", "", code_lines)
  any(
    grepl(paste0("functions/", filename), code, fixed = TRUE) |  # literal / critical_sources
    grepl(paste0('"', filename, '"'),     code, fixed = TRUE)    # get_project_file("functions", "x.R")
  )
}

test_that("every functions/*.R is reachable from the global.R/app.R source chain", {
  fn_dir <- file.path(.scc_root, "functions")
  skip_if_not(dir.exists(fn_dir), "functions/ directory not found")

  fn_files <- list.files(fn_dir, pattern = "\\.R$", recursive = TRUE)
  expect_gt(length(fn_files), 0)

  src_paths <- file.path(.scc_root, c("global.R", "app.R"))
  src_paths <- src_paths[file.exists(src_paths)]
  expect_gt(length(src_paths), 0)
  code_lines <- unlist(lapply(src_paths, readLines, warn = FALSE), use.names = FALSE)

  unsourced <- Filter(function(f) !.scc_is_sourced(basename(f), code_lines), fn_files)

  if (length(unsourced) > 0) {
    fail(paste0(
      "These functions/*.R files are not source()d in global.R or app.R, so they ",
      "will not load at runtime (undefined-symbol risk) — add a source() line: ",
      paste(unsourced, collapse = ", ")
    ))
  } else {
    succeed()
  }
})

test_that("the source-chain matcher is non-vacuous (forms + comment-stripping)", {
  lines <- c(
    'source("functions/alpha.R")',                          # literal form
    'source(get_project_file("functions", "beta.R"))',      # constructed form
    '  "functions/epsilon.R",',                             # critical_sources vector entry
    '# See functions/gamma.R for implementation details',   # comment-only -> NOT sourced
    'x <- 1'
  )
  expect_true(.scc_is_sourced("alpha.R",   lines))
  expect_true(.scc_is_sourced("beta.R",    lines))
  expect_true(.scc_is_sourced("epsilon.R", lines))
  expect_false(.scc_is_sourced("gamma.R",  lines))   # only mentioned in a comment
  expect_false(.scc_is_sourced("delta.R",  lines))   # absent entirely
})
