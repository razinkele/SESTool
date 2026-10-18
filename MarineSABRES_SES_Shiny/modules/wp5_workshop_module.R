# modules/wp5_workshop_module.R
# =============================================================================
# WP5 WS-10 (spec 2026-10-18): D5.2 workshop elicitation - a PIMS page to set up
# a workshop (measures, poll, tenets), enter or import participant answers, see
# the results, and apply the tenet outcome to the register (undoable).
# Logic: functions/wp5_workshop.R.
# =============================================================================

# i18n-ref: modules.wp5_workshop.answer.agree
# i18n-ref: modules.wp5_workshop.answer.completely_agree
# i18n-ref: modules.wp5_workshop.answer.completely_disagree
# i18n-ref: modules.wp5_workshop.answer.disagree
# i18n-ref: modules.wp5_workshop.answer.dont_know
# i18n-ref: modules.wp5_workshop.answer.neutral
# i18n-ref: modules.wp5_workshop.answer.blank
# i18n-ref: modules.wp5_workshop.applied
# i18n-ref: modules.wp5_workshop.apply_button
# i18n-ref: modules.wp5_workshop.apply_intro
# i18n-ref: modules.wp5_workshop.apply_tenets_off
# i18n-ref: modules.wp5_workshop.apply_unavailable
# i18n-ref: modules.wp5_workshop.cancel
# i18n-ref: modules.wp5_workshop.col_criterion
# i18n-ref: modules.wp5_workshop.col_current
# i18n-ref: modules.wp5_workshop.col_date
# i18n-ref: modules.wp5_workshop.col_mean
# i18n-ref: modules.wp5_workshop.col_measure
# i18n-ref: modules.wp5_workshop.col_median
# i18n-ref: modules.wp5_workshop.col_n
# i18n-ref: modules.wp5_workshop.col_participant
# i18n-ref: modules.wp5_workshop.col_proposed
# i18n-ref: modules.wp5_workshop.col_source
# i18n-ref: modules.wp5_workshop.col_tenet
# i18n-ref: modules.wp5_workshop.col_workshop
# i18n-ref: modules.wp5_workshop.consent_check
# i18n-ref: modules.wp5_workshop.consent_required
# i18n-ref: modules.wp5_workshop.consent_text
# i18n-ref: modules.wp5_workshop.consent_title
# i18n-ref: modules.wp5_workshop.context_import
# i18n-ref: modules.wp5_workshop.criteria_required
# i18n-ref: modules.wp5_workshop.criterion.feasibility
# i18n-ref: modules.wp5_workshop.criterion.importance
# i18n-ref: modules.wp5_workshop.criterion.long_term_impact
# i18n-ref: modules.wp5_workshop.delete
# i18n-ref: modules.wp5_workshop.delete_applied_note
# i18n-ref: modules.wp5_workshop.delete_confirm_text
# i18n-ref: modules.wp5_workshop.delete_resp_text
# i18n-ref: modules.wp5_workshop.delete_selected
# i18n-ref: modules.wp5_workshop.deleted
# i18n-ref: modules.wp5_workshop.duplicate
# i18n-ref: modules.wp5_workshop.export
# i18n-ref: modules.wp5_workshop.field_criteria
# i18n-ref: modules.wp5_workshop.field_date
# i18n-ref: modules.wp5_workshop.field_measures
# i18n-ref: modules.wp5_workshop.field_note
# i18n-ref: modules.wp5_workshop.field_scale
# i18n-ref: modules.wp5_workshop.field_tenets_on
# i18n-ref: modules.wp5_workshop.field_title
# i18n-ref: modules.wp5_workshop.heat_title
# i18n-ref: modules.wp5_workshop.import_add
# i18n-ref: modules.wp5_workshop.import_added
# i18n-ref: modules.wp5_workshop.import_blanked
# i18n-ref: modules.wp5_workshop.import_dropped
# i18n-ref: modules.wp5_workshop.import_error.foreign_columns
# i18n-ref: modules.wp5_workshop.import_error.no_answer_columns
# i18n-ref: modules.wp5_workshop.import_error.too_many_rows
# i18n-ref: modules.wp5_workshop.import_ignored
# i18n-ref: modules.wp5_workshop.import_rows
# i18n-ref: modules.wp5_workshop.invalid_ids
# i18n-ref: modules.wp5_workshop.locked_note
# i18n-ref: modules.wp5_workshop.matches_register
# i18n-ref: modules.wp5_workshop.measure_gone
# i18n-ref: modules.wp5_workshop.n_participants
# i18n-ref: modules.wp5_workshop.new
# i18n-ref: modules.wp5_workshop.no_measures
# i18n-ref: modules.wp5_workshop.no_participants
# i18n-ref: modules.wp5_workshop.no_project
# i18n-ref: modules.wp5_workshop.no_workshop
# i18n-ref: modules.wp5_workshop.not_in_register
# i18n-ref: modules.wp5_workshop.nothing_to_save
# i18n-ref: modules.wp5_workshop.participants_title
# i18n-ref: modules.wp5_workshop.poll_title
# i18n-ref: modules.wp5_workshop.question.admin_achievable
# i18n-ref: modules.wp5_workshop.question.communicable
# i18n-ref: modules.wp5_workshop.question.culturally_inclusive
# i18n-ref: modules.wp5_workshop.question.ecol_effective
# i18n-ref: modules.wp5_workshop.question.econ_efficient
# i18n-ref: modules.wp5_workshop.question.econ_viable
# i18n-ref: modules.wp5_workshop.question.ethically_defensible
# i18n-ref: modules.wp5_workshop.question.legally_permissible
# i18n-ref: modules.wp5_workshop.question.politically_expedient
# i18n-ref: modules.wp5_workshop.question.socially_desirable
# i18n-ref: modules.wp5_workshop.question.tech_feasible
# i18n-ref: modules.wp5_workshop.ranking_title
# i18n-ref: modules.wp5_workshop.register_empty
# i18n-ref: modules.wp5_workshop.save_participant
# i18n-ref: modules.wp5_workshop.save_setup
# i18n-ref: modules.wp5_workshop.saved_as
# i18n-ref: modules.wp5_workshop.scale.four
# i18n-ref: modules.wp5_workshop.scale.pm5
# i18n-ref: modules.wp5_workshop.setup_saved
# i18n-ref: modules.wp5_workshop.source.form
# i18n-ref: modules.wp5_workshop.source.import
# i18n-ref: modules.wp5_workshop.source_template
# i18n-ref: modules.wp5_workshop.subtitle
# i18n-ref: modules.wp5_workshop.tab_apply
# i18n-ref: modules.wp5_workshop.tab_entry
# i18n-ref: modules.wp5_workshop.tab_results
# i18n-ref: modules.wp5_workshop.tab_setup
# i18n-ref: modules.wp5_workshop.template_download
# i18n-ref: modules.wp5_workshop.template_help
# i18n-ref: modules.wp5_workshop.tenet_source
# i18n-ref: modules.wp5_workshop.yes
# i18n-ref: modules.wp5_workshop.no
# i18n-ref: modules.wp5_workshop.tenets_title
# i18n-ref: modules.wp5_workshop.title
# i18n-ref: modules.wp5_workshop.too_few
# i18n-ref: modules.wp5_workshop.translation_note
# i18n-ref: modules.wp5_workshop.unavailable
# i18n-ref: modules.wp5_workshop.undo_button
# i18n-ref: modules.wp5_workshop.undo_changed
# i18n-ref: modules.wp5_workshop.undone
# i18n-ref: modules.wp5_workshop.upload
# i18n-ref: modules.wp5_workshop.workshop
# i18n-ref: modules.response.governance.tenet_level.minimal
# i18n-ref: modules.response.governance.tenet_level.intermediate
# i18n-ref: modules.response.governance.tenet_level.full
# i18n-ref: modules.response.governance.tenet_level.not_assessed

