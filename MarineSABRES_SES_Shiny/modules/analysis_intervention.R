# modules/analysis_intervention.R
# =============================================================================
# Intervention & Measure Simulation Module
#
# Provides:
#   - Design interventions (name, affected nodes, indicators, effect range)
#   - Add intervention node to adjacency matrix
#   - Run simulation on modified matrix
#   - Compare original vs intervention final states
#   - Manage multiple intervention scenarios
#
# Depends on: functions/ses_dynamics.R, functions/cld_validation.R,
#             functions/ui_helpers.R
# =============================================================================

# ============================================================================
# UI FUNCTION
# ============================================================================

analysis_intervention_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    uiOutput(ns("module_header")),
    uiOutput(ns("cld_check_ui")),
    uiOutput(ns("main_ui"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

analysis_intervention_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Local reactive state ─────────────────────────────────────────────
    rv <- reactiveValues(
      numeric_matrix = NULL,
      interventions = list(),         # List of defined interventions
      comparison_results = list(),    # Comparison results per intervention
      current_intervention = NULL,    # Currently selected intervention name
      analysis_complete = FALSE,
      error_message = NULL
    )

    # ── Standard header + help ───────────────────────────────────────────
    create_reactive_header(
      output = output, ns = ns,
      title_key = "modules.analysis_intervention.title",
      subtitle_key = "modules.analysis_intervention.subtitle",
      help_id = "help_intervention",
      i18n = i18n
    )

    create_help_observer(
      input = input, input_id = "help_intervention",
      title_key = "modules.analysis_intervention.help_title",
      content = tagList(
        h4(i18n$t("modules.analysis_intervention.help_heading")),
        p(i18n$t("modules.analysis_intervention.help_design")),
        p(i18n$t("modules.analysis_intervention.help_compare"))
      ),
      i18n = i18n
    )

    # ── CLD validation gate ──────────────────────────────────────────────
    output$cld_check_ui <- renderUI({
      data <- project_data_reactive()
      if (is.null(data) || !has_valid_cld(data)) {
        div(class = "alert alert-warning", style = "margin: 20px;",
          icon("exclamation-triangle"), " ",
          strong(i18n$t("modules.analysis_intervention.no_cld_data")),
          p(i18n$t("modules.analysis_intervention.no_cld_data_hint"))
        )
      }
    })

    # ── Main UI ──────────────────────────────────────────────────────────
    output$main_ui <- renderUI({
      data <- project_data_reactive()
      if (is.null(data) || !has_valid_cld(data)) return(NULL)

      node_names <- data$data$cld$nodes$label
      if (is.null(node_names)) node_names <- data$data$cld$nodes$id
      node_ids <- data$data$cld$nodes$id
      node_choices <- setNames(node_ids, node_names)

      # Also gather response measures if available
      responses <- data$data$isa_data$responses
      response_names <- if (!is.null(responses) && nrow(responses) > 0) responses$name else character(0)

      tagList(
        fluidRow(
          # ── Intervention design panel ──
          column(4,
            bs4Card(
              title = tagList(icon("magic"), " ",
                              i18n$t("modules.analysis_intervention.design")),
              width = 12, collapsible = FALSE, status = "primary",

              # Pre-populated from responses or manual
              textInput(
                ns("intervention_name"),
                i18n$t("modules.analysis_intervention.name"),
                placeholder = i18n$t("modules.analysis_intervention.name_placeholder")
              ),

              # Quick-select from existing response measures
              if (length(response_names) > 0) {
                selectizeInput(
                  ns("from_response"),
                  i18n$t("modules.analysis_intervention.from_responses"),
                  choices = c("" = "", response_names),
                  options = list(
                    placeholder = i18n$t("modules.analysis_intervention.select_response"))
                )
              },

              selectizeInput(
                ns("affected_nodes"),
                i18n$t("modules.analysis_intervention.affected_nodes"),
                choices = node_choices, multiple = TRUE,
                options = list(
                  placeholder = i18n$t("modules.analysis_intervention.select_affected"))
              ),

              selectizeInput(
                ns("indicator_nodes"),
                i18n$t("modules.analysis_intervention.indicator_nodes"),
                choices = node_choices, multiple = TRUE,
                options = list(
                  placeholder = i18n$t("modules.analysis_intervention.select_indicators"))
              ),

              sliderInput(
                ns("effect_range"),
                i18n$t("modules.analysis_intervention.effect_range"),
                min = -1, max = 1, value = c(-0.5, 0.5), step = 0.1
              ),

              sliderInput(
                ns("n_iter"),
                i18n$t("modules.analysis_intervention.iterations"),
                min = DYNAMICS_MIN_ITER, max = 2000,
                value = DYNAMICS_DEFAULT_ITER, step = 50
              ),

              hr(),

              actionButton(
                ns("add_intervention"),
                tagList(icon("plus"), " ", i18n$t("modules.analysis_intervention.add")),
                class = "btn-success btn-block", style = "margin-bottom: 8px;"
              ),

              actionButton(
                ns("run_analysis"),
                tagList(icon("play"), " ", i18n$t("modules.analysis_intervention.run")),
                class = "btn-primary btn-block"
              )
            ),

            # Saved interventions list
            bs4Card(
              title = tagList(icon("list"), " ",
                              i18n$t("modules.analysis_intervention.saved")),
              width = 12, collapsible = TRUE, status = "secondary",
              uiOutput(ns("interventions_list"))
            )
          ),

          # ── Results panel ──
          column(8,
            uiOutput(ns("results_ui"))
          )
        )
      )
    })

    # ── Auto-fill from response measures ─────────────────────────────────
    observeEvent(input$from_response, {
      req(input$from_response, input$from_response != "")
      updateTextInput(session, "intervention_name", value = input$from_response)
    })

    # ── Add intervention ─────────────────────────────────────────────────
    observeEvent(input$add_intervention, {
      name <- trimws(input$intervention_name)
      if (name == "") {
        showNotification(i18n$t("modules.analysis_intervention.name_required"),
                         type = "warning")
        return()
      }
      if (is.null(input$affected_nodes) || length(input$affected_nodes) == 0) {
        showNotification(i18n$t("modules.analysis_intervention.affected_required"),
                         type = "warning")
        return()
      }

      data <- project_data_reactive()
      req(data, has_valid_cld(data))

      # Build numeric matrix if needed
      if (is.null(rv$numeric_matrix)) {
        rv$numeric_matrix <- cld_to_numeric_matrix(
          data$data$cld$nodes, data$data$cld$edges, use_labels = TRUE
        )
      }

      # Map IDs to labels for affected and indicator nodes
      nodes_df <- data$data$cld$nodes
      affected_labels <- nodes_df$label[match(input$affected_nodes, nodes_df$id)]
      affected_labels <- ifelse(is.na(affected_labels),
                                 input$affected_nodes, affected_labels)
      indicator_labels <- if (!is.null(input$indicator_nodes)) {
        lbl <- nodes_df$label[match(input$indicator_nodes, nodes_df$id)]
        ifelse(is.na(lbl), input$indicator_nodes, lbl)
      } else { character(0) }

      # Create intervention matrix
      tryCatch({
        int_mat <- ses_add_intervention(
          rv$numeric_matrix,
          name = name,
          affected_nodes = affected_labels,
          indicator_nodes = indicator_labels,
          effect_range = input$effect_range
        )

        rv$interventions[[name]] <- list(
          name = name,
          affected_nodes = affected_labels,
          indicator_nodes = indicator_labels,
          effect_range = input$effect_range,
          matrix = int_mat,
          timestamp = Sys.time()
        )

        showNotification(
          paste(i18n$t("modules.analysis_intervention.added"), name),
          type = "message"
        )

        # Clear inputs
        updateTextInput(session, "intervention_name", value = "")
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # ── Interventions list ───────────────────────────────────────────────
    output$interventions_list <- renderUI({
      if (length(rv$interventions) == 0) {
        return(p(class = "text-muted",
          i18n$t("modules.analysis_intervention.no_interventions")))
      }

      tagList(
        lapply(names(rv$interventions), function(name) {
          int <- rv$interventions[[name]]
          div(
            class = "d-flex justify-content-between align-items-center",
            style = "padding: 5px 0; border-bottom: 1px solid #eee;",
            tags$span(
              icon("syringe"), " ", strong(name),
              tags$br(),
              tags$small(class = "text-muted",
                length(int$affected_nodes), " ",
                i18n$t("modules.analysis_intervention.nodes_affected"))
            ),
            actionButton(
              ns(paste0("remove_", gsub("[^a-zA-Z0-9]", "_", name))),
              icon("trash"), class = "btn-sm btn-outline-danger"
            )
          )
        })
      )
    })

    # ── Run analysis ─────────────────────────────────────────────────────
    observeEvent(input$run_analysis, {
      if (length(rv$interventions) == 0) {
        showNotification(i18n$t("modules.analysis_intervention.add_first"),
                         type = "warning")
        return()
      }

      data <- project_data_reactive()
      req(data, has_valid_cld(data))

      rv$analysis_complete <- FALSE
      rv$error_message <- NULL

      if (is.null(rv$numeric_matrix)) {
        rv$numeric_matrix <- cld_to_numeric_matrix(
          data$data$cld$nodes, data$data$cld$edges, use_labels = TRUE
        )
      }

      n_interventions <- length(rv$interventions)

      withProgress(
        message = i18n$t("modules.analysis_intervention.running"),
        value = 0, {

        for (i in seq_along(rv$interventions)) {
          name <- names(rv$interventions)[i]
          int <- rv$interventions[[name]]
          incProgress(1 / n_interventions,
            detail = paste(i, "/", n_interventions, "-", name))

          tryCatch({
            comparison <- ses_compare_interventions(
              rv$numeric_matrix, int$matrix, n_iter = input$n_iter
            )
            rv$comparison_results[[name]] <- comparison
          }, error = function(e) {
            rv$comparison_results[[name]] <- NULL
            rv$error_message <- paste(name, ":", e$message)
          })
        }

        rv$analysis_complete <- TRUE

        # Save to project data
        data$data$analysis$dynamics$interventions <- lapply(
          names(rv$comparison_results), function(name) {
            list(
              name = name,
              comparison = rv$comparison_results[[name]],
              affected_nodes = rv$interventions[[name]]$affected_nodes,
              indicator_nodes = rv$interventions[[name]]$indicator_nodes,
              effect_range = rv$interventions[[name]]$effect_range,
              timestamp = Sys.time()
            )
          }
        )
        data$last_modified <- Sys.time()
        project_data_reactive(data)
      })
    })

    # ── Results UI ───────────────────────────────────────────────────────
    output$results_ui <- renderUI({
      if (!rv$analysis_complete || length(rv$comparison_results) == 0) {
        return(div(
          style = "text-align: center; padding: 60px; color: #999;",
          icon("syringe", class = "fa-3x"), tags$br(), tags$br(),
          p(i18n$t("modules.analysis_intervention.click_to_start"))
        ))
      }

      tabs <- list()

      # One tab per intervention
      for (name in names(rv$comparison_results)) {
        comp <- rv$comparison_results[[name]]
        if (is.null(comp)) next

        local_name <- name  # capture for closure
        tabs <- c(tabs, list(
          tabPanel(
            title = local_name,
            tags$div(style = "padding: 15px;",
              h5(icon("syringe"), " ", local_name),
              shinycssloaders::withSpinner(
                plotly::plotlyOutput(ns(paste0("comp_plot_", gsub("[^a-zA-Z0-9]", "_", local_name))),
                                     height = PLOT_HEIGHT_MD)
              ),
              hr(),
              DT::DTOutput(ns(paste0("comp_table_", gsub("[^a-zA-Z0-9]", "_", local_name))))
            )
          )
        ))
      }

      # Summary comparison tab
      if (length(rv$comparison_results) > 1) {
        tabs <- c(list(
          tabPanel(
            title = tagList(icon("chart-bar"), " ",
                            i18n$t("modules.analysis_intervention.comparison")),
            tags$div(style = "padding: 15px;",
              shinycssloaders::withSpinner(
                plotly::plotlyOutput(ns("multi_comparison_plot"), height = PLOT_HEIGHT_LG)
              )
            )
          )
        ), tabs)
      }

      do.call(tabsetPanel, c(list(id = ns("results_tabs"), type = "pills"), tabs))
    })

    # ── Dynamic comparison plot and table renderers ──────────────────────
    observe({
      for (name in names(rv$comparison_results)) {
        local({
          local_name <- name
          comp <- rv$comparison_results[[local_name]]
          if (is.null(comp)) return()

          safe_id <- gsub("[^a-zA-Z0-9]", "_", local_name)

          output[[paste0("comp_plot_", safe_id)]] <- plotly::renderPlotly({
            df <- comp

            plotly::plot_ly() %>%
              plotly::add_trace(
                x = df$node, y = df$state_original, type = "bar",
                name = i18n$t("modules.analysis_intervention.original"),
                marker = list(color = "#3498db")
              ) %>%
              plotly::add_trace(
                x = df$node, y = df$state_intervention, type = "bar",
                name = local_name,
                marker = list(color = "#e74c3c")
              ) %>%
              plotly::layout(
                title = paste(i18n$t("modules.analysis_intervention.comparison_title"),
                              local_name),
                xaxis = list(title = "", tickangle = -45),
                yaxis = list(title = i18n$t("modules.analysis_intervention.final_state")),
                barmode = "group"
              )
          })

          output[[paste0("comp_table_", safe_id)]] <- DT::renderDT({
            df <- comp
            df$state_original <- round(df$state_original, 4)
            df$state_intervention <- round(df$state_intervention, 4)
            df$delta <- round(df$delta, 4)
            DT::datatable(df, options = list(pageLength = 20, scrollX = TRUE),
                          rownames = FALSE)
          })
        })
      }
    })

    # ── Multi-intervention comparison ────────────────────────────────────
    output$multi_comparison_plot <- plotly::renderPlotly({
      req(length(rv$comparison_results) > 1)

      p <- plotly::plot_ly()

      for (name in names(rv$comparison_results)) {
        comp <- rv$comparison_results[[name]]
        if (is.null(comp)) next
        p <- plotly::add_trace(p, x = comp$node, y = comp$delta,
                                type = "bar", name = name)
      }

      p %>% plotly::layout(
        title = i18n$t("modules.analysis_intervention.multi_comparison_title"),
        xaxis = list(title = "", tickangle = -45),
        yaxis = list(title = i18n$t("modules.analysis_intervention.state_delta")),
        barmode = "group"
      )
    })

  })
}
