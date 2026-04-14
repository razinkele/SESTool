# modules/feedback_admin_module.R
# Admin module: feedback log dashboard and duplicate detection
# Only loaded/rendered when ADMIN_MODE is TRUE (set in global.R)

feedback_admin_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)

  fluidPage(
    fluidRow(
      column(12,
        tags$h3(
          style = "margin-bottom: 20px;",
          tags$i(class = "fas fa-chart-bar", style = "margin-right: 8px;"),
          i18n$t("modules.feedback_admin.dashboard_tab")
        )
      )
    ),

    bs4TabCard(
      id = ns("admin_tabs"),
      width = 12,
      side = "left",
      status = "primary",
      solidHeader = FALSE,
      collapsible = FALSE,

      # ================================================================
      # Tab 1 – Feedback Dashboard
      # ================================================================
      tabPanel(
        title = tagList(
          tags$i(class = "fas fa-list", style = "margin-right: 5px;"),
          i18n$t("modules.feedback_admin.dashboard_tab")
        ),

        # Value boxes row
        fluidRow(
          column(2,
            bs4ValueBoxOutput(ns("vbox_total"), width = 12)
          ),
          column(2,
            bs4ValueBoxOutput(ns("vbox_bugs"), width = 12)
          ),
          column(2,
            bs4ValueBoxOutput(ns("vbox_suggestions"), width = 12)
          ),
          column(2,
            bs4ValueBoxOutput(ns("vbox_recent"), width = 12)
          ),
          column(2,
            bs4ValueBoxOutput(ns("vbox_github"), width = 12)
          ),
          column(2,
            bs4ValueBoxOutput(ns("vbox_local"), width = 12)
          )
        ),

        # Table
        fluidRow(
          column(12,
            bs4Card(
              width = 12,
              solidHeader = TRUE,
              status = "primary",
              title = i18n$t("modules.feedback_admin.dashboard_tab"),
              DT::dataTableOutput(ns("feedback_table"))
            )
          )
        ),

        # Detail modal placeholder
        uiOutput(ns("detail_modal_ui"))
      ),

      # ================================================================
      # Tab 2 – Duplicate Detection
      # ================================================================
      tabPanel(
        title = tagList(
          tags$i(class = "fas fa-copy", style = "margin-right: 5px;"),
          i18n$t("modules.feedback_admin.duplicates_tab")
        ),

        fluidRow(
          column(4,
            bs4Card(
              width = 12,
              solidHeader = TRUE,
              status = "warning",
              title = i18n$t("modules.feedback_admin.similarity_threshold"),
              sliderInput(
                ns("similarity_threshold"),
                label = NULL,
                min = 0.5, max = 0.95, value = 0.7, step = 0.05
              ),
              actionButton(
                ns("find_duplicates"),
                label = tagList(
                  tags$i(class = "fas fa-search", style = "margin-right: 5px;"),
                  i18n$t("modules.feedback_admin.find_duplicates")
                ),
                class = "btn btn-warning btn-block"
              ),
              tags$br(),
              actionButton(
                ns("recalculate"),
                label = tagList(
                  tags$i(class = "fas fa-sync-alt", style = "margin-right: 5px;"),
                  i18n$t("modules.feedback_admin.recalculate")
                ),
                class = "btn btn-outline-secondary btn-block"
              ),
              uiOutput(ns("scale_note_ui"))
            )
          ),
          column(8,
            bs4Card(
              width = 12,
              solidHeader = TRUE,
              status = "warning",
              title = i18n$t("modules.feedback_admin.duplicates_tab"),
              DT::dataTableOutput(ns("duplicates_table"))
            )
          )
        )
      )
    )
  )
}


