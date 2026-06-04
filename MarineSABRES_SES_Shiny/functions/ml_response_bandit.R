# ==============================================================================
# Contextual Bandit for Response-Measure Prioritization
# ==============================================================================
#
# LinUCB (Li, Chu, Langford, Schapire 2010) contextual bandit. Given a
# context vector describing the user's current SES state and a candidate
# response measure, picks a "priority arm" (high / medium / low) and
# updates its parameters when the user accepts or rejects that priority.
#
# Why LinUCB and not "real" reinforcement learning:
#   - This is a one-shot decision per (context, response) pair, not a
#     sequential MDP with state transitions and credit assignment.
#   - LinUCB is the canonical algorithm for this setting and has
#     well-understood regret bounds.
#   - Pure RL formulations on small data overfit catastrophically; LinUCB
#     uses ridge regression + uncertainty bound which is more stable.
#
# Arm definition:
#   "priority arm" ∈ {high, medium, low}
#
# Context features (d=32 dims):
#   - DAPSIWRM type of the candidate's target one-hot (7 dims)
#   - Effectiveness one-hot, locale-stable (3 dims)
#   - Feasibility one-hot, locale-stable (3 dims)
#   - Stakeholder-engagement level (1 dim continuous, 0-1)
#   - Current SES size: n_elements/100 (1 dim continuous, capped)
#   - Current SES connectivity: n_connections/n_elements (1 dim)
#   - Regional one-hot (4 dims: Baltic, Atlantic, Mediterranean, other)
#   - Issue one-hot (8 dims: fisheries, pollution, climate, MPA,
#                            tourism, eutrophication, biodiversity, other)
#   - Bias term (1 dim, always 1.0)
# ==============================================================================

if (!requireNamespace("MASS", quietly = TRUE)) {
  warning("Package 'MASS' is recommended for matrix inversion. Falling back to base::solve.")
}

BANDIT_CONFIG <- list(
  context_dim = 32L,
  arms = c("high", "medium", "low"),
  alpha = 1.0,                # exploration parameter
  store_path = "data/ml_response_bandit_state.rds"
)

#' Initialize a fresh LinUCB bandit state
#'
#' @param context_dim Integer. Context feature vector dimensionality.
#' @param arms Character vector of arm names.
#' @return list of {A, b, alpha, n_updates_per_arm}
#' @export
init_response_bandit <- function(context_dim = BANDIT_CONFIG$context_dim,
                                  arms = BANDIT_CONFIG$arms,
                                  alpha = BANDIT_CONFIG$alpha) {
  state <- list(
    arms = arms,
    context_dim = as.integer(context_dim),
    alpha = alpha,
    # Per-arm ridge-regression state
    A = lapply(arms, function(a) diag(context_dim)),       # d × d
    b = lapply(arms, function(a) rep(0, context_dim)),     # d × 1
    n_updates = setNames(rep(0L, length(arms)), arms),
    created_at = as.character(Sys.time())
  )
  names(state$A) <- arms
  names(state$b) <- arms
  state
}

#' Predict priority arm for a context
#'
#' @param state Bandit state (from init_response_bandit or load_response_bandit).
#' @param context Numeric vector of length state$context_dim.
#' @return list(arm, ucb_per_arm, expected_per_arm)
#' @export
predict_response_priority <- function(state, context) {
  stopifnot(length(context) == state$context_dim)
  x <- as.numeric(context)
  ucb_scores <- vapply(state$arms, function(a) {
    A_inv <- tryCatch(solve(state$A[[a]]), error = function(e) MASS::ginv(state$A[[a]]))
    theta <- A_inv %*% state$b[[a]]
    expected <- as.numeric(t(x) %*% theta)
    uncertainty <- state$alpha * sqrt(as.numeric(t(x) %*% A_inv %*% x))
    expected + uncertainty
  }, numeric(1))
  expected_only <- vapply(state$arms, function(a) {
    A_inv <- tryCatch(solve(state$A[[a]]), error = function(e) MASS::ginv(state$A[[a]]))
    theta <- A_inv %*% state$b[[a]]
    as.numeric(t(x) %*% theta)
  }, numeric(1))
  best <- state$arms[which.max(ucb_scores)]
  list(
    arm = best,
    ucb_per_arm = setNames(ucb_scores, state$arms),
    expected_per_arm = setNames(expected_only, state$arms)
  )
}

#' Update bandit state with observed reward
#'
#' @param state Bandit state.
#' @param arm Character. Which arm was pulled.
#' @param context Numeric vector. Context at decision time.
#' @param reward Numeric. Observed reward, typically 0 or 1.
#' @return Updated bandit state.
#' @export
update_response_bandit <- function(state, arm, context, reward) {
  stopifnot(arm %in% state$arms)
  stopifnot(length(context) == state$context_dim)
  x <- as.numeric(context)
  state$A[[arm]] <- state$A[[arm]] + outer(x, x)
  state$b[[arm]] <- state$b[[arm]] + reward * x
  state$n_updates[[arm]] <- state$n_updates[[arm]] + 1L
  state
}

