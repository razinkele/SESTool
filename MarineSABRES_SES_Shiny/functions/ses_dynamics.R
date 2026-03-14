# functions/ses_dynamics.R
# =============================================================================
# SES Dynamics Analysis Engine
# Adapted from DTU/utils.R for integration into the MarineSABRES SES Toolbox
#
# Provides: Laplacian stability analysis, Boolean network modeling,
#           deterministic simulation, participation ratio analysis,
#           Monte Carlo state-shift analysis, intervention simulation,
#           and random forest variable importance.
#
# All functions are pure computation (no file I/O, no Shiny dependencies).
# Shiny modules handle visualization and user interaction.
#
# Original DTU functions by: Technical University of Denmark (T5.3)
# Refactored for MarineSABRES SES Toolbox by: MarineSABRES development team
# =============================================================================

# ============================================================================
# CONSTANTS: DYNAMICS_* constants and DYNAMICS_WEIGHT_MAP
# Defined in constants.R (loaded before this file)
# ============================================================================

# ============================================================================
# HELPER: Safe debug logging
# ============================================================================

#' Internal logging helper for ses_dynamics functions
#' @param msg Character message to log
#' @param level Log level string (default "INFO")
#' @keywords internal
.dyn_log <- function(msg, level = "INFO") {
  if (exists("debug_log", mode = "function")) {
    debug_log(paste("[SES_DYNAMICS]", msg), level)
  }
}

# ============================================================================
# HELPER: Matrix validation
# ============================================================================

#' Validate that input is a square numeric matrix
#' @param mat Object to validate
#' @param fn_name Name of the calling function (for error messages)
#' @return TRUE invisibly, or stops with an informative error
#' @keywords internal
.validate_matrix <- function(mat, fn_name = "ses_dynamics") {
  if (is.null(mat)) {
    stop(sprintf("[%s] Matrix is NULL", fn_name))
  }
  if (!is.matrix(mat)) {
    stop(sprintf("[%s] Input must be a matrix, got %s", fn_name, class(mat)[1]))
  }
  if (!is.numeric(mat)) {
    stop(sprintf("[%s] Matrix must be numeric", fn_name))
  }
  if (nrow(mat) != ncol(mat)) {
    stop(sprintf("[%s] Matrix must be square (%d x %d)", fn_name, nrow(mat), ncol(mat)))
  }
  if (nrow(mat) == 0) {
    stop(sprintf("[%s] Matrix is empty (0 x 0)", fn_name))
  }
  invisible(TRUE)
}

# ============================================================================
# 1. ADJACENCY MATRIX CONSTRUCTION
# ============================================================================

#' Build a square numeric adjacency matrix from parallel vectors
#'
#' Creates a named adjacency matrix from source, target, and weight vectors.
#' This is the low-level matrix builder; for CLD data, use
#' \code{\link{cld_to_numeric_matrix}} instead.
#'
#' @param from Character vector of source node names
#' @param to Character vector of target node names
#' @param weight Numeric vector of edge weights
#' @return Named square numeric matrix where mat[i,j] = weight of edge from i to j
#' @export
ses_make_matrix <- function(from, to, weight) {
  tryCatch({
    stopifnot(
      is.character(from),
      is.character(to),
      length(from) == length(to),
      length(from) == length(weight),
      is.numeric(weight)
    )

    elements <- unique(c(from, to))
    n <- length(elements)
    mat <- matrix(0, nrow = n, ncol = n,
                  dimnames = list(elements, elements))

    # Vectorized fill using matrix indexing
    row_idx <- match(from, elements)
    col_idx <- match(to, elements)
    valid <- !is.na(row_idx) & !is.na(col_idx)
    mat[cbind(row_idx[valid], col_idx[valid])] <- weight[valid]

    .dyn_log(sprintf("Built %dx%d adjacency matrix from %d edges", n, n, sum(valid)))
    return(mat)
  }, error = function(e) {
    .dyn_log(sprintf("ses_make_matrix failed: %s", e$message), "ERROR")
    stop(e)
  })
}


#' Convert CLD data (nodes + edges) to a square numeric adjacency matrix
#'
#' This is the primary bridge between the SES Toolbox data model and
#' the DTU analytical functions. Maps polarity/strength to numeric weights
#' using the DYNAMICS_WEIGHT_MAP from constants.R.
#'
#' @param nodes Data frame with at least 'id' and 'label' columns
#' @param edges Data frame with 'from', 'to', 'polarity', 'strength' columns
#' @param use_labels Logical: use labels (human-readable) or IDs as matrix names
#' @param weight_map Named list mapping "polarity+strength" keys to numeric weights.
#'   Default uses DYNAMICS_WEIGHT_MAP from constants.R.
#' @param include_confidence Logical: scale weights by confidence (confidence/5)
#' @return Named square numeric matrix, or NULL if input is invalid
#' @export
cld_to_numeric_matrix <- function(nodes, edges,
                                   use_labels = TRUE,
                                   weight_map = NULL,
                                   include_confidence = FALSE) {

  # Validate inputs
  if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0) {
    .dyn_log("cld_to_numeric_matrix: no nodes provided", "WARN")
    return(NULL)
  }
  if (is.null(edges) || !is.data.frame(edges) || nrow(edges) == 0) {
    .dyn_log("cld_to_numeric_matrix: no edges provided", "WARN")
    return(NULL)
  }
  if (!all(c("from", "to") %in% names(edges))) {
    stop("Edges data frame must contain 'from' and 'to' columns")
  }
  if (!"id" %in% names(nodes)) {
    stop("Nodes data frame must contain 'id' column")
  }

  if (is.null(weight_map)) {
    weight_map <- if (exists("DYNAMICS_WEIGHT_MAP")) DYNAMICS_WEIGHT_MAP else list(
      "+strong" = 1.0, "+medium" = 0.5, "+weak" = 0.25,
      "-strong" = -1.0, "-medium" = -0.5, "-weak" = -0.25
    )
  }

  # Build node name vector
  node_names <- if (use_labels && "label" %in% names(nodes)) {
    ifelse(is.na(nodes$label) | nodes$label == "", nodes$id, nodes$label)
  } else {
    nodes$id
  }
  # Ensure unique names (append suffix if duplicates)
  if (anyDuplicated(node_names)) {
    node_names <- make.unique(node_names, sep = "_")
  }
  names(node_names) <- nodes$id

  n <- length(node_names)
  mat <- matrix(0, nrow = n, ncol = n,
                dimnames = list(node_names, node_names))

  # Build O(1) id-to-index lookup
  id_to_idx <- setNames(seq_along(nodes$id), nodes$id)

  # Fill matrix
  for (i in seq_len(nrow(edges))) {
    from_idx <- id_to_idx[edges$from[i]]
    to_idx   <- id_to_idx[edges$to[i]]
    if (is.na(from_idx) || is.na(to_idx)) next

    polarity <- if ("polarity" %in% names(edges)) edges$polarity[i] else "+"
    strength <- if ("strength" %in% names(edges)) edges$strength[i] else "medium"

    key <- paste0(polarity, strength)
    w <- weight_map[[key]]
    if (is.null(w)) {
      # Fallback for unrecognized combinations
      w <- ifelse(polarity == "+", 0.5, -0.5)
      .dyn_log(sprintf("Unrecognized weight key '%s' - using fallback %.2f", key, w), "WARN")
    }

    # Optionally scale by confidence
    if (include_confidence && "confidence" %in% names(edges)) {
      conf <- suppressWarnings(as.numeric(edges$confidence[i]))
      if (!is.na(conf) && conf > 0) {
        w <- w * (conf / 5)
      }
    }

    mat[from_idx, to_idx] <- w
  }

  .dyn_log(sprintf("Built %dx%d numeric matrix from CLD (%d edges mapped)",
                    n, n, nrow(edges)))
  return(mat)
}


