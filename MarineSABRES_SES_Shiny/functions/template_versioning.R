# ==============================================================================
# Template Versioning System (Week 9)
# ==============================================================================
# Functions for tracking template versions, model performance, and metadata.
# Enables reproducibility, comparison across versions, and rollback capabilities.
#
# Features:
# - Template metadata tracking
# - Version history management
# - Model performance logging
# - Training configuration storage
# - Version comparison
#
# Author: Phase 2 ML Enhancement - Week 9
# Date: 2026-01-01
# ==============================================================================

# ==============================================================================
# Version Metadata Functions
# ==============================================================================

#' Create Template Version Metadata
#'
#' @param template_name Character. Name of the template
#' @param version Character. Version number (e.g., "1.0", "1.1")
#' @param author Character. Template author
#' @param description Character. Version description
#' @param regional_sea Character. Regional sea
#' @param ecosystem_types Character. Semicolon-separated ecosystem types
#' @param main_issues Character. Semicolon-separated main issues
#' @param source_template Character. Source template for transfer learning (optional)
#' @param training_strategy Character. "finetune", "scratch", or "pretrained"
#' @param model_path Character. Path to trained model file
#' @param performance List. Performance metrics (accuracy, loss, etc.)
#' @param training_config List. Training configuration (epochs, lr, etc.)
#' @param notes Character. Additional notes
#' @return List with version metadata
#' @export
create_template_version <- function(template_name,
                                    version,
                                    author = "",
                                    description = "",
                                    regional_sea = "",
                                    ecosystem_types = "",
                                    main_issues = "",
                                    source_template = NULL,
                                    training_strategy = "scratch",
                                    model_path = NULL,
                                    performance = NULL,
                                    training_config = NULL,
                                    notes = "") {

  metadata <- list(
    # Template information
    template_name = template_name,
    version = version,
    author = author,
    description = description,
    created_date = Sys.time(),

    # Context information
    regional_sea = regional_sea,
    ecosystem_types = ecosystem_types,
    main_issues = main_issues,

    # Transfer learning information
    source_template = source_template,
    training_strategy = training_strategy,

    # Model information
    model_path = model_path,
    performance = performance,
    training_config = training_config,

    # Additional notes
    notes = notes,

    # System information
    r_version = R.version.string,
    torch_version = if (requireNamespace("torch", quietly = TRUE)) {
      as.character(packageVersion("torch"))
    } else {
      "not available"
    }
  )

  class(metadata) <- c("template_version", "list")
  return(metadata)
}

#' Save Template Version
#'
#' @param version_metadata List. Version metadata from create_template_version()
#' @param versions_dir Character. Directory to store version files
#' @return Character. Path to saved version file
#' @export
save_template_version <- function(version_metadata,
                                  versions_dir = "models/template_versions") {

  # Create directory if needed
  if (!dir.exists(versions_dir)) {
    dir.create(versions_dir, recursive = TRUE)
  }

  # Generate filename
  template_slug <- gsub(" ", "_", tolower(version_metadata$template_name))
  version_slug <- gsub("\\.", "_", version_metadata$version)
  timestamp <- format(version_metadata$created_date, "%Y%m%d_%H%M%S")

  filename <- sprintf("%s_v%s_%s.rds",
                     template_slug,
                     version_slug,
                     timestamp)

  filepath <- file.path(versions_dir, filename)

  # Save metadata
  saveRDS(version_metadata, filepath)

  debug_log(sprintf("Template version saved: %s", filepath), "TEMPLATE_VERSION")

  return(filepath)
}

#' Load Template Version
#'
#' @param filepath Character. Path to version metadata file
#' @return List. Version metadata
#' @export
load_template_version <- function(filepath) {
  if (!file.exists(filepath)) {
    stop("Version file not found: ", filepath)
  }

  metadata <- readRDS(filepath)

  if (!inherits(metadata, "template_version")) {
    warning("File may not be a valid template version")
  }

  return(metadata)
}

