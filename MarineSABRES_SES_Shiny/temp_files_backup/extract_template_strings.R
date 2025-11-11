#!/usr/bin/env Rscript
# Extract all hard-coded template strings from AI ISA module

library(stringr)

# Read module file
module_code <- readLines('modules/ai_isa_assistant_module.R')

# Find lines with template data (between observeEvent(input$template_ and next observeEvent or closing brace)
template_lines <- module_code[1373:1640]

# Extract strings from list(name = "...", ...) patterns
name_strings <- str_extract_all(paste(template_lines, collapse = "\n"),
                                'name = "([^"]+)"')[[1]]
name_strings <- str_replace_all(name_strings, 'name = "|"', '')

# Extract context strings (project_name, ecosystem_type, main_issue)
context_strings <- c(
  str_extract_all(paste(template_lines, collapse = "\n"),
                 'project_name = "([^"]+)"')[[1]],
  str_extract_all(paste(template_lines, collapse = "\n"),
                 'ecosystem_type = "([^"]+)"')[[1]],
  str_extract_all(paste(template_lines, collapse = "\n"),
                 'main_issue = "([^"]+)"')[[1]]
)
context_strings <- str_replace_all(context_strings, '(project_name|ecosystem_type|main_issue) = "|"', '')

# Extract connection from/to strings
from_to_strings <- c(
  str_extract_all(paste(template_lines, collapse = "\n"),
                 'from = "([^"]+)"')[[1]],
  str_extract_all(paste(template_lines, collapse = "\n"),
                 'to = "([^"]+)"')[[1]]
)
from_to_strings <- str_replace_all(from_to_strings, '(from|to) = "|"', '')

# Combine all unique strings
all_template_strings <- unique(c(name_strings, context_strings, from_to_strings))

cat("Found", length(all_template_strings), "unique template strings:\n\n")
for (s in sort(all_template_strings)) {
  cat('"', s, '",\n', sep='')
}

# Save to file
writeLines(sort(all_template_strings), "template_strings.txt")
cat("\n✓ Saved to template_strings.txt\n")
