# modules/graphical_ses_ml_enhancer.R
# ML enhancements for graphical SES creator
# Wraps existing AI functions with ML-powered predictions

# Load dependencies
if (!exists("ml_model_available")) {
  source("functions/ml_inference.R")
}

# ==============================================================================
# ML-Enhanced Connection Prediction
# ==============================================================================

#' Predict connection with ML enhancement
#'
#' Blends ML predictions with rule-based logic for robust results
#'
#' @param from_element List with name and type
#' @param to_element List with name and type
#' @param context Context information
#' @param ml_weight Weight for ML predictions (default: 0.7)
#' @return List with connection prediction
#' @export
predict_connection_enhanced <- function(from_element, to_element, context, ml_weight = 0.7) {

  # Try ML prediction first
  ml_result <- NULL
  if (ml_model_available()) {
    tryCatch({
      ml_result <- predict_connection_ml(
        source_name = from_element$name,
        source_type = from_element$type,
        target_name = to_element$name,
        target_type = to_element$type,
        context = context,
        threshold = 0.5
      )
    }, error = function(e) {
      debug_log(paste("ML prediction failed:", e$message), "ML_ENHANCER")
    })
  }

  # Fallback to rule-based if ML not available
  if (is.null(ml_result)) {
    debug_log("Using rule-based prediction only", "ML_ENHANCER")

    # Simple rule-based prediction
    rule_result <- list(
      connection_exists = TRUE,  # Conservative: assume connection possible
      existence_probability = 0.5,
      strength = "medium",
      confidence = 3,
      polarity = "+",
      method = "rule-based"
    )

    return(rule_result)
  }

  # If ML succeeded, return ML result
  debug_log(paste("Using ML prediction (prob:", round(ml_result$existence_probability, 3), ")"), "ML_ENHANCER")
  return(ml_result)
}

# ==============================================================================
# ML-Enhanced Element Suggestions
# ==============================================================================

#' Suggest and rank connected elements using ML
#'
#' Enhances existing suggestion system with ML-based ranking
#'
#' @param node_id ID of node to expand from
#' @param node_data Node data (name, type)
#' @param existing_network Current network
#' @param context Context information
#' @param max_suggestions Maximum suggestions
#' @return List of ranked suggestions
#' @export
suggest_connected_elements_ml <- function(node_id, node_data, existing_network,
                                          context, max_suggestions = 5) {

  # Get base suggestions from existing system
  if (exists("suggest_connected_elements")) {
    base_suggestions <- suggest_connected_elements(
      node_id = node_id,
      node_data = node_data,
      existing_network = existing_network,
      context = context,
      max_suggestions = max_suggestions * 2  # Get more, then ML filter
    )
  } else {
    debug_log("Base suggestion function not found", "ML_ENHANCER")
    return(list())
  }

  if (length(base_suggestions) == 0) {
    return(list())
  }

  debug_log(paste("Got", length(base_suggestions), "base suggestions, applying ML ranking..."), "ML_ENHANCER")

  # If ML not available, return base suggestions
  if (!ml_model_available()) {
    debug_log("ML not available, returning base suggestions", "ML_ENHANCER")
    return(head(base_suggestions, max_suggestions))
  }

  # Score each suggestion with ML
  ml_scored_suggestions <- list()

  for (i in seq_along(base_suggestions)) {
    suggestion <- base_suggestions[[i]]

    # Get ML prediction for this connection
    ml_pred <- tryCatch({
      predict_connection_ml(
        source_name = node_data$name,
        source_type = node_data$type,
        target_name = suggestion$name,
        target_type = suggestion$type,
        context = context
      )
    }, error = function(e) {
      NULL
    })

    # Add ML score to suggestion
    if (!is.null(ml_pred)) {
      suggestion$ml_score <- ml_pred$existence_probability
      suggestion$ml_strength <- ml_pred$strength
      suggestion$ml_confidence <- ml_pred$confidence
      suggestion$ml_polarity <- ml_pred$polarity

      # Update connection properties with ML predictions
      if (ml_pred$existence_probability > 0.5) {
        suggestion$strength <- ml_pred$strength
        suggestion$confidence <- ml_pred$confidence
        suggestion$polarity <- ml_pred$polarity
      }
    } else {
      suggestion$ml_score <- 0.5  # Default neutral score
    }

    ml_scored_suggestions[[i]] <- suggestion
  }

  # Sort by ML score (descending)
  ml_scores <- sapply(ml_scored_suggestions, function(s) s$ml_score %||% 0)
  sorted_indices <- order(ml_scores, decreasing = TRUE)
  sorted_suggestions <- ml_scored_suggestions[sorted_indices]

  # Return top N
  top_suggestions <- head(sorted_suggestions, max_suggestions)

  debug_log(paste("Ranked suggestions by ML score, returning top", length(top_suggestions)), "ML_ENHANCER")

  return(top_suggestions)
}

