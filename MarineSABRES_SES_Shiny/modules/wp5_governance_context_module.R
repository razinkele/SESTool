# modules/wp5_governance_context_module.R
# =============================================================================
# WP5 WS-9a (spec 2026-10-17 §5): D5.4 governance context of a demonstration
# area — barrier/enabler cards (Tables 5-7) and recommendation cards with
# "Add to register". Mounted as a tab of the Response module, which passes a
# register API so the register stays the single writer of its measures.
# Depends on: functions/wp5_governance.R, functions/stakeholder_schema.R
# =============================================================================

# i18n-ref: modules.wp5_vocabulary.npg.knowledge
# i18n-ref: modules.wp5_vocabulary.npg.collaboration
# i18n-ref: modules.wp5_vocabulary.npg.values_conflict
# i18n-ref: modules.wp5_vocabulary.npg.legitimacy_equity
# i18n-ref: modules.wp5_vocabulary.npg.cross_sectoral
# i18n-ref: modules.wp5_governance.polarity.enabler
# i18n-ref: modules.wp5_governance.polarity.barrier
# i18n-ref: modules.wp5_governance.sub_area_greenland
# i18n-ref: modules.wp5_governance.sub_area_iceland
# i18n-ref: modules.wp5_governance.sub_area_faroe_islands
# i18n-ref: modules.wp5_governance.sub_area_azores
# i18n-ref: modules.wp5_governance.sub_area_madeira
# i18n-ref: modules.wp5_governance.sub_area_canaries
# i18n-ref: modules.wp5_governance.context_title
# i18n-ref: modules.wp5_governance.context_note
# i18n-ref: modules.wp5_governance.filter_da
# i18n-ref: modules.wp5_governance.project_da
# i18n-ref: modules.wp5_governance.filter_dimension
# i18n-ref: modules.wp5_governance.filter_polarity
# i18n-ref: modules.wp5_governance.filter_sub_area
# i18n-ref: modules.wp5_governance.all
# i18n-ref: modules.wp5_governance.both
# i18n-ref: modules.wp5_governance.all_sub_areas
# i18n-ref: modules.wp5_governance.unavailable
# i18n-ref: modules.wp5_governance.english_source
# i18n-ref: modules.wp5_governance.no_da_hint
# i18n-ref: modules.wp5_governance.cards_title
# i18n-ref: modules.wp5_governance.no_cards
# i18n-ref: modules.wp5_governance.recommendations_title
# i18n-ref: modules.wp5_governance.no_recommendations
# i18n-ref: modules.wp5_governance.ebm_code
# i18n-ref: modules.wp5_governance.governance_level
# i18n-ref: modules.wp5_governance.add_to_register
# i18n-ref: modules.wp5_governance.already_in_register
# i18n-ref: modules.wp5_governance.added_to_register
# i18n-ref: modules.wp5_governance.context_add

wp5_governance_context_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_governance.", k))
  profiles <- load_wp5_governance_profiles()
  sites <- if (is.null(profiles)) character(0) else unname(vapply(profiles$das, `[[`, "", "da_site"))
  tagList(
    h4(tr("context_title")),
    tags$small(class = "text-muted", tr("context_note")),
    hr(),
    fluidRow(
      column(3, selectInput(ns("da"), tr("filter_da"),
                            choices = c(stats::setNames("", tr("project_da")), stats::setNames(sites, sites)))),
      column(3, selectInput(ns("dimension"), tr("filter_dimension"),
                            choices = c(stats::setNames("", tr("all")), stats::setNames(WP5_GOV_DIMENSIONS,
                              wp5_vocab_label("npg", WP5_GOV_DIMENSIONS, i18n))))),
      column(3, selectInput(ns("polarity"), tr("filter_polarity"),
                            choices = c(stats::setNames("", tr("both")), stats::setNames(WP5_GOV_POLARITIES,
                              vapply(WP5_GOV_POLARITIES, function(p) tr(paste0("polarity.", p)), character(1)))))),
      column(3, uiOutput(ns("sub_area_ui")))
    ),
    uiOutput(ns("body"))
  )
}

