# functions/module_validation_helpers.R
# Module Input Validation Helpers
#
# This file provides validation functions specifically for Shiny module inputs
# All functions are designed to work within reactive contexts and provide
# user-friendly error notifications

# ============================================================================
# TEXT INPUT VALIDATION
# ============================================================================

#' Validate text input
#'
#' Validates text input for non-empty, length, and pattern
#'
#' @param value Input value from Shiny
#' @param field_name Human-readable field name for error messages
#' @param required Logical, is field required?
#' @param min_length Minimum length (default: 1)
#' @param max_length Maximum length (default: NULL for no limit)
#' @param pattern Regex pattern to match (default: NULL)
#' @param session Shiny session for notifications
#' @return List with valid (logical) and message (character)
validate_text_input <- function(value, field_name, required = TRUE,
                                min_length = 1, max_length = NULL,
                                pattern = NULL, session = NULL) {

  tryCatch({

    # Check if value exists
    if (is.null(value) || length(value) == 0) {
      if (required) {
        msg <- paste(field_name, "is required")
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Trim whitespace
    value <- trimws(value)

    # Check if empty after trimming
    if (nchar(value) == 0) {
      if (required) {
        msg <- paste(field_name, "cannot be empty")
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Check minimum length
    if (nchar(value) < min_length) {
      msg <- paste(field_name, "must be at least", min_length, "characters")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check maximum length
    if (!is.null(max_length) && nchar(value) > max_length) {
      msg <- paste(field_name, "must be at most", max_length, "characters")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check pattern if provided
    if (!is.null(pattern) && !grepl(pattern, value)) {
      msg <- paste(field_name, "format is invalid")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # All checks passed
    return(list(valid = TRUE, message = NULL, value = value))

  }, error = function(e) {
    log_message(paste("Error validating text input:", e$message), "ERROR")
    msg <- paste("Validation error for", field_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg))
  })
}

#' Validate text input (shorthand)
#'
#' Quick validation for required text fields
#'
#' @param value Input value
#' @param field_name Field name for error messages
#' @param session Shiny session
#' @return Logical
validate_required_text <- function(value, field_name, session = NULL) {
  result <- validate_text_input(value, field_name, required = TRUE, session = session)
  return(result$valid)
}

# ============================================================================
# NUMERIC INPUT VALIDATION
# ============================================================================

#' Validate numeric input
#'
#' Validates numeric input for range and type
#'
#' @param value Input value from Shiny
#' @param field_name Human-readable field name
#' @param required Logical, is field required?
#' @param min Minimum value (default: NULL)
#' @param max Maximum value (default: NULL)
#' @param integer_only Require integer? (default: FALSE)
#' @param positive_only Require positive? (default: FALSE)
#' @param session Shiny session for notifications
#' @return List with valid (logical) and message (character)
validate_numeric_input <- function(value, field_name, required = TRUE,
                                   min = NULL, max = NULL,
                                   integer_only = FALSE, positive_only = FALSE,
                                   session = NULL) {

  tryCatch({

    # Check if value exists
    if (is.null(value) || length(value) == 0 || is.na(value)) {
      if (required) {
        msg <- paste(field_name, "is required")
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Check if numeric
    if (!is.numeric(value)) {
      msg <- paste(field_name, "must be a number")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check if integer if required
    if (integer_only && (value != as.integer(value))) {
      msg <- paste(field_name, "must be a whole number")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check if positive if required
    if (positive_only && value <= 0) {
      msg <- paste(field_name, "must be positive")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check minimum
    if (!is.null(min) && value < min) {
      msg <- paste(field_name, "must be at least", min)
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check maximum
    if (!is.null(max) && value > max) {
      msg <- paste(field_name, "must be at most", max)
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # All checks passed
    return(list(valid = TRUE, message = NULL, value = value))

  }, error = function(e) {
    log_message(paste("Error validating numeric input:", e$message), "ERROR")
    msg <- paste("Validation error for", field_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg))
  })
}

# ============================================================================
# SELECT INPUT VALIDATION
# ============================================================================

#' Validate select input
#'
#' Validates select/dropdown input
#'
#' @param value Selected value from Shiny
#' @param field_name Human-readable field name
#' @param required Logical, is selection required?
#' @param valid_choices Vector of valid choices (default: NULL)
#' @param session Shiny session for notifications
#' @return List with valid (logical) and message (character)
validate_select_input <- function(value, field_name, required = TRUE,
                                  valid_choices = NULL, session = NULL) {

  tryCatch({

    # Check if value exists
    if (is.null(value) || length(value) == 0 || value == "") {
      if (required) {
        msg <- paste("Please select", field_name)
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Check if value is in valid choices
    if (!is.null(valid_choices) && !value %in% valid_choices) {
      msg <- paste("Invalid selection for", field_name)
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # All checks passed
    return(list(valid = TRUE, message = NULL, value = value))

  }, error = function(e) {
    log_message(paste("Error validating select input:", e$message), "ERROR")
    msg <- paste("Validation error for", field_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg))
  })
}

# ============================================================================
# DATE INPUT VALIDATION
# ============================================================================

#' Validate date input
#'
#' Validates date input for range
#'
#' @param value Date value from Shiny
#' @param field_name Human-readable field name
#' @param required Logical, is date required?
#' @param min_date Minimum date (default: NULL)
#' @param max_date Maximum date (default: NULL)
#' @param session Shiny session for notifications
#' @return List with valid (logical) and message (character)
validate_date_input <- function(value, field_name, required = TRUE,
                                min_date = NULL, max_date = NULL,
                                session = NULL) {

  tryCatch({

    # Check if value exists
    if (is.null(value) || length(value) == 0 || is.na(value)) {
      if (required) {
        msg <- paste(field_name, "is required")
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Convert to Date if needed
    if (!inherits(value, "Date")) {
      date_value <- tryCatch({
        as.Date(value)
      }, error = function(e) {
        NULL
      })

      if (is.null(date_value)) {
        msg <- paste(field_name, "is not a valid date")
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      }
    } else {
      date_value <- value
    }

    # Check minimum date
    if (!is.null(min_date)) {
      min_date_conv <- as.Date(min_date)
      if (date_value < min_date_conv) {
        msg <- paste(field_name, "cannot be before", format(min_date_conv, "%Y-%m-%d"))
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      }
    }

    # Check maximum date
    if (!is.null(max_date)) {
      max_date_conv <- as.Date(max_date)
      if (date_value > max_date_conv) {
        msg <- paste(field_name, "cannot be after", format(max_date_conv, "%Y-%m-%d"))
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      }
    }

    # All checks passed
    return(list(valid = TRUE, message = NULL, value = date_value))

  }, error = function(e) {
    log_message(paste("Error validating date input:", e$message), "ERROR")
    msg <- paste("Validation error for", field_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg))
  })
}

# ============================================================================
# FILE INPUT VALIDATION
# ============================================================================

#' Validate file upload
#'
#' Validates uploaded file for type and size
#'
#' @param file_input File input from Shiny (input$file)
#' @param field_name Human-readable field name
#' @param required Logical, is file required?
#' @param allowed_extensions Vector of allowed extensions (e.g., c("xlsx", "csv"))
#' @param max_size_mb Maximum file size in MB (default: 10)
#' @param session Shiny session for notifications
#' @return List with valid (logical) and message (character)
validate_file_upload <- function(file_input, field_name, required = TRUE,
                                 allowed_extensions = NULL, max_size_mb = 10,
                                 session = NULL) {

  tryCatch({

    # Check if file exists
    if (is.null(file_input) || !is.data.frame(file_input) || nrow(file_input) == 0) {
      if (required) {
        msg <- paste("Please upload", field_name)
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      } else {
        return(list(valid = TRUE, message = NULL))
      }
    }

    # Get file info
    file_name <- file_input$name[1]
    file_size <- file_input$size[1]
    file_path <- file_input$datapath[1]

    # Check file extension
    if (!is.null(allowed_extensions)) {
      file_ext <- tolower(tools::file_ext(file_name))

      if (!file_ext %in% allowed_extensions) {
        msg <- paste(field_name, "must be one of:", paste(allowed_extensions, collapse = ", "))
        if (!is.null(session)) {
          showNotification(msg, type = "warning", session = session)
        }
        return(list(valid = FALSE, message = msg))
      }
    }

    # Check file size
    file_size_mb <- file_size / 1024 / 1024
    if (file_size_mb > max_size_mb) {
      msg <- paste(field_name, "is too large. Maximum size:", max_size_mb, "MB")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # Check file exists at path
    if (!file.exists(file_path)) {
      msg <- paste("Uploaded file not found")
      if (!is.null(session)) {
        showNotification(msg, type = "error", session = session)
      }
      return(list(valid = FALSE, message = msg))
    }

    # All checks passed
    return(list(
      valid = TRUE,
      message = NULL,
      name = file_name,
      path = file_path,
      size_mb = round(file_size_mb, 2)
    ))

  }, error = function(e) {
    log_message(paste("Error validating file upload:", e$message), "ERROR")
    msg <- paste("File validation error")
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg))
  })
}

# ============================================================================
# COMPOSITE VALIDATION
# ============================================================================

#' Validate multiple inputs at once
#'
#' Validates multiple inputs and returns combined result
#'
#' @param validations List of validation results
#' @param session Shiny session for notifications
#' @return Logical indicating if all validations passed
validate_all <- function(validations, session = NULL) {

  tryCatch({

    if (!is.list(validations)) {
      log_message("validate_all requires list of validation results", "ERROR")
      return(FALSE)
    }

    # Check each validation
    all_valid <- TRUE
    error_messages <- c()

    for (i in seq_along(validations)) {
      validation <- validations[[i]]

      if (!is.list(validation) || !"valid" %in% names(validation)) {
        log_message(paste("Invalid validation result at index", i), "WARNING")
        all_valid <- FALSE
        next
      }

      if (!validation$valid) {
        all_valid <- FALSE
        if (!is.null(validation$message)) {
          error_messages <- c(error_messages, validation$message)
        }
      }
    }

    # Show combined error if needed
    if (!all_valid && !is.null(session) && length(error_messages) > 0) {
      combined_msg <- paste(
        "Please fix the following issues:",
        paste("-", error_messages, collapse = "\n")
      )
      showNotification(combined_msg, type = "warning", duration = 10, session = session)
    }

    return(all_valid)

  }, error = function(e) {
    log_message(paste("Error in validate_all:", e$message), "ERROR")
    return(FALSE)
  })
}

# ============================================================================
# REACTIVE VALIDATION HELPERS
# ============================================================================

#' Create reactive validation
#'
#' Wraps validation in reactive expression
#'
#' @param validation_expr Expression that returns validation result
#' @return Reactive validation
reactive_validation <- function(validation_expr) {
  reactive({
    tryCatch({
      validation_expr
    }, error = function(e) {
      log_message(paste("Error in reactive validation:", e$message), "ERROR")
      list(valid = FALSE, message = "Validation error")
    })
  })
}

#' Enable/disable button based on validation
#'
#' Helper to enable/disable action button based on validation state
#'
#' @param session Shiny session
#' @param button_id Button ID to enable/disable
#' @param validation_reactive Reactive that returns validation result
#' @return Observer
observe_validation <- function(session, button_id, validation_reactive) {
  observe({
    validation <- validation_reactive()

    if (is.list(validation) && "valid" %in% names(validation)) {
      if (validation$valid) {
        shinyjs::enable(button_id)
      } else {
        shinyjs::disable(button_id)
      }
    }
  })
}

# ============================================================================
# DOMAIN-SPECIFIC VALIDATION
# ============================================================================

#' Validate stakeholder power/interest
#'
#' Validates power and interest values are in range 0-10
#'
#' @param power Power value
#' @param interest Interest value
#' @param session Shiny session
#' @return List with valid (logical) and message (character)
validate_stakeholder_values <- function(power, interest, session = NULL) {

  validations <- list(
    validate_numeric_input(power, "Power", required = TRUE,
                          min = 0, max = 10, session = session),
    validate_numeric_input(interest, "Interest", required = TRUE,
                          min = 0, max = 10, session = session)
  )

  all_valid <- validate_all(validations, session = NULL)  # Don't show duplicate notification

  return(list(
    valid = all_valid,
    message = if (all_valid) NULL else "Power and Interest must be between 0 and 10"
  ))
}

#' Validate element data
#'
#' Validates DAPSI(W)R(M) element data entry
#'
#' @param name Element name
#' @param indicator Indicator name
#' @param session Shiny session
#' @return List with valid (logical) and message (character)
validate_element_entry <- function(name, indicator = NULL, session = NULL) {

  validations <- list(
    validate_text_input(name, "Element name", required = TRUE,
                       min_length = 2, max_length = 200, session = session)
  )

  if (!is.null(indicator)) {
    validations <- c(validations, list(
      validate_text_input(indicator, "Indicator", required = FALSE,
                         max_length = 200, session = session)
    ))
  }

  all_valid <- validate_all(validations, session = NULL)

  return(list(
    valid = all_valid,
    message = if (all_valid) NULL else "Please check element data"
  ))
}

#' Validate email address
#'
#' Validates email format
#'
#' @param email Email address
#' @param field_name Field name for error messages
#' @param required Is email required?
#' @param session Shiny session
#' @return List with valid (logical) and message (character)
validate_email <- function(email, field_name = "Email", required = TRUE, session = NULL) {

  # Basic email regex pattern
  email_pattern <- "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

  validate_text_input(
    email,
    field_name,
    required = required,
    pattern = email_pattern,
    session = session
  )
}

# ============================================================================
# DATA FRAME VALIDATION
# ============================================================================

#' Validate data frame columns
#'
#' Checks if a data frame has required columns
#'
#' @param df Data frame to validate
#' @param required_cols Character vector of required column names
#' @param df_name Human-readable name for the data frame (for error messages)
#' @param case_sensitive Logical, should column matching be case-sensitive? (default: TRUE)
#' @param session Shiny session for notifications
#' @return List with valid (logical), message (character), and missing_cols (character vector)
#' @examples
#' # Check if data has required columns
#' result <- validate_dataframe_columns(my_data, c("Year", "Value"), "Time series data")
#' if (!result$valid) {
#'   print(result$message)
#' }
validate_dataframe_columns <- function(df, required_cols, df_name = "Data frame",
                                      case_sensitive = TRUE, session = NULL) {

  tryCatch({

    # Check if df exists and is a data frame
    if (is.null(df)) {
      msg <- paste(df_name, "is NULL")
      if (!is.null(session)) {
        showNotification(msg, type = "error", session = session)
      }
      return(list(valid = FALSE, message = msg, missing_cols = required_cols))
    }

    if (!is.data.frame(df)) {
      msg <- paste(df_name, "is not a data frame")
      if (!is.null(session)) {
        showNotification(msg, type = "error", session = session)
      }
      return(list(valid = FALSE, message = msg, missing_cols = required_cols))
    }

    # Check if df has any rows
    if (nrow(df) == 0) {
      msg <- paste(df_name, "is empty")
      if (!is.null(session)) {
        showNotification(msg, type = "warning", session = session)
      }
      return(list(valid = FALSE, message = msg, missing_cols = required_cols))
    }

    # Get column names
    df_cols <- names(df)

    # Check for required columns
    if (case_sensitive) {
      missing_cols <- setdiff(required_cols, df_cols)
    } else {
      # Case-insensitive matching
      df_cols_lower <- tolower(df_cols)
      required_cols_lower <- tolower(required_cols)
      missing_cols_lower <- setdiff(required_cols_lower, df_cols_lower)

      # Map back to original required column names
      missing_cols <- required_cols[required_cols_lower %in% missing_cols_lower]
    }

    # If columns are missing, return error
    if (length(missing_cols) > 0) {
      if (length(missing_cols) == 1) {
        msg <- paste(df_name, "must have column:", missing_cols)
      } else {
        msg <- paste(df_name, "must have columns:", paste(missing_cols, collapse = ", "))
      }

      if (!is.null(session)) {
        showNotification(msg, type = "error", session = session)
      }

      return(list(valid = FALSE, message = msg, missing_cols = missing_cols))
    }

    # All checks passed
    return(list(valid = TRUE, message = NULL, missing_cols = character(0)))

  }, error = function(e) {
    log_message(paste("Error validating data frame columns:", e$message), "ERROR")
    msg <- paste("Validation error for", df_name)
    if (!is.null(session)) {
      showNotification(msg, type = "error", session = session)
    }
    return(list(valid = FALSE, message = msg, missing_cols = required_cols))
  })
}

#' Validate data frame columns (shorthand)
#'
#' Quick validation for required columns, returns logical
#'
#' @param df Data frame to validate
#' @param required_cols Character vector of required column names
#' @param df_name Human-readable name for the data frame
#' @param session Shiny session
#' @return Logical indicating if all required columns exist
has_required_columns <- function(df, required_cols, df_name = "Data", session = NULL) {
  result <- validate_dataframe_columns(df, required_cols, df_name, session = session)
  return(result$valid)
}
