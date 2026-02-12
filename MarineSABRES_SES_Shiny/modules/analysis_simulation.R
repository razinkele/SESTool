# modules/analysis_simulation.R
# =============================================================================
# Dynamic Simulation & State-Shift Analysis Module
#
# Provides:
#   - Deterministic time-series simulation (linear matrix dynamics)
#   - Phase space (PCA) trajectory visualization
#   - Participation ratio analysis
#   - Monte Carlo state-shift robustness analysis
#
# Depends on: functions/ses_dynamics.R, functions/cld_validation.R,
#             functions/ui_helpers.R
# =============================================================================

# ============================================================================
# UI FUNCTION
# ============================================================================

analysis_simulation_ui <- function(id, i18n) {
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

analysis_simulation_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Local reactive state ─────────────────────────────────────────────
    rv <- reactiveValues(
      numeric_matrix = NULL,
      sim_result = NULL,
      pr_result = NULL,
      state_shift_result = NULL,
      sim_complete = FALSE,
      ss_complete = FALSE,
      error_message = NULL
    )

    # ── Standard header + help ───────────────────────────────────────────
    create_reactive_header(
      output = output, ns = ns,
      title_key = "modules.analysis_simulation.title",
      subtitle_key = "modules.analysis_simulation.subtitle",
      help_id = "help_simulation",
      i18n = i18n
    )

    create_help_observer(
      input = input, input_id = "help_simulation",
      title_key = "modules.analysis_simulation.help_title",
      content = tagList(
        h4(i18n$t("modules.analysis_simulation.help_heading")),
        p(i18n$t("modules.analysis_simulation.help_simulation")),
        p(i18n$t("modules.analysis_simulation.help_state_shift")),
        p(i18n$t("modules.analysis_simulation.help_participation"))
      ),
      i18n = i18n
    )

    # ── CLD validation gate ──────────────────────────────────────────────
    setup_cld_gate(output, project_data_reactive, i18n,
      "modules.analysis_simulation.no_cld_data",
      "modules.analysis_simulation.no_cld_data_hint"
    )

    # ── Main UI ──────────────────────────────────────────────────────────
    output$main_ui <- renderUI({
      data <- project_data_reactive()
      if (is.null(data) || !has_valid_cld(data)) return(NULL)

      node_names <- data$data$cld$nodes$label
      if (is.null(node_names)) node_names <- data$data$cld$nodes$id
      node_ids <- data$data$cld$nodes$id

      tagList(
        fluidRow(
          # ── Controls ──
          column(4,
            # Simulation controls
            bs4Card(
              title = tagList(icon("chart-line"), " ",
                              i18n$t("modules.analysis_simulation.simulation_controls")),
              width = 12, collapsible = FALSE, status = "primary",

              sliderInput(
                ns("n_iter"),
                i18n$t("modules.analysis_simulation.iterations"),
                min = DYNAMICS_MIN_ITER, max = 2000,
                value = DYNAMICS_DEFAULT_ITER, step = 50
              ),

              checkboxInput(
                ns("include_confidence"),
                i18n$t("modules.analysis_simulation.scale_by_confidence"),
                value = FALSE
              ),

              actionButton(
                ns("run_simulation"),
                tagList(icon("play"), " ", i18n$t("modules.analysis_simulation.run_simulation")),
                class = "btn-primary btn-block"
              )
            ),

            # State-shift controls
            bs4Card(
              title = tagList(icon("random"), " ",
                              i18n$t("modules.analysis_simulation.state_shift_controls")),
              width = 12, collapsible = TRUE, status = "info",

              sliderInput(
                ns("n_simulations"),
                i18n$t("modules.analysis_simulation.n_simulations"),
                min = 10, max = 1000, value = DYNAMICS_DEFAULT_GREED, step = 10
              ),

              radioButtons(
                ns("randomization_type"),
                i18n$t("modules.analysis_simulation.randomization"),
                choices = setNames(c("uniform", "ordinal"),
                  c(i18n$t("modules.analysis_simulation.uniform"),
                    i18n$t("modules.analysis_simulation.ordinal"))),
                selected = "uniform"
              ),

              selectizeInput(
                ns("target_nodes"),
                i18n$t("modules.analysis_simulation.target_nodes"),
                choices = setNames(node_ids, node_names),
                multiple = TRUE,
                options = list(placeholder = i18n$t("modules.analysis_simulation.select_targets"))
              ),

              tags$p(class = "text-muted", style = "font-size: 12px;",
                icon("info-circle"), " ",
                i18n$t("modules.analysis_simulation.target_nodes_help")
              ),

              actionButton(
                ns("run_state_shift"),
                tagList(icon("random"), " ", i18n$t("modules.analysis_simulation.run_state_shift")),
                class = "btn-info btn-block"
              )
            ),

            # Download
            conditionalPanel(
              condition = sprintf("output['%s'] === true", ns("any_results")),
              downloadButton(
                ns("download_results"),
                tagList(icon("download"), " ", i18n$t("modules.analysis_simulation.download")),
                class = "btn-outline-success btn-block",
                style = "margin-top: 10px;"
              )
            )
          ),

          # ── Results ──
          column(8,
            uiOutput(ns("results_ui"))
          )
        )
      )
    })

    # ── Results flag for conditional UI ──────────────────────────────────
    output$any_results <- reactive({ rv$sim_complete || rv$ss_complete })
    outputOptions(output, "any_results", suspendWhenHidden = FALSE)

    # ── Build numeric matrix helper ──────────────────────────────────────
    .get_matrix <- function(data) {
      # Check if we already have a cached matrix from Boolean module
      cached <- safe_get_nested(data, "data", "analysis", "dynamics", "numeric_matrix",
                                 default = NULL)
      if (!is.null(cached) && is.matrix(cached)) return(cached)

      cld_to_numeric_matrix(
        data$data$cld$nodes,
        data$data$cld$edges,
        use_labels = TRUE,
        include_confidence = input$include_confidence
      )
    }

    # ── Run deterministic simulation ─────────────────────────────────────
    observeEvent(input$run_simulation, {
      data <- project_data_reactive()
      req(data, has_valid_cld(data))

      rv$sim_complete <- FALSE
      rv$error_message <- NULL

      withProgress(message = i18n$t("modules.analysis_simulation.running_sim"), value = 0, {

        # Build matrix
        incProgress(0.1, detail = i18n$t("modules.analysis_simulation.building_matrix"))
        rv$numeric_matrix <- tryCatch(.get_matrix(data), error = function(e) {
          rv$error_message <- e$message
          NULL
        })
        if (is.null(rv$numeric_matrix)) return()

        # Run simulation
        incProgress(0.4, detail = i18n$t("modules.analysis_simulation.simulating"))
        rv$sim_result <- tryCatch(
          ses_simulate(rv$numeric_matrix, n_iter = input$n_iter),
          error = function(e) { rv$error_message <- e$message; NULL }
        )
        if (is.null(rv$sim_result)) return()

        # Participation ratio
        incProgress(0.3, detail = i18n$t("modules.analysis_simulation.computing_pr"))
        rv$pr_result <- tryCatch(
          ses_participation_ratio(rv$numeric_matrix),
          error = function(e) { rv$error_message <- paste("PR:", e$message); NULL }
        )

        incProgress(0.2)
        rv$sim_complete <- TRUE

        # Save to project data
        data$data$analysis$dynamics$numeric_matrix <- rv$numeric_matrix
        data$data$analysis$dynamics$simulation <- list(
          time_series = rv$sim_result$time_series,
          n_iter = rv$sim_result$n_iter,
          diverged = rv$sim_result$diverged,
          initial_state = rv$sim_result$initial_state,
          timestamp = Sys.time()
        )
        if (!is.null(rv$pr_result)) {
          data$data$analysis$dynamics$participation_ratio <- rv$pr_result
        }
        data$last_modified <- Sys.time()
        project_data_reactive(data)
      })
    })

    # ── Run state-shift Monte Carlo ──────────────────────────────────────
    observeEvent(input$run_state_shift, {
      data <- project_data_reactive()
      req(data, has_valid_cld(data))

      rv$ss_complete <- FALSE

      withProgress(message = i18n$t("modules.analysis_simulation.running_ss"), value = 0, {

        if (is.null(rv$numeric_matrix)) {
          rv$numeric_matrix <- tryCatch(.get_matrix(data), error = function(e) NULL)
        }
        if (is.null(rv$numeric_matrix)) return()

        n_sims <- input$n_simulations

        # Map selected target IDs to labels
        target_labels <- NULL
        if (!is.null(input$target_nodes) && length(input$target_nodes) > 0) {
          nodes_df <- data$data$cld$nodes
          idx <- match(input$target_nodes, nodes_df$id)
          target_labels <- ifelse(is.na(nodes_df$label[idx]), nodes_df$id[idx],
                                   nodes_df$label[idx])
        }

        rv$state_shift_result <- tryCatch(
          ses_state_shift(
            rv$numeric_matrix,
            n_simulations = n_sims,
            n_iter = input$n_iter,
            type = input$randomization_type,
            target_nodes = target_labels,
            progress_callback = function(i, n) {
              incProgress(1 / n,
                detail = sprintf("%d / %d", i, n))
            }
          ),
          error = function(e) {
            rv$error_message <- paste("State-shift error:", e$message)
            NULL
          }
        )

        if (!is.null(rv$state_shift_result)) {
          rv$ss_complete <- TRUE

          # Save to project data
          data$data$analysis$dynamics$state_shift <- list(
            final_states = rv$state_shift_result$final_states,
            n_simulations = rv$state_shift_result$n_simulations,
            randomization_type = rv$state_shift_result$randomization_type,
            target_nodes = rv$state_shift_result$target_nodes,
            success_rate = rv$state_shift_result$success_rate,
            timestamp = Sys.time()
          )
          data$last_modified <- Sys.time()
          project_data_reactive(data)
        }
      })
    })

    # ── Results UI ───────────────────────────────────────────────────────
    output$results_ui <- renderUI({
      if (!rv$sim_complete && !rv$ss_complete) {
        return(div(
          style = "text-align: center; padding: 60px; color: #999;",
          icon("chart-line", class = "fa-3x"), tags$br(), tags$br(),
          p(i18n$t("modules.analysis_simulation.click_to_start"))
        ))
      }

      if (!is.null(rv$error_message)) {
        return(div(class = "alert alert-danger", style = "margin: 10px;",
          icon("exclamation-circle"), " ", rv$error_message))
      }

      tabs <- list()

      # Tab 1: Time Series
      if (rv$sim_complete) {
        tabs <- c(tabs, list(
          tabPanel(
            title = tagList(icon("chart-line"), " ",
                            i18n$t("modules.analysis_simulation.time_series_tab")),
            value = "ts",
            tags$div(style = "padding: 15px;",
              uiOutput(ns("sim_summary")),
              shinycssloaders::withSpinner(
                plotly::plotlyOutput(ns("time_series_plot"), height = PLOT_HEIGHT_LG)
              )
            )
          )
        ))

        # Tab 2: Participation Ratio
        if (!is.null(rv$pr_result)) {
          tabs <- c(tabs, list(
            tabPanel(
              title = tagList(icon("balance-scale"), " ",
                              i18n$t("modules.analysis_simulation.pr_tab")),
              value = "pr",
              tags$div(style = "padding: 15px;",
                shinycssloaders::withSpinner(
                  plotly::plotlyOutput(ns("pr_plot"), height = PLOT_HEIGHT_MD)
                ),
                hr(),
                DT::DTOutput(ns("pr_table"))
              )
            )
          ))
        }
      }

      # Tab 3: State-Shift Results
      if (rv$ss_complete) {
        tabs <- c(tabs, list(
          tabPanel(
            title = tagList(icon("random"), " ",
                            i18n$t("modules.analysis_simulation.state_shift_tab")),
            value = "ss",
            tags$div(style = "padding: 15px;",
              uiOutput(ns("ss_summary")),
              shinycssloaders::withSpinner(
                plotly::plotlyOutput(ns("ss_heatmap"), height = PLOT_HEIGHT_LG)
              ),
              hr(),
              h5(i18n$t("modules.analysis_simulation.outcome_distribution")),
              shinycssloaders::withSpinner(
                plotly::plotlyOutput(ns("ss_distribution"), height = PLOT_HEIGHT_SM)
              )
            )
          )
        ))
      }

      do.call(tabsetPanel, c(list(id = ns("results_tabs"), type = "pills"), tabs))
    })

    # ── Simulation summary ───────────────────────────────────────────────
    output$sim_summary <- renderUI({
      req(rv$sim_result)
      res <- rv$sim_result
      n_nodes <- nrow(res$time_series)

      fluidRow(
        column(3,
          bs4ValueBox(
            value = n_nodes, subtitle = i18n$t("modules.analysis_simulation.nodes"),
            icon = icon("circle"), color = "primary", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = res$n_iter, subtitle = i18n$t("modules.analysis_simulation.iterations_run"),
            icon = icon("redo"), color = "info", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = if (res$diverged) i18n$t("modules.analysis_simulation.yes")
                    else i18n$t("modules.analysis_simulation.no"),
            subtitle = i18n$t("modules.analysis_simulation.diverged"),
            icon = icon(if (res$diverged) "exclamation-triangle" else "check-circle"),
            color = if (res$diverged) "danger" else "success", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = if (!is.null(res$diverged_at)) res$diverged_at else "-",
            subtitle = i18n$t("modules.analysis_simulation.diverged_at"),
            icon = icon("clock"), color = "secondary", width = 12
          )
        )
      )
    })

    # ── Time series plot ─────────────────────────────────────────────────
    output$time_series_plot <- plotly::renderPlotly({
      req(rv$sim_result)
      ts <- rv$sim_result$time_series
      node_names <- rownames(ts)
      n_iter <- ncol(ts)

      # Build long-format data
      df <- do.call(rbind, lapply(seq_along(node_names), function(i) {
        valid_cols <- which(!is.na(ts[i, ]))
        if (length(valid_cols) == 0) return(NULL)
        data.frame(
          time = valid_cols,
          value = ts[i, valid_cols],
          node = node_names[i],
          stringsAsFactors = FALSE
        )
      }))

      if (is.null(df) || nrow(df) == 0) return(plotly::plotly_empty())

      p <- plotly::plot_ly()
      for (nd in unique(df$node)) {
        sub <- df[df$node == nd, ]
        p <- plotly::add_trace(p, x = ~sub$time, y = ~sub$value,
                                type = "scatter", mode = "lines",
                                name = nd,
                                hoverinfo = "text",
                                text = paste(nd, "<br>t =", sub$time,
                                             "<br>", round(sub$value, 4)))
      }

      p %>% plotly::layout(
        title = i18n$t("modules.analysis_simulation.time_series_title"),
        xaxis = list(title = i18n$t("modules.analysis_simulation.time_step"), type = "log"),
        yaxis = list(title = i18n$t("modules.analysis_simulation.state_value")),
        hovermode = "closest"
      )
    })

    # ── Participation ratio plot ─────────────────────────────────────────
    output$pr_plot <- plotly::renderPlotly({
      req(rv$pr_result)
      df <- rv$pr_result
      df <- df[order(-df$participation_ratio), ]
      df$node <- factor(df$node, levels = df$node)

      plotly::plot_ly(df, x = ~node, y = ~participation_ratio, type = "bar",
                      marker = list(color = "#3498db"),
                      hoverinfo = "text",
                      text = ~paste(node, "<br>PR:", round(participation_ratio, 4))) %>%
        plotly::layout(
          title = i18n$t("modules.analysis_simulation.pr_title"),
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = i18n$t("modules.analysis_simulation.participation_ratio"),
                       range = c(0, 1)),
          showlegend = FALSE
        )
    })

    output$pr_table <- DT::renderDT({
      req(rv$pr_result)
      df <- rv$pr_result
      df$participation_ratio <- round(df$participation_ratio, 6)
      df$eigenvalue_real <- round(df$eigenvalue_real, 6)
      df$eigenvalue_imag <- round(df$eigenvalue_imag, 6)
      DT::datatable(df, options = list(pageLength = 15, scrollX = TRUE),
                    rownames = FALSE)
    })

    # ── State-shift summary ──────────────────────────────────────────────
    output$ss_summary <- renderUI({
      req(rv$state_shift_result)
      res <- rv$state_shift_result

      fluidRow(
        column(3,
          bs4ValueBox(
            value = res$n_simulations,
            subtitle = i18n$t("modules.analysis_simulation.simulations_run"),
            icon = icon("random"), color = "primary", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = res$randomization_type,
            subtitle = i18n$t("modules.analysis_simulation.randomization_type"),
            icon = icon("dice"), color = "info", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = if (!is.null(res$success_rate))
              paste0(round(res$success_rate * 100, 1), "%") else "-",
            subtitle = i18n$t("modules.analysis_simulation.success_rate"),
            icon = icon("check-double"),
            color = if (!is.null(res$success_rate) && res$success_rate > 0.5) "success" else "warning",
            width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = if (!is.null(res$target_nodes)) length(res$target_nodes) else 0,
            subtitle = i18n$t("modules.analysis_simulation.target_count"),
            icon = icon("bullseye"), color = "secondary", width = 12
          )
        )
      )
    })

    # ── State-shift heatmap ──────────────────────────────────────────────
    output$ss_heatmap <- plotly::renderPlotly({
      req(rv$state_shift_result)
      fs <- rv$state_shift_result$final_states
      node_names <- rownames(fs)

      plotly::plot_ly(
        z = fs, x = seq_len(ncol(fs)), y = node_names,
        type = "heatmap",
        colorscale = list(c(0, "#e74c3c"), c(0.5, "#ffffff"), c(1, "#2ecc71")),
        zmid = 0,
        hoverinfo = "text",
        text = outer(node_names, seq_len(ncol(fs)), function(n, s) {
          paste("Node:", n, "<br>Sim:", s, "<br>State:", round(fs[n, s], 3))
        })
      ) %>%
        plotly::layout(
          title = i18n$t("modules.analysis_simulation.final_states_heatmap"),
          xaxis = list(title = i18n$t("modules.analysis_simulation.simulation_number")),
          yaxis = list(title = "")
        )
    })

    # ── State-shift distribution ─────────────────────────────────────────
    output$ss_distribution <- plotly::renderPlotly({
      req(rv$state_shift_result)
      fs <- rv$state_shift_result$final_states
      node_names <- rownames(fs)

      # Compute fraction of simulations where each node ends positive
      pos_frac <- apply(fs, 1, function(row) mean(row > 0, na.rm = TRUE))
      df <- data.frame(
        node = node_names,
        positive_fraction = pos_frac,
        stringsAsFactors = FALSE
      )
      df <- df[order(-df$positive_fraction), ]
      df$node <- factor(df$node, levels = df$node)

      colors <- ifelse(df$positive_fraction >= 0.5, "#2ecc71", "#e74c3c")

      plotly::plot_ly(df, x = ~node, y = ~positive_fraction, type = "bar",
                      marker = list(color = colors),
                      hoverinfo = "text",
                      text = ~paste(node, "<br>",
                                    round(positive_fraction * 100, 1), "%",
                                    " positive")) %>%
        plotly::layout(
          title = i18n$t("modules.analysis_simulation.outcome_distribution_title"),
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = i18n$t("modules.analysis_simulation.fraction_positive"),
                       range = c(0, 1)),
          showlegend = FALSE,
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, xref = "paper",
                 y0 = 0.5, y1 = 0.5, line = list(dash = "dash", color = "#999"))
          )
        )
    })

    # ── Download handler ─────────────────────────────────────────────────
    output$download_results <- downloadHandler(
      filename = function() {
        generate_export_filename("Simulation_Results", ".csv")
      },
      content = function(file) {
        if (rv$ss_complete && !is.null(rv$state_shift_result)) {
          fs <- rv$state_shift_result$final_states
          df <- as.data.frame(t(fs))
          write.csv(df, file, row.names = FALSE)
        } else if (rv$sim_complete && !is.null(rv$sim_result)) {
          ts <- rv$sim_result$time_series
          df <- as.data.frame(t(ts))
          write.csv(df, file, row.names = FALSE)
        }
      }
    )
  })
}
