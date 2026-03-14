# ==============================================================================
# Evaluate Connection Predictor Model V2 (Phase 2)
# ==============================================================================
# Evaluates the Phase 2 model on test set and compares with Phase 1 baseline
#
# Target: 87-90% accuracy (vs 82.6% Phase 1)
# ==============================================================================

library(torch)
library(dplyr)

# Source Phase 2 modules
source("functions/ml_feature_engineering.R")
source("functions/ml_context_embeddings.R")
source("functions/ml_models.R")

if (file.exists("functions/ml_graph_features.R")) {
  source("functions/ml_graph_features.R")
}

set.seed(42)
torch_manual_seed(42)

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  data_file = "data/ml_training_data.rds",
  model_file = "models/connection_predictor_v2_graph_aware.pt",
  embedding_dim = 128,
  batch_size = 32
)

cat("\n==================================================================\n")
cat("  PHASE 2: Model Evaluation\n")
cat("==================================================================\n\n")

# ==============================================================================
# Load Model and Data
# ==============================================================================

cat("Loading trained Phase 2 model...\n")
if (!file.exists(CONFIG$model_file)) {
  stop(sprintf("Model file not found: %s\nPlease train the model first using train_connection_predictor_v2.R", CONFIG$model_file))
}

model <- torch_load(CONFIG$model_file)
model$eval()
cat(sprintf("  ✓ Model loaded: %s\n\n", CONFIG$model_file))

cat("Loading test data...\n")
training_data <- readRDS(CONFIG$data_file)
test_data <- training_data$test

cat(sprintf("  Test set: %d examples\n", nrow(test_data)))

# Check for graph features
has_graph_features <- !is.null(training_data$test_graph_features)
if (has_graph_features) {
  cat(sprintf("  ✓ Graph features available: %d dims\n", ncol(training_data$test_graph_features)))
} else {
  cat("  ℹ No graph features. Using zero-padding.\n")
}
cat("\n")

# ==============================================================================
# Prepare Test Features
# ==============================================================================

cat("Preparing test features...\n")

# Element features (270 dims: 2x128 embeddings + 2x7 types)
n_test <- nrow(test_data)
test_elem_features <- matrix(0, nrow = n_test, ncol = 270)

for (i in 1:n_test) {
  # Create embeddings
  source_emb <- create_element_embedding(test_data$source_name[i], CONFIG$embedding_dim)
  target_emb <- create_element_embedding(test_data$target_name[i], CONFIG$embedding_dim)

  # Encode types
  source_type <- encode_dapsiwrm_type(test_data$source_type[i])
  target_type <- encode_dapsiwrm_type(test_data$target_type[i])

  # Combine: 128 + 128 + 7 + 7 = 270
  test_elem_features[i, ] <- c(source_emb, target_emb, source_type, target_type)
}

# Context indices
test_context_indices <- lapply(1:nrow(test_data), function(i) {
  prepare_context_indices(
    regional_sea = test_data$regional_sea[i],
    ecosystem_types = test_data$ecosystem_types[i],
    main_issues = test_data$main_issues[i]
  )
})

# Graph features
if (has_graph_features) {
  test_graph_features <- training_data$test_graph_features
} else {
  test_graph_features <- matrix(0, nrow = nrow(test_data), ncol = 8)
}

cat("  ✓ Features prepared\n\n")

# ==============================================================================
# Run Predictions
# ==============================================================================

cat("Running predictions on test set...\n")

test_elem_tensor <- torch_tensor(test_elem_features, dtype = torch_float())
test_graph_tensor <- torch_tensor(test_graph_features, dtype = torch_float())

all_predictions <- list()

with_no_grad({
  # Batch predictions for efficiency
  for (i in seq(1, n_test, by = CONFIG$batch_size)) {
    batch_end <- min(i + CONFIG$batch_size - 1, n_test)
    batch_indices <- i:batch_end
    batch_size_actual <- length(batch_indices)

    # Prepare batch
    batch_elem <- test_elem_tensor[batch_indices, ]
    batch_graph <- test_graph_tensor[batch_indices, ]

    # Prepare context tensors
    batch_context <- test_context_indices[batch_indices]

    # Extract indices - take first value for multi-hot
    sea_indices <- sapply(batch_context, function(ctx) as.numeric(ctx$sea_idx)[1])
    eco_indices <- sapply(batch_context, function(ctx) as.numeric(ctx$eco_idx)[1])
    issue_indices <- sapply(batch_context, function(ctx) as.numeric(ctx$issue_idx)[1])

    # Convert to tensors (shape should be (batch,) not (batch, 1))
    sea_idx <- torch_tensor(sea_indices, dtype = torch_long())
    eco_idx <- torch_tensor(eco_indices, dtype = torch_long())
    issue_idx <- torch_tensor(issue_indices, dtype = torch_long())

    context_data <- list(
      sea_idx = sea_idx,
      eco_idx = eco_idx,
      issue_idx = issue_idx
    )

    # Forward pass
    predictions <- model(batch_elem, context_data, batch_graph)
    all_predictions[[length(all_predictions) + 1]] <- predictions
  }
})

cat("  ✓ Predictions complete\n\n")

# ==============================================================================
# Calculate Metrics
# ==============================================================================

cat("Calculating evaluation metrics...\n\n")

