# Graphical SES creator: connections get a sign only from evidence
# (evidenced polarity, Task 7). stub_kb() lives in helper-kb-stub.R.

source_for_test(c("functions/polarity_evidence.R",
                  "functions/visnetwork_helpers.R",
                  "modules/graphical_ses_network_builder.R",
                  "modules/graphical_ses_creator_module.R"))
# helper-stubs.R shadows these with stubs; drive the real ones
graphical_ses_creator_server <- get("graphical_ses_creator_server", envir = .GlobalEnv)
convert_graphical_to_isa <- get("convert_graphical_to_isa", envir = .GlobalEnv)
create_ghost_node_data <- get("create_ghost_node_data", envir = .GlobalEnv)

# Bind a value in .GlobalEnv (where the module's free names resolve) for one test
local_global <- function(name, value, env = parent.frame()) {
  had <- exists(name, envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get(name, envir = .GlobalEnv) else NULL
  assign(name, value, envir = .GlobalEnv)
  withr::defer(if (had) assign(name, old, envir = .GlobalEnv) else rm(list = name, envir = .GlobalEnv),
               envir = env)
}

ctx <- list(regional_sea = "Baltic Sea", ecosystem_type = "Open coast", main_issue = "Overfishing")
two_node_net <- function() data.frame(
  id = c("A_1", "D_1"), name = c("Bottom trawling", "Food demand"),
  type = c("Activities", "Drivers"), stringsAsFactors = FALSE)

suggest_from_trawling <- function(existing = two_node_net()) {
  suggest_connected_elements("A_1", list(name = "Bottom trawling", type = "Activities"),
                             existing, ctx, max_suggestions = 10)
}
pols <- function(g) vapply(g, function(s) s$connection_polarity, character(1))

test_that("ghost suggestions carry only evidenced signs", {
  stub_kb(NULL)
  g <- suggest_from_trawling()
  expect_gt(length(g), 0)
  expect_true(all(is.na(pols(g))))
  expect_true(all(is.na(vapply(g, function(s) s$connection_polarity_source, character(1)))))
  # the builders that used to guess a sign (completeness, chain, bridge) leave it unset too
  net <- data.frame(id = c("D_1", "GB_1"), name = c("Food demand", "Fish income"),
                    type = c("Drivers", "Goods & Benefits"), stringsAsFactors = FALSE)
  topo <- analyze_network_topology_for_suggestions(
    "D_1", list(name = "Food demand", type = "Drivers"), net, get_allowed_targets("Drivers"), ctx)
  chain <- analyze_causal_chains_for_suggestions(
    "D_1", list(name = "Food demand", type = "Drivers"), net, get_allowed_targets("Drivers"), ctx)
  expect_gt(length(c(topo, chain)), 0)
  expect_true(all(is.na(pols(c(topo, chain)))))
})

test_that("an exact, sourced KB match fills the sign and its citation", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020", strength = "strong"))
  g <- suggest_from_trawling()
  expect_gt(length(g), 0)
  expect_true(all(pols(g) == "-"))
  expect_true(all(vapply(g, function(s) s$connection_polarity_source, character(1)) == "Smith 2020"))
})

test_that("a synonym KB match is not evidence", {
  stub_kb(list(polarity = "+", match_quality = "synonym", source = "X", strength = "medium"))
  expect_true(all(is.na(pols(suggest_from_trawling()))))
})

test_that("the KB lookup receives KB categories and names in the right slots", {
  calls <- list()
  local_global("lookup_knowledge_base", function(from_name, from_type, to_name, to_type, ...) {
    calls[[length(calls) + 1]] <<- list(from_name = from_name, from_type = from_type,
                                        to_name = to_name, to_type = to_type)
    NULL
  })
  ev <- graphical_polarity_evidence("Bottom trawling", "Activities",
                                    "Seabed damage", "Pressures")
  expect_identical(ev, list(polarity = NA_character_, source = NA_character_))
  expect_equal(calls[[1]], list(from_name = "Bottom trawling", from_type = "activities",
                                to_name = "Seabed damage", to_type = "pressures"))
  graphical_polarity_evidence("Seabed damage", "Pressures",
                              "Benthic habitat", "Marine Processes & Functioning")
  expect_identical(calls[[2]]$to_type, "states")
})

