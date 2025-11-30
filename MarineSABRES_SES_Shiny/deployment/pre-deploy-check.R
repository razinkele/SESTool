#!/usr/bin/env Rscript
# ============================================================================
# MarineSABRES SES Tool - Pre-Deployment Check Script
# ============================================================================
#
# This script validates the application before deployment
# Run this before deploying to catch common issues
#
# Usage:
#   Rscript pre-deploy-check.R
#
# ============================================================================

cat("================================================================================\n")
cat("MarineSABRES SES Tool - Pre-Deployment Validation\n")
cat("================================================================================\n\n")

# Set working directory to app root
setwd("..")

# Initialize counters
errors <- 0
warnings <- 0
checks_passed <- 0

# Helper functions
print_check <- function(name, status, message = "") {
  if (status == "PASS") {
    cat(sprintf("✓ %s\n", name))
    checks_passed <<- checks_passed + 1
  } else if (status == "WARN") {
    cat(sprintf("⚠ %s: %s\n", name, message))
    warnings <<- warnings + 1
  } else {
    cat(sprintf("✗ %s: %s\n", name, message))
    errors <<- errors + 1
  }
}

# ============================================================================
# Check 1: Required files exist
# ============================================================================
cat("\n[1] Checking Required Files...\n")

required_files <- c(
  "app.R",
  "global.R",
  "run_app.R",
  "constants.R",
  "io.R",
  "utils.R",
  "VERSION",
  "VERSION_INFO.json",
  "version_manager.R",
  "functions/translation_loader.R"
)

for (file in required_files) {
  if (file.exists(file)) {
    print_check(paste("File:", file), "PASS")
  } else {
    print_check(paste("File:", file), "ERROR", "File not found")
  }
}

# ============================================================================
# Check 2: Required directories exist
# ============================================================================
cat("\n[2] Checking Required Directories...\n")

required_dirs <- c(
  "modules",
  "functions",
  "server",
  "www",
  "data",
  "translations"
)

for (dir in required_dirs) {
  if (dir.exists(dir)) {
    print_check(paste("Directory:", dir), "PASS")
  } else {
    print_check(paste("Directory:", dir), "ERROR", "Directory not found")
  }
}

# Check optional directories
if (dir.exists("docs")) {
  print_check("Directory: docs (optional)", "PASS")
} else {
  print_check("Directory: docs (optional)", "WARN", "Documentation directory not found")
}

# Validate JSON templates exist in data directory
cat("\n[2.1] Checking JSON Templates in data/...\n")
if (dir.exists("data")) {
  json_templates <- list.files("data", pattern = ".*_SES_Template\\.json$", full.names = FALSE)
  if (length(json_templates) > 0) {
    print_check("JSON templates in data/", "PASS")
    cat(sprintf("   Found %d template(s): %s\n", length(json_templates), paste(json_templates, collapse = ", ")))
  } else {
    print_check("JSON templates in data/", "WARN", "No SES template JSON files found")
  }
} else {
  print_check("JSON templates in data/", "ERROR", "data/ directory does not exist")
}

# ============================================================================
# Check 3: Validate Modular Translation System
# ============================================================================
cat("\n[3] Validating Modular Translation System...\n")

# Check for translation subdirectories
translation_subdirs <- c("common", "modules", "ui", "data")
all_subdirs_exist <- TRUE
for (subdir in translation_subdirs) {
  subdir_path <- file.path("translations", subdir)
  if (dir.exists(subdir_path)) {
    print_check(paste("Translation subdir:", subdir), "PASS")
  } else {
    print_check(paste("Translation subdir:", subdir), "ERROR", "Directory not found")
    all_subdirs_exist <- FALSE
  }
}

# Check for translation files in subdirectories
if (all_subdirs_exist) {
  tryCatch({
    library(jsonlite)

    # Find all modular translation JSON files
    json_files <- list.files(
      path = "translations",
      pattern = "\\.json$",
      full.names = TRUE,
      recursive = TRUE
    )

    # Exclude backups and legacy files
    json_files <- json_files[!grepl("backup|translation\\.json$|ui_flat_keys\\.json$",
                                    json_files, ignore.case = TRUE)]

    # Only include modular files
    json_files <- json_files[grepl("(_[a-z]+\\.json$|/common/|/modules/|/ui/|/data/)", json_files)]

    if (length(json_files) > 0) {
      print_check("Modular translation files", "PASS")
      cat(sprintf("   Found %d modular translation files\n", length(json_files)))

      # Validate structure of each file
      valid_count <- 0
      invalid_files <- c()

      for (file_path in json_files) {
        data <- tryCatch({
          fromJSON(file_path, simplifyVector = FALSE)
        }, error = function(e) {
          invalid_files <- c(invalid_files, basename(file_path))
          NULL
        })

        if (!is.null(data) && "languages" %in% names(data) && "translation" %in% names(data)) {
          valid_count <- valid_count + 1
        } else if (!is.null(data)) {
          invalid_files <- c(invalid_files, basename(file_path))
        }
      }

      if (length(invalid_files) > 0) {
        print_check("Translation file structure", "WARN",
                   sprintf("%d files with invalid structure: %s",
                          length(invalid_files),
                          paste(head(invalid_files, 3), collapse = ", ")))
      } else {
        print_check("Translation file structure", "PASS")
      }

      # Check for reverse key mapping (DEPRECATED - now optional)
      if (file.exists("scripts/reverse_key_mapping.json")) {
        mapping_data <- tryCatch({
          fromJSON("scripts/reverse_key_mapping.json", simplifyVector = TRUE)
        }, error = function(e) {
          NULL
        })

        if (!is.null(mapping_data) && length(mapping_data) > 0) {
          print_check("Reverse key mapping (deprecated)", "PASS")
          cat(sprintf("   Found %d key mappings (file is deprecated but still present)\n", length(mapping_data)))
        } else {
          print_check("Reverse key mapping (deprecated)", "WARN", "File exists but appears empty or invalid")
        }
      } else {
        print_check("Reverse key mapping (deprecated)", "PASS")
        cat("   File not present (deprecated feature removed)\n")
      }

    } else {
      print_check("Modular translation files", "ERROR", "No modular translation files found")
    }
  }, error = function(e) {
    print_check("Translation validation", "ERROR", e$message)
  })
} else {
  print_check("Translation system", "ERROR", "Required translation subdirectories missing")
}

