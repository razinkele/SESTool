# ==============================================================================
# ML Inference Wrapper Functions
# ==============================================================================
# Simple API for loading trained models and making connection predictions.
#
# Inference pipeline with graceful fallback:
#   1. Ensemble (Phase 2, 5 models) -- if ensemble loaded
#   2. Phase 2 single model (connection_predictor_v2, 314-dim) -- if v2 model loaded
#   3. Phase 1 single model (connection_predictor, 358-dim) -- if v1 model loaded
#   4. Rule-based fallback -- always available (caller handles this)
#
# Main functions:
# - load_ml_model(): Load trained model into memory (Phase 1 or Phase 2)
# - predict_connection_ml(): Predict connection between two elements
# - predict_batch_ml(): Batch predictions for multiple element pairs
# - ml_model_available(): Check if ML model is loaded
# ==============================================================================

# Check for torch availability - graceful degradation if not installed
.ml_torch_available <- requireNamespace("torch", quietly = TRUE)
if (!.ml_torch_available) {
  debug_log("Package 'torch' not available - ML features will be disabled", "ML_INFERENCE")
  debug_log("To enable ML features, install torch: install.packages('torch')", "ML_INFERENCE")
} else {
  # Only source if not already loaded (global.R may have loaded them first)
  if (!exists("create_feature_vector", mode = "function")) {
    source("functions/ml_feature_engineering.R")
  }
  if (!exists("connection_predictor")) {
    source("functions/ml_models.R")
  }
}

# ==============================================================================
# Global Model Cache
# ==============================================================================

.ml_env <- new.env(parent = emptyenv())
.ml_env$model <- NULL
.ml_env$model_loaded <- FALSE
.ml_env$model_path <- "models/connection_predictor_best.pt"
# Phase 2 fields: track which model version is loaded
.ml_env$model_version <- NULL   # "v1" or "v2"
.ml_env$model_input_dim <- NULL # 358 for v1, 314 for v2

# ==============================================================================
# Model Integrity Verification
# ==============================================================================

# Expected SHA-256 hashes for trusted model files.
# Hashes are loaded from models/checksums.json on first verification call.
# To enable verification in production, set:
#   Sys.setenv(MARINESABRES_VERIFY_MODELS = "TRUE")
# In development mode (default), verification is skipped.
.ml_model_hashes <- list()
.ml_hashes_loaded <- FALSE

#' Load model checksums from models/checksums.json
#'
#' Reads the checksums JSON file and populates .ml_model_hashes with
#' normalized paths mapped to expected SHA-256 hashes. Called automatically
#' on first verification attempt.
#'
#' @return Logical. TRUE if checksums were loaded, FALSE otherwise.
#' @keywords internal
.load_model_checksums <- function() {
  if (.ml_hashes_loaded) return(length(.ml_model_hashes) > 0)

  checksums_path <- file.path("models", "checksums.json")
  if (!file.exists(checksums_path)) {
    debug_log("No models/checksums.json found - model verification unavailable", "ML_INFERENCE")
    .ml_hashes_loaded <<- TRUE
    return(FALSE)
  }

  tryCatch({
    checksums_data <- jsonlite::fromJSON(checksums_path, simplifyVector = TRUE)
    model_hashes <- checksums_data$models
    if (is.null(model_hashes) || length(model_hashes) == 0) {
      debug_log("checksums.json loaded but contains no model entries", "ML_INFERENCE")
      .ml_hashes_loaded <<- TRUE
      return(FALSE)
    }

    # Map relative paths (as stored in JSON) to normalized absolute paths
    for (rel_path in names(model_hashes)) {
      full_path <- normalizePath(file.path("models", rel_path), mustWork = FALSE)
      .ml_model_hashes[[full_path]] <<- model_hashes[[rel_path]]
    }

    debug_log(sprintf("Loaded %d model checksums from %s", length(model_hashes), checksums_path), "ML_INFERENCE")
    .ml_hashes_loaded <<- TRUE
    return(TRUE)
  }, error = function(e) {
    debug_log(sprintf("Failed to load checksums.json: %s", e$message), "ML_INFERENCE")
    .ml_hashes_loaded <<- TRUE
    return(FALSE)
  })
}

