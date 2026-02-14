# ==============================================================================
# ML Ensemble Module (Week 5)
# ==============================================================================
# Manages ensemble of models for improved predictions and disagreement-based
# active learning.
#
# Key features:
# - Load and manage multiple trained models
# - Ensemble predictions (averaging/voting)
# - Disagreement-based uncertainty quantification
# - Active learning sample selection
#
# Author: Phase 2 ML Enhancement
# Date: 2025-12-31
# ==============================================================================

if (!requireNamespace("torch", quietly = TRUE)) {
  stop("Package 'torch' is required for ML features. Install with: install.packages('torch')")
}

# ==============================================================================
# Ensemble Manager
# ==============================================================================

#' Ensemble Model Manager
#'
#' Environment to store and manage ensemble of models
#'
#' @export
ensemble_env <- new.env(parent = emptyenv())
ensemble_env$models <- list()
ensemble_env$loaded <- FALSE
ensemble_env$n_models <- 0
ensemble_env$metadata <- NULL

#' Load Ensemble Models
#'
#' Loads multiple trained models from ensemble directory
#'
#' @param ensemble_dir Character. Path to ensemble directory (default: "models/ensemble")
#' @param metadata_file Character. Name of metadata file (default: "ensemble_metadata.rds")
#' @return Logical. TRUE if successful
#' @export
load_ensemble <- function(ensemble_dir = "models/ensemble",
                         metadata_file = "ensemble_metadata.rds") {

  # Load metadata
  metadata_path <- file.path(ensemble_dir, metadata_file)
  if (!file.exists(metadata_path)) {
    warning(sprintf("Ensemble metadata not found: %s", metadata_path))
    return(FALSE)
  }

  ensemble_env$metadata <- readRDS(metadata_path)
  n_models <- ensemble_env$metadata$n_models

  # Load all models
  ensemble_env$models <- list()

  for (i in 1:n_models) {
    model_path <- ensemble_env$metadata$model_paths[i]

    if (!file.exists(model_path)) {
      warning(sprintf("Model %d not found: %s", i, model_path))
      next
    }

    tryCatch({
      model <- torch_load(model_path)
      model$eval()  # Set to evaluation mode
      ensemble_env$models[[i]] <- model
      debug_log(sprintf("Loaded ensemble model %d (seed=%d)",
                  i, ensemble_env$metadata$seeds[i]), "ML_ENSEMBLE")
    }, error = function(e) {
      warning(sprintf("Failed to load model %d: %s", i, e$message))
    })
  }

  ensemble_env$n_models <- length(ensemble_env$models)
  ensemble_env$loaded <- TRUE

  debug_log(sprintf("Ensemble loaded successfully: %d models", ensemble_env$n_models), "ML_ENSEMBLE")
  return(TRUE)
}

#' Check if Ensemble is Available
#'
#' @return Logical. TRUE if ensemble is loaded
#' @export
ensemble_available <- function() {
  return(ensemble_env$loaded && ensemble_env$n_models > 0)
}

#' Unload Ensemble
#'
#' @export
unload_ensemble <- function() {
  ensemble_env$models <- list()
  ensemble_env$loaded <- FALSE
  ensemble_env$n_models <- 0
  gc()
  debug_log("Ensemble unloaded from memory", "ML_ENSEMBLE")
}

# ==============================================================================
# Ensemble Predictions
# ==============================================================================

