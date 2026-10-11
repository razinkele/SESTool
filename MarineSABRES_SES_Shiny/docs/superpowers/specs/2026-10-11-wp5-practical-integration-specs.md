# WP5 practical integration: specifications

**Date:** 2026-10-11
**Status:** Draft for partner review
**Baseline release:** 1.21.1
**Supersedes:** Phases 2–4 of `2026-05-06-wp5-integration-roadmap-design.md`. This spec also amends that roadmap's Phase 1, because the shipped KB needs rebuilding. The May document is kept unchanged as a historical record.
**Inputs:**
- Gap analysis: `WP5/WP5_Integration_Gap_Analysis_2026-10-11.md`
- Line-cited source reports: `docs/wp5-source-audit/2026-10-11/`:
  - `A_` = D5.2 final v5
  - `B_` = D5.1
  - `C_` = D5.3
  - `D_` = D5.4

Citations such as "A§6.4" refer to sections of those reports, and each report cites the original deliverable line numbers.

---

## 1. Principles (apply to every workstream)

**P1. Provenance is data and is visible.** Every reference record carries a `provenance` field:

| Value | Meaning |
|---|---|
| `wp5_source` | Verbatim or close paraphrase of a WP5 deliverable. Must include `source_ref` (document, table/section, version). |
| `wp5_derived` | Mechanically derived from WP5 data, e.g. the code remap or midpoints. Must include `derivation`. |
| `toolbox_extension` | A method or content the toolbox adds, e.g. NPV, a readiness score, scoring advice, or a row→EBM-code mapping. |
| `provisional` | Awaiting a partner definition, e.g. the undefined D5.3 matrix rows. |

The UI shows a small badge for any value that is not `wp5_source` (`ui_components.R` gains `provenance_badge(provenance, i18n)`).

This rule exists because the shipped KB showed builder-authored text to users as WP5 findings (A§6.5). Four separate source reports also flagged toolbox constructs that partners could mistake for WP5 method.

**P2. Store codes in data and translate only on display.** Vocabulary values in project data are stable codes such as `EE`, `1.1`, `output_control` or `S3`. Labels resolve through `i18n$t()` at render time. `response_module.R` currently stores translated `rm_type` labels as values (C§5.1), so the label changes with the user's language. WS-2 fixes this and migrates existing data.

**P3. Store published values; do not recompute them.** Where WP5 tables are internally inconsistent (the Arctic revenue tables, A§3.1), store the published numbers and flag the inconsistency.

**P4. Use ordinal values where WP5 is ordinal.** Do not invent numeric scales. If a calculation needs numbers (colour ramps, aggregation), map ordinal to numeric in one documented function marked `toolbox_extension`.

**P5. Reference data is not project data.** WP5 KBs live in `data/` as versioned JSON, loaded by cached loaders on the `wp5_kb_loader.R` pattern. When a user adopts a reference value into a project, it is copied as a snapshot that records `ref_id` and `ref_version` (drift detection, as specified in roadmap §7.6 and kept here).

**P6. Use project conventions.**
- Module signature: `(id, project_data_reactive, i18n, event_bus = NULL)`.
- UI starts with the defensive `usei18n` wrapper.
- Every new `functions/*.R` file is `source()`d in a form recognised by `test-functions-sourced-in-app.R`.
- All 9 languages are provided for UI chrome. Long-form KB prose stays English (offshore-wind precedent) and carries a visible "English only" note.

**P7. Testing conventions** (see `CLAUDE.md`):
- Use `source_for_test()` for module and server files.
- Re-bind the real server from `.GlobalEnv` before `testServer()`, because `helper-stubs.R` shadows it.
- Never end a test in `expect_true(TRUE)`.
- Pure functions get unit tests.
- Every new project-data block gets a save/load round-trip in `test-json-project-loading.R`.

---

## 2. Workstream map and dependencies

| ID | Workstream | Tier | Depends on | Partner gate |
|---|---|---|---|---|
| WS-0 | Prerequisite fixes (scenario storage split, `min_app_version` bump helper) | Foundation | — | none |
| WS-1 | WP5 shared vocabulary (`constants.R` + i18n) | Foundation | — | criteria/rubric labels |
| WS-2 | KB v2 (mechanisms rebuilt from final D5.2, with provenance) | **Corrective** | WS-1 | **mechanism lists + guidance text** |
| WS-3 | R/M classification, governance annotations, typing lint | Core | WS-1 | instrument/measure vocabulary |
| WS-4 | Indicator registry | Core | WS-1 | fiche content, code remap |
| WS-5 | Valuation calculator | Core | WS-2 (valuation block) | disclaimer text |
| WS-6 | Impact-assessment module | Core | WS-1, WS-4; soft on WS-2 and WS-3 | rubric, reference datasets |
| WS-7 | Intervention designer (D5.3 graph-edit modes) | Extension | WS-0, WS-1, WS-3 | operations table |
| WS-8 | Scenario × worldview reference library | Extension | WS-0, WS-1 | — |
| WS-9 | Governance profiles and readiness check | Extension | WS-3 | readiness-score labelling |
| WS-10 | Workshop elicitation (ranking poll + 11-tenet Likert) | Extension | WS-1, WS-3 | instrument wording |

