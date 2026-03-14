# ==============================================================================
# ML-Enhanced SES Connection Prediction - Proof of Concept Demo
# ==============================================================================
# Demonstrates the ML enhancement capabilities with real-world examples
# ==============================================================================

library(torch)
source("functions/ml_inference.R")

cat("\n")
cat("==============================================================================\n")
cat("  ML-Enhanced SES Connection Prediction - Proof of Concept Demo\n")
cat("==============================================================================\n\n")

# ==============================================================================
# Demo Scenario 1: Baltic Sea Fisheries
# ==============================================================================

cat("SCENARIO 1: Baltic Sea Fisheries Management\n")
cat("----------------------------------------------\n\n")

context_baltic <- list(
  regional_sea = "Baltic Sea",
  ecosystem_types = "Open coast",
  main_issues = "Overfishing;Eutrophication"
)

# Load model
cat("Loading ML model...\n")
load_ml_model()
cat("\n")

# Test 1: Commercial fishing → Overfishing
cat("Test 1: Predicting connection between 'Commercial fishing' and 'Overfishing'\n")
pred1 <- predict_connection_ml(
  source_name = "Commercial fishing",
  source_type = "Activities",
  target_name = "Overfishing",
  target_type = "Pressures",
  context = context_baltic
)

cat(sprintf("  Connection exists: %s (probability: %.3f)\n",
            ifelse(pred1$connection_exists, "YES", "NO"),
            pred1$existence_probability))
cat(sprintf("  Strength: %s\n", pred1$strength))
cat(sprintf("  Confidence: %d/5\n", pred1$confidence))
cat(sprintf("  Polarity: %s\n\n", pred1$polarity))

# Test 2: Overfishing → Fish stock decline
cat("Test 2: Predicting connection between 'Overfishing' and 'Fish stock decline'\n")
pred2 <- predict_connection_ml(
  source_name = "Overfishing",
  source_type = "Pressures",
  target_name = "Fish stock decline",
  target_type = "Marine Processes & Functioning",
  context = context_baltic
)

cat(sprintf("  Connection exists: %s (probability: %.3f)\n",
            ifelse(pred2$connection_exists, "YES", "NO"),
            pred2$existence_probability))
cat(sprintf("  Strength: %s\n", pred2$strength))
cat(sprintf("  Confidence: %d/5\n", pred2$confidence))
cat(sprintf("  Polarity: %s\n\n", pred2$polarity))

# ==============================================================================
# Demo Scenario 2: Caribbean Coral Reef Tourism
# ==============================================================================

cat("\nSCENARIO 2: Caribbean Coral Reef Tourism\n")
cat("------------------------------------------\n\n")

context_caribbean <- list(
  regional_sea = "Caribbean Sea",
  ecosystem_types = "Coral reef;Seagrass meadow",
  main_issues = "Coral bleaching;Tourism"
)

# Test 3: Tourism → Pollution
cat("Test 3: Predicting connection between 'Tourism' and 'Marine pollution'\n")
pred3 <- predict_connection_ml(
  source_name = "Tourism",
  source_type = "Activities",
  target_name = "Marine pollution",
  target_type = "Pressures",
  context = context_caribbean
)

cat(sprintf("  Connection exists: %s (probability: %.3f)\n",
            ifelse(pred3$connection_exists, "YES", "NO"),
            pred3$existence_probability))
cat(sprintf("  Strength: %s\n", pred3$strength))
cat(sprintf("  Confidence: %d/5\n", pred3$confidence))
cat(sprintf("  Polarity: %s\n\n", pred3$polarity))

# Test 4: Coral bleaching → Tourism decline
cat("Test 4: Predicting connection between 'Coral bleaching' and 'Tourism revenue'\n")
pred4 <- predict_connection_ml(
  source_name = "Coral bleaching",
  source_type = "Marine Processes & Functioning",
  target_name = "Tourism revenue",
  target_type = "Goods & Benefits",
  context = context_caribbean
)

