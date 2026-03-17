# data/dapsiwrm_element_keywords.R
# Keyword database for AI-powered DAPSIWRM element classification
# Used by the graphical SES creator module to classify user-provided elements

#' DAPSIWRM Element Keywords Database
#'
#' Comprehensive keyword lists for classifying elements into DAPSIWRM categories.
#' Each category has:
#' - primary: Exact keywords that strongly indicate the category
#' - patterns: Regex patterns for partial matches
#' - context_boost: Keywords that increase relevance in specific contexts
#'
#' @format List of 7 DAPSIWRM types, each containing keyword lists
#' @export
DAPSIWRM_KEYWORDS <- list(

  # ============================================================================
  # DRIVERS (D)
  # Social, economic, or environmental factors that create demand/need
  # ============================================================================
  Drivers = list(
    primary = c(
      # Economic drivers
      "demand", "need", "requirement", "desire", "pressure for",
      "economic growth", "development", "market demand", "consumer demand",
      "employment", "job creation", "income generation",

      # Social drivers
      "population growth", "population increase", "urbanization",
      "food security", "energy security", "water security",
      "livelihood", "subsistence", "welfare need",

      # Cultural drivers
      "tourism demand", "recreational demand", "cultural practice",
      "tradition", "heritage", "identity",

      # Environmental drivers
      "climate change", "sea level rise", "temperature increase",
      "natural variability", "environmental change",

      # Additional drivers
      "agricultural", "vulnerability", "blue economy", "diversification",
      "intensification", "adaptation", "urbanisation", "infrastructure"
    ),

    patterns = c(
      ".*demand.*", ".*need.*", ".*requirement.*",
      ".*growth.*", ".*security.*", ".*livelihood.*",
      ".*population.*", ".*market.*", ".*consumer.*"
    ),

    context_boost = list(
      fishing = c("food security", "livelihood", "employment", "market demand"),
      tourism = c("tourism demand", "economic growth", "employment"),
      eutrophication = c("food security", "population growth", "development"),
      aquaculture = c("food security", "market demand", "livelihood", "employment"),
      shipping = c("economic growth", "market demand", "development"),
      coastal_development = c("urbanization", "infrastructure", "population growth", "development"),
      pollution = c("population growth", "development", "demand"),
      climate = c("climate change", "sea level rise", "adaptation", "vulnerability"),
      invasive_species = c("environmental change", "natural variability"),
      arctic = c("climate change", "vulnerability", "adaptation", "livelihood")
    )
  ),

  # ============================================================================
  # ACTIVITIES (A)
  # Human actions/interventions in the marine environment
  # ============================================================================
  Activities = list(
    primary = c(
      # Fishing activities
      "fishing", "commercial fishing", "recreational fishing", "artisanal fishing",
      "trawling", "bottom trawling", "purse seining", "longlining",
      "gillnetting", "dredging for shellfish",

      # Aquaculture
      "aquaculture", "fish farming", "shellfish farming", "mariculture",
      "fish farm", "salmon farming", "mussel farming",

      # Maritime transport
      "shipping", "maritime transport", "vessel traffic", "navigation",
      "port operations", "cruise ships",

      # Coastal development
      "construction", "coastal development", "port development",
      "harbor development", "infrastructure",

      # Tourism and recreation
      "tourism", "recreational activities", "beach tourism",
      "diving", "sailing", "boating",

      # Resource extraction
      "sand extraction", "gravel extraction", "oil drilling",
      "gas extraction", "mining", "dredging",

      # Agriculture and land use
      "agriculture", "farming", "livestock", "fertilizer use",
      "land runoff", "wastewater discharge",

      # Other activities
      "renewable energy", "wind farms", "wave energy",
      "desalination", "coastal defense",

      # Additional activities
      "harvesting", "anchoring", "mooring", "remediation", "monitoring",
      "nourishment", "seismic", "cultivation", "stocking", "hatchery",
      "dredging", "discharge", "extraction"
    ),

    patterns = c(
      ".*fishing", ".*trawling", ".*aquaculture.*", ".*farm.*",
      ".*shipping", ".*transport.*", ".*construction.*",
      ".*development", ".*extraction.*", ".*dredging.*",
      ".*tourism.*", ".*recreation.*"
    ),

    context_boost = list(
      fishing = c("commercial fishing", "trawling", "overfishing"),
      eutrophication = c("agriculture", "farming", "fertilizer use"),
      tourism = c("tourism", "recreational activities", "coastal development"),
      aquaculture = c("aquaculture", "fish farming", "shellfish farming", "cage", "feed", "pen", "hatchery"),
      shipping = c("shipping", "port operations", "vessel traffic", "navigation", "ballast"),
      coastal_development = c("construction", "coastal development", "urbanization", "resort", "infrastructure"),
      pollution = c("wastewater discharge", "discharge", "land runoff"),
      climate = c("coastal defense", "renewable energy"),
      invasive_species = c("introduction of species", "stocking"),
      arctic = c("extraction", "mining", "monitoring")
    )
  ),

  # ============================================================================
  # PRESSURES (P)
  # Direct stressors on the marine environment from activities
  # ============================================================================
  Pressures = list(
    primary = c(
      # Biological pressures
      "overfishing", "bycatch", "incidental catch", "selective extraction",
      "introduction of species", "invasive species", "alien species",
      "disease", "pathogen introduction",

      # Physical pressures
      "seabed disturbance", "habitat destruction", "habitat damage",
      "physical loss", "smothering", "abrasion",
      "noise pollution", "underwater noise", "acoustic disturbance",
      "marine litter", "plastic pollution", "debris",
      "siltation", "turbidity", "sediment resuspension",

      # Chemical pressures
      "nutrient enrichment", "eutrophication", "nutrient pollution",
      "chemical pollution", "contamination", "toxic substances",
      "heavy metals", "oil spills", "pesticides",
      "ocean acidification", "pH change",

      # Thermal pressures
      "thermal pollution", "heating", "cooling water discharge",

      # Hydrological pressures
      "salinity change", "coastal erosion", "wave exposure change",
      "current alteration",

      # Additional pressures
      "altered", "anoxic", "anoxia", "antifouling", "leaching", "bleaching",
      "heatwave", "accumulation", "overgrazing", "trampling", "sewage",
      "warming", "blocked", "barrier", "hypoxia", "turbidity",
      "salinisation", "acidification"
    ),

    patterns = c(
      ".*pollution", ".*contamination.*", ".*enrichment.*",
      ".*overfishing.*", ".*damage.*", ".*loss.*",
      ".*disturbance.*", ".*erosion.*", ".*litter.*",
      ".*invasive.*", ".*alien.*"
    ),

    context_boost = list(
      fishing = c("overfishing", "bycatch", "seabed disturbance"),
      eutrophication = c("nutrient enrichment", "eutrophication", "hypoxia"),
      tourism = c("marine litter", "noise pollution", "physical disturbance"),
      aquaculture = c("nutrient enrichment", "disease", "pathogen introduction", "chemical pollution"),
      shipping = c("oil spills", "noise pollution", "invasive species", "ballast", "antifouling"),
      coastal_development = c("habitat destruction", "coastal erosion", "siltation", "turbidity"),
      pollution = c("contamination", "toxic substances", "sewage", "chemical pollution", "microplastic"),
      climate = c("warming", "acidification", "bleaching", "heatwave", "ocean acidification"),
      invasive_species = c("invasive species", "alien species", "introduction of species", "non-native"),
      arctic = c("warming", "permafrost", "ice", "acidification", "anoxia")
    )
  ),

  # ============================================================================
  # MARINE PROCESSES & FUNCTIONING (State/S)
  # Changes in the state of marine ecosystems
  # ============================================================================
  "Marine Processes & Functioning" = list(
    primary = c(
      # Biodiversity
      "biodiversity", "species diversity", "genetic diversity",
      "ecosystem diversity", "richness",

      # Populations
      "population decline", "population size", "abundance",
      "biomass", "stock size", "recruitment",
      "age structure", "size distribution",

      # Habitats
      "habitat extent", "habitat quality", "habitat condition",
      "seagrass beds", "coral reefs", "kelp forests",
      "rocky reefs", "soft sediments", "nursery grounds",

      # Water quality
      "water quality", "dissolved oxygen", "hypoxia", "anoxia",
      "clarity", "transparency", "turbidity level",

      # Ecosystem functioning
      "primary production", "productivity", "nutrient cycling",
      "food web", "trophic structure", "community composition",
      "ecosystem health", "resilience",

      # Additional state keywords
      "migration", "sediment budget", "clarity", "salinity",
      "filamentous", "freshwater lens", "permafrost", "recruitment",
      "canopy", "benthos", "benthic", "matte", "halocline"
    ),

    patterns = c(
      ".*biodiversity.*", ".*population.*", ".*habitat.*",
      ".*quality.*", ".*abundance.*", ".*diversity.*",
      ".*production.*", ".*functioning.*", ".*health.*"
    ),

    context_boost = list(
      fishing = c("population decline", "stock size", "abundance"),
      eutrophication = c("hypoxia", "water quality", "primary production"),
      habitat_loss = c("habitat extent", "habitat quality", "biodiversity"),
      aquaculture = c("benthos", "benthic", "water quality", "nutrient cycling"),
      shipping = c("community composition", "habitat condition"),
      coastal_development = c("habitat extent", "sediment budget", "benthos"),
      pollution = c("water quality", "community composition", "biodiversity"),
      climate = c("recruitment", "migration", "canopy", "bleaching", "resilience"),
      invasive_species = c("community composition", "biodiversity", "trophic structure"),
      arctic = c("permafrost", "halocline", "salinity", "migration", "canopy")
    )
  ),

  # ============================================================================
  # ECOSYSTEM SERVICES (Impact/I)
  # Services provided by marine ecosystems
  # ============================================================================
  "Ecosystem Services" = list(
    primary = c(
      # Provisioning services
      "fish provision", "seafood provision", "food provision",
      "raw materials", "genetic resources", "medicinal resources",

      # Regulating services
      "climate regulation", "carbon sequestration", "carbon storage",
      "coastal protection", "erosion control", "wave attenuation",
      "water purification", "waste treatment", "nutrient regulation",
      "oxygen production", "air quality regulation",

      # Habitat services
      "nursery function", "breeding ground", "spawning area",
      "migration corridor", "refuge",

      # Cultural services
      "recreation", "aesthetic value", "cultural heritage",
      "education", "research", "spiritual value",

      # Additional ecosystem services
      "amenity", "blue carbon", "endemism", "pharmaceutical",
      "ecotourism", "filtration", "flyway", "food web",
      "nursery function", "wave attenuation", "shoreline stabilisation"
    ),

    patterns = c(
      ".*provision.*", ".*service.*", ".*regulation.*",
      ".*protection.*", ".*sequestration.*", ".*nursery.*",
      ".*function.*"
    ),

    context_boost = list(
      fishing = c("fish provision", "food provision", "nursery function"),
      climate = c("carbon sequestration", "climate regulation", "blue carbon"),
      tourism = c("recreation", "aesthetic value", "cultural heritage", "ecotourism", "amenity"),
      aquaculture = c("food provision", "nursery function", "water purification"),
      shipping = c("migration corridor"),
      coastal_development = c("coastal protection", "erosion control", "wave attenuation", "shoreline stabilisation"),
      pollution = c("water purification", "waste treatment", "filtration"),
      invasive_species = c("nursery function", "food web", "endemism"),
      arctic = c("carbon sequestration", "blue carbon", "climate regulation")
    )
  ),

  # ============================================================================
  # GOODS & BENEFITS (Welfare/W)
  # Human welfare benefits derived from ecosystem services
  # ============================================================================
  "Goods & Benefits" = list(
    primary = c(
      # Economic benefits
      "income", "revenue", "profit", "economic value",
      "employment", "jobs", "livelihood",
      "gross domestic product", "GDP contribution",

      # Social benefits
      "food security", "nutrition", "health", "wellbeing",
      "quality of life", "social cohesion", "community resilience",

      # Cultural benefits
      "cultural identity", "heritage preservation", "sense of place",
      "recreational opportunities", "leisure",

      # Environmental benefits
      "clean environment", "healthy ecosystem", "ecosystem resilience",

      # Additional welfare keywords
      "safety", "flood damage", "avoided costs", "decommissioning",
      "drinking water", "pride", "viability", "displacement",
      "overcrowding", "gentrification"
    ),

    patterns = c(
      ".*income.*", ".*revenue.*", ".*welfare.*",
      ".*benefit.*", ".*value.*", ".*employment.*",
      ".*health.*", ".*wellbeing.*", ".*security.*"
    ),

    context_boost = list(
      fishing = c("income", "employment", "food security"),
      tourism = c("revenue", "employment", "recreational opportunities"),
      general = c("quality of life", "wellbeing", "health"),
      aquaculture = c("income", "employment", "food security", "livelihood"),
      shipping = c("revenue", "employment", "economic value"),
      coastal_development = c("flood damage", "avoided costs", "safety", "displacement", "gentrification"),
      pollution = c("health", "drinking water", "clean environment"),
      climate = c("safety", "flood damage", "avoided costs", "ecosystem resilience"),
      invasive_species = c("livelihood", "viability", "food security"),
      arctic = c("livelihood", "safety", "cultural identity", "pride")
    )
  ),

  # ============================================================================
  # RESPONSES (R)
  # Management measures and policy interventions
  # ============================================================================
  Responses = list(
    primary = c(
      # Spatial management
      "marine protected area", "MPA", "no-take zone", "reserve",
      "protected area", "sanctuary", "restricted area",

      # Fishing management
      "fishing quota", "catch limit", "total allowable catch", "TAC",
      "fishing restriction", "seasonal closure", "gear restriction",
      "size limit", "minimum landing size", "mesh size regulation",

      # Pollution control
      "emission limit", "discharge regulation", "pollution control",
      "wastewater treatment", "nutrient reduction", "ban",

      # Planning and zoning
      "spatial planning", "marine spatial planning", "zoning",
      "integrated coastal zone management", "ICZM",

      # Restoration
      "habitat restoration", "ecosystem restoration", "rewilding",
      "reef restoration", "seagrass restoration",

      # Monitoring and enforcement
      "monitoring program", "surveillance", "enforcement",
      "compliance", "inspection",

      # Economic instruments
      "subsidy", "tax", "payment for ecosystem services",
      "fishing license", "permit",

      # Other responses
      "environmental policy", "regulation", "legislation",
      "management plan", "conservation strategy",
      "awareness campaign", "education program",

      # Additional responses
      "buffer zone", "moratorium", "treaty", "convention", "clean-up",
      "pump-out", "community-based", "co-management", "decommissioning",
      "early warning", "carrying capacity", "biosecurity", "eradication"
    ),

    patterns = c(
      ".*regulation.*", ".*policy.*", ".*management.*",
      ".*protection.*", ".*restriction.*", ".*limit.*",
      ".*ban.*", ".*quota.*", ".*MPA.*", ".*reserve.*",
      ".*restoration.*", ".*control.*"
    ),

    context_boost = list(
      fishing = c("fishing quota", "MPA", "catch limit"),
      eutrophication = c("nutrient reduction", "emission limit", "wastewater treatment"),
      general = c("regulation", "policy", "monitoring program"),
      aquaculture = c("regulation", "permit", "zoning", "carrying capacity"),
      shipping = c("regulation", "pollution control", "discharge regulation", "convention"),
      coastal_development = c("spatial planning", "zoning", "buffer zone", "ICZM"),
      pollution = c("pollution control", "clean-up", "pump-out", "discharge regulation", "ban"),
      climate = c("conservation strategy", "ecosystem restoration", "early warning"),
      invasive_species = c("biosecurity", "eradication", "monitoring program", "ban"),
      arctic = c("MPA", "treaty", "conservation strategy", "moratorium", "co-management")
    )
  )
)


