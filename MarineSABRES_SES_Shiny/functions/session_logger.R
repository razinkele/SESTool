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
