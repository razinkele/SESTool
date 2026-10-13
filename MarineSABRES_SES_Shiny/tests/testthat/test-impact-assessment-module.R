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
  testServer(impact_assessment_server, args = srv(mk_project("Tuscan Archipelago")), {
    session$flushReact()
    html <- as.character(output$step_body$html)
    expect_match(html, "modules.impact_assessment.tuscan_empty", fixed = TRUE)
    expect_match(html, "response_valuation", fixed = TRUE)
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

test_that("an existing assessment in the project is loaded, and reloaded on project_loaded", {
  p <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Corridor")))
  args <- srv(p); bus <- create_event_bus("ia-load"); args$event_bus <- bus
  testServer(impact_assessment_server, args = args, {
    session$flushReact()
    expect_identical(rv$ia$characterisation$focal_issue, "Corridor")
    p2 <- set_impact_assessment(mk_project("Macaronesia"), impact_set_section(new_impact_assessment("macaronesia"), "characterisation", list(focal_issue = "Other")))
    args$project_data_reactive(p2); bus$emit_project_loaded("test"); session$flushReact()
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
