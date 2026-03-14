# functions/ml_feedback_logger.R
# User Feedback Logging for ML Model Improvement
# Captures accept/reject decisions for active learning

# ==============================================================================
# Configuration
# ==============================================================================

FEEDBACK_LOG_FILE <- "data/ml_feedback_log.rds"
FEEDBACK_CSV_FILE <- "data/ml_feedback_log.csv"

# In-memory cache to avoid repeated disk reads
.feedback_cache <- new.env(parent = emptyenv())
.feedback_cache$data <- NULL
.feedback_cache$mtime <- NULL

#' Read feedback log with caching
#' @return Feedback log dataframe
read_feedback_cached <- function() {
  if (!file.exists(FEEDBACK_LOG_FILE)) return(NULL)
  current_mtime <- file.mtime(FEEDBACK_LOG_FILE)
  if (!is.null(.feedback_cache$data) && !is.null(.feedback_cache$mtime) &&
      identical(current_mtime, .feedback_cache$mtime)) {
    return(.feedback_cache$data)
  }
  .feedback_cache$data <- readRDS(FEEDBACK_LOG_FILE)
  .feedback_cache$mtime <- current_mtime
  .feedback_cache$data
}

#' Write feedback log and update cache
#' @param feedback_log Feedback log dataframe
write_feedback_and_cache <- function(feedback_log) {
  saveRDS(feedback_log, FEEDBACK_LOG_FILE)
  write.csv(feedback_log, FEEDBACK_CSV_FILE, row.names = FALSE)
  .feedback_cache$data <- feedback_log
  .feedback_cache$mtime <- file.mtime(FEEDBACK_LOG_FILE)
}

# ==============================================================================
# Feedback Logging Functions
# ==============================================================================

#' Initialize Feedback Log
#'
#' Creates empty feedback log if it doesn't exist
#'
#' @export
init_feedback_log <- function() {
  if (!file.exists(FEEDBACK_LOG_FILE)) {
    # Create empty feedback dataframe
    feedback_log <- data.frame(
      timestamp = as.POSIXct(character()),
      prediction_id = character(),
      prediction_type = character(),  # "classification" or "connection"

      # Element details
      source_name = character(),
      source_type = character(),
      target_name = character(),
      target_type = character(),

      # ML prediction
      ml_predicted_type = character(),
      ml_existence_probability = numeric(),
      ml_strength = character(),
      ml_confidence = numeric(),
      ml_polarity = character(),

      # User decision
      user_action = character(),  # "accepted", "rejected", "modified"
      user_selected_type = character(),
      user_selected_strength = character(),
      user_selected_confidence = numeric(),
      user_selected_polarity = character(),

      # Context
      regional_sea = character(),
      ecosystem_types = character(),
      main_issues = character(),

      # Uncertainty metrics (Phase 2 - Week 6)
      uncertainty_score = numeric(),          # Overall uncertainty (0-1)
      confidence_category = character(),       # "high_confidence", "medium_confidence", "low_confidence"
      disagreement_score = numeric(),          # Ensemble disagreement (0-1)
      uncertainty_existence = numeric(),       # Task-specific uncertainties
      uncertainty_strength = numeric(),
      uncertainty_confidence = numeric(),
      uncertainty_polarity = numeric(),

      # Active learning metadata
      sampling_method = character(),           # "uncertainty", "disagreement", "combined", "random"
      was_reviewed = logical(),               # TRUE if from active learning review

      # Session metadata
      session_id = character(),
      user_id = character()

      
    )

    write_feedback_and_cache(feedback_log)

    debug_log(paste("Initialized feedback log:", FEEDBACK_LOG_FILE), "ML_FEEDBACK")
    return(feedback_log)
  } else {
    # Load existing log (cached)
    feedback_log <- read_feedback_cached()
    debug_log(paste("Loaded existing feedback log:", nrow(feedback_log), "entries"), "ML_FEEDBACK")
    return(feedback_log)
  }
}

