# fix_tuscan_da_types.R
# Script to add inferred DAPSIWRM types to Tuscan DA Excel files
# These files have 100% NA values in their Type columns

library(readxl)
library(openxlsx)

# Set working directory to app root
app_root <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny"
setwd(app_root)

# Source the type inference module
source("functions/dapsiwrm_type_inference.R")

# Files to fix
tuscan_files <- c(
 "SESModels/Tuscan DA/KUMU_TA_Full model CLD.xlsx",
 "SESModels/Tuscan DA/Simplified final map SES.xlsx",
 "SESModels/Tuscan DA/Simplified final map SES_MPASimplified.xlsx",
 "SESModels/Tuscan DA/Simplified final map SES_TurismSimplified.xlsx"
)

cat("=" , rep("=", 79), "\n", sep = "")
cat("TUSCAN DA TYPE INFERENCE FIX SCRIPT\n")
cat("=" , rep("=", 79), "\n\n", sep = "")

for (file_path in tuscan_files) {
 if (!file.exists(file_path)) {
   cat("WARNING: File not found:", file_path, "\n")
   next
 }

 cat("\n", rep("-", 70), "\n", sep = "")
 cat("Processing:", basename(file_path), "\n")
 cat(rep("-", 70), "\n", sep = "")

 # Read the Elements sheet
 elements <- tryCatch({
   read_excel(file_path, sheet = "Elements")
 }, error = function(e) {
   cat("ERROR reading Elements sheet:", e$message, "\n")
   NULL
 })

 if (is.null(elements)) {
   next
 }

 cat("Original element count:", nrow(elements), "\n")
 cat("Original Type column NA count:", sum(is.na(elements$Type)), "\n\n")

 # Show original labels
 cat("Element labels:\n")
 for (i in 1:min(nrow(elements), 10)) {
   cat(sprintf("  %2d. %s\n", i, elements$Label[i]))
 }
 if (nrow(elements) > 10) {
   cat(sprintf("  ... and %d more\n", nrow(elements) - 10))
 }
 cat("\n")

 # Infer types
 cat("Inferring DAPSIWRM types from element names...\n\n")
 keywords <- get_dapsiwrm_keywords()

 inferred_types <- character(nrow(elements))
 inference_details <- list()

 for (i in 1:nrow(elements)) {
   label <- elements$Label[i]
   if (!is.na(label) && nzchar(trimws(label))) {
     result <- infer_dapsiwrm_type(label, keywords, return_score = TRUE)
     if (!is.na(result$type)) {
       inferred_types[i] <- result$type
       inference_details[[i]] <- list(
         label = label,
         type = result$type,
         score = result$score,
         keywords = result$matches
       )
       cat(sprintf("  %-45s -> %-30s (score: %d)\n",
                   substr(label, 1, 45),
                   result$type,
                   result$score))
     } else {
       inferred_types[i] <- NA_character_
       cat(sprintf("  %-45s -> NO MATCH\n", substr(label, 1, 45)))
     }
   } else {
     inferred_types[i] <- NA_character_
   }
 }

 # Summary
 cat("\n")
 cat("Inference Summary:\n")
 type_table <- table(inferred_types, useNA = "ifany")
 for (t in names(sort(type_table, decreasing = TRUE))) {
   display <- if (is.na(t)) "<Unmatched>" else t
   cat(sprintf("  %-30s: %d\n", display, type_table[t]))
 }

 matched_count <- sum(!is.na(inferred_types))
 cat(sprintf("\nMatched: %d/%d (%.1f%%)\n",
             matched_count, nrow(elements),
             100 * matched_count / nrow(elements)))

 # Ask to update file
 cat("\n")

 # Update the Type column
 elements$Type <- inferred_types

 # Also update lowercase 'type' column if it exists
 if ("type" %in% names(elements)) {
   elements$type <- inferred_types
 }

 # Create output file path (add _fixed suffix)
 output_path <- sub("\\.xlsx$", "_FIXED.xlsx", file_path)

 # Read all sheets from original file
 cat("Creating fixed file:", basename(output_path), "\n")

 # Create new workbook
 wb <- createWorkbook()

 # Add Elements sheet with fixed types
 addWorksheet(wb, "Elements")
 writeData(wb, "Elements", elements)

 # Copy Connections sheet
 connections <- tryCatch({
   read_excel(file_path, sheet = "Connections")
 }, error = function(e) NULL)

 if (!is.null(connections)) {
   addWorksheet(wb, "Connections")
   writeData(wb, "Connections", connections)
 }

 # Save workbook
 saveWorkbook(wb, output_path, overwrite = TRUE)
 cat("Saved:", output_path, "\n")

 # Also create a version that overwrites original (backup first)
 backup_path <- sub("\\.xlsx$", "_BACKUP.xlsx", file_path)
 if (!file.exists(backup_path)) {
   file.copy(file_path, backup_path)
   cat("Created backup:", basename(backup_path), "\n")
 }

 # Overwrite original
 saveWorkbook(wb, file_path, overwrite = TRUE)
 cat("Updated original file:", basename(file_path), "\n")
}

cat("\n")
cat("=" , rep("=", 79), "\n", sep = "")
cat("PROCESSING COMPLETE\n")
cat("=" , rep("=", 79), "\n")
cat("\nFiles have been updated with inferred DAPSIWRM types.\n")
cat("Backup files (*_BACKUP.xlsx) have been created.\n")
cat("You can also find *_FIXED.xlsx versions with the changes.\n")
