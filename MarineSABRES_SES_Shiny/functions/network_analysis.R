# functions/network_analysis.R
# Network analysis functions for loop detection and metrics calculation
# Note: igraph is loaded in global.R

# ============================================================================
# CONSTANTS - Define defaults if not already loaded from global.R
# ============================================================================

if (!exists("CONFIDENCE_DEFAULT")) {
  CONFIDENCE_DEFAULT <- 3
}

if (!exists("CONFIDENCE_OPACITY")) {
  CONFIDENCE_OPACITY <- c(
    "1" = 0.3,
    "2" = 0.5,
    "3" = 0.7,
    "4" = 0.9,
    "5" = 1.0
  )
}

if (!exists("EDGE_COLORS")) {
  EDGE_COLORS <- list(
    reinforcing = "#80b8d7",  # Light blue
    opposing = "#dc131e"      # Red
  )
}

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

  # Require a graph with at least one edge for metrics
  if (vcount(g) == 0 || ecount(g) == 0) {
    stop("No valid edges found")
  }

  # Check if graph is connected (handle disconnected graphs gracefully)
  graph_connected <- is_connected(g, mode = "weak")

  # For disconnected graphs, calculate diameter on largest component
  safe_diameter <- tryCatch({
    if (graph_connected) {
      diameter(g, directed = TRUE)
    } else {
      # Use largest component for diameter
      comp <- components(g, mode = "weak")
      largest_comp <- which.max(comp$csize)
      subg <- induced_subgraph(g, which(comp$membership == largest_comp))
      diameter(subg, directed = TRUE)
    }
  }, error = function(e) 0)

  safe_avg_path <- tryCatch({
    d <- mean_distance(g, directed = TRUE)
    if (is.nan(d) || is.infinite(d)) 0 else d
  }, error = function(e) 0)

  # Closeness can return Inf/NaN for disconnected graphs
  safe_closeness <- tryCatch({
    cl <- closeness(g, mode = "all")
    cl[is.nan(cl) | is.infinite(cl)] <- 0
    cl
  }, error = function(e) rep(0, vcount(g)))

  metrics <- list(
    nodes = vcount(g),
    edges = ecount(g),
    density = edge_density(g),
    connected = graph_connected,
    diameter = safe_diameter,
    avg_path_length = safe_avg_path,
    degree = degree(g, mode = "all"),
    indegree = degree(g, mode = "in"),
    outdegree = degree(g, mode = "out"),
    betweenness = tryCatch(betweenness(g, directed = TRUE), error = function(e) rep(0, vcount(g))),
    closeness = safe_closeness,
    eigenvector = tryCatch(eigen_centrality(g, directed = TRUE)$vector, error = function(e) rep(0, vcount(g))),
    pagerank = tryCatch(page_rank(g)$vector, error = function(e) rep(0, vcount(g)))
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

  # Handle case with no edges - create graph with nodes only
  if (nrow(valid_edges) == 0) {
    cat("[NETWORK_ANALYSIS] No edges found, creating graph with nodes only\n")
    # Create graph with no edges
    g <- igraph::graph_from_data_frame(
      d = data.frame(from = character(0), to = character(0)),
      vertices = nodes,
      directed = TRUE
    )
    return(g)
  }

  # Select available columns - must include 'from' and 'to'
  if (!all(c("from", "to") %in% names(valid_edges))) {
    stop("Edges dataframe must contain 'from' and 'to' columns")
  }
  allowed_extra <- c("polarity", "strength", "confidence", "link_type")
  cols_to_use <- c("from", "to", intersect(allowed_extra, names(valid_edges)))

  graph_from_data_frame(
    valid_edges[, cols_to_use, drop = FALSE],
    directed = TRUE,
    vertices = nodes
  )
}

#' Build an igraph object directly from an 'isa' structure (list with $nodes and $edges)
#'
#' @param isa list with components 'nodes' and 'edges' (data.frames)
#' @return igraph object or NULL
build_network_from_isa <- function(isa) {
  if (is.null(isa)) return(NULL)
  nodes <- isa$nodes
  edges <- isa$edges
  if (is.null(nodes) || is.null(edges)) return(NULL)
  create_igraph_from_data(nodes, edges)
}

#' Calculate basic centrality metrics and return as a named list
#'
#' @param graph igraph object
#' @return named list of numeric vectors
calculate_centrality <- function(graph) {
  if (is.null(graph) || !inherits(graph, "igraph")) return(list())
  list(
    degree = igraph::degree(graph, mode = "all"),
    betweenness = igraph::betweenness(graph, directed = TRUE),
    closeness = tryCatch({
      cl <- igraph::closeness(graph, mode = "all")
      cl[is.nan(cl) | is.infinite(cl)] <- 0
      cl
    }, error = function(e) rep(0, vcount(graph)))
  )
}

