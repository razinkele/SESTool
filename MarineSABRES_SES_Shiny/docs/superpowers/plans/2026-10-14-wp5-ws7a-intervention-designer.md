# WP5 WS-7a Intervention Designer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Designer (D5.3)" tab to the Intervention page that evaluates every allowed ordinal-weight combination of a new intervention node (mode A) and/or new edges between existing nodes (mode B), ranks them by the D5.3 criteria, and runs in a background R process.

**Architecture:** A pure engine file (`functions/intervention_designer.R`, no Shiny) turns a design (base matrix + variable edges with level sets) into a grid, evaluates it in sparse batched chunks, checks stability for successes, ranks, and runs a Boolean pre-check. A small job layer (`functions/intervention_designer_job.R`) runs the engine in a `callr::r_bg()` process. A sub-module (`modules/intervention_designer_module.R`) builds the design, starts and polls the job, and shows results; `modules/analysis_intervention.R` mounts it as a second tab.

**Tech Stack:** R 4.4, Shiny + bs4Dash, shiny.i18n, Matrix (sparse products), callr (background process), BoolNet (via existing `boolean_model()`), testthat 3.

**Spec:** `docs/superpowers/specs/2026-10-14-wp5-ws7a-intervention-designer-design.md` (read it first; §4 is normative). Parent: `docs/superpowers/specs/2026-10-11-wp5-practical-integration-specs.md` §WS-7.

## Global Constraints

- Work in the worktree `C:/Users/arturas.baziukas/wt-ws7a`, branch `feat/wp5-ws7a-intervention-designer`. Git root is one level above the app dir: use `git -C C:/Users/arturas.baziukas/wt-ws7a ...`; app files are under `MarineSABRES_SES_Shiny/`.
- Run R tests from the app dir with the user library first (the system library has a stale magrittr):
  `"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter='^<name>$', stop_on_failure=FALSE)"` where `<name>` is the test file name without `test-` and `.R`.
- `git commit -F -` does not work from the PowerShell tool; write the message to a scratch file and use `-F <file>`. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Levels: `INTERVENTION_GRID_LEVELS = c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)`; 0 = edge absent.
- Cap: `INTERVENTION_GRID_CAP = 50000`; above it, a seeded sample of 50,000 distinct indices.
- Steps 1000, window 100 (last 100 steps), rescale every 10 steps by the L1 norm.
- Criterion (a)/(b): strictly `> 0` at **each** of the last 100 steps (not a sign product).
- Criterion (c): all eigenvalues of `diag(rowSums(A)) - A` have `abs(Im) <= 1e-9`.
- Criterion (d): non-zero count over intervention edges (kind `"intervention"`); if the design has none, over all variable edges.
- Ranking: a desc, b desc, c desc, d asc, then grid order.
- Every new `functions/*.R` is sourced in `global.R` with a literal `source("functions/<file>.R", local = FALSE)` (checked by `test-functions-sourced-in-app.R`).
- All user-facing text through `i18n$t()`; new keys in `translations/modules/intervention_designer.json` in all 9 languages (`en es fr de lt pt it no el`). Dynamic key lookups need `# i18n-ref: <key>` sentinel comments.
- Module UI starts with `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)`.
- Logging via `.dyn_log()` / `debug_log()`, never `cat()`. User errors via `format_user_error(e, i18n = i18n, context_key = ...)`.
- Engine functions used by the worker must take every parameter explicitly (the worker has no `constants.R`).
- 7a writes nothing to project data.
- Release: 1.27.0.

## Review Focus

1. **Node labels with punctuation** ("P. oceanica extension", "Marine traffic (including anchoring)") are matrix dimnames and Boolean rule names; the pipeline must work with them. Pinned in Task 5 (fixture uses such labels) and Task 4 (pre-check with punctuated labels).
2. **Renaming the intervention after adding its edges** must carry the edges to the new name, not leave them pointing at the old one. Pinned in Task 8 (edges stored with a placeholder, substituted at run time).
3. **The network changes after a run.** The comparison plot for a selected row must use the network the run used (`result$base`), not the current one. Pinned in Task 8.
4. **Very large grids** (above 2^31 combinations, e.g. 12 edges × 7 levels) must sample 50,000 distinct indices without integer overflow. Pinned in Task 1.
5. **A failing worker** (engine error, crash, timeout) must show a translated error and re-enable Run. Pinned in Task 6 (job returns an error state) and Task 8 (module resets).

---

### Task 1: Constants, grid primitives, evidence priors

**Files:**
- Modify: `MarineSABRES_SES_Shiny/constants.R` (append a block after the WP5 impact-assessment block, end of file is fine)
- Create: `MarineSABRES_SES_Shiny/functions/intervention_designer.R`
- Modify: `MarineSABRES_SES_Shiny/functions/wp5_vocabulary.R` (add `get_intervention_ebm_codes()` after `get_allowed_graph_ops()`)
- Modify: `MarineSABRES_SES_Shiny/global.R:716` (add source line after `impact_assessment_view.R`)
- Test: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer.R`

**Interfaces:**
- Produces:
  - constants `INTERVENTION_GRID_LEVELS`, `INTERVENTION_GRID_CAP`, `INTERVENTION_CHUNK`, `INTERVENTION_N_STEPS`, `INTERVENTION_WINDOW`, `INTERVENTION_DEFAULT_SEED`, `INTERVENTION_TOP_K`, `INTERVENTION_JOB_TIMEOUT_S`, `INTERVENTION_EVIDENCE_PRIORS`
  - `.with_seed(seed, expr)` → value of `expr`, global RNG state restored
  - `ses_level_set(min_level, max_level, levels)` → numeric vector (subset of `levels` in `[min_level, max_level]`)
  - `ses_level_sets(edges, levels)` → list of numeric vectors, one per row of `edges` (`edges` has numeric `min_level`, `max_level`)
  - `ses_intervention_grid(level_sets, cap, seed)` → `list(n_total = <double>, sampled = <logical>, n_eval = <double>, indices = NULL | <sorted double vector, 1-based>)`
  - `ses_grid_decode(idx, level_sets)` → numeric matrix `length(level_sets) x length(idx)`; edge 1 varies fastest
  - `ses_evidence_prior_range(ebm_codes, priors)` → named numeric `c(min = , max = )`
  - `get_intervention_ebm_codes(id)` → character vector (possibly empty)

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-intervention-designer.R`:

```r
# tests/testthat/test-intervention-designer.R
# WS-7a intervention designer: pure engine (spec 2026-10-14 §4).
source_for_test("functions/intervention_designer.R")

LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)

test_that("constants match the spec", {
  expect_equal(INTERVENTION_GRID_LEVELS, LV)
  expect_equal(INTERVENTION_GRID_CAP, 50000)
  expect_equal(INTERVENTION_N_STEPS, 1000L)
  expect_equal(INTERVENTION_WINDOW, 100L)
})

test_that("level sets come from min/max ranges", {
  expect_equal(ses_level_set(-0.5, 0, LV), c(-0.5, -0.25, 0))
  expect_equal(ses_level_set(0, 1, LV), c(0, 0.25, 0.5, 1))
  expect_equal(ses_level_set(0.5, 0.25, LV), numeric(0))      # inverted range is empty
  e <- data.frame(min_level = c(-1, 0), max_level = c(1, 0.25))
  expect_equal(lengths(ses_level_sets(e, LV)), c(7L, 2L))
})

test_that("grid size, exhaustive vs sampled", {
  g <- ses_intervention_grid(list(1:7, 1:4), cap = 50000, seed = 1)
  expect_equal(g$n_total, 28); expect_false(g$sampled); expect_null(g$indices); expect_equal(g$n_eval, 28)
  g2 <- ses_intervention_grid(rep(list(1:7), 6), cap = 50000, seed = 1)   # 117,649
  expect_true(g2$sampled); expect_equal(g2$n_eval, 50000)
  expect_equal(length(unique(g2$indices)), 50000L)
  expect_true(all(g2$indices >= 1 & g2$indices <= 117649))
  expect_false(is.unsorted(g2$indices))
})

test_that("grids above 2^31 sample without overflow (review focus 4)", {
  g <- ses_intervention_grid(rep(list(LV), 12), cap = 50000, seed = 7)     # 7^12 = 13.8e9
  expect_equal(g$n_total, 7^12)
  expect_true(g$sampled)
  expect_equal(length(unique(g$indices)), 50000L)
  expect_true(max(g$indices) <= 7^12 && min(g$indices) >= 1)
  d <- ses_grid_decode(g$indices[1:5], rep(list(LV), 12))
  expect_equal(dim(d), c(12L, 5L))
  expect_true(all(d %in% LV))
})

test_that("empty designs and empty ranges are rejected", {
  expect_error(ses_intervention_grid(list(), cap = 10, seed = 1), "no variable edges")
  expect_error(ses_intervention_grid(list(1:3, numeric(0)), cap = 10, seed = 1), "empty level range")
})

test_that("mixed-radix decoding enumerates every combination once, edge 1 fastest", {
  sets <- list(c(-1, 0), c(0, 0.5, 1))
  d <- ses_grid_decode(1:6, sets)
  expect_equal(d[, 1], c(-1, 0)); expect_equal(d[, 2], c(0, 0)); expect_equal(d[, 3], c(-1, 0.5))
  expect_equal(nrow(unique(t(d))), 6L)
})

test_that("seeded sampling is reproducible and leaves the global RNG alone", {
  set.seed(99); before <- runif(1); set.seed(99)
  a <- ses_intervention_grid(rep(list(1:7), 6), cap = 50000, seed = 3)$indices
  after <- runif(1)
  expect_equal(before, after)
  b <- ses_intervention_grid(rep(list(1:7), 6), cap = 50000, seed = 3)$indices
  expect_identical(a, b)
})

test_that("evidence priors: behavioural weak, legal/output/spatial medium, else full", {
  P <- c(behavioural = 0.25, regulatory = 0.5)
  expect_equal(ses_evidence_prior_range(c("2.5"), P), c(min = -0.25, max = 0.25))
  expect_equal(ses_evidence_prior_range(c("1.1", "output"), P), c(min = -0.5, max = 0.5))
  expect_equal(ses_evidence_prior_range(c("spatial.year_round"), P), c(min = -0.5, max = 0.5))
  expect_equal(ses_evidence_prior_range(c("1.5", "2.4"), P), c(min = -0.25, max = 0.25))  # behavioural wins
  expect_equal(ses_evidence_prior_range(c("3.1"), P), c(min = -1, max = 1))
  expect_equal(ses_evidence_prior_range(character(0), P), c(min = -1, max = 1))
})

test_that("get_intervention_ebm_codes reads the WS-1 operations table", {
  load_wp5_intervention_ops(force_reload = TRUE)
  expect_equal(get_intervention_ebm_codes("nudge"), "2.5")
  expect_setequal(get_intervention_ebm_codes("quota_license"), c("1.1", "output", "input.capacity"))
  expect_equal(get_intervention_ebm_codes("cascade_creation"), character(0))
  expect_equal(get_intervention_ebm_codes("no_such_type"), character(0))
})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run (from `MarineSABRES_SES_Shiny/`): the Global Constraints command with filter `^intervention-designer$`.
Expected: FAIL / errors, e.g. `could not find function "ses_level_set"` and `object 'INTERVENTION_GRID_LEVELS' not found`.

- [ ] **Step 3: Add the constants**

Append to `constants.R`:

```r
# ============================================================================
# WP5 INTERVENTION DESIGNER (spec 2026-10-14 WS-7a)
# ============================================================================
# D5.3 ordinal grid (C§5.2): strong/medium/weak negative, none, weak/medium/strong positive.
INTERVENTION_GRID_LEVELS <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)
INTERVENTION_GRID_CAP <- 50000          # exhaustive up to this; seeded sample above
INTERVENTION_CHUNK <- 2048L             # configurations stepped together
INTERVENTION_N_STEPS <- 1000L           # D5.3 FIN:1198
INTERVENTION_WINDOW <- 100L             # objective judged over the last 100 steps
INTERVENTION_DEFAULT_SEED <- 20261014L  # initial state + sampling seed (recorded in results)
INTERVENTION_TOP_K <- 20L
INTERVENTION_JOB_TIMEOUT_S <- 600
# Evidence priors (C§3; toolbox_extension): max |level| by instrument evidence.
INTERVENTION_EVIDENCE_PRIORS <- c(behavioural = 0.25, regulatory = 0.5)
```

- [ ] **Step 4: Create the engine file with the grid primitives**

Create `functions/intervention_designer.R`:

```r
# functions/intervention_designer.R
# =============================================================================
# WP5 WS-7a intervention designer engine (spec 2026-10-14, D5.3 modes A and B)
#
# Pure functions, no Shiny. Also sourced inside the callr background worker,
# which has no constants.R: every function the worker calls takes all of its
# parameters explicitly.
# =============================================================================

