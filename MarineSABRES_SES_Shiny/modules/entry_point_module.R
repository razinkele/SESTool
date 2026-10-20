# =============================================================================
# MODULE: Entry Point System
# File: modules/entry_point_module.R
# =============================================================================
#
# Purpose:
#   Simplified Entry Point System for Marine Management DSS & Toolbox.
#   Guides users through EP0-EP4 to find appropriate tools based on their
#   data availability and analysis needs.
#
# Dependencies:
#   - www/entry-point.css (custom styling)
#
# Exports:
#   - entry_point_ui(id, i18n)
#   - entry_point_server(id, project_data, i18n, event_bus)
#
# =============================================================================

# =============================================================================
# UI FUNCTION
# =============================================================================

#' Entry Point System UI
#'
#' @param id Character. Module namespace ID
#' @param i18n Translator object for internationalization
#' @return A Shiny UI element with entry point navigation
#' @export
entry_point_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  fluidPage(
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

entry_point_server <- function(id, project_data_reactive, i18n, parent_session = NULL, user_level_reactive = NULL, event_bus = NULL) {
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

    # Checkbox ticks are copied into rv only when the user leaves the step.
    # The guided screen's renderUI reads rv$ep*_selected (to restore ticks on
    # Back), so copying on every tick re-rendered the whole screen: the boxes
    # flickered and ticks made during a re-render were lost (user feedback
    # 2026-10-13). Skip clears the step, as on EP0/EP1.
    commit_ep23 <- function() {
      rv$ep2_selected <- input$ep2_activities %||% c()
      rv$ep3_selected <- input$ep3_risks %||% c()
    }
    commit_ep4 <- function() {
      rv$ep4_selected <- input$ep4_topics %||% c()
    }

    # ========== EP2-3 ACTIONS ==========
    observeEvent(input$ep23_back, {
      commit_ep23()
      rv$current_step <- 1
    })

    observeEvent(input$ep23_continue, {
      commit_ep23()
      rv$current_step <- 4
    })

    observeEvent(input$ep23_skip, {
      rv$ep2_selected <- c()
      rv$ep3_selected <- c()
      rv$current_step <- 4
    })

    # ========== EP4 ACTIONS ==========
    observeEvent(input$ep4_back, {
      commit_ep4()
      rv$current_step <- 2
    })

    observeEvent(input$ep4_get_recommendations, {
      commit_ep4()
      rv$current_screen <- "recommendations"
    })

    observeEvent(input$ep4_skip, {
      rv$ep4_selected <- c()
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
            ep_option_label("ep0", EP0_MANAGER_ROLES, id, i18n)
          })
          pathway_summary <- c(pathway_summary, paste("Role:", paste(role_labels, collapse = ", ")))
        }

        if (length(rv$ep1_selected) > 0) {
          need_labels <- sapply(rv$ep1_selected, function(id) {
            ep_option_label("ep1", EP1_BASIC_NEEDS, id, i18n)
          })
          pathway_summary <- c(pathway_summary, paste("Need:", paste(need_labels, collapse = ", ")))
        }

        if (length(rv$ep2_selected) > 0) {
          activity_labels <- sapply(rv$ep2_selected, function(id) {
            ep_option_label("ep2", EP2_ACTIVITY_SECTORS, id, i18n)
          })
          pathway_summary <- c(pathway_summary, paste("Activities:", paste(activity_labels, collapse = ", ")))
        }

        if (length(rv$ep3_selected) > 0) {
          risk_labels <- sapply(rv$ep3_selected, function(id) {
            ep_option_label("ep3", EP3_RISKS_HAZARDS, id, i18n)
          })
          pathway_summary <- c(pathway_summary, paste("Risks:", paste(risk_labels, collapse = ", ")))
        }

        if (length(rv$ep4_selected) > 0) {
          topic_labels <- sapply(rv$ep4_selected, function(id) {
            ep_option_label("ep4", EP4_TOPICS, id, i18n)
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
          format_user_error(e, i18n = i18n, context_key = "common.messages.context_generating_pathway_report"),
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
          column(12,
            div(
              class = "ep-card start-here-highlight",
              style = "max-width: 600px; margin: 0 auto;",
              div(
                class = "start-here-badge",
                icon("star"), " ", i18n$t("modules.entry_point.start_here")
              ),
              h3(icon("route"), " ", i18n$t("modules.entry_point.guided_pathway")),
              p(i18n$t("modules.entry_point.step_by_step_guidance_through_the_entry_points")),
              actionButton(ns("start_guided"), i18n$t("modules.entry_point.start_guided_journey"),
                          icon = icon("play"), class = "btn-primary btn-lg btn-block")
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
            p(i18n$t("modules.entry_point.faq_started_answer_2"))
          ),
          bs4AccordionItem(
            title = i18n$t("modules.entry_point.faq_expertise_question"),
            status = "secondary",
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

# Translated text of an entry-point option. config/entry_points.R holds the
# English; translations are keyed by step and option id,
# modules.entry_point.<ep>.<id>.<label|description|taskN>
# (translations/modules/entry_point_options.json). The English config text
# was used as the key before, so every option stayed English in all other
# languages (user feedback 2026-10-13 "Language error").
ep_option_text <- function(ep, item, field, i18n, fallback = item[[field]]) {
  key <- paste("modules.entry_point", ep, item$id, field, sep = ".")
  txt <- i18n$t(key)
  if (is.null(txt) || !nzchar(txt) || identical(txt, key)) fallback %||% "" else txt
}

ep_option_label <- function(ep, options, id, i18n) {
  item <- options[[which(vapply(options, function(x) x$id, "") == id)]]
  ep_option_text(ep, item, "label", i18n)
}

# Keys looked up dynamically by ep_option_text(), listed for the i18n audit:
# i18n-ref: modules.entry_point.ep0.policy_creator.label
# i18n-ref: modules.entry_point.ep0.policy_creator.description
# i18n-ref: modules.entry_point.ep0.policy_creator.task1
# i18n-ref: modules.entry_point.ep0.policy_creator.task2
# i18n-ref: modules.entry_point.ep0.policy_creator.task3
# i18n-ref: modules.entry_point.ep0.policy_implementer.label
# i18n-ref: modules.entry_point.ep0.policy_implementer.description
# i18n-ref: modules.entry_point.ep0.policy_implementer.task1
# i18n-ref: modules.entry_point.ep0.policy_implementer.task2
# i18n-ref: modules.entry_point.ep0.policy_implementer.task3
# i18n-ref: modules.entry_point.ep0.policy_advisor.label
# i18n-ref: modules.entry_point.ep0.policy_advisor.description
# i18n-ref: modules.entry_point.ep0.policy_advisor.task1
# i18n-ref: modules.entry_point.ep0.policy_advisor.task2
# i18n-ref: modules.entry_point.ep0.policy_advisor.task3
# i18n-ref: modules.entry_point.ep0.activity_manager.label
# i18n-ref: modules.entry_point.ep0.activity_manager.description
# i18n-ref: modules.entry_point.ep0.activity_manager.task1
# i18n-ref: modules.entry_point.ep0.activity_manager.task2
# i18n-ref: modules.entry_point.ep0.activity_manager.task3
# i18n-ref: modules.entry_point.ep0.activity_advisor.label
# i18n-ref: modules.entry_point.ep0.activity_advisor.description
# i18n-ref: modules.entry_point.ep0.activity_advisor.task1
# i18n-ref: modules.entry_point.ep0.activity_advisor.task2
# i18n-ref: modules.entry_point.ep0.activity_advisor.task3
# i18n-ref: modules.entry_point.ep0.engo_worker.label
# i18n-ref: modules.entry_point.ep0.engo_worker.description
# i18n-ref: modules.entry_point.ep0.engo_worker.task1
# i18n-ref: modules.entry_point.ep0.engo_worker.task2
# i18n-ref: modules.entry_point.ep0.engo_worker.task3
# i18n-ref: modules.entry_point.ep0.fisher.label
# i18n-ref: modules.entry_point.ep0.fisher.description
# i18n-ref: modules.entry_point.ep0.fisher.task1
# i18n-ref: modules.entry_point.ep0.fisher.task2
# i18n-ref: modules.entry_point.ep0.fisher.task3
# i18n-ref: modules.entry_point.ep0.other_industry.label
# i18n-ref: modules.entry_point.ep0.other_industry.description
# i18n-ref: modules.entry_point.ep0.other_industry.task1
# i18n-ref: modules.entry_point.ep0.other_industry.task2
# i18n-ref: modules.entry_point.ep0.other_industry.task3
# i18n-ref: modules.entry_point.ep0.sme.label
# i18n-ref: modules.entry_point.ep0.sme.description
# i18n-ref: modules.entry_point.ep0.sme.task1
# i18n-ref: modules.entry_point.ep0.sme.task2
# i18n-ref: modules.entry_point.ep0.sme.task3
# i18n-ref: modules.entry_point.ep0.educator_researcher.label
# i18n-ref: modules.entry_point.ep0.educator_researcher.description
# i18n-ref: modules.entry_point.ep0.educator_researcher.task1
# i18n-ref: modules.entry_point.ep0.educator_researcher.task2
# i18n-ref: modules.entry_point.ep0.educator_researcher.task3
# i18n-ref: modules.entry_point.ep1.welfare.label
# i18n-ref: modules.entry_point.ep1.welfare.description
# i18n-ref: modules.entry_point.ep1.resource_provision.label
# i18n-ref: modules.entry_point.ep1.resource_provision.description
# i18n-ref: modules.entry_point.ep1.employment.label
# i18n-ref: modules.entry_point.ep1.employment.description
# i18n-ref: modules.entry_point.ep1.enjoyment.label
# i18n-ref: modules.entry_point.ep1.enjoyment.description
# i18n-ref: modules.entry_point.ep2.physical_restructuring.label
# i18n-ref: modules.entry_point.ep2.nonliving_extraction.label
# i18n-ref: modules.entry_point.ep2.energy_production.label
# i18n-ref: modules.entry_point.ep2.living_extraction.label
# i18n-ref: modules.entry_point.ep2.cultivation.label
# i18n-ref: modules.entry_point.ep2.transport.label
# i18n-ref: modules.entry_point.ep2.urban_industrial.label
# i18n-ref: modules.entry_point.ep2.tourism_leisure.label
# i18n-ref: modules.entry_point.ep2.security_defense.label
# i18n-ref: modules.entry_point.ep2.education_research.label
# i18n-ref: modules.entry_point.ep2.conservation_restoration.label
# i18n-ref: modules.entry_point.ep2.mixed_use.label
# i18n-ref: modules.entry_point.ep3.hydro_flood.label
# i18n-ref: modules.entry_point.ep3.physio_natural_chronic.label
# i18n-ref: modules.entry_point.ep3.physio_human_chronic.label
# i18n-ref: modules.entry_point.ep3.physio_acute.label
# i18n-ref: modules.entry_point.ep3.climate_acute.label
# i18n-ref: modules.entry_point.ep3.climate_chronic.label
# i18n-ref: modules.entry_point.ep3.tectonic_acute.label
# i18n-ref: modules.entry_point.ep3.tectonic_chronic.label
# i18n-ref: modules.entry_point.ep3.bio_micro.label
# i18n-ref: modules.entry_point.ep3.bio_macro.label
# i18n-ref: modules.entry_point.ep3.tech_introduced.label
# i18n-ref: modules.entry_point.ep3.tech_extractive.label
# i18n-ref: modules.entry_point.ep3.chem_acute.label
# i18n-ref: modules.entry_point.ep3.chem_chronic.label
# i18n-ref: modules.entry_point.ep3.geopolitical_acute.label
# i18n-ref: modules.entry_point.ep3.geopolitical_chronic.label
# i18n-ref: modules.entry_point.ep3.social_inequality.label
# i18n-ref: modules.entry_point.ep3.food_insecurity.label
# i18n-ref: modules.entry_point.ep3.health_wellbeing.label
# i18n-ref: modules.entry_point.ep3.cultural_heritage.label
# i18n-ref: modules.entry_point.ep4.basic_concepts.label
# i18n-ref: modules.entry_point.ep4.ecosystem_structure.label
# i18n-ref: modules.entry_point.ep4.ecosystem_services.label
# i18n-ref: modules.entry_point.ep4.biodiversity.label
# i18n-ref: modules.entry_point.ep4.nis.label
# i18n-ref: modules.entry_point.ep4.climate.label
# i18n-ref: modules.entry_point.ep4.anthropogenic_effects.label
# i18n-ref: modules.entry_point.ep4.recovery.label
# i18n-ref: modules.entry_point.ep4.fisheries_econ.label
# i18n-ref: modules.entry_point.ep4.resource_econ.label
# i18n-ref: modules.entry_point.ep4.goods_benefits.label
# i18n-ref: modules.entry_point.ep4.governance.label
# i18n-ref: modules.entry_point.ep4.policy_derivation.label
# i18n-ref: modules.entry_point.ep4.policy_implementation.label
# i18n-ref: modules.entry_point.ep4.conservation.label
# i18n-ref: modules.entry_point.ep4.planning.label
# i18n-ref: modules.entry_point.ep4.societal.label
# i18n-ref: modules.entry_point.ep4.citizenship.label
# i18n-ref: modules.entry_point.ep4.skills_data.label
# i18n-ref: modules.entry_point.ep4.methods.label

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
          title = if (!is.null(role$typical_tasks)) {
            tasks <- vapply(seq_along(role$typical_tasks), function(i)
              ep_option_text("ep0", role, paste0("task", i), i18n, fallback = role$typical_tasks[[i]]), "")
            paste(i18n$t("modules.entry_point.typical_tasks"), paste(tasks, collapse = ", "))
          } else ep_option_text("ep0", role, "description", i18n),
          fluidRow(
            column(2, icon(role$icon, class = "fa-3x", style = "color: #3498db;")),
            column(10,
              h4(ep_option_text("ep0", role, "label", i18n)),
              p(ep_option_text("ep0", role, "description", i18n))
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
          title = paste0(ep_option_text("ep1", need, "label", i18n), ": ",
                         ep_option_text("ep1", need, "description", i18n)),
          h4(ep_option_text("ep1", need, "label", i18n)),
          p(ep_option_text("ep1", need, "description", i18n))
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
                          sapply(EP2_ACTIVITY_SECTORS, function(x) ep_option_text("ep2", x, "label", i18n))),
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
                          sapply(EP3_RISKS_HAZARDS, function(x) ep_option_text("ep3", x, "label", i18n))),
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
                          sapply(EP4_TOPICS, function(x) ep_option_text("ep4", x, "label", i18n))),
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
              ep_option_label("ep0", EP0_MANAGER_ROLES, id, i18n)), collapse = ", ")),
          if (length(rv$ep1_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.need"), " "),
            paste(sapply(rv$ep1_selected, function(id)
              ep_option_label("ep1", EP1_BASIC_NEEDS, id, i18n)), collapse = ", ")),
          if (length(rv$ep2_selected) > 0) tags$li(strong(i18n$t("modules.response.measures.activities"), " "),
            paste(sapply(rv$ep2_selected, function(id)
              ep_option_label("ep2", EP2_ACTIVITY_SECTORS, id, i18n)), collapse = ", ")),
          if (length(rv$ep3_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.risks"), " "),
            paste(sapply(rv$ep3_selected, function(id)
              ep_option_label("ep3", EP3_RISKS_HAZARDS, id, i18n)), collapse = ", ")),
          if (length(rv$ep4_selected) > 0) tags$li(strong(i18n$t("modules.entry_point.topics"), " "),
            paste(sapply(rv$ep4_selected, function(id)
              ep_option_label("ep4", EP4_TOPICS, id, i18n)), collapse = ", "))
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
