# WP5 WS-7b: Intervention designer — mode C, before/after, Apply to project — design

**Date:** 2026-10-15
**Status:** approved in brainstorming (sections 1-4); written spec awaiting review
**Builds on:** `2026-10-14-wp5-ws7a-intervention-designer-design.md` (released as 1.27.0)
**Master spec:** `2026-10-11-wp5-practical-integration-specs.md` §WS-7
**Source:** D5.3 final (`WP5/Task 5.3 Societal Behaviour Change/MarineSABRES_5_3_final.docx`); paragraph numbers below are `FIN:<n>` in the text extracted with python-docx (1,038 paragraphs).

## 1. Purpose and scope

7b completes WS-7. It adds:

1. **Mode C (`reweight_edge`)**: re-weighting existing links, as D5.3 did for the Arctic DA (FIN:325, 580-605).
2. **"What success depends on"**: D5.3's per-edge summary of the levels that successful configurations need (FIN:584-592).
3. **Before / after structure** for a selected configuration: feedback loops, leverage points, Boolean attractors.
4. **"Apply to project"**: writes a selected configuration as a Scenario Builder scenario with an `ops` record, and adds the missing `links_modified` support to the Scenario Builder.

Out of scope: writing a configuration into the project CLD/ISA itself; sign flips or link removal in mode C; the D5.3 "same-step" option for the new-node delay; per-country multi-layer graphs; reproducing D5.3's Arctic numbers (see §7).

## 2. Decisions taken in brainstorming

1. **Mode C levels follow D5.3: sign fixed.** A re-weighted link takes weak / medium / strong of its current sign (`sign(w) × {0.25, 0.5, 1}`): 3 levels, never removed, never flipped. D5.3 keeps signs explicitly (FIN:388) and counts 3 levels per edge (FIN:580: 3^19 = 1,162,261,467 sets).
2. **Link choice is PR-guided plus manual.** Components ranked by participation ratio; ticking one adds all its existing links; single links can be removed or added. D5.3 selects "all edges connected to" the high-PR components (FIN:580, 605).
3. **Apply writes a new scenario only.** The baseline CLD/ISA is never modified.
4. **One engine.** Mode C is a new variable-edge kind in the 7a grid engine, so ranking, sampling, stability, time budget and the background worker are reused, and modes can be combined in one design. A separate engine built on `state_shift_monte_carlo()` was rejected: its continuous uniform randomisation is not D5.3's ordinal grid and it has no ranking or stability step.

## 3. Engine (`functions/intervention_designer.R`)

### 3.1 Edge kind `reweight`

- `edges$kind` gains the value `"reweight"` (existing: `"intervention"`, `"new_edge"`).
- `ses_design_matrix()`:
  - a `reweight` edge must sit on an **existing non-zero** cell of `base`; otherwise `stop("a re-weighted edge must exist in the network")`;
  - the existing check (a non-`reweight` variable edge on an existing cell is an error) stays;
  - a `reweight` edge's level set is `sign(base[from, to]) * c(0.25, 0.5, 1)`, intersected with the row's `min_level`/`max_level` range (so the user can narrow it, never flip it). An empty intersection is an error, as for other kinds;
  - the result gains `base_levels`: the baseline weight of each variable edge (0 for `intervention` and `new_edge`).
- `ses_apply_config()` is unchanged (variable cells are zeroed in `dm$matrix` and overwritten by the configuration).

### 3.2 Criterion (d)

(d) becomes **the number of variable edges whose level differs from `base_levels`**, counted over `count_rows`. For `intervention` and `new_edge` rows `base_levels` is 0, so 7a values are unchanged. For `reweight` rows (d) counts changed links, so among equally successful configurations the one closest to today's system ranks first. `count_rows` rule extended: rows of kind `intervention` when any exist, else all rows (unchanged), with `reweight` rows always included.

### 3.3 Edge dependence

