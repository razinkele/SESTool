# WP5 WS-3b — Typing lint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Warn users when their model probably mistypes an intervention, without ever changing their data. The lint has two rules:
- **L1:** a Driver, Activity or Ecosystem Service whose name matches a policy-instrument or management-measure term (quota, licence, MPA, label, mooring, subsidy, tax, ban, closure, restoration …).
- **L2:** a Response with no incoming link from a Marine Process, Ecosystem Service or Goods & Benefit. D5.3 calls this a "no-feedback intervention".

**Architecture:**
- **Data:** `data/wp5_rm_synonyms.json`, toolbox-authored and holding regex fragments for each of the 9 languages.
- **Logic:** `functions/wp5_typing_lint.R` holds the pure, word-boundary-safe lint `wp5_typing_lint(nodes, edges, patterns)`. It runs over the nodes and edges from the existing builders `create_nodes_df()` / `create_edges_df()`.
- **Surfacing:** the ISA module shows the findings next to the existing matrix-alignment warning, as one translated notification that fires only when the findings change. This is the same pattern as `warn_if_matrices_misaligned()`.

**Tech Stack:** R 4.4.1, shiny 1.11.1, testthat 3.3.2, jsonlite; PCRE with `(*UCP)` and `\p{L}` for Unicode word boundaries.

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` (WS-3 "Typing lint"). Evidence: `docs/wp5-source-audit/2026-10-11/C_D5.3_interventions.md` §4 and §5.4 (all three DA models had mistyped instruments; Tuscan instruments had no feedback).

## Deviations from spec WS-3 (explicit)

| Spec | 3b decision | Why |
|---|---|---|
| "Surfaced in the CLD validation panel and ISA review" | **ISA module only**, one notification next to the matrix-alignment warning | The app has no single CLD validation panel. One surface keeps it simple; a second can follow. |
| L2: "incoming edge from C/ES/GB/**HW**" | **MPF/ES/GB** | This app has no HW node group (`create_nodes_df` groups) |
| Synonyms "per language held in the vocabulary JSON" | Separate `data/wp5_rm_synonyms.json` with `provenance: "toolbox_extension"` | These are regex data, not UI labels. Keeping them out of `translations/` respects the keys-defined-once rule. |

## Global Constraints

- **Never change user data.** The lint only reports.
- **Word-boundary-safe matching.** The pattern is `(*UCP)(?<!\p{L})(<fragment>)(?!\p{L})` with `perl = TRUE, ignore.case = TRUE`. Short terms must not match inside other words: `tax` must not match "taxa", and `ban` must not match "urban" or "banner".
- **Group names** are the ones `create_nodes_df()` emits:
  - L1 applies to `"Drivers"`, `"Activities"` and `"Ecosystem Services"`.
  - L2 applies to `"Responses"`; an incoming link counts as feedback when its source group is `"Marine Processes & Functioning"`, `"Ecosystem Services"` or `"Goods & Benefits"`.
- **i18n.** Three new keys go in `translations/modules/isa_data_entry.json` (namespace `modules.isa.data_entry.common.`), with genuine text in all 9 languages.
  - The keys-once rule from `origin/main` 1.22.2 applies: a key may be defined in exactly one file.
  - `test-i18n-english-fallback.R` (no English sentences of 30+ characters) and the i18n audit must pass.
- **Tests.**
  - Use `source_for_test()`.
  - For the ISA module, use the server from `.GlobalEnv`, as in `test-matrix-alignment-on-load.R`.
  - Do not use `local_mocked_bindings`.
  - Run the full suite in the background; the system may kill it if memory runs low.
- **Shell and repo.**
  - Use `git -C`. The repo root is `SESToolbox/` and the app is in `MarineSABRES_SES_Shiny/`.
  - `docs/` is gitignored, so add files there with `add -f`.
- **Worktree:** `C:/Users/arturas.baziukas/wt-ws3b`, branch `feat/wp5-ws3b-typing-lint` from local `main` f892400.
- **Upstream:** `origin/main` is 84591de (1.22.2). Task 0 merges it in. A trial merge showed a CHANGELOG-only conflict.

## Review Focus

1. **Short or ambiguous terms inside other words.** "Urban development", "Taxa richness", "Banner fishing" and "Labour market" must not be flagged. Pinned in Task 1.
2. **Element names in Lithuanian or Greek**, e.g. "Žvejybos kvotos" typed as an Activity, must be flagged. Pinned in Task 1.
3. **A model with no Responses, no edges, or an empty ISA** must return zero findings without error. Pinned in Task 1.
4. **Re-saving a project with the same findings** must not show the notification again; only a change in findings re-notifies. Pinned in Task 2.
5. **The seven shipped templates** must lint without error. Their finding counts are recorded in the ledger as information; templates are not edited here. Pinned in Task 1.

---

### Task 0: Integrate origin/main; commit the plan

- [ ] **Step 1: Merge origin/main**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3b" fetch origin
git -C "C:/Users/arturas.baziukas/wt-ws3b" merge --no-edit origin/main
```

