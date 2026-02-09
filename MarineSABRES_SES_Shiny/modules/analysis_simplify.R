# Simplification Tools Module
# Extracted from analysis_tools_module.R
# Purpose: Reduce network complexity while preserving essential structure
# Methods: SISO encapsulation, exogenous removal, weak edge filtering,
#          low-centrality node removal, strength-based aggregation

analysis_simplify_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    # Header with information
    uiOutput(ns("module_header")),

    hr(),

    # Network status panel
    fluidRow(
      column(12,
        bs4Card(
          title = i18n$t("modules.analysis.simplify.current_network_status"),
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,

          fluidRow(
            valueBoxOutput(ns("original_nodes_box"), width = 3),
            valueBoxOutput(ns("original_edges_box"), width = 3),
            valueBoxOutput(ns("simplified_nodes_box"), width = 3),
            valueBoxOutput(ns("simplified_edges_box"), width = 3)
          ),

          fluidRow(
            column(6,
              h4(i18n$t("modules.analysis.simplify.original_network_summary")),
              verbatimTextOutput(ns("original_summary"))
            ),
            column(6,
              h4(i18n$t("modules.analysis.simplify.simplified_network_summary")),
              verbatimTextOutput(ns("simplified_summary"))
            )
          )
        )
      )
    ),

    # Main simplification controls
    fluidRow(
      # Left panel - Simplification methods
      column(4,
        bs4Card(
          title = i18n$t("modules.analysis.simplify.simplification_methods"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,

          h4(icon("filter"), i18n$t("modules.analysis.simplify.select_methods")),
          p(class = "text-muted", i18n$t("modules.analysis.simplify.choose_techniques")),

          # Method 1: SISO Encapsulation
          checkboxInput(
            ns("method_siso"),
            label = strong(i18n$t("modules.analysis.simplify.siso_encapsulation")),
            value = FALSE
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("method_siso")),
            div(
              class = "well well-sm",
              p(icon("info-circle"),
                strong(i18n$t("modules.analysis.simplify.siso_info_title"))),
              p(class = "text-muted", style = "font-size: 12px;",
                i18n$t("modules.analysis.simplify.siso_description")
              ),
              tags$ul(
                tags$li(i18n$t("modules.analysis.simplify.siso_bullet_chains")),
                tags$li(i18n$t("modules.analysis.simplify.siso_bullet_polarity")),
                tags$li(i18n$t("modules.analysis.simplify.siso_bullet_structure"))
              )
            )
          ),

          hr(),

          # Method 2: Exogenous Variable Removal
          checkboxInput(
            ns("method_exogenous"),
            label = strong(i18n$t("modules.analysis.simplify.remove_exogenous")),
            value = FALSE
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("method_exogenous")),
            div(
              class = "well well-sm",
              p(icon("info-circle"),
                strong(i18n$t("modules.analysis.simplify.exogenous_info_title"))),
              p(class = "text-muted", style = "font-size: 12px;",
                i18n$t("modules.analysis.simplify.exogenous_description")
              ),
              tags$ul(
                tags$li(i18n$t("modules.analysis.simplify.exogenous_bullet_endogenous")),
                tags$li(i18n$t("modules.analysis.simplify.exogenous_bullet_feedback")),
                tags$li(i18n$t("modules.analysis.simplify.exogenous_bullet_degree"))
              ),
              checkboxInput(
                ns("exogenous_preview"),
                label = i18n$t("modules.analysis.common.preview_exogenous_nodes_before_removal"),
                value = TRUE
              )
            )
          ),

          hr(),

          # Method 3: Weak Connection Filtering
          checkboxInput(
            ns("method_weak_edges"),
            label = strong(i18n$t("modules.analysis.simplify.filter_weak_connections")),
            value = FALSE
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("method_weak_edges")),
            div(
              class = "well well-sm",
              p(icon("info-circle"),
                strong(i18n$t("modules.analysis.simplify.weak_conn_info_title"))),
              p(class = "text-muted", style = "font-size: 12px;",
                i18n$t("modules.analysis.simplify.weak_conn_description")
              ),
              radioButtons(
                ns("weak_edge_threshold"),
                i18n$t("modules.analysis.simplify.min_strength_to_keep"),
                choices = setNames(
                  c("medium", "strong"),
                  c(i18n$t("modules.analysis.simplify.keep_medium_strong"),
                    i18n$t("modules.analysis.simplify.keep_strong_only"))
                ),
                selected = "medium"
              ),
              tags$ul(
                tags$li(i18n$t("modules.analysis.simplify.weak_bullet_dominant")),
                tags$li(i18n$t("modules.analysis.simplify.weak_bullet_clutter")),
                tags$li(i18n$t("modules.analysis.simplify.weak_bullet_disconnect"))
              )
            )
          ),

          hr(),

          # Method 4: Low Centrality Node Removal
          checkboxInput(
            ns("method_low_centrality"),
            label = strong(i18n$t("modules.analysis.simplify.remove_low_centrality")),
            value = FALSE
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("method_low_centrality")),
            div(
              class = "well well-sm",
              p(icon("info-circle"),
                strong(i18n$t("modules.analysis.simplify.centrality_info_title"))),
              p(class = "text-muted", style = "font-size: 12px;",
                i18n$t("modules.analysis.simplify.centrality_description")
              ),
              selectInput(
                ns("centrality_metric"),
                i18n$t("modules.analysis.simplify.centrality_metric_label"),
                choices = setNames(
                  c("degree", "betweenness", "pagerank", "eigenvector"),
                  c(i18n$t("modules.analysis.simplify.metric_degree"),
                    i18n$t("modules.analysis.simplify.metric_betweenness"),
                    i18n$t("modules.analysis.simplify.metric_pagerank"),
                    i18n$t("modules.analysis.simplify.metric_eigenvector"))
                ),
                selected = "degree"
              ),
              sliderInput(
                ns("centrality_percentile"),
                i18n$t("modules.analysis.simplify.keep_above_percentile"),
                min = 0, max = 100, value = 50, step = 5,
                post = "%"
              ),
              tags$ul(
                tags$li(i18n$t("modules.analysis.simplify.centrality_bullet_important")),
                tags$li(i18n$t("modules.analysis.simplify.centrality_bullet_adjustable")),
                tags$li(i18n$t("modules.analysis.simplify.centrality_bullet_aspects"))
              )
            )
          ),

          hr(),

          # Method 5: Element Type Filtering
          checkboxInput(
            ns("method_element_filter"),
            label = strong(i18n$t("modules.analysis.simplify.filter_by_element_type")),
            value = FALSE
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("method_element_filter")),
            div(
              class = "well well-sm",
              p(icon("info-circle"),
                strong(i18n$t("modules.analysis.simplify.element_info_title"))),
              p(class = "text-muted", style = "font-size: 12px;",
                i18n$t("modules.analysis.simplify.element_description")
              ),
              checkboxGroupInput(
                ns("elements_to_keep"),
                i18n$t("modules.analysis.simplify.elements_to_keep"),
                choices = setNames(
                  c("Drivers", "Activities", "Pressures",
                    "Marine Processes & Functioning", "Ecosystem Services",
                    "Goods & Benefits"),
                  c(i18n$t("modules.analysis.simplify.elem_drivers"),
                    i18n$t("modules.analysis.simplify.elem_activities"),
                    i18n$t("modules.analysis.simplify.elem_pressures"),
                    i18n$t("modules.analysis.simplify.elem_marine_processes"),
                    i18n$t("modules.analysis.simplify.elem_ecosystem_services"),
                    i18n$t("modules.analysis.simplify.elem_goods_benefits"))
                ),
                selected = c("Drivers", "Activities", "Pressures",
                           "Marine Processes & Functioning", "Ecosystem Services",
                           "Goods & Benefits")
              )
            )
          ),

          hr(),

          # Action buttons
          fluidRow(
            column(6,
              actionButton(
                ns("apply_simplification"),
                i18n$t("modules.analysis.simplify.btn_apply"),
                icon = icon("compress"),
                class = "btn-primary btn-block"
              )
            ),
            column(6,
              actionButton(
                ns("reset_simplification"),
                i18n$t("modules.analysis.simplify.btn_reset"),
                icon = icon("undo"),
                class = "btn-warning btn-block"
              )
            )
          ),

          br(),

          # Save to project option
          checkboxInput(
            ns("save_to_project"),
            i18n$t("modules.analysis.simplify.save_simplification_to_project"),
            value = FALSE
          ),
          helpText(i18n$t("modules.analysis.simplify.save_simplification_warning")),

          br(),

          # Export simplified network
          downloadButton(
            ns("export_simplified"),
            i18n$t("modules.analysis.simplify.export_simplified_network"),
            class = "btn-success btn-block"
          ),

          br(),
          br(),

          # Restore original network (only show if network was saved with simplifications)
          conditionalPanel(
            condition = "output.has_saved_simplification",
            ns = ns,
            actionButton(
              ns("restore_original"),
              i18n$t("modules.analysis.network.restore_original_network"),
              icon = icon("history"),
              class = "btn-danger btn-block"
            ),
            helpText(i18n$t("modules.analysis.common.restore_original_warning"))
          )
        )
      ),

      # Right panel - Visualization comparison
      column(8,
        bs4Card(
          title = i18n$t("modules.analysis.simplify.network_visualization"),
          status = "success",
          solidHeader = TRUE,
          width = 12,

          tabsetPanel(
            id = ns("viz_tabs"),

            # Tab 1: Side-by-side comparison
            tabPanel(
              i18n$t("modules.analysis.simplify.tab_side_by_side"),
              icon = icon("columns"),

              br(),

              fluidRow(
                column(6,
                  h4(i18n$t("modules.analysis.simplify.original_network"), class = "text-center"),
                  visNetworkOutput(ns("original_network"), height = PLOT_HEIGHT_LG)
                ),
                column(6,
                  h4(i18n$t("modules.analysis.simplify.simplified_network"), class = "text-center"),
                  visNetworkOutput(ns("simplified_network"), height = PLOT_HEIGHT_LG)
                )
              ),

              br(),

              fluidRow(
                column(12,
                  h4(i18n$t("modules.analysis.simplify.simplification_statistics")),
                  tableOutput(ns("simplification_stats"))
                )
              )
            ),

            # Tab 2: Simplified view only
            tabPanel(
              i18n$t("modules.analysis.simplify.tab_simplified_view"),
              icon = icon("eye"),

              br(),

              fluidRow(
                column(12,
                  visNetworkOutput(ns("simplified_network_full"), height = PLOT_HEIGHT_XL)
                )
              ),

              br(),

              fluidRow(
                column(6,
                  h4(i18n$t("modules.analysis.simplify.removed_nodes")),
                  div(
                    style = "max-height: 200px; overflow-y: auto;",
                    tableOutput(ns("removed_nodes_table"))
                  )
                ),
                column(6,
                  h4(i18n$t("modules.analysis.simplify.removed_edges")),
                  div(
                    style = "max-height: 200px; overflow-y: auto;",
                    tableOutput(ns("removed_edges_table"))
                  )
                )
              )
            ),

            # Tab 3: Simplification history
            tabPanel(
              i18n$t("modules.analysis.simplify.tab_history"),
              icon = icon("history"),

              br(),

              h4(i18n$t("modules.analysis.simplify.applied_methods")),
              verbatimTextOutput(ns("simplification_log")),

              br(),

              h4(i18n$t("modules.analysis.simplify.impact_summary")),
              plotOutput(ns("impact_chart"), height = PLOT_HEIGHT_MD)
            )
          )
        )
      )
    ),

    # Information panel
    fluidRow(
      column(12,
        bs4Card(
          title = i18n$t("modules.analysis.simplify.about_simplification"),
          status = "info",
          solidHeader = FALSE,
          width = 12,
          collapsible = TRUE,
          collapsed = TRUE,

          h4(i18n$t("modules.analysis.simplify.about_why_title")),
          p(i18n$t("modules.analysis.simplify.about_why_description")),

          tags$ul(
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_better_communication"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_focused_analysis"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_computational_efficiency"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_pattern_recognition"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_scenario_testing")))
          ),

          h4(i18n$t("modules.analysis.simplify.about_best_practices_title")),
          tags$ol(
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_feedback"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_causality"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_document"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_validate"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_multiple"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_bp_iterate")))
          ),

          h4(i18n$t("modules.analysis.simplify.about_recommendations_title")),
          tags$ul(
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_rec_internal"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_rec_visual"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_rec_leverage"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_rec_sector"))),
            tags$li(HTML(i18n$t("modules.analysis.simplify.about_rec_maximum")))
          )
        )
      )
    )
  )
}

