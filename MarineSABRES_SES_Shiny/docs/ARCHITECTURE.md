# Architecture Decision Records

MarineSABRES SES Toolbox - Key design decisions for knowledge transfer.

---

## ADR-1: Dual i18n System (Global + Session-Local Translators)

**Context:** shiny.i18n's `Translator` object is mutable. In multi-user deployments on shiny-server, a single global translator would cause language changes by one user to affect all others.

**Decision:** Initialize a global `i18n` translator at startup (in `global.R`) for default English rendering, then clone a session-local translator per user (stored in `session$userData$i18n`). The global object handles static UI; session-local handles reactive language switching.

**Consequences:** Modules must accept `i18n` as a parameter and use the session-scoped instance. Adds slight memory overhead per session but guarantees language isolation. The wrapped translator object (`class = "wrapped_translator"`) provides a uniform `i18n$t()` interface regardless of whether modular or legacy translation mode is active.

---

## ADR-2: Event Bus Pattern for Cross-Module Communication

**Context:** With 25+ Shiny modules that need to react to each other's changes (e.g., ISA edits must trigger CLD rebuild), direct module coupling via `session$sendInputMessage` or returned reactive values creates tight dependencies and makes modules hard to test in isolation.

**Decision:** Implement a pub/sub event bus (`server/event_bus_setup.R`) using `reactiveVal` counters as triggers. Modules emit named events (`emit_isa_change`, `emit_cld_update`) and subscribe via `on_*` accessors. Each session gets its own event bus instance.

**Consequences:** Modules are loosely coupled -- they depend on event names, not on each other. New events can be added without modifying existing modules. The event bus is optional (`event_bus = NULL` is a valid parameter), so modules degrade gracefully in test harnesses.

---

## ADR-3: Debounced Reactive Pipeline with Signature-Based Change Detection

**Context:** The data flow is ISA (element tables) -> CLD (network graph) -> Analysis (loops, metrics). CLD regeneration from ISA is expensive. During rapid editing (adding multiple elements), regenerating after every keystroke wastes compute and causes UI flicker.

**Decision:** Use Shiny's `debounce()` on ISA change events (default 500ms, configurable via `MARINESABRES_ISA_DEBOUNCE_MS` env var). Additionally, compute an xxhash64 digest of ISA data (`create_isa_signature`) and skip CLD regeneration if the signature is unchanged. Analysis results are automatically invalidated when upstream data changes.

**Consequences:** Rapid edits batch into a single CLD rebuild. The signature check prevents no-op rebuilds (e.g., when a project is reloaded with identical data). The pipeline is defined in `functions/reactive_pipeline.R` and wired up via `setup_reactive_pipeline()`.

---

## ADR-4: RDS Project Format for Persistence

**Context:** Projects contain nested R data structures: data frames, lists, adjacency matrices, and metadata. Need a format that preserves R types exactly without lossy conversion.

**Decision:** Use R's native `saveRDS()`/`readRDS()` for project files (`.rds`). Validation checks structure on load via `validate_project_structure()`. A `safe_readRDS()` wrapper enforces a 50MB size limit and type checking.

**Consequences:** Projects are not human-readable or interoperable with non-R tools. This is acceptable because the app also provides Excel/CSV export for data exchange. RDS preserves factors, attributes, and nested lists exactly, avoiding the impedance mismatch of JSON serialization for R objects.

---

## ADR-5: bs4Dash Framework

**Context:** The app needs a dashboard layout with sidebar navigation, tabbed content, cards, modals, and a controlbar. Options considered: shinydashboard (Bootstrap 3, aging), bslib (modern but less opinionated), bs4Dash (Bootstrap 4, AdminLTE3).

**Decision:** Use bs4Dash for the UI framework. It provides `bs4DashPage`, `bs4DashSidebar`, `bs4TabItems`, and card components out of the box with a professional AdminLTE3 theme.

**Consequences:** Locked into Bootstrap 4 (not 5). Some components (e.g., `updateTabItems`) are bs4Dash-specific. The trade-off is worth it for the rich widget library, built-in sidebar/controlbar behavior, and preloader support that would otherwise require custom CSS/JS.

---

## ADR-6: Single reactiveVal for Project Data

**Context:** The project state includes ISA data (7 element categories + adjacency matrices), CLD (nodes/edges), analysis results, metadata, and settings. Could use separate `reactiveVal`s per section or one big nested list.

**Decision:** Use a single `reactiveVal` (`project_data`) holding the entire project as a nested list. Modules read via `project_data()$data$isa_data$drivers` and write by copying, mutating, and setting back: `data <- project_data(); data$field <- new_value; project_data(data)`.

