# WP5 WS-7a: Intervention designer (D5.3 modes A and B) — design

**Status:** design approved in conversation 2026-10-14; this file awaits user review.
**Parent spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-7.
**Sources:** `docs/wp5-source-audit/2026-10-11/C_D5.3_interventions.md` (cited as C§x; D5.3 final report lines as FIN:n).
**Release target:** 1.27.0.

## 1. Purpose and scope

DA teams and WP5 partners use the designer to test interventions on their causal loop diagram the way D5.3 did. They define the new graph structure an intervention introduces, let the tool try every allowed combination of ordinal edge weights, and see which combinations reach the policy objective. Success for this release: the tool reproduces the shape of a D5.3 worked example (Tuscany "additional moorings") and reports the result as D5.3 does, as a share of successful combinations ("x of N").

WS-7 is split into two releases (decision 2026-10-14):

| Release | Contents |
|---|---|
| **7a (this spec)** | Grid engine, D5.3 ranking criteria, Boolean pre-check, mode A (new intervention node), mode B (new edges between existing nodes, incl. the self-loop helper), advisory operations table, evidence-prior default ranges, background-process execution, Designer tab. |
| 7b (later) | Mode C (participation-ratio preselection + re-weighting existing edges), "Apply to project" writing a scenario with an `ops` record and `links_modified` support, before/after loops and leverage panels. |

Out of scope for 7a: anything that writes to project data; mode C; the D5.3 "same-step" option for the new-node delay (C§5.6 item 7) — the limitation is documented in the help text instead; multi-layer (per-country) graphs.

## 2. Decisions taken in brainstorming

1. **Split 7a/7b** as above.
2. **Operations table is advisory.** The user may run any mode. Picking an intervention type shows the operations the D5.3 matrix (`ops_xlsx`) and the EBM framework (`ops_ebm`) list for it, each tagged with its source, under a `provisional` badge, and shows a non-blocking amber note when the design uses an operation neither lists. Partner question Q4 remains open; the table stays replaceable reference data.
3. **The existing page keeps its flow.** `analysis_intervention.R` gets two tabs: "Quick compare" (today's flow, unchanged) and "Designer (D5.3)".
4. **Background execution.** Grids run in a separate R process via `callr::r_bg()`, so the single-process Shiny Server on laguna stays responsive for other users. Benchmarks on the laptop (reference BLAS): a 30-node sparse graph costs ~1-2 ms per configuration, so the 50,176-combination Tuscany grid takes ~1-2 min; synchronous execution would freeze every laguna session for that long.
5. **Reuse the WS-1 operations table.** `data/wp5_intervention_ops.json` (30 interventions, `ops_xlsx`, `ops_ebm`, provisional `ebm_code`) and its loader in `functions/wp5_vocabulary.R` (`load_wp5_intervention_ops()`, `get_intervention_types()`, `get_allowed_graph_ops()`) already exist. No new reference file.

## 3. Core idea: one grid engine for modes A and B

A **design** is a base matrix plus a list of **variable edges**. Each variable edge has a `from`, a `to`, and an allowed **level set**, a subset of `INTERVENTION_GRID_LEVELS = c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)`. Level 0 means the edge is absent.

- **Mode A** (new node, `new_node`): the design adds one intervention node. Its variable edges are the outgoing edges to the nodes it acts on and the incoming edges from its indicator nodes.
- **Mode B** (new edge, `new_edge`): variable edges between existing nodes, including self-loops. A self-loop on a living stock or habitat (D5.3 pre-step, FIN:1079-1085, FIN:1465-1469) is the main use.

A design can combine both, as the Tuscany example does (self-loop + new node). A **configuration** is one choice of level per variable edge. The grid is the Cartesian product of the level sets.

Ordinal labels used in tables: ±1 = strong, ±0.5 = medium, ±0.25 = weak, 0 = none, each with its sign.

## 4. Engine semantics

These rules decide whether results match D5.3. They are normative for the implementation and its tests.

### 4.1 Simulation

- Linear model as in `simulate_dynamics()`: `x[t] = t(A) %*% x[t-1]`, where `A` is the design's matrix for the configuration (base matrix, plus the intervention node as the last row and column in mode A, with the configuration's levels written into the variable-edge cells).
- **Initial state:** one random vector drawn with a fixed seed (`INTERVENTION_DEFAULT_SEED`, recorded in the result), shared by all configurations. The intervention node starts at 0.5, as `ses_compare_interventions()` does.
- **Steps:** `INTERVENTION_N_STEPS = 1000`; **window:** the last `INTERVENTION_WINDOW = 100` steps (FIN:1198).
- **Rescaling:** every 10 steps each configuration's state vector is divided by its L1 norm (skipped when the norm is 0). The model is linear, so this preserves every sign exactly and removes overflow. A configuration that would diverge is judged on its signs, not discarded.