#' Assemble ISA segment-pair adjacency matrices into a single numeric matrix
#'
#' Reads ISA data (DAPSIWRM elements and their segment-pair adjacency matrices)
#' and assembles them into a single square numeric matrix suitable for
#' dynamics analysis.
#'
#' @param isa_data The isa_data list from project_data, containing element
#'   data frames (drivers, activities, etc.) and adjacency_matrices.
#' @return Named square numeric matrix, or NULL if insufficient data
#' @export
isa_to_numeric_matrix <- function(isa_data) {
  if (is.null(isa_data)) return(NULL)

  # Collect all element names across types
  types <- c("drivers", "activities", "pressures", "marine_processes",
             "ecosystem_services", "goods_benefits", "responses")

  all_elements <- list()
  for (type in types) {
    df <- isa_data[[type]]
    if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
      for (r in seq_len(nrow(df))) {
        all_elements[[df$id[r]]] <- df$name[r]
      }
    }
  }

  if (length(all_elements) == 0) return(NULL)

  ids <- names(all_elements)
  nms <- unname(unlist(all_elements))
  # Ensure unique names
  if (anyDuplicated(nms)) nms <- make.unique(nms, sep = "_")

  n <- length(ids)
  mat <- matrix(0, nrow = n, ncol = n, dimnames = list(nms, nms))

  id_to_idx <- setNames(seq_along(ids), ids)

  # Parse and fill from each segment-pair matrix
  adj_matrices <- isa_data$adjacency_matrices
  if (is.null(adj_matrices)) return(mat)

  # Use existing parser if available, otherwise minimal fallback
  parse_fn <- if (exists("parse_connection_value", mode = "function")) {
    parse_connection_value
  } else {
    function(val) {
      pol <- if (grepl("^\\+", val)) "+" else if (grepl("^-", val)) "-" else "+"
      str <- if (grepl("strong", val, ignore.case = TRUE)) "strong"
             else if (grepl("medium", val, ignore.case = TRUE)) "medium"
             else "weak"
      list(polarity = pol, strength = str)
    }
  }

  wmap <- if (exists("DYNAMICS_WEIGHT_MAP")) DYNAMICS_WEIGHT_MAP else list(
    "+strong" = 1.0, "+medium" = 0.5, "+weak" = 0.25,
    "-strong" = -1.0, "-medium" = -0.5, "-weak" = -0.25
  )

  for (pair_name in names(adj_matrices)) {
    seg_mat <- adj_matrices[[pair_name]]
    if (is.null(seg_mat) || !is.matrix(seg_mat)) next

    for (r in seq_len(nrow(seg_mat))) {
      for (cc in seq_len(ncol(seg_mat))) {
        val <- seg_mat[r, cc]
        if (is.na(val) || val == "") next

        parsed <- tryCatch(parse_fn(val), error = function(e) NULL)
        if (is.null(parsed)) next

        key <- paste0(parsed$polarity, parsed$strength)
        w <- wmap[[key]]
        if (is.null(w)) w <- 0.5

        from_id <- rownames(seg_mat)[r]
        to_id   <- colnames(seg_mat)[cc]
        fi <- id_to_idx[from_id]
        ti <- id_to_idx[to_id]
        if (!is.na(fi) && !is.na(ti)) {
          mat[fi, ti] <- w
        }
      }
    }
  }

  .dyn_log(sprintf("Assembled %dx%d numeric matrix from ISA data", n, n))
  return(mat)
}


# ============================================================================
# 2. LAPLACIAN STABILITY ANALYSIS
# ============================================================================

#' Compute Laplacian eigenvalues for structural stability analysis
#'
#' Computes eigenvalues of the graph Laplacian matrix to characterize
#' structural stability. The Laplacian L = D - A where D is the degree matrix.
#' A zero eigenvalue indicates a connected component. The smallest non-zero
#' eigenvalue (Fiedler value / algebraic connectivity) indicates how easily
#' the system can be disconnected.
#'
#' Adapted from DTU \code{SES.laplacian()}.
#'
#' @param mat Square numeric adjacency matrix
#' @param direction "cols" (default, out-degree Laplacian) or "rows" (in-degree)
#' @return Named list with:
#'   \describe{
#'     \item{eigenvalues}{Named numeric vector of eigenvalues (sorted ascending)}
#'     \item{fiedler_value}{Algebraic connectivity (smallest non-zero eigenvalue)}
#'     \item{n_components}{Number of connected components (count of zero eigenvalues)}
#'     \item{direction}{Direction used for computation}
#'   }
#' @export
laplacian_eigenvalues <- function(mat, direction = "cols") {
  tryCatch({
    .validate_matrix(mat, "laplacian_eigenvalues")

    if (direction == "rows") {
      L <- diag(rowSums(t(mat))) - t(mat)
    } else {
      L <- diag(rowSums(mat)) - mat
    }

    eig_vals <- Re(eigen(L)$values)
    names(eig_vals) <- rownames(mat)

    # Sort by magnitude
    eig_vals <- sort(eig_vals)

    # Fiedler value = smallest non-zero eigenvalue (algebraic connectivity)
    near_zero <- abs(eig_vals) < 1e-10
    n_components <- sum(near_zero)
    fiedler_value <- if (any(!near_zero)) min(abs(eig_vals[!near_zero])) else 0

    .dyn_log(sprintf("Laplacian (%s): %d components, Fiedler=%.4f",
                      direction, max(1L, n_components), fiedler_value))

    list(
      eigenvalues = eig_vals,
      fiedler_value = fiedler_value,
      n_components = max(1L, n_components),
      direction = direction
    )
  }, error = function(e) {
    .dyn_log(sprintf("laplacian_eigenvalues failed: %s", e$message), "ERROR")
    stop(e)
  })
}

