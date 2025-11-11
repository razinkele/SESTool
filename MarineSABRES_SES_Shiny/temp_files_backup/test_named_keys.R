library(shiny.i18n)

# Test if shiny.i18n supports named key format
i18n_test <- Translator$new(translation_json_path = "test_translation_format.json")
i18n_test$set_translation_language("en")

cat("Testing named key format:\n")
cat("1. Using key 'test_key_1':", i18n_test$t("test_key_1"), "\n")
cat("2. Using key 'test_key_2':", i18n_test$t("test_key_2"), "\n")

i18n_test$set_translation_language("es")
cat("\nTesting in Spanish:\n")
cat("1. Using key 'test_key_1':", i18n_test$t("test_key_1"), "\n")
cat("2. Using key 'test_key_2':", i18n_test$t("test_key_2"), "\n")
