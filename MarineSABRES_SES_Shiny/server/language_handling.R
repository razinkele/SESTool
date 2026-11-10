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
      # Borrow the shared global translator: set this session's language, translate,
      # then ALWAYS restore (via on.exit) even if a step throws — otherwise a throw
      # would strand the process-global translator in this session's language for
      # other sessions on the worker. Atomic under single-threaded R (no async here).
      old_lang <- translator$get_translation_language()
      if (old_lang != env$current_lang) {
        on.exit(translator$set_translation_language(old_lang), add = TRUE)
        translator$set_translation_language(env$current_lang)
      }
      tryCatch(global_i18n$t(key), error = function(e) key)
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

      # Parse, validate AND normalise (review 2026-10-07 N4) -- the same path
      # as every other JSON load
      restored <- restore_project_from_json_text(input$restore_project_data_from_lang_change)

      if (is.null(restored)) {
        # Invalid or unreadable payload: tell the user instead of silently
        # starting from an empty project (review 2026-10-07 N60)
        debug_log("Invalid or unreadable project data in language-change restore", "LANG_RESTORE")
        shiny::showNotification(
          format_user_error(simpleError("invalid project data"), i18n = session_i18n,
                            context_key = "common.messages.context_language_change_restore"),
          type = "error",
          duration = 6
        )
        return()
      }

      project_data(restored)
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
    }, error = function(e) {
      debug_log(sprintf("ERROR restoring project data: %s", e$message), "LANG_RESTORE")
      # Surface a translated notification so the user knows their in-progress
      # work could not be restored after the language change (the default
      # template is used as the fallback). Previously this failed silently.
      shiny::showNotification(
        format_user_error(e, i18n = session_i18n,
                          context_key = "common.messages.context_language_change_restore"),
        type = "error",
        duration = 6
      )
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

# ============================================================================
# Per-language static UI
#
# The page layout (app.R build_app_ui()) is translated with the global i18n
# wrapper, which reads the shared translator's language. Building it once at
# startup froze every static heading in English; the language switch reloads
# the page with ?language=<code>, so the layout is now built per language on
# first request and cached for the life of the R process.
# ============================================================================

#' Language code requested in a page URL's query string
#'
#' @param query_string Raw query string (with or without leading "?"), or NULL
#' @param available Accepted language codes
#' @param default Code returned when the parameter is missing or not accepted
#' @return A single language code from `available`, or `default`
resolve_ui_language <- function(query_string, available, default = "en") {
  if (is.null(query_string) || !nzchar(query_string)) return(default)
  lang <- shiny::parseQueryString(query_string)$language
  if (is.null(lang) || length(lang) != 1 || !(lang %in% available)) return(default)
  lang
}

#' Does the query string carry Shiny bookmark state?
#'
#' Shiny restores bookmarked input values into input constructors while the UI
#' function runs, so such a build is visitor-specific and must not be cached.
#'
#' @param query_string Raw query string, or NULL
#' @return TRUE when `_inputs_`, `_values_` or `_state_id_` is present
has_bookmark_restore <- function(query_string) {
  if (is.null(query_string) || !nzchar(query_string)) return(FALSE)
  keys <- names(shiny::parseQueryString(query_string))
  any(c("_inputs_", "_values_", "_state_id_") %in% keys)
}

#' Build a Shiny UI function that renders the layout per language
#'
#' Nothing is built when this is called: every language, English included, is
#' built on its first request (laguna stops the R process seconds after the
#' last visitor leaves, so an eager English build would mostly be wasted).
#'
#' @param build_fn Zero-argument function returning the page tags; it must
#'   translate through the translator passed here (via the global i18n wrapper)
#' @param translator The shared shiny.i18n translator (get/set language)
#' @param available Accepted language codes
#' @param default Language for requests without a valid ?language=
#' @return function(request) for shinyApp(ui = ...); its "cache" attribute is
#'   the environment holding built layouts keyed by language code
make_per_language_ui <- function(build_fn, translator, available, default = "en") {
  cache <- new.env(parent = emptyenv())

  build_in <- function(lang) {
    # Borrow the shared translator and ALWAYS restore it (on.exit is registered
    # before the switch), so a failed build cannot strand other sessions in
    # this language. Single-threaded R: no other request runs meanwhile.
    old_lang <- translator$get_translation_language()
    on.exit(translator$set_translation_language(old_lang), add = TRUE)
    translator$set_translation_language(lang)
    if (neutral_restore) {
      # Shiny calls ui(request) inside the request's bookmark restore context;
      # build outside it so bookmarked values (e.g. actionButton click counts,
      # which would re-fire observeEvent handlers) never reach the static
      # inputs, as with the old static ui. Bookmarks still restore through the
      # server's onRestore (server/bookmarking.R).
      shiny_ns$withRestoreContext(shiny_ns$RestoreContext$new(), build_fn())
    } else {
      build_fn()
    }
  }

  # shiny's own uiHttpHandler uses these (unexported) helpers; if a future
  # shiny drops them, bookmark requests fall back to an uncached build.
  shiny_ns <- asNamespace("shiny")
  neutral_restore <- exists("withRestoreContext", envir = shiny_ns, inherits = FALSE) &&
    exists("RestoreContext", envir = shiny_ns, inherits = FALSE)

  ui <- function(request) {
    qs <- request$QUERY_STRING
    lang <- resolve_ui_language(qs, available, default)
    if (!neutral_restore && has_bookmark_restore(qs)) {
      debug_log(sprintf("Building uncached UI for bookmark restore (%s)", lang), "LANGUAGE")
      return(build_in(lang))
    }
    if (!exists(lang, envir = cache, inherits = FALSE)) {
      started <- Sys.time()
      built <- build_in(lang)  # a throw propagates and leaves nothing cached
      assign(lang, built, envir = cache)
      debug_log(sprintf("Built UI for '%s' in %.1f s", lang,
                        as.numeric(difftime(Sys.time(), started, units = "secs"))), "LANGUAGE")
    }
    get(lang, envir = cache, inherits = FALSE)
  }
  attr(ui, "cache") <- cache
  ui
}