Expect a conflict in `MarineSABRES_SES_Shiny/CHANGELOG.md`. Resolve it as follows:

- Keep both sides.
- origin's released `## [1.22.2]` (and its other released) sections stay as they are.
- The WP5 entries (WS-0/1, WS-2 and WS-3a) stay under `## [Unreleased]`, above `## [1.22.2]`.

Then run `git -C … add MarineSABRES_SES_Shiny/CHANGELOG.md` and `git -C … commit --no-edit`.

- [ ] **Step 2: Post-merge checks**

Run from `MarineSABRES_SES_Shiny/`:
- `test-i18n-english-fallback.R`
- `test-i18n-placeholders.R`
- `test-i18n-enforcement.R`
- `test-wp5-vocabulary.R`
- `test-response-measures-schema.R`
- `test-response-module.R`
- `test-wp5-kb-loader.R`

Also run any new origin test about keys defined once: `ls tests/testthat | grep -i "once\|duplicate"`.

Expected: all PASS.

If the keys-once test fails because a WP5 key is also defined in another file:
- keep the WP5 file's definition and remove the other one;
- ledger a `Ruling:`.

- [ ] **Step 3: Commit the plan**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3b" add -f MarineSABRES_SES_Shiny/docs/superpowers/plans/2026-10-11-wp5-ws3b-typing-lint.md
git -C "C:/Users/arturas.baziukas/wt-ws3b" commit -m "docs(wp5): WS-3b typing lint plan

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 1: Synonym data and the pure lint

**Files:**
- Create: `data/wp5_rm_synonyms.json`
- Create: `functions/wp5_typing_lint.R`
- Create: `tests/testthat/test-wp5-typing-lint.R`
- Modify: `global.R` — add `source("functions/wp5_typing_lint.R", local = FALSE)` after the `response_measures_schema.R` line.

**Interfaces (produced):**
- `load_wp5_rm_synonyms(path = NULL) -> character`: all regex fragments across languages. Cached. Returns `character(0)` with a warning when the file is missing.
- `wp5_typing_lint(nodes, edges, patterns = load_wp5_rm_synonyms()) -> data.frame(node_id, name, group, rule, matched)`.
  - `rule` is `"L1"` or `"L2"`. `matched` is the matched text for L1 and `""` for L2.
  - Rows are ordered by rule, then by name.
- `typing_lint_from_isa(isa_data) -> data.frame`. It builds nodes and edges with `create_nodes_df()` / `create_edges_df()`, runs the lint, and returns 0 rows on any error.

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-wp5-typing-lint.R
# WS-3b: flag likely mistyped interventions (L1) and Responses without feedback (L2). Never edits data.
library(testthat)
source_for_test(c("functions/visnetwork_helpers.R", "functions/template_loader.R", "functions/wp5_typing_lint.R"))

nd <- function(id, name, group) data.frame(id = id, label = name, name_raw = name, group = group, stringsAsFactors = FALSE)
eg <- function(from, to) data.frame(from = from, to = to, stringsAsFactors = FALSE)

