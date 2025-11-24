#!/usr/bin/env Rscript
# scripts/translation_workflow.R
# Master script for translation workflow management

# ============================================================================
# WORKFLOW COMMANDS
# ============================================================================

commands <- list(
  validate = list(
    desc = "Validate all translation files",
    script = "scripts/validate_translations.R",
    help = "Checks JSON syntax, structure, language completeness, and encoding"
  ),

  test = list(
    desc = "Run automated test suite",
    script = "scripts/test_translations.R",
    help = "Tests translation loader, integration, and end-to-end functionality"
  ),

  add = list(
    desc = "Add new translation (auto-mode, recommended)",
    script = "scripts/add_translation_auto.R",
    help = "Smart auto-detection with legacy extraction (minimal interaction)"
  ),

  add_batch = list(
    desc = "Add translations from file (batch mode)",
    script = NULL,  # Inline with args
    help = "Add multiple translations from file (one English key per line)"
  ),

  add_manual = list(
    desc = "Add translation manually (full control)",
    script = "scripts/add_translation.R",
    help = "Interactive tool with full control over all fields"
  ),

  stats = list(
    desc = "Show translation statistics",
    script = NULL,  # Inline
    help = "Display statistics about translation coverage and files"
  ),

  check = list(
    desc = "Pre-commit check (validate + test)",
    script = NULL,  # Inline
    help = "Run all checks before committing changes"
  ),

  format = list(
    desc = "Reformat JSON files",
    script = NULL,  # Inline
    help = "Reformat all translation JSON files with consistent style"
  ),

  find_missing = list(
    desc = "Find missing translation keys",
    script = "scripts/find_missing_translations.R",
    help = "Find translation keys used in code but not in translation files"
  ),

  find_unused = list(
    desc = "Find unused translation keys",
    script = NULL,  # Inline
    help = "Find translation keys defined but not used in code"
  ),

  process_missing = list(
    desc = "Find and add ALL missing translations (complete workflow)",
    script = NULL,  # Inline
    help = "Find missing translations then batch process them all automatically"
  )
)

# ============================================================================
# COMMAND IMPLEMENTATIONS
# ============================================================================

cmd_stats <- function() {
  cat("\n=== Translation Statistics ===\n\n")

  source("functions/translation_loader.R")

  # Load translations
  result <- load_translations("translations", debug = FALSE)
  stats <- get_translation_stats(result)

  cat("Total Entries:    ", stats$total_entries, "\n")
  cat("Namespaced Keys:  ", stats$namespaced_keys, "\n")
  cat("Flat Keys:        ", stats$flat_keys, "\n")
  cat("Glossary Terms:   ", stats$glossary_terms, "\n")
  cat("\nLanguages:", paste(stats$languages, collapse = ", "), "\n")

  cat("\nEntries per language:\n")
  for (lang in names(stats$entries_per_language)) {
    cat(sprintf("  %s: %d\n", toupper(lang), stats$entries_per_language[[lang]]))
  }

  cat("\nCharacters per language:\n")
  for (lang in names(stats$characters_per_language)) {
    cat(sprintf("  %s: %s\n", toupper(lang),
               format(stats$characters_per_language[[lang]], big.mark = ",")))
  }

  # File statistics
  json_files <- list.files("translations", pattern = "\\.json$",
                          full.names = TRUE, recursive = TRUE)
  json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

  cat("\nFiles:\n")
  for (dir in c("common", "ui", "data", "modules")) {
    dir_files <- json_files[grepl(paste0("/", dir, "/"), json_files)]
    if (length(dir_files) > 0) {
      cat(sprintf("  %s/: %d files\n", dir, length(dir_files)))
    }
  }

  cat("\n")
}

cmd_check <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Pre-Commit Translation Check        ║\n")
  cat("╚═══════════════════════════════════════╝\n")

  # Step 1: Validate
  cat("\n[Step 1/2] Running validation...\n")
  validate_result <- system2("Rscript", args = c("scripts/validate_translations.R"),
                            stdout = TRUE, stderr = TRUE)
  validate_status <- attr(validate_result, "status")

  if (!is.null(validate_status) && validate_status != 0) {
    cat("\n✗ Validation failed!\n")
    cat(paste(validate_result, collapse = "\n"))
    cat("\nFix validation errors before committing.\n")
    return(invisible(FALSE))
  }

  cat(paste(validate_result, collapse = "\n"))

  # Step 2: Test
  cat("\n[Step 2/2] Running tests...\n")
  test_result <- system2("Rscript", args = c("scripts/test_translations.R"),
                        stdout = TRUE, stderr = TRUE)
  test_status <- attr(test_result, "status")

  if (!is.null(test_status) && test_status != 0) {
    cat("\n✗ Tests failed!\n")
    cat(paste(test_result, collapse = "\n"))
    cat("\nFix test failures before committing.\n")
    return(invisible(FALSE))
  }

  cat(paste(test_result, collapse = "\n"))

  # Success
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  ✓ ALL CHECKS PASSED                 ║\n")
  cat("║  Ready to commit!                    ║\n")
  cat("╚═══════════════════════════════════════╝\n\n")

  return(invisible(TRUE))
}

