# app.R - SES Tool with Intelligent Group Assignment
# Modified to work with utils.R AI-powered node classification

# List of required packages
required_packages <- c("shiny", "shinyBS", "visNetwork", "readsdr", "readr", "igraph", 
                      "dplyr", "htmlwidgets", "colourpicker", "shinyjs", "DT", 
                      "markdown", "stringdist")

# Function to check and install packages
install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cat(paste0("Installing package: ", package, "\n"))
    install.packages(package, dependencies = TRUE)
  } else {
    cat(paste0("Package already installed: ", package, "\n"))
  }
}

# Check and install missing packages
cat("Checking and installing required packages...\n")
sapply(required_packages, install_if_missing)

# Load the packages
cat("\nLoading required packages...\n")
sapply(required_packages, library, character.only = TRUE)

cat("\nAll required packages are installed and loaded.\n")

# Include the R file containing the R6 class SES
source("classes.R")

# Include the intelligent group assignment utilities
if (file.exists("utils.R")) {
  source("utils.R")
  cat("✅ Intelligent group assignment system loaded successfully.\n")
  UTILS_AVAILABLE <- TRUE
} else {
  warning("⚠️ utils.R not found - intelligent assignment will not be available")
  UTILS_AVAILABLE <- FALSE
}

# Define UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; }
      .container-fluid { padding-top: 20px; }
      .well { background-color: #f8f9fa; border: none; box-shadow: none; }
      .btn { border-radius: 0; }
      .left-align { float: left;}
      .form-control { border-radius: 0; }
      .nav-tabs { border-bottom: 2px solid #dee2e6; }
      .nav-tabs > li.active > a, .nav-tabs > li.active > a:focus, .nav-tabs > li.active > a:hover {
        border: none;
        border-bottom: 2px solid #007bff;
      }
      .network-container { border: 1px solid #dee2e6; border-radius: 4px; padding: 15px; }
      #colorPickers .shiny-input-container { display: inline-block; margin-right: 10px; margin-bottom: 10px; }
      
      /* Enhanced styling */
      .status-box { 
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 15px; 
        margin: 10px 0; 
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      }
      
      .debug-info { 
        background-color: #f8f9fa; 
        border: 1px solid #dee2e6; 
        padding: 10px; 
        margin: 10px 0; 
        border-radius: 4px; 
        font-family: 'Courier New', monospace; 
        font-size: 12px;
        max-height: 200px;
        overflow-y: auto;
      }
      
      .intelligent-section {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        padding: 15px;
        border-radius: 8px;
        margin: 10px 0;
        box-shadow: 0 3px 5px rgba(0,0,0,0.1);
      }
      
      .intelligent-section .btn {
        background: rgba(255,255,255,0.9);
        color: #333;
        border: none;
        font-weight: bold;
        margin: 3px;
      }
      
      .intelligent-section .btn:hover {
        background: white;
        transform: translateY(-1px);
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
      }
      
      .section-header {
        color: #2c3e50; 
        border-bottom: 2px solid #3498db; 
        padding-bottom: 5px;
        margin-bottom: 15px;
      }
      
      .ai-badge {
        background: #2ecc71; 
        color: white; 
        padding: 4px 8px; 
        border-radius: 12px; 
        font-size: 10px;
        font-weight: bold;
      }
      
      .basic-badge {
        background: #e74c3c; 
        color: white; 
        padding: 4px 8px; 
        border-radius: 12px; 
        font-size: 10px;
        font-weight: bold;
      }
    "))
  ),
  
  titlePanel(div(
    style = "display: flex; align-items: center; gap: 10px; margin-bottom: 20px;",
    img(
      src = "https://raw.githubusercontent.com/razinkele/SESTool/main/images/01%20marinesabres_logo_transparent.png",
      height = "70px",
      style = "margin-left: 3px;"
    ),
    div(
      h2("SES Tool", style = "margin: 0; color: #2c3e50;"),
      h5("with AI-Powered Group Assignment", style = "margin: 0; color: #7f8c8d; font-style: italic;")
    ),
    div(
      style = "margin-left: auto;",
      if (UTILS_AVAILABLE) {
        tags$span("🧠 AI Ready", class = "ai-badge")
      } else {
        tags$span("⚠️ Basic Mode", class = "basic-badge")
      }
    )
  )),
  
  # Sidebar ----
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      # File Upload Section
      h4("📁 Data Input", class = "section-header"),
      
      # Dropdown list for selecting file format
      selectInput("fileType", "Select File Format:",
        choices = c("XLSX" = "xlsx", "CSV" = "csv", "GraphML" = "graphml")
      ),
      
      # Dynamic file upload button based on dropdown selection
      uiOutput("dynamicUploadButton"),
      
      # Data Configuration
      h4("⚙️ Configuration", class = "section-header"),
      
      actionButton("change_df", "Change groups & links", 
                  title = "Group and links width field selection", 
                  class = "btn-primary btn-block"),
      
      # dropdown menu to select column for width/strength
      uiOutput("strength"),
      # dropdown menu to select column for group
      uiOutput("group"),
      
      hr(),
      
      # Network Creation
      h4("🌐 Network Creation", class = "section-header"),
      
      actionButton("createNetwork", "Create Network", 
                  title = "Create network from the uploaded links table", 
                  class = "btn-primary btn-block"),
      
      actionButton("createGraph", "Create/Update Graph", 
                  class = "btn-primary btn-block"),
      
      # Intelligent Assignment Section
      conditionalPanel(
        condition = paste0("true"), # Always show, but content changes based on UTILS_AVAILABLE
        div(class = "intelligent-section",
          h5("🧠 AI Group Assignment", style = "color: white; margin-top: 0;"),
          
          conditionalPanel(
            condition = paste0(UTILS_AVAILABLE),
            actionButton("intelligentAssign", "🚀 Auto-Assign Groups", 
                        title = "Automatically assign nodes to SES groups using AI", 
                        class = "btn-block"),
            
            br(),
            
            sliderInput("confidenceThreshold", "Confidence Threshold:", 
                       min = 0.1, max = 1.0, value = 0.5, step = 0.1,
                       width = "100%"),
            
            fluidRow(
              column(6,
                actionButton("testClassification", "🧪 Test AI", 
                            class = "btn-secondary btn-sm btn-block")
              ),
              column(6,
                actionButton("debugTest", "📊 Demo", 
                            class = "btn-warning btn-sm btn-block")
              )
            )
          ),
          
          conditionalPanel(
            condition = paste0("!", UTILS_AVAILABLE),
            div(style = "text-align: center; color: white;",
                p("⚠️ AI features require utils.R"),
                p("Place utils.R in project directory", style = "font-size: 12px;")
            )
          )
        )
      ),
      
      hr(),
      
      # Visualization Options
      h4("🎨 Visualization", class = "section-header"),
      
      selectInput("nodeShape", "Node Shape:", 
                 choices = c("dot", "square", "triangle", "diamond"), 
                 selected = "dot"),
      
      selectInput("edgeStyle", "Edge Style:", 
                 choices = c("to", "from", "middle"), 
                 selected = "to"),
      
      sliderInput("edgeWidth", "Edge Width:", min = 1, max = 10, value = 1),
      
      checkboxInput("showLabels", "Show Labels", value = TRUE),
      checkboxInput("useGroupShapes", "Use Group Shapes", value = TRUE),
      checkboxInput("useEdgeWeight", "Use Edge Weights", value = TRUE),
      checkboxInput("useEdgeColor", "Use Edge Colors", value = TRUE),
      checkboxInput("showLegend", "Show Legend", value = TRUE),
      
      hr(),
      
      # Analysis and Export
      h4("📈 Analysis & Export", class = "section-header"),
      
      actionButton("Run analyses", "Run CLD loop analysis", class = "btn-success btn-block"),
      
      downloadButton("downloadPlot", "💾 Save Plot as HTML", class = "btn-info btn-block"),
      
      hr()
    ),
    
    # Main panel ----
    mainPanel(
      width = 9,
      
      # Enhanced status message output
      div(class = "status-box",
          h5("📊 System Status", style = "margin: 0 0 10px 0;"),
          textOutput("statusMessage")
      ),
      
      # Debug information panel (toggleable)
      conditionalPanel(
        condition = "input.showDebugInfo == true",
        div(class = "debug-info",
            h6("🔍 Debug Information"),
            verbatimTextOutput("debugInfo")
        )
      ),
      
      tabsetPanel(
        
        # Network Graph Tab
        tabPanel(
          "🌐 Network Graph",
          icon = icon("project-diagram"),
          br(),
          div(
            class = "network-container",
            visNetworkOutput("network", height = "600px")
          ),
          br(),
          fluidRow(
            column(3,
              checkboxInput("showDebugInfo", "Show Debug Info", value = FALSE)
            ),
            column(3,
              downloadButton("downloadData", "Export Data", 
                           class = "btn-outline-primary btn-sm")
            ),
            column(3,
              actionButton("resetLayout", "Reset Layout", 
                          class = "btn-outline-secondary btn-sm")
            ),
            column(3,
              actionButton("refreshGraph", "Refresh Graph", 
                          class = "btn-outline-success btn-sm")
            )
          )
        ),
        
        # Group Analysis Tab (Enhanced)
        tabPanel(
          "🧠 Group Analysis",
          icon = icon("chart-pie"),
          br(),
          
          conditionalPanel(
            condition = paste0(UTILS_AVAILABLE),
            
            fluidRow(
              column(6,
                div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                  h4("📊 Group Distribution", style = "margin-top: 0;"),
                  DTOutput("groupAnalysisTable")
                )
              ),
              column(6,
                div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                  h4("📈 Classification Summary", style = "margin-top: 0;"),
                  verbatimTextOutput("classificationSummary")
                )
              )
            ),
            
            br(),
            
            fluidRow(
              column(12,
                div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                  h4("⚠️ Low Confidence Assignments", style = "margin-top: 0;"),
                  DTOutput("lowConfidenceTable")
                )
              )
            ),
            
            br(),
            
            fluidRow(
              column(6,
                div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                  h4("📋 AI System Info", style = "margin-top: 0;"),
                  actionButton("exportRules", "📄 Export Rules", 
                             class = "btn-info btn-sm"),
                  br(), br(),
                  div(style = "max-height: 300px; overflow-y: auto; background: #f8f9fa; padding: 10px; border-radius: 4px;",
                      verbatimTextOutput("aiSystemInfo")
                  )
                )
              ),
              column(6,
                div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                  h4("💡 Quick Actions", style = "margin-top: 0;"),
                  actionButton("rerunClassification", "🔄 Re-run Classification", 
                             class = "btn-primary btn-sm btn-block"),
                  br(),
                  actionButton("adjustThreshold", "⚙️ Optimize Threshold", 
                             class = "btn-secondary btn-sm btn-block"),
                  br(),
                  actionButton("exportAnalysis", "📊 Export Analysis", 
                             class = "btn-success btn-sm btn-block")
                )
              )
            )
          ),
          
          # Fallback message when utils.R not available
          conditionalPanel(
            condition = paste0("!", UTILS_AVAILABLE),
            div(class = "alert alert-warning", style = "margin: 20px;",
                h4("⚠️ AI Features Unavailable"),
                p("The intelligent group assignment features require the utils.R file to be present in your project directory."),
                p("To enable AI features:"),
                tags$ol(
                  tags$li("Download utils.R from the provided files"),
                  tags$li("Place it in the same directory as app.R and classes.R"),
                  tags$li("Restart the application")
                ),
                p(strong("Benefits of AI features:"), "Automatic classification of nodes into SES groups using marine science expertise.")
            )
          )
        ),
        
        # Elements Table Tab
        tabPanel(
          "📋 Elements Table",
          icon = icon("table"),
          br(),
          DTOutput("EldataTable")
        ),
        
        # Connections Table Tab
        tabPanel(
          "🔗 Connections Table", 
          icon = icon("link"),
          br(),
          DTOutput("dataTable")
        ),
        
        # Tool Help Tab
        tabPanel(
          "❓ Tool Help",
          icon = icon("question-circle"),
          br(),
          tryCatch({
            includeMarkdown("tool.md")
          }, error = function(e) {
            div(class = "alert alert-info",
                h4("📚 SES Tool Help"),
                p("Tool help documentation (tool.md) not found in project directory."),
                h5("Quick Start Guide:"),
                tags$ol(
                  tags$li(strong("Upload Data:"), "Select file format (XLSX, CSV, GraphML) and upload your network data"),
                  tags$li(strong("Create Network:"), "Click 'Create Network' to process the data structure"),
                  tags$li(strong("Generate Graph:"), "Click 'Create/Update Graph' to create the visualization"),
                  tags$li(strong("AI Assignment:"), "Use 'Auto-Assign Groups' for intelligent node classification"),
                  tags$li(strong("Analyze Results:"), "Check the Group Analysis tab for detailed insights"),
                  tags$li(strong("Export:"), "Save your network as interactive HTML")
                ),
                h5("File Format Requirements:"),
                tags$ul(
                  tags$li(strong("CSV:"), "Minimum 2 columns (from, to). Optional: weight, group, edge_color"),
                  tags$li(strong("XLSX:"), "Single sheet with connections OR two sheets (Elements + Connections)"),
                  tags$li(strong("GraphML:"), "Standard network format from other tools")
                ),
                h5("SES Group Categories:"),
                tags$ul(
                  tags$li("🔵 Marine processes: Natural oceanic and coastal processes"),
                  tags$li("🟩 Pressures: Human-induced stresses on the system"),  
                  tags$li("🔺 Ecosystem Services: Benefits provided by marine ecosystems"),
                  tags$li("🔻 Societal Goods and Benefits: Direct benefits to human society"),
                  tags$li("♦️ Activities: Human activities affecting the marine environment"),
                  tags$li("⬡ Drivers: Underlying forces driving system changes")
                )
            )
          })
        ),
        
        # SES Help Tab
        tabPanel(
          "🌊 SES Help",
          icon = icon("info-circle"),
          br(),
          tryCatch({
            includeMarkdown("guidance.md")
          }, error = function(e) {
            div(class = "alert alert-info",
                h4("🌊 Social-Ecological Systems (SES) Guidance"),
                p("SES guidance documentation (guidance.md) not found in project directory."),
                h5("What are Social-Ecological Systems?"),
                p("Social-ecological systems (SES) are complex, integrated systems where social and ecological components interact across multiple scales. In marine contexts, SES include:"),
                
                h5("Core SES Components:"),
                div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;",
                  tags$ul(
                    tags$li(strong("🔵 Marine Processes:"), "Biological, chemical, and physical ocean processes (currents, productivity, biodiversity)"),
                    tags$li(strong("🟩 Pressures:"), "Human-induced stresses (pollution, overfishing, climate change, habitat destruction)"),
                    tags$li(strong("🔺 Ecosystem Services:"), "Benefits ecosystems provide (fish production, climate regulation, coastal protection)"),
                    tags$li(strong("🔻 Societal Goods & Benefits:"), "Direct human benefits (food security, livelihoods, recreation, cultural values)"),
                    tags$li(strong("♦️ Activities:"), "Human activities affecting the system (fishing, shipping, tourism, development)"),
                    tags$li(strong("⬡ Drivers:"), "Underlying forces of change (population growth, economic development, governance, technology)")
                  )
                ),
                
                h5("SES Analysis Principles:"),
                tags$ul(
                  tags$li("🔄 Interconnectedness: All components are linked through complex relationships"),
                  tags$li("⚡ Feedback Loops: Changes in one component affect others, creating cascading effects"),
                  tags$li("📊 Multi-scale: Interactions occur across local, regional, and global scales"),
                  tags$li("🕐 Temporal Dynamics: Systems change over time with different response rates"),
                  tags$li("🎯 Sustainability: Balance between human needs and ecological integrity")
                ),
                
                h5("Using This Tool for SES Analysis:"),
                tags$ol(
                  tags$li("Map your system components as nodes"),
                  tags$li("Define relationships between components as edges"),
                  tags$li("Use AI assignment to categorize nodes into SES groups"),
                  tags$li("Analyze network structure to identify key relationships"),
                  tags$li("Look for feedback loops and system vulnerabilities"),
                  tags$li("Use insights for sustainable management strategies")
                )
            )
          })
        )
      )
    )
  )
)

