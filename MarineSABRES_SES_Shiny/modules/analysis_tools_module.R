# Analysis Tools Module
# Advanced analysis features for CLD and SES analysis
# Includes: Loop Detection, Network Metrics, BOT Analysis, Simplification
# Note: igraph is loaded in global.R

# ============================================================================
# LOOP DETECTION MODULE
# ============================================================================

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
analysis_loops_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    create_module_header(
      ns = ns,
      title_key = "Feedback Loop Detection and Analysis",
      subtitle_key = "Automatically identify and analyze feedback loops in your Causal Loop Diagram.",
      help_id = "help_loops",
      i18n = i18n
    ),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("loop_tabs"),

          # Tab 1: Loop Detection ----
          tabPanel("Detect Loops",
            h4("Automatic Loop Detection"),
            p("Identify all feedback loops in your DAPSI(W)R(M) system."),

            wellPanel(
              fluidRow(
                column(4,
                  h5("Detection Parameters"),
                  numericInput(ns("max_loop_length"), "Maximum Loop Length:",
                              value = 8, min = 3, max = 15,
                              step = 1),
                  numericInput(ns("max_cycles"), "Maximum Cycles to Find:",
                              value = 500, min = 50, max = 2000,
                              step = 50),
                  checkboxInput(ns("include_self_loops"), "Include Self-Loops", value = FALSE),
                  checkboxInput(ns("filter_trivial"), "Filter Trivial Loops", value = TRUE),
                  tags$small(class = "text-muted",
                    "Note: Lower values prevent hanging on complex networks"),
                  br(), br(),
                  actionButton(ns("detect_loops"), "Detect Loops",
                              icon = icon("search"),
                              class = "btn-primary btn-lg btn-block")
                ),
                column(8,
                  h5("Detection Summary"),
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
                h5("Detected Loops"),
                DTOutput(ns("loops_table"))
              )
            )
          ),

          # Tab 2: Loop Classification ----
          tabPanel("Loop Classification",
            h4("Reinforcing vs. Balancing Loops"),
            p("Classify loops based on polarity and understand their system behavior."),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Reinforcing Loops (R)"),
                  p("Amplify change - can create virtuous or vicious cycles."),
                  DTOutput(ns("reinforcing_loops_table")),
                  hr(),
                  plotOutput(ns("reinforcing_dist"), height = "200px")
                )
              ),
              column(6,
                wellPanel(
                  h5("Balancing Loops (B)"),
                  p("Counteract change - seek equilibrium or stability."),
                  DTOutput(ns("balancing_loops_table")),
                  hr(),
                  plotOutput(ns("balancing_dist"), height = "200px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Loop Type Distribution"),
                  plotOutput(ns("loop_type_plot"), height = "300px")
                )
              )
            )
          ),

          # Tab 3: Loop Details ----
          tabPanel("Loop Details",
            h4("Detailed Loop Information"),

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
                  visNetworkOutput(ns("loop_network"), height = "400px")
                ),
                wellPanel(
                  h5("Loop Narrative"),
                  htmlOutput(ns("loop_narrative"))
                )
              )
            )
          ),

          # Tab 4: Dominant Loops ----
          tabPanel("Dominant Loops",
            h4("Identify Key System Drivers"),
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
                  plotOutput(ns("loop_strength_plot"), height = "300px")
                )
              ),
              column(6,
                wellPanel(
                  h5("Element Participation"),
                  p("How many loops each element appears in:"),
                  plotOutput(ns("element_participation_plot"), height = "300px")
                )
              )
            )
          ),

          # Tab 5: Export ----
          tabPanel("Export Results",
            h4("Export Loop Analysis"),

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

    # ============================================================================
    # CACHED REACTIVE: Graph Construction
    # ============================================================================
    # This reactive expression builds an igraph object from ISA data.
    #
    # CACHING:
    # - Cached based on ISA data digest (xxhash64)
    # - Cache invalidates automatically when ISA data changes
    # - Cache persists for session duration
    #
    # PERFORMANCE:
    # - First call: ~100-500ms (depends on network size)
    # - Cached calls: < 1ms (instant return)
    # - Cache hit rate: Typically 80-95% during analysis sessions
    #
    # USAGE:
    # - Call graph_data <- build_graph_from_isa() anywhere
    # - No need to worry about cache management
    # - Cache automatically handles invalidation
    # ============================================================================
    build_graph_from_isa <- reactive({
      start_time <- Sys.time()

      req(project_data_reactive())

      isa_data <- project_data_reactive()$data$isa_data

      if(is.null(isa_data)) return(NULL)

      # Use the existing helper functions to build nodes and edges
      # These functions properly handle adjacency matrices from templates
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
      # Cache key: Digest of ISA data
      # Recomputes only when ISA data changes
      digest::digest(
        project_data_reactive()$data$isa_data,
        algo = "xxhash64"
      ),
      cache = "session"  # Per-session cache (default)
    )

    # Detect Loops ----
    observeEvent(input$detect_loops, {

      cat("═══════════════════════════════════════════════════════════════════\n")
      cat("[LOOP DETECTION] Button clicked at", format(Sys.time(), "%H:%M:%S"), "\n")
      cat("═══════════════════════════════════════════════════════════════════\n")

      output$detection_status <- renderText(i18n$t("analysis_detecting_loops"))

      # DIAGNOSTIC: Step 1 - Build graph
      cat("[STEP 1/7] Building graph from ISA data...\n")
      step_start <- Sys.time()

      graph_data <- build_graph_from_isa()

      if(is.null(graph_data)) {
        cat("[ERROR] No graph data available\n")
        output$detection_status <- renderText(i18n$t("analysis_no_graph_data"))
        showNotification(i18n$t("analysis_no_isa_data"), type = "error")
        return()
      }

      g <- graph_data$graph
      nodes <- graph_data$nodes
      edges <- graph_data$edges

      step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
      cat(sprintf("[STEP 1/7] ✓ Graph built in %.3f seconds\n", step_elapsed))

      # Log basic graph info for monitoring
      cat(sprintf("[GRAPH INFO] Nodes: %d, Edges: %d\n", vcount(g), ecount(g)))
      cat(sprintf("[GRAPH INFO] Density: %.4f\n", edge_density(g)))

      # DIAGNOSTIC: Step 2 - Analyze SCC structure
      cat("[STEP 2/7] Analyzing strongly connected components...\n")
      step_start <- Sys.time()

      scc <- components(g, mode = "strong")
      comp_sizes <- table(scc$membership)
      max_comp_size <- max(comp_sizes)

      step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
      cat(sprintf("[STEP 2/7] ✓ SCC analysis completed in %.3f seconds\n", step_elapsed))
      cat(sprintf("[SCC INFO] Number of components: %d\n", length(unique(scc$membership))))
      cat(sprintf("[SCC INFO] Largest component: %d nodes\n", max_comp_size))
      cat(sprintf("[SCC INFO] Average component size: %.1f nodes\n", mean(comp_sizes)))

      # Check for reasonable graph size to prevent hanging
      if(vcount(g) > 100 || ecount(g) > 500) {
        cat("[WARNING] Large network detected - may take longer\n")
        showNotification(
          paste0(i18n$t("Large network detected:"), " ", vcount(g), " ", i18n$t("nodes"), ", ", ecount(g), " ", i18n$t("edges"), ". ",
                 i18n$t("Loop detection may take longer. Consider reducing max_cycles or max_loop_length.")),
          type = "warning",
          duration = 8
        )
      }

      if(vcount(g) > 300 || ecount(g) > 1500) {
        cat("[ERROR] Network too large - refusing to process\n")
        output$detection_status <- renderText(i18n$t("Graph too large for reliable loop detection. Please simplify the network first."))
        showNotification(
          i18n$t("Error: Network too large (>300 nodes or >1500 edges). Loop detection disabled to prevent hanging."),
          type = "error",
          duration = 15
        )
        return()
      }

      # Use optimized loop detection algorithm from network_analysis.R
      withProgress(message = 'Detecting loops (this may take 10-30 seconds)...', value = 0, {

        incProgress(0.1, detail = "Preparing detection parameters...")
        Sys.sleep(0.1)  # Force UI update

        # Use the optimized find_all_cycles function which uses strongly connected components
        tryCatch({
          # DIAGNOSTIC: Step 3 - Prepare parameters
          cat("[STEP 3/7] Preparing detection parameters...\n")

          # Get max_cycles from user input, with sensible default
          max_cycles_limit <- if(!is.null(input$max_cycles) && input$max_cycles > 0) {
            input$max_cycles
          } else {
            500
          }

          # Limit max_loop_length to prevent hanging
          safe_max_length <- min(input$max_loop_length, 8)  # Cap at 8 to prevent exponential explosion

          cat(sprintf("[STEP 3/7] ✓ Parameters set: max_length=%d (requested: %d), max_cycles=%d\n",
                      safe_max_length, input$max_loop_length, max_cycles_limit))

          incProgress(0.1, detail = "Analyzing components...")
          Sys.sleep(0.1)  # Force UI update

          incProgress(0.1, detail = "Finding cycles (please wait)...")
          Sys.sleep(0.1)  # Force UI update

          # Run with timeout to prevent hanging
          all_loops <- NULL
          error_occurred <- FALSE

          # DIAGNOSTIC: Step 4 - Run cycle detection
          cat("[STEP 4/7] Starting cycle detection...\n")
          cat(sprintf("[TIMING] Detection start: %s\n", format(Sys.time(), "%H:%M:%S.%OS3")))
          step_start <- Sys.time()

          tryCatch({
            # Set a reasonable timeout (30 seconds)
            setTimeLimit(cpu = 30, elapsed = 30, transient = TRUE)
            cat("[TIMEOUT] Set to 30 seconds\n")

            all_loops <- find_all_cycles(
              nodes, edges,
              max_length = safe_max_length,
              max_cycles = max_cycles_limit
            )

            # Reset time limit
            setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
            cat("[TIMEOUT] Reset\n")

            step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
            cat(sprintf("[STEP 4/7] ✓ Cycle detection completed in %.3f seconds\n", step_elapsed))
            cat(sprintf("[RESULT] Found %d cycles\n", ifelse(is.null(all_loops), 0, length(all_loops))))
          }, error = function(e) {
            # Reset time limit
            setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)

            step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
            cat(sprintf("[STEP 4/7] ✗ ERROR after %.3f seconds: %s\n", step_elapsed, e$message))

            if (grepl("time limit", e$message, ignore.case = TRUE)) {
              cat("[ERROR] Timeout occurred\n")
              showNotification(
                i18n$t("Loop detection timed out after 30 seconds. Try reducing max loop length or max cycles."),
                type = "error",
                duration = 10
              )
            } else {
              cat(sprintf("[ERROR] Exception: %s\n", e$message))
              showNotification(
                paste(i18n$t("Error during loop detection:"), e$message),
                type = "error",
                duration = 10
              )
            }
            error_occurred <<- TRUE
          })

          if (error_occurred || is.null(all_loops)) {
            cat("[ABORT] Detection failed or timed out\n")
            output$detection_status <- renderText(i18n$t("Loop detection failed or timed out."))
            return()
          }

          incProgress(0.1, detail = "Processing detected loops...")
          Sys.sleep(0.1)  # Force UI update

          if(length(all_loops) == 0) {
            cat("[INFO] No loops found in network\n")
            output$detection_status <- renderText(i18n$t("analysis_no_loops_detected"))
            showNotification(i18n$t("analysis_no_loops_found"), type = "warning")
            return()
          }

          # DIAGNOSTIC: Step 5 - Limit loops for display
          cat("[STEP 5/7] Limiting loops for display...\n")
          max_loops_display <- 500
          original_count <- length(all_loops)

          if(length(all_loops) > max_loops_display) {
            cat(sprintf("[INFO] Limiting from %d to %d loops\n", original_count, max_loops_display))
            showNotification(
              paste0(i18n$t("Found"), " ", length(all_loops), " ", i18n$t("loops. Displaying first"), " ", max_loops_display, " ", i18n$t("loops.")),
              type = "warning",
              duration = 10
            )
            all_loops <- all_loops[1:max_loops_display]
          }
          cat(sprintf("[STEP 5/7] ✓ Will process %d loops\n", length(all_loops)))

          incProgress(0.1, detail = "Processing loop details...")
          Sys.sleep(0.1)  # Force UI update

          # DIAGNOSTIC: Step 6 - Process loops to dataframe
          cat("[STEP 6/7] Processing cycles to dataframe...\n")
          step_start <- Sys.time()

          loop_info <- process_cycles_to_loops(all_loops, nodes, edges, g)

          step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
          cat(sprintf("[STEP 6/7] ✓ Processing completed in %.3f seconds\n", step_elapsed))
          cat(sprintf("[RESULT] Created dataframe with %d rows\n", nrow(loop_info)))

          incProgress(0.2, detail = "Finalizing results...")
          Sys.sleep(0.1)  # Force UI update

          # DIAGNOSTIC: Step 7 - Save results
          cat("[STEP 7/7] Saving results...\n")
          step_start <- Sys.time()

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

          step_elapsed <- as.numeric(Sys.time() - step_start, units = "secs")
          cat(sprintf("[STEP 7/7] ✓ Results saved in %.3f seconds\n", step_elapsed))

          output$detection_status <- renderText(
            paste("Detection complete! Found", nrow(loop_info), "loops.")
          )

          showNotification(
            paste(i18n$t("Detection complete! Found"), nrow(loop_info), i18n$t("feedback loops.")),
            type = "message"
          )

          cat("═══════════════════════════════════════════════════════════════════\n")
          cat("[LOOP DETECTION] Completed successfully at", format(Sys.time(), "%H:%M:%S"), "\n")
          cat(sprintf("[SUMMARY] Total loops found: %d\n", nrow(loop_info)))
          cat("═══════════════════════════════════════════════════════════════════\n\n")

        }, error = function(e) {
          output$detection_status <- renderText(paste(i18n$t("Error during loop detection:"), conditionMessage(e)))
          showNotification(
            paste(i18n$t("Loop detection failed:"), conditionMessage(e)),
            type = "error",
            duration = 10
          )
          cat("[Loop Detection ERROR]:", conditionMessage(e), "\n")
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
        label = unique_labels,  # Use descriptive labels instead of IDs
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
          width = 5,  # 5x thicker edges for better loop visibility
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
      loops$DominanceScore <- 100 / loops$Length  # Shorter loops often more influential
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
        paste0("Loop_Analysis_", Sys.Date(), ".xlsx")
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
        h4(i18n$t("What are feedback loops?")),
        p(i18n$t("Feedback loops are circular patterns in the system where an element eventually affects itself through a chain of causal connections. These loops are fundamental to understanding system dynamics and behavior.")),
        hr(),
        h5(i18n$t("Loop types:")),
        tags$ul(
          tags$li(strong(i18n$t("Reinforcing loops (R):")), i18n$t(" Amplify change in the system.")),
          tags$ul(
            tags$li(i18n$t("Rule: Even number of negative connections (-)")),
            tags$li(i18n$t("Behavior: Can create virtuous cycles (exponential growth) or vicious cycles (collapse)")),
            tags$li(i18n$t("Example: Species population → + Reproduction rate → + Species population"))
          ),
          tags$li(strong(i18n$t("Balancing loops (B):")), i18n$t(" Counteract change and seek equilibrium.")),
          tags$ul(
            tags$li(i18n$t("Rule: Odd number of negative connections (-)")),
            tags$li(i18n$t("Behavior: Produces resistance to change and system stabilization")),
            tags$li(i18n$t("Example: Fishing → - Fish biomass → - Fishing"))
          )
        ),
        hr(),
        h5(i18n$t("How to use this tool:")),
        tags$ol(
          tags$li(strong(i18n$t("1. Detect loops:")), i18n$t(" Set detection parameters (maximum length, number of cycles) and run automatic detection")),
          tags$li(strong(i18n$t("2. Classification:")), i18n$t(" Review reinforcing and balancing loops found")),
          tags$li(strong(i18n$t("3. Details:")), i18n$t(" Examine individual loops and see their complete path")),
          tags$li(strong(i18n$t("4. Visualization:")), i18n$t(" See highlighted loops in the context of your full network")),
          tags$li(strong(i18n$t("5. Element participation:")), i18n$t(" Identify which system elements participate in most loops")),
          tags$li(strong(i18n$t("6. Export:")), i18n$t(" Save results in Excel or CSV formats for further analysis"))
        ),
        hr(),
        h5(i18n$t("Understanding the results:")),
        tags$ul(
          tags$li(strong(i18n$t("Loop length:")), i18n$t(" Number of elements in the loop. Shorter loops (3-5 elements) tend to have greater influence.")),
          tags$li(strong(i18n$t("Dominance score:")), i18n$t(" Measures how significant the loop is based on the centrality of its elements.")),
          tags$li(strong(i18n$t("Element participation:")), i18n$t(" Elements appearing in multiple loops are potential leverage points for interventions."))
        ),
        hr(),
        p(em(i18n$t("Understanding feedback loops: Reinforcing loops often identify areas of system growth or collapse, while balancing loops identify stabilization mechanisms or resistance to change.")))
      ),
      i18n = i18n
    )

    return(reactive({ loop_data }))
  })
}

# ============================================================================
# NETWORK METRICS MODULE
# ============================================================================

analysis_metrics_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    h2(icon("chart-line"), " ", i18n$t("Network Metrics Analysis")),
    p(i18n$t("Calculate and visualize centrality metrics to identify key nodes and understand network structure.")),

    # Check if CLD exists
    uiOutput(ns("cld_check_ui")),

    # Main metrics interface (shown only if CLD exists)
    uiOutput(ns("metrics_main_ui"))
  )
}

