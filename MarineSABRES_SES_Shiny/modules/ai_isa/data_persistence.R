# modules/ai_isa/data_persistence.R
# AI ISA Assistant - Data Persistence Sub-Module
# Purpose: Handle session save/load and ISA format conversion
#
# This module handles:
# - Session state serialization and restoration
# - localStorage integration for browser-based persistence
# - Conversion of AI ISA data to ISA framework format
# - Adjacency matrix building from approved connections
# - Auto-save functionality with debouncing

# ============================================================================
# SESSION SERIALIZATION
# ============================================================================

#' Get Current Session Data
#'
#' Serializes the current AI ISA assistant session state into a saveable format
#'
#' @param rv Reactive values object containing session state
#'
#' @return List containing all session data with timestamp
get_session_data <- function(rv) {
  list(
    current_step = rv$current_step,
    elements = rv$elements,
    context = rv$context,
    suggested_connections = rv$suggested_connections,
    approved_connections = rv$approved_connections,
    conversation = rv$conversation,
    timestamp = Sys.time()
  )
}

#' Restore Session Data
#'
#' Restores a saved AI ISA assistant session from serialized data
#'
#' @param rv Reactive values object to restore into
#' @param data Saved session data from get_session_data()
#' @param i18n Optional i18n translator for notification messages
#'
#' @return NULL (modifies rv in place)
restore_session_data <- function(rv, data, i18n = NULL) {
  if (!is.null(data)) {
    rv$current_step <- data$current_step %||% 0
    rv$elements <- data$elements %||% list(
      drivers = list(),
      activities = list(),
      pressures = list(),
      states = list(),
      impacts = list(),
      welfare = list(),
      responses = list()
    )
    rv$context <- data$context %||% list(
      project_name = NULL,
      location = NULL,
      ecosystem_type = NULL,
      main_issue = NULL
    )
    rv$suggested_connections <- data$suggested_connections %||% list()
    rv$approved_connections <- data$approved_connections %||% list()
    rv$conversation <- data$conversation %||% list()

    # Show notification if i18n is available
    if (!is.null(i18n)) {
      showNotification(i18n$t("common.messages.session_restored_successfully"), type = "message", duration = 3)
    } else {
      showNotification("Session restored successfully!", type = "message", duration = 3)
    }
  }
}

# ============================================================================
# ISA FORMAT CONVERSION
# ============================================================================

#' Convert AI ISA Elements to ISA Dataframe Format
#'
#' Converts AI ISA element lists into the ISA framework dataframe structure
#' with proper IDs, types, and metadata fields
#'
#' @param elements List of AI ISA elements (drivers, activities, pressures, etc.)
#' @param element_type Type of elements to convert
#' @param id_prefix Prefix for element IDs (e.g., "D", "A", "P")
#' @param type_label Label for the Type column
#'
#' @return Dataframe in ISA format
convert_to_isa_dataframe <- function(elements, element_type, id_prefix, type_label) {
  if (length(elements[[element_type]]) > 0) {
    data.frame(
      ID = paste0(id_prefix, sprintf("%03d", seq_along(elements[[element_type]]))),
      Name = sapply(elements[[element_type]], function(x) x$name),
      Type = type_label,
      Description = sapply(elements[[element_type]], function(x) x$description %||% ""),
      Stakeholder = "",
      Importance = "",
      Trend = "",
      stringsAsFactors = FALSE
    )
  } else {
    # Return empty dataframe with proper structure
    data.frame(
      ID = character(),
      Name = character(),
      Type = character(),
      Description = character(),
      Stakeholder = character(),
      Importance = character(),
      Trend = character(),
      stringsAsFactors = FALSE
    )
  }
}

