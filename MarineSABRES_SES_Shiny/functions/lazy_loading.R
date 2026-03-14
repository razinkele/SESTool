# functions/lazy_loading.R
# ============================================================================
# Lazy Loading System for Optional Modules
#
# Provides deferred loading of optional modules (ML, export formats, etc.)
# to improve startup time and reduce memory usage.
# ============================================================================

# Module registry for tracking loaded/unloaded optional modules
.lazy_module_registry <- new.env(parent = emptyenv())
.lazy_module_registry$loaded <- character(0)
.lazy_module_registry$load_times <- list()

#' Register a Lazy-Loadable Module
#'
#' Registers a module for deferred loading. The module's source file will
#' only be sourced when explicitly requested.
#'
#' @param module_id Unique identifier for the module
#' @param source_file Path to the module's R source file
#' @param dependencies Character vector of module IDs this module depends on
#' @param category Module category (e.g., "ml", "export", "analysis")
#' @export
register_lazy_module <- function(module_id, source_file, dependencies = NULL, category = "optional") {
  if (!exists(module_id, envir = .lazy_module_registry)) {
    .lazy_module_registry[[module_id]] <- list(
      source_file = source_file,
      dependencies = dependencies,
      category = category,
      loaded = FALSE,
      load_time = NULL
    )
    debug_log(sprintf("Registered lazy module: %s (%s)", module_id, category), "LAZY_LOAD")
  }
}

#' Load a Lazy Module
#'
#' Loads a previously registered lazy module and its dependencies.
#' If already loaded, returns immediately.
#'
#' @param module_id The module identifier to load
#' @param force Force reload even if already loaded
#' @return TRUE if successful, FALSE otherwise
#' @export
load_lazy_module <- function(module_id, force = FALSE) {
  # Check if module is registered
  if (!exists(module_id, envir = .lazy_module_registry)) {
    debug_log(sprintf("Module not registered: %s", module_id), "LAZY_LOAD")
    return(FALSE)
  }

  module_info <- .lazy_module_registry[[module_id]]

  # Already loaded?
  if (module_info$loaded && !force) {
    debug_log(sprintf("Module already loaded: %s", module_id), "LAZY_LOAD")
    return(TRUE)
  }

  # Load dependencies first
  if (!is.null(module_info$dependencies)) {
    for (dep_id in module_info$dependencies) {
      if (!load_lazy_module(dep_id)) {
        debug_log(sprintf("Failed to load dependency %s for %s", dep_id, module_id), "LAZY_LOAD")
        return(FALSE)
      }
    }
  }

  # Load the module
  start_time <- Sys.time()
  result <- tryCatch({
    if (!file.exists(module_info$source_file)) {
      stop(sprintf("Source file not found: %s", module_info$source_file))
    }
    source(module_info$source_file, local = FALSE)
    TRUE
  }, error = function(e) {
    debug_log(sprintf("Error loading module %s: %s", module_id, e$message), "LAZY_LOAD")
    FALSE
  })

  if (result) {
    load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    .lazy_module_registry[[module_id]]$loaded <- TRUE
    .lazy_module_registry[[module_id]]$load_time <- load_time
    .lazy_module_registry$loaded <- c(.lazy_module_registry$loaded, module_id)
    .lazy_module_registry$load_times[[module_id]] <- load_time
    debug_log(sprintf("Loaded lazy module: %s (%.2fs)", module_id, load_time), "LAZY_LOAD")
  }

  result
}

#' Check if Module is Loaded
#'
#' @param module_id The module identifier to check
#' @return TRUE if loaded, FALSE otherwise
#' @export
is_module_loaded <- function(module_id) {
  if (!exists(module_id, envir = .lazy_module_registry)) {
    return(FALSE)
  }
  .lazy_module_registry[[module_id]]$loaded
}

#' Get Loaded Modules
#'
#' @param category Optional category filter
#' @return Character vector of loaded module IDs
#' @export
get_loaded_modules <- function(category = NULL) {
  loaded <- .lazy_module_registry$loaded
  if (!is.null(category)) {
    loaded <- Filter(function(m) {
      .lazy_module_registry[[m]]$category == category
    }, loaded)
  }
  loaded
}

#' Get Module Load Statistics
#'
#' @return Data frame with module loading statistics
#' @export
get_lazy_load_stats <- function() {
  modules <- ls(.lazy_module_registry, pattern = "^[^.]")
  modules <- setdiff(modules, c("loaded", "load_times"))

  if (length(modules) == 0) {
    return(data.frame(
      module_id = character(0),
      category = character(0),
      loaded = logical(0),
      load_time_sec = numeric(0)
      
    ))
  }

  data.frame(
    module_id = modules,
    category = sapply(modules, function(m) .lazy_module_registry[[m]]$category),
    loaded = sapply(modules, function(m) .lazy_module_registry[[m]]$loaded),
    load_time_sec = sapply(modules, function(m) {
      lt <- .lazy_module_registry[[m]]$load_time
      if (is.null(lt)) NA_real_ else lt
    })
    
  )
}

