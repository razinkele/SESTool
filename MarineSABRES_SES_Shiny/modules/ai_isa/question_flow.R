# modules/ai_isa/question_flow.R
# AI ISA Question Flow Module
# Purpose: Wizard navigation, session management, and flow control
#
# This module contains the question flow definition, session persistence,
# navigation logic, breadcrumb navigation, progress tracking, and modal dialogs.
#
# Author: Refactored from ai_isa_assistant_module.R
# Date: 2026-01-04
# Dependencies: shiny, i18n, knowledge_base (get_regional_seas_knowledge_base)

# Libraries loaded in global.R: shiny, shinyjs, bs4Dash

# ==============================================================================
# QUESTION FLOW DEFINITION
# ==============================================================================

#' Define AI ISA Question Flow
#'
#' Creates the step-by-step wizard flow for the AI ISA Assistant.
#'
#' @param i18n shiny.i18n translator object
#'
#' @return List of question steps with metadata
#'
#' @details
#' Each step contains:
#' - step: Numeric step index (0-10)
#' - title_key: Translation key for navigation
#' - title: Translated title text
#' - question: AI assistant question text
#' - type: Step type (choice_regional_sea, choice_ecosystem, multiple, connection_review)
#' - target: Target data field (regional_sea, ecosystem_type, drivers, etc.)
#' - use_context_examples: Whether to show context-aware suggestions
#'
#' @export
define_question_flow <- function(i18n) {
  list(
    list(
      step = 0,
      title_key = "regional_sea",
      title = i18n$t("modules.isa.ai_assistant.regional_sea_context"),
      question = i18n$t("modules.isa.ai_assistant.welcome_message"),
      type = "choice_regional_sea",
      target = "regional_sea"
    ),
    list(
      step = 1,
      title_key = "ecosystem",
      title = i18n$t("modules.isa.ai_assistant.ecosystem_type"),
      question = i18n$t("modules.isa.ai_assistant.what_type_of_marine_ecosystem_are_you_studying"),
      type = "choice_ecosystem",
      target = "ecosystem_type"
    ),
    list(
      step = 2,
      title_key = "main_issue",
      title = i18n$t("modules.isa.ai_assistant.main_issue_identification"),
      question = i18n$t("modules.isa.ai_assistant.question_main_issues"),
      type = "choice_with_custom_multiple",  # Changed to support multiple selections
      target = "main_issue"
    ),
    list(
      step = 3,
      title_key = "drivers",
      title = i18n$t("modules.isa.ai_assistant.drivers_societal_needs"),
      question = i18n$t("modules.isa.ai_assistant.question_drivers"),
      type = "multiple",
      target = "drivers",
      use_context_examples = TRUE
    ),
    list(
      step = 4,
      title_key = "activities",
      title = i18n$t("modules.isa.ai_assistant.activities_human_actions"),
      question = i18n$t("modules.isa.ai_assistant.question_activities"),
      type = "multiple",
      target = "activities",
      use_context_examples = TRUE
    ),
    list(
      step = 5,
      title_key = "pressures",
      title = i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors"),
      question = i18n$t("modules.isa.what_pressures_do_these_activities_put_on_the_mari"),
      type = "multiple",
      target = "pressures",
      use_context_examples = TRUE
    ),
    list(
      step = 6,
      title_key = "states",
      title = i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects"),
      question = i18n$t("modules.isa.how_do_these_pressures_change_the_state_of_the_mar"),
      type = "multiple",
      target = "states",
      use_context_examples = TRUE
    ),
    list(
      step = 7,
      title_key = "impacts",
      title = i18n$t("modules.isa.ai_assistant.impacts_effects_on_ecosystem_services"),
      question = i18n$t("modules.isa.what_are_the_impacts_on_ecosystem_services_and_ben"),
      type = "multiple",
      target = "impacts",
      use_context_examples = TRUE
    ),
    list(
      step = 8,
      title_key = "welfare",
      title = i18n$t("modules.isa.ai_assistant.welfare_human_well_being_effects"),
      question = i18n$t("modules.isa.how_do_these_impacts_affect_human_welfare_and_well"),
      type = "multiple",
      target = "welfare",
      use_context_examples = TRUE
    ),
    list(
      step = 9,
      title_key = "responses",
      title = i18n$t("modules.isa.ai_assistant.response_measures_management_policy"),
      question = i18n$t("modules.isa.what_response_measures_management_actions_policies"),
      type = "multiple",
      target = "responses",
      use_context_examples = TRUE
    ),
    list(
      step = 10,
      title_key = "connection_review",
      title = i18n$t("modules.ses.creation.connection_review"),
      question = i18n$t("modules.isa.ai_assistant.connection_review_intro"),
      type = "connection_review",
      target = "connections"
    )
  )
}