**Consequences:** Any mutation triggers all observers of `project_data`, but the signature-based change detection (ADR-3) prevents unnecessary downstream work. The single-value approach simplifies save/load (just `saveRDS(project_data())`) and makes project state trivially serializable. Accessor helpers in `functions/data_accessors.R` reduce boilerplate for deep nesting.

---

## ADR-7: Optional ML with Graceful Degradation

**Context:** The app offers ML-assisted DAPSIWRM element classification and connection prediction using torch. However, torch is a heavy dependency (~2GB with libtorch) that may not be available on all deployments.

**Decision:** ML is gated by `MARINESABRES_ML_ENABLED` env var and wrapped in `tryCatch`. If torch is unavailable, `ML_AVAILABLE` stays `FALSE` and the app falls back to rule-based classification using keyword matching (`functions/dapsiwrm_type_inference.R`) and connection rules (`functions/dapsiwrm_connection_rules.R`).

**Consequences:** The app works fully without torch installed. ML source files are conditionally loaded (checked with `file.exists()` before `source()`). UI modules check `ML_AVAILABLE` to show/hide ML-specific features. Users get a clear startup message about ML status.

---

## ADR-8: Modular Translation Files (37 JSON Files)

**Context:** The app supports 9 languages with 1000+ translation keys. A single monolithic `translation.json` was hard to maintain -- merge conflicts were frequent, and finding the right key was slow.

**Decision:** Split translations into `translations/common/` (shared: buttons, labels, messages) and `translations/modules/` (module-specific keys). A `translation_loader.R` merges them at startup into `_merged_translations.json` which shiny.i18n consumes. Keys use dot-namespacing (e.g., `ui.sidebar.home`, `modules.isa.add_element`).

**Consequences:** Developers edit small, focused files. Adding a new module's translations does not touch shared files. The merge step adds ~200ms to startup. The `_merged_translations.json` file is auto-generated and should not be edited directly.

---

## ADR-9: Session Isolation via Per-Session Temp Directories

**Context:** On shiny-server, multiple users share a single R process. Temp files (auto-saves, exports, intermediate computation artifacts) must not leak between sessions.

**Decision:** Each session gets a unique directory under `tempdir()/marinesabres_sessions/{session_id}` created by `init_session_isolation()`. Session IDs are SHA-256 hashes of timestamp + random bytes + PID. Cleanup is automatic via `session$onSessionEnded()`.

**Consequences:** All temp file operations must use `get_session_temp_file()` instead of bare `tempfile()`. The `0700` directory permissions prevent cross-session file access. Session diagnostics (`get_session_diagnostics()`) provide debugging info for multi-user issues.

---

## ADR-10: DAPSIWRM as Domain Model