feedback_admin_server <- function(id, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ------------------------------------------------------------------
    # Resolve log path
    # ------------------------------------------------------------------
    log_path <- if (exists("PROJECT_ROOT")) {
      file.path(PROJECT_ROOT, "data", "user_feedback_log.ndjson")
    } else {
      "data/user_feedback_log.ndjson"
    }

    # ------------------------------------------------------------------
    # Reactive: feedback data (loaded once on session start, refreshable)
    # ------------------------------------------------------------------
    rv <- reactiveValues(
      feedback_df   = NULL,
      dup_pairs     = NULL,
      selected_row  = NULL
    )

    # Load data once on session start
    observe({
      df <- tryCatch(
        load_feedback_log(log_path),
        error = function(e) {
          debug_log(paste("feedback_admin: load error:", e$message), "ERROR")
          data.frame(
            line_num = integer(0), type = character(0), title = character(0),
            description = character(0), steps = character(0),
            timestamp = character(0), github_url = character(0),
            duplicate_of = character(0), stringsAsFactors = FALSE
          )
        }
      )
      rv$feedback_df <- df
    }) |> bindEvent(session$clientData$url_search, once = TRUE)

    # ------------------------------------------------------------------
    # Value Boxes
    # ------------------------------------------------------------------
    output$vbox_total <- renderbs4ValueBox({
      df <- rv$feedback_df
      n  <- if (is.null(df)) 0L else nrow(df)
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.total_reports"),
        icon     = tags$i(class = "fas fa-comment-dots"),
        color    = "primary",
        width    = 12
      )
    })

    output$vbox_bugs <- renderbs4ValueBox({
      df <- rv$feedback_df
      n  <- if (is.null(df)) 0L else sum(df$type == "bug", na.rm = TRUE)
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.bug_reports"),
        icon     = tags$i(class = "fas fa-bug"),
        color    = "danger",
        width    = 12
      )
    })

    output$vbox_suggestions <- renderbs4ValueBox({
      df <- rv$feedback_df
      n  <- if (is.null(df)) 0L else sum(df$type == "suggestion", na.rm = TRUE)
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.suggestions"),
        icon     = tags$i(class = "fas fa-lightbulb"),
        color    = "success",
        width    = 12
      )
    })

    output$vbox_recent <- renderbs4ValueBox({
      df <- rv$feedback_df
      n  <- if (is.null(df) || nrow(df) == 0L) {
        0L
      } else {
        cutoff <- Sys.time() - 7 * 86400
        ts_parsed <- suppressWarnings(as.POSIXct(df$timestamp,
                                                  format = "%Y-%m-%dT%H:%M:%OSZ",
                                                  tz = "UTC"))
        sum(!is.na(ts_parsed) & ts_parsed >= cutoff, na.rm = TRUE)
      }
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.last_7_days"),
        icon     = tags$i(class = "fas fa-calendar-week"),
        color    = "info",
        width    = 12
      )
    })

    output$vbox_github <- renderbs4ValueBox({
      df <- rv$feedback_df
      n  <- if (is.null(df)) 0L else
        sum(!is.na(df$github_url) & nzchar(df$github_url) & df$github_url != "NA",
            na.rm = TRUE)
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.github_submitted"),
        icon     = tags$i(class = "fab fa-github"),
        color    = "secondary",
        width    = 12
      )
    })

    output$vbox_local <- renderbs4ValueBox({
      df <- rv$feedback_df
      n_total  <- if (is.null(df)) 0L else nrow(df)
      n_github <- if (is.null(df)) 0L else
        sum(!is.na(df$github_url) & nzchar(df$github_url) & df$github_url != "NA",
            na.rm = TRUE)
      n <- n_total - n_github
      bs4ValueBox(
        value    = n,
        subtitle = i18n$t("modules.feedback_admin.local_only"),
        icon     = tags$i(class = "fas fa-hdd"),
        color    = "warning",
        width    = 12
      )
    })

    # ------------------------------------------------------------------
    # Feedback DT table
    # ------------------------------------------------------------------
    output$feedback_table <- DT::renderDataTable({
      df <- rv$feedback_df

      if (is.null(df) || nrow(df) == 0L) {
        return(DT::datatable(
          data.frame(
            message = i18n$t("modules.feedback_admin.no_feedback"),
            stringsAsFactors = FALSE
          ),
          options = list(dom = "t"),
          rownames = FALSE
        ))
      }

      # Build display data.frame — validate URL starts with https:// to prevent XSS
      is_valid_url <- !is.na(df$github_url) & nzchar(df$github_url) &
                      df$github_url != "NA" & grepl("^https://", df$github_url)
      github_html <- ifelse(is_valid_url,
        paste0('<a href="', htmltools::htmlEscape(df$github_url),
               '" target="_blank" rel="noopener"><i class="fa fa-check-circle text-success"></i></a>'),
        '<i class="fa fa-times-circle text-muted"></i>'
      )

      disp <- data.frame(
        Date        = format(suppressWarnings(
          as.POSIXct(df$timestamp, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")),
          "%Y-%m-%d", tz = "UTC"),
        Type        = df$type,
        Title       = df$title,
        Description = ifelse(
          nchar(df$description) > 100,
          paste0(substr(df$description, 1, 100), "\u2026"),
          df$description
        ),
        GitHub      = github_html,
        stringsAsFactors = FALSE
      )

      DT::datatable(
        disp,
        colnames    = c(
          i18n$t("modules.feedback_admin.col_date"),
          i18n$t("modules.feedback_admin.col_type"),
          i18n$t("modules.feedback_admin.col_title"),
          i18n$t("modules.feedback_admin.col_description"),
          i18n$t("modules.feedback_admin.col_github")
        ),
        escape      = FALSE,
        selection   = "single",
        rownames    = FALSE,
        options     = list(
          pageLength = 15,
          order      = list(list(0, "desc")),
          dom        = "lfrtip",
          scrollX    = TRUE
        )
      )
    })

    # ------------------------------------------------------------------
    # Row click -> open detail modal
    # ------------------------------------------------------------------
    observeEvent(input$feedback_table_rows_selected, {
      idx <- input$feedback_table_rows_selected
      req(length(idx) > 0)

      df <- rv$feedback_df
      req(!is.null(df) && nrow(df) >= idx)

      row <- df[idx, , drop = FALSE]
      rv$selected_row <- row

      showModal(modalDialog(
        title = tagList(
          tags$i(class = "fas fa-file-alt", style = "margin-right: 8px;"),
          i18n$t("modules.feedback_admin.detail_title")
        ),
        tags$dl(
          tags$dt(i18n$t("modules.feedback_admin.col_date")),
          tags$dd(as.character(row$timestamp)),
          tags$dt(i18n$t("modules.feedback_admin.col_type")),
          tags$dd(as.character(row$type)),
          tags$dt(i18n$t("modules.feedback_admin.col_title")),
          tags$dd(as.character(row$title)),
          tags$dt(i18n$t("modules.feedback_admin.col_description")),
          tags$dd(as.character(row$description)),
          tags$dt(i18n$t("modules.feedback_admin.steps_label")),
          tags$dd(as.character(row$steps)),
          tags$dt(i18n$t("modules.feedback_admin.col_github")),
          tags$dd(if (!is.na(row$github_url) && nzchar(row$github_url) &&
                      grepl("^https://", row$github_url))
                    tags$a(href = row$github_url, target = "_blank", rel = "noopener", row$github_url)
                  else
                    tags$em("—"))
        ),
        footer = modalButton(i18n$t("common.buttons.close")),
        easyClose = TRUE,
        size = "l"
      ))
    })

    # ------------------------------------------------------------------
    # Duplicate detection
    # ------------------------------------------------------------------

    # Scale note when df > 500
    output$scale_note_ui <- renderUI({
      df <- rv$feedback_df
      if (!is.null(df) && nrow(df) > 500L) {
        tags$div(
          class = "alert alert-info",
          style = "margin-top: 10px; font-size: 12px;",
          tags$i(class = "fas fa-info-circle", style = "margin-right: 4px;"),
          i18n$t("modules.feedback_admin.scale_note")
        )
      }
    })

    # Reactive to hold current threshold (used by both buttons)
    run_detection <- reactiveVal(0)

    observeEvent(input$find_duplicates, {
      run_detection(run_detection() + 1L)
    })

    observeEvent(input$recalculate, {
      # Reload data first
      df <- tryCatch(
        load_feedback_log(log_path),
        error = function(e) {
          debug_log(paste("feedback_admin recalculate: load error:", e$message), "ERROR")
          rv$feedback_df
        }
      )
      rv$feedback_df <- df
      run_detection(run_detection() + 1L)
    })

    observe({
      req(run_detection() > 0)
      df <- rv$feedback_df
      req(!is.null(df) && nrow(df) >= 2)

      withProgress(message = i18n$t("modules.feedback_admin.find_duplicates"), {
        incProgress(0.3, detail = "Computing similarity...")
        pairs <- tryCatch(
          find_duplicate_pairs(df, threshold = input$similarity_threshold %||% 0.7),
          error = function(e) {
            debug_log(paste("feedback_admin dup detection error:", e$message), "ERROR")
            showNotification(i18n$t("modules.feedback_admin.mark_error"), type = "error")
            data.frame(line_num_a = integer(0), line_num_b = integer(0),
                       similarity = numeric(0), stringsAsFactors = FALSE)
          }
        )
        incProgress(0.7, detail = "Done")
        rv$dup_pairs <- pairs
      })
    })

    # ------------------------------------------------------------------
    # Duplicates DT table
    # ------------------------------------------------------------------
    output$duplicates_table <- DT::renderDataTable({
      pairs <- rv$dup_pairs

      if (is.null(pairs) || nrow(pairs) == 0L) {
        return(DT::datatable(
          data.frame(
            message = i18n$t("modules.feedback_admin.no_duplicates"),
            stringsAsFactors = FALSE
          ),
          options = list(dom = "t"),
          rownames = FALSE
        ))
      }

      df <- rv$feedback_df

      get_title <- function(line) {
        if (is.null(df)) return(as.character(line))
        idx <- which(df$line_num == line)
        if (length(idx) == 0L) return(as.character(line))
        paste0("[", line, "] ", substr(df$title[idx[1]], 1, 60))
      }

      ns_id <- ns("mark_dup")

      action_btns <- mapply(function(la, lb) {
        sprintf(
          '<button class="btn btn-xs btn-warning" onclick="Shiny.setInputValue(\'%s\', {line: %d, dup_of: %d, rand: Math.random()})">%s</button>',
          ns_id, lb, la,
          htmltools::htmlEscape(i18n$t("modules.feedback_admin.mark_duplicate"))
        )
      }, pairs$line_num_a, pairs$line_num_b, SIMPLIFY = TRUE)

      disp <- data.frame(
        Report_A   = vapply(pairs$line_num_a, get_title, character(1L)),
        Report_B   = vapply(pairs$line_num_b, get_title, character(1L)),
        Similarity = round(pairs$similarity, 3),
        Action     = action_btns,
        stringsAsFactors = FALSE
      )

      DT::datatable(
        disp,
        colnames = c(
          i18n$t("modules.feedback_admin.col_report_a"),
          i18n$t("modules.feedback_admin.col_report_b"),
          i18n$t("modules.feedback_admin.col_similarity"),
          i18n$t("modules.feedback_admin.col_action")
        ),
        escape   = FALSE,
        rownames = FALSE,
        options  = list(
          pageLength = 10,
          dom        = "lfrtip",
          order      = list(list(2, "desc")),
          scrollX    = TRUE
        )
      )
    })

    # ------------------------------------------------------------------
    # Handle mark-as-duplicate button clicks (set via JS onclick)
    # ------------------------------------------------------------------
    observeEvent(input$mark_dup, {
      req(!is.null(input$mark_dup$line))

      line_num <- as.integer(input$mark_dup$line)
      dup_of   <- as.integer(input$mark_dup$dup_of)

      # Build a reference string: use the original line's title if available
      df <- rv$feedback_df
      orig_idx <- if (!is.null(df)) which(df$line_num == dup_of) else integer(0)
      dup_ref  <- if (length(orig_idx) > 0L) {
        paste0("line:", dup_of, " - ", df$title[orig_idx[1]])
      } else {
        paste0("line:", dup_of)
      }

      success <- tryCatch(
        mark_as_duplicate(log_path, line_num = line_num, duplicate_of_line = dup_ref),
        error = function(e) {
          debug_log(paste("feedback_admin mark_dup error:", e$message), "ERROR")
          FALSE
        }
      )

      if (success) {
        showNotification(
          i18n$t("modules.feedback_admin.marked_duplicate"),
          type = "message"
        )
        # Reload and re-detect
        df <- tryCatch(load_feedback_log(log_path), error = function(e) rv$feedback_df)
        rv$feedback_df <- df
        run_detection(run_detection() + 1L)
      } else {
        showNotification(
          i18n$t("modules.feedback_admin.mark_error"),
          type = "error"
        )
      }
    }, ignoreInit = TRUE)

  })
}
