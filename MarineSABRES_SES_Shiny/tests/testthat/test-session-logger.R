# tests/testthat/test-session-logger.R
# Unit tests for functions/session_logger.R
#
# See docs/superpowers/specs/2026-04-11-session-logger-design.md

library(testthat)
library(jsonlite)

# Source the implementation under test. This will fail in Task 1 (RED) because
# the file doesn't exist yet — that's the expected TDD starting state.
# Path is relative to the test runner's working directory (tests/testthat/).
test_logger_source <- function() {
  logger_path <- file.path("..", "..", "functions", "session_logger.R")
  if (file.exists(logger_path)) {
    source(logger_path, local = globalenv())
  }
}
test_logger_source()

# Helper: reset the cache env before each test so tests don't bleed into each other.
reset_session_log_cache <- function() {
  if (exists(".session_log_env", envir = globalenv())) {
    cache <- get(".session_log_env", envir = globalenv())
    if (is.environment(cache)) {
      if (exists("dir", envir = cache)) rm("dir", envir = cache)
    }
  }
}

# Helper: mock session for tests
make_mock_session <- function(sid = "sess_test000000000000000000000000",
                              lang = "en") {
  list(
    userData = list(session_id = sid),
    stub = TRUE
  )
}

make_mock_i18n <- function(lang = "en") {
  list(
    get_translation_language = function() lang
  )
}

# ============================================================================
# Test 1: resolver happy path (canonical Linux path writable)
# ============================================================================
test_that("resolve_session_log_dir returns canonical path when writable", {
  reset_session_log_cache()

  tmp_canonical <- file.path(tempdir(), paste0("canonical_", as.integer(Sys.time())))
  dir.create(tmp_canonical, recursive = TRUE, showWarnings = FALSE)

  withr::with_options(
    list(marinesabres.session_log_canonical = tmp_canonical),
    {
      result <- resolve_session_log_dir()
      expect_equal(normalizePath(result), normalizePath(tmp_canonical))
    }
  )

  unlink(tmp_canonical, recursive = TRUE)
})

# ============================================================================
# Test 2: resolver fallback when canonical path is unwritable
# ============================================================================
test_that("resolve_session_log_dir falls back to tempdir when canonical unwritable", {
  reset_session_log_cache()

  withr::with_options(
    list(marinesabres.session_log_canonical = ""),
    {
      result <- resolve_session_log_dir()
      expect_true(grepl("marinesabres_sessions", result, fixed = TRUE))
      expect_true(dir.exists(result))
    }
  )
})

# ============================================================================
# Test 3: resolver caches result — second call doesn't re-probe the filesystem
# ============================================================================
test_that("resolve_session_log_dir caches its result", {
  reset_session_log_cache()

  tmp_canonical <- file.path(tempdir(), paste0("cache_test_", as.integer(Sys.time())))
  dir.create(tmp_canonical, recursive = TRUE, showWarnings = FALSE)

  withr::with_options(
    list(marinesabres.session_log_canonical = tmp_canonical),
    {
      first <- resolve_session_log_dir()

      # Now remove the directory. If resolver is caching, second call still
      # returns the same path. If it re-probes, it would fall back to tempdir.
      unlink(tmp_canonical, recursive = TRUE)

      second <- resolve_session_log_dir()
      expect_equal(first, second)
    }
  )
})

# ============================================================================
# Test 4: log_session_start + log_session_end round-trip via NDJSON
# ============================================================================
test_that("log_session_start and log_session_end write parseable NDJSON", {
  reset_session_log_cache()

  tmp_log_dir <- file.path(tempdir(), paste0("roundtrip_", as.integer(Sys.time())))
  dir.create(tmp_log_dir, recursive = TRUE, showWarnings = FALSE)

  session <- make_mock_session(sid = "sess_roundtrip0000000000000000")
  i18n <- make_mock_i18n(lang = "fr")

  withr::with_options(
    list(marinesabres.session_log_canonical = tmp_log_dir),
    {
      if (!exists("APP_VERSION", envir = globalenv())) {
        assign("APP_VERSION", "test-1.0", envir = globalenv())
      }

      start_time <- Sys.time()
      log_session_start(session, i18n)
      Sys.sleep(0.1)
      log_session_end(session$userData$session_id, start_time)
    }
  )

  log_files <- list.files(tmp_log_dir, pattern = "^sessions-.*\\.jsonl$",
                         full.names = TRUE)
  expect_length(log_files, 1)

  lines <- readLines(log_files[1])
  expect_length(lines, 2)

  start_rec <- jsonlite::fromJSON(lines[1], simplifyVector = FALSE)
  end_rec   <- jsonlite::fromJSON(lines[2], simplifyVector = FALSE)

  expect_equal(start_rec$event, "session_start")
  expect_equal(start_rec$session_id, "sess_roundtrip0000000000000000")
  expect_equal(start_rec$lang, "fr")
  expect_match(start_rec$ts, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
  expect_true(!is.null(start_rec$app_version))

  expect_equal(end_rec$event, "session_end")
  expect_equal(end_rec$session_id, "sess_roundtrip0000000000000000")
  expect_true(is.numeric(end_rec$duration_s))
  expect_true(end_rec$duration_s >= 0)

  expect_null(end_rec$lang)

  unlink(tmp_log_dir, recursive = TRUE)
})

# ============================================================================
# Test 5: no-throw when logging is disabled (resolver returned NULL)
# ============================================================================
test_that("log_session_start never throws when resolver returns NULL", {
  reset_session_log_cache()

  if (!exists(".session_log_env", envir = globalenv())) {
    assign(".session_log_env", new.env(parent = emptyenv()), envir = globalenv())
  }
  cache <- get(".session_log_env", envir = globalenv())
  assign("dir", NULL, envir = cache)

  session <- make_mock_session()
  i18n <- make_mock_i18n()

  expect_no_error(log_session_start(session, i18n))
  expect_no_error(log_session_end(session$userData$session_id, Sys.time()))
})
