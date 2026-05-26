# tests/testthat/test-matrix-from-linked.R
# Unit tests for the pure helpers in functions/matrix_from_linked.R
library(testthat)

td <- getwd()
root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
src_path <- file.path(root, "functions", "matrix_from_linked.R")
if (file.exists(src_path)) source(src_path)

# ---- parse_linked ----------------------------------------------------------

test_that("parse_linked returns character(0) for NULL/NA/empty", {
  expect_equal(parse_linked(NULL), character(0))
  expect_equal(parse_linked(NA), character(0))
  expect_equal(parse_linked(""), character(0))
})

test_that("parse_linked returns single ID for length-1 input (backward compat)", {
  expect_equal(parse_linked("GB001"), "GB001")
})

test_that("parse_linked splits '|'-delimited string", {
  expect_equal(parse_linked("GB001|GB002|GB003"), c("GB001", "GB002", "GB003"))
})

test_that("parse_linked drops empty segments from malformed input", {
  expect_equal(parse_linked("GB001||GB002"), c("GB001", "GB002"))
  expect_equal(parse_linked("|GB001|"), "GB001")
})

# ---- serialize_linked ------------------------------------------------------

test_that("serialize_linked returns '' for empty/NULL input", {
  expect_equal(serialize_linked(NULL), "")
  expect_equal(serialize_linked(character(0)), "")
})

test_that("serialize_linked returns single ID unchanged (length-1 backward compat)", {
  expect_equal(serialize_linked("GB001"), "GB001")
})

test_that("serialize_linked joins with '|' delimiter", {
  expect_equal(serialize_linked(c("GB001", "GB002")), "GB001|GB002")
})

test_that("serialize_linked drops empty-string elements before joining", {
  expect_equal(serialize_linked(c("GB001", "", "GB002")), "GB001|GB002")
})

test_that("serialize_linked + parse_linked roundtrip preserves IDs", {
  ids <- c("GB001", "GB003", "GB007")
  expect_equal(parse_linked(serialize_linked(ids)), ids)
})

# ---- assert_matrices_aligned ----------------------------------------------

test_that("assert_matrices_aligned passes for NULL inputs", {
  expect_silent(assert_matrices_aligned(NULL, NULL))
  expect_silent(assert_matrices_aligned(matrix(1, 1, 1), NULL))
  expect_silent(assert_matrices_aligned(NULL, matrix(TRUE, 1, 1)))
})

test_that("assert_matrices_aligned passes for matching dims+dimnames", {
  adj <- matrix("", 2, 2, dimnames = list(c("A","B"), c("X","Y")))
  edited <- matrix(FALSE, 2, 2, dimnames = list(c("A","B"), c("X","Y")))
  expect_silent(assert_matrices_aligned(adj, edited))
})

test_that("assert_matrices_aligned throws on dim mismatch", {
  adj <- matrix("", 2, 2)
  edited <- matrix(FALSE, 3, 2)
  expect_error(assert_matrices_aligned(adj, edited), "dim")
})

# ---- rebuild_matrix_from_linked -------------------------------------------

make_es_df <- function(ids, linked, confidence = "Medium") {
  data.frame(
    ID = ids,
    Name = paste0("ES_", ids),
    LinkedGB = linked,
    Confidence = rep(confidence, length(ids)),
    stringsAsFactors = FALSE
  )
}

test_that("rebuild returns list with matrix + user_edited", {
  es_df <- make_es_df("ES001", "")
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = "GB001"
  )
  expect_named(out, c("matrix", "user_edited", "stale_linked_ids", "dropped_user_edits"),
               ignore.order = TRUE)
})

test_that("empty LinkedGB produces all-empty matrix; no stale; no dropped", {
  es_df <- make_es_df("ES001", "")
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001", "GB002")
  )
  expect_true(all(out$matrix == ""))
  expect_equal(length(out$stale_linked_ids), 0)
  expect_equal(length(out$dropped_user_edits), 0)
})