#' @rdname laplacian_eigenvalues
#' @export
ses_laplacian_eigenvalues <- laplacian_eigenvalues


#' Laplacian stability analysis with interpretation
#'
#' Wrapper around \code{\link{laplacian_eigenvalues}} that adds stability
#' interpretation and summary statistics suitable for display in UI modules.
#'
#' @param mat Square numeric adjacency matrix
#' @param direction "cols" (default) or "rows"
#' @return Named list with all fields from \code{laplacian_eigenvalues} plus:
#'   \describe{
#'     \item{spectral_gap}{Difference between two smallest eigenvalues}
#'     \item{stability_class}{Character: "strongly_connected", "weakly_connected",
#'       "fragmented", or "disconnected"}
#'     \item{interpretation}{Human-readable interpretation string}
#'     \item{max_eigenvalue}{Largest eigenvalue (perturbation decay rate)}
#'   }
#' @export
laplacian_stability <- function(mat, direction = "cols") {
  tryCatch({
    result <- laplacian_eigenvalues(mat, direction = direction)

    ev <- result$eigenvalues
    n <- length(ev)

    # Spectral gap: difference between 1st and 2nd smallest eigenvalues
    sorted_ev <- sort(abs(ev))
    spectral_gap <- if (n >= 2) sorted_ev[2] - sorted_ev[1] else 0
    max_eigenvalue <- max(abs(ev))

    # Classify stability
    fv <- result$fiedler_value
    nc <- result$n_components

    stability_class <- if (nc > 1) {
      "disconnected"
    } else if (fv < 0.01) {
      "fragmented"
    } else if (fv < 0.5) {
      "weakly_connected"
    } else {
      "strongly_connected"
    }

    interpretation <- switch(stability_class,
      "disconnected" = sprintf(
        "System has %d disconnected components. Perturbations in one component cannot propagate to others.",
        nc),
      "fragmented" = sprintf(
        "System is technically connected but fragile (Fiedler value = %.4f). Small disruptions could fragment the network.",
        fv),
      "weakly_connected" = sprintf(
        "System is weakly connected (Fiedler value = %.4f). Moderate resilience to disruptions.",
        fv),
      "strongly_connected" = sprintf(
        "System is strongly connected (Fiedler value = %.4f). High structural resilience; perturbations propagate and dissipate efficiently.",
        fv)
    )

    c(result, list(
      spectral_gap = spectral_gap,
      max_eigenvalue = max_eigenvalue,
      stability_class = stability_class,
      interpretation = interpretation
    ))
  }, error = function(e) {
    .dyn_log(sprintf("laplacian_stability failed: %s", e$message), "ERROR")
    stop(e)
  })
}


# ============================================================================
# 3. BOOLEAN NETWORK ANALYSIS
# ============================================================================

#' Create Boolean network rules from a signed adjacency matrix
#'
#' Converts the matrix into BoolNet-compatible rules where positive
#' regulators activate and negative regulators inhibit (prefixed with !).
#' Regulators are combined with OR (|) logic. Nodes with no regulators
#' get self-referencing rules.
#'
#' Adapted from DTU \code{boolean.file.creation()}.
#'
#' @param mat Square numeric adjacency matrix (sign matters, magnitude ignored)
#' @return Data frame with columns:
#'   \describe{
#'     \item{targets}{BoolNet-compatible gene/node names}
#'     \item{factors}{Boolean rule expressions using |, !}
#'   }
#' @export
ses_create_boolean_rules <- function(mat) {
  tryCatch({
    .validate_matrix(mat, "ses_create_boolean_rules")

    bin <- sign(mat)

    # Clean names for BoolNet compatibility (alphanumeric + underscore only)
    clean_names <- gsub("[^[:alnum:]_]", "", gsub("\\s+", "_", colnames(bin)))
    # Ensure no empty names
    empty <- clean_names == ""
    if (any(empty)) clean_names[empty] <- paste0("node_", which(empty))
    # Ensure unique
    if (anyDuplicated(clean_names)) clean_names <- make.unique(clean_names, sep = "_")

    colnames(bin) <- clean_names
    rownames(bin) <- clean_names

    rules_df <- data.frame(
      targets = clean_names,
      factors = NA_character_,
      stringsAsFactors = FALSE
    )

    for (i in seq_len(ncol(bin))) {
      pos_regulators <- names(which(bin[, i] == 1))
      neg_regulators <- names(which(bin[, i] == -1))

      if (length(neg_regulators) > 0) {
        neg_regulators <- paste0("!", neg_regulators)
      }

      all_regulators <- c(pos_regulators, neg_regulators)

      if (length(all_regulators) == 0) {
        # Self-referencing rule for nodes with no regulators
        rules_df$factors[i] <- clean_names[i]
      } else {
        rules_df$factors[i] <- paste(all_regulators, collapse = " | ")
      }
    }

    .dyn_log(sprintf("Created Boolean rules for %d nodes", ncol(bin)))
    return(rules_df)
  }, error = function(e) {
    .dyn_log(sprintf("ses_create_boolean_rules failed: %s", e$message), "ERROR")
    stop(e)
  })
}


