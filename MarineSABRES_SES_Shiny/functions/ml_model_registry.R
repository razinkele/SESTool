# ==============================================================================
# ML Model Registry
# ==============================================================================
# Model versioning and registry system for managing multiple model versions
#
# Features:
# - Register and track model versions
# - Version compatibility checking
# - Model metadata storage
# - Automatic model selection based on requirements
# ==============================================================================

# ==============================================================================
# Registry Environment
# ==============================================================================

.model_registry_env <- new.env(parent = emptyenv())
.model_registry_env$registry <- list()
.model_registry_env$active_model <- NULL
.model_registry_env$registry_file <- "models/model_registry.json"

# ==============================================================================
# Version Parsing and Comparison
# ==============================================================================

#' Parse semantic version string
#'
#' @param version_str Version string like "1.0.0" or "2.1.3"
#' @return Named list with major, minor, patch components
#' @export
parse_model_version <- function(version_str) {
  if (is.null(version_str) || !is.character(version_str)) {
    return(list(major = 0, minor = 0, patch = 0, raw = "0.0.0"))
  }

  # Remove 'v' prefix if present
  version_str <- gsub("^v", "", version_str)

  parts <- strsplit(version_str, "\\.")[[1]]

  # Handle missing parts by defaulting to 0
  major <- if (length(parts) >= 1 && !is.na(parts[1])) as.integer(parts[1]) else 0L
  minor <- if (length(parts) >= 2 && !is.na(parts[2])) as.integer(parts[2]) else 0L
  patch <- if (length(parts) >= 3 && !is.na(parts[3])) as.integer(parts[3]) else 0L

  list(
    major = major,
    minor = minor,
    patch = patch,
    raw = version_str
  )
}

#' Compare two model versions
#'
#' @param version1 First version string
#' @param version2 Second version string
#' @return -1 if v1 < v2, 0 if equal, 1 if v1 > v2
#' @export
compare_model_versions <- function(version1, version2) {
  v1 <- parse_model_version(version1)
  v2 <- parse_model_version(version2)

  if (v1$major != v2$major) return(sign(v1$major - v2$major))
  if (v1$minor != v2$minor) return(sign(v1$minor - v2$minor))
  if (v1$patch != v2$patch) return(sign(v1$patch - v2$patch))

  return(0)
}

#' Check if a version satisfies a requirement
#'
#' @param version Version to check
#' @param requirement Requirement string like ">=1.0.0" or "~2.1"
#' @return TRUE if version satisfies requirement
#' @export
version_satisfies <- function(version, requirement) {
  if (is.null(requirement) || requirement == "*") return(TRUE)

  # Parse operator and version
  match <- regmatches(requirement, regexec("^(>=|<=|>|<|~|\\^)?(.+)$", requirement))[[1]]

  if (length(match) < 3) return(FALSE)

  operator <- match[2]
  req_version <- match[3]

  comparison <- compare_model_versions(version, req_version)

  switch(operator,
         ">=" = comparison >= 0,
         "<=" = comparison <= 0,
         ">"  = comparison > 0,
         "<"  = comparison < 0,
         "~"  = {
           # Compatible within minor version
           v <- parse_model_version(version)
           rv <- parse_model_version(req_version)
           v$major == rv$major && v$minor == rv$minor
         },
         "^"  = {
           # Compatible within major version
           v <- parse_model_version(version)
           rv <- parse_model_version(req_version)
           v$major == rv$major
         },
         comparison == 0  # Exact match if no operator
  )
}

# ==============================================================================
# Model Registration
# ==============================================================================

#' Register a model in the registry
#'
#' @param model_id Unique identifier for the model
#' @param version Semantic version string
#' @param path Path to the model file
#' @param input_dim Expected input dimensions
#' @param description Human-readable description
#' @param metadata Additional metadata list
#' @param features List of features the model supports
#' @return TRUE if registration succeeded
#' @export
register_model <- function(model_id,
                           version,
                           path,
                           input_dim,
                           description = "",
                           metadata = list(),
                           features = character()) {

  entry <- list(
    model_id = model_id,
    version = version,
    path = path,
    input_dim = input_dim,
    description = description,
    metadata = metadata,
    features = features,
    registered_at = Sys.time(),
    hash = NULL
  )

  # Calculate file hash if file exists
  if (file.exists(path) && requireNamespace("digest", quietly = TRUE)) {
    entry$hash <- digest::digest(file = path, algo = "sha256")
  }

  # Store in registry
  key <- paste(model_id, version, sep = "@")
  .model_registry_env$registry[[key]] <- entry

  debug_log(sprintf("Registered model: %s@%s", model_id, version), "MODEL_REGISTRY")

  TRUE
}

