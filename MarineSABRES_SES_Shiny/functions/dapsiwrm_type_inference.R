# functions/dapsiwrm_type_inference.R
# DAPSIWRM Type Inference from Element Names
# Uses keyword matching to guess element types when not provided

# ============================================================================
# KEYWORD DICTIONARIES FOR DAPSIWRM TYPES
# ============================================================================

#' Get keyword dictionary for DAPSIWRM type inference
#'
#' Returns a list of keywords associated with each DAPSIWRM element type.
#' Keywords are matched case-insensitively against element names.
#'
#' @return Named list with DAPSIWRM types as names and keyword vectors as values
#' @export
get_dapsiwrm_keywords <- function() {
  list(
    # DRIVERS - External forces that cause change
    "Driver" = c(
      # Climate/Environmental drivers
      "climate", "climate change", "global warming", "temperature", "warming",
      "sea level", "ocean acidification", "weather", "storm", "hurricane",
      "greenhouse gas", "ghg emission", "climate mitigation",
      # Economic drivers
      "market", "demand", "price", "economy", "economic", "trade", "globalization",
      "investment", "subsidy", "subsidies", "incentive",
      "consumer purchasing", "consumer preference", "purchasing",
      # Social/demographic drivers
      "population", "demographic", "migration", "urbanization", "lifestyle",
      "consumption", "consumer", "cultural", "tradition", "social change",
      "identity", "employment rate",
      # Policy/governance drivers
      "policy", "regulation", "legislation", "law", "governance", "political",
      "eu directive", "international agreement", "treaty",
      # Technology drivers
      "technology", "innovation", "technological", "digitalization",
      "technology and product development", "product development"
    ),

    # ACTIVITIES - Human actions/sectors
    "Activity" = c(
      # Fishing activities
      "fishing", "fishery", "fisheries", "trawling", "aquaculture", "mariculture",
      "harvesting", "extraction", "extractive", "catch", "landing",
      "pelagic fishing", "demersal fishing", "catch mackerel", "catch herring",
      "catch blue whiting",
      # Tourism/recreation
      "tourism", "tourist", "recreation", "recreational", "diving", "boating",
      "sailing", "cruise", "beach", "bathing", "swimming", "snorkeling",
      "whale watching", "ecotourism",
      # Shipping/transport
      "shipping", "transport", "navigation", "maritime", "port", "harbor",
      "vessel", "boat traffic", "ferry", "marine traffic", "mooring", "moorings",
      # Industry
      "industry", "industrial", "manufacturing", "processing", "refinery",
      "oil", "gas", "offshore", "drilling", "mining", "dredging",
      # Coastal development
      "construction", "development", "infrastructure", "coastal development",
      "urbanization", "land use", "reclamation",
      # Energy
      "energy", "wind farm", "offshore wind", "renewable", "power plant",
      # Agriculture
      "agriculture", "farming", "irrigation", "runoff"
    ),

    # PRESSURES - Environmental stressors from activities
    "Pressure" = c(
      # Pollution
      "pollution", "pollutant", "contamination", "discharge", "emission",
      "nutrient", "nitrogen", "phosphorus", "eutrophication", "waste",
      "plastic", "microplastic", "litter", "garbage", "sewage", "effluent",
      "chemical", "toxic", "heavy metal", "oil spill",
      # Physical pressures
      "disturbance", "damage", "destruction", "degradation", "erosion",
      "sedimentation", "turbidity", "dredging impact", "habitat loss",
      "seabed", "abrasion", "smothering", "anchoring",
      # Biological pressures
      "overfishing", "overexploitation", "bycatch", "invasive", "alien species",
      "disease", "pathogen", "parasite", "biological pressure",
      "animals killed", "animals injured", "mortality", "injury",
      "fishing mortality", "fishing pressure",
      # Noise/light
      "noise", "underwater noise", "light pollution", "artificial light",
      # Climate pressures
      "acidification", "hypoxia", "anoxia", "dead zone", "bleaching",
      "heatwave", "heat wave", "marine heatwave"
    ),

    # MARINE PROCESS AND FUNCTION (State) - Ecosystem components and processes
    "Marine Process and Function" = c(
      # Habitats
      "habitat", "ecosystem", "biotope", "seagrass", "posidonia", "kelp",
      "coral", "reef", "mangrove", "wetland", "marsh", "estuary",
      "benthic", "pelagic", "intertidal", "subtidal",
      # Specific species/habitats (Mediterranean)
      "p. oceanica", "posidonia oceanica", "cymodocea",
      # Species/biodiversity
      "biodiversity", "species", "population", "abundance", "biomass",
      "fish stock", "stock", "community", "assemblage", "fauna", "flora",
      "plankton", "phytoplankton", "zooplankton",
      # Spawning stock biomass (Arctic models)
      "ssb", "spawning stock", "ssb mackerel", "ssb herring", "ssb blue whiting",
      # Ecological processes
      "primary production", "productivity", "food web", "trophic",
      "nutrient cycling", "carbon cycle", "biogeochemical",
      "reproduction", "recruitment", "spawning", "nursery",
      "migration", "connectivity", "dispersal",
      # Reproduction and occurrence (Arctic models)
      "reproductive success", "fish occurrence", "occurrence",
      "breeding success", "survival", "mortality rate",
      # Water quality
      "water quality", "clarity", "transparency", "oxygen",
      # Ecosystem state
      "health", "condition", "integrity", "resilience", "recovery",
      # Physical state
      "sst", "sea surface temperature", "salinity", "current"
    ),

    # ECOSYSTEM SERVICE - Benefits from ecosystems
    "Ecosystem Service" = c(
      # Provisioning services
      "fish provision", "food provision", "seafood", "raw material",
      "genetic resource", "medicinal", "ornamental",
      # Regulating services
      "carbon sequestration", "carbon storage", "climate regulation",
      "coastal protection", "erosion control", "flood protection",
      "water purification", "filtration", "detoxification",
      "pest control", "disease regulation",
      # Cultural services
      "aesthetic", "scenic", "landscape", "seascape",
      "spiritual", "inspiration", "sense of place", "identity",
      "scientific", "research", "education", "educational",
      "heritage", "historical",
      # Supporting services
      "habitat provision", "nursery habitat", "spawning ground",
      "biodiversity maintenance", "life cycle maintenance"
    ),

    # GOOD AND BENEFIT (Welfare) - Human benefits/wellbeing
    "Good and Benefit" = c(
      # Economic benefits
      "income", "revenue", "profit", "livelihood", "employment", "job",
      "economic contribution", "gdp", "value added", "economic value",
      "export", "market value",
      # Blue economy benefits (Arctic models)
      "blue employment", "blue economy", "community development",
      # Food/nutrition
      "food security", "nutrition", "protein", "diet", "food provision",
      # Health
      "health", "wellbeing", "well-being", "welfare", "quality of life",
      "mental health", "physical health", "stress reduction",
      # Social benefits
      "community", "social cohesion", "cultural identity", "tradition",
      "knowledge", "local knowledge", "traditional knowledge",
      "public service", "public services",
      # Recreation benefits
      "enjoyment", "satisfaction", "experience", "leisure",
      # Safety
      "safety", "security", "protection"
    ),

    # RESPONSE/MEASURE - Management actions
    "Response" = c(
      # Protected areas
      "mpa", "marine protected area", "protected area", "reserve",
      "sanctuary", "conservation area", "natura 2000", "no-take zone",
      # Regulations
      "regulation", "restriction", "ban", "prohibition", "quota", "limit",
      "moratorium", "closure", "seasonal closure",
      # Management measures
      "management", "plan", "strategy", "action", "measure", "intervention",
      "monitoring", "surveillance", "enforcement", "compliance",
      # Restoration
      "restoration", "rehabilitation", "recovery", "rewilding",
      "transplantation", "reintroduction",
      # Pollution control
      "treatment", "wastewater treatment", "cleanup", "remediation",
      "emission reduction", "pollution control",
      # Sustainable practices
      "sustainable", "certification", "eco-label", "best practice",
      "gear modification", "selective fishing",
      # Awareness/education
      "awareness", "campaign", "outreach", "stakeholder engagement",
      "participation", "co-management"
    )
  )
}

