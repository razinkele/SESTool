# functions/ui_header.R
# Dashboard header UI for the SES Tool
# Extracted from app.R for better maintainability

# ============================================================================
# HEADER CONSTRUCTION
# ============================================================================

#' Build Dashboard Header
#'
#' Creates the dashboard navbar with settings dropdown, help, bookmark, and user info.
#'
#' @param i18n shiny.i18n translator object
#' @return bs4DashNavbar object
build_dashboard_header <- function(i18n) {
  bs4DashNavbar(
    title = dashboardBrand(
      title = i18n$t("ui.header.brand_title"),
      color = "primary",
      href = "https://marinesabres.eu",
      image = "img/MSabres.png"
    ),
    skin = "dark",
    status = "primary",
    border = TRUE,
    fixed = FALSE,
    controlbarIcon = NULL,  # Hide controlbar toggle (no controlbar in this app)

    # Right-side UI elements
    rightUi = tagList(

      # Language selector dropdown
      tags$li(
        class = "dropdown settings-dropdown",
        tags$a(
          href = "#",
          id = "language_dropdown_toggle",
          class = "settings-dropdown-toggle",
          `aria-haspopup` = "true",
          `aria-expanded` = "false",
          `aria-label` = i18n$t("ui.header.language"),
          icon("globe"),
          tags$span(i18n$t("ui.header.language"), `data-i18n`="ui.header.language"),
          tags$span(class = "caret", style = "margin-left: 5px;")
        ),
        tags$div(
          class = "settings-dropdown-menu",
          tags$a(
            href = "#",
            id = "open_language_modal",
            class = "action-button",
            icon("globe"),
            tags$span(i18n$t("ui.header.change_language"), `data-i18n`="ui.header.change_language")
          )
        )
      ),

      # Settings dropdown (no About — About is a separate widget)
      tags$li(
        class = "dropdown settings-dropdown",
        tags$a(
          href = "#",
          id = "settings_dropdown_toggle",
          class = "settings-dropdown-toggle",
          `aria-haspopup` = "true",
          `aria-expanded` = "false",
          `aria-label` = i18n$t("ui.header.settings"),
          icon("cog"),
          tags$span(i18n$t("ui.header.settings"), `data-i18n`="ui.header.settings"),
          tags$span(class = "caret", style = "margin-left: 5px;")
        ),
        tags$div(
          class = "settings-dropdown-menu",
          tags$a(
            href = "#",
            id = "open_settings_modal",
            class = "action-button",
            icon("cog"),
            tags$span(i18n$t("ui.header.application_settings"), `data-i18n`="ui.header.application_settings")
          ),
          tags$a(
            href = "#",
            id = "open_user_level_modal",
            class = "action-button",
            icon("user-cog"),
            tags$span(i18n$t("ui.header.user_experience_level"), `data-i18n`="ui.header.user_experience_level")
          ),
          tags$a(
            href = "#",
            id = "open_manuals_modal",
            class = "action-button",
            icon("download"),
            tags$span(i18n$t("ui.header.download_manuals"), `data-i18n`="ui.header.download_manuals")
          ),
          tags$hr(style = "margin: 5px 0; border-color: #555;"),
          tags$a(
            href = "#",
            id = "clear_session_btn",
            class = "action-button",
            icon("trash-alt"),
            tags$span(i18n$t("ui.header.clear_session"), `data-i18n`="ui.header.clear_session"),
            style = "color: #dc3545;"
          )
        )
      ),

      # Bookmark button
      tags$li(
        class = "dropdown",
        tags$a(
          href = "#",
          id = "bookmark_btn",
          `aria-label` = i18n$t("ui.header.save_current_state_as_bookmark"),
          role = "button",
          icon("bookmark"),
          tags$span(i18n$t("ui.header.bookmark"), `data-i18n`="ui.header.bookmark"),
          style = "cursor: pointer;",
          title = i18n$t("ui.header.save_current_state_as_bookmark"),
          `data-i18n-title`="ui.header.save_current_state_as_bookmark"
        )
      ),

      # About button (standalone, extracted from Settings)
      tags$li(
        class = "dropdown",
        tags$a(
          href = "#",
          id = "open_about_modal",
          `aria-label` = i18n$t("ui.header.app_info"),
          role = "button",
          icon("info-circle"),
          tags$span(i18n$t("ui.header.app_info"), `data-i18n`="ui.header.app_info"),
          style = "cursor: pointer;",
          title = i18n$t("ui.header.app_info"),
          onclick = "Shiny.setInputValue('show_about_modal', Math.random()); return false;"
        )
      ),

      # Feedback button (bug reports & suggestions)
      tags$li(
        class = "dropdown",
        tags$a(
          href = "#",
          id = "open_feedback_modal",
          `aria-label` = i18n$t("ui.modals.feedback.button_label"),
          role = "button",
          icon("comment-dots"),
          tags$span(i18n$t("ui.modals.feedback.button_label"), `data-i18n`="ui.modals.feedback.button_label"),
          style = "cursor: pointer;",
          title = i18n$t("ui.modals.feedback.button_label"),
          onclick = "Shiny.setInputValue('show_feedback_modal', Math.random()); return false;"
        )
      ),

      # Help dropdown (rightmost, with KB References)
      tags$li(
        class = "dropdown settings-dropdown",
        tags$a(
          href = "#",
          id = "help_dropdown_toggle",
          class = "settings-dropdown-toggle",
          `aria-haspopup` = "true",
          `aria-expanded` = "false",
          `aria-label` = i18n$t("ui.header.help"),
          icon("question-circle"),
          tags$span(i18n$t("ui.header.help"), `data-i18n`="ui.header.help"),
          tags$span(class = "caret", style = "margin-left: 5px;")
        ),
        tags$div(
          class = "settings-dropdown-menu",
          tags$a(
            href = "#",
            onclick = "window.open('beginner_guide.html', '_blank'); return false;",
            icon("graduation-cap"),
            tags$span(i18n$t("ui.header.beginners_guide"), `data-i18n`="ui.header.beginners_guide")
          ),
          tags$a(
            href = "#",
            onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
            icon("list-ol"),
            tags$span(i18n$t("ui.header.step_by_step_tutorial"), `data-i18n`="ui.header.step_by_step_tutorial")
          ),
          tags$a(
            href = "#",
            onclick = "window.open('user_guide.html', '_blank'); return false;",
            icon("book"),
            tags$span(i18n$t("ui.header.quick_reference"), `data-i18n`="ui.header.quick_reference")
          ),
          tags$hr(style = "margin: 5px 0; border-color: #eee;"),
          tags$a(
            href = "#",
            id = "open_kb_references_modal",
            class = "action-button",
            icon("book-open"),
            tags$span(i18n$t("ui.header.kb_references"), `data-i18n`="ui.header.kb_references")
          )
        )
      ),

      # Pipeline status indicator (hidden by default)
      tags$li(
        class = "dropdown",
        hidden(
          div(
            id = "pipeline_status_indicator",
            class = "pipeline-status",
            style = "display: none;", # Initially hidden
            icon("cogs", class = "fa-spin"),
            tags$span(i18n$t("ui.header.processing"), style = "margin-left: 5px;")
          )
        )
      ),

      # User info
      tags$li(
        class = "dropdown",
        tags$a(
          href = "#",
          icon("user"),
          textOutput("user_info", inline = TRUE)
        )
      )
    ) # End rightUi tagList
  )
}
