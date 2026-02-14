# ==============================================================================
# ML Inference Wrapper Functions
# ==============================================================================
# Simple API for loading trained models and making connection predictions
#
# Main functions:
# - load_ml_model(): Load trained model into memory
# - predict_connection_ml(): Predict connection between two elements
# - predict_batch_ml(): Batch predictions for multiple element pairs
# - ml_model_available(): Check if ML model is loaded
# ==============================================================================

if (!requireNamespace("torch", quietly = TRUE)) {
  stop("Package 'torch' is required for ML features. Install with: install.packages('torch')")
}
source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")

# ==============================================================================
# Global Model Cache
# ==============================================================================

.ml_env <- new.env(parent = emptyenv())
.ml_env$model <- NULL
.ml_env$model_loaded <- FALSE
.ml_env$model_path <- "models/connection_predictor_best.pt"

# ==============================================================================
# Model Loading Functions
# ==============================================================================

#' Load trained ML model into memory
#'
#' @param model_path Character. Path to saved model file (default: models/connection_predictor_best.pt)
#' @param force_reload Logical. Force reload even if already loaded (default: FALSE)
#' @return Logical. TRUE if successful, FALSE otherwise
#' @export
load_ml_model <- function(model_path = "models/connection_predictor_best.pt", force_reload = FALSE) {
  # Check if already loaded
  if (.ml_env$model_loaded && !force_reload) {
    debug_log("ML model already loaded from cache", "ML_INFERENCE")
    return(TRUE)
  }

  # Check if model file exists
  if (!file.exists(model_path)) {
    warning(sprintf("ML model file not found: %s", model_path))
    .ml_env$model_loaded <- FALSE
    return(FALSE)
  }

  # Load model
  tryCatch({
    .ml_env$model <- torch_load(model_path)
    .ml_env$model$eval()  # Set to evaluation mode
    .ml_env$model_path <- model_path
    .ml_env$model_loaded <- TRUE
    debug_log(sprintf("ML model loaded successfully from %s", model_path), "ML_INFERENCE")
    return(TRUE)
  }, error = function(e) {
    warning(sprintf("Failed to load ML model: %s", e$message))
    .ml_env$model_loaded <- FALSE
    return(FALSE)
  })
}

#' Check if ML model is available
#'
#' @return Logical. TRUE if model is loaded and ready
#' @export
ml_model_available <- function() {
  return(.ml_env$model_loaded && !is.null(.ml_env$model))
}

#' Unload ML model from memory
#'
#' @export
unload_ml_model <- function() {
  .ml_env$model <- NULL
  .ml_env$model_loaded <- FALSE
  gc()  # Trigger garbage collection
  debug_log("ML model unloaded from memory", "ML_INFERENCE")
}

# ==============================================================================
# Prediction Functions
# ==============================================================================

