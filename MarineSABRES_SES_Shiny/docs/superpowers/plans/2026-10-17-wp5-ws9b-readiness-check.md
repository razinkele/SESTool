# WP5 WS-9b Governance-Readiness Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A PIMS "Governance readiness (D5.4)" page where a DA team enters (form) or imports (xlsx/csv template) anonymous answers to the D5.4 stakeholder questionnaire and sees a per-NPG-dimension toolbox indicator, item distributions and the Annex 7 priority ranking.

**Architecture:** A hand-written item bank (`data/wp5_readiness_items.json`, English text verified against the D5.4 PDF) drives everything. Pure R functions in `functions/wp5_readiness.R` store, score, import and export answers kept in `data$pims$readiness`; a thin module `modules/wp5_readiness_module.R` renders the three tabs. Projects with respondents are stamped 1.31.0.

**Tech Stack:** R ≥ 4.4.1, Shiny + bs4Dash, shiny.i18n, jsonlite, openxlsx, DT, testthat 3; Python (micromamba env `shiny`) with PyMuPDF (`fitz`), pytest.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-17-wp5-ws9b-readiness-check-design.md` (the authority; decisions D1–D6).

All paths are relative to `MarineSABRES_SES_Shiny/` in the worktree `C:/Users/arturas.baziukas/wt-ws9b` (branch `feat/wp5-ws9b-readiness-check`, from main e646b53). Git root is one level up: `git -C C:/Users/arturas.baziukas/wt-ws9b ...`, never `cd <path> && git`.

## Global Constraints

- D5.4 sources are only in the main checkout: `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5`. Python tests that need them skip when absent (env var `WP5_DIR` or that default). CI does not run pytest.
- **Python safety:** only `micromamba run -n shiny python <script file or -m module>`, in the FOREGROUND. Never `python -`, `python3 -`, a bare `python`, a heredoc into python, or any background command — a console-less stdin starts the Python REPL, which loops a traceback forever (it filled the disk on 2026-10-17).
- R tests from the app dir, one file filter per process, user library first: `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^wp5-readiness$')"`. Never run several R test processes at once (16 GB laptop). "package built under R version 4.4.3" warnings are environment noise.
- Dimensions = `NPG_DIMENSIONS` (`knowledge, collaboration, values_conflict, legitimacy_equity, cross_sectoral`); labels via `wp5_vocab_label("npg", code, i18n)`.
- Scoring (spec §5, D6): agree7 +2…−2 (`dont_know`, `prefer_not` excluded); yes_no ±1; yes_no_sometimes +1/0/−1; extent5 −2…+2; `reverse` flips the sign; only `kind == "state"` items feed the indicator; cross_sectoral has no state item (coverage `none`), knowledge one (coverage `low`). Rank 1 = most important.
- Storage `data$pims$readiness = list(version = "1.0", respondents = <data.frame>)`; columns `RespondentId` (`R001`…), `EnteredAt`, `Source` (`form`/`import`), `Role`, then one column per item id. No names, contacts or free text are ever stored or read.
- `WP5_READINESS_MIN_APP_VERSION <- "1.31.0"`, stamped whenever a project with ≥ 1 respondent is written by the module or loaded through `normalize_json_project_data()`.
- Every label through `i18n$t()` (9 languages: en, es, fr, de, lt, pt, it, no, el); dynamic keys get `# i18n-ref:` sentinels; the audit (`micromamba run -n shiny python scripts/_i18n_audit.py`, "Totals:" line) must show `missing=0 hardcoded=0`. Never edit `translations/_merged_translations.json`.
- New single ids via `next_element_id()` + `safe_counter()` (functions/data_structure.R).
- Module tests re-bind real functions from `.GlobalEnv` before `testServer()`.
- Commits: message file, `git -C <wt> commit -F <file>`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_013pgU49PTbBYa3XxbHfFRC6`. `docs/` is gitignored (`git add -f`). Never add `__pycache__/`.

## Rulings made while planning

1. **A consented form with no answer and no role saves nothing** (notice "nothing to save"); an empty row would inflate the respondent count.
2. **Answer labels are keyed by code** (`modules.wp5_readiness.answer.<code>`): codes are unique across scales (`prefer_not` exists for answers and for roles but under different key prefixes). Import matching is done per item scale, so "No" can only map to `no` where the scale has it.
3. **Rank items get no answer labels** (codes `1`…`5`).
4. **Fully empty imported rows are dropped** and counted, not added as empty respondents.
5. **Respondent ids keep the spec's `R001` form**; they live in `data$pims$readiness`, separate from ISA Response element ids.

## Review Focus

1. Consent ticked but nothing answered → nothing saved, a notice (Task 5 test).
2. An import file whose cells are all blank → no respondents added, no error (Task 4 test).
3. A loaded project with answers for an item id the bank no longer has → the answers are kept but not scored (Task 2 test).
4. Deleting every respondent → an empty table (never NULL), Results shows the no-respondents hint (Task 2 and Task 5 tests).
5. A dimension where every answer is "I don't know" → "no answers", not NaN (Task 2 test).

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `data/wp5_readiness_items.json` | 1 | item bank |
| `scripts/tests/test_wp5_readiness_items.py` | 1 | verbatim check vs D5.4 |
| `tests/testthat/test-wp5-readiness-items.R` | 1 | item-bank schema |
| `.gitattributes` | 1 | LF for the item bank |
| `constants.R`, `functions/wp5_readiness.R` (new), `functions/data_structure.R`, `global.R` | 2, 4 | storage, scoring, import/export |
| `tests/testthat/test-wp5-readiness.R` | 2, 4 | pure-function tests |
| `translations/modules/wp5_readiness.json` (new), `translations/ui/sidebar.json` | 3 | keys |
| `modules/wp5_readiness_module.R` (new), `functions/ui_sidebar.R`, `app.R` | 5 | page and wiring |
| `tests/testthat/test-wp5-readiness-module.R` | 5 | module tests |
| `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md` | 6 | release 1.31.0 |

---

### Task 1: Item bank and its verification

**Files:** Create `data/wp5_readiness_items.json`, `scripts/tests/test_wp5_readiness_items.py`, `tests/testthat/test-wp5-readiness-items.R`; modify `.gitattributes` (app dir).

**Interfaces:** Produces the item bank exactly as below (19 items: q3 q4 q5 q6 q7 q8 q9 q10 q13 q15 q16 q17 q18 q19 q35 q36 q37 q38 q39).

- [ ] **Step 1: Write the R schema test** `tests/testthat/test-wp5-readiness-items.R`:

```r
# tests/testthat/test-wp5-readiness-items.R
# WS-9b (spec 2026-10-17 §3): schema of the D5.4 readiness item bank.
library(testthat)
bank <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_readiness_items.json"), simplifyVector = FALSE)
ids <- vapply(bank$items, `[[`, "", "id")

test_that("item ids, kinds and scales", {
  expect_equal(ids, c("q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q13", "q15", "q16", "q17", "q18", "q19",
                      "q35", "q36", "q37", "q38", "q39"))
  kinds <- vapply(bank$items, `[[`, "", "kind")
  expect_equal(ids[kinds == "state"], c("q3", "q4", "q6", "q10", "q13", "q15", "q16", "q17", "q18", "q19"))
  expect_equal(ids[kinds == "attitude"], c("q5", "q7", "q8", "q9"))
  expect_equal(ids[kinds == "priority"], c("q35", "q36", "q37", "q38", "q39"))
  for (it in bank$items) expect_true(it$scale %in% names(bank$scales), info = it$id)
  expect_equal(vapply(Filter(function(it) isTRUE(it$reverse), bank$items), `[[`, "", "id"), c("q10", "q13"))
})

test_that("dimensions: NPG_DIMENSIONS, q39 none, cross_sectoral has no state item, knowledge one", {
  for (it in bank$items) {
    if (identical(it$id, "q39")) expect_null(it$dimension) else expect_true(it$dimension %in% NPG_DIMENSIONS, info = it$id)
  }
  st <- Filter(function(it) identical(it$kind, "state"), bank$items)
  dims <- vapply(st, `[[`, "", "dimension")
  expect_false("cross_sectoral" %in% dims)
  expect_equal(sum(dims == "knowledge"), 1L)
})

test_that("scales: codes and points as decided (D6)", {
  pts <- function(s) unlist(lapply(bank$scales[[s]]$points, function(p) if (is.null(p)) NA else p))
  expect_equal(unlist(bank$scales$agree7$codes),
               c("completely_agree", "agree", "neither", "disagree", "completely_disagree", "dont_know", "prefer_not"))
  expect_equal(pts("agree7"), c(2, 1, 0, -1, -2, NA, NA))
  expect_equal(pts("yes_no"), c(1, -1))
  expect_equal(pts("yes_no_sometimes"), c(1, 0, -1))
  expect_equal(pts("extent5"), c(-2, -1, 0, 1, 2))
  expect_equal(unlist(bank$scales$rank5$codes), as.character(1:5))
  expect_equal(unlist(bank$roles), c("government", "manager", "researcher", "tourism_operator", "fishers",
                                     "civil_society", "industry", "general_public", "other", "prefer_not"))
})

test_that("every item has text and a D5.4 source", {
  for (it in bank$items) {
    expect_true(nzchar(it$text_en), info = it$id)
    expect_match(it$source_ref, "^D5\\.4 Annex [57] Q[0-9]+, p\\. [0-9]+$", info = it$id)
  }
})
```

- [ ] **Step 2: Write the pytest** `scripts/tests/test_wp5_readiness_items.py`:

```python
"""Verify data/wp5_readiness_items.json text against D5.4 Annexes 5 and 7 (spec 2026-10-17 WS-9b §8)."""
import json
import os
import re
import unicodedata
from functools import lru_cache
from pathlib import Path