#' Build the 32-dim context vector for a response candidate
#'
#' @param target_type Character. DAPSIWRM category of the response's target.
#' @param effectiveness Character or numeric. "high"/"medium"/"low" or 1/2/3.
#' @param feasibility Character or numeric. "high"/"medium"/"low" or 1/2/3.
#' @param stakeholder_engagement Numeric, 0-1.
#' @param n_elements Integer. Current SES element count.
#' @param n_connections Integer. Current SES connection count.
#' @param regional_sea Character. One of Baltic / Atlantic / Mediterranean / other.
#' @param main_issue Character. One of fisheries / pollution / climate / MPA / tourism / eutrophication / biodiversity / other.
#' @return Numeric vector of length 32.
#' @export
build_response_context <- function(target_type = "Responses",
                                    effectiveness = "medium",
                                    feasibility = "medium",
                                    stakeholder_engagement = 0.5,
                                    n_elements = 0L,
                                    n_connections = 0L,
                                    regional_sea = "other",
                                    main_issue = "other") {
  v <- numeric(32)

  # Target type one-hot (7) — uses DAPSIWRM_ELEMENTS ordering if available
  dapsi_levels <- if (exists("DAPSIWRM_ELEMENTS")) DAPSIWRM_ELEMENTS else c(
    "Drivers", "Activities", "Pressures",
    "Marine Processes & Functioning", "Ecosystem Services",
    "Goods & Benefits", "Responses"
  )
  idx <- match(target_type, dapsi_levels)
  if (!is.na(idx) && idx <= 7L) v[idx] <- 1

  # Effectiveness one-hot (3) at positions 8-10
  eff_levels <- c("high", "medium", "low")
  if (is.numeric(effectiveness)) {
    eff_idx <- max(1L, min(3L, as.integer(effectiveness)))
  } else {
    eff_idx <- match(tolower(as.character(effectiveness)), eff_levels)
    if (is.na(eff_idx)) eff_idx <- 2L
  }
  v[7L + eff_idx] <- 1

  # Feasibility one-hot (3) at positions 11-13
  feas_levels <- c("high", "medium", "low")
  if (is.numeric(feasibility)) {
    feas_idx <- max(1L, min(3L, as.integer(feasibility)))
  } else {
    feas_idx <- match(tolower(as.character(feasibility)), feas_levels)
    if (is.na(feas_idx)) feas_idx <- 2L
  }
  v[10L + feas_idx] <- 1

  # Stakeholder engagement (pos 14)
  v[14L] <- max(0, min(1, as.numeric(stakeholder_engagement)))

  # SES size (pos 15)
  v[15L] <- min(1, n_elements / 100)

  # Connectivity (pos 16)
  v[16L] <- if (n_elements > 0L) min(2, n_connections / n_elements) / 2 else 0

  # Regional one-hot (4) at 17-20
  reg_levels <- c("baltic", "atlantic", "mediterranean", "other")
  reg <- tolower(as.character(regional_sea))
  reg_match <- reg_levels[sapply(reg_levels, function(r) grepl(r, reg, fixed = TRUE))]
  reg_idx <- if (length(reg_match) >= 1) match(reg_match[1], reg_levels) else 4L
  v[16L + reg_idx] <- 1

  # Issue one-hot (8) at 21-28
  issue_levels <- c("fisheries", "pollution", "climate", "mpa",
                    "tourism", "eutrophication", "biodiversity", "other")
  iss <- tolower(as.character(main_issue))
  iss_match <- issue_levels[sapply(issue_levels, function(r) grepl(r, iss, fixed = TRUE))]
  iss_idx <- if (length(iss_match) >= 1) match(iss_match[1], issue_levels) else 8L
  v[20L + iss_idx] <- 1

  # Pad positions 29-31 with derived features
  v[29L] <- v[8L] * v[11L]   # high effectiveness × high feasibility interaction
  v[30L] <- v[9L] * v[12L]   # medium × medium
  v[31L] <- 1 - v[14L]       # 1 minus stakeholder engagement

  # Bias term
  v[32L] <- 1

  v
}

#' Persist bandit state to disk
#'
#' @param state Bandit state.
#' @param path Character file path (default BANDIT_CONFIG$store_path).
#' @return path (invisibly).
#' @export
save_response_bandit <- function(state, path = BANDIT_CONFIG$store_path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(state, path)
  invisible(path)
}

#' Load bandit state from disk; initialize a fresh one if not found.
#'
#' Three outcomes:
#'   - file doesn't exist: silently return a fresh init (normal cold start).
#'   - file exists and is valid: return the deserialized state.
#'   - file exists but is malformed: warn() loudly, then return a fresh init
#'     so the app keeps running, but the user / log gets a clear signal that
#'     the persisted learning was lost rather than silently reset.
#'
#' @param path Character file path.
#' @return Bandit state.
#' @export
load_response_bandit <- function(path = BANDIT_CONFIG$store_path) {
  if (!file.exists(path)) return(init_response_bandit())
  state <- safe_readRDS(path)
  if (is.null(state)) return(init_response_bandit())
  if (!is.null(state) && is.list(state) &&
      !is.null(state$arms) && !is.null(state$A)) {
    return(state)
  }
  warning(sprintf(
    "Bandit state file %s exists but is malformed (missing $arms or $A). Returning fresh init.",
    path))
  init_response_bandit()
}

debug_log("Response bandit module loaded", "ML_BANDIT")
