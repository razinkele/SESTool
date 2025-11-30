# Test translation system
source("global.R")

cat("\n=== Translation System Test ===\n")
cat("Current language:", i18n$get_translation_language(), "\n\n")

# Test 1: Direct English text lookup (how shiny.i18n normally works)
cat("Test 1 - Direct English lookup:\n")
result1 <- i18n$translator$t("Getting Started")
cat("  i18n$translator$t('Getting Started'):", result1, "\n\n")

# Test 2: Namespaced key through wrapper
cat("Test 2 - Namespaced key through wrapper:\n")
result2 <- i18n$t("ui.sidebar.getting_started")
cat("  i18n$t('ui.sidebar.getting_started'):", result2, "\n\n")

# Test 3: Try changing language
cat("Test 3 - Change language to Spanish:\n")
i18n$set_translation_language("es")
cat("  Current language:", i18n$get_translation_language(), "\n")
result3 <- i18n$t("ui.sidebar.getting_started")
cat("  i18n$t('ui.sidebar.getting_started'):", result3, "\n\n")

# Test 4: Check if reverse mapping works
cat("Test 4 - Check reverse mapping:\n")
cat("  Looking for key: ui.sidebar.getting_started\n")
# Read reverse mapping
mapping <- jsonlite::fromJSON("scripts/reverse_key_mapping.json")
cat("  Maps to:", mapping[["ui.sidebar.getting_started"]], "\n\n")
