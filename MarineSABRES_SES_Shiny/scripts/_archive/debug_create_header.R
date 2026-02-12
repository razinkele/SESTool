#!/usr/bin/env Rscript
# Debug what create_module_header does

source("functions/translation_loader.R")

# Initialize translation system
translation_system <- init_translation_system(
  base_path = "translations",
  debug = FALSE,
  persistent = TRUE,
  use_direct_lookup = TRUE
)

i18n_translator <- translation_system$translator
t_ <- translation_system$wrapper

# Create wrapped i18n object (same as global.R)
i18n <- list(
  t = t_,
  set_translation_language = function(lang) {
    i18n_translator$set_translation_language(lang)
  },
  get_translation_language = function() {
    i18n_translator$get_translation_language()
  },
  translator = i18n_translator
)

# Set to English (default)
i18n$set_translation_language("en")

cat("=== Simulating create_module_header behavior ===\n\n")

# Simulate what create_module_header does
title_key <- "modules.cld.visualization.title"
subtitle_key <- "modules.cld.visualization.subtitle"

cat("Step 1: Wrapper translates key to English text\n")
title_en <- i18n$t(title_key)
subtitle_en <- i18n$t(subtitle_key)

cat(sprintf("  title_key '%s' => '%s'\n", title_key, title_en))
cat(sprintf("  subtitle_key => '%s'\n", substr(subtitle_en, 1, 60)))

cat("\nStep 2: Pass English text to translator\n")
cat("  Current language:", i18n$get_translation_language(), "\n")
result_en <- i18n$translator$t(title_en)
cat(sprintf("  translator$t('%s') => '%s'\n", title_en, result_en))

cat("\nStep 3: Change language to French\n")
i18n$set_translation_language("fr")
cat("  Current language:", i18n$get_translation_language(), "\n")
result_fr <- i18n$translator$t(title_en)
cat(sprintf("  translator$t('%s') => '%s'\n", title_en, result_fr))

cat("\nStep 4: Change language to Spanish\n")
i18n$set_translation_language("es")
cat("  Current language:", i18n$get_translation_language(), "\n")
result_es <- i18n$translator$t(title_en)
cat(sprintf("  translator$t('%s') => '%s'\n", title_en, result_es))

cat("\n=== PROBLEM IDENTIFIED ===\n")
cat("The wrapper is called ONCE at UI build time.\n")
cat("It returns English text based on language at that moment.\n")
cat("That English text is then used for all language switches.\n")
cat("This works IF the app starts in English.\n")
cat("But if app starts in another language, wrapper returns non-English text!\n")