#' Verify model file integrity using SHA-256 checksum
#'
#' Checks whether model integrity verification is enabled (via the
#' MARINESABRES_VERIFY_MODELS environment variable). When enabled, compares
#' the file's SHA-256 hash against the expected hash from models/checksums.json.
#' In development mode (default), verification is skipped.
#'
#' @param model_path Character. Path to model file.
#' @return TRUE if verified or verification skipped, FALSE if hash mismatch.
#' @keywords internal
.verify_model_integrity <- function(model_path) {
  # Check if verification is enabled (production mode)
  verify_enabled <- identical(
    toupper(Sys.getenv("MARINESABRES_VERIFY_MODELS", "FALSE")),
    "TRUE"
  )

  if (!verify_enabled) {
    debug_log("Model verification skipped (development mode). Set MARINESABRES_VERIFY_MODELS=TRUE for production.", "ML_INFERENCE")
    return(TRUE)
  }

  # Ensure checksums are loaded from JSON
  .load_model_checksums()

  expected_hash <- .ml_model_hashes[[normalizePath(model_path, mustWork = FALSE)]]

  if (is.null(expected_hash)) {
    debug_log(
      sprintf("WARNING: No expected hash registered for model '%s' - verification cannot proceed.", model_path),
      "ML_INFERENCE"
    )
    debug_log(
      "Run scripts/generate_model_checksums.R to update models/checksums.json.",
      "ML_INFERENCE"
    )
    # In production mode, refuse to load unverified models
    return(FALSE)
  }

  if (!requireNamespace("digest", quietly = TRUE)) {
    debug_log("Package 'digest' not available - cannot verify model integrity", "ML_INFERENCE")
    return(FALSE)
  }

  actual_hash <- tryCatch(
    digest::digest(file = model_path, algo = "sha256"),
    error = function(e) {
      debug_log(sprintf("Failed to compute hash for %s: %s", model_path, e$message), "ML_INFERENCE")
      return(NULL)
    }
  )

  if (is.null(actual_hash)) {
    debug_log("Model integrity check FAILED - could not compute file hash", "ML_INFERENCE")
    return(FALSE)
  }

  if (!identical(actual_hash, expected_hash)) {
    debug_log(
      sprintf("Model integrity check FAILED for %s: expected hash %s, got %s",
              model_path, expected_hash, actual_hash),
      "ML_INFERENCE"
    )
    return(FALSE)
  }

  debug_log(sprintf("Model integrity verified for %s (SHA-256: %s)", model_path, actual_hash), "ML_INFERENCE")
  return(TRUE)
}

#' Detect model version from a loaded torch model
#'
#' Checks whether the loaded model is a Phase 1 (ConnectionPredictor) or
#' Phase 2 (ConnectionPredictorV2) model by inspecting its class name
#' and architecture.
#'
#' @param model A loaded torch nn_module
#' @return Character. "v2" if ConnectionPredictorV2, "v1" otherwise.
#' @keywords internal
.detect_model_version <- function(model) {
  # Check class name first (most reliable)
  model_class <- class(model)
  if (any(grepl("ConnectionPredictorV2", model_class, fixed = TRUE))) {
    return("v2")
  }

  # Check for Phase 2 specific attributes
  if (!is.null(model$context_embed) || !is.null(model$use_embeddings)) {
    return("v2")
  }

  # Check input_dim: Phase 2 uses 314, Phase 1 uses 358
  if (!is.null(model$input_dim) && model$input_dim == 314) {
    return("v2")
  }

  return("v1")
}

# ==============================================================================
# Model Loading Functions
# ==============================================================================

