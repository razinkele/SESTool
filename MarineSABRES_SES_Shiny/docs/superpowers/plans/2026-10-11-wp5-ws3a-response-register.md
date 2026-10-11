# WP5 WS-3a — Response register: codes, EBM classification, governance, tenets — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Response-measures register store stable codes instead of translated labels, migrating existing projects. Add EBM instrument/measure classification, governance annotations, management-strategy pairing, links to implementing stakeholders, and an 11-tenet appraisal.

**Architecture:**
- A new pure-function file, `functions/response_measures_schema.R`, owns the register schema:
  - the column list and an empty data frame;
  - a reverse map from labels to codes, built from **all** translation files in all 9 languages;
  - `normalize_response_measures()` (idempotent);
  - helpers for target suggestion, EBM picker choices, display labels, and the stakeholder-ID codec.
- Every load path normalizes the register through `normalize_json_project_data()`, plus the module's own loader.
- `modules/response_module.R` writes codes, gains a collapsible "EBM classification and governance" panel, and translates codes only for display.
- Every column is scalar (no list-columns), so the data survives a JSON round trip.

**Tech Stack:** R 4.4.1, shiny 1.11.1 (bs4Dash), testthat 3.3.2, jsonlite, DT, officer/flextable (existing).

**Spec:** `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` (P1–P7, WS-3). WS-1 vocabulary: `constants.R` (`EBM_POLICY_INSTRUMENTS`, `EBM_MANAGEMENT_MEASURES`, `EBM_TENETS`) and `functions/wp5_vocabulary.R` (`wp5_vocab_label()`).

**Split:** WS-3 is delivered as two plans. **3a** (this one) is the register. **3b**, the typing lint over CLD nodes and edges, is a separate plan written after 3a lands. The two share no code or data.

## Deviations from spec WS-3 (explicit)

| Spec | 3a decision | Why |
|---|---|---|
| New `rm_type_code` / `rm_target_code` columns | **Rewrite `Type`/`Target`/`Status` in place** to codes when the reverse map resolves; leave unresolvable strings untouched (display falls back to the raw text) | Two columns would mean two sources of truth once the form writes codes |
| Spec lists `rm_type` and `rm_target` only | **`rm_status` included** | It has the same bug: translated labels are stored as values |
| `tenet_scores` as a named list | **11 scalar columns `Tenet_<code>`** | List-columns turn into data frames after `fromJSON(simplifyVector=TRUE)` (WS-0 review C1) |
| `implementing_stakeholder_ids` list | **`ImplementingStakeholders`, a `;`-joined ID string** | Scalar column; same reason |
| `pestle_tag` | **Deferred to WS-8** | WS-8 is its only consumer |
| Minimal/full tenet tooltips | **Deferred.** 3a ships tenet names and the three level labels only | 22 long definitions × 9 languages need their own translation pass |
| Lint "surfaced in CLD validation panel and ISA review" | **Moved to plan 3b** | Separate subsystem |
| ISA `responses` element frame (`measure_type`, …) | **Untouched** | Different store from the register |

## Global Constraints

- **Codes in data, labels on display (spec P2).**
  - `Type` ∈ `RM_TYPE_CODES`; `Target` ∈ `RM_TARGET_CODES`; `Status` ∈ `RM_STATUS_CODES`; `Kind` ∈ {`instrument`, `measure`, ""}.
  - `EbmCode` ∈ the WS-1 instrument **type** codes or measure codes, or "".
  - `GovernanceLevel` ∈ `GOVERNANCE_LEVELS` or "".
  - `Tenet_<code>` ∈ `TENET_LEVELS` or "". `intermediate` is allowed for `ecol_effective` only.
- **Scalar columns only.** Every register column is `character`, except `Cost`, which is `numeric`. No list-columns.
- **All load paths** run `normalize_response_measures()` via `normalize_json_project_data()`. This covers project I/O, local storage, the language-switch restore and autosave recovery. The module loader also calls it; it is idempotent.
- **i18n.** New keys use the `modules.response.governance.*` namespace in a new file, `translations/modules/response_governance.json`, with genuine text in all 9 languages.
  - `test-i18n-english-fallback.R` (zero English sentences of ≥30 chars in other languages), `test-i18n-enforcement.R`, `test-i18n-placeholders.R` and `scripts/_i18n_audit.py` (missing=0, hardcoded=0) must pass.
  - EBM type and tenet labels reuse WS-1 keys through `wp5_vocab_label()`.
  - Dynamically built keys get `# i18n-ref:` sentinels.
- **Sourcing.** `functions/response_measures_schema.R` is sourced in `global.R` with a literal `source("functions/response_measures_schema.R", local = FALSE)` placed **before** `source("functions/data_structure.R"...)`, or anywhere in the chain if all calls happen at runtime. `test-functions-sourced-in-app.R` must pass.
- **R tests.**
  - Modules: use `source_for_test()` and re-bind the real server from `.GlobalEnv` (`real_response_measures_server`, already defined in `test-response-module.R`).
  - `testServer()` cannot observe `updateSelectInput()`, so assert on pure functions.
  - `local_mocked_bindings()` does not work outside a package; swap globals by hand.
  - Never end a test in `expect_true(TRUE)`.
- **Shell and environment.**
  - Use `git -C`. The repo root is `SESToolbox/`; the app lives in `MarineSABRES_SES_Shiny/`.
  - `docs/` is gitignored, so stage plans with `add -f`.
  - CRLF line endings on Windows are fine.
  - Run the full suite in the background; it may be killed under memory pressure, so each task is gated by its own targeted test files.
- **Worktree:** `C:/Users/arturas.baziukas/wt-ws3`, branch `feat/wp5-ws3-rm-governance` from local `main` 2e376cf. `origin/main` had nothing new on 2026-10-11.

## Review Focus