#' Log Classification Feedback
#'
#' Records user's accept/reject of ML classification
#'
#' @param element_name Name of classified element
#' @param ml_prediction ML prediction result from classify_element_ml_enhanced
#' @param user_action "accepted", "rejected", or "modified"
#' @param user_selected_type Type user actually selected
#' @param context Context information
#' @param session_id Session identifier
#' @export
log_classification_feedback <- function(element_name,
                                       ml_prediction,
                                       user_action,
                                       user_selected_type,
                                       context = list(),
                                       session_id = NULL) {

  # Load feedback log (cached)
  feedback_log <- tryCatch({
    read_feedback_cached() %||% init_feedback_log()
  }, error = function(e) {
    init_feedback_log()
  })

  # Create new entry
  new_entry <- data.frame(
    timestamp = Sys.time(),
    prediction_id = generate_prediction_id(),
    prediction_type = "classification",

    # Element details
    source_name = element_name,
    source_type = ml_prediction$primary$type,
    target_name = NA,
    target_type = NA,

    # ML prediction
    ml_predicted_type = ml_prediction$primary$type,
    ml_existence_probability = ml_prediction$primary$confidence,
    ml_strength = NA,
    ml_confidence = ml_prediction$primary$confidence * 5,  # Convert to 1-5 scale
    ml_polarity = NA,

    # User decision
    user_action = user_action,
    user_selected_type = user_selected_type,
    user_selected_strength = NA,
    user_selected_confidence = NA,
    user_selected_polarity = NA,

    # Context
    regional_sea = context$regional_sea %||% NA,
    ecosystem_types = paste(context$ecosystem_types %||% "", collapse = ";"),
    main_issues = paste(context$main_issues %||% "", collapse = ";"),

    # Session metadata
    session_id = session_id %||% "unknown",
    user_id = Sys.info()["user"]

    
  )

  # Append to log
  feedback_log <- rbind(feedback_log, new_entry)

  # Save (cached)
  write_feedback_and_cache(feedback_log)

  debug_log(paste("Logged classification feedback:", user_action, "(", element_name, ")"), "ML_FEEDBACK")

  return(invisible(new_entry))
}

#' Log Connection Feedback
#'
#' Records user's accept/reject of ML connection suggestion
#'
#' @param source_element Source element details
#' @param target_element Target element details
#' @param ml_prediction ML prediction result
#' @param user_action "accepted", "rejected", "modified"
#' @param user_properties User-selected connection properties
#' @param context Context information
#' @param session_id Session identifier
#' @export
log_connection_feedback <- function(source_element,
                                   target_element,
                                   ml_prediction,
                                   user_action,
                                   user_properties = list(),
                                   context = list(),
                                   session_id = NULL) {

  # Load feedback log (cached)
  feedback_log <- tryCatch({
    read_feedback_cached() %||% init_feedback_log()
  }, error = function(e) {
    init_feedback_log()
  })

  # Create new entry
  new_entry <- data.frame(
    timestamp = Sys.time(),
    prediction_id = generate_prediction_id(),
    prediction_type = "connection",

    # Element details
    source_name = source_element$name,
    source_type = source_element$type,
    target_name = target_element$name,
    target_type = target_element$type,

    # ML prediction
    ml_predicted_type = target_element$type,
    ml_existence_probability = ml_prediction$existence_probability %||% NA,
    ml_strength = ml_prediction$strength %||% NA,
    ml_confidence = ml_prediction$confidence %||% NA,
    ml_polarity = ml_prediction$polarity %||% NA,

    # User decision
    user_action = user_action,
    user_selected_type = target_element$type,
    user_selected_strength = user_properties$strength %||% ml_prediction$strength %||% NA,
    user_selected_confidence = user_properties$confidence %||% ml_prediction$confidence %||% NA,
    user_selected_polarity = user_properties$polarity %||% ml_prediction$polarity %||% NA,

    # Context
    regional_sea = context$regional_sea %||% NA,
    ecosystem_types = paste(context$ecosystem_types %||% "", collapse = ";"),
    main_issues = paste(context$main_issues %||% "", collapse = ";"),

    # Uncertainty metrics (Phase 2 - Week 6)
    uncertainty_score = if (!is.null(ml_prediction$uncertainty)) {
      ml_prediction$uncertainty$overall_score %||% NA
    } else { NA },
    confidence_category = if (!is.null(ml_prediction$uncertainty)) {
      ml_prediction$uncertainty$confidence_category %||% NA
    } else { NA },
    disagreement_score = if (!is.null(ml_prediction$disagreement)) {
      ml_prediction$disagreement$overall_score %||% NA
    } else { NA },
    uncertainty_existence = if (!is.null(ml_prediction$uncertainty$task_uncertainties)) {
      ml_prediction$uncertainty$task_uncertainties$existence %||% NA
    } else { NA },
    uncertainty_strength = if (!is.null(ml_prediction$uncertainty$task_uncertainties)) {
      ml_prediction$uncertainty$task_uncertainties$strength %||% NA
    } else { NA },
    uncertainty_confidence = if (!is.null(ml_prediction$uncertainty$task_uncertainties)) {
      ml_prediction$uncertainty$task_uncertainties$confidence %||% NA
    } else { NA },
    uncertainty_polarity = if (!is.null(ml_prediction$uncertainty$task_uncertainties)) {
      ml_prediction$uncertainty$task_uncertainties$polarity %||% NA
    } else { NA },

    # Active learning metadata
    sampling_method = ml_prediction$sampling_method %||% NA,
    was_reviewed = !is.null(ml_prediction$from_review) && ml_prediction$from_review,

    # Session metadata
    session_id = session_id %||% "unknown",
    user_id = Sys.info()["user"]

    
  )

  # Append to log
  feedback_log <- rbind(feedback_log, new_entry)

  # Save (cached)
  write_feedback_and_cache(feedback_log)

  debug_log(paste("Logged connection feedback:", user_action,
          "(", source_element$name, "->", target_element$name, ")"), "ML_FEEDBACK")

  return(invisible(new_entry))
}

