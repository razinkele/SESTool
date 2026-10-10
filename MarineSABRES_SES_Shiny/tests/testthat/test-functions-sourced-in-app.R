# tests/testthat/test-functions-sourced-in-app.R
#
# Guard: every functions/*.R must be reachable from the app's startup source
# chain (global.R's source() calls + app.R's `critical_sources` list). A file
# that defines helpers but is never source()d is a runtime undefined-symbol
# risk — exactly the feedback-#1 bug, where functions/matrix_from_linked.R
# existed (v1.13.0) but was never sourced, so the N:M reconciler silently never
# ran.
#
# Pure text scan — sources nothing, so it is cheap and cannot segfault the way
# testServer/heavy-source tests can.
#
# A reference only counts when it is a real load (review 2026-10-07 N72):
#   source("functions/<name>.R")                        # literal path
#   source(get_project_file("functions", "<name>.R"))   # constructed path
#   critical_sources <- c("functions/<name>.R", ...)    # app.R vector + loop
# Comments, file.exists("functions/x.R") guards and other bare mentions do
# not count. And a file whose only source() lines sit inside global.R's
# torch-gated `if (ML_ENABLED) { ... }` block is undefined wherever torch is
# absent (laguna, CI), so it must be an ML file (ml_*.R) — a general helper
# that lands there fails this test.

# Resolve project root the same way helper-00-load-functions.R does.
.scc_root <- local({
  td <- getwd()
  if (basename(td) == "testthat") dirname(dirname(td)) else td
})

# Line indices of a critical_sources <- c( ... ) vector (app.R)
.scc_vector_lines <- function(code) {
  start <- grep("critical_sources\\s*<-\\s*c\\(", code)
  out <- integer(0)
  for (s in start) {
    e <- s
    while (e <= length(code) && !grepl(")", code[e], fixed = TRUE)) e <- e + 1
    out <- c(out, s:min(e, length(code)))
  }
  out
}

# Indices of the lines in `code_lines` that actually load `filename`.
.scc_source_lines <- function(filename, code_lines) {
  code <- sub("#.*$", "", code_lines)
  mentions <- grepl(paste0("functions/", filename), code, fixed = TRUE) |   # literal / vector
              grepl(paste0('"', filename, '"'),     code, fixed = TRUE)     # get_project_file()
  loads <- grepl("source(", code, fixed = TRUE)
  loads[.scc_vector_lines(code)] <- TRUE
  which(mentions & loads)
}

.scc_is_sourced <- function(filename, code_lines) length(.scc_source_lines(filename, code_lines)) > 0

# First and last line of the `if (ML_ENABLED) { ... }` block (brace-tracked)
.scc_ml_block <- function(code_lines) {
  code <- sub("#.*$", "", code_lines)
  s <- grep("^if \\(ML_ENABLED\\) \\{", code)[1]
  if (is.na(s)) return(c(NA_integer_, NA_integer_))
  depth <- 0
  for (i in s:length(code)) {
    ch <- strsplit(gsub('"[^"]*"', "", code[i]), "")[[1]]
    depth <- depth + sum(ch == "{") - sum(ch == "}")
    if (depth == 0) return(c(s, i))
  }
  c(s, length(code))
}

test_that("every functions/*.R is reachable from the global.R/app.R source chain", {
  fn_dir <- file.path(.scc_root, "functions")
  skip_if_not(dir.exists(fn_dir), "functions/ directory not found")

  fn_files <- list.files(fn_dir, pattern = "[.]R$", recursive = TRUE)
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

test_that("only ML files are loaded exclusively inside the torch-gated block (N72)", {
  g_path <- file.path(.scc_root, "global.R")
  skip_if_not(file.exists(g_path))
  g <- readLines(g_path, warn = FALSE)
  blk <- .scc_ml_block(g)
  expect_false(anyNA(blk))
  app_lines <- if (file.exists(file.path(.scc_root, "app.R"))) readLines(file.path(.scc_root, "app.R"), warn = FALSE) else character(0)

  fn_files <- basename(list.files(file.path(.scc_root, "functions"), pattern = "[.]R$", recursive = TRUE))
  gated_only <- Filter(function(f) {
    hits <- .scc_source_lines(f, g)
    length(hits) > 0 && all(hits >= blk[1] & hits <= blk[2]) && !.scc_is_sourced(f, app_lines)
  }, fn_files)
  expect_gt(length(gated_only), 0)   # the ML files themselves
  not_ml <- gated_only[!grepl("^ml_", gated_only)]
  expect_identical(not_ml, character(0),
                   info = paste("Sourced only inside the torch-gated ML block, so undefined",
                                "without torch:", paste(not_ml, collapse = ", ")))
})

test_that("the source-chain matcher is non-vacuous (forms + comment-stripping)", {
  lines <- c(
    'source("functions/alpha.R")',                          # literal form
    'source(get_project_file("functions", "beta.R"))',      # constructed form
    'critical_sources <- c(',
    '  "functions/epsilon.R",',                             # critical_sources vector entry
    ')',
    '# See functions/gamma.R for implementation details',   # comment-only -> NOT sourced
    'if (file.exists("functions/zeta.R")) x <- 1',          # bare mention -> NOT sourced
    'x <- 1'
  )
  expect_true(.scc_is_sourced("alpha.R",   lines))
  expect_true(.scc_is_sourced("beta.R",    lines))
  expect_true(.scc_is_sourced("epsilon.R", lines))
  expect_false(.scc_is_sourced("gamma.R",  lines))   # only mentioned in a comment
  expect_false(.scc_is_sourced("zeta.R",   lines))   # file.exists() is not a load
  expect_false(.scc_is_sourced("delta.R",  lines))   # absent entirely
})

test_that("the ML-block detector finds a gated-only file (N72 self-test)", {
  g <- c('x <- 1',
         'if (ML_ENABLED) {',
         '  tryCatch({',
         '    source("functions/helper_new.R")',
         '  }, error = function(e) cat("{ not a brace }"))',
         '} else {',
         '  y <- 2',
         '}',
         'source("functions/always.R")')
  blk <- .scc_ml_block(g)
  expect_equal(blk, c(2L, 8L))
  hits <- .scc_source_lines("helper_new.R", g)
  expect_true(all(hits >= blk[1] & hits <= blk[2]))
  expect_false(all(.scc_source_lines("always.R", g) <= blk[2]))
})
