# WP5 Integration Roadmap — Design

**Date:** 2026-05-06
**Status:** Draft for partner review
**Baseline release:** 1.11.2
**Target end-state:** 1.15.0
**Predecessor analysis:** `WP5/WP5_Integration_Analysis_2026-04-23.docx`

---

## 1. Purpose and audience

This roadmap layers an actionable, time-phased plan on top of the existing WP5 integration analysis (2026-04-23). The analysis answered *what* should be integrated; the roadmap answers *when*, *in what order*, *with what dependencies*, and *touching which files*.

The document is hybrid:

- **Partner-facing narrative** at the top of each phase (suitable for the next WP5/SES coordination meeting deck).
- **Developer-detail appendix** below the narrative for each phase (file lists, schemas, tests, i18n keys, exit criteria, risks).

A single document travels to both audiences without requiring a parallel partner-facing summary.

## 2. Scope

**In scope** — the four core integration strands the analysis singled out as highest-leverage:

1. **Strand 1** — Financial-mechanism KB ingestion (Phase 1, target 1.12.0)
2. **Strand 4** — Ecosystem-service valuation calculator (Phase 2, target 1.13.0)
3. **Strand 2** — Indicator registry (Phase 3, target 1.14.0)
4. **Strand 3** — Impact-assessment module (Phase 4, target 1.15.0)

**Out of scope, deferred to future work** (see §10):

- Strand 5 — Scenario-comparison view (radar/heatmap)
- Strand 6 — DA dashboard enrichment from D5.2 annexes
- Strand 7 — Elliott 10+1 stakeholder ranking elicitation

## 3. Decisions baked in

| Decision | Choice |
|---|---|
| Audience / depth | Hybrid — partner narrative + developer appendix per phase |
| Scope | Core 4 strands; strands 5/6/7 explicit future-work appendix |
| i18n posture | English-first with translation backfill; UI chrome translated, KB long-form prose stays English (matches offshore-wind KB precedent) |
| Release rhythm | One strand per minor release |
| Ordering rationale | Phase 1 (KB) is the cheapest data work and unblocks all later phases; Phase 2 (valuation) ships the first user-visible feature; Phase 3 (registry) is required by Phase 4; Phase 4 (impact-assessment) is the centrepiece deliverable |

## 4. Phase map

| # | Phase | Strand | Version | Indicative duration | Headline output |
|---|---|---|---|---|---|
| 0 | Partner sign-off | — | (no release) | ~2 weeks | Roadmap ratified at WP5/SES coordination meeting; schemas agreed |
| 1 | KB ingestion | 1 | **1.12.0** | ~4 weeks | `data/ses_knowledge_db_wp5_mechanisms.json` for 3 DAs; reference pane on Response/Measure ISA elements |
| 2 | Valuation calculator | 4 | **1.13.0** | ~3 weeks | `modules/valuation_calculator_module.R`; first user-visible WP5 feature |
| 3 | Indicator registry | 2 | **1.14.0** | ~4 weeks | `data/wp5_indicators.json`; ISA-element ↔ indicator linkage via existing `indicator`/`indicator_unit`/`data_source` columns |
| 4 | Impact-assessment module | 3 | **1.15.0** | ~6–8 weeks | `modules/impact_assessment_module.R` — 7-step framework, criterion×scenario matrix, Word/Excel report |

### 4.1 Indicative timeline — under two effort assumptions

The phase durations above are **engineering effort**, not calendar time. Calendar time depends on how much of an engineer's week is actually available to WP5 vs. competing priorities (translation review, deployment work, klaidoos-style scientific cleanups, PR reviews, non-WP5 bug-fix backlog).

| FTE assumption | Phase 4 effort | Total elapsed (Phase 1 → 1.15.0 release) |
|---|---|---|
| **1.0 FTE on WP5** (optimistic) | 6 weeks | ~4 months |
| **0.6 FTE on WP5** (realistic given recent project rhythm) | 10 weeks | ~7 months |
| **0.4 FTE on WP5** (if WP5 deprioritised against other work) | 14 weeks | ~10 months |

The roadmap's per-phase effort estimates do not change with FTE; only the calendar mapping does. Partner-facing planning should use the **0.6 FTE / ~7-month** row as the default unless the team commits explicitly to 1.0 FTE on WP5 for the duration. The 4-month figure should not be quoted in coordination meetings without that commitment.

### 4.2 Dependency graph

```
                    ┌──► Phase 2 (Valuation)
                    │
Phase 0 ──► Phase 1 ┤
            (KB)    │
                    └──► Phase 3 (Indicator) ──► Phase 4 (Impact)
                                                     ▲
                                                     │
                          Phase 1 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
                                  (soft: Phase 4 reads
                                   the Phase 1 KB for
                                   linked-mechanism UI)
```

Hard dependencies:

- **Phase 2 → Phase 1**: valuation calculator reads `valuation_unit_values` extracted in Phase 1 (consumed via the same loader exposed by `functions/wp5_kb_loader.R`).
- **Phase 4 → Phase 3**: impact-assessment scoring matrix populates rows from the indicator registry.

Soft dependencies:

- **Phase 4 ⇠ Phase 1**: impact-assessment "linked mechanisms" UI consumes the Phase 1 KB. Phase 4 can technically build without it (mechanism multi-select renders empty), but a pre-1.12 Phase 4 wouldn't be useful to partners.

Phases 2 and 3 are sibling consumers of Phase 1, not sequential — the linear ordering in the version table reflects single-engineer serialization, not a technical dependency.

### 4.3 Note on parallel execution (not recommended)

A two-engineer plan could run Phases 2 and 3 in parallel after Phase 1 lands. **This would not save the ~3 weeks the naive math suggests** — both phases touch `functions/isa_form_builders.R` (Phase 1 reference pane, Phase 3 indicator picker) and several phases touch `constants.R` and shared test files. Realistic merge-conflict cost is roughly 1 week per engineer. Compression is real but smaller than it looks. Mentioned here because it will come up in coordination meetings; if pursued, plan for explicit serialization on `isa_form_builders.R`.

### 4.4 Partner gates

Each phase exits via a partner-approval gate:

- **Phase 0:** approve scope and JSON schema sketch
- **Phase 1:** approve mechanism extraction (5-mechanism sample correctness check)
- **Phase 2:** approve valuation methodology and unit-value bounds shown in UI
- **Phase 3:** approve indicator-fiche completeness
- **Phase 4:** approve scoring rubric, criterion definitions, report layout