cmd_format <- function() {
  cat("\n=== Formatting Translation Files ===\n\n")

  json_files <- list.files("translations", pattern = "\\.json$",
                          full.names = TRUE, recursive = TRUE)
  json_files <- json_files[!grepl("backup", json_files, ignore.case = TRUE)]

  for (file in json_files) {
    cat("Formatting:", basename(file), "...")

    tryCatch({
      data <- jsonlite::fromJSON(file, simplifyVector = FALSE)
      jsonlite::write_json(data, file, pretty = TRUE, auto_unbox = TRUE)
      cat(" ✓\n")
    }, error = function(e) {
      cat(" ✗ Error:", e$message, "\n")
    })
  }

  cat("\nFormatting complete.\n")
}

cmd_find_missing <- function() {
  cat("\n=== Finding Missing Translations ===\n\n")

  source("functions/translation_helpers.R")

  result <- check_translation_completeness()

  if (length(result$missing_in_file) > 0) {
    cat(sprintf("Found %d keys used in code but not in translation files:\n\n",
               length(result$missing_in_file)))

    for (key in head(result$missing_in_file, 20)) {
      cat("  -", key, "\n")
    }

    if (length(result$missing_in_file) > 20) {
      cat(sprintf("\n  ... and %d more\n", length(result$missing_in_file) - 20))
    }

    cat("\nAdd these translations using: Rscript scripts/add_translation.R\n")
  } else {
    cat("✓ No missing translations found!\n")
  }

  cat("\n")
}

cmd_find_unused <- function() {
  cat("\n=== Finding Unused Translations ===\n\n")

  source("functions/translation_helpers.R")

  result <- check_translation_completeness()

  if (length(result$unused_in_code) > 0) {
    cat(sprintf("Found %d keys in translation files but not used in code:\n\n",
               length(result$unused_in_code)))

    for (key in head(result$unused_in_code, 20)) {
      cat("  -", key, "\n")
    }

    if (length(result$unused_in_code) > 20) {
      cat(sprintf("\n  ... and %d more\n", length(result$unused_in_code) - 20))
    }

    cat("\nThese keys might be:\n")
    cat("  - Truly unused and can be removed\n")
    cat("  - Used in dynamically generated keys\n")
    cat("  - Used in HTML/JavaScript files (not scanned)\n")
  } else {
    cat("✓ No unused translations found!\n")
  }

  cat("\n")
}

cmd_add_batch <- function(file_path) {
  if (is.null(file_path) || !file.exists(file_path)) {
    cat("Error: Please provide a valid file path\n")
    cat("Usage: Rscript scripts/translation_workflow.R add_batch FILE.txt\n")
    return(invisible(FALSE))
  }

  cat("\n=== Batch Adding Translations ===\n\n")
  cat(sprintf("Processing file: %s\n\n", file_path))

  # Run the automated tool
  result <- system2("Rscript", args = c("scripts/add_translation_auto.R", file_path),
                   stdout = TRUE, stderr = TRUE)

  cat(paste(result, collapse = "\n"))
  cat("\n")

  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    return(invisible(FALSE))
  }

  return(invisible(TRUE))
}

