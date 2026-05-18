# ==============================================================================
# Collaborative Filtering for SES Element Recommendations
# ==============================================================================
#
# Item-based collaborative filtering using truncated SVD. "Users" are
# project authors / saved-project sessions; "items" are SES elements.
# Given a user's partial element selection, recommends elements that
# co-occur in similar users' projects.
#
# Honest scope: at v1.15.0 the user × item matrix has only 7 rows
# (the 7 production templates) because the real user log is empty.
# As more users save projects, the matrix expands and recommendations
# improve. The interface stays stable; only the underlying matrix grows.
#
# Algorithm:
#   1. Build user × item binary matrix M (1 if user has element, 0 otherwise).
#   2. Truncated SVD: M ≈ U Σ Vᵀ, rank k=8 (capped at min(n_users, n_items)).
#   3. Item embeddings = V[, 1:k] · diag(Σ[1:k])
#   4. For a query (current user's selected items), average their item
#      embeddings → query vector q.
#   5. Score each candidate item by cosine(q, V_item). Return top-k unseen items.
#
# Storage: matrix + factorization persisted to data/ml_cf_state.rds.
# ==============================================================================

CF_CONFIG <- list(
  rank = 8L,                    # truncated SVD rank
  store_path = "data/ml_cf_state.rds",
  min_users = 2L                # below this, no recommendations
)

#' Build the user × item matrix from a list of (user_id, items) records
#'
#' @param records List of lists. Each entry: list(user_id, items = character()).
#' @return list(matrix, users, items)
#' @export
build_cf_matrix <- function(records) {
  users <- unique(vapply(records, function(r) as.character(r$user_id), character(1)))
  all_items <- unique(unlist(lapply(records, function(r) as.character(r$items))))
  M <- matrix(0, nrow = length(users), ncol = length(all_items),
              dimnames = list(users, all_items))
  for (r in records) {
    uid <- as.character(r$user_id)
    its <- as.character(r$items)
    its <- intersect(its, all_items)
    M[uid, its] <- 1
  }
  list(matrix = M, users = users, items = all_items)
}

#' Fit truncated SVD on the user × item matrix
#'
#' @param mat_struct Output of build_cf_matrix.
#' @param rank Integer. Truncation rank.
#' @return list(item_embeddings, user_embeddings, items, users)
#' @export
fit_cf_svd <- function(mat_struct, rank = CF_CONFIG$rank) {
  M <- mat_struct$matrix
  if (nrow(M) < CF_CONFIG$min_users) {
    return(NULL)
  }
  k <- min(rank, nrow(M), ncol(M))
  decomp <- svd(M, nu = k, nv = k)
  sigma_k <- decomp$d[seq_len(k)]
  user_emb <- decomp$u %*% diag(sigma_k, k, k)        # n_users × k
  item_emb <- decomp$v %*% diag(sigma_k, k, k)        # n_items × k
  rownames(user_emb) <- mat_struct$users
  rownames(item_emb) <- mat_struct$items
  list(
    item_embeddings = item_emb,
    user_embeddings = user_emb,
    items = mat_struct$items,
    users = mat_struct$users,
    rank  = k
  )
}

#' Recommend top-k items for a given list of seed items
#'
#' @param state CF state (output of fit_cf_svd).
#' @param seed_items Character vector of items the user has already selected.
#' @param k Integer. Number of recommendations to return.
#' @param exclude_seeds Logical. If TRUE (default), exclude seed items from recommendations.
#' @return data.frame with columns: item, score. Ordered by score desc.
#' @export
recommend_cf_items <- function(state, seed_items, k = 10L, exclude_seeds = TRUE) {
  if (is.null(state) || length(seed_items) == 0L) {
    return(data.frame(item = character(0), score = numeric(0)))
  }
  seed <- intersect(as.character(seed_items), state$items)
  if (length(seed) == 0L) {
    return(data.frame(item = character(0), score = numeric(0)))
  }
  # Average seed embeddings
  seed_emb <- state$item_embeddings[seed, , drop = FALSE]
  q <- colMeans(seed_emb)
  q_norm <- sqrt(sum(q^2))
  if (q_norm == 0) {
    # Query vector is zero — there's nothing meaningful to recommend
    # against (e.g., all seed items have zero embeddings, which
    # shouldn't happen with a real SVD factorization but can occur on
    # degenerate inputs).
    return(data.frame(item = character(0), score = numeric(0)))
  }
  # Cosine score against all items. Items with zero-norm embeddings
  # would produce 0/0 = NaN cosines; we mask them out rather than
  # short-circuiting the whole call (P2 fix — previously a single
  # zero-norm item killed the entire recommender).
  norms <- sqrt(rowSums(state$item_embeddings^2))
  zero_norm <- norms == 0
  if (any(zero_norm)) {
    norms[zero_norm] <- 1  # avoid divide-by-zero
  }
  cos_sim <- (state$item_embeddings %*% q) / (norms * q_norm)
  scores <- as.numeric(cos_sim)
  scores[zero_norm] <- -Inf  # zero-norm items can never be top
  names(scores) <- state$items
  if (exclude_seeds) scores[seed] <- -Inf
  ord <- order(scores, decreasing = TRUE)
  top <- head(ord, k)
  data.frame(
    item  = state$items[top],
    score = scores[top],
    stringsAsFactors = FALSE
  )
}

#' Persist + load helpers
#'
#' @export
save_cf_state <- function(state, path = CF_CONFIG$store_path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(state, path)
  invisible(path)
}

#' Load CF state. Returns NULL if not yet trained; warns if file is
#' present but malformed so the user sees that persisted data was lost.
#'
#' @export
load_cf_state <- function(path = CF_CONFIG$store_path) {
  if (!file.exists(path)) return(NULL)
  s <- tryCatch(readRDS(path),
                error = function(e) { warning(sprintf(
                  "CF state file %s could not be read: %s.",
                  path, conditionMessage(e))); NULL })
  if (!is.null(s) && !is.null(s$item_embeddings)) return(s)
  warning(sprintf(
    "CF state file %s exists but is malformed (missing $item_embeddings). Returning NULL.",
    path))
  NULL
}

debug_log("Collaborative filter module loaded", "ML_CF")