#' Run Boolean attractor analysis using BoolNet
#'
#' Performs exhaustive Boolean attractor search. Identifies all stable states
#' (fixed points) and limit cycles, along with their basin sizes.
#'
#' Adapted from DTU \code{boolean.analyses()}.
#'
#' @param boolean_rules Data frame with 'targets' and 'factors' columns
#'   (from \code{\link{ses_create_boolean_rules}})
#' @param max_nodes Maximum number of nodes for exhaustive search (default from
#'   DYNAMICS_MAX_BOOLEAN_NODES constant = 25). Exhaustive search is O(2^n).
#' @return Named list with:
#'   \describe{
#'     \item{n_states}{Total number of states (2^n)}
#'     \item{n_attractors}{Number of attractors found}
#'     \item{attractors}{List of data frames, each describing an attractor}
#'     \item{basins}{Numeric vector of basin sizes per attractor}
#'     \item{transition_graph}{igraph state transition graph, or NULL}
#'     \item{rules_used}{The boolean_rules data frame used}
#'     \item{n_genes}{Number of genes/nodes}
#'   }
#' @export
ses_boolean_attractors <- function(boolean_rules, max_nodes = NULL) {
  if (is.null(max_nodes)) {
    max_nodes <- if (exists("DYNAMICS_MAX_BOOLEAN_NODES")) DYNAMICS_MAX_BOOLEAN_NODES else 25L
  }

  if (!requireNamespace("BoolNet", quietly = TRUE)) {
    stop("Package 'BoolNet' is required for Boolean analysis. Install with: install.packages('BoolNet')")
  }

  n_genes <- nrow(boolean_rules)
  if (n_genes > max_nodes) {
    stop(sprintf(
      "Network has %d nodes, exceeding the maximum of %d for exhaustive Boolean analysis. Consider simplifying the network or increasing the limit.",
      n_genes, max_nodes
    ))
  }

  tryCatch({
    .dyn_log(sprintf("Running Boolean attractor analysis on %d nodes (2^%d = %d states)",
                      n_genes, n_genes, 2^n_genes))

    # Write rules to a temp file for BoolNet loading
    temp_file <- tempfile(fileext = ".csv")
    on.exit(unlink(temp_file), add = TRUE)
    write.csv(boolean_rules, temp_file, row.names = FALSE, quote = FALSE)

    # Load and analyse
    boolean_net <- BoolNet::loadNetwork(temp_file)
    attractors <- BoolNet::getAttractors(boolean_net, returnTable = TRUE)

    n_states <- length(attractors$stateInfo$table)
    n_attractors <- length(attractors$attractors)

    attractor_list <- vector("list", n_attractors)
    basin_sizes <- numeric(n_attractors)

    if (n_attractors > 0) {
      for (i in seq_len(n_attractors)) {
        attractor_list[[i]] <- tryCatch(
          as.data.frame(BoolNet::getAttractorSequence(attractors, i)),
          error = function(e) data.frame()
        )
        basin_sizes[i] <- attractors$attractors[[i]]$basinSize
      }
    }

    # State transition graph
    transition_graph <- tryCatch({
      BoolNet::plotStateGraph(attractors,
                              layout = igraph::layout.fruchterman.reingold,
                              plotIt = FALSE)
    }, error = function(e) {
      .dyn_log(sprintf("Could not create state transition graph: %s", e$message), "WARN")
      NULL
    })

    .dyn_log(sprintf("Boolean analysis complete: %d attractors found in %d states",
                      n_attractors, n_states))

    list(
      n_states = n_states,
      n_attractors = n_attractors,
      attractors = attractor_list,
      basins = basin_sizes,
      transition_graph = transition_graph,
      rules_used = boolean_rules,
      n_genes = n_genes
    )
  }, error = function(e) {
    .dyn_log(sprintf("ses_boolean_attractors failed: %s", e$message), "ERROR")
    stop(e)
  })
}


#' Convenience wrapper: Boolean network model from adjacency matrix
#'
#' Combines \code{\link{ses_create_boolean_rules}} and
#' \code{\link{ses_boolean_attractors}} into a single call.
#'
#' @param mat Square numeric adjacency matrix
#' @param max_nodes Maximum nodes for exhaustive Boolean search (default 25)
#' @return Named list with:
#'   \describe{
#'     \item{rules}{Data frame of Boolean rules}
#'     \item{analysis}{Full attractor analysis results (or NULL if too many nodes)}
#'     \item{n_nodes}{Number of nodes in the network}
#'     \item{skipped}{Logical: TRUE if analysis was skipped due to node limit}
#'   }
#' @export
boolean_model <- function(mat, max_nodes = NULL) {
  if (is.null(max_nodes)) {
    max_nodes <- if (exists("DYNAMICS_MAX_BOOLEAN_NODES")) DYNAMICS_MAX_BOOLEAN_NODES else 25L
  }

  tryCatch({
    .validate_matrix(mat, "boolean_model")

    rules <- ses_create_boolean_rules(mat)
    n_nodes <- nrow(rules)

    analysis <- NULL
    skipped <- FALSE

    if (n_nodes <= max_nodes) {
      analysis <- ses_boolean_attractors(rules, max_nodes = max_nodes)
    } else {
      .dyn_log(sprintf("Boolean analysis skipped: %d nodes exceeds limit of %d",
                        n_nodes, max_nodes), "WARN")
      skipped <- TRUE
    }

    list(
      rules = rules,
      analysis = analysis,
      n_nodes = n_nodes,
      skipped = skipped
    )
  }, error = function(e) {
    .dyn_log(sprintf("boolean_model failed: %s", e$message), "ERROR")
    stop(e)
  })
}


# ============================================================================
# 4. DETERMINISTIC SIMULATION
# ============================================================================

#' Run deterministic linear dynamics simulation
#'
#' Iterates the linear dynamical system: state[t] = t(mat) \%*\% state[t-1],
#' starting from a random or user-specified initial state. Monitors for
#' divergence and stops early if values exceed the threshold.
#'
#' Adapted from DTU \code{SES.simulate()}.
#'
#' @param mat Square numeric adjacency matrix
#' @param n_iter Number of iterations (default from DYNAMICS_DEFAULT_ITER = 500).
#'   Clamped to [DYNAMICS_MIN_ITER, DYNAMICS_MAX_ITER].
#' @param initial_state Optional numeric vector of initial state values
#'   (length must equal nrow(mat)). If NULL, uses random uniform [0,1].
#' @param detect_divergence Logical: stop early if values exceed
#'   DYNAMICS_DIVERGENCE_THRESHOLD (default TRUE)
#' @return Named list with:
#'   \describe{
#'     \item{time_series}{Matrix (rows=nodes, cols=timesteps)}
#'     \item{n_iter}{Number of iterations run}
#'     \item{diverged}{Logical: did the simulation diverge?}
#'     \item{diverged_at}{Integer iteration where divergence was detected, or NULL}
#'     \item{initial_state}{The initial state vector used}
#'   }
#' @export
simulate_dynamics <- function(mat, n_iter = NULL, initial_state = NULL,
                               detect_divergence = TRUE) {
  tryCatch({
    default_iter <- if (exists("DYNAMICS_DEFAULT_ITER")) DYNAMICS_DEFAULT_ITER else 500L
    min_iter <- if (exists("DYNAMICS_MIN_ITER")) DYNAMICS_MIN_ITER else 50L
    max_iter <- if (exists("DYNAMICS_MAX_ITER")) DYNAMICS_MAX_ITER else 5000L
    div_thresh <- if (exists("DYNAMICS_DIVERGENCE_THRESHOLD")) DYNAMICS_DIVERGENCE_THRESHOLD else 1e10

    if (is.null(n_iter)) n_iter <- default_iter
    n_iter <- max(min_iter, min(as.integer(n_iter), max_iter))

    .validate_matrix(mat, "simulate_dynamics")
    n <- nrow(mat)

    # Initial state
    if (is.null(initial_state)) {
      initial_state <- runif(n, 0, 1)
    }
    if (length(initial_state) != n) {
      stop(sprintf("initial_state length (%d) must equal matrix dimension (%d)",
                   length(initial_state), n))
    }

    sim <- matrix(NA_real_, nrow = n, ncol = n_iter)
    rownames(sim) <- rownames(mat)
    sim[, 1] <- initial_state

    mat_t <- t(mat)
    diverged <- FALSE
    diverged_at <- NULL

    for (i in 2:n_iter) {
      sim[, i] <- mat_t %*% matrix(sim[, i - 1], ncol = 1)

      # Divergence check
      if (detect_divergence && any(abs(sim[, i]) > div_thresh, na.rm = TRUE)) {
        diverged <- TRUE
        diverged_at <- i
        .dyn_log(sprintf("Simulation diverged at iteration %d", i), "WARN")
        # Fill remaining with NA
        if (i < n_iter) {
          sim[, (i + 1):n_iter] <- NA_real_
        }
        break
      }
    }

    .dyn_log(sprintf("Simulation complete: %d nodes, %d iterations%s",
                      n, n_iter,
                      if (diverged) sprintf(" (diverged at %d)", diverged_at) else ""))

    list(
      time_series = sim,
      n_iter = n_iter,
      diverged = diverged,
      diverged_at = diverged_at,
      initial_state = initial_state
    )
  }, error = function(e) {
    .dyn_log(sprintf("simulate_dynamics failed: %s", e$message), "ERROR")
    stop(e)
  })
}

