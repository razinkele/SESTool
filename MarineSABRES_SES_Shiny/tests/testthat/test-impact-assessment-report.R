# tests/testthat/test-impact-assessment-report.R
library(testthat)
load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"), force_reload = TRUE)
load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)
source_for_test(c("functions/impact_assessment_view.R", "functions/impact_assessment_report.R"))
i18n <- make_test_i18n()   # echoes keys; wp5_vocab_label() then falls back to the code

# A real translator over the module + vocabulary files, one language at a time
real_t <- function(lang) {
  files <- file.path(PROJECT_ROOT, "translations", "modules", c("impact_assessment.json", "wp5_vocabulary.json", "wp5_mechanisms.json"))
  tr <- do.call(c, lapply(files, function(f) jsonlite::fromJSON(f, simplifyVector = FALSE)$translation))
  structure(list(t = function(key, ...) { v <- tr[[key]][[lang]]; if (is.null(v) || !nzchar(v)) key else v }, translator = NULL), class = "i18n_stub")
}
LANGS <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

# Fixture: Macaronesia reference starters (S1 baseline), one copied cell, one assessed low-confidence cell,
# one no_change cell, one trade-off scenario (S2: EE up, FF down)
fixture_ia <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  cl <- impact_get_cell(ia, "EQ", "S4")
  cl$direction <- "increase"; cl$magnitude <- "substantial"; cl$timing <- "long"
  cl$confidence <- "low"; cl$uncertainty_driver <- "implementation_dependency"
  cl$evidence <- c("literature", "stakeholder"); cl$rationale <- "Needs compensation – €0.25–1m/yr band"
  cl$indicator_roles <- list(C_01 = "primary"); cl$mechanism_ids <- "mac_01"
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  up <- new_impact_cell(); up$direction <- "increase"; up$magnitude <- "moderate"; up$confidence <- "high"
  dn <- new_impact_cell(); dn$direction <- "decrease"; dn$magnitude <- "incremental"; dn$timing <- "short"; dn$confidence <- "medium"
  nc <- new_impact_cell(); nc$direction <- "no_change"; nc$confidence <- "high"
  ia <- impact_set_cell(ia, "EE", "S2", up)
  ia <- impact_set_cell(ia, "FF", "S2", dn)
  ia <- impact_set_cell(ia, "PI", "S3", nc)
  ia <- impact_set_section(ia, "characterisation", list(focal_issue = "Migratory corridor", stakeholders = "Fishers; tour operators"))
  ia <- impact_set_section(ia, "uncertainty", list(notes = "Compliance in ABNJ — Δ unknown"))
  ia <- impact_set_section(ia, "recommendations", list(text = "Pilot S3 first (Πιλοτικό)"))
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003"), indicator_codes = "C_01")
  impact_set_displacement(ia, "yes", "Effort may move to ABNJ waters")
}

test_that(".ia_fmt formats positional placeholders and falls back when the translation dropped them", {
  expect_identical(.ia_fmt("%1$s vs %2$s", "a", "b"), "a vs b")
  expect_identical(.ia_fmt("%2$s then %1$s", "a", "b"), "b then a")
  expect_identical(.ia_fmt("no placeholders", "a", 2L), "no placeholders a 2")
  expect_silent(.ia_fmt("one %1$s only", "a", "b"))
})

test_that(".ia_scenario_order ranks by ambition then code, unranked last", {
  ia <- new_impact_assessment("macaronesia")
  ia <- impact_add_scenario(ia, new_impact_scenario("B", "b", ambition_rank = 2L))
  ia <- impact_add_scenario(ia, new_impact_scenario("Z", "z"))                       # unranked
  ia <- impact_add_scenario(ia, new_impact_scenario("A", "a", ambition_rank = 2L))
  ia <- impact_add_scenario(ia, new_impact_scenario("C", "c", ambition_rank = 1L))
  expect_identical(.ia_scenario_order(ia), c("C", "A", "B", "Z"))
})

