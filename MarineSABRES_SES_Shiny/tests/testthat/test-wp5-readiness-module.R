# tests/testthat/test-wp5-readiness-module.R
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "modules/wp5_readiness_module.R"))
real_srv <- get("wp5_readiness_server", envir = .GlobalEnv)
real_ui <- get("wp5_readiness_ui", envir = .GlobalEnv)
i18n_echo <- make_test_i18n()
proj <- function() { p <- create_empty_project("t"); p$project_id <- "p1"; p }

test_that("UI contract: tabs, consent, one radio group per item, wiring in app and sidebar", {
  ui <- as.character(real_ui("rd", i18n_echo))
  for (id in c("rd-consent", "rd-role", "rd-ans_q6", "rd-ans_q35", "rd-save", "rd-upload", "rd-results"))
    expect_match(ui, id, fixed = TRUE)
  expect_match(ui, "modules.wp5_readiness.translation_note", fixed = TRUE)
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus") %in% names(formals(real_srv))))
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "pims_readiness"', fixed = TRUE)
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "modules/wp5_readiness_module.R", fixed = TRUE)
  expect_match(app, 'bs4TabItem(tabName = "pims_readiness"', fixed = TRUE)
  expect_match(app, 'wp5_readiness_server("pims_ready"', fixed = TRUE)
})

test_that("consent is required; an empty answer set is not saved (review focus 1); saves R001, R002 and stamps", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    session$setInputs(ans_q6 = "agree", save = 1)
    expect_equal(nrow(pd()$data$pims$readiness$respondents), 0L)              # no consent
    session$setInputs(consent = TRUE, ans_q6 = character(0), save = 2)
    expect_equal(nrow(pd()$data$pims$readiness$respondents), 0L)              # nothing answered
    session$setInputs(consent = TRUE, role = "fishers", ans_q6 = "agree", ans_q16 = "sometimes", save = 3)
    session$setInputs(consent = TRUE, ans_q19 = "disagree", save = 4)
    r <- pd()$data$pims$readiness$respondents
    expect_equal(r$RespondentId, c("R001", "R002"))
    expect_equal(c(r$Role[1], r$q6[1], r$q16[1], r$q19[2]), c("fishers", "agree", "sometimes", "disagree"))
    expect_equal(pd()$min_app_version, WP5_READINESS_MIN_APP_VERSION)
  })
})

test_that("results: hint with no respondents; indicator, coverage notes and hidden role breakdown with some", {
  p <- proj()
  testServer(real_srv, args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo), {
    session$flushReact()
    expect_match(as.character(output$results$html), "modules.wp5_readiness.no_respondents", fixed = TRUE)
  })
  bank <- load_wp5_readiness_items()
  rows <- data.frame(Role = rep("fishers", 3), q6 = c("agree", "agree", "disagree"), q19 = c("agree", "", ""),
                     stringsAsFactors = FALSE)                     # q19 answered so knowledge shows "low coverage"
  p$data$pims$readiness <- readiness_append(NULL, rows, "import", bank)
  testServer(real_srv, args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo), {
    session$flushReact()
    html <- as.character(output$results$html)
    expect_match(html, "modules.wp5_readiness.indicator_label", fixed = TRUE)
    expect_match(html, "modules.wp5_readiness.coverage_none", fixed = TRUE)
    expect_match(html, "modules.wp5_readiness.coverage_low", fixed = TRUE)
    expect_match(html, "modules.wp5_readiness.roles_hidden", fixed = TRUE)
  })
})

test_that("delete selected; deleting everyone leaves an empty table (review focus 4)", {
  bank <- load_wp5_readiness_items()
  p <- proj()
  p$data$pims$readiness <- readiness_append(NULL, data.frame(Role = c("", ""), q6 = c("agree", "no_answer_x"),
                                                             stringsAsFactors = FALSE), "import", bank)
  pd <- shiny::reactiveVal(p)
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    session$setInputs(respondent_table_rows_selected = 1, delete_selected = 1)
    expect_equal(pd()$data$pims$readiness$respondents$RespondentId, "R002")
    session$setInputs(respondent_table_rows_selected = 1, delete_selected = 2)
    expect_true(is.data.frame(pd()$data$pims$readiness$respondents))
    expect_equal(nrow(pd()$data$pims$readiness$respondents), 0L)
    expect_match(as.character(output$results$html), "modules.wp5_readiness.no_respondents", fixed = TRUE)
  })
})

test_that("import: upload previews, confirm appends with source import", {
  f <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(role = "manager", q6 = "agree", name = "Ana", stringsAsFactors = FALSE), f, row.names = FALSE)
  pd <- shiny::reactiveVal(proj())
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    session$setInputs(upload = list(name = "answers.csv", datapath = f))
    html <- as.character(output$import_preview$html)
    expect_match(html, "modules.wp5_readiness.import_rows", fixed = TRUE)
    session$setInputs(import_confirm = 1)
    r <- pd()$data$pims$readiness$respondents
    expect_equal(c(r$Role, r$q6, r$Source), c("manager", "agree", "import"))
    expect_false("name" %in% names(r))
  })
})

test_that("a missing item bank shows the notice", {
  old <- get("load_wp5_readiness_items", envir = .GlobalEnv)
  assign("load_wp5_readiness_items", function(...) NULL, envir = .GlobalEnv)
  withr::defer(assign("load_wp5_readiness_items", old, envir = .GlobalEnv))
  testServer(real_srv, args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo), {
    session$flushReact()
    expect_match(as.character(output$results$html), "modules.wp5_readiness.unavailable", fixed = TRUE)
  })
})