#' Evaluate `expr` with a fixed seed, then restore the caller's RNG state.
#' @keywords internal
.with_seed <- function(seed, expr) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv()) else NULL
  on.exit({
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  })
  set.seed(seed)
  expr
}

#' Allowed levels of one variable edge: the grid levels within [min, max].
ses_level_set <- function(min_level, max_level, levels) {
  levels[levels >= min_level - 1e-12 & levels <= max_level + 1e-12]
}

#' Level sets for every row of an edges data frame (columns min_level, max_level).
ses_level_sets <- function(edges, levels) {
  lapply(seq_len(nrow(edges)), function(i)
    ses_level_set(edges$min_level[i], edges$max_level[i], levels))
}

#' Grid over the level sets: exhaustive up to `cap`, else a seeded sample.
#' @return list(n_total, sampled, n_eval, indices); indices are 1-based doubles,
#'   sorted, and NULL when the grid is exhaustive.
ses_intervention_grid <- function(level_sets, cap, seed) {
  sizes <- lengths(level_sets)
  if (length(sizes) == 0) stop("design has no variable edges")
  if (any(sizes == 0)) stop("a variable edge has an empty level range")
  n_total <- prod(as.numeric(sizes))
  if (n_total <= cap) {
    return(list(n_total = n_total, sampled = FALSE, n_eval = n_total, indices = NULL))
  }
  idx <- .with_seed(seed, sample.int(n_total, size = cap))
  list(n_total = n_total, sampled = TRUE, n_eval = as.numeric(cap), indices = sort(as.numeric(idx)))
}

#' Decode 1-based grid indices into level values (mixed radix, edge 1 fastest).
#' @return numeric matrix: one row per variable edge, one column per index
ses_grid_decode <- function(idx, level_sets) {
  sizes <- lengths(level_sets)
  r <- as.numeric(idx) - 1
  out <- matrix(0, nrow = length(sizes), ncol = length(idx))
  for (j in seq_along(sizes)) {
    d <- r %% sizes[j]
    out[j, ] <- level_sets[[j]][d + 1]
    r <- (r - d) / sizes[j]
  }
  out
}

#' Default |level| range from an intervention type's EBM codes (C§3).
#' Behavioural (2.x) evidence is weakest and wins over every other code;
#' legal/regulatory (1.x), output and spatial measures are medium; else full.
#' @param priors named numeric c(behavioural = , regulatory = )
ses_evidence_prior_range <- function(ebm_codes, priors) {
  codes <- as.character(unlist(ebm_codes))
  w <- if (any(grepl("^2(\\.|$)", codes))) {
    priors[["behavioural"]]
  } else if (any(grepl("^1(\\.|$)", codes) | codes == "output" | grepl("^spatial(\\.|$)", codes))) {
    priors[["regulatory"]]
  } else {
    1
  }
  c(min = -w, max = w)
}
```

- [ ] **Step 5: Add `get_intervention_ebm_codes()`**

In `functions/wp5_vocabulary.R`, after `get_allowed_graph_ops()`:

```r
#' EBM codes the operations table proposes for an intervention type (master row).
#' Provisional (spec Q4). Empty when the type is unknown or has no code.
get_intervention_ebm_codes <- function(id) {
  rows <- .wp5_ops_env$db$interventions %||% list()
  pick <- Find(function(r) identical(r$id, id) && is.null(r$context), rows)
  if (is.null(pick)) return(character(0))
  as.character(unlist(pick$ebm_code))
}
```

- [ ] **Step 6: Source the engine in `global.R`**

After the line `source("functions/impact_assessment_view.R", local = FALSE)` add:

```r
source("functions/intervention_designer.R", local = FALSE)
```

- [ ] **Step 7: Run the tests to verify they pass**

Run with filter `^intervention-designer$`, then `^functions-sourced-in-app$`, then `^wp5-intervention-ops$`.
Expected: all PASS, 0 failures.

- [ ] **Step 8: Commit**

```bash
git -C C:/Users/arturas.baziukas/wt-ws7a add MarineSABRES_SES_Shiny/constants.R MarineSABRES_SES_Shiny/functions/intervention_designer.R MarineSABRES_SES_Shiny/functions/wp5_vocabulary.R MarineSABRES_SES_Shiny/global.R MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer.R
git -C C:/Users/arturas.baziukas/wt-ws7a commit -F <msgfile>   # "feat(wp5): WS-7a grid primitives, constants and evidence priors"
```

---

### Task 2: Design matrix, variable edges and configurations

**Files:**
- Modify: `MarineSABRES_SES_Shiny/functions/intervention_designer.R` (append)
- Test: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer.R` (append)

**Interfaces:**
- Consumes: `ses_level_sets(edges, levels)` (Task 1).
- Produces:
  - A **design** is `list(new_node = NULL | "<name>", edges = data.frame(from, to, kind, min_level, max_level))`; `kind` is `"intervention"` (edges of the new node) or `"context"` (new edges between existing nodes, incl. self-loops). `from`/`to` are matrix dimnames (node labels) or the new node's name.
  - `ses_design_matrix(base, design, levels)` → `dm = list(matrix, cells, level_sets, new_node, edges, count_rows)`. `matrix` is the base (extended by one zero row/col named `new_node` when present) with every variable cell set to 0; `cells` is an integer matrix with columns `row`, `col`; `count_rows` are the variable-edge indices counted by criterion (d).
  - `ses_apply_config(dm, levels)` → numeric matrix with `levels` written into `dm$cells`.
  - `ses_add_edges(mat, edges_df)` → matrix with `edges_df$weight` written at (`from`, `to`); errors on unknown nodes.
  - `ses_self_loop_candidates(labels, types)` → labels whose type is `"Marine Processes & Functioning"`.
  - `ses_check_new_edge(from_type, to_type)` → `NULL` or a character warning (main process only).
  - `ses_level_code(x)` → character codes `strong_neg medium_neg weak_neg none weak_pos medium_pos strong_pos`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-intervention-designer.R`:

```r
base3 <- function() {
  m <- matrix(0, 3, 3, dimnames = rep(list(c("A x", "P. y", "C (z)")), 2))
  m["A x", "P. y"] <- 0.5; m["P. y", "C (z)"] <- -0.5
  m
}
edges_df <- function(...) {
  d <- data.frame(..., stringsAsFactors = FALSE)
  if (is.null(d$min_level)) d$min_level <- -1
  if (is.null(d$max_level)) d$max_level <- 1
  d
}

test_that("mode A design adds one zero row/column and zeroes variable cells", {
  des <- list(new_node = "AM", edges = edges_df(from = c("AM", "C (z)"), to = c("A x", "AM"),
                                                kind = "intervention"))
  dm <- ses_design_matrix(base3(), des, LV)
  expect_equal(dim(dm$matrix), c(4L, 4L))
  expect_equal(rownames(dm$matrix), c("A x", "P. y", "C (z)", "AM"))
  expect_equal(unname(dm$cells[1, ]), c(4L, 1L))
  expect_equal(dm$matrix[dm$cells], c(0, 0))
  expect_equal(dm$matrix["A x", "P. y"], 0.5)             # base kept
  expect_equal(dm$count_rows, 1:2)
})

test_that("mode B design: self-loop and context edges; d counts intervention edges only", {
  des <- list(new_node = "AM", edges = edges_df(
    from = c("C (z)", "AM"), to = c("C (z)", "A x"), kind = c("context", "intervention")))
  dm <- ses_design_matrix(base3(), des, LV)
  expect_equal(dm$count_rows, 2L)
  des_b <- list(new_node = NULL, edges = edges_df(from = "C (z)", to = "C (z)", kind = "context"))
  dm_b <- ses_design_matrix(base3(), des_b, LV)
  expect_equal(dim(dm_b$matrix), c(3L, 3L))
  expect_equal(dm_b$count_rows, 1L)                         # mode-B-only: all edges count
})

test_that("design errors: unknown node, existing edge, duplicate, name clash", {
  expect_error(ses_design_matrix(base3(), list(new_node = NULL,
    edges = edges_df(from = "nope", to = "A x", kind = "context")), LV), "unknown node")
  expect_error(ses_design_matrix(base3(), list(new_node = NULL,
    edges = edges_df(from = "A x", to = "P. y", kind = "context")), LV), "already exists")
  expect_error(ses_design_matrix(base3(), list(new_node = NULL,
    edges = edges_df(from = c("A x", "A x"), to = c("C (z)", "C (z)"), kind = "context")), LV), "duplicate")
  expect_error(ses_design_matrix(base3(), list(new_node = "A x",
    edges = edges_df(from = "A x", to = "P. y", kind = "intervention")), LV), "already exists in the network")
})

test_that("apply_config and add_edges write weights", {
  des <- list(new_node = "AM", edges = edges_df(from = c("AM", "C (z)"), to = c("A x", "AM"),
                                                kind = "intervention"))
  dm <- ses_design_matrix(base3(), des, LV)
  m <- ses_apply_config(dm, c(-0.5, 1))
  expect_equal(m["AM", "A x"], -0.5); expect_equal(m["C (z)", "AM"], 1)
  m2 <- ses_add_edges(base3(), data.frame(from = "C (z)", to = "C (z)", weight = 0.25))
  expect_equal(m2["C (z)", "C (z)"], 0.25)
  expect_error(ses_add_edges(base3(), data.frame(from = "x", to = "A x", weight = 1)), "unknown node")
})

test_that("self-loop candidates are Marine Processes & Functioning nodes", {
  expect_equal(ses_self_loop_candidates(c("a", "b", "c"),
    c("Activities", "Marine Processes & Functioning", "Goods & Benefits")), "b")
})

test_that("new-edge check returns a warning only for non-standard transitions", {
  skip_if_not(exists("validate_connection_with_feedback", mode = "function"))
  expect_null(ses_check_new_edge("Drivers", "Activities"))
  expect_type(ses_check_new_edge("Goods & Benefits", "Pressures"), "character")
})

test_that("level codes", {
  expect_equal(ses_level_code(LV), c("strong_neg", "medium_neg", "weak_neg", "none",
                                     "weak_pos", "medium_pos", "strong_pos"))
})
```

- [ ] **Step 2: Run to verify failure**

Filter `^intervention-designer$`. Expected: the new tests FAIL with `could not find function "ses_design_matrix"` (and siblings); Task 1 tests still pass.

- [ ] **Step 3: Implement**

Append to `functions/intervention_designer.R`:

```r
#' Build the design matrix: base (+ the new node) with variable cells zeroed.
#' @param design list(new_node = NULL|name, edges = data.frame(from, to, kind,
#'   min_level, max_level))
#' @return list(matrix, cells, level_sets, new_node, edges, count_rows)
ses_design_matrix <- function(base, design, levels) {
  if (!is.matrix(base) || nrow(base) != ncol(base) || is.null(rownames(base))) {
    stop("base must be a square matrix with node names")
  }
  edges <- design$edges
  if (is.null(edges) || nrow(edges) == 0) stop("design has no variable edges")
  mat <- base
  new_node <- design$new_node
  if (!is.null(new_node)) {
    if (new_node %in% rownames(base)) {
      stop(sprintf("new node name already exists in the network: %s", new_node))
    }
    nm <- c(rownames(base), new_node)
    mat <- rbind(cbind(base, 0), 0)
    dimnames(mat) <- list(nm, nm)
  }
  ri <- match(edges$from, rownames(mat))
  ci <- match(edges$to, colnames(mat))
  bad <- unique(c(edges$from[is.na(ri)], edges$to[is.na(ci)]))
  if (length(bad)) stop(sprintf("unknown node in design: %s", paste(bad, collapse = ", ")))
  if (anyDuplicated(paste(ri, ci))) stop("duplicate variable edge in design")
  existing_cell <- ri <= nrow(base) & ci <= ncol(base)
  if (any(base[cbind(ri[existing_cell], ci[existing_cell])] != 0)) {
    stop("a variable edge already exists in the network (re-weighting is mode C)")
  }
  cells <- cbind(row = ri, col = ci)
  mat[cells] <- 0
  is_int <- edges$kind == "intervention"
  list(
    matrix = mat,
    cells = cells,
    level_sets = ses_level_sets(edges, levels),
    new_node = new_node,
    edges = edges,
    count_rows = if (any(is_int)) which(is_int) else seq_len(nrow(edges))
  )
}

#' Matrix of one configuration: `levels` written into the variable cells.
ses_apply_config <- function(dm, levels) {
  m <- dm$matrix
  m[dm$cells] <- levels
  m
}

#' Write fixed edge weights (data.frame from, to, weight) into a matrix.
ses_add_edges <- function(mat, edges_df) {
  ri <- match(edges_df$from, rownames(mat))
  ci <- match(edges_df$to, colnames(mat))
  bad <- unique(c(edges_df$from[is.na(ri)], edges_df$to[is.na(ci)]))
  if (length(bad)) stop(sprintf("unknown node: %s", paste(bad, collapse = ", ")))
  mat[cbind(ri, ci)] <- as.numeric(edges_df$weight)
  mat
}

