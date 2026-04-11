# Session Logger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an R-side per-session NDJSON logger (`functions/session_logger.R`) that writes session start/end events to `/var/log/shiny-server/marinesabres/sessions-YYYY-MM-DD.jsonl` via `onSessionEnded`, replacing the reverted Sprint 4 M2 attempt at using the Pro-only `session_logging true;` config directive.

**Architecture:** TDD loop across 3 tasks. Task 1 writes failing unit tests. Task 2 implements the logger module and makes tests pass. Task 3 wires the logger into `global.R` + `app.R` server function. No new runtime dependencies (uses `jsonlite` which is already in Imports, `digest` which is already used by session_isolation, and base R only for I/O).

**Tech Stack:** R / testthat / jsonlite / base R file I/O

**Design source:** `docs/superpowers/specs/2026-04-11-session-logger-design.md` (committed 2026-04-11 as `975282f`)

**Drift check (verified 2026-04-11)**:
- `app.R:568` has `session_isolation <- init_session_isolation(session)`; line 570 has the existing `debug_log` for session start. New wiring goes between line 570 and 572.
- `global.R:649` sources `functions/session_isolation.R`. New `source("functions/session_logger.R")` goes right after that line so the logger is available when the server function runs.
- `init_session_isolation()` at `functions/session_isolation.R:52-89` sets `session$userData$session_id` at line 64 and registers its own `onSessionEnded` cleanup callback at line 74. Our new `onSessionEnded` from Task 3 will be registered AFTER (during session server function execution) — Shiny chains multiple callbacks in registration order, so cleanup fires first, then our end-log.
- `session_id` format verified: `"sess_" + 24 hex chars` = 29-char total string. Full value is logged (not truncated).
- `/var/log/shiny-server/` on laguna is owned `shiny:shiny` mode 755 (verified with `sudo -u shiny mkdir` on 2026-04-11). The shiny worker process can create `marinesabres/` subdir on first call.
- `APP_VERSION` is defined at top-level in `global.R:160` via `tryCatch(readLines("VERSION"))` and ends up in `globalenv()` at runtime — `get("APP_VERSION", envir = globalenv())` in the logger resolves correctly.

---

## File Map

