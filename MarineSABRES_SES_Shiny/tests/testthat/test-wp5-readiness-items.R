# tests/testthat/test-wp5-readiness-items.R
# WS-9b (spec 2026-10-17 §3): schema of the D5.4 readiness item bank.
library(testthat)
bank <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_readiness_items.json"), simplifyVector = FALSE)
ids <- vapply(bank$items, `[[`, "", "id")

test_that("item ids, kinds and scales", {
  expect_equal(ids, c("q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q13", "q15", "q16", "q17", "q18", "q19",
                      "q35", "q36", "q37", "q38", "q39"))
  kinds <- vapply(bank$items, `[[`, "", "kind")
  expect_equal(ids[kinds == "state"], c("q3", "q4", "q6", "q10", "q13", "q15", "q16", "q17", "q18", "q19"))
  expect_equal(ids[kinds == "attitude"], c("q5", "q7", "q8", "q9"))
  expect_equal(ids[kinds == "priority"], c("q35", "q36", "q37", "q38", "q39"))
  for (it in bank$items) expect_true(it$scale %in% names(bank$scales), info = it$id)
  expect_equal(vapply(Filter(function(it) isTRUE(it$reverse), bank$items), `[[`, "", "id"), c("q10", "q13"))
})

test_that("dimensions: NPG_DIMENSIONS, q39 none, cross_sectoral has no state item, knowledge one", {
  for (it in bank$items) {
    if (identical(it$id, "q39")) expect_null(it$dimension) else expect_true(it$dimension %in% NPG_DIMENSIONS, info = it$id)
  }
  st <- Filter(function(it) identical(it$kind, "state"), bank$items)
  dims <- vapply(st, `[[`, "", "dimension")
  expect_false("cross_sectoral" %in% dims)
  expect_equal(sum(dims == "knowledge"), 1L)
})

test_that("scales: codes and points as decided (D6)", {
  pts <- function(s) unlist(lapply(bank$scales[[s]]$points, function(p) if (is.null(p)) NA else p))
  expect_equal(unlist(bank$scales$agree7$codes),
               c("completely_agree", "agree", "neither", "disagree", "completely_disagree", "dont_know", "prefer_not"))
  expect_equal(pts("agree7"), c(2, 1, 0, -1, -2, NA, NA))
  expect_equal(pts("yes_no"), c(1, -1))
  expect_equal(pts("yes_no_sometimes"), c(1, 0, -1))
  expect_equal(pts("extent5"), c(-2, -1, 0, 1, 2))
  expect_equal(unlist(bank$scales$rank5$codes), as.character(1:5))
  expect_equal(unlist(bank$roles), c("government", "manager", "researcher", "tourism_operator", "fishers",
                                     "civil_society", "industry", "general_public", "other", "prefer_not"))
})

test_that("every item has text and a D5.4 source", {
  for (it in bank$items) {
    expect_true(nzchar(it$text_en), info = it$id)
    expect_match(it$source_ref, "^D5\\.4 Annex [57] Q[0-9]+, p\\. [0-9]+$", info = it$id)
  }
})