#' Nodes offered by the biological self-loop helper (D5.3 FIN:1079, 1463).
ses_self_loop_candidates <- function(labels, types) {
  labels[!is.na(types) & types == "Marine Processes & Functioning"]
}

#' DAPSIWRM check for a new edge between existing nodes (main process only).
#' @return NULL when the transition is standard, else the validator's message
ses_check_new_edge <- function(from_type, to_type) {
  if (!exists("validate_connection_with_feedback", mode = "function")) return(NULL)
  fb <- validate_connection_with_feedback(from_type, to_type, strict = FALSE)
  if (isTRUE(fb$warning) || !isTRUE(fb$valid)) fb$message else NULL
}

#' Ordinal code of a level (labels live in translations, key suffix level.<code>).
ses_level_code <- function(x) {
  codes <- c("-1" = "strong_neg", "-0.5" = "medium_neg", "-0.25" = "weak_neg", "0" = "none",
             "0.25" = "weak_pos", "0.5" = "medium_pos", "1" = "strong_pos")
  unname(codes[as.character(x)])
}
```

- [ ] **Step 4: Run to verify pass**

Filter `^intervention-designer$`. Expected: all PASS.

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a design matrix, variable edges and configurations"`.

---

### Task 3: Batched grid evaluator

**Files:**
- Modify: `MarineSABRES_SES_Shiny/functions/intervention_designer.R` (append)
- Test: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer.R` (append)

**Interfaces:**
- Consumes: `ses_design_matrix()`, `ses_apply_config()`, `ses_grid_decode()`, `ses_level_sets()` (Tasks 1–2).
- Produces: `ses_grid_evaluate(dm, configs, objective_idx, sustain_idx, x0, steps, window)` → `list(a = <logical, length ncol(configs)>, b = <logical>)`. `configs` is a numeric matrix `nrow(dm$cells) x C`; `x0` has length `nrow(dm$matrix)`; empty `sustain_idx` gives `b = TRUE`.

- [ ] **Step 1: Write the failing tests**

Append:

```r
# Reference semantics (spec §4.1-4.2): one configuration at a time.
ref_eval <- function(dm, levels, obj, sus, x0, steps, window) {
  M <- ses_apply_config(dm, levels); At <- t(M); x <- x0; a <- TRUE; b <- TRUE
  for (t in 2:steps) {
    x <- drop(At %*% x)
    if (t %% 10 == 0) { s <- sum(abs(x)); if (s > 0) x <- x / s }
    if (t > steps - window) { a <- a && all(x[obj] > 0); b <- b && all(x[sus] > 0) }
  }
  c(a = a, b = b)
}
rand_design <- function(seed, n = 6, new_node = TRUE, self_loop = TRUE) {
  set.seed(seed)
  nm <- paste0("N", 1:n)
  base <- matrix(0, n, n, dimnames = list(nm, nm))
  base[cbind(sample(n, 9, TRUE), sample(n, 9, TRUE))] <- sample(c(-1, -0.5, 0.5, 1), 9, TRUE)
  diag(base) <- 0
  e <- data.frame(from = character(), to = character(), kind = character(), stringsAsFactors = FALSE)
  if (new_node) e <- rbind(e, data.frame(from = c("IV", "IV", "N3"), to = c("N1", "N2", "IV"),
                                         kind = "intervention", stringsAsFactors = FALSE))
  if (self_loop) e <- rbind(e, data.frame(from = "N4", to = "N4", kind = "context", stringsAsFactors = FALSE))
  e$min_level <- -1; e$max_level <- 1
  list(base = base, design = list(new_node = if (new_node) "IV" else NULL, edges = e))
}

test_that("batched evaluation equals the per-configuration reference (modes A, B, A+B)", {
  for (case in list(c(TRUE, FALSE), c(FALSE, TRUE), c(TRUE, TRUE))) {
    rd <- rand_design(11, new_node = case[1], self_loop = case[2])
    dm <- ses_design_matrix(rd$base, rd$design, LV)
    n <- nrow(dm$matrix)
    x0 <- c(runif(nrow(rd$base)), if (case[1]) 0.5)
    g <- ses_intervention_grid(dm$level_sets, cap = 50000, seed = 1)
    idx <- seq_len(min(g$n_eval, 300))
    cfg <- ses_grid_decode(idx, dm$level_sets)
    got <- ses_grid_evaluate(dm, cfg, objective_idx = 1L, sustain_idx = c(2L, 5L), x0 = x0,
                             steps = 200L, window = 50L)
    want <- vapply(idx, function(i) ref_eval(dm, cfg[, i], 1L, c(2L, 5L), x0, 200L, 50L), logical(2))
    expect_identical(got$a, unname(want["a", ]))
    expect_identical(got$b, unname(want["b", ]))
  }
})

