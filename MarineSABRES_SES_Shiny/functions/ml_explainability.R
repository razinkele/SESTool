# =============================================================================
# ML EXPLAINABILITY MODULE
# File: functions/ml_explainability.R
# =============================================================================
#
# Purpose:
#   Provides explainability features for ML predictions including feature
#   importance, SHAP-like explanations, and human-readable prediction reasons.
#
# Features:
#   - Feature importance (gradient-based, permutation)
#   - SHAP-like value approximations
#   - Natural language explanation generation
#   - Confidence calibration insights
#
# Usage:
#   explanation <- explain_prediction(model, elem1, elem2, context)
#   print(explanation)
#
# =============================================================================

# =============================================================================
# FEATURE IMPORTANCE ANALYSIS
# =============================================================================

#' Calculate Feature Importance via Gradients
#'
#' Computes gradient-based feature importance for a prediction.
#' Higher absolute gradients indicate more important features.
#'
#' @param model Torch model
#' @param elem_features Element features tensor
#' @param context_data Context data tensor (optional)
#' @param graph_features Graph features tensor (optional)
#' @param task Character. Which output to explain ("existence", "polarity", etc.)
#' @return List with feature_importance vector and feature_names
#' @export
calculate_gradient_importance <- function(model,
                                           elem_features,
                                           context_data = NULL,
                                           graph_features = NULL,
                                           task = "existence") {

  if (!requireNamespace("torch", quietly = TRUE)) {
    stop("Package 'torch' required for gradient importance")
  }

  # Enable gradient tracking
  elem_features_grad <- elem_features$clone()$requires_grad_(TRUE)

  # Forward pass
  with_enable_grad({
    predictions <- model(elem_features_grad, context_data, graph_features)

    # Get the relevant output
    output <- switch(task,
      "existence" = predictions$existence,
      "polarity" = predictions$polarity,
      "strength" = predictions$strength,
      "confidence" = predictions$confidence,
      predictions$existence  # default
    )

    # Backpropagate
    if (task == "strength") {
      # For multi-class, use max logit
      target <- output$max(dim = 2)[[1]]
    } else {
      target <- output$squeeze()
    }

    target$backward()
  })

  # Get gradients
  gradients <- elem_features_grad$grad$abs()$squeeze()$to(device = "cpu")$as_array()

  list(
    importance = gradients,
    task = task
  )
}

#' Calculate Permutation Feature Importance
#'
#' Measures feature importance by shuffling each feature and measuring
#' prediction change. More robust but slower than gradient-based.
#'
#' @param model Torch model
#' @param elem_features Element features tensor
#' @param context_data Context data tensor (optional)
#' @param graph_features Graph features tensor (optional)
#' @param n_permutations Number of permutations per feature (default: 10)
#' @param task Which output to measure
#' @return List with feature_importance vector
#' @export
calculate_permutation_importance <- function(model,
                                              elem_features,
                                              context_data = NULL,
                                              graph_features = NULL,
                                              n_permutations = 10,
                                              task = "existence") {

  if (!requireNamespace("torch", quietly = TRUE)) {
    stop("Package 'torch' required for permutation importance")
  }

  model$eval()

  # Get baseline prediction
  with_no_grad({
    baseline_pred <- model(elem_features, context_data, graph_features)
    baseline_value <- switch(task,
      "existence" = torch_sigmoid(baseline_pred$existence),
      "polarity" = torch_sigmoid(baseline_pred$polarity),
      baseline_pred$existence
    )
    baseline_value <- as.numeric(baseline_value$to(device = "cpu"))
  })

  n_features <- elem_features$size(2)
  importance <- numeric(n_features)

  # Permute each feature
  for (i in 1:n_features) {
    diffs <- numeric(n_permutations)

    for (j in 1:n_permutations) {
      # Create permuted copy
      permuted <- elem_features$clone()

      # Shuffle feature i
      perm_idx <- sample(permuted$size(1))
      permuted[, i] <- permuted[perm_idx, i]

      # Get prediction with permuted feature
      with_no_grad({
        perm_pred <- model(permuted, context_data, graph_features)
        perm_value <- switch(task,
          "existence" = torch_sigmoid(perm_pred$existence),
          "polarity" = torch_sigmoid(perm_pred$polarity),
          perm_pred$existence
        )
        perm_value <- as.numeric(perm_value$to(device = "cpu"))
      })

      diffs[j] <- abs(baseline_value - perm_value)
    }

    importance[i] <- mean(diffs)
  }

  list(
    importance = importance,
    baseline = baseline_value,
    task = task
  )
}

