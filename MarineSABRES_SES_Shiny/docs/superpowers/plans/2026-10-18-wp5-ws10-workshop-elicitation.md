# WP5 WS-10 Workshop Elicitation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A PIMS "Workshop elicitation (D5.2)" page where a facilitator records anonymous workshop answers on Response-register measures (a ranking poll and the D5.2 Annex 4 11-tenet rating), sees the results, and can write the tenet results back into the register measure by measure, with undo.

**Architecture:** A verified data file (`data/wp5_tenet_guiding_questions.json`) plus pure R functions in `functions/wp5_workshop.R` (storage in `data$data$pims$workshops`, summaries, write-back proposal, apply/undo records, import/template/export, reusing the WS-9b matcher in `functions/wp5_readiness.R`). A thin module `modules/wp5_workshop_module.R` renders four tabs. The register is written only through the `register_api` that `response_measures_server()` now returns, extended with `update()`.

**Tech Stack:** R ≥ 4.4.1, Shiny + bs4Dash, shiny.i18n, jsonlite, openxlsx, DT, testthat 3; Python (micromamba env `shiny`) with PyMuPDF (`fitz`), pytest.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-18-wp5-ws10-workshop-elicitation-design.md` (the authority; decisions D1–D7, rulings §11).

All paths are relative to `MarineSABRES_SES_Shiny/` in the worktree `C:/Users/arturas.baziukas/wt-ws10` (branch `feat/wp5-ws10-workshop-elicitation`, from main 4b53b7d). Git root is one level up: `git -C C:/Users/arturas.baziukas/wt-ws10 ...`, never `cd <path> && git`.

## Global Constraints

- D5.2 source is only in the main checkout: `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5/D5.2/MarineSABRES_D5.2_Final.pdf`. Python tests that need it skip when absent (env var `WP5_DIR` or that default). CI does not run pytest.
- **Python safety:** only `micromamba run -n shiny python <script file or -m module>`, in the FOREGROUND. Never `python -`, `python3 -`, a bare `python`, a heredoc into python, or any background command — a console-less stdin starts the Python REPL, which loops a traceback forever (it filled the disk on 2026-10-17). If `micromamba run` reports "Python was not found", call `C:/Users/arturas.baziukas/micromamba/envs/shiny/python.exe <file> < /dev/null` directly.
- R tests from the app dir, one file filter per process, user library first: `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^wp5-workshop$')"`. Never run several R test processes at once (16 GB laptop). "package built under R version 4.4.3" warnings are environment noise.
- Storage `data$data$pims$workshops = list(version = 1L, counter, items)` exactly as spec §4. Participant answer columns `rank__<measureId>__<criterion>` and `tenet__<measureId>__<tenet>`. No names, contacts or free text are stored or read.
- Tenets = `EBM_TENETS$code` (constants.R), in that order; labels via `wp5_vocab_label("tenet", code, i18n)`. Register tenet columns `paste0("Tenet_", code)`; levels `TENET_LEVELS` (`minimal`, `intermediate`, `full`; `intermediate` only for `ecol_effective`); level labels via `modules.response.governance.tenet_level.<level>` / `.not_assessed` (existing keys).
- Write-back mapping (spec §6): median ≥ 4 → full; 3 ≤ m < 4 → intermediate for `ecol_effective`, minimal otherwise; < 3 → minimal; `n_valid < 3` → no proposal.
- `WP5_WORKSHOP_MIN_APP_VERSION <- "1.32.0"`, stamped when a project has ≥ 1 workshop or any register row has a non-empty `TenetSource` — in the module write helper and in the JSON load block of `functions/data_structure.R`.
- The workshop module never writes `data$response_measures` directly; register writes go through `register$update(id, fields)`, and the workshop store is re-read from `project_data_reactive()` after each such call.
- Every label through `i18n$t()` (9 languages: en, es, fr, de, lt, pt, it, no, el); dynamic keys get `# i18n-ref:` sentinels; the audit (`micromamba run -n shiny python scripts/_i18n_audit.py`, "Totals:" line) must show `missing=0 hardcoded=0`. Never edit `translations/_merged_translations.json`.
- New ids via `next_element_id()` + `safe_counter()` (functions/data_structure.R): `W001`… for workshops, `P001`… for participants (per workshop).
- Module tests re-bind real functions from `.GlobalEnv` before `testServer()` (helper-stubs.R shadows modules).
- Commits: message file, `git -C <wt> commit -F <file>`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_013pgU49PTbBYa3XxbHfFRC6`. Stage by explicit path only (`git add <path> ...`); never `git add -A`, `.` or `-f` on anything except `docs/` files; check `git diff --cached --stat` before committing. `docs/` is gitignored (`git add -f` for the plan/spec only). Never add `__pycache__/`, `translations/_merged_translations.json` or `*.rds`.

## Rulings made while planning

1. **JSON projects load with `fromJSON(simplifyVector = TRUE)`** (`server/project_io.R:99`), which turns `items` into a data.frame with nested columns. `normalize_workshops()` therefore round-trips a data.frame-shaped `items` through `toJSON(...)` / `fromJSON(simplifyVector = FALSE)`, like `.scenarios_as_list()` (`functions/data_structure.R:1201`).
2. **Rename = edit the title in Set-up and press "Save set-up"** (no separate Rename button); spec §7's "Rename" is satisfied by the title field.
3. **Locked set-up fields are rendered as read-only text** (not disabled inputs), so they cannot be submitted; `workshop_update_setup()` also ignores them server-side.
4. **Normalisation keeps only the answer columns of the current set-up** (`workshop_answer_columns(ws)`), a strict subset of the spec §4 regex; set-up is locked while answers exist, so nothing valid is lost.
5. **Tenet answers import also accepts digits `1`–`5`** (paper forms), next to codes and labels in any language.
6. **`response_measures_server()` returns `c(register_api, list(data = reactive(response_data)))`**: nothing consumes the old return value (`app.R:1068` discards it; no test calls `getReturned()` on it).
7. **Apply/Undo buttons send `Shiny.setInputValue('<ns>apply_measure' | '<ns>undo_measure', '<id>', {priority: 'event'})`**, one observer each, instead of one observer per dynamic button.
8. **Consent toggle writes `ws$consent` immediately** (observer on `input$consent`, `ignoreInit = TRUE`).

## Review Focus

1. A project saved to JSON and loaded again (auto-unboxed single intervention, data.frame-shaped `items` and nested respondents) → identical workshop after normalisation (Task 2 test).
2. An xlsx template whose poll cells come back as numbers (`-5`, `3`) or with a typographic minus (`−3`) → accepted as the scale value (Task 4 test).
3. Template headers carrying upper-case measure ids (`rank__RM003__importance`), which `.ready_key()` lower-cases → still matched (Task 4 test).
4. A register measure whose tenet is "not assessed" (`""`) → a proposal counts as a change and is applied (Task 3 test).
5. A workshop deleted after its results were applied → the project still needs 1.32.0 because `TenetSource` remains (Task 2 test).

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `data/wp5_tenet_guiding_questions.json` | 1 | 11 Annex 4 guiding questions |
| `scripts/tests/test_wp5_tenet_questions.py` | 1 | verbatim check vs D5.2 |
| `.gitattributes` (git root) | 1 | LF for the new JSON |
| `functions/wp5_workshop.R` (new), `global.R` | 1–4 | loader, storage, summaries, write-back, import/export |
| `constants.R` | 2 | workshop constants, `TenetSource` column |
| `functions/data_structure.R` | 2 | JSON load normalisation + stamp |
| `tests/testthat/test-wp5-workshop.R` | 1–4 | pure-function tests |
| `modules/response_module.R` | 3 | `register$update()`, return the api |
| `tests/testthat/test-response-module.R` | 3 | register api tests |
| `translations/modules/wp5_workshop.json` (new), `translations/ui/sidebar.json` | 5 | keys |
| `modules/wp5_workshop_module.R` (new), `functions/ui_sidebar.R`, `app.R` | 6 | page and wiring |
| `tests/testthat/test-wp5-workshop-module.R` | 6 | module tests |
| `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md` | 7 | release 1.32.0 |

---

### Task 1: Guiding questions, their verification and the loader

**Files:**
- Create: `data/wp5_tenet_guiding_questions.json`, `scripts/tests/test_wp5_tenet_questions.py`, `functions/wp5_workshop.R`, `tests/testthat/test-wp5-workshop.R`
- Modify: `global.R` (after the `functions/wp5_readiness.R` source line, ~L715), `.gitattributes` at the git root (`C:/Users/arturas.baziukas/wt-ws10/.gitattributes`)

**Interfaces:**
- Produces: `load_wp5_tenet_questions(path = NULL, force_reload = FALSE)` → list (`version`, `source`, `source_file`, `scale`, `questions` = list of `list(tenet, text_en, source_page)`) or NULL; `wp5_tenet_question(qs, tenet)` → English text or "".

- [ ] **Step 1: Write the data file** `data/wp5_tenet_guiding_questions.json` (UTF-8, LF, 2-space indent, trailing newline):

```json
{
  "version": 1,
  "source": "D5.2 Final, Annex 4 tenet assessment form",
  "source_file": "WP5/D5.2/MarineSABRES_D5.2_Final.pdf",
  "scale": ["completely_disagree", "disagree", "neutral", "agree", "completely_agree"],
  "questions": [
    {"tenet": "ecol_effective", "text_en": "To what extent does this measure contribute to achieving environmental targets and safeguarding ecosystem features and functioning?", "source_page": 219},
    {"tenet": "tech_feasible", "text_en": "Is the necessary technology available and proven to support the implementation and long-term maintenance of this measure?", "source_page": 219},
    {"tenet": "econ_efficient", "text_en": "Does this measure offer good value for money compared to other alternatives, considering both costs and benefits?", "source_page": 219},
    {"tenet": "econ_viable", "text_en": "Will this measure improve economic viability, both in the short-term and long-term, considering revenue relative to costs?", "source_page": 220},
    {"tenet": "socially_desirable", "text_en": "To what extent do you believe stakeholders will support this measure, or might there be resistance?", "source_page": 220},
    {"tenet": "ethically_defensible", "text_en": "To what extent is this measure ethically sound and morally acceptable?", "source_page": 220},
    {"tenet": "culturally_inclusive", "text_en": "To what extent does this measure consider and respect local customs and practices?", "source_page": 220},
    {"tenet": "legally_permissible", "text_en": "To what extent does this measure comply with existing regional, national, and international laws and regulations?", "source_page": 221},
    {"tenet": "admin_achievable", "text_en": "To what extent are the administrative processes and transaction costs manageable for implementing this measure?", "source_page": 221},
    {"tenet": "communicable", "text_en": "To what extent can this measure be effectively communicated to the public, and does it align with the current political landscape?", "source_page": 221},
    {"tenet": "politically_expedient", "text_en": "To what extent does this measure align with the prevailing political climate and have the support of political leaders?", "source_page": 222}
  ]
}
```

Append `MarineSABRES_SES_Shiny/data/wp5_tenet_guiding_questions.json text eol=lf` to the git-root `.gitattributes` (next to the WS-8 lines).

- [ ] **Step 2: Write the pytest** `scripts/tests/test_wp5_tenet_questions.py`:

```python
"""Verify data/wp5_tenet_guiding_questions.json against D5.2 Annex 4 (spec 2026-10-18 WS-10 §3)."""
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
D52 = WP5 / "D5.2" / "MarineSABRES_D5.2_Final.pdf"
QS = json.loads((APP / "data" / "wp5_tenet_guiding_questions.json").read_text(encoding="utf-8"))
TENETS = ["ecol_effective", "tech_feasible", "econ_efficient", "econ_viable", "socially_desirable",
          "ethically_defensible", "culturally_inclusive", "legally_permissible", "admin_achievable",
          "communicable", "politically_expedient"]
needs_src = pytest.mark.skipif(not D52.exists(), reason="D5.2 source not available (WP5/ is not in git)")
ANNEX4 = (219, 222)   # printed page = PDF page


def key(s):
    return re.sub(r"[^0-9a-z]", "", unicodedata.normalize("NFKC", s).lower())


@lru_cache(maxsize=None)
def annex_text():
    import fitz
    doc = fitz.open(str(D52))
    return key(" ".join(doc[p - 1].get_text() for p in range(ANNEX4[0], ANNEX4[1] + 1)))


def test_eleven_questions_in_tenet_order():
    assert [q["tenet"] for q in QS["questions"]] == TENETS
    assert all(ANNEX4[0] <= q["source_page"] <= ANNEX4[1] for q in QS["questions"])


