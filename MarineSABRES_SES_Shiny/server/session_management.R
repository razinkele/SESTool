# server/session_management.R
# ============================================================================
# Session Management Functions
#
# Handles session isolation and session-scoped resource management
# for multi-user shiny-server deployments.
# ============================================================================

#' Initialize Session Isolation
#'
#' Creates a unique session ID and session-scoped temp directory.
#' This is essential for multi-user deployments to prevent data leakage.
#'
#' @param session The Shiny session object
#' @return List containing session_id, session_temp_dir, and cleanup function
#' @export
init_session_isolation <- function(session) {
  # Generate unique session ID
  session_id <- paste0(
    format(Sys.time(), "%Y%m%d_%H%M%S"),
    "_",
    substr(digest::digest(runif(1)), 1, 8)
  )

  # Create session-scoped temp directory
  session_temp_dir <- file.path(tempdir(), paste0("ses_session_", session_id))
  if (!dir.exists(session_temp_dir)) {
    dir.create(session_temp_dir, recursive = TRUE)
    debug_log(sprintf("Created session temp dir: %s", session_temp_dir), "SESSION")
  }

  # Store in session$userData for access by other modules
  session$userData$session_id <- session_id
  session$userData$session_temp_dir <- session_temp_dir
  session$userData$session_start_time <- Sys.time()

  # Return isolation context
  list(
    session_id = session_id,
    session_temp_dir = session_temp_dir,
    cleanup = function() {
      # Cleanup function to be called on session end
      if (dir.exists(session_temp_dir)) {
        unlink(session_temp_dir, recursive = TRUE)
        debug_log(sprintf("Cleaned up session temp dir: %s", session_temp_dir), "SESSION")
      }
    }
  )
}

#' Initialize Session Reactive Values
#'
#' Creates the standard set of reactive values used across the application.
#' These values must be created within the server function context.
#'
#' @param session The Shiny session object
#' @return List of reactive values (project_data, user_level, autosave settings, etc.)
#' @export
init_session_reactive_values <- function(session) {
  list(
    # Main project data
    project_data = shiny::reactiveVal(init_session_data()),

    # User experience level (beginner/intermediate/expert)
    user_level = shiny::reactiveVal("beginner"),

    # Auto-save settings
    autosave_enabled = shiny::reactiveVal(TRUE),
    autosave_delay = shiny::reactiveVal(2),
    autosave_notifications = shiny::reactiveVal(FALSE),
    autosave_indicator = shiny::reactiveVal(TRUE),
    autosave_triggers = shiny::reactiveVal(c("elements", "context", "connections", "steps")),

    # SES Models directory setting
    ses_models_directory = shiny::reactiveVal(""),

    # Session-local language state
    session_language = shiny::reactiveVal("en")
  )
}

#' Get File System Volumes for shinyFiles
#'
#' Returns a named character vector of root directories for file browser dialogs.
#'
#' @return Named character vector of directory paths
#' @export
get_filesystem_volumes <- function() {
  volumes <- c(
    Home = Sys.getenv("HOME"),
    Documents = file.path(Sys.getenv("HOME"), "Documents"),
    App = normalizePath(".")
  )

  # Add system volumes on Windows/Mac
  tryCatch({
    system_volumes <- shinyFiles::getVolumes()()
    volumes <- c(volumes, system_volumes)
  }, error = function(e) {
    debug_log(sprintf("Could not get system volumes: %s", e$message), "SESSION")
  })

  volumes
}

#' Clear Server Autosaves
#'
#' Clears all autosave files from the session temp directory.
#' Used for "Clear Session & Start Fresh" functionality.
#'
#' @param session The Shiny session object
#' @param clear_persistent Whether to also clear persistent autosave folder
#' @return TRUE if successful, FALSE otherwise
#' @export
clear_server_autosaves <- function(session, clear_persistent = FALSE) {
  tryCatch({
    # Get session-scoped temp directory
    session_temp_dir <- session$userData$session_temp_dir

    if (!is.null(session_temp_dir) && dir.exists(session_temp_dir)) {
      # Remove autosave directory
      autosave_dir <- file.path(session_temp_dir, "autosave")
      if (dir.exists(autosave_dir)) {
        unlink(autosave_dir, recursive = TRUE)
        debug_log(sprintf("Cleared autosave directory: %s", autosave_dir), "CLEAR_SESSION")
      }

      # Also remove any .rds files in the session temp dir
      rds_files <- list.files(session_temp_dir, pattern = "\\.rds$", full.names = TRUE)
      for (f in rds_files) {
        file.remove(f)
        debug_log(sprintf("Removed: %s", f), "CLEAR_SESSION")
      }
    }

    # Optionally clear persistent autosave folder
    if (clear_persistent) {
      persistent_folder <- get_projects_folder(create_if_missing = FALSE)
      if (!is.null(persistent_folder) && dir.exists(persistent_folder)) {
        autosave_folder <- file.path(persistent_folder, "autosave")
        if (dir.exists(autosave_folder)) {
          # Only remove autosave subfolder, not saved projects
          unlink(autosave_folder, recursive = TRUE)
          debug_log("Cleared persistent autosave folder", "CLEAR_SESSION")
        }
      }
    }

    TRUE
  }, error = function(e) {
    debug_log(sprintf("Error clearing autosaves: %s", e$message), "CLEAR_SESSION")
    FALSE
  })
}

#' Log Session Diagnostics
#'
#' Logs diagnostic information about the current project state.
#' Only active when DEBUG_MODE is TRUE.
#'
#' @param project_data_reactive The reactive project_data value
#' @export
log_session_diagnostics <- function(project_data_reactive) {
  if (!exists("DEBUG_MODE") || !DEBUG_MODE) return()

  data <- shiny::isolate(project_data_reactive())

  if (!is.null(data) && !is.null(data$data$isa_data)) {
    debug_log("[DIAGNOSTIC] Project data loaded", "DIAGNOSTICS")

    element_types <- c("drivers", "activities", "pressures", "marine_processes",
                       "ecosystem_services", "goods_benefits", "responses")

    for (etype in element_types) {
      el <- data$data$isa_data[[etype]]
      if (!is.null(el) && nrow(el) > 0) {
        debug_log(sprintf("%s: %d elements", etype, nrow(el)), "DIAGNOSTICS")
        debug_log(sprintf("%s IDs: %s", etype, paste(head(el$ID, 10), collapse = ", ")), "DIAGNOSTICS")
      } else {
        debug_log(sprintf("%s: 0 elements", etype), "DIAGNOSTICS")
      }
    }

    if (!is.null(data$data$isa_data$adjacency_matrices)) {
      debug_log("Adjacency matrices present:", "DIAGNOSTICS")
      debug_log(paste(names(data$data$isa_data$adjacency_matrices), collapse = ", "), "DIAGNOSTICS")
    } else {
      debug_log("No adjacency matrices present", "DIAGNOSTICS")
    }
  } else {
    debug_log("Project data or isa_data is NULL", "DIAGNOSTICS")
  }
}
