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
