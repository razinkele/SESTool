# functions/session_isolation.R
# Session Isolation Utilities for Multi-User Shiny Server Deployments
#
# PURPOSE: Ensures complete data isolation between concurrent user sessions
# when running on shiny-server or shinyapps.io
#
# KEY FEATURES:
# - Cryptographically unique session IDs
# - Session-scoped temp directories
# - Automatic cleanup on disconnect
# - Session validation helpers

#' Generate a cryptographically unique session ID
#'
#' Creates a unique identifier for each user session that is:
#' - Collision-resistant across concurrent sessions
#' - Not predictable (includes random component)
#' - Contains timestamp for debugging
#'
#' @return Character string with unique session ID
#' @export
generate_session_id <- function() {

  # Combine multiple entropy sources for uniqueness
  # Note: %OS gives fractional seconds (e.g., "123456" for microseconds)
  # %f is not a valid R strptime format code
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S_%OS3")
  random_bytes <- paste0(sample(c(0:9, letters[1:6]), 16, replace = TRUE), collapse = "")
  process_id <- Sys.getpid()


  # Create composite ID
  raw_id <- paste(timestamp, random_bytes, process_id, sep = "_")

  # Hash for consistent length and additional collision resistance
  session_id <- paste0(
    "sess_",
    substr(digest::digest(raw_id, algo = "sha256"), 1, 24)
  )

  return(session_id)
}

#' Initialize session isolation for a Shiny session
#'
#' Sets up session-specific storage and identifiers. Call this at the
#' beginning of your server function.
#'
#' @param session Shiny session object
#' @return List with session isolation utilities
#' @export
init_session_isolation <- function(session) {
  # Generate unique session ID

  session_id <- generate_session_id()

  # Create session-specific temp directory
  session_temp_dir <- file.path(tempdir(), "marinesabres_sessions", session_id)
  if (!dir.exists(session_temp_dir)) {
    dir.create(session_temp_dir, recursive = TRUE, mode = "0700")
  }

  # Store in session$userData for access throughout the session
  session$userData$session_id <- session_id
  session$userData$session_temp_dir <- session_temp_dir
  session$userData$session_start_time <- Sys.time()
  session$userData$session_isolated <- TRUE

  # Log session initialization
  debug_log(sprintf("Session initialized: %s", session_id), "SESSION_ISOLATION")
  debug_log(sprintf("Session temp dir: %s", session_temp_dir), "SESSION_ISOLATION")

  # Setup automatic cleanup when session ends
  session$onSessionEnded(function() {
    cleanup_session_isolation(session_id, session_temp_dir)
  })

  # Return utilities for use in server
  list(
    session_id = session_id,
    temp_dir = session_temp_dir,
    get_temp_file = function(filename) {
      file.path(session_temp_dir, filename)
    },
    validate = function() {
      validate_session_isolation(session)
    }
  )
}

#' Get session-scoped temp file path
#'
#' Returns a path to a temp file that is isolated to the current session.
#' Use this instead of tempfile() for session-specific data.
#'
#' @param session Shiny session object
#' @param filename Name of the temp file
#' @param subdir Optional subdirectory within session temp
#' @return Full path to session-scoped temp file
#' @export
get_session_temp_file <- function(session, filename, subdir = NULL) {
  # Validate session has been initialized
  if (is.null(session$userData$session_temp_dir)) {
    stop("Session isolation not initialized. Call init_session_isolation() first.")
  }

  base_dir <- session$userData$session_temp_dir

  if (!is.null(subdir)) {
    base_dir <- file.path(base_dir, subdir)
    if (!dir.exists(base_dir)) {
      dir.create(base_dir, recursive = TRUE)
    }
  }

  file.path(base_dir, filename)
}

#' Get the current session ID
#'
#' @param session Shiny session object
#' @return Session ID string or NULL if not initialized
#' @export
get_session_id <- function(session) {
  session$userData$session_id
}

