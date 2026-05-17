# ==============================================================================
# ML Models for SES Connection Prediction
# ==============================================================================
# Deep learning models using torch for predicting connections between
# DAPSI(W)R(M) elements in Social-Ecological Systems frameworks.
#
# Models:
# - connection_predictor: Multi-task neural network (Phase 1, 358-dim input)
# - connection_predictor_v2: Enhanced with context embeddings (Phase 2, 314-dim)
#
# Phase 2 Enhancements:
# - Learned context embeddings (88 → 36 dims)
# - Graph structural features (+8 dims)
# - Backward compatible with Phase 1 models
#
# Dependencies: torch (>= 0.12.0)
# ==============================================================================

if (!requireNamespace("torch", quietly = TRUE)) {
  stop("Package 'torch' is required for ML features. Install with: install.packages('torch')")
}

# Load context embeddings module (Phase 2) - only if not already loaded
if (!exists("context_embeddings") && file.exists("functions/ml_context_embeddings.R")) {
  source("functions/ml_context_embeddings.R", local = TRUE)
}

# ==============================================================================
# Connection Predictor Model
# ==============================================================================

#' Multi-task Neural Network for Connection Prediction
#'
#' Predicts whether a connection exists between two SES elements, along with
#' connection properties (strength, confidence, polarity).
#'
#' Architecture:
#' - Input: Feature vector (default 358 dims)
#' - Shared backbone: 3 FC layers with batch norm and dropout
#' - Task-specific heads:
#'   * existence: Binary classification (connection yes/no)
#'   * strength: Multi-class (weak=1, medium=2, strong=3)
#'   * confidence: Regression (1-5 scale)
#'   * polarity: Binary classification (+1 or -1)
#'
#' @param input_dim Integer. Input feature dimension (default 358)
#' @param hidden_dim Integer. Hidden layer dimension (default 256)
#' @param dropout Numeric. Dropout rate (default 0.3)
#' @return torch nn_module
#' @export
connection_predictor <- nn_module(
  "ConnectionPredictor",

  initialize = function(input_dim = 358, hidden_dim = 256, dropout = 0.3) {
    # Store hyperparameters
    self$input_dim <- input_dim
    self$hidden_dim <- hidden_dim
    self$dropout_rate <- dropout

    # Shared backbone layers
    self$fc1 <- nn_linear(input_dim, hidden_dim)
    self$bn1 <- nn_batch_norm1d(hidden_dim)
    self$dropout1 <- nn_dropout(dropout)

    self$fc2 <- nn_linear(hidden_dim, hidden_dim)
    self$bn2 <- nn_batch_norm1d(hidden_dim)
    self$dropout2 <- nn_dropout(dropout)

    self$fc3 <- nn_linear(hidden_dim, 128)
    self$bn3 <- nn_batch_norm1d(128)
    self$dropout3 <- nn_dropout(dropout * 0.67)  # Slightly less dropout in final layer

    # Task-specific output heads
    self$existence_head <- nn_linear(128, 1)      # Binary: connection exists?
    self$strength_head <- nn_linear(128, 3)       # Multi-class: weak/medium/strong
    self$confidence_head <- nn_linear(128, 1)     # Regression: 1-5 confidence
    self$polarity_head <- nn_linear(128, 1)       # Binary: positive/negative
  },

  forward = function(x) {
    # Shared backbone
    x <- x %>%
      self$fc1() %>%
      self$bn1() %>%
      nnf_relu() %>%
      self$dropout1()

    x <- x %>%
      self$fc2() %>%
      self$bn2() %>%
      nnf_relu() %>%
      self$dropout2()

    features <- x %>%
      self$fc3() %>%
      self$bn3() %>%
      nnf_relu() %>%
      self$dropout3()

    # Multi-task outputs
    list(
      existence = self$existence_head(features),      # Raw logits for BCE loss
      strength = self$strength_head(features),        # Raw logits for CrossEntropy
      confidence = self$confidence_head(features),    # Regression output
      polarity = self$polarity_head(features)         # Raw logits for BCE loss
    )
  }
)

