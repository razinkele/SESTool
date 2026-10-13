# tests/testthat/test-impact-assessment-module.R
library(testthat)
library(shiny)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"), force_reload = TRUE)
source_for_test(c("server/event_bus_setup.R", "functions/ui_components.R", "functions/impact_assessment_view.R",
                  "modules/impact_assessment_module.R"))
impact_assessment_server <- get("impact_assessment_server", envir = .GlobalEnv)
impact_assessment_ui <- get("impact_assessment_ui", envir = .GlobalEnv)

mk_project <- function(da = "Macaronesia") { p <- create_empty_project("ia"); p$data$metadata$da_site <- da; p }
srv <- function(p) list(project_data_reactive = shiny::reactiveVal(p), i18n = make_test_i18n(), event_bus = NULL)

test_that("UI returns namespaced tags with the step bar and body outputs", {
  ui <- as.character(impact_assessment_ui("ia", make_test_i18n()))
  for (id in c("ia-step_bar", "ia-step_body", "ia-da_banner")) expect_match(ui, id, fixed = TRUE)
  expect_match(ui, "modules.impact_assessment.title", fixed = TRUE)
})

test_that("server has the conventional signature", {
  expect_equal(names(formals(impact_assessment_server)), c("id", "project_data_reactive", "i18n", "event_bus"))
})

test_that("a Macaronesia project starts from the WP5 reference scenarios without writing the project until the user acts", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3", "S4"))
    expect_identical(rv$ia$baseline_code, "S1")
    expect_null(get_impact_assessment(args$project_data_reactive()))   # not stamped yet
    expect_match(as.character(output$da_banner$html), "modules.impact_assessment.da.macaronesia", fixed = TRUE)
  })
})

test_that("a Tuscan project shows the valuation-only empty state and no step body", {
  args <- srv(mk_project("Tuscan Archipelago")); bus <- create_event_bus("ia-tuscan"); args$event_bus <- bus
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.tuscan_empty", fixed = TRUE)
    expect_match(html, "-go_valuation\"", fixed = TRUE)
    expect_false(grepl("onclick", html, fixed = TRUE))
    session$setInputs(go_valuation = 1); session$flushReact()
    ev <- isolate(bus$get_last_event())
    expect_identical(ev$type, "navigation_request")
    expect_identical(ev$target, "response_valuation")
  })
})

test_that("a project without a DA gets an empty assessment and the no-DA note", {
  testServer(impact_assessment_server, args = srv(mk_project(NULL)), {
    session$flushReact()
    expect_identical(rv$ia$da, "")
    expect_length(impact_scenario_codes(rv$ia), 0L)
    expect_match(as.character(output$da_banner$html), "modules.impact_assessment.da.none", fixed = TRUE)
  })
})

test_that("an existing assessment in the project is loaded, and reloaded when another project is opened (no event bus)", {
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Corridor")))
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Corridor")
    p2 <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Other")))
    args$project_data_reactive(p2); session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Other")
  })
})

test_that("a project opened after session start is picked up; commits do not reload or reset the step", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(rv$ia$da, "")
    # 1. open a Macaronesia project (no load event is emitted by any load path)
    pa <- mk_project("Macaronesia"); pa$project_id <- "PROJ_A"
    args$project_data_reactive(pa); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3", "S4"))
    expect_identical(rv$ia$da, "macaronesia")
    # 2. saving writes the loaded project's assessment and keeps the step
    rv$step <- 2L
    session$setInputs(char_focal_issue = "x", char_spatial_scope = "", char_time_horizon = "", char_stakeholders = "",
                      save_characterisation = 1)
    session$flushReact()
    expect_identical(get_impact_assessment(args$project_data_reactive())$da, "macaronesia")
    expect_identical(rv$step, 2L)
    # 3. switching to another project that holds an assessment loads it and resets to step 1
    rv$step <- 4L
    pb <- set_impact_assessment(mk_project("Macaronesia"),
                                impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Other")))
    pb$project_id <- "PROJ_B"
    args$project_data_reactive(pb); session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Other")
    expect_identical(rv$step, 1L)
    # 4. a normal commit neither reloads nor moves the user
    rv$step <- 5L
    commit(impact_set_section(rv$ia, "recommendations", list(text = "ok")))
    rv$ia$in_memory_marker <- "kept"   # a reload would rebuild rv$ia from the project and drop this
    session$flushReact()
    expect_identical(rv$ia$in_memory_marker, "kept")
    expect_identical(rv$step, 5L)
    expect_identical(rv$ia$recommendations$text, "ok")
    expect_identical(rv$ia$characterisation$focal_issue, "Other")
  })
})