# =============================================================================
# SHAP-LIKE EXPLANATIONS
# =============================================================================

#' Approximate SHAP Values Using Sampling
#'
#' Approximates Shapley values using random sampling of feature coalitions.
#' Provides additive feature attributions that sum to prediction - baseline.
#'
#' @param model Torch model
#' @param elem_features Element features tensor (single sample)
#' @param context_data Context data tensor (optional)
#' @param graph_features Graph features tensor (optional)
#' @param n_samples Number of coalition samples (default: 100)
#' @param baseline_features Baseline features (default: zeros)
#' @return List with shap_values vector
#' @export
approximate_shap_values <- function(model,
                                     elem_features,
                                     context_data = NULL,
                                     graph_features = NULL,
                                     n_samples = 100,
                                     baseline_features = NULL) {

  if (!requireNamespace("torch", quietly = TRUE)) {
    stop("Package 'torch' required for SHAP values")
  }

  model$eval()

  n_features <- elem_features$size(2)

  # Use zeros as baseline if not provided
  if (is.null(baseline_features)) {
    baseline_features <- torch_zeros_like(elem_features)
  }

  # Get baseline and full predictions
  with_no_grad({
    baseline_pred <- model(baseline_features, context_data, graph_features)
    full_pred <- model(elem_features, context_data, graph_features)

    baseline_value <- as.numeric(torch_sigmoid(baseline_pred$existence)$to(device = "cpu"))
    full_value <- as.numeric(torch_sigmoid(full_pred$existence)$to(device = "cpu"))
  })

  # Initialize SHAP values
  shap_values <- numeric(n_features)
  shap_counts <- numeric(n_features)

  # Sample random coalitions
  for (s in 1:n_samples) {
    # Random subset of features to include
    coalition_size <- sample(0:n_features, 1)
    if (coalition_size == 0) next

    included <- sample(1:n_features, coalition_size)

    # Create coalition features (baseline + included features from input)
    coalition <- baseline_features$clone()
    for (i in included) {
      coalition[1, i] <- elem_features[1, i]
    }

    # Get coalition prediction
    with_no_grad({
      coal_pred <- model(coalition, context_data, graph_features)
      coal_value <- as.numeric(torch_sigmoid(coal_pred$existence)$to(device = "cpu"))
    })

    # Calculate marginal contribution for each included feature
    for (i in included) {
      # Remove feature i from coalition
      without_i <- coalition$clone()
      without_i[1, i] <- baseline_features[1, i]

      with_no_grad({
        without_pred <- model(without_i, context_data, graph_features)
        without_value <- as.numeric(torch_sigmoid(without_pred$existence)$to(device = "cpu"))
      })

      # Marginal contribution
      contribution <- coal_value - without_value
      shap_values[i] <- shap_values[i] + contribution
      shap_counts[i] <- shap_counts[i] + 1
    }
  }

  # Average contributions
  shap_values <- ifelse(shap_counts > 0, shap_values / shap_counts, 0)

  list(
    shap_values = shap_values,
    baseline_value = baseline_value,
    prediction = full_value,
    expected_sum = full_value - baseline_value,
    actual_sum = sum(shap_values)
  )
}

# =============================================================================
# NATURAL LANGUAGE EXPLANATIONS
# =============================================================================