| Task | Type | File | Effort |
|------|------|------|--------|
| 1 | Create | `tests/testthat/test-session-logger.R` (RED — functions don't exist yet) | 25 min |
| 2 | Create | `functions/session_logger.R` (GREEN — tests now pass) | 35 min |
| 3 | Modify | `global.R` (1-line source) + `app.R` (3-line wiring) | 15 min |

---

### Task 1: Write failing unit tests (RED)

**Files:**
- Create: `tests/testthat/test-session-logger.R`

**Background**: This task writes 5 unit tests that reference functions (`resolve_session_log_dir`, `log_session_start`, `log_session_end`) that don't exist yet. Running the tests should fail with "could not find function" errors. That's the expected TDD RED state. Task 2 makes them GREEN.

- [ ] **Step 1: Create the test file with 5 tests**

Write the full file contents to `tests/testthat/test-session-logger.R`:

```r
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
    # i18n must be accessible from the server-function scope, we pass it as a
    # separate argument to log_session_start — included here so test_4 can also
    # write the end event with a captured start_time.
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

  # Redirect the canonical path check to a temp directory we control.
  # The real resolver tries /var/log/shiny-server/marinesabres first, then
  # falls back to tempdir(). For this test we override the canonical path
  # with a writable temp path and expect the resolver to accept it.
  tmp_canonical <- file.path(tempdir(), paste0("canonical_", as.integer(Sys.time())))
  dir.create(tmp_canonical, recursive = TRUE, showWarnings = FALSE)

  # The resolver reads options("marinesabres.session_log_canonical") for
  # test-time overriding of the canonical path (design decision: testability
  # hook, default is the production /var/log path).
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

  # Point the canonical path at a location that can't be created (NULL dir on
  # a path inside a non-existent read-only root). The cleanest cross-platform
  # way: point at "" which dir.create rejects.
  withr::with_options(
    list(marinesabres.session_log_canonical = ""),
    {
      result <- resolve_session_log_dir()
      # Should fall back to <tempdir>/marinesabres_sessions
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
      # Stub APP_VERSION if not defined in test env
      if (!exists("APP_VERSION", envir = globalenv())) {
        assign("APP_VERSION", "test-1.0", envir = globalenv())
      }

      start_time <- Sys.time()
      log_session_start(session, i18n)
      Sys.sleep(0.1)  # ensure nonzero duration
      log_session_end(session$userData$session_id, start_time)
    }
  )

  # Find today's log file
  log_files <- list.files(tmp_log_dir, pattern = "^sessions-.*\\.jsonl$",
                         full.names = TRUE)
  expect_length(log_files, 1)

  lines <- readLines(log_files[1])
  expect_length(lines, 2)

  # Parse both lines — both must be valid JSON
  start_rec <- jsonlite::fromJSON(lines[1], simplifyVector = FALSE)
  end_rec   <- jsonlite::fromJSON(lines[2], simplifyVector = FALSE)

  # Start record fields
  expect_equal(start_rec$event, "session_start")
  expect_equal(start_rec$session_id, "sess_roundtrip0000000000000000")
  expect_equal(start_rec$lang, "fr")
  expect_match(start_rec$ts, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
  expect_true(!is.null(start_rec$app_version))

  # End record fields
  expect_equal(end_rec$event, "session_end")
  expect_equal(end_rec$session_id, "sess_roundtrip0000000000000000")
  expect_true(is.numeric(end_rec$duration_s))
  expect_true(end_rec$duration_s >= 0)

  # End should NOT have a lang field (only start events carry it)
  expect_null(end_rec$lang)

  unlink(tmp_log_dir, recursive = TRUE)
})

# ============================================================================
# Test 5: no-throw when logging is disabled (resolver returned NULL)
# ============================================================================
test_that("log_session_start never throws when resolver returns NULL", {
  reset_session_log_cache()

  # Force the cache to hold NULL, simulating a completely failed resolve.
  # The logger must accept this and silently no-op.
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
```

- [ ] **Step 2: Run tests to verify RED state**

```bash
Rscript -e "testthat::test_file('tests/testthat/test-session-logger.R')" 2>&1 | tail -30
```

Expected: all 5 tests fail with errors containing "could not find function \"resolve_session_log_dir\"" or "could not find function \"log_session_start\"". This is the expected RED state for TDD — the test file is valid but the implementation doesn't exist yet.

If any test passes, STOP — the test is not actually verifying the behavior it claims to.

- [ ] **Step 3: Commit (RED)**

```bash
git add tests/testthat/test-session-logger.R
git commit -m "$(cat <<'EOF'
test: add failing tests for session_logger (TDD red)

5 unit tests covering:
- resolve_session_log_dir happy path (writable canonical)
- resolve_session_log_dir fallback to tempdir on unwritable canonical
- resolve_session_log_dir caching (second call doesn't re-probe)
- log_session_start + log_session_end NDJSON round-trip
- log_session_start no-throw when resolver returned NULL

All tests currently fail with "could not find function" — this is the
expected TDD RED state. Task 2 implements functions/session_logger.R
and makes them pass.

Uses a testability hook: options("marinesabres.session_log_canonical")
overrides the production /var/log path. Default (option unset) is the
production path.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Implement the session logger (GREEN)

**Files:**
- Create: `functions/session_logger.R`

**Background**: Implement the 4 functions (resolver, path builder, start logger, end logger) plus the package-level cache env. Keep it under 120 lines. When this task is done, Task 1's tests turn from RED to GREEN.

- [ ] **Step 1: Create `functions/session_logger.R`**

Write the full file contents:

```r
# functions/session_logger.R
# ============================================================================
# Session Logger
#
# Writes one-line NDJSON events (session_start, session_end) to a daily-rotated
# log file. Designed as the R-side alternative to Shiny Server Pro's
# session_logging directive (which the open-source version we run does NOT
# support — see 2026-04-11 incident and
# docs/superpowers/specs/2026-04-11-session-logger-design.md).
#
# Contract: no codepath in this file can raise an exception that reaches
# Shiny's main loop. All I/O is wrapped in tryCatch; failures degrade to
# silent no-ops with a debug_log trail.
# ============================================================================

# Package-level cache environment for the resolved log directory.
# Stays alive for the life of the R worker process — resolve-and-test
# happens once per worker, not per session.
.session_log_env <- new.env(parent = emptyenv())

#' Resolve the directory where session log files live
#'
#' Resolution order:
#'   1. Canonical: /var/log/shiny-server/marinesabres/ (overridable in tests
#'      via options("marinesabres.session_log_canonical"))
#'   2. Fallback:  <tempdir>/marinesabres_sessions
#'   3. NULL:      logging is disabled, log_session_* become no-ops
#'
#' Result is cached in .session_log_env$dir after the first successful resolve.
#'
#' @return Character path to a writable directory, or NULL if nothing worked.
#' @keywords internal
resolve_session_log_dir <- function() {
  # Cache hit
  if (exists("dir", envir = .session_log_env)) {
    return(get("dir", envir = .session_log_env))
  }

  # Determine canonical path (test override or production default)
  canonical <- getOption("marinesabres.session_log_canonical",
                         "/var/log/shiny-server/marinesabres")

  # Try 1: canonical path
  result <- tryCatch({
    if (nzchar(canonical)) {
      dir.create(canonical, recursive = TRUE, showWarnings = FALSE)
      if (dir.exists(canonical) && file.access(canonical, mode = 2) == 0) {
        return_path <- canonical
      } else {
        return_path <- NULL
      }
    } else {
      return_path <- NULL
    }
    return_path
  }, error = function(e) NULL)

  # Try 2: tempdir fallback
  if (is.null(result)) {
    result <- tryCatch({
      fallback <- file.path(tempdir(), "marinesabres_sessions")
      dir.create(fallback, recursive = TRUE, showWarnings = FALSE)
      if (dir.exists(fallback) && file.access(fallback, mode = 2) == 0) {
        if (exists("debug_log", envir = globalenv())) {
          debug_log(sprintf("session_logger: canonical path unavailable, using tempdir fallback: %s", fallback),
                    "SESSION_LOG")
        }
        fallback
      } else {
        NULL
      }
    }, error = function(e) NULL)
  }

  # Cache the result (even if NULL, so we don't re-probe every call)
  assign("dir", result, envir = .session_log_env)

  if (is.null(result) && exists("debug_log", envir = globalenv())) {
    debug_log("session_logger: no writable log directory, logging disabled",
              "SESSION_LOG")
  }

  result
}

#' Build the per-day log file path
#'
#' Uses UTC date explicitly to avoid tz-ambiguity at day boundaries.
#' Single format() call — do NOT wrap in as.Date() which reintroduces local tz.
#'
#' @param dir Directory returned by resolve_session_log_dir()
#' @return Full path string, or NULL if dir is NULL.
#' @keywords internal
build_session_log_path <- function(dir) {
  if (is.null(dir)) return(NULL)
  date_str <- format(Sys.time(), "%Y-%m-%d", tz = "UTC")
  file.path(dir, paste0("sessions-", date_str, ".jsonl"))
}

#' Write a session_start event
#'
#' Fields: ts, event, session_id, lang, app_version.
#' All I/O is wrapped — this function cannot throw to the Shiny main loop.
#'
#' @param session Shiny session object (session$userData$session_id must be set
#'   by init_session_isolation() which runs earlier in the server function).
#' @param i18n Session-local i18n translator with get_translation_language() method.
#' @return invisible(NULL)
#' @export
log_session_start <- function(session, i18n) {
  tryCatch({
    dir <- resolve_session_log_dir()
    if (is.null(dir)) return(invisible(NULL))

    path <- build_session_log_path(dir)
    if (is.null(path)) return(invisible(NULL))

    sid <- tryCatch(session$userData$session_id, error = function(e) NULL)
    if (is.null(sid) || !nzchar(sid)) {
      if (exists("debug_log", envir = globalenv())) {
        debug_log("session_logger: session_id missing, skipping start event",
                  "SESSION_LOG")
      }
      return(invisible(NULL))
    }

    lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
    app_version <- tryCatch(get("APP_VERSION", envir = globalenv()),
                            error = function(e) "unknown")

    record <- list(
      ts = paste0(format(Sys.time(), "%Y-%m-%dT%H:%M:%S", tz = "UTC"), "Z"),
      event = "session_start",
      session_id = sid,
      lang = lang,
      app_version = app_version
    )

    line <- paste0(jsonlite::toJSON(record, auto_unbox = TRUE), "\n")
    cat(line, file = path, append = TRUE)
    invisible(NULL)
  }, error = function(e) {
    if (exists("debug_log", envir = globalenv())) {
      debug_log(paste("session_logger start failed:", conditionMessage(e)),
                "SESSION_LOG")
    }
    invisible(NULL)
  })
}

#' Write a session_end event
#'
#' Parameters are pre-captured locals (not extracted from session at end time)
#' because session$userData may be partially torn down in some shutdown paths.
#'
#' @param session_id Character session ID captured at session start
#' @param start_time POSIXct captured at session start
#' @return invisible(NULL)
#' @export
log_session_end <- function(session_id, start_time) {
  tryCatch({
    dir <- resolve_session_log_dir()
    if (is.null(dir)) return(invisible(NULL))

    path <- build_session_log_path(dir)
    if (is.null(path)) return(invisible(NULL))

    if (is.null(session_id) || !nzchar(session_id)) return(invisible(NULL))

    duration_s <- tryCatch(
      as.integer(round(as.numeric(difftime(Sys.time(), start_time, units = "secs")))),
      error = function(e) 0L
    )

    record <- list(
      ts = paste0(format(Sys.time(), "%Y-%m-%dT%H:%M:%S", tz = "UTC"), "Z"),
      event = "session_end",
      session_id = session_id,
      duration_s = duration_s
    )

    line <- paste0(jsonlite::toJSON(record, auto_unbox = TRUE), "\n")
    cat(line, file = path, append = TRUE)
    invisible(NULL)
  }, error = function(e) {
    if (exists("debug_log", envir = globalenv())) {
      debug_log(paste("session_logger end failed:", conditionMessage(e)),
                "SESSION_LOG")
    }
    invisible(NULL)
  })
}
```

- [ ] **Step 2: Verify R parses**

```bash
Rscript -e "parse('functions/session_logger.R'); cat('OK\n')"
```
Expected: `OK`

- [ ] **Step 3: Run the Task 1 tests — should now be GREEN**

```bash
Rscript -e "testthat::test_file('tests/testthat/test-session-logger.R')" 2>&1 | tail -30
```
Expected: all 5 tests pass (`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]` or similar testthat summary).

If any test fails, STOP — read the failure, fix the implementation (not the test), and re-run. Do NOT weaken the tests to make them pass.

- [ ] **Step 4: Commit (GREEN)**

```bash
git add functions/session_logger.R
git commit -m "$(cat <<'EOF'
feat: session_logger — per-session NDJSON event log (TDD green)