#' Predict connection between two SES elements
#'
#' @param source_name Character. Name of source element
#' @param source_type Character. DAPSI(W)R(M) type of source
#' @param target_name Character. Name of target element
#' @param target_type Character. DAPSI(W)R(M) type of target
#' @param context List. Context information (regional_sea, ecosystem_types, main_issues)
#' @param threshold Numeric. Probability threshold for connection existence (default: 0.5)
#' @param return_uncertainty Logical. Include uncertainty scores (default: TRUE)
#' @return List with prediction results
#' @export
predict_connection_ml <- function(source_name, target_name,
                                   source_type = NULL, target_type = NULL,
                                   context = list(), threshold = 0.5,
                                   return_uncertainty = TRUE) {
  # Check if model is loaded
  if (!ml_model_available()) {
    warning("ML model not loaded. Call load_ml_model() first.")
    return(NULL)
  }

  # Default context values
  regional_sea <- context$regional_sea %||% "Other"
  ecosystem_types <- context$ecosystem_types %||% context$ecosystem_type %||% "Other"
  main_issues <- context$main_issues %||% context$main_issue %||% "Other"

  # Auto-classify types if not provided (fallback to rule-based)
  if (is.null(source_type) && exists("classify_element_with_ai")) {
    source_classification <- classify_element_with_ai(source_name, context)
    source_type <- source_classification$primary$type
  } else if (is.null(source_type)) {
    source_type <- "Activities"  # Default fallback
  }

  if (is.null(target_type) && exists("classify_element_with_ai")) {
    target_classification <- classify_element_with_ai(target_name, context)
    target_type <- target_classification$primary$type
  } else if (is.null(target_type)) {
    target_type <- "Pressures"  # Default fallback
  }

  # Create feature vector
  feature_vector <- create_feature_vector(
    source_name = source_name,
    source_type = source_type,
    target_name = target_name,
    target_type = target_type,
    regional_sea = regional_sea,
    ecosystem_types = ecosystem_types,
    main_issues = main_issues,
    embedding_dim = 128
  )

  # Convert to torch tensor
  x <- torch_tensor(matrix(feature_vector, nrow = 1), dtype = torch_float())

  # Make prediction
  with_no_grad({
    predictions <- .ml_env$model(x)
  })

  # Extract and process predictions
  # 1. Connection existence
  existence_logit <- predictions$existence$item()
  existence_prob <- 1 / (1 + exp(-existence_logit))  # Sigmoid
  connection_exists <- existence_prob >= threshold

  # 2. Strength (only meaningful if connection exists)
  strength_logits <- as.numeric(predictions$strength)
  strength_probs <- exp(strength_logits) / sum(exp(strength_logits))  # Softmax
  strength_class <- which.max(strength_probs)
  strength_labels <- c("weak", "medium", "strong")
  strength <- strength_labels[strength_class]

  # 3. Confidence (1-5 scale)
  confidence_raw <- predictions$confidence$item()
  confidence <- max(1, min(5, round(confidence_raw)))  # Clamp to 1-5

  # 4. Polarity
  polarity_logit <- predictions$polarity$item()
  polarity_prob <- 1 / (1 + exp(-polarity_logit))
  polarity <- if (polarity_prob >= 0.5) "+" else "-"

  # 5. Calculate uncertainty scores if requested
  result <- list(
    connection_exists = connection_exists,
    existence_probability = existence_prob,
    strength = strength,
    strength_probabilities = list(
      weak = strength_probs[1],
      medium = strength_probs[2],
      strong = strength_probs[3]
    ),
    confidence = confidence,
    polarity = polarity,
    source = list(name = source_name, type = source_type),
    target = list(name = target_name, type = target_type),
    method = "ml"
  )

  # Add uncertainty information if available and requested
  if (return_uncertainty && exists("calculate_connection_uncertainty")) {
    uncertainty_info <- calculate_connection_uncertainty(predictions)

    result$uncertainty <- list(
      overall_score = as.numeric(uncertainty_info$overall),
      confidence_category = categorize_uncertainty(as.numeric(uncertainty_info$overall))[[1]],
      task_uncertainties = list(
        existence = as.numeric(uncertainty_info$existence),
        strength = as.numeric(uncertainty_info$strength),
        confidence = as.numeric(uncertainty_info$confidence),
        polarity = as.numeric(uncertainty_info$polarity)
      )
    )
  }

  return(result)
}

