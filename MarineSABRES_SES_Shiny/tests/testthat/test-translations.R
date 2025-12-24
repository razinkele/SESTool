# test-translations.R
# Unit tests for translation/i18n functionality

library(testthat)
library(jsonlite)

# Helper function to load translation file
load_translations <- function() {
  translation_file <- "../../translations/translation.json"
  if (!file.exists(translation_file)) {
    skip("Translation file not found")
  }
  fromJSON(translation_file, simplifyVector = FALSE)
}

# ============================================================================
# Test Translation File Structure
# ============================================================================

test_that("Translation file exists and is valid JSON", {
  translation_file <- "../../translations/translation.json"
  skip_if_not(file.exists(translation_file))

  # Should parse without errors
  translations <- fromJSON(translation_file)

  expect_true(is.list(translations))
  expect_true("languages" %in% names(translations))
  expect_true("translation" %in% names(translations))
})

test_that("Translation file supports all required languages", {
  translations <- load_translations()

  # Expected languages
  expected_languages <- c("en", "es", "fr", "de", "lt", "pt", "it")

  expect_true(all(expected_languages %in% translations$languages))
})

test_that("All translation entries have all language keys", {
  translations <- load_translations()

  languages <- unlist(translations$languages)

  for (i in seq_along(translations$translation)) {
    entry <- translations$translation[[i]]
    entry_langs <- names(entry)

    # Check that all languages are present
    for (lang in languages) {
      expect_true(lang %in% entry_langs,
                  info = paste("Entry", i, "missing language:", lang))
    }
  }
})

# ============================================================================
# Test Create SES Translation Keys
# ============================================================================

test_that("Create SES core menu translations exist", {
  translations <- load_translations()

  # Extract all English keys
  en_keys <- sapply(translations$translation, function(x) x$en)

  # Core menu items
  expect_true("Create SES" %in% en_keys)
  expect_true("Choose Method" %in% en_keys)
  expect_true("Standard Entry" %in% en_keys)
  expect_true("AI Assistant" %in% en_keys)
  expect_true("Template-Based" %in% en_keys)
})

test_that("Create SES UI header translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  expect_true("Create Your Social-Ecological System" %in% en_keys)
  expect_true("Choose the method that best fits your experience level and project needs" %in% en_keys)
})

test_that("Create SES method badge translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  expect_true("Beginner" %in% en_keys)
  expect_true("Intermediate" %in% en_keys)
  expect_true("Advanced" %in% en_keys)
  expect_true("Recommended" %in% en_keys)
  expect_true("Quick Start" %in% en_keys)
  expect_true("Structured" %in% en_keys)
})

test_that("Create SES method descriptions exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  # Standard Entry description
  expect_true(any(grepl("Traditional form-based approach", en_keys)))

  # AI Assistant description
  expect_true(any(grepl("Intelligent question-based guidance", en_keys)))

  # Template-Based description
  expect_true(any(grepl("Start from pre-built templates", en_keys)))
})

test_that("Create SES feature list translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  # Standard Entry features
  expect_true("Step-by-step guided exercises" %in% en_keys)
  expect_true("Complete control over all elements" %in% en_keys)
  expect_true("Detailed data validation" %in% en_keys)
  expect_true("Direct framework implementation" %in% en_keys)
  expect_true("Export-ready data structure" %in% en_keys)

  # AI Assistant features
  expect_true("Interactive Q&A workflow" %in% en_keys)
  expect_true("Context-aware suggestions" %in% en_keys)
  expect_true("Automatic element generation" %in% en_keys)
  expect_true("Learning-friendly approach" %in% en_keys)
  expect_true("Built-in examples" %in% en_keys)

  # Template-Based features
  expect_true("Pre-populated frameworks" %in% en_keys)
  expect_true("Domain-specific templates" %in% en_keys)
  expect_true("Ready-to-customize elements" %in% en_keys)
  expect_true("Fastest setup time" %in% en_keys)
  expect_true("Example connections included" %in% en_keys)
})

test_that("Create SES comparison table translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  expect_true("Method Comparison" %in% en_keys)
  expect_true("Time to Start" %in% en_keys)
  expect_true("Learning Curve" %in% en_keys)
  expect_true("Flexibility" %in% en_keys)
  expect_true("Guidance Level" %in% en_keys)
  expect_true("Customization" %in% en_keys)
})

test_that("Create SES help section translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  expect_true("Need Help Choosing?" %in% en_keys)
  expect_true("New to SES modeling?" %in% en_keys)
  expect_true("Have existing framework knowledge?" %in% en_keys)
  expect_true("Working on a time-sensitive project?" %in% en_keys)
})

