# tests/testthat/test-decision-lens.R
# Unit tests for functions/decision_lens.R (QSEM Decision Lens pure helpers)

# Self-contained load (mirrors test-network-analysis.R) so the file runs
# standalone via testthat::test_file() as well as in the full suite.
if (!exists("classify_factors_micmac") || !exists("calculate_micmac_safe")) {
  tryCatch({
    suppressPackageStartupMessages({
      library(igraph)
      library(dplyr)
    })
    source(file.path("..", "..", "functions", "network_analysis.R"), local = TRUE)
    source(file.path("..", "..", "functions", "decision_lens.R"), local = TRUE)
  }, error = function(e) {
    skip(paste("Cannot load decision_lens.R deps:", e$message))
  })
}

# Realistic fixture: FULL-NAME groups + PREFIXED ids, matching create_nodes_df
# output (NOT fabricated short codes — see spec §0 data-model fix).
make_fixture_nodes <- function() {
  data.frame(
    id    = c("D_1", "A_1", "P_1", "MPF_1"),
    label = c("Driver", "Activity", "Pressure", "State"),
    group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
    stringsAsFactors = FALSE
  )
}
make_fixture_edges <- function() {
  data.frame(
    from     = c("D_1", "A_1", "P_1", "MPF_1"),
    to       = c("A_1", "P_1", "MPF_1", "D_1"),
    polarity = c("+", "+", "-", "+"),
    stringsAsFactors = FALSE
  )
}

test_that("dl_code_from_id strips the numeric suffix to the DAPSIWRM code", {
  expect_equal(dl_code_from_id(c("D_1", "MPF_3", "GB_12", "R_2")),
               c("D", "MPF", "GB", "R"))
})

test_that("classify_factors_micmac joins labels and full-name groups onto MICMAC output", {
  res <- classify_factors_micmac(make_fixture_nodes(), make_fixture_edges())

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 4)
  expect_setequal(names(res),
                  c("id", "label", "group", "influence", "dependence", "quadrant"))
  expect_setequal(res$label, c("Driver", "Activity", "Pressure", "State"))
  # group stays the FULL category name (not a short code)
  expect_true("Marine Processes & Functioning" %in% res$group)
  expect_true(all(res$quadrant %in% c("Relay", "Influential", "Dependent", "Autonomous")))
  expect_type(res$influence, "double")
  expect_type(res$dependence, "double")
})

test_that("classify_factors_micmac returns empty frame with stable columns on no edges", {
  res <- classify_factors_micmac(make_fixture_nodes(), edges = data.frame())
  expect_equal(nrow(res), 0)
  expect_setequal(names(res),
                  c("id", "label", "group", "influence", "dependence", "quadrant"))
})

# ---------------------------------------------------------------------------
# build_decision_narrative — i18n stub echoes keys so assertions are
# language-independent.
# ---------------------------------------------------------------------------
test_that("build_decision_narrative fuses quadrant, loops, and archetype leverage", {
  i18n <- list(t = function(k, ...) k)

  micmac <- data.frame(
    id = "P_1", label = "Pressure", group = "Pressures",
    influence = 5, dependence = 2, quadrant = "Influential",
    stringsAsFactors = FALSE
  )
  loop_info <- data.frame(
    LoopID = c(1L, 2L), Type = c("Reinforcing", "Balancing"),
    NodeIDs = c("D_1,A_1,P_1", "A_1,P_1,MPF_1"), stringsAsFactors = FALSE
  )
  archetypes <- list(list(
    archetype_key = "limits_to_growth", loop_ids = c(1L, 2L),
    node_ids = c("D_1", "A_1", "P_1", "MPF_1"), shared_node_ids = "A_1",
    leverage_node_id = "P_1", confidence = "candidate"
  ))

  html <- build_decision_narrative("P_1", micmac, loop_info, archetypes, i18n)

  expect_type(html, "character")
  expect_match(html, "modules.analysis.decision_lens.quad_influential", fixed = TRUE)
  expect_match(html, "modules.analysis.decision_lens.narrative_in_loops", fixed = TRUE)
  expect_match(html, "modules.analysis.decision_lens.archetype.limits_to_growth.name", fixed = TRUE)
  expect_match(html, "modules.analysis.decision_lens.narrative_confirm", fixed = TRUE)
})

