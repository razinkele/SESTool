# modules/prepare_report_module.R
# Prepare Report Module
# Purpose: Generate comprehensive analysis reports requiring loop and leverage analyses

# ============================================================================
# UI FUNCTION
# ============================================================================

prepare_report_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        uiOutput(ns("module_header"))
      )
    ),

    hr(),

    fluidRow(
      # Status Panel
      column(6,
        bs4Card(
          title = tagList(icon("check-circle"), " Prerequisites Status"),
          status = "info",
          solidHeader = TRUE,
          width = NULL,

          uiOutput(ns("prerequisite_status"))
        )
      ),

      # Report Configuration
      column(6,
        bs4Card(
          title = tagList(icon("cog"), " Report Configuration"),
          status = "primary",
          solidHeader = TRUE,
          width = NULL,

          textInput(ns("report_title"),
                   "Report Title:",
                   value = "SES Analysis Report"),

          textInput(ns("report_author"),
                   "Author(s):",
                   placeholder = "Enter author name(s)"),

          checkboxGroupInput(ns("report_sections"),
                            "Include Sections:",
                            choices = c(
                              "Executive Summary" = "summary",
                              "ISA Framework" = "isa",
                              "CLD Visualization" = "cld",
                              "Network Metrics" = "metrics",
                              "Loop Analysis" = "loops",
                              "Leverage Points" = "leverage",
                              "Recommendations" = "recommendations"
                            ),
                            selected = c("summary", "isa", "cld", "loops", "leverage"))
        )
      )
    ),

    fluidRow(
      column(12,
        bs4Card(
          title = tagList(icon("file-download"), " Generate Report"),
          status = "success",
          solidHeader = TRUE,
          width = NULL,

          p("Select the report format you wish to generate:"),

          fluidRow(
            column(3,
              actionButton(ns("generate_html"),
                          "HTML Report",
                          icon = icon("globe"),
                          class = "btn-primary btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_pdf"),
                          "PDF Report",
                          icon = icon("file-pdf"),
                          class = "btn-danger btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_word"),
                          "Word Document",
                          icon = icon("file-word"),
                          class = "btn-info btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_ppt"),
                          "PowerPoint",
                          icon = icon("file-powerpoint"),
                          class = "btn-warning btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            )
          ),

          hr(),

          uiOutput(ns("generation_status"))
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

prepare_report_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    # Reactive values for storing report paths
    rv <- reactiveValues(
      html_report_path = NULL,
      pdf_report_path = NULL,
      word_report_path = NULL,
      ppt_report_path = NULL
    )

    # === REACTIVE MODULE HEADER ===
    output$module_header <- renderUI({
      tagList(
        h2(icon("file-alt"), " ", i18n$t("modules.prepare.report.title")),
        p(i18n$t("modules.prepare.report.subtitle")),
        p(strong(i18n$t("modules.prepare.report.requirements_label")), " ", i18n$t("modules.prepare.report.requirements"))
      )
    })

    # Check prerequisites
    check_prerequisites <- reactive({
      data <- project_data_reactive()

      # Check if loop analysis has been performed
      has_loops <- !is.null(data$data$analysis$loops) &&
                   length(data$data$analysis$loops) > 0

      # Check if leverage point analysis has been performed
      has_leverage <- !is.null(data$data$cld$nodes) &&
                      any(data$data$cld$nodes$leverage_score > 0, na.rm = TRUE)

      list(
        loops = has_loops,
        leverage = has_leverage,
        both = has_loops && has_leverage
      )
    })

    # Render prerequisite status
    output$prerequisite_status <- renderUI({
      status <- check_prerequisites()

      tagList(
        tags$div(
          style = "margin-bottom: 15px;",
          icon(if(status$loops) "check-circle" else "times-circle",
               class = if(status$loops) "text-success" else "text-danger",
               style = "font-size: 1.5em;"),
          " ",
          tags$span(
            style = if(status$loops) "color: #28a745;" else "color: #dc3545;",
            strong("Loop Detection Analysis")
          ),
          if (!status$loops) {
            tags$p(style = "margin-left: 30px; color: #666;",
                  "Please complete loop detection analysis before generating report.",
                  tags$br(),
                  actionLink(session$ns("goto_loops"), "Go to Loop Detection →"))
          }
        ),

        tags$div(
          style = "margin-bottom: 15px;",
          icon(if(status$leverage) "check-circle" else "times-circle",
               class = if(status$leverage) "text-success" else "text-danger",
               style = "font-size: 1.5em;"),
          " ",
          tags$span(
            style = if(status$leverage) "color: #28a745;" else "color: #dc3545;",
            strong("Leverage Point Analysis")
          ),
          if (!status$leverage) {
            tags$p(style = "margin-left: 30px; color: #666;",
                  "Please complete leverage point analysis before generating report.",
                  tags$br(),
                  actionLink(session$ns("goto_leverage"), "Go to Leverage Analysis →"))
          }
        ),

        hr(),

        if (status$both) {
          tags$div(
            style = "padding: 15px; background: #d4edda; border-radius: 5px; text-align: center;",
            icon("check-circle", class = "text-success", style = "font-size: 2em;"),
            tags$h4(style = "color: #155724; margin-top: 10px;",
                   "All Prerequisites Met"),
            tags$p(style = "color: #155724;",
                  "You can now generate your comprehensive report.")
          )
        } else {
          tags$div(
            style = "padding: 15px; background: #f8d7da; border-radius: 5px; text-align: center;",
            icon("exclamation-triangle", class = "text-danger", style = "font-size: 2em;"),
            tags$h4(style = "color: #721c24; margin-top: 10px;",
                   "Prerequisites Not Met"),
            tags$p(style = "color: #721c24;",
                  "Complete required analyses to enable report generation.")
          )
        }
      )
    })

    # Navigation links
    observeEvent(input$goto_loops, {
      updateTabItems(session = session$parent, "sidebar_menu", "analysis_loops")
    })

    observeEvent(input$goto_leverage, {
      updateTabItems(session = session$parent, "sidebar_menu", "analysis_leverage")
    })

    # Report generation handlers
    observeEvent(input$generate_html, {
      cat("\n*** PREPARE REPORT MODULE: Generate HTML clicked ***\n")
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          "Please complete both Loop Detection and Leverage Point Analysis before generating a report.",
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_html_report"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()
        cat("[HTML REPORT] Using generate_report_content() from functions/report_generation.R...\n")

        # Use the fixed report generation function from functions/report_generation.R
        report_md <- generate_report_content(
          data = data,
          report_type = "full",  # Use full report type
          include_viz = TRUE,
          include_data = FALSE
        )
        cat("[HTML REPORT] Markdown content generated successfully!\n")

        # Convert markdown to HTML using rmarkdown
        cat("[HTML REPORT] Converting to HTML...\n")
        rmd_file <- tempfile(fileext = ".Rmd")
        writeLines(report_md, rmd_file)

        temp_file <- tempfile(fileext = ".html")
        rmarkdown::render(
          input = rmd_file,
          output_format = "html_document",
          output_file = temp_file,
          quiet = TRUE
        )
        cat("[HTML REPORT] Report rendered to HTML successfully!\n")

        # Copy to www directory so it can be served by Shiny
        www_dir <- file.path(getwd(), "www", "reports")
        if (!dir.exists(www_dir)) {
          dir.create(www_dir, recursive = TRUE)
        }

        # Create unique filename
        report_filename <- paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html")
        www_file <- file.path(www_dir, report_filename)
        file.copy(temp_file, www_file, overwrite = TRUE)

        # Create relative URL for Shiny
        report_url <- paste0("reports/", report_filename)

        # Open in new window using JavaScript
        session$sendCustomMessage(
          type = "openReport",
          message = list(url = report_url)
        )

        showNotification(
          "Report opened in a new window!",
          type = "message",
          duration = 5
        )

        # Store temp file path for download
        rv$html_report_path <- temp_file

      }, error = function(e) {
        showNotification(
          paste("Error generating report:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    observeEvent(input$generate_pdf, {
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          "Please complete both Loop Detection and Leverage Point Analysis before generating a report.",
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_pdf_report"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()

        # Check if LaTeX is available
        latex_available <- tryCatch({
          tinytex::tinytex_root()
          TRUE
        }, error = function(e) {
          # Check system LaTeX
          tryCatch({
            system("pdflatex --version", intern = TRUE, ignore.stderr = TRUE)
            TRUE
          }, error = function(e2) {
            FALSE
          })
        })

        if (!latex_available) {
          # LaTeX not available - show helpful message
          showModal(modalDialog(
            title = "PDF Generation Not Available",
            tags$div(
              tags$p(icon("exclamation-triangle", class = "text-warning", style = "font-size: 2em;")),
              tags$h4("PDF generation requires LaTeX"),
              tags$hr(),
              tags$p("PDF reports require a LaTeX distribution. You have two options:"),
              tags$h5("Option 1: Install TinyTeX (Recommended)"),
              tags$p("Run these commands in R:"),
              tags$pre("install.packages('tinytex')\ntinytex::install_tinytex()"),
              tags$h5("Option 2: Use HTML Report"),
              tags$p("Generate an HTML report instead, which you can:"),
              tags$ul(
                tags$li("View in your browser"),
                tags$li("Print to PDF using your browser's print function (Ctrl+P → Save as PDF)")
              )
            ),
            footer = tagList(
              actionButton(session$ns("generate_html_instead"), "Generate HTML Report Instead",
                          class = "btn-primary"),
              modalButton("Cancel")
            ),
            easyClose = TRUE,
            size = "l"
          ))
          return()
        }

        # Generate markdown content
        report_md <- generate_report_content(
          data = data,
          report_type = "full",
          include_viz = TRUE,
          include_data = FALSE
        )

        # Render to PDF
        rmd_file <- tempfile(fileext = ".Rmd")
        writeLines(report_md, rmd_file)

        temp_pdf <- tempfile(fileext = ".pdf")
        rmarkdown::render(
          input = rmd_file,
          output_format = "pdf_document",
          output_file = temp_pdf,
          quiet = FALSE
        )

        showModal(modalDialog(
          title = "PDF Report Generated Successfully",
          tags$p("Your PDF report has been generated successfully."),
          footer = tagList(
            downloadButton(session$ns("download_pdf"), "Download Report"),
            modalButton("Close")
          ),
          easyClose = TRUE,
          size = "m"
        ))

        rv$pdf_report_path <- temp_pdf

      }, error = function(e) {
        showNotification(
          paste("Error generating PDF report:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Handler for "Generate HTML Instead" button in PDF error modal
    observeEvent(input$generate_html_instead, {
      removeModal()
      # Trigger HTML generation
      shinyjs::click("generate_html")
    })

    observeEvent(input$generate_word, {
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          "Please complete both Loop Detection and Leverage Point Analysis before generating a report.",
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_word_document"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()

        # Check if officer package is available
        if (requireNamespace("officer", quietly = TRUE) && requireNamespace("flextable", quietly = TRUE)) {

          temp_docx <- tempfile(fileext = ".docx")

          # Generate Word document
          generate_word_report(
            data = data,
            title = input$report_title,
            author = input$report_author,
            sections = input$report_sections,
            output_file = temp_docx
          )

          showModal(modalDialog(
            title = "Word Report Generated Successfully",
            tags$p("Your Word document has been generated successfully."),
            tags$p(tags$strong("File location:"), temp_docx),
            footer = tagList(
              downloadButton(session$ns("download_word"), "Download Report"),
              modalButton("Close")
            ),
            easyClose = TRUE,
            size = "m"
          ))

          rv$word_report_path <- temp_docx

        } else {
          showNotification(
            "Word generation requires the 'officer' and 'flextable' packages. Please install them.",
            type = "warning",
            duration = 10
          )
        }

      }, error = function(e) {
        showNotification(
          paste("Error generating Word report:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    observeEvent(input$generate_ppt, {
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          "Please complete both Loop Detection and Leverage Point Analysis before generating a report.",
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_powerpoint"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()

        # Check if officer package is available
        if (requireNamespace("officer", quietly = TRUE)) {

          temp_pptx <- tempfile(fileext = ".pptx")

          # Generate PowerPoint presentation
          generate_ppt_report(
            data = data,
            title = input$report_title,
            author = input$report_author,
            sections = input$report_sections,
            output_file = temp_pptx
          )

          showModal(modalDialog(
            title = "PowerPoint Report Generated Successfully",
            tags$p("Your PowerPoint presentation has been generated successfully."),
            tags$p(tags$strong("File location:"), temp_pptx),
            footer = tagList(
              downloadButton(session$ns("download_ppt"), "Download Report"),
              modalButton("Close")
            ),
            easyClose = TRUE,
            size = "m"
          ))

          rv$ppt_report_path <- temp_pptx

        } else {
          showNotification(
            "PowerPoint generation requires the 'officer' package. Please install it.",
            type = "warning",
            duration = 10
          )
        }

      }, error = function(e) {
        showNotification(
          paste("Error generating PowerPoint report:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Generation status
    output$generation_status <- renderUI({
      tags$div(
        style = "padding: 10px; background: #e7f3ff; border-radius: 5px;",
        icon("info-circle"),
        " ",
        "Report generation will compile all your analyses into a comprehensive document.",
        tags$br(),
        tags$small("Processing may take 30-60 seconds depending on model complexity.")
      )
    })

    # Download handler for HTML report
    output$download_html <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".html")
      },
      content = function(file) {
        file.copy(rv$html_report_path, file)
      }
    )

    # Download handler for HTML fallback
    output$download_html_fallback <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".html")
      },
      content = function(file) {
        file.copy(rv$html_report_path, file)
      }
    )

    # Download handler for PDF report
    output$download_pdf <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".pdf")
      },
      content = function(file) {
        file.copy(rv$pdf_report_path, file)
      }
    )

    # Download handler for Word report
    output$download_word <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".docx")
      },
      content = function(file) {
        file.copy(rv$word_report_path, file)
      }
    )

    # Download handler for PowerPoint report
    output$download_ppt <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".pptx")
      },
      content = function(file) {
        file.copy(rv$ppt_report_path, file)
      }
    )
  })
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Generate HTML Report
#'
#' Creates a comprehensive HTML report from project data
#'
#' @param data Project data list
#' @param title Report title
#' @param author Report author
#' @param sections Vector of sections to include
#' @return HTML string
# Helper: generate an HTML table for a DAPSI(W)R(M) element data frame
.element_html_table <- function(df, heading) {
  if (is.null(df) || nrow(df) == 0) return(character(0))
  rows <- vapply(seq_len(nrow(df)), function(i) {
    id_val   <- as.character(df$ID[i])[1]
    name_val <- as.character(df$Name[i])[1]
    desc     <- if (!is.null(df$Description) && !is.na(df$Description[i]))
                  as.character(df$Description[i])[1] else ""
    paste0("    <tr><td>", id_val, "</td><td>", name_val, "</td><td>", desc, "</td></tr>")
  }, character(1))
  c(paste0("  <h3>", heading, "</h3>"),
    "  <table>",
    "    <tr><th>ID</th><th>Name</th><th>Description</th></tr>",
    rows,
    "  </table>")
}