test_that("criterion (a) is strict positivity at every window step, not a sign product", {
  # Two-node oscillator: x1 <- -x2, x2 <- x1 flips signs; the sign product over an
  # even window is positive, but the node is not > 0 at every step.
  base <- matrix(c(0, 1, -1, 0), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  dm <- ses_design_matrix(base, list(new_node = NULL, edges = data.frame(
    from = "a", to = "a", kind = "context", min_level = 0, max_level = 0)), LV)
  r <- ses_grid_evaluate(dm, matrix(0, 1, 1), 1L, integer(0), c(1, 1), steps = 100L, window = 20L)
  expect_false(r$a)
  expect_true(r$b)                                          # no sustain nodes
})

test_that("a growing system is judged on signs, not discarded (rescaling)", {
  base <- matrix(c(2, 0, 0, 2), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  dm <- ses_design_matrix(base, list(new_node = NULL, edges = data.frame(
    from = "a", to = "b", kind = "context", min_level = 0, max_level = 1)), LV)
  cfg <- ses_grid_decode(1:4, dm$level_sets)
  r <- ses_grid_evaluate(dm, cfg, 1L, 2L, c(1, 1), steps = 1000L, window = 100L)
  expect_true(all(r$a)); expect_true(all(r$b))
})
```

- [ ] **Step 2: Run to verify failure** — filter `^intervention-designer$`; new tests fail with `could not find function "ses_grid_evaluate"`.

- [ ] **Step 3: Implement**

Append:

```r
#' Evaluate a chunk of configurations together (spec §4.1, §4.4).
#'
#' x[t] = t(A) %*% x[t-1]; the fixed part of A is applied as one sparse
#' product, each variable cell (r, c) adds level * x[r] to x[c]. States are
#' divided by their L1 norm every 10 steps (exact for signs: the model is
#' linear). (a)/(b): strictly > 0 at each of the last `window` steps.
#' @param configs numeric matrix, one row per variable edge, one column per configuration
#' @return list(a = logical, b = logical), one element per configuration
ses_grid_evaluate <- function(dm, configs, objective_idx, sustain_idx, x0, steps, window) {
  A <- dm$matrix
  n <- nrow(A)
  C <- ncol(configs)
  cells <- dm$cells
  fixed_t <- Matrix::Matrix(t(A), sparse = TRUE)
  X <- matrix(x0, nrow = n, ncol = C)
  ok_a <- rep(TRUE, C)
  ok_b <- rep(TRUE, C)
  first_check <- steps - window + 1L
  for (t in 2:steps) {
    Xn <- as.matrix(fixed_t %*% X)
    for (k in seq_len(nrow(cells))) {
      tgt <- cells[k, 2]
      Xn[tgt, ] <- Xn[tgt, ] + configs[k, ] * X[cells[k, 1], ]
    }
    X <- Xn
    if (t %% 10L == 0L) {
      s <- colSums(abs(X))
      s[s == 0] <- 1
      X <- X / rep(s, each = n)
    }
    if (t >= first_check) {
      if (length(objective_idx)) {
        ok_a <- ok_a & colSums(X[objective_idx, , drop = FALSE] > 0) == length(objective_idx)
      }
      if (length(sustain_idx)) {
        ok_b <- ok_b & colSums(X[sustain_idx, , drop = FALSE] > 0) == length(sustain_idx)
      }
    }
  }
  list(a = unname(ok_a), b = unname(ok_b))
}
```

- [ ] **Step 4: Run to verify pass** — filter `^intervention-designer$`; all PASS.

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a batched grid evaluator with sign-exact rescaling"`.

---

### Task 4: Stability, ranking, Boolean pre-check

**Files:**
- Modify: `MarineSABRES_SES_Shiny/functions/intervention_designer.R` (append)
- Test: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer.R` (append)

**Interfaces:**
- Consumes: `ses_apply_config()` (Task 2); `boolean_model(mat, max_nodes)` from `functions/ses_dynamics.R` (returns `list(rules, analysis, n_nodes, skipped)`; `analysis$attractors` is a list of data frames whose columns follow the matrix node order, values 0/1).
- Produces:
  - `ses_is_stable_attractor(mat, tol = 1e-9)` → logical
  - `rank_simplest(df)` → `df` reordered; `df` has logical `a`, `b`, `c` (NA allowed, treated as FALSE), integer `d`, numeric `index`
  - `ses_boolean_precheck(dm, objective_idx, max_nodes)` → `list(status = "passed" | "topology_change_needed" | "skipped" | "unavailable", n_nodes, n_attractors, n_desirable)`

- [ ] **Step 1: Write the failing tests**

Append:

```r
test_that("stability: complex Laplacian eigenvalues mean unstable", {
  rot <- matrix(c(0, 1, -1, 0), 2, 2)                 # L = -rot has eigenvalues ±i
  expect_false(ses_is_stable_attractor(rot))
  sym <- matrix(c(0, 0.5, 0.5, 0), 2, 2)
  expect_true(ses_is_stable_attractor(sym))
})

test_that("rank_simplest orders by a, b, c desc then d asc, ties keep grid order", {
  df <- data.frame(index = 1:6,
                   a = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE),
                   b = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
                   c = c(FALSE, NA, NA, TRUE, TRUE, FALSE),
                   d = c(1L, 0L, 0L, 3L, 2L, 1L))
  expect_equal(rank_simplest(df)$index, c(5L, 4L, 1L, 6L, 2L, 3L))
})

test_that("Boolean pre-check: passed, topology change needed, skipped (review focus 1)", {
  nm <- c("Act. (x)", "P. oceanica extension")
  base <- matrix(0, 2, 2, dimnames = list(nm, nm))
  dm_ok <- ses_design_matrix(base, list(new_node = "IV", edges = data.frame(
    from = c("IV", "P. oceanica extension"), to = c("P. oceanica extension", "IV"),
    kind = "intervention", min_level = c(0, 0), max_level = c(1, 1))), LV)
  pc <- ses_boolean_precheck(dm_ok, objective_idx = 2L, max_nodes = 20L)
  expect_equal(pc$status, "passed")
  expect_gte(pc$n_desirable, 1L)

  # A negative self-loop makes P. oceanica oscillate (rule P = !P): no attractor
  # keeps it ON in every state.
  dm_bad <- ses_design_matrix(base, list(new_node = NULL, edges = data.frame(
    from = "P. oceanica extension", to = "P. oceanica extension", kind = "context",
    min_level = -1, max_level = -0.25)), LV)
  expect_equal(ses_boolean_precheck(dm_bad, 2L, max_nodes = 20L)$status, "topology_change_needed")

  expect_equal(ses_boolean_precheck(dm_ok, 2L, max_nodes = 2L)$status, "skipped")
})
```

- [ ] **Step 2: Run to verify failure** — new tests fail with `could not find function`.

- [ ] **Step 3: Implement**

Append:

```r
#' D5.3 stability (FIN:1517): every Laplacian eigenvalue is real.
#' laplacian_eigenvalues() drops imaginary parts, so it cannot be reused here.
ses_is_stable_attractor <- function(mat, tol = 1e-9) {
  L <- diag(rowSums(mat), nrow = nrow(mat)) - mat
  ev <- eigen(L, only.values = TRUE)$values
  all(abs(Im(ev)) <= tol)
}

#' D5.3 ranking (C§5.2 step 6): a, b, c descending, d ascending, grid order.
rank_simplest <- function(df) {
  cc <- df$c %in% TRUE
  df[order(-df$a, -df$b, -cc, df$d, df$index), , drop = FALSE]
}

#' Boolean pre-check (spec §4.6): every variable edge at the strongest level of
#' its allowed sign; does any attractor keep every objective node ON?
ses_boolean_precheck <- function(dm, objective_idx, max_nodes) {
  n <- nrow(dm$matrix)
  out <- function(status, n_att = NA_integer_, n_des = NA_integer_) {
    list(status = status, n_nodes = n, n_attractors = n_att, n_desirable = n_des)
  }
  if (n > max_nodes) return(out("skipped"))
  extreme <- vapply(dm$level_sets, function(s) if (max(s) > 0) max(s) else min(s), numeric(1))
  bm <- tryCatch(boolean_model(ses_apply_config(dm, extreme), max_nodes = max_nodes),
                 error = function(e) NULL)
  if (is.null(bm)) return(out("unavailable"))
  if (isTRUE(bm$skipped) || is.null(bm$analysis)) return(out("skipped"))
  att <- bm$analysis$attractors
  desirable <- vapply(att, function(a) {
    if (is.null(a) || !is.data.frame(a) || nrow(a) == 0) return(FALSE)
    all(as.matrix(a[, objective_idx, drop = FALSE]) == 1)
  }, logical(1))
  out(if (any(desirable)) "passed" else "topology_change_needed",
      length(att), sum(desirable))
}
```

- [ ] **Step 4: Run to verify pass** — filter `^intervention-designer$`; all PASS.

  If the "passed" case fails, print `boolean_model(...)$analysis$attractors` for the fixture and check that the attractor columns follow node order; do not change the criterion.

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a stability check, D5.3 ranking and Boolean pre-check"`.

---

### Task 5: Pipeline `ses_run_design()` and the D5.3 fixtures

**Files:**
- Modify: `MarineSABRES_SES_Shiny/functions/intervention_designer.R` (append)
- Create: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer-d53.R`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: `ses_run_design(payload, progress = NULL)` where `payload` is
  `list(base, design, levels, objectives, sustain, seed, steps, window, cap, chunk, top_k, max_boolean_nodes)`
  (`objectives`/`sustain`: node labels; `progress`: `function(done, total)` or NULL). Returns:

  ```
  list(n_total, n_eval, sampled, n_a, n_ab, n_abc, share,          # share = n_a / n_eval
       precheck,                                                   # from ses_boolean_precheck()
       top = data.frame(rank, index, a, b, c, d),                  # top_k rows
       top_levels = <numeric matrix: variable edges x top_k>,
       design_matrix = <dm from ses_design_matrix()>,
       base = payload$base, objectives, sustain,
       seed, steps, window, elapsed_s)
  ```

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-intervention-designer-d53.R`:

```r
# tests/testthat/test-intervention-designer-d53.R
# D5.3 Tuscany "additional moorings" (C§4.3, FIN:1461-1585), built from the
# edges D5.3 describes in text. Labels keep D5.3's punctuation on purpose.
source_for_test("functions/intervention_designer.R")

LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)
OBJ <- "P. oceanica extension"

tuscany_base <- function() {
  nodes <- c("Tourism demand", "Recreational boating", "Boat moorings", "Spatial planning (MPA)",
             "Anchoring", OBJ, "Coastal protection", "Extension of natural habitats", "Tourism revenue")
  E <- data.frame(
    from = c("Tourism demand", "Recreational boating", "Recreational boating", "Anchoring",
             "Boat moorings", "Spatial planning (MPA)", OBJ, OBJ, "Coastal protection",
             "Tourism revenue", "Extension of natural habitats"),
    to = c("Recreational boating", "Anchoring", "Boat moorings", OBJ, OBJ, OBJ,
           "Coastal protection", "Extension of natural habitats", "Tourism revenue",
           "Tourism demand", "Tourism demand"),
    weight = c(0.5, 0.5, 0.5, -1, -0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.25),
    stringsAsFactors = FALSE)
  m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
  ses_add_edges(m, E)
}

moorings_payload <- function(self_loop) {
  base <- tuscany_base()
  if (self_loop != 0) base <- ses_add_edges(base, data.frame(from = OBJ, to = OBJ, weight = self_loop))
  am <- "Additional moorings"
  edges <- data.frame(
    from = c("Extension of natural habitats", OBJ, am, am, am),
    to = c(am, am, "Anchoring", "Boat moorings", "Spatial planning (MPA)"),
    kind = "intervention",
    min_level = c(0, 0, -1, -1, 0), max_level = c(1, 1, 0, 0, 1),
    stringsAsFactors = FALSE)
  list(base = base, design = list(new_node = am, edges = edges), levels = LV,
       objectives = OBJ, sustain = c("Extension of natural habitats", "Tourism revenue"),
       seed = 20261014L, steps = 1000L, window = 100L, cap = 50000, chunk = 2048L,
       top_k = 20L, max_boolean_nodes = 20L)
}

test_that("D5.3 Tuscany: a strong self-loop raises the success share (FIN:1513-1558)", {
  none <- ses_run_design(moorings_payload(0))
  weak <- ses_run_design(moorings_payload(0.25))
  strong <- ses_run_design(moorings_payload(1))
  expect_equal(strong$n_eval, 4^5)
  expect_false(strong$sampled)
  expect_gt(strong$n_a, 0)
  expect_gt(strong$share, weak$share)
  expect_gt(weak$share, none$share)
})

test_that("pipeline result is well formed and ranked", {
  r <- ses_run_design(moorings_payload(1))
  expect_equal(nrow(r$top), 20L)
  expect_equal(dim(r$top_levels), c(5L, 20L))
  expect_true(all(r$top_levels %in% LV))
  expect_equal(rank_simplest(r$top)$index, r$top$index)    # already in rank order
  expect_equal(r$top$rank, 1:20)
  expect_true(r$top$a[1])
  expect_lte(r$n_abc, r$n_ab); expect_lte(r$n_ab, r$n_a)
  expect_true(r$precheck$status %in% c("passed", "topology_change_needed", "skipped", "unavailable"))
  expect_equal(r$seed, 20261014L)
})

test_that("pipeline counts equal the per-configuration reference", {
  p <- moorings_payload(1)
  r <- ses_run_design(p)
  dm <- r$design_matrix
  x0 <- c(.with_seed(p$seed, stats::runif(nrow(p$base))), 0.5)
  cfg <- ses_grid_decode(seq_len(r$n_eval), dm$level_sets)
  obj <- match(p$objectives, rownames(dm$matrix))
  a_ref <- vapply(seq_len(r$n_eval), function(i) {
    At <- t(ses_apply_config(dm, cfg[, i])); x <- x0; ok <- TRUE
    for (t in 2:1000) { x <- drop(At %*% x); if (t %% 10 == 0) { s <- sum(abs(x)); if (s > 0) x <- x / s }
      if (t > 900) ok <- ok && x[obj] > 0 }
    ok
  }, logical(1))
  expect_equal(r$n_a, sum(a_ref))
})

test_that("progress callback reports completion", {
  seen <- numeric(0)
  ses_run_design(moorings_payload(1), progress = function(done, total) seen <<- c(seen, done / total))
  expect_equal(tail(seen, 1), 1)
})

test_that("realistic size: the repo's Tuscany network runs a 2,401-configuration design", {
  f <- file.path(dirname(dirname(getwd())), "data", "TuscanySES.xlsx")
  if (!file.exists(f)) f <- file.path("data", "TuscanySES.xlsx")
  skip_if_not(file.exists(f))
  el <- openxlsx::read.xlsx(f, "Elements"); cn <- openxlsx::read.xlsx(f, "Connections")
  lab <- el$Label
  m <- matrix(0, length(lab), length(lab), dimnames = list(lab, lab))
  w <- ifelse(cn$Label == "-", -0.5, 0.5)
  keep <- cn$From %in% lab & cn$To %in% lab
  m[cbind(cn$From[keep], cn$To[keep])] <- w[keep]
  iv <- "Additional moorings"
  p <- list(base = m, design = list(new_node = iv, edges = data.frame(
      from = c("P. oceanica extension", iv, iv, iv), to = c(iv, "Marine traffic (including anchoring)",
               "Boat moorings", "Spatial planning (MPA)"),
      kind = "intervention", min_level = -1, max_level = 1, stringsAsFactors = FALSE)),
    levels = LV, objectives = "P. oceanica extension", sustain = character(0),
    seed = 1L, steps = 1000L, window = 100L, cap = 50000, chunk = 2048L, top_k = 20L,
    max_boolean_nodes = 20L)
  r <- ses_run_design(p)
  expect_equal(r$n_eval, 7^4)
  expect_equal(r$precheck$status, "skipped")                # 29 nodes > 20
  expect_true(is.numeric(r$share) && r$share >= 0 && r$share <= 1)
})
```

- [ ] **Step 2: Run to verify failure** — filter `^intervention-designer-d53$`; fails with `could not find function "ses_run_design"`.

- [ ] **Step 3: Implement**

Append to `functions/intervention_designer.R`:

```r
#' Run a whole design (called in the background worker).
#' @param payload list(base, design, levels, objectives, sustain, seed, steps,
#'   window, cap, chunk, top_k, max_boolean_nodes)
#' @param progress optional function(done, total)
ses_run_design <- function(payload, progress = NULL) {
  t0 <- Sys.time()
  dm <- ses_design_matrix(payload$base, payload$design, payload$levels)
  nm <- rownames(dm$matrix)
  obj <- match(payload$objectives, nm)
  if (!length(obj) || anyNA(obj)) stop("objective nodes not found in the network")
  sus <- match(payload$sustain, nm)
  sus <- sus[!is.na(sus)]
  grid <- ses_intervention_grid(dm$level_sets, cap = payload$cap, seed = payload$seed)
  x0 <- .with_seed(payload$seed, stats::runif(nrow(payload$base)))
  if (!is.null(dm$new_node)) x0 <- c(x0, 0.5)
  precheck <- tryCatch(ses_boolean_precheck(dm, obj, payload$max_boolean_nodes),
                       error = function(e) list(status = "unavailable", n_nodes = nrow(dm$matrix),
                                                n_attractors = NA_integer_, n_desirable = NA_integer_))
  n_eval <- grid$n_eval
  index <- if (grid$sampled) grid$indices else seq_len(n_eval)
  a <- logical(n_eval); b <- logical(n_eval); d <- integer(n_eval)
  for (s in seq(1, n_eval, by = payload$chunk)) {
    pos <- s:min(n_eval, s + payload$chunk - 1)
    cfg <- ses_grid_decode(index[pos], dm$level_sets)
    r <- ses_grid_evaluate(dm, cfg, obj, sus, x0, payload$steps, payload$window)
    a[pos] <- r$a
    b[pos] <- r$b
    d[pos] <- as.integer(colSums(cfg[dm$count_rows, , drop = FALSE] != 0))
    if (is.function(progress)) progress(max(pos), n_eval)
  }
  c_ok <- rep(NA, n_eval)
  for (i in which(a)) {
    c_ok[i] <- ses_is_stable_attractor(ses_apply_config(dm, ses_grid_decode(index[i], dm$level_sets)[, 1]))
  }
  ranked <- rank_simplest(data.frame(index = index, a = a, b = b, c = c_ok, d = d))
  top <- utils::head(ranked, payload$top_k)
  top$rank <- seq_len(nrow(top))
  top <- top[, c("rank", "index", "a", "b", "c", "d")]
  rownames(top) <- NULL
  list(
    n_total = grid$n_total, n_eval = n_eval, sampled = grid$sampled,
    n_a = sum(a), n_ab = sum(a & b), n_abc = sum(a & b & (c_ok %in% TRUE)),
    share = sum(a) / n_eval,
    precheck = precheck,
    top = top,
    top_levels = ses_grid_decode(top$index, dm$level_sets),
    design_matrix = dm, base = payload$base,
    objectives = payload$objectives, sustain = payload$sustain,
    seed = payload$seed, steps = payload$steps, window = payload$window,
    elapsed_s = as.numeric(difftime(Sys.time(), t0, units = "secs"))
  )
}
```

- [ ] **Step 4: Run to verify pass** — filters `^intervention-designer-d53$` and `^intervention-designer$`; all PASS. The D5.3 test was prototyped on 2026-10-14 with the same semantics: none 239/1024, weak 373/1024, strong 733/1024 configurations meet the objective.

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a design pipeline with D5.3 Tuscany fixture"`.

---

### Task 6: Background job layer (callr)

**Files:**
- Create: `MarineSABRES_SES_Shiny/functions/intervention_designer_job.R`
- Modify: `MarineSABRES_SES_Shiny/global.R` (source line after `intervention_designer.R`)
- Modify: `MarineSABRES_SES_Shiny/deployment/required_packages.R` (add `"callr"` and `"Matrix"` to `REQUIRED_PACKAGES`)
- Modify: `MarineSABRES_SES_Shiny/DESCRIPTION` (add `callr,` and `Matrix,` to `Imports`)
- Create: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer-job.R`

**Interfaces:**
- Consumes: `ses_run_design(payload, progress)` (Task 5), sourced in the worker from absolute paths.
- Produces:
  - `designer_engine_files(root = NULL)` → absolute paths of `functions/ses_dynamics.R` and `functions/intervention_designer.R`
  - `designer_job_start(payload, engine_files = designer_engine_files())` → `job = list(process, progress_file, started)`
  - `designer_job_poll(job, timeout_s = INTERVENTION_JOB_TIMEOUT_S)` → `list(state = "running", done, total)` | `list(state = "done", result)` | `list(state = "error", message)`
  - `designer_job_cancel(job)` → invisible TRUE
  - `designer_job_api()` → `list(start, poll, cancel)` (the module takes this, tests replace it)

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-intervention-designer-job.R`:

```r
# tests/testthat/test-intervention-designer-job.R
source_for_test(c("functions/intervention_designer.R", "functions/intervention_designer_job.R"))

app_root <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }
LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)
tiny_payload <- function(objectives = "b") {
  m <- matrix(c(0, 0.5, 0, 0), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  list(base = m, design = list(new_node = "IV", edges = data.frame(
         from = c("IV", "b"), to = c("a", "IV"), kind = "intervention",
         min_level = -1, max_level = 1, stringsAsFactors = FALSE)),
       levels = LV, objectives = objectives, sustain = character(0), seed = 1L,
       steps = 200L, window = 50L, cap = 50000, chunk = 2048L, top_k = 5L, max_boolean_nodes = 20L)
}
wait_for <- function(job, secs = 120) {
  t_end <- Sys.time() + secs
  repeat {
    st <- designer_job_poll(job, timeout_s = secs)
    if (st$state != "running" || Sys.time() > t_end) return(st)
    Sys.sleep(0.2)
  }
}

test_that("engine files resolve to existing absolute paths", {
  f <- designer_engine_files(app_root())
  expect_length(f, 2L)
  expect_true(all(file.exists(f)))
})

test_that("a background job runs a tiny design to a result", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(), designer_engine_files(app_root()))
  st <- wait_for(job)
  expect_equal(st$state, "done")
  expect_equal(st$result$n_eval, 49)
  expect_false(file.exists(job$progress_file))
})

test_that("an engine error comes back as an error state (review focus 5)", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(objectives = "no such node"), designer_engine_files(app_root()))
  st <- wait_for(job)
  expect_equal(st$state, "error")
  expect_match(st$message, "objective nodes not found")
})

test_that("cancel kills the worker", {
  skip_if_not_installed("callr")
  p <- tiny_payload(); p$steps <- 1000L
  p$design$edges <- data.frame(from = c("IV", "IV", "b", "a"), to = c("a", "b", "IV", "a"),
    kind = c("intervention", "intervention", "intervention", "context"),
    min_level = -1, max_level = 1, stringsAsFactors = FALSE)
  job <- designer_job_start(p, designer_engine_files(app_root()))
  designer_job_cancel(job)
  Sys.sleep(0.5)
  expect_false(job$process$is_alive())
})

test_that("a job past its timeout is killed and reported", {
  skip_if_not_installed("callr")
  job <- designer_job_start(tiny_payload(), designer_engine_files(app_root()))
  job$started <- Sys.time() - 1000
  st <- designer_job_poll(job, timeout_s = 1)
  expect_equal(st$state, "error")
  expect_match(st$message, "timed out")
})
```

- [ ] **Step 2: Run to verify failure** — filter `^intervention-designer-job$`; fails with `could not find function "designer_engine_files"`.

- [ ] **Step 3: Implement**

Create `functions/intervention_designer_job.R`:

```r
# functions/intervention_designer_job.R
# =============================================================================
# Background execution for the WS-7a intervention designer (spec §2.4, §5).
# laguna runs open-source Shiny Server: one R process serves every user, so
# grids (up to ~50 s) run in a separate R process via callr.
# =============================================================================

#' Absolute paths of the engine files the worker sources.
designer_engine_files <- function(root = NULL) {
  if (is.null(root)) {
    root <- if (exists("PROJECT_ROOT", inherits = TRUE)) get("PROJECT_ROOT", inherits = TRUE) else getwd()
  }
  normalizePath(file.path(root, "functions", c("ses_dynamics.R", "intervention_designer.R")),
                winslash = "/", mustWork = TRUE)
}

#' Start a designer run in a background R process.
designer_job_start <- function(payload, engine_files = designer_engine_files()) {
  progress_file <- tempfile("designer_progress_", fileext = ".txt")
  proc <- callr::r_bg(
    function(payload, engine_files, progress_file) {
      suppressMessages(library(Matrix))
      for (f in engine_files) source(f, local = FALSE)
      progress <- function(done, total) {
        tmp <- paste0(progress_file, ".tmp")
        writeLines(sprintf("%.0f %.0f", done, total), tmp)
        file.rename(tmp, progress_file)
      }
      ses_run_design(payload, progress = progress)
    },
    args = list(payload = payload, engine_files = engine_files, progress_file = progress_file),
    supervise = TRUE
  )
  list(process = proc, progress_file = progress_file, started = Sys.time())
}

#' Poll a designer job.
designer_job_poll <- function(job, timeout_s = INTERVENTION_JOB_TIMEOUT_S) {
  p <- job$process
  if (p$is_alive()) {
    if (as.numeric(difftime(Sys.time(), job$started, units = "secs")) > timeout_s) {
      designer_job_cancel(job)
      return(list(state = "error", message = sprintf("designer run timed out after %.0f s", timeout_s)))
    }
    prog <- tryCatch(scan(job$progress_file, quiet = TRUE), error = function(e) numeric(0),
                     warning = function(w) numeric(0))
    return(list(state = "running",
                done = if (length(prog) >= 1) prog[1] else 0,
                total = if (length(prog) >= 2) prog[2] else NA_real_))
  }
  res <- tryCatch(p$get_result(), error = function(e) e)
  unlink(c(job$progress_file, paste0(job$progress_file, ".tmp")))
  if (inherits(res, "error")) {
    msg <- if (!is.null(res$parent)) conditionMessage(res$parent) else conditionMessage(res)
    if (exists("debug_log", mode = "function")) debug_log(paste("Designer job failed:", msg), "INTERVENTION")
    return(list(state = "error", message = msg))
  }
  list(state = "done", result = res)
}

#' Kill a designer job and remove its progress file.
designer_job_cancel <- function(job) {
  if (!is.null(job) && !is.null(job$process) && job$process$is_alive()) job$process$kill()
  if (!is.null(job)) unlink(c(job$progress_file, paste0(job$progress_file, ".tmp")))
  invisible(TRUE)
}

#' The job functions the designer module uses (tests pass a fake).
designer_job_api <- function() {
  list(start = function(payload) designer_job_start(payload),
       poll = designer_job_poll,
       cancel = designer_job_cancel)
}
```

In `global.R` after the line added in Task 1:

```r
source("functions/intervention_designer_job.R", local = FALSE)
```

In `deployment/required_packages.R`, inside `REQUIRED_PACKAGES <- unique(c(` after `"sortable"`:

```r
  "sortable",        # drag-and-drop UI
  "callr",           # background R process for the intervention designer (WS-7a)
  "Matrix"           # sparse products in the intervention designer (WS-7a)
```

In `DESCRIPTION` `Imports:` append after `flextable`: `,` then lines `    callr,` and `    Matrix` (keep the list comma-separated, last entry without a comma).

- [ ] **Step 4: Run to verify pass** — filters `^intervention-designer-job$`, `^functions-sourced-in-app$`; all PASS.

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a background job layer (callr)"`.

---

### Task 7: Translations

**Files:**
- Create: `MarineSABRES_SES_Shiny/translations/modules/intervention_designer.json`
- Create: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer-i18n.R`

**Interfaces:**
- Produces: the keys below, all prefixed `modules.intervention_designer.`; Task 8 uses them verbatim.

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test-intervention-designer-i18n.R
root <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }
langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

test_that("designer translations cover every key in 9 languages", {
  tr <- jsonlite::fromJSON(file.path(root(), "translations", "modules", "intervention_designer.json"),
                           simplifyVector = FALSE)$translation
  expect_gt(length(tr), 100L)
  for (k in names(tr)) {
    expect_setequal(names(tr[[k]]), langs)
    expect_true(all(nzchar(unlist(tr[[k]]))), info = k)
  }
})

test_that("every intervention type and group in the ops table has a label", {
  tr <- jsonlite::fromJSON(file.path(root(), "translations", "modules", "intervention_designer.json"),
                           simplifyVector = FALSE)$translation
  ops <- jsonlite::fromJSON(file.path(root(), "data", "wp5_intervention_ops.json"), simplifyVector = FALSE)
  ids <- unique(vapply(ops$interventions, function(r) r$id, character(1)))
  groups <- unique(vapply(ops$interventions, function(r) r$group, character(1)))
  expect_true(all(paste0("modules.intervention_designer.type.", ids) %in% names(tr)))
  expect_true(all(paste0("modules.intervention_designer.group.", groups) %in% names(tr)))
})
```

- [ ] **Step 2: Run to verify failure** — filter `^intervention-designer-i18n$`; fails (file missing).

- [ ] **Step 3: Write the translation file**

Same structure as `translations/modules/impact_assessment.json`: `{"languages": [9 codes], "translation": {"<key>": {"en": ..., "es": ..., ...}}}`. Provide every key below in all 9 languages. Keep the module's established terminology: reuse wording from `translations/modules/analysis_intervention.json` and `impact_assessment.json` where the same concept appears (e.g. "intervention", "objective", "node"). Greek and Norwegian must be real translations, not English copies.

English values (key suffix → text):

| Key suffix | English |
|---|---|
| `tab_quick` | Quick compare |
| `tab_designer` | Designer (D5.3) |
| `intro` | Try every allowed combination of ordinal edge weights for a new intervention, the way D5.3 did, and rank them by the D5.3 criteria. |
| `step_intervention` | 1. Intervention |
| `step_edges` | 2. Edges to vary |
| `step_objectives` | 3. Objectives |
| `step_run` | 4. Run |
| `name` | Intervention name |
| `name_placeholder` | e.g. Additional moorings |
| `type` | Intervention type (optional) |
| `type_none` | No type |
| `ops_heading` | Operations the sources list for this type |
| `ops_source_xlsx` | D5.3 matrix |
| `ops_source_ebm` | EBM framework |
| `ops_mismatch` | Your design uses an operation that neither source lists for this type. The table is provisional, so the run is still allowed. |
| `prior_note` | New edges start with the default range for this type's evidence. You can widen it. |
| `op.new_node` | New node |
| `op.new_edge` | New edge |
| `op.reweight_edge` | Re-weight an existing edge |
| `add_node_heading` | Add the intervention node |
| `node_targets` | Nodes it acts on |
| `node_indicators` | Indicator nodes that feed it |
| `add_node_edges` | Add node edges |
| `add_edge_heading` | Add an edge between existing nodes |
| `edge_from` | From |
| `edge_to` | To |
| `add_edge` | Add edge |
| `self_loop_node` | Self-loop on a marine process |
| `add_self_loop` | Add self-loop |
| `edge_exists` | This edge already exists. Changing its weight is re-weighting, which comes in a later release. |
| `edge_rule_warning` | This edge breaks the usual DAPSIWRM sequence: |
| `no_edges` | No edges yet. Add the intervention node or an edge. |
| `new_node_placeholder` | (new node) |
| `col_from` | From |
| `col_to` | To |
| `col_kind` | Kind |
| `col_range` | Levels |
| `kind.intervention` | Intervention |
| `kind.context` | Context |
| `edit_edge` | Edge to edit |
| `min_level` | Lowest level |
| `max_level` | Highest level |
| `apply_range` | Apply |
| `sign_nonpos` | Only negative or none |
| `sign_nonneg` | Only positive or none |
| `remove_edge` | Remove edge |
| `level.strong_neg` | strong − |
| `level.medium_neg` | medium − |
| `level.weak_neg` | weak − |
| `level.none` | none |
| `level.weak_pos` | weak + |
| `level.medium_pos` | medium + |
| `level.strong_pos` | strong + |
| `objectives` | Objective nodes |
| `sustain` | Also sustain (default: all Goods & Benefits) |
| `combinations` | combinations |
| `exhaustive` | every combination is tested |
| `sampled` | a random sample of 50,000 is tested |
| `run` | Run |
| `cancel` | Cancel |
| `running` | Running |
| `progress_of` | of |
| `need_edges` | Add at least one edge to vary. |
| `empty_range` | An edge has no levels in its range. |
| `need_objective` | Choose at least one objective node. |
| `need_name` | Name the intervention node. |
| `name_clash` | The intervention name matches an existing node. Choose another name. |
| `need_target` | Choose at least one node the intervention acts on. |
| `job_running` | A run is already in progress. |
| `context_run` | Starting the designer run |
| `run_failed` | The designer run failed: |
| `cancelled` | Run cancelled. |
| `precheck.passed` | Boolean pre-check passed: at least one attractor keeps every objective on. |
| `precheck.topology_change_needed` | Boolean pre-check: no attractor keeps every objective on. A topology change is needed; consider adding edges between existing nodes. |
| `precheck.skipped` | Boolean pre-check skipped: the network has more than 20 nodes. |
| `precheck.unavailable` | Boolean pre-check unavailable. |
| `result_share` | Combinations meeting the objective |
| `result_pass_a` | Objective met (a) |
| `result_pass_ab` | Objective met and also-sustain nodes kept (a, b) |
| `result_pass_abc` | ... and stable (a, b, c) |
| `estimate_note` | Estimated from a random sample. |
| `top_heading` | Best combinations |
| `col_rank` | Rank |
| `col_a` | Objective |
| `col_b` | Sustain |
| `col_c` | Stable |
| `col_d` | Edges used |
| `yes` | yes |
| `no` | no |
| `select_row_hint` | Select a row to compare its final states with the network the run used. |
| `compare_title` | Final states: network vs selected combination |
| `compare_original` | Network |
| `compare_selected` | Selected combination |
| `run_meta` | Seed, steps and window |
| `help_designer` | The Designer adds an intervention node, new edges between existing nodes, or both. Each edge takes every level in its range; the tool tests every combination (or a random sample of 50,000) over 1,000 steps and keeps those whose objective nodes stay positive over the last 100. Results are ranked by objective, also-sustain nodes, stability and the number of edges used, as in D5.3. |
| `help_delay` | A new intervention node acts one step after its indicators change. D5.3 notes that this delay can destabilise the system. |
| `group.behavioural` | Mainly behavioural |
| `group.management` | Mainly management |
| `group.economic` | Mainly economic |
| `group.governance` | Mainly governance |
| `type.nudge` | Nudge |
| `type.certification` | Certification |
| `type.traceability` | Traceability |
| `type.norms_influence` | Norms influence |
| `type.data_valuing` | Data valuing |
| `type.change_in_accessibility` | Change in accessibility |
| `type.participation_in_governance` | Change in participation in governance |
| `type.cascade_creation` | Cascade creation |
| `type.remote_market_access` | Remote market access |
| `type.change_in_practices` | Change in practices |
| `type.quota_license` | Quota or licence |
| `type.mpa_oecm` | MPA or OECM |
| `type.subsidies` | Subsidies |
| `type.incentives` | Incentives |
| `type.trade_agreements` | Trade agreements |
| `type.payment_goods_services` | Payment for goods and services |
| `type.payment_non_market_services` | Payment for non-market goods and services |
| `type.externalities_in_prices` | Externalities in prices |
| `type.one_off_recosting` | One-off recosting |
| `type.ongoing_recosting` | Ongoing recosting |
| `type.multi_level_governance` | Multi-level governance |
| `type.change_power_dynamics` | Change power dynamics |
| `type.cross_sector_coordination` | Cross-sector coordination |
| `type.enhance_governance_capacity` | Enhance governance capacity |
| `type.incorporate_society_values` | Incorporate society's values in decision-making |
| `type.enhance_trust` | Enhance trust between actors |
| `type.reduce_conflicts` | Reduce conflicts among stakeholders |
| `type.increase_collaboration` | Increase collaboration between stakeholders and sectors |
| `type.increase_participation` | Increase participation in decision-making |
| `type.enhance_compliance_monitoring` | Enhance compliance and monitoring |

- [ ] **Step 4: Run to verify pass** — filter `^intervention-designer-i18n$`; PASS. Then rebuild/validate merged translations the way CI does: `micromamba run -n shiny python scripts/_i18n_audit.py` (expect `missing=0`; `hardcoded` is checked again after Task 8).

- [ ] **Step 5: Commit** — `"feat(wp5): WS-7a designer translations (9 languages)"`.

---

### Task 8: Designer sub-module and the Intervention page tabs

**Files:**
- Create: `MarineSABRES_SES_Shiny/modules/intervention_designer_module.R`
- Modify: `MarineSABRES_SES_Shiny/modules/analysis_intervention.R` (UI function lines 20–29; server: help observer ~line 71 and a new line after `setup_cld_gate(...)`)
- Modify: `MarineSABRES_SES_Shiny/app.R:114` — add `"modules/intervention_designer_module.R",` to the `CRITICAL_MODULES` vector immediately before `"modules/analysis_intervention.R",`
- Modify: `MarineSABRES_SES_Shiny/tests/testthat/helper-stubs.R` only if it stubs `analysis_intervention_ui`/`_server` (keep stub signatures matching)
- Create: `MarineSABRES_SES_Shiny/tests/testthat/test-intervention-designer-module.R`

**Interfaces:**
- Consumes: `ses_design_matrix`, `ses_level_sets`, `ses_intervention_grid`, `ses_apply_config`, `ses_self_loop_candidates`, `ses_check_new_edge`, `ses_level_code`, `ses_evidence_prior_range` (Tasks 1–5); `designer_job_api()` (Task 6); `get_intervention_types()`, `get_allowed_graph_ops()`, `get_intervention_ebm_codes()`, `load_wp5_intervention_ops()` (wp5_vocabulary); `cld_to_numeric_matrix()`, `ses_compare_interventions()` (ses_dynamics); `has_valid_cld()`; `provenance_badge()`; `format_user_error()`; translation keys from Task 7.
- Produces:
  - `intervention_designer_ui(id, i18n)`
  - `intervention_designer_server(id, project_data_reactive, i18n, event_bus = NULL, job_api = designer_job_api())` — returns `rv` invisibly is not needed; tests read `rv` inside `testServer()`.
  - `.designer_payload(net, edges, name, objectives, sustain)` → payload list (pure; placeholder substitution, review focus 2)

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-intervention-designer-module.R`:

```r
# tests/testthat/test-intervention-designer-module.R
source_for_test(c("functions/intervention_designer.R", "functions/intervention_designer_job.R",
                  "modules/intervention_designer_module.R", "modules/analysis_intervention.R"))

i18n_echo <- list(t = function(k, ...) k, translator = NULL)
proj <- function() {
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1", "MPF_1", "GB_1"),
    label = c("Demand", "Boating", "Anchoring", "P. oceanica extension", "Habitat"),
    group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning", "Goods & Benefits"),
    stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "A_1", "P_1", "MPF_1"), to = c("A_1", "P_1", "MPF_1", "GB_1"),
                      polarity = c("+", "+", "-", "+"), strength = "medium", stringsAsFactors = FALSE)
  list(data = list(cld = list(nodes = nodes, edges = edges)))
}
# Synchronous fake job API: runs the engine in-process.
fake_api <- function(fail = FALSE) {
  list(start = function(payload) list(payload = payload),
       poll = function(job) if (fail) list(state = "error", message = "boom")
                            else list(state = "done", result = ses_run_design(job$payload)),
       cancel = function(job) invisible(TRUE))
}
real_designer_server <- get("intervention_designer_server", envir = .GlobalEnv)

