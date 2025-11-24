# server/modals.R
# Modal dialog handlers for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# LANGUAGE MODAL (Simplified)
# ============================================================================

#' Setup Language Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param AVAILABLE_LANGUAGES List of available languages
setup_language_modal_only <- function(input, output, session, i18n, AVAILABLE_LANGUAGES) {

  # Show language modal when button is clicked
  observeEvent(input$open_language_modal, {
    current_lang <- if(!is.null(i18n$get_translation_language())) {
      i18n$get_translation_language()
    } else {
      "en"
    }

    showModal(modalDialog(
      title = tags$h3(icon("globe"), " ", i18n$t("Change Language")),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("Cancel")),
        actionButton("apply_language_only", i18n$t("Apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$p(
          style = "font-size: 15px; margin-bottom: 20px;",
          i18n$t("Select your preferred language for the application interface.")
        ),

        selectInput(
          "language_selector",
          label = tags$strong(i18n$t("Interface Language:")),
          choices = setNames(
            names(AVAILABLE_LANGUAGES),
            sapply(AVAILABLE_LANGUAGES, function(x) paste(x$flag, x$name))
          ),
          selected = current_lang,
          width = "100%"
        ),

        tags$div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          icon("info-circle"),
          tags$strong(" ", i18n$t("Note:"), " "),
          i18n$t("The application will reload to apply the language change.")
        )
      )
    ))
  })

  # Handle Apply button click in language modal
  observeEvent(input$apply_language_only, {
    req(input$language_selector)

    new_lang <- input$language_selector

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

    # Save language to localStorage and reload with URL parameter
    # This ensures the language persists across reloads
    session$sendCustomMessage(type = "saveLanguageAndReload", message = new_lang)
  })
}

# ============================================================================
# SETTINGS MODAL (Auto-Save Only)
# ============================================================================

#' Setup Settings Modal Handlers (Without Language)
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param autosave_enabled reactiveVal for autosave setting
setup_settings_modal_handlers <- function(input, output, session, i18n, autosave_enabled) {

  # Show settings modal when button is clicked
  observeEvent(input$open_settings_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("cog"), " ", i18n$t("Application Settings")),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("Cancel")),
        actionButton("apply_settings", i18n$t("Apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("save"), " ", i18n$t("Auto-Save Settings")),
        tags$p(i18n$t("Configure automatic saving behavior for the AI ISA Assistant module.")),
        tags$br(),

        shinyWidgets::switchInput(
          inputId = "autosave_enabled",
          label = tags$strong(i18n$t("Enable Auto-Save:")),
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
          " ", i18n$t("Auto-save automatically saves your work when the AI ISA Assistant completes generating the framework (Step 10). When disabled, you must manually save your work.")
        ),

        tags$div(
          class = "alert alert-warning",
          style = "margin-top: 15px;",
          icon("exclamation-triangle"),
          tags$strong(" ", i18n$t("Default: OFF."), " "),
          i18n$t("Auto-save is disabled by default to prevent accidental overwrites when loading templates or existing data.")
        )
      )
    ))
  })

  # Handle Apply button click in settings modal
  observeEvent(input$apply_settings, {
    # Update autosave setting
    if (!is.null(input$autosave_enabled)) {
      autosave_enabled(input$autosave_enabled)
      cat(sprintf("[SETTINGS] Auto-save %s\n", if(input$autosave_enabled) "enabled" else "disabled"))
    }

    removeModal()

    showNotification(
      i18n$t("Settings updated successfully"),
      type = "message",
      duration = 2
    )
  })
}

# ============================================================================
# LEGACY: Combined Language/Settings Modal (Keep for compatibility)
# ============================================================================

