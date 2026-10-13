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
