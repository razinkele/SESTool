# tests/testthat/test-intervention-designer-d53.R
# D5.3 Tuscany "additional moorings" (C§4.3, FIN:1461-1585), built from the
# edges D5.3 describes in text. Labels keep D5.3's punctuation on purpose.
source_for_test("functions/intervention_designer.R")
app_root_d53 <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }

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

# -- Stability time budget (final review item 2) -------------------------------
test_that("default run checks every (a) row: counts unchanged, not partial", {
  r <- ses_run_design(moorings_payload(1))                  # no stability_budget_s: no limit
  expect_false(r$stability_partial)
  expect_equal(c(r$n_a, r$n_ab, r$n_abc), c(733, 733, 5))   # grid row 893 included, see below
  p <- moorings_payload(1); p$stability_budget_s <- Inf
  expect_identical(ses_run_design(p)$n_abc, r$n_abc)
})

test_that("a zero stability budget leaves (c) unchecked and flags the result partial", {
  p <- moorings_payload(1); p$stability_budget_s <- 0
  calls <- list()
  r <- ses_run_design(p, progress = function(done, total, precheck = NULL)
    calls[[length(calls) + 1L]] <<- done)
  expect_true(r$stability_partial)
  expect_equal(r$n_a, 733)
  expect_true(all(is.na(r$top$c[r$top$a])))                 # unchecked rows keep NA
  expect_equal(r$n_abc, 0)
  done <- unlist(calls)
  expect_true(all(diff(done) >= 0))
  expect_equal(tail(done, 1), 1000)
})

test_that("stability is checked for (a)&(b) rows before (a)-only rows, each in grid order", {
  expect_equal(.ses_stability_order(c(TRUE, TRUE, FALSE, TRUE, TRUE), c(FALSE, TRUE, TRUE, FALSE, TRUE)),
               c(2L, 5L, 1L, 4L))
  # The real run calls the stability check in exactly that order. Sustaining
  # "Anchoring" leaves many rows that pass (a) but not (b).
  p <- moorings_payload(1); p$sustain <- "Anchoring"
  seen <- list()
  orig <- get("ses_is_stable_attractor", envir = globalenv())
  assign("ses_is_stable_attractor", function(mat, ...) {
    seen[[length(seen) + 1L]] <<- mat
    orig(mat, ...)
  }, envir = globalenv())
  withr::defer(assign("ses_is_stable_attractor", orig, envir = globalenv()))
  r <- ses_run_design(p)
  expect_false(r$sampled)                                   # grid index == position
  dm <- r$design_matrix
  cfg <- ses_grid_decode(seq_len(r$n_eval), dm$level_sets)
  ev <- ses_grid_evaluate(dm, cfg, match(p$objectives, rownames(dm$matrix)),
                          match(p$sustain, rownames(dm$matrix)), r$x0, p$steps, p$window)
  expected <- c(which(ev$a & ev$b), which(ev$a & !ev$b))
  expect_gt(sum(ev$a & ev$b), 0)
  expect_gt(sum(ev$a & !ev$b), 0)
  cfg_key <- apply(cfg, 2, paste, collapse = ",")
  checked <- match(vapply(seen, function(m) paste(m[dm$cells], collapse = ","), character(1)), cfg_key)
  expect_equal(checked, expected)
  expect_false(r$stability_partial)
})

test_that("a repeated real Laplacian eigenvalue counts as stable on every BLAS build", {
  # Grid row 893 has a double eigenvalue 0.5. Rounding splits it into
  # 0.5 +/- 1.6e-8i with Windows' reference LAPACK but not with OpenBLAS, so an
  # absolute 1e-9 tolerance gave n_abc 4 on Windows and 5 on Linux CI.
  dm <- ses_design_matrix(moorings_payload(1)$base, moorings_payload(1)$design, LV)
  m <- ses_apply_config(dm, ses_grid_decode(893, dm$level_sets)[, 1])
  expect_equal(unname(ses_grid_decode(893, dm$level_sets)[, 1]), c(0, 1, 0, -0.5, 1))
  expect_true(ses_is_stable_attractor(m))
})

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

test_that("Arctic DA file: a mode-C design on Pelagic fishing links completes (no D5.3 numbers asserted)", {
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
  idx <- which(m != 0 & (row(m) == match(pf, lab) | col(m) == match(pf, lab)), arr.ind = TRUE)
  idx <- idx[seq_len(min(6L, nrow(idx))), , drop = FALSE]
  expect_gte(nrow(idx), 3L)
  e <- data.frame(from = lab[idx[, 1]], to = lab[idx[, 2]], kind = "reweight", min_level = -1, max_level = 1,
                  stringsAsFactors = FALSE)
  r <- ses_run_design(list(base = m, design = list(new_node = NULL, edges = e), levels = LV,
                           objectives = c("Fish occurrence", "Reproductive success"), sustain = character(0),
                           seed = 1L, steps = 1000L, window = 100L, cap = 65536, chunk = 2048L, top_k = 5L,
                           max_boolean_nodes = 20L))
  expect_equal(r$n_eval, 3^nrow(idx))
  expect_true(r$share >= 0 && r$share <= 1)
})