# ==============================================================================
# Loss Functions
# ==============================================================================

#' Weighted Multi-task Loss for Connection Prediction
#'
#' Combines losses from all prediction tasks with configurable weights.
#'
#' Loss components:
#' - Existence: Binary Cross-Entropy (weight=0.4)
#' - Strength: Cross-Entropy (weight=0.3)
#' - Confidence: MSE (weight=0.2)
#' - Polarity: Binary Cross-Entropy (weight=0.1)
#'
#' @param predictions List. Model outputs (existence, strength, confidence, polarity)
#' @param targets List. Ground truth labels (all torch tensors)
#' @param weights List. Task weights (default: c(0.4, 0.3, 0.2, 0.1))
#' @return torch_tensor. Scalar loss value
#' @export
multitask_loss <- function(predictions, targets,
                           weights = list(existence = 0.4,
                                         strength = 0.3,
                                         confidence = 0.2,
                                         polarity = 0.1)) {

  # 1. Connection existence loss (Binary Cross-Entropy)
  # Always compute for all examples
  existence_loss <- nnf_binary_cross_entropy_with_logits(
    predictions$existence,
    targets$existence
  )

  # 2. Strength loss (Cross-Entropy) - only for positive examples
  # Mask where connection exists (existence == 1)
  strength_mask <- (targets$existence$squeeze() == 1)
  n_positive <- strength_mask$sum()$item()

  if (n_positive > 0) {
    strength_loss <- nnf_cross_entropy(
      predictions$strength[strength_mask, ],
      targets$strength[strength_mask]
    )
  } else {
    strength_loss <- torch_tensor(0.0, device = predictions$strength$device)
  }

  # 3. Confidence loss (MSE) - only for positive examples
  confidence_mask <- (targets$existence$squeeze() == 1)
  if (n_positive > 0) {
    confidence_loss <- nnf_mse_loss(
      predictions$confidence[confidence_mask],
      targets$confidence[confidence_mask]
    )
  } else {
    confidence_loss <- torch_tensor(0.0, device = predictions$confidence$device)
  }

  # 4. Polarity loss (Binary Cross-Entropy) - only for positive examples
  polarity_mask <- (targets$existence$squeeze() == 1)
  if (n_positive > 0) {
    polarity_loss <- nnf_binary_cross_entropy_with_logits(
      predictions$polarity[polarity_mask],
      targets$polarity[polarity_mask]
    )
  } else {
    polarity_loss <- torch_tensor(0.0, device = predictions$polarity$device)
  }

  # Weighted combination
  total_loss <- (
    weights$existence * existence_loss +
    weights$strength * strength_loss +
    weights$confidence * confidence_loss +
    weights$polarity * polarity_loss
  )

  return(total_loss)
}

# ==============================================================================
# Metrics Functions
# ==============================================================================

#' Calculate binary accuracy
#'
#' @param predictions torch_tensor. Logits from model
#' @param targets torch_tensor. Binary targets (0 or 1)
#' @return Numeric. Accuracy (0-1)
#' @export
binary_accuracy <- function(predictions, targets) {
  # Apply sigmoid to get probabilities, then threshold at 0.5
  preds <- (torch_sigmoid(predictions) > 0.5)$to(dtype = torch_float())
  correct <- (preds == targets)$sum()$item()
  total <- targets$numel()
  return(correct / total)
}

#' Calculate multi-class accuracy
#'
#' @param predictions torch_tensor. Logits from model (N x C)
#' @param targets torch_tensor. Class indices (N)
#' @return Numeric. Accuracy (0-1)
#' @export
multiclass_accuracy <- function(predictions, targets) {
  preds <- torch_argmax(predictions, dim = 2)
  correct <- (preds == targets)$sum()$item()
  total <- targets$numel()
  return(correct / total)
}

