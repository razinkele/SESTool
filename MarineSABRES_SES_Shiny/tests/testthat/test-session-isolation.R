# test-session-isolation.R
# Comprehensive tests for functions/session_isolation.R
#
# Tests cover:
# - Session ID generation (uniqueness, format)
# - Temp directory creation per session
# - Directory isolation between sessions
# - Cleanup on disconnect
# - File operations within session scope
# - Edge cases: NULL session, uninitialized session
# - Concurrent session simulation
# - Session diagnostics and validation

library(testthat)

# Source session isolation functions directly
source("../../functions/session_isolation.R", local = TRUE)

# ============================================================================
# HELPER: Create a mock Shiny session object
# ============================================================================

create_mock_session <- function(user_data = list()) {
  # Accumulate onSessionEnded callbacks
  callbacks <- list()

  session <- list(
    userData = as.environment(user_data),
    onSessionEnded = function(callback) {
      callbacks[[length(callbacks) + 1L]] <<- callback
    },
    # Trigger all registered cleanup callbacks (simulates disconnect)
    .trigger_ended = function() {
      for (cb in callbacks) cb()
    },
    .get_callbacks = function() callbacks
  )

  session
}

# ============================================================================
# SESSION ID GENERATION
# ============================================================================

test_that("generate_session_id returns a character string", {
  id <- generate_session_id()
  expect_type(id, "character")
  expect_length(id, 1L)
})

test_that("generate_session_id starts with 'sess_' prefix", {
  id <- generate_session_id()
  expect_match(id, "^sess_")
})

test_that("generate_session_id has consistent length", {
  ids <- replicate(20, generate_session_id())
  # "sess_" (5 chars) + 24 hex chars = 29
  lengths <- nchar(ids)
  expect_true(all(lengths == 29))
})

test_that("generate_session_id produces unique IDs", {
  ids <- replicate(200, generate_session_id())
  expect_equal(length(unique(ids)), 200)
})

test_that("generate_session_id contains only valid characters", {
  ids <- replicate(50, generate_session_id())
  # Should be "sess_" followed by hex characters (0-9, a-f)
  for (id in ids) {
    expect_match(id, "^sess_[0-9a-f]{24}$")
  }
})

# ============================================================================
# INIT SESSION ISOLATION
# ============================================================================

test_that("init_session_isolation creates temp directory", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  expect_true(dir.exists(result$temp_dir))
})

test_that("init_session_isolation returns expected structure", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  expect_type(result, "list")
  expect_named(result, c("session_id", "temp_dir", "get_temp_file", "validate"),
               ignore.order = TRUE)
  expect_type(result$session_id, "character")
  expect_type(result$temp_dir, "character")
  expect_type(result$get_temp_file, "closure")
  expect_type(result$validate, "closure")
})

test_that("init_session_isolation populates session$userData", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  expect_equal(mock_session$userData$session_id, result$session_id)
  expect_equal(mock_session$userData$session_temp_dir, result$temp_dir)
  expect_true(inherits(mock_session$userData$session_start_time, "POSIXct"))
  expect_true(mock_session$userData$session_isolated)
})

test_that("init_session_isolation registers cleanup callback", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  callbacks <- mock_session$.get_callbacks()
  expect_gte(length(callbacks), 1L)
})

test_that("init_session_isolation get_temp_file helper works", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  path <- result$get_temp_file("test_output.csv")
  expect_equal(path, file.path(result$temp_dir, "test_output.csv"))
})

# ============================================================================
# DIRECTORY ISOLATION BETWEEN SESSIONS
# ============================================================================

test_that("two sessions get different temp directories", {
  session_a <- create_mock_session()
  session_b <- create_mock_session()

  result_a <- init_session_isolation(session_a)
  result_b <- init_session_isolation(session_b)

  on.exit({
    unlink(result_a$temp_dir, recursive = TRUE)
    unlink(result_b$temp_dir, recursive = TRUE)
  }, add = TRUE)

  expect_false(result_a$temp_dir == result_b$temp_dir)
  expect_true(dir.exists(result_a$temp_dir))
  expect_true(dir.exists(result_b$temp_dir))
})

test_that("files written in one session are not visible in another", {
  session_a <- create_mock_session()
  session_b <- create_mock_session()

  result_a <- init_session_isolation(session_a)
  result_b <- init_session_isolation(session_b)

  on.exit({
    unlink(result_a$temp_dir, recursive = TRUE)
    unlink(result_b$temp_dir, recursive = TRUE)
  }, add = TRUE)

  # Write a file in session A
  file_a <- result_a$get_temp_file("secret.txt")
  writeLines("session A data", file_a)

  # Session B should not see it
  file_b <- result_b$get_temp_file("secret.txt")
  expect_true(file.exists(file_a))
  expect_false(file.exists(file_b))

  # Listing session B dir should be empty
  expect_equal(length(list.files(result_b$temp_dir)), 0L)
})

# ============================================================================
# CLEANUP ON DISCONNECT
# ============================================================================