Recommended order: **WS-0 → WS-1 → WS-2 → WS-3 → WS-4 → WS-5 → WS-6**, then WS-7 to WS-10 as partner priorities dictate.

WS-1 is small and unblocks four strands. WS-2 must ship before any feature that surfaces mechanisms more prominently than the current reference pane.

Release mapping: one minor version per workstream group, starting at 1.22.0. Example grouping:
- 1.22 = WS-0/1/2
- 1.23 = WS-3/4
- 1.24 = WS-5/6
- later = WS-7 onwards

---

## WS-0. Prerequisite fixes

**Problem.** Scenarios are written to `data$data$scenarios` (`modules/scenario_builder_module.R:1164`, read at `:117`). The schema declares `data$analysis$scenarios` (`functions/data_structure.R:382`), and nothing uses it. WS-7 and WS-8 both add scenario-adjacent data, so the location must be settled first.

**Change.**
1. Make `data$analysis$scenarios` canonical.
2. In `normalize_json_project_data()` / `normalize_and_reconcile_project()`, move a legacy `data$scenarios` into `data$analysis$scenarios`, using a one-time merge by `id`.
3. Update the builder's read and write paths.
4. Add a helper `stamp_min_app_version(project, version)` that only ever raises the stamped version. Use it from WS-4 and WS-6 instead of ad-hoc writes.

**Tests:**
- A legacy project with `data$scenarios` loads into `analysis$scenarios`.
- A save/load round-trip preserves scenarios.
- The stamp helper never lowers a version.

---

## WS-1. WP5 shared vocabulary

**Source:**
- A§2.2–2.3: criteria, aliases, rubric, time horizons.
- A§8.1: D5.2 intervention typology.
- C§2: EBM instruments 1.1–4.3 and measures.
- C§1.1–1.3: graph-operation legend and matrix.
- D§1.2: NPG dimensions.
- C§3.3 / D§3.4: 11 tenets.

**Files.** Add to `constants.R`:

```r
WP5_CRITERIA <- data.frame(
  code = c("EE","EC","EQ","PI","FF"),
  aliases = I(list(character(), character(), character(), c("PO"), c("FI"))))
  # labels: i18n key modules.wp5_vocabulary.criteria.<code> (wp5_vocab_key())
WP5_CRITERION_SUBDIMENSIONS <- list(
  EQ = c("distributional","procedural","recognitional"),
  PI = c("credibility","manageability","contestation_risk"))
WP5_RUBRIC <- list(                       # D5.2 Macaronesia Phase 3, A§2.3
  direction  = c("increase","decrease","no_change","uncertain"),
  magnitude  = c("incremental","moderate","substantial"),
  timing     = c("short","medium","long"),            # 1–3 / 4–7 / 8–15 years
  confidence = c("high","medium","low"),
  evidence   = c("dataset","literature","stakeholder","da_judgement","triangulation"),
  uncertainty_driver = c("data_gap","contested_assumption","weak_causal_link","implementation_dependency"),
  indicator_role   = c("primary","supporting"),
  pathway_segment  = c("pressure","state","benefit","governance_capacity"))
WP5_TIME_HORIZON_YEARS <- list(short = c(1,3), medium = c(4,7), long = c(8,15))
EBM_POLICY_INSTRUMENTS   # data.frame: code ("1","1.1",…,"4.3"; 3.5 absent), category, i18n_key, example_key
EBM_MANAGEMENT_MEASURES  # data.frame: code (spatial.year_round, spatial.seasonal, input.capacity, input.effort,
                         #   input.technical, output, remediation, restoration.species, restoration.habitat,
                         #   nbs.enhance, nbs.multi_use, nbs.replace), dapsiwrm_target ("A|P|C","A","P","C",…)
EBM_TENETS               # 11 codes: ecol_effective, tech_feasible, econ_efficient (measure-level);
                         #   econ_viable, socially_desirable, ethically_defensible, culturally_inclusive,
                         #   legally_permissible, admin_achievable, communicable, politically_expedient
NPG_DIMENSIONS <- c("knowledge","collaboration","values_conflict","legitimacy_equity","cross_sectoral")
GRAPH_EDIT_OPS <- c("reweight_edge","new_edge","new_node")   # D5.3 (+/-), (---), (o)
```

