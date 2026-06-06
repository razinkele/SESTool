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
