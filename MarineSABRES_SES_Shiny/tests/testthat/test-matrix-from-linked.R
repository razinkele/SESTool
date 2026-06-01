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

# --- Task 2: stable (non-positional) element ID generator ---
source_for_test("functions/data_structure.R")

test_that("generate_stable_element_id never reuses a number for a prefix", {
  reset_stable_id_counter("ES")
  ids <- c(generate_stable_element_id("ES"),
           generate_stable_element_id("ES"),
           generate_stable_element_id("ES"))
  expect_equal(ids, c("ES001", "ES002", "ES003"))
  expect_equal(anyDuplicated(ids), 0)
})

test_that("seed_stable_id_counter advances the high-water mark from existing ids", {
  reset_stable_id_counter("GB")
  seed_stable_id_counter("GB", c("GB001", "GB004", "GB002"))
  expect_equal(generate_stable_element_id("GB"), "GB005")
})

# --- Task 4: legacy-corruption-safe ID repair on load ---

test_that("reconcile_loaded_element_ids uniquifies duplicate ids, preserves first occurrence", {
  reset_stable_id_counter("ES")
  df <- data.frame(ID = c("ES001", "ES001", "ES002"), Name = c("a", "b", "c"),
                   LinkedGB = c("GB001", "", "GB001"), stringsAsFactors = FALSE)
  res <- reconcile_loaded_element_ids(df, "ES")
  expect_equal(anyDuplicated(res$df$ID), 0)
  expect_true(all(nzchar(res$df$ID)))
  expect_equal(res$df$ID[1], "ES001")          # first kept
  expect_false(res$df$ID[2] %in% c("ES001"))   # duplicate re-keyed
  expect_true(isTRUE(res$repaired))
})

test_that("reconcile_loaded_element_ids is a no-op for clean ids", {
  reset_stable_id_counter("ES")
  df <- data.frame(ID = c("ES001", "ES002"), Name = c("a", "b"), stringsAsFactors = FALSE)
  res <- reconcile_loaded_element_ids(df, "ES")
  expect_equal(res$df$ID, c("ES001", "ES002"))
  expect_false(isTRUE(res$repaired))
})

test_that("reconcile_loaded_element_ids handles a lowercase 'id' column (load-path bug L6)", {
  reset_stable_id_counter("ES")
  df <- data.frame(id = c("ES001","ES002"), name = c("a","b"), stringsAsFactors = FALSE)
  res <- reconcile_loaded_element_ids(df, "ES")
  expect_true("ID" %in% names(res$df))
  expect_equal(as.character(res$df$ID), c("ES001","ES002"))   # NON-empty -> panel_ids will populate
})

test_that("reconcile_loaded_element_ids generates ids when no id column exists", {
  reset_stable_id_counter("GB")
  df <- data.frame(name = c("x","y","z"), stringsAsFactors = FALSE)
  res <- reconcile_loaded_element_ids(df, "GB")
  expect_true("ID" %in% names(res$df))
  expect_equal(sum(nzchar(as.character(res$df$ID))), 3L)       # all rows got an id
  expect_equal(anyDuplicated(res$df$ID), 0)
})
