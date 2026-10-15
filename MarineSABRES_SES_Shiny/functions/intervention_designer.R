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

#' Largest grid the engine accepts: sample.int() rejects n > 4.5e15 (just below
#' 2^52, where double indices stop being exact), so larger designs are refused.
SES_MAX_GRID_COMBINATIONS <- 4.5e15

#' Grid over the level sets: exhaustive up to `cap`, else a seeded sample.
#' Stops on designs with more than SES_MAX_GRID_COMBINATIONS combinations.
#' @return list(n_total, sampled, n_eval, indices); indices are 1-based doubles,
#'   sorted, and NULL when the grid is exhaustive.
ses_intervention_grid <- function(level_sets, cap, seed) {
  sizes <- lengths(level_sets)
  if (length(sizes) == 0) stop("design has no variable edges")
  if (any(sizes == 0)) stop("a variable edge has an empty level range")
  n_total <- prod(as.numeric(sizes))
  if (n_total > SES_MAX_GRID_COMBINATIONS) stop("design has too many combinations")
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

#' Evaluate a chunk of configurations together (spec §4.1, §4.4).
#'
#' x[t] = t(A) %*% x[t-1]; the fixed part of A is applied as one sparse
#' product, each variable cell (r, c) adds level * x[r] to x[c]. States are
#' divided by their L1 norm every 10 steps (exact for signs: the model is
#' linear). (a)/(b): strictly > 0 at each of the last `window` steps.
#' @param configs numeric matrix, one row per variable edge, one column per configuration
#' @return list(a = logical, b = logical), one element per configuration
ses_grid_evaluate <- function(dm, configs, objective_idx, sustain_idx, x0, steps, window) {
  A <- dm$matrix
  n <- nrow(A)
  C <- ncol(configs)
  stopifnot(steps >= 2, window >= 1, window <= steps,
            nrow(configs) == nrow(dm$cells), length(x0) == n)
  cells <- dm$cells
  fixed_t <- Matrix::Matrix(t(A), sparse = TRUE)
  X <- matrix(x0, nrow = n, ncol = C)
  ok_a <- rep(TRUE, C)
  ok_b <- rep(TRUE, C)
  first_check <- steps - window + 1L
  for (t in 2:steps) {
    Xn <- as.matrix(fixed_t %*% X)
    for (k in seq_len(nrow(cells))) {
      tgt <- cells[k, 2]
      Xn[tgt, ] <- Xn[tgt, ] + configs[k, ] * X[cells[k, 1], ]
    }
    X <- Xn
    if (t %% 10L == 0L) {
      s <- colSums(abs(X))
      s[s == 0] <- 1
      X <- X / rep(s, each = n)
    }
    if (t >= first_check) {
      if (length(objective_idx)) {
        ok_a <- ok_a & colSums(X[objective_idx, , drop = FALSE] > 0) == length(objective_idx)
      }
      if (length(sustain_idx)) {
        ok_b <- ok_b & colSums(X[sustain_idx, , drop = FALSE] > 0) == length(sustain_idx)
      }
    }
  }
  list(a = unname(ok_a), b = unname(ok_b))
}

#' D5.3 stability (FIN:1517): every Laplacian eigenvalue is real.
#' laplacian_eigenvalues() drops imaginary parts, so it cannot be reused here.
ses_is_stable_attractor <- function(mat, tol = 1e-9) {
  L <- diag(rowSums(mat), nrow = nrow(mat)) - mat
  ev <- eigen(L, only.values = TRUE)$values
  all(abs(Im(ev)) <= tol)
}

#' D5.3 ranking (C section 5.2 step 6): a, b, c descending, d ascending, grid order.
rank_simplest <- function(df) {
  cc <- df$c %in% TRUE
  df[order(-df$a, -df$b, -cc, df$d, df$index), , drop = FALSE]
}

#' Boolean pre-check (spec section 4.6): every variable edge at the strongest level of
#' its allowed sign; does any attractor keep every objective node ON?
ses_boolean_precheck <- function(dm, objective_idx, max_nodes) {
  n <- nrow(dm$matrix)
  out <- function(status, n_att = NA_integer_, n_des = NA_integer_) {
    list(status = status, n_nodes = n, n_attractors = n_att, n_desirable = n_des)
  }
  if (n > max_nodes) return(out("skipped"))
  extreme <- vapply(dm$level_sets, function(s) if (max(s) > 0) max(s) else min(s), numeric(1))
  bm <- tryCatch(boolean_model(ses_apply_config(dm, extreme), max_nodes = max_nodes),
                 error = function(e) NULL)
  if (is.null(bm)) return(out("unavailable"))
  if (isTRUE(bm$skipped) || is.null(bm$analysis)) return(out("skipped"))
  att <- bm$analysis$attractors
  desirable <- vapply(att, function(a) {
    if (is.null(a) || !is.data.frame(a) || nrow(a) == 0) return(FALSE)
    all(as.matrix(a[, objective_idx, drop = FALSE]) == 1)
  }, logical(1))
  out(if (any(desirable)) "passed" else "topology_change_needed",
      length(att), sum(desirable))
}

#' Final state of one configuration matrix, stepped exactly as ses_grid_evaluate()
#' does (x[t] = t(M) %*% x[t-1], L1 rescaling every 10 steps), so its signs agree
#' with criteria (a)/(b). Used for the Designer's comparison plot (spec §4.7).
#' @return numeric vector named by rownames(M)
ses_config_final_state <- function(M, x0, steps) {
  At <- t(M)
  x <- as.numeric(x0)
  for (t in 2:steps) {
    x <- as.vector(At %*% x)
    if (t %% 10L == 0L) {
      s <- sum(abs(x))
      if (s > 0) x <- x / s
    }
  }
  stats::setNames(x, rownames(M))
}

#' Order of the stability checks (spec §4.2(c)): rows passing (a) and (b) first,
#' then rows passing (a) only, each in grid order.
#' @keywords internal
.ses_stability_order <- function(a, b) c(which(a & b), which(a & !b))

#' Run a whole design (called in the background worker).
#' @param payload list(base, design, levels, objectives, sustain, seed, steps,
#'   window, cap, chunk, top_k, max_boolean_nodes, stability_budget_s). The
#'   stability checks stop once the run has taken stability_budget_s seconds
#'   (NULL = no limit); rows left unchecked keep c = NA and the result has
#'   stability_partial = TRUE.
#' @param progress optional function(done, total, precheck = NULL). Called once
#'   with done = 0 and the pre-check status before the grid runs (spec §4.6),
#'   then in fixed units of 1000: 0-900 over the grid chunks, 900-1000 over the
#'   stability checks, ending at 1000 (the bar never jumps back).
ses_run_design <- function(payload, progress = NULL) {
  t0 <- Sys.time()
  report <- function(done, precheck = NULL) {
    if (!is.function(progress)) return(invisible())
    if (is.null(precheck)) progress(done, 1000) else progress(done, 1000, precheck)
  }
  dm <- ses_design_matrix(payload$base, payload$design, payload$levels)
  nm <- rownames(dm$matrix)
  obj <- match(payload$objectives, nm)
  if (!length(obj) || anyNA(obj)) stop("objective nodes not found in the network")
  sus <- match(payload$sustain, nm)
  sus <- sus[!is.na(sus)]
  grid <- ses_intervention_grid(dm$level_sets, cap = payload$cap, seed = payload$seed)
  x0 <- .with_seed(payload$seed, stats::runif(nrow(payload$base)))
  if (!is.null(dm$new_node)) x0 <- c(x0, 0.5)
  precheck <- tryCatch(ses_boolean_precheck(dm, obj, payload$max_boolean_nodes),
                       error = function(e) list(status = "unavailable", n_nodes = nrow(dm$matrix),
                                                n_attractors = NA_integer_, n_desirable = NA_integer_))
  report(0, precheck$status)                     # visible while the grid runs (spec §4.6, §6)
  n_eval <- grid$n_eval
  index <- if (grid$sampled) grid$indices else seq_len(n_eval)
  a <- logical(n_eval); b <- logical(n_eval); d <- integer(n_eval)
  for (s in seq(1, n_eval, by = payload$chunk)) {
    pos <- s:min(n_eval, s + payload$chunk - 1)
    cfg <- ses_grid_decode(index[pos], dm$level_sets)
    r <- ses_grid_evaluate(dm, cfg, obj, sus, x0, payload$steps, payload$window)
    a[pos] <- r$a
    b[pos] <- r$b
    d[pos] <- as.integer(colSums(cfg[dm$count_rows, , drop = FALSE] != 0))
    report(floor(900 * max(pos) / n_eval))
  }
  # (c) for (a)&(b) rows first (so n_abc is exact), then (a)-only rows, until the
  # time budget (measured from the start of the run) is used up (spec §4.2(c)).
  budget <- if (is.null(payload$stability_budget_s)) Inf else as.numeric(payload$stability_budget_s)
  c_ok <- rep(NA, n_eval)
  succ <- .ses_stability_order(a, b)
  n_succ <- length(succ)
  n_checked <- 0L
  for (j in seq_along(succ)) {
    if (as.numeric(difftime(Sys.time(), t0, units = "secs")) >= budget) break
    i <- succ[j]
    c_ok[i] <- ses_is_stable_attractor(ses_apply_config(dm, ses_grid_decode(index[i], dm$level_sets)[, 1]))
    n_checked <- j
    if (j %% 500L == 0L) report(900 + floor(100 * j / n_succ))
  }
  report(1000)
  ranked <- rank_simplest(data.frame(index = index, a = a, b = b, c = c_ok, d = d))
  top <- utils::head(ranked, payload$top_k)
  top$rank <- seq_len(nrow(top))
  top <- top[, c("rank", "index", "a", "b", "c", "d")]
  rownames(top) <- NULL
  list(
    n_total = grid$n_total, n_eval = n_eval, sampled = grid$sampled,
    n_a = sum(a), n_ab = sum(a & b), n_abc = sum(a & b & (c_ok %in% TRUE)),
    stability_partial = n_checked < n_succ,
    share = sum(a) / n_eval,
    precheck = precheck,
    top = top,
    top_levels = ses_grid_decode(top$index, dm$level_sets),
    design_matrix = dm, base = payload$base, x0 = x0,
    objectives = payload$objectives, sustain = payload$sustain,
    seed = payload$seed, steps = payload$steps, window = payload$window,
    elapsed_s = as.numeric(difftime(Sys.time(), t0, units = "secs"))
  )
}
