# functions/persistent_storage.R
# Persistent Storage Utilities for MarineSABRES Projects
#
# PURPOSE: Provides a consistent location for saving/loading projects
# that persists across sessions, whether running locally or on a server.
#
# KEY FEATURES:
# - Suggests a default folder in user's Documents (user must confirm)
# - Browser-based File System Access API fallback (server mode)
# - Recent projects list with easy reload
# - User identifier for project organization

# ============================================================================
# CONSTANTS
# ============================================================================

#' Default folder name for MarineSABRES projects
MARINESABRES_PROJECTS_FOLDER <- "MarineSABRES_Projects"

#' Maximum recent projects to track
MAX_RECENT_PROJECTS <- 20

#' Project file extension
PROJECT_FILE_EXTENSION <- ".rds"

#' Config file name for storing user preferences
STORAGE_CONFIG_FILE <- ".marinesabres_storage_config.rds"

# ============================================================================
# DEPLOYMENT MODE DETECTION
# ============================================================================

#' Detect if running in local mode or server mode
#'
#' Local mode: Running on user's machine via RStudio or Rscript
#' Server mode: Running on shiny-server, shinyapps.io, or Docker
#'
#' @return Character: "local" or "server"
#' @export
detect_deployment_mode <- function() {
  # Check for common server environment indicators

  # shinyapps.io sets this
  if (Sys.getenv("SHINYAPPS") != "") {
    return("server")
  }


  # shiny-server typically runs as 'shiny' user
  if (Sys.info()["user"] == "shiny") {
    return("server")
  }

  # Docker container indicator
  if (file.exists("/.dockerenv")) {
    return("server")
  }

  # Check if we have write access to user's Documents folder
  docs_path <- get_user_documents_path()
  if (!is.null(docs_path) && dir.exists(docs_path)) {
    test_file <- file.path(docs_path, ".marinesabres_write_test")
    tryCatch({
      writeLines("test", test_file)
      file.remove(test_file)
      return("local")
    }, error = function(e) {
      # Cannot write to Documents - likely server mode
      return("server")
    })
  }

  # Default to server mode (safer)
  return("server")
}

#' Get the user's Documents folder path
#'
#' Cross-platform detection of Documents folder
#'
#' @return Character path or NULL if not found
#' @export
get_user_documents_path <- function() {
  # Windows
  if (.Platform$OS.type == "windows") {
    # Try USERPROFILE first (most reliable on Windows)
    user_profile <- Sys.getenv("USERPROFILE")
    if (user_profile != "") {
      docs <- file.path(user_profile, "Documents")
      if (dir.exists(docs)) return(normalizePath(docs, winslash = "/"))

      # Try OneDrive Documents (common in enterprise)
      onedrive <- Sys.getenv("OneDrive")
      if (onedrive != "") {
        docs <- file.path(onedrive, "Documents")
        if (dir.exists(docs)) return(normalizePath(docs, winslash = "/"))
      }
    }
  }

  # Unix/Mac - use HOME
  home <- Sys.getenv("HOME")
  if (home != "") {
    # macOS
    docs <- file.path(home, "Documents")
    if (dir.exists(docs)) return(docs)

    # Linux - might not have Documents
    if (dir.exists(home)) return(home)
  }

  return(NULL)
}

# ============================================================================
# STORAGE CONFIGURATION MANAGEMENT
# ============================================================================

#' Get the path to the storage config file
#'
#' @return Character path to config file
get_storage_config_path <- function() {
  # Store config in user's home directory (hidden file)
  home <- Sys.getenv("HOME")
  if (home == "") {
    home <- Sys.getenv("USERPROFILE")
  }
  if (home == "") {
    return(NULL)
  }
  file.path(home, STORAGE_CONFIG_FILE)
}

#' Get the suggested default projects folder path
#'
#' Returns the suggested path without creating it.
#'
#' @return Character path to suggested folder or NULL
#' @export
get_suggested_projects_folder <- function() {
  docs_path <- get_user_documents_path()
  if (is.null(docs_path)) {
    return(NULL)
  }
  file.path(docs_path, MARINESABRES_PROJECTS_FOLDER)
}

#' Check if storage has been configured by the user
#'
#' @return Logical TRUE if configured, FALSE otherwise
#' @export
is_storage_configured <- function() {
  config_path <- get_storage_config_path()
  if (is.null(config_path)) return(FALSE)
  file.exists(config_path)
}

