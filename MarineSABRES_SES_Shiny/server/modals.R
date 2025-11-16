# server/modals.R
# Modal dialog handlers for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# LANGUAGE SETTINGS MODAL
# ============================================================================

#' Setup Language Settings Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param autosave_enabled reactiveVal for autosave setting
#' @param AVAILABLE_LANGUAGES List of available languages
setup_language_modal_handlers <- function(input, output, session, i18n, autosave_enabled, AVAILABLE_LANGUAGES) {

  # Show settings modal when button is clicked
  observeEvent(input$show_settings_modal, {
    current_lang <- if(!is.null(i18n$get_translation_language())) {
      i18n$get_translation_language()
    } else {
      "en"
    }

    showModal(modalDialog(
      title = tags$h3(icon("cog"), " Application Settings"),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("Cancel")),
        actionButton("apply_language_change", i18n$t("Apply Changes"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("globe"), " ", i18n$t("Interface Language")),
        tags$p(i18n$t("Select your preferred language for the application interface. Click 'Apply Changes' to reload the application with the new language.")),
        tags$br(),

        selectInput(
          "settings_language_selector",
          label = tags$strong("Language:"),
          choices = setNames(
            names(AVAILABLE_LANGUAGES),
            sapply(AVAILABLE_LANGUAGES, function(x) paste(x$flag, x$name))
          ),
          selected = current_lang,
          width = "100%"
        ),

        tags$hr(style = "margin: 30px 0;"),

        tags$h4(icon("save"), " ", i18n$t("Auto-Save Settings")),
        tags$p(i18n$t("Configure automatic saving behavior for the AI ISA Assistant module.")),
        tags$br(),

        shinyWidgets::switchInput(
          inputId = "autosave_enabled",
          label = tags$strong("Enable Auto-Save:"),
          value = autosave_enabled(),  # Load current value
          onLabel = "ON",
          offLabel = "OFF",
          onStatus = "success",
          offStatus = "danger",
          size = "default",
          width = "100%"
        ),

        tags$p(
          style = "margin-top: 10px; font-size: 13px; color: #666;",
          icon("info-circle"),
          " Auto-save automatically saves your work when the AI ISA Assistant completes generating the framework (Step 10). When disabled, you must manually save your work."
        ),

        tags$div(
          class = "alert alert-warning",
          style = "margin-top: 15px;",
          icon("exclamation-triangle"),
          tags$strong(" Default: OFF. "),
          "Auto-save is disabled by default to prevent accidental overwrites when loading templates or existing data."
        ),

        tags$div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          icon("info-circle"),
          tags$strong(" Note: "),
          "The application will reload to apply the language changes. Your current work will be preserved."
        )
      )
    ))
  })

  # Handle Apply button click in settings modal
  observeEvent(input$apply_language_change, {
    req(input$settings_language_selector)

    new_lang <- input$settings_language_selector

    # Update autosave setting
    if (!is.null(input$autosave_enabled)) {
      autosave_enabled(input$autosave_enabled)
      cat(sprintf("[SETTINGS] Auto-save %s\n", if(input$autosave_enabled) "enabled" else "disabled"))
    }

    # Get language name for notifications
    lang_name <- AVAILABLE_LANGUAGES[[new_lang]]$name

    # Log language change
    cat(paste0("[", Sys.time(), "] INFO: Language changed to: ", new_lang, "\n"))

    # Close the modal first
    removeModal()

    # Show loading overlay with translated message
    loading_messages <- list(
      en = "Changing Language",
      es = "Cambiando Idioma",
      fr = "Changement de Langue",
      de = "Sprache Ändern",
      lt = "Keičiama Kalba",
      pt = "Mudando Idioma",
      it = "Cambio Lingua"
    )

    session$sendCustomMessage(
      type = "showLanguageLoading",
      message = list(text = loading_messages[[new_lang]])
    )

    # Update the translator language
    shiny.i18n::update_lang(new_lang, session)
    i18n$set_translation_language(new_lang)

    # Note: Sidebar menu will update automatically via renderMenu()
    # Reload session immediately to update all UI elements
    session$reload()
  })
}

# ============================================================================
# USER LEVEL MODAL
# ============================================================================

