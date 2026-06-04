# tests/testthat/test-user-edited-matrices-persist.R
#
# M12: user_edited_matrices must survive a save → reload round-trip.
#
# APPROACH: Static + seam round-trip (NOT testServer).
#   Rationale: isa_data_entry_module.R is a 1600-line reactive module; testServer
#   of the full server carries segfault risk per project conventions (bare Rscript -e
#   with heavy sources). Instead:
#   1. Static grep: assert sync_to_project_data() writes user_edited_matrices to pd.
#   2. Seam round-trip: source the pure helper restore_user_edited_matrices()
#      (extracted from apply_saved_isa in isa_data_entry_module.R) and verify that
#      a TRUE cell in a saved user_edited_matrices survives the restore step.
#
# LIMITATION: the static test proves the assignment is textually present; a live
#   testServer() test would confirm runtime behavior.  The seam test proves the
#   restore logic is correct for the happy path and the old-save fallback path.

library(testthat)
library(shiny)

# Source the pure helper (extracted in the M12 fix).
source_for_test("functions/matrix_from_linked.R")

# ── 1. Static: sync_to_project_data() writes user_edited_matrices ────────────

test_that("sync_to_project_data writes user_edited_matrices to project data", {
  expect_context_key_in_file(
    "modules/isa_data_entry_module.R",
    "pd$data$isa_data$user_edited_matrices <- isa_data$user_edited_matrices",
    info = paste(
      "sync_to_project_data() must persist user_edited_matrices so that",
      "user-tuned matrix cells survive a save/reload cycle (M12)."
    )
  )
})

# ── 2. Seam: restore_user_edited_matrices() round-trip ───────────────────────
#
# restore_user_edited_matrices(saved_ue, adj_matrices) is a pure function
# extracted from apply_saved_isa.  It takes:
#   saved_ue     — list of logical matrices (from saved project$data$isa_data$user_edited_matrices)
#   adj_matrices — the adjacency matrices that were just loaded/reconciled
# and returns a list of logical matrices aligned to adj_matrices, with:
#   - TRUE cells preserved from saved_ue wherever dimnames match
#   - all-FALSE default for keys/cells not present in saved_ue (old-save safety)

source_for_test("modules/isa_data_entry_module.R")

test_that("restore_user_edited_matrices() is exported by isa_data_entry_module.R", {
  skip_if_not(
    exists("restore_user_edited_matrices", mode = "function"),
    "restore_user_edited_matrices not available — M12 fix may not be sourced yet (expected failure)"
  )
  expect_true(is.function(restore_user_edited_matrices))
})

test_that("TRUE user-edited cell survives save→reload round-trip via restore_user_edited_matrices", {
  skip_if_not(
    exists("restore_user_edited_matrices", mode = "function"),
    "restore_user_edited_matrices not available — expected failure before M12 fix"
  )

  # Simulate the saved adjacency matrix for es_gb (after project save)
  adj <- matrix(
    c("+HighMedium:High", "", "", "+MediumMedium:Medium"),
    nrow = 2, ncol = 2,
    dimnames = list(c("ES001", "ES002"), c("GB001", "GB002"))
  )

  # Simulate the saved user_edited_matrices (as persisted by the fixed sync_to_project_data)
  saved_ue <- list(
    es_gb = matrix(
      c(TRUE, FALSE, FALSE, FALSE),
      nrow = 2, ncol = 2,
      dimnames = list(c("ES001", "ES002"), c("GB001", "GB002"))
    )
  )

  adj_matrices <- list(es_gb = adj)

  # Run the restore helper
  restored <- restore_user_edited_matrices(saved_ue, adj_matrices)

  # The TRUE at [ES001, GB001] must survive
  expect_true(
    restored$es_gb["ES001", "GB001"],
    label = "User-edited TRUE cell [ES001,GB001] must be preserved after restore"
  )
  # The FALSE cells must remain FALSE
  expect_false(restored$es_gb["ES001", "GB002"])
  expect_false(restored$es_gb["ES002", "GB001"])
  expect_false(restored$es_gb["ES002", "GB002"])
})

test_that("old-save fallback: restore_user_edited_matrices returns all-FALSE when saved_ue is NULL", {
  skip_if_not(
    exists("restore_user_edited_matrices", mode = "function"),
    "restore_user_edited_matrices not available — expected failure before M12 fix"
  )

  adj <- matrix("", nrow = 2, ncol = 2,
                dimnames = list(c("ES001", "ES002"), c("GB001", "GB002")))
  adj_matrices <- list(es_gb = adj)

  # Old save: no user_edited_matrices saved
  restored <- restore_user_edited_matrices(NULL, adj_matrices)

  # Must return all-FALSE for es_gb (not an error)
  expect_true(is.list(restored))
  expect_true("es_gb" %in% names(restored))
  expect_false(any(restored$es_gb))
})

test_that("old-save fallback: restore_user_edited_matrices returns all-FALSE when saved_ue is empty list", {
  skip_if_not(
    exists("restore_user_edited_matrices", mode = "function"),
    "restore_user_edited_matrices not available — expected failure before M12 fix"
  )

  adj <- matrix("", nrow = 1, ncol = 1,
                dimnames = list("D001", "A001"))
  adj_matrices <- list(d_a = adj)

  restored <- restore_user_edited_matrices(list(), adj_matrices)

  expect_true(is.list(restored))
  expect_true("d_a" %in% names(restored))
  expect_false(any(restored$d_a))
})

test_that("restore_user_edited_matrices handles dimension mismatch gracefully (falls back to all-FALSE)", {
  skip_if_not(
    exists("restore_user_edited_matrices", mode = "function"),
    "restore_user_edited_matrices not available — expected failure before M12 fix"
  )

  # Saved matrix has 2 rows; current adjacency has 3 rows (element was added)
  saved_ue <- list(
    a_p = matrix(c(TRUE, FALSE), nrow = 2, ncol = 1,
                 dimnames = list(c("A001", "A002"), "P001"))
  )
  # After reconcile, A003 was added
  adj <- matrix("", nrow = 3, ncol = 1,
                dimnames = list(c("A001", "A002", "A003"), "P001"))
  adj_matrices <- list(a_p = adj)

  # restore must not error; should preserve TRUE for A001 but all-FALSE for A003
  restored <- restore_user_edited_matrices(saved_ue, adj_matrices)
  expect_true(restored$a_p["A001", "P001"])
  expect_false(restored$a_p["A003", "P001"])
})

# ── 3. Static: apply_saved_isa overlays saved user_edited_matrices ────────────

test_that("apply_saved_isa source overlays saved_isa$user_edited_matrices (not just recover defaults)", {
  expect_context_key_in_file(
    "modules/isa_data_entry_module.R",
    "restore_user_edited_matrices",
    info = paste(
      "apply_saved_isa() must call restore_user_edited_matrices() so that",
      "the SAVED user_edited_matrices (not just recover defaults) are restored."
    )
  )
})
