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

source("global.R")

# ============================================================================
# REGISTER RESOURCE PATHS
# ============================================================================

# Make docs directory accessible for serving user manuals (only if it exists)
if (dir.exists("docs")) {
  addResourcePath("docs", "docs")
}

# ============================================================================
# LOAD HELPER FUNCTIONS
# ============================================================================

source("functions/report_generation.R")

# Load UI components
source("functions/ui_header.R")
source("functions/ui_sidebar.R")

# Load server components
source("server/modals.R")
source("server/dashboard.R")
source("server/project_io.R")
source("server/export_handlers.R")

# ============================================================================
# SOURCE MODULES
# ============================================================================

source("modules/entry_point_module.R", local = TRUE)  # Entry Point guidance system
source("modules/create_ses_module.R", local = TRUE)  # NEW: Consolidated Create SES module
source("modules/template_ses_module.R", local = TRUE)  # NEW: Template-based SES creation
source("modules/ai_isa_assistant_module.R", local = TRUE)  # AI-Assisted SES Creation
source("modules/import_data_module.R", local = TRUE)  # Import Data from Excel
source("modules/isa_data_entry_module.R", local = TRUE)  # Standard ISA Data Entry
source("modules/pims_module.R", local = TRUE)
source("modules/pims_stakeholder_module.R", local = TRUE)
source("modules/cld_visualization_module.R", local = TRUE)
source("modules/analysis_tools_module.R", local = TRUE)
source("modules/response_module.R", local = TRUE)
source("modules/scenario_builder_module.R", local = TRUE)  # Scenario Builder
source("modules/prepare_report_module.R", local = TRUE)  # Report preparation (comprehensive)
source("modules/export_reports_module.R", local = TRUE)  # Export & Reports (simple)
# source("modules/response_validation_module.R", local = FALSE)  # Not implemented yet

# ============================================================================
# UI
# ============================================================================

