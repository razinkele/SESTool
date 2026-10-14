# functions/intervention_designer.R
# =============================================================================
# WP5 WS-7a intervention designer engine (spec 2026-10-14, D5.3 modes A and B)
#
# Pure functions, no Shiny. Also sourced inside the callr background worker,
# which has no constants.R: every function the worker calls takes all of its
# parameters explicitly.
# =============================================================================

#' Evaluate `expr` with a fixed seed, then restore the caller's RNG state.
#' @keywords internal
.with_seed <- function(seed, expr) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv()) else NULL
  on.exit({
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  })
  set.seed(seed)
  expr
}

#' Allowed levels of one variable edge: the grid levels within [min, max].
ses_level_set <- function(min_level, max_level, levels) {
  levels[levels >= min_level - 1e-12 & levels <= max_level + 1e-12]
}

#' Level sets for every row of an edges data frame (columns min_level, max_level).
ses_level_sets <- function(edges, levels) {
  lapply(seq_len(nrow(edges)), function(i)
    ses_level_set(edges$min_level[i], edges$max_level[i], levels))
}

#' Grid over the level sets: exhaustive up to `cap`, else a seeded sample.
#' @return list(n_total, sampled, n_eval, indices); indices are 1-based doubles,
#'   sorted, and NULL when the grid is exhaustive.
ses_intervention_grid <- function(level_sets, cap, seed) {
  sizes <- lengths(level_sets)
  if (length(sizes) == 0) stop("design has no variable edges")
  if (any(sizes == 0)) stop("a variable edge has an empty level range")
  n_total <- prod(as.numeric(sizes))
  if (n_total <= cap) {
    return(list(n_total = n_total, sampled = FALSE, n_eval = n_total, indices = NULL))
  }
  idx <- .with_seed(seed, sample.int(n_total, size = cap))
  list(n_total = n_total, sampled = TRUE, n_eval = as.numeric(cap), indices = sort(as.numeric(idx)))
}

#' Decode 1-based grid indices into level values (mixed radix, edge 1 fastest).
#' @return numeric matrix: one row per variable edge, one column per index
ses_grid_decode <- function(idx, level_sets) {
  sizes <- lengths(level_sets)
  r <- as.numeric(idx) - 1
  out <- matrix(0, nrow = length(sizes), ncol = length(idx))
  for (j in seq_along(sizes)) {
    d <- r %% sizes[j]
    out[j, ] <- level_sets[[j]][d + 1]
    r <- (r - d) / sizes[j]
  }
  out
}

#' Default |level| range from an intervention type's EBM codes (C§3).
#' Behavioural (2.x) evidence is weakest and wins over every other code;
#' legal/regulatory (1.x), output and spatial measures are medium; else full.
#' @param priors named numeric c(behavioural = , regulatory = )
ses_evidence_prior_range <- function(ebm_codes, priors) {
  codes <- as.character(unlist(ebm_codes))
  w <- if (any(grepl("^2(\\.|$)", codes))) {
    priors[["behavioural"]]
  } else if (any(grepl("^1(\\.|$)", codes) | codes == "output" | grepl("^spatial(\\.|$)", codes))) {
    priors[["regulatory"]]
  } else {
    1
  }
  c(min = -w, max = w)
}

# Private: match edge endpoints to matrix dimnames; stop on unknown nodes.
.ses_match_nodes <- function(mat, from, to, msg) {
  ri <- match(from, rownames(mat))
  ci <- match(to, colnames(mat))
  bad <- unique(c(from[is.na(ri)], to[is.na(ci)]))
  if (length(bad)) stop(sprintf(msg, paste(bad, collapse = ", ")))
  list(ri = ri, ci = ci)
}

#' Build the design matrix: base (+ the new node) with variable cells zeroed.
#' @param design list(new_node = NULL|name, edges = data.frame(from, to, kind,
#'   min_level, max_level))
#' @return list(matrix, cells, level_sets, new_node, edges, count_rows)
ses_design_matrix <- function(base, design, levels) {
  if (!is.matrix(base) || nrow(base) != ncol(base) || is.null(rownames(base))) {
    stop("base must be a square matrix with node names")
  }
  edges <- design$edges
  if (is.null(edges) || nrow(edges) == 0) stop("design has no variable edges")
  mat <- base
  new_node <- design$new_node
  if (!is.null(new_node)) {
    if (new_node %in% rownames(base)) {
      stop(sprintf("new node name already exists in the network: %s", new_node))
    }
    nm <- c(rownames(base), new_node)
    mat <- rbind(cbind(base, 0), 0)
    dimnames(mat) <- list(nm, nm)
  }
  idx <- .ses_match_nodes(mat, edges$from, edges$to, "unknown node in design: %s")
  ri <- idx$ri
  ci <- idx$ci
  if (anyDuplicated(paste(ri, ci))) stop("duplicate variable edge in design")
  existing_cell <- ri <= nrow(base) & ci <= ncol(base)
  if (any(base[cbind(ri[existing_cell], ci[existing_cell])] != 0)) {
    stop("a variable edge already exists in the network (re-weighting is mode C)")
  }
  cells <- cbind(row = ri, col = ci)
  mat[cells] <- 0
  is_int <- edges$kind == "intervention"
  list(
    matrix = mat,
    cells = cells,
    level_sets = ses_level_sets(edges, levels),
    new_node = new_node,
    edges = edges,
    count_rows = if (any(is_int)) which(is_int) else seq_len(nrow(edges))
  )
}

#' Matrix of one configuration: `levels` written into the variable cells.
ses_apply_config <- function(dm, levels) {
  m <- dm$matrix
  m[dm$cells] <- levels
  m
}

#' Write fixed edge weights (data.frame from, to, weight) into a matrix.
ses_add_edges <- function(mat, edges_df) {
  idx <- .ses_match_nodes(mat, edges_df$from, edges_df$to, "unknown node: %s")
  mat[cbind(idx$ri, idx$ci)] <- as.numeric(edges_df$weight)
  mat
}

#' Nodes offered by the biological self-loop helper (D5.3 FIN:1079, 1463).
ses_self_loop_candidates <- function(labels, types) {
  labels[!is.na(types) & types == "Marine Processes & Functioning"]
}

#' DAPSIWRM check for a new edge between existing nodes (main process only).
#' Returns a logical so the caller can build a translated warning; the
#' validator's own message is untranslated English and is not shown.
#' @return TRUE when the transition is non-standard or invalid, else FALSE
ses_check_new_edge <- function(from_type, to_type) {
  if (!exists("validate_connection_with_feedback", mode = "function")) return(FALSE)
  fb <- validate_connection_with_feedback(from_type, to_type, strict = FALSE)
  isTRUE(fb$warning) || !isTRUE(fb$valid)
}

#' Ordinal code of a level (labels live in translations, key suffix level.<code>).
ses_level_code <- function(x) {
  codes <- c("-1" = "strong_neg", "-0.5" = "medium_neg", "-0.25" = "weak_neg", "0" = "none",
             "0.25" = "weak_pos", "0.5" = "medium_pos", "1" = "strong_pos")
  unname(codes[as.character(x)])
}
