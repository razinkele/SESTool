# modules/ai_isa/ui_components.R
# AI ISA UI Components Module
# Purpose: All visual components, styling, and rendering logic
#
# This module contains the UI definition, CSS styling, JavaScript handlers,
# and all output rendering functions for the AI ISA Assistant interface.
#
# Author: Refactored from ai_isa_assistant_module.R
# Date: 2026-01-04
# Dependencies: shiny, shinyjs, bs4Dash, i18n, connection_review_tabbed module

# Libraries loaded in global.R: shiny, shinyjs, bs4Dash

# ==============================================================================
# CSS STYLING
# ==============================================================================

#' Get AI ISA Custom CSS
#'
#' Returns the CSS styling for the AI ISA Assistant interface.
#'
#' @return HTML tags object containing CSS styles
#' @export
get_ai_isa_css <- function() {
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
  "))
}

# ==============================================================================
# JAVASCRIPT HANDLERS
# ==============================================================================

#' Get AI ISA JavaScript Handlers
#'
#' Returns the JavaScript code for localStorage session management.
#'
#' @return HTML script tag containing JavaScript handlers
#' @export
get_ai_isa_js <- function() {
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
}

# ==============================================================================
# MAIN UI FUNCTION
# ==============================================================================

# NOTE: ai_isa_assistant_ui() is defined in ai_isa_assistant_module.R (the parent module).
# This file provides helper functions: setup_ui_outputs, highlight_keywords, get_ai_isa_css, get_ai_isa_js

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

#' Highlight DAPSI(W)R(M) Keywords in Text
#'
#' Wraps DAPSI(W)R(M) framework keywords in HTML spans for visual emphasis.
#'
#' @param text Character string containing text to highlight
#'
#' @return HTML object with highlighted keywords
#'
#' @details
#' Highlights the keywords: DRIVERS, ACTIVITIES, PRESSURES, STATE, IMPACTS,
#' WELFARE, RESPONSES with bold purple styling.
#'
#' @examples
#' \dontrun{
#' highlight_keywords("What DRIVERS lead to fishing ACTIVITIES?")
#' # Returns HTML with DRIVERS and ACTIVITIES highlighted
#' }
#'
#' @export
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

# ==============================================================================
# OUTPUT RENDERERS
# ==============================================================================

#' Setup UI Output Renderers
#'
#' Initializes all reactive output rendering for the AI ISA interface.
#' This function should be called from the server module to set up:
#' - Conversation display
#' - Input area (dynamic based on step)
#' - Sidebar panel (progress, summary)
#'
#' @param output Shiny output object
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#' @param QUESTION_FLOW List defining the wizard steps
#'
#' @return NULL (sets up reactive outputs as side effect)
#'
#' @details
#' Sets up the following outputs:
#' - output$conversation: Current AI question
#' - output$input_area: Dynamic input based on step type
#' - output$sidebar_panel: Progress indicator and element summary
#'
#' @export
setup_ui_outputs <- function(output, input, session, rv, i18n, QUESTION_FLOW) {
  ns <- session$ns

  # Render conversation - only show current question
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
    # Force re-render when render_counter changes
    counter_val <- rv$render_counter

    input_area_exec_count <<- input_area_exec_count + 1

    debug_log(sprintf("EXECUTION #%d | step: %d | show_text_input: %s | render_counter: %d",
                      input_area_exec_count, rv$current_step, rv$show_text_input, counter_val),
              "AI ISA INPUT_AREA")

    if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
      step_info <- QUESTION_FLOW[[rv$current_step + 1]]

      if (step_info$type == "connection_review") {
        # Connection review interface using tabbed module
        wellPanel(
          h4(icon("link"), " ", i18n$t("modules.isa.ai_assistant.review_suggested_connections")),
          p(i18n$t("modules.isa.approve_or_reject_each_connection_organized_by_fra")),
          connection_review_tabbed_ui(ns("conn_review"), i18n),
          br(),
          fluidRow(
            column(6,
              actionButton(ns("approve_all_connections"), i18n$t("modules.isa.ai_assistant.approve_all"),
                          icon = icon("check-circle"),
                          class = "btn-success btn-block")
            ),
            column(6,
              actionButton(ns("finish_connections"), i18n$t("modules.isa.ai_assistant.finish_continue"),
                          icon = icon("arrow-right"),
                          class = "btn-primary btn-block")
            )
          )
        )
      } else {
        # Standard input interface
        show_input <- rv$show_text_input

        wellPanel(
          if (show_input) {
            tagList(
              textAreaInput(ns("user_input"),
                           label = NULL,
                           placeholder = i18n$t("modules.isa.ai_assistant.type_your_answer_here"),
                           rows = 3,
                           width = "100%"),
              actionButton(ns("submit_answer"), i18n$t("modules.isa.ai_assistant.submit_answer"),
                          icon = icon("paper-plane"),
                          class = "btn-primary btn-block"),
              br()
            )
          },
          uiOutput(ns("quick_options")),
          br(),
          # Always show continue button for "multiple" type steps
          uiOutput(ns("continue_button"))
        )
      }
    }
  })

  # Render sidebar panel with progress and summary
  output$sidebar_panel <- renderUI({
    bs4Card(
      title = i18n$t("modules.isa.ai_assistant.your_ses_model_progress"),
      status = "info",
      solidHeader = TRUE,
      width = 12,
      collapsible = TRUE,

      # AI badge
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

      # Element summary
      uiOutput(ns("elements_summary")),

      hr(),

      # Connection summary
      uiOutput(ns("connections_summary"))
    )
  })
}

# ==============================================================================
# MODULE INITIALIZATION MESSAGE
# ==============================================================================

message("[INFO] AI ISA UI Components module loaded successfully")
message("       Available functions: setup_ui_outputs, highlight_keywords, get_ai_isa_css, get_ai_isa_js")
