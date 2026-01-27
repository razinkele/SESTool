# functions/dapsiwrm_connection_rules.R
# DAPSIWRM adjacency rules and connection inference
# Defines which types can connect to which, and how to infer connection properties

#' DAPSIWRM Adjacency Rules
#'
#' Defines allowed connections between DAPSIWRM types following the framework logic:
#' Drivers → Activities → Pressures → Marine Processes & Functioning →
#' Ecosystem Services → Goods & Benefits → (Drivers/Responses)
#' Responses → (Drivers/Activities/Pressures/Marine Processes & Functioning)
#'
#' @format List of allowed connections with polarity and examples
#' @export
DAPSIWRM_ADJACENCY_RULES <- list(

  # ============================================================================
  # DRIVERS (D) → ACTIVITIES (A)
  # ============================================================================
  Drivers = list(
    targets = c("Activities"),
    default_polarity = "+",
    allowed_polarities = c("+", "-"),

    description = "Drivers create demand for activities",

    examples = list(
      list(
        from = "Food security need",
        to = "Commercial fishing",
        polarity = "+",
        strength = "strong",
        reasoning = "Food demand drives fishing activity"
      ),
      list(
        from = "Economic growth",
        to = "Coastal development",
        polarity = "+",
        strength = "strong",
        reasoning = "Economic growth drives development"
      ),
      list(
        from = "Tourism demand",
        to = "Recreational boating",
        polarity = "+",
        strength = "medium",
        reasoning = "Tourism creates demand for recreation"
      )
    )
  ),

  # ============================================================================
  # ACTIVITIES (A) → PRESSURES (P)
  # ============================================================================
  Activities = list(
    targets = c("Pressures"),
    default_polarity = "+",
    allowed_polarities = c("+", "-"),

    description = "Activities generate pressures on the environment",

    examples = list(
      list(
        from = "Trawl fishing",
        to = "Seabed disturbance",
        polarity = "+",
        strength = "strong",
        reasoning = "Trawling directly disturbs seabed"
      ),
      list(
        from = "Aquaculture",
        to = "Nutrient enrichment",
        polarity = "+",
        strength = "medium",
        reasoning = "Fish farms release nutrients"
      ),
      list(
        from = "Agriculture",
        to = "Nutrient pollution",
        polarity = "+",
        strength = "strong",
        reasoning = "Fertilizer runoff causes nutrient pollution"
      ),
      list(
        from = "Wastewater treatment",
        to = "Nutrient pollution",
        polarity = "-",
        strength = "medium",
        reasoning = "Treatment reduces nutrient pollution"
      )
    )
  ),

  # ============================================================================
  # PRESSURES (P) → MARINE PROCESSES & FUNCTIONING (S)
  # ============================================================================
  Pressures = list(
    targets = c("Marine Processes & Functioning"),
    default_polarity = "-",
    allowed_polarities = c("-", "+"),

    description = "Pressures negatively affect marine state and processes",

    examples = list(
      list(
        from = "Nutrient enrichment",
        to = "Hypoxia",
        polarity = "+",
        strength = "strong",
        reasoning = "Nutrients cause oxygen depletion"
      ),
      list(
        from = "Overfishing",
        to = "Fish population decline",
        polarity = "+",
        strength = "strong",
        reasoning = "Overfishing reduces populations"
      ),
      list(
        from = "Seabed disturbance",
        to = "Habitat quality",
        polarity = "-",
        strength = "medium",
        reasoning = "Disturbance degrades habitat"
      ),
      list(
        from = "Marine litter",
        to = "Biodiversity",
        polarity = "-",
        strength = "medium",
        reasoning = "Litter harms marine life"
      )
    )
  ),

  # ============================================================================
  # MARINE PROCESSES & FUNCTIONING (S) → ECOSYSTEM SERVICES (I)
  # ============================================================================
  "Marine Processes & Functioning" = list(
    targets = c("Ecosystem Services"),
    default_polarity = "+",
    allowed_polarities = c("+", "-"),

    description = "Healthy ecosystem state provides services",

    examples = list(
      list(
        from = "Seagrass habitat",
        to = "Nursery function",
        polarity = "+",
        strength = "strong",
        reasoning = "Seagrass provides nursery habitat"
      ),
      list(
        from = "Fish population",
        to = "Fish provision",
        polarity = "+",
        strength = "strong",
        reasoning = "Populations provide fish"
      ),
      list(
        from = "Biodiversity",
        to = "Ecosystem resilience",
        polarity = "+",
        strength = "medium",
        reasoning = "Diversity enhances resilience"
      ),
      list(
        from = "Hypoxia",
        to = "Fish provision",
        polarity = "-",
        strength = "strong",
        reasoning = "Oxygen depletion reduces fish availability"
      )
    )
  ),

  # ============================================================================
  # ECOSYSTEM SERVICES (I) → GOODS & BENEFITS (W)
  # ============================================================================
  "Ecosystem Services" = list(
    targets = c("Goods & Benefits"),
    default_polarity = "+",
    allowed_polarities = c("+", "-"),

    description = "Services provide welfare benefits to humans",

    examples = list(
      list(
        from = "Fish provision",
        to = "Food security",
        polarity = "+",
        strength = "strong",
        reasoning = "Fish provision ensures food security"
      ),
      list(
        from = "Coastal protection",
        to = "Property protection",
        polarity = "+",
        strength = "strong",
        reasoning = "Natural barriers protect infrastructure"
      ),
      list(
        from = "Recreation",
        to = "Tourism revenue",
        polarity = "+",
        strength = "medium",
        reasoning = "Recreation attracts tourists"
      ),
      list(
        from = "Carbon sequestration",
        to = "Climate regulation benefit",
        polarity = "+",
        strength = "medium",
        reasoning = "Carbon storage mitigates climate change"
      )
    )
  ),

  # ============================================================================
  # GOODS & BENEFITS (W) → DRIVERS (D) / RESPONSES (R)
  # ============================================================================
  "Goods & Benefits" = list(
    targets = c("Drivers", "Responses"),
    default_polarity = "+",
    allowed_polarities = c("+", "-"),

    description = "Benefits can drive demand or trigger responses",

    examples = list(
      list(
        from = "Economic loss",
        to = "Policy demand",
        polarity = "+",
        strength = "medium",
        reasoning = "Losses create pressure for policy"
      ),
      list(
        from = "Income from fishing",
        to = "Fishing demand",
        polarity = "+",
        strength = "medium",
        reasoning = "Profitable fishing increases demand"
      ),
      list(
        from = "Health impacts",
        to = "Regulation demand",
        polarity = "+",
        strength = "strong",
        reasoning = "Health issues trigger regulation calls"
      )
    )
  ),

  # ============================================================================
  # RESPONSES (R) → Multiple targets
  # ============================================================================
  Responses = list(
    targets = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
    default_polarity = "-",
    allowed_polarities = c("-", "+"),

    description = "Responses manage or mitigate drivers, activities, and pressures, or enhance state",

    examples = list(
      list(
        from = "Fishing quota",
        to = "Commercial fishing",
        polarity = "-",
        strength = "strong",
        reasoning = "Quotas limit fishing activity"
      ),
      list(
        from = "Marine Protected Area",
        to = "Trawl fishing",
        polarity = "-",
        strength = "strong",
        reasoning = "MPAs restrict fishing"
      ),
      list(
        from = "Nutrient reduction policy",
        to = "Nutrient enrichment",
        polarity = "-",
        strength = "medium",
        reasoning = "Policy reduces nutrient input"
      ),
      list(
        from = "Habitat restoration",
        to = "Habitat quality",
        polarity = "+",
        strength = "medium",
        reasoning = "Restoration improves habitat"
      ),
      list(
        from = "Fishing ban",
        to = "Fishing demand",
        polarity = "-",
        strength = "strong",
        reasoning = "Ban reduces demand for fishing"
      )
    )
  )
)