1. **A legacy project saved in Lithuanian**, e.g. `Type = "Reguliavimo"`, opened in an English session. It must show the English label, and saving must write the code. Pinned in Task 2.
2. **A legacy label that matches no translation** (hand-typed or a since-renamed label). It must be kept verbatim, without error, and displayed as-is. Pinned in Task 1.
3. **A register saved as JSON and reloaded with `simplifyVector = TRUE` or `FALSE`.** All new columns, including `ImplementingStakeholders` with several IDs and all 11 tenet columns, must round-trip unchanged. Pinned in Task 2.
4. **Adding a measure when PIMS has no stakeholders and the register is empty.** The form must work and the stakeholder and pairing selectors must be empty. A measure with an empty EBM panel must still save. Pinned in Task 4.
5. **Choosing a management-measure EBM type.** The suggested DAPSIWRM target must follow the WS-1 `dapsiwrm_target` (A → activities, P → pressures, C → state, `A|P|C` → multiple). Policy instruments make no suggestion. Pinned in Task 1.

---

### Task 0: Commit the plan

- [ ] **Step 1**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add -f MarineSABRES_SES_Shiny/docs/superpowers/plans/2026-10-11-wp5-ws3a-response-register.md
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "docs(wp5): WS-3a response register plan

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 1: Register schema, reverse map, helpers, constants, translations

**Files:**
- Create: `functions/response_measures_schema.R`
- Create: `translations/modules/response_governance.json`
- Create: `tests/testthat/test-response-measures-schema.R`
- Modify: `constants.R`. Add after the WS-1 block, before `# END OF CONSTANTS`.
- Modify: `global.R`. Add `source("functions/response_measures_schema.R", local = FALSE)` next to the `wp5_vocabulary.R` line.

**Interfaces (produced):**
- **Constants:**
  - `RM_TYPE_CODES` (named chr: code → existing label-key suffix)
  - `RM_TARGET_CODES`
  - `RM_STATUS_CODES`
  - `GOVERNANCE_LEVELS` (chr)
  - `TENET_LEVELS` (chr)
  - `RM_REGISTER_COLUMNS` (chr, ordered column names)
- **Functions:**
  - `empty_measures_df() -> data.frame` with 0 rows and all `RM_REGISTER_COLUMNS`
  - `rm_reverse_label_map(force = FALSE) -> list(type, target, status)`, each a named chr label → code (cached)
  - `normalize_response_measures(df) -> data.frame`. Accepts NULL, a data frame, or a list of row lists; returns exactly `RM_REGISTER_COLUMNS` with labels mapped to codes. Idempotent.
  - `suggest_rm_target(ebm_code) -> chr(1)`: a code from `RM_TARGET_CODES`, or "" when there is no suggestion
  - `ebm_code_choices(kind, i18n) -> named chr`: names are labels, values are codes; the first entry is `""`
  - `rm_display_label(vocab, code, i18n) -> chr` (vectorised). `vocab` ∈ {type, target, status, kind, governance_level, ebm_code}. Falls back to the raw value.
  - `encode_ids(x) -> chr(1)`, `decode_ids(s) -> chr`

- [ ] **Step 1: Write the failing tests**

```r
# tests/testthat/test-response-measures-schema.R
# WS-3a: response register schema — codes in data, labels on display, scalar columns.
library(testthat)

test_that("empty register has exactly the schema columns, character except Cost", {
  df <- empty_measures_df()
  expect_equal(names(df), RM_REGISTER_COLUMNS)
  expect_equal(nrow(df), 0L)
  expect_type(df$Cost, "double")
  for (cl in setdiff(RM_REGISTER_COLUMNS, "Cost")) expect_type(df[[cl]], "character")
  expect_true(all(paste0("Tenet_", EBM_TENETS$code) %in% RM_REGISTER_COLUMNS))
})

test_that("reverse map resolves the label in every language to the code", {
  m <- rm_reverse_label_map(force = TRUE)
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  for (l in c("en","es","fr","de","lt","pt","it","no","el")) {
    expect_equal(unname(m$type[tr[["modules.response.measures.regulatory"]][[l]]]), "regulatory", info = l)
    expect_equal(unname(m$target[tr[["modules.response.measures.multiple_levels"]][[l]]]), "multiple", info = l)
    expect_equal(unname(m$status[tr[["modules.response.measures.partially_implemented"]][[l]]]), "partially_implemented", info = l)
  }
})

test_that("normalize maps legacy labels to codes, keeps unresolvable text, is idempotent", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  legacy <- data.frame(ID = c("RM_1", "RM_2"), Name = c("a", "b"),
                       Type = c(tr[["modules.response.measures.economic"]]$lt, "hand typed"),
                       Target = c(tr[["modules.response.measures.pressures"]]$de, ""),
                       Status = c(tr[["modules.response.measures.implemented"]]$el, "planned"),
                       Cost = c(5, 3), stringsAsFactors = FALSE)
  out <- normalize_response_measures(legacy)
  expect_equal(names(out), RM_REGISTER_COLUMNS)
  expect_equal(out$Type, c("economic", "hand typed"))
  expect_equal(out$Target, c("pressures", ""))
  expect_equal(out$Status, c("implemented", "planned"))
  expect_equal(out$Kind, c("", ""))
  expect_identical(normalize_response_measures(out), out)
})

test_that("normalize accepts NULL, empty list and list-of-rows (simplifyVector = FALSE)", {
  expect_equal(nrow(normalize_response_measures(NULL)), 0L)
  expect_equal(nrow(normalize_response_measures(list())), 0L)
  rows <- list(list(ID = "RM_1", Name = "x", Type = "regulatory", Cost = 2,
                    ImplementingStakeholders = "SH_1;SH_2", Tenet_ecol_effective = "full"))
  out <- normalize_response_measures(rows)
  expect_equal(out$ImplementingStakeholders, "SH_1;SH_2")
  expect_equal(out$Tenet_ecol_effective, "full")
  expect_equal(out$Cost, 2)
})

test_that("suggest_rm_target follows WS-1 dapsiwrm_target; instruments suggest nothing", {
  expect_equal(suggest_rm_target("output"), "pressures")
  expect_equal(suggest_rm_target("input.effort"), "activities")
  expect_equal(suggest_rm_target("restoration.habitat"), "state")
  expect_equal(suggest_rm_target("spatial.year_round"), "multiple")
  expect_equal(suggest_rm_target("1.1"), "")
  expect_equal(suggest_rm_target(""), "")
  expect_equal(suggest_rm_target(NULL), "")
})

test_that("ebm_code_choices: types only for instruments, all measures for measures, blank first", {
  idt <- list(t = function(k) k)
  ins <- ebm_code_choices("instrument", idt)
  expect_equal(unname(ins[1]), "")
  expect_setequal(unname(ins[-1]), EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"])
  expect_setequal(unname(ebm_code_choices("measure", idt)[-1]), EBM_MANAGEMENT_MEASURES$code)
  expect_equal(unname(ebm_code_choices("", idt)), "")
})

test_that("display labels translate codes and fall back to raw text", {
  lab <- list(t = function(k) paste0("T:", k))
  expect_equal(rm_display_label("type", c("regulatory", "hand typed", ""), lab),
               c("T:modules.response.measures.regulatory", "hand typed", ""))
  expect_equal(rm_display_label("target", "multiple", lab), "T:modules.response.measures.multiple_levels")
  expect_equal(rm_display_label("governance_level", "eu", lab), "T:modules.response.governance.level.eu")
  expect_equal(rm_display_label("ebm_code", "output", lab), "T:modules.wp5_vocabulary.measure.output")
  expect_equal(rm_display_label("ebm_code", "1.1", lab), "T:modules.wp5_vocabulary.instrument.1_1")
})

test_that("stakeholder id codec round-trips and drops blanks", {
  expect_equal(encode_ids(c("SH_1", "", "SH_2")), "SH_1;SH_2")
  expect_equal(encode_ids(NULL), "")
  expect_equal(decode_ids("SH_1;SH_2"), c("SH_1", "SH_2"))
  expect_equal(decode_ids(""), character(0))
})

test_that("governance translations exist in all 9 languages", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_governance.json"),
                           simplifyVector = FALSE)$translation
  keys <- c(paste0("modules.response.governance.level.", GOVERNANCE_LEVELS),
            paste0("modules.response.governance.kind.", c("instrument", "measure")),
            paste0("modules.response.governance.tenet_level.", c(TENET_LEVELS, "not_assessed")))
  for (k in keys) for (l in c("en","es","fr","de","lt","pt","it","no","el"))
    expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
})
```

