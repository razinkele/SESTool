#!/usr/bin/env Rscript
# scripts/add_translation.R
# Interactive tool for adding new translations safely
# Ensures all required fields are present and validates before saving

# ============================================================================
# CONFIGURATION
# ============================================================================

REQUIRED_LANGUAGES <- c("en", "es", "fr", "de", "lt", "pt", "it")
LANGUAGE_NAMES <- list(
  en = "English",
  es = "Español",
  fr = "Français",
  de = "Deutsch",
  lt = "Lietuvių",
  pt = "Português",
  it = "Italiano"
)

# ============================================================================
# INTERACTIVE HELPERS
# ============================================================================

prompt <- function(message, default = NULL) {
  if (!is.null(default)) {
    message <- paste0(message, " [", default, "]")
  }
  cat(message, ": ")
  input <- readLines("stdin", n = 1, warn = FALSE)
  if (input == "" && !is.null(default)) {
    return(default)
  }
  return(input)
}

choose_option <- function(options, prompt_msg = "Choose an option") {
  cat("\n", prompt_msg, ":\n", sep = "")
  for (i in seq_along(options)) {
    cat(sprintf("  %d. %s\n", i, options[i]))
  }
  choice <- as.integer(prompt("\nEnter number"))
  if (is.na(choice) || choice < 1 || choice > length(options)) {
    cat("Invalid choice. Using option 1.\n")
    return(1)
  }
  return(choice)
}

confirm <- function(message) {
  response <- tolower(prompt(paste(message, "(y/n)"), "n"))
  return(response %in% c("y", "yes"))
}

# ============================================================================
# FILE SELECTION
# ============================================================================

select_translation_file <- function() {
  cat("\n=== Select Translation File ===\n\n")

  # List available translation files
  common_files <- list.files("translations/common", pattern = "\\.json$",
                            full.names = TRUE)
  ui_files <- list.files("translations/ui", pattern = "\\.json$",
                        full.names = TRUE)
  data_files <- list.files("translations/data", pattern = "\\.json$",
                          full.names = TRUE)

  all_files <- c(common_files, ui_files, data_files)

  if (length(all_files) == 0) {
    cat("No translation files found. Creating new file...\n")
    return(create_new_file())
  }

  # Add option to create new file
  options <- c(basename(all_files), "→ Create new file")

  choice <- choose_option(options, "Select file to add translation to")

  if (choice == length(options)) {
    return(create_new_file())
  } else {
    return(all_files[choice])
  }
}

create_new_file <- function() {
  cat("\n=== Create New Translation File ===\n\n")

  # Select category
  cat("Select category:\n")
  categories <- list(
    list(name = "common", desc = "Common UI elements (buttons, labels, etc.)"),
    list(name = "ui", desc = "UI component translations (sidebar, header, etc.)"),
    list(name = "data", desc = "Data-specific translations (node types, etc.)"),
    list(name = "modules", desc = "Module-specific translations")
  )

  for (i in seq_along(categories)) {
    cat(sprintf("  %d. %s/ - %s\n", i, categories[[i]]$name,
               categories[[i]]$desc))
  }

  cat_choice <- as.integer(prompt("\nEnter number", "1"))
  if (is.na(cat_choice) || cat_choice < 1 || cat_choice > length(categories)) {
    cat_choice <- 1
  }

  category <- categories[[cat_choice]]$name

  # Get filename
  filename <- prompt("\nEnter filename (without .json)")
  filename <- gsub("[^a-z0-9_]", "_", tolower(filename))

  file_path <- file.path("translations", category, paste0(filename, ".json"))

  # Create directory if needed
  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)

  # Create initial file structure
  initial_data <- list(
    languages = REQUIRED_LANGUAGES,
    translation = list()
  )

  jsonlite::write_json(initial_data, file_path, pretty = TRUE, auto_unbox = TRUE)

  cat("\nCreated new file:", file_path, "\n")
  return(file_path)
}

# ============================================================================
# TRANSLATION ENTRY
# ============================================================================