test_that("the draft is built only from keys and codes: every sentence type appears for the fixture", {
  txt <- impact_narrative_draft(fixture_ia(), i18n)
  K <- "modules.impact_assessment.narrative."
  # NOTE: scenario_unassessed is NOT in this list on purpose — every non-baseline fixture scenario has at
  # least one assessed cell (S2: EE/FF, S3: PI, S4: EQ), so that sentence never fires here. See the dedicated test below.
  for (k in c("intro", "scenario_lead", "increase", "decrease", "no_change",
              "trade_off", "low_confidence", "displacement", "unassessed", "closing"))
    expect_match(txt, paste0(K, k), fixed = TRUE, info = k)
  expect_false(grepl(paste0(K, "synergy"), txt, fixed = TRUE))         # no scenario with ≥2 increases and no decrease
  expect_false(grepl(paste0(K, "no_trade_offs"), txt, fixed = TRUE))
  expect_false(grepl("S1", strsplit(txt, "\n\n")[[1]][2], fixed = TRUE))  # baseline has no per-scenario paragraph
  expect_match(txt, "EE (moderate)", fixed = TRUE)                        # codes fall back when labels are missing
  expect_match(txt, "FF (incremental, short)", fixed = TRUE)
  expect_match(txt, "Effort may move to ABNJ waters", fixed = TRUE)
  expect_true(startsWith(strsplit(txt, "\n\n")[[1]][3], K))               # S3 before S4 (ambition rank order)
})

test_that("an empty assessment and a baseline-only assessment draft without error", {
  expect_match(impact_narrative_draft(new_impact_assessment("macaronesia"), i18n), "narrative.empty", fixed = TRUE)
  ia <- impact_add_scenario(new_impact_assessment(""), new_impact_scenario("BAU", "Business as usual"))
  ia <- impact_set_baseline(ia, "BAU")
  txt <- impact_narrative_draft(ia, i18n)
  expect_match(txt, "narrative.intro", fixed = TRUE)
  expect_match(txt, "narrative.closing", fixed = TRUE)
  expect_false(grepl("narrative.unassessed", txt, fixed = TRUE))
})

test_that("a scenario with no assessed cell gets the scenario_unassessed sentence and counts in the unassessed total", {
  ia <- impact_add_scenario(new_impact_assessment(""), new_impact_scenario("BAU", "Business as usual"))
  ia <- impact_add_scenario(ia, new_impact_scenario("ALT", "Alternative"))
  ia <- impact_set_baseline(ia, "BAU")
  txt <- impact_narrative_draft(ia, i18n)
  expect_match(txt, "narrative.scenario_unassessed", fixed = TRUE)
  expect_match(txt, "ALT (Alternative)", fixed = TRUE)
  expect_match(txt, paste0("narrative.unassessed ", nrow(WP5_CRITERIA), " ", nrow(WP5_CRITERIA)), fixed = TRUE)  # key-echo fallback appends args
  expect_false(grepl("narrative.scenario_lead", txt, fixed = TRUE))
})

test_that("in all 9 languages the draft has no raw key, no leftover placeholder, and real labels", {
  ia <- fixture_ia()
  for (l in LANGS) {
    txt <- impact_narrative_draft(ia, real_t(l))
    expect_false(grepl("modules.", txt, fixed = TRUE), info = l)
    expect_false(grepl("%[0-9]\\$", txt), info = l)
    expect_match(txt, "S2", fixed = TRUE, info = l)
    expect_false(grepl("\\bEE\\b", txt), info = paste(l, "criterion code leaked"))
  }
  en <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  txt <- impact_narrative_draft(ia, real_t("en"))
  expect_match(txt, sub("%1\\$s.*$", "", en[["modules.impact_assessment.narrative.low_confidence"]][["en"]]), fixed = TRUE)
  expect_match(txt, en[["modules.impact_assessment.narrative.closing"]][["en"]], fixed = TRUE)
})

test_that("the narrative keys exist in all 9 languages and keep their placeholders", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  ph <- list(intro = c("%1$d", "%2$s"), intro_no_baseline = "%1$d", scenario_lead = "%1$s", increase = "%1$s", decrease = "%1$s",
             no_change = "%1$s", uncertain = "%1$s", scenario_unassessed = "%1$s", trade_off = c("%1$s", "%2$s", "%3$s"),
             synergy = c("%1$s", "%2$s"), no_trade_offs = character(0), low_confidence = c("%1$s", "%2$s"), no_driver = character(0),
             displacement = "%1$s", no_note = character(0), unassessed = c("%1$d", "%2$d"), closing = character(0), empty = character(0))
  for (k in names(ph)) for (l in LANGS) {
    v <- tr[[paste0("modules.impact_assessment.narrative.", k)]][[l]]
    expect_true(!is.null(v) && nzchar(v), info = paste(k, l))
    for (p in ph[[k]]) expect_true(grepl(p, v, fixed = TRUE), info = paste(k, l, p))
  }
})

# ---- impact_report_data ----------------------------------------------------------
report_project <- function(ia = fixture_ia(), canonical_cols = FALSE) {
  p <- create_empty_project("Corridor case"); p$data$metadata$project_name <- "Corridor case"; p$data$metadata$da_site <- "Macaronesia"
  el <- data.frame(id = c("P001", "C003"), name = c("Trawling pressure", "Seabird colony"), stringsAsFactors = FALSE)
  if (canonical_cols) names(el) <- c("ID", "Name")
  p$data$isa_data$pressures <- el[1, , drop = FALSE]; p$data$isa_data$marine_processes <- el[2, , drop = FALSE]
  set_impact_assessment(p, ia)
}

