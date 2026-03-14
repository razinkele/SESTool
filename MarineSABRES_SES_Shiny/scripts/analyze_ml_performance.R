# ==============================================================================
# ML Model Performance Analysis
# ==============================================================================
# Comprehensive evaluation of the trained connection predictor model
#
# Analyzes:
# - Test set performance (Baltic, Climate, Wind templates)
# - Confusion matrices
# - Per-class metrics
# - Comparison with baseline
# ==============================================================================

library(torch)
library(dplyr)
library(ggplot2)

source("functions/ml_feature_engineering.R")
source("functions/ml_models.R")
source("functions/ml_inference.R")

# ==============================================================================
# Configuration
# ==============================================================================

CONFIG <- list(
  data_file = "data/ml_training_data.rds",
  model_file = "models/connection_predictor_best.pt",
  output_dir = "models/analysis",
  embedding_dim = 128
)

# Create output directory
if (!dir.exists(CONFIG$output_dir)) {
  dir.create(CONFIG$output_dir, recursive = TRUE)
}

# ==============================================================================
# Load Data and Model
# ==============================================================================

cat("\n==============================================================\n")
cat("  ML Model Performance Analysis\n")
cat("==============================================================\n\n")

cat("Loading data and model...\n")
training_data <- readRDS(CONFIG$data_file)
load_ml_model(CONFIG$model_file)

cat(sprintf("  Train set: %d examples\n", nrow(training_data$train)))
cat(sprintf("  Validation set: %d examples\n", nrow(training_data$validation)))
cat(sprintf("  Test set: %d examples\n", nrow(training_data$test)))
cat("\n")

# ==============================================================================
# Test Set Evaluation
# ==============================================================================

cat("Evaluating on test set...\n")

# Create feature matrix for test set
test_features <- create_feature_matrix(training_data$test, CONFIG$embedding_dim)

# Prepare targets
test_targets <- list(
  existence = torch_tensor(as.numeric(training_data$test$connection_exists), dtype = torch_float())$view(c(-1, 1)),
  strength = torch_tensor(rep(2L, nrow(training_data$test)), dtype = torch_long()),  # Placeholder
  confidence = torch_tensor(rep(3.0, nrow(training_data$test)), dtype = torch_float())$view(c(-1, 1)),
  polarity = torch_tensor(rep(1.0, nrow(training_data$test)), dtype = torch_float())$view(c(-1, 1))
)

# Convert to tensors
x_test <- torch_tensor(test_features, dtype = torch_float())

# Make predictions
with_no_grad({
  predictions <- .ml_env$model(x_test)
})

# ==============================================================================
# Calculate Metrics
# ==============================================================================

# Existence predictions
existence_probs <- torch_sigmoid(predictions$existence)$cpu()$squeeze()
existence_preds <- (existence_probs >= 0.5)$to(dtype = torch_float())
existence_targets <- test_targets$existence$cpu()$squeeze()

# Accuracy
accuracy <- (existence_preds == existence_targets)$sum()$item() / existence_targets$numel()

# Confusion matrix
tp <- ((existence_preds == 1) & (existence_targets == 1))$sum()$item()
tn <- ((existence_preds == 0) & (existence_targets == 0))$sum()$item()
fp <- ((existence_preds == 1) & (existence_targets == 0))$sum()$item()
fn <- ((existence_preds == 0) & (existence_targets == 1))$sum()$item()

# Precision, Recall, F1
precision <- if (tp + fp > 0) tp / (tp + fp) else 0
recall <- if (tp + fn > 0) tp / (tp + fn) else 0
f1 <- if (precision + recall > 0) 2 * (precision * recall) / (precision + recall) else 0

# ==============================================================================
# Print Results
# ==============================================================================

cat("\n==============================================================\n")
cat("  Test Set Performance\n")
cat("==============================================================\n\n")

cat(sprintf("Total test examples: %d\n", existence_targets$numel()))
cat(sprintf("Positive examples: %d (%.1f%%)\n",
            sum(as.numeric(existence_targets)),
            100 * sum(as.numeric(existence_targets)) / existence_targets$numel()))
