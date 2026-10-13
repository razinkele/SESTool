# WP5 WS-6b (impact-assessment module UI): planning handoff

**Status:** planning not yet written. This file records the decisions and starting facts so the next session can write the WS-6b implementation plan (`docs/superpowers/plans/<date>-wp5-ws6b-impact-module.md`) with superpowers:writing-plans and then execute it.
**Branch:** `feat/wp5-ws6b-impact-module` (created from `main` at `80c61f6`) in worktree `C:/Users/arturas.baziukas/wt-ws6`.
**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-6 (L327-371), principles P1-P7 (top), cross-cutting §3. Roadmap `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md` §8 (L420-530: steps, matrix UI, report, tests, exit criteria, risks).
**Previous plan:** `docs/superpowers/plans/2026-10-12-wp5-ws6a-impact-data.md` (WS-6a: the data and model layer, now done).

## Where things stand (2026-10-13)

- WS-6a is merged to `main` (`80c61f6`), pushed to origin, CI green (R Tests and i18n validation), and deployed to laguna. VERSION is still **1.24.0**. The CHANGELOG entry is under `[Unreleased]`. WS-6a + WS-6b ship together as **1.25.0** (`WP5_IMPACT_MIN_APP_VERSION <- "1.25.0"` already in constants.R).
- The full suite on `80c61f6` gave 14,925 pass / 0 fail. Run it in alphabetical chunks with a fresh Rscript per chunk; a single run is killed for low memory.

## WS-6a API that WS-6b drives (functions/impact_assessment_model.R, functions/impact_reference.R)

- Construct / start: `new_impact_assessment(da)`, `impact_assessment_from_reference(da)` (published scenarios + baseline; Tuscan → no scenarios; `da = ""` → empty assessment).
- Scenarios: `new_impact_scenario(code, name, description, ambition_rank, source, dimensions)`, `impact_add_scenario`, `impact_update_scenario(ia, code, name=, description=, ambition_rank=, dimensions=)`, `impact_remove_scenario`, `impact_set_baseline`, `impact_scenario_codes`. Max `IMPACT_MAX_SCENARIOS` (5).
- Cells: `new_impact_cell()`, `impact_get_cell`, `impact_set_cell(ia, criterion, scenario_code, cell)`. Fields: direction, magnitude, timing, confidence, evidence[], uncertainty_driver, rationale, subdimension_notes (EQ/PI), indicator_roles (code→role), mechanism_ids[], reference.
- Sections: `impact_set_section(ia, section, values)` for characterisation (focal_issue, spatial_scope, time_horizon, stakeholders), uncertainty (notes), trade_offs (text, auto_draft), recommendations (text). Scope: `impact_set_scope_items(ia, element_ids, indicator_codes)`, `impact_set_displacement(ia, answer, note, displaced_pressure_id)`, `impact_displacement_flagged`.
- Problems / step gating: `impact_cell_problems`, `impact_step_problems(ia, step)` (steps 2, 3, 4), `impact_problem_blocks`, `impact_can_advance(ia, step)`.
- Reference: `impact_reference_status(da)` ("available" | "valuation_only" | "unavailable"), `impact_reference_cell`, `impact_reference_revenue("arctic")`, `impact_copy_reference_cell(ia, criterion, scenario_code, overwrite)` (errors: no_da, no_reference_cell, scenario_not_reference, cell_not_empty, unknown_scenario).
- Linking: `impact_mechanism_options(da, scenario_code)` → id, name, applicability, applicability_text (all mechanisms, sorted); `impact_indicator_suggestions(criterion, da)` → code, name, role, stub.
- Storage: `get_impact_assessment(project)`, `set_impact_assessment(project, ia)` (stamps 1.25.0; errors `malformed_assessment`; NULL removes the block).
- Errors are conditions of class `impact_error` with `$code`. WS-6b translates every error and problem code. Code lists to label: `IMPACT_SCENARIO_DIMENSIONS`, `IMPACT_DISPLACEMENT_ANSWERS`, `IMPACT_TEXT_SECTIONS` fields; problem codes direction_missing, confidence_missing, driver_required, invalid_*, no_scenarios, too_many_scenarios, baseline_missing, displacement_note_missing. Rubric labels already exist (WS-1 `wp5_vocab_label()`).

## Decisions already taken for WS-6b

