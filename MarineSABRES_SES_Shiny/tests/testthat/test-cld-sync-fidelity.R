# tests/testthat/test-cld-sync-fidelity.R
# Review 2026-10-07 N3: any CLD edit rewrote every adjacency matrix to bare
# polarity (strength/confidence/delay lost), replaced element IDs with the
# positional node ids ("GB_1") and names with the wrapped labels, dropped the
# user_edited flags and lowercased the frames. Red before the sync rewrite.
source_for_test(c("functions/visnetwork_helpers.R",
                  "functions/cld_interaction_helpers.R"))

long_name <- "Commercial fisheries landings and processing income"   # > LABEL_WRAP_WIDTH -> wrapped label

fixture_isa <- function() list(
  goods_benefits = data.frame(ID = c("GB001", "GB002"), Name = c("Food", long_name),
                              Type = "Provisioning", Description = c("d1", "d2"), Stakeholder = "",
                              Importance = "High", Trend = "Stable", stringsAsFactors = FALSE),
  ecosystem_services = data.frame(ID = "ES001", Name = "Fish stock", Type = "Provisioning",
                                  Description = "", LinkedGB = "GB001|GB002", Mechanism = "",
                                  Confidence = "High", stringsAsFactors = FALSE),
  drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "", LinkedA = "",
                       Trend = "", Controllability = "", stringsAsFactors = FALSE),
  adjacency_matrices = list(
    es_gb = matrix(c("+strong:4", "-weak:2"), nrow = 1, dimnames = list("ES001", c("GB001", "GB002"))),
    gb_d  = matrix(c("+medium:3", ""), nrow = 2, ncol = 1, dimnames = list(c("GB001", "GB002"), "D001"))
  ),
  user_edited_matrices = list(
    es_gb = matrix(c(TRUE, FALSE), nrow = 1, dimnames = list("ES001", c("GB001", "GB002")))
  )
)

round_trip <- function(isa, mutate_cld = identity) {
  nodes <- create_nodes_df(isa)
  edges <- create_edges_df(isa, isa$adjacency_matrices)
  cld <- mutate_cld(list(nodes = nodes, edges = edges))
  pd <- list(project_id = "p", data = list(cld = cld, isa_data = isa))
  sync_cld_to_isa_data(pd)$data$isa_data
}

test_that("create_nodes_df carries the ISA element id and raw name on every node", {
  nodes <- create_nodes_df(fixture_isa())
  expect_true(all(c("element_id", "name_raw") %in% names(nodes)))
  gb <- nodes[nodes$group == "Goods & Benefits", ]
  expect_equal(gb$element_id, c("GB001", "GB002"))
  expect_equal(gb$name_raw[2], long_name)
  expect_true(grepl("\n", gb$label[2], fixed = TRUE))   # label IS wrapped, name_raw is not
})

test_that("N3: an edit-free round trip keeps IDs, raw names, cell values, user_edited flags and column case", {
  out <- round_trip(fixture_isa())
  expect_equal(out$goods_benefits$ID, c("GB001", "GB002"))
  expect_equal(out$goods_benefits$Name, c("Food", long_name))
  expect_equal(out$goods_benefits$Description, c("d1", "d2"))
  expect_true(all(c("ID", "Name", "Type", "Importance") %in% names(out$goods_benefits)))
  expect_equal(out$ecosystem_services$ID, "ES001")
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB001"], "+strong:4")
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB002"], "-weak:2")
  expect_equal(out$adjacency_matrices$gb_d["GB001", "D001"], "+medium:3")
  expect_equal(dimnames(out$adjacency_matrices$es_gb), list("ES001", c("GB001", "GB002")))
  expect_true(out$user_edited_matrices$es_gb["ES001", "GB001"])
  expect_false(out$user_edited_matrices$es_gb["ES001", "GB002"])
})

test_that("N3: a polarity edit changes only the polarity character of the stored cell", {
  out <- round_trip(fixture_isa(), function(cld) {
    i <- which(cld$edges$from == "ES_1" & cld$edges$to == "GB_1")
    cld$edges$label[i] <- "-"; cld$edges$polarity[i] <- "-"
    cld
  })
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB001"], "-strong:4")
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB002"], "-weak:2")
})

