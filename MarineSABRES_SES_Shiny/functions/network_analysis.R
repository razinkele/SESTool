# functions/network_analysis.R
# Network analysis functions for loop detection and metrics calculation
# Note: igraph is loaded in global.R

# ============================================================================
# NETWORK METRICS FUNCTIONS
# ============================================================================

#' Calculate all network metrics
#'
#' @param nodes Nodes dataframe OR igraph object
#' @param edges Edges dataframe (optional if nodes is an igraph object)
#' @return List of metric vectors
calculate_network_metrics <- function(nodes, edges = NULL) {

  # Handle different input types
  if (inherits(nodes, "igraph")) {
    # If nodes is actually an igraph object
    g <- nodes
  } else {
    # Create igraph object from data
    g <- create_igraph_from_data(nodes, edges)
  }

  # Calculate metrics
  if (vcount(g) == 0) {
    return(list(
      nodes = 0,
      edges = 0,
      density = 0,
      diameter = 0,
      avg_path_length = 0
    ))
  }

  # Calculate graph-level metrics
  metrics <- list(
    nodes = vcount(g),
    edges = ecount(g),
    density = edge_density(g),
    diameter = tryCatch(diameter(g, directed = TRUE), error = function(e) 0),
    avg_path_length = tryCatch(mean_distance(g, directed = TRUE), error = function(e) 0),
    # Node-level centrality metrics
    degree = degree(g, mode = "all"),
    indegree = degree(g, mode = "in"),
    outdegree = degree(g, mode = "out"),
    betweenness = betweenness(g, directed = TRUE),
    closeness = closeness(g, mode = "all"),
    eigenvector = tryCatch(eigen_centrality(g, directed = TRUE)$vector, error = function(e) rep(0, vcount(g))),
    pagerank = page_rank(g)$vector
  )

  return(metrics)
}

#' Create igraph object from nodes and edges
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return igraph object
create_igraph_from_data <- function(nodes, edges) {

  # Validate that all edges reference existing nodes
  valid_node_ids <- nodes$id

  # Filter edges to only include those referencing existing nodes
  valid_edges <- edges %>%
    filter(from %in% valid_node_ids & to %in% valid_node_ids)

  if (nrow(valid_edges) < nrow(edges)) {
    invalid_count <- nrow(edges) - nrow(valid_edges)
    warning(sprintf(
      "Removed %d edges referencing non-existent nodes. Check data consistency.",
      invalid_count
    ))
  }

  if (nrow(valid_edges) == 0) {
    stop("No valid edges found after filtering. Cannot create graph.")
  }

  # Select required columns, include confidence if present
  required_cols <- c("from", "to", "polarity", "strength")
  if ("confidence" %in% names(valid_edges)) {
    required_cols <- c(required_cols, "confidence")
  }

  graph_from_data_frame(
    valid_edges[, required_cols, drop = FALSE],
    directed = TRUE,
    vertices = nodes
  )
}

#' Calculate MICMAC analysis
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return Dataframe with influence and exposure scores
calculate_micmac <- function(nodes, edges) {

  tryCatch({
    # Input validation
    if (is.null(nodes) || nrow(nodes) == 0) {
      stop("Nodes dataframe is empty or NULL")
    }
    if (is.null(edges) || nrow(edges) == 0) {
      warning("Edges dataframe is empty - returning zero influence/exposure")
      return(data.frame(
        node_id = nodes$id,
        influence = 0,
        exposure = 0,
        quadrant = "Autonomous",
        stringsAsFactors = FALSE
      ))
    }
    if (!"id" %in% names(nodes)) {
      stop("Nodes dataframe must have 'id' column")
    }
    if (!all(c("from", "to") %in% names(edges))) {
      stop("Edges dataframe must have 'from' and 'to' columns")
    }

    # Create adjacency matrix
    adj <- create_numeric_adjacency_matrix(nodes, edges)

    # Calculate direct influence and exposure
    influence_direct <- rowSums(adj != 0)
    exposure_direct <- colSums(adj != 0)

    # Calculate indirect influence (matrix multiplication)
    adj_squared <- adj %*% adj
    influence_indirect <- rowSums(adj_squared != 0)
    exposure_indirect <- colSums(adj_squared != 0)

    # Total influence and exposure
    micmac <- data.frame(
      node_id = nodes$id,
      influence = influence_direct + influence_indirect,
      exposure = exposure_direct + exposure_indirect,
      stringsAsFactors = FALSE
    )

    # Classify nodes into quadrants
    median_influence <- median(micmac$influence)
    median_exposure <- median(micmac$exposure)

    micmac$quadrant <- case_when(
      micmac$influence > median_influence & micmac$exposure > median_exposure ~ "Relay",
      micmac$influence > median_influence & micmac$exposure <= median_exposure ~ "Influential",
      micmac$influence <= median_influence & micmac$exposure > median_exposure ~ "Dependent",
      TRUE ~ "Autonomous"
    )

    return(micmac)

  }, error = function(e) {
    stop(paste("Error in MICMAC analysis:", e$message))
  })
}

