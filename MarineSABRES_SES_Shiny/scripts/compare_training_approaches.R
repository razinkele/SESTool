# ==============================================================================
# Training Approach Comparison Script (Week 8)
# ==============================================================================
# Compares three training strategies on a target template:
# 1. From-Scratch: Train on target template without pre-training
# 2. Pre-trained Only: Use Caribbean pre-trained model directly
# 3. Fine-tuned: Caribbean pre-trained + fine-tune on target
#
# This script demonstrates the value of transfer learning by comparing
# performance across approaches on small templates like Aquaculture.
#
# Author: Phase 2 ML Enhancement - Week 8
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
  target_template = "Aquaculture",  # Small template for comparison
  elem_feature_dim = 270,
  graph_dim = 8,

  # Model architecture (Phase 2)
  hidden_dim = 256,
  dropout = 0.3,
  use_embeddings = TRUE,

  # Training - From-Scratch
  scratch_epochs = 100,
  scratch_lr = 0.001,
  scratch_patience = 15,

  # Training - Fine-tuning
  finetune_epochs = 30,
  finetune_lr = 0.0001,
  finetune_patience = 10,
  freeze_layers = c("fc1"),  # Freeze early layers

  # Common
  batch_size = 32,

  # Paths
  pretrained_model_path = "models/connection_predictor_pretrained.pt",
  results_dir = "models/comparison_results",
  output_report = "models/comparison_results/training_approach_comparison.txt"
)

# Create directories
if (!dir.exists(CONFIG$results_dir)) dir.create(CONFIG$results_dir, recursive = TRUE)

# ==============================================================================
# Helper Functions
# ==============================================================================

#' Filter Training Data to Single Template
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

  return(list(
    train = filtered_train,
    val = filtered_val,
    train_graph = filtered_train_graph,
    val_graph = filtered_val_graph,
    n_train = nrow(filtered_train),
    n_val = nrow(filtered_val)
  ))
}

#' Prepare Training Data
prepare_data <- function(filtered, config) {

  # Element features
  train_elem_features <- torch_zeros(filtered$n_train, config$elem_feature_dim)
  for (i in 1:filtered$n_train) {
    source_emb <- create_element_embedding(filtered$train$source_name[i], 128)
    target_emb <- create_element_embedding(filtered$train$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(filtered$train$source_type[i])
    target_type <- encode_dapsiwrm_type(filtered$train$target_type[i])
    train_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
  }

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

  # Graph features
  train_graph_tensor <- torch_tensor(filtered$train_graph, dtype = torch_float())

  # Targets
  train_targets <- list(
    existence = torch_tensor(as.numeric(filtered$train$connection_exists), dtype = torch_float())$view(c(-1, 1)),
    strength = torch_tensor(convert_strength_to_numeric(filtered$train$strength) - 1, dtype = torch_long()),
    confidence = torch_tensor(as.numeric(filtered$train$confidence), dtype = torch_float())$view(c(-1, 1)),
    polarity = torch_tensor(ifelse(filtered$train$polarity == "+", 1, 0), dtype = torch_float())$view(c(-1, 1))
  )

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

  # Validation features
  val_elem_features <- torch_zeros(filtered$n_val, config$elem_feature_dim)
  for (i in 1:filtered$n_val) {
    source_emb <- create_element_embedding(filtered$val$source_name[i], 128)
    target_emb <- create_element_embedding(filtered$val$target_name[i], 128)
    source_type <- encode_dapsiwrm_type(filtered$val$source_type[i])
    target_type <- encode_dapsiwrm_type(filtered$val$target_type[i])
    val_elem_features[i, ] <- torch_tensor(c(source_emb, target_emb, source_type, target_type))
  }

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

  val_graph_tensor <- torch_tensor(filtered$val_graph, dtype = torch_float())

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

  return(list(
    train_loader = train_loader,
    val_loader = val_loader
  ))
}

#' Freeze Model Layers
freeze_layers <- function(model, layer_names) {
  for (layer_name in layer_names) {
    if (layer_name == "fc1" && !is.null(model$fc1)) {
      model$fc1$parameters %>% purrr::walk(~ .x$requires_grad_(FALSE))
    } else if (layer_name == "fc2" && !is.null(model$fc2)) {
      model$fc2$parameters %>% purrr::walk(~ .x$requires_grad_(FALSE))
    } else if (layer_name == "context_embeddings" && !is.null(model$context_embeddings)) {
      model$context_embeddings$parameters %>% purrr::walk(~ .x$requires_grad_(FALSE))
    }
  }
}

#' Evaluate Model
evaluate_model <- function(model, val_loader) {
  model$eval()
  val_losses <- c()

  # Track predictions for accuracy
  all_predictions <- list()
  all_targets <- list()

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

      # Store predictions
      all_predictions$existence <- c(all_predictions$existence, as.numeric(predictions$existence$cpu()))
      all_targets$existence <- c(all_targets$existence, as.numeric(b_exist_target$cpu()))
    })
  })

  # Calculate accuracy
  pred_binary <- ifelse(all_predictions$existence > 0.5, 1, 0)
  accuracy <- mean(pred_binary == all_targets$existence)

  return(list(
    loss = mean(val_losses),
    accuracy = accuracy
  ))
}

