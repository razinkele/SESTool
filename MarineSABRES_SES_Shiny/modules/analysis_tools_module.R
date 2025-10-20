# Analysis Tools Module
# Advanced analysis features for CLD and SES analysis
# Includes: Loop Detection, Network Metrics, BOT Analysis, Simplification

library(igraph)

# ============================================================================
# LOOP DETECTION MODULE
# ============================================================================

analysis_loops_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          div(
            h3("Feedback Loop Detection and Analysis"),
            p("Automatically identify and analyze feedback loops in your Causal Loop Diagram.")
          ),
          div(style = "margin-top: 10px;",
            actionButton(ns("help_loops"), "Loop Analysis Guide",
                        icon = icon("question-circle"),
                        class = "btn btn-info btn-lg")
          )
        )
      )
    ),

    hr(),

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
                              value = 10, min = 3, max = 20),
                  checkboxInput(ns("include_self_loops"), "Include Self-Loops", value = FALSE),
                  checkboxInput(ns("filter_trivial"), "Filter Trivial Loops", value = TRUE),
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

analysis_loops_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for loop data
    loop_data <- reactiveValues(
      loops = NULL,
      graph = NULL,
      adjacency = NULL,
      detection_complete = FALSE
    )

    # Build graph from ISA data ----
    build_graph_from_isa <- reactive({
      req(project_data_reactive())

      isa_data <- project_data_reactive()$isa_data

      if(is.null(isa_data)) return(NULL)

      # Create edge list from ISA data
      edges <- data.frame(from = character(), to = character(),
                         type = character(), polarity = character(),
                         stringsAsFactors = FALSE)

      # G&B -> ES connections
      if(!is.null(isa_data$ecosystem_services) && nrow(isa_data$ecosystem_services) > 0) {
        for(i in 1:nrow(isa_data$ecosystem_services)) {
          linked <- isa_data$ecosystem_services$LinkedGB[i]
          if(!is.na(linked) && linked != "") {
            gb_id <- gsub(":.*", "", linked)
            es_id <- isa_data$ecosystem_services$ID[i]
            edges <- rbind(edges, data.frame(
              from = gb_id, to = es_id,
              type = "GB_to_ES", polarity = "+",
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # ES -> MPF connections
      if(!is.null(isa_data$marine_processes) && nrow(isa_data$marine_processes) > 0) {
        for(i in 1:nrow(isa_data$marine_processes)) {
          linked <- isa_data$marine_processes$LinkedES[i]
          if(!is.na(linked) && linked != "") {
            es_id <- gsub(":.*", "", linked)
            mpf_id <- isa_data$marine_processes$ID[i]
            edges <- rbind(edges, data.frame(
              from = es_id, to = mpf_id,
              type = "ES_to_MPF", polarity = "+",
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # MPF -> P connections (note: pressures NEGATIVELY affect processes)
      if(!is.null(isa_data$pressures) && nrow(isa_data$pressures) > 0) {
        for(i in 1:nrow(isa_data$pressures)) {
          linked <- isa_data$pressures$LinkedMPF[i]
          if(!is.na(linked) && linked != "") {
            mpf_id <- gsub(":.*", "", linked)
            p_id <- isa_data$pressures$ID[i]
            edges <- rbind(edges, data.frame(
              from = p_id, to = mpf_id,
              type = "P_to_MPF", polarity = "-",
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # P -> A connections
      if(!is.null(isa_data$activities) && nrow(isa_data$activities) > 0) {
        for(i in 1:nrow(isa_data$activities)) {
          linked <- isa_data$activities$LinkedP[i]
          if(!is.na(linked) && linked != "") {
            p_id <- gsub(":.*", "", linked)
            a_id <- isa_data$activities$ID[i]
            edges <- rbind(edges, data.frame(
              from = a_id, to = p_id,
              type = "A_to_P", polarity = "+",
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # A -> D connections
      if(!is.null(isa_data$drivers) && nrow(isa_data$drivers) > 0) {
        for(i in 1:nrow(isa_data$drivers)) {
          linked <- isa_data$drivers$LinkedA[i]
          if(!is.na(linked) && linked != "") {
            a_id <- gsub(":.*", "", linked)
            d_id <- isa_data$drivers$ID[i]
            edges <- rbind(edges, data.frame(
              from = d_id, to = a_id,
              type = "D_to_A", polarity = "+",
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # Loop connections (D -> G&B)
      if(!is.null(isa_data$loop_connections) && nrow(isa_data$loop_connections) > 0) {
        for(i in 1:nrow(isa_data$loop_connections)) {
          d_id <- isa_data$loop_connections$DriverID[i]
          gb_id <- isa_data$loop_connections$GBID[i]
          polarity <- ifelse(isa_data$loop_connections$Effect[i] == "Positive", "+", "-")
          edges <- rbind(edges, data.frame(
            from = d_id, to = gb_id,
            type = "D_to_GB", polarity = polarity,
            stringsAsFactors = FALSE
          ))
        }
      }

      if(nrow(edges) == 0) return(NULL)

      # Create igraph object
      g <- graph_from_data_frame(edges, directed = TRUE)
      E(g)$polarity <- edges$polarity

      return(list(graph = g, edges = edges))
    })

    # Detect Loops ----
    observeEvent(input$detect_loops, {

      output$detection_status <- renderText("Detecting loops...")

      graph_data <- build_graph_from_isa()

      if(is.null(graph_data)) {
        output$detection_status <- renderText("Error: No graph data available. Please complete ISA data entry first.")
        showNotification("No ISA data found. Complete exercises first.", type = "error")
        return()
      }

      g <- graph_data$graph

      # Find all simple cycles (loops)
      # Note: This can be computationally expensive for large graphs
      withProgress(message = 'Detecting loops...', value = 0, {

        all_loops <- list()
        vertices <- V(g)

        # For each vertex, find paths back to itself
        for(i in 1:length(vertices)) {
          incProgress(1/length(vertices), detail = paste("Checking vertex", i))

          vertex <- vertices[i]

          # Find all simple paths from vertex back to itself
          paths <- tryCatch({
            all_simple_paths(g, from = vertex, to = vertex,
                            mode = "out",
                            cutoff = input$max_loop_length)
          }, error = function(e) list())

          if(length(paths) > 0) {
            for(path in paths) {
              if(length(path) >= 2) {  # At least 2 nodes for a loop
                all_loops <- c(all_loops, list(path))
              }
            }
          }
        }

        if(length(all_loops) == 0) {
          output$detection_status <- renderText("No loops detected. Try closing more feedback connections in Exercise 6.")
          showNotification("No loops found. Add loop connections in Exercise 6.", type = "warning")
          return()
        }

        # Calculate loop polarity
        loop_info <- data.frame(
          LoopID = character(),
          Length = integer(),
          Elements = character(),
          Type = character(),
          Polarity = character(),
          Description = character(),
          stringsAsFactors = FALSE
        )

        for(i in 1:length(all_loops)) {
          loop <- all_loops[[i]]
          loop_names <- names(loop)

          # Calculate polarity
          negative_count <- 0
          for(j in 1:(length(loop)-1)) {
            from_node <- loop[j]
            to_node <- loop[j+1]

            # Find edge polarity
            edge_id <- get.edge.ids(g, c(from_node, to_node))
            if(edge_id > 0) {
              polarity <- E(g)$polarity[edge_id]
              if(polarity == "-") negative_count <- negative_count + 1
            }
          }

          # Even number of negative links = Reinforcing
          # Odd number = Balancing
          loop_type <- ifelse(negative_count %% 2 == 0, "Reinforcing", "Balancing")
          loop_polarity <- ifelse(negative_count %% 2 == 0, "R", "B")

          loop_info <- rbind(loop_info, data.frame(
            LoopID = paste0("L", sprintf("%03d", i)),
            Length = length(loop) - 1,
            Elements = paste(loop_names, collapse = " → "),
            Type = loop_type,
            Polarity = loop_polarity,
            Description = paste(loop_type, "loop with", length(loop)-1, "elements"),
            stringsAsFactors = FALSE
          ))
        }

        loop_data$loops <- loop_info
        loop_data$graph <- g
        loop_data$all_loops <- all_loops
        loop_data$detection_complete <- TRUE

        output$detection_status <- renderText(
          paste("Detection complete! Found", nrow(loop_info), "loops.")
        )

        showNotification(paste("Found", nrow(loop_info), "feedback loops!"),
                        type = "message")
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

      # Create subgraph for this loop
      loop_nodes <- names(loop)

      # Prepare nodes
      nodes_df <- data.frame(
        id = loop_nodes,
        label = loop_nodes,
        color = "#2B7CE9",
        shape = "dot",
        size = 20
      )

      # Prepare edges
      edges_list <- list()
      for(i in 1:(length(loop)-1)) {
        from_node <- loop[i]
        to_node <- loop[i+1]

        edge_id <- get.edge.ids(loop_data$graph, c(from_node, to_node))
        polarity <- if(edge_id > 0) E(loop_data$graph)$polarity[edge_id] else "+"

        edges_list[[i]] <- data.frame(
          from = names(from_node),
          to = names(to_node),
          arrows = "to",
          color = ifelse(polarity == "+", "#06D6A0", "#E63946"),
          label = polarity
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
    observeEvent(input$help_loops, {
      showModal(modalDialog(
        title = "Feedback Loop Detection and Analysis Guide",
        size = "l",
        easyClose = TRUE,

        h4("What are Feedback Loops?"),
        p("Feedback loops are circular causal pathways where an element influences itself through a chain of other elements. They are fundamental to understanding system dynamics."),

        hr(),
        h5("Loop Types"),

        tags$ul(
          tags$li(strong("Reinforcing Loops (R):"), "Amplify change - exponential growth or decline"),
          tags$ul(
            tags$li("Even number of negative (-) links"),
            tags$li("Create virtuous cycles or vicious cycles"),
            tags$li("Example: More fish → More fishing → Even more fishing pressure")
          ),
          tags$li(strong("Balancing Loops (B):"), "Counteract change - seek equilibrium"),
          tags$ul(
            tags$li("Odd number of negative (-) links"),
            tags$li("Self-regulate and maintain stability"),
            tags$li("Example: Declining quality → Reduced demand → Less pressure → Quality improves")
          )
        ),

        hr(),
        h5("How to Use This Tool"),

        tags$ol(
          tags$li(strong("Complete ISA Exercise 6:"), "Create loop closure connections (Drivers → Goods/Benefits)"),
          tags$li(strong("Set Parameters:"), "Choose maximum loop length to search"),
          tags$li(strong("Detect Loops:"), "Click 'Detect Loops' to run analysis"),
          tags$li(strong("Review Results:"), "Examine reinforcing and balancing loops"),
          tags$li(strong("Analyze Details:"), "Study individual loops and their behavior"),
          tags$li(strong("Export:"), "Download results for documentation")
        ),

        hr(),
        h5("Understanding Results"),

        tags$ul(
          tags$li(strong("Loop Length:"), "Number of elements in the loop (shorter often more influential)"),
          tags$li(strong("Dominance Score:"), "Relative importance of loop in system behavior"),
          tags$li(strong("Element Participation:"), "Which elements appear in most loops (leverage points)")
        ),

        hr(),
        p(em("Feedback loops are where small changes can have large system-wide effects - identify them to find leverage points for management interventions.")),

        footer = modalButton("Close")
      ))
    })

    return(reactive({ loop_data }))
  })
}

# ============================================================================
# NETWORK METRICS MODULE (Placeholder for future implementation)
# ============================================================================

analysis_metrics_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("Network Metrics Analysis"),
    p("Advanced network centrality and connectivity analysis."),
    p(strong("Status:"), "Implementation in progress...")
  )
}

analysis_metrics_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    # Placeholder
  })
}

# ============================================================================
# BOT ANALYSIS MODULE - Behaviour Over Time
# ============================================================================

analysis_bot_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
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

      showNotification("Data point added successfully!", type = "message")
    })

    # CSV upload
    observeEvent(input$upload_csv, {
      req(input$upload_csv)

      tryCatch({
        uploaded <- read.csv(input$upload_csv$datapath)
        if(all(c("Year", "Value") %in% names(uploaded))) {
          bot_rv$timeseries_data <- uploaded[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
          showNotification("CSV data loaded successfully!", type = "message")
        } else {
          showNotification("CSV must have 'Year' and 'Value' columns!", type = "error")
        }
      }, error = function(e) {
        showNotification(paste("Error loading CSV:", e$message), type = "error")
      })
    })

    # Load ISA BOT data
    observe({
      req(input$data_input_method == "isa")
      req(project_data_reactive())

      data <- project_data_reactive()
      if(!is.null(data$data$isa_data$bot_data) && nrow(data$data$isa_data$bot_data) > 0) {
        # Assuming BOT data has Year and Value columns
        bot_data <- data$data$isa_data$bot_data
        if(all(c("Year", "Value") %in% names(bot_data))) {
          bot_rv$timeseries_data <- bot_data[, c("Year", "Value")]
          bot_rv$timeseries_data <- bot_rv$timeseries_data[order(bot_rv$timeseries_data$Year), ]
        }
      }
    })

    # Clear data
    observeEvent(input$clear_data, {
      bot_rv$timeseries_data <- data.frame(Year = integer(), Value = numeric())
      showNotification("All data cleared", type = "warning")
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
# SIMPLIFICATION TOOLS MODULE (Placeholder)
# ============================================================================

analysis_simplify_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("Model Simplification Tools"),
    p("Aggregate nodes, encapsulate sub-systems, and create simplified views."),
    p(strong("Status:"), "Implementation in progress...")
  )
}

analysis_simplify_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    # Placeholder
  })
}
