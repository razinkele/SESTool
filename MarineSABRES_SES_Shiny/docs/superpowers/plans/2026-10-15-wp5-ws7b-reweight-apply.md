# WP5 WS-7b Intervention Designer (mode C, before/after, Apply to project) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add D5.3 mode C (re-weighting existing links with fixed sign), a "what success depends on" table, a before/after structure comparison, and "Apply to project" (writes a Scenario Builder scenario with `ops` and `links_modified`) to the Designer tab shipped in 1.27.0.

**Architecture:** Mode C is a new variable-edge kind (`reweight`) in the 7a grid engine (`functions/intervention_designer.R`), so sampling, ranking, stability and the callr worker are reused. Pure scenario helpers move to a new `functions/scenario_network.R` shared by the Scenario Builder, the Designer and a second worker job type (`compare`). The Designer module gains a mode-C panel ranked by dominant-eigenvalue link sensitivity, a dependence table, a compare panel and an Apply modal.

**Tech Stack:** R ≥ 4.4.1, Shiny + bs4Dash, shiny.i18n, Matrix, igraph, dplyr, callr, testthat 3, DT, plotly.

**Spec:** `MarineSABRES_SES_Shiny/docs/superpowers/specs/2026-10-15-wp5-ws7b-reweight-apply-design.md` (read it; it is the authority). 7a spec: `.../specs/2026-10-14-wp5-ws7a-intervention-designer-design.md`.

All paths below are relative to `MarineSABRES_SES_Shiny/` in the worktree `C:/Users/arturas.baziukas/wt-ws7b` (branch `feat/wp5-ws7b-reweight-apply`). The git root is one level up: use `git -C C:/Users/arturas.baziukas/wt-ws7b ...`, never `cd <path> && git`.

## Global Constraints

- **Run tests** (PowerShell or Bash, from the app dir) with the user library first, one file filter at a time; never the whole suite in one process:
  `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^intervention-designer-reweight$')"`
  (`filter` matches the file name without `test-` and `.R`.)
- Engine files (`functions/intervention_designer.R`, `functions/scenario_network.R`) are also sourced in the callr worker, which has **no `constants.R`, no `%||%`, no `debug_log`**: every function the worker calls takes its parameters explicitly and must not use `%||%`.
- Mode C level set: `sign(w) × {0.25, 0.5, 1}` intersected with the row's `[min_level, max_level]`; never 0, never the other sign.
- Edge kinds: `"intervention"` (edges of the new node), `"context"` (new edge between existing nodes, op `new_edge`), `"reweight"` (op `reweight_edge`).
- `INTERVENTION_DEPENDENCE_MIN_SUCCESS <- 30L` (constants.R); passed to the worker in the payload as `dependence_min_success`.
- Edge identity in scenarios: `links_modified` entries are matched to baseline edges by `from` and `to` **node ids**, never by edge `id` (ids are renumbered by the CLD editor).
- Matrix row names → node ids **positionally**, by the `cld_to_numeric_matrix()` naming rule (label, else id; `make.unique(sep = "_")`), never `match(label, nodes$label)`.
- 7a behaviour must not change: `test-intervention-designer-d53.R` counts (733 / 733 / 5) and every existing `test-intervention-designer*.R` keep passing unchanged.
- All user-facing text through `i18n$t()`, 9 languages (en, es, fr, de, lt, pt, it, no, el) in `translations/modules/*.json`; dynamic keys get `# i18n-ref:` sentinels; `micromamba run -n shiny python scripts/_i18n_audit.py` must report `missing=0` and `hardcoded=0`. Never edit `translations/_merged_translations.json`.
- Logging via `debug_log()`; user errors via `format_user_error(e, i18n = i18n, context_key = ...)`.
- No new packages (igraph, dplyr, callr, Matrix are already dependencies).
- Commits: write the message to a scratch file and `git -C <wt> commit -F <file>`; end every message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `docs/` is gitignored: plan/spec changes need `git add -f`.

## Rulings made while planning (recorded here so reviewers do not flag them)

1. **Edge identity by endpoints** (spec §5.2 amended): see Global Constraints.
2. **`scenario_network.R`** instead of moving `scenario_loops()` into `network_analysis.R` (spec §4.4 amended): it also holds `scenario_apply_modifications()`, which the Designer reuses so Compare shows exactly what Apply writes.
3. **Worker `debug_log` stub goes in the global environment** (spec §4.4 amended): a function-local stub is not found by files sourced with `local = FALSE`, and `scenario_loops()`'s `tryCatch` silently returns 0 loops.
4. **Mode C panel uses "Add ticked links"** rather than live tick/untick sync (spec §4.1 amended); rows are removed in the existing edge editor.
5. **Existing bug fixed in passing:** `apply_scenario_modifications()` does `rbind(edges, new_edges)` where the baseline edges have more columns than the new rows, which errors. `scenario_apply_modifications()` fills missing columns with `NA` (Task 4).

## Review Focus

1. A `reweight` row whose link changed **sign** in the CLD between adding and Run → Run disabled with `reweight_stale`, never a worker error (Task 7 test).
2. Apply after a CLD edit that renumbered edge ids → the modified link is still the right one, because matching is by endpoints (Task 4 test).
3. `decisive` with exactly 29 vs 30 successes → NA vs a real verdict (Task 2 test).
4. A network whose two largest-modulus eigenvalues are λ and −λ (or three equal moduli) → ranking returns NULL, panel shows `ranking_unavailable` and lists links unranked (Task 3 + Task 7 tests).
5. Compare where either side hits the 500-loop cap → panel says the lists are truncated (Task 5 test on `ses_loop_diff()`).

---

## File map

| File | Task | Responsibility |
|---|---|---|
| `functions/intervention_designer.R` | 1, 2, 3, 5 | engine: `reweight` kind, `base_levels`, (d), positions, dependence, link sensitivity, attractor summary, config → scenario/network, compare |
| `functions/scenario_network.R` (new) | 4 | `scenario_loops()`, `scenario_apply_modifications()` |
| `functions/intervention_designer_job.R` | 5 | `type = "compare"` worker, engine file lists |
| `modules/scenario_builder_module.R` | 4 | uses the moved helpers; `links_modified` counts/badges; `predict_impacts()` re-weight impact + `links_removed` fix |
| `global.R` | 4 | source `functions/scenario_network.R` |
| `constants.R` | 2 | `INTERVENTION_DEPENDENCE_MIN_SUCCESS` |
| `translations/modules/intervention_designer.json`, `translations/modules/scenario_builder.json` | 6 | new keys |
| `modules/intervention_designer_module.R` | 7, 8 | mode-C panel, gating, dependence, compare, Apply |
| tests | each task | see tasks |
| `VERSION`, `VERSION_INFO.json`, `DESCRIPTION`, `CHANGELOG.md` | 9 | release 1.28.0 |

---

### Task 1: `reweight` edge kind, `base_levels`, criterion (d)

**Files:**
- Modify: `functions/intervention_designer.R` (`ses_design_matrix()` ~line 99-140; `ses_run_design()` (d) line ~313)
- Create: `tests/testthat/test-intervention-designer-reweight.R`

**Interfaces:**
- Produces: `ses_design_matrix(base, design, levels)` now returns `list(matrix, cells, level_sets, new_node, edges, base_levels, count_rows)`. `base_levels`: numeric, one per variable edge, the baseline weight for `reweight` rows and 0 otherwise. `count_rows`: when any `intervention` row exists, the `intervention` and `reweight` rows (sorted); otherwise all rows.
- Produces: `ses_run_design()` `top$d` = number of `count_rows` edges whose level differs from `base_levels`.

- [ ] **Step 1: Write the failing tests** — create `tests/testthat/test-intervention-designer-reweight.R`:

```r
# tests/testthat/test-intervention-designer-reweight.R
# WS-7b mode C (spec 2026-10-15 §3): re-weighting existing links, sign fixed.
source_for_test("functions/intervention_designer.R")

LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)

# Small graph with a decisive link by construction (verified while planning):
# a-b is a growing core with x_a / x_b ~ 1.28; d gets +w from a and -1 from b,
# so the objective d > 0 needs w(a -> d) = strong; d -> e has no effect on d.
dep_base <- function() {
  nm <- c("a", "b", "d", "e")
  m <- matrix(0, 4, 4, dimnames = list(nm, nm))
  m["a", "a"] <- 0.5; m["a", "b"] <- 1; m["b", "a"] <- 1
  m["a", "d"] <- 0.5; m["b", "d"] <- -1; m["d", "e"] <- 0.5
  m
}
rw <- function(from, to, min = -1, max = 1, kind = "reweight")
  data.frame(from = from, to = to, kind = kind, min_level = min, max_level = max,
             stringsAsFactors = FALSE)
dep_payload <- function(edges, new_node = NULL) {
  list(base = dep_base(), design = list(new_node = new_node, edges = edges), levels = LV,
       objectives = "d", sustain = character(0), seed = 1L, steps = 1000L, window = 100L,
       cap = 65536, chunk = 2048L, top_k = 10L, max_boolean_nodes = 20L)
}

test_that("reweight level sets keep the link's sign and respect narrowing", {
  dm <- ses_design_matrix(dep_base(), list(new_node = NULL, edges = rw(c("a", "b"), c("d", "d"))), LV)
  expect_equal(dm$level_sets[[1]], c(0.25, 0.5, 1))
  expect_equal(dm$level_sets[[2]], c(-1, -0.5, -0.25))
  expect_equal(dm$base_levels, c(0.5, -1))
  expect_equal(unname(dm$matrix["a", "d"]), 0)                  # variable cells are zeroed
  narrowed <- ses_design_matrix(dep_base(), list(new_node = NULL, edges = rw("a", "d", 0.25, 0.5)), LV)
  expect_equal(narrowed$level_sets[[1]], c(0.25, 0.5))
  flipped <- ses_design_matrix(dep_base(), list(new_node = NULL, edges = rw("a", "d", -1, -0.25)), LV)
  expect_length(flipped$level_sets[[1]], 0)                     # never the other sign
})

test_that("reweight must sit on an existing link; other kinds still must not", {
  expect_error(ses_design_matrix(dep_base(), list(new_node = NULL, edges = rw("d", "a")), LV),
               "must exist in the network")
  expect_error(ses_design_matrix(dep_base(), list(new_node = NULL, edges = rw("a", "d", kind = "context")), LV),
               "already exists in the network")
})

test_that("count_rows: intervention + reweight rows when a node exists, else all rows", {
  e <- rbind(rw("IV", "a", kind = "intervention"), rw("a", "d"), rw("e", "e", 0, 1, kind = "context"))
  dm <- ses_design_matrix(dep_base(), list(new_node = "IV", edges = e), LV)
  expect_equal(dm$count_rows, c(1L, 2L))                        # the self-loop pre-step is not counted
  expect_equal(dm$base_levels, c(0, 0.5, 0))
  dm2 <- ses_design_matrix(dep_base(), list(new_node = NULL, edges = rbind(rw("a", "d"), rw("e", "e", 0, 1, kind = "context"))), LV)
  expect_equal(dm2$count_rows, 1:2)
})

test_that("(d) counts links that differ from the baseline", {
  r <- ses_run_design(dep_payload(rbind(rw("a", "d"), rw("d", "e"))))
  expect_equal(r$n_eval, 9)
  expect_equal(r$n_a, 3)                                        # only a -> d = strong succeeds
  dm <- r$design_matrix
  expect_equal(r$top$d, unname(colSums(r$top_levels != dm$base_levels)))
  # a -> d strong with d -> e unchanged (0.5) is one change; with d -> e weak, two.
  # (Ranking sorts on stability (c) before (d), so look the columns up, not rank 1.)
  col_of <- function(v) which(r$top_levels[1, ] == v[1] & r$top_levels[2, ] == v[2])
  expect_equal(r$top$d[col_of(c(1, 0.5))], 1L)
  expect_equal(r$top$d[col_of(c(1, 0.25))], 2L)
})
```

- [ ] **Step 2: Run to verify they fail**