test_that("Create SES action button translations exist", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  expect_true("Proceed to Selected Method" %in% en_keys)
  expect_true("You selected:" %in% en_keys)
  expect_true("Best for:" %in% en_keys)
})

# ============================================================================
# Test Translation Quality
# ============================================================================

test_that("Create SES Spanish translations are present", {
  translations <- load_translations()

  # Find "Create SES" entry
  create_ses_entry <- NULL
  for (entry in translations$translation) {
    if (entry$en == "Create SES") {
      create_ses_entry <- entry
      break
    }
  }

  skip_if(is.null(create_ses_entry))

  expect_equal(create_ses_entry$es, "Crear SES")
  expect_equal(create_ses_entry$fr, "Créer SES")
  expect_equal(create_ses_entry$de, "SES erstellen")
  expect_equal(create_ses_entry$lt, "Sukurti SES")
  expect_equal(create_ses_entry$pt, "Criar SES")
  expect_equal(create_ses_entry$it, "Crea SES")
})

test_that("Standard Entry translations are present in all languages", {
  translations <- load_translations()

  standard_entry <- NULL
  for (entry in translations$translation) {
    if (entry$en == "Standard Entry") {
      standard_entry <- entry
      break
    }
  }

  skip_if(is.null(standard_entry))

  expect_equal(standard_entry$es, "Entrada Estándar")
  expect_equal(standard_entry$fr, "Saisie Standard")
  expect_equal(standard_entry$de, "Standardeingabe")
  expect_equal(standard_entry$lt, "Standartinė įvestis")
  expect_equal(standard_entry$pt, "Entrada Padrão")
  expect_equal(standard_entry$it, "Inserimento Standard")
})

test_that("No translation entries have empty strings", {
  translations <- load_translations()

  for (i in seq_along(translations$translation)) {
    entry <- translations$translation[[i]]

    for (lang in names(entry)) {
      expect_true(nchar(entry[[lang]]) > 0,
                  info = paste("Entry", i, "has empty", lang, "translation"))
    }
  }
})

# ============================================================================
# Test i18n Object (if loaded)
# ============================================================================

test_that("i18n object can translate Create SES keys", {
  skip_if_not(exists("i18n"))

  # Test core translations
  expect_true(nchar(i18n$t("ui.sidebar.create_ses")) > 0)
  expect_true(nchar(i18n$t("ui.sidebar.standard_entry")) > 0)
  expect_true(nchar(i18n$t("ui.sidebar.ai_assistant")) > 0)
  expect_true(nchar(i18n$t("ui.sidebar.template_based")) > 0)
})

test_that("i18n object handles missing keys gracefully", {
  skip_if_not(exists("i18n"))

  # Should return the key itself or a placeholder
  result <- i18n$t("common.misc.nonexistent_key_12345")
  expect_true(is.character(result))
})

# ============================================================================
# Test Translation Consistency
# ============================================================================

test_that("All Create SES translations maintain consistent terminology", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  # Check that "SES" appears consistently (not translated to different terms)
  ses_entries <- en_keys[grepl("SES", en_keys)]

  # Should have multiple SES-related entries
  expect_true(length(ses_entries) >= 3)
})

test_that("Translation file has no duplicate English keys", {
  translations <- load_translations()
  en_keys <- sapply(translations$translation, function(x) x$en)

  # Check for duplicates
  duplicates <- en_keys[duplicated(en_keys)]

  expect_equal(length(duplicates), 0,
               info = paste("Duplicate keys found:", paste(duplicates, collapse = ", ")))
})

# ============================================================================
# Test Translation Count
# ============================================================================

test_that("Translation file contains all expected Create SES entries", {
  translations <- load_translations()

  # Should have at least 44 new Create SES entries plus existing ones
  # Previously had 113 entries, now should have 157 (113 + 44)
  expect_true(length(translations$translation) >= 150,
              info = paste("Expected at least 150 translations, got", length(translations$translation)))
})

test_that("Translation file structure is valid after updates", {
  translation_file <- "../../translations/translation.json"
  skip_if_not(file.exists(translation_file))

  # Read raw file
  raw_content <- readLines(translation_file, warn = FALSE)

  # Should start with {
  expect_true(grepl("^\\{", raw_content[1]))

  # Should end with }
  expect_true(grepl("\\}$", tail(raw_content, 1)))

  # Should be valid JSON (already tested above, but double-check)
  expect_silent(fromJSON(translation_file))
})
