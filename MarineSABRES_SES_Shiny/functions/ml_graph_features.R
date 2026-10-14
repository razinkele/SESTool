# functions/ml_graph_features.R
# Graph Structural Features for ML - Phase 2 Enhancement 1 (Week 2)
# ==============================================================================
#
# Extracts structural features from SES networks using igraph to improve
# connection prediction accuracy. Features capture:
# - Node centrality (degree, betweenness)
# - Shortest path distances
# - DAPSIWRM framework compliance
#
# Integration: 8 additional dims to Phase 2 model (314-dim input)
#
# ==============================================================================

if (!requireNamespace("igraph", quietly = TRUE)) {
  warning("Package 'igraph' is required for graph features. Graph features will be unavailable.")
}

# Source dependencies (only if not already loaded by global.R)
if (!exists("create_igraph_from_data", mode = "function") &&
    file.exists("functions/network_analysis.R")) {
  source("functions/network_analysis.R", chdir = TRUE)
}
if (!exists("get_dapsiwrm_connection_rules", mode = "function") &&
    file.exists("functions/dapsiwrm_connection_rules.R")) {
  source("functions/dapsiwrm_connection_rules.R", chdir = TRUE)
}

# ==============================================================================
# DAPSIWRM Type Distance Calculation
# ==============================================================================

#' Calculate DAPSIWRM Framework Distance
#'
#' Computes the sequential distance in the DAPSIWRM framework between two types.
#' Lower distances indicate connections following the standard causal chain.
#'
#' Framework sequence: D → A → P → MPF → ES → GB → R
#' Feedback loops: R → D/A/P/MPF (distance = 0, valid feedback)
#'
#' @param source_type Source DAPSIWRM type
#' @param target_type Target DAPSIWRM type
#' @return Numeric distance (0 = valid feedback, 1 = adjacent, 2+ = skipped steps)
#' @export
calculate_dapsiwrm_distance <- function(source_type, target_type) {

  # Normalize type names to canonical form
  type_mapping <- setNames(seq_along(DAPSIWRM_ELEMENTS), DAPSIWRM_ELEMENTS)

  source_idx <- unname(type_mapping[source_type])
  target_idx <- unname(type_mapping[target_type])

  # Handle unknown types
  if (is.na(source_idx) || is.na(target_idx)) {
    return(5)  # Maximum distance for unknown types
  }

  # Special case: Responses can feedback to earlier stages (distance = 0)
  if (source_idx == 7 && target_idx <= 4) {
    return(0)  # Valid feedback loop
  }

  # Special case: Goods & Benefits can feedback to Drivers (distance = 0)
  if (source_idx == 6 && target_idx == 1) {
    return(0)  # Valid feedback loop
  }

  # Forward direction: calculate sequential distance
  if (target_idx > source_idx) {
    return(unname(target_idx - source_idx - 1))  # 0 = adjacent, 1 = skip one, etc.
  }

  # Backward (invalid) direction: penalize heavily
  return(5)
}

#' Check if Connection is Valid DAPSIWRM Transition
#'
#' Wrapper around network_analysis.R function for consistency
#'
#' @param source_type Source DAPSIWRM type
#' @param target_type Target DAPSIWRM type
#' @return Logical (1 = valid, 0 = invalid)
#' @export
check_valid_dapsiwrm_transition <- function(source_type, target_type) {

  # Use existing validation function if available
  if (exists("is_valid_dapsiwrm_transition")) {
    result <- is_valid_dapsiwrm_transition(source_type, target_type)
    return(as.numeric(result))
  }

  # Fallback: use distance calculation
  distance <- calculate_dapsiwrm_distance(source_type, target_type)
  return(as.numeric(distance <= 1))  # 0 or 1 = valid
}

# ==============================================================================
# Graph Feature Extraction
# ==============================================================================

