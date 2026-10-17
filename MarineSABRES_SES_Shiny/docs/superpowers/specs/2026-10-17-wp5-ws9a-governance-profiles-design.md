# WP5 WS-9a: Governance profiles, actor seeding, barrier/enabler cards and policy targets (D5.4) — design

Date: 2026-10-17. Status: approved in brainstorming (sections 1–4), awaiting spec review.
Parent spec: `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-9.
Source audit: `docs/wp5-source-audit/2026-10-11/D_D5.4_governance.md`.
Release: 1.30.0. Execution: subagent-driven (as WS-8).

## 1. Scope

WS-9 is split. **9a (this spec)** ships features 1, 2 and 4 of the parent spec plus the country-database additions:

1. Per-DA governance profiles as a curated data file.
2. "Load DA actor list" in PIMS stakeholders, with a new D5.4 roles column.
3. Barrier/enabler cards and recommendation cards (with "Add to register") in the Response module.
4. An optional `Policy_Target` field on indicators.
5. Greenland, the Faroe Islands and seven regional bodies in `country_governance_db.json`.

**Deferred:** 9b, the governance-readiness questionnaire (own spec); storing the stakeholder `Type` as a code instead of a translated label (existing behaviour, separate fix); power/interest grids for Arctic, Azores and Canaries (partner question Q6); the EBM-principles 26-vs-15 count (not used by 9a).

## 2. Decisions taken in brainstorming

| # | Decision |
|---|---|
| D1 | Split WS-9 into 9a (this spec) and 9b (readiness questionnaire). |
| D2 | D5.4 roles go into a new stakeholder column `NERoles` (codes from `STAKEHOLDER_TYPES`, `;`-joined); the existing `Type` list is unchanged. |
| D3 | Recommendations are cards with an "Add to register" button that creates a register measure. |
| D4 | Data is a hand-curated JSON with page/table references; a pytest check verifies quoted text against the D5.4 PDF. |
| D5 | Card, actor, legal-instrument and recommendation text stays English source text with a "Source text (English)" badge; all labels are translated (same rule as WS-8). |

## 3. Data

### 3.1 Sources

- Primary: `WP5/Task 5.4 Governance Measures & Targets/Deliverable 5.4/final version/MarineSABRES_D5.4 Governance Arrangements_29.05.2026.pdf` (D5.4 final, Boteler et al. 2026, DOI 10.48481/rifs.2026.011). Cards come from the summary Tables 5, 6 and 7 only ("What is working well" / "Areas of improvement"; printed pages 23–26, 28–30 and 33–34; PDF pages 24–27, 29–31, 34–35). The detailed per-dimension annex tables 12–22 are not used, to avoid near-duplicate cards. Actors, legal instruments, gaps and recommendations come from §4.1–4.3 and Annexes 1–3.
- Power/interest grids and role assignments for Tuscany and Madeira: `WP5/Task 5.4 .../Case study work/Tuscany archipelago/MarineSABRES_Characterisation_TuscanArchipelago.docx` and `.../Macaronesia/MarineSABRES_Characterisation_Macaronesia.docx`, cross-checked with D5.4 where it repeats them.
- `WP5/` is untracked in git and absent on CI; only the curated JSON is committed.

### 3.2 `data/wp5_governance_profiles.json`

Hand-curated, UTF-8, LF line endings (add the file to the app `.gitattributes` `eol=lf` list, as WS-8). Shape:

```json
{
  "version": "1.0",
  "source": { "doc": "D5.4 Governance Arrangements (final)", "date": "2026-05-29", "doi": "10.48481/rifs.2026.011" },
  "dimensions": ["knowledge", "collaboration", "values_conflicts", "legitimacy", "cross_sectoral"],
  "das": {
    "tuscan_archipelago": {
      "da_site": "Tuscan Archipelago",
      "sub_areas": [],
      "governance_levels": ["local", "regional", "national", "eu", "regional_sea"],
      "grid_available": true,
      "grid_note": null,
      "actors": [ { "id": "tus_a01", "name": "...", "level": "regional", "sub_area": null,
                    "ne_roles": ["Regulators"], "pims_type": "government_regulators",
                    "power": "HIGH", "interest": "LOW", "source_ref": "..." } ],
      "legal_instruments": [ { "name": "...", "level": "national", "source_ref": "..." } ],
      "cards": [ { "id": "tus_c01", "dimension": "knowledge", "polarity": "enabler",
                   "text": "...", "sub_area": null, "source_ref": "D5.4 Table 7, p. 33" } ],
      "gaps": [ { "text": "...", "source_ref": "..." } ],
      "recommendations": [ { "id": "tus_r01", "title": "...", "text": "...", "ebm_code": "1.4",
                             "rm_type": "institutional", "governance_level": "regional",
                             "target_roles": ["Regulators"], "implementing_actor_ids": ["tus_a01"],
                             "source_ref": "..." } ]
    },
    "arctic_nea": { "da_site": "Arctic Northeast Atlantic", "sub_areas": ["greenland", "iceland", "faroe_islands"], "grid_available": false, "grid_note": "no_published_grid", "...": "..." },
    "macaronesia": { "da_site": "Macaronesia", "sub_areas": ["azores", "madeira", "canaries"], "grid_available": true, "grid_note": "grid_madeira_only", "...": "..." }
  }
}
```

Field rules:
- `da_site` equals an entry of `DA_SITES` exactly.
- `dimensions`: the five NPG dimensions of D5.4 Tables 5–7 — incorporation of knowledge; collaborative structures; values, conflicts and decision making; inclusivity and legitimacy; cross-sectoral coordination (Tuscany: "and transboundary cooperation").
- `ne_roles` ⊆ `STAKEHOLDER_TYPES` (Inputters, Extractors, Regulators, Affectees, Beneficiaries, Influencers); an actor may have several.
- `pims_type` is one of the existing PIMS Type option keys: `resource_users`, `industrybusiness`, `governmentregulators`, `ngocivil_society`, `scientificacademic`, `local_communities`, `indigenous_groups`, `other` (the suffixes of the `modules.pims.stakeholder.*` keys the form uses; `other` maps to `modules.isa.ai_assistant.other`).
- `power`, `interest` ∈ `HIGH`, `LOW`, or null. Non-null only where a published grid places the actor (Tuscany; Madeira actors in Macaronesia). Macaronesia `grid_available` is true but only Madeira actors carry values; Azores and Canaries actors carry null and the note `grid_madeira_only`.
- `polarity`: `enabler` = "What is working well"; `barrier` = "Areas of improvement".
- `card.text`: the bullet text as printed, without the leading bullet glyph; a bold lead-in ("Transparency at regional level:") stays part of the text.
- `card.sub_area`: set when the table cell names a sub-area (e.g. "Iceland:"); otherwise null.
- `ebm_code` ∈ the WS-1 instrument codes (1.x, 2.x, 4.x levels of `EBM_POLICY_INSTRUMENTS`). `rm_type` ∈ `names(RM_TYPE_CODES)`. `governance_level` ∈ `GOVERNANCE_LEVELS`.
- `implementing_actor_ids` ⊆ the same DA's actor ids (may be empty).
- `source_ref`: human-readable, citing the printed page, e.g. `"D5.4 Table 5, p. 23"`, `"D5.4 Annex 1, p. 60"`, `"Characterisation Tuscan Archipelago, stakeholder grid"`.
- Ids: `<da>_<a|c|r>NN`, unique across the file. `<da>` prefixes: `tus`, `arc`, `mac`.

Recommendations: 4 Arctic, 6 Macaronesia, 4 Tuscany (audit §2.2–2.4).

### 3.3 Country database additions (`data/country_governance_db.json`)

- Countries `GL` (Greenland) and `FO` (Faroe Islands), same record shape as existing countries (`code`, `name_en`, `eu_member: false`, `income_level`, `governance_group: "non_eu_european"`, `regional_conventions`). Add both to `countries_by_sea$arctic` (and `atlantic` where Iceland is listed).
- Regional bodies in `regional_conventions`: `neafc`, `ices`, `gfcm`, `accobams`, `pelagos`, `medpan`, `nordic_council`, each with `name`, `full_name`, `member_codes`, `responses` (2–4 suggested Response element texts, as existing entries). Update each member country's `regional_conventions` list. Bump `last_updated`.

### 3.4 Verification

- `scripts/tests/test_wp5_governance_profiles.py` (pytest; skips when the D5.4 PDF is absent; source path from env `WP5_D54_SRC` or the main-checkout default): extracts the PDF text with PyMuPDF (`fitz`, in the `shiny` env), normalises whitespace and hyphenation at line ends, and asserts every `card.text`, every D5.4-sourced actor `name` and every recommendation `title` occurs in it. Actors sourced from the characterisation documents are checked against those `.docx` texts (python-docx).
- R tests (`tests/testthat/test-wp5-governance-profiles.R`): schema — keys present, `da_site` ∈ `DA_SITES`, dimensions ⊆ the five ids, `ne_roles` ⊆ `STAKEHOLDER_TYPES`, `pims_type`, `rm_type`, `governance_level`, `ebm_code` valid, ids unique, `implementing_actor_ids` resolve, recommendation counts 4/6/4, every DA has ≥ 1 card per dimension; country DB has GL and FO, the seven bodies, and `get_countries_for_sea("arctic")` includes GL and FO.

## 4. Stakeholder roles and seeding (PIMS)

### 4.1 Schema

- New `functions/stakeholder_schema.R`: `PIMS_STAKEHOLDER_COLUMNS` (the existing 12 columns plus `NERoles`, `SourceId`) and `normalize_stakeholders(df)` — NULL/empty → zero-row frame with all columns; missing columns added as `""`; column order fixed; `NERoles` normalised to known `STAKEHOLDER_TYPES` codes in canonical order (unknown codes dropped, `debug_log()`). Sourced from `global.R`.
- `pims_stakeholder_module.R`: the add handler builds the new row through `normalize_stakeholders()` and normalises the existing frame before `rbind`; project load normalises `pims$stakeholders`. The form gains a `sh_ne_roles` multi-select (choices = `STAKEHOLDER_TYPES`, labels translated); the table shows `NERoles` as translated labels and hides `SourceId`.

### 4.2 "Load DA actor list"

- Button in the stakeholder register tab. Disabled, with a hint, when the project has no `metadata$da_site` or no matching profile, or when the profiles file is unavailable.
- Click opens a modal: the DA name, a sub-area multi-select (Arctic, Macaronesia; all selected), and the grid note where applicable. Confirm seeds.
- Each actor → one row: `Name` = actor name; `Type` = the translated label of `pims_type` (written exactly as the form writes it); `NERoles`; `Power`/`Interest` from the grid or `""`; `Role` = translated governance-level label; `SourceId` = `d54:<actor id>`; `DateAdded`; `ID` from the existing counter. Other columns `""`.
- Idempotent: skip an actor when its `SourceId` already exists, or when an existing row's `Name` matches after lower-casing and collapsing whitespace.
- Notification: "Added N actors; skipped M already present", plus the grid note for areas without a grid.
- Pure helper `seed_da_actors(stakeholders, profile, sub_areas, i18n, next_id)` in `functions/wp5_governance.R` returns the new frame and counts, so it is unit-testable without Shiny.

## 5. Governance context in the Response module

- New sub-module `modules/wp5_governance_context_module.R` (`wp5_governance_context_ui(id, i18n)`, `wp5_governance_context_server(id, project_data_reactive, i18n, event_bus = NULL)`), mounted as a new tab "Governance context (D5.4)" in `response_measures_ui()`'s `tabsetPanel(id = ns("response_tabs"))`, after the WP5 mechanisms tab. Added to `OPTIONAL_MODULES` before `modules/response_module.R`; mount guarded with `exists()`.
- Filters: DA (default = project `da_site`; the user may switch), NPG dimension (all / one), polarity (both / enablers / barriers), sub-area (where the DA has them). No project DA → hint plus the DA selector.
- Header note: findings of D5.4's NPG assessment; qualitative, not a score.
- Barrier/enabler cards grouped by dimension: polarity badge, verbatim text, source badge, sub-area, `source_ref`.
- Recommendation cards: title, text, EBM code label (`wp5_vocab_label("instrument", code, i18n)`), governance-level label, `source_ref`, and "Add to register":
  - Builds the row with `normalize_response_measures()`: `Name` = title; `Description` = text + " (D5.4 recommendation, <source_ref>)"; `Kind` = `instrument`; `EbmCode`; `GovernanceLevel`; `Type` = `rm_type`; `Status` = `proposed`; `Target` = `""`; `ImplementingStakeholders` = IDs of project stakeholders whose `SourceId` is `d54:<id>` for an id in `implementing_actor_ids`; `DateAdded`; new `ID` from the register counter.
  - Disabled as "Already in register" when a register measure has the same `Name`.
  - Writes through the project reactive the same way the register does, so the register tab updates.
- Pure helpers in `functions/wp5_governance.R`: `load_wp5_governance_profiles(path = NULL, force_reload = FALSE)`, `wp5_gov_profile_for_site(profiles, da_site)`, `wp5_gov_filter_cards(profile, dimension, polarity, sub_area)`, `wp5_gov_recommendation_measure(rec, stakeholders, next_id)`.

## 6. `Policy_Target` on indicators

- Append `"Policy_Target"` to `ISA_INDICATOR_COLUMNS`; it flows through the existing indicator-column save/load and normalisation paths.
- Standard Entry element form: a selectize next to the indicator fields, `options = list(create = TRUE)`; picklist codes `kmgbf_30x30`, `eu_nrr`, `msfd_ges_d1`, `msfd_ges_d6`, `national_mpa_pct` (`WP5_POLICY_TARGETS` in `constants.R`), labels translated; free text stored as typed. A help line: D5.4 sets no targets; these are external policy targets.

## 7. Compatibility

- `WP5_GOVERNANCE_MIN_APP_VERSION <- "1.30.0"` in `constants.R`. On save, `stamp_min_app_version()` when any stakeholder has non-empty `NERoles` or `SourceId`, or any element has non-empty `Policy_Target`. Older apps then warn before loading instead of dropping columns or failing on the next stakeholder add.
- Legacy projects load with the new columns as `""`.

## 8. i18n

About 60–70 keys in 9 languages: tab and panel titles, filter labels, the five dimensions, polarity badges, the six role labels (`STAKEHOLDER_TYPES`), sub-areas, grid notes, notifications, modal text, "Add to register" / "Already in register", policy-target labels and help. New file `translations/modules/wp5_governance.json`; PIMS and indicator keys in their existing files. Dynamic keys get `# i18n-ref:` sentinels. The audit must report `missing=0 hardcoded=0`.

