#!/usr/bin/env Rscript
# Cleanup temporary files from internationalization work

cat("=== Cleaning up temporary files ===\n\n")

# Create backup directory
backup_dir <- "temp_files_backup"
if (!dir.exists(backup_dir)) {
  dir.create(backup_dir)
  cat("Created backup directory:", backup_dir, "\n")
}

# Define core files that should NOT be deleted
core_files <- c(
  "app.R",
  "global.R",
  "install_packages.R",
  "run_app.R",
  "version_manager.R",
  "VERSION_INFO.json"
)

# Get all .R and .json files in root
all_r_files <- list.files(".", pattern = "\\.R$", full.names = FALSE)
all_json_files <- list.files(".", pattern = "\\.json$", full.names = FALSE)

# Identify temporary files
temp_r_files <- setdiff(all_r_files, core_files)
temp_json_files <- setdiff(all_json_files, core_files)

# Filter for obvious temporary patterns
temp_patterns <- c(
  "^add_", "^check_", "^compare_", "^convert_", "^count_",
  "^deduplicate_", "^diagnose_", "^extract_", "^filter_",
  "^find_", "^generate_", "^merge_", "^reformat_", "^test_",
  "^update_", "^validate_",
  "_translations\\.json$", "_translations_clean\\.json$",
  "_translations_to_add\\.json$", "_translation\\.json$",
  "^ai_isa_", "^isa_", "^pims_", "^response_", "^scenario_",
  "^validation_", "^template_", "^progress_", "^ep_notify",
  "^cld_", "^missing_", "^remaining_", "^app_header",
  "^create_ses_translations", "^entry_point_translations",
  "^filtered_"
)

# Find temp files to move
temp_to_move <- c()
for (file in c(temp_r_files, temp_json_files)) {
  for (pattern in temp_patterns) {
    if (grepl(pattern, file, ignore.case = TRUE)) {
      temp_to_move <- c(temp_to_move, file)
      break
    }
  }
}

# Remove duplicates
temp_to_move <- unique(temp_to_move)

if (length(temp_to_move) > 0) {
  cat("\nMoving", length(temp_to_move), "temporary files to backup directory...\n\n")

  moved_count <- 0
  for (file in temp_to_move) {
    if (file.exists(file)) {
      tryCatch({
        file.copy(file, file.path(backup_dir, file), overwrite = TRUE)
        file.remove(file)
        cat("  Moved:", file, "\n")
        moved_count <- moved_count + 1
      }, error = function(e) {
        cat("  Error moving", file, ":", e$message, "\n")
      })
    }
  }

  cat("\n✓ Moved", moved_count, "files to", backup_dir, "\n")
  cat("✓ Core files preserved:", paste(core_files, collapse = ", "), "\n")
} else {
  cat("No temporary files found to clean up\n")
}

# Check for backup module files
module_backups <- list.files("modules", pattern = "\\.R\\.(backup|old|new)$", full.names = TRUE)
if (length(module_backups) > 0) {
  cat("\nFound", length(module_backups), "module backup files:\n")
  for (f in module_backups) {
    cat("  •", basename(f), "\n")
  }
  cat("\nTo remove module backups, delete them manually from the modules/ directory\n")
}

# Also check for text files that might be temporary
txt_files <- list.files(".", pattern = "\\.(txt|md)$", full.names = FALSE)
temp_txt <- grep("^(labels|descriptions|all_unique|template_strings|remaining_|missing_)", txt_files, value = TRUE, ignore.case = TRUE)

if (length(temp_txt) > 0) {
  cat("\nFound", length(temp_txt), "temporary text/markdown files:\n")
  for (f in temp_txt) {
    cat("  •", f, "\n")
  }
  cat("\nThese files were not moved. If you want to clean them up, delete them manually\n")
}

cat("\n=== Cleanup Complete ===\n")
