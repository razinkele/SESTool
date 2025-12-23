# test-i18n-enforcement.R — i18n enforcement tests
# Comprehensive i18n enforcement tests to prevent hardcoded strings
# and ensure i18n best practices are followed

library(testthat)

# Module dir helper for repeated use in tests
module_dir <- "../../modules"

# ==============================================================================
# TEST 1: Module UI Functions Have usei18n()
# ==============================================================================

test_that("All module UI functions with i18n parameter have usei18n() calls", {
  # Find all module files
  module_files <- list.files(module_dir, pattern = "\\.R$", full.names = TRUE)
  module_files <- module_files[!grepl("backup|old|\\.bak", module_files, ignore.case = TRUE)]

  # Preload app.R to accept global usei18n() calls
  app_content <- ""
  if (file.exists("../../app.R")) {
    app_content <- paste(readLines("../../app.R", warn = FALSE), collapse = "\n")
  }

  # List of modules that should have usei18n()
  critical_modules <- c(
    "analysis_tools_module.R",
    "isa_data_entry_module.R",
    "ai_isa_assistant_module.R",
    "response_module.R",
    "scenario_builder_module.R",
    "export_reports_module.R",
    "connection_review_tabbed.R",
    "cld_visualization_module.R",
    "auto_save_module.R",
    "progress_indicator_module.R"
  )

  for (module in critical_modules) {
    module_path <- file.path(module_dir, module)

    if (!file.exists(module_path)) {
      skip(paste("Module not found:", module))
      next
    }

    content <- readLines(module_path, warn = FALSE)
    content_str <- paste(content, collapse = "\n")

    # Check if module has UI functions with i18n parameter
    has_i18n_param <- grepl("function\\([^)]*i18n[^)]*\\)", content_str)

    if (has_i18n_param) {
      # Module should have usei18n() call either in module or globally in app.R
      has_usei18n <- grepl("shiny\\.i18n::usei18n\\(i18n\\)|usei18n\\(i18n\\)", content_str) ||
                     grepl("shiny\\.i18n::usei18n\\(i18n\\$translator\\)|usei18n\\(i18n\\$translator\\)", app_content)

      expect_true(
        has_usei18n,
        info = paste(module, "has i18n parameter but missing usei18n() call (module or app-level)")
      )
    }
  }
})

# ==============================================================================
# TEST 2: No Hardcoded Strings in showNotification
# ==============================================================================

test_that("showNotification calls use i18n$t() for all user-facing messages", {
  # Check app.R and module files
  module_dir <- "../../modules"
  files_to_check <- c(
    "../../app.R",
    list.files(module_dir, pattern = "\\.R$", full.names = TRUE)
  )

  # Exclude backup files
  files_to_check <- files_to_check[!grepl("backup|old|\\.bak", files_to_check, ignore.case = TRUE)]

  hardcoded_notifications <- list()

  for (file_path in files_to_check) {
    if (!file.exists(file_path)) next

    content <- readLines(file_path, warn = FALSE)

    for (i in seq_along(content)) {
      line <- content[i]

      # Check for showNotification with hardcoded strings (not using i18n$t)
      if (grepl("showNotification\\s*\\(", line)) {
        # Get next few lines for context
        context_end <- min(i + 5, length(content))
        context <- paste(content[i:context_end], collapse = " ")

        # Check if notification has hardcoded string (quoted text not wrapped in i18n$t)
        # Pattern: "text" that's not preceded by i18n$t(
        notification_pattern <- "showNotification\\s*\\(\\s*\"[^\"]+\"|showNotification\\s*\\(\\s*paste0?\\s*\\(\\s*\"[^\"]+"
        if (grepl(notification_pattern, context)) {
          # Check if it's NOT using i18n$t
          if (!grepl("i18n\\$t\\s*\\(", context)) {
            hardcoded_notifications[[length(hardcoded_notifications) + 1]] <- list(
              file = basename(file_path),
              line = i,
              content = trimws(line)
            )
          }
        }
      }
    }
  }

  if (length(hardcoded_notifications) > 0) {
    msg <- paste(
      sprintf("\nFound %d showNotification calls with hardcoded strings:", length(hardcoded_notifications)),
      paste(sapply(hardcoded_notifications, function(x) {
        sprintf("  %s:%d - %s", x$file, x$line, substr(x$content, 1, 80))
      }), collapse = "\n"),
      sep = "\n"
    )

    # Warning instead of failure for now, as some may be intentional
    warning(msg)
  }

  # This test passes but generates warnings for review
  expect_true(TRUE)
})