Each gate has a default response window of **2 weeks** and an escalation path: if no response within **4 weeks**, the gate is escalated to the WP leads at the next coordination meeting. **Auto-approval on silence is not used** — academic-partner schedules (teaching loads, conference cycles, EU reporting) make 2-week silences common, and silently advancing the schema or rubric without explicit sign-off creates rework risk that materially exceeds the time saved. If a gate slips, the affected phase pauses; downstream phases that don't depend on the held content (e.g., Phase 2 doesn't depend on Phase 4 sign-off) continue.

The 2/4-week mechanism itself is a Phase 0 deliverable — it must be ratified by partners before it can be invoked.

---

## 5. Phase 1 — KB ingestion (target 1.12.0, ~4 weeks)

### 5.1 Partner-facing narrative

Phase 1 converts the WP5 financial-mechanism content from Word documents into a queryable JSON dataset. No new user interface module is built; the existing ISA/CLD modules grow a side-pane that surfaces relevant mechanisms when a user clicks a Response or Measure node. Cheapest extraction of the highest-leverage WP5 content; unblocks every later phase.

### 5.2 Files to create

| Path | Purpose |
|---|---|
| `data/ses_knowledge_db_wp5_mechanisms.json` | The 28 mechanism descriptions (16 Macaronesia + 6 Tuscan + 6 Arctic) plus `valuation_unit_values` block |
| `scripts/build_wp5_mechanisms_kb.py` | Python builder mirroring `scripts/build_offshore_wind_kb.py` style |
| `functions/wp5_kb_loader.R` | R loader, mirrors `functions/ses_knowledge_db_loader.R` |
| `tests/testthat/test-wp5-kb-loader.R` | Loader smoke tests |
| `scripts/kb_audit/audit_wp5_mechanisms.py` | Quality audit (≥8/10 attributes populated per mechanism) |

### 5.3 Files to modify

| Path | Change |
|---|---|
| `global.R` | Source `functions/wp5_kb_loader.R`; call loader at startup |
| `modules/isa_data_entry_module.R` (parent), `functions/isa_form_builders.R` (per-element form) | Add "Linked WP5 mechanisms" reference pane shown only for Response/Measure elements. Code-spike at Phase 1 kick-off settles whether the pane lives in the parent module's right rail or in the form builder for Response/Measure types — both are viable; the pane is small enough that the choice is purely about which file owns the rendering code |
| `constants.R` | Add `WP5_DA_CONTEXTS <- c("macaronesia", "tuscan", "arctic")` |
| `translations/modules/wp5_mechanisms.json` (new) | UI labels for the reference pane (~25 keys) |

### 5.4 JSON schema sketch

```json
{
  "version": "1.0",
  "description": "WP5 financial and implementation mechanisms catalogue (Deliverable 5.2).",
  "last_updated": "2026-MM-DD",
  "source_documents": [
    "Blue_corridor_financial toolkit_17_04_2026.docx",
    "Draft financial mechanisms_Tuscan DA.docx",
    "Draft text financial mechanisms_Arctic DA.docx"
  ],
  "demonstration_areas": {
    "macaronesia": {
      "description": "Blue Corridor; mechanisms supporting cross-jurisdictional MPA networks",
      "mechanisms": [
        {
          "id": "mac_01_blue_corridor_facility",
          "name": "Blue Corridor Facility",
          "cost_profile": "recurring",
          "what_it_funds": "Coordinated monitoring and enforcement across EEZ + ABNJ",
          "finance_flow": {
            "payer": ["EU", "national governments", "philanthropic"],
            "receiver": "regional secretariat",
            "type": "blended"
          },
          "design_parameters": [],
          "evidence_base": [],
          "transferable_lessons": [],
          "applies_to_DAs": ["macaronesia"],
          "success_metrics": ["C_01", "M_01"],
          "risks_and_guardrails": [
            { "risk": "mandate creep", "guardrail": "narrow corridor mandate" }
          ],
          "use_in_impact_assessment": "",
          "references": []
        }
      ]
    },
    "tuscan": { "mechanisms": [] },
    "arctic":  { "mechanisms": [] }
  },
  "valuation_unit_values": {
    "posidonia_oceanica": {
      "coastal_protection":   { "low": 3500, "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost" },
      "carbon_sequestration": { "low": 40,   "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon" },
      "recreation_tourism":   { "low": 400,  "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP" },
      "food_provision":       { "low": 150,  "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing" },
      "water_purification":   { "low": 350,  "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost" }
    },
    "restoration_costs": {
      "posidonia_oceanica": { "low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60 }
    }
  }
}
```

The `valuation_unit_values` block is bundled here so Phase 2 consumes it without a second extraction pass.

### 5.5 Tests

- Loader smoke test: 3 DA contexts present, expected mechanism counts, all mandatory fields populated, valuation block parses to numeric.
- Schema completeness audit: every mechanism has all 10 attribute fields; ≥8/10 populated as a hard floor.
- Reference-pane render test (`testServer`): Response/Measure element selected → pane lists ≥1 mechanism; Driver element selected → pane is empty.

### 5.6 i18n keys

~25 chrome keys. Mechanism content stays English. Backfill ticket: `WP5-i18n-Phase1` covering 25 keys × 8 non-English locales = 200 string translations.

### 5.7 Partner exit criteria

- 5-mechanism sample (Macaronesia: Blue Corridor Facility; Tuscan: PES; Arctic: cost-recovery fees; plus 2 partner-picked) verified paragraph-for-paragraph against source `.docx`.
- All 28 mechanisms pass `audit_wp5_mechanisms.py` completeness check (≥8/10 attributes populated).

### 5.8 Risks

| Risk | Mitigation |
|---|---|
| Source `.docx` text revised during Phase 1 build | Pin to commit `1f636e8`; later drafts → patch release |
| Build script makes manual hand-edits hard to recover | Header banner pattern (cf. `build_offshore_wind_kb.py`); CI check that fails if JSON newer than build script without tagged commit |
| Schema change after Phase 1 forces re-extraction | Lock schema at end of Phase 0 partner gate |

---

## 6. Phase 2 — Valuation calculator (target 1.13.0, ~3 weeks)

### 6.1 Partner-facing narrative

First user-visible WP5 feature. A calculator that lets users multiply a biophysical indicator value (e.g. hectares of *Posidonia oceanica*) by benefit-transfer unit values to get monetary estimates of ecosystem services, with low/central/high bounds. Output: annual total per service, cumulative NPV over a user-set horizon, and a side-by-side comparison with restoration cost. Data feeds from the `valuation_unit_values` block extracted in Phase 1.

### 6.2 Files to create