Run: `Rscript -e ".libPaths(c('C:/Users/arturas.baziukas/AppData/Local/R/win-library/4.4', .libPaths())); testthat::test_dir('tests/testthat', filter = '^intervention-designer-reweight$')"`
Expected: FAIL (`a variable edge already exists in the network`, `base_levels` NULL).

- [ ] **Step 3: Implement** — in `ses_design_matrix()`, replace the block from `existing_cell <- ...` through the `list(...)` return with:

```r
  existing_cell <- ri <= nrow(base) & ci <= ncol(base)
  is_rw <- edges$kind == "reweight"
  base_w <- numeric(nrow(edges))
  base_w[existing_cell] <- base[cbind(ri[existing_cell], ci[existing_cell])]
  if (any(is_rw & base_w == 0)) stop("a re-weighted edge must exist in the network")
  if (any(!is_rw & base_w != 0)) {
    stop("a variable edge already exists in the network (re-weighting is mode C)")
  }
  cells <- cbind(row = ri, col = ci)
  mat[cells] <- 0
  level_sets <- ses_level_sets(edges, levels)
  # Mode C (spec 2026-10-15 §3.1): the link's own sign, weak/medium/strong, within [min, max]
  for (k in which(is_rw)) {
    cand <- sort(sign(base_w[k]) * c(0.25, 0.5, 1))
    level_sets[[k]] <- cand[cand >= edges$min_level[k] - 1e-12 & cand <= edges$max_level[k] + 1e-12]
  }
  is_int <- edges$kind == "intervention"
  list(
    matrix = mat,
    cells = cells,
    level_sets = level_sets,
    new_node = new_node,
    edges = edges,
    base_levels = ifelse(is_rw, base_w, 0),
    # (d) counts the intervention's own edges plus every re-weighted link (§3.2)
    count_rows = if (any(is_int)) sort(c(which(is_int), which(is_rw))) else seq_len(nrow(edges))
  )
```

Update the roxygen `@return` line to `list(matrix, cells, level_sets, new_node, edges, base_levels, count_rows)`.

In `ses_run_design()` replace the (d) line with:

```r
    d[pos] <- as.integer(colSums(cfg[dm$count_rows, , drop = FALSE] != dm$base_levels[dm$count_rows]))
```

- [ ] **Step 4: Run the new tests and the 7a regressions**

Run the command of Step 2, then the same with `filter = '^intervention-designer'` (all designer files).
Expected: all PASS; `test-intervention-designer-d53.R` still asserts 733/733/5 unchanged.

- [ ] **Step 5: Commit** — `feat(wp5): mode C reweight edge kind, base levels and (d) from baseline (WS-7b)`.

---

### Task 2: success dependence (`ses_grid_decode_positions`, `ses_edge_dependence`)

**Files:**
- Modify: `functions/intervention_designer.R` (after `ses_grid_decode()`; in `ses_run_design()`), `constants.R` (after `INTERVENTION_EVIDENCE_PRIORS`, ~line 925)
- Test: `tests/testthat/test-intervention-designer-reweight.R` (append)

**Interfaces:**
- Consumes: Task 1 `ses_design_matrix()`.
- Produces: `ses_grid_decode_positions(idx, level_sets)` → integer matrix (variable edges × idx), 1-based positions in each level set. `ses_edge_dependence(codes, level_sets, edges, min_success)` → `NULL` or a data.frame with columns `from`, `to`, `kind`, `decisive` (logical, NA below `min_success`), list columns `levels`, `shares`, `needed_levels`; attribute `n_success`. `ses_run_design()` result gains `dependence` and reads `payload$dependence_min_success` (default 30 when NULL).
- Produces: `INTERVENTION_DEPENDENCE_MIN_SUCCESS <- 30L`.

- [ ] **Step 1: Append failing tests**

```r
test_that("decode positions match decoded values", {
  ls <- list(c(0.25, 0.5, 1), c(-1, -0.5, -0.25), c(0, 1))
  idx <- c(1, 5, 18)
  pos <- ses_grid_decode_positions(idx, ls)
  expect_true(is.integer(pos))
  vals <- ses_grid_decode(idx, ls)
  for (k in seq_along(ls)) expect_equal(ls[[k]][pos[k, ]], vals[k, ])
})

test_that("edge dependence: decisive = successes use a strict subset of levels", {
  ls <- list(c(0.25, 0.5, 1), c(-1, -0.5, -0.25), c(0, 1))
  e <- data.frame(from = c("a", "b", "IV"), to = c("d", "d", "a"),
                  kind = c("reweight", "reweight", "intervention"), stringsAsFactors = FALSE)
  codes <- rbind(rep(3L, 30), rep(1:3, length.out = 30), rep(1:2, 15))
  dep <- ses_edge_dependence(codes, ls, e, min_success = 30L)
  expect_equal(dep$decisive, c(TRUE, FALSE, FALSE))
  expect_equal(dep$needed_levels[[1]], 1)
  expect_equal(dep$shares[[1]], c(0, 0, 1))
  expect_equal(dep$levels[[2]], c(-1, -0.5, -0.25))
  expect_equal(attr(dep, "n_success"), 30L)
})

test_that("edge dependence: below the threshold no verdict (29 vs 30, review focus 3)", {
  ls <- list(c(0.25, 0.5, 1))
  e <- data.frame(from = "a", to = "d", kind = "reweight", stringsAsFactors = FALSE)
  expect_true(is.na(ses_edge_dependence(matrix(3L, 1, 29), ls, e, 30L)$decisive))
  expect_true(ses_edge_dependence(matrix(3L, 1, 30), ls, e, 30L)$decisive)
  expect_null(ses_edge_dependence(NULL, ls, e, 30L))
  expect_null(ses_edge_dependence(matrix(integer(0), 1, 0), ls, e, 30L))
})

test_that("run returns dependence over the (a)-passing configurations", {
  p <- dep_payload(rbind(rw("a", "d"), rw("d", "e")))
  p$dependence_min_success <- 1L
  dep <- ses_run_design(p)$dependence
  expect_equal(dep$decisive, c(TRUE, FALSE))
  expect_equal(dep$needed_levels[[1]], 1)                       # success needs a -> d strong
  expect_equal(dep$shares[[2]], c(1, 1, 1) / 3)
  expect_true(is.na(ses_run_design(dep_payload(rbind(rw("a", "d"), rw("d", "e"))))$dependence$decisive[1]))
})
```

- [ ] **Step 2: Run to verify they fail** (command of Task 1 Step 2). Expected: FAIL, `could not find function "ses_grid_decode_positions"`.

- [ ] **Step 3: Implement** — after `ses_grid_decode()` add:

```r
#' Decode 1-based grid indices into level positions (same mixed radix as
#' ses_grid_decode()): integer matrix, one row per variable edge.
ses_grid_decode_positions <- function(idx, level_sets) {
  sizes <- lengths(level_sets)
  r <- as.numeric(idx) - 1
  out <- matrix(0L, nrow = length(sizes), ncol = length(idx))
  for (j in seq_along(sizes)) {
    d <- r %% sizes[j]
    out[j, ] <- as.integer(d + 1)
    r <- (r - d) / sizes[j]
  }
  out
}

#' D5.3 "success depended on" (FIN:584-592, spec 2026-10-15 §3.3): share of the
#' successful configurations at each level of every variable edge. An edge is
#' decisive when successes use a strict subset of its levels; with fewer than
#' `min_success` successes no verdict is given (decisive = NA).
#' @param codes integer matrix (variable edges x successful configurations) of level positions
#' @return NULL when there are no successes, else a data.frame (see spec)
ses_edge_dependence <- function(codes, level_sets, edges, min_success) {
  if (is.null(codes) || ncol(codes) == 0) return(NULL)
  n_s <- ncol(codes)
  shares <- lapply(seq_along(level_sets), function(k)
    tabulate(codes[k, ], nbins = length(level_sets[[k]])) / n_s)
  decisive <- vapply(shares, function(s) if (n_s < min_success) NA else any(s == 0), logical(1))
  out <- data.frame(from = edges$from, to = edges$to, kind = edges$kind, decisive = decisive,
                    stringsAsFactors = FALSE)
  out$levels <- level_sets
  out$shares <- shares
  out$needed_levels <- lapply(seq_along(level_sets), function(k)
    if (isTRUE(decisive[k])) level_sets[[k]][shares[[k]] > 0] else numeric(0))
  attr(out, "n_success") <- n_s
  out
}
```

In `ses_run_design()`: before the chunk loop add `succ_codes <- list()`; inside the loop after `b[pos] <- r$b` add

```r
    if (any(r$a)) succ_codes[[length(succ_codes) + 1L]] <- ses_grid_decode_positions(index[pos][r$a], dm$level_sets)
```

after the loop add

```r
  min_success <- if (is.null(payload$dependence_min_success)) 30L else as.integer(payload$dependence_min_success)
  dependence <- ses_edge_dependence(if (length(succ_codes)) do.call(cbind, succ_codes) else NULL,
                                    dm$level_sets, dm$edges, min_success)
```

and add `dependence = dependence,` to the returned list (after `top_levels`). Document `dependence_min_success` in the `@param payload` line.

In `constants.R` after `INTERVENTION_EVIDENCE_PRIORS` add:

```r
INTERVENTION_DEPENDENCE_MIN_SUCCESS <- 30L  # fewest successes for a "decisive link" verdict (WS-7b §3.3)
```

- [ ] **Step 4: Run tests** — reweight file, then `filter = '^intervention-designer'`. Expected: PASS.

- [ ] **Step 5: Commit** — `feat(wp5): success dependence per variable edge (WS-7b)`.

---

### Task 3: link sensitivity ranking and attractor summary

**Files:**
- Modify: `functions/intervention_designer.R` (after `ses_is_stable_attractor()`; refactor `ses_boolean_precheck()`)
- Test: `tests/testthat/test-intervention-designer-reweight.R` (append)

**Interfaces:**
- Produces: `ses_link_sensitivity(mat)` → NULL or data.frame(`from`, `to`, `weight`, `sensitivity`) sorted by sensitivity desc, then from, to. `ses_boolean_attractor_summary(M, objective_idx, max_nodes)` → `list(status, n_nodes, n_attractors, n_desirable)` with status `passed` / `topology_change_needed` / `skipped` / `unavailable`.

- [ ] **Step 1: Append failing tests**

```r
sens_small <- function() {
  m <- matrix(0, 4, 4, dimnames = rep(list(c("a", "b", "c", "d")), 2))
  m["a", "b"] <- 1; m["b", "a"] <- 0.5; m["b", "c"] <- 0.25; m["c", "a"] <- 0.25; m["d", "a"] <- 0.5
  m
}
dominant <- function(m, near) { ev <- eigen(t(m))$values; ev[which.min(Mod(ev - near))] }

test_that("link sensitivity equals a finite-difference estimate", {
  m <- sens_small()
  s <- ses_link_sensitivity(m)
  lam <- dominant(m, 10)
  for (i in seq_len(nrow(s))) {
    m2 <- m; m2[s$from[i], s$to[i]] <- m2[s$from[i], s$to[i]] + 1e-6
    expect_equal(Mod((dominant(m2, lam) - lam) / 1e-6), s$sensitivity[i], tolerance = 1e-4)
  }
  expect_equal(s$sensitivity[s$from == "d"], 0)                 # d has no incoming links
  expect_equal(s$sensitivity, sort(s$sensitivity, decreasing = TRUE))
})

test_that("link sensitivity does not depend on node order", {
  m <- sens_small()
  s1 <- ses_link_sensitivity(m)
  p <- c(3, 1, 4, 2)
  s2 <- ses_link_sensitivity(m[p, p])
  k1 <- paste(s1$from, s1$to); k2 <- paste(s2$from, s2$to)
  expect_equal(s2$sensitivity[match(k1, k2)], s1$sensitivity, tolerance = 1e-8)
})

test_that("link sensitivity: degenerate networks give NULL (review focus 4)", {
  expect_null(ses_link_sensitivity(matrix(0, 2, 2)))
  cyc <- matrix(0, 3, 3, dimnames = rep(list(c("a", "b", "c")), 2))
  cyc["a", "b"] <- cyc["b", "c"] <- cyc["c", "a"] <- 0.5        # three eigenvalues of equal modulus
  expect_null(ses_link_sensitivity(cyc))
  two <- matrix(c(0, 1, 1, 0), 2, 2, dimnames = rep(list(c("a", "b")), 2))   # eigenvalues 1 and -1
  expect_null(ses_link_sensitivity(two))
})

test_that("attractor summary: skipped above the node limit, same result as the pre-check", {
  big <- matrix(0, 25, 25, dimnames = rep(list(paste0("n", 1:25)), 2))
  expect_equal(ses_boolean_attractor_summary(big, 1L, 20L)$status, "skipped")
  skip_if_not_installed("BoolNet")
  m <- dep_base()
  s <- ses_boolean_attractor_summary(m, match("d", rownames(m)), 20L)
  expect_true(s$status %in% c("passed", "topology_change_needed"))
  expect_true(s$n_attractors >= s$n_desirable)
})
```

