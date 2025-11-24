# functions/ui_sidebar.R
# Sidebar menu generation for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# MENU TOOLTIP HELPER
# ============================================================================

#' Add tooltip to menu items via JavaScript
#' TEMPORARILY DISABLED TO DEBUG FREEZE ISSUE
#'
#' @param menu_item Shiny menu item
#' @param tooltip_text Tooltip text
#' @return Menu item (unchanged for now)
add_menu_tooltip <- function(menu_item, tooltip_text) {
  # Simply return the menu item without modification
  return(menu_item)
}

# ============================================================================
# USER LEVEL FILTER
# ============================================================================

#' Helper function to determine if menu item should be shown based on user level
#'
#' @param item_name Name of the menu item
#' @param user_level User experience level ("beginner", "intermediate", "expert")
#' @return TRUE if item should be shown, FALSE otherwise
should_show_menu_item <- function(item_name, user_level) {
  # Beginner: Only show essential items
  if (user_level == "beginner") {
    beginner_items <- c(
      "Getting Started",
      "Dashboard",
      "Create SES",  # Will show AI guided and Template based creation
      "SES Visualization",
      "Analysis Tools",  # Will show Loop Detection and Leverage Point Analysis only
      "Import Data",  # Import from Excel
      "Export Data",
      "Prepare Report"
    )
    return(item_name %in% beginner_items)
  }

  # Intermediate: Show everything (same as Expert for now)
  if (user_level == "intermediate") {
    return(TRUE)
  }

  # Expert: Show everything
  return(TRUE)
}

# ============================================================================
# SIDEBAR MENU GENERATION
# ============================================================================

