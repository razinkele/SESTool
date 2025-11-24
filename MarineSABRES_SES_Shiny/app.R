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

# ============================================================================
# SOURCE MODULES
# ============================================================================

source("modules/entry_point_module.R", local = TRUE)  # Entry Point guidance system
source("modules/create_ses_module.R", local = TRUE)  # NEW: Consolidated Create SES module
source("modules/template_ses_module.R", local = TRUE)  # NEW: Template-based SES creation
source("modules/ai_isa_assistant_module.R", local = TRUE)  # AI-Assisted ISA Creation
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
    width = 300,

    # Dynamic sidebar menu that updates when language changes
    sidebarMenuOutput("dynamic_sidebar")
  ),
  
  # ========== BODY ==========
  dashboardBody(

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
            h2(i18n$t("MarineSABRES Social-Ecological Systems Analysis Tool")),
            p(i18n$t("Welcome to the computer-assisted SES creation and analysis platform."))
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
            title = i18n$t("Project Overview"),
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            tags$div(
              style = "overflow-y: auto; max-height: 330px; padding: 5px;",
              uiOutput("project_overview_ui")
            )
          ),

          # Status summary
          box(
            title = i18n$t("Status Summary"),
            status = "success",
            solidHeader = TRUE,
            width = 6,
            height = 400,

            # Project status indicators
            tags$div(
              style = "overflow-y: auto; max-height: 330px; padding: 5px;",

              # ISA Data Status
              tags$div(
                style = "margin-bottom: 10px; padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("database"), " ", i18n$t("ISA Data Status")),
                uiOutput("status_isa_elements"),
                uiOutput("status_isa_connections")
              ),

              # CLD Status
              tags$div(
                style = "margin-bottom: 10px; padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("project-diagram"), " ", i18n$t("CLD Status")),
                uiOutput("status_cld_nodes"),
                uiOutput("status_cld_edges")
              ),

              # Analysis Status
              tags$div(
                style = "padding: 8px; background: #f8f9fa; border-radius: 5px;",
                tags$h5(style = "margin-bottom: 8px; font-size: 14px;",
                  icon("chart-line"), " ", i18n$t("Analysis Status")),
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
      tabItem(tabName = "analysis_metrics", analysis_metrics_ui("analysis_met")),
      tabItem(tabName = "analysis_loops", analysis_loops_ui("analysis_loop")),
      tabItem(tabName = "analysis_leverage", analysis_leverage_ui("analysis_lev")),
      tabItem(tabName = "analysis_bot", analysis_bot_ui("analysis_b")),
      tabItem(tabName = "analysis_simplify", analysis_simplify_ui("analysis_simp")),
      
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
      tabItem(tabName = "prepare_report", prepare_report_ui("prep_report"))
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {

  cat("\n")
  cat("=====================================\n")
  cat("APP RESTARTED - NEW SESSION STARTING\n")
  cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Report generation functions loaded:", exists("generate_report_content"), "\n")
  cat("=====================================\n")
  cat("\n")

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
      footer = modalButton(i18n$t("Close")),

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
        i18n$t("Bookmark restored successfully!")
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

  # ========== DYNAMIC SIDEBAR MENU ==========
  # Renders sidebar menu dynamically based on current language and user level
  # This allows the menu to update when language or user level changes
  output$dynamic_sidebar <- renderMenu({
    tryCatch({
      cat("[SIDEBAR] Rendering dynamic sidebar...\n")
      cat(sprintf("[SIDEBAR] User level: %s\n", user_level()))
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

  # Load language from query parameter on startup
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query$language) && query$language %in% names(AVAILABLE_LANGUAGES)) {
      i18n$set_translation_language(query$language)
      cat(sprintf("[LANGUAGE] Loaded from URL: %s\n", query$language))
    }
  })

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
  analysis_metrics_server("analysis_met", project_data)
  analysis_loops_server("analysis_loop", project_data, i18n)
  analysis_leverage_server("analysis_lev", project_data)
  analysis_bot_server("analysis_b", project_data)
  analysis_simplify_server("analysis_simp", project_data)
  
  # Response & validation modules
  response_measures_server("resp_meas", project_data, i18n)
  scenario_builder_server("scenario_builder", project_data, i18n)
  response_validation_server("resp_val", project_data)

  # Import Data module
  import_data_server("import_data_mod", project_data, i18n, session, event_bus)

  # Export & Reports module (simple)
  export_reports_server("export_reports_mod", project_data, i18n)

  # Prepare Report module (comprehensive)
  prepare_report_server("prep_report", project_data)

  # ========== REACTIVE DATA PIPELINE ==========
  # Setup event-based reactive pipeline for automatic data propagation
  # ISA changes → auto-regenerate CLD → auto-invalidate analysis
  setup_reactive_pipeline(project_data, event_bus)

  # ========== DASHBOARD ==========
  # Dashboard logic extracted to server/dashboard.R for better maintainability

  setup_dashboard_rendering(input, output, session, project_data, i18n)

  # ========== SAVE/LOAD PROJECT ==========
  
  observeEvent(input$save_project, {
    showModal(modalDialog(
      title = "Save Project",
      textInput("save_project_name", "Project Name:",
               value = project_data()$project_id),
      footer = tagList(
        modalButton(i18n$t("Cancel")),
        downloadButton("confirm_save", "Save")
      )
    ))
  })
  
  output$confirm_save <- downloadHandler(
    filename = function() {
      # Sanitize filename to prevent path traversal
      safe_name <- sanitize_filename(input$save_project_name)
      paste0(safe_name, "_", Sys.Date(), ".rds")
    },
    content = function(file) {
      tryCatch({
        # Validate data structure before saving
        data <- project_data()
        if (!is.list(data) || !all(c("project_id", "data") %in% names(data))) {
          showNotification("Error: Invalid project data structure",
                          type = "error", duration = 10)
          return(NULL)
        }

        # Save with error handling
        saveRDS(data, file)

        # Verify saved file
        if (!file.exists(file) || file.size(file) == 0) {
          showNotification("Error: File save failed or file is empty",
                          type = "error", duration = 10)
          return(NULL)
        }

        removeModal()
        showNotification("Project saved successfully!", type = "message")

      }, error = function(e) {
        showNotification(
          paste("Error saving project:", e$message),
          type = "error",
          duration = 10
        )
      })
    }
  )
  
  observeEvent(input$load_project, {
    showModal(modalDialog(
      title = i18n$t("Load Project"),
      fileInput("load_project_file", i18n$t("Choose RDS File:"),
               accept = ".rds"),
      footer = tagList(
        modalButton(i18n$t("Cancel")),
        actionButton("confirm_load", i18n$t("Load"))
      )
    ))
  })
  
  observeEvent(input$confirm_load, {
    req(input$load_project_file)

    tryCatch({
      # Load RDS file
      loaded_data <- readRDS(input$load_project_file$datapath)

      # Validate project structure
      if (!validate_project_structure(loaded_data)) {
        showNotification(
          "Error: Invalid project file structure. This may not be a valid MarineSABRES project file.",
          type = "error",
          duration = 10
        )
        return()
      }

      # Load validated data
      project_data(loaded_data)

      removeModal()
      showNotification("Project loaded successfully!", type = "message")

    }, error = function(e) {
      showNotification(
        paste("Error loading project:", e$message),
        type = "error",
        duration = 10
      )
    })
  })
  
  # ========== EXPORT HANDLERS ==========
  
  output$download_data <- downloadHandler(
    filename = function() {
      format <- input$export_data_format
      ext <- switch(format,
        "Excel (.xlsx)" = ".xlsx",
        "CSV (.csv)" = ".csv",
        "JSON (.json)" = ".json",
        "R Data (.RData)" = ".RData"
      )
      paste0("MarineSABRES_Data_", Sys.Date(), ext)
    },
    content = function(file) {
      data <- project_data()
      components <- input$export_data_components

      # Prepare export data based on selected components
      export_list <- list()

      if("metadata" %in% components) {
        export_list$metadata <- data$data$metadata
        export_list$project_info <- list(
          project_id = data$project_id,
          project_name = data$project_name,
          created_at = data$created_at,
          last_modified = data$last_modified
        )
      }

      if("pims" %in% components) {
        export_list$pims <- data$data$pims
      }

      if("isa_data" %in% components) {
        export_list$goods_benefits <- data$data$isa_data$goods_benefits
        export_list$ecosystem_services <- data$data$isa_data$ecosystem_services
        export_list$marine_processes <- data$data$isa_data$marine_processes
        export_list$pressures <- data$data$isa_data$pressures
        export_list$activities <- data$data$isa_data$activities
        export_list$drivers <- data$data$isa_data$drivers
        export_list$bot_data <- data$data$isa_data$bot_data
      }

      if("cld" %in% components) {
        export_list$cld_nodes <- data$data$cld$nodes
        export_list$cld_edges <- data$data$cld$edges
        export_list$cld_loops <- data$data$cld$loops
      }

      if("analysis" %in% components) {
        export_list$analysis_results <- data$data$analysis
      }

      if("responses" %in% components) {
        export_list$response_measures <- data$data$responses
      }

      # Export based on format
      format <- input$export_data_format

      if(format == "Excel (.xlsx)") {
        wb <- createWorkbook()

        # Add each component as a worksheet
        for(name in names(export_list)) {
          item <- export_list[[name]]
          if(is.data.frame(item) && nrow(item) > 0) {
            addWorksheet(wb, name)
            writeData(wb, name, item)
          } else if(is.list(item) && !is.data.frame(item)) {
            # Convert list to data frame
            df <- as.data.frame(t(unlist(item)), stringsAsFactors = FALSE)
            addWorksheet(wb, name)
            writeData(wb, name, df)
          }
        }

        saveWorkbook(wb, file, overwrite = TRUE)

      } else if(format == "CSV (.csv)") {
        # For CSV, export the main ISA data
        if("isa_data" %in% components && !is.null(data$data$isa_data$goods_benefits)) {
          write.csv(data$data$isa_data$goods_benefits, file, row.names = FALSE)
        } else {
          write.csv(data.frame(message = "No data to export"), file, row.names = FALSE)
        }

      } else if(format == "JSON (.json)") {
        json_data <- toJSON(export_list, pretty = TRUE, auto_unbox = TRUE)
        writeLines(json_data, file)

      } else if(format == "R Data (.RData)") {
        save(export_list, file = file)
      }

      showNotification("Data exported successfully!", type = "message")
    }
  )
  
  output$download_viz <- downloadHandler(
    filename = function() {
      format <- input$export_viz_format
      ext <- switch(format,
        "PNG (.png)" = ".png",
        "SVG (.svg)" = ".svg",
        "HTML (.html)" = ".html",
        "PDF (.pdf)" = ".pdf"
      )
      paste0("MarineSABRES_CLD_", Sys.Date(), ext)
    },
    content = function(file) {
      data <- project_data()

      # Check if CLD data exists
      if(is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        showNotification("No CLD data to export. Please create a CLD first.", type = "error")
        return(NULL)
      }

      nodes <- data$data$cld$nodes
      edges <- data$data$cld$edges

      format <- input$export_viz_format
      width <- input$export_viz_width
      height <- input$export_viz_height

      if(format == "HTML (.html)") {
        # Create interactive HTML visualization
        viz <- visNetwork(nodes, edges, width = paste0(width, "px"), height = paste0(height, "px")) %>%
          visIgraphLayout(layout = "layout_with_fr") %>%
          visNodes(
            borderWidth = 2,
            font = list(size = 14)
          ) %>%
          visEdges(
            arrows = "to",
            smooth = list(enabled = TRUE, type = "curvedCW")
          ) %>%
          visOptions(
            highlightNearest = list(enabled = TRUE, hover = TRUE),
            nodesIdSelection = TRUE
          ) %>%
          visInteraction(
            navigationButtons = TRUE,
            hover = TRUE,
            zoomView = TRUE
          ) %>%
          visLegend(width = 0.1, position = "right")

        visSave(viz, file)

      } else if(format == "PNG (.png)" || format == "SVG (.svg)" || format == "PDF (.pdf)") {
        # For static exports, create an igraph object and plot
        # Note: igraph is already loaded in global.R

        # Create igraph object
        g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)

        # Set vertex attributes
        V(g)$label <- V(g)$label
        V(g)$color <- V(g)$color
        V(g)$size <- 15

        # Set edge attributes
        E(g)$color <- ifelse(edges$link_type == "positive", "#06D6A0", "#E63946")
        E(g)$arrow.size <- 0.5

        # Open appropriate device
        if(format == "PNG (.png)") {
          png(file, width = width, height = height, res = 150)
        } else if(format == "SVG (.svg)") {
          svg(file, width = width/100, height = height/100)
        } else if(format == "PDF (.pdf)") {
          pdf(file, width = width/100, height = height/100)
        }

        # Plot
        par(mar = c(0, 0, 2, 0))
        plot(g,
             layout = layout_with_fr(g),
             vertex.label.cex = 0.8,
             vertex.label.color = "black",
             vertex.frame.color = "gray",
             edge.curved = 0.2,
             main = "MarineSABRES Causal Loop Diagram")

        # Add legend
        legend("bottomright",
               legend = c("Positive link", "Negative link"),
               col = c("#06D6A0", "#E63946"),
               lty = 1, lwd = 2,
               bty = "n")

        dev.off()
      }

      showNotification("Visualization exported successfully!", type = "message")
    }
  )

  # ========== REPORT GENERATION ==========

  # Report status output

}

# Note: Report generation functions now loaded from functions/report_generation.R

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server, enableBookmarking = "url")
