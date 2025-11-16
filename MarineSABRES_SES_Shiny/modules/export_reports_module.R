library(shiny)
library(shinydashboard)

# modules/export_reports_module.R
# Export & Reports Module
# Purpose: Handle data export, visualization export, and report generation

# Source the report generation functions
source("functions/report_generation.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

export_reports_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        create_module_header(
          ns = ns,
          title_key = "Export & Reports",
          subtitle_key = "Export your data, visualizations, and generate comprehensive reports.",
          help_id = "help_export",
          i18n = i18n
        )
      )
    ),

    fluidRow(
      box(
        title = i18n$t("Export Data"),
        status = "primary",
        solidHeader = TRUE,
        width = 6,

        selectInput(
          ns("export_data_format"),
          i18n$t("Select Format:"),
          choices = c("Excel (.xlsx)", "CSV (.csv)", "JSON (.json)",
                      "R Data (.RData)")
        ),

        checkboxGroupInput(
          ns("export_data_components"),
          i18n$t("Select Components:"),
          choices = c(
            "metadata" = i18n$t("Project Metadata"),
            "pims" = i18n$t("PIMS Data"),
            "isa_data" = i18n$t("ISA Data"),
            "cld" = i18n$t("CLD Data"),
            "analysis" = i18n$t("Analysis Results"),
            "responses" = i18n$t("Response Measures")
          ),
          selected = c("metadata", "isa_data", "cld")
        ),

        downloadButton(ns("download_data"), i18n$t("Download Data"),
                       class = "btn-primary")
      ),

      box(
        title = i18n$t("Export Visualizations"),
        status = "info",
        solidHeader = TRUE,
        width = 6,

        selectInput(
          ns("export_viz_format"),
          i18n$t("Select Format:"),
          choices = c("PNG (.png)", "SVG (.svg)", "HTML (.html)",
                      "PDF (.pdf)")
        ),

        numericInput(
          ns("export_viz_width"),
          i18n$t("Width (pixels):"),
          value = 1200,
          min = 400,
          max = 4000
        ),

        numericInput(
          ns("export_viz_height"),
          i18n$t("Height (pixels):"),
          value = 900,
          min = 300,
          max = 3000
        ),

        downloadButton(ns("download_viz"), i18n$t("Download Visualization"),
                       class = "btn-info")
      )
    ),

    fluidRow(
      box(
        title = i18n$t("Generate Report"),
        status = "success",
        solidHeader = TRUE,
        width = 12,

        selectInput(
          ns("report_type"),
          i18n$t("Report Type:"),
          choices = c(
            "Executive Summary" = "executive",
            "Technical Report" = "technical",
            "Stakeholder Presentation" = "presentation",
            "Full Project Report" = "full"
          )
        ),

        selectInput(
          ns("report_format"),
          i18n$t("Report Format:"),
          choices = c("HTML", "PDF", "Word")
        ),

        checkboxInput(
          ns("report_include_viz"),
          i18n$t("Include Visualizations"),
          value = TRUE
        ),

        checkboxInput(
          ns("report_include_data"),
          i18n$t("Include Data Tables"),
          value = TRUE
        ),

        actionButton(
          ns("generate_report"),
          i18n$t("Generate Report"),
          icon = icon("file-alt"),
          class = "btn-success"
        ),

        uiOutput(ns("report_status"))
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

export_reports_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {

    # Reactive value to store output file path
    report_file_path <- reactiveVal(NULL)

    # ========== REPORT GENERATION ==========

    output$report_status <- renderUI({
      tags$div(
        style = "margin-top: 20px;",
        id = session$ns("report_status_div")
      )
    })

    # Generate report button
    observeEvent(input$generate_report, {
      cat("\n*** EXPORT REPORTS MODULE: Generate Report clicked ***\n")
      cat("Report type:", input$report_type, "\n")
      cat("Report format:", input$report_format, "\n")

      # Show progress
      showModal(modalDialog(
        title = "Generating Report",
        "Please wait while your report is being generated...",
        footer = NULL,
        easyClose = FALSE
      ))

      data <- project_data_reactive()
      report_type <- input$report_type
      report_format <- input$report_format
      include_viz <- input$report_include_viz
      include_data <- input$report_include_data

      tryCatch({
        # Create a temporary Rmd file
        rmd_file <- tempfile(fileext = ".Rmd")

        # Generate report content using the fixed function
        cat("[EXPORT] Calling generate_report_content()...\n")
        flush.console()

        report_content <- tryCatch({
          generate_report_content(
            data = data,
            report_type = report_type,
            include_viz = include_viz,
            include_data = include_data
          )
        }, error = function(e) {
          cat("\n!!! ERROR IN generate_report_content() !!!\n")
          cat("Error message:", e$message, "\n")
          cat("Error class:", class(e), "\n")
          print(traceback())
          cat("=====================================\n\n")
          flush.console()
          stop(e)
        })

        cat("[EXPORT] Report content generated successfully!\n")
        cat("[EXPORT] Content length:", nchar(report_content), "characters\n")
        flush.console()

        writeLines(report_content, rmd_file)
        cat("[EXPORT] Written to temp Rmd file:", rmd_file, "\n")
        flush.console()

        # Render the report
        # Ensure report_format is a simple character string
        report_format_safe <- as.character(report_format)[1]
        cat("[EXPORT] report_format:", report_format, "class:",
            class(report_format), "\n")
        cat("[EXPORT] report_format_safe:", report_format_safe, "\n")
        flush.console()

        output_format <- switch(report_format_safe,
          "HTML" = "html_document",
          "PDF" = "pdf_document",
          "Word" = "word_document",
          "html_document"  # default
        )

        output_ext <- switch(report_format_safe,
          "HTML" = ".html",
          "PDF" = ".pdf",
          "Word" = ".docx",
          ".html"  # default
        )

        output_file <- tempfile(fileext = output_ext)

        cat("[EXPORT] output_format:", output_format, "class:",
            class(output_format), "\n")
        cat("[EXPORT] output_file:", output_file, "class:",
            class(output_file), "\n")
        cat("[EXPORT] rmd_file:", rmd_file, "class:",
            class(rmd_file), "\n")
        flush.console()

        cat("[EXPORT] About to call rmarkdown::render()...\n")
        flush.console()

        rmarkdown::render(
          input = rmd_file,
          output_format = output_format,
          output_file = output_file,
          quiet = FALSE  # Changed to FALSE to see rendering errors
        )
        cat("[EXPORT] Report rendered successfully!\n")
        flush.console()

        # Store file path for download
        report_file_path(output_file)

        # Show success
        removeModal()

        # For HTML reports, open in browser automatically
        if (report_format == "HTML") {
          cat("[EXPORT] Opening HTML report in browser...\n")
          browseURL(output_file)

          msg <- i18n$t(
            "Report opened in your browser! You can also download it below."
          )
          showNotification(msg, type = "message", duration = 5)

          # Still show download option
          showModal(modalDialog(
            title = i18n$t("Report Generated Successfully"),
            tags$div(
              p(i18n$t("Your HTML report has been opened in your browser.")),
              p(i18n$t("You can also download it to save permanently:")),
              downloadButton(session$ns("download_report_file"),
                             i18n$t("Download Report"),
                             class = "btn-success")
            ),
            footer = modalButton(i18n$t("Close"))
          ))
        } else {
          # For PDF/Word, show download dialog
          showModal(modalDialog(
            title = i18n$t("Report Generated Successfully"),
            tags$div(
              p(i18n$t("Your report has been generated successfully.")),
              downloadButton(session$ns("download_report_file"),
                             i18n$t("Download Report"),
                             class = "btn-success")
            ),
            footer = modalButton(i18n$t("Close"))
          ))
        }

      }, error = function(e) {
        removeModal()
        cat("\n!!! ERROR IN REPORT GENERATION !!!\n")
        cat("Error message:", e$message, "\n")
        cat("Error class:", class(e), "\n")
        print(e)
        cat("=====================================\n\n")
        showNotification(paste("Error generating report:", e$message),
                         type = "error", duration = 10)
      })
    })

    # Download handler for generated report
    output$download_report_file <- downloadHandler(
      filename = function() {
        paste0("MarineSABRES_Report_", input$report_type, "_", Sys.Date(),
               switch(input$report_format,
                      "HTML" = ".html",
                      "PDF" = ".pdf",
                      "Word" = ".docx"))
      },
      content = function(file) {
        file.copy(report_file_path(), file)
      }
    )

    # ========== DATA EXPORT ==========
    # (Placeholders - implement as needed)

    output$download_data <- downloadHandler(
      filename = function() {
        paste0("MarineSABRES_Data_", Sys.Date(),
               switch(input$export_data_format,
                      "Excel (.xlsx)" = ".xlsx",
                      "CSV (.csv)" = ".csv",
                      "JSON (.json)" = ".json",
                      "R Data (.RData)" = ".RData"))
      },
      content = function(file) {
        # Implement data export logic
        showNotification("Data export not yet implemented", type = "warning")
      }
    )

    # ========== VISUALIZATION EXPORT ==========

    output$download_viz <- downloadHandler(
      filename = function() {
        paste0("MarineSABRES_Viz_", Sys.Date(),
               switch(input$export_viz_format,
                      "PNG (.png)" = ".png",
                      "SVG (.svg)" = ".svg",
                      "HTML (.html)" = ".html",
                      "PDF (.pdf)" = ".pdf"))
      },
      content = function(file) {
        # Implement visualization export logic
        showNotification(
          "Visualization export not yet implemented",
          type = "warning"
        )
      }
    )

    # Help Modal ----
    create_help_observer(
      input, "help_export", "export_guide_title",
      tagList(
        h4(i18n$t("export_guide_data_title")),
        p(i18n$t("export_guide_data_p1")),
        h4(i18n$t("export_guide_viz_title")),
        p(i18n$t("export_guide_viz_p1")),
        h4(i18n$t("export_guide_reports_title")),
        p(i18n$t("export_guide_reports_p1"))
      ),
      i18n
    )
  })
}
