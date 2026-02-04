# Bookmarking Setup
# Extracted from app.R for better maintainability
# Handles URL-based bookmarking: save state, restore state, bookmark modal

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
      title = tags$h3(icon("bookmark"), " Bookmark Created"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(session_i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("check-circle"), " Your bookmark has been created!"),
        tags$p("Copy the URL below to save your current application state:"),

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

        tags$button(
          id = "copy_bookmark_btn",
          class = "btn btn-primary btn-block",
          icon("copy"),
          " Copy URL to Clipboard",
          onclick = "
            var textarea = document.getElementById('bookmark_url');
            textarea.select();
            document.execCommand('copy');
            $(this).html('<i class=\"fa fa-check\"></i> Copied!');
            setTimeout(() => {
              $(this).html('<i class=\"fa fa-copy\"></i> Copy URL to Clipboard');
            }, 2000);
          "
        ),

        tags$hr(),

        tags$div(
          class = "alert alert-info",
          icon("info-circle"),
          tags$strong(" Note: "),
          "This bookmark saves your current view and settings. To save your complete project data, use the 'Save Project' button in the sidebar."
        ),

        tags$h5("What's saved in this bookmark:"),
        tags$ul(
          tags$li("Current tab/page location"),
          tags$li("User experience level"),
          tags$li("Language preference"),
          tags$li("Auto-save settings"),
          tags$li("Selected demonstration area and focal issue")
        )
      )
    ))
  })

  # Restore state from bookmark
  onRestore(function(state) {
    debug_log("Restoring app state...", "BOOKMARK")

    # Restore user level
    if (!is.null(state$values$user_level)) {
      user_level(state$values$user_level)
      debug_log(paste("Restored user level:", state$values$user_level), "BOOKMARK")
    }

    # Restore autosave setting
    if (!is.null(state$values$autosave_enabled)) {
      autosave_enabled(state$values$autosave_enabled)
      debug_log(paste("Restored autosave setting:", state$values$autosave_enabled), "BOOKMARK")
    }

    # Restore metadata if saved
    if (!is.null(state$values$metadata_da_site) || !is.null(state$values$metadata_focal_issue)) {
      data <- project_data()
      if (!is.null(state$values$metadata_da_site)) {
        data$data$metadata$da_site <- state$values$metadata_da_site
      }
      if (!is.null(state$values$metadata_focal_issue)) {
        data$data$metadata$focal_issue <- state$values$metadata_focal_issue
      }
      project_data(data)
      debug_log("Restored metadata", "BOOKMARK")
    }

    # Restore active tab
    if (!is.null(state$values$active_tab)) {
      updateTabItems(session, "sidebar_menu", state$values$active_tab)
      debug_log(paste("Restored active tab:", state$values$active_tab), "BOOKMARK")
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
