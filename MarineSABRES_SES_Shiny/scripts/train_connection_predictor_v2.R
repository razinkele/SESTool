# ==============================================================================
# Train Connection Predictor Model V2 (Phase 2)
# ==============================================================================
# Trains the Phase 2 enhanced connection predictor with:
# - Context embeddings (36 dense dims vs 88 sparse one-hot)
# - Graph structural features (8 dims)
# - Total input: 314 dims (270 elem + 36 context + 8 graph)
#
# Output:
# - models/connection_predictor_v2_graph_aware.pt: Best Phase 2 model
# - models/connection_predictor_v2_final.pt: Final model
# - models/training_history_v2.rds: Training metrics history
# ==============================================================================

library(torch)
library(dplyr)

# Source Phase 2 modules
source("functions/ml_feature_engineering.R")
source("functions/ml_context_embeddings.R")
source("functions/ml_models.R")

# Optionally load graph features module
if (file.exists("functions/ml_graph_features.R")) {
  source("functions/ml_graph_features.R")
  cat("✓ Graph features module loaded\n")
}

set.seed(42)
torch_manual_seed(42)

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  # Data
  data_file = "data/ml_training_data.rds",
  embedding_dim = 128,

  # Phase 2: Context embeddings replace 88-dim one-hot
  use_context_embeddings = TRUE,
  context_dim = 36,  # 8 (sea) + 12 (ecosystem) + 16 (issue)

  # Phase 2: Graph features
  use_graph_features = TRUE,
  graph_dim = 8,

  # Total feature dimension: 270 (elem) + 36 (context) + 8 (graph) = 314
  feature_dim = 314,  # Down from 358 in Phase 1
  elem_feature_dim = 270,  # 2*128 (embeddings) + 2*7 (types)

  # Model
  hidden_dim = 256,
  dropout = 0.3,

  # Training
  batch_size = 32,
  learning_rate = 0.001,
  max_epochs = 100,
  patience = 10,  # Early stopping patience

  # Output
  models_dir = "models",
  checkpoint_freq = 5,  # Save checkpoint every N epochs

  # Phase 2 specific
  model_version = "v2"
)

# Create models directory
if (!dir.exists(CONFIG$models_dir)) {
  dir.create(CONFIG$models_dir, recursive = TRUE)
  cat(sprintf("Created directory: %s\n", CONFIG$models_dir))
}

cat("\n==================================================================\n")
cat("  PHASE 2: Training Enhanced Connection Predictor\n")
cat("==================================================================\n\n")
cat("Enhancements:\n")
cat("  ✓ Context Embeddings: 88 sparse → 36 dense dims\n")
cat("  ✓ Graph Features: +8 structural dims\n")
cat("  ✓ Total Input: 314 dims (vs 358 in Phase 1)\n")
cat("  ✓ Target Accuracy: 87-90%\n\n")

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Prepare targets for training
#'
#' Convert connection properties to torch tensors
#'
#' @param data Dataframe with connection data
#' @return List of torch tensors
prepare_targets <- function(data) {
  # Connection existence (0 or 1)
  existence <- torch_tensor(as.numeric(data$connection_exists), dtype = torch_float())$view(c(-1, 1))

  # Strength: weak=1, medium=2, strong=3
  # For negative examples (no connection), default to 2 (medium)
  strength_map <- c("weak" = 1L, "medium" = 2L, "strong" = 3L)
  strength_values <- sapply(seq_len(nrow(data)), function(i) {
    s <- data$strength[i]
    if (is.na(s) || s == "" || is.null(s)) {
      return(2L)  # Default to medium for negative examples
    }
    val <- strength_map[tolower(as.character(s))]
    if (is.na(val)) return(2L)
    as.integer(val)
  })
  strength <- torch_tensor(strength_values, dtype = torch_long())

  # Confidence: 1-5 scale
  # For negative examples, default to 3
  confidence_values <- sapply(seq_len(nrow(data)), function(i) {
    c_val <- data$confidence[i]
    if (is.na(c_val) || is.null(c_val)) {
      return(3.0)
    }
    as.numeric(c_val)
  })
  confidence <- torch_tensor(confidence_values, dtype = torch_float())$view(c(-1, 1))

  # Polarity: + → 1, - → 0
  # For negative examples, default to 1 (positive)
  polarity_values <- sapply(seq_len(nrow(data)), function(i) {
    p <- data$polarity[i]
    if (is.na(p) || p == "" || is.null(p)) {
      return(1.0)  # Default to positive
    }
    if (as.character(p) == "+") 1.0 else 0.0
  })
  polarity <- torch_tensor(polarity_values, dtype = torch_float())$view(c(-1, 1))

  return(list(
    existence = existence,
    strength = strength,
    confidence = confidence,
    polarity = polarity
  ))
}