#' Require Lazy Module (with User Feedback)
#'
#' Attempts to load a lazy module with user notification.
#' Shows loading indicator while loading.
#'
#' @param module_id The module identifier
#' @param session Shiny session (for notifications)
#' @param i18n i18n translator (for messages)
#' @param notification Show notification during load
#' @return TRUE if successful, FALSE otherwise
#' @export
require_lazy_module <- function(module_id, session = NULL, i18n = NULL, notification = TRUE) {
  if (is_module_loaded(module_id)) {
    return(TRUE)
  }

  # Show loading notification
  notification_id <- NULL
  if (notification && !is.null(session)) {
    notification_id <- shiny::showNotification(
      paste0("Loading ", module_id, "..."),
      type = "message",
      duration = NULL,
      closeButton = FALSE
    )
  }

  # Load the module
  result <- load_lazy_module(module_id)

  # Remove loading notification
  if (!is.null(notification_id)) {
    shiny::removeNotification(notification_id)
  }

  # Show result notification
  if (!is.null(session)) {
    if (result) {
      shiny::showNotification(
        paste0(module_id, " loaded successfully"),
        type = "message",
        duration = 2
      )
    } else {
      shiny::showNotification(
        paste0("Failed to load ", module_id),
        type = "error",
        duration = 5
      )
    }
  }

  result
}

# ============================================================================
# Pre-register Optional Modules
# ============================================================================

#' Initialize Lazy Module Registry
#'
#' Registers all known optional modules for lazy loading.
#' Should be called once during app initialization.
#'
#' @export
init_lazy_module_registry <- function() {
  # ML modules (heavy dependencies, often not needed)
  register_lazy_module(
    "ml_feature_engineering",
    "functions/ml_feature_engineering.R",
    category = "ml"
  )

  register_lazy_module(
    "ml_model_architecture",
    "functions/ml_model_architecture.R",
    dependencies = c("ml_feature_engineering"),
    category = "ml"
  )

  register_lazy_module(
    "ml_inference_api",
    "functions/ml_inference_api.R",
    dependencies = c("ml_model_architecture"),
    category = "ml"
  )

  # Export format modules
  register_lazy_module(
    "export_word",
    "functions/export_word.R",
    category = "export"
  )

  register_lazy_module(
    "export_powerpoint",
    "functions/export_powerpoint.R",
    category = "export"
  )

  # Advanced analysis modules
  register_lazy_module(
    "analysis_simulation",
    "modules/analysis_simulation.R",
    category = "analysis"
  )

  debug_log("Lazy module registry initialized", "LAZY_LOAD")
}

# ============================================================================
# Feature Cache for ML Performance
# ============================================================================

# Cache environment for ML feature vectors
.ml_feature_cache <- new.env(parent = emptyenv())
.ml_feature_cache$features <- list()
.ml_feature_cache$timestamps <- list()
.ml_feature_cache$max_size <- 1000  # Maximum cached entries

#' Cache ML Features
#'
#' Caches computed features for an element to avoid recomputation.
#'
#' @param element_id Unique element identifier
#' @param features Computed feature vector
#' @param ttl_seconds Time-to-live in seconds (default: 300 = 5 minutes)
#' @export
cache_ml_features <- function(element_id, features, ttl_seconds = 300) {
  # Prune cache if too large
  if (length(.ml_feature_cache$features) >= .ml_feature_cache$max_size) {
    prune_ml_feature_cache()
  }

  .ml_feature_cache$features[[element_id]] <- features
  .ml_feature_cache$timestamps[[element_id]] <- Sys.time() + ttl_seconds
}

#' Get Cached ML Features
#'
#' Retrieves cached features for an element if available and not expired.
#'
#' @param element_id Unique element identifier
#' @return Feature vector or NULL if not cached/expired
#' @export
get_cached_ml_features <- function(element_id) {
  if (!element_id %in% names(.ml_feature_cache$features)) {
    return(NULL)
  }

  # Check expiration
  if (Sys.time() > .ml_feature_cache$timestamps[[element_id]]) {
    # Expired - remove from cache
    .ml_feature_cache$features[[element_id]] <- NULL
    .ml_feature_cache$timestamps[[element_id]] <- NULL
    return(NULL)
  }

  .ml_feature_cache$features[[element_id]]
}

#' Prune ML Feature Cache
#'
#' Removes expired entries from the cache.
#'
#' @export
prune_ml_feature_cache <- function() {
  now <- Sys.time()
  expired <- names(.ml_feature_cache$timestamps)[
    sapply(.ml_feature_cache$timestamps, function(t) now > t)
  ]

  for (id in expired) {
    .ml_feature_cache$features[[id]] <- NULL
    .ml_feature_cache$timestamps[[id]] <- NULL
  }

  debug_log(sprintf("Pruned %d expired ML feature cache entries", length(expired)), "ML_CACHE")
}

#' Clear ML Feature Cache
#'
#' Clears all cached features.
#'
#' @export
clear_ml_feature_cache <- function() {
  .ml_feature_cache$features <- list()
  .ml_feature_cache$timestamps <- list()
  debug_log("Cleared ML feature cache", "ML_CACHE")
}

#' Get ML Cache Statistics
#'
#' @return List with cache statistics
#' @export
get_ml_cache_stats <- function() {
  list(
    cached_count = length(.ml_feature_cache$features),
    max_size = .ml_feature_cache$max_size,
    memory_estimate = object.size(.ml_feature_cache$features)
  )
}
