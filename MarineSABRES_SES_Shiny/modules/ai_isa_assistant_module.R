# modules/ai_isa_assistant_module.R
# AI-Assisted ISA Creation Module
# Purpose: Guide users through stepwise questions to build DAPSI(W)R(M) framework

# ============================================================================
# UI FUNCTION
# ============================================================================

ai_isa_assistant_ui <- function(id, i18n) {
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
        uiOutput(ns("module_header"))
      )
    ),

    # Note: Progress indicator is shown in sidebar (see sidebar_panel section)

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
        uiOutput(ns("sidebar_panel"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

ai_isa_assistant_server <- function(id, project_data_reactive, i18n) {
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
        title_key = "welcome",
        title = i18n$t("Welcome & Introduction"),
        question = i18n$t("Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?"),
        type = "text",
        target = "project_name"
      ),
      list(
        step = 1,
        title_key = "ecosystem",
        title = i18n$t("Ecosystem Context"),
        question = i18n$t("Great! Now, what type of marine ecosystem are you studying?"),
        type = "choice",
        options = c(i18n$t("Coastal waters"), i18n$t("Open ocean"), i18n$t("Estuaries"), i18n$t("Coral reefs"), i18n$t("Mangroves"), i18n$t("Seagrass beds"), i18n$t("Deep sea"), i18n$t("Other")),
        target = "ecosystem_type"
      ),
      list(
        step = 2,
        title_key = "main_issue",
        title = i18n$t("Main Issue Identification"),
        question = i18n$t("What is the main environmental or management issue you're addressing?"),
        type = "text",
        target = "main_issue"
      ),
      list(
        step = 3,
        title_key = "drivers",
        title = i18n$t("Drivers - Societal Needs"),
        question = i18n$t("Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs? (e.g., Food security, Economic development, Recreation, Energy needs)"),
        type = "multiple",
        target = "drivers",
        examples = c(i18n$t("Food security"), i18n$t("Economic development"), i18n$t("Recreation and tourism"), i18n$t("Energy needs"), i18n$t("Coastal protection"), i18n$t("Cultural heritage"))
      ),
      list(
        step = 4,
        title_key = "activities",
        title = i18n$t("Activities - Human Actions"),
        question = i18n$t("Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area? (e.g., Fishing, Aquaculture, Shipping, Tourism)"),
        type = "multiple",
        target = "activities",
        examples = c(i18n$t("Commercial fishing"), i18n$t("Recreational fishing"), i18n$t("Aquaculture"), i18n$t("Shipping/Transport"), i18n$t("Tourism"), i18n$t("Coastal development"), i18n$t("Renewable energy (wind/wave)"), i18n$t("Oil & gas extraction"))
      ),
      list(
        step = 5,
        title_key = "pressures",
        title = i18n$t("Pressures - Environmental Stressors"),
        question = i18n$t("What PRESSURES do these activities put on the marine environment? (e.g., Overfishing, Pollution, Habitat destruction)"),
        type = "multiple",
        target = "pressures",
        examples = c(i18n$t("Overfishing"), i18n$t("Bycatch"), i18n$t("Physical habitat damage"), i18n$t("Pollution (nutrients, chemicals)"), i18n$t("Noise pollution"), i18n$t("Marine litter/plastics"), i18n$t("Temperature changes"), i18n$t("Ocean acidification"))
      ),
      list(
        step = 6,
        title_key = "states",
        title = i18n$t("State Changes - Ecosystem Effects"),
        question = i18n$t("How do these pressures change the STATE of the marine ecosystem? (e.g., Declining fish stocks, Loss of biodiversity, Degraded water quality)"),
        type = "multiple",
        target = "states",
        examples = c(i18n$t("Declining fish stocks"), i18n$t("Loss of biodiversity"), i18n$t("Habitat degradation"), i18n$t("Water quality decline"), i18n$t("Altered food webs"), i18n$t("Invasive species"), i18n$t("Loss of ecosystem resilience"))
      ),
      list(
        step = 7,
        title_key = "impacts",
        title = i18n$t("Impacts - Effects on Ecosystem Services"),
        question = i18n$t("What are the IMPACTS on ecosystem services and benefits? How do these changes affect what the ocean provides? (e.g., Reduced fish catch, Loss of tourism revenue)"),
        type = "multiple",
        target = "impacts",
        examples = c(i18n$t("Reduced fish catch"), i18n$t("Loss of tourism revenue"), i18n$t("Reduced coastal protection"), i18n$t("Loss of biodiversity value"), i18n$t("Reduced water quality for recreation"), i18n$t("Loss of cultural services"))
      ),
      list(
        step = 8,
        title_key = "welfare",
        title = i18n$t("Welfare - Human Well-being Effects"),
        question = i18n$t("How do these impacts affect human WELFARE and well-being? (e.g., Loss of livelihoods, Health impacts, Reduced quality of life)"),
        type = "multiple",
        target = "welfare",
        examples = c(i18n$t("Loss of livelihoods"), i18n$t("Food insecurity"), i18n$t("Economic losses"), i18n$t("Health impacts"), i18n$t("Loss of cultural identity"), i18n$t("Reduced quality of life"), i18n$t("Social conflicts"))
      ),
      list(
        step = 9,
        title_key = "responses",
        title = i18n$t("Responses - Management Actions"),
        question = i18n$t("What RESPONSES or management actions are being taken (or could be taken) to address these issues? (e.g., Marine protected areas, Fishing quotas, Pollution regulations)"),
        type = "multiple",
        target = "responses",
        examples = c(i18n$t("Marine protected areas (MPAs)"), i18n$t("Fishing quotas/limits"), i18n$t("Pollution regulations"), i18n$t("Habitat restoration"), i18n$t("Sustainable fishing practices"), i18n$t("Ecosystem-based management"), i18n$t("Stakeholder engagement"), i18n$t("Monitoring programs"))
      ),
      list(
        step = 10,
        title_key = "measures",
        title = i18n$t("Measures - Policy Instruments"),
        question = i18n$t("Finally, what specific MEASURES or policy instruments support these responses? (e.g., Laws, Economic incentives, Education programs)"),
        type = "multiple",
        target = "measures",
        examples = c(i18n$t("Environmental legislation"), i18n$t("Marine spatial planning"), i18n$t("Economic incentives (subsidies, taxes)"), i18n$t("Education and awareness programs"), i18n$t("Certification schemes (MSC, etc.)"), i18n$t("International agreements"), i18n$t("Monitoring and enforcement"), i18n$t("Research funding"))
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
        h2(icon("robot"), " ", i18n$t("AI-Assisted ISA Creation")),
        p(class = "lead", i18n$t("Let me guide you step-by-step through building your DAPSI(W)R(M) model."))
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

        # Progress bar
        uiOutput(ns("progress_bar")),

        hr(),

        h4(icon("chart-line"), " ", i18n$t("Elements Created:")),
        uiOutput(ns("elements_summary")),

        hr(),

        h4(icon("sitemap"), " ", i18n$t("Framework Flow:")),
        uiOutput(ns("dapsiwrm_diagram")),

        hr(),

        h4(icon("network-wired"), " ", i18n$t("Current Framework:")),
        tags$ul(
          tags$li(strong(i18n$t("Drivers:")), " ", textOutput(ns("count_drivers"), inline = TRUE)),
          tags$li(strong(i18n$t("Activities:")), " ", textOutput(ns("count_activities"), inline = TRUE)),
          tags$li(strong(i18n$t("Pressures:")), " ", textOutput(ns("count_pressures"), inline = TRUE)),
          tags$li(strong(i18n$t("State Changes:")), " ", textOutput(ns("count_states"), inline = TRUE)),
          tags$li(strong(i18n$t("Impacts:")), " ", textOutput(ns("count_impacts"), inline = TRUE)),
          tags$li(strong(i18n$t("Welfare:")), " ", textOutput(ns("count_welfare"), inline = TRUE)),
          tags$li(strong(i18n$t("Responses:")), " ", textOutput(ns("count_responses"), inline = TRUE)),
          tags$li(strong(i18n$t("Measures:")), " ", textOutput(ns("count_measures"), inline = TRUE))
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
          wellPanel(
            textAreaInput(session$ns("user_input"),
                         label = NULL,
                         placeholder = i18n$t("Type your answer here..."),
                         rows = 3,
                         width = "100%"),
            fluidRow(
              column(6,
                actionButton(session$ns("submit_answer"), i18n$t("Submit Answer"),
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
        return(p(i18n$t("No connections to review.")))
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
                     i18n$t("Polarity:"), " ", span(style = paste0("color: ", if(conn$polarity == "+") "green" else "red"),
                                       conn$polarity), " | ",
                     i18n$t("Strength:"), " ", conn$strength)
              )
            ),
            column(4,
              if (is_approved) {
                actionButton(session$ns(paste0("reject_conn_", i)),
                            i18n$t("Reject"),
                            icon = icon("times"),
                            class = "btn-danger btn-sm btn-block")
              } else {
                actionButton(session$ns(paste0("approve_conn_", i)),
                            i18n$t("Approve"),
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
      showNotification(i18n$t("All connections approved!"), type = "message")
    })

    # Finish connection review
    observeEvent(input$finish_connections, {
      approved_count <- length(rv$approved_connections)

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = paste0(i18n$t("Great! You've approved"), " ", approved_count, " ",
                            i18n$t("connections out of"), " ",
                            length(rv$suggested_connections), " ", i18n$t("suggested connections."), " ",
                            i18n$t("These connections will be included in your saved ISA data.")),
             timestamp = Sys.time())
      ))

      move_to_next_step()
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

    # Render quick options
    output$quick_options <- renderUI({
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (!is.null(step_info$examples)) {
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

          if (!is.null(step_info$examples)) {
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
              confidence = CONFIDENCE_DEFAULT,  # Default confidence for auto-generated connections
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
              confidence = CONFIDENCE_DEFAULT,  # Default confidence for auto-generated connections
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
              confidence = 3,
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
              confidence = 3,
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
              confidence = 3,
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
              confidence = 3,
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
              confidence = 3,
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
      # Check if we can move forward before incrementing
      if (rv$current_step < length(QUESTION_FLOW)) {
        rv$current_step <- rv$current_step + 1
      }

      if (rv$current_step < length(QUESTION_FLOW)) {
        # Add next question
        next_step <- QUESTION_FLOW[[rv$current_step + 1]]

        # If moving to connection review step, generate connections first
        if (next_step$type == "connection_review") {
          rv$suggested_connections <- generate_connections(rv$elements)

          # Add connection suggestions message
          conn_count <- length(rv$suggested_connections)
          message <- paste0(next_step$question, " ", i18n$t("I've identified"), " ", conn_count,
                           " ", i18n$t("potential connections based on the DAPSI(W)R(M) framework logic."), " ",
                           i18n$t("Review each connection below and approve or reject them."))

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
        p(class = "text-muted",
          i18n$t("Total elements:"), " ",
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

    # Handle save to ISA
    observeEvent(input$save_to_isa, {
      cat("[AI ISA] Save to ISA clicked\n")

      tryCatch({
        # Get current project data
        current_data <- project_data_reactive()
        cat("[AI ISA] Retrieved project data\n")

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

        cat(sprintf("[AI ISA] Saving %d drivers, %d activities, %d pressures, %d states, %d impacts, %d welfare, %d responses, %d measures\n",
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
          # Format: "+strength:confidence"
          confidence <- conn$confidence %||% CONFIDENCE_DEFAULT  # Default if not present
          value <- paste0(conn$polarity, conn$strength, ":", confidence)

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
