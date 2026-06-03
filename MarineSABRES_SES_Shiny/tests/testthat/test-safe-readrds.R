# test-safe-readrds.R
# Security hardening tests for safe_readRDS (L12 — reject S4/R5 reference-class objects)
#
# safe_readRDS is loaded via global.R -> functions/utils.R (helper-00-load-functions.R).

library(testthat)
library(methods)

# ---------------------------------------------------------------------------
# R5 (reference-class) rejection
# ---------------------------------------------------------------------------
test_that("safe_readRDS rejects a reference-class (R5) object", {
  skip_if_not(exists("safe_readRDS", mode = "function"))
  Ref <- methods::setRefClass("B1RefTmp", fields = list(x = "numeric"))
  f <- tempfile(fileext = ".rds")
  on.exit(unlink(f), add = TRUE)
  saveRDS(Ref$new(x = 1), f)
  # Pin the branch: R5 must be rejected via the reference-class path (not the
  # generic S4 path), so the SECURITY message names it a reference-class object.
  expect_warning(res <- safe_readRDS(f), regexp = "reference-class", fixed = FALSE)
  expect_null(res)
})

# ---------------------------------------------------------------------------
# Normal list — must still load
# ---------------------------------------------------------------------------
test_that("safe_readRDS still loads a normal list", {
  skip_if_not(exists("safe_readRDS", mode = "function"))
  f <- tempfile(fileext = ".rds")
  on.exit(unlink(f), add = TRUE)
  saveRDS(list(a = 1, b = "x"), f)
  out <- safe_readRDS(f)
  expect_equal(out$a, 1)
})

# ---------------------------------------------------------------------------
# S4 object rejection
# ---------------------------------------------------------------------------
test_that("safe_readRDS rejects an S4 object", {
  skip_if_not(exists("safe_readRDS", mode = "function"))
  # Define a minimal S4 class (may already exist from a previous run; suppress warning)
  suppressWarnings(
    methods::setClass("B1S4Tmp", representation(x = "numeric"))
  )
  f <- tempfile(fileext = ".rds")
  on.exit(unlink(f), add = TRUE)
  saveRDS(methods::new("B1S4Tmp", x = 42), f)
  expect_null(safe_readRDS(f))
})