# Define server ----
server <- function(input, output, session) {
  # Disable action buttons initially
  disable("Run analyses")
  disable("change_df")
  disable("createNetwork")
  disable("createGraph")
  if (UTILS_AVAILABLE) {
    disable("intelligentAssign")
  }
  
  # Internal storage for reactive values
  current_df <- reactiveVal(NULL)
  links_data <- reactiveVal(NULL)
  elements_data <- reactiveVal(NULL)
  excel <- reactiveVal(FALSE)
  graph_data <- reactiveVal(NULL)
  classification_results <- reactiveVal(NULL)
  
  # Add a Bootstrap tooltip
  bsTooltip("fileType", "Select file format for your network data", placement = "right", trigger = "hover")
  
  # Enhanced debug output
  output$debugInfo <- renderText({
    info <- c()
    
    # System information
    info <- c(info, paste("🤖 AI System:", ifelse(UTILS_AVAILABLE, "Available ✅", "Not Available ❌")))
    info <- c(info, paste("📅 Session Time:", format(Sys.time(), "%H:%M:%S")))
    
    # Data information
    if (!is.null(links_data())) {
      info <- c(info, paste("🔗 Links data:", nrow(links_data()), "rows,", ncol(links_data()), "columns"))
    }
    
    if (!is.null(elements_data())) {
      info <- c(info, paste("📋 Elements data:", nrow(elements_data()), "rows,", ncol(elements_data()), "columns"))
      if ("group" %in% colnames(elements_data())) {
        group_counts <- table(elements_data()$group)
        info <- c(info, paste("🏷️ Groups:", paste(names(group_counts), "=", group_counts, collapse = ", ")))
      }
      if ("group_confidence" %in% colnames(elements_data())) {
        avg_conf <- round(mean(elements_data()$group_confidence, na.rm = TRUE), 3)
        info <- c(info, paste("📊 Avg Confidence:", avg_conf))
      }
    }
    
    if (!is.null(graph_data())) {
      info <- c(info, paste("🌐 Graph data:", nrow(graph_data()$nodes), "nodes,", nrow(graph_data()$edges), "edges"))
    }
    
    # Configuration
    info <- c(info, paste("⚙️ Excel mode:", excel()))
    if (UTILS_AVAILABLE) {
      info <- c(info, paste("🎯 Confidence threshold:", input$confidenceThreshold))
    }
    
    if (length(info) == 0) {
      info <- "ℹ️ No data loaded yet - upload a file to begin"
    }
    
    paste(info, collapse = "\n")
  })
  
  # Observe the button click to change the dataframe
  observeEvent(input$change_df, {
    req(links_data())
    req(current_df)
    df <- current_df()
    df1 <- links_data()
    if (identical(current_df(), df1)) {
      current_df(df)
    } else {
      current_df(df1)
    }
  })
  
  # Create dynamic dropdown menus based on dataframe column names
  output$strength <- renderUI({
    req(current_df())
    df <- current_df()
    selectInput("strength", "Strength variable:", choices = names(df))
  })

  output$group <- renderUI({
    req(current_df())
    df <- current_df()
    selectInput("group", "Group variable:", choices = names(df))
  })
  
  # Render the file input dynamically based on the selected file type
  output$dynamicUploadButton <- renderUI({
    req(input$fileType)
    
    file_icon <- switch(input$fileType,
                       "xlsx" = "📊",
                       "csv" = "📄", 
                       "graphml" = "🕸️")
    
    fileInput("file", 
             paste(file_icon, "Upload", toupper(input$fileType), "File"),
             accept = switch(input$fileType,
               "xlsx" = ".xlsx",
               "csv" = ".csv",
               "graphml" = ".graphml"
             ))
  })

  # Enhanced file upload observer
  observeEvent(input$file, {
    req(input$file)
    file <- input$file$datapath
    file_type <- input$fileType
    
    print(paste("Processing file:", input$file$name))

    # Initialize variables
    status <- NULL
    df <- NULL
    nodes <- NULL
    xl <- FALSE

    # Show loading notification
    id <- showNotification("🔄 Loading file...", type = "default", duration = NULL)
    
    # Load and validate data based on file type
    if (file_type == "csv") {
      print("Loading CSV file...")
      df <- tryCatch({
        read.csv(file, stringsAsFactors = FALSE)
      }, error = function(e) {
        showNotification("❌ Error reading CSV file. Please check file format.", type = "error")
        NULL
      })
      
      if (!is.null(df)) {
        if (ncol(df) < 2) {
          showNotification("❌ CSV file must have at least 2 columns", type = "error")
          df <- NULL
        } else {
          status <- "✅ CSV file loaded successfully"
          excel(FALSE)
          xl <- FALSE
        }
      } else {
        status <- "❌ Invalid CSV file"
      }
      
    } else if (file_type == "xlsx") {
      print("Loading Excel file with SES object...")
      tryCatch({
        ses <- SES$new(file, use_intelligent_groups = UTILS_AVAILABLE)
        nodes <- ses$nodes
        df <- ses$edges
        
        if (!is.null(df)) {
          excel(TRUE)
          xl <- TRUE
          status <- ifelse(UTILS_AVAILABLE, 
                          "✅ Excel file loaded with AI group assignment", 
                          "✅ Excel file loaded successfully")
          print("Excel file processed successfully")
        } else {
          status <- "❌ Invalid Excel file - no edges found"
        }
      }, error = function(e) {
        showNotification(paste("❌ Error loading Excel file:", e$message), type = "error")
        status <- "❌ Error loading Excel file"
      })
      
    } else if (file_type == "graphml") {
      print("Loading GraphML file...")
      df <- tryCatch({
        read_graph(file, format = "graphml")
      }, error = function(e) {
        showNotification("❌ Error reading GraphML file. Please check file format.", type = "error")
        NULL
      })
      
      if (!is.null(df)) {
        status <- "✅ GraphML file loaded successfully"
        excel(FALSE)
        xl <- FALSE
      } else {
        status <- "❌ Invalid GraphML file"
      }
    }
    
    # Remove loading notification
    removeNotification(id)
    
    # Update status and store data if valid
    output$statusMessage <- renderText(status)
    
    if (!is.null(df)) {
      links_data(df)
      current_df(df)
      
      # Store nodes data if from excel file
      if (xl && !is.null(nodes)) {
        elements_data(nodes)
      }
      
      # Enable action buttons
      enable("change_df")
      enable("createNetwork")
      enable("createGraph")
      if (UTILS_AVAILABLE) {
        enable("intelligentAssign")
      }
      enable("Run analyses")
      
      # Success notification with file details
      showNotification(
        paste("🎉 File loaded successfully!", 
              nrow(df), "connections found"),
        type = "message",
        duration = 5
      )
    }
  })
  
  # Create network observer
  observeEvent(input$createNetwork, {
    req(links_data())
    data <- links_data()
    xl <- excel()
    
    if (xl) {
      print("Processing Excel network data")
    } else {
      if (ncol(data) < 2) {
        showNotification("❌ Data must have at least 2 columns for connections", type = "error")
        return()
      }
      
      # Ensure proper column names
      colnames(data)[1:2] <- c("from", "to")
      nodes <- data.frame(id = unique(c(data$from, data$to)), stringsAsFactors = FALSE)
      elements_data(nodes)
      print(paste("Created", nrow(nodes), "nodes from connections"))
    }
    
    showNotification("✅ Network structure created successfully!", type = "message")
  })

  # Intelligent group assignment observer
  if (UTILS_AVAILABLE) {
    observeEvent(input$intelligentAssign, {
      req(elements_data())
      
      nodes <- elements_data()
      
      if (nrow(nodes) == 0) {
        showNotification("❌ No nodes available for group assignment", type = "error")
        return()
      }
      
      # Apply intelligent group assignment with progress
      withProgress(message = "🧠 Analyzing nodes with AI...", value = 0, {
        
        incProgress(0.2, detail = "Initializing classification system...")
        
        incProgress(0.4, detail = "Applying machine learning rules...")
        
        classified_nodes <- assign_multiple_groups(
          nodes,
          name_column = "id",
          description_column = if("description" %in% colnames(nodes)) "description" else NULL,
          confidence_threshold = input$confidenceThreshold,
          add_confidence = TRUE
        )
        
        incProgress(0.8, detail = "Updating visualization...")
        
        # Update the stored data
        elements_data(classified_nodes)
        classification_results(classified_nodes)
        
        # Analyze results
        analysis <- analyze_classification_results(classified_nodes)
        
        incProgress(1.0, detail = "Complete!")
      })
      
      # Show detailed results
      high_conf <- sum(classified_nodes$group_confidence >= 0.7, na.rm = TRUE)
      med_conf <- sum(classified_nodes$group_confidence >= 0.4 & classified_nodes$group_confidence < 0.7, na.rm = TRUE)
      low_conf <- sum(classified_nodes$group_confidence < 0.4, na.rm = TRUE)
      
      showNotification(
        HTML(paste("🎉 <strong>AI Assignment Complete!</strong><br>",
                  "✅ High confidence:", high_conf, "<br>",
                  "⚠️ Medium confidence:", med_conf, "<br>", 
                  "❌ Low confidence:", low_conf)),
        type = "message",
        duration = 10
      )
      
      # Force graph update if graph exists
      if (!is.null(graph_data())) {
        current_edges <- links_data()
        graph_data(list(nodes = classified_nodes, edges = current_edges))
      }
    })
  }

  # Enhanced create graph observer
  observeEvent(input$createGraph, {
    req(links_data())
    data <- links_data()
    xl <- excel()
    
    # Validate data
    if (is.null(data) || nrow(data) == 0) {
      showNotification("❌ No data available for graph creation", type = "error")
      return()
    }
    
    strength <- input$strength
    print("Creating graph visualization...")
    
    # Process nodes and edges based on data source
    if (xl) {
      # Excel data from SES object
      nodes <- elements_data()
      edges <- links_data()
      
      if (is.null(nodes) || is.null(edges)) {
        showNotification("❌ Missing nodes or edges data", type = "error")
        return()
      }
    } else {
      # CSV or other data
      if (!all(c("from", "to") %in% names(data))) {
        if (ncol(data) >= 2) {
          colnames(data)[1:2] <- c("from", "to")
        } else {
          showNotification("❌ Data must contain 'from' and 'to' columns", type = "error")
          return()
        }
      }
      
      # Create nodes dataframe
      nodes <- data.frame(id = unique(c(data$from, data$to)), stringsAsFactors = FALSE)
      
      # Apply group assignment
      if ("group" %in% names(data)) {
        nodes$group <- data$group[match(unique(c(data$from, data$to)), data$from)]
        print("Using existing groups from data")
      } else if (UTILS_AVAILABLE) {
        print("Applying intelligent group assignment...")
        
        tryCatch({
          classified_nodes <- assign_multiple_groups(
            nodes,
            name_column = "id",
            confidence_threshold = input$confidenceThreshold,
            add_confidence = TRUE
          )
          nodes$group <- classified_nodes$group
          nodes$group_confidence <- classified_nodes$group_confidence
          classification_results(classified_nodes)
          
          print("Intelligent assignment completed")
        }, error = function(e) {
          print(paste("Error in intelligent assignment:", e$message))
          nodes$group <- "Unclassified"
        })
      } else {
        print("No group information available, using 'Unclassified'")
        nodes$group <- "Unclassified"
      }
      
      # Add visual properties
      nodes$Name <- if (input$showLabels) as.character(nodes$id) else ""
      nodes$shape <- input$nodeShape
      
      # Save nodes
      elements_data(nodes)
      
      # Create edges dataframe
      edges <- data.frame(from = data$from, to = data$to, stringsAsFactors = FALSE)
      edges$width <- if (input$useEdgeWeight && "weight" %in% names(data)) {
        as.numeric(data$weight)
      } else {
        input$edgeWidth
      }
      edges$arrows <- input$edgeStyle
      edges$color <- if (input$useEdgeColor && "edge_color" %in% names(data)) {
        data$edge_color
      } else {
        "gray"
      }
    }
    
    # Create enhanced tooltips
    print("Creating tooltips...")
    
    # Edge tooltips
    if ("Frequency" %in% names(edges)) {
      edges$title <- paste0("<p><b>", edges$Frequency, "</b><br>Frequency</p>")
    } else if ("width" %in% names(edges)) {
      edges$title <- paste0("<p><b>Strength: ", edges$width, "</b></p>")
    } else {
      edges$title <- "Connection"
    }
    
    # Enhanced node tooltips with confidence
    if ("group_confidence" %in% names(nodes)) {
      conf_level <- cut(nodes$group_confidence, 
                       breaks = c(0, 0.4, 0.7, 1), 
                       labels = c("Low", "Medium", "High"),
                       include.lowest = TRUE)
      
      nodes$title <- paste0(
        "<p><b>", nodes$id, "</b><br>",
        "Group: ", nodes$group, "<br>",
        "Confidence: ", round(nodes$group_confidence, 2), " (", conf_level, ")</p>"
      )
    } else if ("group" %in% names(nodes)) {
      nodes$title <- paste0("<p><b>", nodes$id, "</b><br>Group: ", nodes$group, "</p>")
    } else {
      nodes$title <- paste0("<p><b>", nodes$id, "</b></p>")
    }
    
    # Store the updated data
    links_data(edges)
    graph_data(list(nodes = nodes, edges = edges))
    
    print(paste("Graph created successfully:", nrow(nodes), "nodes,", nrow(edges), "edges"))
    showNotification("🎨 Graph visualization created successfully!", type = "message")
  })

  # Enhanced network rendering
  output$network <- renderVisNetwork({
    req(graph_data())
    data <- graph_data()
    
    print("Rendering network visualization...")
    
    # Create the network plot
    net <- visNetwork(nodes = data$nodes, edges = data$edges) %>%
      visOptions(
        manipulation = list(enabled = TRUE),
        highlightNearest = list(enabled = TRUE, degree = 2, hover = TRUE),
        selectedBy = if ("group" %in% colnames(data$nodes)) "group" else NULL
      ) %>%
      visLayout(randomSeed = 123) %>%
      visPhysics(
        stabilization = list(enabled = TRUE, iterations = 100),
        barnesHut = list(gravitationalConstant = -8000, springConstant = 0.001, springLength = 200)
      ) %>%
      set_VisGroups() %>%
      visInteraction(
        navigationButtons = TRUE, 
        hover = TRUE,
        tooltipDelay = 300,
        hideEdgesOnDrag = TRUE
      ) %>%
      visEvents(
        hoverNode = "function(nodes) {
          Shiny.onInputChange('current_node_id', nodes.node);
        }",
        hoverEdge = "function(edges) {
          Shiny.onInputChange('current_edge_id', edges.edge);
        }",
        click = "function(nodes) {
          Shiny.onInputChange('clicked_node', nodes.nodes[0]);
        }"
      )

    # Add legend if requested
    if (input$showLegend) {
      net <- net %>% visLegend(
        width = 0.2, 
        position = "right", 
        main = "🏷️ Node Groups",
        ncol = 1,
        stepX = 100,
        stepY = 65
      )
    }

    print("Network visualization rendered")
    net
  })
  
  # Group analysis outputs (only if UTILS_AVAILABLE)
  if (UTILS_AVAILABLE) {
    output$groupAnalysisTable <- renderDT({
      req(elements_data())
      
      if ("group" %in% colnames(elements_data())) {
        analysis <- analyze_classification_results(elements_data())
        
        group_summary <- data.frame(
          Group = names(analysis$group_distribution),
          Count = as.numeric(analysis$group_distribution),
          Percentage = paste0(analysis$group_percentages, "%"),
          stringsAsFactors = FALSE
        )
        
        # Add confidence information if available
        if ("group_confidence" %in% colnames(elements_data())) {
          conf_by_group <- elements_data() %>%
            group_by(group) %>%
            summarise(
              AvgConfidence = round(mean(group_confidence, na.rm = TRUE), 2),
              .groups = 'drop'
            )
          
          group_summary <- merge(group_summary, conf_by_group, by.x = "Group", by.y = "group", all.x = TRUE)
        }
        
        datatable(group_summary, 
                 options = list(pageLength = 10, dom = 't'),
                 rownames = FALSE) %>%
          formatStyle(
            'Group',
            backgroundColor = styleEqual(
              c('Marine processes', 'Pressures', 'Ecosystem Services', 
                'Societal Goods and Benefits', 'Activities', 'Drivers', 'Unclassified'),
              c('#E3F2FD', '#F1F8E9', '#E8F5E8', '#E0F2F1', '#FFF3E0', '#F3E5F5', '#FFF9C4')
            )
          )
      }
    })

    output$classificationSummary <- renderText({
      req(elements_data())
      
      if ("group_confidence" %in% colnames(elements_data())) {
        analysis <- analyze_classification_results(elements_data())
        
        paste(
          "📊 Classification Summary\n",
          "========================\n",
          "Total Nodes: ", analysis$total_nodes, "\n",
          "✅ Classified: ", analysis$total_nodes - analysis$unclassified_count, "\n",
          "❌ Unclassified: ", analysis$unclassified_count, "\n",
          "📈 Average Confidence: ", round(analysis$average_confidence, 3), "\n",
          "⚠️ Low Confidence (<0.6): ", analysis$low_confidence_nodes, "\n\n",
          "🎯 Quality Rating: ", 
          if (analysis$average_confidence >= 0.7) "🟢 Excellent" 
          else if (analysis$average_confidence >= 0.5) "🟡 Good" 
          else "🔴 Needs Review"
        )
      } else if ("group" %in% colnames(elements_data())) {
        analysis <- analyze_classification_results(elements_data())
        paste(
          "📊 Basic Group Summary\n",
          "=====================\n",
          "Total Nodes: ", analysis$total_nodes, "\n",
          "✅ Classified: ", analysis$total_nodes - analysis$unclassified_count, "\n",
          "❌ Unclassified: ", analysis$unclassified_count, "\n\n",
          "ℹ️ Confidence data: Not available\n",
          "💡 Use AI assignment for confidence scores"
        )
      } else {
        "📊 No group data available\n\n💡 Upload data or use AI assignment to get started"
      }
    })

    output$lowConfidenceTable <- renderDT({
      req(elements_data())
      
      if ("group_confidence" %in% colnames(elements_data())) {
        low_conf <- elements_data()[elements_data()$group_confidence < 0.6, ]
        
        if (nrow(low_conf) > 0) {
          datatable(low_conf, 
                   options = list(pageLength = 10),
                   rownames = FALSE) %>%
            formatStyle(
              'group_confidence',
              backgroundColor = styleInterval(c(0.4, 0.6), c('#ffebee', '#fff3e0', '#e8f5e8'))
            )
        } else {
          datatable(data.frame(Message = "🎉 No low confidence assignments found!"), 
                   options = list(dom = 't'), rownames = FALSE)
        }
      }
    })
    
    output$aiSystemInfo <- renderText({
      if (exists("test_classification_system")) {
        paste(
          "🧠 AI Classification System Status\n",
          "===================================\n",
          "System: ACTIVE ✅\n",
          "Marine Keywords: 600+ terms\n",
          "SES Categories: 6 groups\n",
          "Algorithm: Multi-layer matching\n",
          "  - Exact keyword matching\n",
          "  - Fuzzy text similarity\n",
          "  - Partial string matching\n",
          "  - Confidence scoring\n\n",
          "📊 Quality Thresholds:\n",
          "🟢 High (0.7-1.0): Very reliable\n",
          "🟡 Medium (0.4-0.7): Generally good\n",
          "🔴 Low (0.0-0.4): Needs review\n\n",
          "🔧 Current Settings:\n",
          "Threshold: ", input$confidenceThreshold, "\n",
          "Mode: ", ifelse(input$confidenceThreshold >= 0.7, "Strict", 
                          ifelse(input$confidenceThreshold >= 0.4, "Balanced", "Permissive"))
        )
      } else {
        "⚠️ AI system not fully loaded"
      }
    })
  }

  # Test functions
  if (UTILS_AVAILABLE) {
    observeEvent(input$debugTest, {
      print("Loading demo data for testing...")
      
      test_nodes <- data.frame(
        id = c("Commercial fishing", "Ocean acidification", "Fish production", 
               "Tourism revenue", "Coral reef ecosystem", "Plastic pollution"),
        description = c("Large-scale fishing operations", "pH reduction in seawater",
                       "Marine food provision", "Income from coastal tourism",
                       "Coral reef habitat and biodiversity", "Marine plastic waste"),
        stringsAsFactors = FALSE
      )
      
      test_edges <- data.frame(
        from = c("Commercial fishing", "Ocean acidification", "Fish production", 
                "Coral reef ecosystem", "Plastic pollution"),
        to = c("Ocean acidification", "Fish production", "Tourism revenue",
              "Fish production", "Ocean acidification"),
        weight = c(0.8, 0.7, 0.9, 0.6, 0.5),
        arrows = rep("to", 5),
        stringsAsFactors = FALSE
      )
      
      elements_data(test_nodes)
      links_data(test_edges)
      graph_data(list(nodes = test_nodes, edges = test_edges))
      
      showNotification("🧪 Demo data loaded! Try 'Auto-Assign Groups' to see AI in action.", 
                      type = "message", duration = 8)
    })

    observeEvent(input$testClassification, {
      if (exists("test_classification_system")) {
        withProgress(message = "🧪 Testing AI classification system...", value = 0, {
          incProgress(0.5, detail = "Running validation tests...")
          results <- test_classification_system()
          incProgress(1.0, detail = "Complete!")
        })
        
        showNotification(
          HTML(paste("🧪 <strong>AI System Test Results:</strong><br>",
                    "✅ Accuracy:", round(results$accuracy * 100, 1), "%<br>",
                    "📊 Avg Confidence:", round(results$average_confidence, 3))),
          type = "message",
          duration = 10
        )
      } else {
        showNotification("❌ utils.R not properly loaded - cannot run test", type = "error")
      }
    })
    
    # Additional AI action buttons
    observeEvent(input$rerunClassification, {
      if (!is.null(elements_data())) {
        updateSliderInput(session, "intelligentAssign")
        showNotification("🔄 Click 'Auto-Assign Groups' to re-run classification", type = "message")
      }
    })
    
    observeEvent(input$adjustThreshold, {
      if (!is.null(elements_data()) && "group_confidence" %in% colnames(elements_data())) {
        # Suggest optimal threshold based on current data
        confidences <- elements_data()$group_confidence
        optimal <- quantile(confidences, 0.3, na.rm = TRUE)
        updateSliderInput(session, "confidenceThreshold", value = round(optimal, 1))
        showNotification(paste("🎯 Threshold adjusted to", round(optimal, 1), "based on your data"), type = "message")
      }
    })
  }
  
  # Data table outputs
  output$dataTable <- renderDT({
    req(links_data())
    datatable(links_data(), 
             editable = TRUE,
             options = list(scrollX = TRUE, pageLength = 15))
  })

  output$EldataTable <- renderDT({
    req(elements_data())
    datatable(elements_data(), 
             editable = TRUE,
             options = list(scrollX = TRUE, pageLength = 15))
  })

  # Update reactive data when tables are edited
  observeEvent(input$dataTable_cell_edit, {
    info <- input$dataTable_cell_edit
    updated_data <- editData(links_data(), info)
    links_data(updated_data)
    showNotification("📝 Connections data updated", type = "message")
  })

  observeEvent(input$EldataTable_cell_edit, {
    info <- input$EldataTable_cell_edit
    updated_data <- editData(elements_data(), info)
    elements_data(updated_data)
    showNotification("📝 Elements data updated", type = "message")
  })

  # Enhanced download handler
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste0("ses_network_", Sys.Date(), ".html")
    },
    content = function(file) {
      req(graph_data())
      
      withProgress(message = "💾 Preparing download...", value = 0, {
        incProgress(0.5, detail = "Creating interactive plot...")
        
        net <- visNetwork(nodes = graph_data()$nodes, edges = graph_data()$edges) %>%
          visOptions(manipulation = FALSE, highlightNearest = list(enabled = TRUE, degree = 2)) %>%
          visLayout(randomSeed = 123) %>%
          visPhysics(stabilization = TRUE) %>%
          visInteraction(navigationButtons = TRUE, hover = TRUE) %>%
          set_VisGroups()

        if (input$showLegend) {
          net <- net %>% visLegend(width = 0.15, position = "right", main = "Node Groups")
        }
        
        incProgress(1.0, detail = "Saving file...")
        saveWidget(net, file, selfcontained = TRUE)
      })
      
      showNotification("💾 Network plot saved successfully!", type = "message")
    }
  )
  
  # Status message output
  output$statusMessage <- renderText({
    if (is.null(links_data())) {
      "ℹ️ No data loaded. Please upload a file to begin."
    } else if (is.null(graph_data())) {
      "📊 Data loaded. Click 'Create Network' then 'Create/Update Graph' to visualize."
    } else {
      nodes_count <- nrow(graph_data()$nodes)
      edges_count <- nrow(graph_data()$edges)
      
      if ("group_confidence" %in% colnames(graph_data()$nodes)) {
        avg_conf <- round(mean(graph_data()$nodes$group_confidence, na.rm = TRUE), 2)
        paste("✅ Network ready:", nodes_count, "nodes,", edges_count, "edges | AI Confidence:", avg_conf)
      } else {
        paste("✅ Network ready:", nodes_count, "nodes,", edges_count, "edges")
      }
    }
  })
}

# Run the app ----
cat("🚀 Starting SES Tool application...\n")
cat("====================================\n")
if (UTILS_AVAILABLE) {
  cat("✅ AI-powered group assignment: ENABLED\n")
} else {
  cat("⚠️ AI-powered group assignment: DISABLED (utils.R not found)\n")
}
cat("🌐 Starting Shiny server...\n")

shinyApp(ui = ui, server = server)