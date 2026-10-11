# tests/testthat/test-wp5-vocabulary.R
# WS-1: WP5 shared vocabulary. Codes are stored; labels resolve via i18n at render.
library(testthat)

test_that("criteria codes are the five D5.2 criteria; aliases resolve", {
  expect_equal(WP5_CRITERIA$code, c("EE", "EC", "EQ", "PI", "FF"))
  expect_equal(wp5_criterion_code(c("PI", "PO", "po", "FI", "ee")), c("PI", "PI", "PI", "FF", "EE"))
  expect_equal(wp5_criterion_code(c("XX", NA, "")), c(NA_character_, NA_character_, NA_character_))
})

test_that("rubric is ordinal D5.2 Phase-3 vocabulary (no numeric scales)", {
  expect_equal(WP5_RUBRIC$magnitude, c("incremental", "moderate", "substantial"))
  expect_equal(WP5_RUBRIC$direction, c("increase", "decrease", "no_change", "uncertain"))
  expect_equal(WP5_RUBRIC$timing, c("short", "medium", "long"))
  expect_equal(WP5_TIME_HORIZON_YEARS$long, c(8, 15))
  for (v in WP5_RUBRIC) expect_type(v, "character")
})

test_that("EBM instrument vocabulary matches the source (3.5 absent)", {
  types <- EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "type"]
  expect_equal(length(types), 20L)
  expect_false("3.5" %in% types)
  expect_true(all(c("1.1", "2.5", "3.7", "4.3") %in% types))
  expect_equal(EBM_POLICY_INSTRUMENTS$code[EBM_POLICY_INSTRUMENTS$level == "category"], c("1", "2", "3", "4"))
  expect_false(anyDuplicated(EBM_POLICY_INSTRUMENTS$code) > 0)
})

test_that("management measures carry a valid DAPSIWRM target", {
  expect_equal(nrow(EBM_MANAGEMENT_MEASURES), 12L)
  parts <- unlist(strsplit(EBM_MANAGEMENT_MEASURES$dapsiwrm_target, "|", fixed = TRUE))
  expect_true(all(parts %in% c("A", "P", "C")))
  expect_equal(EBM_MANAGEMENT_MEASURES$dapsiwrm_target[EBM_MANAGEMENT_MEASURES$code == "output"], "P")
})

test_that("tenets: 3 measure-level + 8 intervention-level = 11", {
  expect_equal(nrow(EBM_TENETS), 11L)
  expect_equal(sum(EBM_TENETS$scope == "measure"), 3L)
})

test_that("every vocabulary has unique codes", {
  for (v in c("criteria", "subdimension", "direction", "magnitude", "timing", "confidence",
              "evidence", "uncertainty_driver", "indicator_role", "pathway_segment",
              "instrument", "measure", "tenet", "npg", "graph_op")) {
    codes <- wp5_vocab_codes(v)
    expect_gt(length(codes), 0)
    expect_false(anyDuplicated(codes) > 0, info = v)
  }
  expect_error(wp5_vocab_codes("nope"), "Unknown WP5 vocabulary")
})

test_that("i18n keys use the modules.wp5_vocabulary namespace with dots->underscores", {
  expect_equal(wp5_vocab_key("instrument", "1.1"), "modules.wp5_vocabulary.instrument.1_1")
  expect_equal(wp5_vocab_key("measure", "spatial.year_round"),
               "modules.wp5_vocabulary.measure.spatial_year_round")
})

test_that("labels follow the active translator; stored codes never change", {
  en <- list(t = function(k) paste0("EN:", k))
  lt <- list(t = function(k) paste0("LT:", k))
  code <- "1.1"
  expect_equal(wp5_vocab_label("instrument", code, en), "EN:modules.wp5_vocabulary.instrument.1_1")
  expect_equal(wp5_vocab_label("instrument", code, lt), "LT:modules.wp5_vocabulary.instrument.1_1")
  expect_equal(code, "1.1")
})

test_that("labels for unknown/NA codes fall back to the code, never error", {
  idt <- list(t = function(k) k)   # shiny.i18n returns the key when missing
  expect_equal(wp5_vocab_label("instrument", c("9.9", NA), idt), c("9.9", ""))
  broken <- list(t = function(k) stop("boom"))
  expect_equal(wp5_vocab_label("instrument", "1.1", broken), "1.1")
})