test_that("L1 flags instrument/measure terms on D/A/ES nodes, in several languages", {
  nodes <- rbind(nd("A_1", "Fishing quota agreements", "Activities"),
                 nd("A_2", "Žvejybos kvotos", "Activities"),
                 nd("D_1", "Μέτρα απαγόρευσης αλιείας", "Drivers"),
                 nd("ES_1", "Marine protected area", "Ecosystem Services"),
                 nd("P_1", "Mooring damage", "Pressures"))          # pressures are not linted by L1
  out <- wp5_typing_lint(nodes, eg(character(), character()))
  l1 <- out[out$rule == "L1", ]
  expect_setequal(l1$node_id, c("A_1", "A_2", "D_1", "ES_1"))
  expect_true(all(nzchar(l1$matched)))
})

test_that("L1 does not match terms inside other words", {
  nodes <- rbind(nd("A_1", "Urban development", "Activities"), nd("A_2", "Taxa richness survey", "Activities"),
                 nd("A_3", "Banner fishing", "Activities"), nd("D_1", "Labour market", "Drivers"),
                 nd("A_4", "Coastal tourism", "Activities"))
  expect_equal(nrow(wp5_typing_lint(nodes, eg(character(), character()))), 0L)
})

test_that("L2 flags Responses with no feedback link from MPF/ES/GB only", {
  nodes <- rbind(nd("R_1", "Quota", "Responses"), nd("R_2", "Eco-label", "Responses"),
                 nd("GB_1", "Fish catch", "Goods & Benefits"), nd("D_1", "Food demand", "Drivers"))
  edges <- rbind(eg("GB_1", "R_1"), eg("D_1", "R_2"))             # D->R is not feedback
  out <- wp5_typing_lint(nodes, edges)
  expect_equal(out$node_id[out$rule == "L2"], "R_2")
})

test_that("empty inputs give zero findings without error", {
  e <- wp5_typing_lint(nd("x", "x", "Drivers")[0, ], eg(character(), character()))
  expect_equal(nrow(e), 0L)
  expect_equal(names(e), c("node_id", "name", "group", "rule", "matched"))
  expect_equal(nrow(typing_lint_from_isa(list())), 0L)
  expect_equal(nrow(wp5_typing_lint(NULL, NULL)), 0L)
})

test_that("synonym file is toolbox-authored and covers all 9 languages", {
  syn <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_rm_synonyms.json"), simplifyVector = FALSE)
  expect_equal(syn$provenance, "toolbox_extension")
  expect_setequal(names(syn$patterns), c("en","es","fr","de","lt","pt","it","no","el"))
  for (p in unlist(syn$patterns)) expect_no_error(grepl(paste0("(*UCP)(?<!\\p{L})(", p, ")(?!\\p{L})"), "x", perl = TRUE))
})

test_that("all seven shipped templates lint without error (counts recorded)", {
  for (nm in c("Aquaculture", "Caribbean", "ClimateChange", "Fisheries", "OffshoreWind", "Pollution", "Tourism")) {
    p <- file.path(PROJECT_ROOT, "data", paste0(nm, "_SES_Template.json"))
    tpl <- load_template_from_json(p, use_cache = FALSE)
    isa <- list(drivers = tpl$drivers, activities = tpl$activities, pressures = tpl$pressures,
                marine_processes = tpl$marine_processes, ecosystem_services = tpl$ecosystem_services,
                goods_benefits = tpl$goods_benefits, responses = tpl$responses,
                adjacency_matrices = tpl$adjacency_matrices)
    out <- typing_lint_from_isa(isa)
    expect_s3_class(out, "data.frame")
    message(sprintf("[typing-lint] %s: L1=%d L2=%d", nm, sum(out$rule == "L1"), sum(out$rule == "L2")))
  }
})
```

- [ ] **Step 2: Run to verify fail**

Run: `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-wp5-typing-lint.R')"`
Expected: FAIL, `could not find function "wp5_typing_lint"`.

- [ ] **Step 3a: `data/wp5_rm_synonyms.json`**

