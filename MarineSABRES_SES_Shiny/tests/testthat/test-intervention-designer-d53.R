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
       seed = 20261014L, steps = 1000L, window = 100L, cap = 65536, chunk = 2048L,
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
  p <- moorings_payload(1); p$chunk <- 100L     # 11 chunks, ragged last one: checks chunk boundaries
  r <- ses_run_design(p)
  dm <- r$design_matrix
  x0 <- c(.with_seed(p$seed, stats::runif(nrow(p$base))), 0.5)
  expect_equal(r$x0, x0)
  cfg <- ses_grid_decode(seq_len(r$n_eval), dm$level_sets)
  obj <- match(p$objectives, rownames(dm$matrix))
  a_ref <- vapply(seq_len(r$n_eval), function(i) {
    At <- t(ses_apply_config(dm, cfg[, i])); x <- x0; ok <- TRUE
    for (t in 2:1000) { x <- drop(At %*% x); if (t %% 10 == 0) { s <- sum(abs(x)); if (s > 0) x <- x / s }
      if (t > 900) ok <- ok && x[obj] > 0 }
    ok
  }, logical(1))
  expect_equal(r$n_a, sum(a_ref))
  expect_equal(r$n_a, ses_run_design(moorings_payload(1))$n_a)   # independent of chunk size
})

test_that("progress: pre-check status first, then forward-only to completion (spec §4.6)", {
  calls <- list()
  p <- moorings_payload(1); p$chunk <- 100L
  ses_run_design(p, progress = function(done, total, precheck = NULL)
    calls[[length(calls) + 1L]] <<- list(done = done, total = total, precheck = precheck))
  done <- vapply(calls, function(x) x$done, numeric(1))
  expect_equal(calls[[1]]$done, 0)
  expect_true(calls[[1]]$precheck %in% c("passed", "topology_change_needed", "skipped", "unavailable"))
  expect_true(all(vapply(calls[-1], function(x) is.null(x$precheck), logical(1))))
  expect_true(all(vapply(calls, function(x) x$total == 1000, logical(1))))
  expect_true(all(diff(done) >= 0))
  expect_equal(sum(done > 0 & done <= 900), 11)              # one call per grid chunk
  expect_equal(tail(done, 1), 1000)
})

test_that("ses_config_final_state agrees with criterion (a) for top configurations (review focus 3)", {
  r <- ses_run_design(moorings_payload(1))
  obj <- match(r$objectives, rownames(r$design_matrix$matrix))
  expect_true(any(r$top$a))
  for (k in which(r$top$a)) {
    fs <- ses_config_final_state(ses_apply_config(r$design_matrix, r$top_levels[, k]), r$x0, r$steps)
    expect_true(all(fs[obj] > 0), info = paste("top row", k))
  }
  fb <- ses_config_final_state(r$base, r$x0[seq_len(nrow(r$base))], r$steps)
  expect_equal(names(fb), rownames(r$base))
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
    seed = 1L, steps = 1000L, window = 100L, cap = 65536, chunk = 2048L, top_k = 20L,
    max_boolean_nodes = 20L)
  r <- ses_run_design(p)
  expect_equal(r$n_eval, 7^4)
  expect_equal(r$precheck$status, "skipped")                # 29 nodes > 20
  expect_true(is.numeric(r$share) && r$share >= 0 && r$share <= 1)
})