| Path | Purpose |
|---|---|
| `modules/valuation_calculator_module.R` | Standard `_ui(id, i18n)` / `_server(id, project_data_reactive, i18n, event_bus = NULL)` shape |
| `functions/valuation_calculations.R` | Pure functions: `calculate_annual_value()`, `calculate_npv()`, `calculate_break_even_horizon()` |
| `tests/testthat/test-valuation-calculator-module.R` | Signature-contract test |
| `tests/testthat/test-valuation-calculations.R` | Pure-function unit tests |
| `translations/modules/valuation_calculator.json` | UI strings (~40 keys) |

### 6.3 Files to modify

| Path | Change |
|---|---|
| `app.R` | Wire `valuation_calculator_server(...)`; add menu item under Analysis |
| `constants.R` | Add `WP5_DEFAULT_DISCOUNT_RATE <- 0.03`, `WP5_DEFAULT_TIME_HORIZON <- 20L` |
| `tests/testthat/test-modules.R` | Add module to the testServer integration suite |

### 6.4 Calculation logic (pure, testable)

```r
calculate_annual_value <- function(area_ha, unit_values) {
  list(
    low     = area_ha * unit_values$low,
    central = area_ha * unit_values$central,
    high    = area_ha * unit_values$high
  )
}

calculate_npv <- function(annual_value, horizon_years, discount_rate) {
  if (discount_rate == 0) return(annual_value * horizon_years)
  annual_value * (1 - (1 + discount_rate)^-horizon_years) / discount_rate
}

calculate_break_even_horizon <- function(annual_value, restoration_cost, discount_rate) {
  if (annual_value <= 0) return(NA_real_)
  if (discount_rate == 0) return(restoration_cost / annual_value)
  ratio <- 1 - (restoration_cost * discount_rate / annual_value)
  if (ratio <= 0) return(NA_real_)
  -log(ratio) / log(1 + discount_rate)
}
```

Pure functions; module reactives just call these. Critical edge cases for unit tests:

- `area_ha = 0` → all bands return zero
- `discount_rate = 0` → NPV = `annual_value * horizon`
- `horizon_years = 0` → NPV = 0
- `discount_rate = 0.03, horizon = 20, annual = €100k` → NPV ≈ €1.488m (reference)
- `restoration_cost > NPV(infinity)` → break-even returns `NA`; UI shows "does not break even within reasonable horizon"
- Band ordering invariant: `low ≤ central ≤ high` (post-condition assertion)

### 6.5 UX guardrails

- Show NPV across discount rates 0/3/5/7% as a small table — not just one user-chosen rate. Discourages rate-hunting.
- Methodology disclaimer in module header: "Benefit-transfer estimate; not a primary valuation."
- Phase 2 ships *one* habitat (Posidonia oceanica). Future habitats added with explicit applicability notes.

### 6.6 i18n keys

~40 chrome keys. Methodology disclaimer translated all 9 languages. Service names presented through translation lookup (English values for now). Backfill ticket: `WP5-i18n-Phase2`.

### 6.7 Partner exit criteria

- Tuscan partner reviewer confirms unit-value bounds match D5.2 §4.x table values within rounding.
- Methodology disclaimer text reviewed and signed off by Tuscan WP5 lead.
- `.xlsx` and `.docx` exports manually inspected for one full calculation.

### 6.8 Risks

| Risk | Mitigation |
|---|---|
| Users misinterpret benefit-transfer values as site-specific | Hard-coded methodology disclaimer; "Benefit-transfer estimate" badge next to TOTAL |
| Users compare incompatible habitats | Phase 2 ships Posidonia only; future habitats added with explicit applicability notes |
| Discount-rate UI invites rate-hunting | Multi-rate sensitivity table (0/3/5/7%) presented alongside user-selected rate |

---

## 7. Phase 3 — Indicator registry (target 1.14.0, ~4 weeks)

### 7.1 Partner-facing narrative

The Macaronesia and Tuscan chapters of D5.2 introduce structured indicators (C_01–T_04 plus Posidonia biophysical indicators). Phase 3 turns these into a typed reference vocabulary that users can attach to ISA elements: pick "Meadow density (shoots / m²)" from the registry, and the element's existing `indicator`/`indicator_unit`/`data_source` fields auto-populate from the registry entry. Traceability from CLD diagrams to measurable quantities improves substantially.

The registry **does not** introduce a parallel data structure — ISA elements already carry the relevant columns (see `functions/data_structure.R:284–286` inside `create_empty_element_df()`: `indicator`, `indicator_unit`, `data_source`). Phase 3 just provides an authoritative starting vocabulary the user can pick from.

### 7.2 Files to create

| Path | Purpose |
|---|---|
| `data/wp5_indicators.json` | Indicator registry — ~16 entries (11 Macaronesia + 5 Tuscan biophysical) |
| `functions/indicator_registry.R` | Loader + lookup helpers |
| `tests/testthat/test-indicator-registry.R` | Loader + lookup edge cases |
| `translations/modules/indicator_registry.json` | UI strings for picker (~30 keys) |

### 7.3 Files to modify

| Path | Change |
|---|---|
| `global.R` | Source `functions/indicator_registry.R`; call loader at startup |
| `functions/isa_form_builders.R` | Add "Indicator (from registry)" picker (`selectizeInput`) next to the existing free-text `indicator` field for every element type that exposes that field. On selection, auto-populate `indicator`, `indicator_unit`, `data_source` from the registry entry; user can still edit afterwards |
| `constants.R` | Add `WP5_INDICATOR_PATHWAY_SEGMENTS` vocabulary |
| `tests/testthat/test-data-structure.R` | Confirm auto-populated fields round-trip through save/load |

### 7.4 JSON schema sketch

```json
{
  "version": "1.0",
  "description": "WP5 indicator vocabulary (D5.2 Macaronesia & Tuscan chapters).",
  "indicators": {
    "C_01": {
      "code": "C_01",
      "name": "Connectivity",
      "category": "cross_cutting",
      "applies_to_DAs": ["macaronesia"],
      "definition": "Degree of physical and ecological connectivity between MPA nodes in the Blue Corridor.",
      "unit": "dimensionless index (0–1)",
      "spatial_scope": "EEZ + ABNJ corridor",
      "baseline_period": "2020–2024",
      "data_sources": ["satellite tracking", "biophysical modelling", "MPA boundary GIS"],
      "affected_stakeholders": ["fisheries managers", "MPA managers", "scientific community"],
      "role_in_criteria": {
        "EE": "primary", "EC": "secondary", "EQ": "n/a", "PI": "secondary", "FF": "n/a"
      },
      "dapsi_pathway_segment": "state",
      "default_dapsi_link": "Components/State",
      "references": ["D5.2 Annex C_01"]
    }
  }
}
```

