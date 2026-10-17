# modules/wp5_readiness_module.R
# =============================================================================
# WP5 WS-9b (spec 2026-10-17 §6): D5.4 governance-readiness check — a PIMS page
# to enter (form) or import (template) anonymous questionnaire answers and see
# the toolbox indicator per NPG dimension. Logic: functions/wp5_readiness.R.
# =============================================================================

# i18n-ref: modules.wp5_readiness.answer.completely_agree
# i18n-ref: modules.wp5_readiness.answer.agree
# i18n-ref: modules.wp5_readiness.answer.neither
# i18n-ref: modules.wp5_readiness.answer.disagree
# i18n-ref: modules.wp5_readiness.answer.completely_disagree
# i18n-ref: modules.wp5_readiness.answer.dont_know
# i18n-ref: modules.wp5_readiness.answer.prefer_not
# i18n-ref: modules.wp5_readiness.answer.yes
# i18n-ref: modules.wp5_readiness.answer.no
# i18n-ref: modules.wp5_readiness.answer.sometimes
# i18n-ref: modules.wp5_readiness.answer.very_little
# i18n-ref: modules.wp5_readiness.answer.occasionally
# i18n-ref: modules.wp5_readiness.answer.neutral
# i18n-ref: modules.wp5_readiness.answer.regularly
# i18n-ref: modules.wp5_readiness.answer.very_much
# i18n-ref: modules.wp5_readiness.role.government
# i18n-ref: modules.wp5_readiness.role.manager
# i18n-ref: modules.wp5_readiness.role.researcher
# i18n-ref: modules.wp5_readiness.role.tourism_operator
# i18n-ref: modules.wp5_readiness.role.fishers
# i18n-ref: modules.wp5_readiness.role.civil_society
# i18n-ref: modules.wp5_readiness.role.industry
# i18n-ref: modules.wp5_readiness.role.general_public
# i18n-ref: modules.wp5_readiness.role.other
# i18n-ref: modules.wp5_readiness.role.prefer_not
# i18n-ref: modules.wp5_readiness.item.q3
# i18n-ref: modules.wp5_readiness.item.q4
# i18n-ref: modules.wp5_readiness.item.q5
# i18n-ref: modules.wp5_readiness.item.q6
# i18n-ref: modules.wp5_readiness.item.q7
# i18n-ref: modules.wp5_readiness.item.q8
# i18n-ref: modules.wp5_readiness.item.q9
# i18n-ref: modules.wp5_readiness.item.q10
# i18n-ref: modules.wp5_readiness.item.q13
# i18n-ref: modules.wp5_readiness.item.q15
# i18n-ref: modules.wp5_readiness.item.q16
# i18n-ref: modules.wp5_readiness.item.q17
# i18n-ref: modules.wp5_readiness.item.q18
# i18n-ref: modules.wp5_readiness.item.q19
# i18n-ref: modules.wp5_readiness.item.q35
# i18n-ref: modules.wp5_readiness.item.q36
# i18n-ref: modules.wp5_readiness.item.q37
# i18n-ref: modules.wp5_readiness.item.q38
# i18n-ref: modules.wp5_readiness.item.q39
# i18n-ref: modules.wp5_readiness.source.form
# i18n-ref: modules.wp5_readiness.source.import
# i18n-ref: modules.wp5_readiness.import_error.too_many_rows
# i18n-ref: modules.wp5_readiness.import_error.no_item_columns
# i18n-ref: modules.wp5_readiness.title
# i18n-ref: modules.wp5_readiness.subtitle
# i18n-ref: modules.wp5_readiness.tab_add
# i18n-ref: modules.wp5_readiness.tab_import
# i18n-ref: modules.wp5_readiness.tab_results
# i18n-ref: modules.wp5_readiness.consent_title
# i18n-ref: modules.wp5_readiness.consent_text
# i18n-ref: modules.wp5_readiness.consent_check
# i18n-ref: modules.wp5_readiness.consent_required
# i18n-ref: modules.wp5_readiness.nothing_to_save
# i18n-ref: modules.wp5_readiness.role
# i18n-ref: modules.wp5_readiness.translation_note
# i18n-ref: modules.wp5_readiness.source
# i18n-ref: modules.wp5_readiness.section_priority
# i18n-ref: modules.wp5_readiness.save
# i18n-ref: modules.wp5_readiness.saved_as
# i18n-ref: modules.wp5_readiness.no_project
# i18n-ref: modules.wp5_readiness.unavailable
# i18n-ref: modules.wp5_readiness.template_download
# i18n-ref: modules.wp5_readiness.template_help
# i18n-ref: modules.wp5_readiness.upload
# i18n-ref: modules.wp5_readiness.import_rows
# i18n-ref: modules.wp5_readiness.import_blanked
# i18n-ref: modules.wp5_readiness.import_ignored
# i18n-ref: modules.wp5_readiness.import_dropped
# i18n-ref: modules.wp5_readiness.import_add
# i18n-ref: modules.wp5_readiness.import_added
# i18n-ref: modules.wp5_readiness.context_import
# i18n-ref: modules.wp5_readiness.n_respondents
# i18n-ref: modules.wp5_readiness.indicator_label
# i18n-ref: modules.wp5_readiness.coverage_none
# i18n-ref: modules.wp5_readiness.coverage_low
# i18n-ref: modules.wp5_readiness.no_answers
# i18n-ref: modules.wp5_readiness.no_respondents
# i18n-ref: modules.wp5_readiness.answers_n
# i18n-ref: modules.wp5_readiness.items_title
# i18n-ref: modules.wp5_readiness.attitudes_title
# i18n-ref: modules.wp5_readiness.priorities_title
# i18n-ref: modules.wp5_readiness.rank_note
# i18n-ref: modules.wp5_readiness.mean_rank
# i18n-ref: modules.wp5_readiness.mean_points
# i18n-ref: modules.wp5_readiness.roles_title
# i18n-ref: modules.wp5_readiness.roles_hidden
# i18n-ref: modules.wp5_readiness.respondents_title
# i18n-ref: modules.wp5_readiness.col_respondent
# i18n-ref: modules.wp5_readiness.col_role
# i18n-ref: modules.wp5_readiness.col_date
# i18n-ref: modules.wp5_readiness.col_source
# i18n-ref: modules.wp5_readiness.delete_selected
# i18n-ref: modules.wp5_readiness.deleted
# i18n-ref: modules.wp5_readiness.export

