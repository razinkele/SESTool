# app.R
# Main application file for MarineSABRES SES Shiny Application

# ============================================================================
# LOAD GLOBAL ENVIRONMENT
# ============================================================================

source("global.R", local = TRUE)

# ============================================================================
# SOURCE MODULES
# ============================================================================

source("modules/pims_module.R", local = TRUE)
source("modules/pims_stakeholder_module.R", local = TRUE)
source("modules/isa_data_entry_module.R", local = TRUE)
source("modules/cld_visualization_module.R", local = TRUE)
source("modules/analysis_tools_module.R", local = TRUE)
source("modules/response_module.R", local = TRUE)
# source("modules/response_validation_module.R", local = TRUE)  # Not implemented yet

# ============================================================================
# UI
# ============================================================================

ui <- dashboardPage(
  
  # ========== HEADER ==========
  dashboardHeader(
    title = tags$div(
      tags$img(src = "img/01 marinesabres_logo_transparent.png",
               height = "40px",
               style = "margin-top: -10px; margin-right: 10px;"),
      tags$span("SES Tool", style = "font-size: 18px; vertical-align: middle;")
    ),
    titleWidth = 300,
    
    # User info and help
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        icon("question-circle"),
        "Help",
        onclick = "window.open('user_guide.html', '_blank')"
      )
    ),
    
    tags$li(
      class = "dropdown",
      tags$a(
        href = "#",
        icon("user"),
        textOutput("user_info", inline = TRUE)
      )
    )
  ),
  
  # ========== SIDEBAR ==========
  dashboardSidebar(
    width = 300,
    
    sidebarMenu(
      id = "sidebar_menu",
      
      menuItem(
        "Dashboard",
        tabName = "dashboard",
        icon = icon("dashboard")
      ),
      
      menuItem(
        "PIMS Module",
        tabName = "pims",
        icon = icon("project-diagram"),
        menuSubItem("Project Setup", tabName = "pims_project"),
        menuSubItem("Stakeholders", tabName = "pims_stakeholders"),
        menuSubItem("Resources & Risks", tabName = "pims_resources"),
        menuSubItem("Data Management", tabName = "pims_data"),
        menuSubItem("Evaluation", tabName = "pims_evaluation")
      ),
      
      menuItem(
        "ISA Data Entry",
        tabName = "isa",
        icon = icon("edit")
      ),
      
      menuItem(
        "CLD Visualization",
        tabName = "cld_viz",
        icon = icon("project-diagram")
      ),
      
      menuItem(
        "Analysis Tools",
        tabName = "analysis",
        icon = icon("chart-line"),
        menuSubItem("Network Metrics", tabName = "analysis_metrics"),
        menuSubItem("Loop Detection", tabName = "analysis_loops"),
        menuSubItem("BOT Analysis", tabName = "analysis_bot"),
        menuSubItem("Simplification", tabName = "analysis_simplify")
      ),
      
      menuItem(
        "Response & Validation",
        tabName = "response",
        icon = icon("tasks"),
        menuSubItem("Response Measures", tabName = "response_measures"),
        menuSubItem("Scenario Builder", tabName = "response_scenarios"),
        menuSubItem("Validation", tabName = "response_validation")
      ),
      
      menuItem(
        "Export & Reports",
        tabName = "export",
        icon = icon("download")
      ),
      
      hr(),
      
      # Progress indicator
      div(
        style = "padding: 15px;",
        h5("Project Progress"),
        progressBar(
          id = "project_progress",
          value = 0,
          total = 100,
          display_pct = TRUE,
          status = "info"
        )
      ),
      
      # Quick actions
      div(
        style = "padding: 15px;",
        h5("Quick Actions"),
        actionButton(
          "save_project",
          "Save Project",
          icon = icon("save"),
          class = "btn-primary btn-block"
        ),
        actionButton(
          "load_project",
          "Load Project",
          icon = icon("folder-open"),
          class = "btn-secondary btn-block"
        )
      )
    )
  ),
  
  # ========== BODY ==========
  dashboardBody(
    
    # Custom CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    
    # Enable shinyjs
    useShinyjs(),
    
    tabItems(
      
      # ==================== DASHBOARD ====================
      tabItem(
        tabName = "dashboard",
        
        fluidRow(
          column(12,
            h2("MarineSABRES Social-Ecological Systems Analysis Tool"),
            p("Welcome to the computer-assisted SES creation and analysis platform.")
          )
        ),
        
        fluidRow(
          # Summary boxes
          valueBoxOutput("total_elements_box", width = 3),
          valueBoxOutput("total_connections_box", width = 3),
          valueBoxOutput("loops_detected_box", width = 3),
          valueBoxOutput("completion_box", width = 3)
        ),
        
        fluidRow(
          # Project overview
          box(
            title = "Project Overview",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            uiOutput("project_overview_ui")
          ),
          
          # Quick access
          box(
            title = "Quick Access",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            height = 400,
            h4("Recent Activities"),
            uiOutput("recent_activities_ui")
          )
        ),
        
        fluidRow(
          # Mini CLD preview
          box(
            title = "CLD Preview",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            height = 500,
            visNetworkOutput("dashboard_network_preview", height = "450px")
          )
        )
      ),
      
      # ==================== PIMS MODULE ====================
      tabItem(tabName = "pims_project", pims_project_ui("pims_proj")),
      tabItem(tabName = "pims_stakeholders", pimsStakeholderUI("pims_stake")),
      tabItem(tabName = "pims_resources", pims_resources_ui("pims_res")),
      tabItem(tabName = "pims_data", pims_data_ui("pims_dm")),
      tabItem(tabName = "pims_evaluation", pims_evaluation_ui("pims_eval")),
      
      # ==================== ISA DATA ENTRY ====================
      tabItem(tabName = "isa", isaDataEntryUI("isa_module")),
      
      # ==================== CLD VISUALIZATION ====================
      tabItem(tabName = "cld_viz", cld_viz_ui("cld_visual")),
      
      # ==================== ANALYSIS ====================
      tabItem(tabName = "analysis_metrics", analysis_metrics_ui("analysis_met")),
      tabItem(tabName = "analysis_loops", analysis_loops_ui("analysis_loop")),
      tabItem(tabName = "analysis_bot", analysis_bot_ui("analysis_b")),
      tabItem(tabName = "analysis_simplify", analysis_simplify_ui("analysis_simp")),
      
      # ==================== RESPONSE & VALIDATION ====================
      tabItem(tabName = "response_measures", response_measures_ui("resp_meas")),
      tabItem(tabName = "response_scenarios", response_scenarios_ui("resp_scen")),
      tabItem(tabName = "response_validation", response_validation_ui("resp_val")),
      
      # ==================== EXPORT ====================
      tabItem(
        tabName = "export",
        
        fluidRow(
          column(12,
            h2("Export & Reports"),
            p("Export your data, visualizations, and generate comprehensive reports.")
          )
        ),
        
        fluidRow(
          box(
            title = "Export Data",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            selectInput(
              "export_data_format",
              "Select Format:",
              choices = c("Excel (.xlsx)", "CSV (.csv)", "JSON (.json)", 
                         "R Data (.RData)")
            ),
            
            checkboxGroupInput(
              "export_data_components",
              "Select Components:",
              choices = c(
                "Project Metadata" = "metadata",
                "PIMS Data" = "pims",
                "ISA Data" = "isa_data",
                "CLD Data" = "cld",
                "Analysis Results" = "analysis",
                "Response Measures" = "responses"
              ),
              selected = c("metadata", "isa_data", "cld")
            ),
            
            downloadButton("download_data", "Download Data", 
                          class = "btn-primary")
          ),
          
          box(
            title = "Export Visualizations",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            selectInput(
              "export_viz_format",
              "Select Format:",
              choices = c("PNG (.png)", "SVG (.svg)", "HTML (.html)", 
                         "PDF (.pdf)")
            ),
            
            numericInput(
              "export_viz_width",
              "Width (pixels):",
              value = 1200,
              min = 400,
              max = 4000
            ),
            
            numericInput(
              "export_viz_height",
              "Height (pixels):",
              value = 900,
              min = 300,
              max = 3000
            ),
            
            downloadButton("download_viz", "Download Visualization", 
                          class = "btn-info")
          )
        ),
        
        fluidRow(
          box(
            title = "Generate Report",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            selectInput(
              "report_type",
              "Report Type:",
              choices = c(
                "Executive Summary" = "executive",
                "Technical Report" = "technical",
                "Stakeholder Presentation" = "presentation",
                "Full Project Report" = "full"
              )
            ),
            
            selectInput(
              "report_format",
              "Report Format:",
              choices = c("HTML", "PDF", "Word")
            ),
            
            checkboxInput(
              "report_include_viz",
              "Include Visualizations",
              value = TRUE
            ),
            
            checkboxInput(
              "report_include_data",
              "Include Data Tables",
              value = TRUE
            ),
            
            actionButton(
              "generate_report",
              "Generate Report",
              icon = icon("file-alt"),
              class = "btn-success"
            ),
            
            uiOutput("report_status")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {
  
  # ========== REACTIVE VALUES ==========
  
  # Main project data
  project_data <- reactiveVal(init_session_data())
  
  # User info
  output$user_info <- renderText({
    paste("User:", Sys.info()["user"])
  })
  
  # ========== CALL MODULE SERVERS ==========
  
  # PIMS modules
  pims_project_data <- pims_project_server("pims_proj", project_data)
  pims_stakeholders_data <- pimsStakeholderServer("pims_stake", project_data)
  pims_resources_data <- pims_resources_server("pims_res", project_data)
  pims_data_data <- pims_data_server("pims_dm", project_data)
  pims_evaluation_data <- pims_evaluation_server("pims_eval", project_data)
  
  # ISA data entry module
  isa_data <- isaDataEntryServer("isa_module", project_data)
  
  # CLD visualization
  cld_viz_server("cld_visual", project_data)
  
  # Analysis modules
  analysis_metrics_server("analysis_met", project_data)
  analysis_loops_server("analysis_loop", project_data)
  analysis_bot_server("analysis_b", project_data)
  analysis_simplify_server("analysis_simp", project_data)
  
  # Response & validation modules
  response_measures_server("resp_meas", project_data)
  response_scenarios_server("resp_scen", project_data)
  response_validation_server("resp_val", project_data)
  
  # ========== DASHBOARD ==========
  
  # Value boxes
  output$total_elements_box <- renderValueBox({
    data <- project_data()
    n_elements <- length(unlist(data$data$isa_data))
    
    valueBox(
      n_elements,
      "Total Elements",
      icon = icon("circle"),
      color = "blue"
    )
  })
  
  output$total_connections_box <- renderValueBox({
    data <- project_data()
    # Count non-empty adjacency matrix cells
    n_connections <- 0
    
    valueBox(
      n_connections,
      "Connections",
      icon = icon("arrow-right"),
      color = "green"
    )
  })
  
  output$loops_detected_box <- renderValueBox({
    data <- project_data()
    n_loops <- nrow(data$data$cld$loops %||% data.frame())
    
    valueBox(
      n_loops,
      "Loops Detected",
      icon = icon("refresh"),
      color = "orange"
    )
  })
  
  output$completion_box <- renderValueBox({
    # Calculate completion percentage
    completion <- 0
    
    valueBox(
      paste0(completion, "%"),
      "Completion",
      icon = icon("check-circle"),
      color = "purple"
    )
  })
  
  # Project overview
  output$project_overview_ui <- renderUI({
    data <- project_data()
    
    tagList(
      p(strong("Project ID:"), data$project_id),
      p(strong("Created:"), format_date_display(data$created_at)),
      p(strong("Last Modified:"), format_date_display(data$last_modified)),
      p(strong("Demonstration Area:"), data$data$metadata$da_site %||% "Not set"),
      p(strong("Focal Issue:"), data$data$metadata$focal_issue %||% "Not defined"),
      hr(),
      h4("Status Summary"),
      p("PIMS Setup: ", if(length(data$data$pims) > 0) "Complete" else "Incomplete"),
      p("ISA Data Entry: ", "In Progress"),
      p("CLD Generated: ", if(!is.null(data$data$cld$nodes)) "Yes" else "No")
    )
  })
  
  # Mini CLD preview on dashboard
  output$dashboard_network_preview <- renderVisNetwork({
    req(project_data()$data$cld$nodes)
    
    nodes <- project_data()$data$cld$nodes
    edges <- project_data()$data$cld$edges
    
    visNetwork(nodes, edges, height = "100%") %>%
      visIgraphLayout(layout = "layout_with_fr") %>%
      visOptions(
        highlightNearest = TRUE,
        nodesIdSelection = FALSE
      ) %>%
      visInteraction(
        navigationButtons = FALSE,
        hover = TRUE
      )
  })
  
  # ========== SAVE/LOAD PROJECT ==========
  
  observeEvent(input$save_project, {
    showModal(modalDialog(
      title = "Save Project",
      textInput("save_project_name", "Project Name:", 
               value = project_data()$project_id),
      footer = tagList(
        modalButton("Cancel"),
        downloadButton("confirm_save", "Save")
      )
    ))
  })
  
  output$confirm_save <- downloadHandler(
    filename = function() {
      paste0(input$save_project_name, "_", Sys.Date(), ".rds")
    },
    content = function(file) {
      saveRDS(project_data(), file)
      removeModal()
      showNotification("Project saved successfully!", type = "message")
    }
  )
  
  observeEvent(input$load_project, {
    showModal(modalDialog(
      title = "Load Project",
      fileInput("load_project_file", "Choose RDS File:",
               accept = ".rds"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_load", "Load")
      )
    ))
  })
  
  observeEvent(input$confirm_load, {
    req(input$load_project_file)
    
    loaded_data <- readRDS(input$load_project_file$datapath)
    project_data(loaded_data)
    
    removeModal()
    showNotification("Project loaded successfully!", type = "message")
  })
  
  # ========== EXPORT HANDLERS ==========
  
  output$download_data <- downloadHandler(
    filename = function() {
      format <- input$export_data_format
      ext <- switch(format,
        "Excel (.xlsx)" = ".xlsx",
        "CSV (.csv)" = ".csv",
        "JSON (.json)" = ".json",
        "R Data (.RData)" = ".RData"
      )
      paste0("MarineSABRES_Data_", Sys.Date(), ext)
    },
    content = function(file) {
      data <- project_data()
      components <- input$export_data_components

      # Prepare export data based on selected components
      export_list <- list()

      if("metadata" %in% components) {
        export_list$metadata <- data$data$metadata
        export_list$project_info <- list(
          project_id = data$project_id,
          project_name = data$project_name,
          created_at = data$created_at,
          last_modified = data$last_modified
        )
      }

      if("pims" %in% components) {
        export_list$pims <- data$data$pims
      }

      if("isa_data" %in% components) {
        export_list$goods_benefits <- data$data$isa_data$goods_benefits
        export_list$ecosystem_services <- data$data$isa_data$ecosystem_services
        export_list$marine_processes <- data$data$isa_data$marine_processes
        export_list$pressures <- data$data$isa_data$pressures
        export_list$activities <- data$data$isa_data$activities
        export_list$drivers <- data$data$isa_data$drivers
        export_list$bot_data <- data$data$isa_data$bot_data
      }

      if("cld" %in% components) {
        export_list$cld_nodes <- data$data$cld$nodes
        export_list$cld_edges <- data$data$cld$edges
        export_list$cld_loops <- data$data$cld$loops
      }

      if("analysis" %in% components) {
        export_list$analysis_results <- data$data$analysis
      }

      if("responses" %in% components) {
        export_list$response_measures <- data$data$responses
      }

      # Export based on format
      format <- input$export_data_format

      if(format == "Excel (.xlsx)") {
        wb <- createWorkbook()

        # Add each component as a worksheet
        for(name in names(export_list)) {
          item <- export_list[[name]]
          if(is.data.frame(item) && nrow(item) > 0) {
            addWorksheet(wb, name)
            writeData(wb, name, item)
          } else if(is.list(item) && !is.data.frame(item)) {
            # Convert list to data frame
            df <- as.data.frame(t(unlist(item)), stringsAsFactors = FALSE)
            addWorksheet(wb, name)
            writeData(wb, name, df)
          }
        }

        saveWorkbook(wb, file, overwrite = TRUE)

      } else if(format == "CSV (.csv)") {
        # For CSV, export the main ISA data
        if("isa_data" %in% components && !is.null(data$data$isa_data$goods_benefits)) {
          write.csv(data$data$isa_data$goods_benefits, file, row.names = FALSE)
        } else {
          write.csv(data.frame(message = "No data to export"), file, row.names = FALSE)
        }

      } else if(format == "JSON (.json)") {
        json_data <- toJSON(export_list, pretty = TRUE, auto_unbox = TRUE)
        writeLines(json_data, file)

      } else if(format == "R Data (.RData)") {
        save(export_list, file = file)
      }

      showNotification("Data exported successfully!", type = "message")
    }
  )
  
  output$download_viz <- downloadHandler(
    filename = function() {
      format <- input$export_viz_format
      ext <- switch(format,
        "PNG (.png)" = ".png",
        "SVG (.svg)" = ".svg",
        "HTML (.html)" = ".html",
        "PDF (.pdf)" = ".pdf"
      )
      paste0("MarineSABRES_CLD_", Sys.Date(), ext)
    },
    content = function(file) {
      data <- project_data()

      # Check if CLD data exists
      if(is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
        showNotification("No CLD data to export. Please create a CLD first.", type = "error")
        return(NULL)
      }

      nodes <- data$data$cld$nodes
      edges <- data$data$cld$edges

      format <- input$export_viz_format
      width <- input$export_viz_width
      height <- input$export_viz_height

      if(format == "HTML (.html)") {
        # Create interactive HTML visualization
        viz <- visNetwork(nodes, edges, width = paste0(width, "px"), height = paste0(height, "px")) %>%
          visIgraphLayout(layout = "layout_with_fr") %>%
          visNodes(
            borderWidth = 2,
            font = list(size = 14)
          ) %>%
          visEdges(
            arrows = "to",
            smooth = list(enabled = TRUE, type = "curvedCW")
          ) %>%
          visOptions(
            highlightNearest = list(enabled = TRUE, hover = TRUE),
            nodesIdSelection = TRUE
          ) %>%
          visInteraction(
            navigationButtons = TRUE,
            hover = TRUE,
            zoomView = TRUE
          ) %>%
          visLegend(width = 0.1, position = "right")

        visSave(viz, file)

      } else if(format == "PNG (.png)" || format == "SVG (.svg)" || format == "PDF (.pdf)") {
        # For static exports, create an igraph object and plot
        require(igraph)

        # Create igraph object
        g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)

        # Set vertex attributes
        V(g)$label <- V(g)$label
        V(g)$color <- V(g)$color
        V(g)$size <- 15

        # Set edge attributes
        E(g)$color <- ifelse(edges$link_type == "positive", "#06D6A0", "#E63946")
        E(g)$arrow.size <- 0.5

        # Open appropriate device
        if(format == "PNG (.png)") {
          png(file, width = width, height = height, res = 150)
        } else if(format == "SVG (.svg)") {
          svg(file, width = width/100, height = height/100)
        } else if(format == "PDF (.pdf)") {
          pdf(file, width = width/100, height = height/100)
        }

        # Plot
        par(mar = c(0, 0, 2, 0))
        plot(g,
             layout = layout_with_fr(g),
             vertex.label.cex = 0.8,
             vertex.label.color = "black",
             vertex.frame.color = "gray",
             edge.curved = 0.2,
             main = "MarineSABRES Causal Loop Diagram")

        # Add legend
        legend("bottomright",
               legend = c("Positive link", "Negative link"),
               col = c("#06D6A0", "#E63946"),
               lty = 1, lwd = 2,
               bty = "n")

        dev.off()
      }

      showNotification("Visualization exported successfully!", type = "message")
    }
  )

  # ========== REPORT GENERATION ==========

  # Report status output
  output$report_status <- renderUI({
    tags$div(
      style = "margin-top: 20px;",
      id = "report_status_div"
    )
  })

  # Generate report button
  observeEvent(input$generate_report, {
    # Show progress
    showModal(modalDialog(
      title = "Generating Report",
      "Please wait while your report is being generated...",
      footer = NULL,
      easyClose = FALSE
    ))

    data <- project_data()
    report_type <- input$report_type
    report_format <- input$report_format
    include_viz <- input$report_include_viz
    include_data <- input$report_include_data

    tryCatch({
      # Create a temporary Rmd file
      rmd_file <- tempfile(fileext = ".Rmd")

      # Generate report content based on type
      report_content <- generate_report_content(
        data = data,
        report_type = report_type,
        include_viz = include_viz,
        include_data = include_data
      )

      writeLines(report_content, rmd_file)

      # Render the report
      output_format <- switch(report_format,
        "HTML" = "html_document",
        "PDF" = "pdf_document",
        "Word" = "word_document"
      )

      output_file <- tempfile(fileext = switch(report_format,
        "HTML" = ".html",
        "PDF" = ".pdf",
        "Word" = ".docx"
      ))

      rmarkdown::render(
        input = rmd_file,
        output_format = output_format,
        output_file = output_file,
        quiet = TRUE
      )

      # Copy to downloads or show success
      removeModal()

      showModal(modalDialog(
        title = "Report Generated Successfully",
        tags$div(
          p("Your report has been generated successfully."),
          downloadButton("download_report_file", "Download Report", class = "btn-success")
        ),
        footer = modalButton("Close")
      ))

      # Store output file path for download
      output$download_report_file <- downloadHandler(
        filename = function() {
          paste0("MarineSABRES_Report_", report_type, "_", Sys.Date(),
                 switch(report_format,
                   "HTML" = ".html",
                   "PDF" = ".pdf",
                   "Word" = ".docx"))
        },
        content = function(file) {
          file.copy(output_file, file)
        }
      )

    }, error = function(e) {
      removeModal()
      showNotification(paste("Error generating report:", e$message), type = "error", duration = 10)
    })
  })

}

# ============================================================================
# HELPER FUNCTION FOR REPORT GENERATION
# ============================================================================

generate_report_content <- function(data, report_type, include_viz, include_data) {

  header <- paste0("---\ntitle: 'MarineSABRES SES Analysis Report'\n",
                   "subtitle: '", report_type, " Report'\n",
                   "date: '", format(Sys.Date(), "%B %d, %Y"), "'\n",
                   "output:\n  html_document:\n    toc: true\n    toc_float: true\n",
                   "---\n\n")

  intro <- paste0("# Project Overview\n\n",
                  "**Project:** ", data$project_name, "\n\n",
                  "**Demonstration Area:** ", data$data$metadata$da_site %||% "Not specified", "\n\n",
                  "**Focal Issue:** ", data$data$metadata$focal_issue %||% "Not defined", "\n\n",
                  "**Created:** ", format(data$created_at, "%Y-%m-%d"), "\n\n",
                  "**Last Modified:** ", format(data$last_modified, "%Y-%m-%d"), "\n\n")

  if(report_type == "executive") {
    content <- paste0(
      "# Executive Summary\n\n",
      "This report provides a high-level overview of the social-ecological system analysis.\n\n",
      "## Key Findings\n\n",
      "- System elements identified: ", length(unlist(data$data$isa_data)), "\n",
      "- Feedback loops detected: ", nrow(data$data$cld$loops %||% data.frame()), "\n",
      "- Stakeholders involved: ", nrow(data$data$pims$stakeholders %||% data.frame()), "\n\n"
    )
  } else if(report_type == "technical") {
    content <- paste0(
      "# Technical Analysis\n\n",
      "## DAPSI(W)R(M) Framework Elements\n\n",
      "### Drivers\n\n",
      if(!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$drivers), " drivers in the system.\n\n")
      } else {
        "No drivers data available.\n\n"
      },
      "### Activities\n\n",
      if(!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$activities), " activities.\n\n")
      } else {
        "No activities data available.\n\n"
      },
      "### Pressures\n\n",
      if(!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) {
        paste0("Identified ", nrow(data$data$isa_data$pressures), " pressures.\n\n")
      } else {
        "No pressures data available.\n\n"
      }
    )
  } else if(report_type == "presentation") {
    content <- paste0(
      "# Stakeholder Presentation\n\n",
      "## System Overview\n\n",
      "This analysis examines the social-ecological system in ",
      data$data$metadata$da_site %||% "the study area", ".\n\n",
      "## Key Insights\n\n",
      "- Multiple interconnected system components\n",
      "- Feedback loops influencing system behavior\n",
      "- Management opportunities identified\n\n"
    )
  } else {
    # Full report
    content <- paste0(
      "# Complete System Analysis\n\n",
      "## ISA Data Entry Results\n\n",
      "### Goods and Benefits\n\n",
      if(!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) {
        paste0("```{r echo=FALSE}\n",
               "knitr::kable(head(data$data$isa_data$goods_benefits))\n",
               "```\n\n")
      } else {
        "No data available.\n\n"
      },
      "## Causal Loop Diagram\n\n",
      if(!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
        paste0("The CLD contains ", nrow(data$data$cld$nodes), " nodes and ",
               nrow(data$data$cld$edges %||% data.frame()), " connections.\n\n")
      } else {
        "No CLD generated yet.\n\n"
      },
      "## Stakeholder Analysis\n\n",
      if(!is.null(data$data$pims$stakeholders) && nrow(data$data$pims$stakeholders) > 0) {
        paste0(nrow(data$data$pims$stakeholders), " stakeholders identified.\n\n")
      } else {
        "No stakeholder data available.\n\n"
      }
    )
  }

  footer <- paste0("\n\n---\n\n",
                   "*Report generated by MarineSABRES SES Tool*\n\n",
                   "*", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n")

  return(paste0(header, intro, content, footer))
}

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server)