# ==============================================================================
# Version History Functions
# ==============================================================================

#' Get Template Version History
#'
#' @param template_name Character. Template name
#' @param versions_dir Character. Directory containing version files
#' @return Dataframe with version history
#' @export
get_version_history <- function(template_name,
                                versions_dir = "models/template_versions") {

  if (!dir.exists(versions_dir)) {
    return(data.frame())
  }

  # Find all version files for this template
  template_slug <- gsub(" ", "_", tolower(template_name))
  pattern <- sprintf("^%s_v.*\\.rds$", template_slug)

  files <- list.files(versions_dir, pattern = pattern, full.names = TRUE)

  if (length(files) == 0) {
    return(data.frame())
  }

  # Load all versions
  history <- data.frame(
    version = character(),
    created_date = character(),
    author = character(),
    strategy = character(),
    source_template = character(),
    accuracy = numeric(),
    val_loss = numeric(),
    model_path = character(),
    notes = character(),
    filepath = character(),
    stringsAsFactors = FALSE
  )

  for (file in files) {
    tryCatch({
      meta <- readRDS(file)

      # Extract performance metrics
      accuracy <- if (!is.null(meta$performance$accuracy)) {
        meta$performance$accuracy
      } else if (!is.null(meta$performance$test_accuracy)) {
        meta$performance$test_accuracy
      } else {
        NA
      }

      val_loss <- if (!is.null(meta$performance$val_loss)) {
        meta$performance$val_loss
      } else if (!is.null(meta$performance$best_val_loss)) {
        meta$performance$best_val_loss
      } else {
        NA
      }

      history <- rbind(history, data.frame(
        version = meta$version,
        created_date = as.character(meta$created_date),
        author = meta$author,
        strategy = meta$training_strategy,
        source_template = ifelse(is.null(meta$source_template), "", meta$source_template),
        accuracy = accuracy,
        val_loss = val_loss,
        model_path = ifelse(is.null(meta$model_path), "", meta$model_path),
        notes = meta$notes,
        filepath = file,
        stringsAsFactors = FALSE
      ))
    }, error = function(e) {
      warning(sprintf("Failed to load version file: %s (%s)", file, e$message))
    })
  }

  # Sort by date (most recent first)
  if (nrow(history) > 0) {
    history <- history[order(history$created_date, decreasing = TRUE), ]
  }

  return(history)
}

#' Get Latest Template Version
#'
#' @param template_name Character. Template name
#' @param versions_dir Character. Directory containing version files
#' @return List. Latest version metadata, or NULL if none found
#' @export
get_latest_version <- function(template_name,
                               versions_dir = "models/template_versions") {

  history <- get_version_history(template_name, versions_dir)

  if (nrow(history) == 0) {
    return(NULL)
  }

  # Load the most recent version
  latest_file <- history$filepath[1]
  return(load_template_version(latest_file))
}

