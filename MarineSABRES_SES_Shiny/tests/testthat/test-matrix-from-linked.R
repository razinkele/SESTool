# tests/testthat/test-matrix-from-linked.R
source_for_test("functions/matrix_from_linked.R")

test_that("reconciler reports a row as dropped IFF it is absent from source_ids (correct contract)", {
  existing <- matrix("", 2, 1, dimnames = list(c("ES001", "ES002"), "GB001"))
  existing["ES002", "GB001"] <- "-High:High"
  edited <- matrix(FALSE, 2, 1, dimnames = list(c("ES001", "ES002"), "GB001"))
  edited["ES002", "GB001"] <- TRUE

  # UNSTABLE scope (ES002 dropped from source_ids): reconciler CORRECTLY flags it.
  el_unstable <- data.frame(ID = "ES001", LinkedGB = "GB001", Confidence = "High",
                            stringsAsFactors = FALSE)
  r1 <- rebuild_matrix_from_linked(el_unstable, "LinkedGB",
          source_ids = "ES001", target_ids = "GB001",
          existing_matrix = existing, user_edited_matrix = edited)
  expect_equal(r1$dropped_user_edits, "ES002:GB001")  # correct, given the bad scope

  # STABLE scope (ES002 retained): no phantom drop, edit preserved.
  el_stable <- data.frame(ID = "ES002", LinkedGB = "GB001", Confidence = "High",
                          stringsAsFactors = FALSE)
  r2 <- rebuild_matrix_from_linked(el_stable, "LinkedGB",
          source_ids = "ES002", target_ids = "GB001",
          existing_matrix = existing["ES002", , drop = FALSE],
          user_edited_matrix = edited["ES002", , drop = FALSE])
  expect_length(r2$dropped_user_edits, 0)
  expect_equal(r2$matrix["ES002", "GB001"], "-High:High")
})

test_that("stale_linked_ids fires only for targets outside target_ids", {
  el <- data.frame(ID = "MPF001", LinkedES = "ES001|ES999", Confidence = "Medium",
                   stringsAsFactors = FALSE)
  res <- rebuild_matrix_from_linked(el, "LinkedES",
          source_ids = "MPF001", target_ids = "ES001")
  expect_equal(res$stale_linked_ids, "ES999")
  expect_true(nzchar(res$matrix["MPF001", "ES001"]))  # valid edge still written
})