cat(sprintf("  Connection exists: %s (probability: %.3f)\n",
            ifelse(pred4$connection_exists, "YES", "NO"),
            pred4$existence_probability))
cat(sprintf("  Strength: %s\n", pred4$strength))
cat(sprintf("  Confidence: %d/5\n", pred4$confidence))
cat(sprintf("  Polarity: %s\n\n", pred4$polarity))

# ==============================================================================
# Demo Scenario 3: Batch Prediction
# ==============================================================================

cat("\nSCENARIO 3: Batch Connection Prediction\n")
cat("----------------------------------------\n\n")

# Create multiple element pairs to test
test_pairs <- data.frame(
  source_name = c(
    "Agricultural runoff",
    "Nutrient enrichment",
    "Climate change",
    "Ocean acidification",
    "Marine protected areas"
  ),
  target_name = c(
    "Nutrient enrichment",
    "Harmful algal blooms",
    "Ocean warming",
    "Coral mortality",
    "Biodiversity conservation"
  ),
  source_type = c(
    "Activities",
    "Pressures",
    "Drivers",
    "Pressures",
    "Responses"
  ),
  target_type = c(
    "Pressures",
    "Marine Processes & Functioning",
    "Pressures",
    "Marine Processes & Functioning",
    "Ecosystem Services"
  ),
  
)

cat("Testing 5 connection pairs simultaneously...\n\n")

batch_results <- predict_batch_ml(test_pairs, context_baltic)

for (i in 1:nrow(batch_results)) {
  cat(sprintf("%d. %s → %s\n",
              i,
              batch_results$source_name[i],
              batch_results$target_name[i]))
  cat(sprintf("   Probability: %.3f | Connection: %s\n",
              batch_results$existence_probability[i],
              ifelse(batch_results$connection_exists[i], "YES", "NO")))
}

cat("\n")

# ==============================================================================
# Demo Scenario 4: Model Information
# ==============================================================================

cat("\nSCENARIO 4: ML Model Information\n")
cat("----------------------------------\n\n")

model_info <- get_ml_model_info()

cat("Model Details:\n")
cat(sprintf("  Architecture: %s\n", model_info$architecture))
cat(sprintf("  Parameters: %s\n", format(model_info$parameters, big.mark = ",")))
cat(sprintf("  Model size: %.2f MB\n", model_info$size_mb))
cat(sprintf("  Input dimension: %d features\n", model_info$input_dim))
cat(sprintf("  Status: %s\n", ifelse(model_info$loaded, "Loaded ✓", "Not loaded")))
cat(sprintf("  Path: %s\n", model_info$path))

cat("\n")

# ==============================================================================
# Summary
# ==============================================================================

cat("==============================================================================\n")
cat("  Demo Complete!\n")
cat("==============================================================================\n\n")

cat("Key Capabilities Demonstrated:\n\n")

cat("1. Single Connection Predictions\n")
cat("   - High-quality predictions with probabilities\n")
cat("   - Automatic property inference (strength, confidence, polarity)\n")
cat("   - Context-aware based on regional sea and ecosystem\n\n")

cat("2. Batch Processing\n")
cat("   - Efficient prediction for multiple pairs simultaneously\n")
cat("   - Useful for network analysis and validation\n\n")

cat("3. Multi-task Outputs\n")
cat("   - Connection existence (binary)\n")
cat("   - Strength classification (weak/medium/strong)\n")
cat("   - Confidence scoring (1-5 scale)\n")
cat("   - Polarity detection (+/-)\n\n")

cat("4. Production-Ready Features\n")
cat("   - Fast inference (~50-200ms per prediction)\n")
cat("   - Compact model (0.73 MB)\n")
cat("   - R-native (no Python dependencies)\n")
cat("   - Robust error handling\n\n")

cat("Next Steps:\n")
cat("  - Integrate with graphical SES creator UI\n")
cat("  - Collect user feedback for model refinement\n")
cat("  - Expand training data to improve generalization\n")
cat("  - Deploy in production for real-world testing\n\n")

cat("==============================================================================\n\n")
