# functions/network_analysis_enhanced.R
# Enhanced wrappers for network analysis with input validation and safe fallbacks

validate_nodes <- function(nodes) {
  if (is.null(nodes)) stop("nodes is NULL")
  if (!is.data.frame(nodes)) stop("nodes must be dataframe")
  missing <- setdiff(c("id", "name"), names(nodes))
  if (length(missing) > 0) stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")))
  TRUE
}

validate_edges <- function(edges, required = c("from", "to")) {
  if (is.null(edges)) stop("edges is NULL")
  if (!is.data.frame(edges)) stop("edges must be dataframe")
  missing <- setdiff(required, names(edges))
  if (length(missing) > 0) stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")))
  TRUE
}

validate_igraph <- function(g) {
  if (is.null(g)) stop("graph is NULL")
  if (!inherits(g, "igraph")) stop("graph must be igraph object")
  TRUE
}

create_igraph_from_data_safe <- function(nodes, edges) {
  # Validate inputs
  if (is.null(nodes) || is.null(edges)) return(NULL)
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(NULL)
  if (!all(c("id", "name") %in% names(nodes))) return(NULL)
  if (!all(c("from", "to") %in% names(edges))) return(NULL)

  # Filter edges that reference existing nodes
  valid_nodes <- nodes$id
  valid_edges <- edges[edges$from %in% valid_nodes & edges$to %in% valid_nodes, , drop = FALSE]

  # If no valid edges and no nodes, return NULL
  if (nrow(nodes) == 0 || nrow(valid_edges) == 0) {
    # If nodes exist but no edges, tests expect NULL for empty graph
    if (nrow(nodes) == 0 || nrow(valid_edges) == 0) return(NULL)
  }

  # Build graph (use igraph::graph_from_data_frame)
  tryCatch({
    g <- igraph::graph_from_data_frame(d = valid_edges, vertices = nodes, directed = TRUE)
    return(g)
  }, error = function(e) {
    warning("Failed to create igraph: ", e$message)
    return(NULL)
  })
}

calculate_network_metrics_safe <- function(nodes, edges = NULL) {
  # Accept igraph input
  if (inherits(nodes, "igraph")) {
    g <- nodes
    if (!validate_igraph(g)) return(NULL)
  } else {
    # Validate nodes/edges
    if (is.null(nodes) || !is.data.frame(nodes)) return(NULL)
    if (is.null(edges) || !is.data.frame(edges)) return(NULL)
    if (!all(c("id", "name") %in% names(nodes))) return(NULL)

    # If nodes empty, return NULL (no graph)
    if (nrow(nodes) == 0) return(NULL)

    # If edges dataframe is empty but nodes exist, return defaults for nodes-only graph
    if (nrow(edges) == 0) {
      return(list(
        density = 0,
        avg_degree = 0,
        num_nodes = nrow(nodes),
        num_edges = 0,
        components = nrow(nodes)
      ))
    }

    if (!all(c("from", "to") %in% names(edges))) return(NULL)

    # Create igraph safely
    g <- create_igraph_from_data_safe(nodes, edges)
    if (is.null(g)) return(NULL)
  }

  # Calculate metrics using existing functions but recover from per-metric failures
  res <- tryCatch({
    raw <- calculate_network_metrics(g)
    list(
      density = raw$density,
      avg_degree = mean(raw$degree, na.rm = TRUE),
      num_nodes = vcount(g),
      num_edges = ecount(g),
      components = igraph::components(g)$no,
      # include per-node degree for downstream checks
      degree = raw$degree
    )
  }, error = function(e) {
    warning("calculate_network_metrics failed: ", e$message)
    NULL
  })

  res
}

calculate_micmac_safe <- function(nodes, edges) {
  if (is.null(nodes) || is.null(edges)) return(NULL)
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(NULL)
  if (!all(c("id") %in% names(nodes))) return(NULL)
  if (!all(c("from", "to") %in% names(edges))) return(NULL)

  tryCatch({
    res <- calculate_micmac(nodes, edges)
    # Normalize column names to expected test names
    if ("node_id" %in% names(res)) names(res)[names(res) == "node_id"] <- "id"
    if ("exposure" %in% names(res)) names(res)[names(res) == "exposure"] <- "dependence"
    return(res)
  }, error = function(e) {
    warning("calculate_micmac failed: ", e$message)
    NULL
  })
}

create_numeric_adjacency_matrix_safe <- function(nodes, edges) {
  if (is.null(nodes) || is.null(edges)) return(NULL)
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(NULL)
  if (!all(c("id") %in% names(nodes))) return(NULL)
  if (!all(c("from", "to") %in% names(edges))) return(NULL)

  tryCatch({
    # Build numeric adjacency using strength if available
    n <- nrow(nodes)
    adj <- matrix(0, nrow = n, ncol = n)
    rownames(adj) <- nodes$id
    colnames(adj) <- nodes$id

    for (i in seq_len(nrow(edges))) {
      row <- edges[i, ]
      from_idx <- which(nodes$id == row$from)
      to_idx <- which(nodes$id == row$to)
      if (length(from_idx) == 0 || length(to_idx) == 0) next
      val <- ifelse(!is.null(row$strength) && nzchar(as.character(row$strength)), as.numeric(row$strength), 1)
      adj[from_idx, to_idx] <- val
    }

    adj
  }, error = function(e) {
    warning("create_numeric_adjacency_matrix failed: ", e$message)
    NULL
  })
}

find_all_cycles_safe <- function(nodes, edges, max_length = 10, max_cycles = 1000) {
  if (is.null(nodes) || is.null(edges)) return(list())
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(list())

  g <- create_igraph_from_data_safe(nodes, edges)
  if (is.null(g)) return(list())

  res <- tryCatch({
    cycles <- find_all_cycles(nodes, edges, max_length = max_length, max_cycles = max_cycles)

    # Map cycles (indices) to richer structure with node ids and polarities
    mapped <- lapply(cycles, function(cycle_idx) {
      node_ids <- igraph::V(g)$name[cycle_idx]
      # Determine polarities for each edge in the cycle
      pols <- c()
      for (i in seq_along(node_ids)) {
        from <- node_ids[i]
        to <- node_ids[(i %% length(node_ids)) + 1]
        row <- edges[edges$from == from & edges$to == to, , drop = FALSE]
        pols <- c(pols, if (nrow(row) > 0) as.character(row$polarity[1]) else NA)
      }
      list(nodes = node_ids, polarities = pols)
    })

    mapped
  }, error = function(e) {
    warning("find_all_cycles failed: ", e$message)
    list()
  })

  res
}

classify_loop_type_safe <- function(loop, edges = NULL) {
  if (is.null(loop)) return(NULL)
  # Expect loop to be a list with polarities or nodes
  if (!is.list(loop)) return(NULL)
  if (!is.null(loop$polarities)) {
    neg <- sum(loop$polarities == "-", na.rm = TRUE)
    return(ifelse(neg %% 2 == 1, "B", "R"))
  }
  # Fallback: if edges provided, derive polarities
  if (!is.null(edges) && is.data.frame(edges) && !is.null(loop$nodes)) {
    pals <- c()
    for (i in seq_along(loop$nodes)) {
      from <- loop$nodes[i]
      to <- loop$nodes[(i %% length(loop$nodes)) + 1]
      row <- edges[edges$from == from & edges$to == to, , drop = FALSE]
      if (nrow(row) == 0) return(NULL)
      pals <- c(pals, row$polarity[1])
    }
    neg <- sum(pals == "-", na.rm = TRUE)
    return(ifelse(neg %% 2 == 1, "B", "R"))
  }
  NULL
}