test_that("impact_report_data returns every block with the fixture's content", {
  r <- impact_report_data(report_project(), fixture_ia(), i18n)
  expect_identical(r$meta$project_name, "Corridor case")
  expect_identical(r$meta$da, "macaronesia"); expect_identical(r$meta$baseline, "S1"); expect_identical(r$meta$n_scenarios, 4L)
  expect_identical(r$characterisation$value[r$characterisation$field == "focal_issue"], "Migratory corridor")
  expect_identical(r$scenarios$code, c("S1", "S2", "S3", "S4"))
  expect_identical(r$scope_elements$name, c("Trawling pressure", "Seabird colony"))
  expect_identical(r$scope_indicators$code, "C_01"); expect_true(nzchar(r$scope_indicators$name))
  expect_identical(nrow(r$displacement), 3L)
  expect_match(r$displacement$value[2], "ABNJ", fixed = TRUE)
  expect_identical(names(r$matrix_wide), c("criterion", "S1", "S2", "S3", "S4"))
  expect_identical(nrow(r$matrix_wide), nrow(WP5_CRITERIA))
  expect_match(r$matrix_wide$S2[r$matrix_wide$criterion == "EE"], "\u2191", fixed = TRUE)      # glyph + magnitude code
  expect_identical(nrow(r$cells_long), nrow(WP5_CRITERIA) * 4L)
  eq_s4 <- r$cells_long[r$cells_long$criterion == "EQ" & r$cells_long$scenario == "S4", ]
  expect_identical(eq_s4$evidence, "literature, stakeholder")
  expect_match(eq_s4$indicators, "C_01 (primary)", fixed = TRUE)
  expect_match(eq_s4$mechanisms, "mac_01", fixed = TRUE)
  expect_match(eq_s4$rationale, "€0.25–1m/yr", fixed = TRUE)
  ee_s3 <- r$cells_long[r$cells_long$criterion == "EE" & r$cells_long$scenario == "S3", ]
  expect_match(ee_s3$reference, "Table 21", fixed = TRUE)
  expect_identical(r$mechanisms$id, "mac_01"); expect_identical(r$mechanisms$provenance, "wp5_source")
  expect_match(r$mechanisms$linked_to, "EQ / S4", fixed = TRUE)
  expect_true("reference_copy" %in% r$provenance$kind)                                        # copied EE/S3, unedited
  expect_false("reference_copy_edited" %in% r$provenance$kind)
  expect_false("toolbox_extension" %in% r$provenance$kind)                                     # no draft stored yet
  expect_identical(r$text$recommendations, "Pilot S3 first (Πιλοτικό)")
})

test_that("the provenance appendix records an edited copy and the toolbox draft", {
  ia <- fixture_ia()
  cl <- impact_get_cell(ia, "EE", "S3"); cl$rationale <- paste(cl$rationale, "(edited)"); ia <- impact_set_cell(ia, "EE", "S3", cl)
  ia <- impact_set_section(ia, "trade_offs", list(auto_draft = impact_narrative_draft(ia, i18n)))
  r <- impact_report_data(report_project(ia), ia, i18n)
  expect_true("reference_copy_edited" %in% r$provenance$kind)
  expect_true("toolbox_extension" %in% r$provenance$kind)
  expect_identical(r$provenance$provenance[r$provenance$kind == "reference_copy_edited"], "wp5_derived")
})

test_that("unknown mechanism ids / indicator codes and canonical ID/Name columns do not break the report data", {
  ia <- fixture_ia()
  cl <- impact_get_cell(ia, "EQ", "S4"); cl$mechanism_ids <- c("mac_01", "gone_99"); cl$indicator_roles <- list(NOPE_1 = "supporting")
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003", "X999"), indicator_codes = c("C_01", "NOPE_1"))
  r <- impact_report_data(report_project(ia, canonical_cols = TRUE), ia, i18n)
  expect_identical(r$scope_elements$name, c("Trawling pressure", "Seabird colony", "X999"))     # unknown id shown as id
  expect_identical(r$scope_indicators$name[r$scope_indicators$code == "NOPE_1"], "")
  gone <- r$mechanisms[r$mechanisms$id == "gone_99", ]
  expect_identical(gone$name, "gone_99"); expect_identical(gone$provenance, "")
})