#' Predict connections for multiple element pairs (batch)
#'
#' @param pairs Dataframe with columns: source_name, target_name, source_type, target_type
#' @param context List. Context information
#' @param threshold Numeric. Probability threshold
#' @param return_uncertainty Logical. Include uncertainty scores (default: TRUE)
#' @return Dataframe with predictions
#' @export
predict_batch_ml <- function(pairs, context = list(), threshold = 0.5, return_uncertainty = TRUE) {
  if (!ml_model_available()) {
    warning("ML model not loaded. Call load_ml_model() first.")
    return(NULL)
  }

  # Default context
  regional_sea <- context$regional_sea %||% "Other"
  ecosystem_types <- context$ecosystem_types %||% "Other"
  main_issues <- context$main_issues %||% "Other"

  # Create feature matrix for all pairs
  n_pairs <- nrow(pairs)
  feature_matrix <- matrix(0, nrow = n_pairs, ncol = 358)

  for (i in 1:n_pairs) {
    feature_matrix[i, ] <- create_feature_vector(
      source_name = pairs$source_name[i],
      source_type = pairs$source_type[i] %||% "Activities",
      target_name = pairs$target_name[i],
      target_type = pairs$target_type[i] %||% "Pressures",
      regional_sea = regional_sea,
      ecosystem_types = ecosystem_types,
      main_issues = main_issues,
      embedding_dim = 128
    )
  }

  # Convert to torch tensor
  x <- torch_tensor(feature_matrix, dtype = torch_float())

  # Batch prediction
  with_no_grad({
    predictions <- .ml_env$model(x)
  })

  # Process results
  existence_probs <- torch_sigmoid(predictions$existence)$squeeze()$cpu()
  results <- data.frame(
    source_name = pairs$source_name,
    target_name = pairs$target_name,
    existence_probability = as.numeric(existence_probs),
    connection_exists = as.numeric(existence_probs) >= threshold,
    stringsAsFactors = FALSE
  )

  # Add uncertainty scores if requested
  if (return_uncertainty && exists("batch_uncertainty_scores")) {
    uncertainty_df <- batch_uncertainty_scores(predictions, return_components = FALSE)
    results$uncertainty_score <- uncertainty_df$uncertainty_score
    results$confidence_category <- uncertainty_df$confidence_category
  }

  return(results)
}

# ==============================================================================
# Blending Functions (ML + Rule-Based)
# ==============================================================================

#' Blend ML predictions with rule-based predictions
#'
#' @param ml_result List. ML prediction result
#' @param rule_result List. Rule-based prediction result
#' @param ml_weight Numeric. Weight for ML (default: 0.7)
#' @return List. Blended prediction
#' @export
blend_predictions <- function(ml_result, rule_result, ml_weight = 0.7) {
  rule_weight <- 1 - ml_weight

  # Blend existence probabilities
  ml_prob <- ml_result$existence_probability %||% 0.5
  rule_prob <- rule_result$confidence %||% 0.5

  blended_prob <- ml_weight * ml_prob + rule_weight * rule_prob
  connection_exists <- blended_prob >= 0.5

  # Use ML predictions for strength/confidence/polarity if connection exists
  # Otherwise use rule-based as fallback
  if (connection_exists) {
    strength <- ml_result$strength %||% rule_result$strength %||% "medium"
    confidence <- round(ml_result$confidence %||% rule_result$confidence %||% 3)
    polarity <- ml_result$polarity %||% rule_result$polarity %||% "+"
  } else {
    strength <- rule_result$strength %||% "medium"
    confidence <- rule_result$confidence %||% 3
    polarity <- rule_result$polarity %||% "+"
  }

  return(list(
    connection_exists = connection_exists,
    existence_probability = blended_prob,
    strength = strength,
    confidence = confidence,
    polarity = polarity,
    method = "blended",
    ml_weight = ml_weight,
    ml_contribution = ml_prob,
    rule_contribution = rule_prob
  ))
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' Get ML model information
#'
#' @return List with model metadata
#' @export
get_ml_model_info <- function() {
  if (!ml_model_available()) {
    return(list(loaded = FALSE))
  }

  # Count parameters
  total_params <- 0
  for (param in .ml_env$model$parameters) {
    total_params <- total_params + param$numel()
  }

  return(list(
    loaded = TRUE,
    path = .ml_env$model_path,
    parameters = total_params,
    size_mb = round(total_params * 4 / 1024^2, 2),
    input_dim = 358,
    architecture = "Multi-task Neural Network"
  ))
}

# ==============================================================================
# Load message
# ==============================================================================

debug_log("ML Inference wrapper loaded", "ML_INFERENCE")
debug_log("load_ml_model(): Load trained model", "ML_INFERENCE")
debug_log("predict_connection_ml(): Single prediction", "ML_INFERENCE")
debug_log("predict_batch_ml(): Batch predictions", "ML_INFERENCE")
debug_log("blend_predictions(): Blend ML + rules", "ML_INFERENCE")