import pytest

APP = Path(__file__).resolve().parents[2]
WP5 = Path(os.environ.get("WP5_DIR", "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/"
                                     "SESToolbox/MarineSABRES_SES_Shiny/WP5"))
D54 = WP5 / "Task 5.4 Governance Measures & Targets" / "Deliverable 5.4" / "final version" / \
    "MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf"
BANK = json.loads((APP / "data" / "wp5_readiness_items.json").read_text(encoding="utf-8"))
needs_src = pytest.mark.skipif(not D54.exists(), reason="D5.4 sources not available (WP5/ is not in git)")
ANNEX5_PAGES = range(140, 146)    # PDF pages (printed 139-144)
ANNEX7_PAGES = range(149, 154)


def key(s):
    return re.sub(r"[^0-9a-z]", "", unicodedata.normalize("NFKC", s).lower())


@lru_cache(maxsize=None)
def pages_text(first, last):
    import fitz
    doc = fitz.open(str(D54))
    return key(" ".join(doc[p - 1].get_text() for p in range(first, last + 1)))


@needs_src
@pytest.mark.parametrize("item", BANK["items"], ids=lambda it: it["id"])
def test_item_text_is_in_its_annex(item):
    pages = ANNEX7_PAGES if item["source_ref"].startswith("D5.4 Annex 7") else ANNEX5_PAGES
    assert key(item["text_en"]) in pages_text(pages.start, pages.stop - 1), item["id"]


@needs_src
def test_a_made_up_item_is_rejected():
    assert key("Stakeholders always agree on everything") not in pages_text(140, 145)
```

- [ ] **Step 3: Run both to verify they fail** — pytest (`micromamba run -n shiny python -m pytest scripts/tests/test_wp5_readiness_items.py -q -p no:cacheprovider`) and filter `'^wp5-readiness-items$'`: errors, file missing.

- [ ] **Step 4: Create `data/wp5_readiness_items.json`** (UTF-8, LF, 2-space indent) with exactly this content (texts are D5.4 Annex 5/7 verbatim; check the printed page numbers against the PDF and correct any that differ — the test only checks the format):

```json
{
  "version": "1.0",
  "source": { "doc": "D5.4 Governance Arrangements (final)", "date": "2026-05-29", "doi": "10.48481/rifs.2026.011" },
  "scales": {
    "agree7": { "codes": ["completely_agree", "agree", "neither", "disagree", "completely_disagree", "dont_know", "prefer_not"],
                "points": [2, 1, 0, -1, -2, null, null] },
    "yes_no": { "codes": ["yes", "no"], "points": [1, -1] },
    "yes_no_sometimes": { "codes": ["yes", "sometimes", "no"], "points": [1, 0, -1] },
    "extent5": { "codes": ["very_little", "occasionally", "neutral", "regularly", "very_much"], "points": [-2, -1, 0, 1, 2] },
    "rank5": { "codes": ["1", "2", "3", "4", "5"], "points": null }
  },
  "roles": ["government", "manager", "researcher", "tourism_operator", "fishers", "civil_society", "industry", "general_public", "other", "prefer_not"],
  "items": [
    { "id": "q3", "kind": "state", "dimension": "collaboration", "scale": "yes_no", "reverse": false,
      "text_en": "Do you collaborate with other stakeholders?", "source_ref": "D5.4 Annex 5 Q3, p. 139", "annex7_ref": "Q5" },
    { "id": "q4", "kind": "state", "dimension": "collaboration", "scale": "extent5", "reverse": false,
      "text_en": "To what extent do you collaborate with other stakeholders?", "source_ref": "D5.4 Annex 5 Q4, p. 140", "annex7_ref": "Q6" },
    { "id": "q5", "kind": "attitude", "dimension": "collaboration", "scale": "agree7", "reverse": false,
      "text_en": "I think collaboration with other stakeholders is important to achieve management and conservation goals", "source_ref": "D5.4 Annex 5 Q5, p. 140", "annex7_ref": "Q7" },
    { "id": "q6", "kind": "state", "dimension": "values_conflict", "scale": "agree7", "reverse": false,
      "text_en": "I trust the stakeholders engaged in decision-making, management, and conservation.", "source_ref": "D5.4 Annex 5 Q6, p. 140", "annex7_ref": "Q9" },
    { "id": "q7", "kind": "attitude", "dimension": "values_conflict", "scale": "agree7", "reverse": false,
      "text_en": "I think trust in other stakeholders is important to achieve management, and conservation goals.", "source_ref": "D5.4 Annex 5 Q7, p. 140", "annex7_ref": "Q11" },
    { "id": "q8", "kind": "attitude", "dimension": "legitimacy_equity", "scale": "agree7", "reverse": false,
      "text_en": "Stakeholders should have a voice in decision-making, management, and conservation.", "source_ref": "D5.4 Annex 5 Q8, p. 140", "annex7_ref": "Q13" },
    { "id": "q9", "kind": "attitude", "dimension": "legitimacy_equity", "scale": "agree7", "reverse": false,
      "text_en": "I think that all stakeholders should have an equal opportunity to contribute to decision making, management and conservation.", "source_ref": "D5.4 Annex 5 Q9, p. 141", "annex7_ref": "Q15" },
    { "id": "q10", "kind": "state", "dimension": "legitimacy_equity", "scale": "agree7", "reverse": true,
      "text_en": "Some stakeholders are more powerful than others in influencing decision making, management and conservation.", "source_ref": "D5.4 Annex 5 Q10, p. 141", "annex7_ref": "Q17" },
    { "id": "q13", "kind": "state", "dimension": "values_conflict", "scale": "yes_no", "reverse": true,
      "text_en": "Do conflicts between stakeholders or groups exist?", "source_ref": "D5.4 Annex 5 Q13, p. 141", "annex7_ref": "Q21" },
    { "id": "q15", "kind": "state", "dimension": "values_conflict", "scale": "yes_no", "reverse": false,
      "text_en": "Do opportunities to overcome conflicts between stakeholders exist?", "source_ref": "D5.4 Annex 5 Q15, p. 142", "annex7_ref": "Q24" },
    { "id": "q16", "kind": "state", "dimension": "values_conflict", "scale": "yes_no_sometimes", "reverse": false,
      "text_en": "Do stakeholders follow the rules for management and conservation?", "source_ref": "D5.4 Annex 5 Q16, p. 142", "annex7_ref": "Q26" },
    { "id": "q17", "kind": "state", "dimension": "values_conflict", "scale": "yes_no", "reverse": false,
      "text_en": "Do opportunities to ensure stakeholders follow the rules for management and conservation exist?", "source_ref": "D5.4 Annex 5 Q17, p. 142", "annex7_ref": "Q28" },
    { "id": "q18", "kind": "state", "dimension": "legitimacy_equity", "scale": "agree7", "reverse": false,
      "text_en": "All ‘appropriate’ stakeholders are included and consulted in decision making, management, and conservation processes.", "source_ref": "D5.4 Annex 5 Q18, p. 142", "annex7_ref": "Q30" },
    { "id": "q19", "kind": "state", "dimension": "knowledge", "scale": "agree7", "reverse": false,
      "text_en": "Decision making, management, and conservation activities are transparent for all stakeholders.", "source_ref": "D5.4 Annex 5 Q19, p. 142", "annex7_ref": "Q32" },
    { "id": "q35", "kind": "priority", "dimension": "values_conflict", "scale": "rank5", "reverse": false,
      "text_en": "Improving the mechanisms to solve conflicts between different stakeholders", "source_ref": "D5.4 Annex 7 Q35, p. 151", "annex7_ref": "Q35" },
    { "id": "q36", "kind": "priority", "dimension": "values_conflict", "scale": "rank5", "reverse": false,
      "text_en": "Improving trust among/between people and organisations", "source_ref": "D5.4 Annex 7 Q36, p. 151", "annex7_ref": "Q36" },
    { "id": "q37", "kind": "priority", "dimension": "legitimacy_equity", "scale": "rank5", "reverse": false,
      "text_en": "Improving representation and inclusivity of people/organisations (in decision-making processes)", "source_ref": "D5.4 Annex 7 Q37, p. 151", "annex7_ref": "Q37" },
    { "id": "q38", "kind": "priority", "dimension": "cross_sectoral", "scale": "rank5", "reverse": false,
      "text_en": "Improving integration between different sectors (cross-sectoral approaches)", "source_ref": "D5.4 Annex 7 Q38, p. 151", "annex7_ref": "Q38" },
    { "id": "q39", "kind": "priority", "dimension": null, "scale": "rank5", "reverse": false,
      "text_en": "Strengthening organisational capacities including through more access to financial resources, equipment, people and infrastructure", "source_ref": "D5.4 Annex 7 Q39, p. 151", "annex7_ref": "Q39" }
  ]
}
```

- [ ] **Step 5: Pin LF** — append `data/wp5_readiness_items.json text eol=lf` to the app `.gitattributes`.

- [ ] **Step 6: Run until green** — pytest (21 passed, or 1 + skips without sources) and `'^wp5-readiness-items$'` → 0 failures. A failing text is a transcription error: fix the data from the PDF, never the test.

- [ ] **Step 7: Commit** `data/wp5_readiness_items.json`, `scripts/tests/test_wp5_readiness_items.py`, `tests/testthat/test-wp5-readiness-items.R`, `.gitattributes` — `feat(wp5): D5.4 readiness item bank, verified against the deliverable (WS-9b)`.

---

### Task 2: Storage and scoring (pure R)

**Files:** Modify `constants.R` (after `WP5_GOVERNANCE_MIN_APP_VERSION`, ~line 957), `functions/data_structure.R` (`create_empty_project()` pims list ~line 181; `normalize_json_project_data()` after the WS-9a stakeholder hook ~line 1010), `global.R` (after `source("functions/wp5_governance.R", local = FALSE)`); create `functions/wp5_readiness.R`, `tests/testthat/test-wp5-readiness.R`.

**Interfaces — Produces:** `WP5_READINESS_MIN_APP_VERSION`, `READINESS_ID_PREFIX`, `READINESS_META_COLUMNS`; `load_wp5_readiness_items(path = NULL, force_reload = FALSE)`; `readiness_item_ids(bank)`; `readiness_item(bank, id)`; `readiness_scale_codes(bank, scale)`; `normalize_readiness(readiness, bank)` → `list(version, respondents)`; `readiness_points(bank, id, codes)` → numeric; `readiness_score(respondents, bank)` → data.frame(dimension, score, n_respondents, n_answers, n_items, coverage); `readiness_item_counts(respondents, bank, kind)` → data.frame(item, code, n); `readiness_priority(respondents, bank)` → data.frame(item, mean_rank, n); `readiness_role_breakdown(respondents, bank, min_n = 5L)` → data.frame or NULL; `readiness_append(readiness, rows, source, bank)`; `readiness_delete(readiness, ids, bank)`; `readiness_has_respondents(readiness)`.

- [ ] **Step 1: Write the failing tests** `tests/testthat/test-wp5-readiness.R`:

```r
# tests/testthat/test-wp5-readiness.R
# WS-9b (spec 2026-10-17 §4-§5): storage, scoring, import/export of the readiness check.
library(testthat)
source_for_test("functions/wp5_readiness.R")
bank <- load_wp5_readiness_items(force_reload = TRUE)
ids <- readiness_item_ids(bank)
rows_of <- function(...) {                       # build answer rows: rows_of(list(q6 = "agree"), list(q6 = "disagree"))
  rs <- list(...)
  as.data.frame(do.call(rbind, lapply(rs, function(r) {
    full <- stats::setNames(as.list(rep("", length(ids) + 1)), c("Role", ids))
    full[names(r)] <- r
    full
  })), stringsAsFactors = FALSE)
}
fix <- function(df) { for (cl in names(df)) df[[cl]] <- as.character(unlist(df[[cl]])); df }