#' Unregister a model from the registry
#'
#' @param model_id Model identifier
#' @param version Version to unregister (NULL for all versions)
#' @return TRUE if unregistration succeeded
#' @export
unregister_model <- function(model_id, version = NULL) {
  if (is.null(version)) {
    # Remove all versions
    keys <- grep(paste0("^", model_id, "@"), names(.model_registry_env$registry), value = TRUE)
    for (key in keys) {
      .model_registry_env$registry[[key]] <- NULL
    }
  } else {
    key <- paste(model_id, version, sep = "@")
    .model_registry_env$registry[[key]] <- NULL
  }

  TRUE
}

#' Get a registered model by ID and version
#'
#' @param model_id Model identifier
#' @param version Version string (NULL for latest)
#' @param version_requirement Version requirement like ">=1.0.0"
#' @return Model registry entry or NULL
#' @export
get_registered_model <- function(model_id, version = NULL, version_requirement = NULL) {
  if (!is.null(version)) {
    key <- paste(model_id, version, sep = "@")
    return(.model_registry_env$registry[[key]])
  }

  # Find all versions of this model
  pattern <- paste0("^", model_id, "@")
  keys <- grep(pattern, names(.model_registry_env$registry), value = TRUE)

  if (length(keys) == 0) return(NULL)

  # Filter by requirement if specified
  if (!is.null(version_requirement)) {
    valid_keys <- sapply(keys, function(k) {
      entry <- .model_registry_env$registry[[k]]
      version_satisfies(entry$version, version_requirement)
    })
    keys <- keys[valid_keys]
  }

  if (length(keys) == 0) return(NULL)

  # Return latest version
  versions <- sapply(keys, function(k) .model_registry_env$registry[[k]]$version)
  latest_idx <- which.max(sapply(versions, function(v) {
    pv <- parse_model_version(v)
    pv$major * 10000 + pv$minor * 100 + pv$patch
  }))

  .model_registry_env$registry[[keys[latest_idx]]]
}

#' List all registered models
#'
#' @param model_id Optional filter by model ID
#' @return Data frame of registered models
#' @export
list_registered_models <- function(model_id = NULL) {
  registry <- .model_registry_env$registry

  if (length(registry) == 0) {
    return(data.frame(
      model_id = character(),
      version = character(),
      path = character(),
      input_dim = integer(),
      description = character()
      
    ))
  }

  entries <- if (is.null(model_id)) {
    registry
  } else {
    pattern <- paste0("^", model_id, "@")
    registry[grep(pattern, names(registry))]
  }

  do.call(rbind, lapply(entries, function(e) {
    data.frame(
      model_id = e$model_id,
      version = e$version,
      path = e$path,
      input_dim = e$input_dim,
      description = e$description
      
    )
  }))
}

# ==============================================================================
# Registry Persistence
# ==============================================================================

#' Save registry to file
#'
#' @param file_path Path to save registry (default: models/model_registry.json)
#' @return TRUE if save succeeded
#' @export
save_model_registry <- function(file_path = NULL) {
  if (is.null(file_path)) {
    file_path <- .model_registry_env$registry_file
  }

  # Convert to serializable format
  registry_data <- lapply(.model_registry_env$registry, function(entry) {
    entry$registered_at <- as.character(entry$registered_at)
    entry
  })

  tryCatch({
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    json <- jsonlite::toJSON(registry_data, auto_unbox = TRUE, pretty = TRUE)
    writeLines(json, file_path)
    debug_log(sprintf("Saved model registry to %s", file_path), "MODEL_REGISTRY")
    TRUE
  }, error = function(e) {
    debug_log(sprintf("Failed to save registry: %s", e$message), "MODEL_REGISTRY_ERROR")
    FALSE
  })
}

#' Load registry from file
#'
#' @param file_path Path to load registry from
#' @return TRUE if load succeeded
#' @export
load_model_registry <- function(file_path = NULL) {
  if (is.null(file_path)) {
    file_path <- .model_registry_env$registry_file
  }

  if (!file.exists(file_path)) {
    debug_log(sprintf("Registry file not found: %s", file_path), "MODEL_REGISTRY")
    return(FALSE)
  }

  tryCatch({
    json <- readLines(file_path, warn = FALSE)
    registry_data <- jsonlite::fromJSON(paste(json, collapse = "\n"), simplifyVector = FALSE)

    # Restore to environment
    .model_registry_env$registry <- registry_data

    debug_log(sprintf("Loaded model registry from %s (%d models)",
                      file_path, length(registry_data)), "MODEL_REGISTRY")
    TRUE
  }, error = function(e) {
    debug_log(sprintf("Failed to load registry: %s", e$message), "MODEL_REGISTRY_ERROR")
    FALSE
  })
}

# ==============================================================================
# Model Discovery
# ==============================================================================

