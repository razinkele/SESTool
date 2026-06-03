# tests/testthat/test-normalize-reconcile-project.R
# TDD tests for normalize_and_reconcile_project() helper (Task B2).
# Ensure the helper is available (data_structure.R is in global.R's source
# chain, so it is loaded by helper-00-load-functions.R in a full testthat run;
# the explicit source_for_test call below is a safety net for standalone usage).
source_for_test("functions/data_structure.R")

# Ensure debug_log exists outside full app bootstrap
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = "") invisible(NULL)
}

# ============================================================================
# Basic contract
# ============================================================================

test_that("normalize_and_reconcile_project lowercases->reconciles element IDs to unique uppercase ID", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  proj <- list(data = list(isa_data = list(
    drivers = data.frame(ID = c("D001", "D001"), Name = c("a", "b"), stringsAsFactors = FALSE),  # dup ID
    goods_benefits = data.frame(ID = "GB001", Name = "x", stringsAsFactors = FALSE)
  )))
  out <- normalize_and_reconcile_project(proj)
  d <- out$data$isa_data$drivers
  expect_true("ID" %in% names(d))          # uppercase ID restored (not lowercase id)
  expect_equal(anyDuplicated(d$ID), 0)     # duplicate repaired
  expect_equal(nrow(d), 2)                 # rows preserved
})

test_that("normalize_and_reconcile_project leaves a NULL/empty project unchanged", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  expect_null(normalize_and_reconcile_project(NULL))
})

# ============================================================================
# Additional coverage
# ============================================================================

test_that("normalize_and_reconcile_project handles a non-list project unchanged", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  result <- normalize_and_reconcile_project("not_a_list")
  expect_equal(result, "not_a_list")
})

test_that("normalize_and_reconcile_project reconciles all 6 element frames", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  isa <- list(
    goods_benefits     = data.frame(ID = c("GB001", "GB001"), Name = c("g1", "g2"), stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = c("ES001", "ES001"), Name = c("e1", "e2"), stringsAsFactors = FALSE),
    marine_processes   = data.frame(ID = c("MPF001", "MPF001"), Name = c("m1", "m2"), stringsAsFactors = FALSE),
    pressures          = data.frame(ID = c("P001", "P001"), Name = c("p1", "p2"), stringsAsFactors = FALSE),
    activities         = data.frame(ID = c("A001", "A001"), Name = c("a1", "a2"), stringsAsFactors = FALSE),
    drivers            = data.frame(ID = c("D001", "D001"), Name = c("d1", "d2"), stringsAsFactors = FALSE)
  )
  proj <- list(data = list(isa_data = isa))
  out <- normalize_and_reconcile_project(proj)
  for (k in c("goods_benefits", "ecosystem_services", "marine_processes",
               "pressures", "activities", "drivers")) {
    df <- out$data$isa_data[[k]]
    expect_equal(anyDuplicated(df$ID), 0,
                 info = paste("duplicates found in", k))
    expect_equal(nrow(df), 2,
                 info = paste("row count changed in", k))
    expect_true("ID" %in% names(df),
                info = paste("ID column missing in", k))
  }
})

test_that("normalize_and_reconcile_project leaves adjacency matrices and metadata intact", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  mat <- matrix("+", 1, 1, dimnames = list("ES001", "GB001"))
  proj <- list(
    project_name = "Test",
    data = list(
      metadata = list(da_site = "site_a"),
      isa_data = list(
        drivers = data.frame(ID = "D001", Name = "x", stringsAsFactors = FALSE),
        adjacency_matrices = list(es_gb = mat)
      )
    )
  )
  out <- normalize_and_reconcile_project(proj)
  expect_equal(out$project_name, "Test")
  expect_equal(out$data$metadata$da_site, "site_a")
  # matrix is preserved as-is
  expect_equal(out$data$isa_data$adjacency_matrices$es_gb, mat)
})

test_that("normalize_and_reconcile_project skips empty/NULL element frames without error", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  # Use NULL for empty frame (0-row frames without an indicator column would
  # trigger a pre-existing NA_character_ assignment bug in normalize_json_project_data
  # which is outside the scope of this helper). NULL is the natural representation
  # for "no elements loaded yet" and is gracefully skipped by reconcile.
  proj <- list(data = list(isa_data = list(
    drivers            = NULL,
    goods_benefits     = NULL,
    ecosystem_services = data.frame(ID = "ES001", Name = "e1", stringsAsFactors = FALSE)
  )))
  expect_no_error(normalize_and_reconcile_project(proj))
  out <- normalize_and_reconcile_project(proj)
  expect_equal(nrow(out$data$isa_data$ecosystem_services), 1)
})

test_that("normalize_and_reconcile_project normalizes lowercase id column to uppercase ID", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  # Simulate what happens after normalize_json_project_data runs (id is lowercased)
  proj <- list(data = list(isa_data = list(
    activities = data.frame(id = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                             stringsAsFactors = FALSE)
  )))
  out <- normalize_and_reconcile_project(proj)
  act <- out$data$isa_data$activities
  expect_true("ID" %in% names(act))
  expect_false("id" %in% names(act))
})

test_that("normalize_and_reconcile_project handles a 0-row element frame without crashing (normalize indicator guard)", {
  skip_if_not(exists("normalize_and_reconcile_project", mode = "function"))
  proj <- list(data = list(isa_data = list(
    drivers = data.frame(id = character(0), name = character(0), stringsAsFactors = FALSE),
    goods_benefits = data.frame(ID = "GB001", Name = "x", stringsAsFactors = FALSE)
  )))
  expect_error(out <- normalize_and_reconcile_project(proj), NA)   # must not error on 0-row frame
  expect_equal(nrow(out$data$isa_data$drivers), 0)
})