analysis_metrics_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for metrics
    metrics_rv <- reactiveValues(
      calculated_metrics = NULL,
      node_metrics_df = NULL
    )

    # Check if CLD data exists
    output$cld_check_ui <- renderUI({
      req(project_data_reactive())

      data <- project_data_reactive()

      if (is.null(data$data$cld) || is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        div(
          class = "alert alert-warning",
          icon("exclamation-triangle"), " ",
          strong(i18n$t("No CLD data found.")),
          p(i18n$t("Please generate a CLD network first using:"), style = "margin-top: 10px;"),
          tags$ol(
            tags$li(i18n$t("Navigate to 'ISA Data Entry' and complete your SES model")),
            tags$li(i18n$t("Go to 'CLD Visualization' and click 'Generate CLD'")),
            tags$li(i18n$t("Return here to analyze network metrics"))
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
                        i18n$t("Calculate Network Metrics"),
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
          i18n$t("Network metrics calculated successfully!"),
          type = "message",
          duration = 3
        )

      }, error = function(e) {
        showNotification(
          paste(i18n$t("Error calculating metrics:"), e$message),
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
            h3(icon("network-wired"), paste(" ", i18n$t("Network Summary")))
          )
        ),

        fluidRow(
          valueBox(
            value = metrics$nodes,
            subtitle = i18n$t("Total Nodes"),
            icon = icon("circle"),
            color = "blue",
            width = 3
          ),
          valueBox(
            value = metrics$edges,
            subtitle = i18n$t("Total Edges"),
            icon = icon("arrow-right"),
            color = "green",
            width = 3
          ),
          valueBox(
            value = round(metrics$density, 3),
            subtitle = i18n$t("Network Density"),
            icon = icon("project-diagram"),
            color = "purple",
            width = 3
          ),
          valueBox(
            value = metrics$diameter,
            subtitle = i18n$t("Network Diameter"),
            icon = icon("arrows-alt"),
            color = "orange",
            width = 3
          )
        ),

        fluidRow(
          column(6,
            wellPanel(
              h5(icon("info-circle"), paste(" ", i18n$t("Average Path Length"))),
              h3(round(metrics$avg_path_length, 2)),
              p(class = "text-muted", i18n$t("Average shortest path between any two nodes"))
            )
          ),
          column(6,
            wellPanel(
              h5(icon("percentage"), paste(" ", i18n$t("Network Connectivity"))),
              h3(paste0(round(metrics$density * 100, 1), "%")),
              p(class = "text-muted", i18n$t("Percentage of possible connections that exist"))
            )
          )
        ),

        hr(),

        # Node-level metrics
        fluidRow(
          column(12,
            h3(icon("users"), paste(" ", i18n$t("Node-Level Centrality Metrics")))
          )
        ),

        fluidRow(
          column(12,
            tabsetPanel(
              id = ns("metrics_tabs"),

              # Metrics Table
              tabPanel(
                title = tagList(icon("table"), paste(" ", i18n$t("All Metrics"))),
                br(),
                DTOutput(ns("metrics_table")),
                br(),
                downloadButton(ns("download_metrics"),
                              i18n$t("Download Network Metrics"),
                              class = "btn-success")
              ),

              # Visualizations
              tabPanel(
                title = tagList(icon("chart-bar"), paste(" ", i18n$t("Visualizations"))),
                br(),
                fluidRow(
                  column(6,
                    selectInput(ns("viz_metric"),
                               i18n$t("Select Metric"),
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
                                i18n$t("Top N Nodes"),
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
                      h5(i18n$t("Comparison Plot - Degree vs Betweenness")),
                      plotOutput(ns("metrics_comparison"), height = "400px")
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(i18n$t("Distribution Histogram")),
                      plotOutput(ns("metrics_histogram"), height = "400px")
                    )
                  )
                )
              ),

              # Key Nodes
              tabPanel(
                title = tagList(icon("star"), paste(" ", i18n$t("Key Nodes"))),
                br(),
                h4(i18n$t("Most Important Nodes by Different Metrics")),
                fluidRow(
                  column(6,
                    wellPanel(
                      h5(icon("arrows-alt-h"), paste(" ", i18n$t("Top 5 Nodes by Degree"))),
                      p(class = "text-muted", i18n$t("Most connected nodes in the network")),
                      tableOutput(ns("top_degree"))
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(icon("route"), paste(" ", i18n$t("Top 5 Nodes by Betweenness"))),
                      p(class = "text-muted", i18n$t("Critical bridge nodes connecting different parts")),
                      tableOutput(ns("top_betweenness"))
                    )
                  )
                ),
                fluidRow(
                  column(6,
                    wellPanel(
                      h5(icon("compress-arrows-alt"), paste(" ", i18n$t("Top 5 Nodes by Closeness"))),
                      p(class = "text-muted", i18n$t("Most central nodes with shortest paths to others")),
                      tableOutput(ns("top_closeness"))
                    )
                  ),
                  column(6,
                    wellPanel(
                      h5(icon("crown"), paste(" ", i18n$t("Top 5 Nodes by PageRank"))),
                      p(class = "text-muted", i18n$t("Most influential nodes based on incoming connections")),
                      tableOutput(ns("top_pagerank"))
                    )
                  )
                )
              ),

              # Interpretation Guide
              tabPanel(
                title = tagList(icon("question-circle"), paste(" ", i18n$t("Guide"))),
                br(),
                h4(i18n$t("Understanding Centrality Metrics")),

                wellPanel(
                  h5(icon("info-circle"), paste(" ", i18n$t("Network-Level Metrics"))),
                  tags$dl(
                    tags$dt(i18n$t("Network Density")),
                    tags$dd(i18n$t("Proportion of actual connections to possible connections. Higher density indicates more interconnected system.")),

                    tags$dt(i18n$t("Network Diameter")),
                    tags$dd(i18n$t("Longest shortest path between any two nodes. Indicates how far information needs to travel.")),

                    tags$dt(i18n$t("Average Path Length")),
                    tags$dd(i18n$t("Average steps needed to reach any node from any other node."))
                  )
                ),

                wellPanel(
                  h5(icon("users"), paste(" ", i18n$t("Node Centrality Metrics"))),
                  tags$dl(
                    tags$dt(i18n$t("Degree Centrality")),
                    tags$dd(i18n$t("Number of direct connections. High degree = well-connected hub.")),

                    tags$dt(i18n$t("Betweenness Centrality")),
                    tags$dd(i18n$t("How often a node lies on shortest paths between other nodes. High betweenness = important bridge or bottleneck.")),

                    tags$dt(i18n$t("Closeness Centrality")),
                    tags$dd(i18n$t("How close a node is to all other nodes. High closeness = can quickly reach or be reached by others.")),

                    tags$dt(i18n$t("Eigenvector Centrality")),
                    tags$dd(i18n$t("Importance based on connections to other important nodes. High eigenvector = well-connected to other hubs.")),

                    tags$dt(i18n$t("PageRank")),
                    tags$dd(i18n$t("Google's algorithm: importance based on quality and quantity of incoming connections."))
                  )
                ),

                wellPanel(
                  h5(icon("lightbulb"), paste(" ", i18n$t("Practical Applications"))),
                  tags$ul(
                    tags$li(strong(i18n$t("High Degree:")), paste(" ", i18n$t("Target for broad interventions"))),
                    tags$li(strong(i18n$t("High Betweenness:")), paste(" ", i18n$t("Leverage points for system change"))),
                    tags$li(strong(i18n$t("High Closeness:")), paste(" ", i18n$t("Efficient information spreaders"))),
                    tags$li(strong(i18n$t("High PageRank:")), paste(" ", i18n$t("Most influential system components")))
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
          order = list(list(3, 'desc'))  # Sort by Degree descending
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
        main = i18n$t("Bar Plot - Top Nodes by Selected Metric"),
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
           xlab = i18n$t("Degree Centrality"),
           ylab = i18n$t("Betweenness Centrality"),
           main = i18n$t("Comparison Plot - Degree vs Betweenness"),
           pch = 19,
           cex = top10$PageRank_norm * 3 + 0.5,
           col = adjustcolor("#3498db", alpha = 0.6))

      text(top10$Degree_norm, top10$Betweenness_norm,
           labels = top10$Label,
           pos = 3,
           cex = 0.7)

      legend("topright",
             legend = i18n$t("Bubble size represents PageRank"),
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
           main = i18n$t("Distribution Histogram"),
           xlab = metric_col,
           ylab = i18n$t("Frequency"))

      abline(v = mean(values), col = "red", lwd = 2, lty = 2)
      abline(v = median(values), col = "darkgreen", lwd = 2, lty = 2)

      legend("topright",
             legend = c(i18n$t("Mean"), i18n$t("Median")),
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

# ============================================================================
# BOT ANALYSIS MODULE - Behaviour Over Time
# ============================================================================

analysis_bot_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    h2(icon("chart-line"), " Advanced BOT Analysis"),
    p("Analyze temporal patterns and trends in your social-ecological system."),

    fluidRow(
      # Left Panel: Data Input and Configuration
      column(4,
        wellPanel(
          h4(icon("database"), " Time Series Data"),

          # Element Selection
          selectInput(ns("bot_element"), "Select Element:",
                     choices = c("Select element..." = ""),
                     width = "100%"),

          # Time Period
          sliderInput(ns("bot_years"), "Time Period:",
                     min = 1950, max = 2030, value = c(2000, 2024),
                     step = 1, sep = ""),

          # Data Input Method
          radioButtons(ns("data_input_method"), "Data Input Method:",
                      choices = c("Manual Entry" = "manual",
                                 "Upload CSV" = "upload",
                                 "Use ISA BOT Data" = "isa"),
                      selected = "isa"),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'manual'", ns("data_input_method")),
            numericInput(ns("manual_year"), "Year:", value = 2024, min = 1950, max = 2030),
            numericInput(ns("manual_value"), "Value:", value = 100),
            actionButton(ns("add_datapoint"), "Add Data Point", class = "btn-sm btn-primary")
          ),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'upload'", ns("data_input_method")),
            fileInput(ns("upload_csv"), "Upload CSV (Year, Value):",
                     accept = c(".csv"))
          ),

          hr(),

          # Analysis Options
          h5(icon("sliders-h"), " Analysis Options"),

          checkboxInput(ns("show_trend"), "Show Trend Line", value = TRUE),
          checkboxInput(ns("show_moving_avg"), "Show Moving Average", value = FALSE),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("show_moving_avg")),
            sliderInput(ns("moving_avg_window"), "Window Size:",
                       min = 2, max = 10, value = 3, step = 1)
          ),

          checkboxInput(ns("detect_patterns"), "Detect Patterns", value = FALSE),

          hr(),
          actionButton(ns("help_bot"), "Help", icon = icon("question-circle"), class = "btn-info btn-sm")
        )
      ),

      # Right Panel: Visualizations and Analysis
      column(8,
        tabsetPanel(
          # Time Series Plot
          tabPanel(icon("chart-line"), "Time Series",
            br(),
            dygraphOutput(ns("bot_timeseries"), height = "400px"),
            br(),
            h5(icon("table"), " Summary Statistics"),
            verbatimTextOutput(ns("bot_stats"))
          ),

          # Pattern Detection
          tabPanel(icon("search"), "Pattern Analysis",
            br(),
            h4("Temporal Pattern Detection"),
            conditionalPanel(
              condition = sprintf("!input['%s']", ns("detect_patterns")),
              p(class = "text-muted", "Enable 'Detect Patterns' to analyze temporal dynamics.")
            ),
            conditionalPanel(
              condition = sprintf("input['%s']", ns("detect_patterns")),
              uiOutput(ns("pattern_results"))
            )
          ),

          # Data Table
          tabPanel(icon("table"), "Data",
            br(),
            DTOutput(ns("bot_data_table")),
            br(),
            div(style = "margin-top: 10px;",
              downloadButton(ns("download_bot_data"), "Download Data", class = "btn-sm"),
              actionButton(ns("clear_data"), "Clear All Data", class = "btn-sm btn-warning")
            )
          ),

          # Comparison
          tabPanel(icon("exchange-alt"), "Scenario Comparison",
            br(),
            h4("Compare Multiple Scenarios"),
            p("Upload or create multiple time series to compare different scenarios."),
            p(class = "text-muted", "Feature coming soon...")
          )
        )
      )
    )
  )
}

analysis_bot_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # Reactive values for BOT data
    bot_rv <- reactiveValues(
      current_element = NULL,
      timeseries_data = data.frame(Year = integer(), Value = numeric())
    )

    # Update element choices from ISA data
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      isa_data <- data$data$isa_data

      # Get all element names
      all_elements <- c()
      if (!is.null(isa_data$goods_benefits) && nrow(isa_data$goods_benefits) > 0) {
        gb_names <- if("Name" %in% names(isa_data$goods_benefits)) {
          isa_data$goods_benefits$Name
        } else if("name" %in% names(isa_data$goods_benefits)) {
          isa_data$goods_benefits$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("G&B: ", gb_names))
      }

      if (!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
        es_names <- if("Name" %in% names(isa_data$ecosystem_services)) {
          isa_data$ecosystem_services$Name
        } else if("name" %in% names(isa_data$ecosystem_services)) {
          isa_data$ecosystem_services$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("ES: ", es_names))
      }

      if (!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
        p_names <- if("Name" %in% names(isa_data$pressures)) {
          isa_data$pressures$Name
        } else if("name" %in% names(isa_data$pressures)) {
          isa_data$pressures$name
        } else {
          character(0)
        }
        all_elements <- c(all_elements, paste0("Pressure: ", p_names))
      }

      updateSelectInput(session, "bot_element",
                       choices = c("Select element..." = "", all_elements))
    })

    # Manual data point addition
    observeEvent(input$add_datapoint, {
      req(input$manual_year, input$manual_value)

      new_point <- data.frame(
        Year = input$manual_year,
        Value = input$manual_value
      )

      bot_rv$timeseries_data <- rbind(bot_rv$timeseries_data, new_point)
      bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]

      showNotification(i18n$t("analysis_data_added"), type = "message")
    })

    # CSV upload
    observeEvent(input$upload_csv, {
      req(input$upload_csv)

      tryCatch({
        uploaded <- read.csv(input$upload_csv$datapath)
        if(has_required_columns(uploaded, c("Year", "Value"))) {
          bot_rv$timeseries_data <- uploaded[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
          showNotification(i18n$t("analysis_csv_loaded"), type = "message")
        } else {
          showNotification(i18n$t("analysis_csv_columns_error"), type = "error")
        }
      }, error = function(e) {
        showNotification(paste(i18n$t("analysis_error_loading_csv"), e$message), type = "error")
      })
    })

    # Load ISA BOT data
    observe({
      req(input$data_input_method == "isa")
      req(project_data_reactive())

      data <- project_data_reactive()
      if(!is.null(data$data$isa_data$bot_data) && nrow(data$data$isa_data$bot_data) > 0) {
        # Load BOT data if it has the required Year and Value columns
        bot_data <- data$data$isa_data$bot_data
        if(has_required_columns(bot_data, c("Year", "Value"))) {
          bot_rv$timeseries_data <- bot_data[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
        }
      }
    })

    # Clear data
    observeEvent(input$clear_data, {
      bot_rv$timeseries_data <- data.frame(Year = integer(), Value = numeric())
      showNotification(i18n$t("analysis_data_cleared"), type = "warning")
    })

    # Time series plot with dygraphs
    output$bot_timeseries <- renderDygraph({
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      # Convert to xts for dygraphs
      ts_xts <- xts::xts(ts_data$Value, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

      dg <- dygraph(ts_xts, main = paste("BOT Analysis:", input$bot_element),
                   xlab = "Year", ylab = "Value") %>%
        dyOptions(colors = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
        dyRangeSelector() %>%
        dyHighlight(highlightCircleSize = 5,
                   highlightSeriesBackgroundAlpha = 0.2,
                   hideOnMouseOut = FALSE)

      # Add trend line if requested
      if(input$show_trend && nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        trend_values <- predict(lm_fit, newdata = ts_data)
        trend_xts <- xts::xts(trend_values, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

        combined <- merge(ts_xts, trend_xts)
        names(combined) <- c("Actual", "Trend")

        dg <- dygraph(combined) %>%
          dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
          dySeries("Trend", color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
          dyRangeSelector() %>%
          dyHighlight(highlightCircleSize = 5)
      }

      # Add moving average if requested
      if(input$show_moving_avg && nrow(ts_data) > input$moving_avg_window) {
        ma_values <- stats::filter(ts_data$Value, rep(1/input$moving_avg_window, input$moving_avg_window), sides = 2)
        ma_xts <- xts::xts(ma_values, order.by = as.Date(paste0(ts_data$Year, "-01-01")))

        if(input$show_trend) {
          combined <- merge(combined, ma_xts)
          names(combined) <- c("Actual", "Trend", "Moving Avg")
          dg <- dygraph(combined) %>%
            dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries("Trend", color = "#FF5722", strokeWidth = 2, strokePattern = "dashed") %>%
            dySeries("Moving Avg", color = "#4CAF50", strokeWidth = 2) %>%
            dyRangeSelector()
        } else {
          combined <- merge(ts_xts, ma_xts)
          names(combined) <- c("Actual", "Moving Avg")
          dg <- dygraph(combined) %>%
            dySeries("Actual", color = "#2196F3", strokeWidth = 2, drawPoints = TRUE, pointSize = 4) %>%
            dySeries("Moving Avg", color = "#4CAF50", strokeWidth = 2) %>%
            dyRangeSelector()
        }
      }

      dg
    })

    # Summary statistics
    output$bot_stats <- renderText({
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      stats_text <- paste(
        sprintf("Number of observations: %d", nrow(ts_data)),
        sprintf("Time period: %d - %d", min(ts_data$Year), max(ts_data$Year)),
        sprintf("Mean value: %.2f", mean(ts_data$Value, na.rm = TRUE)),
        sprintf("Std deviation: %.2f", sd(ts_data$Value, na.rm = TRUE)),
        sprintf("Min value: %.2f (Year %d)", min(ts_data$Value), ts_data$Year[which.min(ts_data$Value)]),
        sprintf("Max value: %.2f (Year %d)", max(ts_data$Value), ts_data$Year[which.max(ts_data$Value)]),
        sep = "\n"
      )

      # Add trend info if enabled
      if(input$show_trend && nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        slope <- coef(lm_fit)[2]
        r_squared <- summary(lm_fit)$r.squared

        trend_direction <- if(slope > 0) "Increasing" else if(slope < 0) "Decreasing" else "Stable"

        stats_text <- paste(
          stats_text,
          "",
          "Trend Analysis:",
          sprintf("  Direction: %s", trend_direction),
          sprintf("  Rate of change: %.2f units/year", slope),
          sprintf("  R-squared: %.3f", r_squared),
          sep = "\n"
        )
      }

      stats_text
    })

    # Pattern detection
    output$pattern_results <- renderUI({
      req(input$detect_patterns)
      req(nrow(bot_rv$timeseries_data) > 0)

      ts_data <- bot_rv$timeseries_data

      patterns <- list()

      # Trend pattern
      if(nrow(ts_data) > 2) {
        lm_fit <- lm(Value ~ Year, data = ts_data)
        slope <- coef(lm_fit)[2]
        p_value <- summary(lm_fit)$coefficients[2, 4]

        if(p_value < 0.05) {
          if(slope > 0) {
            patterns <- c(patterns, list(tags$div(
              class = "alert alert-info",
              icon("arrow-up"), strong(" Significant Increasing Trend Detected"),
              p(sprintf("The data shows a statistically significant upward trend (p < 0.05) with an average increase of %.2f units per year.", slope))
            )))
          } else {
            patterns <- c(patterns, list(tags$div(
              class = "alert alert-warning",
              icon("arrow-down"), strong(" Significant Decreasing Trend Detected"),
              p(sprintf("The data shows a statistically significant downward trend (p < 0.05) with an average decrease of %.2f units per year.", abs(slope)))
            )))
          }
        }
      }

      # Volatility pattern
      if(nrow(ts_data) > 3) {
        cv <- sd(ts_data$Value) / mean(ts_data$Value) * 100
        if(cv > 30) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-danger",
            icon("exclamation-triangle"), strong(" High Volatility Detected"),
            p(sprintf("Coefficient of variation: %.1f%%. The system shows high variability, suggesting instability or external shocks.", cv))
          )))
        }
      }

      # Growth/decline phases
      if(nrow(ts_data) > 5) {
        diffs <- diff(ts_data$Value)
        growth_phases <- sum(diffs > 0)
        decline_phases <- sum(diffs < 0)

        if(growth_phases > decline_phases * 2) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-success",
            icon("chart-line"), strong(" Predominantly Growth Phase"),
            p(sprintf("%d periods of growth vs %d periods of decline.", growth_phases, decline_phases))
          )))
        } else if(decline_phases > growth_phases * 2) {
          patterns <- c(patterns, list(tags$div(
            class = "alert alert-warning",
            icon("chart-line"), strong(" Predominantly Decline Phase"),
            p(sprintf("%d periods of decline vs %d periods of growth.", decline_phases, growth_phases))
          )))
        }
      }

      if(length(patterns) == 0) {
        return(tags$div(
          class = "alert alert-secondary",
          icon("info-circle"), " No significant patterns detected in the current time series."
        ))
      }

      do.call(tagList, patterns)
    })

    # Data table
    output$bot_data_table <- renderDT({
      datatable(bot_rv$timeseries_data,
               options = list(pageLength = 10, scrollY = "300px"),
               rownames = FALSE,
               editable = TRUE)
    })

    # Download handler
    output$download_bot_data <- downloadHandler(
      filename = function() {
        paste0("BOT_Data_", input$bot_element, "_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(bot_rv$timeseries_data, file, row.names = FALSE)
      }
    )

    # Help modal
    observeEvent(input$help_bot, {
      showModal(modalDialog(
        title = "Advanced BOT Analysis - Help",
        size = "l",
        easyClose = TRUE,

        h4(icon("info-circle"), " What is BOT Analysis?"),
        p("Behaviour Over Time (BOT) analysis examines how key system indicators change over time, revealing important dynamics such as trends, oscillations, and regime shifts."),

        h5(icon("chart-line"), " Features"),
        tags$ul(
          tags$li(strong("Interactive Time Series:"), " Zoom, pan, and explore temporal patterns with dygraphs"),
          tags$li(strong("Trend Analysis:"), " Automatically detect and visualize linear trends"),
          tags$li(strong("Moving Averages:"), " Smooth out short-term fluctuations"),
          tags$li(strong("Pattern Detection:"), " Identify significant trends, volatility, and phase changes"),
          tags$li(strong("Multiple Data Sources:"), " Manual entry, CSV upload, or ISA data import")
        ),

        h5(icon("lightbulb"), " Interpreting Patterns"),
        tags$ul(
          tags$li(strong("Increasing Trend:"), " System variable is growing over time"),
          tags$li(strong("Decreasing Trend:"), " System variable is declining"),
          tags$li(strong("High Volatility:"), " Large fluctuations suggest instability or external shocks"),
          tags$li(strong("Growth/Decline Phases:"), " Periods of consistent increase or decrease")
        ),

        h5(icon("book"), " Best Practices"),
        tags$ol(
          tags$li("Select meaningful time periods that capture system dynamics"),
          tags$li("Use multiple data points (5+ recommended) for reliable trend detection"),
          tags$li("Compare BOT graphs across different elements to understand relationships"),
          tags$li("Look for tipping points or regime shifts in the data"),
          tags$li("Validate patterns with stakeholder knowledge")
        ),

        footer = modalButton("Close")
      ))
    })

  })
}