#' Compare Template Versions
#'
#' @param version1_path Character. Path to first version file
#' @param version2_path Character. Path to second version file
#' @return List with comparison details
#' @export
compare_versions <- function(version1_path, version2_path) {

  v1 <- load_template_version(version1_path)
  v2 <- load_template_version(version2_path)

  comparison <- list(
    version1 = list(
      version = v1$version,
      date = v1$created_date,
      strategy = v1$training_strategy,
      source = v1$source_template,
      accuracy = v1$performance$accuracy %||% v1$performance$test_accuracy %||% NA,
      val_loss = v1$performance$val_loss %||% v1$performance$best_val_loss %||% NA
    ),
    version2 = list(
      version = v2$version,
      date = v2$created_date,
      strategy = v2$training_strategy,
      source = v2$source_template,
      accuracy = v2$performance$accuracy %||% v2$performance$test_accuracy %||% NA,
      val_loss = v2$performance$val_loss %||% v2$performance$best_val_loss %||% NA
    ),
    differences = list()
  )

  # Calculate differences
  if (!is.na(comparison$version1$accuracy) && !is.na(comparison$version2$accuracy)) {
    comparison$differences$accuracy_change <- comparison$version2$accuracy - comparison$version1$accuracy
    comparison$differences$accuracy_pct_change <-
      (comparison$version2$accuracy / comparison$version1$accuracy - 1) * 100
  }

  if (!is.na(comparison$version1$val_loss) && !is.na(comparison$version2$val_loss)) {
    comparison$differences$val_loss_change <- comparison$version2$val_loss - comparison$version1$val_loss
    comparison$differences$val_loss_pct_change <-
      (comparison$version2$val_loss / comparison$version1$val_loss - 1) * 100
  }

  # Context changes
  comparison$differences$context_changed <- (
    v1$regional_sea != v2$regional_sea ||
    v1$ecosystem_types != v2$ecosystem_types ||
    v1$main_issues != v2$main_issues
  )

  comparison$differences$strategy_changed <- v1$training_strategy != v2$training_strategy

  return(comparison)
}

# ==============================================================================
# Version Management Functions
# ==============================================================================

#' Create New Version from Existing
#'
#' @param base_version_path Character. Path to base version
#' @param new_version Character. New version number
#' @param changes Character. Description of changes
#' @param model_path Character. Path to new model (optional)
#' @param performance List. New performance metrics (optional)
#' @return List. New version metadata
#' @export
create_new_version_from_base <- function(base_version_path,
                                         new_version,
                                         changes = "",
                                         model_path = NULL,
                                         performance = NULL) {

  base <- load_template_version(base_version_path)

  # Increment version if not specified
  if (missing(new_version)) {
    # Parse version number
    version_parts <- as.numeric(strsplit(base$version, "\\.")[[1]])
    version_parts[length(version_parts)] <- version_parts[length(version_parts)] + 1
    new_version <- paste(version_parts, collapse = ".")
  }

  # Create new version inheriting from base
  new_metadata <- create_template_version(
    template_name = base$template_name,
    version = new_version,
    author = base$author,
    description = base$description,
    regional_sea = base$regional_sea,
    ecosystem_types = base$ecosystem_types,
    main_issues = base$main_issues,
    source_template = base$source_template,
    training_strategy = base$training_strategy,
    model_path = model_path %||% base$model_path,
    performance = performance %||% base$performance,
    training_config = base$training_config,
    notes = sprintf("Based on v%s. Changes: %s", base$version, changes)
  )

  return(new_metadata)
}

#' Delete Template Version
#'
#' @param version_path Character. Path to version file to delete
#' @param confirm Logical. Require confirmation (default: TRUE)
#' @return Logical. TRUE if deleted successfully
#' @export
delete_version <- function(version_path, confirm = TRUE) {

  if (!file.exists(version_path)) {
    warning("Version file not found: ", version_path)
    return(FALSE)
  }

  if (confirm) {
    meta <- readRDS(version_path)
    message(sprintf("Delete version %s of template '%s'? (created %s)",
                   meta$version,
                   meta$template_name,
                   meta$created_date))

    response <- readline("Type 'yes' to confirm: ")
    if (tolower(trimws(response)) != "yes") {
      message("Deletion cancelled")
      return(FALSE)
    }
  }

  file.remove(version_path)
  debug_log(sprintf("Version deleted: %s", version_path), "TEMPLATE_VERSION")

  return(TRUE)
}

# ==============================================================================
# Reporting Functions
# ==============================================================================

