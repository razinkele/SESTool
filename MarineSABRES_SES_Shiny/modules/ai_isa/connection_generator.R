# modules/ai_isa/connection_generator.R
# AI ISA Connection Generator Module
# Purpose: AI/ML algorithms for intelligent connection suggestions
#
# This module contains pure functions for generating, filtering, and ranking
# connections between DAPSI(W)R(M) framework elements. It uses keyword-based
# semantic matching and polarity detection to suggest relevant ecological
# relationships.
#
# Author: Refactored from ai_isa_assistant_module.R
# Date: 2026-01-04
# Dependencies: Base R only (no Shiny, no reactivity)

# ==============================================================================
# POLARITY DETECTION
# ==============================================================================

#' Detect Connection Polarity
#'
#' Determines whether a connection between two elements is positive (+) or
#' negative (-) based on keyword analysis and DAPSI(W)R(M) framework rules.
#'
#' @param from_name Character string of source element name
#' @param to_name Character string of target element name
#' @param from_type Character string of source element type
#'   (drivers, activities, pressures, states, impacts, welfare, responses)
#' @param to_type Character string of target element type
#'
#' @return Character: "+" (positive/increasing) or "-" (negative/decreasing)
#'
#' @details
#' Polarity detection uses:
#' - Keyword matching for negative impacts (decline, degradation, loss)
#' - Keyword matching for positive changes (increase, recovery, improvement)
#' - Framework-specific rules (e.g., Responses → Pressures is typically "-")
#'
#' @examples
#' \dontrun{
#' detect_polarity("Fishing", "Fish_Stocks", "activities", "states")
#' # Returns: "-" (fishing decreases fish stocks)
#'
#' detect_polarity("Protection", "Biodiversity", "responses", "states")
#' # Returns: "+" (protection increases biodiversity)
#' }
#'
#' @export
detect_polarity <- function(from_name, to_name, from_type, to_type) {
  # Keywords that suggest negative impacts/changes
  negative_keywords <- c(
    "declin", "degrad", "loss", "reduc", "damag", "destruct", "pollut",
    "eutrophic", "overfish", "bycatch", "invasive", "extinct", "harm",
    "contaminat", "erosion", "acidific", "hypox", "dead zone", "bleach",
    "disease", "mortality", "collapse", "fragment", "depletion"
  )

  # Keywords that suggest positive changes
  positive_keywords <- c(
    "increas", "growth", "restor", "recover", "improv", "enhanc", "protect",
    "conserv", "benefit", "health", "sustain", "resilient", "biodiver",
    "abundance", "productiv", "regenerat", "rehabilit", "rebui"
  )

  # Keywords for mitigation/reduction actions
  mitigation_keywords <- c(
    "ban", "prohibit", "restrict", "limit", "regulat", "control", "manag",
    "reduce", "prevent", "mitigat", "protect", "enforce", "monitor",
    "stop", "remov", "clean", "treat"
  )

  from_lower <- tolower(from_name)
  to_lower <- tolower(to_name)

  # Check characteristics of target element
  to_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, to_lower)))
  to_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, to_lower)))

  # Check if source is a mitigation action
  from_is_mitigation <- any(sapply(mitigation_keywords, function(kw) grepl(kw, from_lower)))

  # Special case: Response Measures → Pressures
  if (from_type == "responses" && to_type == "pressures") {
    # Response measures typically reduce pressures
    return("-")
  }

  # Special case: Response Measures → States
  if (from_type == "responses" && to_type == "states") {
    # If state is negative (decline, loss), response reduces it → "-"
    # If state is positive (recovery, increase), response increases it → "+"
    if (to_is_negative) {
      return("-")  # Reduces bad state
    } else if (to_is_positive) {
      return("+")  # Increases good state
    }
    return("+")  # Default: responses improve states
  }

  # Activities → Pressures
  if (from_type == "activities" && to_type == "pressures") {
    # Activities generally cause pressures
    return("+")
  }

  # Pressures → States
  if (from_type == "pressures" && to_type == "states") {
    # If state is negative (fish stock decline), pressure increases it → "+"
    # If state is positive (fish stock recovery), pressure reduces it → "-"
    if (to_is_negative) {
      return("+")  # Pressure increases negative state
    } else if (to_is_positive) {
      return("-")  # Pressure decreases positive state
    }
    return("-")  # Default: pressures degrade states
  }

  # States → Impacts
  if (from_type == "states" && to_type == "impacts") {
    # If state is negative and impact is negative → "+" (bad state causes bad impact)
    # If state is positive and impact is positive → "+" (good state causes good impact)
    from_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, from_lower)))
    from_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, from_lower)))

    if ((from_is_negative && to_is_negative) || (from_is_positive && to_is_positive)) {
      return("+")
    } else if ((from_is_negative && to_is_positive) || (from_is_positive && to_is_negative)) {
      return("-")
    }
    return("-")  # Default: degraded states reduce services
  }

  # Impacts → Welfare
  if (from_type == "impacts" && to_type == "welfare") {
    # Negative impacts reduce welfare → "-"
    # Positive impacts increase welfare → "+"
    from_is_negative <- any(sapply(negative_keywords, function(kw) grepl(kw, from_lower)))
    from_is_positive <- any(sapply(positive_keywords, function(kw) grepl(kw, from_lower)))

    if (from_is_negative) {
      return("-")
    } else if (from_is_positive) {
      return("+")
    }
    return("-")  # Default: impacts reduce welfare
  }

  # Default fallback
  return("+")
}