**Context:** The app models Social-Ecological Systems for marine environments. Multiple SES frameworks exist (DPSIR, DPSER, Ostrom's SES). The EU Marine-SABRES project specifically requires DAPSI(W)R(M), an extension of DPSIR developed for marine management by Elliott et al.

**Decision:** Hard-code the 7 DAPSIWRM element categories (Drivers, Activities, Pressures, Marine Processes & Functioning, Ecosystem Services, Goods & Benefits, Responses) as the core domain model in `constants.R`. All ISA data structures, templates, and analyses are organized around these categories.

**Consequences:** The app is purpose-built for DAPSIWRM and cannot easily support alternative SES frameworks. This is intentional -- the Marine-SABRES project requires this specific framework. Element colors, shapes, and ID prefixes are all tied to these 7 categories. The `DAPSIWRM_FRAMEWORK_RULES.md` documents valid connection types between categories.

---

## ADR-11: Stable Categorical Keys for Localized selectInputs

**Context:** Modules with `selectInput(choices = c("", i18n$t("modules.x.high"), i18n$t("modules.x.medium"), ...))` store the *translated* label as the input value. Code that compares those values against English literals (`df$Power == "High"`) then silently mis-classifies records in any non-English session. PIMS Power-Interest grids reversed quadrant counts; response-measure priority scoring inverted rankings; both failed silently.

**Decision:** Where a `selectInput` value is used in logic (comparisons, scoring, filtering), wrap choices with `setNames(c("", "HIGH", "MEDIUM", "LOW"), c("", i18n$t("modules.x.high"), i18n$t("modules.x.medium"), i18n$t("modules.x.low")))`. The names become the display labels (locale-dependent); the values become stable categorical keys (locale-independent). Logic compares against stable keys; display code translates via small `level_label(key)` helpers at the boundary.

**Consequences:** Internal state is locale-independent — a session that started in Spanish and switched to French keeps comparing values correctly. Excel/Word/CSV exports translate at the export boundary via a small `translate_levels_for_export(df)` helper so users still see localized labels in downloads. The pattern is now applied in `pims_stakeholder_module.R` (Power/Interest) and `response_module.R` (Effectiveness/Feasibility); a codebase-wide grep for `== "(High|Medium|Low|Strong|Weak|Moderate)"` confirms no remaining offenders.

---

## ADR-12: Module Data Persistence via `project_id`-Keyed Load Observer

**Context:** Several Shiny modules (initially `pims_stakeholder_module.R` and `response_module.R`) accept `project_data_reactive` as a parameter but operate on module-local `reactiveValues`, never reading from or writing to the canonical project store. Data vanishes on session restart and is missing from project save files. A naive bidirectional `observe()` causes a feedback loop (save → project_data changes → load fires → writes module state → triggers save).

**Decision:** Each persisting module exposes a `sync_to_project_data()` helper called explicitly after every mutation, and a load observer keyed on `project_id`:

```r
observeEvent(project_data_reactive()$project_id, {
  # populate module state from project_data
}, ignoreNULL = FALSE)
```

`project_id` only changes when a different project is loaded; same-project saves preserve it, so loads don't re-fire on the module's own writes. Mutations call the explicit `sync_to_project_data()`; no implicit observer chain.

**Consequences:** The pattern is a copy-paste template for new modules with their own reactiveValues that need persistence. The trade-off vs. making `project_data` the only source of truth is that each module keeps a local copy — divergence is possible if a third party mutates `project_data` outside the LOAD path. Acceptable because no other code path mutates a module's slot. Validated by `test-pims-module.R` (47/47) and `test-response-module.R` (8/8) after the migration.

---

## ADR-13: `isolate()` All Event-Bus `emit_*` Bodies

**Context:** Event-bus emitters in `server/event_bus_setup.R` compute their increment via `current <- triggers$X(); triggers$X(current + 1)`. Reading a `reactiveVal` registers a dependency on the current reactive context. Two problems followed: (1) the test suite couldn't call `bus$emit_isa_change()` from top-level code without raising "Operation not allowed without an active reactive context", and (2) any observer that emitted an event registered itself as a dependent of the event it just fired, risking self-firing loops if the observer body did anything else reactive.

**Decision:** Wrap each `emit_*` function body in `shiny::isolate({...})`. Emit functions write events; they should not be reactive consumers, ever.

**Consequences:** Tests can construct an event bus and exercise emit/get patterns directly with `shiny::isolate()` only on the *read-side* getters (which need to register dependencies in production). Production observers no longer depend on the events they emit. The fix turned 10 long-standing test errors green in one commit. Applied to all 8 `emit_*` functions: `emit_isa_change`, `emit_cld_update`, `emit_analysis_request`, `emit_template_loaded`, `emit_project_saved`, `emit_project_loaded`, `emit_navigation_request`, `emit_language_changed`.

---

## ADR-14: GraphSAGE Encoder for Connection Prediction (v1.15.0)

**Context:** The v1.14.0 base predictor scores a candidate connection from a 358-dim feature vector that captures element-name embeddings, DAPSI(W)R(M) type one-hots, and per-template priors — but treats the user's in-progress SES graph as a *bag of features*, not as a graph. The original ESP 2026 abstract claimed "graph neural networks for model completion"; the v1.14.0 release fell short of that by using hand-engineered scalar graph features (centrality, shortest-path, framework-compliance flag) rather than learned message passing.

**Decision:** Add a 2-layer GraphSAGE encoder (`functions/ml_models.R::graph_sage_encoder`) that produces 32-dim node embeddings from a 135-dim per-node input (7-dim DAPSI(W)R(M) one-hot + 128-dim sentence-transformer text embedding). The companion `connection_predictor_gnn` wraps the encoder with multi-task heads that consume the pair representation `[h_source; h_target; h_source ⊙ h_target]`. GraphSAGE was chosen over vanilla GCN because (a) inference graphs are dynamic — the user's partial model is what we feed in, not a fixed adjacency — and (b) the mean aggregator + neighbour-sampling pattern handles small graphs (typical template has 25-30 nodes) more gracefully than spectral GCN normalization.

**Training:** Within-template hold-out (20% of positives masked per epoch), existence-only binary cross-entropy loss (the multi-task variant degraded ranking; see ADR-15), Adam lr=5e-4, dropout 0.3, edge dropout 0.1, patience-20 early stopping. Trained on all 7 production templates simultaneously.

**Consequences:** Retrospective comparison vs. v1.14.0 base shows the GNN wins at top-of-rank (precision@5 0.086 vs base 0.057, +51%; recall@10 0.100 vs 0.081, +23%) and ties or slightly loses past top-10. Real-user impact is small in absolute terms but consistent: when users look at the FIRST few suggestions (which is what the UI surfaces), the GNN is meaningfully better. Both checkpoints are kept; `retrospective_validation_gnn.R` documents the side-by-side numbers.

---

## ADR-15: Existence-Only Loss for the GraphSAGE Predictor

**Context:** The v1.14.0 multi-task loss combines four heads — existence (BCE, weight 0.4), strength (CE, 0.3), confidence (MSE, 0.2), polarity (BCE, 0.1). When the GraphSAGE-augmented architecture was trained with the same weighted loss, validation loss plateaued at ~1.6 and retrospective precision@10 was *worse* than the base classifier (0.029 vs 0.057). Inspection showed the strength/confidence/polarity heads were dominating gradient updates because the existence head's loss surface was already shallow, and the small per-template sample sizes meant the auxiliary tasks were memorizing noise.

**Decision:** When training the GNN predictor (only — the v1.14.0 base keeps its multi-task loss), use binary cross-entropy on the existence head alone (`CONFIG$existence_only = TRUE` in `scripts/train_connection_predictor_gnn.R`).

**Consequences:** Val loss drops to 0.63 with no overfitting (train 0.68). Precision@5 lifts to 0.086 (+51% over base). The strength/confidence/polarity heads still exist in the architecture (so the model object loads against `connection_predictor_gnn` cleanly) and are still functional at inference time — they're just trained passively from the existence-head gradients via the shared backbone. Hard lesson on small-data multi-task learning: more output heads ≠ more learning. The base v1.14.0 had enough data to support the auxiliary tasks; the GraphSAGE variant with its tighter parameter budget did not.

---

## ADR-16: In Silico Validation as a Pilot Proxy

**Context:** The original ESP 2026 abstract claims "23% more relevant connections" and "64% greater consistency across users" — numbers that can only be measured with a human-subject pilot. The pilot is designed (`docs/ml_pilot_protocol.md`) but takes ~8 weeks calendar including ethics clearance and recruitment. The submission needed defensible numbers before that timeline.

**Decision:** Build three computational analyses that use only the existing KB data to produce numbers in the same units the pilot would produce, with explicit caveats about what they do and do not measure:

1. **Connection-recovery lift** (`scripts/simulate_non_expert_users.R`): simulate users who start with a random 30% subset of true positives and add 10 more via either uniform-random sampling within the DAPSI(W)R(M)-valid pool or top-ML-score. Replaces the "23% more connections" claim with a measured +100% median relative lift.
2. **Cross-user consistency lift** (`scripts/cross_template_consistency.R`): 5 simulated users per template, mean pairwise Jaccard of final models. Replaces the "64% greater consistency" claim with a measured +396% median relative lift, plus an honest caveat that deterministic ML scoring contributes a substantial share of the lift.
3. **Bibliometric calibration** (`scripts/bibliometric_validation.R`): Spearman correlation between ML existence probability and KB reference counts (and consortium expert confidence). Provides a "the model agrees with the literature" signal independent of either user-substitute simulation.

All three feed into `docs/IN_SILICO_VALIDATION.md` and the ESP 2026 v3 abstract (`MARBEFES/ESP2026/abstract_Razinkovas_et_al_v3.docx`).

**Consequences:** The submission can be made with measured numbers immediately. The pilot remains in the protocol queue but is no longer blocking. When the pilot eventually completes, its real-user numbers replace the in silico ones in any subsequent paper. The honest framing — "in silico simulation shows X; pilot in preparation to measure real-user gain" — is more defensible at the podium than either pure simulation or unsourced claims would be.

---

## ADR-17: Hashed Participant IDs at the Toolbox Boundary (Pilot Study)

**Context:** The pilot study captures session-level measurements (timing, NASA-TLX, model snapshots) per participant. To run paired statistics across the two sessions per participant, every session needs to be linked to the same participant. To honour the consent form's "no PII captured" promise, the participant identifier on disk must not be a re-identifiable string.

**Decision:** The participant ID enters the system via a URL parameter (`?pid=P01`) along with the condition (`?pilot_condition=A|B`). The `modules/pilot_study_module.R` module immediately hashes the raw `pid` with SHA-256 and truncates to the first 12 characters. Only the hashed value is written to disk (`data/pilot/<hashed_pid>__<condition>__<iso>.json`). The mapping from raw `pid` to hash is reconstructable (SHA-256 is deterministic) but is never persisted by the toolbox; the PI keeps the mapping in a separate password-protected spreadsheet that is destroyed after analysis.

**Consequences:** Statistical pairing works (same raw `pid` → same hash → joined across two sessions). PII never lands in the repository. A reviewer can audit `data/pilot/` and see only opaque 12-character IDs. Even if the pilot raw data were accidentally pushed to git (it shouldn't be — the `.gitignore` excludes it), participants are not identifiable from the files alone. The 12-character truncation is fine for the expected N = 8-12 (collision probability negligible) and keeps file names short.