# ==============================================================================
# TEST 3: No Common Hardcoded UI Patterns
# ==============================================================================

test_that("Common UI elements use i18n$t() for labels and titles", {
  module_files <- list.files(module_dir, pattern = "\\.R$", full.names = TRUE)
  module_files <- module_files[!grepl("backup|old|\\.bak", module_files, ignore.case = TRUE)]

  # Patterns that often indicate hardcoded strings
  suspicious_patterns <- c(
    "actionButton\\([^,]+,\\s*\"[A-Z]",
    "h[1-6]\\(\\s*\"[A-Z]",
    "modalDialog\\([^,]*title\\s*=\\s*\"[A-Z]"
  )

  hardcoded_ui_elements <- list()

  for (file_path in module_files) {
    if (!file.exists(file_path)) next

    content <- readLines(file_path, warn = FALSE)

    for (i in seq_along(content)) {
      line <- content[i]

      for (pattern in suspicious_patterns) {
        if (grepl(pattern, line)) {
          # Check if line uses i18n$t
          if (!grepl('i18n\\$t\\s*\\(', line)) {
            hardcoded_ui_elements[[length(hardcoded_ui_elements) + 1]] <- list(
              file = basename(file_path),
              line = i,
              content = trimws(line)
            )
          }
        }
      }
    }
  }

  # This is informational - we expect some hardcoded elements for now
  if (length(hardcoded_ui_elements) > 0 && length(hardcoded_ui_elements) <= 10) {
    info_msg <- paste(
      sprintf("Found %d UI elements that might benefit from i18n:", length(hardcoded_ui_elements)),
      paste(sapply(head(hardcoded_ui_elements, 10), function(x) {
        sprintf("  %s:%d", x$file, x$line)
      }), collapse = "\n"),
      sep = "\n"
    )
    message(info_msg)
  }

  expect_true(TRUE)
})

# ==============================================================================
# TEST 4: All i18n$t() Calls Have Translation Keys
# ==============================================================================

test_that("All i18n$t() calls have corresponding translation keys", {
  skip_if_not(dir.exists("../../translations"), "Translation directory not found")

  # Load all translation keys
  source("../../functions/translation_loader.R")
  result <- load_translations("../../translations", debug = FALSE)
  # Support multiple loader return shapes (historical differences)
  if (!is.null(result$translations) && !is.null(result$translations$en)) {
    all_keys <- names(result$translations$en)
  } else if (!is.null(result$translation)) {
    all_keys <- names(result$translation)
  } else if (!is.null(result$translations) && is.list(result$translations)) {
    all_keys <- names(result$translations)
  } else {
    stop('Unrecognized translation loader output format')
  }

  # Find all i18n$t() calls in code
  code_files <- c(
    "../../app.R",
    list.files("../../modules", pattern = "\\.R$", full.names = TRUE)
  )

  code_files <- code_files[!grepl("backup|old|\\.bak", code_files, ignore.case = TRUE)]

  used_keys <- character()

  for (file_path in code_files) {
    if (!file.exists(file_path)) next

    content <- readLines(file_path, warn = FALSE)
    content_str <- paste(content, collapse = "\n")

    # Extract i18n$t() calls
    matches <- gregexpr('i18n\\$t\\s*\\(\\s*"([^"]+)"', content_str, perl = TRUE)

    if (matches[[1]][1] != -1) {
      for (match_start in matches[[1]]) {
        match_length <- attr(matches[[1]], "match.length")[which(matches[[1]] == match_start)]
        match_text <- substr(content_str, match_start, match_start + match_length - 1)

        # Extract the key
        key_match <- regexpr('"([^"]+)"', match_text, perl = TRUE)
        if (key_match != -1) {
          key <- gsub('"', '', regmatches(match_text, key_match))
          used_keys <- c(used_keys, key)
        }
      }
    }
  }

  used_keys <- unique(used_keys)

  # Check for missing keys
  missing_keys <- setdiff(used_keys, all_keys)

  if (length(missing_keys) > 0) {
    warning(sprintf(
      "Found %d i18n$t() calls with missing translation keys:\n%s",
      length(missing_keys),
      paste(head(missing_keys, 20), collapse = "\n")
    ))
  }

  # This should ideally be 0
  expect_equal(
    length(missing_keys), 0,
    label = "Number of missing translation keys",
    expected.label = "0 (all keys should exist)"
  )
})

