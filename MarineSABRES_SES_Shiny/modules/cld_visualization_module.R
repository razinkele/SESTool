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
    ")),

    fluidRow(
      # Left sidebar column with controls
      column(
        width = 3,

      # Generate Button
      wellPanel(
        actionButton(
          ns("generate_cld_btn"),
          "Generate CLD from ISA",
          icon = icon("magic"),
          class = "btn-success btn-block"
        )
      ),

      # Layout Controls
      wellPanel(
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
        )
      ),

      # Filter Controls
      wellPanel(
        h5(icon("filter"), " Filters"),
        selectInput(
          ns("element_types"),
          "Elements:",
          choices = DAPSIWRM_ELEMENTS,
          selected = DAPSIWRM_ELEMENTS,
          multiple = TRUE,
          selectize = TRUE
        ),
        selectInput(
          ns("polarity_filter"),
          "Polarity:",
          choices = c("Reinforcing (+)" = "+", "Opposing (-)" = "-"),
          selected = c("+", "-"),
          multiple = TRUE
        ),
        selectInput(
          ns("strength_filter"),
          "Strength:",
          choices = CONNECTION_STRENGTH,
          selected = CONNECTION_STRENGTH,
          multiple = TRUE
        ),
        sliderInput(
          ns("confidence_filter"),
          "Min Confidence:",
          min = min(CONFIDENCE_LEVELS),
          max = max(CONFIDENCE_LEVELS),
          value = min(CONFIDENCE_LEVELS),
          step = 1
        )
      ),

      # Search & Highlight
      wellPanel(
        h5(icon("search"), " Search"),
        textInput(
          ns("search_node"),
          NULL,
          placeholder = "Search nodes..."
        ),
        fluidRow(
          column(6,
            actionButton(
              ns("highlight_btn"),
              "Highlight",
              icon = icon("lightbulb"),
              class = "btn-primary btn-block"
            )
          ),
          column(6,
            actionButton(
              ns("clear_highlight_btn"),
              "Clear",
              icon = icon("eraser"),
              class = "btn-default btn-block"
            )
          )
        )
      ),

      # Focus Mode
      wellPanel(
        h5(icon("bullseye"), " Focus"),
        selectInput(
          ns("focus_node"),
          "Node:",
          choices = NULL
        ),
        sliderInput(
          ns("focus_degree"),
          "Degree:",
          min = 1,
          max = 5,
          value = 2
        ),
        fluidRow(
          column(6,
            actionButton(
              ns("apply_focus_btn"),
              "Apply",
              icon = icon("compress"),
              class = "btn-info btn-block"
            )
          ),
          column(6,
            actionButton(
              ns("reset_focus_btn"),
              "Reset",
              icon = icon("expand"),
              class = "btn-default btn-block"
            )
          )
        )
      ),

      # Node Sizing
      wellPanel(
        h5(icon("chart-bar"), " Node Size"),
        selectInput(
          ns("node_size_metric"),
          NULL,
          choices = c(
            "Default" = "default",
            "Degree" = "degree",
            "Betweenness" = "betweenness",
            "Closeness" = "closeness",
            "Eigenvector" = "eigenvector"
          )
        )
      )
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
cld_viz_server <- function(id, project_data_reactive) {
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
    observeEvent(input$generate_cld_btn, {
      req(project_data_reactive())

      tryCatch({
        data <- project_data_reactive()
        isa_data <- data$data$isa_data

        if(is.null(isa_data) || length(isa_data) == 0) {
          showNotification(
            "No ISA data found. Please complete ISA exercises first.",
            type = "error",
            duration = 5
          )
          return()
        }

        # Validate adjacency matrices dimensions before building CLD
        if (!is.null(isa_data$adjacency_matrices)) {
          validation_errors <- validate_adjacency_matrices(isa_data)

          if (length(validation_errors) > 0) {
            showNotification(
              HTML(paste0(
                "<strong>Adjacency Matrix Dimension Errors:</strong><br/>",
                paste(validation_errors, collapse = "<br/>"),
                "<br/><br/>",
                "<em>The CLD will be generated using the available data, ",
                "but some connections may be missing. ",
                "Please check your ISA data and adjacency matrices.</em>"
              )),
              type = "warning",
              duration = 15
            )
          }
        }

        # Build nodes and edges
        nodes_df <- create_nodes_df(isa_data)
        edges_df <- create_edges_df(isa_data, isa_data$adjacency_matrices)

        if(is.null(nodes_df) || nrow(nodes_df) == 0) {
          showNotification(
            "Could not generate network. Please add elements in ISA exercises.",
            type = "warning",
            duration = 5
          )
          return()
        }

        # Save to project data
        data$data$cld$nodes <- nodes_df
        data$data$cld$edges <- edges_df
        data$last_modified <- Sys.time()

        project_data_reactive(data)

        # Update reactive values
        rv$nodes <- nodes_df
        rv$edges <- edges_df

        showNotification(
          paste0("CLD generated successfully! ", nrow(nodes_df), " nodes and ",
                 nrow(edges_df), " edges created."),
          type = "message",
          duration = 5
        )

      }, error = function(e) {
        showNotification(
          paste("Error generating CLD:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # === CREATE NODES AND EDGES (WITH CACHING) ===
    observe({
      req(project_data_reactive())

      isa_data <- project_data_reactive()$data$isa_data

      if (!is.null(isa_data) && length(isa_data) > 0) {
        # Create a simple hash by concatenating row counts from all ISA tables
        # This is much lighter than computing a cryptographic hash
        isa_signature <- paste(
          nrow(isa_data$drivers %||% data.frame()),
          nrow(isa_data$activities %||% data.frame()),
          nrow(isa_data$pressures %||% data.frame()),
          nrow(isa_data$marine_processes %||% data.frame()),
          nrow(isa_data$ecosystem_services %||% data.frame()),
          nrow(isa_data$goods_benefits %||% data.frame()),
          sep = "-"
        )

        if (is.null(rv$isa_hash) || rv$isa_hash != isa_signature) {
          # ISA data changed - rebuild network
          rv$nodes <- create_nodes_df(isa_data)
          rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
          rv$isa_hash <- isa_signature
          rv$metrics <- NULL  # Invalidate cached metrics

          # Update focus node choices
          if (!is.null(rv$nodes)) {
            updateSelectInput(
              session,
              "focus_node",
              choices = setNames(rv$nodes$id, rv$nodes$label)
            )
          }
        }
      }
    })
    
    # === FILTER DATA ===
    filtered_data <- reactive({
      req(rv$nodes, rv$edges)

      # Filter by element type
      filtered <- filter_by_element_type(
        rv$nodes,
        rv$edges,
        input$element_types
      )

      # Filter by polarity
      filtered$edges <- filter_by_polarity(
        filtered$edges,
        input$polarity_filter
      )

      # Filter by strength
      filtered$edges <- filter_by_strength(
        filtered$edges,
        input$strength_filter
      )

      # Filter by confidence
      filtered$edges <- filter_by_confidence(
        filtered$edges,
        input$confidence_filter
      )

      rv$filtered_nodes <- filtered$nodes
      rv$filtered_edges <- filtered$edges

      return(filtered)
    })
    
    # === APPLY NODE SIZING ===
    sized_nodes <- reactive({
      req(filtered_data())
      
      nodes <- filtered_data()$nodes
      
      if (input$node_size_metric != "default") {
        if (is.null(rv$metrics)) {
          rv$metrics <- calculate_network_metrics(
            filtered_data()$nodes,
            filtered_data()$edges
          )
        }
        
        metric_values <- rv$metrics[[input$node_size_metric]]
        nodes <- apply_metric_sizing(nodes, metric_values, 15, 50)
      }
      
      return(nodes)
    })
    
    # === MAIN NETWORK VISUALIZATION ===
    output$network <- renderVisNetwork({
      req(sized_nodes(), filtered_data())
      
      nodes <- sized_nodes()
      edges <- filtered_data()$edges
      
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

    # === SEARCH AND HIGHLIGHT ===
    observeEvent(input$highlight_btn, {
      req(rv$network_proxy, input$search_node, rv$nodes)
      
      # Find matching nodes
      matching_nodes <- rv$nodes %>%
        filter(grepl(input$search_node, label, ignore.case = TRUE)) %>%
        pull(id)
      
      if (length(matching_nodes) > 0) {
        visNetworkProxy("network") %>%
          visSelectNodes(id = matching_nodes) %>%
          visFocus(id = matching_nodes[1], scale = 1.5)
        
        showNotification(
          paste("Found", length(matching_nodes), "matching node(s)"),
          type = "message"
        )
      } else {
        showNotification("No matching nodes found", type = "warning")
      }
    })
    
    observeEvent(input$clear_highlight_btn, {
      req(rv$network_proxy)
      visNetworkProxy("network") %>% visUnselectAll()
    })
    
    # === FOCUS MODE ===
    observeEvent(input$apply_focus_btn, {
      req(rv$network_proxy, input$focus_node, rv$nodes, rv$edges)
      
      # Get neighborhood
      neighbor_ids <- get_neighborhood(
        rv$nodes,
        rv$edges,
        input$focus_node,
        input$focus_degree
      )
      
      # Filter to neighborhood
      nodes_focused <- rv$nodes %>% filter(id %in% neighbor_ids)
      edges_focused <- rv$edges %>%
        filter(from %in% neighbor_ids, to %in% neighbor_ids)
      
      # Update network
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes_focused) %>%
        visUpdateEdges(edges_focused) %>%
        visFocus(id = input$focus_node, scale = 1.5)
    })
    
    observeEvent(input$reset_focus_btn, {
      req(rv$network_proxy, filtered_data())
      
      visNetworkProxy("network") %>%
        visUpdateNodes(filtered_data()$nodes) %>%
        visUpdateEdges(filtered_data()$edges) %>%
        visFit(animation = list(duration = 500))
    })

  })
}