# ============================================================================
# TYPE INFERENCE FUNCTIONS
# ============================================================================

#' Infer DAPSIWRM type from element name
#'
#' Uses keyword matching to guess the most likely DAPSIWRM type for an element.
#'
#' @param element_name Character string with the element name
#' @param keywords Optional custom keyword dictionary (uses default if NULL)
#' @param return_score If TRUE, returns list with type and confidence score
#' @return Character string with inferred type, or NA if no match found
#' @export
infer_dapsiwrm_type <- function(element_name, keywords = NULL, return_score = FALSE) {
  if (is.na(element_name) || !nzchar(trimws(element_name))) {
    if (return_score) {
      return(list(type = NA_character_, score = 0, matches = character()))
    }
    return(NA_character_)
  }

  if (is.null(keywords)) {
    keywords <- get_dapsiwrm_keywords()
  }

  name_lower <- tolower(element_name)

  # Score each type based on keyword matches
  scores <- sapply(names(keywords), function(type) {
    type_keywords <- keywords[[type]]
    matches <- sapply(type_keywords, function(kw) {
      grepl(kw, name_lower, fixed = TRUE)
    })
    sum(matches)
  })

  # Find best match
  best_type <- names(which.max(scores))
  best_score <- max(scores)

  if (best_score == 0) {
    if (return_score) {
      return(list(type = NA_character_, score = 0, matches = character()))
    }
    return(NA_character_)
  }

  if (return_score) {
    # Find which keywords matched
    matched_keywords <- keywords[[best_type]][sapply(keywords[[best_type]], function(kw) {
      grepl(kw, name_lower, fixed = TRUE)
    })]
    return(list(type = best_type, score = best_score, matches = matched_keywords))
  }

  return(best_type)
}