# ============================================================================
# Check 4: R package dependencies
# ============================================================================
cat("\n[4] Checking R Package Dependencies...\n")

required_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "shinyjs", "shinyBS",
  "shiny.i18n", "tidyverse", "dplyr", "tidyr", "readr", "purrr",
  "tibble", "stringr", "forcats", "lubridate", "DT", "openxlsx",
  "jsonlite", "digest", "igraph", "visNetwork", "ggraph", "tidygraph",
  "ggplot2", "plotly", "dygraphs", "xts", "timevis", "rmarkdown", "htmlwidgets"
)

missing_packages <- c()
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    # Package available - don't print individual successes to reduce noise
  } else {
    print_check(paste("Package:", pkg), "ERROR", "Not installed")
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) == 0) {
  print_check("All required packages", "PASS")
  cat(sprintf("   Checked %d packages\n", length(required_packages)))
} else {
  cat(sprintf("\n   Missing packages: %s\n", paste(missing_packages, collapse = ", ")))
  cat("   Run: Rscript deployment/install_dependencies.R\n")
}

# ============================================================================
# Check 5: Validate app.R syntax
# ============================================================================
cat("\n[5] Checking R Syntax...\n")

r_files <- c("app.R", "global.R", "run_app.R", "constants.R", "io.R", "utils.R", "version_manager.R")

for (file in r_files) {
  if (file.exists(file)) {
    result <- tryCatch({
      parse(file)
      TRUE
    }, error = function(e) {
      print_check(paste("Syntax:", file), "ERROR", e$message)
      FALSE
    })
    if (result) {
      print_check(paste("Syntax:", file), "PASS")
    }
  }
}

# ============================================================================
# Check 6: Check for common issues
# ============================================================================
cat("\n[6] Checking for Common Issues...\n")

# Check for large files in www/
if (dir.exists("www")) {
  www_files <- list.files("www", recursive = TRUE, full.names = TRUE)
  large_files <- www_files[file.size(www_files) > 10*1024*1024]  # > 10MB
  if (length(large_files) > 0) {
    print_check("Large files in www/", "WARN", 
               sprintf("%d files > 10MB found", length(large_files)))
    cat("   Consider optimizing or moving large files\n")
  } else {
    print_check("www/ directory size", "PASS")
  }
}

# Check for temporary files
temp_patterns <- c("*~", "*.tmp", "*.log", ".Rhistory", ".RData")
temp_found <- FALSE
for (pattern in temp_patterns) {
  temp_files <- list.files(pattern = glob2rx(pattern), recursive = FALSE)
  if (length(temp_files) > 0) {
    if (!temp_found) {
      print_check("Temporary files", "WARN", "Found temporary files in root")
      temp_found <- TRUE
    }
  }
}
if (!temp_found) {
  print_check("Temporary files", "PASS")
}

# ============================================================================
# Summary
# ============================================================================
cat("\n================================================================================\n")
cat("Pre-Deployment Check Summary\n")
cat("================================================================================\n\n")

total_checks <- checks_passed + warnings + errors

cat(sprintf("Total Checks: %d\n", total_checks))
cat(sprintf("✓ Passed: %d\n", checks_passed))
if (warnings > 0) {
  cat(sprintf("⚠ Warnings: %d\n", warnings))
}
if (errors > 0) {
  cat(sprintf("✗ Errors: %d\n", errors))
}

cat("\n")

if (errors > 0) {
  cat("❌ DEPLOYMENT NOT RECOMMENDED\n")
  cat("   Please fix the errors above before deploying.\n\n")
  quit(status = 1)
} else if (warnings > 0) {
  cat("⚠️  DEPLOYMENT POSSIBLE WITH WARNINGS\n")
  cat("   Review warnings before deploying to production.\n\n")
  quit(status = 0)
} else {
  cat("✅ ALL CHECKS PASSED\n")
  cat("   Application is ready for deployment!\n\n")
  quit(status = 0)
}
