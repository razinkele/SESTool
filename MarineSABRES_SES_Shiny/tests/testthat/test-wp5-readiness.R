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

# ---- Task 4: import / template / export --------------------------------------
tr <- readiness_translations()

test_that("import: codes and labels in any language; bad values blanked; other columns ignored", {
  es_agree <- tr[["modules.wp5_readiness.answer.agree"]]$es
  lt_fishers <- tr[["modules.wp5_readiness.role.fishers"]]$lt
  df <- data.frame(Name = c("Ana", "Bo"), role = c(lt_fishers, "manager"), q6 = c("agree", toupper(es_agree)),
                   q16 = c("Sometimes", "maybe"), q35 = c(1, 2), Comment = c("x", "y"), stringsAsFactors = FALSE)
  p <- readiness_parse_import(df, bank, tr)
  expect_true(p$ok)
  expect_equal(p$rows$Role, c("fishers", "manager"))
  expect_equal(p$rows$q6, c("agree", "agree"))
  expect_equal(p$rows$q16, c("sometimes", ""))
  expect_equal(p$rows$q35, c("1", "2"))
  expect_equal(p$blanked, 1L)
  expect_setequal(p$ignored, c("name", "comment"))
  expect_false(any(c("name", "comment", "Name") %in% names(p$rows)))
})

test_that("import ignores Latin accents (Si / Sí)", {
  fake <- list("modules.wp5_readiness.answer.yes" = list(en = "Yes", es = "S\u00ed"),
               "modules.wp5_readiness.answer.no" = list(en = "No"))
  p <- readiness_parse_import(data.frame(q3 = c("si", "S\u00cd"), stringsAsFactors = FALSE), bank, fake)
  expect_equal(p$rows$q3, c("yes", "yes"))
  expect_equal(p$blanked, 0L)
})

test_that("import: a label meaning different codes in different languages is unreadable", {
  fake <- list("modules.wp5_readiness.answer.yes" = list(en = "Yes", xx = "Si"),
               "modules.wp5_readiness.answer.no" = list(en = "No", yy = "Si"))
  p <- readiness_parse_import(data.frame(q3 = c("si", "yes"), q6 = c("agree", "agree"), stringsAsFactors = FALSE), bank, fake)
  expect_equal(p$rows$q3, c("", "yes"))
  expect_equal(p$blanked, 1L)
})

test_that("import: all-blank file adds nothing (review focus 2); no item columns and too many rows refused", {
  p <- readiness_parse_import(data.frame(q6 = c("", NA), role = c(NA, ""), stringsAsFactors = FALSE), bank, tr)
  expect_true(p$ok)
  expect_equal(nrow(p$rows), 0L)
  expect_equal(p$dropped_empty, 2L)
  e <- readiness_parse_import(data.frame(name = "x"), bank, tr)
  expect_false(e$ok); expect_equal(e$error, "no_item_columns"); expect_true("q6" %in% e$expected)
  big <- data.frame(q6 = rep("agree", 1001), stringsAsFactors = FALSE)
  expect_equal(readiness_parse_import(big, bank, tr)$error, "too_many_rows")
})

