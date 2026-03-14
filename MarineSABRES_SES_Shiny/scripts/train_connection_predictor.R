# ==============================================================================
# Train Connection Predictor Model
# ==============================================================================
# Trains the deep learning connection predictor on DA template data
#
# Output:
# - models/connection_predictor_best.pt: Best model checkpoint
# - models/connection_predictor_final.pt: Final model
# - models/training_history.rds: Training metrics history
# ==============================================================================

library(torch)
library(dplyr)
source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")

set.seed(42)
torch_manual_seed(42)

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  # Data
  data_file = "data/ml_training_data.rds",
  embedding_dim = 128,
  feature_dim = 358,

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
  checkpoint_freq = 5  # Save checkpoint every N epochs
)

# Create models directory
if (!dir.exists(CONFIG$models_dir)) {
  dir.create(CONFIG$models_dir, recursive = TRUE)
  cat(sprintf("Created directory: %s\n", CONFIG$models_dir))
}

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

#' Create torch dataset
ses_dataset <- dataset(
  name = "SESDataset",

  initialize = function(features, targets) {
    self$features <- features
    self$targets <- targets
    self$n <- nrow(features)
  },

  .getitem = function(index) {
    list(
      x = self$features[index, ],
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

cat("\n==============================================================\n")
cat("  Training Connection Predictor Model\n")
cat("==============================================================\n\n")

cat("Loading training data...\n")
training_data <- readRDS(CONFIG$data_file)

cat(sprintf("  Train set: %d examples\n", nrow(training_data$train)))
cat(sprintf("  Validation set: %d examples\n", nrow(training_data$validation)))
cat(sprintf("  Test set: %d examples\n", nrow(training_data$test)))
cat("\n")

# Create feature matrices
cat("Creating feature matrices...\n")
train_features <- create_feature_matrix(training_data$train, CONFIG$embedding_dim)
val_features <- create_feature_matrix(training_data$validation, CONFIG$embedding_dim)

cat(sprintf("  Feature dimension: %d\n", ncol(train_features)))
cat("\n")

# Prepare targets
cat("Preparing targets...\n")
train_targets <- prepare_targets(training_data$train)
val_targets <- prepare_targets(training_data$validation)
cat("  ✓ Targets prepared\n\n")

# Create torch datasets
train_features_tensor <- torch_tensor(train_features, dtype = torch_float())
val_features_tensor <- torch_tensor(val_features, dtype = torch_float())

train_ds <- ses_dataset(train_features_tensor, train_targets)
val_ds <- ses_dataset(val_features_tensor, val_targets)

# Create dataloaders
train_dl <- dataloader(train_ds, batch_size = CONFIG$batch_size, shuffle = TRUE)
val_dl <- dataloader(val_ds, batch_size = CONFIG$batch_size, shuffle = FALSE)

cat(sprintf("Created dataloaders (batch size: %d)\n", CONFIG$batch_size))
cat(sprintf("  Train batches: %d\n", length(train_dl)))
cat(sprintf("  Validation batches: %d\n\n", length(val_dl)))

# ==============================================================================
# Initialize Model and Optimizer
# ==============================================================================

cat("Initializing model...\n")
model <- connection_predictor(
  input_dim = CONFIG$feature_dim,
  hidden_dim = CONFIG$hidden_dim,
  dropout = CONFIG$dropout
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
    # Forward pass
    predictions <- model(batch$x)

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
      predictions <- model(batch$x)
      loss <- multitask_loss(predictions, batch$y)

      val_loss_sum <- val_loss_sum + loss$item()
      val_batches <- val_batches + 1

      # Store predictions for metrics
      all_val_predictions[[val_batches]] <- predictions
      all_val_targets[[val_batches]] <- batch$y
    })
  })

  val_loss <- val_loss_sum / val_batches

  # Calculate validation metrics (on last batch for simplicity)
  val_metrics <- calculate_metrics(
    all_val_predictions[[val_batches]],
    all_val_targets[[val_batches]]
  )

  # Store history
  history$train_loss <- c(history$train_loss, train_loss)
  history$val_loss <- c(history$val_loss, val_loss)
  history$train_metrics[[epoch]] <- list()  # Would need to aggregate across batches
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
    torch_save(model, file.path(CONFIG$models_dir, "connection_predictor_best.pt"))
    cat("  ✓ Saved best model checkpoint\n")
  } else {
    patience_counter <- patience_counter + 1
    cat(sprintf("  Patience: %d/%d\n", patience_counter, CONFIG$patience))
  }

  # Periodic checkpoints
  if (epoch %% CONFIG$checkpoint_freq == 0) {
    checkpoint_file <- file.path(CONFIG$models_dir, sprintf("checkpoint_epoch_%03d.pt", epoch))
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
torch_save(model, file.path(CONFIG$models_dir, "connection_predictor_final.pt"))
cat(sprintf("✓ Saved final model: %s\n", file.path(CONFIG$models_dir, "connection_predictor_final.pt")))

# Save training history
saveRDS(history, file.path(CONFIG$models_dir, "training_history.rds"))
cat(sprintf("✓ Saved training history: %s\n", file.path(CONFIG$models_dir, "training_history.rds")))

# ==============================================================================
# Training Summary
# ==============================================================================

cat("\n==============================================================\n")
cat("  Training Summary\n")
cat("==============================================================\n")
cat(sprintf("Total epochs: %d\n", length(history$train_loss)))
cat(sprintf("Best validation loss: %.4f\n", best_val_loss))
cat(sprintf("Final train loss: %.4f\n", tail(history$train_loss, 1)))
cat(sprintf("Final val loss: %.4f\n", tail(history$val_loss, 1)))
cat("\n")

# Get best epoch metrics
best_epoch <- which.min(history$val_loss)
best_metrics <- history$val_metrics[[best_epoch]]
cat(sprintf("Best epoch: %d\n", best_epoch))
cat(sprintf("  Existence Accuracy: %.3f\n", best_metrics$existence_accuracy))
cat(sprintf("  Existence F1: %.3f\n", best_metrics$existence_f1))
cat(sprintf("  Strength Accuracy: %.3f\n", best_metrics$strength_accuracy %||% 0))
cat(sprintf("  Confidence MAE: %.3f\n", best_metrics$confidence_mae %||% 0))
cat(sprintf("  Polarity Accuracy: %.3f\n", best_metrics$polarity_accuracy %||% 0))
cat("\n")

cat("==============================================================\n")
cat("✓ Training pipeline complete!\n")
cat("==============================================================\n")