#' Detect feedback loops (simple cycles) up to a maximum length
#'
#' @param graph igraph directed graph
#' @param max_length integer maximum cycle length
#' @return data.frame of cycles (path strings)
detect_feedback_loops <- function(graph, max_length = 5) {
  if (!inherits(graph, "igraph")) return(list())
  nodes <- igraph::V(graph)$name
  result <- data.frame(path = character(0), stringsAsFactors = FALSE)
  for (v in nodes) {
    paths <- igraph::all_simple_paths(graph, from = v, to = v, mode = "out", cutoff = max_length)
    for (p in paths) {
      if (length(p) > 1) {
        path_str <- paste(igraph::V(graph)$name[as.numeric(p)], collapse = "->")
        result <- rbind(result, data.frame(path = path_str, stringsAsFactors = FALSE))
      }
    }
  }
  result
}

#' Classify loop type (Reinforcing or Balancing) based on edge sign vector
#' @param loop_info list with edge_types (vector of '+' or '-')
#' @return character 'Reinforcing' or 'Balancing'
classify_loop_type <- function(loop_info) {
  if (is.null(loop_info$edge_types)) return(NA_character_)
  neg_count <- sum(loop_info$edge_types == "-")
  if (neg_count %% 2 == 0) "Reinforcing" else "Balancing"
}

#' Simplify network by removing low-importance nodes
#' @param graph igraph object
#' @param threshold numeric proportion threshold (0-1)
#' @return simplified igraph object
simplify_network <- function(graph, threshold = NULL) {
  if (!inherits(graph, "igraph")) return(graph)
  if (is.null(threshold)) return(graph)
  deg <- igraph::degree(graph)
  keep <- deg >= threshold * max(deg)
  igraph::induced_subgraph(graph, igraph::V(graph)[keep])
}

#' Rank node importance using PageRank
#' @param graph igraph object
#' @return data.frame with node and importance
rank_node_importance <- function(graph) {
  if (!inherits(graph, "igraph")) return(data.frame())
  pr <- igraph::page_rank(graph)$vector
  data.frame(node = igraph::V(graph)$name, importance = pr, stringsAsFactors = FALSE)
}

#' Find simple pathways between two nodes (limited search)
#' @param graph igraph object
#' @param from source node id
#' @param to target node id
#' @return list of pathways or data.frame
find_pathways <- function(graph, from, to) {
  if (!inherits(graph, "igraph")) return(list())
  paths <- igraph::all_simple_paths(graph, from = from, to = to, mode = "out")
  lapply(paths, function(p) igraph::V(graph)$name[as.numeric(p)])
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

    # Pre-build named lookup for O(1) index access (instead of O(n) which() per edge)
    node_idx <- setNames(seq_len(nrow(nodes)), nodes$id)

    # Vectorized edge lookup
    from_indices <- node_idx[edges$from]
    to_indices <- node_idx[edges$to]

    # Find valid edges (both endpoints exist)
    valid <- !is.na(from_indices) & !is.na(to_indices)
    if (any(!valid)) {
      warning(sprintf("Skipped %d edges referencing non-existent nodes.", sum(!valid)))
    }

    # Fill adjacency matrix using matrix indexing (fully vectorized)
    if (any(valid)) {
      adj[cbind(from_indices[valid], to_indices[valid])] <- 1
    }

    return(adj)

  }, error = function(e) {
    stop(paste("Error creating adjacency matrix:", e$message))
  })
}

# ============================================================================
# DAPSIRWRM FRAMEWORK VALIDATION
# ============================================================================