#' Calculate Mean Absolute Error for regression
#'
#' @param predictions torch_tensor. Predicted values
#' @param targets torch_tensor. True values
#' @return Numeric. MAE
#' @export
mean_absolute_error <- function(predictions, targets) {
  mae <- torch_abs(predictions - targets)$mean()$item()
  return(mae)
}

#' Calculate F1 score for binary classification
#'
#' @param predictions torch_tensor. Logits from model
#' @param targets torch_tensor. Binary targets (0 or 1)
#' @return Numeric. F1 score (0-1)
#' @export
f1_score <- function(predictions, targets) {
  preds <- (torch_sigmoid(predictions) > 0.5)$to(dtype = torch_float())

  # True positives, false positives, false negatives
  tp <- ((preds == 1) & (targets == 1))$sum()$item()
  fp <- ((preds == 1) & (targets == 0))$sum()$item()
  fn <- ((preds == 0) & (targets == 1))$sum()$item()

  if (tp == 0) return(0.0)

  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)

  f1 <- 2 * (precision * recall) / (precision + recall)
  return(f1)
}

#' Calculate all metrics for connection prediction
#'
#' @param predictions List. Model outputs (torch tensors)
#' @param targets List. Ground truth labels (torch tensors)
#' @return List. All metrics
#' @export
calculate_metrics <- function(predictions, targets) {
  # Existence metrics (all examples)
  existence_acc <- binary_accuracy(
    predictions$existence,
    targets$existence
  )

  existence_f1 <- f1_score(
    predictions$existence,
    targets$existence
  )

  # Strength metrics (only for positive examples)
  strength_mask <- (targets$existence$squeeze() == 1)
  n_positive <- strength_mask$sum()$item()

  strength_acc <- if (n_positive > 0) {
    multiclass_accuracy(
      predictions$strength[strength_mask, , drop = FALSE],
      targets$strength[strength_mask]
    )
  } else {
    NA
  }

  # Confidence metrics (only for positive examples)
  confidence_mae <- if (n_positive > 0) {
    mean_absolute_error(
      predictions$confidence[strength_mask],
      targets$confidence[strength_mask]
    )
  } else {
    NA
  }

  # Polarity metrics (only for positive examples)
  polarity_acc <- if (n_positive > 0) {
    binary_accuracy(
      predictions$polarity[strength_mask],
      targets$polarity[strength_mask]
    )
  } else {
    NA
  }

  return(list(
    existence_accuracy = existence_acc,
    existence_f1 = existence_f1,
    strength_accuracy = strength_acc,
    confidence_mae = confidence_mae,
    polarity_accuracy = polarity_acc
  ))
}

# ==============================================================================
# Model Summary
# ==============================================================================

#' Print model summary
#'
#' @param model torch nn_module. The model to summarize
#' @param input_dim Integer. Input dimension (for parameter counting)
#' @export
print_model_summary <- function(model, input_dim = 358) {
  cat("\n==============================================================\n")
  cat("  Connection Predictor Model Summary\n")
  cat("==============================================================\n\n")

  cat("Architecture:\n")
  cat(sprintf("  Input dimension: %d\n", input_dim))
  cat(sprintf("  Hidden dimension: %d\n", model$hidden_dim))
  cat(sprintf("  Dropout rate: %.2f\n", model$dropout_rate))
  cat("\n")

  cat("Layers:\n")
  cat("  Shared backbone:\n")
  cat("    - FC1: input_dim → hidden_dim (+ BatchNorm + ReLU + Dropout)\n")
  cat("    - FC2: hidden_dim → hidden_dim (+ BatchNorm + ReLU + Dropout)\n")
  cat("    - FC3: hidden_dim → 128 (+ BatchNorm + ReLU + Dropout)\n")
  cat("\n")
  cat("  Task-specific heads:\n")
  cat("    - Existence: 128 → 1 (binary classification)\n")
  cat("    - Strength: 128 → 3 (multi-class classification)\n")
  cat("    - Confidence: 128 → 1 (regression)\n")
  cat("    - Polarity: 128 → 1 (binary classification)\n")
  cat("\n")

  # Count parameters
  total_params <- 0
  trainable_params <- 0

  for (param in model$parameters) {
    n_params <- param$numel()
    total_params <- total_params + n_params
    if (param$requires_grad) {
      trainable_params <- trainable_params + n_params
    }
  }

  cat(sprintf("Total parameters: %s\n", format(total_params, big.mark = ",")))
  cat(sprintf("Trainable parameters: %s\n", format(trainable_params, big.mark = ",")))
  cat(sprintf("Model size: ~%.2f MB\n", total_params * 4 / 1024^2))
  cat("\n==============================================================\n")
}