# ==============================================================================
# ML-Enhanced Classification
# ==============================================================================

#' Classify element with ML enhancement
#'
#' Uses ML to improve classification confidence
#'
#' @param element_name Element name
#' @param context Context
#' @param reference_elements Existing elements for connection-based classification
#' @return Classification result
#' @export
classify_element_ml_enhanced <- function(element_name, context, reference_elements = NULL) {

  # Get base classification from existing AI
  base_classification <- if (exists("classify_element_with_ai")) {
    classify_element_with_ai(element_name, context)
  } else {
    list(
      primary = list(type = "Activities", confidence = 0.5),
      alternatives = list(),
      element_name = element_name
    )
  }

  # If ML not available, return base classification
  if (!ml_model_available() || is.null(reference_elements) || nrow(reference_elements) == 0) {
    return(base_classification)
  }

  # Try ML-based classification by testing connections with existing elements
  debug_log("Testing ML connections for classification refinement...", "ML_ENHANCER")

  type_scores <- list()

  # Test connections with a few existing elements of each type
  for (ref_type in unique(reference_elements$type)) {
    ref_elements_of_type <- reference_elements[reference_elements$type == ref_type, ]

    if (nrow(ref_elements_of_type) == 0) next

    # Sample up to 3 elements of this type
    sample_size <- min(3, nrow(ref_elements_of_type))
    sampled_refs <- ref_elements_of_type[sample(nrow(ref_elements_of_type), sample_size), ]

    # Test connections
    connection_probs <- numeric(sample_size)

    for (i in 1:sample_size) {
      pred <- tryCatch({
        predict_connection_ml(
          source_name = sampled_refs$name[i],
          source_type = sampled_refs$type[i],
          target_name = element_name,
          target_type = base_classification$primary$type,  # Use base classification
          context = context
        )
      }, error = function(e) NULL)

      connection_probs[i] <- if (!is.null(pred)) pred$existence_probability else 0.5
    }

    # Average connection probability for this type
    type_scores[[ref_type]] <- mean(connection_probs)
  }

  if (length(type_scores) > 0) {
    # Find type with highest average connection score
    best_type <- names(which.max(unlist(type_scores)))
    best_score <- max(unlist(type_scores))

    debug_log(paste("ML suggests type:", best_type, "(score:", round(best_score, 3), ")"), "ML_ENHANCER")

    # Blend with base classification
    if (best_score > 0.6 && best_type != base_classification$primary$type) {
      debug_log("ML overriding base classification", "ML_ENHANCER")
      base_classification$primary$type <- best_type
      base_classification$primary$confidence <- (best_score + base_classification$primary$confidence) / 2
      base_classification$primary$ml_enhanced <- TRUE
    }
  }

  return(base_classification)
}

# ==============================================================================
# Batch Prediction Utilities
# ==============================================================================

#' Predict connections for multiple pairs (for network analysis)
#'
#' @param pairs Dataframe with source_name, target_name, source_type, target_type
#' @param context Context
#' @return Dataframe with predictions
#' @export
batch_predict_network_connections <- function(pairs, context) {
  if (!ml_model_available()) {
    warning("ML model not loaded")
    return(NULL)
  }

  return(predict_batch_ml(pairs, context, threshold = 0.5))
}

# ==============================================================================
# Load message
# ==============================================================================

debug_log("ML Enhancer module loaded", "ML_ENHANCER")

# Try to load ML model automatically
if (!exists(".ml_enhancer_model_loaded")) {
  tryCatch({
    load_ml_model()
    .ml_enhancer_model_loaded <- TRUE
  }, error = function(e) {
    debug_log(paste("ML model not loaded:", e$message), "ML_ENHANCER")
    .ml_enhancer_model_loaded <- FALSE
  })
}
