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
      title = tags$h3(icon("globe"), " ", i18n$t("ui.header.change_language")),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("apply_language_only", i18n$t("common.buttons.apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$p(
          style = "font-size: 15px; margin-bottom: 20px;",
          i18n$t("ui.modals.select_your_preferred_language_for_the_application_interface")
        ),

        selectInput(
          "language_selector",
          label = tags$strong(i18n$t("ui.modals.interface_language")),
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
          tags$strong(" ", i18n$t("common.labels.note"), " "),
          i18n$t("ui.modals.the_application_will_reload_to_apply_the_language_change")
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
      title = tags$h3(icon("cog"), " ", i18n$t("ui.header.application_settings")),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("apply_settings", i18n$t("common.buttons.apply"), class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("save"), " ", i18n$t("ui.modals.auto_save_settings")),
        tags$p(i18n$t("ui.modals.configure_automatic_saving_behavior_for_the_ai_isa_assistant_module")),
        tags$br(),

        shinyWidgets::switchInput(
          inputId = "autosave_enabled",
          label = tags$strong(i18n$t("ui.modals.enable_auto_save")),
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
          " ", i18n$t("ui.modals.auto_save_automatically_saves_your_work_when_the_a")
        ),

        tags$div(
          class = "alert alert-warning",
          style = "margin-top: 15px;",
          icon("exclamation-triangle"),
          tags$strong(" ", i18n$t("ui.modals.default_off"), " "),
          i18n$t("ui.modals.auto_save_is_disabled_by_default_to_prevent_accide")
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
      i18n$t("ui.modals.settings_updated_successfully"),
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
      title = tags$h3(icon("user-cog"), " ", i18n$t("ui.header.user_experience_level")),
      size = "m",
      easyClose = FALSE,

      tags$div(
        style = "padding: 10px;",

        tags$p(
          style = "margin-bottom: 20px; font-size: 14px;",
          i18n$t("ui.modals.select_your_experience_level_with_marine_ecosystem_modeling")
        ),

        # Single radio button group with all choices
        radioButtons(
          "user_level_selector",
          label = NULL,
          choices = setNames(
            c("beginner", "intermediate", "expert"),
            c(
              paste("\U0001F7E2", i18n$t("modules.ses.creation.beginner"), "-", i18n$t("ui.modals.simplified_interface_for_first_time_users_shows_essential_tools_only")),
              paste("\U0001F7E1", i18n$t("modules.ses.creation.intermediate"), "-", i18n$t("ui.modals.standard_interface_for_regular_users_shows_most_tools_and_features")),
              paste("\U0001F534", i18n$t("ui.modals.expert"), "-", i18n$t("ui.modals.advanced_interface_showing_all_tools_technical_ter"))
            )
          ),
          selected = user_level(),
          width = "100%"
        ),

        tags$hr(),

        tags$p(
          style = "font-size: 12px; color: #666; margin-top: 15px;",
          icon("info-circle"), " ",
          i18n$t("ui.modals.the_application_will_reload_to_apply_the_new_user_experience_level")
        )
      ),

      footer = tagList(
        actionButton("cancel_user_level", i18n$t("common.buttons.cancel"), class = "btn-default"),
        actionButton("apply_user_level", i18n$t("ui.modals.apply_changes"), class = "btn-primary", icon = icon("check"))
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
      i18n$t("ui.modals.applying_new_user_experience_level"),
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
      title = tags$h3(icon("download"), " ", i18n$t("ui.modals.download_user_manuals_guides")),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        # Beginner-Friendly Guides Section
        tags$div(
          class = "well",
          style = "background: #e8f5e9; border-left: 4px solid #4caf50;",
          tags$h4(
            icon("graduation-cap"),
            " ",
            i18n$t("ui.modals.beginner_friendly_guides"),
            tags$span(
              class = "label label-success",
              style = "margin-left: 10px;",
              i18n$t("ui.modals.recommended_for_new_users")
            )
          ),
          tags$p(i18n$t("ui.modals.simple_practical_guides_with_step_by_step_instruct")),
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
              tags$small(i18n$t("ui.modals.5_minute_introduction"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
              class = "btn btn-success btn-lg",
              style = "margin: 5px;",
              icon("list-ol"),
              " ",
              i18n$t("ui.header.step_by_step_tutorial"),
              tags$br(),
              tags$small(i18n$t("ui.modals.20_minute_hands_on_walkthrough"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Quick Reference
        tags$div(
          class = "well",
          tags$h4(icon("book"), " ", i18n$t("ui.modals.quick_reference_guide")),
          tags$p(i18n$t("ui.modals.compact_reference_for_experienced_users_who_need_a_quick_reminder")),
          tags$div(
            style = "margin-top: 15px;",
            tags$a(
              href = "#",
              onclick = "window.open('user_guide.html', '_blank'); return false;",
              class = "btn btn-primary btn-lg",
              style = "margin: 5px;",
              icon("book"),
              " ",
              i18n$t("ui.modals.quick_reference_guide"),
              tags$br(),
              tags$small(i18n$t("ui.modals.open_in_browser"))
            )
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Complete Manuals Section
        tags$div(
          class = "well",
          tags$h4(icon("file-alt"), " ", i18n$t("ui.modals.complete_user_manuals")),
          tags$p(i18n$t("ui.modals.comprehensive_documentation_with_detailed_explanat")),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("ui.modals.english_manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("ui.modals.html_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.view_online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_EN.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("ui.modals.pdf_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.downloadprint"))
            )
          ),

          tags$h5(style = "margin-top: 20px; color: #337ab7;",
                 icon("globe"),
                 " ",
                 i18n$t("ui.modals.french_manual")),
          tags$div(
            style = "margin: 10px 0;",
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.html', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-code"),
              " ",
              i18n$t("ui.modals.html_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.view_online"))
            ),
            tags$a(
              href = "#",
              onclick = "window.open('docs/MarineSABRES_User_Manual_FR.pdf', '_blank'); return false;",
              class = "btn btn-info",
              style = "margin: 5px;",
              icon("file-pdf"),
              " ",
              i18n$t("ui.modals.pdf_version"),
              tags$br(),
              tags$small(i18n$t("ui.modals.downloadprint"))
            )
          ),

          tags$div(
            class = "alert alert-info",
            style = "margin-top: 20px;",
            icon("info-circle"),
            " ",
            i18n$t("ui.modals.the_complete_manual_contains_approximately_75_page")
          )
        ),

        tags$hr(style = "margin: 25px 0;"),

        # Additional Resources
        tags$div(
          class = "well",
          tags$h4(icon("link"), " ", i18n$t("ui.modals.additional_resources")),
          tags$ul(
            tags$li(
              tags$strong(i18n$t("ui.modals.video_tutorials")),
              " ",
              i18n$t("ui.modals.coming_soon_check_back_later")
            ),
            tags$li(
              tags$strong(i18n$t("ui.modals.example_projects")),
              " ",
              i18n$t("ui.modals.available_in_the_template_library")
            ),
            tags$li(
              tags$strong(i18n$t("ui.modals.technical_documentation")),
              " ",
              i18n$t("ui.modals.for_developers_and_advanced_users")
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
      footer = modalButton(i18n$t("common.buttons.close")),

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