`ses_edge_dependence(levels_matrix, success, level_sets)`:
- input: the levels of each variable edge for the (a)-passing configurations (the worker keeps them, `n_var × n_success`), and the level sets;
- output: a data frame with one row per variable edge: `from`, `to`, `kind`, one share column per level of its set (share of successes at that level), `decisive` (TRUE when successes use a strict subset of the edge's levels), `needed_levels` (the levels used when decisive);
- computed in the worker over the (a)-passing rows of the evaluated grid (exhaustive or sampled), returned as `result$dependence`; NULL when there are no successes.
- "Success" here is criterion (a), as in D5.3's Arctic summary (FIN:584).

### 3.4 Participation-ratio candidates

`ses_pr_candidates(mat)`:
- calls `participation_ratio(mat)` (`functions/ses_dynamics.R:776`); on error returns NULL;
- returns components ranked by PR (descending), each with `node`, `pr`, `n_links`, and its existing links (`from`, `to`, `weight`, incoming and outgoing, self-loops once).

### 3.5 Configured network and scenario builders

- `ses_config_network(dm, levels, cld)`: CLD-shaped `list(nodes, edges)` for one configuration. Weights map to `polarity` (`+`/`-`) and `strength` (`weak`/`medium`/`strong`, from `DYNAMICS_WEIGHT_MAP`); level 0 = no edge; the new node gets `dapsi`/`group` "Responses" and a generated id. Node and edge ids come from `cld` (matrix rows are labels; the label → id map is `cld$nodes`).
- `ses_config_to_scenario(dm, levels, cld, meta)`: the scenario list of §5.1.

### 3.6 Grid size

Mode C grows grids as 3^n. The existing limits apply unchanged: the 65,536 cap with seeded sampling above it, and the `SES_MAX_GRID_COMBINATIONS` (4.5e15) block. D5.3's Arctic 3^19 shows as "sampled 65,536 of 1,162,261,467". Prototype timing on the laptop: 16,384 configurations of a 23-node graph in 50 s.

## 4. Designer tab (`modules/intervention_designer_module.R`)

### 4.1 Step 2, Edges: "Re-weight existing links (mode C)"

- A third button next to "Add intervention node" and "Add edge between existing nodes".
- It opens a panel listing `ses_pr_candidates()` for the current CLD (computed once per CLD version, cached in the module): component, PR bar, number of links, checkbox.
- Ticking a component adds all its links as `reweight` rows; a link shared by two ticked components is added once. Unticking removes the rows that component added (rows also reached through another ticked component stay).
- A "from → to" picker of existing links adds single links.
- Variable-edge table: `reweight` rows show kind "re-weight" and a fixed-sign badge; min/max selectors offer only weak / medium / strong of that sign.
- The run-size line is unchanged ("3^12 = 531,441 combinations — sampled 65,536").
- The advisory ops note includes `reweight_edge` in the union check.
- If PR fails: "Participation ratio unavailable" in the panel; manual link choice still works.

### 4.2 Run gating

Added to 7a's reasons: a `reweight` row whose link no longer exists in the CLD, or whose sign changed since it was added ("link changed in the CLD"). The sign check matters because the level set was derived from the old sign.

### 4.3 Results column additions

1. **"What success depends on"**: shown when `result$dependence` is not NULL. One row per variable edge with stacked share bars per level; decisive edges highlighted with a sentence ("Success needs *A → B* at weak (+)"). Applies to all modes.
2. **"Compare structure"** button for the selected top-20 row, run on demand as a background job (§4.4). Shows:
   - **Loops**: baseline vs configuration counts of reinforcing and balancing loops; lists of loops gained, lost, and changed in polarity (loops compared as node sets in cycle order);
   - **Leverage**: top 10 by `identify_leverage_points()` side by side, with rank-change arrows and "new" marks;
   - **Attractors**: Boolean attractor count and desirable-attractor count, baseline vs configuration, reusing `ses_boolean_precheck()` logic at the selected levels; "skipped" above `max_boolean_nodes` (20) or without BoolNet, as in 7a.
3. **"Apply to project"** on the selected row (§5).

### 4.4 Compare job

- `designer_job_start()` gains a `type` argument: `"run"` (7a, default) or `"compare"`. The compare worker sources `functions/network_analysis.R` and `functions/intervention_designer.R`, loads `igraph`, defines a no-op `debug_log()` when absent, and returns `list(loops = list(baseline, config), leverage = list(baseline, config), attractors = list(baseline, config))` as plain data.
- `scenario_loops()` moves from `modules/scenario_builder_module.R` to `functions/network_analysis.R` (unchanged body) so the worker can source it; the Scenario Builder keeps calling it by name.
- One job per session at a time (run or compare); same timeout and cancel as 7a.

### 4.5 Stale results

When the ISA changes after a run, the 7a rerun notice appears and Compare and Apply are disabled until the next run.

## 5. Apply to project

### 5.1 Scenario written

Modal: name (default "‹intervention name› — configuration #‹rank›", "(2)", "(3)"… appended if the name exists) and description (pre-filled: seed, success share, a/b/c/d, exhaustive or sampled). On confirm, `ses_config_to_scenario()` builds:

| Variable edge in the configuration | Scenario entry |
|---|---|
| new intervention node (design has `new_node`) | `nodes_added`: `{id, label, dapsi = "Responses", description}` |
| `intervention` / `new_edge`, level ≠ 0 | `links_added`: `{id, from, to, polarity, strength}`; `from`/`to` are node ids |
| any variable edge at level 0 | nothing |
| `reweight`, level ≠ baseline | `links_modified`: `{edge_id, from, to, polarity, strength, previous_strength}` |
| `reweight`, level = baseline | nothing |

The scenario also carries:
- `ops`: one record per written change, `{op, from, to, weight, intervention_type, ebm_code}`; `op` ∈ `new_node`, `new_edge`, `reweight_edge`; `intervention_type`/`ebm_code` from the selected type (NA when none; `ebm_code` via `get_intervention_ebm_codes()`);
- `source = "intervention_designer"`; `id`, `name`, `description`, `created`, `modified`, `results = NULL` as for builder-created scenarios.

It is appended to `project_data$data$analysis$scenarios` through `project_data_reactive()`. The Scenario Builder's reload observer picks it up. Writes are all-or-nothing: if any node or edge id cannot be resolved, nothing is written and a translated error is shown.

### 5.2 Scenario Builder changes (`modules/scenario_builder_module.R`)

- `apply_scenario_modifications()`:
  - `links_added` entries use `strength` when present; entries without it get `"medium"`;
  - new step: `links_modified` entries set `polarity` and `strength` on the baseline edge with `id == edge_id`; entries whose edge no longer exists are skipped.
- `validate_modifications()`: a translated warning lists `links_modified` entries whose edge no longer exists (warning, not an error).
- The modification-count line and the scenario detail list include modified links, shown as "A → B: weak → strong".
- Nothing else in the builder changes.

## 6. Components

| File | Kind | Change |
|---|---|---|
| `functions/intervention_designer.R` | changed | `reweight` kind, `base_levels`, (d) rule, `ses_edge_dependence()`, `ses_pr_candidates()`, `ses_config_network()`, `ses_config_to_scenario()`; `ses_run_design()` returns `dependence` |
| `functions/intervention_designer_job.R` | changed | `type = "compare"` worker |
| `functions/network_analysis.R` | changed | receives `scenario_loops()` |
| `modules/intervention_designer_module.R` | changed | mode C panel, dependence table, compare panel, Apply modal |
| `modules/scenario_builder_module.R` | changed | `links_modified`, `strength` on `links_added`, counts/details; `scenario_loops()` removed (moved) |
| `translations/modules/intervention_designer.json`, `translations/modules/scenario_builder*.json` | changed | new keys, 9 languages |
| `VERSION`, `VERSION_INFO.json`, `DESCRIPTION`, `CHANGELOG.md` | changed | release 1.28.0 |

## 7. Errors and tests

**Errors** (all user-facing text translated; raw errors only logged):
- stale `reweight` row → Run disabled with reason (§4.2);
- PR failure → panel notice, manual choice still works;
- compare-job crash/timeout → 7a job error path (notification, panel reset);
- Apply id resolution failure → nothing written, error notification.

**Tests** (`tests/testthat/`):
- **Engine, by construction** (`test-intervention-designer-reweight.R`): a small graph where the objective is reached only when A → B is weak:
  - `reweight` level sets keep the sign and respect min/max narrowing;
  - `ses_design_matrix()` rejects `reweight` on an empty cell and still rejects other kinds on existing cells;
  - (d) counts changes from baseline; 7a (d) values unchanged (regression on an existing 7a fixture);
  - `ses_edge_dependence()` marks A → B decisive with needed level weak, other edges not decisive; NULL with no successes;
  - `ses_pr_candidates()` lists each incident link once (self-loop included once) and returns NULL on failure.
- **Tuscany fixture** (extend `test-intervention-designer-d53.R`): mode C on the existing "Boat moorings → P. oceanica" and "Anchoring → P. oceanica" links gives 3^2 = 9 configurations, all sign-preserving; a combined design (self-loop + new node + one re-weight) runs end to end.
- **Arctic smoke**: `SESModels/Arctic DA/Arctic Model edge and node data 20.02.2025V3.xlsx` sheet 1/2 loaded with label cleaning that strips U+00A0 and U+202F (the file uses U+202F), a 3^6-configuration mode-C design on links of "Pelagic fishing" completes with a well-formed result. No D5.3 Arctic numbers asserted: D5.3's run used feedback edges from its Table 6 and the [fast]/[slow] variants, which are not in this file (a 16,384-sample prototype on the file found 0 successes).
- **Scenario** (`test-intervention-designer-apply.R`): `ses_config_to_scenario()` output per §5.1 table (incl. skipping level-0 and unchanged rows, ops records, name de-duplication helper); `apply_scenario_modifications()` applies `links_modified`, skips missing edges, defaults strength; save/load round-trip keeps the scenario.
- **Compare**: `ses_config_network()` polarity/strength/new-node mapping; the compare job on a tiny design returns the three fields; `scenario_loops()` still works from the Scenario Builder after the move (existing tests keep passing).
- **Module** (`test-intervention-designer-module.R`): `testServer()` with the job API faked: PR panel → tick component → re-weight rows → run → dependence table → Apply writes one scenario into `project_data` with `source = "intervention_designer"`.
- **i18n**: `scripts/_i18n_audit.py` reports missing = 0, hardcoded = 0.

## 8. Open items

- Q4 (operations table) stays open; `reweight_edge` is checked against the advisory union like the other operations.
- Reproducing D5.3's Arctic mode-C result needs D5.3 Table 6 edges and the [fast]/[slow] variant definitions from the DA partners.
- Grid phase on very large networks remains unbounded (parked in 7a): mode C makes large grids more common, but sampling keeps them at 65,536 evaluations.
