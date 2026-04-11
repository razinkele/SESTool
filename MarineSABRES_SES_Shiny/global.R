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
  library(readxl)     # Excel reading for template imports
  library(httr)       # HTTP client for GitHub Issues API
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
  if (Sys.getenv("MARINESABRES_DEBUG", "FALSE") == "TRUE") {
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
  version_text <- readLines(file.path(PROJECT_ROOT, "VERSION"), warn = FALSE)[1]
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
    debug_log("Using modular translation system with wrapper", "I18N")
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
    debug_log("Pure modular translation system with wrapper initialized", "I18N")
    debug_log(sprintf("Translation file: %s", translation_file), "I18N")
    debug_log(sprintf("File size: %s KB", round(file.info(translation_file)$size / 1024, 1)), "I18N")
    debug_log("Use i18n$t(\"namespaced.key\") or t_(\"namespaced.key\")", "I18N")
  }

  # Note: No cleanup needed for persistent translation file
  # The file is kept in translations/_merged_translations.json
  # and will be overwritten on next initialization
} else {
  # Fallback to monolithic translation file
  debug_log("Using legacy monolithic translation file", "I18N")
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

# ==============================================================================
# P2 FIX: Translation Validation at Startup
# ==============================================================================

#' Validate that all required translation keys exist
#'
#' Reports any missing translation keys at startup.
#'
#' @param i18n The i18n translator object
#' @param required_keys Character vector of required keys (optional)
#' @return Invisibly returns list of missing keys
#' @export
validate_translation_completeness <- function(i18n, required_keys = NULL) {
  # Define critical keys that must exist.
  # NOTE: Keys use the namespaced form (common.*, ui.*) — the old flat form
  # (buttons.save, messages.error) was renamed during the modular i18n migration.
  # If you add keys here, also list them in scripts/_i18n_audit.py's
  # CRITICAL_VALIDATION_KEYS set so the auditor can track them.
  critical_keys <- c(
    "ui.header.title",
    "ui.header.preloader_title",
    "ui.sidebar.home",
    "common.buttons.save",
    "common.buttons.cancel",
    "common.buttons.delete",
    "common.messages.success",
    "common.messages.error"
  )

  keys_to_check <- if (!is.null(required_keys)) required_keys else critical_keys

  missing_keys <- character()
  for (key in keys_to_check) {
    tryCatch({
      translated <- i18n$t(key)
      # If translation returns the key itself, it's missing
      if (identical(translated, key)) {
        missing_keys <- c(missing_keys, key)
      }
    }, error = function(e) {
      missing_keys <<- c(missing_keys, key)
    })
  }

  if (length(missing_keys) > 0) {
    warning(sprintf(
      "Missing %d translation key(s): %s",
      length(missing_keys),
      paste(head(missing_keys, 10), collapse = ", ")
    ))
  }

  invisible(missing_keys)
}

#' Get all translation keys for a language
#'
#' @param i18n The i18n translator object
#' @param language Language code (default: "en")
#' @return Character vector of all translation keys
#' @export
get_translation_keys <- function(i18n, language = "en") {
  tryCatch({
    translations <- i18n$get_translations()
    if (!is.null(translations) && language %in% names(translations)) {
      return(names(translations[[language]]))
    }
    return(character())
  }, error = function(e) {
    return(character())
  })
}

#' Check translation coverage across languages
#'
#' @param i18n The i18n translator object
#' @return Data frame with language coverage stats
#' @export
check_translation_coverage <- function(i18n) {
  languages <- tryCatch(i18n$get_languages(), error = function(e) character())
  if (length(languages) == 0) return(NULL)

  base_lang <- "en"
  base_keys <- get_translation_keys(i18n, base_lang)
  if (length(base_keys) == 0) return(NULL)

  coverage <- data.frame(
    language = languages,
    total_keys = length(base_keys),
    translated = sapply(languages, function(lang) {
      keys <- get_translation_keys(i18n, lang)
      sum(keys %in% base_keys)
    })
  )
  coverage$coverage_pct <- round(coverage$translated / coverage$total_keys * 100, 1)

  coverage
}

# Run validation at startup (non-blocking)
tryCatch({
  validate_translation_completeness(i18n)
}, error = function(e) {
  # Don't fail startup on validation error
  message("Translation validation skipped: ", e$message)
})

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

# ============================================================================
# DEBUG MODE CONFIGURATION (must be early for use by other modules)
# ============================================================================

# Enable/disable debug logging via environment variable
# Set MARINESABRES_DEBUG=TRUE in .Renviron or before running the app to enable debug logs
# Default is FALSE for production use
DEBUG_MODE <- Sys.getenv("MARINESABRES_DEBUG", "FALSE") == "TRUE"
ADMIN_MODE <- Sys.getenv("MARINESABRES_ADMIN_MODE", "FALSE") == "TRUE"

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

#' P1 FIX: Startup Log Function
#'
#' Logs startup messages. These are shown even in production mode since
#' they provide important feedback during app initialization.
#' Use debug_log() for ongoing diagnostic messages.
#'
#' @param message Character string to log
#' @param type One of "info", "success", "warning", "error"
#' @param verbose If FALSE, only show in DEBUG_MODE
#' @keywords internal
startup_log <- function(message, type = "info", verbose = TRUE) {
  # Only show verbose messages in DEBUG_MODE
  if (!verbose && !DEBUG_MODE) {
    return(invisible(NULL))
  }

  prefix <- switch(type,
    "success" = "\u2713 ",
    "warning" = "\u26A0 ",
    "error"   = "\u2717 ",
    "info"    = "  "
  )

  cat(paste0(prefix, message, "\n"))
}

# ==============================================================================
# P2 FIX: Reusable Logging Utilities
# ==============================================================================

#' Log a startup step with section and status
#'
#' Provides structured logging for application startup phases.
#'
#' @param section The startup section (e.g., "packages", "modules", "config")
#' @param status Status of the step ("started", "completed", "failed")
#' @param details Optional additional details
#' @export
log_startup_step <- function(section, status, details = NULL) {
  timestamp <- format(Sys.time(), "%H:%M:%S")
  status_icon <- switch(status,
    "started"   = "\u25B6",
    "completed" = "\u2713",
    "failed"    = "\u2717",
    "skipped"   = "\u25CB",
    "\u2022"
  )

  msg <- sprintf("[%s] %s %s", timestamp, status_icon, section)
  if (!is.null(details)) {
    msg <- paste0(msg, " - ", details)
  }

  cat(msg, "\n")
}

#' Log a data structure with summary information
#'
#' Useful for debugging data flow through the application.
#'
#' @param name Name of the data structure
#' @param type Type of structure (e.g., "data.frame", "list", "reactive")
#' @param count Number of items/rows
#' @param ids Optional vector of IDs to show (first 5)
#' @export
log_data_structure <- function(name, type, count, ids = NULL) {
  if (!DEBUG_MODE) return(invisible(NULL))

  msg <- sprintf("[DATA] %s (%s): %d items", name, type, count)
  if (!is.null(ids) && length(ids) > 0) {
    show_ids <- head(ids, 5)
    msg <- paste0(msg, " [", paste(show_ids, collapse = ", "))
    if (length(ids) > 5) msg <- paste0(msg, ", ...")
    msg <- paste0(msg, "]")
  }

  cat(msg, "\n")
}

#' Log a module event
#'
#' Standardized logging for module lifecycle and user interactions.
#'
#' @param module Module name (e.g., "isa_data_entry", "cld_visualization")
#' @param event Event type (e.g., "init", "render", "click", "save")
#' @param data Optional data to include in log
#' @export
log_module_event <- function(module, event, data = NULL) {
  if (!DEBUG_MODE) return(invisible(NULL))

  timestamp <- format(Sys.time(), "%H:%M:%S.%OS3")
  msg <- sprintf("[%s] [%s] %s", timestamp, module, event)

  if (!is.null(data)) {
    if (is.list(data)) {
      data_str <- paste(names(data), "=", sapply(data, function(x) {
        if (length(x) > 1) paste0("[", length(x), " items]")
        else as.character(x)
      }), collapse = ", ")
      msg <- paste0(msg, " {", data_str, "}")
    } else {
      msg <- paste0(msg, " (", as.character(data), ")")
    }
  }

  cat(msg, "\n")
}

# log_error() is defined in functions/error_handling.R (line 550)
# Signature: log_error(context, message, error = NULL)
# Uses debug_log() for consistent logging output

# Application configuration from environment variables
if (file.exists(get_project_file("config", "app_config.R"))) {
  source(get_project_file("config", "app_config.R"), local = FALSE)
}

# User level configuration system (centralised feature toggles per level)
if (file.exists(get_project_file("config", "user_level_config.R"))) {
  source(get_project_file("config", "user_level_config.R"), local = FALSE)
  startup_log("User level config loaded", "success", verbose = FALSE)
}

# ============================================================================
# SOURCE HELPER FUNCTIONS
# ============================================================================

# UI helper functions (global scope for use across modules)
source("functions/ui_helpers.R", local = FALSE)

# Shared UI component library (global scope for use across modules)
source("functions/ui_components.R", local = FALSE)

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

# ISA form builders and entry collection helpers (extracted from isa_data_entry_module)
source("functions/isa_form_builders.R", local = TRUE)

# ISA export helpers (extracted from isa_data_entry_module)
source("functions/isa_export_helpers.R", local = TRUE)

# Data accessor functions (simplifies deep reactive nesting)
source("functions/data_accessors.R", local = TRUE)

# Lazy loading system for optional modules (improves startup time)
# Lazy loading infrastructure removed - all modules are eagerly loaded

# Network analysis functions
source("functions/network_analysis.R", local = TRUE)

# visNetwork helper functions
source("functions/visnetwork_helpers.R", local = TRUE)

# CLD interaction helpers (manipulation, node/edge creation, highlight logic)
source("functions/cld_interaction_helpers.R", local = TRUE)

# Export functions
source("functions/export_functions.R", local = TRUE)

# Report generation functions — sourced once via app.R critical_sources

# Module validation helpers
source("functions/module_validation_helpers.R", local = TRUE)

# CLD validation utilities (shared across analysis modules)
source(get_project_file("functions", "cld_validation.R"), local = FALSE)

# Error handling and validation
source("functions/error_handling.R", local = FALSE)  # FALSE = global scope for log_error, safe_execute, etc.

# Feedback reporter (local NDJSON log + optional GitHub Issues)
source("functions/feedback_reporter.R", local = FALSE)

# Feedback analyzer (NDJSON loader, TF-IDF similarity, duplicate detection)
source("functions/feedback_analyzer.R", local = FALSE)

# KB report helpers (KB context, citation matching, governance lookup for report generation)
source("functions/kb_report_helpers.R", local = FALSE)

# Project transaction wrappers (atomic state changes, cross-reference validation)
source("functions/project_transactions.R", local = FALSE)  # FALSE = global scope for test access

# Undo/redo system (command pattern-based history)
source("functions/undo_redo.R", local = FALSE)  # FALSE = global scope for module access

# Reactive pipeline (event-based data flow)
source("functions/reactive_pipeline.R", local = TRUE)

# Session isolation utilities (for multi-user shiny-server deployments)
source("functions/session_isolation.R", local = FALSE)  # FALSE = global scope for server access
source("functions/session_logger.R", local = FALSE)  # FALSE = global scope for logger functions

# Persistent storage utilities (for saving projects to user's Documents folder)
source("functions/persistent_storage.R", local = FALSE)  # FALSE = global scope for server access

# Async computation helpers (lightweight progress-aware wrappers)
source(get_project_file("functions", "async_helpers.R"), local = FALSE)

# Cross-tool recommendation engine (next-steps links after analysis completion)
source("functions/tool_recommendations.R", local = FALSE)  # FALSE = global scope for module access

# Root utils.R: Network visualization helpers (convert_strength, get_node_colors, get_node_shapes, etc.)
source("utils.R", local = FALSE)  # FALSE = global scope for get_node_colors, get_node_shapes, etc.

# Navigation helpers (breadcrumbs, progress bars, nav buttons)
source("modules/navigation_helpers.R", local = TRUE)

# Auto-save module
source("modules/auto_save_module.R", local = TRUE)

# Recent projects module (easy access to saved projects)
source("modules/recent_projects_module.R", local = TRUE)

# Tutorial system (contextual help for features)
source("modules/tutorial_system.R", local = TRUE)
source("config/tutorial_content.R", local = TRUE)

# Graphical SES Creator system (AI-powered step-by-step network building)
# Note: Knowledge base must be global scope for use by both AI ISA and Graphical SES modules
source("modules/ai_isa_knowledge_base.R", local = FALSE)

# Marine SES Connection Knowledge Base (curated DAPSI(W)R(M) connections from published case studies)
# Must be global scope for use by AI ISA connection generator and ML scoring
source("data/ses_connection_knowledge_base.R", local = FALSE)

# SES Knowledge Database loader (JSON-based context-specific element and connection suggestions)
# Must be global scope for use by AI ISA knowledge base and connection generator
source("functions/ses_knowledge_db_loader.R", local = FALSE)

# Country Governance and Socio-Economic Database loader
# Must be global scope for country-specific governance and socioeconomic element suggestions
source("functions/country_governance_loader.R", local = FALSE)

source("data/dapsiwrm_element_keywords.R", local = TRUE)
source("functions/dapsiwrm_connection_rules.R", local = TRUE)
source("functions/ses_dynamics.R", local = TRUE)
source("modules/graphical_ses_ai_classifier.R", local = TRUE)
source("modules/graphical_ses_network_builder.R", local = TRUE)
source("modules/graphical_ses_creator_module.R", local = TRUE)
source("modules/connection_review_tabbed.R", local = FALSE)  # FALSE = global scope (used by multiple modules)
source("modules/workflow_stepper_module.R", local = TRUE)

# ============================================================================
# OPTIONAL ML ENHANCEMENT (Deep Learning Connection Predictor)
# ============================================================================

# ML can be enabled/disabled via environment variable or user preference
ML_ENABLED <- Sys.getenv("MARINESABRES_ML_ENABLED", "TRUE") == "TRUE"
ML_AVAILABLE <- FALSE  # Will be set to TRUE if model loads successfully
ENSEMBLE_AVAILABLE <- FALSE  # Will be set to TRUE if ensemble loads successfully

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
    if (file.exists("functions/ml_explainability.R")) {
      source("functions/ml_explainability.R", local = TRUE)
      cat("✓ ML explainability module loaded\n")
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

    # ML feature cache (LRU cache for feature vectors)
    if (file.exists("functions/ml_feature_cache.R")) {
      source("functions/ml_feature_cache.R", local = TRUE)
      cat("✓ ML feature cache loaded\n")
    }

    # Load advanced text embeddings module (P1 enhancement)
    if (file.exists("functions/ml_text_embeddings.R")) {
      source("functions/ml_text_embeddings.R", local = TRUE)
      cat("✓ ML text embeddings loaded\n")
    }

    # Load model registry (P1 enhancement)
    if (file.exists("functions/ml_model_registry.R")) {
      source("functions/ml_model_registry.R", local = TRUE)
      cat("✓ ML model registry loaded\n")
    }

    # Try to load trained model (Phase 2 v2 preferred, fallback to Phase 1 v1)
    # load_ml_model() auto-detects v1/v2 and tries v2 path if v1 not found
    model_path <- "models/connection_predictor_best.pt"
    v2_model_path <- "models/connection_predictor_v2_best.pt"
    if (file.exists(model_path) || file.exists(v2_model_path)) {
      load_ml_model(model_path)
      ML_AVAILABLE <- TRUE

      model_info <- get_ml_model_info()
      cat(sprintf("\n✓ ML Model Loaded Successfully\n"))
      cat(sprintf("  - Model: %s\n", model_info$architecture))
      cat(sprintf("  - Version: %s\n", model_info$model_version %||% "v1"))
      cat(sprintf("  - Input dim: %d\n", model_info$input_dim))
      cat(sprintf("  - Parameters: %s\n", format(model_info$parameters, big.mark = ",")))
      cat(sprintf("  - Size: %.2f MB\n", model_info$size_mb))
      cat(sprintf("  - Pipeline: %s\n", model_info$pipeline %||% "phase1"))
      cat(sprintf("  - Status: Ready for predictions\n"))
    } else {
      cat(sprintf("\n✗ ML model file not found: %s (or %s)\n", model_path, v2_model_path))
      cat("  ML predictions will not be available\n")
      cat("  To enable ML, run: Rscript scripts/train_connection_predictor.R\n")
    }

    # Try to load ensemble models for improved predictions (Phase 2)
    ENSEMBLE_AVAILABLE <<- FALSE
    ensemble_path <- "models/ensemble"
    if (dir.exists(ensemble_path) && exists("load_ensemble", mode = "function")) {
      tryCatch({
        load_ensemble(ensemble_path)
        if (exists("ensemble_available", mode = "function") && ensemble_available()) {
          ENSEMBLE_AVAILABLE <<- TRUE
          n_ensemble <- if (exists("ensemble_env")) ensemble_env$n_models else 0
          cat(sprintf("\n✓ ML Ensemble Loaded Successfully\n"))
          cat(sprintf("  - Path: %s\n", ensemble_path))
          cat(sprintf("  - Models: %d\n", n_ensemble))
          cat(sprintf("  - Ensemble predictions enabled\n"))
        } else {
          cat("\n  Ensemble directory found but no valid models loaded\n")
        }
      }, error = function(e) {
        cat(sprintf("\n✗ ML Ensemble not loaded: %s\n", e$message))
        cat("  Using single model predictions\n")
      })
    } else if (ML_AVAILABLE) {
      cat("\n  Ensemble not available - using single model\n")
      # NOTE: To enable ensemble, train 5 models with different seeds and save to
      # models/ensemble/ with ensemble_metadata.rds. See scripts/train_connection_predictor_v2.R
    }

  }, error = function(e) {
    cat(sprintf("\n✗ ML Enhancement could not be loaded: %s\n", e$message))
    cat("  Falling back to rule-based AI only\n")
    cat("  To enable ML, install torch: install.packages('torch')\n")
    ML_ENABLED <<- FALSE
  })

  cat("═══════════════════════════════════════════════════════════\n\n")
} else {
  cat("\nML Enhancement: Disabled (using rule-based AI only)\n")
  cat("Set MARINESABRES_ML_ENABLED=TRUE to enable ML features\n\n")
}