```json
{
  "version": "1.0.0",
  "provenance": "toolbox_extension",
  "description": "Regex fragments (case-insensitive, matched with Unicode word boundaries) for policy-instrument / management-measure terms, used by the WS-3b typing lint to suggest reclassifying a Driver/Activity/Ecosystem Service as a Response. Toolbox-authored from the EBM instrument/measure typology (D5.3); not a WP5 deliverable.",
  "patterns": {
    "en": ["quotas?", "tacs?", "licen[cs](e|es|ing)", "permits?", "mpas?", "oecms?", "(marine )?protected areas?", "no[- ]take( zones?| areas?)?", "(eco[- ]?)?label(s|ling|ing|led)?", "certifi(cation|cations|ed)", "moorings?", "subsid(y|ies)", "tax(es|ation)?", "levy|levies", "fees?", "bans?", "closures?", "closed (seasons?|areas?)", "restoration", "restocking", "zoning", "regulations?"],
    "es": ["cuotas?", "licencias?", "permisos?", "áreas? marinas? protegidas?", "amps?", "zonas? de no extracción", "(eco)?etiquetas?( ecológicas?)?", "certificaci(ón|ones)", "fondeos?", "boyas? de fondeo", "subvenci(ón|ones)", "subsidios?", "impuestos?", "tasas?", "prohibici(ón|ones)", "vedas?", "cierres?", "restauraci(ón|ones)", "regulaci(ón|ones)", "zonificaci(ón|ones)"],
    "fr": ["quotas?", "licences?", "permis", "aires? marines? protégées?", "amp", "zones? de non[- ]prélèvement", "(éco[- ]?)?labels?", "écolabels?", "certifications?", "mouillages?", "subventions?", "taxes?", "redevances?", "interdictions?", "fermetures?", "restauration", "réglementations?", "zonage"],
    "de": ["\\p{L}*quoten?", "\\p{L}*lizenzen?", "genehmigungen?", "\\p{L}*schutzgebiete?n?", "nullnutzungszonen?", "(öko-?)?label(s|n)?", "ökosiegel", "zertifizierung(en)?", "bojen?", "liegeplätze?", "subventionen?", "\\p{L}*steuern?", "\\p{L}*abgaben?", "\\p{L}*gebühren?", "\\p{L}*verbote?", "schonzeiten?", "sperrungen?", "renaturierung", "wiederherstellung", "regulierung(en)?", "zonierung"],
    "lt": ["kvot\\p{L}*", "licencij\\p{L}*", "leidim\\p{L}*", "saugom\\p{L}* teritorij\\p{L}*", "ženklinim\\p{L}*", "ekoženkl\\p{L}*", "sertifikavim\\p{L}*", "sertifikat\\p{L}*", "švartavim\\p{L}*", "subsidij\\p{L}*", "mokesč\\p{L}*", "draudim\\p{L}*", "atkūrim\\p{L}*", "reglamentavim\\p{L}*", "zonavim\\p{L}*"],
    "pt": ["quotas?", "licenças?", "autorizaç(ão|ões)", "áreas? marinhas? protegidas?", "amps?", "zonas? de não extração", "rotulagem", "rótulos?", "(eco)?etiquetas?", "certificaç(ão|ões)", "fundeadouros?", "amarraç(ão|ões)", "subsídios?", "impostos?", "taxas?", "proibiç(ão|ões)", "defesos?", "encerramentos?", "restauro", "restauraç(ão|ões)", "regulamentaç(ão|ões)", "zonamento"],
    "it": ["quot(a|e)", "licenz(a|e)", "permess(o|i)", "are(a|e) marin(a|e) protett(a|e)", "amp", "zon(a|e) di divieto", "(eco)?etichett(a|e|atura)", "certificazion(e|i)", "ormeggi(o)?", "sussidi(o)?", "tass(a|e)", "impost(a|e)", "divieti|divieto", "chiusur(a|e)", "ripristino", "regolamentazion(e|i)", "zonizzazione"],
    "no": ["\\p{L}*kvote(r|ne)?", "lisens(er|en)?", "tillatelser?", "\\p{L}*verneområd(e|er|et|ene)", "nullfiskeområd\\p{L}*", "miljømerk\\p{L}*", "sertifisering(er)?", "fortøyning(er)?", "tilskudd", "subsidier?", "\\p{L}*avgift(er)?", "\\p{L}*skatt(er)?", "\\p{L}*forbud", "stenging(er)?", "fredning\\p{L}*", "restaurering", "regulering(er)?", "soneinndeling"],
    "el": ["ποσοστώσ\\p{L}*", "άδει(α|ες|ών)", "θαλάσσι\\p{L}* προστατευόμεν\\p{L}*", "προστατευόμεν\\p{L}* περιοχ\\p{L}*", "οικολογικ\\p{L}* σήμ\\p{L}*", "πιστοποίησ\\p{L}*", "αγκυροβόλι\\p{L}*", "επιδοτήσ\\p{L}*|επιδότησ\\p{L}*", "φόρ(ος|οι|ου|ων)", "απαγόρευσ\\p{L}*", "αποκατάστασ\\p{L}*", "ρύθμισ\\p{L}*", "χωροθέτησ\\p{L}*"]
  }
}
```