#' Generate Unique Prediction ID
#'
#' @return Character prediction ID
generate_prediction_id <- function() {
  paste0("PRED_", format(Sys.time(), "%Y%m%d%H%M%S"), "_",
         sample(1000:9999, 1))
}

#' Get Feedback Statistics
#'
#' Calculates statistics about user feedback
#'
#' @return List with feedback statistics
#' @export
get_feedback_stats <- function() {
  if (!file.exists(FEEDBACK_LOG_FILE)) {
    return(list(
      total_entries = 0,
      classifications = 0,
      connections = 0,
      acceptance_rate = NA,
      message = "No feedback data available"
    ))
  }

  feedback_log <- read_feedback_cached()

  if (is.null(feedback_log) || nrow(feedback_log) == 0) {
    return(list(
      total_entries = 0,
      classifications = 0,
      connections = 0,
      acceptance_rate = NA,
      message = "Feedback log is empty"
    ))
  }

  # Calculate statistics
  n_total <- nrow(feedback_log)
  n_classifications <- sum(feedback_log$prediction_type == "classification")
  n_connections <- sum(feedback_log$prediction_type == "connection")

  n_accepted <- sum(feedback_log$user_action == "accepted", na.rm = TRUE)
  n_rejected <- sum(feedback_log$user_action == "rejected", na.rm = TRUE)
  n_modified <- sum(feedback_log$user_action == "modified", na.rm = TRUE)

  acceptance_rate <- n_accepted / (n_accepted + n_rejected + n_modified)

  # Per-type statistics
  classification_stats <- if (n_classifications > 0) {
    class_log <- feedback_log[feedback_log$prediction_type == "classification", ]
    list(
      total = n_classifications,
      accepted = sum(class_log$user_action == "accepted", na.rm = TRUE),
      rejected = sum(class_log$user_action == "rejected", na.rm = TRUE),
      modified = sum(class_log$user_action == "modified", na.rm = TRUE),
      accuracy = sum(class_log$ml_predicted_type == class_log$user_selected_type, na.rm = TRUE) / n_classifications
    )
  } else {
    NULL
  }

  connection_stats <- if (n_connections > 0) {
    conn_log <- feedback_log[feedback_log$prediction_type == "connection", ]
    list(
      total = n_connections,
      accepted = sum(conn_log$user_action == "accepted", na.rm = TRUE),
      rejected = sum(conn_log$user_action == "rejected", na.rm = TRUE),
      modified = sum(conn_log$user_action == "modified", na.rm = TRUE),
      avg_probability = mean(conn_log$ml_existence_probability, na.rm = TRUE)
    )
  } else {
    NULL
  }

  return(list(
    total_entries = n_total,
    classifications = n_classifications,
    connections = n_connections,
    accepted = n_accepted,
    rejected = n_rejected,
    modified = n_modified,
    acceptance_rate = acceptance_rate,
    classification_stats = classification_stats,
    connection_stats = connection_stats,
    latest_timestamp = max(feedback_log$timestamp, na.rm = TRUE),
    oldest_timestamp = min(feedback_log$timestamp, na.rm = TRUE)
  ))
}

#' Export Feedback for Retraining
#'
#' Exports feedback log in format suitable for model retraining
#'
#' @param output_file Output file path
#' @param min_confidence_threshold Only export high-confidence user decisions
#' @return Path to exported file
#' @export
export_feedback_for_retraining <- function(output_file = "data/ml_feedback_training.csv",
                                           min_confidence_threshold = 3) {

  if (!file.exists(FEEDBACK_LOG_FILE)) {
    stop("No feedback log found")
  }

  feedback_log <- read_feedback_cached()

  # Filter for high-quality feedback (user was confident)
  # Only include accepted connections or corrected classifications
  training_data <- feedback_log %>%
    filter(
      (prediction_type == "connection" & user_action == "accepted") |
      (prediction_type == "classification" & !is.na(user_selected_type))
    )

  # Format for training
  training_export <- training_data %>%
    select(
      source_name,
      source_type = user_selected_type,
      target_name,
      target_type,
      connection_exists = user_action,  # Will convert
      strength = user_selected_strength,
      confidence = user_selected_confidence,
      polarity = user_selected_polarity,
      regional_sea,
      ecosystem_types,
      main_issues
    ) %>%
    mutate(
      connection_exists = ifelse(connection_exists == "accepted", 1, 0)
    )

  write.csv(training_export, output_file, row.names = FALSE)

  debug_log(paste("Exported", nrow(training_export), "feedback entries to:", output_file), "ML_FEEDBACK")

  return(output_file)
}

