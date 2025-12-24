# modules/ai_isa_knowledge_base.R
# Knowledge Base and Context-Aware Suggestions for AI ISA Assistant
# Purpose: Provides regional seas data and context-aware suggestions for DAPSI(W)R(M) elements

# ============================================================================
# REGIONAL SEAS KNOWLEDGE BASE
# ============================================================================

#' Get Regional Seas Knowledge Base
#'
#' Returns a list of regional seas with their characteristics, common issues,
#' and ecosystem types.
#'
#' @param i18n Internationalization object for translations
#' @return List of regional seas with their properties
get_regional_seas_knowledge_base <- function(i18n) {
  list(
    baltic = list(
      name_en = "Baltic Sea",
      name_i18n = i18n$t("common.misc.baltic_sea"),
      common_issues = c("Eutrophication", "Overfishing", "Pollution", "Invasive species", "Climate change"),
      ecosystem_types = c("Open coast", "Archipelago", "Estuary", "Coastal lagoon", "Offshore waters")
    ),
    mediterranean = list(
      name_en = "Mediterranean Sea",
      name_i18n = i18n$t("common.misc.mediterranean_sea"),
      common_issues = c("Overfishing", "Coastal development", "Tourism pressure", "Marine litter", "Invasive species", "Climate change"),
      ecosystem_types = c("Open coast", "Coastal lagoon", "Rocky shore", "Sandy beach", "Seagrass meadow", "Offshore waters")
    ),
    north_sea = list(
      name_en = "North Sea",
      name_i18n = i18n$t("common.misc.north_sea"),
      common_issues = c("Overfishing", "Oil and gas extraction", "Shipping", "Wind energy development", "Climate change", "Eutrophication"),
      ecosystem_types = c("Open coast", "Estuary", "Tidal flat", "Offshore waters", "Rocky shore", "Sandy beach")
    ),
    irish_sea = list(
      name_en = "Irish Sea",
      name_i18n = i18n$t("common.misc.irish_sea"),
      common_issues = c("Overfishing", "Coastal development", "Shipping", "Marine litter", "Eutrophication", "Climate change"),
      ecosystem_types = c("Open coast", "Estuary", "Coastal lagoon", "Rocky shore", "Sandy beach", "Offshore waters")
    ),
    east_atlantic = list(
      name_en = "East Atlantic",
      name_i18n = i18n$t("common.misc.east_atlantic"),
      common_issues = c("Overfishing", "Climate change", "Ocean acidification", "Shipping", "Coastal erosion", "Marine litter"),
      ecosystem_types = c("Open coast", "Continental shelf", "Offshore waters", "Rocky shore", "Sandy beach", "Estuary")
    ),
    black_sea = list(
      name_en = "Black Sea",
      name_i18n = i18n$t("common.misc.black_sea"),
      common_issues = c("Eutrophication", "Overfishing", "Pollution", "Invasive species", "Coastal erosion"),
      ecosystem_types = c("Open coast", "Delta", "Coastal lagoon", "Offshore waters", "Estuary")
    ),
    atlantic = list(
      name_en = "Atlantic Ocean",
      name_i18n = i18n$t("common.misc.atlantic_ocean"),
      common_issues = c("Overfishing", "Climate change", "Ocean acidification", "Shipping", "Deep-sea mining"),
      ecosystem_types = c("Open ocean", "Continental shelf", "Coastal upwelling", "Open coast", "Offshore waters")
    ),
    pacific = list(
      name_en = "Pacific Ocean",
      name_i18n = i18n$t("common.misc.pacific_ocean"),
      common_issues = c("Overfishing", "Coral bleaching", "Plastic pollution", "Climate change", "Illegal fishing"),
      ecosystem_types = c("Coral reef", "Open ocean", "Coastal waters", "Mangrove", "Offshore waters")
    ),
    indian = list(
      name_en = "Indian Ocean",
      name_i18n = i18n$t("common.misc.indian_ocean"),
      common_issues = c("Overfishing", "Coastal erosion", "Mangrove loss", "Climate change", "Illegal fishing"),
      ecosystem_types = c("Coral reef", "Mangrove", "Open coast", "Lagoon", "Offshore waters")
    ),
    caribbean = list(
      name_en = "Caribbean Sea",
      name_i18n = i18n$t("common.misc.caribbean_sea"),
      common_issues = c("Coral bleaching", "Overfishing", "Tourism pressure", "Hurricanes", "Sargassum blooms"),
      ecosystem_types = c("Coral reef", "Mangrove", "Seagrass bed", "Sandy beach", "Open coast")
    ),
    arctic = list(
      name_en = "Arctic Ocean",
      name_i18n = i18n$t("common.misc.arctic_ocean"),
      common_issues = c("Climate change", "Sea ice loss", "Oil and gas exploration", "Shipping increase", "Arctic fisheries"),
      ecosystem_types = c("Sea ice", "Open ocean", "Fjord", "Coastal waters", "Continental shelf")
    ),
    other = list(
      name_en = "Other/Regional",
      name_i18n = i18n$t("common.misc.otherregional"),
      common_issues = c("Overfishing", "Pollution", "Coastal development", "Climate change"),
      ecosystem_types = c("Open coast", "Estuary", "Lagoon", "Offshore waters", "Rocky shore")
    )
  )
}