test_that("normalize: NULL, list rows from JSON, bad codes blanked, unknown item columns kept (review focus 3)", {
  e <- normalize_readiness(NULL, bank)
  expect_equal(nrow(e$respondents), 0L)
  expect_equal(names(e$respondents), c(READINESS_META_COLUMNS, ids))
  rd <- normalize_readiness(list(respondents = list(list(RespondentId = "R001", q6 = "agree", q4 = "bogus",
                                                         q99 = "yes", Role = "fishers"))), bank)
  r <- rd$respondents
  expect_equal(c(r$q6, r$q4, r$q99, r$Role), c("agree", "", "yes", "fishers"))
  expect_false("q99" %in% names(readiness_score(r, bank)))          # not scored (only dimensions returned)
})

test_that("points: scales, reverse, exclusions (D6)", {
  expect_equal(readiness_points(bank, "q6", c("completely_agree", "neither", "dont_know", "")), c(2, 0, NA, NA))
  expect_equal(readiness_points(bank, "q10", c("completely_agree", "disagree")), c(-2, 1))     # reversed
  expect_equal(readiness_points(bank, "q13", c("yes", "no")), c(-1, 1))                       # reversed yes/no
  expect_equal(readiness_points(bank, "q16", c("yes", "sometimes", "no")), c(1, 0, -1))
  expect_equal(readiness_points(bank, "q4", c("very_little", "very_much")), c(-2, 2))
})

test_that("score: state items only, coverage flags, counts", {
  r <- fix(rows_of(list(q6 = "completely_agree", q13 = "yes", q5 = "completely_disagree", q19 = "agree"),
                   list(q6 = "agree", q15 = "yes")))
  sc <- readiness_score(r, bank)
  expect_equal(sc$dimension, NPG_DIMENSIONS)
  vc <- sc[sc$dimension == "values_conflict", ]
  expect_equal(vc$score, mean(c(2, -1, 1, 1)))                  # q6 2, q13 yes -> -1, q6 1, q15 1; q5 (attitude) ignored
  expect_equal(c(vc$n_respondents, vc$n_answers, vc$n_items), c(2L, 4L, 5L))
  expect_equal(sc$coverage[sc$dimension == "cross_sectoral"], "none")
  expect_true(is.na(sc$score[sc$dimension == "cross_sectoral"]))
  expect_equal(sc$coverage[sc$dimension == "knowledge"], "low")
  expect_equal(sc$score[sc$dimension == "knowledge"], 1)
  expect_equal(sc$coverage[sc$dimension == "collaboration"], "ok")
})

test_that("a dimension answered only with don't know gives NA, not NaN (review focus 5)", {
  sc <- readiness_score(fix(rows_of(list(q19 = "dont_know"), list(q19 = "prefer_not"))), bank)
  k <- sc[sc$dimension == "knowledge", ]
  expect_true(is.na(k$score) && !is.nan(k$score))
  expect_equal(k$n_answers, 0L)
})

test_that("item counts, priority mean rank, role breakdown threshold", {
  r <- fix(rows_of(list(q5 = "agree", q35 = "1", q39 = "5"), list(q5 = "agree", q35 = "3")))
  ct <- readiness_item_counts(r, bank, "attitude")
  expect_equal(ct$n[ct$item == "q5" & ct$code == "agree"], 2L)
  pr <- readiness_priority(r, bank)
  expect_equal(pr$mean_rank[pr$item == "q35"], 2)
  expect_equal(pr$n[pr$item == "q39"], 1L)
  four <- fix(do.call(rows_of, rep(list(list(Role = "fishers", q6 = "agree")), 4)))
  expect_null(readiness_role_breakdown(four, bank))
  five <- fix(do.call(rows_of, rep(list(list(Role = "fishers", q6 = "agree")), 5)))
  rb <- readiness_role_breakdown(five, bank)
  expect_equal(unique(rb$role), "fishers")
})

test_that("append assigns R001.. and safe ids; delete leaves an empty table (review focus 4)", {
  rd <- readiness_append(NULL, fix(rows_of(list(q6 = "agree"))), "form", bank)
  rd <- readiness_append(rd, fix(rows_of(list(q6 = "disagree"), list(q19 = "agree"))), "import", bank)
  expect_equal(rd$respondents$RespondentId, c("R001", "R002", "R003"))
  expect_equal(rd$respondents$Source, c("form", "import", "import"))
  expect_true(readiness_has_respondents(rd))
  rd2 <- readiness_delete(rd, c("R002"), bank)
  rd3 <- readiness_append(rd2, fix(rows_of(list(q6 = "agree"))), "form", bank)
  expect_equal(rd3$respondents$RespondentId, c("R001", "R003", "R004"))
  empty <- readiness_delete(rd, rd$respondents$RespondentId, bank)
  expect_true(is.data.frame(empty$respondents))
  expect_equal(nrow(empty$respondents), 0L)
  expect_false(readiness_has_respondents(empty))
})

test_that("empty project and JSON load: empty table; respondents stamp 1.31.0", {
  p <- create_empty_project("t")
  expect_equal(nrow(p$data$pims$readiness$respondents), 0L)
  pd <- list(data = list(pims = list(readiness = list(respondents = list(list(RespondentId = "R001", q6 = "agree"))))))
  out <- normalize_json_project_data(pd)
  expect_equal(out$data$pims$readiness$respondents$q6, "agree")
  expect_equal(out$min_app_version, WP5_READINESS_MIN_APP_VERSION)
  none <- normalize_json_project_data(list(data = list(pims = list(readiness = list(respondents = list())))))
  expect_null(none$min_app_version)
})

test_that("a missing or corrupt item bank gives NULL", {
  expect_null(load_wp5_readiness_items(path = tempfile(fileext = ".json")))
  bad <- tempfile(fileext = ".json"); writeLines("{ nope", bad)
  expect_null(load_wp5_readiness_items(path = bad))
  expect_false(is.null(load_wp5_readiness_items()))
})
```

- [ ] **Step 2: Run to verify it fails** — `'^wp5-readiness$'`.

- [ ] **Step 3: Constants** (`constants.R`, after `WP5_GOVERNANCE_MIN_APP_VERSION`):

```r
# ============================================================================
# WP5 GOVERNANCE-READINESS CHECK (spec 2026-10-17 WS-9b, D5.4 questionnaire)
# ============================================================================
READINESS_ID_PREFIX <- "R"            # anonymous respondent ids R001..
READINESS_META_COLUMNS <- c("RespondentId", "EnteredAt", "Source", "Role")
# data$pims$readiness is new in 1.31.0; stamped whenever a project has a respondent
WP5_READINESS_MIN_APP_VERSION <- "1.31.0"
```

- [ ] **Step 4: Create `functions/wp5_readiness.R`** (Task 4 appends the import/export functions to this file):

```r
# functions/wp5_readiness.R
# =============================================================================
# WP5 WS-9b (spec 2026-10-17): D5.4 governance-readiness check. Item bank
# loader, anonymous answer storage (data$pims$readiness) and the toolbox
# indicator per NPG dimension. Pure functions; the module is a thin shell.
# The indicator is a toolbox construct, not a WP5 score (D5.4 has no index).
# =============================================================================

.wp5_ready_env <- new.env(parent = emptyenv())

