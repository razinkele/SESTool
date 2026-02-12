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
# All functions are pure computation (no file I/O, no plotting).
# Shiny modules handle visualization and user interaction.
# =============================================================================

# ============================================================================
# CONSTANTS: DYNAMICS_* constants and DYNAMICS_WEIGHT_MAP
# Defined in constants.R (loaded before this file)
# ============================================================================

# ============================================================================
# HELPER: Safe debug logging
# ============================================================================

.dyn_log <- function(...) {
  if (exists("debug_log", mode = "function")) {
    debug_log("[SES_DYNAMICS]", ...)
  }
}

# ============================================================================
# 1. ADJACENCY MATRIX CONSTRUCTION
# ============================================================================

#' Build a square numeric adjacency matrix from parallel vectors
#'
#' @param from Character vector of source node names
#' @param to Character vector of target node names
#' @param weight Numeric vector of edge weights
#' @return Named square numeric matrix
ses_make_matrix <- function(from, to, weight) {
  stopifnot(
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

  return(mat)
}


#' Convert CLD data (nodes + edges) to a square numeric adjacency matrix
#'
#' This is the primary bridge between the SES Toolbox data model and
#' the DTU analytical functions.
#'
#' @param nodes Data frame with at least 'id' and 'label' columns
#' @param edges Data frame with 'from', 'to', 'polarity', 'strength' columns
#' @param use_labels Logical: use labels (human-readable) or IDs as matrix names
#' @param weight_map Named list mapping "polarity+strength" keys to numeric weights
#' @param include_confidence Logical: scale weights by confidence (confidence/5)
#' @return Named square numeric matrix, or NULL if input is invalid
cld_to_numeric_matrix <- function(nodes, edges,
                                   use_labels = TRUE,
                                   weight_map = NULL,
                                   include_confidence = FALSE) {

  # Validate inputs
  if (is.null(nodes) || !is.data.frame(nodes) || nrow(nodes) == 0) {
    .dyn_log("cld_to_numeric_matrix: no nodes provided")
    return(NULL)
  }
  if (is.null(edges) || !is.data.frame(edges) || nrow(edges) == 0) {
    .dyn_log("cld_to_numeric_matrix: no edges provided")
    return(NULL)
  }
  if (!all(c("from", "to") %in% names(edges))) {
    stop("Edges data frame must contain 'from' and 'to' columns")
  }
  if (!"id" %in% names(nodes)) {
    stop("Nodes data frame must contain 'id' column")
  }

  if (is.null(weight_map)) weight_map <- DYNAMICS_WEIGHT_MAP

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
      .dyn_log("Unrecognized weight key:", key, "- using fallback", w)
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

  return(mat)
}


#' Assemble ISA segment-pair adjacency matrices into a single numeric matrix
#'
#' @param isa_data The isa_data list from project_data
#' @return Named square numeric matrix, or NULL if insufficient data
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
  id_to_name <- setNames(nms, ids)

  # Parse and fill from each segment-pair matrix
  adj_matrices <- isa_data$adjacency_matrices
  if (is.null(adj_matrices)) return(mat)

  parse_fn <- if (exists("parse_connection_value", mode = "function")) {
    parse_connection_value
  } else {
    # Minimal fallback parser
    function(val) {
      pol <- if (grepl("^\\+", val)) "+" else if (grepl("^-", val)) "-" else "+"
      str <- if (grepl("strong", val, ignore.case = TRUE)) "strong"
             else if (grepl("medium", val, ignore.case = TRUE)) "medium"
             else "weak"
      list(polarity = pol, strength = str)
    }
  }

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
        w <- DYNAMICS_WEIGHT_MAP[[key]]
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

  return(mat)
}


# ============================================================================
# 2. LAPLACIAN STABILITY ANALYSIS
# ============================================================================

#' Compute Laplacian eigenvalues for structural stability analysis
#'
#' @param mat Square numeric adjacency matrix
#' @param direction "cols" (default, out-degree Laplacian) or "rows" (in-degree)
#' @return Named list with $eigenvalues (named numeric vector),
#'         $fiedler_value (algebraic connectivity), $n_components
ses_laplacian_eigenvalues <- function(mat, direction = "cols") {
  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))

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

  list(
    eigenvalues = eig_vals,
    fiedler_value = fiedler_value,
    n_components = max(1L, n_components),
    direction = direction
  )
}