# ============================================================================
# CONTEXT-AWARE SUGGESTIONS
# ============================================================================

#' Semantic Deduplication Helper
#'
#' Removes semantically similar suggestions to avoid showing "trawl fishing" and "trawling" together
#'
#' @param suggestions Character vector of suggestions
#' @return Deduplicated character vector
deduplicate_suggestions <- function(suggestions) {
  if (length(suggestions) <= 1) return(suggestions)

  # Convert to lowercase for comparison
  lower_suggestions <- tolower(suggestions)

  # Track which items to keep
  keep <- rep(TRUE, length(suggestions))

  for (i in seq_along(lower_suggestions)) {
    if (!keep[i]) next  # Already marked for removal

    current <- lower_suggestions[i]

    # Check against all subsequent items
    for (j in seq_along(lower_suggestions)) {
      if (i >= j || !keep[j]) next  # Skip self and already removed items

      other <- lower_suggestions[j]

      # Extract core words (remove common suffixes/prefixes)
      current_words <- unlist(strsplit(current, "\\s+"))
      other_words <- unlist(strsplit(other, "\\s+"))

      # Check for significant overlap
      # If one is a subset of the other, or they share key root words, mark as duplicate
      current_core <- gsub("ing$|ed$|s$", "", current_words)
      other_core <- gsub("ing$|ed$|s$", "", other_words)

      # Calculate overlap - if 80%+ of words match (after stemming), it's a duplicate
      common_words <- intersect(current_core, other_core)

      # If they share most core words, keep the shorter/simpler one
      if (length(common_words) > 0) {
        overlap_ratio <- length(common_words) / min(length(current_core), length(other_core))

        if (overlap_ratio >= 0.8) {
          # Keep the one with fewer words (simpler)
          if (length(current_words) <= length(other_words)) {
            keep[j] <- FALSE
          } else {
            keep[i] <- FALSE
            break  # Current item removed, move to next i
          }
        }
      }
    }
  }

  return(suggestions[keep])
}

