#!/usr/bin/env Rscript
# ============================================================================
# MarineSABRES Remote Pre-Deployment Validation Script
# ============================================================================
#
# This script performs comprehensive pre-deployment checks before remote
# deployment to laguna.ku.lt
#
# Usage:
#   Rscript pre-deploy-check-remote.R
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical errors found
#   2 - Warnings found (deployment can continue)
#
# Version: 1.0
# Created: 2026-01-12
#
# ============================================================================

# Initialize counters
errors <- 0
warnings <- 0
checks_passed <- 0

# Store warning details for verbose output
warning_details <- list()

# Helper functions
print_header <- function(msg) {
  cat("\n")
  cat("================================================================================\n")
  cat(" ", msg, "\n")
  cat("================================================================================\n")
  cat("\n")
}

print_check <- function(name, status, message = "", details = NULL) {
  if (status == "PASS") {
    cat("[OK] ", name, "\n", sep = "")
    checks_passed <<- checks_passed + 1
  } else if (status == "WARN") {
    cat("[WARN] ", name, ": ", message, "\n", sep = "")
    warnings <<- warnings + 1
    # Store details for verbose output
    if (!is.null(details)) {
      warning_details[[length(warning_details) + 1]] <<- list(
        name = name,
        message = message,
        details = details
      )
    }
  } else {
    cat("[ERROR] ", name, ": ", message, "\n", sep = "")
    errors <<- errors + 1
  }
}

print_status <- function(msg) {
  cat("==> ", msg, "\n", sep = "")
}

# Start validation
print_header("MarineSABRES Remote Pre-Deployment Validation")

# ============================================================================
# 1. Core Application Files
# ============================================================================

print_status("Checking core application files...")

# Required core files
required_files <- c("app.R", "global.R", "VERSION", "VERSION_INFO.json", "constants.R", "io.R", "utils.R")

for (file in required_files) {
  if (file.exists(file)) {
    print_check(paste("Core file:", file), "PASS")
  } else {
    print_check(paste("Core file:", file), "ERROR", "File missing")
  }
}

# Check VERSION file content
if (file.exists("VERSION")) {
  version_content <- readLines("VERSION", n = 1, warn = FALSE)
  if (nchar(version_content) > 0 && grepl("^[0-9]+\\.[0-9]+", version_content)) {
    print_check("VERSION file format", "PASS")
  } else {
    print_check("VERSION file format", "WARN", "Invalid version format")
  }
}

# ============================================================================
# 2. Required Directories
# ============================================================================

print_status("Checking required directories...")

required_dirs <- c("modules", "functions", "server", "www", "data", "translations")
optional_dirs <- c("scripts", "SESModels", "docs", "config")

for (dir in required_dirs) {
  if (dir.exists(dir)) {
    file_count <- length(list.files(dir, recursive = TRUE))
    print_check(paste("Required directory:", dir), "PASS", paste("(", file_count, "files)", sep = ""))
  } else {
    print_check(paste("Required directory:", dir), "ERROR", "Directory missing")
  }
}

for (dir in optional_dirs) {
  if (dir.exists(dir)) {
    file_count <- length(list.files(dir, recursive = TRUE))
    print_check(paste("Optional directory:", dir), "PASS", paste("(", file_count, "files)", sep = ""))
  } else {
    print_check(paste("Optional directory:", dir), "WARN", "Directory missing (optional)")
  }
}

# ============================================================================
# 3. SESModels Validation
# ============================================================================

print_status("Validating SESModels directory...")

if (dir.exists("SESModels")) {
  # Count Excel files
  excel_files <- list.files("SESModels", pattern = "\\.(xlsx|xls)$", recursive = TRUE, full.names = TRUE)

  if (length(excel_files) > 0) {
    print_check("SESModels Excel files", "PASS", paste(length(excel_files), "files found"))

    # Check for DA directories
    da_dirs <- list.dirs("SESModels", recursive = FALSE, full.names = FALSE)
    da_dirs <- da_dirs[da_dirs != "SESModels" & da_dirs != ""]
    da_dirs <- da_dirs[grepl("DA", da_dirs, ignore.case = TRUE)]

    if (length(da_dirs) > 0) {
      print_check("DA directories", "PASS", paste(length(da_dirs), "directories:", paste(da_dirs, collapse = ", ")))
    } else {
      print_check("DA directories", "WARN", "No DA directories found")
    }

    # Check file sizes
    large_files <- excel_files[file.size(excel_files) > 10 * 1024 * 1024]  # > 10MB
    if (length(large_files) > 0) {
      print_check("Large Excel files", "WARN", paste(length(large_files), "files > 10MB"))
    } else {
      print_check("Excel file sizes", "PASS")
    }

  } else {
    print_check("SESModels content", "WARN", "No Excel files found")
  }
} else {
  print_check("SESModels directory", "WARN", "Directory missing - will be excluded from deployment")
}

# ============================================================================
# 4. Translation System
# ============================================================================

print_status("Validating translation system...")

