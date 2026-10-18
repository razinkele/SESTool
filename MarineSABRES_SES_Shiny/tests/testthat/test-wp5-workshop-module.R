# tests/testthat/test-wp5-workshop-module.R
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "functions/wp5_workshop.R", "modules/wp5_workshop_module.R"))
real_srv <- get("wp5_workshop_server", envir = .GlobalEnv)
real_ui <- get("wp5_workshop_ui", envir = .GlobalEnv)
i18n_echo <- make_test_i18n()
proj <- function() {
  p <- create_empty_project("t"); p$project_id <- "p1"
  p$data$response_measures$measures <- normalize_response_measures(data.frame(
    ID = c("RM001", "RM002"), Name = c("Quota", "Label"), stringsAsFactors = FALSE))
  p
}
fake_register <- function(pd) {                 # writes the project like response_measures_server does
  list(measures = function() normalize_response_measures(pd()$data$response_measures$measures),
       update = function(id, fields) {
         p <- pd(); m <- normalize_response_measures(p$data$response_measures$measures)
         i <- match(id, m$ID); if (is.na(i)) return(FALSE)
         for (cl in names(fields)) m[[cl]][i] <- fields[[cl]]
         p$data$response_measures$measures <- m; pd(p); TRUE
       })
}
with_ws <- function(p, ws) { p$data$pims$workshops <- workshop_set(workshop_create(NULL), ws); p }
base_ws <- function() normalize_workshop(list(id = "W001", title = "A", date = "2026-10-18", interventions = c("RM001", "RM002"),
                                              poll = list(scale = "pm5", criteria = "importance"), tenets_on = TRUE, consent = TRUE))

test_that("UI contract and wiring in app and sidebar", {
  ui <- as.character(real_ui("ws", i18n_echo))
  for (id in c("ws-workshop", "ws-new", "ws-setup", "ws-entry", "ws-results", "ws-apply")) expect_match(ui, id, fixed = TRUE)
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus", "register") %in% names(formals(real_srv))))
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "pims_workshops"', fixed = TRUE)
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "modules/wp5_workshop_module.R", fixed = TRUE)
  expect_match(app, 'bs4TabItem(tabName = "pims_workshops"', fixed = TRUE)
  expect_match(app, "resp_register <- response_measures_server(", fixed = TRUE)
  expect_match(app, 'wp5_workshop_server("pims_ws", project_data, session_i18n, register = resp_register)', fixed = TRUE)
})

test_that("new workshop, set-up save, stamp; set-up locked after the first participant", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(new = 1)
    st <- pd()$data$pims$workshops
    expect_equal(st$items[[1]]$id, "W001")
    expect_equal(pd()$min_app_version, WP5_WORKSHOP_MIN_APP_VERSION)
    session$setInputs(workshop = "W001", title = "Arctic", date = "2026-10-18", note = "", interventions = c("RM002", "RM001"),
                      scale = "four", criteria = c("importance", "feasibility"), tenets_on = TRUE, save_setup = 1)
    ws <- pd()$data$pims$workshops$items[[1]]
    expect_equal(c(ws$title, ws$interventions, ws$poll$scale), c("Arctic", "RM002", "RM001", "four"))
    session$setInputs(consent = TRUE)
    session$setInputs(a_rank__RM002__importance = "3", save_participant = 1)
    session$setInputs(interventions = "RM001", scale = "pm5", save_setup = 2)
    ws <- pd()$data$pims$workshops$items[[1]]
    expect_equal(ws$interventions, c("RM002", "RM001"))
    expect_equal(ws$poll$scale, "four")
  })
})

test_that("consent gate blocks a save; an empty participant is refused", {
  p <- proj(); ws <- base_ws(); ws$consent <- FALSE
  pd <- shiny::reactiveVal(with_ws(p, ws))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001", a_rank__RM001__importance = "2", save_participant = 1)
    expect_equal(nrow(pd()$data$pims$workshops$items[[1]]$respondents), 0L)
    session$setInputs(consent = TRUE)
    session$setInputs(a_rank__RM001__importance = "", save_participant = 2)
    expect_equal(nrow(pd()$data$pims$workshops$items[[1]]$respondents), 0L)
    session$setInputs(a_rank__RM001__importance = "2", a_tenet__RM001__ecol_effective = "agree", save_participant = 3)
    r <- pd()$data$pims$workshops$items[[1]]$respondents
    expect_equal(c(r$RespondentId, r$rank__RM001__importance, r$tenet__RM001__ecol_effective), c("P001", "2", "agree"))
  })
})