### 4.2 Criteria (FIN:1198, 1515, 1517, 1533)

- **(a) objective:** every objective node is strictly greater than 0 at each of the last 100 steps.
  This deliberately differs from `state_shift_monte_carlo()`, which takes the product of signs over the window (two sign flips pass there).
- **(b) also-sustain:** the same test on the also-sustain nodes. Default: all Goods & Benefits nodes.
- **(c) stable:** all eigenvalues of the Laplacian `L = diag(rowSums(A)) - A` have zero imaginary part (tolerance `1e-9`). New helper `ses_is_stable_attractor()`; the existing `laplacian_eigenvalues()` discards imaginary parts and cannot be reused for this. Computed only for configurations that pass (a), since (c) only orders successes.
- **(d) simplicity:** number of the intervention's own edges at a non-zero level. In a design with a new node these are the variable edges incident to that node; mode-B edges such as a biological self-loop are context, not intervention, and do not count (D5.3 counts intervention edges, FIN:1515, 1533). In a mode-B-only design every variable edge counts.

**Ranking:** by (a) desc, then (b) desc, then (c) desc, then (d) asc; ties keep grid order.

### 4.3 Grid size, cap and sampling

- Grid size `N = prod(lengths(level_sets))`.
- `N <= INTERVENTION_GRID_CAP` (65,536): exhaustive. Configurations are enumerated by index in chunks (mixed-radix decoding), never materialised all at once. The cap is chosen so D5.3's 50,176-combination Tuscany grid (4^5 × 7^2) is evaluated exhaustively and reported as an exact "x of N".
- `N > cap`: a seeded random sample of 65,536 distinct indices, flagged `sampled = TRUE`; the page says the share is an estimate.
- Chunk size: `INTERVENTION_CHUNK = 2048` configurations.

### 4.4 Batched evaluation

`ses_grid_evaluate()` advances all configurations of a chunk together. The fixed part of the matrix is applied as a sparse product (`Matrix` package, already installed); the variable cells are added per configuration as vectorised column operations. Its output must equal a per-configuration loop over `simulate_dynamics()`-style stepping with the same rescaling (equivalence test, §7).

### 4.5 Sign rules and evidence priors

- Per-edge sign rules (e.g. "indicator edges ≤ 0", Arctic AoQ FIN:1179-1196) are expressed as level subsets, never as post-filters.
- **Evidence priors** set default level ranges from the intervention type's EBM code (C§3, `toolbox_extension`, shown with a provenance badge):

| EBM category | Default range |
|---|---|
| 2.x voluntary / information (behavioural) | weak: \|level\| ≤ 0.25 |
| 1.x legal / regulatory; measures `output`, `spatial.*` | medium: \|level\| ≤ 0.5 |
| anything else, or no type | full range |

  Priors apply only to the edges incident to the new intervention node, not to mode-B edges between existing nodes. They only pre-fill the ranges; the user can widen them.

### 4.6 Boolean pre-check (FIN:1756, C§5.2 step 4)

Before the grid runs, `ses_boolean_precheck()` builds the signed matrix with every variable edge at the strongest level of its allowed sign (both signs allowed: the positive extreme) and calls `boolean_model()`.

- If at least one attractor has every objective node ON: "pre-check passed".
- If none does: "topology change needed", with a suggestion to add edges (mode B). The grid still runs if the user chooses.
- The pre-check runs in the worker before the first chunk. Its status is reported through the progress channel at that point and shown above the progress bar while the grid runs, so a user who sees "topology change needed" can Cancel and add edges; otherwise the grid continues.
- Graphs above `DYNAMICS_MAX_BOOLEAN_NODES` (20) are skipped by `boolean_model()`. The page then says "pre-check skipped (N nodes > 20)". The Tuscany network (28 nodes) is in this case.

