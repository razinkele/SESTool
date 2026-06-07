# tests/testthat/test-isa-responses-matrices.R
source_for_test("functions/matrix_from_linked.R")
source_for_test("functions/isa_form_builders.R")

# Minimal isa_data-like list: 2 G&B, 1 Response (LinkedGB->GB002, LinkedD->D001), 1 Driver.
make_resp_isa <- function() {
  list(
    goods_benefits = data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"),
                                stringsAsFactors = FALSE),
    drivers        = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
    activities     = data.frame(ID = character(), Name = character(), stringsAsFactors = FALSE),
    pressures      = data.frame(ID = character(), Name = character(), stringsAsFactors = FALSE),
    responses      = data.frame(ID = "R001", Name = "MSP",
                                LinkedGB = "GB002", LinkedD = "D001",
                                LinkedA = "", LinkedP = "", stringsAsFactors = FALSE),
    adjacency_matrices   = list(),
    user_edited_matrices = list()
  )
}

test_that("r_d is R x target with -medium:3 at the linked cell", {
  isa <- make_resp_isa()
  out <- build_response_matrices(isa)
  m <- out$adjacency_matrices$r_d
  expect_equal(dim(m), c(1L, 1L))
  expect_equal(rownames(m), "R001"); expect_equal(colnames(m), "D001")
  expect_equal(m["R001","D001"], "-medium:3")
})

test_that("gb_r is GB x R (transposed) with +medium:3 at [GB002,R001], not [GB001,R001]", {
  isa <- make_resp_isa()
  out <- build_response_matrices(isa)
  g <- out$adjacency_matrices$gb_r
  expect_equal(dim(g), c(2L, 1L))            # GB x R, not R x GB
  expect_equal(rownames(g), c("GB001","GB002"))
  expect_equal(colnames(g), "R001")
  expect_equal(g["GB002","R001"], "+medium:3")
  expect_equal(g["GB001","R001"], "")        # asymmetric: catches a transpose bug
})

test_that("re-save preserves a user-edited gb_r cell", {
  isa <- make_resp_isa()
  out1 <- build_response_matrices(isa)
  # Simulate an edit-edge-modal edit on the stored GB x R matrix:
  isa$adjacency_matrices   <- out1$adjacency_matrices
  isa$user_edited_matrices <- out1$user_edited_matrices
  isa$adjacency_matrices$gb_r["GB002","R001"]   <- "-strong:5"
  isa$user_edited_matrices$gb_r["GB002","R001"] <- TRUE
  out2 <- build_response_matrices(isa)
  expect_equal(out2$adjacency_matrices$gb_r["GB002","R001"], "-strong:5")
  expect_true(out2$user_edited_matrices$gb_r["GB002","R001"])  # flag survives transpose round-trip
})

test_that("empty responses yields no matrices (no error)", {
  isa <- make_resp_isa(); isa$responses <- isa$responses[0, , drop = FALSE]
  out <- build_response_matrices(isa)
  expect_null(out$adjacency_matrices$r_d)
  expect_null(out$adjacency_matrices$gb_r)
})

test_that("responses without an ID column returns matrices unchanged", {
  isa <- make_resp_isa(); isa$responses <- data.frame(Name = "x", stringsAsFactors = FALSE)
  out <- build_response_matrices(isa)
  expect_null(out$adjacency_matrices$r_d)
  expect_null(out$adjacency_matrices$gb_r)
})

test_that("rederive_linked_from_matrix scans rows for R x target matrices", {
  # r_d: R x D, edge R001 -> D002
  m <- matrix(c("", "-medium:3"), nrow = 1,
              dimnames = list("R001", c("D001","D002")))
  expect_equal(rederive_linked_from_matrix(m, "R001", "row"), "D002")
})

test_that("rederive_linked_from_matrix scans columns for gb_r (GB x R)", {
  # gb_r: GB x R, edge GB002 -> R001
  g <- matrix(c("", "+medium:3"), nrow = 2,
              dimnames = list(c("GB001","GB002"), "R001"))
  expect_equal(rederive_linked_from_matrix(g, "R001", "col"), "GB002")
})

test_that("rederive_linked_from_matrix returns '' when the element has no edges", {
  m <- matrix("", nrow = 1, ncol = 2, dimnames = list("R001", c("D001","D002")))
  expect_equal(rederive_linked_from_matrix(m, "R001", "row"), "")
})

test_that("isa_fields_r returns name/type/desc + four linked multi-selects", {
  i18n <- list(t = function(x) x)          # identity stub
  flds <- isa_fields_r(i18n, gb_choices = c("GB001"), d_choices = c("D001"),
                       a_choices = character(), p_choices = character())
  ids <- vapply(flds, function(f) f$id, character(1))
  expect_true(all(c("name","type","desc","linkedgb","linkedd","linkeda","linkedp") %in% ids))
  lg <- Filter(function(f) f$id == "linkedgb", flds)[[1]]
  expect_true(isTRUE(lg$multiple)); expect_equal(lg$type, "select")
})

