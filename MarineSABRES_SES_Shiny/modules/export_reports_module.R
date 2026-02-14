# modules/export_reports_module.R
# Libraries loaded in global.R: shiny
# Export & Reports Module
# Purpose: Handle data export, visualization export, and report generation

# Report generation functions sourced globally via app.R critical_sources

# ============================================================================
# UI FUNCTION
# ============================================================================

export_reports_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    # Use i18n for language support
    # REMOVED: usei18n() - only called once in main UI (app.R)

    fluidRow(
      column(12,
        uiOutput(ns("module_header"))
      )
    ),

    fluidRow(
      bs4Card(
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

      bs4Card(
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
      bs4Card(
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

    # === REACTIVE MODULE HEADER ===
    create_reactive_header(
      output = output,
      ns = session$ns,
      title_key = "modules.export.reports.title",
      subtitle_key = "modules.export.reports.subtitle",
      help_id = "help_export",
      i18n = i18n
    )

    # ========== REPORT GENERATION ==========

    output$report_status <- renderUI({
      tags$div(
        style = "margin-top: 20px;",
        id = session$ns("report_status_div")
      )
    })

    # Generate report button
    observeEvent(input$generate_report, {
      debug_log("Generate Report clicked", "EXPORT")
      debug_log(paste("Report type:", input$report_type), "EXPORT")
      debug_log(paste("Report format:", input$report_format), "EXPORT")

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
        on.exit(unlink(rmd_file), add = TRUE)

        # Generate report content using the fixed function
        debug_log("Calling generate_report_content()...", "EXPORT")
        flush.console()

        report_content <- generate_report_content(
          data = data,
          report_type = report_type,
          include_viz = include_viz,
          include_data = include_data
        )

        debug_log("Report content generated successfully!", "EXPORT")
        debug_log(paste("Content length:", nchar(report_content), "characters"), "EXPORT")

        writeLines(report_content, rmd_file)
        debug_log(paste("Written to temp Rmd file:", rmd_file), "EXPORT")

        # Render the report
        # Ensure report_format is a simple character string
        report_format_safe <- as.character(report_format)[1]
        debug_log(paste("report_format:", report_format, "class:", class(report_format)), "EXPORT")
        debug_log(paste("report_format_safe:", report_format_safe), "EXPORT")

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

        old_report <- report_file_path()
        if (!is.null(old_report) && file.exists(old_report)) {
          tryCatch(unlink(old_report), error = function(e) debug_log(paste("Cleanup failed:", e$message), "EXPORT"))
        }
        output_file <- tempfile(fileext = output_ext)

        debug_log(paste("output_format:", output_format, "class:", class(output_format)), "EXPORT")
        debug_log(paste("output_file:", output_file, "class:", class(output_file)), "EXPORT")
        debug_log(paste("rmd_file:", rmd_file, "class:", class(rmd_file)), "EXPORT")

        debug_log("About to call rmarkdown::render()...", "EXPORT")

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
            removeModal()
            showNotification(
              paste("PDF generation requires LaTeX. Please install TinyTeX using:",
                    "install.packages('tinytex'); tinytex::install_tinytex().",
                    "Alternatively, generate an HTML report and print to PDF from your browser."),
              type = "error",
              duration = 15
            )
            return()
          }
        }

        rmarkdown::render(
          input = rmd_file,
          output_format = output_format,
          output_file = output_file,
          quiet = FALSE  # Changed to FALSE to see rendering errors
        )
        debug_log("Report rendered successfully!", "EXPORT")

        # Store file path for download
        report_file_path(output_file)

        # Show success
        removeModal()

        # For HTML reports, open in new window/tab
        if (report_format == "HTML") {
          debug_log("Opening HTML report in new window...", "EXPORT")

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
        debug_log("ERROR IN REPORT GENERATION", "EXPORT")
        debug_log(paste("Error message:", e$message), "EXPORT")
        debug_log(paste("Error class:", paste(class(e), collapse = ", ")), "EXPORT")
        showNotification(paste(i18n$t("common.messages.error_generating_report"), e$message),
                         type = "error", duration = 10)
      })
    })

    # Download handler for generated report
    output$download_report_file <- downloadHandler(
      filename = function() {
        generate_export_filename(
          paste0("MarineSABRES_Report_", input$report_type),
          switch(input$report_format, "HTML" = ".html", "PDF" = ".pdf", "Word" = ".docx")
        )
      },
      content = function(file) {
        file.copy(report_file_path(), file)
      }
    )

    # ========== DATA EXPORT ==========
    # (Placeholders - implement as needed)

    output$download_data <- downloadHandler(
      filename = function() {
        generate_export_filename(
          "MarineSABRES_Data",
          switch(input$export_data_format,
                 "Excel (.xlsx)" = ".xlsx", "CSV (.csv)" = ".csv",
                 "JSON (.json)" = ".json", "R Data (.RData)" = ".RData")
        )
      },
      content = function(file) {
        # Implement data export logic
        showNotification(i18n$t("common.messages.data_export_not_implemented"), type = "warning")
      }
    )

    # ========== VISUALIZATION EXPORT ==========

    output$download_viz <- downloadHandler(
      filename = function() {
        generate_export_filename(
          "MarineSABRES_Viz",
          switch(input$export_viz_format,
                 "PNG (.png)" = ".png", "SVG (.svg)" = ".svg",
                 "HTML (.html)" = ".html", "PDF (.pdf)" = ".pdf")
        )
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