# Combine all predictions
existence_probs <- torch_cat(lapply(all_predictions, function(p) p$existence), dim = 1)
strength_logits <- torch_cat(lapply(all_predictions, function(p) p$strength), dim = 1)
confidence_preds <- torch_cat(lapply(all_predictions, function(p) p$confidence), dim = 1)
polarity_probs <- torch_cat(lapply(all_predictions, function(p) p$polarity), dim = 1)

# Ground truth
gt_existence <- as.numeric(test_data$connection_exists)
gt_strength <- sapply(test_data$strength, function(s) {
  if (is.na(s) || s == "") return(2L)
  strength_map <- c("weak" = 1L, "medium" = 2L, "strong" = 3L)
  val <- strength_map[tolower(as.character(s))]
  if (is.na(val)) 2L else as.integer(val)
})
gt_confidence <- sapply(test_data$confidence, function(c) {
  if (is.na(c)) 3.0 else as.numeric(c)
})
gt_polarity <- sapply(test_data$polarity, function(p) {
  if (is.na(p) || p == "") 1.0 else if (as.character(p) == "+") 1.0 else 0.0
})

# === Existence Accuracy ===
pred_existence <- as.numeric(existence_probs > 0.5)
existence_accuracy <- mean(pred_existence == gt_existence)

# Existence F1 Score
tp <- sum(pred_existence == 1 & gt_existence == 1)
fp <- sum(pred_existence == 1 & gt_existence == 0)
fn <- sum(pred_existence == 0 & gt_existence == 1)
precision <- ifelse(tp + fp > 0, tp / (tp + fp), 0)
recall <- ifelse(tp + fn > 0, tp / (tp + fn), 0)
f1 <- ifelse(precision + recall > 0, 2 * precision * recall / (precision + recall), 0)

# === Strength Accuracy ===
strength_preds <- as.numeric(strength_logits$argmax(dim = 2))
# Filter to only positive examples
positive_indices <- which(gt_existence == 1)
if (length(positive_indices) > 0) {
  strength_accuracy <- mean(strength_preds[positive_indices] == gt_strength[positive_indices])
} else {
  strength_accuracy <- NA
}

# === Confidence MAE ===
confidence_mae <- mean(abs(as.numeric(confidence_preds) - gt_confidence))

# === Polarity Accuracy ===
pred_polarity <- as.numeric(polarity_probs > 0.5)
if (length(positive_indices) > 0) {
  polarity_accuracy <- mean(pred_polarity[positive_indices] == gt_polarity[positive_indices])
} else {
  polarity_accuracy <- NA
}

# ==============================================================================
# Print Results
# ==============================================================================

cat("==================================================================\n")
cat("  PHASE 2 TEST SET RESULTS\n")
cat("==================================================================\n\n")

cat("Overall Metrics:\n")
cat(sprintf("  Existence Accuracy: %.2f%% (Phase 1 baseline: 82.6%%)\n", existence_accuracy * 100))
cat(sprintf("  Existence F1 Score: %.3f\n", f1))
cat(sprintf("  Precision: %.3f | Recall: %.3f\n\n", precision, recall))

cat("Task-Specific Metrics:\n")
cat(sprintf("  Strength Accuracy: %.2f%%\n", ifelse(is.na(strength_accuracy), 0, strength_accuracy * 100)))
cat(sprintf("  Confidence MAE: %.3f\n", confidence_mae))
cat(sprintf("  Polarity Accuracy: %.2f%%\n\n", ifelse(is.na(polarity_accuracy), 0, polarity_accuracy * 100)))

# Breakdown by template
cat("Per-Template Breakdown:\n")
for (template_name in unique(test_data$template)) {
  template_indices <- which(test_data$template == template_name)
  template_acc <- mean(pred_existence[template_indices] == gt_existence[template_indices])
  cat(sprintf("  %s: %.2f%% (n=%d)\n",
              template_name, template_acc * 100, length(template_indices)))
}

cat("\n==================================================================\n")

# Check if target met
if (existence_accuracy >= 0.87) {
  cat("✓ TARGET MET: Achieved 87-90% accuracy goal!\n")
} else if (existence_accuracy >= 0.83) {
  cat("⚠ CLOSE: Within 4% of target. Consider additional training.\n")
} else {
  cat("✗ TARGET MISSED: Below 87% target. Recommendations:\n")
  cat("  1. Increase training epochs\n")
  cat("  2. Adjust learning rate\n")
  cat("  3. Increase dropout regularization\n")
  cat("  4. Verify graph features are being used\n")
}

cat("==================================================================\n\n")

# Save detailed results
results <- list(
  overall = list(
    existence_accuracy = existence_accuracy,
    existence_f1 = f1,
    precision = precision,
    recall = recall,
    strength_accuracy = strength_accuracy,
    confidence_mae = confidence_mae,
    polarity_accuracy = polarity_accuracy
  ),
  predictions = data.frame(
    template = test_data$template,
    source = test_data$source_name,
    target = test_data$target_name,
    gt_exists = gt_existence,
    pred_exists = pred_existence,
    pred_prob = as.numeric(existence_probs),
    correct = pred_existence == gt_existence
  ),
  metadata = list(
    model_file = CONFIG$model_file,
    test_size = nrow(test_data),
    evaluation_date = Sys.time()
  )
)

results_file <- "models/evaluation_results_v2.rds"
saveRDS(results, results_file)
cat(sprintf("✓ Detailed results saved: %s\n\n", results_file))