#' Generate Human-Readable Prediction Explanation
#'
#' Creates a natural language explanation for why the model made its prediction.
#'
#' @param elem1 First element (list with type, label)
#' @param elem2 Second element (list with type, label)
#' @param prediction Model prediction (list with existence, polarity, strength, confidence)
#' @param feature_importance Optional feature importance scores
#' @param i18n Optional translator for internationalization
#' @return Character string with explanation
#' @export
generate_prediction_explanation <- function(elem1,
                                              elem2,
                                              prediction,
                                              feature_importance = NULL,
                                              i18n = NULL) {

  # Helper for translation
  t <- if (!is.null(i18n) && is.function(i18n$t)) {
    i18n$t
  } else {
    function(x) x
  }

  # Build explanation parts
  parts <- character(0)

  # Connection existence
  exists_prob <- prediction$existence
  if (exists_prob > 0.7) {
    parts <- c(parts, sprintf(
      "The model predicts a **strong likelihood** (%.0f%%) of a connection between '%s' and '%s'.",
      exists_prob * 100, elem1$label, elem2$label
    ))
  } else if (exists_prob > 0.5) {
    parts <- c(parts, sprintf(
      "The model predicts a **moderate likelihood** (%.0f%%) of a connection.",
      exists_prob * 100
    ))
  } else if (exists_prob > 0.3) {
    parts <- c(parts, sprintf(
      "The model predicts a **low likelihood** (%.0f%%) of a connection.",
      exists_prob * 100
    ))
  } else {
    parts <- c(parts, sprintf(
      "The model predicts **no significant connection** (%.0f%% probability).",
      exists_prob * 100
    ))
  }

  # Add reasoning based on element types
  type_reasons <- get_type_based_reasoning(elem1$type, elem2$type)
  if (!is.null(type_reasons)) {
    parts <- c(parts, type_reasons)
  }

  # Polarity explanation
  if (!is.null(prediction$polarity) && exists_prob > 0.5) {
    pol_prob <- prediction$polarity
    if (pol_prob > 0.6) {
      parts <- c(parts, "The relationship is likely **reinforcing** (positive feedback).")
    } else if (pol_prob < 0.4) {
      parts <- c(parts, "The relationship is likely **opposing** (negative feedback).")
    } else {
      parts <- c(parts, "The polarity is **uncertain** - could be either direction.")
    }
  }

  # Confidence note
  if (!is.null(prediction$model_confidence)) {
    if (prediction$model_confidence < 0.6) {
      parts <- c(parts, "\n*Note: Model confidence is low. Consider reviewing this prediction.*")
    }
  }

  # Feature importance explanation
  if (!is.null(feature_importance) && length(feature_importance$importance) > 0) {
    top_features <- get_top_important_features(feature_importance, n = 3)
    if (length(top_features) > 0) {
      feat_text <- paste("Top influential factors:", paste(top_features, collapse = ", "))
      parts <- c(parts, feat_text)
    }
  }

  paste(parts, collapse = "\n\n")
}

#' Get Type-Based Reasoning
#'
#' Provides DAPSIWRM-based reasoning for connection likelihood.
#'
#' @param type1 DAPSIWRM type of first element
#' @param type2 DAPSIWRM type of second element
#' @return Character string with reasoning or NULL
#' @keywords internal
get_type_based_reasoning <- function(type1, type2) {
  # DAPSIWRM flow relationships
  flow_pairs <- list(
    c("D", "A") = "Drivers commonly influence Activities in the DAPSIWRM framework.",
    c("A", "P") = "Activities typically create Pressures on the system.",
    c("P", "MPF") = "Pressures affect Marine Processes & Functioning.",
    c("P", "C") = "Pressures affect ecosystem Components/State.",
    c("MPF", "ES") = "Marine Processes provide Ecosystem Services.",
    c("C", "ES") = "Ecosystem state determines Services provision.",
    c("ES", "GB") = "Ecosystem Services generate Goods & Benefits.",
    c("GB", "D") = "Societal benefits can reinforce Drivers (feedback loop).",
    c("R", "A") = "Response measures typically target Activities.",
    c("R", "P") = "Response measures can directly address Pressures."
  )

  key <- paste(type1, type2, sep = "_")

  # Check direct match
  for (pair_key in names(flow_pairs)) {
    pair <- strsplit(pair_key, ", ")[[1]]
    if ((pair[1] == type1 && pair[2] == type2) ||
        (pair[1] == type2 && pair[2] == type1)) {
      return(flow_pairs[[pair_key]])
    }
  }

  NULL
}

#' Get Top Important Features
#'
#' Extracts top N most important feature names.
#'
#' @param feature_importance Feature importance result
#' @param n Number of top features to return
#' @return Character vector of feature descriptions
#' @keywords internal
get_top_important_features <- function(feature_importance, n = 3) {
  imp <- feature_importance$importance

  if (length(imp) == 0) return(character(0))

  # Get top indices
  top_idx <- order(imp, decreasing = TRUE)[1:min(n, length(imp))]

  # Map to feature names (simplified - would need actual feature mapping)
  feature_descriptions <- c(
    "Element type similarity",
    "Semantic embedding distance",
    "DAPSIWRM flow position",
    "Contextual features",
    "Graph structure patterns"
  )

  # Return top feature descriptions
  if (length(feature_descriptions) >= max(top_idx)) {
    feature_descriptions[top_idx]
  } else {
    sprintf("Feature %d", top_idx)
  }
}