test_that("build_response_panel_ui emits inputs suffixed by the panel id", {
  ns <- function(x) paste0("mod-", x)
  i18n <- list(t = function(x) x)
  flds <- isa_fields_r(i18n, "GB001", "D001", character(), character())
  ui <- build_response_panel_ui(ns, "R001", flds, i18n)
  html <- as.character(ui)
  expect_true(grepl("mod-r_name_R001", html, fixed = TRUE))
  expect_true(grepl("mod-r_linkedgb_R001", html, fixed = TRUE))
  expect_true(grepl("mod-r_linkedd_R001", html, fixed = TRUE))
})

test_that("create_isa_analysis_workbook includes Responses sheet + r_d matrix when present", {
  library(openxlsx)
  isa <- make_resp_isa()
  isa$adjacency_matrices <- build_response_matrices(isa)$adjacency_matrices
  wb <- create_isa_analysis_workbook(isa)
  sheets <- names(wb)
  expect_true("Responses_Measures" %in% sheets)
  expect_true("Matrix_r_d" %in% sheets)
})

test_that("build_kumu_elements includes response nodes when present", {
  # NB: the existing build_kumu_elements is not robust to empty categories, so
  # use a full 6-category fixture (its hardening is out of scope here).
  isa <- list(
    goods_benefits     = data.frame(ID = "GB001",  Name = "Food",    stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001",  Name = "Fish",    stringsAsFactors = FALSE),
    marine_processes   = data.frame(ID = "MPF001", Name = "Prod",    stringsAsFactors = FALSE),
    pressures          = data.frame(ID = "P001",   Name = "Fishing", stringsAsFactors = FALSE),
    activities         = data.frame(ID = "A001",   Name = "Trawl",   stringsAsFactors = FALSE),
    drivers            = data.frame(ID = "D001",   Name = "Demand",  stringsAsFactors = FALSE),
    responses          = data.frame(ID = "R001",   Name = "MSP",     stringsAsFactors = FALSE)
  )
  el <- build_kumu_elements(isa)
  expect_true("R001" %in% el$ID)
})

# --- apply_matrix_cell_edit: per-edge strength editing with user_edited persistence ---

ace_fixture <- function() {
  list(
    am = list(r_d = matrix("-medium:3", 1, 1, dimnames = list("R001", "D001"))),
    ue = list()
  )
}

test_that("apply_matrix_cell_edit writes a valid cell and flags user_edited", {
  f <- ace_fixture()
  out <- apply_matrix_cell_edit(f$am, f$ue, "r_d", 1, 1, "+strong:4")
  expect_null(out$error)
  expect_equal(out$am$r_d["R001","D001"], "+strong:4")
  expect_true(out$ue$r_d["R001","D001"])          # flag created + set
})

test_that("apply_matrix_cell_edit lowercases strength on accept", {
  f <- ace_fixture()
  out <- apply_matrix_cell_edit(f$am, f$ue, "r_d", 1, 1, "+STRONG:4")
  expect_equal(out$am$r_d["R001","D001"], "+strong:4")
})

test_that("apply_matrix_cell_edit rejects malformed values without writing", {
  f <- ace_fixture()
  out <- apply_matrix_cell_edit(f$am, f$ue, "r_d", 1, 1, "garbage")
  expect_false(is.null(out$error))
  expect_equal(out$am$r_d["R001","D001"], "-medium:3")   # unchanged
  expect_null(out$ue$r_d)                                  # no flag matrix created
})

test_that("apply_matrix_cell_edit empty value clears the cell but still flags user_edited", {
  f <- ace_fixture()
  out <- apply_matrix_cell_edit(f$am, f$ue, "r_d", 1, 1, "")
  expect_null(out$error)
  expect_equal(out$am$r_d["R001","D001"], "")
  expect_true(out$ue$r_d["R001","D001"])
})

test_that("apply_matrix_cell_edit errors on unknown key or out-of-range cell", {
  f <- ace_fixture()
  expect_false(is.null(apply_matrix_cell_edit(f$am, f$ue, "nope", 1, 1, "+strong:4")$error))
  expect_false(is.null(apply_matrix_cell_edit(f$am, f$ue, "r_d", 2, 1, "+strong:4")$error))
})

test_that("build_kumu_elements is robust to empty/missing categories", {
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    responses      = data.frame(ID = "R001", Name = "MSP", stringsAsFactors = FALSE)
    # ecosystem_services/marine_processes/pressures/activities/drivers all absent
  )
  el <- build_kumu_elements(isa)              # must not error
  expect_equal(sort(el$ID), c("GB001", "R001"))
  expect_true(all(c("Label","Type","ID") %in% names(el)))
})

test_that("build_kumu_elements returns an empty frame when no categories have rows", {
  el <- build_kumu_elements(list())
  expect_equal(nrow(el), 0L)
  expect_equal(names(el), c("Label","Type","ID"))
})