test_that("cleanup_session_isolation removes the temp directory", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  # Verify directory exists before cleanup

  expect_true(dir.exists(result$temp_dir))

  # Write some files
  writeLines("data1", result$get_temp_file("file1.txt"))
  writeLines("data2", result$get_temp_file("file2.txt"))
  expect_equal(length(list.files(result$temp_dir)), 2L)

  # Trigger session ended (fires cleanup callback)
  mock_session$.trigger_ended()

  # Directory should be removed
  expect_false(dir.exists(result$temp_dir))
})

test_that("cleanup of one session does not affect another", {
  session_a <- create_mock_session()
  session_b <- create_mock_session()

  result_a <- init_session_isolation(session_a)
  result_b <- init_session_isolation(session_b)

  on.exit(unlink(result_b$temp_dir, recursive = TRUE), add = TRUE)

  # Write files in both sessions
  writeLines("A", result_a$get_temp_file("a.txt"))
  writeLines("B", result_b$get_temp_file("b.txt"))

  # Clean up session A
  session_a$.trigger_ended()

  # Session A dir gone, session B dir intact
  expect_false(dir.exists(result_a$temp_dir))
  expect_true(dir.exists(result_b$temp_dir))
  expect_true(file.exists(result_b$get_temp_file("b.txt")))
})

test_that("cleanup handles already-removed directory gracefully", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  # Manually remove the directory first
  unlink(result$temp_dir, recursive = TRUE)
  expect_false(dir.exists(result$temp_dir))

  # Cleanup should not error
  expect_no_error(cleanup_session_isolation(result$session_id, result$temp_dir))
})

test_that("cleanup handles NULL temp dir gracefully", {
  expect_no_error(cleanup_session_isolation("sess_fake_id", NULL))
})

# ============================================================================
# FILE OPERATIONS WITHIN SESSION SCOPE
# ============================================================================

test_that("get_session_temp_file returns correct path", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  path <- get_session_temp_file(mock_session, "output.csv")
  expect_equal(path, file.path(result$temp_dir, "output.csv"))
})

test_that("get_session_temp_file creates subdirectory when specified", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  path <- get_session_temp_file(mock_session, "report.pdf", subdir = "exports")

  expected_subdir <- file.path(result$temp_dir, "exports")
  expect_true(dir.exists(expected_subdir))
  expect_equal(path, file.path(expected_subdir, "report.pdf"))
})

test_that("get_session_temp_file errors when session not initialized", {
  uninit_session <- create_mock_session()

  expect_error(
    get_session_temp_file(uninit_session, "file.txt"),
    "Session isolation not initialized"
  )
})

test_that("session temp files are writable and readable", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  # Write and read back
  test_path <- get_session_temp_file(mock_session, "round_trip.txt")
  test_content <- "Hello from session isolation test"
  writeLines(test_content, test_path)

  read_back <- readLines(test_path)
  expect_equal(read_back, test_content)
})

# ============================================================================
# GET SESSION ID
# ============================================================================

test_that("get_session_id returns ID after initialization", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  retrieved_id <- get_session_id(mock_session)
  expect_equal(retrieved_id, result$session_id)
})

test_that("get_session_id returns NULL for uninitialized session", {
  mock_session <- create_mock_session()
  expect_null(get_session_id(mock_session))
})

# ============================================================================
# VALIDATION
# ============================================================================

test_that("validate_session_isolation returns TRUE for properly initialized session", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  # Note: validation also checks for i18n, which we have not set
  # Without i18n, it should return FALSE
  expect_false(validate_session_isolation(mock_session))

  # Now set i18n and it should pass
  mock_session$userData$i18n <- list()
  expect_true(validate_session_isolation(mock_session))
})

test_that("validate_session_isolation returns FALSE for uninitialized session", {
  mock_session <- create_mock_session()
  expect_false(validate_session_isolation(mock_session))
})

test_that("validate_session_isolation returns FALSE when temp dir deleted", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)
  mock_session$userData$i18n <- list()

  # Remove the temp dir
  unlink(result$temp_dir, recursive = TRUE)

  expect_false(validate_session_isolation(mock_session))
})

# ============================================================================
# ASSERT SESSION ISOLATED
# ============================================================================

test_that("assert_session_isolated succeeds for fully initialized session", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)
  mock_session$userData$i18n <- list()

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  expect_invisible(assert_session_isolated(mock_session, "test operation"))
})

test_that("assert_session_isolated errors for uninitialized session", {
  mock_session <- create_mock_session()

  expect_error(
    assert_session_isolated(mock_session, "save project"),
    "Session isolation required for save project"
  )
})

# ============================================================================
# SESSION DIAGNOSTICS
# ============================================================================

test_that("get_session_diagnostics returns expected fields", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  diag <- get_session_diagnostics(mock_session)

  expect_type(diag, "list")
  expect_equal(diag$session_id, result$session_id)
  expect_equal(diag$session_temp_dir, result$temp_dir)
  expect_true(inherits(diag$session_start_time, "POSIXct"))
  expect_true(is.numeric(diag$session_uptime_minutes))
  expect_true(diag$is_isolated)
  expect_false(diag$has_i18n)
  expect_equal(diag$process_id, Sys.getpid())
  expect_equal(diag$temp_dir_files, 0L)
})