#' Get Keywords for a Specific DAPSIWRM Type
#'
#' @param type DAPSIWRM type name (e.g., "Drivers", "Activities")
#' @return List with primary keywords and patterns
#' @export
get_keywords_for_type <- function(type) {
  if (!type %in% names(DAPSIWRM_KEYWORDS)) {
    stop(paste("Unknown DAPSIWRM type:", type))
  }
  return(DAPSIWRM_KEYWORDS[[type]])
}


#' Get All DAPSIWRM Type Names
#'
#' @return Character vector of DAPSIWRM type names
#' @export
get_dapsiwrm_type_names <- function() {
  return(names(DAPSIWRM_KEYWORDS))
}


#' Get Context-Specific Keywords
#'
#' @param type DAPSIWRM type name
#' @param context Context keyword (e.g., "fishing", "eutrophication")
#' @return Character vector of context-boosted keywords
#' @export
get_context_keywords <- function(type, context) {
  keywords <- DAPSIWRM_KEYWORDS[[type]]

  if (is.null(keywords$context_boost)) {
    return(character(0))
  }

  # Try exact match
  if (context %in% names(keywords$context_boost)) {
    return(keywords$context_boost[[context]])
  }

  # Try partial match
  for (ctx_name in names(keywords$context_boost)) {
    if (grepl(ctx_name, context, ignore.case = TRUE)) {
      return(keywords$context_boost[[ctx_name]])
    }
  }

  return(character(0))
}