#' Get Allowed Target Types for a DAPSIWRM Type
#'
#' @param source_type Source DAPSIWRM type
#' @return Character vector of allowed target types
#' @export
get_allowed_targets <- function(source_type) {
  if (!source_type %in% names(DAPSIWRM_ADJACENCY_RULES)) {
    log_warning("DAPSIWRM", paste("Unknown DAPSIWRM type:", source_type))
    return(character(0))
  }

  return(DAPSIWRM_ADJACENCY_RULES[[source_type]]$targets)
}


#' Infer Connection Polarity
#'
#' Determines the most likely polarity (+/-) for a connection between two elements
#'
#' @param from_name Source element name
#' @param to_name Target element name
#' @param from_type Source DAPSIWRM type
#' @param to_type Target DAPSIWRM type
#' @return Character: "+" or "-"
#' @export
infer_connection_polarity <- function(from_name, to_name, from_type, to_type) {

  # Get rule for this connection
  if (!from_type %in% names(DAPSIWRM_ADJACENCY_RULES)) {
    return("+")  # Default positive
  }

  rule <- DAPSIWRM_ADJACENCY_RULES[[from_type]]

  # Check if target type is allowed
  if (!to_type %in% rule$targets) {
    log_warning("DAPSIWRM", paste("Connection", from_type, "->", to_type, "not in standard DAPSIWRM framework"))
    return("+")
  }

  # Use default polarity
  default_pol <- rule$default_polarity

  # Check for negative keywords that might reverse polarity
  from_lower <- tolower(from_name)
  to_lower <- tolower(to_name)

  # Special cases for Activities → Pressures
  if (from_type == "Activities" && to_type == "Pressures") {
    # If activity is about treatment/reduction, polarity is negative
    if (grepl("treatment|reduction|control|mitigation|restoration", from_lower)) {
      return("-")
    }
    return("+")  # Most activities create pressures
  }

  # Special cases for Pressures → State
  if (from_type == "Pressures" && to_type == "Marine Processes & Functioning") {
    # Check if "to" is negative (decline, loss) or positive (quality, health)
    if (grepl("decline|loss|depletion|degradation|mortality", to_lower)) {
      return("+")  # Pressure increases decline
    } else if (grepl("quality|health|abundance|biodiversity|resilience", to_lower)) {
      return("-")  # Pressure decreases quality
    }
    return("-")  # Default: pressures harm state
  }

  # Special cases for Responses
  if (from_type == "Responses") {
    # Check target type
    if (to_type %in% c("Drivers", "Activities", "Pressures")) {
      return("-")  # Responses typically reduce these
    } else if (to_type == "Marine Processes & Functioning") {
      # Restoration increases state
      if (grepl("restoration|enhancement|improvement", from_lower)) {
        return("+")
      }
      return("-")  # Protection/regulation
    }
  }

  return(default_pol)
}


