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
