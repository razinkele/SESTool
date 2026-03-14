# ==============================================================================
# Pre-training Script (Week 7)
# ==============================================================================
# Pre-trains connection predictor on Caribbean template (largest dataset).
# The pre-trained model serves as a strong initialization for fine-tuning
# on smaller templates, enabling better transfer learning.
#
# Caribbean template advantages:
# - Largest dataset: 273 training examples
# - Most comprehensive: 78 elements across all DAPSI(W)R(M) types
# - Rich context: Diverse marine ecosystem patterns
# - Strong foundation for transfer to other templates
#
# Author: Phase 2 ML Enhancement - Week 7
# Date: 2026-01-01
# ==============================================================================

library(torch)
library(dplyr)

# Source required modules
source("functions/ml_feature_engineering.R")
source("functions/ml_context_embeddings.R")
source("functions/ml_models.R")
source("functions/ml_graph_features.R")

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  # Data
  data_file = "data/ml_training_data.rds",
  pretrain_template = "Caribbean Island - Comprehensive SES Template",
  elem_feature_dim = 270,
  graph_dim = 8,

  # Model architecture (Phase 2)
  hidden_dim = 256,
  dropout = 0.3,
  use_embeddings = TRUE,

  # Training
  max_epochs = 100,
  batch_size = 32,
  learning_rate = 0.001,
  patience = 15,

  # Output
  models_dir = "models",
  pretrained_model_name = "connection_predictor_pretrained.pt",
  checkpoint_dir = "models/checkpoints/pretrain",
  log_file = "models/training_log_pretrain.txt"
)

# Create directories
if (!dir.exists(CONFIG$models_dir)) dir.create(CONFIG$models_dir, recursive = TRUE)
if (!dir.exists(CONFIG$checkpoint_dir)) dir.create(CONFIG$checkpoint_dir, recursive = TRUE)

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Filter Training Data to Single Template
#'
#' @param train_df Dataframe. Training data
#' @param val_df Dataframe. Validation data
#' @param graph_features_train Matrix. Training graph features
#' @param graph_features_val Matrix. Validation graph features
#' @param template_name Character. Template to filter
#' @return List with filtered datasets
filter_to_template <- function(train_df, val_df,
                               graph_features_train, graph_features_val,
                               template_name) {

  # Filter training data
  train_mask <- train_df$template == template_name
  filtered_train <- train_df[train_mask, ]
  filtered_train_graph <- graph_features_train[train_mask, , drop = FALSE]

  # Filter validation data
  val_mask <- val_df$template == template_name
  filtered_val <- val_df[val_mask, ]
  filtered_val_graph <- graph_features_val[val_mask, , drop = FALSE]

  cat(sprintf("Filtered to '%s':\n", template_name))
  cat(sprintf("  Train: %d examples (%.1f%% of total)\n",
              nrow(filtered_train),
              100 * nrow(filtered_train) / nrow(train_df)))
  cat(sprintf("  Validation: %d examples (%.1f%% of total)\n",
              nrow(filtered_val),
              100 * nrow(filtered_val) / nrow(val_df)))

  return(list(
    train = filtered_train,
    val = filtered_val,
    train_graph = filtered_train_graph,
    val_graph = filtered_val_graph,
    n_train = nrow(filtered_train),
    n_val = nrow(filtered_val)
  ))
}

# ==============================================================================
# Main Pre-training Function
# ==============================================================================