ui <- dashboardPage(
  
  # ========== HEADER ==========
  build_dashboard_header(i18n),
  
  # ========== SIDEBAR ==========
  dashboardSidebar(
    width = UI_SIDEBAR_WIDTH,

    # Dynamic sidebar menu that updates when language changes
    sidebarMenuOutput("dynamic_sidebar")
  ),
  
  # ========== BODY ==========
  dashboardBody(

    # Enable shiny.i18n automatic language detection and reactive translations
    # Note: Must use the underlying translator object, not the wrapper
    shiny.i18n::usei18n(i18n$translator),

    # Custom CSS and JavaScript
    tags$head(
      tags$title("MarineSABRES SES Toolbox"),
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "isa-forms.css"),
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

    tabItems(

      # ==================== ENTRY POINT (GETTING STARTED) ====================
      tabItem(tabName = "entry_point", entry_point_ui("entry_pt", i18n)),

      # ==================== DASHBOARD ====================
      tabItem(
        tabName = "dashboard",

        fluidRow(
          column(12,
            uiOutput("dashboard_header")
          )
        ),

        fluidRow(
          # Summary boxes
          valueBoxOutput("total_elements_box", width = 3),
          valueBoxOutput("total_connections_box", width = 3),
          valueBoxOutput("loops_detected_box", width = 3),
          valueBoxOutput("completion_box", width = 3)
        ),

        fluidRow(
          # Project overview
          box(
            title = i18n$t("ui.dashboard.project_overview"),
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = UI_BOX_HEIGHT_DEFAULT,
            tags$div(
              style = "overflow-y: auto; max-height: 330px; padding: 5px;",
              uiOutput("project_overview_ui")
            )
          ),

          # Status summary
          box(
            title = i18n$t("ui.dashboard.status_summary"),
            status = "success",
            solidHeader = TRUE,
            width = 6,
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

              # CLD Status
              tags$div(
                style = "margin-bottom: 10px; padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("project-diagram"), " ", i18n$t("ui.dashboard.cld_status")),
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
        )
      ),

      # ==================== PIMS MODULE ====================
      tabItem(tabName = "pims_project", pims_project_ui("pims_proj", i18n)),
      tabItem(tabName = "pims_stakeholders", pimsStakeholderUI("pims_stake", i18n)),
      tabItem(tabName = "pims_resources", pims_resources_ui("pims_res", i18n)),
      tabItem(tabName = "pims_data", pims_data_ui("pims_dm", i18n)),
      tabItem(tabName = "pims_evaluation", pims_evaluation_ui("pims_eval", i18n)),

      # ==================== CREATE SES ====================
      # Choose Method
      tabItem(tabName = "create_ses_choose", create_ses_ui("create_ses_main", i18n)),

      # Standard Entry
      tabItem(tabName = "create_ses_standard", isaDataEntryUI("isa_module")),

      # AI Assistant
      tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod", i18n)),

      # Template-Based
      tabItem(tabName = "create_ses_template", template_ses_ui("template_ses", i18n)),

      # ==================== CLD VISUALIZATION ====================
      tabItem(tabName = "cld_viz", cld_viz_ui("cld_visual", i18n)),
      
      # ==================== ANALYSIS ====================
      tabItem(tabName = "analysis_metrics", analysis_metrics_ui("analysis_met", i18n)),
      tabItem(tabName = "analysis_loops", analysis_loops_ui("analysis_loop", i18n)),
      tabItem(tabName = "analysis_leverage", analysis_leverage_ui("analysis_lev", i18n)),
      tabItem(tabName = "analysis_bot", analysis_bot_ui("analysis_b", i18n)),
      tabItem(tabName = "analysis_simplify", analysis_simplify_ui("analysis_simp", i18n)),
      
      # ==================== RESPONSE & VALIDATION ====================
      tabItem(tabName = "response_measures", response_measures_ui("resp_meas", i18n)),
      tabItem(tabName = "response_scenarios", scenario_builder_ui("scenario_builder", i18n)),
      tabItem(tabName = "response_validation", response_validation_ui("resp_val", i18n)),

      # ==================== IMPORT DATA ====================
      tabItem(tabName = "import_data", import_data_ui("import_data_mod", i18n)),

      # ==================== EXPORT ====================
      tabItem(
        tabName = "export",
        export_reports_ui("export_reports_mod", i18n)
      ),

      # ==================== PREPARE REPORT ====================
      tabItem(tabName = "prepare_report", prepare_report_ui("prep_report", i18n))
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {
  # === DIAGNOSTICS: Print project data element counts and IDs at startup and on load ===
  observe({
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
        template_path <- "data/Caribbean_SES_Template_migrated.json"
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
  # ========== BOOKMARKING SETUP ========== 
  # Enable bookmarking for this session
  setBookmarkExclude(c("save_project", "load_project", "confirm_save",
                       "confirm_load", "trigger_bookmark"))

  # ========== REACTIVE VALUES ==========

  # Main project data
  project_data <- reactiveVal(init_session_data())

  # User experience level (beginner/intermediate/expert)
  # Default to beginner for new users and stakeholder testing
  user_level <- reactiveVal("beginner")

  # Auto-save enabled flag (controls AI ISA Assistant auto-save)
  # Default to FALSE to avoid accidental overwrites
  autosave_enabled <- reactiveVal(FALSE)

  # ========== REACTIVE EVENT BUS ==========
  # Create event bus for reactive data pipeline
  event_bus <- create_event_bus()

  # ========== BOOKMARKING HANDLERS ==========

  # Save state when bookmark button is clicked
  observeEvent(input$trigger_bookmark, {
    session$doBookmark()
  })

  # Save app state for bookmarking
  onBookmark(function(state) {
    cat("[BOOKMARK] Saving app state...\n")

    # Save user level
    state$values$user_level <- user_level()

    # Save current tab
    if (!is.null(input$sidebar_menu)) {
      state$values$active_tab <- input$sidebar_menu
      cat("[BOOKMARK] Saved active tab:", input$sidebar_menu, "\n")
    }

    # Save autosave setting
    state$values$autosave_enabled <- autosave_enabled()

    # Save project data (serialized as JSON for URL safety)
    # Note: Only save essential data to avoid URL length limits
    data <- project_data()

    # Save metadata
    if (!is.null(data$data$metadata)) {
      state$values$metadata_da_site <- data$data$metadata$da_site
      state$values$metadata_focal_issue <- data$data$metadata$focal_issue
    }

    # Indicate if ISA data exists
    state$values$has_isa_data <- !is.null(data$data$isa_data$goods_benefits) &&
                                  nrow(data$data$isa_data$goods_benefits) > 0

    # Indicate if CLD exists
    state$values$has_cld_data <- !is.null(data$data$cld$nodes) &&
                                  nrow(data$data$cld$nodes) > 0

    cat("[BOOKMARK] State saved successfully\n")
  })

  # Show modal after bookmark URL is generated
  onBookmarked(function(url) {
    cat("[BOOKMARK] Bookmark URL created:", url, "\n")

    # Show bookmark modal with URL
    showModal(modalDialog(
      title = tags$h3(icon("bookmark"), " Bookmark Created"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close")),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("check-circle"), " Your bookmark has been created!"),
        tags$p("Copy the URL below to save your current application state:"),

        tags$div(
          class = "well",
          style = "background: #f8f9fa; padding: 15px; margin: 20px 0;",
          tags$textarea(
            id = "bookmark_url",
            class = "form-control",
            rows = 4,
            readonly = "readonly",
            style = "font-family: monospace; font-size: 12px; resize: vertical;",
            url
          )
        ),

        tags$button(
          id = "copy_bookmark_btn",
          class = "btn btn-primary btn-block",
          icon("copy"),
          " Copy URL to Clipboard",
          onclick = "
            var textarea = document.getElementById('bookmark_url');
            textarea.select();
            document.execCommand('copy');
            $(this).html('<i class=\"fa fa-check\"></i> Copied!');
            setTimeout(() => {
              $(this).html('<i class=\"fa fa-copy\"></i> Copy URL to Clipboard');
            }, 2000);
          "
        ),

        tags$hr(),

        tags$div(
          class = "alert alert-info",
          icon("info-circle"),
          tags$strong(" Note: "),
          "This bookmark saves your current view and settings. To save your complete project data, use the 'Save Project' button in the sidebar."
        ),

        tags$h5("What's saved in this bookmark:"),
        tags$ul(
          tags$li("Current tab/page location"),
          tags$li("User experience level"),
          tags$li("Language preference"),
          tags$li("Auto-save settings"),
          tags$li("Selected demonstration area and focal issue")
        )
      )
    ))
  })

  # Restore state from bookmark
  onRestore(function(state) {
    cat("[BOOKMARK] Restoring app state...\n")

    # Restore user level
    if (!is.null(state$values$user_level)) {
      user_level(state$values$user_level)
      cat("[BOOKMARK] Restored user level:", state$values$user_level, "\n")
    }

    # Restore autosave setting
    if (!is.null(state$values$autosave_enabled)) {
      autosave_enabled(state$values$autosave_enabled)
      cat("[BOOKMARK] Restored autosave setting:", state$values$autosave_enabled, "\n")
    }

    # Restore metadata if saved
    if (!is.null(state$values$metadata_da_site) || !is.null(state$values$metadata_focal_issue)) {
      data <- project_data()
      if (!is.null(state$values$metadata_da_site)) {
        data$data$metadata$da_site <- state$values$metadata_da_site
      }
      if (!is.null(state$values$metadata_focal_issue)) {
        data$data$metadata$focal_issue <- state$values$metadata_focal_issue
      }
      project_data(data)
      cat("[BOOKMARK] Restored metadata\n")
    }

    # Restore active tab
    if (!is.null(state$values$active_tab)) {
      # Use updateTabItems to switch to saved tab
      updateTabItems(session, "sidebar_menu", state$values$active_tab)
      cat("[BOOKMARK] Restored active tab:", state$values$active_tab, "\n")
    }

    # Show restoration notification
    showNotification(
      HTML(paste0(
        icon("bookmark"), " ",
        i18n$t("common.messages.bookmark_restored_successfully")
      )),
      type = "message",
      duration = 5
    )

    cat("[BOOKMARK] State restored successfully\n")
  })

  # Restore tab after bookmark URL is loaded
  observeEvent(input$sidebar_menu, {
    query <- parseQueryString(session$clientData$url_search)
    if ("_state_id_" %in% names(query)) {
      # This is a bookmarked session, log it
      cat("[BOOKMARK] Bookmarked session detected\n")
    }
  }, once = TRUE)

  # ========== AUTO-SAVE MODULE ==========
  # Initialize auto-save functionality
  # Pass autosave_enabled reactive so module respects user's setting
  auto_save_server("auto_save", project_data, i18n, autosave_enabled)

  # ========== LANGUAGE STATE MANAGEMENT (EARLY) ==========
  # Load language from query parameter BEFORE anything else
  observe({
    query <- parseQueryString(session$clientData$url_search)
    cat(sprintf("[LANGUAGE] URL search: %s\n", session$clientData$url_search))

    if (!is.null(query$language)) {
      cat(sprintf("[LANGUAGE] Found language parameter: %s\n", query$language))

      if (query$language %in% names(AVAILABLE_LANGUAGES)) {
        cat(sprintf("[LANGUAGE] Setting language to: %s\n", query$language))

        # Set language in wrapper (this will also set it in underlying translator)
        i18n$set_translation_language(query$language)
        cat(sprintf("[LANGUAGE] Language set. Current: %s\n", i18n$get_translation_language()))

        # Use shiny.i18n's built-in update mechanism for elements with data-i18n attributes
        shiny.i18n::update_lang(query$language, session)

        # Capture translations NOW (before async call) to ensure they're strings
        header_translations <- list(
          language = as.character(i18n$t("ui.header.language")),
          change_language = as.character(i18n$t("ui.header.change_language")),
          settings = as.character(i18n$t("ui.header.settings")),
          application_settings = as.character(i18n$t("ui.header.application_settings")),
          user_experience_level = as.character(i18n$t("ui.header.user_experience_level")),
          download_manuals = as.character(i18n$t("ui.header.download_manuals")),
          app_info = as.character(i18n$t("ui.header.app_info")),
          help = as.character(i18n$t("ui.header.help")),
          step_by_step_tutorial = as.character(i18n$t("ui.header.step_by_step_tutorial")),
          quick_reference = as.character(i18n$t("ui.header.quick_reference")),
          bookmark = as.character(i18n$t("ui.header.bookmark"))
        )
        cat(sprintf("[LANGUAGE] Header translations captured: %s, %s, %s\n",
                    header_translations$language, header_translations$settings, header_translations$help))

        # Schedule header update to run after shiny.i18n finishes
        later::later(function() {
          session$sendCustomMessage(type = "updateHeaderTranslations", message = header_translations)
        }, delay = 0.1)
      } else {
        cat(sprintf("[LANGUAGE] Invalid language: %s\n", query$language))
      }
    } else {
      cat("[LANGUAGE] No language parameter in URL\n")
    }
  }, priority = 1000)  # High priority to run early

  # ========== LANGUAGE CHANGE TRIGGER ==========
  # Create a reactive value that changes when language changes
  # This forces UI elements to re-render when language is switched
  lang_trigger <- reactiveVal(0)
  last_lang <- reactiveVal(i18n$get_translation_language())

  # Observe language changes and trigger re-render only if language actually changes
  observe({
    current_lang <- i18n$get_translation_language()
    if (!identical(current_lang, last_lang())) {
      lang_trigger(lang_trigger() + 1)
      last_lang(current_lang)
      cat(sprintf("[LANGUAGE] Language trigger updated: %s (count: %d)\n",
                  current_lang, lang_trigger()))
    }
  })

  # ========== DYNAMIC SIDEBAR MENU ==========
  # Renders sidebar menu dynamically based on current language and user level
  # This allows the menu to update when language or user level changes
  output$dynamic_sidebar <- renderMenu({
    # Add dependency on language trigger to force re-render on language change
    lang_trigger()

    tryCatch({
      cat("[SIDEBAR] Rendering dynamic sidebar...\n")
      cat(sprintf("[SIDEBAR] User level: %s\n", user_level()))
      cat(sprintf("[SIDEBAR] Current language: %s\n", i18n$get_translation_language()))
      menu <- generate_sidebar_menu(user_level(), i18n)
      cat("[SIDEBAR] Sidebar generated successfully\n")
      menu
    }, error = function(e) {
      cat(sprintf("[SIDEBAR] ERROR: %s\n", e$message))
      # Return a minimal sidebar on error
      sidebarMenu(
        menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard"))
      )
    })
  })

  # User info
  output$user_info <- renderText({
    paste("User:", Sys.info()["user"])
  })

  # Current language display
  output$current_language_display <- renderText({
    current_lang <- if(!is.null(i18n$get_translation_language())) {
      i18n$get_translation_language()
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
      cat(sprintf("[USER-LEVEL] Loaded from URL: %s\n", query$user_level))
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

  # Setup language settings modal
  setup_language_modal_handlers(input, output, session, i18n, autosave_enabled, AVAILABLE_LANGUAGES)

  # Setup user level modal
  setup_user_level_modal_handlers(input, output, session, user_level, i18n)

  # Setup download manuals modal
  setup_manuals_modal_handlers(input, output, session, i18n)

  # Setup about modal
  setup_about_modal_handlers(input, output, session, i18n)

  # ========== CALL MODULE SERVERS ==========

  # Entry Point module - pass session for sidebar navigation and user level
  entry_point_server("entry_pt", project_data, i18n, parent_session = session, user_level_reactive = user_level)

  # PIMS modules
  pims_project_data <- pims_project_server("pims_proj", project_data, i18n)
  pims_stakeholders_data <- pimsStakeholderServer("pims_stake", project_data, i18n)
  pims_resources_data <- pims_resources_server("pims_res", project_data, i18n)
  pims_data_data <- pims_data_server("pims_dm", project_data, i18n)
  pims_evaluation_data <- pims_evaluation_server("pims_eval", project_data, i18n)
  
  # ==================== CREATE SES MODULES ====================
  # Main Create SES module (method selector)
  create_ses_server("create_ses_main", project_data, session, i18n)

  # Template-based SES module
  template_ses_server("template_ses", project_data, session, event_bus, i18n)

  # AI ISA Assistant module
  ai_isa_assistant_server("ai_isa_mod", project_data, i18n, event_bus, autosave_enabled, user_level, session)

  # ISA data entry module (Standard Entry)
  isa_data <- isaDataEntryServer("isa_module", project_data, event_bus)

  # CLD visualization
  cld_viz_server("cld_visual", project_data, i18n)
  
  # Analysis modules
  analysis_metrics_server("analysis_met", project_data, i18n)
  analysis_loops_server("analysis_loop", project_data, i18n)
  analysis_leverage_server("analysis_lev", project_data, i18n)
  analysis_bot_server("analysis_b", project_data, i18n)
  analysis_simplify_server("analysis_simp", project_data, i18n)
  
  # Response & validation modules
  response_measures_server("resp_meas", project_data, i18n)
  scenario_builder_server("scenario_builder", project_data, i18n)
  response_validation_server("resp_val", project_data)

  # Import Data module
  import_data_server("import_data_mod", project_data, i18n, session, event_bus)

  # Export & Reports module (simple)
  export_reports_server("export_reports_mod", project_data, i18n)

  # Prepare Report module (comprehensive)
  prepare_report_server("prep_report", project_data, i18n)

  # ========== REACTIVE DATA PIPELINE ==========
  # Setup event-based reactive pipeline for automatic data propagation
  # ISA changes → auto-regenerate CLD → auto-invalidate analysis
  setup_reactive_pipeline(project_data, event_bus)

  # ========== DASHBOARD ==========
  # Dashboard logic extracted to server/dashboard.R for better maintainability

  setup_dashboard_rendering(input, output, session, project_data, i18n)

  # ========== SAVE/LOAD PROJECT ==========
  # Project I/O logic extracted to server/project_io.R for better maintainability

  setup_project_io_handlers(input, output, session, project_data, i18n)
  
  # ========== EXPORT HANDLERS ==========
  # Export logic extracted to server/export_handlers.R for better maintainability

  setup_export_handlers(input, output, session, project_data, i18n)

  # ========== REPORT GENERATION ==========

  # Report status output

}

# Note: Report generation functions now loaded from functions/report_generation.R

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server, enableBookmarking = "url")