#' Extract Graph Structural Features for ML Prediction
#'
#' Computes 8 structural features for a source-target node pair:
#' 1. Source outdegree
#' 2. Target indegree
#' 3. Source betweenness centrality
#' 4. Target betweenness centrality
#' 5. Shortest path length (or Inf if unreachable)
#' 6. DAPSIWRM type distance
#' 7. Valid DAPSIWRM transition (binary)
#' 8. Common neighbors count
#'
#' @param source_id Source node ID
#' @param target_id Target node ID
#' @param graph igraph object representing the current network
#' @param nodes Nodes dataframe (for type lookup)
#' @return Numeric vector of 8 features
#' @export
extract_graph_features <- function(source_id, target_id, graph, nodes) {

  # Default zero features if graph is invalid
  if (is.null(graph) || !inherits(graph, "igraph") || vcount(graph) == 0) {
    return(rep(0, 8))
  }

  # Check if nodes exist in graph
  source_exists <- source_id %in% V(graph)$name
  target_exists <- target_id %in% V(graph)$name

  if (!source_exists || !target_exists) {
    return(rep(0, 8))
  }

  # === Feature 1-2: Node Degrees ===
  source_outdegree <- tryCatch(
    degree(graph, v = source_id, mode = "out"),
    error = function(e) 0
  )

  target_indegree <- tryCatch(
    degree(graph, v = target_id, mode = "in"),
    error = function(e) 0
  )

  # === Feature 3-4: Betweenness Centrality ===
  # Calculate for all nodes (batch operation), then extract
  betweenness_scores <- tryCatch(
    betweenness(graph, directed = TRUE),
    error = function(e) rep(0, vcount(graph))
  )

  # Map node names to betweenness
  betweenness_lookup <- setNames(betweenness_scores, V(graph)$name)
  source_betweenness <- betweenness_lookup[source_id]
  target_betweenness <- betweenness_lookup[target_id]

  # Normalize betweenness (0-1 scale) to avoid large values
  max_betweenness <- max(betweenness_scores, na.rm = TRUE)
  if (max_betweenness > 0) {
    source_betweenness <- source_betweenness / max_betweenness
    target_betweenness <- target_betweenness / max_betweenness
  }

  # === Feature 5: Shortest Path Length ===
  shortest_path_length <- tryCatch({
    path <- shortest_paths(
      graph,
      from = source_id,
      to = target_id,
      mode = "out"
    )$vpath[[1]]

    if (length(path) == 0) {
      10  # Unreachable (use large value instead of Inf for ML)
    } else {
      length(path) - 1  # Number of edges
    }
  }, error = function(e) 10)

  # Cap at reasonable maximum
  shortest_path_length <- min(shortest_path_length, 10)

  # === Feature 6-7: DAPSIWRM Framework Features ===
  # Get source and target types from nodes
  source_type <- nodes$group[nodes$id == source_id]
  target_type <- nodes$group[nodes$id == target_id]

  # Handle missing types
  if (length(source_type) == 0 || length(target_type) == 0) {
    dapsiwrm_distance <- 5
    valid_transition <- 0
  } else {
    dapsiwrm_distance <- calculate_dapsiwrm_distance(source_type, target_type)
    valid_transition <- check_valid_dapsiwrm_transition(source_type, target_type)
  }

  # === Feature 8: Common Neighbors ===
  # Count nodes that are neighbors of both source and target
  common_neighbors <- tryCatch({
    source_neighbors <- neighbors(graph, v = source_id, mode = "out")
    target_neighbors <- neighbors(graph, v = target_id, mode = "in")

    # Convert to names for comparison
    source_neighbor_names <- V(graph)[source_neighbors]$name
    target_neighbor_names <- V(graph)[target_neighbors]$name

    length(intersect(source_neighbor_names, target_neighbor_names))
  }, error = function(e) 0)

  # Return 8-dim feature vector
  features <- c(
    source_outdegree,
    target_indegree,
    source_betweenness,
    target_betweenness,
    shortest_path_length,
    dapsiwrm_distance,
    valid_transition,
    common_neighbors
  )

  # Ensure numeric and no NAs
  features <- as.numeric(features)
  features[is.na(features)] <- 0

  return(features)
}

# ==============================================================================
# Batch Feature Extraction (for Training Data)
# ==============================================================================

