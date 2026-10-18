# WP5 WS-10: Workshop elicitation (ranking poll + 11-tenet rating) — design

Date: 2026-10-18. Status: approved in brainstorming (sections 1–3), awaiting spec review.
Parent spec: `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-10.
Source audit: `docs/wp5-source-audit/2026-10-11/A_D5.2_audit.md` §7 (7.1 ranking poll, 7.2 tenet assessment).
Builds on: WS-3 (register `Tenet_*` columns, `EBM_TENETS`, `TENET_LEVELS`), WS-9a (`register_api`), WS-9b (anonymous entry engine: form + template import, id counter, PDF verification pattern).
Release: 1.32.0. Execution: subagent-driven.

## 1. Purpose and scope

A demonstration-area facilitator runs a stakeholder workshop on candidate interventions (measures from the project's Response register) and records two D5.2 instruments per anonymous participant:

1. an **intervention-ranking poll** with a configurable scale (Arctic precedent −5…+5; Macaronesia precedent 1–4) on one or more criteria (importance, feasibility, long-term impact);
2. an **11-tenet rating** per intervention on the D5.2 Annex 4 five-point agree scale, each tenet with its Annex 4 guiding question.

The toolbox summarises the answers and can, measure by measure and only on the facilitator's confirmation, write the tenet results back into the register's `Tenet_*` columns.

**Out of scope (deferred):** importing the Annex 4 Arctic tick-mark results as demonstration data (audit §7.2: needs decoding from column positions, verified against the PDF); free-text answers (top-3 reasons, expected impacts, country challenges — privacy, and not scored); writing poll results to the register (no register field); live participant self-entry on their own devices (facilitator mode only).

## 2. Decisions taken in brainstorming

| # | Decision |
|---|---|
| D1 | Interventions = measures selected from the project's Response register (by register ID). |
| D2 | Write-back is mapped and confirmed per measure (§6). |
| D3 | Several workshops per project; each holds both instruments (tenet rating can be switched off). |
| D4 | Participants are anonymous; the facilitator enters one participant at a time, or imports a template. |
| D5 | Guiding questions are curated JSON verified word for word against the D5.2 PDF, translated into 9 languages for participants. |
| D6 | New PIMS sidebar page with its own module (next to Governance readiness). |
| D7 | Provenance of written tenet values is a new register column `TenetSource`. |

## 3. Guiding questions

### 3.1 Source

`WP5/D5.2/MarineSABRES_D5.2_Final.pdf`, Annex 4 tenet form, printed pages 219–222 (printed page = PDF page). The form numbers "3." twice and skips "7."; the toolbox uses `EBM_TENETS` order and ignores the form numbering. A probe (2026-10-18) confirmed all 11 questions extract cleanly with PyMuPDF; line-break hyphens vanish under the letters-and-digits `key()` comparison.

### 3.2 `data/wp5_tenet_guiding_questions.json`

```json
{
  "version": 1,
  "source": "D5.2 Final, Annex 4 tenet assessment form",
  "source_file": "WP5/D5.2/MarineSABRES_D5.2_Final.pdf",
  "scale": ["completely_disagree", "disagree", "neutral", "agree", "completely_agree"],
  "questions": [
    {"tenet": "ecol_effective", "text_en": "To what extent does this measure contribute to achieving environmental targets and safeguarding ecosystem features and functioning?", "source_page": 219}
  ]
}
```

Eleven entries, one per `EBM_TENETS$code`, in that order. Texts (from the probe; the pytest is the authority):

| tenet | text_en | p. |
|---|---|---|
| ecol_effective | To what extent does this measure contribute to achieving environmental targets and safeguarding ecosystem features and functioning? | 219 |
| tech_feasible | Is the necessary technology available and proven to support the implementation and long-term maintenance of this measure? | 219 |
| econ_efficient | Does this measure offer good value for money compared to other alternatives, considering both costs and benefits? | 219–220 |
| econ_viable | Will this measure improve economic viability, both in the short-term and long-term, considering revenue relative to costs? | 220 |
| socially_desirable | To what extent do you believe stakeholders will support this measure, or might there be resistance? | 220 |
| ethically_defensible | To what extent is this measure ethically sound and morally acceptable? | 220 |
| culturally_inclusive | To what extent does this measure consider and respect local customs and practices? | 220 |
| legally_permissible | To what extent does this measure comply with existing regional, national, and international laws and regulations? | 221 |
| admin_achievable | To what extent are the administrative processes and transaction costs manageable for implementing this measure? | 221 |
| communicable | To what extent can this measure be effectively communicated to the public, and does it align with the current political landscape? | 221 |
| politically_expedient | To what extent does this measure align with the prevailing political climate and have the support of political leaders? | 222 |

`source_page` stores the first page; `econ_efficient` spans 219–220 (the pytest matches every question on the joined text of pp. 219–222).

**Scale codes and points:** `completely_disagree` = 1 … `completely_agree` = 5; `dont_know` is an extra answer code, never a number. D5.2 prints only the anchors "Completely Disagree – Neutral – Completely Agree"; the toolbox labels points 2 and 4 "Disagree" / "Agree" (ruling, reversible).

### 3.3 Translations

`translations/modules/wp5_workshop.json`: UI chrome plus `modules.wp5_workshop.question.<tenet>` × 9 languages. Tenet names reuse `wp5_vocab_label("tenet", code, i18n)`. Answer labels for the agree scale and the poll criteria are new keys in this file. Sidebar key `ui.sidebar.workshop_elicitation`.

## 4. Storage

`data$data$pims$workshops` (next to WS-9b's `data$data$pims$readiness`; normalised by `normalize_workshops()` on every JSON load path and before every module write):

```
list(
  version  = 1,
  counter  = <int, highest W-number ever issued>,
  items    = list(<workshop>, ...)
)
<workshop> = list(
  id = "W001", title = "", date = "YYYY-MM-DD", note = "",
  interventions = c("RM003", "RM007"),        # register IDs (ELEMENT_ID_PREFIX$measures = "RM"), facilitator order
  poll = list(scale = "pm5" | "four", criteria = c("importance", ...)),
  tenets_on = TRUE,
  consent = FALSE,                             # facilitator confirmation, required before any entry
  counter = <int, highest P-number ever issued in this workshop>,
  respondents = data.frame(RespondentId, EnteredAt, Source, <answer columns>),
  applied = list(<apply record>, ...)          # §6 Undo
)
```

- `date`: `YYYY-MM-DD` or "" (anything else is blanked on normalisation); defaults to today on New.
- Measure IDs are embedded in column names, so only register IDs matching `^[A-Za-z0-9]+$` can be selected; others are listed disabled with a note (all IDs the app itself issues match).
- `poll$scale`: `pm5` = integers −5…+5; `four` = integers 1–4. Default `pm5`. `poll$criteria` ⊆ `WORKSHOP_POLL_CRITERIA = c("importance", "feasibility", "long_term_impact")`, at least one, default `"importance"`.
- Answer columns: `rank__<measureId>__<criterion>` (character integer or "") and, when `tenets_on`, `tenet__<measureId>__<tenet>` (scale code, `dont_know` or "").
- Normalisation keeps only meta columns and answer columns matching `^rank__<id>__(importance|feasibility|long_term_impact)$` / `^tenet__<id>__(<11 tenet codes>)$` whose measure id is in `interventions`; values outside the allowed set are blanked and logged with `debug_log`. Ids use `safe_counter()` + `next_element_id()` (`W` prefix for workshops, `P` for participants) so ids are never reused after deletes.
- Poll values are stored as ASCII strings (`"-5"` … `"5"`, hyphen-minus); the UI may display a typographic minus.
- **Locking:** while a workshop has ≥ 1 respondent, `interventions`, `poll` and `tenets_on` cannot change (deleting every respondent unlocks it); "Duplicate set-up" copies them into a new, empty workshop.
- **Version mark:** `WP5_WORKSHOP_MIN_APP_VERSION <- "1.32.0"`; a project is stamped when it has ≥ 1 workshop (even with no respondents yet — an older app would drop the set-up) or any register row with a non-empty `TenetSource` (it can outlive deleted respondents). It is stamped via `stamp_min_app_version()` in two places, exactly as WS-9b: (a) the module's write helper (`modules/wp5_readiness_module.R` `write_readiness()` pattern), and (b) the JSON load normalisation block in `functions/data_structure.R` (next to the readiness block, ~L1012), which also runs `normalize_workshops()`.

**Register addition:** `TenetSource` appended to `RM_REGISTER_COLUMNS` (`constants.R`) and handled by `normalize_response_measures()` (default ""). It stays out of `RM_DISPLAY_COLUMNS` (like the `Tenet_*` columns) and the add-measure form; it is shown on the workshop's Apply cards and included in the register Excel export.

## 5. Summaries (pure, `functions/wp5_workshop.R`)

- `workshop_poll_summary(ws)` → one row per measure × criterion: `n` (non-blank answers), `median`, `mean`, counts per scale value. Sorted by the first criterion's median (desc), ties by mean (desc), then intervention order.
- `workshop_tenet_summary(ws)` → one row per measure × tenet: `n_valid` (answers 1–5), `n_dont_know`, `median` (of 1–5; plain `stats::median`, so x.5 is possible), counts per point.
- No small-cell suppression (there are no subgroups).

## 6. Write-back

`workshop_writeback_proposal(ws, measures)` → per workshop measure still present in `measures`: 11 rows `tenet, current, median, n_valid, proposed, changed`.

| median | `ecol_effective` | other 10 tenets |
|---|---|---|
| ≥ 4 | full | full |
| 3 ≤ m < 4 | intermediate | minimal |
| < 3 | minimal | minimal |

(`TENET_LEVELS`: "intermediate" exists only for ecological effectiveness — `constants.R` comment.)

- `n_valid < 3` → `proposed = NA` ("too few ratings"), never written.
- `changed = !is.na(proposed) & proposed != current`.
- "Apply to this measure" writes only changed rows plus `TenetSource` = "Workshop W001 (2026-10-18, n = 12)" (date = the workshop's `date`, or the apply date when blank; n = max `n_valid` among written rows; built from a translated template with placeholders, in the facilitator's language at apply time). Disabled, with "matches register", when no row changed.
- Measures no longer in the register are listed as "(no longer in register)" and skipped.
- Poll results are never written.

**Undo last apply.** The register has no edit path (`response_module.R` only adds and deletes measures), so each Apply is reversible from the workshop:

- Every Apply appends to the workshop's `applied` list: `list(measure = "RM003", at = "<ISO time>", before = <named list of the written Tenet_* columns + TenetSource, prior values>, after = <same names, values written>)`.
- Each card shows "Undo last apply" when the workshop's latest `applied` entry for that measure exists. `workshop_undo_check(entry, measures)` returns `ok` only if the register row still holds exactly `after` for those columns; then `register$update(id, before)` restores them and the entry is removed.
- Otherwise Undo is refused with a translated message ("the register has changed since this apply") and nothing is written; a measure no longer in the register is refused the same way.
- Undo is one level per measure per workshop (the latest entry); earlier entries are undone in turn after it.
- `applied` is normalised like the rest of the workshop (entries with unknown measures or malformed `before`/`after` are dropped and logged).

**Register access:** `response_measures_server()` now **returns** its `register_api`, extended with `update(id, fields)` (merges `fields` into the row with that ID, re-normalises, calls `sync_to_project_data()`; returns FALSE when the ID is absent). `app.R` captures the return value and passes it as `register =` to `wp5_workshop_server()`, which is called after `response_measures_server()` (currently `app.R:1068`, after the PIMS servers). Within one Apply/Undo handler the order is: `register$update()` first (it writes `project_data_reactive`), then the workshop write helper re-reads `project_data_reactive()` and records/removes the `applied` entry — never a `pd` captured before the update, which would revert the register write. The workshop module never writes `data$response_measures` directly: the response module reloads its state only on project change and would overwrite such a write on its next sync.

## 7. Module `modules/wp5_workshop_module.R`

PIMS page `pims_workshops`; signature `wp5_workshop_server(id, project_data_reactive, i18n, event_bus = NULL, register = NULL)`. Four tabs:

The module's own state is `data$data$pims$workshops`, read from `project_data_reactive()` and written through one write helper (normalise → stamp → `project_data_reactive(pd)`), as WS-9b does; no other module writes it. Register measures are read from `register$measures()` when `register` is given, else from `project_data_reactive()$data$response_measures$measures`.

1. **Set-up** — workshop picker; New / Rename / Duplicate set-up / Delete (Delete confirms via modal stating the respondent count and, if any, that values already applied to the register stay there and can no longer be undone); title, date, note; selectize of register measures ("ID — Name") in pick order (an empty register shows "add measures in the Response register first"); scale radio; criteria checkboxes; tenet on/off. Locked fields are disabled with an explanation once respondents exist.
2. **Entry** — consent checkbox per workshop, stored as `consent` (the facilitator confirms once for the group, unlike WS-9b's per-respondent box); server-enforced for both form save and import; per measure: one select per criterion (scale values + blank) and, if on, an 11-row grid (5 points + don't know + blank) with the guiding question as help text; "Save participant and next" appends and resets; an all-blank participant is refused. Template import (xlsx, or csv with comma or semicolon) with columns `rank__…` / `tenet__…` exactly as stored; labels accepted in any of the 9 languages, accent-folded — by reusing (not copying) WS-9b's `readiness_translations(path = <wp5_workshop.json>)`, `readiness_value_map()` and `.ready_key()` from `functions/wp5_readiness.R`, and `readiness_read_file()` for xlsx/csv reading; a template whose columns name measures, criteria or tenets not in the workshop is refused with a message naming them; invalid values are blanked and counted; all-blank rows dropped and counted. Template download prefilled with the workshop's columns. Respondent table with "Delete selected" (confirm modal).
3. **Results** — poll ranking table; per measure × criterion a small HTML bar row of the distribution (renderUI, as WS-9b's distributions; no new plotting dependency); tenet heat table (median, coloured by the §6 bands ≥ 4 / 3–4 / < 3, grey when `n_valid < 3`; `n_valid` and `n_dont_know` in a tooltip); xlsx export (sheets: setup, respondents, poll_summary, tenet_summary).
4. **Apply to register** — one card per measure (§6) with Apply and Undo last apply; disabled with a note when `register` is NULL or the tenet rating is off.

All text via `i18n$t()`; errors via `format_user_error(e, i18n = i18n, context_key = ...)`.

## 8. Errors

- Malformed project data never blocks loading: normalisation drops/blanks and logs.
- Import refusals and counts are shown as translated notifications.
- Apply or Undo on a measure removed between render and click: `register$update()` returns FALSE → warning notification, nothing written (and no `applied` entry is added or removed).
- Template and export use English column headers (as WS-9b; parked follow-up).

## 9. Testing

- **testthat helpers** (`test-wp5-workshop.R`): normalisation (unknown columns, out-of-range values, measures not in `interventions`); id counters never reuse after delete (workshops and participants); poll summary incl. sort; tenet summary incl. even-n median and `dont_know` exclusion; mapping at boundaries (2.5, 3, 3.5, 4) for `ecol_effective` and one other tenet; n < 3 rule; `changed` logic; import parsing (multilingual labels, accent folding, semicolon CSV, foreign columns refused, blank rows dropped); template → import round trip; export sheets; min-version stamp on module write and on JSON load, for each trigger (workshop without respondents; `TenetSource` only).
- **Register API**: `update()` merges fields, re-normalises, returns FALSE for an unknown ID; `TenetSource` survives normalisation.
- **Module** (`test-wp5-workshop-module.R`): signature contract; `testServer()` behaviour (re-bound from `.GlobalEnv`): consent gate blocks a save; set-up locked after the first respondent; Apply writes only changed tenets + `TenetSource` through a fake `register`; removed measure skipped; Undo restores the `before` values and is refused once the register row differs from `after`; after Apply the project holds both the register write and the `applied` entry (ordering guard, §6).
- **Undo helper**: `workshop_undo_check()` ok / changed-since / measure-gone cases; an Apply → Undo round trip leaves the register identical to before.
- **pytest** `scripts/tests/test_wp5_tenet_questions.py`: 11 entries in `EBM_TENETS` order; each `text_en` found (key-normalised) in the joined text of printed pp. 219–222; skips without the WP5 folder.
- i18n audit `missing=0 hardcoded=0`; `test-functions-sourced-in-app.R` covers `functions/wp5_workshop.R`.

## 10. Release

1.32.0: VERSION, CHANGELOG, `WP5_WORKSHOP_MIN_APP_VERSION`. Worktree `C:/Users/arturas.baziukas/wt-ws10`, branch `feat/wp5-ws10-workshop-elicitation` from main 4b53b7d. Subagent-driven; full suite in alphabetical chunks, pytest, i18n audit and pre-deploy check before the finish menu.

## 11. Rulings (reversible)

- Scale points 2 / 4 labelled Disagree / Agree (D5.2 prints only the end and middle anchors).
- `n_valid < 3` → no proposal.
- `TenetSource` n = max `n_valid` across the written tenets.
- Poll inputs are selects (not sliders) so a blank answer is possible.