test_that("a loop opportunity never supplies a sign", {
  stub_kb(NULL)
  net <- data.frame(id = c("R_1", "D_1", "A_2"), name = c("Fishing quota", "Food demand", "Shipping"),
                    type = c("Responses", "Drivers", "Activities"), stringsAsFactors = FALSE)
  opp <- identify_loop_opportunities(list(name = "Gear rules", type = "Responses"), net,
                                     get_allowed_targets("Responses"))
  expect_gt(length(opp), 0)
  expect_true(all(is.na(vapply(opp, function(o) o$polarity, character(1)))))
  expect_true(all(nzchar(vapply(opp, function(o) o$loop_type, character(1)))))   # kept for display
  topo <- analyze_network_topology_for_suggestions(
    "R_1", list(name = "Gear rules", type = "Responses"), net, get_allowed_targets("Responses"), ctx)
  loops <- Filter(function(s) identical(s$strategy_tag, "FEEDBACK_LOOP"), topo)
  expect_gt(length(loops), 0)
  expect_true(all(is.na(pols(loops))))
})

test_that("unsigned suggestions get a neutral reasoning text", {
  expect_match(generate_suggestion_reasoning("a", "b", "Activities", "Pressures", NA_character_, "strong"),
               "affects", fixed = TRUE)
})

test_that("ghost edges carry the polarity source column", {
  sg <- list(from_node = "A_1", connection_polarity = "-", connection_polarity_source = "Smith 2020",
             connection_strength = "medium", connection_confidence = 3)
  e <- create_ghost_edge_data(sg, 1)
  expect_identical(e$polarity, "-")
  expect_identical(e$polarity_source, "Smith 2020")
  sg$connection_polarity <- NA_character_; sg$connection_polarity_source <- NULL
  e2 <- create_ghost_edge_data(sg, 2)
  expect_identical(e2$polarity_source, NA_character_)
  expect_equal(names(e), names(e2))                      # rbind-safe
})

test_that("graphical_edge_cell does not invent +", {
  e <- data.frame(polarity = c("+", "opposing", "?", NA, "Positive", "minus"),
                  strength = "medium", confidence = 3, stringsAsFactors = FALSE)
  expect_equal(vapply(1:6, function(i) graphical_edge_cell(e, i), ""),
               c("+medium:3", "-medium:3", NA, NA, "+medium:3", "-medium:3"))
  expect_identical(graphical_edge_cell(data.frame(strength = "medium"), 1), NA_character_)
})

test_that("ISA export skips unsigned edges instead of writing +", {
  nodes <- data.frame(id = c("D_1", "A_1", "P_1"), name = c("Food demand", "Trawling", "Abrasion"),
                      type = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE)
  edges <- data.frame(id = c("E1", "E2"), from = c("D_1", "A_1"), to = c("A_1", "P_1"),
                      polarity = c(NA, "-"), strength = "medium", confidence = 3,
                      stringsAsFactors = FALSE)
  isa <- convert_graphical_to_isa(nodes, edges, list())
  am <- isa$adjacency_matrices
  expect_null(am$d_a)                                    # no matrix for the unsigned edge
  expect_equal(am$a_p["A001", "P001"], "-medium:3")
  expect_equal(isa$drivers$LinkedA, "")
  expect_equal(isa$metadata$edges_unsigned, 1L)
  cells <- unlist(lapply(am, as.vector))
  expect_false(any(is.na(cells)))
  expect_false(any(grepl("^NA", cells)))
})

# --- creator server: accepting a ghost --------------------------------------

start_network <- function(session, rv) {
  rv$classification_result <- list(element_name = "Bottom trawling",
                                   primary = list(type = "Activities", confidence = 0.9))
  rv$selected_classification_type <- "Activities"
  session$setInputs(confirm_classification = 1)
  first <- rv$network_nodes$id[1]
  session$setInputs(node_clicked = first)
  session$setInputs(expand_node = 1)
  first
}

