#!/usr/bin/env Rscript
# Find all module headers that need fixing

# Pattern: create_module_header calls
files <- list.files("modules", pattern = "\\.R$", full.names = TRUE)

cat("Checking module headers...\n\n")

for (file in files) {
  lines <- readLines(file)

  for (i in seq_along(lines)) {
    if (grepl("create_module_header", lines[i])) {
      # Check if it has unquoted strings or doesn't start with "modules."
      if (!grepl('i18n\\$t\\(', lines[i])) {
        # Extract the parameters
        cat(sprintf("%s:%d\n  %s\n\n", basename(file), i, trimws(lines[i])))
      }
    }
  }
}