#' D5.4 readiness item bank, or NULL. Only default-path loads are cached.
load_wp5_readiness_items <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_ready_env$bank)) return(.wp5_ready_env$bank)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_readiness_items.json")
            else file.path("data", "wp5_readiness_items.json")
  }
  db <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) debug_log(sprintf("WP5 readiness: could not load %s", path), "WP5")
  if (default) .wp5_ready_env$bank <- db
  db
}

readiness_item_ids <- function(bank) vapply(bank$items, `[[`, "", "id")
readiness_item <- function(bank, id) Find(function(it) identical(it$id, id), bank$items)
readiness_scale_codes <- function(bank, scale) as.character(unlist(bank$scales[[scale]]$codes))

#' Normalise data$pims$readiness: NULL, list(respondents = data.frame) or JSON list rows.
#' Unknown answer codes become ""; unknown item columns are kept (future item banks).
normalize_readiness <- function(readiness, bank) {
  resp <- if (is.list(readiness)) readiness$respondents else NULL
  if (is.list(resp) && !is.data.frame(resp)) {
    rows <- Filter(is.list, resp)
    resp <- if (!length(rows)) NULL else {
      keys <- unique(unlist(lapply(rows, names)))
      as.data.frame(stats::setNames(lapply(keys, function(k) vapply(rows, function(r) {
        v <- r[[k]]
        if (is.null(v) || length(v) == 0 || all(is.na(unlist(v)))) "" else as.character(unlist(v))[1]
      }, character(1))), keys), stringsAsFactors = FALSE)
    }
  }
  if (!is.data.frame(resp)) resp <- data.frame()
  ids <- if (is.null(bank)) character(0) else readiness_item_ids(bank)
  cols <- union(c(READINESS_META_COLUMNS, ids), names(resp))
  n <- nrow(resp)
  out <- lapply(cols, function(cl) {
    v <- if (cl %in% names(resp)) as.character(resp[[cl]]) else rep("", n)
    v[is.na(v)] <- ""
    v
  })
  out <- as.data.frame(stats::setNames(out, cols), stringsAsFactors = FALSE)
  if (!is.null(bank)) {
    for (id in ids) out[[id]][!out[[id]] %in% readiness_scale_codes(bank, readiness_item(bank, id)$scale)] <- ""
    out$Role[!out$Role %in% unlist(bank$roles)] <- ""
  }
  list(version = "1.0", respondents = out)
}

readiness_has_respondents <- function(readiness) {
  r <- if (is.list(readiness)) readiness$respondents else NULL
  is.data.frame(r) && nrow(r) > 0
}

#' Points of answer codes for one item (NA = not scorable); reverse flips the sign
readiness_points <- function(bank, id, codes) {
  it <- readiness_item(bank, id)
  sc <- bank$scales[[it$scale]]
  pts <- vapply(sc$points %||% list(), function(p) if (is.null(p)) NA_real_ else as.numeric(p), numeric(1))
  if (!length(pts)) return(rep(NA_real_, length(codes)))
  v <- pts[match(as.character(codes), as.character(unlist(sc$codes)))]
  if (isTRUE(it$reverse)) -v else v
}

#' Toolbox indicator per NPG dimension (state items only)
readiness_score <- function(respondents, bank) {
  n <- if (is.data.frame(respondents)) nrow(respondents) else 0L
  state <- Filter(function(it) identical(it$kind, "state"), bank$items)
  do.call(rbind, lapply(NPG_DIMENSIONS, function(d) {
    its <- Filter(function(it) identical(it$dimension, d), state)
    m <- if (length(its) && n > 0) {
      matrix(vapply(its, function(it) readiness_points(bank, it$id, respondents[[it$id]] %||% rep("", n)),
                    numeric(n)), nrow = n)
    } else matrix(numeric(0), nrow = n, ncol = 0)
    n_ans <- sum(!is.na(m))
    data.frame(dimension = d,
               score = if (n_ans > 0) mean(m, na.rm = TRUE) else NA_real_,
               n_respondents = as.integer(sum(rowSums(!is.na(m)) > 0)),
               n_answers = as.integer(n_ans), n_items = length(its),
               coverage = if (length(its) == 0) "none" else if (length(its) == 1) "low" else "ok",
               stringsAsFactors = FALSE)
  }))
}

#' Answer-code counts per item of one kind ("state", "attitude")
readiness_item_counts <- function(respondents, bank, kind) {
  its <- Filter(function(it) identical(it$kind, kind), bank$items)
  rows <- lapply(its, function(it) {
    codes <- readiness_scale_codes(bank, it$scale)
    v <- as.character(respondents[[it$id]] %||% character(0))
    data.frame(item = it$id, code = codes, n = vapply(codes, function(cd) sum(v == cd), integer(1)),
               stringsAsFactors = FALSE, row.names = NULL)
  })
  if (!length(rows)) return(data.frame(item = character(), code = character(), n = integer()))
  do.call(rbind, rows)
}

#' Annex 7 priority areas: mean rank (1 = most important) and number of ranks
readiness_priority <- function(respondents, bank) {
  its <- Filter(function(it) identical(it$kind, "priority"), bank$items)
  do.call(rbind, lapply(its, function(it) {
    r <- suppressWarnings(as.numeric(respondents[[it$id]] %||% character(0)))
    r <- r[!is.na(r)]
    data.frame(item = it$id, mean_rank = if (length(r)) mean(r) else NA_real_, n = length(r), stringsAsFactors = FALSE)
  }))
}

#' Per-role indicator, only for roles with at least min_n respondents (anonymity)
readiness_role_breakdown <- function(respondents, bank, min_n = 5L) {
  roles <- setdiff(unique(as.character(respondents$Role)), "")
  out <- Filter(Negate(is.null), lapply(roles, function(r) {
    sub <- respondents[respondents$Role == r, , drop = FALSE]
    if (nrow(sub) < min_n) return(NULL)
    cbind(role = r, readiness_score(sub, bank), stringsAsFactors = FALSE)
  }))
  if (!length(out)) NULL else do.call(rbind, out)
}

#' Append respondents (rows: data.frame of Role + item answer codes)
readiness_append <- function(readiness, rows, source, bank) {
  rd <- normalize_readiness(readiness, bank)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(rd)
  start <- safe_counter(0, rd$respondents$RespondentId, READINESS_ID_PREFIX)
  rows$RespondentId <- vapply(seq_len(nrow(rows)), function(i) next_element_id(READINESS_ID_PREFIX, start + i), character(1))
  rows$EnteredAt <- as.character(Sys.Date())
  rows$Source <- source
  new <- normalize_readiness(list(respondents = rows), bank)$respondents
  cols <- union(names(rd$respondents), names(new))
  fill <- function(df) {
    for (cl in setdiff(cols, names(df))) df[[cl]] <- rep("", nrow(df))
    df[, cols, drop = FALSE]
  }
  rd$respondents <- rbind(fill(rd$respondents), fill(new))
  rd
}

