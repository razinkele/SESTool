library(jsonlite)
library(shiny.i18n)

# Load and test
i18n <- Translator$new(translation_json_path = "translations/translation.json")
i18n$set_translation_language("es")

# Test the specific strings
test_strings <- c(
  "AI-Assisted ISA Creation",
  "Let me guide you step-by-step through building your DAPSI(W)R(M) model."
)

for (s in test_strings) {
  translation <- i18n$t(s)
  cat(sprintf("EN: %s\n", s))
  cat(sprintf("ES: %s\n\n", translation))
}
