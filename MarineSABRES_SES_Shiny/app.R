# app.R
# Main application file for MarineSABRES SES Shiny Application
  
# ============================================================================
# FIX: Disable devmode to prevent shiny.i18n JavaScript double-loading
# ============================================================================
options(shiny.minified = TRUE)
options(shiny.autoreload = FALSE)

# ============================================================================
# LOAD GLOBAL ENVIRONMENT
# ============================================================================

# Note: Global environment contains packages, constants, and shared utilities
source("global.R", local = FALSE)

# ============================================================================
# REGISTER RESOURCE PATHS
# ============================================================================

# Make docs directory accessible for serving user manuals (only if it exists)
if (dir.exists("docs")) {
  addResourcePath("docs", "docs")
}

# ============================================================================
# LOAD HELPER FUNCTIONS (with error handling)
# ============================================================================

# Note: These functions define UI and server components, must be globally available
# Critical files - app cannot start without these
critical_sources <- c(
  "functions/report_generation.R",
  "functions/ui_header.R",
  "functions/ui_sidebar.R",
  "server/modals.R",
  "server/dashboard.R",
  "server/project_io.R",
  "server/export_handlers.R",
  "server/bookmarking.R"
)

source_load_errors <- list()
for (source_file in critical_sources) {
  tryCatch({
    if (!file.exists(source_file)) {
      stop(sprintf("Critical source file not found: %s", source_file))
    }
    source(source_file, local = FALSE)
  }, error = function(e) {
    file_name <- basename(source_file)
    error_msg <- sprintf("[SOURCE_LOAD] Failed to load %s: %s", file_name, e$message)
    debug_log(error_msg, "SOURCE_LOAD")
    source_load_errors[[file_name]] <<- e$message
  })
}

# Critical source failures should stop the app
if (length(source_load_errors) > 0) {
  stop(sprintf(
    "CRITICAL: Failed to load %d essential source file(s): %s. Application cannot start.",
    length(source_load_errors),
    paste(names(source_load_errors), collapse = ", ")
  ))
}

# ============================================================================
# SOURCE MODULES (with error handling)
# ============================================================================

# Define module files for loading with error context
module_files <- c(
  "modules/entry_point_module.R",        # Entry Point guidance system
  "modules/create_ses_module.R",         # Consolidated Create SES module
  "modules/template_ses_module.R",       # Template-based SES creation
  "modules/ai_isa_assistant_module.R",   # AI-Assisted SES Creation
  "modules/import_data_module.R",        # Import Data from Excel
  "modules/ses_models_module.R",         # Load Pre-built SES Models
  "modules/isa_data_entry_module.R",     # Standard ISA Data Entry
  "modules/pims_module.R",               # PIMS Project module
  "modules/pims_stakeholder_module.R",   # PIMS Stakeholder module
  "modules/cld_visualization_module.R",  # CLD Visualization
  "modules/analysis_loops.R",            # Loop Detection Analysis
  "modules/analysis_metrics.R",          # Network Metrics Analysis
  "modules/analysis_bot.R",              # BOT (Behaviour Over Time) Analysis
  "modules/analysis_simplify.R",         # Network Simplification Tools
  "modules/analysis_leverage.R",         # Leverage Point Analysis
  "modules/response_module.R",           # Response measures (includes response_validation_server())
  "modules/scenario_builder_module.R",   # Scenario Builder
  "modules/prepare_report_module.R",     # Report preparation (comprehensive)
  "modules/export_reports_module.R",     # Export & Reports (simple)
  "modules/local_storage_module.R",      # Local storage for saving to user's computer
  "modules/analysis_boolean.R",          # Boolean Network & Laplacian Stability (DTU)
  "modules/analysis_simulation.R",       # Dynamic Simulation & State-Shift (DTU)
  "modules/analysis_intervention.R"      # Intervention Simulation (DTU)
)

# Load all modules with error handling
module_load_errors <- list()
for (module_file in module_files) {
  tryCatch({
    if (!file.exists(module_file)) {
      stop(sprintf("Module file not found: %s", module_file))
    }
    source(module_file, local = TRUE)
  }, error = function(e) {
    module_name <- basename(module_file)
    error_msg <- sprintf("[MODULE_LOAD] Failed to load %s: %s", module_name, e$message)
    debug_log(error_msg, "MODULE_LOAD")
    module_load_errors[[module_name]] <<- e$message
  })
}

# Report any module loading failures
if (length(module_load_errors) > 0) {
  warning(sprintf(
    "Failed to load %d module(s): %s. Application may have reduced functionality.",
    length(module_load_errors),
    paste(names(module_load_errors), collapse = ", ")
  ))
}

# NOTE: response_validation_server() is defined in response_module.R, not a separate file

# ============================================================================
# UI
# ============================================================================

