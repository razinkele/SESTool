# global.R
# Global variables, package loading, and function sourcing for MarineSABRES SES Shiny App

# ============================================================================
# PACKAGE LOADING
# ============================================================================

# Suppress package startup messages
suppressPackageStartupMessages({

  # Core Shiny packages
  library(shiny)
  library(bs4Dash)  # Modern Bootstrap 4 dashboard framework
  library(shinyWidgets)
  library(shinyjs)
  library(shinyBS)
  library(shinyFiles)  # Directory/file selection widgets

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
# PROJECT ROOT ESTABLISHMENT
# ============================================================================

# Establish project root for reliable file sourcing
if (!exists("PROJECT_ROOT")) {
  # Find project root by looking for app.R
  find_project_root <- function(start_dir = getwd()) {
    dir <- start_dir
    # Look up directory tree for app.R
    while (dir != dirname(dir)) {  # Not at filesystem root
      if (file.exists(file.path(dir, "app.R"))) {
        return(dir)
      }
      dir <- dirname(dir)
    }
    # Fallback to current directory
    return(start_dir)
  }

  PROJECT_ROOT <- find_project_root()
  if (DEBUG_MODE <- (Sys.getenv("MARINESABRES_DEBUG", "FALSE") == "TRUE")) {
    message("Project root: ", PROJECT_ROOT)
  }
}

# Helper to get project file path
get_project_file <- function(...) {
  file.path(PROJECT_ROOT, ...)
}

# ============================================================================
# STARTUP DIRECTORY CHECKS
# ============================================================================

# Check required directories at startup
startup_check_directories <- function() {
  cat("\n")
  cat("================================================================================\n")
  cat(" MarineSABRES SES Tool - Startup Directory Check\n")
  cat("================================================================================\n")
  cat("\n")
  cat("  Working Directory: ", getwd(), "\n", sep = "")
  cat("  Project Root:      ", PROJECT_ROOT, "\n", sep = "")
  cat("\n")

  # Required directories (must exist for app to work)
  required_dirs <- c("modules", "functions", "server", "www", "data", "translations")

  # Optional directories (app works without them but features disabled)
  optional_dirs <- c("SESModels", "config", "docs")

  cat("  Required Directories:\n")
  all_required_ok <- TRUE
  for (dir in required_dirs) {
    dir_path <- file.path(PROJECT_ROOT, dir)
    if (dir.exists(dir_path)) {
      cat("    [OK] ", dir, "\n", sep = "")
    } else {
      cat("    [MISSING] ", dir, " - CRITICAL!\n", sep = "")
      all_required_ok <- FALSE
    }
  }

  cat("\n  Optional Directories:\n")
  for (dir in optional_dirs) {
    dir_path <- file.path(PROJECT_ROOT, dir)
    if (dir.exists(dir_path)) {
      file_count <- length(list.files(dir_path, recursive = TRUE))
      cat("    [OK] ", dir, " (", file_count, " files)\n", sep = "")
    } else {
      cat("    [SKIP] ", dir, " - not found (feature disabled)\n", sep = "")
    }
  }

  cat("\n")

  if (!all_required_ok) {
    cat("  [WARNING] Some required directories are missing!\n")
    cat("  The application may not function correctly.\n")
    cat("\n")
  }

  cat("================================================================================\n")
  cat("\n")

  return(all_required_ok)
}

# Run startup check
startup_check_directories()

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
  "no" = list(name = "Norsk", flag = "🇳🇴"),
  "el" = list(name = "Ελληνικά", flag = "🇬🇷")
)

# ============================================================================
# LOAD CONSTANTS
# ============================================================================

# Load application constants (must be loaded before other functions)
# Note: local = FALSE makes constants available globally
source("constants.R", local = FALSE)

# Application configuration from environment variables
if (file.exists(get_project_file("config", "app_config.R"))) {
  source(get_project_file("config", "app_config.R"), local = FALSE)
}

# ============================================================================
# SOURCE HELPER FUNCTIONS
# ============================================================================

# UI helper functions (global scope for use across modules)
source("functions/ui_helpers.R", local = FALSE)

# Template loading functions (for JSON templates)
source("functions/template_loader.R", local = TRUE)

# DAPSIWRM type inference (keyword-based type guessing from element names)
source("functions/dapsiwrm_type_inference.R", local = FALSE)  # FALSE = global scope

# Universal Excel loader (handles multiple Excel formats for SES models)
source("functions/universal_excel_loader.R", local = FALSE)  # FALSE = global scope

# SES Models loader (for loading pre-built models from Excel files)
source("functions/ses_models_loader.R", local = TRUE)

# Excel import helpers (shared between import_data_module and ses_models_module)
source("functions/excel_import_helpers.R", local = FALSE)  # FALSE = global scope for module access

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

# CLD validation utilities (shared across analysis modules)
source(get_project_file("functions", "cld_validation.R"), local = FALSE)

# Error handling and validation
source("functions/error_handling.R", local = TRUE)

# Reactive pipeline (event-based data flow)
source("functions/reactive_pipeline.R", local = TRUE)

# Async computation helpers (lightweight progress-aware wrappers)
source(get_project_file("functions", "async_helpers.R"), local = FALSE)

# Utility functions (general helper functions)
source("utils.R", local = TRUE)

# Navigation helpers (breadcrumbs, progress bars, nav buttons)
source("modules/navigation_helpers.R", local = TRUE)

# Auto-save module
source("modules/auto_save_module.R", local = TRUE)

# Tutorial system (contextual help for features)
source("modules/tutorial_system.R", local = TRUE)
source("config/tutorial_content.R", local = TRUE)

# Graphical SES Creator system (AI-powered step-by-step network building)
# Note: Knowledge base must be global scope for use by both AI ISA and Graphical SES modules
source("modules/ai_isa_knowledge_base.R", local = FALSE)
source("data/dapsiwrm_element_keywords.R", local = TRUE)
source("functions/dapsiwrm_connection_rules.R", local = TRUE)
source("functions/ses_dynamics.R", local = TRUE)
source("modules/graphical_ses_ai_classifier.R", local = TRUE)
source("modules/graphical_ses_network_builder.R", local = TRUE)
source("modules/graphical_ses_creator_module.R", local = TRUE)
source("modules/connection_review_tabbed.R", local = TRUE)
source("modules/workflow_stepper_module.R", local = TRUE)

# ============================================================================
# OPTIONAL ML ENHANCEMENT (Deep Learning Connection Predictor)
# ============================================================================

# ML can be enabled/disabled via environment variable or user preference
ML_ENABLED <- Sys.getenv("MARINESABRES_ML_ENABLED", "TRUE") == "TRUE"
ML_AVAILABLE <- FALSE  # Will be set to TRUE if model loads successfully

if (ML_ENABLED) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  ML Enhancement: Loading Deep Learning Module\n")
  cat("═══════════════════════════════════════════════════════════\n")

  # Try to load torch package (required for ML)
  tryCatch({
    suppressPackageStartupMessages({
      library(torch)
    })
    cat("✓ torch package loaded\n")

    # Load ML functions
    source("functions/ml_feature_engineering.R", local = TRUE)
    cat("✓ ML feature engineering functions loaded\n")

    # Load Phase 2 ML modules (context embeddings, graph features, active learning, ensemble)
    if (file.exists("functions/ml_context_embeddings.R")) {
      source("functions/ml_context_embeddings.R", local = TRUE)
    }
    if (file.exists("functions/ml_graph_features.R")) {
      source("functions/ml_graph_features.R", local = TRUE)
    }
    if (file.exists("functions/ml_active_learning.R")) {
      source("functions/ml_active_learning.R", local = TRUE)
    }
    if (file.exists("functions/ml_ensemble.R")) {
      source("functions/ml_ensemble.R", local = TRUE)
    }
    if (file.exists("functions/ml_template_matching.R")) {
      source("functions/ml_template_matching.R", local = TRUE)
    }
    if (file.exists("functions/template_versioning.R")) {
      source("functions/template_versioning.R", local = TRUE)
    }

    source("functions/ml_models.R", local = TRUE)
    cat("✓ ML model architecture loaded\n")

    source("functions/ml_inference.R", local = TRUE)
    cat("✓ ML inference API loaded\n")

    source("modules/graphical_ses_ml_enhancer.R", local = TRUE)
    cat("✓ ML enhancer module loaded\n")

    source("functions/ml_feedback_logger.R", local = TRUE)
    cat("✓ ML feedback logger loaded\n")

    # Try to load trained model
    model_path <- "models/connection_predictor_best.pt"
    if (file.exists(model_path)) {
      load_ml_model(model_path)
      ML_AVAILABLE <- TRUE

      model_info <- get_ml_model_info()
      cat(sprintf("\n✓ ML Model Loaded Successfully\n"))
      cat(sprintf("  - Model: %s\n", model_info$architecture))
      cat(sprintf("  - Parameters: %s\n", format(model_info$parameters, big.mark = ",")))
      cat(sprintf("  - Size: %.2f MB\n", model_info$size_mb))
      cat(sprintf("  - Status: Ready for predictions\n"))
    } else {
      cat(sprintf("\n✗ ML model file not found: %s\n", model_path))
      cat("  ML predictions will not be available\n")
      cat("  To enable ML, run: Rscript scripts/train_connection_predictor.R\n")
    }

  }, error = function(e) {
    cat(sprintf("\n✗ ML Enhancement could not be loaded: %s\n", e$message))
    cat("  Falling back to rule-based AI only\n")
    cat("  To enable ML, install torch: install.packages('torch')\n")
    ML_ENABLED <- FALSE
  })

  cat("═══════════════════════════════════════════════════════════\n\n")
} else {
  cat("\nML Enhancement: Disabled (using rule-based AI only)\n")
  cat("Set MARINESABRES_ML_ENABLED=TRUE to enable ML features\n\n")
}

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
#' STANDARDIZED DEBUG LOGGING PATTERN:
#' - Use debug_log() for ALL debug messages (respects DEBUG_MODE)
#' - NEVER use cat() directly for debug messages
#' - Use consistent context tags: SETTINGS, CONFIG, I18N, ML, DIAGNOSTICS, etc.
#' - Format: debug_log("message", "CONTEXT") → outputs "[CONTEXT] message"
#'
#' EXCEPTION: System status messages (ML loading, i18n init) that users should
#' always see use cat() directly - these are informational, not debug messages.
#'
#' @param message Character string to log
#' @param context Optional context string (e.g., "TEMPLATE", "NETWORK_ANALYSIS")
#' @export
#'
#' @examples
#' debug_log("Processing started", "TEMPLATE")  # [TEMPLATE] Processing started
#' debug_log("Found 5 connections")              # Found 5 connections
debug_log <- function(message, context = NULL) {
  if (DEBUG_MODE) {
    if (!is.null(context)) {
      cat(sprintf("[%s] %s\n", context, message))
    } else {
      cat(message, "\n")
    }
  }
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
#' @export
#'
#' @examples
#' sanitize_filename("My Report: 2024 (Final Version)")
#' # Returns: "My Report 2024 Final Version"
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

debug_log(sprintf("ISA debounce delay: %d ms", ISA_DEBOUNCE_MS), "CONFIG")

# NOTE: The following constants are now defined in constants.R:
# - DAPSIWRM_ELEMENTS (MarineSABRES element types)
# - ELEMENT_COLORS (Kumu-style colors for DAPSIWRM elements)
# - ELEMENT_SHAPES (visNetwork shapes for DAPSIWRM elements)
# - EDGE_COLORS (reinforcing/opposing edge colors)
# - DA_SITES (Demonstration Areas)
# - STAKEHOLDER_TYPES (Newton & Elliott, 2016)
# All constants moved to constants.R for centralized configuration

# ============================================================================
# GRAPHICAL SES CREATOR CONSTANTS
# ============================================================================

# Ghost node rendering (semi-transparent preview nodes in graphical creator)
GHOST_NODE_OPACITY <- 0.4         # 40% opacity for ghost nodes
GHOST_EDGE_OPACITY <- 0.4         # 40% opacity for ghost edges
GHOST_NODE_BORDER_DASH <- c(5, 5) # Dashed border pattern

# AI suggestion limits
MAX_SUGGESTIONS_PER_EXPANSION <- 5  # Max number of ghost nodes per expansion
MIN_CLASSIFICATION_CONFIDENCE <- 0.2 # Minimum confidence to show classification

# Network validation
MIN_NETWORK_NODES_FOR_EXPORT <- 2  # Minimum nodes required for ISA export
MIN_NETWORK_EDGES_FOR_EXPORT <- 1  # Minimum edges required for ISA export

# ============================================================================
# ENTRY POINT SYSTEM (Marine Management DSS & Toolbox)
# Based on: Elliott, M. - Discussion Document V3.0
# Extracted to config/entry_points.R for maintainability
# ============================================================================
source(get_project_file("config", "entry_points.R"), local = FALSE)

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

# NOTE: CONFIDENCE_OPACITY and CONFIDENCE_DEFAULT are defined in constants.R

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
# UTILITY FUNCTIONS
# ============================================================================
# NOTE: Default visualization constants (DEFAULT_NODE_SIZE, DEFAULT_EDGE_WIDTH, etc.)
# are defined in constants.R — the single source of truth for all constants.

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

# NOTE: validate_element_data() now defined in functions/data_structure.R
# (removed duplicate definition to avoid function name conflicts)

# NOTE: validate_adjacency_matrix() now defined in functions/data_structure.R
# (removed duplicate definition to avoid function name conflicts)

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

# NOTE: sanitize_filename() is defined earlier in this file (global.R:430)
# (removed duplicate definition to avoid function name conflicts)

# NOTE: validate_project_structure() now defined in functions/data_structure.R
# (removed duplicate definition to avoid function name conflicts)

# NOTE: safe_get_nested() now defined in functions/error_handling.R
# (removed duplicate definition to avoid function name conflicts)

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

# Maximum file upload size (use constant from constants.R)
options(shiny.maxRequestSize = MAX_UPLOAD_SIZE_BYTES)

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
