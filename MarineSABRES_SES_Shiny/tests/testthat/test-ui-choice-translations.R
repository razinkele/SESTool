# tests/testthat/test-ui-choice-translations.R
# Select/checkbox option labels go through i18n (German feedback 2026-10-13),
# and option values stay language-independent ids.
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/matrix_from_linked.R",
                  "modules/export_reports_module.R",
                  "modules/cld_visualization_module.R"))
# Re-bind the real server over the helper-stubs.R stub (see test-isa-responses-entry.R).
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)
cld_viz_ui <- get("cld_viz_ui", envir = .GlobalEnv)
export_reports_ui <- get("export_reports_ui", envir = .GlobalEnv)

# A translator that visibly changes every key, so untranslated English shows up.
fake_i18n <- list(t = function(key, ...) switch(key,
  "common.misc.step_d_of_d" = "T %d/%d",   # sprintf formats keep their slots
  "common.choices.loop_n" = "T %d",
  paste0("T[", key, "]")))

choices_file <- test_path("..", "..", "translations", "common", "choices.json")

test_that("common.choices keys have a non-empty text in all 9 languages", {
  tr <- jsonlite::fromJSON(choices_file, simplifyVector = FALSE)$translation
  expect_gt(length(tr), 0)
  for (k in names(tr)) {
    for (lang in c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")) {
      expect_true(nzchar(tr[[k]][[lang]] %||% ""), info = paste(k, lang))
    }
  }
})

ui_inputs <- function(ui, name_suffix) {
  html <- as.character(htmltools::renderTags(ui)$html)
  m <- regmatches(html, gregexpr(sprintf('<input[^>]*name="[^"]*%s"[^>]*>', name_suffix), html))[[1]]
  list(values = sub('.*value="([^"]*)".*', "\\1", m),
       checked = grepl("checked", m), html = html)
}

test_that("Export Data components submit ids and show translated labels", {
  ui <- export_reports_ui("exp", fake_i18n)
  got <- ui_inputs(ui, "export_data_components")
  expect_equal(got$values, c("metadata", "pims", "isa_data", "cld", "analysis", "responses"))
  # The defaults are ticked (they used to match nothing).
  expect_equal(got$values[got$checked], c("metadata", "isa_data", "cld"))
  expect_true(grepl("T[modules.export.reports.project_metadata]", got$html, fixed = TRUE))
})

test_that("report type and CLD edit options are translated, values unchanged", {
  html <- as.character(htmltools::renderTags(export_reports_ui("exp", fake_i18n))$html)
  expect_true(grepl('value="executive"', html, fixed = TRUE))
  expect_true(grepl("T[common.choices.report_executive]", html, fixed = TRUE))
  expect_false(grepl("Executive Summary", html, fixed = TRUE))

  cld <- as.character(htmltools::renderTags(cld_viz_ui("cld", fake_i18n))$html)
  for (txt in c("Reinforcing (+)", "Very Low (1/5)", "Hierarchical (DAPSI)", "Down-Up")) {
    expect_false(grepl(txt, cld, fixed = TRUE), info = txt)
  }
  expect_true(grepl("T[common.choices.polarity_reinforcing]", cld, fixed = TRUE))
  expect_true(grepl('value="DU"', cld, fixed = TRUE))
})

test_that("ISA exercise navigation works when tab titles are translated", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = fake_i18n), {
    # The tabset reports the tab's value (its key), not the translated title.
    session$setInputs(isa_tabs = "modules.isa.data_entry.ex3.exercise_3_pressures")
    expect_equal(current_exercise(), 5L)
    session$setInputs(nav_next = 1)
    expect_equal(current_exercise(), 6L)
    session$setInputs(nav_back = 1)
    expect_equal(current_exercise(), 5L)
    expect_false(session$isClosed())
  })
})
