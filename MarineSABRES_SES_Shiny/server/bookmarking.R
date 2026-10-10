# Bookmarking Setup
# Extracted from app.R for better maintainability
# Handles URL-based bookmarking: save state, restore state, bookmark modal

#' Validate values restored from a bookmark URL
#'
#' With enableBookmarking = "url", state$values is deserialised from the
#' `_values_` query parameter, so whoever wrote the link controls every field
#' and its JSON type (review 2026-10-07 N81 / N82). Pure: returns only the
#' fields that pass, each as a well-typed scalar; anything else is dropped.
#'
#' @param values state$values from onRestore()
#' @param levels allowed user levels
#' @param da_sites allowed demonstration areas (the PIMS select's choices)
#' @param max_focal maximum focal-issue length in characters
#' @return named list with any of user_level, autosave_enabled, active_tab,
#'   metadata_da_site, metadata_focal_issue
sanitize_bookmark_values <- function(values,
                                     levels = c("beginner", "intermediate", "expert"),
                                     da_sites = if (exists("DA_SITES")) DA_SITES else character(0),
                                     max_focal = 1000L) {
  out <- list()
  if (!is.list(values)) return(out)
  scalar_chr <- function(x) is.character(x) && length(x) == 1 && !is.na(x)

  v <- values$user_level
  if (scalar_chr(v) && v %in% levels) out$user_level <- v

  v <- values$autosave_enabled
  if (is.logical(v) && length(v) == 1 && !is.na(v)) out$autosave_enabled <- v

  v <- values$active_tab
  if (scalar_chr(v) && nchar(v) <= 64 && grepl("^[A-Za-z0-9_]+$", v)) out$active_tab <- v

  v <- values$metadata_da_site
  if (scalar_chr(v) && v %in% c("", da_sites)) out$metadata_da_site <- v

  v <- values$metadata_focal_issue
  if (scalar_chr(v) && nchar(v) <= max_focal) {
    # drop control characters other than ordinary line breaks / tabs
    out$metadata_focal_issue <- gsub("[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]", "", v, perl = TRUE)
  }
  out
}

