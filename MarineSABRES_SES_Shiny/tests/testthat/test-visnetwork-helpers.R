test_that("create_edges_df deduplicates edges from overlapping matrices", {
  skip_if_not(exists("create_edges_df", mode = "function"),
              "create_edges_df not available")

  # Create ISA data with one response and one pressure
  isa_data <- list(
    drivers = data.frame(id = "D1", name = "Driver1", stringsAsFactors = FALSE),
    activities = data.frame(id = "A1", name = "Activity1", stringsAsFactors = FALSE),
    pressures = data.frame(id = "P1", name = "Pressure1", stringsAsFactors = FALSE),
    marine_processes = NULL,
    ecosystem_services = NULL,
    goods_benefits = NULL,
    responses = data.frame(id = "R1", name = "Response1", stringsAsFactors = FALSE)
  )

  # Create BOTH r_p and p_r matrices (should produce same edge)
  r_p_mat <- matrix("+", nrow = 1, ncol = 1,
                     dimnames = list("Response1", "Pressure1"))
  p_r_mat <- matrix("+", nrow = 1, ncol = 1,
                     dimnames = list("Pressure1", "Response1"))

  adj_matrices <- list(r_p = r_p_mat, p_r = p_r_mat)

  edges <- create_edges_df(isa_data, adj_matrices)

  # Edge IDs are built as PREFIX_INDEX (e.g., "R_1", "P_1")
  # Should have exactly 1 R->P edge, not 2
  r_to_p <- edges[edges$from == "R_1" & edges$to == "P_1", ]
  expect_equal(nrow(r_to_p), 1,
               info = "Duplicate edges from r_p and p_r matrices must be deduplicated")
})
