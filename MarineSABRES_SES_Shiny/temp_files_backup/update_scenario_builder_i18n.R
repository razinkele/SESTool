# Update scenario_builder_module.R with i18n$t() wrapper calls
# This script wraps all hardcoded English text with i18n$t()

library(stringr)

# Read the original module file
module_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/modules/scenario_builder_module.R"
code_lines <- readLines(module_file, warn = FALSE)

# Create backup
backup_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/modules/scenario_builder_module.R.backup"
writeLines(code_lines, backup_file)
cat("Created backup:", backup_file, "\n\n")

# Load all translations to know what strings to wrap
library(jsonlite)
trans_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_translations.json"
translations <- fromJSON(trans_file)

if (is.data.frame(translations)) {
  all_texts <- translations$en
} else if (is.list(translations)) {
  all_texts <- sapply(translations, function(x) x$en)
}

cat("Total texts to wrap:", length(all_texts), "\n")

# Function to wrap a text with i18n$t()
wrap_text <- function(text) {
  # Escape special regex characters
  escaped <- gsub("([.()[]{}*+?^$|\\\\])", "\\\\\\1", text)
  return(paste0('i18n$t("', text, '")'))
}

# Modified code - join all lines
code <- paste(code_lines, collapse = "\n")

# Key replacement patterns
# Priority: longer strings first to avoid partial replacements
all_texts_sorted <- all_texts[order(-nchar(all_texts))]

replacement_count <- 0

for (text in all_texts_sorted) {
  # Skip very short fragments that might cause issues
  if (nchar(text) < 3) next

  # Different context patterns where this text appears
  patterns <- c(
    # In h2, h3, h4, h5, p tags: h2("text") -> h2(i18n$t("text"))
    paste0('(h[2-6]\\([^)]*)"', str_replace_all(text, fixed("("), "\\("), '"'),
    paste0('(p\\([^)]*)"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In actionButton: actionButton(..., "text") -> actionButton(..., i18n$t("text"))
    paste0('(actionButton\\([^,]+,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In modalButton: modalButton("text") -> modalButton(i18n$t("text"))
    paste0('(modalButton\\()"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In selectInput label: selectInput(..., "label:", ...) -> selectInput(..., i18n$t("label:"), ...)
    paste0('(selectInput\\([^,]+,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In textInput/textAreaInput labels
    paste0('(textInput\\([^,]+,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),
    paste0('(textAreaInput\\([^,]+,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In tabPanel: tabPanel("text") -> tabPanel(i18n$t("text"))
    paste0('(tabPanel\\()"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In tags$strong/tags$p
    paste0('(tags\\$strong\\()"', str_replace_all(text, fixed("("), "\\("), '"'),
    paste0('(tags\\$p\\()"', str_replace_all(text, fixed("("), "\\("), '"'),

    # In div/span class texts
    paste0('(div\\([^)]*,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),
    paste0('(span\\([^)]*,\\s*)"', str_replace_all(text, fixed("("), "\\("), '"'),

    # Simple quoted strings in common contexts
    paste0('"', str_replace_all(text, fixed("("), "\\("), '"')
  )

  # Try each pattern
  for (pattern in patterns) {
    replacement <- paste0('\\1i18n$t("', text, '")')

    # Check if pattern exists
    if (str_detect(code, pattern)) {
      code <- str_replace_all(code, pattern, replacement)
      replacement_count <- replacement_count + 1
      break  # Found a match, move to next text
    }
  }
}

cat("Made", replacement_count, "replacements\n\n")

# Write updated code
code_lines_new <- strsplit(code, "\n")[[1]]
writeLines(code_lines_new, module_file)

cat("Updated module file:", module_file, "\n")
cat("Backup saved to:", backup_file, "\n")
cat("\nNote: Please review the updated file to ensure all replacements are correct.\n")
cat("The backup can be restored if needed.\n")