# ==============================================================================
# Connection Predictor V2 (Phase 2 - With Context Embeddings)
# ==============================================================================

#' Enhanced Connection Predictor with Learned Context Embeddings (Phase 2)
#'
#' Phase 2 enhancements over base connection_predictor:
#' - Learned context embeddings (88 sparse → 36 dense dims)
#' - Graph structural features (+8 dims)
#' - Input dimension: 314 (vs 358 in Phase 1)
#'
#' Input structure:
#' - Element embeddings: 2×128 = 256 dims (unchanged)
#' - Type encodings: 2×7 = 14 dims (unchanged)
#' - Context indices: 3 lists (sea_idx, eco_idx, issue_idx) → 36 dims via embeddings
#' - Graph features: 8 dims (optional, zero-padded if unavailable)
#' Total: 256 + 14 + 36 + 8 = 314 dims
#'
#' @param elem_input_dim Integer. Combined element embedding + type dim (default 270 = 2×128 + 2×7)
#' @param graph_dim Integer. Graph feature dimension (default 8)
#' @param hidden_dim Integer. Hidden layer dimension (default 256)
#' @param dropout Numeric. Dropout rate (default 0.3)
#' @param use_embeddings Logical. If TRUE, uses ContextEmbeddings; if FALSE, expects full 314-dim input
#' @return torch nn_module
#' @export
connection_predictor_v2 <- nn_module(
  "ConnectionPredictorV2",

  initialize = function(elem_input_dim = 270,  # 2×128 + 2×7
                       graph_dim = 8,
                       hidden_dim = 256,
                       dropout = 0.3,
                       use_embeddings = TRUE) {

    # Store hyperparameters
    self$elem_input_dim <- elem_input_dim
    self$graph_dim <- graph_dim
    self$hidden_dim <- hidden_dim
    self$dropout_rate <- dropout
    self$use_embeddings <- use_embeddings

    # Context embeddings (Phase 2)
    if (use_embeddings) {
      self$context_embed <- context_embeddings(
        n_seas = 12,
        n_ecosystems = 25,
        n_issues = 51,
        embed_dim_sea = 8,
        embed_dim_eco = 12,
        embed_dim_issue = 16
      )
      context_dim <- 36  # 8 + 12 + 16
    } else {
      context_dim <- 36  # If not using embeddings, expect 36 dims directly
    }

    # Total input dimension
    self$input_dim <- elem_input_dim + context_dim + graph_dim  # 270 + 36 + 8 = 314

    # Shared backbone layers (same as Phase 1)
    self$fc1 <- nn_linear(self$input_dim, hidden_dim)
    self$bn1 <- nn_batch_norm1d(hidden_dim)
    self$dropout1 <- nn_dropout(dropout)

    self$fc2 <- nn_linear(hidden_dim, hidden_dim)
    self$bn2 <- nn_batch_norm1d(hidden_dim)
    self$dropout2 <- nn_dropout(dropout)

    self$fc3 <- nn_linear(hidden_dim, 128)
    self$bn3 <- nn_batch_norm1d(128)
    self$dropout3 <- nn_dropout(dropout * 0.67)

    # Task-specific output heads (same as Phase 1)
    self$existence_head <- nn_linear(128, 1)
    self$strength_head <- nn_linear(128, 3)
    self$confidence_head <- nn_linear(128, 1)
    self$polarity_head <- nn_linear(128, 1)
  },

  forward = function(elem_features, context_data, graph_features = NULL) {
    # elem_features: (batch, elem_input_dim) - element embeddings + types
    # context_data: If use_embeddings=TRUE, list(sea_idx, eco_idx, issue_idx)
    #               If use_embeddings=FALSE, tensor (batch, 36)
    # graph_features: (batch, graph_dim) - optional, zero-padded if NULL

    # Process context
    if (self$use_embeddings) {
      # Context data is list of indices
      context_vec <- self$context_embed(
        context_data$sea_idx,
        context_data$eco_idx,
        context_data$issue_idx
      )  # (batch, 36)
    } else {
      # Context data is already a tensor
      context_vec <- context_data
    }

    # Handle graph features (optional)
    if (is.null(graph_features)) {
      # Zero-pad if graph unavailable
      batch_size <- elem_features$size(1)
      graph_features <- torch_zeros(c(batch_size, self$graph_dim))
      if (elem_features$device$type != "cpu") {
        graph_features <- graph_features$to(device = elem_features$device)
      }
    }

    # Concatenate all inputs
    x <- torch_cat(list(elem_features, context_vec, graph_features), dim = 2)
    # x: (batch, 314)

    # Shared backbone (identical to Phase 1)
    x <- x %>%
      self$fc1() %>%
      self$bn1() %>%
      nnf_relu() %>%
      self$dropout1()

    x <- x %>%
      self$fc2() %>%
      self$bn2() %>%
      nnf_relu() %>%
      self$dropout2()

    features <- x %>%
      self$fc3() %>%
      self$bn3() %>%
      nnf_relu() %>%
      self$dropout3()

    # Multi-task outputs (identical to Phase 1)
    list(
      existence = self$existence_head(features),
      strength = self$strength_head(features),
      confidence = self$confidence_head(features),
      polarity = self$polarity_head(features)
    )
  }
)