# ==============================================================================
# RELEVANCE CALCULATION
# ==============================================================================

#' Calculate Semantic Relevance Between Elements
#'
#' Calculates a relevance score (0-1) between two elements based on keyword
#' matching and connection type. Higher scores indicate stronger semantic
#' relationships.
#'
#' @param from_name Character string of source element name
#' @param to_name Character string of target element name
#' @param from_type Character string of source element type
#' @param to_type Character string of target element type
#'
#' @return Numeric relevance score between 0 and 1
#'   - 0.9: High relevance (2+ keyword matches)
#'   - 0.6: Moderate relevance (1 keyword match)
#'   - 0.3: Low relevance (no keyword matches)
#'   - 0.5: Default for unknown connection types
#'
#' @details
#' Uses connection-type-specific keyword lists to identify semantically
#' related elements. For example, "fishing" and "fish stock decline" would
#' score high for an activities→pressures connection.
#'
#' @examples
#' \dontrun{
#' calculate_relevance("Commercial Fishing", "Overfishing", "activities", "pressures")
#' # Returns: 0.9 (high relevance - multiple keyword matches)
#'
#' calculate_relevance("Tourism", "Fish Decline", "activities", "pressures")
#' # Returns: 0.3 (low relevance - no keyword matches)
#' }
#'
#' @export
calculate_relevance <- function(from_name, to_name, from_type, to_type) {
  # Normalize names to lowercase for comparison
  from_lower <- tolower(from_name)
  to_lower <- tolower(to_name)

  # Keywords that suggest strong relationships
  connection_keywords <- list(
    drivers_activities = c("fish", "food", "econom", "livelihood", "subsistence", "commerc", "industr", "recreat", "tourism", "develop", "demand", "need", "cultural", "spiritual"),
    activities_pressures = c("fish", "extract", "harvest", "develop", "construct", "pollut", "discharge", "emission", "waste", "noise", "disturb", "remov", "introduc", "invasive"),
    pressures_states = c("pollut", "nutrient", "contamin", "extract", "remov", "habitat", "species", "abundance", "diversity", "structure", "function", "ecosystem", "chemical", "physical", "biological"),
    states_impacts = c("decline", "loss", "degrad", "change", "abundance", "diversity", "habitat", "ecosystem", "service", "provision", "regulat", "cultural", "support"),
    impacts_welfare = c("food", "protein", "nutrition", "income", "livelihood", "employ", "health", "wellbeing", "recreation", "cultural", "spiritual", "aesthetic", "economic", "social"),
    responses_pressures = c("regulat", "protect", "conserv", "restor", "manag", "monitor", "enforc", "limit", "restrict", "ban", "quota", "closure", "zone", "designation"),
    welfare_responses = c("concern", "awareness", "demand", "advocacy", "pressure", "policy", "legislation", "management", "action", "intervention"),
    responses_drivers = c("policy", "awareness", "education", "incentiv", "subsid", "tax", "regulation", "enforcement", "behavior", "demand"),
    responses_activities = c("limit", "restrict", "ban", "regulat", "control", "manage", "permit", "license", "quota", "closure", "zone")
  )

  # Get relevant keywords for this connection type
  key <- paste(from_type, to_type, sep = "_")
  keywords <- connection_keywords[[key]]

  if (is.null(keywords)) return(0.5)  # Default moderate relevance

  # Count keyword matches
  from_matches <- sum(sapply(keywords, function(kw) grepl(kw, from_lower)))
  to_matches <- sum(sapply(keywords, function(kw) grepl(kw, to_lower)))

  # Calculate relevance score (0-1)
  total_matches <- from_matches + to_matches
  if (total_matches == 0) return(0.3)  # Low relevance
  if (total_matches == 1) return(0.6)  # Moderate relevance
  return(0.9)  # High relevance
}