#' Get Context-Aware Suggestions for DAPSI(W)R(M) Elements
#'
#' Returns intelligent suggestions based on regional sea, ecosystem type,
#' and main issue context.
#'
#' @param category DAPSIWRM category (drivers, activities, pressures, states, impacts, welfare, responses)
#' @param regional_sea Selected regional sea key
#' @param ecosystem_type Selected ecosystem type
#' @param main_issue Main environmental issue
#' @return Character vector of context-aware suggestions
get_context_suggestions <- function(category, regional_sea, ecosystem_type, main_issue) {
  suggestions <- list()

  if (category == "drivers") {
    # Universal drivers
    suggestions$universal <- c("Food security", "Economic development", "Recreation and tourism",
                               "Energy needs", "Coastal protection", "Cultural heritage",
                               "Employment", "Trade and commerce")

    # Add region-specific drivers
    if (!is.null(regional_sea)) {
      if (regional_sea %in% c("baltic", "north_sea")) {
        suggestions$regional <- c("Maritime transport", "Resource extraction", "Renewable energy")
      } else if (regional_sea %in% c("mediterranean", "caribbean", "pacific")) {
        suggestions$regional <- c("Beach tourism", "Diving and snorkeling", "Heritage tourism")
      } else if (regional_sea == "arctic") {
        suggestions$regional <- c("Indigenous subsistence", "Resource exploration", "Shipping routes")
      }
    }
  }

  else if (category == "activities") {
    # Universal activities
    suggestions$universal <- c("Commercial fishing", "Aquaculture", "Shipping", "Coastal development")

    # Region-specific
    if (!is.null(regional_sea)) {
      if (regional_sea %in% c("baltic", "north_sea", "irish_sea")) {
        suggestions$regional <- c("Wind farm development", "Dredging", "Oil and gas extraction",
                                  "Trawl fishing", "Marine aggregate extraction")
      } else if (regional_sea %in% c("mediterranean", "caribbean")) {
        suggestions$regional <- c("Beach recreation", "Yacht tourism", "Scuba diving",
                                  "Coastal construction", "Marine debris disposal")
      } else if (regional_sea == "arctic") {
        suggestions$regional <- c("Ice navigation", "Arctic oil exploration", "Cold-water fishing")
      } else if (regional_sea %in% c("pacific", "indian")) {
        suggestions$regional <- c("Reef fishing", "Mangrove clearing", "Port expansion")
      }
    }

    # Issue-specific
    if (length(main_issue) > 0) {
      if (any(grepl("fish", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Trawling", "Long-line fishing", "Purse seining", "Fish farming")
      } else if (any(grepl("eutroph|nutrient", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Agriculture runoff", "Sewage discharge", "Aquaculture waste")
      } else if (any(grepl("pollution|litter", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Plastic disposal", "Wastewater discharge", "Ship emissions")
      } else if (any(grepl("tourism", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Beach development", "Hotel construction", "Cruise tourism")
      }
    }
  }

  else if (category == "pressures") {
    # Universal pressures
    suggestions$universal <- c("Nutrient enrichment", "Overfishing", "Physical disturbance",
                               "Marine litter", "Underwater noise", "Habitat loss")

    # Region-specific
    if (!is.null(regional_sea)) {
      if (regional_sea == "baltic") {
        suggestions$regional <- c("Hypoxia", "Algal blooms", "Sediment resuspension")
      } else if (regional_sea == "north_sea") {
        suggestions$regional <- c("Seabed abrasion", "Hydrocarbon contamination", "Noise from shipping")
      } else if (regional_sea %in% c("mediterranean", "caribbean")) {
        suggestions$regional <- c("Coastal erosion", "Beach trampling", "Anchor damage")
      } else if (regional_sea == "arctic") {
        suggestions$regional <- c("Oil spill risk", "Ice habitat loss", "Black carbon deposition")
      }
    }

    # Issue-specific
    if (length(main_issue) > 0) {
      if (any(grepl("eutroph", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Nitrogen loading", "Phosphorus loading", "Organic enrichment", "Algal blooms")
      } else if (any(grepl("fish", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Stock depletion", "Bycatch", "Trawl damage", "Discarding")
      } else if (any(grepl("climate", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Ocean warming", "Ocean acidification", "Sea level rise")
      }
    }
  }

  else if (category == "states") {
    # Universal state changes
    suggestions$universal <- c("Water quality decline", "Biodiversity loss", "Habitat degradation",
                               "Species population changes", "Oxygen depletion")

    # Region-specific
    if (!is.null(regional_sea)) {
      if (regional_sea == "baltic") {
        suggestions$regional <- c("Hypoxic zones expansion", "Cod stock collapse", "Seagrass decline")
      } else if (regional_sea %in% c("mediterranean", "caribbean", "pacific", "indian")) {
        suggestions$regional <- c("Coral bleaching", "Seagrass loss", "Reef degradation")
      } else if (regional_sea == "arctic") {
        suggestions$regional <- c("Sea ice reduction", "Permafrost thaw", "Species range shifts")
      } else if (regional_sea == "north_sea") {
        suggestions$regional <- c("Benthic community changes", "Fish stock declines", "Phytoplankton shifts")
      }
    }

    # Ecosystem-specific
    if (!is.null(ecosystem_type)) {
      if (grepl("coral|reef", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Coral cover decline", "Fish diversity loss", "Reef structural complexity loss")
      } else if (grepl("mangrove", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Mangrove forest area loss", "Carbon storage reduction", "Nursery habitat loss")
      } else if (grepl("estuar", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Salinity changes", "Turbidity increase", "Migratory fish decline")
      }
    }
  }

  else if (category == "impacts") {
    # Universal impacts
    suggestions$universal <- c("Loss of ecosystem services", "Reduced fish catches", "Coastal vulnerability",
                               "Economic losses", "Health risks", "Cultural loss")

    # Ecosystem-specific
    if (!is.null(ecosystem_type)) {
      if (grepl("coral|reef", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Tourism revenue loss", "Coastal protection loss", "Fishery collapse")
      } else if (grepl("mangrove", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Storm protection loss", "Nursery habitat loss", "Carbon release")
      } else if (grepl("seagrass", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Nursery function loss", "Water clarity decline", "Carbon storage loss")
      } else if (grepl("estuar", ecosystem_type, ignore.case = TRUE)) {
        suggestions$ecosystem <- c("Fishery productivity loss", "Water quality impacts", "Flood risk increase")
      }
    }

    # Issue-specific
    if (length(main_issue) > 0) {
      if (any(grepl("fish", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Livelihood loss", "Food security threats", "Economic decline")
      } else if (any(grepl("eutroph|nutrient", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Recreation value loss", "Drinking water contamination", "Shellfish harvest closures")
      } else if (any(grepl("tourism", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Aesthetic value loss", "Revenue decline", "Employment loss")
      }
    }
  }

  else if (category == "welfare") {
    # Universal welfare impacts
    suggestions$universal <- c("Income loss", "Food insecurity", "Health impacts", "Cultural identity loss",
                               "Displacement", "Recreational opportunities loss")

    # Issue-specific
    if (length(main_issue) > 0) {
      if (any(grepl("fish", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Fisher income loss", "Protein source loss", "Traditional livelihoods decline")
      } else if (any(grepl("tourism", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Tourism employment loss", "Local business decline", "Community well-being impacts")
      } else if (any(grepl("climate", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Displacement risk", "Property loss", "Livelihood disruption")
      }
    }
  }

  else if (category == "responses") {
    # Universal responses
    suggestions$universal <- c("Marine Protected Areas", "Fishing regulations", "Pollution controls",
                               "Monitoring programs", "Ecosystem restoration", "Stakeholder engagement")

    # Region-specific
    if (!is.null(regional_sea)) {
      if (regional_sea == "baltic") {
        suggestions$regional <- c("Nutrient reduction targets", "Oxygen restoration", "Fish stock recovery plans")
      } else if (regional_sea %in% c("mediterranean", "caribbean")) {
        suggestions$regional <- c("Coral restoration", "Beach management plans", "Marine debris reduction")
      } else if (regional_sea == "north_sea") {
        suggestions$regional <- c("Trawling restrictions", "Wind farm planning", "Oil spill preparedness")
      } else if (regional_sea == "arctic") {
        suggestions$regional <- c("Shipping regulations", "Ice habitat protection", "Indigenous co-management")
      }
    }

    # Issue-specific
    if (length(main_issue) > 0) {
      if (any(grepl("fish", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Catch limits", "Fishing gear restrictions", "Stock recovery zones", "Aquaculture alternatives")
      } else if (any(grepl("eutroph", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Agricultural best practices", "Wastewater treatment", "Buffer zones")
      } else if (any(grepl("climate", main_issue, ignore.case = TRUE))) {
        suggestions$issue <- c("Carbon reduction", "Climate adaptation planning", "Coastal defense")
      }
    }
  }

  # Combine all suggestions and remove exact duplicates
  all_suggestions <- unique(c(suggestions$universal, suggestions$regional,
                              suggestions$ecosystem, suggestions$issue))

  # Apply semantic deduplication to remove similar terms
  deduplicated <- deduplicate_suggestions(all_suggestions)

  return(deduplicated)
}