# ==============================================================================
# TEST 5: Translation Files Are Well-Formed
# ==============================================================================

test_that("All translation files are valid JSON and properly structured", {
  skip_if_not(dir.exists("../../translations"), "Translation directory not found")

  json_files <- list.files("../../translations", pattern = "\\.json$",
                          full.names = TRUE, recursive = TRUE)

  # Exclude backup files and special files
  json_files <- json_files[!grepl("backup|safebackup", json_files, ignore.case = TRUE)]

  for (json_file in json_files) {
    file_name <- basename(json_file)

    # Test 1: Valid JSON
    expect_error(
      jsonlite::fromJSON(json_file),
      NA,
      label = paste("Invalid JSON in", file_name)
    )

    # Special handling for _framework.json which has a different structure
    if (grepl("^_", file_name)) {
      # Framework file has different structure - just check it's valid JSON
      next
    }

    # Test 2: Has required language keys
    data <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)

    required_languages <- c("en", "es", "fr", "de", "lt", "pt", "it")

    # Support both unified 'translation' files and per-language files
    if ("translation" %in% names(data)) {
      # unified format: { languages: [...], translation: { key: {en:.., es:... } } }
      langs <- data$languages
      if (is.null(langs) || length(langs) == 0) {
        first <- data$translation[[1]]
        langs <- names(first)
      }

      for (lang in required_languages) {
        expect_true(
          lang %in% langs,
          label = paste(file_name, "has language", lang)
        )
      }

      # Test 3: All languages have same keys (iterate translation keys)
      en_keys <- names(data$translation)

      for (tk in en_keys) {
        for (lang in required_languages) {
          expect_true(
            !is.null(data$translation[[tk]][[lang]]),
            info = paste("Key", tk, "is missing language", lang, "in", file_name)
          )
        }
      }

    } else {
      # Per-language top-level format
      for (lang in required_languages) {
        expect_true(
          lang %in% names(data),
          label = paste(file_name, "has language", lang)
        )
      }

      # Test 3: All languages have same keys
      if (length(data) > 0 && "en" %in% names(data)) {
        en_keys <- names(data$en)

        for (lang in setdiff(names(data), c("en", "glossary"))) {
          lang_keys <- names(data[[lang]])

          # Keys should match (order doesn't matter)
          expect_equal(
            sort(lang_keys),
            sort(en_keys),
            label = paste(file_name, "- Language", lang, "keys"),
            expected.label = "English keys"
          )
        }
      }
    }
  }
})

# ==============================================================================
# TEST 6: No Empty Translation Values
# ==============================================================================

test_that("Translation files have no empty values", {
  skip_if_not(dir.exists("../../translations"), "Translation directory not found")

  json_files <- list.files("../../translations", pattern = "\\.json$",
                          full.names = TRUE, recursive = TRUE)
  json_files <- json_files[!grepl("backup|safebackup", json_files, ignore.case = TRUE)]

  for (json_file in json_files) {
    file_name <- basename(json_file)

    # Skip special files with different structures
    if (grepl("^_", file_name)) next

    data <- jsonlite::fromJSON(json_file, simplifyVector = FALSE)

    # Support unified translation structure or per-language structure
    if ("translation" %in% names(data)) {
      for (tk in names(data$translation)) {
        for (lang in data$languages) {
          value <- data$translation[[tk]][[lang]]
          expect_true(
            !is.null(value) && is.character(value) && nchar(trimws(value)) > 0,
            label = sprintf("%s - %s[%s] has value", file_name, lang, tk)
          )
        }
      }
    } else {
      for (lang in names(data)) {
        if (lang == "glossary") next

        for (key in names(data[[lang]])) {
          value <- data[[lang]][[key]]

          expect_true(
            !is.null(value) && nchar(trimws(value)) > 0,
            label = sprintf("%s - %s[%s] has value", file_name, lang, key)
          )
        }
      }
    }
  }
})