#' Load trained ML model into memory
#'
#' Loads either a Phase 1 (358-dim) or Phase 2 (314-dim) model.
#' Model version is auto-detected from the loaded weights.
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

  # Phase 2: Also try v2 model path if default v1 path not found
  if (!file.exists(model_path)) {
    v2_path <- "models/connection_predictor_v2_best.pt"
    if (file.exists(v2_path)) {
      debug_log(sprintf("Phase 1 model not found, trying Phase 2 model: %s", v2_path), "ML_INFERENCE")
      model_path <- v2_path
    }
  }

  # Check if model file exists
  if (!file.exists(model_path)) {
    debug_log(sprintf("ML model file not found: %s", model_path), "ML_INFERENCE")
    debug_log(sprintf("Working directory: %s", getwd()), "ML_INFERENCE")
    .ml_env$model_loaded <- FALSE
    .ml_env$model_version <- NULL
    return(FALSE)
  }

  # Verify model integrity before loading
  if (!.verify_model_integrity(model_path)) {
    debug_log(sprintf("SECURITY: Refusing to load unverified model: %s", model_path), "ML_INFERENCE")
    .ml_env$model_loaded <- FALSE
    return(FALSE)
  }

  # Load model
  tryCatch({
    .ml_env$model <- torch_load(model_path)
    .ml_env$model$eval()  # Set to evaluation mode
    .ml_env$model_path <- model_path

    # Auto-detect model version
    .ml_env$model_version <- .detect_model_version(.ml_env$model)
    .ml_env$model_input_dim <- if (.ml_env$model_version == "v2") 314 else 358

    .ml_env$model_loaded <- TRUE
    debug_log(sprintf("ML model loaded successfully from %s (version: %s, input_dim: %d)",
                      model_path, .ml_env$model_version, .ml_env$model_input_dim), "ML_INFERENCE")
    return(TRUE)
  }, error = function(e) {
    debug_log(sprintf("Failed to load ML model from %s: %s", model_path, e$message), "ML_INFERENCE")
    .ml_env$model_loaded <- FALSE
    .ml_env$model_version <- NULL
    return(FALSE)
  })
}

#' Check if ML model is available
#'
#' @return Logical. TRUE if torch is installed and model is loaded and ready
#' @export
ml_model_available <- function() {
  # First check if torch is available
  if (!exists(".ml_torch_available") || !.ml_torch_available) {
    return(FALSE)
  }
  return(.ml_env$model_loaded && !is.null(.ml_env$model))
}

#' Check if Phase 2 model is loaded
#'
#' @return Logical. TRUE if the loaded model is a Phase 2 (v2) model
#' @export
ml_model_is_v2 <- function() {
  ml_model_available() && identical(.ml_env$model_version, "v2")
}

#' Unload ML model from memory
#'
#' @export
unload_ml_model <- function() {
  .ml_env$model <- NULL
  .ml_env$model_loaded <- FALSE
  .ml_env$model_version <- NULL
  .ml_env$model_input_dim <- NULL
  gc()  # Trigger garbage collection
  debug_log("ML model unloaded from memory", "ML_INFERENCE")
}

# ==============================================================================
# Phase 2 Feature Preparation Helpers
# ==============================================================================