#' Setup User Level Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param user_level reactiveVal for user experience level
#' @param i18n shiny.i18n translator object
setup_user_level_modal_handlers <- function(input, output, session, user_level, i18n) {

  # Show user level modal
  observeEvent(input$open_user_level_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("user-cog"), " ", i18n$t("User Experience Level")),
      size = "m",
      easyClose = FALSE,

      tags$div(
        style = "padding: 10px;",

        tags$p(
          style = "margin-bottom: 20px; font-size: 14px;",
          i18n$t("Select your experience level with marine ecosystem modeling:")
        ),

        # Single radio button group with all choices
        radioButtons(
          "user_level_selector",
          label = NULL,
          choices = setNames(
            c("beginner", "intermediate", "expert"),
            c(
              paste("\U0001F7E2", i18n$t("Beginner"), "-", i18n$t("Simplified interface for first-time users. Shows essential tools only.")),
              paste("\U0001F7E1", i18n$t("Intermediate"), "-", i18n$t("Standard interface for regular users. Shows most tools and features.")),
              paste("\U0001F534", i18n$t("Expert"), "-", i18n$t("Advanced interface showing all tools, technical terminology, and advanced options."))
            )
          ),
          selected = user_level(),
          width = "100%"
        ),

        tags$hr(),

        tags$p(
          style = "font-size: 12px; color: #666; margin-top: 15px;",
          icon("info-circle"), " ",
          i18n$t("The application will reload to apply the new user experience level.")
        )
      ),

      footer = tagList(
        actionButton("cancel_user_level", i18n$t("Cancel"), class = "btn-default"),
        actionButton("apply_user_level", i18n$t("Apply Changes"), class = "btn-primary", icon = icon("check"))
      )
    ))
  })

  # Apply user level changes
  observeEvent(input$apply_user_level, {
    req(input$user_level_selector)

    new_level <- input$user_level_selector

    # Log the change
    cat(sprintf("[USER-LEVEL] Changing from %s to %s\n", user_level(), new_level))

    # Save to localStorage and reload via JavaScript
    session$sendCustomMessage(
      type = "save_user_level",
      message = list(level = new_level)
    )

    removeModal()

    showNotification(
      i18n$t("Applying new user experience level..."),
      type = "message",
      duration = 2
    )
  })

  # Cancel user level changes
  observeEvent(input$cancel_user_level, {
    removeModal()
  })
}

# ============================================================================
# ABOUT MODAL
# ============================================================================

#' Setup About Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
setup_about_modal_handlers <- function(input, output, session, i18n) {

  # Show about modal when button is clicked
  observeEvent(input$show_about_modal, {
    # Read version info
    version_info <- jsonlite::fromJSON("VERSION_INFO.json")

    showModal(modalDialog(
      title = tags$h3(icon("info-circle"), " About MarineSABRES SES Toolbox"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("Close")),

      tags$div(
        style = "padding: 20px;",

        # Application Info
        tags$div(
          class = "well",
          tags$h4(icon("cube"), " Application Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Version:")),
              tags$td(
                tags$span(
                  style = "font-size: 18px; color: #3c8dbc; font-weight: bold;",
                  version_info$version
                ),
                tags$span(
                  class = "label label-success",
                  style = "margin-left: 10px;",
                  version_info$status
                )
              )
            ),
            tags$tr(
              tags$td(tags$strong("Release Name:")),
              tags$td(version_info$version_name)
            ),
            tags$tr(
              tags$td(tags$strong("Release Date:")),
              tags$td(version_info$release_date)
            ),
            tags$tr(
              tags$td(tags$strong("Release Type:")),
              tags$td(
                tags$span(
                  class = if(version_info$release_type == "major") "label label-danger"
                        else if(version_info$release_type == "minor") "label label-warning"
                        else "label label-info",
                  version_info$release_type
                )
              )
            )
          )
        ),

        # Features
        tags$div(
          class = "well",
          tags$h4(icon("star"), " Key Features"),
          tags$ul(
            lapply(version_info$features, function(feature) {
              tags$li(feature)
            })
          )
        ),

        # Technical Info
        tags$div(
          class = "well",
          tags$h4(icon("cogs"), " Technical Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Minimum R Version:")),
              tags$td(version_info$minimum_r_version)
            ),
            tags$tr(
              tags$td(tags$strong("Current R Version:")),
              tags$td(paste(R.version$major, R.version$minor, sep = "."))
            ),
            tags$tr(
              tags$td(tags$strong("Platform:")),
              tags$td(R.version$platform)
            ),
            tags$tr(
              tags$td(tags$strong("Git Branch:")),
              tags$td(version_info$build_info$git_branch)
            )
          )
        ),

        # Contributors
        tags$div(
          class = "well",
          tags$h4(icon("users"), " Contributors"),
          tags$ul(
            lapply(version_info$contributors, function(contributor) {
              tags$li(contributor)
            })
          )
        ),

        # Links
        tags$div(
          class = "alert alert-info",
          icon("book"),
          tags$strong(" Documentation: "),
          tags$a(
            href = "#",
            onclick = "window.open('user_guide.html', '_blank'); return false;",
            "User Guide",
            style = "margin-right: 15px;"
          ),
          tags$a(
            href = "#",
            onclick = sprintf("window.open('%s', '_blank'); return false;", version_info$changelog_url),
            "Changelog"
          )
        )
      )
    ))
  })
}