The intervention→operation table is data, not a constant: `data/wp5_intervention_ops.json`. Each row has `id`, `group` (behavioural / management / economic / governance), `ops_xlsx`, `ops_ebm`, `ebm_code` (`provisional` mapping per C§2.3), `definition_key` (null where undefined), `provenance`, `source` (`master` / `T5.4`) and an optional `context` (DA) for per-DA overrides.

Until WP5 resolves the xlsx-vs-EBM conflicts (C§1.4), the allowed operations are the **union** of the two sources, with each operation tagged by source.

**i18n.** Labels and one-line definitions for the vocabulary (`translations/modules/wp5_vocabulary.json`): about 120 keys × 9 languages. Tenet minimal/full definitions are UI tooltips, so they are translated. Fix the copy error in the "administratively achievable" text (D§3.4) before translating.

**Tests (`test-wp5-vocabulary.R`):**
- Codes are unique.
- Every `i18n_key` exists in all 9 languages.
- Aliases resolve: `wp5_criterion_code("PO") == "PI"`.
- Every `ebm_code` in `wp5_intervention_ops.json` exists in `EBM_POLICY_INSTRUMENTS` or is marked `provisional`.

---

## WS-2. KB v2: financial mechanisms rebuilt from final D5.2 (corrective)

**Source.** A§6: final Tables 9 (Arctic, 8), 20 (Tuscan, 7) and 22 (Macaronesia, 16). Cost bands come from Draftv5. Untraceable content is listed in A§6.5.

**Builder.** Rewrite `scripts/build_wp5_mechanisms_kb.py` so that its inputs are the final D5.2 text and Draftv5 tables, pinned by file hash in `source_documents`. Keep the header-banner pattern.

**Schema v2.** Changes from v1:
- Add: `provenance` and `source_ref` per mechanism and per guidance field.
- Add: `cost_band` (`€`..`€€€€`, Macaronesia only, with the band legend in a top-level `cost_bands` block).
- Add: `scenario_applicability`, e.g. `{ "arctic_full": "most_effective", … }`, taken from the Table 9/20 applicability columns as published text plus a coded level where the text is unambiguous.
- Add: `success_statement` (Macaronesia "what success looks like").
- `success_metrics`: canonical WS-4 indicator codes only.
- Remove: invented codes (`POS_density`), Tuscan S-labels and `§x.x` placeholders.
- `use_in_impact_assessment`: kept only as `toolbox_guidance { text, provenance: "toolbox_extension" }`, and only if partners opt in (Q1).
- Add: a top-level `scenarios` block per DA with code, final name and short label:
  - Arctic: `no_agreement`, `partial_agreement` (status quo), `full_agreement`
  - Macaronesia: S1–S4, final names per A§3.3
  - Tuscan: `[]`
- Keep `valuation_unit_values`. Each `central` is labelled `wp5_derived` (midpoint).

**Content fixes:**
- Replace `mac_01` with toolkit #1 (corridor coordination & platform resourcing) and `mac_02` with #8 (local stewardship & benefit-sharing).
- Add `arc_07` (research & innovation funds), `arc_08` (PPP/CSR funding), the Tuscan credits mechanism and the Tuscan certification & branding mechanism.
- Map the Tuscan user fees to a single entry with sub-variants (moorings, concessions).
- Correct the `arc_01` and `arc_03` payer lists.
- Rename `arc_03` to "National financing of monitoring, control and surveillance (MCS)".

**Loader.** `functions/wp5_kb_loader.R`:
- Accept schema `version` 1.x or 2.x; warn on 1.x.
- Add `get_scenarios_for_da(da)`, `get_cost_band_legend()` and `mechanism_provenance(id, field)`.
- Keep existing function signatures.

**UI.** Response module pane (`modules/response_module.R:904–950`):
- Render the cost band, applicability and provenance badges.
- Show a toolbox-guidance block only when present, with its badge.

**Audit.** `scripts/kb_audit/audit_wp5_mechanisms.py` fails on:
- any `§x.x`;
- any `success_metrics` code missing from the WS-4 registry;
- any scenario label not in that DA's `scenarios` block;
- any field without `provenance`.

**Tests (`test-wp5-kb-loader.R`, extended):**
- Counts are 8/7/16.
- No placeholder references.
- Every mechanism has `source_ref`.
- The Tuscan `scenarios` list is empty.
- Every `cost_band` is in the legend.
- A v1 file still loads, with a warning.

**Partner gate.** Check all 31 mechanisms against Tables 9, 20 and 22 (the May roadmap checked a 5-mechanism sample). Q1 must be answered before any guidance text ships.

---

## WS-3. Response/Measure classification, governance annotations, typing lint