#' Create Phase 2 feature matrix with context embeddings and graph features
#'
#' @param data Training data dataframe
#' @param graph_features Matrix of graph features (optional)
#' @param embedding_dim Element embedding dimension
#' @return Feature matrix (n_examples x 314)
create_feature_matrix_v2 <- function(data, graph_features = NULL, embedding_dim = 128) {
  n_examples <- nrow(data)

  # === Part 1: Element Features (270 dims) ===
  # Create element embeddings using existing function
  elem_features <- create_element_features(
    source_names = data$source_name,
    target_names = data$target_name,
    source_types = data$source_type,
    target_types = data$target_type,
    embedding_dim = embedding_dim
  )

  # === Part 2: Context Index Preparation (for embeddings) ===
  # Convert context to indices for embedding lookup
  context_indices <- lapply(1:n_examples, function(i) {
    prepare_context_indices(
      regional_sea = data$regional_sea[i],
      ecosystem_types = data$ecosystem_types[i],
      main_issues = data$main_issues[i]
    )
  })

  # Store indices for later (will be used in forward pass via embedding layer)
  # For now, create placeholder zeros (embeddings happen in model forward pass)
  context_placeholder <- matrix(0, nrow = n_examples, ncol = CONFIG$context_dim)

  # === Part 3: Graph Features (8 dims) ===
  if (!is.null(graph_features) && CONFIG$use_graph_features) {
    # Use provided graph features
    if (nrow(graph_features) != n_examples) {
      warning(sprintf("Graph features size mismatch: expected %d, got %d. Using zeros.",
                      n_examples, nrow(graph_features)))
      graph_feat <- matrix(0, nrow = n_examples, ncol = CONFIG$graph_dim)
    } else {
      graph_feat <- graph_features
    }
  } else {
    # No graph features: use zeros (graceful degradation)
    graph_feat <- matrix(0, nrow = n_examples, ncol = CONFIG$graph_dim)
  }

  # === Combine Features ===
  # NOTE: Context embeddings will be computed in model forward pass
  # Here we concatenate: elem (270) + context_placeholder (36) + graph (8) = 314
  features <- cbind(elem_features, context_placeholder, graph_feat)

  # Attach context indices as attribute for use in training
  attr(features, "context_indices") <- context_indices

  return(features)
}

#' Create torch dataset for Phase 2
#' Note: We store context as scalars (first value only) to avoid variable-length issues
ses_dataset_v2 <- dataset(
  name = "SESDatasetV2",

  initialize = function(elem_features, context_sea, context_eco, context_issue, graph_features, targets) {
    self$elem_features <- elem_features
    self$context_sea <- context_sea  # Tensor of sea indices
    self$context_eco <- context_eco  # Tensor of eco indices (first value)
    self$context_issue <- context_issue  # Tensor of issue indices (first value)
    self$graph_features <- graph_features
    self$targets <- targets
    self$n <- nrow(elem_features)
  },

  .getitem = function(index) {
    list(
      elem_features = self$elem_features[index, ],
      sea_idx = self$context_sea[index],
      eco_idx = self$context_eco[index],
      issue_idx = self$context_issue[index],
      graph_features = self$graph_features[index, ],
      y = list(
        existence = self$targets$existence[index, ],
        strength = self$targets$strength[index],
        confidence = self$targets$confidence[index, ],
        polarity = self$targets$polarity[index, ]
      )
    )
  },

  .length = function() {
    self$n
  }
)

# ==============================================================================
# Load and Prepare Data
# ==============================================================================

cat("Loading training data...\n")
training_data <- readRDS(CONFIG$data_file)

cat(sprintf("  Train set: %d examples\n", nrow(training_data$train)))
cat(sprintf("  Validation set: %d examples\n", nrow(training_data$validation)))
cat(sprintf("  Test set: %d examples\n", nrow(training_data$test)))

# Check for Phase 2 graph features
has_graph_features <- !is.null(training_data$train_graph_features)
if (has_graph_features) {
  cat(sprintf("  ✓ Graph features available: %d dims\n", ncol(training_data$train_graph_features)))
} else {
  cat("  ℹ No graph features found. Using zero-padding.\n")
}
cat("\n")