#' Extract Graph Features for Multiple Pairs (Batch Operation)
#'
#' Efficiently extracts graph features for a batch of source-target pairs.
#' Pre-computes centrality metrics once for all nodes.
#'
#' @param source_ids Vector of source node IDs
#' @param target_ids Vector of target node IDs
#' @param graph igraph object
#' @param nodes Nodes dataframe
#' @return Matrix of graph features (n_pairs x 8)
#' @export
extract_graph_features_batch <- function(source_ids, target_ids, graph, nodes) {

  n_pairs <- length(source_ids)

  # Validate inputs
  if (length(target_ids) != n_pairs) {
    stop("source_ids and target_ids must have the same length")
  }

  # Default zero matrix if graph is invalid
  if (is.null(graph) || !inherits(graph, "igraph") || vcount(graph) == 0) {
    return(matrix(0, nrow = n_pairs, ncol = 8))
  }

  # Everything graph-level is computed once here; the per-pair work below is
  # plain R lookups. Per-pair igraph calls (shortest_paths, neighbors) cost
  # ~3 ms each in argument matching and vertex-sequence indexing, and every
  # unreachable pair raised an igraph warning, which made R's warning
  # collection the dominant cost for sparse graphs.
  vnames <- V(graph)$name
  source_ids <- as.character(source_ids)
  target_ids <- as.character(target_ids)

  features_matrix <- matrix(0, nrow = n_pairs, ncol = 8)
  valid <- which(source_ids %in% vnames & target_ids %in% vnames)
  if (length(valid) == 0) {
    return(features_matrix)
  }
  vs <- source_ids[valid]
  vt <- target_ids[valid]

  # Feature 1-2: Degrees
  outdegree_lookup <- setNames(degree(graph, mode = "out"), vnames)
  indegree_lookup <- setNames(degree(graph, mode = "in"), vnames)

  # Feature 3-4: Betweenness, normalised to 0-1 by the graph maximum
  betweenness_scores <- tryCatch(
    betweenness(graph, directed = TRUE),
    error = function(e) rep(0, vcount(graph))
  )
  betweenness_lookup <- setNames(betweenness_scores, vnames)
  max_betweenness <- max(betweenness_scores, na.rm = TRUE)
  source_betweenness <- unname(betweenness_lookup[vs])
  target_betweenness <- unname(betweenness_lookup[vt])
  if (max_betweenness > 0) {
    source_betweenness <- source_betweenness / max_betweenness
    target_betweenness <- target_betweenness / max_betweenness
  }

  # Feature 5: Shortest path length in edges, capped at 10 (10 = unreachable).
  # Unweighted graphs (everything create_igraph_from_data builds) use one hop
  # matrix for all distinct sources. A graph with a "weight" attribute keeps
  # the per-pair weighted search, because the hop count of the weighted
  # shortest path can differ from the unweighted one.
  if ("weight" %in% edge_attr_names(graph)) {
    shortest_path_length <- vapply(seq_along(vs), function(i) {
      tryCatch({
        path <- suppressWarnings(shortest_paths(
          graph, from = vs[i], to = vt[i], mode = "out"
        ))$vpath[[1]]
        if (length(path) == 0) 10 else min(length(path) - 1, 10)
      }, error = function(e) 10)
    }, numeric(1))
  } else {
    sources <- unique(vs)
    hops <- tryCatch(
      distances(graph, v = sources, to = V(graph), mode = "out", weights = NA),
      error = function(e) NULL
    )
    if (is.null(hops)) {
      shortest_path_length <- rep(10, length(vs))
    } else {
      shortest_path_length <- hops[cbind(match(vs, sources), match(vt, vnames))]
      shortest_path_length[!is.finite(shortest_path_length)] <- 10
      shortest_path_length <- pmin(shortest_path_length, 10)
    }
  }

  # Feature 6-7: DAPSIWRM type distance and transition validity
  type_lookup <- setNames(nodes$group, nodes$id)
  source_type <- unname(type_lookup[vs])
  target_type <- unname(type_lookup[vt])
  dapsiwrm_distance <- rep(5, length(vs))
  valid_transition <- rep(0, length(vs))
  typed <- which(!is.na(source_type) & !is.na(target_type))
  if (length(typed) > 0) {
    dapsiwrm_distance[typed] <- mapply(
      calculate_dapsiwrm_distance, source_type[typed], target_type[typed],
      USE.NAMES = FALSE
    )
    valid_transition[typed] <- mapply(
      check_valid_dapsiwrm_transition, source_type[typed], target_type[typed],
      USE.NAMES = FALSE
    )
  }

  # Feature 8: Common neighbours (out-neighbours of source that are also
  # in-neighbours of target)
  common_neighbors <- tryCatch({
    out_nb <- setNames(
      lapply(adjacent_vertices(graph, V(graph), mode = "out"),
             function(x) vnames[as.integer(x)]),
      vnames
    )
    in_nb <- setNames(
      lapply(adjacent_vertices(graph, V(graph), mode = "in"),
             function(x) vnames[as.integer(x)]),
      vnames
    )
    vapply(seq_along(vs), function(i) {
      length(intersect(out_nb[[vs[i]]], in_nb[[vt[i]]]))
    }, numeric(1))
  }, error = function(e) rep(0, length(vs)))

  features_matrix[valid, ] <- cbind(
    unname(outdegree_lookup[vs]),
    unname(indegree_lookup[vt]),
    source_betweenness,
    target_betweenness,
    shortest_path_length,
    dapsiwrm_distance,
    valid_transition,
    common_neighbors
  )

  features_matrix[is.na(features_matrix)] <- 0

  return(features_matrix)
}

# ==============================================================================
# Graph Caching (Session-Level)
# ==============================================================================

#' Graph Cache Environment
#'
#' Session-level cache to avoid rebuilding graphs repeatedly.
#' Implements LRU eviction when cache exceeds max size.
#' @export
GRAPH_CACHE <- new.env(parent = emptyenv())
.graph_cache_order <- character(0)  # Track insertion order for LRU eviction
.GRAPH_CACHE_MAX_SIZE <- 50L  # Maximum cached graphs (graphs are large objects)

