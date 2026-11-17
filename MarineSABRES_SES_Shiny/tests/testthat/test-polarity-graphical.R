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
  tags <- vapply(c(topo, chain), function(s) s$strategy_tag, character(1))
  expect_true(all(c("COMPLETENESS", "CHAIN_COMPLETION", "BRIDGE") %in% tags))
  for (tg in c("COMPLETENESS", "CHAIN_COMPLETION", "BRIDGE")) {
    expect_true(all(is.na(pols(c(topo, chain)[tags == tg]))), info = tg)
  }
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

# Words that name or imply a sign in the rule-table descriptions and loop labels
sign_words <- "negativ|mitigat|enhanc|reduc|increas|decreas|demand|generat|harm|degrad|balancing|reinforcing"
rule_descriptions <- vapply(DAPSIWRM_ADJACENCY_RULES, function(r) r$description, character(1))
# tooltip text without the element name (names are user/KB data, not hints)
tooltip_text <- function(ghost) sub("<b>[^<]*</b>", "", ghost$title)
expect_no_sign_hint <- function(text, info = NULL) {
  for (d in rule_descriptions) expect_false(grepl(d, text, fixed = TRUE), info = paste(info, d))
  expect_false(grepl(sign_words, text, ignore.case = TRUE), info = paste(info, text))
}

test_that("unsigned reasoning never shows a rule description or sign word", {
  for (f in names(DAPSIWRM_ADJACENCY_RULES)) {
    r <- DAPSIWRM_ADJACENCY_RULES[[f]]
    for (t in unique(c(r$targets, r$extension_targets))) {
      txt <- generate_suggestion_reasoning("a", "b", f, t, NA_character_, "strong")
      expect_match(txt, "affects", fixed = TRUE)
      expect_no_sign_hint(txt, paste(f, "->", t))
    }
  }
  # once a sign is evidenced the description may be shown
  expect_match(generate_suggestion_reasoning("a", "b", "Pressures", "Marine Processes & Functioning",
                                             "-", "strong"),
               rule_descriptions[["Pressures"]], fixed = TRUE)
})

test_that("unsigned ghost tooltips carry no sign hint (real suggestions, real tooltip)", {
  stub_kb(NULL)
  net <- data.frame(id = c("P_1", "R_1", "D_1", "GB_1"),
                    name = c("Seabed abrasion", "Gear rules", "Food demand", "Fish income"),
                    type = c("Pressures", "Responses", "Drivers", "Goods & Benefits"),
                    stringsAsFactors = FALSE)
  for (src in list(list(id = "P_1", name = "Seabed abrasion", type = "Pressures"),
                   list(id = "R_1", name = "Gear rules", type = "Responses"))) {
    g <- suggest_connected_elements(src$id, list(name = src$name, type = src$type), net, ctx,
                                    max_suggestions = 10)
    expect_gt(length(g), 0)
    for (i in seq_along(g)) {
      expect_true(is.na(g[[i]]$connection_polarity))
      expect_no_sign_hint(tooltip_text(create_ghost_node_data(g[[i]], i, i18n = make_test_i18n())),
                          paste(src$type, g[[i]]$name))
    }
  }
})

