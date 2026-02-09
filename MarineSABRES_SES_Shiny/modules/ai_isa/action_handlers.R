# modules/ai_isa/action_handlers.R
# AI ISA Assistant - Action Handlers
# Purpose: Handle user actions (preview, save, start over, element links)
#
# Extracted from ai_isa_assistant_module.R for better maintainability

#' Setup Action Handlers
#'
#' Registers observeEvent handlers for preview model, save from preview,
#' start over, and element link modals
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv Reactive values containing AI ISA state
#' @param i18n i18n translator object
#' @param project_data_reactive Reactive value for project data
#' @param event_bus Event bus for ISA change events (optional)
setup_action_handlers <- function(input, session, rv, i18n, project_data_reactive,
                                   event_bus = NULL) {

  # Handle preview model
  observeEvent(input$preview_model, {
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
          tags$ul(lapply(rv$elements$drivers, function(d) tags$li(d$name)))
        )
      },

      # Activities
      if (length(rv$elements$activities) > 0) {
        div(
          h4(style = "color: #5abc67;", icon("running"), " ", i18n$t("modules.isa.ai_assistant.activities_human_actions")),
          tags$ul(lapply(rv$elements$activities, function(a) tags$li(a$name)))
        )
      },

      # Pressures
      if (length(rv$elements$pressures) > 0) {
        div(
          h4(style = "color: #fec05a;", icon("exclamation-triangle"), " ", i18n$t("modules.isa.ai_assistant.pressures_environmental_stressors")),
          tags$ul(lapply(rv$elements$pressures, function(p) tags$li(p$name)))
        )
      },

      # State Changes
      if (length(rv$elements$states) > 0) {
        div(
          h4(style = "color: #bce2ee;", icon("water"), " ", i18n$t("modules.isa.ai_assistant.state_changes_ecosystem_effects")),
          tags$ul(lapply(rv$elements$states, function(s) tags$li(s$name)))
        )
      },

      # Impacts
      if (length(rv$elements$impacts) > 0) {
        div(
          h4(style = "color: #313695;", icon("chart-line"), " ", i18n$t("modules.isa.ai_assistant.impacts_service_effects")),
          tags$ul(lapply(rv$elements$impacts, function(i) tags$li(i$name)))
        )
      },

      # Welfare
      if (length(rv$elements$welfare) > 0) {
        div(
          h4(style = "color: #fff1a2; text-shadow: 1px 1px 2px #666;", icon("heart"), " ", i18n$t("modules.isa.ai_assistant.welfare_human_well_being")),
          tags$ul(lapply(rv$elements$welfare, function(w) tags$li(w$name)))
        )
      },

      # Responses
      if (length(rv$elements$responses) > 0) {
        div(
          h4(style = "color: #66c2a5;", icon("shield-alt"), " ", i18n$t("modules.isa.ai_assistant.response_measures_management_policy")),
          tags$ul(lapply(rv$elements$responses, function(r) tags$li(r$name)))
        )
      },

      hr(),

      # Connections
      if (length(rv$approved_connections) > 0 && length(rv$suggested_connections) > 0) {
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
                         if(conn$polarity == "+") "\u2192" else "\u22b8"),
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
    showNotification(
      i18n$t("Model saved! Navigate to 'ISA Data Entry' to see your elements."),
      type = "message",
      duration = 5
    )
  })

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
    debug_log("[AI ISA] Starting over - resetting all data")

    rv$current_step <- 0
    rv$auto_saved_step_10 <- FALSE
    rv$show_text_input <- FALSE

    rv$conversation <- list(
      list(type = "ai", message = QUESTION_FLOW[[1]]$question, timestamp = Sys.time())
    )

    rv$elements <- list(
      drivers = list(),
      activities = list(),
      pressures = list(),
      states = list(),
      impacts = list(),
      welfare = list(),
      responses = list()
    )

    rv$context <- list(
      project_name = NULL,
      regional_sea = NULL,
      ecosystem_type = NULL,
      ecosystem_subtype = NULL,
      main_issue = NULL
    )

    rv$suggested_connections <- list()
    rv$approved_connections <- list()

    current_data <- project_data_reactive()
    if (!is.null(current_data$data$isa_data)) {
      debug_log("[AI ISA] Clearing saved project ISA data")
      current_data$data$isa_data <- NULL
      current_data$data$cld <- list(nodes = NULL, edges = NULL)
      current_data$data$metadata$data_source <- NULL
      current_data$last_modified <- Sys.time()
      project_data_reactive(current_data)

      if (!is.null(event_bus)) {
        event_bus$emit_isa_change()
      }
    }

    session$sendCustomMessage('clear_ai_isa_session', list())
    rv$last_save_time <- NULL

    removeModal()

    showNotification(i18n$t("common.messages.all_data_cleared_starting_over"), type = "message", duration = 3)
    debug_log("[AI ISA] Reset complete")
  })

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
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.ses.creation.welfare")),
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
        title = tagList(icon("arrow-circle-right"), " ", i18n$t("modules.isa.ai_assistant.responses")),
        tags$ul(lapply(rv$elements$responses, function(r) tags$li(strong(r$name)))),
        size = "m",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    }
  })

  observeEvent(input$link_connections, {
    if (length(rv$approved_connections) > 0) {
      conn_list <- lapply(rv$approved_connections, function(idx) {
        conn <- rv$suggested_connections[[idx]]
        tags$li(
          strong(conn$from_name), " ",
          span(style = CSS_TEXT_MUTED, if(conn$polarity == "+") "\u2192" else "\u22b8"), " ",
          strong(conn$to_name),
          tags$br(),
          span(style = "font-size: 0.9em; color: #666;",
               "Strength: ", conn$strength, ", Confidence: ", conn$confidence %||% 3)
        )
      })

      showModal(modalDialog(
        title = tagList(icon("project-diagram"), " ", i18n$t("modules.isa.ai_assistant.approved_connections")),
        tags$ul(conn_list),
        size = "l",
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
    } else {
      showNotification(i18n$t("common.messages.no_connections_approved_yet"), type = "warning", duration = 2)
    }
  })
}
