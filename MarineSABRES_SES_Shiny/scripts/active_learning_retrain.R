# scripts/active_learning_retrain.R
# Active Learning Pipeline - Retrain Model with User Feedback
# ==============================================================================
#
# This script:
# 1. Loads original training data
# 2. Merges with user feedback corrections
# 3. Applies data augmentation
# 4. Retrains the model
# 5. Evaluates improvement
#
# Usage: Rscript scripts/active_learning_retrain.R
# ==============================================================================

library(torch)
library(dplyr)

# Source required functions
source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")
source("functions/ml_feedback_logger.R")
source("functions/ml_data_augmentation.R")

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  # Data files
  original_training_data = "data/ml_training_data.rds",
  feedback_log = "data/ml_feedback_log.rds",

  # Output
  output_model = "models/connection_predictor_active.pt",
  output_data = "data/ml_training_data_augmented.rds",

  # Training parameters
  batch_size = 32,
  learning_rate = 0.001,
  max_epochs = 100,
  patience = 15,  # Increased patience for augmented data

  # Model architecture
  input_dim = 358,
  hidden_dim = 256,
  dropout = 0.3,

  # Augmentation
  use_augmentation = TRUE,
  augmentation_factor = 2,  # 2x expansion of positive examples

  # Active learning
  min_feedback_entries = 10,  # Minimum feedback before retraining
  feedback_weight = 1.5  # Weight user corrections higher
)

# ==============================================================================
# Step 1: Load Original Training Data
# ==============================================================================

cat("\n")
cat("==============================================================\n")
cat("  Active Learning - Model Retraining with User Feedback\n")
cat("==============================================================\n\n")

cat("Step 1: Loading original training data...\n")

if (!file.exists(CONFIG$original_training_data)) {
  stop("Original training data not found. Run scripts/extract_training_data.R first.")
}

training_data <- readRDS(CONFIG$original_training_data)

cat(sprintf("  Train: %d examples\n", nrow(training_data$train)))
cat(sprintf("  Validation: %d examples\n", nrow(training_data$validation)))
cat(sprintf("  Test: %d examples\n", nrow(training_data$test)))

# ==============================================================================
# Step 2: Load and Process User Feedback
# ==============================================================================

cat("\nStep 2: Loading user feedback...\n")

if (!file.exists(CONFIG$feedback_log)) {
  cat("  No feedback log found. Skipping feedback integration.\n")
  cat("  Will proceed with data augmentation only.\n")
  feedback_data <- NULL
} else {
  feedback_log <- readRDS(CONFIG$feedback_log)

  if (nrow(feedback_log) < CONFIG$min_feedback_entries) {
    cat(sprintf("  Only %d feedback entries (minimum: %d)\n",
                nrow(feedback_log), CONFIG$min_feedback_entries))
    cat("  Insufficient data for active learning. Skipping feedback integration.\n")
    feedback_data <- NULL
  } else {
    cat(sprintf("  Found %d feedback entries\n", nrow(feedback_log)))

    # Convert feedback to training format
    feedback_data <- feedback_log %>%
      filter(
        # Only include accepted connections or corrected classifications
        (prediction_type == "connection" & user_action == "accepted") |
        (prediction_type == "classification" & user_action == "modified")
      ) %>%
      mutate(
        # Convert to training format
        connection_exists = ifelse(prediction_type == "connection" & user_action == "accepted", 1, 0),
        source_type = ifelse(is.na(source_type), user_selected_type, source_type),
        target_type = ifelse(is.na(target_type), user_selected_type, target_type),
        strength = user_selected_strength,
        confidence = user_selected_confidence,
        polarity = user_selected_polarity
      ) %>%
      select(
        source_name, source_type,
        target_name, target_type,
        connection_exists,
        strength, confidence, polarity,
        regional_sea, ecosystem_types, main_issues,
        template = session_id  # Use session as template identifier
      )

    # Remove entries with missing critical fields
    feedback_data <- feedback_data %>%
      filter(
        !is.na(source_name) & source_name != "",
        !is.na(source_type) & source_type != ""
      )

    cat(sprintf("  Processed %d high-quality feedback entries\n", nrow(feedback_data)))
  }
}

# ==============================================================================
# Step 3: Merge Feedback with Training Data
# ==============================================================================

if (!is.null(feedback_data) && nrow(feedback_data) > 0) {
  cat("\nStep 3: Merging feedback with training data...\n")

  # Add feedback to training set with higher weight
  # We'll duplicate feedback entries to give them more influence
  weighted_feedback <- feedback_data
  for (i in 1:(CONFIG$feedback_weight - 1)) {
    weighted_feedback <- rbind(weighted_feedback, feedback_data)
  }

  training_data$train <- rbind(training_data$train, weighted_feedback)

  cat(sprintf("  Added %d feedback examples (weighted %dx)\n",
              nrow(feedback_data), CONFIG$feedback_weight))
  cat(sprintf("  New training set size: %d examples\n", nrow(training_data$train)))
} else {
  cat("\nStep 3: No feedback to merge (skipped)\n")
}

# ==============================================================
# Step 4: Data Augmentation
# ==============================================================