# ============================================================================
# 3. BOOLEAN NETWORK ANALYSIS
# ============================================================================

#' Create Boolean network rules from a signed adjacency matrix
#'
#' Converts the matrix into BoolNet-compatible rules where positive
#' regulators activate and negative regulators inhibit (prefixed with !).
#' Regulators are combined with OR (|) logic.
#'
#' @param mat Square numeric adjacency matrix (sign matters, magnitude ignored)
#' @return Data frame with columns 'targets' and 'factors'
ses_create_boolean_rules <- function(mat) {
  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))

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

  return(rules_df)
}


#' Run Boolean attractor analysis using BoolNet
#'
#' @param boolean_rules Data frame with 'targets' and 'factors' columns
#'   (from ses_create_boolean_rules)
#' @param max_nodes Maximum number of nodes for exhaustive search (default 25)
#' @return Named list with $n_states, $n_attractors, $attractors, $basins,
#'         $transition_graph (igraph), $rules_used
ses_boolean_attractors <- function(boolean_rules, max_nodes = NULL) {
  if (is.null(max_nodes)) max_nodes <- DYNAMICS_MAX_BOOLEAN_NODES

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

  .dyn_log("Running Boolean attractor analysis on", n_genes, "nodes")

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
    state_graph <- BoolNet::plotStateGraph(attractors,
                                            layout = igraph::layout.fruchterman.reingold,
                                            plotIt = FALSE)
    state_graph
  }, error = function(e) {
    .dyn_log("Could not create state transition graph:", e$message)
    NULL
  })

  .dyn_log("Boolean analysis complete:", n_attractors, "attractors found in",
           n_states, "states")

  list(
    n_states = n_states,
    n_attractors = n_attractors,
    attractors = attractor_list,
    basins = basin_sizes,
    transition_graph = transition_graph,
    rules_used = boolean_rules,
    n_genes = n_genes
  )
}


# ============================================================================
# 4. DETERMINISTIC SIMULATION
# ============================================================================

#' Run deterministic linear dynamics simulation
#'
#' Iterates: state[t] = t(mat) %*% state[t-1]
#' Starting from a random or user-specified initial state.
#'
#' @param mat Square numeric adjacency matrix
#' @param n_iter Number of iterations (default 500)
#' @param initial_state Optional numeric vector of initial state values (length = nrow(mat))
#' @param detect_divergence Logical: stop early if values exceed threshold
#' @return Named list with $time_series (matrix: rows=nodes, cols=timesteps),
#'         $diverged (logical), $diverged_at (integer or NULL)
ses_simulate <- function(mat, n_iter = NULL, initial_state = NULL,
                          detect_divergence = TRUE) {
  if (is.null(n_iter)) n_iter <- DYNAMICS_DEFAULT_ITER
  n_iter <- max(DYNAMICS_MIN_ITER, min(n_iter, DYNAMICS_MAX_ITER))

  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))
  n <- nrow(mat)

  # Initial state
  if (is.null(initial_state)) {
    initial_state <- runif(n, 0, 1)
  }
  stopifnot(length(initial_state) == n)

  sim <- matrix(NA_real_, nrow = n, ncol = n_iter)
  rownames(sim) <- rownames(mat)
  sim[, 1] <- initial_state

  mat_t <- t(mat)
  diverged <- FALSE
  diverged_at <- NULL

  for (i in 2:n_iter) {
    sim[, i] <- mat_t %*% matrix(sim[, i - 1], ncol = 1)

    # Divergence check
    if (detect_divergence && any(abs(sim[, i]) > DYNAMICS_DIVERGENCE_THRESHOLD, na.rm = TRUE)) {
      diverged <- TRUE
      diverged_at <- i
      .dyn_log("Simulation diverged at iteration", i)
      # Fill remaining with last valid values
      if (i < n_iter) {
        sim[, (i + 1):n_iter] <- NA_real_
      }
      break
    }
  }

  list(
    time_series = sim,
    n_iter = n_iter,
    diverged = diverged,
    diverged_at = diverged_at,
    initial_state = initial_state
  )
}


# ============================================================================
# 5. PARTICIPATION RATIO
# ============================================================================

