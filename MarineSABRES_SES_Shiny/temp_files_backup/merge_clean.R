#!/usr/bin/env Rscript
library(jsonlite)

cat("Clean merge of AI ISA translations...\n\n")

# Load files
cat("Loading base translations (856 keys)...\n")
base <- fromJSON('translations/translation_backup_20251103_232419.json', simplifyDataFrame = TRUE)
base_df <- base$translation

cat("Loading AI ISA translations (178 keys)...\n")
ai_isa <- fromJSON('ai_isa_assistant_translations.json', simplifyDataFrame = TRUE)
ai_isa_df <- ai_isa$translation

# Check for duplicates
dups <- ai_isa_df$en[ai_isa_df$en %in% base_df$en]
cat(sprintf("\nDuplicates found: %d\n", length(dups)))
if (length(dups) > 0) {
  cat("Duplicate keys:\n")
  for (d in dups) cat("  -", d, "\n")
}

# Remove duplicates from AI ISA
ai_isa_clean <- ai_isa_df[!(ai_isa_df$en %in% base_df$en), ]
cat(sprintf("\nAfter removing duplicates: %d new AI ISA keys\n", nrow(ai_isa_clean)))

# Merge
merged_df <- rbind(base_df, ai_isa_clean)
cat(sprintf("\nMerged total: %d keys\n", nrow(merged_df)))

# Convert back to list format for JSON
merged_list <- lapply(1:nrow(merged_df), function(i) {
  as.list(merged_df[i, ])
})

# Save
output <- list(translation = merged_list)
write_json(output, 'translations/translation.json', pretty = TRUE, auto_unbox = TRUE)

cat("\n✓ Clean merge complete!\n")
cat(sprintf("  Base: %d keys\n", nrow(base_df)))
cat(sprintf("  AI ISA (unique): %d keys\n", nrow(ai_isa_clean)))
cat(sprintf("  Total: %d keys\n", nrow(merged_df)))
