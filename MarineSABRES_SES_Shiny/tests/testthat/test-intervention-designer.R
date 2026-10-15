# tests/testthat/test-intervention-designer.R
# WS-7a intervention designer: pure engine (spec 2026-10-14 §4).
source_for_test("functions/intervention_designer.R")

LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)

test_that("constants match the spec", {
  expect_equal(INTERVENTION_GRID_LEVELS, LV)
  expect_equal(INTERVENTION_GRID_CAP, 65536)
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
  g <- ses_intervention_grid(list(1:7, 1:4), cap = 65536, seed = 1)
  expect_equal(g$n_total, 28); expect_false(g$sampled); expect_null(g$indices); expect_equal(g$n_eval, 28)
  g2 <- ses_intervention_grid(rep(list(1:7), 6), cap = 65536, seed = 1)   # 117,649
  expect_true(g2$sampled); expect_equal(g2$n_eval, 65536)
  expect_equal(length(unique(g2$indices)), 65536L)
  expect_true(all(g2$indices >= 1 & g2$indices <= 117649))
  expect_false(is.unsorted(g2$indices))
})

test_that("D5.3's 50,176-combination Tuscany grid is exhaustive under the cap", {
  g <- ses_intervention_grid(c(rep(list(1:4), 5), rep(list(1:7), 2)), cap = INTERVENTION_GRID_CAP, seed = 1)
  expect_equal(g$n_total, 50176)
  expect_false(g$sampled)
  expect_equal(g$n_eval, 50176)
  expect_null(g$indices)
})

test_that("grids above 2^31 sample without overflow (review focus 4)", {
  g <- ses_intervention_grid(rep(list(LV), 12), cap = 65536, seed = 7)     # 7^12 = 13.8e9
  expect_equal(g$n_total, 7^12)
  expect_true(g$sampled)
  expect_equal(length(unique(g$indices)), 65536L)
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
  a <- ses_intervention_grid(rep(list(1:7), 6), cap = 65536, seed = 3)$indices
  after <- runif(1)
  expect_equal(before, after)
  b <- ses_intervention_grid(rep(list(1:7), 6), cap = 65536, seed = 3)$indices
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

test_that("new-edge check flags only non-standard transitions", {
  skip_if_not(exists("validate_connection_with_feedback", mode = "function"))
  expect_false(ses_check_new_edge("Drivers", "Activities"))
  expect_true(ses_check_new_edge("Goods & Benefits", "Pressures"))
})

test_that("level codes", {
  expect_equal(ses_level_code(LV), c("strong_neg", "medium_neg", "weak_neg", "none",
                                     "weak_pos", "medium_pos", "strong_pos"))
})

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
  # positive-biased weights so outcomes vary across configurations (non-vacuous)
  base[cbind(sample(n, 12, TRUE), sample(n, 12, TRUE))] <-
    sample(c(-1, -0.5, 0.5, 1), 12, TRUE, prob = c(0.1, 0.1, 0.4, 0.4))
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
    rd <- rand_design(38, new_node = case[1], self_loop = case[2])
    dm <- ses_design_matrix(rd$base, rd$design, LV)
    n <- nrow(dm$matrix)
    set.seed(5)
    x0 <- c(runif(nrow(rd$base), 0.2, 1), if (case[1]) 0.5)
    g <- ses_intervention_grid(dm$level_sets, cap = 65536, seed = 1)
    idx <- seq_len(min(g$n_eval, 300))
    cfg <- ses_grid_decode(idx, dm$level_sets)
    got <- ses_grid_evaluate(dm, cfg, objective_idx = 1L, sustain_idx = c(2L, 5L), x0 = x0,
                             steps = 200L, window = 50L)
    want <- vapply(idx, function(i) ref_eval(dm, cfg[, i], 1L, c(2L, 5L), x0, 200L, 50L), logical(2))
    # non-vacuity: both outcomes occur for (a) and (b), so a swap or window bug shows
    expect_true(any(got$a) && !all(got$a))
    expect_true(any(got$b) && !all(got$b))
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
  base <- matrix(c(4, 0, 0, 4), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  dm <- ses_design_matrix(base, list(new_node = NULL, edges = data.frame(
    from = "a", to = "b", kind = "context", min_level = 0, max_level = 1)), LV)
  cfg <- ses_grid_decode(1:4, dm$level_sets)
  r <- ses_grid_evaluate(dm, cfg, 1L, 2L, c(1, 1), steps = 1000L, window = 100L)
  expect_true(all(r$a)); expect_true(all(r$b))
})

test_that("ses_grid_evaluate rejects inconsistent arguments", {
  base <- matrix(c(0, 1, 1, 0), 2, 2, dimnames = rep(list(c("a", "b")), 2))
  dm <- ses_design_matrix(base, list(new_node = NULL, edges = data.frame(
    from = "a", to = "a", kind = "context", min_level = 0, max_level = 1)), LV)
  cfg <- matrix(0, 1, 2)
  expect_error(ses_grid_evaluate(dm, cfg, 1L, 2L, c(1, 1), steps = 1L, window = 1L))
  expect_error(ses_grid_evaluate(dm, cfg, 1L, 2L, c(1, 1), steps = 10L, window = 11L))
  expect_error(ses_grid_evaluate(dm, matrix(0, 2, 2), 1L, 2L, c(1, 1), steps = 10L, window = 5L))
  expect_error(ses_grid_evaluate(dm, cfg, 1L, 2L, 1, steps = 10L, window = 5L))
})