# ==============================================================================
# SESSION PERSISTENCE FUNCTIONS
# ==============================================================================
# NOTE: get_session_data() and restore_session_data() are defined in
# modules/ai_isa/data_persistence.R to avoid duplication. They are available
# here because data_persistence.R is sourced in the same module context.

# ==============================================================================
# SESSION INITIALIZATION & RECOVERY
# ==============================================================================

#' Setup Session Initialization Observer
#'
#' Creates an observer that loads recovered ISA data from project_data_reactive.
#' This allows the AI ISA Assistant to restore state after auto-save recovery.
#'
#' @param project_data_reactive Reactive containing project data
#' @param rv ReactiveValues object containing wizard state
#' @param convert_matrices_to_connections Function to convert adjacency matrices
#'
#' @return Observer object
#'
#' @export
setup_session_initialization <- function(project_data_reactive, rv, convert_matrices_to_connections) {
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
          !is.null(isa_data$responses) && nrow(isa_data$responses) > 0
        )

        # Debug: print each element count
        cat(sprintf("[AI ISA] Element counts - drivers: %d, activities: %d, pressures: %d, states: %d, impacts: %d, welfare: %d, responses: %d\n",
          if(!is.null(isa_data$drivers)) nrow(isa_data$drivers) else 0,
          if(!is.null(isa_data$activities)) nrow(isa_data$activities) else 0,
          if(!is.null(isa_data$pressures)) nrow(isa_data$pressures) else 0,
          if(!is.null(isa_data$marine_processes)) nrow(isa_data$marine_processes) else 0,
          if(!is.null(isa_data$ecosystem_services)) nrow(isa_data$ecosystem_services) else 0,
          if(!is.null(isa_data$goods_benefits)) nrow(isa_data$goods_benefits) else 0,
          if(!is.null(isa_data$responses)) nrow(isa_data$responses) else 0
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
          } else if (!is.null(isa_data$adjacency_matrices)) {
            # Convert adjacency matrices to connection list format
            cat("[AI ISA] Converting adjacency matrices to connection list...\n")
            rv$suggested_connections <- convert_matrices_to_connections(
              isa_data$adjacency_matrices,
              rv$elements
            )
            # Mark all as approved since they came from a saved/template source
            rv$approved_connections <- seq_along(rv$suggested_connections)
            cat(sprintf("[AI ISA] Converted %d connections from adjacency matrices (all approved)\n",
                        length(rv$suggested_connections)))
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
            length(rv$elements$responses)
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
}

# ==============================================================================
# AUTO-SAVE FUNCTIONALITY
# ==============================================================================

#' Setup Auto-Save Observer
#'
#' Creates an observer that automatically saves session data to localStorage.
#'
#' @param rv ReactiveValues object containing wizard state
#' @param session Shiny session object
#'
#' @return Observer object
#'
#' @export
setup_auto_save <- function(rv, session) {
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

        session_data <- get_session_data(rv)
        session$sendCustomMessage("save_ai_isa_session", session_data)
        rv$last_save_time <- current_time
      }
    }
  })
}

#' Setup Save/Load Button Handlers
#'
#' Creates observers for manual save/load buttons and handles loaded session data.
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#'
#' @return NULL (sets up observers as side effect)
#'
#' @export
setup_save_load_handlers <- function(input, session, rv, i18n) {
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
}

# ==============================================================================
# NAVIGATION & PROGRESS TRACKING
# ==============================================================================

