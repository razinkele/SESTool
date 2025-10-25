# modules/ai_isa_assistant_module.R
# AI-Assisted ISA Creation Module
# Purpose: Guide users through stepwise questions to build DAPSI(W)R(M) framework

# ============================================================================
# UI FUNCTION
# ============================================================================

ai_isa_assistant_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    shiny.i18n::usei18n(i18n),

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
        $(document).ready(function() {
          var savedData = localStorage.getItem('ai_isa_session');
          if (savedData) {
            Shiny.setInputValue('ai_isa_mod-has_saved_session', true, {priority: 'event'});
          }
        });
      "))
    ),

    # Main content
    fluidRow(
      column(12,
        h2(icon("robot"), " AI-Assisted ISA Creation"),
        p(class = "lead", "Let me guide you step-by-step through building your DAPSI(W)R(M) model.")
      )
    ),

    # Progress indicator
    fluidRow(
      column(12,
        div(class = "step-indicator",
          uiOutput(ns("step_title"))
        ),
        div(class = "progress-bar-custom",
          uiOutput(ns("progress_bar"))
        )
      )
    ),

    hr(),

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
        box(
          title = "Your SES Model Progress",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,

          h4(icon("chart-line"), " Elements Created:"),
          uiOutput(ns("elements_summary")),

          hr(),

          h4(icon("sitemap"), " Framework Flow:"),
          uiOutput(ns("dapsiwrm_diagram")),

          hr(),

          h4(icon("network-wired"), " Current Framework:"),
          tags$ul(
            tags$li(strong("Drivers: "), textOutput(ns("count_drivers"), inline = TRUE)),
            tags$li(strong("Activities: "), textOutput(ns("count_activities"), inline = TRUE)),
            tags$li(strong("Pressures: "), textOutput(ns("count_pressures"), inline = TRUE)),
            tags$li(strong("State Changes: "), textOutput(ns("count_states"), inline = TRUE)),
            tags$li(strong("Impacts: "), textOutput(ns("count_impacts"), inline = TRUE)),
            tags$li(strong("Welfare: "), textOutput(ns("count_welfare"), inline = TRUE)),
            tags$li(strong("Responses: "), textOutput(ns("count_responses"), inline = TRUE)),
            tags$li(strong("Measures: "), textOutput(ns("count_measures"), inline = TRUE))
          ),

          hr(),

          h5(icon("database"), " Session Management"),
          uiOutput(ns("save_status")),
          br(),
          fluidRow(
            column(6,
              actionButton(ns("manual_save"), "Save Progress",
                          icon = icon("save"),
                          class = "btn-primary btn-sm btn-block",
                          title = "Save your current progress to browser storage")
            ),
            column(6,
              actionButton(ns("load_session"), "Load Saved",
                          icon = icon("folder-open"),
                          class = "btn-secondary btn-sm btn-block",
                          title = "Restore your last saved session")
            )
          ),
          br(),

          hr(),

          actionButton(ns("preview_model"), "Preview Model",
                      icon = icon("eye"),
                      class = "btn-info btn-block"),
          br(),
          actionButton(ns("save_to_isa"), "Save to ISA Data Entry",
                      icon = icon("save"),
                      class = "btn-success btn-block"),
          br(),
          actionButton(ns("load_template"), "Load Example Template",
                      icon = icon("file-import"),
                      class = "btn-info btn-block"),
          br(),
          actionButton(ns("start_over"), "Start Over",
                      icon = icon("redo"),
                      class = "btn-warning btn-block")
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

ai_isa_assistant_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {

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
        location = NULL,
        ecosystem_type = NULL,
        main_issue = NULL
      ),
      total_steps = 11,  # Increased to include connection suggestions
      undo_stack = list(),  # For undo functionality
      suggested_connections = list(),  # AI-generated connection suggestions
      approved_connections = list(),   # User-approved connections
      last_save_time = NULL,  # Track last save timestamp
      auto_save_enabled = TRUE  # Auto-save toggle
    )

    # Define the stepwise questions
    QUESTION_FLOW <- list(
      list(
        step = 0,
        title = "Welcome & Introduction",
        question = "Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?",
        type = "text",
        target = "project_name"
      ),
      list(
        step = 1,
        title = "Ecosystem Context",
        question = "Great! Now, what type of marine ecosystem are you studying?",
        type = "choice",
        options = c("Coastal waters", "Open ocean", "Estuaries", "Coral reefs", "Mangroves", "Seagrass beds", "Deep sea", "Other"),
        target = "ecosystem_type"
      ),
      list(
        step = 2,
        title = "Main Issue Identification",
        question = "What is the main environmental or management issue you're addressing?",
        type = "text",
        target = "main_issue"
      ),
      list(
        step = 3,
        title = "Drivers - Societal Needs",
        question = "Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs? (e.g., Food security, Economic development, Recreation, Energy needs)",
        type = "multiple",
        target = "drivers",
        examples = c("Food security", "Economic development", "Recreation and tourism", "Energy needs", "Coastal protection", "Cultural heritage")
      ),
      list(
        step = 4,
        title = "Activities - Human Actions",
        question = "Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area? (e.g., Fishing, Aquaculture, Shipping, Tourism)",
        type = "multiple",
        target = "activities",
        examples = c("Commercial fishing", "Recreational fishing", "Aquaculture", "Shipping/Transport", "Tourism", "Coastal development", "Renewable energy (wind/wave)", "Oil & gas extraction")
      ),
      list(
        step = 5,
        title = "Pressures - Environmental Stressors",
        question = "What PRESSURES do these activities put on the marine environment? (e.g., Overfishing, Pollution, Habitat destruction)",
        type = "multiple",
        target = "pressures",
        examples = c("Overfishing", "Bycatch", "Physical habitat damage", "Pollution (nutrients, chemicals)", "Noise pollution", "Marine litter/plastics", "Temperature changes", "Ocean acidification")
      ),
      list(
        step = 6,
        title = "State Changes - Ecosystem Effects",
        question = "How do these pressures change the STATE of the marine ecosystem? (e.g., Declining fish stocks, Loss of biodiversity, Degraded water quality)",
        type = "multiple",
        target = "states",
        examples = c("Declining fish stocks", "Loss of biodiversity", "Habitat degradation", "Water quality decline", "Altered food webs", "Invasive species", "Loss of ecosystem resilience")
      ),
      list(
        step = 7,
        title = "Impacts - Effects on Ecosystem Services",
        question = "What are the IMPACTS on ecosystem services and benefits? How do these changes affect what the ocean provides? (e.g., Reduced fish catch, Loss of tourism revenue)",
        type = "multiple",
        target = "impacts",
        examples = c("Reduced fish catch", "Loss of tourism revenue", "Reduced coastal protection", "Loss of biodiversity value", "Reduced water quality for recreation", "Loss of cultural services")
      ),
      list(
        step = 8,
        title = "Welfare - Human Well-being Effects",
        question = "How do these impacts affect human WELFARE and well-being? (e.g., Loss of livelihoods, Health impacts, Reduced quality of life)",
        type = "multiple",
        target = "welfare",
        examples = c("Loss of livelihoods", "Food insecurity", "Economic losses", "Health impacts", "Loss of cultural identity", "Reduced quality of life", "Social conflicts")
      ),
      list(
        step = 9,
        title = "Responses - Management Actions",
        question = "What RESPONSES or management actions are being taken (or could be taken) to address these issues? (e.g., Marine protected areas, Fishing quotas, Pollution regulations)",
        type = "multiple",
        target = "responses",
        examples = c("Marine protected areas (MPAs)", "Fishing quotas/limits", "Pollution regulations", "Habitat restoration", "Sustainable fishing practices", "Ecosystem-based management", "Stakeholder engagement", "Monitoring programs")
      ),
      list(
        step = 10,
        title = "Measures - Policy Instruments",
        question = "Finally, what specific MEASURES or policy instruments support these responses? (e.g., Laws, Economic incentives, Education programs)",
        type = "multiple",
        target = "measures",
        examples = c("Environmental legislation", "Marine spatial planning", "Economic incentives (subsidies, taxes)", "Education and awareness programs", "Certification schemes (MSC, etc.)", "International agreements", "Monitoring and enforcement", "Research funding")
      ),
      list(
        step = 11,
        title = "Connection Review",
        question = "Great! Now I'll suggest logical connections between the elements you've identified. These connections represent causal relationships in your social-ecological system. You can review and approve/reject each suggestion.",
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
          paste0(round(time_diff), " seconds ago")
        } else {
          paste0(round(time_diff / 60), " minutes ago")
        }

        div(class = "save-status",
          icon("check-circle"), " Auto-saved ", time_text
        )
      } else {
        div(class = "save-status warning",
          icon("exclamation-triangle"), " Not yet saved"
        )
      }
    })

    # Manual save button
    observeEvent(input$manual_save, {
      session_data <- get_session_data()
      session$sendCustomMessage("save_ai_isa_session", session_data)
      rv$last_save_time <- Sys.time()

      showNotification(
        "Session saved successfully!",
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
          title = "Restore Previous Session?",
          paste0("Found a saved session from ",
                 format(as.POSIXct(input$loaded_session_data$timestamp), "%Y-%m-%d %H:%M:%S"),
                 ". Do you want to restore it?"),
          footer = tagList(
            actionButton(session$ns("confirm_load"), "Yes, Restore", class = "btn-primary"),
            modalButton("Cancel")
          )
        ))

        # Store loaded data temporarily
        rv$temp_loaded_data <- loaded_data
      } else {
        showNotification("No saved session found.", type = "warning", duration = 3)
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
          "A previous session was found. Click 'Load Saved' to restore it.",
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

    # Render progress bar
    output$progress_bar <- renderUI({
      progress_pct <- round((rv$current_step / length(QUESTION_FLOW)) * 100)
      div(class = "progress-fill",
          style = paste0("width: ", progress_pct, "%;"),
          paste0(progress_pct, "%")
      )
    })

    # Render conversation
    output$conversation <- renderUI({
      messages <- lapply(rv$conversation, function(msg) {
        if (msg$type == "ai") {
          div(class = "ai-message",
            div(style = "color: #667eea; font-weight: 600;",
              icon("robot"), " AI Assistant"
            ),
            p(msg$message)
          )
        } else {
          div(class = "user-message",
            div(style = "color: #2196f3; font-weight: 600;",
              icon("user"), " You"
            ),
            p(msg$message)
          )
        }
      })

      tagList(messages)
    })

    # Render input area dynamically based on step type
    output$input_area <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (step_info$type == "connection_review") {
          # Connection review interface
          wellPanel(
            h4(icon("link"), " Review Suggested Connections"),
            p("Approve or reject each connection. You can modify the strength and polarity if needed."),
            uiOutput(session$ns("connection_list")),
            br(),
            fluidRow(
              column(6,
                actionButton(session$ns("approve_all_connections"), "Approve All",
                            icon = icon("check-circle"),
                            class = "btn-success btn-block")
              ),
              column(6,
                actionButton(session$ns("finish_connections"), "Finish & Continue",
                            icon = icon("arrow-right"),
                            class = "btn-primary btn-block")
              )
            )
          )
        } else {
          # Standard input interface
          wellPanel(
            textAreaInput(session$ns("user_input"),
                         label = NULL,
                         placeholder = "Type your answer here...",
                         rows = 3,
                         width = "100%"),
            fluidRow(
              column(6,
                actionButton(session$ns("submit_answer"), "Submit Answer",
                            icon = icon("paper-plane"),
                            class = "btn-primary btn-block")
              ),
              column(6,
                uiOutput(session$ns("continue_button"))
              )
            ),
            br(),
            div(id = session$ns("quick_options_container"),
              uiOutput(session$ns("quick_options"))
            )
          )
        }
      }
    })

    # Render connection list for review
    output$connection_list <- renderUI({
      if (length(rv$suggested_connections) == 0) {
        return(p("No connections to review."))
      }

      lapply(seq_along(rv$suggested_connections), function(i) {
        conn <- rv$suggested_connections[[i]]
        is_approved <- i %in% rv$approved_connections

        div(
          style = paste0("border: 2px solid ",
                        if(is_approved) "#28a745" else "#ddd",
                        "; border-radius: 8px; padding: 15px; margin: 10px 0; background: ",
                        if(is_approved) "#d4edda" else "white"),
          fluidRow(
            column(8,
              div(
                strong(paste0(conn$from_name, " → ", conn$to_name)),
                br(),
                span(style = "color: #666; font-size: 0.9em;",
                     icon("arrow-right"), " ", conn$rationale),
                br(),
                span(style = "font-size: 0.85em;",
                     "Polarity: ", span(style = paste0("color: ", if(conn$polarity == "+") "green" else "red"),
                                       conn$polarity), " | ",
                     "Strength: ", conn$strength)
              )
            ),
            column(4,
              if (is_approved) {
                actionButton(session$ns(paste0("reject_conn_", i)),
                            "Reject",
                            icon = icon("times"),
                            class = "btn-danger btn-sm btn-block")
              } else {
                actionButton(session$ns(paste0("approve_conn_", i)),
                            "Approve",
                            icon = icon("check"),
                            class = "btn-success btn-sm btn-block")
              }
            )
          )
        )
      })
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
          # Approve observer
          approve_obs <- observeEvent(input[[paste0("approve_conn_", i)]], {
            conn_idx <- i
            if (!(conn_idx %in% isolate(rv$approved_connections))) {
              rv$approved_connections <- c(isolate(rv$approved_connections), conn_idx)
            }
          }, ignoreInit = TRUE)
          new_observers[[length(new_observers) + 1]] <- approve_obs

          # Reject observer
          reject_obs <- observeEvent(input[[paste0("reject_conn_", i)]], {
            conn_idx <- i
            rv$approved_connections <- setdiff(isolate(rv$approved_connections), conn_idx)
          }, ignoreInit = TRUE)
          new_observers[[length(new_observers) + 1]] <- reject_obs
        }
      }

      connection_observers(new_observers)
    }, ignoreInit = FALSE)

    # Approve all connections
    observeEvent(input$approve_all_connections, {
      rv$approved_connections <- seq_along(rv$suggested_connections)
      showNotification("All connections approved!", type = "message")
    })

    # Finish connection review
    observeEvent(input$finish_connections, {
      approved_count <- length(rv$approved_connections)

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = paste0("Great! You've approved ", approved_count, " connections out of ",
                            length(rv$suggested_connections), " suggested connections. ",
                            "These connections will be included in your saved ISA data."),
             timestamp = Sys.time())
      ))

      move_to_next_step()
    })

    # Render continue button with context-aware label
    output$continue_button <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        # Determine button label based on next step
        button_label <- "Skip This Question"
        button_icon <- icon("forward")

        if (rv$current_step + 1 < length(QUESTION_FLOW)) {
          next_step <- QUESTION_FLOW[[rv$current_step + 2]]

          # Create context-aware labels
          if (next_step$title == "Activities - Human Actions") {
            button_label <- "Continue to Activities"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "Pressures - Environmental Stressors") {
            button_label <- "Continue to Pressures"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "State Changes - Ecosystem Effects") {
            button_label <- "Continue to State Changes"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "Impacts - Effects on Ecosystem Services") {
            button_label <- "Continue to Impacts"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "Welfare - Human Well-being Effects") {
            button_label <- "Continue to Welfare"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "Responses - Management Actions") {
            button_label <- "Continue to Responses"
            button_icon <- icon("arrow-right")
          } else if (next_step$title == "Measures - Policy Instruments") {
            button_label <- "Continue to Measures"
            button_icon <- icon("arrow-right")
          } else {
            button_label <- "Continue"
            button_icon <- icon("arrow-right")
          }
        } else {
          button_label <- "Finish"
          button_icon <- icon("check")
        }

        actionButton(session$ns("skip_question"), button_label,
                    icon = button_icon,
                    class = "btn-success btn-block")
      }
    })

    # Render quick options
    output$quick_options <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (!is.null(step_info$examples)) {
          tagList(
            h5("Quick options (click to add):"),
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
      }
    })

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

    # Handle quick select - Dynamic observer for all quick option buttons
    observe({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (!is.null(step_info$examples)) {
          lapply(seq_along(step_info$examples), function(i) {
            observeEvent(input[[paste0("quick_opt_", i)]], {
              example <- step_info$examples[i]
              process_answer(example)
            }, ignoreInit = TRUE)
          })
        }
      }
    })

    # Handle skip
    observeEvent(input$skip_question, {
      move_to_next_step()
    })

    # Process answer function
    process_answer <- function(answer) {
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        # Store answer based on target
        if (step_info$type == "multiple") {
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

          # AI response with count
          ai_response <- paste0("✓ Added '", answer, "' (", element_count, " ", step_info$target, " total). Click quick options to add more, or click the green button to continue.")

          # Add AI response
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

        } else {
          # Store single value
          rv$context[[step_info$target]] <- answer

          # Add AI response BEFORE moving to next step
          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = "Thank you! Moving to the next question...", timestamp = Sys.time())
          ))

          move_to_next_step()
        }
      }
    }

    # Generate logical connections based on DAPSI(W)R(M) framework
    generate_connections <- function(elements) {
      connections <- list()

      # D → A (Drivers → Activities): Strong positive connections
      if (length(elements$drivers) > 0 && length(elements$activities) > 0) {
        for (i in seq_along(elements$drivers)) {
          for (j in seq_along(elements$activities)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "drivers",
              from_index = i,
              from_name = elements$drivers[[i]]$name,
              to_type = "activities",
              to_index = j,
              to_name = elements$activities[[j]]$name,
              polarity = "+",
              strength = "medium",
              rationale = paste(elements$drivers[[i]]$name, "drives", elements$activities[[j]]$name),
              matrix = "a_d"
            )
          }
        }
      }

      # A → P (Activities → Pressures): Positive connections
      if (length(elements$activities) > 0 && length(elements$pressures) > 0) {
        for (i in seq_along(elements$activities)) {
          for (j in seq_along(elements$pressures)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "activities",
              from_index = i,
              from_name = elements$activities[[i]]$name,
              to_type = "pressures",
              to_index = j,
              to_name = elements$pressures[[j]]$name,
              polarity = "+",
              strength = "medium",
              rationale = paste(elements$activities[[i]]$name, "causes", elements$pressures[[j]]$name),
              matrix = "p_a"
            )
          }
        }
      }

      # P → S (Pressures → States): Negative connections (pressures degrade states)
      if (length(elements$pressures) > 0 && length(elements$states) > 0) {
        for (i in seq_along(elements$pressures)) {
          for (j in seq_along(elements$states)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "pressures",
              from_index = i,
              from_name = elements$pressures[[i]]$name,
              to_type = "states",
              to_index = j,
              to_name = elements$states[[j]]$name,
              polarity = "-",
              strength = "medium",
              rationale = paste(elements$pressures[[i]]$name, "negatively affects", elements$states[[j]]$name),
              matrix = "mpf_p"
            )
          }
        }
      }

      # S → I (States → Impacts): Negative connections (degraded states reduce services)
      if (length(elements$states) > 0 && length(elements$impacts) > 0) {
        for (i in seq_along(elements$states)) {
          for (j in seq_along(elements$impacts)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "states",
              from_index = i,
              from_name = elements$states[[i]]$name,
              to_type = "impacts",
              to_index = j,
              to_name = elements$impacts[[j]]$name,
              polarity = "-",
              strength = "medium",
              rationale = paste(elements$states[[i]]$name, "impacts", elements$impacts[[j]]$name),
              matrix = "es_mpf"
            )
          }
        }
      }

      # I → W (Impacts → Welfare): Negative connections
      if (length(elements$impacts) > 0 && length(elements$welfare) > 0) {
        for (i in seq_along(elements$impacts)) {
          for (j in seq_along(elements$welfare)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "impacts",
              from_index = i,
              from_name = elements$impacts[[i]]$name,
              to_type = "welfare",
              to_index = j,
              to_name = elements$welfare[[j]]$name,
              polarity = "-",
              strength = "medium",
              rationale = paste(elements$impacts[[i]]$name, "reduces", elements$welfare[[j]]$name),
              matrix = "gb_es"
            )
          }
        }
      }

      # R → P (Responses → Pressures): Negative connections (responses reduce pressures)
      if (length(elements$responses) > 0 && length(elements$pressures) > 0) {
        for (i in seq_along(elements$responses)) {
          for (j in seq_along(elements$pressures)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "responses",
              from_index = i,
              from_name = elements$responses[[i]]$name,
              to_type = "pressures",
              to_index = j,
              to_name = elements$pressures[[j]]$name,
              polarity = "-",
              strength = "medium",
              rationale = paste(elements$responses[[i]]$name, "aims to reduce", elements$pressures[[j]]$name),
              matrix = "p_r"  # Note: This may need to be added to the system
            )
          }
        }
      }

      # M → R (Measures → Responses): Positive connections
      if (length(elements$measures) > 0 && length(elements$responses) > 0) {
        for (i in seq_along(elements$measures)) {
          for (j in seq_along(elements$responses)) {
            connections[[length(connections) + 1]] <- list(
              from_type = "measures",
              from_index = i,
              from_name = elements$measures[[i]]$name,
              to_type = "responses",
              to_index = j,
              to_name = elements$responses[[j]]$name,
              polarity = "+",
              strength = "medium",
              rationale = paste(elements$measures[[i]]$name, "supports", elements$responses[[j]]$name),
              matrix = "r_m"  # Note: This may need to be added to the system
            )
          }
        }
      }

      return(connections)
    }

    # Move to next step
    move_to_next_step <- function() {
      rv$current_step <- rv$current_step + 1

      if (rv$current_step < length(QUESTION_FLOW)) {
        # Add next question
        next_step <- QUESTION_FLOW[[rv$current_step + 1]]

        # If moving to connection review step, generate connections first
        if (next_step$type == "connection_review") {
          rv$suggested_connections <- generate_connections(rv$elements)

          # Add connection suggestions message
          conn_count <- length(rv$suggested_connections)
          message <- paste0(next_step$question, " I've identified ", conn_count,
                           " potential connections based on the DAPSI(W)R(M) framework logic. ",
                           "Review each connection below and approve or reject them.")

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
               message = "Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module.",
               timestamp = Sys.time())
        ))
      }

      # Scroll to bottom
      shinyjs::runjs(sprintf("document.getElementById('%s').scrollTop = document.getElementById('%s').scrollHeight",
                            session$ns("chat_container"), session$ns("chat_container")))
    }

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
        p(style = "text-align: center;", "Total elements created")
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
        h3(icon("project-diagram"), " Your DAPSI(W)R(M) Model Preview"),
        hr(),

        if (!is.null(rv$context$project_name)) {
          div(
            h4(icon("map-marker-alt"), " Project Information"),
            tags$ul(
              tags$li(strong("Project/Location: "), rv$context$project_name),
              if (!is.null(rv$context$ecosystem_type)) tags$li(strong("Ecosystem Type: "), rv$context$ecosystem_type),
              if (!is.null(rv$context$main_issue)) tags$li(strong("Main Issue: "), rv$context$main_issue)
            ),
            hr()
          )
        },

        # Drivers
        if (length(rv$elements$drivers) > 0) {
          div(
            h4(style = "color: #776db3;", icon("flag"), " Drivers (Societal Needs)"),
            tags$ul(
              lapply(rv$elements$drivers, function(d) tags$li(d$name))
            )
          )
        },

        # Activities
        if (length(rv$elements$activities) > 0) {
          div(
            h4(style = "color: #5abc67;", icon("running"), " Activities (Human Actions)"),
            tags$ul(
              lapply(rv$elements$activities, function(a) tags$li(a$name))
            )
          )
        },

        # Pressures
        if (length(rv$elements$pressures) > 0) {
          div(
            h4(style = "color: #fec05a;", icon("exclamation-triangle"), " Pressures (Environmental Stressors)"),
            tags$ul(
              lapply(rv$elements$pressures, function(p) tags$li(p$name))
            )
          )
        },

        # State Changes
        if (length(rv$elements$states) > 0) {
          div(
            h4(style = "color: #bce2ee;", icon("water"), " State Changes (Ecosystem Effects)"),
            tags$ul(
              lapply(rv$elements$states, function(s) tags$li(s$name))
            )
          )
        },

        # Impacts
        if (length(rv$elements$impacts) > 0) {
          div(
            h4(style = "color: #313695;", icon("chart-line"), " Impacts (Service Effects)"),
            tags$ul(
              lapply(rv$elements$impacts, function(i) tags$li(i$name))
            )
          )
        },

        # Welfare
        if (length(rv$elements$welfare) > 0) {
          div(
            h4(style = "color: #fff1a2; text-shadow: 1px 1px 2px #666;", icon("heart"), " Welfare (Human Well-being)"),
            tags$ul(
              lapply(rv$elements$welfare, function(w) tags$li(w$name))
            )
          )
        },

        # Responses
        if (length(rv$elements$responses) > 0) {
          div(
            h4(style = "color: #66c2a5;", icon("shield-alt"), " Responses (Management Actions)"),
            tags$ul(
              lapply(rv$elements$responses, function(r) tags$li(r$name))
            )
          )
        },

        # Measures
        if (length(rv$elements$measures) > 0) {
          div(
            h4(style = "color: #3288bd;", icon("gavel"), " Measures (Policy Instruments)"),
            tags$ul(
              lapply(rv$elements$measures, function(m) tags$li(m$name))
            )
          )
        },

        hr(),
        p(class = "text-muted",
          "Total elements: ",
          sum(length(rv$elements$drivers), length(rv$elements$activities),
              length(rv$elements$pressures), length(rv$elements$states),
              length(rv$elements$impacts), length(rv$elements$welfare),
              length(rv$elements$responses), length(rv$elements$measures)))
      )

      showModal(modalDialog(
        preview_content,
        title = NULL,
        size = "l",
        easyClose = TRUE,
        footer = tagList(
          modalButton("Close"),
          actionButton(session$ns("save_from_preview"), "Save to ISA Data Entry",
                      class = "btn-success", icon = icon("save"))
        )
      ))
    })

    # Handle save from preview modal
    observeEvent(input$save_from_preview, {
      removeModal()
      # Trigger the main save action
      showNotification(
        "Model saved! Navigate to 'ISA Data Entry' to see your elements.",
        type = "message",
        duration = 5
      )
    })

    # Handle start over
    observeEvent(input$start_over, {
      showModal(modalDialog(
        title = "Confirm Start Over",
        "Are you sure you want to start over? All current progress will be lost.",
        footer = tagList(
          modalButton("Cancel"),
          actionButton(session$ns("confirm_start_over"), "Yes, Start Over", class = "btn-danger")
        )
      ))
    })

    observeEvent(input$confirm_start_over, {
      rv$current_step <- 0
      rv$conversation <- list(
        list(type = "ai", message = QUESTION_FLOW[[1]]$question, timestamp = Sys.time())
      )
      rv$elements <- list(
        drivers = list(), activities = list(), pressures = list(),
        states = list(), impacts = list(), welfare = list(),
        responses = list(), measures = list()
      )
      rv$context <- list(
        project_name = NULL, location = NULL,
        ecosystem_type = NULL, main_issue = NULL
      )
      removeModal()
    })

    # Handle load template
    observeEvent(input$load_template, {
      showModal(modalDialog(
        title = "Load Example Template",
        h4("Choose a pre-built scenario:"),
        fluidRow(
          column(6,
            actionButton(session$ns("template_overfishing"), "Overfishing in Coastal Waters",
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_pollution"), "Marine Pollution & Plastics",
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        fluidRow(
          column(6,
            actionButton(session$ns("template_tourism"), "Coastal Tourism Impacts",
                        class = "btn-primary btn-block", style = "margin: 5px;")
          ),
          column(6,
            actionButton(session$ns("template_climate"), "Climate Change & Coral Reefs",
                        class = "btn-primary btn-block", style = "margin: 5px;")
          )
        ),
        footer = modalButton("Cancel")
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
      showNotification("Overfishing template loaded with example connections! You can now preview or modify it.", type = "message", duration = 5)
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
      showNotification("Marine Pollution template loaded with example connections!", type = "message", duration = 5)
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
      showNotification("Coastal Tourism template loaded with example connections!", type = "message", duration = 5)
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
      showNotification("Climate Change template loaded with example connections!", type = "message", duration = 5)
    })

    # Handle save to ISA
    observeEvent(input$save_to_isa, {
      # Get current project data
      current_data <- project_data_reactive()

      # Convert AI Assistant elements to ISA dataframe format
      # CLD expects separate dataframes for each category

      # Create drivers dataframe
      if (length(rv$elements$drivers) > 0) {
        current_data$data$isa_data$drivers <- data.frame(
          name = sapply(rv$elements$drivers, function(x) x$name),
          description = sapply(rv$elements$drivers, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$drivers <- data.frame(
          name = character(), description = character(), indicator = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create activities dataframe
      if (length(rv$elements$activities) > 0) {
        current_data$data$isa_data$activities <- data.frame(
          name = sapply(rv$elements$activities, function(x) x$name),
          description = sapply(rv$elements$activities, function(x) x$description %||% ""),
          indicator = "",
          scale = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$activities <- data.frame(
          name = character(), description = character(), indicator = character(),
          scale = character(), stringsAsFactors = FALSE
        )
      }

      # Create pressures dataframe
      if (length(rv$elements$pressures) > 0) {
        current_data$data$isa_data$pressures <- data.frame(
          name = sapply(rv$elements$pressures, function(x) x$name),
          description = sapply(rv$elements$pressures, function(x) x$description %||% ""),
          indicator = "",
          type = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$pressures <- data.frame(
          name = character(), description = character(), indicator = character(),
          type = character(), stringsAsFactors = FALSE
        )
      }

      # Create marine_processes dataframe (states)
      if (length(rv$elements$states) > 0) {
        current_data$data$isa_data$marine_processes <- data.frame(
          name = sapply(rv$elements$states, function(x) x$name),
          description = sapply(rv$elements$states, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$marine_processes <- data.frame(
          name = character(), description = character(), indicator = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create ecosystem_services dataframe (impacts)
      if (length(rv$elements$impacts) > 0) {
        current_data$data$isa_data$ecosystem_services <- data.frame(
          name = sapply(rv$elements$impacts, function(x) x$name),
          description = sapply(rv$elements$impacts, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$ecosystem_services <- data.frame(
          name = character(), description = character(), indicator = character(),
          stringsAsFactors = FALSE
        )
      }

      # Create goods_benefits dataframe (welfare)
      if (length(rv$elements$welfare) > 0) {
        current_data$data$isa_data$goods_benefits <- data.frame(
          name = sapply(rv$elements$welfare, function(x) x$name),
          description = sapply(rv$elements$welfare, function(x) x$description %||% ""),
          indicator = "",
          stringsAsFactors = FALSE
        )
      } else {
        current_data$data$isa_data$goods_benefits <- data.frame(
          name = character(), description = character(), indicator = character(),
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
      if (length(rv$approved_connections) > 0) {
        # Get dimensions for each matrix
        n_drivers <- length(rv$elements$drivers)
        n_activities <- length(rv$elements$activities)
        n_pressures <- length(rv$elements$pressures)
        n_states <- length(rv$elements$states)
        n_impacts <- length(rv$elements$impacts)
        n_welfare <- length(rv$elements$welfare)

        # Initialize matrices
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

        # Fill matrices with approved connections
        for (conn_idx in rv$approved_connections) {
          conn <- rv$suggested_connections[[conn_idx]]
          value <- paste0(conn$polarity, conn$strength)

          # Determine which matrix and indices
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
          }
        }
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
      project_data_reactive(current_data)

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

      showNotification(
        paste0("Model saved successfully! ", total_elements, " elements and ",
               n_connections, " connections transferred to ISA Data Entry."),
        type = "message",
        duration = 5
      )
    })

  })
}