#' Infer Connection Strength
#'
#' Estimates connection strength based on element names and types
#'
#' @param from_name Source element name
#' @param to_name Target element name
#' @param context User's context (optional)
#' @return Character: "strong", "medium", or "weak"
#' @export
infer_connection_strength <- function(from_name, to_name, context = NULL) {

  from_lower <- tolower(from_name)
  to_lower <- tolower(to_name)

  # Check for word overlap (indicates direct relationship)
  from_words <- strsplit(from_lower, "[\\s,.-]+")[[1]]
  to_words <- strsplit(to_lower, "[\\s,.-]+")[[1]]

  # Remove common stopwords
  stopwords <- c("the", "a", "an", "of", "in", "on", "at", "to", "for", "and", "or")
  from_words <- setdiff(from_words, stopwords)
  to_words <- setdiff(to_words, stopwords)

  overlap_count <- length(intersect(from_words, to_words))

  # High overlap = strong connection
  if (overlap_count >= 2) {
    return("strong")
  } else if (overlap_count == 1) {
    return("medium")
  }

  # Check for strong relationship keywords
  strong_keywords <- c(
    "overfishing|fishing", "nutrient enrichment|nutrient", "pollution|contamination",
    "quota|fishing", "MPA|protection", "habitat|biodiversity"
  )

  for (pair in strong_keywords) {
    keywords <- strsplit(pair, "\\|")[[1]]
    if (grepl(keywords[1], from_lower) && grepl(keywords[2], to_lower)) {
      return("strong")
    }
  }

  # Default to medium
  return("medium")
}


