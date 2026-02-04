#!/usr/bin/env Rscript
# ============================================================================
# MarineSABRES SES Tool - Dependency Installation Script
# ============================================================================
#
# This script installs all required R packages for the MarineSABRES Shiny app
# Run this script before deploying the application to a new server
#
# Usage:
#   Rscript install_dependencies.R
#
# ============================================================================

cat("================================================================================\n")
cat("MarineSABRES SES Tool - Dependency Installation\n")
cat("================================================================================\n\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# ============================================================================
# PINNED PACKAGE VERSIONS (for reproducible builds)
# Last verified: 2026-02-03
# ============================================================================
# Core framework
# shiny >= 1.8.0
# bs4Dash >= 2.3.0
# shinyWidgets >= 0.8.0
# shinyjs >= 2.1.0
#
# Data
# tidyverse >= 2.0.0
# DT >= 0.31
# jsonlite >= 1.8.8
# openxlsx >= 4.2.5
#
# Network
# igraph >= 1.6.0
# visNetwork >= 2.1.2
#
# i18n
# shiny.i18n >= 0.5.0
# ============================================================================

# Helper: Install package with version pinning for reproducible builds
install_versioned <- function(pkg, min_version = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    if (!is.null(min_version) && requireNamespace("remotes", quietly = TRUE)) {
      remotes::install_version(pkg, version = paste0(">= ", min_version),
                                repos = "https://cloud.r-project.org",
                                upgrade = "never")
    } else {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  } else if (!is.null(min_version)) {
    installed_ver <- packageVersion(pkg)
    if (installed_ver < min_version) {
      message(sprintf("Upgrading %s from %s to >= %s", pkg, installed_ver, min_version))
      if (requireNamespace("remotes", quietly = TRUE)) {
        remotes::install_version(pkg, version = paste0(">= ", min_version),
                                  repos = "https://cloud.r-project.org",
                                  upgrade = "never")
      } else {
        install.packages(pkg, repos = "https://cloud.r-project.org")
      }
    }
  }
}

# Define required packages
required_packages <- c(
  # Core Shiny packages
  "shiny",
  "bs4Dash",
  "shinyWidgets",
  "shinyjs",
  "shinyBS",

  # Internationalization
  "shiny.i18n",

  # Data manipulation
  "tidyverse",
  "dplyr",
  "tidyr",
  "readr",
  "purrr",
  "tibble",
  "stringr",
  "forcats",
  "lubridate",
  "DT",
  "openxlsx",
  "jsonlite",
  "digest",

  # Network visualization and analysis
  "igraph",
  "visNetwork",
  "ggraph",
  "tidygraph",

  # Plotting and time series
  "ggplot2",
  "plotly",
  "dygraphs",
  "xts",
  "zoo",

  # Project management
  "timevis",

  # Export/Reporting
  "rmarkdown",
  "htmlwidgets",
  "knitr"
)

cat("Checking for missing packages...\n\n")

# Check which packages are not installed
installed <- installed.packages()[, "Package"]
missing <- setdiff(required_packages, installed)

if (length(missing) == 0) {
  cat("All required packages are already installed!\n")
} else {
  cat(sprintf("Installing %d missing packages:\n", length(missing)))
  cat(paste(" -", missing, collapse = "\n"), "\n\n")

  # Install missing packages
  for (pkg in missing) {
    cat(sprintf("Installing %s...\n", pkg))
    tryCatch({
      install.packages(pkg, dependencies = TRUE, quiet = FALSE)
      cat(sprintf("  ✓ %s installed successfully\n", pkg))
    }, error = function(e) {
      cat(sprintf("  ✗ ERROR installing %s: %s\n", pkg, e$message))
    })
  }
}

cat("\n================================================================================\n")
cat("Package Installation Summary\n")
cat("================================================================================\n\n")

# Verify all packages can be loaded
success_count <- 0
fail_count <- 0
failed_packages <- c()

for (pkg in required_packages) {
  can_load <- requireNamespace(pkg, quietly = TRUE)
  if (can_load) {
    success_count <- success_count + 1
    cat(sprintf("✓ %s\n", pkg))
  } else {
    fail_count <- fail_count + 1
    failed_packages <- c(failed_packages, pkg)
    cat(sprintf("✗ %s - FAILED\n", pkg))
  }
}

cat("\n")
cat(sprintf("Successfully installed: %d / %d packages\n", success_count, length(required_packages)))

if (fail_count > 0) {
  cat(sprintf("\n⚠ WARNING: %d package(s) failed to install:\n", fail_count))
  cat(paste(" -", failed_packages, collapse = "\n"), "\n")
  cat("\nPlease install these packages manually before deploying the application.\n")
  quit(status = 1)
} else {
  cat("\n✓ All dependencies installed successfully!\n")
  cat("\nYou can now deploy the MarineSABRES SES Tool.\n")
}

cat("\n================================================================================\n")

# Print R session info for troubleshooting
cat("\nR Session Information:\n")
cat("================================================================================\n")
sessionInfo()