generate_html_report <- function(data, title, author, sections) {

  # Safely convert title and author to character strings
  title <- as.character(title)[1]
  author <- if (!is.null(author)) as.character(author)[1] else ""

  # Safely convert sections to character vector
  sections <- as.character(sections)

  cat("  [gen_html] Function called\n")
  cat("  [gen_html] Title:", title, "class:", class(title), "\n")
  cat("  [gen_html] Author:", author, "class:", class(author), "\n")
  cat("  [gen_html] Sections:", paste(sections, collapse = ", "), "class:", class(sections), "\n")
  flush.console()

  # Start HTML document
  html <- c(
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "  <meta charset='utf-8'>",
    paste0("  <title>", title, "</title>"),
    "  <style>",
    "    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }",
    "    h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }",
    "    h2 { color: #34495e; margin-top: 30px; border-bottom: 2px solid #95a5a6; padding-bottom: 5px; }",
    "    h3 { color: #7f8c8d; margin-top: 20px; }",
    "    table { border-collapse: collapse; width: 100%; margin: 20px 0; }",
    "    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }",
    "    th { background-color: #3498db; color: white; }",
    "    tr:nth-child(even) { background-color: #f2f2f2; }",
    "    .info-box { background: #e8f4f8; border-left: 4px solid #3498db; padding: 15px; margin: 20px 0; }",
    "    .warning-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }",
    "    .positive { color: #27ae60; font-weight: bold; }",
    "    .negative { color: #e74c3c; font-weight: bold; }",
    "    .metadata { color: #7f8c8d; font-size: 0.9em; margin-bottom: 30px; }",
    "  </style>",
    "</head>",
    "<body>",
    paste0("  <h1>", title, "</h1>")
  )

  # Add metadata
  if (!is.null(author) && nchar(author) > 0) {
    html <- c(html, paste0("  <p class='metadata'><strong>Author:</strong> ", author, "</p>"))
  }
  html <- c(html, paste0("  <p class='metadata'><strong>Generated:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>"))

  # Executive Summary
  if ("summary" %in% sections) {
    cat("  [gen_html] Processing summary section...\n")
    flush.console()

    # Extract project name with explicit null checking and type conversion
    project_name <- tryCatch({
      if (!is.null(data$data$metadata$project_name)) {
        as.character(data$data$metadata$project_name)[1]
      } else {
        "Unnamed Project"
      }
    }, error = function(e) {
      cat("  [gen_html] ERROR extracting project_name:", e$message, "\n")
      "Unnamed Project"
    })

    cat("  [gen_html] project_name:", project_name, "class:", class(project_name), "\n")
    flush.console()

    html <- c(html,
      "  <h2>Executive Summary</h2>",
      "  <div class='info-box'>",
      paste0("    <p>This report presents a comprehensive analysis of the Social-Ecological System: <strong>",
             project_name, "</strong></p>")
    )

    # Count elements with explicit null checking
    cat("  [gen_html] Counting ISA elements...\n")
    flush.console()

    n_drivers <- if (!is.null(data$data$isa_data$drivers)) as.integer(nrow(data$data$isa_data$drivers)) else 0L
    n_activities <- if (!is.null(data$data$isa_data$activities)) as.integer(nrow(data$data$isa_data$activities)) else 0L
    n_pressures <- if (!is.null(data$data$isa_data$pressures)) as.integer(nrow(data$data$isa_data$pressures)) else 0L
    n_marine <- if (!is.null(data$data$isa_data$marine_processes)) as.integer(nrow(data$data$isa_data$marine_processes)) else 0L
    n_ecosystem <- if (!is.null(data$data$isa_data$ecosystem_services)) as.integer(nrow(data$data$isa_data$ecosystem_services)) else 0L
    n_goods <- if (!is.null(data$data$isa_data$goods_benefits)) as.integer(nrow(data$data$isa_data$goods_benefits)) else 0L
    n_responses <- if (!is.null(data$data$isa_data$responses)) as.integer(nrow(data$data$isa_data$responses)) else 0L

    n_elements <- as.integer(n_drivers + n_activities + n_pressures + n_marine + n_ecosystem + n_goods + n_responses)
    n_nodes <- if (!is.null(data$data$cld$nodes)) as.integer(nrow(data$data$cld$nodes)) else 0L
    n_edges <- if (!is.null(data$data$cld$edges)) as.integer(nrow(data$data$cld$edges)) else 0L
    n_loops <- if (!is.null(data$data$analysis$loops)) as.integer(length(data$data$analysis$loops)) else 0L

    cat("  [gen_html] n_elements:", n_elements, "class:", class(n_elements), "\n")
    cat("  [gen_html] n_nodes:", n_nodes, "class:", class(n_nodes), "\n")
    cat("  [gen_html] n_edges:", n_edges, "class:", class(n_edges), "\n")
    cat("  [gen_html] n_loops:", n_loops, "class:", class(n_loops), "\n")
    flush.console()

    cat("  [gen_html] Building summary HTML with paste0...\n")
    flush.console()

    html <- c(html,
      paste0("    <p><strong>Total Elements:</strong> ", as.character(n_elements), "</p>"),
      paste0("    <p><strong>CLD Nodes:</strong> ", as.character(n_nodes), "</p>"),
      paste0("    <p><strong>CLD Edges:</strong> ", as.character(n_edges), "</p>"),
      paste0("    <p><strong>Feedback Loops Detected:</strong> ", as.character(n_loops), "</p>"),
      "  </div>"
    )

    cat("  [gen_html] Summary section completed\n")
    flush.console()
  }

  # ISA Framework
  if ("isa" %in% sections) {
    cat("  [gen_html] Processing ISA Framework section...\n")
    flush.console()

    html <- c(html, "  <h2>ISA Framework (DAPSIWRM)</h2>")

    # DAPSI(W)R(M) element tables
    element_tables <- list(
      list(df = data$data$isa_data$drivers,            heading = "Drivers"),
      list(df = data$data$isa_data$activities,         heading = "Activities"),
      list(df = data$data$isa_data$pressures,          heading = "Pressures"),
      list(df = data$data$isa_data$marine_processes,   heading = "Marine Processes & Functions"),
      list(df = data$data$isa_data$ecosystem_services, heading = "Ecosystem Services"),
      list(df = data$data$isa_data$goods_benefits,     heading = "Goods & Benefits"),
      list(df = data$data$isa_data$responses,          heading = "Responses")
    )
    for (tbl in element_tables) {
      html <- c(html, .element_html_table(tbl$df, tbl$heading))
    }

  }

  # Loop Analysis
  if ("loops" %in% sections && !is.null(data$data$analysis$loops)) {
    html <- c(html, "  <h2>Feedback Loop Analysis</h2>")

    loops <- data$data$analysis$loops
    if (length(loops) > 0) {
      html <- c(html, paste0("  <p>Detected <strong>", length(loops), "</strong> feedback loops in the system:</p>"))

      # Count by type
      n_reinforcing <- sum(sapply(loops, function(l) l$type == "reinforcing"))
      n_balancing <- sum(sapply(loops, function(l) l$type == "balancing"))

      html <- c(html,
        "  <div class='info-box'>",
        paste0("    <p><strong>Reinforcing Loops:</strong> ", n_reinforcing, " (amplifying changes)</p>"),
        paste0("    <p><strong>Balancing Loops:</strong> ", n_balancing, " (stabilizing system)</p>"),
        "  </div>",
        "  <h3>Loop Details</h3>",
        "  <table>",
        "    <tr><th>Loop ID</th><th>Type</th><th>Length</th><th>Nodes</th></tr>"
      )

      for (i in 1:length(loops)) {
        loop <- loops[[i]]
        nodes_str <- paste(loop$nodes, collapse=" → ")
        html <- c(html,
          paste0("    <tr>",
                 "<td>Loop ", i, "</td>",
                 "<td class='", if(loop$type == "reinforcing") "positive" else "negative", "'>",
                 toupper(loop$type), "</td>",
                 "<td>", length(loop$nodes), "</td>",
                 "<td>", nodes_str, "</td>",
                 "</tr>")
        )
      }
      html <- c(html, "  </table>")
    }
  }

  # Leverage Points
  if ("leverage" %in% sections && !is.null(data$data$cld$nodes)) {
    html <- c(html, "  <h2>Leverage Point Analysis</h2>")

    nodes <- data$data$cld$nodes
    nodes_with_leverage <- nodes[nodes$leverage_score > 0, ]

    if (nrow(nodes_with_leverage) > 0) {
      # Sort by leverage score
      nodes_with_leverage <- nodes_with_leverage[order(-nodes_with_leverage$leverage_score), ]

      html <- c(html,
        "  <p>Identified key leverage points in the system based on network centrality metrics:</p>",
        "  <table>",
        "    <tr><th>Rank</th><th>Node</th><th>Leverage Score</th><th>In-Degree</th><th>Out-Degree</th><th>Betweenness</th></tr>"
      )

      for (i in 1:min(20, nrow(nodes_with_leverage))) {
        node <- nodes_with_leverage[i, ]

        # Extract metrics with explicit null checking
        in_deg <- if (!is.null(node$in_degree) && !is.na(node$in_degree)) node$in_degree else 0
        out_deg <- if (!is.null(node$out_degree) && !is.na(node$out_degree)) node$out_degree else 0
        between <- if (!is.null(node$betweenness) && !is.na(node$betweenness)) round(node$betweenness, 2) else 0

        html <- c(html,
          paste0("    <tr>",
                 "<td>", i, "</td>",
                 "<td><strong>", node$label, "</strong></td>",
                 "<td>", round(node$leverage_score, 2), "</td>",
                 "<td>", in_deg, "</td>",
                 "<td>", out_deg, "</td>",
                 "<td>", between, "</td>",
                 "</tr>")
        )
      }
      html <- c(html, "  </table>")

      # Interpretation
      html <- c(html,
        "  <div class='info-box'>",
        "    <h4>Interpretation</h4>",
        "    <p>Leverage points represent nodes with high influence in the system. Interventions at these points may have cascading effects throughout the network.</p>",
        "    <ul>",
        "      <li><strong>High In-Degree:</strong> Affected by many other factors</li>",
        "      <li><strong>High Out-Degree:</strong> Influences many other factors</li>",
        "      <li><strong>High Betweenness:</strong> Acts as a bridge between system components</li>",
        "    </ul>",
        "  </div>"
      )
    }
  }

  # Recommendations
  if ("recommendations" %in% sections) {
    html <- c(html,
      "  <h2>Recommendations</h2>",
      "  <p>Based on the analysis, consider the following management strategies:</p>",
      "  <ol>",
      "    <li><strong>Target High-Leverage Nodes:</strong> Focus interventions on nodes with highest leverage scores for maximum impact.</li>",
      "    <li><strong>Monitor Feedback Loops:</strong> Pay special attention to reinforcing loops that can amplify changes.</li>",
      "    <li><strong>Address Root Causes:</strong> Identify and address drivers at the beginning of causal chains.</li>",
      "    <li><strong>Build Resilience:</strong> Strengthen balancing loops to improve system stability.</li>",
      "    <li><strong>Stakeholder Engagement:</strong> Involve stakeholders associated with key leverage points.</li>",
      "  </ol>"
    )
  }

  # Close HTML
  html <- c(html,
    "  <hr>",
    "  <p class='metadata'>This report was generated using the Marine SABRES SES Toolbox</p>",
    "</body>",
    "</html>"
  )

  return(paste(html, collapse = "\n"))
}