# Note: Using explicit bs4Dash naming convention (bs4DashPage, bs4DashSidebar, etc.)
# rather than aliases (dashboardPage, dashboardSidebar) for clarity and to avoid
# confusion with legacy shinydashboard package. Both are valid in bs4Dash 2.0+.

ui <- bs4DashPage(
  # Page title (displayed in browser tab)
  title = i18n$t("ui.header.page_title"),

  # Enable scroll-to-top button (appears bottom-right)
  scrollToTop = TRUE,

  # Preloader - Custom CSS-based loading screen
  preloader = list(
    html = tagList(
      tags$div(
        style = "display: flex; flex-direction: column; align-items: center; justify-content: center;",
        # Animated spinner
        tags$div(
          class = "spinner",
          style = "
            width: 60px;
            height: 60px;
            border: 6px solid rgba(52, 152, 219, 0.2);
            border-top-color: #3498db;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 25px;
          "
        ),
        # Logo/Icon
        tags$div(
          style = "font-size: 48px; color: #3498db; margin-bottom: 15px;",
          icon("water")
        ),
        # Loading text
        tags$div(
          style = "font-size: 22px; font-weight: 600; color: #2c3e50; margin-bottom: 8px;",
          i18n$t("ui.header.preloader_title")
        ),
        tags$div(
          style = "font-size: 14px; color: #7f8c8d;",
          i18n$t("ui.header.preloader_subtitle")
        ),
        # CSS animation
        tags$style(HTML("
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        "))
      )
    ),
    color = "rgba(255, 255, 255, 0.95)"  # Semi-transparent white background
  ),

  # ========== HEADER ==========
  header = build_dashboard_header(i18n),  # Note: bs4DashPage uses 'header' not 'navbar'

  # ========== SIDEBAR ==========
  sidebar = bs4DashSidebar(
    id = "sidebar",          # ID for programmatic access
    skin = "light",
    status = "primary",
    elevation = 3,
    width = UI_SIDEBAR_WIDTH,
    collapsed = FALSE,       # Start expanded to show menu descriptions
    minified = TRUE,         # Keep icons visible when collapsed
    expandOnHover = FALSE,   # IMPORTANT: Disable auto-expand on hover to prevent overlap
    fixed = TRUE,

    # Dynamic sidebar menu that updates when language changes
    sidebarMenuOutput("dynamic_sidebar")
  ),

  # ========== BODY ==========
  body = bs4DashBody(

    # Enable shiny.i18n automatic language detection and reactive translations
    # Note: Must use the underlying translator object, not the wrapper
    shiny.i18n::usei18n(i18n$translator),

    # Custom CSS and JavaScript
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "bs4dash-custom.css"),  # bs4Dash custom theme
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),  # Module-specific styles
      tags$link(rel = "stylesheet", type = "text/css", href = "isa-forms.css"),  # ISA form styles
      tags$link(rel = "stylesheet", type = "text/css", href = "workflow-stepper.css"),  # Workflow stepper
      tags$script(src = "custom.js"),

      tags$style(HTML("
        /* Persistent loading overlay */
        #language-loading-overlay { 
          display: none;
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background-color: rgba(255, 255, 255, 0.95);
          z-index: 99999;
          justify-content: center;
          align-items: center;
          flex-direction: column;
        }
        #language-loading-overlay.active {
          display: flex !important;
        }
        .loading-spinner {
          font-size: 48px;
          color: #3c8dbc;
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .loading-message {
          margin-top: 20px;
          font-size: 24px;
          color: #3c8dbc;
          font-weight: bold;
        }
        .loading-submessage {
          margin-top: 10px;
          font-size: 14px;
          color: #666;
        }
      "))
    ),

    # Enable shinyjs
    useShinyjs(),

    # User level script (for localStorage)
    uiOutput("user_level_script"),

    # Auto-save indicator (fixed position overlay)
    auto_save_indicator_ui("auto_save"),

    # Local storage JavaScript handlers (for File System Access API)
    local_storage_ui("local_storage", i18n),

    # Tutorial system (contextual help overlays)
    tutorial_ui(),

    # Workflow stepper bar (beginner guidance)
    workflow_stepper_ui("workflow_stepper"),

    bs4TabItems(

      # ==================== ENTRY POINT (GETTING STARTED) ====================
      bs4TabItem(tabName = "entry_point", entry_point_ui("entry_pt", i18n)),

      # ==================== DASHBOARD ====================
      bs4TabItem(
        tabName = "dashboard",

        fluidRow(
          column(12,
            uiOutput("dashboard_header")
          )
        ),

        fluidRow(
          # Summary boxes
          valueBoxOutput("total_elements_box", width = UI_BOX_WIDTH_QUARTER),
          valueBoxOutput("total_connections_box", width = UI_BOX_WIDTH_QUARTER),
          valueBoxOutput("loops_detected_box", width = UI_BOX_WIDTH_QUARTER),
          valueBoxOutput("completion_box", width = UI_BOX_WIDTH_QUARTER)
        ),

        fluidRow(
          # Project overview
          bs4Card(
            id = "project_overview_card",
            title = i18n$t("ui.dashboard.project_overview"),
            status = "primary",
            solidHeader = TRUE,
            width = UI_BOX_WIDTH_HALF,
            height = UI_BOX_HEIGHT_DEFAULT,
            tags$div(
              style = "overflow-y: auto; max-height: 330px; padding: 5px;",
              uiOutput("project_overview_ui")
            )
          ),

          # Status summary
          bs4Card(
            id = "status_summary_card",
            title = i18n$t("ui.dashboard.status_summary"),
            status = "success",
            solidHeader = TRUE,
            width = UI_BOX_WIDTH_HALF,
            height = UI_BOX_HEIGHT_DEFAULT,

            # Project status indicators
            tags$div(
              style = "overflow-y: auto; max-height: 330px; padding: 5px;",

              # ISA Data Status
              tags$div(
                style = "margin-bottom: 10px; padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("database"), " ", i18n$t("ui.dashboard.isa_data_status")),
                uiOutput("status_isa_elements"),
                uiOutput("status_isa_connections")
              ),

              # Network Status
              tags$div(
                style = "margin-bottom: 10px; padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("project-diagram"), " ", i18n$t("ui.dashboard.network_status")),
                uiOutput("status_cld_nodes"),
                uiOutput("status_cld_edges")
              ),

              # Analysis Status
              tags$div(
                style = "padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("chart-line"), " ", i18n$t("ui.dashboard.analysis_status")),
                uiOutput("status_analysis_complete")
              )
            )
          )
        ),

        # Project History Timeline
        fluidRow(
          bs4Card(
            id = "project_timeline_card",
            title = tagList(icon("history"), " ", i18n$t("ui.dashboard.project_history")),
            status = "primary",
            solidHeader = TRUE,
            width = UI_BOX_WIDTH_FULL,
            collapsible = TRUE,
            collapsed = TRUE,

            # Timeline output (uses Shiny's built-in loading indicator)
            uiOutput("dashboard_timeline")
          )
        )
      ),

      # ==================== PIMS MODULE ====================
      bs4TabItem(tabName = "pims_project", pims_project_ui("pims_proj", i18n)),
      bs4TabItem(tabName = "pims_stakeholders", pims_stakeholder_ui("pims_stake", i18n)),
      bs4TabItem(tabName = "pims_resources", pims_resources_ui("pims_res", i18n)),
      bs4TabItem(tabName = "pims_data", pims_data_ui("pims_dm", i18n)),
      bs4TabItem(tabName = "pims_evaluation", pims_evaluation_ui("pims_eval", i18n)),

      # ==================== CREATE SES ====================
      # Choose Method
      bs4TabItem(tabName = "create_ses_choose", create_ses_ui("create_ses_main", i18n)),

      # Standard Entry
      bs4TabItem(tabName = "create_ses_standard", isa_data_entry_ui("isa_module")),

      # AI Assistant
      bs4TabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod", i18n)),

      # Template-Based
      bs4TabItem(tabName = "create_ses_template", template_ses_ui("template_ses", i18n)),

      # ==================== GRAPHICAL SES CREATOR ====================
      # AI-powered step-by-step network building with context wizard
      bs4TabItem(tabName = "graphical_ses_creator",
        graphical_ses_creator_ui("graphical_ses_mod", i18n)),

      # ==================== CLD VISUALIZATION ====================
      bs4TabItem(tabName = "cld_viz", cld_viz_ui("cld_visual", i18n)),
      
      # ==================== ANALYSIS ====================
      bs4TabItem(tabName = "analysis_metrics", analysis_metrics_ui("analysis_met", i18n)),
      bs4TabItem(tabName = "analysis_loops", analysis_loops_ui("analysis_loop", i18n)),
      bs4TabItem(tabName = "analysis_leverage", analysis_leverage_ui("analysis_lev", i18n)),
      bs4TabItem(tabName = "analysis_bot", analysis_bot_ui("analysis_b", i18n)),
      bs4TabItem(tabName = "analysis_simplify", analysis_simplify_ui("analysis_simp", i18n)),
      bs4TabItem(tabName = "analysis_boolean", analysis_boolean_ui("analysis_bool", i18n)),
      bs4TabItem(tabName = "analysis_simulation", analysis_simulation_ui("analysis_sim", i18n)),
      bs4TabItem(tabName = "analysis_intervention", analysis_intervention_ui("analysis_intv", i18n)),

      # ==================== RESPONSE & VALIDATION ====================
      bs4TabItem(tabName = "response_measures", response_measures_ui("resp_meas", i18n)),
      bs4TabItem(tabName = "response_scenarios", scenario_builder_ui("scenario_builder", i18n)),
      bs4TabItem(tabName = "response_validation", response_validation_ui("resp_val", i18n)),

      # ==================== IMPORT DATA ====================
      bs4TabItem(tabName = "import_data", import_data_ui("import_data_mod", i18n)),

      # ==================== SES MODELS (Load Pre-built) ====================
      bs4TabItem(tabName = "ses_models", ses_models_ui("ses_models_mod", i18n)),

      # ==================== EXPORT ====================
      bs4TabItem(
        tabName = "export",
        export_reports_ui("export_reports_mod", i18n)
      ),

      # ==================== PREPARE REPORT ====================
      bs4TabItem(tabName = "prepare_report", prepare_report_ui("prep_report", i18n))
    )
  ),

  # ========== CONTROLBAR - REMOVED ==========
  # Controlbar removed - settings moved to main settings modal
  # Quick actions (Save/Load) available in sidebar
  controlbar = NULL,

  # ========== FOOTER ==========
  footer = bs4DashFooter(
    left = tags$span(
      "© 2026 ",
      tags$a(href = "https://marinesabres.eu", target = "_blank", "Marine-SABRES"),
      " - ", i18n$t("ui.header.footer_project")
    ),
    right = tags$span(
      i18n$t("ui.header.footer_toolbox"), " ",
      tags$strong(paste0("v", tryCatch(readLines("VERSION")[1], error = function(e) "unknown"))),
      " | ",
      tags$a(href = "https://github.com/marinesabres", target = "_blank", icon("github"))
    )
  ),

  # ========== DASHBOARD OPTIONS ==========
  # Static light theme (following EcoNeTool architecture)
  skin = "light",
  freshTheme = NULL,
  help = NULL,  # Disable bs4Dash's built-in help toggle (we use custom tooltip implementation)
  dark = NULL
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {

  # ========== REACTIVE VALUES ==========
  # NOTE: These must be initialized BEFORE any observe() blocks that use them

  # Main project data
  project_data <- reactiveVal(init_session_data())

  # User experience level (beginner/intermediate/expert)
  # Default to beginner for new users and stakeholder testing
  user_level <- reactiveVal("beginner")

  # Auto-save enabled flag (controls AI ISA Assistant auto-save)
  # Default to FALSE to avoid accidental overwrites
  autosave_enabled <- reactiveVal(FALSE)

  # Advanced auto-save settings
  autosave_delay <- reactiveVal(2)  # Default: 2 seconds
  autosave_notifications <- reactiveVal(FALSE)  # Default: notifications OFF
  autosave_indicator <- reactiveVal(TRUE)  # Default: indicator ON
  autosave_triggers <- reactiveVal(c("elements", "context", "connections", "steps"))  # Default: all triggers

  # SES Models directory setting (empty = use default app directory)
  ses_models_directory <- reactiveVal("")

  # Define root directories for shinyFiles (used in directory selection)
  volumes <- c(
    Home = Sys.getenv("HOME"),
    Documents = file.path(Sys.getenv("HOME"), "Documents"),
    App = normalizePath("."),
    getVolumes()()  # System volumes (drives)
  )

  # ========== REACTIVE EVENT BUS ==========
  # Create event bus for reactive data pipeline
  event_bus <- create_event_bus()

  # === DIAGNOSTICS: Print project data element counts and IDs at startup and on load ===
  observe({
    if (!DEBUG_MODE) return()
    data <- project_data()
    if (!is.null(data) && !is.null(data$data$isa_data)) {
      debug_log("[DIAGNOSTIC] Project data loaded", "DIAGNOSTICS")
      for (etype in c("drivers", "activities", "pressures", "marine_processes", "ecosystem_services", "goods_benefits", "responses")) {
        el <- data$data$isa_data[[etype]]
        if (!is.null(el) && nrow(el) > 0) {
          debug_log(sprintf("%s: %d elements", etype, nrow(el)), "DIAGNOSTICS")
          debug_log(sprintf("%s IDs: %s", etype, paste(head(el$ID, 10), collapse=", ")), "DIAGNOSTICS")
        } else {
          debug_log(sprintf("%s: 0 elements", etype), "DIAGNOSTICS")
        }
      }
      if (!is.null(data$data$isa_data$adjacency_matrices)) {
        debug_log("Adjacency matrices present:", "DIAGNOSTICS")
        debug_log(paste(names(data$data$isa_data$adjacency_matrices), collapse=", "), "DIAGNOSTICS")
      } else {
        debug_log("No adjacency matrices present", "DIAGNOSTICS")
      }
    } else {
      debug_log("Project data or isa_data is NULL", "DIAGNOSTICS")
    }
  })

  debug_log("=====================================", "SESSION")
  debug_log("APP RESTARTED - NEW SESSION STARTING", "SESSION")
  debug_log(paste("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), "SESSION")
  debug_log(paste("Report generation functions loaded:", exists("generate_report_content")), "SESSION")
  debug_log("=====================================", "SESSION")

  # ========== SESSION-LOCAL I18N TRANSLATOR ==========
  # IMPORTANT: Create a session-local i18n to prevent language changes from affecting

  # other users' sessions. The global i18n in global.R is shared across all sessions,
  # so we need a session-specific wrapper that maintains its own language state.

  # Session-local language state (defaults to English)
  session_language <- reactiveVal("en")

  # Create session-local i18n wrapper that uses session-specific language
  # This wraps the global translator but maintains its own language setting
  session_i18n <- local({
    # Private environment to store session-specific state
    env <- new.env(parent = emptyenv())
    env$current_lang <- "en"

    # Get reference to the underlying translator from global i18n
    translator <- i18n$translator

    list(
      t = function(key) {
        # Temporarily set the translator's language, translate, then restore
        # This is thread-safe because Shiny processes one session at a time per worker
        old_lang <- translator$get_translation_language()
        if (old_lang != env$current_lang) {
          translator$set_translation_language(env$current_lang)
        }
        result <- tryCatch({
          i18n$t(key)  # Use the wrapper's t() which handles namespaced keys
        }, error = function(e) {
          key  # Fallback to key on error
        })
        if (old_lang != env$current_lang) {
          translator$set_translation_language(old_lang)
        }
        result
      },
      set_translation_language = function(lang) {
        env$current_lang <- lang
        session_language(lang)  # Update reactive value
        debug_log(sprintf("Session language set to: %s", lang), "I18N")
      },
      get_translation_language = function() {
        env$current_lang
      },
      get_translations = function() {
        translator$get_translations()
      },
      use_js = function() {
        translator$use_js()
      },
      get_languages = function() {
        translator$get_languages()
      },
      get_key_translation = function() {
        translator$get_key_translation()
      },
      translator = translator  # Access to underlying translator if needed
    )
  })
  class(session_i18n) <- c("session_translator", "wrapped_translator", "list")

  # Store in session$userData for access by modules if needed
  session$userData$i18n <- session_i18n
  session$userData$session_language <- session_language

  debug_log("Session-local i18n translator created", "I18N")

  # ========== AUTO-LOAD DEFAULT TEMPLATE IF EMPTY ========== 
  observe({
    # Only run once at startup
    isolate({
      data <- project_data()
      # Check if all SES element types are empty or missing
      isa <- data$data$isa_data
      if (is_empty_isa_data(isa)) {
        debug_log("No SES data found, loading default template...", "AUTOLOAD")
        # Load the migrated Caribbean template (update path if needed)
        template_path <- "data/Caribbean_SES_Template.json"
        if (file.exists(template_path)) {
          template <- load_template_from_json(template_path)
          # Build project_data structure
          new_data <- data
          new_data$data$isa_data$drivers <- template$drivers
          new_data$data$isa_data$activities <- template$activities
          new_data$data$isa_data$pressures <- template$pressures
          new_data$data$isa_data$marine_processes <- template$marine_processes
          new_data$data$isa_data$ecosystem_services <- template$ecosystem_services
          new_data$data$isa_data$goods_benefits <- template$goods_benefits
          new_data$data$isa_data$responses <- template$responses
          new_data$data$isa_data$adjacency_matrices <- template$adjacency_matrices
          new_data$data$metadata$template_used <- template$template_name %||% "Caribbean_SES_Template"
          new_data$data$metadata$source <- "autoloaded_default_template"
          new_data$last_modified <- Sys.time()
          project_data(new_data)
          debug_log("Default template loaded successfully", "AUTOLOAD")
        } else {
          debug_log(paste("ERROR: Default template file not found at:", template_path), "AUTOLOAD")
        }
      }
    })
  })

  # ========== RESTORE PROJECT DATA AFTER LANGUAGE CHANGE ==========
  # When user changes language, the page reloads. To preserve their work,
  # we save project data to sessionStorage before reload and restore it here.
  observeEvent(input$restore_project_data_from_lang_change, {
    req(input$restore_project_data_from_lang_change)

    tryCatch({
      debug_log("Restoring project data after language change...", "LANG_RESTORE")

      # Parse the JSON data sent from JavaScript
      saved_data <- jsonlite::fromJSON(input$restore_project_data_from_lang_change, simplifyVector = FALSE)

      if (!is.null(saved_data)) {
        # Validate project structure before restoring
        required_keys <- c("project_id", "project_name", "data")
        if (!is.list(saved_data) || !all(required_keys %in% names(saved_data))) {
          debug_log("Invalid project structure in restored data — refusing to restore", "LANG_RESTORE")
          return()
        }

        # Restore the project data
        project_data(saved_data)
        debug_log("Project data restored successfully after language change", "LANG_RESTORE")

        # Show notification to user
        showNotification(
          HTML(paste0(
            icon("check-circle"), " ",
            session_i18n$t("common.messages.progress_restored_after_language_change")
          )),
          type = "message",
          duration = 4
        )
      }
    }, error = function(e) {
      debug_log(sprintf("ERROR restoring project data: %s", e$message), "LANG_RESTORE")
      # Don't show error to user, just log it - the default template will be used
    })
  }, ignoreInit = TRUE)

  # ========== BOOKMARKING ==========
  # Bookmarking logic extracted to server/bookmarking.R for better maintainability
  setup_bookmarking(input, output, session, project_data, user_level,
                    autosave_enabled, session_i18n, debug_log)

  # ========== AUTO-SAVE MODULE ==========
  # Initialize auto-save functionality
  # Pass autosave_enabled reactive so module respects user's setting
  # Pass event_bus for event-driven auto-save (non-intrusive, triggers on SES changes)
  # Pass advanced autosave settings for customizable behavior
  auto_save_server("auto_save", project_data, session_i18n, autosave_enabled, event_bus,
                   autosave_delay, autosave_notifications,
                   autosave_indicator, autosave_triggers)

  # ========== LOCAL STORAGE MODULE ==========
  # Initialize local storage functionality for saving/loading to user's computer
  # Uses File System Access API for modern browsers with download/upload fallback
  local_storage_control <- local_storage_server("local_storage", project_data, session_i18n, event_bus)

  # ========== LANGUAGE STATE MANAGEMENT (EARLY) ==========
  # Load language from query parameter BEFORE anything else
  observe({
    query <- parseQueryString(session$clientData$url_search)
    debug_log(sprintf("URL search: %s", session$clientData$url_search), "LANGUAGE")

    if (!is.null(query$language)) {
      debug_log(sprintf("Found language parameter: %s", query$language), "LANGUAGE")

      if (query$language %in% names(AVAILABLE_LANGUAGES)) {
        debug_log(sprintf("Setting language to: %s", query$language), "LANGUAGE")

        # Set language in SESSION-LOCAL translator (not global!)
        # This ensures language changes only affect THIS session
        session_i18n$set_translation_language(query$language)
        debug_log(sprintf("Session language set. Current: %s", session_i18n$get_translation_language()), "LANGUAGE")

        # Use shiny.i18n's built-in update mechanism for elements with data-i18n attributes
        shiny.i18n::update_lang(query$language, session)

        # Capture translations NOW (before async call) to ensure they're strings
        # Use session_i18n for session-specific translations
        header_translations <- list(
          language = as.character(session_i18n$t("ui.header.language")),
          change_language = as.character(session_i18n$t("ui.header.change_language")),
          settings = as.character(session_i18n$t("ui.header.settings")),
          application_settings = as.character(session_i18n$t("ui.header.application_settings")),
          user_experience_level = as.character(session_i18n$t("ui.header.user_experience_level")),
          download_manuals = as.character(session_i18n$t("ui.header.download_manuals")),
          app_info = as.character(session_i18n$t("ui.header.app_info")),
          help = as.character(session_i18n$t("ui.header.help")),
          step_by_step_tutorial = as.character(session_i18n$t("ui.header.step_by_step_tutorial")),
          quick_reference = as.character(session_i18n$t("ui.header.quick_reference")),
          bookmark = as.character(session_i18n$t("ui.header.bookmark"))
        )
        debug_log(sprintf("Header translations captured: %s, %s, %s",
                    header_translations$language, header_translations$settings, header_translations$help), "LANGUAGE")

        # Schedule header update to run after shiny.i18n finishes
        later::later(function() {
          session$sendCustomMessage(type = "updateHeaderTranslations", message = header_translations)
        }, delay = 0.1)
      } else {
        debug_log(sprintf("Invalid language: %s", query$language), "LANGUAGE")
      }
    } else {
      debug_log("No language parameter in URL", "LANGUAGE")
    }
  }, priority = 1000)  # High priority to run early

  # ========== LANGUAGE CHANGE TRIGGER ==========
  # Create a reactive value that changes when language changes
  # This forces UI elements to re-render when language is switched
  lang_trigger <- reactiveVal(0)
  last_lang <- reactiveVal(session_i18n$get_translation_language())

  # Observe language changes and trigger re-render only if language actually changes
  # Uses session_language reactive to detect changes in the session-local language
  observe({
    current_lang <- session_language()  # Use the reactive value for proper invalidation
    if (!identical(current_lang, last_lang())) {
      lang_trigger(lang_trigger() + 1)
      last_lang(current_lang)
      debug_log(sprintf("Language trigger updated: %s (count: %d)",
                  current_lang, lang_trigger()), "LANGUAGE")
    }
  })

  # ========== DYNAMIC SIDEBAR MENU ==========
  # Renders sidebar menu dynamically based on current language and user level
  # This allows the menu to update when language or user level changes
  output$dynamic_sidebar <- renderMenu({
    # Add dependency on language trigger to force re-render on language change
    lang_trigger()

    tryCatch({
      debug_log("Rendering dynamic sidebar...", "SIDEBAR")
      debug_log(sprintf("User level: %s", user_level()), "SIDEBAR")
      debug_log(sprintf("Current language: %s", session_i18n$get_translation_language()), "SIDEBAR")
      menu <- generate_sidebar_menu(user_level(), session_i18n)
      debug_log("Sidebar generated successfully", "SIDEBAR")
      menu
    }, error = function(e) {
      debug_log(sprintf("ERROR: %s", e$message), "SIDEBAR")
      # Return a minimal sidebar on error
      bs4SidebarMenu(
        bs4SidebarMenuItem(text = "Dashboard", tabName = "dashboard", icon = icon("dashboard"))
      )
    })
  })

  # Re-initialize tooltips for sidebar menu items after dynamic updates
  # The sidebar is rendered dynamically via renderMenu(), so tooltips need
  # to be re-initialized each time language or user level changes
  # We use custom JavaScript handler for full control over tooltip behavior
  # NOTE: Using shinyjs::delay instead of invalidateLater to avoid infinite re-trigger loop
  observeEvent(c(lang_trigger(), user_level()), {
    # Use shinyjs::delay for one-time delayed execution (not invalidateLater which loops)
    shinyjs::delay(600, {
      # Send custom message to JavaScript to re-initialize tooltips
      # This ensures sidebar menu tooltips work after dynamic updates
      session$sendCustomMessage("initSidebarTooltips", list(
        selector = ".main-sidebar .nav-link[title]"
      ))

      debug_log("Sidebar tooltip re-initialization completed", "TOOLTIPS")
    })
  }, ignoreNULL = TRUE, ignoreInit = TRUE)

  # User info
  output$user_info <- renderText({
    paste("User:", Sys.info()["user"])
  })

  # Current language display
  output$current_language_display <- renderText({
    current_lang <- if(!is.null(session_i18n$get_translation_language())) {
      session_i18n$get_translation_language()
    } else {
      "en"
    }
    AVAILABLE_LANGUAGES[[current_lang]]$name
  })

  # ========== LANGUAGE STATE MANAGEMENT ==========
  # (Handled earlier at line 543 with high priority)

  # ========== USER LEVEL STATE MANAGEMENT ==========

  # Load user level from query parameter on startup
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query$user_level) && query$user_level %in% c("beginner", "intermediate", "expert")) {
      user_level(query$user_level)
      debug_log(sprintf("Loaded from URL: %s", query$user_level), "USER-LEVEL")
    }
  })

  # User level persistence REMOVED for consistent fresh-start behavior
  # Previously loaded from localStorage, but this caused confusion:
  # - User level persisted (setting)
  # - But guided pathway data did NOT persist (actual work)
  # Now: Everything starts fresh on restart for stakeholder testing
  # Users must explicitly "Save Project" to persist any data

  # ========== MODAL HANDLERS ==========
  # Modals extracted to server/modals.R for better maintainability
  # IMPORTANT: Use session_i18n for session-specific translations

  # Setup language settings modal (uses session_i18n to prevent cross-session language changes)
  # Pass project_data so it can be saved before language change reload
  setup_language_modal_handlers(input, output, session, session_i18n, autosave_enabled, AVAILABLE_LANGUAGES,
                                 autosave_delay, autosave_notifications,
                                 autosave_indicator, autosave_triggers,
                                 ses_models_directory, volumes,
                                 project_data = project_data)

  # Setup user level modal
  setup_user_level_modal_handlers(input, output, session, user_level, session_i18n)

  # Setup download manuals modal
  setup_manuals_modal_handlers(input, output, session, session_i18n)

  # Setup about modal
  setup_about_modal_handlers(input, output, session, session_i18n)

  # ========== CONTROLBAR HANDLERS - REMOVED ==========
  # Controlbar has been removed - settings now in main settings modal
  # User level and autosave settings accessible via Settings dropdown in header
  # Quick save/load actions available in sidebar

  # ========== CALL MODULE SERVERS ==========
  # IMPORTANT: All modules now receive session_i18n for session-specific translations

  # Entry Point module - pass session for sidebar navigation and user level
  entry_point_server("entry_pt", project_data, session_i18n, parent_session = session, user_level_reactive = user_level)

  # Workflow stepper (beginner guidance bar)
  workflow_stepper_server(
    "workflow_stepper",
    project_data_reactive = project_data,
    i18n = session_i18n,
    parent_session = session,
    user_level_reactive = user_level,
    sidebar_input = reactive(input$sidebar_menu)
  )

  # PIMS modules
  pims_project_data <- pims_project_server("pims_proj", project_data, session_i18n)
  pims_stakeholders_data <- pims_stakeholder_server("pims_stake", project_data, session_i18n)
  pims_resources_data <- pims_resources_server("pims_res", project_data, session_i18n)
  pims_data_data <- pims_data_server("pims_dm", project_data, session_i18n)
  pims_evaluation_data <- pims_evaluation_server("pims_eval", project_data, session_i18n)

  # ==================== CREATE SES MODULES ====================
  # Main Create SES module (method selector)
  create_ses_server("create_ses_main", project_data, session_i18n, parent_session = session)

  # Template-based SES module
  template_ses_server("template_ses", project_data, session, event_bus, session_i18n)

  # AI ISA Assistant module
  ai_isa_assistant_server("ai_isa_mod", project_data, session_i18n, event_bus, autosave_enabled, user_level, session)

  # ISA data entry module (Standard Entry)
  isa_data <- isa_data_entry_server("isa_module", project_data, event_bus)

  # Graphical SES Creator module (AI-powered step-by-step network building)
  graphical_ses_creator_server("graphical_ses_mod", project_data, session, session_i18n)

  # CLD visualization
  cld_viz_server("cld_visual", project_data, session_i18n)

  # Analysis modules
  analysis_metrics_server("analysis_met", project_data, session_i18n)
  analysis_loops_server("analysis_loop", project_data, session_i18n)
  analysis_leverage_server("analysis_lev", project_data, session_i18n)
  analysis_bot_server("analysis_b", project_data, session_i18n)
  analysis_simplify_server("analysis_simp", project_data, session_i18n)

  # DTU dynamics analysis modules
  analysis_boolean_server("analysis_bool", project_data, session_i18n)
  analysis_simulation_server("analysis_sim", project_data, session_i18n)
  analysis_intervention_server("analysis_intv", project_data, session_i18n)

  # Response & validation modules
  response_measures_server("resp_meas", project_data, session_i18n)
  scenario_builder_server("scenario_builder", project_data, session_i18n)
  response_validation_server("resp_val", project_data, session_i18n)

  # Import Data module
  import_data_server("import_data_mod", project_data, session_i18n, session, event_bus)

  # SES Models module (Load Pre-built Models)
  ses_models_server("ses_models_mod", project_data, session_i18n, session, event_bus, ses_models_directory)

  # Export & Reports module (simple)
  export_reports_server("export_reports_mod", project_data, session_i18n)

  # Prepare Report module (comprehensive)
  prepare_report_server("prep_report", project_data, session_i18n, parent_session = session)

  # ========== REACTIVE DATA PIPELINE ==========
  # Setup event-based reactive pipeline for automatic data propagation
  # ISA changes → auto-regenerate CLD → auto-invalidate analysis
  setup_reactive_pipeline(project_data, event_bus)

  # ========== DASHBOARD ==========
  # Dashboard logic extracted to server/dashboard.R for better maintainability

  setup_dashboard_rendering(input, output, session, project_data, session_i18n)

  # ========== SAVE/LOAD PROJECT ==========
  # Project I/O logic extracted to server/project_io.R for better maintainability

  setup_project_io_handlers(input, output, session, project_data, session_i18n)

  # ========== EXPORT HANDLERS ==========
  # Export logic extracted to server/export_handlers.R for better maintainability

  setup_export_handlers(input, output, session, project_data, session_i18n)

  # ========== REPORT GENERATION ==========

  # Report status output

  # ========== SESSION CLEANUP ==========
  # Clean up reactive values and temporary files when session ends
  session$onSessionEnded(function() {
    tryCatch({
      # Clean up any temporary report files created during this session
      temp_report_dir <- file.path(tempdir(), "reports")
      if (dir.exists(temp_report_dir)) {
        unlink(temp_report_dir, recursive = TRUE)
      }

      # Clean up www/reports directory (HTML reports served during session)
      www_reports_dir <- file.path(getwd(), "www", "reports")
      if (dir.exists(www_reports_dir)) {
        unlink(www_reports_dir, recursive = TRUE)
      }

      debug_log("Session ended - cleanup completed", "SESSION")
    }, error = function(e) {
      # Silently handle cleanup errors - session is ending anyway
    })
  })

}

# Note: Report generation functions now loaded from functions/report_generation.R

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server, enableBookmarking = "url")