- [ ] **Step 2: Run to verify they fail.** Expected: `could not find function "ses_link_sensitivity"`.

- [ ] **Step 3: Implement** — after `ses_is_stable_attractor()` add (verified while planning on Tuscany, a permuted copy and these fixtures):

```r
#' Link ranking for mode C (spec 2026-10-15 §3.4): sensitivity of the dominant
#' eigenvalue of J = t(mat) (x_t = J x_{t-1}) to each existing link,
#' |d lambda / d mat[i, j]| = |w_j v_i / (w . v)|. Independent of node order,
#' unlike per-component participation ratio.
#' @return NULL when there is no single dominant mode (or eigen fails), else a
#'   data.frame(from, to, weight, sensitivity) sorted by sensitivity, descending
ses_link_sensitivity <- function(mat) {
  if (!is.matrix(mat) || nrow(mat) != ncol(mat) || !any(mat != 0)) return(NULL)
  er <- tryCatch(eigen(t(mat)), error = function(e) NULL)       # right eigenvectors of J
  el <- tryCatch(eigen(mat), error = function(e) NULL)          # t(J) == mat: left eigenvectors of J
  if (is.null(er) || is.null(el)) return(NULL)
  mods <- Mod(er$values)
  top <- max(mods)
  if (top < 1e-12) return(NULL)
  tol <- 1e-9 * max(1, top)
  cand <- which(abs(mods - top) <= tol)
  if (length(cand) > 2) return(NULL)
  if (length(cand) == 2 && Mod(er$values[cand[1]] - Conj(er$values[cand[2]])) > tol) return(NULL)
  k <- cand[which.max(Im(er$values[cand]))]
  lam <- er$values[k]
  v <- er$vectors[, k]
  w <- el$vectors[, which.min(Mod(el$values - lam))]           # not solve(V): fails on defective matrices
  wv <- sum(w * v)
  if (Mod(wv) < 1e-12) return(NULL)
  idx <- which(mat != 0, arr.ind = TRUE)
  out <- data.frame(from = rownames(mat)[idx[, 1]], to = colnames(mat)[idx[, 2]], weight = mat[idx],
                    sensitivity = Mod(w[idx[, 2]] * v[idx[, 1]] / wv), stringsAsFactors = FALSE)
  out <- out[order(-out$sensitivity, out$from, out$to), , drop = FALSE]
  rownames(out) <- NULL
  out
}
```

Replace the body of `ses_boolean_precheck()` so the attractor part is shared:

```r
#' Boolean attractors of one matrix: does any attractor keep every objective node ON?
#' @return list(status, n_nodes, n_attractors, n_desirable)
ses_boolean_attractor_summary <- function(M, objective_idx, max_nodes) {
  n <- nrow(M)
  out <- function(status, n_att = NA_integer_, n_des = NA_integer_) {
    list(status = status, n_nodes = n, n_attractors = n_att, n_desirable = n_des)
  }
  if (n > max_nodes) return(out("skipped"))
  bm <- tryCatch(boolean_model(M, max_nodes = max_nodes), error = function(e) NULL)
  if (is.null(bm)) return(out("unavailable"))
  if (isTRUE(bm$skipped) || is.null(bm$analysis)) return(out("skipped"))
  att <- bm$analysis$attractors
  desirable <- vapply(att, function(a) {
    if (is.null(a) || !is.data.frame(a) || nrow(a) == 0) return(FALSE)
    all(as.matrix(a[, objective_idx, drop = FALSE]) == 1)
  }, logical(1))
  out(if (any(desirable)) "passed" else "topology_change_needed", length(att), sum(desirable))
}

#' Boolean pre-check (spec section 4.6): every variable edge at the strongest level of
#' its allowed sign; does any attractor keep every objective node ON?
ses_boolean_precheck <- function(dm, objective_idx, max_nodes) {
  extreme <- vapply(dm$level_sets, function(s) if (max(s) > 0) max(s) else min(s), numeric(1))
  ses_boolean_attractor_summary(ses_apply_config(dm, extreme), objective_idx, max_nodes)
}
```

(The old early return on `n > max_nodes` happened before building the matrix; `ses_apply_config()` is cheap, so the order change is harmless.)

- [ ] **Step 4: Run tests** — reweight file, then `filter = '^intervention-designer'`. Expected: PASS (7a pre-check tests unchanged).

- [ ] **Step 5: Commit** — `feat(wp5): dominant-eigenvalue link sensitivity and shared attractor summary (WS-7b)`.

---

### Task 4: `scenario_network.R` and Scenario Builder `links_modified`

**Files:**
- Create: `functions/scenario_network.R`
- Modify: `modules/scenario_builder_module.R` (remove `scenario_loops()` ~line 1423-1451 and the inner `apply_scenario_modifications()` ~1222-1298; counts ~line 253; badges ~line 709-744; `validate_modifications()` ~1178; `predict_impacts()` ~1321), `global.R` (after line 618 `source("functions/network_analysis.R", local = TRUE)`), `tests/testthat/test-scenario-builder-module.R` (line 10), `tests/testthat/test-analysis-modules-batch.R` (where it sources the scenario builder module)
- Create: `tests/testthat/test-scenario-network.R`

**Interfaces:**
- Produces: `scenario_loops(network)` (moved verbatim). `scenario_apply_modifications(baseline_cld, modifications)` → `list(nodes, edges)`: removes nodes/links, adds nodes (DAPSI as `group`), adds links (with `strength`, default `"medium"`), applies `links_modified` by `from`/`to` node ids, fills missing columns with NA when binding.
- Produces (module-internal): `validate_modifications()` returns `list(valid, errors, warnings)`.

- [ ] **Step 1: Write failing tests** — create `tests/testthat/test-scenario-network.R`:

```r
# tests/testthat/test-scenario-network.R
source_for_test(c("functions/network_analysis.R", "functions/scenario_network.R"))

base_cld <- function() {
  list(nodes = data.frame(id = c("D_1", "A_1", "P_1"), label = c("Demand", "Boating", "Anchoring"),
                          group = c("Drivers", "Activities", "Pressures"), color = "#fff",
                          stringsAsFactors = FALSE),
       edges = data.frame(id = 1:2, from = c("D_1", "A_1"), to = c("A_1", "P_1"),
                          polarity = c("+", "+"), strength = c("medium", "weak"),
                          confidence = 3L, stringsAsFactors = FALSE))
}
mods <- function(...) {
  m <- list(nodes_added = list(), nodes_removed = c(), nodes_modified = list(),
            links_added = list(), links_removed = c(), links_modified = list())
  utils::modifyList(m, list(...))
}

test_that("links_modified changes polarity and strength of the link with the same endpoints", {
  out <- scenario_apply_modifications(base_cld(), mods(links_modified = list(
    list(from = "A_1", to = "P_1", polarity = "+", strength = "strong", previous_strength = "weak"))))
  e <- out$edges[out$edges$from == "A_1" & out$edges$to == "P_1", ]
  expect_equal(e$strength, "strong")
  expect_equal(nrow(out$edges), 2L)
})

test_that("links_modified ignores edge ids: renumbered ids still hit the right link (review focus 2)", {
  cld <- base_cld(); cld$edges$id <- c(2L, 1L)                  # the CLD editor renumbered rows
  out <- scenario_apply_modifications(cld, mods(links_modified = list(
    list(from = "D_1", to = "A_1", polarity = "+", strength = "strong", previous_strength = "medium"))))
  expect_equal(out$edges$strength[out$edges$from == "D_1"], "strong")
  expect_equal(out$edges$strength[out$edges$from == "A_1"], "weak")
})

test_that("a links_modified entry whose link is gone is skipped", {
  out <- scenario_apply_modifications(base_cld(), mods(links_modified = list(
    list(from = "P_1", to = "D_1", polarity = "-", strength = "strong", previous_strength = "weak"))))
  expect_equal(out$edges, base_cld()$edges)
})

test_that("added nodes and links bind to a baseline with more columns; strength defaults to medium", {
  out <- scenario_apply_modifications(base_cld(), mods(
    nodes_added = list(list(id = "scenario_node_1", label = "Moorings", dapsi = "Responses", description = "")),
    links_added = list(list(id = "scenario_link_1_1", from = "scenario_node_1", to = "P_1", polarity = "-",
                            strength = "strong"),
                       list(id = "scenario_link_1_2", from = "D_1", to = "P_1", polarity = "+"))))
  expect_equal(nrow(out$nodes), 4L)
  expect_equal(out$nodes$group[out$nodes$id == "scenario_node_1"], "Responses")
  expect_equal(out$edges$strength[out$edges$id == "scenario_link_1_1"], "strong")
  expect_equal(out$edges$strength[out$edges$id == "scenario_link_1_2"], "medium")
  expect_true(is.na(out$edges$confidence[out$edges$id == "scenario_link_1_2"]))
})

test_that("scenario_loops still works from its new home", {
  net <- list(nodes = data.frame(id = c("a", "b", "c", "d"), label = c("A", "B", "C", "D"), stringsAsFactors = FALSE),
              edges = data.frame(from = c("a", "b", "c", "c", "d"), to = c("b", "c", "a", "d", "a"),
                                 polarity = c("+", "+", "-", "+", "+"), stringsAsFactors = FALSE))
  expect_equal(scenario_loops(net)$count, 2L)
})
```

Append to `tests/testthat/test-scenario-builder-module.R` (re-bind pattern as in that file; `real_scenario_builder_server` already exists there):

```r
test_that("predict_impacts reports re-weighted links and survives removed links", {
  cld <- list(nodes = data.frame(id = c("D_1", "A_1", "P_1"), label = c("Demand", "Boating", "Anchoring"),
                                 group = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE),
              edges = data.frame(id = 1:2, from = c("D_1", "A_1"), to = c("A_1", "P_1"),
                                 polarity = "+", strength = c("medium", "weak"), stringsAsFactors = FALSE))
  sc <- list(id = "s1", name = "s", description = "", created = Sys.time(), modified = Sys.time(),
             modifications = list(nodes_added = list(), nodes_removed = c(), nodes_modified = list(),
                                  links_added = list(), links_removed = c("1"),
                                  links_modified = list(list(from = "A_1", to = "P_1", polarity = "+",
                                                             strength = "strong", previous_strength = "weak"))),
             results = NULL)
  data <- list(data = list(cld = cld, analysis = list(scenarios = list(sc))))
  testServer(real_scenario_builder_server,
             args = list(project_data_reactive = shiny::reactiveVal(data), i18n = list(t = function(k, ...) k)), {
    net <- scenario_apply_modifications(cld, sc$modifications)
    imp <- predict_impacts(cld, net, sc$modifications)
    expect_equal(imp$reason[imp$node == "Anchoring"], "modules.scenario.builder.scenario_link_strength_changed")
    expect_equal(imp$impact_magnitude[imp$node == "Anchoring"], 2)    # weak -> strong = two steps
    expect_equal(imp$impact_direction[imp$node == "Demand"], "negative")  # touched by the removed link 1
  })
})
```

(If `i18n$t` is called with `sprintf` placeholders, the echo stub returns the key; the assertions use keys. If the scenario builder test file names its re-bound server differently, use that name.)

- [ ] **Step 2: Run to verify they fail** — `filter = '^scenario-network$'` then `'^scenario-builder-module$'`. Expected: `cannot open file 'functions/scenario_network.R'` / `could not find function "scenario_apply_modifications"`.