#' Compute participation ratio for each eigenmode
#'
#' Measures how distributed each dynamical mode is across nodes.
#' PR near 1/n = mode localized to one node.
#' PR near 1 = all nodes participate equally.
#'
#' @param mat Square numeric adjacency matrix
#' @return Data frame with columns 'node', 'participation_ratio', 'eigenvalue'
ses_participation_ratio <- function(mat) {
  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))

  n <- nrow(mat)
  jacobian <- t(mat)

  eig <- eigen(jacobian)
  left_eigvec  <- eigen(t(jacobian))$vectors
  right_eigvec <- eig$vectors
  eigenvalues  <- eig$values

  # Participation ratio: PR_k = (sum |L_ik * R_ik|)^2 / (n * sum |L_ik * R_ik|^2)
  product <- left_eigvec * right_eigvec
  pr <- Re(rowSums(product)^2) / Re(n * rowSums(product^2))

  # Ensure PR values are real and bounded

  pr <- pmax(0, pmin(1, Re(pr)))

  data.frame(
    node = colnames(mat),
    participation_ratio = pr,
    eigenvalue_real = Re(eigenvalues),
    eigenvalue_imag = Im(eigenvalues),
    stringsAsFactors = FALSE
  )
}


# ============================================================================
# 6. MONTE CARLO STATE-SHIFT ANALYSIS
# ============================================================================

#' Generate a single randomized adjacency matrix preserving sign structure
#'
#' @param mat Square numeric adjacency matrix
#' @param type "uniform" (continuous [0,1]) or "ordinal" (discrete: 0, 0.25, 0.5, 0.75, 1)
#' @return Randomized matrix with same sign structure
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

  # Preserve sign structure: sign(original) * |randomized|
  result <- (mat != 0) * sign(mat) * rand
  dimnames(result) <- dimnames(mat)
  return(result)
}