- [ ] **Step 2: Run to verify fail**

Run (from `MarineSABRES_SES_Shiny/`): `"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-response-measures-schema.R')"`
Expected: FAIL with `object 'RM_REGISTER_COLUMNS' not found`.

- [ ] **Step 3a: Constants** (append to `constants.R` before `# END OF CONSTANTS`)

```r
# ============================================================================
# RESPONSE REGISTER CODES (spec 2026-10-11 WS-3a) — codes stored; labels via
# existing modules.response.measures.<key> translations (values = key suffix)
# ============================================================================
RM_TYPE_CODES <- c(regulatory = "regulatory", economic = "economic", educational = "educational",
                   technical = "technical", institutional = "institutional",
                   voluntary = "voluntary", mixed = "mixed")
RM_TARGET_CODES <- c(drivers = "drivers", activities = "activities", pressures = "pressures",
                     state = "state", multiple = "multiple_levels")
RM_STATUS_CODES <- c(proposed = "proposed", planned = "planned", implemented = "implemented",
                     partially_implemented = "partially_implemented", abandoned = "abandoned")
GOVERNANCE_LEVELS <- c("local", "island", "regional", "national", "eu", "regional_sea", "international")
TENET_LEVELS <- c("minimal", "intermediate", "full")   # intermediate: ecol_effective only (EBM framework)

RM_REGISTER_COLUMNS <- c(
  "ID", "Name", "Type", "Target", "Description", "Mechanism", "TargetElement",
  "Effectiveness", "Feasibility", "Cost", "Status", "Stakeholders", "Barriers", "DateAdded",
  "Kind", "EbmCode", "GovernanceLevel", "CompetentAuthority", "LegalBasis",
  "ImplementingStakeholders", "PairedWith",
  paste0("Tenet_", c("ecol_effective", "tech_feasible", "econ_efficient",
                     "econ_viable", "socially_desirable", "ethically_defensible", "culturally_inclusive",
                     "legally_permissible", "admin_achievable", "communicable", "politically_expedient"))
)
```

- [ ] **Step 3b: `functions/response_measures_schema.R`**

