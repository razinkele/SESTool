#!/usr/bin/env Rscript
# version_manager.R
# Automated version management script for MarineSABRES SES Shiny Application
#
# Usage:
#   Rscript version_manager.R                                 # Show current version
#   Rscript version_manager.R bump patch "Bug fixes"          # Bump patch version
#   Rscript version_manager.R bump minor "New features"       # Bump minor version
#   Rscript version_manager.R bump major "Breaking changes"   # Bump major version
#   Rscript version_manager.R set 2.0.0 "Release name" major  # Set specific version

suppressPackageStartupMessages({
  library(jsonlite)
})

# ============================================================================
# VERSION MANAGEMENT FUNCTIONS
# ============================================================================

# Read current version from VERSION file
get_version <- function() {
  if (!file.exists("VERSION")) {
    stop("VERSION file not found. Run from project root directory.")
  }
  version <- trimws(readLines("VERSION", warn = FALSE)[1])
  if (is.na(version) || version == "") {
    stop("VERSION file is empty")
  }
  version
}

# Parse semantic version into components
parse_version <- function(version_string) {
  # Remove any pre-release or build metadata
  clean_version <- sub("[-+].*$", "", version_string)

  # Split into parts
  parts <- as.integer(strsplit(clean_version, "\\.")[[1]])

  if (length(parts) != 3) {
    stop("Invalid version format. Expected MAJOR.MINOR.PATCH")
  }

  list(
    major = parts[1],
    minor = parts[2],
    patch = parts[3]
  )
}

# Increment version based on type
increment_version <- function(type = c("major", "minor", "patch")) {
  type <- match.arg(type)
  current <- get_version()
  parts <- parse_version(current)

  if (type == "major") {
    parts$major <- parts$major + 1
    parts$minor <- 0
    parts$patch <- 0
  } else if (type == "minor") {
    parts$minor <- parts$minor + 1
    parts$patch <- 0
  } else if (type == "patch") {
    parts$patch <- parts$patch + 1
  }

  paste(parts$major, parts$minor, parts$patch, sep = ".")
}

# Update version files
update_version <- function(new_version, version_name = NULL, release_type = "patch", status = "stable") {
  # Validate version format
  tryCatch({
    parse_version(new_version)
  }, error = function(e) {
    stop("Invalid version format: ", new_version)
  })

  # Update VERSION file
  writeLines(new_version, "VERSION")
  cat("✓ Updated VERSION to", new_version, "\n")

  # Update VERSION_INFO.json if it exists
  if (file.exists("VERSION_INFO.json")) {
    info <- fromJSON("VERSION_INFO.json")
    info$version <- new_version

    if (!is.null(version_name)) {
      info$version_name <- version_name
    }

    info$release_date <- as.character(Sys.Date())
    info$release_type <- release_type
    info$status <- status
    info$build_info$build_date <- as.character(as.POSIXct(Sys.time()))

    write_json(info, "VERSION_INFO.json", pretty = TRUE, auto_unbox = TRUE)
    cat("✓ Updated VERSION_INFO.json\n")
  }

  # Update global.R if it contains hardcoded version
  if (file.exists("global.R")) {
    global_content <- readLines("global.R", warn = FALSE)

    # Look for version references
    version_pattern <- 'log_message\\(paste\\("Application version:".*?\\)\\)'
    for (i in seq_along(global_content)) {
      if (grepl(version_pattern, global_content[i])) {
        cat("⚠ Found hardcoded version in global.R at line", i, "\n")
        cat("  Consider updating to read from VERSION file\n")
      }
    }
  }

  cat("\n")
  cat("Next steps:\n")
  cat("1. Review changes: git diff VERSION VERSION_INFO.json\n")
  cat("2. Update CHANGELOG.md with release notes\n")
  cat("3. Commit changes: git add VERSION VERSION_INFO.json CHANGELOG.md\n")
  cat("4. Create tag: git tag -a v", new_version, " -m 'Release version ", new_version, "'\n", sep = "")
  cat("5. Push: git push origin main --tags\n")
}

# Show current version info
show_version_info <- function() {
  version <- get_version()
  cat("Current Version:", version, "\n\n")

  if (file.exists("VERSION_INFO.json")) {
    info <- fromJSON("VERSION_INFO.json")
    cat("Version Name:", info$version_name, "\n")
    cat("Release Date:", info$release_date, "\n")
    cat("Release Type:", info$release_type, "\n")
    cat("Status:", info$status, "\n")
    cat("Minimum R Version:", info$minimum_r_version, "\n")

    if (!is.null(info$features) && length(info$features) > 0) {
      cat("\nKey Features:\n")
      for (feat in info$features) {
        cat("  -", feat, "\n")
      }
    }
  }
}