# Check modular translation structure
if (dir.exists("translations")) {
  # Check for modular subdirectories
  modular_dirs <- c("common", "modules", "ui", "data")
  modular_present <- sapply(modular_dirs, function(d) dir.exists(file.path("translations", d)))

  if (all(modular_present)) {
    print_check("Modular translation structure", "PASS")

    # Count translation files
    json_files <- list.files("translations", pattern = "\\.json$", recursive = TRUE)
    print_check("Translation files", "PASS", paste(length(json_files), "files"))

    # Check for valid JSON
    invalid_json <- c()
    for (json_file in file.path("translations", json_files)) {
      tryCatch({
        jsonlite::fromJSON(json_file)
      }, error = function(e) {
        invalid_json <<- c(invalid_json, json_file)
      })
    }

    if (length(invalid_json) == 0) {
      print_check("Translation JSON validity", "PASS")
    } else {
      print_check("Translation JSON validity", "ERROR", paste("Invalid:", paste(basename(invalid_json), collapse = ", ")))
    }

  } else {
    missing_dirs <- modular_dirs[!modular_present]
    print_check("Modular translation structure", "WARN", paste("Missing:", paste(missing_dirs, collapse = ", ")))
  }
}

# ============================================================================
# 5. R Package Dependencies
# ============================================================================

print_status("Checking R package dependencies (not installing, only checking)...")

# Core dependencies for remote deployment - these MUST be available
core_packages <- c("shiny", "bs4Dash", "shinyWidgets", "shinyjs", "DT", "jsonlite", "dplyr", "visNetwork")

# Additional packages used by the application
additional_packages <- c(
  "igraph", "readxl", "writexl", "shinyFeedback", "waiter",
  "shinycssloaders", "shinyalert", "rmarkdown", "knitr",
  "htmltools", "htmlwidgets", "magrittr", "tidyr", "purrr",
  "stringr", "lubridate", "ggplot2", "plotly", "scales"
)

# Optional packages (nice to have but not critical)
optional_packages <- c("torch", "coro", "promises", "future")

cat("\n")
cat("  Checking CORE packages (required):\n")
missing_core <- c()
for (pkg in core_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("    [OK] ", pkg, "\n", sep = "")
  } else {
    cat("    [MISSING] ", pkg, "\n", sep = "")
    missing_core <- c(missing_core, pkg)
  }
}

cat("\n")
cat("  Checking ADDITIONAL packages:\n")
missing_additional <- c()
for (pkg in additional_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("    [OK] ", pkg, "\n", sep = "")
  } else {
    cat("    [MISSING] ", pkg, "\n", sep = "")
    missing_additional <- c(missing_additional, pkg)
  }
}

cat("\n")
cat("  Checking OPTIONAL packages (ML features):\n")
missing_optional <- c()
for (pkg in optional_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("    [OK] ", pkg, "\n", sep = "")
  } else {
    cat("    [SKIP] ", pkg, " (optional)\n", sep = "")
    missing_optional <- c(missing_optional, pkg)
  }
}
cat("\n")

# Report results
if (length(missing_core) > 0) {
  print_check("Core R packages", "ERROR",
              paste(length(missing_core), "CRITICAL packages missing"),
              details = list(
                missing = missing_core,
                install_cmd = paste0("install.packages(c('", paste(missing_core, collapse = "', '"), "'))")
              ))
} else {
  print_check("Core R packages", "PASS", paste("All", length(core_packages), "core packages available"))
}

if (length(missing_additional) > 0) {
  print_check("Additional R packages", "WARN",
              paste(length(missing_additional), "packages missing - some features may not work"),
              details = list(
                missing = missing_additional,
                install_cmd = paste0("install.packages(c('", paste(missing_additional, collapse = "', '"), "'))")
              ))
} else {
  print_check("Additional R packages", "PASS", paste("All", length(additional_packages), "additional packages available"))
}

if (length(missing_optional) > 0) {
  # Optional packages are just informational, not a warning
  cat("  Note: ", length(missing_optional), " optional packages not installed (ML features disabled)\n", sep = "")
}

# ============================================================================
# 6. R Syntax Validation
# ============================================================================

print_status("Validating R syntax...")

r_files <- c(
  list.files(pattern = "\\.(R|r)$", full.names = TRUE),
  list.files("modules", pattern = "\\.(R|r)$", recursive = TRUE, full.names = TRUE),
  list.files("functions", pattern = "\\.(R|r)$", recursive = TRUE, full.names = TRUE),
  list.files("server", pattern = "\\.(R|r)$", recursive = TRUE, full.names = TRUE)
)

syntax_errors <- c()
for (r_file in r_files) {
  tryCatch({
    parse(r_file)
  }, error = function(e) {
    syntax_errors <<- c(syntax_errors, r_file)
  })
}

if (length(syntax_errors) == 0) {
  print_check("R syntax validation", "PASS", paste(length(r_files), "files checked"))
} else {
  print_check("R syntax validation", "ERROR", paste("Syntax errors in:", paste(basename(syntax_errors), collapse = ", ")))
}

# ============================================================================
# 7. File Size and Content Validation
# ============================================================================

print_status("Checking file sizes and content...")