# ==============================================================================
# SMART CONNECTION GENERATION
# ==============================================================================

#' Generate Smart Connections Between Element Sets
#'
#' Generates filtered and ranked connections between two sets of elements
#' using relevance scoring and polarity detection.
#'
#' @param from_elements List of source elements (each with $name attribute)
#' @param to_elements List of target elements (each with $name attribute)
#' @param from_type Character string of source element type
#' @param to_type Character string of target element type
#' @param matrix_name Character string identifying the connection matrix
#' @param max_count Integer maximum number of connections to return
#' @param min_relevance Numeric minimum relevance threshold (0-1)
#'
#' @return List of connection objects, sorted by relevance (highest first)
#'
#' @details
#' Each connection object contains:
#' - from_type, from_index, from_name
#' - to_type, to_index, to_name
#' - polarity ("+"/"-")
#' - strength ("medium" default)
#' - confidence (3 default)
#' - rationale (human-readable description)
#' - matrix (connection matrix identifier)
#'
#' The function filters out low-relevance connections and returns only the
#' top-ranked suggestions up to max_count.
#'
#' @examples
#' \dontrun{
#' drivers <- list(list(name = "Economic Growth"), list(name = "Population Growth"))
#' activities <- list(list(name = "Commercial Fishing"), list(name = "Tourism"))
#' connections <- generate_smart_connections(
#'   drivers, activities, "drivers", "activities", "d_a", max_count = 15, min_relevance = 0.3
#' )
#' }
#'
#' @export
generate_smart_connections <- function(from_elements, to_elements, from_type, to_type, matrix_name, max_count, min_relevance) {
  candidates <- list()

  for (i in seq_along(from_elements)) {
    for (j in seq_along(to_elements)) {
      relevance <- calculate_relevance(from_elements[[i]]$name, to_elements[[j]]$name, from_type, to_type)
      if (relevance >= min_relevance) {
        polarity <- detect_polarity(from_elements[[i]]$name, to_elements[[j]]$name, from_type, to_type)

        # Choose appropriate verb based on connection type
        verb <- if (from_type == "drivers") {
          "drives"
        } else if (from_type == "activities") {
          if (polarity == "+") "increases" else "causes"
        } else if (from_type == "pressures") {
          if (polarity == "+") "increases" else "decreases"
        } else if (from_type == "states") {
          "impacts"
        } else if (from_type == "impacts") {
          if (polarity == "+") "increases" else "reduces"
        } else if (from_type == "responses") {
          if (polarity == "-") "restricts" else "enables"
        } else if (from_type == "welfare") {
          if (polarity == "+") "motivates" else "reduces"
        } else {
          if (polarity == "+") "affects positively" else "affects negatively"
        }

        candidates[[length(candidates) + 1]] <- list(
          conn = list(
            from_type = from_type,
            from_index = i,
            from_name = from_elements[[i]]$name,
            to_type = to_type,
            to_index = j,
            to_name = to_elements[[j]]$name,
            polarity = polarity,
            strength = "medium",
            confidence = 3,
            rationale = paste(from_elements[[i]]$name, verb, to_elements[[j]]$name),
            matrix = matrix_name
          ),
          relevance = relevance
        )
      }
    }
  }

  # Sort by relevance and return top connections
  if (length(candidates) > 0) {
    candidates <- candidates[order(sapply(candidates, function(x) x$relevance), decreasing = TRUE)]
    n_to_return <- min(length(candidates), max_count)
    result <- lapply(1:n_to_return, function(i) candidates[[i]]$conn)
    cat(sprintf("[AI ISA CONNECTIONS] Generated %d %s→%s connections (from %d candidates, %.0f%% filtered)\n",
                n_to_return, toupper(substring(from_type, 1, 1)), toupper(substring(to_type, 1, 1)),
                length(candidates), (1 - n_to_return/length(candidates)) * 100))
    return(result)
  }

  cat(sprintf("[AI ISA CONNECTIONS] No relevant %s→%s connections found\n", from_type, to_type))
  return(list())
}