test_that("an unsigned loop ghost does not name its loop type; an evidenced one may", {
  net <- data.frame(id = c("R_1", "D_1"), name = c("Fishing quota", "Food demand"),
                    type = c("Responses", "Drivers"), stringsAsFactors = FALSE)
  loop_of <- function() {
    topo <- analyze_network_topology_for_suggestions(
      "R_1", list(name = "Gear rules", type = "Responses"), net, get_allowed_targets("Responses"), ctx)
    Filter(function(s) identical(s$strategy_tag, "FEEDBACK_LOOP"), topo)
  }
  stub_kb(NULL)
  loops <- loop_of()
  expect_gt(length(loops), 0)
  for (s in loops) {
    expect_true(s$loop_type %in% c("balancing", "reinforcing"))     # kept as data
    expect_false(grepl("balancing|reinforcing", s$reasoning))
    expect_no_sign_hint(tooltip_text(create_ghost_node_data(s, 1, i18n = make_test_i18n())), s$name)
  }
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020"))
  for (s in loop_of()) expect_match(s$reasoning, s$loop_type, fixed = TRUE)
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
    expect_identical(rv$network_edges, edges_before)
    expect_gt(nrow(rv$ghost_nodes), 0)
    # the picker for that ghost is brought into view: its node's suggestions are listed
    expect_identical(rv$sign_needed_ghost, "GHOST_1")
    expect_identical(rv$selected_node_id, rv$expanded_node_id)
    expect_match(output$details_content$html,
                 session$ns(graphical_ghost_sign_id(rv$ghost_batch, "GHOST_1")), fixed = TRUE)

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
    expect_null(rv$sign_needed_ghost)                        # cleared once that ghost is accepted
    node_title <- rv$network_nodes$title[nrow(rv$network_nodes)]
    expect_false(grepl("unset|Click to accept|Connection:", node_title))

    # a later expansion reuses GHOST_1: the earlier pick must not carry over
    session$setInputs(expand_node = 2)
    expect_gt(nrow(rv$ghost_nodes), 0)
    n_nodes <- nrow(rv$network_nodes)
    session$setInputs(accept_ghost = "GHOST_1")
    expect_equal(nrow(rv$network_nodes), n_nodes)
    expect_equal(nrow(rv$network_edges), 1)
    expect_identical(rv$sign_needed_ghost, "GHOST_1")
    session$setInputs(expand_node = 3)                       # a new expansion clears it
    expect_null(rv$sign_needed_ghost)
    session$setInputs(accept_ghost = "GHOST_1")
    expect_identical(rv$sign_needed_ghost, "GHOST_1")
    session$setInputs(clear_ghosts = 1)                      # dismissing the suggestions clears it
    expect_null(rv$sign_needed_ghost)
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

test_that("changing an evidenced sign keeps the user's sign and drops the citation", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020", strength = "strong"))
  local_global("ML_AVAILABLE", FALSE)
  testServer(graphical_ses_creator_server, args = list(
    project_data_reactive = reactiveVal(list()), i18n = make_test_i18n()), {
    start_network(session, rv)
    pid <- graphical_ghost_sign_id(rv$ghost_batch, "GHOST_1")
    src_id <- paste0(pid, "_source")
    # the element the citation toggle targets is the one the panel renders
    expect_match(output$details_content$html, paste0('id="', session$ns(src_id), '"'), fixed = TRUE)
    session$flushReact()
    expect_true(rv$citation_states[[src_id]])                # evidenced sign: citation shown
    do.call(session$setInputs, setNames(list("-"), pid))
    expect_true(rv$citation_states[[src_id]])                # same sign picked: still shown
    do.call(session$setInputs, setNames(list("+"), pid))
    expect_false(rv$citation_states[[src_id]])               # changed: citation hidden
    ghost_title <- rv$ghost_nodes$title[rv$ghost_nodes$id == "GHOST_1"]
    expect_match(ghost_title, "decreases", fixed = TRUE)     # the ghost described the "-"
    session$setInputs(accept_ghost = "GHOST_1")
    expect_equal(nrow(rv$network_edges), 1)
    expect_identical(rv$network_edges$polarity, "+")
    expect_identical(rv$network_edges$polarity_source, NA_character_)
    # the accepted node no longer carries the ghost's sign wording or accept prompt
    node_title <- rv$network_nodes$title[rv$network_nodes$id == rv$network_edges$to]
    expect_false(grepl("unset|negativ|decreases|Click to accept|Connection:", node_title))
    expect_match(node_title, "modules.graphical_ses_creator.node_tooltip_type", fixed = TRUE)
    expect_equal(rv$network_edges$color,
                 adjustcolor(EDGE_COLORS$reinforcing, alpha.f = GHOST_EDGE_OPACITY))
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
        expect_false(grepl("checked", html, fixed = TRUE))   # nothing preselected
      } else {
        expect_match(html, "common.polarity.from_source Smith 2020", fixed = TRUE)
        expect_match(html, "checked", fixed = TRUE)          # evidenced sign preselected
      }
    })
  }
})