# ============================================================================
# DEBUG MODE STATUS MESSAGE
# (DEBUG_MODE and debug_log() defined earlier, after constants.R)
# ============================================================================

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
# NOTE: All application constants are defined in constants.R
# ============================================================================

debug_log(sprintf("ISA debounce delay: %d ms", ISA_DEBOUNCE_MS), "CONFIG")

# ============================================================================
# ENTRY POINT SYSTEM (Marine Management DSS & Toolbox)
# Based on: Elliott, M. - Discussion Document V3.0
# Extracted to config/entry_points.R for maintainability
# ============================================================================
source(get_project_file("config", "entry_points.R"), local = FALSE)

# ============================================================================
# UTILITY FUNCTIONS (extracted to functions/utils.R)
# ============================================================================
# Contains: generate_id, format_date_display, is_valid_email,
#   parse_connection_value, log_message, init_session_data,
#   sanitize_color, sanitize_filename, validate_isa_dataframe
# NOTE: Default visualization constants (DEFAULT_NODE_SIZE, DEFAULT_EDGE_WIDTH, etc.)
# are defined in constants.R — the single source of truth for all constants.
# functions/utils.R: Core utilities (generate_id, format_date, parse_connection_value, safe_readRDS, etc.)
source("functions/utils.R", local = FALSE)

# Sidebar UI helpers (includes ARIA accessibility functions)
# NOTE: Also sourced in app.R, but needed here for test availability
source("functions/ui_sidebar.R", local = FALSE)

# NOTE: validate_element_data() defined in functions/data_structure.R
# NOTE: validate_adjacency_matrix() defined in functions/data_structure.R
# NOTE: validate_project_structure() defined in functions/data_structure.R
# NOTE: safe_get_nested() defined in functions/error_handling.R

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
