# ==============================================================================
# Train Ensemble Models for Active Learning (P2 #26: Expanded Ensemble)
# ==============================================================================
# Trains multiple Phase 2 models with different random seeds for ensemble
# predictions and disagreement-based active learning.
#
# Default configuration uses ML_ENSEMBLE_DEFAULT_SIZE (5) models for improved
# diversity and uncertainty quantification.
#
# Target: Improve robustness and enable disagreement sampling
# ==============================================================================

library(torch)
library(dplyr)

# Source constants and Phase 2 modules
source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_context_embeddings.R")
source("functions/ml_models.R")

if (file.exists("functions/ml_graph_features.R")) {
  source("functions/ml_graph_features.R")
}

# ==============================================================================
# Configuration (uses constants from constants.R where available)
# ==============================================================================

# Determine ensemble size from constants or command line
ensemble_size <- if (exists("ML_ENSEMBLE_DEFAULT_SIZE")) {
  ML_ENSEMBLE_DEFAULT_SIZE
} else {
  5  # Fallback default
}

# Allow override via command line args
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0 && grepl("^\\d+$", args[1])) {
  ensemble_size <- as.integer(args[1])
  cat(sprintf("Using command line ensemble size: %d\n", ensemble_size))
}

# Get seeds from constants or generate
ensemble_seeds <- if (exists("ML_ENSEMBLE_SEEDS")) {
  ML_ENSEMBLE_SEEDS[1:min(ensemble_size, length(ML_ENSEMBLE_SEEDS))]
} else {
  c(42, 123, 456, 789, 1024)[1:ensemble_size]
}

CONFIG <- list(
  # Data
  data_file = "data/ml_training_data.rds",

  # Model architecture (use constants where available)
  elem_feature_dim = 270,  # 2×128 element + 2×7 type
  graph_dim = 8,
  hidden_dim = if (exists("ML_HIDDEN_DIMS")) ML_HIDDEN_DIMS[1] else 256,
  dropout = if (exists("ML_DROPOUT_RATE")) ML_DROPOUT_RATE else 0.3,

  # Training (use constants where available)
  max_epochs = if (exists("ML_DEFAULT_EPOCHS")) ML_DEFAULT_EPOCHS else 100,
  batch_size = if (exists("ML_DEFAULT_BATCH_SIZE")) ML_DEFAULT_BATCH_SIZE else 32,
  learning_rate = if (exists("ML_DEFAULT_LEARNING_RATE")) ML_DEFAULT_LEARNING_RATE else 0.001,
  patience = if (exists("ML_EARLY_STOPPING_PATIENCE")) ML_EARLY_STOPPING_PATIENCE else 15,
  checkpoint_freq = 5,

  # Ensemble configuration (P2 #26: Expanded from 3 to 5 default)
  seeds = ensemble_seeds,
  n_models = ensemble_size,

  # Output
  models_dir = "models/ensemble"
)

# Create ensemble directory
if (!dir.exists(CONFIG$models_dir)) {
  dir.create(CONFIG$models_dir, recursive = TRUE)
}

cat("\n==================================================================\n")
cat("  PHASE 2: Training Ensemble Models (Week 5)\n")
cat("==================================================================\n\n")
cat("Ensemble Configuration:\n")
cat(sprintf("  Number of models: %d\n", CONFIG$n_models))
cat(sprintf("  Random seeds: %s\n", paste(CONFIG$seeds, collapse = ", ")))
cat(sprintf("  Architecture: Phase 2 (314-dim input)\n"))
cat(sprintf("  Hidden dimension: %d\n", CONFIG$hidden_dim))
cat(sprintf("  Dropout: %.2f\n", CONFIG$dropout))
cat("\n")

# ==============================================================================
# Load Training Data
# ==============================================================================

cat("Loading training data...\n")
training_data <- readRDS(CONFIG$data_file)

cat(sprintf("  Train set: %d examples\n", nrow(training_data$train)))
cat(sprintf("  Validation set: %d examples\n", nrow(training_data$validation)))
cat(sprintf("  Test set: %d examples\n", nrow(training_data$test)))

