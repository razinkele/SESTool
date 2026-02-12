#!/usr/bin/env Rscript
# Fix all module headers to use namespaced translation keys

# Mapping of old non-namespaced keys to new namespaced keys
replacements <- list(
  c('"import_data_title"', '"modules.import.data.title"'),
  c('"import_data_subtitle"', '"modules.import.data.subtitle"'),
  c('"pims_project_title"', '"modules.pims.project.title"'),
  c('"pims_project_subtitle"', '"modules.pims.project.subtitle"'),
  c('"pims_stakeholders_title"', '"modules.pims.stakeholders.title"'),
  c('"pims_stakeholders_subtitle"', '"modules.pims.stakeholders.subtitle"'),
  c('"pims_resources_title"', '"modules.pims.resources.title"'),
  c('"pims_data_title"', '"modules.pims.data.title"'),
  c('"pims_data_subtitle"', '"modules.pims.data.subtitle"'),
  c('"pims_evaluation_title"', '"modules.pims.evaluation.title"'),
  c('"pims_evaluation_subtitle"', '"modules.pims.evaluation.subtitle"'),
  c('"pims_stakeholder_title"', '"modules.pims.stakeholder.title"'),
  c('"pims_stakeholder_subtitle"', '"modules.pims.stakeholder.subtitle"')
)

files <- c(
  "modules/import_data_module.R",
  "modules/pims_module.R",
  "modules/pims_stakeholder_module.R"
)

for (file in files) {
  if (!file.exists(file)) {
    cat("Skipping", file, "(not found)\n")
    next
  }

  content <- readLines(file)
  modified <- FALSE

  for (repl in replacements) {
    old_key <- repl[1]
    new_key <- repl[2]

    # Replace in content
    new_content <- gsub(old_key, new_key, content, fixed = TRUE)

    if (!identical(content, new_content)) {
      content <- new_content
      modified <- TRUE
      cat("  Replaced", old_key, "with", new_key, "in", file, "\n")
    }
  }

  if (modified) {
    writeLines(content, file)
    cat("✓ Updated", file, "\n\n")
  } else {
    cat("  No changes needed in", file, "\n\n")
  }
}

cat("All module headers updated!\n")
