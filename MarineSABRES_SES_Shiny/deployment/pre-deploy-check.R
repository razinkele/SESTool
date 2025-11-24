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
  "translations/translation.json"
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
# Check 3: Validate translation.json
# ============================================================================
cat("\n[3] Validating Translation File...\n")

if (file.exists("translations/translation.json")) {
  tryCatch({
    library(jsonlite)
    trans_data <- fromJSON("translations/translation.json", simplifyVector = FALSE)
    
    # Check if it has the expected structure
    if (is.list(trans_data) && "translation" %in% names(trans_data)) {
      translations <- trans_data$translation
      print_check("Translation JSON structure", "PASS")
      cat(sprintf("   Found %d translation entries\n", length(translations)))
      
      # Check for duplicates
      en_texts <- sapply(translations, function(x) x$en)
      if (any(duplicated(en_texts))) {
        dup_count <- sum(duplicated(en_texts))
        print_check("Translation duplicates", "WARN", 
                   sprintf("%d duplicate entries found", dup_count))
      } else {
        print_check("Translation duplicates", "PASS")
      }
      
      # Check for required languages
      if ("languages" %in% names(trans_data)) {
        required_langs <- c("en", "es", "fr", "de", "lt", "pt", "it")
        available_langs <- unlist(trans_data$languages)
        missing_langs <- setdiff(required_langs, available_langs)
        if (length(missing_langs) > 0) {
          print_check("Translation languages", "WARN", 
                     paste("Missing languages:", paste(missing_langs, collapse = ", ")))
        } else {
          print_check("Translation languages", "PASS")
        }
      } else {
        print_check("Translation languages", "WARN", "No 'languages' key in JSON")
      }
    } else {
      print_check("Translation JSON structure", "ERROR", "Invalid JSON structure")
    }
  }, error = function(e) {
    print_check("Translation JSON parsing", "ERROR", e$message)
  })
} else {
  print_check("Translation file", "ERROR", "File not found")
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
