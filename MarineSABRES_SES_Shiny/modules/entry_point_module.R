# modules/entry_point_module.R
# Simplified Entry Point System for Marine Management DSS & Toolbox
# Purpose: Guide users through EP0-EP4 to find appropriate tools

# ============================================================================
# UI FUNCTION
# ============================================================================

entry_point_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    # Custom CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "entry-point.css"),
      # Initialize Bootstrap tooltips and download handler
      tags$script(HTML("
        $(document).ready(function() {
          // Initialize tooltips on page load
          $('[data-toggle=\"tooltip\"]').tooltip();

          // Re-initialize tooltips when content changes
          Shiny.addCustomMessageHandler('reinit_tooltips', function(message) {
            setTimeout(function() {
              $('[data-toggle=\"tooltip\"]').tooltip();
            }, 100);
          });

          // Handle pathway report download
          Shiny.addCustomMessageHandler('download_pathway_report', function(message) {
            var blob = new Blob([message.content], {type: 'text/plain'});
            var url = window.URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = message.filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
          });
        });

        // Re-initialize tooltips after any Shiny update
        $(document).on('shiny:value', function(event) {
          setTimeout(function() {
            $('[data-toggle=\"tooltip\"]').tooltip();
          }, 100);
        });
      "))
    ),

    # Dynamic content area
    uiOutput(ns("main_content"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

entry_point_server <- function(id, project_data_reactive, i18n, parent_session = NULL, user_level_reactive = NULL) {
  moduleServer(id, function(input, output, session) {

    # Reactive values to track state
    rv <- reactiveValues(
      current_screen = "welcome",  # welcome, guided, recommendations
      current_step = 0,            # 0=EP0, 1=EP1, 2=EP2-3, 4=EP4
      ep0_selected = c(),          # Changed to vector for multi-select
      ep1_selected = c(),          # Changed to vector for multi-select
      ep2_selected = c(),
      ep3_selected = c(),
      ep4_selected = c()
    )

    # ========== MAIN CONTENT RENDERER ==========
    output$main_content <- renderUI({
      # Add reactive dependency on current language to trigger re-render when language changes
      current_lang <- i18n$get_translation_language()

      # Get current user level (default to intermediate if not provided)
      current_user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"

      if (rv$current_screen == "welcome") {
        render_welcome_screen(session$ns, i18n)
      } else if (rv$current_screen == "guided") {
        render_guided_screen(session$ns, rv, input, i18n)
      } else if (rv$current_screen == "recommendations") {
        render_recommendations_screen(session$ns, rv, current_user_level, i18n)
      }
    })

    # ========== WELCOME SCREEN ACTIONS ==========
    observeEvent(input$start_guided, {
      rv$current_screen <- "guided"
      rv$current_step <- 0
    })

    observeEvent(input$start_quick, {
      showNotification(i18n$t("modules.entry_point.ep_notify_use_main_menu"), type = "message")
    })

    # ========== EP0 ACTIONS ==========
    observeEvent(input$ep0_role_click, {
      # Toggle multi-select behavior
      clicked_id <- input$ep0_role_click
      if (clicked_id %in% rv$ep0_selected) {
        # Deselect if already selected
        rv$ep0_selected <- setdiff(rv$ep0_selected, clicked_id)
      } else {
        # Add to selection
        rv$ep0_selected <- c(rv$ep0_selected, clicked_id)
      }
    })

    observeEvent(input$ep0_continue, {
      if (length(rv$ep0_selected) > 0) {
        rv$current_step <- 1
      } else {
        showNotification(i18n$t("modules.entry_point.ep_notify_select_role"), type = "warning")
      }
    })

    observeEvent(input$ep0_skip, {
      rv$ep0_selected <- c()
      rv$current_step <- 1
    })

    # ========== EP1 ACTIONS ==========
    observeEvent(input$ep1_need_click, {
      # Toggle multi-select behavior
      clicked_id <- input$ep1_need_click
      if (clicked_id %in% rv$ep1_selected) {
        # Deselect if already selected
        rv$ep1_selected <- setdiff(rv$ep1_selected, clicked_id)
      } else {
        # Add to selection
        rv$ep1_selected <- c(rv$ep1_selected, clicked_id)
      }
    })

    observeEvent(input$ep1_back, {
      rv$current_step <- 0
    })

    observeEvent(input$ep1_continue, {
      if (length(rv$ep1_selected) > 0) {
        rv$current_step <- 2
      } else {
        showNotification(i18n$t("modules.entry_point.ep_notify_select_need"), type = "warning")
      }
    })

    observeEvent(input$ep1_skip, {
      rv$ep1_selected <- c()
      rv$current_step <- 2
    })

    # ========== EP2-3 ACTIONS ==========
    observe({
      rv$ep2_selected <- input$ep2_activities %||% c()
    })

    observe({
      rv$ep3_selected <- input$ep3_risks %||% c()
    })

    observeEvent(input$ep23_back, {
      rv$current_step <- 1
    })

    observeEvent(input$ep23_continue, {
      rv$current_step <- 4
    })

    observeEvent(input$ep23_skip, {
      rv$current_step <- 4
    })

    # ========== EP4 ACTIONS ==========
    observe({
      rv$ep4_selected <- input$ep4_topics %||% c()
    })

    observeEvent(input$ep4_back, {
      rv$current_step <- 2
    })

    observeEvent(input$ep4_get_recommendations, {
      rv$current_screen <- "recommendations"
    })

    observeEvent(input$ep4_skip, {
      rv$current_screen <- "recommendations"
    })

    # ========== START OVER ==========
    observeEvent(input$start_over, {
      rv$current_screen <- "welcome"
      rv$current_step <- 0
      rv$ep0_selected <- c()
      rv$ep1_selected <- c()
      rv$ep2_selected <- c()
      rv$ep3_selected <- c()
      rv$ep4_selected <- c()
    })

    # ========== EXPORT PATHWAY REPORT ==========
    observeEvent(input$export_pathway, {
      tryCatch({
        # Get current user level (default to intermediate if not provided)
        current_user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"

        # Get recommended tools
        recommended_tools <- get_tool_recommendations(rv, current_user_level, i18n)

        # Create pathway summary text
        pathway_summary <- c()

        if (length(rv$ep0_selected) > 0) {
          role_labels <- sapply(rv$ep0_selected, function(id) {
            i18n$t(EP0_MANAGER_ROLES[[which(sapply(EP0_MANAGER_ROLES, function(x) x$id) == id)]]$label)
          })
          pathway_summary <- c(pathway_summary, paste("Role:", paste(role_labels, collapse = ", ")))
        }

        if (length(rv$ep1_selected) > 0) {
          need_labels <- sapply(rv$ep1_selected, function(id) {
            i18n$t(EP1_BASIC_NEEDS[[which(sapply(EP1_BASIC_NEEDS, function(x) x$id) == id)]]$label)
          })
          pathway_summary <- c(pathway_summary, paste("Need:", paste(need_labels, collapse = ", ")))
        }

        if (length(rv$ep2_selected) > 0) {
          activity_labels <- sapply(rv$ep2_selected, function(id) {
            i18n$t(EP2_ACTIVITY_SECTORS[[which(sapply(EP2_ACTIVITY_SECTORS, function(x) x$id) == id)]]$label)
          })
          pathway_summary <- c(pathway_summary, paste("Activities:", paste(activity_labels, collapse = ", ")))
        }

        if (length(rv$ep3_selected) > 0) {
          risk_labels <- sapply(rv$ep3_selected, function(id) {
            i18n$t(EP3_RISKS_HAZARDS[[which(sapply(EP3_RISKS_HAZARDS, function(x) x$id) == id)]]$label)
          })
          pathway_summary <- c(pathway_summary, paste("Risks:", paste(risk_labels, collapse = ", ")))
        }

        if (length(rv$ep4_selected) > 0) {
          topic_labels <- sapply(rv$ep4_selected, function(id) {
            i18n$t(EP4_TOPICS[[which(sapply(EP4_TOPICS, function(x) x$id) == id)]]$label)
          })
          pathway_summary <- c(pathway_summary, paste("Topics:", paste(topic_labels, collapse = ", ")))
        }

        # Create tools summary
        tools_summary <- sapply(seq_along(recommended_tools), function(i) {
          tool <- recommended_tools[[i]]
          sprintf("%d. %s\n   %s\n   %s %s | %s %s\n",
                  i, tool$name, tool$description,
                  i18n$t("modules.entry_point.report_time"), tool$time_required,
                  i18n$t("modules.entry_point.report_skill"), tool$skill_level)
        })

        # Combine into report text
        report_text <- paste0(
          i18n$t("modules.entry_point.report_header"), "\n\n",
          i18n$t("modules.entry_point.report_generated"), " ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n",
          i18n$t("modules.entry_point.report_pathway"), "\n",
          paste(pathway_summary, collapse = "\n"), "\n\n",
          i18n$t("modules.entry_point.report_tools"), "\n",
          paste(tools_summary, collapse = "\n"), "\n\n",
          i18n$t("modules.entry_point.report_workflow"), "\n",
          "1. ", i18n$t("modules.entry_point.report_step_1"), "\n",
          "2. ", i18n$t("modules.entry_point.report_step_2"), "\n",
          "3. ", i18n$t("modules.entry_point.report_step_3"), "\n",
          "4. ", i18n$t("modules.entry_point.report_step_4"), "\n",
          "5. ", i18n$t("modules.entry_point.report_step_5"), "\n"
        )

        # Create temporary file
        temp_file <- tempfile(fileext = ".txt")
        writeLines(report_text, temp_file)

        # Download the file
        session$sendCustomMessage(
          type = "download_pathway_report",
          message = list(
            filename = paste0("pathway_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt"),
            content = report_text
          )
        )

        showNotification(
          i18n$t("modules.entry_point.pathway_report_generated_successfully"),
          type = "message",
          duration = 3
        )

      }, error = function(e) {
        showNotification(
          paste(i18n$t("modules.entry_point.error_generating_pathway_report"), e$message),
          type = "error",
          duration = 5
        )
        debug_log(sprintf("Error generating pathway report: %s", e$message), "ENTRY-POINT")
      })
    })

    # ========== TOOL NAVIGATION OBSERVERS ==========
    # These handle the "Go to [Tool]" buttons on the recommendations screen
    # Since the parent_session is needed to update the sidebar menu, we only
    # create these observers if parent_session is provided

    if (!is.null(parent_session)) {
      # Track which tool navigation observers have been created to prevent leaks
      created_observers <- reactiveVal(character(0))

      observe({
        if (rv$current_screen == "recommendations") {
          current_user_level <- if (!is.null(user_level_reactive)) user_level_reactive() else "intermediate"
          recommended_tools <- get_tool_recommendations(rv, current_user_level, i18n)
          already_created <- created_observers()

          new_ids <- character(0)
          lapply(recommended_tools, function(tool) {
            btn_id <- paste0("goto_", tool$id)

            if (!(btn_id %in% already_created)) {
              new_ids <<- c(new_ids, btn_id)
              observeEvent(input[[btn_id]], {
                updateTabItems(parent_session, "sidebar_menu", tool$menu_id)
                showNotification(
                  sprintf(i18n$t("modules.entry_point.navigating_to_s"), tool$name),
                  type = "message",
                  duration = 2
                )
              }, ignoreInit = TRUE)
            }
          })

          if (length(new_ids) > 0) {
            created_observers(c(already_created, new_ids))
          }
        }
      })
    }

  })
}

# ============================================================================
# UI HELPER FUNCTIONS
# ============================================================================

render_welcome_screen <- function(ns, i18n) {
  fluidRow(
    column(12,
      div(
        class = "jumbotron",

        fluidRow(
          column(6,
            div(
              class = "ep-card start-here-highlight",
              div(
                class = "start-here-badge",
                icon("star"), " ", i18n$t("modules.entry_point.start_here")
              ),
              h3(icon("route"), " ", i18n$t("modules.entry_point.guided_pathway")),
              p(i18n$t("modules.entry_point.step_by_step_guidance_through_the_entry_points")),
              actionButton(ns("start_guided"), i18n$t("modules.entry_point.start_guided_journey"),
                          icon = icon("play"), class = "btn-primary btn-lg btn-block")
            )
          ),
          column(6,
            div(
              class = "ep-card",
              h3(icon("bolt"), " ", i18n$t("modules.entry_point.quick_access")),
              p(i18n$t("modules.entry_point.i_know_what_tool_i_need")),
              actionButton(ns("start_quick"), i18n$t("modules.entry_point.browse_tools"),
                          icon = icon("tools"), class = "btn-success btn-lg btn-block")
            )
          )
        )
      ),

      # FAQ Accordion
      hr(),
      column(12,
        h4(icon("question-circle"), " ", i18n$t("modules.entry_point.faq_title")),
        bs4Accordion(
          id = ns("faq_accordion"),
          bs4AccordionItem(
            title = i18n$t("modules.entry_point.faq_ses_question"),
            status = "primary",
            collapsed = TRUE,
            p(i18n$t("modules.entry_point.faq_ses_answer_1")),
            p(i18n$t("modules.entry_point.faq_ses_answer_2"))
          ),
          bs4AccordionItem(
            title = i18n$t("modules.entry_point.faq_dapsiwrm_question"),
            status = "info",
            collapsed = TRUE,
            p(i18n$t("modules.entry_point.faq_dapsiwrm_answer")),
            tags$ul(
              tags$li(strong("Drivers:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_drivers")),
              tags$li(strong("Activities:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_activities")),
              tags$li(strong("Pressures:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_pressures")),
              tags$li(strong("State:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_state")),
              tags$li(strong("Impacts:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_impacts")),
              tags$li(strong("Welfare:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_welfare")),
              tags$li(strong("Responses:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_responses")),
              tags$li(strong("Measures:"), " ", i18n$t("modules.entry_point.faq_dapsiwrm_measures"))
            )
          ),
          bs4AccordionItem(
            title = i18n$t("modules.entry_point.faq_started_question"),
            status = "success",
            collapsed = TRUE,
            p(i18n$t("modules.entry_point.faq_started_answer_1"), " ", strong(i18n$t("modules.entry_point.guided_pathway")), " ", i18n$t("modules.entry_point.faq_started_answer_1_suffix")),
            p(i18n$t("modules.entry_point.faq_started_answer_2")),
            p(i18n$t("modules.entry_point.faq_started_answer_3"), " ", strong(i18n$t("modules.entry_point.quick_access")), " ", i18n$t("modules.entry_point.faq_started_answer_3_suffix"))
          ),
          bs4AccordionItem(
            title = i18n$t("modules.entry_point.faq_expertise_question"),
            status = "warning",
            collapsed = TRUE,
            p(i18n$t("modules.entry_point.faq_expertise_answer")),
            tags$ul(
              tags$li(strong("Beginners:"), " ", i18n$t("modules.entry_point.faq_beginners")),
              tags$li(strong("Intermediate:"), " ", i18n$t("modules.entry_point.faq_intermediate")),
              tags$li(strong("Experts:"), " ", i18n$t("modules.entry_point.faq_experts"))
            ),
            p(i18n$t("modules.entry_point.faq_change_level"))
          )
        )
      )
    )
  )
}

render_guided_screen <- function(ns, rv, input, i18n) {
  tagList(
    # Progress tracker
    fluidRow(
      column(12,
        div(
          class = "ep-progress",
          h5(i18n$t("modules.entry_point.your_progress")),
          span(class = "ep-step completed", icon("check"), " ", i18n$t("modules.entry_point.welcome")),
          span("→"),
          span(class = if(rv$current_step > 0) "ep-step completed" else "ep-step active", i18n$t("modules.entry_point.ep0_role")),
          span("→"),
          span(class = if(rv$current_step > 1) "ep-step completed" else if(rv$current_step == 1) "ep-step active" else "ep-step", i18n$t("modules.entry_point.ep1_need")),
          span("→"),
          span(class = if(rv$current_step > 2) "ep-step completed" else if(rv$current_step == 2) "ep-step active" else "ep-step", i18n$t("modules.entry_point.ep2_3_context")),
          span("→"),
          span(class = if(rv$current_step >= 4) "ep-step active" else "ep-step", i18n$t("modules.entry_point.ep4_topic")),
          span("→"),
          span(class = if(rv$current_screen == "recommendations") "ep-step completed" else "ep-step", icon("star"), " ", i18n$t("modules.entry_point.tools"))
        )
      )
    ),

    hr(),

    # Render current step
    if (rv$current_step == 0) {
      render_ep0(ns, rv, i18n)
    } else if (rv$current_step == 1) {
      render_ep1(ns, rv, i18n)
    } else if (rv$current_step == 2) {
      render_ep23(ns, rv, i18n)
    } else if (rv$current_step == 4) {
      render_ep4(ns, rv, i18n)
    }
  )
}

render_ep0 <- function(ns, rv, i18n) {
  fluidRow(
    column(12,
      div(
        h2(icon("user"), " ", i18n$t("modules.entry_point.entry_point_0_who_are_you")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("modules.entry_point.your_role_helps_us_recommend_the_most_relevant_too")
        )
      ),
      p(class = "text-muted", i18n$t("modules.entry_point.select_your_role_in_marine_management_multiple_sel")),
      br(),

      lapply(EP0_MANAGER_ROLES, function(role) {
        div(
          class = if(role$id %in% rv$ep0_selected) "ep-card selected" else "ep-card",
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("ep0_role_click"), role$id),
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = if(!is.null(role$typical_tasks)) paste(i18n$t("modules.entry_point.typical_tasks"), role$typical_tasks) else i18n$t(role$description),
          fluidRow(
            column(2, icon(role$icon, class = "fa-3x", style = "color: #3498db;")),
            column(10,
              h4(i18n$t(role$label)),
              p(i18n$t(role$description))
            )
          )
        )
      }),

      br(),
      fluidRow(
        column(6,
          actionButton(ns("ep0_skip"), i18n$t("common.buttons.skip"), icon = icon("forward"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.tooltip_skip_role"))
        ),
        column(6,
          actionButton(ns("ep0_continue"), i18n$t("modules.entry_point.continue_to_ep1"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.proceed_to_identify_your_basic_human_needs"))
        )
      )
    )
  )
}

render_ep1 <- function(ns, rv, i18n) {
  fluidRow(
    column(12,
      div(
        h2(icon("heart"), " ", i18n$t("modules.entry_point.entry_point_1_why_do_you_care")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("modules.entry_point.understanding_the_fundamental_human_need_behind_yo")
        )
      ),
      p(class = "text-muted", i18n$t("modules.entry_point.what_basic_human_need_drives_your_question_multipl")),
      br(),

      lapply(EP1_BASIC_NEEDS, function(need) {
        div(
          class = if(need$id %in% rv$ep1_selected) "ep-card selected" else "ep-card",
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("ep1_need_click"), need$id),
          style = sprintf("border-left: 5px solid %s;", sanitize_color(need$color)),
          `data-toggle` = "tooltip",
          `data-placement` = "top",
          title = paste0(i18n$t(need$label), ": ", i18n$t(need$description)),
          h4(i18n$t(need$label)),
          p(i18n$t(need$description))
        )
      }),

      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep1_back"), i18n$t("common.buttons.back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.return_to_role_selection"))
        ),
        column(4,
          actionButton(ns("ep1_skip"), i18n$t("common.buttons.skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.tooltip_skip_needs"))
        ),
        column(4,
          actionButton(ns("ep1_continue"), i18n$t("common.buttons.continue"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.proceed_to_specify_activities_and_risks"))
        )
      )
    )
  )
}

render_ep23 <- function(ns, rv, i18n) {
  fluidRow(
    column(6,
      div(
        h3(icon("industry"), " ", i18n$t("modules.entry_point.ep2_activity_sectors")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("modules.entry_point.tooltip_activities")
        )
      ),
      p(class = "text-muted", style = "font-size: 0.9em;", i18n$t("modules.entry_point.select_all_that_apply_multiple_selection_allowed")),
      checkboxGroupInput(ns("ep2_activities"), NULL,
        choices = setNames(sapply(EP2_ACTIVITY_SECTORS, function(x) x$id),
                          sapply(EP2_ACTIVITY_SECTORS, function(x) i18n$t(x$label))),
        selected = rv$ep2_selected)
    ),
    column(6,
      div(
        h3(icon("exclamation-triangle"), " ", i18n$t("modules.entry_point.ep3_risks_hazards")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("modules.entry_point.tooltip_risks")
        )
      ),
      p(class = "text-muted", style = "font-size: 0.9em;", i18n$t("modules.entry_point.select_all_that_apply_multiple_selection_allowed")),
      checkboxGroupInput(ns("ep3_risks"), NULL,
        choices = setNames(sapply(EP3_RISKS_HAZARDS, function(x) x$id),
                          sapply(EP3_RISKS_HAZARDS, function(x) i18n$t(x$label))),
        selected = rv$ep3_selected)
    ),
    column(12,
      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep23_back"), i18n$t("common.buttons.back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.return_to_basic_needs"))
        ),
        column(4,
          actionButton(ns("ep23_skip"), i18n$t("common.buttons.skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.skip_if_you_want_to_explore_all_activities_and_risks"))
        ),
        column(4,
          actionButton(ns("ep23_continue"), i18n$t("common.buttons.continue"), icon = icon("arrow-right"), class = "btn-primary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.proceed_to_select_knowledge_topics"))
        )
      )
    )
  )
}

render_ep4 <- function(ns, rv, i18n) {
  fluidRow(
    column(12,
      div(
        h2(icon("book-open"), " ", i18n$t("modules.entry_point.entry_point_4_knowledge_domain")),
        span(
          icon("info-circle", style = "color: #3498db; cursor: help; margin-left: 10px;"),
          `data-toggle` = "tooltip",
          `data-placement` = "right",
          title = i18n$t("modules.entry_point.select_the_knowledge_domains_and_analytical_approa")
        )
      ),
      p(class = "text-muted", i18n$t("modules.entry_point.what_topic_areas_are_you_interested_in_select_all_that_apply")),
      br(),

      checkboxGroupInput(ns("ep4_topics"), NULL,
        choices = setNames(sapply(EP4_TOPICS, function(x) x$id),
                          sapply(EP4_TOPICS, function(x) i18n$t(x$label))),
        selected = rv$ep4_selected),

      br(),
      fluidRow(
        column(4,
          actionButton(ns("ep4_back"), i18n$t("common.buttons.back"), icon = icon("arrow-left"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.return_to_activities_and_risks"))
        ),
        column(4,
          actionButton(ns("ep4_skip"), i18n$t("common.buttons.skip"), icon = icon("forward"), class = "btn-warning btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.skip_to_see_all_available_tools"))
        ),
        column(4,
          actionButton(ns("ep4_get_recommendations"), i18n$t("modules.entry_point.get_recommendations"),
                      icon = icon("magic"), class = "btn-success btn-lg btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.get_personalized_tool_recommendations_based_on_your_pathway"))
        )
      )
    )
  )
}

render_recommendations_screen <- function(ns, rv, user_level = "intermediate", i18n) {
  # Get recommended tools based on pathway and user level
  recommended_tools <- get_tool_recommendations(rv, user_level, i18n)

  fluidRow(
    column(12,
      h2(icon("star"), " ", i18n$t("modules.entry_point.recommended_tools_for_your_marine_management_question")),

      bs4Card(
        title = i18n$t("modules.entry_point.your_pathway_summary"),
        status = "info",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        # Add ribbon to highlight this as starting point
        ribbon = bs4Ribbon(
          text = "START HERE",
          color = "success"
        ),

        tags$ul(
          if (length(rv$ep0_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.role"), " "),
            paste(sapply(rv$ep0_selected, function(id)
              i18n$t(EP0_MANAGER_ROLES[[which(sapply(EP0_MANAGER_ROLES, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep1_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.need"), " "),
            paste(sapply(rv$ep1_selected, function(id)
              i18n$t(EP1_BASIC_NEEDS[[which(sapply(EP1_BASIC_NEEDS, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep2_selected) > 0) tags$li(strong(i18n$t("modules.response.measures.activities"), " "),
            paste(sapply(rv$ep2_selected, function(id)
              i18n$t(EP2_ACTIVITY_SECTORS[[which(sapply(EP2_ACTIVITY_SECTORS, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep3_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.risks"), " "),
            paste(sapply(rv$ep3_selected, function(id)
              i18n$t(EP3_RISKS_HAZARDS[[which(sapply(EP3_RISKS_HAZARDS, function(x) x$id) == id)]]$label)), collapse = ", ")),
          if (length(rv$ep4_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.topics"), " "),
            paste(sapply(rv$ep4_selected, function(id)
              i18n$t(EP4_TOPICS[[which(sapply(EP4_TOPICS, function(x) x$id) == id)]]$label)), collapse = ", "))
        )
      ),

      h3(icon("tools"), " ", i18n$t("modules.entry_point.recommended_workflow")),
      p(class = "text-muted", i18n$t("modules.entry_point.follow_this_sequence_of_tools_to_address_your_mari")),

      # Render recommended tools in priority order
      lapply(seq_along(recommended_tools), function(i) {
        tool <- recommended_tools[[i]]
        priority_class <- if (i == 1) "success" else if (i == 2) "info" else "warning"
        priority_icon <- if (i == 1) "star" else if (i == 2) "check-circle" else "tools"
        priority_label <- if (i == 1) i18n$t("modules.entry_point.ep_priority_start_here")
                          else if (i == 2) i18n$t("modules.entry_point.ep_priority_next_step")
                          else i18n$t("modules.entry_point.ep_priority_also_relevant")

        div(
          class = paste0("alert alert-", priority_class),
          div(
            style = "display: flex; justify-content: space-between; align-items: center;",
            div(
              span(class = "badge badge-light", style = "font-size: 0.9em; margin-right: 10px;",
                   paste0(i, ". ", priority_label)),
              h4(style = "display: inline; margin: 0;", icon(priority_icon), " ", tool$name)
            )
          ),
          p(style = "margin-top: 10px; margin-bottom: 10px;", tool$description),
          div(
            style = "font-size: 0.85em; color: #666;",
            icon("clock"), " ", tool$time_required, " | ",
            icon("signal"), " ", i18n$t("modules.entry_point.skill"), " ", tool$skill_level, " | ",
            icon("graduation-cap"), " ", tool$use_case
          ),
          br(),
          actionButton(ns(paste0("goto_", tool$id)), paste(i18n$t("modules.entry_point.go_to"), tool$name),
                      class = paste0("btn-", priority_class),
                      icon = icon("arrow-right"))
        )
      }),

      hr(),
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
        h4(icon("lightbulb"), " ", i18n$t("modules.entry_point.suggested_workflow")),
        tags$ol(
          tags$li(strong(i18n$t("modules.entry_point.start_with_pims"), " "), i18n$t("modules.entry_point.define_your_project_goals_stakeholders_and_timeline")),
          tags$li(strong(i18n$t("modules.entry_point.quick_start_option"), " "), i18n$t("modules.entry_point.use_create_ses_with_templates_or_ai_assistant_for_")),
          tags$li(strong(i18n$t("modules.entry_point.build_your_ses_model"), " "), i18n$t("modules.entry_point.use_isa_dat_entry_to_map_dapsiwrm_elements_with_co")),
          tags$li(strong(i18n$t("modules.entry_point.visualize_analyze"), " "), i18n$t("modules.entry_point.create_cld_networks_with_confidence_based_visual_f")),
          tags$li(strong(i18n$t("modules.entry_point.refine_communicate"), " "), i18n$t("modules.entry_point.simplify_models_and_develop_management_scenarios"))
        ),
        tags$div(
          class = "alert alert-info",
          style = "margin-top: 15px; margin-bottom: 0;",
          icon("star"), " ",
          tags$strong(i18n$t("modules.entry_point.new_in_v120"), " "),
          i18n$t("modules.entry_point.confidence_property_system_allows_you_to_track_dat")
        )
      ),

      br(),
      fluidRow(
        column(6,
          actionButton(ns("start_over"), i18n$t("modules.entry_point.start_over"), icon = icon("redo"), class = "btn-secondary btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.ep_tooltip_begin_new_pathway"))
        ),
        column(6,
          actionButton(ns("export_pathway"), i18n$t("modules.entry_point.export_pathway_report"), icon = icon("download"),
                      class = "btn-info btn-block",
                      `data-toggle` = "tooltip", title = i18n$t("modules.entry_point.ep_tooltip_download_pdf"))
        )
      )
    )
  )
}

# Helper function to recommend tools based on user pathway and experience level
get_tool_recommendations <- function(rv, user_level = "intermediate", i18n = NULL) {
  # Fallback: if i18n not provided, create a passthrough that returns the key
  if (is.null(i18n)) {
    i18n <- list(t = function(key) key)
  }
  tools <- list()

  # BEGINNER LEVEL: Simplify recommendations - focus on quick start tools
  if (user_level == "beginner") {
    # For beginners, prioritize AI Assistant and Template creation
    tools[[length(tools) + 1]] <- list(
      id = "create_ses_ai",
      name = i18n$t("modules.entry_point.tool_create_ses_ai_name"),
      description = i18n$t("modules.entry_point.tool_create_ses_ai_desc"),
      time_required = "20-40 minutes",
      skill_level = i18n$t("modules.entry_point.tool_create_ses_ai_skill"),
      use_case = i18n$t("modules.entry_point.tool_create_ses_ai_usecase"),
      menu_id = "create_ses_ai"
    )

    tools[[length(tools) + 1]] <- list(
      id = "create_ses_template",
      name = i18n$t("modules.entry_point.tool_create_ses_template_name"),
      description = i18n$t("modules.entry_point.tool_create_ses_template_desc"),
      time_required = "15-30 minutes",
      skill_level = i18n$t("modules.entry_point.tool_create_ses_template_skill"),
      use_case = i18n$t("modules.entry_point.tool_create_ses_template_usecase"),
      menu_id = "create_ses_template"
    )

    # CLD Visualization
    tools[[length(tools) + 1]] <- list(
      id = "cld",
      name = i18n$t("modules.entry_point.tool_cld_name"),
      description = i18n$t("modules.entry_point.tool_cld_desc"),
      time_required = "10-20 minutes",
      skill_level = i18n$t("modules.entry_point.tool_cld_skill"),
      use_case = i18n$t("modules.entry_point.tool_cld_usecase"),
      menu_id = "cld_viz"
    )

    # Only show Loop Detection for beginners
    tools[[length(tools) + 1]] <- list(
      id = "loops",
      name = i18n$t("modules.entry_point.tool_loops_name"),
      description = i18n$t("modules.entry_point.tool_loops_desc"),
      time_required = "15-30 minutes",
      skill_level = i18n$t("modules.entry_point.tool_loops_skill"),
      use_case = i18n$t("modules.entry_point.tool_loops_usecase"),
      menu_id = "analysis_loops"
    )

    # Leverage Points for beginners
    tools[[length(tools) + 1]] <- list(
      id = "leverage",
      name = i18n$t("modules.entry_point.tool_leverage_name"),
      description = i18n$t("modules.entry_point.tool_leverage_desc"),
      time_required = "20-30 minutes",
      skill_level = i18n$t("modules.entry_point.tool_leverage_skill"),
      use_case = i18n$t("modules.entry_point.tool_leverage_usecase"),
      menu_id = "analysis_leverage"
    )

    return(tools)
  }

  # INTERMEDIATE/EXPERT LEVEL: Full recommendations based on pathway
  tools <- list()

  # PIMS - Recommended for project planning (especially for policy creators, advisors, educators)
  if (is.null(rv$ep0_selected) || rv$ep0_selected %in% c("policy_creator", "policy_advisor", "educator")) {
    tools[[length(tools) + 1]] <- list(
      id = "pims",
      name = i18n$t("modules.entry_point.tool_pims_name"),
      description = i18n$t("modules.entry_point.tool_pims_desc"),
      time_required = "30-60 minutes",
      skill_level = i18n$t("modules.entry_point.tool_pims_skill"),
      use_case = i18n$t("modules.entry_point.tool_pims_usecase"),
      menu_id = "pims_project"
    )
  }

  # Create SES - Quick start with templates or AI
  tools[[length(tools) + 1]] <- list(
    id = "create_ses",
    name = i18n$t("modules.entry_point.tool_create_ses_name"),
    description = i18n$t("modules.entry_point.tool_create_ses_desc"),
    time_required = "15-45 minutes",
    skill_level = i18n$t("modules.entry_point.tool_create_ses_skill"),
    use_case = i18n$t("modules.entry_point.tool_create_ses_usecase"),
    menu_id = "create_ses_choose"
  )

  # ISA Data Entry - Core tool for all pathways
  tools[[length(tools) + 1]] <- list(
    id = "isa",
    name = i18n$t("modules.entry_point.tool_isa_name"),
    description = i18n$t("modules.entry_point.tool_isa_desc"),
    time_required = "1-3 hours",
    skill_level = i18n$t("modules.entry_point.tool_isa_skill"),
    use_case = i18n$t("modules.entry_point.tool_isa_usecase"),
    menu_id = "create_ses_standard"
  )

  # CLD Visualization - Follows ISA
  tools[[length(tools) + 1]] <- list(
    id = "cld",
    name = i18n$t("modules.entry_point.tool_cld_viz_name"),
    description = i18n$t("modules.entry_point.tool_cld_viz_desc"),
    time_required = "15-30 minutes",
    skill_level = i18n$t("modules.entry_point.tool_cld_viz_skill"),
    use_case = i18n$t("modules.entry_point.tool_cld_viz_usecase"),
    menu_id = "cld_viz"
  )

  # Topics-based recommendations
  if (length(rv$ep4_selected) > 0) {
    topic_ids <- rv$ep4_selected

    # If Ecosystem Structure & Functioning selected → Loop Detection
    if (any(grepl("ecosystem_structure|basic_concepts", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "loops",
        name = i18n$t("modules.entry_point.tool_loop_detection_name"),
        description = i18n$t("modules.entry_point.tool_loop_detection_desc"),
        time_required = "30-60 minutes",
        skill_level = i18n$t("modules.entry_point.tool_loop_detection_skill"),
        use_case = i18n$t("modules.entry_point.tool_loop_detection_usecase"),
        menu_id = "analysis_loops"
      )
    }

    # If Methods/Tools selected → Network Metrics
    if (any(grepl("methods_tools|scientific_skills", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "metrics",
        name = i18n$t("modules.entry_point.tool_metrics_name"),
        description = i18n$t("modules.entry_point.tool_metrics_desc"),
        time_required = "20-45 minutes",
        skill_level = i18n$t("modules.entry_point.tool_metrics_skill"),
        use_case = i18n$t("modules.entry_point.tool_metrics_usecase"),
        menu_id = "analysis_metrics"
      )
    }

    # If Climate Change or Other Anthropogenic Effects → BOT Analysis
    if (any(grepl("climate_change|anthropogenic_effects|ecosystem_recovery", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "bot",
        name = i18n$t("modules.entry_point.tool_bot_name"),
        description = i18n$t("modules.entry_point.tool_bot_desc"),
        time_required = "45-90 minutes",
        skill_level = i18n$t("modules.entry_point.tool_bot_skill"),
        use_case = i18n$t("modules.entry_point.tool_bot_usecase"),
        menu_id = "analysis_bot"
      )
    }

    # If Governance/Policy selected → Scenario Builder
    if (any(grepl("policy_|governance|marine_planning", topic_ids))) {
      tools[[length(tools) + 1]] <- list(
        id = "scenarios",
        name = i18n$t("modules.entry_point.tool_scenarios_name"),
        description = i18n$t("modules.entry_point.tool_scenarios_desc"),
        time_required = "1-2 hours",
        skill_level = i18n$t("modules.entry_point.tool_scenarios_skill"),
        use_case = i18n$t("modules.entry_point.tool_scenarios_usecase"),
        menu_id = "response_scenarios"
      )
    }
  }

  # Model Simplification - Recommended for communication needs
  if (length(rv$ep0_selected) > 0 && any(rv$ep0_selected %in% c("policy_creator", "educator", "engo"))) {
    tools[[length(tools) + 1]] <- list(
      id = "simplification",
      name = i18n$t("modules.entry_point.tool_simplification_name"),
      description = i18n$t("modules.entry_point.tool_simplification_desc"),
      time_required = "30-45 minutes",
      skill_level = i18n$t("modules.entry_point.tool_simplification_skill"),
      use_case = i18n$t("modules.entry_point.tool_simplification_usecase"),
      menu_id = "analysis_simplify"
    )
  }

  # Ensure we have at least 3 recommendations
  if (length(tools) < 3) {
    # Add CLD if not already there
    if (!any(sapply(tools, function(t) t$id == "cld"))) {
      tools[[length(tools) + 1]] <- list(
        id = "cld",
        name = i18n$t("modules.entry_point.tool_cld_viz_name"),
        description = i18n$t("modules.entry_point.tool_cld_fallback_desc"),
        time_required = "15-30 minutes",
        skill_level = i18n$t("modules.entry_point.tool_cld_fallback_skill"),
        use_case = i18n$t("modules.entry_point.tool_cld_fallback_usecase"),
        menu_id = "cld_viz"
      )
    }
  }

  return(tools)
}
