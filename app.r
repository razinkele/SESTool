# app.R - SES Tool with Intelligent Group Assignment and Loop Analysis
# Modified to work with utils.R AI-powered node classification and analysis.R loop analysis
# FIXED: Corrected showNotification types and removed Change groups & Visualization sections

# List of required packages
required_packages <- c("shiny", "shinyBS", "visNetwork", "readsdr", "readr", "igraph", 
                      "dplyr", "htmlwidgets", "colourpicker", "shinyjs", "DT", 
                      "markdown", "stringdist", "LoopAnalyst")

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

# Include the loop analysis functions
if (file.exists("analysis.R")) {
  source("analysis.R")
  cat("✅ Loop analysis functions loaded successfully.\n")
  ANALYSIS_AVAILABLE <- TRUE
} else {
  warning("⚠️ analysis.R not found - loop analysis will not be available")
  ANALYSIS_AVAILABLE <- FALSE
}

# Include the loop generator plugin
if (file.exists("loop_generator.R")) {
  source("loop_generator.R")
  cat("✅ Loop generator plugin loaded successfully.\n")
  LOOP_GENERATOR_AVAILABLE <- TRUE
} else {
  warning("⚠️ loop_generator.R not found - loop generation will not be available")
  LOOP_GENERATOR_AVAILABLE <- FALSE
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
      },
      " ",
      if (ANALYSIS_AVAILABLE) {
        tags$span("🔄 Loop Analysis", class = "ai-badge")
      } else {
        tags$span("⚠️ No Loops", class = "basic-badge")
      },
      " ",
      if (LOOP_GENERATOR_AVAILABLE) {
        tags$span("🎯 Loop Generator", class = "ai-badge")
      } else {
        tags$span("⚠️ No Generator", class = "basic-badge")
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
      
      hr(),
      
      # Network Creation
      h4("🌐 Network Creation", class = "section-header"),
      
      actionButton("createNetwork", "Create Network", 
                  title = "Create network from the uploaded links table", 
                  class = "btn-primary btn-block"),
      
      actionButton("createGraph", "Create/Update Graph", 
                  class = "btn-primary btn-block"),
      
      # Intelligent Assignment Section
      div(class = "intelligent-section",
        h5("🧠 AI Group Assignment", style = "color: white; margin-top: 0;"),
        
        if (UTILS_AVAILABLE) {
          tagList(
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
          )
        } else {
          div(style = "text-align: center; color: white;",
              p("⚠️ AI features require utils.R"),
              p("Place utils.R in project directory", style = "font-size: 12px;")
          )
        }
      ),
      
      hr(),
      
      # Loop Network Generator Plugin
      if (LOOP_GENERATOR_AVAILABLE) {
        div(class = "intelligent-section", style = "background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%);",
          h5("🔄 Loop Network Generator", style = "color: white; margin-top: 0;"),
          
          selectInput("loopTemplate", "Network Template:",
                     choices = list(
                       "Simple Marine Loop" = "simple_marine",
                       "Complex Fisheries System" = "complex_fisheries", 
                       "Coastal Tourism Loop" = "coastal_tourism",
                       "Climate-Ecosystem Loop" = "climate_ecosystem",
                       "Pollution Impact Chain" = "pollution_chain",
                       "Multiple Feedback System" = "multi_feedback"
                     ),
                     selected = "simple_marine",
                     width = "100%"),
          
          fluidRow(
            column(6,
              numericInput("loopSize", "Network Size:", 
                          value = 8, min = 6, max = 20, step = 1,
                          width = "100%")
            ),
            column(6,
              numericInput("loopComplexity", "Loop Count:", 
                          value = 2, min = 1, max = 5, step = 1,
                          width = "100%")
            )
          ),
          
          actionButton("generateLoopNetwork", "🎯 Generate Loop Network", 
                      class = "btn-block", 
                      style = "background: rgba(255,255,255,0.9); color: #333; font-weight: bold;"),
          
          br(),
          
          fluidRow(
            column(6,
              actionButton("addRandomLoop", "➕ Add Loop", 
                          class = "btn-secondary btn-sm btn-block",
                          style = "background: rgba(255,255,255,0.7); color: #333;")
            ),
            column(6,
              actionButton("showLoopInfo", "ℹ️ Loop Info", 
                          class = "btn-info btn-sm btn-block",
                          style = "background: rgba(255,255,255,0.7); color: #333;")
            )
          )
        )
      } else {
        div(class = "alert alert-warning", style = "margin: 10px 0; padding: 10px;",
            h6("🔄 Loop Generator Unavailable"),
            p("The loop generator plugin requires loop_generator.R", style = "margin: 0; font-size: 12px;")
        )
      },
      
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
        id = "main_tabs",
        
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
          
          if (UTILS_AVAILABLE) {
            tagList(
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
            )
          } else {
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
          }
        ),
        
        # Loop Analysis Tab
        tabPanel(
          "🔄 Loop Analysis",
          icon = icon("sync-alt"),
          br(),
          
          if (ANALYSIS_AVAILABLE) {
            tagList(
              fluidRow(
                column(12,
                  div(style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
                    h4("🔄 Causal Loop Analysis", style = "margin: 0 0 10px 0;"),
                    p("Analyze feedback loops, system stability, and key pathways in your social-ecological network.", 
                      style = "margin: 0;")
                  )
                )
              ),
              
              fluidRow(
                column(6,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("📋 Analysis Summary", style = "margin-top: 0;"),
                    verbatimTextOutput("loopAnalysisSummary")
                  )
                ),
                column(6,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("📊 System Metrics", style = "margin-top: 0;"),
                    DTOutput("systemMetricsTable")
                  )
                )
              ),
              
              br(),
              
              fluidRow(
                column(12,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("🔁 Feedback Loops Visualization", style = "margin-top: 0;"),
                    plotOutput("loopVisualization", height = "400px")
                  )
                )
              ),
              
              br(),
              
              fluidRow(
                column(6,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("⭐ Node Importance", style = "margin-top: 0;"),
                    DTOutput("nodeImportanceTable")
                  )
                ),
                column(6,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("🎯 Key Pathways", style = "margin-top: 0;"),
                    DTOutput("keyPathwaysTable")
                  )
                )
              ),
              
              br(),
              
              fluidRow(
                column(12,
                  div(style = "border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;",
                    h4("🔍 Loop Details", style = "margin-top: 0;"),
                    DTOutput("loopDetailsTable")
                  )
                )
              ),
              
              br(),
              
              fluidRow(
                column(12,
                  div(style = "text-align: center;",
                    downloadButton("downloadLoopReport", "📥 Download Full Report", 
                                  class = "btn-primary"),
                    " ",
                    downloadButton("downloadAdjMatrix", "📊 Download Adjacency Matrix", 
                                  class = "btn-secondary"),
                    " ",
                    downloadButton("downloadLoopMetrics", "📈 Download All Metrics", 
                                  class = "btn-info")
                  )
                )
              )
            )
          } else {
            div(class = "alert alert-warning", style = "margin: 20px;",
              h4("⚠️ Loop Analysis Unavailable"),
              p("The loop analysis features require the analysis.R file to be present in your project directory."),
              p("To enable loop analysis:"),
              tags$ol(
                tags$li("Download analysis.R from the provided files"),
                tags$li("Place it in the same directory as app.R"),
                tags$li("Restart the application")
              )
            )
          }
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
                  tags$li(strong("Loop Analysis:"), "Click 'Run CLD loop analysis' for feedback loop detection"),
                  tags$li(strong("Analyze Results:"), "Check the Group Analysis and Loop Analysis tabs for insights"),
                  tags$li(strong("Export:"), "Save your network as interactive HTML or download analysis reports")
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
                  tags$li("Run loop analysis to identify feedback mechanisms"),
                  tags$li("Analyze network structure to identify key relationships"),
                  tags$li("Look for system vulnerabilities and leverage points"),
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
  loop_analysis_results <- reactiveVal(NULL)
  
  # Add a Bootstrap tooltip
  bsTooltip("fileType", "Select file format for your network data", placement = "right", trigger = "hover")
  
  # Enhanced debug output
  output$debugInfo <- renderText({
    info <- c()
    
    # System information
    info <- c(info, paste("🤖 AI System:", ifelse(UTILS_AVAILABLE, "Available ✅", "Not Available ❌")))
    info <- c(info, paste("🔄 Loop Analysis:", ifelse(ANALYSIS_AVAILABLE, "Available ✅", "Not Available ❌")))
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
    
    if (!is.null(loop_analysis_results()) && !loop_analysis_results()$error) {
      info <- c(info, paste("🔁 Loops found:", loop_analysis_results()$n_loops))
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

  # Enhanced create graph observer - SIMPLIFIED (removed visualization options)
  observeEvent(input$createGraph, {
    req(links_data())
    data <- links_data()
    xl <- excel()
    
    # Validate data
    if (is.null(data) || nrow(data) == 0) {
      showNotification("❌ No data available for graph creation", type = "error")
      return()
    }
    
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
      
      # Add visual properties with default values
      nodes$Name <- as.character(nodes$id)  # Always show labels
      nodes$shape <- "dot"  # Default shape
      
      # Save nodes
      elements_data(nodes)
      
      # Create edges dataframe with default values
      edges <- data.frame(from = data$from, to = data$to, stringsAsFactors = FALSE)
      edges$width <- if ("weight" %in% names(data)) {
        as.numeric(data$weight)
      } else {
        2  # Default edge width
      }
      edges$arrows <- "to"  # Default arrow style
      edges$color <- if ("edge_color" %in% names(data)) {
        data$edge_color
      } else {
        "gray"  # Default color
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

    # Always add legend if groups are available
    if ("group" %in% colnames(data$nodes)) {
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
  
  # Loop analysis observer
  observeEvent(input$`Run analyses`, {
    req(links_data())
    
    if (!ANALYSIS_AVAILABLE) {
      showNotification("❌ Loop analysis not available - analysis.R file missing", type = "error")
      return()
    }
    
    showNotification("🔄 Starting loop analysis...", type = "default", duration = NULL, id = "loop_notification")
    
    withProgress(message = "Analyzing network loops...", value = 0, {
      incProgress(0.2, detail = "Preparing data...")
      
      # Get current data
      edges <- links_data()
      nodes <- if (!is.null(elements_data())) elements_data() else NULL
      
      incProgress(0.4, detail = "Finding feedback loops...")
      
      # Perform loop analysis
      analysis_results <- perform_loop_analysis(edges, nodes)
      
      incProgress(0.8, detail = "Generating report...")
      
      # Store results
      loop_analysis_results(analysis_results)
      
      incProgress(1.0, detail = "Complete!")
    })
    
    removeNotification("loop_notification")
    
    if (analysis_results$error) {
      showNotification(paste("❌", analysis_results$message), type = "error", duration = 5)
    } else {
      showNotification(
        HTML(paste("✅ <strong>Loop Analysis Complete!</strong><br>",
                  "🔁 Loops found:", ifelse(is.null(analysis_results$n_loops), "N/A", analysis_results$n_loops), "<br>",
                  "📊 System stability:", ifelse(is.null(analysis_results$stable), "N/A", 
                                               ifelse(analysis_results$stable, "Stable", "Unstable")))),
        type = "message", 
        duration = 8
      )
      
      # Switch to loop analysis tab
      updateTabsetPanel(session, "main_tabs", selected = "🔄 Loop Analysis")
    }
  })
  
  # Loop analysis output renderers (unchanged)
  output$loopAnalysisSummary <- renderText({
    req(loop_analysis_results())
    create_loop_report(loop_analysis_results())
  })
  
  output$systemMetricsTable <- renderDT({
    req(loop_analysis_results())
    results <- loop_analysis_results()
    
    if (!results$error && !is.null(results$system_metrics)) {
      metrics_df <- data.frame(
        Metric = c("Nodes", "Edges", "Density", "Mean Degree", "Reciprocity", "Transitivity"),
        Value = c(
          results$system_metrics$nodes,
          results$system_metrics$edges,
          results$system_metrics$density,
          results$system_metrics$mean_degree,
          results$system_metrics$reciprocity,
          results$system_metrics$transitivity
        ),
        Description = c(
          "Total number of nodes in the network",
          "Total number of connections",
          "Fraction of possible connections that exist",
          "Average number of connections per node",
          "Proportion of reciprocal connections",
          "Clustering coefficient"
        ),
        stringsAsFactors = FALSE
      )
      
      # Add modularity if available
      if (!is.null(results$system_metrics$modularity)) {
        metrics_df <- rbind(metrics_df, data.frame(
          Metric = "Modularity",
          Value = results$system_metrics$modularity,
          Description = "Strength of division into groups",
          stringsAsFactors = FALSE
        ))
      }
      
      datatable(metrics_df, 
                options = list(dom = 't', pageLength = 10),
                rownames = FALSE) %>%
        formatRound("Value", 3)
    }
  })
  
  output$nodeImportanceTable <- renderDT({
    req(loop_analysis_results())
    results <- loop_analysis_results()
    
    if (!results$error && !is.null(results$node_metrics)) {
      # Select key columns for display
      display_cols <- c("node", "eigenvector", "betweenness", "page_rank", "loops_involved")
      if ("group" %in% colnames(results$node_metrics)) {
        display_cols <- c(display_cols, "group")
      }
      
      node_table <- results$node_metrics[, display_cols]
      
      datatable(node_table, 
                options = list(pageLength = 10),
                rownames = FALSE) %>%
        formatRound(c("eigenvector", "betweenness", "page_rank"), 3) %>%
        formatStyle(
          'eigenvector',
          background = styleColorBar(node_table$eigenvector, 'lightgreen'),
          backgroundSize = '100% 90%',
          backgroundRepeat = 'no-repeat',
          backgroundPosition = 'center'
        )
    }
  })
  
  output$keyPathwaysTable <- renderDT({
    req(loop_analysis_results())
    results <- loop_analysis_results()
    
    if (!results$error && !is.null(results$top_pathways) && length(results$top_pathways) > 0) {
      pathways_df <- data.frame(
        Pathway = names(results$top_pathways),
        Influence = round(as.numeric(results$top_pathways), 3),
        stringsAsFactors = FALSE
      )
      
      datatable(pathways_df, 
                options = list(pageLength = 10),
                rownames = FALSE) %>%
        formatStyle(
          'Influence',
          background = styleColorBar(pathways_df$Influence, 'lightblue'),
          backgroundSize = '100% 90%',
          backgroundRepeat = 'no-repeat',
          backgroundPosition = 'center'
        )
    }
  })
  
  output$loopDetailsTable <- renderDT({
    req(loop_analysis_results())
    results <- loop_analysis_results()
    
    if (!results$error && !is.null(results$loop_details)) {
      loop_df <- describe_loops(results, max_loops = 50)
      
      if (nrow(loop_df) > 0) {
        datatable(loop_df, 
                  options = list(
                    pageLength = 10,
                    columnDefs = list(
                      list(width = '10%', targets = 0),
                      list(width = '15%', targets = 1),
                      list(width = '10%', targets = 2),
                      list(width = '65%', targets = 3)
                    )
                  ),
                  rownames = FALSE) %>%
          formatStyle(
            'Type',
            backgroundColor = styleEqual(
              c('reinforcing (R)', 'balancing (B)'),
              c('#ffebee', '#e8f5e9')
            )
          )
      }
    }
  })
  
  # Loop visualization
  output$loopVisualization <- renderPlot({
    req(loop_analysis_results())
    results <- loop_analysis_results()
    
    if (!results$error && !is.null(results$adjacency_matrix)) {
      # Create a heatmap of the adjacency matrix
      adj_mat <- results$adjacency_matrix
      
      # Set up the plot
      par(mar = c(10, 10, 4, 2))
      
      # Color palette
      colors <- colorRampPalette(c("white", "lightblue", "darkblue"))(100)
      
      # Create the heatmap
      image(1:ncol(adj_mat), 1:nrow(adj_mat), t(adj_mat)[, nrow(adj_mat):1],
            col = colors,
            xlab = "", ylab = "",
            axes = FALSE,
            main = "Network Adjacency Matrix Heatmap")
      
      # Add labels (limit to first 50 for readability)
      n_labels <- min(50, ncol(adj_mat))
      if (ncol(adj_mat) <= 50) {
        axis(1, at = 1:ncol(adj_mat), labels = colnames(adj_mat), las = 2, cex.axis = 0.7)
        axis(2, at = 1:nrow(adj_mat), labels = rev(rownames(adj_mat)), las = 1, cex.axis = 0.7)
      } else {
        # Sample labels for large networks
        label_idx <- round(seq(1, ncol(adj_mat), length.out = n_labels))
        axis(1, at = label_idx, labels = colnames(adj_mat)[label_idx], las = 2, cex.axis = 0.6)
        axis(2, at = label_idx, labels = rev(rownames(adj_mat))[label_idx], las = 1, cex.axis = 0.6)
      }
      
      # Add grid
      abline(h = seq(0.5, nrow(adj_mat) + 0.5, 1), col = "gray90", lty = 1)
      abline(v = seq(0.5, ncol(adj_mat) + 0.5, 1), col = "gray90", lty = 1)
      
      # Add color legend
      legend("topright", 
             legend = c("No connection", "Weak", "Strong"),
             fill = c("white", "lightblue", "darkblue"),
             bty = "n",
             cex = 0.8)
    } else {
      plot.new()
      text(0.5, 0.5, "No data available for visualization", cex = 1.2, col = "gray")
    }
  })
  
  # Loop analysis download handlers (unchanged)
  output$downloadLoopReport <- downloadHandler(
    filename = function() {
      paste0("loop_analysis_report_", Sys.Date(), ".txt")
    },
    content = function(file) {
      req(loop_analysis_results())
      report <- create_loop_report(loop_analysis_results())
      writeLines(report, file)
    }
  )
  
  output$downloadAdjMatrix <- downloadHandler(
    filename = function() {
      paste0("adjacency_matrix_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(loop_analysis_results())
      results <- loop_analysis_results()
      if (!results$error && !is.null(results$adjacency_matrix)) {
        write.csv(results$adjacency_matrix, file)
      }
    }
  )
  
  output$downloadLoopMetrics <- downloadHandler(
    filename = function() {
      paste0("loop_analysis_metrics_", Sys.Date(), ".zip")
    },
    content = function(file) {
      req(loop_analysis_results())
      results <- loop_analysis_results()
      
      if (!results$error) {
        # Create temporary directory
        temp_dir <- tempdir()
        files_to_zip <- c()
        
        # Save adjacency matrix
        if (!is.null(results$adjacency_matrix)) {
          adj_file <- file.path(temp_dir, "adjacency_matrix.csv")
          write.csv(results$adjacency_matrix, adj_file)
          files_to_zip <- c(files_to_zip, adj_file)
        }
        
        # Save node metrics
        if (!is.null(results$node_metrics)) {
          metrics_file <- file.path(temp_dir, "node_metrics.csv")
          write.csv(results$node_metrics, metrics_file, row.names = FALSE)
          files_to_zip <- c(files_to_zip, metrics_file)
        }
        
        # Save loop details
        if (!is.null(results$loop_details)) {
          loops_file <- file.path(temp_dir, "loop_details.csv")
          loop_df <- describe_loops(results, max_loops = 100)
          write.csv(loop_df, loops_file, row.names = FALSE)
          files_to_zip <- c(files_to_zip, loops_file)
        }
        
        # Save report
        report_file <- file.path(temp_dir, "analysis_report.txt")
        report <- create_loop_report(results)
        writeLines(report, report_file)
        files_to_zip <- c(files_to_zip, report_file)
        
        # Create zip file
        zip(file, files_to_zip, flags = "-j")
      }
    }
  )
  
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
  
  # Loop Network Generator Functions (only if plugin available)
  if (LOOP_GENERATOR_AVAILABLE) {
    
    # Loop Network Generator Observers
    observeEvent(input$generateLoopNetwork, {
      withProgress(message = "🎯 Generating loop network...", value = 0, {
        incProgress(0.3, detail = "Creating network structure...")
        
        # Generate network data using plugin
        network_data <- generate_loop_network(
          template = input$loopTemplate,
          size = input$loopSize,
          complexity = input$loopComplexity,
          add_noise = TRUE
        )
        
        incProgress(0.6, detail = "Applying SES groups...")
        
        # Apply intelligent groups if available
        if (UTILS_AVAILABLE) {
          tryCatch({
            classified_nodes <- assign_multiple_groups(
              network_data$nodes,
              name_column = "id",
              confidence_threshold = 0.3,  # Lower threshold for generated data
              add_confidence = TRUE
            )
            network_data$nodes <- classified_nodes
          }, error = function(e) {
            print(paste("Error in intelligent assignment:", e$message))
          })
        }
        
        incProgress(0.9, detail = "Finalizing visualization...")
        
        # Store the data
        elements_data(network_data$nodes)
        links_data(network_data$edges)
        excel(FALSE)
        
        # Enable buttons
        enable("createNetwork")
        enable("createGraph")
        if (UTILS_AVAILABLE) {
          enable("intelligentAssign")
        }
        enable("Run analyses")
        
        incProgress(1.0, detail = "Complete!")
      })
      
      showNotification(
        HTML(paste("🎯 <strong>Loop Network Generated!</strong><br>",
                  "📊 Template:", network_data$template_name, "<br>",
                  "🔗 Nodes:", input$loopSize, "<br>",
                  "🔄 Loops Created:", network_data$actual_loops, "<br>",
                  "💡 Click 'Create Network' then 'Create Graph' to visualize")),
        type = "message",
        duration = 8
      )
    })
    
    observeEvent(input$addRandomLoop, {
      req(elements_data(), links_data())
      
      nodes <- elements_data()
      edges <- links_data()
      
      if (nrow(nodes) < 3) {
        showNotification("❌ Need at least 3 nodes to create a loop", type = "error")
        return()
      }
      
      # Use plugin function to add random loop
      tryCatch({
        updated_edges <- add_random_loop(nodes, edges)
        
        # Update data
        links_data(updated_edges)
        
        showNotification(
          "➕ Random loop added to network! Update the graph to see changes.",
          type = "message",
          duration = 6
        )
      }, error = function(e) {
        showNotification(paste("❌ Error adding loop:", e$message), type = "error")
      })
    })
    
    observeEvent(input$showLoopInfo, {
      req(elements_data(), links_data())
      
      nodes <- elements_data()
      edges <- links_data()
      
      # Use plugin function to analyze structure
      analysis <- analyze_network_structure(edges, nodes)
      
      showNotification(
        HTML(paste("<strong>🔍 Network Analysis:</strong><br>",
                  gsub("\n", "<br>", analysis$summary), "<br>",
                  "💡 Run 'CLD loop analysis' for detailed loop detection!")),
        type = "default",
        duration = 12
      )
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

        if ("group" %in% colnames(graph_data()$nodes)) {
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
      
      status_parts <- paste("✅ Network ready:", nodes_count, "nodes,", edges_count, "edges")
      
      if ("group_confidence" %in% colnames(graph_data()$nodes)) {
        avg_conf <- round(mean(graph_data()$nodes$group_confidence, na.rm = TRUE), 2)
        status_parts <- paste(status_parts, "| AI Confidence:", avg_conf)
      }
      
      if (!is.null(loop_analysis_results()) && !loop_analysis_results()$error) {
        loops <- loop_analysis_results()$n_loops
        status_parts <- paste(status_parts, "| Loops:", loops)
      }
      
      status_parts
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
if (ANALYSIS_AVAILABLE) {
  cat("✅ Loop analysis: ENABLED\n")
} else {
  cat("⚠️ Loop analysis: DISABLED (analysis.R not found)\n")
}
if (LOOP_GENERATOR_AVAILABLE) {
  cat("✅ Loop network generator: ENABLED\n")
} else {
  cat("⚠️ Loop network generator: DISABLED (loop_generator.R not found)\n")
}
cat("🌐 Starting Shiny server...\n")

shinyApp(ui = ui, server = server)