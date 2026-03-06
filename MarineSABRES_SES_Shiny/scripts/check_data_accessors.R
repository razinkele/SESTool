# scripts/check_data_accessors.R
# P2 #25: Data Accessor Enforcement Linter
#
# Scans R files for direct data access patterns that should use data accessors.
# Run with: Rscript scripts/check_data_accessors.R
#
# Data accessors (functions/data_accessors.R) provide a cleaner API for
# accessing deeply nested project_data() structures.

# ============================================================================
# CONFIGURATION
# ============================================================================

# Patterns that should use data accessors instead
PROBLEMATIC_PATTERNS <- list(
  # Direct ISA data access
  isa_data_direct = list(
    pattern = "\\$data\\$isa_data\\$",
    suggestion = "Use get_isa_data() or get_isa_elements()",
    severity = "warning"
  ),

  # Direct adjacency matrix access
  adjacency_direct = list(
    pattern = "\\$adjacency_matrices\\$",
    suggestion = "Use get_adjacency_matrix()",
    severity = "warning"
  ),

  # Direct CLD data access
  cld_direct = list(
    pattern = "\\$data\\$cld\\$",
    suggestion = "Use get_cld_data() or get_cld_nodes()/get_cld_edges()",
    severity = "warning"
  ),

  # Direct metadata access
  metadata_direct = list(
    pattern = "\\$metadata\\$",
    suggestion = "Use get_project_metadata() or specific accessor",
    severity = "info"
  ),

  # Double nested project_data access (often error-prone)
  double_nested = list(
    pattern = "project_data\\(\\)\\$data\\$",
    suggestion = "Use typed accessor functions for cleaner code",
    severity = "info"
  )
)

# Files/directories to exclude from checking
EXCLUDE_PATTERNS <- c(
  "data_accessors\\.R$",      # The accessors file itself
  "_archive/",                # Archived files
  "backup/",                  # Backup files
  "\\.Rmd$",                  # R Markdown (documentation)
  "test-.*\\.R$"              # Test files (may legitimately test internals)
)

# ============================================================================
# LINTING FUNCTIONS
# ============================================================================

#' Check a single file for direct data access patterns
#'
#' @param file_path Path to R file
#' @return List of violations found
check_file <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  violations <- list()

  for (i in seq_along(lines)) {
    line <- lines[i]

    # Skip comments
    if (grepl("^\\s*#", line)) next

    # Check each pattern
    for (pattern_name in names(PROBLEMATIC_PATTERNS)) {
      pattern_info <- PROBLEMATIC_PATTERNS[[pattern_name]]

      if (grepl(pattern_info$pattern, line, perl = TRUE)) {
        violations <- c(violations, list(
          list(
            file = file_path,
            line_number = i,
            line_content = trimws(line),
            pattern = pattern_name,
            suggestion = pattern_info$suggestion,
            severity = pattern_info$severity
          )
        ))
      }
    }
  }

  violations
}

#' Check all R files in directory
#'
#' @param dir Directory to scan
#' @return List of all violations
check_directory <- function(dir = ".") {
  # Find all R files
  r_files <- list.files(
    path = dir,
    pattern = "\\.R$",
    recursive = TRUE,
    full.names = TRUE
  )

  # Filter excluded patterns
  for (pattern in EXCLUDE_PATTERNS) {
    r_files <- r_files[!grepl(pattern, r_files)]
  }

  # Check each file
  all_violations <- list()

  for (file in r_files) {
    violations <- check_file(file)
    if (length(violations) > 0) {
      all_violations <- c(all_violations, violations)
    }
  }

  all_violations
}

#' Format violation for display
#'
#' @param v Violation list
#' @return Formatted string
format_violation <- function(v) {
  severity_icon <- switch(v$severity,
    "error"   = "\u2717",
    "warning" = "\u26A0",
    "info"    = "\u2139",
    "\u2022"
  )

  sprintf(
    "  %s %s:%d\n    Pattern: %s\n    Suggestion: %s\n    Code: %s\n",
    severity_icon,
    basename(v$file),
    v$line_number,
    v$pattern,
    v$suggestion,
    substr(v$line_content, 1, 60)
  )
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Set working directory to project root if needed
if (!file.exists("global.R")) {
  if (file.exists("../global.R")) {
    setwd("..")
  } else {
    stop("Must run from project root or scripts/ directory")
  }
}

cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("Data Accessor Enforcement Linter\n")
cat("=" |> rep(70) |> paste(collapse = ""), "\n\n")

# Run checks
violations <- check_directory()

if (length(violations) == 0) {
  cat("\u2713 No direct data access patterns found!\n")
  cat("  All code uses data accessor functions appropriately.\n\n")
} else {
  # Group by severity
  errors <- violations[sapply(violations, function(v) v$severity == "error")]
  warnings <- violations[sapply(violations, function(v) v$severity == "warning")]
  infos <- violations[sapply(violations, function(v) v$severity == "info")]

  cat(sprintf("Found %d potential issues:\n\n", length(violations)))

  if (length(errors) > 0) {
    cat(sprintf("ERRORS (%d):\n", length(errors)))
    for (v in errors) {
      cat(format_violation(v))
    }
    cat("\n")
  }

  if (length(warnings) > 0) {
    cat(sprintf("WARNINGS (%d):\n", length(warnings)))
    for (v in warnings) {
      cat(format_violation(v))
    }
    cat("\n")
  }

  if (length(infos) > 0) {
    cat(sprintf("INFO (%d):\n", length(infos)))
    for (v in infos) {
      cat(format_violation(v))
    }
    cat("\n")
  }

  # Summary
  cat("-" |> rep(70) |> paste(collapse = ""), "\n")
  cat("Summary:\n")
  cat(sprintf("  Errors:   %d\n", length(errors)))
  cat(sprintf("  Warnings: %d\n", length(warnings)))
  cat(sprintf("  Info:     %d\n", length(infos)))
  cat("\n")

  # Recommendations
  cat("Recommendations:\n")
  cat("  1. Replace direct access patterns with data accessor functions\n")
  cat("  2. Import accessors: source('functions/data_accessors.R')\n")
  cat("  3. Use get_isa_data(), get_cld_data(), etc. for cleaner code\n")
  cat("\n")

  # Exit with error if there are errors
  if (length(errors) > 0) {
    quit(status = 1)
  }
}

cat("=" |> rep(70) |> paste(collapse = ""), "\n")
cat("Linter complete.\n")