wp5_workshop_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_workshop.", k))
  tagList(
    h3(tr("title")), p(class = "text-muted", tr("subtitle")),
    fluidRow(
      column(5, selectInput(ns("workshop"), tr("workshop"), choices = c(" " = ""))),
      column(7, div(class = "mt-4",
        actionButton(ns("new"), tr("new"), icon = icon("plus"), class = "btn-primary"),
        actionButton(ns("duplicate"), tr("duplicate"), icon = icon("copy")),
        actionButton(ns("delete"), tr("delete"), icon = icon("trash"), class = "btn-danger")))),
    tabsetPanel(id = ns("tabs"),
      tabPanel(tr("tab_setup"), div(class = "mt-3", uiOutput(ns("setup")))),
      tabPanel(tr("tab_entry"), div(class = "mt-3", uiOutput(ns("entry")),
        h5(class = "mt-4", tr("template_download")),
        downloadButton(ns("template"), tr("template_download")),
        p(class = "small text-muted mt-2", tr("template_help")),
        fileInput(ns("upload"), tr("upload"), accept = c(".xlsx", ".csv")),
        uiOutput(ns("import_preview")),
        h5(class = "mt-4", tr("participants_title")), DT::DTOutput(ns("respondent_table")),
        actionButton(ns("delete_resp"), tr("delete_selected"), icon = icon("trash"), class = "btn-danger mt-2"))),
      tabPanel(tr("tab_results"), div(class = "mt-3", uiOutput(ns("results")),
        downloadButton(ns("export"), tr("export"), class = "mt-2"))),
      tabPanel(tr("tab_apply"), div(class = "mt-3", uiOutput(ns("apply")))))
  )
}

