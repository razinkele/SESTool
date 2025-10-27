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

source("global.R", local = TRUE)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Add tooltip to menu items via JavaScript
add_menu_tooltip <- function(menu_item, tooltip_text) {
  menu_item$children[[1]]$attribs$`data-tooltip` <- tooltip_text
  return(menu_item)
}

# Add tooltip to submenu items
add_submenu_tooltip <- function(submenu_item, tooltip_text) {
  submenu_item$children[[1]]$attribs$`data-tooltip` <- tooltip_text
  return(submenu_item)
}

# ============================================================================
# SOURCE MODULES
# ============================================================================

source("modules/entry_point_module.R", local = TRUE)  # Entry Point guidance system
source("modules/create_ses_module.R", local = TRUE)  # NEW: Consolidated Create SES module
source("modules/template_ses_module.R", local = TRUE)  # NEW: Template-based SES creation
source("modules/ai_isa_assistant_module.R", local = TRUE)  # AI-Assisted ISA Creation
source("modules/isa_data_entry_module.R", local = TRUE)  # Standard ISA Data Entry
source("modules/pims_module.R", local = TRUE)
source("modules/pims_stakeholder_module.R", local = TRUE)
source("modules/cld_visualization_module.R", local = TRUE)
source("modules/analysis_tools_module.R", local = TRUE)
source("modules/response_module.R", local = TRUE)
source("modules/scenario_builder_module.R", local = TRUE)  # Scenario Builder
# source("modules/response_validation_module.R", local = TRUE)  # Not implemented yet

# ============================================================================
# UI
# ============================================================================