test_that("designer UI has the conventional contract", {
  ui <- intervention_designer_ui("dz", i18n_echo)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("dz-", as.character(ui), fixed = TRUE))
  fm <- names(formals(intervention_designer_server))
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus", "job_api") %in% fm))
})

test_that("intervention page now has Quick compare and Designer tabs", {
  html <- as.character(analysis_intervention_ui("iv", i18n_echo))
  expect_true(grepl("modules.intervention_designer.tab_quick", html, fixed = TRUE))
  expect_true(grepl("modules.intervention_designer.tab_designer", html, fixed = TRUE))
  expect_true(grepl("iv-designer-", html, fixed = TRUE))
})

test_that("payload substitutes the node name at run time (review focus 2)", {
  net <- list(matrix = matrix(0, 2, 2, dimnames = rep(list(c("a", "b")), 2)))
  e <- data.frame(from = c(".NEW_NODE.", "b"), to = c("a", ".NEW_NODE."), kind = "intervention",
                  min_level = -1, max_level = 1, stringsAsFactors = FALSE)
  p <- .designer_payload(net, e, "Renamed IV", "a", character(0))
  expect_equal(p$design$new_node, "Renamed IV")
  expect_equal(p$design$edges$from, c("Renamed IV", "b"))
  expect_equal(p$design$edges$to, c("a", "Renamed IV"))
  e2 <- data.frame(from = "a", to = "a", kind = "context", min_level = 0, max_level = 1)
  expect_null(.designer_payload(net, e2, "", "a", character(0))$design$new_node)
})

