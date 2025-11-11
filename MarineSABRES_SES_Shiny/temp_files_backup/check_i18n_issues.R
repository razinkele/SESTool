#!/usr/bin/env Rscript
# Comprehensive i18n consistency check

library(stringr)

cat("=== Internationalization Consistency Check ===\n\n")

# 1. Check app.R for hardcoded strings
cat("1. Checking app.R for hardcoded English strings...\n")
app_content <- readLines("app.R", warn = FALSE)

hardcoded_patterns <- list(
  modalButton = 'modalButton\\("([^"]+)"\\)',
  actionButton_label = 'actionButton\\("[^"]+",\\s*"([^"]+)"',
  title_attr = 'title\\s*=\\s*"([A-Z][^"]{10,})"',
  tags_p = 'tags\\$p\\("([A-Z][^"]{10,})"\\)',
  tags_h = 'tags\\$h[1-6]\\("([A-Z][^"]{10,})"\\)'
)

hardcoded_found <- list()
for (pattern_name in names(hardcoded_patterns)) {
  pattern <- hardcoded_patterns[[pattern_name]]
  for (i in seq_along(app_content)) {
    matches <- str_match_all(app_content[i], pattern)[[1]]
    if (nrow(matches) > 0 && ncol(matches) >= 2) {
      for (j in 1:nrow(matches)) {
        text <- matches[j, 2]
        # Skip if it looks like it's inside i18n$t()
        if (!grepl("i18n\\$t", app_content[i], fixed = TRUE)) {
          hardcoded_found[[length(hardcoded_found) + 1]] <- list(
            file = "app.R",
            line = i,
            type = pattern_name,
            text = text
          )
        }
      }
    }
  }
}

if (length(hardcoded_found) > 0) {
  cat("  Found", length(hardcoded_found), "potential hardcoded strings:\n")
  for (item in hardcoded_found[1:min(10, length(hardcoded_found))]) {
    cat(sprintf("    Line %d (%s): %s\n", item$line, item$type, item$text))
  }
} else {
  cat("  ✓ No obvious hardcoded strings found\n")
}
cat("\n")

# 2. Check module consistency
cat("2. Checking module i18n parameter consistency...\n")
module_files <- list.files("modules", pattern = "_module\\.R$", full.names = TRUE)

modules_with_i18n <- c()
modules_without_i18n <- c()

for (mod_file in module_files) {
  mod_content <- readLines(mod_file, warn = FALSE)
  # Check if UI function has i18n parameter
  ui_lines <- grep("^[a-z_]+_ui\\s*<-\\s*function", mod_content, value = TRUE)
  if (length(ui_lines) > 0) {
    if (any(grepl("i18n", ui_lines))) {
      modules_with_i18n <- c(modules_with_i18n, basename(mod_file))
    } else {
      modules_without_i18n <- c(modules_without_i18n, basename(mod_file))
    }
  }
}

cat("  Modules WITH i18n parameter:\n")
for (mod in modules_with_i18n) {
  cat("    ✓", mod, "\n")
}
cat("\n  Modules WITHOUT i18n parameter (using global i18n):\n")
for (mod in modules_without_i18n) {
  cat("    •", mod, "\n")
}
cat("\n")

# 3. Check for duplicate files
cat("3. Checking for duplicate/temporary files...\n")
all_files <- list.files(".", pattern = "\\.(R|r|json)$", recursive = FALSE)
duplicates <- grep("(backup|new|old|temp|test|check|merge|add_|generate_|extract_|filter_|find_|diagnose_|update_|validate_|compare_|convert_|count_|deduplicate_|reformat_|remaining_)",
                   all_files, value = TRUE)

if (length(duplicates) > 0) {
  cat("  Found", length(duplicates), "potential temporary files:\n")
  for (f in duplicates[1:min(15, length(duplicates))]) {
    cat("    •", f, "\n")
  }
  if (length(duplicates) > 15) {
    cat("    ... and", length(duplicates) - 15, "more\n")
  }
} else {
  cat("  ✓ No obvious duplicate files found\n")
}
cat("\n")

# 4. Check translation.json structure
cat("4. Checking translation.json structure...\n")
library(jsonlite)
trans <- tryCatch({
  fromJSON('translations/translation.json', simplifyDataFrame = FALSE)
}, error = function(e) {
  cat("  ✗ Error loading translation.json:", e$message, "\n")
  return(NULL)
})

if (!is.null(trans)) {
  en_keys <- sapply(trans$translation, function(x) x$en)

  # Check for duplicates
  dups <- en_keys[duplicated(en_keys)]
  if (length(dups) > 0) {
    cat("  ✗ Found", length(dups), "duplicate English keys:\n")
    for (d in dups[1:min(5, length(dups))]) {
      cat("    •", d, "\n")
    }
  } else {
    cat("  ✓ No duplicate keys found\n")
  }

  # Check for empty translations
  empty_count <- 0
  for (entry in trans$translation) {
    for (lang in trans$languages) {
      if (is.null(entry[[lang]]) || entry[[lang]] == "") {
        empty_count <- empty_count + 1
      }
    }
  }

  if (empty_count > 0) {
    cat("  ✗ Found", empty_count, "empty translation entries\n")
  } else {
    cat("  ✓ All translations are non-empty\n")
  }

  cat("  Total translations:", length(trans$translation), "\n")
  cat("  Languages:", paste(trans$languages, collapse = ", "), "\n")
}

cat("\n=== Check Complete ===\n")