pretrain_base_model <- function(config = CONFIG) {

  cat("\n")
  cat("==================================================================\n")
  cat("  PRE-TRAINING ON CARIBBEAN TEMPLATE (Week 7)\n")
  cat("==================================================================\n\n")

  cat(sprintf("Pre-training template: %s\n", config$pretrain_template))
  cat("Rationale: Largest dataset for strong feature learning\n\n")

  # ==============================================================================
  # Load and Filter Data
  # ==============================================================================

  cat("Loading training data...\n")
  training_data <- readRDS(config$data_file)

  # Filter to Caribbean template only
  filtered <- filter_to_template(
    training_data$train,
    training_data$validation,
    training_data$train_graph_features,
    training_data$val_graph_features,
    config$pretrain_template
  )

  if (filtered$n_train == 0) {
    stop("No training examples found for template: ", config$pretrain_template)
  }

  cat(sprintf("\n✓ Graph features available: %d dims\n\n", ncol(filtered$train_graph)))

  # ==============================================================================
  # Prepare Training Data
  # ==============================================================================

  cat("Preparing training features...\n")

  # Element features
  train_elem_features <- torch_zeros(filtered$n_train, config$elem_feature_dim)
  for (i in 1:filtered$n_train) {
    source_emb <- create_element_embedding(filtered$train$source_name[i], 128)
    target_emb <- create_element_embedding(filtered$train$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(filtered$train$source_type[i])
    target_type <- encode_dapsiwrm_type(filtered$train$target_type[i])
    train_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
  }
  cat("  ✓ Element features: 270 dims\n")

  # Context indices
  train_context <- prepare_context_indices(
    filtered$train$regional_sea,
    filtered$train$ecosystem_types,
    filtered$train$main_issues
  )
  train_context_data <- list(
    sea_idx = torch_tensor(as.numeric(train_context$sea_idx), dtype = torch_long()),
    eco_idx = torch_tensor(as.numeric(train_context$eco_idx), dtype = torch_long()),
    issue_idx = torch_tensor(as.numeric(train_context$issue_idx), dtype = torch_long())
  )
  cat("  ✓ Context indices prepared\n")

  # Graph features
  train_graph_tensor <- torch_tensor(filtered$train_graph, dtype = torch_float())

  # Targets
  train_targets <- list(
    existence = torch_tensor(as.numeric(filtered$train$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(convert_strength_to_numeric(filtered$train$strength) - 1, dtype = torch_long()),
    confidence = torch_tensor(as.numeric(filtered$train$confidence), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(ifelse(filtered$train$polarity == "+", 1, 0), dtype = torch_float())$view(c(-1, 1))
  )
  cat("  ✓ Targets prepared\n")

  # Create dataloader
  train_dataset <- tensor_dataset(
    train_elem_features,
    train_context_data$sea_idx,
    train_context_data$eco_idx,
    train_context_data$issue_idx,
    train_graph_tensor,
    train_targets$existence,
    train_targets$strength,
    train_targets$confidence,
    train_targets$polarity
  )

  train_loader <- dataloader(
    train_dataset,
    batch_size = config$batch_size,
    shuffle = TRUE,
    drop_last = FALSE
  )

  cat(sprintf("  ✓ Created dataloader (batch size: %d)\n", config$batch_size))
  cat(sprintf("  ✓ Train batches: %d\n\n", length(train_loader)))

  # ==============================================================================
  # Prepare Validation Data
  # ==============================================================================

  cat("Preparing validation features...\n")

  # Element features
  val_elem_features <- torch_zeros(filtered$n_val, config$elem_feature_dim)
  for (i in 1:filtered$n_val) {
    source_emb <- create_element_embedding(filtered$val$source_name[i], 128)
    target_emb <- create_element_embedding(filtered$val$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(filtered$val$source_type[i])
    target_type <- encode_dapsiwrm_type(filtered$val$target_type[i])
    val_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
  }

  # Context indices
  val_context <- prepare_context_indices(
    filtered$val$regional_sea,
    filtered$val$ecosystem_types,
    filtered$val$main_issues
  )
  val_context_data <- list(
    sea_idx = torch_tensor(as.numeric(val_context$sea_idx), dtype = torch_long()),
    eco_idx = torch_tensor(as.numeric(val_context$eco_idx), dtype = torch_long()),
    issue_idx = torch_tensor(as.numeric(val_context$issue_idx), dtype = torch_long())
  )

  # Graph features
  val_graph_tensor <- torch_tensor(filtered$val_graph, dtype = torch_float())

  # Targets
  val_targets <- list(
    existence = torch_tensor(as.numeric(filtered$val$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(convert_strength_to_numeric(filtered$val$strength) - 1, dtype = torch_long()),
    confidence = torch_tensor(as.numeric(filtered$val$confidence), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(ifelse(filtered$val$polarity == "+", 1, 0), dtype = torch_float())$view(c(-1, 1))
  )

  val_dataset <- tensor_dataset(
    val_elem_features,
    val_context_data$sea_idx,
    val_context_data$eco_idx,
    val_context_data$issue_idx,
    val_graph_tensor,
    val_targets$existence,
    val_targets$strength,
    val_targets$confidence,
    val_targets$polarity
  )

  val_loader <- dataloader(
    val_dataset,
    batch_size = config$batch_size,
    shuffle = FALSE,
    drop_last = FALSE
  )

  cat(sprintf("  ✓ Validation batches: %d\n\n", length(val_loader)))

  # ==============================================================================
  # Initialize Model
  # ==============================================================================

  cat("Initializing Phase 2 model for pre-training...\n")
  model <- connection_predictor_v2(
    elem_input_dim = config$elem_feature_dim,
    graph_dim = config$graph_dim,
    hidden_dim = config$hidden_dim,
    dropout = config$dropout,
    use_embeddings = config$use_embeddings
  )

  optimizer <- optim_adam(model$parameters, lr = config$learning_rate)

  n_params <- sum(sapply(model$parameters, function(p) prod(p$shape)))
  cat(sprintf("  Model parameters: %s\n", format(n_params, big.mark = ",")))
  cat(sprintf("  Input dimension: %d\n", config$elem_feature_dim + config$graph_dim))
  cat(sprintf("  Hidden dimension: %d\n", config$hidden_dim))
  cat(sprintf("  Dropout: %.2f\n\n", config$dropout))

  # ==============================================================================
  # Training Loop
  # ==============================================================================

  cat("Starting pre-training...\n")
  cat(sprintf("  Max epochs: %d\n", config$max_epochs))
  cat(sprintf("  Batch size: %d\n", config$batch_size))
  cat(sprintf("  Learning rate: %.4f\n", config$learning_rate))
  cat(sprintf("  Early stopping patience: %d\n\n", config$patience))

  best_val_loss <- Inf
  patience_counter <- 0
  training_history <- list()

  for (epoch in 1:config$max_epochs) {

    # ==============================================================================
    # Training Epoch
    # ==============================================================================

    model$train()
    train_losses <- c()

    coro::loop(for (batch in train_loader) {
      # Unpack batch
      b_elem <- batch[[1]]
      b_sea <- batch[[2]]
      b_eco <- batch[[3]]
      b_issue <- batch[[4]]
      b_graph <- batch[[5]]
      b_exist_target <- batch[[6]]
      b_strength_target <- batch[[7]]
      b_conf_target <- batch[[8]]
      b_pol_target <- batch[[9]]

      # Forward pass
      predictions <- model(
        b_elem,
        list(sea_idx = b_sea, eco_idx = b_eco, issue_idx = b_issue),
        b_graph
      )

      # Calculate loss
      loss <- multitask_loss(
        predictions,
        list(
          existence = b_exist_target,
          strength = b_strength_target,
          confidence = b_conf_target,
          polarity = b_pol_target
        ),
        weights = list(existence = 1.0, strength = 0.8, confidence = 0.5, polarity = 0.5)
      )

      # Backward pass
      optimizer$zero_grad()
      loss$backward()
      optimizer$step()

      train_losses <- c(train_losses, as.numeric(loss))
    })

    avg_train_loss <- mean(train_losses)

    # ==============================================================================
    # Validation
    # ==============================================================================

    model$eval()
    val_losses <- c()

    with_no_grad({
      coro::loop(for (batch in val_loader) {
        b_elem <- batch[[1]]
        b_sea <- batch[[2]]
        b_eco <- batch[[3]]
        b_issue <- batch[[4]]
        b_graph <- batch[[5]]
        b_exist_target <- batch[[6]]
        b_strength_target <- batch[[7]]
        b_conf_target <- batch[[8]]
        b_pol_target <- batch[[9]]

        predictions <- model(
          b_elem,
          list(sea_idx = b_sea, eco_idx = b_eco, issue_idx = b_issue),
          b_graph
        )

        loss <- multitask_loss(
          predictions,
          list(
            existence = b_exist_target,
            strength = b_strength_target,
            confidence = b_conf_target,
            polarity = b_pol_target
          ),
          weights = list(existence = 1.0, strength = 0.8, confidence = 0.5, polarity = 0.5)
        )

        val_losses <- c(val_losses, as.numeric(loss))
      })
    })

    avg_val_loss <- mean(val_losses)

    # ==============================================================================
    # Logging and Early Stopping
    # ==============================================================================

    cat(sprintf("Epoch %d/%d\n", epoch, config$max_epochs))
    cat(sprintf("  Train Loss: %.4f | Val Loss: %.4f\n", avg_train_loss, avg_val_loss))

    # Save history
    training_history[[epoch]] <- list(
      epoch = epoch,
      train_loss = avg_train_loss,
      val_loss = avg_val_loss
    )

    # Check for improvement
    if (avg_val_loss < best_val_loss) {
      best_val_loss <- avg_val_loss
      patience_counter <- 0

      # Save best model
      torch_save(model, file.path(config$models_dir, config$pretrained_model_name))
      cat("  ✓ Saved best pre-trained model\n")
    } else {
      patience_counter <- patience_counter + 1
      cat(sprintf("  Patience: %d/%d\n", patience_counter, config$patience))
    }

    cat("\n")

    # Early stopping check
    if (patience_counter >= config$patience) {
      cat(sprintf("Early stopping triggered at epoch %d\n", epoch))
      break
    }

    # Save checkpoint every 10 epochs
    if (epoch %% 10 == 0) {
      checkpoint_path <- file.path(
        config$checkpoint_dir,
        sprintf("pretrain_epoch_%03d.pt", epoch)
      )
      torch_save(model, checkpoint_path)
    }
  }

  # ==============================================================================
  # Pre-training Complete
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  PRE-TRAINING COMPLETE\n")
  cat("==================================================================\n\n")

  cat(sprintf("Pre-trained on: %s\n", config$pretrain_template))
  cat(sprintf("Training examples: %d\n", filtered$n_train))
  cat(sprintf("Validation examples: %d\n", filtered$n_val))
  cat(sprintf("Best validation loss: %.4f\n", best_val_loss))
  cat(sprintf("Pre-trained model saved: %s\n\n",
              file.path(config$models_dir, config$pretrained_model_name)))

  # Save training history
  history_file <- file.path(config$models_dir, "training_history_pretrain.rds")
  saveRDS(training_history, history_file)
  cat(sprintf("Training history saved: %s\n", history_file))

  # Save metadata
  metadata <- list(
    template = config$pretrain_template,
    n_train = filtered$n_train,
    n_val = filtered$n_val,
    best_val_loss = best_val_loss,
    epochs_trained = length(training_history),
    model_config = list(
      elem_feature_dim = config$elem_feature_dim,
      graph_dim = config$graph_dim,
      hidden_dim = config$hidden_dim,
      dropout = config$dropout
    ),
    timestamp = Sys.time()
  )

  metadata_file <- file.path(config$models_dir, "pretrain_metadata.rds")
  saveRDS(metadata, metadata_file)
  cat(sprintf("Metadata saved: %s\n", metadata_file))

  cat("\nNext steps:\n")
  cat("  1. Evaluate pre-trained model on all templates (baseline)\n")
  cat("  2. Fine-tune on small templates (Aquaculture, Pollution, etc.)\n")
  cat("  3. Compare: From-scratch vs Pre-trained vs Fine-tuned\n\n")

  return(list(
    model = model,
    history = training_history,
    best_val_loss = best_val_loss,
    metadata = metadata
  ))
}

# ==============================================================================
# Execute Pre-training
# ==============================================================================

if (!interactive()) {
  result <- pretrain_base_model(CONFIG)
  cat("\n✓ Pre-training complete!\n")
}