#' Generate sidebar menu (dynamic, responds to language changes and user level)
#'
#' @param user_level User experience level ("beginner", "intermediate", "expert")
#' @param i18n shiny.i18n translator object
#' @return Shiny sidebarMenu object
generate_sidebar_menu <- function(user_level = "intermediate", i18n) {
  # Initialize menu items list
  menu_items <- list()

  # Getting Started (all levels)
  if (should_show_menu_item("Getting Started", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Getting Started"),
          tabName = "entry_point",
          icon = icon("compass")
        ),
        i18n$t("Guided entry point to find the right tools for your marine management needs")
      )
    ))
  }

  # Dashboard (all levels)
  if (should_show_menu_item("Dashboard", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Dashboard"),
          tabName = "dashboard",
          icon = icon("dashboard")
        ),
        i18n$t("Overview of your project status and key metrics")
      )
    ))
  }

  # PIMS Module (intermediate and expert only)
  if (should_show_menu_item("PIMS Module", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("PIMS Module"),
          tabName = "pims",
          icon = icon("project-diagram"),
          menuSubItem(i18n$t("Project Setup"), tabName = "pims_project"),
          menuSubItem(i18n$t("Stakeholders"), tabName = "pims_stakeholders"),
          menuSubItem(i18n$t("Resources & Risks"), tabName = "pims_resources"),
          menuSubItem(i18n$t("Data Management"), tabName = "pims_data"),
          menuSubItem(i18n$t("Evaluation"), tabName = "pims_evaluation")
        ),
        "Project Information Management System for planning and tracking"
      )
    ))
  }

  # Create SES (all levels, but beginner shows simplified menu)
  if (should_show_menu_item("Create SES", user_level)) {
    if (user_level == "beginner") {
      # Beginner: Show AI guided and Template based creation as direct links
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            i18n$t("AI guided SES creation"),
            tabName = "create_ses_ai",
            icon = icon("robot")
          ),
          "Guided question-based SES creation with AI assistance"
        ),
        add_menu_tooltip(
          menuItem(
            i18n$t("Template based SES creation"),
            tabName = "create_ses_template",
            icon = icon("file-alt")
          ),
          "Start from pre-built SES templates"
        )
      ))
    } else {
      # Intermediate/Expert: Show full Create SES menu with all methods
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            i18n$t("Create SES"),
            tabName = "create_ses",
            icon = icon("layer-group"),
            menuSubItem(i18n$t("Choose Method"), tabName = "create_ses_choose"),
            menuSubItem(i18n$t("Standard Entry"), tabName = "create_ses_standard"),
            menuSubItem(i18n$t("AI Assistant"), tabName = "create_ses_ai"),
            menuSubItem(i18n$t("Template-Based"), tabName = "create_ses_template")
          ),
          "Create your Social-Ecological System using structured methods"
        )
      ))
    }
  }

  # SES Visualization (all levels)
  if (should_show_menu_item("SES Visualization", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("SES Visualization"),
          tabName = "cld_viz",
          icon = icon("project-diagram")
        ),
        "Interactive visualization of your Social-Ecological System network"
      )
    ))
  }

  # Analysis Tools (all levels, but beginners see only key analyses)
  if (should_show_menu_item("Analysis Tools", user_level)) {
    if (user_level == "beginner") {
      # Beginner: Show only Loop Detection and Leverage Point Analysis
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            i18n$t("Analysis Tools"),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(i18n$t("Loop Detection"), tabName = "analysis_loops"),
            menuSubItem(i18n$t("Leverage Point Analysis"), tabName = "analysis_leverage")
          ),
          "Essential network analysis tools for understanding your SES"
        )
      ))
    } else {
      # Intermediate/Expert: Show all analysis tools
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            i18n$t("Analysis Tools"),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(i18n$t("Network Metrics"), tabName = "analysis_metrics"),
            menuSubItem(i18n$t("Loop Detection"), tabName = "analysis_loops"),
            menuSubItem(i18n$t("Leverage Point Analysis"), tabName = "analysis_leverage"),
            menuSubItem(i18n$t("BOT Analysis"), tabName = "analysis_bot"),
            menuSubItem(i18n$t("Simplification"), tabName = "analysis_simplify")
          ),
          "Advanced network analysis and metrics tools for your SES model"
        )
      ))
    }
  }

  # Response & Validation (intermediate and expert only)
  if (should_show_menu_item("Response & Validation", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Response & Validation"),
          tabName = "response",
          icon = icon("tasks"),
          menuSubItem(i18n$t("Response Measures"), tabName = "response_measures"),
          menuSubItem(i18n$t("Scenario Builder"), tabName = "response_scenarios"),
          menuSubItem(i18n$t("Validation"), tabName = "response_validation")
        ),
        "Design response measures, build scenarios, and validate your model"
      )
    ))
  }

  # Import Data (all levels)
  if (should_show_menu_item("Import Data", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Import Data"),
          tabName = "import_data",
          icon = icon("upload")
        ),
        "Import existing data from Excel files with Elements and Connections sheets"
      )
    ))
  }

  # Export Data (all levels)
  if (should_show_menu_item("Export Data", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Export Data"),
          tabName = "export",
          icon = icon("download")
        ),
        "Export data and generate comprehensive analysis reports"
      )
    ))
  }

  # Prepare Report (all levels - but requires analyses to be performed)
  if (should_show_menu_item("Prepare Report", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          i18n$t("Prepare Report"),
          tabName = "prepare_report",
          icon = icon("file-alt")
        ),
        "Generate comprehensive analysis report (requires loop and leverage analyses)"
      )
    ))
  }

  # Add horizontal rule and Quick Actions (all levels)
  menu_items <- c(menu_items, list(
    hr(),
    div(
      style = "padding: 15px 10px; text-align: center;",
      h5(i18n$t("Quick Actions"), style = "margin-bottom: 15px;"),
      div(
        style = "display: flex; flex-direction: column; align-items: center; gap: 10px;",
        actionButton(
          "save_project",
          i18n$t("Save Project"),
          icon = icon("save"),
          class = "btn-primary",
          style = "width: 90%; min-width: 180px;",
          title = i18n$t("Save your current project data, including all PIMS, ISA entries, and analysis results")
        ),
        actionButton(
          "load_project",
          i18n$t("Load Project"),
          icon = icon("folder-open"),
          class = "btn-secondary",
          style = "width: 90%; min-width: 180px;",
          title = i18n$t("Load a previously saved project")
        )
      ),
      bsTooltip(
        id = "save_project",
        title = i18n$t("Save your current project data, including all PIMS, ISA entries, and analysis results"),
        placement = "right",
        trigger = "hover"
      ),
      bsTooltip(
        id = "load_project",
        title = i18n$t("Load a previously saved project"),
        placement = "right",
        trigger = "hover"
      )
    )
  ))

  # Build and return the dynamic menu
  do.call(sidebarMenu, c(list(id = "sidebar_menu"), menu_items))
}