wp5_workshop_server <- function(id, project_data_reactive, i18n, event_bus = NULL, register = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_workshop.", k))
    qs <- load_wp5_tenet_questions()
    level_label <- function(x) i18n$t(paste0("modules.response.governance.tenet_level.", if (nzchar(x %||% "")) x else "not_assessed"))

    store <- reactive({
      pd <- project_data_reactive()
      if (is.null(pd)) NULL else normalize_workshops(pd$data$pims$workshops)
    })
    measures <- reactive({
      if (!is.null(register)) normalize_response_measures(register$measures())
      else normalize_response_measures(project_data_reactive()$data$response_measures$measures)
    })
    # single write path: always starts from the CURRENT project (spec §6 ordering guard)
    modify_store <- function(f) {
      pd <- project_data_reactive()
      if (is.null(pd)) { showNotification(tr("no_project"), type = "warning"); return(invisible(NULL)) }
      st <- normalize_workshops(f(normalize_workshops(pd$data$pims$workshops)))
      pd$data$pims$workshops <- st
      if (workshops_need_version(st, pd$data$response_measures$measures))
        pd <- stamp_min_app_version(pd, WP5_WORKSHOP_MIN_APP_VERSION)
      project_data_reactive(pd)
      invisible(st)
    }
    current <- reactive({
      st <- store(); id <- input$workshop
      if (is.null(st) || is.null(id) || !nzchar(id)) NULL else workshop_get(st, id)
    })
    want_select <- reactiveVal(NULL)   # id of a just-created workshop; consumed by the list observer

    observe({
      st <- store(); req(st)
      ids <- vapply(st$items, `[[`, "", "id")
      labels <- vapply(st$items, function(w) if (nzchar(w$title)) paste(w$id, "-", w$title) else w$id, "")
      sel <- workshop_pick_selection(ids, isolate(input$workshop), isolate(want_select()))
      isolate(want_select(NULL))
      updateSelectInput(session, "workshop", choices = c(" " = "", stats::setNames(ids, labels)), selected = sel)
    })

    # ---- Workshop list ----
    observeEvent(input$new, {
      st <- modify_store(function(st) workshop_create(st))
      if (!is.null(st) && length(st$items)) want_select(st$items[[length(st$items)]]$id)
    })
    observeEvent(input$duplicate, {
      ws <- current(); req(ws)
      st <- modify_store(function(st) workshop_duplicate(st, ws$id))
      if (!is.null(st) && length(st$items)) want_select(st$items[[length(st$items)]]$id)
    })
    observeEvent(input$delete, {
      ws <- current(); req(ws)
      showModal(modalDialog(
        p(tr("delete_confirm_text"), " ", ws$id, " (", tr("n_participants"), ": ", nrow(ws$respondents), ")"),
        if (length(ws$applied)) p(class = "text-warning", tr("delete_applied_note")),
        footer = tagList(modalButton(tr("cancel")), actionButton(ns("delete_confirm"), tr("delete"), class = "btn-danger"))))
    })
    observeEvent(input$delete_confirm, {
      ws <- current(); req(ws)
      modify_store(function(st) workshop_remove(st, ws$id))
      removeModal()
    })

    # ---- Set-up ----
    output$setup <- renderUI({
      st <- store()
      if (is.null(st)) return(div(class = "alert alert-light", tr("no_project")))
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      m <- measures()
      ok <- workshop_valid_measure_id(m$ID)
      choices <- stats::setNames(m$ID[ok], paste(m$ID[ok], "\u2014", m$Name[ok]))
      locked <- workshop_has_respondents(ws)
      crit_choices <- stats::setNames(WORKSHOP_POLL_CRITERIA, vapply(WORKSHOP_POLL_CRITERIA, function(c) tr(paste0("criterion.", c)), ""))
      scale_choices <- stats::setNames(names(WORKSHOP_POLL_SCALES), vapply(names(WORKSHOP_POLL_SCALES), function(s) tr(paste0("scale.", s)), ""))
      tagList(
        textInput(ns("title"), tr("field_title"), value = ws$title),
        dateInput(ns("date"), tr("field_date"), value = if (nzchar(ws$date)) ws$date else NULL),
        textInput(ns("note"), tr("field_note"), value = ws$note),
        if (locked) tagList(
          div(class = "alert alert-info small", tr("locked_note")),
          p(strong(paste0(tr("field_measures"), ":")), " ", paste(ws$interventions, collapse = ", ")),
          p(strong(paste0(tr("field_scale"), ":")), " ", tr(paste0("scale.", ws$poll$scale))),
          p(strong(paste0(tr("field_criteria"), ":")), " ", paste(vapply(ws$poll$criteria, function(c) tr(paste0("criterion.", c)), ""), collapse = ", ")),
          p(strong(paste0(tr("field_tenets_on"), ":")), " ", if (ws$tenets_on) tr("yes") else tr("no")))
        else tagList(
          if (!nrow(m)) div(class = "alert alert-warning", tr("register_empty")),
          selectizeInput(ns("interventions"), tr("field_measures"), choices = choices, selected = ws$interventions,
                         multiple = TRUE, options = list(plugins = list("remove_button"))),
          if (any(!ok)) tags$small(class = "text-muted d-block", tr("invalid_ids"), " ", paste(m$ID[!ok], collapse = ", ")),
          radioButtons(ns("scale"), tr("field_scale"), choices = scale_choices, selected = ws$poll$scale, inline = TRUE),
          checkboxGroupInput(ns("criteria"), tr("field_criteria"), choices = crit_choices, selected = ws$poll$criteria, inline = TRUE),
          checkboxInput(ns("tenets_on"), tr("field_tenets_on"), value = ws$tenets_on)),
        actionButton(ns("save_setup"), tr("save_setup"), icon = icon("save"), class = "btn-primary"))
    })
    observeEvent(input$save_setup, {
      ws <- current(); req(ws)
      fields <- list(title = input$title %||% "", date = as.character(input$date %||% ""), note = input$note %||% "")
      if (!workshop_has_respondents(ws)) {
        crit <- as.character(input$criteria %||% character(0))
        if (!length(crit)) { showNotification(tr("criteria_required"), type = "warning"); return() }
        fields <- c(fields, list(interventions = as.character(input$interventions %||% character(0)),
                                 poll = list(scale = input$scale %||% "pm5", criteria = crit),
                                 tenets_on = isTRUE(input$tenets_on)))
      }
      modify_store(function(st) workshop_set(st, workshop_update_setup(workshop_get(st, ws$id), fields)))
      showNotification(tr("setup_saved"), type = "message")
    })

    # ---- Entry ----
    observeEvent(input$consent, {
      ws <- current(); req(ws)
      if (!identical(isTRUE(input$consent), isTRUE(ws$consent))) {
        modify_store(function(st) { w <- workshop_get(st, ws$id); w$consent <- isTRUE(input$consent); workshop_set(st, w) })
      }
    }, ignoreInit = TRUE)
    output$entry <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (is.null(qs)) return(div(class = "alert alert-warning", tr("unavailable")))
      consent_box <- div(class = "alert alert-info", strong(tr("consent_title")), p(tr("consent_text")),
                         checkboxInput(ns("consent"), tr("consent_check"), value = ws$consent))
      if (!length(ws$interventions)) return(tagList(consent_box, div(class = "alert alert-light", tr("no_measures"))))
      m <- measures()
      scale_vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
      # UI-only blank choice (saves ""); deliberately not part of WORKSHOP_TENET_ANSWERS or import matching
      tenet_choices <- c(stats::setNames("", tr("answer.blank")),
                         stats::setNames(WORKSHOP_TENET_ANSWERS, vapply(WORKSHOP_TENET_ANSWERS, function(cd) tr(paste0("answer.", cd)), "")))
      form <- tagList(lapply(ws$interventions, function(mid) {
        nm <- m$Name[match(mid, m$ID)]
        div(class = "card card-body mb-3",
          h5(mid, if (!is.na(nm)) paste(" \u2014", nm) else tagList(" ", tr("not_in_register"))),
          h6(tr("poll_title")),
          fluidRow(lapply(ws$poll$criteria, function(cr) column(4,
            selectInput(ns(paste0("a_", workshop_rank_col(mid, cr))), tr(paste0("criterion.", cr)),
                        choices = c(" " = "", stats::setNames(scale_vals, gsub("-", "\u2212", scale_vals, fixed = TRUE))))))),
          if (ws$tenets_on) tagList(h6(tr("tenets_title")), lapply(EBM_TENETS$code, function(t) div(class = "mb-2",
            radioButtons(ns(paste0("a_", workshop_tenet_col(mid, t))), wp5_vocab_label("tenet", t, i18n),
                         choices = tenet_choices, selected = "", inline = TRUE),
            tags$small(class = "text-muted", tr(paste0("question.", t)))))))
      }), p(class = "small text-muted", tr("translation_note")),
      actionButton(ns("save_participant"), tr("save_participant"), icon = icon("save"), class = "btn-primary"))
      tagList(consent_box, conditionalPanel(sprintf("input['%s'] == true", ns("consent")), form))
    })
    observeEvent(input$save_participant, {
      ws <- current(); req(ws)
      if (!isTRUE(ws$consent) && !isTRUE(input$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      cols <- workshop_answer_columns(ws)
      vals <- vapply(cols, function(cl) { v <- input[[paste0("a_", cl)]]; if (length(v)) as.character(v[1]) else "" }, "")
      if (!any(nzchar(vals))) { showNotification(tr("nothing_to_save"), type = "warning"); return() }
      row <- as.data.frame(as.list(vals), stringsAsFactors = FALSE, check.names = FALSE)
      st <- modify_store(function(st) {
        w <- workshop_get(st, ws$id); w$consent <- TRUE
        workshop_set(st, workshop_append(w, row, "form"))
      })
      if (!is.null(st)) showNotification(paste(tr("saved_as"), utils::tail(workshop_get(st, ws$id)$respondents$RespondentId, 1)),
                                         type = "message")
    })

    # ---- Import ----
    parsed <- reactiveVal(NULL)
    observeEvent(input$workshop, parsed(NULL), ignoreInit = TRUE)   # a preview belongs to the workshop it was parsed for
    output$template <- downloadHandler(
      filename = function() "workshop_template.xlsx",
      content = function(file) openxlsx::saveWorkbook(workshop_template_wb(current(), measures(), i18n), file, overwrite = TRUE))
    observeEvent(input$upload, {
      f <- input$upload; ws <- current(); req(f, ws)
      parsed(tryCatch({
        pr <- workshop_parse_import(readiness_read_file(f$datapath, f$name), ws)
        pr$ws_id <- ws$id
        pr
      }, error = function(e) {
        debug_log(paste("WP5 workshop: import failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_workshop.context_import"), type = "error")
        NULL
      }))
    })
    output$import_preview <- renderUI({
      pr <- parsed()
      if (is.null(pr)) return(NULL)
      if (!isTRUE(pr$ok)) return(div(class = "alert alert-warning", tr(paste0("import_error.", pr$error)), " ",
                                     if (length(pr$expected)) tags$small(paste(pr$expected, collapse = ", "))))
      tagList(
        p(tr("import_rows"), " ", nrow(pr$rows), " \u00b7 ", tr("import_blanked"), " ", pr$blanked, " \u00b7 ",
          tr("import_ignored"), " ", length(pr$ignored), " \u00b7 ", tr("import_dropped"), " ", pr$dropped_empty),
        if (length(pr$ignored)) tags$small(class = "text-muted d-block", paste(pr$ignored, collapse = ", ")),
        if (nrow(pr$rows)) actionButton(ns("import_confirm"), paste(tr("import_add"), nrow(pr$rows)), class = "btn-primary"))
    })
    observeEvent(input$import_confirm, {
      pr <- parsed(); ws <- current(); req(isTRUE(pr$ok), nrow(pr$rows) > 0, ws, identical(pr$ws_id, ws$id))
      if (!isTRUE(ws$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      modify_store(function(st) workshop_set(st, workshop_append(workshop_get(st, ws$id), pr$rows, "import")))
      parsed(NULL)
      showNotification(paste(tr("import_added"), nrow(pr$rows)), type = "message")
    })

    # ---- Participants ----
    respondents_view <- reactive({
      ws <- current(); req(ws)
      r <- ws$respondents
      data.frame(stats::setNames(list(r$RespondentId, r$EnteredAt,
                                      vapply(r$Source, function(x) as.character(tr(paste0("source.", x))), "")),
                                 c(tr("col_participant"), tr("col_date"), tr("col_source"))),
                 check.names = FALSE, stringsAsFactors = FALSE)
    })
    output$respondent_table <- DT::renderDT(DT::datatable(respondents_view(), selection = "multiple",
                                                          rownames = FALSE, options = list(pageLength = 10)))
    pending_delete <- reactiveVal(character(0))
    observeEvent(input$delete_resp, {
      ws <- current(); sel <- input$respondent_table_rows_selected; req(ws, length(sel) > 0)
      pending_delete(ws$respondents$RespondentId[sel])
      showModal(modalDialog(p(tr("delete_resp_text"), " ", paste(pending_delete(), collapse = ", ")),
        footer = tagList(modalButton(tr("cancel")), actionButton(ns("delete_resp_confirm"), tr("delete_selected"), class = "btn-danger"))))
    })
    observeEvent(input$delete_resp_confirm, {
      ws <- current(); ids <- pending_delete(); req(ws, length(ids) > 0)
      modify_store(function(st) workshop_set(st, workshop_delete_respondents(workshop_get(st, ws$id), ids)))
      pending_delete(character(0)); removeModal()
      showNotification(paste(tr("deleted"), length(ids)), type = "warning")
    })

    # ---- Results ----
    output$results <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (!workshop_has_respondents(ws)) return(div(class = "alert alert-light", tr("no_participants")))
      m <- measures()
      name_of <- function(id) { nm <- m$Name[match(id, m$ID)]; if (is.na(nm)) paste(id, tr("not_in_register")) else paste(id, "\u2014", nm) }
      ps <- workshop_poll_summary(ws); ct <- workshop_poll_counts(ws)
      bars <- function(mid, cr) {
        sub <- ct[ct$measure == mid & ct$criterion == cr, ]
        mx <- max(1L, sub$n)
        div(class = "d-flex align-items-end", style = "height: 40px; gap: 2px;", lapply(seq_len(nrow(sub)), function(i)
          div(title = paste0(sub$value[i], ": ", sub$n[i]), class = "bg-info",
              style = sprintf("width: 14px; height: %dpx;", max(1L, round(36 * sub$n[i] / mx))))))
      }
      ts <- workshop_tenet_summary(ws)
      band <- function(med, nv) if (nv < WORKSHOP_MIN_VALID || is.na(med)) "#e9ecef" else if (med >= 4) "#c3e6cb" else if (med >= 3) "#ffeeba" else "#f5c6cb"
      tagList(
        p(strong(tr("n_participants")), ": ", nrow(ws$respondents)),
        h5(tr("ranking_title")),
        tags$table(class = "table table-sm small",
          tags$thead(tags$tr(tags$th(tr("col_measure")), tags$th(tr("col_criterion")), tags$th(tr("col_n")),
                             tags$th(tr("col_median")), tags$th(tr("col_mean")), tags$th(""))),
          tags$tbody(lapply(seq_len(nrow(ps)), function(i) tags$tr(
            tags$td(name_of(ps$measure[i])), tags$td(tr(paste0("criterion.", ps$criterion[i]))), tags$td(ps$n[i]),
            tags$td(if (is.na(ps$median[i])) "" else format(ps$median[i])),
            tags$td(if (is.na(ps$mean[i])) "" else sprintf("%.2f", ps$mean[i])),
            tags$td(bars(ps$measure[i], ps$criterion[i])))))),
        if (nrow(ts)) tagList(h5(class = "mt-3", tr("heat_title")),
          tags$table(class = "table table-sm small",
            tags$thead(tags$tr(tags$th(tr("col_tenet")), lapply(ws$interventions, function(mid) tags$th(mid)))),
            tags$tbody(lapply(EBM_TENETS$code, function(t) tags$tr(tags$td(wp5_vocab_label("tenet", t, i18n)),
              lapply(ws$interventions, function(mid) {
                s <- ts[ts$measure == mid & ts$tenet == t, ]
                tags$td(style = paste0("background:", band(s$median, s$n_valid), ";"),
                        title = paste0(tr("col_n"), " = ", s$n_valid, "; ", tr("answer.dont_know"), ": ", s$n_dont_know),
                        if (s$n_valid < WORKSHOP_MIN_VALID) tr("too_few") else format(s$median))
              })))))))
    })
    output$export <- downloadHandler(
      filename = function() paste0("workshop_", current()$id %||% "", ".xlsx"),
      content = function(file) openxlsx::saveWorkbook(workshop_export_wb(current(), i18n), file, overwrite = TRUE))

    # ---- Apply to register (spec §6) ----
    output$apply <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (is.null(register)) return(div(class = "alert alert-warning", tr("apply_unavailable")))
      if (!ws$tenets_on) return(div(class = "alert alert-light", tr("apply_tenets_off")))
      m <- measures()
      pr <- workshop_writeback_proposal(ws, m)
      send <- function(input_id, mid) sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns(input_id), mid)
      tagList(p(class = "small text-muted", tr("apply_intro")), lapply(ws$interventions, function(mid) {
        i <- match(mid, m$ID)
        if (is.na(i)) return(div(class = "card card-body mb-2", strong(mid), " ", tr("not_in_register")))
        rows <- pr[pr$measure == mid, ]
        last <- workshop_last_apply(ws, mid)
        div(class = "card card-body mb-3",
          h5(mid, " \u2014 ", m$Name[i]),
          if (nzchar(m$TenetSource[i])) tags$small(class = "text-muted d-block", paste0(tr("tenet_source"), ": ", m$TenetSource[i])),
          tags$table(class = "table table-sm small",
            tags$thead(tags$tr(tags$th(tr("col_tenet")), tags$th(tr("col_current")), tags$th(tr("col_workshop")), tags$th(tr("col_proposed")))),
            tags$tbody(lapply(seq_len(nrow(rows)), function(k) tags$tr(class = if (rows$changed[k]) "table-warning",
              tags$td(wp5_vocab_label("tenet", rows$tenet[k], i18n)), tags$td(level_label(rows$current[k])),
              tags$td(if (is.na(rows$median[k])) "" else format(rows$median[k]), " (", rows$n_valid[k], ")"),
              tags$td(if (is.na(rows$proposed[k])) tr("too_few") else level_label(rows$proposed[k])))))),
          if (any(rows$changed)) tags$button(class = "btn btn-primary btn-sm", onclick = send("apply_measure", mid), tr("apply_button"))
          else tags$small(class = "text-muted", tr("matches_register")),
          if (!is.null(last)) tags$button(class = "btn btn-outline-secondary btn-sm ml-2", onclick = send("undo_measure", mid), tr("undo_button")))
      }))
    })
    # run an apply/undo body; real errors are logged + shown, silent req() conditions pass through
    guard_apply <- function(expr) {
      tryCatch(expr,
        shiny.silent.error = function(e) stop(e),
        error = function(e) {
          debug_log(paste("WP5 workshop: apply failed:", e$message), "ERROR")
          showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_workshop.context_apply"), type = "error")
        })
    }
    observeEvent(input$apply_measure, {
      ws <- current(); mid <- input$apply_measure; req(ws, !is.null(register), mid %in% ws$interventions)
      guard_apply({
        ch <- workshop_apply_change(ws, mid, measures(), tr("source_template"))
        if (is.null(ch)) {
          if (!mid %in% measures()$ID) showNotification(tr("measure_gone"), type = "warning")
          return()
        }
        if (!isTRUE(register$update(mid, ch$after))) { showNotification(tr("measure_gone"), type = "warning"); return() }
        # re-read the project AFTER the register write (modify_store starts from project_data_reactive())
        modify_store(function(st) workshop_set(st, workshop_record_apply(workshop_get(st, ws$id), mid, ch$before, ch$after)))
        showNotification(paste(tr("applied"), mid), type = "message")
      })
    })
    observeEvent(input$undo_measure, {
      ws <- current(); mid <- input$undo_measure; req(ws, !is.null(register), mid %in% ws$interventions)
      e <- workshop_last_apply(ws, mid); req(e)
      guard_apply({
        chk <- workshop_undo_check(e, measures())
        if (identical(chk, "gone")) { showNotification(tr("measure_gone"), type = "warning"); return() }
        if (identical(chk, "changed")) { showNotification(tr("undo_changed"), type = "warning"); return() }
        if (!isTRUE(register$update(mid, e$before))) { showNotification(tr("measure_gone"), type = "warning"); return() }
        modify_store(function(st) workshop_set(st, workshop_drop_last_apply(workshop_get(st, ws$id), mid)))
        showNotification(paste(tr("undone"), mid), type = "message")
      })
    })

    invisible(list(store = store))
  })
}