test_that("app.R and the sidebar wire the module under Response & Validation", {
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, 'bs4TabItem(tabName = "response_impact", impact_assessment_ui("impact_assess", i18n))', fixed = TRUE)
  expect_match(app, 'impact_assessment_server("impact_assess", project_data, session_i18n', fixed = TRUE)
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "response_impact"', fixed = TRUE)
  g <- paste(readLines(file.path(PROJECT_ROOT, "global.R"), warn = FALSE), collapse = "\n")
  expect_match(g, 'source("functions/impact_assessment_view.R", local = FALSE)', fixed = TRUE)
})

test_that("every modules.impact_assessment.* key used in the module exists in all 9 languages", {
  src <- paste(readLines(file.path(PROJECT_ROOT, "modules", "impact_assessment_module.R"), warn = FALSE),
               readLines(file.path(PROJECT_ROOT, "functions", "impact_assessment_view.R"), warn = FALSE), collapse = "\n")
  keys <- unique(regmatches(src, gregexpr("modules[.]impact_assessment[.][A-Za-z0-9_.]+", src))[[1]])
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  keys <- keys[!grepl("[.]$", keys)]   # dynamic-key prefixes (step., da., error.) are covered by their i18n-ref sentinels
  for (k in keys) {
    expect_true(k %in% names(tr), label = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), label = paste(k, l))
  }
})

test_that("step 1 saves the four characterisation fields into the project", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(char_focal_issue = "Migratory corridor", char_spatial_scope = "Azores EEZ",
                      char_time_horizon = "2030", char_stakeholders = "Fishers; NGOs")
    session$setInputs(save_characterisation = 1); session$flushReact()
    ch <- get_impact_assessment(args$project_data_reactive())$characterisation
    expect_identical(ch$focal_issue, "Migratory corridor")
    expect_identical(ch$stakeholders, "Fishers; NGOs")
    expect_identical(args$project_data_reactive()$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
  })
})

test_that("step 7 saves recommendations and prefills from the stored text", {
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "recommendations", list(text = "Pilot S3")))
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 7L; session$flushReact()
    expect_match(as.character(output$step_body$html), "Pilot S3", fixed = TRUE)
    session$setInputs(rec_text = "Pilot S3, then S4", save_recommendations = 1); session$flushReact()
    expect_identical(get_impact_assessment(args$project_data_reactive())$recommendations$text, "Pilot S3, then S4")
  })
})

test_that("try_commit returns FALSE on a model error and TRUE on success", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    bad <- try_commit(stop(structure(class = c("impact_error", "error", "condition"),
                                     list(message = "x", code = "unknown"))))
    expect_false(bad)
    expect_true(try_commit(impact_set_section(rv$ia, "recommendations", list(text = "ok"))))
    expect_identical(get_impact_assessment(args$project_data_reactive())$recommendations$text, "ok")
  })
})

test_that("step 2 adds, sets baseline, removes scenarios and enforces the maximum", {
  args <- srv(mk_project(NULL))   # no DA: starts empty
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.no_scenarios", fixed = TRUE)
    for (i in 1:5) { session$setInputs(sc_code = paste0("U", i), sc_name = paste("User", i), sc_description = "", sc_ambition = i, sc_add = i); session$flushReact() }
    expect_identical(impact_scenario_codes(rv$ia), paste0("U", 1:5))
    session$setInputs(sc_code = "U6", sc_name = "Six", sc_ambition = 6, sc_add = 6); session$flushReact()
    expect_length(impact_scenario_codes(rv$ia), 5L)                      # refused: IMPACT_MAX_SCENARIOS
    session$setInputs(sc_baseline = "U2"); session$flushReact()
    expect_identical(rv$ia$baseline_code, "U2")
    # renderDT is server-side, so the cells are not in the output payload: assert the
    # render runs with translated headers and goes through the display mapping
    # (impact_scenario_table_display, unit-tested in test-impact-assessment-view.R)
    expect_match(paste(as.character(output$sc_table), collapse = " "), "modules.impact_assessment.baseline_label", fixed = TRUE)
    mod_src <- paste(readLines(file.path(PROJECT_ROOT, "modules", "impact_assessment_module.R"), warn = FALSE), collapse = "\n")
    expect_match(mod_src, "impact_scenario_table_display(impact_scenario_table_df(rv$ia, i18n))", fixed = TRUE)
    session$setInputs(sc_table_rows_selected = 5L, sc_remove = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), paste0("U", 1:4))
    expect_identical(get_impact_assessment(args$project_data_reactive())$baseline_code, "U2")
  })
})

