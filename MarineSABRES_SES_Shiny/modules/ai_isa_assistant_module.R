# modules/ai_isa_assistant_module.R
# AI-Assisted SES Creation Module
# Purpose: Guide users through stepwise questions to build DAPSI(W)R(M) framework

# Load helper modules
source("modules/ai_isa_knowledge_base.R", local = TRUE)
source("modules/connection_review_tabbed.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

ai_isa_assistant_ui <- function(id, i18n) {
  cat(sprintf("[AI ISA UI] UI function called with id: %s at %s\n", id, Sys.time()))
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .ai-chat-container {
          background: #f8f9fa;
          border-radius: 10px;
          padding: 20px;
          margin: 20px 0;
          max-height: 600px;
          overflow-y: auto;
        }
        .ai-message {
          background: white;
          border-left: 4px solid #667eea;
          padding: 15px;
          margin: 10px 0;
          border-radius: 5px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .user-message {
          background: #e3f2fd;
          border-left: 4px solid #2196f3;
          padding: 15px;
          margin: 10px 0;
          border-radius: 5px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin-left: 40px;
        }
        .step-indicator {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 15px;
          border-radius: 10px;
          margin-bottom: 20px;
          text-align: center;
          font-weight: 600;
        }
        .progress-bar-custom {
          height: 30px;
          background: #e0e0e0;
          border-radius: 15px;
          overflow: hidden;
          margin: 10px 0;
        }
        .progress-fill {
          height: 100%;
          background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
          transition: width 0.3s ease;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-weight: 600;
        }
        .element-preview {
          background: white;
          border: 2px solid #ddd;
          border-radius: 8px;
          padding: 10px;
          margin: 5px;
          display: inline-block;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .quick-option {
          background: white;
          border: 2px solid #667eea;
          border-radius: 8px;
          padding: 10px 15px;
          margin: 5px;
          cursor: pointer;
          transition: all 0.3s ease;
          display: inline-block;
        }
        .quick-option:hover {
          background: #667eea;
          color: white;
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .quick-option.selected {
          background: #667eea;
          color: white;
          border-color: #5568d3;
          box-shadow: 0 2px 8px rgba(102, 126, 234, 0.4);
        }
        .quick-option.selected::after {
          content: ' ✓';
          font-weight: bold;
        }
        .ai-breadcrumb {
          background: #f8f9fa;
          padding: 10px 15px;
          border-radius: 8px;
          margin-bottom: 15px;
          font-size: 0.9em;
        }
        .ai-breadcrumb a {
          color: #667eea;
          text-decoration: none;
          cursor: pointer;
          transition: color 0.2s ease;
        }
        .ai-breadcrumb a:hover {
          color: #5568d3;
          text-decoration: underline;
        }
        .ai-breadcrumb .separator {
          margin: 0 8px;
          color: #999;
        }
        .ai-breadcrumb .current {
          color: #333;
          font-weight: 600;
        }
        .dapsiwrm-diagram {
          background: white;
          border: 2px solid #e0e0e0;
          border-radius: 10px;
          padding: 15px;
          margin: 10px 0;
        }
        .dapsiwrm-box {
          padding: 8px;
          margin: 5px 0;
          border-radius: 5px;
          font-size: 11px;
          text-align: center;
          border: 2px solid;
          font-weight: 600;
        }
        .dapsiwrm-arrow {
          text-align: center;
          color: #999;
          font-size: 16px;
          margin: 2px 0;
        }
        .save-status {
          background: #d4edda;
          border: 1px solid #c3e6cb;
          color: #155724;
          padding: 8px 12px;
          border-radius: 5px;
          font-size: 0.85em;
          text-align: center;
          margin: 5px 0;
        }
        .save-status.warning {
          background: #fff3cd;
          border-color: #ffeaa7;
          color: #856404;
        }
      ")),
      # JavaScript for local storage
      tags$script(HTML("
        // Save data to localStorage
        Shiny.addCustomMessageHandler('save_ai_isa_session', function(data) {
          try {
            localStorage.setItem('ai_isa_session', JSON.stringify(data));
            localStorage.setItem('ai_isa_session_timestamp', new Date().toISOString());
            console.log('AI ISA session saved to localStorage');
          } catch(e) {
            console.error('Failed to save to localStorage:', e);
          }
        });

        // Load data from localStorage
        Shiny.addCustomMessageHandler('load_ai_isa_session', function(message) {
          try {
            var savedData = localStorage.getItem('ai_isa_session');
            var timestamp = localStorage.getItem('ai_isa_session_timestamp');

            if (savedData) {
              Shiny.setInputValue('ai_isa_mod-loaded_session_data', {
                data: JSON.parse(savedData),
                timestamp: timestamp
              }, {priority: 'event'});
            } else {
              Shiny.setInputValue('ai_isa_mod-loaded_session_data', null, {priority: 'event'});
            }
          } catch(e) {
            console.error('Failed to load from localStorage:', e);
            Shiny.setInputValue('ai_isa_mod-loaded_session_data', null, {priority: 'event'});
          }
        });

        // Check for saved session on page load
        $(document).on('shiny:connected', function() {
          var savedData = localStorage.getItem('ai_isa_session');
          if (savedData) {
            Shiny.setInputValue('ai_isa_mod-has_saved_session', true, {priority: 'event'});
          }
        });

        // Clear session from localStorage
        Shiny.addCustomMessageHandler('clear_ai_isa_session', function(message) {
          try {
            localStorage.removeItem('ai_isa_session');
            localStorage.removeItem('ai_isa_session_timestamp');
            console.log('AI ISA session cleared from localStorage');
          } catch(e) {
            console.error('Failed to clear localStorage:', e);
          }
        });
      "))
    ),

    # Main content
    fluidRow(
      column(12,
        create_module_header(ns, "modules.isa.ai_assistant.ai_assisted_isa_creation", "modules.isa.ai_assistant.subtitle", "ai_isa_help", i18n)
      )
    ),

    # Note: Progress indicator is shown in sidebar (see sidebar_panel section)

    # Chat interface
    fluidRow(
      column(8,
        div(class = "ai-chat-container", id = ns("chat_container"),
          uiOutput(ns("conversation"))
        ),

        # Input area - dynamically changes based on step type
        uiOutput(ns("input_area"))
      ),

      # Summary panel
      column(4,
        uiOutput(ns("sidebar_panel"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

ai_isa_assistant_server <- function(id, project_data_reactive, i18n, event_bus = NULL, autosave_enabled_reactive = NULL, user_level_reactive = NULL, parent_session = NULL) {
  cat(sprintf("[AI ISA SERVER] Server function called with id: %s at %s\n", id, Sys.time()))
  moduleServer(id, function(input, output, session) {
    cat(sprintf("[AI ISA SERVER] moduleServer executed for id: %s at %s\n", id, Sys.time()))

    # Reactive values for conversation state
    rv <- reactiveValues(
      current_step = 0,  # 0=intro, 1=context, 2=drivers, 3=activities, etc.
      conversation = list(),
      elements = list(
        drivers = list(),
        activities = list(),
        pressures = list(),
        states = list(),
        impacts = list(),
        welfare = list(),
        responses = list()  # Combined responses and measures (R/M in DAPSI(W)R(M))
      ),
      context = list(
        project_name = NULL,
        regional_sea = NULL,
        ecosystem_type = NULL,
        ecosystem_subtype = NULL,
        main_issue = character(0)  # Changed to vector for multiple selections
      ),
      selected_issues = character(0),  # Track selected issues for UI highlighting
      total_steps = 10,  # Updated: merged responses and measures into one step
      suggested_connections = list(),  # AI-generated connection suggestions
      approved_connections = list(),   # User-approved connections
      last_save_time = NULL,  # Track last save timestamp
      auto_save_enabled = TRUE,  # Auto-save toggle
      auto_saved_step_10 = FALSE,  # Flag to prevent auto-save infinite loop
      show_text_input = FALSE,  # Flag to show text input when "Other" is selected
      render_counter = 0  # Counter to force UI re-render for selection highlighting
    )

    # ========================================================================
    # CONTEXT-AWARE KNOWLEDGE BASE
    # ========================================================================
    # Load knowledge base from helper file
    REGIONAL_SEAS <- get_regional_seas_knowledge_base(i18n)

    # Note: get_context_suggestions() is defined in ai_isa_knowledge_base.R

    # Observer to load recovered data when project_data_reactive changes
    # This allows AI ISA Assistant to restore state after auto-save recovery
    observe({
      # Watch for changes in project_data_reactive
      recovered_data <- project_data_reactive()

      cat("[AI ISA] Observer triggered\n")

      # Only proceed if we don't already have elements and there's data to load
      if (length(rv$elements$drivers) == 0 &&
          length(rv$elements$activities) == 0) {

        cat("[AI ISA] Elements are empty, checking for data\n")

        isolate({
          tryCatch({

        if (!is.null(recovered_data) && !is.null(recovered_data$data$isa_data)) {
          cat("[AI ISA] Found data in project_data_reactive\n")
          isa_data <- recovered_data$data$isa_data

          # Check if there's actually data to recover
          has_data <- any(
            !is.null(isa_data$drivers) && nrow(isa_data$drivers) > 0,
            !is.null(isa_data$activities) && nrow(isa_data$activities) > 0,
            !is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0,
            !is.null(isa_data$marine_processes) && nrow(isa_data$marine_processes) > 0,
            !is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0,
            !is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0,
            !is.null(isa_data$responses) && nrow(isa_data$responses) > 0
          )

          # Debug: print each element count
          cat(sprintf("[AI ISA] Element counts - drivers: %d, activities: %d, pressures: %d, states: %d, impacts: %d, welfare: %d, responses: %d\n",
            if(!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0,
            if(!is.null(isa_data$activities)) nrow(isa_data$activities) else 0,
            if(!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0,
            if(!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0,
            if(!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0,
            if(!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0,
            if(!is.null(isa_data$responses)) nrow(isa_data$responses) else 0
          ))

          cat(sprintf("[AI ISA] has_data check result: %s\n", has_data))

          if (has_data) {
            cat("[AI ISA] Loading recovered data from project_data_reactive\n")

            # Convert dataframes back to list format for AI ISA Assistant
            # Drivers
            if (!is.null(isa_data$drivers) && nrow(isa_data$drivers) > 0) {
              rv$elements$drivers <- lapply(1:nrow(isa_data$drivers), function(i) {
                list(
                  name = isa_data$drivers$Name[i],
                  description = isa_data$drivers$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Activities
            if (!is.null(isa_data$activities) && nrow(isa_data$activities) > 0) {
              rv$elements$activities <- lapply(1:nrow(isa_data$activities), function(i) {
                list(
                  name = isa_data$activities$Name[i],
                  description = isa_data$activities$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Pressures
            if (!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
              rv$elements$pressures <- lapply(1:nrow(isa_data$pressures), function(i) {
                list(
                  name = isa_data$pressures$Name[i],
                  description = isa_data$pressures$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # States (marine_processes)
            if (!is.null(isa_data$marine_processes) && nrow(isa_data$marine_processes) > 0) {
              rv$elements$states <- lapply(1:nrow(isa_data$marine_processes), function(i) {
                list(
                  name = isa_data$marine_processes$Name[i],
                  description = isa_data$marine_processes$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Impacts (ecosystem_services)
            if (!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
              rv$elements$impacts <- lapply(1:nrow(isa_data$ecosystem_services), function(i) {
                list(
                  name = isa_data$ecosystem_services$Name[i],
                  description = isa_data$ecosystem_services$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Welfare (goods_benefits)
            if (!is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0) {
              rv$elements$welfare <- lapply(1:nrow(isa_data$goods_benefits), function(i) {
                list(
                  name = isa_data$goods_benefits$Name[i],
                  description = isa_data$goods_benefits$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Responses
            if (!is.null(isa_data$responses) && nrow(isa_data$responses) > 0) {
              rv$elements$responses <- lapply(1:nrow(isa_data$responses), function(i) {
                list(
                  name = isa_data$responses$Name[i],
                  description = isa_data$responses$Description[i] %||% "",
                  timestamp = Sys.time()
                )
              })
            }

            # Load metadata/context if available
            if (!is.null(isa_data$metadata)) {
              rv$context$project_name <- isa_data$metadata$project_name %||% NULL
              rv$context$ecosystem_type <- isa_data$metadata$ecosystem_type %||% NULL
              rv$context$main_issue <- isa_data$metadata$main_issue %||% NULL
            }

            # Load connections if available
            if (!is.null(isa_data$connections)) {
              rv$suggested_connections <- isa_data$connections$suggested %||% list()
              rv$approved_connections <- isa_data$connections$approved %||% list()
              cat(sprintf("[AI ISA] Recovered %d connections (%d approved)\n",
                          length(rv$suggested_connections),
                          length(rv$approved_connections)))
            } else if (!is.null(isa_data$adjacency_matrices)) {
              # Convert adjacency matrices to connection list format
              cat("[AI ISA] Converting adjacency matrices to connection list...\n")
              rv$suggested_connections <- convert_matrices_to_connections(
                isa_data$adjacency_matrices,
                rv$elements
              )
              # Mark all as approved since they came from a saved/template source
              rv$approved_connections <- seq_along(rv$suggested_connections)
              cat(sprintf("[AI ISA] Converted %d connections from adjacency matrices (all approved)\n",
                          length(rv$suggested_connections)))
            }

            # Set to step 10 (completed) since data was recovered
            rv$current_step <- 10

            total_recovered <- sum(
              length(rv$elements$drivers),
              length(rv$elements$activities),
              length(rv$elements$pressures),
              length(rv$elements$states),
              length(rv$elements$impacts),
              length(rv$elements$welfare),
              length(rv$elements$responses)
            )

            cat(sprintf("[AI ISA] Recovered %d elements into AI ISA Assistant UI\n", total_recovered))
          }
        }
          }, error = function(e) {
            cat(sprintf("[AI ISA] Recovery initialization error: %s\n", e$message))
          })
        })
      }
    })

    # Define the stepwise questions
    QUESTION_FLOW <- list(
      list(
        step = 0,
        title_key = "regional_sea",
        title = i18n$t("modules.isa.ai_assistant.regional_sea_context"),
        question = i18n$t("modules.isa.ai_assistant.welcome_message"),
        type = "choice_regional_sea",
        target = "regional_sea"
      ),
      list(
        step = 1,
        title_key = "ecosystem",
        title = i18n$t("modules.isa.ai_assistant.ecosystem_type"),
        question = i18n$t("modules.isa.ai_assistant.what_type_of_marine_ecosystem_are_you_studying"),
        type = "choice_ecosystem",
        target = "ecosystem_type"
      ),
      list(
        step = 2,
        title_key = "main_issue",
        title = i18n$t("modules.isa.ai_assistant.main_issue_identification"),
        question = i18n$t("modules.isa.ai_assistant.question_main_issues"),
        type = "choice_with_custom_multiple",  # Changed to support multiple selections
        target = "main_issue"
      ),
      list(
        step = 3,
        title_key = "drivers",
        title = i18n$t("modules.isa.ai_assistant.drivers_societal_needs"),
        question = i18n$t("modules.isa.ai_assistant.question_drivers"),
        type = "multiple",
        target = "drivers",
        use_context_examples = TRUE
      ),
      list(
        step = 4,
        title_key = "activities",
        title = i18n$t("modules.isa.ai_assistant.activities_human_actions"),
        question = i18n$t("modules.isa.ai_assistant.question_activities"),
        type = "multiple",
        target = "activities",
        use_context_examples = TRUE
      ),
      list(
        step = 5,
        title_key = "pressures",
        title = i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors"),
        question = i18n$t("modules.isa.what_pressures_do_these_activities_put_on_the_mari"),
        type = "multiple",
        target = "pressures",
        use_context_examples = TRUE
      ),
      list(
        step = 6,
        title_key = "states",
        title = i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects"),
        question = i18n$t("modules.isa.how_do_these_pressures_change_the_state_of_the_mar"),
        type = "multiple",
        target = "states",
        use_context_examples = TRUE
      ),
      list(
        step = 7,
        title_key = "impacts",
        title = i18n$t("modules.isa.ai_assistant.impacts_effects_on_ecosystem_services"),
        question = i18n$t("modules.isa.what_are_the_impacts_on_ecosystem_services_and_ben"),
        type = "multiple",
        target = "impacts",
        use_context_examples = TRUE
      ),
      list(
        step = 8,
        title_key = "welfare",
        title = i18n$t("modules.isa.ai_assistant.welfare_human_well_being_effects"),
        question = i18n$t("modules.isa.how_do_these_impacts_affect_human_welfare_and_well"),
        type = "multiple",
        target = "welfare",
        use_context_examples = TRUE
      ),
      list(
        step = 9,
        title_key = "responses",
        title = i18n$t("modules.isa.ai_assistant.response_measures_management_policy"),
        question = i18n$t("modules.isa.what_response_measures_management_actions_policies"),
        type = "multiple",
        target = "responses",
        use_context_examples = TRUE
      ),
      list(
        step = 10,
        title_key = "connection_review",
        title = i18n$t("modules.ses.creation.connection_review"),
        question = i18n$t("modules.isa.ai_assistant.connection_review_intro"),
        type = "connection_review",
        target = "connections"
      )
    )

    # Initialize conversation
    observe({
      if (length(rv$conversation) == 0) {
        rv$conversation <- list(
          list(
            type = "ai",
            message = QUESTION_FLOW[[1]]$question,
            timestamp = Sys.time()
          )
        )
      }
    })

    # ========== HELP MODAL ==========
    create_help_observer(
      input,
      "ai_isa_help",
      "AI Assistant Help",
      i18n$t("modules.isa.this_ai_powered_assistant_helps_you_create_your_da"),
      i18n
    )

    # ========== REACTIVE SIDEBAR ==========

    output$sidebar_panel <- renderUI({
      ns <- session$ns
      box(
        title = i18n$t("modules.isa.ai_assistant.your_ses_model_progress"),
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        # Progress indicator
        div(class = "step-indicator",
          icon("tasks"), " ",
          sprintf(i18n$t("common.misc.step_d_of_d"), rv$current_step, rv$total_steps)
        ),

        # Breadcrumb navigation
        uiOutput(ns("breadcrumb_nav")),

        # Progress bar
        uiOutput(ns("progress_bar")),

        hr(),

        h4(icon("network-wired"), " ", i18n$t("modules.isa.ai_assistant.current_framework")),

        # Two-column layout: Elements | Connection Types
        tags$table(
          style = "width: 100%; margin-left: 10px; border-spacing: 0;",
          tags$tr(
            tags$td(
              style = "vertical-align: top; padding-right: 15px; border-right: 1px solid #ddd;",
              tags$div(style = "font-weight: bold; color: #007bff; margin-bottom: 5px;",
                      i18n$t("modules.isa.ai_assistant.elements")),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_drivers"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.response.measures.drivers")), " ", textOutput(ns("count_drivers"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_activities"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.response.measures.activities")), " ", textOutput(ns("count_activities"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_pressures"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.response.measures.pressures")), " ", textOutput(ns("count_pressures"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_states"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.state_changes")), " ", textOutput(ns("count_states"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_impacts"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.impacts")), " ", textOutput(ns("count_impacts"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_welfare"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.welfare")), " ", textOutput(ns("count_welfare"), inline = TRUE)),
                          style = "color: #007bff;")
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_responses"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.response_measures")), " ", textOutput(ns("count_responses"), inline = TRUE)),
                          style = "color: #007bff;")
              )
            ),
            tags$td(
              style = "vertical-align: top; padding-left: 15px;",
              tags$div(style = "font-weight: bold; color: #28a745; margin-bottom: 5px;",
                      i18n$t("modules.isa.ai_assistant.connection_types")),
              uiOutput(ns("connection_types_summary"))
            )
          )
        ),

        tags$div(
          style = "margin-bottom: 5px; margin-top: 10px; padding-top: 10px; border-top: 1px solid #ddd; margin-left: 10px;",
          actionLink(ns("link_connections"),
                    tagList(icon("project-diagram"), " ", strong(i18n$t("modules.isa.ai_assistant.connections")), " ", textOutput(ns("count_connections"), inline = TRUE)),
                    style = "color: #28a745; font-weight: bold;")
        ),

        hr(),

        h5(icon("database"), " ", i18n$t("modules.isa.ai_assistant.session_management")),
        uiOutput(ns("save_status")),
        br(),
        fluidRow(
          column(6,
            actionButton(ns("manual_save"), i18n$t("modules.isa.ai_assistant.save_progress"),
                        icon = icon("save"),
                        class = "btn-primary btn-sm btn-block",
                        title = i18n$t("modules.isa.ai_assistant.save_your_current_progress_to_browser_storage"))
          ),
          column(6,
            actionButton(ns("load_session"), i18n$t("modules.isa.ai_assistant.load_saved"),
                        icon = icon("folder-open"),
                        class = "btn-secondary btn-sm btn-block",
                        title = i18n$t("modules.isa.ai_assistant.restore_your_last_saved_session"))
          )
        ),
        br(),

        hr(),

        actionButton(ns("preview_model"), i18n$t("modules.isa.ai_assistant.preview_model"),
                    icon = icon("eye"),
                    class = "btn-info btn-block"),
        br(),
        actionButton(ns("save_to_isa"), i18n$t("modules.isa.ai_assistant.save_to_isa_data_entry"),
                    icon = icon("save"),
                    class = "btn-success btn-block",
                    title = i18n$t("modules.isa.transfer_your_completed_model_to_the_standard_isa_")),
        br(),
        actionButton(ns("load_template"), i18n$t("modules.isa.ai_assistant.load_example_template"),
                    icon = icon("file-import"),
                    class = "btn-info btn-block"),
        br(),
        actionButton(ns("start_over"), i18n$t("modules.entry_point.start_over"),
                    icon = icon("redo"),
                    class = "btn-warning btn-block")
      )
    })

    # ========== SESSION SAVE/LOAD FUNCTIONS ==========

    # Function to serialize current session state
    get_session_data <- function() {
      list(
        current_step = rv$current_step,
        elements = rv$elements,
        context = rv$context,
        suggested_connections = rv$suggested_connections,
        approved_connections = rv$approved_connections,
        conversation = rv$conversation,
        timestamp = Sys.time()
      )
    }

    # Function to restore session state
    restore_session_data <- function(data) {
      if (!is.null(data)) {
        rv$current_step <- data$current_step %||% 0
        rv$elements <- data$elements %||% list(drivers=list(), activities=list(), pressures=list(),
                                                states=list(), impacts=list(), welfare=list(),
                                                responses=list())
        rv$context <- data$context %||% list(project_name=NULL, location=NULL,
                                              ecosystem_type=NULL, main_issue=NULL)
        rv$suggested_connections <- data$suggested_connections %||% list()
        rv$approved_connections <- data$approved_connections %||% list()
        rv$conversation <- data$conversation %||% list()

        showNotification("Session restored successfully!", type = "message", duration = 3)
      }
    }

    # Auto-save observer - triggers on data changes
    observe({
      # Trigger on any data change
      rv$current_step
      rv$elements
      rv$context
      rv$approved_connections

      if (rv$auto_save_enabled && rv$current_step > 0) {
        # Debounce: only save if at least 2 seconds since last save
        current_time <- Sys.time()
        if (is.null(rv$last_save_time) ||
            difftime(current_time, rv$last_save_time, units = "secs") > 2) {

          session_data <- get_session_data()
          session$sendCustomMessage("save_ai_isa_session", session_data)
          rv$last_save_time <- current_time
        }
      }
    })

    # Render save status indicator
    output$save_status <- renderUI({
      if (!is.null(rv$last_save_time)) {
        time_diff <- difftime(Sys.time(), rv$last_save_time, units = "secs")
        time_text <- if (time_diff < 60) {
          paste0(round(time_diff), " ", i18n$t("modules.isa.ai_assistant.seconds_ago"))
        } else {
          paste0(round(time_diff / 60), " ", i18n$t("modules.isa.ai_assistant.minutes_ago"))
        }

        div(class = "save-status",
          icon("check-circle"), " ", i18n$t("modules.isa.ai_assistant.auto_saved"), " ", time_text
        )
      } else {
        div(class = "save-status warning",
          icon("exclamation-triangle"), " ", i18n$t("modules.isa.ai_assistant.not_yet_saved")
        )
      }
    })

    # Manual save button
    observeEvent(input$manual_save, {
      session_data <- get_session_data()
      session$sendCustomMessage("save_ai_isa_session", session_data)
      rv$last_save_time <- Sys.time()

      showNotification(
        i18n$t("modules.isa.ai_assistant.session_saved_successfully"),
        type = "message",
        duration = 3
      )
    })

    # Load session button
    observeEvent(input$load_session, {
      session$sendCustomMessage("load_ai_isa_session", list())
    })

    # Handle loaded session data from JavaScript
    observeEvent(input$loaded_session_data, {
      if (!is.null(input$loaded_session_data)) {
        loaded_data <- input$loaded_session_data$data

        # Show confirmation dialog
        showModal(modalDialog(
          title = i18n$t("modules.isa.ai_assistant.restore_previous_session"),
          paste0(i18n$t("modules.isa.ai_assistant.found_a_saved_session_from"),
                 " ",
                 format(as.POSIXct(input$loaded_session_data$timestamp), "%Y-%m-%d %H:%M:%S"),
                 ". ", i18n$t("modules.isa.ai_assistant.do_you_want_to_restore_it")),
          footer = tagList(
            actionButton(session$ns("confirm_load"), i18n$t("modules.isa.ai_assistant.yes_restore"), class = "btn-primary"),
            modalButton(i18n$t("common.buttons.cancel"))
          )
        ))

        # Store loaded data temporarily
        rv$temp_loaded_data <- loaded_data
      } else {
        showNotification(i18n$t("modules.isa.ai_assistant.no_saved_session_found"), type = "warning", duration = 3)
      }
    })

    # Confirm load
    observeEvent(input$confirm_load, {
      if (!is.null(rv$temp_loaded_data)) {
        restore_session_data(rv$temp_loaded_data)
        rv$temp_loaded_data <- NULL
      }
      removeModal()
    })

    # Check for existing session on startup
    observeEvent(input$has_saved_session, {
      if (!is.null(input$has_saved_session) && input$has_saved_session) {
        # Notify user about saved session
        showNotification(
          i18n$t("modules.isa.ai_assistant.previous_session_found"),
          type = "message",
          duration = 5
        )
      }
    }, once = TRUE)

    # Render step title
    output$step_title <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]
        HTML(paste0("<h4>Step ", rv$current_step + 1, " of ", length(QUESTION_FLOW), ": ", step_info$title, "</h4>"))
      } else {
        HTML("<h4>Complete! Review your model</h4>")
      }
    })

    # Note: progress_bar is rendered later (see line 1170) with better calculation using rv$total_steps

    # Helper function to highlight keywords in question text
    highlight_keywords <- function(text) {
      # Keywords to highlight (DAPSI(W)R(M) components)
      keywords <- c("DRIVERS", "ACTIVITIES", "PRESSURES", "STATE", "IMPACTS",
                   "WELFARE", "RESPONSES")

      # Highlight each keyword found in the text
      for (keyword in keywords) {
        if (grepl(keyword, text, fixed = TRUE)) {
          # Wrap keyword in span with bold and purple color
          highlighted <- sprintf('<span style="font-weight: bold; color: #667eea;">%s</span>', keyword)
          text <- gsub(keyword, highlighted, text, fixed = TRUE)
        }
      }

      return(HTML(text))
    }

    # Render conversation - only show current question, not the entire history
    output$conversation <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        # Show only the current AI question
        div(class = "ai-message",
          div(style = "color: #667eea; font-weight: 600;",
            icon("robot"), " AI Assistant"
          ),
          p(highlight_keywords(step_info$question))
        )
      } else {
        # Show completion message
        div(class = "ai-message",
          div(style = "color: #667eea; font-weight: 600;",
            icon("robot"), " AI Assistant"
          ),
          p(i18n$t("modules.isa.ai_assistant.completion_message"))
        )
      }
    })

    # Render input area dynamically based on step type
    input_area_exec_count <- 0

    output$input_area <- renderUI({
      # Force re-render when render_counter changes (used for selection highlighting)
      # Store in temp variable to avoid multiple reactive reads
      counter_val <- rv$render_counter

      input_area_exec_count <<- input_area_exec_count + 1

      cat(sprintf("\n++++++++++++++++++++++++++++++++++++++++\n"))
      cat(sprintf("[AI ISA INPUT_AREA] EXECUTION #%d at %s\n", input_area_exec_count, Sys.time()))
      cat(sprintf("[AI ISA INPUT_AREA] Current step: %d\n", rv$current_step))
      cat(sprintf("[AI ISA INPUT_AREA] show_text_input: %s\n", rv$show_text_input))
      cat(sprintf("[AI ISA INPUT_AREA] Render counter: %d\n", counter_val))
      cat(sprintf("++++++++++++++++++++++++++++++++++++++++\n\n"))

      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (step_info$type == "connection_review") {
          # Connection review interface using tabbed module
          wellPanel(
            h4(icon("link"), " ", i18n$t("modules.isa.ai_assistant.review_suggested_connections")),
            p(i18n$t("modules.isa.approve_or_reject_each_connection_organized_by_fra")),
            connection_review_tabbed_ui(session$ns("conn_review"), i18n),
            br(),
            fluidRow(
              column(6,
                actionButton(session$ns("approve_all_connections"), i18n$t("modules.isa.ai_assistant.approve_all"),
                            icon = icon("check-circle"),
                            class = "btn-success btn-block")
              ),
              column(6,
                actionButton(session$ns("finish_connections"), i18n$t("modules.isa.ai_assistant.finish_continue"),
                            icon = icon("arrow-right"),
                            class = "btn-primary btn-block")
              )
            )
          )
        } else {
          # Standard input interface
          # Show text input ONLY when "Other" is selected
          show_input <- rv$show_text_input

          wellPanel(
            if (show_input) {
              tagList(
                textAreaInput(session$ns("user_input"),
                             label = NULL,
                             placeholder = i18n$t("modules.isa.ai_assistant.type_your_answer_here"),
                             rows = 3,
                             width = "100%"),
                actionButton(session$ns("submit_answer"), i18n$t("modules.isa.ai_assistant.submit_answer"),
                            icon = icon("paper-plane"),
                            class = "btn-primary btn-block"),
                br()
              )
            },
            uiOutput(session$ns("quick_options")),
            br(),
            # Always show continue button for "multiple" type steps
            uiOutput(session$ns("continue_button"))
          )
        }
      }
    })

    # NOTE: Old connection_list renderUI removed - now using connection_review_tabbed module

    # NOTE: Old slider/observer logic commented out - now using connection_review_tabbed module
    # These observers are no longer needed as the tabbed module handles all connection interactions

    #========================================================================
    # CONNECTION REVIEW TABBED MODULE
    #========================================================================

    # Call the connection_review_tabbed server module
    connection_review_tabbed_server(
      id = "conn_review",
      connections_reactive = reactive(rv$suggested_connections),
      i18n = i18n,
      on_approve = function(index, conn) {
        # Add to approved list
        if (!(index %in% rv$approved_connections)) {
          rv$approved_connections <- c(rv$approved_connections, index)
          cat(sprintf("[AI ISA CONN REVIEW] Connection #%d approved (total: %d)\n",
                     index, length(rv$approved_connections)))
        }
      },
      on_reject = function(index, conn) {
        # Remove from approved list
        rv$approved_connections <- setdiff(rv$approved_connections, index)
        cat(sprintf("[AI ISA CONN REVIEW] Connection #%d rejected (total approved: %d)\n",
                   index, length(rv$approved_connections)))
      },
      on_amend = function(index, polarity, strength, confidence) {
        # Update the connection with amended values
        if (index <= length(rv$suggested_connections)) {
          rv$suggested_connections[[index]]$polarity <- polarity
          rv$suggested_connections[[index]]$strength <- strength
          rv$suggested_connections[[index]]$confidence <- confidence
          cat(sprintf("[AI ISA CONN REVIEW] Connection #%d amended: %s, %s, %d\n",
                     index, polarity, strength, confidence))
        }
      }
    )

    # Approve all connections
    observeEvent(input$approve_all_connections, {
      rv$approved_connections <- seq_along(rv$suggested_connections)
      cat(sprintf("[AI ISA CONNECTIONS] APPROVE ALL clicked - approved %d connections\n",
                 length(rv$approved_connections)))
      showNotification(i18n$t("modules.isa.ai_assistant.all_connections_approved"), type = "message")
    })

    # Finish connection review
    observeEvent(input$finish_connections, {
      approved_count <- length(rv$approved_connections)
      cat(sprintf("[AI ISA CONNECTIONS] FINISH clicked - %d approved, %d total suggested\n",
                 approved_count, length(rv$suggested_connections)))
      cat(sprintf("[AI ISA CONNECTIONS] Approved indices: %s\n",
                 paste(rv$approved_connections, collapse = ", ")))

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = paste0(i18n$t("modules.isa.ai_assistant.great_youve_approved"), " ", approved_count, " ",
                            i18n$t("modules.isa.ai_assistant.connections_out_of"), " ",
                            length(rv$suggested_connections), " ", i18n$t("modules.isa.ai_assistant.suggested_connections"), " ",
                            i18n$t("modules.isa.these_connections_will_be_included_in_your_saved_i")),
             timestamp = Sys.time())
      ))

      # Save directly with approved connections - don't rely on auto-save observer
      cat("[AI ISA CONNECTIONS] Directly saving with approved connections\n")

      # Get current project data
      current_data <- project_data_reactive()
      if (is.null(current_data$data)) {
        current_data$data <- list()
      }
      if (is.null(current_data$data$isa_data)) {
        current_data$data$isa_data <- list()
      }

      # Convert element lists to dataframes with proper structure and save
      current_data$data$isa_data$drivers <- if (length(rv$elements$drivers) > 0) {
        data.frame(
          ID = paste0("D", sprintf("%03d", seq_along(rv$elements$drivers))),
          Name = sapply(rv$elements$drivers, function(x) x$name),
          Type = "Driver",
          Description = sapply(rv$elements$drivers, function(x) x$description %||% ""),
          Stakeholder = "", Importance = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$activities <- if (length(rv$elements$activities) > 0) {
        data.frame(
          ID = paste0("A", sprintf("%03d", seq_along(rv$elements$activities))),
          Name = sapply(rv$elements$activities, function(x) x$name),
          Type = "Activity",
          Description = sapply(rv$elements$activities, function(x) x$description %||% ""),
          Stakeholder = "", Importance = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$pressures <- if (length(rv$elements$pressures) > 0) {
        data.frame(
          ID = paste0("P", sprintf("%03d", seq_along(rv$elements$pressures))),
          Name = sapply(rv$elements$pressures, function(x) x$name),
          Type = "Pressure",
          Description = sapply(rv$elements$pressures, function(x) x$description %||% ""),
          Stakeholder = "", Importance = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$marine_processes <- if (length(rv$elements$states) > 0) {
        data.frame(
          ID = paste0("MPF", sprintf("%03d", seq_along(rv$elements$states))),
          Name = sapply(rv$elements$states, function(x) x$name),
          Type = "State",
          Description = sapply(rv$elements$states, function(x) x$description %||% ""),
          Indicator = "", Baseline = "", Target = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$ecosystem_services <- if (length(rv$elements$impacts) > 0) {
        data.frame(
          ID = paste0("ES", sprintf("%03d", seq_along(rv$elements$impacts))),
          Name = sapply(rv$elements$impacts, function(x) x$name),
          Type = "Impact",
          Description = sapply(rv$elements$impacts, function(x) x$description %||% ""),
          Indicator = "", Baseline = "", Target = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$goods_benefits <- if (length(rv$elements$welfare) > 0) {
        data.frame(
          ID = paste0("GB", sprintf("%03d", seq_along(rv$elements$welfare))),
          Name = sapply(rv$elements$welfare, function(x) x$name),
          Type = "Welfare",
          Description = sapply(rv$elements$welfare, function(x) x$description %||% ""),
          Indicator = "", Baseline = "", Target = "", Trend = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      current_data$data$isa_data$responses <- if (length(rv$elements$responses) > 0) {
        data.frame(
          ID = paste0("R", sprintf("%03d", seq_along(rv$elements$responses))),
          Name = sapply(rv$elements$responses, function(x) x$name),
          Type = "Response",
          Description = sapply(rv$elements$responses, function(x) x$description %||% ""),
          Stakeholder = "", Status = "", Effectiveness = "",
          stringsAsFactors = FALSE
        )
      } else { NULL }

      # Build adjacency matrices from approved connections
      cat(sprintf("[AI ISA CONNECTIONS SAVE] Building matrices for %d approved connections\n", approved_count))

      # Get element counts
      n_drivers <- length(rv$elements$drivers)
      n_activities <- length(rv$elements$activities)
      n_pressures <- length(rv$elements$pressures)
      n_states <- length(rv$elements$states)
      n_impacts <- length(rv$elements$impacts)
      n_welfare <- length(rv$elements$welfare)
      n_responses <- length(rv$elements$responses)

      # Initialize adjacency matrices list (NEW DAPSIWRM forward causal flow)
      current_data$data$isa_data$adjacency_matrices <- list(
        d_a = NULL, a_p = NULL, p_mpf = NULL,
        mpf_es = NULL, es_gb = NULL, gb_d = NULL,
        gb_r = NULL, r_d = NULL, r_a = NULL, r_p = NULL
      )

      # Create matrices with forward causal flow (SOURCE×TARGET format)
      # Matrix convention: matrix[source_row, target_col] = connection from source to target
      
      # 1. Drivers → Activities (D→A)
      if (n_drivers > 0 && n_activities > 0) {
        current_data$data$isa_data$adjacency_matrices$d_a <- matrix(
          "", nrow = n_drivers, ncol = n_activities,
          dimnames = list(
            sapply(rv$elements$drivers, function(x) x$name),
            sapply(rv$elements$activities, function(x) x$name)
          )
        )
      }

      # 2. Activities → Pressures (A→P)
      if (n_activities > 0 && n_pressures > 0) {
        current_data$data$isa_data$adjacency_matrices$a_p <- matrix(
          "", nrow = n_activities, ncol = n_pressures,
          dimnames = list(
            sapply(rv$elements$activities, function(x) x$name),
            sapply(rv$elements$pressures, function(x) x$name)
          )
        )
      }

      # 3. Pressures → Marine Processes/Functioning (P→MPF)
      if (n_pressures > 0 && n_states > 0) {
        current_data$data$isa_data$adjacency_matrices$p_mpf <- matrix(
          "", nrow = n_pressures, ncol = n_states,
          dimnames = list(
            sapply(rv$elements$pressures, function(x) x$name),
            sapply(rv$elements$states, function(x) x$name)
          )
        )
      }

      # 4. Marine Processes → Ecosystem Services (MPF→ES)
      if (n_states > 0 && n_impacts > 0) {
        current_data$data$isa_data$adjacency_matrices$mpf_es <- matrix(
          "", nrow = n_states, ncol = n_impacts,
          dimnames = list(
            sapply(rv$elements$states, function(x) x$name),
            sapply(rv$elements$impacts, function(x) x$name)
          )
        )
      }

      # 5. Ecosystem Services → Goods/Benefits (ES→GB)
      if (n_impacts > 0 && n_welfare > 0) {
        current_data$data$isa_data$adjacency_matrices$es_gb <- matrix(
          "", nrow = n_impacts, ncol = n_welfare,
          dimnames = list(
            sapply(rv$elements$impacts, function(x) x$name),
            sapply(rv$elements$welfare, function(x) x$name)
          )
        )
      }

      # 6. Goods/Benefits → Drivers feedback (GB→D)
      if (n_welfare > 0 && n_drivers > 0) {
        current_data$data$isa_data$adjacency_matrices$gb_d <- matrix(
          "", nrow = n_welfare, ncol = n_drivers,
          dimnames = list(
            sapply(rv$elements$welfare, function(x) x$name),
            sapply(rv$elements$drivers, function(x) x$name)
          )
        )
      }

      # 7. Goods/Benefits → Responses (GB→R)
      if (n_welfare > 0 && n_responses > 0) {
        current_data$data$isa_data$adjacency_matrices$gb_r <- matrix(
          "", nrow = n_welfare, ncol = n_responses,
          dimnames = list(
            sapply(rv$elements$welfare, function(x) x$name),
            sapply(rv$elements$responses, function(x) x$name)
          )
        )
      }

      # 8. Responses → Drivers (R→D management)
      if (n_responses > 0 && n_drivers > 0) {
        current_data$data$isa_data$adjacency_matrices$r_d <- matrix(
          "", nrow = n_responses, ncol = n_drivers,
          dimnames = list(
            sapply(rv$elements$responses, function(x) x$name),
            sapply(rv$elements$drivers, function(x) x$name)
          )
        )
      }

      # 9. Responses → Activities (R→A management)
      if (n_responses > 0 && n_activities > 0) {
        current_data$data$isa_data$adjacency_matrices$r_a <- matrix(
          "", nrow = n_responses, ncol = n_activities,
          dimnames = list(
            sapply(rv$elements$responses, function(x) x$name),
            sapply(rv$elements$activities, function(x) x$name)
          )
        )
      }

      # 10. Responses → Pressures (R→P management)
      if (n_responses > 0 && n_pressures > 0) {
        current_data$data$isa_data$adjacency_matrices$r_p <- matrix(
          "", nrow = n_responses, ncol = n_pressures,
          dimnames = list(
            sapply(rv$elements$responses, function(x) x$name),
            sapply(rv$elements$pressures, function(x) x$name)
          )
        )
      }

      # Fill matrices with approved connections
      if (length(rv$approved_connections) > 0) {
        for (conn_idx in rv$approved_connections) {
          conn <- rv$suggested_connections[[conn_idx]]
          confidence <- conn$confidence %||% 3
          value <- paste0(conn$polarity, conn$strength, ":", confidence)

          # NEW: Forward causal flow matrices use [from_index, to_index] (SOURCE×TARGET)
          if (conn$matrix == "d_a" && !is.null(current_data$data$isa_data$adjacency_matrices$d_a)) {
            current_data$data$isa_data$adjacency_matrices$d_a[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "a_p" && !is.null(current_data$data$isa_data$adjacency_matrices$a_p)) {
            current_data$data$isa_data$adjacency_matrices$a_p[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "p_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$p_mpf)) {
            current_data$data$isa_data$adjacency_matrices$p_mpf[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "mpf_es" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_es)) {
            current_data$data$isa_data$adjacency_matrices$mpf_es[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "es_gb" && !is.null(current_data$data$isa_data$adjacency_matrices$es_gb)) {
            current_data$data$isa_data$adjacency_matrices$es_gb[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "gb_d" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_d)) {
            current_data$data$isa_data$adjacency_matrices$gb_d[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "gb_r" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_r)) {
            current_data$data$isa_data$adjacency_matrices$gb_r[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "r_d" && !is.null(current_data$data$isa_data$adjacency_matrices$r_d)) {
            current_data$data$isa_data$adjacency_matrices$r_d[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "r_a" && !is.null(current_data$data$isa_data$adjacency_matrices$r_a)) {
            current_data$data$isa_data$adjacency_matrices$r_a[conn$from_index, conn$to_index] <- value
          } else if (conn$matrix == "r_p" && !is.null(current_data$data$isa_data$adjacency_matrices$r_p)) {
            current_data$data$isa_data$adjacency_matrices$r_p[conn$from_index, conn$to_index] <- value
          }
        }
      }

      # Count total connections saved
      n_connections <- 0
      for (matrix_name in names(current_data$data$isa_data$adjacency_matrices)) {
        mat <- current_data$data$isa_data$adjacency_matrices[[matrix_name]]
        if (!is.null(mat) && is.matrix(mat)) {
          n_filled <- sum(mat != "", na.rm = TRUE)
          if (n_filled > 0) {
            cat(sprintf("[AI ISA CONNECTIONS SAVE] Matrix %s: %d connections\n", matrix_name, n_filled))
          }
          n_connections <- n_connections + n_filled
        }
      }
      cat(sprintf("[AI ISA CONNECTIONS SAVE] Total connections saved: %d\n", n_connections))

      # Update project data
      project_data_reactive(current_data)

      # Mark as saved and move to completion
      rv$auto_saved_step_10 <- TRUE
      cat("[AI ISA CONNECTIONS] Moving to completion\n")
      rv$current_step <- 12

      showNotification(
        paste0(approved_count, " ", i18n$t("modules.isa.ai_assistant.connections_saved_navigating_to_dashboard")),
        type = "message",
        duration = 3
      )

      # Navigate to dashboard after finishing connection review
      if (!is.null(parent_session)) {
        cat("[AI ISA CONNECTIONS] Navigating to dashboard\n")
        updateTabItems(parent_session, "sidebar_menu", "dashboard")
      } else {
        cat("[AI ISA CONNECTIONS] Warning: parent_session is NULL, cannot navigate\n")
      }
    })

    # Render continue button with context-aware label
    output$continue_button <- renderUI({
      # Hide continue/skip button when custom text input is shown
      # User must submit their custom text first via "Submit Answer" button
      if (isTRUE(rv$show_text_input)) {
        return(NULL)
      }

      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        # Determine button label based on next step
        button_label <- i18n$t("modules.isa.ai_assistant.skip_this_question")
        button_icon <- icon("forward")

        # For main_issue step (multiple selection), show count of selected items
        if (step_info$target == "main_issue") {
          selected_count <- length(rv$selected_issues)
          if (selected_count > 0) {
            button_label <- paste0(i18n$t("modules.isa.ai_assistant.continue_with"), " ", selected_count, " ", i18n$t("modules.isa.ai_assistant.selected"))
            button_icon <- icon("arrow-right")
          } else {
            button_label <- i18n$t("modules.isa.ai_assistant.skip_this_question")
            button_icon <- icon("forward")
          }
        }
        else if (rv$current_step + 1 < length(QUESTION_FLOW)) {
          next_step <- QUESTION_FLOW[[rv$current_step + 2]]

          # Create context-aware labels using title_key
          if (next_step$title_key == "activities") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_activities")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "pressures") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_pressures")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "states") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_state_changes")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "impacts") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_impacts")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "welfare") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_welfare")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "responses") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_responses")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "measures") {
            button_label <- i18n$t("modules.isa.ai_assistant.continue_to_measures")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "connection_review") {
            button_label <- i18n$t("common.buttons.finish")
            button_icon <- icon("check")
          } else {
            button_label <- i18n$t("common.buttons.continue")
            button_icon <- icon("arrow-right")
          }
        } else {
          button_label <- i18n$t("common.buttons.finish")
          button_icon <- icon("check")
        }

        actionButton(session$ns("skip_question"), button_label,
                    icon = button_icon,
                    class = "btn-success btn-block")
      }
    })

    # Render quick options - CONTEXT-AWARE VERSION
    # Track execution count for debugging
    quick_options_exec_count <- 0

    output$quick_options <- renderUI({
      # Force re-render when render_counter changes (used for selection highlighting)
      # Store in temp variable to avoid multiple reactive reads
      counter_val <- rv$render_counter

      quick_options_exec_count <<- quick_options_exec_count + 1
      current_step <- rv$current_step

      cat(sprintf("\n========================================\n"))
      cat(sprintf("[AI ISA QUICK] EXECUTION #%d at %s\n", quick_options_exec_count, Sys.time()))
      cat(sprintf("[AI ISA QUICK] Current step: %d / %d\n", current_step, length(QUESTION_FLOW)))
      cat(sprintf("[AI ISA QUICK] Render counter: %d\n", counter_val))

      # Return NULL first to force complete DOM cleanup
      if (current_step < 0 || current_step >= length(QUESTION_FLOW)) {
        cat(sprintf("[AI ISA QUICK] Returning NULL (step out of range)\n"))
        cat(sprintf("========================================\n\n"))
        return(NULL)
      }

      # Use current step as suffix to ensure unique IDs and enable proper observers
      render_suffix <- paste0("_s", current_step)
      cat(sprintf("[AI ISA QUICK] Using suffix: %s\n", render_suffix))

      step_info <- QUESTION_FLOW[[current_step + 1]]
      cat(sprintf("[AI ISA QUICK] Step type: %s, target: %s\n", step_info$type, step_info$target))

      # Handle regional sea selection
      if (step_info$type == "choice_regional_sea") {
          # CRITICAL FIX: Exclude "other" since it's created separately below
          regional_seas_list <- setdiff(names(REGIONAL_SEAS), "other")
          cat(sprintf("[AI ISA QUICK] Creating %d regional sea buttons (excluding 'other')\n", length(regional_seas_list)))

          regional_sea_buttons <- lapply(regional_seas_list, function(sea_key) {
            sea_info <- REGIONAL_SEAS[[sea_key]]
            button_id <- session$ns(paste0("regional_sea_", sea_key, render_suffix))

            # Check if this regional sea is already selected (for breadcrumb navigation)
            is_selected <- !is.null(rv$context$regional_sea) && rv$context$regional_sea == sea_key
            button_class <- if (is_selected) "quick-option selected" else "quick-option"

            cat(sprintf("[AI ISA QUICK]   Button ID: %s, Selected: %s\n", button_id, is_selected))
            actionButton(
              inputId = button_id,
              label = sea_info$name_i18n,
              class = button_class,
              style = "margin: 3px; min-width: 150px;"
            )
          })

          # Add "Other" button
          other_button_id <- session$ns(paste0("regional_sea_other", render_suffix))
          cat(sprintf("[AI ISA QUICK] *** CREATING OTHER BUTTON ***\n"))
          cat(sprintf("[AI ISA QUICK] *** ID: %s ***\n", other_button_id))
          cat(sprintf("[AI ISA QUICK] *** EXEC COUNT: %d ***\n", quick_options_exec_count))
          cat(sprintf("========================================\n\n"))

          other_button <- actionButton(
            inputId = other_button_id,
            label = i18n$t("modules.isa.ai_assistant.other"),
            class = "quick-option",
            style = "margin: 3px; min-width: 150px; background-color: #f0f0f0;"
          )

          return(div(
            h5(style = "font-weight: 600; color: #667eea;", i18n$t("modules.isa.ai_assistant.select_your_regional_sea")),
            div(style = "margin-top: 10px;", regional_sea_buttons, other_button)
          ))
        }

        # Handle ecosystem type (dynamic based on regional sea)
        else if (step_info$type == "choice_ecosystem") {
          if (!is.null(rv$context$regional_sea)) {
            ecosystem_types <- REGIONAL_SEAS[[rv$context$regional_sea]]$ecosystem_types
            ecosystem_buttons <- lapply(seq_along(ecosystem_types), function(i) {
              actionButton(
                inputId = session$ns(paste0("ecosystem_", i, render_suffix)),
                label = ecosystem_types[i],
                class = "quick-option",
                style = "margin: 3px; min-width: 140px;"
              )
            })
            # Add "Other" button
            other_button <- actionButton(
              inputId = session$ns(paste0("ecosystem_other", render_suffix)),
              label = i18n$t("modules.isa.ai_assistant.other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 140px; background-color: #f0f0f0;"
            )
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 paste0(i18n$t("modules.isa.ai_assistant.common_ecosystem_types_in"), " ",
                        REGIONAL_SEAS[[rv$context$regional_sea]]$name_i18n, ":")),
              div(style = "margin-top: 10px;", ecosystem_buttons, other_button)
            ))
          }
        }

        # Handle main issue with suggestions (multiple selection)
        else if (step_info$type == "choice_with_custom_multiple") {
          if (!is.null(rv$context$regional_sea)) {
            issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues
            issue_buttons <- lapply(seq_along(issues), function(i) {
              # Check if this issue is already selected
              is_selected <- issues[i] %in% rv$selected_issues
              button_class <- if (is_selected) "quick-option selected" else "quick-option"

              actionButton(
                inputId = session$ns(paste0("issue_", i, render_suffix)),
                label = issues[i],
                class = button_class,
                style = "margin: 3px; min-width: 160px;"
              )
            })
            # Add "Other" button
            other_button <- actionButton(
              inputId = session$ns(paste0("issue_other", render_suffix)),
              label = i18n$t("modules.isa.ai_assistant.other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 160px; background-color: #f0f0f0;"
            )
            # NOTE: Removed inline continue button - now using the general continue button
            # that shows count at the bottom of the interface (line 1328-1337)
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 i18n$t("modules.isa.ai_assistant.common_issues_in_your_region")),
              p(style = "font-size: 0.9em; color: #666; margin-top: 5px;",
                i18n$t("modules.isa.ai_assistant.click_to_selectdeselect_multiple_selections_allowed")),
              div(style = "margin-top: 10px;", issue_buttons, other_button)
            ))
          }
        }
        # Keep backward compatibility for single choice
        else if (step_info$type == "choice_with_custom") {
          if (!is.null(rv$context$regional_sea)) {
            issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues
            issue_buttons <- lapply(seq_along(issues), function(i) {
              actionButton(
                inputId = session$ns(paste0("issue_", i, render_suffix)),
                label = issues[i],
                class = "quick-option",
                style = "margin: 3px; min-width: 160px;"
              )
            })
            # Add "Other" button
            other_button <- actionButton(
              inputId = session$ns(paste0("issue_other", render_suffix)),
              label = i18n$t("modules.isa.ai_assistant.other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 160px; background-color: #f0f0f0;"
            )
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 i18n$t("modules.isa.ai_assistant.common_issues_in_your_region")),
              div(style = "margin-top: 10px;", issue_buttons, other_button)
            ))
          }
        }

        # Handle context-aware examples for DAPSI(W)R(M) elements
        else if (!is.null(step_info$use_context_examples) && step_info$use_context_examples) {
          cat(sprintf("[AI ISA QUICK] Rendering context-aware suggestions for step %d, target: %s\n",
                      rv$current_step, step_info$target))
          cat(sprintf("[AI ISA QUICK] Context - regional_sea: %s, ecosystem: %s, issue: %s\n",
                      rv$context$regional_sea, rv$context$ecosystem_type, rv$context$main_issue))

          suggestions <- get_context_suggestions(
            category = step_info$target,
            regional_sea = rv$context$regional_sea,
            ecosystem_type = rv$context$ecosystem_type,
            main_issue = rv$context$main_issue
          )

          cat(sprintf("[AI ISA QUICK] Got %d suggestions\n", length(suggestions)))

          if (length(suggestions) > 0) {
            # Limit to first 12 suggestions to avoid overwhelming UI
            display_suggestions <- if (length(suggestions) > 12) suggestions[1:12] else suggestions

            suggestion_buttons <- lapply(seq_along(display_suggestions), function(i) {
              suggestion_name <- display_suggestions[i]
              # Check if this suggestion is already in the elements list
              element_names <- sapply(rv$elements[[step_info$target]], function(e) e$name)
              is_selected <- suggestion_name %in% element_names
              button_class <- if (is_selected) "quick-option selected" else "quick-option"

              actionButton(
                inputId = session$ns(paste0("quick_opt_", i)),
                label = suggestion_name,
                class = button_class,
                style = "margin: 3px;"
              )
            })

            context_info <- ""
            if (!is.null(rv$context$regional_sea)) {
              context_info <- paste0(
                " (", i18n$t("modules.isa.ai_assistant.tailored_for"), " ",
                REGIONAL_SEAS[[rv$context$regional_sea]]$name_i18n,
                if (!is.null(rv$context$ecosystem_type)) paste0(" - ", rv$context$ecosystem_type) else "",
                ")"
              )
            }

            # Add "Other" button
            other_button <- actionButton(
              inputId = session$ns("dapsiwrm_other"),
              label = i18n$t("modules.isa.ai_assistant.other_enter_your_own"),
              class = "quick-option",
              style = "margin: 3px; background-color: #f0f0f0;"
            )

            # Show custom-added elements that aren't in suggestions
            custom_elements <- NULL
            if (!is.null(rv$elements[[step_info$target]]) && length(rv$elements[[step_info$target]]) > 0) {
              element_names <- sapply(rv$elements[[step_info$target]], function(e) e$name)
              custom_names <- setdiff(element_names, display_suggestions)

              if (length(custom_names) > 0) {
                custom_elements <- tagList(
                  hr(style = "margin: 15px 0;"),
                  h5(style = "font-weight: 600; color: #28a745;",
                     paste0(i18n$t("modules.isa.ai_assistant.your_custom_additions"), " (", length(custom_names), "):")),
                  div(style = "margin-top: 10px;",
                    lapply(custom_names, function(name) {
                      tags$span(
                        class = "quick-option selected",
                        style = "margin: 3px; display: inline-block;",
                        tags$span(style = "margin-right: 5px;", name),
                        tags$i(class = "fa fa-check-circle", style = "color: #28a745;")
                      )
                    })
                  )
                )
              }
            }

            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 paste0(i18n$t("modules.isa.ai_assistant.ai_suggested_options"), context_info, ":")),
              p(style = "font-size: 0.9em; color: #666; margin-top: 5px;",
                i18n$t("modules.isa.ai_assistant.click_to_selectdeselect_multiple_selections_allowed")),
              div(style = "margin-top: 10px;", suggestion_buttons, other_button),
              custom_elements
            ))
          }
        }

        # Fallback for old static examples (backwards compatibility)
        else if (!is.null(step_info$examples)) {
          tagList(
            h5(i18n$t("modules.isa.ai_assistant.quick_options_click_to_add")),
            lapply(seq_along(step_info$examples), function(i) {
              example <- step_info$examples[i]
              actionButton(
                inputId = session$ns(paste0("quick_opt_", i)),
                label = example,
                class = "quick-option",
                style = "margin: 3px;"
              )
            })
          )
        }
    })

    # Prevent output from rendering when not visible to avoid duplicates
    outputOptions(output, "quick_options", suspendWhenHidden = TRUE)

    # Handle submit answer
    observeEvent(input$submit_answer, {
      req(input$user_input)

      # Add user message to conversation
      rv$conversation <- c(rv$conversation, list(
        list(type = "user", message = input$user_input, timestamp = Sys.time())
      ))

      # Process answer
      process_answer(input$user_input)

      # Clear input
      updateTextAreaInput(session, "user_input", value = "")
    })

    # NOTE: Observer blocks for regional sea, ecosystem, and issue buttons have been
    # consolidated into the main quick_options observer block below (starting at line ~1659)
    # to prevent duplicate ID issues and properly handle dynamic button creation with render_suffix.

    # Observer to reset show_text_input flag when step changes
    observeEvent(rv$current_step, {
      rv$show_text_input <- FALSE
    })

    # Handle quick select - Fixed observer pattern to prevent duplicates
    # Track which quick option observers have been set up for current step
    quick_observers_setup_for_step <- reactiveVal(-1)
    last_render_counter <- reactiveVal(-1)

    # Store active observers so we can destroy them
    active_observers <- list()

    # Create observers for quick option buttons (only once per step, but recreate on navigation)
    observe({
      current_step <- rv$current_step
      current_render_counter <- rv$render_counter %||% 0

      # Set up new observers if step changed OR if navigating back (render_counter changed)
      needs_setup <- (current_step != quick_observers_setup_for_step()) ||
                     (current_render_counter != last_render_counter())

      if (needs_setup) {
        # Destroy all previous observers before creating new ones
        if (length(active_observers) > 0) {
          cat(sprintf("[AI ISA] Destroying %d old observers\n", length(active_observers)))
          lapply(active_observers, function(obs) {
            if (!is.null(obs)) obs$destroy()
          })
          active_observers <<- list()
        }

        quick_observers_setup_for_step(current_step)
        last_render_counter(current_render_counter)

        if (current_step >= 0 && current_step < length(QUESTION_FLOW)) {
          step_info <- QUESTION_FLOW[[current_step + 1]]

          # === HANDLE REGIONAL SEA SELECTION (Step 0) ===
          if (step_info$type == "choice_regional_sea") {
            # Set up observers for each regional sea button
            lapply(names(REGIONAL_SEAS), function(sea_key) {
              local({
                button_id <- paste0("regional_sea_", sea_key, "_s", current_step)
                sea_name <- REGIONAL_SEAS[[sea_key]]$name_en

                observeEvent(input[[button_id]], {
                  if (rv$current_step == current_step) {
                    cat(sprintf("[AI ISA] Regional sea button clicked: %s\n", sea_name))

                    # Check if user is changing regional sea after having made progress
                    previous_selection <- rv$context$regional_sea
                    is_changing_selection <- !is.null(previous_selection) && previous_selection != sea_key
                    has_made_progress <- length(rv$elements$drivers) > 0 ||
                                        length(rv$elements$activities) > 0 ||
                                        !is.null(rv$context$ecosystem_type) ||
                                        length(rv$context$main_issue) > 0

                    # Show warning if changing after making progress
                    if (is_changing_selection && has_made_progress) {
                      cat(sprintf("[AI ISA] Warning: User changing regional sea from %s to %s after making progress\n",
                                 previous_selection, sea_key))

                      showModal(modalDialog(
                        title = tags$h4(icon("exclamation-triangle"), " ", i18n$t("common.messages.warning_changing_regional_sea")),
                        size = "m",
                        easyClose = FALSE,
                        footer = tagList(
                          modalButton(i18n$t("common.buttons.cancel")),
                          actionButton(session$ns("confirm_regional_sea_change"),
                                      i18n$t("common.buttons.continue"),
                                      class = "btn-warning")
                        ),
                        tags$div(
                          p(style = "font-size: 15px;",
                            i18n$t("modules.isa.you_are_changing_your_regional_sea_selection_this_")),
                          tags$ul(
                            tags$li(i18n$t("modules.isa.ai_assistant.ecosystem_types")),
                            tags$li(i18n$t("modules.isa.ai_assistant.common_issues_in_the_region")),
                            tags$li(i18n$t("modules.isa.ai_assistant.context_specific_suggestions"))
                          ),
                          p(style = "font-size: 15px; font-weight: 600; color: #d9534f;",
                            i18n$t("modules.isa.your_curr_ecosystem_and_issue_selections_may_no_lo"))
                        )
                      ))

                      # Set up observer for confirmation
                      observeEvent(input$confirm_regional_sea_change, {
                        # User confirmed - proceed with change
                        rv$context$regional_sea <- sea_key

                        # Clear dependent selections
                        rv$context$ecosystem_type <- NULL
                        rv$context$ecosystem_subtype <- NULL
                        rv$context$main_issue <- character(0)
                        rv$selected_issues <- character(0)

                        cat(sprintf("[AI ISA] Regional sea changed to %s, cleared dependent selections\n", sea_key))

                        ai_response <- paste0(
                          i18n$t("modules.isa.ai_assistant.regional_sea_changed_to"), " ", REGIONAL_SEAS[[sea_key]]$name_i18n, ". ",
                          i18n$t("modules.isa.your_ecosystem_and_issue_selections_have_been_clea")
                        )
                        rv$conversation <- c(rv$conversation, list(
                          list(type = "ai", message = ai_response, timestamp = Sys.time())
                        ))

                        removeModal()
                        move_to_next_step()
                      }, ignoreInit = TRUE, once = TRUE)

                    } else {
                      # No conflict - proceed normally
                      rv$context$regional_sea <- sea_key

                      ai_response <- paste0(
                        i18n$t("modules.isa.ai_assistant.great_you_selected"), " ", REGIONAL_SEAS[[sea_key]]$name_i18n, ". ",
                        i18n$t("modules.isa.this_will_help_me_suggest_relevant_activities_and_")
                      )
                      rv$conversation <- c(rv$conversation, list(
                        list(type = "ai", message = ai_response, timestamp = Sys.time())
                      ))

                      move_to_next_step()
                    }
                  }
                }, ignoreInit = TRUE, once = TRUE)
              })
            })

            # Observer for "Other" button - regional sea
            observeEvent(input[[paste0("regional_sea_other_s", current_step)]], {
              if (rv$current_step == current_step) {
                cat("[AI ISA] Regional sea 'Other' button clicked - showing text input\n")
                rv$show_text_input <- TRUE
              }
            }, ignoreInit = TRUE, once = TRUE)
          }

          # === HANDLE ECOSYSTEM TYPE SELECTION (Step 1) ===
          else if (step_info$type == "choice_ecosystem") {
            if (!is.null(rv$context$regional_sea)) {
              ecosystem_types <- REGIONAL_SEAS[[rv$context$regional_sea]]$ecosystem_types

              # Set up observers for each ecosystem button
              lapply(seq_along(ecosystem_types), function(i) {
                local({
                  button_id <- paste0("ecosystem_", i, "_s", current_step)
                  ecosystem_name <- ecosystem_types[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      cat(sprintf("[AI ISA] Ecosystem button clicked: %s\n", ecosystem_name))
                      rv$context$ecosystem_type <- ecosystem_name

                      ai_response <- paste0(
                        i18n$t("modules.isa.ai_assistant.perfect"), " ", ecosystem_name, " ",
                        i18n$t("modules.isa.ai_assistant.ecosystems_unique_characteristics")
                      )
                      rv$conversation <- c(rv$conversation, list(
                        list(type = "ai", message = ai_response, timestamp = Sys.time())
                      ))

                      move_to_next_step()
                    }
                  }, ignoreInit = TRUE, once = TRUE)
                })
              })

              # Observer for "Other" button - ecosystem
              observeEvent(input[[paste0("ecosystem_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  cat("[AI ISA] Ecosystem 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)
            }
          }

          # === HANDLE MAIN ISSUE SELECTION - MULTIPLE (Step 2) ===
          else if (step_info$type == "choice_with_custom_multiple") {
            if (!is.null(rv$context$regional_sea)) {
              issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues

              # Set up observers for each issue button (toggle selection)
              lapply(seq_along(issues), function(i) {
                local({
                  button_id <- paste0("issue_", i, "_s", current_step)
                  issue_name <- issues[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      # Toggle selection
                      if (issue_name %in% rv$selected_issues) {
                        # Deselect
                        cat(sprintf("[AI ISA] Issue deselected: %s\n", issue_name))
                        rv$selected_issues <- setdiff(rv$selected_issues, issue_name)
                      } else {
                        # Select
                        cat(sprintf("[AI ISA] Issue selected: %s\n", issue_name))
                        rv$selected_issues <- c(rv$selected_issues, issue_name)
                      }

                      # Force UI re-render by incrementing render counter
                      rv$render_counter <- (rv$render_counter %||% 0) + 1
                    }
                  }, ignoreInit = TRUE)
                })
              })

              # Observer for "Other" button - issue
              observeEvent(input[[paste0("issue_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  cat("[AI ISA] Issue 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)

              # NOTE: Removed inline continue button observer - now handled by
              # the general skip_question observer which uses the bottom continue button
              # that shows "Continue with X selected" (see line 2178 onwards)
            }
          }
          # === HANDLE MAIN ISSUE SELECTION - SINGLE (backward compatibility) ===
          else if (step_info$type == "choice_with_custom") {
            if (!is.null(rv$context$regional_sea)) {
              issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues

              # Set up observers for each issue button
              lapply(seq_along(issues), function(i) {
                local({
                  button_id <- paste0("issue_", i, "_s", current_step)
                  issue_name <- issues[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      cat(sprintf("[AI ISA] Issue button clicked: %s\n", issue_name))
                      rv$context$main_issue <- issue_name

                      ai_response <- paste0(
                        i18n$t("modules.isa.ai_assistant.understood_focus_suggestions"), " ", tolower(issue_name), "-related issues. ",
                        i18n$t("modules.isa.ai_assistant.now_lets_start_building")
                      )
                      rv$conversation <- c(rv$conversation, list(
                        list(type = "ai", message = ai_response, timestamp = Sys.time())
                      ))

                      move_to_next_step()
                    }
                  }, ignoreInit = TRUE, once = TRUE)
                })
              })

              # Observer for "Other" button - issue
              observeEvent(input[[paste0("issue_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  cat("[AI ISA] Issue 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)
            }
          }

          # === HANDLE STATIC EXAMPLES (old approach) ===
          else if (!is.null(step_info$examples)) {
            # Set up observers for this step's buttons
            lapply(seq_along(step_info$examples), function(i) {
              local({
                button_id <- paste0("quick_opt_", i)
                example_text <- step_info$examples[i]

                observeEvent(input[[button_id]], {
                  # Only process if still on the same step
                  if (rv$current_step == current_step) {
                    process_answer(example_text)
                  }
                }, ignoreInit = TRUE, once = TRUE)
              })
            })
          }
          # === HANDLE CONTEXT-AWARE EXAMPLES (new approach) ===
          else if (!is.null(step_info$use_context_examples) && step_info$use_context_examples) {
            # Get context-aware suggestions
            suggestions <- get_context_suggestions(
              category = step_info$target,
              regional_sea = rv$context$regional_sea,
              ecosystem_type = rv$context$ecosystem_type,
              main_issue = rv$context$main_issue
            )

            if (length(suggestions) > 0) {
              # Limit to first 12 suggestions to match UI
              display_suggestions <- if (length(suggestions) > 12) suggestions[1:12] else suggestions

              # Set up observers for context-aware suggestion buttons (toggle selection)
              lapply(seq_along(display_suggestions), function(i) {
                local({
                  button_id <- paste0("quick_opt_", i)
                  suggestion_text <- display_suggestions[i]

                  observeEvent(input[[button_id]], {
                    # Only process if still on the same step
                    if (rv$current_step == current_step) {
                      # Check if this suggestion is already added
                      element_names <- sapply(rv$elements[[step_info$target]], function(e) e$name)
                      is_already_added <- suggestion_text %in% element_names

                      if (is_already_added) {
                        # Remove (deselect)
                        cat(sprintf("[AI ISA QUICK] Removing %s from %s\n", suggestion_text, step_info$target))
                        rv$elements[[step_info$target]] <- Filter(
                          function(e) e$name != suggestion_text,
                          rv$elements[[step_info$target]]
                        )
                      } else {
                        # Add (select)
                        cat(sprintf("[AI ISA QUICK] Adding %s to %s\n", suggestion_text, step_info$target))
                        new_element <- list(
                          name = suggestion_text,
                          description = "",
                          timestamp = Sys.time()
                        )
                        rv$elements[[step_info$target]] <- c(rv$elements[[step_info$target]], list(new_element))
                      }

                      # Force UI re-render to update button classes
                      rv$render_counter <- (rv$render_counter %||% 0) + 1
                    }
                  }, ignoreInit = TRUE)
                })
              })
            }

            # Observer for "Other" button - DAPSIWRM elements
            observeEvent(input[["dapsiwrm_other"]], {
              if (rv$current_step == current_step) {
                cat("[AI ISA] DAPSIWRM 'Other' button clicked - showing text input\n")
                rv$show_text_input <- TRUE
              }
            }, ignoreInit = TRUE, once = TRUE)
          }
        }
      }
    })

    # Handle skip
    observeEvent(input$skip_question, {
      # If on main_issue step with multiple selections, save them before moving on
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (step_info$target == "main_issue" && length(rv$selected_issues) > 0) {
          # Save selected issues to context
          rv$context$main_issue <- rv$selected_issues

          # Create AI response
          issue_list <- paste(rv$selected_issues, collapse = ", ")
          ai_response <- paste0(
            i18n$t("modules.isa.ai_assistant.great_focus_on_issues"), " ", issue_list, ". ",
            i18n$t("modules.isa.ai_assistant.now_lets_start_building")
          )
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))
        }
      }

      move_to_next_step()
    })

    # Process answer function
    process_answer <- function(answer) {
      cat(sprintf("[AI ISA PROCESS] process_answer called with: '%s'\n", answer))

      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]
        cat(sprintf("[AI ISA PROCESS] Current step %d, type: %s, target: %s\n",
                    rv$current_step, step_info$type, step_info$target))

        # === Handle context-setting steps (regional_sea, ecosystem, issue) ===

        # Regional sea (text input fallback)
        if (step_info$target == "regional_sea") {
          # Try to match input to a regional sea
          matched_sea <- NULL
          for (sea_key in names(REGIONAL_SEAS)) {
            if (grepl(answer, REGIONAL_SEAS[[sea_key]]$name_en, ignore.case = TRUE) ||
                grepl(answer, REGIONAL_SEAS[[sea_key]]$name_i18n, ignore.case = TRUE)) {
              matched_sea <- sea_key
              break
            }
          }

          if (!is.null(matched_sea)) {
            rv$context$regional_sea <- matched_sea
            cat(sprintf("[AI ISA] Regional sea set to: %s (text input)\n", REGIONAL_SEAS[[matched_sea]]$name_en))

            ai_response <- paste0(
              i18n$t("modules.isa.ai_assistant.great_you_selected"), " ", REGIONAL_SEAS[[matched_sea]]$name_i18n, ". ",
              i18n$t("modules.isa.this_will_help_me_suggest_relevant_activities_and_")
            )
          } else {
            # Couldn't match, use "other"
            rv$context$regional_sea <- "other"
            cat("[AI ISA] Regional sea set to: other (text input not matched)\n")
            ai_response <- i18n$t("I'll use general marine suggestions for your area.")
          }

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          move_to_next_step()
          return()
        }

        # Ecosystem type (text input fallback)
        else if (step_info$target == "ecosystem_type") {
          rv$context$ecosystem_type <- answer
          cat(sprintf("[AI ISA] Ecosystem type set to: %s (text input)\n", answer))

          ai_response <- paste0(
            i18n$t("modules.isa.ai_assistant.perfect"), " ", answer, " ",
            i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
          )

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          move_to_next_step()
          return()
        }

        # Main issue (text input)
        else if (step_info$target == "main_issue") {
          rv$context$main_issue <- answer
          cat(sprintf("[AI ISA] Main issue set to: %s\n", answer))

          ai_response <- paste0(
            i18n$t("Understood. I'll focus suggestions on"), " ", tolower(answer), "-related issues. ",
            i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
          )

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          move_to_next_step()
          return()
        }

        # === Existing logic for DAPSI(W)R(M) elements ===

        # Store answer based on target
        if (step_info$type == "multiple") {
          cat(sprintf("[AI ISA PROCESS] Adding element to %s\n", step_info$target))

          # Add to list
          current_list <- rv$elements[[step_info$target]]
          new_element <- list(
            name = answer,
            description = "",
            timestamp = Sys.time()
          )
          rv$elements[[step_info$target]] <- c(current_list, list(new_element))

          # Count current elements in this category
          element_count <- length(rv$elements[[step_info$target]])
          cat(sprintf("[AI ISA PROCESS] Element added! Total %s: %d\n", step_info$target, element_count))

          # Hide text input and show continue button again
          rv$show_text_input <- FALSE

          # AI response with count
          ai_response <- paste0(i18n$t("modules.isa.ai_assistant.added"), " '", answer, "' (", element_count, " ", step_info$target, " ", i18n$t("modules.isa.ai_assistant.total"), "). ", i18n$t("modules.isa.click_quick_options_to_add_more_or_click_the_green"))

          # Add AI response
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

        } else {
          # Store single value
          rv$context[[step_info$target]] <- answer

          # Add AI response BEFORE moving to next step
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = i18n$t("modules.isa.ai_assistant.thank_you_moving_to_the_next_question"), timestamp = Sys.time())
          ))

          move_to_next_step()
        }
      }
    }

    # Intelligent polarity detection based on element names
    detect_polarity <- function(from_name, to_name, from_type, to_type) {
      # Keywords that suggest negative impacts/changes
      negative_keywords <- c(
        "declin", "degrad", "loss", "reduc", "damag", "destruct", "pollut",
        "eutrophic", "overfish", "bycatch", "invasive", "extinct", "harm",
        "contaminat", "erosion", "acidific", "hypox", "dead zone", "bleach",
        "disease", "mortality", "collapse", "fragment", "depletion"
      )

      # Keywords that suggest positive changes
      positive_keywords <- c(
        "increas", "growth", "restor", "recover", "improv", "enhanc", "protect",
        "conserv", "benefit", "health", "sustain", "resilient", "biodiver",
        "abundance", "productiv", "regenerat", "rehabilit", "rebui"
      )

      # Keywords for mitigation/reduction actions
      mitigation_keywords <- c(
        "ban", "prohibit", "restrict", "limit", "regulat", "control", "manag",
        "reduce", "prevent", "mitigat", "protect", "enforce", "monitor",
        "stop", "remov", "clean", "treat"
      )

      from_lower <- tolower(from_name)
      to_lower <- tolower(to_name)

      # Check characteristics of target element
      to_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, to_lower)))
      to_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, to_lower)))

      # Check if source is a mitigation action
      from_is_mitigation <- any(sapply(mitigation_keywords, function(kw) grepl(kw, from_lower)))

      # Special case: Response Measures → Pressures
      if (from_type == "responses" && to_type == "pressures") {
        # Response measures typically reduce pressures
        return("-")
      }

      # Special case: Response Measures → States
      if (from_type == "responses" && to_type == "states") {
        # If state is negative (decline, loss), response reduces it → "-"
        # If state is positive (recovery, increase), response increases it → "+"
        if (to_is_negative) {
          return("-")  # Reduces bad state
        } else if (to_is_positive) {
          return("+")  # Increases good state
        }
        return("+")  # Default: responses improve states
      }

      # Activities → Pressures
      if (from_type == "activities" && to_type == "pressures") {
        # Activities generally cause pressures
        return("+")
      }

      # Pressures → States
      if (from_type == "pressures" && to_type == "states") {
        # If state is negative (fish stock decline), pressure increases it → "+"
        # If state is positive (fish stock recovery), pressure reduces it → "-"
        if (to_is_negative) {
          return("+")  # Pressure increases negative state
        } else if (to_is_positive) {
          return("-")  # Pressure decreases positive state
        }
        return("-")  # Default: pressures degrade states
      }

      # States → Impacts
      if (from_type == "states" && to_type == "impacts") {
        # If state is negative and impact is negative → "+" (bad state causes bad impact)
        # If state is positive and impact is positive → "+" (good state causes good impact)
        from_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, from_lower)))
        from_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, from_lower)))

        if ((from_is_negative && to_is_negative) || (from_is_positive && to_is_positive)) {
          return("+")
        } else if ((from_is_negative && to_is_positive) || (from_is_positive && to_is_negative)) {
          return("-")
        }
        return("-")  # Default: degraded states reduce services
      }

      # Impacts → Welfare
      if (from_type == "impacts" && to_type == "welfare") {
        # Negative impacts reduce welfare → "-"
        # Positive impacts increase welfare → "+"
        from_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, from_lower)))
        from_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, from_lower)))

        if (from_is_negative) {
          return("-")
        } else if (from_is_positive) {
          return("+")
        }
        return("-")  # Default: impacts reduce welfare
      }

      # Default fallback
      return("+")
    }

    # Convert adjacency matrices to connection list format
    convert_matrices_to_connections <- function(matrices, elements) {
      connections <- list()

      # Matrix mapping: matrix_name -> list(from_type, to_type, from_list, to_list)
      matrix_map <- list(
        d_a = list(from_type = "drivers", to_type = "activities", from = elements$drivers, to = elements$activities),
        a_p = list(from_type = "activities", to_type = "pressures", from = elements$activities, to = elements$pressures),
        p_mpf = list(from_type = "pressures", to_type = "states", from = elements$pressures, to = elements$states),
        mpf_es = list(from_type = "states", to_type = "impacts", from = elements$states, to = elements$impacts),
        es_gb = list(from_type = "impacts", to_type = "welfare", from = elements$impacts, to = elements$welfare),
        gb_d = list(from_type = "welfare", to_type = "drivers", from = elements$welfare, to = elements$drivers),
        gb_r = list(from_type = "welfare", to_type = "responses", from = elements$welfare, to = elements$responses),
        r_d = list(from_type = "responses", to_type = "drivers", from = elements$responses, to = elements$drivers),
        r_a = list(from_type = "responses", to_type = "activities", from = elements$responses, to = elements$activities),
        r_p = list(from_type = "responses", to_type = "pressures", from = elements$responses, to = elements$pressures)
      )

      for (matrix_name in names(matrices)) {
        # Skip if not in our map
        if (!matrix_name %in% names(matrix_map)) next

        mat <- matrices[[matrix_name]]
        map_info <- matrix_map[[matrix_name]]

        # Skip if elements lists are empty
        if (is.null(map_info$from) || is.null(map_info$to) ||
            length(map_info$from) == 0 || length(map_info$to) == 0) next

        # Loop through matrix cells
        for (i in 1:nrow(mat)) {
          for (j in 1:ncol(mat)) {
            value <- mat[i, j]
            # Skip empty cells
            if (is.null(value) || is.na(value) || value == "" || trimws(value) == "") next

            # Parse value (format: "+strong:5" or "-medium:3")
            polarity <- "+"
            strength <- "medium"
            confidence <- 3

            if (grepl("^[+-]", value)) {
              polarity <- substr(value, 1, 1)
              rest <- substr(value, 2, nchar(value))

              # Extract strength and confidence
              if (grepl(":", rest)) {
                parts <- strsplit(rest, ":")[[1]]
                strength <- parts[1]
                if (length(parts) > 1) {
                  confidence <- as.integer(parts[2])
                }
              } else {
                strength <- rest
              }
            }

            # Create connection object
            connections[[length(connections) + 1]] <- list(
              from_type = map_info$from_type,
              from_index = i,
              from_name = map_info$from[[i]]$name,
              to_type = map_info$to_type,
              to_index = j,
              to_name = map_info$to[[j]]$name,
              polarity = polarity,
              strength = strength,
              confidence = confidence,
              rationale = paste(map_info$from[[i]]$name,
                              if(polarity == "+") "increases" else "decreases",
                              map_info$to[[j]]$name),
              matrix = matrix_name
            )
          }
        }
      }

      cat(sprintf("[AI ISA] Converted %d connections from %d matrices\n",
                  length(connections), length(matrices)))
      return(connections)
    }

    # Helper function to generate smart connections with relevance filtering
    generate_smart_connections <- function(from_elements, to_elements, from_type, to_type, matrix_name, max_count, min_relevance) {
      candidates <- list()

      for (i in seq_along(from_elements)) {
        for (j in seq_along(to_elements)) {
          relevance <- calculate_relevance(from_elements[[i]]$name, to_elements[[j]]$name, from_type, to_type)
          if (relevance >= min_relevance) {
            polarity <- detect_polarity(from_elements[[i]]$name, to_elements[[j]]$name, from_type, to_type)

            # Choose appropriate verb based on connection type
            verb <- if (from_type == "drivers") {
              "drives"
            } else if (from_type == "activities") {
              if (polarity == "+") "increases" else "causes"
            } else if (from_type == "pressures") {
              if (polarity == "+") "increases" else "decreases"
            } else if (from_type == "states") {
              "impacts"
            } else if (from_type == "impacts") {
              if (polarity == "+") "increases" else "reduces"
            } else if (from_type == "responses") {
              if (polarity == "-") "restricts" else "enables"
            } else if (from_type == "welfare") {
              if (polarity == "+") "motivates" else "reduces"
            } else {
              if (polarity == "+") "affects positively" else "affects negatively"
            }

            candidates[[length(candidates) + 1]] <- list(
              conn = list(
                from_type = from_type,
                from_index = i,
                from_name = from_elements[[i]]$name,
                to_type = to_type,
                to_index = j,
                to_name = to_elements[[j]]$name,
                polarity = polarity,
                strength = "medium",
                confidence = 3,
                rationale = paste(from_elements[[i]]$name, verb, to_elements[[j]]$name),
                matrix = matrix_name
              ),
              relevance = relevance
            )
          }
        }
      }

      # Sort by relevance and return top connections
      if (length(candidates) > 0) {
        candidates <- candidates[order(sapply(candidates, function(x) x$relevance), decreasing = TRUE)]
        n_to_return <- min(length(candidates), max_count)
        result <- lapply(1:n_to_return, function(i) candidates[[i]]$conn)
        cat(sprintf("[AI ISA CONNECTIONS] Generated %d %s→%s connections (from %d candidates, %.0f%% filtered)\n",
                    n_to_return, toupper(substring(from_type, 1, 1)), toupper(substring(to_type, 1, 1)),
                    length(candidates), (1 - n_to_return/length(candidates)) * 100))
        return(result)
      }

      cat(sprintf("[AI ISA CONNECTIONS] No relevant %s→%s connections found\n", from_type, to_type))
      return(list())
    }

    # Helper function to calculate semantic relevance between two elements
    calculate_relevance <- function(from_name, to_name, from_type, to_type) {
      # Normalize names to lowercase for comparison
      from_lower <- tolower(from_name)
      to_lower <- tolower(to_name)

      # Keywords that suggest strong relationships
      connection_keywords <- list(
        drivers_activities = c("fish", "food", "econom", "livelihood", "subsistence", "commerc", "industr", "recreat", "tourism", "develop", "demand", "need", "cultural", "spiritual"),
        activities_pressures = c("fish", "extract", "harvest", "develop", "construct", "pollut", "discharge", "emission", "waste", "noise", "disturb", "remov", "introduc", "invasive"),
        pressures_states = c("pollut", "nutrient", "contamin", "extract", "remov", "habitat", "species", "abundance", "diversity", "structure", "function", "ecosystem", "chemical", "physical", "biological"),
        states_impacts = c("decline", "loss", "degrad", "change", "abundance", "diversity", "habitat", "ecosystem", "service", "provision", "regulat", "cultural", "support"),
        impacts_welfare = c("food", "protein", "nutrition", "income", "livelihood", "employ", "health", "wellbeing", "recreation", "cultural", "spiritual", "aesthetic", "economic", "social"),
        responses_pressures = c("regulat", "protect", "conserv", "restor", "manag", "monitor", "enforc", "limit", "restrict", "ban", "quota", "closure", "zone", "designation"),
        welfare_responses = c("concern", "awareness", "demand", "advocacy", "pressure", "policy", "legislation", "management", "action", "intervention"),
        responses_drivers = c("policy", "awareness", "education", "incentiv", "subsid", "tax", "regulation", "enforcement", "behavior", "demand"),
        responses_activities = c("limit", "restrict", "ban", "regulat", "control", "manage", "permit", "license", "quota", "closure", "zone")
      )

      # Get relevant keywords for this connection type
      key <- paste(from_type, to_type, sep = "_")
      keywords <- connection_keywords[[key]]

      if (is.null(keywords)) return(0.5)  # Default moderate relevance

      # Count keyword matches
      from_matches <- sum(sapply(keywords, function(kw) grepl(kw, from_lower)))
      to_matches <- sum(sapply(keywords, function(kw) grepl(kw, to_lower)))

      # Calculate relevance score (0-1)
      total_matches <- from_matches + to_matches
      if (total_matches == 0) return(0.3)  # Low relevance
      if (total_matches == 1) return(0.6)  # Moderate relevance
      return(0.9)  # High relevance
    }

    # Generate logical connections based on DAPSI(W)R(M) framework
    generate_connections <- function(elements) {
      connections <- list()
      MAX_PER_TYPE <- 15  # Reduced limit for better quality (10 types × 15 = max 150 total)
      MIN_RELEVANCE <- 0.3  # Lower threshold to ensure core DAPSIWR connections are generated

      # Per-type counters
      count_da <- 0  # Drivers → Activities
      count_ap <- 0  # Activities → Pressures
      count_ps <- 0  # Pressures → States
      count_si <- 0  # States → Impacts
      count_iw <- 0  # Impacts → Welfare
      count_rp <- 0  # Responses → Pressures
      count_wd <- 0  # Welfare → Drivers (feedback)
      count_wr <- 0  # Welfare → Responses (feedback)
      count_rd <- 0  # Responses → Drivers (feedback)
      count_ra <- 0  # Responses → Activities (feedback)

      cat(sprintf("[AI ISA CONNECTIONS] Generating connections (max %d per type)...\n", MAX_PER_TYPE))
      cat(sprintf("[AI ISA CONNECTIONS] Element counts: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R=%d\n",
                  length(elements$drivers %||% list()),
                  length(elements$activities %||% list()),
                  length(elements$pressures %||% list()),
                  length(elements$states %||% list()),
                  length(elements$impacts %||% list()),
                  length(elements$welfare %||% list()),
                  length(elements$responses %||% list())))

      # Debug: Print actual element names
      if (length(elements$drivers) > 0) {
        cat(sprintf("[AI ISA CONNECTIONS] Drivers: %s\n", paste(sapply(elements$drivers, function(x) x$name), collapse=", ")))
      }
      if (length(elements$activities) > 0) {
        cat(sprintf("[AI ISA CONNECTIONS] Activities: %s\n", paste(sapply(elements$activities, function(x) x$name), collapse=", ")))
      }

      # D → A (Drivers → Activities): Smart connection generation
      if (length(elements$drivers) > 0 && length(elements$activities) > 0) {
        new_conns <- generate_smart_connections(elements$drivers, elements$activities, "drivers", "activities", "d_a", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_da <- length(new_conns)
      }

      # A → P (Activities → Pressures): Smart connection generation
      if (length(elements$activities) > 0 && length(elements$pressures) > 0) {
        new_conns <- generate_smart_connections(elements$activities, elements$pressures, "activities", "pressures", "a_p", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_ap <- length(new_conns)
      }

      # P → S (Pressures → States): Smart connection generation
      if (length(elements$pressures) > 0 && length(elements$states) > 0) {
        new_conns <- generate_smart_connections(elements$pressures, elements$states, "pressures", "states", "p_mpf", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_ps <- length(new_conns)
      }

      # S → I (States → Impacts): Smart connection generation
      if (length(elements$states) > 0 && length(elements$impacts) > 0) {
        new_conns <- generate_smart_connections(elements$states, elements$impacts, "states", "impacts", "mpf_es", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_si <- length(new_conns)
      }

      # I → W (Impacts → Welfare): Smart connection generation
      if (length(elements$impacts) > 0 && length(elements$welfare) > 0) {
        new_conns <- generate_smart_connections(elements$impacts, elements$welfare, "impacts", "welfare", "es_gb", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_iw <- length(new_conns)
      }

      # R → P (Responses → Pressures): Smart connection generation
      if (length(elements$responses) > 0 && length(elements$pressures) > 0) {
        new_conns <- generate_smart_connections(elements$responses, elements$pressures, "responses", "pressures", "r_p", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_rp <- length(new_conns)
      }

      # ========================================================================
      # FEEDBACK LOOPS - Additional logical connections
      # ========================================================================

      # W → D (Welfare → Drivers): Smart feedback loop generation
      if (length(elements$welfare) > 0 && length(elements$drivers) > 0) {
        new_conns <- generate_smart_connections(elements$welfare, elements$drivers, "welfare", "drivers", "gb_d", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_wd <- length(new_conns)
      }

      # W → R (Welfare → Responses): Smart feedback loop generation
      if (length(elements$welfare) > 0 && length(elements$responses) > 0) {
        new_conns <- generate_smart_connections(elements$welfare, elements$responses, "welfare", "responses", "gb_r", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_wr <- length(new_conns)
      }

      # R → D (Responses → Drivers): Smart feedback loop generation
      if (length(elements$responses) > 0 && length(elements$drivers) > 0) {
        new_conns <- generate_smart_connections(elements$responses, elements$drivers, "responses", "drivers", "r_d", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_rd <- length(new_conns)
      }

      # R → A (Responses → Activities): Smart feedback loop generation
      if (length(elements$responses) > 0 && length(elements$activities) > 0) {
        new_conns <- generate_smart_connections(elements$responses, elements$activities, "responses", "activities", "r_a", MAX_PER_TYPE, MIN_RELEVANCE)
        connections <- c(connections, new_conns)
        count_ra <- length(new_conns)
      }

      # Log final count and per-type breakdown
      cat(sprintf("[AI ISA CONNECTIONS] ========================================\n"))
      cat(sprintf("[AI ISA CONNECTIONS] TOTAL GENERATED: %d connections\n", length(connections)))
      cat(sprintf("[AI ISA CONNECTIONS] Per-type breakdown:\n"))
      cat(sprintf("[AI ISA CONNECTIONS]   D→A: %d  A→P: %d  P→S: %d\n", count_da, count_ap, count_ps))
      cat(sprintf("[AI ISA CONNECTIONS]   S→I: %d  I→W: %d  R→P: %d\n", count_si, count_iw, count_rp))
      cat(sprintf("[AI ISA CONNECTIONS]   W→D: %d  W→R: %d  R→D: %d  R→A: %d\n", count_wd, count_wr, count_rd, count_ra))
      cat(sprintf("[AI ISA CONNECTIONS] ========================================\n"))

      return(connections)
    }

    # Move to next step
    move_to_next_step <- function() {
      # Check if we can move forward before incrementing
      if (rv$current_step < length(QUESTION_FLOW)) {
        rv$current_step <- rv$current_step + 1
      }

      if (rv$current_step < length(QUESTION_FLOW)) {
        # Add next question
        next_step <- QUESTION_FLOW[[rv$current_step + 1]]

        # If moving to connection review step, generate connections first
        if (next_step$type == "connection_review") {
          # Check if we have any elements
          total_elements <- sum(
            length(rv$elements$drivers),
            length(rv$elements$activities),
            length(rv$elements$pressures),
            length(rv$elements$states),
            length(rv$elements$impacts),
            length(rv$elements$welfare),
            length(rv$elements$responses)
          )

          if (total_elements == 0) {
            # No elements - show helpful message
            message <- paste0(
              i18n$t("I notice you haven't added any elements yet!"), " ",
              i18n$t("modules.isa.to_create_connections_you_need_to_add_at_least_som"), " ",
              i18n$t("modules.isa.please_go_back_through_the_previous_steps_and_add_")
            )
          } else {
            # Generate connections with progress indicator
            conn_count <- 0
            withProgress(message = i18n$t("modules.isa.ai_assistant.analyzing_your_elements_and_generating_connections"),
                        value = 0, {
              incProgress(0.3, detail = i18n$t("modules.isa.ai_assistant.this_may_take_a_moment"))

              # Generate connections
              cat("[AI ISA] About to call generate_connections()...\n")
              all_connections <- generate_connections(rv$elements)
              cat(sprintf("[AI ISA] generate_connections() returned %d connections\n", length(all_connections)))

              # Limit to 200 connections for tabbed display (distributed across tabs)
              max_connections <- 200
              if (length(all_connections) > max_connections) {
                rv$suggested_connections <- all_connections[1:max_connections]
                conn_count <- max_connections
                too_many <- TRUE
              } else {
                rv$suggested_connections <- all_connections
                conn_count <- length(rv$suggested_connections)
                too_many <- FALSE
              }

              # Add a generation timestamp to force UI refresh
              attr(rv$suggested_connections, "generated_at") <- Sys.time()

              cat(sprintf("[AI ISA] Generated %d connections for review at %s\n",
                         length(rv$suggested_connections), Sys.time()))
              cat(sprintf("[AI ISA] First connection structure: %s\n",
                         paste(names(rv$suggested_connections[[1]]), collapse=", ")))

              incProgress(0.7, detail = i18n$t("modules.isa.ai_assistant.finalizing_connections"))
            })

            if (conn_count == 0) {
              message <- paste0(
                i18n$t("I see you've added"), " ", total_elements, " ", i18n$t("elements, but I couldn't generate connections between them."), " ",
                i18n$t("modules.isa.try_adding_more_elements_to_different_categories_d")
              )
            } else {
              base_message <- paste0(next_step$question, " ", i18n$t("I've identified"), " ", conn_count,
                               " ", i18n$t("modules.isa.potential_connections_based_on_the_dapsiwrm_framew"), " ",
                               i18n$t("modules.isa.ai_assistant.review_each_connection_below_and_approve_or_reject_them"))

              if (too_many) {
                message <- paste0(base_message, " ",
                                 i18n$t("modules.isa.ai_assistant.note_i_found_more_connections_but_limited_to"), " ", max_connections,
                                 " ", i18n$t("modules.isa.distributed_across_tabs_to_keep_the_interface_resp"))
              } else {
                message <- base_message
              }
            }
          }

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = message, timestamp = Sys.time())
          ))
        } else {
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = next_step$question, timestamp = Sys.time())
          ))
        }
      } else {
        # All done
        rv$conversation <- c(rv$conversation, list(
          list(type = "ai",
               message = i18n$t("Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module."),
               timestamp = Sys.time())
        ))
      }

      # Scroll to bottom
      shinyjs::runjs(sprintf("document.getElementById('%s').scrollTop = document.getElementById('%s').scrollHeight",
                            session$ns("chat_container"), session$ns("chat_container")))
    }

    # Render breadcrumb navigation
    output$breadcrumb_nav <- renderUI({
      if (rv$current_step <= 0) return(NULL)

      # Build breadcrumb trail
      breadcrumbs <- list()

      # Home/Start
      breadcrumbs[[1]] <- tags$a(
        href = "#",
        onclick = sprintf("Shiny.setInputValue('%s', Math.random())", session$ns("goto_start")),
        icon("home"),
        " ",
        i18n$t("common.buttons.start")
      )

      # Add previous steps up to current
      for (i in 1:min(rv$current_step, length(QUESTION_FLOW))) {
        step_info <- QUESTION_FLOW[[i]]
        breadcrumbs[[length(breadcrumbs) + 1]] <- tags$span(class = "separator", "›")

        if (i < rv$current_step) {
          # Clickable - can go back
          breadcrumbs[[length(breadcrumbs) + 1]] <- tags$a(
            href = "#",
            onclick = sprintf("Shiny.setInputValue('%s', %d)", session$ns("goto_step"), i - 1),
            step_info$title
          )
        } else {
          # Current step - not clickable
          breadcrumbs[[length(breadcrumbs) + 1]] <- tags$span(
            class = "current",
            step_info$title
          )
        }
      }

      div(class = "ai-breadcrumb", breadcrumbs)
    })

    # Handle breadcrumb navigation - go to start
    observeEvent(input$goto_start, {
      cat("[AI ISA] Breadcrumb: Returning to start\n")
      rv$current_step <- 0
      rv$selected_issues <- character(0)
    })

    # Handle breadcrumb navigation - go to specific step
    observeEvent(input$goto_step, {
      target_step <- input$goto_step
      if (!is.null(target_step) && target_step >= 0 && target_step < rv$current_step) {
        cat(sprintf("[AI ISA] Breadcrumb: Going back to step %d from step %d\n",
                   target_step, rv$current_step))

        # Clear connections if navigating back from connection review (step 10)
        # This will force regeneration when returning to step 10
        if (rv$current_step == 10 && target_step < 10) {
          cat("[AI ISA] Breadcrumb: Clearing connections for regeneration\n")
          # Don't set timestamp on empty list to prevent reactive loop
          rv$suggested_connections <- list()
          rv$approved_connections <- list()
          cat("[AI ISA] Breadcrumb: Connections cleared (no timestamp set)\n")
        }

        rv$current_step <- target_step

        # Restore selected issues if going back to issue selection step (current_step==1 shows QUESTION_FLOW[[2]])
        if (target_step == 1) {
          # Restore from context
          if (length(rv$context$main_issue) > 0) {
            rv$selected_issues <- rv$context$main_issue
            cat(sprintf("[AI ISA] Breadcrumb: Restored %d selected issues: %s\n",
                       length(rv$selected_issues),
                       paste(rv$selected_issues, collapse=", ")))
          } else {
            rv$selected_issues <- character(0)
            cat("[AI ISA] Breadcrumb: No issues in context to restore\n")
          }
        } else if (target_step < 1) {
          # Clear selected issues if going before issue selection
          rv$selected_issues <- character(0)
          cat("[AI ISA] Breadcrumb: Cleared selected issues (before step 1)\n")
        }

        # Force UI re-render
        rv$render_counter <- (rv$render_counter %||% 0) + 1
      }
    })

    # Render progress bar
    output$progress_bar <- renderUI({
      progress_pct <- if (rv$total_steps > 0) {
        round((rv$current_step / rv$total_steps) * 100)
      } else {
        0
      }

      div(class = "progress-bar-custom",
        div(class = "progress-fill",
          style = sprintf("width: %d%%;", progress_pct),
          sprintf("%d%%", progress_pct)
        )
      )
    })

    # Render elements summary
    output$elements_summary <- renderUI({
      total_elements <- sum(
        length(rv$elements$drivers),
        length(rv$elements$activities),
        length(rv$elements$pressures),
        length(rv$elements$states),
        length(rv$elements$impacts),
        length(rv$elements$welfare),
        length(rv$elements$responses)
      )

      div(
        h2(style = "color: #667eea; text-align: center;", total_elements),
        p(style = "text-align: center;", i18n$t("modules.isa.ai_assistant.total_elements_created"))
      )
    })

    # Render counts for detailed list
    output$count_drivers <- renderText({ length(rv$elements$drivers) })
    output$count_activities <- renderText({ length(rv$elements$activities) })
    output$count_pressures <- renderText({ length(rv$elements$pressures) })
    output$count_states <- renderText({ length(rv$elements$states) })
    output$count_impacts <- renderText({ length(rv$elements$impacts) })
    output$count_welfare <- renderText({ length(rv$elements$welfare) })
    output$count_responses <- renderText({ length(rv$elements$responses) })
    output$count_connections <- renderText({ length(rv$approved_connections) })

    # Render connection types summary in a single column
    output$connection_types_summary <- renderUI({
      # Helper function to count connections by matrix type
      count_by_matrix <- function(matrix_name) {
        suggested_count <- 0
        approved_count <- 0

        # Count suggested connections
        if (!is.null(rv$suggested_connections) && length(rv$suggested_connections) > 0) {
          suggested_count <- sum(sapply(rv$suggested_connections, function(conn) {
            if (is.list(conn) && !is.null(conn$matrix)) {
              isTRUE(conn$matrix == matrix_name)
            } else {
              FALSE
            }
          }))
        }

        # Count approved connections
        if (!is.null(rv$approved_connections) && length(rv$approved_connections) > 0) {
          approved_count <- sum(sapply(rv$approved_connections, function(conn) {
            if (is.list(conn) && !is.null(conn$matrix)) {
              isTRUE(conn$matrix == matrix_name)
            } else {
              FALSE
            }
          }))
        }

        suggested_count + approved_count
      }

      # Count all 9 connection types
      count_da <- count_by_matrix("d_a")    # Drivers → Activities
      count_ap <- count_by_matrix("a_p")    # Activities → Pressures
      count_ps <- count_by_matrix("p_mpf")  # Pressures → States
      count_si <- count_by_matrix("mpf_es") # States → Impacts
      count_iw <- count_by_matrix("es_gb")  # Impacts → Welfare
      count_wr <- count_by_matrix("gb_r")   # Welfare → Responses
      count_rd <- count_by_matrix("r_d")    # Responses → Drivers
      count_ra <- count_by_matrix("r_a")    # Responses → Activities
      count_rp <- count_by_matrix("r_p")    # Responses → Pressures

      # Create display with bold font
      tagList(
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("D→A: %d", count_da)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("A→P: %d", count_ap)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("P→S: %d", count_ps)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("S→I: %d", count_si)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("I→W: %d", count_iw)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("W→R: %d", count_wr)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("R→D: %d", count_rd)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("R→A: %d", count_ra)),
        tags$div(style = "font-weight: bold; margin-bottom: 3px;",
                 sprintf("R→P: %d", count_rp))
      )
    })

    # Render DAPSI(W)R(M) flow diagram
    output$dapsiwrm_diagram <- renderUI({
      div(class = "dapsiwrm-diagram",
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #776db3; color: #776db3;",
          paste0("D: ", length(rv$elements$drivers))),
        div(class = "dapsiwrm-arrow", "↓"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #5abc67; color: #5abc67;",
          paste0("A: ", length(rv$elements$activities))),
        div(class = "dapsiwrm-arrow", "↓"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #fec05a; color: #fec05a;",
          paste0("P: ", length(rv$elements$pressures))),
        div(class = "dapsiwrm-arrow", "↓"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #bce2ee; color: #5ab4d9;",
          paste0("S: ", length(rv$elements$states))),
        div(class = "dapsiwrm-arrow", "↓"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #313695; color: #313695;",
          paste0("I: ", length(rv$elements$impacts))),
        div(class = "dapsiwrm-arrow", "↓"),
        div(class = "dapsiwrm-box", style = "background: #fff1a2; border-color: #f0c808; color: #666;",
          paste0("W: ", length(rv$elements$welfare))),
        div(class = "dapsiwrm-arrow", "↑"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #66c2a5; color: #66c2a5;",
          paste0("R/M: ", length(rv$elements$responses)))
      )
    })

    # Handle preview model
    observeEvent(input$preview_model, {
      # Create preview of all elements
      preview_content <- tagList(
        h3(icon("project-diagram"), " ", i18n$t("modules.isa.ai_assistant.your_dapsiwrm_model_preview")),
        hr(),

        if (!is.null(rv$context$project_name)) {
          div(
            h4(icon("map-marker-alt"), " ", i18n$t("common.messages.project_information")),
            tags$ul(
              tags$li(strong(i18n$t("modules.isa.ai_assistant.projectlocation")), " ", rv$context$project_name),
              if (!is.null(rv$context$ecosystem_type)) tags$li(strong(i18n$t("common.labels.ecosystem_type")), " ", rv$context$ecosystem_type),
              if (!is.null(rv$context$main_issue)) tags$li(strong(i18n$t("modules.isa.ai_assistant.main_issue")), " ", rv$context$main_issue)
            ),
            hr()
          )
        },

        # Drivers
        if (length(rv$elements$drivers) > 0) {
          div(
            h4(style = "color: #776db3;", icon("flag"), " ", i18n$t("modules.isa.ai_assistant.drivers_societal_needs")),
            tags$ul(
              lapply(rv$elements$drivers, function(d) tags$li(d$name))
            )
          )
        },

        # Activities
        if (length(rv$elements$activities) > 0) {
          div(
            h4(style = "color: #5abc67;", icon("running"), " ", i18n$t("modules.isa.ai_assistant.activities_human_actions")),
            tags$ul(
              lapply(rv$elements$activities, function(a) tags$li(a$name))
            )
          )
        },

        # Pressures
        if (length(rv$elements$pressures) > 0) {
          div(
            h4(style = "color: #fec05a;", icon("exclamation-triangle"), " ", i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors")),
            tags$ul(
              lapply(rv$elements$pressures, function(p) tags$li(p$name))
            )
          )
        },

        # State Changes
        if (length(rv$elements$states) > 0) {
          div(
            h4(style = "color: #bce2ee;", icon("water"), " ", i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects")),
            tags$ul(
              lapply(rv$elements$states, function(s) tags$li(s$name))
            )
          )
        },

        # Impacts
        if (length(rv$elements$impacts) > 0) {
          div(
            h4(style = "color: #313695;", icon("chart-line"), " ", i18n$t("modules.isa.ai_assistant.impacts_service_effects")),
            tags$ul(
              lapply(rv$elements$impacts, function(i) tags$li(i$name))
            )
          )
        },

        # Welfare
        if (length(rv$elements$welfare) > 0) {
          div(
            h4(style = "color: #fff1a2; text-shadow: 1px 1px 2px #666;", icon("heart"), " ", i18n$t("modules.isa.ai_assistant.welfare_human_well_being")),
            tags$ul(
              lapply(rv$elements$welfare, function(w) tags$li(w$name))
            )
          )
        },

        # Responses
        if (length(rv$elements$responses) > 0) {
          div(
            h4(style = "color: #66c2a5;", icon("shield-alt"), " ", i18n$t("modules.isa.ai_assistant.response_measures_management_policy")),
            tags$ul(
              lapply(rv$elements$responses, function(r) tags$li(r$name))
            )
          )
        },

        hr(),

        # Connections
        if (length(rv$approved_connections) > 0 && length(rv$suggested_connections) > 0) {
          # Filter out invalid indices (bounds check)
          valid_indices <- rv$approved_connections[rv$approved_connections <= length(rv$suggested_connections)]

          if (length(valid_indices) > 0) {
            div(
              h4(style = "color: #28a745;", icon("project-diagram"), " ",
                 i18n$t("ui.dashboard.connections"), " (", length(valid_indices), ")"),
              tags$div(
                style = "max-height: 300px; overflow-y: auto; padding: 10px; background: #f8f9fa; border-radius: 5px;",
                tags$ul(
                  style = "list-style-type: none; padding-left: 0;",
                  lapply(valid_indices, function(conn_idx) {
                    conn <- rv$suggested_connections[[conn_idx]]
                    tags$li(
                      style = "margin-bottom: 8px; padding: 5px; background: white; border-radius: 3px;",
                      icon("link"),
                      " ",
                      strong(conn$from_name),
                      " ",
                      span(style = "color: #666;",
                           if(conn$polarity == "+") "→" else "⊸"),
                      " ",
                      strong(conn$to_name),
                      tags$br(),
                      span(style = "font-size: 0.85em; color: #666; margin-left: 20px;",
                           i18n$t("modules.isa.data_entry.common.strength"), " ", conn$strength, ", ",
                           i18n$t("modules.isa.data_entry.common.confidence"), " ", conn$confidence %||% 3)
                    )
                  })
                )
              ),
              hr()
            )
          }
        },

        p(class = "text-muted",
          i18n$t("modules.isa.ai_assistant.total_elements"), " ",
          sum(length(rv$elements$drivers), length(rv$elements$activities),
              length(rv$elements$pressures), length(rv$elements$states),
              length(rv$elements$impacts), length(rv$elements$welfare),
              length(rv$elements$responses)),
          " | ",
          i18n$t("modules.isa.ai_assistant.total_connections"), " ",
          # Count only valid approved connections (bounds check)
          if (length(rv$suggested_connections) > 0) {
            length(rv$approved_connections[rv$approved_connections <= length(rv$suggested_connections)])
          } else {
            0
          })
      )

      showModal(modalDialog(
        preview_content,
        title = NULL,
        size = "l",
        easyClose = TRUE,
        footer = tagList(
          modalButton(i18n$t("common.buttons.close")),
          actionButton(session$ns("save_from_preview"), i18n$t("modules.isa.ai_assistant.save_to_isa_data_entry"),
                      class = "btn-success", icon = icon("save"))
        )
      ))
    })

    # Handle save from preview modal
    observeEvent(input$save_from_preview, {
      removeModal()
      # Trigger the main save action
      showNotification(
        i18n$t("Model saved! Navigate to 'ISA Data Entry' to see your elements."),
        type = "message",
        duration = 5
      )
    })

    # Handle start over
    observeEvent(input$start_over, {
      showModal(modalDialog(
        title = i18n$t("common.messages.confirm_start_over"),
        i18n$t("modules.isa.are_you_sure_you_want_to_start_over_all_curr_progr"),
        footer = tagList(
          modalButton(i18n$t("common.buttons.cancel")),
          actionButton(session$ns("confirm_start_over"), i18n$t("modules.isa.ai_assistant.yes_start_over"), class = "btn-danger")
        )
      ))
    })

    observeEvent(input$confirm_start_over, {
      cat("[AI ISA] Starting over - resetting all data\n")

      # Reset step
      rv$current_step <- 0
      rv$auto_saved_step_10 <- FALSE
      rv$show_text_input <- FALSE

      # Reset conversation
      rv$conversation <- list(
        list(type = "ai", message = QUESTION_FLOW[[1]]$question, timestamp = Sys.time())
      )

      # Reset all elements
      rv$elements <- list(
        drivers = list(),
        activities = list(),
        pressures = list(),
        states = list(),
        impacts = list(),
        welfare = list(),
        responses = list()
      )

      # Reset context - MUST match initialization structure
      rv$context <- list(
        project_name = NULL,
        regional_sea = NULL,
        ecosystem_type = NULL,
        ecosystem_subtype = NULL,
        main_issue = NULL
      )

      # Reset connections
      rv$suggested_connections <- list()
      rv$approved_connections <- list()

      # Clear project data (if saved)
      current_data <- project_data_reactive()
      if (!is.null(current_data$data$isa_data)) {
        cat("[AI ISA] Clearing saved project ISA data\n")
        current_data$data$isa_data <- NULL
        current_data$data$cld <- list(nodes = NULL, edges = NULL)
        current_data$data$metadata$data_source <- NULL
        current_data$last_modified <- Sys.time()
        project_data_reactive(current_data)

        # Emit ISA change event to clear CLD
        if (!is.null(event_bus)) {
          event_bus$emit_isa_change()
        }
      }

      # Clear localStorage auto-save
      session$sendCustomMessage('clear_ai_isa_session', list())

      # Reset last save time
      rv$last_save_time <- NULL

      removeModal()

      showNotification("All data cleared. Starting over from step 1.", type = "message", duration = 3)
      cat("[AI ISA] Reset complete\n")
    })

    # Framework element link observers - show element details in modal
    observeEvent(input$link_drivers, {
      if (length(rv$elements$drivers) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.drivers")),
          tags$ul(lapply(rv$elements$drivers, function(d) tags$li(strong(d$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_activities, {
      if (length(rv$elements$activities) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.activities")),
          tags$ul(lapply(rv$elements$activities, function(a) tags$li(strong(a$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_pressures, {
      if (length(rv$elements$pressures) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.pressures")),
          tags$ul(lapply(rv$elements$pressures, function(p) tags$li(strong(p$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_states, {
      if (length(rv$elements$states) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.state_changes")),
          tags$ul(lapply(rv$elements$states, function(s) tags$li(strong(s$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_impacts, {
      if (length(rv$elements$impacts) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.impacts")),
          tags$ul(lapply(rv$elements$impacts, function(i) tags$li(strong(i$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_welfare, {
      if (length(rv$elements$welfare) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.ses.creation.welfare")),
          tags$ul(lapply(rv$elements$welfare, function(w) tags$li(strong(w$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_responses, {
      if (length(rv$elements$responses) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.responses")),
          tags$ul(lapply(rv$elements$responses, function(r) tags$li(strong(r$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    })

    observeEvent(input$link_connections, {
      if (length(rv$approved_connections) > 0) {
        # Build list of approved connections with details
        conn_list <- lapply(rv$approved_connections, function(idx) {
          conn <- rv$suggested_connections[[idx]]
          tags$li(
            strong(conn$from_name), " ",
            span(style = "color: #666;", if(conn$polarity == "+") "→" else "⊸"), " ",
            strong(conn$to_name),
            tags$br(),
            span(style = "font-size: 0.9em; color: #666;",
                 "Strength: ", conn$strength, ", Confidence: ", conn$confidence %||% 3)
          )
        })

        showModal(modalDialog(
          title = tagList(icon("project-diagram"), " ", i18n$t("modules.isa.ai_assistant.approved_connections")),
          tags$ul(conn_list),
          size = "l",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      } else {
        showNotification("No connections approved yet.", type = "warning", duration = 2)
      }
    })

    # Handle load template
    observeEvent(input$load_template, {
      showModal(modalDialog(
        title = i18n$t("modules.isa.ai_assistant.load_example_template"),
        h4(i18n$t("modules.isa.ai_assistant.choose_a_pre_built_scenario")),
        fluidRow(
          column(6,
            actionButton(session$ns("template_overfishing"), i18n$t("modules.isa.ai_assistant.overfishing_in_coastal_waters"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_pollution"), i18n$t("modules.isa.ai_assistant.marine_pollution_plastics"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        fluidRow(
          column(6,
            actionButton(session$ns("template_tourism"), i18n$t("modules.isa.ai_assistant.coastal_tourism_impacts"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_climate"), i18n$t("modules.isa.ai_assistant.climate_change_coral_reefs"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        footer = modalButton(i18n$t("common.buttons.cancel"))
      ))
    })

    # Template: Overfishing
    observeEvent(input$template_overfishing, {
      rv$context <- list(
        project_name = "Overfishing Management",
        ecosystem_type = "Coastal waters",
        main_issue = "Declining fish stocks due to overfishing"
      )
      rv$elements <- list(
        drivers = list(
          list(name = "Food security", description = "", timestamp = Sys.time()),
          list(name = "Economic development", description = "", timestamp = Sys.time())
        ),
        activities = list(
          list(name = "Commercial fishing", description = "", timestamp = Sys.time()),
          list(name = "Recreational fishing", description = "", timestamp = Sys.time())
        ),
        pressures = list(
          list(name = "Overfishing", description = "", timestamp = Sys.time()),
          list(name = "Bycatch of non-target species", description = "", timestamp = Sys.time())
        ),
        states = list(
          list(name = "Declining fish stocks", description = "", timestamp = Sys.time()),
          list(name = "Altered food webs", description = "", timestamp = Sys.time())
        ),
        impacts = list(
          list(name = "Reduced fish catch", description = "", timestamp = Sys.time()),
          list(name = "Loss of biodiversity value", description = "", timestamp = Sys.time())
        ),
        welfare = list(
          list(name = "Loss of livelihoods for fishers", description = "", timestamp = Sys.time()),
          list(name = "Food insecurity", description = "", timestamp = Sys.time())
        ),
        responses = list(
          list(name = "Fishing quotas and limits", description = "", timestamp = Sys.time()),
          list(name = "Marine protected areas", description = "", timestamp = Sys.time())
        )
      )

      # Add example connections
      rv$suggested_connections <- list(
        # Drivers → Activities
        list(from = "Food security", to = "Commercial fishing", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
        list(from = "Economic development", to = "Commercial fishing", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 1),
        list(from = "Economic development", to = "Recreational fishing", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
        # Activities → Pressures
        list(from = "Commercial fishing", to = "Overfishing", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 1),
        list(from = "Commercial fishing", to = "Bycatch of non-target species", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 2),
        list(from = "Recreational fishing", to = "Overfishing", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "weak", matrix = "p_a", from_index = 2, to_index = 1),
        # Pressures → States
        list(from = "Overfishing", to = "Declining fish stocks", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
        list(from = "Overfishing", to = "Altered food webs", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
        list(from = "Bycatch of non-target species", to = "Altered food webs", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 2),
        # States → Impacts
        list(from = "Declining fish stocks", to = "Reduced fish catch", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
        list(from = "Altered food webs", to = "Loss of biodiversity value", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
        # Impacts → Welfare
        list(from = "Reduced fish catch", to = "Loss of livelihoods for fishers", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 1),
        list(from = "Reduced fish catch", to = "Food insecurity", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "medium", matrix = "gb_es", from_index = 1, to_index = 2),
        list(from = "Loss of biodiversity value", to = "Loss of livelihoods for fishers", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "weak", matrix = "gb_es", from_index = 2, to_index = 1)
      )

      # Mark all connections as approved
      rv$approved_connections <- seq_along(rv$suggested_connections)
      rv$current_step <- 10  # Mark as complete
      removeModal()
      showNotification(i18n$t("modules.isa.overfishing_template_loaded_with_example_connectio"), type = "message", duration = 5)
    })

    # Template: Marine Pollution
    observeEvent(input$template_pollution, {
      rv$context <- list(
        project_name = "Marine Plastic Pollution",
        ecosystem_type = "Coastal waters",
        main_issue = "Plastic pollution and marine litter"
      )
      rv$elements <- list(
        drivers = list(
          list(name = "Economic development", description = "", timestamp = Sys.time()),
          list(name = "Consumer demand", description = "", timestamp = Sys.time())
        ),
        activities = list(
          list(name = "Coastal development", description = "", timestamp = Sys.time()),
          list(name = "Tourism", description = "", timestamp = Sys.time()),
          list(name = "Shipping", description = "", timestamp = Sys.time())
        ),
        pressures = list(
          list(name = "Marine litter and plastics", description = "", timestamp = Sys.time()),
          list(name = "Chemical pollution", description = "", timestamp = Sys.time())
        ),
        states = list(
          list(name = "Water quality decline", description = "", timestamp = Sys.time()),
          list(name = "Habitat degradation", description = "", timestamp = Sys.time())
        ),
        impacts = list(
          list(name = "Loss of tourism revenue", description = "", timestamp = Sys.time()),
          list(name = "Reduced water quality for recreation", description = "", timestamp = Sys.time())
        ),
        welfare = list(
          list(name = "Health impacts from contamination", description = "", timestamp = Sys.time()),
          list(name = "Economic losses in tourism", description = "", timestamp = Sys.time())
        ),
        responses = list(
          list(name = "Pollution regulations", description = "", timestamp = Sys.time()),
          list(name = "Beach cleanup programs", description = "", timestamp = Sys.time())
        )
      )

      # Add example connections
      rv$suggested_connections <- list(
        # Drivers → Activities
        list(from = "Economic development", to = "Coastal development", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
        list(from = "Economic development", to = "Tourism", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 2),
        list(from = "Consumer demand", to = "Tourism", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
        list(from = "Economic development", to = "Shipping", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 3),
        # Activities → Pressures
        list(from = "Coastal development", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 1),
        list(from = "Tourism", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 2, to_index = 1),
        list(from = "Shipping", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "medium", matrix = "p_a", from_index = 3, to_index = 1),
        list(from = "Coastal development", to = "Chemical pollution", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "weak", matrix = "p_a", from_index = 1, to_index = 2),
        # Pressures → States
        list(from = "Marine litter and plastics", to = "Water quality decline", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
        list(from = "Marine litter and plastics", to = "Habitat degradation", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
        list(from = "Chemical pollution", to = "Water quality decline", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 2, to_index = 1),
        # States → Impacts
        list(from = "Water quality decline", to = "Reduced water quality for recreation", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 2),
        list(from = "Habitat degradation", to = "Loss of tourism revenue", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "medium", matrix = "es_mpf", from_index = 2, to_index = 1),
        # Impacts → Welfare
        list(from = "Reduced water quality for recreation", to = "Health impacts from contamination", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 1),
        list(from = "Loss of tourism revenue", to = "Economic losses in tourism", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 2)
      )

      # Mark all connections as approved
      rv$approved_connections <- seq_along(rv$suggested_connections)
      rv$current_step <- 10
      removeModal()
      showNotification(i18n$t("modules.isa.marine_pollution_template_loaded_with_example_conn"), type = "message", duration = 5)
    })

    # Template: Coastal Tourism
    observeEvent(input$template_tourism, {
      rv$context <- list(
        project_name = "Coastal Tourism Management",
        ecosystem_type = "Coastal waters",
        main_issue = "Tourism impacts on coastal ecosystems"
      )
      rv$elements <- list(
        drivers = list(
          list(name = "Recreation and leisure", description = "", timestamp = Sys.time()),
          list(name = "Economic development", description = "", timestamp = Sys.time())
        ),
        activities = list(
          list(name = "Tourism and recreation", description = "", timestamp = Sys.time()),
          list(name = "Coastal development (hotels, infrastructure)", description = "", timestamp = Sys.time())
        ),
        pressures = list(
          list(name = "Physical habitat damage", description = "", timestamp = Sys.time()),
          list(name = "Pollution from tourists", description = "", timestamp = Sys.time())
        ),
        states = list(
          list(name = "Habitat degradation", description = "", timestamp = Sys.time()),
          list(name = "Loss of biodiversity", description = "", timestamp = Sys.time())
        ),
        impacts = list(
          list(name = "Reduced coastal protection", description = "", timestamp = Sys.time()),
          list(name = "Loss of cultural and aesthetic value", description = "", timestamp = Sys.time())
        ),
        welfare = list(
          list(name = "Reduced quality of life for residents", description = "", timestamp = Sys.time()),
          list(name = "Loss of cultural identity", description = "", timestamp = Sys.time())
        ),
        responses = list(
          list(name = "Sustainable tourism practices", description = "", timestamp = Sys.time()),
          list(name = "Coastal zone management", description = "", timestamp = Sys.time())
        )
      )

      # Add example connections
      rv$suggested_connections <- list(
        # Drivers → Activities
        list(from = "Recreation and leisure", to = "Tourism and recreation", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
        list(from = "Economic development", to = "Tourism and recreation", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 1),
        list(from = "Economic development", to = "Coastal development (hotels, infrastructure)", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 2),
        # Activities → Pressures
        list(from = "Tourism and recreation", to = "Physical habitat damage", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 1),
        list(from = "Tourism and recreation", to = "Pollution from tourists", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 2),
        list(from = "Coastal development (hotels, infrastructure)", to = "Physical habitat damage", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 2, to_index = 1),
        # Pressures → States
        list(from = "Physical habitat damage", to = "Habitat degradation", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
        list(from = "Physical habitat damage", to = "Loss of biodiversity", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
        list(from = "Pollution from tourists", to = "Habitat degradation", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 1),
        # States → Impacts
        list(from = "Habitat degradation", to = "Reduced coastal protection", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
        list(from = "Loss of biodiversity", to = "Loss of cultural and aesthetic value", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
        # Impacts → Welfare
        list(from = "Reduced coastal protection", to = "Reduced quality of life for residents", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "medium", matrix = "gb_es", from_index = 1, to_index = 1),
        list(from = "Loss of cultural and aesthetic value", to = "Reduced quality of life for residents", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 1),
        list(from = "Loss of cultural and aesthetic value", to = "Loss of cultural identity", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 2)
      )

      # Mark all connections as approved
      rv$approved_connections <- seq_along(rv$suggested_connections)
      rv$current_step <- 10
      removeModal()
      showNotification(i18n$t("modules.isa.coastal_tourism_template_loaded_with_example_conne"), type = "message", duration = 5)
    })

    # Template: Climate Change
    observeEvent(input$template_climate, {
      rv$context <- list(
        project_name = "Climate Change Impacts on Coral Reefs",
        ecosystem_type = "Coral reefs",
        main_issue = "Coral bleaching from rising temperatures"
      )
      rv$elements <- list(
        drivers = list(
          list(name = "Energy needs", description = "", timestamp = Sys.time()),
          list(name = "Economic development", description = "", timestamp = Sys.time())
        ),
        activities = list(
          list(name = "Greenhouse gas emissions", description = "", timestamp = Sys.time()),
          list(name = "Coastal development", description = "", timestamp = Sys.time())
        ),
        pressures = list(
          list(name = "Ocean temperature rise", description = "", timestamp = Sys.time()),
          list(name = "Ocean acidification", description = "", timestamp = Sys.time())
        ),
        states = list(
          list(name = "Coral bleaching", description = "", timestamp = Sys.time()),
          list(name = "Loss of coral reef ecosystem", description = "", timestamp = Sys.time())
        ),
        impacts = list(
          list(name = "Loss of fisheries productivity", description = "", timestamp = Sys.time()),
          list(name = "Reduced coastal protection from storms", description = "", timestamp = Sys.time())
        ),
        welfare = list(
          list(name = "Loss of livelihoods for fishing communities", description = "", timestamp = Sys.time()),
          list(name = "Increased vulnerability to storms", description = "", timestamp = Sys.time())
        ),
        responses = list(
          list(name = "Climate change mitigation", description = "", timestamp = Sys.time()),
          list(name = "Coral reef restoration", description = "", timestamp = Sys.time())
        )
      )

      # Add example connections
      rv$suggested_connections <- list(
        # Drivers → Activities
        list(from = "Energy needs", to = "Greenhouse gas emissions", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
        list(from = "Economic development", to = "Greenhouse gas emissions", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 1),
        list(from = "Economic development", to = "Coastal development", from_category = "drivers", to_category = "activities",
             polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
        # Activities → Pressures
        list(from = "Greenhouse gas emissions", to = "Ocean temperature rise", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 1),
        list(from = "Greenhouse gas emissions", to = "Ocean acidification", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 2),
        list(from = "Coastal development", to = "Ocean temperature rise", from_category = "activities", to_category = "pressures",
             polarity = "+", strength = "weak", matrix = "p_a", from_index = 2, to_index = 1),
        # Pressures → States
        list(from = "Ocean temperature rise", to = "Coral bleaching", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
        list(from = "Ocean temperature rise", to = "Loss of coral reef ecosystem", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 2),
        list(from = "Ocean acidification", to = "Coral bleaching", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 1),
        list(from = "Ocean acidification", to = "Loss of coral reef ecosystem", from_category = "pressures", to_category = "states",
             polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 2),
        # States → Impacts
        list(from = "Coral bleaching", to = "Loss of fisheries productivity", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
        list(from = "Loss of coral reef ecosystem", to = "Loss of fisheries productivity", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 1),
        list(from = "Loss of coral reef ecosystem", to = "Reduced coastal protection from storms", from_category = "states", to_category = "impacts",
             polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
        # Impacts → Welfare
        list(from = "Loss of fisheries productivity", to = "Loss of livelihoods for fishing communities", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 1),
        list(from = "Reduced coastal protection from storms", to = "Increased vulnerability to storms", from_category = "impacts", to_category = "welfare",
             polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 2)
      )

      # Mark all connections as approved
      rv$approved_connections <- seq_along(rv$suggested_connections)
      rv$current_step <- 10
      removeModal()
      showNotification(i18n$t("modules.isa.ai_assistant.climate_change_template_loaded_with_example_connections"), type = "message", duration = 5)
    })

    # Auto-save when ISA framework generation is complete (step 10)
    # This ensures auto-save module can recover the data without requiring manual save
    # Uses isolate() and a flag to prevent infinite loop
    observe({
      # Debug: log every time observer fires
      cat(sprintf("[AI ISA SAVE] Observer fired - current_step: %s\n",
                  if(is.null(rv$current_step)) "NULL" else rv$current_step))

      # Only trigger when step reaches 10
      if (!is.null(rv$current_step) && rv$current_step == 10) {
        cat(sprintf("[AI ISA SAVE] Step is 10, checking auto_saved_step_10 flag: %s\n",
                    isTRUE(rv$auto_saved_step_10)))

        # Use isolate() to prevent reactive loop when updating project_data_reactive
        isolate({
          # Check if auto-save is enabled
          if (!is.null(autosave_enabled_reactive) && !autosave_enabled_reactive()) {
            cat("[AI ISA SAVE] Skipping auto-save - auto-save is disabled in settings\n")
            return()
          }

          # Check if we've already auto-saved (prevent duplicate saves)
          if (!isTRUE(rv$auto_saved_step_10)) {
            # Check if data was loaded from template - if so, skip auto-save
            current_data <- project_data_reactive()
            if (!is.null(current_data$data$metadata$source) &&
                current_data$data$metadata$source %in% c("template_direct_load", "template_reviewed_load")) {
              cat("[AI ISA SAVE] Skipping auto-save - data is from template load\n")
              return()
            }

            total_elements <- sum(
              length(rv$elements$drivers), length(rv$elements$activities),
              length(rv$elements$pressures), length(rv$elements$states),
              length(rv$elements$impacts), length(rv$elements$welfare),
              length(rv$elements$responses)
            )

            cat(sprintf("[AI ISA SAVE] Total elements: %d (D:%d A:%d P:%d S:%d I:%d W:%d R/M:%d)\n",
                        total_elements,
                        length(rv$elements$drivers), length(rv$elements$activities),
                        length(rv$elements$pressures), length(rv$elements$states),
                        length(rv$elements$impacts), length(rv$elements$welfare),
                        length(rv$elements$responses)))

            if (total_elements > 0) {
              cat("[AI ISA] Auto-saving generated ISA framework to project data\n")

              # Set flag to prevent re-triggering
              rv$auto_saved_step_10 <- TRUE

          tryCatch({
            # Get current project data
            current_data <- project_data_reactive()

            # Initialize data structure if needed
            if (is.null(current_data) || length(current_data) == 0) {
              current_data <- list(data = list(isa_data = list()), last_modified = Sys.time())
            }
            if (is.null(current_data$data)) {
              current_data$data <- list(isa_data = list())
            }
            if (is.null(current_data$data$isa_data)) {
              current_data$data$isa_data <- list()
            }

            # Save all elements to project_data_reactive
            # (Using same logic as manual save)
            current_data$data$isa_data$drivers <- if (length(rv$elements$drivers) > 0) {
              data.frame(
                ID = paste0("D", sprintf("%03d", seq_along(rv$elements$drivers))),
                Name = sapply(rv$elements$drivers, function(x) x$name),
                Type = "Driver",
                Description = sapply(rv$elements$drivers, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$activities <- if (length(rv$elements$activities) > 0) {
              data.frame(
                ID = paste0("A", sprintf("%03d", seq_along(rv$elements$activities))),
                Name = sapply(rv$elements$activities, function(x) x$name),
                Type = "Activity",
                Description = sapply(rv$elements$activities, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$pressures <- if (length(rv$elements$pressures) > 0) {
              data.frame(
                ID = paste0("P", sprintf("%03d", seq_along(rv$elements$pressures))),
                Name = sapply(rv$elements$pressures, function(x) x$name),
                Type = "Pressure",
                Description = sapply(rv$elements$pressures, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$marine_processes <- if (length(rv$elements$states) > 0) {
              data.frame(
                ID = paste0("S", sprintf("%03d", seq_along(rv$elements$states))),
                Name = sapply(rv$elements$states, function(x) x$name),
                Type = "Marine Process/State",
                Description = sapply(rv$elements$states, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$ecosystem_services <- if (length(rv$elements$impacts) > 0) {
              data.frame(
                ID = paste0("I", sprintf("%03d", seq_along(rv$elements$impacts))),
                Name = sapply(rv$elements$impacts, function(x) x$name),
                Type = "Ecosystem Service/Impact",
                Description = sapply(rv$elements$impacts, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$goods_benefits <- if (length(rv$elements$welfare) > 0) {
              data.frame(
                ID = paste0("W", sprintf("%03d", seq_along(rv$elements$welfare))),
                Name = sapply(rv$elements$welfare, function(x) x$name),
                Type = "Good/Benefit/Welfare",
                Description = sapply(rv$elements$welfare, function(x) x$description %||% ""),
                Stakeholder = "", Importance = "", Trend = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(ID = character(), Name = character(), Type = character(),
                        Description = character(), Stakeholder = character(),
                        Importance = character(), Trend = character(),
                        stringsAsFactors = FALSE)
            }

            current_data$data$isa_data$responses <- if (length(rv$elements$responses) > 0) {
              data.frame(
                Name = sapply(rv$elements$responses, function(x) x$name),
                Description = sapply(rv$elements$responses, function(x) x$description %||% ""),
                Indicator = "",
                stringsAsFactors = FALSE
              )
            } else {
              data.frame(Name = character(), Description = character(), Indicator = character(),
                        stringsAsFactors = FALSE)
            }

            # Save connections (for AI ISA Assistant recovery)
            current_data$data$isa_data$connections <- list(
              suggested = rv$suggested_connections,
              approved = rv$approved_connections
            )

            # Build adjacency matrices from approved connections
            # Check if data came from Excel import - if so, preserve existing matrices
            data_source <- if (!is.null(current_data$data$metadata$data_source)) current_data$data$metadata$data_source else "ai_assistant"

            if (data_source == "excel_import") {
              cat("[AI ISA AUTO-SAVE] Data from Excel import detected - preserving existing adjacency matrices\n")
              # Don't overwrite adjacency matrices from imported data
              # Just ensure the structure exists
              if (is.null(current_data$data$isa_data$adjacency_matrices)) {
                current_data$data$isa_data$adjacency_matrices <- list()
              }
            } else {
              # Initialize all matrices to NULL first for AI-generated data
              # NEW DAPSIWRM forward causal flow
              current_data$data$isa_data$adjacency_matrices <- list(
                d_a = NULL,
                a_p = NULL,
                p_mpf = NULL,
                mpf_es = NULL,
                es_gb = NULL,
                gb_d = NULL,
                gb_r = NULL,
                r_d = NULL,
                r_a = NULL,
                r_p = NULL
              )
            }

            # If there are approved connections, build the matrices
            cat(sprintf("[AI ISA AUTO-SAVE] Approved connections count: %d\n", length(rv$approved_connections)))
            cat(sprintf("[AI ISA AUTO-SAVE] Approved connection indices: %s\n", paste(rv$approved_connections, collapse = ", ")))
            cat(sprintf("[AI ISA AUTO-SAVE] Total suggested connections: %d\n", length(rv$suggested_connections)))

            # Only build matrices from approved connections if data is NOT from Excel import
            if (data_source != "excel_import" && length(rv$approved_connections) > 0) {
              # Get dimensions for each matrix
              n_drivers <- length(rv$elements$drivers)
              n_activities <- length(rv$elements$activities)
              n_pressures <- length(rv$elements$pressures)
              n_states <- length(rv$elements$states)
              n_impacts <- length(rv$elements$impacts)
              n_welfare <- length(rv$elements$welfare)
              n_responses <- length(rv$elements$responses)

              cat(sprintf("[AI ISA AUTO-SAVE] Matrix dimensions: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R/M=%d\n",
                         n_drivers, n_activities, n_pressures, n_states, n_impacts, n_welfare, n_responses))

              # Initialize matrices with forward causal flow (SOURCE×TARGET format)
              
              # 1. Drivers → Activities (D→A)
              if (n_drivers > 0 && n_activities > 0) {
                current_data$data$isa_data$adjacency_matrices$d_a <- matrix(
                  "", nrow = n_drivers, ncol = n_activities,
                  dimnames = list(
                    sapply(rv$elements$drivers, function(x) x$name),
                    sapply(rv$elements$activities, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created d_a matrix (%d x %d)\n", n_drivers, n_activities))
              }

              # 2. Activities → Pressures (A→P)
              if (n_activities > 0 && n_pressures > 0) {
                current_data$data$isa_data$adjacency_matrices$a_p <- matrix(
                  "", nrow = n_activities, ncol = n_pressures,
                  dimnames = list(
                    sapply(rv$elements$activities, function(x) x$name),
                    sapply(rv$elements$pressures, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created a_p matrix (%d x %d)\n", n_activities, n_pressures))
              }

              # 3. Pressures → Marine Processes (P→MPF)
              if (n_pressures > 0 && n_states > 0) {
                current_data$data$isa_data$adjacency_matrices$p_mpf <- matrix(
                  "", nrow = n_pressures, ncol = n_states,
                  dimnames = list(
                    sapply(rv$elements$pressures, function(x) x$name),
                    sapply(rv$elements$states, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created p_mpf matrix (%d x %d)\n", n_pressures, n_states))
              }

              # 4. Marine Processes → Ecosystem Services (MPF→ES)
              if (n_states > 0 && n_impacts > 0) {
                current_data$data$isa_data$adjacency_matrices$mpf_es <- matrix(
                  "", nrow = n_states, ncol = n_impacts,
                  dimnames = list(
                    sapply(rv$elements$states, function(x) x$name),
                    sapply(rv$elements$impacts, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created mpf_es matrix (%d x %d)\n", n_states, n_impacts))
              }

              # 5. Ecosystem Services → Goods/Benefits (ES→GB)
              if (n_impacts > 0 && n_welfare > 0) {
                current_data$data$isa_data$adjacency_matrices$es_gb <- matrix(
                  "", nrow = n_impacts, ncol = n_welfare,
                  dimnames = list(
                    sapply(rv$elements$impacts, function(x) x$name),
                    sapply(rv$elements$welfare, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created es_gb matrix (%d x %d)\n", n_impacts, n_welfare))
              }

              # 6. Goods/Benefits → Drivers feedback (GB→D)
              if (n_welfare > 0 && n_drivers > 0) {
                current_data$data$isa_data$adjacency_matrices$gb_d <- matrix(
                  "", nrow = n_welfare, ncol = n_drivers,
                  dimnames = list(
                    sapply(rv$elements$welfare, function(x) x$name),
                    sapply(rv$elements$drivers, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created gb_d matrix (%d x %d)\n", n_welfare, n_drivers))
              }

              # 7. Goods/Benefits → Responses (GB→R)
              if (n_welfare > 0 && n_responses > 0) {
                current_data$data$isa_data$adjacency_matrices$gb_r <- matrix(
                  "", nrow = n_welfare, ncol = n_responses,
                  dimnames = list(
                    sapply(rv$elements$welfare, function(x) x$name),
                    sapply(rv$elements$responses, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created gb_r matrix (%d x %d)\n", n_welfare, n_responses))
              }

              # 8. Responses → Drivers (R→D management)
              if (n_responses > 0 && n_drivers > 0) {
                current_data$data$isa_data$adjacency_matrices$r_d <- matrix(
                  "", nrow = n_responses, ncol = n_drivers,
                  dimnames = list(
                    sapply(rv$elements$responses, function(x) x$name),
                    sapply(rv$elements$drivers, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created r_d matrix (%d x %d)\n", n_responses, n_drivers))
              }

              # 9. Responses → Activities (R→A management)
              if (n_responses > 0 && n_activities > 0) {
                current_data$data$isa_data$adjacency_matrices$r_a <- matrix(
                  "", nrow = n_responses, ncol = n_activities,
                  dimnames = list(
                    sapply(rv$elements$responses, function(x) x$name),
                    sapply(rv$elements$activities, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created r_a matrix (%d x %d)\n", n_responses, n_activities))
              }

              # 10. Responses → Pressures (R→P management)
              if (n_responses > 0 && n_pressures > 0) {
                current_data$data$isa_data$adjacency_matrices$r_p <- matrix(
                  "", nrow = n_responses, ncol = n_pressures,
                  dimnames = list(
                    sapply(rv$elements$responses, function(x) x$name),
                    sapply(rv$elements$responses, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created p_r matrix (%d x %d)\n", n_pressures, n_responses))
              }

              # Fill matrices with approved connections
              cat(sprintf("[AI ISA AUTO-SAVE] Processing %d approved connections...\n", length(rv$approved_connections)))
              for (conn_idx in rv$approved_connections) {
                conn <- rv$suggested_connections[[conn_idx]]

                cat(sprintf("[AI ISA AUTO-SAVE] Connection #%d: %s\n", conn_idx,
                           paste(names(conn), collapse = ", ")))
                cat(sprintf("[AI ISA AUTO-SAVE]   matrix=%s, from_index=%s, to_index=%s, polarity=%s, strength=%s\n",
                           conn$matrix %||% "NULL",
                           conn$from_index %||% "NULL",
                           conn$to_index %||% "NULL",
                           conn$polarity %||% "NULL",
                           conn$strength %||% "NULL"))

                # Format: "+strength:confidence"
                confidence <- conn$confidence %||% CONFIDENCE_DEFAULT
                value <- paste0(conn$polarity, conn$strength, ":", confidence)
                cat(sprintf("[AI ISA AUTO-SAVE]   Formatted value: %s\n", value))

                # Determine which matrix and indices (NEW: forward flow uses [from, to])
                if (conn$matrix == "d_a" && !is.null(current_data$data$isa_data$adjacency_matrices$d_a)) {
                  current_data$data$isa_data$adjacency_matrices$d_a[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to d_a[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "a_p" && !is.null(current_data$data$isa_data$adjacency_matrices$a_p)) {
                  current_data$data$isa_data$adjacency_matrices$a_p[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to a_p[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "p_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$p_mpf)) {
                  current_data$data$isa_data$adjacency_matrices$p_mpf[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to p_mpf[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "mpf_es" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_es)) {
                  current_data$data$isa_data$adjacency_matrices$mpf_es[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to mpf_es[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "es_gb" && !is.null(current_data$data$isa_data$adjacency_matrices$es_gb)) {
                  current_data$data$isa_data$adjacency_matrices$es_gb[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to es_gb[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "gb_d" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_d)) {
                  current_data$data$isa_data$adjacency_matrices$gb_d[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to gb_d[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "gb_r" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_r)) {
                  current_data$data$isa_data$adjacency_matrices$gb_r[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to gb_r[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "r_d" && !is.null(current_data$data$isa_data$adjacency_matrices$r_d)) {
                  current_data$data$isa_data$adjacency_matrices$r_d[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to r_d[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "r_a" && !is.null(current_data$data$isa_data$adjacency_matrices$r_a)) {
                  current_data$data$isa_data$adjacency_matrices$r_a[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to r_a[%d, %d]\n", conn$from_index, conn$to_index))
                } else if (conn$matrix == "r_p" && !is.null(current_data$data$isa_data$adjacency_matrices$r_p)) {
                  current_data$data$isa_data$adjacency_matrices$r_p[conn$from_index, conn$to_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to r_p[%d, %d]\n", conn$from_index, conn$to_index))
                } else {
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✗ FAILED to save - matrix '%s' not found or NULL\n", conn$matrix %||% "NULL"))
                }
              }
              cat("[AI ISA AUTO-SAVE] Finished processing all connections\n")
            }

            current_data$last_modified <- Sys.time()

            # Debug: verify data before saving
            cat(sprintf("[AI ISA] About to save - drivers: %d rows, activities: %d rows, connections: %d suggested (%d approved)\n",
              nrow(current_data$data$isa_data$drivers),
              nrow(current_data$data$isa_data$activities),
              length(rv$suggested_connections),
              length(rv$approved_connections)))

            # Update project_data_reactive
            project_data_reactive(current_data)

            # Debug: verify data after saving
            verify_data <- project_data_reactive()
            cat(sprintf("[AI ISA] Verification after save - drivers: %d rows, activities: %d rows\n",
              if(!is.null(verify_data$data$isa_data$drivers)) nrow(verify_data$data$isa_data$drivers) else 0,
              if(!is.null(verify_data$data$isa_data$activities)) nrow(verify_data$data$isa_data$activities) else 0))

              cat(sprintf("[AI ISA] Auto-saved %d total elements to project_data_reactive\n", total_elements))
            }, error = function(e) {
              cat(sprintf("[AI ISA] Auto-save error: %s\n", e$message))
            })
            }
          }
        })
      }
    })

    # Handle manual save to ISA
    # NOTE: Auto-save already saves when step reaches 10 (see observer at line 1955)
    # This button allows users to manually trigger save after editing elements
    observeEvent(input$save_to_isa, {
      cat("[AI ISA] Manual save to ISA clicked\n")

      # Check if auto-save already saved
      if (isTRUE(rv$auto_saved_step_10)) {
        showNotification(
          i18n$t("Your work is already saved automatically. Navigate to 'ISA Data Entry' to see your elements."),
          type = "message",
          duration = 5
        )
        cat("[AI ISA] Auto-save already completed, no manual save needed\n")
        return()
      }

      tryCatch({
        # Get current project data
        current_data <- project_data_reactive()
        cat("[AI ISA] Retrieved project data for manual save\n")

        # Initialize data structure if it doesn't exist
        if (is.null(current_data) || length(current_data) == 0) {
          cat("[AI ISA] Initializing new project data structure\n")
          current_data <- list(
            data = list(
              isa_data = list()
            ),
            last_modified = Sys.time()
          )
        }

        # Ensure isa_data structure exists
        if (is.null(current_data$data)) {
          cat("[AI ISA] Initializing data container\n")
          current_data$data <- list(isa_data = list())
        }
        if (is.null(current_data$data$isa_data)) {
          cat("[AI ISA] Initializing isa_data container\n")
          current_data$data$isa_data <- list()
        }

        cat(sprintf("[AI ISA] Manual saving %d drivers, %d activities, %d pressures, %d states, %d impacts, %d welfare, %d response measures\n",
                   length(rv$elements$drivers), length(rv$elements$activities),
                   length(rv$elements$pressures), length(rv$elements$states),
                   length(rv$elements$impacts), length(rv$elements$welfare),
                   length(rv$elements$responses)))

      # Convert AI Assistant elements to ISA dataframe format
      # CLD expects separate dataframes for each category

      # Create drivers dataframe
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$drivers) > 0) {
        current_data$data$isa_data$drivers <- data.frame(
          ID = paste0("D", sprintf("%03d", seq_along(rv$elements$drivers))),
          Name = sapply(rv$elements$drivers, function(x) x$name),
          Type = "Driver",
          Description = sapply(rv$elements$drivers, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$drivers <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create activities dataframe
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$activities) > 0) {
        current_data$data$isa_data$activities <- data.frame(
          ID = paste0("A", sprintf("%03d", seq_along(rv$elements$activities))),
          Name = sapply(rv$elements$activities, function(x) x$name),
          Type = "Activity",
          Description = sapply(rv$elements$activities, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$activities <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create pressures dataframe
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$pressures) > 0) {
        current_data$data$isa_data$pressures <- data.frame(
          ID = paste0("P", sprintf("%03d", seq_along(rv$elements$pressures))),
          Name = sapply(rv$elements$pressures, function(x) x$name),
          Type = "Pressure",
          Description = sapply(rv$elements$pressures, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$pressures <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create marine_processes dataframe (states)
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$states) > 0) {
        current_data$data$isa_data$marine_processes <- data.frame(
          ID = paste0("MPF", sprintf("%03d", seq_along(rv$elements$states))),
          Name = sapply(rv$elements$states, function(x) x$name),
          Type = "State Change",
          Description = sapply(rv$elements$states, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$marine_processes <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create ecosystem_services dataframe (impacts)
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$impacts) > 0) {
        current_data$data$isa_data$ecosystem_services <- data.frame(
          ID = paste0("ES", sprintf("%03d", seq_along(rv$elements$impacts))),
          Name = sapply(rv$elements$impacts, function(x) x$name),
          Type = "Impact",
          Description = sapply(rv$elements$impacts, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$ecosystem_services <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create goods_benefits dataframe (welfare)
      # Match Standard Entry structure: ID, Name, Type, Description, Stakeholder, Importance, Trend
      if (length(rv$elements$welfare) > 0) {
        current_data$data$isa_data$goods_benefits <- data.frame(
          ID = paste0("GB", sprintf("%03d", seq_along(rv$elements$welfare))),
          Name = sapply(rv$elements$welfare, function(x) x$name),
          Type = "Welfare",
          Description = sapply(rv$elements$welfare, function(x) x$description %||% ""),
          Stakeholder = "",
          Importance = "",
          Trend = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$goods_benefits <- data.frame(
          ID = character(), Name = character(), Type = character(),
          Description = character(), Stakeholder = character(),
          Importance = character(), Trend = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create responses dataframe
      if (length(rv$elements$responses) > 0) {
        current_data$data$isa_data$responses <- data.frame(
          name = sapply(rv$elements$responses, function(x) x$name),
          description = sapply(rv$elements$responses, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$responses <- data.frame(
          name = character(), description = character(), indicator = character(),
          stringsAsFactors = FALSE
        )
      }

      # Build adjacency matrices from approved connections
      # NEW DAPSIWRM forward causal flow
      current_data$data$isa_data$adjacency_matrices <- list(
        d_a = NULL,
        a_p = NULL,
        p_mpf = NULL,
        mpf_es = NULL,
        es_gb = NULL,
        gb_d = NULL,
        gb_r = NULL,
        r_d = NULL,
        r_a = NULL,
        r_p = NULL
      )

      # If there are approved connections, build the matrices
      cat(sprintf("[AI ISA CONNECTIONS] Approved connections count: %d\n", length(rv$approved_connections)))
      cat(sprintf("[AI ISA CONNECTIONS] Approved connection indices: %s\n", paste(rv$approved_connections, collapse = ", ")))
      cat(sprintf("[AI ISA CONNECTIONS] Total suggested connections: %d\n", length(rv$suggested_connections)))

      if (length(rv$approved_connections) > 0) {
        # Get dimensions for each matrix
        n_drivers <- length(rv$elements$drivers)
        n_activities <- length(rv$elements$activities)
        n_pressures <- length(rv$elements$pressures)
        n_states <- length(rv$elements$states)
        n_impacts <- length(rv$elements$impacts)
        n_welfare <- length(rv$elements$welfare)
        n_responses <- length(rv$elements$responses)

        cat(sprintf("[AI ISA CONNECTIONS] Matrix dimensions: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R=%d\n",
                   n_drivers, n_activities, n_pressures, n_states, n_impacts, n_welfare, n_responses))

        # Initialize matrices with forward causal flow (SOURCE×TARGET format)
        
        # 1. Drivers → Activities (D→A)
        if (n_drivers > 0 && n_activities > 0) {
          current_data$data$isa_data$adjacency_matrices$d_a <- matrix(
            "", nrow = n_drivers, ncol = n_activities,
            dimnames = list(
              sapply(rv$elements$drivers, function(x) x$name),
              sapply(rv$elements$activities, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created d_a matrix (%d x %d)\n", n_drivers, n_activities))
        }

        # 2. Activities → Pressures (A→P)
        if (n_activities > 0 && n_pressures > 0) {
          current_data$data$isa_data$adjacency_matrices$a_p <- matrix(
            "", nrow = n_activities, ncol = n_pressures,
            dimnames = list(
              sapply(rv$elements$activities, function(x) x$name),
              sapply(rv$elements$pressures, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created a_p matrix (%d x %d)\n", n_activities, n_pressures))
        }

        # 3. Pressures → Marine Processes (P→MPF)
        if (n_pressures > 0 && n_states > 0) {
          current_data$data$isa_data$adjacency_matrices$p_mpf <- matrix(
            "", nrow = n_pressures, ncol = n_states,
            dimnames = list(
              sapply(rv$elements$pressures, function(x) x$name),
              sapply(rv$elements$states, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created p_mpf matrix (%d x %d)\n", n_pressures, n_states))
        }

        # 4. Marine Processes → Ecosystem Services (MPF→ES)
        if (n_states > 0 && n_impacts > 0) {
          current_data$data$isa_data$adjacency_matrices$mpf_es <- matrix(
            "", nrow = n_states, ncol = n_impacts,
            dimnames = list(
              sapply(rv$elements$states, function(x) x$name),
              sapply(rv$elements$impacts, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created mpf_es matrix (%d x %d)\n", n_states, n_impacts))
        }

        # 5. Ecosystem Services → Goods/Benefits (ES→GB)
        if (n_impacts > 0 && n_welfare > 0) {
          current_data$data$isa_data$adjacency_matrices$es_gb <- matrix(
            "", nrow = n_impacts, ncol = n_welfare,
            dimnames = list(
              sapply(rv$elements$impacts, function(x) x$name),
              sapply(rv$elements$welfare, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created es_gb matrix (%d x %d)\n", n_impacts, n_welfare))
        }

        # 6. Goods/Benefits → Drivers feedback (GB→D)
        if (n_welfare > 0 && n_drivers > 0) {
          current_data$data$isa_data$adjacency_matrices$gb_d <- matrix(
            "", nrow = n_welfare, ncol = n_drivers,
            dimnames = list(
              sapply(rv$elements$welfare, function(x) x$name),
              sapply(rv$elements$drivers, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created gb_d matrix (%d x %d)\n", n_welfare, n_drivers))
        }

        # 7. Goods/Benefits → Responses (GB→R)
        if (n_welfare > 0 && n_responses > 0) {
          current_data$data$isa_data$adjacency_matrices$gb_r <- matrix(
            "", nrow = n_welfare, ncol = n_responses,
            dimnames = list(
              sapply(rv$elements$welfare, function(x) x$name),
              sapply(rv$elements$responses, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created gb_r matrix (%d x %d)\n", n_welfare, n_responses))
        }

        # 8. Responses → Drivers (R→D management)
        if (n_responses > 0 && n_drivers > 0) {
          current_data$data$isa_data$adjacency_matrices$r_d <- matrix(
            "", nrow = n_responses, ncol = n_drivers,
            dimnames = list(
              sapply(rv$elements$responses, function(x) x$name),
              sapply(rv$elements$drivers, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created r_d matrix (%d x %d)\n", n_responses, n_drivers))
        }

        # 9. Responses → Activities (R→A management)
        if (n_responses > 0 && n_activities > 0) {
          current_data$data$isa_data$adjacency_matrices$r_a <- matrix(
            "", nrow = n_responses, ncol = n_activities,
            dimnames = list(
              sapply(rv$elements$responses, function(x) x$name),
              sapply(rv$elements$activities, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created r_a matrix (%d x %d)\n", n_responses, n_activities))
        }

        # 10. Responses → Pressures (R→P management)
        if (n_responses > 0 && n_pressures > 0) {
          current_data$data$isa_data$adjacency_matrices$r_p <- matrix(
            "", nrow = n_responses, ncol = n_pressures,
            dimnames = list(
              sapply(rv$elements$responses, function(x) x$name),
              sapply(rv$elements$pressures, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created r_p matrix (%d x %d)\n", n_responses, n_pressures))
        }

        # Fill matrices with approved connections
        cat(sprintf("[AI ISA CONNECTIONS] Processing %d approved connections...\n", length(rv$approved_connections)))
        for (conn_idx in rv$approved_connections) {
          conn <- rv$suggested_connections[[conn_idx]]

          cat(sprintf("[AI ISA CONNECTIONS] Connection #%d: %s\n", conn_idx,
                     paste(names(conn), collapse = ", ")))
          cat(sprintf("[AI ISA CONNECTIONS]   matrix=%s, from_index=%s, to_index=%s, polarity=%s, strength=%s\n",
                     conn$matrix %||% "NULL",
                     conn$from_index %||% "NULL",
                     conn$to_index %||% "NULL",
                     conn$polarity %||% "NULL",
                     conn$strength %||% "NULL"))

          # Format: "+strength:confidence"
          confidence <- conn$confidence %||% CONFIDENCE_DEFAULT  # Default if not present
          value <- paste0(conn$polarity, conn$strength, ":", confidence)
          cat(sprintf("[AI ISA CONNECTIONS]   Formatted value: %s\n", value))

          # Determine which matrix and indices (NEW: forward flow uses [from, to])
          if (conn$matrix == "d_a" && !is.null(current_data$data$isa_data$adjacency_matrices$d_a)) {
            current_data$data$isa_data$adjacency_matrices$d_a[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to d_a[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "a_p" && !is.null(current_data$data$isa_data$adjacency_matrices$a_p)) {
            current_data$data$isa_data$adjacency_matrices$a_p[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to a_p[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "p_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$p_mpf)) {
            current_data$data$isa_data$adjacency_matrices$p_mpf[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to p_mpf[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "mpf_es" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_es)) {
            current_data$data$isa_data$adjacency_matrices$mpf_es[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to mpf_es[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "es_gb" && !is.null(current_data$data$isa_data$adjacency_matrices$es_gb)) {
            current_data$data$isa_data$adjacency_matrices$es_gb[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to es_gb[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "gb_d" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_d)) {
            current_data$data$isa_data$adjacency_matrices$gb_d[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to gb_d[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "gb_r" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_r)) {
            current_data$data$isa_data$adjacency_matrices$gb_r[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to gb_r[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "r_d" && !is.null(current_data$data$isa_data$adjacency_matrices$r_d)) {
            current_data$data$isa_data$adjacency_matrices$r_d[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to r_d[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "r_a" && !is.null(current_data$data$isa_data$adjacency_matrices$r_a)) {
            current_data$data$isa_data$adjacency_matrices$r_a[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to r_a[%d, %d]\n", conn$from_index, conn$to_index))
          } else if (conn$matrix == "r_p" && !is.null(current_data$data$isa_data$adjacency_matrices$r_p)) {
            current_data$data$isa_data$adjacency_matrices$r_p[conn$from_index, conn$to_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to r_p[%d, %d]\n", conn$from_index, conn$to_index))
          } else {
            cat(sprintf("[AI ISA CONNECTIONS]   ✗ FAILED to save - matrix '%s' not found or NULL\n", conn$matrix %||% "NULL"))
          }
        }
        cat("[AI ISA CONNECTIONS] Finished processing all connections\n")
      }

      # Add metadata
      current_data$data$isa_data$metadata <- list(
        project_name = rv$context$project_name %||% "Unnamed Project",
        location = rv$context$location %||% "",
        ecosystem_type = rv$context$ecosystem_type %||% "",
        main_issue = rv$context$main_issue %||% "",
        created_by = "AI ISA Assistant",
        created_at = Sys.time()
      )
      current_data$last_modified <- Sys.time()

        # Update the reactive value
        cat("[AI ISA] Updating project_data reactive\n")
        project_data_reactive(current_data)
        cat("[AI ISA] Project data updated successfully\n")

        # Count total elements
        total_elements <- sum(
          length(rv$elements$drivers),
          length(rv$elements$activities),
          length(rv$elements$pressures),
          length(rv$elements$states),
          length(rv$elements$impacts),
          length(rv$elements$welfare),
          length(rv$elements$responses)
        )

        # Count connections
        n_connections <- length(rv$approved_connections)

        cat(sprintf("[AI ISA] Save completed: %d elements, %d connections\n", total_elements, n_connections))

        showNotification(
          paste0(i18n$t("modules.isa.ai_assistant.model_saved_successfully"), " ", total_elements, " ", i18n$t("modules.isa.ai_assistant.elements_and"), " ",
                 n_connections, " ", i18n$t("modules.isa.ai_assistant.connections_transferred_to_isa_data_entry")),
          type = "message",
          duration = 5
        )

      }, error = function(e) {
        cat(sprintf("[AI ISA ERROR] Save failed: %s\n", e$message))
        cat(sprintf("[AI ISA ERROR] Call stack: %s\n", paste(sys.calls(), collapse = "\n")))

        showNotification(
          paste0(i18n$t("modules.isa.ai_assistant.error_saving_model"), " ", e$message),
          type = "error",
          duration = 10
        )
      })
    })

  })
}