test_that("an empty assessment yields empty tables and '(not provided)' text, not an error", {
  r <- impact_report_data(create_empty_project("x"), new_impact_assessment(""), i18n)
  expect_identical(nrow(r$scenarios), 0L); expect_identical(nrow(r$cells_long), 0L); expect_identical(nrow(r$provenance), 0L)
  expect_identical(names(r$matrix_wide), "criterion")
  expect_identical(r$text$recommendations, "")
  expect_identical(r$meta$da_label, "modules.impact_assessment.da.none")
})

test_that("the report keys exist in all 9 languages", {
  # The explicit contract (the Step 4 table), not a regex over the source: heading keys are built with
  # t(paste0(K, ...)) so a source scan only ever sees the sentinel comments.
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "impact_assessment.json"), simplifyVector = FALSE)$translation
  REPORT_KEYS <- c("title", "subtitle", "project", "da", "generated", "ref_version", "baseline",
    paste0("section.", c("characterisation", "scenarios", "scope", "matrix", "uncertainty", "trade_offs", "recommendations")),
    "appendix_mechanisms", "appendix_provenance", "scope_elements", "scope_indicators", "displacement", "matrix_summary", "matrix_detail",
    "draft_label", "user_text_label", "empty", "none", "yes", "no", "stub", "narrative_item", "provenance_none", "provenance_intro",
    paste0("kind.", c("reference_copy", "reference_copy_edited", "mechanism", "indicator", "toolbox_extension")),
    paste0("col.", c("code", "name", "baseline", "ambition", "source", "description", "id", "provenance", "criterion", "scenario",
                     "direction", "magnitude", "timing", "confidence", "evidence", "uncertainty_driver", "rationale", "subdimensions",
                     "indicators", "mechanisms", "reference", "source_ref", "linked_to", "kind", "item", "detail", "label", "value")))
  expect_length(REPORT_KEYS, 64L)   # = the number of rows in the Step 4 table
  for (k in paste0("modules.impact_assessment.report.", REPORT_KEYS)) for (l in LANGS) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  expect_true(nzchar(jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "wp5_mechanisms.json"), simplifyVector = FALSE)$translation[["modules.wp5_mechanisms.provenance.wp5_source"]][["el"]] %||% ""))
})

# ---- docx ----------------------------------------------------------------------------
docx_text <- function(path) officer::docx_summary(officer::read_docx(path))$text

test_that("build_impact_report_docx writes every section, the matrix, both appendices and non-ASCII text", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  ia <- fixture_ia(); ia <- impact_set_section(ia, "trade_offs", list(text = "S4: equity vs cost", auto_draft = impact_narrative_draft(ia, i18n)))
  r <- impact_report_data(report_project(ia), ia, i18n)
  f <- tempfile(fileext = ".docx")
  build_impact_report_docx(r, i18n, f)
  expect_true(file.exists(f) && file.info(f)$size > 0)
  txt <- paste(docx_text(f), collapse = "\n")
  for (k in c("report.title", "report.section.characterisation", "report.section.scenarios", "report.section.scope", "report.section.matrix",
              "report.section.uncertainty", "report.section.trade_offs", "report.section.recommendations",
              "report.appendix_mechanisms", "report.appendix_provenance", "report.draft_label", "report.user_text_label"))
    expect_match(txt, paste0("modules.impact_assessment.", k), fixed = TRUE, info = k)
  expect_match(txt, "Corridor case", fixed = TRUE)
  expect_match(txt, "Migratory corridor", fixed = TRUE)
  expect_match(txt, "Pilot S3 first (Πιλοτικό)", fixed = TRUE)
  expect_match(txt, "€0.25–1m/yr", fixed = TRUE)
  expect_match(txt, "mac_01", fixed = TRUE)
  expect_match(txt, "narrative.closing", fixed = TRUE)                     # the draft is in the document
  expect_match(txt, "report.kind.reference_copy", fixed = TRUE)
  expect_match(txt, "report.kind.toolbox_extension", fixed = TRUE)
})

test_that("an empty assessment still produces a valid document with the 'none' appendix line", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  r <- impact_report_data(create_empty_project("x"), new_impact_assessment(""), i18n)
  f <- tempfile(fileext = ".docx")
  build_impact_report_docx(r, i18n, f)
  txt <- paste(docx_text(f), collapse = "\n")
  expect_match(txt, "report.provenance_none", fixed = TRUE)
  expect_match(txt, "report.empty", fixed = TRUE)
})

test_that("a forced writer failure propagates and leaves no file", {
  r <- impact_report_data(report_project(), fixture_ia(), i18n)
  f <- tempfile(fileext = ".docx")
  expect_error(build_impact_report_docx(r, i18n, f, writer = function(doc, target) stop("disk full")), "disk full")
  expect_false(file.exists(f))
})