- [ ] **Step 3: Implement** — create `functions/scenario_network.R`:

```r
# functions/scenario_network.R
# =============================================================================
# Pure scenario-network helpers shared by the Scenario Builder, the Designer
# (WS-7b Apply / Compare) and the designer's callr compare worker. No Shiny,
# no constants.R, no %||% (the worker has none of them).
# =============================================================================

# rbind two data frames, filling columns missing on either side with NA
.scenario_bind_rows <- function(a, b) {
  if (is.null(a) || !nrow(a)) return(b)
  if (is.null(b) || !nrow(b)) return(a)
  for (col in setdiff(names(a), names(b))) b[[col]] <- NA
  for (col in setdiff(names(b), names(a))) a[[col]] <- NA
  rbind(a, b[, names(a), drop = FALSE])
}

# Label of a node id (the id itself when unknown)
.scenario_label <- function(node_id, nodes) {
  hit <- nodes$label[nodes$id == node_id]
  if (length(hit)) hit[1] else node_id
}

#' Apply a scenario's modifications to a baseline CLD.
#' links_modified entries are matched by from/to node ids, never by edge id:
#' the CLD editor renumbers edge ids (spec 2026-10-15 §5.2).
#' @return list(nodes, edges)
scenario_apply_modifications <- function(baseline_cld, modifications) {
  nodes <- baseline_cld$nodes
  edges <- baseline_cld$edges
  if (length(modifications$nodes_removed) > 0) {
    nodes <- nodes[!nodes$id %in% modifications$nodes_removed, , drop = FALSE]
    edges <- edges[!edges$from %in% modifications$nodes_removed &
                   !edges$to %in% modifications$nodes_removed, , drop = FALSE]
  }
  if (length(modifications$nodes_added) > 0) {
    new_nodes <- do.call(rbind, lapply(modifications$nodes_added, function(n) {
      data.frame(id = n$id, label = n$label, group = n$dapsi, dapsi = n$dapsi,
                 description = if (is.null(n$description)) "" else n$description,
                 stringsAsFactors = FALSE)
    }))
    nodes <- .scenario_bind_rows(nodes, new_nodes)
  }
  if (length(modifications$links_removed) > 0 && "id" %in% names(edges)) {
    edges <- edges[!as.character(edges$id) %in% as.character(modifications$links_removed), , drop = FALSE]
  }
  for (l in modifications$links_modified) {
    hit <- edges$from == l$from & edges$to == l$to
    if (any(hit)) {
      edges$polarity[hit] <- l$polarity
      edges$strength[hit] <- l$strength
    }
  }
  if (length(modifications$links_added) > 0) {
    new_edges <- do.call(rbind, lapply(modifications$links_added, function(l) {
      data.frame(id = l$id, from = l$from, to = l$to,
                 from_label = .scenario_label(l$from, nodes), to_label = .scenario_label(l$to, nodes),
                 polarity = if (is.null(l$polarity)) "+" else l$polarity,
                 strength = if (is.null(l$strength)) "medium" else l$strength,
                 stringsAsFactors = FALSE)
    }))
    edges <- .scenario_bind_rows(edges, new_edges)
  }
  rownames(nodes) <- NULL
  rownames(edges) <- NULL
  list(nodes = nodes, edges = edges)
}
```

Then move `scenario_loops()` with its roxygen block verbatim from the end of `modules/scenario_builder_module.R` to the end of `functions/scenario_network.R`. In `global.R` add after line 618:

```r
source("functions/scenario_network.R", local = TRUE)   # WS-7b: scenario_loops + scenario_apply_modifications
```

In `modules/scenario_builder_module.R`:
- delete the inner `apply_scenario_modifications <- function(...) {...}` and replace its body with a one-line delegate (keeps the call sites):

```r
    apply_scenario_modifications <- function(baseline_cld, modifications) {
      scenario_apply_modifications(baseline_cld, modifications)
    }
```

- `validate_modifications()`: before `list(valid = ...)` add

```r
      warnings <- character()
      for (l in modifications$links_modified) {
        if (!any(baseline_cld$edges$from == l$from & baseline_cld$edges$to == l$to)) {
          warnings <- c(warnings, sprintf(i18n$t("modules.scenario.builder.link_modified_missing"),
                                          get_node_label_by_id(l$from, baseline_cld$nodes),
                                          get_node_label_by_id(l$to, baseline_cld$nodes)))
        }
      }
```

  and return `list(valid = length(errors) == 0, errors = errors, warnings = warnings)`. In the `run_impact_analysis` observer, after the `if (!validation$valid) {...}` block add:

```r
      if (length(validation$warnings)) {
        showNotification(paste(validation$warnings, collapse = "; "), type = "warning", duration = 8)
      }
```

- modification count (line ~253): add `+ length(scenario$modifications$links_modified)`.
- `output$added_links_list`: include `modified_links <- active_scenario$modifications$links_modified` in the empty check (`length(added_links) == 0 && length(removed_links) == 0 && length(modified_links) == 0`) and add a third block:

```r
        if (length(modified_links) > 0) {
          # i18n-ref: modules.scenario.builder.strength_weak
          # i18n-ref: modules.scenario.builder.strength_medium
          # i18n-ref: modules.scenario.builder.strength_strong
          st <- function(x) i18n$t(paste0("modules.scenario.builder.strength_", x))
          lapply(modified_links, function(link) {
            span(class = "modification-badge link-modified", icon("sliders-h"), " ",
                 get_node_label(link$from, data, active_scenario), " → ",
                 get_node_label(link$to, data, active_scenario), ": ",
                 st(link$previous_strength), " → ", st(link$strength))
          })
        }
```

- `predict_impacts()`: replace the `connected_links_removed` computation with a lookup of the removed ids in the baseline edges, and add the modified-links branch before the removed-links branch:

```r
        removed_ids <- as.character(modifications$links_removed)
        removed_edges <- baseline$edges[as.character(baseline$edges$id) %in% removed_ids, , drop = FALSE]
        connected_links_removed <- removed_edges$from == node_id | removed_edges$to == node_id
        modified <- Filter(function(l) l$from == node_id || l$to == node_id, modifications$links_modified)
```

```r
        } else if (length(modified)) {
          steps <- c(weak = 1, medium = 2, strong = 3)
          delta <- max(vapply(modified, function(l)
            abs(steps[[l$strength]] - steps[[l$previous_strength]]), numeric(1)))
          pol <- vapply(modified, function(l) l$polarity, character(1))
          impact_magnitude <- delta
          impact_direction <- if (all(pol == "+")) "positive" else if (all(pol == "-")) "negative" else "mixed"
          reason <- i18n$t("modules.scenario.builder.scenario_link_strength_changed")
```

  (`connected_links_removed` is now a logical vector; `any(connected_links_removed)` keeps working; the old `sapply(removed_links, function(l) l$from ...)` errored on the character ids.)
- In `tests/testthat/test-scenario-builder-module.R` line 10 and in `test-analysis-modules-batch.R` wherever the scenario builder module is sourced alone, source `functions/network_analysis.R` and `functions/scenario_network.R` before it.

The three new `modules.scenario.builder.*` keys used here (`link_modified_missing`, `scenario_link_strength_changed`, `strength_weak/medium/strong`) are added in Task 6; until then `i18n$t` returns the key, which is fine for tests.

- [ ] **Step 4: Run tests** — `'^scenario-network$'`, `'^scenario-builder-module$'`, `'^analysis-modules-batch$'`, `'^functions-sourced-in-app$'`. Expected: PASS (the source-chain test recognises the new `global.R` line).

- [ ] **Step 5: Commit** — `feat(wp5): scenario_network helpers, links_modified by endpoints, predict_impacts fixes (WS-7b)`.

---

### Task 5: configuration → scenario/network, compare structure, compare job

**Files:**
- Modify: `functions/intervention_designer.R` (append), `functions/intervention_designer_job.R`
- Create: `tests/testthat/test-intervention-designer-apply.R`
- Modify: `tests/testthat/test-intervention-designer-job.R` (append)

**Interfaces:**
- Consumes: Task 1 `ses_design_matrix()` (`base_levels`, kinds), Task 3 `ses_boolean_attractor_summary()`, Task 4 `scenario_apply_modifications()`, `scenario_loops()`.
- Produces:
  - `ses_matrix_node_ids(nodes)` → character vector of node ids named by matrix row name (cld_to_numeric_matrix rule).
  - `ses_config_to_scenario(dm, levels, cld, meta)`; `meta = list(name, description, intervention_type, ebm_code, now)` (`now` POSIXct) → scenario list (spec §5.1) with `ops`, `source = "intervention_designer"`. Stops with `"unknown node: <label>"` when a label has no id.
  - `ses_config_network(dm, levels, cld, now)` → `list(nodes, edges)`.
  - `.scenario_unique_name(name, existing)` → name, or `name (2)`, `name (3)` …
  - `ses_loop_key(nodes)`, `ses_loop_diff(base_loops, cfg_loops, cap = 500L)` → `list(gained, lost, changed, truncated)`.
  - `ses_compare_structure(payload)`; payload `list(baseline = list(nodes, edges), config = list(nodes, edges), base_matrix, config_matrix, objectives (labels), max_boolean_nodes)` → `list(loops = list(baseline, config), loop_diff, leverage = list(baseline, config), attractors = list(baseline, config))`.
  - `designer_engine_files(root = NULL, type = "run")`; `designer_job_start(payload, engine_files = designer_engine_files(type = type), type = "run")`; `designer_job_api()` gains `start_compare = function(payload) designer_job_start(payload, type = "compare")`.

- [ ] **Step 1: Write failing tests** — create `tests/testthat/test-intervention-designer-apply.R`:

```r
# tests/testthat/test-intervention-designer-apply.R
source_for_test(c("functions/network_analysis.R", "functions/scenario_network.R",
                  "functions/ses_dynamics.R", "functions/intervention_designer.R"))
LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)

cld <- function() {
  list(nodes = data.frame(id = c("D_1", "A_1", "P_1", "MPF_1"),
                          label = c("Demand", "Boating", "Anchoring", "Seagrass"),
                          group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
                          stringsAsFactors = FALSE),
       edges = data.frame(id = 1:3, from = c("D_1", "A_1", "P_1"), to = c("A_1", "P_1", "MPF_1"),
                          polarity = c("+", "+", "-"), strength = c("medium", "medium", "strong"),
                          stringsAsFactors = FALSE))
}
base_matrix <- function(c = cld()) {
  m <- cld_to_numeric_matrix(c$nodes, c$edges, use_labels = TRUE)
  dimnames(m) <- lapply(dimnames(m), unname)
  m
}
design <- function() {
  e <- data.frame(from = c("IV", "IV", "Seagrass", "Boating"),
                  to = c("Anchoring", "Seagrass", "Seagrass", "Anchoring"),
                  kind = c("intervention", "intervention", "context", "reweight"),
                  min_level = c(-1, 0, 0, -1), max_level = c(0, 1, 1, 1), stringsAsFactors = FALSE)
  ses_design_matrix(base_matrix(), list(new_node = "IV", edges = e), LV)
}
meta <- list(name = "IV - configuration #1", description = "d", intervention_type = "mpa_oecm",
             ebm_code = "3.1", now = as.POSIXct("2026-10-15 12:00:00", tz = "UTC"))

test_that("matrix names map to node ids positionally, duplicates made unique", {
  nodes <- data.frame(id = c("x1", "x2", "x3"), label = c("Same", "Same", ""), stringsAsFactors = FALSE)
  expect_equal(ses_matrix_node_ids(nodes), c(Same = "x1", Same_1 = "x2", x3 = "x3"))
})

test_that("configuration -> scenario follows the spec table", {
  # IV->Anchoring strong negative, IV->Seagrass 0 (skipped), self-loop weak, Boating->Anchoring strong (was medium)
  sc <- ses_config_to_scenario(design(), c(-1, 0, 0.25, 1), cld(), meta)
  m <- sc$modifications
  expect_equal(sc$source, "intervention_designer")
  expect_length(m$nodes_added, 1L)
  expect_equal(m$nodes_added[[1]]$label, "IV")
  expect_equal(m$nodes_added[[1]]$dapsi, "Responses")
  expect_length(m$links_added, 2L)                               # level-0 edge not written
  la <- m$links_added[[1]]
  expect_equal(c(la$from, la$to, la$polarity, la$strength), c(m$nodes_added[[1]]$id, "P_1", "-", "strong"))
  expect_equal(m$links_added[[2]][c("from", "to", "strength")], list(from = "MPF_1", to = "MPF_1", strength = "weak"))
  expect_false(identical(m$links_added[[1]]$id, m$links_added[[2]]$id))
  expect_length(m$links_modified, 1L)
  expect_equal(m$links_modified[[1]][c("from", "to", "strength", "previous_strength")],
               list(from = "A_1", to = "P_1", strength = "strong", previous_strength = "medium"))
  expect_equal(vapply(sc$ops, `[[`, "", "op"), c("new_node", "new_edge", "new_edge", "reweight_edge"))
  expect_true(is.na(sc$ops[[1]]$from))
  expect_equal(sc$ops[[4]][c("from", "to", "weight", "intervention_type", "ebm_code")],
               list(from = "Boating", to = "Anchoring", weight = 1, intervention_type = "mpa_oecm", ebm_code = "3.1"))
})

test_that("an unchanged re-weighted link writes nothing", {
  sc <- ses_config_to_scenario(design(), c(-1, 0, 0.25, 0.5), cld(), meta)
  expect_length(sc$modifications$links_modified, 0L)
  expect_false("reweight_edge" %in% vapply(sc$ops, `[[`, "", "op"))
})

test_that("unknown labels stop (Apply writes nothing)", {
  c2 <- cld(); c2$nodes$label[3] <- "Renamed"
  expect_error(ses_config_to_scenario(design(), c(-1, 0, 0.25, 1), c2, meta), "unknown node")
})

test_that("configured network rebuilds exactly the configuration matrix", {
  dm <- design(); lv <- c(-1, 0.5, 0.25, 1)
  net <- ses_config_network(dm, lv, cld(), meta$now)
  m <- cld_to_numeric_matrix(net$nodes, net$edges, use_labels = TRUE)
  dimnames(m) <- lapply(dimnames(m), unname)
  expected <- ses_apply_config(dm, lv)
  expect_equal(m[rownames(expected), colnames(expected)], expected)
})

test_that("scenario names are de-duplicated", {
  expect_equal(.scenario_unique_name("A", character(0)), "A")
  expect_equal(.scenario_unique_name("A", c("A", "A (2)")), "A (3)")
})

test_that("loop diff: rotation-independent keys, gained/lost/changed, truncation (review focus 5)", {
  expect_equal(ses_loop_key(c("C", "A", "B")), ses_loop_key(c("A", "B", "C")))
  b <- list(list(type = "Reinforcing", nodes = c("A", "B", "C")), list(type = "Balancing", nodes = c("B", "D")))
  cf <- list(list(type = "Balancing", nodes = c("C", "A", "B")), list(type = "Reinforcing", nodes = c("E", "F")))
  d <- ses_loop_diff(b, cf)
  expect_equal(d$gained, list(c("E", "F")))
  expect_equal(d$lost, list(c("B", "D")))
  expect_equal(d$changed, list(c("A", "B", "C")))
  expect_false(d$truncated)
  many <- replicate(500, list(type = "Reinforcing", nodes = c("A", "B")), simplify = FALSE)
  expect_true(ses_loop_diff(many, list())$truncated)
})

test_that("compare structure returns loops, leverage and attractors for both sides", {
  dm <- design(); lv <- c(-1, 0.5, 0.25, 1)
  p <- list(baseline = cld(), config = ses_config_network(dm, lv, cld(), meta$now),
            base_matrix = base_matrix(), config_matrix = ses_apply_config(dm, lv),
            objectives = "Seagrass", max_boolean_nodes = 20L)
  out <- ses_compare_structure(p)
  expect_named(out, c("loops", "loop_diff", "leverage", "attractors"))
  expect_true(is.data.frame(out$leverage$baseline))
  expect_true(out$attractors$config$status %in% c("passed", "topology_change_needed", "skipped", "unavailable"))
})
```

Append to `tests/testthat/test-intervention-designer-job.R`:

```r
test_that("compare job runs in a real background process and finds loops", {
  nodes <- data.frame(id = c("a", "b", "c", "d"), label = c("A", "B", "C", "D"), group = "Activities",
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = c("a", "b", "c", "c", "d"), to = c("b", "c", "a", "d", "a"),
                      polarity = c("+", "+", "-", "+", "+"), strength = "medium", stringsAsFactors = FALSE)
  m <- matrix(0, 4, 4, dimnames = rep(list(c("A", "B", "C", "D")), 2))
  p <- list(baseline = list(nodes = nodes, edges = edges), config = list(nodes = nodes, edges = edges),
            base_matrix = m, config_matrix = m, objectives = "A", max_boolean_nodes = 20L)
  job <- designer_job_start(p, engine_files = designer_engine_files(app_root(), type = "compare"), type = "compare")
  st <- wait_for(job)
  expect_equal(st$state, "done")
  # a non-zero count proves the worker's debug_log stub is visible to sourced files
  expect_equal(length(st$result$loops$baseline$loops), 2L)
})
```

- [ ] **Step 2: Run to verify they fail** — `'^intervention-designer-apply$'`, `'^intervention-designer-job$'`. Expected: missing functions / unused argument `type`.

- [ ] **Step 3: Implement** — append to `functions/intervention_designer.R`:

```r
# ── WS-7b: configuration -> scenario / network, compare (spec 2026-10-15 §3.5, §4.4, §5) ──

#' Node ids named by matrix row name, using cld_to_numeric_matrix()'s naming
#' rule (label, else id; make.unique on duplicates). Positional, never match().
ses_matrix_node_ids <- function(nodes) {
  nm <- ifelse(is.na(nodes$label) | nodes$label == "", nodes$id, nodes$label)
  if (anyDuplicated(nm)) nm <- make.unique(nm, sep = "_")
  stats::setNames(as.character(nodes$id), nm)
}

.ses_strength_name <- function(w) {
  c("0.25" = "weak", "0.5" = "medium", "1" = "strong")[[as.character(abs(w))]]
}

#' The scenario Apply writes for one configuration (spec §5.1).
#' @param meta list(name, description, intervention_type, ebm_code, now)
ses_config_to_scenario <- function(dm, levels, cld, meta) {
  ids <- ses_matrix_node_ids(cld$nodes)
  ms <- format(round(as.numeric(meta$now) * 1000), scientific = FALSE)
  node_id <- if (!is.null(dm$new_node)) paste0("scenario_node_", ms) else NULL
  id_of <- function(label) {
    if (!is.null(dm$new_node) && identical(label, dm$new_node)) return(node_id)
    if (!label %in% names(ids)) stop(sprintf("unknown node: %s", label))
    ids[[label]]
  }
  na_chr <- function(x) if (is.null(x) || !length(x) || is.na(x[1]) || !nzchar(x[1])) NA_character_ else as.character(x[1])
  op_rec <- function(op, from, to, weight) list(op = op, from = from, to = to, weight = weight,
                                                intervention_type = na_chr(meta$intervention_type),
                                                ebm_code = na_chr(meta$ebm_code))
  nodes_added <- list(); links_added <- list(); links_modified <- list(); ops <- list()
  if (!is.null(dm$new_node)) {
    nodes_added <- list(list(id = node_id, label = dm$new_node, dapsi = "Responses", description = ""))
    ops <- list(op_rec("new_node", NA_character_, dm$new_node, NA_real_))
  }
  e <- dm$edges
  for (k in seq_len(nrow(e))) {
    lv <- levels[k]
    from <- id_of(e$from[k]); to <- id_of(e$to[k])
    if (e$kind[k] == "reweight") {
      if (lv == dm$base_levels[k]) next
      links_modified[[length(links_modified) + 1L]] <- list(
        from = from, to = to, polarity = if (lv > 0) "+" else "-", strength = .ses_strength_name(lv),
        previous_strength = .ses_strength_name(dm$base_levels[k]))
      ops[[length(ops) + 1L]] <- op_rec("reweight_edge", e$from[k], e$to[k], lv)
    } else if (lv != 0) {
      links_added[[length(links_added) + 1L]] <- list(
        id = paste0("scenario_link_", ms, "_", k), from = from, to = to,
        polarity = if (lv > 0) "+" else "-", strength = .ses_strength_name(lv))
      ops[[length(ops) + 1L]] <- op_rec("new_edge", e$from[k], e$to[k], lv)
    }
  }
  list(id = paste0("scenario_", ms), name = meta$name, description = meta$description,
       created = meta$now, modified = meta$now,
       modifications = list(nodes_added = nodes_added, nodes_removed = c(), nodes_modified = list(),
                            links_added = links_added, links_removed = c(), links_modified = links_modified),
       results = NULL, ops = ops, source = "intervention_designer")
}

#' CLD-shaped network of one configuration: exactly what Apply would write.
ses_config_network <- function(dm, levels, cld, now) {
  sc <- ses_config_to_scenario(dm, levels, cld, list(name = "", description = "", now = now))
  scenario_apply_modifications(cld, sc$modifications)
}

#' "name", or "name (2)", "name (3)" ... when taken.
.scenario_unique_name <- function(name, existing) {
  if (!name %in% existing) return(name)
  k <- 2L
  while (sprintf("%s (%d)", name, k) %in% existing) k <- k + 1L
  sprintf("%s (%d)", name, k)
}

#' Loop key: node sequence rotated to start at its alphabetically first node.
ses_loop_key <- function(nodes) {
  i <- which.min(rank(nodes, ties.method = "first"))
  paste(c(nodes[i:length(nodes)], nodes[seq_len(i - 1)]), collapse = "\r")
}

#' Loops gained, lost and changed in type between two scenario_loops() lists.
ses_loop_diff <- function(base_loops, cfg_loops, cap = 500L) {
  kb <- vapply(base_loops, function(l) ses_loop_key(l$nodes), "")
  kc <- vapply(cfg_loops, function(l) ses_loop_key(l$nodes), "")
  tb <- vapply(base_loops, function(l) l$type, ""); tc <- vapply(cfg_loops, function(l) l$type, "")
  both <- intersect(kb, kc)
  changed <- both[tb[match(both, kb)] != tc[match(both, kc)]]
  nodes_of <- function(keys) lapply(keys, function(k) strsplit(k, "\r", fixed = TRUE)[[1]])
  list(gained = nodes_of(setdiff(kc, kb)), lost = nodes_of(setdiff(kb, kc)), changed = nodes_of(changed),
       truncated = length(base_loops) >= cap || length(cfg_loops) >= cap)
}

#' Before/after structure (spec §4.3 item 2); runs in the compare worker.
ses_compare_structure <- function(payload) {
  side <- function(net, M) {
    obj <- match(payload$objectives, rownames(M))
    list(loops = scenario_loops(net),
         leverage = identify_leverage_points(net$nodes, net$edges, top_n = 10),
         attractors = tryCatch(ses_boolean_attractor_summary(M, obj[!is.na(obj)], payload$max_boolean_nodes),
                               error = function(e) list(status = "unavailable")))
  }
  b <- side(payload$baseline, payload$base_matrix)
  cf <- side(payload$config, payload$config_matrix)
  list(loops = list(baseline = b$loops, config = cf$loops),
       loop_diff = ses_loop_diff(b$loops$loops, cf$loops$loops),
       leverage = list(baseline = b$leverage, config = cf$leverage),
       attractors = list(baseline = b$attractors, config = cf$attractors))
}
```

In `functions/intervention_designer_job.R`:

```r
#' Absolute paths of the engine files the worker sources.
designer_engine_files <- function(root = NULL, type = "run") {
  if (is.null(root)) {
    root <- if (exists("PROJECT_ROOT", inherits = TRUE)) get("PROJECT_ROOT", inherits = TRUE) else getwd()
  }
  files <- if (identical(type, "compare")) {
    c("ses_dynamics.R", "network_analysis.R", "scenario_network.R", "intervention_designer.R")
  } else {
    c("ses_dynamics.R", "intervention_designer.R")
  }
  normalizePath(file.path(root, "functions", files), winslash = "/", mustWork = TRUE)
}
```

Change the `designer_job_start()` signature to `designer_job_start(payload, engine_files = designer_engine_files(type = type), type = "run")`, pass `type = type` in `args`, and make the worker function:

```r
    function(payload, engine_files, progress_file, type) {
      suppressMessages(library(Matrix))
      if (identical(type, "compare")) {
        suppressMessages({ library(igraph); library(dplyr) })
        # Global, not local: files sourced with local = FALSE look debug_log up in
        # globalenv; a missing one makes scenario_loops() silently return 0 loops.
        assign("debug_log", function(...) invisible(NULL), envir = globalenv())
      }
      for (f in engine_files) source(f, local = FALSE)
      if (identical(type, "compare")) return(ses_compare_structure(payload))
      pc_state <- ""
      ...  # the existing progress function and ses_run_design() call, unchanged
    },
    args = list(payload = payload, engine_files = engine_files, progress_file = progress_file, type = type),
```

Return `type` in the job list: `list(process = proc, progress_file = progress_file, started = Sys.time(), type = type)`. In `designer_job_api()` add `start_compare = function(payload) designer_job_start(payload, type = "compare"),`.

- [ ] **Step 4: Run tests** — `'^intervention-designer-apply$'`, `'^intervention-designer-job$'`, `'^intervention-designer'`. Expected: PASS.

- [ ] **Step 5: Commit** — `feat(wp5): configuration to scenario, structure compare and compare job (WS-7b)`.

---

### Task 6: translations

**Files:**
- Modify: `translations/modules/intervention_designer.json`, `translations/modules/scenario_builder.json`

**Interfaces:**
- Produces the keys below, each with all 9 languages (en, es, fr, de, lt, pt, it, no, el). English text is fixed (use verbatim); write the other 8 in the style and terminology of the existing entries in the same file (e.g. reuse the file's existing words for "link", "scenario", "strong/medium/weak").

`modules.intervention_designer.*`:

| key | en |
|---|---|
| `reweight_heading` | Re-weight existing links (mode C) |
| `reweight_help` | Links are ranked by how strongly they drive the system's long-run behaviour. A re-weighted link keeps its sign; its strength varies over weak, medium and strong. |
| `reweight_links` | Links, most influential first |
| `add_reweight` | Add ticked links |
| `reweight_node` | All links of a node |
| `add_node_links` | Add the node's links |
| `ranking_unavailable` | Link ranking unavailable for this network; links are listed unranked. |
| `kind.reweight` | Re-weight |
| `reweight_stale` | A re-weighted link was removed or changed sign in the CLD. Remove it from the design and add it again. |
| `reweight_fixed_sign` | Re-weighted links keep their sign. |
| `need_link` | Tick at least one link first. |
| `dependence_heading` | What success depends on |
| `dependence_needs` | Success needs |
| `dependence_at` | at |
| `dependence_any` | any strength works |
| `dependence_few` | Too few successes to call a link decisive. |
| `dependence_estimated` | Estimated from the sample. |
| `col_link` | Link |
| `col_shares` | Share of successes per level |
| `compare_structure` | Compare structure |
| `compare_heading` | Before / after |
| `compare_running` | Comparing structure… |
| `loops_heading` | Feedback loops |
| `loops_reinforcing` | Reinforcing |
| `loops_balancing` | Balancing |
| `col_before` | Before |
| `col_after` | After |
| `loops_gained` | Loops gained |
| `loops_lost` | Loops lost |
| `loops_changed` | Loops that changed type |
| `loops_truncated` | Loop lists are cut at 500 loops. |
| `none` | None |
| `leverage_heading` | Leverage points (top 10) |
| `leverage_new` | new |
| `attractors_heading` | Boolean attractors |
| `attractors_total` | Attractors |
| `attractors_desirable` | Desirable attractors |
| `attractors_skipped` | Skipped (more than 20 nodes or BoolNet not available). |
| `apply` | Apply to project |
| `apply_title` | Save this configuration as a scenario |
| `apply_name` | Scenario name |
| `apply_description` | Description |
| `apply_confirm` | Save scenario |
| `apply_summary` | Intervention designer run |
| `configuration` | configuration |
| `applied` | Scenario saved. Open it in the Scenario Builder. |
| `apply_stale` | The network changed since this run. Run the design again before applying. |
| `need_row` | Select a configuration in the table first. |
| `context_apply` | Saving the scenario |
| `context_compare` | Comparing structure |

`modules.scenario.builder.*`:

| key | en |
|---|---|
| `link_modified_missing` | Modified link no longer exists: %s → %s |
| `scenario_link_strength_changed` | Link strength changed |
| `strength_weak` | weak |
| `strength_medium` | medium |
| `strength_strong` | strong |

- [ ] **Step 1: Add the keys** to the two JSON files (keep 2-space indentation and the existing key order style; append at the end of `"translation"`). Validate both files parse: `micromamba run -n shiny python -c "import json,sys; [json.load(open(f, encoding='utf-8')) for f in sys.argv[1:]]" translations/modules/intervention_designer.json translations/modules/scenario_builder.json`.

- [ ] **Step 2: Run** `micromamba run -n shiny python scripts/_i18n_audit.py` — Expected: `missing=0`, `hardcoded=0` (the Task 4 module code now resolves). Run `filter = '^intervention-designer-i18n$'` and `'^i18n-enforcement$'` — Expected: PASS (the designer i18n test checks every key used by the module has 9 languages).

- [ ] **Step 3: Commit** — `i18n(wp5): WS-7b designer and scenario builder keys (9 languages)`.

---

### Task 7: Designer module — mode C panel and run gating

**Files:**
- Modify: `modules/intervention_designer_module.R`
- Test: `tests/testthat/test-intervention-designer-module.R` (append)

**Interfaces:**
- Consumes: Task 1 kinds/level sets, Task 3 `ses_link_sensitivity()`, Task 6 keys.
- Produces: inputs `rw_links` (checkbox group, values `"<from>\r<to>"`), `add_reweight`, `rw_node`, `add_node_links`; `rv$edges` rows with `kind = "reweight"`, `min_level`/`max_level` = smallest / largest of `sign(w) × {0.25, 0.5, 1}`; run-block key `modules.intervention_designer.reweight_stale`.

- [ ] **Step 1: Append failing tests**

```r
test_that("mode C: ticked links become sign-fixed reweight rows", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "", type = "", rw_links = c("Boating\rAnchoring", "Anchoring\rP. oceanica extension"))
    session$setInputs(add_reweight = 1)
    expect_equal(rv$edges$kind, c("reweight", "reweight"))
    expect_equal(rv$edges$min_level, c(0.25, -1))
    expect_equal(rv$edges$max_level, c(1, -0.25))
    session$setInputs(rw_node = "Demand", add_node_links = 1)
    expect_equal(nrow(rv$edges), 3L)                            # Demand -> Boating added once
    session$setInputs(objectives = "P. oceanica extension", sustain = NULL)
    expect_null(run_block_reason())
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_equal(rv$result$n_eval, 27)
  })
})

test_that("mode C: a link that changed sign or vanished blocks Run (review focus 1)", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(name = "", type = "", rw_links = "Boating\rAnchoring", objectives = "Habitat")
    session$setInputs(add_reweight = 1)
    expect_null(run_block_reason())
    p <- proj(); p$data$cld$edges$polarity[2] <- "-"; pd(p)    # Boating -> Anchoring flipped
    session$flushReact()
    expect_equal(run_block_reason(), "modules.intervention_designer.reweight_stale")
    p$data$cld$edges <- p$data$cld$edges[-2, ]; pd(p)          # and now deleted
    session$flushReact()
    expect_equal(run_block_reason(), "modules.intervention_designer.reweight_stale")
  })
})

test_that("mode C: ranking falls back to an unranked list (review focus 4)", {
  p <- proj()
  p$data$cld$edges <- data.frame(from = c("D_1", "A_1"), to = c("A_1", "D_1"), polarity = "+",
                                 strength = "strong", stringsAsFactors = FALSE)   # eigenvalues 1 and -1
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo, job_api = fake_api()), {
    expect_null(link_rank()$ranked)
    expect_equal(nrow(link_rank()$links), 2L)
    expect_match(as.character(output$reweight_ui$html), "modules.intervention_designer.ranking_unavailable")
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^intervention-designer-module$'`. Expected: FAIL (`rv$edges` empty, `link_rank` not found).

- [ ] **Step 3: Implement** in `modules/intervention_designer_module.R`:

1. After `net <- reactive({...})` add the ranking reactive (all existing links, ranked when possible):

```r
    # Mode C link list (spec 2026-10-15 §3.4, §4.1): ranked by dominant-eigenvalue
    # sensitivity; when no single dominant mode exists, listed unranked.
    link_rank <- reactive({
      m <- net()$matrix
      ranked <- tryCatch(ses_link_sensitivity(m), error = function(e) NULL)
      links <- if (!is.null(ranked)) ranked else {
        idx <- which(m != 0, arr.ind = TRUE)
        data.frame(from = rownames(m)[idx[, 1]], to = colnames(m)[idx[, 2]], weight = m[idx],
                   sensitivity = NA_real_, stringsAsFactors = FALSE)
      }
      list(ranked = ranked, links = links)
    })
```

2. In `output$design_ui`, inside the "Edges" card, after the self-loop `tagList(...)` and before the `hr()` that precedes `tableOutput(ns("edges_table"))`, insert `hr(), uiOutput(ns("reweight_ui")),`. Add the output:

```r
    output$reweight_ui <- renderUI({
      lr <- link_rank(); l <- lr$links
      if (!nrow(l)) return(NULL)
      top <- if (is.null(lr$ranked)) 1 else max(l$sensitivity, 1e-12)
      names_ui <- lapply(seq_len(nrow(l)), function(i) {
        bar <- if (is.na(l$sensitivity[i])) NULL else
          span(style = sprintf("display:inline-block;height:6px;width:%dpx;background:#3c8dbc;margin-left:6px;",
                               round(60 * l$sensitivity[i] / top)))
        tagList(paste0(l$from[i], " → ", l$to[i], " (", lvl_label(l$weight[i]), ")"), bar)
      })
      tagList(
        h6(i18n$t("modules.intervention_designer.reweight_heading")),
        p(class = "small text-muted", i18n$t("modules.intervention_designer.reweight_help")),
        if (is.null(lr$ranked)) div(class = "alert alert-secondary py-1 small",
                                    i18n$t("modules.intervention_designer.ranking_unavailable")),
        div(style = "max-height: 220px; overflow-y: auto;",
            checkboxGroupInput(ns("rw_links"), i18n$t("modules.intervention_designer.reweight_links"),
                               choiceNames = names_ui, choiceValues = paste(l$from, l$to, sep = "\r"),
                               selected = isolate(input$rw_links))),
        actionButton(ns("add_reweight"), i18n$t("modules.intervention_designer.add_reweight"), icon = icon("plus")),
        fluidRow(column(8, selectInput(ns("rw_node"), i18n$t("modules.intervention_designer.reweight_node"),
                                       net()$labels)),
                 column(4, actionButton(ns("add_node_links"), i18n$t("modules.intervention_designer.add_node_links"),
                                        class = "mt-4")))
      )
    })
```

3. Add the observers (after `observeEvent(input$add_self_loop, ...)`):

```r
    # Mode C rows: the link's own sign, weak..strong (spec §3.1)
    add_reweight_rows <- function(from, to) {
      m <- net()$matrix
      ok <- from %in% rownames(m) & to %in% colnames(m)
      from <- from[ok]; to <- to[ok]
      w <- m[cbind(from, to)]
      from <- from[w != 0]; to <- to[w != 0]; w <- w[w != 0]
      if (!length(w)) return(invisible(FALSE))
      s <- sign(w)
      add_rows(data.frame(from = from, to = to, kind = "reweight",
                          min_level = pmin(s * 0.25, s * 1), max_level = pmax(s * 0.25, s * 1),
                          stringsAsFactors = FALSE))
      invisible(TRUE)
    }
    observeEvent(input$add_reweight, {
      keys <- input$rw_links %||% character(0)
      if (!length(keys)) {
        showNotification(i18n$t("modules.intervention_designer.need_link"), type = "warning")
        return()
      }
      parts <- strsplit(keys, "\r", fixed = TRUE)
      add_reweight_rows(vapply(parts, `[`, "", 1), vapply(parts, `[`, "", 2))
    })
    observeEvent(input$add_node_links, {
      req(input$rw_node)
      l <- link_rank()$links
      hit <- l$from == input$rw_node | l$to == input$rw_node
      add_reweight_rows(l$from[hit], l$to[hit])
    })
```

4. Edge editor: in `output$edge_editor_ui`, compute choices per row kind:

```r
      ch <- level_choices()
      if (identical(e$kind[i], "reweight")) {
        s <- sign(e$max_level[i])
        ch <- ch[as.numeric(ch) %in% (s * c(0.25, 0.5, 1))]
      }
```

  and use `ch` in both `selectInput(ns("min_level"), ...)` and `selectInput(ns("max_level"), ...)`. In the `sign_nonpos` and `sign_nonneg` observers, after `i <- req_edit_row()`, add:

```r
      if (identical(rv$edges$kind[i], "reweight")) {
        showNotification(i18n$t("modules.intervention_designer.reweight_fixed_sign"), type = "message")
        return()
      }
```

  In `observeEvent(input$edit_edge, ...)`, before updating min/max, refresh the choices for reweight rows the same way (`updateSelectInput(session, "min_level", choices = ch, selected = ...)`; same for max).

5. `edges_table`: add `# i18n-ref: modules.intervention_designer.kind.reweight` next to the existing kind sentinels.

6. `ops_ui` `used`: add `if (any(rv$edges$kind == "reweight")) "reweight_edge"`.

7. `run_block_reason()`: replace the `ctx <- ...` block with

```r
      ctx <- e[e$from != .DESIGNER_NEW & e$to != .DESIGNER_NEW & e$kind != "reweight", , drop = FALSE]
      if (nrow(ctx) && any(net()$matrix[cbind(ctx$from, ctx$to)] != 0)) {
        return("modules.intervention_designer.edge_exists")
      }
      rw_rows <- e[e$kind == "reweight", , drop = FALSE]
      if (nrow(rw_rows)) {
        w <- net()$matrix[cbind(rw_rows$from, rw_rows$to)]
        if (any(w == 0 | sign(w) != sign(rw_rows$max_level))) return("modules.intervention_designer.reweight_stale")
      }
```

  and add `# i18n-ref: modules.intervention_designer.reweight_stale` to the sentinel list above it.

8. `.designer_payload()`: add `dependence_min_success = INTERVENTION_DEPENDENCE_MIN_SUCCESS,`.

Note: `stale_edges` (ends not in labels) is checked before `reweight_stale`, so a deleted *node* still reports `stale_edges`; a deleted *link* between existing nodes reports `reweight_stale`.

- [ ] **Step 4: Run tests** — `'^intervention-designer-module$'`, `'^intervention-designer'`, `'^analysis-intervention'`. Expected: PASS. Run the i18n audit: `missing=0 hardcoded=0`.

- [ ] **Step 5: Commit** — `feat(wp5): Designer mode C panel and re-weight gating (WS-7b)`.

---

### Task 8: Designer module — dependence table, Compare, Apply

**Files:**
- Modify: `modules/intervention_designer_module.R`
- Test: `tests/testthat/test-intervention-designer-module.R` (append; extend `fake_api()`)

**Interfaces:**
- Consumes: Task 2 `result$dependence`, Task 5 `ses_config_to_scenario()`, `ses_config_network()`, `.scenario_unique_name()`, `job_api$start_compare`, Task 6 keys.
- Produces: `rv$cmp_job`, `rv$compare`, `rv$stale`; inputs `compare`, `apply`, `apply_name`, `apply_description`, `confirm_apply`; scenarios appended to `project_data$data$analysis$scenarios`.

- [ ] **Step 1: Append failing tests** — first replace `fake_api()` at the top of the test file with:

```r
fake_api <- function(fail = FALSE) {
  list(start = function(payload) list(payload = payload, type = "run"),
       start_compare = function(payload) list(payload = payload, type = "compare"),
       poll = function(job) {
         if (fail) return(list(state = "error", reason = "engine", message = "boom"))
         if (identical(job$type, "compare")) return(list(state = "done", result = ses_compare_structure(job$payload)))
         list(state = "done", result = ses_run_design(job$payload))
       },
       cancel = function(job) invisible(TRUE))
}
```

and add `"functions/network_analysis.R", "functions/scenario_network.R"` to the `source_for_test()` call at the top. Then append:

```r
run_mode_c <- function(session) {
  session$setInputs(name = "", type = "", rw_links = c("Boating\rAnchoring", "Anchoring\rP. oceanica extension"),
                    objectives = "Habitat", sustain = NULL)
  session$setInputs(add_reweight = 1)
  session$setInputs(run = 1)
  session$elapse(1100)
}

test_that("dependence table is built from the result", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    expect_false(is.null(rv$result$dependence) && rv$result$n_a > 0)
    expect_error(output$dependence_ui, NA)
  })
})

test_that("Compare runs as its own job and fills rv$compare", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    session$setInputs(top_table_rows_selected = 1)
    session$setInputs(compare = 1)
    session$elapse(1100)
    expect_null(rv$cmp_job)
    expect_named(rv$compare, c("loops", "loop_diff", "leverage", "attractors"))
    expect_error(output$compare_ui, NA)
  })
})

test_that("Apply writes one designer scenario into the project", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    session$setInputs(top_table_rows_selected = 1)
    session$setInputs(apply = 1)
    session$setInputs(apply_name = "My scenario", apply_description = "x", confirm_apply = 1)
    sc <- pd()$data$analysis$scenarios
    expect_length(sc, 1L)
    expect_equal(sc[[1]]$source, "intervention_designer")
    expect_equal(sc[[1]]$name, "My scenario")
    session$setInputs(confirm_apply = 2)                        # same name again
    expect_equal(pd()$data$analysis$scenarios[[2]]$name, "My scenario (2)")
  })
})

test_that("Apply is refused after the network changed", {
  pd <- shiny::reactiveVal(proj())
  eb <- list(on_isa_change = function() pd())                   # minimal bus: fires on project change
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api(), event_bus = eb), {
    run_mode_c(session)
    p <- proj(); p$data$cld$edges$strength[1] <- "strong"; pd(p)
    session$flushReact()
    expect_true(rv$stale)
    session$setInputs(top_table_rows_selected = 1, apply = 1, apply_name = "S", apply_description = "", confirm_apply = 1)
    expect_length(pd()$data$analysis$scenarios, 0L)
  })
})
```

- [ ] **Step 2: Run to verify they fail** — `'^intervention-designer-module$'`.

- [ ] **Step 3: Implement**:

1. `rv <- reactiveValues(...)`: add `cmp_job = NULL, compare = NULL, stale = FALSE`.

2. Stale observer: inside `if (isolate(rv$analysis_complete)) {`, add `rv$stale <- TRUE`. In the poll observer's `done` branch add `rv$stale <- FALSE; rv$compare <- NULL`.

3. `run_block_reason()`: change the first line to `if (!is.null(rv$job) || !is.null(rv$cmp_job)) return("modules.intervention_designer.job_running")`.

4. Selected row helper:

```r
    selected_levels <- reactive({
      r <- rv$result; i <- input$top_table_rows_selected
      req(r, length(i) == 1)
      r$top_levels[, i]
    })
    cld_now <- reactive(project_data_reactive()$data$cld)
```

5. Results UI: in `output$results_ui`, after the top-20 card add:

```r
        uiOutput(ns("dependence_ui")),
        bs4Card(title = i18n$t("modules.intervention_designer.compare_heading"), width = 12, collapsible = FALSE,
          actionButton(ns("compare"), i18n$t("modules.intervention_designer.compare_structure"), icon = icon("project-diagram")),
          actionButton(ns("apply"), i18n$t("modules.intervention_designer.apply"), icon = icon("save"),
                       class = "btn-primary ml-2"),
          uiOutput(ns("compare_ui")))
```

6. Dependence output:

```r
    output$dependence_ui <- renderUI({
      dep <- rv$result$dependence
      if (is.null(dep)) return(NULL)
      pct <- function(x) sprintf("%.0f%%", 100 * x)
      rows <- lapply(seq_len(nrow(dep)), function(k) {
        shares <- paste(paste(lvl_label(dep$levels[[k]]), pct(dep$shares[[k]])), collapse = " · ")
        verdict <- if (isTRUE(dep$decisive[k])) {
          strong(i18n$t("modules.intervention_designer.dependence_needs"), " ",
                 dep$from[k], " → ", dep$to[k], " ", i18n$t("modules.intervention_designer.dependence_at"), " ",
                 paste(lvl_label(dep$needed_levels[[k]]), collapse = ", "))
        } else if (isFALSE(dep$decisive[k])) {
          span(class = "text-muted", i18n$t("modules.intervention_designer.dependence_any"))
        }
        tags$tr(tags$td(paste(dep$from[k], "→", dep$to[k])), tags$td(class = "small", shares), tags$td(verdict))
      })
      bs4Card(title = i18n$t("modules.intervention_designer.dependence_heading"), width = 12, collapsible = FALSE,
        if (anyNA(dep$decisive)) p(class = "text-warning small", i18n$t("modules.intervention_designer.dependence_few")),
        if (isTRUE(rv$result$sampled)) p(class = "text-muted small", i18n$t("modules.intervention_designer.dependence_estimated")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(i18n$t("modules.intervention_designer.col_link")),
                             tags$th(i18n$t("modules.intervention_designer.col_shares")), tags$th(""))),
          tags$tbody(rows)))
    })
```

7. Compare start / poll:

```r
    observeEvent(input$compare, {
      if (!length(input$top_table_rows_selected)) {
        showNotification(i18n$t("modules.intervention_designer.need_row"), type = "warning"); return()
      }
      if (!is.null(rv$job) || !is.null(rv$cmp_job)) return()
      r <- rv$result; lv <- selected_levels()
      payload <- tryCatch(list(
        baseline = cld_now(), config = ses_config_network(r$design_matrix, lv, cld_now(), Sys.time()),
        base_matrix = r$base, config_matrix = ses_apply_config(r$design_matrix, lv),
        objectives = r$objectives, max_boolean_nodes = DYNAMICS_MAX_BOOLEAN_NODES), error = function(e) e)
      if (inherits(payload, "error")) {
        showNotification(format_user_error(payload, i18n = i18n, context_key = "modules.intervention_designer.context_compare"),
                         type = "error"); return()
      }
      rv$compare <- NULL
      rv$cmp_job <- tryCatch(job_api$start_compare(payload), error = function(e) {
        showNotification(format_user_error(e, i18n = i18n, context_key = "modules.intervention_designer.context_compare"),
                         type = "error"); NULL })
    })
    observe({
      job <- rv$cmp_job
      req(job)
      invalidateLater(1000)
      st <- tryCatch(job_api$poll(job), error = function(e) list(state = "error", message = conditionMessage(e)))
      if (identical(st$state, "running")) return()
      rv$cmp_job <- NULL
      if (identical(st$state, "done")) rv$compare <- st$result
      else showNotification(format_user_error(simpleError(st$message %||% ""), i18n = i18n,
                                              context_key = "modules.intervention_designer.context_compare"), type = "error")
    })
```

  and in `session$onSessionEnded` also cancel `rv$cmp_job`.

8. Compare panel:

```r
    output$compare_ui <- renderUI({
      if (!is.null(rv$cmp_job)) return(p(class = "text-muted mt-2", i18n$t("modules.intervention_designer.compare_running")))
      cmp <- rv$compare
      if (is.null(cmp)) return(NULL)
      cnt <- function(l, type) sum(vapply(l$loops, function(x) identical(x$type, type), logical(1)))
      loop_list <- function(x) if (!length(x)) i18n$t("modules.intervention_designer.none") else
        tags$ul(class = "small", lapply(x, function(n) tags$li(paste(n, collapse = " → "))))
      lev_b <- cmp$leverage$baseline$Name; lev_c <- cmp$leverage$config$Name
      att <- function(a) if (!identical(a$status, "passed") && !identical(a$status, "topology_change_needed"))
        i18n$t("modules.intervention_designer.attractors_skipped") else
        paste0(i18n$t("modules.intervention_designer.attractors_total"), ": ", a$n_attractors, " · ",
               i18n$t("modules.intervention_designer.attractors_desirable"), ": ", a$n_desirable)
      tagList(
        h6(class = "mt-3", i18n$t("modules.intervention_designer.loops_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th(""), tags$th(i18n$t("modules.intervention_designer.col_before")),
                             tags$th(i18n$t("modules.intervention_designer.col_after")))),
          tags$tbody(
            tags$tr(tags$td(i18n$t("modules.intervention_designer.loops_reinforcing")),
                    tags$td(cnt(cmp$loops$baseline, "Reinforcing")), tags$td(cnt(cmp$loops$config, "Reinforcing"))),
            tags$tr(tags$td(i18n$t("modules.intervention_designer.loops_balancing")),
                    tags$td(cnt(cmp$loops$baseline, "Balancing")), tags$td(cnt(cmp$loops$config, "Balancing"))))),
        if (isTRUE(cmp$loop_diff$truncated)) p(class = "text-warning small", i18n$t("modules.intervention_designer.loops_truncated")),
        strong(i18n$t("modules.intervention_designer.loops_gained")), loop_list(cmp$loop_diff$gained),
        strong(i18n$t("modules.intervention_designer.loops_lost")), loop_list(cmp$loop_diff$lost),
        strong(i18n$t("modules.intervention_designer.loops_changed")), loop_list(cmp$loop_diff$changed),
        h6(class = "mt-3", i18n$t("modules.intervention_designer.leverage_heading")),
        tags$table(class = "table table-sm",
          tags$thead(tags$tr(tags$th("#"), tags$th(i18n$t("modules.intervention_designer.col_before")),
                             tags$th(i18n$t("modules.intervention_designer.col_after")))),
          tags$tbody(lapply(seq_len(max(length(lev_b), length(lev_c))), function(i) {
            after <- lev_c[i]
            moved <- if (is.na(after)) "" else {
              j <- match(after, lev_b)
              if (is.na(j)) paste0(" (", i18n$t("modules.intervention_designer.leverage_new"), ")")
              else if (j > i) " ↑" else if (j < i) " ↓" else ""
            }
            tags$tr(tags$td(i), tags$td(lev_b[i] %||% ""), tags$td(paste0(after %||% "", moved)))
          }))),
        h6(class = "mt-3", i18n$t("modules.intervention_designer.attractors_heading")),
        tags$ul(class = "small",
          tags$li(i18n$t("modules.intervention_designer.col_before"), ": ", att(cmp$attractors$baseline)),
          tags$li(i18n$t("modules.intervention_designer.col_after"), ": ", att(cmp$attractors$config)))
      )
    })
```

  (`lev_b[i]` beyond its length is `NA`; replace `%||%` there with `ifelse(is.na(x), "", x)` if `NA` shows.)

9. Apply:

```r
    observeEvent(input$apply, {
      if (isTRUE(rv$stale)) { showNotification(i18n$t("modules.intervention_designer.apply_stale"), type = "warning"); return() }
      if (!length(input$top_table_rows_selected)) {
        showNotification(i18n$t("modules.intervention_designer.need_row"), type = "warning"); return()
      }
      r <- rv$result; i <- input$top_table_rows_selected
      label <- r$design_matrix$new_node %||% i18n$t("modules.intervention_designer.reweight_heading")
      showModal(modalDialog(
        title = i18n$t("modules.intervention_designer.apply_title"),
        textInput(ns("apply_name"), i18n$t("modules.intervention_designer.apply_name"),
                  value = sprintf("%s — %s #%d", label, i18n$t("modules.intervention_designer.configuration"), r$top$rank[i])),
        textAreaInput(ns("apply_description"), i18n$t("modules.intervention_designer.apply_description"), rows = 3,
                      value = sprintf("%s: seed %s, %s/%s (%.1f%%), a=%s b=%s c=%s d=%s",
                                      i18n$t("modules.intervention_designer.apply_summary"), r$seed,
                                      format(r$n_a, big.mark = ","), format(r$n_eval, big.mark = ","), 100 * r$share,
                                      r$top$a[i], r$top$b[i], r$top$c[i], r$top$d[i])),
        footer = tagList(modalButton(i18n$t("common.buttons.cancel")),
                         actionButton(ns("confirm_apply"), i18n$t("modules.intervention_designer.apply_confirm"),
                                      class = "btn-primary"))))
    })
    observeEvent(input$confirm_apply, {
      if (isTRUE(rv$stale)) { showNotification(i18n$t("modules.intervention_designer.apply_stale"), type = "warning"); return() }
      req(length(input$top_table_rows_selected) == 1)
      r <- rv$result
      data <- project_data_reactive()
      if (exists("migrate_legacy_scenarios", mode = "function")) data <- migrate_legacy_scenarios(data)
      existing <- data$data$analysis$scenarios %||% list()
      tp <- input$type %||% ""
      sc <- tryCatch(ses_config_to_scenario(r$design_matrix, selected_levels(), data$data$cld, list(
        name = .scenario_unique_name(trimws(input$apply_name %||% ""), vapply(existing, function(s) s$name %||% "", "")),
        description = input$apply_description %||% "",
        intervention_type = tp,
        ebm_code = if (nzchar(tp)) paste(unlist(get_intervention_ebm_codes(tp)), collapse = ";") else NA_character_,
        now = Sys.time())), error = function(e) e)
      if (inherits(sc, "error")) {
        showNotification(format_user_error(sc, i18n = i18n, context_key = "modules.intervention_designer.context_apply"),
                         type = "error"); return()
      }
      if (!is.list(data$data$analysis)) data$data$analysis <- list()
      data$data$analysis$scenarios <- c(existing, list(sc))
      data$last_modified <- Sys.time()
      project_data_reactive(data)
      removeModal()
      showNotification(i18n$t("modules.intervention_designer.applied"), type = "message")
    })
```

  Check `common.buttons.cancel` exists (`grep -rn '"common.buttons.cancel"' translations/common`); if the cancel key has another name, use that one.

- [ ] **Step 4: Run tests** — `'^intervention-designer-module$'`, `'^intervention-designer'`, `'^scenario-builder-module$'`, `'^analysis-intervention'`; i18n audit `missing=0 hardcoded=0`.

- [ ] **Step 5: Commit** — `feat(wp5): Designer dependence table, structure compare and Apply to project (WS-7b)`.

---

### Task 9: Tuscany/Arctic tests, release 1.28.0, verification

**Files:**
- Modify: `tests/testthat/test-intervention-designer-d53.R` (append), `VERSION`, `VERSION_INFO.json`, `DESCRIPTION`, `CHANGELOG.md`

- [ ] **Step 1: Append D5.3 fixture tests** to `test-intervention-designer-d53.R`:

```r
test_that("mode C on Tuscany: 3^2 sign-preserving configurations", {
  e <- data.frame(from = c("Boat moorings", "Anchoring"), to = c(OBJ, OBJ), kind = "reweight",
                  min_level = -1, max_level = 1, stringsAsFactors = FALSE)
  p <- moorings_payload(1); p$design <- list(new_node = NULL, edges = e)
  r <- ses_run_design(p)
  expect_equal(r$n_eval, 9)
  expect_true(all(r$top_levels < 0))                            # both links stay negative
  expect_false(is.null(r$dependence) && r$n_a > 0)
})

test_that("combined design: self-loop + new node + one re-weight runs end to end", {
  p <- moorings_payload(1)
  p$design$edges <- rbind(p$design$edges,
    data.frame(from = "Boat moorings", to = OBJ, kind = "reweight", min_level = -1, max_level = -0.25))
  r <- ses_run_design(p)
  expect_equal(r$n_eval, 4^5 * 3)
  expect_equal(nrow(r$top_levels), 6L)
})

test_that("Arctic DA file: a 3^6 mode-C design completes (no D5.3 numbers asserted)", {
  f <- file.path(app_root_d53(), "SESModels", "Arctic DA", "Arctic Model edge and node data 20.02.2025V3.xlsx")
  skip_if_not(file.exists(f))
  skip_if_not_installed("openxlsx")
  # The file pads labels with U+00A0 / U+202F, which trimws() does not strip
  clean <- function(x) trimws(gsub("[[:space:]\u00a0\u202f]+", " ", enc2utf8(x)))
  nd <- openxlsx::read.xlsx(f, 1); ed <- openxlsx::read.xlsx(f, 2)
  lab <- clean(nd$Label); ed$From <- clean(ed$From); ed$To <- clean(ed$To)
  s <- tolower(clean(ed$Strength))
  w <- ifelse(grepl("strong", s), 1, ifelse(grepl("medium", s), 0.5, 0.25)) * ifelse(grepl("negative", s), -1, 1)
  m <- matrix(0, length(lab), length(lab), dimnames = list(lab, lab))
  ok <- ed$From %in% lab & ed$To %in% lab
  expect_equal(sum(ok), nrow(ed))                               # cleaning matched every endpoint
  m[cbind(ed$From[ok], ed$To[ok])] <- w[ok]
  pf <- "Pelagic fishing"
  idx <- which(m != 0 & (row(m) == match(pf, lab) | col(m) == match(pf, lab)), arr.ind = TRUE)[1:6, ]
  e <- data.frame(from = lab[idx[, 1]], to = lab[idx[, 2]], kind = "reweight", min_level = -1, max_level = 1,
                  stringsAsFactors = FALSE)
  r <- ses_run_design(list(base = m, design = list(new_node = NULL, edges = e), levels = LV,
                           objectives = c("Fish occurrence", "Reproductive success"), sustain = character(0),
                           seed = 1L, steps = 1000L, window = 100L, cap = 65536, chunk = 2048L, top_k = 5L,
                           max_boolean_nodes = 20L))
  expect_equal(r$n_eval, 3^6)
  expect_true(r$share >= 0 && r$share <= 1)
})
```

At the top of the file add `app_root_d53 <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }`. If "Pelagic fishing" has fewer than 6 links in the file, use `seq_len(min(6, nrow(...)))` and assert `3^nrow(e)`.

- [ ] **Step 2: Run** `'^intervention-designer-d53$'` — Expected: PASS.

- [ ] **Step 3: Release 1.28.0**
  - `VERSION` → `1.28.0`; `DESCRIPTION` `Version: 1.28.0`.
  - `VERSION_INFO.json`: `version` 1.28.0, `release_date` today, `release_type` minor, `previous_version` 1.27.0, version name "WP5 intervention designer — mode C, before/after, Apply to project"; replace the features list with the WS-7b items.
  - `CHANGELOG.md`: under `## [Unreleased]` add `## [1.28.0] - <today>` with `### Added (WP5 intervention designer — spec 2026-10-15 WS-7b)`: mode C re-weighting with fixed sign; link ranking by dominant-eigenvalue sensitivity; "What success depends on"; Compare structure (loops, leverage, attractors) as a background job; Apply to project → Scenario Builder scenario with `ops` and `links_modified`. `### Fixed`: Scenario Builder `predict_impacts()` crashed on scenarios that remove a link; added links failed to bind to baseline edges with extra columns. `### Notes`: participation ratio per component depends on eigen-solver mode order (spec §3.4, open item for DTU).

- [ ] **Step 4: Full verification** (one Rscript per chunk; report the pass/fail/skip of each):
  - `filter = '^[a-c]'`, `'^[d-h]'`, `'^[i-l]'`, `'^[m-o]'`, `'^[p-s]'`, `'^[t-z]'` — Expected: 0 failures.
  - `micromamba run -n shiny python scripts/_i18n_audit.py` — `missing=0 hardcoded=0`.
  - `Rscript deployment/pre-deploy-check.R` — all checks pass.

- [ ] **Step 5: Commit** — `chore(release): 1.28.0 — WP5 intervention designer mode C and Apply to project (WS-7b)`; force-add the plan and spec if changed.
