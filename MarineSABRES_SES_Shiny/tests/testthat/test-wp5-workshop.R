# tests/testthat/test-wp5-workshop.R
# WS-10 (spec 2026-10-18): workshop elicitation — storage, summaries, write-back, import/export.
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "functions/wp5_workshop.R"))

test_that("guiding questions: 11, in EBM_TENETS order, non-empty English text", {
  qs <- load_wp5_tenet_questions(force_reload = TRUE)
  expect_false(is.null(qs))
  expect_equal(vapply(qs$questions, `[[`, "", "tenet"), EBM_TENETS$code)
  expect_true(all(nzchar(vapply(EBM_TENETS$code, function(t) wp5_tenet_question(qs, t), ""))))
  expect_equal(wp5_tenet_question(qs, "not_a_tenet"), "")
  expect_equal(unlist(qs$scale), c("completely_disagree", "disagree", "neutral", "agree", "completely_agree"))
})

test_that("a missing file gives NULL, not an error", {
  expect_null(load_wp5_tenet_questions(path = tempfile(fileext = ".json")))
})