```r
# functions/response_measures_schema.R
# Response-measures register schema (spec 2026-10-11 WS-3a).
# Codes are stored; labels are produced only for display. All columns scalar.

.rm_schema_env <- new.env(parent = emptyenv())

#' Empty register with every schema column (character, Cost numeric)
empty_measures_df <- function() {
  cols <- lapply(RM_REGISTER_COLUMNS, function(cl) if (cl == "Cost") numeric(0) else character(0))
  as.data.frame(setNames(cols, RM_REGISTER_COLUMNS), stringsAsFactors = FALSE)
}

#' Reverse map label -> code for Type / Target / Status, from ALL translation files, all languages
rm_reverse_label_map <- function(force = FALSE) {
  if (!force && !is.null(.rm_schema_env$map)) return(.rm_schema_env$map)
  root <- if (exists("PROJECT_ROOT")) PROJECT_ROOT else "."
  files <- list.files(file.path(root, "translations"), pattern = "[.]json$", recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("_merged|backup", basename(files))]
  vocabs <- list(type = RM_TYPE_CODES, target = RM_TARGET_CODES, status = RM_STATUS_CODES)
  out <- lapply(vocabs, function(v) character(0))
  for (f in files) {
    tr <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE)$translation, error = function(e) NULL)
    if (is.null(tr)) next
    for (vn in names(vocabs)) {
      v <- vocabs[[vn]]
      for (code in names(v)) {
        entry <- tr[[paste0("modules.response.measures.", v[[code]])]]
        if (is.null(entry)) next
        labels <- unique(trimws(unlist(entry)))
        labels <- labels[nzchar(labels)]
        out[[vn]] <- c(out[[vn]], setNames(rep(code, length(labels)), labels))
      }
    }
  }
  out <- lapply(out, function(m) m[!duplicated(names(m))])
  .rm_schema_env$map <- out
  out
}

.map_codes <- function(x, map, codes) {
  x <- as.character(x); x[is.na(x)] <- ""
  hit <- !(x %in% codes) & x %in% names(map)
  x[hit] <- unname(map[x[hit]])
  x
}

#' Normalize a register to the WS-3a schema (idempotent)
#' @param df NULL, data.frame, or list of row lists (jsonlite simplifyVector = FALSE)
normalize_response_measures <- function(df) {
  if (is.null(df) || (is.list(df) && !is.data.frame(df) && length(df) == 0)) return(empty_measures_df())
  if (is.list(df) && !is.data.frame(df)) {
    df <- tryCatch(do.call(rbind, lapply(df, function(r) {
      r <- lapply(r, function(v) if (is.null(v) || length(v) == 0) NA else if (length(v) > 1) paste(v, collapse = ";") else v)
      as.data.frame(r, stringsAsFactors = FALSE)
    })), error = function(e) NULL)
    if (is.null(df)) return(empty_measures_df())
  }
  if (!is.data.frame(df)) return(empty_measures_df())
  n <- nrow(df)
  out <- lapply(RM_REGISTER_COLUMNS, function(cl) {
    v <- if (cl %in% names(df)) df[[cl]] else if (cl == "Cost") rep(NA_real_, n) else rep("", n)
    if (cl == "Cost") return(suppressWarnings(as.numeric(v)))
    v <- as.character(unlist(lapply(v, function(e) if (is.null(e) || length(e) == 0) "" else paste(e, collapse = ";"))))
    v[is.na(v)] <- ""
    v
  })
  out <- as.data.frame(setNames(out, RM_REGISTER_COLUMNS), stringsAsFactors = FALSE)
  m <- rm_reverse_label_map()
  out$Type   <- .map_codes(out$Type,   m$type,   names(RM_TYPE_CODES))
  out$Target <- .map_codes(out$Target, m$target, names(RM_TARGET_CODES))
  out$Status <- .map_codes(out$Status, m$status, names(RM_STATUS_CODES))
  out
}

#' Suggested register Target code for an EBM code (management measures only)
suggest_rm_target <- function(ebm_code) {
  if (is.null(ebm_code) || !nzchar(ebm_code)) return("")
  t <- EBM_MANAGEMENT_MEASURES$dapsiwrm_target[EBM_MANAGEMENT_MEASURES$code == ebm_code]
  if (length(t) == 0) return("")
  switch(t, "A" = "activities", "P" = "pressures", "C" = "state", "A|P|C" = "multiple", "")
}

#' EBM picker choices for a kind; names = labels, values = codes; "" first
ebm_code_choices <- function(kind, i18n) {
  if (identical(kind, "instrument")) {
    codes <- EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"]
    labels <- paste(codes, wp5_vocab_label("instrument", codes, i18n))
  } else if (identical(kind, "measure")) {
    codes <- EBM_MANAGEMENT_MEASURES$code
    labels <- wp5_vocab_label("measure", codes, i18n)
  } else {
    return(c(" " = ""))
  }
  c(" " = "", setNames(codes, labels))
}

#' Display labels for register codes; unknown values pass through unchanged
rm_display_label <- function(vocab, code, i18n) {
  code <- as.character(code); code[is.na(code)] <- ""
  key_for <- function(cd) {
    switch(vocab,
      type   = if (cd %in% names(RM_TYPE_CODES))   paste0("modules.response.measures.", RM_TYPE_CODES[[cd]]),
      target = if (cd %in% names(RM_TARGET_CODES)) paste0("modules.response.measures.", RM_TARGET_CODES[[cd]]),
      status = if (cd %in% names(RM_STATUS_CODES)) paste0("modules.response.measures.", RM_STATUS_CODES[[cd]]),
      kind   = if (cd %in% c("instrument", "measure")) paste0("modules.response.governance.kind.", cd),
      governance_level = if (cd %in% GOVERNANCE_LEVELS) paste0("modules.response.governance.level.", cd),
      NULL)
  }
  vapply(code, function(cd) {
    if (!nzchar(cd)) return("")
    if (vocab == "ebm_code") {
      if (cd %in% EBM_MANAGEMENT_MEASURES$code) return(wp5_vocab_label("measure", cd, i18n))
      if (cd %in% EBM_POLICY_INSTRUMENTS$code) return(wp5_vocab_label("instrument", cd, i18n))
      return(cd)
    }
    k <- key_for(cd)
    if (is.null(k)) return(cd)
    lbl <- tryCatch(as.character(i18n$t(k)), error = function(e) cd)
    if (length(lbl) != 1 || !nzchar(lbl)) cd else lbl
  }, character(1), USE.NAMES = FALSE)
}

#' Stakeholder-id codec (scalar column)
encode_ids <- function(x) {
  x <- as.character(unlist(x)); x <- x[!is.na(x) & nzchar(x)]
  paste(x, collapse = ";")
}
decode_ids <- function(s) {
  if (is.null(s) || is.na(s) || !nzchar(s)) return(character(0))
  strsplit(s, ";", fixed = TRUE)[[1]]
}
```

- [ ] **Step 3c: `translations/modules/response_governance.json`**

Use the same format as `translations/modules/wp5_mechanisms.json`, with genuine text in all 9 languages. The English source strings:

| Key suffix (`modules.response.governance.`) | English |
|---|---|
| `section_title` | EBM classification and governance |
| `kind` | Instrument or measure |
| `kind.instrument` | Policy instrument |
| `kind.measure` | Management measure |
| `ebm_code` | EBM type |
| `ebm_code_hint` | Choosing a management-measure type suggests the DAPSIWRM target above. |
| `level` | Governance level |
| `level.local` / `island` / `regional` / `national` / `eu` / `regional_sea` / `international` | Local / Island / Regional / National / EU / Regional sea / International |
| `competent_authority` | Competent authority |
| `legal_basis` | Legal basis |
| `implementing_stakeholders` | Implementing stakeholders |
| `no_stakeholders_hint` | Add stakeholders under PIMS › Stakeholders to link them here. |
| `paired_with` | Paired with (management strategy) |
| `tenets_title` | Appraisal against the 11 tenets |
| `tenet_level.minimal` / `intermediate` / `full` / `not_assessed` | Minimal compliance / Intermediate / Full compliance / Not assessed |

Write the file with a small generator, as in WS-1 Task 5, so the 9 columns per key stay aligned. Check EU terms in IATE.