# ==============================================================================
# GraphSAGE Encoder (Phase 3, v1.15.0)
# ==============================================================================
#
# Learnable graph neural network for connection prediction. Replaces the
# hand-engineered scalar graph features (centrality, shortest path,
# framework compliance) with a 2-layer GraphSAGE message-passing encoder.
#
# Operates per-context: given a context's element set and the connections
# already in the (partial) model, produces a 32-dim embedding for every
# node. For a candidate edge (s, t) the prediction head consumes
# [h_s; h_t; h_s * h_t] (96 dims), so direction and interaction are
# both captured.
#
# Why GraphSAGE rather than vanilla GCN:
#   1. Handles dynamic graphs at inference time (the user's model is
#      partially built when we predict; we don't have a fixed adjacency).
#   2. Mean aggregator + sampling tolerates the small graphs in this
#      domain better than the spectral GCN normalization.
#
# Input node features (135-dim):
#   - DAPSIWRM one-hot (7 dims)
#   - Element-name text embedding (128 dims; truncated/projected from
#     the existing sentence-transformer or vocabulary strategy)
# ==============================================================================

GRAPH_SAGE_NODE_DIM <- 135L  # 7 DAPSIWRM + 128 text-embedding
GRAPH_SAGE_HIDDEN  <- 64L
GRAPH_SAGE_OUTPUT  <- 32L

#' GraphSAGE Layer
#'
#' Single SAGE convolution: aggregates neighbour embeddings, concatenates
#' with the node's own embedding, projects through a linear layer + ReLU.
#'
#' @param in_dim Integer. Input embedding dimension.
#' @param out_dim Integer. Output embedding dimension.
#' @return torch nn_module
graph_sage_layer <- nn_module(
  "GraphSageLayer",

  initialize = function(in_dim, out_dim) {
    self$linear <- nn_linear(in_dim * 2, out_dim)
  },

  forward = function(node_features, adj) {
    # node_features: (N, in_dim)
    # adj: (N, N) row-normalized adjacency matrix as torch tensor.
    #      Self-loops should already be included by the caller.
    neighbor_agg <- torch_matmul(adj, node_features)               # (N, in_dim)
    combined     <- torch_cat(list(node_features, neighbor_agg), dim = 2L)  # (N, 2*in_dim)
    self$linear(combined)
  }
)

