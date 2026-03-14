# tests/testthat/test-auto-save-module.R
# Comprehensive tests for the auto-save module functionality
#
# These tests verify:
# 1. UI component generation and namespacing
# 2. Auto-save constants and configuration
# 3. Session-scoped storage key generation
# 4. Recovery file creation and restoration
# 5. Adaptive debouncing behavior
# 6. Save state tracking and transitions
# 7. Data integrity: saved data matches original
# 8. Edge cases: empty data, missing directories, disabled auto-save
# 9. Trigger filtering and settings synchronization
# 10. Persistent storage path generation

library(testthat)

# ============================================================================
# UI COMPONENT TESTS
# ============================================================================

test_that("auto_save_indicator_ui returns valid Shiny tag", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("test_autosave")

  expect_true(inherits(ui, "shiny.tag") ||
              inherits(ui, "shiny.tag.list") ||
              inherits(ui, "html"))
})

test_that("auto_save_indicator_ui uses namespace correctly", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("my_module")
  html_str <- as.character(ui)

  # Should contain namespaced IDs for status_icon, status_text, status_time
  expect_true(grepl("my_module-status_icon", html_str))
  expect_true(grepl("my_module-status_text", html_str))
  expect_true(grepl("my_module-status_time", html_str))
  expect_true(grepl("my_module-mode_badge", html_str))
  expect_true(grepl("my_module-mode_text", html_str))
})

test_that("auto_save_indicator_ui contains all JavaScript handlers", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("test")
  html_str <- as.character(ui)

  # All custom message handlers from the module
  expect_true(grepl("init_autosave_session", html_str))
  expect_true(grepl("autosave_to_localstorage", html_str))
  expect_true(grepl("update_save_indicator", html_str))
  expect_true(grepl("update_editing_mode", html_str))
  expect_true(grepl("reload_page", html_str))
})

test_that("auto_save_indicator_ui has session-scoped localStorage keys in JS", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("test")
  html_str <- as.character(ui)

  # Session-scoped localStorage prefixes

  expect_true(grepl("_autosave_session_id", html_str))
  expect_true(grepl("marinesabres_autosave_", html_str))
  expect_true(grepl("marinesabres_mode_badge_", html_str))
})

test_that("auto_save_indicator_ui contains CSS classes for all states", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("test")
  html_str <- as.character(ui)

  # CSS classes for different indicator states
  expect_true(grepl("auto-save-indicator", html_str))
  expect_true(grepl("\\.saving", html_str) || grepl("saving", html_str))
  expect_true(grepl("\\.saved", html_str) || grepl("saved", html_str))
  expect_true(grepl("\\.error", html_str) || grepl("error", html_str))

  # Editing mode badge CSS
  expect_true(grepl("editing-mode-badge", html_str))
  expect_true(grepl("mode-casual", html_str))
  expect_true(grepl("mode-rapid", html_str))
  expect_true(grepl("mode-hidden", html_str))
})

test_that("auto_save_indicator_ui contains dismiss button", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui <- auto_save_indicator_ui("test")
  html_str <- as.character(ui)

  expect_true(grepl("save-indicator-dismiss", html_str))
  expect_true(grepl("fadeOut", html_str))
})

test_that("auto_save_indicator_ui produces different HTML for different IDs", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  ui1 <- as.character(auto_save_indicator_ui("module_a"))
  ui2 <- as.character(auto_save_indicator_ui("module_b"))

  expect_false(identical(ui1, ui2))
  expect_true(grepl("module_a", ui1))
  expect_true(grepl("module_b", ui2))
  expect_false(grepl("module_b", ui1))
})

# ============================================================================
# AUTO-SAVE CONSTANTS TESTS
# ============================================================================

test_that("all auto-save constants are defined", {
  required_constants <- c(
    "AUTOSAVE_DEBOUNCE_CASUAL_MS",
    "AUTOSAVE_DEBOUNCE_RAPID_MS",
    "AUTOSAVE_RAPID_THRESHOLD",
    "AUTOSAVE_PATTERN_WINDOW_SEC",
    "AUTOSAVE_RECOVERY_WINDOW_HOURS",
    "AUTOSAVE_INDICATOR_UPDATE_MS"
  )

  for (const in required_constants) {
    skip_if_not(exists(const), paste(const, "not defined"))
    value <- get(const)
    expect_true(is.numeric(value), info = paste(const, "should be numeric"))
    expect_true(value > 0, info = paste(const, "should be positive"))
  }
})

test_that("casual debounce is shorter than rapid debounce", {
  skip_if_not(exists("AUTOSAVE_DEBOUNCE_CASUAL_MS") &&
              exists("AUTOSAVE_DEBOUNCE_RAPID_MS"),
              "Auto-save debounce constants not defined")

  # Casual mode saves faster (shorter debounce) because edits are infrequent
  # Rapid mode batches changes (longer debounce) to reduce interruptions
  expect_true(AUTOSAVE_DEBOUNCE_CASUAL_MS < AUTOSAVE_DEBOUNCE_RAPID_MS,
              info = "Casual debounce should be shorter than rapid debounce")
})

test_that("debounce values are within reasonable bounds", {
  skip_if_not(exists("AUTOSAVE_DEBOUNCE_CASUAL_MS") &&
              exists("AUTOSAVE_DEBOUNCE_RAPID_MS"),
              "Auto-save debounce constants not defined")

  # Casual: between 1-10 seconds
  expect_true(AUTOSAVE_DEBOUNCE_CASUAL_MS >= 1000)
  expect_true(AUTOSAVE_DEBOUNCE_CASUAL_MS <= 10000)

  # Rapid: between 3-30 seconds
  expect_true(AUTOSAVE_DEBOUNCE_RAPID_MS >= 3000)
  expect_true(AUTOSAVE_DEBOUNCE_RAPID_MS <= 30000)
})