#' Setup Bookmarking Handlers
#'
#' Configures URL-based bookmarking for the Shiny app, including
#' save/restore state handlers and bookmark URL modal.
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param project_data Reactive value containing project data
#' @param user_level Reactive value for user experience level
#' @param autosave_enabled Reactive value for auto-save setting
#' @param session_i18n i18n translation object
#' @param debug_log Debug logging function
setup_bookmarking <- function(input, output, session, project_data, user_level,
                               autosave_enabled, session_i18n, debug_log) {

  # ========== BOOKMARKING SETUP ==========
  # Enable bookmarking for this session
  setBookmarkExclude(c("save_project", "load_project", "confirm_save",
                       "confirm_load", "trigger_bookmark"))

  # ========== BOOKMARKING HANDLERS ==========

  # Save state when bookmark button is clicked
  observeEvent(input$trigger_bookmark, {
    session$doBookmark()
  })

  # Save app state for bookmarking
  onBookmark(function(state) {
    debug_log("Saving app state...", "BOOKMARK")

    # Save user level
    state$values$user_level <- user_level()

    # Save current tab
    if (!is.null(input$sidebar_menu)) {
      state$values$active_tab <- input$sidebar_menu
      debug_log(paste("Saved active tab:", input$sidebar_menu), "BOOKMARK")
    }

    # Save autosave setting
    state$values$autosave_enabled <- autosave_enabled()

    # Save project data (serialized as JSON for URL safety)
    # Note: Only save essential data to avoid URL length limits
    data <- project_data()

    # Save metadata
    if (!is.null(data$data$metadata)) {
      state$values$metadata_da_site <- data$data$metadata$da_site
      state$values$metadata_focal_issue <- data$data$metadata$focal_issue
    }

    # Indicate if ISA data exists
    state$values$has_isa_data <- !is.null(data$data$isa_data$goods_benefits) &&
                                  nrow(data$data$isa_data$goods_benefits) > 0

    # Indicate if CLD exists
    state$values$has_cld_data <- !is.null(data$data$cld$nodes) &&
                                  nrow(data$data$cld$nodes) > 0

    debug_log("State saved successfully", "BOOKMARK")
  })

  # Show modal after bookmark URL is generated
  onBookmarked(function(url) {
    debug_log(paste("Bookmark URL created:", url), "BOOKMARK")

    # Show bookmark modal with URL
    showModal(modalDialog(
      title = tags$h3(icon("bookmark"), " ", session_i18n$t("ui.modals.bookmark_created")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(session_i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("check-circle"), " ", session_i18n$t("ui.modals.bookmark_success")),
        tags$p(session_i18n$t("ui.modals.bookmark_copy_instruction")),

        tags$div(
          class = "well",
          style = "background: #f8f9fa; padding: 15px; margin: 20px 0;",
          tags$textarea(
            id = "bookmark_url",
            class = "form-control",
            rows = 4,
            readonly = "readonly",
            style = "font-family: monospace; font-size: 12px; resize: vertical;",
            url
          )
        ),

        local({
          # Prepare translated strings for injection into JavaScript
          copied_text <- session_i18n$t("common.buttons.copied")
          copy_text <- session_i18n$t("ui.modals.bookmark_copy_url")
          js_safe <- function(txt) {
            raw <- jsonlite::toJSON(txt, auto_unbox = TRUE)
            substr(raw, 2, nchar(raw) - 1)
          }
          js_copied <- js_safe(copied_text)
          js_copy <- js_safe(copy_text)

          tags$button(
            id = "copy_bookmark_btn",
            class = "btn btn-primary btn-block",
            icon("copy"),
            " ", copy_text,
            onclick = sprintf("
              var btn = this;
              var text = document.getElementById('bookmark_url').value;
              if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(function() {
                  $(btn).html('<i class=\"fa fa-check\"></i> %s');
                  setTimeout(function() {
                    $(btn).html('<i class=\"fa fa-copy\"></i> %s');
                  }, 2000);
                }, function() {
                  var textarea = document.getElementById('bookmark_url');
                  textarea.select();
                  document.execCommand('copy');
                  $(btn).html('<i class=\"fa fa-check\"></i> %s');
                  setTimeout(function() {
                    $(btn).html('<i class=\"fa fa-copy\"></i> %s');
                  }, 2000);
                });
              } else {
                var textarea = document.getElementById('bookmark_url');
                textarea.select();
                document.execCommand('copy');
                $(btn).html('<i class=\"fa fa-check\"></i> %s');
                setTimeout(function() {
                  $(btn).html('<i class=\"fa fa-copy\"></i> %s');
                }, 2000);
              }
            ", js_copied, js_copy, js_copied, js_copy, js_copied, js_copy)
          )
        }),

        tags$hr(),

        tags$div(
          class = "alert alert-info",
          icon("info-circle"),
          tags$strong(" ", session_i18n$t("common.labels.note"), ": "),
          session_i18n$t("ui.modals.bookmark_note")
        ),

        tags$h5(session_i18n$t("ui.modals.bookmark_saved_items")),
        tags$ul(
          tags$li(session_i18n$t("ui.modals.bookmark_tab_location")),
          tags$li(session_i18n$t("ui.modals.bookmark_experience_level")),
          tags$li(session_i18n$t("ui.modals.bookmark_language")),
          tags$li(session_i18n$t("ui.modals.bookmark_autosave")),
          tags$li(session_i18n$t("ui.modals.bookmark_demo_area"))
        )
      )
    ))
  })

  # Restore state from bookmark
  onRestore(function(state) {
    debug_log("Restoring app state...", "BOOKMARK")

    # Every value comes from the URL: validate type and content first
    # (review 2026-10-07 N81 / N82). A non-logical autosave flag used to crash
    # the session on the first flush; unvalidated metadata reached reports.
    vals <- sanitize_bookmark_values(state$values)
    dropped <- setdiff(intersect(names(state$values),
                                 c("user_level", "autosave_enabled", "active_tab",
                                   "metadata_da_site", "metadata_focal_issue")),
                       names(vals))
    if (length(dropped) > 0) {
      debug_log(paste("Ignored invalid bookmark values:", paste(dropped, collapse = ", ")), "BOOKMARK")
    }

    # Restore user level
    if (!is.null(vals$user_level)) {
      user_level(vals$user_level)
      debug_log(paste("Restored user level:", vals$user_level), "BOOKMARK")
    }

    # Restore autosave setting
    if (!is.null(vals$autosave_enabled)) {
      autosave_enabled(vals$autosave_enabled)
      debug_log(paste("Restored autosave setting:", vals$autosave_enabled), "BOOKMARK")
    }

    # Restore metadata if saved
    if (!is.null(vals$metadata_da_site) || !is.null(vals$metadata_focal_issue)) {
      data <- project_data()
      if (!is.null(vals$metadata_da_site)) {
        data$data$metadata$da_site <- vals$metadata_da_site
      }
      if (!is.null(vals$metadata_focal_issue)) {
        data$data$metadata$focal_issue <- vals$metadata_focal_issue
      }
      project_data(data)
      debug_log("Restored metadata", "BOOKMARK")
    }

    # Restore active tab
    if (!is.null(vals$active_tab)) {
      updateTabItems(session, "sidebar_menu", vals$active_tab)
      debug_log(paste("Restored active tab:", vals$active_tab), "BOOKMARK")
    }

    # Show restoration notification
    showNotification(
      HTML(paste0(
        icon("bookmark"), " ",
        session_i18n$t("common.messages.bookmark_restored_successfully")
      )),
      type = "message",
      duration = 5
    )

    debug_log("State restored successfully", "BOOKMARK")
  })

  # Restore tab after bookmark URL is loaded
  observeEvent(input$sidebar_menu, {
    query <- parseQueryString(session$clientData$url_search)
    if ("_state_id_" %in% names(query)) {
      debug_log("Bookmarked session detected", "BOOKMARK")
    }
  }, once = TRUE)
}