#' @rdname simulate_dynamics
#' @export
ses_simulate <- simulate_dynamics


# ============================================================================
# 5. PARTICIPATION RATIO
# ============================================================================

#' Compute participation ratio for each eigenmode
#'
#' Measures how distributed each dynamical mode is across nodes using the
#' left and right eigenvectors of the Jacobian (transposed adjacency matrix).
#'
#' For each eigenmode k:
#'   PR_k = (sum_i |L_ik * R_ik|)^2 / (n * sum_i |L_ik * R_ik|^2)
#'
#' PR near 1/n = mode localized to one node.
#' PR near 1 = all nodes participate equally in that mode.
#'
#' Adapted from DTU \code{participation_ratio()}.
#'
#' @param mat Square numeric adjacency matrix
#' @return Data frame with columns:
#'   \describe{
#'     \item{component}{Node/component name (from matrix column names)}
#'     \item{participation_ratio}{Real-valued PR in [0, 1]}
#'     \item{eigenvalue_real}{Real part of eigenvalue for this mode}
#'     \item{eigenvalue_imag}{Imaginary part of eigenvalue}
#'   }
#' @export
participation_ratio <- function(mat) {
  tryCatch({
    .validate_matrix(mat, "participation_ratio")

    n <- nrow(mat)
    jacobian <- t(mat)

    eig <- eigen(jacobian)
    left_eigvec  <- eigen(t(jacobian))$vectors
    right_eigvec <- eig$vectors
    eigenvalues  <- eig$values

    # Participation ratio per eigenmode (column k of eigenvector matrices):
    #   product_ik = L_ik * R_ik
    #   PR_k = (sum_i |product_ik|)^2 / (n * sum_i |product_ik|^2)
    pr_values <- numeric(n)
    for (k in seq_len(n)) {
      product_k <- left_eigvec[, k] * right_eigvec[, k]
      sum_abs <- sum(Mod(product_k))
      sum_abs_sq <- sum(Mod(product_k)^2)
      if (sum_abs_sq > 0) {
        pr_values[k] <- Re(sum_abs^2 / (n * sum_abs_sq))
      } else {
        pr_values[k] <- 0
      }
    }

    # Clamp to [0, 1]
    pr_values <- pmax(0, pmin(1, pr_values))

    result <- data.frame(
      node = colnames(mat),
      component = colnames(mat),
      participation_ratio = pr_values,
      eigenvalue_real = Re(eigenvalues),
      eigenvalue_imag = Im(eigenvalues),
      stringsAsFactors = FALSE
    )

    .dyn_log(sprintf("Participation ratio computed for %d modes (range: %.3f - %.3f)",
                      n, min(pr_values), max(pr_values)))

    return(result)
  }, error = function(e) {
    .dyn_log(sprintf("participation_ratio failed: %s", e$message), "ERROR")
    stop(e)
  })
}

#' @rdname participation_ratio
#' @export
ses_participation_ratio <- participation_ratio


# ============================================================================
# 6. MONTE CARLO STATE-SHIFT ANALYSIS
# ============================================================================

#' Generate a single randomized adjacency matrix preserving sign structure
#'
#' Creates a randomized version of the adjacency matrix where only the
#' magnitudes change (sign structure is preserved). Used internally by
#' \code{\link{state_shift_monte_carlo}}.
#'
#' Adapted from DTU \code{simulate.mat()}.
#'
#' @param mat Square numeric adjacency matrix
#' @param type "uniform" (continuous [0,1]) or "ordinal" (discrete: 0, 0.25, 0.5, 0.75, 1)
#' @return Randomized matrix with same sign structure and dimensions
#' @export
ses_randomize_matrix <- function(mat, type = "uniform") {
  stopifnot(is.matrix(mat))

  n <- nrow(mat)
  m <- ncol(mat)

  if (type == "ordinal") {
    vals <- c(0, 0.25, 0.5, 0.75, 1)
    rand <- matrix(sample(vals, n * m, replace = TRUE), nrow = n, ncol = m)
  } else {
    rand <- matrix(runif(n * m, 0, 1), nrow = n, ncol = m)
  }

  # Preserve sign structure: sign(original) * |randomized|, only where original != 0
  result <- (mat != 0) * sign(mat) * rand
  dimnames(result) <- dimnames(mat)
  return(result)
}


