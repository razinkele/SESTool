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
          title = tagList(icon("check-circle"), " ", i18n$t("modules.prepare.report.prerequisites_status")),
          status = "info",
          solidHeader = TRUE,
          width = NULL,

          uiOutput(ns("prerequisite_status"))
        )
      ),

      # Report Configuration
      column(6,
        bs4Card(
          title = tagList(icon("cog"), " ", i18n$t("modules.prepare.report.report_configuration")),
          status = "primary",
          solidHeader = TRUE,
          width = NULL,

          textInput(ns("report_title"),
                   i18n$t("modules.prepare.report.report_title_label"),
                   value = i18n$t("modules.prepare.report.default_report_title")),

          textInput(ns("report_author"),
                   i18n$t("modules.prepare.report.author_label"),
                   placeholder = i18n$t("modules.prepare.report.author_placeholder")),

          checkboxGroupInput(ns("report_sections"),
                            i18n$t("modules.prepare.report.include_sections"),
                            choices = setNames(
                              c("summary", "isa", "cld", "metrics", "loops", "leverage", "recommendations"),
                              c(i18n$t("modules.prepare.report.section_summary"),
                                i18n$t("modules.prepare.report.section_isa"),
                                i18n$t("modules.prepare.report.section_cld"),
                                i18n$t("modules.prepare.report.section_metrics"),
                                i18n$t("modules.prepare.report.section_loops"),
                                i18n$t("modules.prepare.report.section_leverage"),
                                i18n$t("modules.prepare.report.section_recommendations"))
                            ),
                            selected = c("summary", "isa", "cld", "loops", "leverage")),

          checkboxInput(ns("include_regional_context"),
                        i18n$t("modules.report_context.include_context"),
                        value = TRUE)
        )
      )
    ),

    fluidRow(
      column(12,
        bs4Card(
          title = tagList(icon("file-download"), " ", i18n$t("modules.prepare.report.generate_report")),
          status = "success",
          solidHeader = TRUE,
          width = NULL,

          p(i18n$t("modules.prepare.report.select_format")),

          fluidRow(
            column(3,
              actionButton(ns("generate_html"),
                          i18n$t("modules.prepare.report.btn_html"),
                          icon = icon("globe"),
                          class = "btn-primary btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_pdf"),
                          i18n$t("modules.prepare.report.btn_pdf"),
                          icon = icon("file-pdf"),
                          class = "btn-danger btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_word"),
                          i18n$t("modules.prepare.report.btn_word"),
                          icon = icon("file-word"),
                          class = "btn-info btn-lg btn-block",
                          style = "margin-bottom: 10px;")
            ),
            column(3,
              actionButton(ns("generate_ppt"),
                          i18n$t("modules.prepare.report.btn_ppt"),
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

prepare_report_server <- function(id, project_data_reactive, i18n, parent_session = NULL, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {

    # Reactive values for storing report paths
    rv <- reactiveValues(
      html_report_path = NULL,
      pdf_report_path = NULL,
      word_report_path = NULL,
      ppt_report_path = NULL
    )

    # Helper to clean up previous temp report files
    cleanup_old_report <- function(old_path) {
      if (!is.null(old_path) && nzchar(old_path) && file.exists(old_path)) {
        tryCatch(unlink(old_path), error = function(e) debug_log(paste("Cleanup failed:", e$message), "REPORT"))
      }
    }

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

      # Check if loop analysis has been performed (even if zero loops found)
      has_loops <- !is.null(data$data$analysis$loops) &&
                   (length(data$data$analysis$loops) > 0)

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
            strong(i18n$t("modules.prepare.report.loop_detection"))
          ),
          if (!status$loops) {
            tags$p(style = "margin-left: 30px; color: #666;",
                  i18n$t("modules.prepare.report.complete_loop_detection"),
                  tags$br(),
                  actionLink(session$ns("goto_loops"), i18n$t("modules.prepare.report.goto_loops")))
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
            strong(i18n$t("modules.prepare.report.leverage_analysis"))
          ),
          if (!status$leverage) {
            tags$p(style = "margin-left: 30px; color: #666;",
                  i18n$t("modules.prepare.report.complete_leverage_analysis"),
                  tags$br(),
                  actionLink(session$ns("goto_leverage"), i18n$t("modules.prepare.report.goto_leverage")))
          }
        ),

        hr(),

        if (status$both) {
          tags$div(
            style = "padding: 15px; background: #d4edda; border-radius: 5px; text-align: center;",
            icon("check-circle", class = "text-success", style = "font-size: 2em;"),
            tags$h4(style = "color: #155724; margin-top: 10px;",
                   i18n$t("modules.prepare.report.all_prerequisites_met")),
            tags$p(style = "color: #155724;",
                  i18n$t("modules.prepare.report.can_generate"))
          )
        } else {
          tags$div(
            style = "padding: 15px; background: #f8d7da; border-radius: 5px; text-align: center;",
            icon("exclamation-triangle", class = "text-danger", style = "font-size: 2em;"),
            tags$h4(style = "color: #721c24; margin-top: 10px;",
                   i18n$t("modules.prepare.report.prerequisites_not_met")),
            tags$p(style = "color: #721c24;",
                  i18n$t("modules.prepare.report.complete_analyses"))
          )
        }
      )
    })

    # Navigation links
    observeEvent(input$goto_loops, {
      if (!is.null(parent_session)) {
        updateTabItems(session = parent_session, "sidebar_menu", "analysis_loops")
      }
    })

    observeEvent(input$goto_leverage, {
      if (!is.null(parent_session)) {
        updateTabItems(session = parent_session, "sidebar_menu", "analysis_leverage")
      }
    })

    # Report generation handlers
    observeEvent(input$generate_html, {
      debug_log("Generate HTML clicked", "REPORT")
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          i18n$t("modules.prepare.report.requirements"),
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_html_report"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()
        debug_log("Using generate_report_content() from functions/report_generation.R", "REPORT")

        # Use the fixed report generation function from functions/report_generation.R
        opts <- list(include_regional_context = input$include_regional_context,
                     sections = input$report_sections %||% character(0))
        report_md <- generate_report_content(
          data = data,
          report_type = "full",  # Use full report type
          include_viz = TRUE,
          include_data = FALSE,
          options = opts
        )
        debug_log("Markdown content generated successfully", "REPORT")

        # Convert markdown to HTML WITHOUT knitting user text (review 2026-10-07
        # N11: the body carries project/element names) and serve it through a
        # session-scoped URL instead of the shared www/reports tree (N14).
        debug_log("Converting to HTML", "REPORT")
        cleanup_old_report(rv$html_report_path)
        temp_file <- tempfile(fileext = ".html")
        render_report_safely(report_md, temp_file, format = "html", i18n = i18n)
        debug_log("Report rendered to HTML successfully", "REPORT")
        report_url <- register_session_report(session, temp_file)

        # Open in new window using JavaScript
        session$sendCustomMessage(
          type = "openReport",
          message = list(url = report_url)
        )

        # Store temp file path for download
        rv$html_report_path <- temp_file

        # The opened tab's URL dies with the session ("not found" later, user
        # feedback 2026-06-15), so offer the file itself as well.
        showModal(modalDialog(
          title = i18n$t("modules.prepare.report.report_opened"),
          tags$p(i18n$t("common.messages.html_report_link_temporary")),
          footer = tagList(
            downloadButton(session$ns("download_html"), i18n$t("modules.prepare.report.download_report")),
            modalButton(i18n$t("common.buttons.close"))
          ),
          easyClose = TRUE,
          size = "m"
        ))

      }, error = function(e) {
        showNotification(
          format_user_error(e, i18n = i18n, context_key = "common.messages.context_generating_html_report"),
          type = "error",
          duration = 10
        )
      })
    })

    observeEvent(input$generate_pdf, {
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          i18n$t("modules.prepare.report.requirements"),
          type = "error",
          duration = 5
        )
        return()
      }

      showNotification(i18n$t("common.messages.generating_pdf_report"), type = "message", duration = 3)

      tryCatch({
        data <- project_data_reactive()

        # Check if the PDF engine is really usable (review 2026-10-07 N41: the
        # old probe treated tinytex_root() == "" and a failing pdflatex as success)
        latex_available <- latex_engine_available("lualatex")

        if (!latex_available) {
          # LaTeX not available - show helpful message
          showModal(modalDialog(
            title = i18n$t("modules.prepare.report.pdf_not_available"),
            tags$div(
              tags$p(icon("exclamation-triangle", class = "text-warning", style = "font-size: 2em;")),
              tags$h4(i18n$t("modules.prepare.report.pdf_requires_latex")),
              tags$hr(),
              tags$p(i18n$t("modules.prepare.report.pdf_latex_options")),
              tags$h5(i18n$t("modules.prepare.report.option_tinytex")),
              tags$p(i18n$t("modules.prepare.report.run_commands_in_r")),
              tags$pre("install.packages('tinytex')\ntinytex::install_tinytex()"),
              tags$h5(i18n$t("modules.prepare.report.option_html_report")),
              tags$p(i18n$t("modules.prepare.report.html_alternative")),
              tags$ul(
                tags$li(i18n$t("modules.prepare.report.view_in_browser")),
                tags$li(i18n$t("modules.prepare.report.print_to_pdf"))
              )
            ),
            footer = tagList(
              actionButton(session$ns("generate_html_instead"), i18n$t("modules.prepare.report.generate_html_instead"),
                          class = "btn-primary"),
              modalButton(i18n$t("common.buttons.cancel"))
            ),
            easyClose = TRUE,
            size = "l"
          ))
          return()
        }

        # Generate markdown content
        opts <- list(include_regional_context = input$include_regional_context,
                     sections = input$report_sections %||% character(0))
        report_md <- generate_report_content(
          data = data,
          report_type = "full",
          include_viz = TRUE,
          include_data = FALSE,
          options = opts
        )

        # Render to PDF without knitting user text (review 2026-10-07 N11)
        cleanup_old_report(rv$pdf_report_path)
        temp_pdf <- tempfile(fileext = ".pdf")
        render_report_safely(report_md, temp_pdf, format = "pdf",
                             pdf_engine = "lualatex", quiet = FALSE, i18n = i18n)

        showModal(modalDialog(
          title = i18n$t("modules.prepare.report.pdf_success"),
          tags$p(i18n$t("modules.prepare.report.pdf_success_message")),
          footer = tagList(
            downloadButton(session$ns("download_pdf"), i18n$t("modules.prepare.report.download_report")),
            modalButton(i18n$t("common.buttons.close"))
          ),
          easyClose = TRUE,
          size = "m"
        ))

        rv$pdf_report_path <- temp_pdf

      }, error = function(e) {
        showNotification(
          format_user_error(e, i18n = i18n, context_key = "common.messages.context_generating_pdf_report", show_details = TRUE),
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
          i18n$t("modules.prepare.report.requirements"),
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

          cleanup_old_report(rv$word_report_path)
          temp_docx <- tempfile(fileext = ".docx")

          # Same content as the HTML and PDF reports (user feedback 2026-10-18
          # "Word vs html report"): the separate officer builder,
          # generate_word_report(), had far less content and miscounted loops.
          opts <- list(include_regional_context = input$include_regional_context,
                     sections = input$report_sections %||% character(0))
          report_md <- generate_report_content(
            data = data,
            report_type = "full",
            include_viz = TRUE,
            include_data = FALSE,
            options = opts
          )
          render_report_safely(report_md, temp_docx, format = "docx", i18n = i18n)

          showModal(modalDialog(
            title = i18n$t("modules.prepare.report.word_success"),
            tags$p(i18n$t("modules.prepare.report.word_success_message")),
            tags$p(tags$strong(i18n$t("modules.prepare.report.file_location")), temp_docx),
            footer = tagList(
              downloadButton(session$ns("download_word"), i18n$t("modules.prepare.report.download_report")),
              modalButton(i18n$t("common.buttons.close"))
            ),
            easyClose = TRUE,
            size = "m"
          ))

          rv$word_report_path <- temp_docx

        } else {
          showNotification(
            i18n$t("modules.prepare.report.requires_officer_flextable"),
            type = "warning",
            duration = 10
          )
        }

      }, error = function(e) {
        showNotification(
          format_user_error(e, i18n = i18n, context_key = "common.messages.context_generating_word_document", show_details = TRUE),
          type = "error",
          duration = 10
        )
      })
    })

    observeEvent(input$generate_ppt, {
      status <- check_prerequisites()
      if (!status$both) {
        showNotification(
          i18n$t("modules.prepare.report.requirements"),
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

          cleanup_old_report(rv$ppt_report_path)
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
            title = i18n$t("modules.prepare.report.ppt_success"),
            tags$p(i18n$t("modules.prepare.report.ppt_success_message")),
            tags$p(tags$strong(i18n$t("modules.prepare.report.file_location")), temp_pptx),
            footer = tagList(
              downloadButton(session$ns("download_ppt"), i18n$t("modules.prepare.report.download_report")),
              modalButton(i18n$t("common.buttons.close"))
            ),
            easyClose = TRUE,
            size = "m"
          ))

          rv$ppt_report_path <- temp_pptx

        } else {
          showNotification(
            i18n$t("modules.prepare.report.requires_officer"),
            type = "warning",
            duration = 10
          )
        }

      }, error = function(e) {
        showNotification(
          format_user_error(e, i18n = i18n, context_key = "common.messages.context_generating_powerpoint_presentation", show_details = TRUE),
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
        req(report_path_is_servable(rv$html_report_path))
        file.copy(rv$html_report_path, file)
      }
    )

    # Download handler for HTML fallback
    output$download_html_fallback <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".html")
      },
      content = function(file) {
        req(report_path_is_servable(rv$html_report_path))
        file.copy(rv$html_report_path, file)
      }
    )

    # Download handler for PDF report
    output$download_pdf <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".pdf")
      },
      content = function(file) {
        req(report_path_is_servable(rv$pdf_report_path))
        file.copy(rv$pdf_report_path, file)
      }
    )

    # Download handler for Word report
    output$download_word <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".docx")
      },
      content = function(file) {
        req(report_path_is_servable(rv$word_report_path))
        file.copy(rv$word_report_path, file)
      }
    )

    # Download handler for PowerPoint report
    output$download_ppt <- downloadHandler(
      filename = function() {
        generate_export_filename(sanitize_filename(input$report_title), ".pptx")
      },
      content = function(file) {
        req(report_path_is_servable(rv$ppt_report_path))
        file.copy(rv$ppt_report_path, file)
      }
    )
  })
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# (generate_html_report() and its table helper were removed: never called --
#  the HTML report is built by generate_report_content() in
#  functions/report_generation.R (see the generate_html observer). Review
#  2026-10-07 N67.)

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

  # Helper: safely convert to data.frame (ISA data may be stored as lists)
  safe_df <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.data.frame(x)) return(x)
    tryCatch(as.data.frame(x), error = function(e) NULL)
  }

  # Helper: safely get nrow (returns 0 for non-data.frame objects)
  safe_nrow <- function(x) {
    if (is.null(x)) return(0)
    if (is.data.frame(x)) return(nrow(x))
    tryCatch(nrow(as.data.frame(x)), error = function(e) 0)
  }

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

    # Count elements (safe_nrow handles lists gracefully)
    n_drivers <- safe_nrow(data$data$isa_data$drivers)
    n_activities <- safe_nrow(data$data$isa_data$activities)
    n_pressures <- safe_nrow(data$data$isa_data$pressures)
    n_marine <- safe_nrow(data$data$isa_data$marine_processes)
    n_ecosystem <- safe_nrow(data$data$isa_data$ecosystem_services)
    n_goods <- safe_nrow(data$data$isa_data$goods_benefits)
    n_responses <- safe_nrow(data$data$isa_data$responses)

    n_elements <- n_drivers + n_activities + n_pressures + n_marine + n_ecosystem + n_goods + n_responses
    n_nodes <- safe_nrow(data$data$cld$nodes)
    n_edges <- safe_nrow(data$data$cld$edges)
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

    # Helper to add an ISA element section with flextable
    add_isa_section <- function(doc, element_data, heading) {
      df <- safe_df(element_data)
      if (!is.null(df) && nrow(df) > 0) {
        doc <- officer::body_add_par(doc, heading, style = "heading 3")
        if (requireNamespace("flextable", quietly = TRUE)) {
          # Only include columns that exist
          cols <- intersect(c("ID", "Name", "Description"), names(df))
          if (length(cols) > 0) {
            ft <- flextable::flextable(df[, cols, drop = FALSE])
            ft <- flextable::theme_vanilla(ft)
            doc <- flextable::body_add_flextable(doc, ft)
          }
        }
        doc <- officer::body_add_par(doc, "", style = "Normal")
      }
      doc
    }

    doc <- add_isa_section(doc, data$data$isa_data$drivers, "Drivers")
    doc <- add_isa_section(doc, data$data$isa_data$activities, "Activities")
    doc <- add_isa_section(doc, data$data$isa_data$pressures, "Pressures")
    doc <- add_isa_section(doc, data$data$isa_data$marine_processes, "Marine Processes & Functions")
    doc <- add_isa_section(doc, data$data$isa_data$ecosystem_services, "Ecosystem Services")
    doc <- add_isa_section(doc, data$data$isa_data$goods_benefits, "Goods & Benefits")

    doc <- add_isa_section(doc, data$data$isa_data$responses, "Responses")

  }

  # Loop Analysis
  if ("loops" %in% sections && !is.null(data$data$analysis$loops)) {
    doc <- officer::body_add_par(doc, "Feedback Loop Analysis", style = "heading 2")

    loops <- data$data$analysis$loops
    if (length(loops) > 0) {
      doc <- officer::body_add_par(doc, paste("Detected", length(loops), "feedback loops in the system:"), style = "Normal")

      # Count by type (safely handle different loop data structures)
      n_reinforcing <- tryCatch(sum(sapply(loops, function(l) identical(l$type, "reinforcing"))), error = function(e) 0)
      n_balancing <- tryCatch(sum(sapply(loops, function(l) identical(l$type, "balancing"))), error = function(e) 0)

      doc <- officer::body_add_par(doc, paste("Reinforcing Loops:", n_reinforcing, "(amplifying changes)"), style = "Normal")
      doc <- officer::body_add_par(doc, paste("Balancing Loops:", n_balancing, "(stabilizing system)"), style = "Normal")
      doc <- officer::body_add_par(doc, "", style = "Normal")

      # Loop details table
      if (requireNamespace("flextable", quietly = TRUE)) {
        tryCatch({
          loop_df <- data.frame(
            Loop_ID = paste("Loop", 1:length(loops)),
            Type = toupper(sapply(loops, function(l) as.character(l$type)[1])),
            Length = sapply(loops, function(l) length(l$nodes)),
            Nodes = sapply(loops, function(l) paste(l$nodes, collapse = " -> "))
          )
          ft <- flextable::flextable(loop_df)
          ft <- flextable::theme_vanilla(ft)
          doc <- flextable::body_add_flextable(doc, ft)
        }, error = function(e) NULL)
      }
      doc <- officer::body_add_par(doc, "", style = "Normal")
    }
  }

  # Leverage Points
  if ("leverage" %in% sections && !is.null(data$data$cld$nodes)) {
    doc <- officer::body_add_par(doc, "Leverage Point Analysis", style = "heading 2")

    nodes <- safe_df(data$data$cld$nodes)
    if (!is.null(nodes) && "leverage_score" %in% names(nodes)) {
      nodes_with_leverage <- nodes[!is.na(nodes$leverage_score) & nodes$leverage_score > 0, , drop = FALSE]

      if (nrow(nodes_with_leverage) > 0) {
        nodes_with_leverage <- nodes_with_leverage[order(-nodes_with_leverage$leverage_score), , drop = FALSE]

        doc <- officer::body_add_par(doc, "Identified key leverage points in the system based on network centrality metrics:", style = "Normal")

        if (requireNamespace("flextable", quietly = TRUE)) {
          tryCatch({
            n_top <- min(20, nrow(nodes_with_leverage))
            top_nodes <- nodes_with_leverage[1:n_top, , drop = FALSE]

            in_degrees <- if ("in_degree" %in% names(top_nodes)) top_nodes$in_degree else rep(0, n_top)
            out_degrees <- if ("out_degree" %in% names(top_nodes)) top_nodes$out_degree else rep(0, n_top)
            betweenness_vals <- if ("betweenness" %in% names(top_nodes)) round(top_nodes$betweenness, 2) else rep(0, n_top)

            leverage_df <- data.frame(
              Rank = 1:n_top,
              Node = as.character(top_nodes$label),
              Leverage_Score = round(top_nodes$leverage_score, 2),
              In_Degree = in_degrees,
              Out_Degree = out_degrees,
              Betweenness = betweenness_vals
            )
            ft <- flextable::flextable(leverage_df)
            ft <- flextable::theme_vanilla(ft)
            doc <- flextable::body_add_flextable(doc, ft)
          }, error = function(e) NULL)
        }
        doc <- officer::body_add_par(doc, "", style = "Normal")
      }
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

# =============================================================================
# Report graphs (PowerPoint) — user feedback 2026-11-12, L30: the report should
# carry the graphs of the analyses and the main network.
# =============================================================================

#' Draw the CLD as a static layered diagram (PNG) for the PowerPoint report
#'
#' Nodes sit in rows by their DAPSI(W)R(M) `level` (as in the CLD view), coloured
#' by `group` from ELEMENT_COLORS; edges are coloured by polarity.
#' @param nodes CLD nodes data frame (id, label/name_raw, group, level, color)
#' @param edges CLD edges data frame (from, to, polarity)
#' @param file  PNG path
#' @return TRUE if a diagram was written, FALSE if there is nothing to draw
report_network_png <- function(nodes, edges, file, width = 2000, height = 1250, res = 150) {
  if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0 || !"id" %in% names(nodes)) {
    return(FALSE)
  }
  nodes <- nodes[!duplicated(nodes$id), , drop = FALSE]
  if (is.null(edges) || !is.data.frame(edges) || !all(c("from", "to") %in% names(edges))) {
    edges <- data.frame(from = character(0), to = character(0))
  }
  edges <- edges[edges$from %in% nodes$id & edges$to %in% nodes$id, , drop = FALSE]
  g <- igraph::graph_from_data_frame(edges[, c("from", "to"), drop = FALSE],
                                     directed = TRUE, vertices = data.frame(name = nodes$id))

  grp <- if ("group" %in% names(nodes)) as.character(nodes$group) else rep(NA_character_, nrow(nodes))
  pal <- unlist(ELEMENT_COLORS)

  # Layered layout: one row per DAPSI(W)R(M) group, top to bottom in causal
  # order (Responses and Measures get their own rows; in the CLD they share
  # the Pressures level, which overlapped their labels). Unknown groups fall
  # back to the node's `level`, then to a last row.
  row_order <- c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
                 "Ecosystem Services", "Goods & Benefits", "Responses", "Measures")
  row <- match(grp, row_order)
  if (anyNA(row)) {
    lvl <- if ("level" %in% names(nodes)) suppressWarnings(as.numeric(nodes$level)) else rep(NA, nrow(nodes))
    row[is.na(row)] <- ifelse(is.na(lvl[is.na(row)]), length(row_order) + 1, 6 - lvl[is.na(row)])
  }
  rows <- sort(unique(row))
  y_of <- if (length(rows) == 1) c(0) else seq(1, -1, length.out = length(rows))
  xy <- matrix(0, nrow(nodes), 2)
  per_row <- integer(nrow(nodes))
  label_side <- numeric(nrow(nodes))
  for (k in seq_along(rows)) {
    idx <- which(row == rows[k])
    xy[idx, 1] <- if (length(idx) == 1) 0 else seq(-1, 1, length.out = length(idx))
    xy[idx, 2] <- y_of[k]
    per_row[idx] <- length(idx)
    # alternate labels below/above the node so neighbours in a busy row don't collide
    label_side[idx] <- ifelse(seq_along(idx) %% 2 == 1, pi / 2, -pi / 2)
  }
  fill <- unname(pal[grp])
  if ("color" %in% names(nodes)) {
    own <- as.character(nodes$color)
    use_own <- is.na(fill) & !is.na(own) & nzchar(own)
    fill[use_own] <- own[use_own]
  }
  fill[is.na(fill)] <- "#cccccc"

  lab <- if ("name_raw" %in% names(nodes)) as.character(nodes$name_raw)
         else if ("label" %in% names(nodes)) gsub("\n", " ", as.character(nodes$label))
         else as.character(nodes$id)
  # Shorter labels in crowded rows: alternating sides give each label about
  # two node gaps of width.
  max_chars <- pmax(12L, pmin(30L, as.integer(120 / pmax(per_row, 1))))
  lab <- ifelse(nchar(lab) > max_chars, paste0(substr(lab, 1, max_chars - 1), "…"), lab)

  pol <- if ("polarity" %in% names(edges)) as.character(edges$polarity) else rep("+", nrow(edges))
  ecol <- ifelse(!is.na(pol) & pol == "-", EDGE_COLORS$opposing, EDGE_COLORS$reinforcing)

  n <- nrow(nodes)
  png(file, width = width, height = height, res = res)
  on.exit(dev.off())
  op <- par(mar = c(0, 0, 0, 0), family = "sans"); on.exit(par(op), add = TRUE, after = FALSE)
  # rescale = FALSE with fixed limits: the strip below y = -1.15 is kept for the legend
  # asp = 0: fill the wide image instead of igraph's square default
  plot(g, layout = xy, rescale = FALSE, asp = 0, xlim = c(-1.12, 1.12), ylim = c(-1.38, 1.1),
       vertex.color = fill, vertex.frame.color = "#555555",
       vertex.size = if (n > 60) 3 else if (n > 30) 4 else 5.5,
       vertex.label = lab, vertex.label.family = "sans",
       vertex.label.cex = if (n > 60) 0.5 else if (n > 30) 0.6 else 0.7,
       vertex.label.color = "#1a1a1a", vertex.label.dist = 1.2, vertex.label.degree = label_side,
       edge.color = ecol, edge.arrow.size = 0.3, edge.width = 1.1, edge.curved = 0.15)
  present <- intersect(names(pal), grp)
  if (length(present) > 0) {
    legend(x = -1.12, y = -1.2, legend = present, pt.bg = pal[present], pch = 21, pt.cex = 1.3,
           bty = "n", cex = 0.7, ncol = min(4L, length(present)), xpd = TRUE)
  }
  legend(x = 0.98, y = -1.2, legend = c("+", "-"), lwd = 2, bty = "n", cex = 0.7, xpd = TRUE,
         col = c(EDGE_COLORS$reinforcing, EDGE_COLORS$opposing))
  TRUE
}