Implements the 4 functions from docs/superpowers/specs/2026-04-11-
session-logger-design.md:

- resolve_session_log_dir — canonical /var/log path with tempdir
  fallback, cached per R worker lifetime
- build_session_log_path — daily-rotated filename, UTC date
- log_session_start — NDJSON line with ts, event, session_id, lang,
  app_version via jsonlite::toJSON
- log_session_end — NDJSON line with duration_s computed from
  start_time captured at session entry

Contract: no exception reaches Shiny main loop. All I/O wrapped in
tryCatch, failures degrade to silent no-ops + debug_log trail.

Cache env (.session_log_env) holds the resolved path across sessions
within the same R worker. Test-time override via
options("marinesabres.session_log_canonical").

Makes Task 1's 5 unit tests pass.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Wire the logger into `global.R` and `app.R`

**Files:**
- Modify: `global.R` line 649 area (add 1-line source)
- Modify: `app.R` line 570 area (add 3-line wiring)

**Background**: Load the new file at startup, then call the logger from the server function right after `init_session_isolation` (so `session$userData$session_id` is set). Register `log_session_end` via `session$onSessionEnded` — this becomes the SECOND `onSessionEnded` callback (the first being the cleanup from `init_session_isolation`). Shiny chains them; cleanup fires first, then our end-log.