#' Prepare Phase 2 features for a single element pair
#'
#' Creates the three separate input components needed by connection_predictor_v2:
#' elem_features (270-dim), context_data (indices for embedding lookup), and
#' graph_features (8-dim). Falls back gracefully when Phase 2 modules are
#' not available.
#'
#' @param source_name Character. Source element name
#' @param source_type Character. Source DAPSI(W)R(M) type
#' @param target_name Character. Target element name
#' @param target_type Character. Target DAPSI(W)R(M) type
#' @param regional_sea Character. Regional sea name
#' @param ecosystem_types Character. Ecosystem types
#' @param main_issues Character. Focal issues
#' @param graph igraph object. Current network graph (optional, for graph features)
#' @param nodes Dataframe. Nodes dataframe (optional, for graph features)
#' @param source_id Character. Source node ID (optional, for graph features)
#' @param target_id Character. Target node ID (optional, for graph features)
#' @return List with elem_features, context_data, graph_features (all torch tensors)
#' @keywords internal
.prepare_v2_features <- function(source_name, source_type,
                                  target_name, target_type,
                                  regional_sea, ecosystem_types, main_issues,
                                  graph = NULL, nodes = NULL,
                                  source_id = NULL, target_id = NULL) {

  debug_log("Preparing Phase 2 features (v2 pipeline)", "ML_INFERENCE")

  # --- Element features: 2x128 embeddings + 2x7 type encodings = 270 dims ---
  source_emb <- create_element_embedding(source_name, 128)
  source_type_enc <- encode_dapsiwrm_type(source_type)
  target_emb <- create_element_embedding(target_name, 128)
  target_type_enc <- encode_dapsiwrm_type(target_type)

  elem_vec <- c(source_emb, source_type_enc, target_emb, target_type_enc)
  elem_features <- torch_tensor(matrix(elem_vec, nrow = 1), dtype = torch_float())

  # --- Context data: indices for learned embeddings ---
  # Use context_to_indices() from ml_context_embeddings.R if available,
  # otherwise fall back to prepare_context_indices() from ml_feature_engineering.R
  context_data <- tryCatch({
    if (exists("context_to_indices", mode = "function")) {
      debug_log("Using context_to_indices() for Phase 2 context embeddings", "ML_INFERENCE")
      # context_to_indices returns torch tensors already
      idx <- context_to_indices(regional_sea, ecosystem_types, main_issues)
      # Ensure batch dimension (view as 1-element batch)
      list(
        sea_idx = idx$sea_idx$view(c(1, -1)),
        eco_idx = idx$eco_idx$view(c(1, -1)),
        issue_idx = idx$issue_idx$view(c(1, -1))
      )
    } else if (exists("prepare_context_indices", mode = "function")) {
      debug_log("Falling back to prepare_context_indices() for context", "ML_INFERENCE")
      ctx_idx <- prepare_context_indices(regional_sea, ecosystem_types, main_issues)
      list(
        sea_idx = torch_tensor(matrix(ctx_idx$sea_idx, nrow = 1), dtype = torch_long()),
        eco_idx = torch_tensor(matrix(ctx_idx$eco_idx, nrow = 1), dtype = torch_long()),
        issue_idx = torch_tensor(matrix(ctx_idx$issue_idx, nrow = 1), dtype = torch_long())
      )
    } else {
      debug_log("No context index function available, using defaults", "ML_INFERENCE")
      list(
        sea_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long()),
        eco_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long()),
        issue_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long())
      )
    }
  }, error = function(e) {
    debug_log(sprintf("Context index preparation failed: %s, using defaults", e$message), "ML_INFERENCE")
    list(
      sea_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long()),
      eco_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long()),
      issue_idx = torch_tensor(matrix(1L, nrow = 1), dtype = torch_long())
    )
  })

  # --- Graph features: 8 dims from ml_graph_features.R ---
  graph_features <- tryCatch({
    if (exists("extract_graph_features", mode = "function") &&
        !is.null(graph) && !is.null(nodes) &&
        !is.null(source_id) && !is.null(target_id)) {
      debug_log("Extracting graph structural features (8-dim)", "ML_INFERENCE")
      gf <- extract_graph_features(source_id, target_id, graph, nodes)
      torch_tensor(matrix(gf, nrow = 1), dtype = torch_float())
    } else {
      debug_log("Graph features not available, zero-padding (8-dim)", "ML_INFERENCE")
      torch_zeros(c(1, 8))
    }
  }, error = function(e) {
    debug_log(sprintf("Graph feature extraction failed: %s, zero-padding", e$message), "ML_INFERENCE")
    torch_zeros(c(1, 8))
  })

  return(list(
    elem_features = elem_features,
    context_data = context_data,
    graph_features = graph_features
  ))
}

# ==============================================================================
# Internal: Process raw model predictions into result list
# ==============================================================================

#' Process raw model output tensors into a structured result list
#'
#' @param predictions List with existence, strength, confidence, polarity tensors
#' @param source_name Character.
#' @param source_type Character.
#' @param target_name Character.
#' @param target_type Character.
#' @param threshold Numeric.
#' @param method Character. Method label for the result.
#' @param return_uncertainty Logical.
#' @return List with processed prediction results.
#' @keywords internal
.process_predictions <- function(predictions, source_name, source_type,
                                  target_name, target_type, threshold,
                                  method = "ml", return_uncertainty = TRUE) {
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

  # Build result
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
    method = method
  )

  # Add uncertainty information if available and requested
  if (return_uncertainty && exists("calculate_connection_uncertainty", mode = "function")) {
    tryCatch({
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
    }, error = function(e) {
      debug_log(sprintf("Uncertainty calculation failed: %s", e$message), "ML_INFERENCE")
    })
  }

  return(result)
}

# ==============================================================================
# Prediction Functions
# ==============================================================================

