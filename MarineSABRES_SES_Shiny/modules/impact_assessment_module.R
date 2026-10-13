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
    available_steps <- function() c(1L, 2L, 3L, 7L)   # grows: Part B adds 4-6

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

    # sprintf only when the translated text carries a placeholder (the test stub returns the bare key)
    fmt_n <- function(key, n) { f <- i18n$t(key); if (grepl("%", f, fixed = TRUE)) sprintf(f, n) else f }

    step2_ui <- function() {
      df <- impact_scenario_table_df(rv$ia, i18n)
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 2), i18n)
      tagList(
        p(class = "text-muted", fmt_n("modules.impact_assessment.scenarios_intro", IMPACT_MAX_SCENARIOS)),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li))),
        fluidRow(
          column(7,
            DT::DTOutput(ns("sc_table")),
            div(class = "mt-2",
              actionButton(ns("sc_remove"), i18n$t("modules.impact_assessment.scenario_remove"), icon = icon("trash"), class = "btn-outline-danger btn-sm"),
              if (identical(ref_status(), "available"))
                actionButton(ns("sc_load_reference"), i18n$t("modules.impact_assessment.scenario_load_reference"), icon = icon("download"), class = "btn-outline-primary btn-sm ms-2")
            ),
            if (nrow(df) > 0) radioButtons(ns("sc_baseline"), i18n$t("modules.impact_assessment.baseline_label"),
                                           choices = stats::setNames(df$code, paste(df$code, df$name, sep = " — ")),
                                           selected = if (nzchar(rv$ia$baseline_code)) rv$ia$baseline_code else character(0))
          ),
          column(5, wellPanel(
            h5(i18n$t("modules.impact_assessment.scenario_add_heading")),
            textInput(ns("sc_code"), i18n$t("modules.impact_assessment.scenario_code"), placeholder = "S5"),
            textInput(ns("sc_name"), i18n$t("modules.impact_assessment.scenario_name")),
            textAreaInput(ns("sc_description"), i18n$t("modules.impact_assessment.scenario_description"), rows = 2),
            numericInput(ns("sc_ambition"), i18n$t("modules.impact_assessment.scenario_ambition"), value = 0, min = 0, max = 10, step = 1),
            tags$details(tags$summary(i18n$t("modules.impact_assessment.scenario_dimensions")),
              lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) {
                # i18n-ref: modules.impact_assessment.dimension.governance_form
                # i18n-ref: modules.impact_assessment.dimension.spatial_scope
                # i18n-ref: modules.impact_assessment.dimension.sectoral_activation
                # i18n-ref: modules.impact_assessment.dimension.monitoring_data
                # i18n-ref: modules.impact_assessment.dimension.compliance_credibility
                # i18n-ref: modules.impact_assessment.dimension.financing_capacity
                textInput(ns(paste0("sc_dim_", d)), i18n$t(paste0("modules.impact_assessment.dimension.", d)))
              })),
            actionButton(ns("sc_add"), i18n$t("modules.impact_assessment.scenario_add"), icon = icon("plus"), class = "btn-success")
          ))
        )
      )
    }
    output$sc_table <- DT::renderDT({
      req(rv$ia)
      df <- impact_scenario_table_df(rv$ia, i18n)
      names(df) <- c(i18n$t("modules.impact_assessment.scenario_code"), i18n$t("modules.impact_assessment.scenario_name"),
                     i18n$t("modules.impact_assessment.baseline_label"), i18n$t("modules.impact_assessment.scenario_ambition"),
                     i18n$t("modules.impact_assessment.scenario_source"))
      DT::datatable(df, selection = "single", options = list(pageLength = 6, dom = "t"), rownames = FALSE)
    })
    observeEvent(input$sc_add, {
      if (length(impact_scenario_codes(rv$ia)) >= IMPACT_MAX_SCENARIOS) {
        showNotification(fmt_n("modules.impact_assessment.error.too_many_scenarios", IMPACT_MAX_SCENARIOS), type = "warning")
        return()
      }
      code <- trimws(input$sc_code %||% "")
      if (code %in% impact_scenario_codes(rv$ia)) {
        showNotification(i18n$t("modules.impact_assessment.error.duplicate_scenario_code"), type = "warning")
        return()
      }
      dims <- setNames(lapply(IMPACT_SCENARIO_DIMENSIONS, function(d) input[[paste0("sc_dim_", d)]] %||% ""), IMPACT_SCENARIO_DIMENSIONS)
      dims <- dims[vapply(dims, nzchar, logical(1))]
      tryCatch({
        sc <- new_impact_scenario(code, input$sc_name %||% code, input$sc_description %||% "",
                                  as.integer(input$sc_ambition %||% 0L), "user", if (length(dims)) dims else NULL)
        commit(impact_add_scenario(rv$ia, sc))
        updateTextInput(session, "sc_code", value = ""); updateTextInput(session, "sc_name", value = "")
      }, error = notify_impact_error)
    })
    observeEvent(input$sc_remove, {
      sel <- input$sc_table_rows_selected
      req(length(sel) == 1)
      code <- impact_scenario_table_df(rv$ia, i18n)$code[sel]
      try_commit(impact_remove_scenario(rv$ia, code))
    })
    observeEvent(input$sc_baseline, {
      req(input$sc_baseline %in% impact_scenario_codes(rv$ia))
      if (!identical(input$sc_baseline, rv$ia$baseline_code)) try_commit(impact_set_baseline(rv$ia, input$sc_baseline))
    })
    observeEvent(input$sc_load_reference, {
      tryCatch({
        ref <- impact_assessment_from_reference(da())
        ia <- rv$ia
        for (cd in impact_scenario_codes(ref)) if (!cd %in% impact_scenario_codes(ia)) ia <- impact_add_scenario(ia, ref$scenarios[[cd]])
        if (!nzchar(ia$baseline_code) && nzchar(ref$baseline_code)) ia <- impact_set_baseline(ia, ref$baseline_code)
        commit(ia)
      }, error = notify_impact_error)
    })

    step3_ui <- function() {
      sc <- rv$ia$scope
      pd <- project_data_reactive()
      el <- impact_element_choices(pd)
      pressures <- el[grepl("\\[pressures\\]$", names(el))]
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 3), i18n)
      # i18n-ref: modules.impact_assessment.displacement.yes
      # i18n-ref: modules.impact_assessment.displacement.no
      # i18n-ref: modules.impact_assessment.displacement.unsure
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.scoping_intro")),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li))),
        if (length(el) == 0) div(class = "alert alert-secondary py-2", i18n$t("modules.impact_assessment.no_isa_elements")),
        selectizeInput(ns("scope_elements"), i18n$t("modules.impact_assessment.scope_elements"), choices = el,
                       selected = sc$element_ids, multiple = TRUE, width = "100%"),
        selectizeInput(ns("scope_indicators"), i18n$t("modules.impact_assessment.scope_indicators"),
                       choices = impact_indicator_choices(da(), i18n), selected = sc$indicator_codes, multiple = TRUE, width = "100%"),
        hr(),
        h5(i18n$t("modules.impact_assessment.displacement_heading")),
        p(class = "text-muted", i18n$t("modules.impact_assessment.displacement_question")),
        radioButtons(ns("scope_displacement"), NULL,
                     choices = stats::setNames(IMPACT_DISPLACEMENT_ANSWERS,
                                               vapply(IMPACT_DISPLACEMENT_ANSWERS, function(a) i18n$t(paste0("modules.impact_assessment.displacement.", a)), character(1))),
                     selected = if (nzchar(sc$displacement$answer %||% "")) sc$displacement$answer else "unsure", inline = TRUE),
        textAreaInput(ns("scope_displacement_note"), i18n$t("modules.impact_assessment.displacement_note"), value = sc$displacement$note %||% "", rows = 2, width = "100%"),
        selectizeInput(ns("scope_displaced_pressure"), i18n$t("modules.impact_assessment.displaced_pressure"),
                       choices = c(stats::setNames("", i18n$t("modules.impact_assessment.displaced_pressure_none")), pressures),
                       selected = sc$displacement$displaced_pressure_id %||% "", width = "100%"),
        tags$small(class = "text-muted", i18n$t("modules.impact_assessment.displaced_pressure_hint")),
        div(class = "mt-3", actionButton(ns("save_scope"), i18n$t("modules.impact_assessment.save_section"), icon = icon("save"), class = "btn-success"))
      )
    }
    observeEvent(input$save_scope, {
      tryCatch({
        ia <- impact_set_scope_items(rv$ia, element_ids = as.character(input$scope_elements %||% character(0)),
                                     indicator_codes = as.character(input$scope_indicators %||% character(0)))
        ia <- impact_set_displacement(ia, input$scope_displacement %||% "unsure", input$scope_displacement_note %||% "",
                                      input$scope_displaced_pressure %||% "")
        commit(ia)
        showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
      }, error = notify_impact_error)
    })

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
      switch(as.character(rv$step), "1" = step1_ui(), "2" = step2_ui(), "3" = step3_ui(), "7" = step7_ui(), div(i18n$t("modules.impact_assessment.step_not_available")))
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
