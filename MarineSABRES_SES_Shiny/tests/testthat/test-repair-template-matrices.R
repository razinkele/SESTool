# test-repair-template-matrices.R
# Projects saved from an AI-assistant template before PR #129 hold their
# connections in legacy-named matrices (a_d, p_a, ...) next to empty forward
# matrices, so their diagram is empty. On load they are rebuilt from the
# saved connection list (isa_data$connections), which is exact; the legacy
# matrices themselves were mis-shaped and cannot be trusted.

library(testthat)

source_for_test(c("modules/ai_isa/data_persistence.R"))

# A project shaped like the old template save: 3 drivers x 2 activities (non-
# square, so a layout error cannot hide), D->A and A->P connections labelled
# with legacy names, legacy matrices filled the old (wrong) way, forward empty.
old_template_project <- function() {
  el <- function(n) data.frame(id = sprintf("X%03d", seq_along(n)), name = n, description = "",
                               stringsAsFactors = FALSE)
  conns <- list(
    list(from = "D3", to = "A2", from_category = "drivers", to_category = "activities",
         polarity = "+", strength = "strong", matrix = "a_d", from_index = 3, to_index = 2),
    list(from = "A1", to = "P1", from_category = "activities", to_category = "pressures",
         polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 1),
    list(from = "D1", to = "A1", from_category = "drivers", to_category = "activities",
         polarity = "+", strength = "weak", matrix = "a_d", from_index = 1, to_index = 1)  # not approved
  )
  empty <- function(r, c) matrix("", length(r), length(c), dimnames = list(r, c))
  a_d <- empty(c("A1", "A2"), c("D1", "D2", "D3")); a_d[1, 1] <- "+strong:3"   # old garbled cell
  p_a <- empty("P1", c("A1", "A2")); p_a[1, 1] <- "+medium:3"
  list(data = list(
    isa_data = list(
      drivers = el(c("D1", "D2", "D3")), activities = el(c("A1", "A2")), pressures = el("P1"),
      adjacency_matrices = list(d_a = empty(c("D1", "D2", "D3"), c("A1", "A2")),
                                a_p = empty(c("A1", "A2"), "P1"), a_d = a_d, p_a = p_a),
      connections = list(suggested = conns, approved = c(1L, 2L))
    ),
    metadata = list()
  ))
}

test_that("an old template project gets its forward matrices rebuilt from the saved connections", {
  p <- old_template_project()
  out <- repair_template_connection_matrices(p$data$isa_data)
  m <- out$adjacency_matrices
  expect_equal(dim(m$d_a), c(3L, 2L))
  expect_true(nzchar(m$d_a["D3", "A2"]))
  expect_equal(sum(m$d_a != ""), 1L)            # only the approved D->A link
  expect_true(nzchar(m$a_p["A1", "P1"]))
  expect_null(m$a_d)
  expect_null(m$p_a)
  expect_equal(attr(out, "repaired_matrices"), c("d_a", "a_p"))
})

test_that("projects without the template-bug pattern are left untouched", {
  p <- old_template_project()$data$isa_data
  p$adjacency_matrices$d_a["D1", "A1"] <- "+medium:3"     # forward already has data
  p$adjacency_matrices$a_p["A2", "P1"] <- "+weak:3"
  expect_identical(repair_template_connection_matrices(p), p)

  q <- old_template_project()$data$isa_data
  q$connections <- NULL                                   # nothing to rebuild from
  expect_identical(repair_template_connection_matrices(q), q)

  r <- old_template_project()$data$isa_data
  r$adjacency_matrices$a_d <- NULL; r$adjacency_matrices$p_a <- NULL   # normal project
  expect_identical(repair_template_connection_matrices(r), r)
})

test_that("loading a project runs the repair", {
  skip_if_not(exists("normalize_json_project_data", mode = "function"))
  out <- normalize_json_project_data(old_template_project())
  expect_true(nzchar(out$data$isa_data$adjacency_matrices$d_a["D3", "A2"]))
  expect_null(out$data$isa_data$adjacency_matrices$a_d)
  expect_equal(attr(out, "repaired_template_links"), 2L)
})