#' Build or Retrieve Cached Graph
#'
#' Builds igraph from nodes/edges or retrieves from cache if available.
#' Implements LRU eviction when cache exceeds max size.
#'
#' @param nodes Nodes dataframe
#' @param edges Edges dataframe
#' @param cache_key Optional cache key (default: hash of nodes/edges)
#' @param force_rebuild Force rebuild even if cached (default: FALSE)
#' @return igraph object
#' @export
get_cached_graph <- function(nodes, edges, cache_key = NULL, force_rebuild = FALSE) {

  # Generate cache key if not provided
  if (is.null(cache_key)) {
    # Use number of nodes and edges as simple key
    cache_key <- sprintf("graph_n%d_e%d", nrow(nodes), nrow(edges))
  }

  # Check cache
  if (!force_rebuild && exists(cache_key, envir = GRAPH_CACHE)) {
    return(get(cache_key, envir = GRAPH_CACHE))
  }

  # Build graph
  graph <- tryCatch({
    if (exists("create_igraph_from_data")) {
      create_igraph_from_data(nodes, edges)
    } else {
      # Fallback: use igraph directly
      # Ensure nodes has 'name' column (igraph requirement)
      nodes_copy <- nodes
      if (!"name" %in% names(nodes_copy) && "id" %in% names(nodes_copy)) {
        nodes_copy$name <- nodes_copy$id
      }

      if (nrow(edges) == 0) {
        igraph::graph_from_data_frame(
          d = data.frame(from = character(0), to = character(0)),
          vertices = nodes_copy,
          directed = TRUE
        )
      } else {
        igraph::graph_from_data_frame(edges, directed = TRUE, vertices = nodes_copy)
      }
    }
  }, error = function(e) {
    warning("Failed to build graph: ", e$message)
    NULL
  })

  # Store in cache with LRU eviction

  if (!is.null(graph)) {
    # Evict oldest entries if cache is full
    cache_size <- length(.graph_cache_order)
    if (cache_size >= .GRAPH_CACHE_MAX_SIZE) {
      # Remove oldest 20% of entries (graphs are expensive, evict more aggressively)
      evict_count <- max(1L, as.integer(cache_size * 0.2))
      keys_to_remove <- .graph_cache_order[1:evict_count]
      for (k in keys_to_remove) {
        if (exists(k, envir = GRAPH_CACHE)) {
          rm(list = k, envir = GRAPH_CACHE)
        }
      }
      .graph_cache_order <<- .graph_cache_order[-(1:evict_count)]
    }

    assign(cache_key, graph, envir = GRAPH_CACHE)
    .graph_cache_order <<- c(.graph_cache_order, cache_key)
  }

  return(graph)
}

#' Clear Graph Cache
#'
#' Clears all cached graphs (useful when network structure changes)
#' @export
clear_graph_cache <- function() {
  rm(list = ls(envir = GRAPH_CACHE), envir = GRAPH_CACHE)
  .graph_cache_order <<- character(0)
  debug_log("Cleared", "ML_GRAPH")
}

#' Get Graph Cache Statistics
#'
#' @return List with cache size and max size
#' @export
get_graph_cache_stats <- function() {
  list(
    size = length(.graph_cache_order),
    max_size = .GRAPH_CACHE_MAX_SIZE,
    utilization = length(.graph_cache_order) / .GRAPH_CACHE_MAX_SIZE
  )
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' Get Graph Feature Dimension
#'
#' Returns the number of graph features (8)
#' @export
get_graph_feature_dim <- function() {
  8
}

#' Get Graph Feature Names
#'
#' Returns descriptive names for the 8 graph features
#' @export
get_graph_feature_names <- function() {
  c(
    "source_outdegree",
    "target_indegree",
    "source_betweenness_norm",
    "target_betweenness_norm",
    "shortest_path_length",
    "dapsiwrm_distance",
    "valid_dapsiwrm_transition",
    "common_neighbors"
  )
}

# ==============================================================================
# Initialization Message
# ==============================================================================

debug_log("ML Graph Features module loaded", "ML_GRAPH")
debug_log(sprintf("Graph feature extraction: %d dimensions", get_graph_feature_dim()), "ML_GRAPH")
debug_log("Features: degree, betweenness, shortest path, DAPSIWRM compliance, common neighbors", "ML_GRAPH")
debug_log("extract_graph_features(): Extract features for single pair", "ML_GRAPH")
debug_log("extract_graph_features_batch(): Batch extraction for training", "ML_GRAPH")
debug_log("get_cached_graph(): Session-level graph caching", "ML_GRAPH")