# ============================================================================
# SIMPLIFICATION TOOLS MODULE
# ============================================================================
# Purpose: Reduce network complexity while preserving essential structure
# Methods: SISO encapsulation, exogenous removal, weak edge filtering,
#          low-centrality node removal, strength-based aggregation
# ============================================================================

analysis_simplify_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    # Header with information
    fluidRow(
      column(12,
        h2(icon("compress-arrows-alt"), "Model Simplification Tools"),
        p(class = "text-muted",
          "Reduce network complexity while preserving essential causal structures and feedback loops.",
          "Apply multiple simplification methods to create focused, interpretable models."
        )
      )
    ),

    hr(),

    # Network status panel
    fluidRow(
      column(12,
        box(
          title = "Current Network Status",
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
              h4("Original Network Summary"),
              verbatimTextOutput(ns("original_summary"))
            ),
            column(6,
              h4("Simplified Network Summary"),
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
        box(
          title = "Simplification Methods",
          status = "primary",
          solidHeader = TRUE,
          width = 12,

          h4(icon("filter"), "Select Methods to Apply"),
          p(class = "text-muted", "Choose one or more simplification techniques:"),

          # Method 1: SISO Encapsulation
          checkboxInput(
            ns("method_siso"),
            label = strong("SISO Encapsulation"),
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
            label = strong("Remove Exogenous Variables"),
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
                label = i18n$t("preview_exogenous_nodes_before_removal"),
                value = TRUE
              )
            )
          ),

          hr(),

          # Method 3: Weak Connection Filtering
          checkboxInput(
            ns("method_weak_edges"),
            label = strong("Filter Weak Connections"),
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
            label = strong("Remove Low-Centrality Nodes"),
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
            label = strong("Filter by Element Type"),
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
                "Apply Simplification",
                icon = icon("compress"),
                class = "btn-primary btn-block"
              )
            ),
            column(6,
              actionButton(
                ns("reset_simplification"),
                "Reset to Original",
                icon = icon("undo"),
                class = "btn-warning btn-block"
              )
            )
          ),

          br(),

          # Save to project option
          checkboxInput(
            ns("save_to_project"),
            i18n$t("save_simplification_to_project"),
            value = FALSE
          ),
          helpText(i18n$t("save_simplification_warning")),

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
              i18n$t("restore_original_network"),
              icon = icon("history"),
              class = "btn-danger btn-block"
            ),
            helpText(i18n$t("restore_original_warning"))
          )
        )
      ),

      # Right panel - Visualization comparison
      column(8,
        box(
          title = "Network Visualization Comparison",
          status = "success",
          solidHeader = TRUE,
          width = 12,

          tabsetPanel(
            id = ns("viz_tabs"),

            # Tab 1: Side-by-side comparison
            tabPanel(
              "Side-by-Side Comparison",
              icon = icon("columns"),

              br(),

              fluidRow(
                column(6,
                  h4("Original Network", class = "text-center"),
                  visNetworkOutput(ns("original_network"), height = "500px")
                ),
                column(6,
                  h4("Simplified Network", class = "text-center"),
                  visNetworkOutput(ns("simplified_network"), height = "500px")
                )
              ),

              br(),

              fluidRow(
                column(12,
                  h4("Simplification Statistics"),
                  tableOutput(ns("simplification_stats"))
                )
              )
            ),

            # Tab 2: Simplified view only
            tabPanel(
              "Simplified View Only",
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
                  h4("Removed Nodes"),
                  div(
                    style = "max-height: 200px; overflow-y: auto;",
                    tableOutput(ns("removed_nodes_table"))
                  )
                ),
                column(6,
                  h4("Removed Edges"),
                  div(
                    style = "max-height: 200px; overflow-y: auto;",
                    tableOutput(ns("removed_edges_table"))
                  )
                )
              )
            ),

            # Tab 3: Simplification history
            tabPanel(
              "Simplification History",
              icon = icon("history"),

              br(),

              h4("Applied Simplification Methods"),
              verbatimTextOutput(ns("simplification_log")),

              br(),

              h4("Impact Summary"),
              plotOutput(ns("impact_chart"), height = "400px")
            )
          )
        )
      )
    ),

    # Information panel
    fluidRow(
      column(12,
        box(
          title = "About Model Simplification",
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

analysis_simplify_server <- function(id, project_data_reactive) {
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
      valueBox(
        node_count,
        "Original Nodes",
        icon = icon("circle"),
        color = "blue"
      )
    })

    output$original_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$original_edges)) nrow(rv$original_edges) else 0
      valueBox(
        edge_count,
        "Original Edges",
        icon = icon("arrow-right"),
        color = "blue"
      )
    })

    output$simplified_nodes_box <- renderValueBox({
      node_count <- if (!is.null(rv$simplified_nodes)) nrow(rv$simplified_nodes) else 0
      reduction <- if (!is.null(rv$original_nodes) && !is.null(rv$simplified_nodes)) {
        pct <- round((1 - nrow(rv$simplified_nodes) / nrow(rv$original_nodes)) * 100, 1)
        paste0(" (", pct, "% reduction)")
      } else ""

      valueBox(
        paste0(node_count, reduction),
        "Simplified Nodes",
        icon = icon("circle"),
        color = if (rv$has_simplified) "green" else "light-blue"
      )
    })

    output$simplified_edges_box <- renderValueBox({
      edge_count <- if (!is.null(rv$simplified_edges)) nrow(rv$simplified_edges) else 0
      reduction <- if (!is.null(rv$original_edges) && !is.null(rv$simplified_edges)) {
        pct <- round((1 - nrow(rv$simplified_edges) / nrow(rv$original_edges)) * 100, 1)
        paste0(" (", pct, "% reduction)")
      } else ""

      valueBox(
        paste0(edge_count, reduction),
        "Simplified Edges",
        icon = icon("arrow-right"),
        color = if (rv$has_simplified) "green" else "light-blue"
      )
    })

    # ========== NETWORK SUMMARIES ==========
    output$original_summary <- renderPrint({
      req(rv$original_nodes, rv$original_edges)

      cat("Network Components:\n")
      cat("------------------\n")

      # Count by element type
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

      # Count by element type
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

          # Get node names that are below threshold
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
            i18n$t("simplified_network_saved"),
            type = "success",
            duration = 4
          )
        }
      })

      showNotification(
        ifelse(isTRUE(input$save_to_project),
          i18n$t("simplification_applied_and_saved"),
          i18n$t("simplification_applied")
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

      # Check if there's a saved original to restore
      if (!is.null(data$data$cld$original_nodes)) {
        # Restore the original network
        data$data$cld$nodes <- data$data$cld$original_nodes
        data$data$cld$edges <- data$data$cld$original_edges

        # Clear backup and simplification data
        data$data$cld$original_nodes <- NULL
        data$data$cld$original_edges <- NULL
        data$data$cld$removed_nodes <- NULL
        data$data$cld$simplification_history <- NULL
        data$last_modified <- Sys.time()

        project_data_reactive(data)

        # Also reset the local reactive values
        rv$original_nodes <- data$data$cld$nodes
        rv$original_edges <- data$data$cld$edges
        rv$simplified_nodes <- data$data$cld$nodes
        rv$simplified_edges <- data$data$cld$edges
        rv$removed_nodes <- data.frame()
        rv$removed_edges <- data.frame()
        rv$simplification_history <- list()
        rv$has_simplified <- FALSE

        showNotification(
          i18n$t("original_network_restored"),
          type = "success",
          duration = 4
        )
      } else {
        showNotification(
          i18n$t("no_original_to_restore"),
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

    # Original network visualization
    output$original_network <- renderVisNetwork({
      req(rv$original_nodes, rv$original_edges)

      visNetwork(rv$original_nodes, rv$original_edges, height = "500px") %>%
        visOptions(
          highlightNearest = TRUE,
          nodesIdSelection = TRUE
        ) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(
          stabilization = TRUE,
          barnesHut = list(
            gravitationalConstant = -2000,
            springLength = 200
          )
        ) %>%
        visInteraction(
          navigationButtons = TRUE,
          hover = TRUE
        )
    })

    # Simplified network visualization (side-by-side)
    output$simplified_network <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)

      visNetwork(rv$simplified_nodes, rv$simplified_edges, height = "500px") %>%
        visOptions(
          highlightNearest = TRUE,
          nodesIdSelection = TRUE
        ) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(
          stabilization = TRUE,
          barnesHut = list(
            gravitationalConstant = -2000,
            springLength = 200
          )
        ) %>%
        visInteraction(
          navigationButtons = TRUE,
          hover = TRUE
        )
    })

    # Simplified network visualization (full view)
    output$simplified_network_full <- renderVisNetwork({
      req(rv$simplified_nodes, rv$simplified_edges)

      visNetwork(rv$simplified_nodes, rv$simplified_edges, height = "600px") %>%
        visOptions(
          highlightNearest = TRUE,
          nodesIdSelection = TRUE
        ) %>%
        visLayout(randomSeed = 42) %>%
        visPhysics(
          stabilization = TRUE,
          barnesHut = list(
            gravitationalConstant = -2000,
            springLength = 200
          )
        ) %>%
        visInteraction(
          navigationButtons = TRUE,
          hover = TRUE,
          zoomView = TRUE
        )
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
        head(50)  # Limit to 50 for display
    }, striped = TRUE, hover = TRUE)

    output$removed_edges_table <- renderTable({
      if (!rv$has_simplified || is.null(rv$removed_edges) || nrow(rv$removed_edges) == 0) {
        return(data.frame(Message = "No edges removed"))
      }

      rv$removed_edges %>%
        select(From = from, To = to, Polarity = polarity, Strength = strength, Reason = reason) %>%
        head(50)  # Limit to 50 for display
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
          cat(sprintf("  → Nodes removed: %d\n", item$removed_nodes))
        }
        if (!is.null(item$removed_edges) && item$removed_edges > 0) {
          cat(sprintf("  → Edges removed: %d\n", item$removed_edges))
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

      # Create comparison data
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

# ============================================================================
# LEVERAGE POINT ANALYSIS MODULE
# ============================================================================

#' Leverage Point Analysis UI
#'
#' @param id Module ID
#' @return UI elements
analysis_leverage_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

    create_module_header(
      ns = ns,
      title_key = "Leverage Point Analysis",
      subtitle_key = "Identify the most influential nodes in your network that could serve as key intervention points.",
      help_id = "help_leverage",
      i18n = i18n
    ),

    fluidRow(
      column(4,
        wellPanel(
          h4(icon("sliders-h"), " Analysis Settings"),
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
            "Calculate Leverage Points",
            icon = icon("calculator"),
            class = "btn-primary btn-block"
          ),
          br(),
          div(
            style = "background: #e8f4f8; padding: 10px; border-radius: 5px; border-left: 4px solid #17a2b8;",
            h5(icon("info-circle"), " About Leverage Points"),
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
            title = tagList(icon("list"), " Leverage Points"),
            value = "results",
            br(),
            uiOutput(ns("leverage_status")),
            br(),
            DT::dataTableOutput(ns("leverage_table"))
          ),

          # Network Visualization Tab
          tabPanel(
            title = tagList(icon("project-diagram"), " Network View"),
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
            title = tagList(icon("lightbulb"), " Interpretation"),
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
analysis_leverage_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {

    # Reactive values
    rv <- reactiveValues(
      leverage_results = NULL,
      has_data = FALSE
    )

    # Check if data exists - check ISA data directly like loop analysis does
    observe({
      project_data <- project_data_reactive()

      # Check for ISA data (same approach as loop analysis)
      isa_data <- project_data$data$isa_data

      if (!is.null(isa_data)) {
        # Try to build nodes/edges from ISA data to check if we have sufficient data
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

          # Build nodes and edges from ISA data (same approach as loop analysis)
          isa_data <- project_data$data$isa_data
          nodes <- create_nodes_df(isa_data)
          edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

          incProgress(0.4, detail = "Creating network graph...")

          # Calculate leverage points for all nodes
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

          # Update nodes with leverage scores and centrality metrics - match by label since that's what centralities uses
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
          project_data$data$cld$edges <- edges  # Also save edges
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

        cat("[LEVERAGE NET] Building network visualization\n")

        # Build network
        nodes <- create_nodes_df(isa_data)
        edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

        cat("[LEVERAGE NET] Nodes:", nrow(nodes), "Edges:", nrow(edges), "\n")

        # Map leverage scores to nodes
        leverage_df <- rv$leverage_results
        leverage_lookup <- setNames(leverage_df$Composite_Score, leverage_df$ID)

        cat("[LEVERAGE NET] Leverage results:", nrow(leverage_df), "rows\n")

        # Add leverage scores to nodes
        nodes$leverage_score <- leverage_lookup[nodes$id]
        nodes$leverage_score[is.na(nodes$leverage_score)] <- 0

        cat("[LEVERAGE NET] Score range:", min(nodes$leverage_score), "to", max(nodes$leverage_score), "\n")

        # Normalize scores to node sizes (15-60 range for better visibility)
        min_score <- min(nodes$leverage_score, na.rm = TRUE)
        max_score <- max(nodes$leverage_score, na.rm = TRUE)

        # Override node sizes based on leverage score
        if (max_score > min_score) {
          nodes$size <- 15 + ((nodes$leverage_score - min_score) / (max_score - min_score)) * 45
        } else {
          nodes$size <- 30  # Default size if all scores are equal
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

        cat("[LEVERAGE NET] Size range:", min(nodes$size), "to", max(nodes$size), "\n")

        cat("[LEVERAGE NET] Rendering network\n")

        # Build visNetwork (edges already in correct format)
        visNetwork(nodes, edges, width = "100%", height = "600px") %>%
          visNodes(
            shape = "dot",
            font = list(size = 14)
          ) %>%
          visEdges(
            arrows = "to",
            smooth = list(enabled = TRUE, type = "continuous")
          ) %>%
          visOptions(
            highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
            nodesIdSelection = FALSE
          ) %>%
          visInteraction(
            navigationButtons = TRUE,
            hover = TRUE,
            tooltipDelay = 100
          ) %>%
          visLayout(randomSeed = 42) %>%
          visPhysics(
            stabilization = list(iterations = 200),
            solver = "forceAtlas2Based",
            forceAtlas2Based = list(gravitationalConstant = -50, springLength = 100)
          )
      }, error = function(e) {
        cat("[LEVERAGE NET ERROR]:", conditionMessage(e), "\n")
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

          h4(icon("star"), " Top Leverage Point"),
          p(
            strong(top_node),
            sprintf(" has the highest composite score (%.2f) and represents the most strategic intervention point in your network.", top_score)
          ),

          hr(),

          h4(icon("chart-line"), " Understanding the Metrics"),

          h5(icon("exchange-alt"), " Betweenness Centrality"),
          p("Measures how often a node lies on the shortest path between other nodes. High betweenness means the node controls information flow and serves as a bridge."),

          h5(icon("network-wired"), " Eigenvector Centrality"),
          p("Measures a node's influence based on the importance of its neighbors. A node with high eigenvector centrality is connected to other important nodes."),

          h5(icon("sitemap"), " PageRank"),
          p("Originally developed for web pages, PageRank measures importance based on incoming connections and the importance of source nodes."),

          hr(),

          h4(icon("lightbulb"), " Intervention Strategies"),
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
      title_key = "Leverage Point Analysis Help",
      content = tagList(
        h4(i18n$t("What are leverage points?")),
        p(i18n$t("Leverage points are nodes in your network that have the highest potential for system-wide impact when interventions are applied. These are strategic locations where small changes can lead to significant improvements across the entire social-ecological system.")),

        hr(),
        h5(i18n$t("Metrics Used:")),
        tags$ul(
          tags$li(
            strong("Betweenness Centrality: "),
            i18n$t("Betweenness Centrality: Measures how often a node acts as a bridge between other nodes. High betweenness means the node controls information flow and can act as a bottleneck or facilitator.")
          ),
          tags$li(
            strong("Eigenvector Centrality: "),
            i18n$t("Eigenvector Centrality: Measures the influence of a node based on the importance of its neighbors. Nodes connected to other important nodes score higher.")
          ),
          tags$li(
            strong("PageRank: "),
            i18n$t("PageRank: Google's algorithm adapted for network analysis. Measures overall importance considering both direct connections and the importance of connecting nodes.")
          ),
          tags$li(
            strong("Composite Score: "),
            i18n$t("Composite Score: A combined metric that sums the normalized values of all three centrality measures to provide an overall leverage score.")
          )
        ),

        hr(),
        h5(i18n$t("How to interpret results:")),
        tags$ul(
          tags$li(
            strong("High Composite Score: "),
            i18n$t("High Composite Score: These nodes are your top leverage points. Interventions here can have cascading effects throughout the system.")
          ),
          tags$li(
            strong("High Betweenness: "),
            i18n$t("High Betweenness: Focus on nodes that control information flow. They can block or facilitate changes.")
          ),
          tags$li(
            strong("High Eigenvector: "),
            i18n$t("High Eigenvector: Target nodes that are influential because they're connected to other influential nodes.")
          ),
          tags$li(
            strong("High PageRank: "),
            i18n$t("High PageRank: These nodes have broad influence across the network and often represent core system elements.")
          )
        ),

        hr(),
        h5(i18n$t("Using leverage points for intervention design:")),
        tags$ul(
          tags$li(
            strong("Prioritize interventions: "),
            i18n$t("Prioritize interventions: Focus resources on high-leverage nodes rather than spreading efforts thinly across many nodes.")
          ),
          tags$li(
            strong("Consider node type: "),
            i18n$t("Consider node type: Different types of nodes (Drivers, Activities, Pressures, States, Impacts, Responses) may require different intervention strategies.")
          ),
          tags$li(
            strong("Combine with loop analysis: "),
            i18n$t("Combine with loop analysis: Nodes that appear in multiple feedback loops AND have high leverage scores are especially important for system-wide change.")
          )
        )
      ),
      i18n = i18n
    )

  })
}