test_that("N3: a node added in the CLD gets a fresh non-colliding element ID; a renamed node keeps its ID", {
  out <- round_trip(fixture_isa(), function(cld) {
    new_node <- cld$nodes[cld$nodes$id == "GB_1", ][1, ]
    new_node$id <- "GB_3"; new_node$label <- "New benefit"; new_node$element_id <- NA_character_; new_node$name_raw <- NA_character_
    cld$nodes <- rbind(cld$nodes, new_node)
    cld$nodes$label[cld$nodes$id == "GB_1"] <- "Food security"   # rename
    cld$edges <- rbind(cld$edges, transform(cld$edges[1, ], from = "ES_1", to = "GB_3", label = "+", polarity = "+"))
    cld
  })
  gb <- out$goods_benefits
  expect_equal(nrow(gb), 3)
  expect_equal(gb$ID[1:2], c("GB001", "GB002"))
  expect_equal(gb$Name[1], "Food security")
  expect_false(gb$ID[3] %in% c("GB001", "GB002"))
  expect_true(grepl("^GB[0-9]+$", gb$ID[3]))
  expect_equal(gb$Name[3], "New benefit")
  expect_true(gb$ID[3] %in% colnames(out$adjacency_matrices$es_gb))
  expect_true(nzchar(out$adjacency_matrices$es_gb["ES001", gb$ID[3]]))
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB001"], "+strong:4")   # untouched
})

test_that("N3: deleting a node in the CLD removes its element and matrix row/col but keeps the others intact", {
  out <- round_trip(fixture_isa(), function(cld) {
    cld$nodes <- cld$nodes[cld$nodes$id != "GB_1", ]
    cld$edges <- cld$edges[!(cld$edges$from == "GB_1" | cld$edges$to == "GB_1"), ]
    cld
  })
  expect_equal(out$goods_benefits$ID, "GB002")
  expect_equal(colnames(out$adjacency_matrices$es_gb), "GB002")
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB002"], "-weak:2")
})

test_that("N3: a label-only polarity edit (what the module writes first) is honoured", {
  out <- round_trip(fixture_isa(), function(cld) {
    i <- which(cld$edges$from == "ES_1" & cld$edges$to == "GB_1")
    cld$edges$label[i] <- "-"                      # polarity column left stale on purpose
    cld
  })
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB001"], "-strong:4")
})

test_that("N3: the sync writes element_id / name_raw back onto the CLD nodes", {
  isa <- fixture_isa()
  nodes <- create_nodes_df(isa); edges <- create_edges_df(isa, isa$adjacency_matrices)
  nodes$element_id <- NULL; nodes$name_raw <- NULL
  pd <- list(project_id = "p", data = list(cld = list(nodes = nodes, edges = edges), isa_data = isa))
  res <- sync_cld_to_isa_data(pd)
  n2 <- res$data$cld$nodes
  expect_equal(n2$element_id[n2$id == "GB_2"], "GB002")
  expect_equal(n2$name_raw[n2$id == "GB_2"], long_name)
})

test_that("N3: a legacy CLD survives TWO syncs across a deletion (name match beats position)", {
  isa <- fixture_isa()
  nodes <- create_nodes_df(isa); edges <- create_edges_df(isa, isa$adjacency_matrices)
  nodes$element_id <- NULL; nodes$name_raw <- NULL
  # delete GB_1 (= GB001) in the CLD, sync once
  nodes1 <- nodes[nodes$id != "GB_1", ]; edges1 <- edges[!(edges$from == "GB_1" | edges$to == "GB_1"), ]
  pd1 <- list(project_id = "p", data = list(cld = list(nodes = nodes1, edges = edges1), isa_data = isa))
  res1 <- sync_cld_to_isa_data(pd1)
  expect_equal(res1$data$isa_data$goods_benefits$ID, "GB002")
  # second edit on the same (legacy-shaped) nodes: strip the written-back ids to
  # simulate a module that still holds the old rv$nodes, then sync again
  nodes2 <- res1$data$cld$nodes; nodes2$element_id <- NULL; nodes2$name_raw <- NULL
  pd2 <- res1; pd2$data$cld$nodes <- nodes2
  res2 <- sync_cld_to_isa_data(pd2)
  expect_equal(res2$data$isa_data$goods_benefits$ID, "GB002")           # not GB003 / not a fresh id
  expect_equal(res2$data$isa_data$goods_benefits$Name, long_name)
  expect_equal(res2$data$isa_data$adjacency_matrices$es_gb["ES001", "GB002"], "-weak:2")
})