#' Check if a transition follows valid DAPSIRWRM framework logic
#'
#' Valid transitions:
#' - Forward: D→A, A→P, P→MPF, MPF→ES, ES→GB, GB→R
#' - Feedback: R→D, R→A, R→P, D→GB
#'
#' @param from_type Source node type
#' @param to_type Target node type
#' @return Logical indicating if transition is valid
is_valid_dapsirwrm_transition <- function(from_type, to_type) {
  # Normalize types to lowercase for comparison
  from <- tolower(trimws(as.character(from_type)))
  to <- tolower(trimws(as.character(to_type)))

  # Define valid transitions (using arrays for flexibility with synonyms)
  valid_transitions <- list(
    # Forward transitions
    list(from = c("driver", "drivers"), to = c("activity", "activities")),
    list(from = c("activity", "activities"), to = c("pressure", "pressures", "enmp")),
    list(from = c("pressure", "pressures", "enmp"),
         to = c("state", "states", "state change", "marine_process", "marine_processes", "mpf")),
    list(from = c("state", "states", "state change", "marine_process", "marine_processes", "mpf"),
         to = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es")),
    list(from = c("impact", "impacts", "ecosystem_service", "ecosystem_services", "es"),
         to = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing")),
    list(from = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"),
         to = c("response", "responses")),

    # Feedback transitions (responses back to earlier stages)
    list(from = c("response", "responses"), to = c("driver", "drivers")),
    list(from = c("response", "responses"), to = c("activity", "activities")),
    list(from = c("response", "responses"), to = c("pressure", "pressures", "enmp")),

    # Direct feedback shortcut
    list(from = c("driver", "drivers"),
         to = c("welfare", "goods_benefit", "goods_benefits", "gb", "wellbeing"))
  )

  # Check if this transition matches any valid pattern
  for (transition in valid_transitions) {
    if (from %in% transition$from && to %in% transition$to) {
      return(TRUE)
    }
  }

  return(FALSE)
}

#' Validate that all edges in a loop follow DAPSIRWRM framework
#'
#' @param loop_node_ids Vector of node IDs in the loop
#' @param nodes Nodes dataframe with id and type/group columns
#' @return List with is_valid (logical) and invalid_edges (character vector)
validate_loop_dapsirwrm <- function(loop_node_ids, nodes) {
  invalid_edges <- character(0)

  # Helper function to derive type from group or use type directly
  get_node_type <- function(node_data) {
    if ("type" %in% names(node_data) && !is.null(node_data$type)) {
      return(node_data$type)
    } else if ("group" %in% names(node_data) && !is.null(node_data$group)) {
      # Map group names to type names
      group <- node_data$group
      type_mapping <- c(
        "Drivers" = "driver",
        "Activities" = "activity",
        "Pressures" = "pressure",
        "Marine Processes & Functioning" = "state",
        "Ecosystem Services" = "impact",
        "Goods & Benefits" = "welfare",
        "Responses" = "response"
      )
      return(type_mapping[group])
    }
    return(NA_character_)
  }

  # Create fast lookup for node types - handle both type and group columns
  if ("type" %in% names(nodes)) {
    node_type_lookup <- setNames(nodes$type, nodes$id)
  } else if ("group" %in% names(nodes)) {
    # Derive type from group
    type_mapping <- c(
      "Drivers" = "driver",
      "Activities" = "activity",
      "Pressures" = "pressure",
      "Marine Processes & Functioning" = "state",
      "Ecosystem Services" = "impact",
      "Goods & Benefits" = "welfare",
      "Responses" = "response"
    )
    node_types <- type_mapping[nodes$group]
    node_type_lookup <- setNames(node_types, nodes$id)
  } else {
    stop("nodes dataframe must have either 'type' or 'group' column")
  }

  # Check each edge in the loop
  for (i in seq_along(loop_node_ids)) {
    from_id <- loop_node_ids[i]
    to_id <- loop_node_ids[(i %% length(loop_node_ids)) + 1]

    from_type <- node_type_lookup[from_id]
    to_type <- node_type_lookup[to_id]

    # Validate this transition
    if (!is_valid_dapsirwrm_transition(from_type, to_type)) {
      invalid_edge <- sprintf("%s (%s) → %s (%s)",
                              from_id, from_type, to_id, to_type)
      invalid_edges <- c(invalid_edges, invalid_edge)
    }
  }

  list(
    is_valid = length(invalid_edges) == 0,
    invalid_edges = invalid_edges
  )
}

# ============================================================================
# LOOP DETECTION FUNCTIONS
# ============================================================================

#' Find all simple cycles in the network
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param max_length Maximum cycle length to detect
#' @param max_cycles Maximum number of cycles to find (default 1000)
#' @return List of cycles (vectors of node IDs)
find_all_cycles <- function(nodes, edges, max_length = 10, max_cycles = 1000) {

  # Create igraph object
  g <- create_igraph_from_data(nodes, edges)

  # Get all strongly connected components
  scc <- components(g, mode = "strong")

  cycles <- list()

  # Warn about large components
  comp_sizes <- table(scc$membership)
  max_comp_size <- max(comp_sizes)

  if (max_comp_size > 50) {
    warning(sprintf(
      "Large strongly connected component detected (%d nodes). This may cause slow performance or timeout. Consider simplifying the network.",
      max_comp_size
    ))
  }

  # Process each component
  for (comp_id in unique(scc$membership)) {
    # Stop if we've reached the cycle limit
    if (length(cycles) >= max_cycles) break

    comp_nodes <- which(scc$membership == comp_id)
    comp_size <- length(comp_nodes)

    if (comp_size > 1) {
      # Extract subgraph once
      subg <- induced_subgraph(g, comp_nodes)

      # Skip very large components that will cause exponential explosion
      # Use reasonable limits for large components
      # DAPSIR frameworks with feedback loops typically have 2-5% density
      if (comp_size > 30) {
        edge_count <- ecount(subg)
        edge_density <- edge_count / (comp_size * (comp_size - 1))

        # Adjusted limits to allow typical DAPSIR feedback structures
        # Components with >10% density are truly problematic
        max_density <- if (comp_size > 100) 0.05 else if (comp_size > 70) 0.08 else if (comp_size > 50) 0.10 else 0.15

        if (edge_density > max_density) {
          warning(sprintf(
            "Skipping large dense component (%d nodes, %d edges, %.1f%% density) to prevent hanging. Reduce network complexity or use simplification tools.",
            comp_size, edge_count, edge_density * 100
          ))
          next
        }
      }

      # Calculate remaining cycle budget
      remaining_cycles <- max_cycles - length(cycles)

      # Find cycles in this component
      comp_cycles <- find_cycles_dfs(subg, max_length, max_cycles = remaining_cycles)

      # CRITICAL: Remap subgraph indices to original graph indices
      # comp_cycles contains indices in the subgraph, we need to map them to the original graph
      if (length(comp_cycles) > 0) {
        comp_cycles <- lapply(comp_cycles, function(cycle) {
          comp_nodes[cycle]  # Map subgraph indices to original graph indices
        })
      }

      cycles <- c(cycles, comp_cycles)
    }
  }

  return(cycles)
}

#' Find cycles using depth-first search
#'
#' Optimized DFS implementation using index-based stack to avoid
#' O(n) vector append/remove operations. Uses pre-allocated arrays
#' for O(1) push/pop operations.
#'
#' @param graph igraph object
#' @param max_length Maximum cycle length
#' @param max_cycles Maximum number of cycles to find (default 1000)
#' @return List of cycles
find_cycles_dfs <- function(graph, max_length, max_cycles = 1000) {

  n_vertices <- vcount(graph)
  cycles <- list()
  visited <- rep(FALSE, n_vertices)
  in_stack <- rep(FALSE, n_vertices)  # Fast O(1) stack membership lookup

  # Pre-allocated stack with index pointer (avoids O(n) vector operations)
  stack <- integer(max_length + 1)
  stack_ptr <- 0L  # Stack pointer (0 = empty)

  # Use a hash environment for O(1) signature lookup
  cycle_signatures <- new.env(hash = TRUE, parent = emptyenv())

  # Helper: push to stack (O(1))
  stack_push <- function(v) {
    stack_ptr <<- stack_ptr + 1L
    stack[stack_ptr] <<- v
  }

  # Helper: pop from stack (O(1))
  stack_pop <- function() {
    stack_ptr <<- stack_ptr - 1L
  }

  # Helper: get current stack contents
  get_stack <- function() {
    if (stack_ptr > 0L) stack[1:stack_ptr] else integer(0)
  }

  # DFS visit function
  dfs_visit <- function(v, depth = 1L) {
    # Stop if we've found enough cycles
    if (length(cycles) >= max_cycles) return()

    if (depth > max_length) return()

    visited[v] <<- TRUE
    stack_push(v)
    in_stack[v] <<- TRUE  # Mark node as in current path

    # Get neighbors
    neighbor_list <- neighbors(graph, v, mode = "out")

    for (neighbor in neighbor_list) {
      # Stop if we've found enough cycles
      if (length(cycles) >= max_cycles) break

      neighbor_idx <- as.integer(neighbor)

      # Check if we've completed a cycle (O(1) lookup)
      if (in_stack[neighbor_idx]) {
        # Found a cycle - extract from stack
        current_stack <- get_stack()
        cycle_start <- which(current_stack == neighbor_idx)
        cycle <- current_stack[cycle_start:length(current_stack)]

        # Fast duplicate check using hash environment (O(1) lookup)
        normalized <- normalize_cycle(cycle)
        signature <- paste(normalized, collapse = "-")

        if (!exists(signature, envir = cycle_signatures, inherits = FALSE)) {
          cycles <<- c(cycles, list(cycle))
          assign(signature, TRUE, envir = cycle_signatures)
        }
      } else if (!visited[neighbor_idx]) {
        # Continue DFS only if we haven't exceeded depth
        if (depth < max_length) {
          dfs_visit(neighbor_idx, depth + 1L)
        }
      }
    }

    # Backtrack (O(1) operations)
    stack_pop()
    in_stack[v] <<- FALSE  # Remove from current path
    visited[v] <<- FALSE
  }

  # Start DFS from each node
  for (v in 1:n_vertices) {
    # Stop if we've found enough cycles
    if (length(cycles) >= max_cycles) break

    dfs_visit(v)
  }

  # Warn if limit reached
  if (length(cycles) >= max_cycles) {
    warning(sprintf("Cycle detection stopped after finding %d cycles (limit reached). Network may contain more cycles.", max_cycles))
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
#' @param edges Edges dataframe OR edge lookup table (optional if loop_nodes is a list)
#' @param edge_lookup Optional: pre-computed edge lookup table for performance
#' @return "Reinforcing" or "Balancing" (capitalized, consistent format)
classify_loop_type <- function(loop_nodes, edges = NULL, edge_lookup = NULL) {

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
  if (is.null(edges) && is.null(edge_lookup)) {
    stop("edges or edge_lookup parameter is required when loop_nodes is a vector")
  }

  # Create edge lookup if not provided (for backwards compatibility)
  if (is.null(edge_lookup) && !is.null(edges)) {
    edge_lookup <- create_edge_lookup_table(edges)
  }

  # Count negative edges in the loop using fast lookup
  n_negative <- 0

  for (i in 1:length(loop_nodes)) {
    from_id <- loop_nodes[i]
    to_id <- loop_nodes[(i %% length(loop_nodes)) + 1]

    edge_key <- paste(from_id, to_id, sep = "->")

    if (!is.null(edge_lookup[[edge_key]]) && edge_lookup[[edge_key]] == "-") {
      n_negative <- n_negative + 1
    }
  }

  # Even number of negatives = Reinforcing
  # Odd number of negatives = Balancing
  ifelse(n_negative %% 2 == 0, "Reinforcing", "Balancing")
}

#' Create edge lookup table for fast edge polarity access
#'
#' @param edges Edges dataframe with from, to, and polarity columns
#' @return Named list for O(1) edge polarity lookup
create_edge_lookup_table <- function(edges) {
  lookup <- list()

  for (i in 1:nrow(edges)) {
    key <- paste(edges$from[i], edges$to[i], sep = "->")
    lookup[[key]] <- edges$polarity[i]
  }

  return(lookup)
}

#' Process detected cycles into loops dataframe
#'
#' @param cycles List of cycles (node indices)
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param g igraph object
#' @param validate_dapsirwrm Logical, whether to validate loops against DAPSIRWRM framework (default TRUE)
#' @return Dataframe with loop information
process_cycles_to_loops <- function(cycles, nodes, edges, g, validate_dapsirwrm = TRUE) {

  if (length(cycles) == 0) {
    return(data.frame(
      LoopID = integer(0),
      Name = character(0),
      Type = character(0),
      Length = integer(0),
      Elements = character(0),
      NodeIDs = character(0),
      Significance = character(0),
      Story = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Create lookup tables for performance (O(1) access instead of O(n) filtering)
  # Handle NA labels by using id as fallback
  safe_labels <- ifelse(is.na(nodes$label) | !nzchar(as.character(nodes$label)),
                        nodes$id,
                        nodes$label)
  node_label_lookup <- setNames(safe_labels, nodes$id)
  edge_lookup <- create_edge_lookup_table(edges)

  # Process cycles in batches for progress monitoring on large datasets
  batch_size <- 100
  n_cycles <- length(cycles)
  n_batches <- ceiling(n_cycles / batch_size)

  if (n_cycles > batch_size) {
    cat(sprintf("[Loop Processing] Processing %d loops in %d batches\n", n_cycles, n_batches))
  }

  # Track invalid loops for reporting
  invalid_loops <- list()

  loops_list <- lapply(seq_along(cycles), function(i) {
    # Progress monitoring for large datasets
    if (i %% batch_size == 0 && n_cycles > batch_size) {
      cat(sprintf("[Loop Processing] Processed %d/%d loops (%.1f%%)\n",
                  i, n_cycles, (i/n_cycles)*100))
    }

    cycle <- cycles[[i]]

    # Get node IDs and labels using fast lookup
    node_ids <- V(g)[cycle]$name
    node_labels <- node_label_lookup[node_ids]

    # Validate loop against DAPSIRWRM framework if requested
    if (validate_dapsirwrm) {
      validation <- validate_loop_dapsirwrm(node_ids, nodes)

      if (!validation$is_valid) {
        # Store invalid loop info for reporting
        invalid_loops[[length(invalid_loops) + 1]] <<- list(
          loop_id = i,
          elements = paste(node_labels, collapse = " → "),
          invalid_edges = validation$invalid_edges
        )
        return(NULL)  # Skip this loop
      }
    }

    # Determine loop type using pre-computed edge lookup
    loop_type <- classify_loop_type(node_ids, edge_lookup = edge_lookup)

    data.frame(
      LoopID = i,
      Name = paste0("Loop_", i),
      Type = loop_type,
      Length = length(node_ids),
      Elements = paste(node_labels, collapse = " → "),
      NodeIDs = paste(node_ids, collapse = ","),
      Significance = NA_character_,
      Story = NA_character_,
      stringsAsFactors = FALSE
    )
  })

  # Filter out NULL entries (invalid loops)
  loops_list <- Filter(Negate(is.null), loops_list)

  # Report on filtered loops
  if (validate_dapsirwrm && length(invalid_loops) > 0) {
    cat(sprintf("\n[DAPSIRWRM Validation] Filtered out %d invalid loops that violate framework constraints:\n",
                length(invalid_loops)))

    # Show first few examples
    n_examples <- min(3, length(invalid_loops))
    for (i in 1:n_examples) {
      invalid <- invalid_loops[[i]]
      cat(sprintf("  Loop %d: %s\n", invalid$loop_id, invalid$elements))
      cat(sprintf("    Invalid transitions: %s\n",
                  paste(invalid$invalid_edges, collapse="; ")))
    }

    if (length(invalid_loops) > n_examples) {
      cat(sprintf("  ... and %d more invalid loops\n",
                  length(invalid_loops) - n_examples))
    }

    cat(sprintf("\nValid DAPSIRWRM transitions:\n"))
    cat("  Forward: D→A→P→MPF→ES→GB→R\n")
    cat("  Feedback: R→D, R→A, R→P, D→GB\n\n")
  }

  # Re-number loop IDs to be sequential
  if (length(loops_list) > 0) {
    result <- bind_rows(loops_list)
    result$LoopID <- seq_len(nrow(result))
    result$Name <- paste0("Loop_", result$LoopID)
    return(result)
  } else {
    return(data.frame(
      LoopID = integer(0),
      Name = character(0),
      Type = character(0),
      Length = integer(0),
      Elements = character(0),
      NodeIDs = character(0),
      Significance = character(0),
      Story = character(0),
      stringsAsFactors = FALSE
    ))
  }
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

# ============================================================================
# LEVERAGE POINT ANALYSIS
# ============================================================================

#' Safe Scale Helper Function
#'
#' Safely scales a numeric vector, handling cases with zero variance
#'
#' @param x Numeric vector to scale
#' @return Scaled vector (or original if sd is 0)
safe_scale <- function(x) {
  if (sd(x, na.rm = TRUE) == 0) {
    return(rep(0, length(x)))
  }
  scale(x)[,1]
}

#' Calculate All Centrality Metrics for Nodes
#'
#' Computes multiple centrality measures for each node in the network
#'
#' @param g An igraph object
#' @return A data frame with centrality metrics
calculate_all_centralities <- function(g) {

  if (vcount(g) == 0) {
    return(data.frame(
      Node = integer(0),
      Name = character(0),
      Degree = numeric(0),
      In_Degree = numeric(0),
      Out_Degree = numeric(0),
      Betweenness = numeric(0),
      Closeness = numeric(0),
      Eigenvector = numeric(0),
      PageRank = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  # Safe centrality calculation with fallbacks
  safe_betweenness <- tryCatch(
    betweenness(g, directed = TRUE),
    error = function(e) rep(0, vcount(g))
  )

  safe_closeness <- tryCatch({
    cl <- closeness(g, mode = "all")
    cl[is.nan(cl) | is.infinite(cl)] <- 0
    cl
  }, error = function(e) rep(0, vcount(g)))

  safe_eigenvector <- tryCatch(
    eigen_centrality(g, directed = TRUE)$vector,
    error = function(e) rep(0, vcount(g))
  )

  safe_pagerank <- tryCatch(
    page_rank(g)$vector,
    error = function(e) rep(0, vcount(g))
  )

  data.frame(
    Node = 1:vcount(g),
    Name = if (!is.null(V(g)$label)) V(g)$label else if (!is.null(V(g)$name)) V(g)$name else paste("Node", 1:vcount(g)),
    Degree = degree(g),
    In_Degree = degree(g, mode = "in"),
    Out_Degree = degree(g, mode = "out"),
    Betweenness = safe_betweenness,
    Closeness = safe_closeness,
    Eigenvector = safe_eigenvector,
    PageRank = safe_pagerank,
    stringsAsFactors = FALSE
  )
}

#' Identify Leverage Points in Network
#'
#' Identifies the most influential nodes that could serve as intervention points
#' based on a composite score of betweenness, eigenvector, and PageRank centrality.
#'
#' @param nodes Nodes dataframe OR igraph object
#' @param edges Edges dataframe (optional if nodes is an igraph object)
#' @param top_n Number of top leverage points to return (default: 10)
#'
#' @return A data frame of top N nodes sorted by composite_score (descending),
#'   including all centrality metrics
#'
#' @details
#' The composite score is calculated as the sum of scaled betweenness, eigenvector
#' centrality, and PageRank. Higher scores indicate nodes that are critical for
#' information flow, have high influence, and connect important parts of the network.
#'
#' @export
identify_leverage_points <- function(nodes, edges = NULL, top_n = 10) {

  # Handle different input types
  if (inherits(nodes, "igraph")) {
    # If nodes is actually an igraph object
    g <- nodes
  } else {
    # Create igraph object from data
    g <- create_igraph_from_data(nodes, edges)
  }

  if (vcount(g) == 0) {
    return(data.frame(
      Node = integer(0),
      Name = character(0),
      Degree = numeric(0),
      In_Degree = numeric(0),
      Out_Degree = numeric(0),
      Betweenness = numeric(0),
      Closeness = numeric(0),
      Eigenvector = numeric(0),
      PageRank = numeric(0),
      Composite_Score = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  # Calculate centralities
  centralities <- calculate_all_centralities(g)

  # Calculate composite score for leverage points
  centralities$Composite_Score <- safe_scale(centralities$Betweenness) +
                                   safe_scale(centralities$Eigenvector) +
                                   safe_scale(centralities$PageRank)

  # Sort by composite score and return top N
  leverage_points <- centralities[order(-centralities$Composite_Score), ]
  return(head(leverage_points, min(top_n, nrow(leverage_points))))
}

# ============================================================================
# INCREMENTAL NETWORK UPDATE HELPERS
# ============================================================================

#' Add a node to an existing visNetwork via proxy (no full re-render)
#'
#' @param proxy_id The visNetwork output ID
#' @param session The Shiny session
#' @param node_data A list or data.frame with node properties (id, label, group, etc.)
#' @return The visNetworkProxy object (for chaining)
add_node_incremental <- function(proxy_id, session, node_data) {
  if (is.null(node_data) || length(node_data) == 0) return(invisible(NULL))

  proxy <- visNetworkProxy(proxy_id, session = session)

  if (is.data.frame(node_data)) {
    visUpdateNodes(proxy, node_data)
  } else {
    # Convert list to single-row data.frame
    node_df <- as.data.frame(node_data, stringsAsFactors = FALSE)
    visUpdateNodes(proxy, node_df)
  }

  invisible(proxy)
}

#' Remove a node from an existing visNetwork via proxy
#'
#' @param proxy_id The visNetwork output ID
#' @param session The Shiny session
#' @param node_id The ID of the node to remove
#' @return The visNetworkProxy object (for chaining)
remove_node_incremental <- function(proxy_id, session, node_id) {
  if (is.null(node_id)) return(invisible(NULL))

  proxy <- visNetworkProxy(proxy_id, session = session)
  visRemoveNodes(proxy, id = node_id)

  invisible(proxy)
}

#' Add an edge to an existing visNetwork via proxy
#'
#' @param proxy_id The visNetwork output ID
#' @param session The Shiny session
#' @param edge_data A list or data.frame with edge properties (from, to, etc.)
#' @return The visNetworkProxy object (for chaining)
add_edge_incremental <- function(proxy_id, session, edge_data) {
  if (is.null(edge_data) || length(edge_data) == 0) return(invisible(NULL))

  proxy <- visNetworkProxy(proxy_id, session = session)

  if (is.data.frame(edge_data)) {
    visUpdateEdges(proxy, edge_data)
  } else {
    edge_df <- as.data.frame(edge_data, stringsAsFactors = FALSE)
    visUpdateEdges(proxy, edge_df)
  }

  invisible(proxy)
}

#' Remove an edge from an existing visNetwork via proxy
#'
#' @param proxy_id The visNetwork output ID
#' @param session The Shiny session
#' @param edge_id The ID of the edge to remove
#' @return The visNetworkProxy object (for chaining)
remove_edge_incremental <- function(proxy_id, session, edge_id) {
  if (is.null(edge_id)) return(invisible(NULL))

  proxy <- visNetworkProxy(proxy_id, session = session)
  visRemoveEdges(proxy, id = edge_id)

  invisible(proxy)
}

# ============================================================================
# SAFE WRAPPER FUNCTIONS
# (Consolidated from network_analysis_enhanced.R)
# These add input validation and error handling around the core analysis functions.
# ============================================================================

#' Validate nodes data frame (basic check for safe wrappers)
validate_nodes <- function(nodes) {
  if (is.null(nodes)) stop("nodes is NULL")
  if (!is.data.frame(nodes)) stop("nodes must be dataframe")
  missing <- setdiff(c("id", "name"), names(nodes))
  if (length(missing) > 0) stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")))
  TRUE
}

#' Validate edges data frame
validate_edges <- function(edges, required = c("from", "to")) {
  if (is.null(edges)) stop("edges is NULL")
  if (!is.data.frame(edges)) stop("edges must be dataframe")
  missing <- setdiff(required, names(edges))
  if (length(missing) > 0) stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")))
  TRUE
}

create_igraph_from_data_safe <- function(nodes, edges) {
  if (is.null(nodes) || is.null(edges)) return(NULL)
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(NULL)
  if (!all(c("id", "name") %in% names(nodes))) return(NULL)
  if (!all(c("from", "to") %in% names(edges))) return(NULL)

  valid_nodes <- nodes$id
  valid_edges <- edges[edges$from %in% valid_nodes & edges$to %in% valid_nodes, , drop = FALSE]

  if (nrow(nodes) == 0 || nrow(valid_edges) == 0) return(NULL)

  tryCatch({
    g <- igraph::graph_from_data_frame(d = valid_edges, vertices = nodes, directed = TRUE)
    return(g)
  }, error = function(e) {
    warning("Failed to create igraph: ", e$message)
    return(NULL)
  })
}

calculate_network_metrics_safe <- function(nodes, edges = NULL) {
  if (inherits(nodes, "igraph")) {
    g <- nodes
    if (!inherits(g, "igraph")) return(NULL)
  } else {
    if (is.null(nodes) || !is.data.frame(nodes)) return(NULL)
    if (is.null(edges) || !is.data.frame(edges)) return(NULL)
    if (!all(c("id", "name") %in% names(nodes))) return(NULL)
    if (nrow(nodes) == 0) return(NULL)
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
    g <- create_igraph_from_data_safe(nodes, edges)
    if (is.null(g)) return(NULL)
  }

  tryCatch({
    raw <- calculate_network_metrics(g)
    list(
      density = raw$density,
      avg_degree = mean(raw$degree, na.rm = TRUE),
      num_nodes = vcount(g),
      num_edges = ecount(g),
      components = igraph::components(g)$no,
      degree = raw$degree
    )
  }, error = function(e) {
    warning("calculate_network_metrics failed: ", e$message)
    NULL
  })
}

calculate_micmac_safe <- function(nodes, edges) {
  if (is.null(nodes) || is.null(edges)) return(NULL)
  if (!is.data.frame(nodes) || !is.data.frame(edges)) return(NULL)
  if (!all(c("id") %in% names(nodes))) return(NULL)
  if (!all(c("from", "to") %in% names(edges))) return(NULL)

  tryCatch({
    res <- calculate_micmac(nodes, edges)
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

  tryCatch({
    cycles <- find_all_cycles(nodes, edges, max_length = max_length, max_cycles = max_cycles)
    lapply(cycles, function(cycle_idx) {
      node_ids <- igraph::V(g)$name[cycle_idx]
      pols <- c()
      for (i in seq_along(node_ids)) {
        from <- node_ids[i]
        to <- node_ids[(i %% length(node_ids)) + 1]
        row <- edges[edges$from == from & edges$to == to, , drop = FALSE]
        pols <- c(pols, if (nrow(row) > 0) as.character(row$polarity[1]) else NA)
      }
      list(nodes = node_ids, polarities = pols)
    })
  }, error = function(e) {
    warning("find_all_cycles failed: ", e$message)
    list()
  })
}

classify_loop_type_safe <- function(loop, edges = NULL) {
  if (is.null(loop)) return(NULL)
  if (!is.list(loop)) return(NULL)
  if (!is.null(loop$polarities)) {
    neg <- sum(loop$polarities == "-", na.rm = TRUE)
    return(ifelse(neg %% 2 == 1, "B", "R"))
  }
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