test_that("accepting an unsigned ghost waits for a sign", {
  stub_kb(NULL)
  local_global("ML_AVAILABLE", FALSE)
  testServer(graphical_ses_creator_server, args = list(
    project_data_reactive = reactiveVal(list()), i18n = make_test_i18n()), {
    first <- start_network(session, rv)
    expect_gt(nrow(rv$ghost_nodes), 0)
    expect_true(is.na(rv$ghost_edges$polarity[rv$ghost_edges$to == "GHOST_1"]))
    nodes_before <- rv$network_nodes
    edges_before <- rv$network_edges

    session$setInputs(node_clicked = "GHOST_1")           # canvas click, no sign yet
    expect_identical(rv$network_nodes, nodes_before)
    expect_identical(rv$network_edges, edges_before)
    expect_gt(nrow(rv$ghost_nodes), 0)                     # suggestions stay to be signed

    session$setInputs(accept_ghost = "GHOST_1")           # suggestion-panel click, no sign yet
    expect_identical(rv$network_nodes, nodes_before)

    pick <- graphical_ghost_sign_id(rv$ghost_batch, "GHOST_1")
    do.call(session$setInputs, setNames(list("-"), pick))
    session$setInputs(accept_ghost = "GHOST_1")
    expect_equal(nrow(rv$network_nodes), nrow(nodes_before) + 1)
    expect_equal(nrow(rv$network_edges), 1)
    expect_identical(rv$network_edges$polarity, "-")
    expect_identical(rv$network_edges$from, first)
    expect_identical(rv$network_edges$to, rv$network_nodes$id[nrow(rv$network_nodes)])
    expect_false(grepl("common.polarity.unset", rv$network_edges$title, fixed = TRUE))
    expect_equal(rv$network_edges$color,
                 adjustcolor(EDGE_COLORS$opposing, alpha.f = GHOST_EDGE_OPACITY))
    expect_equal(nrow(rv$ghost_nodes), 0)

    # a later expansion reuses GHOST_1: the earlier pick must not carry over
    session$setInputs(expand_node = 2)
    expect_gt(nrow(rv$ghost_nodes), 0)
    n_nodes <- nrow(rv$network_nodes)
    session$setInputs(accept_ghost = "GHOST_1")
    expect_equal(nrow(rv$network_nodes), n_nodes)
    expect_equal(nrow(rv$network_edges), 1)
  })
})

test_that("an evidenced ghost is added directly with its sign and citation", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020", strength = "strong"))
  local_global("ML_AVAILABLE", FALSE)
  testServer(graphical_ses_creator_server, args = list(
    project_data_reactive = reactiveVal(list()), i18n = make_test_i18n()), {
    start_network(session, rv)
    n_nodes <- nrow(rv$network_nodes)
    session$setInputs(node_clicked = "GHOST_1")
    expect_equal(nrow(rv$network_nodes), n_nodes + 1)
    expect_identical(rv$network_edges$polarity, "-")
    expect_identical(rv$network_edges$polarity_source, "Smith 2020")
  })
})

test_that("the suggestion panel shows the picker for unsigned and the citation for evidenced ghosts", {
  local_global("ML_AVAILABLE", FALSE)
  for (case in list(list(kb = NULL, picker = TRUE),
                    list(kb = list(polarity = "+", match_quality = "exact", source = "Smith 2020"),
                         picker = FALSE))) {
    stub_kb(case$kb)
    testServer(graphical_ses_creator_server, args = list(
      project_data_reactive = reactiveVal(list()), i18n = make_test_i18n()), {
      start_network(session, rv)
      html <- output$details_content$html
      expect_match(html, "common.polarity.choose_sign", fixed = TRUE)
      expect_match(html, session$ns(graphical_ghost_sign_id(rv$ghost_batch, "GHOST_1")), fixed = TRUE)
      if (case$picker) {
        expect_false(grepl("Smith 2020", html, fixed = TRUE))
      } else {
        expect_match(html, "common.polarity.from_source Smith 2020", fixed = TRUE)
      }
    })
  }
})

test_that("infer_connection_polarity and get_rule_default_polarity are gone", {
  expect_false(exists("infer_connection_polarity"))
  expect_false(exists("get_rule_default_polarity"))
})
