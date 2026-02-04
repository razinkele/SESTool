# Leverage Point Analysis Module
# Extracted from analysis_tools_module.R
# Identifies and ranks nodes with highest potential for system-wide impact

#' Leverage Point Analysis UI
#'
#' @param id Module ID
#' @return UI elements
analysis_leverage_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    uiOutput(ns("module_header")),

    fluidRow(
      column(4,
        wellPanel(
          h4(icon("sliders-h"), " ", i18n$t("modules.analysis.leverage.analysis_settings")),
          sliderInput(
            ns("top_n"),
            "Number of Top Nodes:",
            min = 5,
            max = 20,
            value = 10,
            step = 1
          ),
          actionButton(
            ns("calculate_leverage"),
            i18n$t("modules.analysis.leverage.btn_calculate"),
            icon = icon("calculator"),
            class = "btn-primary btn-block"
          ),
          br(),
          div(
            style = "background: #e8f4f8; padding: 10px; border-radius: 5px; border-left: 4px solid #17a2b8;",
            h5(icon("info-circle"), " ", i18n$t("modules.analysis.leverage.about_leverage_points")),
            p("Leverage points are nodes that have the highest potential for system-wide impact based on:"),
            tags$ul(
              tags$li(strong("Betweenness:"), " Control over information flow"),
              tags$li(strong("Eigenvector:"), " Connection to other important nodes"),
              tags$li(strong("PageRank:"), " Overall importance in the network")
            )
          )
        )
      ),

      column(8,
        tabsetPanel(
          id = ns("leverage_tabs"),

          # Results Tab
          tabPanel(
            title = tagList(icon("list"), " ", i18n$t("modules.analysis.leverage.tab_leverage_points")),
            value = "results",
            br(),
            uiOutput(ns("leverage_status")),
            br(),
            DT::dataTableOutput(ns("leverage_table"))
          ),

          # Network Visualization Tab
          tabPanel(
            title = tagList(icon("project-diagram"), " ", i18n$t("modules.analysis.leverage.tab_network_view")),
            value = "network",
            br(),
            div(
              style = "background: #f8f9fa; padding: 10px; border-radius: 5px; margin-bottom: 15px;",
              icon("info-circle"), " Node sizes reflect composite leverage scores. Larger nodes = higher leverage."
            ),
            visNetworkOutput(ns("leverage_network"), height = "600px")
          ),

          # Interpretation Tab
          tabPanel(
            title = tagList(icon("lightbulb"), " ", i18n$t("modules.analysis.leverage.tab_interpretation")),
            value = "interpretation",
            br(),
            uiOutput(ns("interpretation_ui"))
          )
        )
      )
    )
  )
}