### 4.7 Outputs

- Success share: "x of N (p%)", marked exhaustive or sampled.
- Counts passing (a), (a and b), (a, b and c).
- Top 20 configurations by rank: one column per variable edge with its ordinal label, plus a, b, c, d.
- For a selected configuration: base vs configuration final (normalised) state, computed with the run's recorded initial state, steps and rescaling (§4.1) by `ses_config_final_state()`, so its signs agree with criteria (a)/(b); plotted like the Quick compare tab. (`ses_compare_interventions()` is not used here: it draws its own initial state, runs 500 unrescaled steps and stops at the divergence cutoff, so its signs can contradict the ranking.)
- Run metadata: seed, steps, window, grid size, sampled flag, elapsed time.

## 5. Components

| File | Kind | Contents |
|---|---|---|
| `functions/intervention_designer.R` | new, pure (no Shiny) | `ses_add_edges()`, `ses_self_loop_candidates()`, `ses_design_matrix()`, `ses_intervention_grid()`, `ses_grid_decode()`, `ses_grid_evaluate()`, `ses_is_stable_attractor()`, `rank_simplest()`, `ses_boolean_precheck()`, `ses_evidence_prior_range()`, `ses_config_final_state()` (comparison plot), `ses_run_design()` (the whole pipeline, called by the worker) |
| `functions/intervention_designer_job.R` | new | `designer_job_start(payload)`, `designer_job_poll(job)`, `designer_job_cancel(job)`; wraps `callr::r_bg()`; progress through a temp file |
| `modules/intervention_designer_module.R` | new sub-module | `intervention_designer_ui(id, i18n)`, `intervention_designer_server(id, project_data_reactive, i18n, event_bus = NULL)` |
| `modules/analysis_intervention.R` | changed | wraps the existing UI in a `tabsetPanel`: "Quick compare" + "Designer (D5.3)"; mounts the sub-module |
| `constants.R` | changed | `INTERVENTION_GRID_LEVELS`, `INTERVENTION_GRID_CAP`, `INTERVENTION_CHUNK`, `INTERVENTION_N_STEPS`, `INTERVENTION_WINDOW`, `INTERVENTION_DEFAULT_SEED`, `INTERVENTION_TOP_K`, `INTERVENTION_JOB_TIMEOUT_S`, `INTERVENTION_EVIDENCE_PRIORS` |
| `global.R` / `app.R` | changed | source the two new functions files in a form `test-functions-sourced-in-app.R` recognises |
| `translations/modules/intervention_designer.json` | new | UI chrome + labels for the 30 intervention types, 9 languages |
| `deployment/required_packages.R`, `DESCRIPTION` | changed | add `callr` (already installed locally and on laguna, 3.7.6) |

**Worker contract.** The payload is a plain list: base matrix (with dimnames), the design (new node name or NULL, variable edges with level sets), objective and also-sustain node names, seed, steps, window, cap, chunk, top-k, and the absolute paths of the two source files. The worker sources `functions/ses_dynamics.R` and `functions/intervention_designer.R` (the payload carries the absolute paths of both) and `library(Matrix)`, runs `ses_run_design()`, and writes progress (`done`, `total`, and the Boolean pre-check status once known) to a temp file: once after the pre-check, then after each chunk and during the stability checks. The result is a plain list (no Shiny objects) that includes the shared initial state `x0`. Worker errors and timeouts come back as an error state with a reason (`engine` / `timeout`); the raw message is only logged.

## 6. Designer tab: user flow and data flow

**Left column, four steps:**