#' GraphSAGE Encoder for SES Connection Prediction
#'
#' 2-layer encoder with edge dropout for regularization. The caller
#' assembles the adjacency matrix from the context's current connection
#' set; this module is agnostic to context size.
#'
#' @param node_dim Integer. Input node feature dim (default 135).
#' @param hidden_dim Integer. Hidden layer dim (default 64).
#' @param output_dim Integer. Output embedding dim (default 32).
#' @param dropout Numeric. Dropout rate on node features (default 0.5).
#' @param edge_dropout Numeric. Edge dropout during training (default 0.2).
#' @return torch nn_module
#' @export
graph_sage_encoder <- nn_module(
  "GraphSageEncoder",

  initialize = function(node_dim = GRAPH_SAGE_NODE_DIM,
                        hidden_dim = GRAPH_SAGE_HIDDEN,
                        output_dim = GRAPH_SAGE_OUTPUT,
                        dropout = 0.5,
                        edge_dropout = 0.2) {
    self$layer1 <- graph_sage_layer(node_dim, hidden_dim)
    self$layer2 <- graph_sage_layer(hidden_dim, output_dim)
    self$dropout_rate <- dropout
    self$edge_dropout_rate <- edge_dropout
    self$dropout1 <- nn_dropout(dropout)
    self$dropout2 <- nn_dropout(dropout)
  },

  forward = function(node_features, adj, training_mode = TRUE) {
    # Edge dropout: randomly mask a fraction of off-diagonal entries
    # during training. Identical mask applied symmetrically.
    if (training_mode && self$edge_dropout_rate > 0) {
      n <- adj$shape[[1]]
      eye <- torch_eye(n, dtype = adj$dtype, device = adj$device)
      mask <- (torch_rand_like(adj) > self$edge_dropout_rate)$to(dtype = adj$dtype)
      mask <- mask * (1 - eye) + eye  # always keep self-loops
      adj_dropped <- adj * mask
      # Re-normalize row sums to keep adjacency a valid mean aggregator
      row_sums <- adj_dropped$sum(dim = 2L, keepdim = TRUE)$clamp(min = 1e-6)
      adj <- adj_dropped / row_sums
    }

    h <- self$layer1(node_features, adj) %>% nnf_relu() %>% self$dropout1()
    h <- self$layer2(h, adj) %>% nnf_relu() %>% self$dropout2()
    h  # (N, output_dim)
  }
)