#' Predict connection between two SES elements
#'
#' Uses the best available inference pipeline with graceful fallback:
#' Ensemble (Phase 2) -> Phase 2 single model -> Phase 1 single model -> NULL.
#'
#' @param source_name Character. Name of source element
#' @param source_type Character. DAPSI(W)R(M) type of source
#' @param target_name Character. Name of target element
#' @param target_type Character. DAPSI(W)R(M) type of target
#' @param context List. Context information (regional_sea, ecosystem_types, main_issues)
#' @param threshold Numeric. Probability threshold for connection existence (default: 0.5)
#' @param return_uncertainty Logical. Include uncertainty scores (default: TRUE)
#' @param graph igraph object. Current network graph (optional, for Phase 2 graph features)
#' @param nodes Dataframe. Node data (optional, for Phase 2 graph features)
#' @param source_id Character. Source node ID in graph (optional)
#' @param target_id Character. Target node ID in graph (optional)
#' @return List with prediction results, or NULL if no model available
#' @export
predict_connection_ml <- function(source_name, target_name,
                                   source_type = NULL, target_type = NULL,
                                   context = list(), threshold = 0.5,
                                   return_uncertainty = TRUE,
                                   graph = NULL, nodes = NULL,
                                   source_id = NULL, target_id = NULL) {
  # Check if model is loaded
  if (!ml_model_available()) {
    debug_log("predict_connection_ml: ML model not available, returning NULL", "ML_INFERENCE")
    return(NULL)
  }

  debug_log("predict_connection_ml: Starting inference pipeline", "ML_INFERENCE")

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

  # =========================================================================
  # Pipeline Stage 1: Try Ensemble (Phase 2, multiple models)
  # =========================================================================
  if (exists("ensemble_available", mode = "function") && ensemble_available()) {
    debug_log("Pipeline stage 1: Attempting ensemble prediction", "ML_INFERENCE")
    ensemble_result <- tryCatch({
      predict_connection_ensemble(
        source_name = source_name,
        target_name = target_name,
        source_type = source_type,
        target_type = target_type,
        context = context,
        threshold = threshold,
        return_disagreement = return_uncertainty
      )
    }, error = function(e) {
      debug_log(sprintf("Ensemble prediction failed: %s", e$message), "ML_INFERENCE")
      NULL
    })

    if (!is.null(ensemble_result)) {
      debug_log(sprintf("Ensemble prediction succeeded (n_models=%d, prob=%.3f)",
                        ensemble_result$n_models, ensemble_result$existence_probability), "ML_INFERENCE")
      return(ensemble_result)
    }
    debug_log("Ensemble prediction returned NULL, falling back to single model", "ML_INFERENCE")
  }

  # =========================================================================
  # Pipeline Stage 2: Try Phase 2 single model (v2, 314-dim)
  # =========================================================================
  if (ml_model_is_v2()) {
    debug_log("Pipeline stage 2: Using Phase 2 model (v2, 314-dim)", "ML_INFERENCE")

    v2_result <- tryCatch({
      v2_features <- .prepare_v2_features(
        source_name = source_name, source_type = source_type,
        target_name = target_name, target_type = target_type,
        regional_sea = regional_sea, ecosystem_types = ecosystem_types,
        main_issues = main_issues,
        graph = graph, nodes = nodes,
        source_id = source_id, target_id = target_id
      )

      # Phase 2 forward pass: model(elem_features, context_data, graph_features)
      with_no_grad({
        predictions <- .ml_env$model(
          v2_features$elem_features,
          v2_features$context_data,
          v2_features$graph_features
        )
      })

      .process_predictions(
        predictions = predictions,
        source_name = source_name, source_type = source_type,
        target_name = target_name, target_type = target_type,
        threshold = threshold, method = "ml_v2",
        return_uncertainty = return_uncertainty
      )
    }, error = function(e) {
      debug_log(sprintf("Phase 2 single model prediction failed: %s", e$message), "ML_INFERENCE")
      NULL
    })

    if (!is.null(v2_result)) {
      debug_log(sprintf("Phase 2 prediction succeeded (prob=%.3f)", v2_result$existence_probability), "ML_INFERENCE")
      return(v2_result)
    }
    debug_log("Phase 2 prediction failed, falling back to Phase 1", "ML_INFERENCE")
  }

  # =========================================================================
  # Pipeline Stage 3: Phase 1 single model (v1, 358-dim)
  # =========================================================================
  debug_log("Pipeline stage 3: Using Phase 1 model (v1, 358-dim)", "ML_INFERENCE")

  v1_result <- tryCatch({
    # Create Phase 1 feature vector (one-hot context, no graph features)
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

    # Phase 1 forward pass: model(x)
    with_no_grad({
      predictions <- .ml_env$model(x)
    })

    .process_predictions(
      predictions = predictions,
      source_name = source_name, source_type = source_type,
      target_name = target_name, target_type = target_type,
      threshold = threshold, method = "ml",
      return_uncertainty = return_uncertainty
    )
  }, error = function(e) {
    debug_log(sprintf("Phase 1 single model prediction failed: %s", e$message), "ML_INFERENCE")
    NULL
  })

  if (!is.null(v1_result)) {
    debug_log(sprintf("Phase 1 prediction succeeded (prob=%.3f)", v1_result$existence_probability), "ML_INFERENCE")
    return(v1_result)
  }

  # =========================================================================
  # All ML stages failed
  # =========================================================================
  debug_log("All ML prediction stages failed, returning NULL", "ML_INFERENCE")
  return(NULL)
}

