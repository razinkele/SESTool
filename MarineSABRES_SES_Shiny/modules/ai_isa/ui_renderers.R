# modules/ai_isa/ui_renderers.R
# AI ISA Assistant - UI Renderers
# Purpose: Render breadcrumb navigation, progress bar, element counts,
#          DAPSI(W)R(M) diagram, and connection types summary
#
# Extracted from ai_isa_assistant_module.R for better maintainability

#' Setup UI Renderers
#'
#' Registers renderUI/renderText outputs for breadcrumb nav, progress bar,
#' element counts, DAPSI(W)R(M) flow diagram, and connection types summary.
#' Also registers breadcrumb navigation observers.
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param rv Reactive values containing AI ISA state
#' @param i18n i18n translator object
#' @param QUESTION_FLOW Question flow definition list
setup_ui_renderers <- function(input, output, session, rv, i18n, QUESTION_FLOW) {

  # ========== BREADCRUMB NAVIGATION ==========

  output$breadcrumb_nav <- renderUI({
    if (rv$current_step <= 0) return(NULL)

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
      breadcrumbs[[length(breadcrumbs) + 1]] <- tags$span(class = "separator", "\u203a")

      if (i < rv$current_step) {
        breadcrumbs[[length(breadcrumbs) + 1]] <- tags$a(
          href = "#",
          onclick = sprintf("Shiny.setInputValue('%s', %d)", session$ns("goto_step"), i - 1),
          step_info$title
        )
      } else {
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
    debug_log("[AI ISA] Breadcrumb: Returning to start")
    rv$current_step <- 0
    rv$selected_issues <- character(0)
  })

  # Handle breadcrumb navigation - go to specific step
  observeEvent(input$goto_step, {
    target_step <- input$goto_step
    if (!is.null(target_step) && target_step >= 0 && target_step < rv$current_step) {
      debug_log(sprintf("[AI ISA] Breadcrumb: Going back to step %d from step %d",
                 target_step, rv$current_step))

      if (rv$current_step == 10 && target_step < 10) {
        debug_log("[AI ISA] Breadcrumb: Clearing connections for regeneration")
        rv$suggested_connections <- list()
        rv$approved_connections <- list()
      }

      rv$current_step <- target_step

      if (target_step == 1) {
        if (length(rv$context$main_issue) > 0) {
          rv$selected_issues <- rv$context$main_issue
        } else {
          rv$selected_issues <- character(0)
        }
      } else if (target_step < 1) {
        rv$selected_issues <- character(0)
      }

      rv$render_counter <- (rv$render_counter %||% 0) + 1
    }
  })

  # ========== PROGRESS BAR ==========

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

  # ========== ELEMENT COUNTS ==========

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

  output$count_drivers <- renderText({ length(rv$elements$drivers) })
  output$count_activities <- renderText({ length(rv$elements$activities) })
  output$count_pressures <- renderText({ length(rv$elements$pressures) })
  output$count_states <- renderText({ length(rv$elements$states) })
  output$count_impacts <- renderText({ length(rv$elements$impacts) })
  output$count_welfare <- renderText({ length(rv$elements$welfare) })
  output$count_responses <- renderText({ length(rv$elements$responses) })
  output$count_connections <- renderText({ length(rv$approved_connections) })

  # ========== CONNECTION TYPES SUMMARY ==========

  output$connection_types_summary <- renderUI({
    count_by_matrix <- function(matrix_name) {
      suggested_count <- 0
      approved_count <- 0

      if (!is.null(rv$suggested_connections) && length(rv$suggested_connections) > 0) {
        suggested_count <- sum(sapply(rv$suggested_connections, function(conn) {
          if (is.list(conn) && !is.null(conn$matrix)) {
            isTRUE(conn$matrix == matrix_name)
          } else {
            FALSE
          }
        }))
      }

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

    count_da <- count_by_matrix("d_a")
    count_ap <- count_by_matrix("a_p")
    count_ps <- count_by_matrix("p_mpf")
    count_si <- count_by_matrix("mpf_es")
    count_iw <- count_by_matrix("es_gb")
    count_wr <- count_by_matrix("gb_r")
    count_rd <- count_by_matrix("r_d")
    count_ra <- count_by_matrix("r_a")
    count_rp <- count_by_matrix("r_p")

    tagList(
      tags$div(style = CSS_LABEL_BOLD, sprintf("D\u2192A: %d", count_da)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("A\u2192P: %d", count_ap)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("P\u2192S: %d", count_ps)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("S\u2192I: %d", count_si)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("I\u2192W: %d", count_iw)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("W\u2192R: %d", count_wr)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("R\u2192D: %d", count_rd)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("R\u2192A: %d", count_ra)),
      tags$div(style = CSS_LABEL_BOLD, sprintf("R\u2192P: %d", count_rp))
    )
  })

  # ========== DAPSI(W)R(M) FLOW DIAGRAM ==========

  output$dapsiwrm_diagram <- renderUI({
    div(class = "dapsiwrm-diagram",
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #776db3; color: #776db3;",
        paste0("D: ", length(rv$elements$drivers))),
      div(class = "dapsiwrm-arrow", "\u2193"),
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #5abc67; color: #5abc67;",
        paste0("A: ", length(rv$elements$activities))),
      div(class = "dapsiwrm-arrow", "\u2193"),
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #fec05a; color: #fec05a;",
        paste0("P: ", length(rv$elements$pressures))),
      div(class = "dapsiwrm-arrow", "\u2193"),
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #bce2ee; color: #5ab4d9;",
        paste0("S: ", length(rv$elements$states))),
      div(class = "dapsiwrm-arrow", "\u2193"),
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #313695; color: #313695;",
        paste0("I: ", length(rv$elements$impacts))),
      div(class = "dapsiwrm-arrow", "\u2193"),
      div(class = "dapsiwrm-box", style = "background: #fff1a2; border-color: #f0c808; color: #666;",
        paste0("W: ", length(rv$elements$welfare))),
      div(class = "dapsiwrm-arrow", "\u2191"),
      div(class = "dapsiwrm-box", style = "background: #f0f0f0; border-color: #66c2a5; color: #66c2a5;",
        paste0("R/M: ", length(rv$elements$responses)))
    )
  })

  # ========== STEP TITLE ==========

  output$step_title <- renderUI({
    if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
      step_info <- QUESTION_FLOW[[rv$current_step + 1]]
      HTML(paste0("<h4>Step ", rv$current_step + 1, " of ", length(QUESTION_FLOW), ": ", htmltools::htmlEscape(step_info$title), "</h4>"))
    } else {
      HTML("<h4>Complete! Review your model</h4>")
    }
  })
}
