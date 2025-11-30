# global.R
# Global variables, package loading, and function sourcing for MarineSABRES SES Shiny App

# ============================================================================
# PACKAGE LOADING
# ============================================================================

# Suppress package startup messages
suppressPackageStartupMessages({

  # Core Shiny packages
  library(shiny)
  library(shinydashboard)
  library(shinyWidgets)
  library(shinyjs)
  library(shinyBS)

  # Data manipulation
  library(tidyverse)
  library(DT)
  library(openxlsx)
  library(jsonlite)
  library(digest)  # For ISA change detection in reactive pipeline

  # Network visualization and analysis
  library(igraph)
  library(visNetwork)
  library(ggraph)
  library(tidygraph)

  # Plotting
  library(ggplot2)
  library(plotly)
  library(dygraphs)
  library(xts)

  # Project management
  library(timevis)

  # Export/Reporting
  library(rmarkdown)
  library(htmlwidgets)

  # Internationalization
  library(shiny.i18n)

})

# ============================================================================
# HELPER OPERATORS
# ============================================================================

# Define the %||% operator for NULL coalescing (return right side if left is NULL)
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

# Define the %|||% operator for NULL or NA coalescing (return right side if left is NULL or NA)
`%|||%` <- function(a, b) {
  if (is.null(a) || (length(a) == 1 && is.na(a))) b else a
}

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

# Read version from VERSION file (single source of truth)
APP_VERSION <- tryCatch({
  version_text <- readLines("VERSION", warn = FALSE)[1]
  trimws(version_text)
}, error = function(e) {
  "1.0.0-unknown"  # Fallback if VERSION file not found
})

# Read detailed version info from VERSION_INFO.json
VERSION_INFO <- tryCatch({
  jsonlite::fromJSON("VERSION_INFO.json")
}, error = function(e) {
  list(
    version = APP_VERSION,
    version_name = "Unknown",
    status = "unknown",
    release_date = as.character(Sys.Date())
  )
})

# ============================================================================
# INTERNATIONALIZATION (i18n) CONFIGURATION
# ============================================================================

# Check if modular translations should be used (can be controlled via env var)
USE_MODULAR_TRANSLATIONS <- Sys.getenv("USE_MODULAR_TRANSLATIONS", "TRUE") == "TRUE"

if (USE_MODULAR_TRANSLATIONS) {
  # Source translation loader
  source("functions/translation_loader.R")

  # Check debug mode
  DEBUG_I18N <- getOption("marinesabres.debug_i18n", FALSE) ||
                Sys.getenv("DEBUG_I18N", "FALSE") == "TRUE"

  # Initialize modular translation system with wrapper
  if (DEBUG_I18N) {
    cat("[I18N] Using modular translation system with wrapper\n")
  }

  translation_system <- init_translation_system(
    base_path = "translations",
    mapping_path = "scripts/reverse_key_mapping.json",
    validate = DEBUG_I18N,
    debug = DEBUG_I18N,
    persistent = TRUE  # Use persistent file to avoid session cleanup issues
  )

  # Extract components from translation system
  i18n_translator <- translation_system$translator  # Original shiny.i18n Translator object
  t_ <- translation_system$wrapper                  # Wrapper function for namespaced keys
  translation_file <- translation_system$file        # Path to merged JSON

  # Create an i18n wrapper object that makes i18n$t() use namespaced keys
  # This allows existing code using i18n$t("namespaced.key") to work seamlessly
  i18n <- list(
    t = t_,  # Wrapper function for translation
    set_translation_language = function(lang) {
      i18n_translator$set_translation_language(lang)
    },
    get_translation_language = function() {
      i18n_translator$get_translation_language()
    },
    get_translations = function() {
      i18n_translator$get_translations()
    },
    use_js = function() {
      i18n_translator$use_js()
    },
    get_languages = function() {
      i18n_translator$get_languages()
    },
    get_key_translation = function() {
      i18n_translator$get_key_translation()
    },
    translator = i18n_translator  # Access to underlying translator if needed
  )
  class(i18n) <- c("wrapped_translator", "list")

  # Verify translation file exists
  if (!file.exists(translation_file)) {
    stop("[I18N] FATAL: Translation file not created. Check translations directory.")
  }

  if (DEBUG_I18N) {
    cat(sprintf("[I18N] Pure modular translation system with wrapper initialized\n"))
    cat(sprintf("[I18N] Translation file: %s\n", translation_file))
    cat(sprintf("[I18N] File size: %s KB\n", round(file.info(translation_file)$size / 1024, 1)))
    cat(sprintf("[I18N] Use i18n$t(\"namespaced.key\") or t_(\"namespaced.key\")\n"))
  }

  # Note: No cleanup needed for persistent translation file
  # The file is kept in translations/_merged_translations.json
  # and will be overwritten on next initialization
} else {
  # Fallback to monolithic translation file
  cat("[I18N] Using legacy monolithic translation file\n")
  i18n_translator <- Translator$new(
    translation_json_path = "translations/translation.json.backup"
  )
  # Wrap in same structure for consistency
  i18n <- list(
    t = function(key) i18n_translator$t(key),
    set_translation_language = function(lang) {
      i18n_translator$set_translation_language(lang)
    },
    get_translation_language = function() {
      i18n_translator$get_translation_language()
    },
    get_translations = function() {
      i18n_translator$get_translations()
    },
    use_js = function() {
      i18n_translator$use_js()
    },
    get_languages = function() {
      i18n_translator$get_languages()
    },
    get_key_translation = function() {
      i18n_translator$get_key_translation()
    },
    translator = i18n_translator  # Access to underlying translator
  )
  class(i18n) <- c("wrapped_translator", "list")
}

