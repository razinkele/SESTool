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
    rv <- reactiveValues(ia = NULL, step = 1L, editing = NULL)

    da <- reactive(wp5_da_for_project(project_data_reactive()))
    ref_status <- reactive(impact_reference_status(da()))
    available_steps <- function() 1:7

    # What the working copy was last built from / last written to. A plain
    # (non-reactive) environment: the seeding observer reads it under isolate()
    # and commit() updates it, so a commit never looks like a project change.
    loaded <- new.env(parent = emptyenv())
    loaded$project_id <- NULL
    loaded$block <- NULL

    # Build the working copy from the project; a fresh one starts from the DA's
    # published scenarios (nothing is written until the user acts).
    load_from_project <- function(pd, reset_step = TRUE) {
      stored <- get_impact_assessment(pd)
      ia <- stored
      if (is.null(ia)) {
        d <- wp5_da_for_project(pd)
        ia <- if (identical(impact_reference_status(d), "available")) impact_assessment_from_reference(d) else new_impact_assessment(d)
      }
      loaded$project_id <- pd$project_id
      loaded$block <- stored
      rv$ia <- ia
      if (reset_step) rv$step <- 1L
    }
    # No load path emits project_loaded, so the project itself is the signal:
    # reload when another project is opened (id), when the stored block differs
    # from what this module last committed (reload of the same file, external
    # change), or when nothing is stored and the DA changed. Only
    # project_data_reactive() is a dependency; everything else is isolated.
    observe({
      pd <- project_data_reactive()
      isolate({
        first <- is.null(rv$ia)
        id_changed <- !identical(pd$project_id, loaded$project_id)
        block <- get_impact_assessment(pd)
        block_changed <- !identical(block, loaded$block)
        da_changed <- !first && is.null(block) && !identical(wp5_da_for_project(pd), rv$ia$da)
        if (first || id_changed || block_changed || da_changed) load_from_project(pd, reset_step = first || id_changed)
      })
    })
    # Backup only: the observer above is the mechanism
    if (!is.null(event_bus)) observeEvent(event_bus$on_project_loaded(), load_from_project(project_data_reactive()), ignoreInit = TRUE)

    # Persist: the only write path. Never emits ISA/CLD events. loaded$block is
    # updated before the write so the re-triggered seeding observer finds the
    # block it committed and does nothing (project_id is deliberately untouched).
    commit <- function(ia) {
      pd <- set_impact_assessment(isolate(project_data_reactive()), ia)   # may raise impact_error
      loaded$block <- get_impact_assessment(pd)
      rv$ia <- ia
      project_data_reactive(pd)
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
    blocked_steps <- reactive({ req(rv$ia); Filter(function(s) !impact_can_advance(rv$ia, s), c(2L, 3L, 4L)) })
    output$step_bar <- renderUI({ req(rv$ia); impact_step_bar(rv$step, available_steps(), i18n, ns, blocked = blocked_steps()) })
    # Direct jumps are intentionally ungated (the step bar marks blocked steps); only Next is gated.
    lapply(1:7, function(n) observeEvent(input[[paste0("goto_step_", n)]], { rv$step <- n }))
    observeEvent(input$prev_step, { if (rv$step > 1L) rv$step <- rv$step - 1L })
    observeEvent(input$next_step, {
      if (rv$step >= max(available_steps())) return()
      if (!impact_can_advance(rv$ia, rv$step)) {
        msgs <- impact_problem_messages(impact_step_problems(rv$ia, rv$step), i18n)
        showNotification(tagList(strong(i18n$t("modules.impact_assessment.cannot_advance")), tags$ul(lapply(head(msgs, 3), tags$li))), type = "warning", duration = 8)
        return()
      }
      rv$step <- rv$step + 1L
    })

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
        ),
        arctic_panel()
      )
    }
    output$sc_table <- DT::renderDT({
      req(rv$ia)
      df <- impact_scenario_table_display(impact_scenario_table_df(rv$ia, i18n))
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

    # ---- Step 4: criterion x scenario matrix with a per-cell editor ----------
    step4_ui <- function() {
      problems <- impact_problem_messages(impact_step_problems(rv$ia, 4), i18n)
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.matrix_intro")),
        if (length(impact_scenario_codes(rv$ia)) == 0) div(class = "alert alert-warning py-2", i18n$t("modules.impact_assessment.problem.no_scenarios")),
        impact_matrix_table(rv$ia, i18n, ns),
        if (length(problems)) div(class = "alert alert-warning py-2", tags$ul(lapply(problems, tags$li)))
      )
    }
    # One observer per cell link, registered once. The registry is a plain
    # (non-reactive) environment: keeping it in reactiveValues would make this
    # observer read and write the same reactive and re-trigger itself forever.
    cell_obs <- new.env(parent = emptyenv())
    observe({
      req(rv$ia); codes <- impact_scenario_codes(rv$ia)
      for (cr in WP5_CRITERIA$code) for (cd in codes) local({
        id <- paste0("cell_", cr, "_", cd); cr_ <- cr; cd_ <- cd
        if (!exists(id, envir = cell_obs, inherits = FALSE)) {
          assign(id, observeEvent(input[[id]], {
            rv$editing <- c(criterion = cr_, scenario = cd_)
            show_cell_modal(cr_, cd_)
          }, ignoreInit = TRUE), envir = cell_obs)
        }
      })
    })
    rubric_select <- function(id, vocab, key, selected, multiple = FALSE) {
      choices <- stats::setNames(WP5_RUBRIC[[vocab]], wp5_vocab_label(vocab, WP5_RUBRIC[[vocab]], i18n))
      if (!multiple) choices <- c(stats::setNames("", i18n$t("modules.impact_assessment.not_set")), choices)
      selectizeInput(ns(id), i18n$t(key), choices = choices, selected = selected, multiple = multiple, width = "100%")
    }
    show_cell_modal <- function(cr, cd) {
      cl <- impact_get_cell(rv$ia, cr, cd)
      d <- da()
      is_ref_scenario <- identical(rv$ia$scenarios[[cd]]$source, "wp5_reference")
      ref <- if (nzchar(d) && is_ref_scenario) impact_reference_cell(d, cr, cd) else NULL
      subs <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
      ind <- impact_indicator_suggestions(cr, d)
      mech <- impact_mechanism_options(d, cd)
      mech_labels <- if (nrow(mech)) paste0(mech$name, ifelse(is.na(mech$applicability), "", paste0(" \u2014 ", mech$applicability))) else character(0)
      showModal(modalDialog(size = "l", easyClose = FALSE,
        title = paste0(wp5_vocab_label("criteria", cr, i18n), " \u00d7 ", cd, " \u2014 ", rv$ia$scenarios[[cd]]$name),
        impact_reference_panel(ref, is_ref_scenario, ns, i18n),
        fluidRow(
          column(6, rubric_select("cell_direction", "direction", "modules.impact_assessment.cell_direction", cl$direction),
                    rubric_select("cell_magnitude", "magnitude", "modules.impact_assessment.cell_magnitude", cl$magnitude),
                    rubric_select("cell_timing", "timing", "modules.impact_assessment.cell_timing", cl$timing)),
          column(6, rubric_select("cell_confidence", "confidence", "modules.impact_assessment.cell_confidence", cl$confidence),
                    rubric_select("cell_driver", "uncertainty_driver", "modules.impact_assessment.cell_driver", cl$uncertainty_driver),
                    rubric_select("cell_evidence", "evidence", "modules.impact_assessment.cell_evidence", cl$evidence, multiple = TRUE))
        ),
        textAreaInput(ns("cell_rationale"), i18n$t("modules.impact_assessment.cell_rationale"), value = cl$rationale, rows = 3, width = "100%"),
        if (length(subs)) tagList(h6(i18n$t("modules.impact_assessment.cell_subdimensions")),
          lapply(subs, function(s) textInput(ns(paste0("cell_sub_", s)), wp5_vocab_label("subdimension", s, i18n), value = cl$subdimension_notes[[s]] %||% ""))),
        selectizeInput(ns("cell_indicators"), i18n$t("modules.impact_assessment.cell_indicators"),
                       choices = if (nrow(ind)) stats::setNames(ind$code, paste0(ind$name, " (", ind$code, ", ", wp5_vocab_label("indicator_role", ind$role, i18n), ")")) else character(0),
                       selected = names(cl$indicator_roles), multiple = TRUE, width = "100%"),
        selectizeInput(ns("cell_mechanisms"), i18n$t("modules.impact_assessment.cell_mechanisms"),
                       choices = stats::setNames(mech$id, mech_labels), selected = cl$mechanism_ids, multiple = TRUE, width = "100%"),
        footer = tagList(actionButton(ns("cell_clear"), i18n$t("modules.impact_assessment.cell_clear"), class = "btn-outline-danger"),
                         modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("cell_save"), i18n$t("modules.impact_assessment.save_section"), class = "btn-success"))
      ))
    }
    cell_from_inputs <- function(cr, cd) {
      cl <- impact_get_cell(rv$ia, cr, cd)
      cl$direction <- input$cell_direction %||% ""; cl$magnitude <- input$cell_magnitude %||% ""
      cl$timing <- input$cell_timing %||% ""; cl$confidence <- input$cell_confidence %||% ""
      cl$uncertainty_driver <- input$cell_driver %||% ""; cl$evidence <- as.character(input$cell_evidence %||% character(0))
      cl$rationale <- input$cell_rationale %||% ""
      subs <- WP5_CRITERION_SUBDIMENSIONS[[cr]] %||% character(0)
      notes <- setNames(lapply(subs, function(s) input[[paste0("cell_sub_", s)]] %||% ""), subs)
      cl$subdimension_notes <- notes[vapply(notes, nzchar, logical(1))]
      ind <- as.character(input$cell_indicators %||% character(0))
      sugg <- impact_indicator_suggestions(cr, da())
      cl$indicator_roles <- setNames(as.list(ifelse(ind %in% sugg$code, sugg$role[match(ind, sugg$code)], "supporting")), ind)
      cl$mechanism_ids <- as.character(input$cell_mechanisms %||% character(0))
      cl
    }
    observeEvent(input$cell_save, {
      req(rv$editing); cr <- rv$editing[["criterion"]]; cd <- rv$editing[["scenario"]]
      try_commit(impact_set_cell(rv$ia, cr, cd, cell_from_inputs(cr, cd)))
      removeModal()
    })
    observeEvent(input$cell_clear, {
      req(rv$editing)
      try_commit(impact_set_cell(rv$ia, rv$editing[["criterion"]], rv$editing[["scenario"]], new_impact_cell()))
      removeModal()
    })
    observeEvent(input$cell_copy_reference, {
      req(rv$editing)
      tryCatch({
        commit(impact_copy_reference_cell(rv$ia, rv$editing[["criterion"]], rv$editing[["scenario"]]))
        removeModal(); show_cell_modal(rv$editing[["criterion"]], rv$editing[["scenario"]])
      }, error = notify_impact_error)
    })
    # ---- Steps 5-6: uncertainty and trade-offs ------------------------------
    step5_ui <- function() tagList(
      p(class = "text-muted", i18n$t("modules.impact_assessment.uncertainty_intro")),
      text_section_ui("uncertainty", IMPACT_TEXT_SECTIONS$uncertainty, "unc_", "save_uncertainty", rows = 6)
    )
    step6_ui <- function() {
      draft <- rv$ia$trade_offs$auto_draft %||% ""
      tagList(
        p(class = "text-muted", i18n$t("modules.impact_assessment.trade_offs_intro")),
        div(class = "mb-2",
          actionButton(ns("draft_trade_offs"), i18n$t("modules.impact_assessment.draft_button"), icon = icon("magic"), class = "btn-outline-primary btn-sm"),
          " ", provenance_badge("toolbox_extension", i18n),
          tags$small(class = "d-block text-muted", i18n$t("modules.impact_assessment.draft_hint"))),
        if (nzchar(draft))
          div(class = "alert alert-light border",
              strong(i18n$t("modules.impact_assessment.auto_draft_heading")), " ", provenance_badge("toolbox_extension", i18n),
              lapply(strsplit(draft, "

", fixed = TRUE)[[1]], p),
              actionButton(ns("use_draft"), i18n$t("modules.impact_assessment.draft_use"), class = "btn-link btn-sm p-0")),
        text_section_ui("trade_offs", "text", "to_", "save_trade_offs", rows = 6)
      )
    }
    # The draft is regenerated on demand and stored next to the author's text. The current
    # text-box content is COMMITTED in the same write (so "Draft" also acts as "Save" for the
    # text): the step body re-renders on rv$ia change, which would otherwise wipe unsaved typing.
    observeEvent(input$draft_trade_offs, {
      vals <- list(text = input$to_text %||% rv$ia$trade_offs$text %||% "", auto_draft = impact_narrative_draft(rv$ia, i18n))
      if (isTRUE(try_commit(impact_set_section(rv$ia, "trade_offs", vals)))) {
        showNotification(i18n$t("modules.impact_assessment.draft_created"), type = "message", duration = 3)
      }
    })
    observeEvent(input$use_draft, {
      updateTextAreaInput(session, "to_text", value = rv$ia$trade_offs$auto_draft %||% "")
    })
    observeEvent(input$save_uncertainty, save_section("uncertainty", IMPACT_TEXT_SECTIONS$uncertainty, "unc_"))
    observeEvent(input$save_trade_offs, {
      vals <- list(text = input$to_text %||% "", auto_draft = rv$ia$trade_offs$auto_draft %||% "")
      if (isTRUE(try_commit(impact_set_section(rv$ia, "trade_offs", vals)))) {
        showNotification(i18n$t("modules.impact_assessment.saved"), type = "message", duration = 3)
      }
    })

    # ---- Arctic read-only reference panel (step 2); NULL for other DAs ------
    arctic_panel <- function() {
      rev <- impact_reference_revenue(da()); if (is.null(rev)) return(NULL)
      feas <- impact_feasibility_rows(da(), i18n)
      tagList(hr(), h5(i18n$t("modules.impact_assessment.arctic_revenue_heading"), " ", provenance_badge(rev$provenance, i18n)),
        div(class = "alert alert-warning py-2", icon("exclamation-triangle"), " ", i18n$t("modules.impact_assessment.arctic_revenue_note"),
            tags$small(class = "d-block text-muted", rev$data_quality_note)),
        DT::DTOutput(ns("arctic_revenue")),
        if (nrow(feas)) tagList(h6(i18n$t("modules.impact_assessment.arctic_feasibility_heading")),
          tags$table(class = "table table-sm", tags$tbody(lapply(seq_len(nrow(feas)), function(i)
            tags$tr(tags$td(impact_scenario_display_name(rv$ia, da(), feas$scenario[i])),
                    tags$td(tags$b(feas$rating_text[i]), " ", feas$text[i])))))))
    }
    # Codes stay in the data; the table shows translated labels (spec P2)
    output$arctic_revenue <- DT::renderDT({
      tbl <- impact_revenue_display(impact_reference_revenue(da()), da(), i18n)
      DT::datatable(tbl$data, colnames = tbl$colnames, options = list(pageLength = 10, dom = "t"), rownames = FALSE)
    })

    output$step_body <- renderUI({
      req(rv$ia)
      if (identical(ref_status(), "valuation_only")) {
        return(tagList(
          ses_empty_state("modules.impact_assessment.tuscan_empty", "modules.impact_assessment.tuscan_empty_hint",
                          icon_name = "euro-sign", status = "info", i18n = i18n),
          div(class = "text-center", actionButton(ns("go_valuation"), i18n$t("modules.impact_assessment.go_valuation"),
                                                 class = "btn-outline-primary"))
        ))
      }
      switch(as.character(rv$step), "1" = step1_ui(), "2" = step2_ui(), "3" = step3_ui(), "4" = step4_ui(), "5" = step5_ui(), "6" = step6_ui(), "7" = step7_ui(), div(i18n$t("modules.impact_assessment.step_not_available")))
    })

    # Navigation to the valuation calculator (Tuscan empty state)
    observeEvent(input$go_valuation, {
      if (!is.null(event_bus) && is.function(event_bus$emit_navigation_request)) event_bus$emit_navigation_request("response_valuation", source = "impact_assessment")
    })

    create_help_observer(input, "help_impact", "modules.impact_assessment.help_title",
                         tagList(p(i18n$t("modules.impact_assessment.help_body"))), i18n)
    reactive(rv$ia)
  })
}
