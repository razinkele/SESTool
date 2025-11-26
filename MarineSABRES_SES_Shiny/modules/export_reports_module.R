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
    # Use i18n for language support
    shiny.i18n::usei18n(i18n),

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
        title = i18n$t("modules.isa.data_entry.common.export_data"),
        status = "primary",
        solidHeader = TRUE,
        width = 6,

        selectInput(
          ns("export_data_format"),
          i18n$t("modules.export.reports.select_format"),
          choices = c("Excel (.xlsx)", "CSV (.csv)", "JSON (.json)",
                      "R Data (.RData)")
        ),

        checkboxGroupInput(
          ns("export_data_components"),
          i18n$t("modules.export.reports.select_components"),
          choices = c(
            "metadata" = i18n$t("modules.export.reports.project_metadata"),
            "pims" = i18n$t("modules.export.reports.pims_data"),
            "isa_data" = i18n$t("modules.export.reports.isa_data"),
            "cld" = i18n$t("modules.export.reports.cld_data"),
            "analysis" = i18n$t("modules.export.reports.analysis_results"),
            "responses" = i18n$t("ui.sidebar.response_measures")
          ),
          selected = c("metadata", "isa_data", "cld")
        ),

        downloadButton(ns("download_data"), i18n$t("modules.export.reports.download_data"),
                       class = "btn-primary")
      ),

      box(
        title = i18n$t("modules.export.reports.export_visualizations"),
        status = "info",
        solidHeader = TRUE,
        width = 6,

        selectInput(
          ns("export_viz_format"),
          i18n$t("modules.export.reports.select_format"),
          choices = c("PNG (.png)", "SVG (.svg)", "HTML (.html)",
                      "PDF (.pdf)")
        ),

        numericInput(
          ns("export_viz_width"),
          i18n$t("modules.export.reports.width_pixels"),
          value = 1200,
          min = 400,
          max = 4000
        ),

        numericInput(
          ns("export_viz_height"),
          i18n$t("modules.export.reports.height_pixels"),
          value = 900,
          min = 300,
          max = 3000
        ),

        downloadButton(ns("download_viz"), i18n$t("modules.export.reports.download_visualization"),
                       class = "btn-info")
      )
    ),

    fluidRow(
      box(
        title = i18n$t("modules.export.reports.generate_report"),
        status = "success",
        solidHeader = TRUE,
        width = 12,

        selectInput(
          ns("report_type"),
          i18n$t("common.labels.report_type"),
          choices = c(
            "Executive Summary" = "executive",
            "Technical Report" = "technical",
            "Stakeholder Presentation" = "presentation",
            "Full Project Report" = "full"
          )
        ),

        selectInput(
          ns("report_format"),
          i18n$t("modules.export.reports.report_format"),
          choices = c("HTML", "PDF", "Word")
        ),

        checkboxInput(
          ns("report_include_viz"),
          i18n$t("modules.export.reports.include_visualizations"),
          value = TRUE
        ),

        checkboxInput(
          ns("report_include_data"),
          i18n$t("modules.export.reports.include_data_tables"),
          value = TRUE
        ),

        actionButton(
          ns("generate_report"),
          i18n$t("modules.export.reports.generate_report"),
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

        # Special handling for PDF - check if LaTeX is available
        if (report_format_safe == "PDF") {
          # Check if tinytex or other LaTeX is installed
          latex_available <- tryCatch({
            tinytex::tinytex_root()
            TRUE
          }, error = function(e) {
            FALSE
          })

          if (!latex_available) {
            # Check system LaTeX
            latex_available <- tryCatch({
              system("pdflatex --version", intern = TRUE, ignore.stderr = TRUE)
              TRUE
            }, error = function(e) {
              FALSE
            })
          }

          if (!latex_available) {
            stop("PDF generation requires LaTeX. Please install TinyTeX using:\n",
                 "install.packages('tinytex')\n",
                 "tinytex::install_tinytex()\n\n",
                 "Alternatively, generate an HTML report and print to PDF from your browser.")
          }
        }

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

        # For HTML reports, open in new window/tab
        if (report_format == "HTML") {
          cat("[EXPORT] Opening HTML report in new window...\n")

          # Copy to www directory so it can be served by Shiny
          www_dir <- file.path(getwd(), "www", "reports")
          if (!dir.exists(www_dir)) {
            dir.create(www_dir, recursive = TRUE)
          }

          # Create unique filename
          report_filename <- paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html")
          www_file <- file.path(www_dir, report_filename)
          file.copy(output_file, www_file, overwrite = TRUE)

          # Create relative URL for Shiny
          report_url <- paste0("reports/", report_filename)

          # Open in new window using JavaScript
          session$sendCustomMessage(
            type = "openReport",
            message = list(url = report_url)
          )

          showNotification(
            i18n$t("modules.export.reports.report_opened_in_a_new_window"),
            type = "message",
            duration = 5
          )

        } else if (report_format == "PDF") {
          # For PDF, show informative message about requirements
          showModal(modalDialog(
            title = i18n$t("modules.export.reports.pdf_report_notice"),
            tags$div(
              tags$p(icon("info-circle"), style = "color: #17a2b8;",
                     i18n$t("modules.export.reports.pdf_generation_requires_latex_eg_tinytex_or_miktex")),
              tags$p(i18n$t("modules.export.if_you_see_errors_try_generating_an_html_report_in")),
              tags$hr(),
              tags$p(i18n$t("modules.export.reports.to_install_tinytex_for_pdf_support")),
              tags$pre("install.packages('tinytex')\ntinytex::install_tinytex()"),
              tags$hr(),
              downloadButton(session$ns("download_report_file"),
                             i18n$t("modules.export.reports.download_report_if_generated"),
                             class = "btn-danger")
            ),
            footer = modalButton(i18n$t("common.buttons.close")),
            easyClose = TRUE
          ))
        } else {
          # For Word, show download dialog
          showModal(modalDialog(
            title = i18n$t("common.messages.report_generated_successfully"),
            tags$div(
              p(i18n$t("modules.export.reports.your_report_has_been_generated_successfully")),
              downloadButton(session$ns("download_report_file"),
                             i18n$t("modules.export.reports.download_report"),
                             class = "btn-success")
            ),
            footer = modalButton(i18n$t("common.buttons.close"))
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
        h4(i18n$t("modules.export.reports.export_guide_data_title")),
        p(i18n$t("modules.export.reports.export_guide_data_p1")),
        h4(i18n$t("modules.export.reports.export_guide_viz_title")),
        p(i18n$t("modules.export.reports.export_guide_viz_p1")),
        h4(i18n$t("modules.export.reports.export_guide_reports_title")),
        p(i18n$t("modules.export.reports.export_guide_reports_p1"))
      ),
      i18n
    )
  })
}
