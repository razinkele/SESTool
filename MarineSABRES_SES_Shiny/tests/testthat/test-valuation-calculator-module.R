# tests/testthat/test-valuation-calculator-module.R
# WS-5: valuation calculator module — signature, behaviour (real server), export.
library(testthat)
library(shiny)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
source_for_test(c("functions/valuation_calculations.R", "functions/ui_components.R",
                  "modules/valuation_calculator_module.R"))
# helper-stubs.R may shadow module functions in the helper env; use the real ones (P7).
valuation_calculator_server <- get("valuation_calculator_server", envir = .GlobalEnv)
valuation_calculator_ui <- get("valuation_calculator_ui", envir = .GlobalEnv)

test_that("UI returns namespaced tags with the inputs, disclaimer and download button", {
  ui <- as.character(valuation_calculator_ui("vc", make_test_i18n()))
  for (id in c("vc-area_ha", "vc-services", "vc-horizon", "vc-discount_rate", "vc-restoration_area",
               "vc-cost_bound", "vc-download_xlsx", "vc-results"))
    expect_match(ui, id, fixed = TRUE)
  expect_match(ui, "modules.valuation_calculator.disclaimer", fixed = TRUE)
})

test_that("server has the conventional signature", {
  expect_equal(names(formals(valuation_calculator_server)),
               c("id", "project_data_reactive", "i18n", "event_bus"))
  expect_null(formals(valuation_calculator_server)$event_bus)
})

srv_args <- list(project_data_reactive = shiny::reactiveVal(list()), i18n = make_test_i18n(), event_bus = NULL)
set_defaults <- function(session, ...) {
  vals <- utils::modifyList(list(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20,
                                 discount_rate = NA, restoration_area = NA, cost_bound = "low"), list(...))
  do.call(session$setInputs, vals)
}

test_that("changing the area updates the total and the rendered results", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session)
    expect_equal(unname(valuation()$total[c("low", "high")]), c(4440, 25840))
    expect_match(as.character(output$results$html), "€88\u00a0800", fixed = TRUE)
    session$setInputs(area_ha = 2)
    expect_equal(unname(valuation()$total[c("low", "high")]), c(8880, 51680))
    expect_match(as.character(output$results$html), "€177\u00a0600", fixed = TRUE)
  })
})

test_that("the secondary block carries the toolbox_extension badge and the NPV table", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, discount_rate = 4, restoration_area = 1)
    html <- as.character(output$results$html)
    expect_match(html, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
    for (p in c("0%", "3%", "4%", "5%", "7%")) expect_match(html, p, fixed = TRUE)
    expect_match(html, "modules.valuation_calculator.break_even_heading", fixed = TRUE)
  })
})

test_that("invalid area shows the message and computes nothing", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, area_ha = -3)
    expect_false(valuation()$ok)
    html <- as.character(output$results$html)
    expect_match(html, "modules.valuation_calculator.error.invalid_area", fixed = TRUE)
    expect_false(grepl("€", html, fixed = TRUE))
  })
})

test_that("no services ticked shows the warning and zero totals", {
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session, services = character(0))
    expect_equal(unname(valuation()$total), c(0, 0, 0))
    expect_match(as.character(output$results$html), "modules.valuation_calculator.warn.no_services", fixed = TRUE)
  })
})

test_that("unavailable data shows the message instead of crashing", {
  old <- .wp5_kb_env$db; on.exit({ .wp5_kb_env$db <- old; .wp5_kb_env$loaded <- TRUE })
  .wp5_kb_env$db <- NULL; .wp5_kb_env$loaded <- FALSE
  testServer(valuation_calculator_server, args = srv_args, {
    set_defaults(session)
    expect_match(as.character(output$results$html), "modules.valuation_calculator.error.data_unavailable",
                 fixed = TRUE)
  })
})

test_that("build_valuation_excel writes one sheet with inputs, outputs and provenance", {
  r <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20, restoration_area = 1)
  f <- tempfile(fileext = ".xlsx")
  build_valuation_excel(r, data.frame(parameter = "area_ha", value = "1"), f)
  expect_true(file.exists(f))
  expect_equal(openxlsx::getSheetNames(f), "Valuation")
  x <- openxlsx::read.xlsx(f, colNames = FALSE)
  flat <- unlist(x)
  expect_true("provenance" %in% flat)
  expect_true("area_ha" %in% flat)
  expect_true("wp5_source" %in% flat && "toolbox_extension" %in% flat)
})

test_that("a forced saver failure propagates and leaves no file", {
  r <- compute_valuation(area_ha = 1, services = WP5_VALUATION_SERVICES, horizon = 20)
  f <- tempfile(fileext = ".xlsx")
  expect_error(build_valuation_excel(r, data.frame(parameter = "area_ha", value = "1"), f,
                                     saver = function(...) stop("disk full")), "disk full")
  expect_false(file.exists(f))
})

test_that("the download handler wraps the builder in tryCatch and stops on error (hardening pattern)", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "valuation_calculator_module.R"), warn = FALSE),
             collapse = "\n")
  expect_match(s, "build_valuation_excel(", fixed = TRUE)
  expect_match(s, "stop(e)", fixed = TRUE)
  expect_match(s, "common.messages.excel_export_failed", fixed = TRUE)
})

test_that("the app wires the module under the Response menu", {
  app <- paste(readLines(file.path(PROJECT_ROOT, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, "modules/valuation_calculator_module.R", fixed = TRUE)
  expect_match(app, 'bs4TabItem(tabName = "response_valuation", valuation_calculator_ui("valuation_calc", i18n))',
               fixed = TRUE)
  expect_match(app, 'valuation_calculator_server("valuation_calc", project_data, session_i18n)', fixed = TRUE)
  sb <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_sidebar.R"), warn = FALSE), collapse = "\n")
  expect_match(sb, 'tabName = "response_valuation"', fixed = TRUE)
})

test_that("every valuation-calculator key used in code exists in all 9 languages", {
  langs <- c("en","es","fr","de","lt","pt","it","no","el")
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "valuation_calculator.json"),
                           simplifyVector = FALSE)$translation
  src <- paste(readLines(file.path(PROJECT_ROOT, "modules", "valuation_calculator_module.R"), warn = FALSE),
               collapse = "\n")
  found <- regmatches(src, gregexpr("modules\\.valuation_calculator\\.[A-Za-z0-9_.]*[A-Za-z0-9_]", src))[[1]]
  found <- sub("^modules\\.valuation_calculator\\.", "", found)
  found <- found[!grepl("\\.$", found) & !found %in% c("service", "method", "error", "warn")]  # paste0 prefixes
  keys <- unique(c(found, "title", "subtitle", "help_title", "disclaimer"))
  for (k in paste0("modules.valuation_calculator.", keys)) {
    expect_false(is.null(tr[[k]]), info = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in c("cumulative_label", "central_cumulative", "years_value", "break_even_rate_note"))
    for (l in langs)
      expect_true(grepl("%1$", tr[[paste0("modules.valuation_calculator.", k)]][[l]], fixed = TRUE),
                  info = paste(k, l))
  sb <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "ui", "sidebar.json"),
                           simplifyVector = FALSE)$translation
  for (l in langs) expect_true(nzchar(sb[["ui.sidebar.valuation_calculator"]][[l]] %||% ""), info = l)
})