test_that("apply writes only changed tenets + TenetSource and records it; undo restores, and refuses after a change", {
  p <- proj(); ws <- base_ws()
  rows <- do.call(rbind, lapply(1:3, function(i) {
    r <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
    r$tenet__RM001__ecol_effective <- "agree"; r$tenet__RM001__tech_feasible <- "completely_disagree"
    as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE)
  }))
  p$data$response_measures$measures$Tenet_tech_feasible[1] <- "minimal"           # already matches -> not written
  pd <- shiny::reactiveVal(with_ws(p, workshop_append(ws, rows, "form")))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001", apply_measure = "RM001")
    m <- pd()$data$response_measures$measures
    expect_equal(c(m$Tenet_ecol_effective[1], m$Tenet_tech_feasible[1]), c("full", "minimal"))
    expect_equal(m$TenetSource[1], "modules.wp5_workshop.source_template")       # echo i18n returns the key
    ap <- pd()$data$pims$workshops$items[[1]]$applied                             # ordering guard: both writes kept
    expect_length(ap, 1)
    expect_equal(names(ap[[1]]$after), c("Tenet_ecol_effective", "TenetSource"))
    session$setInputs(undo_measure = "RM001")
    m <- pd()$data$response_measures$measures
    expect_equal(c(m$Tenet_ecol_effective[1], m$TenetSource[1]), c("", ""))
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 0)
    session$setInputs(apply_measure = "RM001x")                                     # unknown -> nothing
    session$setInputs(apply_measure = "RM001")
    q <- pd(); q$data$response_measures$measures$Tenet_ecol_effective[1] <- "minimal"; pd(q)   # changed elsewhere
    session$setInputs(undo_measure = "RM001x"); session$setInputs(undo_measure = "RM001")
    expect_equal(pd()$data$response_measures$measures$Tenet_ecol_effective[1], "minimal")
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 1)
  })
})

test_that("a measure removed from the register is skipped and shown as removed", {
  p <- proj(); ws <- base_ws()
  p$data$response_measures$measures <- p$data$response_measures$measures[1, , drop = FALSE]
  pd <- shiny::reactiveVal(with_ws(p, ws))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001", apply_measure = "RM002")
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 0)
    expect_match(as.character(output$apply$html), "modules.wp5_workshop.not_in_register", fixed = TRUE)
  })
})

test_that("delete workshop and delete participants go through a confirmation", {
  p <- proj(); ws <- base_ws()
  r <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  r$rank__RM001__importance <- "1"
  pd <- shiny::reactiveVal(with_ws(p, workshop_append(ws, as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE), "form")))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001", respondent_table_rows_selected = 1, delete_resp = 1)
    expect_equal(nrow(pd()$data$pims$workshops$items[[1]]$respondents), 1L)       # not yet
    session$setInputs(delete_resp_confirm = 1)
    expect_equal(nrow(pd()$data$pims$workshops$items[[1]]$respondents), 0L)
    session$setInputs(delete = 1)
    expect_length(pd()$data$pims$workshops$items, 1L)
    session$setInputs(delete_confirm = 1)
    expect_length(pd()$data$pims$workshops$items, 0L)
  })
})

test_that("results render the ranking and heat tables; no register -> apply notice", {
  p <- proj(); ws <- base_ws()
  r <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  r$rank__RM001__importance <- "4"; r$tenet__RM001__ecol_effective <- "agree"
  pd <- shiny::reactiveVal(with_ws(p, workshop_append(ws, as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE), "form")))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    session$setInputs(workshop = "W001")
    html <- as.character(output$results$html)
    expect_match(html, "modules.wp5_workshop.ranking_title", fixed = TRUE)
    expect_match(html, "modules.wp5_workshop.heat_title", fixed = TRUE)
    expect_match(as.character(output$apply$html), "modules.wp5_workshop.apply_unavailable", fixed = TRUE)
  })
})

