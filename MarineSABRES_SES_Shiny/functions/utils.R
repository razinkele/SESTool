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

# ============================================================================
# JSON PROJECT DATA VALIDATION
# ============================================================================

#' Validate JSON project input data
#'
#' Validates project data received from client-side JSON (e.g., from localStorage
#' or sessionStorage after language change). Checks structure, types, and limits
#' to prevent malicious or malformed data from being loaded.
#'
#' @param data List parsed from JSON input
#' @return List with: valid (logical), errors (character vector), data (validated data or NULL)
#' @export
validate_json_project_input <- function(data) {
  errors <- c()

  # Check basic structure

  if (!is.list(data)) {
    return(list(valid = FALSE, errors = "Data must be a list", data = NULL))
  }

  # Check for expected top-level structure
  # Valid structures: direct project_data or wrapper with 'data' key
  project_data <- data

  # If data has a nested 'data' key containing the actual project, unwrap it
  if (!is.null(data$data) && is.list(data$data)) {
    # This is a wrapped structure
    project_data <- data
  }

  # Validate string length limits to prevent DoS
  max_string_length <- 10000  # 10KB per string field
  max_name_length <- 500

  # Validate project_id if present
  if (!is.null(project_data$project_id)) {
    if (!is.character(project_data$project_id) ||
        nchar(as.character(project_data$project_id)) > max_name_length) {
      errors <- c(errors, "Invalid or too long project_id")
    }
  }

  # Validate project_name if present
  if (!is.null(project_data$project_name)) {
    if (!is.character(project_data$project_name) ||
        nchar(as.character(project_data$project_name)) > max_name_length) {
      errors <- c(errors, "Invalid or too long project_name")
    }
  }

  # Validate nested data structure if present
  if (!is.null(project_data$data) && is.list(project_data$data)) {
    nested_data <- project_data$data

    # Validate ISA data if present
    if (!is.null(nested_data$isa_data) && is.list(nested_data$isa_data)) {
      isa_data <- nested_data$isa_data

      # Check elements count limit
      if (!is.null(isa_data$elements) && is.list(isa_data$elements)) {
        total_elements <- 0
        for (type_name in names(isa_data$elements)) {
          type_data <- isa_data$elements[[type_name]]
          if (is.data.frame(type_data)) {
            total_elements <- total_elements + nrow(type_data)
          } else if (is.list(type_data)) {
            total_elements <- total_elements + length(type_data)
          }
        }
        if (total_elements > 10000) {
          errors <- c(errors, "Too many elements in ISA data (max 10000)")
        }
      }

      # Check connections count limit
      if (!is.null(isa_data$connections)) {
        conn_count <- 0
        if (is.data.frame(isa_data$connections)) {
          conn_count <- nrow(isa_data$connections)
        } else if (is.list(isa_data$connections)) {
          conn_count <- length(isa_data$connections)
        }
        if (conn_count > 50000) {
          errors <- c(errors, "Too many connections in ISA data (max 50000)")
        }
      }
    }

    # Validate CLD data if present
    if (!is.null(nested_data$cld_data) && is.list(nested_data$cld_data)) {
      cld_data <- nested_data$cld_data

      # Check nodes count limit
      if (!is.null(cld_data$nodes)) {
        node_count <- if (is.data.frame(cld_data$nodes)) nrow(cld_data$nodes) else length(cld_data$nodes)
        if (node_count > 10000) {
          errors <- c(errors, "Too many nodes in CLD data (max 10000)")
        }
      }

      # Check edges count limit
      if (!is.null(cld_data$edges)) {
        edge_count <- if (is.data.frame(cld_data$edges)) nrow(cld_data$edges) else length(cld_data$edges)
        if (edge_count > 50000) {
          errors <- c(errors, "Too many edges in CLD data (max 50000)")
        }
      }
    }
  }

  # Return validation result
  if (length(errors) > 0) {
    return(list(valid = FALSE, errors = errors, data = NULL))
  }

  return(list(valid = TRUE, errors = NULL, data = project_data))
}

# ============================================================================
# SAFE RDS FILE LOADING
# ============================================================================

#' Safely load an RDS file with size and type validation
#'
#' Loads an RDS file with security checks to prevent loading excessively large
#' files or malicious objects. Validates the result is a basic list structure.
#'
#' @param file Path to the RDS file
#' @param max_size_mb Maximum allowed file size in megabytes (default: 50)
#' @return The loaded data, or NULL with warning if validation fails
#' @export
safe_readRDS <- function(file, max_size_mb = 50) {
  # Check file exists

  if (!file.exists(file)) {
    warning("File does not exist: ", file)
    return(NULL)
  }

  # Check file size
  file_size <- file.size(file)
  max_size_bytes <- max_size_mb * 1024 * 1024

  if (file_size > max_size_bytes) {
    warning(sprintf("File exceeds maximum size limit (%.1f MB > %d MB)",
                   file_size / (1024 * 1024), max_size_mb))
    return(NULL)
  }

  # Attempt to load the file
  data <- tryCatch({
    readRDS(file)
  }, error = function(e) {
    warning("Failed to read RDS file: ", e$message)
    return(NULL)
  })

  if (is.null(data)) {
    return(NULL)
  }

  # Validate result is a basic list, not an environment or function
  # These could potentially execute code
  if (is.environment(data)) {
    warning("RDS file contains an environment - this is not allowed for security reasons")
    return(NULL)
  }

  if (is.function(data)) {
    warning("RDS file contains a function - this is not allowed for security reasons")
    return(NULL)
  }

  # Check for potentially dangerous object types at the top level
  if (!is.list(data) && !is.data.frame(data) && !is.vector(data)) {
    warning("RDS file contains unexpected object type: ", class(data)[1])
    return(NULL)
  }

  return(data)
}