test_that("template round trip: download, fill, read back, parse", {
  wb <- readiness_template_wb(bank, make_test_i18n())
  expect_equal(openxlsx::sheets(wb), c("answers", "items", "roles"))
  row <- stats::setNames(as.list(rep("", length(ids) + 1)), c("role", ids))   # same column order as the header
  row[c("role", "q6", "q19")] <- list("researcher", "completely_agree", "Disagree")
  openxlsx::writeData(wb, "answers", as.data.frame(row, stringsAsFactors = FALSE), startRow = 2, colNames = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  df <- readiness_read_file(f, "filled.xlsx")
  p <- readiness_parse_import(df, bank, tr)
  expect_equal(nrow(p$rows), 1L)
  expect_equal(c(p$rows$Role, p$rows$q6), c("researcher", "completely_agree"))
  csv <- tempfile(fileext = ".csv"); utils::write.csv(data.frame(q6 = "agree"), csv, row.names = FALSE)
  expect_equal(readiness_read_file(csv, "a.csv")$q6, "agree")
  expect_error(readiness_read_file(csv, "a.txt"))
})

test_that("export workbook has answers, indicator and priorities", {
  rd <- readiness_append(NULL, fix(rows_of(list(q6 = "agree", q35 = "2"))), "form", bank)
  wb <- readiness_export_wb(rd, bank, make_test_i18n())
  expect_equal(openxlsx::sheets(wb), c("about", "answers", "indicator", "priorities"))
})

test_that("role cells resting on fewer than 5 respondents are hidden (final review)", {
  rows <- c(rep(list(list(Role = "fishers", q6 = "agree")), 4), list(list(Role = "fishers", q6 = "agree", q19 = "agree")))
  rb <- readiness_role_breakdown(fix(do.call(rows_of, rows)), bank)
  d6 <- bank$items[[which(readiness_item_ids(bank) == "q6")]]$dimension
  d19 <- bank$items[[which(readiness_item_ids(bank) == "q19")]]$dimension
  skip_if(identical(d6, d19))
  expect_false(is.na(rb$score[rb$dimension == d6]))
  expect_true(is.na(rb$score[rb$dimension == d19]))
})

test_that("semicolon-separated csv is read with sep ';' (final review)", {
  f <- tempfile(fileext = ".csv"); writeLines(c("role;q6", "manager;agree"), f)
  df <- readiness_read_file(f, "a.csv")
  expect_equal(names(df), c("role", "q6"))
  p <- readiness_parse_import(df, bank, readiness_translations())
  expect_equal(c(p$rows$Role, p$rows$q6), c("manager", "agree"))
})

test_that("respondent ids are never reused after a delete; counter survives JSON (final review)", {
  rd <- readiness_append(NULL, fix(rows_of(list(q6 = "agree"), list(q6 = "agree"), list(q6 = "agree"))), "form", bank)
  expect_equal(rd$counter, 3L)
  rd <- readiness_delete(rd, "R003", bank)
  expect_equal(rd$counter, 3L)
  rd <- readiness_append(rd, fix(rows_of(list(q6 = "agree"))), "form", bank)
  expect_equal(rd$respondents$RespondentId, c("R001", "R002", "R004"))
  rt <- normalize_readiness(jsonlite::fromJSON(jsonlite::toJSON(rd, auto_unbox = TRUE), simplifyVector = FALSE), bank)
  expect_equal(rt$counter, 4L)
  legacy <- normalize_readiness(list(respondents = rd$respondents), bank)
  expect_equal(legacy$counter, 4L)
  expect_equal(create_empty_project("t")$data$pims$readiness$counter, 0)
})

# ---- PR 114 review: privacy and ranking integrity ----------------------------

test_that("normalize drops non-item columns (Name/Email) and the export has no Name column", {
  rd <- normalize_readiness(list(respondents = list(list(RespondentId = "R001", Name = "Ana", Email = "a@b",
                                                         q6 = "agree", q99 = "yes"))), bank)
  r <- rd$respondents
  expect_false(any(c("Name", "Email") %in% names(r)))
  expect_equal(c(r$q6, r$q99), c("agree", "yes"))
  wb <- readiness_export_wb(list(respondents = list(list(RespondentId = "R001", Name = "Ana", q6 = "agree"))),
                            bank, make_test_i18n())
  ans <- openxlsx::read.xlsx(wb, "answers")
  expect_false("Name" %in% names(ans))
  expect_true("q6" %in% names(ans))
})

test_that("readiness_rank_conflict: distinct FALSE, repeated TRUE, blanks ignored", {
  df <- rows_of(list(q35 = "1", q36 = "2", q37 = "3"), list(q35 = "1", q36 = "1"),
                list(q35 = "2", q36 = "", q37 = "", q38 = "2"), list(q6 = "agree"))
  expect_equal(readiness_rank_conflict(df, bank), c(FALSE, TRUE, TRUE, FALSE))
  expect_false(readiness_rank_conflict(list(q35 = "1", q36 = ""), bank))
  expect_true(readiness_rank_conflict(list(q35 = "4", q39 = "4"), bank))
})

test_that("import blanks the ranking of a respondent with repeated ranks, keeps other answers", {
  df <- data.frame(q35 = c("1", "1"), q36 = c("1", "2"), q6 = c("agree", "agree"), stringsAsFactors = FALSE)
  p <- readiness_parse_import(df, bank, list())
  expect_equal(p$rank_conflicts, 1L)
  expect_equal(c(p$rows$q35[1], p$rows$q36[1], p$rows$q6[1]), c("", "", "agree"))
  expect_equal(c(p$rows$q35[2], p$rows$q36[2]), c("1", "2"))
  expect_equal(p$blanked, 0L)
})