- [ ] **Step 3b: `functions/wp5_typing_lint.R`**

```r
# functions/wp5_typing_lint.R
# WS-3b typing lint: report (never fix) likely mistyped interventions.
#   L1: Driver / Activity / Ecosystem Service named like a policy instrument or
#       management measure (data/wp5_rm_synonyms.json, toolbox-authored).
#   L2: Response with no incoming link from a Marine Process, Ecosystem Service
#       or Goods & Benefit ("no feedback", D5.3).

.wp5_lint_env <- new.env(parent = emptyenv())
WP5_LINT_L1_GROUPS <- c("Drivers", "Activities", "Ecosystem Services")
WP5_LINT_FEEDBACK_GROUPS <- c("Marine Processes & Functioning", "Ecosystem Services", "Goods & Benefits")

.empty_lint <- function() data.frame(node_id = character(), name = character(), group = character(),
                                     rule = character(), matched = character(), stringsAsFactors = FALSE)

load_wp5_rm_synonyms <- function(path = NULL) {
  if (is.null(path) && !is.null(.wp5_lint_env$patterns)) return(.wp5_lint_env$patterns)
  if (is.null(path)) {
    path <- if (exists("get_project_file", mode = "function")) get_project_file("data", "wp5_rm_synonyms.json")
            else file.path("data", "wp5_rm_synonyms.json")
  }
  if (!file.exists(path)) {
    warning(sprintf("[WP5 lint] synonym file not found: %s", path))
    return(character(0))
  }
  syn <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  pats <- as.character(unlist(syn$patterns))
  .wp5_lint_env$patterns <- pats
  pats
}

wp5_typing_lint <- function(nodes, edges, patterns = load_wp5_rm_synonyms()) {
  if (!is.data.frame(nodes) || nrow(nodes) == 0 || !all(c("id", "group") %in% names(nodes))) return(.empty_lint())
  name <- as.character(if ("name_raw" %in% names(nodes)) nodes$name_raw else nodes$label)
  name[is.na(name)] <- ""
  out <- list()
  if (length(patterns) > 0) {
    rx <- paste0("(*UCP)(?<!\\p{L})(", paste(patterns, collapse = "|"), ")(?!\\p{L})")
    cand <- which(nodes$group %in% WP5_LINT_L1_GROUPS)
    for (i in cand) {
      m <- regmatches(name[i], regexpr(rx, name[i], perl = TRUE, ignore.case = TRUE))
      if (length(m) == 1) out[[length(out) + 1]] <- data.frame(node_id = nodes$id[i], name = name[i],
        group = nodes$group[i], rule = "L1", matched = m, stringsAsFactors = FALSE)
    }
  }
  resp <- which(nodes$group == "Responses")
  if (length(resp) > 0) {
    fb_ids <- nodes$id[nodes$group %in% WP5_LINT_FEEDBACK_GROUPS]
    has_fb <- if (is.data.frame(edges) && nrow(edges) > 0) unique(edges$to[edges$from %in% fb_ids]) else character(0)
    for (i in resp) if (!(nodes$id[i] %in% has_fb)) out[[length(out) + 1]] <- data.frame(node_id = nodes$id[i],
      name = name[i], group = nodes$group[i], rule = "L2", matched = "", stringsAsFactors = FALSE)
  }
  if (length(out) == 0) return(.empty_lint())
  res <- do.call(rbind, out)
  res[order(res$rule, res$name), , drop = FALSE]
}

typing_lint_from_isa <- function(isa_data) {
  tryCatch({
    if (!is.list(isa_data) || length(isa_data) == 0) return(.empty_lint())
    nodes <- create_nodes_df(isa_data)
    edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
    wp5_typing_lint(nodes, edges)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(paste("typing lint failed:", e$message), "WARN")
    .empty_lint()
  })
}
```