#' Infer DAPSIWRM types for multiple elements
#'
#' @param element_names Vector of element names
#' @param keywords Optional custom keyword dictionary
#' @param verbose If TRUE, prints progress information
#' @return Vector of inferred types (same length as input)
#' @export
infer_dapsiwrm_types <- function(element_names, keywords = NULL, verbose = FALSE) {
  if (is.null(keywords)) {
    keywords <- get_dapsiwrm_keywords()
  }

  n <- length(element_names)
  types <- character(n)
  matched_count <- 0

  for (i in seq_len(n)) {
    result <- infer_dapsiwrm_type(element_names[i], keywords, return_score = TRUE)
    types[i] <- result$type

    if (!is.na(result$type)) {
      matched_count <- matched_count + 1
      if (verbose) {
        debug_log(sprintf("[%d/%d] '%s' -> %s (score: %d, keywords: %s)",
                    i, n, element_names[i], result$type, result$score,
                    paste(result$matches, collapse = ", ")), "TYPE_INFERENCE")
      }
    } else if (verbose) {
      debug_log(sprintf("[%d/%d] '%s' -> NO MATCH", i, n, element_names[i]), "TYPE_INFERENCE")
    }
  }

  if (verbose) {
    debug_log(sprintf("Inferred types for %d of %d elements (%.1f%%)",
                matched_count, n, 100 * matched_count / n), "TYPE_INFERENCE")
  }

  return(types)
}

