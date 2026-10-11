# tests/testthat/test-wp5-intervention-ops.R
# WS-1: D5.3 intervention -> SES-graph-change table (audit C§1.2-1.4, C§2.3).
library(testthat)

.root <- function() { wd <- getwd(); if (basename(wd) == "testthat") dirname(dirname(wd)) else wd }
OPS_PATH <- file.path(.root(), "data", "wp5_intervention_ops.json")

test_that("table loads: 23 master rows + 7 T5.4 governance rows", {
  db <- load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  expect_false(is.null(db))
  src <- vapply(db$interventions, `[[`, "", "source")
  expect_equal(sum(src == "master"), 23L)
  expect_equal(sum(src == "T5.4"), 7L)
})

test_that("every row is valid: group, ops, ebm_code, provenance", {
  db <- load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  valid_codes <- c(EBM_POLICY_INSTRUMENTS$code, EBM_MANAGEMENT_MEASURES$code)
  for (r in db$interventions) {
    expect_true(r$group %in% c("behavioural", "management", "economic", "governance"), info = r$id)
    expect_true(all(unlist(r$ops_xlsx) %in% GRAPH_EDIT_OPS), info = r$id)
    expect_true(all(unlist(r$ops_ebm) %in% GRAPH_EDIT_OPS), info = r$id)
    expect_true(all(unlist(r$ebm_code) %in% valid_codes), info = r$id)
    expect_true(r$provenance %in% c("wp5_source", "wp5_derived", "toolbox_extension", "provisional"))
    expect_true(nzchar(r$source_ref %||% ""), info = r$id)
    if (length(unlist(r$ebm_code)) > 0) expect_equal(r$ebm_code_provenance, "provisional", info = r$id)
  }
  ids <- vapply(db$interventions, `[[`, "", "id")
  expect_false(anyDuplicated(ids) > 0)
})

test_that("allowed ops = union of xlsx and EBM, tagged by source", {
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  nudge <- get_allowed_graph_ops("nudge")
  expect_setequal(nudge$op, c("reweight_edge", "new_edge"))
  expect_equal(nudge$source[nudge$op == "new_edge"], "ebm")
  expect_true("xlsx" %in% strsplit(nudge$source[nudge$op == "reweight_edge"], "+", fixed = TRUE)[[1]])
  mpa <- get_allowed_graph_ops("mpa_oecm")
  expect_setequal(mpa$op, GRAPH_EDIT_OPS)
})

test_that("unknown id returns empty frame; unknown context falls back to master", {
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)
  expect_equal(nrow(get_allowed_graph_ops("does_not_exist")), 0L)
  expect_equal(get_allowed_graph_ops("nudge", context = "atlantis"), get_allowed_graph_ops("nudge"))
})

test_that("missing or corrupt file: warning + empty results, no error", {
  expect_warning(res <- load_wp5_intervention_ops(file.path(tempdir(), "nope.json"), force_reload = TRUE))
  expect_null(res)
  expect_equal(nrow(get_allowed_graph_ops("nudge")), 0L)
  bad <- tempfile(fileext = ".json"); writeLines("{not json", bad)
  expect_warning(load_wp5_intervention_ops(bad, force_reload = TRUE))
  expect_equal(nrow(get_intervention_types()), 0L)
  load_wp5_intervention_ops(OPS_PATH, force_reload = TRUE)   # restore for later tests
})