### 7.5 Lookup helpers

```r
get_indicator_by_id(id)
list_indicators_for_dapsi(category)
list_indicators_for_da(da_site)
list_indicators_for_pathway(segment)
search_indicators(query)
```

Pure functions; the picker wires them to a `selectizeInput`.

### 7.6 Snapshot semantics + drift-detection

When a user picks a registry entry, the values are **copied** to the ISA element row at that moment, not bound. The link is a snapshot. The `registry_id` is stored as a new optional column (`NA_character_` default) — backwards compatible with existing project files.

Rationale: a live binding would silently mutate user data when the JSON updates between releases — a quietly nasty data-integrity bug. But the snapshot semantics have a worse failure mode if left unguarded: if the registry is corrected (typo in unit, fix to a baseline period, refined definition) in v1.1, every project that snapshotted from v1.0 keeps the typo with no way to know.

**Drift detection** (Phase 3 ships this together with snapshot semantics, not as an afterthought):

- A second optional column `registry_version` (e.g. `"1.0"`) is added alongside `registry_id` and stores the registry version at the moment of snapshot.
- On project load, the ISA element editor compares each `(registry_id, registry_version)` pair against the current registry. If the snapshotted version is older, a small "registry has been updated" badge appears next to that field.
- Clicking the badge shows a diff: snapshot value vs. current registry value, and a "re-snapshot to current" button. User decides per element; no silent rewrites.
- A new test in `tests/testthat/test-indicator-registry.R` covers: load a project with a stale snapshot → drift badge appears; user accepts re-snapshot → field updates and badge clears; user dismisses → no change, badge persists across reloads (until user accepts or registry rolls back).

This costs ~half a day of additional work in Phase 3 and prevents a class of silent data-correctness bugs that would otherwise compound over releases.

### 7.7 Tests

- Loader smoke test: file parses; all entries have required fields; `dapsi_pathway_segment` values are members of `WP5_INDICATOR_PATHWAY_SEGMENTS`.
- Round-trip test: pick registry entry → save project → reload → fields preserved exactly.
- Filter helpers: at least 5 entries returned for `Components/State`; no crash on empty `applies_to_DAs` filter.
- testServer-based picker integration test.
- Drift-detection test (per §7.6): load a project whose snapshotted `registry_version` is older than the current registry → drift badge appears; user accepts re-snapshot → field updates and badge clears; user dismisses → no change, badge persists across reloads.

### 7.8 i18n keys

~30 chrome keys. Indicator definitions stay English. Backfill ticket: `WP5-i18n-Phase3`.

### 7.9 Partner exit criteria

- Macaronesia partner verifies 11 indicator definitions match D5.2 §x.x text.
- Tuscan partner verifies 5 Posidonia biophysical indicator entries match D5.2 §4.x.
- End-to-end auto-population on a test project verified.

### 7.10 Risks

| Risk | Mitigation |
|---|---|
| Free-text `indicator` field re-typed without user awareness | Picker is additive; free-text stays editable; "from registry: C_01" badge shown, removable |
| Registry entries diverge from ISA element values over time | Snapshot semantics; documented "Selecting copies current values to this element" |
| 16 entries too few; users want their own | Out of scope; user-defined registry entries → future ticket |
| Schema collision with free-text `indicator` field | New optional `registry_id` and `registry_version` columns (added together); field schema otherwise unchanged; backwards compatible |

---

## 8. Phase 4 — Impact-assessment module (target 1.15.0, ~6–8 weeks)

### 8.1 Partner-facing narrative

The headline WP5 feature: an Impact-Assessment Module walking users through D5.2 §1.4's seven-step framework (characterisation → baseline + scenarios → impact scoping → criterion assessment → uncertainty → trade-offs → recommendations). The module ships exactly the rubric from the deliverable (5 criteria EE/EC/EQ/PI/FF; ≤5 scenarios) and produces a Word + Excel report consistent with D5.2's reporting conventions. The visual centerpiece is a criterion×scenario matrix with cells carrying direction, magnitude, timing, confidence and dominant-uncertainty fields. Users attach financial mechanisms (Phase 1 KB) and indicators (Phase 3 registry) directly to each cell, completing the "what causes what + how good is this intervention" loop.

### 8.2 Files to create

| Path | Purpose |
|---|---|
| `modules/impact_assessment_module.R` | Top-level module — UI shell, server orchestration. Hosts steps 1 (Characterisation), 2 (Baseline + scenarios), 3 (Impact scoping), 6 (Trade-offs / synergies); these are form-based steps that don't justify their own sub-file |
| `modules/impact_assessment/step_definitions.R` | 7-step `QUESTION_FLOW` equivalent (step metadata, completion predicates, navigation closures) |
| `modules/impact_assessment/scoring_matrix.R` | Step 4 — Criterion×Scenario matrix UI + per-cell modal |
| `modules/impact_assessment/uncertainty_analysis.R` | Step 5 — sensitivity prompts + tornado viz |
| `modules/impact_assessment/report_builder.R` | Step 7 — `officer` (.docx) + `openxlsx` (.xlsx) generation |
| `modules/impact_assessment/mechanism_linker.R` | Cross-cutting helper: shared mechanism multi-select consumed by step 4 cells. Reads the Phase 1 KB via `functions/wp5_kb_loader.R`. **Phase 4's soft dependency on Phase 1 is concentrated here** — if Phase 1 hasn't shipped, this file degrades to an empty selector |
| `functions/impact_assessment_calculations.R` | Pure functions: `score_to_color()`, `aggregate_criterion_scores()`, `criterion_summary_stats()` |
| `tests/testthat/test-impact-assessment-module.R` | Signature contract |
| `tests/testthat/test-impact-assessment-calculations.R` | Pure-function unit tests |
| `tests/testthat/test-impact-assessment-stepflow.R` | Step navigation correctness |
| `tests/testthat/test-impact-assessment-report.R` | Report generation |
| `translations/modules/impact_assessment.json` | UI strings (~120 keys) |

The split mirrors the eventual restructure of `modules/ai_isa/` — pre-splitting saves a future refactor cycle.

### 8.3 Files to modify

| Path | Change |
|---|---|
| `app.R` | Add menu item under Analysis; wire server with `event_bus` |
| `constants.R` | Add `IMPACT_CRITERIA`, `IMPACT_DIRECTIONS`, `IMPACT_TIMING` vocabularies; add `IMPACT_MAX_SCENARIOS <- 5L` (hard ceiling enforced in `step_definitions.R`) |
| `server/export_handlers.R` | Add download handlers for `.docx` and `.xlsx` reports |