#' Predict connections for multiple element pairs (batch)
#'
#' Supports both Phase 1 (358-dim) and Phase 2 (314-dim) models.
#' Automatically selects the correct feature pipeline based on loaded model version.
#'
#' @param pairs Dataframe with columns: source_name, target_name, source_type, target_type
#' @param context List. Context information
#' @param threshold Numeric. Probability threshold
#' @param return_uncertainty Logical. Include uncertainty scores (default: TRUE)
#' @param graph igraph object. Current network (optional, for Phase 2 graph features)
#' @param nodes Dataframe. Node data (optional, for Phase 2 graph features)
#' @return Dataframe with predictions
#' @export
predict_batch_ml <- function(pairs, context = list(), threshold = 0.5,
                              return_uncertainty = TRUE,
                              graph = NULL, nodes = NULL) {
  if (!ml_model_available()) {
    debug_log("predict_batch_ml: ML model not available, returning NULL", "ML_INFERENCE")
    return(NULL)
  }

  # Default context
  regional_sea <- context$regional_sea %||% "Other"
  ecosystem_types <- context$ecosystem_types %||% "Other"
  main_issues <- context$main_issues %||% "Other"

  n_pairs <- nrow(pairs)
  debug_log(sprintf("predict_batch_ml: Processing %d pairs (model version: %s)",
                    n_pairs, .ml_env$model_version %||% "v1"), "ML_INFERENCE")

  # =========================================================================
  # Phase 2 batch path (v2 model)
  # =========================================================================
  if (ml_model_is_v2()) {
    debug_log("predict_batch_ml: Using Phase 2 feature pipeline", "ML_INFERENCE")

    batch_result <- tryCatch({
      # Build element features matrix (n_pairs x 270)
      elem_matrix <- matrix(0, nrow = n_pairs, ncol = 270)
      for (i in 1:n_pairs) {
        src_emb <- create_element_embedding(pairs$source_name[i], 128)
        src_type <- encode_dapsiwrm_type(pairs$source_type[i] %||% "Activities")
        tgt_emb <- create_element_embedding(pairs$target_name[i], 128)
        tgt_type <- encode_dapsiwrm_type(pairs$target_type[i] %||% "Pressures")
        elem_matrix[i, ] <- c(src_emb, src_type, tgt_emb, tgt_type)
      }
      elem_features <- torch_tensor(elem_matrix, dtype = torch_float())

      # Context indices (shared across batch -- same project context)
      context_data <- tryCatch({
        if (exists("context_to_indices", mode = "function")) {
          idx <- context_to_indices(regional_sea, ecosystem_types, main_issues)
          # Expand to batch size
          list(
            sea_idx = idx$sea_idx$view(c(1, -1))$expand(c(n_pairs, -1)),
            eco_idx = idx$eco_idx$view(c(1, -1))$expand(c(n_pairs, -1)),
            issue_idx = idx$issue_idx$view(c(1, -1))$expand(c(n_pairs, -1))
          )
        } else {
          list(
            sea_idx = torch_ones(c(n_pairs, 1), dtype = torch_long()),
            eco_idx = torch_ones(c(n_pairs, 1), dtype = torch_long()),
            issue_idx = torch_ones(c(n_pairs, 1), dtype = torch_long())
          )
        }
      }, error = function(e) {
        debug_log(sprintf("Batch context index preparation failed: %s", e$message), "ML_INFERENCE")
        list(
          sea_idx = torch_ones(c(n_pairs, 1), dtype = torch_long()),
          eco_idx = torch_ones(c(n_pairs, 1), dtype = torch_long()),
          issue_idx = torch_ones(c(n_pairs, 1), dtype = torch_long())
        )
      })

      # Graph features (batch)
      graph_features <- tryCatch({
        if (exists("extract_graph_features_batch", mode = "function") &&
            !is.null(graph) && !is.null(nodes) &&
            "source_id" %in% names(pairs) && "target_id" %in% names(pairs)) {
          debug_log("Extracting batch graph features", "ML_INFERENCE")
          gf_matrix <- extract_graph_features_batch(pairs$source_id, pairs$target_id, graph, nodes)
          torch_tensor(gf_matrix, dtype = torch_float())
        } else {
          torch_zeros(c(n_pairs, 8))
        }
      }, error = function(e) {
        debug_log(sprintf("Batch graph feature extraction failed: %s", e$message), "ML_INFERENCE")
        torch_zeros(c(n_pairs, 8))
      })

      # Phase 2 forward pass
      with_no_grad({
        predictions <- .ml_env$model(elem_features, context_data, graph_features)
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
      if (return_uncertainty && exists("batch_uncertainty_scores", mode = "function")) {
        tryCatch({
          uncertainty_df <- batch_uncertainty_scores(predictions, return_components = FALSE)
          results$uncertainty_score <- uncertainty_df$uncertainty_score
          results$confidence_category <- uncertainty_df$confidence_category
        }, error = function(e) {
          debug_log(sprintf("Batch uncertainty calculation failed: %s", e$message), "ML_INFERENCE")
        })
      }

      results
    }, error = function(e) {
      debug_log(sprintf("Phase 2 batch prediction failed: %s, falling back to Phase 1", e$message), "ML_INFERENCE")
      NULL
    })

    if (!is.null(batch_result)) {
      return(batch_result)
    }
    # Fall through to Phase 1 path
  }

  # =========================================================================
  # Phase 1 batch path (v1 model, dynamically-sized feature vector)
  # =========================================================================
  debug_log("predict_batch_ml: Using Phase 1 feature pipeline", "ML_INFERENCE")

  # Compute actual feature dimension from first pair
  first_fv <- create_feature_vector(
    source_name = pairs$source_name[1],
    source_type = pairs$source_type[1] %||% "Activities",
    target_name = pairs$target_name[1],
    target_type = pairs$target_type[1] %||% "Pressures",
    regional_sea = regional_sea,
    ecosystem_types = ecosystem_types,
    main_issues = main_issues,
    embedding_dim = 128
  )
  feature_dim <- length(first_fv)

  feature_matrix <- matrix(0, nrow = n_pairs, ncol = feature_dim)
  feature_matrix[1, ] <- first_fv

  if (n_pairs > 1) {
    for (i in 2:n_pairs) {
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
  if (return_uncertainty && exists("batch_uncertainty_scores", mode = "function")) {
    tryCatch({
      uncertainty_df <- batch_uncertainty_scores(predictions, return_components = FALSE)
      results$uncertainty_score <- uncertainty_df$uncertainty_score
      results$confidence_category <- uncertainty_df$confidence_category
    }, error = function(e) {
      debug_log(sprintf("Batch uncertainty calculation failed: %s", e$message), "ML_INFERENCE")
    })
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

  model_version <- .ml_env$model_version %||% "v1"
  input_dim <- .ml_env$model_input_dim %||% 358

  architecture <- if (model_version == "v2") {
    "Multi-task Neural Network (Phase 2 - context embeddings + graph features)"
  } else {
    "Multi-task Neural Network"
  }

  # Check ensemble status
  ensemble_loaded <- exists("ensemble_available", mode = "function") && ensemble_available()
  ensemble_count <- if (ensemble_loaded && exists("ensemble_env")) ensemble_env$n_models else 0

  return(list(
    loaded = TRUE,
    path = .ml_env$model_path,
    parameters = total_params,
    size_mb = round(total_params * 4 / 1024^2, 2),
    input_dim = input_dim,
    model_version = model_version,
    architecture = architecture,
    ensemble_loaded = ensemble_loaded,
    ensemble_count = ensemble_count,
    pipeline = if (ensemble_loaded) "ensemble" else if (model_version == "v2") "phase2" else "phase1"
  ))
}

# ==============================================================================
# Load message
# ==============================================================================

debug_log("ML Inference wrapper loaded (Phase 1 + Phase 2 pipeline support)", "ML_INFERENCE")
debug_log("load_ml_model(): Load trained model (auto-detects v1/v2)", "ML_INFERENCE")
debug_log("predict_connection_ml(): Single prediction with fallback: ensemble -> v2 -> v1", "ML_INFERENCE")
debug_log("predict_batch_ml(): Batch predictions (v1 or v2)", "ML_INFERENCE")
debug_log("blend_predictions(): Blend ML + rules", "ML_INFERENCE")