#' Run Monte Carlo state-shift analysis
#'
#' Runs multiple simulations with randomized matrix magnitudes (sign structure
#' preserved) to assess how robust system outcomes are to parameter uncertainty.
#' For each Monte Carlo run, a randomized matrix is generated and simulated.
#' The final-state sign pattern (stable for last 100 steps) classifies each node
#' as positive or negative.
#'
#' Adapted from DTU \code{state.shift()}.
#'
#' @param mat Square numeric adjacency matrix
#' @param n_simulations Number of Monte Carlo runs (default from
#'   DYNAMICS_DEFAULT_GREED = 100). Clamped to [1, DYNAMICS_MAX_GREED].
#' @param n_iter Iterations per simulation (default from DYNAMICS_DEFAULT_ITER = 500)
#' @param type Randomization type: "uniform" or "ordinal"
#' @param target_nodes Character vector of node names that should end positive
#'   for a "success" outcome. If NULL, no success classification is done.
#' @param progress_callback Optional function(i, n) called after each simulation
#'   for progress reporting (e.g., shiny::incProgress)
#' @return Named list with:
#'   \describe{
#'     \item{final_states}{Matrix (nodes x simulations) of final-state sign products}
#'     \item{success_rate}{Proportion of simulations where all target_nodes ended positive (or NULL)}
#'     \item{target_success}{Logical vector per simulation (or NULL)}
#'     \item{n_simulations}{Number of simulations run}
#'     \item{n_iter}{Iterations per simulation}
#'     \item{randomization_type}{Type used}
#'     \item{target_nodes}{Target nodes used}
#'     \item{all_matrices}{List of all randomized matrices (for RF importance)}
#'   }
#' @export
state_shift_monte_carlo <- function(mat, n_simulations = NULL, n_iter = NULL,
                                     type = "uniform", target_nodes = NULL,
                                     progress_callback = NULL) {
  tryCatch({
    default_greed <- if (exists("DYNAMICS_DEFAULT_GREED")) DYNAMICS_DEFAULT_GREED else 100L
    max_greed <- if (exists("DYNAMICS_MAX_GREED")) DYNAMICS_MAX_GREED else 2000L

    if (is.null(n_simulations)) n_simulations <- default_greed
    n_simulations <- max(1L, min(as.integer(n_simulations), max_greed))

    .validate_matrix(mat, "state_shift_monte_carlo")
    n <- nrow(mat)
    node_names <- rownames(mat)

    .dyn_log(sprintf("Starting Monte Carlo state-shift: %d simulations, type=%s",
                      n_simulations, type))

    # Storage for final states
    final_states <- matrix(NA_real_, nrow = n, ncol = n_simulations)
    rownames(final_states) <- node_names

    # Storage for randomized matrices (needed for RF importance)
    all_matrices <- vector("list", n_simulations)

    for (i in seq_len(n_simulations)) {
      # Randomize matrix
      rand_mat <- ses_randomize_matrix(mat, type = type)
      all_matrices[[i]] <- rand_mat

      # Simulate
      sim_result <- simulate_dynamics(rand_mat, n_iter = n_iter, detect_divergence = TRUE)

      # Extract final state: use sign-product of last 100 steps (or all if < 100)
      ts <- sim_result$time_series
      total_cols <- ncol(ts)
      start_col <- max(1L, total_cols - 100L)

      # Remove NA columns (from divergence)
      valid_cols <- which(!is.na(ts[1, start_col:total_cols])) + start_col - 1
      if (length(valid_cols) > 0) {
        final_states[, i] <- apply(sign(ts[, valid_cols, drop = FALSE]), 1, prod)
      } else {
        final_states[, i] <- rep(NA_real_, n)
      }

      if (!is.null(progress_callback)) {
        tryCatch(progress_callback(i, n_simulations), error = function(e) NULL)
      }
    }

    # Success classification
    success_rate <- NULL
    target_success <- NULL

    if (!is.null(target_nodes) && length(target_nodes) > 0) {
      target_idx <- which(node_names %in% target_nodes)
      if (length(target_idx) > 0) {
        # A simulation is "successful" if all target nodes end positive
        target_success <- apply(final_states[target_idx, , drop = FALSE], 2, function(col) {
          all(!is.na(col) & col > 0)
        })
        success_rate <- mean(target_success, na.rm = TRUE)
      }
    }

    .dyn_log(sprintf("State-shift complete: %d simulations.%s",
                      n_simulations,
                      if (!is.null(success_rate))
                        sprintf(" Success rate: %.1f%%", success_rate * 100)
                      else ""))

    list(
      final_states = final_states,
      n_simulations = n_simulations,
      n_iter = n_iter,
      randomization_type = type,
      target_nodes = target_nodes,
      success_rate = success_rate,
      target_success = target_success,
      all_matrices = all_matrices
    )
  }, error = function(e) {
    .dyn_log(sprintf("state_shift_monte_carlo failed: %s", e$message), "ERROR")
    stop(e)
  })
}

#' @rdname state_shift_monte_carlo
#' @export
ses_state_shift <- state_shift_monte_carlo


# ============================================================================
# 7. INTERVENTION SIMULATION
# ============================================================================

#' Add an intervention node to the adjacency matrix
#'
#' Creates a new row (outgoing effects on affected nodes) and column
#' (incoming effects from indicator nodes) with random weights sampled
#' within the specified range. The intervention node is appended as the
#' last row/column.
#'
#' Adapted from DTU \code{simulate.measure()}.
#'
#' @param mat Square numeric adjacency matrix
#' @param name Name for the intervention node
#' @param affected_nodes Character vector of node names the intervention affects
#'   (outgoing edges from intervention)
#' @param indicator_nodes Character vector of node names that indicate
#'   intervention success (incoming edges to intervention)
#' @param effect_range Numeric vector c(lower, upper) for random weight sampling.
#'   Default c(-1, 1).
#' @return Extended adjacency matrix with intervention node appended
#' @export
ses_add_intervention <- function(mat, name, affected_nodes, indicator_nodes,
                                  effect_range = c(-1, 1)) {
  tryCatch({
    .validate_matrix(mat, "ses_add_intervention")
    stopifnot(is.character(name), nchar(name) > 0)

    node_names <- rownames(mat)
    n <- nrow(mat)

    # Validate nodes exist
    valid_affected <- affected_nodes[affected_nodes %in% node_names]
    valid_indicators <- indicator_nodes[indicator_nodes %in% node_names]

    if (length(valid_affected) == 0) {
      stop("None of the specified affected nodes exist in the matrix")
    }

    # Warn about invalid nodes
    invalid_affected <- setdiff(affected_nodes, node_names)
    if (length(invalid_affected) > 0) {
      .dyn_log(sprintf("Ignoring %d affected nodes not in matrix: %s",
                        length(invalid_affected),
                        paste(invalid_affected, collapse = ", ")), "WARN")
    }

    # Create new row (intervention -> affected nodes)
    new_row <- matrix(0, nrow = 1, ncol = n)
    colnames(new_row) <- node_names
    affect_idx <- match(valid_affected, node_names)
    new_row[1, affect_idx] <- runif(length(affect_idx),
                                     min(effect_range), max(effect_range))

    # Append row
    mat_ext <- rbind(mat, new_row)

    # Create new column (indicator nodes -> intervention)
    new_col <- matrix(0, nrow = n + 1, ncol = 1)
    if (length(valid_indicators) > 0) {
      indicator_idx <- match(valid_indicators, node_names)
      new_col[indicator_idx, 1] <- runif(length(indicator_idx),
                                          min(effect_range), max(effect_range))
    }

    # Append column
    mat_ext <- cbind(mat_ext, new_col)

    # Name the new node
    rownames(mat_ext)[n + 1] <- name
    colnames(mat_ext)[n + 1] <- name

    .dyn_log(sprintf("Added intervention '%s': %d affected, %d indicator nodes",
                      name, length(valid_affected), length(valid_indicators)))

    return(mat_ext)
  }, error = function(e) {
    .dyn_log(sprintf("ses_add_intervention failed: %s", e$message), "ERROR")
    stop(e)
  })
}