test_that("an invalid scenario code is reported, not fatal", {
  testServer(impact_assessment_server, args = srv(mk_project(NULL)), {
    session$flushReact(); rv$step <- 2L
    session$setInputs(sc_code = "S 1!", sc_name = "Bad", sc_ambition = 1, sc_add = 1); session$flushReact()
    expect_length(impact_scenario_codes(rv$ia), 0L)
  })
})

test_that("Load WP5 scenarios restores the published set for a DA with reference data", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L
    session$setInputs(sc_table_rows_selected = 4L, sc_remove = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3"))
    session$setInputs(sc_load_reference = 1); session$flushReact()
    expect_identical(impact_scenario_codes(rv$ia), c("S1", "S2", "S3", "S4"))
  })
})

test_that("step 3 saves scope elements, indicators and the displacement answer; a yes needs a note", {
  p <- mk_project("Macaronesia")
  p$data$isa_data$pressures <- data.frame(ID = c("P001", "P002"), Name = c("Extraction", "Noise"), stringsAsFactors = FALSE)
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 3L; session$flushReact()
    session$setInputs(scope_elements = "P001", scope_indicators = character(0), scope_displacement = "yes",
                      scope_displacement_note = "", scope_displaced_pressure = "P002", save_scope = 1)
    session$flushReact()
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.displacement_note_missing", fixed = TRUE)
    session$setInputs(scope_displacement_note = "Effort may move to ABNJ", save_scope = 2); session$flushReact()
    ia <- get_impact_assessment(args$project_data_reactive())
    expect_identical(ia$scope$element_ids, "P001")
    expect_identical(ia$scope$displacement$answer, "yes")
    expect_identical(ia$scope$displacement$displaced_pressure_id, "P002")
    expect_false(any(grepl("displacement_note_missing", as.character(output$step_body$html))))
  })
})

test_that("the cell modal saves a rating and the matrix reflects it; low confidence without a driver is listed as a problem", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 4L; session$flushReact()
    session$setInputs(cell_EE_S2 = 1); session$flushReact()
    expect_identical(rv$editing, c(criterion = "EE", scenario = "S2"))
    session$setInputs(cell_direction = "increase", cell_magnitude = "moderate", cell_timing = "medium", cell_confidence = "low",
                      cell_evidence = c("literature"), cell_driver = "", cell_rationale = "Corridor closure", cell_indicators = character(0),
                      cell_mechanisms = character(0), cell_save = 1)
    session$flushReact()
    cl <- impact_get_cell(get_impact_assessment(args$project_data_reactive()), "EE", "S2")
    expect_identical(cl$direction, "increase")
    expect_match(as.character(output$step_body$html), "ia-fill-2 ia-dir-increase ia-conf-low", fixed = TRUE)
    expect_match(as.character(output$step_body$html), "modules.impact_assessment.problem.driver_required", fixed = TRUE)
  })
})

test_that("copy-from-reference fills a reference scenario cell once and reports cell_not_empty the second time", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 4L
    session$setInputs(cell_EQ_S4 = 1); session$flushReact()
    session$setInputs(cell_copy_reference = 1); session$flushReact()
    cl <- impact_get_cell(rv$ia, "EQ", "S4")
    expect_true(nzchar(cl$rationale)); expect_identical(cl$reference$provenance, "wp5_source")
    session$setInputs(cell_copy_reference = 2); session$flushReact()   # must not crash; notification only
    expect_identical(impact_get_cell(rv$ia, "EQ", "S4")$rationale, cl$rationale)
  })
})

test_that("a user scenario reusing a reference code cannot receive reference text", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    rv$ia$da <- "macaronesia"
    commit(impact_add_scenario(rv$ia, new_impact_scenario("S1", "Mine")))
    rv$step <- 4L; session$setInputs(cell_EE_S1 = 1); session$flushReact()
    session$setInputs(cell_copy_reference = 1); session$flushReact()
    expect_identical(impact_get_cell(rv$ia, "EE", "S1"), new_impact_cell())
  })
})