#' Create numeric adjacency matrix from edges
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return Numeric matrix
create_numeric_adjacency_matrix <- function(nodes, edges) {

  tryCatch({
    # Input validation
    if (is.null(nodes) || nrow(nodes) == 0) {
      stop("Nodes dataframe is empty or NULL")
    }
    if (is.null(edges) || nrow(edges) == 0) {
      # Return empty matrix if no edges
      n <- nrow(nodes)
      adj <- matrix(0, nrow = n, ncol = n)
      rownames(adj) <- nodes$id
      colnames(adj) <- nodes$id
      return(adj)
    }
    if (!"id" %in% names(nodes)) {
      stop("Nodes dataframe must have 'id' column")
    }
    if (!all(c("from", "to") %in% names(edges))) {
      stop("Edges dataframe must have 'from' and 'to' columns")
    }

    n <- nrow(nodes)
    adj <- matrix(0, nrow = n, ncol = n)
    rownames(adj) <- nodes$id
    colnames(adj) <- nodes$id

    for (i in 1:nrow(edges)) {
      from_idx <- which(nodes$id == edges$from[i])
      to_idx <- which(nodes$id == edges$to[i])

      # Validate indices
      if (length(from_idx) == 0 || length(to_idx) == 0) {
        warning(paste("Edge", i, "references non-existent node. Skipping."))
        next
      }

      adj[from_idx, to_idx] <- 1
    }

    return(adj)

  }, error = function(e) {
    stop(paste("Error creating adjacency matrix:", e$message))
  })
}

# ============================================================================
# LOOP DETECTION FUNCTIONS
# ============================================================================

#' Find all simple cycles in the network
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param max_length Maximum cycle length to detect
#' @return List of cycles (vectors of node IDs)
find_all_cycles <- function(nodes, edges, max_length = 10) {
  
  # Create igraph object
  g <- create_igraph_from_data(nodes, edges)
  
  # Get all strongly connected components
  scc <- components(g, mode = "strong")
  
  cycles <- list()
  
  # Process each component
  for (comp_id in unique(scc$membership)) {
    comp_nodes <- which(scc$membership == comp_id)
    
    if (length(comp_nodes) > 1) {
      # Extract subgraph
      subg <- induced_subgraph(g, comp_nodes)
      
      # Find cycles in this component
      comp_cycles <- find_cycles_dfs(subg, max_length)
      
      cycles <- c(cycles, comp_cycles)
    }
  }
  
  return(cycles)
}

#' Find cycles using depth-first search
#' 
#' @param graph igraph object
#' @param max_length Maximum cycle length
#' @return List of cycles
find_cycles_dfs <- function(graph, max_length) {
  
  cycles <- list()
  visited <- rep(FALSE, vcount(graph))
  stack <- integer(0)
  
  # DFS visit function
  dfs_visit <- function(v, depth = 1) {
    if (depth > max_length) return()
    
    visited[v] <<- TRUE
    stack <<- c(stack, v)
    
    # Get neighbors
    neighbors <- neighbors(graph, v, mode = "out")
    
    for (neighbor in neighbors) {
      neighbor_idx <- as.integer(neighbor)
      
      # Check if we've completed a cycle
      if (neighbor_idx %in% stack) {
        # Found a cycle
        cycle_start <- which(stack == neighbor_idx)
        cycle <- stack[cycle_start:length(stack)]
        
        # Add to cycles list if not duplicate
        if (!is_duplicate_cycle(cycle, cycles)) {
          cycles <<- c(cycles, list(cycle))
        }
      } else if (!visited[neighbor_idx]) {
        # Continue DFS
        dfs_visit(neighbor_idx, depth + 1)
      }
    }
    
    # Backtrack
    stack <<- stack[-length(stack)]
    visited[v] <<- FALSE
  }
  
  # Start DFS from each node
  for (v in 1:vcount(graph)) {
    dfs_visit(v)
  }
  
  return(cycles)
}

#' Check if cycle is duplicate (considering rotations)
#' 
#' @param cycle Vector of node indices
#' @param existing_cycles List of existing cycles
#' @return Logical
is_duplicate_cycle <- function(cycle, existing_cycles) {
  if (length(existing_cycles) == 0) return(FALSE)
  
  # Normalize cycle (start from smallest ID)
  normalized <- normalize_cycle(cycle)
  
  for (existing in existing_cycles) {
    if (identical(normalized, normalize_cycle(existing))) {
      return(TRUE)
    }
  }
  
  return(FALSE)
}