# Create element feature matrices (270 dims: 2x128 embeddings + 2x7 types)
# We'll extract just the element portion (first 270 dims) from create_feature_vector
cat("Creating element features...\n")

n_train <- nrow(training_data$train)
n_val <- nrow(training_data$validation)

# Create element features manually (embeddings + types only, no context)
train_elem_features <- matrix(0, nrow = n_train, ncol = CONFIG$elem_feature_dim)
for (i in 1:n_train) {
  # Create embeddings
  source_emb <- create_element_embedding(training_data$train$source_name[i], CONFIG$embedding_dim)
  target_emb <- create_element_embedding(training_data$train$target_name[i], CONFIG$embedding_dim)

  # Encode types
  source_type <- encode_dapsiwrm_type(training_data$train$source_type[i])
  target_type <- encode_dapsiwrm_type(training_data$train$target_type[i])

  # Combine: 128 + 128 + 7 + 7 = 270
  train_elem_features[i, ] <- c(source_emb, target_emb, source_type, target_type)
}

val_elem_features <- matrix(0, nrow = n_val, ncol = CONFIG$elem_feature_dim)
for (i in 1:n_val) {
  source_emb <- create_element_embedding(training_data$validation$source_name[i], CONFIG$embedding_dim)
  target_emb <- create_element_embedding(training_data$validation$target_name[i], CONFIG$embedding_dim)
  source_type <- encode_dapsiwrm_type(training_data$validation$source_type[i])
  target_type <- encode_dapsiwrm_type(training_data$validation$target_type[i])
  val_elem_features[i, ] <- c(source_emb, target_emb, source_type, target_type)
}

cat(sprintf("  Element features: %d dims\n", ncol(train_elem_features)))
cat("\n")

# Prepare context indices for embedding lookup (extract scalars upfront)
cat("Preparing context indices for embeddings...\n")

# Train context
train_sea <- sapply(1:n_train, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$train$regional_sea[i],
    ecosystem_types = training_data$train$ecosystem_types[i],
    main_issues = training_data$train$main_issues[i]
  )
  as.numeric(idx_data$sea_idx)[1]
})

train_eco <- sapply(1:n_train, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$train$regional_sea[i],
    ecosystem_types = training_data$train$ecosystem_types[i],
    main_issues = training_data$train$main_issues[i]
  )
  as.numeric(idx_data$eco_idx)[1]
})

train_issue <- sapply(1:n_train, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$train$regional_sea[i],
    ecosystem_types = training_data$train$ecosystem_types[i],
    main_issues = training_data$train$main_issues[i]
  )
  as.numeric(idx_data$issue_idx)[1]
})

# Validation context
val_sea <- sapply(1:n_val, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$validation$regional_sea[i],
    ecosystem_types = training_data$validation$ecosystem_types[i],
    main_issues = training_data$validation$main_issues[i]
  )
  as.numeric(idx_data$sea_idx)[1]
})

val_eco <- sapply(1:n_val, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$validation$regional_sea[i],
    ecosystem_types = training_data$validation$ecosystem_types[i],
    main_issues = training_data$validation$main_issues[i]
  )
  as.numeric(idx_data$eco_idx)[1]
})

val_issue <- sapply(1:n_val, function(i) {
  idx_data <- prepare_context_indices(
    regional_sea = training_data$validation$regional_sea[i],
    ecosystem_types = training_data$validation$ecosystem_types[i],
    main_issues = training_data$validation$main_issues[i]
  )
  as.numeric(idx_data$issue_idx)[1]
})

# Convert to torch tensors
train_sea_tensor <- torch_tensor(train_sea, dtype = torch_long())
train_eco_tensor <- torch_tensor(train_eco, dtype = torch_long())
train_issue_tensor <- torch_tensor(train_issue, dtype = torch_long())
val_sea_tensor <- torch_tensor(val_sea, dtype = torch_long())
val_eco_tensor <- torch_tensor(val_eco, dtype = torch_long())
val_issue_tensor <- torch_tensor(val_issue, dtype = torch_long())

cat("  ✓ Context indices prepared\n\n")

# Load graph features
if (has_graph_features) {
  train_graph_features <- training_data$train_graph_features
  val_graph_features <- training_data$val_graph_features
} else {
  train_graph_features <- matrix(0, nrow = nrow(training_data$train), ncol = CONFIG$graph_dim)
  val_graph_features <- matrix(0, nrow = nrow(training_data$validation), ncol = CONFIG$graph_dim)
}