## 9. Errors

- Missing or corrupt profiles JSON: loader returns NULL and `debug_log()`s the path; the governance tab shows "governance reference data unavailable"; the seeding button is disabled with the same notice; all other Response and PIMS features work.
- Project DA without a matching profile: hint, no error.
- Malformed `NERoles` in a loaded project: unknown codes dropped on normalise.

## 10. Testing

- pytest: §3.4.
- R: profile schema and country DB (§3.4); `normalize_stakeholders()` on NULL, legacy and malformed frames; `seed_da_actors()` — twice gives no duplicates, a manual row with the same name is skipped, sub-area filter, grid values for Tuscany/Madeira and none for Arctic, roles valid; stakeholder module `testServer()` — the button is disabled without a DA, seeding writes rows, a save/load JSON round trip keeps `NERoles` and `SourceId`; governance module `testServer()` — filters, no-DA hint, add-to-register row (codes, source note, linked stakeholders after seeding, empty without), second add blocked, missing-data notice (loader stubbed); `Policy_Target` round trip and legacy load; stamp set only when the new fields are used.
- Module tests re-bind the real functions from `.GlobalEnv` (helper-stubs shadowing).
- Release check: six alphabetical testthat chunks, pytest, i18n audit, `deployment/pre-deploy-check.R`.

## 11. Release

1.30.0: `VERSION`, `DESCRIPTION`, `VERSION_INFO.json`, `CHANGELOG.md`. Notes: power/interest grids only where D5.4 publishes them (Tuscany, Madeira); readiness questionnaire follows in 9b; findings are qualitative.