#' Run Monte Carlo state-shift analysis
#'
#' Runs multiple simulations with randomized matrix magnitudes (sign preserved)
#' to assess outcome robustness.
#'
#' @param mat Square numeric adjacency matrix
#' @param n_simulations Number of Monte Carlo runs (default 100)
#' @param n_iter Iterations per simulation (default 500)
#' @param type Randomization type: "uniform" or "ordinal"
#' @param target_nodes Character vector of node names that should end positive
#'   for a "success" outcome. If NULL, no success classification is done.
#' @param progress_callback Optional function(i, n) called after each simulation
#' @return Named list with $final_states (matrix: nodes x simulations),
#'         $success_rate (numeric or NULL), $target_success (logical vector),
#'         $n_simulations, $randomization_type
ses_state_shift <- function(mat, n_simulations = NULL, n_iter = NULL,
                             type = "uniform", target_nodes = NULL,
                             progress_callback = NULL) {

  if (is.null(n_simulations)) n_simulations <- DYNAMICS_DEFAULT_GREED
  if (is.null(n_iter)) n_iter <- DYNAMICS_DEFAULT_ITER
  n_simulations <- max(1L, min(n_simulations, DYNAMICS_MAX_GREED))

  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))
  n <- nrow(mat)
  node_names <- rownames(mat)

  # Storage for final states
  final_states <- matrix(NA_real_, nrow = n, ncol = n_simulations)
  rownames(final_states) <- node_names

  # Storage for randomized matrices (optional, can be large)
  all_matrices <- vector("list", n_simulations)

  for (i in seq_len(n_simulations)) {
    # Randomize matrix
    rand_mat <- ses_randomize_matrix(mat, type = type)
    all_matrices[[i]] <- rand_mat

    # Simulate
    sim_result <- ses_simulate(rand_mat, n_iter = n_iter, detect_divergence = TRUE)

    # Extract final state: use sign-product of last 100 steps (or all if < 100)
    ts <- sim_result$time_series
    start_col <- max(1L, ncol(ts) - 100L)
    end_col <- ncol(ts)

    # Remove NA columns (from divergence)
    valid_cols <- which(!is.na(ts[1, start_col:end_col])) + start_col - 1
    if (length(valid_cols) > 0) {
      final_states[, i] <- apply(sign(ts[, valid_cols, drop = FALSE]), 1, prod)
    } else {
      final_states[, i] <- rep(NA_real_, n)
    }

    if (!is.null(progress_callback)) {
      progress_callback(i, n_simulations)
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

  .dyn_log("State-shift complete:", n_simulations, "simulations.",
           if (!is.null(success_rate)) paste("Success rate:", round(success_rate * 100, 1), "%") else "")

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
}


# ============================================================================
# 7. INTERVENTION SIMULATION
# ============================================================================

#' Add an intervention node to the adjacency matrix
#'
#' Creates a new row (outgoing effects on affected nodes) and column
#' (incoming effects from indicator nodes) with random weights.
#'
#' @param mat Square numeric adjacency matrix
#' @param name Name for the intervention node
#' @param affected_nodes Character vector of node names the intervention affects
#' @param indicator_nodes Character vector of node names that indicate intervention success
#' @param effect_range Numeric vector c(lower, upper) for random weight sampling
#' @return Extended adjacency matrix with intervention node appended
ses_add_intervention <- function(mat, name, affected_nodes, indicator_nodes,
                                  effect_range = c(-1, 1)) {
  stopifnot(is.matrix(mat), nrow(mat) == ncol(mat))
  stopifnot(is.character(name), nchar(name) > 0)

  node_names <- rownames(mat)
  n <- nrow(mat)

  # Validate nodes exist
  valid_affected <- affected_nodes[affected_nodes %in% node_names]
  valid_indicators <- indicator_nodes[indicator_nodes %in% node_names]

  if (length(valid_affected) == 0) {
    stop("None of the specified affected nodes exist in the matrix")
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

  return(mat_ext)
}


#' Compare original and intervention simulations
#'
#' @param mat_original Original adjacency matrix
#' @param mat_intervention Intervention-extended adjacency matrix
#' @param n_iter Number of simulation iterations
#' @return Data frame comparing final states per node
ses_compare_interventions <- function(mat_original, mat_intervention, n_iter = NULL) {
  if (is.null(n_iter)) n_iter <- DYNAMICS_DEFAULT_ITER

  # Run both simulations with same seed for comparability
  set.seed(42)
  sim_original <- ses_simulate(mat_original, n_iter = n_iter)

  # For intervention simulation, extend the initial state with a value for the new node
  n_orig <- nrow(mat_original)
  n_interv <- nrow(mat_intervention)
  new_initial <- c(sim_original$initial_state,
                    rep(0.5, n_interv - n_orig))  # new nodes start at 0.5

  set.seed(42)
  sim_intervention <- ses_simulate(mat_intervention, n_iter = n_iter,
                                    initial_state = new_initial)

  # Get final states (last non-NA column)
  get_final <- function(ts) {
    last_valid <- max(which(!is.na(ts[1, ])))
    ts[, last_valid]
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

  comparison$change_direction <- ifelse(comparison$delta > 0, "Improved",
                                  ifelse(comparison$delta < 0, "Worsened", "No change"))

  return(comparison)
}


# ============================================================================
# 8. RANDOM FOREST VARIABLE IMPORTANCE
# ============================================================================

#' Train random forest on state-shift outcomes to identify key connections
#'
#' @param state_shift_result Result from ses_state_shift()
#' @param target_nodes Character vector of node names for success classification
#' @param n_trees Number of trees (default 1000)
#' @return Named list with $model, $importance (data frame), $top_variables,
#'         $oob_error, $confusion_matrix
ses_rf_importance <- function(state_shift_result, target_nodes = NULL,
                               n_trees = NULL) {
  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("Package 'randomForest' is required. Install with: install.packages('randomForest')")
  }

  if (is.null(n_trees)) n_trees <- DYNAMICS_DEFAULT_RF_TREES
  if (is.null(target_nodes)) target_nodes <- state_shift_result$target_nodes

  if (is.null(target_nodes) || length(target_nodes) == 0) {
    stop("target_nodes must be specified for outcome classification")
  }

  # Build training data from randomized matrices
  all_mats <- state_shift_result$all_matrices
  final_states <- state_shift_result$final_states
  node_names <- rownames(final_states)

  if (is.null(all_mats) || length(all_mats) == 0) {
    stop("No randomized matrices available in state_shift_result")
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

  .dyn_log("Training random forest:", n_trees, "trees,", ncol(features),
           "features,", nrow(train_data), "observations")

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
    clean_name = colnames(features),
    MeanDecreaseAccuracy = imp[, "MeanDecreaseAccuracy"],
    MeanDecreaseGini = imp[, "MeanDecreaseGini"],
    stringsAsFactors = FALSE
  )
  importance_df <- importance_df[order(-importance_df$MeanDecreaseAccuracy), ]
  rownames(importance_df) <- NULL

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
}