#' Print Version Summary
#'
#' @param version_metadata List. Version metadata
#' @export
print_version_summary <- function(version_metadata) {

  cat("\n")
  cat("==================================================================\n")
  cat(sprintf("  Template: %s (v%s)\n", version_metadata$template_name, version_metadata$version))
  cat("==================================================================\n\n")

  cat(sprintf("Author: %s\n", version_metadata$author))
  cat(sprintf("Created: %s\n", version_metadata$created_date))
  cat(sprintf("Description: %s\n\n", version_metadata$description))

  cat("Context:\n")
  cat(sprintf("  Regional Sea: %s\n", version_metadata$regional_sea))
  cat(sprintf("  Ecosystems: %s\n", version_metadata$ecosystem_types))
  cat(sprintf("  Main Issues: %s\n\n", version_metadata$main_issues))

  cat("Training:\n")
  cat(sprintf("  Strategy: %s\n", version_metadata$training_strategy))
  if (!is.null(version_metadata$source_template)) {
    cat(sprintf("  Source Template: %s\n", version_metadata$source_template))
  }

  if (!is.null(version_metadata$performance)) {
    cat("\nPerformance:\n")
    perf <- version_metadata$performance
    if (!is.null(perf$accuracy) || !is.null(perf$test_accuracy)) {
      acc <- perf$accuracy %||% perf$test_accuracy
      cat(sprintf("  Accuracy: %.2f%%\n", acc * 100))
    }
    if (!is.null(perf$val_loss) || !is.null(perf$best_val_loss)) {
      loss <- perf$val_loss %||% perf$best_val_loss
      cat(sprintf("  Validation Loss: %.4f\n", loss))
    }
    if (!is.null(perf$f1_score)) {
      cat(sprintf("  F1 Score: %.3f\n", perf$f1_score))
    }
  }

  if (!is.null(version_metadata$training_config)) {
    cat("\nTraining Configuration:\n")
    cfg <- version_metadata$training_config
    if (!is.null(cfg$epochs)) cat(sprintf("  Epochs: %d\n", cfg$epochs))
    if (!is.null(cfg$learning_rate)) cat(sprintf("  Learning Rate: %.5f\n", cfg$learning_rate))
    if (!is.null(cfg$batch_size)) cat(sprintf("  Batch Size: %d\n", cfg$batch_size))
    if (!is.null(cfg$frozen_layers)) {
      cat(sprintf("  Frozen Layers: %s\n", paste(cfg$frozen_layers, collapse = ", ")))
    }
  }

  if (!is.null(version_metadata$model_path) && version_metadata$model_path != "") {
    cat(sprintf("\nModel Path: %s\n", version_metadata$model_path))
  }

  if (version_metadata$notes != "") {
    cat(sprintf("\nNotes: %s\n", version_metadata$notes))
  }

  cat("\n")
}