#' Add inferred types to elements dataframe
#'
#' Adds or fills missing types in an elements dataframe using inference.
#'
#' @param elements Data frame with element data
#' @param label_col Name of the label column (default: "Label")
#' @param type_col Name of the type column (default: "Type")
#' @param overwrite If TRUE, replaces all types; if FALSE, only fills NA values
#' @param verbose If TRUE, prints progress information
#' @return Updated data frame with inferred types
#' @export
add_inferred_types <- function(elements, label_col = "Label", type_col = "Type",
                                overwrite = FALSE, verbose = TRUE) {
  if (!label_col %in% names(elements)) {
    stop("Label column '", label_col, "' not found in elements data")
  }

  # Ensure type column exists
  if (!type_col %in% names(elements)) {
    elements[[type_col]] <- NA_character_
  }

  # Get indices to update
  if (overwrite) {
    indices <- seq_len(nrow(elements))
  } else {
    indices <- which(is.na(elements[[type_col]]) | !nzchar(trimws(elements[[type_col]])))
  }

  if (length(indices) == 0) {
    if (verbose) debug_log("No elements need type inference.", "TYPE_INFERENCE")
    return(elements)
  }

  if (verbose) {
    debug_log(sprintf("Inferring types for %d elements...", length(indices)), "TYPE_INFERENCE")
  }

  # Infer types for selected elements
  names_to_infer <- elements[[label_col]][indices]
  inferred <- infer_dapsiwrm_types(names_to_infer, verbose = verbose)

  # Update dataframe
  elements[[type_col]][indices] <- inferred

  # Report results
  if (verbose) {
    na_count <- sum(is.na(elements[[type_col]]))
    debug_log(sprintf("Result: %d elements still without type (%.1f%%)",
                na_count, 100 * na_count / nrow(elements)), "TYPE_INFERENCE")
  }

  return(elements)
}

# ============================================================================
# ANALYSIS FUNCTIONS
# ============================================================================

#' Analyze type inference results
#'
#' Provides detailed analysis of type inference for a set of elements.
#'
#' @param element_names Vector of element names
#' @param actual_types Optional vector of actual types for comparison
#' @return Data frame with inference results
#' @export
analyze_type_inference <- function(element_names, actual_types = NULL) {
  keywords <- get_dapsiwrm_keywords()

  results <- data.frame(
    element = element_names,
    inferred_type = character(length(element_names)),
    score = integer(length(element_names)),
    matched_keywords = character(length(element_names)),
    stringsAsFactors = FALSE
  )

  if (!is.null(actual_types)) {
    results$actual_type <- actual_types
    results$match <- logical(length(element_names))
  }

  for (i in seq_along(element_names)) {
    result <- infer_dapsiwrm_type(element_names[i], keywords, return_score = TRUE)
    results$inferred_type[i] <- if (is.na(result$type)) "" else result$type
    results$score[i] <- result$score
    results$matched_keywords[i] <- paste(result$matches, collapse = "; ")

    if (!is.null(actual_types)) {
      results$match[i] <- !is.na(result$type) && !is.na(actual_types[i]) &&
        tolower(result$type) == tolower(actual_types[i])
    }
  }

  return(results)
}

#' Print type inference summary
#'
#' @param elements Data frame with Label and Type columns
#' @param label_col Name of label column
#' @param type_col Name of type column
#' @export
print_type_inference_summary <- function(elements, label_col = "Label", type_col = "Type") {
  if (!type_col %in% names(elements)) {
    cat("No type column found.\n")
    return(invisible(NULL))
  }

  types <- elements[[type_col]]
  type_counts <- table(types, useNA = "ifany")

  cat("Type Distribution:\n")
  cat(rep("-", 40), "\n", sep = "")
  for (t in names(sort(type_counts, decreasing = TRUE))) {
    display_name <- if (is.na(t)) "<NA>" else t
    cat(sprintf("  %-30s: %d\n", display_name, type_counts[t]))
  }
  cat(rep("-", 40), "\n", sep = "")
  cat(sprintf("Total: %d elements\n", nrow(elements)))
}