test_that("get_session_diagnostics counts files in temp dir", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  # Create some files
  writeLines("a", result$get_temp_file("one.txt"))
  writeLines("b", result$get_temp_file("two.txt"))

  diag <- get_session_diagnostics(mock_session)
  expect_equal(diag$temp_dir_files, 2L)
})

test_that("get_session_diagnostics handles uninitialized session", {
  mock_session <- create_mock_session()
  diag <- get_session_diagnostics(mock_session)

  expect_equal(diag$session_id, "NOT_SET")
  expect_equal(diag$session_temp_dir, "NOT_SET")
  expect_true(is.na(diag$session_start_time))
  expect_true(is.na(diag$session_uptime_minutes))
  expect_false(diag$is_isolated)
  expect_equal(diag$temp_dir_files, 0L)
})

# ============================================================================
# CONCURRENT SESSION SIMULATION
# ============================================================================

test_that("10 concurrent sessions maintain full isolation", {
  n <- 10
  sessions <- lapply(seq_len(n), function(i) create_mock_session())
  results <- lapply(sessions, init_session_isolation)

  on.exit({
    for (r in results) unlink(r$temp_dir, recursive = TRUE)
  }, add = TRUE)

  # All IDs are unique
  ids <- vapply(results, function(r) r$session_id, character(1))
  expect_equal(length(unique(ids)), n)

  # All temp dirs are unique and exist
  dirs <- vapply(results, function(r) r$temp_dir, character(1))
  expect_equal(length(unique(dirs)), n)
  for (d in dirs) expect_true(dir.exists(d))

  # Write session-specific data
  for (i in seq_len(n)) {
    writeLines(paste("session", i), results[[i]]$get_temp_file("identity.txt"))
  }

  # Verify each session reads its own data
  for (i in seq_len(n)) {
    content <- readLines(results[[i]]$get_temp_file("identity.txt"))
    expect_equal(content, paste("session", i))
  }
})

test_that("staggered cleanup of concurrent sessions works", {
  sessions <- lapply(1:5, function(i) create_mock_session())
  results <- lapply(sessions, init_session_isolation)

  # Write files in all sessions
  for (i in seq_along(sessions)) {
    writeLines(paste("data", i), results[[i]]$get_temp_file("data.txt"))
  }

  # Clean up sessions 1, 3, 5
  for (i in c(1, 3, 5)) {
    sessions[[i]]$.trigger_ended()
  }

  # Sessions 1, 3, 5 should be gone

  for (i in c(1, 3, 5)) {
    expect_false(dir.exists(results[[i]]$temp_dir))
  }

  # Sessions 2, 4 should still exist with data intact
  for (i in c(2, 4)) {
    expect_true(dir.exists(results[[i]]$temp_dir))
    content <- readLines(results[[i]]$get_temp_file("data.txt"))
    expect_equal(content, paste("data", i))
  }

  # Cleanup remaining
  for (i in c(2, 4)) {
    sessions[[i]]$.trigger_ended()
  }
})

# ============================================================================
# EDGE CASES
# ============================================================================

test_that("cleanup_session_isolation does not error on non-existent path", {
  expect_no_error(
    cleanup_session_isolation("sess_nonexistent", "/tmp/does_not_exist_12345")
  )
})

test_that("init_session_isolation is idempotent on temp dir creation", {
  mock_session <- create_mock_session()

  # First init
  result1 <- init_session_isolation(mock_session)
  dir1 <- result1$temp_dir

  on.exit(unlink(dir1, recursive = TRUE), add = TRUE)

  # Calling init again creates a new session (new ID, new dir)
  result2 <- init_session_isolation(mock_session)

  on.exit(unlink(result2$temp_dir, recursive = TRUE), add = TRUE)

  # Second call overwrites userData but both dirs should exist
  expect_true(dir.exists(dir1))
  expect_true(dir.exists(result2$temp_dir))
  expect_false(dir1 == result2$temp_dir)
})

test_that("session temp dir path contains session ID component", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  # The temp dir should be under marinesabres_sessions/<session_id>
  expect_true(grepl("marinesabres_sessions", result$temp_dir))
  expect_true(grepl(result$session_id, result$temp_dir))
})

test_that("get_session_temp_file handles nested subdirectories", {
  mock_session <- create_mock_session()
  result <- init_session_isolation(mock_session)

  on.exit(unlink(result$temp_dir, recursive = TRUE), add = TRUE)

  path <- get_session_temp_file(mock_session, "deep.txt", subdir = "a/b/c")
  expect_true(dir.exists(file.path(result$temp_dir, "a", "b", "c")))
  expect_equal(basename(path), "deep.txt")

  # Write and verify
  writeLines("deep content", path)
  expect_equal(readLines(path), "deep content")
})