#' Connection Predictor with GraphSAGE Encoder
#'
#' Multi-task head consuming pairwise node embeddings from GraphSAGE.
#' Inputs at forward() are arranged per-batch where each example carries
#' its source/target node indices into a per-context graph + the graph's
#' node features and adjacency.
#'
#' Forward signature is intentionally explicit (no kwargs) so the model
#' can be saved and reloaded across torch versions.
#'
#' Inputs at predict-time:
#'   node_features: (N, node_dim) for this context
#'   adj:           (N, N) row-normalized adjacency for this context
#'   src_idx:       (B,) long, source node index per example
#'   tgt_idx:       (B,) long, target node index per example
#'
#' @param node_dim Integer. Input node feature dim (default 135).
#' @param hidden_dim Integer. Encoder hidden dim (default 64).
#' @param emb_dim Integer. Node embedding output dim (default 32).
#' @param head_dim Integer. MLP hidden dim before output heads (default 128).
#' @param dropout Numeric. Dropout rate (default 0.5).
#' @return torch nn_module
#' @export
connection_predictor_gnn <- nn_module(
  "ConnectionPredictorGNN",

  initialize = function(node_dim = GRAPH_SAGE_NODE_DIM,
                        hidden_dim = GRAPH_SAGE_HIDDEN,
                        emb_dim = GRAPH_SAGE_OUTPUT,
                        head_dim = 128L,
                        dropout = 0.5) {
    self$encoder <- graph_sage_encoder(
      node_dim = node_dim,
      hidden_dim = hidden_dim,
      output_dim = emb_dim,
      dropout = dropout
    )
    # Pairwise input is [h_s; h_t; h_s * h_t] = 3 * emb_dim
    pair_dim <- 3L * emb_dim
    self$mlp1 <- nn_linear(pair_dim, head_dim)
    self$bn1  <- nn_batch_norm1d(head_dim)
    self$drop1 <- nn_dropout(dropout)

    self$existence_head  <- nn_linear(head_dim, 1L)
    self$strength_head   <- nn_linear(head_dim, 3L)
    self$confidence_head <- nn_linear(head_dim, 1L)
    self$polarity_head   <- nn_linear(head_dim, 1L)
  },

  forward = function(node_features, adj, src_idx, tgt_idx) {
    # Run the GNN encoder over the entire context graph
    h <- self$encoder(node_features, adj, training_mode = self$training)
    # Gather source / target embeddings
    h_s <- h$index_select(1L, src_idx)  # (B, emb_dim)
    h_t <- h$index_select(1L, tgt_idx)  # (B, emb_dim)
    pair <- torch_cat(list(h_s, h_t, h_s * h_t), dim = 2L)  # (B, 3*emb_dim)

    features <- pair %>%
      self$mlp1() %>%
      self$bn1() %>%
      nnf_relu() %>%
      self$drop1()

    list(
      existence  = self$existence_head(features),
      strength   = self$strength_head(features),
      confidence = self$confidence_head(features),
      polarity   = self$polarity_head(features)
    )
  }
)

# ==============================================================================
# Adjacency helper for the GNN training / inference pipeline
# ==============================================================================

#' Build row-normalized adjacency with self-loops
#'
#' @param edge_list Two-column integer matrix (1-indexed) of (source, target) pairs,
#'   or a 0-row matrix when the graph has no edges yet.
#' @param n_nodes Integer. Total number of nodes in the context.
#' @param directed Logical. If TRUE the adjacency is directed (default TRUE,
#'   matching the DAPSIWRM framework which is sequential).
#' @return torch_tensor of shape (n_nodes, n_nodes), float, row-normalized.
#' @export
build_normalized_adjacency <- function(edge_list, n_nodes, directed = TRUE) {
  adj_mat <- matrix(0, n_nodes, n_nodes)
  if (!is.null(edge_list) && nrow(edge_list) > 0L) {
    for (i in seq_len(nrow(edge_list))) {
      s <- edge_list[i, 1L]
      t <- edge_list[i, 2L]
      if (s >= 1L && s <= n_nodes && t >= 1L && t <= n_nodes) {
        adj_mat[s, t] <- 1
        if (!directed) adj_mat[t, s] <- 1
      }
    }
  }
  # Self-loops
  diag(adj_mat) <- 1
  # Row-normalize (mean aggregator)
  row_sums <- rowSums(adj_mat)
  row_sums[row_sums == 0] <- 1  # guard
  adj_mat <- adj_mat / row_sums
  torch_tensor(adj_mat, dtype = torch_float())
}

# ==============================================================================
# Load message
# ==============================================================================

debug_log("ML Models loaded successfully", "ML_MODELS")
debug_log("connection_predictor: Multi-task neural network (Phase 1, 358-dim)", "ML_MODELS")
if (exists("context_embeddings")) {
  debug_log("connection_predictor_v2: Enhanced with context embeddings (Phase 2, 314-dim)", "ML_MODELS")
}
debug_log("connection_predictor_gnn: GraphSAGE encoder + multi-task heads (Phase 3)", "ML_MODELS")
debug_log("multitask_loss: Weighted loss function", "ML_MODELS")
debug_log("Metrics: accuracy, F1, MAE", "ML_MODELS")