#' Setup Language Settings Modal Handlers (Legacy)
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
#' @param autosave_enabled reactiveVal for autosave setting
#' @param AVAILABLE_LANGUAGES List of available languages
setup_language_modal_handlers <- function(input, output, session, i18n, autosave_enabled, AVAILABLE_LANGUAGES) {
  # Call the new separate handlers
  setup_language_modal_only(input, output, session, i18n, AVAILABLE_LANGUAGES)
  setup_settings_modal_handlers(input, output, session, i18n, autosave_enabled)
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
# DOWNLOAD MANUALS MODAL
# ============================================================================

#' Setup Download Manuals Modal Handlers
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param i18n shiny.i18n translator object
setup_manuals_modal_handlers <- function(input, output, session, i18n) {

  # Show manuals modal when button is clicked
  observeEvent(input$open_manuals_modal, {
    showModal(modalDialog(
      title = tags$h3(icon("download"), " ", i18n$t("Download User Manuals & Guides")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("Close")),

      tags$div(
        style = "padding: 20px;",

        # Beginner-Friendly Guides Section
        tags$div(
          class = "well",
          style = "background: #e8f5e9; border-left: 4px solid #4caf50;",
          tags$h4(
            icon("graduation-cap"),
            " ",
            i18n$t("Beginner-Friendly Guides"),
            tags$span(
              class = "label label-success",
              style = "margin-left: 10px;",
              i18n$t("Recommended for New Users")
            )
          ),
          tags$p(i18n$t("Simple, practical guides with step-by-step instructions and no technical jargon.")),
          tags$div(
            style = "margin-top: 15px;",
            tags$a(
              href = "#",
              onclick = "window.open('beginner_guide.html', '_blank'); return false;",
              class = "btn btn-success btn-lg",
              style = "margin: 5px;",
              icon("graduation-cap"),
              " ",
              i18n$t("Beginner's Quick Start"),
              tags$br(),
              tags$small(i18n$t("5-minute introduction"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
              class = "btn btn-success btn-lg",
              style = "margin: 5px;",
              icon("list-ol"),
              " ",
              i18n$t("Step-by-Step Tutorial"),
              tags$br(),
              tags$small(i18n$t("20-minute hands-on walkthrough"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Quick Reference
        tags$div(
          class = "well",
          tags$h4(icon("book"), " ", i18n$t("Quick Reference Guide")),
          tags$p(i18n$t("Compact reference for experienced users who need a quick reminder.")),
          tags$div(
            style = "margin-top: 15px;",
            tags$a(
              href = "#",
              onclick = "window.open('user_guide.html', '_blank'); return false;",
              class = "btn btn-primary btn-lg",
              style = "margin: 5px;",
              icon("book"),
              " ",
              i18n$t("Quick Reference Guide"),
              tags$br(),
              tags$small(i18n$t("Open in browser"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Complete Manuals Section
        tags$div(
          class = "well",
          tags$h4(icon("file-alt"), " ", i18n$t("Complete User Manuals")),
          tags$p(i18n$t("Comprehensive documentation with detailed explanations, technical details, and advanced features.")),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("English Manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("HTML Version"),
              tags$br(),
              tags$small(i18n$t("View online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("PDF Version"),
              tags$br(),
              tags$small(i18n$t("Download/Print"))
            )
          ),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("French Manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("HTML Version"),
              tags$br(),
              tags$small(i18n$t("View online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("PDF Version"),
              tags$br(),
              tags$small(i18n$t("Download/Print"))
            )
          ),

          tags$div(
            class = "alert alert-info",
            style = "margin-top: 20px;",
            icon("info-circle"),
            " ",
            i18n$t("The complete manual contains approximately 75 pages of detailed documentation covering all features and workflows.")
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Additional Resources
        tags$div(
          class = "well",
          tags$h4(icon("link"), " ", i18n$t("Additional Resources")),
          tags$ul(
            tags$li(
              tags$strong(i18n$t("Video Tutorials:")),
              " ",
              i18n$t("Coming soon - check back later")
            ),
            tags$li(
              tags$strong(i18n$t("Example Projects:")),
              " ",
              i18n$t("Available in the template library")
            ),
            tags$li(
              tags$strong(i18n$t("Technical Documentation:")),
              " ",
              i18n$t("For developers and advanced users")
            )
          )
        )
      )
    ))
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
            "Quick Guide",
            style = "margin-right: 15px;"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
            "📘 Manual (EN HTML)",
            style = "margin-right: 15px;",
            title = "Comprehensive 75-page English manual - HTML version"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
            "📕 Manual (EN PDF)",
            style = "margin-right: 15px;",
            title = "Comprehensive 75-page English manual - PDF version"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
            "📗 Manuel (FR HTML)",
            style = "margin-right: 15px;",
            title = "Manuel français complet de 75 pages - version HTML"
          ),
          tags$a(
            href = "#",
            onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
            "📙 Manuel (FR PDF)",
            style = "margin-right: 15px;",
            title = "Manuel français complet de 75 pages - version PDF"
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