if (CONFIG$use_augmentation) {
  cat("\nStep 4: Applying data augmentation...\n")

  training_data <- augment_training_split(
    training_data,
    augmentation_factor = CONFIG$augmentation_factor
  )
} else {
  cat("\nStep 4: Data augmentation disabled (skipped)\n")
}

# Save augmented data
cat(sprintf("\nSaving augmented training data to %s...\n", CONFIG$output_data))
saveRDS(training_data, CONFIG$output_data)
cat("✓ Data saved\n")

# ==============================================================
# Step 5: Retrain Model
# ==============================================================

cat("\nStep 5: Retraining model with augmented data...\n")
cat("==============================================================\n\n")

# Create feature matrices
cat("Creating feature matrices...\n")
train_features <- create_feature_matrix(training_data$train, CONFIG$input_dim)
val_features <- create_feature_matrix(training_data$validation, CONFIG$input_dim)

# Prepare targets
prepare_targets <- function(data) {
  # Helper function to map strength
  strength_map <- c("weak" = 1L, "medium" = 2L, "strong" = 3L)

  list(
    existence = torch_tensor(as.numeric(data$connection_exists),
                            dtype = torch_float())$view(c(-1, 1)),

    strength = torch_tensor(
      sapply(seq_len(nrow(data)), function(i) {
        s <- data$strength[i]
        if (is.na(s) || s == "" || is.null(s)) return(2L)
        val <- strength_map[tolower(as.character(s))]
        if (is.na(val)) return(2L)
        as.integer(val)
      }),
      dtype = torch_long()
    ),

    confidence = torch_tensor(
      sapply(data$confidence, function(x) {
        if (is.na(x)) return(3.0)
        max(1.0, min(5.0, as.numeric(x)))
      }),
      dtype = torch_float()
    )$view(c(-1, 1)),

    polarity = torch_tensor(
      sapply(data$polarity, function(x) {
        if (is.na(x) || x == "" || is.null(x)) return(1.0)
        ifelse(as.character(x) == "+", 1.0, 0.0)
      }),
      dtype = torch_float()
    )$view(c(-1, 1))
  )
}

train_targets <- prepare_targets(training_data$train)
val_targets <- prepare_targets(training_data$validation)

# Create datasets
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
      y = self$targets
    )
  },

  .length = function() {
    self$n
  }
)

train_ds <- ses_dataset(train_features, train_targets)
val_ds <- ses_dataset(val_features, val_targets)

# Create dataloaders
train_dl <- dataloader(train_ds, batch_size = CONFIG$batch_size, shuffle = TRUE)
val_dl <- dataloader(val_ds, batch_size = CONFIG$batch_size, shuffle = FALSE)

# Initialize model
model <- connection_predictor(
  input_dim = CONFIG$input_dim,
  hidden_dim = CONFIG$hidden_dim,
  dropout = CONFIG$dropout
)

# Optimizer
optimizer <- optim_adam(model$parameters, lr = CONFIG$learning_rate)

# Training loop
cat("\nTraining model...\n")
cat("----------------------------------------------------------\n")

best_val_loss <- Inf
patience_counter <- 0

for (epoch in 1:CONFIG$max_epochs) {
  # Training
  model$train()
  train_loss <- 0

  coro::loop(for (batch in train_dl) {
    optimizer$zero_grad()

    predictions <- model(batch$x)
    loss <- multitask_loss(predictions, batch$y)

    loss$backward()
    optimizer$step()

    train_loss <- train_loss + loss$item()
  })

  train_loss <- train_loss / length(train_dl)

  # Validation
  model$eval()
  val_loss <- 0

  with_no_grad({
    coro::loop(for (batch in val_dl) {
      predictions <- model(batch$x)
      loss <- multitask_loss(predictions, batch$y)
      val_loss <- val_loss + loss$item()
    })
  })

  val_loss <- val_loss / length(val_dl)

  # Print progress
  cat(sprintf("Epoch %3d/%d - Train Loss: %.4f - Val Loss: %.4f",
              epoch, CONFIG$max_epochs, train_loss, val_loss))

  # Check for improvement
  if (val_loss < best_val_loss) {
    best_val_loss <- val_loss
    patience_counter <- 0

    # Save best model
    torch_save(model, CONFIG$output_model)
    cat(" ← BEST\n")
  } else {
    patience_counter <- patience_counter + 1
    cat(sprintf(" (patience: %d/%d)\n", patience_counter, CONFIG$patience))
  }

  # Early stopping
  if (patience_counter >= CONFIG$patience) {
    cat(sprintf("\nEarly stopping triggered at epoch %d\n", epoch))
    break
  }
}

cat("\n==============================================================\n")
cat("✓ Active Learning Retraining Complete!\n")
cat("==============================================================\n\n")

cat("Results:\n")
cat(sprintf("  Best validation loss: %.4f\n", best_val_loss))
cat(sprintf("  Model saved to: %s\n", CONFIG$output_model))
cat(sprintf("  Training data saved to: %s\n", CONFIG$output_data))

cat("\nNext steps:\n")
cat("  1. Evaluate new model: Rscript scripts/analyze_ml_performance.R\n")
cat("  2. Compare with previous model\n")
cat("  3. Deploy if performance improved\n\n")