# Validate that we're in the correct directory
validate_directory <- function() {
  required_files <- c("app.R", "global.R", "VERSION")

  for (file in required_files) {
    if (!file.exists(file)) {
      stop("Required file '", file, "' not found. Please run from project root directory.")
    }
  }
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

main <- function() {
  # Validate we're in project root
  tryCatch({
    validate_directory()
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    quit(status = 1)
  })

  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    # No arguments: show current version
    show_version_info()

  } else if (args[1] == "bump") {
    # Bump version
    type <- ifelse(length(args) > 1, args[2], "patch")

    if (!type %in% c("major", "minor", "patch")) {
      cat("ERROR: Invalid bump type. Use 'major', 'minor', or 'patch'\n")
      quit(status = 1)
    }

    version_name <- ifelse(length(args) > 2, paste(args[-(1:2)], collapse = " "), paste(type, "update"))

    cat("Incrementing", toupper(type), "version...\n")
    new_version <- increment_version(type)
    cat("New version will be:", new_version, "\n\n")

    # Ask for confirmation in interactive mode
    if (interactive()) {
      response <- readline("Continue? (y/n): ")
      if (tolower(response) != "y") {
        cat("Aborted.\n")
        quit(status = 0)
      }
    }

    update_version(new_version, version_name, type)

  } else if (args[1] == "set") {
    # Set specific version
    if (length(args) < 2) {
      cat("ERROR: Version number required\n")
      cat("Usage: Rscript version_manager.R set <version> [name] [type]\n")
      quit(status = 1)
    }

    new_version <- args[2]
    version_name <- ifelse(length(args) > 2, args[3], "Manual version update")
    release_type <- ifelse(length(args) > 3, args[4], "patch")

    cat("Setting version to:", new_version, "\n\n")

    # Ask for confirmation in interactive mode
    if (interactive()) {
      response <- readline("Continue? (y/n): ")
      if (tolower(response) != "y") {
        cat("Aborted.\n")
        quit(status = 0)
      }
    }

    update_version(new_version, version_name, release_type)

  } else if (args[1] == "dev") {
    # Set development version
    current <- get_version()
    parts <- parse_version(current)
    dev_version <- paste0(parts$major, ".", parts$minor + 1, ".0-dev")

    cat("Setting development version to:", dev_version, "\n\n")
    update_version(dev_version, "Development version", "minor", "development")

  } else if (args[1] == "stable") {
    # Set stable version (remove -dev suffix)
    current <- get_version()
    stable_version <- sub("-dev.*$", "", current)

    if (stable_version == current) {
      cat("Already a stable version:", current, "\n")
      quit(status = 0)
    }

    cat("Setting stable version to:", stable_version, "\n\n")
    update_version(stable_version, "Stable release", "minor", "stable")

  } else if (args[1] == "help" || args[1] == "--help" || args[1] == "-h") {
    # Show help
    cat("MarineSABRES Version Manager\n\n")
    cat("Usage:\n")
    cat("  Rscript version_manager.R                                 # Show current version\n")
    cat("  Rscript version_manager.R bump patch ['description']      # Bump patch version (1.0.0 -> 1.0.1)\n")
    cat("  Rscript version_manager.R bump minor ['description']      # Bump minor version (1.0.0 -> 1.1.0)\n")
    cat("  Rscript version_manager.R bump major ['description']      # Bump major version (1.0.0 -> 2.0.0)\n")
    cat("  Rscript version_manager.R set <version> [name] [type]     # Set specific version\n")
    cat("  Rscript version_manager.R dev                              # Set development version (1.1.0 -> 1.2.0-dev)\n")
    cat("  Rscript version_manager.R stable                           # Set stable version (1.2.0-dev -> 1.2.0)\n")
    cat("  Rscript version_manager.R help                             # Show this help\n")
    cat("\n")
    cat("Examples:\n")
    cat("  Rscript version_manager.R bump patch 'Fix critical bug'\n")
    cat("  Rscript version_manager.R bump minor 'Add new template'\n")
    cat("  Rscript version_manager.R set 2.0.0 'Major release' major\n")

  } else {
    cat("ERROR: Unknown command:", args[1], "\n")
    cat("Run 'Rscript version_manager.R help' for usage information\n")
    quit(status = 1)
  }
}

# Run main function
main()
