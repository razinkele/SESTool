# tests/testthat/test-polarity-persistence.R
# Evidenced polarity: no writer may save a connection without a sign.
source_for_test(c("modules/ai_isa/data_persistence.R",
                  "functions/visnetwork_helpers.R",
                  "functions/cld_interaction_helpers.R"))

test_that("matrix builder skips a connection with NA polarity", {
  elements <- list(drivers = list(list(name = "D1"), list(name = "D2")),
                   activities = list(list(name = "A1"), list(name = "A2")))
  mk <- function(pol, from_i, to_i) list(
    from = paste0("D", from_i), to = paste0("A", to_i),
    from_category = "drivers", to_category = "activities",
    polarity = pol, strength = "medium", matrix = "d_a",
    from_index = from_i, to_index = to_i)
  suggested <- list(mk("+", 1, 1), mk(NA_character_, 2, 2))
  am <- build_adjacency_matrices(elements, suggested, approved_connections = 1:2)
  cells <- unlist(lapply(am, function(m) m[!is.na(m) & nzchar(m)]))
  expect_false(any(startsWith(cells, "NA")))
  expect_length(cells, 1)
  expect_true(startsWith(cells, "+"))
})

test_that("CLD sync drops an edge without a sign instead of inventing +", {
  isa <- list(
    goods_benefits = data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Jobs"),
                                Type = "Provisioning", Description = "", Stakeholder = "",
                                Importance = "High", Trend = "Stable", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish stock", Type = "Provisioning",
                                    Description = "", LinkedGB = "GB001|GB002", Mechanism = "",
                                    Confidence = "High", stringsAsFactors = FALSE),
    adjacency_matrices = list(
      es_gb = matrix(c("+strong:4", "-weak:2"), nrow = 1,
                     dimnames = list("ES001", c("GB001", "GB002")))
    )
  )
  nodes <- create_nodes_df(isa)
  edges <- create_edges_df(isa, isa$adjacency_matrices)
  expect_equal(nrow(edges), 2)
  edges$label[2] <- NA_character_; edges$polarity[2] <- NA_character_
  pd <- list(project_id = "p", data = list(cld = list(nodes = nodes, edges = edges), isa_data = isa))
  out <- sync_cld_to_isa_data(pd)$data$isa_data$adjacency_matrices
  cells <- unlist(lapply(out, function(m) m[!is.na(m) & nzchar(m)]))
  expect_length(cells, 1)
  expect_false(any(startsWith(cells, "NA")))
  expect_equal(unname(cells), "+strong:4")
})
