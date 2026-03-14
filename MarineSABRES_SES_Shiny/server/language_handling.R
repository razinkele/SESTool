# server/language_handling.R
# ============================================================================
# Language Handling Functions
#
# Manages session-local i18n translation and language switching
# for multi-user shiny-server deployments.
# ============================================================================

#' Create Session-Local i18n Translator
#'
#' Creates a session-scoped i18n wrapper that maintains its own language state.
#' This is essential for multi-user deployments where each user may have
#' different language preferences.
#'
#' ARCHITECTURE NOTE: The app uses a dual i18n system by design:
#' 1. Global i18n (global.R) - Used for static UI rendering at app startup
#' 2. Session-local session_i18n (here) - Used for runtime translations
#'
#' @param global_i18n The global i18n translator from global.R
#' @param session_language_reactive A reactiveVal to track session language
#' @return A session-scoped translator object with t(), set_translation_language(), etc.
#' @export
create_session_i18n <- function(global_i18n, session_language_reactive) {
  # Private environment to store session-specific state
  env <- new.env(parent = emptyenv())
  env$current_lang <- "en"

  # Get reference to the underlying translator
  translator <- global_i18n$translator

  session_i18n <- list(
    t = function(key) {
      # Temporarily set the translator's language, translate, then restore
      # This is thread-safe because Shiny processes one session at a time per worker
      old_lang <- translator$get_translation_language()
      if (old_lang != env$current_lang) {
        translator$set_translation_language(env$current_lang)
      }
      result <- tryCatch({
        global_i18n$t(key)  # Use the wrapper's t() which handles namespaced keys
      }, error = function(e) {
        key  # Fallback to key on error
      })
      if (old_lang != env$current_lang) {
        translator$set_translation_language(old_lang)
      }
      result
    },

    set_translation_language = function(lang) {
      env$current_lang <- lang
      session_language_reactive(lang)  # Update reactive value
      debug_log(sprintf("Session language set to: %s", lang), "I18N")
    },

    get_translation_language = function() {
      env$current_lang
    },

    get_translations = function() {
      translator$get_translations()
    },

    use_js = function() {
      translator$use_js()
    },

    get_languages = function() {
      translator$get_languages()
    },

    get_key_translation = function() {
      translator$get_key_translation()
    },

    # Access to underlying translator if needed
    translator = translator
  )

  class(session_i18n) <- c("session_translator", "wrapped_translator", "list")

  session_i18n
}

#' Setup Language Change Handler
#'
#' Creates an observeEvent handler that restores project data after
#' a language change causes a page reload.
#'
#' @param input The Shiny input object
#' @param project_data A reactiveVal containing project data
#' @param session_i18n The session-local translator
#' @return The observeEvent handler (for reference, usually not needed)
#' @export
setup_language_restore_handler <- function(input, project_data, session_i18n) {
  shiny::observeEvent(input$restore_project_data_from_lang_change, {
    shiny::req(input$restore_project_data_from_lang_change)

    tryCatch({
      debug_log("Restoring project data after language change...", "LANG_RESTORE")

      # Parse the JSON data sent from JavaScript (safely)
      saved_data <- safe_parse_json(input$restore_project_data_from_lang_change)

      if (!is.null(saved_data)) {
        # Validate JSON input for security and structure
        validation_result <- validate_json_project_input(saved_data)
        if (!validation_result$valid) {
          debug_log(paste("Invalid project data in restored data:", paste(validation_result$errors, collapse = "; ")), "LANG_RESTORE")
          return()
        }

        # Restore the validated project data
        project_data(validation_result$data)
        debug_log("Project data restored successfully after language change", "LANG_RESTORE")

        # Show notification to user
        shiny::showNotification(
          shiny::HTML(paste0(
            shiny::icon("check-circle"), " ",
            session_i18n$t("common.messages.progress_restored_after_language_change")
          )),
          type = "message",
          duration = 4
        )
      }
    }, error = function(e) {
      debug_log(sprintf("ERROR restoring project data: %s", e$message), "LANG_RESTORE")
      # Don't show error to user, just log it - the default template will be used
    })
  }, ignoreInit = TRUE)
}

#' Get Supported Languages
#'
#' Returns the list of supported language codes.
#'
#' @return Character vector of language codes
#' @export
get_supported_languages <- function() {
  c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
}

#' Get Language Display Names
#'
#' Returns a named vector mapping language codes to display names.
#'
#' @return Named character vector (code -> name)
#' @export
get_language_display_names <- function() {
  c(
    "en" = "English",
    "es" = "Español",
    "fr" = "Français",
    "de" = "Deutsch",
    "lt" = "Lietuvių",
    "pt" = "Português",
    "it" = "Italiano",
    "no" = "Norsk",
    "el" = "Ελληνικά"
  )
}

#' Validate Language Code
#'
#' Checks if a language code is valid and supported.
#'
#' @param lang The language code to validate
#' @return TRUE if valid, FALSE otherwise
#' @export
is_valid_language <- function(lang) {
  !is.null(lang) &&
    is.character(lang) &&
    length(lang) == 1 &&
    lang %in% get_supported_languages()
}

#' Get Default Language
#'
#' Returns the default language code for new sessions.
#'
#' @return Language code string
#' @export
get_default_language <- function() {
  "en"
}