1. **Intervention.** Name; optional type from `get_intervention_types()` grouped by D5.3 group. Picking a type shows `ops_xlsx` and `ops_ebm` with source tags and a `provisional` badge, and pre-fills level ranges from the evidence prior. If the design uses an operation not in the union, an amber note appears; nothing is blocked.
2. **Edges.**
   - "Add intervention node": pick target nodes (outgoing) and indicator nodes (incoming).
   - "Add edge between existing nodes": pick from and to; a "Self-loop" shortcut lists Marine Processes & Functioning nodes.
   - Each variable edge is a table row: from, to, minimum level, maximum level, remove. A per-row "sign rule" shortcut sets the range to ≤ 0 or ≥ 0.
   - New edges between existing nodes are checked with `validate_connection_with_feedback()` (`functions/dapsiwrm_connection_rules.R`). A rule violation shows a translated warning naming the edge (the validator's English message is not shown) and is still allowed.
3. **Objectives.** Objective nodes (required); also-sustain nodes (default all Goods & Benefits).
4. **Run.** A line shows "N combinations — exhaustive" or "N combinations — sampled 65,536". Run is disabled with a reason when the design has no variable edge, an edge that no longer matches the CLD, an empty level range, or no objective.

**Right column:** pre-check result, then a progress bar with Cancel while the job runs, then the outputs of §4.7. Selecting a row of the top-20 table draws its final-state comparison.

**Data flow.** Project CLD → `cld_to_numeric_matrix(nodes, edges)` (label-keyed) → payload → background worker → result list → module `reactiveValues` (session-only). The module polls with `invalidateLater(1000)`. 7a writes nothing to project data. When the ISA changes after a run, the standard `event_bus$on_isa_change()` notice asks for a rerun.

**Limits.** One job per session (Run disabled while a job is active); worker timeout `INTERVENTION_JOB_TIMEOUT_S = 600`; the worker is killed on `session$onSessionEnded`.

## 7. Errors and tests

**Errors.**
- No valid CLD: the existing `setup_cld_gate()` message.
- Worker crash, timeout or error result: a translated notification with the reason (via `format_user_error(..., context_key = ...)`); job state resets.
- Cancel kills the worker and discards partial results.
- Engine logging uses the existing `.dyn_log()`; raw errors are never shown.

**Tests** (`tests/testthat/`):
- `test-intervention-designer.R` (pure): grid size and mixed-radix decoding; chunk enumeration covers every index once; cap triggers sampling with distinct indices; level subsets from sign rules and priors; `ses_add_edges()` incl. self-loops and validator warnings; strict-positivity criterion (a sign-flipping trajectory fails); `ses_is_stable_attractor()` detects complex eigenvalues; `rank_simplest()` order and tie-keeping; pre-check skip above 20 nodes.
- **Equivalence:** `ses_grid_evaluate()` equals a per-configuration reference loop on random small designs (modes A, B and combined).
- **D5.3 fixture:** the Tuscany "additional moorings" structure built from the edges D5.3 describes in text (C§4.3; FIN:1461-1585), with the P. oceanica self-loop. Asserts a non-zero success share with a strong self-loop and a higher share than without the self-loop (D5.3's qualitative finding, FIN:1513-1558). Exact percentages are not asserted: D5.3's "before" graph exists only as a figure, and `data/TuscanySES.xlsx` is a different version (28 nodes, anchoring folded into "Marine traffic (including anchoring)", no Boat moorings → P. oceanica edge).
- **Realistic size:** a run on `data/TuscanySES.xlsx` with a 2,401-configuration design completes and returns well-formed results (no timing assertion).
- `test-intervention-designer-job.R`: start, poll and collect on a tiny design; cancel kills the process; a running poll returns the pre-check status. Boolean pre-check tests that need BoolNet use `skip_if_not_installed("BoolNet")` (CI has no BoolNet; laguna does).
- `test-intervention-designer-module.R`: UI renders and namespaces IDs; `testServer()` behaviour test drives a tiny design to results with the job helpers stubbed (real server re-bound from `.GlobalEnv`, per `CLAUDE.md`). Existing `analysis_intervention` tests keep passing.
- i18n: `scripts/_i18n_audit.py` reports missing = 0, hardcoded = 0.

## 8. Open items carried to 7b or to WP5

- Q4: authoritative operations table, per-DA matrices, definitions of the undefined rows (C§0.3, C§5.6).
- Mode C and "Apply to project" (7b).
- New-node one-step delay (FIN:1273): documented in help; a "same-step" option is a later decision.
- Performance: if laguna users need grids above 65,536 (the cap, chosen so D5.3's 50,176-combination Tuscany grid stays exhaustive), a compiled inner loop (Rcpp) is the next step; not needed for D5.3's published grids.