#' Train Model
train_model <- function(model, optimizer, train_loader, val_loader,
                       max_epochs, patience, approach_name) {

  cat(sprintf("\nTraining %s approach...\n", approach_name))

  best_val_loss <- Inf
  patience_counter <- 0
  history <- list()

  for (epoch in 1:max_epochs) {
    # Training
    model$train()
    train_losses <- c()

    coro::loop(for (batch in train_loader) {
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

      optimizer$zero_grad()
      loss$backward()
      optimizer$step()

      train_losses <- c(train_losses, as.numeric(loss))
    })

    avg_train_loss <- mean(train_losses)

    # Validation
    val_results <- evaluate_model(model, val_loader)

    if (epoch %% 5 == 0 || epoch == 1) {
      cat(sprintf("  Epoch %d/%d - Train Loss: %.4f | Val Loss: %.4f | Val Acc: %.2f%%\n",
                  epoch, max_epochs, avg_train_loss, val_results$loss, val_results$accuracy * 100))
    }

    history[[epoch]] <- list(
      epoch = epoch,
      train_loss = avg_train_loss,
      val_loss = val_results$loss,
      val_accuracy = val_results$accuracy
    )

    # Early stopping
    if (val_results$loss < best_val_loss) {
      best_val_loss <- val_results$loss
      best_accuracy <- val_results$accuracy
      patience_counter <- 0
    } else {
      patience_counter <- patience_counter + 1
      if (patience_counter >= patience) {
        cat(sprintf("  Early stopping at epoch %d\n", epoch))
        break
      }
    }
  }

  return(list(
    history = history,
    best_val_loss = best_val_loss,
    best_accuracy = best_accuracy,
    epochs_trained = length(history)
  ))
}

# ==============================================================================
# Main Comparison Function
# ==============================================================================

