# modules/create_ses_module.R
# Consolidated "Create SES" Module
# Purpose: Main entry point for creating Social-Ecological Systems with 3 methods
# Methods: 1) Standard Entry, 2) AI Assistant, 3) Template-Based

# ============================================================================
# UI FUNCTION
# ============================================================================

create_ses_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    # REMOVED: usei18n() - only called once in main UI (app.R)

    # Custom CSS for the Create SES interface
    tags$head(
      tags$style(HTML("
        .create-ses-container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 20px;
        }
        .method-card {
          background: white;
          border: 3px solid #e0e0e0;
          border-radius: 15px;
          padding: 30px;
          margin: 20px 0;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          height: 100%;
        }
        .method-card:hover {
          border-color: #667eea;
          box-shadow: 0 8px 16px rgba(102,126,234,0.3);
          transform: translateY(-5px);
        }
        .method-card.selected {
          border-color: #27ae60;
          background: linear-gradient(135deg, #f8fff9 0%, #e8f8f0 100%);
          box-shadow: 0 8px 20px rgba(39,174,96,0.3);
        }
        .method-icon {
          font-size: 60px;
          color: #667eea;
          margin-bottom: 20px;
          text-align: center;
        }
        .method-card.selected .method-icon {
          color: #27ae60;
        }
        .method-title {
          font-size: 24px;
          font-weight: 700;
          color: #2c3e50;
          text-align: center;
          margin-bottom: 15px;
        }
        .method-description {
          font-size: 15px;
          color: #34495e;
          text-align: center;
          line-height: 1.6;
          margin-bottom: 15px;
        }
        .method-features {
          list-style: none;
          padding: 0;
          margin: 15px 0;
        }
        .method-features li {
          padding: 8px 0;
          padding-left: 30px;
          position: relative;
        }
        .method-features li:before {
          content: '✓';
          position: absolute;
          left: 0;
          color: #27ae60;
          font-weight: bold;
          font-size: 18px;
        }
        .method-badge {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 5px 15px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 600;
          margin: 5px 5px 5px 0;
        }
        .method-badge.beginner {
          background: #27ae60;
        }
        .method-badge.intermediate {
          background: #f39c12;
        }
        .method-badge.advanced {
          background: #e74c3c;
        }
        .method-badge.recommended {
          background: #9b59b6;
        }
        .header-section {
          text-align: center;
          margin-bottom: 40px;
          padding: 30px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 15px;
          color: white;
        }
        .header-section h2 {
          font-size: 36px;
          font-weight: 700;
          margin-bottom: 10px;
        }
        .header-section p {
          font-size: 18px;
          opacity: 0.95;
        }
        .proceed-button {
          background: linear-gradient(135deg, #27ae60 0%, #229954 100%);
          border: none;
          color: white;
          padding: 15px 40px;
          font-size: 18px;
          font-weight: 600;
          border-radius: 30px;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(39,174,96,0.3);
          margin-top: 30px;
        }
        .proceed-button:hover {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(39,174,96,0.4);
        }
        .proceed-button:disabled {
          background: #95a5a6;
          cursor: not-allowed;
          box-shadow: none;
        }
        .comparison-table {
          background: white;
          border-radius: 10px;
          padding: 20px;
          margin: 30px 0;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
      "))
    ),

    # Reactive UI container
    uiOutput(ns("main_content"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

create_ses_server <- function(id, project_data_reactive, parent_session = NULL, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      selected_method = NULL
    )

    # Render reactive UI
    output$main_content <- renderUI({
      div(class = "create-ses-container",
        # Header Section
        div(class = "header-section",
          create_module_header(
            ns = ns,
            title_key = "modules.ses.creation.title",
            subtitle_key = "modules.ses.creation.subtitle",
            help_id = "help_create_ses",
            i18n = i18n
          )
        ),

        # Method Selection Cards
        fluidRow(
          column(4,
            div(class = "method-card", id = ns("card_standard"),
                onclick = sprintf("Shiny.setInputValue('%s', 'standard', {priority: 'event'})", ns("method_selected")),
              div(class = "method-icon",
                icon("edit", class = "fa-3x")
              ),
              div(class = "method-title", i18n$t("ui.sidebar.standard_entry")),
              div(
                span(class = "method-badge intermediate", i18n$t("modules.ses.creation.intermediate")),
                span(class = "method-badge", i18n$t("modules.ses.creation.structured"))
              ),
              div(class = "method-description",
                i18n$t("modules.ses.traditional_form_based_approach_following_the_daps")
              ),
              tags$ul(class = "method-features",
                tags$li(i18n$t("modules.ses.creation.step_by_step_guided_exercises")),
                tags$li(i18n$t("modules.ses.creation.complete_control_over_all_elements")),
                tags$li(i18n$t("modules.ses.creation.detailed_data_validation")),
                tags$li(i18n$t("modules.ses.creation.direct_framework_implementation")),
                tags$li(i18n$t("modules.ses.creation.export_ready_data_structure"))
              ),
              div(style = "text-align: center; margin-top: 20px;",
                tags$strong(i18n$t("modules.ses.creation.best_for")),
                " ",
                i18n$t("modules.ses.creation.experienced_users_academic_research_detailed_documentation")
              )
            )
          ),

          column(4,
            div(class = "method-card", id = ns("card_ai"),
                onclick = sprintf("Shiny.setInputValue('%s', 'ai', {priority: 'event'})", ns("method_selected")),
              div(class = "method-icon",
                icon("robot", class = "fa-3x")
              ),
              div(class = "method-title", i18n$t("ui.sidebar.ai_assistant")),
              div(
                span(class = "method-badge beginner", i18n$t("modules.ses.creation.beginner")),
                span(class = "method-badge recommended", i18n$t("modules.ses.creation.recommended"))
              ),
              div(class = "method-description",
                i18n$t("modules.ses.intelligent_question_based_guidance_that_helps_you")
              ),
              tags$ul(class = "method-features",
                tags$li(i18n$t("modules.ses.creation.interactive_qa_workflow")),
                tags$li(i18n$t("modules.ses.creation.context_aware_suggestions")),
                tags$li(i18n$t("modules.ses.creation.automatic_element_generation")),
                tags$li(i18n$t("modules.ses.creation.learning_friendly_approach")),
                tags$li(i18n$t("modules.ses.creation.built_in_examples"))
              ),
              div(style = "text-align: center; margin-top: 20px;",
                tags$strong(i18n$t("modules.ses.creation.best_for")),
                " ",
                i18n$t("modules.ses.creation.beginners_first_time_users_exploratory_analysis")
              )
            )
          ),

          column(4,
            div(class = "method-card", id = ns("card_template"),
                onclick = sprintf("Shiny.setInputValue('%s', 'template', {priority: 'event'})", ns("method_selected")),
              div(class = "method-icon",
                icon("clone", class = "fa-3x")
              ),
              div(class = "method-title", i18n$t("ui.sidebar.template_based")),
              div(
                span(class = "method-badge beginner", i18n$t("modules.ses.creation.beginner")),
                span(class = "method-badge", i18n$t("modules.ses.creation.quick_start"))
              ),
              div(class = "method-description",
                i18n$t("modules.ses.start_from_pre_built_templates_based_on_common_mar")
              ),
              tags$ul(class = "method-features",
                tags$li(i18n$t("modules.ses.creation.pre_populated_frameworks")),
                tags$li(i18n$t("modules.ses.creation.domain_specific_templates")),
                tags$li(i18n$t("modules.ses.creation.ready_to_customize_elements")),
                tags$li(i18n$t("modules.ses.creation.fastest_setup_time")),
                tags$li(i18n$t("modules.ses.creation.example_connections_included"))
              ),
              div(style = "text-align: center; margin-top: 20px;",
                tags$strong(i18n$t("modules.ses.creation.best_for")),
                " ",
                i18n$t("modules.ses.quick_prototyping_common_scenarios_time_constraine")
              )
            )
          )
        ),

        # Selection feedback and proceed button
        fluidRow(
          column(12, style = "text-align: center; margin-top: 30px;",
            uiOutput(ns("selection_feedback")),
            br(),
            actionButton(ns("proceed"),
                         i18n$t("modules.ses.creation.proceed_to_selected_method"),
                         icon = icon("arrow-right"),
                         class = "proceed-button",
                         disabled = TRUE)
          )
        ),

        # Comparison section
        hr(style = "margin: 50px 0;"),

        div(class = "comparison-table",
          h4(icon("table"), " ", i18n$t("modules.ses.creation.method_comparison"), style = "text-align: center; margin-bottom: 20px;"),
          tableOutput(ns("comparison_table"))
        ),

        # Help section
        fluidRow(
          column(12,
            wellPanel(
              style = "background: #f8f9fa; border-left: 4px solid #667eea;",
              h5(icon("lightbulb"), " ", i18n$t("modules.ses.creation.need_help_choosing")),
              p(tags$strong(i18n$t("modules.ses.creation.new_to_ses_modeling")), " Start with the ", tags$strong(i18n$t("ui.sidebar.ai_assistant")),
                " for guided learning and gentle introduction to the framework."),
              p(tags$strong(i18n$t("modules.ses.creation.have_existing_framework_knowledge")), " Use ", tags$strong(i18n$t("ui.sidebar.standard_entry")),
                " for maximum control and detailed customization."),
              p(tags$strong(i18n$t("modules.ses.creation.working_on_a_time_sensitive_project")), " Try ", tags$strong(i18n$t("ui.sidebar.template_based")),
                " to jumpstart your analysis with proven structures."),
              p(strong("Not sure?"), " You can always switch methods later or combine approaches!")
            )
          )
        )
      )
    })

    # Track method selection
    observeEvent(input$method_selected, {
      rv$selected_method <- input$method_selected

      # Update card styling
      shinyjs::runjs(sprintf("
        $('.method-card').removeClass('selected');
        $('#%s').addClass('selected');
      ", ns(paste0("card_", input$method_selected))))

      # Enable proceed button
      shinyjs::enable("proceed")
    })

    # Selection feedback
    output$selection_feedback <- renderUI({
      req(rv$selected_method)

      method_names <- list(
        standard = i18n$t("ui.sidebar.standard_entry"),
        ai = i18n$t("ui.sidebar.ai_assistant"),
        template = i18n$t("ui.sidebar.template_based")
      )

      div(style = "font-size: 18px; color: #27ae60; font-weight: 600;",
        icon("check-circle"),
        sprintf(" %s %s", i18n$t("modules.ses.creation.you_selected"), method_names[[rv$selected_method]])
      )
    })

    # Comparison table
    output$comparison_table <- renderTable({
      data.frame(
        Feature = c(
          i18n$t("modules.ses.creation.time_to_start"),
          i18n$t("modules.ses.creation.learning_curve"),
          i18n$t("modules.ses.creation.flexibility"),
          i18n$t("modules.ses.creation.guidance_level"),
          i18n$t("modules.ses.creation.customization"),
          "Best For"
        ),
        `Standard Entry` = c(
          "Medium (15-30 min)",
          "Moderate",
          "High",
          i18n$t("modules.ses.creation.structured"),
          "Complete",
          "Experienced users"
        ),
        `AI Assistant` = c(
          "Quick (5-10 min)",
          "Easy",
          "Medium",
          i18n$t("modules.ses.creation.interactive_qa_workflow"),
          "Guided",
          "Beginners"
        ),
        `Template-Based` = c(
          "Very Quick (2-5 min)",
          "Very Easy",
          "Medium",
          i18n$t("modules.ses.creation.pre_populated_frameworks"),
          "Moderate",
          i18n$t("modules.ses.creation.quick_start")
        ),
        check.names = FALSE
      )
    }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")

    # Proceed button action
    observeEvent(input$proceed, {
      req(rv$selected_method)

      # Route to appropriate module based on selection
      if (!is.null(parent_session)) {
        if (rv$selected_method == "standard") {
          updateTabItems(parent_session, "sidebar_menu", "create_ses_standard")
        } else if (rv$selected_method == "ai") {
          updateTabItems(parent_session, "sidebar_menu", "create_ses_ai")
        } else if (rv$selected_method == "template") {
          updateTabItems(parent_session, "sidebar_menu", "create_ses_template")
        }
      }
    })

    # Help Modal ----
    create_help_observer(
      input, "help_create_ses", "create_ses_guide_title",
      tagList(
        h4(i18n$t("modules.ses.creation.create_ses_guide_methods_title")),
        p(i18n$t("modules.ses.creation.create_ses_guide_methods_p1")),
        tags$ul(
          tags$li(strong(i18n$t("ui.sidebar.standard_entry")), ": ", i18n$t("modules.ses.creation.create_ses_guide_standard_desc")),
          tags$li(strong(i18n$t("ui.sidebar.ai_assistant")), ": ", i18n$t("modules.ses.creation.create_ses_guide_ai_desc")),
          tags$li(strong(i18n$t("ui.sidebar.template_based")), ": ", i18n$t("modules.ses.creation.create_ses_guide_template_desc"))
        )
      ),
      i18n
    )

    # Return selected method for parent to access
    return(reactive({ rv$selected_method }))
  })
}
