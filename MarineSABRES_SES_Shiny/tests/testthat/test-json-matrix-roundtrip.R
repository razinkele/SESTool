# tests/testthat/test-json-matrix-roundtrip.R
# Review 2026-10-07 N4 (+ the language-switch path found while fixing it):
# a project serialised with jsonlite came back with matrices as nested lists
# (local storage, language switch) or as dimname-less matrices (.json load);
# the language-switch restore also left element tables as plain lists.
source_for_test(c("functions/data_structure.R", "functions/utils.R",
                  "functions/matrix_from_linked.R", "functions/standard_entry_excel_import.R"))

fixture <- function() {
  pd <- create_empty_project("T")
  pd$data$isa_data$drivers <- data.frame(ID = c("D001", "D002"), Name = c("Demand", "Policy"),
                                         LinkedA = c("A001", ""), stringsAsFactors = FALSE)
  pd$data$isa_data$activities <- data.frame(ID = "A001", Name = "Fishing", stringsAsFactors = FALSE)
  pd$data$isa_data$adjacency_matrices <- list(
    d_a = matrix(c("+strong:4", ""), 2, 1, dimnames = list(c("D001", "D002"), "A001")))
  pd$data$isa_data$user_edited_matrices <- list(
    d_a = matrix(c(TRUE, FALSE), 2, 1, dimnames = list(c("D001", "D002"), "A001")))
  pd
}
to_json <- function(pd, sidecar = TRUE) {
  as.character(jsonlite::toJSON(if (sidecar) with_matrix_dimnames_sidecar(pd) else pd,
                                auto_unbox = TRUE, null = "null", na = "null"))
}
check_isa <- function(isa) {
  m <- isa$adjacency_matrices$d_a; u <- isa$user_edited_matrices$d_a
  expect_true(is.matrix(m)); expect_true(is.matrix(u))
  expect_equal(dimnames(m), list(c("D001", "D002"), "A001"))
  expect_equal(m["D001", "A001"], "+strong:4")
  expect_equal(m["D002", "A001"], "")
  expect_true(is.logical(u)); expect_true(u["D001", "A001"]); expect_false(u["D002", "A001"])
  expect_null(isa$matrix_dimnames)                        # sidecar consumed
}

test_that("N4: local-storage path (simplifyVector = FALSE + normalise) keeps real matrices", {
  isa <- normalize_json_project_data(safe_parse_json(to_json(fixture())))$data$isa_data
  check_isa(isa)
})

test_that("N4: .json project load (simplifyVector = TRUE + normalise) keeps dimnames and flags", {
  isa <- normalize_json_project_data(jsonlite::fromJSON(to_json(fixture()), simplifyVector = TRUE))$data$isa_data
  check_isa(isa)
})

test_that("language-switch restore returns data-frame elements and real matrices", {
  pd <- restore_project_from_json_text(to_json(fixture()))
  expect_false(is.null(pd))
  expect_true(is.data.frame(pd$data$isa_data$drivers))
  expect_equal(nrow(pd$data$isa_data$drivers), 2)
  check_isa(pd$data$isa_data)
  expect_null(restore_project_from_json_text("{not json"))
})

test_that("N4: older files without the sidecar fall back to the element ID order", {
  for (parse in list(function(j) safe_parse_json(j), function(j) jsonlite::fromJSON(j, simplifyVector = TRUE))) {
    isa <- normalize_json_project_data(parse(to_json(fixture(), sidecar = FALSE)))$data$isa_data
    check_isa(isa)
  }
})

test_that("N4: the sidecar wins when matrix order differs from element order", {
  pd <- fixture()
  pd$data$isa_data$drivers <- pd$data$isa_data$drivers[2:1, ]       # elements now D002, D001
  isa <- normalize_json_project_data(safe_parse_json(to_json(pd)))$data$isa_data
  expect_equal(rownames(isa$adjacency_matrices$d_a), c("D001", "D002"))
  expect_equal(isa$adjacency_matrices$d_a["D001", "A001"], "+strong:4")
})

test_that("N4: a matrix that cannot be placed on the elements is dropped, not mis-wired", {
  pd <- fixture()
  pd$data$isa_data$drivers <- pd$data$isa_data$drivers[1, , drop = FALSE]   # 1 driver, 2-row matrix
  isa <- normalize_json_project_data(safe_parse_json(to_json(pd, sidecar = FALSE)))$data$isa_data
  expect_null(isa$adjacency_matrices$d_a)
})

test_that("N4: recover_isa_data's Linked* fallback works on lowercased (normalised) columns", {
  pd <- fixture()
  pd$data$isa_data$adjacency_matrices <- list()          # force the name-based fallback
  pd$data$isa_data$user_edited_matrices <- list()
  isa <- normalize_json_project_data(safe_parse_json(to_json(pd)))$data$isa_data
  expect_true("linkeda" %in% names(isa$drivers))       # columns are lowercase after normalise
  rec <- recover_isa_data(isa, new_stable_id_store())
  expect_true(is.matrix(rec$adjacency_matrices$d_a))
  expect_true(nzchar(rec$adjacency_matrices$d_a["D001", "A001"]))
})

test_that(".json_to_matrix handles empty and ragged input", {
  expect_equal(dim(.json_to_matrix(list())), c(0L, 0L))
  expect_null(.json_to_matrix(list(list("a", "b"), list("c"))))
  expect_equal(.json_to_matrix(list(list("a", NULL), list(NA, "d"))), matrix(c("a", "", "", "d"), 2, byrow = TRUE))
})
