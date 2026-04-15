#!/usr/bin/env Rscript
# ============================================================================
# MarineSABRES SES Tool - Required Package Registry
# ============================================================================
#
# Single source of truth for all R package dependencies.
# Auto-extracts library() calls from global.R so the list never drifts.
#
# Usage (from any deployment script):
#   source("deployment/required_packages.R")
#   # Now use: REQUIRED_PACKAGES, OPTIONAL_PACKAGES, ALL_PACKAGES
#
# ============================================================================

# Locate global.R relative to this file or PROJECT_ROOT
.find_global_r <- function() {
  candidates <- c(
    file.path(getwd(), "global.R"),
    file.path(getwd(), "..", "global.R"),
    if (exists("PROJECT_ROOT")) file.path(PROJECT_ROOT, "global.R") else NULL
  )
  for (f in candidates) {
    if (file.exists(f)) return(normalizePath(f))
  }
  NULL
}

# Parse library() calls from global.R to auto-detect required packages
.parse_global_r_packages <- function() {
  global_path <- .find_global_r()
  if (is.null(global_path)) return(character(0))

  lines <- readLines(global_path, warn = FALSE)
  # Match library(pkg) — ignore commented lines
  lib_lines <- grep("^\\s*library\\(", lines, value = TRUE)
  pkgs <- gsub(".*library\\(([^)]+)\\).*", "\\1", lib_lines)
  # Strip quotes if present
  pkgs <- gsub("[\"']", "", trimws(pkgs))
  unique(pkgs)
}

# Packages loaded via library() in global.R (auto-parsed)
.global_r_packages <- .parse_global_r_packages()

# Packages that appear in global.R but are loaded conditionally (not startup-blocking)
.conditional_packages <- c("torch")
.global_r_packages <- setdiff(.global_r_packages, .conditional_packages)

# Packages required at startup (everything in global.R plus implicit deps)
# These MUST be installed or the app will not start
REQUIRED_PACKAGES <- unique(c(
  .global_r_packages,
  # Implicit dependencies loaded inside modules or conditionally
  "dplyr", "tidyr", "readr", "purrr", "tibble",
  "stringr", "forcats", "lubridate", "magrittr",
  "zoo",             # required by xts
  "knitr",           # required by rmarkdown
  "htmltools",       # required by shiny/htmlwidgets
  "httpuv",          # HTTP backend for shiny (often missing after R upgrades)
  "later",           # async event loop for shiny
  "promises",        # async operations
  "waiter",          # loading screens
  "fresh",           # bs4Dash theming
  "sortable"         # drag-and-drop UI
))

# Optional packages — app starts without them, but some features are disabled
OPTIONAL_PACKAGES <- c(
  "torch",           # ML-assisted element classification
  "coro",            # async generators (torch dependency)
  "officer",         # Word/PowerPoint export
  "flextable",       # Rich tables in reports
  "tinytex"          # LaTeX for PDF export
)

# Combined list for convenience
ALL_PACKAGES <- unique(c(REQUIRED_PACKAGES, OPTIONAL_PACKAGES))

# Diagnostic: verify which packages are installed
check_packages <- function(packages = REQUIRED_PACKAGES, verbose = TRUE) {
  installed <- rownames(installed.packages())
  missing <- setdiff(packages, installed)

  if (verbose && length(missing) > 0) {
    cat(sprintf("Missing %d package(s):\n", length(missing)))
    cat(paste(" -", missing, collapse = "\n"), "\n")
    cat(sprintf("\nInstall with:\n  install.packages(c(%s))\n",
                paste0("'", missing, "'", collapse = ", ")))
  }

  list(
    installed = intersect(packages, installed),
    missing = missing,
    ok = length(missing) == 0
  )
}

if (!is.null(.global_r_packages) && length(.global_r_packages) > 0) {
  # Silently loaded
} else {
  message("WARNING: Could not parse global.R — using fallback package list")
}
