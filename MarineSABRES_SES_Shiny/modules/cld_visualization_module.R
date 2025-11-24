# modules/cld_visualization_module.R
# Main CLD visualization module using visNetwork

# ============================================================================
# UI FUNCTION
# ============================================================================

#' CLD Visualization Module UI
#'
#' Creates the user interface for the Causal Loop Diagram visualization module.
#' Includes a collapsible sidebar with controls for layout, filtering, search,
#' focus mode, and node sizing, along with a main panel for the network visualization.
#'
#' @param id Character string. Module namespace ID.
#' @param i18n Translator object for internationalization.
#'
#' @return A Shiny UI element containing the CLD visualization interface.
#'
#' @details
#' The UI features:
#' \itemize{
#'   \item Collapsible left sidebar with smooth CSS transitions
#'   \item Layout controls (hierarchical, physics-based, circular)
#'   \item Filters for element types, polarity, strength, and confidence
#'   \item Search and highlight functionality
#'   \item Focus mode to isolate nodes and their neighbors
#'   \item Node sizing based on centrality metrics
#'   \item Floating toggle button for sidebar visibility
#'   \item Frameless visNetwork canvas with legend
#' }
#'
#' @examples
#' \dontrun{
#' ui <- fluidPage(
#'   cld_viz_ui("cld_module", i18n)
#' )
#' }
#'
#' @export
cld_viz_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    tags$style(HTML("
      /* Remove all frames from visNetwork elements */
      .cld-network-container .vis-network {
        border: none !important;
        box-shadow: none !important;
        background: transparent !important;
      }
      .cld-network-container canvas {
        border: none !important;
        box-shadow: none !important;
      }
      /* Remove frame from legend */
      .cld-network-container .vis-legend {
        border: none !important;
        box-shadow: none !important;
        background: transparent !important;
        padding: 0 !important;
      }
      .cld-network-container .vis-legend-text {
        border: none !important;
        background: transparent !important;
      }
      /* Style control sections inside box */
      .cld-controls-box h5 {
        font-weight: 600;
        color: #333;
        margin-bottom: 10px;
        margin-top: 5px;
      }
      .cld-controls-box hr {
        margin-top: 20px;
        margin-bottom: 15px;
        border-top: 1px solid #e0e0e0;
      }
      .cld-controls-box .form-group {
        margin-bottom: 15px;
      }
    ")),

    fluidRow(
      column(12,
        create_module_header(
          ns = ns,
          title_key = "Causal Loop Diagram Visualization",
          subtitle_key = "Interactive network visualization of your social-ecological system",
          help_id = "help_cld",
          i18n = i18n
        )
      )
    ),

    fluidRow(
      # Left sidebar column with controls
      column(
        width = 3,

        # Collapsible controls box
        box(
          width = NULL,
          title = tagList(icon("sliders"), i18n$t("Visualisation Controls")),
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = FALSE,
          class = "cld-controls-box",

          # Note: CLD is automatically generated from ISA data
          # No manual generation needed - see automatic observer below

          # Layout Controls
          h5(icon("cogs"), i18n$t("Layout")),
          selectInput(
            ns("layout_type"),
            NULL,
            choices = setNames(
              c("hierarchical", "physics"),
              c(i18n$t("Hierarchical (DAPSI)"), i18n$t("Physics-based (Manual)"))
            ),
            selected = "hierarchical"
          ),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'hierarchical'", ns("layout_type")),
            ns = ns,
            selectInput(
              ns("hierarchy_direction"),
              i18n$t("Direction:"),
              choices = setNames(
                c("DU", "UD", "LR", "RL"),
                c(i18n$t("Down-Up"), i18n$t("Up-Down"), i18n$t("Left-Right"), i18n$t("Right-Left"))
              ),
              selected = "DU"
            ),
            sliderInput(
              ns("level_separation"),
              i18n$t("Spacing:"),
              min = 50,
              max = 300,
              value = 150,
              step = 10
            )
          ),

          # Highlight Controls
          hr(),
          h5(icon("lightbulb"), i18n$t("Highlight")),

          div(
            style = "padding: 10px 0;",
            shinyWidgets::materialSwitch(
              inputId = ns("highlight_leverage"),
              label = i18n$t("Leverage Points"),
              value = FALSE,
              status = "success",
              right = TRUE
            )
          ),

          div(
            style = "padding: 10px 0;",
            selectInput(
              inputId = ns("selected_loop"),
              label = i18n$t("Highlight Loop"),
              choices = setNames("none", i18n$t("None")),
              selected = "none",
              width = "100%"
            ),
            htmlOutput(ns("loop_tooltip"))
          )
        )  # Close box
      ),  # Close column(width = 3)

      # Main content column with network visualization
      column(
        width = 9,
        box(
          width = NULL,
          status = "primary",
          solidHeader = FALSE,
          title = NULL,
          # Network Visualization
          div(
            class = "cld-network-container",
            visNetworkOutput(ns("network"), height = "700px")
          )
        )
      )
    )  # Close fluidRow
  )  # Close tagList
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