test_that("an Arctic project shows the read-only revenue table and feasibility cells on step 2", {
  args <- srv(mk_project("Arctic Northeast Atlantic"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.arctic_revenue_note", fixed = TRUE)
    expect_match(html, "-arctic_revenue\"", fixed = TRUE)   # testServer namespaces as proxyN-
    expect_identical(impact_scenario_codes(rv$ia), c("no_agreement", "partial_agreement", "full_agreement"))
    # labels, not codes (spec P2): translated headers and reference scenario names in the revenue
    # table (cell values are server-side; impact_revenue_display is unit-tested), names in the feasibility rows
    rev <- paste(as.character(output$arctic_revenue), collapse = " ")
    expect_match(rev, "modules.impact_assessment.revenue.country", fixed = TRUE)
    expect_match(rev, htmltools::htmlEscape(impact_scenario_display_name(NULL, "arctic", "full_agreement")), fixed = TRUE)
    nm <- rv$ia$scenarios$no_agreement$name
    expect_match(html, paste0("<td>", htmltools::htmlEscape(nm), "</td>"), fixed = TRUE)
    if (!identical(nm, "no_agreement")) expect_false(grepl("<td>no_agreement</td>", html, fixed = TRUE))
  })
})

test_that("steps 5 and 6 persist their text", {
  args <- srv(mk_project("Macaronesia"))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 5L; session$flushReact()
    session$setInputs(unc_notes = "Compliance in ABNJ", save_uncertainty = 1); session$flushReact()
    rv$step <- 6L; session$flushReact()
    session$setInputs(to_text = "S4: equity vs cost", save_trade_offs = 1); session$flushReact()
    ia <- get_impact_assessment(args$project_data_reactive())
    expect_identical(ia$uncertainty$notes, "Compliance in ABNJ")
    expect_identical(ia$trade_offs$text, "S4: equity vs cost")
  })
})

test_that("next is blocked on step 2 without scenarios and on step 4 with a low-confidence cell lacking a driver", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact(); rv$step <- 2L; session$flushReact()
    session$setInputs(next_step = 1); session$flushReact()
    expect_identical(rv$step, 2L)
    commit(impact_set_baseline(impact_add_scenario(rv$ia, new_impact_scenario("U1", "One")), "U1"))
    session$setInputs(next_step = 2); session$flushReact()
    expect_identical(rv$step, 3L)
    session$setInputs(next_step = 3); session$flushReact()   # step 3 passes when displacement is not "yes"
    expect_identical(rv$step, 4L)
    cl <- new_impact_cell(); cl$direction <- "increase"; cl$confidence <- "low"
    commit(impact_set_cell(rv$ia, "EE", "U1", cl))
    session$setInputs(next_step = 4); session$flushReact()
    expect_identical(rv$step, 4L)
    cl$uncertainty_driver <- "data_gap"; commit(impact_set_cell(rv$ia, "EE", "U1", cl))
    session$setInputs(next_step = 5); session$flushReact()
    expect_identical(rv$step, 5L)
  })
})

# ---- WS-6c: step 6 draft -------------------------------------------------------
ia_with_matrix <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  up <- new_impact_cell(); up$direction <- "increase"; up$magnitude <- "moderate"; up$confidence <- "high"
  dn <- new_impact_cell(); dn$direction <- "decrease"; dn$magnitude <- "incremental"; dn$confidence <- "medium"
  ia <- impact_set_cell(ia, "EE", "S2", up)
  impact_set_cell(ia, "FF", "S2", dn)
}

test_that("step 6 drafts the narrative from the matrix, stores it, shows it with the toolbox badge, and can copy it into the text box", {
  p <- set_impact_assessment(mk_project("Macaronesia"), ia_with_matrix())
  args <- srv(p)
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(goto_step_6 = 1); session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "-draft_trade_offs\"", fixed = TRUE)
    expect_false(grepl("-use_draft\"", html, fixed = TRUE))              # no draft yet
    expect_identical(rv$ia$trade_offs$auto_draft, "")
    session$setInputs(to_text = "My own notes", draft_trade_offs = 1); session$flushReact()
    draft <- rv$ia$trade_offs$auto_draft
    expect_match(draft, "modules.impact_assessment.narrative.trade_off", fixed = TRUE)
    expect_identical(rv$ia$trade_offs$text, "My own notes")              # unsaved text box content is kept
    expect_identical(get_impact_assessment(args$project_data_reactive())$trade_offs$auto_draft, draft)
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.auto_draft_heading", fixed = TRUE)
    expect_match(html, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
    expect_match(html, "-use_draft\"", fixed = TRUE)
    session$setInputs(use_draft = 1); session$flushReact()                 # updateTextAreaInput is a no-op in tests;
    expect_identical(rv$ia$trade_offs$auto_draft, draft)                  # the button must not alter stored state
  })
})

test_that("drafting on an assessment without scenarios stores the 'empty' sentence and does not error", {
  args <- srv(mk_project(NULL))
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    session$setInputs(goto_step_6 = 1, draft_trade_offs = 1); session$flushReact()
    expect_match(rv$ia$trade_offs$auto_draft, "narrative.empty", fixed = TRUE)
  })
})