**Source:**
- C§2, C§5.3–5.4: vocabulary, management strategy = instrument + measure, typing lint.
- D§3.1, D§5 rows 3, 4, 9: governance fields, tenets, power basis.
- A§8.1: D5.2 typology, consistent with the EBM categories.

**Data (Response module frame `data$data$response_measures$measures`).** Add optional columns, defaulting to `NA`:

| Column | Type | Notes |
|---|---|---|
| `rm_kind` | `instrument` / `measure` | |
| `ebm_code` | code from `EBM_POLICY_INSTRUMENTS` or `EBM_MANAGEMENT_MEASURES` | |
| `paired_with` | ID | Builds a management strategy (instrument + measure pair). |
| `governance_level` | `local`, `island`, `regional`, `national`, `eu`, `regional_sea`, `international` | |
| `competent_authority` | text | |
| `legal_basis` | text | |
| `implementing_stakeholder_ids` | list | Links to `pims$stakeholders$ID` and replaces free-text `Stakeholders`. Keep the old column for display of legacy rows. |
| `tenet_scores` | named list; 11 tenets × {`minimal`, `intermediate` (ecological only), `full`, NA} | |
| `pestle_tag` | P/E/S/T/L/E multi-select | For WS-8 linkage. |

**Migration.** `rm_type` and `rm_target` both use unnamed `selectInput` choices of `i18n$t(...)` strings (`response_module.R:40–46`), so the saved `Type` and `Target` values are whatever language the user had active. Fix both inputs to named choices (code values, label names). Then map the existing `Type` and `Target` values to codes with a reverse-translation table built from all 9 language files, stored in `rm_type_code` and `rm_target_code`. Rows that do not match keep their raw text and get `rm_type_code = NA` (P2). Add a test with one label per language.

**UI (`modules/response_module.R`):**
- A grouped selectize for EBM code (instrument categories / measure categories) that filters by `rm_kind`.
- A governance-fields panel.
- An 11-tenet appraisal grid with minimal/full tooltips.
- A "pair with" selector.
- The DAPSIWRM target for a measure is pre-suggested from `dapsiwrm_target` but stays editable.

**Typing lint** (`functions/wp5_typing_lint.R`, pure; surfaced in the CLD validation panel and ISA review):
- **L1.** A D, A or ES element whose label matches the instrument/measure synonym list (quota, licence, MPA, OECM, label, certification, mooring, subsidy, tax, ban, closure, restoration, …; synonyms per language held in the vocabulary JSON) triggers "Consider reclassifying as Response/Measure". Grounded in all three DA models (C§5.4).
- **L2.** An R/M element with no incoming edge from a C, ES, GB or HW node triggers "This intervention cannot respond to its management target" (D5.3: no-feedback interventions).

**Tests:**
- Lint unit tests covering each DA's real mistyping example ("Agreements on quotas" as an Activity; "MPA" as an ES).
- Migration round-trip.
- `testServer` test: selecting a measure code suggests its target.
- Stakeholder link survives save/load.

---

## WS-4. Indicator registry

**Sources:**
- A§5: canonical codes, fiche coverage, Posidonia Tables 17–18, Annex 1 typed tables.
- B§4.4: MS5.1 per-DA typed tables.
- The roadmap §7 snapshot and drift design is retained.

**Data: `data/wp5_indicators.json`**
- **Macaronesia, 11 entries.** C_01, F_01, F_02, F_03, M_01, T_01 and T_03 are full entries from the Annex 8 fiches. C_02, M_02, T_02 and T_04 are `stub: true` entries with name and criterion role only (Q3).
- Each entry has `annex_code` for the stale fiche code (F_02→F_01, F_03→F_02, F_04→F_03, M_03→M_02).
- `T_03` records both meanings: shortlist "wildlife-watch participation" and fiche "number of marine tourism companies". The fiche meaning is canonical, pending Q3.
- **Posidonia (Tuscan).** About 30 indicators from Table 17, grouped by ecosystem service. Use generated codes such as `TUS_POS_SHOOT_DENSITY` with `provenance: wp5_derived`. Table 18 reference ranges go in `reference_range { low, high, unit }`.
- **DAPSIWRM-typed indicators.** From D5.2 Annex 1 (Tuscan Table 6, Macaronesia Table 7) and MS5.1 tables, with `dapsiwrm_type` and `data_source`. Entries marked "data gap" in the source keep `data_gap: true`.
- **Arctic.** No formal set exists (A§5.5). Provide five descriptive entries: landings, price, TAC vs ICES advice, SSB vs reference points, MSC status. Mark them `wp5_derived`.