@needs_src
@pytest.mark.parametrize("q", QS["questions"], ids=lambda q: q["tenet"])
def test_question_text_is_in_annex4(q):
    assert key(q["text_en"]) in annex_text(), q["tenet"]


@needs_src
def test_a_made_up_question_is_rejected():
    assert key("To what extent is this measure loved by everyone?") not in annex_text()
```

- [ ] **Step 3: Run it** — `micromamba run -n shiny python -m pytest scripts/tests/test_wp5_tenet_questions.py -q -p no:cacheprovider` → 13 passed (fails first only if the JSON is wrong — fix the JSON text, never the test).

- [ ] **Step 4: Write the failing R test** — create `tests/testthat/test-wp5-workshop.R`:

```r
# tests/testthat/test-wp5-workshop.R
# WS-10 (spec 2026-10-18): workshop elicitation — storage, summaries, write-back, import/export.
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "functions/wp5_workshop.R"))

test_that("guiding questions: 11, in EBM_TENETS order, non-empty English text", {
  qs <- load_wp5_tenet_questions(force_reload = TRUE)
  expect_false(is.null(qs))
  expect_equal(vapply(qs$questions, `[[`, "", "tenet"), EBM_TENETS$code)
  expect_true(all(nzchar(vapply(EBM_TENETS$code, function(t) wp5_tenet_question(qs, t), ""))))
  expect_equal(wp5_tenet_question(qs, "not_a_tenet"), "")
  expect_equal(unlist(qs$scale), c("completely_disagree", "disagree", "neutral", "agree", "completely_agree"))
})

test_that("a missing file gives NULL, not an error", {
  expect_null(load_wp5_tenet_questions(path = tempfile(fileext = ".json")))
})
```

Run: `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^wp5-workshop$')"` → FAIL (`functions/wp5_workshop.R` missing).

- [ ] **Step 5: Create `functions/wp5_workshop.R`** with the header and loader:

```r
# functions/wp5_workshop.R
# =============================================================================
# WP5 WS-10 (spec 2026-10-18): workshop elicitation on Response-register
# measures — D5.2 ranking poll + D5.2 Annex 4 11-tenet rating. Storage in
# data$data$pims$workshops, summaries, write-back proposal with apply/undo
# records, import/template/export. Pure functions; the module is a thin shell.
# Import label matching reuses functions/wp5_readiness.R (.ready_key,
# readiness_value_map, readiness_translations, readiness_read_file).
# =============================================================================

.wp5_ws_env <- new.env(parent = emptyenv())

#' D5.2 Annex 4 guiding questions, or NULL. Only default-path loads are cached.
load_wp5_tenet_questions <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_ws_env$questions)) return(.wp5_ws_env$questions)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_tenet_guiding_questions.json")
            else file.path("data", "wp5_tenet_guiding_questions.json")
  }
  qs <- if (file.exists(path)) tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL) else NULL
  if (is.null(qs) && exists("debug_log", mode = "function")) debug_log(sprintf("WP5 workshop: could not load %s", path), "WP5")
  if (default) .wp5_ws_env$questions <- qs
  qs
}

#' English guiding question for one tenet ("" when unknown)
wp5_tenet_question <- function(qs, tenet) {
  q <- Find(function(x) identical(x$tenet, tenet), qs$questions %||% list())
  if (is.null(q)) "" else as.character(q$text_en)
}
```

Add to `global.R` directly after `source("functions/wp5_readiness.R", local = FALSE) ...`:

```r
source("functions/wp5_workshop.R", local = FALSE)         # WS-10: D5.2 workshop elicitation
```

- [ ] **Step 6: Run** the R test → PASS; also `filter = '^functions-sourced-in-app$'` → PASS.
- [ ] **Step 7: Commit** (explicit paths: the JSON, the pytest, `functions/wp5_workshop.R`, `global.R`, the test, git-root `.gitattributes`) — `feat(wp5): D5.2 Annex 4 tenet guiding questions, verified against the PDF (WS-10)`.

---

### Task 2: Constants, storage and the version mark (pure R)

**Files:**
- Modify: `constants.R` (end of the WS-9b block, ~L965; and `RM_REGISTER_COLUMNS`, ~L831), `functions/wp5_workshop.R`, `functions/data_structure.R` (after the readiness block, ~L1021)
- Test: `tests/testthat/test-wp5-workshop.R`

**Interfaces:**
- Consumes: `safe_counter()`, `next_element_id()`, `stamp_min_app_version()`, `normalize_response_measures()`, `EBM_TENETS`.
- Produces (all pure; `ws` = one workshop list, `store` = `list(version, counter, items)`):
  - `workshop_rank_col(m, crit)`, `workshop_tenet_col(m, tenet)` → character vectors
  - `workshop_valid_measure_id(id)` → logical vector
  - `workshop_answer_columns(ws)` → character vector (per measure: rank columns in `poll$criteria` order, then 11 tenet columns if `tenets_on`)
  - `normalize_workshop(ws)` → workshop list with `id, title, date, note, interventions, poll(scale, criteria), tenets_on, consent, counter, respondents (data.frame), applied (list)`
  - `normalize_workshops(x)` → store
  - `workshop_get(store, id)` → ws or NULL; `workshop_set(store, ws)` → store (replace by id); `workshop_remove(store, id)` → store
  - `workshop_create(store, title = "", date = as.character(Sys.Date()))` → store (new workshop last); `workshop_duplicate(store, id)` → store (copy of set-up, no respondents/applied, new id, last)
  - `workshop_has_respondents(ws)` → logical
  - `workshop_update_setup(ws, fields)` → ws (locked keys ignored while respondents exist)
  - `workshop_append(ws, rows, source)` → ws; `workshop_delete_respondents(ws, ids)` → ws
  - `workshops_need_version(store, measures)` → logical

- [ ] **Step 1: Constants.** In `constants.R` append `"TenetSource"` as the last element of `RM_REGISTER_COLUMNS` (after the `paste0("Tenet_", ...)` block). After the WS-9b block add:

```r
# ============================================================================
# WP5 WORKSHOP ELICITATION (spec 2026-10-18 WS-10, D5.2 ranking poll + Annex 4 tenets)
# ============================================================================
WORKSHOP_ID_PREFIX <- "W"                 # workshops W001..
WORKSHOP_PARTICIPANT_PREFIX <- "P"        # anonymous participants P001.. (per workshop)
WORKSHOP_META_COLUMNS <- c("RespondentId", "EnteredAt", "Source")
WORKSHOP_POLL_CRITERIA <- c("importance", "feasibility", "long_term_impact")
WORKSHOP_POLL_SCALES <- list(pm5 = as.character(-5:5), four = as.character(1:4))   # ASCII hyphen-minus
WORKSHOP_TENET_CODES <- c("completely_disagree", "disagree", "neutral", "agree", "completely_agree")  # points 1..5
WORKSHOP_TENET_ANSWERS <- c(WORKSHOP_TENET_CODES, "dont_know")
WORKSHOP_MIN_VALID <- 3L                  # fewer valid tenet ratings -> no write-back proposal
# data$data$pims$workshops and the register's TenetSource are new in 1.32.0; stamped when a
# project has a workshop or a TenetSource value
WP5_WORKSHOP_MIN_APP_VERSION <- "1.32.0"
```

- [ ] **Step 2: Write the failing tests** — append to `tests/testthat/test-wp5-workshop.R`:

