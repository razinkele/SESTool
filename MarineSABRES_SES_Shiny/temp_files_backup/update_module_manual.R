# Manual approach: Create a summary of what needs to be changed
# Given the complexity, this creates a guide for manual updates

library(jsonlite)

# Load translations
trans_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE\Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_translations.json"
translations <- fromJSON(trans_file)

if (is.list(translations)) {
  all_texts <- sapply(translations, function(x) x$en)
} else {
  all_texts <- translations$en
}

# Read the module to identify lines
module_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/modules/scenario_builder_module.R"
code_lines <- readLines(module_file, warn = FALSE)

cat("i18n Update Guide for scenario_builder_module.R\n")
cat("================================================\n\n")

cat("APPROACH:\n")
cat("1. Add i18n parameter to both UI and server functions\n")
cat("2. Wrap all English text strings with i18n$t()\n\n")

cat("STEP 1: Update function signatures\n")
cat("-----------------------------------\n")
cat('Change: scenario_builder_ui <- function(id) {\n')
cat('To:     scenario_builder_ui <- function(id, i18n) {\n\n')

cat('Change: scenario_builder_server <- function(id, project_data_reactive) {\n')
cat('To:     scenario_builder_server <- function(id, project_data_reactive, i18n) {\n\n')

cat("STEP 2: Text Replacements (", length(all_texts), "total)\n")
cat("-----------------------------------\n\n")

# Group texts by likely location/type
ui_texts <- c(
  "Scenario Builder",
  "Create and analyze what-if scenarios by modifying your CLD network.",
  "No CLD Network Found",
  "You need to create a Causal Loop Diagram first before building scenarios.",
  "Please go to the CLD Visualization module to create your network.",
  "Scenarios",
  "New Scenario",
  "No scenarios yet. Create one to get started.",
  "Configure",
  "Impact Analysis",
  "Compare Scenarios",
  "Select a scenario from the list or create a new one to get started.",
  "Add/Modify Nodes",
  "Add New Node",
  "Remove Nodes",
  "Select node to remove:",
  "Remove Node",
  "Add/Modify Links",
  "Add New Link",
  "Remove Links",
  "Select link to remove:",
  "Remove Link",
  "Preview Network",
  "Run Impact Analysis"
)

cat("KEY UI TEXT REPLACEMENTS (examples):\n\n")
for (i in 1:min(10, length(ui_texts))) {
  text <- ui_texts[i]
  cat(sprintf('"%s"  =>  i18n$t("%s")\n', text, text))
}

cat("\n... and", length(all_texts), "total text strings\n\n")

cat("STEP 3: Check app.R or main file\n")
cat("-----------------------------------\n")
cat("Ensure i18n is passed to the module:\n")
cat('scenario_builder_server("scenario_builder", project_data, i18n = i18n)\n\n')

cat("OUTPUT FILES READY FOR MERGE:\n")
cat("  - scenario_builder_translations.json (all 114 translations)\n")
cat("  - scenario_builder_unique_translations.json (109 new ones)\n")
cat("  - scenario_builder_duplicates.json (5 already exist)\n\n")

cat("Note: Due to the large number of replacements (114), it's recommended to:\n")
cat("1. Use a text editor with find-replace regex support\n")
cat("2. Or manually update key sections one at a time\n")
cat("3. Test after each major section is updated\n")