#' Bar chart of the top leverage points (PNG) for the PowerPoint report
#' @param nodes CLD nodes with `leverage_score` (from Leverage Analysis)
#' @return TRUE if written, FALSE when no node has a positive score
report_leverage_png <- function(nodes, file, top_n = 10, width = 1600, height = 1000, res = 150) {
  if (is.null(nodes) || !is.data.frame(nodes) || !"leverage_score" %in% names(nodes)) return(FALSE)
  sc <- suppressWarnings(as.numeric(nodes$leverage_score))
  keep <- !is.na(sc) & sc > 0
  if (!any(keep)) return(FALSE)
  lab <- if ("name_raw" %in% names(nodes)) as.character(nodes$name_raw)
         else gsub("\n", " ", as.character(nodes$label %||% nodes$id))
  df <- data.frame(label = lab[keep], score = sc[keep], stringsAsFactors = FALSE)
  df <- head(df[order(-df$score), , drop = FALSE], top_n)
  df$label <- ifelse(nchar(df$label) > 40, paste0(substr(df$label, 1, 39), "…"), df$label)
  png(file, width = width, height = height, res = res)
  on.exit(dev.off())
  op <- par(mar = c(4, min(22, max(6, max(nchar(df$label)) * 0.5)), 1, 1)); on.exit(par(op), add = TRUE, after = FALSE)
  vals <- rev(df$score)
  top <- max(pretty(c(0, vals)))
  mids <- barplot(vals, names.arg = rev(df$label), horiz = TRUE, las = 1, col = "#457B9D",
                  cex.names = 0.8, xlim = c(0, top), xlab = "Leverage score")
  text(vals, mids, labels = format(round(vals, 2), nsmall = 2), pos = 4, cex = 0.7, xpd = TRUE)
  TRUE
}