# Check for large files that might cause deployment issues
large_files <- c()
all_files <- list.files(".", recursive = TRUE, full.names = TRUE)
for (file in all_files) {
  if (file.info(file)$size > 50 * 1024 * 1024) {  # > 50MB
    large_files <- c(large_files, file)
  }
}

if (length(large_files) == 0) {
  print_check("Large files check", "PASS")
} else {
  print_check("Large files check", "WARN", paste("Files > 50MB:", length(large_files)))
}

# Check for temporary files that shouldn't be deployed
temp_patterns <- c("\\.tmp$", "\\.log$", "~$", "\\.swp$", "\\.DS_Store$")
temp_files <- c()
for (pattern in temp_patterns) {
  temp_files <- c(temp_files, list.files(".", pattern = pattern, recursive = TRUE))
}

if (length(temp_files) == 0) {
  print_check("Temporary files", "PASS")
} else {
  print_check("Temporary files", "WARN",
              paste(length(temp_files), "files found (will be excluded by rsync)"),
              details = list(files = temp_files))
}

# ============================================================================
# 8. Remote Deployment Readiness
# ============================================================================

print_status("Checking remote deployment readiness...")

# Check if rsync is available (in PATH)
rsync_available <- Sys.which("rsync") != ""
if (rsync_available) {
  print_check("rsync availability", "PASS")
} else {
  print_check("rsync availability", "WARN", "rsync not in PATH - may need WSL/Git Bash")
}

# Check if SSH is available
ssh_available <- Sys.which("ssh") != ""
if (ssh_available) {
  print_check("SSH availability", "PASS")
} else {
  print_check("SSH availability", "WARN", "SSH not in PATH - may need WSL/Git Bash")
}

# Check git status for untracked important files
if (dir.exists(".git")) {
  git_status_cmd <- "git status --porcelain"
  tryCatch({
    git_output <- system(git_status_cmd, intern = TRUE, show.output.on.console = FALSE)
    untracked_important <- grep("^\\?\\?.*\\.(R|json)$", git_output, value = TRUE)

    if (length(untracked_important) == 0) {
      print_check("Git tracked files", "PASS")
    } else {
      print_check("Git tracked files", "WARN", paste(length(untracked_important), "untracked R/JSON files"))
    }
  }, error = function(e) {
    print_check("Git status", "WARN", "Could not check git status")
  })
}

# ============================================================================
# Summary and Exit
# ============================================================================

print_header("Validation Summary")

cat("Checks performed: ", checks_passed + warnings + errors, "\n", sep = "")
cat("[OK] Passed: ", checks_passed, "\n", sep = "")
cat("[WARN] Warnings: ", warnings, "\n", sep = "")
cat("[ERROR] Errors: ", errors, "\n", sep = "")

# Show verbose warning details
if (length(warning_details) > 0) {
  cat("\n")
  cat("================================================================================\n")
  cat(" WARNING DETAILS\n")
  cat("================================================================================\n")
  for (i in seq_along(warning_details)) {
    w <- warning_details[[i]]
    cat("\n")
    cat("[", i, "] ", w$name, "\n", sep = "")
    cat("    Issue: ", w$message, "\n", sep = "")
    if (!is.null(w$details$missing)) {
      cat("    Missing items:\n")
      for (item in w$details$missing) {
        cat("      - ", item, "\n", sep = "")
      }
    }
    if (!is.null(w$details$install_cmd)) {
      cat("    To fix, run:\n")
      cat("      ", w$details$install_cmd, "\n", sep = "")
    }
    if (!is.null(w$details$files)) {
      cat("    Files:\n")
      for (f in head(w$details$files, 10)) {
        cat("      - ", f, "\n", sep = "")
      }
      if (length(w$details$files) > 10) {
        cat("      ... and ", length(w$details$files) - 10, " more\n", sep = "")
      }
    }
  }
}

cat("\n")

if (errors > 0) {
  cat("================================================================================\n")
  cat(" CRITICAL ERRORS FOUND - Fix these issues before deployment\n")
  cat("================================================================================\n")
  cat("\n")
  quit(status = 1)
} else if (warnings > 0) {
  cat("================================================================================\n")
  cat(" WARNINGS FOUND - Review above, deployment can continue\n")
  cat("================================================================================\n")
  cat("\n")
  cat("Recommendations:\n")
  cat("  1. Review all warnings above and fix if possible\n")
  cat("  2. Use --exclude-models if SESModels issues persist\n")
  cat("  3. Ensure SSH access to laguna.ku.lt is configured\n")
  cat("  4. Run deployment with --dry-run first\n")
  cat("\n")
  quit(status = 2)
} else {
  cat("================================================================================\n")
  cat(" ALL CHECKS PASSED - Ready for remote deployment\n")
  cat("================================================================================\n")
  cat("\n")
  cat("Next steps:\n")
  cat("  1. Run: ./remote-deploy.sh --dry-run\n")
  cat("  2. If dry run looks good: ./remote-deploy.sh\n")
  cat("  3. Test application at: http://laguna.ku.lt:3838/marinesabres/\n")
  cat("\n")
  quit(status = 0)
}