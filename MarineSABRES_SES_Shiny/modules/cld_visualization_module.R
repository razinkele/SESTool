# modules/cld_visualization_module.R
# Main CLD visualization module using visNetwork

# ============================================================================
# UI FUNCTION
# ============================================================================

cld_viz_ui <- function(id) {
  ns <- NS(id)

  tagList(
    useShinyjs(),  # Enable shinyjs for sidebar toggle

    fluidPage(
      # Page Header with Toggle Button
      fluidRow(
        column(10,
          h2(icon("project-diagram"), " Causal Loop Diagram Visualization")
        ),
        column(2,
          actionButton(
            ns("toggle_sidebar"),
            "Toggle Controls",
            icon = icon("bars"),
            class = "btn-primary btn-sm pull-right",
            style = "margin-top: 15px;"
          )
        ),
        column(12, hr())
      ),

      # Sidebar Layout with Collapsible Sidebar
      sidebarLayout(
        # === COLLAPSIBLE SIDEBAR (LEFT) ===
        sidebarPanel(
          id = ns("sidebar"),
          width = 3,
          style = "height: 800px; overflow-y: auto; position: fixed; width: 23%;",

        # Generate CLD Button
        h4(icon("network-wired"), " CLD Generation"),
        actionButton(
          ns("generate_cld_btn"),
          "Generate CLD from ISA Data",
          icon = icon("magic"),
          class = "btn-success btn-block",
          style = "margin-bottom: 10px;"
        ),
        p(class = "text-muted small", "Click to build network from ISA exercises"),

        hr(),

        # Layout Controls
        h4(icon("cogs"), " Layout"),
        selectInput(
          ns("layout_type"),
          "Algorithm:",
          choices = c(
            "Hierarchical (DAPSI)" = "hierarchical",
            "Physics-based" = "physics",
            "Circular" = "circular",
            "Manual Arrangement" = "manual"
          ),
          selected = "hierarchical"
        ),

        # Hierarchical options
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
            "Level Spacing:",
            min = 50,
            max = 300,
            value = 150,
            step = 10
          )
        ),

        hr(),

        # Filter Controls
        h4(icon("filter"), " Filters"),
        checkboxGroupInput(
          ns("element_types"),
          "Element Types:",
          choices = DAPSIWRM_ELEMENTS,
          selected = DAPSIWRM_ELEMENTS
        ),

        checkboxGroupInput(
          ns("polarity_filter"),
          "Connection Polarity:",
          choices = c("Reinforcing (+)" = "+", "Opposing (-)" = "-"),
          selected = c("+", "-")
        ),

        checkboxGroupInput(
          ns("strength_filter"),
          "Connection Strength:",
          choices = CONNECTION_STRENGTH,
          selected = CONNECTION_STRENGTH
        ),

        sliderInput(
          ns("confidence_filter"),
          "Minimum Confidence Level:",
          min = min(CONFIDENCE_LEVELS),
          max = max(CONFIDENCE_LEVELS),
          value = min(CONFIDENCE_LEVELS),
          step = 1,
          ticks = TRUE
        ),

        hr(),

        # Search & Highlight
        h4(icon("search"), " Search"),
        textInput(
          ns("search_node"),
          "Node Name:",
          placeholder = "Type to search..."
        ),
        actionButton(
          ns("highlight_btn"),
          "Highlight",
          icon = icon("lightbulb"),
          class = "btn-primary btn-sm btn-block"
        ),
        actionButton(
          ns("clear_highlight_btn"),
          "Clear",
          icon = icon("eraser"),
          class = "btn-secondary btn-sm btn-block"
        ),

        hr(),

        # Focus Mode
        h4(icon("bullseye"), " Focus Mode"),
        selectInput(
          ns("focus_node"),
          "Select Node:",
          choices = NULL
        ),
        sliderInput(
          ns("focus_degree"),
          "Neighborhood Degree:",
          min = 1,
          max = 5,
          value = 2
        ),
        actionButton(
          ns("apply_focus_btn"),
          "Apply Focus",
          icon = icon("compress"),
          class = "btn-info btn-sm btn-block"
        ),
        actionButton(
          ns("reset_focus_btn"),
          "Reset View",
          icon = icon("expand"),
          class = "btn-secondary btn-sm btn-block"
        ),

        hr(),

        # Node Sizing
        h4(icon("chart-bar"), " Node Sizing"),
        selectInput(
          ns("node_size_metric"),
          "Size By:",
          choices = c(
            "Default" = "default",
            "Degree Centrality" = "degree",
            "Betweenness" = "betweenness",
            "Closeness" = "closeness",
            "Eigenvector" = "eigenvector"
          )
        )
      ),

      # === MAIN PANEL (RIGHT) ===
      mainPanel(
        width = 9,
        style = "margin-left: 25%;",

        # Network Visualization
        box(
          title = tagList(icon("diagram-project"), " Network Diagram"),
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          visNetworkOutput(ns("network"), height = "750px")
        )
      )
    )
    )  # Close fluidPage
  )  # Close tagList
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

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
      sidebar_visible = TRUE
    )

    # === TOGGLE SIDEBAR ===
    observeEvent(input$toggle_sidebar, {
      rv$sidebar_visible <- !rv$sidebar_visible
      shinyjs::toggle(id = "sidebar", anim = TRUE, animType = "slide")
    })

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

    # === CREATE NODES AND EDGES ===
    observe({
      req(project_data_reactive())
      
      isa_data <- project_data_reactive()$data$isa_data
      
      if (!is.null(isa_data) && length(isa_data) > 0) {
        rv$nodes <- create_nodes_df(isa_data)
        rv$edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
        
        # Update focus node choices
        if (!is.null(rv$nodes)) {
          updateSelectInput(
            session,
            "focus_node",
            choices = setNames(rv$nodes$id, rv$nodes$label)
          )
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