# ==============================================================================
# ADJACENCY MATRIX CONVERSION
# ==============================================================================

#' Convert Adjacency Matrices to Connection List
#'
#' Converts adjacency matrix representation to a list of connection objects.
#' Used when loading connections from saved ISA data format.
#'
#' @param matrices List of adjacency matrices (named by matrix type)
#' @param elements List of element collections (drivers, activities, etc.)
#'
#' @return List of connection objects parsed from matrix cells
#'
#' @details
#' Matrix cell format: "+strong:5" or "-medium:3"
#' - First character: polarity (+/-)
#' - Middle part: strength (weak/medium/strong)
#' - After colon: confidence level (1-5)
#'
#' Supported matrices:
#' - d_a: Drivers → Activities
#' - a_p: Activities → Pressures
#' - p_mpf: Pressures → States
#' - mpf_es: States → Impacts
#' - es_gb: Impacts → Welfare
#' - gb_d: Welfare → Drivers
#' - gb_r: Welfare → Responses
#' - r_d: Responses → Drivers
#' - r_a: Responses → Activities
#' - r_p: Responses → Pressures
#'
#' @examples
#' \dontrun{
#' # Matrix with format: "+strong:5"
#' matrices <- list(d_a = matrix(c("+medium:4", "", "", "-weak:2"), nrow = 2))
#' elements <- list(
#'   drivers = list(list(name = "Growth"), list(name = "Policy")),
#'   activities = list(list(name = "Fishing"), list(name = "Tourism"))
#' )
#' connections <- convert_matrices_to_connections(matrices, elements)
#' }
#'
#' @export
convert_matrices_to_connections <- function(matrices, elements) {
  connections <- list()

  # Matrix mapping: matrix_name -> list(from_type, to_type, from_list, to_list)
  matrix_map <- list(
    d_a = list(from_type = "drivers", to_type = "activities", from = elements$drivers, to = elements$activities),
    a_p = list(from_type = "activities", to_type = "pressures", from = elements$activities, to = elements$pressures),
    p_mpf = list(from_type = "pressures", to_type = "states", from = elements$pressures, to = elements$states),
    mpf_es = list(from_type = "states", to_type = "impacts", from = elements$states, to = elements$impacts),
    es_gb = list(from_type = "impacts", to_type = "welfare", from = elements$impacts, to = elements$welfare),
    gb_d = list(from_type = "welfare", to_type = "drivers", from = elements$welfare, to = elements$drivers),
    gb_r = list(from_type = "welfare", to_type = "responses", from = elements$welfare, to = elements$responses),
    r_d = list(from_type = "responses", to_type = "drivers", from = elements$responses, to = elements$drivers),
    r_a = list(from_type = "responses", to_type = "activities", from = elements$responses, to = elements$activities),
    r_p = list(from_type = "responses", to_type = "pressures", from = elements$responses, to = elements$pressures)
  )

  for (matrix_name in names(matrices)) {
    # Skip if not in our map
    if (!matrix_name %in% names(matrix_map)) next

    mat <- matrices[[matrix_name]]
    map_info <- matrix_map[[matrix_name]]

    # Skip if elements lists are empty
    if (is.null(map_info$from) || is.null(map_info$to) ||
        length(map_info$from) == 0 || length(map_info$to) == 0) next

    # Loop through matrix cells
    for (i in 1:nrow(mat)) {
      for (j in 1:ncol(mat)) {
        value <- mat[i, j]
        # Skip empty cells
        if (is.null(value) || is.na(value) || value == "" || trimws(value) == "") next

        # Parse value (format: "+strong:5" or "-medium:3")
        polarity <- "+"
        strength <- "medium"
        confidence <- 3

        if (grepl("^[+-]", value)) {
          polarity <- substr(value, 1, 1)
          rest <- substr(value, 2, nchar(value))

          # Extract strength and confidence
          if (grepl(":", rest)) {
            parts <- strsplit(rest, ":")[[1]]
            strength <- parts[1]
            if (length(parts) > 1) {
              confidence <- as.integer(parts[2])
            }
          } else {
            strength <- rest
          }
        }

        # Create connection object
        connections[[length(connections) + 1]] <- list(
          from_type = map_info$from_type,
          from_index = i,
          from_name = map_info$from[[i]]$name,
          to_type = map_info$to_type,
          to_index = j,
          to_name = map_info$to[[j]]$name,
          polarity = polarity,
          strength = strength,
          confidence = confidence,
          rationale = paste(map_info$from[[i]]$name,
                          if(polarity == "+") "increases" else "decreases",
                          map_info$to[[j]]$name),
          matrix = matrix_name
        )
      }
    }
  }

  cat(sprintf("[AI ISA] Converted %d connections from %d matrices\n",
              length(connections), length(matrices)))
  return(connections)
}

