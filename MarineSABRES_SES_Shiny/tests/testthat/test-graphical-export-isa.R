# tests/testthat/test-graphical-export-isa.R
# Review 2026-10-07 N6: Graphical SES "Export to ISA" could not run at all
# (trailing comma inside data.frame() in convert_nodes_to_element_df) and,
# behind that, wrote keys nothing reads. The older tests in
# test-graphical-ses-ai-creation.R exercised a helper-stubs.R stub instead of
# the real converter, so neither defect was visible. These tests re-bind the
# real function from .GlobalEnv.
source_for_test(c("modules/graphical_ses_network_builder.R",
                  "functions/visnetwork_helpers.R",
                  "functions/matrix_from_linked.R",
                  "functions/data_structure.R",
                  "functions/standard_entry_excel_import.R"))
convert_graphical_to_isa <- get("convert_graphical_to_isa", envir = .GlobalEnv)

canvas <- function() {
  nodes <- data.frame(
    id   = c("CF_1", "CF_2", "CF_3", "CF_4", "CF_5", "CF_6", "CF_7", "CF_8"),
    name = c("Food demand", "Trawling", "Seabed abrasion", "Benthic habitat",
             "Fish provision", "Fish catch income", "Closed areas", "Gear rules"),
    type = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
             "Ecosystem Services", "Goods & Benefits", "Responses", "Management"),
    stringsAsFactors = FALSE)
  edges <- data.frame(
    id = paste0("E", 1:9),
    from = c("CF_1", "CF_2", "CF_3", "CF_4", "CF_5", "CF_6", "CF_6", "CF_7", "CF_1"),
    to   = c("CF_2", "CF_3", "CF_4", "CF_5", "CF_6", "CF_1", "CF_7", "CF_2", "CF_3"),
    polarity = c("+", "+", "-", "+", "+", "+", "positive", "negative", "+"),
    strength = c("strong", "medium", "high", NA, "weak", "medium", "medium", "strong", "medium"),
    confidence = c(4, 3, 5, NA, 2, 3, 3, 4, 3),
    stringsAsFactors = FALSE)
  list(nodes = nodes, edges = edges)
}

test_that("N6: the real converter runs and emits the canonical schema", {
  cv <- canvas()
  isa <- convert_graphical_to_isa(cv$nodes, cv$edges, list(regional_sea = "Baltic Sea"))
  for (k in c("drivers", "activities", "pressures", "marine_processes", "ecosystem_services",
              "goods_benefits", "responses")) expect_true(is.data.frame(isa[[k]]), info = k)
  expect_false(any(c("state", "impact", "welfare", "management") %in% names(isa)))
  expect_equal(isa$drivers$ID, "D001")
  expect_equal(isa$marine_processes$ID, "MPF001")
  expect_equal(isa$marine_processes$Name, "Benthic habitat")
  expect_equal(isa$responses$ID, c("R001", "R002"))
  expect_equal(isa$responses$Type, c("", "Measure"))            # Management -> responses
  am <- isa$adjacency_matrices
  expect_setequal(names(am), c("d_a", "a_p", "p_mpf", "mpf_es", "es_gb", "gb_d", "gb_r", "r_a"))
  expect_false(any(c("p_s", "s_i", "i_w", "w_d") %in% names(am)))
})

test_that("N6: cells use the parseable '<pol><strength>:<conf>' format, keyed by element IDs", {
  cv <- canvas()
  am <- convert_graphical_to_isa(cv$nodes, cv$edges, list())$adjacency_matrices
  expect_equal(am$d_a["D001", "A001"], "+strong:4")
  expect_equal(am$p_mpf["P001", "MPF001"], "-strong:5")           # high -> strong
  expect_equal(am$mpf_es["MPF001", "ES001"], "+medium:3")         # NA -> defaults
  expect_equal(am$gb_r["GB001", "R001"], "+medium:3")             # 'positive' -> +, stored GB x R
  expect_equal(am$r_a["R001", "A001"], "-strong:4")               # 'negative' -> -
  conn <- parse_connection_value(am$d_a["D001", "A001"])
  expect_equal(conn$polarity, "+"); expect_equal(conn$confidence, 4L)
})

test_that("N6: non-canonical transitions are reported, not silently mis-filed", {
  cv <- canvas()
  isa <- convert_graphical_to_isa(cv$nodes, cv$edges, list())
  expect_equal(isa$metadata$edges_not_exported, 1L)               # D -> P has no ISA matrix
  expect_false(any(nzchar(isa$adjacency_matrices$a_p["A001", setdiff(colnames(isa$adjacency_matrices$a_p), "P001")])))
})

test_that("N6: Linked* columns mirror the edges and canvas cells are flagged user-edited", {
  cv <- canvas()
  isa <- convert_graphical_to_isa(cv$nodes, cv$edges, list())
  expect_equal(isa$drivers$LinkedA, "A001")
  expect_equal(isa$ecosystem_services$LinkedGB, "GB001")
  expect_equal(isa$responses$LinkedGB, c("GB001", ""))
  expect_equal(isa$responses$LinkedA, c("A001", ""))
  expect_true(isa$user_edited_matrices$d_a["D001", "A001"])
  # a later ISA save (rebuild from LinkedA) keeps the canvas strength/confidence
  rb <- rebuild_matrix_from_linked(isa$drivers, "LinkedA", isa$drivers$ID, isa$activities$ID,
                                   existing_matrix = isa$adjacency_matrices$d_a,
                                   user_edited_matrix = isa$user_edited_matrices$d_a)
  expect_equal(rb$matrix["D001", "A001"], "+strong:4")
})

test_that("N6: the export round-trips through the CLD builders and the ISA loader", {
  cv <- canvas()
  isa <- convert_graphical_to_isa(cv$nodes, cv$edges, list())
  nodes <- create_nodes_df(isa)
  expect_equal(nrow(nodes), 8)
  expect_setequal(unique(nodes$group), c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
                                         "Ecosystem Services", "Goods & Benefits", "Responses"))
  edges <- create_edges_df(isa, isa$adjacency_matrices)
  expect_gte(nrow(edges), 6)                                     # the full forward loop D->...->GB->D
  rec <- recover_isa_data(isa, new_stable_id_store())
  expect_equal(rec$elements$marine_processes$ID, "MPF001")
  expect_identical(rec$adjacency_matrices$d_a, isa$adjacency_matrices$d_a)   # faithful matrix kept
})

test_that("N6: an empty canvas exports an empty but well-formed ISA", {
  isa <- convert_graphical_to_isa(data.frame(), data.frame(), list())
  expect_equal(nrow(isa$drivers), 0)
  expect_equal(length(isa$adjacency_matrices), 0)
  expect_true(all(c("ID", "Name") %in% names(isa$goods_benefits)))
})

test_that("N6: app.R passes the event bus to the Graphical SES creator (source guard)", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  src <- paste(readLines(file.path(root, "app.R"), warn = FALSE), collapse = "\n")
  call <- regmatches(src, regexpr("graphical_ses_creator_server\\([^)]*\\)", src))
  expect_match(call, "event_bus")
})
