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
        tags$span(i18n$t("Language")),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          id = "open_language_modal",
          class = "action-button",
          icon("globe"),
          i18n$t("Change Language")
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
        tags$span(i18n$t("Settings")),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          id = "open_settings_modal",
          class = "action-button",
          icon("cog"),
          i18n$t("Application Settings")
        ),
        tags$a(
          href = "#",
          id = "open_user_level_modal",
          class = "action-button",
          icon("user-cog"),
          i18n$t("User Experience Level")
        ),
        tags$a(
          href = "#",
          id = "open_manuals_modal",
          class = "action-button",
          icon("download"),
          i18n$t("Download Manuals")
        ),
        tags$a(
          href = "#",
          id = "open_about_modal",
          class = "action-button",
          icon("info-circle"),
          i18n$t("App Info")
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
        tags$span(i18n$t("Help")),
        tags$span(class = "caret", style = "margin-left: 5px;")
      ),
      tags$div(
        class = "settings-dropdown-menu",
        tags$a(
          href = "#",
          onclick = "window.open('beginner_guide.html', '_blank'); return false;",
          icon("graduation-cap"),
          i18n$t("Beginner's Guide")
        ),
        tags$a(
          href = "#",
          onclick = "window.open('step_by_step_tutorial.html', '_blank'); return false;",
          icon("list-ol"),
          i18n$t("Step-by-Step Tutorial")
        ),
        tags$a(
          href = "#",
          onclick = "window.open('user_guide.html', '_blank'); return false;",
          icon("book"),
          i18n$t("Quick Reference")
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
        i18n$t("Bookmark"),
        style = "cursor: pointer;",
        title = i18n$t("Save current state as bookmark")
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
