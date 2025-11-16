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
#'   cld_viz_ui("cld_module")
#' )
#' }
#'
#' @export
cld_viz_ui <- function(id) {
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
          title = tagList(icon("sliders"), " Visualisation Controls"),
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = FALSE,
          class = "cld-controls-box",

          # Note: CLD is automatically generated from ISA data
          # No manual generation needed - see automatic observer below

          # Layout Controls
          h5(icon("cogs"), " Layout"),
          selectInput(
            ns("layout_type"),
            NULL,
            choices = c(
              "Hierarchical (DAPSI)" = "hierarchical",
              "Physics-based" = "physics",
              "Circular" = "circular",
              "Manual" = "manual"
            ),
            selected = "hierarchical"
          ),

          conditionalPanel(
            condition = sprintf("input['%s'] == 'hierarchical'", ns("layout_type")),
            ns = ns,
            selectInput(
              ns("hierarchy_direction"),
              "Direction:",
              choices = c(
                "Down-Up" = "DU",
                "Up-Down" = "UD",
                "Left-Right" = "LR",
                "Right-Left" = "RL"
              ),
              selected = "DU"
            ),
            sliderInput(
              ns("level_separation"),
              "Spacing:",
              min = 50,
              max = 300,
              value = 150,
              step = 10
            )
          ),

          # Highlight Controls
          hr(),
          h5(icon("lightbulb"), " Highlight"),

          div(
            style = "padding: 10px 0;",
            shinyWidgets::materialSwitch(
              inputId = ns("highlight_leverage"),
              label = "Leverage Points",
              value = FALSE,
              status = "success",
              right = TRUE
            )
          ),

          div(
            style = "padding: 10px 0;",
            selectInput(
              inputId = ns("selected_loop"),
              label = "Highlight Loop",
              choices = c("None" = "none"),
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
            # Always rebuild edges from adjacency matrices (they are the source of truth)
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
            cat(sprintf("[CLD VIZ] Rebuilt edges from adjacency matrices: %d edges\n", nrow(rv$edges)))
          } else {
            # No CLD exists yet - build from ISA data
            cat("[CLD VIZ] Building new CLD from ISA data\n")
            rv$nodes <- create_nodes_df(isa_data)
            rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)

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
          stabilizationIterationsDone = "function() {
            this.setOptions({physics: false});
          }"
        )
      
      return(vis)
    })
    
    # Store network proxy
    observe({
      rv$network_proxy <- visNetworkProxy("network")
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
          # Create updated nodes with highlighting
          # Use separate border color and width for leverage nodes
          highlighted_nodes <- data.frame(
            id = rv$nodes$id,
            color.border = if_else(rv$nodes$id %in% leverage_nodes$id, "#4CAF50", rv$nodes$color),
            color.background = rv$nodes$color,
            borderWidth = if_else(rv$nodes$id %in% leverage_nodes$id, 6, 2),
            font.size = if_else(rv$nodes$id %in% leverage_nodes$id,
                                as.integer(pmax(rv$nodes$font.size * 1.3, rv$nodes$font.size + 4)),
                                as.integer(rv$nodes$font.size)),
            stringsAsFactors = FALSE
          )

          cat("[CLD VIZ] Updating", nrow(highlighted_nodes), "nodes for highlighting\n")
          cat("[CLD VIZ] Nodes with borderWidth=6:", sum(highlighted_nodes$borderWidth == 6), "\n")
          cat("[CLD VIZ] Sample border colors:", paste(head(highlighted_nodes$color.border, 5), collapse=", "), "\n")

          visNetworkProxy("network") %>%
            visUpdateNodes(highlighted_nodes) %>%
            visSelectNodes(id = head(leverage_nodes$id, 5))

          showNotification(
            paste("Highlighting", nrow(leverage_nodes), "leverage points with thick green borders"),
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
        # Reset highlighting - restore original node styling
        reset_nodes <- data.frame(
          id = rv$nodes$id,
          color.border = rv$nodes$color,
          color.background = rv$nodes$color,
          borderWidth = 2,
          font.size = as.integer(rv$nodes$font.size),
          stringsAsFactors = FALSE
        )

        cat("[CLD VIZ] Resetting node highlighting\n")

        visNetworkProxy("network") %>%
          visUpdateNodes(reset_nodes) %>%
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
      req(rv$network_proxy, rv$edges, rv$nodes)

      cat("[CLD VIZ] Loop selector changed to:", input$selected_loop, "\n")

      if (input$selected_loop != "none") {
        project_data <- project_data_reactive()

        if (!is.null(project_data$data$analysis$loops)) {
          loop_info <- project_data$data$analysis$loops$loop_info
          all_loops <- project_data$data$analysis$loops$all_loops
          loop_idx <- as.integer(input$selected_loop)

          if (loop_idx > 0 && loop_idx <= length(all_loops)) {
            selected_loop <- all_loops[[loop_idx]]

            # Get node IDs in this specific loop
            loop_node_ids <- as.character(selected_loop)

            # Create edges for this loop (consecutive nodes in the cycle)
            loop_edges <- character(0)
            if (length(loop_node_ids) > 1) {
              for (i in 1:(length(loop_node_ids) - 1)) {
                loop_edges <- c(loop_edges, paste(loop_node_ids[i], loop_node_ids[i+1], sep = "->"))
              }
              # Close the loop: last node back to first
              loop_edges <- c(loop_edges, paste(loop_node_ids[length(loop_node_ids)], loop_node_ids[1], sep = "->"))
            }

            cat("[CLD VIZ] Highlighting loop", loop_idx, "with", length(loop_node_ids), "nodes\n")

            # Ghost non-loop nodes (make semi-transparent) and highlight loop nodes
            highlighted_nodes <- data.frame(
              id = rv$nodes$id,
              opacity = ifelse(rv$nodes$id %in% loop_node_ids, 1.0, 0.15),
              color.border = ifelse(rv$nodes$id %in% loop_node_ids, "#FF6B35", rv$nodes$color),
              color.background = rv$nodes$color,
              borderWidth = ifelse(rv$nodes$id %in% loop_node_ids, 5, 2),
              font.size = ifelse(rv$nodes$id %in% loop_node_ids, 16, 14),
              stringsAsFactors = FALSE
            )

            # Ghost non-loop edges and highlight loop edges
            edge_ids <- paste(rv$edges$from, rv$edges$to, sep = "->")
            highlighted_edges <- data.frame(
              id = 1:nrow(rv$edges),
              opacity = ifelse(edge_ids %in% loop_edges, 1.0, 0.1),
              color = ifelse(edge_ids %in% loop_edges, "#FF6B35", rv$edges$color),
              width = ifelse(edge_ids %in% loop_edges, 4, rv$edges$width),
              stringsAsFactors = FALSE
            )

            visNetworkProxy("network") %>%
              visUpdateNodes(highlighted_nodes) %>%
              visUpdateEdges(highlighted_edges)
          }
        }
      } else {
        # Reset highlighting - restore original styling and full opacity
        reset_nodes <- data.frame(
          id = rv$nodes$id,
          opacity = 1.0,
          color.border = rv$nodes$color,
          color.background = rv$nodes$color,
          borderWidth = 2,
          font.size = 14,
          stringsAsFactors = FALSE
        )

        reset_edges <- data.frame(
          id = 1:nrow(rv$edges),
          opacity = 1.0,
          color = rv$edges$color,
          width = rv$edges$width,
          stringsAsFactors = FALSE
        )

        cat("[CLD VIZ] Resetting loop highlighting\n")

        visNetworkProxy("network") %>%
          visUpdateNodes(reset_nodes) %>%
          visUpdateEdges(reset_edges)
      }
    })

    # === HELP MODAL ===
    create_help_observer(
      input, "help_cld", "cld_guide_title",
      tagList(
        h4(i18n$t("cld_guide_what_is_cld_title")),
        p(i18n$t("cld_guide_what_is_cld_p1")),
        p(i18n$t("cld_guide_what_is_cld_p2")),
        hr(),
        h4(i18n$t("cld_guide_how_to_read_title")),
        tags$ul(
          tags$li(strong(i18n$t("nodes_label")), i18n$t("cld_guide_nodes_desc")),
          tags$li(strong(i18n$t("edges_label")), i18n$t("cld_guide_edges_desc")),
          tags$li(strong(i18n$t("polarity_label")), i18n$t("cld_guide_polarity_desc"))
        ),
        hr(),
        h4(i18n$t("cld_guide_controls_title")),
        tags$ul(
          tags$li(strong(i18n$t("layout_label")), i18n$t("cld_guide_layout_desc")),
          tags$li(strong(i18n$t("highlight_leverage_label")), i18n$t("cld_guide_leverage_desc")),
          tags$li(strong(i18n$t("highlight_loop_label")), i18n$t("cld_guide_loop_desc"))
        )
      ),
      i18n
    )

  })
}