**Entry fields:**
- `code`, `annex_code`, `name_key`, `da`, `dapsiwrm_type`
- `pathway_segment` (WS-1)
- `criterion_roles { EE: primary|supporting|null … }`
- `unit`, `scale_type` (`numeric` | `ordinal_profile` for C_01 0/+/++/+++)
- `baseline [{ area, period, value, unit }]` (e.g. F_01 tuna share 2022–24: Madeira 37.77%, Azores 45.48%, Canaries 51.24%)
- `scenario_projection { S1..S4: { direction, magnitude_text, confidence } }`, where published
- `early_warning [{ lever, metric, trigger }]`, from the fiche adaptive-management tables
- `data_sources`, `provenance`, `source_ref`

**Loader and lookups (`functions/indicator_registry.R`):** `get_indicator()`, `list_indicators(da=, dapsiwrm_type=, segment=)`, `search_indicators()`.

**Picker.** The `indicator` / `indicator_unit` / `data_source` columns exist in every element frame (`data_structure.R:461–463`). However, **no form renders them today**: `isa_form_builders.R` has no indicator inputs, and `indicator_unit` is unused in every module. WS-4 therefore first adds the three fields to the per-element form in `functions/isa_form_builders.R`, then places the registry picker beside them:
- Selecting an entry copies the values (snapshot) and sets `registry_id` and `registry_version` (new optional columns).
- Drift badge and re-snapshot behaviour follow roadmap §7.6.

**Tests:**
- Every code is unique.
- Every `annex_code` remaps correctly.
- Stubs are flagged.
- Each `dapsiwrm_type` is a valid DAPSIWRM category.
- Snapshot round-trip.
- Drift badge appears for an older `registry_version`.

**Partner gate.** Macaronesia partner verifies the 7 fiche extracts and the code remap. Tuscan partner verifies the Table 17/18 transcription.

---

## WS-5. Valuation calculator

**Source.** A§4: Table 19 values match the plan; the 20-year figure is undiscounted; D5.2 has no NPV. Roadmap §6 pure functions are kept.

**Module.** `modules/valuation_calculator_module.R`, under the Response menu (next to `response_measures`), plus `functions/valuation_calculations.R`.

**Behaviour:**
- **Inputs:**
  - area (ha);
  - services (checkboxes, default all 5);
  - horizon (years, default 20);
  - optional restoration area and cost bound;
  - optional discount rate.
- **Primary output** (`wp5_source`): annual value low–high per service and total, and the cumulative **undiscounted** value over the horizon. This reproduces D5.2's €88,800–€500,000+ per ha at 20 years.
- **Secondary output** (`toolbox_extension` badge):
  - "Central" midpoint.
  - NPV at 0/3/5/7%, as a table, never a single rate.
  - Break-even horizon against the restoration cost.
  - Survival-adjusted restoration cost: cost ÷ survival rate (38–60%).
- **Export:** an xlsx sheet with inputs, outputs and the provenance column.

**Tests:**
- Reproduces D5.2's 20-year undiscounted bounds exactly (area 1 ha).
- Roadmap §6.4 edge cases.
- Band ordering invariant.
- `testServer` test: changing the area updates the total.

**Partner gate.** Tuscan lead signs off the disclaimer: "Benefit-transfer estimate; not a site valuation".

---

## WS-6. Impact-assessment module

**Source:**
- A§2: 7 steps, criteria, ordinal rubric, sub-dimensions.
- A§3: reference datasets. Arctic Tables 2–8 and 10–12; Macaronesia Table 21, Table 23, and the C_01 and F_02 scenario tables. Tuscan has none.
- The roadmap §8 structure is kept. The changes are below.

**Changes from roadmap §8:**
1. **Matrix cell schema** (ordinal, per P4): `{ direction, magnitude, timing, confidence, evidence[], uncertainty_driver (required when confidence = low), rationale, subdimension_notes {…} (EQ/PI only), indicator_codes[] with role, mechanism_ids[] }`. The 0–10 magnitude and the 0–4 `governance_ambition` are removed.
2. **Scenario axis.** Scenarios carry `code`, `name`, `description` and optional `ambition_rank` (ordinal position on the escalation axis, as in Macaronesia S1→S4). D5.2 uses six description dimensions (governance form, spatial scope, sectoral activation, monitoring and data, compliance credibility, financing/capacity), which become optional structured fields.
3. **Reference starters, loaded by DA** from the WS-2 `scenarios` block and a new `data/wp5_impact_reference.json`:
   - **Macaronesia:** S1–S4 with the published Table 21 text per criterion and confidence, as read-only "WP5 reference" cells that the user can copy into an editable assessment.
   - **Arctic:** 3 scenarios, published revenue tables (P3), and the Table 8 political-feasibility ratings.
   - **Tuscan:** an empty-state message explaining that D5.2 provides valuation, not scenarios, linking to WS-5.