### 8.4 The seven steps

| # | Step | UI shape | Outputs to project_data |
|---|---|---|---|
| 1 | Characterisation | Free-text + structured fields (focal issue, spatial scope, time horizon, stakeholders); some pulled from existing project metadata | `impact_assessment$characterisation` |
| 2 | Baseline + scenarios | Up to `IMPACT_MAX_SCENARIOS` (default 5, hard ceiling 10) scenarios with `name`, `description`, `governance_ambition` (0–4); user picks BAU baseline. The default of 5 reflects D5.2's per-DA scenario counts (Macaronesia 4, Arctic 3) and decision-science guidance on comparable alternatives; the configurable constant accommodates cross-DA comparison without forcing matrix-UX redesign | `impact_assessment$scenarios` |
| 3 | Impact scoping | Select DAPSI(W)R(M) elements (current ISA) and indicators (Phase 3 registry) in scope | `impact_assessment$scope` |
| 4 | Criterion assessment | The matrix: 5 criteria × N scenarios; each cell = `{direction, magnitude (0–10), timing, confidence, dominant_uncertainty, linked_mechanism_ids}` | `impact_assessment$matrix` |
| 5 | Uncertainty / sensitivity | Re-score under alternative assumptions; tornado-style visualisation | `impact_assessment$uncertainty` |
| 6 | Trade-offs / synergies | Auto-drafted narrative from matrix data; user edits | `impact_assessment$trade_offs` |
| 7 | Recommendations + report | Free-text recommendations + one-click `.docx`/`.xlsx` export | `impact_assessment$recommendations` |

### 8.5 The matrix UI (centerpiece)

```
                              S1 BAU      S2 Light      S3 Coord.    S4 Integrated
                            ┌───────────┬───────────┬───────────┬──────────────┐
Environmental effectiveness │  ↓↓ med   │  ~ low    │  ↑ med    │  ↑↑ high     │
Economic efficiency         │  ~ low    │  ↑ med    │  ↑ high   │  ↑ med       │
Equity and fairness         │  ↓ low    │  ~ low    │  ↑ low    │  ↑↑ med      │
Policy implementability     │  ↑ high   │  ↑ med    │  ~ low    │  ↓ low       │
Financial feasibility       │  ↑ high   │  ↑ med    │  ↑ low    │  ~ low       │
                            └───────────┴───────────┴───────────┴──────────────┘
```

- Direction: arrow glyph (↓↓ ↓ ~ ↑ ↑↑) ↔ `IMPACT_DIRECTIONS`
- Confidence: tile shade
- Per-cell modal: editable form for 5 fields + multi-select of mechanisms from Phase 1 KB

### 8.6 Report builder

`officer` + `openxlsx` (already in DESCRIPTION). Section structure mirrors D5.2 §1.4:

- Cover (DA, scenarios, date)
- §1 Characterisation
- §2 Scenarios
- §3 Scope (elements + indicators)
- §4 Criterion assessment matrix
- §5 Uncertainty analysis
- §6 Trade-offs and synergies
- §7 Recommendations
- Appendix: linked mechanisms (one-page-per-mechanism summaries from Phase 1 KB)

### 8.7 Tests

- Unit (calculations): direction-magnitude → composite score; uniform-weight aggregation; `score_to_color()` round-trip.
- Step flow: blocked advance from step 2 with no scenarios; i18n notification fires.
- Save/load round-trip: 4-scenario assessment → save → reload → matrix preserved with all cell metadata; mechanism links resolve.
- Report: end-to-end produces `.docx` and `.xlsx`; non-empty; section headings match expectations.
- Per-DA reference test: Macaronesia project → step 2 defaults to S1–S4 from KB.
- E2E (`shinytest2`): deferred to Phase 4.1 patch release to avoid blocking 1.15.0.

### 8.8 i18n keys

~120 chrome keys. Criterion definitions are first-class translations (domain-critical). Free-text user content not translated. Backfill ticket: `WP5-i18n-Phase4`.

### 8.9 Partner exit criteria

- A WP5 partner runs through all 7 steps end-to-end on a real DA scenario and generates a `.docx` they would attach to a real D5.2 deliverable annex.
- A second partner runs the **tutorial fixture project** (`data/tutorial_projects/wp5_macaronesia_demo.json`, per §9.8) end-to-end as a separate validation path; tutorial completes without errors and the in-app guided tour reads cleanly.
- Criterion definitions and scoring rubric tooltips reviewed and signed off.
- Macaronesia partner verifies S1–S4 scenarios load as defaults from the KB.
- `.docx` opens cleanly in Word/LibreOffice with table formatting intact; visual diff against an existing `report_generation.R` output shows consistent styling (per §8.10 row).

### 8.10 Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **Phase 4 effort underestimate** — 7-step wizard + matrix + report builder + ~120 i18n keys + 4 test files at 6–8 weeks is optimistic by precedent (the comparably-complex `modules/ai_isa/` workflow split across 9 sub-files); most likely failure mode is shipping with steps 5–6 stubbed and a Word export that partners reject for formatting | High | Plan against the §4.1 0.6-FTE row (10 weeks effort); commit to a Phase-4-week-2 internal scope review where the team explicitly confirms or descopes step 5 (uncertainty viz) and step 6 (auto-drafted trade-offs) — both are nice-to-have additions on top of the 5-step minimum required by D5.2 §1.4 |
| Scope creep — partners want a sixth criterion or custom rubric | High | Phase 4 ships exactly the D5.2 rubric; custom rubrics → future work |
| Matrix UI performance with many scenarios | Medium | `IMPACT_MAX_SCENARIOS` constant (default 5, ceiling 10); D5.2's per-DA scenarios are 3–4, so 5 covers same-DA comparison; ceiling 10 supports cross-DA comparison without UI redesign; paginate mechanism dropdown if KB grows |
| Save/load schema introduces breaking change | Low | `impact_assessment` block is optional; pre-1.15 projects load unchanged; migration test in CI; user-facing migration messaging — see §9.4 |
| Mid-phase requirements drift | Medium | Lock scoping + step definitions at end of Phase 4 week 2; later changes → follow-on minor release |
| Report builder breaks on unicode special chars | Low | `report_builder.R` sanitisation step; arrow rendering via Word table formatting, not literal glyphs |
| Report formatting drift from existing project reports | Medium | Phase 4 `report_builder.R` reuses style helpers from existing `report_generation.R` where applicable (table styles, header levels, font conventions); a side-by-side visual diff with one existing report is part of partner exit criteria |

