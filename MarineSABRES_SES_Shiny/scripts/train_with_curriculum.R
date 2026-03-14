# ==============================================================================
# Curriculum Learning Training Script (Week 6)
# ==============================================================================
# Trains connection predictor with curriculum learning strategy:
# - Phase 1 (epochs 1-30): Easy templates (high accuracy, small size)
# - Phase 2 (epochs 31-60): Medium templates (moderate accuracy, medium size)
# - Phase 3 (epochs 61-100): All templates including hard ones
#
# This progressive difficulty approach helps the model learn fundamental
# patterns first before tackling complex, ambiguous cases.
#
# Author: Phase 2 ML Enhancement - Week 6
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
  patience = 15,  # Increased for curriculum (more variability)

  # Curriculum phases
  curriculum = list(
    phase1 = list(
      epochs = 1:30,
      templates = c("Tourism_SES_Template.json", "Fisheries", "Pollution"),
      name = "Easy Templates"
    ),
    phase2 = list(
      epochs = 31:60,
      templates = c("Tourism_SES_Template.json", "Fisheries", "Pollution",
                    "OffshoreWind_SES_Template.json",
                    "Climate Change Impacts on Marine Ecosystems"),
      name = "Easy + Medium Templates"
    ),
    phase3 = list(
      epochs = 61:100,
      templates = "all",  # All templates
      name = "All Templates"
    )
  ),

  # Output
  models_dir = "models",
  checkpoint_dir = "models/checkpoints/curriculum",
  final_model_name = "connection_predictor_v2_curriculum.pt",
  log_file = "models/training_log_curriculum.txt"
)

# Create directories
if (!dir.exists(CONFIG$models_dir)) dir.create(CONFIG$models_dir, recursive = TRUE)
if (!dir.exists(CONFIG$checkpoint_dir)) dir.create(CONFIG$checkpoint_dir, recursive = TRUE)

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Get Current Curriculum Phase
#'
#' @param epoch Integer. Current epoch number
#' @param curriculum List. Curriculum configuration
#' @return List with phase info
get_curriculum_phase <- function(epoch, curriculum) {
  for (phase_name in names(curriculum)) {
    phase <- curriculum[[phase_name]]
    if (epoch %in% phase$epochs) {
      return(list(
        name = phase_name,
        display_name = phase$name,
        templates = phase$templates,
        epoch_range = range(phase$epochs)
      ))
    }
  }
  # Default: return last phase
  last_phase <- curriculum[[length(curriculum)]]
  return(list(
    name = paste0("phase", length(curriculum)),
    display_name = last_phase$name,
    templates = last_phase$templates,
    epoch_range = range(last_phase$epochs)
  ))
}

#' Filter Training Data by Curriculum Phase
#'
#' @param train_df Dataframe. Training data
#' @param graph_features Matrix. Graph features
#' @param phase_templates Character vector. Templates for current phase
#' @return List with filtered data and features
filter_by_curriculum <- function(train_df, graph_features, phase_templates) {
  if (length(phase_templates) == 1 && phase_templates == "all") {
    # Use all data
    return(list(
      data = train_df,
      graph_features = graph_features,
      n_examples = nrow(train_df)
    ))
  }

  # Filter by templates
  mask <- train_df$template %in% phase_templates
  filtered_df <- train_df[mask, ]
  filtered_graph <- graph_features[mask, , drop = FALSE]

  return(list(
    data = filtered_df,
    graph_features = filtered_graph,
    n_examples = nrow(filtered_df)
  ))
}

#' Create Dataloader for Curriculum Phase
#'
#' @param elem_features Tensor. Element features
#' @param context_data List. Context indices
#' @param graph_features Tensor. Graph features
#' @param targets List. Target tensors
#' @param batch_size Integer. Batch size
#' @param shuffle Logical. Whether to shuffle
#' @return Dataloader
create_curriculum_dataloader <- function(elem_features, context_data, graph_features,
                                        targets, batch_size, shuffle = TRUE) {
  dataset <- tensor_dataset(
    elem_features,
    context_data$sea_idx,
    context_data$eco_idx,
    context_data$issue_idx,
    graph_features,
    targets$existence,
    targets$strength,
    targets$confidence,
    targets$polarity
  )

  dataloader(
    dataset,
    batch_size = batch_size,
    shuffle = shuffle,
    drop_last = FALSE
  )
}

# ==============================================================================
# Main Training Function
# ==============================================================================