# Set default language to English
i18n$set_translation_language("en")

# Available languages
AVAILABLE_LANGUAGES <- list(
  "en" = list(name = "English", flag = "🇬🇧"),
  "es" = list(name = "Español", flag = "🇪🇸"),
  "fr" = list(name = "Français", flag = "🇫🇷"),
  "de" = list(name = "Deutsch", flag = "🇩🇪"),
  "lt" = list(name = "Lietuvių", flag = "🇱🇹"),
  "pt" = list(name = "Português", flag = "🇵🇹"),
  "it" = list(name = "Italiano", flag = "🇮🇹"),
  "no" = list(name = "Norsk", flag = "🇳🇴")
)

# ============================================================================
# SOURCE HELPER FUNCTIONS
# ============================================================================

# UI helper functions
source("functions/ui_helpers.R")

# Template loading functions (for JSON templates)
source("functions/template_loader.R", local = TRUE)

# Data structure functions
source("functions/data_structure.R", local = TRUE)

# Network analysis functions
source("functions/network_analysis.R", local = TRUE)

# visNetwork helper functions
source("functions/visnetwork_helpers.R", local = TRUE)

# Export functions
source("functions/export_functions.R", local = TRUE)

# Report generation functions
source("functions/report_generation.R", local = TRUE)

# Module validation helpers
source("functions/module_validation_helpers.R", local = TRUE)

# Error handling and validation
source("functions/error_handling.R", local = TRUE)

# Reactive pipeline (event-based data flow)
source("functions/reactive_pipeline.R", local = TRUE)

# Navigation helpers (breadcrumbs, progress bars, nav buttons)
source("modules/navigation_helpers.R", local = TRUE)

# Auto-save module
source("modules/auto_save_module.R", local = TRUE)

# ============================================================================
# DEBUG MODE CONFIGURATION
# ============================================================================

# Enable/disable debug logging via environment variable
# Set MARINESABRES_DEBUG=TRUE in .Renviron or before running the app to enable debug logs
# Default is FALSE for production use
DEBUG_MODE <- Sys.getenv("MARINESABRES_DEBUG", "FALSE") == "TRUE"

#' Debug logging helper function
#'
#' Conditionally prints debug messages based on DEBUG_MODE flag.
#' In production (DEBUG_MODE=FALSE), these calls are silently skipped.
#'
#' @param message Character string to log
#' @param context Optional context string (e.g., "TEMPLATE", "NETWORK_ANALYSIS")
#' @export
debug_log <- function(message, context = NULL) {
  if (DEBUG_MODE) {
    if (!is.null(context)) {
      cat(sprintf("[%s] %s\n", context, message))
    } else {
      cat(message, "\n")
    }
  }
}

