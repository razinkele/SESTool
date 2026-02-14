# ==============================================================================
# Active Learning & Uncertainty Quantification Module
# ==============================================================================
# Week 4 of Phase 2 ML Enhancements
#
# Functions for uncertainty quantification and active learning:
# - Temperature scaling for probability calibration
# - Uncertainty metrics (entropy, margin, variance)
# - Uncertainty sampling for smart feedback collection
# - Active learning sample selection
#
# Author: Phase 2 ML Enhancement
# Date: 2025-12-31
# ==============================================================================

if (!requireNamespace("torch", quietly = TRUE)) {
  stop("Package 'torch' is required for ML features. Install with: install.packages('torch')")
}

# ==============================================================================
# Temperature Scaling for Calibration
# ==============================================================================

#' Temperature Scaling Module
#'
#' Calibrates model predictions using temperature scaling.
#' Temperature scaling is a post-hoc calibration method that rescales
#' the logits by a learned temperature parameter.
#'
#' @param temperature Numeric. Temperature parameter (default: 1.0, no scaling)
#' @return torch nn_module
#' @export
temperature_scaler <- nn_module(
  "TemperatureScaler",

  initialize = function(temperature = 1.0) {
    # Temperature parameter (learnable)
    self$temperature <- nn_parameter(torch_tensor(temperature, dtype = torch_float()))
  },

  forward = function(logits) {
    # Scale logits by temperature
    # Lower temperature -> sharper probabilities
    # Higher temperature -> softer probabilities
    return(logits / self$temperature)
  }
)

#' Fit Temperature Scaling
#'
#' Learns optimal temperature parameter using validation set.
#' Minimizes negative log-likelihood on validation predictions.
#'
#' @param logits torch_tensor. Model logits on validation set (N x C)
#' @param targets torch_tensor. Ground truth labels (N)
#' @param lr Numeric. Learning rate (default: 0.01)
#' @param max_iter Integer. Maximum optimization iterations (default: 100)
#' @return Fitted temperature_scaler module
#' @export
fit_temperature_scaling <- function(logits, targets, lr = 0.01, max_iter = 100) {
  # Initialize temperature scaler
  scaler <- temperature_scaler(temperature = 1.5)

  # Optimizer
  optimizer <- optim_lbfgs(scaler$parameters, lr = lr, max_iter = max_iter)

  # Loss function (negative log-likelihood)
  loss_fn <- function() {
    scaled_logits <- scaler(logits)
    loss <- nnf_cross_entropy(scaled_logits, targets)
    optimizer$zero_grad()
    loss$backward()
    return(loss)
  }

  # Optimize temperature
  optimizer$step(loss_fn)

  return(scaler)
}

# ==============================================================================
# Uncertainty Metrics
# ==============================================================================

#' Calculate Predictive Entropy
#'
#' Measures uncertainty as the entropy of the predicted probability distribution.
#' Higher entropy indicates more uncertainty.
#'
#' @param probs torch_tensor. Predicted probabilities (N x C) or (N x 1) for binary
#' @return torch_tensor. Entropy for each prediction (N)
#' @export
calculate_entropy <- function(probs) {
  # For binary classification (N x 1), convert to (N x 2)
  if (length(dim(probs)) == 2 && dim(probs)[2] == 1) {
    probs <- torch_cat(list(1 - probs, probs), dim = 2)
  }

  # Avoid log(0) by adding small epsilon
  eps <- 1e-10
  probs <- torch_clamp(probs, min = eps, max = 1 - eps)

  # Entropy: -sum(p * log(p))
  entropy <- -torch_sum(probs * torch_log(probs), dim = 2)

  return(entropy)
}

#' Calculate Prediction Margin
#'
#' Measures uncertainty as the difference between top-2 predicted probabilities.
#' Lower margin indicates more uncertainty (model is unsure between two classes).
#'
#' @param probs torch_tensor. Predicted probabilities (N x C)
#' @return torch_tensor. Margin for each prediction (N)
#' @export
calculate_margin <- function(probs) {
  # For binary classification, margin is |p - 0.5| * 2
  if (length(dim(probs)) == 2 && dim(probs)[2] == 1) {
    margin <- torch_abs(probs - 0.5) * 2
    return(margin$squeeze())
  }

  # For multi-class, margin is difference between top-2 probabilities
  sorted_probs <- torch_sort(probs, dim = 2, descending = TRUE)
  top1 <- sorted_probs[[1]][, 1]
  top2 <- sorted_probs[[1]][, 2]
  margin <- top1 - top2

  return(margin)
}