test_that("server drives a design to results with a fake job API", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "Moorings", type = "", node_targets = "Anchoring",
                      node_indicators = "P. oceanica extension")
    session$setInputs(add_node_edges = 1)
    expect_equal(nrow(rv$edges), 2L)
    session$setInputs(self_loop_node = "P. oceanica extension", add_self_loop = 1)
    expect_equal(nrow(rv$edges), 3L)
    session$setInputs(objectives = "P. oceanica extension", sustain = "Habitat")
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_false(is.null(rv$result))
    expect_equal(rv$result$n_eval, 7^3)
    expect_equal(rv$result$design_matrix$new_node, "Moorings")
  })
})

test_that("renaming after adding edges carries them to the new name (review focus 2)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "Old", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1)
    session$setInputs(name = "New name", objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_equal(rv$result$design_matrix$new_node, "New name")
  })
})

test_that("Run is blocked with a reason when the design is incomplete", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    expect_equal(run_block_reason(), "modules.intervention_designer.need_edges")
    session$setInputs(name = "", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1)
    expect_equal(run_block_reason(), "modules.intervention_designer.need_name")
    session$setInputs(name = "Demand")
    expect_equal(run_block_reason(), "modules.intervention_designer.name_clash")
    session$setInputs(name = "IV", objectives = NULL)
    expect_equal(run_block_reason(), "modules.intervention_designer.need_objective")
  })
})

test_that("an existing edge is refused as a mode-B edge", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(edge_from = "Demand", edge_to = "Boating", add_edge = 1)
    expect_equal(nrow(rv$edges), 0L)
  })
})

test_that("a failing job shows an error and frees Run (review focus 5)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api(fail = TRUE)), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_null(rv$result)
    expect_match(rv$error, "boom")
    expect_null(run_block_reason())
  })
})

test_that("the comparison uses the network the run used, not the current one (review focus 3)", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    p2 <- proj(); p2$data$cld$edges <- p2$data$cld$edges[1:2, ]
    pd(p2)
    session$setInputs(top_table_rows_selected = 1)
    cmp <- selected_comparison()
    expect_equal(sum(rv$result$base != 0), 4L)               # the run's network, 4 edges
    expect_equal(cmp, ses_compare_interventions(
      rv$result$base, ses_apply_config(rv$result$design_matrix, rv$result$top_levels[, 1])))
  })
})
```

- [ ] **Step 2: Run to verify failure** — filter `^intervention-designer-module$`; fails (`intervention_designer_ui` not found; tabs absent).

- [ ] **Step 3: Implement the sub-module**

Create `modules/intervention_designer_module.R`:

```r
# modules/intervention_designer_module.R
# =============================================================================
# WP5 WS-7a Designer tab (spec 2026-10-14 §6): build a design (new node and/or
# new edges), run it in the background, show D5.3-ranked results.
# Depends on: functions/intervention_designer.R, functions/intervention_designer_job.R,
#             functions/wp5_vocabulary.R, functions/ses_dynamics.R
# =============================================================================

.DESIGNER_NEW <- ".NEW_NODE."

.designer_empty_edges <- function() {
  data.frame(from = character(), to = character(), kind = character(),
             min_level = numeric(), max_level = numeric(), stringsAsFactors = FALSE)
}

#' Payload for the worker; substitutes the node placeholder with `name`.
.designer_payload <- function(net, edges, name, objectives, sustain) {
  has_node <- any(edges$from == .DESIGNER_NEW | edges$to == .DESIGNER_NEW)
  edges$from[edges$from == .DESIGNER_NEW] <- name
  edges$to[edges$to == .DESIGNER_NEW] <- name
  list(base = net$matrix,
       design = list(new_node = if (has_node) name else NULL, edges = edges),
       levels = INTERVENTION_GRID_LEVELS,
       objectives = objectives, sustain = sustain %||% character(0),
       seed = INTERVENTION_DEFAULT_SEED, steps = INTERVENTION_N_STEPS,
       window = INTERVENTION_WINDOW, cap = INTERVENTION_GRID_CAP,
       chunk = INTERVENTION_CHUNK, top_k = INTERVENTION_TOP_K,
       max_boolean_nodes = DYNAMICS_MAX_BOOLEAN_NODES)
}

intervention_designer_ui <- function(id, i18n) {
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)
  ns <- NS(id)
  tagList(
    p(class = "text-muted mt-2", i18n$t("modules.intervention_designer.intro")),
    fluidRow(
      column(5, uiOutput(ns("design_ui"))),
      column(7, uiOutput(ns("results_ui")))
    )
  )
}

