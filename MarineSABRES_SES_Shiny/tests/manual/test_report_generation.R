# Test report generation outside of Shiny to identify the error
# This script loads a saved project and attempts to generate a report

cat("Loading functions...\n")
source("functions/report_generation.R")

cat("Loading saved project data...\n")
# Find autosave directories
autosave_dirs <- list.files("/tmp", pattern = "^Rtmp.*", full.names = TRUE, include.dirs = TRUE)
autosave_dirs <- file.path(autosave_dirs, "marinesabres_autosave")
autosave_dirs <- autosave_dirs[dir.exists(autosave_dirs)]

if (length(autosave_dirs) == 0) {
  stop("No autosave directory found. Please load a project in the app first.")
}

# Get the most recently modified directory
mod_times <- file.mtime(autosave_dirs)
autosave_dir <- autosave_dirs[which.max(mod_times)]

cat("Autosave directory:", autosave_dir, "\n")

# Find the most recent .rds file
rds_files <- list.files(autosave_dir, pattern = "\\.rds$", full.names = TRUE)
if (length(rds_files) == 0) {
  stop("No autosave files found. Please load a project in the app first.")
}

latest_file <- rds_files[which.max(file.mtime(rds_files))]
cat("Loading:", latest_file, "\n")

project_data <- readRDS(latest_file)

cat("\nProject data structure:\n")
cat("Names:", paste(names(project_data), collapse = ", "), "\n")
cat("Project name:", project_data$project_name, "\n")

# Check metadata
cat("\nMetadata structure:\n")
cat("da_site class:", class(project_data$data$metadata$da_site), "\n")
cat("da_site is.list:", is.list(project_data$data$metadata$da_site), "\n")
cat("da_site value:", project_data$data$metadata$da_site, "\n")
cat("focal_issue class:", class(project_data$data$metadata$focal_issue), "\n")
cat("focal_issue is.list:", is.list(project_data$data$metadata$focal_issue), "\n")
cat("focal_issue value:", project_data$data$metadata$focal_issue, "\n")

cat("\n========================================\n")
cat("TESTING REPORT GENERATION\n")
cat("========================================\n")

# Try to generate each report type
for (report_type in c("executive", "technical", "presentation", "full")) {
  cat("\n--- Testing:", report_type, "---\n")
  tryCatch({
    content <- generate_report_content(
      data = project_data,
      report_type = report_type,
      include_viz = TRUE,
      include_data = FALSE
    )
    cat("SUCCESS! Generated", nchar(content), "characters\n")
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    cat("Error occurred in", report_type, "report\n")
    print(e)
  })
}

cat("\n========================================\n")
cat("TEST COMPLETE\n")
cat("========================================\n")