wp5_readiness_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_readiness.", k))
  bank <- load_wp5_readiness_items()
  item_input <- function(it) {
    codes <- readiness_scale_codes(bank, it$scale)
    labels <- if (identical(it$scale, "rank5")) codes else vapply(codes, function(cd) tr(paste0("answer.", cd)), character(1))
    div(class = "mb-3",
      radioButtons(ns(paste0("ans_", it$id)), tr(paste0("item.", it$id)),
                   choices = stats::setNames(codes, labels), selected = character(0), inline = TRUE),
      tags$small(class = "text-muted", tr("source"), ": ", it$source_ref))
  }
  form <- if (is.null(bank)) div(class = "alert alert-warning", tr("unavailable")) else tagList(
    selectInput(ns("role"), tr("role"), choices = c(stats::setNames("", ""), stats::setNames(unlist(bank$roles),
      vapply(unlist(bank$roles), function(r) tr(paste0("role.", r)), character(1))))),
    lapply(NPG_DIMENSIONS, function(d) {
      its <- Filter(function(it) identical(it$dimension, d) && it$kind %in% c("state", "attitude"), bank$items)
      if (!length(its)) return(NULL)
      tagList(h5(class = "mt-3", wp5_vocab_label("npg", d, i18n)), lapply(its, item_input))
    }),
    h5(class = "mt-3", tr("section_priority")),
    lapply(Filter(function(it) identical(it$kind, "priority"), bank$items), item_input),
    p(class = "small text-muted", tr("translation_note")),
    actionButton(ns("save"), tr("save"), icon = icon("save"), class = "btn-primary"))
  tagList(
    h3(tr("title")), p(class = "text-muted", tr("subtitle")),
    tabsetPanel(id = ns("tabs"),
      tabPanel(tr("tab_add"),
        div(class = "alert alert-info mt-3", strong(tr("consent_title")), p(tr("consent_text")),
            checkboxInput(ns("consent"), tr("consent_check"), value = FALSE)),
        conditionalPanel(condition = sprintf("input['%s'] == true", ns("consent")), form)),
      tabPanel(tr("tab_import"),
        div(class = "mt-3",
          downloadButton(ns("template"), tr("template_download")),
          p(class = "small text-muted mt-2", tr("template_help")),
          fileInput(ns("upload"), tr("upload"), accept = c(".xlsx", ".csv")),
          uiOutput(ns("import_preview")))),
      tabPanel(tr("tab_results"),
        div(class = "mt-3", uiOutput(ns("results")),
            h5(class = "mt-4", tr("respondents_title")), DT::DTOutput(ns("respondent_table")),
            actionButton(ns("delete_selected"), tr("delete_selected"), icon = icon("trash"), class = "btn-danger mt-2"),
            downloadButton(ns("export"), tr("export"), class = "mt-2 ml-2"))))
  )
}