- [ ] **Step 1: Add source line in `global.R`**

Use Edit:

**Old:**
```r
source("functions/session_isolation.R", local = FALSE)  # FALSE = global scope for server access
```

**New:**
```r
source("functions/session_isolation.R", local = FALSE)  # FALSE = global scope for server access
source("functions/session_logger.R", local = FALSE)  # FALSE = global scope for logger functions
```

- [ ] **Step 2: Wire the logger hooks in `app.R` server function**

Find the existing block at `app.R:568-572`:

**Old:**
```r
  # ========== SESSION ISOLATION (MUST BE FIRST) ==========
  # Initialize session isolation for multi-user shiny-server deployments
  # This creates a unique session ID and session-scoped temp directory
  session_isolation <- init_session_isolation(session)

  debug_log(sprintf("New session started: %s", session_isolation$session_id), "SESSION")

  # ========== REACTIVE VALUES ==========
```

**New:**
```r
  # ========== SESSION ISOLATION (MUST BE FIRST) ==========
  # Initialize session isolation for multi-user shiny-server deployments
  # This creates a unique session ID and session-scoped temp directory
  session_isolation <- init_session_isolation(session)

  debug_log(sprintf("New session started: %s", session_isolation$session_id), "SESSION")

  # ========== SESSION LOGGER (M2 R-side replacement) ==========
  # Write NDJSON start/end events to /var/log/shiny-server/marinesabres/.
  # Defensive: session_logger handles its own errors; session_i18n may not
  # yet be in scope at this exact line, so we use the global i18n object.
  # Pre-capture session_id and start_time into locals BEFORE registering the
  # onSessionEnded closure — spec contract says log_session_end must NOT read
  # session$userData at end time (it may be partially torn down in some
  # shutdown paths). See docs/superpowers/specs/2026-04-11-session-logger-
  # design.md "Components: log_session_end" section.
  sid <- session$userData$session_id
  session_start_time <- Sys.time()
  log_session_start(session, i18n)
  session$onSessionEnded(function() {
    log_session_end(sid, session_start_time)
  })

  # ========== REACTIVE VALUES ==========
```