# ==============================================================================
# MAIN CONNECTION GENERATION ORCHESTRATOR
# ==============================================================================

#' Generate All Connections for DAPSI(W)R(M) Framework
#'
#' Main orchestrator function that generates all logical connections between
#' element types based on the DAPSI(W)R(M) framework structure.
#'
#' @param elements List containing all 7 element types:
#'   - drivers: Economic/social drivers
#'   - activities: Human activities
#'   - pressures: Environmental pressures
#'   - states: Ecosystem state changes
#'   - impacts: Impacts on ecosystem services
#'   - welfare: Human welfare impacts
#'   - responses: Management responses
#'
#' @return List of all generated connection objects
#'
#' @details
#' Generates connections for 10 connection types:
#' - Forward chain: D→A→P→S→I→W
#' - Response interventions: R→P, R→D, R→A
#' - Feedback loops: W→D, W→R
#'
#' Default limits:
#' - MAX_PER_TYPE: 15 connections per type (max 150 total)
#' - MIN_RELEVANCE: 0.3 (30% relevance threshold)
#'
#' @examples
#' \dontrun{
#' elements <- list(
#'   drivers = list(list(name = "Economic Growth")),
#'   activities = list(list(name = "Fishing")),
#'   pressures = list(list(name = "Overfishing")),
#'   states = list(list(name = "Fish Stock Decline")),
#'   impacts = list(list(name = "Reduced Fish Provisioning")),
#'   welfare = list(list(name = "Food Security Loss")),
#'   responses = list(list(name = "Fishing Quotas"))
#' )
#' connections <- generate_connections(elements)
#' }
#'
#' @export
generate_connections <- function(elements) {
  connections <- list()
  MAX_PER_TYPE <- 15  # Reduced limit for better quality (10 types × 15 = max 150 total)
  MIN_RELEVANCE <- 0.3  # Lower threshold to ensure core DAPSIWR connections are generated

  # Per-type counters
  count_da <- 0  # Drivers → Activities
  count_ap <- 0  # Activities → Pressures
  count_ps <- 0  # Pressures → States
  count_si <- 0  # States → Impacts
  count_iw <- 0  # Impacts → Welfare
  count_rp <- 0  # Responses → Pressures
  count_wd <- 0  # Welfare → Drivers (feedback)
  count_wr <- 0  # Welfare → Responses (feedback)
  count_rd <- 0  # Responses → Drivers (feedback)
  count_ra <- 0  # Responses → Activities (feedback)

  cat(sprintf("[AI ISA CONNECTIONS] Generating connections (max %d per type)...\n", MAX_PER_TYPE))
  cat(sprintf("[AI ISA CONNECTIONS] Element counts: D=%d, A=%d, P=%d, S=%d, I=%d, W=%d, R=%d\n",
              length(elements$drivers %||% list()),
              length(elements$activities %||% list()),
              length(elements$pressures %||% list()),
              length(elements$states %||% list()),
              length(elements$impacts %||% list()),
              length(elements$welfare %||% list()),
              length(elements$responses %||% list())))

  # Debug: Print actual element names
  if (length(elements$drivers) > 0) {
    cat(sprintf("[AI ISA CONNECTIONS] Drivers: %s\n", paste(sapply(elements$drivers, function(x) x$name), collapse=", ")))
  }
  if (length(elements$activities) > 0) {
    cat(sprintf("[AI ISA CONNECTIONS] Activities: %s\n", paste(sapply(elements$activities, function(x) x$name), collapse=", ")))
  }

  # D → A (Drivers → Activities): Smart connection generation
  if (length(elements$drivers) > 0 && length(elements$activities) > 0) {
    new_conns <- generate_smart_connections(elements$drivers, elements$activities, "drivers", "activities", "d_a", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_da <- length(new_conns)
  }

  # A → P (Activities → Pressures): Smart connection generation
  if (length(elements$activities) > 0 && length(elements$pressures) > 0) {
    new_conns <- generate_smart_connections(elements$activities, elements$pressures, "activities", "pressures", "a_p", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_ap <- length(new_conns)
  }

  # P → S (Pressures → States): Smart connection generation
  if (length(elements$pressures) > 0 && length(elements$states) > 0) {
    new_conns <- generate_smart_connections(elements$pressures, elements$states, "pressures", "states", "p_mpf", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_ps <- length(new_conns)
  }

  # S → I (States → Impacts): Smart connection generation
  if (length(elements$states) > 0 && length(elements$impacts) > 0) {
    new_conns <- generate_smart_connections(elements$states, elements$impacts, "states", "impacts", "mpf_es", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_si <- length(new_conns)
  }

  # I → W (Impacts → Welfare): Smart connection generation
  if (length(elements$impacts) > 0 && length(elements$welfare) > 0) {
    new_conns <- generate_smart_connections(elements$impacts, elements$welfare, "impacts", "welfare", "es_gb", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_iw <- length(new_conns)
  }

  # R → P (Responses → Pressures): Smart connection generation
  if (length(elements$responses) > 0 && length(elements$pressures) > 0) {
    new_conns <- generate_smart_connections(elements$responses, elements$pressures, "responses", "pressures", "r_p", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_rp <- length(new_conns)
  }

  # ========================================================================
  # FEEDBACK LOOPS - Additional logical connections
  # ========================================================================

  # W → D (Welfare → Drivers): Smart feedback loop generation
  if (length(elements$welfare) > 0 && length(elements$drivers) > 0) {
    new_conns <- generate_smart_connections(elements$welfare, elements$drivers, "welfare", "drivers", "gb_d", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_wd <- length(new_conns)
  }

  # W → R (Welfare → Responses): Smart feedback loop generation
  if (length(elements$welfare) > 0 && length(elements$responses) > 0) {
    new_conns <- generate_smart_connections(elements$welfare, elements$responses, "welfare", "responses", "gb_r", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_wr <- length(new_conns)
  }

  # R → D (Responses → Drivers): Smart feedback loop generation
  if (length(elements$responses) > 0 && length(elements$drivers) > 0) {
    new_conns <- generate_smart_connections(elements$responses, elements$drivers, "responses", "drivers", "r_d", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_rd <- length(new_conns)
  }

  # R → A (Responses → Activities): Smart feedback loop generation
  if (length(elements$responses) > 0 && length(elements$activities) > 0) {
    new_conns <- generate_smart_connections(elements$responses, elements$activities, "responses", "activities", "r_a", MAX_PER_TYPE, MIN_RELEVANCE)
    connections <- c(connections, new_conns)
    count_ra <- length(new_conns)
  }

  # Log final count and per-type breakdown
  cat(sprintf("[AI ISA CONNECTIONS] ========================================\n"))
  cat(sprintf("[AI ISA CONNECTIONS] TOTAL GENERATED: %d connections\n", length(connections)))
  cat(sprintf("[AI ISA CONNECTIONS] Per-type breakdown:\n"))
  cat(sprintf("[AI ISA CONNECTIONS]   D→A: %d  A→P: %d  P→S: %d\n", count_da, count_ap, count_ps))
  cat(sprintf("[AI ISA CONNECTIONS]   S→I: %d  I→W: %d  R→P: %d\n", count_si, count_iw, count_rp))
  cat(sprintf("[AI ISA CONNECTIONS]   W→D: %d  W→R: %d  R→D: %d  R→A: %d\n", count_wd, count_wr, count_rd, count_ra))
  cat(sprintf("[AI ISA CONNECTIONS] ========================================\n"))

  return(connections)
}

# ==============================================================================
# MODULE INITIALIZATION MESSAGE
# ==============================================================================

message("[INFO] AI ISA Connection Generator module loaded successfully")
message("       Available functions: detect_polarity, calculate_relevance,")
message("       generate_smart_connections, convert_matrices_to_connections,")
message("       generate_connections")