#' Predict with Ensemble
#'
#' Makes predictions using all ensemble models and aggregates results
#'
#' @param elem_features torch_tensor. Element features (batch, 270)
#' @param context_data List. Context indices (sea_idx, eco_idx, issue_idx)
#' @param graph_features torch_tensor. Graph features (batch, 8)
#' @param aggregation Character. "mean" or "vote" (default: "mean")
#' @return List with aggregated predictions and individual model predictions
#' @export
predict_ensemble <- function(elem_features, context_data, graph_features,
                             aggregation = "mean") {

  if (!ensemble_available()) {
    stop("Ensemble not loaded. Call load_ensemble() first.")
  }

  n_models <- ensemble_env$n_models
  batch_size <- elem_features$size(1)

  # Storage for individual predictions
  all_existence_logits <- list()
  all_strength_logits <- list()
  all_confidence_preds <- list()
  all_polarity_logits <- list()

  # Get predictions from each model
  with_no_grad({
    for (i in 1:n_models) {
      model <- ensemble_env$models[[i]]
      preds <- model(elem_features, context_data, graph_features)

      all_existence_logits[[i]] <- preds$existence
      all_strength_logits[[i]] <- preds$strength
      all_confidence_preds[[i]] <- preds$confidence
      all_polarity_logits[[i]] <- preds$polarity
    }
  })

  # Aggregate predictions
  if (aggregation == "mean") {
    # Average logits across models
    existence_logits <- torch_mean(torch_stack(all_existence_logits, dim = 1), dim = 1)
    strength_logits <- torch_mean(torch_stack(all_strength_logits, dim = 1), dim = 1)
    confidence_preds <- torch_mean(torch_stack(all_confidence_preds, dim = 1), dim = 1)
    polarity_logits <- torch_mean(torch_stack(all_polarity_logits, dim = 1), dim = 1)

  } else if (aggregation == "vote") {
    # Majority voting for existence and polarity
    existence_probs <- lapply(all_existence_logits, torch_sigmoid)
    existence_votes <- lapply(existence_probs, function(p) (p > 0.5)$to(dtype = torch_float()))
    existence_logits <- torch_mean(torch_stack(existence_votes, dim = 1), dim = 1)

    # For strength: take mode of argmax
    strength_classes <- lapply(all_strength_logits, function(s) s$argmax(dim = 2))
    # Convert to logits (simplified: use mean of logits)
    strength_logits <- torch_mean(torch_stack(all_strength_logits, dim = 1), dim = 1)

    # Polarity voting
    polarity_probs <- lapply(all_polarity_logits, torch_sigmoid)
    polarity_votes <- lapply(polarity_probs, function(p) (p > 0.5)$to(dtype = torch_float()))
    polarity_logits <- torch_mean(torch_stack(polarity_votes, dim = 1), dim = 1)

    # Confidence: mean
    confidence_preds <- torch_mean(torch_stack(all_confidence_preds, dim = 1), dim = 1)
  }

  # Return aggregated predictions and individuals for disagreement calculation
  return(list(
    aggregated = list(
      existence = existence_logits,
      strength = strength_logits,
      confidence = confidence_preds,
      polarity = polarity_logits
    ),
    individual = list(
      existence = all_existence_logits,
      strength = all_strength_logits,
      confidence = all_confidence_preds,
      polarity = all_polarity_logits
    )
  ))
}

# ==============================================================================
# Disagreement-Based Uncertainty
# ==============================================================================

#' Calculate Disagreement Uncertainty
#'
#' Measures uncertainty based on disagreement among ensemble models.
#' High disagreement = high uncertainty.
#'
#' @param individual_predictions List. Individual predictions from each model
#' @param task Character. Which task to measure ("existence", "strength", "confidence", "polarity")
#' @return torch_tensor. Disagreement score per sample (batch,)
#' @export
calculate_disagreement <- function(individual_predictions, task = "existence") {

  predictions <- individual_predictions[[task]]
  n_models <- length(predictions)

  if (task == "existence" || task == "polarity") {
    # Binary: calculate variance of probabilities
    probs_list <- lapply(predictions, torch_sigmoid)
    # Stack creates new dimension: [(batch,1), (batch,1), ...] -> (batch, n_models, 1) when dim=2
    probs_stack <- torch_stack(probs_list, dim = 2)  # (batch, n_models, 1)

    # Variance across models (dim 2), then squeeze last dim
    disagreement <- torch_var(probs_stack, dim = 2)$squeeze(-1)

  } else if (task == "strength") {
    # Multi-class: calculate prediction entropy across models
    # Convert logits to class predictions
    class_preds <- lapply(predictions, function(p) p$argmax(dim = 2))
    # Stack: [(batch,), (batch,), ...] -> (batch, n_models) when dim=2
    class_stack <- torch_stack(class_preds, dim = 2)  # (batch, n_models)

    # Calculate disagreement as proportion of non-modal predictions
    # For each sample, find mode and count disagreements
    batch_size <- class_stack$size(1)
    disagreement_scores <- numeric(batch_size)

    for (i in 1:batch_size) {
      sample_votes <- as.integer(class_stack[i, ])
      vote_counts <- table(sample_votes)
      max_votes <- max(vote_counts)
      disagreement_scores[i] <- 1 - (max_votes / n_models)
    }

    # Create tensor with shape (batch,)
    disagreement <- torch_tensor(disagreement_scores, dtype = torch_float())

  } else if (task == "confidence") {
    # Regression: calculate standard deviation
    # Stack: [(batch,1), (batch,1), ...] -> (batch, n_models, 1) when dim=2
    preds_stack <- torch_stack(predictions, dim = 2)  # (batch, n_models, 1)
    # Std across models (dim 2), then squeeze last dim
    disagreement <- torch_std(preds_stack, dim = 2)$squeeze(-1)
  }

  return(disagreement)
}

