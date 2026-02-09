# modules/graphical_ses_creator_module.R
# Graphical SES Creator Module
# AI-powered step-by-step network building with context wizard and ghost nodes

#' Graphical SES Creator UI
#'
#' Creates the UI for the graphical SES creator module
#'
#' @param id Module namespace ID
#' @param i18n Internationalization object
#' @return Shiny UI element
#' @export
graphical_ses_creator_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    useShinyjs(),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        /* Graphical SES Creator Styles */
        .graphical-ses-container {
          display: flex;
          height: calc(100vh - 150px);
          gap: 15px;
          padding: 15px;
        }

        .context-wizard-panel {
          width: 300px;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          padding: 20px;
          overflow-y: auto;
          transition: width 0.3s ease, margin-left 0.3s ease;
        }

        .context-wizard-panel.collapsed {
          width: 50px;
          padding: 10px 5px;
        }

        .panel-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 20px;
          border-bottom: 2px solid #e0e0e0;
          padding-bottom: 10px;
        }

        .panel-header h4 {
          margin: 0;
          font-size: 16px;
          font-weight: 600;
          color: #333;
        }

        .wizard-step {
          margin-bottom: 20px;
          padding: 15px;
          background: #f8f9fa;
          border-radius: 6px;
          border-left: 4px solid #ddd;
        }

        .wizard-step.active {
          border-left-color: #4CAF50;
          background: #e8f5e9;
        }

        .wizard-step.completed {
          border-left-color: #2196F3;
          background: #e3f2fd;
        }

        .wizard-step-number {
          display: inline-block;
          width: 24px;
          height: 24px;
          line-height: 24px;
          text-align: center;
          background: #ddd;
          color: white;
          border-radius: 50%;
          font-weight: bold;
          font-size: 12px;
          margin-right: 8px;
        }

        .wizard-step.active .wizard-step-number {
          background: #4CAF50;
        }

        .wizard-step.completed .wizard-step-number {
          background: #2196F3;
        }

        .wizard-step-title {
          font-weight: 600;
          color: #555;
          margin-bottom: 10px;
        }

        .classification-result {
          background: white;
          padding: 12px;
          border-radius: 6px;
          margin-bottom: 10px;
          border: 2px solid #e0e0e0;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .classification-result:hover {
          border-color: #4CAF50;
          transform: translateX(4px);
        }

        .classification-result.selected {
          border-color: #4CAF50;
          background: #e8f5e9;
        }

        .classification-result .confidence {
          float: right;
          font-size: 11px;
          color: #666;
        }

        .classification-result .type-name {
          font-weight: 600;
          color: #333;
          margin-bottom: 4px;
        }

        .classification-result .reasoning {
          font-size: 12px;
          color: #666;
          font-style: italic;
        }

        .graph-canvas-panel {
          flex: 1;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          display: flex;
          flex-direction: column;
        }

        .canvas-header {
          padding: 15px 20px;
          border-bottom: 1px solid #e0e0e0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .canvas-header h4 {
          margin: 0;
          font-size: 16px;
          font-weight: 600;
          color: #333;
        }

        .canvas-controls {
          display: flex;
          gap: 8px;
        }

        .canvas-controls .btn {
          padding: 6px 12px;
          font-size: 13px;
        }

        .graph-canvas {
          flex: 1;
          position: relative;
          background: #fafafa;
        }

        .network-stats {
          padding: 10px 20px;
          background: #f5f5f5;
          border-top: 1px solid #e0e0e0;
          font-size: 13px;
          color: #666;
        }

        .network-stats .stat {
          display: inline-block;
          margin-right: 20px;
        }

        .network-stats .stat-label {
          font-weight: 600;
          color: #333;
        }

        .details-expansion-panel {
          width: 250px;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          padding: 20px;
          overflow-y: auto;
        }

        .node-details {
          padding: 15px;
          background: #f8f9fa;
          border-radius: 6px;
          margin-bottom: 15px;
        }

        .node-details .node-name {
          font-weight: 600;
          font-size: 15px;
          color: #333;
          margin-bottom: 8px;
        }

        .node-details .node-type {
          font-size: 12px;
          color: #666;
          margin-bottom: 12px;
        }

        .node-actions {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .ghost-suggestion {
          background: #fff3e0;
          border: 2px solid #ff9800;
          border-radius: 6px;
          padding: 12px;
          margin-bottom: 10px;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .ghost-suggestion:hover {
          background: #ffe0b2;
          transform: translateX(4px);
        }

        .ghost-suggestion .suggestion-name {
          font-weight: 600;
          color: #e65100;
          margin-bottom: 4px;
        }

        .ghost-suggestion .suggestion-type {
          font-size: 11px;
          color: #666;
          margin-bottom: 6px;
        }

        .ghost-suggestion .suggestion-connection {
          font-size: 12px;
          color: #555;
        }

        .action-bar {
          padding: 15px 20px;
          background: white;
          border-top: 1px solid #e0e0e0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .empty-state {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100%;
          color: #999;
          text-align: center;
          padding: 40px;
        }

        .empty-state .empty-icon {
          font-size: 64px;
          margin-bottom: 20px;
          opacity: 0.3;
        }

        .empty-state .empty-text {
          font-size: 16px;
          font-weight: 600;
          margin-bottom: 10px;
        }

        .empty-state .empty-hint {
          font-size: 13px;
          color: #bbb;
        }
      "))
    ),

    # Main layout
    div(class = "graphical-ses-container",

      # LEFT PANEL: Context Wizard
      div(id = ns("context_panel"), class = "context-wizard-panel",
        div(class = "panel-header",
          h4(icon("compass"), " ", i18n$t("modules.graphical_ses_creator.context_wizard")),
          actionButton(ns("toggle_context"), label = "", icon = icon("chevron-left"),
                      class = "btn-sm", style = "border: none; background: none;")
        ),

        # Wizard content
        uiOutput(ns("wizard_content"))
      ),

      # CENTER PANEL: Graph Canvas
      div(class = "graph-canvas-panel",
        div(class = "canvas-header",
          h4(icon("project-diagram"), " ", i18n$t("modules.graphical_ses_creator.ses_network")),
          div(class = "canvas-controls",
            # ML Status Badge
            if (exists("ML_AVAILABLE") && ML_AVAILABLE) {
              tags$span(
                style = "background: #4CAF50; color: white; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: 600; margin-right: 10px;",
                icon("brain"), " ", i18n$t("modules.graphical_ses_creator.ml_enhanced")
              )
            } else {
              tags$span(
                style = "background: #9E9E9E; color: white; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: 600; margin-right: 10px;",
                icon("lightbulb"), " ", i18n$t("modules.graphical_ses_creator.rule_based_ai")
              )
            },
            actionButton(ns("zoom_fit"), label = "", icon = icon("expand"), title = i18n$t("modules.graphical_ses_creator.fit_to_view"),
                        class = "btn-sm btn-default"),
            actionButton(ns("undo"), label = "", icon = icon("undo"), title = i18n$t("modules.graphical_ses_creator.undo"),
                        class = "btn-sm btn-default"),
            actionButton(ns("clear_ghosts"), label = "", icon = icon("ghost"), title = i18n$t("modules.graphical_ses_creator.clear_suggestions"),
                        class = "btn-sm btn-warning"),
            actionButton(ns("save_network"), label = "", icon = icon("save"), title = i18n$t("modules.graphical_ses_creator.save"),
                        class = "btn-sm btn-primary")
          )
        ),

        div(class = "graph-canvas",
          # Conditional: show empty state or network
          uiOutput(ns("canvas_content"))
        ),

        div(class = "network-stats",
          uiOutput(ns("network_statistics"))
        )
      ),

      # RIGHT PANEL: Details & Expansion
      div(class = "details-expansion-panel",
        div(class = "panel-header",
          h4(icon("info-circle"), " ", i18n$t("modules.graphical_ses_creator.details"))
        ),

        uiOutput(ns("details_content"))
      )
    ),

    # BOTTOM ACTION BAR
    div(class = "action-bar",
      actionButton(ns("restart"), label = i18n$t("modules.graphical_ses_creator.start_over"), icon = icon("refresh"),
                  class = "btn-warning"),
      div(
        actionButton(ns("export_isa"), label = i18n$t("modules.graphical_ses_creator.export_to_isa"), icon = icon("download"),
                    class = "btn-primary"),
        actionButton(ns("continue_standard"), label = i18n$t("modules.graphical_ses_creator.continue_in_standard_entry"), icon = icon("arrow-right"),
                    class = "btn-success")
      )
    )
  )
}


