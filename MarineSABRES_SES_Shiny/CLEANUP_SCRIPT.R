# Cleanup Script for Remaining Debug Logging
# Run this to complete the debug logging cleanup in report_generation.R

# This script provides sed-like replacements for the remaining 50 cat() calls
# in functions/report_generation.R

cat("=== Debug Logging Cleanup Script ===\n\n")

# Define replacements
replacements <- list(
  # Simple format: "[Context] message"
  list(
    pattern = 'cat\\("\\s*\\[Full\\]\\s+(.+?)\\\\n"\\)',
    replacement = 'debug_log("\\1", "FULL")'
  ),
  list(
    pattern = 'cat\\("\\s*\\[Full\\]\\s+DEBUG - (.+?)\\\\n"\\)',
    replacement = 'debug_log("DEBUG: \\1", "FULL")'
  ),
  # Complex format with variables
  list(
    pattern = 'cat\\("\\s*\\[Full\\]\\s+DEBUG - (.+?):", (.+?), "\\\\n"\\)',
    replacement = 'debug_log(sprintf("DEBUG: \\1: %s", \\2), "FULL")'
  ),
  # Multiple variables
  list(
    pattern = 'cat\\("\\s*([^"]+):", (.+?), "class:", class\\((.+?)\\), "\\\\n"\\)',
    replacement = 'debug_log(sprintf("\\1: %s (class: %s)", \\2, class(\\3)), "FULL")'
  ),
  # Remove flush.console()
  list(
    pattern = 'flush\\.console\\(\\)',
    replacement = '# flush.console() removed - not needed with debug_log()'
  )
)

cat("Replacement patterns defined:\n")
for (i in seq_along(replacements)) {
  cat(sprintf("  %d. %s\n     -> %s\n", i,
              replacements[[i]]$pattern,
              replacements[[i]]$replacement))
}

cat("\n=== Manual Replacement Instructions ===\n\n")
cat("1. Open functions/report_generation.R in your text editor\n")
cat("2. Use Find & Replace with regex enabled\n")
cat("3. Apply each pattern replacement above\n")
cat("4. Verify no cat() calls remain (except in comments)\n")
cat("5. Test report generation with DEBUG_MODE=FALSE and TRUE\n")

cat("\n=== Expected Result ===\n")
cat("Before: 50+ raw cat() calls\n")
cat("After:  All replaced with debug_log() calls\n")
cat("Benefit: Zero console noise in production mode\n")

# Example transformation
cat("\n=== Example Transformation ===\n\n")
cat("BEFORE:\n")
cat('  cat("  [Full] Building enhanced sections...\\n")\n')
cat('  cat("  [Full] DEBUG - n_loops:", n_loops, "class:", class(n_loops), "\\n")\n')
cat('  flush.console()\n\n')

cat("AFTER:\n")
cat('  debug_log("Building enhanced sections", "FULL")\n')
cat('  debug_log(sprintf("DEBUG: n_loops: %s (class: %s)", n_loops, class(n_loops)), "FULL")\n')
cat('  # flush.console() removed - not needed with debug_log()\n\n')

cat("=== Script Complete ===\n")
cat("Status: Pattern documented, manual application recommended\n")
cat("Estimated time: 10-15 minutes for complete cleanup\n")

# ============================================================================
# BACKUP FILE CLEANUP
# ============================================================================
# Backup files identified for cleanup.
# These files are not sourced by any production code and can be safely removed.
# Review this list and run the deletion commands below.
#
# Generated: 2026-02-03
# Patterns searched: *_backup.R, *_old.R, *-laguna-safeBackup-*.R, *_v2.R
# Directories searched: modules/, functions/
# Verification: grep for source() references found ZERO matches.

cat("\n\n=== Backup File Cleanup ===\n\n")

backup_files <- c(
  # modules/ - laguna-safeBackup files (10 files)
  "modules/ai_isa_assistant_module-laguna-safeBackup-0001.R",
  "modules/cld_visualization_module-laguna-safeBackup-0001.R",
  "modules/connection_review_tabbed-laguna-safeBackup-0001.R",
  "modules/prepare_report_module-laguna-safeBackup-0001.R",
  "modules/export_reports_module-laguna-safeBackup-0001.R",
  "modules/graphical_ses_creator_module-laguna-safeBackup-0001.R",
  "modules/import_data_module-laguna-safeBackup-0001.R",
  "modules/pims_module-laguna-safeBackup-0001.R",
  "modules/template_recommendation_module-laguna-safeBackup-0001.R",
  "modules/template_ses_module-laguna-safeBackup-0001.R",
  # functions/ - laguna-safeBackup files (8 files)
  "functions/network_analysis_enhanced-laguna-safeBackup-0001.R",
  "functions/error_handling-laguna-safeBackup-0001.R",
  "functions/export_functions-laguna-safeBackup-0001.R",
  "functions/ml_context_embeddings-laguna-safeBackup-0001.R",
  "functions/dapsiwrm_connection_rules-laguna-safeBackup-0001.R",
  "functions/data_structure-laguna-safeBackup-0001.R",
  "functions/template_loader-laguna-safeBackup-0001.R",
  "functions/visnetwork_helpers-laguna-safeBackup-0001.R"
)

cat("The following backup files can be safely removed:\n\n")
for (f in backup_files) {
  exists <- file.exists(f)
  cat(sprintf("  %s [%s]\n", f, ifelse(exists, "EXISTS", "MISSING")))
}

cat(sprintf("\nTotal: %d files\n", length(backup_files)))
cat("\nTo delete all backup files, run:\n")
cat("  file.remove(backup_files)\n")
cat("\nNote: These files are OneDrive/cloud sync safe-backup artifacts.\n")
cat("They are already covered by .gitignore patterns (*-laguna-safeBackup-*).\n")
cat("Deleting them will not affect any production functionality.\n")