#' Validate that session isolation is properly configured
#'
#' Checks that all session isolation components are in place.
#' Useful for debugging and assertions.
#'
#' @param session Shiny session object
#' @return TRUE if properly isolated, FALSE otherwise
#' @export
validate_session_isolation <- function(session) {
  checks <- list(
    has_session_id = !is.null(session$userData$session_id),
    has_temp_dir = !is.null(session$userData$session_temp_dir),
    temp_dir_exists = !is.null(session$userData$session_temp_dir) &&
                      dir.exists(session$userData$session_temp_dir),
    has_i18n = !is.null(session$userData$i18n),
    is_isolated_flag = isTRUE(session$userData$session_isolated)
  )

  all_passed <- all(unlist(checks))

  if (!all_passed) {
    failed <- names(checks)[!unlist(checks)]
    debug_log(sprintf("Session isolation validation FAILED: %s",
                paste(failed, collapse = ", ")), "SESSION_ISOLATION")
  }

  return(all_passed)
}

#' Cleanup session-specific resources
#'
#' Called automatically when session ends. Removes all session-specific
#' temp files and directories.
#'
#' @param session_id Session ID to cleanup
#' @param session_temp_dir Session temp directory path
#' @export
cleanup_session_isolation <- function(session_id, session_temp_dir) {
  tryCatch({
    debug_log(sprintf("Cleaning up session: %s", session_id), "SESSION_ISOLATION")

    # Remove session temp directory and all contents
    if (!is.null(session_temp_dir) && dir.exists(session_temp_dir)) {
      # List files before removal for logging
      files <- list.files(session_temp_dir, recursive = TRUE)
      file_count <- length(files)

      unlink(session_temp_dir, recursive = TRUE)

      debug_log(sprintf("Removed %d files from session temp dir", file_count), "SESSION_ISOLATION")
    }

    # Also cleanup any legacy auto-save files for this session
    legacy_autosave_dir <- file.path(tempdir(), "marinesabres_autosave")
    if (dir.exists(legacy_autosave_dir)) {
      session_files <- list.files(legacy_autosave_dir, pattern = session_id, full.names = TRUE)
      if (length(session_files) > 0) {
        file.remove(session_files)
        debug_log(sprintf("Removed %d legacy autosave files", length(session_files)), "SESSION_ISOLATION")
      }
    }

    debug_log(sprintf("Session cleanup complete: %s", session_id), "SESSION_ISOLATION")

  }, error = function(e) {
    # Log but don't fail - session is ending anyway
    debug_log(sprintf("Session cleanup error (non-fatal): %s", e$message), "SESSION_ISOLATION")
  })
}

#' Create a session-scoped reactive value
#'
#' Wrapper around reactiveVal that logs the session context for debugging.
#' Useful for tracking down cross-session contamination issues.
#'
#' @param value Initial value
#' @param name Name for debugging
#' @param session Shiny session object
#' @return reactiveVal
#' @export
session_scoped_reactive <- function(value = NULL, name = "unnamed", session = NULL) {
  rv <- reactiveVal(value)

  if (!is.null(session) && !is.null(session$userData$session_id)) {
    debug_log(sprintf("Created session-scoped reactive '%s' for session %s",
                name, session$userData$session_id), "SESSION_ISOLATION")
  }

  return(rv)
}

#' Assert that code is running within an isolated session
#'
#' Use this at the start of sensitive operations to ensure
#' session isolation is active.
#'
#' @param session Shiny session object
#' @param context Description of what operation is being performed
#' @export
assert_session_isolated <- function(session, context = "operation") {
  if (!validate_session_isolation(session)) {
    stop(sprintf(
      "Session isolation required for %s but not properly initialized. Session ID: %s",
      context,
      session$userData$session_id %||% "UNKNOWN"
    ))
  }
  invisible(TRUE)
}

#' Get session diagnostic information
#'
#' Returns a list of diagnostic info about the current session.
#' Useful for debugging and support.
#'
#' @param session Shiny session object
#' @return List with diagnostic information
#' @export
get_session_diagnostics <- function(session) {
  list(
    session_id = session$userData$session_id %||% "NOT_SET",
    session_temp_dir = session$userData$session_temp_dir %||% "NOT_SET",
    session_start_time = session$userData$session_start_time %||% NA,
    session_uptime_minutes = if (!is.null(session$userData$session_start_time)) {
      round(as.numeric(difftime(Sys.time(), session$userData$session_start_time, units = "mins")), 1)
    } else NA,
    is_isolated = isTRUE(session$userData$session_isolated),
    has_i18n = !is.null(session$userData$i18n),
    process_id = Sys.getpid(),
    temp_dir_files = if (!is.null(session$userData$session_temp_dir) &&
                         dir.exists(session$userData$session_temp_dir)) {
      length(list.files(session$userData$session_temp_dir, recursive = TRUE))
    } else 0
  )
}