analysis_simplify_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    # ========== REACTIVE VALUES ==========
    rv <- reactiveValues(
      original_nodes = NULL,
      original_edges = NULL,
      simplified_nodes = NULL,
      simplified_edges = NULL,
      removed_nodes = NULL,
      removed_edges = NULL,
      simplification_history = list(),
      has_simplified = FALSE
    )

    # === REACTIVE MODULE HEADER ===
    output$module_header <- renderUI({
      fluidRow(
        column(12,
          h2(icon("compress-arrows-alt"), i18n$t("modules.analysis.simplify.model_simplification_tools")),
          p(class = "text-muted",
            i18n$t("modules.analysis.simplify.header_description")
          )
        )
      )
    })

    # ========== LOAD ORIGINAL NETWORK ==========
    observe({
      req(project_data_reactive()$data$cld$nodes)
      req(project_data_reactive()$data$cld$edges)

      rv$original_nodes <- project_data_reactive()$data$cld$nodes
      rv$original_edges <- project_data_reactive()$data$cld$edges
      rv$simplified_nodes <- project_data_reactive()$data$cld$nodes
      rv$simplified_edges <- project_data_reactive()$data$cld$edges
      rv$has_simplified <- FALSE
    })

    # ========== VALUE BOXES ==========
    output$original_nodes_box <- renderValueBox({
      node_count <- if (!is.null(rv$original_nodes)) nrow(rv$original_nodes) else 0
      bs4ValueBox(
        node_count,
        i18n$t("modules.analysis.simplify.original_nodes"),
        icon = icon("circle"),
        color = "primary"
      )
    })

    output$original_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$original_edges)) nrow(rv$original_edges) else 0
      bs4ValueBox(
        edge_count,
        i18n$t("modules.analysis.simplify.original_edges"),
        icon = icon("arrow-right"),
        color = "primary"
      )
    })

    output$simplified_nodes_box <- renderValueBox({
      node_count <- if (!is.null(rv$simplified_nodes)) nrow(rv$simplified_nodes) else 0
      reduction <- if (!is.null(rv$original_nodes) && !is.null(rv$simplified_nodes)) {
        pct <- round((1 - nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) * 100, 1)
        paste0(" (", pct, "% ", i18n$t("modules.analysis.simplify.reduction_pct"), ")")
      } else ""

      bs4ValueBox(
        paste0(node_count, reduction),
        i18n$t("modules.analysis.simplify.simplified_nodes_label"),
        icon = icon("circle"),
        color = if (rv$has_simplified) "success" else "info"
      )
    })

    output$simplified_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$simplified_edges)) nrow(rv$simplified_edges) else 0
      reduction <- if (!is.null(rv$original_edges) && !is.null(rv$simplified_edges)) {
        pct <- round((1 - nrow(rv$simplified_edges) / nrow(rv$original_edges)) * 100, 1)
        paste0(" (", pct, "% ", i18n$t("modules.analysis.simplify.reduction_pct"), ")")
      } else ""

      bs4ValueBox(
        paste0(edge_count, reduction),
        i18n$t("modules.analysis.simplify.simplified_edges_label"),
        icon = icon("arrow-right"),
        color = if (rv$has_simplified) "success" else "info"
      )
    })

    # ========== NETWORK SUMMARIES ==========
    output$original_summary <- renderPrint({
      req(rv$original_nodes, rv$original_edges)

      cat(i18n$t("modules.analysis.simplify.network_components"), "\n")
      cat("------------------\n")

      element_counts <- table(rv$original_nodes$group)
      for (elem in names(element_counts)) {
        cat(sprintf("  %s: %d\n", elem, element_counts[elem]))
      }

      cat("\n", i18n$t("modules.analysis.simplify.connection_strengths"), "\n")
      cat("--------------------\n")
      strength_counts <- table(rv$original_edges$strength)
      for (strength in names(strength_counts)) {
        cat(sprintf("  %s: %d\n", strength, strength_counts[strength]))
      }

      cat("\n", i18n$t("modules.analysis.simplify.polarity_distribution"), "\n")
      cat("---------------------\n")
      polarity_counts <- table(rv$original_edges$polarity)
      for (pol in names(polarity_counts)) {
        pol_name <- ifelse(pol == "+", i18n$t("modules.analysis.simplify.reinforcing"),
                          i18n$t("modules.analysis.simplify.opposing"))
        cat(sprintf("  %s (%s): %d\n", pol_name, pol, polarity_counts[pol]))
      }
    })

    output$simplified_summary <- renderPrint({
      if (!rv$has_simplified) {
        cat(i18n$t("modules.analysis.simplify.no_simplification_yet"), "\n\n")
        cat(i18n$t("modules.analysis.simplify.select_methods_instruction"))
        return()
      }

      req(rv$simplified_nodes, rv$simplified_edges)

      cat(i18n$t("modules.analysis.simplify.network_components"), "\n")
      cat("------------------\n")

      element_counts <- table(rv$simplified_nodes$group)
      for (elem in names(element_counts)) {
        cat(sprintf("  %s: %d\n", elem, element_counts[elem]))
      }

      cat("\n", i18n$t("modules.analysis.simplify.connection_strengths"), "\n")
      cat("--------------------\n")
      strength_counts <- table(rv$simplified_edges$strength)
      for (strength in names(strength_counts)) {
        cat(sprintf("  %s: %d\n", strength, strength_counts[strength]))
      }

      cat("\n", i18n$t("modules.analysis.simplify.polarity_distribution"), "\n")
      cat("---------------------\n")
      polarity_counts <- table(rv$simplified_edges$polarity)
      for (pol in names(polarity_counts)) {
        pol_name <- ifelse(pol == "+", i18n$t("modules.analysis.simplify.reinforcing"),
                          i18n$t("modules.analysis.simplify.opposing"))
        cat(sprintf("  %s (%s): %d\n", pol_name, pol, polarity_counts[pol]))
      }

      cat("\n")
      cat(sprintf("%s %d\n", i18n$t("modules.analysis.simplify.nodes_removed_count"), nrow(rv$removed_nodes)))
      cat(sprintf("%s %d\n", i18n$t("modules.analysis.simplify.edges_removed_count"), nrow(rv$removed_edges)))
    })

    # ========== APPLY SIMPLIFICATION ==========
    observeEvent(input$apply_simplification, {
      req(rv$original_nodes, rv$original_edges)

      tryCatch({
      # Start with original network
      nodes <- rv$original_nodes
      edges <- rv$original_edges
      history <- list()

      # Track what was removed
      all_removed_nodes <- data.frame()
      all_removed_edges <- data.frame()

      withProgress(message = i18n$t("modules.analysis.simplify.progress_applying"), value = 0, {

        # Method 1: SISO Encapsulation
        if (input$method_siso) {
          incProgress(0.15, detail = i18n$t("modules.analysis.simplify.progress_siso"))

          siso_info <- identify_siso_variables(nodes, edges)

          if (nrow(siso_info) > 0) {
            result <- encapsulate_siso_variables(nodes, edges, siso_info)

            removed_nodes <- nodes %>% filter(id %in% siso_info$id)
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_siso")))

            nodes <- result$nodes
            edges <- result$edges

            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_siso_encapsulation"),
              removed_nodes = nrow(siso_info),
              description = sprintf(i18n$t("modules.analysis.simplify.hist_encapsulated_fmt"), nrow(siso_info))
            )))
          } else {
            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_siso_encapsulation"),
              removed_nodes = 0,
              description = i18n$t("modules.analysis.simplify.hist_no_siso_found")
            )))
          }
        }

        # Method 2: Remove Exogenous Variables
        if (input$method_exogenous) {
          incProgress(0.15, detail = i18n$t("modules.analysis.simplify.progress_exogenous"))

          exog_ids <- identify_exogenous_variables(nodes, edges)

          if (length(exog_ids) > 0) {
            removed_nodes <- nodes %>% filter(id %in% exog_ids)
            removed_edges <- edges %>% filter(from %in% exog_ids)

            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_exogenous")))
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_connected_exogenous")))

            result <- remove_exogenous_variables(nodes, edges, exog_ids)
            nodes <- result$nodes
            edges <- result$edges

            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_exogenous_removal"),
              removed_nodes = length(exog_ids),
              description = sprintf(i18n$t("modules.analysis.simplify.hist_removed_exogenous_fmt"), length(exog_ids))
            )))
          } else {
            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_exogenous_removal"),
              removed_nodes = 0,
              description = i18n$t("modules.analysis.simplify.hist_no_exogenous_found")
            )))
          }
        }

        # Method 3: Filter Weak Connections
        if (input$method_weak_edges) {
          incProgress(0.15, detail = i18n$t("modules.analysis.simplify.progress_weak"))

          if (input$weak_edge_threshold == "medium") {
            removed_edges <- edges %>% filter(strength == "weak")
            edges_filtered <- edges %>% filter(strength != "weak")
          } else { # strong only
            removed_edges <- edges %>% filter(strength != "strong")
            edges_filtered <- edges %>% filter(strength == "strong")
          }

          all_removed_edges <- bind_rows(all_removed_edges,
                                        removed_edges %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_weak_connection")))

          # Remove orphaned nodes
          connected_nodes <- unique(c(edges_filtered$from, edges_filtered$to))
          orphaned_nodes <- nodes %>% filter(!id %in% connected_nodes)

          if (nrow(orphaned_nodes) > 0) {
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          orphaned_nodes %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_orphaned")))
          }

          nodes <- nodes %>% filter(id %in% connected_nodes)
          edges <- edges_filtered

          history <- append(history, list(list(
            method = i18n$t("modules.analysis.simplify.hist_weak_edge_filtering"),
            removed_edges = nrow(removed_edges),
            removed_nodes = nrow(orphaned_nodes),
            description = sprintf(i18n$t("modules.analysis.simplify.hist_weak_edges_fmt"),
                                nrow(removed_edges), nrow(orphaned_nodes))
          )))
        }

        # Method 4: Remove Low Centrality Nodes
        if (input$method_low_centrality) {
          incProgress(0.15, detail = i18n$t("modules.analysis.simplify.progress_centrality"))

          metrics <- calculate_network_metrics(nodes, edges)
          metric_values <- metrics[[input$centrality_metric]]

          threshold_value <- quantile(metric_values, probs = input$centrality_percentile / 100)

          below_threshold <- names(metric_values)[metric_values < threshold_value]

          if (length(below_threshold) > 0) {
            removed_nodes <- nodes %>% filter(id %in% below_threshold)
            removed_edges <- edges %>% filter(from %in% below_threshold | to %in% below_threshold)

            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(
                                            reason = sprintf(i18n$t("modules.analysis.simplify.reason_low_centrality_fmt"), input$centrality_metric)))
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_connected_low_centrality")))

            nodes <- nodes %>% filter(!id %in% below_threshold)
            edges <- edges %>% filter(!from %in% below_threshold, !to %in% below_threshold)

            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_low_centrality_removal"),
              metric = input$centrality_metric,
              percentile = input$centrality_percentile,
              removed_nodes = length(below_threshold),
              description = sprintf(i18n$t("modules.analysis.simplify.hist_low_centrality_fmt"),
                                  length(below_threshold), input$centrality_percentile,
                                  input$centrality_metric)
            )))
          }
        }

        # Method 5: Element Type Filtering
        if (input$method_element_filter) {
          incProgress(0.15, detail = i18n$t("modules.analysis.simplify.progress_element_type"))

          removed_nodes <- nodes %>% filter(!group %in% input$elements_to_keep)

          if (nrow(removed_nodes) > 0) {
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_element_excluded")))

            removed_edges <- edges %>% filter(from %in% removed_nodes$id | to %in% removed_nodes$id)
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = i18n$t("modules.analysis.simplify.reason_connected_excluded")))

            nodes <- nodes %>% filter(group %in% input$elements_to_keep)
            edges <- edges %>% filter(!from %in% removed_nodes$id, !to %in% removed_nodes$id)

            history <- append(history, list(list(
              method = i18n$t("modules.analysis.simplify.hist_element_type_filtering"),
              removed_nodes = nrow(removed_nodes),
              description = sprintf(i18n$t("modules.analysis.simplify.hist_kept_only_fmt"), paste(input$elements_to_keep, collapse = ", "))
            )))
          }
        }

        incProgress(0.25, detail = i18n$t("modules.analysis.simplify.progress_finalizing"))

        # Update reactive values
        rv$simplified_nodes <- nodes
        rv$simplified_edges <- edges
        rv$removed_nodes <- all_removed_nodes
        rv$removed_edges <- all_removed_edges
        rv$simplification_history <- history
        rv$has_simplified <- TRUE

        # Save to project if checkbox is checked
        if (isTRUE(input$save_to_project)) {
          data <- project_data_reactive()

          # Store original for undo capability (only if not already stored)
          if (is.null(data$data$cld$original_nodes)) {
            data$data$cld$original_nodes <- data$data$cld$nodes
            data$data$cld$original_edges <- data$data$cld$edges
          }

          # Save simplified network
          data$data$cld$nodes <- rv$simplified_nodes
          data$data$cld$edges <- rv$simplified_edges
          data$data$cld$removed_nodes <- rv$removed_nodes
          data$data$cld$simplification_history <- rv$simplification_history
          data$last_modified <- Sys.time()

          project_data_reactive(data)

          showNotification(
            i18n$t("modules.analysis.network.simplified_network_saved"),
            type = "success",
            duration = 4
          )
        }
      })

      showNotification(
        ifelse(isTRUE(input$save_to_project),
          i18n$t("modules.analysis.simplify.simplification_applied_and_saved"),
          i18n$t("modules.analysis.simplify.simplification_applied")
        ),
        type = "message",
        duration = 3
      )
      }, error = function(e) {
        debug_log(paste("Error in simplification:", e$message), "SIMPLIFY")
        showNotification(
          paste(i18n$t("modules.analysis.simplify.error_applying"), e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # ========== RESET SIMPLIFICATION ==========
    observeEvent(input$reset_simplification, {
      rv$simplified_nodes <- rv$original_nodes
      rv$simplified_edges <- rv$original_edges
      rv$removed_nodes <- data.frame()
      rv$removed_edges <- data.frame()
      rv$simplification_history <- list()
      rv$has_simplified <- FALSE

      showNotification(
        i18n$t("modules.analysis.simplify.network_reset"),
        type = "warning",
        duration = 3
      )
    })

    # ========== RESTORE ORIGINAL NETWORK (UNDO PERMANENT SAVE) ==========
    observeEvent(input$restore_original, {
      data <- project_data_reactive()

      if (!is.null(data$data$cld$original_nodes)) {
        data$data$cld$nodes <- data$data$cld$original_nodes
        data$data$cld$edges <- data$data$cld$original_edges

        data$data$cld$original_nodes <- NULL
        data$data$cld$original_edges <- NULL
        data$data$cld$removed_nodes <- NULL
        data$data$cld$simplification_history <- NULL
        data$last_modified <- Sys.time()

        project_data_reactive(data)

        rv$original_nodes <- data$data$cld$nodes
        rv$original_edges <- data$data$cld$edges
        rv$simplified_nodes <- data$data$cld$nodes
        rv$simplified_edges <- data$data$cld$edges
        rv$removed_nodes <- data.frame()
        rv$removed_edges <- data.frame()
        rv$simplification_history <- list()
        rv$has_simplified <- FALSE

        showNotification(
          i18n$t("modules.analysis.network.original_network_restored"),
          type = "success",
          duration = 4
        )
      } else {
        showNotification(
          i18n$t("modules.analysis.common.no_original_to_restore"),
          type = "warning",
          duration = 3
        )
      }
    })

    # ========== OUTPUT FOR CONDITIONAL PANEL ==========
    output$has_saved_simplification <- reactive({
      data <- project_data_reactive()
      !is.null(data$data$cld$original_nodes)
    })
    outputOptions(output, "has_saved_simplification", suspendWhenHidden = FALSE)

    # ========== VISUALIZATIONS ==========

    # Helper to build a standard visNetwork with common options
    build_vis_network <- function(nodes, edges, height = PLOT_HEIGHT_LG, zoom = FALSE) {
      visNetwork(nodes, edges, height = height) %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(stabilization = TRUE, barnesHut = list(gravitationalConstant = -2000, springLength = 200)) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE, zoomView = zoom)
    }

    output$original_network <- renderVisNetwork({
      req(rv$original_nodes, rv$original_edges)
      build_vis_network(rv$original_nodes, rv$original_edges)
    })

    output$simplified_network <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)
      build_vis_network(rv$simplified_nodes, rv$simplified_edges)
    })

    output$simplified_network_full <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)
      build_vis_network(rv$simplified_nodes, rv$simplified_edges, height = PLOT_HEIGHT_XL, zoom = TRUE)
    })

    # ========== STATISTICS AND TABLES ==========

    output$simplification_stats <- renderTable({
      req(rv$original_nodes, rv$original_edges, rv$simplified_nodes, rv$simplified_edges)

      stats_df <- data.frame(
        Metric = c(i18n$t("modules.analysis.simplify.stat_total_nodes"),
                   i18n$t("modules.analysis.simplify.stat_total_edges"),
                   i18n$t("modules.analysis.simplify.stat_avg_degree"),
                   i18n$t("modules.analysis.simplify.stat_network_density")),
        Original = c(
          nrow(rv$original_nodes),
          nrow(rv$original_edges),
          round(2 * nrow(rv$original_edges) / nrow(rv$original_nodes), 2),
          round(nrow(rv$original_edges) / (nrow(rv$original_nodes) * (nrow(rv$original_nodes) - 1)), 3)
        ),
        Simplified = c(
          nrow(rv$simplified_nodes),
          nrow(rv$simplified_edges),
          if(nrow(rv$simplified_nodes) > 0) round(2 * nrow(rv$simplified_edges) / nrow(rv$simplified_nodes), 2) else 0,
          if(nrow(rv$simplified_nodes) > 1) round(nrow(rv$simplified_edges) / (nrow(rv$simplified_nodes) * (nrow(rv$simplified_nodes) - 1)), 3) else 0
        ),
        Change = c(
          sprintf("%+d (%.1f%%)",
                  nrow(rv$simplified_nodes) - nrow(rv$original_nodes),
                  ((nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) - 1) * 100),
          sprintf("%+d (%.1f%%)",
                  nrow(rv$simplified_edges) - nrow(rv$original_edges),
                  ((nrow(rv$simplified_edges) / nrow(rv$original_edges)) - 1) * 100),
          "-",
          "-"
        )
      )
      colnames(stats_df) <- c(
        i18n$t("modules.analysis.simplify.table_metric"),
        i18n$t("modules.analysis.simplify.stat_original"),
        i18n$t("modules.analysis.simplify.stat_simplified"),
        i18n$t("modules.analysis.simplify.stat_change")
      )
      stats_df
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    output$removed_nodes_table <- renderTable({
      if (!rv$has_simplified || is.null(rv$removed_nodes) || nrow(rv$removed_nodes) == 0) {
        df <- data.frame(x = i18n$t("modules.analysis.simplify.no_nodes_removed"))
        colnames(df) <- i18n$t("modules.analysis.simplify.table_message")
        return(df)
      }

      result <- rv$removed_nodes %>%
        select(id, label, group, reason) %>%
        head(50)
      colnames(result) <- c(
        i18n$t("modules.analysis.simplify.table_id"),
        i18n$t("modules.analysis.simplify.table_label"),
        i18n$t("modules.analysis.simplify.table_type"),
        i18n$t("modules.analysis.simplify.table_reason")
      )
      result
    }, striped = TRUE, hover = TRUE)

    output$removed_edges_table <- renderTable({
      if (!rv$has_simplified || is.null(rv$removed_edges) || nrow(rv$removed_edges) == 0) {
        df <- data.frame(x = i18n$t("modules.analysis.simplify.no_edges_removed"))
        colnames(df) <- i18n$t("modules.analysis.simplify.table_message")
        return(df)
      }

      result <- rv$removed_edges %>%
        select(from, to, polarity, strength, reason) %>%
        head(50)
      colnames(result) <- c(
        i18n$t("modules.analysis.simplify.table_from"),
        i18n$t("modules.analysis.simplify.table_to"),
        i18n$t("modules.analysis.simplify.table_polarity"),
        i18n$t("modules.analysis.simplify.table_strength"),
        i18n$t("modules.analysis.simplify.table_reason")
      )
      result
    }, striped = TRUE, hover = TRUE)

    # ========== SIMPLIFICATION LOG ==========
    output$simplification_log <- renderPrint({
      if (!rv$has_simplified || length(rv$simplification_history) == 0) {
        cat(i18n$t("modules.analysis.simplify.no_methods_applied"), "\n")
        return()
      }

      cat(i18n$t("modules.analysis.simplify.log_title"), "\n")
      cat("======================\n\n")

      for (i in seq_along(rv$simplification_history)) {
        item <- rv$simplification_history[[i]]
        cat(sprintf("%s %d: %s\n", i18n$t("modules.analysis.simplify.log_step"), i, item$method))
        cat(sprintf("  %s\n", item$description))
        if (!is.null(item$removed_nodes) && item$removed_nodes > 0) {
          cat(sprintf("  %s %d\n", i18n$t("modules.analysis.simplify.log_nodes_removed"), item$removed_nodes))
        }
        if (!is.null(item$removed_edges) && item$removed_edges > 0) {
          cat(sprintf("  %s %d\n", i18n$t("modules.analysis.simplify.log_edges_removed"), item$removed_edges))
        }
        cat("\n")
      }

      cat(i18n$t("modules.analysis.simplify.log_total_impact"), "\n")
      cat("------------\n")
      cat(sprintf("%s %d (%.1f%%)\n",
                  i18n$t("modules.analysis.simplify.log_total_nodes"),
                  nrow(rv$removed_nodes),
                  (nrow(rv$removed_nodes) / nrow(rv$original_nodes)) * 100))
      cat(sprintf("%s %d (%.1f%%)\n",
                  i18n$t("modules.analysis.simplify.log_total_edges"),
                  nrow(rv$removed_edges),
                  (nrow(rv$removed_edges) / nrow(rv$original_edges)) * 100))
    })

    # ========== IMPACT CHART ==========
    output$impact_chart <- renderPlot({
      if (!rv$has_simplified) {
        plot.new()
        text(0.5, 0.5, i18n$t("modules.analysis.simplify.apply_to_see_chart"), cex = 1.5)
        return()
      }

      req(rv$original_nodes, rv$simplified_nodes, rv$original_edges, rv$simplified_edges)

      orig_label <- i18n$t("modules.analysis.simplify.stat_original")
      simp_label <- i18n$t("modules.analysis.simplify.stat_simplified")
      nodes_label <- i18n$t("modules.analysis.simplify.chart_nodes")
      edges_label <- i18n$t("modules.analysis.simplify.chart_edges")

      comparison_data <- data.frame(
        Category = rep(c(nodes_label, edges_label), each = 2),
        State = rep(c(orig_label, simp_label), 2),
        Count = c(
          nrow(rv$original_nodes),
          nrow(rv$simplified_nodes),
          nrow(rv$original_edges),
          nrow(rv$simplified_edges)
        )
      )
      comparison_data$State <- factor(comparison_data$State, levels = c(orig_label, simp_label))

      ggplot(comparison_data, aes(x = Category, y = Count, fill = State)) +
        geom_bar(stat = "identity", position = "dodge", width = 0.7) +
        geom_text(aes(label = Count), position = position_dodge(0.7), vjust = -0.5, size = 5) +
        scale_fill_manual(values = setNames(c("#3498db", "#27ae60"), c(orig_label, simp_label))) +
        labs(
          title = i18n$t("modules.analysis.simplify.chart_title"),
          subtitle = sprintf(i18n$t("modules.analysis.simplify.chart_subtitle_fmt"),
                           (1 - nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) * 100,
                           (1 - nrow(rv$simplified_edges) / nrow(rv$original_edges)) * 100),
          x = "",
          y = i18n$t("modules.analysis.simplify.chart_count"),
          fill = i18n$t("modules.analysis.simplify.chart_network_state")
        ) +
        theme_minimal(base_size = 14) +
        theme(
          plot.title = element_text(face = "bold", size = 16),
          plot.subtitle = element_text(color = "gray40"),
          legend.position = "top"
        )
    })

    # ========== EXPORT SIMPLIFIED NETWORK ==========
    output$export_simplified <- downloadHandler(
      filename = function() {
        paste0("simplified_network_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".RData")
      },
      content = function(file) {
        simplified_network <- list(
          nodes = rv$simplified_nodes,
          edges = rv$simplified_edges,
          removed_nodes = rv$removed_nodes,
          removed_edges = rv$removed_edges,
          history = rv$simplification_history,
          original_node_count = nrow(rv$original_nodes),
          original_edge_count = nrow(rv$original_edges),
          timestamp = Sys.time()
        )
        save(simplified_network, file = file)

        showNotification(
          i18n$t("modules.analysis.simplify.export_success"),
          type = "message",
          duration = 3
        )
      }
    )

  })
}
