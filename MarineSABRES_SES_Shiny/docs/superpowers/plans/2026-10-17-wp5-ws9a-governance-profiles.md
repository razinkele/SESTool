# WP5 WS-9a Governance Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the D5.4 governance profiles: a curated, PDF-verified data file; a "Load DA actor list" in PIMS with a D5.4 roles column; barrier/enabler and recommendation cards ("Add to register") in the Response module; an optional `Policy_Target` on indicators; Greenland, the Faroes and seven regional bodies in the country database.

**Architecture:** One hand-curated JSON (`data/wp5_governance_profiles.json`) checked word-for-word against the D5.4 PDF by pytest. Pure R helpers (`functions/stakeholder_schema.R`, `functions/wp5_governance.R`) feed the PIMS stakeholder module (seeding) and a new sub-module `modules/wp5_governance_context_module.R` mounted as a Response-module tab; the sub-module adds measures through a small register API the Response module passes in, so the register's own state stays the single writer.

**Tech Stack:** R ≥ 4.4.1, Shiny + bs4Dash, shiny.i18n, jsonlite, testthat 3; Python (micromamba env `shiny`) with PyMuPDF (`fitz`), python-docx, pytest 8.4.2.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-17-wp5-ws9a-governance-profiles-design.md` (read it; it is the authority). Source audit: `docs/wp5-source-audit/2026-10-11/D_D5.4_governance.md` (its line numbers refer to an older text extraction; use the page numbers in this plan).

All paths below are relative to `MarineSABRES_SES_Shiny/` in the worktree `C:/Users/arturas.baziukas/wt-ws9a` (branch `feat/wp5-ws9a-governance-profiles`). The git root is one level up: use `git -C C:/Users/arturas.baziukas/wt-ws9a ...`, never `cd <path> && git`.

## Global Constraints

- **D5.4 sources are not in the worktree or on CI.** `WP5/` is untracked. The only copy is in the main checkout: `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5`. Python tests that need it skip when it is absent (env var `WP5_DIR` or that default path). CI does not run pytest.
- Python only through `micromamba run -n shiny python <script file>` (no venv, no pip). **Never run `python -` / `python3 -` (stdin), a bare `python`, or a heredoc piped into micromamba python, and never run Python in the background**: a console-less stdin starts the interactive REPL, which loops a traceback forever and filled the disk on 2026-10-17. Write scripts to files and run them in the foreground.
- R tests from the app dir, one file filter per process, user library first:
  `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^wp5-governance-profiles$')"`
  "package built under R version 4.4.3" warnings are known environment noise.
- D5.4 roles = `STAKEHOLDER_TYPES` codes (`Inputters, Extractors, Regulators, Affectees, Beneficiaries, Influencers`), `;`-joined in `NERoles`, canonical order = `STAKEHOLDER_TYPES` order.
- NPG dimension ids, in this order everywhere: `knowledge, collaboration, values_conflicts, legitimacy, cross_sectoral`. Polarity: `enabler` (D5.4 "What is working well"), `barrier` ("Areas of improvement").
- `WP5_GOVERNANCE_MIN_APP_VERSION <- "1.30.0"`. Stamp on save when any stakeholder has non-empty `NERoles` or `SourceId`, or any element has non-empty `Policy_Target`.
- Card, actor, legal-instrument, gap and recommendation text is English source data shown with a "Source text (English)" badge; every label goes through `i18n$t()` in 9 languages (en, es, fr, de, lt, pt, it, no, el). The audit `micromamba run -n shiny python scripts/_i18n_audit.py` must show `missing=0` and `hardcoded=0` on its "Totals:" line. Dynamic keys get `# i18n-ref:` sentinels. Never edit `translations/_merged_translations.json`.
- Logging via `debug_log()`; user errors via `format_user_error(e, i18n = i18n, context_key = ...)`.
- Module tests re-bind real functions from `.GlobalEnv` before `testServer()` (helper-stubs.R shadows some modules).
- Commits: message in a file, `git -C <wt> commit -F <file>`; end every message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_013pgU49PTbBYa3XxbHfFRC6`. `docs/` is gitignored (`git add -f`). Never add `__pycache__/`.

## Rulings made while planning

1. **Existing bug fixed first (Task 3).** `generate_element_id(prefix, n)` returns *all* ids `1..n` for a single `n`, and the stakeholder, engagement, communication and register add-handlers pass their running counter to it: since v1.16.5 the second added stakeholder/measure creates two rows (both with the new name, one reusing an old ID). A new `next_element_id(prefix, n)` returns one id; the four call sites use it. Seeding and "Add to register" depend on it.
2. **Profiles schema gains `source_doc`** (`d54`, `char_tus`, `char_mac`) on actors, so the pytest knows which document to check a name against; the spec example's `pims_type` value `government_regulators` is corrected to `governmentregulators` (Task 1 amends the spec).
3. **Cards come from the summary Tables 5–7 only** (spec §3.1); a card's polarity is checked by the column it is found in.
4. **Recommendations: titles are the numbered headings of the summary sections** (D5.4 §4.1–4.3 "Recommendations"); the plan fixes each recommendation's `ebm_code`, `rm_type` and `governance_level` (table in Task 1) so the curator does not judge them.
5. **Sub-area filter keeps DA-wide items**: actors/cards without `sub_area` (e.g. NEAFC) are always included.
6. **The governance tab's DA selector defaults to "Project's demonstration area"** (empty value = `metadata$da_site`), so it follows the project without update observers.
7. **Recommendation "Add to register" goes through a register API** passed from `response_measures_server()`; the sub-module never writes `response_measures` itself (the register reloads its state only on project change, so a direct write would be overwritten).
8. **The profiles loader caches only default-path loads** (fixes the WS-8 parked minor for this loader).

## Review Focus

1. A project with no DA, or a DA without a profile, opening PIMS stakeholders or the governance tab → hint, no error, and no seeding button (Task 6 and Task 7 tests).
2. Clicking "Add actors" twice, or after the user typed an actor by hand → no duplicate rows (Task 4 `seed_da_actors` tests; Task 6 module test).
3. Deselecting every sub-area in the seeding modal → only DA-wide actors are added, not all of them (Task 4 test).
4. An old project (12-column stakeholder frame, no `Policy_Target`) loaded and then extended → the add works and the new columns appear as `""` (Task 4 normaliser test; Task 6 module test).
5. "Add to register" clicked twice for the same recommendation → one measure (Task 7 test).

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `data/wp5_governance_profiles.json` | 1 | curated D5.4 profiles |
| `scripts/tests/test_wp5_governance_profiles.py` | 1 | verbatim check against D5.4 and characterisation docs |
| `tests/testthat/test-wp5-governance-profiles.R` | 1, 2 | profile + country-DB schema tests |
| `.gitattributes` | 1 | LF for the profiles JSON |
| `data/country_governance_db.json` | 2 | GL, FO, seven bodies |
| `functions/data_structure.R` | 3, 4 | `next_element_id()`; empty-project columns; JSON load hook |
| `modules/pims_stakeholder_module.R`, `modules/response_module.R` | 3, 6, 7 | id fix; seeding UI; governance tab mount |
| `constants.R` | 4, 8 | WS-9a constants; `Policy_Target` column |
| `functions/stakeholder_schema.R` (new) | 4 | stakeholder schema + display |
| `functions/wp5_governance.R` (new) | 4 | loader + pure helpers |
| `global.R` | 4 | source the two new files |
| `translations/modules/wp5_governance.json` (new), `translations/modules/indicator_registry.json` | 5 | keys |
| `modules/wp5_governance_context_module.R` (new), `app.R` | 7 | governance tab |
| `functions/indicator_snapshot.R`, `functions/isa_form_builders.R`, `modules/isa_data_entry_module.R` | 8 | `Policy_Target` |
| `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md` | 9 | release 1.30.0 |

---

### Task 1: Curated governance profiles and their verification

**Files:**
- Create: `data/wp5_governance_profiles.json`, `scripts/tests/test_wp5_governance_profiles.py`, `tests/testthat/test-wp5-governance-profiles.R`
- Modify: `.gitattributes` (app dir); spec (docs, force-add) — ruling 2

**Interfaces:**
- Produces: the JSON described in spec §3.2 plus `actors[].source_doc`; ids `tus_*`, `arc_*`, `mac_*`; recommendations `tus_r01..r04`, `arc_r01..r04`, `mac_r01..r06`, each with ≥ 1 `implementing_actor_ids`.

This task is curation from a PDF. Work from extracted text, copy text exactly (the test compares letters and digits only, so line breaks, hyphenation, quotes and punctuation do not matter — but every word must be the PDF's).

- [ ] **Step 1: Extract the sources to your scratch folder** (not into the repo). Use `C:/Users/arturas.baziukas/wt-ws9a/.superpowers/` as scratch (git-ignored). Run in the foreground:

```bash
SRC="C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/WP5/Task 5.4 Governance Measures & Targets"
OUT=C:/Users/arturas.baziukas/wt-ws9a/.superpowers/ws9a-src; mkdir -p "$OUT"
PDF="$SRC/Deliverable 5.4/final version/MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf"
pdftotext -enc UTF-8 -layout -f 22 -l 37 "$PDF" "$OUT/d54_findings_p22-37.txt"      # §4 findings, Tables 5-7, recommendations
pdftotext -enc UTF-8 -layout -f 52 -l 78 "$PDF" "$OUT/d54_annex1_arctic.txt"
pdftotext -enc UTF-8 -layout -f 79 -l 113 "$PDF" "$OUT/d54_annex2_macaronesia.txt"
pdftotext -enc UTF-8 -layout -f 114 -l 136 "$PDF" "$OUT/d54_annex3_tuscan.txt"
```

Tables 5–7 are two-column tables; the `-layout` text interleaves the columns. For the cards, write `$OUT/dump_cols.py` and run `micromamba run -n shiny python "$OUT/dump_cols.py" "$PDF" > "$OUT/cards_by_column.txt"`:

```python
"""Print Table 5-7 text column by column (scratch helper, not committed)."""
import sys

import fitz

sys.stdout.reconfigure(encoding="utf-8")
doc = fitz.open(sys.argv[1])
for table, pages in (("Table 5 (Arctic)", range(24, 28)), ("Table 6 (Macaronesia)", range(29, 32)),
                     ("Table 7 (Tuscan)", range(34, 36))):
    for col, lo, hi in (("DIMENSION", 0, 180), ("WORKING WELL = enabler", 180, 335),
                        ("AREAS OF IMPROVEMENT = barrier", 335, 10_000)):
        print(f"\n===== {table} | {col} =====")
        for p in pages:
            words = [w for w in doc[p - 1].get_text("words") if lo <= w[0] < hi and w[1] < 770]
            words.sort(key=lambda w: (round(w[1] / 3), w[0]))
            line, last = [], None
            for w in words:
                y = round(w[1] / 3)
                if last is not None and y != last:
                    print(" ".join(line)); line = []
                line.append(w[4]); last = y
            if line:
                print(" ".join(line))
            print(f"--- end of PDF page {p} (printed {p - 1}) ---")
```

For the characterisation grids write `$OUT/dump_docx.py` and run it on both documents (`.../Case study work/Tuscany archipelago/MarineSABRES_Characterisation_TuscanArchipelago.docx` → `$OUT/char_tus.txt`; `.../Case study work/Macaronesia/MarineSABRES_Characterisation_Macaronesia.docx` → `$OUT/char_mac.txt`):

```python
"""Dump a .docx's paragraphs and table cells (scratch helper, not committed)."""
import sys

import docx

sys.stdout.reconfigure(encoding="utf-8")
d = docx.Document(sys.argv[1])
for para in d.paragraphs:
    if para.text.strip():
        print(para.text)
for ti, t in enumerate(d.tables):
    print(f"\n===== table {ti} =====")
    for r in t.rows:
        print(" | ".join(c.text.strip().replace("\n", " / ") for c in r.cells))
```

(The Tuscan stakeholder typology and power/interest grid are around the "stakeholder" section of the Tuscan document; the Madeira typology and grid are in the Macaronesia document's PIMS section, which notes Azores "not completed" and Canaries "not found".)

- [ ] **Step 2: Write the R schema test** `tests/testthat/test-wp5-governance-profiles.R`:

```r
# tests/testthat/test-wp5-governance-profiles.R
# WS-9a (spec 2026-10-17 §3.4): schema of the curated D5.4 profiles.
library(testthat)

gp <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_governance_profiles.json"), simplifyVector = FALSE)
dims <- c("knowledge", "collaboration", "values_conflicts", "legitimacy", "cross_sectoral")
pims_types <- c("resource_users", "industrybusiness", "governmentregulators", "ngocivil_society",
                "scientificacademic", "local_communities", "indigenous_groups", "other")
ebm_types <- EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"]
ids_of <- function(xs) vapply(xs, `[[`, "", "id")

test_that("top level: the five dimensions and one profile per DA site", {
  expect_equal(unlist(gp$dimensions), dims)
  expect_setequal(names(gp$das), c("tuscan_archipelago", "arctic_nea", "macaronesia"))
  expect_setequal(unname(vapply(gp$das, `[[`, "", "da_site")), DA_SITES)
  expect_equal(gp$source$doi, "10.48481/rifs.2026.011")
})

test_that("ids are unique and carry their DA prefix", {
  pre <- c(tuscan_archipelago = "tus_", arctic_nea = "arc_", macaronesia = "mac_")
  all_ids <- character(0)
  for (k in names(gp$das)) {
    d <- gp$das[[k]]
    ids <- c(ids_of(d$actors), ids_of(d$cards), ids_of(d$recommendations))
    expect_true(all(startsWith(ids, pre[[k]])), info = k)
    all_ids <- c(all_ids, ids)
  }
  expect_false(anyDuplicated(all_ids) > 0)
})