#' Normalize cycle to start from smallest node ID
#' 
#' @param cycle Vector of node indices
#' @return Normalized cycle
normalize_cycle <- function(cycle) {
  min_idx <- which.min(cycle)
  c(cycle[min_idx:length(cycle)], cycle[1:(min_idx-1)])
}

#' Classify loop type (reinforcing or balancing)
#'
#' @param loop_nodes Vector of node IDs in loop OR list with path and edge_types
#' @param edges Edges dataframe (optional if loop_nodes is a list)
#' @return "Reinforcing" or "Balancing" (capitalized, consistent format)
classify_loop_type <- function(loop_nodes, edges = NULL) {

  # Handle different input types
  if (is.list(loop_nodes) && !is.null(loop_nodes$edge_types)) {
    # New interface: list with path and edge_types
    edge_types <- loop_nodes$edge_types
    n_negative <- sum(edge_types == "-")

    # Even number of negatives = Reinforcing
    # Odd number of negatives = Balancing
    return(ifelse(n_negative %% 2 == 0, "Reinforcing", "Balancing"))
  }

  # Old interface: vector of node IDs and edges dataframe
  if (is.null(edges)) {
    stop("edges parameter is required when loop_nodes is a vector")
  }

  # Count negative edges in the loop
  n_negative <- 0

  for (i in 1:length(loop_nodes)) {
    from_id <- loop_nodes[i]
    to_id <- loop_nodes[(i %% length(loop_nodes)) + 1]

    edge <- edges %>% filter(from == from_id, to == to_id)

    if (nrow(edge) > 0 && edge$polarity == "-") {
      n_negative <- n_negative + 1
    }
  }

  # Even number of negatives = Reinforcing
  # Odd number of negatives = Balancing
  ifelse(n_negative %% 2 == 0, "Reinforcing", "Balancing")
}

#' Process detected cycles into loops dataframe
#' 
#' @param cycles List of cycles (node indices)
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param g igraph object
#' @return Dataframe with loop information
process_cycles_to_loops <- function(cycles, nodes, edges, g) {
  
  loops_list <- lapply(seq_along(cycles), function(i) {
    cycle <- cycles[[i]]
    
    # Get node IDs and labels
    node_ids <- V(g)[cycle]$name
    node_labels <- nodes %>% 
      filter(id %in% node_ids) %>% 
      pull(label)
    
    # Determine loop type
    loop_type <- classify_loop_type(node_ids, edges)
    
    data.frame(
      loop_id = i,
      name = paste0("Loop_", i),
      type = loop_type,
      length = length(node_ids),
      elements = paste(node_labels, collapse = " → "),
      node_ids = paste(node_ids, collapse = ","),
      significance = NA_character_,
      story = NA_character_,
      stringsAsFactors = FALSE
    )
  })
  
  bind_rows(loops_list)
}

# ============================================================================
# SIMPLIFICATION FUNCTIONS
# ============================================================================

#' Identify exogenous variables (endogenization)
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return Vector of node IDs that are exogenous
identify_exogenous_variables <- function(nodes, edges) {
  
  # Exogenous: outdegree > 0, indegree = 0
  outdegree <- edges %>%
    group_by(from) %>%
    summarize(out = n(), .groups = "drop")
  
  indegree <- edges %>%
    group_by(to) %>%
    summarize(in_deg = n(), .groups = "drop")
  
  exogenous <- nodes$id[
    nodes$id %in% outdegree$from & 
    !nodes$id %in% indegree$to
  ]
  
  return(exogenous)
}

#' Identify SISO variables (encapsulation)
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @return Dataframe with SISO node info
identify_siso_variables <- function(nodes, edges) {
  
  # Count degrees
  outdegree <- edges %>%
    group_by(from) %>%
    summarize(out = n(), .groups = "drop")
  
  indegree <- edges %>%
    group_by(to) %>%
    summarize(in_deg = n(), .groups = "drop")
  
  # SISO: indegree = 1 AND outdegree = 1
  siso_nodes <- nodes %>%
    left_join(indegree, by = c("id" = "to")) %>%
    left_join(outdegree, by = c("id" = "from")) %>%
    filter(in_deg == 1, out == 1)
  
  if (nrow(siso_nodes) == 0) return(data.frame())
  
  # Get input and output for each SISO
  siso_info <- siso_nodes %>%
    rowwise() %>%
    mutate(
      input_id = edges %>% filter(to == id) %>% pull(from),
      output_id = edges %>% filter(from == id) %>% pull(to)
    ) %>%
    ungroup()
  
  return(siso_info)
}