4. **Mechanism linking** uses WS-2 `scenario_applicability` to pre-filter the list. **Indicator linking** uses WS-4 `criterion_roles` to suggest primary indicators per criterion.
5. **Displacement/leakage check** (A§8.4). Step 3 (scoping) prompts: "Could this intervention move the activity or pressure elsewhere?" A yes creates a flagged note, and if enabled, an optional linked P element ("displaced pressure").
6. **Step 6 auto-draft** is limited to deterministic templated sentences, on the pattern of the existing `decision_lens.R` narrative builder, in 9 languages. No free-generated prose.
7. **Storage.** `data$analysis$impact_assessment` (WS-0 convention). Call `stamp_min_app_version()` on first write.

**Files and reports.** As roadmap §8.2 and §8.6, with these differences:
- the report builder reuses `prepare_report_module.R`'s officer helpers (`generate_word_report`, `:620`);
- the report includes a provenance appendix listing every `toolbox_extension` value used.

**Visualisation (absorbs roadmap strand 5).** Criterion × scenario heat map:
- arrow glyph = direction;
- fill intensity = magnitude;
- hatching = low confidence.

The radar chart is **dropped**: an ordinal rubric cannot be plotted as radar areas without inventing numbers. If partners request it, it is reinstated as a `toolbox_extension` using the WS-1 ordinal→numeric map.

**Tests:**
- Roadmap §8.7 tests, with the magnitude tests changed to ordinal.
- Low confidence without an uncertainty driver blocks step advance.
- Macaronesia reference cells match Table 21 text (fixture).
- Arctic revenue values equal the published table values (no recomputation).
- Tuscan empty state.
- Round-trip including sub-dimension notes.

---

## WS-7. Intervention designer (D5.3 graph-edit modes)

**Source.** C§1, C§4, C§5.2: matrix operations, worked DA examples, D5.3 ranking criteria. Existing engine: `functions/ses_dynamics.R` (`ses_add_intervention:1012`, `simulate_dynamics:681`, `participation_ratio:776`, `laplacian_stability:381`, `state_shift_monte_carlo:897`, Boolean attractors `:455–618`).

**Placement.** This extends `modules/analysis_intervention.R`, which already designs a new intervention node and compares runs. It is not a new menu item.

**Three modes, chosen from the intervention type's allowed operations (WS-1 ops table):**

| Mode | Operation | Implementation |
|---|---|---|
| A. New intervention node | `new_node` | Generalise `ses_add_intervention` from uniform-random weights to an **exhaustive ordinal grid** (default levels −1, −0.5, −0.25, 0, 0.25, 0.5, 1), with per-edge sign constraints (e.g. indicator edges ≤ 0). Grid size is capped at 50,000 combinations; above that, fall back to Monte Carlo with a notice. |
| B. New edge between existing nodes | `new_edge` | New `ses_add_edges(mat, edges_df)`. Edges are validated against the DAPSIWRM transition validator. Includes an optional "biological self-loop" helper for living-resource C nodes (D5.3 Arctic and Tuscan pre-steps). |
| C. Re-weight existing edges | `reweight_edge` | Participation-ratio preselection of candidate edges, then grid or greedy search using `state_shift_monte_carlo`. |

**Objectives and ranking (D5.3 criteria, C§5.2).** The user picks objective nodes and "also-sustain" nodes (default: all GB). Each candidate configuration is scored on:
- (a) objective nodes > 0 over the last 100 of 1000 steps;
- (b) all also-sustain nodes > 0;
- (c) stable: all Laplacian eigenvalues real;
- (d) simplicity: number of non-zero intervention edges.

Results sort by a, then b, then c, then d. A Boolean-attractor pre-check runs first: if no desirable attractor exists, show "topology change needed" and suggest mode B (the D5.3 Macaronesia logic).

**Evidence priors.** Default level ranges by instrument category:
- behavioural (2.x): weak / low confidence (C§3);
- legal/regulatory and output/spatial measures: medium.

Shown as ranges with a provenance badge (`toolbox_extension` derived from the D5.3 evidence review).

**Outputs.** Success share over the grid (D5.3 reports results this way, e.g. "~7% of 50,176"), the top-k configurations, and before/after loops, leverage and attractors.

Optional **"Apply to project"**: writes the chosen configuration as a scenario (WS-0 storage), carrying an `ops` record: `{ op, from, to, weight, intervention_type, ebm_code }`. This also adds the missing `links_modified` support to the scenario builder.

**Performance.** There is no async infrastructure on canonical main: no `future`/`promises`, and `async_helpers` existed only on the dead fork. So:
- run grids synchronously inside `withProgress()`, with the 50,000-combination cap;
- vectorise the inner loop over grid rows. The R-torch lesson applies: no per-row dispatch.