#' CLD Visualization Module Server
#'
#' Server logic for the Causal Loop Diagram visualization module.
#' Handles network generation, filtering, layout, search, focus mode,
#' and interactive updates based on user controls.
#'
#' @param id Character string. Module namespace ID (must match UI function).
#' @param project_data_reactive Reactive expression returning project data structure
#'   containing ISA data. Expected structure:
#'   \code{list(data = list(isa_data = list(...)))}
#'
#' @return Server module (no return value, side effects only).
#'
#' @details
#' The server implements:
#' \itemize{
#'   \item CLD generation from ISA data with error handling
#'   \item Efficient network caching using ISA data signatures
#'   \item Real-time filtering by element type, polarity, strength, confidence
#'   \item Layout algorithms: hierarchical, physics-based, circular
#'   \item Node search and highlight functionality
#'   \item Focus mode to show node neighborhoods
#'   \item Dynamic node sizing based on centrality metrics
#'   \item Interactive network updates via visNetworkProxy
#' }
#'
#' Performance optimizations:
#' \itemize{
#'   \item Network only rebuilt when ISA data changes (signature-based caching)
#'   \item Metrics cached and invalidated only when network changes
#'   \item Proxy updates for filtering to avoid full re-renders
#' }
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   project_data <- reactiveVal(init_session_data())
#'   cld_viz_server("cld_module", project_data)
#' }
#' }
#'
#' @export
cld_viz_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    # === REACTIVE VALUES ===
    rv <- reactiveValues(
      nodes = NULL,
      edges = NULL,
      network_proxy = NULL,
      selected_node = NULL,
      selected_edge = NULL,
      loops = NULL,
      metrics = NULL,
      filtered_nodes = NULL,
      filtered_edges = NULL,
      isa_hash = NULL  # Cache hash to track ISA data changes
    )

    # === GENERATE CLD FROM ISA DATA ===
    # NOTE: Manual CLD generation removed - CLD is now automatically generated
    # when ISA data changes (see automatic observer below)

    # === CREATE NODES AND EDGES (WITH SMART CACHING) ===
    # Note: Reloads from project_data when ISA or CLD data changes
    # Includes leverage scores and loop data in signature to detect analysis updates
    observe({
      req(project_data_reactive())

      project_data <- project_data_reactive()
      isa_data <- project_data$data$isa_data

      if (!is.null(isa_data) && length(isa_data) > 0) {
        # Count connections from adjacency matrices
        n_connections <- 0
        if (!is.null(isa_data$adjacency_matrices)) {
          for (matrix_name in names(isa_data$adjacency_matrices)) {
            mat <- isa_data$adjacency_matrices[[matrix_name]]
            if (!is.null(mat) && is.matrix(mat)) {
              n_connections <- n_connections + sum(mat != "", na.rm = TRUE)
            }
          }
        }

        # Create signature that includes ISA data AND connection count
        isa_signature <- paste(
          nrow(isa_data$drivers %||% data.frame()),
          nrow(isa_data$activities %||% data.frame()),
          nrow(isa_data$pressures %||% data.frame()),
          nrow(isa_data$marine_processes %||% data.frame()),
          nrow(isa_data$ecosystem_services %||% data.frame()),
          nrow(isa_data$goods_benefits %||% data.frame()),
          n_connections,  # Add connection count to signature
          sep = "-"
        )

        # Add CLD state to signature (detects leverage analysis updates)
        cld_signature <- if (!is.null(project_data$data$cld$nodes)) {
          paste(
            nrow(project_data$data$cld$nodes),
            sum(!is.na(project_data$data$cld$nodes$leverage_score)),
            sep = "-"
          )
        } else {
          "no-cld"
        }

        full_signature <- paste(isa_signature, cld_signature, sep = "|")

        cat("[CLD VIZ] Current signature:", full_signature, "\n")
        cat("[CLD VIZ] Cached signature:", rv$isa_hash, "\n")

        # Only reload if signature changed
        if (is.null(rv$isa_hash) || rv$isa_hash != full_signature) {
          cat("[CLD VIZ] Signature changed - reloading CLD data\n")

          if (!is.null(project_data$data$cld$nodes) &&
              nrow(project_data$data$cld$nodes) > 0) {
            # Use existing CLD nodes (preserves leverage scores and other analysis results)
            cat("[CLD VIZ] Using existing CLD nodes with analysis results\n")
            rv$nodes <- project_data$data$cld$nodes
            # Store original colors for JavaScript-based highlighting
            if (!"originalColor" %in% names(rv$nodes)) {
              rv$nodes$originalColor <- rv$nodes$color
            }
            # Always rebuild edges from adjacency matrices (they are the source of truth)
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
            # Add IDs to edges for reliable proxy updates
            rv$edges$id <- seq_len(nrow(rv$edges))
            # Store original edge properties for JavaScript-based highlighting
            rv$edges$originalColor <- rv$edges$color
            rv$edges$originalWidth <- rv$edges$width
            cat(sprintf("[CLD VIZ] Rebuilt edges from adjacency matrices: %d edges\n", nrow(rv$edges)))
          } else {
            # No CLD exists yet - build from ISA data
            cat("[CLD VIZ] Building new CLD from ISA data\n")
            rv$nodes <- create_nodes_df(isa_data)
            # Store original colors for JavaScript-based highlighting
            rv$nodes$originalColor <- rv$nodes$color
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
            # Add IDs to edges for reliable proxy updates
            rv$edges$id <- seq_len(nrow(rv$edges))
            # Store original edge properties for JavaScript-based highlighting
            rv$edges$originalColor <- rv$edges$color
            rv$edges$originalWidth <- rv$edges$width

            # Save initial CLD to project_data (use isolate to prevent infinite loop)
            isolate({
              pd <- project_data_reactive()
              pd$data$cld$nodes <- rv$nodes
              pd$data$cld$edges <- rv$edges
              pd$last_modified <- Sys.time()
              project_data_reactive(pd)
              cat("[CLD VIZ] Saved initial CLD to project_data\n")
            })
          }

          rv$isa_hash <- full_signature
          rv$metrics <- NULL

          cat("[CLD VIZ] Loaded nodes:", nrow(rv$nodes), "\n")
          cat("[CLD VIZ] Loaded edges:", nrow(rv$edges), "\n")
          if ("leverage_score" %in% names(rv$nodes)) {
            cat("[CLD VIZ] rv$nodes has leverage scores >0:", sum(!is.na(rv$nodes$leverage_score) & rv$nodes$leverage_score > 0), "\n")

            # Update tooltips to include leverage scores
            rv$nodes <- rv$nodes %>%
              mutate(
                title = if_else(
                  !is.na(leverage_score),
                  paste0(
                    title,
                    sprintf("<br/><strong>Leverage Score:</strong> %.2f", leverage_score)
                  ),
                  title
                )
              )
            cat("[CLD VIZ] Updated tooltips with leverage scores\n")
          }

          # Update focus node choices
          if (!is.null(rv$nodes)) {
            updateSelectInput(
              session,
              "focus_node",
              choices = setNames(rv$nodes$id, rv$nodes$label)
            )
          }
        } else {
          cat("[CLD VIZ] Signature unchanged - skipping reload\n")
        }
      }
    })
    
    # === FILTER DATA ===
    filtered_data <- reactive({
      req(rv$nodes, rv$edges)

      cat("[CLD VIZ] filtered_data reactive triggered\n")
      cat("[CLD VIZ] rv$nodes:", nrow(rv$nodes), "rows\n")
      cat("[CLD VIZ] rv$edges:", nrow(rv$edges), "rows\n")
      if (nrow(rv$edges) > 0) {
        cat("[CLD VIZ] Edge columns:", paste(names(rv$edges), collapse=", "), "\n")
        cat("[CLD VIZ] First edge: from=", rv$edges$from[1], " to=", rv$edges$to[1], "\n")
      }

      # Return all nodes and edges (filter controls removed)
      filtered <- list(
        nodes = rv$nodes,
        edges = rv$edges
      )

      rv$filtered_nodes <- filtered$nodes
      rv$filtered_edges <- filtered$edges

      return(filtered)
    })

    # === APPLY NODE SIZING ===
    sized_nodes <- reactive({
      req(filtered_data())

      # Simply return filtered nodes (node sizing control removed)
      return(filtered_data()$nodes)
    })

    # === MAIN NETWORK VISUALIZATION ===
    output$network <- renderVisNetwork({
      req(sized_nodes(), filtered_data())

      nodes <- sized_nodes()
      edges <- filtered_data()$edges

      cat("[CLD VIZ] renderVisNetwork triggered\n")
      cat("[CLD VIZ] nodes:", nrow(nodes), "rows\n")
      cat("[CLD VIZ] edges:", nrow(edges), "rows\n")
      
      # Create visNetwork
      vis <- visNetwork(nodes, edges, height = "100%", width = "100%") %>%
        apply_standard_styling()
      
      # Apply layout
      if (input$layout_type == "hierarchical") {
        vis <- apply_hierarchical_layout(
          vis,
          input$hierarchy_direction,
          input$level_separation
        )
      } else if (input$layout_type == "physics") {
        vis <- apply_physics_layout(vis)
      } else if (input$layout_type == "circular") {
        vis <- apply_circular_layout(vis)
      }
      
      # Add event handlers
      vis <- vis %>%
        visEvents(
          select = sprintf(
            "function(nodes) {
              Shiny.setInputValue('%s', nodes.nodes);
              Shiny.setInputValue('%s', nodes.edges);
            }",
            session$ns("node_selected"),
            session$ns("edge_selected")
          ),
          stabilizationIterationsDone = sprintf(
            "function() {
              this.setOptions({physics: false});
              window.network_%s = this;
              console.log('[CLD VIZ] Network stabilized and stored');
            }",
            id  # Use module id to create unique window variable
          ),
          type = "once",
          stabilized = sprintf(
            "function() {
              window.network_%s = this;
              console.log('[CLD VIZ] Network stabilized and stored in window.network_%s');
            }",
            id, id
          )
        )
      
      return(vis)
    })
    
    # Store network proxy (IMPORTANT: Use session namespace in module)
    observe({
      rv$network_proxy <- visNetworkProxy(session$ns("network"))
    })

    # === HIGHLIGHT LEVERAGE POINTS ===
    observeEvent(input$highlight_leverage, {
      req(rv$network_proxy, rv$nodes)

      cat("[CLD VIZ] Highlight leverage switch triggered:", input$highlight_leverage, "\n")
      cat("[CLD VIZ] rv$nodes count:", nrow(rv$nodes), "\n")
      cat("[CLD VIZ] Has leverage_score column:", "leverage_score" %in% names(rv$nodes), "\n")
      if ("leverage_score" %in% names(rv$nodes)) {
        cat("[CLD VIZ] Nodes with non-NA leverage scores:", sum(!is.na(rv$nodes$leverage_score)), "\n")
        cat("[CLD VIZ] Nodes with leverage scores >0:", sum(!is.na(rv$nodes$leverage_score) & rv$nodes$leverage_score > 0), "\n")
      }

      if (input$highlight_leverage) {
        # Find nodes with leverage scores
        leverage_nodes <- rv$nodes %>%
          filter(!is.na(leverage_score) & leverage_score > 0) %>%
          arrange(desc(leverage_score))

        cat("[CLD VIZ] Filtered leverage nodes count:", nrow(leverage_nodes), "\n")

        if (nrow(leverage_nodes) > 0) {
          # Show only TOP 10 leverage points, hide others
          top_leverage <- head(leverage_nodes$id, 10)

          cat("[CLD VIZ] Highlighting top", length(top_leverage), "leverage points\n")

          # Use 'hidden' property instead of opacity (more reliable in visNetwork)
          highlighted_nodes <- data.frame(
            id = rv$nodes$id,
            hidden = !(rv$nodes$id %in% top_leverage),  # Hide non-leverage nodes
            borderWidth = ifelse(rv$nodes$id %in% top_leverage, 10, 2),
            font.size = ifelse(rv$nodes$id %in% top_leverage, 18, 14),
            stringsAsFactors = FALSE
          )

          # Also set color for visible nodes (leverage points)
          highlighted_nodes$color.border <- ifelse(
            rv$nodes$id %in% top_leverage,
            "#4CAF50",  # Green for leverage
            "#2B7CE9"   # Default blue
          )
          highlighted_nodes$color.background <- rv$nodes$color

          # Hide edges not connected to leverage points
          highlighted_edges <- data.frame(
            id = seq_len(nrow(rv$edges)),
            hidden = !(rv$edges$from %in% top_leverage | rv$edges$to %in% top_leverage),
            stringsAsFactors = FALSE
          )

          cat("[CLD VIZ] Hiding", sum(highlighted_nodes$hidden), "nodes,",
              "showing", sum(!highlighted_nodes$hidden), "leverage points\n")
          cat("[CLD VIZ] Top leverage nodes:", paste(top_leverage, collapse=", "), "\n")

          # IMPORTANT: Use session namespace for proxy in module context
          # DON'T use visSelectNodes - it triggers highlightNearest which can interfere with custom highlighting
          visNetworkProxy(session$ns("network")) %>%
            visUpdateNodes(highlighted_nodes) %>%
            visUpdateEdges(highlighted_edges) %>%
            visFit()  # Fit view to visible nodes

          showNotification(
            paste("Showing top", length(top_leverage), "leverage points only"),
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            "No leverage scores found. Run Leverage Point Analysis first.",
            type = "warning"
          )
          # Reset switch
          updateMaterialSwitch(session, "highlight_leverage", value = FALSE)
        }
      } else {
        # Reset highlighting - show all nodes/edges
        reset_nodes <- data.frame(
          id = rv$nodes$id,
          hidden = FALSE,  # Show all nodes
          color.border = "#2B7CE9",  # Default blue border
          color.background = rv$nodes$color,
          borderWidth = 2,
          font.size = as.integer(rv$nodes$font.size),
          stringsAsFactors = FALSE
        )

        reset_edges <- data.frame(
          id = seq_len(nrow(rv$edges)),
          hidden = FALSE,  # Show all edges
          stringsAsFactors = FALSE
        )

        cat("[CLD VIZ] Resetting leverage highlighting - showing all nodes\n")

        # IMPORTANT: Use session namespace for proxy in module context
        visNetworkProxy(session$ns("network")) %>%
          visUpdateNodes(reset_nodes) %>%
          visUpdateEdges(reset_edges) %>%
          visUnselectAll()
      }
    })

    # === UPDATE LOOP SELECTOR DROPDOWN ===
    observe({
      project_data <- project_data_reactive()

      if (!is.null(project_data$data$analysis$loops) &&
          !is.null(project_data$data$analysis$loops$loop_info)) {
        loop_info <- project_data$data$analysis$loops$loop_info

        if (nrow(loop_info) > 0) {
          # Create choices: Loop 1, Loop 2, etc.
          choices <- c("None" = "none", setNames(1:nrow(loop_info), paste("Loop", 1:nrow(loop_info))))
          updateSelectInput(session, "selected_loop", choices = choices)

          cat("[CLD VIZ] Updated loop selector with", nrow(loop_info), "loops\n")
        }
      }
    })

    # === DISPLAY LOOP TOOLTIP ===
    output$loop_tooltip <- renderUI({
      req(input$selected_loop)

      if (input$selected_loop == "none") {
        return(NULL)
      }

      project_data <- project_data_reactive()
      if (!is.null(project_data$data$analysis$loops$loop_info)) {
        loop_info <- project_data$data$analysis$loops$loop_info
        loop_idx <- as.integer(input$selected_loop)

        if (loop_idx > 0 && loop_idx <= nrow(loop_info)) {
          loop_row <- loop_info[loop_idx, ]

          div(
            style = "background-color: #f0f8ff; padding: 10px; margin-top: 5px; border-radius: 4px; border-left: 4px solid #2196F3; font-size: 12px;",
            tags$strong(paste0(loop_row$Type, " Loop")),
            tags$br(),
            tags$small(
              style = "color: #666;",
              paste0("Length: ", loop_row$Length, " elements"),
              tags$br(),
              loop_row$Elements
            )
          )
        }
      }
    })

    # === HIGHLIGHT SELECTED LOOP ===
    observeEvent(input$selected_loop, {
      req(rv$edges, rv$nodes)

      cat("[CLD VIZ] Loop selector changed to:", input$selected_loop, "\n")

      if (input$selected_loop != "none") {
        project_data <- project_data_reactive()

        if (!is.null(project_data$data$analysis$loops)) {
          loop_info <- project_data$data$analysis$loops$loop_info
          all_loops <- project_data$data$analysis$loops$all_loops
          loop_idx <- as.integer(input$selected_loop)

          if (loop_idx > 0 && loop_idx <= length(all_loops)) {
            selected_loop <- all_loops[[loop_idx]]

            # IMPORTANT: selected_loop contains node INDICES (1, 2, 3, ...), not IDs
            # Need to convert to actual node IDs (ES_1, P_1, MPF_2, etc.)
            loop_node_indices <- as.integer(selected_loop)

            # Convert indices to actual node IDs
            loop_node_ids <- rv$nodes$id[loop_node_indices]

            cat("[CLD VIZ] Loop indices from analysis:", paste(loop_node_indices, collapse=", "), "\n")
            cat("[CLD VIZ] Converted to node IDs:", paste(loop_node_ids, collapse=", "), "\n")
            cat("[CLD VIZ] Highlighting loop", loop_idx, "with", length(loop_node_ids), "nodes\n")

            # Use JavaScript to highlight loop (exact same approach as app_loops.R)
            runjs(sprintf("
              window.selectedLoopNodes_%s = %s;
              console.log('[CLD VIZ] Selected loop nodes:', window.selectedLoopNodes_%s);

              if (window.network_%s && window.network_%s.body) {
                var allNodes = window.network_%s.body.data.nodes.get();
                var allEdges = window.network_%s.body.data.edges.get();

                // Highlight selected loop nodes
                allNodes.forEach(function(node) {
                  if (window.selectedLoopNodes_%s.includes(node.id)) {
                    // Loop node - restore original appearance with thick black border
                    node.color = node.originalColor;
                    node.opacity = 1.0;
                    node.borderWidth = 3;
                    node.borderColor = '#000000';
                  } else {
                    // Non-loop node - fade using opacity (works for both color and image nodes)
                    node.color = 'rgba(200,200,200,0.3)';
                    node.opacity = 0.3;
                    node.borderWidth = 1;
                  }
                });

                // Highlight loop edges
                allEdges.forEach(function(edge) {
                  var isLoopEdge = false;
                  for (var i = 0; i < window.selectedLoopNodes_%s.length; i++) {
                    var currentNode = window.selectedLoopNodes_%s[i];
                    var nextNode = window.selectedLoopNodes_%s[(i + 1) %% window.selectedLoopNodes_%s.length];
                    if (edge.from === currentNode && edge.to === nextNode) {
                      isLoopEdge = true;
                      break;
                    }
                  }

                  if (isLoopEdge) {
                    // Keep original edge color and make loop edges 5x thicker for visibility
                    edge.color = edge.originalColor;
                    edge.width = (edge.originalWidth || 1) * 5;
                  } else {
                    edge.color = 'rgba(200,200,200,0.3)';
                    edge.width = 1;
                  }
                });

                window.network_%s.body.data.nodes.update(allNodes);
                window.network_%s.body.data.edges.update(allEdges);
              }
            ", id, jsonlite::toJSON(loop_node_ids), id, id, id, id, id, id, id, id, id, id, id, id))
          }
        }
      } else {
        # Clear highlighting when no loop is selected (exact same as app_loops.R)
        cat("[CLD VIZ] Resetting loop highlighting\n")

        runjs(sprintf("
          window.selectedLoopNodes_%s = [];
          if (window.network_%s && window.network_%s.body) {
            var allNodes = window.network_%s.body.data.nodes.get();
            var allEdges = window.network_%s.body.data.edges.get();

            allNodes.forEach(function(node) {
              node.color = node.originalColor;
              node.opacity = 1.0;
              node.borderWidth = 1;
            });

            allEdges.forEach(function(edge) {
              edge.color = edge.originalColor;
              edge.width = edge.originalWidth || 1;
            });

            window.network_%s.body.data.nodes.update(allNodes);
            window.network_%s.body.data.edges.update(allEdges);
          }
        ", id, id, id, id, id, id, id))
      }
    })

    # === HELP MODAL ===
    create_help_observer(
      input, "help_cld", "Causal Loop Diagram Guide",
      tagList(
        h4(i18n$t("What is a Causal Loop Diagram?")),
        p(i18n$t("A Causal Loop Diagram (CLD) is a visual representation of how different elements in your social-ecological system are connected through cause-and-effect relationships.")),
        p(i18n$t("It helps you understand feedback loops, leverage points, and potential intervention strategies.")),
        hr(),
        h4(i18n$t("How to Read the Diagram")),
        tags$ul(
          tags$li(strong(i18n$t("Nodes:")), i18n$t(" Represent elements in your system (drivers, activities, pressures, states, impacts, welfare, responses)")),
          tags$li(strong(i18n$t("Edges:")), i18n$t(" Show causal connections between elements. Arrow direction indicates the direction of influence")),
          tags$li(i18n$t("Polarity: + means the elements change in the same direction, - means they change in opposite directions"))
        ),
        hr(),
        h4(i18n$t("Visualization Controls")),
        tags$ul(
          tags$li(strong(i18n$t("Layout:")), i18n$t(" Choose between hierarchical, physics-based, or circular layouts to better understand different aspects of your system")),
          tags$li(strong(i18n$t("Highlight Leverage Points:")), i18n$t(" Toggle to highlight the most influential nodes where interventions could have the greatest impact")),
          tags$li(strong(i18n$t("Highlight Loop:")), i18n$t(" Select a feedback loop to visualize circular patterns of influence in your system"))
        )
      ),
      i18n
    )

  })
}