readiness_delete <- function(readiness, ids, bank) {
  rd <- normalize_readiness(readiness, bank)
  rd$respondents <- rd$respondents[!rd$respondents$RespondentId %in% ids, , drop = FALSE]
  rownames(rd$respondents) <- NULL
  rd
}
```

- [ ] **Step 5: Wire storage.**
  - `functions/data_structure.R`, `create_empty_project()`: inside `pims = list(` add, after the `stakeholders = data.frame(...)` entry, `readiness = list(version = "1.0", respondents = data.frame(RespondentId = character(), EnteredAt = character(), Source = character(), Role = character(), stringsAsFactors = FALSE)),`.
  - `normalize_json_project_data()`, directly after the WS-9a stakeholder block:

```r
  # PIMS readiness answers: WS-9b schema on every JSON load path; respondents need 1.31.0
  if (is.list(data$data) && is.list(data$data$pims) && !is.null(data$data$pims$readiness) &&
      exists("normalize_readiness", mode = "function")) {
    bank <- if (exists("load_wp5_readiness_items", mode = "function")) load_wp5_readiness_items() else NULL
    data$data$pims$readiness <- normalize_readiness(data$data$pims$readiness, bank)
    if (readiness_has_respondents(data$data$pims$readiness) && exists("stamp_min_app_version", mode = "function") &&
        exists("WP5_READINESS_MIN_APP_VERSION")) {
      data <- stamp_min_app_version(data, WP5_READINESS_MIN_APP_VERSION)
    }
  }
```

  - `global.R`, after `source("functions/wp5_governance.R", local = FALSE)`: `source("functions/wp5_readiness.R", local = FALSE)        # WS-9b: D5.4 governance-readiness check`.

- [ ] **Step 6: Run tests** — `'^wp5-readiness$'`, `'^wp5-readiness-items$'`, `'^functions-sourced-in-app$'`, `'^json-project-loading$'`, `'^data-structure'` → 0 failures.

- [ ] **Step 7: Commit** — `feat(wp5): readiness answer storage and toolbox indicator (WS-9b)`.

---

### Task 3: Translations

**Files:** Create `translations/modules/wp5_readiness.json` (shape of `translations/modules/wp5_governance.json`); modify `translations/ui/sidebar.json`.

**Interfaces:** Produces every key below in 9 languages. English verbatim. The 19 `item.*` English values must equal the item bank's `text_en` exactly. Translations of item texts must keep the meaning of a survey question (they are read by respondents); reuse the terms of `wp5_governance.json` and `wp5_vocabulary.json`; keep D5.4, WP5, NPG, EBM unchanged.

`ui.sidebar.governance_readiness` (sidebar.json): en "Governance readiness (D5.4)".

`modules.wp5_readiness.*`:

| key | en |
|---|---|
| `title` | Governance readiness check (D5.4) |
| `subtitle` | Anonymous answers to the D5.4 stakeholder questionnaire, summarised by governance dimension. |
| `tab_add` | Add respondent |
| `tab_import` | Import |
| `tab_results` | Results |
| `consent_title` | Before you start |
| `consent_text` | Taking part is optional and anonymous. No name, contact details or written explanations are recorded; only the selected answers are kept, in this project file. Respondents should have been invited following the project's own consent procedure. |
| `consent_check` | The respondent has agreed to take part |
| `consent_required` | Please confirm that the respondent has agreed before saving. |
| `nothing_to_save` | No answer was given, so nothing was saved. |
| `role` | How does the respondent self-identify? (optional) |
| `translation_note` | Questions translated by the toolbox; the D5.4 questionnaire wording is English. |
| `source` | Source |
| `section_priority` | Priority areas for improvement (rank 1 = most important) |
| `save` | Save respondent |
| `saved_as` | Saved as respondent |
| `no_project` | Open or create a project first. |
| `unavailable` | The readiness questionnaire items are not available. |
| `template_download` | Download template |
| `template_help` | One row per respondent, one column per question. Fill in the answer codes or labels listed on the "items" sheet; leave a cell empty to skip a question. |
| `upload` | Upload filled template (xlsx or csv) |
| `import_rows` | Respondents to add: |
| `import_blanked` | unreadable answers left empty: |
| `import_ignored` | columns ignored: |
| `import_dropped` | empty rows skipped: |
| `import_add` | Add respondents: |
| `import_added` | Respondents added: |
| `import_error.too_many_rows` | The file has more than 1000 rows. |
| `import_error.no_item_columns` | No question columns were found. Expected columns: |
| `context_import` | Importing the readiness answers |
| `n_respondents` | Respondents |
| `source.form` | entered |
| `source.import` | imported |
| `indicator_label` | Toolbox indicator, not a WP5 score: the mean of the current-state answers from −2 (unfavourable) to +2 (favourable). D5.4 used this questionnaire descriptively. |
| `coverage_none` | The D5.4 questionnaire has no question on this dimension. |
| `coverage_low` | Based on one question only. |
| `no_answers` | No answers yet |
| `no_respondents` | No respondents yet. |
| `answers_n` | answers |
| `items_title` | Current-state questions |
| `attitudes_title` | Views on what should be (not scored) |
| `priorities_title` | Priority areas for improvement |
| `rank_note` | Mean rank; 1 = most important. |
| `mean_rank` | Mean rank |
| `mean_points` | Mean |
| `roles_title` | By self-identified role |
| `roles_hidden` | Shown only for roles with at least 5 respondents, to keep answers anonymous. |
| `respondents_title` | Respondents |
| `col_respondent` | Respondent |
| `col_role` | Role |
| `col_date` | Date |
| `col_source` | Source |
| `delete_selected` | Delete selected |
| `deleted` | Respondents deleted: |
| `export` | Export answers and summary (xlsx) |
| `answer.completely_agree` | Completely agree |
| `answer.agree` | Agree |
| `answer.neither` | Do not agree or disagree |
| `answer.disagree` | Disagree |
| `answer.completely_disagree` | Completely disagree |
| `answer.dont_know` | I don't know |
| `answer.prefer_not` | Prefer not to answer |
| `answer.yes` | Yes |
| `answer.no` | No |
| `answer.sometimes` | Sometimes |
| `answer.very_little` | Very little |
| `answer.occasionally` | Occasionally |
| `answer.neutral` | Neutral |
| `answer.regularly` | Regularly |
| `answer.very_much` | Very much |
| `role.government` | Government representative |
| `role.manager` | Manager |
| `role.researcher` | Researcher |
| `role.tourism_operator` | Tourism operator |
| `role.fishers` | Fishers |
| `role.civil_society` | Civil society representatives |
| `role.industry` | Industry representative |
| `role.general_public` | General public |
| `role.other` | Other |
| `role.prefer_not` | Prefer not to answer |
| `item.q3` … `item.q39` | the 19 `text_en` values of `data/wp5_readiness_items.json`, verbatim |

- [ ] **Step 1: Generate** both files with a Python script FILE in `C:/Users/arturas.baziukas/wt-ws9b/.superpowers/` (load `data/wp5_readiness_items.json` for the `item.*` English values; `json.dump(ensure_ascii=False, indent=2)` + newline, UTF-8, LF). For `sidebar.json` insert the one new key textually so existing lines are untouched (`git diff --stat` shows additions only).
- [ ] **Step 2: Check** — both parse; every `item.<id>` `en` equals the bank's `text_en`; `'^i18n-enforcement$'`, `'^i18n-duplicate-keys$'` → 0 failures; audit Totals `missing=0 hardcoded=0`.
- [ ] **Step 3: Commit** — `i18n(wp5): WS-9b readiness questionnaire and UI keys (9 languages)`.

---

### Task 4: Import, template and export (pure R)

**Files:** Modify `functions/wp5_readiness.R` (append); test `tests/testthat/test-wp5-readiness.R` (append).

**Interfaces:**
- Consumes: Task 2 functions; Task 3 file `translations/modules/wp5_readiness.json`.
- Produces: `readiness_translations(path = NULL)` → named list key → list(lang → text); `readiness_value_map(codes, key_prefix, tr)` → named chr (normalised label → code, ambiguous → NA); `readiness_parse_import(df, bank, tr = readiness_translations())` → `list(ok, rows, blanked, ignored, dropped_empty)` or `list(ok = FALSE, error, expected)`; `readiness_read_file(path, name = path)` → data.frame; `readiness_template_wb(bank, i18n)`, `readiness_export_wb(readiness, bank, i18n)` → openxlsx workbooks.

- [ ] **Step 1: Append failing tests** to `tests/testthat/test-wp5-readiness.R`:

```r
# ---- Task 4: import / template / export --------------------------------------
tr <- readiness_translations()

test_that("import: codes and labels in any language; bad values blanked; other columns ignored", {
  es_agree <- tr[["modules.wp5_readiness.answer.agree"]]$es
  lt_fishers <- tr[["modules.wp5_readiness.role.fishers"]]$lt
  df <- data.frame(Name = c("Ana", "Bo"), role = c(lt_fishers, "manager"), q6 = c("agree", toupper(es_agree)),
                   q16 = c("Sometimes", "maybe"), q35 = c(1, 2), Comment = c("x", "y"), stringsAsFactors = FALSE)
  p <- readiness_parse_import(df, bank, tr)
  expect_true(p$ok)
  expect_equal(p$rows$Role, c("fishers", "manager"))
  expect_equal(p$rows$q6, c("agree", "agree"))
  expect_equal(p$rows$q16, c("sometimes", ""))
  expect_equal(p$rows$q35, c("1", "2"))
  expect_equal(p$blanked, 1L)
  expect_setequal(p$ignored, c("name", "comment"))
  expect_false(any(c("name", "comment", "Name") %in% names(p$rows)))
})

test_that("import: a label meaning different codes in different languages is unreadable", {
  fake <- list("modules.wp5_readiness.answer.yes" = list(en = "Yes", xx = "Si"),
               "modules.wp5_readiness.answer.no" = list(en = "No", yy = "Si"))
  p <- readiness_parse_import(data.frame(q3 = c("si", "yes"), stringsAsFactors = FALSE), bank, fake)
  expect_equal(p$rows$q3, c("", "yes"))
  expect_equal(p$blanked, 1L)
})

test_that("import: all-blank file adds nothing (review focus 2); no item columns and too many rows refused", {
  p <- readiness_parse_import(data.frame(q6 = c("", NA), role = c(NA, ""), stringsAsFactors = FALSE), bank, tr)
  expect_true(p$ok)
  expect_equal(nrow(p$rows), 0L)
  expect_equal(p$dropped_empty, 2L)
  e <- readiness_parse_import(data.frame(name = "x"), bank, tr)
  expect_false(e$ok); expect_equal(e$error, "no_item_columns"); expect_true("q6" %in% e$expected)
  big <- data.frame(q6 = rep("agree", 1001), stringsAsFactors = FALSE)
  expect_equal(readiness_parse_import(big, bank, tr)$error, "too_many_rows")
})

test_that("template round trip: download, fill, read back, parse", {
  wb <- readiness_template_wb(bank, make_test_i18n())
  expect_equal(openxlsx::sheets(wb), c("answers", "items", "roles"))
  row <- stats::setNames(as.list(rep("", length(ids) + 1)), c("role", ids))   # same column order as the header
  row[c("role", "q6", "q19")] <- list("researcher", "completely_agree", "Disagree")
  openxlsx::writeData(wb, "answers", as.data.frame(row, stringsAsFactors = FALSE), startRow = 2, colNames = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  df <- readiness_read_file(f, "filled.xlsx")
  p <- readiness_parse_import(df, bank, tr)
  expect_equal(nrow(p$rows), 1L)
  expect_equal(c(p$rows$Role, p$rows$q6), c("researcher", "completely_agree"))
  csv <- tempfile(fileext = ".csv"); utils::write.csv(data.frame(q6 = "agree"), csv, row.names = FALSE)
  expect_equal(readiness_read_file(csv, "a.csv")$q6, "agree")
  expect_error(readiness_read_file(csv, "a.txt"))
})

test_that("export workbook has answers, indicator and priorities", {
  rd <- readiness_append(NULL, fix(rows_of(list(q6 = "agree", q35 = "2"))), "form", bank)
  wb <- readiness_export_wb(rd, bank, make_test_i18n())
  expect_equal(openxlsx::sheets(wb), c("about", "answers", "indicator", "priorities"))
})
```

Note: `readiness_parse_import()` lower-cases header names, so the first test's `Name` and `Comment` columns are reported as ignored columns `name` and `comment`.

- [ ] **Step 2: Run to verify they fail** — `'^wp5-readiness$'`.

- [ ] **Step 3: Append to `functions/wp5_readiness.R`:**

```r
# ---- Import / template / export (WS-9b Task 4) --------------------------------

.ready_key <- function(x) gsub("\\s+", " ", trimws(tolower(as.character(x))))

#' The readiness translation table: key -> list(lang -> text)
readiness_translations <- function(path = NULL) {
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("translations", "modules", "wp5_readiness.json")
            else file.path("translations", "modules", "wp5_readiness.json")
  }
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE)$translation, error = function(e) list())
}

#' Label -> code map for one set of codes: the code itself and its label in every
#' language; a label that maps to two codes is ambiguous (NA)
readiness_value_map <- function(codes, key_prefix, tr) {
  pairs <- do.call(rbind, lapply(codes, function(cd) {
    labs <- c(cd, as.character(unlist(tr[[paste0(key_prefix, cd)]])))
    data.frame(lab = .ready_key(labs), code = cd, stringsAsFactors = FALSE)
  }))
  pairs <- unique(pairs[nzchar(pairs$lab), , drop = FALSE])
  n_codes <- tapply(pairs$code, pairs$lab, function(z) length(unique(z)))
  m <- stats::setNames(pairs$code, pairs$lab)
  m <- m[!duplicated(names(m))]
  m[names(m) %in% names(n_codes)[n_codes > 1]] <- NA_character_
  m
}

#' Parse an imported answers table. Only `role` and item-id columns are read.
readiness_parse_import <- function(df, bank, tr = readiness_translations()) {
  if (!is.data.frame(df)) df <- data.frame()
  names(df) <- .ready_key(names(df))
  ids <- readiness_item_ids(bank)
  if (nrow(df) > 1000) return(list(ok = FALSE, error = "too_many_rows", expected = NULL))
  if (!length(intersect(names(df), ids))) return(list(ok = FALSE, error = "no_item_columns", expected = ids))
  blanked <- 0L
  conv <- function(v, map) {
    k <- .ready_key(v); k[is.na(v)] <- ""
    res <- unname(map[k])
    bad <- nzchar(k) & is.na(res)
    res[is.na(res)] <- ""
    blanked <<- blanked + sum(bad)
    res
  }
  out <- data.frame(Role = rep("", nrow(df)), stringsAsFactors = FALSE)
  if ("role" %in% names(df)) out$Role <- conv(df$role, readiness_value_map(unlist(bank$roles), "modules.wp5_readiness.role.", tr))
  for (id in ids) {
    out[[id]] <- if (id %in% names(df)) {
      conv(df[[id]], readiness_value_map(readiness_scale_codes(bank, readiness_item(bank, id)$scale),
                                         "modules.wp5_readiness.answer.", tr))
    } else rep("", nrow(df))
  }
  keep <- if (nrow(out)) (rowSums(out[, ids, drop = FALSE] != "") > 0) | out$Role != "" else logical(0)
  list(ok = TRUE, rows = out[keep, , drop = FALSE], blanked = as.integer(blanked),
       ignored = setdiff(names(df), c("role", ids)), dropped_empty = as.integer(sum(!keep)))
}

#' Read an uploaded xlsx (sheet "answers" if present) or csv as character data
readiness_read_file <- function(path, name = path) {
  ext <- tolower(tools::file_ext(name))
  df <- if (ext == "xlsx") {
    sheets <- openxlsx::getSheetNames(path)
    openxlsx::read.xlsx(path, sheet = if ("answers" %in% sheets) "answers" else 1, colNames = TRUE, skipEmptyRows = TRUE)
  } else if (ext == "csv") {
    utils::read.csv(path, colClasses = "character", check.names = FALSE, encoding = "UTF-8", na.strings = c("", "NA"))
  } else stop("Unsupported file type: ", ext)
  if (is.null(df)) data.frame() else df
}

#' xlsx template: answers (header only), items (current language), roles
readiness_template_wb <- function(bank, i18n) {
  ids <- readiness_item_ids(bank)
  lab <- function(key) as.character(i18n$t(key))
  allowed <- function(it) {
    cds <- readiness_scale_codes(bank, it$scale)
    if (identical(it$scale, "rank5")) return(paste(cds, collapse = "; "))
    paste(paste0(cds, " = ", vapply(cds, function(cd) lab(paste0("modules.wp5_readiness.answer.", cd)), "")), collapse = "; ")
  }
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "answers")
  openxlsx::writeData(wb, "answers", as.data.frame(stats::setNames(rep(list(character(0)), length(ids) + 1), c("role", ids))))
  openxlsx::addWorksheet(wb, "items")
  openxlsx::writeData(wb, "items", data.frame(
    id = ids, question = vapply(ids, function(id) lab(paste0("modules.wp5_readiness.item.", id)), ""),
    allowed = vapply(bank$items, allowed, ""), stringsAsFactors = FALSE))
  roles <- unlist(bank$roles)
  openxlsx::addWorksheet(wb, "roles")
  openxlsx::writeData(wb, "roles", data.frame(code = roles,
    label = vapply(roles, function(r) lab(paste0("modules.wp5_readiness.role.", r)), ""), stringsAsFactors = FALSE))
  wb
}

#' xlsx export: about (indicator caveat), anonymous answers, indicator, priorities
readiness_export_wb <- function(readiness, bank, i18n) {
  rd <- normalize_readiness(readiness, bank)
  sc <- readiness_score(rd$respondents, bank)
  sc$label <- vapply(sc$dimension, function(d) wp5_vocab_label("npg", d, i18n), "")
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "about")
  openxlsx::writeData(wb, "about", data.frame(note = as.character(i18n$t("modules.wp5_readiness.indicator_label"))))
  openxlsx::addWorksheet(wb, "answers"); openxlsx::writeData(wb, "answers", rd$respondents)
  openxlsx::addWorksheet(wb, "indicator"); openxlsx::writeData(wb, "indicator", sc)
  openxlsx::addWorksheet(wb, "priorities"); openxlsx::writeData(wb, "priorities", readiness_priority(rd$respondents, bank))
  wb
}
```

- [ ] **Step 4: Run tests** — `'^wp5-readiness$'` → 0 failures.
- [ ] **Step 5: Commit** — `feat(wp5): readiness template import and xlsx export (WS-9b)`.

---

### Task 5: The PIMS page and its wiring

**Files:** Create `modules/wp5_readiness_module.R`, `tests/testthat/test-wp5-readiness-module.R`; modify `functions/ui_sidebar.R` (PIMS block ~line 229), `app.R` (`OPTIONAL_MODULES` after `"modules/pims_stakeholder_module.R",` ~line 99; PIMS tab items ~line 480; PIMS servers ~line 1020).

**Interfaces:** Consumes Tasks 2–4 and Task 3 keys. Produces `wp5_readiness_ui(id, i18n)`, `wp5_readiness_server(id, project_data_reactive, i18n, event_bus = NULL)`; inputs `consent`, `role`, `ans_<item id>`, `save`, `upload`, `import_confirm`, `respondent_table_rows_selected`, `delete_selected`; outputs `import_preview`, `results`, `respondent_table`, `template`, `export`.

- [ ] **Step 1: Write the failing tests** `tests/testthat/test-wp5-readiness-module.R`:

```r
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
```

- [ ] **Step 2: Run to verify they fail** — `'^wp5-readiness-module$'`.

- [ ] **Step 3: Create `modules/wp5_readiness_module.R`:**

```r
# modules/wp5_readiness_module.R
# =============================================================================
# WP5 WS-9b (spec 2026-10-17 §6): D5.4 governance-readiness check — a PIMS page
# to enter (form) or import (template) anonymous questionnaire answers and see
# the toolbox indicator per NPG dimension. Logic: functions/wp5_readiness.R.
# =============================================================================

# i18n-ref: modules.wp5_readiness.answer.completely_agree
# i18n-ref: modules.wp5_readiness.answer.agree
# i18n-ref: modules.wp5_readiness.answer.neither
# i18n-ref: modules.wp5_readiness.answer.disagree
# i18n-ref: modules.wp5_readiness.answer.completely_disagree
# i18n-ref: modules.wp5_readiness.answer.dont_know
# i18n-ref: modules.wp5_readiness.answer.prefer_not
# i18n-ref: modules.wp5_readiness.answer.yes
# i18n-ref: modules.wp5_readiness.answer.no
# i18n-ref: modules.wp5_readiness.answer.sometimes
# i18n-ref: modules.wp5_readiness.answer.very_little
# i18n-ref: modules.wp5_readiness.answer.occasionally
# i18n-ref: modules.wp5_readiness.answer.neutral
# i18n-ref: modules.wp5_readiness.answer.regularly
# i18n-ref: modules.wp5_readiness.answer.very_much
# i18n-ref: modules.wp5_readiness.role.government
# i18n-ref: modules.wp5_readiness.role.manager
# i18n-ref: modules.wp5_readiness.role.researcher
# i18n-ref: modules.wp5_readiness.role.tourism_operator
# i18n-ref: modules.wp5_readiness.role.fishers
# i18n-ref: modules.wp5_readiness.role.civil_society
# i18n-ref: modules.wp5_readiness.role.industry
# i18n-ref: modules.wp5_readiness.role.general_public
# i18n-ref: modules.wp5_readiness.role.other
# i18n-ref: modules.wp5_readiness.role.prefer_not
# i18n-ref: modules.wp5_readiness.item.q3
# i18n-ref: modules.wp5_readiness.item.q4
# i18n-ref: modules.wp5_readiness.item.q5
# i18n-ref: modules.wp5_readiness.item.q6
# i18n-ref: modules.wp5_readiness.item.q7
# i18n-ref: modules.wp5_readiness.item.q8
# i18n-ref: modules.wp5_readiness.item.q9
# i18n-ref: modules.wp5_readiness.item.q10
# i18n-ref: modules.wp5_readiness.item.q13
# i18n-ref: modules.wp5_readiness.item.q15
# i18n-ref: modules.wp5_readiness.item.q16
# i18n-ref: modules.wp5_readiness.item.q17
# i18n-ref: modules.wp5_readiness.item.q18
# i18n-ref: modules.wp5_readiness.item.q19
# i18n-ref: modules.wp5_readiness.item.q35
# i18n-ref: modules.wp5_readiness.item.q36
# i18n-ref: modules.wp5_readiness.item.q37
# i18n-ref: modules.wp5_readiness.item.q38
# i18n-ref: modules.wp5_readiness.item.q39
# i18n-ref: modules.wp5_readiness.source.form
# i18n-ref: modules.wp5_readiness.source.import
# i18n-ref: modules.wp5_readiness.import_error.too_many_rows
# i18n-ref: modules.wp5_readiness.import_error.no_item_columns
# i18n-ref: modules.wp5_readiness.title
# i18n-ref: modules.wp5_readiness.subtitle
# i18n-ref: modules.wp5_readiness.tab_add
# i18n-ref: modules.wp5_readiness.tab_import
# i18n-ref: modules.wp5_readiness.tab_results
# i18n-ref: modules.wp5_readiness.consent_title
# i18n-ref: modules.wp5_readiness.consent_text
# i18n-ref: modules.wp5_readiness.consent_check
# i18n-ref: modules.wp5_readiness.consent_required
# i18n-ref: modules.wp5_readiness.nothing_to_save
# i18n-ref: modules.wp5_readiness.role
# i18n-ref: modules.wp5_readiness.translation_note
# i18n-ref: modules.wp5_readiness.source
# i18n-ref: modules.wp5_readiness.section_priority
# i18n-ref: modules.wp5_readiness.save
# i18n-ref: modules.wp5_readiness.saved_as
# i18n-ref: modules.wp5_readiness.no_project
# i18n-ref: modules.wp5_readiness.unavailable
# i18n-ref: modules.wp5_readiness.template_download
# i18n-ref: modules.wp5_readiness.template_help
# i18n-ref: modules.wp5_readiness.upload
# i18n-ref: modules.wp5_readiness.import_rows
# i18n-ref: modules.wp5_readiness.import_blanked
# i18n-ref: modules.wp5_readiness.import_ignored
# i18n-ref: modules.wp5_readiness.import_dropped
# i18n-ref: modules.wp5_readiness.import_add
# i18n-ref: modules.wp5_readiness.import_added
# i18n-ref: modules.wp5_readiness.context_import
# i18n-ref: modules.wp5_readiness.n_respondents
# i18n-ref: modules.wp5_readiness.indicator_label
# i18n-ref: modules.wp5_readiness.coverage_none
# i18n-ref: modules.wp5_readiness.coverage_low
# i18n-ref: modules.wp5_readiness.no_answers
# i18n-ref: modules.wp5_readiness.no_respondents
# i18n-ref: modules.wp5_readiness.answers_n
# i18n-ref: modules.wp5_readiness.items_title
# i18n-ref: modules.wp5_readiness.attitudes_title
# i18n-ref: modules.wp5_readiness.priorities_title
# i18n-ref: modules.wp5_readiness.rank_note
# i18n-ref: modules.wp5_readiness.mean_rank
# i18n-ref: modules.wp5_readiness.mean_points
# i18n-ref: modules.wp5_readiness.roles_title
# i18n-ref: modules.wp5_readiness.roles_hidden
# i18n-ref: modules.wp5_readiness.respondents_title
# i18n-ref: modules.wp5_readiness.col_respondent
# i18n-ref: modules.wp5_readiness.col_role
# i18n-ref: modules.wp5_readiness.col_date
# i18n-ref: modules.wp5_readiness.col_source
# i18n-ref: modules.wp5_readiness.delete_selected
# i18n-ref: modules.wp5_readiness.deleted
# i18n-ref: modules.wp5_readiness.export

wp5_readiness_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_readiness.", k))
  bank <- load_wp5_readiness_items()
  item_input <- function(it) {
    codes <- readiness_scale_codes(bank, it$scale)
    labels <- if (identical(it$scale, "rank5")) codes else vapply(codes, function(cd) tr(paste0("answer.", cd)), character(1))
    div(class = "mb-3",
      radioButtons(ns(paste0("ans_", it$id)), tr(paste0("item.", it$id)),
                   choices = stats::setNames(codes, labels), selected = character(0), inline = TRUE),
      tags$small(class = "text-muted", tr("source"), ": ", it$source_ref))
  }
  form <- if (is.null(bank)) div(class = "alert alert-warning", tr("unavailable")) else tagList(
    selectInput(ns("role"), tr("role"), choices = c(stats::setNames("", ""), stats::setNames(unlist(bank$roles),
      vapply(unlist(bank$roles), function(r) tr(paste0("role.", r)), character(1))))),
    lapply(NPG_DIMENSIONS, function(d) {
      its <- Filter(function(it) identical(it$dimension, d) && it$kind %in% c("state", "attitude"), bank$items)
      if (!length(its)) return(NULL)
      tagList(h5(class = "mt-3", wp5_vocab_label("npg", d, i18n)), lapply(its, item_input))
    }),
    h5(class = "mt-3", tr("section_priority")),
    lapply(Filter(function(it) identical(it$kind, "priority"), bank$items), item_input),
    p(class = "small text-muted", tr("translation_note")),
    actionButton(ns("save"), tr("save"), icon = icon("save"), class = "btn-primary"))
  tagList(
    h3(tr("title")), p(class = "text-muted", tr("subtitle")),
    tabsetPanel(id = ns("tabs"),
      tabPanel(tr("tab_add"),
        div(class = "alert alert-info mt-3", strong(tr("consent_title")), p(tr("consent_text")),
            checkboxInput(ns("consent"), tr("consent_check"), value = FALSE)),
        conditionalPanel(condition = sprintf("input['%s'] == true", ns("consent")), form)),
      tabPanel(tr("tab_import"),
        div(class = "mt-3",
          downloadButton(ns("template"), tr("template_download")),
          p(class = "small text-muted mt-2", tr("template_help")),
          fileInput(ns("upload"), tr("upload"), accept = c(".xlsx", ".csv")),
          uiOutput(ns("import_preview")))),
      tabPanel(tr("tab_results"),
        div(class = "mt-3", uiOutput(ns("results")),
            h5(class = "mt-4", tr("respondents_title")), DT::DTOutput(ns("respondent_table")),
            actionButton(ns("delete_selected"), tr("delete_selected"), icon = icon("trash"), class = "btn-danger mt-2"),
            downloadButton(ns("export"), tr("export"), class = "mt-2 ml-2"))))
  )
}

wp5_readiness_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_readiness.", k))
    bank <- load_wp5_readiness_items()

    readiness <- reactive({
      pd <- project_data_reactive()
      if (is.null(pd) || is.null(bank)) return(NULL)
      normalize_readiness(pd$data$pims$readiness, bank)
    })
    write_readiness <- function(rd) {
      pd <- project_data_reactive()
      if (is.null(pd)) return(invisible(NULL))
      pd$data$pims$readiness <- rd
      if (readiness_has_respondents(rd)) pd <- stamp_min_app_version(pd, WP5_READINESS_MIN_APP_VERSION)
      project_data_reactive(pd)
    }

    # ---- Add respondent ----
    observeEvent(input$save, {
      req(!is.null(bank))
      if (is.null(project_data_reactive())) { showNotification(tr("no_project"), type = "warning"); return() }
      if (!isTRUE(input$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      ids <- readiness_item_ids(bank)
      answers <- vapply(ids, function(i) { v <- input[[paste0("ans_", i)]]; if (length(v)) as.character(v[1]) else "" },
                        character(1))
      role <- input$role %||% ""
      if (!any(nzchar(answers)) && !nzchar(role)) { showNotification(tr("nothing_to_save"), type = "warning"); return() }
      row <- as.data.frame(c(list(Role = role), as.list(answers)), stringsAsFactors = FALSE)
      rd <- readiness_append(readiness(), row, "form", bank)
      write_readiness(rd)
      for (i in ids) updateRadioButtons(session, paste0("ans_", i), selected = character(0))
      updateSelectInput(session, "role", selected = "")
      updateCheckboxInput(session, "consent", value = FALSE)
      showNotification(paste(tr("saved_as"), utils::tail(rd$respondents$RespondentId, 1)), type = "message")
    })

    # ---- Import ----
    parsed <- reactiveVal(NULL)
    output$template <- downloadHandler(
      filename = function() "governance_readiness_template.xlsx",
      content = function(file) openxlsx::saveWorkbook(readiness_template_wb(bank, i18n), file, overwrite = TRUE))
    observeEvent(input$upload, {
      f <- input$upload; req(f, !is.null(bank))
      res <- tryCatch(readiness_parse_import(readiness_read_file(f$datapath, f$name), bank), error = function(e) {
        debug_log(paste("WP5 readiness: import failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_readiness.context_import"),
                         type = "error")
        NULL
      })
      parsed(res)
    })
    output$import_preview <- renderUI({
      pr <- parsed()
      if (is.null(pr)) return(NULL)
      if (!isTRUE(pr$ok)) {
        return(div(class = "alert alert-warning", tr(paste0("import_error.", pr$error)), " ",
                   if (length(pr$expected)) tags$small(paste(pr$expected, collapse = ", "))))
      }
      tagList(
        p(tr("import_rows"), " ", nrow(pr$rows), " · ", tr("import_blanked"), " ", pr$blanked, " · ",
          tr("import_ignored"), " ", length(pr$ignored), " · ", tr("import_dropped"), " ", pr$dropped_empty),
        if (length(pr$ignored)) tags$small(class = "text-muted d-block", paste(pr$ignored, collapse = ", ")),
        if (nrow(pr$rows)) actionButton(ns("import_confirm"), paste(tr("import_add"), nrow(pr$rows)), class = "btn-primary"))
    })
    observeEvent(input$import_confirm, {
      pr <- parsed(); req(isTRUE(pr$ok), nrow(pr$rows) > 0, !is.null(project_data_reactive()))
      write_readiness(readiness_append(readiness(), pr$rows, "import", bank))
      parsed(NULL)
      showNotification(paste(tr("import_added"), nrow(pr$rows)), type = "message")
    })

    # ---- Results ----
    item_text <- function(id) tr(paste0("item.", id))
    dim_row <- function(s) {
      bar <- if (identical(s$coverage, "none")) {
        tags$small(class = "text-muted", tr("coverage_none"))
      } else if (is.na(s$score)) {
        tags$small(class = "text-muted", tr("no_answers"))
      } else {
        pct <- round((s$score + 2) / 4 * 100)
        tagList(
          div(class = "progress", style = "height: 18px;",
              div(class = paste("progress-bar", if (s$score >= 0) "bg-success" else "bg-danger"),
                  style = sprintf("width: %d%%;", pct), sprintf("%.2f", s$score))),
          tags$small(class = "text-muted", tr("n_respondents"), ": ", s$n_respondents, " · ", s$n_answers, " ",
                     tr("answers_n"), if (identical(s$coverage, "low")) tagList(" · ", tr("coverage_low"))))
      }
      div(class = "mb-2", strong(wp5_vocab_label("npg", s$dimension, i18n)), bar)
    }
    counts_table <- function(resp, kind) {
      ct <- readiness_item_counts(resp, bank, kind)
      its <- unique(ct$item)
      tags$table(class = "table table-sm small", tags$tbody(lapply(its, function(id) {
        sub <- ct[ct$item == id & ct$n > 0, , drop = FALSE]
        cells <- paste(vapply(seq_len(nrow(sub)), function(i)
          paste0(tr(paste0("answer.", sub$code[i])), ": ", sub$n[i]), character(1)), collapse = "; ")
        mean_pts <- if (identical(kind, "state")) {
          v <- readiness_points(bank, id, resp[[id]]); if (any(!is.na(v))) sprintf("%.2f", mean(v, na.rm = TRUE)) else ""
        } else ""
        tags$tr(tags$td(item_text(id)), tags$td(cells), if (identical(kind, "state")) tags$td(mean_pts))
      })))
    }
    output$results <- renderUI({
      if (is.null(bank)) return(div(class = "alert alert-warning", tr("unavailable")))
      rd <- readiness()
      if (is.null(rd)) return(div(class = "alert alert-light", tr("no_project")))
      resp <- rd$respondents
      if (!nrow(resp)) return(div(class = "alert alert-light", tr("no_respondents")))
      sc <- readiness_score(resp, bank)
      pr <- readiness_priority(resp, bank)
      rb <- readiness_role_breakdown(resp, bank)
      tagList(
        p(strong(tr("n_respondents")), ": ", nrow(resp), " (", tr("source.form"), " ", sum(resp$Source == "form"),
          ", ", tr("source.import"), " ", sum(resp$Source == "import"), ")"),
        div(class = "alert alert-info small", tr("indicator_label")),
        lapply(seq_len(nrow(sc)), function(i) dim_row(sc[i, ])),
        h5(class = "mt-3", tr("items_title")), counts_table(resp, "state"),
        h5(class = "mt-3", tr("attitudes_title")), counts_table(resp, "attitude"),
        h5(class = "mt-3", tr("priorities_title")), tags$small(class = "text-muted", tr("rank_note")),
        tags$table(class = "table table-sm small", tags$tbody(lapply(seq_len(nrow(pr)), function(i)
          tags$tr(tags$td(item_text(pr$item[i])),
                  tags$td(tr("mean_rank"), ": ", if (is.na(pr$mean_rank[i])) "" else sprintf("%.1f", pr$mean_rank[i])),
                  tags$td("n = ", pr$n[i]))))),
        h5(class = "mt-3", tr("roles_title")),
        if (is.null(rb)) tags$small(class = "text-muted", tr("roles_hidden"))
        else tagList(tags$small(class = "text-muted", tr("roles_hidden")),
          tags$table(class = "table table-sm small", tags$tbody(lapply(seq_len(nrow(rb)), function(i)
            tags$tr(tags$td(tr(paste0("role.", rb$role[i]))), tags$td(wp5_vocab_label("npg", rb$dimension[i], i18n)),
                    tags$td(if (is.na(rb$score[i])) "" else sprintf("%.2f", rb$score[i]))))))))
    })
    respondents_view <- reactive({
      rd <- readiness(); req(rd)
      r <- rd$respondents
      data.frame(
        stats::setNames(list(r$RespondentId,
                             vapply(r$Role, function(x) if (nzchar(x)) as.character(tr(paste0("role.", x))) else "", ""),
                             r$EnteredAt,
                             vapply(r$Source, function(x) as.character(tr(paste0("source.", x))), "")),
                        c(tr("col_respondent"), tr("col_role"), tr("col_date"), tr("col_source"))),
        check.names = FALSE, stringsAsFactors = FALSE)
    })
    output$respondent_table <- DT::renderDT(DT::datatable(respondents_view(), selection = "multiple",
                                                          rownames = FALSE, options = list(pageLength = 10)))
    observeEvent(input$delete_selected, {
      sel <- input$respondent_table_rows_selected
      rd <- readiness(); req(rd, length(sel) > 0)
      ids <- rd$respondents$RespondentId[sel]
      write_readiness(readiness_delete(rd, ids, bank))
      showNotification(paste(tr("deleted"), length(ids)), type = "warning")
    })
    output$export <- downloadHandler(
      filename = function() "governance_readiness_answers.xlsx",
      content = function(file) openxlsx::saveWorkbook(readiness_export_wb(readiness(), bank, i18n), file, overwrite = TRUE))

    invisible(list(readiness = readiness))
  })
}
```

- [ ] **Step 4: Wire it.**
  - `functions/ui_sidebar.R`, in the PIMS block after the Stakeholders sub-item: `bs4SidebarMenuSubItem(safe_t("ui.sidebar.governance_readiness", i18n_obj = i18n), tabName = "pims_readiness"),`.
  - `app.R`: in `OPTIONAL_MODULES` after `"modules/pims_stakeholder_module.R",` add `"modules/wp5_readiness_module.R",      # WS-9b D5.4 governance-readiness check`; after `bs4TabItem(tabName = "pims_stakeholders", ...)` add `bs4TabItem(tabName = "pims_readiness", wp5_readiness_ui("pims_ready", i18n)),`; after the `pims_stakeholders_data <- ...` server line add `pims_readiness_data <- wp5_readiness_server("pims_ready", project_data, session_i18n)`.

- [ ] **Step 5: Run tests** — `'^wp5-readiness-module$'`, `'^wp5-readiness$'`, `'^pims'`, `'^i18n-enforcement$'`, `'^analysis-modules-batch$'`; audit `missing=0 hardcoded=0`.
- [ ] **Step 6: Commit** — `feat(wp5): governance-readiness page in PIMS (WS-9b)`.

---

### Task 6: Release 1.31.0 and full verification

**Files:** `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`

- [ ] **Step 1: Release files** following the 1.30.0 release commit's conventions (`git -C <wt> log --oneline -12` → the `chore(release): 1.30.0` commit; `git show` it): `VERSION` 1.31.0; `DESCRIPTION` `Version: 1.31.0`; `VERSION_INFO.json`: version 1.31.0, version_name "WP5 governance-readiness check (D5.4)", release_date today, release_type minor, previous_version 1.30.0, features ending " (WS-9b).": the PIMS "Governance readiness (D5.4)" page (anonymous respondents via form or xlsx/csv template, per-dimension toolbox indicator, item distributions, Annex 7 priority ranking, role breakdown from 5 respondents, xlsx export); the item bank verified against D5.4 Annexes 5 and 7; migration note "projects with readiness answers need app 1.31.0". `CHANGELOG.md`: `## [1.31.0] - <today>` under `## [Unreleased]` with `### Added (WP5 governance-readiness check — spec 2026-10-17 WS-9b)` and `### Notes` (the indicator is a toolbox construct, not a WP5 score; only current-state questions are scored, attitudes and priorities are shown separately; cross-sectoral coordination has no D5.4 question; yes/no answers score ±1; no names or free text are collected).
- [ ] **Step 2: Full verification** (one Rscript per chunk, foreground, sequential): filters `'^[a-c]'`, `'^[d-h]'`, `'^[i-l]'`, `'^[m-o]'`, `'^[p-s]'`, `'^[t-z]'` (split a chunk that exceeds 10 minutes) → no failures; `micromamba run -n shiny python -m pytest scripts/tests -q -p no:cacheprovider` → all pass; audit `missing=0 hardcoded=0`; `Rscript deployment/pre-deploy-check.R` → all pass. Attribute any failure (branch vs pre-existing, using the main checkout read-only) and report it; do not fix it in this task.
- [ ] **Step 3: Commit** release files only — `chore(release): 1.31.0 — WP5 governance-readiness check (WS-9b)`.
