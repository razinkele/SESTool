# WP5 WS-9b: Governance-readiness check (D5.4 questionnaire) — design

Date: 2026-10-17. Status: approved in brainstorming (sections 1–3), awaiting spec review.
Parent spec: `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-9 feature 3.
Source audit: `docs/wp5-source-audit/2026-10-11/D_D5.4_governance.md` §4.
Builds on WS-9a (1.30.0): `NPG_DIMENSIONS`, the D5.4 PDF verification pattern.
Release: 1.31.0. Execution: subagent-driven.

## 1. Purpose and scope

A demonstration-area team collects the D5.4 stakeholder questionnaire from several anonymous respondents and sees, per NPG dimension, how the governance situation is perceived. The per-dimension number is a toolbox construct ("toolbox indicator, not a WP5 score"): D5.4 used the questionnaire descriptively, with no validated index or thresholds.

**Out of scope (deferred):** free-text "please explain" answers (privacy); a score for cross-sectoral coordination (no D5.4 item); validating the indicator (partner question Q6); reusing the entry engine for WS-10 workshop polls (decided at WS-10).

## 2. Decisions taken in brainstorming

| # | Decision |
|---|---|
| D1 | Several anonymous respondents per project (not a single self-assessment). |
| D2 | Answers enter through an in-app form (one respondent at a time) and an xlsx template import. |
| D3 | Only current-state items feed the indicator; attitude items and the Annex 7 priority ranking are shown as distributions next to it. |
| D4 | Item text is translated into 9 languages (respondents read it); the English D5.4 wording is the source and is verified against the PDF. |
| D5 | A new PIMS sidebar item with its own module, not a tab in the stakeholder module. |
| D6 | Yes/No items score ±1 and "Sometimes" 0 (agree scale ±2); rank 1 = highest priority; Q39 has no NPG dimension; the "Other" role is stored as a code only. |

## 3. Item bank

### 3.1 Source

`WP5/Task 5.4 Governance Measures & Targets/Deliverable 5.4/final version/MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf`: Annex 5 "Stakeholder consultation questionnaire" (PDF pages 140–145, printed 139–144) and Annex 7 "Macaronesia survey questions" (PDF pages 149–152) for the priority ranking Q35–Q39 and the cross-reference of item numbers.

### 3.2 `data/wp5_readiness_items.json`

Hand-written, UTF-8, LF (pinned in the app `.gitattributes`). Shape:

```json
{
  "version": "1.0",
  "source": { "doc": "D5.4 Governance Arrangements (final)", "date": "2026-05-29", "doi": "10.48481/rifs.2026.011" },
  "scales": {
    "agree7":  { "codes": ["completely_agree", "agree", "neither", "disagree", "completely_disagree", "dont_know", "prefer_not"],
                 "points": [2, 1, 0, -1, -2, null, null] },
    "yes_no":  { "codes": ["yes", "no"], "points": [1, -1] },
    "yes_no_sometimes": { "codes": ["yes", "sometimes", "no"], "points": [1, 0, -1] },
    "extent5": { "codes": ["very_little", "occasionally", "neutral", "regularly", "very_much"], "points": [-2, -1, 0, 1, 2] },
    "rank5":   { "codes": ["1", "2", "3", "4", "5"], "points": null }
  },
  "roles": ["government", "manager", "researcher", "tourism_operator", "fishers", "civil_society", "industry", "general_public", "other", "prefer_not"],
  "items": [
    { "id": "q6", "kind": "state", "dimension": "values_conflict", "scale": "agree7", "reverse": false,
      "text_en": "I trust the stakeholders engaged in decision-making, management, and conservation.",
      "source_ref": "D5.4 Annex 5 Q6, p. 139", "annex7_ref": "Q9" }
  ]
}
```

Items (ids are the Annex 5 numbers; Q35–Q39 keep Annex 7 numbers):

| id | kind | dimension | scale | reverse |
|---|---|---|---|---|
| q3 (collaborate?) | state | collaboration | yes_no | no |
| q4 (extent) | state | collaboration | extent5 | no |
| q5 (collaboration important) | attitude | collaboration | agree7 | — |
| q6 (trust) | state | values_conflict | agree7 | no |
| q7 (trust important) | attitude | values_conflict | agree7 | — |
| q8 (voice) | attitude | legitimacy_equity | agree7 | — |
| q9 (equal opportunity) | attitude | legitimacy_equity | agree7 | — |
| q10 (some more powerful) | state | legitimacy_equity | agree7 | yes |
| q13 (conflicts exist) | state | values_conflict | yes_no | yes |
| q15 (opportunities to overcome conflicts) | state | values_conflict | yes_no | no |
| q16 (follow the rules) | state | values_conflict | yes_no_sometimes | no |
| q17 (opportunities to ensure compliance) | state | values_conflict | yes_no | no |
| q18 (appropriate stakeholders included) | state | legitimacy_equity | agree7 | no |
| q19 (transparent) | state | knowledge | agree7 | no |
| q35–q39 (priority areas) | priority | values_conflict, values_conflict, legitimacy_equity, cross_sectoral, null (Q39 organisational capacity is not an NPG dimension) | rank5 | — |

Rules: `dimension` ∈ `NPG_DIMENSIONS` (null only for q39); `text_en` is the D5.4 statement (the quoted statement for agree items, the question for yes/no items, the area text for Q35–Q39) verbatim; the role list is Q1's categories ("Other" is stored as the code only; its free text is not collected). Rank direction: 1 = highest priority (Annex 7 says "please rank"; the toolbox fixes 1 as most important and says so in the UI).

### 3.3 Translations

`translations/modules/wp5_readiness.json`: every item text, scale label, role label and UI string in 9 languages. Item texts carry the note "translation by the toolbox; D5.4 wording is English" (one shared key shown under the form).

## 4. Storage

`data$pims$readiness = list(version = "1.0", respondents = <data.frame>, counter = <int>)`; `counter` keeps the highest id ever issued so ids are never reused after a delete. Columns: `RespondentId` (`R001`…, via `next_element_id`/`safe_counter`), `EnteredAt` (date), `Source` (`form`/`import`), `Role` (role code or ""), then one column per item id holding the answer code or "". No names, no contact details, no free text. A normaliser (`normalize_readiness()`) accepts NULL, a list with a data.frame, or the list-of-row-lists that `jsonlite::fromJSON(simplifyVector = FALSE)` produces; it adds missing columns, drops unknown answer codes to "", and keeps unknown item columns (future item banks). Hooked into `normalize_json_project_data()`; `create_empty_project()` gets an empty table. `WP5_READINESS_MIN_APP_VERSION <- "1.31.0"` is stamped whenever a project with at least one respondent is written by the module or loaded through `normalize_json_project_data()` (the WS-9a lesson: stamp on the schema, not on a user action). An older app keeps `data$pims$readiness` untouched (it never reads it), so the stamp is a warning, not a guard against a crash.

## 5. Scoring (pure, `functions/wp5_readiness.R`)

- Item points from the scale (yes/no items score ±1, not ±2: a "yes" states presence, not intensity, so it counts like "agree" — decision D6); `reverse` flips the sign; `dont_know`/`prefer_not`/"" are excluded.
- Per dimension: mean of the points over all scored (`kind == "state"`) item answers of all respondents; returns `score`, `n_respondents` (with ≥ 1 scored answer in the dimension), `n_answers`, `n_items`, and a coverage flag: `none` (no state items — cross_sectoral), `low` (one state item — knowledge), `ok`.
- Attitude items: answer-code counts per item. Priority items: mean rank and counts per area.
- Role breakdown: the same per-dimension summary per role, returned only for roles with ≥ 5 respondents.
- Transparency: the Results tab shows each scored item next to the dimension mean, because single items can dominate (e.g. nearly every respondent answering "yes, conflicts exist" to the reversed q13 lowers values_conflict).

## 6. Module `modules/wp5_readiness_module.R`

Wiring: `functions/ui_sidebar.R` adds `bs4SidebarMenuSubItem(safe_t("ui.sidebar.governance_readiness", ...), tabName = "pims_readiness")` after the Stakeholders sub-item, inside the existing "PIMS Module" block (so it inherits the user-level gating `show_pims`); `translations/ui/sidebar.json` gains `ui.sidebar.governance_readiness`; `app.R` adds the module to its module source list, a `bs4TabItem(tabName = "pims_readiness", wp5_readiness_ui("pims_ready", i18n))` next to the other PIMS tab items, and `wp5_readiness_server("pims_ready", project_data, session_i18n)` next to the other PIMS servers. Server signature `(id, project_data_reactive, i18n, event_bus = NULL)`. Three tabs:

1. **Add respondent** — consent/privacy notice written by the toolbox (participation is optional and anonymous; no name, contact or free text is stored; answers are kept in the project file; the project's own GDPR consent procedure, as used for the D5.4 interviews, applies to how respondents were invited — the notice refers to it but does not reproduce it) with a checkbox "The respondent has agreed" that enables the form; optional role; items grouped by dimension, each with translated text, the D5.4 source reference and radio buttons for its scale (no default selection; any item may be skipped); "Save respondent" appends a row and resets the form.
2. **Import** — "Download template" (xlsx: sheet `answers` with columns `role` + item ids; sheet `items` with the current language's item texts and allowed codes and labels; sheet `roles`); upload xlsx or csv; a value may be the answer code or its label in any of the 9 languages (matched case- and space-insensitively against the translation file), so a template filled in another language imports correctly; role values likewise (a label that maps to different codes in different languages is treated as unreadable); a preview lists rows to add, cells blanked as unreadable and ignored columns; "Add N respondents". Columns other than `role` and known item ids are never read. More than 1000 rows is refused.
3. **Results** — respondents (total, form/import); per dimension a bar on −2…+2 with counts and the label "toolbox indicator, not a WP5 score", coverage notes for cross-sectoral (none) and knowledge (low); distributions of the scored items; attitude items as "views on what should be"; priority ranking as mean rank; role breakdown (≥ 5 respondents per role, else hidden with a note); respondent list (id, role, date, source) with "Delete selected"; "Export xlsx" (anonymous answers + summary).

## 7. Errors

- Item bank missing or corrupt: notice "readiness items unavailable"; the rest of PIMS is unaffected.
- No project: hint.
- Import: unreadable file → `format_user_error` notice, nothing added; unknown values → "" and counted; wrong columns → message listing expected item ids; > 1000 rows → refused.
- No respondents → hint; a dimension with no scorable answers → "no answers" instead of a score.

## 8. Testing

- pytest `scripts/tests/test_wp5_readiness_items.py`: every `text_en` occurs in the D5.4 text of Annex 5 (Q35–Q39: Annex 7) with letters+digits comparison; skips without the WP5 folder.
- R: item-bank schema; scoring (points, reverse, exclusions, state-only indicator, cross-sectoral never scored, counts, coverage flags, role breakdown threshold); import (codes and labels, a template from another language, bad values, ignored columns, row limit, template round trip); normaliser and JSON round trip; legacy project → empty table; stamp only when respondents exist; module `testServer` (consent gate, R001/R002, delete, missing item bank, results with zero and with several respondents).
- i18n audit `missing=0 hardcoded=0`; full suite in six chunks; pre-deploy check.

## 9. Release

1.31.0 (`VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`). Notes: the indicator is a toolbox construct, not a WP5 score; cross-sectoral coordination has no D5.4 item; free-text answers are not collected.