#' Convert Responses to ISA Format
#'
#' Special converter for responses (different structure - no ID column)
#'
#' @param elements List of AI ISA elements
#'
#' @return Dataframe in ISA responses format
convert_responses_to_isa <- function(elements) {
  if (length(elements$responses) > 0) {
    data.frame(
      Name = sapply(elements$responses, function(x) x$name),
      Description = sapply(elements$responses, function(x) x$description %||% ""),
      Indicator = "",
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(
      Name = character(),
      Description = character(),
      Indicator = character(),
      stringsAsFactors = FALSE
    )
  }
}

# ============================================================================
# ADJACENCY MATRIX BUILDING
# ============================================================================

#' Build Adjacency Matrices from Approved Connections
#'
#' Creates DAPSI(W)R(M) adjacency matrices from AI-generated connections
#' Uses forward causal flow format (SOURCE×TARGET)
#'
#' @param elements List of AI ISA elements
#' @param suggested_connections List of all suggested connections
#' @param approved_connections Vector of approved connection indices
#' @param CONFIDENCE_DEFAULT Default confidence value
#'
#' @return List of adjacency matrices
build_adjacency_matrices <- function(elements, suggested_connections,
                                     approved_connections, CONFIDENCE_DEFAULT = 70) {

  # Get dimensions
  n_drivers <- length(elements$drivers)
  n_activities <- length(elements$activities)
  n_pressures <- length(elements$pressures)
  n_states <- length(elements$states)
  n_impacts <- length(elements$impacts)
  n_welfare <- length(elements$welfare)
  n_responses <- length(elements$responses)

  cat(sprintf("[AI ISA] Building matrices: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R=%d\n",
             n_drivers, n_activities, n_pressures, n_states, n_impacts, n_welfare, n_responses))

  # Initialize matrices with forward causal flow
  matrices <- list(
    d_a = NULL,
    a_p = NULL,
    p_mpf = NULL,
    mpf_es = NULL,
    es_gb = NULL,
    gb_d = NULL,
    gb_r = NULL,
    r_d = NULL,
    r_a = NULL,
    r_p = NULL
  )

  # 1. Drivers → Activities (D→A)
  if (n_drivers > 0 && n_activities > 0) {
    matrices$d_a <- matrix(
      "", nrow = n_drivers, ncol = n_activities,
      dimnames = list(
        sapply(elements$drivers, function(x) x$name),
        sapply(elements$activities, function(x) x$name)
      )
    )
  }

  # 2. Activities → Pressures (A→P)
  if (n_activities > 0 && n_pressures > 0) {
    matrices$a_p <- matrix(
      "", nrow = n_activities, ncol = n_pressures,
      dimnames = list(
        sapply(elements$activities, function(x) x$name),
        sapply(elements$pressures, function(x) x$name)
      )
    )
  }

  # 3. Pressures → Marine Processes (P→MPF)
  if (n_pressures > 0 && n_states > 0) {
    matrices$p_mpf <- matrix(
      "", nrow = n_pressures, ncol = n_states,
      dimnames = list(
        sapply(elements$pressures, function(x) x$name),
        sapply(elements$states, function(x) x$name)
      )
    )
  }

  # 4. Marine Processes → Ecosystem Services (MPF→ES)
  if (n_states > 0 && n_impacts > 0) {
    matrices$mpf_es <- matrix(
      "", nrow = n_states, ncol = n_impacts,
      dimnames = list(
        sapply(elements$states, function(x) x$name),
        sapply(elements$impacts, function(x) x$name)
      )
    )
  }

  # 5. Ecosystem Services → Goods/Benefits (ES→GB)
  if (n_impacts > 0 && n_welfare > 0) {
    matrices$es_gb <- matrix(
      "", nrow = n_impacts, ncol = n_welfare,
      dimnames = list(
        sapply(elements$impacts, function(x) x$name),
        sapply(elements$welfare, function(x) x$name)
      )
    )
  }

  # 6. Goods/Benefits → Drivers feedback (GB→D)
  if (n_welfare > 0 && n_drivers > 0) {
    matrices$gb_d <- matrix(
      "", nrow = n_welfare, ncol = n_drivers,
      dimnames = list(
        sapply(elements$welfare, function(x) x$name),
        sapply(elements$drivers, function(x) x$name)
      )
    )
  }

  # 7. Goods/Benefits → Responses (GB→R)
  if (n_welfare > 0 && n_responses > 0) {
    matrices$gb_r <- matrix(
      "", nrow = n_welfare, ncol = n_responses,
      dimnames = list(
        sapply(elements$welfare, function(x) x$name),
        sapply(elements$responses, function(x) x$name)
      )
    )
  }

  # 8. Responses → Drivers (R→D management)
  if (n_responses > 0 && n_drivers > 0) {
    matrices$r_d <- matrix(
      "", nrow = n_responses, ncol = n_drivers,
      dimnames = list(
        sapply(elements$responses, function(x) x$name),
        sapply(elements$drivers, function(x) x$name)
      )
    )
  }

  # 9. Responses → Activities (R→A management)
  if (n_responses > 0 && n_activities > 0) {
    matrices$r_a <- matrix(
      "", nrow = n_responses, ncol = n_activities,
      dimnames = list(
        sapply(elements$responses, function(x) x$name),
        sapply(elements$activities, function(x) x$name)
      )
    )
  }

  # 10. Responses → Pressures (R→P management)
  if (n_responses > 0 && n_pressures > 0) {
    matrices$r_p <- matrix(
      "", nrow = n_responses, ncol = n_pressures,
      dimnames = list(
        sapply(elements$responses, function(x) x$name),
        sapply(elements$pressures, function(x) x$name)
      )
    )
  }

  # Fill matrices with approved connections
  cat(sprintf("[AI ISA] Processing %d approved connections...\n", length(approved_connections)))

  for (conn_idx in approved_connections) {
    conn <- suggested_connections[[conn_idx]]

    # Format: "+strength:confidence"
    confidence <- conn$confidence %||% CONFIDENCE_DEFAULT
    value <- paste0(conn$polarity, conn$strength, ":", confidence)

    # Determine which matrix and fill it
    if (conn$matrix == "d_a" && !is.null(matrices$d_a)) {
      matrices$d_a[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "a_p" && !is.null(matrices$a_p)) {
      matrices$a_p[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "p_mpf" && !is.null(matrices$p_mpf)) {
      matrices$p_mpf[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "mpf_es" && !is.null(matrices$mpf_es)) {
      matrices$mpf_es[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "es_gb" && !is.null(matrices$es_gb)) {
      matrices$es_gb[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "gb_d" && !is.null(matrices$gb_d)) {
      matrices$gb_d[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "gb_r" && !is.null(matrices$gb_r)) {
      matrices$gb_r[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "r_d" && !is.null(matrices$r_d)) {
      matrices$r_d[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "r_a" && !is.null(matrices$r_a)) {
      matrices$r_a[conn$from_index, conn$to_index] <- value
    } else if (conn$matrix == "r_p" && !is.null(matrices$r_p)) {
      matrices$r_p[conn$from_index, conn$to_index] <- value
    }
  }

  cat("[AI ISA] Adjacency matrices built successfully\n")
  return(matrices)
}

#' Save AI ISA Data to Project Format
#'
#' Converts AI ISA session data to project ISA format and saves it
#' Handles both new data and Excel import data preservation
#'
#' @param rv Reactive values containing AI ISA data
#' @param current_data Current project data structure
#' @param CONFIDENCE_DEFAULT Default confidence value for connections
#'
#' @return Updated project data structure
save_to_project_format <- function(rv, current_data, CONFIDENCE_DEFAULT = 70) {

  # Initialize data structure if needed
  if (is.null(current_data) || length(current_data) == 0) {
    current_data <- list(data = list(isa_data = list()), last_modified = Sys.time())
  }
  if (is.null(current_data$data)) {
    current_data$data <- list(isa_data = list())
  }
  if (is.null(current_data$data$isa_data)) {
    current_data$data$isa_data <- list()
  }

  # Convert all elements to ISA format
  current_data$data$isa_data$drivers <- convert_to_isa_dataframe(
    rv$elements, "drivers", "D", "Driver"
  )

  current_data$data$isa_data$activities <- convert_to_isa_dataframe(
    rv$elements, "activities", "A", "Activity"
  )

  current_data$data$isa_data$pressures <- convert_to_isa_dataframe(
    rv$elements, "pressures", "P", "Pressure"
  )

  current_data$data$isa_data$marine_processes <- convert_to_isa_dataframe(
    rv$elements, "states", "S", "Marine Process/State"
  )

  current_data$data$isa_data$ecosystem_services <- convert_to_isa_dataframe(
    rv$elements, "impacts", "I", "Ecosystem Service/Impact"
  )

  current_data$data$isa_data$goods_benefits <- convert_to_isa_dataframe(
    rv$elements, "welfare", "W", "Good/Benefit/Welfare"
  )

  current_data$data$isa_data$responses <- convert_responses_to_isa(rv$elements)

  # Save connections metadata (for AI ISA Assistant recovery)
  current_data$data$isa_data$connections <- list(
    suggested = rv$suggested_connections,
    approved = rv$approved_connections
  )

  # Determine data source
  data_source <- if (!is.null(current_data$data$metadata$data_source)) {
    current_data$data$metadata$data_source
  } else {
    "ai_assistant"
  }

  # Build adjacency matrices
  if (data_source == "excel_import") {
    cat("[AI ISA] Data from Excel import - preserving existing matrices\n")
    # Ensure structure exists but don't overwrite
    if (is.null(current_data$data$isa_data$adjacency_matrices)) {
      current_data$data$isa_data$adjacency_matrices <- list()
    }
  } else {
    # Build matrices from approved connections
    current_data$data$isa_data$adjacency_matrices <- build_adjacency_matrices(
      rv$elements,
      rv$suggested_connections,
      rv$approved_connections,
      CONFIDENCE_DEFAULT
    )
  }

  # Update last modified timestamp
  current_data$last_modified <- Sys.time()

  return(current_data)
}
