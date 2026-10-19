# functions/scenario_network.R
# =============================================================================
# Pure scenario-network helpers shared by the Scenario Builder, the Designer
# (WS-7b Apply / Compare) and the designer's callr compare worker. No Shiny,
# no constants.R, no %||% (the worker has none of them).
# =============================================================================

# rbind two data frames, filling columns missing on either side with NA
.scenario_bind_rows <- function(a, b) {
  if (is.null(a) || !nrow(a)) return(b)
  if (is.null(b) || !nrow(b)) return(a)
  for (col in setdiff(names(a), names(b))) b[[col]] <- NA
  for (col in setdiff(names(b), names(a))) a[[col]] <- NA
  rbind(a, b[, names(a), drop = FALSE])
}

# Label of a node id (the id itself when unknown)
.scenario_label <- function(node_id, nodes) {
  hit <- nodes$label[nodes$id == node_id]
  if (length(hit)) hit[1] else node_id
}

# Edges with an id column; a missing id becomes "from->to"
.scenario_with_edge_ids <- function(edges) {
  if (!is.null(edges) && nrow(edges) && !"id" %in% names(edges)) {
    edges$id <- make.unique(paste0(edges$from, "->", edges$to))
  }
  edges
}

#' Baseline edges with an id and from/to labels on every row.
#' The saved CLD (create_edges_df) carries neither; the Scenario Builder needs
#' both to list and remove links. A missing id becomes "from->to", which stays
#' stable when the CLD editor renumbers its own edge ids. Existing values are kept.
#' @return data frame of edges (zero rows when the CLD has none)
scenario_baseline_edges <- function(cld) {
  edges <- cld$edges
  if (is.null(edges) || !nrow(edges)) {
    return(data.frame(id = character(0), from = character(0), to = character(0),
                      from_label = character(0), to_label = character(0),
                      stringsAsFactors = FALSE))
  }
  edges <- .scenario_with_edge_ids(edges)
  labels <- function(ids) vapply(as.character(ids), .scenario_label, "", nodes = cld$nodes,
                                 USE.NAMES = FALSE)
  if (!"from_label" %in% names(edges)) edges$from_label <- labels(edges$from)
  if (!"to_label" %in% names(edges)) edges$to_label <- labels(edges$to)
  edges
}

#' Apply a scenario's modifications to a baseline CLD.
#' links_modified entries are matched by from/to node ids, never by edge id:
#' the CLD editor renumbers edge ids (spec 2026-10-15 5.2).
#' @return list(nodes, edges)
scenario_apply_modifications <- function(baseline_cld, modifications) {
  nodes <- baseline_cld$nodes
  edges <- .scenario_with_edge_ids(baseline_cld$edges)
  if (length(modifications$nodes_removed) > 0) {
    nodes <- nodes[!nodes$id %in% modifications$nodes_removed, , drop = FALSE]
    edges <- edges[!edges$from %in% modifications$nodes_removed &
                   !edges$to %in% modifications$nodes_removed, , drop = FALSE]
  }
  if (length(modifications$nodes_added) > 0) {
    new_nodes <- do.call(rbind, lapply(modifications$nodes_added, function(n) {
      data.frame(id = n$id, label = n$label, group = n$dapsi, dapsi = n$dapsi,
                 description = if (is.null(n$description)) "" else n$description,
                 stringsAsFactors = FALSE)
    }))
    nodes <- .scenario_bind_rows(nodes, new_nodes)
  }
  if (length(modifications$links_removed) > 0 && !is.null(edges) && nrow(edges)) {
    edges <- edges[!as.character(edges$id) %in% as.character(modifications$links_removed), , drop = FALSE]
  }
  for (l in modifications$links_modified) {
    hit <- edges$from == l$from & edges$to == l$to
    if (any(hit)) {
      edges$polarity[hit] <- l$polarity
      edges$strength[hit] <- l$strength
    }
  }
  if (length(modifications$links_added) > 0) {
    new_edges <- do.call(rbind, lapply(modifications$links_added, function(l) {
      data.frame(id = l$id, from = l$from, to = l$to,
                 from_label = .scenario_label(l$from, nodes), to_label = .scenario_label(l$to, nodes),
                 polarity = if (is.null(l$polarity)) "+" else l$polarity,
                 strength = if (is.null(l$strength)) "medium" else l$strength,
                 stringsAsFactors = FALSE)
    }))
    edges <- .scenario_bind_rows(edges, new_edges)
  }
  rownames(nodes) <- NULL
  rownames(edges) <- NULL
  list(nodes = nodes, edges = edges)
}

#' Feedback loops of a scenario network (review 2026-10-07 N33)
#'
#' Uses the shared cycle finder with the Loops tab defaults (no self-loops or
#' 2-node cycles) and returns loop objects the "Affected loops" panel can show.
#' @param network list(nodes, edges) in CLD shape
#' @return list(count = integer, loops = list of list(type, nodes))
scenario_loops <- function(network) {
  empty <- list(count = 0L, loops = list())
  if (is.null(network) || !is.data.frame(network$edges) || nrow(network$edges) == 0 ||
      !is.data.frame(network$nodes) || nrow(network$nodes) == 0) return(empty)
  tryCatch({
    cycles <- find_all_cycles(network$nodes, network$edges, max_length = 8, max_cycles = 500,
                              timeout_seconds = if (exists("LOOP_ANALYSIS_TIMEOUT_SECONDS")) LOOP_ANALYSIS_TIMEOUT_SECONDS else 30)
    cycles <- Filter(function(l) length(l) > 2, cycles)
    if (length(cycles) == 0) return(empty)
    # same builder find_all_cycles uses, so cycle vertex indices line up
    g <- create_igraph_from_data(network$nodes, network$edges)
    info <- process_cycles_to_loops(cycles, network$nodes, network$edges, g, validate_dapsirwrm = FALSE)
    if (!is.data.frame(info) || nrow(info) == 0) return(empty)
    loops <- lapply(seq_len(nrow(info)), function(i) list(
      type = as.character(info$Type[i]),
      nodes = trimws(strsplit(as.character(info$Elements[i]), "→", fixed = TRUE)[[1]])
    ))
    list(count = length(loops), loops = loops)
  }, error = function(e) {
    if (exists("debug_log", mode = "function")) debug_log(sprintf("scenario_loops: %s", conditionMessage(e)), "SCENARIO-BUILDER")
    empty
  })
}
