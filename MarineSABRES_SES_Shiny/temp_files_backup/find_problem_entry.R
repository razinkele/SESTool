library(jsonlite)
library(shiny.i18n)

ai_isa <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = FALSE)
all_entries <- ai_isa$translation

cat("Testing subsets to find problematic entry...\n\n")

# Binary search to find the problem
test_subset <- function(entries, start_idx, end_idx) {
  subset <- list(translation = entries[start_idx:end_idx])
  write_json(subset, 'test_subset.json', pretty = TRUE, auto_unbox = TRUE)
  
  tryCatch({
    test <- Translator$new(translation_json_path = "test_subset.json")
    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  })
}

# Test first 50
if (test_subset(all_entries, 1, 50)) {
  cat("✓ Entries 1-50: OK\n")
} else {
  cat("✗ Entries 1-50: FAIL\n")
}

# Test 51-100
if (test_subset(all_entries, 51, 100)) {
  cat("✓ Entries 51-100: OK\n")
} else {
  cat("✗ Entries 51-100: FAIL\n")
}

# Test 101-150
if (test_subset(all_entries, 101, 150)) {
  cat("✓ Entries 101-150: OK\n")
} else {
  cat("✗ Entries 101-150: FAIL\n")
}

# Test 151-178
if (test_subset(all_entries, 151, 178)) {
  cat("✓ Entries 151-178: OK\n")
} else {
  cat("✗ Entries 151-178: FAIL\n")
}