wp5_governance_context_server <- function(id, project_data_reactive, i18n, event_bus = NULL, register = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_governance.", k))
    profiles <- load_wp5_governance_profiles()
    src_badge <- function() span(class = "badge badge-light ml-1", tr("english_source"))

    project_site <- reactive(tryCatch(project_data_reactive()$data$metadata$da_site %||% "",
                                      error = function(e) ""))
    da <- reactive({
      v <- input$da %||% ""
      if (nzchar(v)) v else project_site()
    })
    profile <- reactive(wp5_gov_profile_for_site(profiles, da()))

    output$sub_area_ui <- renderUI({
      subs <- unlist(profile()$sub_areas)
      if (!length(subs)) return(NULL)
      selectInput(ns("sub_area"), tr("filter_sub_area"),
                  choices = c(stats::setNames("", tr("all_sub_areas")),
                              stats::setNames(subs, vapply(subs, function(s) tr(paste0("sub_area_", s)), character(1)))))
    })

    card_ui <- function(cd) {
      div(class = "border rounded p-2 mb-2",
        span(class = paste("badge", if (identical(cd$polarity, "enabler")) "badge-success" else "badge-danger"),
             tr(paste0("polarity.", cd$polarity))),
        if (!is.null(cd$sub_area)) span(class = "badge badge-info ml-1", tr(paste0("sub_area_", cd$sub_area))),
        p(class = "small mb-1 mt-1", cd$text, src_badge()),
        tags$small(class = "text-muted", cd$source_ref))
    }

    output$body <- renderUI({
      if (is.null(profiles)) return(div(class = "alert alert-warning", tr("unavailable")))
      prof <- profile()
      if (is.null(prof)) return(div(class = "alert alert-light", tr("no_da_hint")))
      cards <- wp5_gov_filter_cards(prof, input$dimension %||% "", input$polarity %||% "", input$sub_area %||% "")
      dims <- intersect(WP5_GOV_DIMENSIONS, vapply(cards, `[[`, "", "dimension"))
      tagList(
        h5(tr("cards_title")),
        if (!length(cards)) p(class = "text-muted", tr("no_cards")),
        lapply(dims, function(d) tagList(
          h6(class = "mt-3", wp5_vocab_label("npg", d, i18n)),
          lapply(Filter(function(cd) identical(cd$dimension, d), cards), card_ui))),
        h5(class = "mt-4", tr("recommendations_title")),
        uiOutput(ns("recommendations")))
    })

    # i18n-ref: modules.response.governance.level.local
    # i18n-ref: modules.response.governance.level.island
    # i18n-ref: modules.response.governance.level.regional
    # i18n-ref: modules.response.governance.level.national
    # i18n-ref: modules.response.governance.level.eu
    # i18n-ref: modules.response.governance.level.regional_sea
    # i18n-ref: modules.response.governance.level.international
    output$recommendations <- renderUI({
      prof <- profile(); req(prof)
      recs <- prof$recommendations %||% list()
      if (!length(recs)) return(p(class = "text-muted", tr("no_recommendations")))
      reg <- if (is.null(register)) NULL else register$measures()
      lapply(recs, function(r) {
        div(class = "border rounded p-2 mb-2",
          strong(r$title), src_badge(),
          p(class = "small mb-1", r$text),
          tags$small(class = "text-muted d-block",
            tr("ebm_code"), ": ", r$ebm_code, " ", wp5_vocab_label("instrument", r$ebm_code, i18n), " · ",
            tr("governance_level"), ": ", i18n$t(paste0("modules.response.governance.level.", r$governance_level)),
            " · ", r$source_ref),
          if (is.null(register)) NULL
          else if (wp5_gov_in_register(reg, r$title)) span(class = "badge badge-secondary mt-1", tr("already_in_register"))
          else tags$button(type = "button", class = "btn btn-sm btn-outline-success mt-1",
                           onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("add_rec"), r$id),
                           icon("plus"), tr("add_to_register")))
      })
    })

    observeEvent(input$add_rec, {
      req(!is.null(register))
      prof <- profile(); req(prof)
      rec <- Find(function(r) identical(r$id, input$add_rec), prof$recommendations)
      req(rec)
      if (wp5_gov_in_register(register$measures(), rec$title)) return()
      sh <- tryCatch(project_data_reactive()$data$pims$stakeholders, error = function(e) NULL)
      tryCatch({
        new_id <- register$add(wp5_gov_recommendation_measure(rec, sh))
        showNotification(paste(tr("added_to_register"), new_id), type = "message")
      }, error = function(e) {
        debug_log(paste("WP5 governance: add to register failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_governance.context_add"),
                         type = "error")
      })
    })

    invisible(list(profile = profile))
  })
}
