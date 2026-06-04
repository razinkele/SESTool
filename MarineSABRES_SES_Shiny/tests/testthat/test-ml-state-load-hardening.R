# ==============================================================================
# Tests for ML state loader security hardening (Task B6)
#
# Approach: BEHAVIORAL tests, not static-assertion tests.
# Rationale: both ml_collaborative_filter.R and ml_response_bandit.R use only
# base R + optional MASS (no torch required), so load_cf_state() and
# load_response_bandit() can be exercised directly.  We test three scenarios
# per loader:
#   1. A hostile R5/reference-class object written to disk → safe_readRDS
#      rejects it → loader falls back to fresh/empty state (no crash, no
#      hostile object returned).
#   2. A normal saved state (plain list) → loads successfully.
#   3. A missing file → cold-start fallback (no error).
#
# If the module cannot be sourced (unexpected environment), the test falls
# back to the static-assertion form so CI never goes red from infrastructure.
# ==============================================================================

library(testthat)

# ---------------------------------------------------------------------------
# Setup: stub debug_log so sourcing the ML modules doesn't error on it,
# then source safe_readRDS (functions/utils.R) and both ML modules.
# ---------------------------------------------------------------------------

# A minimal debug_log stub (the real one is defined in global.R; we only need
# the signature to be compatible).
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, context = "INFO") invisible(NULL)   # nolint
}

# APP_VERSION is referenced by init_session_data() inside utils.R; define a
# stub so sourcing utils.R doesn't abort.
if (!exists("APP_VERSION")) APP_VERSION <- "0.0.0-test"

# Constants referenced by parse_connection_value in utils.R
if (!exists("CONFIDENCE_LEVELS"))  CONFIDENCE_LEVELS  <- 1:5
if (!exists("CONFIDENCE_DEFAULT")) CONFIDENCE_DEFAULT <- 3L
if (!exists("DELAY_CATEGORIES"))   DELAY_CATEGORIES   <- c("immediate", "short-term", "medium-term", "long-term")
if (!exists("derive_delay_category")) {
  derive_delay_category <- function(x) "short-term"   # nolint
}

# Source utils.R (provides safe_readRDS) then the two ML modules.
utils_path  <- file.path(dirname(dirname(getwd())), "functions", "utils.R")
cf_path     <- file.path(dirname(dirname(getwd())), "functions", "ml_collaborative_filter.R")
bandit_path <- file.path(dirname(dirname(getwd())), "functions", "ml_response_bandit.R")

# Also handle invocation from the project root (e.g. testthat::test_dir)
if (!file.exists(utils_path)) {
  utils_path  <- file.path(getwd(), "functions", "utils.R")
  cf_path     <- file.path(getwd(), "functions", "ml_collaborative_filter.R")
  bandit_path <- file.path(getwd(), "functions", "ml_response_bandit.R")
}

can_source <- file.exists(utils_path) && file.exists(cf_path) && file.exists(bandit_path)

if (can_source) {
  source(utils_path,  local = FALSE)
  source(cf_path,     local = FALSE)
  source(bandit_path, local = FALSE)
}

# ==============================================================================
# SECTION 1: static-assertion fallback (always runs, even without sourcing)
# ==============================================================================

test_that("ml state loaders use safe_readRDS, not bare readRDS(path)", {
  for (f in c("functions/ml_collaborative_filter.R",
              "functions/ml_response_bandit.R")) {
    # Resolve path whether we are in project root or tests/testthat/
    fpath <- if (file.exists(f)) f else file.path("..", "..", f)
    skip_if_not(file.exists(fpath), paste("Cannot find", f))
    src <- paste(readLines(fpath, warn = FALSE), collapse = "\n")
    expect_true(
      grepl("safe_readRDS", src, fixed = TRUE),
      info = paste(f, "must call safe_readRDS")
    )
    expect_false(
      grepl("[^_]readRDS\\(path\\)", src),
      info = paste(f, "must not use bare readRDS(path)")
    )
  }
})

# ==============================================================================
# SECTION 2: behavioral tests (skipped if modules could not be sourced)
# ==============================================================================

skip_if(!can_source, "ML module source files not found — skipping behavioral tests")
skip_if(
  !exists("load_cf_state",        mode = "function") ||
  !exists("load_response_bandit", mode = "function") ||
  !exists("safe_readRDS",         mode = "function"),
  "Required functions not in scope — skipping behavioral tests"
)

# ---------------------------------------------------------------------------
# Helper: write a hostile R5 object to a temp file (safe_readRDS rejects R5)
# ---------------------------------------------------------------------------
write_hostile_r5 <- function(path) {
  MyR5 <- setRefClass("MyR5Hostile", fields = list(x = "numeric"))
  obj  <- MyR5$new(x = 42)
  saveRDS(obj, path)
}

# ---------------------------------------------------------------------------
# load_cf_state: R5 hostile object → NULL (fresh state = NULL for CF)
# ---------------------------------------------------------------------------

test_that("load_cf_state: hostile R5 file returns NULL, not the hostile object", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  write_hostile_r5(tmp)
  result <- suppressWarnings(load_cf_state(path = tmp))

  expect_null(result, info = "hostile R5 must be rejected; load_cf_state must return NULL")
})

test_that("load_cf_state: valid plain-list state loads correctly", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  # Minimal valid CF state: a list with $item_embeddings
  good_state <- list(
    item_embeddings = matrix(runif(10), nrow = 5),
    item_ids        = paste0("elem_", 1:5)
  )
  saveRDS(good_state, tmp)

  result <- load_cf_state(path = tmp)
  expect_true(is.list(result),          info = "valid CF state should be a list")
  expect_false(is.null(result$item_embeddings), info = "item_embeddings should be present")
})

test_that("load_cf_state: missing file returns NULL silently", {
  result <- load_cf_state(path = tempfile(fileext = ".rds"))
  expect_null(result)
})

# ---------------------------------------------------------------------------
# load_response_bandit: R5 hostile object → fresh init_response_bandit()
# ---------------------------------------------------------------------------

test_that("load_response_bandit: hostile R5 file returns fresh init, not hostile object", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  write_hostile_r5(tmp)
  result <- suppressWarnings(load_response_bandit(path = tmp))

  # Must NOT be an R5 / envRefClass
  expect_false(
    methods::is(result, "envRefClass"),
    info = "hostile R5 must not propagate through load_response_bandit"
  )
  # Must be a valid fresh bandit state (list with $arms and $A)
  expect_true(is.list(result),         info = "fallback must return a list")
  expect_true(!is.null(result$arms),   info = "fresh init must have $arms")
  expect_true(!is.null(result$A),      info = "fresh init must have $A")
})

test_that("load_response_bandit: valid plain-list state loads correctly", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  good_state <- init_response_bandit()
  saveRDS(good_state, tmp)

  result <- load_response_bandit(path = tmp)
  expect_true(is.list(result))
  expect_equal(result$arms, good_state$arms)
  expect_equal(length(result$A), length(good_state$A))
})

test_that("load_response_bandit: missing file returns fresh init silently", {
  result <- load_response_bandit(path = tempfile(fileext = ".rds"))
  expect_true(is.list(result))
  expect_true(!is.null(result$arms))
})