intervention_designer_server <- function(id, project_data_reactive, i18n, event_bus = NULL,
                                         job_api = designer_job_api()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(edges = .designer_empty_edges(), job = NULL, result = NULL,
                         progress = NULL, error = NULL, analysis_complete = FALSE)

    lvl_label <- function(x) {
      # i18n-ref: modules.intervention_designer.level.strong_neg
      # i18n-ref: modules.intervention_designer.level.medium_neg
      # i18n-ref: modules.intervention_designer.level.weak_neg
      # i18n-ref: modules.intervention_designer.level.none
      # i18n-ref: modules.intervention_designer.level.weak_pos
      # i18n-ref: modules.intervention_designer.level.medium_pos
      # i18n-ref: modules.intervention_designer.level.strong_pos
      vapply(ses_level_code(x), function(cd) i18n$t(paste0("modules.intervention_designer.level.", cd)),
             character(1))
    }
    level_choices <- function() setNames(as.character(INTERVENTION_GRID_LEVELS),
                                         lvl_label(INTERVENTION_GRID_LEVELS))
    node_name <- reactive(trimws(input$name %||% ""))
    show_name <- function(x) ifelse(x == .DESIGNER_NEW,
      if (nzchar(node_name())) node_name() else i18n$t("modules.intervention_designer.new_node_placeholder"), x)

    net <- reactive({
      data <- project_data_reactive()
      req(data, has_valid_cld(data))
      nodes <- data$data$cld$nodes
      labels <- ifelse(is.na(nodes$label) | nodes$label == "", nodes$id, nodes$label)
      types <- if ("group" %in% names(nodes)) as.character(nodes$group) else rep(NA_character_, nrow(nodes))
      list(labels = labels, types = types,
           matrix = cld_to_numeric_matrix(nodes, data$data$cld$edges, use_labels = TRUE))
    })

    # Stale results after an ISA change (standard analysis pattern)
    observe({
      req(!is.null(event_bus))
      event_bus$on_isa_change()
      if (isolate(rv$analysis_complete)) {
        showNotification(i18n$t("modules.analysis.common.data_changed_rerun"),
                         type = "warning", duration = 5, id = ns("stale_data"))
      }
    })

    # ── Design panel ───────────────────────────────────────────────────────
    output$design_ui <- renderUI({
      n <- net()
      lab <- n$labels
      types_df <- tryCatch({ load_wp5_intervention_ops(); get_intervention_types() },
                           error = function(e) data.frame(id = character(), group = character()))
      # i18n-ref: modules.intervention_designer.group.behavioural
      # i18n-ref: modules.intervention_designer.group.management
      # i18n-ref: modules.intervention_designer.group.economic
      # i18n-ref: modules.intervention_designer.group.governance
      type_choices <- c(setNames("", i18n$t("modules.intervention_designer.type_none")),
        lapply(split(types_df$id, types_df$group), function(ids)
          setNames(ids, vapply(ids, function(x) i18n$t(paste0("modules.intervention_designer.type.", x)),
                               character(1)))))
      names(type_choices)[-1] <- vapply(names(type_choices)[-1], function(g)
        i18n$t(paste0("modules.intervention_designer.group.", g)), character(1))
      gb <- lab[!is.na(n$types) & n$types == "Goods & Benefits"]
      loops <- ses_self_loop_candidates(lab, n$types)
      tagList(
        bs4Card(title = i18n$t("modules.intervention_designer.step_intervention"), width = 12,
                status = "primary", collapsible = FALSE,
          textInput(ns("name"), i18n$t("modules.intervention_designer.name"),
                    placeholder = i18n$t("modules.intervention_designer.name_placeholder")),
          selectizeInput(ns("type"), i18n$t("modules.intervention_designer.type"), choices = type_choices),
          uiOutput(ns("ops_ui"))),
        bs4Card(title = i18n$t("modules.intervention_designer.step_edges"), width = 12,
                status = "primary", collapsible = FALSE,
          h6(i18n$t("modules.intervention_designer.add_node_heading")),
          selectizeInput(ns("node_targets"), i18n$t("modules.intervention_designer.node_targets"),
                         choices = lab, multiple = TRUE),
          selectizeInput(ns("node_indicators"), i18n$t("modules.intervention_designer.node_indicators"),
                         choices = lab, multiple = TRUE),
          actionButton(ns("add_node_edges"), i18n$t("modules.intervention_designer.add_node_edges"),
                       icon = icon("plus")),
          hr(),
          h6(i18n$t("modules.intervention_designer.add_edge_heading")),
          fluidRow(column(6, selectInput(ns("edge_from"), i18n$t("modules.intervention_designer.edge_from"), lab)),
                   column(6, selectInput(ns("edge_to"), i18n$t("modules.intervention_designer.edge_to"), lab))),
          actionButton(ns("add_edge"), i18n$t("modules.intervention_designer.add_edge"), icon = icon("plus")),
          if (length(loops)) tagList(
            selectInput(ns("self_loop_node"), i18n$t("modules.intervention_designer.self_loop_node"), loops),
            actionButton(ns("add_self_loop"), i18n$t("modules.intervention_designer.add_self_loop"),
                         icon = icon("redo"))),
          hr(),
          tableOutput(ns("edges_table")),
          uiOutput(ns("edge_editor_ui"))),
        bs4Card(title = i18n$t("modules.intervention_designer.step_objectives"), width = 12,
                status = "primary", collapsible = FALSE,
          selectizeInput(ns("objectives"), i18n$t("modules.intervention_designer.objectives"),
                         choices = lab, multiple = TRUE),
          selectizeInput(ns("sustain"), i18n$t("modules.intervention_designer.sustain"),
                         choices = lab, selected = gb, multiple = TRUE)),
        bs4Card(title = i18n$t("modules.intervention_designer.step_run"), width = 12,
                status = "success", collapsible = FALSE,
          uiOutput(ns("grid_info")),
          actionButton(ns("run"), i18n$t("modules.intervention_designer.run"),
                       icon = icon("play"), class = "btn-success"))
      )
    })

    # ── Operations table (advisory, spec decision 2) ───────────────────────
    output$ops_ui <- renderUI({
      tp <- input$type %||% ""
      if (!nzchar(tp)) return(NULL)
      ops <- get_allowed_graph_ops(tp)
      used <- c(if (any(rv$edges$kind == "intervention")) "new_node",
                if (any(rv$edges$kind == "context")) "new_edge")
      # i18n-ref: modules.intervention_designer.op.new_node
      # i18n-ref: modules.intervention_designer.op.new_edge
      # i18n-ref: modules.intervention_designer.op.reweight_edge
      src_lbl <- function(s) paste(vapply(strsplit(s, "+", fixed = TRUE)[[1]], function(x)
        i18n$t(paste0("modules.intervention_designer.ops_source_", x)), character(1)), collapse = ", ")
      tagList(
        tags$small(strong(i18n$t("modules.intervention_designer.ops_heading")),
                   provenance_badge("provisional", i18n)),
        tags$ul(class = "small mb-1", lapply(seq_len(nrow(ops)), function(i)
          tags$li(i18n$t(paste0("modules.intervention_designer.op.", ops$op[i])), " (", src_lbl(ops$source[i]), ")"))),
        if (length(setdiff(used, ops$op)))
          div(class = "alert alert-warning py-1 small", i18n$t("modules.intervention_designer.ops_mismatch")),
        tags$small(class = "text-muted", i18n$t("modules.intervention_designer.prior_note"),
                   provenance_badge("toolbox_extension", i18n))
      )
    })

    # ── Adding and editing edges ──────────────────────────────────────────
    add_rows <- function(new) {
      cur <- rv$edges
      key <- paste(cur$from, cur$to, sep = "\r")
      new <- new[!paste(new$from, new$to, sep = "\r") %in% key, , drop = FALSE]
      rv$edges <- rbind(cur, new)
    }
    prior <- reactive(ses_evidence_prior_range(get_intervention_ebm_codes(input$type %||% ""),
                                               INTERVENTION_EVIDENCE_PRIORS))

    observeEvent(input$add_node_edges, {
      targets <- input$node_targets %||% character(0)
      inds <- input$node_indicators %||% character(0)
      if (!length(targets)) {
        showNotification(i18n$t("modules.intervention_designer.need_target"), type = "warning")
        return()
      }
      pr <- prior()
      mk <- function(from, to) data.frame(from = from, to = to, kind = "intervention",
        min_level = pr[["min"]], max_level = pr[["max"]], stringsAsFactors = FALSE)
      add_rows(rbind(mk(.DESIGNER_NEW, targets), if (length(inds)) mk(inds, .DESIGNER_NEW)))
    })

    add_context_edge <- function(from, to) {
      n <- net()
      if (from != to && n$matrix[from, to] != 0) {
        showNotification(i18n$t("modules.intervention_designer.edge_exists"), type = "warning")
        return(invisible(FALSE))
      }
      if (from != to) {
        msg <- ses_check_new_edge(n$types[match(from, n$labels)], n$types[match(to, n$labels)])
        if (!is.null(msg)) showNotification(
          paste(i18n$t("modules.intervention_designer.edge_rule_warning"), msg), type = "warning")
      }
      add_rows(data.frame(from = from, to = to, kind = "context", min_level = -1, max_level = 1,
                          stringsAsFactors = FALSE))
      invisible(TRUE)
    }
    observeEvent(input$add_edge, { req(input$edge_from, input$edge_to); add_context_edge(input$edge_from, input$edge_to) })
    observeEvent(input$add_self_loop, { req(input$self_loop_node); add_context_edge(input$self_loop_node, input$self_loop_node) })

    output$edges_table <- renderTable({
      e <- rv$edges
      if (!nrow(e)) return(data.frame(x = i18n$t("modules.intervention_designer.no_edges")) |>
                             setNames(" "))
      # i18n-ref: modules.intervention_designer.kind.intervention
      # i18n-ref: modules.intervention_designer.kind.context
      setNames(data.frame(
        seq_len(nrow(e)), show_name(e$from), show_name(e$to),
        vapply(e$kind, function(k) i18n$t(paste0("modules.intervention_designer.kind.", k)), character(1)),
        paste(lvl_label(e$min_level), "…", lvl_label(e$max_level)), stringsAsFactors = FALSE),
        c("#", i18n$t("modules.intervention_designer.col_from"), i18n$t("modules.intervention_designer.col_to"),
          i18n$t("modules.intervention_designer.col_kind"), i18n$t("modules.intervention_designer.col_range")))
    }, striped = TRUE, spacing = "xs")

    output$edge_editor_ui <- renderUI({
      e <- rv$edges
      if (!nrow(e)) return(NULL)
      choices <- setNames(as.character(seq_len(nrow(e))),
                          paste0(seq_len(nrow(e)), ": ", show_name(e$from), " → ", show_name(e$to)))
      tagList(
        selectInput(ns("edit_edge"), i18n$t("modules.intervention_designer.edit_edge"), choices),
        fluidRow(column(6, selectInput(ns("min_level"), i18n$t("modules.intervention_designer.min_level"),
                                       level_choices(), selected = "-1")),
                 column(6, selectInput(ns("max_level"), i18n$t("modules.intervention_designer.max_level"),
                                       level_choices(), selected = "1"))),
        actionButton(ns("apply_range"), i18n$t("modules.intervention_designer.apply_range"), class = "btn-sm"),
        actionButton(ns("sign_nonpos"), i18n$t("modules.intervention_designer.sign_nonpos"), class = "btn-sm"),
        actionButton(ns("sign_nonneg"), i18n$t("modules.intervention_designer.sign_nonneg"), class = "btn-sm"),
        actionButton(ns("remove_edge"), i18n$t("modules.intervention_designer.remove_edge"),
                     class = "btn-sm btn-outline-danger")
      )
    })
    edit_row <- reactive(as.integer(input$edit_edge %||% NA))
    observeEvent(input$apply_range, {
      i <- edit_row(); req(!is.na(i), i <= nrow(rv$edges))
      e <- rv$edges; e$min_level[i] <- as.numeric(input$min_level); e$max_level[i] <- as.numeric(input$max_level)
      rv$edges <- e
    })
    observeEvent(input$sign_nonpos, {
      i <- edit_row(); req(!is.na(i), i <= nrow(rv$edges))
      e <- rv$edges; e$min_level[i] <- min(e$min_level[i], 0); e$max_level[i] <- 0; rv$edges <- e
    })
    observeEvent(input$sign_nonneg, {
      i <- edit_row(); req(!is.na(i), i <= nrow(rv$edges))
      e <- rv$edges; e$min_level[i] <- 0; e$max_level[i] <- max(e$max_level[i], 0); rv$edges <- e
    })
    observeEvent(input$remove_edge, {
      i <- edit_row(); req(!is.na(i), i <= nrow(rv$edges))
      rv$edges <- rv$edges[-i, , drop = FALSE]
    })

    # ── Run gating ─────────────────────────────────────────────────────────
    level_sets <- reactive(ses_level_sets(rv$edges, INTERVENTION_GRID_LEVELS))
    run_block_reason <- reactive({
      e <- rv$edges
      if (!is.null(rv$job)) return("modules.intervention_designer.job_running")
      if (!nrow(e)) return("modules.intervention_designer.need_edges")
      if (any(lengths(level_sets()) == 0)) return("modules.intervention_designer.empty_range")
      if (any(e$from == .DESIGNER_NEW | e$to == .DESIGNER_NEW)) {
        if (!nzchar(node_name())) return("modules.intervention_designer.need_name")
        if (node_name() %in% net()$labels) return("modules.intervention_designer.name_clash")
      }
      if (!length(input$objectives)) return("modules.intervention_designer.need_objective")
      NULL
    })

    output$grid_info <- renderUI({
      reason <- run_block_reason()
      if (!is.null(reason) && reason != "modules.intervention_designer.job_running") {
        return(div(class = "text-muted small mb-2", i18n$t(reason)))
      }
      g <- ses_intervention_grid(level_sets(), cap = INTERVENTION_GRID_CAP, seed = INTERVENTION_DEFAULT_SEED)
      div(class = "small mb-2",
          format(g$n_total, big.mark = ",", scientific = FALSE), " ",
          i18n$t("modules.intervention_designer.combinations"), " — ",
          i18n$t(if (g$sampled) "modules.intervention_designer.sampled"
                 else "modules.intervention_designer.exhaustive"))
    })

    # ── Run, poll, cancel ──────────────────────────────────────────────────
    observeEvent(input$run, {
      reason <- run_block_reason()
      if (!is.null(reason)) { showNotification(i18n$t(reason), type = "warning"); return() }
      payload <- .designer_payload(net(), rv$edges, node_name(), input$objectives, input$sustain)
      rv$result <- NULL; rv$error <- NULL; rv$progress <- list(done = 0, total = NA_real_)
      rv$job <- tryCatch(job_api$start(payload), error = function(e) {
        rv$error <- format_user_error(e, i18n = i18n, context_key = "modules.intervention_designer.context_run")
        NULL
      })
    })

    observe({
      job <- rv$job
      req(job)
      invalidateLater(1000)
      st <- job_api$poll(job)
      if (identical(st$state, "running")) { rv$progress <- st; return() }
      rv$job <- NULL
      rv$progress <- NULL
      if (identical(st$state, "done")) {
        rv$result <- st$result
        rv$analysis_complete <- TRUE
      } else {
        rv$error <- paste(i18n$t("modules.intervention_designer.run_failed"), st$message %||% "")
      }
    })

    observeEvent(input$cancel, {
      job_api$cancel(rv$job)
      rv$job <- NULL; rv$progress <- NULL
      showNotification(i18n$t("modules.intervention_designer.cancelled"), type = "message")
    })

    session$onSessionEnded(function() {
      j <- isolate(rv$job)
      if (!is.null(j)) job_api$cancel(j)
    })

    # ── Results ────────────────────────────────────────────────────────────
    output$results_ui <- renderUI({
      if (!is.null(rv$job)) {
        pr <- rv$progress
        pct <- if (!is.null(pr) && is.finite(pr$total) && pr$total > 0) round(100 * pr$done / pr$total) else 0
        return(bs4Card(title = i18n$t("modules.intervention_designer.running"), width = 12, collapsible = FALSE,
          div(class = "progress mb-2", div(class = "progress-bar", role = "progressbar",
                                           style = sprintf("width: %d%%", pct), sprintf("%d%%", pct))),
          actionButton(ns("cancel"), i18n$t("modules.intervention_designer.cancel"),
                       icon = icon("stop"), class = "btn-outline-danger")))
      }
      if (!is.null(rv$error)) return(div(class = "alert alert-danger", rv$error))
      r <- rv$result
      if (is.null(r)) return(div(class = "text-muted mt-4", i18n$t("modules.intervention_designer.help_designer")))
      # i18n-ref: modules.intervention_designer.precheck.passed
      # i18n-ref: modules.intervention_designer.precheck.topology_change_needed
      # i18n-ref: modules.intervention_designer.precheck.skipped
      # i18n-ref: modules.intervention_designer.precheck.unavailable
      pc_class <- switch(r$precheck$status, passed = "alert-success",
                         topology_change_needed = "alert-warning", "alert-secondary")
      fmt <- function(x) format(x, big.mark = ",", scientific = FALSE)
      tagList(
        div(class = paste("alert py-2", pc_class),
            i18n$t(paste0("modules.intervention_designer.precheck.", r$precheck$status))),
        bs4Card(title = i18n$t("modules.intervention_designer.result_share"), width = 12, collapsible = FALSE,
          h4(sprintf("%s / %s (%.1f%%)", fmt(r$n_a), fmt(r$n_eval), 100 * r$share)),
          if (isTRUE(r$sampled)) p(class = "text-warning small", i18n$t("modules.intervention_designer.estimate_note")),
          tags$ul(class = "small",
            tags$li(i18n$t("modules.intervention_designer.result_pass_a"), ": ", fmt(r$n_a)),
            tags$li(i18n$t("modules.intervention_designer.result_pass_ab"), ": ", fmt(r$n_ab)),
            tags$li(i18n$t("modules.intervention_designer.result_pass_abc"), ": ", fmt(r$n_abc))),
          tags$small(class = "text-muted", i18n$t("modules.intervention_designer.run_meta"), ": ",
                     r$seed, " / ", r$steps, " / ", r$window)),
        bs4Card(title = i18n$t("modules.intervention_designer.top_heading"), width = 12, collapsible = FALSE,
          DT::DTOutput(ns("top_table")),
          p(class = "text-muted small mt-2", i18n$t("modules.intervention_designer.select_row_hint")),
          plotly::plotlyOutput(ns("compare_plot"), height = "350px"))
      )
    })

    output$top_table <- DT::renderDT({
      r <- rv$result; req(r)
      yn <- function(x) ifelse(x %in% TRUE, i18n$t("modules.intervention_designer.yes"),
                               i18n$t("modules.intervention_designer.no"))
      e <- r$design_matrix$edges
      lv <- as.data.frame(t(apply(r$top_levels, 2, lvl_label)), stringsAsFactors = FALSE)
      names(lv) <- paste(e$from, "→", e$to)
      df <- cbind(data.frame(r$top$rank, yn(r$top$a), yn(r$top$b), yn(r$top$c), r$top$d,
                             stringsAsFactors = FALSE), lv)
      names(df)[1:5] <- c(i18n$t("modules.intervention_designer.col_rank"),
                          i18n$t("modules.intervention_designer.col_a"),
                          i18n$t("modules.intervention_designer.col_b"),
                          i18n$t("modules.intervention_designer.col_c"),
                          i18n$t("modules.intervention_designer.col_d"))
      DT::datatable(df, selection = "single", rownames = FALSE,
                    options = list(pageLength = 10, scrollX = TRUE, dom = "tip"))
    })

    # Uses the network stored with the result (review focus 3)
    selected_comparison <- reactive({
      r <- rv$result; i <- input$top_table_rows_selected
      req(r, length(i) == 1)
      ses_compare_interventions(r$base, ses_apply_config(r$design_matrix, r$top_levels[, i]))
    })

    output$compare_plot <- plotly::renderPlotly({
      cmp <- selected_comparison()
      plotly::plot_ly(cmp, x = ~node) |>
        plotly::add_bars(y = ~state_original, name = i18n$t("modules.intervention_designer.compare_original")) |>
        plotly::add_bars(y = ~state_intervention, name = i18n$t("modules.intervention_designer.compare_selected")) |>
        plotly::layout(title = i18n$t("modules.intervention_designer.compare_title"), barmode = "group",
                       xaxis = list(title = ""), yaxis = list(title = ""))
    })
  })
}
```

- [ ] **Step 4: Mount it on the Intervention page**

In `modules/analysis_intervention.R`, replace the UI body (lines 24–28):

```r
  tagList(
    uiOutput(ns("module_header")),
    uiOutput(ns("cld_check_ui")),
    tabsetPanel(
      id = ns("mode_tabs"), type = "tabs",
      tabPanel(title = i18n$t("modules.intervention_designer.tab_quick"), value = "quick",
               uiOutput(ns("main_ui"))),
      tabPanel(title = i18n$t("modules.intervention_designer.tab_designer"), value = "designer",
               intervention_designer_ui(ns("designer"), i18n))
    )
  )