#' Setup Breadcrumb Navigation
#'
#' Creates breadcrumb navigation UI and handlers for going back to previous steps.
#'
#' @param output Shiny output object
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#' @param QUESTION_FLOW List defining the wizard steps
#'
#' @return NULL (sets up outputs and observers as side effect)
#'
#' @export
setup_breadcrumb_navigation <- function(output, input, session, rv, i18n, QUESTION_FLOW) {
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
      i18n$t("common.buttons.start")
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

      # Clear connections if navigating back from connection review (step 10)
      # This will force regeneration when returning to step 10
      if (rv$current_step == 10 && target_step < 10) {
        cat("[AI ISA] Breadcrumb: Clearing connections for regeneration\n")
        # Don't set timestamp on empty list to prevent reactive loop
        rv$suggested_connections <- list()
        rv$approved_connections <- list()
        cat("[AI ISA] Breadcrumb: Connections cleared (no timestamp set)\n")
      }

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
}

#' Setup Progress Tracking Outputs
#'
#' Creates progress bar and element summary outputs.
#'
#' @param output Shiny output object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#'
#' @return NULL (sets up outputs as side effect)
#'
#' @export
setup_progress_outputs <- function(output, rv, i18n) {
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

  # Render connection types summary
  output$connection_types_summary <- renderUI({
    # Helper function to count connections by matrix type
    count_by_matrix <- function(matrix_name) {
      suggested_count <- 0
      approved_count <- 0

      # Count suggested connections
      if (!is.null(rv$suggested_connections) && length(rv$suggested_connections) > 0) {
        suggested_count <- sum(sapply(rv$suggested_connections, function(conn) {
          if (is.list(conn) && !is.null(conn$matrix)) {
            isTRUE(conn$matrix == matrix_name)
          } else {
            FALSE
          }
        }))
      }

      # Count approved connections
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

    # Count all 9 connection types
    count_da <- count_by_matrix("d_a")    # Drivers → Activities
    count_ap <- count_by_matrix("a_p")    # Activities → Pressures
    count_ps <- count_by_matrix("p_mpf")  # Pressures → States
    count_si <- count_by_matrix("mpf_es") # States → Impacts
    count_iw <- count_by_matrix("es_gb")  # Impacts → Welfare
    count_wr <- count_by_matrix("gb_r")   # Welfare → Responses
    count_rd <- count_by_matrix("r_d")    # Responses → Drivers
    count_ra <- count_by_matrix("r_a")    # Responses → Activities
    count_rp <- count_by_matrix("r_p")    # Responses → Pressures

    # Create display with bold font
    tagList(
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("D→A: %d", count_da)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("A→P: %d", count_ap)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("P→S: %d", count_ps)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("S→I: %d", count_si)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("I→W: %d", count_iw)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("W→R: %d", count_wr)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("R→D: %d", count_rd)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("R→A: %d", count_ra)),
      tags$div(style = CSS_LABEL_BOLD,
               sprintf("R→P: %d", count_rp))
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
  output$count_connections <- renderText({ length(rv$approved_connections) })
}

# ==============================================================================
# MODAL DIALOGS
# ==============================================================================

#' Setup Preview Model Modal
#'
#' Creates observer for preview model button to show complete model overview.
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#'
#' @return NULL (sets up observer as side effect)
#'
#' @export
setup_preview_modal <- function(input, session, rv, i18n) {
  observeEvent(input$preview_model, {
    # Create preview of all elements
    preview_content <- tagList(
      h3(icon("project-diagram"), " ", i18n$t("modules.isa.ai_assistant.your_dapsiwrm_model_preview")),
      hr(),

      if (!is.null(rv$context$project_name)) {
        div(
          h4(icon("map-marker-alt"), " ", i18n$t("common.messages.project_information")),
          tags$ul(
            tags$li(strong(i18n$t("modules.isa.ai_assistant.projectlocation")), " ", rv$context$project_name),
            if (!is.null(rv$context$ecosystem_type)) tags$li(strong(i18n$t("common.labels.ecosystem_type")), " ", rv$context$ecosystem_type),
            if (!is.null(rv$context$main_issue)) tags$li(strong(i18n$t("modules.isa.ai_assistant.main_issue")), " ", rv$context$main_issue)
          ),
          hr()
        )
      },

      # Drivers
      if (length(rv$elements$drivers) > 0) {
        div(
          h4(style = "color: #776db3;", icon("flag"), " ", i18n$t("modules.isa.ai_assistant.drivers_societal_needs")),
          tags$ul(
            lapply(rv$elements$drivers, function(d) tags$li(d$name))
          )
        )
      },

      # Activities
      if (length(rv$elements$activities) > 0) {
        div(
          h4(style = "color: #5abc67;", icon("running"), " ", i18n$t("modules.isa.ai_assistant.activities_human_actions")),
          tags$ul(
            lapply(rv$elements$activities, function(a) tags$li(a$name))
          )
        )
      },

      # Pressures
      if (length(rv$elements$pressures) > 0) {
        div(
          h4(style = "color: #fec05a;", icon("exclamation-triangle"), " ", i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors")),
          tags$ul(
            lapply(rv$elements$pressures, function(p) tags$li(p$name))
          )
        )
      },

      # State Changes
      if (length(rv$elements$states) > 0) {
        div(
          h4(style = "color: #bce2ee;", icon("water"), " ", i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects")),
          tags$ul(
            lapply(rv$elements$states, function(s) tags$li(s$name))
          )
        )
      },

      # Impacts
      if (length(rv$elements$impacts) > 0) {
        div(
          h4(style = "color: #313695;", icon("chart-line"), " ", i18n$t("modules.isa.ai_assistant.impacts_service_effects")),
          tags$ul(
            lapply(rv$elements$impacts, function(i) tags$li(i$name))
          )
        )
      },

      # Welfare
      if (length(rv$elements$welfare) > 0) {
        div(
          h4(style = "color: #fff1a2; text-shadow: 1px 1px 2px #666;", icon("heart"), " ", i18n$t("modules.isa.ai_assistant.welfare_human_well_being")),
          tags$ul(
            lapply(rv$elements$welfare, function(w) tags$li(w$name))
          )
        )
      },

      # Responses
      if (length(rv$elements$responses) > 0) {
        div(
          h4(style = "color: #66c2a5;", icon("shield-alt"), " ", i18n$t("modules.isa.ai_assistant.response_measures_management_policy")),
          tags$ul(
            lapply(rv$elements$responses, function(r) tags$li(r$name))
          )
        )
      },

      hr(),

      # Connections
      if (length(rv$approved_connections) > 0 && length(rv$suggested_connections) > 0) {
        # Filter out invalid indices (bounds check)
        valid_indices <- rv$approved_connections[rv$approved_connections <= length(rv$suggested_connections)]

        if (length(valid_indices) > 0) {
          div(
            h4(style = "color: #28a745;", icon("project-diagram"), " ",
               i18n$t("ui.dashboard.connections"), " (", length(valid_indices), ")"),
            tags$div(
              style = "max-height: 300px; overflow-y: auto; padding: 10px; background: #f8f9fa; border-radius: 5px;",
              tags$ul(
                style = "list-style-type: none; padding-left: 0;",
                lapply(valid_indices, function(conn_idx) {
                  conn <- rv$suggested_connections[[conn_idx]]
                  tags$li(
                    style = "margin-bottom: 8px; padding: 5px; background: white; border-radius: 3px;",
                    icon("link"),
                    " ",
                    strong(conn$from_name),
                    " ",
                    span(style = CSS_TEXT_MUTED,
                         if(conn$polarity == "+") "→" else "⊸"),
                    " ",
                    strong(conn$to_name),
                    tags$br(),
                    span(style = "font-size: 0.85em; color: #666; margin-left: 20px;",
                         i18n$t("modules.isa.data_entry.common.strength"), " ", conn$strength, ", ",
                         i18n$t("modules.isa.data_entry.common.confidence"), " ", conn$confidence %||% 3)
                  )
                })
              )
            ),
            hr()
          )
        }
      },

      p(class = "text-muted",
        i18n$t("modules.isa.ai_assistant.total_elements"), " ",
        sum(length(rv$elements$drivers), length(rv$elements$activities),
            length(rv$elements$pressures), length(rv$elements$states),
            length(rv$elements$impacts), length(rv$elements$welfare),
            length(rv$elements$responses)),
        " | ",
        i18n$t("modules.isa.ai_assistant.total_connections"), " ",
        # Count only valid approved connections (bounds check)
        if (length(rv$suggested_connections) > 0) {
          length(rv$approved_connections[rv$approved_connections <= length(rv$suggested_connections)])
        } else {
          0
        })
    )

    showModal(modalDialog(
      preview_content,
      title = NULL,
      size = "l",
      easyClose = TRUE,
      footer = tagList(
        modalButton(i18n$t("common.buttons.close")),
        actionButton(session$ns("save_from_preview"), i18n$t("modules.isa.ai_assistant.save_to_isa_data_entry"),
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
}

#' Setup Start Over Modal
#'
#' Creates observer for start over button with confirmation dialog.
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#' @param project_data_reactive Reactive containing project data
#' @param event_bus Event bus for emitting ISA change events
#' @param QUESTION_FLOW List defining the wizard steps
#'
#' @return NULL (sets up observers as side effect)
#'
#' @export
setup_start_over_modal <- function(input, session, rv, i18n, project_data_reactive, event_bus, QUESTION_FLOW) {
  # Handle start over
  observeEvent(input$start_over, {
    showModal(modalDialog(
      title = i18n$t("common.messages.confirm_start_over"),
      i18n$t("modules.isa.are_you_sure_you_want_to_start_over_all_curr_progr"),
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton(session$ns("confirm_start_over"), i18n$t("modules.isa.ai_assistant.yes_start_over"), class = "btn-danger")
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
      responses = list()
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

    showNotification(i18n$t("common.messages.all_data_cleared_starting_over"), type = "message", duration = 3)
    cat("[AI ISA] Reset complete\n")
  })
}

#' Setup Element Viewer Modals
#'
#' Creates observers for element links in sidebar to show detailed lists.
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv ReactiveValues object containing wizard state
#' @param i18n shiny.i18n translator object
#'
#' @return NULL (sets up observers as side effect)
#'
#' @export
setup_element_viewer_modals <- function(input, session, rv, i18n) {
  # Framework element link observers - show element details in modal
  observeEvent(input$link_drivers, {
    if (length(rv$elements$drivers) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.drivers")),
        tags$ul(lapply(rv$elements$drivers, function(d) tags$li(strong(d$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_activities, {
    if (length(rv$elements$activities) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.activities")),
        tags$ul(lapply(rv$elements$activities, function(a) tags$li(strong(a$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_pressures, {
    if (length(rv$elements$pressures) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.response.measures.pressures")),
        tags$ul(lapply(rv$elements$pressures, function(p) tags$li(strong(p$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_states, {
    if (length(rv$elements$states) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.state_changes")),
        tags$ul(lapply(rv$elements$states, function(s) tags$li(strong(s$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_impacts, {
    if (length(rv$elements$impacts) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.impacts")),
        tags$ul(lapply(rv$elements$impacts, function(i) tags$li(strong(i$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_welfare, {
    if (length(rv$elements$welfare) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.welfare")),
        tags$ul(lapply(rv$elements$welfare, function(w) tags$li(strong(w$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_responses, {
    if (length(rv$elements$responses) > 0) {
      showModal(modalDialog(
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.response_measures")),
        tags$ul(lapply(rv$elements$responses, function(r) tags$li(strong(r$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_connections, {
    if (length(rv$approved_connections) > 0 && length(rv$suggested_connections) > 0) {
      # Filter out invalid indices
      valid_indices <- rv$approved_connections[rv$approved_connections <= length(rv$suggested_connections)]

      if (length(valid_indices) > 0) {
        showModal(modalDialog(
          title = tagList(icon("project-diagram"), " ", i18n$t("modules.isa.ai_assistant.connections")),
          tags$ul(
            lapply(valid_indices, function(idx) {
              conn <- rv$suggested_connections[[idx]]
              tags$li(
                strong(conn$from_name), " ",
                span(if(conn$polarity == "+") "→" else "⊸"), " ",
                strong(conn$to_name)
              )
            })
          ),
          size = "m",
          easyClose = TRUE,
          footer = modalButton(i18n$t("common.buttons.close"))
        ))
      }
    }
  })
}

# ==============================================================================
# MODULE INITIALIZATION MESSAGE
# ==============================================================================

message("[INFO] AI ISA Question Flow module loaded successfully")
message("       Available functions: define_question_flow, get_session_data,")
message("       restore_session_data, setup_* functions")