test_that("N3: CLD-made edge changes are flagged user-edited so the next ISA save keeps them", {
  isa <- fixture_isa()
  # add ES001 -> GB002? already exists; instead DELETE ES001 -> GB002 and ADD GB002 -> D001 in the CLD
  out <- round_trip(isa, function(cld) {
    cld$edges <- cld$edges[!(cld$edges$from == "ES_1" & cld$edges$to == "GB_2"), ]
    cld$edges <- rbind(cld$edges, transform(cld$edges[1, ], from = "GB_2", to = "D_1", label = "+", polarity = "+"))
    cld
  })
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB002"], "")
  expect_true(out$user_edited_matrices$es_gb["ES001", "GB002"])         # cleared cell is a user edit
  expect_true(nzchar(out$adjacency_matrices$gb_d["GB002", "D001"]))
  expect_true(out$user_edited_matrices$gb_d["GB002", "D001"])
  expect_false(out$user_edited_matrices$gb_d["GB001", "D001"])          # unchanged cell keeps its flag
  # The ISA module's rebuild with the (stale) LinkedGB = "GB001|GB002" must respect both edits
  skip_if_not(exists("rebuild_matrix_from_linked", mode = "function"))
  rb <- rebuild_matrix_from_linked(out$ecosystem_services, "LinkedGB",
                                   source_ids = out$ecosystem_services$ID,
                                   target_ids = out$goods_benefits$ID,
                                   existing_matrix = out$adjacency_matrices$es_gb,
                                   user_edited_matrix = out$user_edited_matrices$es_gb)
  expect_equal(rb$matrix["ES001", "GB002"], "")                          # deleted edge stays deleted
  expect_equal(rb$matrix["ES001", "GB001"], "+strong:4")
})

test_that("N3: new R-arm edges from the CLD use the dynamics-friendly cell format", {
  isa <- fixture_isa()
  isa$responses <- data.frame(ID = "R001", Name = "Quota", Type = "", Description = "", Stakeholder = "",
                              Importance = "", Trend = "", LinkedGB = "", LinkedD = "", LinkedA = "",
                              LinkedP = "", stringsAsFactors = FALSE)
  out <- round_trip(isa, function(cld) {
    # a genuinely new edge carries no strength/confidence yet (unlike a copied row)
    cld$edges <- rbind(cld$edges, transform(cld$edges[1, ], from = "R_1", to = "D_1", label = "-", polarity = "-",
                                            strength = NA_character_, confidence = NA))
    cld
  })
  expect_equal(out$adjacency_matrices$r_d["R001", "D001"], "-medium:3")
})

test_that("N3: legacy CLD nodes without element_id still resolve positionally to the saved IDs", {
  isa <- fixture_isa()
  nodes <- create_nodes_df(isa); edges <- create_edges_df(isa, isa$adjacency_matrices)
  nodes$element_id <- NULL; nodes$name_raw <- NULL        # as stored by pre-fix saves
  pd <- list(project_id = "p", data = list(cld = list(nodes = nodes, edges = edges), isa_data = isa))
  out <- sync_cld_to_isa_data(pd)$data$isa_data
  expect_equal(out$goods_benefits$ID, c("GB001", "GB002"))
  expect_equal(out$goods_benefits$Name[2], long_name)      # unwrapped from the label
  expect_equal(out$adjacency_matrices$es_gb["ES001", "GB002"], "-weak:2")
})