test_that("sub-areas per DA", {
  expect_length(gp$das$tuscan_archipelago$sub_areas, 0L)
  expect_equal(unlist(gp$das$arctic_nea$sub_areas), c("greenland", "iceland", "faroe_islands"))
  expect_equal(unlist(gp$das$macaronesia$sub_areas), c("azores", "madeira", "canaries"))
})

test_that("actors: roles, types, levels, grid values and source documents are valid", {
  for (k in names(gp$das)) {
    d <- gp$das[[k]]
    expect_gte(length(d$actors), 5L)
    for (a in d$actors) {
      info <- paste(k, a$id)
      expect_true(nzchar(a$name), info = info)
      expect_gte(length(a$ne_roles), 1L)
      expect_true(all(unlist(a$ne_roles) %in% STAKEHOLDER_TYPES), info = info)
      expect_true(a$pims_type %in% pims_types, info = info)
      expect_true(a$level %in% GOVERNANCE_LEVELS, info = info)
      expect_true(a$source_doc %in% c("d54", "char_tus", "char_mac"), info = info)
      expect_true(is.null(a$sub_area) || a$sub_area %in% unlist(d$sub_areas), info = info)
      for (f in c("power", "interest")) expect_true(is.null(a[[f]]) || a[[f]] %in% c("HIGH", "LOW"), info = info)
      expect_true(nzchar(a$source_ref), info = info)
    }
  }
})

test_that("grids: Tuscany has one, Madeira only in Macaronesia, none in the Arctic", {
  has_grid <- function(a) !is.null(a$power) || !is.null(a$interest)
  expect_true(any(vapply(gp$das$tuscan_archipelago$actors, has_grid, logical(1))))
  mac <- gp$das$macaronesia$actors
  expect_true(any(vapply(mac, has_grid, logical(1))))
  expect_true(all(vapply(Filter(has_grid, mac), function(a) identical(a$sub_area, "madeira"), logical(1))))
  expect_false(any(vapply(gp$das$arctic_nea$actors, has_grid, logical(1))))
  expect_true(isTRUE(gp$das$tuscan_archipelago$grid_available))
  expect_null(gp$das$tuscan_archipelago$grid_note)
  expect_false(isTRUE(gp$das$arctic_nea$grid_available))
  expect_equal(gp$das$arctic_nea$grid_note, "no_published_grid")
  expect_equal(gp$das$macaronesia$grid_note, "grid_madeira_only")
})

test_that("cards: every DA covers every dimension and both polarities, cited to its table", {
  tab <- c(arctic_nea = "D5.4 Table 5", macaronesia = "D5.4 Table 6", tuscan_archipelago = "D5.4 Table 7")
  for (k in names(gp$das)) {
    cards <- gp$das[[k]]$cards
    for (cd in cards) {
      expect_true(cd$dimension %in% dims, info = cd$id)
      expect_true(cd$polarity %in% c("enabler", "barrier"), info = cd$id)
      expect_gte(nchar(cd$text), 15L)
      expect_false(grepl("^\\s*[o•]\\s", cd$text), info = cd$id)       # no bullet glyph
      expect_true(startsWith(cd$source_ref, tab[[k]]), info = cd$id)
      expect_true(is.null(cd$sub_area) || cd$sub_area %in% unlist(gp$das[[k]]$sub_areas), info = cd$id)
    }
    # A table cell may be empty in the source, so require each dimension once and each polarity once
    expect_setequal(unique(vapply(cards, `[[`, "", "dimension")), dims)
    expect_setequal(unique(vapply(cards, `[[`, "", "polarity")), c("enabler", "barrier"))
  }
})

test_that("recommendations: 4 / 6 / 4 with valid codes and resolvable implementing actors", {
  expect_length(gp$das$arctic_nea$recommendations, 4L)
  expect_length(gp$das$macaronesia$recommendations, 6L)
  expect_length(gp$das$tuscan_archipelago$recommendations, 4L)
  for (k in names(gp$das)) {
    actor_ids <- ids_of(gp$das[[k]]$actors)
    for (r in gp$das[[k]]$recommendations) {
      expect_true(r$ebm_code %in% ebm_types && substr(r$ebm_code, 1, 1) %in% c("1", "2", "4"), info = r$id)
      expect_true(r$rm_type %in% names(RM_TYPE_CODES), info = r$id)
      expect_true(r$governance_level %in% GOVERNANCE_LEVELS, info = r$id)
      expect_true(all(unlist(r$target_roles) %in% STAKEHOLDER_TYPES), info = r$id)
      expect_gte(length(r$implementing_actor_ids), 1L)
      expect_true(all(unlist(r$implementing_actor_ids) %in% actor_ids), info = r$id)
      expect_true(nzchar(r$title) && nzchar(r$text) && nzchar(r$source_ref), info = r$id)
    }
  }
})

test_that("legal instruments and gaps are present for every DA", {
  for (k in names(gp$das)) {
    expect_gte(length(gp$das[[k]]$legal_instruments), 3L)
    expect_gte(length(gp$das[[k]]$gaps), 3L)
    for (li in gp$das[[k]]$legal_instruments) expect_true(li$level %in% GOVERNANCE_LEVELS, info = li$name)
  }
})
```

- [ ] **Step 3: Write the pytest** `scripts/tests/test_wp5_governance_profiles.py`:

```python
"""Verify data/wp5_governance_profiles.json against the D5.4 sources (spec 2026-10-17 WS-9a §3.4).

Comparison keeps only letters and digits (lower-cased), so line breaks, hyphenation,
quotes and punctuation do not matter, but every word must be the source's.
"""
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
T54 = WP5 / "Task 5.4 Governance Measures & Targets"
D54 = T54 / "Deliverable 5.4" / "final version" / "MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf"
CHAR = {"char_tus": T54 / "Case study work" / "Tuscany archipelago" / "MarineSABRES_Characterisation_TuscanArchipelago.docx",
        "char_mac": T54 / "Case study work" / "Macaronesia" / "MarineSABRES_Characterisation_Macaronesia.docx"}
TABLE_PAGES = {"arctic_nea": range(24, 28), "macaronesia": range(29, 32), "tuscan_archipelago": range(34, 36)}  # PDF pages
COL_X = (180, 335)       # x where the "working well" and "areas of improvement" columns start
FOOTER_Y = 770
PROFILES = json.loads((APP / "data" / "wp5_governance_profiles.json").read_text(encoding="utf-8"))
needs_src = pytest.mark.skipif(not D54.exists(), reason="D5.4 sources not available (WP5/ is not in git)")


def key(s):
    return re.sub(r"[^0-9a-z]", "", unicodedata.normalize("NFKC", s).lower())


@lru_cache(maxsize=None)
def doc():
    import fitz
    return fitz.open(str(D54))


@lru_cache(maxsize=None)
def full_text():
    return key(" ".join(p.get_text() for p in doc()))


@lru_cache(maxsize=None)
def column_text(da, polarity):
    lo, hi = (COL_X[0], COL_X[1]) if polarity == "enabler" else (COL_X[1], 10_000)
    parts = []
    for p in TABLE_PAGES[da]:
        ws = [w for w in doc()[p - 1].get_text("words") if lo <= w[0] < hi and w[1] < FOOTER_Y]
        ws.sort(key=lambda w: (round(w[1] / 3), w[0]))
        parts.append(" ".join(w[4] for w in ws))
    return key(" ".join(parts))


@lru_cache(maxsize=None)
def docx_text(name):
    import docx
    d = docx.Document(str(CHAR[name]))
    cells = [c.text for t in d.tables for r in t.rows for c in r.cells]
    return key(" ".join([p.text for p in d.paragraphs] + cells))


def items(kind):
    return [(da, x) for da, prof in PROFILES["das"].items() for x in prof[kind]]


def test_key_ignores_layout_only():
    assert key("Transpar-\nency: “NEAFC”") == key("Transparency: NEAFC")
    assert key("a b") != key("a c")


@needs_src
@pytest.mark.parametrize("da,card", items("cards"), ids=lambda v: v.get("id", v) if isinstance(v, dict) else v)
def test_card_text_is_in_its_table_column(da, card):
    assert key(card["text"]) in column_text(da, card["polarity"]), card["id"]


@needs_src
@pytest.mark.parametrize("da,rec", items("recommendations"), ids=lambda v: v.get("id", v) if isinstance(v, dict) else v)
def test_recommendation_title_and_text_are_in_d54(da, rec):
    assert key(rec["title"]) in full_text(), rec["id"]
    assert key(rec["text"]) in full_text(), rec["id"]


@needs_src
@pytest.mark.parametrize("da,actor", items("actors"), ids=lambda v: v.get("id", v) if isinstance(v, dict) else v)
def test_actor_name_is_in_its_source(da, actor):
    src = full_text() if actor["source_doc"] == "d54" else docx_text(actor["source_doc"])
    assert key(actor["name"]) in src, actor["id"]


@needs_src
def test_a_made_up_card_is_rejected():
    assert key("Greenland publishes all fisheries data in real time") not in column_text("arctic_nea", "enabler")
