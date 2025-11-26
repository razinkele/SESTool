# functions/ui_sidebar.R
# Sidebar menu generation for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# TRANSLATION FALLBACK HELPER
# ============================================================================

#' Safe translation with fallback
#'
#' Wraps safe_t(, i18n_obj = i18n) with error handling and fallback mechanism
#'
#' @param key Translation key (flat key or namespaced)
#' @param fallback Fallback text if translation fails (defaults to key)
#' @param i18n_obj The i18n translator object
#' @return Translated string or fallback
safe_t <- function(key, fallback = key, i18n_obj = NULL) {
  # If no i18n object provided, try to get from parent environment
  if (is.null(i18n_obj) && exists("i18n", envir = parent.frame())) {
    i18n_obj <- get("i18n", envir = parent.frame())
  }

  if (is.null(i18n_obj)) {
    warning(sprintf("[TRANSLATION] No i18n object available for key: %s", key))
    return(fallback)
  }

  tryCatch({
    result <- i18n_obj$t(key)

    # Check if translation actually worked
    if (is.null(result) || result == "" || result == key) {
      # Translation not found, return fallback
      return(fallback)
    }

    return(result)
  }, error = function(e) {
    warning(sprintf("[TRANSLATION ERROR] Key '%s': %s", key, e$message))
    return(fallback)
  })
}

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
          safe_t("Getting Started", i18n_obj = i18n),
          tabName = "entry_point",
          icon = icon("compass")
        ),
        safe_t("Guided entry point to find the right tools for your marine management needs", i18n_obj = i18n)
      )
    ))
  }

  # Dashboard (all levels)
  if (should_show_menu_item("Dashboard", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          safe_t("Dashboard", i18n_obj = i18n),
          tabName = "dashboard",
          icon = icon("dashboard")
        ),
        safe_t("Overview of your project status and key metrics", i18n_obj = i18n)
      )
    ))
  }

  # PIMS Module (intermediate and expert only)
  if (should_show_menu_item("PIMS Module", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          safe_t("PIMS Module", i18n_obj = i18n),
          tabName = "pims",
          icon = icon("project-diagram"),
          menuSubItem(safe_t("Project Setup", i18n_obj = i18n), tabName = "pims_project"),
          menuSubItem(safe_t("Stakeholders", i18n_obj = i18n), tabName = "pims_stakeholders"),
          menuSubItem(safe_t("Resources & Risks", i18n_obj = i18n), tabName = "pims_resources"),
          menuSubItem(safe_t("Data Management", i18n_obj = i18n), tabName = "pims_data"),
          menuSubItem(safe_t("Evaluation", i18n_obj = i18n), tabName = "pims_evaluation")
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
            safe_t("AI guided SES creation", i18n_obj = i18n),
            tabName = "create_ses_ai",
            icon = icon("robot")
          ),
          "Guided question-based SES creation with AI assistance"
        ),
        add_menu_tooltip(
          menuItem(
            safe_t("Template based SES creation", i18n_obj = i18n),
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
            safe_t("Create SES", i18n_obj = i18n),
            tabName = "create_ses",
            icon = icon("layer-group"),
            menuSubItem(safe_t("Choose Method", i18n_obj = i18n), tabName = "create_ses_choose"),
            menuSubItem(safe_t("Standard Entry", i18n_obj = i18n), tabName = "create_ses_standard"),
            menuSubItem(safe_t("AI Assistant", i18n_obj = i18n), tabName = "create_ses_ai"),
            menuSubItem(safe_t("Template-Based", i18n_obj = i18n), tabName = "create_ses_template")
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
          safe_t("SES Visualization", i18n_obj = i18n),
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
            safe_t("Analysis Tools", i18n_obj = i18n),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(safe_t("Loop Detection", i18n_obj = i18n), tabName = "analysis_loops"),
            menuSubItem(safe_t("Leverage Point Analysis", i18n_obj = i18n), tabName = "analysis_leverage")
          ),
          "Essential network analysis tools for understanding your SES"
        )
      ))
    } else {
      # Intermediate/Expert: Show all analysis tools
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            safe_t("Analysis Tools", i18n_obj = i18n),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(safe_t("Network Metrics", i18n_obj = i18n), tabName = "analysis_metrics"),
            menuSubItem(safe_t("Loop Detection", i18n_obj = i18n), tabName = "analysis_loops"),
            menuSubItem(safe_t("Leverage Point Analysis", i18n_obj = i18n), tabName = "analysis_leverage"),
            menuSubItem(safe_t("BOT Analysis", i18n_obj = i18n), tabName = "analysis_bot"),
            menuSubItem(safe_t("Simplification", i18n_obj = i18n), tabName = "analysis_simplify")
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
          safe_t("Response & Validation", i18n_obj = i18n),
          tabName = "response",
          icon = icon("tasks"),
          menuSubItem(safe_t("Response Measures", i18n_obj = i18n), tabName = "response_measures"),
          menuSubItem(safe_t("Scenario Builder", i18n_obj = i18n), tabName = "response_scenarios"),
          menuSubItem(safe_t("Validation", i18n_obj = i18n), tabName = "response_validation")
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
          safe_t("Import Data", i18n_obj = i18n),
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
          safe_t("Export Data", i18n_obj = i18n),
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
          safe_t("Prepare Report", i18n_obj = i18n),
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
      h5(safe_t("Quick Actions", i18n_obj = i18n), style = "margin-bottom: 15px;"),
      div(
        style = "display: flex; flex-direction: column; align-items: center; gap: 10px;",
        actionButton(
          "save_project",
          safe_t("Save Project", i18n_obj = i18n),
          icon = icon("save"),
          class = "btn-primary",
          style = "width: 90%; min-width: 180px;",
          title = safe_t("Save your current project data, including all PIMS, ISA entries, and analysis results", i18n_obj = i18n)
        ),
        actionButton(
          "load_project",
          safe_t("Load Project", i18n_obj = i18n),
          icon = icon("folder-open"),
          class = "btn-secondary",
          style = "width: 90%; min-width: 180px;",
          title = safe_t("Load a previously saved project", i18n_obj = i18n)
        )
      ),
      bsTooltip(
        id = "save_project",
        title = safe_t("Save your current project data, including all PIMS, ISA entries, and analysis results", i18n_obj = i18n),
        placement = "right",
        trigger = "hover"
      ),
      bsTooltip(
        id = "load_project",
        title = safe_t("Load a previously saved project", i18n_obj = i18n),
        placement = "right",
        trigger = "hover"
      )
    )
  ))

  # Build and return the dynamic menu
  do.call(sidebarMenu, c(list(id = "sidebar_menu"), menu_items))
}