#' Calculate Overall Ensemble Disagreement
#'
#' Combines disagreement across all tasks into single uncertainty score
#'
#' @param individual_predictions List. Individual predictions from ensemble
#' @param task_weights List. Weights for each task (default: existence=0.5, others=0.16)
#' @return List with overall disagreement and task-specific disagreements
#' @export
calculate_ensemble_disagreement <- function(individual_predictions,
                                           task_weights = list(
                                             existence = 0.5,
                                             strength = 0.2,
                                             confidence = 0.15,
                                             polarity = 0.15
                                           )) {

  # Calculate disagreement for each task (all return 1D tensors of shape (batch,))
  existence_dis <- calculate_disagreement(individual_predictions, "existence")
  strength_dis <- calculate_disagreement(individual_predictions, "strength")
  confidence_dis <- calculate_disagreement(individual_predictions, "confidence")
  polarity_dis <- calculate_disagreement(individual_predictions, "polarity")

  # Normalize disagreements to [0, 1]
  # Existence/polarity variance is already [0, 0.25], normalize to [0, 1]
  existence_dis_norm <- torch_clamp(existence_dis * 4.0, min = 0, max = 1)
  polarity_dis_norm <- torch_clamp(polarity_dis * 4.0, min = 0, max = 1)

  # Strength disagreement already [0, 1]
  strength_dis_norm <- strength_dis

  # Confidence std needs normalization (assume max std ~ 2.0 for 1-5 scale)
  confidence_dis_norm <- torch_clamp(confidence_dis / 2.0, min = 0, max = 1)

  # Weighted combination
  overall_disagreement <- (
    task_weights$existence * existence_dis_norm +
    task_weights$strength * strength_dis_norm +
    task_weights$confidence * confidence_dis_norm +
    task_weights$polarity * polarity_dis_norm
  )

  return(list(
    overall = overall_disagreement,
    existence = existence_dis_norm,
    strength = strength_dis_norm,
    confidence = confidence_dis_norm,
    polarity = polarity_dis_norm
  ))
}

# ==============================================================================
# Disagreement Sampling
# ==============================================================================

#' Disagreement-Based Sample Selection
#'
#' Selects samples where ensemble models disagree the most
#'
#' @param disagreement_scores torch_tensor or numeric. Disagreement scores
#' @param n_samples Integer. Number of samples to select
#' @param threshold Numeric. Optional minimum disagreement threshold
#' @return Integer vector of selected indices
#' @export
disagreement_sampling <- function(disagreement_scores, n_samples = 10, threshold = NULL) {

  # Convert to numeric if tensor
  if (inherits(disagreement_scores, "torch_tensor")) {
    scores <- as.numeric(disagreement_scores)
  } else {
    scores <- as.numeric(disagreement_scores)
  }

  # Filter by threshold if specified
  if (!is.null(threshold)) {
    candidates <- which(scores >= threshold)
    if (length(candidates) == 0) {
      message("No samples above disagreement threshold")
      return(integer(0))
    }
    scores <- scores[candidates]
    n_samples <- min(n_samples, length(candidates))
  } else {
    candidates <- 1:length(scores)
  }

  # Select top-n by disagreement
  n_samples <- min(n_samples, length(scores))
  selected_in_candidates <- order(scores, decreasing = TRUE)[1:n_samples]

  return(candidates[selected_in_candidates])
}

# ==============================================================================
# Ensemble Prediction API
# ==============================================================================