#' Extract Main Issue Keywords from Context
#'
#' Helper function to extract keywords from user's main issue description
#'
#' @param main_issue User-provided main issue description
#' @return Character vector of extracted keywords
#' @export
extract_issue_keywords <- function(main_issue) {
  if (is.null(main_issue) || nchar(main_issue) == 0) {
    return(character(0))
  }

  main_issue_lower <- tolower(main_issue)

  # Common issue keywords
  issue_patterns <- list(
    fishing = c("fish", "catch", "stock", "quota", "overfish", "trawl"),
    eutrophication = c("eutroph", "nutrient", "nitrogen", "phosphor", "algal", "bloom"),
    tourism = c("tourism", "tourist", "recreation", "visitor", "cruise"),
    pollution = c("pollut", "contamin", "toxic", "chemical", "oil", "plastic", "litter"),
    habitat_loss = c("habitat", "loss", "degrad", "destruction", "coastal development"),
    climate = c("climate", "warming", "acidif", "temperature", "sea level")
  )

  # Find matching patterns
  matched_keywords <- character(0)
  for (issue_type in names(issue_patterns)) {
    for (pattern in issue_patterns[[issue_type]]) {
      if (grepl(pattern, main_issue_lower)) {
        matched_keywords <- c(matched_keywords, issue_type)
        break
      }
    }
  }

  return(unique(matched_keywords))
}