**Scope note**: `log_session_start(session, i18n)` passes the global `i18n` object (which has `get_translation_language()`) because the session-local `session_i18n` wrapper is constructed later in the server function. `session$userData$session_id` is already set by `init_session_isolation` on the previous line. `session_start_time` is captured in a local and closure-captured by the `onSessionEnded` callback — Shiny keeps the closure alive across the session lifetime.

**Why not use `session$userData$session_start_time`**: `init_session_isolation` sets that field at `session_isolation.R:66`, but the sub-second gap between that line and our new `Sys.time()` is irrelevant (<1ms). Using our own local variable keeps the logger's data flow self-contained and easier to reason about.

- [ ] **Step 3: Verify R parses**

```bash
Rscript -e "parse('global.R'); parse('app.R'); cat('OK\n')"
```
Expected: `OK`

- [ ] **Step 4: Re-run the unit tests to confirm no regression**

```bash
Rscript -e "testthat::test_file('tests/testthat/test-session-logger.R')" 2>&1 | tail -10
```
Expected: `[ FAIL 0 | ... | PASS 5 ]` (unchanged from Task 2).

- [ ] **Step 5: Smoke-test the full app startup locally (if feasible)**

```bash
Rscript -e "source('global.R'); cat('OK\n')" 2>&1 | tail -5
```
Expected: `OK` (may have harmless package/startup warnings, but no error about missing `log_session_start` or similar).

This does NOT fully start the Shiny server — it just verifies `global.R` sources cleanly with the new source line. Full integration is verified post-deploy by tailing the actual log file on laguna.

- [ ] **Step 6: Commit**