ui <- dashboardPage(
  
  # ========== HEADER ==========
  dashboardHeader(
    title = "MarineSABRES SES Toolbox",
    titleWidth = 300,

    # Settings button for language selector
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        id = "open_settings_modal",
        icon("globe"),
        textOutput("current_language_display", inline = TRUE),
        style = "cursor: pointer;"
      )
    ),

    # User info and help
    tags$li(
      class = "dropdown",
      tags$a(
        href = "user_guide.html",
        target = "_blank",
        icon("question-circle"),
        "Help",
        style = "cursor: pointer;"
      )
    ),

    # About button
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        id = "open_about_modal",
        icon("info-circle"),
        "About",
        style = "cursor: pointer;"
      )
    ),

    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        icon("user"),
        textOutput("user_info", inline = TRUE)
      )
    )
  ),
  
  # ========== SIDEBAR ==========
  dashboardSidebar(
    width = 300,

    sidebarMenu(
      id = "sidebar_menu",

      add_menu_tooltip(
        menuItem(
          i18n$t("Getting Started"),
          tabName = "entry_point",
          icon = icon("compass")
        ),
        "Guided entry point to find the right tools for your marine management needs"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("Dashboard"),
          tabName = "dashboard",
          icon = icon("dashboard")
        ),
        "Overview of your project status and key metrics"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("PIMS Module"),
          tabName = "pims",
          icon = icon("project-diagram"),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Project Setup"), tabName = "pims_project"),
            "Define project goals, scope, and basic information"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Stakeholders"), tabName = "pims_stakeholders"),
            "Identify and manage stakeholders and their interests"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Resources & Risks"), tabName = "pims_resources"),
            "Track project resources, timeline, and potential risks"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Data Management"), tabName = "pims_data"),
            "Manage data sources, quality, and documentation"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Evaluation"), tabName = "pims_evaluation"),
            "Evaluate project progress and outcomes"
          )
        ),
        "Project Information Management System for planning and tracking"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("Create SES"),
          tabName = "create_ses",
          icon = icon("layer-group"),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Choose Method"), tabName = "create_ses_choose"),
            "Select how you want to create your Social-Ecological System"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Standard Entry"), tabName = "create_ses_standard"),
            "Traditional form-based ISA data entry"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("AI Assistant"), tabName = "create_ses_ai"),
            "Guided question-based SES creation"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Template-Based"), tabName = "create_ses_template"),
            "Start from pre-built SES templates"
          )
        ),
        "Create your Social-Ecological System using structured methods"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("CLD Visualization"),
          tabName = "cld_viz",
          icon = icon("project-diagram")
        ),
        "Interactive Causal Loop Diagram visualization of your SES network"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("Analysis Tools"),
          tabName = "analysis",
          icon = icon("chart-line"),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Network Metrics"), tabName = "analysis_metrics"),
            "Calculate centrality, density, and other network statistics"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Loop Detection"), tabName = "analysis_loops"),
            "Identify feedback loops and causal pathways in your network"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("BOT Analysis"), tabName = "analysis_bot"),
            "Behavior Over Time analysis and temporal dynamics"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Simplification"), tabName = "analysis_simplify"),
            "Simplify complex networks while preserving key structures"
          )
        ),
        "Advanced network analysis and metrics tools for your SES model"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("Response & Validation"),
          tabName = "response",
          icon = icon("tasks"),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Response Measures"), tabName = "response_measures"),
            "Define and design management responses and interventions"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Scenario Builder"), tabName = "response_scenarios"),
            "Build and compare alternative future scenarios"
          ),
          add_submenu_tooltip(
            menuSubItem(i18n$t("Validation"), tabName = "response_validation"),
            "Validate model structure and behavior with stakeholders"
          )
        ),
        "Design response measures, build scenarios, and validate your model"
      ),

      add_menu_tooltip(
        menuItem(
          i18n$t("Export Data"),
          tabName = "export",
          icon = icon("download")
        ),
        "Export data and generate comprehensive analysis reports"
      ),
      
      hr(),
      
      # Progress indicator (temporarily disabled for debugging)
      # div(
      #   style = "padding: 15px;",
      #   h5("Project Progress"),
      #   progressBar(
      #     id = "project_progress",
      #     value = 0,
      #     total = 100,
      #     display_pct = TRUE,
      #     status = "info"
      #   )
      # ),
      
      # Quick actions
      div(
        style = "padding: 15px;",
        h5("Quick Actions"),
        actionButton(
          "save_project",
          i18n$t("Save Project"),
          icon = icon("save"),
          class = "btn-primary btn-block",
          title = i18n$t("Save your current project data, including all PIMS, ISA entries, and analysis results")
        ),
        bsTooltip(
          id = "save_project",
          title = i18n$t("Save your current project data, including all PIMS, ISA entries, and analysis results"),
          placement = "right",
          trigger = "hover"
        ),
        actionButton(
          "load_project",
          i18n$t("Load Project"),
          icon = icon("folder-open"),
          class = "btn-secondary btn-block",
          title = i18n$t("Load a previously saved project")
        ),
        bsTooltip(
          id = "load_project",
          title = i18n$t("Load a previously saved project"),
          placement = "right",
          trigger = "hover"
        )
      )
    )
  ),
  
  # ========== BODY ==========
  dashboardBody(

    # Custom CSS and JavaScript
    tags$head(
      tags$title("MarineSABRES SES Toolbox"),
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "isa-panels-fix.css"),
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
      ")),
      tags$script(HTML("
        $(document).ready(function() {
          // Add tooltips to menu items using data-tooltip attributes
          // This ensures tooltips work even after dynamic updates
          Shiny.addCustomMessageHandler('updateTooltips', function(message) {
            $('.sidebar-menu li a[data-toggle=\"tooltip\"]').tooltip();
          });

          // Open settings modal when clicking the language selector
          $('#open_settings_modal').on('click', function(e) {
            e.preventDefault();
            Shiny.setInputValue('show_settings_modal', Math.random());
          });

          // Show persistent loading overlay for language change
          Shiny.addCustomMessageHandler('showLanguageLoading', function(message) {
            // Remove any existing overlay
            $('#language-loading-overlay').remove();

            // Create new overlay
            var overlay = $('<div id=\"language-loading-overlay\" class=\"active\">' +
              '<div class=\"loading-spinner\"><i class=\"fa fa-spinner fa-spin\"></i></div>' +
              '<div class=\"loading-message\"><i class=\"fa fa-globe\"></i> ' + message.text + '</div>' +
              '<div class=\"loading-submessage\">Please wait while the application reloads...</div>' +
              '</div>');

            // Append to body
            $('body').append(overlay);
          });
        });
      "))
    ),

    # Enable shinyjs
    useShinyjs(),

    # Force ISA input styling
    tags$script(HTML("
      // Function to fix ISA input styling - minimal approach
      function forceISAInputStyling() {
        // Fix inputs and textareas with full styling
        var inputSelectors = [
          '#isa_module-gb_entries input',
          '#isa_module-gb_entries textarea',
          '#isa_module-es_entries input',
          '#isa_module-es_entries textarea',
          '#isa_module-mpf_entries input',
          '#isa_module-mpf_entries textarea',
          '#isa_module-p_entries input',
          '#isa_module-p_entries textarea',
          '#isa_module-a_entries input',
          '#isa_module-a_entries textarea',
          '#isa_module-d_entries input',
          '#isa_module-d_entries textarea',
          '.isa-entry-panel input',
          '.isa-entry-panel textarea'
        ].join(', ');

        $(inputSelectors).each(function() {
          $(this).css({
            'color': '#000000',
            'background-color': '#ffffff',
            'opacity': '1',
            '-webkit-text-fill-color': '#000000',
            'filter': 'none'
          });
        });

        // Minimal fix for selects - just color and opacity, no borders or fonts
        var selectSelectors = [
          '#isa_module-gb_entries select',
          '#isa_module-es_entries select',
          '#isa_module-mpf_entries select',
          '#isa_module-p_entries select',
          '#isa_module-a_entries select',
          '#isa_module-d_entries select',
          '.isa-entry-panel select'
        ].join(', ');

        $(selectSelectors).each(function() {
          $(this).css({
            'color': '#000000',
            'background-color': '#ffffff',
            'opacity': '1',
            'filter': 'none'
          });
        });

        // CRITICAL: Remove recalculating class that makes things look gray
        $('#isa_module-gb_entries, #isa_module-es_entries, #isa_module-mpf_entries, #isa_module-p_entries, #isa_module-a_entries, #isa_module-d_entries').removeClass('recalculating');
        $('.isa-entry-panel').closest('.recalculating').removeClass('recalculating');
      }

      // Run on page load
      $(document).ready(function() {
        forceISAInputStyling();

        // Re-run whenever DOM changes (for dynamically added panels)
        var observer = new MutationObserver(function(mutations) {
          forceISAInputStyling();
        });

        // Observe all ISA entries containers
        var targets = ['gb_entries', 'es_entries', 'mpf_entries', 'p_entries', 'a_entries', 'd_entries'];
        var prefixes = ['isa_module', 'isa_data_entry'];
        prefixes.forEach(function(prefix) {
          targets.forEach(function(id) {
            var element = document.getElementById(prefix + '-' + id);
            if (element) {
              observer.observe(element, { childList: true, subtree: true });
            }
          });
        });

        // Also run every 500ms for the first 5 seconds (ensure it catches everything)
        var counter = 0;
        var interval = setInterval(function() {
          forceISAInputStyling();
          counter++;
          if (counter >= 10) clearInterval(interval);
        }, 500);
      });
    ")),

    tabItems(

      # ==================== ENTRY POINT (GETTING STARTED) ====================
      tabItem(tabName = "entry_point", entry_point_ui("entry_pt")),

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
            uiOutput("project_overview_ui")
          ),

          # Quick access
          box(
            title = i18n$t("Quick Access"),
            status = "info",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            h4(i18n$t("Recent Activities")),
            uiOutput("recent_activities_ui")
          )
        ),

        fluidRow(
          # Mini CLD preview
          box(
            title = i18n$t("CLD Preview"),
            status = "success",
            solidHeader = TRUE,
            width = 12,
            height = 500,
            conditionalPanel(
              condition = "output.has_cld_data",
              visNetworkOutput("dashboard_network_preview", height = "450px")
            ),
            conditionalPanel(
              condition = "!output.has_cld_data",
              div(
                style = "text-align: center; padding: 100px 20px;",
                icon("project-diagram", class = "fa-4x", style = "color: #ccc; margin-bottom: 20px;"),
                h4(i18n$t("No CLD Generated Yet"), style = "color: #999;"),
                p(i18n$t("Build your Causal Loop Diagram from the ISA data to visualize system connections.")),
                actionButton("dashboard_build_network", i18n$t("Build Network from ISA Data"),
                            icon = icon("network-wired"), class = "btn-primary btn-lg",
                            style = "margin-top: 15px;")
              )
            )
          )
        )
      ),

      # ==================== PIMS MODULE ====================
      tabItem(tabName = "pims_project", pims_project_ui("pims_proj")),
      tabItem(tabName = "pims_stakeholders", pimsStakeholderUI("pims_stake")),
      tabItem(tabName = "pims_resources", pims_resources_ui("pims_res")),
      tabItem(tabName = "pims_data", pims_data_ui("pims_dm")),
      tabItem(tabName = "pims_evaluation", pims_evaluation_ui("pims_eval")),

      # ==================== CREATE SES ====================
      # Choose Method
      tabItem(tabName = "create_ses_choose", create_ses_ui("create_ses_main")),

      # Standard Entry
      tabItem(tabName = "create_ses_standard", isaDataEntryUI("isa_module")),

      # AI Assistant
      tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod")),

      # Template-Based
      tabItem(tabName = "create_ses_template", template_ses_ui("template_ses")),

      # ==================== CLD VISUALIZATION ====================
      tabItem(tabName = "cld_viz", cld_viz_ui("cld_visual")),
      
      # ==================== ANALYSIS ====================
      tabItem(tabName = "analysis_metrics", analysis_metrics_ui("analysis_met")),
      tabItem(tabName = "analysis_loops", analysis_loops_ui("analysis_loop")),
      tabItem(tabName = "analysis_bot", analysis_bot_ui("analysis_b")),
      tabItem(tabName = "analysis_simplify", analysis_simplify_ui("analysis_simp")),
      
      # ==================== RESPONSE & VALIDATION ====================
      tabItem(tabName = "response_measures", response_measures_ui("resp_meas")),
      tabItem(tabName = "response_scenarios", scenario_builder_ui("scenario_builder")),
      tabItem(tabName = "response_validation", response_validation_ui("resp_val")),
      
      # ==================== EXPORT ====================
      tabItem(
        tabName = "export",
        
        fluidRow(
          column(12,
            h2(i18n$t("Export & Reports")),
            p(i18n$t("Export your data, visualizations, and generate comprehensive reports."))
          )
        ),
        
        fluidRow(
          box(
            title = i18n$t("Export Data"),
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            selectInput(
              "export_data_format",
              i18n$t("Select Format:"),
              choices = c("Excel (.xlsx)", "CSV (.csv)", "JSON (.json)",
                         "R Data (.RData)")
            ),

            checkboxGroupInput(
              "export_data_components",
              i18n$t("Select Components:"),
              choices = c(
                "metadata" = i18n$t("Project Metadata"),
                "pims" = i18n$t("PIMS Data"),
                "isa_data" = i18n$t("ISA Data"),
                "cld" = i18n$t("CLD Data"),
                "analysis" = i18n$t("Analysis Results"),
                "responses" = i18n$t("Response Measures")
              ),
              selected = c("metadata", "isa_data", "cld")
            ),

            downloadButton("download_data", i18n$t("Download Data"),
                          class = "btn-primary")
          ),
          
          box(
            title = i18n$t("Export Visualizations"),
            status = "info",
            solidHeader = TRUE,
            width = 6,

            selectInput(
              "export_viz_format",
              i18n$t("Select Format:"),
              choices = c("PNG (.png)", "SVG (.svg)", "HTML (.html)",
                         "PDF (.pdf)")
            ),

            numericInput(
              "export_viz_width",
              i18n$t("Width (pixels):"),
              value = 1200,
              min = 400,
              max = 4000
            ),

            numericInput(
              "export_viz_height",
              i18n$t("Height (pixels):"),
              value = 900,
              min = 300,
              max = 3000
            ),

            downloadButton("download_viz", i18n$t("Download Visualization"),
                          class = "btn-info")
          )
        ),
        
        fluidRow(
          box(
            title = i18n$t("Generate Report"),
            status = "success",
            solidHeader = TRUE,
            width = 12,

            selectInput(
              "report_type",
              i18n$t("Report Type:"),
              choices = c(
                "executive" = i18n$t("Executive Summary"),
                "technical" = i18n$t("Technical Report"),
                "presentation" = i18n$t("Stakeholder Presentation"),
                "full" = i18n$t("Full Project Report")
              )
            ),

            selectInput(
              "report_format",
              i18n$t("Report Format:"),
              choices = c("HTML", "PDF", "Word")
            ),

            checkboxInput(
              "report_include_viz",
              i18n$t("Include Visualizations"),
              value = TRUE
            ),

            checkboxInput(
              "report_include_data",
              i18n$t("Include Data Tables"),
              value = TRUE
            ),

            actionButton(
              "generate_report",
              i18n$t("Generate Report"),
              icon = icon("file-alt"),
              class = "btn-success"
            ),

            uiOutput("report_status")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {

  # ========== REACTIVE VALUES ==========

  # Main project data
  project_data <- reactiveVal(init_session_data())

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

  # ========== LANGUAGE SETTINGS MODAL ==========

  # Show settings modal when button is clicked
  observeEvent(input$show_settings_modal, {
    current_lang <- if(!is.null(i18n$get_translation_language())) {
      i18n$get_translation_language()
    } else {
      "en"
    }

    showModal(modalDialog(
      title = tags$h3(icon("cog"), " Application Settings"),
      size = "m",
      easyClose = TRUE,
      footer = tagList(
        modalButton("Cancel"),
        actionButton("apply_language_change", "Apply Changes", class = "btn-primary", icon = icon("check"))
      ),

      tags$div(
        style = "padding: 20px;",

        tags$h4(icon("globe"), " Interface Language"),
        tags$p("Select your preferred language for the application interface. Click 'Apply Changes' to reload the application with the new language."),
        tags$br(),

        selectInput(
          "settings_language_selector",
          label = tags$strong("Language:"),
          choices = setNames(
            names(AVAILABLE_LANGUAGES),
            sapply(AVAILABLE_LANGUAGES, function(x) paste(x$flag, x$name))
          ),
          selected = current_lang,
          width = "100%"
        ),

        tags$div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          icon("info-circle"),
          tags$strong(" Note: "),
          "The application will reload to apply the language changes. Your current work will be preserved."
        )
      )
    ))
  })

  # Handle Apply button click in settings modal
  observeEvent(input$apply_language_change, {
    req(input$settings_language_selector)

    new_lang <- input$settings_language_selector

    # Update the translator language
    shiny.i18n::update_lang(new_lang, session)
    i18n$set_translation_language(new_lang)

    # Get language name for notifications
    lang_name <- AVAILABLE_LANGUAGES[[new_lang]]$name

    # Close the modal
    removeModal()

    # Show persistent JavaScript loading overlay
    session$sendCustomMessage("showLanguageLoading", list(
      text = paste0("Changing language to ", lang_name, "...")
    ))

    # Log language change
    cat(paste0("[", Sys.time(), "] INFO: Language changed to: ", new_lang, "\n"))

    # Reload the session to apply language changes
    # The overlay will persist until the page actually reloads
    session$reload()
  })

  # ========== ABOUT MODAL ==========

  # Show about modal when button is clicked
  observeEvent(input$open_about_modal, {
    # Read version info
    version_info <- jsonlite::fromJSON("VERSION_INFO.json")

    showModal(modalDialog(
      title = tags$h3(icon("info-circle"), " About MarineSABRES SES Toolbox"),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close"),

      tags$div(
        style = "padding: 20px;",

        # Application Info
        tags$div(
          class = "well",
          tags$h4(icon("cube"), " Application Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Version:")),
              tags$td(
                tags$span(
                  style = "font-size: 18px; color: #3c8dbc; font-weight: bold;",
                  version_info$version
                ),
                tags$span(
                  class = "label label-success",
                  style = "margin-left: 10px;",
                  version_info$status
                )
              )
            ),
            tags$tr(
              tags$td(tags$strong("Release Name:")),
              tags$td(version_info$version_name)
            ),
            tags$tr(
              tags$td(tags$strong("Release Date:")),
              tags$td(version_info$release_date)
            ),
            tags$tr(
              tags$td(tags$strong("Release Type:")),
              tags$td(
                tags$span(
                  class = if(version_info$release_type == "major") "label label-danger"
                        else if(version_info$release_type == "minor") "label label-warning"
                        else "label label-info",
                  version_info$release_type
                )
              )
            )
          )
        ),

        # Features
        tags$div(
          class = "well",
          tags$h4(icon("star"), " Key Features"),
          tags$ul(
            lapply(version_info$features, function(feature) {
              tags$li(feature)
            })
          )
        ),

        # Technical Info
        tags$div(
          class = "well",
          tags$h4(icon("cogs"), " Technical Information"),
          tags$table(
            class = "table table-condensed",
            style = "margin-bottom: 0;",
            tags$tr(
              tags$td(tags$strong("Minimum R Version:")),
              tags$td(version_info$minimum_r_version)
            ),
            tags$tr(
              tags$td(tags$strong("Current R Version:")),
              tags$td(paste(R.version$major, R.version$minor, sep = "."))
            ),
            tags$tr(
              tags$td(tags$strong("Platform:")),
              tags$td(R.version$platform)
            ),
            tags$tr(
              tags$td(tags$strong("Git Branch:")),
              tags$td(version_info$build_info$git_branch)
            )
          )
        ),

        # Contributors
        tags$div(
          class = "well",
          tags$h4(icon("users"), " Contributors"),
          tags$ul(
            lapply(version_info$contributors, function(contributor) {
              tags$li(contributor)
            })
          )
        ),

        # Links
        tags$div(
          class = "alert alert-info",
          icon("book"),
          tags$strong(" Documentation: "),
          tags$a(
            href = "#",
            onclick = "window.open('user_guide.html', '_blank'); return false;",
            "User Guide",
            style = "margin-right: 15px;"
          ),
          tags$a(
            href = "#",
            onclick = sprintf("window.open('%s', '_blank'); return false;", version_info$changelog_url),
            "Changelog"
          )
        )
      )
    ))
  })

  # ========== CALL MODULE SERVERS ==========

  # Entry Point module - pass session for sidebar navigation
  entry_point_server("entry_pt", project_data, parent_session = session)

  # PIMS modules
  pims_project_data <- pims_project_server("pims_proj", project_data)
  pims_stakeholders_data <- pimsStakeholderServer("pims_stake", project_data)
  pims_resources_data <- pims_resources_server("pims_res", project_data)
  pims_data_data <- pims_data_server("pims_dm", project_data)
  pims_evaluation_data <- pims_evaluation_server("pims_eval", project_data)
  
  # ==================== CREATE SES MODULES ====================
  # Main Create SES module (method selector)
  create_ses_server("create_ses_main", project_data, session)

  # Template-based SES module
  template_ses_server("template_ses", project_data, session)

  # AI ISA Assistant module
  ai_isa_assistant_server("ai_isa_mod", project_data)

  # ISA data entry module (Standard Entry)
  isa_data <- isaDataEntryServer("isa_module", project_data)

  # CLD visualization
  cld_viz_server("cld_visual", project_data)
  
  # Analysis modules
  analysis_metrics_server("analysis_met", project_data)
  analysis_loops_server("analysis_loop", project_data)
  analysis_bot_server("analysis_b", project_data)
  analysis_simplify_server("analysis_simp", project_data)
  
  # Response & validation modules
  response_measures_server("resp_meas", project_data)
  scenario_builder_server("scenario_builder", project_data)
  response_validation_server("resp_val", project_data)
  
  # ========== DASHBOARD ==========
  
  # Value boxes
  output$total_elements_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      isa_data <- safe_get_nested(data, "data", "isa_data", default = list())
      n_elements <- length(unlist(isa_data))

      valueBox(n_elements, i18n$t("Total Elements"), icon = icon("circle"), color = "blue")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  output$total_connections_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      n_connections <- 0
      adj_matrices <- safe_get_nested(data, "data", "isa_data", "adjacency_matrices", default = list())

      if(length(adj_matrices) > 0) {
        for(mat_name in names(adj_matrices)) {
          mat <- adj_matrices[[mat_name]]
          if(!is.null(mat) && is.matrix(mat)) {
            n_connections <- n_connections + sum(!is.na(mat) & mat != "", na.rm = TRUE)
          }
        }
      }

      valueBox(n_connections, i18n$t("Connections"), icon = icon("arrow-right"), color = "green")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  output$loops_detected_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      loops <- safe_get_nested(data, "data", "cld", "loops", default = data.frame())
      n_loops <- if(is.data.frame(loops)) nrow(loops) else 0

      valueBox(n_loops, i18n$t("Loops Detected"), icon = icon("refresh"), color = "orange")
    }, error = function(e) {
      valueBox(0, "Error", icon = icon("times"), color = "red")
    })
  })

  output$completion_box <- renderValueBox({
    tryCatch({
      data <- project_data()
      completion <- 0

      # Check if ISA data exists (6 components × 6.67% = 40%)
      isa_score <- 0
      if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) isa_score <- isa_score + 6.67
      if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) isa_score <- isa_score + 6.65
      completion <- completion + isa_score

      # Check if connections exist (30%)
      adj_matrices <- safe_get_nested(data, "data", "isa_data", "adjacency_matrices", default = list())
      n_connections <- 0
      if (length(adj_matrices) > 0) {
        for (mat_name in names(adj_matrices)) {
          mat <- adj_matrices[[mat_name]]
          if (!is.null(mat) && is.matrix(mat)) {
            n_connections <- n_connections + sum(!is.na(mat) & mat != "", na.rm = TRUE)
          }
        }
      }
      if (n_connections > 0) completion <- completion + 30

      # Check if CLD generated (30%)
      if (!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
        completion <- completion + 30
      }

      completion <- round(completion)

      valueBox(
        paste0(completion, "%"),
        i18n$t("Completion"),
        icon = icon("check-circle"),
        color = if(completion >= 75) "green" else if(completion >= 40) "yellow" else "purple"
      )
    }, error = function(e) {
      valueBox("0%", "Error", icon = icon("times"), color = "red")
    })
  })
  
  # Project overview
  output$project_overview_ui <- renderUI({
    tryCatch({
      data <- project_data()

      cat("\nDEBUG: Rendering project_overview_ui\n")
      cat("DEBUG: ISA data structure:\n")
      cat("  - goods_benefits rows:", nrow(data$data$isa_data$goods_benefits %||% data.frame()), "\n")
      cat("  - ecosystem_services rows:", nrow(data$data$isa_data$ecosystem_services %||% data.frame()), "\n")

      tagList(
      p(strong(i18n$t("Project ID:")), data$project_id),
      p(strong(i18n$t("Created:")), format_date_display(data$created_at)),
      p(strong(i18n$t("Last Modified:")), format_date_display(data$last_modified)),
      p(strong(i18n$t("Demonstration Area:")), data$data$metadata$da_site %||% i18n$t("Not set")),
      p(strong(i18n$t("Focal Issue:")), data$data$metadata$focal_issue %||% i18n$t("Not defined")),
      hr(),
      h4(i18n$t("Status Summary")),
      p(i18n$t("PIMS Setup:"), " ", if(length(data$data$pims) > 0) i18n$t("Complete") else i18n$t("Incomplete")),
      hr(),
      h5(i18n$t("ISA Data Entry:")),
      tags$ul(style = "list-style-type: none; padding-left: 10px;",
        tags$li(
          icon(if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Goods & Benefits:"), " ",
          if(!is.null(data$data$isa_data$goods_benefits)) nrow(data$data$isa_data$goods_benefits) else 0, " ", i18n$t("entries")),
        tags$li(
          icon(if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Ecosystem Services:"), " ",
          if(!is.null(data$data$isa_data$ecosystem_services)) nrow(data$data$isa_data$ecosystem_services) else 0, " ", i18n$t("entries")),
        tags$li(
          icon(if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Marine Processes:"), " ",
          if(!is.null(data$data$isa_data$marine_processes)) nrow(data$data$isa_data$marine_processes) else 0, " ", i18n$t("entries")),
        tags$li(
          icon(if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Pressures:"), " ",
          if(!is.null(data$data$isa_data$pressures)) nrow(data$data$isa_data$pressures) else 0, " ", i18n$t("entries")),
        tags$li(
          icon(if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Activities:"), " ",
          if(!is.null(data$data$isa_data$activities)) nrow(data$data$isa_data$activities) else 0, " ", i18n$t("entries")),
        tags$li(
          icon(if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "check" else "times",
               class = if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) "text-success" else "text-muted"),
          " ", i18n$t("Drivers:"), " ",
          if(!is.null(data$data$isa_data$drivers)) nrow(data$data$isa_data$drivers) else 0, " ", i18n$t("entries"))
      ),
      hr(),
      p(i18n$t("CLD Generated:"), " ", if(!is.null(data$data$cld$nodes)) i18n$t("Yes") else i18n$t("No"))
    )
    }, error = function(e) {
      cat("\n!!! ERROR in project_overview_ui:\n")
      cat("Error message:", conditionMessage(e), "\n")
      cat("Call stack:\n")
      print(sys.calls())
      # Return error message to UI
      tagList(
        p(style = "color: red;", "Error rendering dashboard:", conditionMessage(e))
      )
    })
  })

  # Check if CLD data exists
  output$has_cld_data <- reactive({
    nodes <- project_data()$data$cld$nodes
    !is.null(nodes) && nrow(nodes) > 0 && all(c("id", "label") %in% names(nodes))
  })
  outputOptions(output, "has_cld_data", suspendWhenHidden = FALSE)

  # Mini CLD preview on dashboard
  output$dashboard_network_preview <- renderVisNetwork({
    nodes <- project_data()$data$cld$nodes
    edges <- project_data()$data$cld$edges

    # Check if CLD has been generated
    if(is.null(nodes) || nrow(nodes) == 0) {
      return(NULL)
    }

    # Validate nodes have required columns for visNetwork
    required_cols <- c("id", "label")
    if(!all(required_cols %in% names(nodes))) {
      return(NULL)
    }

    visNetwork(nodes, edges, height = "100%") %>%
      visIgraphLayout(layout = "layout_with_fr") %>%
      visOptions(
        highlightNearest = TRUE,
        nodesIdSelection = FALSE
      ) %>%
      visInteraction(
        navigationButtons = FALSE,
        hover = TRUE
      )
  })

  # Build network button handler on dashboard
  observeEvent(input$dashboard_build_network, {
    # Navigate to CLD visualization tab
    updateTabItems(session, "sidebar_menu", "cld_viz")
    showNotification("Navigate to CLD Visualization to build your network", type = "message", duration = 3)
  })
  
  # ========== SAVE/LOAD PROJECT ==========
  
  observeEvent(input$save_project, {
    showModal(modalDialog(
      title = "Save Project",
      textInput("save_project_name", "Project Name:", 
               value = project_data()$project_id),
      footer = tagList(
        modalButton("Cancel"),
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
      title = "Load Project",
      fileInput("load_project_file", "Choose RDS File:",
               accept = ".rds"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_load", "Load")
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
        require(igraph)

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
  output$report_status <- renderUI({
    tags$div(
      style = "margin-top: 20px;",
      id = "report_status_div"
    )
  })

  # Generate report button
  observeEvent(input$generate_report, {
    # Show progress
    showModal(modalDialog(
      title = "Generating Report",
      "Please wait while your report is being generated...",
      footer = NULL,
      easyClose = FALSE
    ))

    data <- project_data()
    report_type <- input$report_type
    report_format <- input$report_format
    include_viz <- input$report_include_viz
    include_data <- input$report_include_data

    tryCatch({
      # Create a temporary Rmd file
      rmd_file <- tempfile(fileext = ".Rmd")

      # Generate report content based on type
      report_content <- generate_report_content(
        data = data,
        report_type = report_type,
        include_viz = include_viz,
        include_data = include_data
      )

      writeLines(report_content, rmd_file)

      # Render the report
      output_format <- switch(report_format,
        "HTML" = "html_document",
        "PDF" = "pdf_document",
        "Word" = "word_document"
      )

      output_file <- tempfile(fileext = switch(report_format,
        "HTML" = ".html",
        "PDF" = ".pdf",
        "Word" = ".docx"
      ))

      rmarkdown::render(
        input = rmd_file,
        output_format = output_format,
        output_file = output_file,
        quiet = TRUE
      )

      # Copy to downloads or show success
      removeModal()

      showModal(modalDialog(
        title = "Report Generated Successfully",
        tags$div(
          p("Your report has been generated successfully."),
          downloadButton("download_report_file", "Download Report", class = "btn-success")
        ),
        footer = modalButton("Close")
      ))

      # Store output file path for download
      output$download_report_file <- downloadHandler(
        filename = function() {
          paste0("MarineSABRES_Report_", report_type, "_", Sys.Date(),
                 switch(report_format,
                   "HTML" = ".html",
                   "PDF" = ".pdf",
                   "Word" = ".docx"))
        },
        content = function(file) {
          file.copy(output_file, file)
        }
      )

    }, error = function(e) {
      removeModal()
      showNotification(paste("Error generating report:", e$message), type = "error", duration = 10)
    })
  })

}

# ============================================================================
# HELPER FUNCTION FOR REPORT GENERATION
# ============================================================================

generate_report_content <- function(data, report_type, include_viz, include_data) {

  header <- paste0("---\ntitle: 'MarineSABRES SES Analysis Report'\n",
                   "subtitle: '", report_type, " Report'\n",
                   "date: '", format(Sys.Date(), "%B %d, %Y"), "'\n",
                   "output:\n  html_document:\n    toc: true\n    toc_float: true\n",
                   "---\n\n")

  intro <- paste0("# Project Overview\n\n",
                  "**Project:** ", data$project_name, "\n\n",
                  "**Demonstration Area:** ", data$data$metadata$da_site %||% "Not specified", "\n\n",
                  "**Focal Issue:** ", data$data$metadata$focal_issue %||% "Not defined", "\n\n",
                  "**Created:** ", format(data$created_at, "%Y-%m-%d"), "\n\n",
                  "**Last Modified:** ", format(data$last_modified, "%Y-%m-%d"), "\n\n")

  if(report_type == "executive") {
    content <- paste0(
      "# Executive Summary\n\n",
      "This report provides a high-level overview of the social-ecological system analysis.\n\n",
      "## Key Findings\n\n",
      "- System elements identified: ", length(unlist(data$data$isa_data)), "\n",
      "- Feedback loops detected: ", nrow(data$data$cld$loops %||% data.frame()), "\n",
      "- Stakeholders involved: ", nrow(data$data$pims$stakeholders %||% data.frame()), "\n\n"
    )
  } else if(report_type == "technical") {
    content <- paste0(
      "# Technical Analysis\n\n",
      "## DAPSI(W)R(M) Framework Elements\n\n",
      "### Drivers\n\n",
      if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$drivers), " drivers in the system.\n\n")
      } else {
        "No drivers data available.\n\n"
      },
      "### Activities\n\n",
      if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$activities), " activities.\n\n")
      } else {
        "No activities data available.\n\n"
      },
      "### Pressures\n\n",
      if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$pressures), " pressures.\n\n")
      } else {
        "No pressures data available.\n\n"
      }
    )
  } else if(report_type == "presentation") {
    content <- paste0(
      "# Stakeholder Presentation\n\n",
      "## System Overview\n\n",
      "This analysis examines the social-ecological system in ",
      data$data$metadata$da_site %||% "the study area", ".\n\n",
      "## Key Insights\n\n",
      "- Multiple interconnected system components\n",
      "- Feedback loops influencing system behavior\n",
      "- Management opportunities identified\n\n"
    )
  } else {
    # Full report
    content <- paste0(
      "# Complete System Analysis\n\n",
      "## ISA Data Entry Results\n\n",
      "### Goods and Benefits\n\n",
      if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) {
        paste0("```{r echo=FALSE}\n",
               "knitr::kable(head(data$data$isa_data$goods_benefits))\n",
               "```\n\n")
      } else {
        "No data available.\n\n"
      },
      "## Causal Loop Diagram\n\n",
      if(!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
        paste0("The CLD contains ", nrow(data$data$cld$nodes), " nodes and ",
               nrow(data$data$cld$edges %||% data.frame()), " connections.\n\n")
      } else {
        "No CLD generated yet.\n\n"
      },
      "## Stakeholder Analysis\n\n",
      if(!is.null(data$data$pims$stakeholders) && nrow(data$data$pims$stakeholders) > 0) {
        paste0(nrow(data$data$pims$stakeholders), " stakeholders identified.\n\n")
      } else {
        "No stakeholder data available.\n\n"
      }
    )
  }

  footer <- paste0("\n\n---\n\n",
                   "*Report generated by MarineSABRES SES Tool*\n\n",
                   "*", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n")

  return(paste0(header, intro, content, footer))
}

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server)