#' Calculate Maximum Probability
#'
#' Simple uncertainty measure: 1 - max(p).
#' Higher value indicates more uncertainty.
#'
#' @param probs torch_tensor. Predicted probabilities (N x C) or (N x 1)
#' @return torch_tensor. Uncertainty score (N)
#' @export
calculate_max_prob_uncertainty <- function(probs) {
  if (length(dim(probs)) == 2 && dim(probs)[2] == 1) {
    # Binary: max(p, 1-p)
    max_prob <- torch_max(torch_cat(list(probs, 1 - probs), dim = 2), dim = 2)[[1]]
  } else {
    # Multi-class
    max_prob <- torch_max(probs, dim = 2)[[1]]
  }

  # Uncertainty = 1 - confidence
  uncertainty <- 1 - max_prob

  return(uncertainty)
}

#' Calculate Combined Uncertainty Score
#'
#' Combines multiple uncertainty metrics into a single score.
#'
#' @param probs torch_tensor. Predicted probabilities
#' @param weights List. Weights for entropy, margin, max_prob (default: equal)
#' @return torch_tensor. Combined uncertainty score (N)
#' @export
calculate_uncertainty_score <- function(probs,
                                       weights = list(entropy = 0.4, margin = 0.3, max_prob = 0.3)) {
  # Normalize probabilities
  if (length(dim(probs)) == 1) {
    probs <- probs$unsqueeze(2)
  }

  # Calculate individual metrics
  entropy <- calculate_entropy(probs)
  margin <- calculate_margin(probs)
  max_prob_unc <- calculate_max_prob_uncertainty(probs)

  # Normalize each metric to [0, 1] range
  entropy_norm <- entropy / torch_log(torch_tensor(2.0))  # Max entropy for binary
  margin_norm <- 1 - margin  # Convert margin to uncertainty (lower margin = higher uncertainty)

  # Combine with weights
  combined <- (
    weights$entropy * entropy_norm +
    weights$margin * margin_norm +
    weights$max_prob * max_prob_unc
  )

  return(combined)
}

# ==============================================================================
# Multi-Task Uncertainty for Connection Predictor
# ==============================================================================

#' Calculate Uncertainty for Connection Predictions
#'
#' Specialized uncertainty calculation for multi-task connection predictor.
#' Combines uncertainty across existence, strength, confidence, and polarity tasks.
#'
#' @param predictions List. Model predictions with existence, strength, confidence, polarity
#' @param task_weights List. Weights for each task (default: existence=0.5, others=0.16)
#' @return List with overall_uncertainty and task_uncertainties
#' @export
calculate_connection_uncertainty <- function(predictions,
                                            task_weights = list(
                                              existence = 0.5,
                                              strength = 0.2,
                                              confidence = 0.15,
                                              polarity = 0.15
                                            )) {

  # === Existence Uncertainty ===
  existence_probs <- torch_sigmoid(predictions$existence)
  existence_unc <- calculate_uncertainty_score(existence_probs)

  # === Strength Uncertainty ===
  strength_probs <- nnf_softmax(predictions$strength, dim = 2)
  strength_unc <- calculate_entropy(strength_probs)
  # Normalize by max entropy (log(3) for 3 classes)
  strength_unc <- strength_unc / torch_log(torch_tensor(3.0))

  # === Confidence Uncertainty ===
  # For regression, use prediction variance or distance from midpoint
  # Confidence is 1-5 scale, midpoint is 3
  confidence_unc <- torch_abs(predictions$confidence - 3.0) / 2.0  # Normalize to [0, 1]
  confidence_unc <- 1 - torch_clamp(confidence_unc, min = 0, max = 1)  # Invert: closer to midpoint = more uncertain
  confidence_unc <- confidence_unc$squeeze()

  # === Polarity Uncertainty ===
  polarity_probs <- torch_sigmoid(predictions$polarity)
  polarity_unc <- calculate_uncertainty_score(polarity_probs)

  # === Combined Uncertainty ===
  overall_uncertainty <- (
    task_weights$existence * existence_unc +
    task_weights$strength * strength_unc +
    task_weights$confidence * confidence_unc +
    task_weights$polarity * polarity_unc
  )

  return(list(
    overall = overall_uncertainty,
    existence = existence_unc,
    strength = strength_unc,
    confidence = confidence_unc,
    polarity = polarity_unc
  ))
}

# ==============================================================================
# Active Learning Sample Selection
# ==============================================================================