```bash
git add global.R app.R
git commit -m "$(cat <<'EOF'
feat: wire session_logger into server function startup (M2 replacement)

global.R: source the new functions/session_logger.R file right after
session_isolation (logical dependency ordering).

app.R: inside the server function, immediately after
init_session_isolation(session), pre-capture sid and session_start_
time into locals, then call log_session_start(session, i18n). Register
a second onSessionEnded callback that calls log_session_end(sid,
session_start_time) — the locals are closure-captured so the callback
does NOT read session$userData at end time (which may be partially
torn down in some shutdown paths, per the spec contract).

Shiny chains multiple onSessionEnded callbacks in registration order
— the existing cleanup_session_isolation callback fires first, our
end-log fires second.

Use the global i18n object (not session_i18n, which is constructed
later in the server function) for log_session_start's lang field.

This completes the M2 R-side replacement for the reverted Sprint 4
Task 1 (session_logging true; in shiny-server.conf — Pro-only).

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final Verification

- [ ] **Step 1: Confirm 3 new commits**

```bash
git log --oneline origin/main..HEAD | wc -l
```
Expected: `3` (test file + implementation + wiring).

```bash
git log --oneline origin/main..HEAD
```
Expected subjects (in order): `test:` → `feat:` (session_logger) → `feat:` (wire).

- [ ] **Step 2: Run the full unit test file one more time**

```bash
Rscript -e "testthat::test_file('tests/testthat/test-session-logger.R')" 2>&1 | tail -10
```
Expected: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]`

- [ ] **Step 3: R syntax check on all modified files**

```bash
Rscript -e "for (f in c('global.R','app.R','functions/session_logger.R','tests/testthat/test-session-logger.R')) parse(f); cat('OK\n')"
```
Expected: `OK`

- [ ] **Step 4: i18n audit (nothing should have changed but confirm no drift)**

```bash
micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```
Expected: `missing=0 ... hardcoded=0` (unchanged from Sprint 4 baseline).

- [ ] **Step 5: Push**

```bash
git push
```

- [ ] **Step 6: Deploy code to laguna**

```bash
bash deployment/remote-deploy.sh --force
```
Expected: `Extracted ~653 files` (roughly unchanged).

- [ ] **Step 7: Restart Shiny Server (MANUAL — requires interactive sudo)**

This step cannot be run non-interactively because `sudo systemctl restart` prompts for a password. The executing subagent must STOP here and ask the human operator to run:

```
ssh -t razinka@laguna.ku.lt "sudo systemctl restart shiny-server"
```

from an interactive shell. After the human confirms completion, the subagent resumes with Step 8.

- [ ] **Step 8: Generate real sessions in a browser (MANUAL)**

`curl` creates a session object but doesn't hold the WebSocket long enough for `onSessionEnded` to fire cleanly, so curl alone will only produce `session_start` events (possibly no events at all because the Shiny server handshake times out). The human operator must:

1. Open `https://laguna.ku.lt/marinesabres/` in a real browser
2. Wait for the dashboard to fully render
3. Close the tab

This produces one `session_start` and one `session_end` in the log file.

As a sanity check the subagent CAN run, verify the app is at least HTTP 200:

```bash
curl -sSL -o /dev/null -w "HTTP: %{http_code}\n" --max-time 30 "https://laguna.ku.lt/marinesabres/"
```
Expected: `HTTP: 200`

- [ ] **Step 9: Verify the log file exists and contains parseable NDJSON**

```bash
ssh razinka@laguna.ku.lt "ls -lh /var/log/shiny-server/marinesabres/sessions-*.jsonl && tail -5 /var/log/shiny-server/marinesabres/sessions-*.jsonl | jq ."
```

Expected:
- A file `sessions-YYYY-MM-DD.jsonl` in `/var/log/shiny-server/marinesabres/`
- At least one line parseable as JSON by `jq`
- Parsed line has fields: `ts`, `event = "session_start"`, `session_id` starting with `"sess_"`, `lang`, `app_version = "1.11.0"`

If `jq` isn't installed on laguna, substitute `cat` for a human-readable output.

- [ ] **Step 10: Verify no app crashes in the daemon log**

```bash
ssh razinka@laguna.ku.lt "sudo tail -20 /var/log/shiny-server.log"
```
Expected: normal `Starting listener` / `Shiny Server v1.5.22.1017` lines, NO `Error loading config` lines, NO R errors mentioning `session_logger`, `log_session_start`, or `session_log_env`.