test_that("single-value LinkedGB sets one cell '+Medium:<Confidence>'", {
  es_df <- make_es_df("ES001", "GB001", confidence = "High")
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001", "GB002")
  )
  expect_equal(out$matrix["ES001", "GB001"], "+Medium:High")
  expect_equal(out$matrix["ES001", "GB002"], "")
})

test_that("multi-value 'GB001|GB002' sets two cells", {
  es_df <- make_es_df("ES001", "GB001|GB002")
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001", "GB002")
  )
  expect_equal(out$matrix["ES001", "GB001"], "+Medium:Medium")
  expect_equal(out$matrix["ES001", "GB002"], "+Medium:Medium")
})

test_that("user_edited cell with existing value is PRESERVED", {
  es_df <- make_es_df("ES001", "GB001")
  existing <- matrix("", 1, 2, dimnames = list("ES001", c("GB001","GB002")))
  existing["ES001","GB001"] <- "-High:Low"
  user_edited <- matrix(FALSE, 1, 2, dimnames = list("ES001", c("GB001","GB002")))
  user_edited["ES001","GB001"] <- TRUE
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001","GB002"),
    existing_matrix = existing, user_edited_matrix = user_edited
  )
  expect_equal(out$matrix["ES001","GB001"], "-High:Low")
})

test_that("cell removed from LinkedGB is CLEARED when not user_edited", {
  es_df <- make_es_df("ES001", "GB001")  # GB002 removed
  existing <- matrix("+Medium:Medium", 1, 2,
                     dimnames = list("ES001", c("GB001","GB002")))
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001","GB002"),
    existing_matrix = existing
  )
  expect_equal(out$matrix["ES001","GB001"], "+Medium:Medium")
  expect_equal(out$matrix["ES001","GB002"], "")
})

test_that("cell removed from LinkedGB but user_edited is PRESERVED", {
  es_df <- make_es_df("ES001", "GB001")
  existing <- matrix("", 1, 2, dimnames = list("ES001", c("GB001","GB002")))
  existing["ES001","GB002"] <- "-Low:Medium"
  user_edited <- matrix(FALSE, 1, 2, dimnames = list("ES001", c("GB001","GB002")))
  user_edited["ES001","GB002"] <- TRUE
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001","GB002"),
    existing_matrix = existing, user_edited_matrix = user_edited
  )
  expect_equal(out$matrix["ES001","GB002"], "-Low:Medium")
})

test_that("missing confidence column defaults to 'Medium' WITHOUT silent corruption", {
  es_df <- data.frame(ID = "ES001", Name = "Fish", LinkedGB = "GB001",
                      stringsAsFactors = FALSE)  # NO Confidence column
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = "GB001"
  )
  expect_equal(out$matrix["ES001","GB001"], "+Medium:Medium")
})

test_that("stale linked ID is surfaced in stale_linked_ids attribute", {
  es_df <- make_es_df("ES001", "GB001|GB999")  # GB999 doesn't exist
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = c("GB001","GB002")
  )
  expect_equal(out$matrix["ES001","GB001"], "+Medium:Medium")
  expect_true("GB999" %in% out$stale_linked_ids,
              info = "stale IDs must be surfaced so caller can warn user")
})

test_that("dropped user-edited cell (element removed) is surfaced", {
  es_df <- make_es_df("ES001", "GB001")
  existing <- matrix("+High:High", 2, 1,
                     dimnames = list(c("ES001","ES002"), "GB001"))
  user_edited <- matrix(c(FALSE, TRUE), 2, 1,
                        dimnames = list(c("ES001","ES002"), "GB001"))
  # Caller now only passes ES001 as source (ES002 deleted)
  out <- rebuild_matrix_from_linked(
    element_df = es_df, linked_col = "LinkedGB",
    source_ids = "ES001", target_ids = "GB001",
    existing_matrix = existing, user_edited_matrix = user_edited
  )
  expect_true(any(grepl("ES002", out$dropped_user_edits)),
              info = "dropping a row that had user_edited cells must be surfaced")
})