#' Compare original and intervention simulations
#'
#' Runs deterministic simulations on both the original and intervention-extended
#' matrices (using the same initial conditions for comparability) and produces
#' a per-node comparison of final states.
#'
#' @param mat_original Original adjacency matrix
#' @param mat_intervention Intervention-extended adjacency matrix
#'   (from \code{\link{ses_add_intervention}})
#' @param n_iter Number of simulation iterations
#' @return Data frame with columns:
#'   \describe{
#'     \item{node}{Node name}
#'     \item{state_original}{Final state in original simulation}
#'     \item{state_intervention}{Final state in intervention simulation}
#'     \item{delta}{Difference (intervention - original)}
#'     \item{change_direction}{"Improved", "Worsened", or "No change"}
#'   }
#' @export
ses_compare_interventions <- function(mat_original, mat_intervention, n_iter = NULL) {
  tryCatch({
    .validate_matrix(mat_original, "ses_compare_interventions (original)")
    .validate_matrix(mat_intervention, "ses_compare_interventions (intervention)")

    if (is.null(n_iter)) {
      n_iter <- if (exists("DYNAMICS_DEFAULT_ITER")) DYNAMICS_DEFAULT_ITER else 500L
    }

    # Run both simulations with same seed for comparability
    set.seed(42)
    sim_original <- simulate_dynamics(mat_original, n_iter = n_iter)

    # For intervention simulation, extend the initial state with a value for the new node(s)
    n_orig <- nrow(mat_original)
    n_interv <- nrow(mat_intervention)
    new_initial <- c(sim_original$initial_state,
                      rep(0.5, n_interv - n_orig))  # new nodes start at 0.5

    set.seed(42)
    sim_intervention <- simulate_dynamics(mat_intervention, n_iter = n_iter,
                                          initial_state = new_initial)

    # Get final states (last non-NA column)
    get_final <- function(ts) {
      valid_cols <- which(!is.na(ts[1, ]))
      if (length(valid_cols) == 0) return(rep(NA_real_, nrow(ts)))
      ts[, max(valid_cols)]
    }

    final_orig <- get_final(sim_original$time_series)
    final_intv <- get_final(sim_intervention$time_series)

    # Compare only common nodes
    common_nodes <- rownames(mat_original)
    comparison <- data.frame(
      node = common_nodes,
      state_original = final_orig[common_nodes],
      state_intervention = final_intv[common_nodes],
      delta = final_intv[common_nodes] - final_orig[common_nodes],
      stringsAsFactors = FALSE
    )

    comparison$change_direction <- ifelse(
      comparison$delta > 0, "Improved",
      ifelse(comparison$delta < 0, "Worsened", "No change")
    )

    .dyn_log(sprintf("Intervention comparison: %d/%d nodes improved",
                      sum(comparison$change_direction == "Improved"),
                      nrow(comparison)))

    return(comparison)
  }, error = function(e) {
    .dyn_log(sprintf("ses_compare_interventions failed: %s", e$message), "ERROR")
    stop(e)
  })
}


#' Run full intervention simulation pipeline
#'
#' High-level wrapper that adds an intervention to the network and evaluates
#' its effect using both deterministic simulation and (optionally) Monte Carlo
#' state-shift analysis.
#'
#' @param mat Square numeric adjacency matrix
#' @param name Name for the intervention
#' @param affected_nodes Character vector of nodes the intervention affects
#' @param indicator_nodes Character vector of indicator nodes
#' @param effect_range Numeric c(lower, upper) for effect weight sampling
#' @param n_iter Simulation iterations
#' @param run_monte_carlo Logical: also run Monte Carlo comparison? (default FALSE)
#' @param n_simulations Number of Monte Carlo runs (if run_monte_carlo = TRUE)
#' @param target_nodes Target nodes for success classification (Monte Carlo only)
#' @return Named list with:
#'   \describe{
#'     \item{intervention_matrix}{Extended adjacency matrix}
#'     \item{comparison}{Per-node comparison data frame}
#'     \item{monte_carlo_original}{State-shift results for original (or NULL)}
#'     \item{monte_carlo_intervention}{State-shift results for intervention (or NULL)}
#'   }
#' @export
intervention_simulation <- function(mat, name, affected_nodes, indicator_nodes,
                                     effect_range = c(-1, 1), n_iter = NULL,
                                     run_monte_carlo = FALSE,
                                     n_simulations = NULL,
                                     target_nodes = NULL) {
  tryCatch({
    .validate_matrix(mat, "intervention_simulation")

    # Build intervention matrix
    mat_intervention <- ses_add_intervention(
      mat, name, affected_nodes, indicator_nodes, effect_range
    )

    # Deterministic comparison
    comparison <- ses_compare_interventions(mat, mat_intervention, n_iter = n_iter)

    # Optional Monte Carlo
    mc_original <- NULL
    mc_intervention <- NULL

    if (run_monte_carlo) {
      .dyn_log("Running Monte Carlo comparison for intervention analysis")
      mc_original <- state_shift_monte_carlo(
        mat, n_simulations = n_simulations, n_iter = n_iter,
        target_nodes = target_nodes
      )
      mc_intervention <- state_shift_monte_carlo(
        mat_intervention, n_simulations = n_simulations, n_iter = n_iter,
        target_nodes = target_nodes
      )

      orig_rate <- if (!is.null(mc_original$success_rate)) {
        sprintf("%.1f%%", mc_original$success_rate * 100)
      } else {
        "N/A"
      }
      intv_rate <- if (!is.null(mc_intervention$success_rate)) {
        sprintf("%.1f%%", mc_intervention$success_rate * 100)
      } else {
        "N/A"
      }
      .dyn_log(sprintf("Monte Carlo comparison: original success=%s, intervention success=%s",
                        orig_rate, intv_rate))
    }

    list(
      intervention_matrix = mat_intervention,
      comparison = comparison,
      monte_carlo_original = mc_original,
      monte_carlo_intervention = mc_intervention
    )
  }, error = function(e) {
    .dyn_log(sprintf("intervention_simulation failed: %s", e$message), "ERROR")
    stop(e)
  })
}


# ============================================================================
# 8. RANDOM FOREST VARIABLE IMPORTANCE
# ============================================================================

