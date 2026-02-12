# modules/analysis_boolean.R
# =============================================================================
# Boolean Network & Laplacian Stability Analysis Module
#
# Provides:
#   - Laplacian eigenvalue analysis (structural stability characterization)
#   - Boolean network rule generation and attractor analysis
#   - Combined stability interpretation
#
# Depends on: functions/ses_dynamics.R, functions/cld_validation.R,
#             functions/ui_helpers.R
# =============================================================================

# ============================================================================
# UI FUNCTION
# ============================================================================

analysis_boolean_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    # Reactive module header
    uiOutput(ns("module_header")),

    # CLD data validation gate
    uiOutput(ns("cld_check_ui")),

    # Main content (only shown if CLD data exists)
    uiOutput(ns("main_ui"))
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

analysis_boolean_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Local reactive state ─────────────────────────────────────────────
    rv <- reactiveValues(
      numeric_matrix = NULL,
      laplacian_results = NULL,
      boolean_rules = NULL,
      boolean_results = NULL,
      analysis_complete = FALSE,
      error_message = NULL
    )

    # ── Standard header + help ───────────────────────────────────────────
    create_reactive_header(
      output = output,
      ns = ns,
      title_key = "modules.analysis_boolean.title",
      subtitle_key = "modules.analysis_boolean.subtitle",
      help_id = "help_boolean",
      i18n = i18n
    )

    create_help_observer(
      input = input,
      input_id = "help_boolean",
      title_key = "modules.analysis_boolean.help_title",
      content = tagList(
        h4(i18n$t("modules.analysis_boolean.help_heading")),
        p(i18n$t("modules.analysis_boolean.help_laplacian")),
        p(i18n$t("modules.analysis_boolean.help_boolean")),
        p(i18n$t("modules.analysis_boolean.help_interpretation"))
      ),
      i18n = i18n
    )

    # ── CLD validation gate ──────────────────────────────────────────────
    setup_cld_gate(output, project_data_reactive, i18n,
      "modules.analysis_boolean.no_cld_data",
      "modules.analysis_boolean.no_cld_data_hint"
    )

    # ── Main UI ──────────────────────────────────────────────────────────
    output$main_ui <- renderUI({
      data <- project_data_reactive()
      if (is.null(data) || !has_valid_cld(data)) return(NULL)

      n_nodes <- nrow(data$data$cld$nodes)
      n_edges <- nrow(data$data$cld$edges)

      tagList(
        fluidRow(
          # ── Controls panel ──
          column(4,
            bs4Card(
              title = tagList(icon("cogs"), " ", i18n$t("modules.analysis_boolean.controls")),
              width = 12, collapsible = FALSE, status = "primary",

              # Network info
              tags$div(
                class = "alert alert-info", style = "padding: 10px;",
                icon("project-diagram"), " ",
                strong(n_nodes), " ", i18n$t("modules.analysis_boolean.nodes"), ", ",
                strong(n_edges), " ", i18n$t("modules.analysis_boolean.edges")
              ),

              # Laplacian direction
              radioButtons(
                ns("laplacian_direction"), i18n$t("modules.analysis_boolean.laplacian_direction"),
                choices = setNames(c("cols", "rows"),
                  c(i18n$t("modules.analysis_boolean.out_degree"),
                    i18n$t("modules.analysis_boolean.in_degree"))),
                selected = "cols"
              ),

              # Boolean node limit
              sliderInput(
                ns("max_boolean_nodes"),
                i18n$t("modules.analysis_boolean.max_nodes"),
                min = 5, max = 30, value = DYNAMICS_MAX_BOOLEAN_NODES, step = 1
              ),

              # Boolean feasibility warning
              uiOutput(ns("boolean_feasibility_warning")),

              # Weight mapping option
              checkboxInput(
                ns("include_confidence"),
                i18n$t("modules.analysis_boolean.scale_by_confidence"),
                value = FALSE
              ),

              hr(),

              # Run button
              actionButton(
                ns("run_analysis"),
                tagList(icon("play"), " ", i18n$t("modules.analysis_boolean.run_analysis")),
                class = "btn-primary btn-block",
                style = "margin-bottom: 10px;"
              ),

              # Download button
              conditionalPanel(
                condition = sprintf("output['%s'] === true", ns("analysis_done")),
                downloadButton(
                  ns("download_results"),
                  tagList(icon("download"), " ", i18n$t("modules.analysis_boolean.download")),
                  class = "btn-outline-success btn-block"
                )
              )
            )
          ),

          # ── Results panel ──
          column(8,
            uiOutput(ns("results_ui"))
          )
        )
      )
    })

    # ── Boolean feasibility warning ──────────────────────────────────────
    output$boolean_feasibility_warning <- renderUI({
      data <- project_data_reactive()
      req(data, data$data$cld$nodes)
      n <- nrow(data$data$cld$nodes)
      max_n <- input$max_boolean_nodes %||% DYNAMICS_MAX_BOOLEAN_NODES

      if (n > max_n) {
        div(
          class = "alert alert-warning", style = "padding: 8px; font-size: 13px;",
          icon("exclamation-triangle"), " ",
          sprintf(i18n$t("modules.analysis_boolean.too_many_nodes"), n, max_n),
          tags$br(),
          tags$small(i18n$t("modules.analysis_boolean.simplify_hint"))
        )
      } else if (n > 20) {
        div(
          class = "alert alert-info", style = "padding: 8px; font-size: 13px;",
          icon("info-circle"), " ",
          sprintf(i18n$t("modules.analysis_boolean.many_nodes_warning"), n, 2^n)
        )
      }
    })

    # ── Analysis done flag for conditional UI ────────────────────────────
    output$analysis_done <- reactive({ rv$analysis_complete })
    outputOptions(output, "analysis_done", suspendWhenHidden = FALSE)

    # ── Run analysis ─────────────────────────────────────────────────────
    observeEvent(input$run_analysis, {
      data <- project_data_reactive()
      req(data, has_valid_cld(data))

      rv$analysis_complete <- FALSE
      rv$error_message <- NULL

      withProgress(message = i18n$t("modules.analysis_boolean.running"), value = 0, {

        # Step 1: Build numeric matrix
        incProgress(0.1, detail = i18n$t("modules.analysis_boolean.building_matrix"))
        tryCatch({
          rv$numeric_matrix <- cld_to_numeric_matrix(
            data$data$cld$nodes,
            data$data$cld$edges,
            use_labels = TRUE,
            include_confidence = input$include_confidence
          )
        }, error = function(e) {
          rv$error_message <- paste("Matrix construction error:", e$message)
          return()
        })
        if (is.null(rv$numeric_matrix)) return()

        # Step 2: Laplacian eigenvalues
        incProgress(0.3, detail = i18n$t("modules.analysis_boolean.computing_laplacian"))
        tryCatch({
          rv$laplacian_results <- ses_laplacian_eigenvalues(
            rv$numeric_matrix,
            direction = input$laplacian_direction
          )
        }, error = function(e) {
          rv$error_message <- paste("Laplacian error:", e$message)
        })

        # Step 3: Boolean rules
        incProgress(0.2, detail = i18n$t("modules.analysis_boolean.creating_rules"))
        tryCatch({
          rv$boolean_rules <- ses_create_boolean_rules(rv$numeric_matrix)
        }, error = function(e) {
          rv$error_message <- paste("Boolean rules error:", e$message)
        })

        # Step 4: Boolean attractors (if within node limit)
        n_nodes <- nrow(rv$numeric_matrix)
        max_nodes <- input$max_boolean_nodes %||% DYNAMICS_MAX_BOOLEAN_NODES

        if (!is.null(rv$boolean_rules) && n_nodes <= max_nodes) {
          incProgress(0.3, detail = i18n$t("modules.analysis_boolean.finding_attractors"))
          tryCatch({
            rv$boolean_results <- ses_boolean_attractors(
              rv$boolean_rules, max_nodes = max_nodes
            )
          }, error = function(e) {
            rv$error_message <- paste("Attractor analysis error:", e$message)
          })
        } else if (n_nodes > max_nodes) {
          rv$boolean_results <- NULL
        }

        incProgress(0.1, detail = i18n$t("modules.analysis_boolean.complete"))
        rv$analysis_complete <- TRUE

        # Save results to project data
        data$data$analysis$dynamics$numeric_matrix <- rv$numeric_matrix
        data$data$analysis$dynamics$matrix_params <- list(
          source = "cld",
          include_confidence = input$include_confidence,
          timestamp = Sys.time()
        )
        if (!is.null(rv$laplacian_results)) {
          data$data$analysis$dynamics$laplacian <- c(
            rv$laplacian_results,
            list(timestamp = Sys.time())
          )
        }
        if (!is.null(rv$boolean_results)) {
          data$data$analysis$dynamics$boolean <- list(
            rules = rv$boolean_rules,
            n_states = rv$boolean_results$n_states,
            n_attractors = rv$boolean_results$n_attractors,
            attractors = rv$boolean_results$attractors,
            basins = rv$boolean_results$basins,
            timestamp = Sys.time()
          )
        }
        data$last_modified <- Sys.time()
        project_data_reactive(data)
      })
    })

    # ── Results rendering ────────────────────────────────────────────────
    output$results_ui <- renderUI({
      if (!rv$analysis_complete) {
        return(div(
          style = "text-align: center; padding: 60px; color: #999;",
          icon("flask", class = "fa-3x"), tags$br(), tags$br(),
          p(i18n$t("modules.analysis_boolean.click_to_start"))
        ))
      }

      # Error display
      if (!is.null(rv$error_message)) {
        return(div(
          class = "alert alert-danger", style = "margin: 10px;",
          icon("exclamation-circle"), " ", rv$error_message
        ))
      }

      tabsetPanel(
        id = ns("results_tabs"), type = "pills",

        # Tab 1: Laplacian Eigenvalues
        tabPanel(
          title = tagList(icon("chart-bar"), " ", i18n$t("modules.analysis_boolean.laplacian_tab")),
          value = "laplacian",
          tags$div(style = "padding: 15px;",
            uiOutput(ns("laplacian_summary")),
            shinycssloaders::withSpinner(
              plotly::plotlyOutput(ns("laplacian_plot"), height = PLOT_HEIGHT_MD)
            ),
            hr(),
            DT::DTOutput(ns("laplacian_table"))
          )
        ),

        # Tab 2: Boolean Network
        tabPanel(
          title = tagList(icon("sitemap"), " ", i18n$t("modules.analysis_boolean.boolean_tab")),
          value = "boolean",
          tags$div(style = "padding: 15px;",
            uiOutput(ns("boolean_summary")),
            uiOutput(ns("boolean_content"))
          )
        ),

        # Tab 3: Stability Summary
        tabPanel(
          title = tagList(icon("clipboard-check"), " ", i18n$t("modules.analysis_boolean.stability_tab")),
          value = "stability",
          tags$div(style = "padding: 15px;",
            uiOutput(ns("stability_summary"))
          )
        )
      )
    })

    # ── Laplacian plot ───────────────────────────────────────────────────
    output$laplacian_plot <- plotly::renderPlotly({
      req(rv$laplacian_results)
      eigs <- rv$laplacian_results$eigenvalues

      df <- data.frame(
        node = names(eigs),
        eigenvalue = as.numeric(eigs),
        stringsAsFactors = FALSE
      )
      df <- df[order(df$eigenvalue), ]
      df$node <- factor(df$node, levels = df$node)

      colors <- ifelse(abs(df$eigenvalue) < 1e-10, "#e74c3c",
                 ifelse(df$eigenvalue > 0, "#3498db", "#e67e22"))

      p <- plotly::plot_ly(df, x = ~node, y = ~eigenvalue, type = "bar",
                            marker = list(color = colors),
                            hoverinfo = "text",
                            text = ~paste(node, "<br>", round(eigenvalue, 4))) %>%
        plotly::layout(
          title = i18n$t("modules.analysis_boolean.eigenvalues_chart_title"),
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = i18n$t("modules.analysis_boolean.eigenvalue")),
          showlegend = FALSE
        )
      p
    })

    output$laplacian_summary <- renderUI({
      req(rv$laplacian_results)
      res <- rv$laplacian_results

      tagList(
        fluidRow(
          column(4,
            bs4ValueBox(
              value = round(res$fiedler_value, 4),
              subtitle = i18n$t("modules.analysis_boolean.fiedler_value"),
              icon = icon("wave-square"), color = "primary", width = 12
            )
          ),
          column(4,
            bs4ValueBox(
              value = res$n_components,
              subtitle = i18n$t("modules.analysis_boolean.connected_components"),
              icon = icon("project-diagram"), color = "info", width = 12
            )
          ),
          column(4,
            bs4ValueBox(
              value = length(res$eigenvalues),
              subtitle = i18n$t("modules.analysis_boolean.total_eigenvalues"),
              icon = icon("hashtag"), color = "success", width = 12
            )
          )
        )
      )
    })

    output$laplacian_table <- DT::renderDT({
      req(rv$laplacian_results)
      eigs <- rv$laplacian_results$eigenvalues
      df <- data.frame(
        Node = names(eigs),
        Eigenvalue = round(as.numeric(eigs), 6),
        stringsAsFactors = FALSE
      )
      DT::datatable(df, options = list(pageLength = 15, scrollX = TRUE),
                    rownames = FALSE)
    })

    # ── Boolean content ──────────────────────────────────────────────────
    output$boolean_summary <- renderUI({
      if (is.null(rv$boolean_results)) {
        n_nodes <- if (!is.null(rv$numeric_matrix)) nrow(rv$numeric_matrix) else 0
        return(div(
          class = "alert alert-warning",
          icon("exclamation-triangle"), " ",
          sprintf(i18n$t("modules.analysis_boolean.boolean_skipped"), n_nodes)
        ))
      }

      res <- rv$boolean_results
      fluidRow(
        column(3,
          bs4ValueBox(
            value = res$n_genes,
            subtitle = i18n$t("modules.analysis_boolean.genes"),
            icon = icon("dna"), color = "primary", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = format(res$n_states, big.mark = ","),
            subtitle = i18n$t("modules.analysis_boolean.state_space"),
            icon = icon("th"), color = "info", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = res$n_attractors,
            subtitle = i18n$t("modules.analysis_boolean.attractors_found"),
            icon = icon("bullseye"), color = "success", width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = paste0(max(res$basins), "/", res$n_states),
            subtitle = i18n$t("modules.analysis_boolean.largest_basin"),
            icon = icon("water"), color = "warning", width = 12
          )
        )
      )
    })

    output$boolean_content <- renderUI({
      if (is.null(rv$boolean_results)) return(NULL)
      res <- rv$boolean_results

      tagList(
        # Basin sizes chart
        h5(icon("chart-pie"), " ", i18n$t("modules.analysis_boolean.basin_sizes")),
        shinycssloaders::withSpinner(
          plotly::plotlyOutput(ns("basin_plot"), height = PLOT_HEIGHT_SM)
        ),
        hr(),
        # Boolean rules table
        h5(icon("list"), " ", i18n$t("modules.analysis_boolean.boolean_rules")),
        DT::DTOutput(ns("rules_table")),
        hr(),
        # Attractor details
        h5(icon("bullseye"), " ", i18n$t("modules.analysis_boolean.attractor_details")),
        uiOutput(ns("attractor_details"))
      )
    })

    output$basin_plot <- plotly::renderPlotly({
      req(rv$boolean_results)
      basins <- rv$boolean_results$basins
      df <- data.frame(
        attractor = paste("Attractor", seq_along(basins)),
        basin_size = basins,
        stringsAsFactors = FALSE
      )

      plotly::plot_ly(df, labels = ~attractor, values = ~basin_size,
                      type = "pie",
                      textinfo = "label+percent",
                      hoverinfo = "text",
                      text = ~paste(attractor, "<br>Basin size:", basin_size)) %>%
        plotly::layout(title = i18n$t("modules.analysis_boolean.basin_distribution"))
    })

    output$rules_table <- DT::renderDT({
      req(rv$boolean_rules)
      DT::datatable(rv$boolean_rules,
                    options = list(pageLength = 20, scrollX = TRUE),
                    rownames = FALSE,
                    colnames = c(i18n$t("modules.analysis_boolean.target"),
                                 i18n$t("modules.analysis_boolean.rule")))
    })

    output$attractor_details <- renderUI({
      req(rv$boolean_results)
      attractors <- rv$boolean_results$attractors
      if (length(attractors) == 0) return(p(i18n$t("modules.analysis_boolean.no_attractors")))

      tagList(
        lapply(seq_along(attractors), function(i) {
          att <- attractors[[i]]
          basin <- rv$boolean_results$basins[i]
          bs4Card(
            title = paste(i18n$t("modules.analysis_boolean.attractor"), i,
                          "-", i18n$t("modules.analysis_boolean.basin_size"), basin),
            width = 12, collapsible = TRUE, collapsed = (i > 3),
            status = if (i == which.max(rv$boolean_results$basins)) "success" else "secondary",
            if (nrow(att) > 0) {
              DT::renderDT(DT::datatable(att, options = list(scrollX = TRUE,
                                                               pageLength = 5),
                                          rownames = FALSE))
            } else {
              p(i18n$t("modules.analysis_boolean.empty_attractor"))
            }
          )
        })
      )
    })

    # ── Stability summary ────────────────────────────────────────────────
    output$stability_summary <- renderUI({
      req(rv$analysis_complete)

      cards <- list()

      # Laplacian interpretation
      if (!is.null(rv$laplacian_results)) {
        fiedler <- rv$laplacian_results$fiedler_value
        n_comp <- rv$laplacian_results$n_components
        stability_class <- if (fiedler > 1) "high" else if (fiedler > 0.1) "moderate" else "low"
        stability_color <- switch(stability_class,
          "high" = "success", "moderate" = "warning", "low" = "danger")

        cards <- c(cards, list(
          bs4Card(
            title = tagList(icon("wave-square"), " ",
                            i18n$t("modules.analysis_boolean.laplacian_interpretation")),
            width = 12, status = stability_color,
            tags$p(
              strong(i18n$t("modules.analysis_boolean.algebraic_connectivity")), ": ",
              round(fiedler, 4)
            ),
            tags$p(
              strong(i18n$t("modules.analysis_boolean.connected_components")), ": ", n_comp
            ),
            tags$p(
              i18n$t(paste0("modules.analysis_boolean.stability_", stability_class))
            )
          )
        ))
      }

      # Boolean interpretation
      if (!is.null(rv$boolean_results)) {
        n_att <- rv$boolean_results$n_attractors
        max_basin <- max(rv$boolean_results$basins)
        total_states <- rv$boolean_results$n_states
        dominance <- round(max_basin / total_states * 100, 1)

        cards <- c(cards, list(
          bs4Card(
            title = tagList(icon("sitemap"), " ",
                            i18n$t("modules.analysis_boolean.boolean_interpretation")),
            width = 12, status = if (n_att <= 3) "success" else "warning",
            tags$p(
              strong(i18n$t("modules.analysis_boolean.n_stable_states")), ": ", n_att
            ),
            tags$p(
              strong(i18n$t("modules.analysis_boolean.dominant_basin")), ": ",
              dominance, "%"
            ),
            tags$p(
              if (n_att == 1) i18n$t("modules.analysis_boolean.single_attractor_text")
              else if (n_att <= 3) i18n$t("modules.analysis_boolean.few_attractors_text")
              else i18n$t("modules.analysis_boolean.many_attractors_text")
            )
          )
        ))
      }

      tagList(cards)
    })

    # ── Download handler ─────────────────────────────────────────────────
    output$download_results <- downloadHandler(
      filename = function() {
        generate_export_filename("Boolean_Stability_Analysis", ".csv")
      },
      content = function(file) {
        sheets <- list()
        if (!is.null(rv$laplacian_results)) {
          eigs <- rv$laplacian_results$eigenvalues
          sheets$laplacian <- data.frame(
            Node = names(eigs), Eigenvalue = as.numeric(eigs),
            stringsAsFactors = FALSE
          )
        }
        if (!is.null(rv$boolean_rules)) {
          sheets$boolean_rules <- rv$boolean_rules
        }
        # Write the first available sheet as CSV
        if (length(sheets) > 0) {
          write.csv(sheets[[1]], file, row.names = FALSE)
        }
      }
    )

  })
}