#' Discover and register models from a directory
#'
#' @param models_dir Directory to scan for models
#' @param pattern File pattern to match (default: "*.pt")
#' @return Number of models discovered
#' @export
discover_models <- function(models_dir = "models", pattern = "\\.pt$") {
  if (!dir.exists(models_dir)) {
    return(0)
  }

  model_files <- list.files(models_dir, pattern = pattern, full.names = TRUE)
  discovered <- 0

  for (file_path in model_files) {
    # Try to extract model info from filename
    filename <- basename(file_path)

    # Try to parse version from filename (e.g., model_v1.0.0.pt)
    version_match <- regmatches(filename, regexec("_v?(\\d+\\.\\d+\\.?\\d*)", filename))[[1]]
    version <- if (length(version_match) > 1) version_match[2] else "1.0.0"

    # Extract model ID from filename
    model_id <- gsub("_v?\\d+\\.\\d+\\.?\\d*", "", gsub("\\.pt$", "", filename))
    model_id <- gsub("_best$|_final$", "", model_id)

    # Try to detect input dimensions
    input_dim <- tryCatch({
      if (requireNamespace("torch", quietly = TRUE)) {
        model <- torch::torch_load(file_path)
        # Try to get input dim from model
        if (!is.null(model$parameters)) {
          first_layer <- model$parameters[[1]]
          if (!is.null(dim(first_layer))) dim(first_layer)[2] else 358
        } else {
          358  # Default
        }
      } else {
        358
      }
    }, error = function(e) 358)

    # Register if not already registered
    existing <- get_registered_model(model_id, version)
    if (is.null(existing)) {
      register_model(
        model_id = model_id,
        version = version,
        path = file_path,
        input_dim = input_dim,
        description = sprintf("Auto-discovered from %s", filename)
      )
      discovered <- discovered + 1
    }
  }

  debug_log(sprintf("Discovered %d new models in %s", discovered, models_dir), "MODEL_REGISTRY")
  discovered
}

# ==============================================================================
# Compatibility Checks
# ==============================================================================

#' Check if a model is compatible with current requirements
#'
#' @param model_entry Registry entry for the model
#' @param required_features List of required features
#' @param required_input_dim Required input dimensions
#' @return List with compatible (boolean) and issues (character vector)
#' @export
check_model_compatibility <- function(model_entry,
                                      required_features = NULL,
                                      required_input_dim = NULL) {
  issues <- character()

  # Check file exists
  if (!file.exists(model_entry$path)) {
    issues <- c(issues, sprintf("Model file not found: %s", model_entry$path))
  }

  # Check input dimensions
  if (!is.null(required_input_dim) && model_entry$input_dim != required_input_dim) {
    issues <- c(issues, sprintf("Input dimension mismatch: expected %d, got %d",
                                required_input_dim, model_entry$input_dim))
  }

  # Check required features
  if (!is.null(required_features)) {
    missing <- setdiff(required_features, model_entry$features)
    if (length(missing) > 0) {
      issues <- c(issues, sprintf("Missing features: %s", paste(missing, collapse = ", ")))
    }
  }

  # Verify hash if stored
  if (!is.null(model_entry$hash) && file.exists(model_entry$path)) {
    current_hash <- digest::digest(file = model_entry$path, algo = "sha256")
    if (current_hash != model_entry$hash) {
      issues <- c(issues, "Model file has been modified since registration")
    }
  }

  list(
    compatible = length(issues) == 0,
    issues = issues
  )
}

# ==============================================================================
# Active Model Management
# ==============================================================================

#' Set the active model
#'
#' @param model_id Model identifier
#' @param version Version string (NULL for latest)
#' @return TRUE if model was set
#' @export
set_active_model <- function(model_id, version = NULL) {
  entry <- get_registered_model(model_id, version)

  if (is.null(entry)) {
    debug_log(sprintf("Model not found: %s@%s", model_id, version %||% "latest"),
              "MODEL_REGISTRY_ERROR")
    return(FALSE)
  }

  .model_registry_env$active_model <- entry
  debug_log(sprintf("Set active model: %s@%s", entry$model_id, entry$version),
            "MODEL_REGISTRY")
  TRUE
}

#' Get the active model entry
#'
#' @return Active model registry entry or NULL
#' @export
get_active_model <- function() {
  .model_registry_env$active_model
}

# ==============================================================================
# Initialization
# ==============================================================================

#' Initialize the model registry
#'
#' Loads saved registry and discovers new models
#'
#' @param models_dir Directory to scan for models
#' @param registry_file Path to registry file
#' @return Number of total registered models
#' @export
init_model_registry <- function(models_dir = "models",
                                registry_file = "models/model_registry.json") {
  .model_registry_env$registry_file <- registry_file

  # Load existing registry
  load_model_registry(registry_file)

  # Discover new models
  discover_models(models_dir)

  # Save updated registry
  save_model_registry(registry_file)

  length(.model_registry_env$registry)
}

# Helper for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x
