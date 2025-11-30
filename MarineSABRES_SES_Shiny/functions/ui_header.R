# functions/ui_header.R
# Dashboard header UI for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# HEADER CONSTRUCTION
# ============================================================================

#' Build Dashboard Header
#'
#' Creates the dashboard header with settings dropdown, help, bookmark, and user info.
#'
#' @param i18n shiny.i18n translator object
#' @return dashboardHeader object
build_dashboard_header <- function(i18n) {
  dashboardHeader(
    title = "MarineSABRES SES Toolbox",
    titleWidth = 300,

    # Language selector dropdown
    tags$li(
      class = "dropdown settings-dropdown",
      tags$a(
        href = "#",
        id = "language_dropdown_toggle",
        class = "settings-dropdown-toggle",
        icon("globe"),
        tags$span(i18n$t("ui.header.language"), `data-i18n`="Language"),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          id = "open_language_modal",
          class = "action-button",
          icon("globe"),
          tags$span(i18n$t("ui.header.change_language"), `data-i18n`="Change Language")
        )
      )
    ),

    # Settings dropdown
    tags$li(
      class = "dropdown settings-dropdown",
      tags$a(
        href = "#",
        id = "settings_dropdown_toggle",
        class = "settings-dropdown-toggle",
        icon("cog"),
        tags$span(i18n$t("ui.header.settings"), `data-i18n`="Settings"),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          id = "open_settings_modal",
          class = "action-button",
          icon("cog"),
          tags$span(i18n$t("ui.header.application_settings"), `data-i18n`="Application Settings")
        ),
        tags$a(
          href = "#",
          id = "open_user_level_modal",
          class = "action-button",
          icon("user-cog"),
          tags$span(i18n$t("ui.header.user_experience_level"), `data-i18n`="User Experience Level")
        ),
        tags$a(
          href = "#",
          id = "open_manuals_modal",
          class = "action-button",
          icon("download"),
          tags$span(i18n$t("ui.header.download_manuals"), `data-i18n`="Download Manuals")
        ),
        tags$a(
          href = "#",
          id = "open_about_modal",
          class = "action-button",
          icon("info-circle"),
          tags$span(i18n$t("ui.header.app_info"), `data-i18n`="App Info")
        )
      )
    ),

    # Help button (User Guides)
    tags$li(
      class = "dropdown settings-dropdown",
      tags$a(
        href = "#",
        id = "help_dropdown_toggle",
        class = "settings-dropdown-toggle",
        icon("question-circle"),
        tags$span(i18n$t("ui.header.help"), `data-i18n`="Help"),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          onclick = "window.open('beginner_guide.html', '_blank'); return false;",
          icon("graduation-cap"),
          tags$span("Beginner's Guide", `data-i18n`="Beginner's Guide")
        ),
        tags$a(
          href = "#",
          onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
          icon("list-ol"),
          tags$span(i18n$t("ui.header.step_by_step_tutorial"), `data-i18n`="Step-by-Step Tutorial")
        ),
        tags$a(
          href = "#",
          onclick = "window.open('user_guide.html', '_blank'); return false;",
          icon("book"),
          tags$span(i18n$t("ui.header.quick_reference"), `data-i18n`="Quick Reference")
        )
      )
    ),

    # Bookmark button
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        id = "bookmark_btn",
        icon("bookmark"),
        tags$span(i18n$t("ui.header.bookmark"), `data-i18n`="Bookmark"),
        style = "cursor: pointer;",
        title = i18n$t("ui.header.save_current_state_as_bookmark"),
        `data-i18n-title`="Save current state as bookmark"
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
          tags$span("Processing...", style = "margin-left: 5px;")
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
  )
}
