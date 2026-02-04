# Network Metrics Analysis Module
# Extracted from analysis_tools_module.R
# Calculates and visualizes centrality metrics for CLD networks
# Note: igraph is loaded in global.R

analysis_metrics_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    uiOutput(ns("module_header")),

    # Check if CLD exists
    uiOutput(ns("cld_check_ui")),

    # Main metrics interface (shown only if CLD exists)
    uiOutput(ns("metrics_main_ui"))
  )
}

analysis_metrics_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for metrics
    metrics_rv <- reactiveValues(
      calculated_metrics = NULL,
      node_metrics_df = NULL
    )

    # === REACTIVE MODULE HEADER ===
    output$module_header <- renderUI({
      tagList(
        h2(icon("chart-line"), " ", i18n$t("modules.analysis.network.network_metrics_analysis")),
        p(i18n$t("modules.analysis.calculate_and_visualize_centrality_metrics_to_iden"))
      )
    })

    # Check if CLD data exists
    output$cld_check_ui <- renderUI({
      req(project_data_reactive())

      data <- project_data_reactive()

      if (is.null(data$data$cld) || is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        div(
          class = "alert alert-warning",
          icon("exclamation-triangle"), " ",
          strong(i18n$t("modules.analysis.common.no_cld_data_found")),
          p(i18n$t("modules.analysis.network.please_generate_a_cld_network_first_using"), style = "margin-top: 10px;"),
          tags$ol(
            tags$li(i18n$t("Navigate to 'ISA Data Entry' and complete your SES model")),
            tags$li(i18n$t("Go to 'CLD Visualization' and click 'Generate CLD'")),
            tags$li(i18n$t("modules.analysis.network.return_here_to_analyze_network_metrics"))
          )
        )
      } else {
        NULL  # CLD exists, show main UI
      }
    })

    # Main metrics UI
    output$metrics_main_ui <- renderUI({
      req(project_data_reactive())

      data <- project_data_reactive()
      if (is.null(data$data$cld) || is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        return(NULL)
      }

      tagList(
        fluidRow(
          column(12,
            actionButton(ns("calculate_metrics"),
                        i18n$t("modules.analysis.network.calculate_network_metrics"),
                        icon = icon("calculator"),
                        class = "btn-primary btn-lg")
          )
        ),

        hr(),

        # Results section (shown after calculation)
        uiOutput(ns("metrics_results_ui"))
      )
    })

    # Calculate metrics
    observeEvent(input$calculate_metrics, {
      # Cache reactive value once to avoid race conditions
      data <- project_data_reactive()
      req(data, data$data, data$data$cld, data$data$cld$nodes, data$data$cld$edges)

      tryCatch({
        nodes <- data$data$cld$nodes
        edges <- data$data$cld$edges

        # Calculate metrics
        metrics <- calculate_network_metrics(nodes, edges)

        # Store results
        metrics_rv$calculated_metrics <- metrics

        # Create node-level metrics dataframe
        node_metrics_df <- data.frame(
          ID = nodes$id,
          Label = nodes$label,
          Type = nodes$group,
          Degree = metrics$degree,
          InDegree = metrics$indegree,
          OutDegree = metrics$outdegree,
          Betweenness = round(metrics$betweenness, 2),
          Closeness = round(metrics$closeness, 4),
          Eigenvector = round(metrics$eigenvector, 4),
          PageRank = round(metrics$pagerank, 4),
          stringsAsFactors = FALSE
        )

        metrics_rv$node_metrics_df <- node_metrics_df

        showNotification(
          i18n$t("modules.analysis.network.network_metrics_calculated_successfully"),
          type = "message",
          duration = 3
        )

      }, error = function(e) {
        showNotification(
          paste(i18n$t("modules.analysis.network.error_calculating_metrics"), e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Metrics results UI
    output$metrics_results_ui <- renderUI({
      req(metrics_rv$calculated_metrics)

      metrics <- metrics_rv$calculated_metrics

      tagList(
        # Network-level metrics
        fluidRow(
          column(12,
            h3(icon("network-wired"), paste(" ", i18n$t("modules.analysis.network.network_summary")))
          )
        ),

        fluidRow(
          bs4ValueBox(
            value = metrics$nodes,
            subtitle = i18n$t("modules.analysis.common.total_nodes"),
            icon = icon("circle"),
            color = "primary",
            width = 3
          ),
          bs4ValueBox(
            value = metrics$edges,
            subtitle = i18n$t("modules.analysis.common.total_edges"),
            icon = icon("arrow-right"),
            color = "success",
            width = 3
          ),
          bs4ValueBox(
            value = round(metrics$density, 3),
            subtitle = i18n$t("modules.analysis.network.network_density"),
            icon = icon("project-diagram"),
            color = "secondary",
            width = 3
          ),
          bs4ValueBox(
            value = metrics$diameter,
            subtitle = i18n$t("modules.analysis.network.network_diameter"),
            icon = icon("arrows-alt"),
            color = "orange",
            width = 3
          )
        ),

        fluidRow(
          column(6,
            wellPanel(
              h5(icon("info-circle"), paste(" ", i18n$t("modules.analysis.common.average_path_length"))),
              h3(round(metrics$avg_path_length, 2)),
              p(class = "text-muted", i18n$t("modules.analysis.common.average_shortest_path_between_any_two_nodes"))
            )
          ),
          column(6,
            wellPanel(
              h5(icon("percentage"), paste(" ", i18n$t("modules.analysis.network.network_connectivity"))),
              h3(paste0(round(metrics$density * 100, 1), "%")),
              p(class = "text-muted", i18n$t("modules.analysis.common.percentage_of_possible_connections_that_exist"))
            )
          )
        ),

        hr(),

        # Node-level metrics
        fluidRow(
          column(12,
            h3(icon("users"), paste(" ", i18n$t("modules.analysis.network.node_level_centrality_metrics")))
          )
        ),

        fluidRow(
          column(12,
            tabsetPanel(
              id = ns("metrics_tabs"),

              # Metrics Table
              tabPanel(
                title = tagList(icon("table"), paste(" ", i18n$t("modules.analysis.network.all_metrics"))),
                br(),
                DTOutput(ns("metrics_table")),
                br(),
                downloadButton(ns("download_metrics"),
                              i18n$t("modules.analysis.network.download_network_metrics"),
                              class = "btn-success")
              ),

              # Visualizations
              tabPanel(
                title = tagList(icon("chart-bar"), paste(" ", i18n$t("modules.analysis.common.visualizations"))),
                br(),
                fluidRow(
                  column(6,
                    selectInput(ns("viz_metric"),
                               i18n$t("modules.analysis.network.select_metric"),
                               choices = c(
                                 "Degree Centrality" = "Degree",
                                 "Betweenness Centrality" = "Betweenness",
                                 "Closeness Centrality" = "Closeness",
                                 "Eigenvector Centrality" = "Eigenvector",
                                 "PageRank" = "PageRank"
                               ),
                               selected = "Degree")
                  ),
                  column(6,
                    numericInput(ns("top_n_nodes"),
                                i18n$t("modules.analysis.common.top_n_nodes"),
                                value = 10,
                                min = 5,
                                max = 50,
                                step = 5)
                  )
                ),
                fluidRow(
                  column(12,
                    plotOutput(ns("metrics_barplot"), height = "500px")
                  )
                ),
                hr(),
                fluidRow(
                  column(6,
                    wellPanel(
                      h5(i18n$t("modules.analysis.common.comparison_plot_degree_vs_betweenness")),
                      plotOutput(ns("metrics_comparison"), height = "400px")
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(i18n$t("modules.analysis.common.distribution_histogram")),
                      plotOutput(ns("metrics_histogram"), height = "400px")
                    )
                  )
                )
              ),

              # Key Nodes
              tabPanel(
                title = tagList(icon("star"), paste(" ", i18n$t("modules.analysis.common.key_nodes"))),
                br(),
                h4(i18n$t("modules.analysis.network.most_important_nodes_by_different_metrics")),
                fluidRow(
                  column(6,
                    wellPanel(
                      h5(icon("arrows-alt-h"), paste(" ", i18n$t("modules.analysis.common.top_5_nodes_by_degree"))),
                      p(class = "text-muted", i18n$t("modules.analysis.network.most_connected_nodes_in_the_network")),
                      tableOutput(ns("top_degree"))
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(icon("route"), paste(" ", i18n$t("modules.analysis.common.top_5_nodes_by_betweenness"))),
                      p(class = "text-muted", i18n$t("modules.analysis.common.critical_bridge_nodes_connecting_different_parts")),
                      tableOutput(ns("top_betweenness"))
                    )
                  )
                ),
                fluidRow(
                  column(6,
                    wellPanel(
                      h5(icon("compress-arrows-alt"), paste(" ", i18n$t("modules.analysis.common.top_5_nodes_by_closeness"))),
                      p(class = "text-muted", i18n$t("modules.analysis.common.most_central_nodes_with_shortest_paths_to_others")),
                      tableOutput(ns("top_closeness"))
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(icon("crown"), paste(" ", i18n$t("modules.analysis.common.top_5_nodes_by_pagerank"))),
                      p(class = "text-muted", i18n$t("modules.analysis.common.most_influential_nodes_based_on_incoming_connections")),
                      tableOutput(ns("top_pagerank"))
                    )
                  )
                )
              ),

              # Interpretation Guide
              tabPanel(
                title = tagList(icon("question-circle"), paste(" ", i18n$t("modules.analysis.common.guide"))),
                br(),
                h4(i18n$t("modules.analysis.network.understanding_centrality_metrics")),

                wellPanel(
                  h5(icon("info-circle"), paste(" ", i18n$t("modules.analysis.network.network_level_metrics"))),
                  tags$dl(
                    tags$dt(i18n$t("modules.analysis.network.network_density")),
                    tags$dd(i18n$t("modules.analysis.proportion_of_actual_connections_to_possible_conne")),

                    tags$dt(i18n$t("modules.analysis.network.network_diameter")),
                    tags$dd(i18n$t("modules.analysis.longest_shortest_path_between_any_two_nodes_indica")),

                    tags$dt(i18n$t("modules.analysis.common.average_path_length")),
                    tags$dd(i18n$t("modules.analysis.average_steps_needed_to_reach_any_node_from_any_ot"))
                  )
                ),

                wellPanel(
                  h5(icon("users"), paste(" ", i18n$t("modules.analysis.network.node_centrality_metrics"))),
                  tags$dl(
                    tags$dt(i18n$t("modules.analysis.common.degree_centrality")),
                    tags$dd(i18n$t("modules.analysis.number_of_direct_connections_high_degree_well_conn")),

                    tags$dt(i18n$t("modules.analysis.common.betweenness_centrality")),
                    tags$dd(i18n$t("modules.analysis.how_often_a_node_lies_on_shortest_paths_between_ot")),

                    tags$dt(i18n$t("modules.analysis.common.closeness_centrality")),
                    tags$dd(i18n$t("modules.analysis.how_close_a_node_is_to_all_other_nodes_high_closen")),

                    tags$dt(i18n$t("modules.analysis.common.eigenvector_centrality")),
                    tags$dd(i18n$t("modules.analysis.importance_based_on_connections_to_other_important")),

                    tags$dt(i18n$t("modules.analysis.common.pagerank")),
                    tags$dd(i18n$t("Google's algorithm: importance based on quality and quantity of incoming connections."))
                  )
                ),

                wellPanel(
                  h5(icon("lightbulb"), paste(" ", i18n$t("modules.analysis.common.practical_applications"))),
                  tags$ul(
                    tags$li(strong(i18n$t("modules.analysis.common.high_degree")), paste(" ", i18n$t("modules.analysis.common.target_for_broad_interventions"))),
                    tags$li(strong(i18n$t("modules.analysis.common.high_betweenness")), paste(" ", i18n$t("modules.analysis.leverage.leverage_points_for_system_change"))),
                    tags$li(strong(i18n$t("modules.analysis.common.high_closeness")), paste(" ", i18n$t("modules.analysis.common.efficient_information_spreaders"))),
                    tags$li(strong(i18n$t("modules.analysis.common.high_pagerank")), paste(" ", i18n$t("modules.analysis.common.most_influential_system_components")))
                  )
                )
              )
            )
          )
        )
      )
    })

    # Metrics table
    output$metrics_table <- renderDT({
      req(metrics_rv$node_metrics_df)

      datatable(
        metrics_rv$node_metrics_df,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          order = list(list(3, 'desc'))
        ),
        rownames = FALSE,
        filter = 'top'
      ) %>%
        formatStyle(
          'Degree',
          background = styleColorBar(metrics_rv$node_metrics_df$Degree, 'lightblue'),
          backgroundSize = '100% 90%',
          backgroundRepeat = 'no-repeat',
          backgroundPosition = 'center'
        )
    })

    # Metrics bar plot
    output$metrics_barplot <- renderPlot({
      req(metrics_rv$node_metrics_df, input$viz_metric, input$top_n_nodes)

      df <- metrics_rv$node_metrics_df
      metric_col <- input$viz_metric
      top_n <- min(input$top_n_nodes, nrow(df))

      # Get top N nodes by selected metric
      df_sorted <- df[order(-df[[metric_col]]), ][1:top_n, ]

      # Create bar plot
      par(mar = c(5, 12, 4, 2))
      barplot(
        rev(df_sorted[[metric_col]]),
        names.arg = rev(df_sorted$Label),
        horiz = TRUE,
        las = 1,
        col = colorRampPalette(c("#3498db", "#e74c3c"))(top_n),
        main = i18n$t("modules.analysis.network.bar_plot_top_nodes_by_selected_metric"),
        xlab = metric_col,
        cex.names = 0.8
      )
    })

    # Metrics comparison plot
    output$metrics_comparison <- renderPlot({
      req(metrics_rv$node_metrics_df)

      df <- metrics_rv$node_metrics_df

      # Normalize metrics to 0-1 scale for comparison
      df_norm <- df
      df_norm$Degree_norm <- df$Degree / max(df$Degree)
      df_norm$Betweenness_norm <- df$Betweenness / max(df$Betweenness)
      df_norm$PageRank_norm <- df$PageRank / max(df$PageRank)

      # Get top 10 by degree
      top10 <- df_norm[order(-df_norm$Degree), ][1:min(10, nrow(df_norm)), ]

      # Create comparison plot
      plot(top10$Degree_norm, top10$Betweenness_norm,
           xlim = c(0, 1), ylim = c(0, 1),
           xlab = i18n$t("modules.analysis.common.degree_centrality"),
           ylab = i18n$t("modules.analysis.common.betweenness_centrality"),
           main = i18n$t("modules.analysis.common.comparison_plot_degree_vs_betweenness"),
           pch = 19,
           cex = top10$PageRank_norm * 3 + 0.5,
           col = adjustcolor("#3498db", alpha = 0.6))

      text(top10$Degree_norm, top10$Betweenness_norm,
           labels = top10$Label,
           pos = 3,
           cex = 0.7)

      legend("topright",
             legend = i18n$t("modules.analysis.common.bubble_size_represents_pagerank"),
             bty = "n",
             cex = 0.8)

      abline(h = 0.5, v = 0.5, col = "gray", lty = 2)
    })

    # Metrics histogram
    output$metrics_histogram <- renderPlot({
      req(metrics_rv$node_metrics_df, input$viz_metric)

      df <- metrics_rv$node_metrics_df
      metric_col <- input$viz_metric
      values <- df[[metric_col]]

      hist(values,
           breaks = 20,
           col = "#3498db",
           border = "white",
           main = i18n$t("modules.analysis.common.distribution_histogram"),
           xlab = metric_col,
           ylab = i18n$t("modules.analysis.common.frequency"))

      abline(v = mean(values), col = "red", lwd = 2, lty = 2)
      abline(v = median(values), col = "darkgreen", lwd = 2, lty = 2)

      legend("topright",
             legend = c(i18n$t("modules.analysis.common.mean"), i18n$t("modules.analysis.common.median")),
             col = c("red", "darkgreen"),
             lty = 2,
             lwd = 2)
    })

    # Top nodes tables
    output$top_degree <- renderTable({
      req(metrics_rv$node_metrics_df)
      df <- metrics_rv$node_metrics_df[order(-metrics_rv$node_metrics_df$Degree), ][1:5, c("Label", "Type", "Degree")]
      df
    })

    output$top_betweenness <- renderTable({
      req(metrics_rv$node_metrics_df)
      df <- metrics_rv$node_metrics_df[order(-metrics_rv$node_metrics_df$Betweenness), ][1:5, c("Label", "Type", "Betweenness")]
      df
    })

    output$top_closeness <- renderTable({
      req(metrics_rv$node_metrics_df)
      df <- metrics_rv$node_metrics_df[order(-metrics_rv$node_metrics_df$Closeness), ][1:5, c("Label", "Type", "Closeness")]
      df
    })

    output$top_pagerank <- renderTable({
      req(metrics_rv$node_metrics_df)
      df <- metrics_rv$node_metrics_df[order(-metrics_rv$node_metrics_df$PageRank), ][1:5, c("Label", "Type", "PageRank")]
      df
    })

    # Download handler
    output$download_metrics <- downloadHandler(
      filename = function() {
        paste0("Network_Metrics_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        req(metrics_rv$node_metrics_df, metrics_rv$calculated_metrics)

        wb <- createWorkbook()

        # Add node-level metrics sheet
        addWorksheet(wb, "Node_Metrics")
        writeData(wb, "Node_Metrics", metrics_rv$node_metrics_df)

        # Add network-level metrics sheet
        network_metrics_df <- data.frame(
          Metric = c("Nodes", "Edges", "Density", "Diameter", "Avg Path Length"),
          Value = c(
            metrics_rv$calculated_metrics$nodes,
            metrics_rv$calculated_metrics$edges,
            round(metrics_rv$calculated_metrics$density, 4),
            metrics_rv$calculated_metrics$diameter,
            round(metrics_rv$calculated_metrics$avg_path_length, 4)
          )
        )
        addWorksheet(wb, "Network_Metrics")
        writeData(wb, "Network_Metrics", network_metrics_df)

        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

  })
}