#' Get Connection Confidence
#'
#' Estimates how confident we are about a suggested connection
#'
#' @param from_element Source element data (with type)
#' @param to_element Target element data (with type)
#' @param context User's context
#' @return Numeric confidence (1-5 scale)
#' @export
get_connection_confidence <- function(from_element, to_element, context = NULL) {

  confidence <- 3  # Default: medium confidence

  # Increase confidence if connection follows DAPSIWRM rules
  allowed_targets <- get_allowed_targets(from_element$type)
  if (to_element$type %in% allowed_targets) {
    confidence <- confidence + 1
  }

  # Increase confidence if names have keyword overlap
  strength <- infer_connection_strength(from_element$name, to_element$name, context)
  if (strength == "strong") {
    confidence <- confidence + 1
  }

  # Decrease confidence if types are unusual
  if (from_element$type == "Marine Processes & Functioning" && to_element$type == "Drivers") {
    confidence <- confidence - 1  # Unusual connection
  }

  # Cap at 1-5 range
  return(max(1, min(5, confidence)))
}


#' Validate Connection
#'
#' Checks if a proposed connection is valid according to DAPSIWRM rules
#'
#' @param from_type Source DAPSIWRM type
#' @param to_type Target DAPSIWRM type
#' @param strict If TRUE, only allow standard connections. If FALSE, allow all
#' @return TRUE if valid, FALSE otherwise
#' @export
validate_connection <- function(from_type, to_type, strict = FALSE) {

  if (!from_type %in% names(DAPSIWRM_ADJACENCY_RULES)) {
    return(!strict)  # Allow if not strict
  }

  rule <- DAPSIWRM_ADJACENCY_RULES[[from_type]]
  is_allowed <- to_type %in% rule$targets

  if (!is_allowed && !strict) {
    debug_log(paste("Non-standard connection:", from_type, "->", to_type), "CONNECTION")
    return(TRUE)  # Allow non-standard connections in permissive mode
  }

  return(is_allowed)
}


#' Get Connection Description
#'
#' Returns a human-readable description of what a connection means
#'
#' @param from_type Source DAPSIWRM type
#' @param to_type Target DAPSIWRM type
#' @return Character string describing the relationship
#' @export
get_connection_description <- function(from_type, to_type) {

  if (!from_type %in% names(DAPSIWRM_ADJACENCY_RULES)) {
    return("Related element")
  }

  rule <- DAPSIWRM_ADJACENCY_RULES[[from_type]]

  if (to_type %in% rule$targets) {
    return(rule$description)
  }

  # Generic description
  return(paste(from_type, "affects", to_type))
}


#' Get Connection Examples
#'
#' Returns example connections for a given type pair
#'
#' @param from_type Source DAPSIWRM type
#' @param to_type Target DAPSIWRM type
#' @return List of example connections
#' @export
get_connection_examples <- function(from_type, to_type) {

  if (!from_type %in% names(DAPSIWRM_ADJACENCY_RULES)) {
    return(list())
  }

  rule <- DAPSIWRM_ADJACENCY_RULES[[from_type]]

  if (!to_type %in% rule$targets) {
    return(list())
  }

  # Filter examples for this target type
  # (Examples in rule don't specify target type explicitly,
  #  but we can infer from the allowed targets)
  return(rule$examples)
}