Adding `ExtendedTask` + `future` is a separate decision. It is not required for v1.

**Tests:**
- Pure helpers: `ses_intervention_grid`, `ses_success_criterion`, `ses_is_stable_attractor`, `rank_simplest`, `ses_add_edges`.
- A fixture reproduces a D5.3 Tuscan "additional moorings" structure with the self-loop, asserting a non-zero success share for the [fast] variant.
- The grid cap triggers the Monte-Carlo fallback.

**Open (Q4).** Authoritative operation table; per-DA matrices; definitions for provisional rows.

---

## WS-8. Scenario × worldview reference library (D5.1)

**Source.** B§1, B§4. D5.1 is a congruence analysis regionalised to Europe. It has no driver vectors.

**Data:**
- `data/wp5_scenarios_ssp.json`: 4 SSP-RCPs, each with name, warming cap, and EBM-conduciveness (`yes` / `somewhat` / `no`). Holds the narrative per PESTLE × sector slice (HRMC / SH / LH) from the merged EU narrative. Empty source cells stay `null` with `gap_note`.
  - Per-cell provenance records the source project (FutureMARES / CERES / AFMEC) and its nominal RCP.
  - `driver_mapping: null` is an explicit curation placeholder.
- `data/wp5_worldview_matrix.json`: 3 worldviews (keywords, problem, solution, justice principle) and the 72-cell grid (`match` boolean, `outcome_class` a–d, `transformation_needed`, analyst rationale where available). Resolve the Hierarchy SSP1/SSP2 summary error per the spreadsheet, and record it as a `source_note`.

**UI.** A "WP5 scenarios" reference tab inside the existing `response_scenarios` page (scenario builder):
- SSP cards;
- a worldview × SSP heat map, with a PESTLE drill-down showing where transformation is needed;
- the journal-draft strategies for non-aligned worldviews (B§4.3).

A note states that the results are generic Europe-scale and not DA-specific.

**Linkage.** If WS-3 `pestle_tag` is set on Responses/Measures, highlight responses that address the PESTLE elements flagged for the selected worldview × SSP cell.

**Deferred.** "Apply scenario to CLD": sign-only pressures on user-matched Driver nodes, with persistent forcing added to `simulate_dynamics`. This needs a WP5-endorsed narrative→DAPSIWRM mapping (Q5). The worldview self-assessment also needs the WP5 questionnaire (Q5).

**Tests:**
- JSON integrity: 72 cells, each class in a–d.
- The grid reproduces `results_breakdown.xlsx` (fixture).
- Null cells render the gap note.

---

## WS-9. Governance profiles and readiness check (D5.4)

**Source.** D§1–2, D§4–5.

**Data:**
- `data/wp5_governance_profiles.json`, per DA:
  - governance levels;
  - actors by level, with role in the D5.4 typology (identical to `STAKEHOLDER_TYPES`);
  - legal instruments;
  - NPG-dimension strengths and challenges (+/−, from NPG Table 3 and D5.4 Tables 5–7);
  - gaps;
  - recommendations.

  Each recommendation is modelled as a Response template with `rm_kind = instrument`, an `ebm_code` (1.x/2.x/4.x) and actors as the target.
- `country_governance_db.json` additions:
  - countries GL and FO;
  - `regional_conventions` / bodies: NEAFC, ICES, GFCM, ACCOBAMS, Pelagos, MedPAN, Nordic Council.

**Features:**
1. **Seed stakeholders.** In PIMS, "Load DA actor list" adds the profile's actors as stakeholder rows. For Tuscany and Madeira this includes the published power/interest grid. Arctic and Azores/Canaries load actors only (D§5 row 6), with a note.
2. **Barrier/enabler cards.** Shown in the Response module filtered by the project's DA, and per NPG dimension. Each card: polarity, text, source.
3. **Governance-readiness check** (PIMS sub-tab). Questionnaire items from D5.4 Annex 5/7 with their published scales, mapped to NPG dimensions (D§4.2).
   - Optional, anonymous by default. No personal data is stored. The consent notice follows the project's GDPR form.
   - Aggregation per dimension is a `toolbox_extension` (agree = +2 … disagree = −2; "don't know" / "prefer not" = NA), always labelled "toolbox indicator, not a WP5 score".
   - Dimension 5 (cross-sectoral) is under-covered in the source, so the UI shows a "low item coverage" note rather than inventing items.
4. **Targets.** No WP5 targets exist (D§0). Add only an optional `policy_target` picklist on indicators (30x30, Nature Restoration Regulation, MSFD GES D1/D6, national MPA %), with free-text values.

**Tests:**
- Profile JSON integrity, with roles in `STAKEHOLDER_TYPES`.
- Seeding is idempotent: no duplicate stakeholders on a second click.
- Readiness aggregation unit tests, including that NA is excluded.
- Country DB contains GL and FO, and `get_countries_for_sea()` still passes.