---

## 9. Cross-cutting concerns

### 9.1 i18n backfill workflow — and its risk

Per phase: ~25–120 new English-only keys land (Phase 1 ≈ 25, Phase 2 ≈ 40, Phase 3 ≈ 30, Phase 4 ≈ 120; total ≈ 215). Non-English JSONs auto-receive the keys with the **English string as the value** (not empty, not `[XX]`). i18n CI passes. A `WP5-i18n-Phase{1..4}` ticket is opened per phase. The audit (`scripts/_i18n_audit.py`) gains an `--allow-english-fallback=wp5` flag (~15 lines of allowlist logic). As locales come back, English-fallback values are overwritten. Long-form prose (mechanism descriptions, indicator definitions) lives in JSON KBs, not in the i18n system, and stays English by design.

Total estimated translation queue: ~1,720 string translations (215 keys × 8 non-English locales).

**This workflow's failure mode is structural, not procedural.** The Marine SABRES toolbox markets itself as 9-language; klaidoos / Round-4 fixes earlier in the project were precisely about draining stale `[XX]` placeholders and Greek/Norwegian gaps. An English-fallback CI bypass with no named translator, no per-language reviewer, no SLA, and no plan for what happens at release if the backfill ticket is still open will become a permanent allowlist by default, not by intent. The risk is reputational and contractual, not technical.

**Phase 0 deliverable for i18n** (added in response to review):
- A named translation owner per locale, or one named owner accountable for queueing and tracking translations.
- A target backfill velocity (e.g., "two locales per phase, with the remaining six closed within the 1.x cycle") agreed in writing.
- An explicit decision: are translation deadlines **release-blocking** (then the per-phase calendar in §4.1 expands by 2–3 weeks) or **tracking targets** (then the English-fallback dynamic stands, with the structural risk above named publicly).

### 9.2 KB validation & scientific-validation skill

- `scripts/kb_audit/audit_wp5_mechanisms.py` — completeness + reference resolution + DA-tag consistency.
- `scripts/kb_audit/audit_wp5_indicators.py` — same pattern for indicators.
- `scientific-validation` skill (`.claude/skills/scientific-validation/`) — invoked during partner review of mechanism descriptions and indicator definitions; works on JSON KBs without modification.

User-generated impact-assessment matrix data is **not** subject to scientific validation. Validation applies to authoritative reference data only.

### 9.3 Testing strategy summary

| Phase | New test files | New file names | Total assertion budget |
|---|---|---|---|
| 1 | 1 | `test-wp5-kb-loader.R` | ~25 |
| 2 | 2 | `test-valuation-calculator-module.R`, `test-valuation-calculations.R` | ~40 |
| 3 | 1 | `test-indicator-registry.R` (covers loader, lookups, snapshot round-trip, drift detection) | ~30 |
| 4 | 4 | `test-impact-assessment-module.R`, `test-impact-assessment-calculations.R`, `test-impact-assessment-stepflow.R`, `test-impact-assessment-report.R` | ~80 |
| **Total** | **8** | | **~175** |

Adds ~2.6% to the existing ~6,768-assertion test base. All tests run in the existing harness; no new infrastructure.

**Note on Phase 4 budget:** the original draft of this spec under-budgeted Phase 4 at ~50 assertions; on review the surface area (7-step wizard, criterion×scenario matrix with 6-attribute cells, save/load round-trip, two report formats, mechanism + indicator linkage) does not fit in 50 assertions without leaving entire features uncovered. ~80 is a more honest number; the team should expect this to grow during implementation as edge cases surface.

### 9.4 Project-data schema migration — and its UX

| Phase | Change | Compatibility |
|---|---|---|
| 1 | None (KB is reference data) | ✓ |
| 2 | None (calculator state ephemeral) | ✓ |
| 3 | ISA element rows gain optional `registry_id` + `registry_version` columns (default `NA_character_`) | Backwards compatible |
| 4 | Project root gains optional `impact_assessment` block | Backwards compatible |

All schema additions are optional. A migration test in `tests/testthat/test-json-project-loading.R` (extended once per phase) loads a fixed 1.11.2 fixture project through each release version and asserts no data loss.

**User-facing migration UX** (added in response to review):

