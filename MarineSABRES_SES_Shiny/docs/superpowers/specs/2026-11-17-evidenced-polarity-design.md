# Evidenced Polarity: the User Chooses Every Unevidenced Sign

**Date:** 2026-11-17. **Target:** SES Toolbox v1.36.0. **Branch base:** `docs/rules-v1.2-gemma` (36e209b), off v1.35.6.

## Why

The expert review of the framework rules (Gemma Smith, 12 November 2026; see
`DAPSIWRM_FRAMEWORK_RULES.md` v1.2, "How Polarity Is Assigned") found that the
toolbox's automatic signs are context dependent: the same category pair (D→A,
A→P, C/S→ES, ES→GB, GB→D, R→D, R→P) can carry either sign depending on the
system and on how each element is phrased. Filling in a "typical" sign
restricts modelling and can quietly put wrong loops into a model. Her
recommendation, agreed with the project lead on 17 November:

- where a connection has **evidenced** polarity, the toolbox fills it in and
  the user can change it;
- otherwise the **user must choose** the sign before the connection is
  accepted.

The project lead chose "must pick before accept" over storing an unsigned
"?" state, so that saved projects, loop analysis, exports and the SESPy
importer keep seeing only `+` and `-`.

## Goals

1. No connection enters a project with a sign the user did not choose,
   unless the sign is evidenced.
2. Every place that creates connections offers a clear, translated way to
   pick the sign, with nothing preselected when there is no evidence.
3. Saved data is unchanged in format: every accepted connection, matrix cell
   and CLD edge still has `+` or `-`.

## Non-goals

- No third "unknown" polarity in saved projects, matrices, exports or
  analysis.
- No migration of existing projects: signs already saved stay as they are.
- No renaming of knowledge-base elements to the no-verbs/neutral convention
  (separate follow-up; noted in the rules v1.2).
- No changes to non-user-facing networks (`functions/scenario_network.R`,
  `functions/ses_dynamics.R`, `functions/intervention_designer.R`).
- SESPy parity is a separate follow-up after this ships (SESPy's K1b port of
  the connection scorer will need the same rule).

## Anti-goals

- A sign picker that looks optional but silently becomes `+` (today's review
  switch reads NULL as `+`). If the user did not choose and there is no
  evidence, the connection must not be accepted.
- Hints such as "typical: −" next to the picker. They would reintroduce the
  default the expert asked us to drop.

## What counts as evidence

Evidenced (sign filled in, editable):