```

- [ ] **Step 4: Run both to verify they fail** — `micromamba run -n shiny python -m pytest scripts/tests/test_wp5_governance_profiles.py -q -p no:cacheprovider` (expected: error, `data/wp5_governance_profiles.json` not found) and the R filter `'^wp5-governance-profiles$'` (expected: error, cannot open the file).

- [ ] **Step 5: Curate `data/wp5_governance_profiles.json`** (UTF-8, 2-space indent, LF). Shape (spec §3.2 plus `source_doc`):

```json
{
  "version": "1.0",
  "source": { "doc": "D5.4 Governance Arrangements (final)", "date": "2026-05-29", "doi": "10.48481/rifs.2026.011",
              "characterisations": ["MarineSABRES_Characterisation_TuscanArchipelago.docx", "MarineSABRES_Characterisation_Macaronesia.docx"] },
  "dimensions": ["knowledge", "collaboration", "values_conflicts", "legitimacy", "cross_sectoral"],
  "das": {
    "arctic_nea": {
      "da_site": "Arctic Northeast Atlantic",
      "sub_areas": ["greenland", "iceland", "faroe_islands"],
      "governance_levels": ["national", "regional_sea", "international"],
      "grid_available": false,
      "grid_note": "no_published_grid",
      "actors": [{ "id": "arc_a01", "name": "Ministry of Fisheries and Hunting", "level": "national", "sub_area": "greenland",
                   "ne_roles": ["Regulators"], "pims_type": "governmentregulators", "power": null, "interest": null,
                   "source_doc": "d54", "source_ref": "D5.4 Annex 1, p. 54" }],
      "legal_instruments": [{ "name": "...", "level": "national", "source_ref": "D5.4 Annex 1, p. ..." }],
      "cards": [{ "id": "arc_c01", "dimension": "knowledge", "polarity": "enabler", "sub_area": null,
                  "text": "Transparency at regional level: NEAFC and coastal state consultation documents (e.g. agreed records) are publicly available and enhance regional transparency.",
                  "source_ref": "D5.4 Table 5, p. 23" }],
      "gaps": [{ "text": "...", "source_ref": "D5.4 ..., p. ..." }],
      "recommendations": [{ "id": "arc_r01", "title": "...", "text": "...", "ebm_code": "1.4", "rm_type": "institutional",
                            "governance_level": "regional_sea", "target_roles": ["Regulators"],
                            "implementing_actor_ids": ["arc_a10"], "source_ref": "D5.4 §4.1, p. ..." }]
    },
    "macaronesia": { "da_site": "Macaronesia", "sub_areas": ["azores", "madeira", "canaries"], "grid_available": true, "grid_note": "grid_madeira_only" },
    "tuscan_archipelago": { "da_site": "Tuscan Archipelago", "sub_areas": [], "grid_available": true, "grid_note": null }
  }
}
```

Curation rules:
- **`source_ref`** cites the *printed* page number (PDF page − 1), e.g. `"D5.4 Table 5, p. 23"`, `"D5.4 Annex 1, p. 54"`, `"Characterisation Tuscan Archipelago, stakeholder grid"`.
- **Cards** (Tables 5, 6, 7 only — `cards_by_column.txt`): one card per bullet (`o …`), bullet glyph removed, the bold lead-in kept as the start of the text. Card ids `<da>_c01…` in table order. `dimension` from the row label (Table rows: "Incorporation of knowledge" → `knowledge`; "Collaborative structures" → `collaboration`; "Values, conflicts and decision making" / "Value centred …, trust, reduction of conflicts and compliance" → `values_conflicts`; "Inclusivity and legitimacy" / "Democratic legitimacy …" → `legitimacy`; "Cross-sectoral coordination …" → `cross_sectoral`). `polarity`: middle column → `enabler`, right column → `barrier`. Where a cell starts a group with a place label ("Iceland:", "Greenland:", "Azores:", "Madeira:", "Canary Islands:"), set `sub_area` on the bullets below it and do not include the label in the text. A bullet that continues on the next page is one card (join the parts).
- **Actors** (one row per entity; `source_doc` = where its `name` is printed verbatim):
  - Arctic (`d54`, Annex 1 and §4.1): Greenland — Ministry of Fisheries and Hunting; Greenland Fisheries and Hunting Control; Greenland Institute of Natural Resources. Iceland — the Ministry of Industries; Directorate of Fisheries; Marine and Freshwater Research Institute. Faroe Islands — the fisheries ministry (use the name as D5.4 prints it in Annex 1); Faroe Islands Fisheries Inspection; Faroe Marine Research Institute. DA-wide (`sub_area` null): ICES, NEAFC, Nordic Council of Ministers, Marine Stewardship Council. Levels: national for the nine; `regional_sea` for NEAFC; `international` for ICES, Nordic Council, MSC. Roles: ministries/inspections/NEAFC `Regulators`; research institutes, ICES `Influencers`; MSC `Influencers`; Nordic Council `Influencers`. `pims_type`: authorities `governmentregulators`; institutes and ICES `scientificacademic`; MSC `ngocivil_society`; Nordic Council `governmentregulators`.
  - Macaronesia: Azores, Madeira and Canary Islands organisations named in Annex 2's actors sections (`d54`; `sub_area` accordingly; level `regional` for autonomous-region bodies, `island` for Cabildos, `local` for municipalities, `national` for state bodies such as MITECO, MAPA, DGRM, Puertos del Estado); plus the Madeira stakeholder groups of the characterisation grid (`char_mac`, `sub_area` "madeira", e.g. professional fishers, recreational fishers, aquaculture, diving centres, whale watching, local community, schools, tourists). Madeira entities in the grid get `power`/`interest` from it; an organisation listed both in D5.4 and in the grid is one actor (name as in D5.4, `source_doc` `d54`, grid values copied, `source_ref` citing both). Roles: from the characterisation's Newton & Elliott typology for the Madeira groups; authorities `Regulators`; universities/research `Influencers`.
  - Tuscany: organisations named in §4.3 / Annex 3 (Tuscan Archipelago National Park authority, MASE ministry, Ministry of Infrastructure and Transport, the fisheries office of the agriculture ministry, Coast Guard, Carabinieri forestry unit, MEF, ARPA, ISPRA, CNR, Region of Tuscany, municipalities) as `d54` actors; the stakeholder groups of the Tuscan characterisation (residents/locals, tourists, tourism business owners, ferry companies, divers, artisanal fishers, recreational fishers, seasonal workers, cultural organisations, environmentalists, research institutions, environmental agencies, general public) as `char_tus` actors with their typology roles and grid values. Park authority, municipalities and Region also carry the grid values the characterisation gives them.
  - Power/interest: `HIGH`/`LOW` from the grid quadrants (high/high, high power/low interest, low power/high interest, low/low); `null` where no grid places the actor.
- **Legal instruments** (≥ 3 per DA): the main instruments named in each Annex's rules-of-the-game section (e.g. Arctic: Faroese Act on Marine Resources, Greenland–EU SFPA, NEAFC Management Measures, UNCLOS; Macaronesia: MSFD, MSP Directive, Habitats Directive, the Azores and Madeira regional decrees; Tuscany: Framework Law on Protected Areas 394/1991, Law 979/1982, Barcelona Convention SPA/BD Protocol, MSFD). `level` from `GOVERNANCE_LEVELS`.
- **Gaps** (≥ 3 per DA): the "Challenges and gaps" points of each Annex, one short source sentence each.
- **Recommendations** — titles are the numbered headings of the summary "Recommendations" subsections (§4.1, §4.2, §4.3), copied exactly (joining wrapped lines); `text` = the paragraph directly under the heading, exactly; `target_roles` `["Regulators"]` unless the text names other groups; `implementing_actor_ids` = the actors the text names or, if none, the DA's main competent authority. Use these codes:

| id | title (as printed) | ebm_code | rm_type | governance_level |
|---|---|---|---|---|
| arc_r01 | Broaden stakeholder inclusion to ensure legitimate and participatory governance | 1.4 | institutional | regional_sea |
| arc_r02 | Enhance digital transparency by developing centralised, multilingual portals for real-time data, decisions, and public feedback | 2.3 | technical | national |
| arc_r03 | Institutionalise feedback loops via the creation of mechanisms for stakeholders to respond to policy proposals and receive updates on how input was used | 4.3 | institutional | national |
| arc_r04 | Invest in capacity building to reduce institutional asymmetries and strengthen regional cooperation | 4.1 | institutional | national |
| mac_r01 | Establish a Macaronesia-wide forum for collaboration | 1.4 | institutional | regional_sea |
| mac_r02 | Develop a shared data and information platform across the Macaronesia region | 1.5 | technical | regional_sea |
| mac_r03 | Enhance stakeholder inclusion through improved communication and transparent participatory consultation processes | 2.3 | educational | regional_sea |
| mac_r04 | Develop a Macaronesia-wide and locally adaptable sustainable tourism framework | 2.1 | mixed | regional_sea |
| mac_r05 | Strengthen enforcement and monitoring capacity across the archipelagos adapted to their respective legal and institutional competences | 1.2 | regulatory | regional |
| mac_r06 | Clarify jurisdictional competences and bridge the land-sea governance gap | 1.4 | institutional | national |
| tus_r01 | Build a common, strategic vision for the TANP | 1.4 | institutional | regional |
| tus_r02 | Strengthen the science-policy interface through an established mechanism for knowledge and information exchange | 4.1 | institutional | regional |
| tus_r03 | Expand existing monitoring programmes and initiatives to support decision making | 1.5 | technical | regional |
| tus_r04 | Improve collaborative structures through a multi-stakeholder advisory committee | 1.4 | institutional | local |

- [ ] **Step 6: Add LF pinning** — append to the app `.gitattributes` (under the existing two WS-8 lines):

```
data/wp5_governance_profiles.json text eol=lf
```

- [ ] **Step 7: Amend the spec** (ruling 2): in §3.2's example change `"pims_type": "government_regulators"` to `"pims_type": "governmentregulators"`; in the actor field rules add the line `- \`source_doc\` ∈ \`d54\`, \`char_tus\`, \`char_mac\`: the document where the actor's \`name\` is printed verbatim.`; in §3.4 replace "Actors sourced from the characterisation documents are checked against those `.docx` texts" with "Each actor's `name` is checked against the document named by its `source_doc`; recommendation `text` is checked too".

- [ ] **Step 8: Run until green** — pytest (all pass; report the counts of cards per DA, actors per DA) and `'^wp5-governance-profiles$'` → 0 failures. A card that fails the column check is either mistyped or in the wrong polarity: fix the data, never the test.

- [ ] **Step 9: Commit** exactly: `git -C C:/Users/arturas.baziukas/wt-ws9a add MarineSABRES_SES_Shiny/data/wp5_governance_profiles.json MarineSABRES_SES_Shiny/scripts/tests/test_wp5_governance_profiles.py MarineSABRES_SES_Shiny/tests/testthat/test-wp5-governance-profiles.R MarineSABRES_SES_Shiny/.gitattributes` and `git -C C:/Users/arturas.baziukas/wt-ws9a add -f MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-17-wp5-ws9a-governance-profiles-design.md` — `feat(wp5): D5.4 governance profiles, verified against the deliverable (WS-9a)`.

---

### Task 2: Country database — Greenland, Faroe Islands and regional bodies

**Files:**
- Modify: `data/country_governance_db.json` (via the script below; the file is exactly `json.dumps(indent=2, ensure_ascii=False)` without a trailing newline, so the diff stays minimal)
- Test: `tests/testthat/test-wp5-governance-profiles.R` (append)

**Interfaces:** Produces countries `GL`, `FO`; conventions `neafc`, `ices`, `gfcm`, `accobams`, `pelagos`, `medpan`, `nordic_council`.

- [ ] **Step 1: Append the failing test** to `tests/testthat/test-wp5-governance-profiles.R`:

```r
test_that("country DB: GL and FO, the seven bodies, both directions of membership", {
  db <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "country_governance_db.json"), simplifyVector = FALSE)
  expect_true(all(c("GL", "FO") %in% names(db$countries)))
  bodies <- c("neafc", "ices", "gfcm", "accobams", "pelagos", "medpan", "nordic_council")
  expect_true(all(bodies %in% names(db$regional_conventions)))
  for (b in bodies) {
    rc <- db$regional_conventions[[b]]
    expect_true(nzchar(rc$name) && nzchar(rc$full_name), info = b)
    expect_gte(length(rc$responses), 2L)
    for (cc in unlist(rc$member_codes)) {
      expect_true(cc %in% names(db$countries), info = paste(b, cc))
      expect_true(b %in% unlist(db$countries[[cc]]$regional_conventions), info = paste(b, cc))
    }
  }
  expect_true(all(c("GL", "FO") %in% unlist(db$countries_by_sea$arctic)))
})

test_that("get_countries_for_sea('arctic') now includes Greenland and the Faroe Islands", {
  load_country_governance_db(force_reload = TRUE)
  codes <- vapply(get_countries_for_sea("arctic"), function(r) r$code, character(1))
  expect_true(all(c("GL", "FO", "IS", "NO") %in% codes))
})
```

- [ ] **Step 2: Run to verify it fails** (`'^wp5-governance-profiles$'`).

- [ ] **Step 3: Write and run the edit script** `C:/Users/arturas.baziukas/wt-ws9a/.superpowers/ws9a-src/add_country_bodies.py` (scratch, not committed) — `micromamba run -n shiny python <that file> data/country_governance_db.json` from the app dir:

```python
"""Add GL, FO and seven regional bodies to country_governance_db.json (WS-9a Task 2)."""
import json
import sys

path = sys.argv[1]
db = json.loads(open(path, encoding="utf-8").read())
for code, name in (("GL", "Greenland"), ("FO", "Faroe Islands")):
    db["countries"].setdefault(code, {"code": code, "name_en": name, "eu_member": False, "income_level": "high",
                                      "governance_group": "non_eu_european", "regional_conventions": ["ospar"]})
bodies = {
    "neafc": ("NEAFC (North-East Atlantic Fisheries Commission)", "North-East Atlantic Fisheries Commission",
              ["DK", "FO", "GL", "IS", "NO", "GB"],
              ["NEAFC annual Management Measures for pelagic and deep-sea stocks",
               "NEAFC bottom-fishing closures to protect vulnerable marine ecosystems",
               "NEAFC Scheme of Control and Enforcement (port state control, vessel monitoring)"]),
    "ices": ("ICES (International Council for the Exploration of the Sea)", "International Council for the Exploration of the Sea",
             ["BE", "CA", "DK", "EE", "FI", "FR", "DE", "IS", "IE", "LV", "LT", "NL", "NO", "PL", "PT", "ES", "SE", "GB", "US"],
             ["ICES advice on fishing opportunities (catch limits)",
              "ICES ecosystem overviews and integrated ecosystem assessments",
              "ICES advice on bycatch and vulnerable marine ecosystems"]),
    "gfcm": ("GFCM (General Fisheries Commission for the Mediterranean)", "General Fisheries Commission for the Mediterranean",
             ["AL", "DZ", "BG", "HR", "CY", "EG", "FR", "GE", "GR", "IL", "IT", "LB", "LY", "MT", "ME", "MA", "RO", "SI", "ES", "SY", "TN", "TR"],
             ["GFCM multiannual management plans for demersal and small pelagic stocks",
              "GFCM fisheries restricted areas",
              "GFCM minimum conservation reference sizes and gear rules"]),
    "accobams": ("ACCOBAMS", "Agreement on the Conservation of Cetaceans of the Black Sea, Mediterranean Sea and contiguous Atlantic area",
                 ["AL", "DZ", "BG", "HR", "CY", "EG", "FR", "GE", "GR", "IT", "LB", "LY", "MT", "ME", "MA", "PT", "RO", "SI", "ES", "SY", "TN", "TR", "UA"],
                 ["ACCOBAMS cetacean bycatch mitigation measures",
                  "ACCOBAMS guidelines on underwater noise",
                  "ACCOBAMS High Standard Whale-watching certification"]),
    "pelagos": ("Pelagos Sanctuary", "Pelagos Sanctuary for Mediterranean Marine Mammals",
                ["FR", "IT"],
                ["Pelagos Sanctuary marine mammal protection measures",
                 "Pelagos ship-strike reduction and whale-watching codes of conduct"]),
    "medpan": ("MedPAN", "Network of Marine Protected Area managers in the Mediterranean",
               db["countries_by_sea"]["mediterranean"],
               ["MedPAN MPA management capacity building",
                "MedPAN small grants and MPA networking"]),
    "nordic_council": ("Nordic Council of Ministers", "Nordic Council of Ministers",
                       ["DK", "FI", "IS", "NO", "SE", "GL", "FO"],
                       ["Nordic cooperation programmes on fisheries and the marine environment",
                        "Nordic knowledge exchange on ecosystem-based management"]),
}
for b, (name, full, members, responses) in bodies.items():
    members = [m for m in members if m in db["countries"]]
    db["regional_conventions"][b] = {"name": name, "full_name": full, "member_codes": members, "responses": responses}
    for m in members:
        rc = db["countries"][m].setdefault("regional_conventions", [])
        if b not in rc:
            rc.append(b)
for sea in ("arctic", "atlantic"):
    for code in ("GL", "FO"):
        if code not in db["countries_by_sea"][sea]:
            db["countries_by_sea"][sea].append(code)
db["last_updated"] = "2026-10-17"
open(path, "w", encoding="utf-8", newline="\n").write(json.dumps(db, ensure_ascii=False, indent=2))
print("ok:", len(db["countries"]), "countries,", len(db["regional_conventions"]), "conventions")
```

- [ ] **Step 4: Check the diff is additions only** — `git -C C:/Users/arturas.baziukas/wt-ws9a diff --stat -- MarineSABRES_SES_Shiny/data/country_governance_db.json` (no deletions other than the `last_updated` line and closing brackets of lists that grew).

- [ ] **Step 5: Run tests** — `'^wp5-governance-profiles$'`, `'^knowledge-base$'`, `'^kb-report-helpers$'`, `'^dead-code-cleanup$'` → 0 failures. If an existing test pins a count that the new memberships change, report it (DONE_WITH_CONCERNS) with the old and new value; do not edit the test.

