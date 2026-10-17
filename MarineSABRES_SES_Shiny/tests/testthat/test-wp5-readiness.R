# tests/testthat/test-wp5-readiness.R
# WS-9b (spec 2026-10-17 §4-§5): storage, scoring, import/export of the readiness check.
library(testthat)
source_for_test("functions/wp5_readiness.R")
bank <- load_wp5_readiness_items(force_reload = TRUE)
ids <- readiness_item_ids(bank)
rows_of <- function(...) {                       # build answer rows: rows_of(list(q6 = "agree"), list(q6 = "disagree"))
  rs <- list(...)
  as.data.frame(do.call(rbind, lapply(rs, function(r) {
    full <- stats::setNames(as.list(rep("", length(ids) + 1)), c("Role", ids))
    full[names(r)] <- r
    full
  })), stringsAsFactors = FALSE)
}
fix <- function(df) { for (cl in names(df)) df[[cl]] <- as.character(unlist(df[[cl]])); df }

test_that("normalize: NULL, list rows from JSON, bad codes blanked, unknown item columns kept (review focus 3)", {
  e <- normalize_readiness(NULL, bank)
  expect_equal(nrow(e$respondents), 0L)
  expect_equal(names(e$respondents), c(READINESS_META_COLUMNS, ids))
  rd <- normalize_readiness(list(respondents = list(list(RespondentId = "R001", q6 = "agree", q4 = "bogus",
                                                         q99 = "yes", Role = "fishers"))), bank)
  r <- rd$respondents
  expect_equal(c(r$q6, r$q4, r$q99, r$Role), c("agree", "", "yes", "fishers"))
  without <- r[, setdiff(names(r), "q99"), drop = FALSE]
  expect_equal(readiness_score(r, bank), readiness_score(without, bank))   # the unknown item does not affect the score
})

test_that("points: scales, reverse, exclusions (D6)", {
  expect_equal(readiness_points(bank, "q6", c("completely_agree", "neither", "dont_know", "")), c(2, 0, NA, NA))
  expect_equal(readiness_points(bank, "q10", c("completely_agree", "disagree")), c(-2, 1))     # reversed
  expect_equal(readiness_points(bank, "q13", c("yes", "no")), c(-1, 1))                       # reversed yes/no
  expect_equal(readiness_points(bank, "q16", c("yes", "sometimes", "no")), c(1, 0, -1))
  expect_equal(readiness_points(bank, "q4", c("very_little", "very_much")), c(-2, 2))
})

test_that("score: state items only, coverage flags, counts", {
  r <- fix(rows_of(list(q6 = "completely_agree", q13 = "yes", q5 = "completely_disagree", q19 = "agree"),
                   list(q6 = "agree", q15 = "yes")))
  sc <- readiness_score(r, bank)
  expect_equal(sc$dimension, NPG_DIMENSIONS)
  vc <- sc[sc$dimension == "values_conflict", ]
  expect_equal(vc$score, mean(c(2, -1, 1, 1)))                  # q6 2, q13 yes -> -1, q6 1, q15 1; q5 (attitude) ignored
  expect_equal(c(vc$n_respondents, vc$n_answers, vc$n_items), c(2L, 4L, 5L))
  expect_equal(sc$coverage[sc$dimension == "cross_sectoral"], "none")
  expect_true(is.na(sc$score[sc$dimension == "cross_sectoral"]))
  expect_equal(sc$coverage[sc$dimension == "knowledge"], "low")
  expect_equal(sc$score[sc$dimension == "knowledge"], 1)
  expect_equal(sc$coverage[sc$dimension == "collaboration"], "ok")
})

test_that("a dimension answered only with don't know gives NA, not NaN (review focus 5)", {
  sc <- readiness_score(fix(rows_of(list(q19 = "dont_know"), list(q19 = "prefer_not"))), bank)
  k <- sc[sc$dimension == "knowledge", ]
  expect_true(is.na(k$score) && !is.nan(k$score))
  expect_equal(k$n_answers, 0L)
})

test_that("item counts, priority mean rank, role breakdown threshold", {
  r <- fix(rows_of(list(q5 = "agree", q35 = "1", q39 = "5"), list(q5 = "agree", q35 = "3")))
  ct <- readiness_item_counts(r, bank, "attitude")
  expect_equal(ct$n[ct$item == "q5" & ct$code == "agree"], 2L)
  pr <- readiness_priority(r, bank)
  expect_equal(pr$mean_rank[pr$item == "q35"], 2)
  expect_equal(pr$n[pr$item == "q39"], 1L)
  four <- fix(do.call(rows_of, rep(list(list(Role = "fishers", q6 = "agree")), 4)))
  expect_null(readiness_role_breakdown(four, bank))
  five <- fix(do.call(rows_of, rep(list(list(Role = "fishers", q6 = "agree")), 5)))
  rb <- readiness_role_breakdown(five, bank)
  expect_equal(unique(rb$role), "fishers")
})

test_that("append assigns R001.. and safe ids; delete leaves an empty table (review focus 4)", {
  rd <- readiness_append(NULL, fix(rows_of(list(q6 = "agree"))), "form", bank)
  rd <- readiness_append(rd, fix(rows_of(list(q6 = "disagree"), list(q19 = "agree"))), "import", bank)
  expect_equal(rd$respondents$RespondentId, c("R001", "R002", "R003"))
  expect_equal(rd$respondents$Source, c("form", "import", "import"))
  expect_true(readiness_has_respondents(rd))
  rd2 <- readiness_delete(rd, c("R002"), bank)
  rd3 <- readiness_append(rd2, fix(rows_of(list(q6 = "agree"))), "form", bank)
  expect_equal(rd3$respondents$RespondentId, c("R001", "R003", "R004"))
  empty <- readiness_delete(rd, rd$respondents$RespondentId, bank)
  expect_true(is.data.frame(empty$respondents))
  expect_equal(nrow(empty$respondents), 0L)
  expect_false(readiness_has_respondents(empty))
})

test_that("empty project and JSON load: empty table; respondents stamp 1.31.0", {
  p <- create_empty_project("t")
  expect_equal(nrow(p$data$pims$readiness$respondents), 0L)
  pd <- list(data = list(pims = list(readiness = list(respondents = list(list(RespondentId = "R001", q6 = "agree"))))))
  out <- normalize_json_project_data(pd)
  expect_equal(out$data$pims$readiness$respondents$q6, "agree")
  expect_equal(out$min_app_version, WP5_READINESS_MIN_APP_VERSION)
  none <- normalize_json_project_data(list(data = list(pims = list(readiness = list(respondents = list())))))
  expect_null(none$min_app_version)
})

test_that("a missing or corrupt item bank gives NULL", {
  expect_null(load_wp5_readiness_items(path = tempfile(fileext = ".json")))
  bad <- tempfile(fileext = ".json"); writeLines("{ nope", bad)
  expect_null(load_wp5_readiness_items(path = bad))
  expect_false(is.null(load_wp5_readiness_items()))
})