# Check for graph features
has_graph_features <- !is.null(training_data$train_graph_features)
if (has_graph_features) {
  cat(sprintf("  ✓ Graph features available: %d dims\n", ncol(training_data$train_graph_features)))
} else {
  cat("  ℹ No graph features. Using zero-padding.\n")
}
cat("\n")

# ==============================================================================
# Helper Function: Train Single Model
# ==============================================================================

train_single_model <- function(model_id, seed) {
  cat("==================================================================\n")
  cat(sprintf("  Training Ensemble Model %d (seed=%d)\n", model_id, seed))
  cat("==================================================================\n\n")

  # Set random seed for reproducibility
  set.seed(seed)
  torch_manual_seed(seed)

  # Create element features
  cat("Creating element features...\n")
  n_train <- nrow(training_data$train)
  n_val <- nrow(training_data$validation)

  train_elem_features <- matrix(0, nrow = n_train, ncol = CONFIG$elem_feature_dim)
  val_elem_features <- matrix(0, nrow = n_val, ncol = CONFIG$elem_feature_dim)

  for (i in 1:n_train) {
    source_emb <- create_element_embedding(training_data$train$source_name[i], 128)
    target_emb <- create_element_embedding(training_data$train$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(training_data$train$source_type[i])
    target_type <- encode_dapsiwrm_type(training_data$train$target_type[i])
    train_elem_features[i, ] <- c(source_emb, target_emb, source_type, target_type)
  }

  for (i in 1:n_val) {
    source_emb <- create_element_embedding(training_data$validation$source_name[i], 128)
    target_emb <- create_element_embedding(training_data$validation$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(training_data$validation$source_type[i])
    target_type <- encode_dapsiwrm_type(training_data$validation$target_type[i])
    val_elem_features[i, ] <- c(source_emb, target_emb, source_type, target_type)
  }

  cat(sprintf("  ✓ Element features: %d dims\n\n", CONFIG$elem_feature_dim))

  # Prepare context indices
  cat("Preparing context indices...\n")
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

  cat("  ✓ Context indices prepared\n\n")

  # Prepare graph features
  if (has_graph_features) {
    train_graph_features <- training_data$train_graph_features
    val_graph_features <- training_data$val_graph_features
  } else {
    train_graph_features <- matrix(0, nrow = n_train, ncol = CONFIG$graph_dim)
    val_graph_features <- matrix(0, nrow = n_val, ncol = CONFIG$graph_dim)
  }

  # Prepare targets
  cat("Preparing targets...\n")
  train_targets <- list(
    existence = torch_tensor(as.numeric(training_data$train$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(sapply(training_data$train$strength, function(s) {
      if (is.na(s) || s == "") return(2L)
      strength_map <- c("weak" = 1L, "medium" = 2L, "strong" = 3L)
      val <- strength_map[tolower(as.character(s))]
      if (is.na(val)) 2L else as.integer(val)
    }), dtype = torch_long()),
    confidence = torch_tensor(sapply(training_data$train$confidence, function(c) {
      if (is.na(c)) 3.0 else as.numeric(c)
    }), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(sapply(training_data$train$polarity, function(p) {
      if (is.na(p) || p == "") 1.0 else if (as.character(p) == "+") 1.0 else 0.0
    }), dtype = torch_float())$view(c(-1, 1))
  )

  val_targets <- list(
    existence = torch_tensor(as.numeric(training_data$validation$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(sapply(training_data$validation$strength, function(s) {
      if (is.na(s) || s == "") return(2L)
      strength_map <- c("weak" = 1L, "medium" = 2L, "strong" = 3L)
      val <- strength_map[tolower(as.character(s))]
      if (is.na(val)) 2L else as.integer(val)
    }), dtype = torch_long()),
    confidence = torch_tensor(sapply(training_data$validation$confidence, function(c) {
      if (is.na(c)) 3.0 else as.numeric(c)
    }), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(sapply(training_data$validation$polarity, function(p) {
      if (is.na(p) || p == "") 1.0 else if (as.character(p) == "+") 1.0 else 0.0
    }), dtype = torch_float())$view(c(-1, 1))
  )

  cat("  ✓ Targets prepared\n\n")

  # Create datasets
  ses_dataset_v2 <- dataset(
    name = "SESDatasetV2",
    initialize = function(elem_features, context_sea, context_eco, context_issue, graph_features, targets) {
      self$elem_features <- elem_features
      self$sea_idx <- context_sea
      self$eco_idx <- context_eco
      self$issue_idx <- context_issue
      self$graph_features <- graph_features
      self$targets <- targets
      self$n <- nrow(elem_features)
    },
    .getitem = function(index) {
      list(
        elem_features = self$elem_features[index, ],
        sea_idx = self$sea_idx[index],
        eco_idx = self$eco_idx[index],
        issue_idx = self$issue_idx[index],
        graph_features = self$graph_features[index, ],
        y = list(
          existence = self$targets$existence[index],
          strength = self$targets$strength[index],
          confidence = self$targets$confidence[index],
          polarity = self$targets$polarity[index]
        )
      )
    },
    .length = function() {
      self$n
    }
  )

  train_ds <- ses_dataset_v2(
    torch_tensor(train_elem_features, dtype = torch_float()),
    torch_tensor(train_sea, dtype = torch_long()),
    torch_tensor(train_eco, dtype = torch_long()),
    torch_tensor(train_issue, dtype = torch_long()),
    torch_tensor(train_graph_features, dtype = torch_float()),
    train_targets
  )

  val_ds <- ses_dataset_v2(
    torch_tensor(val_elem_features, dtype = torch_float()),
    torch_tensor(val_sea, dtype = torch_long()),
    torch_tensor(val_eco, dtype = torch_long()),
    torch_tensor(val_issue, dtype = torch_long()),
    torch_tensor(val_graph_features, dtype = torch_float()),
    val_targets
  )

  train_dl <- dataloader(train_ds, batch_size = CONFIG$batch_size, shuffle = TRUE)
  val_dl <- dataloader(val_ds, batch_size = CONFIG$batch_size, shuffle = FALSE)

  cat(sprintf("Created dataloaders (batch size: %d)\n", CONFIG$batch_size))
  cat(sprintf("  Train batches: %d\n", length(train_dl)))
  cat(sprintf("  Validation batches: %d\n\n", length(val_dl)))

  # Initialize model
  cat("Initializing Phase 2 model...\n")
  model <- connection_predictor_v2(
    elem_input_dim = CONFIG$elem_feature_dim,
    graph_dim = CONFIG$graph_dim,
    hidden_dim = CONFIG$hidden_dim,
    dropout = CONFIG$dropout,
    use_embeddings = TRUE
  )

  # Optimizer
  optimizer <- optim_adam(model$parameters, lr = CONFIG$learning_rate)

  # Training loop
  cat(sprintf("\nStarting training (Model %d)...\n", model_id))
  cat(sprintf("  Max epochs: %d\n", CONFIG$max_epochs))
  cat(sprintf("  Early stopping patience: %d\n\n", CONFIG$patience))

  history <- list(
    train_loss = numeric(),
    val_loss = numeric()
  )

  best_val_loss <- Inf
  patience_counter <- 0

  for (epoch in 1:CONFIG$max_epochs) {
    cat(sprintf("Epoch %d/%d\n", epoch, CONFIG$max_epochs))

    # Training
    model$train()
    train_loss_sum <- 0
    train_batches <- 0

    coro::loop(for (batch in train_dl) {
      context_data <- list(
        sea_idx = batch$sea_idx,
        eco_idx = batch$eco_idx,
        issue_idx = batch$issue_idx
      )

      predictions <- model(batch$elem_features, context_data, batch$graph_features)
      loss <- multitask_loss(predictions, batch$y)

      optimizer$zero_grad()
      loss$backward()
      optimizer$step()

      train_loss_sum <- train_loss_sum + loss$item()
      train_batches <- train_batches + 1
    })

    train_loss <- train_loss_sum / train_batches

    # Validation
    model$eval()
    val_loss_sum <- 0
    val_batches <- 0

    with_no_grad({
      coro::loop(for (batch in val_dl) {
        context_data <- list(
          sea_idx = batch$sea_idx,
          eco_idx = batch$eco_idx,
          issue_idx = batch$issue_idx
        )

        predictions <- model(batch$elem_features, context_data, batch$graph_features)
        loss <- multitask_loss(predictions, batch$y)

        val_loss_sum <- val_loss_sum + loss$item()
        val_batches <- val_batches + 1
      })
    })

    val_loss <- val_loss_sum / val_batches

    # Record history
    history$train_loss <- c(history$train_loss, train_loss)
    history$val_loss <- c(history$val_loss, val_loss)

    cat(sprintf("  Train Loss: %.4f | Val Loss: %.4f\n", train_loss, val_loss))

    # Early stopping & checkpointing
    if (val_loss < best_val_loss) {
      best_val_loss <- val_loss
      patience_counter <- 0
      model_path <- file.path(CONFIG$models_dir, sprintf("model_%d_seed%d.pt", model_id, seed))
      torch_save(model, model_path)
      cat("  ✓ Saved best model\n")
    } else {
      patience_counter <- patience_counter + 1
      cat(sprintf("  Patience: %d/%d\n", patience_counter, CONFIG$patience))
    }

    if (patience_counter >= CONFIG$patience) {
      cat(sprintf("\nEarly stopping triggered at epoch %d\n", epoch))
      break
    }

    cat("\n")
  }

  cat(sprintf("✓ Model %d training complete (best val loss: %.4f)\n\n", model_id, best_val_loss))

  return(list(
    model_id = model_id,
    seed = seed,
    best_val_loss = best_val_loss,
    history = history,
    model_path = file.path(CONFIG$models_dir, sprintf("model_%d_seed%d.pt", model_id, seed))
  ))
}

# ==============================================================================
# Train All Ensemble Models
# ==============================================================================

ensemble_results <- list()

for (i in 1:CONFIG$n_models) {
  result <- train_single_model(model_id = i, seed = CONFIG$seeds[i])
  ensemble_results[[i]] <- result
}

# ==============================================================================
# Save Ensemble Metadata
# ==============================================================================

cat("==================================================================\n")
cat("  ENSEMBLE TRAINING SUMMARY\n")
cat("==================================================================\n\n")

for (i in 1:CONFIG$n_models) {
  res <- ensemble_results[[i]]
  cat(sprintf("Model %d (seed=%d):\n", res$model_id, res$seed))
  cat(sprintf("  Best validation loss: %.4f\n", res$best_val_loss))
  cat(sprintf("  Model path: %s\n\n", res$model_path))
}

# Save ensemble configuration
ensemble_metadata <- list(
  n_models = CONFIG$n_models,
  seeds = CONFIG$seeds,
  model_paths = sapply(ensemble_results, function(r) r$model_path),
  best_val_losses = sapply(ensemble_results, function(r) r$best_val_loss),
  architecture = list(
    elem_feature_dim = CONFIG$elem_feature_dim,
    graph_dim = CONFIG$graph_dim,
    hidden_dim = CONFIG$hidden_dim,
    dropout = CONFIG$dropout
  ),
  created_at = Sys.time()
)

metadata_path <- file.path(CONFIG$models_dir, "ensemble_metadata.rds")
saveRDS(ensemble_metadata, metadata_path)
cat(sprintf("✓ Ensemble metadata saved: %s\n\n", metadata_path))

cat("==================================================================\n")
cat("✓ ENSEMBLE TRAINING COMPLETE!\n")
cat("==================================================================\n\n")

cat("Next steps:\n")
cat("  1. Evaluate ensemble on test set\n")
cat("  2. Implement disagreement sampling\n")
cat("  3. Compare with single model performance\n")
cat("  4. Benchmark inference time (<150ms target)\n\n")