#' Uncertainty Sampling
#'
#' Selects samples with highest uncertainty for user review.
#'
#' @param uncertainty_scores torch_tensor or numeric vector. Uncertainty scores
#' @param n_samples Integer. Number of samples to select
#' @param threshold Numeric. Optional threshold (select all above threshold)
#' @return Integer vector of selected indices
#' @export
uncertainty_sampling <- function(uncertainty_scores, n_samples = 10, threshold = NULL) {
  # Convert to numeric if tensor
  if (inherits(uncertainty_scores, "torch_tensor")) {
    scores <- as.numeric(uncertainty_scores)
  } else {
    scores <- as.numeric(uncertainty_scores)
  }

  # If threshold specified, select all above threshold
  if (!is.null(threshold)) {
    selected <- which(scores >= threshold)
    return(selected)
  }

  # Otherwise, select top-n by uncertainty
  n_samples <- min(n_samples, length(scores))
  selected <- order(scores, decreasing = TRUE)[1:n_samples]

  return(selected)
}

#' Random Sampling (Baseline)
#'
#' Randomly selects samples for comparison with uncertainty sampling.
#'
#' @param n_total Integer. Total number of samples
#' @param n_samples Integer. Number of samples to select
#' @return Integer vector of selected indices
#' @export
random_sampling <- function(n_total, n_samples = 10) {
  n_samples <- min(n_samples, n_total)
  selected <- sample(1:n_total, n_samples, replace = FALSE)
  return(selected)
}

#' Stratified Uncertainty Sampling
#'
#' Samples from different uncertainty strata to ensure diversity.
#'
#' @param uncertainty_scores Numeric vector. Uncertainty scores
#' @param n_samples Integer. Number of samples to select
#' @param n_strata Integer. Number of uncertainty strata (default: 3)
#' @return Integer vector of selected indices
#' @export
stratified_uncertainty_sampling <- function(uncertainty_scores,
                                           n_samples = 10,
                                           n_strata = 3) {
  scores <- as.numeric(uncertainty_scores)
  n_total <- length(scores)
  n_samples <- min(n_samples, n_total)

  # Divide into strata by uncertainty percentiles
  percentiles <- quantile(scores, probs = seq(0, 1, length.out = n_strata + 1))

  # Assign each sample to a stratum
  strata <- cut(scores, breaks = percentiles, include.lowest = TRUE, labels = FALSE)

  # Sample proportionally from each stratum
  samples_per_stratum <- rep(floor(n_samples / n_strata), n_strata)
  remainder <- n_samples - sum(samples_per_stratum)
  if (remainder > 0) {
    samples_per_stratum[1:remainder] <- samples_per_stratum[1:remainder] + 1
  }

  # Select samples from each stratum
  selected <- c()
  for (s in 1:n_strata) {
    stratum_indices <- which(strata == s)
    if (length(stratum_indices) > 0) {
      n_select <- min(samples_per_stratum[s], length(stratum_indices))
      if (n_select > 0) {
        # Within stratum, select highest uncertainty
        stratum_scores <- scores[stratum_indices]
        stratum_selected <- order(stratum_scores, decreasing = TRUE)[1:n_select]
        selected <- c(selected, stratum_indices[stratum_selected])
      }
    }
  }

  return(selected)
}

# ==============================================================================
# Uncertainty-Based Filtering
# ==============================================================================

#' Filter High-Confidence Predictions
#'
#' Returns only predictions with uncertainty below threshold (high confidence).
#'
#' @param predictions Data frame or list. Model predictions
#' @param uncertainty_scores Numeric vector. Uncertainty scores
#' @param threshold Numeric. Uncertainty threshold (default: 0.3)
#' @return List with filtered predictions and indices
#' @export
filter_high_confidence <- function(predictions, uncertainty_scores, threshold = 0.3) {
  scores <- as.numeric(uncertainty_scores)
  high_conf_indices <- which(scores < threshold)

  if (is.data.frame(predictions)) {
    filtered <- predictions[high_conf_indices, ]
  } else if (is.list(predictions)) {
    filtered <- lapply(predictions, function(x) {
      if (is.vector(x) || is.matrix(x)) {
        x[high_conf_indices]
      } else {
        x
      }
    })
  }

  return(list(
    predictions = filtered,
    indices = high_conf_indices,
    n_filtered = length(high_conf_indices),
    n_total = length(scores)
  ))
}

#' Categorize Predictions by Uncertainty
#'
#' Categorizes predictions into confidence levels.
#'
#' @param uncertainty_scores Numeric vector. Uncertainty scores
#' @param thresholds List. Thresholds for categories (default: low=0.2, medium=0.5)
#' @return Character vector. Confidence categories: "high", "medium", "low"
#' @export
categorize_uncertainty <- function(uncertainty_scores,
                                  thresholds = list(low = 0.2, medium = 0.5)) {
  scores <- as.numeric(uncertainty_scores)

  categories <- ifelse(scores < thresholds$low, "high_confidence",
                      ifelse(scores < thresholds$medium, "medium_confidence",
                             "low_confidence"))

  return(categories)
}

