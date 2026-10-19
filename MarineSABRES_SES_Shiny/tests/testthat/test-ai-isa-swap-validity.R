# test-ai-isa-swap-validity.R
# "Swap direction" in AI-assistant connection review stored the reversed link
# under a reversed matrix name the diagram reads as the original direction (or
# not at all). Every link type the assistant proposes (D->A, A->P, ...) has an
# invalid reverse under the DAPSIWRM transition rules, so such a swap is now
# refused (the connection is left out and reported); a swap whose reverse is a
# forward link is applied to all fields and stored in that forward matrix.

library(testthat)

source_for_test("modules/ai_isa/data_persistence.R")

conn <- function(from_cat, to_cat, matrix, from_i = 1, to_i = 2, from = "X", to = "Y") {
  list(from = from, to = to, from_name = from, to_name = to,
       from_category = from_cat, to_category = to_cat, from_type = from_cat, to_type = to_cat,
       matrix = matrix, from_index = from_i, to_index = to_i, polarity = "+", strength = "medium")
}

test_that("a swap whose reverse is not a DAPSIWRM link is refused and left out", {
  conns <- list(conn("drivers", "activities", "d_a", from = "Food demand", to = "Trawling"),
                conn("activities", "pressures", "a_p"))
  out <- apply_connection_swaps(conns, approved = c(1L, 2L), swapped = 1L)
  expect_identical(out$approved, 2L)
  expect_identical(out$refused, "Food demand → Trawling")
  expect_identical(out$connections[[1]]$matrix, "d_a")          # untouched
})

test_that("a swap whose reverse is a forward link is applied to every field", {
  conns <- list(conn("activities", "drivers", "a_d", from_i = 2, to_i = 3, from = "Trawling", to = "Food demand"))
  out <- apply_connection_swaps(conns, approved = 1L, swapped = 1L)
  c1 <- out$connections[[1]]
  expect_identical(out$approved, 1L)
  expect_length(out$refused, 0)
  expect_identical(c1$matrix, "d_a")
  expect_identical(c(c1$from_category, c1$to_category), c("drivers", "activities"))
  expect_identical(c(c1$from_type, c1$to_type), c("drivers", "activities"))
  expect_equal(c(c1$from_index, c1$to_index), c(3, 2))
  expect_identical(c(c1$from, c1$to, c1$from_name, c1$to_name),
                   c("Food demand", "Trawling", "Food demand", "Trawling"))
})

test_that("swaps of connections that were not approved are ignored", {
  conns <- list(conn("drivers", "activities", "d_a"))
  out <- apply_connection_swaps(conns, approved = integer(0), swapped = 1L)
  expect_identical(out$connections, conns)
  expect_length(out$refused, 0)
})

test_that("every link type the assistant proposes has an invalid reverse", {
  # guards the reasoning above: if a reverse ever becomes a forward link, the
  # swap button is useful again and this test should be revisited
  rev_keys <- vapply(strsplit(names(AI_ISA_FORWARD_MATRIX), "_"), function(p) paste(p[2], p[1], sep = "_"), "")
  expect_false(any(rev_keys %in% names(AI_ISA_FORWARD_MATRIX)))
})
