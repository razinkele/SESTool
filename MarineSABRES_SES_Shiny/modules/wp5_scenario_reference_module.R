# modules/wp5_scenario_reference_module.R
# =============================================================================
# WP5 WS-8 (spec 2026-10-16 §4): D5.1 scenario x worldview reference tab,
# shown inside the Scenario Builder page and not behind its CLD check.
# Depends on: functions/wp5_scenarios.R, functions/response_measures_schema.R
# =============================================================================

wp5_scenario_reference_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    h4(class = "mt-3", i18n$t("modules.wp5_scenarios.title")),
    uiOutput(ns("body"))
  )
}

wp5_scenario_reference_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    scen <- load_wp5_scenarios()
    mat <- load_wp5_worldview_matrix()
    ok <- !is.null(scen) && !is.null(mat)

    # i18n-ref: modules.wp5_scenarios.worldview.egalitarian
    # i18n-ref: modules.wp5_scenarios.worldview.individualist
    # i18n-ref: modules.wp5_scenarios.worldview.hierarchy
    # i18n-ref: modules.wp5_scenarios.pestle.political
    # i18n-ref: modules.wp5_scenarios.pestle.economic
    # i18n-ref: modules.wp5_scenarios.pestle.social
    # i18n-ref: modules.wp5_scenarios.pestle.technological
    # i18n-ref: modules.wp5_scenarios.pestle.legal
    # i18n-ref: modules.wp5_scenarios.pestle.environmental
    # i18n-ref: modules.wp5_scenarios.state.area
    # i18n-ref: modules.wp5_scenarios.state.europe
    # i18n-ref: modules.wp5_scenarios.state.none
    # i18n-ref: modules.wp5_scenarios.conducive.yes
    # i18n-ref: modules.wp5_scenarios.conducive.somewhat
    # i18n-ref: modules.wp5_scenarios.conducive.no
    # i18n-ref: modules.wp5_scenarios.slice.general
    # i18n-ref: modules.wp5_scenarios.slice.hrmc
    # i18n-ref: modules.wp5_scenarios.slice.sh
    # i18n-ref: modules.wp5_scenarios.slice.lh
    # i18n-ref: modules.wp5_scenarios.focus.tuscany
    # i18n-ref: modules.wp5_scenarios.focus.arctic
    # i18n-ref: modules.wp5_scenarios.focus.macaronesia
    # i18n-ref: modules.wp5_scenarios.gap.ssp_not_in_futuremares
    # i18n-ref: modules.wp5_scenarios.gap.no_afmec_lines
    # i18n-ref: modules.wp5_scenarios.gap.no_source_text
    # i18n-ref: modules.wp5_scenarios.strategy.behavioural
    # i18n-ref: modules.wp5_scenarios.strategy.accepted_instruments
    # i18n-ref: modules.wp5_scenarios.strategy.limits_of_acceptable_change
    # i18n-ref: modules.wp5_scenarios.source_note.summary_hierarchy_ssp
    # i18n-ref: modules.wp5_scenarios.source_note.hierarchy_ssp2_misprint
    # i18n-ref: modules.wp5_scenarios.source_note.conducive_row_label
    # i18n-ref: modules.wp5_scenarios.source_note.ssp3_hierarchy_cells
    # i18n-ref: modules.wp5_scenarios.source_note.generic_europe
    # i18n-ref: modules.wp5_scenarios.unavailable
    # i18n-ref: modules.wp5_scenarios.scope_note
    # i18n-ref: modules.wp5_scenarios.english_source
    # i18n-ref: modules.wp5_scenarios.warming
    # i18n-ref: modules.wp5_scenarios.conducive
    # i18n-ref: modules.wp5_scenarios.heatmap_title
    # i18n-ref: modules.wp5_scenarios.heatmap_help
    # i18n-ref: modules.wp5_scenarios.area_count
    # i18n-ref: modules.wp5_scenarios.europe_count
    # i18n-ref: modules.wp5_scenarios.pattern
    # i18n-ref: modules.wp5_scenarios.col_match
    # i18n-ref: modules.wp5_scenarios.match.yes
    # i18n-ref: modules.wp5_scenarios.match.no
    # i18n-ref: modules.wp5_scenarios.more_conducive
    # i18n-ref: modules.wp5_scenarios.col_rationale
    # i18n-ref: modules.wp5_scenarios.col_worldview_view
    # i18n-ref: modules.wp5_scenarios.col_scenario
    # i18n-ref: modules.wp5_scenarios.guiding_question
    # i18n-ref: modules.wp5_scenarios.strategies_title
    # i18n-ref: modules.wp5_scenarios.strategies_provenance
    # i18n-ref: modules.wp5_scenarios.source_notes_title
    # i18n-ref: modules.wp5_scenarios.responses_title
    # i18n-ref: modules.wp5_scenarios.responses_none
    # i18n-ref: modules.wp5_scenarios.responses_hint
    # i18n-ref: modules.wp5_scenarios.responses_not_area
    # i18n-ref: modules.wp5_scenarios.responses_no_project
    # i18n-ref: modules.wp5_scenarios.col_response
    # i18n-ref: modules.wp5_scenarios.col_tags
    # i18n-ref: modules.wp5_scenarios.col_kind
    # i18n-ref: modules.wp5_scenarios.col_ebm_code
    tr <- function(k) i18n$t(paste0("modules.wp5_scenarios.", k))
    src_badge <- function() span(class = "badge badge-light ml-1", tr("english_source"))
    ssp_label <- function(sid) {
      s <- Find(function(x) identical(x$id, sid), scen$scenarios)
      paste0(s$ssp, "-RCP", s$rcp)
    }

    # Default: the first worldview x scenario with any area-level element
    default_cell <- if (ok) {
      h <- wp5_heatmap_summary(mat)
      r <- h[h$n_area > 0, , drop = FALSE][1, ]
      list(worldview = r$worldview, ssp = r$ssp)
    } else NULL
    selected <- reactive({
      v <- input$cell
      if (is.null(v) || !nzchar(v)) return(default_cell)
      p <- strsplit(v, "|", fixed = TRUE)[[1]]
      list(worldview = p[1], ssp = p[2])
    })

    output$body <- renderUI({
      if (!ok) return(div(class = "alert alert-warning", tr("unavailable")))
      tagList(
        div(class = "alert alert-info small", tr("scope_note")),
        fluidRow(lapply(scen$scenarios, function(s) column(3, bs4Card(
          title = paste0(s$ssp, "-RCP", s$rcp), width = 12, collapsible = FALSE,
          p(strong(s$name), src_badge()),
          p(class = "small", tr("warming"), ": ", sub("^<=", "≤", s$warming_cap), " °C"),
          p(class = "small", tr("conducive"), ": ",
            span(class = paste("badge", switch(s$ebm_conducive, yes = "badge-success", somewhat = "badge-warning",
                                               "badge-danger")), tr(paste0("conducive.", s$ebm_conducive)))),
          p(class = "small", s$global_summary, src_badge()))))),
        h5(tr("heatmap_title")), p(class = "small text-muted", tr("heatmap_help")),
        uiOutput(ns("heatmap")),
        uiOutput(ns("drilldown")),
        uiOutput(ns("responses")),
        h5(class = "mt-3", tr("strategies_title")),
        p(class = "small text-muted", tr("strategies_provenance"), provenance_badge("toolbox_extension", i18n)),
        tags$ul(lapply(unlist(mat$strategies), function(s) tags$li(tr(paste0("strategy.", s))))),
        tags$details(class = "mt-3", tags$summary(strong(tr("source_notes_title"))),
          tags$ul(class = "small", lapply(mat$source_notes, function(n) tags$li(i18n$t(n$text_key)))))
      )
    })

    output$heatmap <- renderUI({
      req(ok)
      h <- wp5_heatmap_summary(mat)
      sel <- selected()
      col_for <- function(n) c("#f8f9fa", "#cfe2ff", "#9ec5fe", "#6ea8fe", "#3d8bfd", "#0d6efd", "#0a58ca")[n + 1]
      tags$table(class = "table table-sm table-bordered text-center",
        tags$thead(tags$tr(tags$th(""), lapply(WP5_SSPS, function(s) tags$th(ssp_label(s))))),
        tags$tbody(lapply(WP5_WORLDVIEWS, function(wv) tags$tr(
          tags$th(tr(paste0("worldview.", wv))),
          lapply(WP5_SSPS, function(s) {
            r <- h[h$worldview == wv & h$ssp == s, ]
            is_sel <- identical(sel$worldview, wv) && identical(sel$ssp, s)
            tags$td(style = sprintf("cursor:pointer;background:%s;%s", col_for(r$n_area),
                                    if (is_sel) "outline:3px solid #212529;" else ""),
                    onclick = sprintf("Shiny.setInputValue('%s', '%s|%s', {priority: 'event'})", ns("cell"), wv, s),
                    div(strong(r$n_area), " ", tr("area_count")),
                    if (r$n_europe > 0) div(class = "small", "+", r$n_europe, " ", tr("europe_count")),
                    div(class = "small text-monospace", title = tr("pattern"), r$pattern))
          }))))
      )
    })

    narrative_ui <- function(scell) {
      tabs <- lapply(unlist(scen$slices), function(sl) {
        v <- scell[[sl]]
        if (identical(sl, "general") && is.null(v$text)) return(NULL)   # no general text: hide the tab (ruling 2)
        focus <- scen$slice_da_focus[[sl]]
        tabPanel(paste0(tr(paste0("slice.", sl)), if (!is.null(focus)) paste0(" (", tr(paste0("focus.", focus)), ")")),
                 if (is.null(v$text)) p(class = "small text-muted", tr(paste0("gap.", v$gap_note)))
                 else p(class = "small", style = "white-space: pre-line;", v$text))
      })
      do.call(tabsetPanel, Filter(Negate(is.null), tabs))
    }

    output$drilldown <- renderUI({
      req(ok)
      sel <- selected(); req(sel)
      wv <- Find(function(x) identical(x$id, sel$worldview), mat$worldviews)
      s <- Find(function(x) identical(x$id, sel$ssp), scen$scenarios)
      rows <- wp5_cell_rows(mat, sel$worldview, sel$ssp)
      # paste, not sprintf: a translation stub that returns the key would make sprintf warn
      bs4Card(title = paste(tr(paste0("worldview.", sel$worldview)), "×", ssp_label(sel$ssp)),
              width = 12, collapsible = FALSE,
        lapply(rows, function(c) {
          div(class = "border-bottom pb-2 mb-2",
            h6(tr(paste0("pestle.", c$pestle)), " — ",
               span(class = paste("badge", switch(c$transformation, area = "badge-primary", europe = "badge-secondary",
                                                  "badge-light")), tr(paste0("state.", c$transformation)))),
            p(class = "small", strong(tr("col_match")), ": ",
              tr(if (isTRUE(c$match)) "match.yes" else "match.no"),
              if (isTRUE(c$wv_more_conducive)) paste0(" (", tr("more_conducive"), ")")),
            p(class = "small", strong(tr("col_rationale")), ": ", c$rationale, src_badge()),
            fluidRow(
              column(5, p(class = "small", strong(tr("col_worldview_view")), src_badge()),
                     p(class = "small", style = "white-space: pre-line;", wv$pestle[[c$pestle]])),
              column(7, p(class = "small", strong(tr("col_scenario")), src_badge(), br(),
                          em(tr("guiding_question"), ": ", scen$pestle_questions[[c$pestle]])),
                     narrative_ui(s$cells[[c$pestle]]))))
        }))
    })

    output$responses <- renderUI({
      req(ok)
      sel <- selected(); req(sel)
      pd <- project_data_reactive()
      if (is.null(pd)) return(div(class = "alert alert-light small", tr("responses_no_project")))
      elements <- wp5_area_elements(mat, sel$worldview, sel$ssp)
      if (!length(elements)) return(div(class = "alert alert-light small", tr("responses_not_area")))
      reg <- pd$data$response_measures$measures
      hit <- wp5_matched_responses(if (is.data.frame(reg)) reg else NULL, elements)
      if (!nrow(hit)) return(div(class = "alert alert-light small", tr("responses_none"), br(), tr("responses_hint")))
      bs4Card(title = tr("responses_title"), width = 12, collapsible = FALSE,
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(tr("col_response")), tags$th(tr("col_tags")),
                             tags$th(tr("col_kind")), tags$th(tr("col_ebm_code")))),
          tags$tbody(lapply(seq_len(nrow(hit)), function(i) {
            tags_i <- strsplit(hit$PestleTag[i], ";", fixed = TRUE)[[1]]
            tags$tr(tags$td(hit$Name[i]),
                    tags$td(lapply(tags_i, function(t) span(
                      class = paste("badge mr-1", if (t %in% hit$matched[[i]]) "badge-primary" else "badge-light"),
                      tr(paste0("pestle.", t))))),
                    tags$td(rm_display_label("kind", hit$Kind[i] %||% "", i18n)),
                    tags$td(rm_display_label("ebm_code", hit$EbmCode[i] %||% "", i18n)))
          }))))
    })

    list(selected = selected)
  })
}