1. **Task 1 (prerequisite, from the WS-6a final review): stop the wholesale `data$analysis` wipes.**
   - Sites: `functions/reactive_pipeline.R:239` (live via `app.R:1085`), `modules/import_data_module.R:573`, `modules/ses_models_module.R:777`.
   - They replace `data$analysis` when the ISA/CLD changes, which destroys `analysis$impact_assessment`. They already destroy WS-0's `analysis$scenarios` on main today.
   - Fix: clear only their own keys (loops, metrics, …) and add a regression test that an assessment, and scenarios, survive an ISA-change invalidation.
2. **Step 5:** free-text uncertainty notes only (WS-6a stores `uncertainty$notes`). Re-scoring under alternative assumptions is descoped, as roadmap §8.10 allows. Record this in the plan and CHANGELOG. To reinstate it later, raise `IMPACT_SCHEMA_VERSION` and `WP5_IMPACT_MIN_APP_VERSION` together and extend the `.impact_fill_*` helpers and the normaliser.
3. **Copy-from-reference button:** offer it only for scenarios whose `source == "wp5_reference"`. The model enforces this (`scenario_not_reference`).
4. **Schema rule:** any new stored field must be added to the matching `.impact_fill_*` helper and to `normalize_impact_assessment()`. Otherwise it disappears on the next load (the normaliser is a whitelist).
5. **No radar chart** (spec). Heat map instead: criterion × scenario; arrow glyph = direction, fill intensity = magnitude, hatching = low confidence. The ordinal→numeric map for fill is one documented function marked `toolbox_extension` (P4).
6. **Tuscan:** empty state explaining that D5.2 gives valuation, not scenarios, with a link to the WS-5 valuation calculator (`response_valuation`).
7. **Arctic:** show the published revenue tables read-only, with the partner-question-2 inconsistency note (P3), and the Table 8 political-feasibility reference cells.
8. **Displacement:** a "yes" needs a note (step 3 blocks otherwise); optionally create a linked P element ("displaced pressure") and store its ID in `scope$displacement$displaced_pressure_id`.
9. **Provenance badges (P1)** wherever reference text, copied cells or toolbox-extension values are shown.
10. **Out of WS-6b (that's WS-6c):**
    - Step 6 deterministic narrative (`trade_offs$auto_draft`, 9 languages, on the `decision_lens.R` pattern).
    - Word/Excel report with provenance appendix (reuse `prepare_report_module.R` officer helpers, `generate_word_report` ~:620).
    - WS-6b still lets the user edit `trade_offs$text` and `recommendations$text`.

## Open questions for the plan writer

- Menu placement: the roadmap said "under Analysis"; WS-5's valuation sits under Response & Validation (`response_valuation`). Pick one and justify it.
- Wizard shape: one module plus `modules/impact_assessment/` sub-files (roadmap §8.2) vs. a single module file. Roadmap §8.10 warns this is the highest-effort-risk phase; consider splitting WS-6b into 6b-1 (task 1 + steps 1-3 + scenario editor) and 6b-2 (matrix, modal, heat map, steps 5-7).
- i18n budget: ~120 keys × 9 languages. Plan a dedicated translation task with the audit (`micromamba run -n shiny python scripts/_i18n_audit.py` must report missing=0, hardcoded=0) and `# i18n-ref:` sentinels for dynamic code→key lookups.

## Code map (to be completed)

An exploration of the code WS-6b depends on was started on 2026-10-13:
- the valuation-module pattern, sidebar and app.R wiring, i18n file layout and tests;
- how modules write project data and emit event_bus events;
- the three wipe sites;
- DA detection (data$metadata$da_site → WP5_DA_CONTEXTS);
- listing ISA elements and adding a P element;
- plotting conventions;
- ui_components / provenance_badge;
- testServer patterns;
- menu structure.

If `docs/superpowers/plans/2026-10-13-wp5-ws6b-code-map.md` exists next to this file, use it. Otherwise re-run that exploration first.

## Next session checklist

1. `git -C C:/Users/arturas.baziukas/wt-ws6 status`. You should be on `feat/wp5-ws6b-impact-module` at `80c61f6` plus this handoff commit.
2. Read this file and the spec §WS-6. Read the code map, or re-run the exploration.
3. Write the WS-6b plan with superpowers:writing-plans. Review it with the 5-lens workflow, as was done for 6a (`wf_d4af0cc7-399`): spec, R correctness, source fidelity, integration, tests-and-gaps.
4. Execute with superpowers:subagent-driven-development.
5. Release 1.25.0:
   - bump VERSION, DESCRIPTION and VERSION_INFO.json;
   - move the CHANGELOG [Unreleased] entry into the 1.25.0 section;
   - PR, merge and tag v1.25.0;
   - deploy with `deploy-remote.ps1 -Force`.