cat(sprintf("Negative examples: %d (%.1f%%)\n\n",
            existence_targets$numel() - sum(as.numeric(existence_targets)),
            100 * (1 - sum(as.numeric(existence_targets)) / existence_targets$numel())))

cat("Confusion Matrix:\n")
cat(sprintf("                  Predicted\n"))
cat(sprintf("                  No    Yes\n"))
cat(sprintf("Actual No      %4d  %4d\n", tn, fp))
cat(sprintf("Actual Yes     %4d  %4d\n\n", fn, tp))

cat("Performance Metrics:\n")
cat(sprintf("  Accuracy:  %.3f (%.1f%%)\n", accuracy, accuracy * 100))
cat(sprintf("  Precision: %.3f\n", precision))
cat(sprintf("  Recall:    %.3f\n", recall))
cat(sprintf("  F1 Score:  %.3f\n\n", f1))

# ==============================================================================
# Per-Template Analysis
# ==============================================================================

cat("==============================================================\n")
cat("  Per-Template Analysis\n")
cat("==============================================================\n\n")

test_templates <- unique(training_data$test$template)

for (template in test_templates) {
  template_indices <- which(training_data$test$template == template)

  if (length(template_indices) == 0) next

  template_preds <- existence_preds[template_indices]
  template_targets <- existence_targets[template_indices]

  template_accuracy <- (template_preds == template_targets)$sum()$item() / length(template_indices)

  cat(sprintf("%s:\n", template))
  cat(sprintf("  Examples: %d\n", length(template_indices)))
  cat(sprintf("  Accuracy: %.3f (%.1f%%)\n\n",
              template_accuracy, template_accuracy * 100))
}

# ==============================================================================
# Probability Distribution Analysis
# ==============================================================================

cat("==============================================================\n")
cat("  Probability Distribution\n")
cat("==============================================================\n\n")

probs_numeric <- as.numeric(existence_probs)
targets_numeric <- as.numeric(existence_targets)

# Statistics for positive vs negative examples
pos_probs <- probs_numeric[targets_numeric == 1]
neg_probs <- probs_numeric[targets_numeric == 0]

cat("Positive Examples (True Connections):\n")
cat(sprintf("  Mean probability: %.3f\n", mean(pos_probs)))
cat(sprintf("  Median probability: %.3f\n", median(pos_probs)))
cat(sprintf("  Min: %.3f, Max: %.3f\n\n", min(pos_probs), max(pos_probs)))

cat("Negative Examples (No Connection):\n")
cat(sprintf("  Mean probability: %.3f\n", mean(neg_probs)))
cat(sprintf("  Median probability: %.3f\n", median(neg_probs)))
cat(sprintf("  Min: %.3f, Max: %.3f\n\n", min(neg_probs), max(neg_probs)))

# ==============================================================================
# Save Results
# ==============================================================================

# Save predictions
test_results <- data.frame(
  template = training_data$test$template,
  source_name = training_data$test$source_name,
  target_name = training_data$test$target_name,
  true_label = as.numeric(existence_targets),
  predicted_prob = probs_numeric,
  predicted_label = as.numeric(existence_preds),
  correct = as.numeric(existence_preds == existence_targets)
)

output_file <- file.path(CONFIG$output_dir, "test_predictions.csv")
write.csv(test_results, output_file, row.names = FALSE)
cat(sprintf("✓ Saved predictions to: %s\n", output_file))

# Save metrics
metrics <- list(
  test_accuracy = accuracy,
  test_precision = precision,
  test_recall = recall,
  test_f1 = f1,
  confusion_matrix = list(tp = tp, tn = tn, fp = fp, fn = fn),
  n_test = existence_targets$numel(),
  n_positive = sum(as.numeric(existence_targets)),
  n_negative = existence_targets$numel() - sum(as.numeric(existence_targets))
)

metrics_file <- file.path(CONFIG$output_dir, "test_metrics.rds")
saveRDS(metrics, metrics_file)
cat(sprintf("✓ Saved metrics to: %s\n", metrics_file))

cat("\n==============================================================\n")
cat("✓ Performance analysis complete!\n")
cat("==============================================================\n")