# Print debug mode status on startup
if (DEBUG_MODE) {
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  DEBUG MODE ENABLED - Verbose logging is active\n")
  cat("  Set MARINESABRES_DEBUG=FALSE to disable debug logs\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
} else {
  cat("Production mode - Debug logging disabled\n")
  cat("Set MARINESABRES_DEBUG=TRUE to enable verbose logging\n\n")
}

# ============================================================================
# GLOBAL VARIABLES AND CONSTANTS
# ============================================================================

# Reactive pipeline debouncing (milliseconds)
# Delay before triggering CLD regeneration after ISA changes
# Prevents excessive regenerations during rapid consecutive edits
ISA_DEBOUNCE_MS <- as.numeric(Sys.getenv("MARINESABRES_ISA_DEBOUNCE_MS", "500"))

if (DEBUG_MODE) {
  cat(sprintf("ISA debounce delay: %d ms\n", ISA_DEBOUNCE_MS))
}

# DAPSI(W)R(M) element types
DAPSIWRM_ELEMENTS <- c(
  "Drivers",
  "Activities",
  "Pressures",
  "Marine Processes & Functioning",
  "Ecosystem Services",
  "Goods & Benefits",
  "Responses"
)

# Color scheme for DAPSI(W)R(M) elements
ELEMENT_COLORS <- list(
  "Drivers" = "#776db3",                           # Purple (Kumu style)
  "Activities" = "#5abc67",                        # Green (Kumu style)
  "Pressures" = "#fec05a",                         # Orange (Kumu style)
  "Marine Processes & Functioning" = "#bce2ee",    # Light Blue (Kumu style)
  "Ecosystem Services" = "#313695",                # Dark Blue (Kumu style)
  "Goods & Benefits" = "#fff1a2",                  # Light Yellow (Kumu style)
  "Responses" = "#9C27B0",                         # Purple for management responses
  "Measures" = "#795548"                           # Brown for management measures/instruments
)

# Node shapes for each element type (following Kumu style guide)
# visNetwork available shapes: dot, diamond, square, triangle, triangleDown,
# star, hexagon, ellipse, database, text, circularImage, circle
# Note: hexagon is available! Octagon is not, using star as closest alternative
ELEMENT_SHAPES <- list(
  "Drivers" = "star",                            # Kumu: octagon → star (closest available)
  "Activities" = "hexagon",                      # Kumu: hexagon → hexagon (EXACT MATCH!)
  "Pressures" = "diamond",                       # Kumu: diamond (EXACT MATCH!)
  "Marine Processes & Functioning" = "dot",      # Kumu: pill → dot (circular, label outside)
  "Ecosystem Services" = "square",               # Kumu: square (EXACT MATCH!)
  "Goods & Benefits" = "triangle",               # Kumu: triangle (EXACT MATCH!)
  "Responses" = "triangleDown"                   # Inverted triangle for management responses
)

# Edge colors (following Kumu style guide)
EDGE_COLORS <- list(
  reinforcing = "#80b8d7",    # Light blue (positive from Kumu)
  opposing = "#dc131e"        # Red (negative from Kumu)
)

# Demonstration Areas
DA_SITES <- c(
  "Tuscan Archipelago",
  "Arctic Northeast Atlantic",
  "Macaronesia"
)

# Stakeholder types (Newton & Elliott, 2016)
STAKEHOLDER_TYPES <- c(
  "Inputters",
  "Extractors",
  "Regulators",
  "Affectees",
  "Beneficiaries",
  "Influencers"
)

# ============================================================================
# ENTRY POINT SYSTEM (Marine Management DSS & Toolbox)
# Based on: Elliott, M. - Discussion Document V3.0
# ============================================================================

# EP0: Marine Manager Typology (Who am I?)
EP0_MANAGER_ROLES <- list(
  list(
    id = "policy_creator",
    label = "Policy Creator",
    description = "Someone creating marine management policies",
    icon = "landmark",
    typical_tasks = c("Policy development", "Strategic planning", "Legislation design")
  ),
  list(
    id = "policy_implementer",
    label = "Policy Implementer (Regulator)",
    description = "Someone implementing and enforcing policies",
    icon = "gavel",
    typical_tasks = c("Compliance monitoring", "Enforcement", "Permitting")
  ),
  list(
    id = "policy_advisor",
    label = "Policy Advisor",
    description = "Someone advising those who create and implement policies",
    icon = "user-tie",
    typical_tasks = c("Scientific advice", "Evidence synthesis", "Impact assessment")
  ),
  list(
    id = "activity_manager",
    label = "Activity Manager (Regulator)",
    description = "Manager of specific marine activities",
    icon = "tasks",
    typical_tasks = c("Operations management", "Resource allocation", "Activity coordination")
  ),
  list(
    id = "activity_advisor",
    label = "Activity Advisor",
    description = "Advisor to managers of marine activities",
    icon = "hands-helping",
    typical_tasks = c("Technical consulting", "Best practice guidance", "Training")
  ),
  list(
    id = "engo_worker",
    label = "eNGO Worker",
    description = "Environmental NGO worker influencing or lobbying decisions",
    icon = "leaf",
    typical_tasks = c("Advocacy", "Public campaigns", "Policy influence")
  ),
  list(
    id = "fisher",
    label = "Fisher (Influencer)",
    description = "Fishers as industry influencers",
    icon = "fish",
    typical_tasks = c("Fishing operations", "Industry representation", "Traditional knowledge")
  ),
  list(
    id = "other_industry",
    label = "Other Industry (Influencer)",
    description = "Non-fishing industry stakeholders",
    icon = "industry",
    typical_tasks = c("Industry operations", "Business advocacy", "Economic development")
  ),
  list(
    id = "sme",
    label = "SME (Influencer)",
    description = "Small/medium enterprise influencers",
    icon = "store",
    typical_tasks = c("Business operations", "Local development", "Innovation")
  ),
  list(
    id = "educator_researcher",
    label = "Educator/Researcher",
    description = "Educators and researchers as influencers",
    icon = "graduation-cap",
    typical_tasks = c("Research", "Education", "Knowledge generation")
  )
)

# EP1: Drivers (Basic Human Needs) (Why do I care?)
EP1_BASIC_NEEDS <- list(
  list(
    id = "welfare",
    label = "Welfare",
    subtitle = "Safety, Health, Security",
    description = "Ensuring safety, health, and security of coastal communities",
    icon = "shield-alt",
    color = "#3498db",
    examples = c("Coastal protection", "Water quality", "Food safety", "Disaster preparedness")
  ),
  list(
    id = "resource_provision",
    label = "Resource Provision",
    subtitle = "Space, Food, Water",
    description = "Providing essential resources from the marine environment",
    icon = "box-open",
    color = "#27ae60",
    examples = c("Fishing grounds", "Aquaculture sites", "Renewable energy space", "Water resources")
  ),
  list(
    id = "employment",
    label = "Employment & Resource Use",
    subtitle = "Livelihoods, Jobs",
    description = "Supporting employment and sustainable resource use",
    icon = "briefcase",
    color = "#f39c12",
    examples = c("Fishing jobs", "Tourism employment", "Marine industries", "Blue economy")
  ),
  list(
    id = "enjoyment",
    label = "Relaxation & Enjoyment",
    subtitle = "Satisfaction, Culture, Aesthetics",
    description = "Enabling recreation, cultural connection, and aesthetic appreciation",
    icon = "umbrella-beach",
    color = "#9b59b6",
    examples = c("Beach access", "Marine parks", "Cultural heritage", "Scenic beauty")
  )
)

# EP2: Activity Sectors / MSFD Themes (What activities?)
EP2_ACTIVITY_SECTORS <- list(
  list(
    id = "physical_restructuring",
    label = "Physical Restructuring",
    description = "Rivers, coastline, seabed restructuring; water management",
    icon = "tractor",
    msfd_descriptor = "D6, D7",
    examples = c("Coastal engineering", "Dredging", "Land reclamation", "Water diversion")
  ),
  list(
    id = "nonliving_extraction",
    label = "Non-Living Resource Extraction",
    description = "Aggregates, minerals, oil, gas extraction",
    icon = "gem",
    msfd_descriptor = "D3, D11",
    examples = c("Sand/gravel extraction", "Oil/gas production", "Mineral mining")
  ),
  list(
    id = "energy_production",
    label = "Energy Production",
    description = "Offshore wind, tidal, wave, oil/gas energy",
    icon = "bolt",
    msfd_descriptor = "D11",
    examples = c("Offshore wind farms", "Tidal energy", "Wave power", "Oil platforms")
  ),
  list(
    id = "living_extraction",
    label = "Living Resource Extraction",
    description = "Fishing, whaling, seaweed harvesting",
    icon = "fish",
    msfd_descriptor = "D3, D4",
    examples = c("Commercial fishing", "Recreational fishing", "Seaweed collection")
  ),
  list(
    id = "cultivation",
    label = "Living Resource Cultivation",
    description = "Aquaculture, mariculture operations",
    icon = "seedling",
    msfd_descriptor = "D5",
    examples = c("Fish farming", "Shellfish cultivation", "Seaweed farming")
  ),
  list(
    id = "transport",
    label = "Transport",
    description = "Shipping, ports, navigation",
    icon = "ship",
    msfd_descriptor = "D11",
    examples = c("Commercial shipping", "Ferry services", "Port operations", "Navigation routes")
  ),
  list(
    id = "urban_industrial",
    label = "Urban & Industrial Uses",
    description = "Coastal development, carbon storage",
    icon = "city",
    msfd_descriptor = "D8, D9",
    examples = c("Coastal infrastructure", "Industrial facilities", "Carbon capture and storage")
  ),
  list(
    id = "tourism_leisure",
    label = "Tourism & Leisure",
    description = "Recreation, diving, yachting",
    icon = "umbrella-beach",
    msfd_descriptor = "D11",
    examples = c("Beach tourism", "Diving", "Sailing", "Coastal recreation")
  ),
  list(
    id = "security_defense",
    label = "Security/Defense",
    description = "Military operations, surveillance",
    icon = "shield-alt",
    msfd_descriptor = "D11",
    examples = c("Naval operations", "Coastal surveillance", "Defense installations")
  ),
  list(
    id = "education_research",
    label = "Education & Research",
    description = "Monitoring, scientific studies",
    icon = "flask",
    msfd_descriptor = "All",
    examples = c("Marine research", "Environmental monitoring", "Educational programs")
  ),
  list(
    id = "conservation_restoration",
    label = "Conservation & Restoration",
    description = "Protected areas, habitat restoration",
    icon = "tree",
    msfd_descriptor = "D1, D4, D6",
    examples = c("Marine protected areas", "Habitat restoration", "Species conservation")
  ),
  list(
    id = "mixed_use",
    label = "Multiple/Mixed Use",
    description = "Areas with multiple overlapping activities",
    icon = "layer-group",
    msfd_descriptor = "All",
    examples = c("Multi-use zones", "Spatial conflicts", "Integrated management")
  )
)

# EP3: Risks & Hazards (What threats?)
EP3_RISKS_HAZARDS <- list(
  # Natural Hazards
  list(
    id = "hydro_flood",
    label = "Flooding & Storm Surge",
    category = "Natural",
    temporal = "Acute",
    description = "Flooding, storm surge, tsunamis",
    icon = "water",
    severity = "High"
  ),
  list(
    id = "physio_natural_chronic",
    label = "Coastal Erosion",
    category = "Natural",
    temporal = "Chronic",
    description = "Coastal erosion, long-term sediment changes",
    icon = "mountain",
    severity = "Medium"
  ),
  list(
    id = "physio_human_chronic",
    label = "Coastal Development Impacts",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Land reclamation, space removal",
    icon = "bulldozer",
    severity = "High"
  ),
  list(
    id = "physio_acute",
    label = "Landslides & Cliff Failures",
    category = "Natural",
    temporal = "Acute",
    description = "Cliff failure, landslides",
    icon = "exclamation-triangle",
    severity = "High"
  ),
  list(
    id = "climate_acute",
    label = "Extreme Weather Events",
    category = "Natural",
    temporal = "Acute",
    description = "Extreme storms, heat waves",
    icon = "cloud-showers-heavy",
    severity = "High"
  ),
  list(
    id = "climate_chronic",
    label = "Climate Change (Sea-level, Acidification)",
    category = "Natural",
    temporal = "Chronic",
    description = "Sea-level rise, NAO changes, ocean acidification",
    icon = "temperature-high",
    severity = "Critical"
  ),
  list(
    id = "tectonic_acute",
    label = "Earthquakes",
    category = "Natural",
    temporal = "Acute",
    description = "Earthquakes, land slips",
    icon = "frown",
    severity = "High"
  ),
  list(
    id = "tectonic_chronic",
    label = "Land Subsidence",
    category = "Natural",
    temporal = "Chronic",
    description = "Subsidence, isostatic rebound",
    icon = "arrows-alt-v",
    severity = "Medium"
  ),
  list(
    id = "bio_micro",
    label = "Pollution & Pathogens",
    category = "Anthropogenic",
    temporal = "Both",
    description = "Sewage pollution, pathogens",
    icon = "bacterium",
    severity = "Medium"
  ),
  list(
    id = "bio_macro",
    label = "Invasive Species & Harmful Blooms",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Non-indigenous species, harmful algal blooms",
    icon = "dna",
    severity = "High"
  ),
  list(
    id = "tech_introduced",
    label = "Infrastructure & Dredging Impacts",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Infrastructure, dredging, sediment disposal",
    icon = "cogs",
    severity = "Medium"
  ),
  list(
    id = "tech_extractive",
    label = "Fishing & Resource Extraction",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Fishing impacts, aggregate extraction",
    icon = "industry",
    severity = "High"
  ),
  list(
    id = "chem_acute",
    label = "Oil Spills & Chemical Accidents",
    category = "Anthropogenic",
    temporal = "Acute",
    description = "Oil spills, chemical accidents",
    icon = "oil-can",
    severity = "Critical"
  ),
  list(
    id = "chem_chronic",
    label = "Chronic Pollution",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Diffuse pollution, point-source contaminants",
    icon = "flask-poison",
    severity = "High"
  ),
  list(
    id = "geopolitical_acute",
    label = "Conflicts & Civil Unrest",
    category = "Anthropogenic",
    temporal = "Acute",
    description = "Wars, terrorism, civil unrest",
    icon = "bomb",
    severity = "Critical"
  ),
  list(
    id = "geopolitical_chronic",
    label = "Migration & Social Displacement",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Human migrations, refugee crises, conflicts",
    icon = "users",
    severity = "High"
  ),
  # Social & Economic Risks
  list(
    id = "social_inequality",
    label = "Social Inequality & Injustice",
    category = "Social",
    temporal = "Chronic",
    description = "Poverty, inequality, lack of access to resources",
    icon = "balance-scale",
    severity = "High"
  ),
  list(
    id = "food_insecurity",
    label = "Food & Livelihood Security",
    category = "Social",
    temporal = "Both",
    description = "Threats to food security, livelihoods, employment",
    icon = "utensils",
    severity = "High"
  ),
  list(
    id = "health_wellbeing",
    label = "Public Health & Wellbeing",
    category = "Social",
    temporal = "Both",
    description = "Health risks, disease, mental health impacts",
    icon = "heartbeat",
    severity = "High"
  ),
  list(
    id = "cultural_heritage",
    label = "Cultural Heritage Loss",
    category = "Social",
    temporal = "Chronic",
    description = "Loss of traditional practices, cultural identity, heritage sites",
    icon = "landmark",
    severity = "Medium"
  )
)

# EP4: Topics (What knowledge domain?)
EP4_TOPICS <- list(
  # Foundation
  list(id = "basic_concepts", label = "Basic Concepts & Fundamental Understanding", domain = "Foundation", icon = "book"),
  list(id = "ecosystem_structure", label = "Ecosystem Structure & Functioning", domain = "Natural", icon = "project-diagram"),

  # Natural Domain
  list(id = "ecosystem_services", label = "Ecosystem Services (natural domain)", domain = "Natural", icon = "leaf"),
  list(id = "biodiversity", label = "Biodiversity Loss (habitats & species)", domain = "Natural", icon = "dove"),
  list(id = "nis", label = "Non-Indigenous Species", domain = "Natural", icon = "bug"),
  list(id = "climate", label = "Climate Change", domain = "Natural", icon = "temperature-high"),
  list(id = "anthropogenic_effects", label = "Other Anthropogenic Effects", domain = "Natural", icon = "smog"),
  list(id = "recovery", label = "Ecosystem Recovery & Remediation", domain = "Natural", icon = "medkit"),

  # Economic Domain
  list(id = "fisheries_econ", label = "Fisheries - Economics Aspects", domain = "Economic", icon = "coins"),
  list(id = "resource_econ", label = "Other Resource Extraction (energy, space)", domain = "Economic", icon = "battery-full"),
  list(id = "goods_benefits", label = "Economic Aspects - Societal Goods & Benefits", domain = "Economic", icon = "hand-holding-usd"),

  # Governance
  list(id = "governance", label = "Governance & Management", domain = "Governance", icon = "balance-scale"),
  list(id = "policy_derivation", label = "Policy Derivation", domain = "Governance", icon = "file-signature"),
  list(id = "policy_implementation", label = "Policy Implementation", domain = "Governance", icon = "tasks"),
  list(id = "conservation", label = "Marine Conservation", domain = "Governance", icon = "shield-alt"),
  list(id = "planning", label = "Marine Planning", domain = "Governance", icon = "map-marked-alt"),

  # Social
  list(id = "societal", label = "Societal & Cultural Considerations", domain = "Social", icon = "users"),
  list(id = "citizenship", label = "Marine Citizenship", domain = "Social", icon = "user-check"),

  # Methodological
  list(id = "skills_data", label = "Scientific Skills, Mapping, Evidence & Data", domain = "Methodological", icon = "database"),
  list(id = "methods", label = "Methods, Techniques, Tools", domain = "Methodological", icon = "wrench")
)

# EP5: Management Solutions (10 Tenets) (How to solve?)
EP5_MANAGEMENT_TENETS <- list(
  list(
    id = "ecological",
    label = "Ecologically Sustainable",
    description = "Maintain ecosystem integrity and function",
    icon = "leaf",
    color = "#27ae60",
    principle = "Ecology, natural environment"
  ),
  list(
    id = "technological",
    label = "Technologically Feasible",
    description = "Solutions must be practically achievable",
    icon = "cogs",
    color = "#3498db",
    principle = "Technology, techniques"
  ),
  list(
    id = "economic",
    label = "Economically Viable",
    description = "Cost-effective and financially sustainable",
    icon = "coins",
    color = "#f39c12",
    principle = "Economics, valuation"
  ),
  list(
    id = "social",
    label = "Socially Desirable/Tolerable",
    description = "Acceptable to affected communities",
    icon = "users",
    color = "#9b59b6",
    principle = "Society, stakeholders"
  ),
  list(
    id = "legal",
    label = "Legally Permissible",
    description = "Compliant with legal frameworks",
    icon = "gavel",
    color = "#34495e",
    principle = "Laws, agreements, regulations"
  ),
  list(
    id = "administrative",
    label = "Administratively Achievable",
    description = "Within institutional capabilities",
    icon = "building",
    color = "#16a085",
    principle = "Authorities, agencies, capacity"
  ),
  list(
    id = "political",
    label = "Politically Expedient",
    description = "Aligned with political priorities",
    icon = "landmark",
    color = "#c0392b",
    principle = "Politics, policies, timing"
  ),
  list(
    id = "ethical",
    label = "Ethically Defensible/Morally Correct",
    description = "Consistent with ethical principles",
    icon = "hands-helping",
    color = "#8e44ad",
    principle = "Ethics, morals, values"
  ),
  list(
    id = "cultural",
    label = "Culturally Inclusive",
    description = "Respects cultural diversity",
    icon = "globe",
    color = "#d35400",
    principle = "Culture, aesthetics, heritage"
  ),
  list(
    id = "communicable",
    label = "Effectively Communicable",
    description = "Can be clearly explained to stakeholders",
    icon = "comments",
    color = "#2980b9",
    principle = "Communication, literacy, transparency"
  )
)

# Connection strength options
CONNECTION_STRENGTH <- c("strong", "medium", "weak")

# Connection polarity options
CONNECTION_POLARITY <- c("+", "-")

# Connection confidence levels (1-5 scale)
CONFIDENCE_LEVELS <- 1:5

# Connection confidence labels
CONFIDENCE_LABELS <- c(
  "1" = "Very Low",
  "2" = "Low",
  "3" = "Medium",
  "4" = "High",
  "5" = "Very High"
)

# Connection confidence opacity mapping (for visual feedback)
CONFIDENCE_OPACITY <- c(
  "1" = 0.3,
  "2" = 0.5,
  "3" = 0.7,
  "4" = 0.85,
  "5" = 1.0
)

# Default confidence level
CONFIDENCE_DEFAULT <- 3

# Ecosystem service categories
ECOSYSTEM_SERVICE_CATEGORIES <- c(
  "Provisioning",
  "Regulating",
  "Cultural",
  "Supporting"
)

# Pressure types
PRESSURE_TYPES <- c(
  "Exogenic (ExP)",
  "Endogenic Managed (EnMP)"
)

# Spatial scales
SPATIAL_SCALES <- c(
  "Local",
  "Regional",
  "National",
  "International"
)

# Activity scales
ACTIVITY_SCALES <- c(
  "Individual",
  "Group/Sector",
  "National",
  "International"
)

# ============================================================================
# DEFAULT VALUES
# ============================================================================

# Default node size
DEFAULT_NODE_SIZE <- 25

# Default edge width
DEFAULT_EDGE_WIDTH <- 2

# Default hierarchy level separation
DEFAULT_LEVEL_SEPARATION <- 150

# Maximum loop length for detection
DEFAULT_MAX_LOOP_LENGTH <- 10

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Generate unique ID
generate_id <- function(prefix = "ID") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", 
         sample(1000:9999, 1))
}