# A minimal i18n object returning the English text of keys in one translation
# file (falls back to the key). For report graphs drawn by module plot helpers.
.report_english_i18n <- function(rel_path) {
  root <- if (exists("PROJECT_ROOT")) PROJECT_ROOT else "."
  tr <- tryCatch(
    jsonlite::fromJSON(file.path(root, "translations", rel_path), simplifyVector = FALSE)$translation,
    error = function(e) list())
  list(t = function(key, ...) {
    v <- tr[[key]]$en
    if (is.null(v) || !nzchar(v)) key else v
  })
}

# Add one picture slide (title + image filling the content area) to `ppt`.
# `aspect` = width / height of the PNG (the helpers above know it). The default
# officer template is a 10 x 7.5 in slide.
.ppt_add_image_slide <- function(ppt, title, png_file, aspect) {
  ppt <- officer::add_slide(ppt, layout = "Title Only", master = "Office Theme")
  ppt <- officer::ph_with(ppt, value = title, location = officer::ph_location_type(type = "title"))
  max_w <- 9; max_h <- 5.6
  w <- min(max_w, max_h * aspect); h <- w / aspect
  officer::ph_with(ppt, value = officer::external_img(png_file, width = w, height = h),
                   location = officer::ph_location(left = (10 - w) / 2, top = 1.6, width = w, height = h))
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

  # Helper: safely convert to data.frame
  safe_df <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.data.frame(x)) return(x)
    tryCatch(as.data.frame(x), error = function(e) NULL)
  }

  safe_nrow <- function(x) {
    if (is.null(x)) return(0)
    if (is.data.frame(x)) return(nrow(x))
    tryCatch(nrow(as.data.frame(x)), error = function(e) 0)
  }

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

    n_elements <- safe_nrow(data$data$isa_data$drivers) + safe_nrow(data$data$isa_data$activities) +
      safe_nrow(data$data$isa_data$pressures) + safe_nrow(data$data$isa_data$marine_processes) +
      safe_nrow(data$data$isa_data$ecosystem_services) + safe_nrow(data$data$isa_data$goods_benefits) +
      safe_nrow(data$data$isa_data$responses)

    project_name <- if (!is.null(data$data$metadata$project_name)) as.character(data$data$metadata$project_name)[1] else "Unnamed Project"
    n_nodes <- safe_nrow(data$data$cld$nodes)
    n_edges <- safe_nrow(data$data$cld$edges)
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

  # ISA Framework slides — helper to add element slides
  add_ppt_isa_slide <- function(ppt, element_data, slide_title) {
    df <- safe_df(element_data)
    if (!is.null(df) && nrow(df) > 0 && "Name" %in% names(df)) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = slide_title, location = officer::ph_location_type(type = "title"))
      element_text <- paste(paste("-", as.character(df$Name)), collapse = "\n")
      ppt <- officer::ph_with(ppt, value = as.character(element_text), location = officer::ph_location_type(type = "body"))
    }
    ppt
  }

  if ("isa" %in% sections) {
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$drivers, "ISA Framework: Drivers")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$activities, "ISA Framework: Activities")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$pressures, "ISA Framework: Pressures")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$marine_processes, "ISA Framework: Marine Processes & Functions")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$ecosystem_services, "ISA Framework: Ecosystem Services")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$goods_benefits, "ISA Framework: Goods & Benefits")
    ppt <- add_ppt_isa_slide(ppt, data$data$isa_data$responses, "ISA Framework: Responses")
  }

  # Graph PNGs are written to temp files that must outlive print(ppt).
  graph_files <- character(0)
  on.exit(unlink(graph_files), add = TRUE)
  new_png <- function() {
    f <- tempfile(fileext = ".png")
    graph_files <<- c(graph_files, f)
    f
  }

  # Network diagram (the "cld" section; it was ignored before L30)
  if ("cld" %in% sections) {
    f <- new_png()
    drawn <- tryCatch(report_network_png(safe_df(data$data$cld$nodes), safe_df(data$data$cld$edges), f),
                      error = function(e) {
                        debug_log(paste("PPT network diagram failed:", e$message), "REPORT")
                        FALSE
                      })
    if (isTRUE(drawn)) ppt <- .ppt_add_image_slide(ppt, "Network Diagram", f, aspect = 2000 / 1250)
  }

  # Feedback Loops. The loops module stores list(loop_info = <data frame, one
  # row per loop>, all_loops = ...); the slide used to count that list's two
  # parts, so it always said "Total Loops: 2".
  if ("loops" %in% sections && !is.null(data$data$analysis$loops)) {
    loop_info <- safe_df(data$data$analysis$loops$loop_info)
    if (!is.null(loop_info) && nrow(loop_info) > 0 && "Type" %in% names(loop_info)) {
      ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
      ppt <- officer::ph_with(ppt, value = "Feedback Loop Analysis", location = officer::ph_location_type(type = "title"))

      loops_text <- paste(
        paste("Total Loops:", nrow(loop_info)),
        paste("Reinforcing:", sum(loop_info$Type == "Reinforcing"), "(amplifying)"),
        paste("Balancing:", sum(loop_info$Type == "Balancing"), "(stabilizing)"),
        sep = "\n"
      )

      ppt <- officer::ph_with(ppt, value = as.character(loops_text), location = officer::ph_location_type(type = "body"))

      # Loop charts, drawn by the Loop Analysis module's own plot helper
      if (exists("loops_plot_png", mode = "function") && all(c("LoopID", "Length", "Elements") %in% names(loop_info))) {
        # The PowerPoint report is in English (like its slide titles), so the
        # chart labels come from the loops module's English translations.
        plain_i18n <- .report_english_i18n("modules/analysis_loops.json")
        for (chart in list(c("strength", "Loop Strength (Dominance)"),
                           c("type", "Loop Types"),
                           c("participation", "Element Participation in Loops"))) {
          f <- new_png()
          ok <- tryCatch({ loops_plot_png(chart[1], loop_info, plain_i18n, f); TRUE },
                         error = function(e) {
                           debug_log(paste("PPT loop chart", chart[1], "failed:", e$message), "REPORT")
                           FALSE
                         })
          if (ok) ppt <- .ppt_add_image_slide(ppt, chart[2], f, aspect = 1000 / 700)
        }
      }
    }
  }

  # Leverage Points
  if ("leverage" %in% sections && !is.null(data$data$cld$nodes)) {
    nodes <- safe_df(data$data$cld$nodes)
    if (!is.null(nodes) && "leverage_score" %in% names(nodes)) {
      nodes_with_leverage <- nodes[!is.na(nodes$leverage_score) & nodes$leverage_score > 0, , drop = FALSE]

      if (nrow(nodes_with_leverage) > 0) {
        nodes_with_leverage <- nodes_with_leverage[order(-nodes_with_leverage$leverage_score), , drop = FALSE]

        ppt <- officer::add_slide(ppt, layout = "Title and Content", master = "Office Theme")
        ppt <- officer::ph_with(ppt, value = "Top Leverage Points", location = officer::ph_location_type(type = "title"))

        top_nodes <- head(nodes_with_leverage, 10)
        leverage_text <- paste(
          paste(1:nrow(top_nodes), ".", as.character(top_nodes$label), "(Score:", round(top_nodes$leverage_score, 2), ")"),
          collapse = "\n"
        )

        ppt <- officer::ph_with(ppt, value = as.character(leverage_text), location = officer::ph_location_type(type = "body"))

        f <- new_png()
        drawn <- tryCatch(report_leverage_png(nodes, f),
                          error = function(e) {
                            debug_log(paste("PPT leverage chart failed:", e$message), "REPORT")
                            FALSE
                          })
        if (isTRUE(drawn)) ppt <- .ppt_add_image_slide(ppt, "Top Leverage Points (chart)", f, aspect = 1600 / 1000)
      }
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

# =============================================================================
# PURE HELPER — testable outside a Shiny session
# =============================================================================

#' Check Whether a Report Path Is Safe to Serve
#'
#' Returns TRUE only when \code{path} is a non-NULL character scalar that points
#' to an existing file. All five download handlers guard with
#' \code{req(report_path_is_servable(rv$<x>_report_path))} so that Shiny
#' silently aborts (no download, no error modal) when the report has not been
#' generated yet.
#'
#' @param path  A candidate file path (any R object accepted).
#' @return Logical scalar.
#' @export
report_path_is_servable <- function(path) {
  !is.null(path) && is.character(path) && length(path) == 1L && file.exists(path)
}