create_translation_entry <- function() {
  cat("\n=== Create Translation Entry ===\n\n")

  entry <- list()

  # Ask if namespaced key should be used
  use_key <- confirm("Use namespaced key (recommended for new translations)?")

  if (use_key) {
    cat("\nNamespaced key format: category.subcategory.name\n")
    cat("Examples:\n")
    cat("  - common.buttons.save\n")
    cat("  - ui.sidebar.dashboard\n")
    cat("  - framework.drivers.singular\n\n")

    key <- prompt("Enter key")
    if (key != "") {
      entry$key <- key
    }
  }

  # Collect translations for each language
  cat("\nEnter translations for each language:\n")
  cat("(Press Enter to skip and fill in later)\n\n")

  for (lang in REQUIRED_LANGUAGES) {
    lang_name <- LANGUAGE_NAMES[[lang]]
    translation <- prompt(sprintf("%s (%s)", lang_name, lang))

    if (translation != "") {
      entry[[lang]] <- translation
    } else {
      # Set placeholder
      entry[[lang]] <- paste0("TODO: ", lang, " translation")
      cat(sprintf("  ⚠ Will use placeholder: '%s'\n", entry[[lang]]))
    }
  }

  return(entry)
}

# ============================================================================
# VALIDATION
# ============================================================================

validate_entry <- function(entry) {
  issues <- list()

  # Check all languages present
  for (lang in REQUIRED_LANGUAGES) {
    if (is.null(entry[[lang]]) || entry[[lang]] == "") {
      issues <- c(issues, paste("Missing", lang, "translation"))
    }
  }

  # Check for TODO placeholders
  for (lang in REQUIRED_LANGUAGES) {
    if (!is.null(entry[[lang]]) && grepl("^TODO:", entry[[lang]])) {
      issues <- c(issues, paste(toupper(lang), "has TODO placeholder"))
    }
  }

  # Check encoding (Lithuanian chars in wrong languages)
  lt_pattern <- "[ĄąČčĖėĘęĮįŠšŲųŪūŽž]"
  for (lang in c("en", "es", "fr", "de", "pt", "it")) {
    if (!is.null(entry[[lang]]) && grepl(lt_pattern, entry[[lang]])) {
      issues <- c(issues, paste(toupper(lang), "contains Lithuanian characters"))
    }
  }

  return(issues)
}

# ============================================================================
# SAVING
# ============================================================================

