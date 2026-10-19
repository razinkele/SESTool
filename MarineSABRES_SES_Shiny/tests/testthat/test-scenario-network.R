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
  args <- list(...)
  m[names(args)] <- args       # not modifyList(): it merges list(list(...)) into list() and drops it
  m
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

# --- feedback 2026-10-13 "Scenario Builder": the saved CLD (create_edges_df)
# has no edge id and no from/to labels, and the builder crashed on them -------
saved_cld <- function() {
  cld <- base_cld()
  cld$edges$id <- NULL                       # shape written by create_edges_df()
  cld
}

test_that("scenario_baseline_edges adds endpoint ids and labels when the CLD has none", {
  e <- scenario_baseline_edges(saved_cld())
  expect_equal(e$id, c("D_1->A_1", "A_1->P_1"))
  expect_equal(e$from_label, c("Demand", "Boating"))
  expect_equal(e$to_label, c("Boating", "Anchoring"))
})

test_that("scenario_baseline_edges keeps existing ids and labels", {
  cld <- base_cld(); cld$edges$from_label <- c("x", "y"); cld$edges$to_label <- c("y", "z")
  e <- scenario_baseline_edges(cld)
  expect_equal(e$id, 1:2)
  expect_equal(e$from_label, c("x", "y"))
})

test_that("scenario_baseline_edges handles a CLD without edges", {
  cld <- saved_cld(); cld$edges <- cld$edges[0, , drop = FALSE]
  expect_equal(nrow(scenario_baseline_edges(cld)), 0L)
  expect_equal(nrow(scenario_baseline_edges(list(nodes = cld$nodes, edges = NULL))), 0L)
})

test_that("a link removed by its endpoint id is removed from a CLD without edge ids", {
  out <- scenario_apply_modifications(saved_cld(), mods(links_removed = "A_1->P_1"))
  expect_equal(nrow(out$edges), 1L)
  expect_equal(out$edges$to, "A_1")
})
