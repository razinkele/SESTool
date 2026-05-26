# test-cld-interaction-helpers-user-edited.R
# Tests for user_edited_matrices flagging in sync_cld_to_isa_data()
#
# Background: When sync_cld_to_isa_data() writes an adjacency matrix cell
# via adj[[mat_name]][from_id, to_id] <- pol, it should ALSO flag that
# cell in user_edited_matrices to mark it as user-intentional (drawn/edited
# in the CLD). This mirrors the pattern from Task 10.

library(testthat)

source_for_test("functions/cld_interaction_helpers.R")

# ============================================================================
# HELPER: minimal project_data with a tiny CLD
# ============================================================================

make_project_data <- function() {
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
    label = c("driver1", "activity1", "pressure1", "mp1", "es1", "gb1"),
    group = c("Drivers", "Activities", "Pressures",
              "Marine Processes & Functioning", "Ecosystem Services",
              "Goods & Benefits"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
    to   = c("A_1", "P_1", "MPF_1", "ES_1", "GB_1", "D_1"),
    label = c("+", "+", "-", "+", "+", "-"),
    stringsAsFactors = FALSE
  )
  list(
    project_id = "test_project",
    project_name = "Test",
    data = list(
      cld = list(nodes = nodes, edges = edges),
      isa_data = list()
    ),
    last_modified = Sys.time()
  )
}

# ============================================================================
# TESTS
# ============================================================================

test_that("sync_cld_to_isa_data flags each cell written to user_edited_matrices", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")

  pd <- make_project_data()
  result <- sync_cld_to_isa_data(pd)

  # Should have isa_data after sync
  expect_true(is.list(result$data$isa_data))

  # Should have adjacency_matrices
  expect_true(!is.null(result$data$isa_data$adjacency_matrices))

  # Should have user_edited_matrices (new requirement)
  expect_true(!is.null(result$data$isa_data$user_edited_matrices),
              info = "user_edited_matrices must exist after sync")

  # For each non-empty adjacency matrix, verify user_edited_matrices has matching shape
  adj <- result$data$isa_data$adjacency_matrices
  user_ed <- result$data$isa_data$user_edited_matrices

  for (mat_name in names(adj)) {
    if (is.null(adj[[mat_name]])) next
    if (nrow(adj[[mat_name]]) == 0 || ncol(adj[[mat_name]]) == 0) next

    # Check user_edited exists and matches shape
    expect_true(mat_name %in% names(user_ed),
                info = paste("user_edited_matrices must have entry for", mat_name))

    expect_equal(dim(user_ed[[mat_name]]), dim(adj[[mat_name]]),
                 info = paste("user_edited[[", mat_name, "]] must match adjacency_matrices shape"))

    # Check that every non-empty cell in adjacency is flagged TRUE in user_edited
    for (i in seq_len(nrow(adj[[mat_name]]))) {
      for (j in seq_len(ncol(adj[[mat_name]]))) {
        cell_val <- adj[[mat_name]][i, j]
        if (!is.na(cell_val) && nzchar(as.character(cell_val))) {
          # This cell is occupied in adjacency
          expect_true(user_ed[[mat_name]][i, j],
                      info = paste("Cell [", i, ",", j, "] in", mat_name,
                                   "has adjacency value but user_edited is not TRUE"))
        }
      }
    }
  }
})

test_that("sync_cld_to_isa_data persists user_edited_matrices to isa_data", {
  skip_if_not(exists("sync_cld_to_isa_data", mode = "function"),
              "sync_cld_to_isa_data not available")

  pd <- make_project_data()
  result <- sync_cld_to_isa_data(pd)

  # Verify the structure is set on isa_data
  isa <- result$data$isa_data
  expect_true(!is.null(isa$user_edited_matrices),
              info = "user_edited_matrices must be assigned to isa_data")
  expect_true(is.list(isa$user_edited_matrices),
              info = "user_edited_matrices must be a list")
})

test_that("source code contains cell-write pattern with user_edited flagging", {
  # This is a source-code contract test to ensure the implementation exists
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- paste(readLines(
    file.path(root, "functions", "cld_interaction_helpers.R"),
    warn = FALSE), collapse = "\n")

  # Original CLD cell-write must exist
  expect_true(grepl("adj\\[\\[mat_name\\]\\]\\[from_id, to_id\\] <- pol", src, perl = TRUE),
              info = "Original cell-write adj[[mat_name]][from_id, to_id] <- pol must exist")

  # Must also flag user_edited after writing
  expect_true(grepl("user_edited\\[\\[mat_name\\]\\]\\[from_id, to_id\\] <- TRUE", src, perl = TRUE),
              info = "Must also write user_edited[[mat_name]][from_id, to_id] <- TRUE")

  # user_edited_matrices must be persisted to isa
  expect_true(grepl("isa\\$user_edited_matrices\\s*<-", src, perl = TRUE),
              info = "user_edited_matrices must be persisted: isa$user_edited_matrices <- user_edited")
})