```

In the server, inside `create_help_observer(... content = tagList(...))`, add two paragraphs after `help_compare`:

```r
        p(i18n$t("modules.intervention_designer.help_designer")),
        p(i18n$t("modules.intervention_designer.help_delay"))
```

and after the `setup_cld_gate(...)` call add:

```r
    # ── WS-7a Designer tab ───────────────────────────────────────────────
    intervention_designer_server("designer", project_data_reactive, i18n, event_bus = event_bus)
```

In `app.R`, add to the `CRITICAL_MODULES` vector, on the line before `"modules/analysis_intervention.R",`:

```r
  "modules/intervention_designer_module.R",  # WP5 WS-7a Designer tab (sub-module of the Intervention page)
```

- [ ] **Step 5: Run to verify pass**

Filters: `^intervention-designer-module$`, `^intervention-designer$`, `^intervention-designer-d53$`, `^modules$`, `^module-signatures$`, `^i18n-enforcement$`, `^functions-sourced-in-app$`. Expected: all PASS.
Then `micromamba run -n shiny python scripts/_i18n_audit.py` → `missing=0, hardcoded=0`.

- [ ] **Step 6: Smoke-run the app**

Start the app from the worktree app dir (`Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); shiny::runApp('.', port = 4848, launch.browser = FALSE)"` in the background), load a template project with a CLD, open Intervention → Designer (D5.3), add a node with two targets and one indicator, choose an objective, Run. Confirm progress, results, the top table, and the comparison plot; confirm Quick compare still works. Stop the app.

- [ ] **Step 7: Commit** — `"feat(wp5): WS-7a Designer tab on the Intervention page"`.

---

### Task 9: Release 1.27.0

**Files:**
- Modify: `MarineSABRES_SES_Shiny/VERSION`, `DESCRIPTION` (`Version:`), `VERSION_INFO.json`, `CHANGELOG.md`

- [ ] **Step 1: Bump version files** (Windows line endings in `VERSION_INFO.json`: edit in place, preserve CRLF)

- `VERSION` → `1.27.0`; `DESCRIPTION` `Version: 1.27.0`.
- `VERSION_INFO.json`: `"version": "1.27.0"`, `"version_name": "WP5 intervention designer (D5.3 modes A and B)"`, `"release_date": "<today>"`, `"release_type": "minor"`, `"previous_version": "1.26.1"`; append to `features`: `"WP5 intervention designer (D5.3): exhaustive ordinal grid over a new intervention node and/or new edges between existing nodes, ranked by objective, also-sustain, stability and simplicity; Boolean pre-check; runs in a background process (WS-7a)."`
- `CHANGELOG.md`: new section under `## [Unreleased]`:

```markdown
## [1.27.0] - <today>

### Added (WP5 intervention designer — spec 2026-10-14 WS-7a)
- Intervention page gets a "Designer (D5.3)" tab next to "Quick compare". It adds a new intervention node (mode A), new edges between existing nodes including a biological self-loop helper (mode B), or both, and tests every combination of ordinal levels (−1 … 1) on those edges, or a seeded sample of 50,000 above that size.
- Results follow D5.3: share of combinations whose objective nodes stay positive over the last 100 of 1,000 steps, also-sustain nodes (default all Goods & Benefits), stability (all Laplacian eigenvalues real) and the number of intervention edges used; top 20 combinations with a final-state comparison.
- Boolean pre-check reports "topology change needed" when no attractor keeps the objectives on (skipped above 20 nodes).
- Picking an intervention type shows the operations the D5.3 matrix and the EBM framework list for it (provisional, advisory) and pre-fills default ranges from the evidence priors (toolbox extension).
- Grids run in a background R process (callr), so other users of the server are not blocked; Cancel stops a run.

### Dependencies
- `callr` and `Matrix` added to the required packages (both already installed on laguna).
```

- [ ] **Step 2: Full verification**

Run the full suite in alphabetical chunks (one Rscript each; background runs get reaped for low memory), e.g. filters `^[a-c]`, `^[d-h]`, `^[i-l]`, `^[m-o]`, `^[p-s]`, `^[t-z]` with the Global Constraints command and `reporter='summary'`. Expected: 0 failures except the known timing-flaky ML test, if it recurs (report it, do not change it). Then `micromamba run -n shiny python scripts/_i18n_audit.py` → `missing=0, hardcoded=0`, and `Rscript deployment/pre-deploy-check.R`.

- [ ] **Step 3: Commit and open the PR**

Commit `"chore(release): 1.27.0 — WP5 intervention designer (WS-7a)"`, push the branch, open a PR against `main` titled `feat(wp5): WS-7a intervention designer (D5.3 modes A and B) — release 1.27.0`, body: summary, the D5.3 fixture numbers (none 239 / weak 373 / strong 733 of 1,024), the decisions in spec §2, deferred items (spec §8), test plan, and `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Do not merge, tag or deploy without the user's instruction.