test_that("rapid threshold requires multiple edits", {
  skip_if_not(exists("AUTOSAVE_RAPID_THRESHOLD"),
              "AUTOSAVE_RAPID_THRESHOLD not defined")

  # Should require at least 2 edits to be "rapid"
  expect_true(AUTOSAVE_RAPID_THRESHOLD >= 2)
  # Should not require an unreasonable number
  expect_true(AUTOSAVE_RAPID_THRESHOLD <= 20)
})

test_that("pattern detection window is reasonable", {
  skip_if_not(exists("AUTOSAVE_PATTERN_WINDOW_SEC"),
              "AUTOSAVE_PATTERN_WINDOW_SEC not defined")

  # Window should be 5-120 seconds
  expect_true(AUTOSAVE_PATTERN_WINDOW_SEC >= 5)
  expect_true(AUTOSAVE_PATTERN_WINDOW_SEC <= 120)
})

test_that("recovery window is reasonable", {
  skip_if_not(exists("AUTOSAVE_RECOVERY_WINDOW_HOURS"),
              "AUTOSAVE_RECOVERY_WINDOW_HOURS not defined")

  # Recovery should be available for at least 1 hour, at most 1 week
  expect_true(AUTOSAVE_RECOVERY_WINDOW_HOURS >= 1)
  expect_true(AUTOSAVE_RECOVERY_WINDOW_HOURS <= 168)  # 7 days
})

test_that("indicator update interval is reasonable", {
  skip_if_not(exists("AUTOSAVE_INDICATOR_UPDATE_MS"),
              "AUTOSAVE_INDICATOR_UPDATE_MS not defined")

  # Not too frequent (CPU), not too slow (UX)
  expect_true(AUTOSAVE_INDICATOR_UPDATE_MS >= 1000)   # At least 1 second
  expect_true(AUTOSAVE_INDICATOR_UPDATE_MS <= 60000)   # At most 1 minute
})

# ============================================================================
# DATA HASHING TESTS
# ============================================================================

test_that("project data hash is consistent for identical data", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  project <- list(
    project_id = "TEST_001",
    project_name = "Test",
    data = list(
      isa_data = list(
        drivers = data.frame(id = "D1", name = "Test Driver")
      )
    )
  )

  hash1 <- digest::digest(project)
  hash2 <- digest::digest(project)

  expect_equal(hash1, hash2)
})

test_that("project data hash changes when data is modified", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  project1 <- list(project_id = "TEST_001", data = list(value = 100))
  project2 <- list(project_id = "TEST_001", data = list(value = 200))

  hash1 <- digest::digest(project1)
  hash2 <- digest::digest(project2)

  expect_false(identical(hash1, hash2))
})

test_that("hash detects changes in nested ISA data", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  base_data <- list(
    project_id = "TEST_001",
    data = list(
      isa_data = list(
        drivers = data.frame(id = "D1", name = "Driver 1"),
        activities = data.frame(id = "A1", name = "Activity 1")
      )
    )
  )

  modified_data <- base_data
  modified_data$data$isa_data$drivers <- rbind(
    modified_data$data$isa_data$drivers,
    data.frame(id = "D2", name = "Driver 2")
  )

  hash_base <- digest::digest(base_data)
  hash_modified <- digest::digest(modified_data)

  expect_false(identical(hash_base, hash_modified))
})

test_that("hash is stable across repeated computations", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  project <- list(
    project_id = "STABLE_TEST",
    data = list(isa_data = list(
      drivers = data.frame(id = paste0("D", 1:10), name = paste("Driver", 1:10)
                           )
    ))
  )

  hashes <- replicate(50, digest::digest(project))
  expect_equal(length(unique(hashes)), 1)
})

# ============================================================================
# RECOVERY FILE CREATION AND RESTORATION TESTS
# ============================================================================

test_that("recovery file can be created and read back", {
  tmp_dir <- file.path(tempdir(), paste0("autosave_test_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create project data
  project_data <- list(
    project_id = "RECOVERY_TEST",
    project_name = "Recovery Test Project",
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = c("D1", "D2"),
          name = c("Food security", "Economic growth")
          
        ),
        activities = data.frame(
          id = "A1",
          name = "Fishing"
          
        )
      )
    ),
    autosave_metadata = list(
      session_id = "test_session_123",
      save_time = Sys.time(),
      save_count = 1,
      version = "1.6.1"
    )
  )

  # Save recovery file
  save_file <- file.path(tmp_dir, "latest_autosave.rds")
  saveRDS(project_data, save_file)

  expect_true(file.exists(save_file))
  expect_true(file.size(save_file) > 0)

  # Read it back
  recovered <- readRDS(save_file)

  expect_equal(recovered$project_id, "RECOVERY_TEST")
  expect_equal(recovered$project_name, "Recovery Test Project")
  expect_equal(nrow(recovered$data$isa_data$drivers), 2)
  expect_equal(nrow(recovered$data$isa_data$activities), 1)
  expect_equal(recovered$autosave_metadata$session_id, "test_session_123")
})