# =============================================================================
# EXPLANATION RESULT CLASS
# =============================================================================

#' Create Prediction Explanation Object
#'
#' Bundles all explanation components into a single object.
#'
#' @param elem1 First element
#' @param elem2 Second element
#' @param prediction Model prediction
#' @param feature_importance Feature importance scores
#' @param shap_values SHAP value approximations
#' @param natural_language Natural language explanation
#' @return An explanation object
#' @export
create_explanation <- function(elem1,
                                elem2,
                                prediction,
                                feature_importance = NULL,
                                shap_values = NULL,
                                natural_language = NULL) {

  explanation <- list(
    elem1 = elem1,
    elem2 = elem2,
    prediction = prediction,
    feature_importance = feature_importance,
    shap_values = shap_values,
    natural_language = natural_language,
    timestamp = Sys.time()
  )

  class(explanation) <- c("ml_explanation", "list")
  explanation
}

#' Print ML Explanation
#' @param x ML explanation object
#' @param ... Additional arguments
#' @export
print.ml_explanation <- function(x, ...) {
  cat("ML Prediction Explanation\n")
  cat("=" |> rep(50) |> paste(collapse = ""), "\n\n")

  cat(sprintf("Elements: '%s' -> '%s'\n", x$elem1$label, x$elem2$label))
  cat(sprintf("Types: %s -> %s\n\n", x$elem1$type, x$elem2$type))

  cat("Prediction:\n")
  cat(sprintf("  Existence: %.1f%%\n", x$prediction$existence * 100))
  if (!is.null(x$prediction$polarity)) {
    cat(sprintf("  Polarity: %.1f%% (positive)\n", x$prediction$polarity * 100))
  }
  cat("\n")

  if (!is.null(x$natural_language)) {
    cat("Explanation:\n")
    cat(x$natural_language, "\n")
  }
}

# =============================================================================
# HIGH-LEVEL API
# =============================================================================

#' Explain a Connection Prediction
#'
#' High-level function to generate a full explanation for a prediction.
#'
#' @param model Trained model
#' @param elem1 First element (list with type, label, features)
#' @param elem2 Second element (list with type, label, features)
#' @param context_data Optional context data
#' @param graph_features Optional graph features
#' @param include_shap Whether to compute SHAP values (slower)
#' @param i18n Optional translator
#' @return An ml_explanation object
#' @export
explain_connection_prediction <- function(model,
                                           elem1,
                                           elem2,
                                           context_data = NULL,
                                           graph_features = NULL,
                                           include_shap = FALSE,
                                           i18n = NULL) {

  # Get prediction (assumes predict_connection_ml exists)
  prediction <- if (exists("predict_connection_ml", mode = "function")) {
    predict_connection_ml(model, elem1, elem2, context_data, graph_features)
  } else {
    list(existence = 0.5, polarity = 0.5)  # Fallback
  }

  # Calculate feature importance
  feat_imp <- NULL
  if (!is.null(elem1$features) && !is.null(elem2$features)) {
    tryCatch({
      elem_features <- torch_tensor(rbind(elem1$features, elem2$features))
      feat_imp <- calculate_gradient_importance(model, elem_features)
    }, error = function(e) {
      debug_log(sprintf("Feature importance failed: %s", e$message), "ML_EXPLAIN")
    })
  }

  # SHAP values (optional)
  shap_vals <- NULL
  if (include_shap && !is.null(elem1$features)) {
    tryCatch({
      elem_features <- torch_tensor(rbind(elem1$features, elem2$features))
      shap_vals <- approximate_shap_values(model, elem_features)
    }, error = function(e) {
      debug_log(sprintf("SHAP calculation failed: %s", e$message), "ML_EXPLAIN")
    })
  }

  # Generate natural language explanation
  nl_explanation <- generate_prediction_explanation(
    elem1, elem2, prediction, feat_imp, i18n
  )

  # Create and return explanation object
  create_explanation(
    elem1 = elem1,
    elem2 = elem2,
    prediction = prediction,
    feature_importance = feat_imp,
    shap_values = shap_vals,
    natural_language = nl_explanation
  )
}