wp5_readiness_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_readiness.", k))
    bank <- load_wp5_readiness_items()

    readiness <- reactive({
      pd <- project_data_reactive()
      if (is.null(pd) || is.null(bank)) return(NULL)
      normalize_readiness(pd$data$pims$readiness, bank)
    })
    write_readiness <- function(rd) {
      pd <- project_data_reactive()
      if (is.null(pd)) return(invisible(NULL))
      pd$data$pims$readiness <- rd
      if (readiness_has_respondents(rd)) pd <- stamp_min_app_version(pd, WP5_READINESS_MIN_APP_VERSION)
      project_data_reactive(pd)
    }

    # ---- Add respondent ----
    observeEvent(input$save, {
      req(!is.null(bank))
      if (is.null(project_data_reactive())) { showNotification(tr("no_project"), type = "warning"); return() }
      if (!isTRUE(input$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      ids <- readiness_item_ids(bank)
      answers <- vapply(ids, function(i) { v <- input[[paste0("ans_", i)]]; if (length(v)) as.character(v[1]) else "" },
                        character(1))
      role <- input$role %||% ""
      if (!any(nzchar(answers)) && !nzchar(role)) { showNotification(tr("nothing_to_save"), type = "warning"); return() }
      row <- as.data.frame(c(list(Role = role), as.list(answers)), stringsAsFactors = FALSE)
      rd <- readiness_append(readiness(), row, "form", bank)
      write_readiness(rd)
      for (i in ids) updateRadioButtons(session, paste0("ans_", i), selected = character(0))
      updateSelectInput(session, "role", selected = "")
      updateCheckboxInput(session, "consent", value = FALSE)
      showNotification(paste(tr("saved_as"), utils::tail(rd$respondents$RespondentId, 1)), type = "message")
    })

    # ---- Import ----
    parsed <- reactiveVal(NULL)
    output$template <- downloadHandler(
      filename = function() "governance_readiness_template.xlsx",
      content = function(file) openxlsx::saveWorkbook(readiness_template_wb(bank, i18n), file, overwrite = TRUE))
    observeEvent(input$upload, {
      f <- input$upload; req(f, !is.null(bank))
      res <- tryCatch(readiness_parse_import(readiness_read_file(f$datapath, f$name), bank), error = function(e) {
        debug_log(paste("WP5 readiness: import failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_readiness.context_import"),
                         type = "error")
        NULL
      })
      parsed(res)
    })
    output$import_preview <- renderUI({
      pr <- parsed()
      if (is.null(pr)) return(NULL)
      if (!isTRUE(pr$ok)) {
        return(div(class = "alert alert-warning", tr(paste0("import_error.", pr$error)), " ",
                   if (length(pr$expected)) tags$small(paste(pr$expected, collapse = ", "))))
      }
      tagList(
        p(tr("import_rows"), " ", nrow(pr$rows), " · ", tr("import_blanked"), " ", pr$blanked, " · ",
          tr("import_ignored"), " ", length(pr$ignored), " · ", tr("import_dropped"), " ", pr$dropped_empty),
        if (length(pr$ignored)) tags$small(class = "text-muted d-block", paste(pr$ignored, collapse = ", ")),
        if (nrow(pr$rows)) actionButton(ns("import_confirm"), paste(tr("import_add"), nrow(pr$rows)), class = "btn-primary"))
    })
    observeEvent(input$import_confirm, {
      pr <- parsed(); req(isTRUE(pr$ok), nrow(pr$rows) > 0, !is.null(project_data_reactive()))
      write_readiness(readiness_append(readiness(), pr$rows, "import", bank))
      parsed(NULL)
      showNotification(paste(tr("import_added"), nrow(pr$rows)), type = "message")
    })

    # ---- Results ----
    item_text <- function(id) tr(paste0("item.", id))
    dim_row <- function(s) {
      bar <- if (identical(s$coverage, "none")) {
        tags$small(class = "text-muted", tr("coverage_none"))
      } else if (is.na(s$score)) {
        tags$small(class = "text-muted", tr("no_answers"))
      } else {
        pct <- round((s$score + 2) / 4 * 100)
        tagList(
          div(class = "progress", style = "height: 18px;",
              div(class = paste("progress-bar", if (s$score >= 0) "bg-success" else "bg-danger"),
                  style = sprintf("width: %d%%;", pct), sprintf("%.2f", s$score))),
          tags$small(class = "text-muted", tr("n_respondents"), ": ", s$n_respondents, " · ", s$n_answers, " ",
                     tr("answers_n"), if (identical(s$coverage, "low")) tagList(" · ", tr("coverage_low"))))
      }
      div(class = "mb-2", strong(wp5_vocab_label("npg", s$dimension, i18n)), bar)
    }
    counts_table <- function(resp, kind) {
      ct <- readiness_item_counts(resp, bank, kind)
      its <- unique(ct$item)
      tags$table(class = "table table-sm small", tags$tbody(lapply(its, function(id) {
        sub <- ct[ct$item == id & ct$n > 0, , drop = FALSE]
        cells <- paste(vapply(seq_len(nrow(sub)), function(i)
          paste0(tr(paste0("answer.", sub$code[i])), ": ", sub$n[i]), character(1)), collapse = "; ")
        mean_pts <- if (identical(kind, "state")) {
          v <- readiness_points(bank, id, resp[[id]]); if (any(!is.na(v))) sprintf("%.2f", mean(v, na.rm = TRUE)) else ""
        } else ""
        tags$tr(tags$td(item_text(id)), tags$td(cells), if (identical(kind, "state")) tags$td(mean_pts))
      })))
    }
    output$results <- renderUI({
      if (is.null(bank)) return(div(class = "alert alert-warning", tr("unavailable")))
      rd <- readiness()
      if (is.null(rd)) return(div(class = "alert alert-light", tr("no_project")))
      resp <- rd$respondents
      if (!nrow(resp)) return(div(class = "alert alert-light", tr("no_respondents")))
      sc <- readiness_score(resp, bank)
      pr <- readiness_priority(resp, bank)
      rb <- readiness_role_breakdown(resp, bank)
      tagList(
        p(strong(tr("n_respondents")), ": ", nrow(resp), " (", tr("source.form"), " ", sum(resp$Source == "form"),
          ", ", tr("source.import"), " ", sum(resp$Source == "import"), ")"),
        div(class = "alert alert-info small", tr("indicator_label")),
        lapply(seq_len(nrow(sc)), function(i) dim_row(sc[i, ])),
        h5(class = "mt-3", tr("items_title")), counts_table(resp, "state"),
        h5(class = "mt-3", tr("attitudes_title")), counts_table(resp, "attitude"),
        h5(class = "mt-3", tr("priorities_title")), tags$small(class = "text-muted", tr("rank_note")),
        tags$table(class = "table table-sm small", tags$tbody(lapply(seq_len(nrow(pr)), function(i)
          tags$tr(tags$td(item_text(pr$item[i])),
                  tags$td(tr("mean_rank"), ": ", if (is.na(pr$mean_rank[i])) "" else sprintf("%.1f", pr$mean_rank[i])),
                  tags$td("n = ", pr$n[i]))))),
        h5(class = "mt-3", tr("roles_title")),
        if (is.null(rb)) tags$small(class = "text-muted", tr("roles_hidden"))
        else tagList(tags$small(class = "text-muted", tr("roles_hidden")),
          tags$table(class = "table table-sm small", tags$tbody(lapply(seq_len(nrow(rb)), function(i)
            tags$tr(tags$td(tr(paste0("role.", rb$role[i]))), tags$td(wp5_vocab_label("npg", rb$dimension[i], i18n)),
                    tags$td(if (is.na(rb$score[i])) "" else sprintf("%.2f", rb$score[i]))))))))
    })
    respondents_view <- reactive({
      rd <- readiness(); req(rd)
      r <- rd$respondents
      data.frame(
        stats::setNames(list(r$RespondentId,
                             vapply(r$Role, function(x) if (nzchar(x)) as.character(tr(paste0("role.", x))) else "", ""),
                             r$EnteredAt,
                             vapply(r$Source, function(x) as.character(tr(paste0("source.", x))), "")),
                        c(tr("col_respondent"), tr("col_role"), tr("col_date"), tr("col_source"))),
        check.names = FALSE, stringsAsFactors = FALSE)
    })
    output$respondent_table <- DT::renderDT(DT::datatable(respondents_view(), selection = "multiple",
                                                          rownames = FALSE, options = list(pageLength = 10)))
    observeEvent(input$delete_selected, {
      sel <- input$respondent_table_rows_selected
      rd <- readiness(); req(rd, length(sel) > 0)
      ids <- rd$respondents$RespondentId[sel]
      write_readiness(readiness_delete(rd, ids, bank))
      showNotification(paste(tr("deleted"), length(ids)), type = "warning")
    })
    output$export <- downloadHandler(
      filename = function() "governance_readiness_answers.xlsx",
      content = function(file) openxlsx::saveWorkbook(readiness_export_wb(readiness(), bank, i18n), file, overwrite = TRUE))

    invisible(list(readiness = readiness))
  })
}