# Format date for display
format_date_display <- function(date) {
  format(as.Date(date), "%d %B %Y")
}

# Validate email
is_valid_email <- function(email) {
  grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)
}

# Convert adjacency matrix value to list with confidence
# Format: "+strong:4" or "-medium:3" where :X is confidence (1-5)
# If confidence is omitted, defaults to CONFIDENCE_DEFAULT (medium confidence)
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
# DATA VALIDATION FUNCTIONS
# ============================================================================

# Validate DAPSI(W)R(M) element data
validate_element_data <- function(data, element_type) {
  errors <- c()
  
  # Check required columns
  required_cols <- c("id", "name", "indicator")
  missing_cols <- setdiff(required_cols, names(data))
  
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Missing required columns:", 
                             paste(missing_cols, collapse = ", ")))
  }
  
  # Check for duplicate IDs
  if (any(duplicated(data$id))) {
    errors <- c(errors, "Duplicate IDs found")
  }
  
  # Check for empty names
  if (any(is.na(data$name) | data$name == "")) {
    errors <- c(errors, "Empty names found")
  }
  
  return(errors)
}

# Validate adjacency matrix
validate_adjacency_matrix <- function(adj_matrix) {
  errors <- c()
  
  # Check if matrix
  if (!is.matrix(adj_matrix)) {
    errors <- c(errors, "Not a valid matrix")
    return(errors)
  }
  
  # Check dimensions
  if (nrow(adj_matrix) == 0 || ncol(adj_matrix) == 0) {
    errors <- c(errors, "Matrix has zero dimensions")
  }
  
  # Check values
  valid_values <- c("", NA, 
                   paste0("+", CONNECTION_STRENGTH),
                   paste0("-", CONNECTION_STRENGTH))
  
  invalid_values <- !adj_matrix %in% valid_values
  if (any(invalid_values, na.rm = TRUE)) {
    errors <- c(errors, "Invalid connection values found")
  }
  
  return(errors)
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Log message to console and file
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

# Initialize session data
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
# SECURITY & VALIDATION HELPER FUNCTIONS
# ============================================================================

# Sanitize color values to prevent XSS
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

# Sanitize filename to prevent path traversal
sanitize_filename <- function(name) {
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
  name <- substr(name, 1, 50)

  # Ensure not empty
  if (nchar(name) == 0) {
    name <- "project"
  }

  return(name)
}

# Validate project data structure
validate_project_structure <- function(data) {
  # Check if data is a list
  if (!is.list(data)) {
    return(FALSE)
  }

  # Essential keys (must have)
  essential_keys <- c("project_id", "project_name", "data")

  if (!all(essential_keys %in% names(data))) {
    return(FALSE)
  }

  # Check that data is a list
  if (!is.list(data$data)) {
    return(FALSE)
  }

  # Basic type validation
  if (!is.character(data$project_id) || length(data$project_id) != 1) {
    return(FALSE)
  }

  if (!is.character(data$project_name) || length(data$project_name) != 1) {
    return(FALSE)
  }

  # Date validation - accept both 'created' and 'created_at' field names
  has_created <- "created" %in% names(data)
  has_created_at <- "created_at" %in% names(data)

  if (!has_created && !has_created_at) {
    return(FALSE)
  }

  # Validate the date field that exists
  created_field <- if (has_created) data$created else data$created_at
  if (!inherits(created_field, "POSIXct") && !is.character(created_field)) {
    return(FALSE)
  }

  # Validate last_modified if present (optional for backward compatibility)
  if ("last_modified" %in% names(data)) {
    if (!inherits(data$last_modified, "POSIXct") && !is.character(data$last_modified)) {
      return(FALSE)
    }
  }

  return(TRUE)
}

# Safe nested data accessor
safe_get_nested <- function(data, ..., default = NULL) {
  keys <- list(...)
  result <- data

  for (key in keys) {
    if (is.null(result)) {
      return(default)
    }

    if (is.list(result) && key %in% names(result)) {
      result <- result[[key]]
    } else {
      return(default)
    }
  }

  return(result)
}

# Validate ISA exercise data
# Generic validation for ISA data frames
# @param data data.frame - The data frame to validate
# @param exercise_name character - Name of the exercise for error messages
# @param required_cols character vector - Required column names
# @return character vector of error messages (empty if valid)
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
# APPLICATION SETTINGS
# ============================================================================

# Maximum file upload size (100 MB)
options(shiny.maxRequestSize = 100 * 1024^2)

# Enable bookmarking
enableBookmarking(store = "url")

# ============================================================================
# LOAD EXAMPLE DATA (if available)
# ============================================================================

if (file.exists("data/example_isa_data.R")) {
  source("data/example_isa_data.R", local = TRUE)
}

# ============================================================================
# INITIALIZATION MESSAGE
# ============================================================================

log_message("Global environment loaded successfully")
log_message(paste("Loaded", length(DAPSIWRM_ELEMENTS), "DAPSI(W)R(M) element types"))
log_message(paste("Application version:", APP_VERSION))
log_message(paste("Version name:", VERSION_INFO$version_name))
log_message(paste("Release status:", VERSION_INFO$status))
