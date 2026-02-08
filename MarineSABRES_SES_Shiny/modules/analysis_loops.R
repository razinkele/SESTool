# Loop Detection Analysis Module
# Extracted from analysis_tools_module.R
# Detects and analyzes feedback loops in the CLD
# Note: igraph is loaded in global.R

#' Loop Detection Analysis Module UI
#'
#' Creates the user interface for feedback loop detection and analysis in the CLD.
#' Displays detected loops with their types (reinforcing/balancing) and allows
#' filtering and visualization.
#'
#' @param id Character string. Module namespace ID.
#'
#' @return A Shiny UI element for loop detection interface.
#'
#' @details
#' Features:
#' \itemize{
#'   \item Detect all feedback loops in the CLD
#'   \item Classify loops as reinforcing or balancing
#'   \item Display loop details with node sequences
#'   \item Filter loops by type and length
#'   \item Visualize selected loops in the network
#' }
#'
#' @export
analysis_loops_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    uiOutput(ns("module_header")),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("loop_tabs"),

          # Tab 1: Loop Detection ----
          tabPanel(i18n$t("modules.analysis.loops.tab_detect"),
            h4(i18n$t("modules.analysis.loops.automatic_detection")),
            p("Identify all feedback loops in your DAPSI(W)R(M) system."),

            wellPanel(
              fluidRow(
                column(4,
                  h5(i18n$t("modules.analysis.loops.detection_parameters")),
                  numericInput(ns("max_loop_length"), "Maximum Loop Length:",
                              value = 8, min = 3, max = 10,
                              step = 1),
                  numericInput(ns("max_cycles"), "Maximum Cycles to Find:",
                              value = 500, min = 50, max = 500,
                              step = 50),
                  checkboxInput(ns("include_self_loops"), "Include Self-Loops", value = FALSE),
                  checkboxInput(ns("filter_trivial"), "Filter Trivial Loops", value = TRUE),
                  tags$small(class = "text-muted",
                    "Note: Lower values prevent hanging on complex networks"),
                  br(), br(),
                  actionButton(ns("detect_loops"), i18n$t("modules.analysis.loops.btn_detect"),
                              icon = icon("search"),
                              class = "btn-primary btn-lg btn-block")
                ),
                column(8,
                  h5(i18n$t("modules.analysis.loops.detection_summary")),
                  verbatimTextOutput(ns("detection_summary")),
                  hr(),
                  h5("Processing Status"),
                  textOutput(ns("detection_status"))
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("modules.analysis.loops.detected_loops")),
                DTOutput(ns("loops_table"))
              )
            )
          ),

          # Tab 2: Loop Classification ----
          tabPanel(i18n$t("modules.analysis.loops.tab_classification"),
            h4(i18n$t("modules.analysis.loops.reinforcing_vs_balancing")),
            p("Classify loops based on polarity and understand their system behavior."),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("modules.analysis.loops.reinforcing_loops")),
                  p("Amplify change - can create virtuous or vicious cycles."),
                  DTOutput(ns("reinforcing_loops_table")),
                  hr(),
                  plotOutput(ns("reinforcing_dist"), height = PLOT_HEIGHT_XS)
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("modules.analysis.loops.balancing_loops")),
                  p("Counteract change - seek equilibrium or stability."),
                  DTOutput(ns("balancing_loops_table")),
                  hr(),
                  plotOutput(ns("balancing_dist"), height = PLOT_HEIGHT_XS)
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Loop Type Distribution"),
                  plotOutput(ns("loop_type_plot"), height = PLOT_HEIGHT_SM)
                )
              )
            )
          ),

          # Tab 3: Loop Details ----
          tabPanel(i18n$t("modules.analysis.loops.tab_details"),
            h4(i18n$t("modules.analysis.loops.detailed_loop_info")),

            fluidRow(
              column(4,
                wellPanel(
                  h5("Select Loop"),
                  selectInput(ns("selected_loop"), "Loop ID:",
                             choices = NULL),
                  hr(),
                  h5("Loop Properties"),
                  verbatimTextOutput(ns("loop_properties"))
                )
              ),
              column(8,
                wellPanel(
                  h5("Loop Visualization"),
                  visNetworkOutput(ns("loop_network"), height = PLOT_HEIGHT_MD)
                ),
                wellPanel(
                  h5("Loop Narrative"),
                  htmlOutput(ns("loop_narrative"))
                )
              )
            )
          ),

          # Tab 4: Dominant Loops ----
          tabPanel(i18n$t("modules.analysis.loops.tab_dominant"),
            h4(i18n$t("modules.analysis.loops.identify_key_drivers")),
            p("Analyze which loops have the most influence on system behavior."),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Dominance Metrics"),
                  p("Loops are ranked by length, centrality, and element importance."),
                  DTOutput(ns("dominant_loops_table"))
                )
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Loop Strength Analysis"),
                  plotOutput(ns("loop_strength_plot"), height = PLOT_HEIGHT_SM)
                )
              ),
              column(6,
                wellPanel(
                  h5("Element Participation"),
                  p("How many loops each element appears in:"),
                  plotOutput(ns("element_participation_plot"), height = PLOT_HEIGHT_SM)
                )
              )
            )
          ),

          # Tab 5: Export ----
          tabPanel(i18n$t("modules.analysis.loops.tab_export"),
            h4(i18n$t("modules.analysis.loops.export_analysis")),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Download Options"),
                  p("Export loop detection results for documentation and reporting."),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_loops_excel"),
                                    "Download Loops (Excel)",
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_loop_report"),
                                    "Download Loop Report (PDF)",
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_loop_viz"),
                                    "Download Loop Diagrams (ZIP)",
                                    class = "btn-warning btn-block")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Loop Summary Statistics"),
                  verbatimTextOutput(ns("export_summary"))
                )
              )
            )
          )
        )
      )
    )
  )
}