- [ ] **Step 6: Commit** — `feat(wp5): Greenland, Faroe Islands and regional bodies in the country database (WS-9a)`.

---

### Task 3: Fix duplicate rows from `generate_element_id()` (existing bug)

**Files:**
- Modify: `functions/data_structure.R` (after `generate_element_id()`, ~line 16), `modules/pims_stakeholder_module.R` (~lines 452, 635, 675), `modules/response_module.R` (~line 530)
- Test: `tests/testthat/test-pims-stakeholder-module.R`, `tests/testthat/test-response-module.R` (append)

**Interfaces:** Produces `next_element_id(prefix, n)` → one id `paste0(prefix, sprintf("%03d", n))`.

- [ ] **Step 1: Append failing tests.** To `tests/testthat/test-pims-stakeholder-module.R`:

```r
test_that("next_element_id returns exactly one id", {
  expect_equal(next_element_id("SH", 2), "SH002")
  expect_equal(next_element_id("RM", 12), "RM012")
})

test_that("adding two stakeholders gives two rows with distinct ids (bug: generate_element_id(prefix, n) returned 1..n)", {
  real_server <- get("pims_stakeholder_server", envir = .GlobalEnv)
  pdr <- shiny::reactiveVal(create_empty_project("t"))
  testServer(real_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    session$setInputs(sh_name = "Fishers", sh_type = "x", add_stakeholder = 1)
    session$setInputs(sh_name = "Divers", sh_type = "x", add_stakeholder = 2)
    sh <- stakeholder_data$stakeholders
    expect_equal(nrow(sh), 2L)
    expect_equal(sh$ID, c("SH001", "SH002"))
    expect_equal(sh$Name, c("Fishers", "Divers"))
  })
})
```

To `tests/testthat/test-response-module.R`:

```r
test_that("adding two measures gives two rows with distinct ids", {
  proj <- create_empty_project("t"); pd <- reactiveVal(proj)
  testServer(real_response_measures_server, args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$setInputs(rm_name = "A", rm_type = "regulatory", add_response = 1)
    session$setInputs(rm_name = "B", rm_type = "regulatory", add_response = 2)
    m <- pd()$data$response_measures$measures
    expect_equal(nrow(m), 2L)
    expect_equal(m$ID, c("RM001", "RM002"))
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^pims-stakeholder-module$'` (could not find `next_element_id`; then 3 rows), `'^response-module$'` (3 rows).

- [ ] **Step 3: Implement.** In `functions/data_structure.R` directly after `generate_element_id()`:

```r
#' One new element ID for a running counter (e.g. the 2nd stakeholder -> "SH002").
#' generate_element_id(prefix, n) returns ALL ids 1..n for a single n, so it must
#' not be used to create one row.
next_element_id <- function(prefix, n) paste0(prefix, sprintf("%03d", as.integer(n)))
```

Replace, in `modules/pims_stakeholder_module.R`, `generate_element_id(PIMS_ID_PREFIX$stakeholder, stakeholder_data$stakeholder_counter)`, `generate_element_id(PIMS_ID_PREFIX$engagement, stakeholder_data$engagement_counter)` and `generate_element_id(PIMS_ID_PREFIX$communication, stakeholder_data$communication_counter)` by `next_element_id(...)` with the same arguments; in `modules/response_module.R` replace `generate_element_id(ELEMENT_ID_PREFIX$measures, response_data$counter)` by `next_element_id(ELEMENT_ID_PREFIX$measures, response_data$counter)`.

- [ ] **Step 4: Run tests** — `'^pims-stakeholder-module$'`, `'^response-module$'`, `'^data-structure'` → 0 failures.

- [ ] **Step 5: Commit** — `fix: adding a second stakeholder or measure no longer creates duplicate rows`.

---

### Task 4: R data layer — constants, stakeholder schema, governance helpers

**Files:**
- Modify: `constants.R` (after `PESTLE_CODES`, ~line 932), `functions/data_structure.R` (`create_empty_project()` stakeholders frame ~lines 165-178; `normalize_json_project_data()` after the response-register hook ~line 979), `global.R` (after `source("functions/wp5_scenarios.R", local = FALSE)`, ~line 712)
- Create: `functions/stakeholder_schema.R`, `functions/wp5_governance.R`, `tests/testthat/test-wp5-governance.R`

**Interfaces:**
- Consumes: Task 1 JSON; `next_element_id()` (Task 3); `encode_ids()` (`functions/response_measures_schema.R`).
- Produces: constants `WP5_GOV_DIMENSIONS`, `WP5_GOV_POLARITIES`, `WP5_POLICY_TARGETS`, `PIMS_STAKEHOLDER_COLUMNS`, `PIMS_STAKEHOLDER_TYPE_KEYS`, `WP5_GOVERNANCE_MIN_APP_VERSION`; `normalize_stakeholders(df)`, `stakeholders_use_governance_fields(df)`, `stakeholders_display_view(df, i18n)`; `load_wp5_governance_profiles(path = NULL, force_reload = FALSE)`, `wp5_gov_profile_for_site(profiles, da_site)`, `wp5_gov_filter_cards(profile, dimension = "", polarity = "", sub_area = "")`, `seed_da_actors(stakeholders, profile, sub_areas = NULL, i18n, counter)` → `list(stakeholders, added, skipped, counter)`, `wp5_gov_recommendation_measure(rec, stakeholders = NULL)` → named list of register fields (no `ID`), `wp5_gov_in_register(register, title)`.

- [ ] **Step 1: Write the failing tests** `tests/testthat/test-wp5-governance.R`:

