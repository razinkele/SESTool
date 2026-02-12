# Debug translation flow
source("global.R")

cat("\n=== TESTING TRANSLATION FLOW ===\n\n")

# Test 1: Check current language
cat("1. Initial language:", i18n$get_translation_language(), "\n")

# Test 2: Try calling a key
cat("2. Test key 'ui.header.language':", i18n$t("ui.header.language"), "\n")

# Test 3: Change language
cat("\n3. Changing language to Spanish...\n")
i18n$set_translation_language("es")
cat("   Current language:", i18n$get_translation_language(), "\n")

# Test 4: Call same key after language change
cat("4. Test key after change:", i18n$t("ui.header.language"), "\n")

# Test 5: Test underlying translator
cat("\n5. Testing underlying translator directly:\n")
cat("   Translator language:", i18n$translator$get_translation_language(), "\n")
cat("   Translator t('Language'):", i18n$translator$t("Language"), "\n")

# Test 6: Check if wrapper and translator are in sync
cat("\n6. Checking sync between wrapper and translator:\n")
cat("   Wrapper language:", i18n$get_translation_language(), "\n")
cat("   Translator language:", i18n$translator$get_translation_language(), "\n")
cat("   Are they equal?", i18n$get_translation_language() == i18n$translator$get_translation_language(), "\n")