test_that("build_decision_narrative omits archetype line when archetypes is empty (deferred path)", {
  i18n <- list(t = function(k, ...) k)
  micmac <- data.frame(id = "MPF_1", label = "State", group = "Marine Processes & Functioning",
                       influence = 1, dependence = 6, quadrant = "Dependent",
                       stringsAsFactors = FALSE)
  loop_info <- data.frame(LoopID = 1L, Type = "Balancing",
                          NodeIDs = "A_1,P_1,MPF_1", stringsAsFactors = FALSE)
  html <- build_decision_narrative("MPF_1", micmac, loop_info, archetypes = list(), i18n)
  expect_match(html, "modules.analysis.decision_lens.quad_dependent", fixed = TRUE)
  expect_match(html, "modules.analysis.decision_lens.narrative_confirm", fixed = TRUE)
  expect_false(grepl("narrative_archetype_leverage", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# detect_archetypes — topology-correct (validated 2026-06-21). Ships B + A only.
# Fixtures use real create_nodes_df-style ids (D_1, MPF_1, R_1, ...).
# ---------------------------------------------------------------------------
test_that("detect_archetypes finds Tragedy of the Commons: shared MPF in >=2 loops, >=2 distinct Activities", {
  # Two activity loops sharing the State/MPF resource, each closing via GB->D->A
  loop_info <- data.frame(
    LoopID  = c(1L, 2L),
    Type    = c("Reinforcing", "Reinforcing"),
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "D_1,A_2,P_2,MPF_1,ES_1,GB_1"),
    stringsAsFactors = FALSE
  )
  res <- detect_archetypes(loop_info)
  keys <- vapply(res, function(x) x$archetype_key, character(1))
  expect_true("tragedy_of_the_commons" %in% keys)
  toc <- res[[which(keys == "tragedy_of_the_commons")[1]]]
  expect_equal(toc$leverage_node_id, "MPF_1")       # govern the shared resource
  expect_setequal(toc$loop_ids, c(1L, 2L))
  expect_equal(toc$confidence, "candidate")
})

test_that("detect_archetypes does NOT fire Commons with only one Activity across the loops", {
  loop_info <- data.frame(
    LoopID  = c(1L, 2L),
    Type    = c("Reinforcing", "Balancing"),
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "GB_1,R_1,MPF_1,ES_1"),     # second loop has no distinct second Activity
    stringsAsFactors = FALSE
  )
  res <- detect_archetypes(loop_info)
  keys <- vapply(res, function(x) x$archetype_key, character(1))
  expect_false("tragedy_of_the_commons" %in% keys)
})

test_that("detect_archetypes finds Limits to Growth: reinforcing engine coupled to Response-mediated balancing loop", {
  loop_info <- data.frame(
    LoopID  = c(1L, 2L),
    Type    = c("Reinforcing", "Balancing"),
    # engine (GB->D closed) shares GB_1/ES_1/MPF_1 with the Response-mediated balancing loop
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "GB_1,R_1,P_1,MPF_1,ES_1"),
    stringsAsFactors = FALSE
  )
  res <- detect_archetypes(loop_info)
  keys <- vapply(res, function(x) x$archetype_key, character(1))
  expect_true("limits_to_growth" %in% keys)
  ltg <- res[[which(keys == "limits_to_growth")[1]]]
  expect_equal(ltg$leverage_node_id, "R_1")          # the management Response, NOT the Pressure
  expect_setequal(ltg$loop_ids, c(1L, 2L))
})

test_that("detect_archetypes returns empty list when there are no loops", {
  expect_equal(detect_archetypes(data.frame()), list())
  expect_equal(detect_archetypes(NULL), list())
})