compare_training_approaches <- function(config = CONFIG) {

  cat("\n")
  cat("==================================================================\n")
  cat("  TRAINING APPROACH COMPARISON (Week 8)\n")
  cat("==================================================================\n\n")

  cat(sprintf("Target template: %s\n", config$target_template))
  cat("Comparing three approaches:\n")
  cat("  1. From-Scratch: Train on target template only\n")
  cat("  2. Pre-trained Only: Use Caribbean model directly\n")
  cat("  3. Fine-tuned: Pre-trained + fine-tune on target\n\n")

  # ==============================================================================
  # Load Data
  # ==============================================================================

  cat("Loading training data...\n")
  training_data <- readRDS(config$data_file)

  filtered <- filter_to_template(
    training_data$train,
    training_data$validation,
    training_data$train_graph_features,
    training_data$val_graph_features,
    config$target_template
  )

  cat(sprintf("  Train: %d examples\n", filtered$n_train))
  cat(sprintf("  Validation: %d examples\n\n", filtered$n_val))

  if (filtered$n_train == 0) {
    stop("No training examples found for template: ", config$target_template)
  }

  # Prepare dataloaders
  cat("Preparing dataloaders...\n")
  data <- prepare_data(filtered, config)

  results <- list()

  # ==============================================================================
  # Approach 1: From-Scratch
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  APPROACH 1: FROM-SCRATCH\n")
  cat("==================================================================\n")

  model_scratch <- connection_predictor_v2(
    elem_input_dim = config$elem_feature_dim,
    graph_dim = config$graph_dim,
    hidden_dim = config$hidden_dim,
    dropout = config$dropout,
    use_embeddings = config$use_embeddings
  )

  optimizer_scratch <- optim_adam(model_scratch$parameters, lr = config$scratch_lr)

  results$scratch <- train_model(
    model_scratch,
    optimizer_scratch,
    data$train_loader,
    data$val_loader,
    config$scratch_epochs,
    config$scratch_patience,
    "From-Scratch"
  )

  # Save model
  scratch_path <- file.path(config$results_dir, "model_scratch.pt")
  torch_save(model_scratch, scratch_path)

  # ==============================================================================
  # Approach 2: Pre-trained Only
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  APPROACH 2: PRE-TRAINED ONLY (Zero-shot)\n")
  cat("==================================================================\n")

  if (!file.exists(config$pretrained_model_path)) {
    cat("  WARNING: Pre-trained model not found. Skipping this approach.\n")
    results$pretrained <- NULL
  } else {
    model_pretrained <- torch_load(config$pretrained_model_path)

    cat("  Evaluating pre-trained model on target template...\n")
    pretrained_results <- evaluate_model(model_pretrained, data$val_loader)

    cat(sprintf("  Val Loss: %.4f | Val Acc: %.2f%%\n",
                pretrained_results$loss, pretrained_results$accuracy * 100))

    results$pretrained <- list(
      best_val_loss = pretrained_results$loss,
      best_accuracy = pretrained_results$accuracy,
      epochs_trained = 0
    )
  }

  # ==============================================================================
  # Approach 3: Fine-tuned
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  APPROACH 3: FINE-TUNED\n")
  cat("==================================================================\n")

  if (!file.exists(config$pretrained_model_path)) {
    cat("  WARNING: Pre-trained model not found. Skipping this approach.\n")
    results$finetuned <- NULL
  } else {
    model_finetuned <- torch_load(config$pretrained_model_path)

    # Freeze layers
    if (length(config$freeze_layers) > 0) {
      cat(sprintf("  Freezing layers: %s\n", paste(config$freeze_layers, collapse = ", ")))
      freeze_layers(model_finetuned, config$freeze_layers)
    }

    # Count parameters
    total_params <- sum(sapply(model_finetuned$parameters, function(p) prod(p$shape)))
    trainable_params <- sum(sapply(
      Filter(function(p) p$requires_grad, model_finetuned$parameters),
      function(p) prod(p$shape)
    ))

    cat(sprintf("  Total parameters: %s\n", format(total_params, big.mark = ",")))
    cat(sprintf("  Trainable parameters: %s (%.1f%%)\n",
                format(trainable_params, big.mark = ","),
                100 * trainable_params / total_params))

    optimizer_finetuned <- optim_adam(
      Filter(function(p) p$requires_grad, model_finetuned$parameters),
      lr = config$finetune_lr
    )

    results$finetuned <- train_model(
      model_finetuned,
      optimizer_finetuned,
      data$train_loader,
      data$val_loader,
      config$finetune_epochs,
      config$finetune_patience,
      "Fine-tuned"
    )

    # Save model
    finetuned_path <- file.path(config$results_dir, sprintf("%s_finetuned.pt", tolower(config$target_template)))
    torch_save(model_finetuned, finetuned_path)
  }

  # ==============================================================================
  # Comparison Report
  # ==============================================================================

  cat("\n")
  cat("==================================================================\n")
  cat("  COMPARISON RESULTS\n")
  cat("==================================================================\n\n")

  cat(sprintf("Target Template: %s\n", config$target_template))
  cat(sprintf("Training Examples: %d\n", filtered$n_train))
  cat(sprintf("Validation Examples: %d\n\n", filtered$n_val))

  # Create comparison table
  comparison <- data.frame(
    Approach = character(),
    Epochs = integer(),
    Val_Loss = numeric(),
    Val_Accuracy = numeric(),
    
  )

  if (!is.null(results$scratch)) {
    comparison <- rbind(comparison, data.frame(
      Approach = "From-Scratch",
      Epochs = results$scratch$epochs_trained,
      Val_Loss = results$scratch$best_val_loss,
      Val_Accuracy = results$scratch$best_accuracy * 100
    ))
  }

  if (!is.null(results$pretrained)) {
    comparison <- rbind(comparison, data.frame(
      Approach = "Pre-trained Only",
      Epochs = 0,
      Val_Loss = results$pretrained$best_val_loss,
      Val_Accuracy = results$pretrained$best_accuracy * 100
    ))
  }

  if (!is.null(results$finetuned)) {
    comparison <- rbind(comparison, data.frame(
      Approach = "Fine-tuned",
      Epochs = results$finetuned$epochs_trained,
      Val_Loss = results$finetuned$best_val_loss,
      Val_Accuracy = results$finetuned$best_accuracy * 100
    ))
  }

  # Sort by accuracy (descending)
  comparison <- comparison[order(comparison$Val_Accuracy, decreasing = TRUE), ]

  # Print table
  cat("Performance Comparison:\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat(sprintf("%-20s %10s %12s %14s\n", "Approach", "Epochs", "Val Loss", "Val Accuracy"))
  cat("───────────────────────────────────────────────────────────\n")

  for (i in 1:nrow(comparison)) {
    cat(sprintf("%-20s %10d %12.4f %13.2f%%\n",
                comparison$Approach[i],
                comparison$Epochs[i],
                comparison$Val_Loss[i],
                comparison$Val_Accuracy[i]))
  }
  cat("───────────────────────────────────────────────────────────\n\n")

  # Calculate improvements
  if (nrow(comparison) >= 2) {
    best_approach <- comparison$Approach[1]
    best_accuracy <- comparison$Val_Accuracy[1]

    if ("From-Scratch" %in% comparison$Approach) {
      scratch_accuracy <- comparison$Val_Accuracy[comparison$Approach == "From-Scratch"]

      if (best_approach != "From-Scratch") {
        improvement <- best_accuracy - scratch_accuracy
        cat(sprintf("Transfer Learning Benefit:\n"))
        cat(sprintf("  %s achieved %.2f%% accuracy\n", best_approach, best_accuracy))
        cat(sprintf("  From-Scratch achieved %.2f%% accuracy\n", scratch_accuracy))
        cat(sprintf("  Improvement: +%.2f%% (%.1fx better)\n\n",
                    improvement, best_accuracy / scratch_accuracy))
      }
    }

    cat(sprintf("Best Approach: %s (%.2f%% accuracy)\n\n", best_approach, best_accuracy))
  }

  # Save report
  sink(config$output_report)
  cat("==================================================================\n")
  cat("  TRAINING APPROACH COMPARISON REPORT\n")
  cat("==================================================================\n\n")
  cat(sprintf("Date: %s\n", Sys.time()))
  cat(sprintf("Target Template: %s\n", config$target_template))
  cat(sprintf("Training Examples: %d\n", filtered$n_train))
  cat(sprintf("Validation Examples: %d\n\n", filtered$n_val))

  cat("Performance Comparison:\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat(sprintf("%-20s %10s %12s %14s\n", "Approach", "Epochs", "Val Loss", "Val Accuracy"))
  cat("───────────────────────────────────────────────────────────\n")
  for (i in 1:nrow(comparison)) {
    cat(sprintf("%-20s %10d %12.4f %13.2f%%\n",
                comparison$Approach[i],
                comparison$Epochs[i],
                comparison$Val_Loss[i],
                comparison$Val_Accuracy[i]))
  }
  cat("───────────────────────────────────────────────────────────\n\n")

  cat("\nDetailed Results:\n\n")

  if (!is.null(results$scratch)) {
    cat("FROM-SCRATCH:\n")
    cat(sprintf("  Best validation loss: %.4f\n", results$scratch$best_val_loss))
    cat(sprintf("  Best validation accuracy: %.2f%%\n", results$scratch$best_accuracy * 100))
    cat(sprintf("  Epochs trained: %d\n", results$scratch$epochs_trained))
    cat(sprintf("  Learning rate: %.4f\n\n", config$scratch_lr))
  }

  if (!is.null(results$pretrained)) {
    cat("PRE-TRAINED ONLY (Zero-shot):\n")
    cat(sprintf("  Validation loss: %.4f\n", results$pretrained$best_val_loss))
    cat(sprintf("  Validation accuracy: %.2f%%\n", results$pretrained$best_accuracy * 100))
    cat(sprintf("  No fine-tuning (zero-shot evaluation)\n\n"))
  }

  if (!is.null(results$finetuned)) {
    cat("FINE-TUNED:\n")
    cat(sprintf("  Best validation loss: %.4f\n", results$finetuned$best_val_loss))
    cat(sprintf("  Best validation accuracy: %.2f%%\n", results$finetuned$best_accuracy * 100))
    cat(sprintf("  Epochs trained: %d\n", results$finetuned$epochs_trained))
    cat(sprintf("  Learning rate: %.4f\n", config$finetune_lr))
    cat(sprintf("  Frozen layers: %s\n\n", paste(config$freeze_layers, collapse = ", ")))
  }

  cat("\nConclusion:\n")
  if (nrow(comparison) >= 2) {
    cat(sprintf("The %s approach achieved the best results with %.2f%% validation accuracy.\n",
                comparison$Approach[1], comparison$Val_Accuracy[1]))

    if ("From-Scratch" %in% comparison$Approach && comparison$Approach[1] != "From-Scratch") {
      scratch_acc <- comparison$Val_Accuracy[comparison$Approach == "From-Scratch"]
      best_acc <- comparison$Val_Accuracy[1]
      improvement <- best_acc - scratch_acc

      cat(sprintf("Transfer learning provided a %.2f%% improvement over training from scratch.\n", improvement))

      if (improvement > 5) {
        cat("\nRecommendation: Use transfer learning (pre-training + fine-tuning) for this template.\n")
      } else if (improvement > 0) {
        cat("\nRecommendation: Transfer learning provides modest benefits for this template.\n")
      } else {
        cat("\nRecommendation: Training from scratch may be sufficient for this template.\n")
      }
    }
  }

  sink()

  cat(sprintf("Report saved to: %s\n", config$output_report))

  return(list(
    results = results,
    comparison = comparison,
    config = config
  ))
}

# ==============================================================================
# Execute Comparison
# ==============================================================================

if (!interactive()) {
  result <- compare_training_approaches(CONFIG)
  cat("\n✓ Comparison complete!\n")
}