#' Train random forest on state-shift outcomes to identify key connections
#'
#' Uses the randomized matrices and final states from a Monte Carlo
#' state-shift analysis to train a random forest classifier. The resulting
#' variable importance scores reveal which connection weights most influence
#' whether the system reaches a desirable outcome.
#'
#' Adapted from DTU \code{random.forest()} and \code{random.forest.res()}.
#'
#' @param state_shift_result Result list from \code{\link{state_shift_monte_carlo}}
#' @param target_nodes Character vector of node names for success classification.
#'   If NULL, uses target_nodes from the state_shift_result.
#' @param n_trees Number of trees (default from DYNAMICS_DEFAULT_RF_TREES = 1000)
#' @return Named list with:
#'   \describe{
#'     \item{model}{Trained randomForest object}
#'     \item{importance}{Data frame with connection names and importance scores}
#'     \item{top_variables}{Character vector of top 20 most important connections}
#'     \item{oob_error}{Out-of-bag error rate}
#'     \item{confusion_matrix}{Confusion matrix from OOB predictions}
#'     \item{n_trees}{Number of trees used}
#'     \item{n_features}{Number of connection features}
#'     \item{n_observations}{Number of training observations}
#'   }
#' @export
random_forest_importance <- function(state_shift_result, target_nodes = NULL,
                                      n_trees = NULL) {
  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install with: install.packages('randomForest')")
  }

  tryCatch({
    default_trees <- if (exists("DYNAMICS_DEFAULT_RF_TREES")) DYNAMICS_DEFAULT_RF_TREES else 1000L
    if (is.null(n_trees)) n_trees <- default_trees
    if (is.null(target_nodes)) target_nodes <- state_shift_result$target_nodes

    if (is.null(target_nodes) || length(target_nodes) == 0) {
      stop("target_nodes must be specified for outcome classification")
    }

    # Extract components from state-shift result
    all_mats <- state_shift_result$all_matrices
    final_states <- state_shift_result$final_states
    node_names <- rownames(final_states)

    if (is.null(all_mats) || length(all_mats) == 0) {
      stop("No randomized matrices available in state_shift_result. Run state_shift_monte_carlo() first.")
    }

    n_sims <- length(all_mats)

    # Feature matrix: flattened connection weights from each simulation
    # Only include non-zero connections from the original structure
    ref_mat <- all_mats[[1]]
    nonzero <- which(ref_mat != 0, arr.ind = TRUE)

    if (nrow(nonzero) == 0) {
      stop("No non-zero connections found in matrices")
    }

    # Create feature names from connection pairs
    feature_names <- paste(rownames(ref_mat)[nonzero[, 1]],
                            "->",
                            colnames(ref_mat)[nonzero[, 2]])

    # Extract features from each simulation
    features <- matrix(NA_real_, nrow = n_sims, ncol = nrow(nonzero))
    colnames(features) <- feature_names

    for (i in seq_len(n_sims)) {
      features[i, ] <- all_mats[[i]][nonzero]
    }

    # Classify outcomes
    target_idx <- which(node_names %in% target_nodes)
    if (length(target_idx) == 0) {
      stop("None of the target_nodes found in state-shift results")
    }

    outcomes <- apply(final_states[target_idx, , drop = FALSE], 2, function(col) {
      if (all(!is.na(col) & col > 0)) "Success" else "Failure"
    })

    # Combine into training data
    train_data <- as.data.frame(features, stringsAsFactors = FALSE)
    # Clean column names for randomForest
    colnames(train_data) <- make.names(colnames(train_data), unique = TRUE)
    train_data$outcome <- factor(outcomes)

    # Remove simulations with NA outcomes
    valid <- !is.na(train_data$outcome)
    train_data <- train_data[valid, ]

    if (nrow(train_data) < 10) {
      stop("Insufficient valid simulations for random forest training (need at least 10)")
    }

    # Check class balance
    class_counts <- table(train_data$outcome)
    if (length(class_counts) < 2) {
      stop(sprintf(
        "All simulations resulted in '%s' - cannot train classifier. Try different target_nodes or more simulations.",
        names(class_counts)[1]
      ))
    }

    .dyn_log(sprintf(
      "Training random forest: %d trees, %d features, %d observations (Success: %d, Failure: %d)",
      n_trees, ncol(features), nrow(train_data),
      class_counts["Success"], class_counts["Failure"]
    ))

    # Train model
    rf_model <- randomForest::randomForest(
      outcome ~ ., data = train_data,
      ntree = n_trees,
      importance = TRUE
    )

    # Extract importance
    imp <- randomForest::importance(rf_model)
    importance_df <- data.frame(
      connection = feature_names,
      clean_name = make.names(feature_names, unique = TRUE),
      MeanDecreaseAccuracy = imp[, "MeanDecreaseAccuracy"],
      MeanDecreaseGini = imp[, "MeanDecreaseGini"],
      stringsAsFactors = FALSE
    )
    importance_df <- importance_df[order(-importance_df$MeanDecreaseAccuracy), ]
    rownames(importance_df) <- NULL

    .dyn_log(sprintf("RF training complete. OOB error: %.2f%%. Top connection: %s",
                      rf_model$err.rate[n_trees, "OOB"] * 100,
                      importance_df$connection[1]))

    list(
      model = rf_model,
      importance = importance_df,
      top_variables = head(importance_df$connection, 20),
      oob_error = rf_model$err.rate[n_trees, "OOB"],
      confusion_matrix = rf_model$confusion,
      n_trees = n_trees,
      n_features = ncol(features),
      n_observations = nrow(train_data)
    )
  }, error = function(e) {
    .dyn_log(sprintf("random_forest_importance failed: %s", e$message), "ERROR")
    stop(e)
  })
}

#' @rdname random_forest_importance
#' @export
ses_rf_importance <- random_forest_importance


# ============================================================================
# 9. SUMMARY / DIAGNOSTICS
# ============================================================================

#' Run a quick diagnostic summary of a CLD network
#'
#' Convenience function that converts CLD data to a numeric matrix and runs
#' the core analyses that do not require optional packages (Laplacian,
#' simulation, participation ratio). Useful for initial assessment.
#'
#' @param nodes Node data frame
#' @param edges Edge data frame
#' @param n_iter Simulation iterations (default 200 for quick check)
#' @return Named list with matrix, laplacian, simulation, and participation_ratio results
#' @export
ses_dynamics_summary <- function(nodes, edges, n_iter = 200L) {
  tryCatch({
    mat <- cld_to_numeric_matrix(nodes, edges)
    if (is.null(mat)) {
      stop("Could not build numeric matrix from CLD data")
    }

    lap <- laplacian_stability(mat)
    sim <- simulate_dynamics(mat, n_iter = n_iter)
    pr  <- participation_ratio(mat)

    list(
      matrix = mat,
      n_nodes = nrow(mat),
      n_edges = sum(mat != 0),
      laplacian = lap,
      simulation = sim,
      participation_ratio = pr
    )
  }, error = function(e) {
    .dyn_log(sprintf("ses_dynamics_summary failed: %s", e$message), "ERROR")
    stop(e)
  })
}


# ============================================================================
# END OF SES DYNAMICS ENGINE
# ============================================================================
.dyn_log("SES Dynamics engine loaded successfully")