#' Generate Word Report
#'
#' Creates a comprehensive Word document from project data
#'
#' @param data Project data list
#' @param title Report title
#' @param author Report author
#' @param sections Vector of sections to include
#' @param output_file Output file path
generate_word_report <- function(data, title, author, sections, output_file) {

  # Safely convert title and author to character strings
  title <- as.character(title)[1]
  author <- if (!is.null(author)) as.character(author)[1] else ""

  # Create a new Word document
  doc <- officer::read_docx()

  # Add title
  doc <- officer::body_add_par(doc, title, style = "heading 1")

  # Add metadata
  if (!is.null(author) && nchar(author) > 0) {
    doc <- officer::body_add_par(doc, paste("Author:", author), style = "Normal")
  }
  doc <- officer::body_add_par(doc, paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), style = "Normal")
  doc <- officer::body_add_par(doc, "", style = "Normal")  # Empty line

  # Executive Summary
  if ("summary" %in% sections) {
    doc <- officer::body_add_par(doc, "Executive Summary", style = "heading 2")

    project_name <- if (!is.null(data$data$metadata$project_name)) data$data$metadata$project_name else "Unnamed Project"
    doc <- officer::body_add_par(doc, paste("This report presents a comprehensive analysis of the Social-Ecological System:", project_name), style = "Normal")

    # Count elements
    n_drivers <- if (!is.null(data$data$isa_data$drivers)) nrow(data$data$isa_data$drivers) else 0
    n_activities <- if (!is.null(data$data$isa_data$activities)) nrow(data$data$isa_data$activities) else 0
    n_pressures <- if (!is.null(data$data$isa_data$pressures)) nrow(data$data$isa_data$pressures) else 0
    n_marine <- if (!is.null(data$data$isa_data$marine_processes)) nrow(data$data$isa_data$marine_processes) else 0
    n_ecosystem <- if (!is.null(data$data$isa_data$ecosystem_services)) nrow(data$data$isa_data$ecosystem_services) else 0
    n_goods <- if (!is.null(data$data$isa_data$goods_benefits)) nrow(data$data$isa_data$goods_benefits) else 0
    n_responses <- if (!is.null(data$data$isa_data$responses)) nrow(data$data$isa_data$responses) else 0

    n_elements <- n_drivers + n_activities + n_pressures + n_marine + n_ecosystem + n_goods + n_responses
    n_nodes <- if (!is.null(data$data$cld$nodes)) nrow(data$data$cld$nodes) else 0
    n_edges <- if (!is.null(data$data$cld$edges)) nrow(data$data$cld$edges) else 0
    n_loops <- if (!is.null(data$data$analysis$loops)) length(data$data$analysis$loops) else 0

    doc <- officer::body_add_par(doc, paste("Total Elements:", n_elements), style = "Normal")
    doc <- officer::body_add_par(doc, paste("CLD Nodes:", n_nodes), style = "Normal")
    doc <- officer::body_add_par(doc, paste("CLD Edges:", n_edges), style = "Normal")
    doc <- officer::body_add_par(doc, paste("Feedback Loops Detected:", n_loops), style = "Normal")
    doc <- officer::body_add_par(doc, "", style = "Normal")
  }

  # ISA Framework
  if ("isa" %in% sections) {
    doc <- officer::body_add_par(doc, "ISA Framework (DAPSIWRM)", style = "heading 2")

    # Drivers
    if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) {
      doc <- officer::body_add_par(doc, "Drivers", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$drivers[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Activities
    if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) {
      doc <- officer::body_add_par(doc, "Activities", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$activities[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Pressures
    if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) {
      doc <- officer::body_add_par(doc, "Pressures", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$pressures[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Marine Processes
    if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) {
      doc <- officer::body_add_par(doc, "Marine Processes & Functions", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$marine_processes[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Ecosystem Services
    if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) {
      doc <- officer::body_add_par(doc, "Ecosystem Services", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$ecosystem_services[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Goods & Benefits
    if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) {
      doc <- officer::body_add_par(doc, "Goods & Benefits", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$goods_benefits[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

    # Responses
    if (!is.null(data$data$isa_data$responses) && nrow(data$data$isa_data$responses) > 0) {
      doc <- officer::body_add_par(doc, "Responses", style = "heading 3")
      if (requireNamespace("flextable", quietly = TRUE)) {
        ft <- flextable::flextable(data$data$isa_data$responses[, c("ID", "Name", "Description")])
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }

  }

  # Loop Analysis
  if ("loops" %in% sections && !is.null(data$data$analysis$loops)) {
    doc <- officer::body_add_par(doc, "Feedback Loop Analysis", style = "heading 2")

    loops <- data$data$analysis$loops
    if (length(loops) > 0) {
      doc <- officer::body_add_par(doc, paste("Detected", length(loops), "feedback loops in the system:"), style = "Normal")

      # Count by type
      n_reinforcing <- sum(sapply(loops, function(l) l$type == "reinforcing"))
      n_balancing <- sum(sapply(loops, function(l) l$type == "balancing"))

      doc <- officer::body_add_par(doc, paste("Reinforcing Loops:", n_reinforcing, "(amplifying changes)"), style = "Normal")
      doc <- officer::body_add_par(doc, paste("Balancing Loops:", n_balancing, "(stabilizing system)"), style = "Normal")
      doc <- officer::body_add_par(doc, "", style = "Normal")

      # Loop details table
      if (requireNamespace("flextable", quietly = TRUE)) {
        loop_df <- data.frame(
          Loop_ID = paste("Loop", 1:length(loops)),
          Type = toupper(sapply(loops, function(l) l$type)),
          Length = sapply(loops, function(l) length(l$nodes)),
          Nodes = sapply(loops, function(l) paste(l$nodes, collapse = " → "))
        )
        ft <- flextable::flextable(loop_df)
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }
  }

  # Leverage Points
  if ("leverage" %in% sections && !is.null(data$data$cld$nodes)) {
    doc <- officer::body_add_par(doc, "Leverage Point Analysis", style = "heading 2")

    nodes <- data$data$cld$nodes
    nodes_with_leverage <- nodes[nodes$leverage_score > 0, ]

    if (nrow(nodes_with_leverage) > 0) {
      # Sort by leverage score
      nodes_with_leverage <- nodes_with_leverage[order(-nodes_with_leverage$leverage_score), ]

      doc <- officer::body_add_par(doc, "Identified key leverage points in the system based on network centrality metrics:", style = "Normal")

      if (requireNamespace("flextable", quietly = TRUE)) {
        # Extract top nodes with explicit null checking
        n_top <- min(20, nrow(nodes_with_leverage))
        top_nodes <- nodes_with_leverage[1:n_top, ]

        # Extract metrics with null checking
        in_degrees <- if (!is.null(top_nodes$in_degree)) top_nodes$in_degree else rep(0, n_top)
        out_degrees <- if (!is.null(top_nodes$out_degree)) top_nodes$out_degree else rep(0, n_top)
        betweenness_vals <- if (!is.null(top_nodes$betweenness)) round(top_nodes$betweenness, 2) else rep(0, n_top)

        leverage_df <- data.frame(
          Rank = 1:n_top,
          Node = top_nodes$label,
          Leverage_Score = round(top_nodes$leverage_score, 2),
          In_Degree = in_degrees,
          Out_Degree = out_degrees,
          Betweenness = betweenness_vals
        )
        ft <- flextable::flextable(leverage_df)
        ft <- flextable::theme_vanilla(ft)
        doc <- flextable::body_add_flextable(doc, ft)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }
  }

  # Recommendations
  if ("recommendations" %in% sections) {
    doc <- officer::body_add_par(doc, "Recommendations", style = "heading 2")
    doc <- officer::body_add_par(doc, "Based on the analysis, consider the following management strategies:", style = "Normal")
    doc <- officer::body_add_par(doc, "1. Target High-Leverage Nodes: Focus interventions on nodes with highest leverage scores for maximum impact.", style = "Normal")
    doc <- officer::body_add_par(doc, "2. Monitor Feedback Loops: Pay special attention to reinforcing loops that can amplify changes.", style = "Normal")
    doc <- officer::body_add_par(doc, "3. Address Root Causes: Identify and address drivers at the beginning of causal chains.", style = "Normal")
    doc <- officer::body_add_par(doc, "4. Build Resilience: Strengthen balancing loops to improve system stability.", style = "Normal")
    doc <- officer::body_add_par(doc, "5. Stakeholder Engagement: Involve stakeholders associated with key leverage points.", style = "Normal")
    doc <- officer::body_add_par(doc, "", style = "Normal")
  }

  # Footer
  doc <- officer::body_add_par(doc, "This report was generated using the Marine SABRES SES Toolbox", style = "Normal")

  # Save document
  print(doc, target = output_file)
}

#' Generate PowerPoint Report
#'
#' Creates a comprehensive PowerPoint presentation from project data
#'
#' @param data Project data list
#' @param title Report title
#' @param author Report author
#' @param sections Vector of sections to include
#' @param output_file Output file path
generate_ppt_report <- function(data, title, author, sections, output_file) {

  # Safely convert title and author to character strings
  title <- as.character(title)[1]
  author <- if (!is.null(author)) as.character(author)[1] else ""

  # Create a new PowerPoint presentation
  ppt <- officer::read_pptx()

  # Title slide
  ppt <- officer::add_slide(ppt, layout = "Title Slide", master = "Office Theme")
  ppt <- officer::ph_with(ppt, value = as.character(title), location = officer::ph_location_type(type = "ctrTitle"))
  if (!is.null(author) && nchar(author) > 0) {
    ppt <- officer::ph_with(ppt, value = as.character(paste("Author:", author)), location = officer::ph_location_type(type = "subTitle"))
  }

  # Executive Summary
  if ("summary" %in% sections) {
    ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
    ppt <- officer::ph_with(ppt, value = "Executive Summary", location = officer::ph_location_type(type = "title"))

    # Count elements
    n_drivers <- if (!is.null(data$data$isa_data$drivers)) nrow(data$data$isa_data$drivers) else 0
    n_activities <- if (!is.null(data$data$isa_data$activities)) nrow(data$data$isa_data$activities) else 0
    n_pressures <- if (!is.null(data$data$isa_data$pressures)) nrow(data$data$isa_data$pressures) else 0
    n_marine <- if (!is.null(data$data$isa_data$marine_processes)) nrow(data$data$isa_data$marine_processes) else 0
    n_ecosystem <- if (!is.null(data$data$isa_data$ecosystem_services)) nrow(data$data$isa_data$ecosystem_services) else 0
    n_goods <- if (!is.null(data$data$isa_data$goods_benefits)) nrow(data$data$isa_data$goods_benefits) else 0
    n_responses <- if (!is.null(data$data$isa_data$responses)) nrow(data$data$isa_data$responses) else 0

    n_elements <- n_drivers + n_activities + n_pressures + n_marine + n_ecosystem + n_goods + n_responses

    project_name <- if (!is.null(data$data$metadata$project_name)) data$data$metadata$project_name else "Unnamed Project"
    n_nodes <- if (!is.null(data$data$cld$nodes)) nrow(data$data$cld$nodes) else 0
    n_edges <- if (!is.null(data$data$cld$edges)) nrow(data$data$cld$edges) else 0
    n_loops <- if (!is.null(data$data$analysis$loops)) length(data$data$analysis$loops) else 0

    summary_text <- paste(
      paste("Project:", project_name),
      paste("Total Elements:", n_elements),
      paste("CLD Nodes:", n_nodes),
      paste("CLD Edges:", n_edges),
      paste("Feedback Loops:", n_loops),
      sep = "\n"
    )

    ppt <- officer::ph_with(ppt, value = as.character(summary_text), location = officer::ph_location_type(type = "body"))
  }

  # ISA Framework slides
  if ("isa" %in% sections) {
    # Drivers
    if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Drivers", location = officer::ph_location_type(type = "title"))

      drivers_text <- paste(paste("-", as.character(data$data$isa_data$drivers$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(drivers_text), location = officer::ph_location_type(type = "body"))
    }

    # Activities
    if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Activities", location = officer::ph_location_type(type = "title"))

      activities_text <- paste(paste("-", as.character(data$data$isa_data$activities$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(activities_text), location = officer::ph_location_type(type = "body"))
    }

    # Pressures
    if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Pressures", location = officer::ph_location_type(type = "title"))

      pressures_text <- paste(paste("-", as.character(data$data$isa_data$pressures$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(pressures_text), location = officer::ph_location_type(type = "body"))
    }

    # Marine Processes
    if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Marine Processes & Functions", location = officer::ph_location_type(type = "title"))

      marine_text <- paste(paste("-", as.character(data$data$isa_data$marine_processes$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(marine_text), location = officer::ph_location_type(type = "body"))
    }

    # Ecosystem Services
    if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Ecosystem Services", location = officer::ph_location_type(type = "title"))

      ecosystem_text <- paste(paste("-", as.character(data$data$isa_data$ecosystem_services$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(ecosystem_text), location = officer::ph_location_type(type = "body"))
    }

    # Goods & Benefits
    if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Goods & Benefits", location = officer::ph_location_type(type = "title"))

      goods_text <- paste(paste("-", as.character(data$data$isa_data$goods_benefits$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(goods_text), location = officer::ph_location_type(type = "body"))
    }

    # Responses
    if (!is.null(data$data$isa_data$responses) && nrow(data$data$isa_data$responses) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "ISA Framework: Responses", location = officer::ph_location_type(type = "title"))

      responses_text <- paste(paste("-", as.character(data$data$isa_data$responses$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(responses_text), location = officer::ph_location_type(type = "body"))
    }

  }

  # Feedback Loops
  if ("loops" %in% sections && !is.null(data$data$analysis$loops)) {
    loops <- data$data$analysis$loops
    if (length(loops) > 0) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "Feedback Loop Analysis", location = officer::ph_location_type(type = "title"))

      n_reinforcing <- sum(sapply(loops, function(l) l$type == "reinforcing"))
      n_balancing <- sum(sapply(loops, function(l) l$type == "balancing"))

      loops_text <- paste(
        paste("Total Loops:", length(loops)),
        paste("Reinforcing:", n_reinforcing, "(amplifying)"),
        paste("Balancing:", n_balancing, "(stabilizing)"),
        sep = "\n"
      )

      ppt <- officer::ph_with(ppt, value = as.character(loops_text), location = officer::ph_location_type(type = "body"))
    }
  }

  # Leverage Points
  if ("leverage" %in% sections && !is.null(data$data$cld$nodes)) {
    nodes <- data$data$cld$nodes
    nodes_with_leverage <- nodes[nodes$leverage_score > 0, ]

    if (nrow(nodes_with_leverage) > 0) {
      nodes_with_leverage <- nodes_with_leverage[order(-nodes_with_leverage$leverage_score), ]

      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "Top Leverage Points", location = officer::ph_location_type(type = "title"))

      top_nodes <- head(nodes_with_leverage, 10)
      leverage_text <- paste(
        paste(1:nrow(top_nodes), ".", as.character(top_nodes$label), "(Score:", round(top_nodes$leverage_score, 2), ")"),
        collapse = "\n"
      )

      ppt <- officer::ph_with(ppt, value = as.character(leverage_text), location = officer::ph_location_type(type = "body"))
    }
  }

  # Recommendations
  if ("recommendations" %in% sections) {
    ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
    ppt <- officer::ph_with(ppt, value = "Recommendations", location = officer::ph_location_type(type = "title"))

    recommendations_text <- paste(
      "1. Target high-leverage nodes for maximum impact",
      "2. Monitor reinforcing feedback loops",
      "3. Address root causes (drivers)",
      "4. Strengthen balancing loops for resilience",
      "5. Engage stakeholders at key leverage points",
      sep = "\n"
    )

    ppt <- officer::ph_with(ppt, value = as.character(recommendations_text), location = officer::ph_location_type(type = "body"))
  }

  # Save presentation
  print(ppt, target = output_file)
}