#' Graphical SES Creator Server
#'
#' Server logic for the graphical SES creator module
#'
#' @param id Module namespace ID
#' @param project_data_reactive Reactive containing project data
#' @param parent_session Parent session object
#' @param i18n Internationalization object
#' @return Reactive values
#' @export
graphical_ses_creator_server <- function(id, project_data_reactive,
                                         parent_session, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    debug_log("Module initialized", "GRAPHICAL SES CREATOR")

    # Auto-collapse sidebar when this tab is active
    observe({
      # Run once on module load to collapse sidebar if on this tab
      shinyjs::runjs("
        // Check if we're on the graphical_ses_creator tab
        var currentTab = $('.sidebar-menu .treeview.active a[data-toggle=\"tab\"]').attr('data-value');

        // If on graphical SES creator tab, collapse the sidebar
        if (currentTab === 'graphical_ses_creator' || window.location.hash.includes('graphical_ses_creator')) {
          // Add sidebar-collapse class to body if not already collapsed
          if (!$('body').hasClass('sidebar-collapse')) {
            $('body').addClass('sidebar-collapse');
          }
        }

        // Listen for tab changes to auto-collapse when switching to this tab
        $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', function(e) {
          var tabValue = $(e.target).attr('data-value');
          if (tabValue === 'graphical_ses_creator') {
            // Collapse sidebar when switching to this tab
            if (!$('body').hasClass('sidebar-collapse')) {
              $('body').addClass('sidebar-collapse');
            }
          }
        });
      ")
    })

    # =========================================================================
    # REACTIVE VALUES
    # =========================================================================

    rv <- reactiveValues(
      # Wizard state
      wizard_step = 1,  # 1-6 (6 = graph building mode)
      context = list(
        regional_sea = NULL,
        ecosystem_type = NULL,
        main_issue = NULL
      ),
      classification_result = NULL,
      selected_classification_type = NULL,

      # Network state
      network_nodes = data.frame(),
      network_edges = data.frame(),
      ghost_nodes = data.frame(),
      ghost_edges = data.frame(),

      # UI state
      selected_node_id = NULL,
      expanded_node_id = NULL,
      panel_collapsed = FALSE,

      # History for undo/redo
      history = list(),
      history_index = 0,

      # Metadata
      network_created_at = NULL,
      last_modified = Sys.time()
    )

    # =========================================================================
    # HELPER FUNCTIONS
    # =========================================================================

    save_to_history <- function() {
      rv$history_index <- rv$history_index + 1

      # Truncate if not at end
      if (rv$history_index < length(rv$history)) {
        rv$history <- rv$history[1:rv$history_index]
      }

      # Save current state
      rv$history[[rv$history_index]] <- list(
        nodes = rv$network_nodes,
        edges = rv$network_edges,
        timestamp = Sys.time()
      )

      # Limit to 20 states
      if (length(rv$history) > 20) {
        rv$history <- rv$history[(length(rv$history) - 19):length(rv$history)]
        rv$history_index <- 20
      }

      debug_log(paste("Saved to history (index:", rv$history_index, ")"), "GRAPHICAL SES")
    }

    restore_from_history <- function(index) {
      if (index >= 1 && index <= length(rv$history)) {
        state <- rv$history[[index]]
        rv$network_nodes <- state$nodes
        rv$network_edges <- state$edges
        rv$last_modified <- state$timestamp

        debug_log(paste("Restored from history (index:", index, ")"), "GRAPHICAL SES")
      }
    }

    clear_ghost_nodes <- function() {
      rv$ghost_nodes <- data.frame()
      rv$ghost_edges <- data.frame()
      rv$expanded_node_id <- NULL

      debug_log("Cleared ghost nodes", "GRAPHICAL SES")
    }

    # =========================================================================
    # WIZARD CONTENT RENDERING
    # =========================================================================

    output$wizard_content <- renderUI({
      step <- rv$wizard_step

      if (rv$panel_collapsed) {
        return(div(class = "text-center",
          icon("chevron-right", style = "font-size: 24px; color: #999; cursor: pointer;"),
          onclick = "Shiny.setInputValue('graphical_ses_creator-toggle_context', Math.random());"
        ))
      }

      tagList(
        # Step 1: Regional Sea
        div(class = paste0("wizard-step", if(step == 1) " active" else if(!is.null(rv$context$regional_sea)) " completed" else ""),
          div(
            span(class = "wizard-step-number", "1"),
            span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.regional_sea"))
          ),
          if (step >= 1) {
            selectInput(ns("regional_sea"),
              label = NULL,
              choices = c("", REGIONAL_SEA_CHOICES),
              selected = rv$context$regional_sea %||% "",
              width = "100%"
            )
          } else {
            div(class = "text-muted", style = "font-size: 12px;", i18n$t("modules.graphical_ses_creator.complete_previous_steps"))
          }
        ),

        # Step 2: Ecosystem Type
        div(class = paste0("wizard-step", if(step == 2) " active" else if(!is.null(rv$context$ecosystem_type)) " completed" else ""),
          div(
            span(class = "wizard-step-number", "2"),
            span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.ecosystem_type"))
          ),
          if (step >= 2) {
            selectInput(ns("ecosystem_type"),
              label = NULL,
              choices = c("", ECOSYSTEM_TYPE_CHOICES),
              selected = rv$context$ecosystem_type %||% "",
              width = "100%"
            )
          } else {
            div(class = "text-muted", style = "font-size: 12px;", i18n$t("modules.graphical_ses_creator.complete_previous_steps"))
          }
        ),

        # Step 3: Main Issue
        div(class = paste0("wizard-step", if(step == 3) " active" else if(!is.null(rv$context$main_issue)) " completed" else ""),
          div(
            span(class = "wizard-step-number", "3"),
            span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.main_issue"))
          ),
          if (step >= 3 && step < 6) {
            tagList(
              textInput(ns("main_issue"),
                label = NULL,
                placeholder = i18n$t("modules.graphical_ses_creator.main_issue_placeholder"),
                value = rv$context$main_issue %||% "",
                width = "100%"
              ),
              div(class = "text-muted", style = "font-size: 11px; margin-top: 5px;",
                i18n$t("modules.graphical_ses_creator.main_issue_help")),
              actionButton(ns("confirm_main_issue"), i18n$t("modules.graphical_ses_creator.continue"),
                          class = "btn-primary btn-sm", style = "margin-top: 10px; width: 100%;")
            )
          } else if (step > 3) {
            div(class = "text-success", style = "font-size: 12px;",
              icon("check-circle"), " ", i18n$t("modules.graphical_ses_creator.issue_defined"), " ", rv$context$main_issue)
          } else {
            div(class = "text-muted", style = "font-size: 12px;", i18n$t("modules.graphical_ses_creator.complete_previous_steps"))
          }
        ),

        # Step 4: Prominent Element
        div(class = paste0("wizard-step", if(step == 4) " active" else if(step > 4) " completed" else ""),
          div(
            span(class = "wizard-step-number", "4"),
            span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.prominent_element"))
          ),
          if (step >= 4 && step < 6) {
            tagList(
              textInput(ns("prominent_element"),
                label = NULL,
                placeholder = i18n$t("modules.graphical_ses_creator.prominent_element_placeholder"),
                value = "",
                width = "100%"
              ),
              div(class = "text-muted", style = "font-size: 11px; margin-top: 5px;",
                i18n$t("modules.graphical_ses_creator.prominent_element_help")),
              actionButton(ns("classify_element"), i18n$t("modules.graphical_ses_creator.classify_element"),
                          class = "btn-primary btn-sm", style = "margin-top: 10px; width: 100%;")
            )
          } else if (step > 4) {
            div(class = "text-success", style = "font-size: 12px;",
              icon("check-circle"), " ", i18n$t("modules.graphical_ses_creator.element_classified"))
          } else {
            div(class = "text-muted", style = "font-size: 12px;", i18n$t("modules.graphical_ses_creator.complete_previous_steps"))
          }
        ),

        # Step 5: Classification Results
        div(class = paste0("wizard-step", if(step == 5) " active" else if(step > 5) " completed" else ""),
          div(
            span(class = "wizard-step-number", "5"),
            span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.confirm_type"))
          ),
          if (step == 5 && !is.null(rv$classification_result)) {
            tagList(
              # Show ML vs Rule-based indicator
              div(style = "font-size: 12px; margin-bottom: 10px; color: #666;",
                if (exists("ML_AVAILABLE") && ML_AVAILABLE) {
                  tagList(
                    icon("brain", style = "color: #4CAF50;"),
                    " ", i18n$t("modules.graphical_ses_creator.ml_enhanced_ai_suggests")
                  )
                } else {
                  tagList(
                    icon("lightbulb", style = "color: #FF9800;"),
                    " ", i18n$t("modules.graphical_ses_creator.rule_based_ai_suggests")
                  )
                }),

              # Primary suggestion with enhanced confidence display
              div(class = paste0("classification-result", if(is.null(rv$selected_classification_type) || rv$selected_classification_type == rv$classification_result$primary$type) " selected" else ""),
                onclick = sprintf("Shiny.setInputValue('%s', '%s');", ns("select_type"), rv$classification_result$primary$type),
                div(class = "type-name",
                  icon("star", style = "color: #ff9800;"),
                  " ", rv$classification_result$primary$type,
                  span(class = "confidence", style = paste0(
                    "background: ", if(rv$classification_result$primary$confidence >= 0.7) "#4CAF50"
                    else if(rv$classification_result$primary$confidence >= 0.4) "#FF9800"
                    else "#F44336",
                    "; color: white; padding: 2px 6px; border-radius: 3px; margin-left: 5px;"
                  ),
                    round(rv$classification_result$primary$confidence * 100), "%")
                ),
                div(class = "reasoning",
                  rv$classification_result$primary$reasoning)
              ),

              # Alternatives
              lapply(rv$classification_result$alternatives, function(alt) {
                div(class = paste0("classification-result", if(!is.null(rv$selected_classification_type) && rv$selected_classification_type == alt$type) " selected" else ""),
                  onclick = sprintf("Shiny.setInputValue('%s', '%s');", ns("select_type"), alt$type),
                  div(class = "type-name",
                    alt$type,
                    span(class = "confidence",
                      round(alt$confidence * 100), "%")
                  ),
                  div(class = "reasoning",
                    alt$reasoning)
                )
              }),

              actionButton(ns("confirm_classification"), i18n$t("modules.graphical_ses_creator.create_first_node"),
                          class = "btn-success btn-sm", style = "margin-top: 15px; width: 100%;")
            )
          } else if (step > 5) {
            div(class = "text-success", style = "font-size: 12px;",
              icon("check-circle"), " ", i18n$t("modules.graphical_ses_creator.first_node_created"))
          } else {
            div(class = "text-muted", style = "font-size: 12px;", i18n$t("modules.graphical_ses_creator.complete_previous_steps"))
          }
        ),

        # Step 6: Building Mode
        if (step == 6) {
          div(class = "wizard-step active",
            div(
              span(class = "wizard-step-number", icon("check")),
              span(class = "wizard-step-title", i18n$t("modules.graphical_ses_creator.building_network"))
            ),
            div(style = "font-size: 12px; color: #666; margin-top: 10px;",
              i18n$t("modules.graphical_ses_creator.click_nodes_to_expand"))
          )
        } else {
          NULL
        }
      )
    })

    # =========================================================================
    # WIZARD STEP OBSERVERS
    # =========================================================================

    # Step 1: Regional Sea
    observeEvent(input$regional_sea, {
      req(input$regional_sea != "")
      rv$context$regional_sea <- input$regional_sea
      rv$wizard_step <- 2
      debug_log(paste("Step 1 complete:", input$regional_sea), "GRAPHICAL SES")
    })

    # Step 2: Ecosystem Type
    observeEvent(input$ecosystem_type, {
      req(input$ecosystem_type != "")
      rv$context$ecosystem_type <- input$ecosystem_type
      rv$wizard_step <- 3
      debug_log(paste("Step 2 complete:", input$ecosystem_type), "GRAPHICAL SES")
    })

    # Step 3: Main Issue - Confirm Button
    observeEvent(input$confirm_main_issue, {
      req(input$main_issue)
      req(nchar(trimws(input$main_issue)) > 0)
      rv$context$main_issue <- trimws(input$main_issue)
      rv$wizard_step <- 4
      debug_log(paste("Step 3 complete:", input$main_issue), "GRAPHICAL SES")
    })

    # Step 4: Classify Element
    observeEvent(input$classify_element, {
      req(input$prominent_element)
      req(nchar(trimws(input$prominent_element)) > 0)

      showModal(modalDialog(
        title = i18n$t("modules.graphical_ses_creator.classifying_element"),
        div(style = "text-align: center; padding: 20px;",
          icon("spinner", "fa-spin", style = "font-size: 48px; color: #2196F3;"),
          h4(style = "margin-top: 20px;", i18n$t("modules.graphical_ses_creator.ai_analyzing_element")),
          p(i18n$t("modules.graphical_ses_creator.only_take_a_moment"))
        ),
        footer = NULL,
        easyClose = FALSE
      ))

      # Run classification (ML-enhanced if available)
      result <- tryCatch({
        # Use ML-enhanced classification if ML is available
        if (exists("ML_AVAILABLE") && ML_AVAILABLE && exists("classify_element_ml_enhanced")) {
          debug_log("Using ML-enhanced classification", "GRAPHICAL SES")
          classify_element_ml_enhanced(
            element_name = trimws(input$prominent_element),
            context = rv$context,
            reference_elements = if(nrow(rv$network_nodes) > 0) rv$network_nodes else NULL
          )
        } else {
          # Fall back to rule-based classification
          debug_log("Using rule-based classification", "GRAPHICAL SES")
          classify_element_with_ai(
            element_name = trimws(input$prominent_element),
            context = rv$context,
            i18n = i18n
          )
        }
      }, error = function(e) {
        debug_log(paste("Classification error:", e$message), "GRAPHICAL SES")
        return(NULL)
      })

      removeModal()

      if (!is.null(result)) {
        rv$classification_result <- result
        rv$selected_classification_type <- result$primary$type
        rv$wizard_step <- 5

        showNotification(
          paste(i18n$t("common.messages.element_classified_as"), result$primary$type),
          type = "message",
          duration = 3
        )
      } else {
        showNotification(
          i18n$t("common.messages.classification_failed"),
          type = "error",
          duration = 5
        )
      }
    })

    # Step 5: Select Type
    observeEvent(input$select_type, {
      rv$selected_classification_type <- input$select_type
      debug_log(paste("Type selected:", input$select_type), "GRAPHICAL SES")
    })

    # Step 5: Confirm Classification -> Create First Node
    observeEvent(input$confirm_classification, {
      req(rv$selected_classification_type)
      req(rv$classification_result)

      # Log user feedback on classification (if ML was used)
      if (exists("ML_AVAILABLE") && ML_AVAILABLE && exists("log_classification_feedback")) {
        user_action <- if (rv$selected_classification_type == rv$classification_result$primary$type) {
          "accepted"
        } else {
          "modified"
        }

        tryCatch({
          log_classification_feedback(
            element_name = rv$classification_result$element_name,
            ml_prediction = rv$classification_result,
            user_action = user_action,
            user_selected_type = rv$selected_classification_type,
            context = rv$context,
            session_id = session$token
          )
        }, error = function(e) {
          debug_log(paste("Feedback logging failed:", e$message), "GRAPHICAL SES")
        })
      }

      # Create first node
      first_node_id <- create_graphical_node_id(rv$selected_classification_type, 1)

      first_node <- data.frame(
        id = first_node_id,
        label = wrap_label(rv$classification_result$element_name, 15),
        name = rv$classification_result$element_name,
        type = rv$selected_classification_type,
        group = rv$selected_classification_type,
        level = get_dapsiwrm_level(rv$selected_classification_type),
        shape = ELEMENT_SHAPES[[rv$selected_classification_type]],
        color.background = ELEMENT_COLORS[[rv$selected_classification_type]],
        color.border = ELEMENT_COLORS[[rv$selected_classification_type]],
        color.highlight.background = ELEMENT_COLORS[[rv$selected_classification_type]],
        color.highlight.border = ELEMENT_COLORS[[rv$selected_classification_type]],
        borderWidth = SELECTED_BORDER_WIDTH,
        borderWidthSelected = SELECTED_BORDER_WIDTH + 1,
        size = LARGE_NODE_SIZE,
        font.size = FONT_SIZE_LARGE,
        font.color = "#ffffff",
        is_ghost = FALSE,
        title = paste0("<b>", htmltools::htmlEscape(rv$classification_result$element_name), "</b><br>", i18n$t("modules.graphical_ses_creator.node_tooltip_type"), " ", htmltools::htmlEscape(rv$selected_classification_type)),
        hidden = FALSE,
        physics = TRUE,
        stringsAsFactors = FALSE
      )

      rv$network_nodes <- rbind(rv$network_nodes, first_node)
      rv$network_created_at <- Sys.time()

      # Save to history
      save_to_history()

      # Transition to building mode
      rv$wizard_step <- 6

      # Auto-close the Context Wizard panel to show the network
      shinyjs::runjs(sprintf("
        var panel = document.getElementById('%s');
        if (panel && panel.style.display !== 'none') {
          panel.style.width = '0px';
          panel.style.minWidth = '0px';
          panel.style.padding = '0';
          panel.style.overflow = 'hidden';
        }
      ", ns("context_panel")))

      showNotification(
        i18n$t("common.messages.first_node_created"),
        type = "message",
        duration = 5
      )

      debug_log(paste("First node created:", first_node_id), "GRAPHICAL SES")
    })

    # =========================================================================
    # CANVAS CONTENT RENDERING
    # =========================================================================

    output$canvas_content <- renderUI({
      if (nrow(rv$network_nodes) == 0) {
        # Empty state
        div(class = "empty-state",
          div(class = "empty-icon", icon("project-diagram")),
          div(class = "empty-text", i18n$t("modules.graphical_ses_creator.no_network_yet")),
          div(class = "empty-hint",
            i18n$t("modules.graphical_ses_creator.complete_wizard_hint"))
        )
      } else {
        # Render network
        visNetworkOutput(ns("network_graph"), height = "100%")
      }
    })

    output$network_graph <- renderVisNetwork({
      req(nrow(rv$network_nodes) > 0)

      # Combine permanent and ghost nodes
      all_nodes <- rv$network_nodes
      if (nrow(rv$ghost_nodes) > 0) {
        all_nodes <- rbind(all_nodes, rv$ghost_nodes)
      }

      # Combine permanent and ghost edges
      all_edges <- rv$network_edges
      if (nrow(rv$ghost_edges) > 0) {
        all_edges <- rbind(all_edges, rv$ghost_edges)
      }

      # Create network
      vis <- visNetwork(all_nodes, all_edges, height = "100%", width = "100%") %>%
        apply_graphical_ses_styling() %>%
        visEvents(
          click = sprintf("function(params) {
            if (params.nodes.length > 0) {
              Shiny.setInputValue('%s', params.nodes[0], {priority: 'event'});
            }
          }", ns("node_clicked"))
        )

      return(vis)
    })

    # =========================================================================
    # NODE INTERACTION
    # =========================================================================

    observeEvent(input$node_clicked, {
      clicked_id <- input$node_clicked
      debug_log(paste("Node clicked:", clicked_id), "GRAPHICAL SES")

      # Check if ghost node
      if (startsWith(clicked_id, "GHOST_")) {
        # Accept ghost node
        accept_ghost_node(clicked_id)
      } else {
        # Select permanent node
        rv$selected_node_id <- clicked_id
        clear_ghost_nodes()  # Clear any existing ghosts
      }
    })

    accept_ghost_node <- function(ghost_id) {
      # Find ghost node
      ghost_node <- rv$ghost_nodes[rv$ghost_nodes$id == ghost_id, ]

      if (nrow(ghost_node) == 0) {
        debug_log(paste("Ghost node not found:", ghost_id), "GRAPHICAL SES")
        return()
      }

      # Log user feedback on connection (if ML was used)
      if (exists("ML_AVAILABLE") && ML_AVAILABLE && exists("log_connection_feedback")) {
        # Find the source node
        ghost_edge <- rv$ghost_edges[rv$ghost_edges$to == ghost_id, ]
        if (nrow(ghost_edge) > 0) {
          source_node <- rv$network_nodes[rv$network_nodes$id == ghost_edge$from[1], ]

          if (nrow(source_node) > 0) {
            # Create ML prediction object (reconstruct from ghost node data)
            ml_prediction <- list(
              existence_probability = 1.0,  # User accepted, so exists
              strength = ghost_edge$strength %||% "medium",
              confidence = ghost_edge$confidence %||% 3,
              polarity = ghost_edge$polarity %||% "+"
            )

            tryCatch({
              log_connection_feedback(
                source_element = list(name = source_node$name, type = source_node$type),
                target_element = list(name = ghost_node$name, type = ghost_node$type),
                ml_prediction = ml_prediction,
                user_action = "accepted",
                user_properties = ml_prediction,
                context = rv$context,
                session_id = session$token
              )
            }, error = function(e) {
              debug_log(paste("Feedback logging failed:", e$message), "GRAPHICAL SES")
            })
          }
        }
      }

      # Convert to permanent
      new_node_id <- create_graphical_node_id(ghost_node$type, nrow(rv$network_nodes) + 1)

      permanent_node <- ghost_node
      permanent_node$id <- new_node_id
      permanent_node$is_ghost <- FALSE
      permanent_node$color.background <- ELEMENT_COLORS[[ghost_node$type]]
      permanent_node$borderWidth <- 3
      permanent_node$borderWidthSelected <- 4
      permanent_node$size <- 50
      permanent_node$font.size <- 16
      permanent_node$font.color <- "#ffffff"

      rv$network_nodes <- rbind(rv$network_nodes, permanent_node)

      # Add edge
      ghost_edge <- rv$ghost_edges[rv$ghost_edges$to == ghost_id, ]
      if (nrow(ghost_edge) > 0) {
        permanent_edge <- ghost_edge
        permanent_edge$to <- new_node_id
        permanent_edge$id <- paste0("EDGE_", nrow(rv$network_edges) + 1)
        permanent_edge$is_ghost <- FALSE
        permanent_edge$dashes <- FALSE

        rv$network_edges <- rbind(rv$network_edges, permanent_edge)
      }

      # Clear ghosts
      clear_ghost_nodes()

      # Save to history
      save_to_history()

      # Auto-select new node
      rv$selected_node_id <- new_node_id

      showNotification(
        paste(i18n$t("common.messages.added_element"), ghost_node$name),
        type = "message",
        duration = 2
      )

      debug_log(paste("Accepted ghost node:", new_node_id), "GRAPHICAL SES")
    }

    # =========================================================================
    # DETAILS PANEL RENDERING
    # =========================================================================

    output$details_content <- renderUI({
      if (is.null(rv$selected_node_id)) {
        div(class = "empty-state",
          div(class = "empty-icon", icon("mouse-pointer")),
          div(class = "empty-text", i18n$t("modules.graphical_ses_creator.no_node_selected")),
          div(class = "empty-hint", i18n$t("modules.graphical_ses_creator.click_node_for_details"))
        )
      } else {
        # Show node details
        node <- rv$network_nodes[rv$network_nodes$id == rv$selected_node_id, ]

        if (nrow(node) == 0) {
          return(div(i18n$t("modules.graphical_ses_creator.node_not_found")))
        }

        tagList(
          div(class = "node-details",
            div(class = "node-name", node$name),
            div(class = "node-type", icon("tag"), " ", node$type)
          ),

          div(class = "node-actions",
            actionButton(ns("expand_node"),
              label = i18n$t("modules.graphical_ses_creator.expand_network"),
              icon = icon("plus-circle"),
              class = "btn-primary btn-block"
            ),
            actionButton(ns("edit_node"),
              label = i18n$t("modules.graphical_ses_creator.edit"),
              icon = icon("edit"),
              class = "btn-default btn-block"
            ),
            actionButton(ns("delete_node"),
              label = i18n$t("modules.graphical_ses_creator.delete"),
              icon = icon("trash"),
              class = "btn-danger btn-block"
            )
          ),

          # Show ghost suggestions if expanded
          if (!is.null(rv$expanded_node_id) && rv$expanded_node_id == rv$selected_node_id && nrow(rv$ghost_nodes) > 0) {
            tagList(
              hr(),
              h5(i18n$t("modules.graphical_ses_creator.suggested_elements")),
              div(style = "max-height: 400px; overflow-y: auto;",
                lapply(1:nrow(rv$ghost_nodes), function(i) {
                  ghost <- rv$ghost_nodes[i, ]
                  div(class = "ghost-suggestion",
                    onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'});",
                                     ns("node_clicked"), ghost$id),
                    div(class = "suggestion-name", ghost$name),
                    div(class = "suggestion-type", icon("tag"), " ", ghost$type),
                    div(class = "suggestion-connection",
                      icon("arrow-right"), " ", i18n$t("modules.graphical_ses_creator.click_to_add"))
                  )
                })
              )
            )
          } else {
            NULL
          }
        )
      }
    })

    # =========================================================================
    # EXPAND NODE
    # =========================================================================

    observeEvent(input$expand_node, {
      req(rv$selected_node_id)

      node <- rv$network_nodes[rv$network_nodes$id == rv$selected_node_id, ]

      if (nrow(node) == 0) {
        return()
      }

      showModal(modalDialog(
        title = i18n$t("modules.graphical_ses_creator.generating_suggestions"),
        div(style = "text-align: center; padding: 20px;",
          icon("lightbulb", "fa-spin", style = "font-size: 48px; color: #ff9800;"),
          h4(style = "margin-top: 20px;", i18n$t("modules.graphical_ses_creator.ai_finding_connected")),
          p(i18n$t("modules.graphical_ses_creator.may_take_a_moment"))
        ),
        footer = NULL,
        easyClose = FALSE
      ))

      # Get suggestions (ML-enhanced if available)
      suggestions <- tryCatch({
        # Use ML-ranked suggestions if ML is available
        if (exists("ML_AVAILABLE") && ML_AVAILABLE && exists("suggest_connected_elements_ml")) {
          debug_log("Using ML-ranked suggestions", "GRAPHICAL SES")
          suggest_connected_elements_ml(
            node_id = rv$selected_node_id,
            node_data = list(
              name = node$name,
              type = node$type
            ),
            existing_network = rv$network_nodes,
            context = rv$context,
            max_suggestions = MAX_SUGGESTIONS_PER_EXPANSION
          )
        } else {
          # Fall back to rule-based suggestions
          debug_log("Using rule-based suggestions", "GRAPHICAL SES")
          suggest_connected_elements(
            node_id = rv$selected_node_id,
            node_data = list(
              name = node$name,
              type = node$type
            ),
            existing_network = rv$network_nodes,
            context = rv$context,
            max_suggestions = MAX_SUGGESTIONS_PER_EXPANSION
          )
        }
      }, error = function(e) {
        debug_log(paste("Suggestion error:", e$message), "GRAPHICAL SES")
        return(list())
      })

      removeModal()

      if (length(suggestions) == 0) {
        showNotification(
          i18n$t("common.messages.no_suggestions_found"),
          type = "warning",
          duration = 5
        )
        return()
      }

      # Create ghost nodes
      clear_ghost_nodes()

      for (i in seq_along(suggestions)) {
        ghost_node <- create_ghost_node_data(suggestions[[i]], i)
        ghost_edge <- create_ghost_edge_data(suggestions[[i]], i)

        rv$ghost_nodes <- rbind(rv$ghost_nodes, ghost_node)
        rv$ghost_edges <- rbind(rv$ghost_edges, ghost_edge)
      }

      rv$expanded_node_id <- rv$selected_node_id

      showNotification(
        sprintf(i18n$t("common.messages.found_suggestions"), length(suggestions)),
        type = "message",
        duration = 3
      )

      debug_log(paste("Created", length(suggestions), "ghost nodes"), "GRAPHICAL SES")
    })

    # =========================================================================
    # CONTROL BUTTONS
    # =========================================================================

    observeEvent(input$clear_ghosts, {
      clear_ghost_nodes()
      showNotification(i18n$t("common.messages.suggestions_cleared"), type = "message", duration = 2)
    })

    observeEvent(input$undo, {
      if (rv$history_index > 1) {
        rv$history_index <- rv$history_index - 1
        restore_from_history(rv$history_index)
        showNotification(i18n$t("common.messages.undone"), type = "message", duration = 2)
      } else {
        showNotification(i18n$t("common.messages.nothing_to_undo"), type = "warning", duration = 2)
      }
    })

    observeEvent(input$zoom_fit, {
      # Trigger visNetwork fit
      visNetworkProxy(ns("network_graph")) %>%
        visFit(animation = list(duration = 500))
    })

    observeEvent(input$restart, {
      showModal(modalDialog(
        title = i18n$t("modules.graphical_ses_creator.start_over_confirm_title"),
        i18n$t("modules.graphical_ses_creator.start_over_confirm_body"),
        footer = tagList(
          modalButton(i18n$t("modules.graphical_ses_creator.cancel")),
          actionButton(ns("confirm_restart"), i18n$t("modules.graphical_ses_creator.yes_start_over"), class = "btn-danger")
        )
      ))
    })

    observeEvent(input$confirm_restart, {
      # Reset everything
      rv$wizard_step <- 1
      rv$context <- list(regional_sea = NULL, ecosystem_type = NULL, main_issue = NULL)
      rv$classification_result <- NULL
      rv$selected_classification_type <- NULL
      rv$network_nodes <- data.frame()
      rv$network_edges <- data.frame()
      rv$ghost_nodes <- data.frame()
      rv$ghost_edges <- data.frame()
      rv$selected_node_id <- NULL
      rv$expanded_node_id <- NULL
      rv$history <- list()
      rv$history_index <- 0

      removeModal()
      showNotification(i18n$t("common.messages.restarted_wizard"), type = "message", duration = 3)

      # Reopen wizard panel
      shinyjs::runjs(sprintf("
        var panel = document.getElementById('%s');
        if (panel) {
          panel.style.width = '320px';
          panel.style.minWidth = '320px';
          panel.style.padding = '15px';
          panel.style.overflow = 'auto';
        }
      ", ns("context_panel")))
    })

    # Toggle Context Wizard panel
    observeEvent(input$toggle_context, {
      shinyjs::runjs(sprintf("
        var panel = document.getElementById('%s');
        if (panel) {
          if (panel.style.width === '0px' || panel.style.display === 'none') {
            // Open panel
            panel.style.width = '320px';
            panel.style.minWidth = '320px';
            panel.style.padding = '15px';
            panel.style.overflow = 'auto';
            panel.style.display = 'block';
          } else {
            // Close panel
            panel.style.width = '0px';
            panel.style.minWidth = '0px';
            panel.style.padding = '0';
            panel.style.overflow = 'hidden';
          }
        }
      ", ns("context_panel")))
    })

    # =========================================================================
    # EXPORT TO ISA
    # =========================================================================

    observeEvent(input$export_isa, {
      # Validate network
      validation <- validate_network_for_export(rv$network_nodes, rv$network_edges)

      if (!validation$is_valid) {
        showModal(modalDialog(
          title = i18n$t("modules.graphical_ses_creator.cannot_export"),
          div(
            h4(i18n$t("modules.graphical_ses_creator.network_validation_failed")),
            tags$ul(
              lapply(validation$issues, function(issue) tags$li(issue))
            )
          ),
          footer = modalButton(i18n$t("modules.graphical_ses_creator.close"))
        ))
        return()
      }

      # Show warnings if any
      if (length(validation$warnings) > 0) {
        showNotification(
          paste(validation$warnings, collapse = "; "),
          type = "warning",
          duration = 5
        )
      }

      showModal(modalDialog(
        title = i18n$t("modules.graphical_ses_creator.exporting_to_isa"),
        div(style = "text-align: center; padding: 20px;",
          icon("spinner", "fa-spin", style = "font-size: 48px; color: #4CAF50;"),
          h4(style = "margin-top: 20px;", i18n$t("modules.graphical_ses_creator.converting_to_isa_format"))
        ),
        footer = NULL,
        easyClose = FALSE
      ))

      # Convert to ISA
      isa_data <- tryCatch({
        convert_graphical_to_isa(
          nodes = rv$network_nodes,
          edges = rv$network_edges,
          context = rv$context
        )
      }, error = function(e) {
        debug_log(paste("Export error:", e$message), "GRAPHICAL SES")
        return(NULL)
      })

      removeModal()

      if (is.null(isa_data)) {
        showNotification(i18n$t("common.messages.export_failed"), type = "error", duration = 5)
        return()
      }

      # Save to project data
      current_data <- isolate(project_data_reactive())
      current_data$data$isa_data <- isa_data
      project_data_reactive(current_data)

      showNotification(
        i18n$t("common.messages.exported_to_isa"),
        type = "message",
        duration = 5
      )

      debug_log("Exported network to ISA", "GRAPHICAL SES")
    })

    # =========================================================================
    # NETWORK STATISTICS
    # =========================================================================

    output$network_statistics <- renderUI({
      n_nodes <- nrow(rv$network_nodes)
      n_edges <- nrow(rv$network_edges)
      n_ghosts <- nrow(rv$ghost_nodes)

      if (n_nodes == 0) {
        return(div(i18n$t("modules.graphical_ses_creator.no_network_data")))
      }

      tagList(
        span(class = "stat",
          span(class = "stat-label", i18n$t("modules.graphical_ses_creator.nodes")), " ", n_nodes
        ),
        span(class = "stat",
          span(class = "stat-label", i18n$t("modules.graphical_ses_creator.connections")), " ", n_edges
        ),
        if (n_ghosts > 0) {
          span(class = "stat",
            span(class = "stat-label", i18n$t("modules.graphical_ses_creator.suggestions")), " ", n_ghosts
          )
        } else {
          NULL
        }
      )
    })

    # Return reactive values
    return(reactive({ rv }))
  })
}
