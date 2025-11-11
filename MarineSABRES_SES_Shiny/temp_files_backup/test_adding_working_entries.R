#!/usr/bin/env Rscript
# Test if we can add existing working entries to a subset

library(jsonlite)
library(shiny.i18n)

cat("Loading working backup...\n")
working <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = FALSE)
cat("  Total entries:", length(working$translation), "\n")

# Test 1: Can we load the full working file?
cat("\n=== TEST 1: Load full working file ===\n")
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "translations/translation_backup_20251103_232419.json")
  cat("✓ Full file loads successfully\n")
  cat("  Total keys:", length(test_i18n$get_key_translation()), "\n")
}, error = function(e) {
  cat("✗ Full file fails:", conditionMessage(e), "\n")
})

# Test 2: Create a subset with first 100 entries
cat("\n=== TEST 2: Create subset with 100 entries ===\n")
subset_100 <- list(translation = working$translation[1:100])
write_json(subset_100, 'test_subset_100.json', pretty = TRUE, auto_unbox = TRUE)
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "test_subset_100.json")
  cat("✓ Subset of 100 loads successfully\n")
}, error = function(e) {
  cat("✗ Subset fails:", conditionMessage(e), "\n")
})

# Test 3: Add entry 101 from working file to the subset
cat("\n=== TEST 3: Add entry 101 (from working file) to subset ===\n")
subset_101 <- list(translation = working$translation[1:101])
write_json(subset_101, 'test_subset_101.json', pretty = TRUE, auto_unbox = TRUE)
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "test_subset_101.json")
  cat("✓ Adding one more working entry succeeds\n")
}, error = function(e) {
  cat("✗ Adding entry fails:", conditionMessage(e), "\n")
})

# Test 4: Can we add entry 857 (a new one) to the full working file?
cat("\n=== TEST 4: Add one more entry to full working file ===\n")
test_857 <- list(translation = c(working$translation, working$translation[[1]]))  # Duplicate first entry
write_json(test_857, 'test_857.json', pretty = TRUE, auto_unbox = TRUE)
tryCatch({
  test_i18n <- Translator$new(translation_json_path = "test_857.json")
  cat("✓ Adding entry 857 succeeds (even if duplicate)\n")
}, error = function(e) {
  cat("✗ Adding entry 857 fails:", conditionMessage(e), "\n")
})

# Clean up
cat("\nCleaning up test files...\n")
test_files <- c('test_subset_100.json', 'test_subset_101.json', 'test_857.json')
for (f in test_files) {
  if (file.exists(f)) file.remove(f)
}
