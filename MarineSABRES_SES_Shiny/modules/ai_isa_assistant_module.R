# modules/ai_isa_assistant_module.R
# AI-Assisted ISA Creation Module
# Purpose: Guide users through stepwise questions to build DAPSI(W)R(M) framework

# Load helper modules
source("modules/ai_isa_knowledge_base.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

ai_isa_assistant_ui <- function(id, i18n) {
  cat(sprintf("[AI ISA UI] UI function called with id: %s at %s\n", id, Sys.time()))
  ns <- NS(id)

  fluidPage(
    useShinyjs(),

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
        uiOutput(ns("module_header"))
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

ai_isa_assistant_server <- function(id, project_data_reactive, i18n, event_bus = NULL, autosave_enabled_reactive = NULL) {
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
        responses = list(),
        measures = list()
      ),
      context = list(
        project_name = NULL,
        regional_sea = NULL,
        ecosystem_type = NULL,
        ecosystem_subtype = NULL,
        main_issue = character(0)  # Changed to vector for multiple selections
      ),
      selected_issues = character(0),  # Track selected issues for UI highlighting
      total_steps = 11,  # Increased for regional sea + ecosystem context questions
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
            !is.null(isa_data$responses) && nrow(isa_data$responses) > 0,
            !is.null(isa_data$measures) && nrow(isa_data$measures) > 0
          )

          # Debug: print each element count
          cat(sprintf("[AI ISA] Element counts - drivers: %d, activities: %d, pressures: %d, states: %d, impacts: %d, welfare: %d, responses: %d, measures: %d\n",
            if(!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0,
            if(!is.null(isa_data$activities)) nrow(isa_data$activities) else 0,
            if(!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0,
            if(!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0,
            if(!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0,
            if(!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0,
            if(!is.null(isa_data$responses)) nrow(isa_data$responses) else 0,
            if(!is.null(isa_data$measures)) nrow(isa_data$measures) else 0
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

            # Measures
            if (!is.null(isa_data$measures) && nrow(isa_data$measures) > 0) {
              rv$elements$measures <- lapply(1:nrow(isa_data$measures), function(i) {
                list(
                  name = isa_data$measures$Name[i],
                  description = isa_data$measures$Description[i] %||% "",
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
              length(rv$elements$responses),
              length(rv$elements$measures)
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
        title = i18n$t("Regional Sea Context"),
        question = i18n$t("Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. Let's start by selecting your regional sea or ocean. This helps me provide relevant suggestions for your area."),
        type = "choice_regional_sea",
        target = "regional_sea"
      ),
      list(
        step = 1,
        title_key = "ecosystem",
        title = i18n$t("Ecosystem Type"),
        question = i18n$t("What type of marine ecosystem are you studying?"),
        type = "choice_ecosystem",
        target = "ecosystem_type"
      ),
      list(
        step = 2,
        title_key = "main_issue",
        title = i18n$t("Main Issue Identification"),
        question = i18n$t("What are the main environmental or management issues you're addressing? (Select all that apply)"),
        type = "choice_with_custom_multiple",  # Changed to support multiple selections
        target = "main_issue"
      ),
      list(
        step = 3,
        title_key = "drivers",
        title = i18n$t("Drivers - Societal Needs"),
        question = i18n$t("Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs?"),
        type = "multiple",
        target = "drivers",
        use_context_examples = TRUE
      ),
      list(
        step = 4,
        title_key = "activities",
        title = i18n$t("Activities - Human Actions"),
        question = i18n$t("Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area?"),
        type = "multiple",
        target = "activities",
        use_context_examples = TRUE
      ),
      list(
        step = 5,
        title_key = "pressures",
        title = i18n$t("Pressures - Environmental Stressors"),
        question = i18n$t("What PRESSURES do these activities put on the marine environment?"),
        type = "multiple",
        target = "pressures",
        use_context_examples = TRUE
      ),
      list(
        step = 6,
        title_key = "states",
        title = i18n$t("State Changes - Ecosystem Effects"),
        question = i18n$t("How do these pressures change the STATE of the marine ecosystem?"),
        type = "multiple",
        target = "states",
        use_context_examples = TRUE
      ),
      list(
        step = 7,
        title_key = "impacts",
        title = i18n$t("Impacts - Effects on Ecosystem Services"),
        question = i18n$t("What are the IMPACTS on ecosystem services and benefits? How do these changes affect what the ocean provides?"),
        type = "multiple",
        target = "impacts",
        use_context_examples = TRUE
      ),
      list(
        step = 8,
        title_key = "welfare",
        title = i18n$t("Welfare - Human Well-being Effects"),
        question = i18n$t("How do these impacts affect human WELFARE and well-being?"),
        type = "multiple",
        target = "welfare",
        use_context_examples = TRUE
      ),
      list(
        step = 9,
        title_key = "responses",
        title = i18n$t("Responses - Management Actions"),
        question = i18n$t("What RESPONSES or management actions are being taken (or could be taken) to address these issues?"),
        type = "multiple",
        target = "responses",
        use_context_examples = TRUE
      ),
      list(
        step = 10,
        title_key = "measures",
        title = i18n$t("Measures - Policy Instruments"),
        question = i18n$t("Finally, what specific MEASURES or policy instruments support these responses?"),
        type = "multiple",
        target = "measures",
        use_context_examples = TRUE
      ),
      list(
        step = 11,
        title_key = "connection_review",
        title = i18n$t("Connection Review"),
        question = i18n$t("Great! Now I'll suggest logical connections between the elements you've identified. These connections represent causal relationships in your social-ecological system. You can review and approve/reject each suggestion."),
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

    # ========== REACTIVE HEADER ==========

    output$module_header <- renderUI({
      tagList(
        h2(icon("robot"), " ", i18n$t("AI-Assisted Socio-Ecological System Creation"))
      )
    })

    # ========== REACTIVE SIDEBAR ==========

    output$sidebar_panel <- renderUI({
      ns <- session$ns
      box(
        title = i18n$t("Your SES Model Progress"),
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        # Progress indicator
        div(class = "step-indicator",
          icon("tasks"), " ",
          sprintf(i18n$t("Step %d of %d"), rv$current_step, rv$total_steps)
        ),

        # Breadcrumb navigation
        uiOutput(ns("breadcrumb_nav")),

        # Progress bar
        uiOutput(ns("progress_bar")),

        hr(),

        h4(icon("network-wired"), " ", i18n$t("Current Framework:")),
        tags$div(
          style = "margin-left: 10px;",
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_drivers"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Drivers:")), " ", textOutput(ns("count_drivers"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_activities"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Activities:")), " ", textOutput(ns("count_activities"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_pressures"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Pressures:")), " ", textOutput(ns("count_pressures"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_states"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("State Changes:")), " ", textOutput(ns("count_states"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_impacts"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Impacts:")), " ", textOutput(ns("count_impacts"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_welfare"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Welfare:")), " ", textOutput(ns("count_welfare"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_responses"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Responses:")), " ", textOutput(ns("count_responses"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px;",
            actionLink(ns("link_measures"),
                      tagList(icon("arrow-circle-right"), " ", strong(i18n$t("Measures:")), " ", textOutput(ns("count_measures"), inline = TRUE)),
                      style = "color: #007bff;")
          ),
          tags$div(
            style = "margin-bottom: 5px; margin-top: 10px; padding-top: 10px; border-top: 1px solid #ddd;",
            actionLink(ns("link_connections"),
                      tagList(icon("project-diagram"), " ", strong(i18n$t("Connections:")), " ", textOutput(ns("count_connections"), inline = TRUE)),
                      style = "color: #28a745; font-weight: bold;")
          )
        ),

        hr(),

        h5(icon("database"), " ", i18n$t("Session Management")),
        uiOutput(ns("save_status")),
        br(),
        fluidRow(
          column(6,
            actionButton(ns("manual_save"), i18n$t("Save Progress"),
                        icon = icon("save"),
                        class = "btn-primary btn-sm btn-block",
                        title = i18n$t("Save your current progress to browser storage"))
          ),
          column(6,
            actionButton(ns("load_session"), i18n$t("Load Saved"),
                        icon = icon("folder-open"),
                        class = "btn-secondary btn-sm btn-block",
                        title = i18n$t("Restore your last saved session"))
          )
        ),
        br(),

        hr(),

        actionButton(ns("preview_model"), i18n$t("Preview Model"),
                    icon = icon("eye"),
                    class = "btn-info btn-block"),
        br(),
        actionButton(ns("save_to_isa"), i18n$t("Save to ISA Data Entry"),
                    icon = icon("save"),
                    class = "btn-success btn-block"),
        br(),
        actionButton(ns("load_template"), i18n$t("Load Example Template"),
                    icon = icon("file-import"),
                    class = "btn-info btn-block"),
        br(),
        actionButton(ns("start_over"), i18n$t("Start Over"),
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
                                                responses=list(), measures=list())
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
          paste0(round(time_diff), " ", i18n$t("seconds ago"))
        } else {
          paste0(round(time_diff / 60), " ", i18n$t("minutes ago"))
        }

        div(class = "save-status",
          icon("check-circle"), " ", i18n$t("Auto-saved"), " ", time_text
        )
      } else {
        div(class = "save-status warning",
          icon("exclamation-triangle"), " ", i18n$t("Not yet saved")
        )
      }
    })

    # Manual save button
    observeEvent(input$manual_save, {
      session_data <- get_session_data()
      session$sendCustomMessage("save_ai_isa_session", session_data)
      rv$last_save_time <- Sys.time()

      showNotification(
        i18n$t("Session saved successfully!"),
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
          title = i18n$t("Restore Previous Session?"),
          paste0(i18n$t("Found a saved session from"),
                 " ",
                 format(as.POSIXct(input$loaded_session_data$timestamp), "%Y-%m-%d %H:%M:%S"),
                 ". ", i18n$t("Do you want to restore it?")),
          footer = tagList(
            actionButton(session$ns("confirm_load"), i18n$t("Yes, Restore"), class = "btn-primary"),
            modalButton(i18n$t("Cancel"))
          )
        ))

        # Store loaded data temporarily
        rv$temp_loaded_data <- loaded_data
      } else {
        showNotification(i18n$t("No saved session found."), type = "warning", duration = 3)
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
          i18n$t("A previous session was found. Click 'Load Saved' to restore it."),
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
                   "WELFARE", "RESPONSES", "MEASURES")

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
          p(i18n$t("Great work! You've completed all the steps. Review your connections and finalize your model."))
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
          # Connection review interface
          wellPanel(
            h4(icon("link"), " ", i18n$t("Review Suggested Connections")),
            p(i18n$t("Approve or reject each connection. You can modify the strength and polarity if needed.")),
            uiOutput(session$ns("connection_list")),
            br(),
            fluidRow(
              column(6,
                actionButton(session$ns("approve_all_connections"), i18n$t("Approve All"),
                            icon = icon("check-circle"),
                            class = "btn-success btn-block")
              ),
              column(6,
                actionButton(session$ns("finish_connections"), i18n$t("Finish & Continue"),
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
                             placeholder = i18n$t("Type your answer here..."),
                             rows = 3,
                             width = "100%"),
                actionButton(session$ns("submit_answer"), i18n$t("Submit Answer"),
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

    # Render connection list for review
    output$connection_list <- renderUI({
      if (length(rv$suggested_connections) == 0) {
        return(p(i18n$t("No connections to review.")))
      }

      lapply(seq_along(rv$suggested_connections), function(i) {
        conn <- rv$suggested_connections[[i]]
        is_approved <- i %in% rv$approved_connections

        div(
          style = paste0("border: 2px solid ",
                        if(is_approved) "#28a745" else "#ddd",
                        "; border-radius: 8px; padding: 15px; margin: 10px 0; background: ",
                        if(is_approved) "#d4edda" else "white",
                        "; max-width: 500px;"),

          # Connection header
          div(
            style = "margin-bottom: 15px;",
            strong(
              style = "font-size: 1.1em;",
              conn$from_name, " ",
              span(
                style = "color: #666; font-weight: normal;",
                textOutput(session$ns(paste0("polarity_text_", i)), inline = TRUE)
              ),
              " ", conn$to_name
            )
          ),

          # Two sliders stacked vertically - narrower with tooltips
          div(
            style = "margin-bottom: 10px;",
            div(
              style = "display: flex; align-items: center; gap: 5px;",
              strong(i18n$t("Strength:"), " ", textOutput(session$ns(paste0("strength_val_", i)), inline = TRUE)),
              tags$span(
                icon("info-circle"),
                style = "color: #17a2b8; cursor: help;",
                title = "1: Very Weak - Minimal influence\n2: Weak - Small influence\n3: Medium - Moderate influence\n4: Strong - Significant influence\n5: Very Strong - Major influence",
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            ),
            sliderInput(
              session$ns(paste0("strength_", i)),
              label = NULL,
              min = 1,
              max = 5,
              value = if(conn$strength == "weak") 2 else if(conn$strength == "medium") 3 else if(conn$strength == "strong") 4 else 3,
              step = 1,
              ticks = TRUE,
              width = "100%"
            )
          ),

          div(
            style = "margin-bottom: 15px;",
            div(
              style = "display: flex; align-items: center; gap: 5px;",
              strong(i18n$t("Confidence:"), " ", textOutput(session$ns(paste0("conf_val_", i)), inline = TRUE)),
              tags$span(
                icon("info-circle"),
                style = "color: #17a2b8; cursor: help;",
                title = "1: Very Low - Highly uncertain\n2: Low - Uncertain with limited evidence\n3: Medium - Moderately certain\n4: High - Confident with good evidence\n5: Very High - Highly confident, well-established",
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            ),
            sliderInput(
              session$ns(paste0("confidence_", i)),
              label = NULL,
              min = 1,
              max = 5,
              value = conn$confidence %||% 3,
              step = 1,
              ticks = TRUE,
              width = "100%"
            )
          ),

          # Action buttons with polarity switch aligned - all same height
          div(
            style = "display: flex; align-items: center; gap: 10px;",
            div(
              style = "width: 110px;",
              actionButton(session$ns(paste0("amend_conn_", i)),
                          i18n$t("Amend"),
                          icon = icon("edit"),
                          class = "btn-warning btn-sm",
                          style = "width: 100%; height: 32px; padding: 6px 8px;")
            ),
            div(
              style = "width: 110px;",
              if (is_approved) {
                actionButton(session$ns(paste0("reject_conn_", i)),
                            i18n$t("Reject"),
                            icon = icon("times"),
                            class = "btn-danger btn-sm",
                            style = "width: 100%; height: 32px; padding: 6px 8px;")
              } else {
                actionButton(session$ns(paste0("approve_conn_", i)),
                            i18n$t("Approve"),
                            icon = icon("check"),
                            class = "btn-success btn-sm",
                            style = "width: 100%; height: 32px; padding: 6px 8px;")
              }
            ),
            div(
              style = "width: 110px; display: flex; align-items: center; justify-content: flex-end;",
              if(is_approved) {
                span(style = "font-size: 0.85em; color: green; margin-right: 5px;", icon("check-circle"))
              } else {
                ""
              },
              shinyWidgets::switchInput(
                inputId = session$ns(paste0("polarity_", i)),
                value = conn$polarity == "+",
                onLabel = "+",
                offLabel = "-",
                onStatus = "success",
                offStatus = "danger",
                size = "small",
                width = "60px"
              )
            )
          )
        )
      })
    })

    # Render slider value displays
    observe({
      if (length(rv$suggested_connections) > 0) {
        lapply(seq_along(rv$suggested_connections), function(i) {
          local({
            idx <- i

            # Strength value display
            output[[paste0("strength_val_", idx)]] <- renderText({
              val <- input[[paste0("strength_", idx)]]
              if (is.null(val)) return("")
              strength_labels <- c("1" = "Very Weak", "2" = "Weak", "3" = "Medium", "4" = "Strong", "5" = "Very Strong")
              paste0("(", strength_labels[as.character(val)], ")")
            })

            # Confidence value display
            output[[paste0("conf_val_", idx)]] <- renderText({
              val <- input[[paste0("confidence_", idx)]]
              if (is.null(val)) return("")
              paste0("(", val, "/5)")
            })

            # Polarity text display (changes with switch)
            output[[paste0("polarity_text_", idx)]] <- renderText({
              polarity_val <- input[[paste0("polarity_", idx)]]
              if (is.null(polarity_val)) {
                # Use initial connection polarity
                conn <- rv$suggested_connections[[idx]]
                if (conn$polarity == "+") {
                  return("drives/increases")
                } else {
                  return("affects/reduces")
                }
              }
              # Switch is TRUE for positive, FALSE for negative
              if (isTRUE(polarity_val)) {
                "drives/increases"
              } else {
                "affects/reduces"
              }
            })
          })
        })
      }
    })

    # Storage for observer handles to prevent duplicates
    connection_observers <- reactiveVal(list())

    # Create observers when connections are generated
    observeEvent(rv$suggested_connections, {
      # Clear old observers
      old_observers <- connection_observers()
      for (obs in old_observers) {
        obs$destroy()
      }

      # Create new observers for each connection
      new_observers <- list()

      if (length(rv$suggested_connections) > 0) {
        for (i in seq_along(rv$suggested_connections)) {
          local({
            # Capture index in closure
            conn_idx <- i

            # Approve observer
            approve_obs <- observeEvent(input[[paste0("approve_conn_", conn_idx)]], {
              if (!(conn_idx %in% isolate(rv$approved_connections))) {
                rv$approved_connections <- c(isolate(rv$approved_connections), conn_idx)
                cat(sprintf("[AI ISA CONNECTIONS] Connection #%d APPROVED (total approved: %d)\n",
                           conn_idx, length(rv$approved_connections)))
              }
            }, ignoreInit = TRUE)
            new_observers[[length(new_observers) + 1]] <<- approve_obs

            # Reject observer
            reject_obs <- observeEvent(input[[paste0("reject_conn_", conn_idx)]], {
              rv$approved_connections <- setdiff(isolate(rv$approved_connections), conn_idx)
              cat(sprintf("[AI ISA CONNECTIONS] Connection #%d REJECTED (total approved: %d)\n",
                         conn_idx, length(rv$approved_connections)))
            }, ignoreInit = TRUE)
            new_observers[[length(new_observers) + 1]] <<- reject_obs

            # Amend observer
            amend_obs <- observeEvent(input[[paste0("amend_conn_", conn_idx)]], {
              # Get current slider/switch values
              polarity_val <- input[[paste0("polarity_", conn_idx)]]
              strength_val <- input[[paste0("strength_", conn_idx)]]
              confidence_val <- input[[paste0("confidence_", conn_idx)]]

              # Debug logging
              cat(sprintf("[AI ISA AMEND DEBUG] Connection #%d - Raw polarity_val: %s (class: %s)\n",
                         conn_idx,
                         if(is.null(polarity_val)) "NULL" else as.character(polarity_val),
                         if(is.null(polarity_val)) "NULL" else class(polarity_val)))

              # Convert values - handle NULL polarity by keeping original
              if (is.null(polarity_val)) {
                polarity <- rv$suggested_connections[[conn_idx]]$polarity
                cat(sprintf("[AI ISA AMEND DEBUG] Polarity is NULL, using original: %s\n", polarity))
              } else {
                polarity <- if(isTRUE(polarity_val)) "+" else "-"
                cat(sprintf("[AI ISA AMEND DEBUG] Polarity converted from %s to %s\n", polarity_val, polarity))
              }

              strength_labels <- c("1" = "very weak", "2" = "weak", "3" = "medium", "4" = "strong", "5" = "very strong")
              strength <- strength_labels[as.character(strength_val)]

              # Update the connection in suggested_connections
              rv$suggested_connections[[conn_idx]]$polarity <- polarity
              rv$suggested_connections[[conn_idx]]$strength <- strength
              rv$suggested_connections[[conn_idx]]$confidence <- confidence_val

              cat(sprintf("[AI ISA CONNECTIONS] Connection #%d AMENDED: polarity=%s, strength=%s, confidence=%d\n",
                         conn_idx, polarity, strength, confidence_val))

              showNotification(
                paste0(i18n$t("Connection"), " #", conn_idx, " ", i18n$t("updated successfully!")),
                type = "message",
                duration = 2
              )
            }, ignoreInit = TRUE)
            new_observers[[length(new_observers) + 1]] <<- amend_obs
          })
        }
      }

      connection_observers(new_observers)
    }, ignoreInit = FALSE)

    # Approve all connections
    observeEvent(input$approve_all_connections, {
      rv$approved_connections <- seq_along(rv$suggested_connections)
      cat(sprintf("[AI ISA CONNECTIONS] APPROVE ALL clicked - approved %d connections\n",
                 length(rv$approved_connections)))
      showNotification(i18n$t("All connections approved!"), type = "message")
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
             message = paste0(i18n$t("Great! You've approved"), " ", approved_count, " ",
                            i18n$t("connections out of"), " ",
                            length(rv$suggested_connections), " ", i18n$t("suggested connections."), " ",
                            i18n$t("These connections will be included in your saved ISA data.")),
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

      current_data$data$isa_data$measures <- if (length(rv$elements$measures) > 0) {
        data.frame(
          ID = paste0("M", sprintf("%03d", seq_along(rv$elements$measures))),
          Name = sapply(rv$elements$measures, function(x) x$name),
          Type = "Measure",
          Description = sapply(rv$elements$measures, function(x) x$description %||% ""),
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
      n_measures <- length(rv$elements$measures)

      # Initialize adjacency matrices list
      current_data$data$isa_data$adjacency_matrices <- list(
        gb_es = NULL, es_mpf = NULL, mpf_p = NULL,
        p_a = NULL, a_d = NULL, d_gb = NULL,
        p_r = NULL, r_m = NULL
      )

      # Create matrices if elements exist
      if (n_welfare > 0 && n_drivers > 0) {
        current_data$data$isa_data$adjacency_matrices$d_gb <- matrix(
          "", nrow = n_drivers, ncol = n_welfare,
          dimnames = list(
            sapply(rv$elements$drivers, function(x) x$name),
            sapply(rv$elements$welfare, function(x) x$name)
          )
        )
      }

      if (n_drivers > 0 && n_activities > 0) {
        current_data$data$isa_data$adjacency_matrices$a_d <- matrix(
          "", nrow = n_activities, ncol = n_drivers,
          dimnames = list(
            sapply(rv$elements$activities, function(x) x$name),
            sapply(rv$elements$drivers, function(x) x$name)
          )
        )
      }

      if (n_activities > 0 && n_pressures > 0) {
        current_data$data$isa_data$adjacency_matrices$p_a <- matrix(
          "", nrow = n_pressures, ncol = n_activities,
          dimnames = list(
            sapply(rv$elements$pressures, function(x) x$name),
            sapply(rv$elements$activities, function(x) x$name)
          )
        )
      }

      if (n_pressures > 0 && n_states > 0) {
        current_data$data$isa_data$adjacency_matrices$mpf_p <- matrix(
          "", nrow = n_states, ncol = n_pressures,
          dimnames = list(
            sapply(rv$elements$states, function(x) x$name),
            sapply(rv$elements$pressures, function(x) x$name)
          )
        )
      }

      if (n_states > 0 && n_impacts > 0) {
        current_data$data$isa_data$adjacency_matrices$es_mpf <- matrix(
          "", nrow = n_impacts, ncol = n_states,
          dimnames = list(
            sapply(rv$elements$impacts, function(x) x$name),
            sapply(rv$elements$states, function(x) x$name)
          )
        )
      }

      if (n_impacts > 0 && n_welfare > 0) {
        current_data$data$isa_data$adjacency_matrices$gb_es <- matrix(
          "", nrow = n_welfare, ncol = n_impacts,
          dimnames = list(
            sapply(rv$elements$welfare, function(x) x$name),
            sapply(rv$elements$impacts, function(x) x$name)
          )
        )
      }

      if (n_responses > 0 && n_pressures > 0) {
        current_data$data$isa_data$adjacency_matrices$p_r <- matrix(
          "", nrow = n_pressures, ncol = n_responses,
          dimnames = list(
            sapply(rv$elements$pressures, function(x) x$name),
            sapply(rv$elements$responses, function(x) x$name)
          )
        )
      }

      if (n_measures > 0 && n_responses > 0) {
        current_data$data$isa_data$adjacency_matrices$r_m <- matrix(
          "", nrow = n_responses, ncol = n_measures,
          dimnames = list(
            sapply(rv$elements$responses, function(x) x$name),
            sapply(rv$elements$measures, function(x) x$name)
          )
        )
      }

      # Fill matrices with approved connections
      if (length(rv$approved_connections) > 0) {
        for (conn_idx in rv$approved_connections) {
          conn <- rv$suggested_connections[[conn_idx]]
          confidence <- conn$confidence %||% 3
          value <- paste0(conn$polarity, conn$strength, ":", confidence)

          if (conn$matrix == "a_d" && !is.null(current_data$data$isa_data$adjacency_matrices$a_d)) {
            current_data$data$isa_data$adjacency_matrices$a_d[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "p_a" && !is.null(current_data$data$isa_data$adjacency_matrices$p_a)) {
            current_data$data$isa_data$adjacency_matrices$p_a[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "mpf_p" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_p)) {
            current_data$data$isa_data$adjacency_matrices$mpf_p[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "es_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$es_mpf)) {
            current_data$data$isa_data$adjacency_matrices$es_mpf[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "gb_es" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_es)) {
            current_data$data$isa_data$adjacency_matrices$gb_es[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "d_gb" && !is.null(current_data$data$isa_data$adjacency_matrices$d_gb)) {
            current_data$data$isa_data$adjacency_matrices$d_gb[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "p_r" && !is.null(current_data$data$isa_data$adjacency_matrices$p_r)) {
            current_data$data$isa_data$adjacency_matrices$p_r[conn$to_index, conn$from_index] <- value
          } else if (conn$matrix == "r_m" && !is.null(current_data$data$isa_data$adjacency_matrices$r_m)) {
            current_data$data$isa_data$adjacency_matrices$r_m[conn$to_index, conn$from_index] <- value
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
        paste0(approved_count, " connections saved! Navigate to 'ISA Data Entry' or 'CLD Visualization' to view your model."),
        type = "message",
        duration = 5
      )
    })

    # Render continue button with context-aware label
    output$continue_button <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        # Determine button label based on next step
        button_label <- i18n$t("Skip This Question")
        button_icon <- icon("forward")

        if (rv$current_step + 1 < length(QUESTION_FLOW)) {
          next_step <- QUESTION_FLOW[[rv$current_step + 2]]

          # Create context-aware labels using title_key
          if (next_step$title_key == "activities") {
            button_label <- i18n$t("Continue to Activities")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "pressures") {
            button_label <- i18n$t("Continue to Pressures")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "states") {
            button_label <- i18n$t("Continue to State Changes")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "impacts") {
            button_label <- i18n$t("Continue to Impacts")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "welfare") {
            button_label <- i18n$t("Continue to Welfare")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "responses") {
            button_label <- i18n$t("Continue to Responses")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "measures") {
            button_label <- i18n$t("Continue to Measures")
            button_icon <- icon("arrow-right")
          } else if (next_step$title_key == "connection_review") {
            button_label <- i18n$t("Finish")
            button_icon <- icon("check")
          } else {
            button_label <- i18n$t("Continue")
            button_icon <- icon("arrow-right")
          }
        } else {
          button_label <- i18n$t("Finish")
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
      quick_options_exec_count <<- quick_options_exec_count + 1
      current_step <- rv$current_step

      cat(sprintf("\n========================================\n"))
      cat(sprintf("[AI ISA QUICK] EXECUTION #%d at %s\n", quick_options_exec_count, Sys.time()))
      cat(sprintf("[AI ISA QUICK] Current step: %d / %d\n", current_step, length(QUESTION_FLOW)))

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
            cat(sprintf("[AI ISA QUICK]   Button ID: %s\n", button_id))
            actionButton(
              inputId = button_id,
              label = sea_info$name_i18n,
              class = "quick-option",
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
            label = i18n$t("Other"),
            class = "quick-option",
            style = "margin: 3px; min-width: 150px; background-color: #f0f0f0;"
          )

          return(div(
            h5(style = "font-weight: 600; color: #667eea;", i18n$t("Select your regional sea:")),
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
              label = i18n$t("Other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 140px; background-color: #f0f0f0;"
            )
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 paste0(i18n$t("Common ecosystem types in"), " ",
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
              label = i18n$t("Other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 160px; background-color: #f0f0f0;"
            )
            # Add Continue button if at least one issue selected
            continue_button <- NULL
            if (length(rv$selected_issues) > 0) {
              continue_button <- actionButton(
                inputId = session$ns(paste0("continue_issues", render_suffix)),
                label = paste0(i18n$t("Continue with"), " ", length(rv$selected_issues), " ",
                              i18n$t("selected issue(s)")),
                class = "btn btn-success",
                style = "margin: 10px 3px; min-width: 200px;",
                icon = icon("arrow-right")
              )
            }
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 i18n$t("Common issues in your region:")),
              p(style = "font-size: 0.9em; color: #666; margin-top: 5px;",
                i18n$t("Click to select/deselect. Multiple selections allowed.")),
              div(style = "margin-top: 10px;", issue_buttons, other_button),
              if (!is.null(continue_button)) div(style = "margin-top: 10px;", continue_button)
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
              label = i18n$t("Other"),
              class = "quick-option",
              style = "margin: 3px; min-width: 160px; background-color: #f0f0f0;"
            )
            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 i18n$t("Common issues in your region:")),
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
                " (", i18n$t("tailored for"), " ",
                REGIONAL_SEAS[[rv$context$regional_sea]]$name_i18n,
                if (!is.null(rv$context$ecosystem_type)) paste0(" - ", rv$context$ecosystem_type) else "",
                ")"
              )
            }

            # Add "Other" button
            other_button <- actionButton(
              inputId = session$ns("dapsiwrm_other"),
              label = i18n$t("Other (enter your own)"),
              class = "quick-option",
              style = "margin: 3px; background-color: #f0f0f0;"
            )

            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 paste0(i18n$t("AI-suggested options"), context_info, ":")),
              p(style = "font-size: 0.9em; color: #666; margin-top: 5px;",
                i18n$t("Click to select/deselect. Multiple selections allowed.")),
              div(style = "margin-top: 10px;", suggestion_buttons, other_button)
            ))
          }
        }

        # Fallback for old static examples (backwards compatibility)
        else if (!is.null(step_info$examples)) {
          tagList(
            h5(i18n$t("Quick options (click to add):")),
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

    # Create observers for quick option buttons (only once per step)
    observe({
      current_step <- rv$current_step

      # Only set up new observers if we haven't already for this step
      if (current_step != quick_observers_setup_for_step()) {
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
                    rv$context$regional_sea <- sea_key

                    ai_response <- paste0(
                      i18n$t("Great! You selected"), " ", REGIONAL_SEAS[[sea_key]]$name_i18n, ". ",
                      i18n$t("This will help me suggest relevant activities and pressures specific to your region.")
                    )
                    rv$conversation <- c(rv$conversation, list(
                      list(type = "ai", message = ai_response, timestamp = Sys.time())
                    ))

                    move_to_next_step()
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
                        i18n$t("Perfect!"), " ", ecosystem_name, " ",
                        i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
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

              # Observer for Continue button
              observeEvent(input[[paste0("continue_issues_s", current_step)]], {
                if (rv$current_step == current_step && length(rv$selected_issues) > 0) {
                  cat(sprintf("[AI ISA] Continuing with %d selected issues\n", length(rv$selected_issues)))

                  # Save selected issues to context
                  rv$context$main_issue <- rv$selected_issues

                  # Create AI response
                  issue_list <- paste(rv$selected_issues, collapse = ", ")
                  ai_response <- paste0(
                    i18n$t("Great! I'll focus suggestions on these issues: "), issue_list, ". ",
                    i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
                  )
                  rv$conversation <- c(rv$conversation, list(
                    list(type = "ai", message = ai_response, timestamp = Sys.time())
                  ))

                  move_to_next_step()
                }
              }, ignoreInit = TRUE, once = TRUE)
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
                        i18n$t("Understood. I'll focus suggestions on"), " ", tolower(issue_name), "-related issues. ",
                        i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
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

          # Mark this step as having observers set up
          quick_observers_setup_for_step(current_step)
        }
      }
    })

    # Handle skip
    observeEvent(input$skip_question, {
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
              i18n$t("Great! You selected"), " ", REGIONAL_SEAS[[matched_sea]]$name_i18n, ". ",
              i18n$t("This will help me suggest relevant activities and pressures specific to your region.")
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
            i18n$t("Perfect!"), " ", answer, " ",
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

          # AI response with count
          ai_response <- paste0(i18n$t("Added"), " '", answer, "' (", element_count, " ", step_info$target, " ", i18n$t("total"), "). ", i18n$t("Click quick options to add more, or click the green button to continue."))

          # Add AI response
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

        } else {
          # Store single value
          rv$context[[step_info$target]] <- answer

          # Add AI response BEFORE moving to next step
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = i18n$t("Thank you! Moving to the next question..."), timestamp = Sys.time())
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

      # Special case: Responses/Measures → Pressures
      if ((from_type %in% c("responses", "measures")) && to_type == "pressures") {
        # Responses/measures typically reduce pressures
        return("-")
      }

      # Special case: Responses/Measures → States
      if ((from_type %in% c("responses", "measures")) && to_type == "states") {
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

    # Generate logical connections based on DAPSI(W)R(M) framework
    generate_connections <- function(elements) {
      connections <- list()
      MAX_CONNECTIONS <- 50  # Limit to prevent browser freeze

      cat(sprintf("[AI ISA CONNECTIONS] Generating connections (max: %d)...\n", MAX_CONNECTIONS))

      # D → A (Drivers → Activities): Intelligent polarity detection
      if (length(elements$drivers) > 0 && length(elements$activities) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$drivers)) {
          for (j in seq_along(elements$activities)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$drivers[[i]]$name, elements$activities[[j]]$name, "drivers", "activities")
            connections[[length(connections) + 1]] <- list(
              from_type = "drivers",
              from_index = i,
              from_name = elements$drivers[[i]]$name,
              to_type = "activities",
              to_index = j,
              to_name = elements$activities[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = CONFIDENCE_DEFAULT,
              rationale = paste(elements$drivers[[i]]$name, "drives", elements$activities[[j]]$name),
              matrix = "a_d"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # A → P (Activities → Pressures): Intelligent polarity detection
      if (length(elements$activities) > 0 && length(elements$pressures) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$activities)) {
          for (j in seq_along(elements$pressures)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$activities[[i]]$name, elements$pressures[[j]]$name, "activities", "pressures")
            connections[[length(connections) + 1]] <- list(
              from_type = "activities",
              from_index = i,
              from_name = elements$activities[[i]]$name,
              to_type = "pressures",
              to_index = j,
              to_name = elements$pressures[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = CONFIDENCE_DEFAULT,
              rationale = paste(elements$activities[[i]]$name, "causes", elements$pressures[[j]]$name),
              matrix = "p_a"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # P → S (Pressures → States): Intelligent polarity detection
      if (length(elements$pressures) > 0 && length(elements$states) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$pressures)) {
          for (j in seq_along(elements$states)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$pressures[[i]]$name, elements$states[[j]]$name, "pressures", "states")
            connections[[length(connections) + 1]] <- list(
              from_type = "pressures",
              from_index = i,
              from_name = elements$pressures[[i]]$name,
              to_type = "states",
              to_index = j,
              to_name = elements$states[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$pressures[[i]]$name, if(polarity == "+") "increases" else "decreases", elements$states[[j]]$name),
              matrix = "mpf_p"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # S → I (States → Impacts): Intelligent polarity detection
      if (length(elements$states) > 0 && length(elements$impacts) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$states)) {
          for (j in seq_along(elements$impacts)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$states[[i]]$name, elements$impacts[[j]]$name, "states", "impacts")
            connections[[length(connections) + 1]] <- list(
              from_type = "states",
              from_index = i,
              from_name = elements$states[[i]]$name,
              to_type = "impacts",
              to_index = j,
              to_name = elements$impacts[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$states[[i]]$name, "impacts", elements$impacts[[j]]$name),
              matrix = "es_mpf"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # I → W (Impacts → Welfare): Intelligent polarity detection
      if (length(elements$impacts) > 0 && length(elements$welfare) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$impacts)) {
          for (j in seq_along(elements$welfare)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$impacts[[i]]$name, elements$welfare[[j]]$name, "impacts", "welfare")
            connections[[length(connections) + 1]] <- list(
              from_type = "impacts",
              from_index = i,
              from_name = elements$impacts[[i]]$name,
              to_type = "welfare",
              to_index = j,
              to_name = elements$welfare[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$impacts[[i]]$name, if(polarity == "+") "increases" else "reduces", elements$welfare[[j]]$name),
              matrix = "gb_es"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # R → P (Responses → Pressures): Intelligent polarity detection
      if (length(elements$responses) > 0 && length(elements$pressures) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$responses)) {
          for (j in seq_along(elements$pressures)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$responses[[i]]$name, elements$pressures[[j]]$name, "responses", "pressures")
            connections[[length(connections) + 1]] <- list(
              from_type = "responses",
              from_index = i,
              from_name = elements$responses[[i]]$name,
              to_type = "pressures",
              to_index = j,
              to_name = elements$pressures[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$responses[[i]]$name, if(polarity == "-") "aims to reduce" else "supports", elements$pressures[[j]]$name),
              matrix = "p_r"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # M → R (Measures → Responses): Intelligent polarity detection
      if (length(elements$measures) > 0 && length(elements$responses) > 0 && length(connections) < MAX_CONNECTIONS) {
        for (i in seq_along(elements$measures)) {
          for (j in seq_along(elements$responses)) {
            if (length(connections) >= MAX_CONNECTIONS) break
            polarity <- detect_polarity(elements$measures[[i]]$name, elements$responses[[j]]$name, "measures", "responses")
            connections[[length(connections) + 1]] <- list(
              from_type = "measures",
              from_index = i,
              from_name = elements$measures[[i]]$name,
              to_type = "responses",
              to_index = j,
              to_name = elements$responses[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$measures[[i]]$name, "supports", elements$responses[[j]]$name),
              matrix = "r_m"
            )
          }
          if (length(connections) >= MAX_CONNECTIONS) break
        }
      }

      # ========================================================================
      # FEEDBACK LOOPS - Additional logical connections
      # ========================================================================

      # W → D (Welfare/Goods & Benefits → Drivers): Feedback loop
      # E.g., "Increased local wellbeing drives policy changes" or "Economic benefits drive further investment"
      if (length(elements$welfare) > 0 && length(elements$drivers) > 0) {
        for (i in seq_along(elements$welfare)) {
          for (j in seq_along(elements$drivers)) {
            polarity <- detect_polarity(elements$welfare[[i]]$name, elements$drivers[[j]]$name, "welfare", "drivers")
            connections[[length(connections) + 1]] <- list(
              from_type = "welfare",
              from_index = i,
              from_name = elements$welfare[[i]]$name,
              to_type = "drivers",
              to_index = j,
              to_name = elements$drivers[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$welfare[[i]]$name, if(polarity == "+") "reinforces" else "reduces", elements$drivers[[j]]$name),
              matrix = "d_gb"  # Feedback: goods/benefits back to drivers
            )
          }
        }
      }

      # W → R (Welfare/Goods & Benefits → Responses): Feedback loop
      # E.g., "Improved public health drives policy responses" or "Economic losses trigger management actions"
      if (length(elements$welfare) > 0 && length(elements$responses) > 0) {
        for (i in seq_along(elements$welfare)) {
          for (j in seq_along(elements$responses)) {
            polarity <- detect_polarity(elements$welfare[[i]]$name, elements$responses[[j]]$name, "welfare", "responses")
            connections[[length(connections) + 1]] <- list(
              from_type = "welfare",
              from_index = i,
              from_name = elements$welfare[[i]]$name,
              to_type = "responses",
              to_index = j,
              to_name = elements$responses[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$welfare[[i]]$name, if(polarity == "+") "motivates" else "reduces", elements$responses[[j]]$name),
              matrix = "r_gb"  # Feedback: goods/benefits to responses
            )
          }
        }
      }

      # W → M (Welfare/Goods & Benefits → Measures): Feedback loop
      # E.g., "Declining fisheries income drives implementation of quotas"
      if (length(elements$welfare) > 0 && length(elements$measures) > 0) {
        for (i in seq_along(elements$welfare)) {
          for (j in seq_along(elements$measures)) {
            polarity <- detect_polarity(elements$welfare[[i]]$name, elements$measures[[j]]$name, "welfare", "measures")
            connections[[length(connections) + 1]] <- list(
              from_type = "welfare",
              from_index = i,
              from_name = elements$welfare[[i]]$name,
              to_type = "measures",
              to_index = j,
              to_name = elements$measures[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$welfare[[i]]$name, if(polarity == "+") "drives implementation of" else "reduces need for", elements$measures[[j]]$name),
              matrix = "m_gb"  # Feedback: goods/benefits to measures
            )
          }
        }
      }

      # R → D (Responses → Drivers): Feedback loop
      # E.g., "Conservation policies drive public awareness" or "Management responses reduce economic drivers"
      if (length(elements$responses) > 0 && length(elements$drivers) > 0) {
        for (i in seq_along(elements$responses)) {
          for (j in seq_along(elements$drivers)) {
            polarity <- detect_polarity(elements$responses[[i]]$name, elements$drivers[[j]]$name, "responses", "drivers")
            connections[[length(connections) + 1]] <- list(
              from_type = "responses",
              from_index = i,
              from_name = elements$responses[[i]]$name,
              to_type = "drivers",
              to_index = j,
              to_name = elements$drivers[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$responses[[i]]$name, if(polarity == "+") "strengthens" else "mitigates", elements$drivers[[j]]$name),
              matrix = "d_r"  # Feedback: responses to drivers
            )
          }
        }
      }

      # R → A (Responses → Activities): Feedback loop
      # E.g., "Fishing regulations reduce fishing activity" or "Protected areas limit tourism"
      if (length(elements$responses) > 0 && length(elements$activities) > 0) {
        for (i in seq_along(elements$responses)) {
          for (j in seq_along(elements$activities)) {
            polarity <- detect_polarity(elements$responses[[i]]$name, elements$activities[[j]]$name, "responses", "activities")
            connections[[length(connections) + 1]] <- list(
              from_type = "responses",
              from_index = i,
              from_name = elements$responses[[i]]$name,
              to_type = "activities",
              to_index = j,
              to_name = elements$activities[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$responses[[i]]$name, if(polarity == "-") "restricts" else "enables", elements$activities[[j]]$name),
              matrix = "a_r"  # Feedback: responses to activities
            )
          }
        }
      }

      # M → D (Measures → Drivers): Feedback loop
      # E.g., "Quota systems reduce economic pressure" or "Awareness campaigns increase environmental concern"
      if (length(elements$measures) > 0 && length(elements$drivers) > 0) {
        for (i in seq_along(elements$measures)) {
          for (j in seq_along(elements$drivers)) {
            polarity <- detect_polarity(elements$measures[[i]]$name, elements$drivers[[j]]$name, "measures", "drivers")
            connections[[length(connections) + 1]] <- list(
              from_type = "measures",
              from_index = i,
              from_name = elements$measures[[i]]$name,
              to_type = "drivers",
              to_index = j,
              to_name = elements$drivers[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$measures[[i]]$name, if(polarity == "+") "strengthens" else "reduces", elements$drivers[[j]]$name),
              matrix = "d_m"  # Feedback: measures to drivers
            )
          }
        }
      }

      # M → A (Measures → Activities): Feedback loop
      # E.g., "Catch limits reduce fishing effort" or "Marine protected areas restrict tourism activities"
      if (length(elements$measures) > 0 && length(elements$activities) > 0) {
        for (i in seq_along(elements$measures)) {
          for (j in seq_along(elements$activities)) {
            polarity <- detect_polarity(elements$measures[[i]]$name, elements$activities[[j]]$name, "measures", "activities")
            connections[[length(connections) + 1]] <- list(
              from_type = "measures",
              from_index = i,
              from_name = elements$measures[[i]]$name,
              to_type = "activities",
              to_index = j,
              to_name = elements$activities[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$measures[[i]]$name, if(polarity == "-") "limits" else "supports", elements$activities[[j]]$name),
              matrix = "a_m"  # Feedback: measures to activities
            )
          }
        }
      }

      # M → P (Measures → Pressures): Feedback loop
      # E.g., "Wastewater treatment reduces pollution" or "Fishing bans reduce overfishing pressure"
      if (length(elements$measures) > 0 && length(elements$pressures) > 0) {
        for (i in seq_along(elements$measures)) {
          for (j in seq_along(elements$pressures)) {
            polarity <- detect_polarity(elements$measures[[i]]$name, elements$pressures[[j]]$name, "measures", "pressures")
            connections[[length(connections) + 1]] <- list(
              from_type = "measures",
              from_index = i,
              from_name = elements$measures[[i]]$name,
              to_type = "pressures",
              to_index = j,
              to_name = elements$pressures[[j]]$name,
              polarity = polarity,
              strength = "medium",
              confidence = 3,
              rationale = paste(elements$measures[[i]]$name, if(polarity == "-") "mitigates" else "increases", elements$pressures[[j]]$name),
              matrix = "p_m"  # Feedback: measures to pressures
            )
          }
        }
      }

      # Log final count and warn if limit reached
      cat(sprintf("[AI ISA CONNECTIONS] Generated %d connections\n", length(connections)))
      if (length(connections) >= MAX_CONNECTIONS) {
        cat(sprintf("[AI ISA CONNECTIONS] WARNING: Connection limit reached (%d). Some connections were not generated to prevent browser freeze.\n", MAX_CONNECTIONS))
      }

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
            length(rv$elements$responses),
            length(rv$elements$measures)
          )

          if (total_elements == 0) {
            # No elements - show helpful message
            message <- paste0(
              i18n$t("I notice you haven't added any elements yet!"), " ",
              i18n$t("To create connections, you need to add at least some Drivers, Activities, Pressures, States, Impacts, Welfare, Responses, or Measures."), " ",
              i18n$t("Please go back through the previous steps and add elements by clicking the suggested options or entering your own text.")
            )
          } else {
            # Generate connections
            rv$suggested_connections <- generate_connections(rv$elements)
            conn_count <- length(rv$suggested_connections)

            if (conn_count == 0) {
              message <- paste0(
                i18n$t("I see you've added"), " ", total_elements, " ", i18n$t("elements, but I couldn't generate connections between them."), " ",
                i18n$t("Try adding more elements to different categories (Drivers, Activities, Pressures, etc.) to create meaningful connections.")
              )
            } else {
              message <- paste0(next_step$question, " ", i18n$t("I've identified"), " ", conn_count,
                               " ", i18n$t("potential connections based on the DAPSI(W)R(M) framework logic."), " ",
                               i18n$t("Review each connection below and approve or reject them."))
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
        i18n$t("Start")
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
        length(rv$elements$responses),
        length(rv$elements$measures)
      )

      div(
        h2(style = "color: #667eea; text-align: center;", total_elements),
        p(style = "text-align: center;", i18n$t("Total elements created"))
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
    output$count_measures <- renderText({ length(rv$elements$measures) })
    output$count_connections <- renderText({ length(rv$approved_connections) })

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
          paste0("R: ", length(rv$elements$responses))),
        div(class = "dapsiwrm-arrow", "↑"),
        div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #3288bd; color: #3288bd;",
          paste0("M: ", length(rv$elements$measures)))
      )
    })

    # Handle preview model
    observeEvent(input$preview_model, {
      # Create preview of all elements
      preview_content <- tagList(
        h3(icon("project-diagram"), " ", i18n$t("Your DAPSI(W)R(M) Model Preview")),
        hr(),

        if (!is.null(rv$context$project_name)) {
          div(
            h4(icon("map-marker-alt"), " ", i18n$t("Project Information")),
            tags$ul(
              tags$li(strong(i18n$t("Project/Location:")), " ", rv$context$project_name),
              if (!is.null(rv$context$ecosystem_type)) tags$li(strong(i18n$t("Ecosystem Type:")), " ", rv$context$ecosystem_type),
              if (!is.null(rv$context$main_issue)) tags$li(strong(i18n$t("Main Issue:")), " ", rv$context$main_issue)
            ),
            hr()
          )
        },

        # Drivers
        if (length(rv$elements$drivers) > 0) {
          div(
            h4(style = "color: #776db3;", icon("flag"), " ", i18n$t("Drivers (Societal Needs)")),
            tags$ul(
              lapply(rv$elements$drivers, function(d) tags$li(d$name))
            )
          )
        },

        # Activities
        if (length(rv$elements$activities) > 0) {
          div(
            h4(style = "color: #5abc67;", icon("running"), " ", i18n$t("Activities (Human Actions)")),
            tags$ul(
              lapply(rv$elements$activities, function(a) tags$li(a$name))
            )
          )
        },

        # Pressures
        if (length(rv$elements$pressures) > 0) {
          div(
            h4(style = "color: #fec05a;", icon("exclamation-triangle"), " ", i18n$t("Pressures (Environmental Stressors)")),
            tags$ul(
              lapply(rv$elements$pressures, function(p) tags$li(p$name))
            )
          )
        },

        # State Changes
        if (length(rv$elements$states) > 0) {
          div(
            h4(style = "color: #bce2ee;", icon("water"), " ", i18n$t("State Changes (Ecosystem Effects)")),
            tags$ul(
              lapply(rv$elements$states, function(s) tags$li(s$name))
            )
          )
        },

        # Impacts
        if (length(rv$elements$impacts) > 0) {
          div(
            h4(style = "color: #313695;", icon("chart-line"), " ", i18n$t("Impacts (Service Effects)")),
            tags$ul(
              lapply(rv$elements$impacts, function(i) tags$li(i$name))
            )
          )
        },

        # Welfare
        if (length(rv$elements$welfare) > 0) {
          div(
            h4(style = "color: #fff1a2; text-shadow: 1px 1px 2px #666;", icon("heart"), " ", i18n$t("Welfare (Human Well-being)")),
            tags$ul(
              lapply(rv$elements$welfare, function(w) tags$li(w$name))
            )
          )
        },

        # Responses
        if (length(rv$elements$responses) > 0) {
          div(
            h4(style = "color: #66c2a5;", icon("shield-alt"), " ", i18n$t("Responses (Management Actions)")),
            tags$ul(
              lapply(rv$elements$responses, function(r) tags$li(r$name))
            )
          )
        },

        # Measures
        if (length(rv$elements$measures) > 0) {
          div(
            h4(style = "color: #3288bd;", icon("gavel"), " ", i18n$t("Measures (Policy Instruments)")),
            tags$ul(
              lapply(rv$elements$measures, function(m) tags$li(m$name))
            )
          )
        },

        hr(),

        # Connections
        if (length(rv$approved_connections) > 0) {
          div(
            h4(style = "color: #28a745;", icon("project-diagram"), " ",
               i18n$t("Connections"), " (", length(rv$approved_connections), ")"),
            tags$div(
              style = "max-height: 300px; overflow-y: auto; padding: 10px; background: #f8f9fa; border-radius: 5px;",
              tags$ul(
                style = "list-style-type: none; padding-left: 0;",
                lapply(rv$approved_connections, function(conn_idx) {
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
                         i18n$t("Strength:"), " ", conn$strength, ", ",
                         i18n$t("Confidence:"), " ", conn$confidence %||% 3)
                  )
                })
              )
            ),
            hr()
          )
        },

        p(class = "text-muted",
          i18n$t("Total elements:"), " ",
          sum(length(rv$elements$drivers), length(rv$elements$activities),
              length(rv$elements$pressures), length(rv$elements$states),
              length(rv$elements$impacts), length(rv$elements$welfare),
              length(rv$elements$responses), length(rv$elements$measures)),
          " | ",
          i18n$t("Total connections:"), " ", length(rv$approved_connections))
      )

      showModal(modalDialog(
        preview_content,
        title = NULL,
        size = "l",
        easyClose = TRUE,
        footer = tagList(
          modalButton(i18n$t("Close")),
          actionButton(session$ns("save_from_preview"), i18n$t("Save to ISA Data Entry"),
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
        title = i18n$t("Confirm Start Over"),
        i18n$t("Are you sure you want to start over? All current progress will be lost."),
        footer = tagList(
          modalButton(i18n$t("Cancel")),
          actionButton(session$ns("confirm_start_over"), i18n$t("Yes, Start Over"), class = "btn-danger")
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
        responses = list(),
        measures = list()
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
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Drivers")),
          tags$ul(lapply(rv$elements$drivers, function(d) tags$li(strong(d$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_activities, {
      if (length(rv$elements$activities) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Activities")),
          tags$ul(lapply(rv$elements$activities, function(a) tags$li(strong(a$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_pressures, {
      if (length(rv$elements$pressures) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Pressures")),
          tags$ul(lapply(rv$elements$pressures, function(p) tags$li(strong(p$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_states, {
      if (length(rv$elements$states) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("State Changes")),
          tags$ul(lapply(rv$elements$states, function(s) tags$li(strong(s$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_impacts, {
      if (length(rv$elements$impacts) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Impacts")),
          tags$ul(lapply(rv$elements$impacts, function(i) tags$li(strong(i$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_welfare, {
      if (length(rv$elements$welfare) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Welfare")),
          tags$ul(lapply(rv$elements$welfare, function(w) tags$li(strong(w$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_responses, {
      if (length(rv$elements$responses) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Responses")),
          tags$ul(lapply(rv$elements$responses, function(r) tags$li(strong(r$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      }
    })

    observeEvent(input$link_measures, {
      if (length(rv$elements$measures) > 0) {
        showModal(modalDialog(
          title = tagList(icon("arrow-circle-right"), " ", i18n$t("Measures")),
          tags$ul(lapply(rv$elements$measures, function(m) tags$li(strong(m$name)))),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
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
          title = tagList(icon("project-diagram"), " ", i18n$t("Approved Connections")),
          tags$ul(conn_list),
          size = "l",
          easyClose = TRUE,
          footer = modalButton(i18n$t("Close"))
        ))
      } else {
        showNotification("No connections approved yet.", type = "warning", duration = 2)
      }
    })

    # Handle load template
    observeEvent(input$load_template, {
      showModal(modalDialog(
        title = i18n$t("Load Example Template"),
        h4(i18n$t("Choose a pre-built scenario:")),
        fluidRow(
          column(6,
            actionButton(session$ns("template_overfishing"), i18n$t("Overfishing in Coastal Waters"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_pollution"), i18n$t("Marine Pollution & Plastics"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        fluidRow(
          column(6,
            actionButton(session$ns("template_tourism"), i18n$t("Coastal Tourism Impacts"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_climate"), i18n$t("Climate Change & Coral Reefs"),
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        footer = modalButton(i18n$t("Cancel"))
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
        ),
        measures = list(
          list(name = "Fisheries legislation", description = "", timestamp = Sys.time()),
          list(name = "Monitoring and enforcement programs", description = "", timestamp = Sys.time())
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
      showNotification(i18n$t("Overfishing template loaded with example connections! You can now preview or modify it."), type = "message", duration = 5)
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
        ),
        measures = list(
          list(name = "Environmental legislation", description = "", timestamp = Sys.time()),
          list(name = "Education and awareness campaigns", description = "", timestamp = Sys.time())
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
      showNotification(i18n$t("Marine Pollution template loaded with example connections!"), type = "message", duration = 5)
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
        ),
        measures = list(
          list(name = "Marine spatial planning", description = "", timestamp = Sys.time()),
          list(name = "Certification schemes for sustainable tourism", description = "", timestamp = Sys.time())
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
      showNotification(i18n$t("Coastal Tourism template loaded with example connections!"), type = "message", duration = 5)
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
        ),
        measures = list(
          list(name = "International climate agreements", description = "", timestamp = Sys.time()),
          list(name = "Research funding for reef resilience", description = "", timestamp = Sys.time())
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
      showNotification(i18n$t("Climate Change template loaded with example connections!"), type = "message", duration = 5)
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
              length(rv$elements$responses), length(rv$elements$measures)
            )

            cat(sprintf("[AI ISA SAVE] Total elements: %d (D:%d A:%d P:%d S:%d I:%d W:%d R:%d M:%d)\n",
                        total_elements,
                        length(rv$elements$drivers), length(rv$elements$activities),
                        length(rv$elements$pressures), length(rv$elements$states),
                        length(rv$elements$impacts), length(rv$elements$welfare),
                        length(rv$elements$responses), length(rv$elements$measures)))

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

            current_data$data$isa_data$measures <- if (length(rv$elements$measures) > 0) {
              data.frame(
                Name = sapply(rv$elements$measures, function(x) x$name),
                Description = sapply(rv$elements$measures, function(x) x$description %||% ""),
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
              current_data$data$isa_data$adjacency_matrices <- list(
                gb_es = NULL,
                es_mpf = NULL,
                mpf_p = NULL,
                p_a = NULL,
                a_d = NULL,
                d_gb = NULL,
                p_r = NULL,
                r_m = NULL
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
              n_measures <- length(rv$elements$measures)

              cat(sprintf("[AI ISA AUTO-SAVE] Matrix dimensions: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R=%d, M=%d\n",
                         n_drivers, n_activities, n_pressures, n_states, n_impacts, n_welfare, n_responses, n_measures))

              # Initialize matrices
              if (n_drivers > 0 && n_activities > 0) {
                current_data$data$isa_data$adjacency_matrices$a_d <- matrix(
                  "", nrow = n_activities, ncol = n_drivers,
                  dimnames = list(
                    sapply(rv$elements$activities, function(x) x$name),
                    sapply(rv$elements$drivers, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created a_d matrix (%d x %d)\n", n_activities, n_drivers))
              }

              if (n_activities > 0 && n_pressures > 0) {
                current_data$data$isa_data$adjacency_matrices$p_a <- matrix(
                  "", nrow = n_pressures, ncol = n_activities,
                  dimnames = list(
                    sapply(rv$elements$pressures, function(x) x$name),
                    sapply(rv$elements$activities, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created p_a matrix (%d x %d)\n", n_pressures, n_activities))
              }

              if (n_pressures > 0 && n_states > 0) {
                current_data$data$isa_data$adjacency_matrices$mpf_p <- matrix(
                  "", nrow = n_states, ncol = n_pressures,
                  dimnames = list(
                    sapply(rv$elements$states, function(x) x$name),
                    sapply(rv$elements$pressures, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created mpf_p matrix (%d x %d)\n", n_states, n_pressures))
              }

              if (n_states > 0 && n_impacts > 0) {
                current_data$data$isa_data$adjacency_matrices$es_mpf <- matrix(
                  "", nrow = n_impacts, ncol = n_states,
                  dimnames = list(
                    sapply(rv$elements$impacts, function(x) x$name),
                    sapply(rv$elements$states, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created es_mpf matrix (%d x %d)\n", n_impacts, n_states))
              }

              if (n_impacts > 0 && n_welfare > 0) {
                current_data$data$isa_data$adjacency_matrices$gb_es <- matrix(
                  "", nrow = n_welfare, ncol = n_impacts,
                  dimnames = list(
                    sapply(rv$elements$welfare, function(x) x$name),
                    sapply(rv$elements$impacts, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created gb_es matrix (%d x %d)\n", n_welfare, n_impacts))
              }

              # Responses → Pressures matrix
              if (n_responses > 0 && n_pressures > 0) {
                current_data$data$isa_data$adjacency_matrices$p_r <- matrix(
                  "", nrow = n_pressures, ncol = n_responses,
                  dimnames = list(
                    sapply(rv$elements$pressures, function(x) x$name),
                    sapply(rv$elements$responses, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created p_r matrix (%d x %d)\n", n_pressures, n_responses))
              }

              # Measures → Responses matrix
              if (n_measures > 0 && n_responses > 0) {
                current_data$data$isa_data$adjacency_matrices$r_m <- matrix(
                  "", nrow = n_responses, ncol = n_measures,
                  dimnames = list(
                    sapply(rv$elements$responses, function(x) x$name),
                    sapply(rv$elements$measures, function(x) x$name)
                  )
                )
                cat(sprintf("[AI ISA AUTO-SAVE] Created r_m matrix (%d x %d)\n", n_responses, n_measures))
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

                # Determine which matrix and indices
                if (conn$matrix == "a_d" && !is.null(current_data$data$isa_data$adjacency_matrices$a_d)) {
                  current_data$data$isa_data$adjacency_matrices$a_d[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to a_d[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "p_a" && !is.null(current_data$data$isa_data$adjacency_matrices$p_a)) {
                  current_data$data$isa_data$adjacency_matrices$p_a[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to p_a[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "mpf_p" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_p)) {
                  current_data$data$isa_data$adjacency_matrices$mpf_p[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to mpf_p[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "es_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$es_mpf)) {
                  current_data$data$isa_data$adjacency_matrices$es_mpf[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to es_mpf[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "gb_es" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_es)) {
                  current_data$data$isa_data$adjacency_matrices$gb_es[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to gb_es[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "p_r" && !is.null(current_data$data$isa_data$adjacency_matrices$p_r)) {
                  current_data$data$isa_data$adjacency_matrices$p_r[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to p_r[%d, %d]\n", conn$to_index, conn$from_index))
                } else if (conn$matrix == "r_m" && !is.null(current_data$data$isa_data$adjacency_matrices$r_m)) {
                  current_data$data$isa_data$adjacency_matrices$r_m[conn$to_index, conn$from_index] <- value
                  cat(sprintf("[AI ISA AUTO-SAVE]   ✓ Saved to r_m[%d, %d]\n", conn$to_index, conn$from_index))
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

        cat(sprintf("[AI ISA] Manual saving %d drivers, %d activities, %d pressures, %d states, %d impacts, %d welfare, %d responses, %d measures\n",
                   length(rv$elements$drivers), length(rv$elements$activities),
                   length(rv$elements$pressures), length(rv$elements$states),
                   length(rv$elements$impacts), length(rv$elements$welfare),
                   length(rv$elements$responses), length(rv$elements$measures)))

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

      # Create measures dataframe
      if (length(rv$elements$measures) > 0) {
        current_data$data$isa_data$measures <- data.frame(
          name = sapply(rv$elements$measures, function(x) x$name),
          description = sapply(rv$elements$measures, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$measures <- data.frame(
          name = character(), description = character(), indicator = character(),
          stringsAsFactors = FALSE
        )
      }

      # Build adjacency matrices from approved connections
      current_data$data$isa_data$adjacency_matrices <- list(
        gb_es = NULL,
        es_mpf = NULL,
        mpf_p = NULL,
        p_a = NULL,
        a_d = NULL,
        d_gb = NULL
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

        cat(sprintf("[AI ISA CONNECTIONS] Matrix dimensions: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d\n",
                   n_drivers, n_activities, n_pressures, n_states, n_impacts, n_welfare))

        # Initialize matrices
        if (n_drivers > 0 && n_activities > 0) {
          current_data$data$isa_data$adjacency_matrices$a_d <- matrix(
            "", nrow = n_activities, ncol = n_drivers,
            dimnames = list(
              sapply(rv$elements$activities, function(x) x$name),
              sapply(rv$elements$drivers, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created a_d matrix (%d x %d)\n", n_activities, n_drivers))
        }

        if (n_activities > 0 && n_pressures > 0) {
          current_data$data$isa_data$adjacency_matrices$p_a <- matrix(
            "", nrow = n_pressures, ncol = n_activities,
            dimnames = list(
              sapply(rv$elements$pressures, function(x) x$name),
              sapply(rv$elements$activities, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created p_a matrix (%d x %d)\n", n_pressures, n_activities))
        }

        if (n_pressures > 0 && n_states > 0) {
          current_data$data$isa_data$adjacency_matrices$mpf_p <- matrix(
            "", nrow = n_states, ncol = n_pressures,
            dimnames = list(
              sapply(rv$elements$states, function(x) x$name),
              sapply(rv$elements$pressures, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created mpf_p matrix (%d x %d)\n", n_states, n_pressures))
        }

        if (n_states > 0 && n_impacts > 0) {
          current_data$data$isa_data$adjacency_matrices$es_mpf <- matrix(
            "", nrow = n_impacts, ncol = n_states,
            dimnames = list(
              sapply(rv$elements$impacts, function(x) x$name),
              sapply(rv$elements$states, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created es_mpf matrix (%d x %d)\n", n_impacts, n_states))
        }

        if (n_impacts > 0 && n_welfare > 0) {
          current_data$data$isa_data$adjacency_matrices$gb_es <- matrix(
            "", nrow = n_welfare, ncol = n_impacts,
            dimnames = list(
              sapply(rv$elements$welfare, function(x) x$name),
              sapply(rv$elements$impacts, function(x) x$name)
            )
          )
          cat(sprintf("[AI ISA CONNECTIONS] Created gb_es matrix (%d x %d)\n", n_welfare, n_impacts))
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

          # Determine which matrix and indices
          if (conn$matrix == "a_d" && !is.null(current_data$data$isa_data$adjacency_matrices$a_d)) {
            current_data$data$isa_data$adjacency_matrices$a_d[conn$to_index, conn$from_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to a_d[%d, %d]\n", conn$to_index, conn$from_index))
          } else if (conn$matrix == "p_a" && !is.null(current_data$data$isa_data$adjacency_matrices$p_a)) {
            current_data$data$isa_data$adjacency_matrices$p_a[conn$to_index, conn$from_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to p_a[%d, %d]\n", conn$to_index, conn$from_index))
          } else if (conn$matrix == "mpf_p" && !is.null(current_data$data$isa_data$adjacency_matrices$mpf_p)) {
            current_data$data$isa_data$adjacency_matrices$mpf_p[conn$to_index, conn$from_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to mpf_p[%d, %d]\n", conn$to_index, conn$from_index))
          } else if (conn$matrix == "es_mpf" && !is.null(current_data$data$isa_data$adjacency_matrices$es_mpf)) {
            current_data$data$isa_data$adjacency_matrices$es_mpf[conn$to_index, conn$from_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to es_mpf[%d, %d]\n", conn$to_index, conn$from_index))
          } else if (conn$matrix == "gb_es" && !is.null(current_data$data$isa_data$adjacency_matrices$gb_es)) {
            current_data$data$isa_data$adjacency_matrices$gb_es[conn$to_index, conn$from_index] <- value
            cat(sprintf("[AI ISA CONNECTIONS]   ✓ Saved to gb_es[%d, %d]\n", conn$to_index, conn$from_index))
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
          length(rv$elements$responses),
          length(rv$elements$measures)
        )

        # Count connections
        n_connections <- length(rv$approved_connections)

        cat(sprintf("[AI ISA] Save completed: %d elements, %d connections\n", total_elements, n_connections))

        showNotification(
          paste0(i18n$t("Model saved successfully!"), " ", total_elements, " ", i18n$t("elements and"), " ",
                 n_connections, " ", i18n$t("connections transferred to ISA Data Entry.")),
          type = "message",
          duration = 5
        )

      }, error = function(e) {
        cat(sprintf("[AI ISA ERROR] Save failed: %s\n", e$message))
        cat(sprintf("[AI ISA ERROR] Call stack: %s\n", paste(sys.calls(), collapse = "\n")))

        showNotification(
          paste0(i18n$t("Error saving model:"), " ", e$message),
          type = "error",
          duration = 10
        )
      })
    })

  })
}