```r
# tests/testthat/test-wp5-governance.R
# WS-9a (spec 2026-10-17 §4-§5): stakeholder schema and governance helpers.
library(testthat)
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R"))

gp <- load_wp5_governance_profiles(force_reload = TRUE)
tus <- wp5_gov_profile_for_site(gp, "Tuscan Archipelago")
arc <- wp5_gov_profile_for_site(gp, "Arctic Northeast Atlantic")
i18n_echo <- make_test_i18n()

test_that("constants match the data", {
  expect_equal(WP5_GOV_DIMENSIONS, unlist(gp$dimensions))
  expect_equal(PIMS_STAKEHOLDER_COLUMNS[13:14], c("NERoles", "SourceId"))
  expect_equal(WP5_GOVERNANCE_MIN_APP_VERSION, "1.30.0")
})

test_that("normalize_stakeholders: NULL, legacy 12-column frame, list rows, bad roles (review focus 4)", {
  expect_equal(names(normalize_stakeholders(NULL)), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(nrow(normalize_stakeholders(NULL)), 0L)
  legacy <- data.frame(ID = "SH001", Name = "Fishers", Type = "x", Sector = "", Contact = "", Interests = "",
                       Role = "", Power = "HIGH", Interest = "", Attitude = "", EngagementLevel = "",
                       DateAdded = "2026-01-01", stringsAsFactors = FALSE)
  out <- normalize_stakeholders(legacy)
  expect_equal(names(out), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(c(out$NERoles, out$SourceId, out$Power), c("", "", "HIGH"))
  rows <- list(list(ID = "SH002", Name = "Park", NERoles = "Regulators;bogus;Inputters"))
  expect_equal(normalize_stakeholders(rows)$NERoles, "Inputters;Regulators")
  expect_equal(nrow(rbind(out, normalize_stakeholders(rows))), 2L)
})

test_that("stakeholders_use_governance_fields and the display view", {
  sh <- normalize_stakeholders(list(list(ID = "SH001", Name = "A", NERoles = "Regulators", SourceId = "d54:x")))
  expect_true(stakeholders_use_governance_fields(sh))
  expect_false(stakeholders_use_governance_fields(normalize_stakeholders(NULL)))
  v <- stakeholders_display_view(sh, i18n_echo)
  expect_false("SourceId" %in% names(v))
  expect_equal(v$NERoles, "modules.wp5_governance.role.regulators")
})

test_that("profile lookup and card filters (sub-area keeps DA-wide cards)", {
  expect_null(wp5_gov_profile_for_site(gp, ""))
  expect_null(wp5_gov_profile_for_site(gp, "Nowhere"))
  expect_null(wp5_gov_profile_for_site(NULL, "Tuscan Archipelago"))
  all_cards <- wp5_gov_filter_cards(tus)
  expect_equal(length(all_cards), length(tus$cards))
  b <- wp5_gov_filter_cards(tus, polarity = "barrier")
  expect_true(length(b) > 0 && all(vapply(b, `[[`, "", "polarity") == "barrier"))
  k <- wp5_gov_filter_cards(tus, dimension = "knowledge")
  expect_true(all(vapply(k, `[[`, "", "dimension") == "knowledge"))
  ic <- wp5_gov_filter_cards(arc, sub_area = "iceland")
  expect_true(all(vapply(ic, function(cd) is.null(cd$sub_area) || identical(cd$sub_area, "iceland"), logical(1))))
})

test_that("seed_da_actors: all actors once; second run adds nothing (review focus 2)", {
  r1 <- seed_da_actors(NULL, tus, NULL, i18n_echo, counter = 0)
  expect_equal(r1$added, length(tus$actors))
  expect_equal(nrow(r1$stakeholders), length(tus$actors))
  expect_equal(r1$stakeholders$ID[1], "SH001")
  expect_true(all(startsWith(r1$stakeholders$SourceId, "d54:tus_")))
  expect_true(all(r1$stakeholders$NERoles != ""))
  expect_true(any(r1$stakeholders$Power == "HIGH"))
  r2 <- seed_da_actors(r1$stakeholders, tus, NULL, i18n_echo, counter = r1$counter)
  expect_equal(r2$added, 0L)
  expect_equal(r2$skipped, length(tus$actors))
  expect_equal(nrow(r2$stakeholders), nrow(r1$stakeholders))
})

test_that("seed_da_actors skips a hand-typed actor with the same name (case/space-insensitive)", {
  a1 <- tus$actors[[1]]
  manual <- normalize_stakeholders(list(list(ID = "SH001", Name = paste0("  ", toupper(a1$name), " "))))
  r <- seed_da_actors(manual, tus, NULL, i18n_echo, counter = 1)
  expect_equal(r$skipped, 1L)
  expect_equal(nrow(r$stakeholders), length(tus$actors))
  expect_equal(r$stakeholders$ID[2], "SH002")
})

test_that("seed_da_actors sub-area filter; an empty selection adds DA-wide actors only (review focus 3)", {
  ice <- seed_da_actors(NULL, arc, "iceland", i18n_echo, 0)$stakeholders
  src <- sub("^d54:", "", ice$SourceId)
  subs <- vapply(arc$actors, function(a) a$sub_area %||% "", "")[match(src, vapply(arc$actors, `[[`, "", "id"))]
  expect_true(all(subs %in% c("", "iceland")))
  expect_true(any(subs == "iceland") && any(subs == ""))
  none <- seed_da_actors(NULL, arc, character(0), i18n_echo, 0)$stakeholders
  expect_true(nrow(none) > 0)
  expect_true(all(vapply(arc$actors, function(a) a$sub_area %||% "", "")[
    match(sub("^d54:", "", none$SourceId), vapply(arc$actors, `[[`, "", "id"))] == ""))
  expect_true(all(none$Power == "" & none$Interest == ""))      # Arctic: no published grid
})

test_that("recommendation -> register fields; implementing stakeholders linked only after seeding", {
  rec <- tus$recommendations[[1]]
  f <- wp5_gov_recommendation_measure(rec, NULL)
  expect_equal(f$Name, rec$title)
  expect_equal(c(f$Kind, f$Status, f$EbmCode, f$Type, f$Target), c("instrument", "proposed", rec$ebm_code, rec$rm_type, ""))
  expect_match(f$Description, "D5.4 recommendation", fixed = TRUE)
  expect_equal(f$ImplementingStakeholders, "")
  seeded <- seed_da_actors(NULL, tus, NULL, i18n_echo, 0)$stakeholders
  f2 <- wp5_gov_recommendation_measure(rec, seeded)
  want <- seeded$ID[seeded$SourceId %in% paste0("d54:", unlist(rec$implementing_actor_ids))]
  expect_equal(f2$ImplementingStakeholders, paste(want, collapse = ";"))
  reg <- normalize_response_measures(as.data.frame(c(list(ID = "RM001"), f2), stringsAsFactors = FALSE))
  expect_true(wp5_gov_in_register(reg, rec$title))
  expect_false(wp5_gov_in_register(reg, "something else"))
  expect_false(wp5_gov_in_register(NULL, rec$title))
})

test_that("a missing or corrupt profiles file gives NULL", {
  expect_null(load_wp5_governance_profiles(path = tempfile(fileext = ".json")))
  bad <- tempfile(fileext = ".json"); writeLines("{ nope", bad)
  expect_null(load_wp5_governance_profiles(path = bad))
  expect_false(is.null(load_wp5_governance_profiles()))       # default-path cache untouched
})

test_that("empty project and JSON load carry the new stakeholder columns", {
  expect_equal(names(create_empty_project("t")$data$pims$stakeholders), PIMS_STAKEHOLDER_COLUMNS)
  pd <- list(data = list(pims = list(stakeholders = list(list(ID = "SH001", Name = "A", NERoles = "Regulators")))))
  out <- normalize_json_project_data(pd)
  expect_equal(names(out$data$pims$stakeholders), PIMS_STAKEHOLDER_COLUMNS)
  expect_equal(out$data$pims$stakeholders$NERoles, "Regulators")
})
```

- [ ] **Step 2: Run to verify it fails** — `'^wp5-governance$'`.

- [ ] **Step 3: Constants.** In `constants.R` after `PESTLE_CODES`:

```r
# ============================================================================
# WP5 GOVERNANCE PROFILES (spec 2026-10-17 WS-9a, D5.4)
# ============================================================================
WP5_GOV_DIMENSIONS <- c("knowledge", "collaboration", "values_conflicts", "legitimacy", "cross_sectoral")
WP5_GOV_POLARITIES <- c("enabler", "barrier")   # D5.4 "What is working well" / "Areas of improvement"
WP5_POLICY_TARGETS <- c("kmgbf_30x30", "eu_nrr", "msfd_ges_d1", "msfd_ges_d6", "national_mpa_pct")
# PIMS stakeholder register; NERoles = ';'-joined STAKEHOLDER_TYPES codes (D5.4 actor typology),
# SourceId = "d54:<actor id>" for actors loaded from a D5.4 profile
PIMS_STAKEHOLDER_COLUMNS <- c("ID", "Name", "Type", "Sector", "Contact", "Interests", "Role", "Power",
                              "Interest", "Attitude", "EngagementLevel", "DateAdded", "NERoles", "SourceId")
# Translation keys of the PIMS "Type" options (the form stores the translated label)
PIMS_STAKEHOLDER_TYPE_KEYS <- c(
  resource_users = "modules.pims.stakeholder.resource_users",
  industrybusiness = "modules.pims.stakeholder.industrybusiness",
  governmentregulators = "modules.pims.stakeholder.governmentregulators",
  ngocivil_society = "modules.pims.stakeholder.ngocivil_society",
  scientificacademic = "modules.pims.stakeholder.scientificacademic",
  local_communities = "modules.pims.stakeholder.local_communities",
  indigenous_groups = "modules.pims.stakeholder.indigenous_groups",
  other = "modules.isa.ai_assistant.other")
# Older apps rbind() a 12-column stakeholder row onto the frame and drop Policy_Target,
# so a project using either needs this version (WS-0 stamp_min_app_version()).
WP5_GOVERNANCE_MIN_APP_VERSION <- "1.30.0"
```

- [ ] **Step 4: Create `functions/stakeholder_schema.R`:**

```r
# functions/stakeholder_schema.R
# =============================================================================
# PIMS stakeholder register schema (WP5 WS-9a, spec 2026-10-17 §4.1).
# The module, the JSON loader and the D5.4 actor seeding build rows through
# normalize_stakeholders(), so older projects gain NERoles/SourceId as "".
# =============================================================================

#' Normalise a stakeholder register to PIMS_STAKEHOLDER_COLUMNS (idempotent)
#' @param df NULL, data.frame, or list of row lists (jsonlite simplifyVector = FALSE)
normalize_stakeholders <- function(df) {
  if (is.list(df) && !is.data.frame(df)) {
    rows <- Filter(is.list, df)
    df <- if (length(rows) == 0) NULL else {
      keys <- union(PIMS_STAKEHOLDER_COLUMNS, unique(unlist(lapply(rows, names))))
      cols <- lapply(keys, function(cl) vapply(rows, function(r) {
        v <- r[[cl]]
        if (is.null(v) || length(v) == 0 || all(is.na(unlist(v)))) "" else paste(unlist(v), collapse = ";")
      }, character(1)))
      as.data.frame(stats::setNames(cols, keys), stringsAsFactors = FALSE)
    }
  }
  if (!is.data.frame(df)) df <- data.frame()
  n <- nrow(df)
  out <- lapply(PIMS_STAKEHOLDER_COLUMNS, function(cl) {
    v <- if (cl %in% names(df)) as.character(df[[cl]]) else rep("", n)
    v[is.na(v)] <- ""
    v
  })
  out <- as.data.frame(stats::setNames(out, PIMS_STAKEHOLDER_COLUMNS), stringsAsFactors = FALSE)
  out$NERoles <- vapply(strsplit(out$NERoles, ";", fixed = TRUE), function(t) {
    t <- trimws(t)
    bad <- setdiff(t[nzchar(t)], STAKEHOLDER_TYPES)
    if (length(bad) && exists("debug_log", mode = "function")) {
      debug_log(sprintf("normalize_stakeholders: dropped unknown role(s): %s", paste(bad, collapse = ", ")), "WARN")
    }
    paste(STAKEHOLDER_TYPES[STAKEHOLDER_TYPES %in% t], collapse = ";")
  }, character(1))
  out
}

#' TRUE when a register uses the WS-9a columns (needs WP5_GOVERNANCE_MIN_APP_VERSION)
stakeholders_use_governance_fields <- function(df) {
  df <- normalize_stakeholders(df)
  any(nzchar(df$NERoles)) || any(nzchar(df$SourceId))
}

#' Register table view: roles as translated labels, SourceId hidden
stakeholders_display_view <- function(df, i18n) {
  df <- normalize_stakeholders(df)
  # i18n-ref: modules.wp5_governance.role.inputters
  # i18n-ref: modules.wp5_governance.role.extractors
  # i18n-ref: modules.wp5_governance.role.regulators
  # i18n-ref: modules.wp5_governance.role.affectees
  # i18n-ref: modules.wp5_governance.role.beneficiaries
  # i18n-ref: modules.wp5_governance.role.influencers
  df$NERoles <- vapply(strsplit(df$NERoles, ";", fixed = TRUE), function(t) {
    paste(vapply(t, function(r) as.character(i18n$t(paste0("modules.wp5_governance.role.", tolower(r)))),
                 character(1)), collapse = ", ")
  }, character(1))
  df[, setdiff(names(df), "SourceId"), drop = FALSE]
}
```

- [ ] **Step 5: Create `functions/wp5_governance.R`:**

```r
# functions/wp5_governance.R
# =============================================================================
# WP5 WS-9a: D5.4 governance profiles (spec 2026-10-17). Loader and pure
# helpers for actor seeding (PIMS) and the governance-context tab (Response).
# data/wp5_governance_profiles.json is curated and verified against D5.4 by
# scripts/tests/test_wp5_governance_profiles.py; do not edit it casually.
# =============================================================================

.wp5_gov_env <- new.env(parent = emptyenv())

#' D5.4 governance profiles, or NULL. Only default-path loads are cached.
load_wp5_governance_profiles <- function(path = NULL, force_reload = FALSE) {
  default <- is.null(path)
  if (default && !force_reload && !is.null(.wp5_gov_env$profiles)) return(.wp5_gov_env$profiles)
  if (default) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_governance_profiles.json")
            else file.path("data", "wp5_governance_profiles.json")
  }
  db <- if (file.exists(path)) {
    tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  } else NULL
  if (is.null(db) && exists("debug_log", mode = "function")) {
    debug_log(sprintf("WP5 governance: could not load %s", path), "WP5")
  }
  if (default) .wp5_gov_env$profiles <- db
  db
}

#' The profile whose da_site equals the project's DA, or NULL
wp5_gov_profile_for_site <- function(profiles, da_site) {
  if (is.null(profiles) || is.null(da_site) || length(da_site) != 1 || !nzchar(da_site)) return(NULL)
  hit <- Filter(function(p) identical(p$da_site, da_site), profiles$das)
  if (length(hit)) hit[[1]] else NULL
}

#' Cards of a profile filtered by dimension / polarity / sub-area ("" = all).
#' The sub-area filter keeps cards that have no sub-area (DA-wide findings).
wp5_gov_filter_cards <- function(profile, dimension = "", polarity = "", sub_area = "") {
  cards <- profile$cards %||% list()
  keep <- vapply(cards, function(cd) {
    (!nzchar(dimension) || identical(cd$dimension, dimension)) &&
      (!nzchar(polarity) || identical(cd$polarity, polarity)) &&
      (!nzchar(sub_area) || is.null(cd$sub_area) || identical(cd$sub_area, sub_area))
  }, logical(1))
  cards[keep]
}

.wp5_name_key <- function(x) gsub("\\s+", " ", trimws(tolower(as.character(x))))

#' Add a profile's actors to a stakeholder register (pure, idempotent).
#' @param sub_areas NULL = no filter; a character vector (possibly empty) keeps
#'   actors in those sub-areas plus actors without a sub-area
#' @param counter the register's current stakeholder counter
#' @return list(stakeholders, added, skipped, counter)
seed_da_actors <- function(stakeholders, profile, sub_areas = NULL, i18n, counter) {
  sh <- normalize_stakeholders(stakeholders)
  actors <- profile$actors %||% list()
  if (!is.null(sub_areas)) {
    actors <- Filter(function(a) is.null(a$sub_area) || a$sub_area %in% sub_areas, actors)
  }
  added <- 0L; skipped <- 0L; rows <- list()
  # i18n-ref: modules.response.governance.level.local
  # i18n-ref: modules.response.governance.level.island
  # i18n-ref: modules.response.governance.level.regional
  # i18n-ref: modules.response.governance.level.national
  # i18n-ref: modules.response.governance.level.eu
  # i18n-ref: modules.response.governance.level.regional_sea
  # i18n-ref: modules.response.governance.level.international
  for (a in actors) {
    sid <- paste0("d54:", a$id)
    known <- .wp5_name_key(c(sh$Name, vapply(rows, `[[`, "", "Name")))
    if (sid %in% sh$SourceId || .wp5_name_key(a$name) %in% known) {
      skipped <- skipped + 1L
      next
    }
    counter <- counter + 1
    rows[[length(rows) + 1L]] <- list(
      ID = next_element_id(PIMS_ID_PREFIX$stakeholder, counter),
      Name = a$name,
      Type = as.character(i18n$t(PIMS_STAKEHOLDER_TYPE_KEYS[[a$pims_type]])),
      Role = if (is.null(a$level)) "" else as.character(i18n$t(paste0("modules.response.governance.level.", a$level))),
      Power = a$power %||% "", Interest = a$interest %||% "",
      NERoles = paste(unlist(a$ne_roles), collapse = ";"),
      SourceId = sid, DateAdded = as.character(Sys.Date()))
    added <- added + 1L
  }
  if (length(rows)) sh <- rbind(sh, normalize_stakeholders(rows))
  list(stakeholders = sh, added = added, skipped = skipped, counter = counter)
}

#' Register fields (no ID) for a D5.4 recommendation; implementing stakeholders
#' are the project's stakeholders seeded from the recommendation's actors.
wp5_gov_recommendation_measure <- function(rec, stakeholders = NULL) {
  sh <- normalize_stakeholders(stakeholders)
  want <- paste0("d54:", unlist(rec$implementing_actor_ids))
  list(Name = rec$title,
       Description = paste0(rec$text, " (D5.4 recommendation, ", rec$source_ref, ")"),
       Kind = "instrument", EbmCode = rec$ebm_code %||% "", GovernanceLevel = rec$governance_level %||% "",
       Type = rec$rm_type %||% "", Status = "proposed", Target = "",
       ImplementingStakeholders = encode_ids(sh$ID[sh$SourceId %in% want]),
       DateAdded = as.character(Sys.Date()))
}

#' TRUE when the register already holds a measure with this name
wp5_gov_in_register <- function(register, title) {
  if (!is.data.frame(register) || nrow(register) == 0 || !"Name" %in% names(register)) return(FALSE)
  any(trimws(as.character(register$Name)) == trimws(title))
}
```

- [ ] **Step 6: Wire into `functions/data_structure.R` and `global.R`.**
  - In `create_empty_project()`'s `pims$stakeholders` data.frame add `NERoles = character(),` and `SourceId = character()` after `DateAdded = character()` (keep the order of `PIMS_STAKEHOLDER_COLUMNS`).
  - In `normalize_json_project_data()` directly after the response-register block (`data$data$response_measures$measures <- normalize_response_measures(...)` and its closing `}`):

```r
  # PIMS stakeholders: WS-9a schema (NERoles, SourceId) on every JSON load path
  if (is.list(data$data) && is.list(data$data$pims) && !is.null(data$data$pims$stakeholders) &&
      exists("normalize_stakeholders", mode = "function")) {
    data$data$pims$stakeholders <- normalize_stakeholders(data$data$pims$stakeholders)
  }
```

  - In `global.R` after `source("functions/wp5_scenarios.R", local = FALSE)`:

```r
source("functions/stakeholder_schema.R", local = FALSE)   # WS-9a: PIMS stakeholder schema (NERoles, SourceId)
source("functions/wp5_governance.R", local = FALSE)       # WS-9a: D5.4 governance profiles
```

- [ ] **Step 7: Run tests** — `'^wp5-governance$'`, `'^wp5-governance-profiles$'`, `'^functions-sourced-in-app$'`, `'^json-project-loading$'`, `'^data-structure'`, `'^pims'` → 0 failures.

- [ ] **Step 8: Commit** — `feat(wp5): stakeholder schema and D5.4 governance helpers (WS-9a)`.

---

### Task 5: Translations

**Files:**
- Create: `translations/modules/wp5_governance.json` (same shape as `translations/modules/wp5_scenarios.json`)
- Modify: `translations/modules/indicator_registry.json`

**Interfaces:** Produces every key below in all 9 languages. English is fixed (use verbatim); write the other 8 in the style of `wp5_scenarios.json` and `response_governance.json` (reuse their terms for "demonstration area", "Response register", "ecosystem-based management"; "worldview" is not used here). Keep proper names (D5.4, WP5, NEAFC, PIMS, MSFD, Kunming-Montreal) unchanged. Use the Scenario/PIMS page names exactly as each language's sidebar shows them (`translations/ui/sidebar.json`).

`modules.wp5_governance.*`:

| key | en |
|---|---|
| `context_tab` | Governance context (D5.4) |
| `context_title` | Governance context of the demonstration area (WP5, D5.4) |
| `context_note` | Findings of the D5.4 New Public Governance assessment (2026). They are qualitative, not a score. |
| `unavailable` | The WP5 governance reference data is not available. |
| `english_source` | Source text (English) |
| `filter_da` | Demonstration area |
| `project_da` | Project's demonstration area |
| `filter_dimension` | Governance dimension |
| `filter_polarity` | Show |
| `filter_sub_area` | Sub-area |
| `all` | All dimensions |
| `both` | Enablers and barriers |
| `all_sub_areas` | All sub-areas |
| `no_da_hint` | Choose a demonstration area here, or set the project's demonstration area in PIMS → Project. |
| `cards_title` | What is working well and areas of improvement |
| `no_cards` | No findings match these filters. |
| `recommendations_title` | D5.4 recommendations for this demonstration area |
| `no_recommendations` | No recommendations for this demonstration area. |
| `ebm_code` | EBM instrument |
| `governance_level` | Governance level |
| `add_to_register` | Add to register |
| `already_in_register` | Already in register |
| `added_to_register` | Added to the Response register as |
| `context_add` | Adding the recommendation to the register |
| `dimension.knowledge` | Incorporation of knowledge |
| `dimension.collaboration` | Collaborative structures |
| `dimension.values_conflicts` | Values, conflicts and decision making |
| `dimension.legitimacy` | Inclusivity and legitimacy |
| `dimension.cross_sectoral` | Cross-sectoral coordination |
| `polarity.enabler` | Enabler – working well |
| `polarity.barrier` | Barrier – area of improvement |
| `sub_area_greenland` | Greenland |
| `sub_area_iceland` | Iceland |
| `sub_area_faroe_islands` | Faroe Islands |
| `sub_area_azores` | Azores |
| `sub_area_madeira` | Madeira |
| `sub_area_canaries` | Canary Islands |
| `role.inputters` | Inputters |
| `role.extractors` | Extractors |
| `role.regulators` | Regulators |
| `role.affectees` | Affectees |
| `role.beneficiaries` | Beneficiaries |
| `role.influencers` | Influencers |
| `ne_roles` | Roles (D5.4 actor typology) |
| `ne_roles_hint` | Newton & Elliott (2016) roles used in WP5 D5.4; an actor can have several. |
| `seed_button` | Load DA actor list |
| `seed_hint` | Adds the actors of the project's demonstration area from WP5 D5.4. |
| `seed_no_da` | Set the project's demonstration area in PIMS → Project to load its actor list from D5.4. |
| `seed_title` | Load actor list: |
| `seed_body` | Adds the governance actors that D5.4 lists for this demonstration area. Actors already in the register (same name, or loaded before) are skipped. |
| `sub_area` | Sub-areas to include |
| `seed_confirm` | Add actors |
| `seed_added` | Actors added: |
| `seed_skipped` | skipped (already present): |
| `grid_note.no_published_grid` | D5.4 publishes no power/interest grid for this area; power and interest are left empty. |
| `grid_note.grid_madeira_only` | A power/interest grid is published for Madeira only; Azores and Canary Islands actors have power and interest left empty. |

`modules.indicator_registry.*` (append to `indicator_registry.json`):

| key | en |
|---|---|
| `field_policy_target` | Policy target |
| `policy_target_help` | Optional external policy target for this indicator. D5.4 sets no targets; pick one or type your own. |
| `policy_target.kmgbf_30x30` | Kunming-Montreal 30x30 |
| `policy_target.eu_nrr` | EU Nature Restoration Regulation |
| `policy_target.msfd_ges_d1` | MSFD Good Environmental Status – D1 Biodiversity |
| `policy_target.msfd_ges_d6` | MSFD Good Environmental Status – D6 Seafloor integrity |
| `policy_target.national_mpa_pct` | National MPA coverage target (%) |

- [ ] **Step 1: Add the keys.** Generate both files with a Python script file in `C:/Users/arturas.baziukas/wt-ws9a/.superpowers/` (`json.dump(..., ensure_ascii=False, indent=2)` + trailing newline, UTF-8, LF; for `indicator_registry.json` load, add, dump, and check with `git diff --stat` that only additions appear). Run it with `micromamba run -n shiny python <file>`.
- [ ] **Step 2: Check** — both files parse; `'^i18n-enforcement$'`, `'^i18n-duplicate-keys$'` → 0 failures; the audit's "Totals:" line shows `missing=0` and `hardcoded=0`.
- [ ] **Step 3: Commit** the two translation files — `i18n(wp5): WS-9a governance profile and policy-target keys (9 languages)`.

---

### Task 6: PIMS stakeholders — roles column and "Load DA actor list"

**Files:**
- Modify: `modules/pims_stakeholder_module.R`
- Test: `tests/testthat/test-pims-stakeholder-module.R` (append)

**Interfaces:**
- Consumes: `normalize_stakeholders()`, `stakeholders_display_view()`, `stakeholders_use_governance_fields()`, `load_wp5_governance_profiles()`, `wp5_gov_profile_for_site()`, `seed_da_actors()`, `next_element_id()`, `WP5_GOVERNANCE_MIN_APP_VERSION`; Task 5 keys.
- Produces: inputs `sh_ne_roles`, `seed_da`, `seed_sub_areas`, `seed_da_confirm`; output `seed_da_ui`.

- [ ] **Step 1: Append failing tests** to `tests/testthat/test-pims-stakeholder-module.R`:

```r
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R"))
real_pst_server <- get("pims_stakeholder_server", envir = .GlobalEnv)
real_pst_ui <- get("pims_stakeholder_ui", envir = .GlobalEnv)
proj_da <- function(site) {
  p <- create_empty_project("t", da_site = site); p$project_id <- "p1"; p
}

test_that("the form offers the D5.4 roles multi-select and the seeding slot", {
  ui <- as.character(real_pst_ui("pst", make_test_i18n()))
  expect_match(ui, "pst-sh_ne_roles", fixed = TRUE)
  expect_match(ui, 'value="Regulators"', fixed = TRUE)
  expect_match(ui, "pst-seed_da_ui", fixed = TRUE)
})

test_that("a manual stakeholder stores its roles as codes in canonical order", {
  pdr <- shiny::reactiveVal(proj_da(NULL))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    session$setInputs(sh_name = "Park", sh_type = "x", sh_ne_roles = c("Regulators", "Inputters"), add_stakeholder = 1)
    expect_equal(stakeholder_data$stakeholders$NERoles, "Inputters;Regulators")
    expect_equal(pdr()$min_app_version, WP5_GOVERNANCE_MIN_APP_VERSION)
  })
})

test_that("no DA: no seeding button, a hint instead (review focus 1)", {
  pdr <- shiny::reactiveVal(proj_da(NULL))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    html <- as.character(output$seed_da_ui$html)
    expect_match(html, "modules.wp5_governance.seed_no_da", fixed = TRUE)
    expect_false(grepl("seed_da\"", html, fixed = TRUE))
  })
})

test_that("seeding the Arctic for Iceland adds Iceland and DA-wide actors once; a legacy project still works (review focus 2, 4)", {
  p <- proj_da("Arctic Northeast Atlantic")
  p$data$pims$stakeholders <- data.frame(ID = "SH001", Name = "Local fishers", Type = "x", Sector = "", Contact = "",
                                         Interests = "", Role = "", Power = "", Interest = "", Attitude = "",
                                         EngagementLevel = "", DateAdded = "2026-01-01", stringsAsFactors = FALSE)
  p$data$pims$stakeholder_counter <- 1
  pdr <- shiny::reactiveVal(p)
  arc <- wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Arctic Northeast Atlantic")
  expected <- length(Filter(function(a) is.null(a$sub_area) || identical(a$sub_area, "iceland"), arc$actors))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    expect_match(as.character(output$seed_da_ui$html), "modules.wp5_governance.seed_button", fixed = TRUE)
    session$setInputs(seed_sub_areas = "iceland", seed_da_confirm = 1)
    sh <- stakeholder_data$stakeholders
    expect_equal(nrow(sh), 1L + expected)
    expect_equal(sh$ID[2], "SH002")
    expect_equal(names(sh), PIMS_STAKEHOLDER_COLUMNS)
    session$setInputs(seed_da_confirm = 2)
    expect_equal(nrow(stakeholder_data$stakeholders), 1L + expected)
    expect_equal(nrow(pdr()$data$pims$stakeholders), 1L + expected)
    expect_equal(pdr()$min_app_version, WP5_GOVERNANCE_MIN_APP_VERSION)
    session$setInputs(sh_name = "Divers", sh_type = "x", add_stakeholder = 1)
    expect_equal(nrow(stakeholder_data$stakeholders), 2L + expected)
  })
})

test_that("roles and SourceId survive a JSON save/load round trip", {
  sh <- seed_da_actors(NULL, wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Tuscan Archipelago"),
                       NULL, make_test_i18n(), 0)$stakeholders
  pd <- list(data = list(pims = list(stakeholders = sh)))
  back <- normalize_json_project_data(jsonlite::fromJSON(jsonlite::toJSON(pd, auto_unbox = TRUE), simplifyVector = FALSE))
  expect_equal(back$data$pims$stakeholders$NERoles, sh$NERoles)
  expect_equal(back$data$pims$stakeholders$SourceId, sh$SourceId)
})
```

- [ ] **Step 2: Run to verify they fail** — `'^pims-stakeholder-module$'`.

- [ ] **Step 3: Implement** in `modules/pims_stakeholder_module.R`:
  - UI, in the "add stakeholder" `wellPanel`, directly before `actionButton(ns("add_stakeholder"), ...)`:

```r
                  # WS-9a: D5.4 actor typology (Newton & Elliott 2016)
                  # i18n-ref: modules.wp5_governance.role.inputters
                  # i18n-ref: modules.wp5_governance.role.extractors
                  # i18n-ref: modules.wp5_governance.role.regulators
                  # i18n-ref: modules.wp5_governance.role.affectees
                  # i18n-ref: modules.wp5_governance.role.beneficiaries
                  # i18n-ref: modules.wp5_governance.role.influencers
                  fluidRow(
                    column(12,
                      selectizeInput(ns("sh_ne_roles"), i18n$t("modules.wp5_governance.ne_roles"),
                        choices = setNames(STAKEHOLDER_TYPES, vapply(STAKEHOLDER_TYPES, function(r)
                          i18n$t(paste0("modules.wp5_governance.role.", tolower(r))), character(1))),
                        multiple = TRUE),
                      tags$small(class = "text-muted", i18n$t("modules.wp5_governance.ne_roles_hint"))
                    )
                  ),
```

  - UI, after the `fluidRow(column(12, wellPanel(...)))` that holds the add form and before the following `hr()`, add `fluidRow(column(12, uiOutput(ns("seed_da_ui")))),`.
  - Server: replace the initial `stakeholders = data.frame(ID = character(), ... DateAdded = character())` in `reactiveValues(...)` by `stakeholders = normalize_stakeholders(NULL),`.
  - Server load observer: `if (!is.null(pims$stakeholders)) stakeholder_data$stakeholders <- normalize_stakeholders(pims$stakeholders)`.
  - Server `sync_to_project_data()`: before `project_data_reactive(pd)` add

```r
      if (stakeholders_use_governance_fields(stakeholder_data$stakeholders)) {
        pd <- stamp_min_app_version(pd, WP5_GOVERNANCE_MIN_APP_VERSION)
      }
```

  - Add handler: build `new_row` as `normalize_stakeholders(data.frame(ID = new_id, Name = input$sh_name, Type = input$sh_type, Sector = input$sh_sector %||% "", Contact = input$sh_contact %||% "", Interests = input$sh_interests %||% "", Role = input$sh_role %||% "", Power = input$sh_power %||% "", Interest = input$sh_interest %||% "", Attitude = input$sh_attitude %||% "", EngagementLevel = input$sh_engagement_level %||% "", DateAdded = as.character(Sys.Date()), NERoles = paste(input$sh_ne_roles %||% character(0), collapse = ";"), stringsAsFactors = FALSE))` and append with `stakeholder_data$stakeholders <- rbind(normalize_stakeholders(stakeholder_data$stakeholders), new_row)`; in the clear-inputs block add `updateSelectizeInput(session, "sh_ne_roles", selected = character(0))`.
  - Table: `datatable(stakeholders_display_view(stakeholder_data$stakeholders, i18n), ...)` (same options).
  - Seeding (new server block):

```r
    # WS-9a: load the actors of the project's DA from the D5.4 profile ----
    gov_profile <- reactive({
      site <- tryCatch(project_data_reactive()$data$metadata$da_site, error = function(e) NULL)
      wp5_gov_profile_for_site(load_wp5_governance_profiles(), site %||% "")
    })
    # i18n-ref: modules.wp5_governance.sub_area_greenland
    # i18n-ref: modules.wp5_governance.sub_area_iceland
    # i18n-ref: modules.wp5_governance.sub_area_faroe_islands
    # i18n-ref: modules.wp5_governance.sub_area_azores
    # i18n-ref: modules.wp5_governance.sub_area_madeira
    # i18n-ref: modules.wp5_governance.sub_area_canaries
    # i18n-ref: modules.wp5_governance.grid_note.no_published_grid
    # i18n-ref: modules.wp5_governance.grid_note.grid_madeira_only
    output$seed_da_ui <- renderUI({
      if (is.null(load_wp5_governance_profiles())) {
        return(tags$small(class = "text-muted", i18n$t("modules.wp5_governance.unavailable")))
      }
      if (is.null(gov_profile())) {
        return(tags$small(class = "text-muted", i18n$t("modules.wp5_governance.seed_no_da")))
      }
      tagList(actionButton(ns("seed_da"), i18n$t("modules.wp5_governance.seed_button"),
                           icon = icon("users"), class = "btn-outline-primary"),
              tags$small(class = "text-muted ml-2", i18n$t("modules.wp5_governance.seed_hint")))
    })

    observeEvent(input$seed_da, {
      prof <- gov_profile(); req(prof)
      subs <- unlist(prof$sub_areas)
      showModal(modalDialog(
        title = paste(i18n$t("modules.wp5_governance.seed_title"), prof$da_site),
        p(i18n$t("modules.wp5_governance.seed_body")),
        if (length(subs)) selectizeInput(ns("seed_sub_areas"), i18n$t("modules.wp5_governance.sub_area"),
          choices = setNames(subs, vapply(subs, function(s) i18n$t(paste0("modules.wp5_governance.sub_area_", s)),
                                          character(1))),
          selected = subs, multiple = TRUE),
        if (!is.null(prof$grid_note)) p(class = "small text-muted",
                                        i18n$t(paste0("modules.wp5_governance.grid_note.", prof$grid_note))),
        footer = tagList(modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("seed_da_confirm"), i18n$t("modules.wp5_governance.seed_confirm"),
                                      class = "btn-primary")),
        easyClose = TRUE))
    })

    observeEvent(input$seed_da_confirm, {
      prof <- gov_profile(); req(prof)
      subs <- if (length(prof$sub_areas)) (input$seed_sub_areas %||% character(0)) else NULL
      res <- seed_da_actors(stakeholder_data$stakeholders, prof, subs, i18n, stakeholder_data$stakeholder_counter)
      stakeholder_data$stakeholders <- res$stakeholders
      stakeholder_data$stakeholder_counter <- res$counter
      sync_to_project_data()
      removeModal()
      msg <- paste(i18n$t("modules.wp5_governance.seed_added"), res$added, "·",
                   i18n$t("modules.wp5_governance.seed_skipped"), res$skipped)
      if (!is.null(prof$grid_note)) {
        msg <- paste(msg, "—", i18n$t(paste0("modules.wp5_governance.grid_note.", prof$grid_note)))
      }
      showNotification(msg, type = "message", duration = 8)
    })
```

- [ ] **Step 4: Run tests** — `'^pims-stakeholder-module$'`, `'^pims-module$'`, `'^i18n-enforcement$'`; the audit `missing=0 hardcoded=0`.

- [ ] **Step 5: Commit** — `feat(wp5): D5.4 roles and 'Load DA actor list' in PIMS stakeholders (WS-9a)`.

---

### Task 7: Governance context tab in the Response module

**Files:**
- Create: `modules/wp5_governance_context_module.R`, `tests/testthat/test-wp5-governance-context-module.R`
- Modify: `modules/response_module.R` (tabsetPanel end ~line 411; server after the project-load observer ~line 492), `app.R` (`OPTIONAL_MODULES`, before `"modules/response_module.R"` ~line 105)

**Interfaces:**
- Consumes: Task 4 helpers; Task 5 keys; `wp5_vocab_label("instrument", code, i18n)`; `format_user_error()`.
- Produces: `wp5_governance_context_ui(id, i18n)`, `wp5_governance_context_server(id, project_data_reactive, i18n, event_bus = NULL, register = NULL)` where `register = list(measures = <reactive/function returning the register frame>, add = function(fields) -> new ID)`; inputs `da`, `dimension`, `polarity`, `sub_area`, `add_rec`.

- [ ] **Step 1: Write the failing tests** `tests/testthat/test-wp5-governance-context-module.R`:

```r
# tests/testthat/test-wp5-governance-context-module.R
library(testthat)
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R",
                  "modules/wp5_governance_context_module.R", "modules/response_module.R"))
real_ctx_server <- get("wp5_governance_context_server", envir = .GlobalEnv)
real_rm_ui <- get("response_measures_ui", envir = .GlobalEnv)        # helper-stubs.R shadows it
real_rm_server <- get("response_measures_server", envir = .GlobalEnv)
i18n_echo <- make_test_i18n()
tus <- wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Tuscan Archipelago")

proj_da <- function(site) { p <- create_empty_project("t", da_site = site); p$project_id <- "p1"; p }
fake_register <- function() {
  store <- shiny::reactiveVal(normalize_response_measures(NULL))
  list(measures = function() store(),
       add = function(fields) {
         id <- sprintf("RM%03d", nrow(store()) + 1L)
         store(rbind(store(), normalize_response_measures(as.data.frame(c(list(ID = id), fields), stringsAsFactors = FALSE))))
         id
       },
       store = store)
}

test_that("UI contract and the Response module tab", {
  ui <- as.character(wp5_governance_context_ui("g", i18n_echo))
  expect_match(ui, "g-dimension", fixed = TRUE)
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus", "register") %in%
                  names(formals(wp5_governance_context_server))))
  html <- as.character(real_rm_ui("rm", i18n_echo))
  expect_match(html, "modules.wp5_governance.context_tab", fixed = TRUE)
  expect_match(html, "rm-gov_ctx-dimension", fixed = TRUE)
})

test_that("project DA drives the cards; filters narrow them", {
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    html <- as.character(output$body$html)
    expect_match(html, "modules.wp5_governance.dimension.knowledge", fixed = TRUE)
    expect_match(html, tus$cards[[1]]$source_ref, fixed = TRUE)
    session$setInputs(polarity = "barrier")
    html <- as.character(output$body$html)
    expect_false(grepl("modules.wp5_governance.polarity.enabler", html, fixed = TRUE))
    expect_match(html, "modules.wp5_governance.polarity.barrier", fixed = TRUE)
  })
})

test_that("no DA: hint; choosing a DA shows it (review focus 1)", {
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da(NULL)),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    expect_match(as.character(output$body$html), "modules.wp5_governance.no_da_hint", fixed = TRUE)
    session$setInputs(da = "Macaronesia")
    expect_match(as.character(output$body$html), "modules.wp5_governance.cards_title", fixed = TRUE)
  })
})

test_that("Add to register writes one measure; a second click does not (review focus 5)", {
  reg <- fake_register()
  rec <- tus$recommendations[[1]]
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = reg), {
    session$flushReact()
    expect_match(as.character(output$recommendations$html), "modules.wp5_governance.add_to_register", fixed = TRUE)
    session$setInputs(add_rec = rec$id)
    m <- shiny::isolate(reg$store())
    expect_equal(nrow(m), 1L)
    expect_equal(c(m$Name, m$Kind, m$Status, m$EbmCode), c(rec$title, "instrument", "proposed", rec$ebm_code))
    session$setInputs(add_rec = rec$id)
    expect_equal(nrow(shiny::isolate(reg$store())), 1L)
    expect_match(as.character(output$recommendations$html), "modules.wp5_governance.already_in_register", fixed = TRUE)
  })
})

test_that("missing reference data shows the notice", {
  old <- get("load_wp5_governance_profiles", envir = .GlobalEnv)
  assign("load_wp5_governance_profiles", function(...) NULL, envir = .GlobalEnv)
  withr::defer(assign("load_wp5_governance_profiles", old, envir = .GlobalEnv))
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    expect_match(as.character(output$body$html), "modules.wp5_governance.unavailable", fixed = TRUE)
  })
})

test_that("inside the Response module, Add to register lands in the register and the project", {
  pd <- shiny::reactiveVal(proj_da("Tuscan Archipelago"))
  rec <- tus$recommendations[[1]]
  testServer(real_rm_server, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    do.call(session$setInputs, stats::setNames(list(rec$id), "gov_ctx-add_rec"))
    expect_equal(nrow(response_data$measures), 1L)
    expect_equal(response_data$measures$ID, "RM001")
    expect_equal(pd()$data$response_measures$measures$Name, rec$title)
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^wp5-governance-context-module$'`.

- [ ] **Step 3: Create `modules/wp5_governance_context_module.R`:**

```r
# modules/wp5_governance_context_module.R
# =============================================================================
# WP5 WS-9a (spec 2026-10-17 §5): D5.4 governance context of a demonstration
# area — barrier/enabler cards (Tables 5-7) and recommendation cards with
# "Add to register". Mounted as a tab of the Response module, which passes a
# register API so the register stays the single writer of its measures.
# Depends on: functions/wp5_governance.R, functions/stakeholder_schema.R
# =============================================================================

# i18n-ref: modules.wp5_governance.dimension.knowledge
# i18n-ref: modules.wp5_governance.dimension.collaboration
# i18n-ref: modules.wp5_governance.dimension.values_conflicts
# i18n-ref: modules.wp5_governance.dimension.legitimacy
# i18n-ref: modules.wp5_governance.dimension.cross_sectoral
# i18n-ref: modules.wp5_governance.polarity.enabler
# i18n-ref: modules.wp5_governance.polarity.barrier
# i18n-ref: modules.wp5_governance.sub_area_greenland
# i18n-ref: modules.wp5_governance.sub_area_iceland
# i18n-ref: modules.wp5_governance.sub_area_faroe_islands
# i18n-ref: modules.wp5_governance.sub_area_azores
# i18n-ref: modules.wp5_governance.sub_area_madeira
# i18n-ref: modules.wp5_governance.sub_area_canaries
# i18n-ref: modules.wp5_governance.context_title
# i18n-ref: modules.wp5_governance.context_note
# i18n-ref: modules.wp5_governance.filter_da
# i18n-ref: modules.wp5_governance.project_da
# i18n-ref: modules.wp5_governance.filter_dimension
# i18n-ref: modules.wp5_governance.filter_polarity
# i18n-ref: modules.wp5_governance.filter_sub_area
# i18n-ref: modules.wp5_governance.all
# i18n-ref: modules.wp5_governance.both
# i18n-ref: modules.wp5_governance.all_sub_areas
# i18n-ref: modules.wp5_governance.unavailable
# i18n-ref: modules.wp5_governance.english_source
# i18n-ref: modules.wp5_governance.no_da_hint
# i18n-ref: modules.wp5_governance.cards_title
# i18n-ref: modules.wp5_governance.no_cards
# i18n-ref: modules.wp5_governance.recommendations_title
# i18n-ref: modules.wp5_governance.no_recommendations
# i18n-ref: modules.wp5_governance.ebm_code
# i18n-ref: modules.wp5_governance.governance_level
# i18n-ref: modules.wp5_governance.add_to_register
# i18n-ref: modules.wp5_governance.already_in_register
# i18n-ref: modules.wp5_governance.added_to_register
# i18n-ref: modules.wp5_governance.context_add

wp5_governance_context_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tr <- function(k) i18n$t(paste0("modules.wp5_governance.", k))
  profiles <- load_wp5_governance_profiles()
  sites <- if (is.null(profiles)) character(0) else unname(vapply(profiles$das, `[[`, "", "da_site"))
  tagList(
    h4(tr("context_title")),
    tags$small(class = "text-muted", tr("context_note")),
    hr(),
    fluidRow(
      column(3, selectInput(ns("da"), tr("filter_da"),
                            choices = c(stats::setNames("", tr("project_da")), stats::setNames(sites, sites)))),
      column(3, selectInput(ns("dimension"), tr("filter_dimension"),
                            choices = c(stats::setNames("", tr("all")), stats::setNames(WP5_GOV_DIMENSIONS,
                              vapply(WP5_GOV_DIMENSIONS, function(d) tr(paste0("dimension.", d)), character(1)))))),
      column(3, selectInput(ns("polarity"), tr("filter_polarity"),
                            choices = c(stats::setNames("", tr("both")), stats::setNames(WP5_GOV_POLARITIES,
                              vapply(WP5_GOV_POLARITIES, function(p) tr(paste0("polarity.", p)), character(1)))))),
      column(3, uiOutput(ns("sub_area_ui")))
    ),
    uiOutput(ns("body"))
  )
}

wp5_governance_context_server <- function(id, project_data_reactive, i18n, event_bus = NULL, register = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    tr <- function(k) i18n$t(paste0("modules.wp5_governance.", k))
    profiles <- load_wp5_governance_profiles()
    src_badge <- function() span(class = "badge badge-light ml-1", tr("english_source"))

    project_site <- reactive(tryCatch(project_data_reactive()$data$metadata$da_site %||% "",
                                      error = function(e) ""))
    da <- reactive({
      v <- input$da %||% ""
      if (nzchar(v)) v else project_site()
    })
    profile <- reactive(wp5_gov_profile_for_site(profiles, da()))

    output$sub_area_ui <- renderUI({
      subs <- unlist(profile()$sub_areas)
      if (!length(subs)) return(NULL)
      selectInput(ns("sub_area"), tr("filter_sub_area"),
                  choices = c(stats::setNames("", tr("all_sub_areas")),
                              stats::setNames(subs, vapply(subs, function(s) tr(paste0("sub_area_", s)), character(1)))))
    })

    card_ui <- function(cd) {
      div(class = "border rounded p-2 mb-2",
        span(class = paste("badge", if (identical(cd$polarity, "enabler")) "badge-success" else "badge-danger"),
             tr(paste0("polarity.", cd$polarity))),
        if (!is.null(cd$sub_area)) span(class = "badge badge-info ml-1", tr(paste0("sub_area_", cd$sub_area))),
        p(class = "small mb-1 mt-1", cd$text, src_badge()),
        tags$small(class = "text-muted", cd$source_ref))
    }

    output$body <- renderUI({
      if (is.null(profiles)) return(div(class = "alert alert-warning", tr("unavailable")))
      prof <- profile()
      if (is.null(prof)) return(div(class = "alert alert-light", tr("no_da_hint")))
      cards <- wp5_gov_filter_cards(prof, input$dimension %||% "", input$polarity %||% "", input$sub_area %||% "")
      dims <- intersect(WP5_GOV_DIMENSIONS, vapply(cards, `[[`, "", "dimension"))
      tagList(
        h5(tr("cards_title")),
        if (!length(cards)) p(class = "text-muted", tr("no_cards")),
        lapply(dims, function(d) tagList(
          h6(class = "mt-3", tr(paste0("dimension.", d))),
          lapply(Filter(function(cd) identical(cd$dimension, d), cards), card_ui))),
        h5(class = "mt-4", tr("recommendations_title")),
        uiOutput(ns("recommendations")))
    })

    # i18n-ref: modules.response.governance.level.local
    # i18n-ref: modules.response.governance.level.island
    # i18n-ref: modules.response.governance.level.regional
    # i18n-ref: modules.response.governance.level.national
    # i18n-ref: modules.response.governance.level.eu
    # i18n-ref: modules.response.governance.level.regional_sea
    # i18n-ref: modules.response.governance.level.international
    output$recommendations <- renderUI({
      prof <- profile(); req(prof)
      recs <- prof$recommendations %||% list()
      if (!length(recs)) return(p(class = "text-muted", tr("no_recommendations")))
      reg <- if (is.null(register)) NULL else register$measures()
      lapply(recs, function(r) {
        div(class = "border rounded p-2 mb-2",
          strong(r$title), src_badge(),
          p(class = "small mb-1", r$text),
          tags$small(class = "text-muted d-block",
            tr("ebm_code"), ": ", r$ebm_code, " ", wp5_vocab_label("instrument", r$ebm_code, i18n), " · ",
            tr("governance_level"), ": ", i18n$t(paste0("modules.response.governance.level.", r$governance_level)),
            " · ", r$source_ref),
          if (is.null(register)) NULL
          else if (wp5_gov_in_register(reg, r$title)) span(class = "badge badge-secondary mt-1", tr("already_in_register"))
          else tags$button(type = "button", class = "btn btn-sm btn-outline-success mt-1",
                           onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("add_rec"), r$id),
                           icon("plus"), tr("add_to_register")))
      })
    })

    observeEvent(input$add_rec, {
      req(!is.null(register))
      prof <- profile(); req(prof)
      rec <- Find(function(r) identical(r$id, input$add_rec), prof$recommendations)
      req(rec)
      if (wp5_gov_in_register(register$measures(), rec$title)) return()
      sh <- tryCatch(project_data_reactive()$data$pims$stakeholders, error = function(e) NULL)
      tryCatch({
        new_id <- register$add(wp5_gov_recommendation_measure(rec, sh))
        showNotification(paste(tr("added_to_register"), new_id), type = "message")
      }, error = function(e) {
        debug_log(paste("WP5 governance: add to register failed:", e$message), "ERROR")
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.wp5_governance.context_add"),
                         type = "error")
      })
    })

    invisible(list(profile = profile))
  })
}
```

- [ ] **Step 4: Mount it.**
  - `modules/response_module.R` UI: replace

```r
            uiOutput(ns("wp5_reference_pane"))
          )
        )
```

with

```r
            uiOutput(ns("wp5_reference_pane"))
          ),

          # Tab 7: WP5 governance context (D5.4, WS-9a) ----
          tabPanel(i18n$t("modules.wp5_governance.context_tab"),
            if (exists("wp5_governance_context_ui", mode = "function"))
              wp5_governance_context_ui(ns("gov_ctx"), i18n)
          )
        )
```

  - `modules/response_module.R` server, directly after the `observeEvent(project_data_reactive()$project_id, { rm <- ...; ... }, ignoreNULL = FALSE)` block:

```r
    # WS-9a: the governance-context tab adds D5.4 recommendations through the
    # register (it reloads its state only on project change, so nothing else may
    # write response_measures directly)
    register_api <- list(
      measures = reactive(response_data$measures),
      add = function(fields) {
        response_data$counter <- response_data$counter + 1
        new_id <- next_element_id(ELEMENT_ID_PREFIX$measures, response_data$counter)
        row <- normalize_response_measures(as.data.frame(c(list(ID = new_id), fields), stringsAsFactors = FALSE))
        response_data$measures <- rbind(normalize_response_measures(response_data$measures), row)
        sync_to_project_data()
        new_id
      })
    if (exists("wp5_governance_context_server", mode = "function")) {
      wp5_governance_context_server("gov_ctx", project_data_reactive, i18n, event_bus = event_bus, register = register_api)
    }
```

  - `app.R`: in `OPTIONAL_MODULES` immediately before `"modules/response_module.R",` add `"modules/wp5_governance_context_module.R",   # WS-9a D5.4 governance tab (sub-module of the Response module)`.

- [ ] **Step 5: Run tests** — `'^wp5-governance-context-module$'`, `'^response-module$'`, `'^response-measures-schema$'`, `'^analysis-modules-batch$'`, `'^i18n-enforcement$'`; audit `missing=0 hardcoded=0`.

- [ ] **Step 6: Commit** — `feat(wp5): D5.4 governance context tab with Add to register (WS-9a)`.

---

### Task 8: `Policy_Target` on indicators

**Files:**
- Modify: `constants.R` (`ISA_INDICATOR_COLUMNS`), `functions/indicator_snapshot.R` (`.IND_INPUT_IDS`; new `project_has_policy_target()`), `functions/isa_form_builders.R` (`build_field()`, `isa_indicator_fields()`, indicator help row), `modules/isa_data_entry_module.R` (save path ~line 302)
- Test: `tests/testthat/test-indicator-snapshot.R` (append)

**Interfaces:** Consumes `WP5_POLICY_TARGETS`, `WP5_GOVERNANCE_MIN_APP_VERSION`, Task 5 keys. Produces element column `Policy_Target`, panel input `<prefix>_policytarget_<id>`, `project_has_policy_target(isa_data)`.

- [ ] **Step 1: Append failing tests** to `tests/testthat/test-indicator-snapshot.R`:

```r
# ---- WS-9a: Policy_Target -----------------------------------------------------
test_that("Policy_Target is an indicator column, a panel input and is collected", {
  expect_true("Policy_Target" %in% ISA_INDICATOR_COLUMNS)
  ui <- as.character(build_entry_panel_ui(shiny::NS("m"), "p", "P001",
                     isa_fields_p(make_test_i18n(), c("")), make_test_i18n()))
  expect_match(ui, "m-p_policytarget_P001", fixed = TRUE)
  expect_match(ui, 'value="kmgbf_30x30"', fixed = TRUE)
  expect_match(ui, "modules.indicator_registry.policy_target_help", fixed = TRUE)
  out <- collect_indicator_inputs(list(p_policytarget_P001 = "Regional 20% target"), "p", c("P001", "P002"))
  expect_equal(out$Policy_Target, c("Regional 20% target", ""))
})

test_that("Policy_Target survives a carried-over save and a JSON load; legacy rows read ''", {
  existing <- data.frame(ID = "GB001", Name = "Fish catch", Policy_Target = "eu_nrr", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, data.frame(), "GB001", character(0), c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(out$Policy_Target, "eu_nrr")
  pd <- list(data = list(isa_data = list(goods_benefits = existing)))
  back <- normalize_json_project_data(jsonlite::fromJSON(jsonlite::toJSON(pd, auto_unbox = TRUE), simplifyVector = FALSE))
  expect_equal(indicator_col(back$data$isa_data$goods_benefits, "Policy_Target"), "eu_nrr")
  legacy <- data.frame(ID = "GB002", Name = "x", stringsAsFactors = FALSE)
  expect_equal(indicator_col(legacy, "Policy_Target"), "")
})

test_that("project_has_policy_target and the save stamp", {
  expect_false(project_has_policy_target(list(activities = data.frame(ID = "A001", Policy_Target = ""))))
  expect_true(project_has_policy_target(list(activities = data.frame(ID = "A001", policy_target = "eu_nrr"))))
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    isa_data$pressures <- data.frame(ID = "P001", Name = "Overfishing", stringsAsFactors = FALSE)
    session$setInputs(add_a = 1)
    aid <- isa_data$a_panel_ids[[length(isa_data$a_panel_ids)]]
    set_panel(session, "a", aid, name = "Fishing", policytarget = "kmgbf_30x30")
    session$setInputs(save_ex4 = 1)
    expect_equal(indicator_col(isa_data$activities, "Policy_Target"), "kmgbf_30x30")
    expect_equal(pdr()$min_app_version, WP5_GOVERNANCE_MIN_APP_VERSION)
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^indicator-snapshot$'`.

- [ ] **Step 3: Implement.**
  - `constants.R`: `ISA_INDICATOR_COLUMNS <- c("Indicator", "Indicator_Unit", "Data_Source", "Registry_Id", "Registry_Version", "Policy_Target")`.
  - `functions/indicator_snapshot.R`: `.IND_INPUT_IDS <- c(Indicator = "indicator", Indicator_Unit = "indunit", Data_Source = "datasource", Registry_Id = "registry", Policy_Target = "policytarget")`; after `project_has_registry_snapshot()` add

```r
#' TRUE when any of the six element frames holds a non-empty Policy_Target (WS-9a)
project_has_policy_target <- function(isa_data) {
  if (!is.list(isa_data)) return(FALSE)
  any(vapply(ISA_ELEMENT_KEYS, function(k) any(nzchar(indicator_col(isa_data[[k]], "Policy_Target"))),
             logical(1)))
}
```

  - `functions/isa_form_builders.R`, in `build_field()` inside the `identical(field$type, "select")` branch, before `if (isTRUE(field$multiple))`:

```r
      if (isTRUE(field$create)) {
        # WS-9a: picklist that also accepts free text
        return(column(field$width, selectizeInput(input_id, field$label, choices = field$choices,
                                                  options = list(create = TRUE, placeholder = ""))))
      }
```

  - `isa_indicator_fields()`: widths `registry` 3, `indicator` 3, `indunit` 2, `datasource` 2, and append

```r
    # i18n-ref: modules.indicator_registry.policy_target.kmgbf_30x30
    # i18n-ref: modules.indicator_registry.policy_target.eu_nrr
    # i18n-ref: modules.indicator_registry.policy_target.msfd_ges_d1
    # i18n-ref: modules.indicator_registry.policy_target.msfd_ges_d6
    # i18n-ref: modules.indicator_registry.policy_target.national_mpa_pct
    list(id = "policytarget", type = "select", create = TRUE, width = 2,
         label = i18n$t("modules.indicator_registry.field_policy_target"),
         choices = c(stats::setNames("", ""), stats::setNames(WP5_POLICY_TARGETS, vapply(WP5_POLICY_TARGETS,
           function(t) i18n$t(paste0("modules.indicator_registry.policy_target.", t)), character(1)))))
```

  - In `build_entry_panel_ui()`'s `row3` help column, after `tags$small(class = "text-muted", i18n$t("modules.indicator_registry.picker_help"))`, add `, tags$br(), tags$small(class = "text-muted", i18n$t("modules.indicator_registry.policy_target_help"))`.
  - `modules/isa_data_entry_module.R`, after the registry-snapshot stamp block:

```r
      # WS-9a: Policy_Target is a new element column older apps drop
      if (project_has_policy_target(pd$data$isa_data)) {
        pd <- stamp_min_app_version(pd, WP5_GOVERNANCE_MIN_APP_VERSION)
      }
```

- [ ] **Step 4: Run tests** — `'^indicator-snapshot$'`, `'^indicator-registry$'`, `'^json-project-loading$'`, `'^isa-'`, `'^i18n-enforcement$'`; audit `missing=0 hardcoded=0`.

- [ ] **Step 5: Commit** — `feat(wp5): optional Policy_Target on indicators (WS-9a)`.

---

### Task 9: Release 1.30.0 and full verification

**Files:** `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`

- [ ] **Step 1: Release files** (follow the 1.29.0 commit's conventions — `git -C <wt> show HEAD~N -- MarineSABRES_SES_Shiny/VERSION_INFO.json` for the 1.29.0 release commit): `VERSION` → `1.30.0`; `DESCRIPTION` `Version: 1.30.0`; `VERSION_INFO.json`: version 1.30.0, version_name "WP5 governance profiles (D5.4)", release_date today, release_type minor, previous_version 1.29.0, features ending " (WS-9a).": the governance-context tab (barrier/enabler cards from D5.4 Tables 5–7, recommendation cards with Add to register); "Load DA actor list" and the D5.4 roles column in PIMS; `Policy_Target` on indicators; Greenland, Faroe Islands and seven regional bodies in the country database; and under `fixes.medium` "Adding a second stakeholder, engagement, communication or response measure created duplicate rows (since 1.16.5)." `CHANGELOG.md`: `## [1.30.0] - <today>` under `## [Unreleased]` with `### Added (WP5 governance profiles — spec 2026-10-17 WS-9a)`, `### Fixed` (the duplicate-rows bug), `### Notes` (findings are qualitative; power/interest grids only where published — Tuscany, Madeira; the readiness questionnaire follows in WS-9b; the Type field still stores translated labels).
- [ ] **Step 2: Full verification** (one Rscript per chunk, foreground, sequential): filters `'^[a-c]'`, `'^[d-h]'`, `'^[i-l]'`, `'^[m-o]'`, `'^[p-s]'`, `'^[t-z]'` with `reporter = 'summary'` → no "Failed" section in any chunk; `micromamba run -n shiny python -m pytest scripts/tests -q -p no:cacheprovider` → all pass; audit `missing=0 hardcoded=0`; `Rscript deployment/pre-deploy-check.R` → all pass. Report per chunk: failures, skips, warnings. If a failure appears, attribute it (branch vs pre-existing, by running that file in the main checkout at `C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny`, read-only) and report it — do not fix it in this task.
- [ ] **Step 3: Commit** release files only — `chore(release): 1.30.0 — WP5 governance profiles (WS-9a)`.