#' Leverage Point Analysis Server
#'
#' @param id Module ID
#' @param project_data_reactive Reactive project data
#' @return Server logic
analysis_leverage_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    # Reactive values
    rv <- reactiveValues(
      leverage_results = NULL,
      has_data = FALSE
    )

    # === REACTIVE MODULE HEADER ===
    create_reactive_header(
      output = output,
      ns = session$ns,
      title_key = "modules.analysis.leverage.title",
      subtitle_key = "modules.analysis.leverage.subtitle",
      help_id = "help_leverage",
      i18n = i18n
    )

    # Check if data exists
    observe({
      project_data <- project_data_reactive()

      isa_data <- project_data$data$isa_data

      if (!is.null(isa_data)) {
        nodes <- create_nodes_df(isa_data)
        edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

        rv$has_data <- !is.null(nodes) && nrow(nodes) > 0 &&
                       !is.null(edges) && nrow(edges) > 0
      } else {
        rv$has_data <- FALSE
      }
    })

    # Calculate leverage points
    observeEvent(input$calculate_leverage, {
      req(rv$has_data)

      project_data <- project_data_reactive()

      withProgress(message = "Analyzing leverage points...", value = 0, {

        tryCatch({
          incProgress(0.2, detail = "Building network from ISA data...")

          isa_data <- project_data$data$isa_data
          nodes <- create_nodes_df(isa_data)
          edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

          incProgress(0.4, detail = "Creating network graph...")

          all_centralities <- calculate_all_centralities(
            graph_from_data_frame(
              edges %>% select(from, to, polarity),
              directed = TRUE,
              vertices = nodes %>% select(id, label, group)
            )
          )

          # Add composite scores
          all_centralities$Composite_Score <- safe_scale(all_centralities$Betweenness) +
                                               safe_scale(all_centralities$Eigenvector) +
                                               safe_scale(all_centralities$PageRank)

          incProgress(0.6, detail = "Ranking nodes...")

          # Get top leverage points
          leverage_df <- all_centralities[order(-all_centralities$Composite_Score), ]
          leverage_df <- head(leverage_df, min(input$top_n, nrow(leverage_df)))

          # Store results
          rv$leverage_results <- leverage_df

          incProgress(0.8, detail = "Updating node attributes...")

          # Update nodes with leverage scores and centrality metrics
          nodes$leverage_score <- NA_real_
          nodes$in_degree <- NA_real_
          nodes$out_degree <- NA_real_
          nodes$betweenness <- NA_real_

          for (i in 1:nrow(all_centralities)) {
            node_label <- all_centralities$Name[i]
            node_idx <- which(nodes$label == node_label)
            if (length(node_idx) > 0) {
              nodes$leverage_score[node_idx[1]] <- all_centralities$Composite_Score[i]
              nodes$in_degree[node_idx[1]] <- all_centralities$In_Degree[i]
              nodes$out_degree[node_idx[1]] <- all_centralities$Out_Degree[i]
              nodes$betweenness[node_idx[1]] <- all_centralities$Betweenness[i]
            }
          }

          # Save updated nodes AND edges back to project_data
          project_data <- project_data_reactive()
          project_data$data$cld$nodes <- nodes
          project_data$data$cld$edges <- edges
          project_data$last_modified <- Sys.time()
          project_data_reactive(project_data)

          incProgress(1.0, detail = "Complete!")

          showNotification(
            paste("Found", nrow(leverage_df), "leverage points! Scores saved to CLD nodes."),
            type = "message",
            duration = 3
          )

        }, error = function(e) {
          showNotification(
            paste("Error analyzing leverage points:", e$message),
            type = "error",
            duration = 10
          )
        })
      })
    })

    # Status output
    output$leverage_status <- renderUI({
      if (!rv$has_data) {
        div(
          class = "alert alert-warning",
          icon("exclamation-triangle"), " ",
          strong("No network data available."),
          " Please create your SES network first using the ",
          tags$em("Create SES"),
          " menu."
        )
      } else if (is.null(rv$leverage_results)) {
        div(
          class = "alert alert-info",
          icon("info-circle"), " ",
          "Click ", strong("Calculate Leverage Points"), " to analyze your network."
        )
      } else {
        div(
          class = "alert alert-success",
          icon("check-circle"), " ",
          strong(sprintf("Found %d leverage points", nrow(rv$leverage_results))),
          " - Nodes are ranked by their composite influence score."
        )
      }
    })

    # Leverage points table
    output$leverage_table <- DT::renderDataTable({
      req(rv$leverage_results)

      df <- rv$leverage_results

      # Format for display
      df_display <- data.frame(
        Rank = 1:nrow(df),
        Node = df$Name,
        `Composite Score` = round(df$Composite_Score, 3),
        Betweenness = round(df$Betweenness, 2),
        Eigenvector = round(df$Eigenvector, 3),
        PageRank = round(df$PageRank, 3),
        `In-Degree` = df$In_Degree,
        `Out-Degree` = df$Out_Degree,
        check.names = FALSE
      )

      DT::datatable(
        df_display,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          dom = 't',
          ordering = FALSE
        ),
        rownames = FALSE
      ) %>%
        DT::formatStyle(
          'Composite Score',
          background = DT::styleColorBar(df_display$`Composite Score`, '#4CAF50'),
          backgroundSize = '100% 80%',
          backgroundRepeat = 'no-repeat',
          backgroundPosition = 'center'
        )
    })

    # Leverage network visualization
    output$leverage_network <- renderVisNetwork({
      req(rv$leverage_results)

      tryCatch({
        project_data <- project_data_reactive()
        isa_data <- project_data$data$isa_data
        req(isa_data)

        # Build network
        nodes <- create_nodes_df(isa_data)
        edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

        # Map leverage scores to nodes
        leverage_df <- rv$leverage_results
        leverage_lookup <- setNames(leverage_df$Composite_Score, leverage_df$ID)

        # Add leverage scores to nodes
        nodes$leverage_score <- leverage_lookup[nodes$id]
        nodes$leverage_score[is.na(nodes$leverage_score)] <- 0

        # Normalize scores to node sizes (15-60 range for better visibility)
        min_score <- min(nodes$leverage_score, na.rm = TRUE)
        max_score <- max(nodes$leverage_score, na.rm = TRUE)

        if (max_score > min_score) {
          nodes$size <- 15 + ((nodes$leverage_score - min_score) / (max_score - min_score)) * 45
        } else {
          nodes$size <- 30
        }

        # Override node colors by leverage score (gradient from yellow to green)
        if (max_score > min_score) {
          score_normalized <- (nodes$leverage_score - min_score) / (max_score - min_score)
          color_idx <- pmax(1, pmin(100, round(score_normalized * 99) + 1))
          nodes$color <- colorRampPalette(c("#FFC107", "#4CAF50"))(100)[color_idx]
        } else {
          nodes$color <- "#4CAF50"
        }

        # Override tooltips to include leverage score
        nodes$title <- paste0(
          "<b>", nodes$label, "</b><br>",
          "Type: ", nodes$group, "<br>",
          "Leverage Score: ", sprintf("%.3f", nodes$leverage_score)
        )

        # Build visNetwork
        visNetwork(nodes, edges, width = "100%", height = "600px") %>%
          visNodes(shape = "dot", font = list(size = 14)) %>%
          visEdges(arrows = "to", smooth = list(enabled = TRUE, type = "continuous")) %>%
          visOptions(highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE), nodesIdSelection = FALSE) %>%
          visInteraction(navigationButtons = TRUE, hover = TRUE, tooltipDelay = 100) %>%
          visLayout(randomSeed = 42) %>%
          visPhysics(
            stabilization = list(iterations = 200),
            solver = "forceAtlas2Based",
            forceAtlas2Based = list(gravitationalConstant = -50, springLength = 100)
          )
      }, error = function(e) {
        debug_log(paste("Leverage network error:", conditionMessage(e)), "LEVERAGE")
        return(NULL)
      })
    })

    # Interpretation guide
    output$interpretation_ui <- renderUI({
      req(rv$leverage_results)

      top_node <- rv$leverage_results$Name[1]
      top_score <- round(rv$leverage_results$Composite_Score[1], 2)

      tagList(
        div(
          class = "well",
          style = "background: #f8f9fa;",

          h4(icon("star"), " ", i18n$t("modules.analysis.leverage.top_leverage_point")),
          p(
            strong(top_node),
            sprintf(" has the highest composite score (%.2f) and represents the most strategic intervention point in your network.", top_score)
          ),

          hr(),

          h4(icon("chart-line"), " ", i18n$t("modules.analysis.leverage.understanding_metrics")),

          h5(icon("exchange-alt"), " Betweenness Centrality"),
          p("Measures how often a node lies on the shortest path between other nodes. High betweenness means the node controls information flow and serves as a bridge."),

          h5(icon("network-wired"), " Eigenvector Centrality"),
          p("Measures a node's influence based on the importance of its neighbors. A node with high eigenvector centrality is connected to other important nodes."),

          h5(icon("sitemap"), " PageRank"),
          p("Originally developed for web pages, PageRank measures importance based on incoming connections and the importance of source nodes."),

          hr(),

          h4(icon("lightbulb"), " ", i18n$t("modules.analysis.leverage.intervention_strategies")),
          tags$ul(
            tags$li(
              strong("Direct Intervention: "), "Focus management actions directly on high-leverage nodes"
            ),
            tags$li(
              strong("Monitoring: "), "Track changes in leverage points as early warning indicators"
            ),
            tags$li(
              strong("Policy Design: "), "Design policies that strengthen or weaken connections to leverage points"
            ),
            tags$li(
              strong("Stakeholder Engagement: "), "Prioritize engagement with actors associated with these nodes"
            )
          )
        )
      )
    })

    # Help Modal ----
    create_help_observer(
      input = input,
      input_id = "help_leverage",
      title_key = "modules.analysis.leverage.help_title",
      content = tagList(
        h4(i18n$t("modules.analysis.leverage.what_are_leverage_points")),
        p(i18n$t("modules.analysis.leverage_points_are_nodes_in_your_network_that_hav")),

        hr(),
        h5(i18n$t("modules.analysis.network.metrics_used")),
        tags$ul(
          tags$li(
            strong("Betweenness Centrality: "),
            i18n$t("modules.analysis.betweenness_centrality_measures_how_often_a_node_a")
          ),
          tags$li(
            strong("Eigenvector Centrality: "),
            i18n$t("modules.analysis.eigenvector_centrality_measures_the_influence_of_a")
          ),
          tags$li(
            strong("PageRank: "),
            i18n$t("PageRank: Google's algorithm adapted for network analysis. Measures overall importance considering both direct connections and the importance of connecting nodes.")
          ),
          tags$li(
            strong("Composite Score: "),
            i18n$t("modules.analysis.composite_score_a_combined_metric_that_sums_the_no")
          )
        ),

        hr(),
        h5(i18n$t("modules.analysis.common.how_to_interpret_results")),
        tags$ul(
          tags$li(
            strong("High Composite Score: "),
            i18n$t("modules.analysis.high_composite_score_these_nodes_are_your_top_leve")
          ),
          tags$li(
            strong("High Betweenness: "),
            i18n$t("modules.analysis.high_betweenness_focus_on_nodes_that_control_infor")
          ),
          tags$li(
            strong("High Eigenvector: "),
            i18n$t("High Eigenvector: Target nodes that are influential because they're connected to other influential nodes.")
          ),
          tags$li(
            strong("High PageRank: "),
            i18n$t("modules.analysis.high_pagerank_these_nodes_have_broad_influence_acr")
          )
        ),

        hr(),
        h5(i18n$t("modules.analysis.leverage.using_leverage_points_for_intervention_design")),
        tags$ul(
          tags$li(
            strong("Prioritize interventions: "),
            i18n$t("modules.analysis.prioritize_interventions_focus_resources_on_high_l")
          ),
          tags$li(
            strong("Consider node type: "),
            i18n$t("modules.analysis.consider_node_type_different_types_of_nodes_driver")
          ),
          tags$li(
            strong("Combine with loop analysis: "),
            i18n$t("modules.analysis.combine_with_loop_anlys_nodes_that_appear_in_multi")
          )
        )
      ),
      i18n = i18n
    )

  })
}
