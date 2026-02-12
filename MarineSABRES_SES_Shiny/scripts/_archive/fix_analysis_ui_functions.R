#!/usr/bin/env Rscript
# Fix analysis tools UI functions to accept i18n parameter

file_path <- "modules/analysis_tools_module.R"

# Read the file
lines <- readLines(file_path)

# Find and replace the function signatures
replacements <- list(
  c("analysis_metrics_ui <- function(id) {", "analysis_metrics_ui <- function(id, i18n) {"),
  c("analysis_bot_ui <- function(id) {", "analysis_bot_ui <- function(id, i18n) {"),
  c("analysis_simplify_ui <- function(id) {", "analysis_simplify_ui <- function(id, i18n) {"),
  c("analysis_leverage_ui <- function(id) {", "analysis_leverage_ui <- function(id, i18n) {")
)

for (replacement in replacements) {
  old_pattern <- replacement[1]
  new_text <- replacement[2]

  # Find the line
  idx <- which(lines == old_pattern)
  if (length(idx) > 0) {
    lines[idx] <- new_text
    cat(sprintf("✅ Replaced: %s\n", old_pattern))
  } else {
    cat(sprintf("❌ Not found: %s\n", old_pattern))
  }
}

# Write back
writeLines(lines, file_path)

cat("\n✅ File updated successfully!\n")