- **Forward-load (older project in newer toolbox):** when 1.15 loads a project saved by 1.11.2, the project loads cleanly with empty `impact_assessment` and `registry_id` slots. A one-time, dismissible toast on first project load explains: "This project was saved with an earlier version. New WP5 features (impact assessment, indicator registry) are available — you can start using them at any time. Existing data is unchanged." The toast is suppressed for projects already migrated, tracked via a `schema_migrated_at` field.
- **Downgrade (newer project in older toolbox):** if a user opens a 1.15-saved project (containing `impact_assessment`) in 1.13 or older, the older app silently ignores the unknown block. **However**, saving from the older app discards that block — a footgun for users running mixed installations across machines. Mitigation: 1.15 stamps a `min_app_version: "1.15.0"` field; older versions surface a single warning at load time ("This project uses features from a newer version. Save here to discard them.") and a non-dismissible badge in the title bar until the user explicitly chooses to save or upgrade.
- **The `min_app_version` mechanism is itself a 1.12.0 deliverable** (introduced in Phase 1 even though Phase 1 doesn't change project-data schema), because all four phases need a place to declare their minimum compatible version. Without it, downgrade silently corrupts data.
- **Documentation:** the project-load CHANGELOG entry for 1.15 explicitly names the migration UX so users encountering it have a reference.

### 9.5 Rollback strategy

The roadmap **does not** introduce feature flags. Rollback for this project is `git revert` + redeploy, consistent with the existing release flow. The earlier draft of this spec proposed a `WP5_FEATURES_ENABLED` constant; on review, that mechanism would add ~30 lines of dead branches the i18n CI then has to reason about, would fall out of sync with reality (sub-features added without a corresponding flag), and earns no real operational benefit at this project's deployment cadence (laguna.ku.lt + a small set of partner installs, no canary, no per-tenant gating). Removed.

If a phase exposes a critical post-release bug:
- Hotfix-or-revert per the existing release flow.
- Where a phase's data is preserved on disk in user projects (Phase 3 `registry_id`, Phase 4 `impact_assessment`), the schema is forwards-compatible (§9.4) so reverting the code does not orphan the data.

### 9.6 Risks register (consolidated, top items)

| Risk | Phase | Severity | Mitigation |
|---|---|---|---|
| Source `.docx` text revises during Phase 1 build | 1 | High | Pin to `1f636e8`; later drafts → patch release |
| **Translation backfill never delivered, English-fallback permanent** | All | **High** *(was Medium; bumped on review — the structural risk in §9.1 is reputational/contractual for a 9-language project)* | Phase 0 deliverable: named translator, target velocity, blocker-vs-target decision (§9.1) |
| Phase 4 scope creep | 4 | High | Lock rubric end of Phase 4 week 2; custom rubrics → future work |
| **Phase 4 effort underestimate at 6–8 weeks** | 4 | **High** | Plan against 0.6-FTE / 10-week effort row in §4.1; week-2 internal scope review can descope steps 5/6 |
| Partner reviewers slow → blocks phase exit | All | Medium | 2-week response, 4-week escalation, **no auto-approval on silence** (§4.4); affected phase pauses |
| Project file schema drift / downgrade footgun | 3, 4 | Low | All schema additions optional; `min_app_version` stamp + downgrade warning UX (§9.4) |
| **Engineer FTE on WP5 < 1.0** | All | **High** | §4.1 plans against 0.6-FTE default; 1.0-FTE timeline is contingent on explicit team commitment, not the spec's assumption |
| Existing user projects (1.11.2) load with empty WP5 features users don't understand | 3, 4 | Medium | First-load toast + CHANGELOG entry per §9.4 |

### 9.7 Coordination & cadence

- Weekly stand-up with WP5 partner contact during active phases.
- Phase exit reviews at monthly coordination meetings; partner sign-off documented in the same git commit as the version bump.
- This document is the canonical roadmap; updates land as PRs.

### 9.8 User training, onboarding, and change management

A 7-step impact-assessment wizard with criterion×scenario matrix is a substantial cognitive lift even for trained partners; for end-users encountering it in 1.15.0 with no prior exposure, "the menu item appeared under Analysis" is not enough. The roadmap therefore commits to the following per-phase deliverables, alongside the code:

| Phase | User-facing deliverable beyond code |
|---|---|
| 1 | CHANGELOG entry explaining the WP5 KB and how the reference pane is reached; tooltip on the pane explaining "what is this?" with a link to D5.2 §x |
| 2 | Methodology disclaimer is shipped as default text; CHANGELOG entry; one-paragraph "How to read these numbers" doc linked from the calculator UI |
| 3 | Indicator-picker tooltip explaining snapshot semantics + drift detection; CHANGELOG entry |
| 4 | A pre-populated **tutorial fixture project** at `data/tutorial_projects/wp5_macaronesia_demo.json`, loaded via "File → Open tutorial project", walking a user through one complete impact assessment with realistic but synthetic data; in-app guided tour for the 7 steps using existing `shinyjs`-driven highlights; partner-led training session before 1.15 release; CHANGELOG entry written for end-users not WP5 specialists |

The tutorial fixture (Phase 4) is part of the Phase 4 effort budget — it is not extra work tacked on after release, and it is part of the partner exit criteria (a partner runs through the tutorial as one of the validation paths).

---

## 10. Future work (deferred)

| Strand | Description | Rough sizing | Earliest release |
|---|---|---|---|
| 5 — Scenario-comparison view | Heat-map of criteria × scenarios + radar chart, generic across DAs and user-defined scenarios | ~2 weeks; depends on having ≥2 completed impact-assessments | 1.16.0 |
| 6 — DA dashboard enrichment | Per-DA overview tab populated from D5.2 annexes (Arctic / Tuscan / Macaronesia characterisations) | ~3 weeks; requires extraction of annex prose | 1.17.0 |
| 7 — Stakeholder ranking elicitation (Elliott 10+1) | Workshop-ready elicitation: −5 to +5 Likert across 10+1 tenets per intervention | ~4 weeks; participatory-assessment design + reporting | 1.18.0 |

Future-work table is revisited at each phase exit. What looks like a future strand may become better-defined or no-longer-needed.

---

## 11. Open questions for partners — Phase 0 inputs

These questions are required inputs to Phase 0 sign-off. The spec assumes a working answer for each (stated below) but partners should explicitly ratify or override.

1. **Engineer FTE assumption.** Spec defaults to **0.6 FTE on WP5** for calendar planning (~7 months Phase 1 → 1.15.0). Is the team committing to 1.0 FTE for the duration? If yes, ~4 months. If less, the calendar in §4.1 expands.

2. **Translation deadlines: blocker or target?** Spec assumes **target with named owner per phase** (English-fallback CI bypass during the cycle). If partners want translations release-blocking, each phase calendar expands by 2–3 weeks for translation review.

3. **Reviewer-of-record per DA.** Who is the partner contact for sign-off on (a) Macaronesia mechanism extraction (Phase 1), (b) Tuscan unit-value methodology (Phase 2), (c) Macaronesia + Tuscan indicator definitions (Phase 3), (d) full impact-assessment rubric and matrix UX (Phase 4)? Spec assumes **one named reviewer per DA**, identified before Phase 0 closes.

4. **Translation owner.** Who is accountable for queueing, tracking, and quality-checking the ~1,720 string translations? Spec assumes **a single named translation owner** (per §9.1's Phase 0 deliverable). Without this, the English-fallback risk in §9.6 is materially understated.

5. **Phase 4 step 5/6 descoping authority.** §8.10 names a Phase-4-week-2 internal scope review where the team can descope step 5 (uncertainty viz) and step 6 (auto-drafted trade-offs) if effort is tracking high. Spec assumes **the partner reviewer-of-record for Phase 4 has approval authority on this descope decision** without needing a full coordination-meeting cycle.

The following questions were in an earlier draft but the spec now commits to a specific answer; flagging here so partners can object if needed:

- Phase 1 source pin (`1f636e8`): **committed.** If a newer WP5 draft lands during Phase 1, treat it as a 1.12.x patch release per §5.8.
- Phase 4 scenario cap: **default 5, hard ceiling 10** via `IMPACT_MAX_SCENARIOS` (§8.4). Cross-DA comparison is supported within the ceiling.
- Phase 1 KB filename `ses_knowledge_db_wp5_mechanisms.json`: **committed**, mirroring `ses_knowledge_db_offshore_wind.json` precedent.
- Partner-gate auto-approval on silence: **removed** in §4.4. Phases pause on silence rather than advance.

## 12. Document history

| Date | Change | Author |
|---|---|---|
| 2026-05-06 | Initial draft, sections §1–§12 | Claude (with Artūras Razinkovas-Baziukas) |
| 2026-05-06 | Multi-angle review revision (round 1): see §13 | Claude (3 parallel reviewer agents + adversarial / consistency / grounding passes) |

## 13. Review log — round 1

This spec went through a multi-angle review by three independent reviewer agents (grounding, adversarial, internal-consistency). Findings are recorded here so future readers can see what was challenged, what changed, and what was deliberately rejected.

### 13.1 Material changes applied

- **§4.1 — Two-FTE-assumption table.** The original draft asserted "~4–5 months" with "~1 FTE" hidden in a parenthetical. The adversarial reviewer flagged this as load-bearing-and-probably-false. Replaced with an explicit FTE/calendar table; **0.6 FTE / ~7 months** is now the default partner-facing figure.
- **§4.2 — Dependency graph redrawn.** The original ASCII graph drew Phase 1→2→3→4 in a line, implying Phase 3 depends on Phase 2. It does not — Phases 2 and 3 are sibling consumers of Phase 1. Graph redrawn.
- **§4.3 — Compression option recharacterised.** The original "save ~3 weeks with two engineers" claim was naive about merge conflicts on `functions/isa_form_builders.R`. Now states realistic ~1-week conflict cost and recommends explicit serialization on shared files if pursued.
- **§4.4 — Auto-approval on silence removed.** The "1-week response, 2-week escalation = approved with minor revisions" mechanism was unrealistic for academic-partner schedules. Replaced with **2/4-week response/escalation, no auto-approval**; affected phase pauses on silence. Mechanism itself is now a Phase 0 deliverable (partners must ratify it before it can be invoked).
- **§7.6 — Drift detection added.** Snapshot semantics were correctly chosen but the adversarial reviewer flagged that uncorrectable typos are a worse failure than careful migration. Added `registry_version` field, "registry has been updated" badge UI, and a re-snapshot path. ~½ day extra Phase 3 work.
- **§8.2 — Sub-file ↔ step mapping clarified.** Original §8.2 listed 5 sub-files but §8.4 had 7 steps; 4 of 7 had no sub-module. Now explicit: top-level module hosts steps 1/2/3/6 (form-based, no sub-file warranted); steps 4/5/7 each get one sub-file. Also added `mechanism_linker.R` as a cross-cutting helper that locates Phase 4's soft Phase 1 dependency in one file.
- **§8.4 — Scenario cap configurable.** `IMPACT_MAX_SCENARIOS` constant (default 5, hard ceiling 10) replaces hard-coded 5. Supports cross-DA comparison without UX redesign.
- **§8.10 — Phase 4 effort risk added as High.** The 6–8w estimate was challenged as 12–16w-realistic by the adversarial reviewer. Added explicit risk; mitigation calls for week-2 internal scope review with authority to descope steps 5/6.
- **§8.10 — Excel/Word export format consistency** with existing `report_generation.R` outputs is now part of partner exit criteria.
- **§9.1 — i18n risk severity bumped to High.** The English-fallback workflow's structural risk (named-owner, SLA, velocity) is now stated explicitly. Phase 0 deliverables added: named translator, target velocity, blocker-vs-target decision.
- **§9.3 — Test count corrected.** Original total claimed 9 files; sum was 8. Corrected to 8 with explicit file names. Phase 4 budget bumped from ~50 to ~80 assertions (the original was structurally under-scoped for the Phase 4 surface area). Total ~175.
- **§9.4 — User-facing migration UX added.** The original "all schema additions optional, round-trip test in CI" was technically correct but operationally insufficient. Added forward-load toast, downgrade warning UX, `min_app_version` stamp introduced as a Phase 1 deliverable.
- **§9.5 — Feature flags removed.** YAGNI for this project's deployment cadence. Replaced with a one-paragraph rollback statement.
- **§9.6 — Risks register updated.** Severities for i18n backfill and engineer FTE bumped to High; new rows for Phase 4 effort underestimate and existing-user migration UX.
- **§9.8 — User training and onboarding section added.** Per-phase user-facing deliverables (CHANGELOG, tooltips, tutorial fixture project, in-app guided tour, partner training session) now committed alongside code.
- **§11 — Open questions cleaned up.** Already-settled items (commit pin, KB filename) moved to a "committed" sub-list; remaining items are genuine partner inputs (FTE commitment, translation owner, reviewers-of-record, descope authority).
- **§7 — Line citation `data_structure.R:285` corrected to `:284–286`** with the function name (`create_empty_element_df`) added.

### 13.2 Findings deferred / rejected

- **"Test budget is laughably under-scoped"** (adversarial, MINOR): partially accepted via the Phase 4 bump from 50 to 80 assertions. Going further would mis-shape the spec — implementation will reveal the right number, and the spec budget is a floor, not a ceiling.
- **"§5.3 reference-pane code spike defers integration work"** (adversarial, MINOR): kept as-is. The spike is a legitimate open question that benefits from being decided in code, not in prose; both candidates (`isa_data_entry_module.R` parent vs. `isa_form_builders.R` per-element) are explicitly named so the decision-maker has a known choice set rather than a TBD.

### 13.3 Round 2 — focused regression review

A focused round-2 review (one reviewer agent verifying the 16 round-1 fixes against the revised text and looking for new issues) confirmed all 16 round-1 items resolved (14 cleanly, 2 partially with minor cosmetic gaps). Round 2 surfaced four trivial editorial issues introduced by the round-1 revisions; all were applied inline:

- §4.2 wording: "team's one-FTE serialization" → "single-engineer serialization" (consistent with §4.1's 0.6-FTE default).
- §7.7 test bullets: drift-detection test added explicitly (was implied in §7.6 prose but missing from the §7.7 test list).
- §7.6 column wording: clarified that `registry_version` is a *second* column added alongside `registry_id`, not a value smuggled into the `registry_id` column. §7.10 risks row updated to match.
- §8.9 partner exit criteria: tutorial fixture walk-through added as a second validation path (was named in §9.8 but not echoed in §8.9).

Bottom-line round-2 verdict: spec is ready for final user approval; no further review rounds needed.

### 13.4 Tools used in the review loop

- 3× general-purpose reviewer agents in parallel (round 1): grounding, adversarial, internal-consistency.
- 1× general-purpose reviewer agent (round 2): focused regression review.
- `superpowers:requesting-code-review` skill protocol for dispatch shape.
- Claude harness `Edit` tool for inline application of findings.
- No MCP scientific-validation invocation: the spec's empirical claims (Posidonia valuation values, NPV math, DAPSIWRM transitions) are sourced from the peer-reviewed D5.2 deliverable itself; no external literature claims required external verification.