- [ ] **Step 3c: Source the file**

Add `source("functions/wp5_typing_lint.R", local = FALSE)` to `global.R` after the `response_measures_schema.R` line.

- [ ] **Step 4: Run to verify pass**

Run the test file → all PASS. Copy the `[typing-lint] <template>: L1=… L2=…` message lines into the ledger as information. If a fragment wrongly fires on a template element (for example L1 on an obviously non-instrument name), tighten that fragment and ledger a `Ruling:`.

Run `test-functions-sourced-in-app.R` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3b" add MarineSABRES_SES_Shiny/data/wp5_rm_synonyms.json MarineSABRES_SES_Shiny/functions/wp5_typing_lint.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-wp5-typing-lint.R
git -C "C:/Users/arturas.baziukas/wt-ws3b" commit -m "feat(wp5): typing lint — mistyped interventions (L1) and no-feedback Responses (L2) (WS-3b)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Surface the lint in the ISA module

**Files:**
- Modify: `modules/isa_data_entry_module.R`. Add `warn_if_mistyped()` after `warn_if_matrices_misaligned()` (~:440–467) and call it on the line right after the existing `warn_if_matrices_misaligned()` call (~:467), so the existing wiring test still matches.
- Modify: `translations/modules/isa_data_entry.json` (3 keys)
- Test: `tests/testthat/test-wp5-typing-lint.R` (append)

**Interfaces:**
- Consumes: `typing_lint_from_isa()`.
- Produces: module-local `typing_state$last`, a character vector of `rule:node_id` keys.

i18n keys (`modules.isa.data_entry.common.`):