#' Loop Detection Analysis Module Server
#'
#' Server logic for detecting and analyzing feedback loops in the Causal Loop Diagram.
#' Implements loop detection algorithms, classification, and visualization.
#'
#' @param id Character string. Module namespace ID (must match UI function).
#' @param project_data_reactive Reactive expression returning project data with CLD nodes/edges.
#'
#' @return Server module (no return value, side effects only).
#'
#' @details
#' Implements:
#' \itemize{
#'   \item Feedback loop detection using igraph cycle finding
#'   \item Loop classification (reinforcing vs balancing based on edge polarity)
#'   \item Interactive loop table with details
#'   \item Loop visualization in network
#'   \item Export functionality for loop data
#' }
#'
#' @export
analysis_loops_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for loop data
    loop_data <- reactiveValues(
      loops = NULL,
      graph = NULL,
      adjacency = NULL,
      detection_complete = FALSE
    )

    # === REACTIVE MODULE HEADER ===
    create_reactive_header(
      output = output,
      ns = session$ns,
      title_key = "modules.analysis.loops.title",
      subtitle_key = "modules.analysis.loops.subtitle",
      help_id = "help_loops",
      i18n = i18n
    )

    # ============================================================================
    # CACHED REACTIVE: Graph Construction
    # ============================================================================
    build_graph_from_isa <- reactive({
      start_time <- Sys.time()

      req(project_data_reactive())

      isa_data <- project_data_reactive()$data$isa_data

      if(is.null(isa_data)) return(NULL)

      # Use the existing helper functions to build nodes and edges
      nodes <- create_nodes_df(isa_data)
      edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

      if(is.null(nodes) || nrow(nodes) == 0 || is.null(edges) || nrow(edges) == 0) {
        return(NULL)
      }

      # Create igraph object with both nodes and edges
      g <- graph_from_data_frame(
        d = edges %>% select(from, to, polarity),
        directed = TRUE,
        vertices = nodes %>% select(id, label, group)
      )

      # Add edge attributes
      E(g)$polarity <- edges$polarity

      # Log cache performance
      elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
      if (elapsed < 0.01) {
        debug_log("Graph retrieved from cache (< 10ms)", "CACHE HIT")
      } else {
        debug_log(sprintf("Graph constructed in %.3f seconds (%d nodes, %d edges)",
                         elapsed, vcount(g), ecount(g)), "CACHE MISS")
      }

      return(list(graph = g, edges = edges, nodes = nodes))
    }) %>% bindCache(
      digest::digest(
        project_data_reactive()$data$isa_data,
        algo = "xxhash64"
      ),
      cache = "session"
    )

    # Detect Loops ----
    observeEvent(input$detect_loops, {

      debug_log("Loop detection button clicked", "LOOP DETECTION")

      output$detection_status <- renderText(i18n$t("modules.analysis.loops.analysis_detecting_loops"))

      graph_data <- build_graph_from_isa()

      if(is.null(graph_data)) {
        output$detection_status <- renderText(i18n$t("modules.analysis.common.analysis_no_graph_data"))
        showNotification(i18n$t("modules.analysis.common.analysis_no_isa_data"), type = "error")
        return()
      }

      g <- graph_data$graph
      nodes <- graph_data$nodes
      edges <- graph_data$edges

      # Log basic graph info for monitoring
      debug_log(sprintf("Graph: %d nodes, %d edges, density %.4f",
                       vcount(g), ecount(g), edge_density(g)), "LOOP DETECTION")

      # Analyze SCC structure
      scc <- components(g, mode = "strong")
      comp_sizes <- table(scc$membership)
      max_comp_size <- max(comp_sizes)

      debug_log(sprintf("SCC: %d components, largest: %d nodes",
                       length(unique(scc$membership)), max_comp_size), "LOOP DETECTION")

      # Check for reasonable graph size to prevent hanging
      if(vcount(g) > 100 || ecount(g) > 500) {
        showNotification(
          paste0(i18n$t("modules.analysis.network.large_network_detected"), " ", vcount(g), " ", i18n$t("modules.analysis.common.nodes"), ", ", ecount(g), " ", i18n$t("modules.analysis.common.edges"), ". ",
                 i18n$t("modules.analysis.loop_detection_may_take_longer_consider_reducing_m")),
          type = "warning",
          duration = 8
        )
      }

      if(vcount(g) > 300 || ecount(g) > 1500) {
        output$detection_status <- renderText(i18n$t("modules.analysis.graph_too_large_for_reliable_loop_detection_please"))
        showNotification(
          i18n$t("common.messages.error_network_too_large_300_nodes_or_1500_edges_lo"),
          type = "error",
          duration = 15
        )
        return()
      }

      # Use optimized loop detection algorithm from network_analysis.R
      withProgress(message = 'Detecting loops (this may take 10-30 seconds)...', value = 0, {

        incProgress(0.1, detail = "Preparing detection parameters...")
        Sys.sleep(0.1)

        tryCatch({
          # Get max_cycles from user input, with sensible default
          max_cycles_limit <- if(!is.null(input$max_cycles) && input$max_cycles > 0) {
            input$max_cycles
          } else {
            500
          }

          # Limit max_loop_length to prevent hanging
          safe_max_length <- min(input$max_loop_length, 10)

          incProgress(0.1, detail = "Analyzing components...")
          Sys.sleep(0.1)

          incProgress(0.1, detail = "Finding cycles (please wait)...")
          Sys.sleep(0.1)

          # Run with timeout to prevent hanging
          all_loops <- NULL
          error_occurred <- FALSE

          tryCatch({
            # Set a reasonable timeout (30 seconds)
            setTimeLimit(cpu = LOOP_ANALYSIS_TIMEOUT_SECONDS, elapsed = LOOP_ANALYSIS_TIMEOUT_SECONDS, transient = TRUE)

            all_loops <- find_all_cycles(
              nodes, edges,
              max_length = safe_max_length,
              max_cycles = max_cycles_limit
            )

            # Reset time limit
            setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

          }, error = function(e) {
            # Reset time limit
            setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

            if (grepl("time limit", e$message, ignore.case = TRUE)) {
              showNotification(
                i18n$t("modules.analysis.loop_detection_timed_out_after_30_seconds_try_redu"),
                type = "error",
                duration = 10
              )
            } else {
              showNotification(
                paste(i18n$t("modules.analysis.loops.error_during_loop_detection"), e$message),
                type = "error",
                duration = 10
              )
            }
            error_occurred <<- TRUE
          })

          if (error_occurred || is.null(all_loops)) {
            output$detection_status <- renderText(i18n$t("modules.analysis.loops.loop_detection_failed_or_timed_out"))
            return()
          }

          incProgress(0.1, detail = "Processing detected loops...")
          Sys.sleep(0.1)

          if(length(all_loops) == 0) {
            output$detection_status <- renderText(i18n$t("modules.analysis.loops.analysis_no_loops_detected"))
            showNotification(i18n$t("modules.analysis.loops.analysis_no_loops_found"), type = "warning")
            return()
          }

          # Limit loops for display
          max_loops_display <- 500
          original_count <- length(all_loops)

          if(length(all_loops) > max_loops_display) {
            showNotification(
              paste0(i18n$t("modules.analysis.common.found"), " ", length(all_loops), " ", i18n$t("modules.analysis.loops.loops_displaying_first"), " ", max_loops_display, " ", i18n$t("modules.analysis.loops.loops")),
              type = "warning",
              duration = 10
            )
            all_loops <- all_loops[1:max_loops_display]
          }

          incProgress(0.1, detail = "Processing loop details...")
          Sys.sleep(0.1)

          loop_info <- process_cycles_to_loops(all_loops, nodes, edges, g)

          incProgress(0.2, detail = "Finalizing results...")
          Sys.sleep(0.1)

          loop_data$loops <- loop_info
          loop_data$graph <- g
          loop_data$all_loops <- all_loops
          loop_data$detection_complete <- TRUE

          # Save loop results to project_data for CLD visualization
          project_data <- project_data_reactive()
          if(is.null(project_data$data$analysis)) {
            project_data$data$analysis <- list()
          }
          project_data$data$analysis$loops <- list(
            loop_info = loop_info,
            all_loops = all_loops
          )
          project_data$last_modified <- Sys.time()
          project_data_reactive(project_data)

          output$detection_status <- renderText(
            paste("Detection complete! Found", nrow(loop_info), "loops.")
          )

          showNotification(
            paste(i18n$t("modules.analysis.common.detection_complete_found"), nrow(loop_info), i18n$t("modules.analysis.loops.feedback_loops")),
            type = "message"
          )

          debug_log(sprintf("Loop detection completed: %d loops found", nrow(loop_info)), "LOOP DETECTION")

        }, error = function(e) {
          output$detection_status <- renderText(paste(i18n$t("modules.analysis.loops.error_during_loop_detection"), conditionMessage(e)))
          showNotification(
            paste(i18n$t("modules.analysis.loops.loop_detection_failed"), conditionMessage(e)),
            type = "error",
            duration = 10
          )
          debug_log(paste("Loop detection error:", conditionMessage(e)), "LOOP DETECTION")
        })
      })
    })

    # Detection Summary ----
    output$detection_summary <- renderText({
      if(!loop_data$detection_complete) {
        return("Click 'Detect Loops' to begin analysis.")
      }

      req(loop_data$loops)

      loops <- loop_data$loops
      reinforcing <- sum(loops$Type == "Reinforcing")
      balancing <- sum(loops$Type == "Balancing")

      paste0(
        "Total Loops Found: ", nrow(loops), "\n",
        "Reinforcing Loops: ", reinforcing, "\n",
        "Balancing Loops: ", balancing, "\n",
        "Average Loop Length: ", round(mean(loops$Length), 1), "\n",
        "Shortest Loop: ", min(loops$Length), " elements\n",
        "Longest Loop: ", max(loops$Length), " elements"
      )
    })

    # Loops Table ----
    output$loops_table <- renderDT({
      req(loop_data$loops)
      datatable(loop_data$loops,
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Reinforcing Loops Table ----
    output$reinforcing_loops_table <- renderDT({
      req(loop_data$loops)
      r_loops <- loop_data$loops[loop_data$loops$Type == "Reinforcing", ]
      datatable(r_loops,
               options = list(pageLength = 5, scrollX = TRUE),
               rownames = FALSE)
    })

    # Balancing Loops Table ----
    output$balancing_loops_table <- renderDT({
      req(loop_data$loops)
      b_loops <- loop_data$loops[loop_data$loops$Type == "Balancing", ]
      datatable(b_loops,
               options = list(pageLength = 5, scrollX = TRUE),
               rownames = FALSE)
    })

    # Loop Type Plot ----
    output$loop_type_plot <- renderPlot({
      req(loop_data$loops)

      type_counts <- table(loop_data$loops$Type)

      barplot(type_counts,
              main = "Loop Type Distribution",
              col = c("Balancing" = "#E63946", "Reinforcing" = "#06D6A0"),
              ylab = "Number of Loops",
              las = 1)

      legend("topright",
             legend = c("Reinforcing (amplify change)", "Balancing (seek equilibrium)"),
             fill = c("#06D6A0", "#E63946"))
    })

    # Update loop selection dropdown ----
    observe({
      req(loop_data$loops)
      if(nrow(loop_data$loops) > 0) {
        choices <- setNames(loop_data$loops$LoopID,
                           paste0(loop_data$loops$LoopID, ": ", loop_data$loops$Type))
        updateSelectInput(session, "selected_loop", choices = choices)
      } else {
        updateSelectInput(session, "selected_loop", choices = c("No loops detected"))
      }
    })

    # Loop Properties ----
    output$loop_properties <- renderText({
      req(input$selected_loop, loop_data$loops)

      loop_row <- loop_data$loops[loop_data$loops$LoopID == input$selected_loop, ]

      paste0(
        "Loop ID: ", loop_row$LoopID, "\n",
        "Type: ", loop_row$Type, "\n",
        "Polarity: ", loop_row$Polarity, "\n",
        "Length: ", loop_row$Length, " elements\n",
        "\nPath:\n", loop_row$Elements
      )
    })

    # Loop Network Visualization ----
    output$loop_network <- renderVisNetwork({
      req(input$selected_loop, loop_data$all_loops, loop_data$graph)

      # Get loop index
      loop_idx <- as.integer(gsub("L", "", input$selected_loop))
      loop <- loop_data$all_loops[[loop_idx]]

      # Get vertex IDs and labels from igraph vertex indices
      loop_vertex_ids <- V(loop_data$graph)$name[loop]
      loop_vertex_labels <- V(loop_data$graph)$label[loop]

      # Ensure unique nodes
      unique_indices <- !duplicated(loop_vertex_ids)
      unique_ids <- loop_vertex_ids[unique_indices]
      unique_labels <- loop_vertex_labels[unique_indices]

      # Prepare nodes with proper descriptive labels
      nodes_df <- data.frame(
        id = unique_ids,
        label = unique_labels,
        color = "#2B7CE9",
        shape = "dot",
        size = 20,
        stringsAsFactors = FALSE
      )

      # Prepare edges (including closing the loop)
      edges_list <- list()
      loop_length <- length(loop_vertex_ids)

      for(i in 1:loop_length) {
        from_node_idx <- loop[i]
        # Close the loop: last node connects back to first
        to_node_idx <- if(i == loop_length) loop[1] else loop[i+1]

        from_name <- V(loop_data$graph)$name[from_node_idx]
        to_name <- V(loop_data$graph)$name[to_node_idx]

        # Get edge polarity
        edge_id <- tryCatch({
          get_edge_ids(loop_data$graph, c(from_node_idx, to_node_idx))
        }, error = function(e) 0)

        polarity <- if(edge_id > 0) E(loop_data$graph)$polarity[edge_id] else "+"

        edges_list[[i]] <- data.frame(
          from = from_name,
          to = to_name,
          arrows = "to",
          color = ifelse(polarity == "+", "#06D6A0", "#E63946"),
          label = polarity,
          width = 5,
          stringsAsFactors = FALSE
        )
      }

      edges_df <- do.call(rbind, edges_list)

      visNetwork(nodes_df, edges_df) %>%
        visEdges(smooth = list(enabled = TRUE, type = "curvedCW")) %>%
        visOptions(highlightNearest = TRUE) %>%
        visLayout(randomSeed = 123)
    })

    # Loop Narrative ----
    output$loop_narrative <- renderUI({
      req(input$selected_loop, loop_data$loops)

      loop_row <- loop_data$loops[loop_data$loops$LoopID == input$selected_loop, ]

      narrative <- if(loop_row$Type == "Reinforcing") {
        paste0(
          "<p><strong>Reinforcing Loop</strong> - This loop amplifies change in the system.</p>",
          "<p>When one element increases, it causes downstream elements to increase (or decrease through negative links), ",
          "which eventually feeds back to increase the original element even more. This creates exponential growth or decline.</p>",
          "<p><strong>System Behavior:</strong> Can create 'virtuous cycles' (positive growth) or 'vicious cycles' (degradation spirals).</p>",
          "<p><strong>Management Implication:</strong> Intervention points in reinforcing loops can have large leverage effects.</p>"
        )
      } else {
        paste0(
          "<p><strong>Balancing Loop</strong> - This loop counteracts change in the system.</p>",
          "<p>When one element increases, the feedback loop causes forces that push it back down toward equilibrium. ",
          "This creates self-regulation and stability-seeking behavior.</p>",
          "<p><strong>System Behavior:</strong> Maintains stability, resists change, seeks goal or equilibrium state.</p>",
          "<p><strong>Management Implication:</strong> Balancing loops can resist policy interventions and maintain status quo.</p>"
        )
      }

      HTML(narrative)
    })

    # Dominant Loops Analysis ----
    output$dominant_loops_table <- renderDT({
      req(loop_data$loops)

      # Calculate dominance score (simple version)
      loops <- loop_data$loops
      loops$DominanceScore <- 100 / loops$Length
      loops <- loops[order(-loops$DominanceScore), ]
      loops$Rank <- 1:nrow(loops)

      datatable(loops[, c("Rank", "LoopID", "Type", "Length", "DominanceScore", "Elements")],
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Element Participation Plot ----
    output$element_participation_plot <- renderPlot({
      req(loop_data$all_loops)

      # Count how many loops each element appears in
      element_counts <- table(unlist(lapply(loop_data$all_loops, names)))
      element_counts <- sort(element_counts, decreasing = TRUE)

      if(length(element_counts) > 15) {
        element_counts <- element_counts[1:15]
      }

      barplot(element_counts,
              main = "Elements in Most Loops (Top 15)",
              ylab = "Number of Loops",
              las = 2,
              col = "#457B9D",
              cex.names = 0.7)
    })

    # Export Summary ----
    output$export_summary <- renderText({
      req(loop_data$loops)

      loops <- loop_data$loops

      paste0(
        "Export Summary\n",
        "====================\n\n",
        "Total Loops: ", nrow(loops), "\n",
        "Reinforcing: ", sum(loops$Type == "Reinforcing"), "\n",
        "Balancing: ", sum(loops$Type == "Balancing"), "\n\n",
        "Ready for export in multiple formats."
      )
    })

    # Download Handlers ----
    output$download_loops_excel <- downloadHandler(
      filename = function() {
        generate_export_filename("Loop_Analysis", ".xlsx")
      },
      content = function(file) {
        req(loop_data$loops)

        wb <- createWorkbook()
        addWorksheet(wb, "All_Loops")
        addWorksheet(wb, "Reinforcing_Loops")
        addWorksheet(wb, "Balancing_Loops")

        writeData(wb, "All_Loops", loop_data$loops)
        writeData(wb, "Reinforcing_Loops",
                 loop_data$loops[loop_data$loops$Type == "Reinforcing", ])
        writeData(wb, "Balancing_Loops",
                 loop_data$loops[loop_data$loops$Type == "Balancing", ])

        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    # Help Modal ----
    create_help_observer(
      input = input,
      input_id = "help_loops",
      title_key = "Feedback Loop Detection and Analysis Guide",
      content = tagList(
        h4(i18n$t("modules.analysis.loops.what_are_feedback_loops")),
        p(i18n$t("modules.analysis.feedback_loops_are_circular_patterns_in_the_system")),
        hr(),
        h5(i18n$t("modules.analysis.loops.loop_types")),
        tags$ul(
          tags$li(strong(i18n$t("modules.analysis.loops.reinforcing_loops_r")), i18n$t("modules.analysis.common.amplify_change_in_the_system")),
          tags$ul(
            tags$li(i18n$t("modules.analysis.common.rule_even_number_of_negative_connections")),
            tags$li(i18n$t("modules.analysis.behavior_can_create_virtuous_cycles_exponential_gr")),
            tags$li(i18n$t("modules.analysis.example_species_population_reproduction_rate_speci"))
          ),
          tags$li(strong(i18n$t("modules.analysis.loops.balancing_loops_b")), i18n$t("modules.analysis.common.counteract_change_and_seek_equilibrium")),
          tags$ul(
            tags$li(i18n$t("modules.analysis.common.rule_odd_number_of_negative_connections")),
            tags$li(i18n$t("modules.analysis.behavior_produces_resistance_to_change_and_system_")),
            tags$li(i18n$t("modules.analysis.common.example_fishing_fish_biomass_fishing"))
          )
        ),
        hr(),
        h5(i18n$t("modules.analysis.common.how_to_use_this_tool")),
        tags$ol(
          tags$li(strong(i18n$t("modules.analysis.loops.1_detect_loops")), i18n$t("modules.analysis.set_detection_parameters_maximum_length_number_of_")),
          tags$li(strong(i18n$t("modules.analysis.common.2_classification")), i18n$t("modules.analysis.loops.review_reinforcing_and_balancing_loops_found")),
          tags$li(strong(i18n$t("common.labels.3_details")), i18n$t("modules.analysis.loops.examine_individual_loops_and_see_their_complete_path")),
          tags$li(strong(i18n$t("modules.analysis.common.4_visualization")), i18n$t("modules.analysis.loops.see_highlighted_loops_in_the_context_of_your_full_network")),
          tags$li(strong(i18n$t("modules.analysis.common.5_element_participation")), i18n$t("modules.analysis.loops.identify_which_system_elements_participate_in_most_loops")),
          tags$li(strong(i18n$t("modules.analysis.common.6_export")), i18n$t("modules.analysis.save_res_in_excel_or_csv_formats_for_further_anlys"))
        ),
        hr(),
        h5(i18n$t("modules.analysis.common.understanding_the_results")),
        tags$ul(
          tags$li(strong(i18n$t("modules.analysis.loops.loop_length")), i18n$t("modules.analysis.number_of_elements_in_the_loop_shorter_loops_3_5_e")),
          tags$li(strong(i18n$t("modules.analysis.common.dominance_score")), i18n$t("modules.analysis.measures_how_significant_the_loop_is_based_on_the_")),
          tags$li(strong(i18n$t("modules.analysis.common.element_participation")), i18n$t("modules.analysis.elements_appearing_in_multiple_loops_are_potential"))
        ),
        hr(),
        p(em(i18n$t("modules.analysis.understanding_feedback_loops_reinforcing_loops_oft")))
      ),
      i18n = i18n
    )

    return(reactive({ loop_data }))
  })
}
