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

# Define required packages
required_packages <- c(
  # Core Shiny packages
  "shiny",
  "shinydashboard",
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
