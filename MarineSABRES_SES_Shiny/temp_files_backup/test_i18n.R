library(shiny.i18n)

i18n_test <- Translator$new(translation_json_path = "translations/translation.json")
i18n_test$set_translation_language("en")

cat("Testing tooltip translations:\n")
cat("1. ep_tooltip_skip_not_sure:", i18n_test$t("ep_tooltip_skip_not_sure"), "\n")
cat("2. ep_tooltip_proceed_needs:", i18n_test$t("ep_tooltip_proceed_needs"), "\n")
cat("3. ep_tooltip_role_help:", i18n_test$t("ep_tooltip_role_help"), "\n")

cat("\nTesting known working translation:\n")
cat("4. Entry Point 0\\: Who Are You?:", i18n_test$t("Entry Point 0: Who Are You?"), "\n")

cat("\nAll keys containing 'ep_tooltip':\n")
all_keys <- i18n_test$get_key_translation()
tooltip_keys <- names(all_keys)[grepl("ep_tooltip", names(all_keys))]
cat(paste(tooltip_keys, collapse = "\n"), "\n")
