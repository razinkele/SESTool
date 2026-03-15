# modules/ai_isa_assistant_module.R
# AI-Assisted SES Creation Module
# Purpose: Guide users through stepwise questions to build DAPSI(W)R(M) framework

# Load helper modules
# NOTE: ai_isa_knowledge_base.R is now sourced globally in global.R
# NOTE: connection_review_tabbed.R is sourced globally in global.R

# Load AI ISA sub-modules
source("modules/ai_isa/connection_generator.R", local = TRUE)
source("modules/ai_isa/ui_components.R", local = TRUE)
source("modules/ai_isa/question_flow.R", local = TRUE)
source("modules/ai_isa/answer_processor.R", local = TRUE)
source("modules/ai_isa/data_persistence.R", local = TRUE)
source("modules/ai_isa/ui_renderers.R", local = TRUE)
source("modules/ai_isa/template_handlers.R", local = TRUE)
source("modules/ai_isa/action_handlers.R", local = TRUE)
source("modules/ai_isa/step_navigation.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

ai_isa_assistant_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  fluidPage(
    # External CSS (extracted from inline styles)
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "ai-isa-assistant.css"),
      # JavaScript for local storage - use ns() for proper namespacing
      tags$script(HTML(sprintf("
        // SESSION-SCOPED localStorage for AI ISA Assistant
        // CRITICAL: Prevents cross-session data leakage in multi-user deployments
        var _ai_isa_session_id = null;

        // Initialize session ID for scoped localStorage
        Shiny.addCustomMessageHandler('init_ai_isa_session_id', function(message) {
          _ai_isa_session_id = message.session_id;
          console.log('[AI ISA] Session initialized:', _ai_isa_session_id);
        });

        // Helper to get session-scoped localStorage key
        function getAiIsaKey(suffix) {
          return _ai_isa_session_id ? 'ai_isa_' + _ai_isa_session_id + '_' + suffix : 'ai_isa_session_' + suffix;
        }

        // Save data to localStorage (SESSION-SCOPED)
        Shiny.addCustomMessageHandler('save_ai_isa_session', function(data) {
          try {
            var dataKey = getAiIsaKey('data');
            var timestampKey = getAiIsaKey('timestamp');
            localStorage.setItem(dataKey, JSON.stringify(data));
            localStorage.setItem(timestampKey, new Date().toISOString());
            console.log('[AI ISA] Session saved to localStorage (session:', _ai_isa_session_id, ')');
          } catch(e) {
            console.error('[AI ISA] Failed to save to localStorage:', e);
          }
        });

        // Load data from localStorage (SESSION-SCOPED)
        Shiny.addCustomMessageHandler('load_ai_isa_session', function(message) {
          try {
            var dataKey = getAiIsaKey('data');
            var timestampKey = getAiIsaKey('timestamp');
            var savedData = localStorage.getItem(dataKey);
            var timestamp = localStorage.getItem(timestampKey);

            if (savedData) {
              Shiny.setInputValue('%s', {
                data: JSON.parse(savedData),
                timestamp: timestamp
              }, {priority: 'event'});
            } else {
              Shiny.setInputValue('%s', null, {priority: 'event'});
            }
          } catch(e) {
            console.error('[AI ISA] Failed to load from localStorage:', e);
            Shiny.setInputValue('%s', null, {priority: 'event'});
          }
        });

        // Check for saved session on page load (SESSION-SCOPED)
        // NOTE: Only checks after session ID is initialized
        $(document).on('shiny:connected', function() {
          // Defer check until session ID is set
          setTimeout(function() {
            if (_ai_isa_session_id) {
              var dataKey = getAiIsaKey('data');
              var savedData = localStorage.getItem(dataKey);
              if (savedData) {
                Shiny.setInputValue('%s', true, {priority: 'event'});
              }
            }
          }, 500);  // Wait for session ID initialization
        });

        // Clear session from localStorage (SESSION-SCOPED)
        Shiny.addCustomMessageHandler('clear_ai_isa_session', function(message) {
          try {
            var dataKey = getAiIsaKey('data');
            var timestampKey = getAiIsaKey('timestamp');
            localStorage.removeItem(dataKey);
            localStorage.removeItem(timestampKey);
            console.log('[AI ISA] Session cleared from localStorage (session:', _ai_isa_session_id, ')');
          } catch(e) {
            console.error('[AI ISA] Failed to clear localStorage:', e);
          }
        });
      ", ns("loaded_session_data"), ns("loaded_session_data"),
         ns("loaded_session_data"), ns("has_saved_session"))))
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

ai_isa_assistant_server <- function(id, project_data_reactive, i18n, event_bus = NULL, autosave_enabled_reactive = NULL, user_level_reactive = NULL, parent_session = NULL, beginner_max_elements_reactive = NULL) {
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
        responses = list()  # Combined responses and measures (R/M in DAPSI(W)R(M))
      ),
      context = list(
        project_name = NULL,
        regional_sea = NULL,
        ecosystem_type = NULL,
        ecosystem_subtype = NULL,
        countries = character(0),
        main_issue = character(0)  # Changed to vector for multiple selections
      ),
      selected_countries = character(0),  # Track selected countries for UI highlighting
      selected_issues = character(0),  # Track selected issues for UI highlighting
      total_steps = 11,  # Updated: added country selection step
      suggested_connections = list(),  # AI-generated connection suggestions
      approved_connections = list(),   # User-approved connections
      last_save_time = NULL,  # Track last save timestamp
      auto_save_enabled = TRUE,  # Auto-save toggle
      auto_saved_step_10 = FALSE,  # Flag to prevent auto-save infinite loop
      show_text_input = FALSE,  # Flag to show text input when "Other" is selected
      render_counter = 0  # Counter to force UI re-render for selection highlighting
    )

    # ========================================================================
    # SESSION-SCOPED LOCALSTORAGE INITIALIZATION
    # ========================================================================
    # CRITICAL: Send session ID to JavaScript for session-scoped localStorage keys
    # This prevents cross-session data leakage in multi-user shiny-server deployments
    session_id <- if (!is.null(session$userData$session_id)) {
      session$userData$session_id
    } else if (!is.null(parent_session) && !is.null(parent_session$userData$session_id)) {
      parent_session$userData$session_id
    } else {
      # Fallback: generate unique ID (legacy behavior)
      paste0("ai_isa_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(1000:9999, 1))
    }

    session$sendCustomMessage(
      type = "init_ai_isa_session_id",
      message = list(session_id = session_id)
    )
    debug_log(sprintf("[AI ISA] Initialized JavaScript with session ID: %s", session_id), "AI_ISA")

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

      debug_log("[AI ISA] Observer triggered\n")

      # Only proceed if we don't already have elements and there's data to load
      if (length(rv$elements$drivers) == 0 &&
          length(rv$elements$activities) == 0) {

        debug_log("[AI ISA] Elements are empty, checking for data\n")

        isolate({
          tryCatch({

        if (!is.null(recovered_data) && !is.null(recovered_data$data$isa_data)) {
          debug_log("[AI ISA] Found data in project_data_reactive\n")
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
          debug_log(sprintf("[AI ISA] Element counts - drivers: %d, activities: %d, pressures: %d, states: %d, impacts: %d, welfare: %d, responses: %d\n",
            if(!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0,
            if(!is.null(isa_data$activities)) nrow(isa_data$activities) else 0,
            if(!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0,
            if(!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0,
            if(!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0,
            if(!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0,
            if(!is.null(isa_data$responses)) nrow(isa_data$responses) else 0
          ))

          debug_log(sprintf("[AI ISA] has_data check result: %s\n", has_data))

          if (has_data) {
            debug_log("[AI ISA] Loading recovered data from project_data_reactive\n")

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
              debug_log(sprintf("[AI ISA] Recovered %d connections (%d approved)\n",
                          length(rv$suggested_connections),
                          length(rv$approved_connections)))
            } else if (!is.null(isa_data$adjacency_matrices)) {
              # Convert adjacency matrices to connection list format
              debug_log("[AI ISA] Converting adjacency matrices to connection list...\n")
              rv$suggested_connections <- convert_matrices_to_connections(
                isa_data$adjacency_matrices,
                rv$elements
              )
              # Mark all as approved since they came from a saved/template source
              rv$approved_connections <- seq_along(rv$suggested_connections)
              debug_log(sprintf("[AI ISA] Converted %d connections from adjacency matrices (all approved)\n",
                          length(rv$suggested_connections)))
            }

            # Set to step 11 (completed) since data was recovered
            rv$current_step <- 11

            total_recovered <- sum(
              length(rv$elements$drivers),
              length(rv$elements$activities),
              length(rv$elements$pressures),
              length(rv$elements$states),
              length(rv$elements$impacts),
              length(rv$elements$welfare),
              length(rv$elements$responses)
            )

            debug_log(sprintf("[AI ISA] Recovered %d elements into AI ISA Assistant UI\n", total_recovered))
          }
        }
          }, error = function(e) {
            debug_log(sprintf("[AI ISA] Recovery initialization error: %s\n", e$message))
          })
        })
      }
    })

    # Define the stepwise questions (single source of truth in question_flow.R)
    QUESTION_FLOW <- define_question_flow(i18n)

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
      bs4Card(
        title = i18n$t("modules.isa.ai_assistant.your_ses_model_progress"),
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        # Add ribbon badge for AI feature
        label = bs4CardLabel(
          text = "AI",
          status = "primary",
          tooltip = "AI-Powered Assistant"
        ),

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
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_activities"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.response.measures.activities")), " ", textOutput(ns("count_activities"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_pressures"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.response.measures.pressures")), " ", textOutput(ns("count_pressures"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_states"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.state_changes")), " ", textOutput(ns("count_states"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_impacts"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.impacts")), " ", textOutput(ns("count_impacts"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_welfare"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.welfare")), " ", textOutput(ns("count_welfare"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
              ),
              tags$div(
                style = "margin-bottom: 5px;",
                actionLink(ns("link_responses"),
                          tagList(icon("arrow-circle-right"), " ", strong(i18n$t("modules.isa.ai_assistant.response_measures")), " ", textOutput(ns("count_responses"), inline = TRUE)),
                          style = CSS_TEXT_PRIMARY)
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
    # NOTE: Functions moved to modules/ai_isa/data_persistence.R

    # Auto-save observer - triggers on data changes
    observe({
      # Trigger on any data change
      rv$current_step
      rv$elements
      rv$context
      rv$approved_connections

      # Guard: only auto-save when enabled and past the initial step
      req(rv$auto_save_enabled)
      req(rv$current_step > 0)

      isolate({
        # Debounce: only save if at least 2 seconds since last save
        current_time <- Sys.time()
        if (is.null(rv$last_save_time) ||
            difftime(current_time, rv$last_save_time, units = "secs") > 2) {

          session_data <- get_session_data(rv)
          session$sendCustomMessage("save_ai_isa_session", session_data)
          rv$last_save_time <- current_time
        }
      })
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
      session_data <- get_session_data(rv)
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
        restore_session_data(rv, rv$temp_loaded_data)
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

    # Step title rendering handled by setup_ui_renderers()

    # Note: progress_bar is rendered later (see line 1170) with better calculation using rv$total_steps

    # Helper function to highlight keywords in question text
    highlight_keywords <- function(text) {
      # Escape user-derived content first to prevent XSS
      text <- htmltools::htmlEscape(text)

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

      debug_log(sprintf("EXECUTION #%d | step: %d | show_text: %s | counter: %d",
                        input_area_exec_count, rv$current_step, rv$show_text_input, counter_val),
                "AI ISA INPUT_AREA")

      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (step_info$type == "connection_review") {
          # Connection review interface using tabbed module
          wellPanel(
            h4(icon("link"), " ", i18n$t("modules.isa.ai_assistant.review_suggested_connections")),
            p(i18n$t("modules.isa.approve_or_reject_each_connection_organized_by_fra")),
            connection_review_tabbed_ui(session$ns("conn_review"), i18n),
            br(),
            # Dynamic finish button - only appears when all categories are reviewed
            uiOutput(session$ns("finish_button_container"))
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

    # Render Finish button container - only shows when all categories are reviewed
    output$finish_button_container <- renderUI({
      # Get all connections and their approval/rejection status
      total_conns <- length(rv$suggested_connections)
      approved_count <- length(rv$approved_connections)

      # Calculate how many have been reviewed (approved OR rejected)
      # The connection review module tracks both approved and rejected
      # For this simplified check, we show the button when at least some connections are approved
      # A more sophisticated check would require tracking rejected connections too

      # Show button when user has reviewed connections
      # For now, show it always but with a warning if not all reviewed
      if (total_conns > 0 && approved_count > 0) {
        # Check for unconnected elements - collect all element names from rv$elements
        all_elements <- character()
        if (!is.null(rv$elements) && length(rv$elements) > 0) {
          for (el_list in rv$elements) {
            if (is.list(el_list)) {
              for (el in el_list) {
                if (!is.null(el$name) && nchar(trimws(el$name)) > 0) {
                  all_elements <- c(all_elements, el$name)
                }
              }
            }
          }
        }
        all_elements <- unique(all_elements)

        # Find which elements appear in approved connections
        # Connection objects use from_name/to_name (not from/to)
        connected_elements <- character()
        for (idx in rv$approved_connections) {
          conn <- rv$suggested_connections[[idx]]
          if (!is.null(conn)) {
            if (!is.null(conn$from_name)) connected_elements <- c(connected_elements, conn$from_name)
            if (!is.null(conn$to_name)) connected_elements <- c(connected_elements, conn$to_name)
          }
        }
        connected_elements <- unique(connected_elements)

        # Elements with no connections
        unconnected <- setdiff(all_elements, connected_elements)

        # Build warning UI if unconnected elements exist
        unconnected_warning <- NULL
        if (length(unconnected) > 0 && length(all_elements) > 0) {
          pct_connected <- round(100 * length(connected_elements) / length(all_elements))
          unconnected_warning <- div(
            style = "margin-bottom: 12px; padding: 12px; background: #fff3e0; border-left: 4px solid #ff9800; border-radius: 4px;",
            p(style = "color: #e65100; margin-bottom: 6px; font-weight: 600;",
              icon("exclamation-triangle"), " ",
              sprintf(i18n$t("modules.isa.ai_assistant.unconnected_elements_warning"),
                      length(unconnected), length(all_elements))
            ),
            p(style = "color: #bf360c; font-size: 13px; margin-bottom: 4px;",
              paste(unconnected, collapse = ", ")
            ),
            p(style = "color: #795548; font-size: 12px; margin: 0;",
              i18n$t("modules.isa.ai_assistant.unconnected_elements_hint")
            )
          )
        }

        # Some connections approved - show finish button
        fluidRow(
          column(12,
            div(style = "margin-top: 15px; padding: 15px; background: #e8f5e9; border-radius: 8px; text-align: center;",
              unconnected_warning,
              p(style = "color: #2e7d32; margin-bottom: 10px;",
                icon("check-circle"),
                sprintf(" %s %d %s", i18n$t("modules.isa.ai_assistant.youve_approved"), approved_count, i18n$t("modules.isa.ai_assistant.connections"))),
              actionButton(session$ns("finish_connections"), i18n$t("modules.isa.ai_assistant.finish_continue"),
                          icon = icon("arrow-right"),
                          class = "btn-primary btn-lg",
                          style = "min-width: 250px;")
            )
          )
        )
      } else if (total_conns > 0) {
        # Connections available but none approved yet - show guidance
        div(style = "margin-top: 15px; padding: 15px; background: #fff3e0; border-radius: 8px; text-align: center;",
          p(style = "color: #ef6c00;",
            icon("info-circle"),
            " ", i18n$t("common.misc.review_connections_to_continue"))
        )
      }
    })

    # Call the connection_review_tabbed server module
    connection_review_tabbed_server(
      id = "conn_review",
      connections_reactive = reactive(rv$suggested_connections),
      i18n = i18n,
      on_approve = function(index, conn) {
        # Add to approved list
        if (!(index %in% rv$approved_connections)) {
          rv$approved_connections <- c(rv$approved_connections, index)
          debug_log(sprintf("[AI ISA CONN REVIEW] Connection #%d approved (total: %d)\n",
                     index, length(rv$approved_connections)))
        }
      },
      on_reject = function(index, conn) {
        # Remove from approved list
        rv$approved_connections <- setdiff(rv$approved_connections, index)
        debug_log(sprintf("[AI ISA CONN REVIEW] Connection #%d rejected (total approved: %d)\n",
                   index, length(rv$approved_connections)))
      },
      on_amend = function(index, polarity, strength, confidence) {
        # Update the connection with amended values
        if (index <= length(rv$suggested_connections)) {
          rv$suggested_connections[[index]]$polarity <- polarity
          rv$suggested_connections[[index]]$strength <- strength
          rv$suggested_connections[[index]]$confidence <- confidence
          debug_log(sprintf("[AI ISA CONN REVIEW] Connection #%d amended: %s, %s, %d\n",
                     index, polarity, strength, confidence))
        }
      }
    )

    # Approve all connections
    observeEvent(input$approve_all_connections, {
      rv$approved_connections <- seq_along(rv$suggested_connections)
      debug_log(sprintf("[AI ISA CONNECTIONS] APPROVE ALL clicked - approved %d connections\n",
                 length(rv$approved_connections)))
      showNotification(i18n$t("modules.isa.ai_assistant.all_connections_approved"), type = "message")
    })

    # Finish connection review
    # NOTE: Element-to-ISA conversion and matrix building delegated to
    # save_to_project_format() in modules/ai_isa/data_persistence.R
    # Helper: find unconnected elements from approved connections
    .find_unconnected <- function() {
      all_elements <- character()
      if (!is.null(rv$elements) && length(rv$elements) > 0) {
        for (el_list in rv$elements) {
          if (is.list(el_list)) {
            for (el in el_list) {
              if (!is.null(el$name) && nchar(trimws(el$name)) > 0) {
                all_elements <- c(all_elements, el$name)
              }
            }
          }
        }
      }
      all_elements <- unique(all_elements)

      connected <- character()
      for (idx in rv$approved_connections) {
        conn <- rv$suggested_connections[[idx]]
        if (!is.null(conn)) {
          if (!is.null(conn$from_name)) connected <- c(connected, conn$from_name)
          if (!is.null(conn$to_name)) connected <- c(connected, conn$to_name)
        }
      }
      connected <- unique(connected)

      list(
        all = all_elements,
        connected = connected,
        unconnected = setdiff(all_elements, connected)
      )
    }

    # Helper: execute the actual save and navigate
    .do_finish_and_save <- function() {
      approved_count <- length(rv$approved_connections)

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai",
             message = paste0(i18n$t("modules.isa.ai_assistant.great_youve_approved"), " ", approved_count, " ",
                            i18n$t("modules.isa.ai_assistant.connections_out_of"), " ",
                            length(rv$suggested_connections), " ", i18n$t("modules.isa.ai_assistant.suggested_connections"), " ",
                            i18n$t("modules.isa.these_connections_will_be_included_in_your_saved_i")),
             timestamp = Sys.time())
      ))

      debug_log("[AI ISA CONNECTIONS] Saving with save_to_project_format()\n")
      current_data <- project_data_reactive()
      current_data <- save_to_project_format(rv, current_data, CONFIDENCE_DEFAULT)
      project_data_reactive(current_data)

      if (!is.null(event_bus)) {
        event_bus$emit_isa_change("ai_isa_assistant")
        debug_log("[AI ISA CONNECTIONS] Emitted ISA change event for CLD regeneration\n")
      }

      rv$auto_saved_step_10 <- TRUE
      rv$current_step <- 12

      showNotification(
        paste0(approved_count, " ", i18n$t("modules.isa.ai_assistant.connections_saved_navigating_to_dashboard")),
        type = "message", duration = 3
      )

      if (!is.null(parent_session)) {
        updateTabItems(parent_session, "sidebar_menu", "dashboard")
      }
    }

    # Finish button: check for unconnected elements first
    observeEvent(input$finish_connections, {
      approved_count <- length(rv$approved_connections)
      debug_log(sprintf("[AI ISA CONNECTIONS] FINISH clicked - %d approved, %d total suggested\n",
                 approved_count, length(rv$suggested_connections)))

      result <- .find_unconnected()

      if (length(result$unconnected) > 0 && length(result$all) > 0) {
        # Show confirmation dialog with options
        showModal(modalDialog(
          title = tagList(icon("exclamation-triangle", style = "color: #ff9800;"), " ",
                          i18n$t("modules.isa.ai_assistant.unconnected_elements_title")),
          size = "m",

          tags$div(
            style = "padding: 10px;",
            tags$p(
              style = "font-size: 14px; margin-bottom: 12px;",
              sprintf(i18n$t("modules.isa.ai_assistant.unconnected_elements_warning"),
                      length(result$unconnected), length(result$all))
            ),
            tags$div(
              style = "background: #fff3e0; padding: 12px; border-radius: 6px; margin-bottom: 15px; max-height: 200px; overflow-y: auto;",
              tags$ul(
                style = "margin: 0; padding-left: 20px;",
                lapply(result$unconnected, function(name) {
                  tags$li(style = "margin-bottom: 4px;", tags$strong(name))
                })
              )
            ),
            tags$p(
              style = "font-size: 13px; color: #666;",
              i18n$t("modules.isa.ai_assistant.unconnected_elements_hint")
            )
          ),

          footer = tagList(
            actionButton(session$ns("finish_remove_unconnected"),
              tagList(icon("trash-alt"), " ", i18n$t("modules.isa.ai_assistant.remove_unconnected_finish")),
              class = "btn-warning"),
            actionButton(session$ns("finish_review_again"),
              tagList(icon("undo"), " ", i18n$t("modules.isa.ai_assistant.review_connections_again")),
              class = "btn-info"),
            actionButton(session$ns("finish_keep_all"),
              tagList(icon("check"), " ", i18n$t("modules.isa.ai_assistant.keep_all_finish")),
              class = "btn-primary")
          ),
          easyClose = FALSE
        ))
      } else {
        # No unconnected elements - save directly
        .do_finish_and_save()
      }
    })

    # Dialog: Remove unconnected elements then finish
    observeEvent(input$finish_remove_unconnected, {
      removeModal()
      result <- .find_unconnected()

      # Remove unconnected elements from rv$elements
      for (cat_name in names(rv$elements)) {
        if (is.list(rv$elements[[cat_name]])) {
          rv$elements[[cat_name]] <- Filter(
            function(el) el$name %in% result$connected,
            rv$elements[[cat_name]]
          )
        }
      }

      # Remap connection indices after element removal.
      # Connections store from_index/to_index referencing positions in original
      # element lists. After filtering, positions change, so we rebuild indices
      # by name lookup and drop any connections referencing removed elements.
      matrix_to_categories <- list(
        d_a = c("drivers", "activities"), a_p = c("activities", "pressures"),
        p_mpf = c("pressures", "states"), mpf_es = c("states", "impacts"),
        es_gb = c("impacts", "welfare"), gb_d = c("welfare", "drivers"),
        gb_r = c("welfare", "responses"), r_d = c("responses", "drivers"),
        r_a = c("responses", "activities"), r_p = c("responses", "pressures")
      )

      # Build name-to-index maps for each category
      name_index_maps <- list()
      for (cat_name in names(rv$elements)) {
        if (is.list(rv$elements[[cat_name]])) {
          names_vec <- sapply(rv$elements[[cat_name]], function(x) x$name)
          name_index_maps[[cat_name]] <- setNames(seq_along(names_vec), names_vec)
        }
      }

      valid_approved <- integer()
      for (conn_idx in rv$approved_connections) {
        conn <- rv$suggested_connections[[conn_idx]]
        cats <- matrix_to_categories[[conn$matrix]]
        if (is.null(cats)) next

        from_map <- name_index_maps[[cats[1]]]
        to_map <- name_index_maps[[cats[2]]]
        new_from <- if (!is.null(from_map)) from_map[[conn$from_name]] else NULL
        new_to <- if (!is.null(to_map)) to_map[[conn$to_name]] else NULL

        if (!is.null(new_from) && !is.null(new_to)) {
          rv$suggested_connections[[conn_idx]]$from_index <- unname(new_from)
          rv$suggested_connections[[conn_idx]]$to_index <- unname(new_to)
          valid_approved <- c(valid_approved, conn_idx)
        }
      }
      rv$approved_connections <- valid_approved

      removed_count <- length(result$unconnected)
      showNotification(
        sprintf(i18n$t("modules.isa.ai_assistant.removed_unconnected_elements"), removed_count),
        type = "message", duration = 4
      )
      debug_log(sprintf("[AI ISA] Removed %d unconnected elements: %s",
                 removed_count, paste(result$unconnected, collapse = ", ")), "AI ISA")

      .do_finish_and_save()
    })

    # Dialog: Go back to review connections
    observeEvent(input$finish_review_again, {
      removeModal()
      showNotification(
        i18n$t("modules.isa.ai_assistant.review_connections_again_hint"),
        type = "message", duration = 5
      )
    })

    # Dialog: Keep all elements and finish anyway
    observeEvent(input$finish_keep_all, {
      removeModal()
      .do_finish_and_save()
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

        # For countries step (multiple selection), show count of selected countries
        if (step_info$target == "countries") {
          selected_count <- length(rv$selected_countries)
          if (selected_count > 0) {
            button_label <- paste0(i18n$t("modules.isa.ai_assistant.continue_with"), " ", selected_count, " ", i18n$t("modules.isa.ai_assistant.countries_selected"))
            button_icon <- icon("arrow-right")
          } else {
            button_label <- i18n$t("modules.isa.ai_assistant.skip_this_question")
            button_icon <- icon("forward")
          }
        }
        # For main_issue step (multiple selection), show count of selected items
        else if (step_info$target == "main_issue") {
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

        # Create both back and continue buttons in a row
        # Back button only shown after step 0 (regional sea selection)
        if (rv$current_step > 0) {
          div(
            class = "d-flex gap-2",
            style = "gap: 10px;",
            actionButton(session$ns("go_back"), i18n$t("modules.isa.ai_assistant.go_back"),
                        icon = icon("arrow-left"),
                        class = "btn-secondary",
                        style = "flex: 0 0 auto;",
                        title = i18n$t("modules.isa.ai_assistant.go_back_to_previous_step")),
            actionButton(session$ns("skip_question"), button_label,
                        icon = button_icon,
                        class = "btn-success",
                        style = "flex: 1;")
          )
        } else {
          # No back button on first step
          actionButton(session$ns("skip_question"), button_label,
                      icon = button_icon,
                      class = "btn-success btn-block")
        }
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

      debug_log(sprintf("EXECUTION #%d | step: %d/%d | counter: %d",
                        quick_options_exec_count, current_step, length(QUESTION_FLOW), counter_val),
                "AI ISA QUICK")

      # Return NULL first to force complete DOM cleanup
      if (current_step < 0 || current_step >= length(QUESTION_FLOW)) {
        return(NULL)
      }

      # Use current step as suffix to ensure unique IDs and enable proper observers
      render_suffix <- paste0("_s", current_step)

      step_info <- QUESTION_FLOW[[current_step + 1]]
      debug_log(sprintf("Step type: %s, target: %s", step_info$type, step_info$target), "AI ISA QUICK")

      # Handle regional sea selection
      if (step_info$type == "choice_regional_sea") {
          # CRITICAL FIX: Exclude "other" since it's created separately below
          regional_seas_list <- setdiff(names(REGIONAL_SEAS), "other")

          regional_sea_buttons <- lapply(regional_seas_list, function(sea_key) {
            sea_info <- REGIONAL_SEAS[[sea_key]]
            button_id <- session$ns(paste0("regional_sea_", sea_key, render_suffix))

            # Check if this regional sea is already selected (for breadcrumb navigation)
            is_selected <- !is.null(rv$context$regional_sea) && rv$context$regional_sea == sea_key
            button_class <- if (is_selected) "quick-option selected" else "quick-option"

            actionButton(
              inputId = button_id,
              label = sea_info$name_i18n,
              class = button_class,
              style = "margin: 3px; min-width: 150px;"
            )
          })

          # Add "Other" button
          other_button_id <- session$ns(paste0("regional_sea_other", render_suffix))

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

        # Handle country selection (multiple toggle)
        else if (step_info$type == "country_multiple") {
          # Get countries for the selected regional sea
          countries_list <- tryCatch(
            get_countries_for_sea(rv$context$regional_sea),
            error = function(e) {
              debug_log(sprintf("get_countries_for_sea error: %s", e$message), "AI ISA QUICK")
              NULL
            }
          )

          if (!is.null(countries_list) && length(countries_list) > 0) {
            # Separate EU and non-EU countries
            eu_countries <- countries_list[sapply(countries_list, function(c) isTRUE(c$eu_member))]
            non_eu_countries <- countries_list[sapply(countries_list, function(c) !isTRUE(c$eu_member))]

            make_country_buttons <- function(country_list) {
              lapply(country_list, function(country) {
                country_code <- country$code
                is_selected <- country_code %in% rv$selected_countries
                button_class <- if (is_selected) "quick-option selected" else "quick-option"

                eu_badge <- if (isTRUE(country$eu_member)) {
                  tags$span(
                    class = "badge badge-primary",
                    style = "font-size: 0.65em; vertical-align: super; margin-left: 3px; padding: 1px 4px;",
                    title = "EU Member State",
                    "EU"
                  )
                } else {
                  NULL
                }

                actionButton(
                  inputId = session$ns(paste0("country_", country_code, render_suffix)),
                  label = tagList(country$name, eu_badge),
                  class = button_class,
                  style = "margin: 3px; min-width: 150px;"
                )
              })
            }

            eu_buttons <- make_country_buttons(eu_countries)
            non_eu_buttons <- make_country_buttons(non_eu_countries)

            # Utility buttons (Select All / Clear All)
            select_all_btn <- actionButton(
              inputId = session$ns(paste0("country_select_all", render_suffix)),
              label = tagList(icon("check-double"), " ", i18n$t("modules.isa.ai_assistant.select_all_countries")),
              class = "btn-outline-primary btn-sm",
              style = "margin: 3px;"
            )
            clear_all_btn <- actionButton(
              inputId = session$ns(paste0("country_clear_all", render_suffix)),
              label = tagList(icon("times"), " ", i18n$t("modules.isa.ai_assistant.clear_countries")),
              class = "btn-outline-secondary btn-sm",
              style = "margin: 3px;"
            )

            selected_count <- length(rv$selected_countries)
            count_text <- if (selected_count > 0) {
              paste0(" (", selected_count, " ", i18n$t("modules.isa.ai_assistant.countries_selected"), ")")
            } else {
              ""
            }

            return(div(
              h5(style = "font-weight: 600; color: #667eea;",
                 paste0(i18n$t("modules.isa.ai_assistant.country_selection"), count_text)),
              p(style = "font-size: 0.9em; color: #666; margin-top: 5px;",
                i18n$t("modules.isa.ai_assistant.click_to_selectdeselect_multiple_selections_allowed")),
              div(style = "margin-top: 5px;", select_all_btn, clear_all_btn),
              if (length(eu_buttons) > 0) {
                tagList(
                  h6(style = "font-weight: 600; color: #28a745; margin-top: 10px;", "EU Member States"),
                  div(style = "margin-top: 5px;", eu_buttons)
                )
              },
              if (length(non_eu_buttons) > 0) {
                tagList(
                  h6(style = "font-weight: 600; color: #6c757d; margin-top: 10px;", "Non-EU Countries"),
                  div(style = "margin-top: 5px;", non_eu_buttons)
                )
              }
            ))
          } else {
            # Fallback when no country data available
            return(div(
              p(style = "color: #666;",
                i18n$t("modules.isa.ai_assistant.skip_this_question"))
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
          # P3: Request source attribution for KB badge display
          suggestion_result <- get_context_suggestions(
            category = step_info$target,
            regional_sea = rv$context$regional_sea,
            ecosystem_type = rv$context$ecosystem_type,
            main_issue = rv$context$main_issue,
            countries = rv$context$countries,
            return_sources = TRUE
          )
          suggestions <- suggestion_result$suggestions
          suggestion_sources <- suggestion_result$sources

          debug_log(sprintf("Context suggestions: %d for %s", length(suggestions), step_info$target),
                    "AI ISA QUICK")

          if (length(suggestions) > 0) {
            # Limit to first 12 suggestions to avoid overwhelming UI
            display_suggestions <- if (length(suggestions) > 12) suggestions[1:12] else suggestions

            # Pre-compute element names once (was inside lapply = O(n²))
            element_names <- sapply(rv$elements[[step_info$target]], function(e) e$name)

            suggestion_buttons <- lapply(seq_along(display_suggestions), function(i) {
              suggestion_name <- display_suggestions[i]
              is_selected <- suggestion_name %in% element_names
              button_class <- if (is_selected) "quick-option selected" else "quick-option"

              # P3: Add source badge for knowledge_db, governance, and socioeconomic sourced suggestions
              source_type <- suggestion_sources[suggestion_name]
              kb_badge <- if (!is.null(source_type) && source_type == "knowledge_db") {
                tags$span(
                  class = "badge badge-info",
                  style = "font-size: 0.65em; vertical-align: super; margin-left: 3px; padding: 1px 4px;",
                  title = i18n$t("modules.isa.ai_assistant.from_knowledge_database"),
                  "KB"
                )
              } else if (!is.null(source_type) && source_type == "governance") {
                tags$span(
                  class = "badge badge-warning",
                  style = "font-size: 0.65em; vertical-align: super; margin-left: 3px; padding: 1px 4px;",
                  title = "Governance suggestion based on selected countries",
                  "GOV"
                )
              } else if (!is.null(source_type) && source_type == "socioeconomic") {
                tags$span(
                  class = "badge badge-success",
                  style = "font-size: 0.65em; vertical-align: super; margin-left: 3px; padding: 1px 4px;",
                  title = "Socioeconomic suggestion based on selected countries",
                  "SE"
                )
              } else {
                NULL
              }

              actionButton(
                inputId = session$ns(paste0("quick_opt_", i)),
                label = tagList(suggestion_name, kb_badge),
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
              # element_names already computed above
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
          debug_log(sprintf("[AI ISA] Destroying %d old observers\n", length(active_observers)))
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
            new_obs <- lapply(names(REGIONAL_SEAS), function(sea_key) {
              local({
                button_id <- paste0("regional_sea_", sea_key, "_s", current_step)
                sea_name <- REGIONAL_SEAS[[sea_key]]$name_en

                observeEvent(input[[button_id]], {
                  if (rv$current_step == current_step) {
                    debug_log(sprintf("[AI ISA] Regional sea button clicked: %s\n", sea_name))

                    # Check if user is changing regional sea after having made progress
                    previous_selection <- rv$context$regional_sea
                    is_changing_selection <- !is.null(previous_selection) && previous_selection != sea_key
                    has_made_progress <- length(rv$elements$drivers) > 0 ||
                                        length(rv$elements$activities) > 0 ||
                                        !is.null(rv$context$ecosystem_type) ||
                                        length(rv$context$main_issue) > 0

                    # Show warning if changing after making progress
                    if (is_changing_selection && has_made_progress) {
                      debug_log(sprintf("[AI ISA] Warning: User changing regional sea from %s to %s after making progress\n",
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
                        rv$context$countries <- character(0)
                        rv$context$main_issue <- character(0)
                        rv$selected_countries <- character(0)
                        rv$selected_issues <- character(0)

                        debug_log(sprintf("[AI ISA] Regional sea changed to %s, cleared dependent selections\n", sea_key))

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

            active_observers <<- c(active_observers, new_obs)

            # Observer for "Other" button - regional sea
            obs_other <- observeEvent(input[[paste0("regional_sea_other_s", current_step)]], {
              if (rv$current_step == current_step) {
                debug_log("[AI ISA] Regional sea 'Other' button clicked - showing text input\n")
                rv$show_text_input <- TRUE
              }
            }, ignoreInit = TRUE, once = TRUE)
            active_observers <<- c(active_observers, list(obs_other))
          }

          # === HANDLE ECOSYSTEM TYPE SELECTION (Step 1) ===
          else if (step_info$type == "choice_ecosystem") {
            if (!is.null(rv$context$regional_sea)) {
              ecosystem_types <- REGIONAL_SEAS[[rv$context$regional_sea]]$ecosystem_types

              # Set up observers for each ecosystem button
              new_obs <- lapply(seq_along(ecosystem_types), function(i) {
                local({
                  button_id <- paste0("ecosystem_", i, "_s", current_step)
                  ecosystem_name <- ecosystem_types[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      debug_log(sprintf("[AI ISA] Ecosystem button clicked: %s\n", ecosystem_name))
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

              active_observers <<- c(active_observers, new_obs)

              # Observer for "Other" button - ecosystem
              obs_other <- observeEvent(input[[paste0("ecosystem_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  debug_log("[AI ISA] Ecosystem 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)
              active_observers <<- c(active_observers, list(obs_other))
            }
          }

          # === HANDLE COUNTRY SELECTION - MULTIPLE (Step 2) ===
          else if (step_info$type == "country_multiple") {
            countries_list <- tryCatch(
              get_countries_for_sea(rv$context$regional_sea),
              error = function(e) {
                debug_log(sprintf("get_countries_for_sea error in observer: %s", e$message), "AI ISA")
                NULL
              }
            )

            if (!is.null(countries_list) && length(countries_list) > 0) {
              # Set up observers for each country toggle button
              new_obs <- lapply(countries_list, function(country) {
                local({
                  country_code <- country$code
                  country_name <- country$name
                  button_id <- paste0("country_", country_code, "_s", current_step)

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      # Toggle selection
                      if (country_code %in% rv$selected_countries) {
                        debug_log(sprintf("[AI ISA] Country deselected: %s\n", country_name))
                        rv$selected_countries <- setdiff(rv$selected_countries, country_code)
                      } else {
                        debug_log(sprintf("[AI ISA] Country selected: %s\n", country_name))
                        rv$selected_countries <- c(rv$selected_countries, country_code)
                      }

                      # Force UI re-render
                      rv$render_counter <- (rv$render_counter %||% 0) + 1
                    }
                  }, ignoreInit = TRUE)
                })
              })

              active_observers <<- c(active_observers, new_obs)

              # Observer for "Select All" button
              obs_select_all <- observeEvent(input[[paste0("country_select_all_s", current_step)]], {
                if (rv$current_step == current_step) {
                  debug_log("[AI ISA] Country 'Select All' clicked\n")
                  all_codes <- sapply(countries_list, function(c) c$code)
                  rv$selected_countries <- all_codes
                  rv$render_counter <- (rv$render_counter %||% 0) + 1
                }
              }, ignoreInit = TRUE)
              active_observers <<- c(active_observers, list(obs_select_all))

              # Observer for "Clear All" button
              obs_clear_all <- observeEvent(input[[paste0("country_clear_all_s", current_step)]], {
                if (rv$current_step == current_step) {
                  debug_log("[AI ISA] Country 'Clear All' clicked\n")
                  rv$selected_countries <- character(0)
                  rv$render_counter <- (rv$render_counter %||% 0) + 1
                }
              }, ignoreInit = TRUE)
              active_observers <<- c(active_observers, list(obs_clear_all))
            }
          }

          # === HANDLE MAIN ISSUE SELECTION - MULTIPLE (Step 3) ===
          else if (step_info$type == "choice_with_custom_multiple") {
            if (!is.null(rv$context$regional_sea)) {
              issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues

              # Set up observers for each issue button (toggle selection)
              new_obs <- lapply(seq_along(issues), function(i) {
                local({
                  button_id <- paste0("issue_", i, "_s", current_step)
                  issue_name <- issues[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      # Toggle selection
                      if (issue_name %in% rv$selected_issues) {
                        # Deselect
                        debug_log(sprintf("[AI ISA] Issue deselected: %s\n", issue_name))
                        rv$selected_issues <- setdiff(rv$selected_issues, issue_name)
                      } else {
                        # Select
                        debug_log(sprintf("[AI ISA] Issue selected: %s\n", issue_name))
                        rv$selected_issues <- c(rv$selected_issues, issue_name)
                      }

                      # Force UI re-render by incrementing render counter
                      rv$render_counter <- (rv$render_counter %||% 0) + 1
                    }
                  }, ignoreInit = TRUE)
                })
              })

              active_observers <<- c(active_observers, new_obs)

              # Observer for "Other" button - issue
              obs_other <- observeEvent(input[[paste0("issue_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  debug_log("[AI ISA] Issue 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)
              active_observers <<- c(active_observers, list(obs_other))

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
              new_obs <- lapply(seq_along(issues), function(i) {
                local({
                  button_id <- paste0("issue_", i, "_s", current_step)
                  issue_name <- issues[i]

                  observeEvent(input[[button_id]], {
                    if (rv$current_step == current_step) {
                      debug_log(sprintf("[AI ISA] Issue button clicked: %s\n", issue_name))
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

              active_observers <<- c(active_observers, new_obs)

              # Observer for "Other" button - issue
              obs_other <- observeEvent(input[[paste0("issue_other_s", current_step)]], {
                if (rv$current_step == current_step) {
                  debug_log("[AI ISA] Issue 'Other' button clicked - showing text input\n")
                  rv$show_text_input <- TRUE
                }
              }, ignoreInit = TRUE, once = TRUE)
              active_observers <<- c(active_observers, list(obs_other))
            }
          }

          # === HANDLE STATIC EXAMPLES (old approach) ===
          else if (!is.null(step_info$examples)) {
            # Set up observers for this step's buttons
            new_obs <- lapply(seq_along(step_info$examples), function(i) {
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
            active_observers <<- c(active_observers, new_obs)
          }
          # === HANDLE CONTEXT-AWARE EXAMPLES (new approach) ===
          else if (!is.null(step_info$use_context_examples) && step_info$use_context_examples) {
            # Get context-aware suggestions
            suggestions <- get_context_suggestions(
              category = step_info$target,
              regional_sea = rv$context$regional_sea,
              ecosystem_type = rv$context$ecosystem_type,
              main_issue = rv$context$main_issue,
              countries = rv$context$countries
            )

            if (length(suggestions) > 0) {
              # Limit to first 12 suggestions to match UI
              display_suggestions <- if (length(suggestions) > 12) suggestions[1:12] else suggestions

              # Set up observers for context-aware suggestion buttons (toggle selection)
              new_obs <- lapply(seq_along(display_suggestions), function(i) {
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
                        debug_log(sprintf("[AI ISA QUICK] Removing %s from %s\n", suggestion_text, step_info$target))
                        rv$elements[[step_info$target]] <- Filter(
                          function(e) e$name != suggestion_text,
                          rv$elements[[step_info$target]]
                        )
                      } else {
                        # Check max elements limit from level config (configurable per category)
                        user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"
                        current_count <- length(rv$elements[[step_info$target]])
                        max_elements <- tryCatch({
                          config <- get_level_config(user_level)
                          cfg_max <- config$max_elements_per_category
                          if (is.null(cfg_max) || cfg_max == 0L) 0L else cfg_max
                        }, error = function(e) {
                          if (!is.null(beginner_max_elements_reactive)) beginner_max_elements_reactive() else BEGINNER_MAX_ELEMENTS_DEFAULT
                        })

                        if (max_elements > 0L && current_count >= max_elements) {
                          # Block adding 4th element, show warning
                          showNotification(
                            i18n$t("modules.isa.ai_assistant.max_elements_warning"),
                            type = "warning",
                            duration = 8
                          )
                          # Add AI message about the limit
                          rv$conversation <- c(rv$conversation, list(
                            list(type = "ai", message = i18n$t("modules.isa.ai_assistant.max_elements_warning"), timestamp = Sys.time())
                          ))
                        } else {
                          # Add (select)
                          debug_log(sprintf("[AI ISA QUICK] Adding %s to %s\n", suggestion_text, step_info$target))
                          new_element <- list(
                            name = suggestion_text,
                            description = "",
                            timestamp = Sys.time()
                          )
                          rv$elements[[step_info$target]] <- c(rv$elements[[step_info$target]], list(new_element))
                        }
                      }

                      # Force UI re-render to update button classes
                      rv$render_counter <- (rv$render_counter %||% 0) + 1
                    }
                  }, ignoreInit = TRUE)
                })
              })
              active_observers <<- c(active_observers, new_obs)
            }

            # Observer for "Other" button - DAPSIWRM elements
            obs_other <- observeEvent(input[["dapsiwrm_other"]], {
              if (rv$current_step == current_step) {
                debug_log("[AI ISA] DAPSIWRM 'Other' button clicked - showing text input\n")
                rv$show_text_input <- TRUE
              }
            }, ignoreInit = TRUE, once = TRUE)
            active_observers <<- c(active_observers, list(obs_other))
          }
        }
      }
    })

    # Handle skip / continue
    observeEvent(input$skip_question, {
      # If on main_issue step with multiple selections, save them before moving on
      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]

        if (step_info$target == "countries") {
          # Save selected countries to context
          rv$context$countries <- rv$selected_countries

          if (length(rv$selected_countries) > 0) {
            # Look up country names for the confirmation message
            countries_list <- tryCatch(
              get_countries_for_sea(rv$context$regional_sea),
              error = function(e) NULL
            )
            country_names <- if (!is.null(countries_list)) {
              sapply(countries_list[sapply(countries_list, function(c) c$code %in% rv$selected_countries)],
                     function(c) c$name)
            } else {
              rv$selected_countries
            }
            country_list_str <- paste(country_names, collapse = ", ")

            ai_response <- paste0(
              country_list_str, " - ",
              i18n$t("modules.isa.ai_assistant.country_confirmed")
            )
            rv$conversation <- c(rv$conversation, list(
              list(type = "ai", message = ai_response, timestamp = Sys.time())
            ))
          }
        }

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

        # BEGINNER MODE: Check minimum elements for DAPSIWRM categories
        # Only enforce minimum 2 elements for element entry steps (type = "multiple")
        if (step_info$type == "multiple") {
          user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"
          element_count <- length(rv$elements[[step_info$target]])

          if (user_level == "beginner" && element_count == 1) {
            # Show warning and prevent moving forward
            showNotification(
              i18n$t("modules.isa.ai_assistant.need_more_elements"),
              type = "warning",
              duration = 8
            )
            # Add AI message about needing more elements
            rv$conversation <- c(rv$conversation, list(
              list(type = "ai", message = i18n$t("modules.isa.ai_assistant.need_more_elements"), timestamp = Sys.time())
            ))
            return()  # Don't proceed
          }

          # P1: Warn when a DAPSIWRM category has 0 elements
          if (element_count == 0) {
            # Map category targets to human-readable labels and consequences
            category_label <- switch(step_info$target,
              "drivers"    = i18n$t("modules.isa.ai_assistant.drivers_societal_needs"),
              "activities" = i18n$t("modules.isa.ai_assistant.activities_human_actions"),
              "pressures"  = i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors"),
              "states"     = i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects"),
              "impacts"    = i18n$t("modules.isa.ai_assistant.impacts_effects_on_ecosystem_services"),
              "welfare"    = i18n$t("modules.isa.ai_assistant.welfare_human_well_being_effects"),
              "responses"  = i18n$t("modules.isa.ai_assistant.response_measures_management_policy"),
              step_info$target
            )

            # Map to downstream consequence
            consequence <- switch(step_info$target,
              "drivers"    = i18n$t("modules.isa.ai_assistant.no_drivers_activities_connections"),
              "activities" = i18n$t("modules.isa.ai_assistant.no_activities_pressures_connections"),
              "pressures"  = i18n$t("modules.isa.ai_assistant.no_pressures_state_connections"),
              "states"     = i18n$t("modules.isa.ai_assistant.no_state_impacts_connections"),
              "impacts"    = i18n$t("modules.isa.ai_assistant.no_impacts_welfare_connections"),
              "welfare"    = i18n$t("modules.isa.ai_assistant.no_welfare_feedback_connections"),
              "responses"  = i18n$t("modules.isa.ai_assistant.no_response_connections"),
              i18n$t("modules.isa.ai_assistant.no_connections_for_category")
            )

            warning_msg <- paste0(
              i18n$t("modules.isa.ai_assistant.no_elements_warning_prefix"), " ",
              category_label, " ",
              i18n$t("modules.isa.ai_assistant.no_elements_warning_suffix"), " ",
              consequence, " ",
              i18n$t("modules.isa.ai_assistant.are_you_sure_continue")
            )

            # Show warning notification
            showNotification(warning_msg, type = "warning", duration = 10)

            # Add AI warning message to conversation
            rv$conversation <- c(rv$conversation, list(
              list(type = "ai", message = warning_msg, timestamp = Sys.time())
            ))

            # Note: We still proceed (don't return) - this is a warning, not a block
          }

          # P4: Info note when fewer than 2 elements added
          if (element_count > 0 && element_count < 2) {
            category_label <- switch(step_info$target,
              "drivers"    = i18n$t("modules.isa.ai_assistant.drivers_societal_needs"),
              "activities" = i18n$t("modules.isa.ai_assistant.activities_human_actions"),
              "pressures"  = i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors"),
              "states"     = i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects"),
              "impacts"    = i18n$t("modules.isa.ai_assistant.impacts_effects_on_ecosystem_services"),
              "welfare"    = i18n$t("modules.isa.ai_assistant.welfare_human_well_being_effects"),
              "responses"  = i18n$t("modules.isa.ai_assistant.response_measures_management_policy"),
              step_info$target
            )

            few_elements_msg <- paste0(
              i18n$t("modules.isa.ai_assistant.only"), " ", element_count, " ",
              category_label, " ",
              i18n$t("modules.isa.ai_assistant.added_consider_more")
            )

            showNotification(few_elements_msg, type = "message", duration = 6)
          }
        }
      }

      move_to_next_step()
    })

    # Handle go back button
    observeEvent(input$go_back, {
      move_to_previous_step()
    })

    # Process answer function
    # NOTE: Equivalent function extracted to modules/ai_isa/answer_processor.R
    # Future refactoring can replace this with: process_answer(answer, step_info, rv, i18n, move_to_next_step, REGIONAL_SEAS)
    process_answer <- function(answer) {
      debug_log(sprintf("[AI ISA PROCESS] process_answer called with: '%s'\n", answer))

      if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
        step_info <- QUESTION_FLOW[[rv$current_step + 1]]
        debug_log(sprintf("[AI ISA PROCESS] Current step %d, type: %s, target: %s\n",
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
            debug_log(sprintf("[AI ISA] Regional sea set to: %s (text input)\n", REGIONAL_SEAS[[matched_sea]]$name_en))

            ai_response <- paste0(
              i18n$t("modules.isa.ai_assistant.great_you_selected"), " ", REGIONAL_SEAS[[matched_sea]]$name_i18n, ". ",
              i18n$t("modules.isa.this_will_help_me_suggest_relevant_activities_and_")
            )
          } else {
            # Couldn't match, use "other"
            rv$context$regional_sea <- "other"
            debug_log("[AI ISA] Regional sea set to: other (text input not matched)\n")
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
          debug_log(sprintf("[AI ISA] Ecosystem type set to: %s (text input)\n", answer))

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

        # Countries (text input fallback - not typical, but handle gracefully)
        else if (step_info$target == "countries") {
          # Skip through - countries are selected via toggle buttons
          move_to_next_step()
          return()
        }

        # Main issue (text input)
        else if (step_info$target == "main_issue") {
          rv$context$main_issue <- answer
          debug_log(sprintf("[AI ISA] Main issue set to: %s\n", answer))

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
          debug_log(sprintf("[AI ISA PROCESS] Adding element to %s\n", step_info$target))

          # Check max elements limit from level config (configurable per category) before adding
          user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"
          current_count <- length(rv$elements[[step_info$target]])
          max_elements <- tryCatch({
            config <- get_level_config(user_level)
            cfg_max <- config$max_elements_per_category
            if (is.null(cfg_max) || cfg_max == 0L) 0L else cfg_max
          }, error = function(e) {
            if (!is.null(beginner_max_elements_reactive)) beginner_max_elements_reactive() else BEGINNER_MAX_ELEMENTS_DEFAULT
          })

          if (max_elements > 0L && current_count >= max_elements) {
            # Block adding 4th element, show warning
            showNotification(
              i18n$t("modules.isa.ai_assistant.max_elements_warning"),
              type = "warning",
              duration = 8
            )
            # Add AI message about the limit
            rv$conversation <- c(rv$conversation, list(
              list(type = "ai", message = i18n$t("modules.isa.ai_assistant.max_elements_warning"), timestamp = Sys.time())
            ))
            # Hide text input
            rv$show_text_input <- FALSE
            return()  # Don't add the element
          }

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
          debug_log(sprintf("[AI ISA PROCESS] Element added! Total %s: %d\n", step_info$target, element_count))

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

    # ========================================================================
    # CONNECTION GENERATION FUNCTIONS
    # ========================================================================
    # All connection generation functions (detect_polarity, calculate_relevance,
    # generate_smart_connections, convert_matrices_to_connections, generate_connections)
    # are defined in modules/ai_isa/connection_generator.R (sourced at module load time)

    # ========== STEP NAVIGATION ==========
    # move_to_next_step and move_to_previous_step extracted to modules/ai_isa/step_navigation.R
    nav_fns <- setup_step_navigation(rv, session, i18n, QUESTION_FLOW)
    move_to_next_step <- nav_fns$move_to_next_step
    move_to_previous_step <- nav_fns$move_to_previous_step

    # ========== UI RENDERERS ==========
    # Breadcrumb, progress, counts, diagram, and connection types extracted to modules/ai_isa/ui_renderers.R
    setup_ui_renderers(input, output, session, rv, i18n, QUESTION_FLOW)

    # ========== ACTION HANDLERS ==========
    # Preview, save, start over, and element link handlers extracted to modules/ai_isa/action_handlers.R
    setup_action_handlers(input, session, rv, i18n, project_data_reactive, event_bus)

    # ========== TEMPLATE HANDLERS ==========
    # Template loading handlers extracted to modules/ai_isa/template_handlers.R
    setup_template_handlers(input, session, rv, i18n)

    # Auto-save when ISA framework generation is complete (step 11)
    # This ensures auto-save module can recover the data without requiring manual save
    # Uses isolate() and a flag to prevent infinite loop
    # NOTE: Element-to-ISA conversion delegated to save_to_project_format()
    # in modules/ai_isa/data_persistence.R
    observe({
      debug_log(sprintf("[AI ISA SAVE] Observer fired - current_step: %s\n",
                  if(is.null(rv$current_step)) "NULL" else rv$current_step))

      # Only trigger when step reaches 11 (connection review)
      if (!is.null(rv$current_step) && rv$current_step == 11) {
        debug_log(sprintf("[AI ISA SAVE] Step is 11, checking auto_saved_step_10 flag: %s\n",
                    isTRUE(rv$auto_saved_step_10)))

        # Use isolate() to prevent reactive loop when updating project_data_reactive
        isolate({
          # Check if auto-save is enabled
          if (!is.null(autosave_enabled_reactive) && !autosave_enabled_reactive()) {
            debug_log("[AI ISA SAVE] Skipping auto-save - auto-save is disabled in settings\n")
            return()
          }

          # Check if we've already auto-saved (prevent duplicate saves)
          if (!isTRUE(rv$auto_saved_step_10)) {
            # Check if data was loaded from template - if so, skip auto-save
            current_data <- project_data_reactive()
            if (!is.null(current_data$data$metadata$source) &&
                current_data$data$metadata$source %in% c("template_direct_load", "template_reviewed_load")) {
              debug_log("[AI ISA SAVE] Skipping auto-save - data is from template load\n")
              return()
            }

            total_elements <- sum(
              length(rv$elements$drivers), length(rv$elements$activities),
              length(rv$elements$pressures), length(rv$elements$states),
              length(rv$elements$impacts), length(rv$elements$welfare),
              length(rv$elements$responses)
            )

            debug_log(sprintf("[AI ISA SAVE] Total elements: %d (D:%d A:%d P:%d S:%d I:%d W:%d R/M:%d)\n",
                        total_elements,
                        length(rv$elements$drivers), length(rv$elements$activities),
                        length(rv$elements$pressures), length(rv$elements$states),
                        length(rv$elements$impacts), length(rv$elements$welfare),
                        length(rv$elements$responses)))

            if (total_elements > 0) {
              debug_log("[AI ISA] Auto-saving generated ISA framework to project data\n")

              # Set flag to prevent re-triggering
              rv$auto_saved_step_10 <- TRUE

              tryCatch({
                current_data <- project_data_reactive()

                # Use shared conversion function (modules/ai_isa/data_persistence.R)
                current_data <- save_to_project_format(rv, current_data, CONFIDENCE_DEFAULT)

                # Update project_data_reactive
                project_data_reactive(current_data)

                # Emit ISA change for CLD regeneration
                if (!is.null(event_bus)) event_bus$emit_isa_change("ai_isa_autosave")

                debug_log(sprintf("[AI ISA] Auto-saved %d total elements to project_data_reactive\n", total_elements))
              }, error = function(e) {
                debug_log(sprintf("[AI ISA] Auto-save error: %s\n", e$message))
              })
            }
          }
        })
      }
    })

    # Handle manual save to ISA
    # NOTE: Element-to-ISA conversion delegated to save_to_project_format()
    # in modules/ai_isa/data_persistence.R
    observeEvent(input$save_to_isa, {
      debug_log("[AI ISA] Manual save to ISA clicked\n")

      # Check if auto-save already saved
      if (isTRUE(rv$auto_saved_step_10)) {
        showNotification(
          i18n$t("Your work is already saved automatically. Navigate to 'ISA Data Entry' to see your elements."),
          type = "message",
          duration = 5
        )
        debug_log("[AI ISA] Auto-save already completed, no manual save needed\n")
        return()
      }

      tryCatch({
        current_data <- project_data_reactive()
        debug_log("[AI ISA] Retrieved project data for manual save\n")

        # Use shared conversion function (modules/ai_isa/data_persistence.R)
        current_data <- save_to_project_format(rv, current_data, CONFIDENCE_DEFAULT)

        # Add metadata
        current_data$data$isa_data$metadata <- list(
          project_name = rv$context$project_name %||% "Unnamed Project",
          location = rv$context$location %||% "",
          ecosystem_type = rv$context$ecosystem_type %||% "",
          main_issue = rv$context$main_issue %||% "",
          created_by = "AI ISA Assistant",
          created_at = Sys.time()
        )

        # Update the reactive value
        debug_log("[AI ISA] Updating project_data reactive\n")
        project_data_reactive(current_data)

        # Emit ISA change for CLD regeneration
        if (!is.null(event_bus)) event_bus$emit_isa_change("ai_isa_manual_save")

        debug_log("[AI ISA] Project data updated successfully\n")

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

        n_connections <- length(rv$approved_connections)
        debug_log(sprintf("[AI ISA] Save completed: %d elements, %d connections\n", total_elements, n_connections))

        showNotification(
          paste0(i18n$t("modules.isa.ai_assistant.model_saved_successfully"), " ", total_elements, " ", i18n$t("modules.isa.ai_assistant.elements_and"), " ",
                 n_connections, " ", i18n$t("modules.isa.ai_assistant.connections_transferred_to_isa_data_entry")),
          type = "message",
          duration = 5
        )

      }, error = function(e) {
        debug_log(sprintf("[AI ISA ERROR] Save failed: %s\n", e$message))
        debug_log(sprintf("[AI ISA ERROR] Call stack: %s\n", paste(sys.calls(), collapse = "\n")))

        showNotification(
          format_user_error(e, i18n = i18n, context = "saving AI model to ISA"),
          type = "error",
          duration = 10
        )
      })
    })

  })
}