# Prepare targets
cat("Preparing targets...\n")
train_targets <- prepare_targets(training_data$train)
val_targets <- prepare_targets(training_data$validation)
cat("  ✓ Targets prepared\n\n")

# Convert to torch tensors
train_elem_tensor <- torch_tensor(train_elem_features, dtype = torch_float())
val_elem_tensor <- torch_tensor(val_elem_features, dtype = torch_float())
train_graph_tensor <- torch_tensor(train_graph_features, dtype = torch_float())
val_graph_tensor <- torch_tensor(val_graph_features, dtype = torch_float())

# Create Phase 2 datasets
train_ds <- ses_dataset_v2(
  train_elem_tensor, train_sea_tensor, train_eco_tensor, train_issue_tensor,
  train_graph_tensor, train_targets
)
val_ds <- ses_dataset_v2(
  val_elem_tensor, val_sea_tensor, val_eco_tensor, val_issue_tensor,
  val_graph_tensor, val_targets
)

# Create dataloaders
train_dl <- dataloader(train_ds, batch_size = CONFIG$batch_size, shuffle = TRUE)
val_dl <- dataloader(val_ds, batch_size = CONFIG$batch_size, shuffle = FALSE)

cat(sprintf("Created dataloaders (batch size: %d)\n", CONFIG$batch_size))
cat(sprintf("  Train batches: %d\n", length(train_dl)))
cat(sprintf("  Validation batches: %d\n\n", length(val_dl)))

# ==============================================================================
# Initialize Phase 2 Model
# ==============================================================================

cat("Initializing Phase 2 model...\n")
model <- connection_predictor_v2(
  elem_input_dim = CONFIG$elem_feature_dim,
  graph_dim = CONFIG$graph_dim,
  hidden_dim = CONFIG$hidden_dim,
  dropout = CONFIG$dropout,
  use_embeddings = CONFIG$use_context_embeddings
)

print_model_summary(model)

optimizer <- optim_adam(model$parameters, lr = CONFIG$learning_rate)

cat(sprintf("Optimizer: Adam (lr = %.4f)\n\n", CONFIG$learning_rate))

# ==============================================================================
# Training Loop
# ==============================================================================

cat("Starting training...\n")
cat(sprintf("  Max epochs: %d\n", CONFIG$max_epochs))
cat(sprintf("  Early stopping patience: %d\n\n", CONFIG$patience))

history <- list(
  train_loss = numeric(),
  val_loss = numeric(),
  train_metrics = list(),
  val_metrics = list()
)

best_val_loss <- Inf
patience_counter <- 0

