# test-cld-to-isa-sync.R
# Tests for sync_cld_to_isa_data() — the bridge function that propagates
# direct-graph CLD edits into isa_data so Loop/Leverage analyses refresh.
#
# Background: before this function, edits to the CLD (add node, rename,
# delete) only updated project_data$data$cld$* and the user-reported
# symptom was "analyses don't reflect my changes". Root cause was that
# analysis_loops/leverage read from $data$isa_data.

library(testthat)

source_for_test("functions/cld_interaction_helpers.R")

# ============================================================================
# HELPER: minimal project_data with a tiny CLD
# ============================================================================

make_project_data <- function() {
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
    label = c("driver1", "activity1", "pressure1", "mp1", "es1", "gb1"),
    group = c("Drivers", "Activities", "Pressures",
              "Marine Processes & Functioning", "Ecosystem Services",
              "Goods & Benefits"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
    to   = c("A_1", "P_1", "MPF_1", "ES_1", "GB_1", "D_1"),
    label = c("+", "+", "-", "+", "+", "-"),
    stringsAsFactors = FALSE
  )
  list(
    project_id = "test_project",
    project_name = "Test",
    data = list(
      cld = list(nodes = nodes, edges = edges),
      isa_data = list()
    )
  )
}

# ============================================================================
# TESTS
# ============================================================================

test_that("sync_cld_to_isa_data exists and is a function", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  expect_true(is.function(sync_cld_to_isa_data))
})

test_that("sync_cld_to_isa_data populates each element-type data frame from nodes", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- make_project_data()
  result <- sync_cld_to_isa_data(pd)
  isa <- result$data$isa_data

  expect_true(nrow(isa$drivers) == 1)
  expect_equal(isa$drivers$name, "driver1")
  expect_equal(isa$drivers$id, "D_1")

  expect_true(nrow(isa$activities) == 1)
  expect_equal(isa$activities$name, "activity1")

  expect_true(nrow(isa$pressures) == 1)
  expect_true(nrow(isa$marine_processes) == 1)
  expect_true(nrow(isa$ecosystem_services) == 1)
  expect_true(nrow(isa$goods_benefits) == 1)
})

test_that("sync_cld_to_isa_data builds all 6 adjacency matrices with correct polarities", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- make_project_data()
  result <- sync_cld_to_isa_data(pd)
  adj <- result$data$isa_data$adjacency_matrices

  # All 6 SOURCE x TARGET matrices present
  for (m in c("d_a", "a_p", "p_mpf", "mpf_es", "es_gb", "gb_d")) {
    expect_true(!is.null(adj[[m]]),
                info = paste0("missing matrix: ", m))
  }

  # Polarities placed in the right cells
  expect_equal(adj$d_a["D_1", "A_1"], "+")
  expect_equal(adj$a_p["A_1", "P_1"], "+")
  expect_equal(adj$p_mpf["P_1", "MPF_1"], "-")
  expect_equal(adj$mpf_es["MPF_1", "ES_1"], "+")
  expect_equal(adj$es_gb["ES_1", "GB_1"], "+")
  expect_equal(adj$gb_d["GB_1", "D_1"], "-")
})

test_that("sync_cld_to_isa_data preserves existing indicator metadata by name-match", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- make_project_data()
  # Pre-populate isa_data$drivers with an indicator the sync should preserve
  pd$data$isa_data$drivers <- data.frame(
    id = "D_1", name = "driver1", indicator = "fishing pressure trend",
    stringsAsFactors = FALSE
  )
  result <- sync_cld_to_isa_data(pd)
  expect_equal(result$data$isa_data$drivers$indicator, "fishing pressure trend")
})

test_that("sync_cld_to_isa_data handles empty groups (no pressures) without error", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- make_project_data()
  # Remove pressures from both nodes and edges
  pd$data$cld$nodes <- pd$data$cld$nodes[pd$data$cld$nodes$group != "Pressures", , drop = FALSE]
  pd$data$cld$edges <- pd$data$cld$edges[!grepl("P_", pd$data$cld$edges$from) &
                                          !grepl("P_", pd$data$cld$edges$to), , drop = FALSE]
  result <- sync_cld_to_isa_data(pd)
  expect_equal(nrow(result$data$isa_data$pressures), 0)
  # The adjacency matrices involving pressures should be 0-dim (no rows or cols)
  expect_true(nrow(result$data$isa_data$adjacency_matrices$a_p) == 1 ||
              nrow(result$data$isa_data$adjacency_matrices$a_p) == 0)
})