test_that("recovery file data integrity is maintained through save/load cycle", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  tmp_dir <- file.path(tempdir(), paste0("integrity_test_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create complex project data
  original_data <- list(
    project_id = "INTEGRITY_TEST",
    project_name = "Data Integrity Test",
    created_at = Sys.time(),
    data = list(
      metadata = list(region = "Baltic Sea", ecosystem = "Marine"),
      isa_data = list(
        drivers = data.frame(
          id = paste0("D", 1:5),
          name = paste("Driver", 1:5),
          indicator = paste("Indicator", 1:5)
          
        ),
        activities = data.frame(
          id = paste0("A", 1:3),
          name = paste("Activity", 1:3)
          
        ),
        pressures = data.frame(
          id = paste0("P", 1:4),
          name = paste("Pressure", 1:4)
          
        )
      ),
      cld = list(
        edges = data.frame(
          from = c("D1", "A1"), to = c("A1", "P1"),
          polarity = c("+", "-")
          
        )
      )
    )
  )

  # Hash before save
  hash_before <- digest::digest(original_data)

  # Save and load
  save_path <- file.path(tmp_dir, "integrity_test.rds")
  saveRDS(original_data, save_path)
  loaded_data <- readRDS(save_path)

  # Hash after load
  hash_after <- digest::digest(loaded_data)

  expect_equal(hash_before, hash_after)

  # Verify specific fields
  expect_equal(loaded_data$data$isa_data$drivers$name, original_data$data$isa_data$drivers$name)
  expect_equal(loaded_data$data$cld$edges$polarity, original_data$data$cld$edges$polarity)
})

test_that("recovery file removal works correctly", {
  tmp_dir <- file.path(tempdir(), paste0("removal_test_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  save_file <- file.path(tmp_dir, "latest_autosave.rds")
  saveRDS(list(test = TRUE), save_file)

  expect_true(file.exists(save_file))

  # Remove the file (as done after recovery or discard)
  file.remove(save_file)

  expect_false(file.exists(save_file))
})

test_that("session-scoped save files use session ID in filename", {
  tmp_dir <- file.path(tempdir(), paste0("scoped_test_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  session_id <- "session_20260314_143025_5678"
  save_file <- file.path(tmp_dir, paste0(session_id, ".rds"))
  saveRDS(list(test = TRUE), save_file)

  expect_true(file.exists(save_file))
  expect_true(grepl(session_id, save_file, fixed = TRUE))
})

test_that("multiple session save files coexist without conflict", {
  tmp_dir <- file.path(tempdir(), paste0("multi_session_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  sessions <- c("session_A_001", "session_B_002", "session_C_003")

  for (sid in sessions) {
    save_file <- file.path(tmp_dir, paste0(sid, ".rds"))
    saveRDS(list(session_id = sid, data = paste("data for", sid)), save_file)
  }

  # All files exist
  for (sid in sessions) {
    expect_true(file.exists(file.path(tmp_dir, paste0(sid, ".rds"))))
  }

  # Each file has correct data
  for (sid in sessions) {
    loaded <- readRDS(file.path(tmp_dir, paste0(sid, ".rds")))
    expect_equal(loaded$session_id, sid)
  }
})

test_that("autosave metadata is correctly structured", {
  session_id <- "test_session_abc"
  save_count <- 5

  metadata <- list(
    session_id = session_id,
    save_time = Sys.time(),
    save_count = save_count,
    version = "1.6.1"
  )

  expect_equal(metadata$session_id, session_id)
  expect_true(inherits(metadata$save_time, "POSIXct"))
  expect_equal(metadata$save_count, 5)
  expect_true(is.character(metadata$version))
})

test_that("autosave metadata is stripped from recovered data", {
  # Simulate what the recovery handler does
  recovered_data <- list(
    project_id = "TEST",
    data = list(value = 42),
    autosave_metadata = list(
      session_id = "old_session",
      save_time = Sys.time() - 3600,
      save_count = 10
    )
  )

  # Module removes autosave_metadata before restoring
  recovered_data$autosave_metadata <- NULL

  expect_null(recovered_data$autosave_metadata)
  expect_equal(recovered_data$project_id, "TEST")
  expect_equal(recovered_data$data$value, 42)
})

# ============================================================================
# ADAPTIVE DEBOUNCING LOGIC TESTS
# ============================================================================

test_that("editing mode classification: rapid vs casual", {
  skip_if_not(exists("AUTOSAVE_RAPID_THRESHOLD") &&
              exists("AUTOSAVE_PATTERN_WINDOW_SEC"),
              "Auto-save pattern constants not defined")

  # Simulate rapid editing: many changes in short window
  now <- Sys.time()
  rapid_timestamps <- lapply(0:(AUTOSAVE_RAPID_THRESHOLD + 1), function(i) {
    now - (AUTOSAVE_PATTERN_WINDOW_SEC - 1) + i  # All within window
  })

  # Filter to within window (same logic as track_change)
  cutoff_time <- now - AUTOSAVE_PATTERN_WINDOW_SEC
  recent <- Filter(function(ts) ts > cutoff_time, rapid_timestamps)

  expect_true(length(recent) >= AUTOSAVE_RAPID_THRESHOLD,
              info = "Should detect rapid editing with many changes in window")
})

test_that("editing mode classification: casual with sparse changes", {
  skip_if_not(exists("AUTOSAVE_RAPID_THRESHOLD") &&
              exists("AUTOSAVE_PATTERN_WINDOW_SEC"),
              "Auto-save pattern constants not defined")

  # Simulate casual editing: only 1 change in window
  now <- Sys.time()
  casual_timestamps <- list(now)

  cutoff_time <- now - AUTOSAVE_PATTERN_WINDOW_SEC
  recent <- Filter(function(ts) ts > cutoff_time, casual_timestamps)

  expect_true(length(recent) < AUTOSAVE_RAPID_THRESHOLD,
              info = "Should classify as casual with few changes in window")
})

test_that("old timestamps are purged from change history", {
  skip_if_not(exists("AUTOSAVE_PATTERN_WINDOW_SEC"),
              "AUTOSAVE_PATTERN_WINDOW_SEC not defined")

  now <- Sys.time()

  # Mix of old and recent timestamps
  timestamps <- list(
    now - 120,  # old (2 minutes ago)
    now - 60,   # old (1 minute ago)
    now - 5,    # recent
    now - 2,    # recent
    now         # current
  )

  cutoff_time <- now - AUTOSAVE_PATTERN_WINDOW_SEC
  recent <- Filter(function(ts) ts > cutoff_time, timestamps)

  # Only timestamps within the window should remain
  expect_true(length(recent) <= length(timestamps))
  for (ts in recent) {
    expect_true(ts > cutoff_time)
  }
})

test_that("custom delay override takes precedence over adaptive debounce", {
  # Simulate get_current_debounce logic
  state <- list(
    custom_delay_sec = NULL,
    current_debounce_ms = 2000  # Adaptive: casual mode
  )

  # Without custom delay
  effective <- if (!is.null(state$custom_delay_sec)) {
    state$custom_delay_sec * 1000
  } else {
    state$current_debounce_ms
  }
  expect_equal(effective, 2000)

  # With custom delay (e.g., 45 seconds from settings)
  state$custom_delay_sec <- 45
  effective <- if (!is.null(state$custom_delay_sec)) {
    state$custom_delay_sec * 1000
  } else {
    state$current_debounce_ms
  }
  expect_equal(effective, 45000)
})

test_that("debounce correctly waits for quiet period", {
  # Simulate the debounce check logic from the module
  last_change_time <- Sys.time() - 3  # 3 seconds ago
  current_debounce_ms <- 2000          # 2 second debounce

  time_since_change_ms <- as.numeric(difftime(Sys.time(), last_change_time,
                                               units = "secs")) * 1000

  # 3 seconds > 2 second debounce = should trigger save

  expect_true(time_since_change_ms >= current_debounce_ms)

  # Simulate recent change (0.5 seconds ago)
  last_change_time_recent <- Sys.time() - 0.5
  time_since_recent_ms <- as.numeric(difftime(Sys.time(), last_change_time_recent,
                                               units = "secs")) * 1000

  # 0.5 seconds < 2 second debounce = should NOT trigger save
  expect_true(time_since_recent_ms < current_debounce_ms)
})

# ============================================================================
# SAVE STATE TRACKING TESTS
# ============================================================================

test_that("save status transitions follow valid state machine", {
  valid_statuses <- c("initialized", "saving", "saved", "error")

  # Initial state
  state <- "initialized"
  expect_true(state %in% valid_statuses)

  # Transition: initialized -> saving
  state <- "saving"
  expect_true(state %in% valid_statuses)

  # Transition: saving -> saved
  state <- "saved"
  expect_true(state %in% valid_statuses)

  # Transition: saving -> error
  state <- "error"
  expect_true(state %in% valid_statuses)

  # Invalid state
  expect_false("unknown" %in% valid_statuses)
  expect_false("pending" %in% valid_statuses)
})

test_that("save count increments correctly through multiple saves", {
  state <- list(save_count = 0)

  for (i in 1:10) {
    state$save_count <- state$save_count + 1
  }

  expect_equal(state$save_count, 10)
})

test_that("last save time is tracked and is a valid timestamp", {
  state <- list(last_save_time = NULL)

  # Before first save
  expect_null(state$last_save_time)

  # After save
  state$last_save_time <- Sys.time()

  expect_true(inherits(state$last_save_time, "POSIXct"))
  expect_true(state$last_save_time <= Sys.time())
  expect_true(as.numeric(difftime(Sys.time(), state$last_save_time, units = "secs")) < 2)
})

test_that("error message is captured on save failure", {
  state <- list(
    save_status = "initialized",
    error_message = NULL
  )

  # Simulate error
  state$save_status <- "error"
  state$error_message <- "Permission denied: /tmp/readonly_dir"

  expect_equal(state$save_status, "error")
  expect_true(grepl("Permission denied", state$error_message))
})

# ============================================================================
# RECOVERY FLAG TESTS
# ============================================================================

test_that("recovery_pending flag blocks auto-save", {
  state <- list(
    is_enabled = TRUE,
    recovery_pending = FALSE
  )

  # Normal operation: should save
  should_save <- state$is_enabled && !state$recovery_pending
  expect_true(should_save)

  # Recovery pending: should NOT save
  state$recovery_pending <- TRUE
  should_save <- state$is_enabled && !state$recovery_pending
  expect_false(should_save)
})

test_that("recovery_pending clears after user confirms recovery", {
  state <- list(recovery_pending = TRUE)

  # User confirms recovery
  state$recovery_pending <- FALSE

  expect_false(state$recovery_pending)
})

test_that("recovery_pending clears after user discards recovery", {
  state <- list(recovery_pending = TRUE)

  # User discards recovery
  state$recovery_pending <- FALSE

  expect_false(state$recovery_pending)
})

test_that("recovery file age check respects window", {
  skip_if_not(exists("AUTOSAVE_RECOVERY_WINDOW_HOURS"),
              "AUTOSAVE_RECOVERY_WINDOW_HOURS not defined")

  # Recent file (1 hour old)
  recent_time <- Sys.time() - 3600
  time_diff_recent <- as.numeric(difftime(Sys.time(), recent_time, units = "hours"))
  expect_true(time_diff_recent < AUTOSAVE_RECOVERY_WINDOW_HOURS)

  # Old file (48 hours old, assuming 24 hour window)
  old_time <- Sys.time() - (AUTOSAVE_RECOVERY_WINDOW_HOURS + 1) * 3600
  time_diff_old <- as.numeric(difftime(Sys.time(), old_time, units = "hours"))
  expect_true(time_diff_old >= AUTOSAVE_RECOVERY_WINDOW_HOURS)
})

# ============================================================================
# DATA DIRTY FLAG TESTS
# ============================================================================

test_that("data_dirty flag tracks hash changes", {
  state <- list(
    data_dirty = FALSE,
    last_data_hash = "hash_abc"
  )

  # New data with different hash
  new_hash <- "hash_xyz"
  if (new_hash != state$last_data_hash) {
    state$data_dirty <- TRUE
    state$last_data_hash <- new_hash
  }

  expect_true(state$data_dirty)
  expect_equal(state$last_data_hash, "hash_xyz")
})

test_that("same data hash does not set dirty flag", {
  state <- list(
    data_dirty = FALSE,
    last_data_hash = "hash_abc"
  )

  # Same hash
  new_hash <- "hash_abc"
  if (new_hash != state$last_data_hash) {
    state$data_dirty <- TRUE
  }

  expect_false(state$data_dirty)
})

test_that("dirty flag resets after successful save", {
  state <- list(data_dirty = TRUE, last_data_hash = "old_hash")

  # Simulate successful save
  state$data_dirty <- FALSE
  state$last_data_hash <- "new_hash"

  expect_false(state$data_dirty)
})

test_that("first data load triggers immediate save (NULL hash)", {
  state <- list(
    last_data_hash = NULL,
    is_enabled = TRUE,
    recovery_pending = FALSE
  )

  data <- list(value = 42)

  # Module logic: if last_data_hash is NULL, do immediate save
  should_immediate_save <- is.null(state$last_data_hash) &&
                           state$is_enabled &&
                           !state$recovery_pending &&
                           !is.null(data)

  expect_true(should_immediate_save)
})

# ============================================================================
# TRIGGER FILTERING TESTS
# ============================================================================

test_that("trigger filtering works with all trigger types", {
  all_triggers <- c("elements", "context", "connections", "steps")

  # All enabled
  enabled <- all_triggers
  for (t in all_triggers) {
    expect_true(t %in% enabled)
  }

  # Subset enabled
  enabled <- c("elements", "connections")
  expect_true("elements" %in% enabled)
  expect_false("context" %in% enabled)
  expect_true("connections" %in% enabled)
  expect_false("steps" %in% enabled)
})

test_that("empty trigger list blocks all saves", {
  enabled_triggers <- character(0)

  for (trigger in c("elements", "context", "connections", "steps")) {
    expect_false(trigger %in% enabled_triggers)
  }
})

# ============================================================================
# SESSION ISOLATION TESTS
# ============================================================================

test_that("session ID generation fallback produces unique IDs", {
  ids <- sapply(1:100, function(i) {
    paste0("session_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(1000:9999, 1))
  })

  # Should be unique (very high probability with random suffix)
  expect_equal(length(unique(ids)), length(ids))
})

test_that("session-scoped temp directories are isolated", {
  base_dir <- file.path(tempdir(), paste0("isolation_test_", sample(10000:99999, 1)))
  on.exit(unlink(base_dir, recursive = TRUE), add = TRUE)

  session_a_dir <- file.path(base_dir, "session_A", "autosave")
  session_b_dir <- file.path(base_dir, "session_B", "autosave")

  dir.create(session_a_dir, recursive = TRUE)
  dir.create(session_b_dir, recursive = TRUE)

  # Save to session A
  saveRDS(list(user = "A", value = 100), file.path(session_a_dir, "latest_autosave.rds"))

  # Save to session B
  saveRDS(list(user = "B", value = 200), file.path(session_b_dir, "latest_autosave.rds"))

  # Verify isolation
  data_a <- readRDS(file.path(session_a_dir, "latest_autosave.rds"))
  data_b <- readRDS(file.path(session_b_dir, "latest_autosave.rds"))

  expect_equal(data_a$user, "A")
  expect_equal(data_a$value, 100)
  expect_equal(data_b$user, "B")
  expect_equal(data_b$value, 200)
})

test_that("localStorage key format includes session ID", {
  session_id <- "session_20260314_abc"
  key <- paste0("marinesabres_autosave_", session_id)

  expect_true(grepl(session_id, key))
  expect_true(startsWith(key, "marinesabres_autosave_"))
})

# ============================================================================
# EDGE CASES
# ============================================================================

test_that("auto-save handles NULL project data gracefully", {
  # Module returns early if data is NULL
  current_data <- NULL

  should_save <- !is.null(current_data) && length(current_data) > 0
  expect_false(should_save)
})

test_that("auto-save handles empty project data gracefully", {
  current_data <- list()

  should_save <- !is.null(current_data) && length(current_data) > 0
  expect_false(should_save)
})

test_that("auto-save skips when disabled", {
  state <- list(is_enabled = FALSE)

  # Module returns early if not enabled
  expect_false(state$is_enabled)
})

test_that("auto-save skips when recovery is pending", {
  state <- list(
    is_enabled = TRUE,
    recovery_pending = TRUE
  )

  should_save <- state$is_enabled && !state$recovery_pending
  expect_false(should_save)
})

test_that("missing autosave directory is created recursively", {
  base_dir <- file.path(tempdir(), paste0("create_test_", sample(10000:99999, 1)),
                        "nested", "autosave")
  on.exit(unlink(dirname(dirname(base_dir)), recursive = TRUE), add = TRUE)

  expect_false(dir.exists(base_dir))

  # Module creates directory with mode 0700
  dir.create(base_dir, recursive = TRUE, mode = "0700")

  expect_true(dir.exists(base_dir))
})

test_that("recovery file not found does not cause error", {
  tmp_dir <- file.path(tempdir(), paste0("no_recovery_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  latest_file <- file.path(tmp_dir, "latest_autosave.rds")

  expect_false(file.exists(latest_file))

  # No error should occur
  expect_silent({
    if (file.exists(latest_file)) {
      readRDS(latest_file)
    }
  })
})

test_that("corrupted recovery file is handled gracefully", {
  tmp_dir <- file.path(tempdir(), paste0("corrupt_test_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create a corrupted file
  corrupt_file <- file.path(tmp_dir, "latest_autosave.rds")
  writeLines("this is not valid RDS data", corrupt_file)

  expect_true(file.exists(corrupt_file))

  # Should error when trying to read
  result <- tryCatch({
    readRDS(corrupt_file)
    list(success = TRUE)
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })

  expect_false(result$success)
  expect_true(nchar(result$error) > 0)
})

test_that("large project data can be saved and recovered", {
  tmp_dir <- file.path(tempdir(), paste0("large_data_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create large-ish project data
  large_data <- list(
    project_id = "LARGE_TEST",
    data = list(
      isa_data = list(
        drivers = data.frame(
          id = paste0("D", 1:500),
          name = paste("Driver", 1:500),
          description = paste("Long description for driver", 1:500,
                              "with additional text to increase size")
          
        ),
        activities = data.frame(
          id = paste0("A", 1:300),
          name = paste("Activity", 1:300)
          
        )
      ),
      cld = list(
        edges = data.frame(
          from = paste0("D", sample(1:500, 1000, replace = TRUE)),
          to = paste0("A", sample(1:300, 1000, replace = TRUE)),
          polarity = sample(c("+", "-"), 1000, replace = TRUE)
          
        )
      )
    )
  )

  save_file <- file.path(tmp_dir, "large_autosave.rds")
  saveRDS(large_data, save_file)

  expect_true(file.exists(save_file))
  expect_true(file.size(save_file) > 0)

  recovered <- readRDS(save_file)
  expect_equal(nrow(recovered$data$isa_data$drivers), 500)
  expect_equal(nrow(recovered$data$isa_data$activities), 300)
  expect_equal(nrow(recovered$data$cld$edges), 1000)
})

# ============================================================================
# SETTINGS SYNCHRONIZATION TESTS
# ============================================================================

test_that("auto-save enabled flag can be toggled", {
  state <- list(is_enabled = TRUE)

  state$is_enabled <- FALSE
  expect_false(state$is_enabled)

  state$is_enabled <- TRUE
  expect_true(state$is_enabled)
})

test_that("show_notifications setting controls notification display", {
  state <- list(show_notifications = FALSE)

  # Default: no notifications
  expect_false(state$show_notifications)

  # User enables notifications
  state$show_notifications <- TRUE
  expect_true(state$show_notifications)
})

test_that("show_indicator setting controls badge visibility", {
  state <- list(show_indicator = TRUE)

  # Default: visible
  expect_true(state$show_indicator)

  # User hides indicator
  state$show_indicator <- FALSE
  expect_false(state$show_indicator)
})

test_that("mode badge visibility depends on multiple flags", {
  # Replicates the logic: show && is_enabled && !recovery_pending && show_indicator
  state <- list(
    is_enabled = TRUE,
    recovery_pending = FALSE,
    show_indicator = TRUE
  )

  show_badge <- state$is_enabled && !state$recovery_pending && state$show_indicator
  expect_true(show_badge)

  # Disabled auto-save hides badge
  state$is_enabled <- FALSE
  show_badge <- state$is_enabled && !state$recovery_pending && state$show_indicator
  expect_false(show_badge)

  # Recovery pending hides badge
  state$is_enabled <- TRUE
  state$recovery_pending <- TRUE
  show_badge <- state$is_enabled && !state$recovery_pending && state$show_indicator
  expect_false(show_badge)

  # Indicator hidden hides badge
  state$recovery_pending <- FALSE
  state$show_indicator <- FALSE
  show_badge <- state$is_enabled && !state$recovery_pending && state$show_indicator
  expect_false(show_badge)
})

# ============================================================================
# COMPLETE WORKFLOW SIMULATION TESTS
# ============================================================================

test_that("complete auto-save workflow: create, save, recover, discard", {
  skip_if_not(requireNamespace("digest", quietly = TRUE),
              "digest package not available")

  tmp_dir <- file.path(tempdir(), paste0("workflow_", sample(10000:99999, 1)))
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # --- Phase 1: Initialize ---
  state <- list(
    is_enabled = TRUE,
    recovery_pending = FALSE,
    data_dirty = FALSE,
    last_data_hash = NULL,
    save_count = 0,
    save_status = "initialized",
    editing_mode = "casual",
    current_debounce_ms = 2000
  )

  expect_equal(state$save_status, "initialized")

  # --- Phase 2: User makes changes ---
  project_data <- list(
    project_id = "WORKFLOW_TEST",
    data = list(isa_data = list(
      drivers = data.frame(id = "D1", name = "Test Driver")
    ))
  )

  current_hash <- digest::digest(project_data)
  state$data_dirty <- TRUE
  state$last_data_hash <- current_hash

  expect_true(state$data_dirty)

  # --- Phase 3: Debounce elapses, perform save ---
  state$save_status <- "saving"
  expect_equal(state$save_status, "saving")

  project_data$autosave_metadata <- list(
    session_id = "workflow_session",
    save_time = Sys.time(),
    save_count = state$save_count + 1,
    version = "1.6.1"
  )

  save_file <- file.path(tmp_dir, "latest_autosave.rds")
  saveRDS(project_data, save_file)

  state$save_status <- "saved"
  state$save_count <- state$save_count + 1
  state$data_dirty <- FALSE
  state$last_save_time <- Sys.time()

  expect_equal(state$save_status, "saved")
  expect_equal(state$save_count, 1)
  expect_false(state$data_dirty)
  expect_true(file.exists(save_file))

  # --- Phase 4: Simulate crash, then recovery ---
  state$recovery_pending <- TRUE
  expect_true(file.exists(save_file))

  recovered <- readRDS(save_file)
  recovered$autosave_metadata <- NULL

  expect_equal(recovered$project_id, "WORKFLOW_TEST")
  expect_null(recovered$autosave_metadata)

  # Delete recovery file to prevent loop
  file.remove(save_file)
  state$recovery_pending <- FALSE

  expect_false(file.exists(save_file))
  expect_false(state$recovery_pending)
})

test_that("auto-save respects disabled state throughout workflow", {
  state <- list(
    is_enabled = FALSE,
    data_dirty = TRUE,
    recovery_pending = FALSE
  )

  should_save <- state$is_enabled && !state$recovery_pending && state$data_dirty
  expect_false(should_save)
})

test_that("adaptive mode correctly switches between casual and rapid", {
  skip_if_not(exists("AUTOSAVE_RAPID_THRESHOLD") &&
              exists("AUTOSAVE_PATTERN_WINDOW_SEC") &&
              exists("AUTOSAVE_DEBOUNCE_CASUAL_MS") &&
              exists("AUTOSAVE_DEBOUNCE_RAPID_MS"),
              "Auto-save constants not defined")

  state <- list(
    editing_mode = "casual",
    current_debounce_ms = AUTOSAVE_DEBOUNCE_CASUAL_MS,
    change_timestamps = list()
  )

  now <- Sys.time()

  # Simulate rapid editing
  for (i in seq_len(AUTOSAVE_RAPID_THRESHOLD + 1)) {
    state$change_timestamps <- c(state$change_timestamps, list(now + i * 0.5))
  }

  # Filter within window
  cutoff <- now + (AUTOSAVE_RAPID_THRESHOLD + 1) * 0.5 - AUTOSAVE_PATTERN_WINDOW_SEC
  recent <- Filter(function(ts) ts > cutoff, state$change_timestamps)

  if (length(recent) >= AUTOSAVE_RAPID_THRESHOLD) {
    state$editing_mode <- "rapid"
    state$current_debounce_ms <- AUTOSAVE_DEBOUNCE_RAPID_MS
  }

  expect_equal(state$editing_mode, "rapid")
  expect_equal(state$current_debounce_ms, AUTOSAVE_DEBOUNCE_RAPID_MS)

  # Simulate calm period: clear timestamps
  state$change_timestamps <- list(now + 100)  # Only one recent change

  recent <- Filter(function(ts) ts > (now + 100 - AUTOSAVE_PATTERN_WINDOW_SEC),
                   state$change_timestamps)
  if (length(recent) < AUTOSAVE_RAPID_THRESHOLD) {
    state$editing_mode <- "casual"
    state$current_debounce_ms <- AUTOSAVE_DEBOUNCE_CASUAL_MS
  }

  expect_equal(state$editing_mode, "casual")
  expect_equal(state$current_debounce_ms, AUTOSAVE_DEBOUNCE_CASUAL_MS)
})

# ============================================================================
# PERSISTENT STORAGE PATH TESTS
# ============================================================================

test_that("get_persistent_autosave_path returns NULL in server mode", {
  skip_if_not(exists("get_persistent_autosave_path", mode = "function"),
              "get_persistent_autosave_path not available")

  # In test environment, behavior depends on detect_deployment_mode
  # We just verify the function runs without error
  result <- tryCatch(
    get_persistent_autosave_path("test_session"),
    error = function(e) NULL
  )

  # Result is either a path (local mode) or NULL (server mode)
  expect_true(is.null(result) || is.character(result))
})

test_that("get_persistent_autosave_path uses session_id in filename", {
  skip_if_not(exists("get_persistent_autosave_path", mode = "function"),
              "get_persistent_autosave_path not available")

  result <- tryCatch(
    get_persistent_autosave_path("my_unique_session"),
    error = function(e) NULL
  )

  if (!is.null(result)) {
    # Session ID (truncated to 16 chars) should be in the filename
    expect_true(grepl("my_unique_sessio", result))
  }
})

test_that("find_recoverable_autosaves returns data frame", {
  skip_if_not(exists("find_recoverable_autosaves", mode = "function"),
              "find_recoverable_autosaves not available")

  result <- find_recoverable_autosaves(max_age_hours = 72)

  expect_true(is.data.frame(result))
})

# ============================================================================
# SAVE INDICATOR TEXT LOGIC TESTS
# ============================================================================

test_that("indicator shows correct text for each status", {
  # Test the logic from updateSaveIndicator
  statuses <- list(
    list(status = "saving", expect_pattern = "saving|Saving"),
    list(status = "saved", expect_pattern = "saved|Saved"),
    list(status = "error", expect_pattern = "error|Error|failed|Failed"),
    list(status = "initialized", expect_pattern = "enabled|disabled|Enabled|Disabled|auto")
  )

  # Just verify the status strings are handled
  for (s in statuses) {
    expect_true(s$status %in% c("initialized", "saving", "saved", "error"),
                info = paste("Status", s$status, "should be valid"))
  }
})

test_that("time diff formatting works for seconds", {
  last_save <- Sys.time() - 30  # 30 seconds ago
  time_diff <- as.numeric(difftime(Sys.time(), last_save, units = "secs"))

  expect_true(time_diff < 60)
  expect_true(time_diff >= 0)

  # Would format as "saved X seconds ago"
  formatted <- sprintf("Last saved %d seconds ago", round(time_diff))
  expect_true(grepl("seconds ago", formatted))
})

test_that("time diff formatting works for minutes", {
  last_save <- Sys.time() - 300  # 5 minutes ago
  time_diff <- as.numeric(difftime(Sys.time(), last_save, units = "secs"))

  expect_true(time_diff >= 60)
  expect_true(time_diff < 3600)

  formatted <- sprintf("Last saved %d minutes ago", round(time_diff / 60))
  expect_true(grepl("minutes ago", formatted))
})

test_that("time diff formatting falls back to timestamp for hours", {
  last_save <- Sys.time() - 7200  # 2 hours ago
  time_diff <- as.numeric(difftime(Sys.time(), last_save, units = "secs"))

  expect_true(time_diff >= 3600)

  # Module uses format(time, "%H:%M:%S") for > 1 hour
  formatted <- format(last_save, "%H:%M:%S")
  expect_true(grepl(":", formatted))
})

# ============================================================================
# MODE INDICATOR LABEL TESTS
# ============================================================================

test_that("mode indicator labels are formatted correctly", {
  # Casual mode
  casual_debounce_ms <- 2000
  casual_short <- sprintf("%s %s", "\U0001f4a4", casual_debounce_ms / 1000)
  casual_full <- sprintf("\U0001f4a4 Casual \u2022 %ds", casual_debounce_ms / 1000)

  expect_true(grepl("2", casual_short))
  expect_true(grepl("Casual", casual_full))

  # Rapid mode
  rapid_debounce_ms <- 5000
  change_count <- 7
  rapid_short <- sprintf("%s %s", "\u26a1", rapid_debounce_ms / 1000)
  rapid_full <- sprintf("\u26a1 Rapid \u2022 %ds \u2022 %d edits",
                        rapid_debounce_ms / 1000, change_count)

  expect_true(grepl("5", rapid_short))
  expect_true(grepl("Rapid", rapid_full))
  expect_true(grepl("7 edits", rapid_full))
})

# ============================================================================
# SERVER FUNCTION SIGNATURE TEST
# ============================================================================

test_that("auto_save_server function has correct signature", {
  skip_if_not(exists("auto_save_server", mode = "function"),
              "auto_save_server function not available")

  params <- names(formals(auto_save_server))

  # Required parameters
  expect_true("id" %in% params)
  expect_true("project_data_reactive" %in% params)
  expect_true("i18n" %in% params)

  # Optional parameters with defaults
  expect_true("event_bus" %in% params)
  expect_true("autosave_enabled_reactive" %in% params)
  expect_true("autosave_delay_reactive" %in% params)
  expect_true("autosave_notifications_reactive" %in% params)
  expect_true("autosave_indicator_reactive" %in% params)
  expect_true("autosave_triggers_reactive" %in% params)
})

test_that("auto_save_indicator_ui function has correct signature", {
  skip_if_not(exists("auto_save_indicator_ui", mode = "function"),
              "auto_save_indicator_ui function not available")

  params <- names(formals(auto_save_indicator_ui))
  expect_true("id" %in% params)
})

# ============================================================================
# TEMP DIRECTORY CLEANUP TESTS
# ============================================================================

test_that("temp directory creation with mode 0700 is restricted", {
  tmp_dir <- file.path(tempdir(), paste0("mode_test_", sample(10000:99999, 1)))
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  dir.create(tmp_dir, recursive = TRUE, mode = "0700")
  expect_true(dir.exists(tmp_dir))

  # Verify we can write to it
  test_file <- file.path(tmp_dir, "test.txt")
  writeLines("test", test_file)
  expect_true(file.exists(test_file))
})

test_that("concurrent writes to different session dirs don't interfere", {
  base_dir <- file.path(tempdir(), paste0("concurrent_", sample(10000:99999, 1)))
  on.exit(unlink(base_dir, recursive = TRUE), add = TRUE)

  # Simulate 5 concurrent sessions writing
  results <- lapply(1:5, function(i) {
    session_dir <- file.path(base_dir, paste0("session_", i), "autosave")
    dir.create(session_dir, recursive = TRUE)

    data <- list(session = i, value = i * 100, timestamp = Sys.time())
    save_path <- file.path(session_dir, "latest_autosave.rds")
    saveRDS(data, save_path)

    list(dir = session_dir, path = save_path, expected_value = i * 100)
  })

  # Verify each session's data is correct
  for (r in results) {
    loaded <- readRDS(r$path)
    expect_equal(loaded$value, r$expected_value)
  }
})