for (epoch in 1:CONFIG$max_epochs) {
  cat(sprintf("Epoch %d/%d\n", epoch, CONFIG$max_epochs))

  # ============================================================================
  # Training Phase
  # ============================================================================

  model$train()
  train_loss_sum <- 0
  train_batches <- 0

  coro::loop(for (batch in train_dl) {
    # Prepare context data (indices should be shape (batch,) not (batch, 1))
    batch_size_actual <- batch$sea_idx$size(1)

    context_data <- list(
      sea_idx = batch$sea_idx,  # Already shape (batch,)
      eco_idx = batch$eco_idx,  # Already shape (batch,)
      issue_idx = batch$issue_idx  # Already shape (batch,)
    )

    # Forward pass
    predictions <- model(batch$elem_features, context_data, batch$graph_features)

    # Calculate loss
    loss <- multitask_loss(predictions, batch$y)

    # Backward pass
    optimizer$zero_grad()
    loss$backward()
    optimizer$step()

    train_loss_sum <- train_loss_sum + loss$item()
    train_batches <- train_batches + 1
  })

  train_loss <- train_loss_sum / train_batches

  # ============================================================================
  # Validation Phase
  # ============================================================================

  model$eval()
  val_loss_sum <- 0
  val_batches <- 0
  all_val_predictions <- list()
  all_val_targets <- list()

  with_no_grad({
    coro::loop(for (batch in val_dl) {
      # Prepare context data (indices should be shape (batch,) not (batch, 1))
      batch_size_actual <- batch$sea_idx$size(1)

      context_data <- list(
        sea_idx = batch$sea_idx,  # Already shape (batch,)
        eco_idx = batch$eco_idx,  # Already shape (batch,)
        issue_idx = batch$issue_idx  # Already shape (batch,)
      )

      predictions <- model(batch$elem_features, context_data, batch$graph_features)
      loss <- multitask_loss(predictions, batch$y)

      val_loss_sum <- val_loss_sum + loss$item()
      val_batches <- val_batches + 1

      # Store predictions for metrics
      all_val_predictions[[val_batches]] <- predictions
      all_val_targets[[val_batches]] <- batch$y
    })
  })

  val_loss <- val_loss_sum / val_batches

  # Calculate validation metrics (on last batch)
  val_metrics <- calculate_metrics(
    all_val_predictions[[val_batches]],
    all_val_targets[[val_batches]]
  )

  # Store history
  history$train_loss <- c(history$train_loss, train_loss)
  history$val_loss <- c(history$val_loss, val_loss)
  history$train_metrics[[epoch]] <- list()
  history$val_metrics[[epoch]] <- val_metrics

  # Print progress
  cat(sprintf("  Train Loss: %.4f | Val Loss: %.4f\n", train_loss, val_loss))
  cat(sprintf("  Val Metrics - Existence Acc: %.3f | F1: %.3f | Strength Acc: %.3f\n",
              val_metrics$existence_accuracy,
              val_metrics$existence_f1,
              val_metrics$strength_accuracy %||% 0))

  # ============================================================================
  # Early Stopping & Checkpointing
  # ============================================================================

  # Save best model
  if (val_loss < best_val_loss) {
    best_val_loss <- val_loss
    patience_counter <- 0
    torch_save(model, file.path(CONFIG$models_dir, "connection_predictor_v2_graph_aware.pt"))
    cat("  ✓ Saved best Phase 2 model checkpoint\n")
  } else {
    patience_counter <- patience_counter + 1
    cat(sprintf("  Patience: %d/%d\n", patience_counter, CONFIG$patience))
  }

  # Periodic checkpoints
  if (epoch %% CONFIG$checkpoint_freq == 0) {
    checkpoint_file <- file.path(CONFIG$models_dir, sprintf("checkpoint_v2_epoch_%03d.pt", epoch))
    torch_save(model, checkpoint_file)
    cat(sprintf("  ✓ Saved checkpoint: %s\n", basename(checkpoint_file)))
  }

  # Early stopping
  if (patience_counter >= CONFIG$patience) {
    cat(sprintf("\nEarly stopping triggered at epoch %d\n", epoch))
    break
  }

  cat("\n")
}

# ==============================================================================
# Save Final Model and History
# ==============================================================================

cat("Training complete!\n\n")

# Save final model
torch_save(model, file.path(CONFIG$models_dir, "connection_predictor_v2_final.pt"))
cat(sprintf("✓ Saved final Phase 2 model: %s\n",
            file.path(CONFIG$models_dir, "connection_predictor_v2_final.pt")))

# Save training history
saveRDS(history, file.path(CONFIG$models_dir, "training_history_v2.rds"))
cat(sprintf("✓ Saved training history: %s\n",
            file.path(CONFIG$models_dir, "training_history_v2.rds")))

# ==============================================================================
# Training Summary
# ==============================================================================

cat("\n==================================================================\n")
cat("  PHASE 2 Training Summary\n")
cat("==================================================================\n")
cat(sprintf("Total epochs: %d\n", length(history$train_loss)))
cat(sprintf("Best validation loss: %.4f\n", best_val_loss))
cat(sprintf("Final train loss: %.4f\n", tail(history$train_loss, 1)))
cat(sprintf("Final val loss: %.4f\n", tail(history$val_loss, 1)))

# Get best epoch metrics
best_epoch <- which.min(history$val_loss)
best_metrics <- history$val_metrics[[best_epoch]]

cat("\nBest epoch metrics:\n")
cat(sprintf("  Existence Accuracy: %.3f%%\n", best_metrics$existence_accuracy * 100))
cat(sprintf("  Existence F1: %.3f\n", best_metrics$existence_f1))
cat(sprintf("  Strength Accuracy: %.3f%%\n", (best_metrics$strength_accuracy %||% 0) * 100))
cat(sprintf("  Confidence MAE: %.3f\n", best_metrics$confidence_mae %||% 0))
cat(sprintf("  Polarity Accuracy: %.3f%%\n", (best_metrics$polarity_accuracy %||% 0) * 100))

cat("\n==================================================================\n")
cat("✓ Phase 2 Training Complete!\n")
cat("==================================================================\n\n")

cat("Next steps:\n")
cat("  1. Evaluate on test set (target: 87-90% accuracy)\n")
cat("  2. Compare with Phase 1 baseline (82.6%)\n")
cat("  3. Update inference module for Phase 2 support\n\n")