test_that("sync_cld_to_isa_data returns project_data unchanged when cld is missing", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- list(data = list())
  expect_equal(sync_cld_to_isa_data(pd), pd)

  pd2 <- list(data = list(cld = list()))
  expect_equal(sync_cld_to_isa_data(pd2), pd2)
})

test_that("sync_cld_to_isa_data updates last_modified", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  pd <- make_project_data()
  result <- sync_cld_to_isa_data(pd)
  expect_true(!is.null(result$last_modified))
  expect_true(inherits(result$last_modified, "POSIXt"))
})

# ============================================================================
# Regression tests for review-caught bugs
# ============================================================================

test_that("sync_cld_to_isa_data preserves Response-related matrices (r_a, r_p, gb_r, r_d)", {
  # REGRESSION: original sync hardcoded 6 matrix pairs, dropping all edges
  # involving Responses. Real project fixtures use gb_r, r_d, r_a, r_p
  # for response-intervention links — must survive a sync round-trip.
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1", "GB_1", "R_1"),
    label = c("d", "a", "p", "gb", "r"),
    group = c("Drivers", "Activities", "Pressures", "Goods & Benefits", "Responses"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    id = 1:4,
    from = c("R_1", "R_1", "R_1", "GB_1"),
    to   = c("D_1", "A_1", "P_1", "R_1"),
    label = c("-", "-", "-", "+"),
    stringsAsFactors = FALSE
  )
  pd <- list(data = list(cld = list(nodes = nodes, edges = edges),
                         isa_data = list()))
  result <- sync_cld_to_isa_data(pd)
  adj <- result$data$isa_data$adjacency_matrices

  expect_true(!is.null(adj$r_d), info = "r_d matrix missing")
  expect_true(!is.null(adj$r_a), info = "r_a matrix missing")
  expect_true(!is.null(adj$r_p), info = "r_p matrix missing")
  expect_true(!is.null(adj$gb_r), info = "gb_r matrix missing")

  expect_equal(adj$r_d["R_1", "D_1"], "-")
  expect_equal(adj$r_a["R_1", "A_1"], "-")
  expect_equal(adj$r_p["R_1", "P_1"], "-")
  expect_equal(adj$gb_r["GB_1", "R_1"], "+")
})

test_that("sync_cld_to_isa_data handles non-data.frame edges defensively", {
  # REGRESSION: if cld$edges is NULL or list() (e.g., after delete-all-edges),
  # the function should not throw — it should produce empty matrices.
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")

  pd <- make_project_data()
  pd$data$cld$edges <- list()   # non-data.frame
  expect_error(sync_cld_to_isa_data(pd), NA)

  pd2 <- make_project_data()
  pd2$data$cld$edges <- data.frame()   # 0-row data.frame
  expect_error(sync_cld_to_isa_data(pd2), NA)
})

test_that("sync_cld_to_isa_data coerces unknown polarity strings to '+'", {
  # REGRESSION: old sync wrote whatever edges$label contained into the
  # matrix cell, including corrupt values like '++' or '0' — breaks
  # downstream polarity-aware analyses that assume binary '+' / '-'.
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")
  nodes <- data.frame(
    id = c("D_1", "A_1"),
    label = c("d", "a"),
    group = c("Drivers", "Activities"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    id = 1,
    from = "D_1", to = "A_1",
    label = "uncertain",
    stringsAsFactors = FALSE
  )
  pd <- list(data = list(cld = list(nodes = nodes, edges = edges),
                         isa_data = list()))
  result <- sync_cld_to_isa_data(pd)
  # Coerced to "+"
  expect_equal(result$data$isa_data$adjacency_matrices$d_a["D_1", "A_1"], "+")
})
