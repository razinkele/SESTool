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
          p(class = "text-muted", "Choose one or more simplification techniques:"),

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
                strong("Single-Input-Single-Output (SISO) Variables")),
              p(class = "text-muted", style = "font-size: 12px;",
                "Identifies nodes with exactly one incoming and one outgoing connection. ",
                "Creates a 'bridge' edge that preserves the causal relationship while removing the intermediate node."
              ),
              tags$ul(
                tags$li("Reduces chains of simple relationships"),
                tags$li("Preserves polarity through the chain"),
                tags$li("Maintains overall network structure")
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
                strong("Exogenous Variables (External Drivers)")),
              p(class = "text-muted", style = "font-size: 12px;",
                "Identifies nodes with outgoing connections but no incoming connections. ",
                "These are external drivers that influence the system but are not influenced by it."
              ),
              tags$ul(
                tags$li("Focuses on endogenous dynamics"),
                tags$li("Useful for understanding internal feedback"),
                tags$li("Removes nodes with outdegree > 0, indegree = 0")
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
                strong("Connection Strength Filtering")),
              p(class = "text-muted", style = "font-size: 12px;",
                "Removes connections below a specified strength threshold to focus on dominant causal relationships."
              ),
              radioButtons(
                ns("weak_edge_threshold"),
                "Minimum strength to keep:",
                choices = c(
                  "Keep Medium & Strong only" = "medium",
                  "Keep Strong only" = "strong"
                ),
                selected = "medium"
              ),
              tags$ul(
                tags$li("Highlights dominant relationships"),
                tags$li("Reduces visual clutter"),
                tags$li("May disconnect some nodes")
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
                strong("Centrality-Based Filtering")),
              p(class = "text-muted", style = "font-size: 12px;",
                "Removes peripheral nodes with low importance based on network centrality metrics."
              ),
              selectInput(
                ns("centrality_metric"),
                "Centrality metric:",
                choices = c(
                  "Degree (Total connections)" = "degree",
                  "Betweenness (Bridge importance)" = "betweenness",
                  "PageRank (Influence score)" = "pagerank",
                  "Eigenvector (Connected to important nodes)" = "eigenvector"
                ),
                selected = "degree"
              ),
              sliderInput(
                ns("centrality_percentile"),
                "Keep nodes above percentile:",
                min = 0, max = 100, value = 50, step = 5,
                post = "%"
              ),
              tags$ul(
                tags$li("Focuses on structurally important nodes"),
                tags$li("Adjustable threshold for control"),
                tags$li("Different metrics highlight different aspects")
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
                strong("DAPSI(W)R(M) Element Selection")),
              p(class = "text-muted", style = "font-size: 12px;",
                "Focus on specific components of the SES framework."
              ),
              checkboxGroupInput(
                ns("elements_to_keep"),
                "Elements to keep:",
                choices = c(
                  "Drivers" = "Drivers",
                  "Activities" = "Activities",
                  "Pressures" = "Pressures",
                  "Marine Processes & Functioning" = "Marine Processes & Functioning",
                  "Ecosystem Services" = "Ecosystem Services",
                  "Goods & Benefits" = "Goods & Benefits"
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
            "Export Simplified Network",
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
                  visNetworkOutput(ns("original_network"), height = "500px")
                ),
                column(6,
                  h4(i18n$t("modules.analysis.simplify.simplified_network"), class = "text-center"),
                  visNetworkOutput(ns("simplified_network"), height = "500px")
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
                  visNetworkOutput(ns("simplified_network_full"), height = "600px")
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
              plotOutput(ns("impact_chart"), height = "400px")
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

          h4("Why Simplify Networks?"),
          p("Complex social-ecological systems often contain hundreds of variables and connections. ",
            "While comprehensive models capture full system complexity, simplified models offer:"),

          tags$ul(
            tags$li(strong("Better Communication:"), " Easier to explain to stakeholders and decision-makers"),
            tags$li(strong("Focused Analysis:"), " Concentrate on key drivers and feedback loops"),
            tags$li(strong("Computational Efficiency:"), " Faster analysis and visualization"),
            tags$li(strong("Pattern Recognition:"), " Clearer identification of core system dynamics"),
            tags$li(strong("Scenario Testing:"), " More manageable models for policy simulation")
          ),

          h4("Simplification Best Practices"),
          tags$ol(
            tags$li(strong("Preserve Feedback Loops:"), " Ensure key reinforcing and balancing loops remain intact"),
            tags$li(strong("Maintain Causality:"), " Keep polarity and direction of relationships accurate"),
            tags$li(strong("Document Changes:"), " Track what was removed and why"),
            tags$li(strong("Validate with Experts:"), " Confirm simplified model still represents reality"),
            tags$li(strong("Use Multiple Methods:"), " Combine techniques for comprehensive simplification"),
            tags$li(strong("Iterate:"), " Apply methods gradually and review results at each step")
          ),

          h4("Method Recommendations by Goal"),
          tags$ul(
            tags$li(strong("Focus on Internal Dynamics:"), " Remove exogenous variables"),
            tags$li(strong("Reduce Visual Complexity:"), " Filter weak connections + SISO encapsulation"),
            tags$li(strong("Highlight Key Leverage Points:"), " Low-centrality node removal with PageRank"),
            tags$li(strong("Sector-Specific Analysis:"), " Element type filtering"),
            tags$li(strong("Maximum Simplification:"), " Combine all methods with careful thresholds")
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
            "Reduce network complexity while preserving essential causal structures and feedback loops. ",
            "Apply multiple simplification methods to create focused, interpretable models."
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
        "Original Nodes",
        icon = icon("circle"),
        color = "primary"
      )
    })

    output$original_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$original_edges)) nrow(rv$original_edges) else 0
      bs4ValueBox(
        edge_count,
        "Original Edges",
        icon = icon("arrow-right"),
        color = "primary"
      )
    })

    output$simplified_nodes_box <- renderValueBox({
      node_count <- if (!is.null(rv$simplified_nodes)) nrow(rv$simplified_nodes) else 0
      reduction <- if (!is.null(rv$original_nodes) && !is.null(rv$simplified_nodes)) {
        pct <- round((1 - nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) * 100, 1)
        paste0(" (", pct, "% reduction)")
      } else ""

      bs4ValueBox(
        paste0(node_count, reduction),
        "Simplified Nodes",
        icon = icon("circle"),
        color = if (rv$has_simplified) "success" else "info"
      )
    })

    output$simplified_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$simplified_edges)) nrow(rv$simplified_edges) else 0
      reduction <- if (!is.null(rv$original_edges) && !is.null(rv$simplified_edges)) {
        pct <- round((1 - nrow(rv$simplified_edges) / nrow(rv$original_edges)) * 100, 1)
        paste0(" (", pct, "% reduction)")
      } else ""

      bs4ValueBox(
        paste0(edge_count, reduction),
        "Simplified Edges",
        icon = icon("arrow-right"),
        color = if (rv$has_simplified) "success" else "info"
      )
    })

    # ========== NETWORK SUMMARIES ==========
    output$original_summary <- renderPrint({
      req(rv$original_nodes, rv$original_edges)

      cat("Network Components:\n")
      cat("------------------\n")

      element_counts <- table(rv$original_nodes$group)
      for (elem in names(element_counts)) {
        cat(sprintf("  %s: %d\n", elem, element_counts[elem]))
      }

      cat("\nConnection Strengths:\n")
      cat("--------------------\n")
      strength_counts <- table(rv$original_edges$strength)
      for (strength in names(strength_counts)) {
        cat(sprintf("  %s: %d\n", strength, strength_counts[strength]))
      }

      cat("\nPolarity Distribution:\n")
      cat("---------------------\n")
      polarity_counts <- table(rv$original_edges$polarity)
      for (pol in names(polarity_counts)) {
        pol_name <- ifelse(pol == "+", "Reinforcing", "Opposing")
        cat(sprintf("  %s (%s): %d\n", pol_name, pol, polarity_counts[pol]))
      }
    })

    output$simplified_summary <- renderPrint({
      if (!rv$has_simplified) {
        cat("No simplification applied yet.\n\n")
        cat("Select simplification methods from the left panel\n")
        cat("and click 'Apply Simplification' to begin.")
        return()
      }

      req(rv$simplified_nodes, rv$simplified_edges)

      cat("Network Components:\n")
      cat("------------------\n")

      element_counts <- table(rv$simplified_nodes$group)
      for (elem in names(element_counts)) {
        cat(sprintf("  %s: %d\n", elem, element_counts[elem]))
      }

      cat("\nConnection Strengths:\n")
      cat("--------------------\n")
      strength_counts <- table(rv$simplified_edges$strength)
      for (strength in names(strength_counts)) {
        cat(sprintf("  %s: %d\n", strength, strength_counts[strength]))
      }

      cat("\nPolarity Distribution:\n")
      cat("---------------------\n")
      polarity_counts <- table(rv$simplified_edges$polarity)
      for (pol in names(polarity_counts)) {
        pol_name <- ifelse(pol == "+", "Reinforcing", "Opposing")
        cat(sprintf("  %s (%s): %d\n", pol_name, pol, polarity_counts[pol]))
      }

      cat("\n")
      cat(sprintf("Nodes removed: %d\n", nrow(rv$removed_nodes)))
      cat(sprintf("Edges removed: %d\n", nrow(rv$removed_edges)))
    })

    # ========== APPLY SIMPLIFICATION ==========
    observeEvent(input$apply_simplification, {
      req(rv$original_nodes, rv$original_edges)

      # Start with original network
      nodes <- rv$original_nodes
      edges <- rv$original_edges
      history <- list()

      # Track what was removed
      all_removed_nodes <- data.frame()
      all_removed_edges <- data.frame()

      withProgress(message = 'Applying simplification methods...', value = 0, {

        # Method 1: SISO Encapsulation
        if (input$method_siso) {
          incProgress(0.15, detail = "Encapsulating SISO variables...")

          siso_info <- identify_siso_variables(nodes, edges)

          if (nrow(siso_info) > 0) {
            result <- encapsulate_siso_variables(nodes, edges, siso_info)

            removed_nodes <- nodes %>% filter(id %in% siso_info$id)
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = "SISO Encapsulation"))

            nodes <- result$nodes
            edges <- result$edges

            history <- append(history, list(list(
              method = "SISO Encapsulation",
              removed_nodes = nrow(siso_info),
              description = sprintf("Encapsulated %d SISO variables", nrow(siso_info))
            )))
          } else {
            history <- append(history, list(list(
              method = "SISO Encapsulation",
              removed_nodes = 0,
              description = "No SISO variables found"
            )))
          }
        }

        # Method 2: Remove Exogenous Variables
        if (input$method_exogenous) {
          incProgress(0.15, detail = "Removing exogenous variables...")

          exog_ids <- identify_exogenous_variables(nodes, edges)

          if (length(exog_ids) > 0) {
            removed_nodes <- nodes %>% filter(id %in% exog_ids)
            removed_edges <- edges %>% filter(from %in% exog_ids)

            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = "Exogenous Variable"))
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = "Connected to Exogenous"))

            result <- remove_exogenous_variables(nodes, edges, exog_ids)
            nodes <- result$nodes
            edges <- result$edges

            history <- append(history, list(list(
              method = "Exogenous Removal",
              removed_nodes = length(exog_ids),
              description = sprintf("Removed %d exogenous variables", length(exog_ids))
            )))
          } else {
            history <- append(history, list(list(
              method = "Exogenous Removal",
              removed_nodes = 0,
              description = "No exogenous variables found"
            )))
          }
        }

        # Method 3: Filter Weak Connections
        if (input$method_weak_edges) {
          incProgress(0.15, detail = "Filtering weak connections...")

          if (input$weak_edge_threshold == "medium") {
            removed_edges <- edges %>% filter(strength == "weak")
            edges_filtered <- edges %>% filter(strength != "weak")
          } else { # strong only
            removed_edges <- edges %>% filter(strength != "strong")
            edges_filtered <- edges %>% filter(strength == "strong")
          }

          all_removed_edges <- bind_rows(all_removed_edges,
                                        removed_edges %>% mutate(reason = "Weak Connection"))

          # Remove orphaned nodes
          connected_nodes <- unique(c(edges_filtered$from, edges_filtered$to))
          orphaned_nodes <- nodes %>% filter(!id %in% connected_nodes)

          if (nrow(orphaned_nodes) > 0) {
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          orphaned_nodes %>% mutate(reason = "Orphaned after edge filtering"))
          }

          nodes <- nodes %>% filter(id %in% connected_nodes)
          edges <- edges_filtered

          history <- append(history, list(list(
            method = "Weak Edge Filtering",
            removed_edges = nrow(removed_edges),
            removed_nodes = nrow(orphaned_nodes),
            description = sprintf("Removed %d weak edges, %d orphaned nodes",
                                nrow(removed_edges), nrow(orphaned_nodes))
          )))
        }

        # Method 4: Remove Low Centrality Nodes
        if (input$method_low_centrality) {
          incProgress(0.15, detail = "Calculating centrality metrics...")

          metrics <- calculate_network_metrics(nodes, edges)
          metric_values <- metrics[[input$centrality_metric]]

          threshold_value <- quantile(metric_values, probs = input$centrality_percentile / 100)

          below_threshold <- names(metric_values)[metric_values < threshold_value]

          if (length(below_threshold) > 0) {
            removed_nodes <- nodes %>% filter(id %in% below_threshold)
            removed_edges <- edges %>% filter(from %in% below_threshold | to %in% below_threshold)

            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(
                                            reason = sprintf("Low %s centrality", input$centrality_metric)))
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = "Connected to low-centrality node"))

            nodes <- nodes %>% filter(!id %in% below_threshold)
            edges <- edges %>% filter(!from %in% below_threshold, !to %in% below_threshold)

            history <- append(history, list(list(
              method = "Low Centrality Removal",
              metric = input$centrality_metric,
              percentile = input$centrality_percentile,
              removed_nodes = length(below_threshold),
              description = sprintf("Removed %d nodes below %d%% %s centrality",
                                  length(below_threshold), input$centrality_percentile,
                                  input$centrality_metric)
            )))
          }
        }

        # Method 5: Element Type Filtering
        if (input$method_element_filter) {
          incProgress(0.15, detail = "Filtering by element type...")

          removed_nodes <- nodes %>% filter(!group %in% input$elements_to_keep)

          if (nrow(removed_nodes) > 0) {
            all_removed_nodes <- bind_rows(all_removed_nodes,
                                          removed_nodes %>% mutate(reason = "Element type excluded"))

            removed_edges <- edges %>% filter(from %in% removed_nodes$id | to %in% removed_nodes$id)
            all_removed_edges <- bind_rows(all_removed_edges,
                                          removed_edges %>% mutate(reason = "Connected to excluded element"))

            nodes <- nodes %>% filter(group %in% input$elements_to_keep)
            edges <- edges %>% filter(!from %in% removed_nodes$id, !to %in% removed_nodes$id)

            history <- append(history, list(list(
              method = "Element Type Filtering",
              removed_nodes = nrow(removed_nodes),
              description = sprintf("Kept only: %s", paste(input$elements_to_keep, collapse = ", "))
            )))
          }
        }

        incProgress(0.25, detail = "Finalizing simplification...")

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
        "Network reset to original state",
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

    output$original_network <- renderVisNetwork({
      req(rv$original_nodes, rv$original_edges)

      visNetwork(rv$original_nodes, rv$original_edges, height = "500px") %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(stabilization = TRUE, barnesHut = list(gravitationalConstant = -2000, springLength = 200)) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE)
    })

    output$simplified_network <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)

      visNetwork(rv$simplified_nodes, rv$simplified_edges, height = "500px") %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(stabilization = TRUE, barnesHut = list(gravitationalConstant = -2000, springLength = 200)) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE)
    })

    output$simplified_network_full <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)

      visNetwork(rv$simplified_nodes, rv$simplified_edges, height = "600px") %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(stabilization = TRUE, barnesHut = list(gravitationalConstant = -2000, springLength = 200)) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE, zoomView = TRUE)
    })

    # ========== STATISTICS AND TABLES ==========

    output$simplification_stats <- renderTable({
      req(rv$original_nodes, rv$original_edges, rv$simplified_nodes, rv$simplified_edges)

      data.frame(
        Metric = c("Total Nodes", "Total Edges", "Avg. Degree", "Network Density"),
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
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    output$removed_nodes_table <- renderTable({
      if (!rv$has_simplified || is.null(rv$removed_nodes) || nrow(rv$removed_nodes) == 0) {
        return(data.frame(Message = "No nodes removed"))
      }

      rv$removed_nodes %>%
        select(ID = id, Label = label, Type = group, Reason = reason) %>%
        head(50)
    }, striped = TRUE, hover = TRUE)

    output$removed_edges_table <- renderTable({
      if (!rv$has_simplified || is.null(rv$removed_edges) || nrow(rv$removed_edges) == 0) {
        return(data.frame(Message = "No edges removed"))
      }

      rv$removed_edges %>%
        select(From = from, To = to, Polarity = polarity, Strength = strength, Reason = reason) %>%
        head(50)
    }, striped = TRUE, hover = TRUE)

    # ========== SIMPLIFICATION LOG ==========
    output$simplification_log <- renderPrint({
      if (!rv$has_simplified || length(rv$simplification_history) == 0) {
        cat("No simplification methods applied yet.\n")
        return()
      }

      cat("SIMPLIFICATION HISTORY\n")
      cat("======================\n\n")

      for (i in seq_along(rv$simplification_history)) {
        item <- rv$simplification_history[[i]]
        cat(sprintf("Step %d: %s\n", i, item$method))
        cat(sprintf("  %s\n", item$description))
        if (!is.null(item$removed_nodes) && item$removed_nodes > 0) {
          cat(sprintf("  -> Nodes removed: %d\n", item$removed_nodes))
        }
        if (!is.null(item$removed_edges) && item$removed_edges > 0) {
          cat(sprintf("  -> Edges removed: %d\n", item$removed_edges))
        }
        cat("\n")
      }

      cat("TOTAL IMPACT\n")
      cat("------------\n")
      cat(sprintf("Total nodes removed: %d (%.1f%%)\n",
                  nrow(rv$removed_nodes),
                  (nrow(rv$removed_nodes) / nrow(rv$original_nodes)) * 100))
      cat(sprintf("Total edges removed: %d (%.1f%%)\n",
                  nrow(rv$removed_edges),
                  (nrow(rv$removed_edges) / nrow(rv$original_edges)) * 100))
    })

    # ========== IMPACT CHART ==========
    output$impact_chart <- renderPlot({
      if (!rv$has_simplified) {
        plot.new()
        text(0.5, 0.5, "Apply simplification to see impact chart", cex = 1.5)
        return()
      }

      req(rv$original_nodes, rv$simplified_nodes, rv$original_edges, rv$simplified_edges)

      comparison_data <- data.frame(
        Category = rep(c("Nodes", "Edges"), each = 2),
        State = rep(c("Original", "Simplified"), 2),
        Count = c(
          nrow(rv$original_nodes),
          nrow(rv$simplified_nodes),
          nrow(rv$original_edges),
          nrow(rv$simplified_edges)
        )
      )

      ggplot(comparison_data, aes(x = Category, y = Count, fill = State)) +
        geom_bar(stat = "identity", position = "dodge", width = 0.7) +
        geom_text(aes(label = Count), position = position_dodge(0.7), vjust = -0.5, size = 5) +
        scale_fill_manual(values = c("Original" = "#3498db", "Simplified" = "#27ae60")) +
        labs(
          title = "Simplification Impact: Before and After",
          subtitle = sprintf("%.1f%% node reduction, %.1f%% edge reduction",
                           (1 - nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) * 100,
                           (1 - nrow(rv$simplified_edges) / nrow(rv$original_edges)) * 100),
          x = "",
          y = "Count",
          fill = "Network State"
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
          "Simplified network exported successfully!",
          type = "message",
          duration = 3
        )
      }
    )

  })
}
