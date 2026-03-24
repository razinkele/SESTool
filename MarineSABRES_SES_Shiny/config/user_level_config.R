# config/user_level_config.R
# Centralized user experience level configuration system
#
# Replaces scattered hardcoded if/else checks for beginner/intermediate/expert
# with a single configuration object per level. Users can customise settings
# via the Settings modal; overrides are persisted in localStorage.

# ============================================================================
# DEFAULT CONFIGURATIONS PER LEVEL
# ============================================================================

USER_LEVEL_DEFAULTS <- list(
  beginner = list(
    max_elements_per_category = 3L,
    show_pims                  = FALSE,
    show_graphical_ses_creator = FALSE,
    show_response_validation   = FALSE,
    show_all_analysis_tools    = FALSE,   # FALSE = only loops + leverage
    show_create_ses_method_chooser = FALSE, # FALSE = direct to AI/Template
    show_workflow_stepper      = TRUE,
    show_scenario_builder      = FALSE,
    template_filter            = "simple", # "simple" or "all"
    show_advanced_cld_controls = FALSE     # hide edit mode, advanced filters
  ),
  intermediate = list(
    max_elements_per_category  = 0L,      # 0 = unlimited
    show_pims                  = TRUE,
    show_graphical_ses_creator = TRUE,
    show_response_validation   = TRUE,
    show_all_analysis_tools    = TRUE,
    show_create_ses_method_chooser = TRUE,
    show_workflow_stepper      = TRUE,
    show_scenario_builder      = TRUE,
    template_filter            = "all",
    show_advanced_cld_controls = TRUE
  ),
  expert = list(
    max_elements_per_category  = 0L,
    show_pims                  = TRUE,
    show_graphical_ses_creator = TRUE,
    show_response_validation   = TRUE,
    show_all_analysis_tools    = TRUE,
    show_create_ses_method_chooser = TRUE,
    show_workflow_stepper      = TRUE,
    show_scenario_builder      = TRUE,
    template_filter            = "all",
    show_advanced_cld_controls = TRUE
  )
)

# All configurable setting keys (used for validation)
USER_LEVEL_CONFIG_KEYS <- names(USER_LEVEL_DEFAULTS[["beginner"]])

# ============================================================================
# RUNTIME CONFIG STORAGE (per-session, populated from localStorage on start)
# ============================================================================

# Environment to hold the active level config for the current session.
# This is populated once at startup from localStorage overrides, then
# updated when the user changes settings via the modal.
.user_level_config_env <- new.env(parent = emptyenv())
.user_level_config_env$overrides <- list()
.user_level_config_env$active_level <- "beginner"

# ============================================================================
# PUBLIC API
# ============================================================================

#' Get the effective configuration for a user level
#'
#' Returns the default config for the given level, with any user overrides
#' merged on top. Unknown keys in overrides are silently ignored.
#'
#' @param level Character: "beginner", "intermediate", or "expert"
#' @param overrides Optional named list of setting overrides (from localStorage)
#' @return Named list of all settings for the level
#' @export
get_level_config <- function(level = NULL, overrides = NULL) {
  # Fallback to active level if not specified
  if (is.null(level)) {
    level <- .user_level_config_env$active_level %||% "beginner"
  }

  # Validate level

  if (!level %in% names(USER_LEVEL_DEFAULTS)) {
    debug_log(sprintf("Unknown user level '%s', falling back to beginner", level), "LEVEL_CONFIG")
    level <- "beginner"
  }

  # Start with defaults

  config <- USER_LEVEL_DEFAULTS[[level]]

  # Merge session overrides (from .user_level_config_env)
  session_overrides <- .user_level_config_env$overrides
  if (length(session_overrides) > 0) {
    for (key in intersect(names(session_overrides), USER_LEVEL_CONFIG_KEYS)) {
      config[[key]] <- session_overrides[[key]]
    }
  }

  # Merge explicit overrides parameter (highest priority)
  if (!is.null(overrides) && is.list(overrides)) {
    for (key in intersect(names(overrides), USER_LEVEL_CONFIG_KEYS)) {
      config[[key]] <- overrides[[key]]
    }
  }

  config
}

#' Get a single setting value from the active level config
#'
#' Convenience wrapper for accessing one setting at a time.
#'
#' @param key Character: setting key name (e.g. "show_pims")
#' @param level Character: user level (default: active level)
#' @return The setting value, or NULL if key is unknown
#' @export
get_level_setting <- function(key, level = NULL) {
  config <- get_level_config(level)
  config[[key]]
}

#' Set the active user level and optional overrides
#'
#' Called when the user applies changes from the settings modal.
#'
#' @param level Character: "beginner", "intermediate", or "expert"
#' @param overrides Optional named list of per-setting overrides
#' @export
set_active_level_config <- function(level, overrides = NULL) {
  if (!level %in% names(USER_LEVEL_DEFAULTS)) {
    debug_log(sprintf("set_active_level_config: unknown level '%s'", level), "LEVEL_CONFIG")
    return(invisible(NULL))
  }

  .user_level_config_env$active_level <- level
  .user_level_config_env$overrides <- if (!is.null(overrides)) overrides else list()

  debug_log(sprintf("Active level config set: %s (overrides: %d)",
                     level, length(.user_level_config_env$overrides)), "LEVEL_CONFIG")
  invisible(get_level_config(level))
}

#' Reset overrides back to level defaults
#'
#' @param level Character: user level to reset
#' @export
reset_level_config <- function(level = NULL) {
  .user_level_config_env$overrides <- list()
  if (!is.null(level)) {
    .user_level_config_env$active_level <- level
  }
  debug_log("Level config overrides reset to defaults", "LEVEL_CONFIG")
  invisible(get_level_config())
}

#' Build a JSON-safe list for sending config to JavaScript / localStorage
#'
#' @param level Character: user level
#' @param overrides Named list of overrides only (not full config)
#' @return List suitable for jsonlite::toJSON
#' @export
build_level_config_for_js <- function(level, overrides = list()) {
  list(
    level = level,
    overrides = overrides
  )
}

#' Parse config received from JavaScript / localStorage
#'
#' @param js_data List received from JS (with $level and $overrides)
#' @return Named list with $level and $overrides
#' @export
parse_level_config_from_js <- function(js_data) {
  if (is.null(js_data)) {
    return(list(level = "beginner", overrides = list()))
  }

  level <- js_data$level %||% "beginner"
  if (!level %in% names(USER_LEVEL_DEFAULTS)) {
    level <- "beginner"
  }

  raw_overrides <- js_data$overrides
  overrides <- list()

  if (!is.null(raw_overrides) && is.list(raw_overrides)) {
    for (key in intersect(names(raw_overrides), USER_LEVEL_CONFIG_KEYS)) {
      val <- raw_overrides[[key]]
      # Coerce types to match defaults
      default_val <- USER_LEVEL_DEFAULTS[[level]][[key]]
      if (is.logical(default_val)) {
        overrides[[key]] <- as.logical(val)
      } else if (is.integer(default_val)) {
        overrides[[key]] <- as.integer(val)
      } else {
        overrides[[key]] <- as.character(val)
      }
    }
  }

  list(level = level, overrides = overrides)
}
