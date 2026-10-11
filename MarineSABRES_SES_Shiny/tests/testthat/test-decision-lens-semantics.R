# tests/testthat/test-decision-lens-semantics.R
# Decision Lens rule changes signed off 2026-10-11 (review 2026-10-07):
#   N37  MICMAC quadrants against the mean; "Undifferentiated" when every node
#        has the same influence and dependence (was: all "Autonomous").
#   N35  Limits to Growth needs a balancing loop through an MPF or ES node.
#   N52  One Tragedy-of-the-Commons record per commons: no ES duplicate of an
#        MPF commons.
source_for_test(c("functions/network_analysis.R", "functions/decision_lens.R"))

cycle_nodes <- function() data.frame(
  id    = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1", "R_1"),
  label = c("Driver", "Activity", "Pressure", "State", "Service", "Benefit", "Response"),
  group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
            "Ecosystem Services", "Goods & Benefits", "Responses"),
  stringsAsFactors = FALSE
)
cycle_edges <- function() data.frame(
  from = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1", "R_1"),
  to   = c("A_1", "P_1", "MPF_1", "ES_1", "GB_1", "R_1", "D_1"),
  polarity = "+", stringsAsFactors = FALSE
)

# ---- N37 -------------------------------------------------------------------
test_that("N37: a uniform 7-node cycle is Undifferentiated, not all Autonomous", {
  res <- calculate_micmac(cycle_nodes(), cycle_edges())
  expect_false(any(res$quadrant == "Autonomous"))
  expect_true(all(res$quadrant == "Undifferentiated"))
})

test_that("N37: quadrants are assigned against the mean of influence and exposure", {
  nodes <- data.frame(id = c("D_1", "D_2", "A_1", "A_2", "P_1", "MPF_1"), stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "D_1", "D_2", "A_1", "A_2", "P_1"),
                      to   = c("A_1", "A_2", "A_1", "P_1", "P_1", "MPF_1"),
                      stringsAsFactors = FALSE)
  res <- calculate_micmac(nodes, edges)
  hi_i <- res$influence > mean(res$influence)
  hi_e <- res$exposure > mean(res$exposure)
  expected <- ifelse(hi_i & hi_e, "Relay", ifelse(hi_i, "Influential",
                     ifelse(hi_e, "Dependent", "Autonomous")))
  expect_identical(res$quadrant, expected)
  expect_true(length(unique(res$quadrant)) > 1)
})

test_that("N37: the Undifferentiated label and narrative are translated", {
  t_en <- list(t = function(k, ...) {
    tr <- jsonlite::fromJSON(file.path(getwd(), "../..", "translations/modules/analysis_decision_lens.json"),
                             simplifyVector = FALSE)$translation
    tr[[k]][["en"]] %||% k
  })
  expect_identical(dl_quadrant_label("Undifferentiated", t_en), "Undifferentiated")
  micmac <- classify_factors_micmac(cycle_nodes(), cycle_edges())
  html <- build_decision_narrative("P_1", micmac, NULL, list(), t_en)
  expect_true(grepl("does not mean low priority", html, fixed = TRUE))
  expect_false(grepl("lower priority", html, fixed = TRUE))
})

# ---- N35 -------------------------------------------------------------------
test_that("N35: a policy-only balancing loop (no MPF/ES) does not make Limits to Growth", {
  loop_info <- data.frame(
    LoopID  = c(1L, 2L),
    Type    = c("Reinforcing", "Balancing"),
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "R_1,R_2,A_1"),          # shares A_1, but never touches the ecosystem
    stringsAsFactors = FALSE
  )
  keys <- vapply(detect_archetypes(loop_info), `[[`, "", "archetype_key")
  expect_false("limits_to_growth" %in% keys)
})

test_that("N35: a balancing loop through the ecosystem still makes Limits to Growth", {
  loop_info <- data.frame(
    LoopID  = c(1L, 2L),
    Type    = c("Reinforcing", "Balancing"),
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "GB_1,R_1,P_1,MPF_1,ES_1"),
    stringsAsFactors = FALSE
  )
  res <- detect_archetypes(loop_info)
  keys <- vapply(res, `[[`, "", "archetype_key")
  expect_true("limits_to_growth" %in% keys)
  expect_identical(res[[which(keys == "limits_to_growth")]]$leverage_node_id, "R_1")
})

# ---- N52 -------------------------------------------------------------------
test_that("N52: an ES whose loops overlap an MPF commons is not reported again", {
  loop_info <- data.frame(
    LoopID  = 1:3,
    Type    = "Reinforcing",
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "D_1,A_2,P_2,MPF_1,ES_1,GB_1",
                "D_1,A_3,P_3,MPF_2,ES_1,GB_2"),   # ES_1's loop-set {1,2,3} is a superset of MPF_1's {1,2}
    stringsAsFactors = FALSE
  )
  res <- detect_archetypes(loop_info)
  toc <- Filter(function(a) a$archetype_key == "tragedy_of_the_commons", res)
  expect_length(toc, 1)
  expect_identical(toc[[1]]$leverage_node_id, "MPF_1")
})

test_that("N52: an ES commons with no MPF commons behind it is still reported", {
  loop_info <- data.frame(
    LoopID  = 1:2,
    Type    = "Reinforcing",
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1",
                "D_1,A_2,P_2,MPF_2,ES_1,GB_1"),   # each MPF in one loop only
    stringsAsFactors = FALSE
  )
  toc <- Filter(function(a) a$archetype_key == "tragedy_of_the_commons", detect_archetypes(loop_info))
  expect_length(toc, 1)
  expect_identical(toc[[1]]$leverage_node_id, "ES_1")
})