cmd_process_missing <- function() {
  cat("\n╔═══════════════════════════════════════╗\n")
  cat("║  Process ALL Missing Translations    ║\n")
  cat("╚═══════════════════════════════════════╝\n\n")

  # Step 1: Find missing translations
  cat("[Step 1/3] Finding missing translations...\n\n")

  find_result <- system2("Rscript", args = "scripts/find_missing_translations.R",
                        stdout = TRUE, stderr = TRUE)
  cat(paste(find_result, collapse = "\n"))

  # Check if missing_translations.txt was created
  if (!file.exists("missing_translations.txt")) {
    cat("\n✓ No missing translations found!\n")
    return(invisible(TRUE))
  }

  # Count lines
  missing_keys <- readLines("missing_translations.txt", warn = FALSE)
  missing_keys <- missing_keys[missing_keys != ""]
  n_missing <- length(missing_keys)

  cat(sprintf("\nFound %d missing translations.\n\n", n_missing))

  # Ask for confirmation
  cat("Proceed to automatically add all missing translations? (Y/n): ")
  response <- tolower(readLines("stdin", n = 1, warn = FALSE))

  if (response == "n" || response == "no") {
    cat("\nCancelled. Missing translations saved to missing_translations.txt\n")
    cat("You can process them later with:\n")
    cat("  Rscript scripts/translation_workflow.R add_batch missing_translations.txt\n")
    return(invisible(FALSE))
  }

  # Step 2: Batch add translations
  cat("\n[Step 2/3] Adding translations automatically...\n\n")

  add_result <- system2("Rscript",
                       args = c("scripts/add_translation_auto.R", "missing_translations.txt"),
                       stdout = TRUE, stderr = TRUE)
  cat(paste(add_result, collapse = "\n"))

  add_status <- attr(add_result, "status")
  if (!is.null(add_status) && add_status != 0) {
    cat("\n✗ Error adding translations\n")
    return(invisible(FALSE))
  }

  # Step 3: Validate
  cat("\n[Step 3/3] Validating translations...\n\n")

  validate_result <- system2("Rscript", args = "scripts/validate_translations.R",
                            stdout = TRUE, stderr = TRUE)
  cat(paste(validate_result, collapse = "\n"))

  validate_status <- attr(validate_result, "status")

  cat("\n╔═══════════════════════════════════════╗\n")
  if (is.null(validate_status) || validate_status == 0) {
    cat("║  ✓ COMPLETE - All translations added ║\n")
    cat("╚═══════════════════════════════════════╝\n\n")
    cat("Next steps:\n")
    cat("  1. Review the changes\n")
    cat("  2. Run tests: Rscript scripts/translation_workflow.R test\n")
    cat("  3. Commit: git add translations/ && git commit\n")
    return(invisible(TRUE))
  } else {
    cat("║  ⚠ COMPLETE with warnings             ║\n")
    cat("╚═══════════════════════════════════════╝\n\n")
    cat("Translations were added but validation found some issues.\n")
    cat("Review the validation output above.\n")
    return(invisible(TRUE))
  }
}

# ============================================================================
# HELP
# ============================================================================

show_help <- function() {
  cat("\n╔═══════════════════════════════════════════════════╗\n")
  cat("║  Translation Workflow Manager                    ║\n")
  cat("╚═══════════════════════════════════════════════════╝\n\n")

  cat("Usage: Rscript scripts/translation_workflow.R <command>\n\n")

  cat("Commands:\n\n")

  for (cmd_name in names(commands)) {
    cmd <- commands[[cmd_name]]
    cat(sprintf("  %-15s %s\n", cmd_name, cmd$desc))
    cat(sprintf("  %15s %s\n", "", cmd$help))
    cat("\n")
  }

  cat("Examples:\n\n")
  cat("  # Add single translation (auto-mode, recommended)\n")
  cat("  Rscript scripts/translation_workflow.R add\n\n")

  cat("  # Find and process ALL missing translations automatically\n")
  cat("  Rscript scripts/translation_workflow.R process_missing\n\n")

  cat("  # Add translations from file (batch)\n")
  cat("  Rscript scripts/translation_workflow.R add_batch missing_translations.txt\n\n")

  cat("  # Run pre-commit checks (always before committing!)\n")
  cat("  Rscript scripts/translation_workflow.R check\n\n")

  cat("  # Show translation statistics\n")
  cat("  Rscript scripts/translation_workflow.R stats\n\n")

  cat("  # Find missing translations\n")
  cat("  Rscript scripts/translation_workflow.R find_missing\n\n")
}

# ============================================================================
# MAIN
# ============================================================================

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0 || args[1] == "help" || args[1] == "--help") {
    show_help()
    return(invisible(NULL))
  }

  command <- args[1]

  if (!command %in% names(commands)) {
    cat("Unknown command:", command, "\n")
    cat("Run 'Rscript scripts/translation_workflow.R help' for usage.\n")
    quit(status = 1)
  }

  cmd <- commands[[command]]

  # Execute command
  if (!is.null(cmd$script)) {
    # Run external script
    result <- system2("Rscript", args = c(cmd$script, args[-1]),
                     stdout = TRUE, stderr = TRUE)
    cat(paste(result, collapse = "\n"))

    status <- attr(result, "status")
    if (!is.null(status) && status != 0) {
      quit(status = status)
    }
  } else {
    # Run inline command
    switch(command,
      stats = cmd_stats(),
      check = if (!cmd_check()) quit(status = 1),
      format = cmd_format(),
      find_unused = cmd_find_unused(),
      add_batch = {
        if (length(args) < 2) {
          cat("Error: add_batch requires a file path\n")
          cat("Usage: Rscript scripts/translation_workflow.R add_batch FILE.txt\n")
          quit(status = 1)
        }
        if (!cmd_add_batch(args[2])) quit(status = 1)
      },
      process_missing = if (!cmd_process_missing()) quit(status = 1)
    )
  }
}

# Run
main()