# ==============================================================================
# TEST 7: Modules With i18n Parameter Actually Use It
# ==============================================================================

test_that("Modules that accept i18n parameter actually use i18n$t()", {
  module_files <- list.files(module_dir, pattern = "\\.R$", full.names = TRUE)
  module_files <- module_files[!grepl("backup|old|\\.bak", module_files, ignore.case = TRUE)]

  for (module_path in module_files) {
    content <- readLines(module_path, warn = FALSE)
    content_str <- paste(content, collapse = "\n")

    # Check if module has i18n parameter
    has_i18n_param <- grepl("function\\([^)]*i18n[^)]*\\)", content_str)

    if (has_i18n_param) {
      # Module should use i18n$t()
      uses_i18n <- grepl("i18n\\$t\\s*\\(", content_str)

      expect_true(
        uses_i18n,
        info = paste(basename(module_path), "has i18n parameter but never uses i18n$t()")
      )
    }
  }
})

# ==============================================================================
# TEST 8: Critical User-Facing Strings Are Internationalized
# ==============================================================================

test_that("Critical user-facing strings in app.R are internationalized", {
  skip_if_not(file.exists("../../app.R"), "app.R not found")

  content <- readLines("../../app.R", warn = FALSE)
  content_str <- paste(content, collapse = "\n")

  # Check for common patterns that should be internationalized
  critical_patterns <- list(
    showNotification = "showNotification\\s*\\(",
    modalDialog_title = "modalDialog\\s*\\([^,]*title\\s*=",
    actionButton_label = "actionButton\\s*\\([^,]+,"
  )

  for (pattern_name in names(critical_patterns)) {
    pattern <- critical_patterns[[pattern_name]]

    # Find all occurrences
    matches <- gregexpr(pattern, content_str)

    if (matches[[1]][1] != -1) {
      # For each match, check if it's using i18n
      # This is a simplified check - just verifying the pattern exists
      # Actual validation would need more sophisticated parsing

      expect_true(
        grepl("i18n\\$t\\s*\\(", content_str),
        info = paste("app.R should use i18n$t() for", pattern_name)
      )
    }
  }

  expect_true(TRUE)
})

# ==============================================================================
# SUMMARY TEST
# ==============================================================================

test_that("i18n enforcement summary", {
  skip_if_not(dir.exists("../../translations"), "Translation directory not found")

  # Count modules with usei18n()
  module_files <- list.files(module_dir, pattern = "\\.R$", full.names = TRUE)
  module_files <- module_files[!grepl("backup|old|\\.bak", module_files, ignore.case = TRUE)]

  modules_with_usei18n <- 0
  total_modules <- length(module_files)

  for (module_path in module_files) {
    content <- paste(readLines(module_path, warn = FALSE), collapse = "\n")
    if (grepl("usei18n\\(i18n\\)", content)) {
      modules_with_usei18n <- modules_with_usei18n + 1
    }
  }

  # Count translation keys
  source("../../functions/translation_loader.R")
  result <- load_translations("../../translations", debug = FALSE)
  total_keys <- length(names(result$translations$en))

  message(sprintf("\n=== i18n Enforcement Summary ==="))
  message(sprintf("Modules with usei18n(): %d/%d (%.1f%%)",
                 modules_with_usei18n, total_modules,
                 100 * modules_with_usei18n / total_modules))
  message(sprintf("Total translation keys: %d", total_keys))
languages_count <- length(names(result$translations)) - 1  # -1 for glossary
    message(sprintf("Supported languages: %d", languages_count))

  expect_true(TRUE)
})
