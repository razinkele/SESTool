# Evidenced Polarity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A connection's sign is filled in only from evidence; everywhere else the user must pick + or − before the connection is accepted (SES Toolbox v1.36.0).

**Architecture:** One evidence lookup (`evidenced_polarity()`) and one sign picker (`polarity_picker_input()` / `read_polarity_pick()`) are shared by every entry point. Pending suggestions may carry `polarity = NA_character_`; persistence refuses NA, so saved data stays `+`/`-` only. Standard Entry and LinkedX-only recovery collect "unsigned links" and resolve them through one shared sign-choice dialog module.

**Tech Stack:** R ≥ 4.4.1, Shiny, bs4Dash, shinyWidgets, shiny.i18n (9 languages), testthat.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-11-17-evidenced-polarity-design.md` (read it first; this plan argues from it).

## Global Constraints

- Work in worktree `C:\Users\arturas.baziukas\AppData\Local\sestool-rules` on a new branch `feat/evidenced-polarity` cut from `docs/rules-v1.2-gemma`; app root is `MarineSABRES_SES_Shiny/`. Run every command from the app root.
- Git: `git -C <path> ...`, never `cd <path> && git ...` (R project CLAUDE.md). Conventional commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Tests: `Rscript -e "testthat::test_file('tests/testthat/<file>.R')"`; full suite `Rscript -e "testthat::test_dir('tests/testthat')"`. New tests that target files outside global.R's chain use `source_for_test()`; behaviour tests re-bind the real server from `.GlobalEnv` before `testServer()` (R CLAUDE.md, Testing). Never end a behaviour test in `expect_true(TRUE)`.
- Every new user-facing string: an i18n key in `translations/common/*.json` (or the module's file) with all 9 languages (`en es fr de lt pt it no el`); `micromamba run -n shiny python scripts/_i18n_audit.py` must report missing=0, hardcoded=0.
- Saved data never holds a missing sign: no `NA`, `""` or invented `+` in `project_data$isa_data` connections, adjacency-matrix cells or CLD edges.
- Evidence is exactly: exact KB match with a non-empty `source` (shown as "from: <citation>"), a shipped-template sign, a `+`/`-` in an imported file, or an earlier user choice. Never evidence: synonym KB matches, keyword heuristics, rule-table defaults, ML predictions, loop-opportunity guesses.
- No "typical sign" hint anywhere.
- Leave alone: `functions/scenario_network.R`, `functions/ses_dynamics.R`, `functions/intervention_designer.R`, `convert_matrices_to_connections()` (AI-session recovery; keep its `+` fallback but add a `debug_log` line).

## Review Focus

1. Saving Standard Entry twice with no new ticks must not open the sign dialog (existing cells are signed) — Task 6.
2. Swapping the direction of a KB-signed suggestion: the evidence was for the other direction, so the sign becomes unset unless the user had chosen it — Task 4.
3. Flipping a KB-filled sign: the "from:" line disappears and the flipped sign is what gets saved — Task 4.
4. "Approve all" in a batch where every suggestion is unsigned approves nothing and shows the count message — Task 4.
5. Cancel in the sign dialog, then Save again: no dialog, and the unticked links stay out — Task 6.

---

### Task 1: Evidence lookup and the shared sign picker

**Files:**
- Create: `functions/polarity_evidence.R` (source it in `global.R` right after `data/ses_connection_knowledge_base.R` is sourced)
- Modify: `functions/ui_components.R`, `translations/common/labels.json` (or the best-fitting common file)
- Test: `tests/testthat/test-polarity-evidence.R`

**Interfaces:**
- Produces:
  - `evidenced_polarity(from_name, from_type, to_name, to_type) -> list(polarity = "+"|"-"|NA_character_, source = character(1)|NA_character_)` — calls `lookup_knowledge_base()`; returns its sign only when `match_quality == "exact"` and `source` is non-empty, else `list(polarity = NA_character_, source = NA_character_)`. Guard with `exists("lookup_knowledge_base", mode = "function")`.
  - `polarity_picker_input(inputId, i18n, selected = NA_character_, evidence_source = NA_character_) -> shiny.tag` — two buttons Reinforcing (+) / Opposing (−) (labels `common.choices.polarity_reinforcing` / `_opposing`), nothing selected when `selected` is NA, a "Choose a sign" prompt while unset, and a "from: <evidence_source>" line when `evidence_source` is given. Widget choice is yours (shinyWidgets radio group or select with empty choice), but unset must be a real, visible state.
  - `read_polarity_pick(x) -> "+"|"-"|NA_character_` — maps the picker's input value (NULL, `character(0)`, `""`, `"+"`, `"-"`) to a sign.
  - i18n keys (all 9 languages): `common.polarity.choose_sign` = "Choose a sign"; `common.polarity.from_source` = "from:"; `common.polarity.approve_blocked` = "Choose + or − before approving this connection."; `common.polarity.needs_sign_count` = "%d connections need a sign before they can be approved."; `common.polarity.sign_dialog_title` = "Choose the sign for new connections"; `common.polarity.direct_import_blocked` = "%d connections in the file have no sign. Use Review to choose them."

- [ ] **Step 1: Write the failing tests**

```r
test_that("exact KB match with a source is evidence", {
  local_mocked_bindings(lookup_knowledge_base = function(...) list(
    polarity = "-", match_quality = "exact", source = "Smith 2020"), .env = globalenv())
  expect_equal(evidenced_polarity("Trawling", "Activities", "Seabed", "Pressures"),
               list(polarity = "-", source = "Smith 2020"))
})
test_that("synonym match, missing source and no match are not evidence", {
  for (kb in list(list(polarity = "+", match_quality = "synonym", source = "X"),
                  list(polarity = "+", match_quality = "exact", source = ""),
                  NULL)) {
    local_mocked_bindings(lookup_knowledge_base = function(...) kb, .env = globalenv())
    expect_identical(evidenced_polarity("a", "Drivers", "b", "Activities")$polarity, NA_character_)
  }
})
test_that("read_polarity_pick maps every unset form to NA", {
  for (x in list(NULL, character(0), "", NA)) expect_identical(read_polarity_pick(x), NA_character_)
  expect_identical(read_polarity_pick("+"), "+"); expect_identical(read_polarity_pick("-"), "-")
})
test_that("picker renders unset with prompt, and a from: line only with evidence", {
  i18n <- make_test_i18n()   # use the suite's existing i18n test helper; create one in a helper file if none exists
  html <- as.character(polarity_picker_input("p", i18n))
  expect_match(html, "Choose a sign"); expect_false(grepl("from:", html))
  html2 <- as.character(polarity_picker_input("p", i18n, selected = "-", evidence_source = "Smith 2020"))
  expect_match(html2, "Smith 2020")
})
```

(If `local_mocked_bindings` cannot target a global function in this suite, stub `lookup_knowledge_base` by assignment inside `withr::defer`-restored scope; the assertions stay.)

- [ ] **Step 2: Run, expect FAIL** (`could not find function "evidenced_polarity"`): `Rscript -e "testthat::test_file('tests/testthat/test-polarity-evidence.R')"`
- [ ] **Step 3: Implement** the three functions, the `global.R` source line and the six i18n keys.
- [ ] **Step 4: Run, expect PASS**; run the i18n audit, expect missing=0, hardcoded=0.
- [ ] **Step 5: Commit** `feat(polarity): evidence lookup and shared sign picker`

### Task 2: Persistence refuses a missing sign

**Files:**
- Modify: `modules/ai_isa/data_persistence.R` (`build_adjacency_matrices`, cell write ~L331-338), `functions/cld_interaction_helpers.R` (`sync_cld_to_isa_data`, `norm_pol` ~L802-810)
- Test: `tests/testthat/test-polarity-persistence.R`

**Interfaces:**
- Produces: both writers skip any connection/edge whose polarity is not `"+"`/`"-"` and `debug_log(..., "ERROR")` it; neither writes `"NA..."` nor turns NA into `"+"`. Also add a `debug_log(..., "WARN")` where `convert_matrices_to_connections()` (`modules/ai_isa/connection_generator.R` ~L660) falls back to `"+"` for a cell without a sign (behaviour unchanged).

- [ ] **Step 1: Failing tests**

```r
test_that("matrix builder skips a connection with NA polarity", {
  # build elements + two suggested connections (one "+", one NA) in the shape
  # build_adjacency_matrices() already takes in test-ai-isa-*.R fixtures
  am <- build_adjacency_matrices(elements, suggested, approved = 1:2)
  cells <- unlist(lapply(am, function(m) m[nzchar(m)]))
  expect_false(any(startsWith(cells, "NA")))
  expect_length(cells, 1)
})
test_that("CLD sync drops an edge without a sign instead of inventing +", {
  pd <- cld_fixture_with_edges(polarity = c("+", NA))   # build from test-cld-sync-fidelity.R fixtures
  out <- sync_cld_to_isa_data(pd)
  expect_equal(count_matrix_edges(out$data$isa_data$adjacency_matrices), 1)
})
```

(Reuse fixture builders from `test-cld-sync-fidelity.R` / the AI-ISA persistence tests; write small local helpers if none fit.)

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS**, plus `test-cld-sync-fidelity.R` and `test-json-matrix-roundtrip.R` still pass.
- [ ] **Step 5: Commit** `fix(polarity): persistence refuses a missing sign`

### Task 3: AI suggestions and ML carry only evidenced signs

**Files:**
- Modify: `modules/ai_isa/connection_generator.R` (`detect_polarity` L62-187, `generate_smart_connections` ~L465-528, KB seeding ~L903), `modules/ai_isa/action_handlers.R` (L71, L288), `modules/template_ses_module.R` (L740, L941), `functions/visnetwork_helpers.R` (L1213), `functions/ml_inference.R` (L442, L1006, L1010), `functions/ml_ensemble.R` (L470)
- Test: `tests/testthat/test-polarity-ai-suggestions.R`; update existing AI-ISA tests that assert heuristic signs

**Interfaces:**
- Consumes: `evidenced_polarity()` (Task 1).
- Produces:
  - `detect_polarity(from_name, to_name, from_type, to_type) -> "+"|"-"|NA_character_`: returns `evidenced_polarity(...)$polarity`. Remove the phrase-analysis and type-rule layers and the final `"+"` (delete `.analyze_polarity_phrase` if nothing else uses it).
  - Every suggestion from `generate_smart_connections()` carries `polarity` (sign or NA) and `polarity_source` (citation or NA). Scoring and confidence (4 exact / 3 synonym) unchanged.
  - Rationale text uses a neutral verb (existing key for "affects" if present, else add `common.polarity.affects`) when polarity is NA.
  - ML results: `polarity = NA_character_`, the thresholded sign moved to `predicted_polarity` (kept for logging only).
  - KB seeding branch (~L903): `kb_conn$polarity` only when the match is exact and sourced, else NA (no `%||% "+"`).
  - The `if (polarity == "+")` sites listed above handle NA without error (NA renders as unset/neutral).

- [ ] **Step 1: Failing tests**

```r
test_that("detect_polarity returns NA without exact KB evidence", {
  stub_kb(NULL)   # local helper wrapping the Task 1 stubbing approach
  expect_identical(detect_polarity("Pollution reduction", "Water quality", "responses", "pressures"), NA_character_)
})
test_that("generated suggestion keeps KB sign and source on exact match", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020", strength = "strong"))
  s <- generate_smart_connections(two_element_fixture)[[1]]
  expect_equal(s$polarity, "-"); expect_equal(s$polarity_source, "Smith 2020"); expect_equal(s$confidence, 4)
})
test_that("synonym match scores but leaves the sign unset", {
  stub_kb(list(polarity = "+", match_quality = "synonym", source = "X", strength = "medium"))
  s <- generate_smart_connections(two_element_fixture)[[1]]
  expect_identical(s$polarity, NA_character_); expect_equal(s$confidence, 3)
})
test_that("ML result has no polarity, only predicted_polarity", {
  r <- ml_result_fixture()   # call the ensemble/inference result builder with a fixed probability 0.9
  expect_identical(r$polarity, NA_character_); expect_equal(r$predicted_polarity, "+")
})
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS**; update and rerun the existing generator/ML tests.
- [ ] **Step 5: Commit** `feat(polarity): AI and ML suggestions carry only evidenced signs`

### Task 4: Review cards require a sign

**Files:**
- Modify: `modules/connection_review_tabbed.R` (card ~L1195-1260, approve ~L1068-1090, batch approve-all ~L866-885, swap handler), `modules/ai_isa_assistant_module.R` (`approve_all_connections` ~L923)
- Test: `tests/testthat/test-connection-review-polarity.R`; update `test-connection-review.R`, `test-connection-review-rerender.R`

**Interfaces:**
- Consumes: `polarity_picker_input()`, `read_polarity_pick()` (Task 1); suggestions' `polarity` / `polarity_source` (Task 3).
- Produces:
  - Card sign control: `polarity_picker_input(ns(paste0("polarity_pick_", idx)), i18n, selected = <amended or conn$polarity>, evidence_source = <conn$polarity_source unless amended>)`. Replace `polarity_switch_<idx>` everywhere (observers, polarity text output). Current sign = amended sign if set, else `conn$polarity` (may be NA) — no `%|||% "+"`.
  - Approve-one: if `read_polarity_pick()` is NA, show `common.polarity.approve_blocked`, leave the card unapproved, call no `on_approve`.
  - Approve-all (per batch and global): approve only indices whose current sign is set; if any were skipped, show `sprintf(i18n$t("common.polarity.needs_sign_count"), n_skipped)`; zero signed → approve nothing.
  - Swap direction: if the current sign came from evidence (not amended by the user), clear it to NA and drop the "from:" line; a user-chosen sign survives the swap.
  - Changing the sign stores it in `rv$amended_data[[idx]]$polarity` and hides the "from:" line.

- [ ] **Step 1: Failing tests** (`testServer()` on `connection_review_tabbed_server`, real server re-bound from `.GlobalEnv`)

```r
test_that("approve is blocked while the sign is unset", {
  conns <- reactiveVal(list(conn(polarity = NA_character_)))
  testServer(connection_review_tabbed_server, args = list(connections_reactive = conns, i18n = i18n), {
    session$setInputs(approve_1 = 1)
    expect_false(1 %in% rv$approved)
    session$setInputs(polarity_pick_1 = "-", approve_1 = 2)
    expect_true(1 %in% rv$approved)
  })
})
test_that("approve all skips unsigned and approves nothing when none are signed", {
  # batch with suggestions c(NA, "+", NA): approve_all -> rv$approved == the "+" index only
  # batch with c(NA, NA): approve_all -> length(rv$approved) == 0
})
test_that("swap clears an evidenced sign but keeps a user-chosen one", {
  # conn(polarity = "-", polarity_source = "Smith 2020"): swap -> current sign NA
  # after setInputs(polarity_pick_1 = "+"): swap -> sign stays "+"
})
test_that("flipping an evidenced sign is what gets approved", {
  # conn(polarity = "-", polarity_source = "S"); set polarity_pick_1 = "+", approve -> on_approve gets polarity "+"
})
```

(Write each commented case as real `expect_*` assertions in the same style as the first test.)

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS** with the updated review tests.
- [ ] **Step 5: Commit** `feat(polarity): review cards require a sign`

### Task 5: Excel/Kumu import keeps file signs and asks for the rest

**Files:**
- Modify: `functions/excel_import_helpers.R` (~L431-438 and wherever the cell is written), `modules/import_data_module.R` (review wiring ~L385-433, finalize ~L442, direct import ~L511, review display ~L718)
- Test: `tests/testthat/test-polarity-import.R`; update `test-excel-import-helpers.R`, `test-import-data-se-format.R`

**Interfaces:**
- Consumes: Task 4 review behaviour.
- Produces:
  - `import_label_polarity(label) -> "+"|"-"|NA_character_` in `excel_import_helpers.R`: first non-space character `+` or `-` gives the sign; anything else (NA, `""`, `"medium:3"`, `"x"`, `"1"`, `"negative"`) gives NA.
  - `convert_excel_to_isa()` writes no cell for an NA-sign connection; it returns those connections as `unsigned` (data.frame From, To) alongside its current result.
  - Import review: suggestions carry `polarity = import_label_polarity(Label)`; `connection_review_tabbed_server(..., on_amend = <fn>)` is wired, and finalize applies amended signs (writes `+`/`-` back into `rv$connections_data$Label` for those rows) before converting. Finalize with an unsigned approved row is impossible (Task 4 blocks it).
  - Direct import: if any row's `import_label_polarity()` is NA, block with `sprintf(i18n$t("common.polarity.direct_import_blocked"), n)` and do not import.

- [ ] **Step 1: Failing tests**

```r
test_that("import_label_polarity reads only a leading sign", {
  expect_equal(import_label_polarity(c("+", "-strong", " -", "+medium:3")), c("+", "-", "-", "+"))
  expect_identical(import_label_polarity(c(NA, "", "medium:3", "x", "1", "negative")), rep(NA_character_, 6))
})
test_that("conversion writes no cell for an unsigned row and reports it", {
  res <- convert_excel_to_isa(elements_fx, data.frame(From = c("A","B"), To = c("B","C"), Label = c("+", "")))
  expect_equal(nrow(res$unsigned), 1)
  # and exactly one non-empty cell across res's adjacency matrices
})
test_that("a sign amended in the import review survives finalize", {
  # testServer(import_data_module server): load fixture with Label "" , set the review pick to "-",
  # approve, finalize -> resulting matrix cell starts with "-"
})
test_that("direct import is blocked when a row has no sign", {
  # testServer: fixture with one unsigned row, click direct import -> project data unchanged
})
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS** with the updated import tests.
- [ ] **Step 5: Commit** `feat(polarity): import keeps file signs, asks for the rest; keep review amendments`

### Task 6: Matrix rebuild takes chosen signs; Standard Entry and recovery ask for them

**Files:**
- Create: `modules/sign_choice_module.R` (source it in `global.R` with the other shared modules)
- Modify: `functions/matrix_from_linked.R` (`rebuild_matrix_from_linked` L87, `rebuild_forward_matrix_by_name` L294), `functions/isa_form_builders.R` (`build_response_matrices` L703-745), `functions/standard_entry_excel_import.R` (L180-230), `functions/dapsiwrm_connection_rules.R` (delete `get_rule_default_polarity` L379-394, `DAPSIWRM_MATRIX_KEY_TYPES` only if nothing else uses it, `default_polarity_for_matrix` L421-425), `modules/isa_data_entry_module.R` (`rebuild_transition` L318, the five call sites L1467-1629, response save ~L1689, load/recovery ~L396, loop builder `loop_effect` L1739), `modules/import_data_module.R` (~L266 recovery), `tests/testthat/helper-stubs.R`
- Test: `tests/testthat/test-polarity-standard-entry.R`; update `test-matrix-from-linked.R`, `test-linked-by-name.R`, `test-dapsiwrm-connection-rules.R`, `test-isa-responses-*.R`, `test-standard-entry-excel-import.R`, `test-recover-isa-data.R`

**Interfaces:**
- Consumes: `polarity_picker_input()`, `read_polarity_pick()` (Task 1).
- Produces:
  - Unsigned-link record (data.frame, one row per link): `matrix_key` (chr), `src_id`, `tgt_id` (ids in rebuild orientation: src owns the LinkedX column), `linked_col` (chr), `suffix` (chr, e.g. `"medium:3"`), `transposed` (lgl; TRUE for `gb_r`).
  - `rebuild_matrix_from_linked(element_df, linked_col, source_ids, target_ids, element_confidence_col = "Confidence", existing_matrix = NULL, user_edited_matrix = NULL, chosen_signs = character(0), default_strength = "medium", default_confidence = "3")` — `default_polarity` removed. `chosen_signs` is a named chr vector, names `"<src_id>|<tgt_id>"`, values `"+"`/`"-"`. A NEW declared cell is written only when its key is in `chosen_signs`; otherwise it is left empty and returned in a new list element `unsigned_links` (records above with `matrix_key = NA`, filled by the caller). Existing cells keep their sign exactly as today.
  - `rebuild_forward_matrix_by_name(source_df, linked_col, target_df, element_confidence_col = "Confidence", chosen_signs = character(0), default_strength = "medium", default_confidence = "3")` — same rule; returns the matrix with `attr(, "unsigned_links")`.
  - `build_response_matrices(isa)` returns `list(adjacency_matrices, user_edited_matrices, unsigned_links)` (records carry `matrix_key`; `gb_r` rows have `transposed = TRUE`).
  - `recover_isa_data(...)` result gains `unsigned_links`.
  - `apply_chosen_signs(adjacency_matrices, links, signs) -> adjacency_matrices`: writes `paste0(sign, suffix)` at `[src_id, tgt_id]` (or `[tgt_id, src_id]` when `transposed`). Put it in `matrix_from_linked.R`.
  - `untick_linked(element_df, src_id, linked_col, tgt_id) -> element_df`: removes `tgt_id` from that row's LinkedX value (use `parse_linked()`/`serialize_linked()`).
  - `sign_choice_server(id, i18n) -> list(open = function(links, labels, on_done))` and its modal: a `modalDialog` titled `common.polarity.sign_dialog_title`, one row per link "<from label> → <to label>" with `polarity_picker_input(ns(paste0("sign_", k)), i18n)`; Confirm enabled only when every row is signed; `on_done(signs)` with `signs` named `"<src>|<tgt>"`, or `on_done(NULL)` on Cancel. `labels` maps ids to element names for display.
  - Standard Entry: `rebuild_transition()` and the response save collect `unsigned_links`; when non-empty after a save, open the dialog. Confirm → `apply_chosen_signs()` then `sync_to_project_data()`. Cancel → `untick_linked()` for each link on `isa_data[[<element type>]]`, then `sync_to_project_data()` (everything else is already saved).
  - Load/recovery (`isa_data_entry_module.R` ~L396 and `import_data_module.R` ~L266): after `recover_isa_data()`, if `unsigned_links` is non-empty, open the same dialog with the same Confirm/Cancel behaviour.
  - `loop_effect` select starts with an empty choice and the add-loop handler requires a chosen value.

- [ ] **Step 1: Failing tests**

```r
test_that("a new declared cell is written only with a chosen sign", {
  df <- data.frame(ID = "D1", LinkedA = "A1;A2", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"), chosen_signs = c("D1|A1" = "-"))
  expect_equal(r$matrix["D1", "A1"], "-medium:3")
  expect_equal(r$matrix["D1", "A2"], "")
  expect_equal(r$unsigned_links[, c("src_id", "tgt_id")], data.frame(src_id = "D1", tgt_id = "A2"))
})
test_that("existing cells keep their sign and are never reported unsigned", {
  ex <- matrix(c("-strong:4", ""), 1, dimnames = list("D1", c("A1", "A2")))
  df <- data.frame(ID = "D1", LinkedA = "A1", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"), existing_matrix = ex)
  expect_equal(substr(r$matrix["D1", "A1"], 1, 1), "-"); expect_equal(nrow(r$unsigned_links), 0)
})
test_that("gb_r unsigned links are transposed and apply to the stored orientation", {
  # build_response_matrices() on an isa fixture with a response whose LinkedGB = "GB1"
  # -> unsigned_links row with matrix_key "gb_r", transposed TRUE;
  # apply_chosen_signs(..., signs = c("R1|GB1" = "+")) -> am$gb_r["GB1", "R1"] == "+medium:3"
})
test_that("untick_linked removes only that target", {
  df <- data.frame(ID = c("D1", "D2"), LinkedA = c("A1;A2", "A2"))
  expect_equal(untick_linked(df, "D1", "LinkedA", "A2")$LinkedA, c(serialize_linked("A1"), "A2"))
})
test_that("rule-default helpers are gone", {
  expect_false(exists("default_polarity_for_matrix")); expect_false(exists("get_rule_default_polarity"))
})
test_that("Standard Entry: second save with no new ticks opens no dialog; cancel unticks", {
  # testServer(isa_data_entry_module server) with a mocked sign_choice_server recording open() calls:
  # tick D1->A2, save -> open called once with 1 link; on_done(NULL) -> isa_data$drivers LinkedA lacks A2;
  # save again -> open not called again
})
test_that("recovering a LinkedX-only workbook asks for signs", {
  # recover_isa_data(fixture with LinkedA, empty d_a) -> nrow(unsigned_links) == number of links, d_a all ""
})
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS** with all updated tests listed under Files.
- [ ] **Step 5: Commit** `feat(polarity): Standard Entry and recovery ask for new links' signs; drop rule-default seeding`

### Task 7: Graphical SES creator asks for unevidenced signs

**Files:**
- Modify: `modules/graphical_ses_network_builder.R` (L99, L834, L921, L1005, L1048; `graphical_edge_cell` L408-416), `modules/graphical_ses_creator_module.R` (ghost acceptance L954-961, `accept_ghost_node` L1047, suggestion panel L1336-1346, L1069/L1186 logging), `modules/graphical_ses_ml_enhancer.R` (L88), `functions/dapsiwrm_connection_rules.R` (delete `infer_connection_polarity` L438+)
- Test: `tests/testthat/test-polarity-graphical.R`; update `test-graphical-export-isa.R`, `test-graphical-ses-ai-creation.R`

**Interfaces:**
- Consumes: `evidenced_polarity()`, `polarity_picker_input()`, `read_polarity_pick()` (Task 1).
- Produces:
  - Ghost edges carry `polarity` from `evidenced_polarity()` and `polarity_source`; loop opportunities carry `polarity = NA_character_` (keep `loop_type` for display).
  - Accepting a ghost node whose edge polarity is NA shows the picker in the suggestion panel for that ghost; the node and edge are added only after a sign is picked. An evidenced ghost shows "from: <citation>" and is added directly.
  - `graphical_edge_cell(edges, i)` returns `NA_character_` for a polarity other than `+`/`-` (after lower-casing, `negative`/`opposing`/`minus` still mean `-` and `positive`/`reinforcing`/`plus` mean `+`), and the ISA export skips such edges with a `debug_log` line.
  - `infer_connection_polarity` deleted; no remaining callers.

- [ ] **Step 1: Failing tests**

```r
test_that("ghost suggestions carry only evidenced signs", {
  stub_kb(NULL)
  g <- generate_ghost_suggestions(node_fixture)   # the builder's suggestion function used at L99
  expect_true(all(is.na(vapply(g, `[[`, "", "polarity"))))
})
test_that("graphical_edge_cell does not invent +", {
  e <- data.frame(polarity = c("+", "opposing", "?", NA), strength = "medium", confidence = 3)
  expect_equal(vapply(1:4, function(i) graphical_edge_cell(e, i), ""),
               c("+medium:3", "-medium:3", NA, NA))
})
test_that("accepting an unsigned ghost waits for a sign", {
  # testServer(graphical_ses_creator server): accept unsigned ghost -> rv nodes unchanged;
  # set its picker to "-" and accept -> node added, edge polarity "-"
})
test_that("infer_connection_polarity is gone", expect_false(exists("infer_connection_polarity")))
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS** with the updated graphical tests.
- [ ] **Step 5: Commit** `feat(polarity): graphical creator asks for unevidenced signs`

### Task 8: CLD editor asks for the sign of a drawn edge

**Files:**
- Modify: `functions/cld_interaction_helpers.R` (`create_new_edge_data` L338), `modules/cld_visualization_module.R` (edge-added observer L1214-1240, edit-edge modal ~L350 and L1302-1394), JS from `generate_manipulation_enable_js` only as needed to remove a cancelled edge client-side
- Test: `tests/testthat/test-polarity-cld.R`; update `test-cld-edge-id.R`

**Interfaces:**
- Consumes: `polarity_picker_input()`, `read_polarity_pick()` (Task 1).
- Produces:
  - `create_new_edge_data(from_id, to_id, max_existing_id, polarity)` — `polarity` required (`"+"`/`"-"`); colour, label and `originalColor` follow it (`EDGE_COLORS$reinforcing` / `$opposing`, label `+`/`-`).
  - Drawing an edge opens the edit-edge dialog with the sign picker unset (strength/confidence defaults as today). Confirm (enabled only with a sign) creates the edge and syncs as today; Cancel creates nothing and removes the client-side edge vis-network already drew.
  - The existing edit-edge dialog uses the picker too, preselected with the edge's sign.

- [ ] **Step 1: Failing tests**

```r
test_that("create_new_edge_data requires and applies a sign", {
  expect_error(create_new_edge_data("A", "B", 0))
  e <- create_new_edge_data("A", "B", 0, polarity = "-")
  expect_equal(e$polarity, "-"); expect_equal(e$label, "-"); expect_equal(e$color, EDGE_COLORS$opposing)
})
test_that("a drawn edge is added only after the sign is confirmed", {
  # testServer(cld_visualization server): setInputs(edge_added = list(from = "A", to = "B")) -> rv$edges unchanged;
  # pick "-" and confirm -> one new edge with polarity "-"; repeat with cancel -> no new edge
})
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS** with `test-cld-*.R`.
- [ ] **Step 5: Commit** `feat(polarity): CLD editor asks for a drawn edge's sign`

### Task 9: Template sign coverage, docs and release 1.36.0

**Files:**
- Modify: `functions/template_loader.R` (L119 fallback), `DAPSIWRM_FRAMEWORK_RULES.md` (remove the "being implemented" sentence in "How Polarity Is Assigned" and the "Polarity seeding" implementation note; describe the new behaviour), `CHANGELOG.md`, `VERSION` (`1.36.0`), user-guide text that describes automatic signs (find with `git grep -n -i "polarit" -- "*.md" "www/*.html" translations` and update only text that claims signs are assigned automatically)
- Test: `tests/testthat/test-template-polarity-coverage.R`

**Interfaces:**
- Produces: every connection in every template that `load_all_templates("data")` loads has an explicit `+`/`-`; the `conn$polarity %||% "+"` fallback is removed (a missing sign is a load error logged with the template name).

- [ ] **Step 1: Failing test** — iterate `load_all_templates("data")`, assert every non-empty matrix cell starts with `+` or `-`, and assert the source text of `template_loader.R` no longer contains `polarity %||% "+"`.
- [ ] **Step 2: Run, expect FAIL** (fallback still present).
- [ ] **Step 3: Implement**; if a shipped template lacks a sign, stop and report it (do not invent one).
- [ ] **Step 4: Run** the new test, then the full suite `Rscript -e "testthat::test_dir('tests/testthat')"` (expect 0 failures; record the counts), the i18n audit (missing=0, hardcoded=0) and `Rscript deployment/pre-deploy-check.R`.
- [ ] **Step 5: Manual check** — `Rscript run_app.R`, then once through each entry point: AI assistant review (unsigned blocked, approve-all count, KB "from:" line), Standard Entry (dialog, cancel unticks), Excel import (review + blocked direct import), graphical creator (unsigned ghost asks), CLD (drawn edge asks). Note what was checked in the commit body.
- [ ] **Step 6: Commit** `release: 1.36.0 — evidenced polarity` with a CHANGELOG entry citing the expert review (Gemma Smith, 12 Nov 2026) and rules v1.2.