---

## WS-10. Workshop elicitation

**Source.** A§7 (two instruments, not one); C§3.3 / D§3.4 (tenet definitions); D5.2 Annex 4 guiding questions.

**Module.** `modules/workshop_elicitation_module.R`, under PIMS.

**Instruments:**
- (a) Intervention ranking poll. The scale is configurable: −5..+5 (Arctic precedent) or 1–4 (Macaronesia), on importance, feasibility and long-term impact.
- (b) 11-tenet rating per intervention on a 5-point agree/disagree Likert, using the D5.2 Annex 4 guiding questions.

**Session model.** Facilitator mode. Responses are entered on one device, or imported from an xlsx/csv template; Mentimeter export columns are documented. Responses are stored anonymously in `data$pims$elicitation`.

**Outputs:**
- Distributions per intervention and tenet.
- Optional write-back of the median tenet level into WS-3 `tenet_scores`, marked "workshop-derived".

Optionally import the D5.2 Annex 4 Arctic tick-mark results as demo data, after verification against the PDF.

**Tests:**
- Scale configuration.
- Import of a template file.
- Median write-back.
- Anonymity: no name field is persisted.

---

## 3. Cross-cutting

**i18n budget (chrome only):**

| Workstream | Approximate keys |
|---|---|
| WS-1 | 120 |
| WS-2 | +15 |
| WS-3 | 60 |
| WS-4 | 30 |
| WS-5 | 40 |
| WS-6 | 120 |
| WS-7 | 50 |
| WS-8 | 30 |
| WS-9 | 70 |
| WS-10 | 40 |
| **Total** | **≈ 575 keys × 9 languages** |

The roadmap §9.1 risk on translation ownership still applies and is still unresolved. Long-form KB prose is English with a visible note.

**Scientific validation.** Run the `scientific-validation` skill and the `kb-connection-reviewer` agent on:
- WS-2 content;
- the WS-3 measure→DAPSIWRM-target table;
- the WS-7 transition validation for new edges;
- any future WS-8 driver mapping.

User assessment data is not validated.

**Schema and migration.**

| Workstream | Addition |
|---|---|
| WS-0 | Scenario location move |
| WS-3 | Optional response columns + `rm_type_code` migration |
| WS-4 | `registry_id` / `registry_version` |
| WS-6 | `analysis$impact_assessment` |
| WS-9 / WS-10 | `pims$elicitation` / readiness |

All additions are optional and `min_app_version` is stamped via the WS-0 helper. Each gets a round-trip test against a fixed 1.21.1 fixture project.

**Out of scope:**
- Country-specific multi-layer graphs (D5.3 Arctic unified model, C§5.6 item 8).
- Persistent forcing in `simulate_dynamics` (WS-8 deferred).
- Radar charts (WS-6).
- Custom rubrics.

---

## 4. Partner questions (consolidated; numbering matches the gap analysis §6)

1. **Mechanism lists and guidance.** Are final D5.2 Tables 9, 20 and 22 authoritative? Should the toolbox-authored per-mechanism assessment guidance be kept with a label, or dropped? *(gates WS-2)*
2. **Arctic revenue tables.** They are inconsistent with the stated assumptions and with Annex 6 multipliers. Which values are authoritative? *(gates WS-6 Arctic reference)*
3. **Macaronesia fiches.** Will fiches for C_02, M_02, T_02 and T_04 be produced? Is T_03 the shortlist meaning or the fiche meaning? *(gates WS-4 completeness)*
4. **D5.3 intervention→operation tables.**
   - Which is authoritative: the xlsx or the EBM framework?
   - Should there be one matrix per DA?
   - Please provide definitions for the ~12 undefined rows.
   - What is code 3.5?
   - Should a restoration/State row be added?

   *(gates WS-1 ops table and WS-7)*
5. **D5.1.**
   - Please share the worldview questionnaire and any DA results.
   - Can you confirm the summary error?
   - Has any DA-level regionalisation been done since February 2024?
   - Do you endorse a sign-only narrative→driver mapping?

   *(gates the WS-8 deferred items)*
6. **D5.4.**
   - Is the count of EBM principles 26 or 15?
   - Are Arctic and Azores/Canaries power/interest grids available?
   - Is a labelled toolbox readiness score acceptable?

   *(gates WS-9)*
7. **Audience per feature.** Which features are for experts, which for DA managers, and which for workshop participants? *(affects WS-9/10 priority)*

## 5. Document history

| Date | Change | Author |
|---|---|---|
| 2026-10-11 | Initial draft from the full WP5 folder audit (reports A–D) | Claude (with Artūras Razinkovas-Baziukas) |
