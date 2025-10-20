# modules/cld_visualization_module.R
# Main CLD visualization module using visNetwork

# ============================================================================
# UI FUNCTION
# ============================================================================

cld_viz_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(12,
        h2(icon("project-diagram"), " Causal Loop Diagram Visualization"),
        p("Interactive exploration of your Social-Ecological System"),
        hr()
      )
    ),
    
    fluidRow(
      # === CONTROL PANEL (LEFT) ===
      column(3,
        wellPanel(
          style = "height: 700px; overflow-y: auto;",

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
        )
      ),
      
      # === MAIN VISUALIZATION (CENTER) ===
      column(9,
        # Info Boxes
        fluidRow(
          valueBoxOutput(ns("total_nodes"), width = 3),
          valueBoxOutput(ns("total_edges"), width = 3),
          valueBoxOutput(ns("reinforcing_loops"), width = 3),
          valueBoxOutput(ns("balancing_loops"), width = 3)
        ),
        
        # Network Visualization
        box(
          title = "Network Diagram",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          height = "700px",
          visNetworkOutput(ns("network"), height = "650px")
        ),
        
        # Selected Element Info
        fluidRow(
          column(6,
            box(
              title = "Selected Node",
              status = "info",
              width = 12,
              verbatimTextOutput(ns("node_info"))
            )
          ),
          column(6,
            box(
              title = "Selected Connection",
              status = "info",
              width = 12,
              verbatimTextOutput(ns("edge_info"))
            )
          )
        )
      )
    ),
    
    # === LOOP ANALYSIS SECTION ===
    fluidRow(
      column(12,
        box(
          title = tagList(icon("refresh"), " Loop Analysis"),
          status = "warning",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = TRUE,
          width = 12,
          
          fluidRow(
            column(3,
              numericInput(
                ns("max_loop_length"),
                "Maximum Loop Length:",
                value = 8,
                min = 3,
                max = 15
              ),
              actionButton(
                ns("detect_loops_btn"),
                "Detect Loops",
                icon = icon("sync"),
                class = "btn-warning btn-block"
              ),
              br(),
              downloadButton(
                ns("download_loops"),
                "Export Loops",
                class = "btn-secondary btn-block"
              )
            ),
            column(9,
              DTOutput(ns("loops_table"))
            )
          ),
          
          hr(),
          
          fluidRow(
            column(12,
              h4("Selected Loop Visualization"),
              visNetworkOutput(ns("loop_network"), height = "400px")
            )
          )
        )
      )
    )
  )
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
      filtered_edges = NULL
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
    
    # === INFO BOXES ===
    output$total_nodes <- renderValueBox({
      n <- nrow(filtered_data()$nodes %||% data.frame())
      valueBox(
        n,
        "Total Nodes",
        icon = icon("circle"),
        color = "blue"
      )
    })
    
    output$total_edges <- renderValueBox({
      n <- nrow(filtered_data()$edges %||% data.frame())
      valueBox(
        n,
        "Connections",
        icon = icon("arrow-right"),
        color = "green"
      )
    })
    
    output$reinforcing_loops <- renderValueBox({
      n <- sum(rv$loops$type == "R", na.rm = TRUE)
      valueBox(
        n,
        "Reinforcing",
        icon = icon("plus-circle"),
        color = "orange"
      )
    })
    
    output$balancing_loops <- renderValueBox({
      n <- sum(rv$loops$type == "B", na.rm = TRUE)
      valueBox(
        n,
        "Balancing",
        icon = icon("minus-circle"),
        color = "purple"
      )
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
    
    # === DISPLAY SELECTED NODE INFO ===
    output$node_info <- renderPrint({
      req(input$node_selected, rv$nodes, rv$edges)
      
      if (length(input$node_selected) == 0) {
        cat("No node selected.\nClick on a node to see details.")
        return()
      }
      
      selected_id <- input$node_selected[1]
      node_data <- get_node(rv$nodes, selected_id)
      
      if (is.null(node_data)) return()
      
      cat("=== NODE INFORMATION ===\n\n")
      cat("Name:", node_data$label, "\n")
      cat("Type:", node_data$group, "\n")
      cat("Indicator:", node_data$indicator, "\n")
      cat("Hierarchical Level:", node_data$level, "\n\n")
      
      cat("=== CONNECTIVITY ===\n\n")
      
      # Calculate degrees
      in_edges <- get_connected_edges(rv$edges, selected_id, "in")
      out_edges <- get_connected_edges(rv$edges, selected_id, "out")
      
      cat("Incoming connections:", nrow(in_edges), "\n")
      cat("Outgoing connections:", nrow(out_edges), "\n")
      cat("Total degree:", nrow(in_edges) + nrow(out_edges), "\n")
      
      # Show connected nodes
      if (nrow(in_edges) > 0) {
        cat("\nInfluenced by:\n")
        in_nodes <- rv$nodes %>% filter(id %in% in_edges$from)
        for (i in 1:min(5, nrow(in_nodes))) {
          cat("  -", in_nodes$label[i], "\n")
        }
        if (nrow(in_nodes) > 5) cat("  ... and", nrow(in_nodes) - 5, "more\n")
      }
      
      if (nrow(out_edges) > 0) {
        cat("\nInfluences:\n")
        out_nodes <- rv$nodes %>% filter(id %in% out_edges$to)
        for (i in 1:min(5, nrow(out_nodes))) {
          cat("  -", out_nodes$label[i], "\n")
        }
        if (nrow(out_nodes) > 5) cat("  ... and", nrow(out_nodes) - 5, "more\n")
      }
    })
    
    # === DISPLAY SELECTED EDGE INFO ===
    output$edge_info <- renderPrint({
      req(input$edge_selected, rv$edges, rv$nodes)
      
      if (length(input$edge_selected) == 0) {
        cat("No connection selected.\nClick on an arrow to see details.")
        return()
      }
      
      # visNetwork returns 0-based index
      edge_idx <- input$edge_selected[1] + 1
      
      if (edge_idx > nrow(rv$edges)) return()
      
      edge_data <- rv$edges[edge_idx, ]
      
      from_node <- get_node(rv$nodes, edge_data$from)
      to_node <- get_node(rv$nodes, edge_data$to)
      
      cat("=== CONNECTION INFORMATION ===\n\n")
      cat("From:", from_node$label, "\n")
      cat("  Type:", from_node$group, "\n\n")
      cat("To:", to_node$label, "\n")
      cat("  Type:", to_node$group, "\n\n")
      cat("Polarity:", edge_data$polarity, 
          ifelse(edge_data$polarity == "+", "(Reinforcing)", "(Opposing)"), "\n")
      cat("Strength:", edge_data$strength, "\n\n")
      
      cat("Interpretation:\n")
      if (edge_data$polarity == "+") {
        cat("An increase in", from_node$label, "\n")
        cat("leads to an increase in", to_node$label)
      } else {
        cat("An increase in", from_node$label, "\n")
        cat("leads to a decrease in", to_node$label)
      }
    })
    
    # === LOOP DETECTION ===
    observeEvent(input$detect_loops_btn, {
      req(rv$nodes, rv$edges)
      
      withProgress(message = "Detecting feedback loops...", value = 0, {
        
        # Find all cycles
        g <- create_igraph_from_data(rv$nodes, rv$edges)
        cycles <- find_all_cycles(rv$nodes, rv$edges, input$max_loop_length)
        
        incProgress(0.5, detail = "Processing loops...")
        
        # Process into loops dataframe
        rv$loops <- process_cycles_to_loops(cycles, rv$nodes, rv$edges, g)
        
        incProgress(1)
      })
      
      n_loops <- nrow(rv$loops)
      n_reinforcing <- sum(rv$loops$type == "R")
      n_balancing <- sum(rv$loops$type == "B")
      
      showNotification(
        paste0(
          "Detected ", n_loops, " loops:\n",
          n_reinforcing, " reinforcing, ",
          n_balancing, " balancing"
        ),
        type = "message",
        duration = 5
      )
    })
    
    # === DISPLAY LOOPS TABLE ===
    output$loops_table <- renderDT({
      req(rv$loops)
      
      datatable(
        rv$loops %>% select(loop_id, name, type, length, elements),
        selection = "single",
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'frtip'
        ),
        rownames = FALSE
      ) %>%
        formatStyle(
          'type',
          backgroundColor = styleEqual(
            c("R", "B"),
            c("#FFE5CC", "#CCE5FF")
          )
        )
    })
    
    # === VISUALIZE SELECTED LOOP ===
    observeEvent(input$loops_table_rows_selected, {
      req(rv$loops, input$loops_table_rows_selected)
      
      selected_loop <- rv$loops[input$loops_table_rows_selected, ]
      loop_node_ids <- strsplit(selected_loop$node_ids, ",")[[1]]
      
      # Filter to loop
      loop_nodes <- rv$nodes %>% filter(id %in% loop_node_ids)
      loop_edges <- rv$edges %>%
        filter(from %in% loop_node_ids, to %in% loop_node_ids)
      
      # Highlight loop edges
      loop_color <- ifelse(selected_loop$type == "R", "#FF6B35", "#4ECDC4")
      loop_edges$color <- loop_color
      loop_edges$width <- 5
      
      output$loop_network <- renderVisNetwork({
        visNetwork(loop_nodes, loop_edges, height = "100%") %>%
          visIgraphLayout(layout = "layout_in_circle") %>%
          apply_standard_styling() %>%
          visOptions(
            highlightNearest = FALSE
          ) %>%
          visNodes(size = 35, font = list(size = 14))
      })
    })
    
    # === DOWNLOAD LOOPS ===
    output$download_loops <- downloadHandler(
      filename = function() {
        paste0("Feedback_Loops_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(rv$loops)
        write.csv(rv$loops, file, row.names = FALSE)
      }
    )
    
  })
}