```r
ws_with <- function(...) {                          # a normalised workshop with fields overridden
  normalize_workshop(utils::modifyList(list(id = "W001", title = "T", date = "2026-10-18",
    interventions = c("RM001", "RM002"), poll = list(scale = "pm5", criteria = "importance"), tenets_on = TRUE,
    consent = TRUE), list(...)))
}
row_of <- function(ws, ...) {                       # one participant row with the given answers
  cols <- workshop_answer_columns(ws)
  r <- stats::setNames(as.list(rep("", length(cols))), cols)
  v <- list(...); r[names(v)] <- v
  as.data.frame(r, stringsAsFactors = FALSE, check.names = FALSE)
}

test_that("answer columns: per measure, rank columns then 11 tenet columns", {
  ws <- ws_with(poll = list(scale = "four", criteria = c("feasibility", "importance")))
  cols <- workshop_answer_columns(ws)
  expect_equal(cols[1:2], c("rank__RM001__importance", "rank__RM001__feasibility"))   # WORKSHOP_POLL_CRITERIA order
  expect_equal(cols[3], "tenet__RM001__ecol_effective")
  expect_length(cols, 2 * (2 + 11))
  expect_length(workshop_answer_columns(ws_with(tenets_on = FALSE)), 2)
})

test_that("normalize_workshop: defaults, bad values blanked, unknown columns and bad ids dropped", {
  ws <- normalize_workshop(list(id = "W001", date = "18/10/2026", interventions = c("RM001", "RM 2", "RM001"),
    poll = list(scale = "bogus", criteria = c("x")),
    respondents = data.frame(RespondentId = "P001", Name = "Ana", rank__RM001__importance = "7",
                             tenet__RM001__ecol_effective = "agree", tenet__RM001__tech_feasible = "maybe",
                             stringsAsFactors = FALSE, check.names = FALSE)))
  expect_equal(ws$date, "")
  expect_equal(ws$interventions, "RM001")
  expect_equal(ws$poll, list(scale = "pm5", criteria = "importance"))
  expect_true(ws$tenets_on)
  expect_false(ws$consent)
  r <- ws$respondents
  expect_false("Name" %in% names(r))
  expect_equal(r$rank__RM001__importance, "")              # 7 is off the -5..5 scale
  expect_equal(r$tenet__RM001__ecol_effective, "agree")
  expect_equal(r$tenet__RM001__tech_feasible, "")
  expect_equal(ws$counter, 1L)
  e <- normalize_workshop(NULL)
  expect_true(is.data.frame(e$respondents)); expect_equal(nrow(e$respondents), 0L)
  expect_equal(e$applied, list())
})

test_that("store: create, duplicate, get/set/remove; ids never reused", {
  st <- normalize_workshops(NULL)
  expect_equal(st$items, list())
  st <- workshop_create(workshop_create(st, title = "A"), title = "B")
  expect_equal(vapply(st$items, `[[`, "", "id"), c("W001", "W002"))
  st <- workshop_remove(st, "W002")
  st <- workshop_create(st)
  expect_equal(vapply(st$items, `[[`, "", "id"), c("W001", "W003"))
  w1 <- workshop_get(st, "W001"); w1$interventions <- "RM009"; w1$title <- "A2"
  st <- workshop_set(st, w1)
  expect_equal(workshop_get(st, "W001")$title, "A2")
  st <- workshop_duplicate(st, "W001")
  d <- workshop_get(st, "W004")
  expect_equal(d$interventions, "RM009")
  expect_equal(nrow(d$respondents), 0L)
  expect_null(workshop_get(st, "W999"))
})

test_that("participants: append P001.., delete never reuses ids", {
  ws <- ws_with()
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "3"), "form")
  ws <- workshop_append(ws, rbind(row_of(ws, rank__RM002__importance = "-5"), row_of(ws, rank__RM001__importance = "0")), "import")
  expect_equal(ws$respondents$RespondentId, c("P001", "P002", "P003"))
  expect_equal(ws$respondents$Source, c("form", "import", "import"))
  ws <- workshop_append(workshop_delete_respondents(ws, "P003"), row_of(ws, rank__RM001__importance = "1"), "form")
  expect_equal(ws$respondents$RespondentId, c("P001", "P002", "P004"))
  expect_equal(nrow(workshop_delete_respondents(ws, ws$respondents$RespondentId)$respondents), 0L)
})

test_that("set-up locks while participants exist; deleting them all unlocks", {
  ws <- ws_with()
  changed <- workshop_update_setup(ws, list(title = "New", interventions = "RM002", tenets_on = FALSE))
  expect_equal(c(changed$title, changed$interventions), c("New", "RM002"))
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "2"), "form")
  locked <- workshop_update_setup(ws, list(title = "New", interventions = "RM002",
                                           poll = list(scale = "four", criteria = "feasibility"), tenets_on = FALSE))
  expect_equal(locked$title, "New")
  expect_equal(locked$interventions, c("RM001", "RM002"))
  expect_equal(locked$poll$scale, "pm5")
  expect_true(locked$tenets_on)
  free <- workshop_update_setup(workshop_delete_respondents(ws, "P001"), list(interventions = "RM002"))
  expect_equal(free$interventions, "RM002")
})

test_that("JSON save/load round trip keeps the workshop (review focus 1)", {
  st <- workshop_create(normalize_workshops(NULL), title = "Arctic")
  ws <- workshop_update_setup(workshop_get(st, "W001"), list(interventions = "RM001"))   # one intervention -> auto-unboxed
  ws <- workshop_append(ws, row_of(ws, rank__RM001__importance = "-2", tenet__RM001__ecol_effective = "agree"), "form")
  st <- workshop_set(st, ws)
  json <- jsonlite::toJSON(list(data = list(pims = list(workshops = st))), pretty = TRUE, auto_unbox = TRUE)
  back <- jsonlite::fromJSON(json, simplifyVector = TRUE)$data$pims$workshops     # server/project_io.R:99 shape
  expect_equal(normalize_workshops(back), normalize_workshops(st))
})

test_that("version mark: any workshop, or a TenetSource left after the workshop is gone (review focus 5)", {
  m <- normalize_response_measures(data.frame(ID = "RM001", Name = "a", stringsAsFactors = FALSE))
  expect_false(workshops_need_version(NULL, m))
  expect_true(workshops_need_version(workshop_create(normalize_workshops(NULL)), m))
  m$TenetSource <- "Workshop W001 (2026-10-18, n = 4)"
  expect_true(workshops_need_version(normalize_workshops(NULL), m))
  expect_true(workshops_need_version(NULL, list(list(ID = "RM001", TenetSource = "x"))))   # JSON row lists
})

test_that("JSON load path normalises workshops and stamps 1.32.0", {
  p <- create_empty_project("t")
  p$data$pims$workshops <- list(items = list(list(id = "W001", interventions = "RM001")))
  out <- normalize_json_project_data(p)
  expect_equal(out$data$pims$workshops$items[[1]]$poll$scale, "pm5")
  expect_equal(out$min_app_version, WP5_WORKSHOP_MIN_APP_VERSION)
  expect_null(normalize_json_project_data(create_empty_project("t"))$min_app_version)
})
```

If `create_empty_project("t")$min_app_version` is not NULL on main, replace the last expectation with a check that it is not `"1.32.0"`.

- [ ] **Step 3: Run** → FAIL (functions missing).

- [ ] **Step 4: Implement** — append to `functions/wp5_workshop.R`:

```r
# ---- Storage (spec §4) ---------------------------------------------------------

workshop_rank_col <- function(m, crit) paste0("rank__", m, "__", crit)
workshop_tenet_col <- function(m, tenet) paste0("tenet__", m, "__", tenet)
workshop_valid_measure_id <- function(id) !is.na(id) & grepl("^[A-Za-z0-9]+$", as.character(id))

.ws_chr1 <- function(x, default = "") {
  v <- as.character(unlist(x))
  if (!length(v) || is.na(v[1])) default else v[1]
}
.ws_log <- function(msg) if (exists("debug_log", mode = "function")) debug_log(paste("WP5 workshop:", msg), "WARN")

workshop_answer_columns <- function(ws) {
  crit <- WORKSHOP_POLL_CRITERIA[WORKSHOP_POLL_CRITERIA %in% unlist(ws$poll$criteria)]
  unlist(lapply(as.character(unlist(ws$interventions)), function(m) {
    c(workshop_rank_col(m, crit), if (isTRUE(ws$tenets_on)) workshop_tenet_col(m, EBM_TENETS$code))
  })) %||% character(0)
}

# respondents: data.frame, or JSON list rows -> character data.frame
.ws_rows_df <- function(resp) {
  if (is.list(resp) && !is.data.frame(resp)) {
    rows <- Filter(is.list, resp)
    if (!length(rows)) return(data.frame())
    keys <- unique(unlist(lapply(rows, names)))
    return(as.data.frame(stats::setNames(lapply(keys, function(k) vapply(rows, function(r) .ws_chr1(r[[k]]), "")), keys),
                         stringsAsFactors = FALSE, check.names = FALSE))
  }
  if (is.data.frame(resp)) resp else data.frame()
}

.ws_norm_applied <- function(x, ivs) {
  allowed <- c(paste0("Tenet_", EBM_TENETS$code), "TenetSource")
  x <- Filter(is.list, x %||% list())
  ok <- Filter(function(e) {
    is.list(e$before) && is.list(e$after) && length(e$after) > 0 && .ws_chr1(e$measure) %in% ivs &&
      setequal(names(e$before), names(e$after)) && all(names(e$after) %in% allowed)
  }, x)
  if (length(ok) < length(x)) .ws_log(sprintf("dropped %d malformed apply record(s)", length(x) - length(ok)))
  lapply(ok, function(e) list(measure = .ws_chr1(e$measure), at = .ws_chr1(e$at),
                              before = lapply(e$before, .ws_chr1), after = lapply(e$after, .ws_chr1)))
}

normalize_workshop <- function(ws) {
  if (!is.list(ws)) ws <- list()
  date <- .ws_chr1(ws$date)
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", date)) date <- ""
  ivs <- unique(as.character(unlist(ws$interventions)))
  ivs <- ivs[workshop_valid_measure_id(ivs)]
  scale <- .ws_chr1(ws$poll$scale, "pm5")
  if (!scale %in% names(WORKSHOP_POLL_SCALES)) scale <- "pm5"
  crit <- WORKSHOP_POLL_CRITERIA[WORKSHOP_POLL_CRITERIA %in% as.character(unlist(ws$poll$criteria))]
  if (!length(crit)) crit <- "importance"
  out <- list(id = .ws_chr1(ws$id), title = .ws_chr1(ws$title), date = date, note = .ws_chr1(ws$note),
              interventions = ivs, poll = list(scale = scale, criteria = crit),
              tenets_on = if (is.null(ws$tenets_on)) TRUE else isTRUE(as.logical(unlist(ws$tenets_on))[1]),
              consent = isTRUE(as.logical(unlist(ws$consent))[1]))
  resp <- .ws_rows_df(ws$respondents)
  cols <- workshop_answer_columns(out)
  dropped <- setdiff(names(resp), c(WORKSHOP_META_COLUMNS, cols))
  if (length(dropped)) .ws_log(paste("dropped columns:", paste(dropped, collapse = ", ")))
  n <- nrow(resp)
  all_cols <- c(WORKSHOP_META_COLUMNS, cols)
  df <- as.data.frame(stats::setNames(lapply(all_cols, function(cl) {
    v <- if (cl %in% names(resp)) as.character(resp[[cl]]) else rep("", n)
    v[is.na(v)] <- ""
    v
  }), all_cols), stringsAsFactors = FALSE, check.names = FALSE)
  bad <- 0L
  for (cl in cols) {
    allowed <- if (startsWith(cl, "rank__")) WORKSHOP_POLL_SCALES[[scale]] else WORKSHOP_TENET_ANSWERS
    x <- nzchar(df[[cl]]) & !df[[cl]] %in% allowed
    bad <- bad + sum(x)
    df[[cl]][x] <- ""
  }
  if (bad > 0) .ws_log(sprintf("blanked %d out-of-range answer(s)", bad))
  out$counter <- as.integer(safe_counter(ws$counter, df$RespondentId, WORKSHOP_PARTICIPANT_PREFIX))
  out$respondents <- df
  out$applied <- .ws_norm_applied(ws$applied, ivs)
  out
}

normalize_workshops <- function(x) {
  items <- if (is.list(x)) x$items else NULL
  if (is.data.frame(items)) {          # fromJSON(simplifyVector = TRUE) shape (ruling 1)
    items <- tryCatch(jsonlite::fromJSON(jsonlite::toJSON(items, auto_unbox = TRUE, null = "null", na = "null"),
                                         simplifyVector = FALSE),
                      error = function(e) { .ws_log(paste("items conversion failed:", e$message)); list() })
  }
  items <- lapply(Filter(is.list, items %||% list()), normalize_workshop)
  items <- Filter(function(w) nzchar(w$id), items)
  ids <- vapply(items, `[[`, "", "id")
  if (any(duplicated(ids))) { .ws_log("dropped duplicate workshop ids"); items <- items[!duplicated(ids)]; ids <- ids[!duplicated(ids)] }
  list(version = 1L, counter = as.integer(safe_counter(if (is.list(x)) x$counter else 0, ids, WORKSHOP_ID_PREFIX)),
       items = items)
}

workshop_get <- function(store, id) Find(function(w) identical(w$id, id), normalize_workshops(store)$items)

workshop_set <- function(store, ws) {
  st <- normalize_workshops(store)
  ws <- normalize_workshop(ws)
  i <- match(ws$id, vapply(st$items, `[[`, "", "id"))
  if (is.na(i)) st$items[[length(st$items) + 1L]] <- ws else st$items[[i]] <- ws
  normalize_workshops(st)
}

workshop_remove <- function(store, id) {
  st <- normalize_workshops(store)
  st$items <- Filter(function(w) !identical(w$id, id), st$items)
  st
}

workshop_create <- function(store, title = "", date = as.character(Sys.Date())) {
  st <- normalize_workshops(store)
  st$counter <- st$counter + 1L
  st$items[[length(st$items) + 1L]] <- normalize_workshop(list(id = next_element_id(WORKSHOP_ID_PREFIX, st$counter),
                                                                title = title, date = date))
  st
}

workshop_duplicate <- function(store, id) {
  src <- workshop_get(store, id)
  if (is.null(src)) return(normalize_workshops(store))
  st <- workshop_create(store, title = src$title, date = as.character(Sys.Date()))
  new <- st$items[[length(st$items)]]
  new[c("interventions", "poll", "tenets_on", "note")] <- src[c("interventions", "poll", "tenets_on", "note")]
  workshop_set(st, new)
}

workshop_has_respondents <- function(ws) is.data.frame(ws$respondents) && nrow(ws$respondents) > 0

workshop_update_setup <- function(ws, fields) {
  ws <- normalize_workshop(ws)
  editable <- c("title", "date", "note", if (!workshop_has_respondents(ws)) c("interventions", "poll", "tenets_on"))
  for (k in intersect(names(fields), editable)) ws[[k]] <- fields[[k]]
  normalize_workshop(ws)
}

workshop_append <- function(ws, rows, source) {
  ws <- normalize_workshop(ws)
  if (!is.data.frame(rows) || nrow(rows) == 0) return(ws)
  start <- ws$counter
  rows$RespondentId <- vapply(seq_len(nrow(rows)), function(i) next_element_id(WORKSHOP_PARTICIPANT_PREFIX, start + i), "")
  rows$EnteredAt <- as.character(Sys.Date())
  rows$Source <- source
  tmp <- ws; tmp$respondents <- rows; tmp$applied <- list()     # never modifyList(): it merges data.frames column-wise
  new <- normalize_workshop(tmp)$respondents
  ws$respondents <- rbind(ws$respondents, new)
  ws$counter <- as.integer(start + nrow(rows))
  normalize_workshop(ws)
}

workshop_delete_respondents <- function(ws, ids) {
  ws <- normalize_workshop(ws)
  ws$respondents <- ws$respondents[!ws$respondents$RespondentId %in% ids, , drop = FALSE]
  rownames(ws$respondents) <- NULL
  ws
}

#' TRUE when the project needs 1.32.0: a workshop exists or a register row has TenetSource
workshops_need_version <- function(store, measures) {
  has_ws <- length(normalize_workshops(store)$items) > 0
  src <- if (is.data.frame(measures)) measures$TenetSource
         else if (is.list(measures)) vapply(Filter(is.list, measures), function(r) .ws_chr1(r$TenetSource), "")
         else NULL
  has_ws || any(nzchar(as.character(unlist(src))) & !is.na(unlist(src)))
}
```

In `functions/data_structure.R`, directly after the WS-9b readiness block (ends ~L1021, before the "Legacy scenario location" comment):

```r
  # PIMS workshops (WS-10): schema on every JSON load path; a workshop or a TenetSource needs 1.32.0
  if (is.list(data$data) && exists("normalize_workshops", mode = "function")) {
    if (is.list(data$data$pims) && !is.null(data$data$pims$workshops)) {
      data$data$pims$workshops <- normalize_workshops(data$data$pims$workshops)
    }
    if (workshops_need_version(data$data$pims$workshops, data$data$response_measures$measures) &&
        exists("stamp_min_app_version", mode = "function") && exists("WP5_WORKSHOP_MIN_APP_VERSION")) {
      data <- stamp_min_app_version(data, WP5_WORKSHOP_MIN_APP_VERSION)
    }
  }
```

- [ ] **Step 5: Run** `'^wp5-workshop$'`, `'^response-measures-schema$'`, `'^json-project-loading$'`, `'^wp5-readiness$'` (one process each) → PASS.
- [ ] **Step 6: Commit** (`constants.R`, `functions/wp5_workshop.R`, `functions/data_structure.R`, the test) — `feat(wp5): workshop storage, ids and 1.32.0 version mark (WS-10)`.

---

### Task 3: Summaries, write-back proposal, apply/undo records and the register API

**Files:**
- Modify: `functions/wp5_workshop.R`, `modules/response_module.R` (register_api ~L506; return ~L1111)
- Test: `tests/testthat/test-wp5-workshop.R`, `tests/testthat/test-response-module.R`

**Interfaces:**
- Consumes: Task 2 functions; `normalize_response_measures()`.
- Produces:
  - `workshop_poll_summary(ws)` → data.frame `measure, criterion, n, median, mean, order` (rows sorted, `order` = measure rank 1..)
  - `workshop_poll_counts(ws)` → data.frame `measure, criterion, value, n` (every scale value)
  - `workshop_tenet_summary(ws)` → data.frame `measure, tenet, n_valid, n_dont_know, median, p1..p5`
  - `workshop_tenet_level(tenet, median)` → `"full" | "intermediate" | "minimal" | NA`
  - `workshop_writeback_proposal(ws, measures)` → data.frame `measure, tenet, current, median, n_valid, proposed, changed` (11 rows per workshop measure present in `measures`)
  - `workshop_source_text(ws, n, template, today = Sys.Date())` → character
  - `workshop_apply_change(ws, measure, measures, template)` → `NULL` (nothing to change) or `list(after = <named list>, before = <named list>)`
  - `workshop_record_apply(ws, measure, before, after, at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"))` → ws
  - `workshop_last_apply(ws, measure)` → entry or NULL; `workshop_drop_last_apply(ws, measure)` → ws
  - `workshop_undo_check(entry, measures)` → `"ok" | "changed" | "gone"`
  - `response_measures_server()` returns `list(measures = reactive, add = function(fields), update = function(id, fields), data = reactive)`; `update()` returns TRUE/FALSE.

- [ ] **Step 1: Write the failing tests** — append to `tests/testthat/test-wp5-workshop.R`:

```r
tenet_rows <- function(ws, m, tenet, codes) {        # one participant per code, rating only (m, tenet)
  do.call(rbind, lapply(codes, function(cd) { r <- row_of(ws); r[[workshop_tenet_col(m, tenet)]] <- cd; r }))
}
reg <- function(...) normalize_response_measures(data.frame(ID = c("RM001", "RM002"), Name = c("a", "b"), ...,
                                                           stringsAsFactors = FALSE))

test_that("poll summary: n, median, mean; sorted by the first criterion's median then mean", {
  ws <- ws_with()
  ws <- workshop_append(ws, rbind(row_of(ws, rank__RM001__importance = "1", rank__RM002__importance = "4"),
                                  row_of(ws, rank__RM001__importance = "2", rank__RM002__importance = "-1"),
                                  row_of(ws, rank__RM002__importance = "4")), "form")
  s <- workshop_poll_summary(ws)
  expect_equal(s$measure, c("RM002", "RM001"))
  expect_equal(s$n, c(3L, 2L))
  expect_equal(s$median, c(4, 1.5))
  expect_equal(s$mean, c(7 / 3, 1.5))
  ct <- workshop_poll_counts(ws)
  expect_equal(nrow(ct), 2 * 11)
  expect_equal(ct$n[ct$measure == "RM002" & ct$value == "4"], 2L)
  expect_equal(nrow(workshop_poll_summary(ws_with(interventions = character(0)))), 0L)
})

test_that("tenet summary: even-n median, dont_know excluded from median and n", {
  ws <- ws_with()
  ws <- workshop_append(ws, tenet_rows(ws, "RM001", "ecol_effective",
                                       c("agree", "neutral", "dont_know", "completely_agree", "neutral")), "form")
  s <- workshop_tenet_summary(ws)
  e <- s[s$measure == "RM001" & s$tenet == "ecol_effective", ]
  expect_equal(c(e$n_valid, e$n_dont_know), c(4L, 1L))
  expect_equal(e$median, 3.5)                               # 3, 3, 4, 5
  expect_equal(c(e$p3, e$p4, e$p5), c(2L, 1L, 1L))
  expect_true(is.na(s$median[s$measure == "RM002" & s$tenet == "ecol_effective"]))
  expect_equal(nrow(s), 2 * 11)
  expect_equal(nrow(workshop_tenet_summary(ws_with(tenets_on = FALSE))), 0L)
})

test_that("level mapping at the boundaries (spec §6)", {
  lv <- function(t, m) workshop_tenet_level(t, m)
  expect_equal(vapply(c(2.5, 3, 3.5, 4, 5), function(m) lv("ecol_effective", m), ""),
               c("minimal", "intermediate", "intermediate", "full", "full"))
  expect_equal(vapply(c(2.5, 3, 3.5, 4), function(m) lv("communicable", m), ""),
               c("minimal", "minimal", "minimal", "full"))
  expect_true(is.na(lv("communicable", NA_real_)))
})

test_that("proposal: n < 3 gives none; not-assessed counts as changed (review focus 4); equal is unchanged", {
  ws <- ws_with()
  ws <- workshop_append(ws, rbind(tenet_rows(ws, "RM001", "ecol_effective", c("agree", "agree", "completely_agree")),
                                  tenet_rows(ws, "RM001", "tech_feasible", c("agree", "agree"))), "form")
  p <- workshop_writeback_proposal(ws, reg(Tenet_ecol_effective = c("", "full")))
  e <- p[p$measure == "RM001" & p$tenet == "ecol_effective", ]
  expect_equal(c(e$current, e$proposed), c("", "full"))
  expect_true(e$changed)
  t <- p[p$measure == "RM001" & p$tenet == "tech_feasible", ]
  expect_true(is.na(t$proposed)); expect_false(t$changed)
  expect_equal(nrow(p), 2 * 11)
  same <- workshop_writeback_proposal(ws, reg(Tenet_ecol_effective = c("full", "")))
  expect_false(same$changed[same$measure == "RM001" & same$tenet == "ecol_effective"])
  gone <- workshop_writeback_proposal(ws, reg()[2, , drop = FALSE])
  expect_equal(unique(gone$measure), "RM002")
})

test_that("apply change, record, undo check, and an apply/undo round trip", {
  ws <- ws_with()
  ws <- workshop_append(ws, tenet_rows(ws, "RM001", "ecol_effective", c("agree", "agree", "agree", "agree")), "form")
  m <- reg()
  ch <- workshop_apply_change(ws, "RM001", m, "Workshop {id} ({date}, n = {n})")
  expect_equal(ch$after$Tenet_ecol_effective, "full")
  expect_equal(ch$after$TenetSource, "Workshop W001 (2026-10-18, n = 4)")
  expect_equal(ch$before, list(Tenet_ecol_effective = "", TenetSource = ""))
  expect_null(workshop_apply_change(ws, "RM002", m, "x"))                   # nothing to change
  expect_equal(workshop_source_text(ws_with(date = ""), 3, "{id} {date} {n}", today = as.Date("2026-01-02")),
               "W001 2026-01-02 3")
  ws <- workshop_record_apply(ws, "RM001", ch$before, ch$after, at = "2026-10-18T10:00:00")
  e <- workshop_last_apply(ws, "RM001")
  expect_equal(e$after$Tenet_ecol_effective, "full")
  applied <- m; applied$Tenet_ecol_effective[1] <- "full"; applied$TenetSource[1] <- ch$after$TenetSource
  expect_equal(workshop_undo_check(e, applied), "ok")
  expect_equal(workshop_undo_check(e, m), "changed")
  expect_equal(workshop_undo_check(e, m[2, , drop = FALSE]), "gone")
  restored <- applied
  for (cl in names(e$before)) restored[[cl]][1] <- e$before[[cl]]
  expect_equal(restored, m)                                                  # round trip
  expect_null(workshop_last_apply(workshop_drop_last_apply(ws, "RM001"), "RM001"))
  expect_equal(normalize_workshop(ws)$applied, ws$applied)                   # records survive normalisation
})
```

Append to `tests/testthat/test-response-module.R` (after the "a loaded project without a counter" test):

```r
test_that("register api: returned by the server; update merges, re-normalises, FALSE for an unknown id", {
  proj <- create_empty_project("t"); proj$project_id <- "p1"
  proj$data$response_measures$measures <- normalize_response_measures(data.frame(
    ID = c("RM001", "RM002"), Name = c("a", "b"), Type = "regulatory", stringsAsFactors = FALSE))
  pd <- reactiveVal(proj)
  testServer(real_response_measures_server, args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$flushReact()
    api <- session$getReturned()
    expect_true(all(c("measures", "add", "update", "data") %in% names(api)))
    expect_true(api$update("RM002", list(Tenet_ecol_effective = "full", TenetSource = "Workshop W001 (2026-10-18, n = 3)")))
    m <- pd()$data$response_measures$measures
    expect_equal(c(m$Tenet_ecol_effective[2], m$TenetSource[2], m$Name[2]),
                 c("full", "Workshop W001 (2026-10-18, n = 3)", "b"))
    expect_equal(m$Tenet_ecol_effective[1], "")
    expect_false(api$update("RM999", list(TenetSource = "x")))
    expect_equal(api$measures()$TenetSource[2], "Workshop W001 (2026-10-18, n = 3)")
  })
})
```

- [ ] **Step 2: Run** both files → FAIL.

- [ ] **Step 3: Implement** — append to `functions/wp5_workshop.R`:

```r
# ---- Summaries (spec §5) -------------------------------------------------------

.ws_bind <- function(rows, empty) if (length(rows)) do.call(rbind, rows) else empty

workshop_poll_summary <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  empty <- data.frame(measure = character(), criterion = character(), n = integer(), median = numeric(),
                      mean = numeric(), order = integer(), stringsAsFactors = FALSE)
  out <- .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(ws$poll$criteria, function(cr) {
    v <- as.character(r[[workshop_rank_col(m, cr)]] %||% character(0))
    x <- suppressWarnings(as.numeric(v[nzchar(v)]))
    data.frame(measure = m, criterion = cr, n = length(x), median = if (length(x)) stats::median(x) else NA_real_,
               mean = if (length(x)) mean(x) else NA_real_, order = NA_integer_, stringsAsFactors = FALSE)
  })), recursive = FALSE), empty)
  if (!nrow(out)) return(empty)
  first <- out[out$criterion == ws$poll$criteria[1], ]
  pos <- match(first$measure, ws$interventions)
  ranked <- first$measure[order(-ifelse(is.na(first$median), -Inf, first$median),
                                -ifelse(is.na(first$mean), -Inf, first$mean), pos)]
  out$order <- match(out$measure, ranked)
  out <- out[order(out$order, match(out$criterion, ws$poll$criteria)), ]
  rownames(out) <- NULL
  out
}

workshop_poll_counts <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
  .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(ws$poll$criteria, function(cr) {
    v <- as.character(r[[workshop_rank_col(m, cr)]] %||% character(0))
    data.frame(measure = m, criterion = cr, value = vals, n = vapply(vals, function(x) sum(v == x), integer(1)),
               stringsAsFactors = FALSE, row.names = NULL)
  })), recursive = FALSE),
  data.frame(measure = character(), criterion = character(), value = character(), n = integer()))
}

workshop_tenet_summary <- function(ws) {
  ws <- normalize_workshop(ws); r <- ws$respondents
  empty <- data.frame(measure = character(), tenet = character(), n_valid = integer(), n_dont_know = integer(),
                      median = numeric(), p1 = integer(), p2 = integer(), p3 = integer(), p4 = integer(), p5 = integer(),
                      stringsAsFactors = FALSE)
  if (!isTRUE(ws$tenets_on)) return(empty)
  .ws_bind(unlist(lapply(ws$interventions, function(m) lapply(EBM_TENETS$code, function(t) {
    v <- as.character(r[[workshop_tenet_col(m, t)]] %||% character(0))
    pts <- match(v, WORKSHOP_TENET_CODES); pts <- pts[!is.na(pts)]
    cnt <- vapply(1:5, function(k) sum(pts == k), integer(1))
    data.frame(measure = m, tenet = t, n_valid = length(pts), n_dont_know = sum(v == "dont_know"),
               median = if (length(pts)) stats::median(pts) else NA_real_,
               p1 = cnt[1], p2 = cnt[2], p3 = cnt[3], p4 = cnt[4], p5 = cnt[5], stringsAsFactors = FALSE)
  })), recursive = FALSE), empty)
}

# ---- Write-back (spec §6) ------------------------------------------------------

workshop_tenet_level <- function(tenet, median) {
  if (length(median) != 1 || is.na(median)) return(NA_character_)
  if (median >= 4) "full" else if (median >= 3 && identical(tenet, "ecol_effective")) "intermediate" else "minimal"
}

workshop_writeback_proposal <- function(ws, measures) {
  ws <- normalize_workshop(ws); measures <- normalize_response_measures(measures)
  sm <- workshop_tenet_summary(ws)
  empty <- data.frame(measure = character(), tenet = character(), current = character(), median = numeric(),
                      n_valid = integer(), proposed = character(), changed = logical(), stringsAsFactors = FALSE)
  .ws_bind(unlist(lapply(intersect(ws$interventions, measures$ID), function(m) {
    i <- match(m, measures$ID)
    lapply(EBM_TENETS$code, function(t) {
      s <- sm[sm$measure == m & sm$tenet == t, , drop = FALSE]
      med <- if (nrow(s)) s$median[1] else NA_real_
      nv <- if (nrow(s)) s$n_valid[1] else 0L
      prop <- if (nv >= WORKSHOP_MIN_VALID) workshop_tenet_level(t, med) else NA_character_
      cur <- measures[[paste0("Tenet_", t)]][i]
      data.frame(measure = m, tenet = t, current = cur, median = med, n_valid = as.integer(nv), proposed = prop,
                 changed = !is.na(prop) && !identical(prop, cur), stringsAsFactors = FALSE)
    })
  }), recursive = FALSE), empty)
}

workshop_source_text <- function(ws, n, template, today = Sys.Date()) {
  date <- if (nzchar(ws$date %||% "")) ws$date else as.character(today)
  out <- gsub("{id}", ws$id, template, fixed = TRUE)
  out <- gsub("{date}", date, out, fixed = TRUE)
  gsub("{n}", as.character(n), out, fixed = TRUE)
}

#' The fields an Apply would write for one measure (changed tenets + TenetSource), or NULL
workshop_apply_change <- function(ws, measure, measures, template) {
  measures <- normalize_response_measures(measures)
  pr <- workshop_writeback_proposal(ws, measures)
  pr <- pr[pr$measure == measure & pr$changed, , drop = FALSE]
  if (!nrow(pr)) return(NULL)
  i <- match(measure, measures$ID)
  after <- c(stats::setNames(as.list(pr$proposed), paste0("Tenet_", pr$tenet)),
             list(TenetSource = workshop_source_text(normalize_workshop(ws), max(pr$n_valid), template)))
  before <- stats::setNames(lapply(names(after), function(cl) measures[[cl]][i]), names(after))
  list(after = after, before = before)
}

workshop_record_apply <- function(ws, measure, before, after, at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")) {
  ws <- normalize_workshop(ws)
  ws$applied[[length(ws$applied) + 1L]] <- list(measure = measure, at = at, before = before, after = after)
  normalize_workshop(ws)
}

workshop_last_apply <- function(ws, measure) {
  hits <- Filter(function(e) identical(e$measure, measure), normalize_workshop(ws)$applied)
  if (length(hits)) hits[[length(hits)]] else NULL
}

workshop_drop_last_apply <- function(ws, measure) {
  ws <- normalize_workshop(ws)
  idx <- which(vapply(ws$applied, function(e) identical(e$measure, measure), logical(1)))
  if (length(idx)) ws$applied[[max(idx)]] <- NULL
  ws
}

workshop_undo_check <- function(entry, measures) {
  measures <- normalize_response_measures(measures)
  i <- match(entry$measure, measures$ID)
  if (is.na(i)) return("gone")
  same <- vapply(names(entry$after), function(cl) identical(as.character(measures[[cl]][i]), entry$after[[cl]]), logical(1))
  if (all(same)) "ok" else "changed"
}
```

In `modules/response_module.R`, extend `register_api` (after `add = function(fields) { ... }`):

```r
      update = function(id, fields) {
        m <- normalize_response_measures(response_data$measures)
        i <- match(id, m$ID)
        if (is.na(i)) return(FALSE)
        for (cl in intersect(names(fields), setdiff(names(m), "ID"))) {
          m[[cl]][i] <- if (cl == "Cost") suppressWarnings(as.numeric(fields[[cl]])) else as.character(fields[[cl]] %||% "")
        }
        response_data$measures <- normalize_response_measures(m)
        sync_to_project_data()
        TRUE
      })
```

Update the comment above `register_api` to: `# WS-9a/WS-10: the governance-context tab and the PIMS workshop page write the register only through this api (they never write response_measures directly; this module reloads its state only on project change).` Replace the server's final `return(reactive({ response_data }))` with:

```r
    # WS-10: the register api is returned so app.R can hand it to the PIMS workshop page
    return(c(register_api, list(data = reactive({ response_data }))))
```

- [ ] **Step 4: Run** `'^wp5-workshop$'`, `'^response-module$'`, `'^wp5-governance-context-module$'` → PASS.
- [ ] **Step 5: Commit** (`functions/wp5_workshop.R`, `modules/response_module.R`, both tests) — `feat(wp5): workshop summaries, tenet write-back proposal with undo records, register update api (WS-10)`.

---

### Task 4: Import, template and export (pure R)

**Files:**
- Modify: `functions/wp5_workshop.R`
- Test: `tests/testthat/test-wp5-workshop.R`

**Interfaces:**
- Consumes: `.ready_key()`, `readiness_value_map()`, `readiness_translations(path)`, `readiness_read_file(path, name)` from `functions/wp5_readiness.R`; Task 2–3 functions.
- Produces:
  - `workshop_translations()` → translation table of `translations/modules/wp5_workshop.json` (empty list if absent)
  - `workshop_parse_import(df, ws, tr = workshop_translations())` → `list(ok = FALSE, error = "too_many_rows" | "no_answer_columns" | "foreign_columns", expected)` or `list(ok = TRUE, rows, blanked, ignored, dropped_empty)`
  - `workshop_template_wb(ws, measures, i18n)` → openxlsx workbook (sheets `answers`, `measures`, `scales`)
  - `workshop_export_wb(ws, i18n)` → openxlsx workbook (sheets `setup`, `respondents`, `poll_summary`, `tenet_summary`)

- [ ] **Step 1: Write the failing tests** — append:

```r
fake_tr <- list("modules.wp5_workshop.answer.agree" = list(en = "Agree", es = "De acuerdo"),
                "modules.wp5_workshop.answer.dont_know" = list(en = "Don't know", lt = "Nežinau"))

test_that("import: codes, labels in any language, accents, digits, numeric and typographic-minus ranks (focus 2, 3)", {
  ws <- ws_with(interventions = "RM003")
  df <- data.frame(`RANK__RM003__IMPORTANCE` = c(-5, 3, NA, 7), `tenet__RM003__ecol_effective` = c("de acuerdo", "4", "nezinau", "x"),
                   name = c("Ana", "", "", ""), stringsAsFactors = FALSE, check.names = FALSE)
  p <- workshop_parse_import(df, ws, fake_tr)
  expect_true(p$ok)
  expect_equal(p$rows$rank__RM003__importance, c("-5", "3", ""))   # row 4 (7, "x") becomes blank and is dropped
  expect_equal(p$rows$tenet__RM003__ecol_effective, c("agree", "agree", "dont_know"))
  expect_equal(p$blanked, 2L)                         # 7 off scale, "x" unknown
  expect_equal(p$dropped_empty, 1L)
  expect_equal(p$ignored, "name")
  minus <- workshop_parse_import(data.frame(rank__RM003__importance = "\u22123", stringsAsFactors = FALSE), ws, fake_tr)
  expect_equal(minus$rows$rank__RM003__importance, "-3")
})

test_that("import: refusals and blank rows", {
  ws <- ws_with(interventions = "RM003")
  f <- workshop_parse_import(data.frame(rank__RM009__importance = "1", stringsAsFactors = FALSE), ws, fake_tr)
  expect_false(f$ok); expect_equal(f$error, "foreign_columns"); expect_equal(f$expected, "rank__rm009__importance")
  n <- workshop_parse_import(data.frame(name = "a", stringsAsFactors = FALSE), ws, fake_tr)
  expect_equal(n$error, "no_answer_columns")
  b <- workshop_parse_import(data.frame(rank__RM003__importance = c("", NA), stringsAsFactors = FALSE), ws, fake_tr)
  expect_true(b$ok); expect_equal(nrow(b$rows), 0L); expect_equal(b$dropped_empty, 2L)
})

test_that("template -> import round trip; export sheets", {
  ws <- ws_with(interventions = "RM001")
  i18n <- list(t = function(k, ...) k)
  wb <- workshop_template_wb(ws, reg(), i18n)
  expect_equal(openxlsx::sheets(wb), c("answers", "measures", "scales"))
  row <- stats::setNames(as.list(rep("", length(workshop_answer_columns(ws)))), workshop_answer_columns(ws))
  row$rank__RM001__importance <- "-4"; row$tenet__RM001__ecol_effective <- "completely_agree"
  openxlsx::writeData(wb, "answers", as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE),
                      startRow = 2, colNames = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  p <- workshop_parse_import(readiness_read_file(f, "x.xlsx"), ws, fake_tr)
  expect_equal(c(p$rows$rank__RM001__importance, p$rows$tenet__RM001__ecol_effective), c("-4", "completely_agree"))
  ws <- workshop_append(ws, p$rows, "import")
  ex <- workshop_export_wb(ws, i18n)
  expect_equal(openxlsx::sheets(ex), c("setup", "respondents", "poll_summary", "tenet_summary"))
})
```

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement** — append to `functions/wp5_workshop.R`:

```r
# ---- Import / template / export (spec §7) --------------------------------------

workshop_translations <- function() {
  path <- if (exists("get_project_file", mode = "function")) get_project_file("translations", "modules", "wp5_workshop.json")
          else file.path("translations", "modules", "wp5_workshop.json")
  readiness_translations(path)
}

workshop_parse_import <- function(df, ws, tr = workshop_translations()) {
  ws <- normalize_workshop(ws)
  if (!is.data.frame(df)) df <- data.frame()
  cols <- workshop_answer_columns(ws)
  keyed <- .ready_key(names(df))
  names(df) <- keyed
  if (nrow(df) > 1000) return(list(ok = FALSE, error = "too_many_rows", expected = NULL))
  foreign <- keyed[grepl("^(rank|tenet)__", keyed) & !keyed %in% tolower(cols)]
  if (length(foreign)) return(list(ok = FALSE, error = "foreign_columns", expected = foreign))
  if (!any(keyed %in% tolower(cols))) return(list(ok = FALSE, error = "no_answer_columns", expected = cols))
  scale_vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
  tmap <- c(readiness_value_map(WORKSHOP_TENET_ANSWERS, "modules.wp5_workshop.answer.", tr),
            stats::setNames(WORKSHOP_TENET_CODES, as.character(1:5)))
  blanked <- 0L
  out <- as.data.frame(stats::setNames(lapply(cols, function(cl) {
    k <- tolower(cl)
    if (!k %in% keyed) return(rep("", nrow(df)))
    v <- as.character(df[[k]]); v[is.na(v)] <- ""
    v <- trimws(gsub("\u2212", "-", v, fixed = TRUE))
    res <- if (startsWith(cl, "rank__")) {
      num <- suppressWarnings(as.numeric(v))
      s <- ifelse(is.na(num), "", as.character(num))
      ifelse(s %in% scale_vals, s, "")
    } else {
      r <- unname(tmap[.ready_key(v)]); r[is.na(r)] <- ""; r
    }
    blanked <<- blanked + sum(nzchar(v) & !nzchar(res))
    res
  }), cols), stringsAsFactors = FALSE, check.names = FALSE)
  keep <- if (nrow(out) && ncol(out)) rowSums(out != "") > 0 else rep(FALSE, nrow(out))
  list(ok = TRUE, rows = out[keep, , drop = FALSE], blanked = as.integer(blanked),
       ignored = setdiff(keyed, tolower(cols)), dropped_empty = as.integer(sum(!keep)))
}

workshop_template_wb <- function(ws, measures, i18n) {
  ws <- normalize_workshop(ws); measures <- normalize_response_measures(measures)
  cols <- workshop_answer_columns(ws)
  lab <- function(key) as.character(i18n$t(key))
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "answers")
  openxlsx::writeData(wb, "answers", as.data.frame(stats::setNames(rep(list(character(0)), length(cols)), cols),
                                                   check.names = FALSE))
  openxlsx::addWorksheet(wb, "measures")
  openxlsx::writeData(wb, "measures", data.frame(id = ws$interventions,
    name = measures$Name[match(ws$interventions, measures$ID)] %||% "", stringsAsFactors = FALSE))
  openxlsx::addWorksheet(wb, "scales")
  openxlsx::writeData(wb, "scales", data.frame(
    scale = c(rep("rank", length(WORKSHOP_POLL_SCALES[[ws$poll$scale]])), rep("tenet", length(WORKSHOP_TENET_ANSWERS))),
    value = c(WORKSHOP_POLL_SCALES[[ws$poll$scale]], WORKSHOP_TENET_ANSWERS),
    label = c(WORKSHOP_POLL_SCALES[[ws$poll$scale]],
              paste0(c(as.character(1:5), ""), ifelse(seq_along(WORKSHOP_TENET_ANSWERS) <= 5, " = ", ""),
                     vapply(WORKSHOP_TENET_ANSWERS, function(cd) lab(paste0("modules.wp5_workshop.answer.", cd)), ""))),
    stringsAsFactors = FALSE))
  wb
}

workshop_export_wb <- function(ws, i18n) {
  ws <- normalize_workshop(ws)
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "setup")
  openxlsx::writeData(wb, "setup", data.frame(
    field = c("id", "title", "date", "note", "measures", "scale", "criteria", "tenets_on"),
    value = c(ws$id, ws$title, ws$date, ws$note, paste(ws$interventions, collapse = "; "), ws$poll$scale,
              paste(ws$poll$criteria, collapse = "; "), as.character(ws$tenets_on)), stringsAsFactors = FALSE))
  openxlsx::addWorksheet(wb, "respondents"); openxlsx::writeData(wb, "respondents", ws$respondents)
  openxlsx::addWorksheet(wb, "poll_summary"); openxlsx::writeData(wb, "poll_summary", workshop_poll_summary(ws))
  openxlsx::addWorksheet(wb, "tenet_summary"); openxlsx::writeData(wb, "tenet_summary", workshop_tenet_summary(ws))
  wb
}
```

- [ ] **Step 4: Run** `'^wp5-workshop$'` → PASS.
- [ ] **Step 5: Commit** — `feat(wp5): workshop template import (multilingual) and xlsx export (WS-10)`.

---

### Task 5: Translations

**Files:** Create `translations/modules/wp5_workshop.json` (shape of `translations/modules/wp5_readiness.json`: `{"languages": [...9], "translation": {key: {en, es, fr, de, lt, pt, it, no, el}}}`); modify `translations/ui/sidebar.json`.

**Interfaces:** Produces every key below in 9 languages, English verbatim. The 11 `question.*` English values must equal `text_en` in `data/wp5_tenet_guiding_questions.json` exactly. Question translations must keep the meaning of a survey question (participants read them). Reuse terms from `wp5_readiness.json`, `wp5_vocabulary.json` (tenet names) and `modules.response.governance.*`; keep D5.2, WP5, EBM unchanged. `source_template` keeps `{id}`, `{date}`, `{n}` literally in every language.

`ui.sidebar.workshop_elicitation` (sidebar.json): en "Workshop elicitation (D5.2)".

`modules.wp5_workshop.*`:

| key | en |
|---|---|
| `title` | Workshop elicitation (D5.2) |
| `subtitle` | Record anonymous workshop answers on candidate measures: a ranking poll and the 11-tenet rating of D5.2 Annex 4. |
| `workshop` | Workshop |
| `new` | New workshop |
| `duplicate` | Duplicate set-up |
| `delete` | Delete workshop |
| `delete_confirm_text` | Delete this workshop and its participants: |
| `delete_applied_note` | Values already applied to the register stay there and can no longer be undone. |
| `cancel` | Cancel |
| `no_project` | Open or create a project first. |
| `no_workshop` | Create a workshop to start. |
| `unavailable` | The tenet guiding questions are not available. |
| `tab_setup` | Set-up |
| `tab_entry` | Entry |
| `tab_results` | Results |
| `tab_apply` | Apply to register |
| `field_title` | Title |
| `field_date` | Date |
| `field_note` | Note (optional) |
| `field_measures` | Measures discussed (in the order shown to participants) |
| `register_empty` | Add measures in the Response register first. |
| `invalid_ids` | These register measures cannot be used because their ID has characters other than letters and digits: |
| `field_scale` | Ranking scale |
| `scale.pm5` | −5 to +5 |
| `scale.four` | 1 to 4 |
| `field_criteria` | Ranking criteria |
| `criterion.importance` | Importance |
| `criterion.feasibility` | Feasibility |
| `criterion.long_term_impact` | Long-term impact |
| `field_tenets_on` | Also rate each measure on the 11 tenets |
| `save_setup` | Save set-up |
| `setup_saved` | Set-up saved. |
| `criteria_required` | Choose at least one ranking criterion. |
| `locked_note` | The measures, scale, criteria and tenet rating are fixed while the workshop has participants. Use Duplicate set-up to start a new workshop with changes. |
| `consent_title` | Before you start |
| `consent_text` | Participants are anonymous: no names, contact details or written comments are recorded, only the selected answers, in this project file. Participants should have been informed following the project's own consent procedure. |
| `consent_check` | Participants were informed and agreed to take part |
| `consent_required` | Please confirm that participants were informed and agreed before adding answers. |
| `no_measures` | Choose the measures in Set-up first. |
| `poll_title` | Ranking |
| `tenets_title` | Tenet rating (1 = completely disagree, 5 = completely agree) |
| `translation_note` | Questions translated by the toolbox; the D5.2 wording is English. |
| `answer.completely_disagree` | Completely disagree |
| `answer.disagree` | Disagree |
| `answer.neutral` | Neutral |
| `answer.agree` | Agree |
| `answer.completely_agree` | Completely agree |
| `answer.dont_know` | Don't know |
| `question.ecol_effective` … `question.politically_expedient` | the 11 `text_en` values, verbatim |
| `save_participant` | Save participant and next |
| `saved_as` | Saved as participant |
| `nothing_to_save` | No answer was given, so nothing was saved. |
| `template_download` | Download template |
| `template_help` | One row per participant. Rankings: a number on the workshop's scale. Tenets: 1–5, an answer label, or dont_know. Leave a cell empty to skip. |
| `upload` | Upload filled template (xlsx or csv) |
| `import_rows` | Participants to add: |
| `import_blanked` | unreadable answers left empty: |
| `import_ignored` | columns ignored: |
| `import_dropped` | empty rows skipped: |
| `import_add` | Add participants: |
| `import_added` | Participants added: |
| `import_error.too_many_rows` | The file has more than 1000 rows. |
| `import_error.no_answer_columns` | No answer columns for this workshop were found. Expected columns: |
| `import_error.foreign_columns` | The file has answer columns that do not belong to this workshop: |
| `context_import` | Importing the workshop answers |
| `participants_title` | Participants |
| `col_participant` | Participant |
| `col_date` | Date |
| `col_source` | Source |
| `source.form` | entered |
| `source.import` | imported |
| `delete_selected` | Delete selected |
| `delete_resp_text` | Delete the selected participants: |
| `deleted` | Participants deleted: |
| `n_participants` | Participants |
| `no_participants` | No participants yet. |
| `ranking_title` | Ranking results |
| `col_measure` | Measure |
| `col_criterion` | Criterion |
| `col_n` | n |
| `col_median` | Median |
| `col_mean` | Mean |
| `heat_title` | Tenet rating results (median) |
| `too_few` | too few ratings |
| `export` | Export answers and summary (xlsx) |
| `apply_intro` | For each measure, the workshop's median tenet rating becomes a register level: 4 or more = full; 3 to under 4 = intermediate for ecological effectiveness, minimal for the other tenets; under 3 = minimal. At least 3 ratings are needed. |
| `apply_unavailable` | The Response register is not available here. |
| `apply_tenets_off` | This workshop did not rate the tenets. |
| `col_tenet` | Tenet |
| `col_current` | Register now |
| `col_workshop` | Workshop median (n) |
| `col_proposed` | Proposed |
| `apply_button` | Apply to this measure |
| `matches_register` | matches register |
| `undo_button` | Undo last apply |
| `applied` | Applied to the register: |
| `undone` | Undo done for |
| `undo_changed` | The register has changed since this apply, so it was not undone. |
| `measure_gone` | This measure is no longer in the register. |
| `not_in_register` | (no longer in register) |
| `source_template` | Workshop {id} ({date}, n = {n}) |
| `tenet_source` | Source of the tenet values |

- [ ] **Step 1: Generate** both files with a Python script FILE in `C:/Users/arturas.baziukas/wt-ws10/.superpowers/` (load `data/wp5_tenet_guiding_questions.json` for the `question.*` English values; `json.dump(ensure_ascii=False, indent=2)` + newline, UTF-8, LF). For `sidebar.json` insert the one new key textually after `ui.sidebar.governance_readiness` so existing lines are untouched (`git diff --stat` shows additions only).
- [ ] **Step 2: Check** — both parse; every `question.<tenet>` `en` equals the data file's `text_en`; `source_template` contains `{id}`, `{date}` and `{n}` in all 9 languages; `'^i18n-enforcement$'`, `'^i18n-duplicate-keys$'` → 0 failures; audit Totals `missing=0 hardcoded=0`.
- [ ] **Step 3: Commit** (the two JSON files only) — `i18n(wp5): WS-10 workshop elicitation keys and tenet questions (9 languages)`.

---

### Task 6: The PIMS page and its wiring

**Files:**
- Create: `modules/wp5_workshop_module.R`, `tests/testthat/test-wp5-workshop-module.R`
- Modify: `functions/ui_sidebar.R` (~L231), `app.R` (module source list ~L100; tab items ~L483; server calls ~L1068)

**Interfaces:**
- Consumes: Tasks 1–4 functions; translations from Task 5; `register` = list returned by `response_measures_server()` (`measures()`, `update(id, fields)`).
- Produces: `wp5_workshop_ui(id, i18n)`, `wp5_workshop_server(id, project_data_reactive, i18n, event_bus = NULL, register = NULL)` returning `invisible(list(store = reactive))`. Input ids: `workshop`, `new`, `duplicate`, `delete`, `delete_confirm`, `title`, `date`, `note`, `interventions`, `scale`, `criteria`, `tenets_on`, `save_setup`, `consent`, `a_<answer column>`, `save_participant`, `template`, `upload`, `import_confirm`, `respondent_table`, `delete_resp`, `delete_resp_confirm`, `export`, `apply_measure`, `undo_measure`. Outputs: `setup`, `entry`, `import_preview`, `respondent_table`, `results`, `apply`.

- [ ] **Step 1: Write the failing module tests** — `tests/testthat/test-wp5-workshop-module.R`:

```r
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
```

- [ ] **Step 2: Run** `'^wp5-workshop-module$'` → FAIL.

- [ ] **Step 3: Implement `modules/wp5_workshop_module.R`.** Start the file with a header comment (as `modules/wp5_readiness_module.R`) and one `# i18n-ref: modules.wp5_workshop.<key>` line for every key in the Task 5 table that is looked up through `tr(...)` with a computed name (`answer.*`, `question.*`, `criterion.*`, `scale.*`, `source.*`, `import_error.*`) plus every other `modules.wp5_workshop.*` key used, and `# i18n-ref:` lines for `modules.response.governance.tenet_level.minimal|intermediate|full|not_assessed`. Then:

```r
wp5_workshop_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_workshop.", k))
  tagList(
    h3(tr("title")), p(class = "text-muted", tr("subtitle")),
    fluidRow(
      column(5, selectInput(ns("workshop"), tr("workshop"), choices = c(" " = ""))),
      column(7, div(class = "mt-4",
        actionButton(ns("new"), tr("new"), icon = icon("plus"), class = "btn-primary"),
        actionButton(ns("duplicate"), tr("duplicate"), icon = icon("copy")),
        actionButton(ns("delete"), tr("delete"), icon = icon("trash"), class = "btn-danger")))),
    tabsetPanel(id = ns("tabs"),
      tabPanel(tr("tab_setup"), div(class = "mt-3", uiOutput(ns("setup")))),
      tabPanel(tr("tab_entry"), div(class = "mt-3", uiOutput(ns("entry")),
        h5(class = "mt-4", tr("template_download")),
        downloadButton(ns("template"), tr("template_download")),
        p(class = "small text-muted mt-2", tr("template_help")),
        fileInput(ns("upload"), tr("upload"), accept = c(".xlsx", ".csv")),
        uiOutput(ns("import_preview")),
        h5(class = "mt-4", tr("participants_title")), DT::DTOutput(ns("respondent_table")),
        actionButton(ns("delete_resp"), tr("delete_selected"), icon = icon("trash"), class = "btn-danger mt-2"))),
      tabPanel(tr("tab_results"), div(class = "mt-3", uiOutput(ns("results")),
        downloadButton(ns("export"), tr("export"), class = "mt-2"))),
      tabPanel(tr("tab_apply"), div(class = "mt-3", uiOutput(ns("apply")))))
  )
}

wp5_workshop_server <- function(id, project_data_reactive, i18n, event_bus = NULL, register = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_workshop.", k))
    qs <- load_wp5_tenet_questions()
    level_label <- function(x) i18n$t(paste0("modules.response.governance.tenet_level.", if (nzchar(x %||% "")) x else "not_assessed"))

    store <- reactive({
      pd <- project_data_reactive()
      if (is.null(pd)) NULL else normalize_workshops(pd$data$pims$workshops)
    })
    measures <- reactive({
      if (!is.null(register)) normalize_response_measures(register$measures())
      else normalize_response_measures(project_data_reactive()$data$response_measures$measures)
    })
    # single write path: always starts from the CURRENT project (spec §6 ordering guard)
    modify_store <- function(f) {
      pd <- project_data_reactive()
      if (is.null(pd)) { showNotification(tr("no_project"), type = "warning"); return(invisible(NULL)) }
      st <- normalize_workshops(f(normalize_workshops(pd$data$pims$workshops)))
      pd$data$pims$workshops <- st
      if (workshops_need_version(st, pd$data$response_measures$measures))
        pd <- stamp_min_app_version(pd, WP5_WORKSHOP_MIN_APP_VERSION)
      project_data_reactive(pd)
      invisible(st)
    }
    current <- reactive({
      st <- store(); id <- input$workshop
      if (is.null(st) || is.null(id) || !nzchar(id)) NULL else workshop_get(st, id)
    })
    select_last <- function(st) {
      if (length(st$items)) updateSelectInput(session, "workshop", selected = st$items[[length(st$items)]]$id)
    }

    observe({
      st <- store(); req(st)
      ids <- vapply(st$items, `[[`, "", "id")
      labels <- vapply(st$items, function(w) if (nzchar(w$title)) paste(w$id, "-", w$title) else w$id, "")
      sel <- isolate(input$workshop)
      if (is.null(sel) || !sel %in% ids) sel <- if (length(ids)) ids[length(ids)] else ""
      updateSelectInput(session, "workshop", choices = c(" " = "", stats::setNames(ids, labels)), selected = sel)
    })

    # ---- Workshop list ----
    observeEvent(input$new, { st <- modify_store(function(st) workshop_create(st)); if (!is.null(st)) select_last(st) })
    observeEvent(input$duplicate, {
      ws <- current(); req(ws)
      st <- modify_store(function(st) workshop_duplicate(st, ws$id)); if (!is.null(st)) select_last(st)
    })
    observeEvent(input$delete, {
      ws <- current(); req(ws)
      showModal(modalDialog(
        p(tr("delete_confirm_text"), " ", ws$id, " (", tr("n_participants"), ": ", nrow(ws$respondents), ")"),
        if (length(ws$applied)) p(class = "text-warning", tr("delete_applied_note")),
        footer = tagList(modalButton(tr("cancel")), actionButton(ns("delete_confirm"), tr("delete"), class = "btn-danger"))))
    })
    observeEvent(input$delete_confirm, {
      ws <- current(); req(ws)
      modify_store(function(st) workshop_remove(st, ws$id))
      removeModal()
    })

    # ---- Set-up ----
    output$setup <- renderUI({
      st <- store()
      if (is.null(st)) return(div(class = "alert alert-light", tr("no_project")))
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      m <- measures()
      ok <- workshop_valid_measure_id(m$ID)
      choices <- stats::setNames(m$ID[ok], paste(m$ID[ok], "\u2014", m$Name[ok]))
      locked <- workshop_has_respondents(ws)
      crit_choices <- stats::setNames(WORKSHOP_POLL_CRITERIA, vapply(WORKSHOP_POLL_CRITERIA, function(c) tr(paste0("criterion.", c)), ""))
      scale_choices <- stats::setNames(names(WORKSHOP_POLL_SCALES), vapply(names(WORKSHOP_POLL_SCALES), function(s) tr(paste0("scale.", s)), ""))
      tagList(
        textInput(ns("title"), tr("field_title"), value = ws$title),
        dateInput(ns("date"), tr("field_date"), value = if (nzchar(ws$date)) ws$date else NULL),
        textInput(ns("note"), tr("field_note"), value = ws$note),
        if (locked) tagList(
          div(class = "alert alert-info small", tr("locked_note")),
          p(strong(tr("field_measures")), ": ", paste(ws$interventions, collapse = ", ")),
          p(strong(tr("field_scale")), ": ", tr(paste0("scale.", ws$poll$scale))),
          p(strong(tr("field_criteria")), ": ", paste(vapply(ws$poll$criteria, function(c) tr(paste0("criterion.", c)), ""), collapse = ", ")),
          p(strong(tr("field_tenets_on")), ": ", if (ws$tenets_on) "\u2713" else "\u2013"))
        else tagList(
          if (!nrow(m)) div(class = "alert alert-warning", tr("register_empty")),
          selectizeInput(ns("interventions"), tr("field_measures"), choices = choices, selected = ws$interventions,
                         multiple = TRUE, options = list(plugins = list("remove_button"))),
          if (any(!ok)) tags$small(class = "text-muted d-block", tr("invalid_ids"), " ", paste(m$ID[!ok], collapse = ", ")),
          radioButtons(ns("scale"), tr("field_scale"), choices = scale_choices, selected = ws$poll$scale, inline = TRUE),
          checkboxGroupInput(ns("criteria"), tr("field_criteria"), choices = crit_choices, selected = ws$poll$criteria, inline = TRUE),
          checkboxInput(ns("tenets_on"), tr("field_tenets_on"), value = ws$tenets_on)),
        actionButton(ns("save_setup"), tr("save_setup"), icon = icon("save"), class = "btn-primary"))
    })
    observeEvent(input$save_setup, {
      ws <- current(); req(ws)
      fields <- list(title = input$title %||% "", date = as.character(input$date %||% ""), note = input$note %||% "")
      if (!workshop_has_respondents(ws)) {
        crit <- as.character(input$criteria %||% character(0))
        if (!length(crit)) { showNotification(tr("criteria_required"), type = "warning"); return() }
        fields <- c(fields, list(interventions = as.character(input$interventions %||% character(0)),
                                 poll = list(scale = input$scale %||% "pm5", criteria = crit),
                                 tenets_on = isTRUE(input$tenets_on)))
      }
      modify_store(function(st) workshop_set(st, workshop_update_setup(workshop_get(st, ws$id), fields)))
      showNotification(tr("setup_saved"), type = "message")
    })

    # ---- Entry ----
    observeEvent(input$consent, {
      ws <- current(); req(ws)
      if (!identical(isTRUE(input$consent), isTRUE(ws$consent))) {
        modify_store(function(st) { w <- workshop_get(st, ws$id); w$consent <- isTRUE(input$consent); workshop_set(st, w) })
      }
    }, ignoreInit = TRUE)
    output$entry <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (is.null(qs)) return(div(class = "alert alert-warning", tr("unavailable")))
      consent_box <- div(class = "alert alert-info", strong(tr("consent_title")), p(tr("consent_text")),
                         checkboxInput(ns("consent"), tr("consent_check"), value = ws$consent))
      if (!length(ws$interventions)) return(tagList(consent_box, div(class = "alert alert-light", tr("no_measures"))))
      m <- measures()
      scale_vals <- WORKSHOP_POLL_SCALES[[ws$poll$scale]]
      tenet_choices <- stats::setNames(WORKSHOP_TENET_ANSWERS, vapply(WORKSHOP_TENET_ANSWERS, function(cd) tr(paste0("answer.", cd)), ""))
      form <- tagList(lapply(ws$interventions, function(mid) {
        nm <- m$Name[match(mid, m$ID)]
        div(class = "card card-body mb-3",
          h5(mid, if (!is.na(nm)) paste(" \u2014", nm) else tagList(" ", tr("not_in_register"))),
          h6(tr("poll_title")),
          fluidRow(lapply(ws$poll$criteria, function(cr) column(4,
            selectInput(ns(paste0("a_", workshop_rank_col(mid, cr))), tr(paste0("criterion.", cr)),
                        choices = c(" " = "", stats::setNames(scale_vals, gsub("-", "\u2212", scale_vals, fixed = TRUE))))))),
          if (ws$tenets_on) tagList(h6(tr("tenets_title")), lapply(EBM_TENETS$code, function(t) div(class = "mb-2",
            radioButtons(ns(paste0("a_", workshop_tenet_col(mid, t))), wp5_vocab_label("tenet", t, i18n),
                         choices = tenet_choices, selected = character(0), inline = TRUE),
            tags$small(class = "text-muted", tr(paste0("question.", t)))))))
      }), p(class = "small text-muted", tr("translation_note")),
      actionButton(ns("save_participant"), tr("save_participant"), icon = icon("save"), class = "btn-primary"))
      tagList(consent_box, conditionalPanel(sprintf("input['%s'] == true", ns("consent")), form))
    })
    observeEvent(input$save_participant, {
      ws <- current(); req(ws)
      if (!isTRUE(ws$consent) && !isTRUE(input$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      cols <- workshop_answer_columns(ws)
      vals <- vapply(cols, function(cl) { v <- input[[paste0("a_", cl)]]; if (length(v)) as.character(v[1]) else "" }, "")
      if (!any(nzchar(vals))) { showNotification(tr("nothing_to_save"), type = "warning"); return() }
      row <- as.data.frame(as.list(vals), stringsAsFactors = FALSE, check.names = FALSE)
      st <- modify_store(function(st) {
        w <- workshop_get(st, ws$id); w$consent <- TRUE
        workshop_set(st, workshop_append(w, row, "form"))
      })
      if (!is.null(st)) showNotification(paste(tr("saved_as"), utils::tail(workshop_get(st, ws$id)$respondents$RespondentId, 1)),
                                         type = "message")
    })

    # ---- Import ----
    parsed <- reactiveVal(NULL)
    output$template <- downloadHandler(
      filename = function() "workshop_template.xlsx",
      content = function(file) openxlsx::saveWorkbook(workshop_template_wb(current(), measures(), i18n), file, overwrite = TRUE))
    observeEvent(input$upload, {
      f <- input$upload; ws <- current(); req(f, ws)
      parsed(tryCatch(workshop_parse_import(readiness_read_file(f$datapath, f$name), ws), error = function(e) {
        debug_log(paste("WP5 workshop: import failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_workshop.context_import"), type = "error")
        NULL
      }))
    })
    output$import_preview <- renderUI({
      pr <- parsed()
      if (is.null(pr)) return(NULL)
      if (!isTRUE(pr$ok)) return(div(class = "alert alert-warning", tr(paste0("import_error.", pr$error)), " ",
                                     if (length(pr$expected)) tags$small(paste(pr$expected, collapse = ", "))))
      tagList(
        p(tr("import_rows"), " ", nrow(pr$rows), " \u00b7 ", tr("import_blanked"), " ", pr$blanked, " \u00b7 ",
          tr("import_ignored"), " ", length(pr$ignored), " \u00b7 ", tr("import_dropped"), " ", pr$dropped_empty),
        if (length(pr$ignored)) tags$small(class = "text-muted d-block", paste(pr$ignored, collapse = ", ")),
        if (nrow(pr$rows)) actionButton(ns("import_confirm"), paste(tr("import_add"), nrow(pr$rows)), class = "btn-primary"))
    })
    observeEvent(input$import_confirm, {
      pr <- parsed(); ws <- current(); req(isTRUE(pr$ok), nrow(pr$rows) > 0, ws)
      if (!isTRUE(ws$consent)) { showNotification(tr("consent_required"), type = "warning"); return() }
      modify_store(function(st) workshop_set(st, workshop_append(workshop_get(st, ws$id), pr$rows, "import")))
      parsed(NULL)
      showNotification(paste(tr("import_added"), nrow(pr$rows)), type = "message")
    })

    # ---- Participants ----
    respondents_view <- reactive({
      ws <- current(); req(ws)
      r <- ws$respondents
      data.frame(stats::setNames(list(r$RespondentId, r$EnteredAt,
                                      vapply(r$Source, function(x) as.character(tr(paste0("source.", x))), "")),
                                 c(tr("col_participant"), tr("col_date"), tr("col_source"))),
                 check.names = FALSE, stringsAsFactors = FALSE)
    })
    output$respondent_table <- DT::renderDT(DT::datatable(respondents_view(), selection = "multiple",
                                                          rownames = FALSE, options = list(pageLength = 10)))
    pending_delete <- reactiveVal(character(0))
    observeEvent(input$delete_resp, {
      ws <- current(); sel <- input$respondent_table_rows_selected; req(ws, length(sel) > 0)
      pending_delete(ws$respondents$RespondentId[sel])
      showModal(modalDialog(p(tr("delete_resp_text"), " ", paste(pending_delete(), collapse = ", ")),
        footer = tagList(modalButton(tr("cancel")), actionButton(ns("delete_resp_confirm"), tr("delete_selected"), class = "btn-danger"))))
    })
    observeEvent(input$delete_resp_confirm, {
      ws <- current(); ids <- pending_delete(); req(ws, length(ids) > 0)
      modify_store(function(st) workshop_set(st, workshop_delete_respondents(workshop_get(st, ws$id), ids)))
      pending_delete(character(0)); removeModal()
      showNotification(paste(tr("deleted"), length(ids)), type = "warning")
    })

    # ---- Results ----
    output$results <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (!workshop_has_respondents(ws)) return(div(class = "alert alert-light", tr("no_participants")))
      m <- measures()
      name_of <- function(id) { nm <- m$Name[match(id, m$ID)]; if (is.na(nm)) paste(id, tr("not_in_register")) else paste(id, "\u2014", nm) }
      ps <- workshop_poll_summary(ws); ct <- workshop_poll_counts(ws)
      bars <- function(mid, cr) {
        sub <- ct[ct$measure == mid & ct$criterion == cr, ]
        mx <- max(1L, sub$n)
        div(class = "d-flex align-items-end", style = "height: 40px; gap: 2px;", lapply(seq_len(nrow(sub)), function(i)
          div(title = paste0(sub$value[i], ": ", sub$n[i]), class = "bg-info",
              style = sprintf("width: 14px; height: %dpx;", max(1L, round(36 * sub$n[i] / mx))))))
      }
      ts <- workshop_tenet_summary(ws)
      band <- function(med, nv) if (nv < WORKSHOP_MIN_VALID || is.na(med)) "#e9ecef" else if (med >= 4) "#c3e6cb" else if (med >= 3) "#ffeeba" else "#f5c6cb"
      tagList(
        p(strong(tr("n_participants")), ": ", nrow(ws$respondents)),
        h5(tr("ranking_title")),
        tags$table(class = "table table-sm small",
          tags$thead(tags$tr(tags$th(tr("col_measure")), tags$th(tr("col_criterion")), tags$th(tr("col_n")),
                             tags$th(tr("col_median")), tags$th(tr("col_mean")), tags$th(""))),
          tags$tbody(lapply(seq_len(nrow(ps)), function(i) tags$tr(
            tags$td(name_of(ps$measure[i])), tags$td(tr(paste0("criterion.", ps$criterion[i]))), tags$td(ps$n[i]),
            tags$td(if (is.na(ps$median[i])) "" else format(ps$median[i])),
            tags$td(if (is.na(ps$mean[i])) "" else sprintf("%.2f", ps$mean[i])),
            tags$td(bars(ps$measure[i], ps$criterion[i])))))),
        if (nrow(ts)) tagList(h5(class = "mt-3", tr("heat_title")),
          tags$table(class = "table table-sm small",
            tags$thead(tags$tr(tags$th(tr("col_tenet")), lapply(ws$interventions, function(mid) tags$th(mid)))),
            tags$tbody(lapply(EBM_TENETS$code, function(t) tags$tr(tags$td(wp5_vocab_label("tenet", t, i18n)),
              lapply(ws$interventions, function(mid) {
                s <- ts[ts$measure == mid & ts$tenet == t, ]
                tags$td(style = paste0("background:", band(s$median, s$n_valid), ";"),
                        title = paste0("n = ", s$n_valid, "; ", tr("answer.dont_know"), ": ", s$n_dont_know),
                        if (s$n_valid < WORKSHOP_MIN_VALID) tr("too_few") else format(s$median))
              })))))))
    })
    output$export <- downloadHandler(
      filename = function() paste0("workshop_", current()$id %||% "", ".xlsx"),
      content = function(file) openxlsx::saveWorkbook(workshop_export_wb(current(), i18n), file, overwrite = TRUE))

    # ---- Apply to register (spec §6) ----
    output$apply <- renderUI({
      ws <- current()
      if (is.null(ws)) return(div(class = "alert alert-light", tr("no_workshop")))
      if (is.null(register)) return(div(class = "alert alert-warning", tr("apply_unavailable")))
      if (!ws$tenets_on) return(div(class = "alert alert-light", tr("apply_tenets_off")))
      m <- measures()
      pr <- workshop_writeback_proposal(ws, m)
      send <- function(input_id, mid) sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns(input_id), mid)
      tagList(p(class = "small text-muted", tr("apply_intro")), lapply(ws$interventions, function(mid) {
        i <- match(mid, m$ID)
        if (is.na(i)) return(div(class = "card card-body mb-2", strong(mid), " ", tr("not_in_register")))
        rows <- pr[pr$measure == mid, ]
        last <- workshop_last_apply(ws, mid)
        div(class = "card card-body mb-3",
          h5(mid, " \u2014 ", m$Name[i]),
          if (nzchar(m$TenetSource[i])) tags$small(class = "text-muted d-block", tr("tenet_source"), ": ", m$TenetSource[i]),
          tags$table(class = "table table-sm small",
            tags$thead(tags$tr(tags$th(tr("col_tenet")), tags$th(tr("col_current")), tags$th(tr("col_workshop")), tags$th(tr("col_proposed")))),
            tags$tbody(lapply(seq_len(nrow(rows)), function(k) tags$tr(class = if (rows$changed[k]) "table-warning",
              tags$td(wp5_vocab_label("tenet", rows$tenet[k], i18n)), tags$td(level_label(rows$current[k])),
              tags$td(if (is.na(rows$median[k])) "" else format(rows$median[k]), " (", rows$n_valid[k], ")"),
              tags$td(if (is.na(rows$proposed[k])) tr("too_few") else level_label(rows$proposed[k])))))),
          if (any(rows$changed)) tags$button(class = "btn btn-primary btn-sm", onclick = send("apply_measure", mid), tr("apply_button"))
          else tags$small(class = "text-muted", tr("matches_register")),
          if (!is.null(last)) tags$button(class = "btn btn-outline-secondary btn-sm ml-2", onclick = send("undo_measure", mid), tr("undo_button")))
      }))
    })
    observeEvent(input$apply_measure, {
      ws <- current(); mid <- input$apply_measure; req(ws, !is.null(register), mid %in% ws$interventions)
      ch <- workshop_apply_change(ws, mid, measures(), tr("source_template"))
      if (is.null(ch)) return()
      if (!isTRUE(register$update(mid, ch$after))) { showNotification(tr("measure_gone"), type = "warning"); return() }
      # re-read the project AFTER the register write (modify_store starts from project_data_reactive())
      modify_store(function(st) workshop_set(st, workshop_record_apply(workshop_get(st, ws$id), mid, ch$before, ch$after)))
      showNotification(paste(tr("applied"), mid), type = "message")
    })
    observeEvent(input$undo_measure, {
      ws <- current(); mid <- input$undo_measure; req(ws, !is.null(register), mid %in% ws$interventions)
      e <- workshop_last_apply(ws, mid); req(e)
      chk <- workshop_undo_check(e, measures())
      if (identical(chk, "gone")) { showNotification(tr("measure_gone"), type = "warning"); return() }
      if (identical(chk, "changed")) { showNotification(tr("undo_changed"), type = "warning"); return() }
      if (!isTRUE(register$update(mid, e$before))) { showNotification(tr("measure_gone"), type = "warning"); return() }
      modify_store(function(st) workshop_set(st, workshop_drop_last_apply(workshop_get(st, ws$id), mid)))
      showNotification(paste(tr("undone"), mid), type = "message")
    })

    invisible(list(store = store))
  })
}
```

Wiring:
- `functions/ui_sidebar.R`: after the `pims_readiness` sub-item add `bs4SidebarMenuSubItem(safe_t("ui.sidebar.workshop_elicitation", i18n_obj = i18n), tabName = "pims_workshops"),`.
- `app.R`: add `"modules/wp5_workshop_module.R",      # WS-10 D5.2 workshop elicitation` after the readiness module in the source list; add `bs4TabItem(tabName = "pims_workshops", wp5_workshop_ui("pims_ws", i18n)),` after the `pims_readiness` tab item; replace `response_measures_server("resp_meas", project_data, session_i18n)` with
  ```r
  resp_register <- response_measures_server("resp_meas", project_data, session_i18n)
  # WS-10: the workshop page writes tenet results through the register api (after the response server)
  pims_workshops_data <- wp5_workshop_server("pims_ws", project_data, session_i18n, register = resp_register)
  ```

- [ ] **Step 4: Run** `'^wp5-workshop-module$'`, `'^wp5-workshop$'`, `'^response-module$'`, `'^modules$'`, `'^i18n-enforcement$'` (one process each) → PASS; audit `missing=0 hardcoded=0` (add any missing `# i18n-ref:` sentinel the audit names). If `showModal()`/`removeModal()` are unsupported by the installed shiny's MockShinySession, keep the modals and make the test drive the confirm input directly (the confirm handlers must not depend on the modal having been shown, only on the pending selection). If a testServer expectation fails only because `updateSelectInput` does not set `input$workshop` in testServer, set `workshop =` explicitly in that test (inputs are not changed by update* calls in testServer).
- [ ] **Step 5: Smoke run** — start the app (`Rscript run_app.R`, foreground with a timeout of 90 s, or `shiny::runApp` in a background-free way) only if Chrome/playwright is available to the implementer; otherwise skip and say so in the report. Never leave a background R process running.
- [ ] **Step 6: Commit** (`modules/wp5_workshop_module.R`, `functions/ui_sidebar.R`, `app.R`, the module test) — `feat(wp5): PIMS workshop elicitation page with tenet write-back and undo (WS-10)`.

---

### Task 7: Release 1.32.0 and full verification

**Files:** `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`

- [ ] **Step 1: Release files** following the 1.31.0 release commit's conventions (`git -C <wt> log --oneline -12` → `chore(release): 1.31.0`; `git show` it): `VERSION` 1.32.0; `DESCRIPTION` `Version: 1.32.0`; `VERSION_INFO.json`: version 1.32.0, version_name "WP5 workshop elicitation (D5.2)", release_date today, release_type minor, previous_version 1.31.0, features ending " (WS-10).": the PIMS "Workshop elicitation (D5.2)" page (several workshops per project; ranking poll on −5…+5 or 1–4 for importance / feasibility / long-term impact; the 11-tenet rating with the D5.2 Annex 4 guiding questions; anonymous participants via form or xlsx/csv template; results and xlsx export); per-measure write-back of the tenet results into the Response register with Undo and a `TenetSource` note; guiding questions verified against D5.2 Annex 4; migration note "projects with workshops need app 1.32.0". `CHANGELOG.md`: `## [1.32.0] - <today>` under `## [Unreleased]` with `### Added (WP5 workshop elicitation — spec 2026-10-18 WS-10)` and `### Notes` (write-back mapping: median ≥ 4 full, 3–4 intermediate for ecological effectiveness and minimal otherwise, < 3 minimal, at least 3 ratings; poll results are not written to the register; no names or free text are collected; the register gains a `TenetSource` column).
- [ ] **Step 2: Full verification** (one Rscript per chunk, foreground, sequential): filters `'^[a-c]'`, `'^[d-h]'`, `'^[i-l]'`, `'^[m-o]'`, `'^[p-s]'`, `'^[t-z]'` (split a chunk that exceeds 10 minutes) → no failures; `micromamba run -n shiny python -m pytest scripts/tests -q -p no:cacheprovider` → all pass; audit `missing=0 hardcoded=0`; `Rscript deployment/pre-deploy-check.R` → all pass. Attribute any failure (branch vs pre-existing, using the main checkout read-only) and report it; do not fix it in this task.
- [ ] **Step 3: Commit** release files only — `chore(release): 1.32.0 — WP5 workshop elicitation (WS-10)`.
