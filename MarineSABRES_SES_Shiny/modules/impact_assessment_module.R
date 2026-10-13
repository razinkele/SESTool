# modules/impact_assessment_module.R
# WP5 impact-assessment wizard (spec 2026-10-11 WS-6; D5.2 1.4 seven steps).
# All state changes go through the pure model in functions/impact_assessment_model.R
# and are persisted with set_impact_assessment(); rendering helpers live in
# functions/impact_assessment_view.R.

impact_assessment_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    fluidRow(column(12,
      create_module_header(ns, "modules.impact_assessment.title", "modules.impact_assessment.subtitle",
                           "help_impact", i18n),
      uiOutput(ns("da_banner")),
      uiOutput(ns("step_bar"))
    )),
    fluidRow(column(12, uiOutput(ns("step_body")))),
    fluidRow(column(12,
      div(class = "mt-3",
        actionButton(ns("prev_step"), i18n$t("modules.impact_assessment.prev"), icon = icon("arrow-left"), class = "btn-outline-secondary"),
        actionButton(ns("next_step"), i18n$t("modules.impact_assessment.next"), icon = icon("arrow-right"), class = "btn-primary ms-2")
      )
    ))
  )
}

impact_assessment_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(ia = NULL, step = 1L)

    da <- reactive(wp5_da_for_project(project_data_reactive()))
    ref_status <- reactive(impact_reference_status(da()))
    available_steps <- function() c(1L, 7L)   # grows: Task 5 adds 2; Task 6 adds 3; Part B adds 4-6

    # Build the working copy from the project; a fresh one starts from the DA's
    # published scenarios (nothing is written until the user acts).
    load_from_project <- function() {
      pd <- project_data_reactive()
      ia <- get_impact_assessment(pd)
      if (is.null(ia)) {
        d <- wp5_da_for_project(pd)
        ia <- if (identical(impact_reference_status(d), "available")) impact_assessment_from_reference(d) else new_impact_assessment(d)
      }
      rv$ia <- ia
      rv$step <- 1L
    }
    observe({ project_data_reactive(); isolate(if (is.null(rv$ia)) load_from_project()) })
    if (!is.null(event_bus)) observeEvent(event_bus$on_project_loaded(), load_from_project(), ignoreInit = TRUE)

    # Persist: the only write path. Never emits ISA/CLD events.
    commit <- function(ia) {
      rv$ia <- ia
      project_data_reactive(set_impact_assessment(project_data_reactive(), ia))
    }
    # Translate a model error (class impact_error, $code) into a notification
    notify_impact_error <- function(e) {
      code <- if (inherits(e, "impact_error")) e$code else "unknown"
      # i18n-ref: modules.impact_assessment.error.unknown
      # i18n-ref: modules.impact_assessment.error.cell_not_empty
      # i18n-ref: modules.impact_assessment.error.duplicate_scenario_code
      # i18n-ref: modules.impact_assessment.error.invalid_displacement_answer
      # i18n-ref: modules.impact_assessment.error.invalid_scenario_code
      # i18n-ref: modules.impact_assessment.error.invalid_scenario_source
      # i18n-ref: modules.impact_assessment.error.malformed_assessment
      # i18n-ref: modules.impact_assessment.error.no_da
      # i18n-ref: modules.impact_assessment.error.no_reference_cell
      # i18n-ref: modules.impact_assessment.error.scenario_not_reference
      # i18n-ref: modules.impact_assessment.error.too_many_scenarios
      # i18n-ref: modules.impact_assessment.error.unknown_criterion
      # i18n-ref: modules.impact_assessment.error.unknown_da
      # i18n-ref: modules.impact_assessment.error.unknown_field
      # i18n-ref: modules.impact_assessment.error.unknown_scenario
      # i18n-ref: modules.impact_assessment.error.unknown_section
      showNotification(i18n$t(paste0("modules.impact_assessment.error.", code)), type = "error", duration = 8)
    }
    try_commit <- function(expr) {
      tryCatch({ commit(expr); TRUE }, error = function(e) { notify_impact_error(e); FALSE })
    }

    output$da_banner <- renderUI(impact_da_banner(da(), ref_status(), i18n))
    output$step_bar <- renderUI({ req(rv$ia); impact_step_bar(rv$step, available_steps(), i18n, ns) })
    lapply(1:7, function(n) observeEvent(input[[paste0("goto_step_", n)]], { rv$step <- n }))
    observeEvent(input$prev_step, { if (rv$step > 1L) rv$step <- rv$step - 1L })
    observeEvent(input$next_step, { if (rv$step < max(available_steps())) rv$step <- rv$step + 1L })

    text_section_ui <- function(section, fields, prefix, save_id, rows = 3) {
      vals <- rv$ia[[section]]
      tagList(
        lapply(fields, function(f) {
          # i18n-ref: modules.impact_assessment.field.focal_issue
          # i18n-ref: modules.impact_assessment.field.spatial_scope
          # i18n-ref: modules.impact_assessment.field.time_horizon
          # i18n-ref: modules.impact_assessment.field.stakeholders
          # i18n-ref: modules.impact_assessment.field.text
          # i18n-ref: modules.impact_assessment.field.notes
          textAreaInput(ns(paste0(prefix, f)), i18n$t(paste0("modules.impact_assessment.field.", f)),
                        value = vals[[f]] %||% "", rows = rows, width = "100%")
        }),
        actionButton(ns(save_id), i18n$t("modules.impact_assessment.save_section"), icon = icon("save"), class = "btn-success")
      )
    }
    step1_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.characterisation_intro")),
      text_section_ui("characterisation", IMPACT_TEXT_SECTIONS$characterisation, "char_", "save_characterisation", rows = 2)
    )
    step7_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.recommendations_intro")),
      text_section_ui("recommendations", IMPACT_TEXT_SECTIONS$recommendations, "rec_", "save_recommendations", rows = 6)
    )
    save_section <- function(section, fields, prefix) {
      vals <- setNames(lapply(fields, function(f) input[[paste0(prefix, f)]] %||% ""), fields)
      if (isTRUE(try_commit(impact_set_section(rv$ia, section, vals)))) {
        showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
      }
    }
    observeEvent(input$save_characterisation, save_section("characterisation", IMPACT_TEXT_SECTIONS$characterisation, "char_"))
    observeEvent(input$save_recommendations, save_section("recommendations", IMPACT_TEXT_SECTIONS$recommendations, "rec_"))

    output$step_body <- renderUI({
      req(rv$ia)
      if (identical(ref_status(), "valuation_only")) {
        return(tagList(
          ses_empty_state("modules.impact_assessment.tuscan_empty", "modules.impact_assessment.tuscan_empty_hint",
                          icon_name = "euro-sign", status = "info", i18n = i18n),
          div(class = "text-center", actionButton(ns("go_valuation"), i18n$t("modules.impact_assessment.go_valuation"),
                                                 class = "btn-outline-primary",
                                                 onclick = "Shiny.setInputValue('impact_nav_target', 'response_valuation', {priority: 'event'})"))
        ))
      }
      switch(as.character(rv$step), "1" = step1_ui(), "7" = step7_ui(), div(i18n$t("modules.impact_assessment.step_not_available")))
    })

    # Navigation to the valuation calculator (Tuscan empty state)
    observeEvent(input$go_valuation, {
      if (!is.null(event_bus) && is.function(event_bus$emit_navigation_request)) event_bus$emit_navigation_request("response_valuation")
    })

    create_help_observer(input, "help_impact", "modules.impact_assessment.help_title",
                         tagList(p(i18n$t("modules.impact_assessment.help_body"))), i18n)
    reactive(rv$ia)
  })
}
