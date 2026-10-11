# tests/testthat/test-template-response-loops.R
# Decision Lens found no archetypes in the Fisheries (Baltic) template because
# no Response sat in any loop: Responses only received Measure -> Response links,
# nothing closed the D -> ... -> GB chain back onto a Response. Goods & Benefits ->
# Response links (DAPSIWRM rule 8) were added to four templates. They are
# benefit-worded, so polarity "-" (less benefit, stronger response) and every
# loop they close must be Balancing.
source_for_test(c("functions/template_loader.R", "functions/decision_lens.R"))

tpl_path <- function(name) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "data", paste0(name, "_SES_Template.json"))
    if (file.exists(p)) return(p)
  }
  stop("template not found: ", name)
}

template_loops <- function(name) {
  tpl <- load_template_from_json(tpl_path(name), use_cache = FALSE)
  isa <- list(drivers = tpl$drivers, activities = tpl$activities, pressures = tpl$pressures,
              marine_processes = tpl$marine_processes, ecosystem_services = tpl$ecosystem_services,
              goods_benefits = tpl$goods_benefits, responses = tpl$responses,
              adjacency_matrices = tpl$adjacency_matrices)
  nodes <- create_nodes_df(isa)
  edges <- create_edges_df(isa, isa$adjacency_matrices)
  gph <- igraph::graph_from_data_frame(edges[, c("from", "to", "polarity")], directed = TRUE,
                                       vertices = nodes[, c("id", "label", "group")])
  loops <- find_all_cycles(nodes, edges, max_length = 8, max_cycles = 500, timeout_seconds = 30)
  loops <- Filter(function(l) length(l) > 2, loops)
  li <- process_cycles_to_loops(loops, nodes, edges, gph)
  list(nodes = nodes, loop_info = li, archetypes = detect_archetypes(li, nodes))
}

loops_with_response <- function(li) {
  if (is.null(li) || nrow(li) == 0) return(li)
  has_r <- vapply(li$NodeIDs, function(s) any(dl_code_from_id(.dl_loop_nodes(s)) == "R"), logical(1))
  li[has_r, , drop = FALSE]
}

test_that("Fisheries (Baltic) template: Decision Lens finds Limits to Growth at the cod quota", {
  res <- template_loops("Fisheries")
  keys <- vapply(res$archetypes, `[[`, "", "archetype_key")
  expect_true("limits_to_growth" %in% keys)
  ltg <- res$archetypes[keys == "limits_to_growth"]
  lev_labels <- res$nodes$label[match(vapply(ltg, `[[`, "", "leverage_node_id"), res$nodes$id)]
  lev_labels <- gsub("[[:space:]]+", " ", lev_labels)   # CLD labels are line-wrapped
  expect_true(any(grepl("cod fishing quota", lev_labels, fixed = TRUE)), info = paste(lev_labels, collapse = " | "))
})

test_that("each edited template has a loop through a Response, and all such loops are Balancing", {
  for (name in c("Fisheries", "Aquaculture", "Pollution", "Tourism")) {
    r_loops <- loops_with_response(template_loops(name)$loop_info)
    expect_gt(NROW(r_loops), 0)
    expect_true(all(r_loops$Type == "Balancing"), info = name)
  }
})

test_that("the GB -> Response links are benefit-worded with '-' polarity", {
  for (name in c("Fisheries", "Aquaculture", "Pollution", "Tourism")) {
    d <- jsonlite::fromJSON(tpl_path(name), simplifyVector = FALSE)
    gbr <- Filter(function(x) x$from_type == "welfare" && x$to_type == "response", d$connections)
    expect_length(gbr, 1)
    expect_identical(gbr[[1]]$polarity, "-", info = name)
    expect_identical(d$metadata$version, "2.1", info = name)
  }
})
