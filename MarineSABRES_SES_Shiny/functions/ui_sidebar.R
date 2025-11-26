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
          safe_t("ui.sidebar.getting_started", i18n_obj = i18n) i18n_obj = i18n),
          tabName = "entry_point",
          icon = icon("compass")
        ),
        safe_t("ui.sidebar.guided_entry_point_to_find_the_right_tools_for_you", i18n_obj = i18n) i18n_obj = i18n)
      )
    ))
  }

  # Dashboard (all levels)
  if (should_show_menu_item("Dashboard", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          safe_t("ui.sidebar.dashboard", i18n_obj = i18n) i18n_obj = i18n),
          tabName = "dashboard",
          icon = icon("dashboard")
        ),
        safe_t("ui.sidebar.overview_of_your_project_status_and_key_metrics", i18n_obj = i18n) i18n_obj = i18n)
      )
    ))
  }

  # PIMS Module (intermediate and expert only)
  if (should_show_menu_item("PIMS Module", user_level)) {
    menu_items <- c(menu_items, list(
      add_menu_tooltip(
        menuItem(
          safe_t("ui.sidebar.pims_module", i18n_obj = i18n) i18n_obj = i18n),
          tabName = "pims",
          icon = icon("project-diagram"),
          menuSubItem(safe_t("ui.sidebar.project_setup", i18n_obj = i18n) i18n_obj = i18n), tabName = "pims_project"),
          menuSubItem(safe_t("ui.sidebar.stakeholders", i18n_obj = i18n) i18n_obj = i18n), tabName = "pims_stakeholders"),
          menuSubItem(safe_t("ui.sidebar.resources_risks", i18n_obj = i18n) i18n_obj = i18n), tabName = "pims_resources"),
          menuSubItem(safe_t("modules.isa.data_entry.common.data_management", i18n_obj = i18n) i18n_obj = i18n), tabName = "pims_data"),
          menuSubItem(safe_t("ui.sidebar.evaluation", i18n_obj = i18n) i18n_obj = i18n), tabName = "pims_evaluation")
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
            safe_t("ui.sidebar.ai_guided_ses_creation", i18n_obj = i18n) i18n_obj = i18n),
            tabName = "create_ses_ai",
            icon = icon("robot")
          ),
          "Guided question-based SES creation with AI assistance"
        ),
        add_menu_tooltip(
          menuItem(
            safe_t("ui.sidebar.template_based_ses_creation", i18n_obj = i18n) i18n_obj = i18n),
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
            safe_t("ui.sidebar.create_ses", i18n_obj = i18n) i18n_obj = i18n),
            tabName = "create_ses",
            icon = icon("layer-group"),
            menuSubItem(safe_t("ui.sidebar.choose_method", i18n_obj = i18n) i18n_obj = i18n), tabName = "create_ses_choose"),
            menuSubItem(safe_t("ui.sidebar.standard_entry", i18n_obj = i18n) i18n_obj = i18n), tabName = "create_ses_standard"),
            menuSubItem(safe_t("ui.sidebar.ai_assistant", i18n_obj = i18n) i18n_obj = i18n), tabName = "create_ses_ai"),
            menuSubItem(safe_t("ui.sidebar.template_based", i18n_obj = i18n) i18n_obj = i18n), tabName = "create_ses_template")
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
          safe_t("ui.sidebar.ses_visualization", i18n_obj = i18n) i18n_obj = i18n),
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
            safe_t("ui.sidebar.analysis_tools", i18n_obj = i18n) i18n_obj = i18n),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(safe_t("ui.sidebar.loop_detection", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_loops"),
            menuSubItem(safe_t("ui.sidebar.leverage_point_analysis", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_leverage")
          ),
          "Essential network analysis tools for understanding your SES"
        )
      ))
    } else {
      # Intermediate/Expert: Show all analysis tools
      menu_items <- c(menu_items, list(
        add_menu_tooltip(
          menuItem(
            safe_t("ui.sidebar.analysis_tools", i18n_obj = i18n) i18n_obj = i18n),
            tabName = "analysis",
            icon = icon("chart-line"),
            menuSubItem(safe_t("ui.sidebar.network_metrics", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_metrics"),
            menuSubItem(safe_t("ui.sidebar.loop_detection", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_loops"),
            menuSubItem(safe_t("ui.sidebar.leverage_point_analysis", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_leverage"),
            menuSubItem(safe_t("ui.sidebar.bot_analysis", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_bot"),
            menuSubItem(safe_t("ui.sidebar.simplification", i18n_obj = i18n) i18n_obj = i18n), tabName = "analysis_simplify")
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
          safe_t("ui.sidebar.response_validation", i18n_obj = i18n) i18n_obj = i18n),
          tabName = "response",
          icon = icon("tasks"),
          menuSubItem(safe_t("ui.sidebar.response_measures", i18n_obj = i18n) i18n_obj = i18n), tabName = "response_measures"),
          menuSubItem(safe_t("ui.sidebar.scenario_builder", i18n_obj = i18n) i18n_obj = i18n), tabName = "response_scenarios"),
          menuSubItem(safe_t("ui.sidebar.validation", i18n_obj = i18n) i18n_obj = i18n), tabName = "response_validation")
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
          safe_t("modules.isa.data_entry.common.import_data", i18n_obj = i18n) i18n_obj = i18n),
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
          safe_t("modules.isa.data_entry.common.export_data", i18n_obj = i18n) i18n_obj = i18n),
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
          safe_t("ui.sidebar.prepare_report", i18n_obj = i18n) i18n_obj = i18n),
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
      h5(safe_t("ui.sidebar.quick_actions", i18n_obj = i18n) i18n_obj = i18n), style = "margin-bottom: 15px;"),
      div(
        style = "display: flex; flex-direction: column; align-items: center; gap: 10px;",
        actionButton(
          "save_project",
          safe_t("common.buttons.save_project", i18n_obj = i18n) i18n_obj = i18n),
          icon = icon("save"),
          class = "btn-primary",
          style = "width: 90%; min-width: 180px;",
          title = safe_t("ui.sidebar.save_your_curr_proj_dat_incl_all_pims_isa_ent_and_", i18n_obj = i18n) i18n_obj = i18n)
        ),
        actionButton(
          "load_project",
          safe_t("common.buttons.load_project", i18n_obj = i18n) i18n_obj = i18n),
          icon = icon("folder-open"),
          class = "btn-secondary",
          style = "width: 90%; min-width: 180px;",
          title = safe_t("ui.sidebar.load_a_previously_saved_project", i18n_obj = i18n) i18n_obj = i18n)
        )
      ),
      bsTooltip(
        id = "save_project",
        title = safe_t("ui.sidebar.save_your_curr_proj_dat_incl_all_pims_isa_ent_and_", i18n_obj = i18n) i18n_obj = i18n),
        placement = "right",
        trigger = "hover"
      ),
      bsTooltip(
        id = "load_project",
        title = safe_t("ui.sidebar.load_a_previously_saved_project", i18n_obj = i18n) i18n_obj = i18n),
        placement = "right",
        trigger = "hover"
      )
    )
  ))

  # Build and return the dynamic menu
  do.call(sidebarMenu, c(list(id = "sidebar_menu"), menu_items))
}