# ==============================================================================
# Initialization
# ==============================================================================

# Initialize feedback log on load (creates file if missing)
#' Check if Auto-Retrain Triggered (Phase 2 - Week 6)
#'
#' Checks if enough new feedback has accumulated to trigger model retraining
#'
#' @param threshold Integer. Number of new feedback entries to trigger retrain (default: 50)
#' @param last_retrain_file Character. File tracking last retrain timestamp
#' @return List with trigger status and counts
#' @export
check_retrain_trigger <- function(threshold = 50,
                                  last_retrain_file = "models/last_retrain_timestamp.txt") {

  if (!file.exists(FEEDBACK_LOG_FILE)) {
    return(list(
      should_retrain = FALSE,
      new_feedback_count = 0,
      message = "No feedback log found"
    ))
  }

  feedback_log <- read_feedback_cached()

  # Get last retrain timestamp
  if (file.exists(last_retrain_file)) {
    last_retrain_time <- as.POSIXct(readLines(last_retrain_file)[1])
  } else {
    last_retrain_time <- as.POSIXct("1970-01-01")  # Beginning of time
  }

  # Count feedback since last retrain
  new_feedback <- feedback_log[feedback_log$timestamp > last_retrain_time, ]
  new_count <- nrow(new_feedback)

  should_retrain <- new_count >= threshold

  return(list(
    should_retrain = should_retrain,
    new_feedback_count = new_count,
    threshold = threshold,
    last_retrain_time = last_retrain_time,
    message = if (should_retrain) {
      sprintf("Retraining triggered: %d new feedback entries (threshold: %d)",
             new_count, threshold)
    } else {
      sprintf("%d/%d new feedback entries", new_count, threshold)
    }
  ))
}

#' Mark Retrain Complete (Phase 2 - Week 6)
#'
#' Updates the last retrain timestamp after model retraining
#'
#' @param timestamp POSIXct. Retrain completion time (default: current time)
#' @param last_retrain_file Character. File to store timestamp
#' @export
mark_retrain_complete <- function(timestamp = Sys.time(),
                                  last_retrain_file = "models/last_retrain_timestamp.txt") {

  # Ensure directory exists
  dir_path <- dirname(last_retrain_file)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }

  # Write timestamp
  writeLines(as.character(timestamp), last_retrain_file)

  debug_log(paste("Retrain timestamp updated:", timestamp), "ML_FEEDBACK")
  return(invisible(timestamp))
}

#' Auto-Trigger Retrain if Needed (Phase 2 - Week 6)
#'
#' Checks trigger and optionally starts retraining
#'
#' @param threshold Integer. Feedback threshold for retraining
#' @param auto_start Logical. If TRUE, automatically start retraining
#' @param retrain_script Character. Path to retraining script
#' @return List with trigger info
#' @export
auto_retrain_check <- function(threshold = 50,
                               auto_start = FALSE,
                               retrain_script = "scripts/train_with_curriculum.R") {

  trigger_info <- check_retrain_trigger(threshold)

  if (trigger_info$should_retrain) {
    debug_log(trigger_info$message, "ML_AUTO_RETRAIN")

    if (auto_start) {
      if (file.exists(retrain_script)) {
        debug_log(paste("Starting retraining:", retrain_script), "ML_AUTO_RETRAIN")

        # Start retraining in background
        system2(
          "Rscript",
          args = retrain_script,
          wait = FALSE,
          stdout = "models/retrain_log.txt",
          stderr = "models/retrain_errors.txt"
        )

        debug_log("Retraining started in background. Check models/retrain_log.txt for progress", "ML_AUTO_RETRAIN")

      } else {
        debug_log(paste("Retrain script not found:", retrain_script), "ML_AUTO_RETRAIN")
      }
    } else {
      debug_log("Auto-start disabled. Run retraining manually.", "ML_AUTO_RETRAIN")
    }
  }

  return(trigger_info)
}

# ==============================================================================
# Module Initialization
# ==============================================================================

if (!exists(".ml_feedback_initialized")) {
  init_feedback_log()
  .ml_feedback_initialized <- TRUE
}

debug_log("ML Feedback Logger loaded", "ML_FEEDBACK")