- [ ] **Step 3d: Source the schema file in `global.R`**

Add `source("functions/response_measures_schema.R", local = FALSE)` after the `wp5_vocabulary.R` line.

- [ ] **Step 4: Run to verify pass**

Run the schema test file → all PASS. Then run `test-functions-sourced-in-app.R` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/constants.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/functions/response_measures_schema.R MarineSABRES_SES_Shiny/translations/modules/response_governance.json MarineSABRES_SES_Shiny/tests/testthat/test-response-measures-schema.R
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "feat(response): register schema — codes, label->code reverse map, governance vocab (WS-3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Normalize on every load path; JSON round-trips

**Files:**
- Modify: `functions/data_structure.R`
  - In `normalize_json_project_data()`, just before the WS-0 `migrate_legacy_scenarios(data)` line, normalize the register.
  - In `create_empty_project()`, build `measures` from `empty_measures_df()`.
- Modify: `modules/response_module.R`
  - The `observeEvent(project_data_reactive()$project_id, …)` loader (~:430) normalizes `rm$measures`.
  - The `response_data$measures` initial value becomes `empty_measures_df()`.
- Test: append to `tests/testthat/test-response-measures-schema.R`

**Interfaces:** Consumes Task 1. Produces the guarantee that `pd$data$response_measures$measures` is always schema-shaped after load.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---- Task 2: every load path; JSON round-trips -----------------------------------
mk_project_with_register <- function() {
  p <- create_empty_project("t")
  p$data$response_measures$measures <- normalize_response_measures(data.frame(
    ID = c("RM_1", "RM_2"), Name = c("Quota", "Moorings"), Type = c("regulatory", "economic"),
    Target = c("pressures", "activities"), Status = c("planned", "proposed"), Cost = c(4, 7),
    Kind = c("measure", "instrument"), EbmCode = c("output", "3.4"), GovernanceLevel = c("national", "local"),
    ImplementingStakeholders = c("SH_1;SH_2", ""), PairedWith = c("RM_2", "RM_1"),
    Tenet_ecol_effective = c("intermediate", ""), Tenet_legally_permissible = c("full", "minimal"),
    stringsAsFactors = FALSE))
  p
}

test_that("create_empty_project uses the register schema", {
  expect_equal(names(create_empty_project("t")$data$response_measures$measures), RM_REGISTER_COLUMNS)
})

test_that("register survives JSON round-trip with simplifyVector = TRUE and FALSE", {
  p <- mk_project_with_register()
  js <- jsonlite::toJSON(p, auto_unbox = TRUE, null = "null", na = "null")
  for (sv in c(TRUE, FALSE)) {
    back <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = sv))
    m <- back$data$response_measures$measures
    expect_equal(names(m), RM_REGISTER_COLUMNS, info = sv)
    expect_equal(m$ImplementingStakeholders, c("SH_1;SH_2", ""), info = sv)
    expect_equal(m$Tenet_ecol_effective, c("intermediate", ""), info = sv)
    expect_equal(m$EbmCode, c("output", "3.4"), info = sv)
    expect_equal(m$Cost, c(4, 7), info = sv)
  }
})

test_that("legacy Lithuanian-label register is migrated on project load", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "response_measures.json"),
                           simplifyVector = FALSE)$translation
  p <- create_empty_project("t")
  p$data$response_measures$measures <- data.frame(
    ID = "RM_1", Name = "x", Type = tr[["modules.response.measures.regulatory"]]$lt,
    Target = tr[["modules.response.measures.state"]]$lt, Status = tr[["modules.response.measures.planned"]]$lt,
    Cost = 5, stringsAsFactors = FALSE)
  out <- normalize_and_reconcile_project(p)$data$response_measures$measures
  expect_equal(c(out$Type, out$Target, out$Status), c("regulatory", "state", "planned"))
})
```

- [ ] **Step 2: Run to verify fail**

Run the schema test file. Expected: FAIL. `create_empty_project` still returns the old 14 columns, and normalization is not applied.

- [ ] **Step 3: Implement**

In `functions/data_structure.R`, `create_empty_project()`: replace the literal `measures = data.frame(ID = character(), … DateAdded = character())` inside `response_measures = list(…)` with `measures = if (exists("empty_measures_df", mode = "function")) empty_measures_df() else data.frame(),`. The guard exists because `tests/run_json_loading_tests.R` sources `data_structure.R` without `global.R`. Also add `source(file.path(project_root, "functions", "response_measures_schema.R"), local = FALSE)` to that runner, after its `data_structure.R` line. The schema file needs `constants.R` and `wp5_vocabulary.R` only at call time, so if the runner lacks them, add those two `source()` lines as well. Then run `Rscript tests/run_json_loading_tests.R` → PASS.

In `normalize_json_project_data()`, before `data <- migrate_legacy_scenarios(data)`:

```r
  # Response register: codes + full schema on every JSON load path (WP5 WS-3a)
  if (is.list(data$data) && is.list(data$data$response_measures) &&
      exists("normalize_response_measures", mode = "function")) {
    data$data$response_measures$measures <- normalize_response_measures(data$data$response_measures$measures)
  }