#' Get the configured projects folder path
#'
#' Returns the user-configured path, or NULL if not configured.
#'
#' @return Character path or NULL
#' @export
get_configured_projects_folder <- function() {
  config_path <- get_storage_config_path()
  if (is.null(config_path) || !file.exists(config_path)) {
    return(NULL)
  }

  tryCatch({
    config <- readRDS(config_path)
    if (!is.list(config)) {
      debug_log("Invalid config file format, ignoring", "PERSISTENT_STORAGE")
      return(NULL)
    }
    if (!is.null(config$projects_folder) && dir.exists(config$projects_folder)) {
      return(normalizePath(config$projects_folder, winslash = "/"))
    }
    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

#' Set the projects folder path (user confirmed)
#'
#' Creates the folder if it doesn't exist and saves the configuration.
#'
#' @param folder_path Path to the projects folder
#' @return List with success status
#' @export
set_projects_folder <- function(folder_path) {
  if (is.null(folder_path) || folder_path == "") {
    return(list(success = FALSE, error = "No folder path provided"))
  }

  # Create folder if it doesn't exist
  if (!dir.exists(folder_path)) {
    tryCatch({
      dir.create(folder_path, recursive = TRUE)
      debug_log(sprintf("Created projects folder: %s", folder_path), "PERSISTENT_STORAGE")
    }, error = function(e) {
      return(list(success = FALSE, error = paste("Cannot create folder:", e$message)))
    })
  }

  # Create README file
  readme_path <- file.path(folder_path, "README.txt")
  if (!file.exists(readme_path)) {
    tryCatch({
      readme_content <- paste0(
        "MarineSABRES SES Toolbox - Projects Folder\n",
        "==========================================\n\n",
        "This folder contains your saved SES (Social-Ecological Systems) projects.\n\n",
        "Files:\n",
        "- .rds files: Project saves (can be loaded in the SES Toolbox)\n",
        "- .json files: JSON exports (can be shared or imported)\n\n",
        "To load a project:\n",
        "1. Open the SES Toolbox\n",
        "2. Go to 'Recent Projects' in the sidebar\n",
        "3. Click on the project you want to load\n\n",
        "Or use: File > Load Project and navigate to this folder.\n\n",
        "Created: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n"
      )
      writeLines(readme_content, readme_path)
    }, error = function(e) {
      # Non-fatal, continue
    })
  }

  # Create autosave subfolder
  autosave_folder <- file.path(folder_path, ".autosave")
  if (!dir.exists(autosave_folder)) {
    tryCatch({
      dir.create(autosave_folder, recursive = TRUE)
    }, error = function(e) {
      # Non-fatal
    })
  }

  # Save configuration
  config_path <- get_storage_config_path()
  if (is.null(config_path)) {
    return(list(success = FALSE, error = "Cannot determine config location"))
  }

  tryCatch({
    config <- list(
      projects_folder = normalizePath(folder_path, winslash = "/"),
      configured_at = Sys.time(),
      version = "1.0"
    )
    saveRDS(config, config_path)
    debug_log(sprintf("Storage configured: %s", folder_path), "PERSISTENT_STORAGE")
    return(list(success = TRUE, path = folder_path))
  }, error = function(e) {
    return(list(success = FALSE, error = paste("Cannot save config:", e$message)))
  })
}

#' Clear storage configuration
#'
#' @return Logical TRUE if cleared successfully
#' @export
clear_storage_config <- function() {
  config_path <- get_storage_config_path()
  if (!is.null(config_path) && file.exists(config_path)) {
    file.remove(config_path)
    return(TRUE)
  }
  return(FALSE)
}

# ============================================================================
# PROJECTS FOLDER MANAGEMENT
# ============================================================================

#' Get the MarineSABRES projects folder
#'
#' Returns the configured folder path if set, NULL otherwise.
#' Does NOT auto-create folders - user must confirm first.
#'
#' @param create_if_missing Ignored (kept for API compatibility)
#' @return Character path to projects folder or NULL
#' @export
get_projects_folder <- function(create_if_missing = FALSE) {
  # Only works in local mode
  mode <- detect_deployment_mode()
  if (mode != "local") {
    return(NULL)
  }

  # Return configured folder (user has already confirmed)
  return(get_configured_projects_folder())
}

#' List all projects in the projects folder
#'
#' @param folder_path Path to projects folder (defaults to get_projects_folder())
#' @return Data frame with project info or empty data frame
#' @export
list_saved_projects <- function(folder_path = NULL) {
  if (is.null(folder_path)) {
    folder_path <- get_projects_folder(create_if_missing = FALSE)
  }

  if (is.null(folder_path) || !dir.exists(folder_path)) {
    return(data.frame(
      name = character(),
      path = character(),
      size_kb = numeric(),
      modified = as.POSIXct(character()),
      type = character()
      
    ))
  }

  # Find all project files
  files <- list.files(
    folder_path,
    pattern = "\\.(rds|json)$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) == 0) {
    return(data.frame(
      name = character(),
      path = character(),
      size_kb = numeric(),
      modified = as.POSIXct(character()),
      type = character()
      
    ))
  }

  # Get file info
  file_info <- file.info(files)

  # Build data frame
  projects <- data.frame(
    name = tools::file_path_sans_ext(basename(files)),
    path = files,
    size_kb = round(file_info$size / 1024, 1),
    modified = file_info$mtime,
    type = ifelse(grepl("\\.rds$", files, ignore.case = TRUE), "rds", "json")
    
  )

  # Sort by modification time (newest first)
  projects <- projects[order(projects$modified, decreasing = TRUE), ]
  rownames(projects) <- NULL

  return(projects)
}

# ============================================================================
# PROJECT SAVE/LOAD FUNCTIONS
# ============================================================================

#' Save a project to the persistent projects folder
#'
#' @param project_data The project data to save
#' @param project_name Name for the project file (without extension)
#' @param folder_path Path to save to (defaults to projects folder)
#' @param format File format: "rds" or "json"
#' @return List with success status and file path
#' @export
save_project_persistent <- function(project_data, project_name = NULL,
                                    folder_path = NULL, format = "rds") {
  if (is.null(folder_path)) {
    folder_path <- get_projects_folder(create_if_missing = TRUE)
  }

  if (is.null(folder_path)) {
    return(list(
      success = FALSE,
      error = "Could not access projects folder",
      path = NULL
    ))
  }

  # Generate project name if not provided
  if (is.null(project_name) || project_name == "") {
    # Try to extract from project data
    project_name <- project_data$project_id %||%
                    project_data$metadata$project_name %||%
                    paste0("project_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  }

  # Sanitize filename
  project_name <- gsub("[^a-zA-Z0-9_-]", "_", project_name)

  # Add timestamp to avoid overwrites
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- sprintf("%s_%s.%s", project_name, timestamp, format)
  file_path <- file.path(folder_path, filename)

  tryCatch({
    if (format == "rds") {
      # Add save metadata
      project_data$save_metadata <- list(
        saved_at = Sys.time(),
        format = "rds",
        app_version = APP_VERSION %||% "unknown"
      )
      saveRDS(project_data, file_path)
    } else {
      # JSON format
      json_data <- jsonlite::toJSON(project_data, auto_unbox = TRUE,
                                     null = "null", pretty = TRUE)
      writeLines(json_data, file_path)
    }

    debug_log(sprintf("Saved project to: %s", file_path), "PERSISTENT_STORAGE")

    return(list(
      success = TRUE,
      path = file_path,
      filename = filename,
      folder = folder_path
    ))

  }, error = function(e) {
    debug_log(sprintf("Failed to save project: %s", e$message), "PERSISTENT_STORAGE")
    return(list(
      success = FALSE,
      error = e$message,
      path = NULL
    ))
  })
}

#' Load a project from file
#'
#' @param file_path Path to the project file
#' @return List with success status and project data
#' @export
load_project_persistent <- function(file_path) {
  if (!file.exists(file_path)) {
    return(list(
      success = FALSE,
      error = "File not found",
      data = NULL
    ))
  }

  tryCatch({
    # Determine format from extension
    is_rds <- grepl("\\.rds$", file_path, ignore.case = TRUE)

    if (is_rds) {
      project_data <- readRDS(file_path)
      if (!is.list(project_data)) {
        debug_log(paste("Invalid project file format:", file_path), "PERSISTENT_STORAGE")
        return(NULL)
      }
    } else {
      # JSON format - use safe parser for user-provided files
      json_content <- readLines(file_path, warn = FALSE)
      project_data <- safe_parse_json(paste(json_content, collapse = "\n"))
      if (is.null(project_data)) {
        return(list(
          success = FALSE,
          error = "Invalid or malformed JSON in project file",
          data = NULL
        ))
      }
    }

    debug_log(sprintf("Loaded project from: %s", file_path), "PERSISTENT_STORAGE")

    return(list(
      success = TRUE,
      data = project_data,
      path = file_path
    ))

  }, error = function(e) {
    debug_log(sprintf("Failed to load project: %s", e$message), "PERSISTENT_STORAGE")
    return(list(
      success = FALSE,
      error = e$message,
      data = NULL
    ))
  })
}

#' Delete a project file
#'
#' @param file_path Path to the project file
#' @return List with success status
#' @export
delete_project_persistent <- function(file_path) {
  if (!file.exists(file_path)) {
    return(list(success = TRUE))  # Already deleted
  }

  tryCatch({
    file.remove(file_path)
    debug_log(sprintf("Deleted project: %s", file_path), "PERSISTENT_STORAGE")
    return(list(success = TRUE))
  }, error = function(e) {
    return(list(success = FALSE, error = e$message))
  })
}

# ============================================================================
# AUTOSAVE TO PERSISTENT FOLDER
# ============================================================================

#' Get the autosave file path for persistent storage
#'
#' In local mode, saves to the projects folder.
#' In server mode, returns NULL (use session temp dir instead).
#'
#' @param session_id Unique session identifier
#' @return Character path or NULL
#' @export
get_persistent_autosave_path <- function(session_id = NULL) {
  folder_path <- get_projects_folder(create_if_missing = TRUE)

  if (is.null(folder_path)) {
    return(NULL)
  }

  # Create autosave subfolder
  autosave_folder <- file.path(folder_path, ".autosave")
  if (!dir.exists(autosave_folder)) {
    dir.create(autosave_folder, recursive = TRUE)
  }

  # Use session_id in filename if provided
  if (!is.null(session_id)) {
    filename <- sprintf("autosave_%s.rds", substr(session_id, 1, 16))
  } else {
    filename <- "autosave_latest.rds"
  }

  return(file.path(autosave_folder, filename))
}

#' Find recoverable autosave files
#'
#' Lists autosave files that can be recovered from the persistent folder.
#'
#' @param max_age_hours Maximum age of autosave files to consider
#' @return Data frame with recoverable autosave info
#' @export
find_recoverable_autosaves <- function(max_age_hours = 72) {
  folder_path <- get_projects_folder(create_if_missing = FALSE)

  if (is.null(folder_path)) {
    return(data.frame())
  }

  autosave_folder <- file.path(folder_path, ".autosave")
  if (!dir.exists(autosave_folder)) {
    return(data.frame())
  }

  files <- list.files(autosave_folder, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0) {
    return(data.frame())
  }

  # Get file info and filter by age
  file_info <- file.info(files)
  cutoff_time <- Sys.time() - (max_age_hours * 3600)

  valid_files <- files[file_info$mtime > cutoff_time]

  if (length(valid_files) == 0) {
    return(data.frame())
  }

  valid_info <- file_info[file_info$mtime > cutoff_time, ]

  return(data.frame(
    path = valid_files,
    modified = valid_info$mtime,
    size_kb = round(valid_info$size / 1024, 1)
    
  ))
}

# ============================================================================
# USER IDENTIFIER MANAGEMENT
# ============================================================================

#' Get or set user identifier for project organization
#'
#' Stores a simple user name/identifier in the projects folder
#' for organizing and identifying projects.
#'
#' @param user_name If provided, sets the user name; if NULL, gets current
#' @return Character user name or NULL
#' @export
user_identifier <- function(user_name = NULL) {
  folder_path <- get_projects_folder(create_if_missing = TRUE)

  if (is.null(folder_path)) {
    return(NULL)
  }

  user_file <- file.path(folder_path, ".user_identity.txt")

  if (!is.null(user_name)) {
    # Set user name
    writeLines(user_name, user_file)
    debug_log(sprintf("Set user identifier: %s", user_name), "PERSISTENT_STORAGE")
    return(user_name)
  }

  # Get user name
  if (file.exists(user_file)) {
    return(trimws(readLines(user_file, n = 1, warn = FALSE)))
  }

  return(NULL)
}

#' Get display-friendly folder path
#'
#' Returns a shortened version of the path for UI display.
#'
#' @param path Full path
#' @return Shortened path for display
#' @export
get_display_path <- function(path) {
  if (is.null(path)) return("Not configured")

  # Replace home dir with ~
  home <- Sys.getenv("HOME")
  if (home != "" && startsWith(path, home)) {
    path <- sub(home, "~", path, fixed = TRUE)
  }

  # Windows: replace user profile
  user_profile <- Sys.getenv("USERPROFILE")
  if (user_profile != "" && startsWith(path, user_profile)) {
    path <- sub(user_profile, "~", path, fixed = TRUE)
  }

  return(path)
}
