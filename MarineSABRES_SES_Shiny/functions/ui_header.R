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

    # Settings dropdown (consolidates Language + User Level + About)
    tags$li(
      class = "dropdown settings-dropdown",
      tags$a(
        href = "#",
        id = "settings_dropdown_toggle",
        class = "settings-dropdown-toggle",
        icon("cog"),
        tags$span("Settings"),
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
          id = "open_about_modal",
          class = "action-button",
          icon("info-circle"),
          "About"
        )
      )
    ),

    # Help button (User Guide)
    tags$li(
      class = "dropdown",
      tags$a(
        href = "user_guide.html",
        target = "_blank",
        icon("book"),
        "About",
        style = "cursor: pointer;"
      )
    ),

    # Bookmark button
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        id = "bookmark_btn",
        icon("bookmark"),
        "Bookmark",
        style = "cursor: pointer;",
        title = "Save current state as bookmark"
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