#' Remove exogenous variables
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param exogenous_ids Vector of node IDs to remove
#' @return List with updated nodes and edges
remove_exogenous_variables <- function(nodes, edges, exogenous_ids) {
  
  nodes_updated <- nodes %>% filter(!id %in% exogenous_ids)
  edges_updated <- edges %>% filter(!from %in% exogenous_ids)
  
  list(nodes = nodes_updated, edges = edges_updated)
}

#' Encapsulate SISO variables
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param siso_info Dataframe with SISO information
#' @return List with updated nodes and edges
encapsulate_siso_variables <- function(nodes, edges, siso_info) {
  
  if (nrow(siso_info) == 0) {
    return(list(nodes = nodes, edges = edges))
  }
  
  # Remove SISO nodes
  siso_ids <- siso_info$id
  nodes_updated <- nodes %>% filter(!id %in% siso_ids)
  
  # Create bridge edges
  bridge_edges <- siso_info %>%
    select(from = input_id, to = output_id) %>%
    left_join(
      edges %>% filter(from %in% siso_info$input_id) %>% 
        select(from, polarity_in = polarity),
      by = "from"
    ) %>%
    left_join(
      edges %>% filter(to %in% siso_info$output_id) %>% 
        select(to, polarity_out = polarity),
      by = "to"
    ) %>%
    mutate(
      # Calculate new polarity based on number of negatives
      n_negative = (polarity_in == "-") + (polarity_out == "-"),
      polarity = ifelse(n_negative %% 2 == 0, "+", "-"),
      strength = "medium",  # Default for bridge edges
      confidence = CONFIDENCE_DEFAULT,  # Default confidence for BOT edges
      arrows = "to",
      # Apply opacity based on confidence
      opacity = CONFIDENCE_OPACITY[as.character(CONFIDENCE_DEFAULT)],
      color = adjustcolor(
        ifelse(polarity == "+", EDGE_COLORS$reinforcing, EDGE_COLORS$opposing),
        alpha.f = CONFIDENCE_OPACITY[as.character(CONFIDENCE_DEFAULT)]
      ),
      width = 2.5,
      title = "Encapsulated connection",
      label = polarity,
      font.size = 10
    ) %>%
    select(from, to, arrows, color, width, opacity, title, polarity, strength, confidence, label, font.size)
  
  # Remove old edges and add bridge edges
  edges_updated <- edges %>%
    filter(!from %in% siso_ids, !to %in% siso_ids) %>%
    bind_rows(bridge_edges)
  
  list(nodes = nodes_updated, edges = edges_updated)
}

# ============================================================================
# COMMUNITY DETECTION
# ============================================================================

#' Detect communities in network
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param method Community detection algorithm
#' @return Nodes dataframe with cluster assignment
detect_communities <- function(nodes, edges, method = "louvain") {
  
  g <- create_igraph_from_data(nodes, edges)
  
  # Apply community detection
  communities <- switch(
    method,
    "louvain" = cluster_louvain(g),
    "walktrap" = cluster_walktrap(g),
    "edge_betweenness" = cluster_edge_betweenness(g),
    "fast_greedy" = cluster_fast_greedy(as.undirected(g)),
    cluster_louvain(g)  # default
  )
  
  # Add cluster membership to nodes
  nodes$cluster <- membership(communities)
  
  return(nodes)
}

# ============================================================================
# PATH ANALYSIS
# ============================================================================

#' Find shortest path between two nodes
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param from_id Source node ID
#' @param to_id Target node ID
#' @return Vector of node IDs in path
find_shortest_path <- function(nodes, edges, from_id, to_id) {
  
  g <- create_igraph_from_data(nodes, edges)
  
  path <- shortest_paths(
    g,
    from = from_id,
    to = to_id,
    mode = "out"
  )$vpath[[1]]
  
  if (length(path) == 0) return(NULL)
  
  V(g)[path]$name
}

#' Find all paths between two nodes up to maximum length
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param from_id Source node ID
#' @param to_id Target node ID
#' @param max_length Maximum path length
#' @return List of paths (vectors of node IDs)
find_all_paths <- function(nodes, edges, from_id, to_id, max_length = 10) {
  
  g <- create_igraph_from_data(nodes, edges)
  
  paths <- all_simple_paths(
    g,
    from = from_id,
    to = to_id,
    mode = "out",
    cutoff = max_length
  )
  
  lapply(paths, function(p) V(g)[p]$name)
}

# ============================================================================
# NEIGHBORHOOD ANALYSIS
# ============================================================================

#' Get neighborhood of a node
#' 
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param node_id Node ID
#' @param degree Neighborhood degree (1 = direct neighbors)
#' @return Vector of neighbor node IDs
get_neighborhood <- function(nodes, edges, node_id, degree = 1) {
  
  g <- create_igraph_from_data(nodes, edges)
  
  neighbors <- ego(g, order = degree, nodes = node_id, mode = "all")[[1]]
  
  V(g)[neighbors]$name
}