test_that("a vote logs the user's picked sign, not the evidenced one", {
  stub_kb(list(polarity = "-", match_quality = "exact", source = "Smith 2020"))
  local_global("ML_AVAILABLE", FALSE)
  logged <- list()
  local_global("log_connection_feedback", function(...) logged[[length(logged) + 1]] <<- list(...))
  testServer(graphical_ses_creator_server, args = list(
    project_data_reactive = reactiveVal(list()), i18n = make_test_i18n()), {
    start_network(session, rv)
    session$setInputs(ml_feedback = list(id = "GHOST_1", vote = "up", n = 1))
    do.call(session$setInputs, setNames(list("+"), graphical_ghost_sign_id(rv$ghost_batch, "GHOST_1")))
    session$setInputs(ml_feedback = list(id = "GHOST_1", vote = "up", n = 2))
  })
  expect_length(logged, 2)
  expect_identical(logged[[1]]$ml_prediction$polarity, "-")        # the suggestion's evidenced sign
  expect_identical(logged[[1]]$user_properties$polarity, NA_character_)  # nothing picked yet
  expect_identical(logged[[2]]$user_properties$polarity, "+")      # the user's pick
})

test_that("the ISA export tells the user how many unsigned edges it left out", {
  notes <- character(0)
  local_global("showNotification", function(ui, ...) notes <<- c(notes, paste(as.character(ui), collapse = "")))
  tr <- list(t = function(key, ...) if (identical(key, "common.polarity.export_left_out_unsigned"))
    "%d unsigned left out" else key)
  pd <- reactiveVal(list())
  testServer(graphical_ses_creator_server, args = list(project_data_reactive = pd, i18n = tr), {
    rv$network_nodes <- data.frame(id = c("D_1", "A_1", "P_1"), name = c("Food demand", "Trawling", "Abrasion"),
                                   type = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE)
    rv$network_edges <- data.frame(id = c("E1", "E2"), from = c("D_1", "A_1"), to = c("A_1", "P_1"),
                                   polarity = c(NA, "-"), strength = "medium", confidence = 3,
                                   stringsAsFactors = FALSE)
    session$setInputs(export_isa = 1)
  })
  expect_true("1 unsigned left out" %in% notes)
  am <- pd()$data$isa_data$adjacency_matrices
  expect_null(am$d_a)
  expect_equal(am$a_p["A001", "P001"], "-medium:3")
})

test_that("infer_connection_polarity and get_rule_default_polarity are gone", {
  expect_false(exists("infer_connection_polarity"))
  expect_false(exists("get_rule_default_polarity"))
})

test_that("unsigned ghost reasoning goes through the translator (final review M1)", {
  stub_kb(NULL)
  tr <- list(t = function(key, ...) paste0("T:", key))
  txt <- generate_suggestion_reasoning("a", "b", "Drivers", "Activities", NA_character_, "strong", i18n = tr)
  expect_match(txt, "T:common.polarity.affects", fixed = TRUE)
  expect_false(grepl(" affects ", txt, fixed = TRUE))
  net <- data.frame(id = c("R_1", "D_1", "A_2"), name = c("Fishing quota", "Food demand", "Shipping"),
                    type = c("Responses", "Drivers", "Activities"), stringsAsFactors = FALSE)
  topo <- analyze_network_topology_for_suggestions(
    "R_1", list(name = "Gear rules", type = "Responses"), net, get_allowed_targets("Responses"), ctx,
    i18n = tr)
  loops <- Filter(function(s) identical(s$strategy_tag, "FEEDBACK_LOOP"), topo)
  expect_gt(length(loops), 0)
  expect_true(all(vapply(loops, function(s) s$reasoning, "") == "T:common.polarity.closes_loop"))
  # suggest_connected_elements hands the translator on
  sugg <- suggest_connected_elements("R_1", list(name = "Gear rules", type = "Responses"), net, ctx,
                                     i18n = tr)
  unsigned <- Filter(function(s) is.na(s$connection_polarity) && is.null(s$strategy_tag), sugg)
  if (length(unsigned) > 0) {
    expect_true(all(grepl("T:common.polarity.affects", vapply(unsigned, function(s) s$reasoning, ""), fixed = TRUE)))
  }
  loops2 <- Filter(function(s) identical(s$strategy_tag, "FEEDBACK_LOOP"), sugg)
  if (length(loops2) > 0) {
    expect_true(all(vapply(loops2, function(s) s$reasoning, "") == "T:common.polarity.closes_loop"))
  }
})