| Key | English (`%d` = count, `%s` = list) |
|---|---|
| `typing_lint_found` | %d possible typing issue(s) in the model: %s. Nothing was changed. |
| `typing_lint_l1` | looks like a policy instrument or management measure; consider making it a Response |
| `typing_lint_l2` | Response with no link from a Marine Process, Ecosystem Service or Goods & Benefit |

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---- Task 2: surfaced in the ISA module (warn only; re-notify only on change) -----
source_for_test(c("modules/isa_data_entry_module.R", "functions/isa_form_builders.R",
                  "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

project_with_activity <- function(act_name, pid = "p1") list(project_id = pid, data = list(isa_data = list(
  activities = data.frame(ID = "A001", Name = act_name, Sector = "", Description = "",
                          LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("a mistyped activity is recorded once; an unchanged re-save does not re-notify", {
  pdr <- shiny::reactiveVal(project_with_activity("Fishing quota agreements"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_true(any(startsWith(typing_state$last, "L1:")))
    first <- typing_state$last
    pdr(pdr()); session$flushReact()
    expect_identical(typing_state$last, first)
  })
})

test_that("a clean model records no typing finding", {
  pdr <- shiny::reactiveVal(project_with_activity("Coastal tourism"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_length(typing_state$last, 0)
  })
})

test_that("typing lint is wired after the alignment warning; messages translated in 9 languages", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("warn_if_matrices_misaligned()\n        warn_if_mistyped()", s, fixed = TRUE))
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "isa_data_entry.json"),
                           simplifyVector = FALSE)$translation
  for (k in paste0("modules.isa.data_entry.common.", c("typing_lint_found", "typing_lint_l1", "typing_lint_l2")))
    for (l in c("en","es","fr","de","lt","pt","it","no","el")) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  for (l in c("en","es","fr","de","lt","pt","it","no","el")) {
    f <- tr[["modules.isa.data_entry.common.typing_lint_found"]][[l]]
    expect_true(grepl("%d", f, fixed = TRUE) && grepl("%s", f, fixed = TRUE), info = l)
  }
})
```

- [ ] **Step 2: Run to verify fail**

Run the test file. Expected: FAIL, `object 'typing_state' not found` (and the wiring test fails).

- [ ] **Step 3: Implement**

In `modules/isa_data_entry_module.R`, directly after the `warn_if_matrices_misaligned <- function() {…}` definition:

```r
    # WS-3b typing lint: warn (never fix) about likely mistyped interventions and
    # Responses without feedback; re-notify only when the findings change.
    # i18n-ref: modules.isa.data_entry.common.typing_lint_l1
    # i18n-ref: modules.isa.data_entry.common.typing_lint_l2
    typing_state <- new.env(parent = emptyenv())
    typing_state$last <- character(0)
    warn_if_mistyped <- function() {
      if (!exists("typing_lint_from_isa", mode = "function")) return(invisible(NULL))
      f <- typing_lint_from_isa(isolate(reactiveValuesToList(isa_data)))
      keys <- if (nrow(f) > 0) paste0(f$rule, ":", f$node_id) else character(0)
      changed <- !identical(keys, typing_state$last)
      typing_state$last <- keys
      if (length(keys) > 0 && changed) {
        debug_log(paste("Typing lint:", paste(keys, collapse = "; ")), "ISA LINT")
        items <- vapply(seq_len(nrow(f)), function(i) paste0("\u201c", f$name[i], "\u201d \u2014 ",
          i18n$t(paste0("modules.isa.data_entry.common.typing_lint_", tolower(f$rule[i])))), character(1))
        shown <- paste(head(items, 5), collapse = "; ")
        if (length(items) > 5) shown <- paste0(shown, "; \u2026")
        fmt <- i18n$t("modules.isa.data_entry.common.typing_lint_found")
        msg <- if (grepl("%d", fmt, fixed = TRUE) && grepl("%s", fmt, fixed = TRUE)) sprintf(fmt, nrow(f), shown) else fmt
        showNotification(msg, type = "warning", duration = 15, session = session)
      }
    }
```

On the line after the existing `warn_if_matrices_misaligned()` call, add a call with the same indentation (8 spaces):

```r
        warn_if_mistyped()
```

Add the 3 keys to `translations/modules/isa_data_entry.json`, with genuine translations in all 9 languages. Keep `%d` and `%s` in `typing_lint_found` in every language. Check that none of these keys is defined in any other file.

- [ ] **Step 4: Run to verify pass**

Run each of the following:
- the lint test file → all PASS;
- `test-matrix-alignment-on-load.R` → PASS (its wiring assertion is unaffected);
- `test-i18n-enforcement.R`, `test-i18n-english-fallback.R`, `test-i18n-placeholders.R`, and the keys-once test if present → PASS;
- `micromamba run -n shiny python scripts/_i18n_audit.py` → missing=0, hardcoded=0.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3b" add MarineSABRES_SES_Shiny/modules/isa_data_entry_module.R MarineSABRES_SES_Shiny/translations/modules/isa_data_entry.json MarineSABRES_SES_Shiny/tests/testthat/test-wp5-typing-lint.R
git -C "C:/Users/arturas.baziukas/wt-ws3b" commit -m "feat(isa): warn about likely mistyped interventions and no-feedback Responses on load (WS-3b)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Full suite, CHANGELOG

- [ ] **Step 1:** Run the full suite in the background. Expected: 0 failures, except the known `test-ml-graph-features` timing flake.
- [ ] **Step 2:** Add a CHANGELOG entry under `[Unreleased]`:

```markdown
### Added (typing check — spec 2026-10-11 WS-3b)
- **On load, the ISA editor warns about likely mistyped interventions.** It flags two cases:
  - Drivers, Activities or Ecosystem Services named like a policy instrument or management measure (quota, licence, MPA, label, mooring, subsidy, tax, ban, closure, restoration…), which probably belong under Responses. This mistake appeared in all three demonstration-area models analysed in D5.3.
  - Responses that receive no link from a Marine Process, Ecosystem Service or Goods & Benefit, so they cannot respond to the state they manage.
- Matching is word-boundary-safe in 9 languages. The warning appears only when the findings change, and nothing in the project is modified.
```

- [ ] **Step 3: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3b" add MarineSABRES_SES_Shiny/CHANGELOG.md
git -C "C:/Users/arturas.baziukas/wt-ws3b" commit -m "docs(changelog): WS-3b typing lint

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Then do the whole-branch review and run superpowers:finishing-a-development-branch.