#' Generate Version History Report
#'
#' @param template_name Character. Template name
#' @param output_file Character. Output file path (optional)
#' @param versions_dir Character. Directory containing version files
#' @export
generate_version_report <- function(template_name,
                                    output_file = NULL,
                                    versions_dir = "models/template_versions") {

  history <- get_version_history(template_name, versions_dir)

  if (nrow(history) == 0) {
    message(sprintf("No version history found for template: %s", template_name))
    return(invisible(NULL))
  }

  # Generate report
  report <- character()

  report <- c(report, "")
  report <- c(report, "==================================================================")
  report <- c(report, sprintf("  Version History: %s", template_name))
  report <- c(report, "==================================================================")
  report <- c(report, "")
  report <- c(report, sprintf("Total Versions: %d", nrow(history)))
  report <- c(report, sprintf("Latest Version: %s (created %s)",
                             history$version[1],
                             history$created_date[1]))
  report <- c(report, "")

  # Version table
  report <- c(report, "Version History:")
  report <- c(report, "───────────────────────────────────────────────────────────────────────")
  report <- c(report, sprintf("%-8s %-20s %-15s %-12s %10s",
                             "Version", "Date", "Strategy", "Source", "Accuracy"))
  report <- c(report, "───────────────────────────────────────────────────────────────────────")

  for (i in 1:nrow(history)) {
    row <- history[i, ]
    acc_str <- if (!is.na(row$accuracy)) {
      sprintf("%.2f%%", row$accuracy * 100)
    } else {
      "N/A"
    }

    source_str <- if (row$source_template != "") {
      substr(row$source_template, 1, 12)
    } else {
      "-"
    }

    report <- c(report, sprintf("%-8s %-20s %-15s %-12s %10s",
                               row$version,
                               substr(row$created_date, 1, 19),
                               row$strategy,
                               source_str,
                               acc_str))
  }

  report <- c(report, "───────────────────────────────────────────────────────────────────────")
  report <- c(report, "")

  # Performance trends
  accuracies <- history$accuracy[!is.na(history$accuracy)]
  if (length(accuracies) >= 2) {
    best_acc <- max(accuracies)
    worst_acc <- min(accuracies)
    latest_acc <- accuracies[1]

    report <- c(report, "Performance Summary:")
    report <- c(report, sprintf("  Best Accuracy: %.2f%% (version %s)",
                               best_acc * 100,
                               history$version[which.max(history$accuracy)]))
    report <- c(report, sprintf("  Latest Accuracy: %.2f%%", latest_acc * 100))
    report <- c(report, sprintf("  Range: %.2f%% - %.2f%%", worst_acc * 100, best_acc * 100))
    report <- c(report, "")
  }

  # Training strategy breakdown
  strategy_counts <- table(history$strategy)
  report <- c(report, "Training Strategies Used:")
  for (strategy in names(strategy_counts)) {
    report <- c(report, sprintf("  %s: %d versions",
                               strategy,
                               strategy_counts[strategy]))
  }
  report <- c(report, "")

  # Output
  report_text <- paste(report, collapse = "\n")

  if (!is.null(output_file)) {
    writeLines(report_text, output_file)
    debug_log(sprintf("Version report saved: %s", output_file), "TEMPLATE_VERSION")
  } else {
    cat(report_text)
  }

  return(invisible(history))
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' List All Templates with Versions
#'
#' @param versions_dir Character. Directory containing version files
#' @return Dataframe with template summary
#' @export
list_all_templates <- function(versions_dir = "models/template_versions") {

  if (!dir.exists(versions_dir)) {
    return(data.frame())
  }

  files <- list.files(versions_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0) {
    return(data.frame())
  }

  # Extract template names and count versions
  template_summary <- data.frame(
    template_name = character(),
    num_versions = integer(),
    latest_version = character(),
    latest_date = character(),
    best_accuracy = numeric(),
    stringsAsFactors = FALSE
  )

  templates <- character()

  for (file in files) {
    tryCatch({
      meta <- readRDS(file)
      templates <- c(templates, meta$template_name)
    }, error = function(e) {
      # Skip invalid files
    })
  }

  unique_templates <- unique(templates)

  for (template in unique_templates) {
    history <- get_version_history(template, versions_dir)

    if (nrow(history) > 0) {
      best_acc <- max(history$accuracy, na.rm = TRUE)
      if (is.infinite(best_acc)) best_acc <- NA

      template_summary <- rbind(template_summary, data.frame(
        template_name = template,
        num_versions = nrow(history),
        latest_version = history$version[1],
        latest_date = history$created_date[1],
        best_accuracy = best_acc,
        stringsAsFactors = FALSE
      ))
    }
  }

  return(template_summary)
}

# ==============================================================================
# Startup Message
# ==============================================================================

debug_log("Template Versioning module loaded", "TEMPLATE_VERSION")
debug_log("create_template_version(): Create version metadata", "TEMPLATE_VERSION")
debug_log("save_template_version(): Save version to disk", "TEMPLATE_VERSION")
debug_log("get_version_history(): Retrieve version history", "TEMPLATE_VERSION")
debug_log("compare_versions(): Compare two versions", "TEMPLATE_VERSION")
debug_log("generate_version_report(): Generate version report", "TEMPLATE_VERSION")