```

In `modules/response_module.R`, inside `response_data <- reactiveValues(` replace the literal `measures = data.frame(…)` with `measures = empty_measures_df(),`. In the project loader:

```r
      if (!is.null(rm$measures))   response_data$measures   <- normalize_response_measures(rm$measures)
```

- [ ] **Step 4: Run to verify pass**

Run each of the following:
- the schema test file → all PASS;
- `test-json-project-loading.R` → PASS, same count as before;
- `test-response-module.R` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/functions/data_structure.R MarineSABRES_SES_Shiny/modules/response_module.R MarineSABRES_SES_Shiny/tests/testthat/test-response-measures-schema.R
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "fix(response): normalize register to codes on every load path (WS-3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Form writes codes; display translates codes

**Files:**
- Modify: `modules/response_module.R`
  - `rm_type`, `rm_target` and `rm_status` `selectInput`s (~:40-52) become named choices (code values).
  - `translate_levels_for_display()` (~:370) also translates Type, Target, Status, Kind, EbmCode and GovernanceLevel.
- Test: append to `tests/testthat/test-response-module.R`

**Interfaces:** Consumes `rm_display_label()`, `RM_*_CODES` and `normalize_response_measures()`.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---- WS-3a Task 3: codes in data, labels on display ------------------------------
rm_add <- function(inputs) {
  proj <- create_empty_project("t"); pd <- reactiveVal(proj); out <- NULL
  testServer(real_response_measures_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    do.call(session$setInputs, inputs)
    session$setInputs(add_response = 1)
    out <<- pd()$data$response_measures$measures
  })
  out
}

test_that("adding a measure stores codes, not translated labels", {
  m <- rm_add(list(rm_name = "Quota cut", rm_type = "regulatory", rm_target = "pressures",
                   rm_status = "planned", rm_description = "", rm_mechanism = "", rm_target_element = "",
                   rm_effectiveness = "HIGH", rm_feasibility = "MEDIUM", rm_cost = 4,
                   rm_stakeholders = "", rm_barriers = ""))
  expect_equal(c(m$Type, m$Target, m$Status), c("regulatory", "pressures", "planned"))
  expect_equal(names(m), RM_REGISTER_COLUMNS)
})

test_that("form choices are codes with translated names", {
  ui <- as.character(response_measures_ui("t", make_test_i18n()))
  expect_match(ui, 'value="regulatory"', fixed = TRUE)
  expect_match(ui, 'value="partially_implemented"', fixed = TRUE)
  expect_match(ui, "modules.response.measures.regulatory", fixed = TRUE)
})
```

- [ ] **Step 2: Run to verify fail**

Run `test-response-module.R`. Expected: FAIL, because `Type` stores the label text (`"modules.response.measures.regulatory"` under the identity stub) and the UI values are labels.

- [ ] **Step 3: Implement**

Replace the three `selectInput` choice vectors:

```r
                  selectInput(ns("rm_type"), i18n$t("common.labels.response_type"),
                             choices = c(" " = "", setNames(names(RM_TYPE_CODES),
                               vapply(RM_TYPE_CODES, function(k) i18n$t(paste0("modules.response.measures.", k)), character(1)))))
```

```r
                  selectInput(ns("rm_target"), i18n$t("modules.response.measures.targets"),
                             choices = c(" " = "", setNames(names(RM_TARGET_CODES),
                               vapply(RM_TARGET_CODES, function(k) i18n$t(paste0("modules.response.measures.", k)), character(1)))))
```

```r
                  selectInput(ns("rm_status"), i18n$t("common.labels.implementation_status"),
                             choices = setNames(names(RM_STATUS_CODES),
                               vapply(RM_STATUS_CODES, function(k) i18n$t(paste0("modules.response.measures.", k)), character(1))))
```

Directly above them, add `# i18n-ref:` sentinel lines for the 17 keys:

```r
# i18n-ref: modules.response.measures.regulatory
# i18n-ref: modules.response.measures.economic
# i18n-ref: modules.response.measures.educational
# i18n-ref: modules.response.measures.technical
# i18n-ref: modules.response.measures.institutional
# i18n-ref: modules.response.measures.voluntary
# i18n-ref: modules.response.measures.mixed
# i18n-ref: modules.response.measures.drivers
# i18n-ref: modules.response.measures.activities
# i18n-ref: modules.response.measures.pressures
# i18n-ref: modules.response.measures.state
# i18n-ref: modules.response.measures.multiple_levels
# i18n-ref: modules.response.measures.proposed
# i18n-ref: modules.response.measures.planned
# i18n-ref: modules.response.measures.implemented
# i18n-ref: modules.response.measures.partially_implemented
# i18n-ref: modules.response.measures.abandoned
```

Extend `translate_levels_for_display()`:

```r
    translate_levels_for_display <- function(df) {
      if (is.null(df) || nrow(df) == 0) return(df)
      if ("Effectiveness" %in% names(df)) df$Effectiveness <- vapply(df$Effectiveness, level_label, character(1))
      if ("Feasibility"   %in% names(df)) df$Feasibility   <- vapply(df$Feasibility,   level_label, character(1))
      for (pair in list(c("Type", "type"), c("Target", "target"), c("Status", "status"), c("Kind", "kind"),
                        c("EbmCode", "ebm_code"), c("GovernanceLevel", "governance_level"))) {
        if (pair[1] %in% names(df)) df[[pair[1]]] <- rm_display_label(pair[2], df[[pair[1]]], i18n)
      }
      df
    }
```

In the add handler, build the row through the schema so the columns always match:

```r
      new_row <- normalize_response_measures(data.frame(
        ID = new_id, Name = input$rm_name, Type = input$rm_type, Target = input$rm_target %||% "",
        Description = input$rm_description %||% "", Mechanism = input$rm_mechanism %||% "",
        TargetElement = input$rm_target_element %||% "", Effectiveness = input$rm_effectiveness %||% "",
        Feasibility = input$rm_feasibility %||% "", Cost = input$rm_cost %||% NA_real_,
        Status = input$rm_status %||% "", Stakeholders = input$rm_stakeholders %||% "",
        Barriers = input$rm_barriers %||% "", DateAdded = as.character(Sys.Date()),
        stringsAsFactors = FALSE))
      response_data$measures <- rbind(normalize_response_measures(response_data$measures), new_row)
```

- [ ] **Step 4: Run to verify pass**

Run `test-response-module.R` → all PASS (including the WS-2 pane tests). Run `test-i18n-enforcement.R` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/modules/response_module.R MarineSABRES_SES_Shiny/tests/testthat/test-response-module.R
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "fix(response): Type/Target/Status store codes; labels translated only for display (WS-3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: EBM classification, governance, stakeholders, pairing

**Files:**
- Modify: `modules/response_module.R`. Add the panel in the UI after the "barriers" row, before `actionButton(ns("add_response"))`. Add observers, add-handler fields, and new visible columns.
- Test: append to `tests/testthat/test-response-module.R`

**Interfaces:** Consumes `ebm_code_choices()`, `suggest_rm_target()`, `encode_ids()` and `GOVERNANCE_LEVELS`.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---- WS-3a Task 4: classification + governance fields --------------------------
base_inputs <- list(rm_name = "Spatial closure", rm_type = "regulatory", rm_target = "multiple",
                    rm_status = "proposed", rm_description = "", rm_mechanism = "", rm_target_element = "",
                    rm_effectiveness = "", rm_feasibility = "", rm_cost = 5, rm_stakeholders = "", rm_barriers = "")

test_that("classification and governance fields are saved as codes/scalars", {
  m <- rm_add(c(base_inputs, list(rm_kind = "measure", rm_ebm_code = "spatial.seasonal",
                                  rm_gov_level = "regional_sea", rm_competent_authority = "Park authority",
                                  rm_legal_basis = "Law 394/1991", rm_impl_stakeholders = c("SH_1", "SH_3"),
                                  rm_paired_with = "")))
  expect_equal(c(m$Kind, m$EbmCode, m$GovernanceLevel), c("measure", "spatial.seasonal", "regional_sea"))
  expect_equal(m$ImplementingStakeholders, "SH_1;SH_3")
  expect_equal(c(m$CompetentAuthority, m$LegalBasis), c("Park authority", "Law 394/1991"))
})

test_that("measure with an empty EBM panel and no PIMS stakeholders still saves", {
  m <- rm_add(base_inputs)
  expect_equal(nrow(m), 1L)
  expect_equal(c(m$Kind, m$EbmCode, m$ImplementingStakeholders, m$PairedWith), c("", "", "", ""))
})

test_that("UI has the classification panel with i18n chrome", {
  ui <- as.character(response_measures_ui("t", make_test_i18n()))
  for (k in c("section_title", "kind", "ebm_code", "level", "competent_authority", "legal_basis",
              "implementing_stakeholders", "paired_with"))
    expect_match(ui, paste0("modules.response.governance.", k), fixed = TRUE)
})
```

- [ ] **Step 2: Run to verify fail**

Run `test-response-module.R`. Expected: FAIL, because `Kind` etc. are empty or missing in the UI.

- [ ] **Step 3: Implement**

UI (insert after the barriers `fluidRow`):

```r
              # i18n-ref: modules.response.governance.kind.instrument
              # i18n-ref: modules.response.governance.kind.measure
              tags$details(class = "mt-2 mb-2",
                tags$summary(strong(i18n$t("modules.response.governance.section_title"))),
                fluidRow(
                  column(3, selectInput(ns("rm_kind"), i18n$t("modules.response.governance.kind"),
                    choices = c(" " = "", setNames(c("instrument", "measure"),
                      c(i18n$t("modules.response.governance.kind.instrument"),
                        i18n$t("modules.response.governance.kind.measure")))))),
                  column(5, selectizeInput(ns("rm_ebm_code"), i18n$t("modules.response.governance.ebm_code"),
                    choices = c(" " = ""), options = list(placeholder = "")),
                    tags$small(class = "text-muted", i18n$t("modules.response.governance.ebm_code_hint"))),
                  column(4, selectInput(ns("rm_gov_level"), i18n$t("modules.response.governance.level"),
                    choices = c(" " = "", setNames(GOVERNANCE_LEVELS,
                      vapply(GOVERNANCE_LEVELS, function(g) i18n$t(paste0("modules.response.governance.level.", g)), character(1))))))
                ),
                fluidRow(
                  column(4, textInput(ns("rm_competent_authority"), i18n$t("modules.response.governance.competent_authority"))),
                  column(4, textInput(ns("rm_legal_basis"), i18n$t("modules.response.governance.legal_basis"))),
                  column(4, selectInput(ns("rm_paired_with"), i18n$t("modules.response.governance.paired_with"), choices = c(" " = "")))
                ),
                fluidRow(column(12,
                  selectizeInput(ns("rm_impl_stakeholders"), i18n$t("modules.response.governance.implementing_stakeholders"),
                    choices = NULL, multiple = TRUE),
                  tags$small(class = "text-muted", i18n$t("modules.response.governance.no_stakeholders_hint"))
                ))
              ),
```

Add the governance-level sentinels above that block:

```r
# i18n-ref: modules.response.governance.level.local
# i18n-ref: modules.response.governance.level.island
# i18n-ref: modules.response.governance.level.regional
# i18n-ref: modules.response.governance.level.national
# i18n-ref: modules.response.governance.level.eu
# i18n-ref: modules.response.governance.level.regional_sea
# i18n-ref: modules.response.governance.level.international
```

Server (after the add handler):

```r
    observeEvent(input$rm_kind, {
      updateSelectizeInput(session, "rm_ebm_code", choices = ebm_code_choices(input$rm_kind, i18n), selected = "")
    }, ignoreInit = TRUE)

    observeEvent(input$rm_ebm_code, {
      tgt <- suggest_rm_target(input$rm_ebm_code)
      if (nzchar(tgt)) updateSelectInput(session, "rm_target", selected = tgt)
    }, ignoreInit = TRUE)

    observe({
      sh <- tryCatch(project_data_reactive()$data$pims$stakeholders, error = function(e) NULL)
      ch <- if (is.data.frame(sh) && nrow(sh) > 0) setNames(as.character(sh$ID), paste0(sh$Name, " (", sh$ID, ")")) else character(0)
      updateSelectizeInput(session, "rm_impl_stakeholders", choices = ch, server = FALSE)
    })

    observe({
      m <- response_data$measures
      ch <- c(" " = "", if (nrow(m) > 0) setNames(m$ID, paste0(m$ID, " - ", m$Name)))
      updateSelectInput(session, "rm_paired_with", choices = ch)
    })
```

In the add handler's `data.frame(...)`, add:

```r
        Kind = input$rm_kind %||% "", EbmCode = input$rm_ebm_code %||% "",
        GovernanceLevel = input$rm_gov_level %||% "",
        CompetentAuthority = input$rm_competent_authority %||% "",
        LegalBasis = input$rm_legal_basis %||% "",
        ImplementingStakeholders = encode_ids(input$rm_impl_stakeholders),
        PairedWith = input$rm_paired_with %||% "",
```

In the clear-inputs block, add:

```r
      updateTextInput(session, "rm_competent_authority", value = "")
      updateTextInput(session, "rm_legal_basis", value = "")
      updateSelectizeInput(session, "rm_impl_stakeholders", selected = character(0))
```

Add `"Kind", "EbmCode", "GovernanceLevel"` to `visible_cols` (~:656), after `"Target"`.

- [ ] **Step 4: Run to verify pass**

Run `test-response-module.R` → all PASS, then `test-i18n-enforcement.R` → PASS.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/modules/response_module.R MarineSABRES_SES_Shiny/tests/testthat/test-response-module.R
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "feat(response): EBM classification, governance level/authority/legal basis, implementing stakeholders, pairing (WS-3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: 11-tenet appraisal grid

**Files:**
- Modify: `modules/response_module.R` (a tenet grid inside the classification `tags$details`, plus the add-handler fields)
- Test: append to `tests/testthat/test-response-module.R`

**Interfaces:** Consumes `EBM_TENETS`, `TENET_LEVELS` and `wp5_vocab_label("tenet", …)`.

- [ ] **Step 1: Write the failing tests** (append)

```r
# ---- WS-3a Task 5: tenet appraisal -----------------------------------------------
test_that("tenet levels are saved per tenet; intermediate offered only for ecol_effective", {
  m <- rm_add(c(base_inputs, list(rm_tenet_ecol_effective = "intermediate",
                                  rm_tenet_legally_permissible = "full", rm_tenet_communicable = "minimal")))
  expect_equal(c(m$Tenet_ecol_effective, m$Tenet_legally_permissible, m$Tenet_communicable, m$Tenet_econ_viable),
               c("intermediate", "full", "minimal", ""))
  ui <- as.character(response_measures_ui("t", make_test_i18n()))
  expect_match(ui, "modules.response.governance.tenets_title", fixed = TRUE)
  ecol <- regmatches(ui, regexpr('(?s)id="t-rm_tenet_ecol_effective".*?</select>', ui, perl = TRUE))
  comm <- regmatches(ui, regexpr('(?s)id="t-rm_tenet_communicable".*?</select>', ui, perl = TRUE))
  expect_match(ecol, 'value="intermediate"', fixed = TRUE)
  expect_false(grepl('value="intermediate"', comm, fixed = TRUE))
})
```

- [ ] **Step 2: Run to verify fail**

Run `test-response-module.R`. Expected: FAIL, because there are no tenet inputs.

- [ ] **Step 3: Implement**

Inside the classification `tags$details`, after the stakeholders row:

```r
                # i18n-ref: modules.response.governance.tenet_level.minimal
                # i18n-ref: modules.response.governance.tenet_level.intermediate
                # i18n-ref: modules.response.governance.tenet_level.full
                # i18n-ref: modules.response.governance.tenet_level.not_assessed
                h6(class = "mt-2", i18n$t("modules.response.governance.tenets_title")),
                fluidRow(lapply(EBM_TENETS$code, function(cd) {
                  lv <- if (cd == "ecol_effective") TENET_LEVELS else setdiff(TENET_LEVELS, "intermediate")
                  column(3, selectInput(ns(paste0("rm_tenet_", cd)), wp5_vocab_label("tenet", cd, i18n),
                    choices = c(setNames("", i18n$t("modules.response.governance.tenet_level.not_assessed")),
                                setNames(lv, vapply(lv, function(x) i18n$t(paste0("modules.response.governance.tenet_level.", x)), character(1))))))
                }))
```

In the add handler, build the tenet columns and pass them into `data.frame(...)`:

```r
      tenets <- setNames(lapply(EBM_TENETS$code, function(cd) input[[paste0("rm_tenet_", cd)]] %||% ""),
                         paste0("Tenet_", EBM_TENETS$code))
```

Splice them in with `data.frame(..., tenets, stringsAsFactors = FALSE)`, which turns the named list into columns. In the clear block, reset each with `updateSelectInput(session, paste0("rm_tenet_", cd), selected = "")` inside `for (cd in EBM_TENETS$code)`.

- [ ] **Step 4: Run to verify pass**

Run `test-response-module.R` → all PASS. Run `test-i18n-enforcement.R`, `test-i18n-english-fallback.R` and `test-i18n-placeholders.R` → PASS. Run `micromamba run -n shiny python scripts/_i18n_audit.py` → missing=0, hardcoded=0.

- [ ] **Step 5: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/modules/response_module.R MarineSABRES_SES_Shiny/tests/testthat/test-response-module.R
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "feat(response): 11-tenet appraisal per measure (WS-3a)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Full suite, CHANGELOG

- [ ] **Step 1: Full suite** (in the background; it may be killed if memory runs low, in which case report it and ask)

Run: `Rscript -e "res <- testthat::test_dir('tests/testthat', reporter='summary', stop_on_failure=FALSE); df <- as.data.frame(res); cat('TOTAL failed=', sum(df$failed), ' error=', sum(df$error), '\n')"`
Expected: 0 failures, apart from the known `test-ml-graph-features.R` timing flake.

- [ ] **Step 2: CHANGELOG** (under `[Unreleased]`)

```markdown
### Fixed (Response register stored translated labels — spec 2026-10-11 WS-3a)
- **Response type, target and status are stored as language-independent codes.** Previously the saved value was whatever language the user had active, so a project saved in Lithuanian showed Lithuanian values in other languages and could not be compared. Existing projects are converted on load, from labels in any of the 9 languages. Text that matches no label is kept unchanged.

### Added (Response register — EBM classification and governance, WS-3a)
- New collapsible section in "Add response measure":
  - EBM classification: policy instrument or management measure, with the WP5 EBM type. Choosing a measure type suggests the DAPSIWRM target.
  - Governance level, competent authority and legal basis.
  - Implementing stakeholders, linked to PIMS stakeholders.
  - Pairing into a management strategy (instrument + measure).
  - Appraisal against the 11 tenets (minimal / intermediate / full compliance).
- All fields are saved in projects and survive JSON save/load.
```

- [ ] **Step 3: Commit**

```bash
git -C "C:/Users/arturas.baziukas/wt-ws3" add MarineSABRES_SES_Shiny/CHANGELOG.md
git -C "C:/Users/arturas.baziukas/wt-ws3" commit -m "docs(changelog): WS-3a response register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Then do the whole-branch review and run superpowers:finishing-a-development-branch.
