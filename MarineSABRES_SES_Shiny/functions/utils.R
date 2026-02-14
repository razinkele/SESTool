# functions/utils.R
# General utility functions extracted from global.R
# These are helper functions used across multiple modules and server files.

# ============================================================================
# ID & FORMATTING UTILITIES
# ============================================================================

#' Generate a unique ID with prefix and timestamp
#'
#' @param prefix Character prefix for the ID (default: "ID")
#' @return Character string like "ID_20260214103045_1234"
generate_id <- function(prefix = "ID") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_",
         sample(1000:9999, 1))
}

#' Format a date for display
#'
#' @param date Date or character that can be coerced to Date
#' @return Character string formatted as "14 February 2026"
format_date_display <- function(date) {
  format(as.Date(date), "%d %B %Y")
}

#' Validate an email address
#'
#' @param email Character string to validate
#' @return Logical TRUE if valid email format
is_valid_email <- function(email) {
  grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)
}

# ============================================================================
# CONNECTION PARSING
# ============================================================================

#' Parse a connection value string into components
#'
#' Converts adjacency matrix value to list with polarity, strength, and confidence.
#' Format: "+strong:4" or "-medium:3" where :X is confidence (1-5).
#' If confidence is omitted, defaults to CONFIDENCE_DEFAULT (medium confidence).
#'
#' @param value Character string like "+strong:4" or "-medium"
#' @return List with polarity, strength, confidence; or NULL if empty/NA
parse_connection_value <- function(value) {
  if (is.na(value) || value == "") {
    return(NULL)
  }

  # Check if confidence is included (format: "+strong:4")
  if (grepl(":", value)) {
    parts <- strsplit(value, ":")[[1]]
    polarity_strength <- parts[1]
    confidence <- as.integer(parts[2])

    # Validate confidence is within allowed range
    if (is.na(confidence) || !confidence %in% CONFIDENCE_LEVELS) {
      confidence <- CONFIDENCE_DEFAULT  # Default if invalid
    }
  } else {
    # No confidence specified, use default
    polarity_strength <- value
    confidence <- CONFIDENCE_DEFAULT
  }

  polarity <- substr(polarity_strength, 1, 1)
  strength <- substr(polarity_strength, 2, nchar(polarity_strength))

  list(polarity = polarity, strength = strength, confidence = confidence)
}

# ============================================================================
# LOGGING
# ============================================================================

#' Log message to console (and optionally to file)
#'
#' @param message Character string to log
#' @param level Log level: "INFO", "WARN", "ERROR" (default: "INFO")
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s", timestamp, level, message)

  # Print to console
  message(log_entry)

  # Optionally write to log file
  # log_file <- "logs/app.log"
  # if (!dir.exists("logs")) dir.create("logs")
  # write(log_entry, file = log_file, append = TRUE)
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

#' Initialize session data structure
#'
#' Creates a fresh project data structure with metadata and empty data slots.
#' @return List with project_id, project_name, timestamps, user, version, and data
init_session_data <- function() {
  list(
    project_id = generate_id("PROJ"),
    project_name = "New Project",
    created_at = Sys.time(),
    last_modified = Sys.time(),
    user = Sys.info()["user"],
    version = APP_VERSION,
    data = list(
      metadata = list(),
      pims = list(),
      isa_data = list(),
      cld = list(),
      responses = list()
    )
  )
}

# ============================================================================
# SECURITY & VALIDATION
# ============================================================================

#' Sanitize color values to prevent XSS
#'
#' Validates that a color string is a safe hex color, RGB value, or known
#' application color. Returns a safe default (#cccccc) for invalid input.
#'
#' @param color Character string representing a color
#' @return Sanitized color string
sanitize_color <- function(color) {
  if (is.null(color) || !is.character(color) || length(color) != 1) {
    return("#cccccc")  # Safe default
  }

  # Whitelist of valid colors used in the application
  valid_colors <- c(
    "#776db3", "#5abc67", "#fec05a", "#bce2ee", "#313695", "#fff1a2",
    "#cccccc", "#d73027", "#f46d43", "#fdae61", "#fee08b", "#d9ef8b",
    "#a6d96a", "#66bd63", "#1a9850", "#3288bd", "#5e4fa2"
  )

  # Check if color is in whitelist
  if (color %in% valid_colors) {
    return(color)
  }

  # Validate hex color format (#RRGGBB)
  if (grepl("^#[0-9A-Fa-f]{6}$", color)) {
    return(color)
  }

  # Validate RGB format (rgb(r,g,b))
  if (grepl("^rgb\\([0-9]{1,3},\\s*[0-9]{1,3},\\s*[0-9]{1,3}\\)$", color)) {
    return(color)
  }

  # Return safe default if validation fails
  return("#cccccc")
}

#' Sanitize filename for safe file operations
#'
#' Removes or replaces characters that could cause issues in filenames across
#' different operating systems. Limits filename length to prevent path issues.
#' Preserves spaces, alphanumeric characters, underscores, and hyphens.
#'
#' @param name Character string to sanitize
#' @param max_length Maximum filename length (default: 50 characters)
#' @return Sanitized filename string
sanitize_filename <- function(name, max_length = 50) {
  if (is.null(name) || !is.character(name) || length(name) != 1) {
    return("project")
  }

  # Remove path separators and dangerous characters
  name <- gsub("[/\\\\:*?\"<>|]", "", name)

  # Keep only alphanumeric, underscore, hyphen, space
  name <- gsub("[^A-Za-z0-9_ -]", "", name)

  # Trim whitespace
  name <- trimws(name)

  # Truncate to reasonable length
  name <- substr(name, 1, max_length)

  # Ensure not empty
  if (nchar(name) == 0) {
    name <- "project"
  }

  return(name)
}

#' Validate ISA exercise data
#'
#' Generic validation for ISA data frames. Checks structure, required columns,
#' empty names, duplicate names, and missing IDs.
#'
#' @param data data.frame to validate
#' @param exercise_name Character name of the exercise (for error messages)
#' @param required_cols Character vector of required column names (default: c("ID", "Name"))
#' @return Character vector of error messages (empty if valid)
validate_isa_dataframe <- function(data, exercise_name, required_cols = c("ID", "Name")) {
  errors <- c()

  # Check if data is a data frame
  if (!is.data.frame(data)) {
    errors <- c(errors, paste(exercise_name, "data must be a data frame"))
    return(errors)
  }

  # Check if at least one entry exists
  if (nrow(data) == 0) {
    errors <- c(errors, paste(exercise_name, "must have at least one entry"))
    return(errors)
  }

  # Check required columns exist
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste(exercise_name, "missing required columns:",
                             paste(missing_cols, collapse = ", ")))
  }

  # Check for empty names
  if ("Name" %in% names(data)) {
    empty_names <- is.na(data$Name) | data$Name == "" | trimws(data$Name) == ""
    if (any(empty_names)) {
      errors <- c(errors, paste(exercise_name, "has", sum(empty_names), "entries with empty names"))
    }

    # Check for duplicate names
    if (any(duplicated(data$Name[!empty_names]))) {
      dupe_names <- data$Name[duplicated(data$Name) & !empty_names]
      errors <- c(errors, paste(exercise_name, "has duplicate names:",
                               paste(unique(dupe_names), collapse = ", ")))
    }
  }

  # Check ID column if it exists
  if ("ID" %in% names(data)) {
    if (any(is.na(data$ID) | data$ID == "")) {
      errors <- c(errors, paste(exercise_name, "has entries with missing IDs"))
    }
  }

  return(errors)
}