test_that("an import parsed for one workshop cannot be confirmed into another", {
  p <- proj(); ws <- base_ws(); ws2 <- base_ws(); ws2$id <- "W002"
  p <- with_ws(p, ws); p$data$pims$workshops <- workshop_set(p$data$pims$workshops, ws2)
  pd <- shiny::reactiveVal(p)
  wb <- workshop_template_wb(ws, normalize_response_measures(p$data$response_measures$measures), i18n_echo)
  row <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  row$rank__RM001__importance <- "2"
  openxlsx::writeData(wb, "answers", as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE), startRow = 2, colNames = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001", upload = list(datapath = f, name = "x.xlsx"))
    expect_true(isTRUE(parsed()$ok)); expect_equal(parsed()$ws_id, "W001")
    session$setInputs(workshop = "W002")
    expect_null(parsed())                                                          # cleared on switch
    session$setInputs(import_confirm = 1)
    items <- pd()$data$pims$workshops$items
    expect_equal(vapply(items, function(w) nrow(w$respondents), 1L), c(0L, 0L))
    session$setInputs(workshop = "W001", upload = list(datapath = f, name = "y.xlsx"))
    session$setInputs(import_confirm = 2)
    expect_equal(vapply(pd()$data$pims$workshops$items, function(w) nrow(w$respondents), 1L), c(1L, 0L))
  })
})

test_that("tenet answers offer a blank choice that saves as empty; New/Duplicate keep working", {
  p <- proj(); ws <- base_ws()
  pd <- shiny::reactiveVal(with_ws(p, ws))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001")
    expect_match(as.character(output$entry$html), "modules.wp5_workshop.answer.blank", fixed = TRUE)
    session$setInputs(a_rank__RM001__importance = "2", a_tenet__RM001__ecol_effective = "", save_participant = 1)
    r <- pd()$data$pims$workshops$items[[1]]$respondents
    expect_equal(c(r$rank__RM001__importance, r$tenet__RM001__ecol_effective), c("2", ""))
    session$setInputs(new = 1)
    expect_equal(vapply(pd()$data$pims$workshops$items, `[[`, "", "id"), c("W001", "W002"))
    expect_null(want_select())                                                     # consumed by the list observer in the same flush
    session$setInputs(workshop = "W002", duplicate = 1)
    expect_equal(vapply(pd()$data$pims$workshops$items, `[[`, "", "id"), c("W001", "W002", "W003"))
  })
})

test_that("apply for a measure that left the register warns; unchanged-but-present stays silent", {
  p <- proj(); ws <- base_ws()
  rows <- do.call(rbind, lapply(1:3, function(i) {
    r <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
    r$tenet__RM002__ecol_effective <- "agree"
    as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE)
  }))
  p$data$response_measures$measures <- p$data$response_measures$measures[1, , drop = FALSE]
  pd <- shiny::reactiveVal(with_ws(p, workshop_append(ws, rows, "form")))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001")
    expect_no_error(session$setInputs(apply_measure = "RM002"))                    # gone -> warning path, no write
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 0)
  })
})

test_that("follow-up: locked set-up shows translated yes/no; source line has no space before the colon", {
  p <- proj(); ws <- base_ws()
  r <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  r$rank__RM001__importance <- "1"
  p$data$response_measures$measures$TenetSource[1] <- "Workshop W001 (2026-10-18, n = 3)"
  pd <- shiny::reactiveVal(with_ws(p, workshop_append(ws, as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE), "form")))
  testServer(real_srv, args = list(project_data_reactive = pd, i18n = i18n_echo, register = fake_register(pd)), {
    session$flushReact()
    session$setInputs(workshop = "W001")
    setup <- as.character(output$setup$html)
    expect_match(setup, "modules.wp5_workshop.yes", fixed = TRUE)
    expect_false(grepl("\u2713", setup, fixed = TRUE))
    expect_match(as.character(output$apply$html),
                 "modules.wp5_workshop.tenet_source: Workshop W001 (2026-10-18, n = 3)", fixed = TRUE)
  })
})