#' Predict Connection with Ensemble
#'
#' High-level API for ensemble predictions with uncertainty
#'
#' @param source_name Character. Source element name
#' @param target_name Character. Target element name
#' @param source_type Character. Source DAPSI(W)R(M) type
#' @param target_type Character. Target DAPSI(W)R(M) type
#' @param context List. Context information
#' @param threshold Numeric. Probability threshold (default: 0.5)
#' @param return_disagreement Logical. Include disagreement scores (default: TRUE)
#' @return List with ensemble predictions
#' @export
predict_connection_ensemble <- function(source_name, target_name,
                                       source_type, target_type,
                                       context = list(),
                                       threshold = 0.5,
                                       return_disagreement = TRUE) {

  if (!ensemble_available()) {
    stop("Ensemble not loaded. Call load_ensemble() first.")
  }

  # Prepare features (same as single model)
  # This requires ml_feature_engineering functions
  if (!exists("create_element_embedding")) {
    stop("ML feature engineering functions not loaded")
  }

  regional_sea <- context$regional_sea %||% "Other"
  ecosystem_types <- context$ecosystem_types %||% "Other"
  main_issues <- context$main_issues %||% "Other"

  # Element features
  source_emb <- create_element_embedding(source_name, 128)
  target_emb <- create_element_embedding(target_name, 128)
  source_type_enc <- encode_dapsiwrm_type(source_type)
  target_type_enc <- encode_dapsiwrm_type(target_type)

  elem_features <- torch_tensor(
    matrix(c(source_emb, target_emb, source_type_enc, target_type_enc), nrow = 1),
    dtype = torch_float()
  )

  # Context indices
  ctx_indices <- prepare_context_indices(regional_sea, ecosystem_types, main_issues)
  context_data <- list(
    sea_idx = torch_tensor(as.numeric(ctx_indices$sea_idx)[1], dtype = torch_long())$view(c(1)),
    eco_idx = torch_tensor(as.numeric(ctx_indices$eco_idx)[1], dtype = torch_long())$view(c(1)),
    issue_idx = torch_tensor(as.numeric(ctx_indices$issue_idx)[1], dtype = torch_long())$view(c(1))
  )

  # Graph features (zero-padded for now)
  graph_features <- torch_zeros(c(1, 8))

  # Ensemble prediction
  ensemble_preds <- predict_ensemble(elem_features, context_data, graph_features)

  # Process aggregated predictions
  agg <- ensemble_preds$aggregated

  # Existence
  existence_prob <- as.numeric(torch_sigmoid(agg$existence))
  connection_exists <- existence_prob >= threshold

  # Strength
  strength_probs <- as.numeric(nnf_softmax(agg$strength, dim = 2))
  strength_class <- which.max(strength_probs)
  strength <- c("weak", "medium", "strong")[strength_class]

  # Confidence
  confidence <- max(1, min(5, round(as.numeric(agg$confidence))))

  # Polarity
  polarity_prob <- as.numeric(torch_sigmoid(agg$polarity))
  polarity <- if (polarity_prob >= 0.5) "+" else "-"

  # Build result
  result <- list(
    connection_exists = connection_exists,
    existence_probability = existence_prob,
    strength = strength,
    confidence = confidence,
    polarity = polarity,
    source = list(name = source_name, type = source_type),
    target = list(name = target_name, type = target_type),
    method = "ensemble",
    n_models = ensemble_env$n_models
  )

  # Add disagreement if requested
  if (return_disagreement) {
    disagreement_info <- calculate_ensemble_disagreement(ensemble_preds$individual)

    result$disagreement <- list(
      overall_score = as.numeric(disagreement_info$overall),
      confidence_category = categorize_uncertainty(as.numeric(disagreement_info$overall))[[1]],
      task_disagreements = list(
        existence = as.numeric(disagreement_info$existence),
        strength = as.numeric(disagreement_info$strength),
        confidence = as.numeric(disagreement_info$confidence),
        polarity = as.numeric(disagreement_info$polarity)
      )
    )
  }

  return(result)
}

# ==============================================================================
# Startup Message
# ==============================================================================

debug_log("ML Ensemble module loaded", "ML_ENSEMBLE")
debug_log("Ensemble manager: load/unload multiple models", "ML_ENSEMBLE")
debug_log("Ensemble predictions: averaging/voting aggregation", "ML_ENSEMBLE")
debug_log("Disagreement uncertainty: variance-based uncertainty", "ML_ENSEMBLE")
debug_log("Disagreement sampling: select high-disagreement samples", "ML_ENSEMBLE")
debug_log("API: predict_connection_ensemble() for easy inference", "ML_ENSEMBLE")