train_with_curriculum <- function(config = CONFIG) {

  cat("\n")
  cat("==================================================================\n")
  cat("  CURRICULUM LEARNING TRAINING (Week 6)\n")
  cat("==================================================================\n\n")

  # Print curriculum schedule
  cat("Curriculum Schedule:\n")
  for (i in 1:length(config$curriculum)) {
    phase <- config$curriculum[[i]]
    epoch_range <- range(phase$epochs)
    templates_str <- if (length(phase$templates) == 1 && phase$templates == "all") {
      "All templates"
    } else {
      paste(phase$templates, collapse = ", ")
    }
    cat(sprintf("  Phase %d (epochs %d-%d): %s\n",
                i, epoch_range[1], epoch_range[2], phase$name))
    cat(sprintf("    Templates: %s\n", templates_str))
  }
  cat("\n")

  # ==============================================================================
  # Load Data
  # ==============================================================================

  cat("Loading training data...\n")
  training_data <- readRDS(config$data_file)

  train_df <- training_data$train
  val_df <- training_data$validation
  train_graph <- training_data$train_graph_features
  val_graph <- training_data$val_graph_features

  cat(sprintf("  Full train set: %d examples\n", nrow(train_df)))
  cat(sprintf("  Validation set: %d examples\n", nrow(val_df)))
  cat(sprintf("  ✓ Graph features available: %d dims\n\n", ncol(train_graph)))

  # ==============================================================================
  # Prepare Validation Data (full validation set, never filtered)
  # ==============================================================================

  cat("Preparing validation data...\n")

  # Element features
  val_elem_features <- torch_zeros(nrow(val_df), config$elem_feature_dim)
  for (i in 1:nrow(val_df)) {
    source_emb <- create_element_embedding(val_df$source_name[i], 128)
    target_emb <- create_element_embedding(val_df$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(val_df$source_type[i])
    target_type <- encode_dapsiwrm_type(val_df$target_type[i])
    val_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
  }

  # Context indices
  val_context <- prepare_context_indices(
    val_df$regional_sea,
    val_df$ecosystem_types,
    val_df$main_issues
  )
  val_context_data <- list(
    sea_idx = torch_tensor(as.numeric(val_context$sea_idx), dtype = torch_long()),
    eco_idx = torch_tensor(as.numeric(val_context$eco_idx), dtype = torch_long()),
    issue_idx = torch_tensor(as.numeric(val_context$issue_idx), dtype = torch_long())
  )

  # Graph features
  val_graph_tensor <- torch_tensor(val_graph, dtype = torch_float())

  # Targets
  val_targets <- list(
    existence = torch_tensor(as.numeric(val_df$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(convert_strength_to_numeric(val_df$strength) - 1, dtype = torch_long()),
    confidence = torch_tensor(as.numeric(val_df$confidence), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(ifelse(val_df$polarity == "+", 1, 0), dtype = torch_float())$view(c(-1, 1))
  )

  val_loader <- create_curriculum_dataloader(
    val_elem_features, val_context_data, val_graph_tensor,
    val_targets, config$batch_size, shuffle = FALSE
  )

  cat("  ✓ Validation data prepared\n\n")

  # ==============================================================================
  # Initialize Model
  # ==============================================================================

  cat("Initializing Phase 2 model with curriculum learning...\n")
  model <- connection_predictor_v2(
    elem_input_dim = config$elem_feature_dim,
    graph_dim = config$graph_dim,
    hidden_dim = config$hidden_dim,
    dropout = config$dropout,
    use_embeddings = config$use_embeddings
  )

  optimizer <- optim_adam(model$parameters, lr = config$learning_rate)

  cat(sprintf("  Model parameters: %d\n",
              sum(sapply(model$parameters, function(p) prod(p$shape)))))
  cat(sprintf("  Input dimension: %d\n\n", config$elem_feature_dim + config$graph_dim))

  # ==============================================================================
  # Training Loop with Curriculum
  # ==============================================================================

  cat("Starting curriculum learning...\n")
  cat(sprintf("  Max epochs: %d\n", config$max_epochs))
  cat(sprintf("  Batch size: %d\n", config$batch_size))
  cat(sprintf("  Early stopping patience: %d\n\n", config$patience))

  best_val_loss <- Inf
  patience_counter <- 0
  training_history <- list()
  current_phase_name <- NULL

  for (epoch in 1:config$max_epochs) {

    # ==============================================================================
    # Check Curriculum Phase
    # ==============================================================================

    phase_info <- get_curriculum_phase(epoch, config$curriculum)

    # Print phase change
    if (is.null(current_phase_name) || current_phase_name != phase_info$name) {
      cat("\n")
      cat("==================================================================\n")
      cat(sprintf("  CURRICULUM PHASE: %s (epochs %d-%d)\n",
                  phase_info$display_name,
                  phase_info$epoch_range[1],
                  phase_info$epoch_range[2]))
      cat("==================================================================\n\n")
      current_phase_name <- phase_info$name
    }

    # ==============================================================================
    # Filter Training Data by Curriculum
    # ==============================================================================

    filtered <- filter_by_curriculum(train_df, train_graph, phase_info$templates)

    if (epoch == min(phase_info$epoch_range)) {
      # First epoch of phase: prepare features
      cat(sprintf("Preparing curriculum data (%d examples)...\n", filtered$n_examples))

      # Element features for filtered data
      train_elem_features <- torch_zeros(filtered$n_examples, config$elem_feature_dim)
      for (i in 1:filtered$n_examples) {
        source_emb <- create_element_embedding(filtered$data$source_name[i], 128)
        target_emb <- create_element_embedding(filtered$data$target_name[i], 128)
        source_type <- encode_dapsiwrm_type(filtered$data$source_type[i])
        target_type <- encode_dapsiwrm_type(filtered$data$target_type[i])
        train_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
      }

      # Context indices
      train_context <- prepare_context_indices(
        filtered$data$regional_sea,
        filtered$data$ecosystem_types,
        filtered$data$main_issues
      )
      train_context_data <- list(
        sea_idx = torch_tensor(as.numeric(train_context$sea_idx), dtype = torch_long()),
        eco_idx = torch_tensor(as.numeric(train_context$eco_idx), dtype = torch_long()),
        issue_idx = torch_tensor(as.numeric(train_context$issue_idx), dtype = torch_long())
      )

      # Graph features
      train_graph_tensor <- torch_tensor(filtered$graph_features, dtype = torch_float())

      # Targets
      train_targets <- list(
        existence = torch_tensor(as.numeric(filtered$data$connection_exists), dtype = torch_float())$view(c(-1, 1)),
        strength = torch_tensor(convert_strength_to_numeric(filtered$data$strength) - 1, dtype = torch_long()),
        confidence = torch_tensor(as.numeric(filtered$data$confidence), dtype = torch_float())$view(c(-1, 1)),
        polarity = torch_tensor(ifelse(filtered$data$polarity == "+", 1, 0), dtype = torch_float())$view(c(-1, 1))
      )

      # Create dataloader
      train_loader <- create_curriculum_dataloader(
        train_elem_features, train_context_data, train_graph_tensor,
        train_targets, config$batch_size, shuffle = TRUE
      )

      cat(sprintf("  ✓ Train batches: %d\n\n", length(train_loader)))
    }

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

    cat(sprintf("Epoch %d/%d (Phase: %s)\n", epoch, config$max_epochs, phase_info$display_name))
    cat(sprintf("  Train Loss: %.4f | Val Loss: %.4f | Examples: %d\n",
                avg_train_loss, avg_val_loss, filtered$n_examples))

    # Save history
    training_history[[epoch]] <- list(
      epoch = epoch,
      phase = phase_info$name,
      train_loss = avg_train_loss,
      val_loss = avg_val_loss,
      n_examples = filtered$n_examples
    )

    # Check for improvement
    if (avg_val_loss < best_val_loss) {
      best_val_loss <- avg_val_loss
      patience_counter <- 0

      # Save best model
      torch_save(model, file.path(config$models_dir, config$final_model_name))
      cat("  ✓ Saved best model\n")
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
        sprintf("model_epoch_%03d.pt", epoch)
      )
      torch_save(model, checkpoint_path)
    }
  }

  # ==============================================================================
  # Training Complete
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  CURRICULUM TRAINING COMPLETE\n")
  cat("==================================================================\n\n")

  cat(sprintf("Best validation loss: %.4f\n", best_val_loss))
  cat(sprintf("Model saved: %s\n\n", file.path(config$models_dir, config$final_model_name)))

  # Save training history
  history_file <- file.path(config$models_dir, "training_history_curriculum.rds")
  saveRDS(training_history, history_file)
  cat(sprintf("Training history saved: %s\n", history_file))

  return(list(
    model = model,
    history = training_history,
    best_val_loss = best_val_loss
  ))
}

# ==============================================================================
# Execute Training
# ==============================================================================

if (!interactive()) {
  result <- train_with_curriculum(CONFIG)
  cat("\n✓ Curriculum training complete!\n")
}