- an **exact** knowledge-base match: `lookup_knowledge_base()` returning
  `match_quality == "exact"` (data/ses_connection_knowledge_base.R:1094-1149).
  "Exact" means both name patterns matched (regexes such as
  `"trawl|bottom.*fish|drag"`), not equal names, so wherever such a sign is
  shown the toolbox shows its literature `source` next to it ("from:
  <citation>"), letting the user see why it was filled in and change it.
  *(Project lead's decision, 17 Nov.)* An entry without a `source` is not
  evidence;
- a sign written by a template author in a shipped template;
- a sign present in an imported file (Excel matrix cell or Kumu `Label`
  starting with `+`/`-`);
- a sign the user chose earlier (editing an existing connection keeps it).

Not evidence (no sign filled in): synonym knowledge-base matches, the
keyword/phrase heuristics in `detect_polarity()`, the rule-table defaults
(`get_rule_default_polarity()`, `default_polarity_for_matrix()`,
`infer_connection_polarity()`), ML predictions (`ml_inference.R:442`,
`ml_ensemble.R:470`), and the graphical creator's loop-opportunity guess.
ML predictions are output fields only (`ml_ensemble.R:470` thresholds a
sigmoid for the returned `polarity`; nothing feeds it back into scoring),
so dropping them needs no retraining.

`detect_polarity()` returns the sign together with its evidence (sign,
source citation) so the review card and the graphical creator can show the
"from:" line; the exact return shape is left to the builder.

## Design

### Representation

A connection that has been **suggested but not yet accepted** may carry
`polarity = NA_character_`. That state lives only in pending suggestions
(AI review cards, graphical ghost edges, import review rows, the Standard
Entry sign dialog, the CLD new-edge dialog). It never reaches
`project_data$isa_data`, the adjacency matrices or CLD edge data.

Persistence guards this: the matrix writer (`modules/ai_isa/data_persistence.R`
around L333-338, where `paste0(polarity, strength, ":", conf)` would produce
`"NAmedium:3"`) and `sync_cld_to_isa_data` (`functions/cld_interaction_helpers.R`
L804-810, which today turns NA into `+`) refuse a missing sign: they log an
error and skip that connection instead of inventing `+`. Code that displays
pending suggestions must handle NA (today `if (polarity == "+")` errors at
`connection_generator.R:516-528`, `action_handlers.R:71/288`,
`template_ses_module.R:740/941`, `visnetwork_helpers.R:1213`,
`cld_interaction_helpers.R:367`); rationale text uses a neutral verb
("affects") when the sign is unset.

### Shared sign picker

One small UI builder in `functions/ui_components.R`, used at every entry
point: two buttons, Reinforcing (+) and Opposing (−), with **nothing
selected** unless a sign is evidenced or already chosen, and a short
"Choose a sign" prompt while unset. When the sign comes from the knowledge
base it shows a "from: <citation>" line under the buttons, which disappears
once the user changes the sign. Its value is `"+"`, `"-"` or `NA`.
Labels reuse `common.choices.polarity_reinforcing` / `_opposing`; any new
strings get all 9 languages. The builder may wrap an existing widget
(shinyWidgets radio buttons or a select with an empty first choice); the
choice is left to the builder, provided "unset" is a real, visible state.

### Entry points

1. **AI ISA assistant** (`modules/ai_isa/connection_generator.R`,
   `modules/connection_review_tabbed.R`).
   - `detect_polarity()` returns the knowledge-base sign only for an exact
     match, otherwise `NA`. The heuristic layers and the final `"+"` go.
     `generate_smart_connections()` keeps its scoring (confidence 4 exact,
     3 synonym) but a synonym match no longer supplies the sign.
   - The review card's sign control uses the shared picker. Approving a card
     with no sign is blocked with a translated message.
   - "Approve all" (per batch, L872-880, and the global
     `approve_all_connections`, `ai_isa_assistant_module.R:923`, the same
     way) approves only the signed suggestions and reports how many still
     need a sign. When none are signed it approves nothing and says "N
     connections need a sign before they can be approved".
   - The import review (`import_data_module.R:385/423`) uses this same
     `connection_review_tabbed` component, so the picker lands once for
     both; the import-side amendment fix is in entry point 5.
   - The dead knowledge-DB seeding branch (`connection_generator.R:903`,
     `kb_conn$polarity %||% "+"`) gets the same rule if kept.
2. **Standard Entry** (`modules/isa_data_entry_module.R`,
   `functions/matrix_from_linked.R`, `functions/isa_form_builders.R`).
   - New matrix cells created from LinkedX selections, and response-matrix
     cells from `build_response_matrices`, are no longer seeded from the
     rule table.
   - A **new link** is a (from, to) pair in the LinkedX selections that has
     no cell in the current saved matrix. Existing cells (from a template,
     an import, an older project or an earlier save) are signed and keep
     their sign. The pending state lives in the save handler: it computes
     the new pairs, and `rebuild_matrix_from_linked()` /
     `rebuild_forward_matrix_by_name()` take the chosen signs as a map
     (pair → sign) instead of a `default_polarity`.
   - When saving would create new links, a modal lists them (from → to,
     with the shared picker on each row). Save completes once every row has
     a sign. Cancel saves everything else, leaves those links out, and
     removes their ticks from the LinkedX fields so the form matches the
     saved data. *(Our call.)*
   - The loop builder's "Effect" select (L1739) starts unset.
3. **CLD editor** (`functions/cld_interaction_helpers.R:348`,
   `modules/cld_visualization_module.R:1221`). Drawing an edge opens the
   edit-edge dialog with no sign selected; the edge is created on confirm,
   and cancel creates nothing.
4. **Graphical SES creator** (`modules/graphical_ses_network_builder.R`,
   `modules/graphical_ses_creator_module.R`). Ghost edges carry an evidenced
   sign or NA (no `infer_connection_polarity()`, no loop-opportunity guess).
   Accepting a ghost node whose edge is unsigned asks for the sign in the
   suggestion panel before adding it. `graphical_edge_cell()` (L408-416)
   stops mapping unknown values to `+`.
5. **Excel/Kumu import** (`functions/excel_import_helpers.R:433`,
   `modules/import_data_module.R`). Rows whose `Label` starts with `+`/`-`
   keep that sign. Rows without one get NA and must be signed in the import
   review. "Direct import" is blocked when any row lacks a sign, with a
   message pointing to the review. For matrix cells, the sign is the first
   character when it is `+` or `-`; any other cell that marks a link
   (`"medium:3"`, `"x"`, `"1"`) is unsigned.
   - Standard Entry workbooks and projects that carry links only in LinkedX
     columns (`recover_isa_data`, `standard_entry_excel_import.R:196`, used
     by `import_data_module.R:266` and `isa_data_entry_module.R:396`):
     these links have no sign in the file, so after loading the toolbox
     shows the same "choose signs" modal as the Standard Entry save, and
     unsigned links are added only once signed. Matrices that already have
     cells are read as they are. *(Our call.)* Also fix the existing bug that discards
   a sign changed in the review (no `on_amend`, finalize reads only
   `rv$connections_data$Label`; L423-433).
6. **Templates** (`functions/template_loader.R:119`). Shipped template signs
   are evidence and stay. Add a test that every connection in every shipped
   template has an explicit sign, so the `%||% "+"` fallback never fires;
   then remove the fallback.
7. **ML suggestions** (`ml_inference.R:442/1006/1010`, `ml_ensemble.R:470`).
   Predicted signs are not evidence: suggestions carry NA and go through the
   same review.

### Left as is

- `convert_matrices_to_connections()` (`connection_generator.R:660`) used
  when recovering a saved AI session: it restores saved, already-approved
  work, not new suggestions. Its `+` fallback for a malformed cell stays,
  with a log line. (LinkedX-only recovery is not left as is: see entry
  point 5.)
- The rule table in `functions/dapsiwrm_connection_rules.R` keeps deciding
  which transitions are **valid**. Its sign fields no longer seed anything;
  `get_rule_default_polarity()` and `default_polarity_for_matrix()` are
  removed; their callers (`isa_form_builders.R:723/739`,
  `isa_data_entry_module.R:324`, `standard_entry_excel_import.R:196`,
  `tests/testthat/helper-stubs.R`) move to the chosen-signs map above, and `infer_connection_polarity()` is removed
  or reduced to the evidenced lookup. *(Our call: removing the API stops it
  creeping back.)*

## Testing

- Unit: `detect_polarity()` returns NA for synonym-only and heuristic-only
  cases and the KB sign for exact matches; the shared picker renders unset;
  Standard Entry rebuild creates no signed cell without a choice; Excel rows
  without a sign come back NA; template sign coverage test; persistence
  refuses NA.
- Behaviour (`testServer()`): review approve-one blocked when unset;
  approve-all skips unsigned and reports the count; CLD new edge not created
  on cancel; import review amendment is kept.
- Update the existing tests that assert default signs
  (`test-dapsiwrm-connection-rules.R`, `test-matrix-from-linked.R`,
  `test-linked-by-name.R`, `test-connection-review*.R`, `test-cld-*.R`,
  `test-graphical-*.R`, `test-excel-import-helpers.R`,
  `test-import-data-se-format.R`, `test-isa-responses-*.R`,
  `test-template-ses-module.R`).
- i18n audit clean (missing=0, hardcoded=0); full testthat suite green;
  one manual run through each entry point in the app.

## Release

v1.36.0 with a CHANGELOG entry that cites the expert review and rules v1.2;
the rules document's "being implemented" note is removed in the same
release. User guide text that describes automatic signs is updated. After
release, open a SESPy issue for the parity port (SESPy's K1b scorer
currently ports the R heuristic and rule-default fallbacks).

## Left to the builder

Widget choice for the picker, modal layouts, exact message wording (in 9
languages), task order, and whether `infer_connection_polarity()` is
deleted or reduced.
