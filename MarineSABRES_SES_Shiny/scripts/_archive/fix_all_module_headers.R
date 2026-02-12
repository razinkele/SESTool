#!/usr/bin/env Rscript
# Fix ALL module headers to use proper translation keys
# This script identifies and fixes hardcoded English text in create_module_header calls

cat("=== Fixing All Module Headers ===\n\n")

# List of modules and their hardcoded headers that need fixing
fixes <- list(
  # Analysis Tools - Loop Detection
  list(
    file = "modules/analysis_tools_module.R",
    old_title = '"Feedback Loop Detection and Analysis"',
    new_title = '"modules.analysis.loops.title"',
    old_subtitle = '"Automatically identify and analyze feedback loops in your Causal Loop Diagram."',
    new_subtitle = '"modules.analysis.loops.subtitle"'
  ),

  # Analysis Tools - Leverage Points
  list(
    file = "modules/analysis_tools_module.R",
    old_title = '"Leverage Point Analysis"',
    new_title = '"modules.analysis.leverage.title"',
    old_subtitle = '"Identify the most influential nodes in your network that could serve as key intervention points."',
    new_subtitle = '"modules.analysis.leverage.subtitle"'
  ),

  # CLD Visualization
  list(
    file = "modules/cld_visualization_module.R",
    old_title = '"Causal Loop Diagram Visualization"',
    new_title = '"modules.cld.visualization.title"',
    old_subtitle = '"Interactive network visualization of your social-ecological system"',
    new_subtitle = '"modules.cld.visualization.subtitle"'
  ),

  # Create SES
  list(
    file = "modules/create_ses_module.R",
    old_title = '"Create Your Social-Ecological System"',
    new_title = '"modules.ses.creation.title"',
    old_subtitle = '"Choose the method that best fits your experience level and project needs"',
    new_subtitle = '"modules.ses.creation.subtitle"'
  ),

  # Export Reports
  list(
    file = "modules/export_reports_module.R",
    old_title = '"Export & Reports"',
    new_title = '"modules.export.reports.title"',
    old_subtitle = '"Export your data, visualizations, and generate comprehensive reports."',
    new_subtitle = '"modules.export.reports.subtitle"'
  ),

  # ISA Data Entry
  list(
    file = "modules/isa_data_entry_module.R",
    old_title = '"Integrated Systems Analysis (ISA) Data Entry"',
    new_title = '"modules.isa.data_entry.title"',
    old_subtitle = '"Follow the structured exercises to build your marine Social-Ecological System analysis."',
    new_subtitle = '"modules.isa.data_entry.subtitle"'
  ),

  # Template SES
  list(
    file = "modules/template_ses_module.R",
    old_title = '"Template-Based SES Creation"',
    new_title = '"modules.ses.template.title"',
    old_subtitle = '"Choose a pre-built template that matches your scenario and customize it to your needs"',
    new_subtitle = '"modules.ses.template.subtitle"'
  ),

  # PIMS Resources - non-namespaced key fix
  list(
    file = "modules/pims_module.R",
    old_subtitle = '"pims_resources_subtitle"',
    new_subtitle = '"modules.pims.resources.subtitle"',
    skip_title = TRUE  # Only fix subtitle
  )
)

fixed_count <- 0
error_count <- 0

for (fix in fixes) {
  cat(sprintf("Processing: %s\n", fix$file))

  if (!file.exists(fix$file)) {
    cat(sprintf("  ✗ File not found: %s\n\n", fix$file))
    error_count <- error_count + 1
    next
  }

  content <- readLines(fix$file, warn = FALSE)
  original_content <- content
  modified <- FALSE

  # Fix title
  if (is.null(fix$skip_title) || !fix$skip_title) {
    if (!is.null(fix$old_title) && !is.null(fix$new_title)) {
      new_content <- gsub(fix$old_title, fix$new_title, content, fixed = TRUE)
      if (!identical(content, new_content)) {
        content <- new_content
        modified <- TRUE
        cat(sprintf("  ✓ Fixed title\n"))
      }
    }
  }

  # Fix subtitle
  if (!is.null(fix$old_subtitle) && !is.null(fix$new_subtitle)) {
    new_content <- gsub(fix$old_subtitle, fix$new_subtitle, content, fixed = TRUE)
    if (!identical(content, new_content)) {
      content <- new_content
      modified <- TRUE
      cat(sprintf("  ✓ Fixed subtitle\n"))
    }
  }

  if (modified) {
    writeLines(content, fix$file)
    cat(sprintf("  ✓ Updated %s\n\n", fix$file))
    fixed_count <- fixed_count + 1
  } else {
    cat(sprintf("  → No changes needed (already fixed)\n\n"))
  }
}

cat(sprintf("=== Summary ===\n"))
cat(sprintf("Files fixed: %d\n", fixed_count))
cat(sprintf("Errors: %d\n", error_count))

if (error_count == 0) {
  cat("\n✓ All module headers have been updated!\n")
  cat("\nNext step: Run scripts/add_missing_translation_keys.R to add the translation keys to JSON files\n")
  quit(status = 0)
} else {
  cat(sprintf("\n✗ %d errors encountered\n", error_count))
  quit(status = 1)
}