save_translation <- function(file_path, entry) {
  # Load existing file
  if (!file.exists(file_path)) {
    data <- list(
      languages = REQUIRED_LANGUAGES,
      translation = list()
    )
  } else {
    data <- jsonlite::fromJSON(file_path, simplifyVector = FALSE)
  }

  # Check for duplicates
  if (!is.null(data$translation) && !is.null(entry$en)) {
    for (existing in data$translation) {
      if (!is.null(existing$en) && existing$en == entry$en) {
        cat("\n⚠ Warning: Entry with same English text already exists!\n")
        cat("Existing entry:\n")
        print(existing)
        if (!confirm("\nReally add duplicate entry?")) {
          return(FALSE)
        }
        break
      }
    }
  }

  # Add new entry
  data$translation <- c(data$translation, list(entry))

  # Save with pretty formatting
  tryCatch({
    jsonlite::write_json(data, file_path, pretty = TRUE, auto_unbox = TRUE)
    cat("\n✓ Translation saved successfully to:", file_path, "\n")
    return(TRUE)
  }, error = function(e) {
    cat("\n✗ Error saving file:", e$message, "\n")
    return(FALSE)
  })
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

run_add_translation <- function() {
  cat("\n╔═══════════════════════════════════════════╗\n")
  cat("║  Add New Translation - Interactive Tool  ║\n")
  cat("╚═══════════════════════════════════════════╝\n")

  # Step 1: Select file
  file_path <- select_translation_file()

  # Step 2: Create entry
  entry <- create_translation_entry()

  # Step 3: Validate
  cat("\n=== Validation ===\n\n")
  issues <- validate_entry(entry)

  if (length(issues) > 0) {
    cat("⚠ Validation issues:\n")
    for (issue in issues) {
      cat("  -", issue, "\n")
    }
    cat("\n")
    if (!confirm("Continue despite issues?")) {
      cat("\nTranslation NOT saved.\n")
      return(invisible(FALSE))
    }
  } else {
    cat("✓ No validation issues found\n")
  }

  # Step 4: Preview
  cat("\n=== Preview ===\n\n")
  cat("File:", file_path, "\n")
  cat("Entry:\n")
  str(entry, max.level = 1)

  # Step 5: Confirm and save
  if (!confirm("\nSave this translation?")) {
    cat("\nTranslation NOT saved.\n")
    return(invisible(FALSE))
  }

  success <- save_translation(file_path, entry)

  if (success) {
    cat("\n✓ Translation added successfully!\n")
    cat("\nNext steps:\n")
    cat("  1. Run validation: Rscript scripts/validate_translations.R\n")
    cat("  2. Test in app: source('global.R')\n")
    cat("  3. Commit changes if all looks good\n")

    if (confirm("\nAdd another translation?")) {
      return(run_add_translation())
    }
  }

  return(invisible(success))
}

# ============================================================================
# BATCH MODE (from CSV)
# ============================================================================

import_from_csv <- function(csv_file) {
  cat("\n=== Import Translations from CSV ===\n\n")

  if (!file.exists(csv_file)) {
    cat("✗ CSV file not found:", csv_file, "\n")
    return(invisible(FALSE))
  }

  # Read CSV
  # Expected columns: key, en, es, fr, de, lt, pt, it, file
  data <- read.csv(csv_file, stringsAsFactors = FALSE, encoding = "UTF-8")

  required_cols <- c("en", REQUIRED_LANGUAGES)
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0) {
    cat("✗ CSV missing required columns:", paste(missing_cols, collapse = ", "), "\n")
    return(invisible(FALSE))
  }

  cat(sprintf("Found %d translations to import\n\n", nrow(data)))

  # Group by file
  if ("file" %in% names(data)) {
    files <- unique(data$file)
  } else {
    # Default file if not specified
    files <- "translations/common/imported.json"
    data$file <- files
  }

  # Import each file
  success_count <- 0
  for (file_path in files) {
    rows <- data[data$file == file_path, ]
    cat(sprintf("\nImporting %d entries to %s\n", nrow(rows), file_path))

    for (i in seq_len(nrow(rows))) {
      entry <- as.list(rows[i, ])

      # Remove file column
      entry$file <- NULL

      # Validate
      issues <- validate_entry(entry)
      if (length(issues) > 0) {
        cat(sprintf("  ⚠ Row %d has issues: %s\n", i,
                   paste(issues, collapse = "; ")))
      }

      # Save
      if (save_translation(file_path, entry)) {
        success_count <- success_count + 1
      }
    }
  }

  cat(sprintf("\n✓ Imported %d/%d translations\n", success_count, nrow(data)))
  return(invisible(TRUE))
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0 && args[1] == "--csv") {
  if (length(args) < 2) {
    cat("Usage: Rscript scripts/add_translation.R --csv <file.csv>\n")
    quit(status = 1)
  }
  import_from_csv(args[2])
} else if (length(args) > 0 && args[1] == "--help") {
  cat("Add Translation Tool\n\n")
  cat("Usage:\n")
  cat("  Rscript scripts/add_translation.R          # Interactive mode\n")
  cat("  Rscript scripts/add_translation.R --csv FILE.csv  # Batch import\n\n")
  cat("CSV Format:\n")
  cat("  Columns: key, en, es, fr, de, lt, pt, it, file\n")
  cat("  - key: optional namespaced key\n")
  cat("  - en,es,fr,de,lt,pt,it: translations\n")
  cat("  - file: optional, target file path\n")
} else {
  # Interactive mode
  if (!interactive() && !exists("rstudioapi")) {
    # Check if running in RStudio or interactive R session
    cat("⚠ This tool works best in interactive mode (RStudio or R console)\n")
    cat("For batch import, use: Rscript scripts/add_translation.R --csv FILE.csv\n\n")
  }

  run_add_translation()
}