# ==============================================================================
# Batch Uncertainty Calculation for Inference
# ==============================================================================

#' Calculate Uncertainty for Batch Predictions
#'
#' Wrapper for calculating uncertainty on batch of predictions.
#' Returns both raw scores and categorized confidence levels.
#'
#' @param predictions List. Model predictions (existence, strength, confidence, polarity)
#' @param return_components Logical. Return individual task uncertainties (default: FALSE)
#' @return Data frame with uncertainty scores and categories
#' @export
batch_uncertainty_scores <- function(predictions, return_components = FALSE) {
  # Calculate connection-specific uncertainty
  uncertainty <- calculate_connection_uncertainty(predictions)

  # Convert to numeric vectors
  overall_scores <- as.numeric(uncertainty$overall)

  # Categorize
  categories <- categorize_uncertainty(overall_scores)

  # Create result data frame
  result <- data.frame(
    uncertainty_score = overall_scores,
    confidence_category = categories,
    stringsAsFactors = FALSE
  )

  # Optionally include component scores
  if (return_components) {
    result$existence_uncertainty <- as.numeric(uncertainty$existence)
    result$strength_uncertainty <- as.numeric(uncertainty$strength)
    result$confidence_uncertainty <- as.numeric(uncertainty$confidence)
    result$polarity_uncertainty <- as.numeric(uncertainty$polarity)
  }

  return(result)
}

# ==============================================================================
# Active Learning Recommendation
# ==============================================================================

#' Recommend Samples for User Review
#'
#' Identifies which predictions should be reviewed by the user.
#' Combines uncertainty sampling with diversity considerations.
#'
#' @param predictions Data frame. Predictions with metadata
#' @param uncertainty_scores Numeric vector. Uncertainty scores
#' @param n_recommend Integer. Number of samples to recommend (default: 10)
#' @param method Character. Sampling method: "uncertainty", "stratified", "random"
#' @param min_threshold Numeric. Minimum uncertainty to consider (default: 0.3)
#' @return Data frame with recommended samples sorted by uncertainty
#' @export
recommend_review_samples <- function(predictions,
                                    uncertainty_scores,
                                    n_recommend = 10,
                                    method = "uncertainty",
                                    min_threshold = 0.3) {

  scores <- as.numeric(uncertainty_scores)

  # Filter by minimum threshold
  candidate_indices <- which(scores >= min_threshold)

  if (length(candidate_indices) == 0) {
    message("No samples above uncertainty threshold. All predictions are confident.")
    return(NULL)
  }

  # Apply sampling method
  if (method == "uncertainty") {
    selected_candidates <- uncertainty_sampling(
      scores[candidate_indices],
      n_samples = min(n_recommend, length(candidate_indices))
    )
  } else if (method == "stratified") {
    selected_candidates <- stratified_uncertainty_sampling(
      scores[candidate_indices],
      n_samples = min(n_recommend, length(candidate_indices))
    )
  } else if (method == "random") {
    selected_candidates <- random_sampling(
      length(candidate_indices),
      n_samples = min(n_recommend, length(candidate_indices))
    )
  }

  # Map back to original indices
  selected_indices <- candidate_indices[selected_candidates]

  # Create recommendation data frame
  if (is.data.frame(predictions)) {
    recommended <- predictions[selected_indices, , drop = FALSE]
    recommended$uncertainty_score <- scores[selected_indices]
    recommended$review_priority <- rank(-scores[selected_indices])
  } else {
    recommended <- data.frame(
      index = selected_indices,
      uncertainty_score = scores[selected_indices],
      review_priority = rank(-scores[selected_indices])
    )
  }

  # Sort by uncertainty (highest first)
  recommended <- recommended[order(-recommended$uncertainty_score), , drop = FALSE]

  return(recommended)
}

# ==============================================================================
# Startup Message
# ==============================================================================

debug_log("ML Active Learning module loaded", "ML_ACTIVE")
debug_log("Temperature scaling for calibration", "ML_ACTIVE")
debug_log("Uncertainty metrics: entropy, margin, max_prob", "ML_ACTIVE")
debug_log("Multi-task uncertainty for connection predictor", "ML_ACTIVE")
debug_log("Active learning sampling: uncertainty, stratified, random", "ML_ACTIVE")
debug_log("Recommendation system for user review", "ML_ACTIVE")
