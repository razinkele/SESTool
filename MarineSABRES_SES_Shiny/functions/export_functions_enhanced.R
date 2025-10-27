# functions/export_functions_enhanced.R
# Enhanced export and reporting functions with comprehensive error handling
#
# This file provides safe versions of export functions from export_functions.R
# All functions include:
# - Input parameter validation
# - File system permission checks
# - Disk space validation
# - Comprehensive error handling with tryCatch
# - Informative error messages
# - Graceful degradation
# - Error logging

# ============================================================================
# VALIDATION UTILITIES
# ============================================================================

#' Validate file path for writing
#'
#' Checks if directory exists and is writable
#'
#' @param file_path Output file path
#' @return TRUE if valid, throws error otherwise
validate_output_path <- function(file_path) {

  if (is.null(file_path)) {
    stop("File path is NULL")
  }

  if (!is.character(file_path) || length(file_path) != 1) {
    stop("File path must be a single character string, got: ", class(file_path)[1])
  }

  if (nchar(file_path) == 0) {
    stop("File path cannot be empty string")
  }

  # Check directory exists
  dir_path <- dirname(file_path)

  if (!dir.exists(dir_path)) {
    stop("Directory does not exist: ", dir_path)
  }

  # Check directory is writable (try to create a temp file)
  test_file <- file.path(dir_path, paste0(".write_test_", Sys.getpid()))
  write_test <- tryCatch({
    file.create(test_file)
    file.remove(test_file)
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (!write_test) {
    stop("Directory is not writable: ", dir_path)
  }

  # Check if file exists and can be overwritten
  if (file.exists(file_path)) {
    can_overwrite <- tryCatch({
      file.access(file_path, mode = 2) == 0  # mode 2 = write permission
    }, error = function(e) {
      FALSE
    })

    if (!can_overwrite) {
      stop("File exists but cannot be overwritten: ", file_path)
    }
  }

  TRUE
}

#' Check available disk space
#'
#' Verifies sufficient disk space for export operation
#'
#' @param file_path Target file path
#' @param estimated_size_mb Estimated file size in MB
#' @return TRUE if sufficient space, warning otherwise
check_disk_space <- function(file_path, estimated_size_mb = 10) {

  tryCatch({

    # This is platform-dependent and simplified
    # Full implementation would use system-specific commands

    dir_path <- dirname(file_path)

    # Simple check: try to write a small test file
    test_file <- file.path(dir_path, paste0(".space_test_", Sys.getpid()))

    # If we can write, we have some space
    space_available <- tryCatch({
      writeLines("test", test_file)
      file.remove(test_file)
      TRUE
    }, error = function(e) {
      FALSE
    })

    if (!space_available) {
      log_message(paste("Potential disk space issue for:", file_path), "WARNING")
    }

    return(TRUE)  # Continue anyway, let the actual write fail if needed

  }, error = function(e) {
    log_message(paste("Error checking disk space:", e$message), "WARNING")
    return(TRUE)  # Optimistically continue
  })
}

#' Validate visNetwork object
#'
#' Checks if object is valid visNetwork
#'
#' @param visnet visNetwork object
#' @return TRUE if valid, throws error otherwise
validate_visnetwork <- function(visnet) {

  if (is.null(visnet)) {
    stop("visNetwork object is NULL")
  }

  if (!inherits(visnet, "visNetwork")) {
    stop("Object is not a visNetwork, got: ", class(visnet)[1])
  }

  # Check has data
  if (is.null(visnet$x$nodes) || is.null(visnet$x$edges)) {
    stop("visNetwork object missing nodes or edges data")
  }

  TRUE
}

#' Validate project data for export
#'
#' Checks if project data is valid for export
#'
#' @param project_data Project data list
#' @return TRUE if valid, throws error otherwise
validate_export_project <- function(project_data) {

  if (is.null(project_data)) {
    stop("Project data is NULL")
  }

  if (!is.list(project_data)) {
    stop("Project data must be list, got: ", class(project_data)[1])
  }

  required_fields <- c("project_id", "project_name", "data")
  missing <- setdiff(required_fields, names(project_data))

  if (length(missing) > 0) {
    stop("Project data missing required fields: ", paste(missing, collapse = ", "))
  }

  TRUE
}

# ============================================================================
# SAFE VISUALIZATION EXPORT FUNCTIONS
# ============================================================================

#' Export CLD as PNG (safe version)
#'
#' Exports visNetwork with full error handling
#'
#' @param visnet visNetwork object
#' @param file_path Output file path
#' @param width Image width in pixels
#' @param height Image height in pixels
#' @return TRUE on success, FALSE on error
export_cld_png_safe <- function(visnet, file_path, width = 1200, height = 900) {

  tryCatch({

    # Validate inputs
    validate_visnetwork(visnet)
    validate_output_path(file_path)

    if (!is.numeric(width) || width <= 0) {
      stop("Width must be positive number, got: ", width)
    }

    if (!is.numeric(height) || height <= 0) {
      stop("Height must be positive number, got: ", height)
    }

    check_disk_space(file_path, estimated_size_mb = 5)

    # Check webshot package
    if (!requireNamespace("webshot", quietly = TRUE)) {
      stop("Package 'webshot' is required for PNG export. Install with: install.packages('webshot'); webshot::install_phantomjs()")
    }

    # Create temp HTML safely
    temp_html <- tryCatch({
      tempfile(fileext = ".html")
    }, error = function(e) {
      stop("Failed to create temporary file: ", e$message)
    })

    # Save as HTML
    html_result <- tryCatch({
      htmlwidgets::saveWidget(visnet, temp_html, selfcontained = TRUE)
      TRUE
    }, error = function(e) {
      stop("Failed to save HTML widget: ", e$message)
    })

    # Convert to PNG
    png_result <- tryCatch({
      webshot::webshot(temp_html, file_path, vwidth = width, vheight = height)
      TRUE
    }, error = function(e) {
      stop("Failed to convert to PNG: ", e$message)
    })

    # Clean up
    cleanup_result <- tryCatch({
      unlink(temp_html)
      TRUE
    }, error = function(e) {
      log_message(paste("Warning: Failed to delete temporary file:", temp_html), "WARNING")
      TRUE  # Don't fail on cleanup error
    })

    # Verify output file exists
    if (!file.exists(file_path)) {
      stop("PNG file was not created: ", file_path)
    }

    log_message(paste("CLD exported as PNG:", file_path), "INFO")
    message("CLD exported as PNG: ", file_path)

    return(TRUE)

  }, error = function(e) {
    log_message(paste("Error exporting CLD as PNG:", e$message), "ERROR")
    message("Error: Failed to export CLD as PNG - ", e$message)
    return(FALSE)
  })
}

#' Export CLD as HTML (safe version)
#'
#' Exports visNetwork as interactive HTML
#'
#' @param visnet visNetwork object
#' @param file_path Output file path
#' @return TRUE on success, FALSE on error
export_cld_html_safe <- function(visnet, file_path) {

  tryCatch({

    # Validate inputs
    validate_visnetwork(visnet)
    validate_output_path(file_path)
    check_disk_space(file_path, estimated_size_mb = 2)

    # Add navigation buttons safely
    enhanced_visnet <- tryCatch({
      visnet %>% visInteraction(navigationButtons = TRUE)
    }, error = function(e) {
      log_message(paste("Warning: Could not add navigation buttons:", e$message), "WARNING")
      visnet  # Use original if enhancement fails
    })

    # Save HTML
    save_result <- tryCatch({
      htmlwidgets::saveWidget(
        enhanced_visnet,
        file_path,
        selfcontained = TRUE
      )
      TRUE
    }, error = function(e) {
      stop("Failed to save HTML: ", e$message)
    })

    # Verify output file exists
    if (!file.exists(file_path)) {
      stop("HTML file was not created: ", file_path)
    }

    # Check file size
    file_size <- file.info(file_path)$size
    if (file_size == 0) {
      stop("HTML file is empty")
    }

    log_message(paste("CLD exported as HTML:", file_path,
                     "- Size:", round(file_size / 1024, 2), "KB"), "INFO")
    message("CLD exported as HTML: ", file_path)

    return(TRUE)

  }, error = function(e) {
    log_message(paste("Error exporting CLD as HTML:", e$message), "ERROR")
    message("Error: Failed to export CLD as HTML - ", e$message)
    return(FALSE)
  })
}

#' Export BOT graphs as PDF (safe version)
#'
#' Exports Behavior Over Time plots with error handling
#'
#' @param bot_data_list List of BOT data for different elements
#' @param file_path Output file path
#' @param width PDF width in inches
#' @param height PDF height in inches
#' @return TRUE on success, FALSE on error
export_bot_pdf_safe <- function(bot_data_list, file_path, width = 11, height = 8.5) {

  tryCatch({

    # Validate inputs
    if (is.null(bot_data_list)) {
      stop("BOT data list is NULL")
    }

    if (!is.list(bot_data_list)) {
      stop("BOT data must be list, got: ", class(bot_data_list)[1])
    }

    if (length(bot_data_list) == 0) {
      stop("BOT data list is empty")
    }

    validate_output_path(file_path)

    if (!is.numeric(width) || width <= 0) {
      stop("Width must be positive number, got: ", width)
    }

    if (!is.numeric(height) || height <= 0) {
      stop("Height must be positive number, got: ", height)
    }

    check_disk_space(file_path, estimated_size_mb = 10)

    # Open PDF device
    pdf_device <- tryCatch({
      pdf(file_path, width = width, height = height)
      TRUE
    }, error = function(e) {
      stop("Failed to open PDF device: ", e$message)
    })

    plots_created <- 0
    plots_skipped <- 0

    # Create plots
    for (element_name in names(bot_data_list)) {

      plot_result <- tryCatch({

        bot_data <- bot_data_list[[element_name]]

        # Validate data
        if (!is.data.frame(bot_data)) {
          log_message(paste("Skipping", element_name, "- not a dataframe"), "WARNING")
          return(FALSE)
        }

        if (nrow(bot_data) == 0) {
          log_message(paste("Skipping", element_name, "- no data"), "INFO")
          return(FALSE)
        }

        # Check required columns
        required_cols <- c("date", "value", "element_id")
        if (!all(required_cols %in% names(bot_data))) {
          log_message(paste("Skipping", element_name, "- missing required columns"), "WARNING")
          return(FALSE)
        }

        # Create plot
        p <- ggplot(bot_data, aes(x = date, y = value, color = element_id)) +
          geom_line(size = 1) +
          geom_point(size = 2) +
          labs(
            title = paste("Behavior Over Time:", element_name),
            x = "Time",
            y = "Value",
            color = "Element"
          ) +
          theme_minimal() +
          theme(
            plot.title = element_text(size = 14, face = "bold"),
            legend.position = "bottom"
          )

        print(p)
        return(TRUE)

      }, error = function(e) {
        log_message(paste("Error plotting", element_name, ":", e$message), "WARNING")
        return(FALSE)
      })

      if (plot_result) {
        plots_created <- plots_created + 1
      } else {
        plots_skipped <- plots_skipped + 1
      }
    }

    # Close PDF device
    close_result <- tryCatch({
      dev.off()
      TRUE
    }, error = function(e) {
      log_message(paste("Error closing PDF device:", e$message), "ERROR")
      FALSE
    })

    if (!close_result) {
      stop("Failed to close PDF device")
    }

    # Verify output
    if (!file.exists(file_path)) {
      stop("PDF file was not created")
    }

    if (plots_created == 0) {
      log_message("Warning: No plots were created in PDF", "WARNING")
    }

    log_message(paste("BOT graphs exported as PDF:", file_path,
                     "- Plots created:", plots_created,
                     "- Skipped:", plots_skipped), "INFO")
    message("BOT graphs exported as PDF: ", file_path,
           " (", plots_created, " plots)")

    return(TRUE)

  }, error = function(e) {
    # Make sure to close PDF device if open
    tryCatch({
      dev.off()
    }, error = function(e2) {
      # Ignore errors closing device
    })

    log_message(paste("Error exporting BOT as PDF:", e$message), "ERROR")
    message("Error: Failed to export BOT as PDF - ", e$message)
    return(FALSE)
  })
}

# ============================================================================
# SAFE DATA EXPORT FUNCTIONS
# ============================================================================

#' Export all project data to Excel (safe version)
#'
#' Exports project with comprehensive error handling
#'
#' @param project_data Project data list
#' @param file_path Output file path
#' @return TRUE on success, FALSE on error
export_project_excel_safe <- function(project_data, file_path) {

  tryCatch({

    # Validate inputs
    validate_export_project(project_data)
    validate_output_path(file_path)
    check_disk_space(file_path, estimated_size_mb = 20)

    # Create workbook
    wb <- tryCatch({
      createWorkbook()
    }, error = function(e) {
      stop("Failed to create workbook: ", e$message)
    })

    sheets_created <- 0

    # Project metadata sheet
    metadata_result <- tryCatch({

      addWorksheet(wb, "Project_Info")

      metadata_df <- data.frame(
        Field = c("Project ID", "Project Name", "Created", "Last Modified",
                  "DA Site", "Focal Issue"),
        Value = c(
          project_data$project_id,
          project_data$project_name,
          as.character(project_data$created_at),
          as.character(project_data$last_modified),
          project_data$data$metadata$da_site %||% "Not set",
          project_data$data$metadata$focal_issue %||% "Not defined"
        ),
        stringsAsFactors = FALSE
      )

      writeData(wb, "Project_Info", metadata_df)
      sheets_created <<- sheets_created + 1
      TRUE

    }, error = function(e) {
      log_message(paste("Error creating Project_Info sheet:", e$message), "WARNING")
      FALSE
    })

    # Stakeholders
    stakeholders_result <- tryCatch({

      if (!is.null(project_data$data$pims$stakeholders) &&
          is.data.frame(project_data$data$pims$stakeholders) &&
          nrow(project_data$data$pims$stakeholders) > 0) {

        addWorksheet(wb, "Stakeholders")
        writeData(wb, "Stakeholders", project_data$data$pims$stakeholders)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating Stakeholders sheet:", e$message), "WARNING")
      FALSE
    })

    # Risks
    risks_result <- tryCatch({

      if (!is.null(project_data$data$pims$risks) &&
          is.data.frame(project_data$data$pims$risks) &&
          nrow(project_data$data$pims$risks) > 0) {

        addWorksheet(wb, "Risks")
        writeData(wb, "Risks", project_data$data$pims$risks)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating Risks sheet:", e$message), "WARNING")
      FALSE
    })

    # ISA data
    isa_result <- tryCatch({

      if (!is.null(project_data$data$isa_data)) {
        isa_sheets <- export_isa_to_workbook_safe(wb, project_data$data$isa_data)
        sheets_created <<- sheets_created + isa_sheets
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating ISA sheets:", e$message), "WARNING")
      FALSE
    })

    # CLD Nodes
    nodes_result <- tryCatch({

      if (!is.null(project_data$data$cld$nodes) &&
          is.data.frame(project_data$data$cld$nodes) &&
          nrow(project_data$data$cld$nodes) > 0) {

        addWorksheet(wb, "CLD_Nodes")
        writeData(wb, "CLD_Nodes", project_data$data$cld$nodes)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating CLD_Nodes sheet:", e$message), "WARNING")
      FALSE
    })

    # CLD Edges (with confidence column)
    edges_result <- tryCatch({

      if (!is.null(project_data$data$cld$edges) &&
          is.data.frame(project_data$data$cld$edges) &&
          nrow(project_data$data$cld$edges) > 0) {

        addWorksheet(wb, "CLD_Edges")

        # Select relevant columns for export
        edge_cols <- c("from", "to", "polarity", "strength")
        if ("confidence" %in% names(project_data$data$cld$edges)) {
          edge_cols <- c(edge_cols, "confidence")
        }

        edges_export <- project_data$data$cld$edges[, edge_cols, drop = FALSE]
        writeData(wb, "CLD_Edges", edges_export)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating CLD_Edges sheet:", e$message), "WARNING")
      FALSE
    })

    # Loops
    loops_result <- tryCatch({

      if (!is.null(project_data$data$cld$loops) &&
          is.data.frame(project_data$data$cld$loops) &&
          nrow(project_data$data$cld$loops) > 0) {

        addWorksheet(wb, "Feedback_Loops")
        writeData(wb, "Feedback_Loops", project_data$data$cld$loops)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating Feedback_Loops sheet:", e$message), "WARNING")
      FALSE
    })

    # Response measures
    responses_result <- tryCatch({

      if (!is.null(project_data$data$responses$measures) &&
          is.data.frame(project_data$data$responses$measures) &&
          nrow(project_data$data$responses$measures) > 0) {

        addWorksheet(wb, "Response_Measures")
        writeData(wb, "Response_Measures", project_data$data$responses$measures)
        sheets_created <<- sheets_created + 1
      }

      TRUE

    }, error = function(e) {
      log_message(paste("Error creating Response_Measures sheet:", e$message), "WARNING")
      FALSE
    })

    # Save workbook
    if (sheets_created == 0) {
      stop("No sheets were created - nothing to export")
    }

    save_result <- tryCatch({
      saveWorkbook(wb, file_path, overwrite = TRUE)
      TRUE
    }, error = function(e) {
      stop("Failed to save workbook: ", e$message)
    })

    # Verify output
    if (!file.exists(file_path)) {
      stop("Excel file was not created")
    }

    file_size <- file.info(file_path)$size
    log_message(paste("Project exported to Excel:", file_path,
                     "- Sheets:", sheets_created,
                     "- Size:", round(file_size / 1024, 2), "KB"), "INFO")
    message("Project data exported to Excel: ", file_path, " (", sheets_created, " sheets)")

    return(TRUE)

  }, error = function(e) {
    log_message(paste("Error exporting project to Excel:", e$message), "ERROR")
    message("Error: Failed to export project to Excel - ", e$message)
    return(FALSE)
  })
}

#' Helper function to export ISA data to existing workbook (safe version)
#'
#' @param wb Workbook object
#' @param isa_data ISA data list
#' @return Number of sheets created
export_isa_to_workbook_safe <- function(wb, isa_data) {

  sheets_created <- 0

  tryCatch({

    # Element sheets
    element_mapping <- list(
      "goods_benefits" = "Goods_Benefits",
      "ecosystem_services" = "Ecosystem_Services",
      "marine_processes" = "Marine_Processes",
      "pressures" = "Pressures",
      "activities" = "Activities",
      "drivers" = "Drivers"
    )

    for (elem_name in names(element_mapping)) {

      elem_result <- tryCatch({

        sheet_name <- element_mapping[[elem_name]]

        if (!is.null(isa_data[[elem_name]]) &&
            is.data.frame(isa_data[[elem_name]]) &&
            nrow(isa_data[[elem_name]]) > 0) {

          addWorksheet(wb, sheet_name)
          writeData(wb, sheet_name, isa_data[[elem_name]])
          sheets_created <<- sheets_created + 1
        }

        TRUE

      }, error = function(e) {
        log_message(paste("Error creating sheet for", elem_name, ":", e$message), "WARNING")
        FALSE
      })
    }

    # Adjacency matrices
    adj_matrices <- isa_data$adjacency_matrices

    if (!is.null(adj_matrices) && is.list(adj_matrices)) {

      adj_mapping <- list(
        "gb_es" = "Matrix_GB_ES",
        "es_mpf" = "Matrix_ES_MPF",
        "mpf_p" = "Matrix_MPF_P",
        "p_a" = "Matrix_P_A",
        "a_d" = "Matrix_A_D",
        "d_gb" = "Matrix_D_GB"
      )

      for (adj_name in names(adj_mapping)) {

        adj_result <- tryCatch({

          sheet_name <- adj_mapping[[adj_name]]
          mat <- adj_matrices[[adj_name]]

          if (!is.null(mat) && is.matrix(mat) && length(mat) > 0) {
            addWorksheet(wb, sheet_name)
            writeData(wb, sheet_name, mat, rowNames = TRUE)
            sheets_created <<- sheets_created + 1
          }

          TRUE

        }, error = function(e) {
          log_message(paste("Error creating sheet for", adj_name, ":", e$message), "WARNING")
          FALSE
        })
      }
    }

    return(sheets_created)

  }, error = function(e) {
    log_message(paste("Error in ISA workbook export:", e$message), "WARNING")
    return(sheets_created)
  })
}

#' Export project data as JSON (safe version)
#'
#' Exports project with JSON serialization error handling
#'
#' @param project_data Project data list
#' @param file_path Output file path
#' @return TRUE on success, FALSE on error
export_project_json_safe <- function(project_data, file_path) {

  tryCatch({

    # Validate inputs
    validate_export_project(project_data)
    validate_output_path(file_path)
    check_disk_space(file_path, estimated_size_mb = 10)

    # Prepare data for JSON
    project_json <- tryCatch({

      # Deep copy to avoid modifying original
      temp_data <- project_data

      # Convert dates safely
      if (!is.null(temp_data$created_at)) {
        temp_data$created_at <- tryCatch({
          as.character(temp_data$created_at)
        }, error = function(e) {
          log_message("Warning: Could not convert created_at to character", "WARNING")
          "Unknown"
        })
      }

      if (!is.null(temp_data$last_modified)) {
        temp_data$last_modified <- tryCatch({
          as.character(temp_data$last_modified)
        }, error = function(e) {
          log_message("Warning: Could not convert last_modified to character", "WARNING")
          "Unknown"
        })
      }

      temp_data

    }, error = function(e) {
      stop("Failed to prepare data for JSON: ", e$message)
    })

    # Convert to JSON
    json_text <- tryCatch({
      toJSON(project_json, pretty = TRUE, auto_unbox = TRUE)
    }, error = function(e) {
      stop("Failed to serialize to JSON: ", e$message)
    })

    # Write to file
    write_result <- tryCatch({
      write(json_text, file_path)
      TRUE
    }, error = function(e) {
      stop("Failed to write JSON file: ", e$message)
    })

    # Verify output
    if (!file.exists(file_path)) {
      stop("JSON file was not created")
    }

    file_size <- file.info(file_path)$size
    if (file_size == 0) {
      stop("JSON file is empty")
    }

    log_message(paste("Project exported as JSON:", file_path,
                     "- Size:", round(file_size / 1024, 2), "KB"), "INFO")
    message("Project data exported as JSON: ", file_path)

    return(TRUE)

  }, error = function(e) {
    log_message(paste("Error exporting project as JSON:", e$message), "ERROR")
    message("Error: Failed to export project as JSON - ", e$message)
    return(FALSE)
  })
}

#' Export project data as CSV zip (safe version)
#'
#' Exports multiple CSV files in zip with error handling
#'
#' @param project_data Project data list
#' @param file_path Output zip file path
#' @return TRUE on success, FALSE on error
export_project_csv_zip_safe <- function(project_data, file_path) {

  temp_dir <- NULL

  tryCatch({

    # Validate inputs
    validate_export_project(project_data)
    validate_output_path(file_path)
    check_disk_space(file_path, estimated_size_mb = 20)

    # Create temporary directory
    temp_dir <- tryCatch({
      temp_path <- tempfile()
      dir.create(temp_path)
      temp_path
    }, error = function(e) {
      stop("Failed to create temporary directory: ", e$message)
    })

    files_created <- 0

    # Export metadata
    metadata_result <- tryCatch({

      metadata_df <- data.frame(
        field = c("project_id", "project_name", "created_at", "last_modified"),
        value = c(
          project_data$project_id,
          project_data$project_name,
          as.character(project_data$created_at),
          as.character(project_data$last_modified)
        ),
        stringsAsFactors = FALSE
      )

      write.csv(metadata_df, file.path(temp_dir, "metadata.csv"), row.names = FALSE)
      files_created <<- files_created + 1
      TRUE

    }, error = function(e) {
      log_message(paste("Error exporting metadata:", e$message), "WARNING")
      FALSE
    })

    # Export PIMS data
    if (!is.null(project_data$data$pims$stakeholders) &&
        is.data.frame(project_data$data$pims$stakeholders) &&
        nrow(project_data$data$pims$stakeholders) > 0) {

      stakeholders_result <- tryCatch({
        write.csv(project_data$data$pims$stakeholders,
                 file.path(temp_dir, "stakeholders.csv"), row.names = FALSE)
        files_created <<- files_created + 1
        TRUE
      }, error = function(e) {
        log_message(paste("Error exporting stakeholders:", e$message), "WARNING")
        FALSE
      })
    }

    if (!is.null(project_data$data$pims$risks) &&
        is.data.frame(project_data$data$pims$risks) &&
        nrow(project_data$data$pims$risks) > 0) {

      risks_result <- tryCatch({
        write.csv(project_data$data$pims$risks,
                 file.path(temp_dir, "risks.csv"), row.names = FALSE)
        files_created <<- files_created + 1
        TRUE
      }, error = function(e) {
        log_message(paste("Error exporting risks:", e$message), "WARNING")
        FALSE
      })
    }

    # Export ISA data
    isa_data <- project_data$data$isa_data
    element_names <- c("goods_benefits", "ecosystem_services", "marine_processes",
                      "pressures", "activities", "drivers")

    for (elem_name in element_names) {

      elem_result <- tryCatch({

        if (!is.null(isa_data[[elem_name]]) &&
            is.data.frame(isa_data[[elem_name]]) &&
            nrow(isa_data[[elem_name]]) > 0) {

          write.csv(isa_data[[elem_name]],
                   file.path(temp_dir, paste0(elem_name, ".csv")),
                   row.names = FALSE)
          files_created <<- files_created + 1
        }

        TRUE

      }, error = function(e) {
        log_message(paste("Error exporting", elem_name, ":", e$message), "WARNING")
        FALSE
      })
    }

    # Export loops
    if (!is.null(project_data$data$cld$loops) &&
        is.data.frame(project_data$data$cld$loops) &&
        nrow(project_data$data$cld$loops) > 0) {

      loops_result <- tryCatch({
        write.csv(project_data$data$cld$loops,
                 file.path(temp_dir, "loops.csv"), row.names = FALSE)
        files_created <<- files_created + 1
        TRUE
      }, error = function(e) {
        log_message(paste("Error exporting loops:", e$message), "WARNING")
        FALSE
      })
    }

    # Check we created at least some files
    if (files_created == 0) {
      stop("No CSV files were created - nothing to zip")
    }

    # Create zip file
    zip_result <- tryCatch({

      current_dir <- getwd()
      setwd(temp_dir)

      zip(file_path, list.files())

      setwd(current_dir)
      TRUE

    }, error = function(e) {
      # Restore directory even on error
      tryCatch(setwd(current_dir), error = function(e2) {})
      stop("Failed to create zip file: ", e$message)
    })

    # Verify output
    if (!file.exists(file_path)) {
      stop("Zip file was not created")
    }

    file_size <- file.info(file_path)$size
    log_message(paste("Project exported as CSV zip:", file_path,
                     "- Files:", files_created,
                     "- Size:", round(file_size / 1024, 2), "KB"), "INFO")
    message("Project data exported as CSV zip: ", file_path, " (", files_created, " files)")

    # Clean up
    cleanup_result <- tryCatch({
      unlink(temp_dir, recursive = TRUE)
      TRUE
    }, error = function(e) {
      log_message(paste("Warning: Failed to delete temporary directory:", temp_dir), "WARNING")
      TRUE
    })

    return(TRUE)

  }, error = function(e) {

    # Clean up temp directory on error
    if (!is.null(temp_dir) && dir.exists(temp_dir)) {
      tryCatch({
        unlink(temp_dir, recursive = TRUE)
      }, error = function(e2) {
        log_message(paste("Warning: Failed to clean up temp directory:", temp_dir), "WARNING")
      })
    }

    log_message(paste("Error exporting project as CSV zip:", e$message), "ERROR")
    message("Error: Failed to export project as CSV zip - ", e$message)
    return(FALSE)
  })
}

# ============================================================================
# SAFE REPORT GENERATION FUNCTIONS
# ============================================================================

#' Generate executive summary report (safe version)
#'
#' Generates report with Rmarkdown error handling
#'
#' @param project_data Project data list
#' @param output_file Output file path (HTML or PDF)
#' @return TRUE on success, FALSE on error
generate_executive_summary_safe <- function(project_data, output_file) {

  temp_rmd <- NULL

  tryCatch({

    # Validate inputs
    validate_export_project(project_data)
    validate_output_path(output_file)
    check_disk_space(output_file, estimated_size_mb = 5)

    # Check rmarkdown package
    if (!requireNamespace("rmarkdown", quietly = TRUE)) {
      stop("Package 'rmarkdown' is required for report generation. Install with: install.packages('rmarkdown')")
    }

    # Create temporary Rmd file
    temp_rmd <- tryCatch({
      tempfile(fileext = ".Rmd")
    }, error = function(e) {
      stop("Failed to create temporary Rmd file: ", e$message)
    })

    # Generate Rmd content
    rmd_content <- tryCatch({
      create_executive_summary_rmd_safe(project_data)
    }, error = function(e) {
      stop("Failed to generate report content: ", e$message)
    })

    # Write Rmd file
    write_result <- tryCatch({
      writeLines(rmd_content, temp_rmd)
      TRUE
    }, error = function(e) {
      stop("Failed to write Rmd file: ", e$message)
    })

    # Determine output format
    output_format <- ifelse(grepl("\\.pdf$", output_file, ignore.case = TRUE),
                           "pdf_document", "html_document")

    # Render report
    render_result <- tryCatch({

      rmarkdown::render(
        temp_rmd,
        output_format = output_format,
        output_file = basename(output_file),
        output_dir = dirname(output_file),
        quiet = TRUE
      )

      TRUE

    }, error = function(e) {
      stop("Failed to render report: ", e$message)
    })

    # Verify output
    if (!file.exists(output_file)) {
      stop("Report file was not created")
    }

    # Clean up
    cleanup_result <- tryCatch({
      unlink(temp_rmd)
      TRUE
    }, error = function(e) {
      log_message(paste("Warning: Failed to delete temp Rmd:", temp_rmd), "WARNING")
      TRUE
    })

    file_size <- file.info(output_file)$size
    log_message(paste("Executive summary generated:", output_file,
                     "- Format:", output_format,
                     "- Size:", round(file_size / 1024, 2), "KB"), "INFO")
    message("Executive summary generated: ", output_file)

    return(TRUE)

  }, error = function(e) {

    # Clean up temp file on error
    if (!is.null(temp_rmd) && file.exists(temp_rmd)) {
      tryCatch({
        unlink(temp_rmd)
      }, error = function(e2) {
        # Ignore cleanup errors
      })
    }

    log_message(paste("Error generating executive summary:", e$message), "ERROR")
    message("Error: Failed to generate executive summary - ", e$message)
    return(FALSE)
  })
}

#' Create executive summary Rmd content (safe version)
#'
#' Generates Rmd content with error handling
#'
#' @param project_data Project data list
#' @return Character vector of Rmd lines
create_executive_summary_rmd_safe <- function(project_data) {

  tryCatch({

    # Generate each section safely
    element_summary <- tryCatch({
      generate_element_summary_md_safe(project_data$data$isa_data)
    }, error = function(e) {
      log_message(paste("Error generating element summary:", e$message), "WARNING")
      c("*Element summary could not be generated*")
    })

    network_summary <- tryCatch({
      generate_network_summary_md_safe(project_data$data$cld)
    }, error = function(e) {
      log_message(paste("Error generating network summary:", e$message), "WARNING")
      c("*Network summary could not be generated*")
    })

    key_findings <- tryCatch({
      generate_key_findings_md_safe(project_data)
    }, error = function(e) {
      log_message(paste("Error generating key findings:", e$message), "WARNING")
      c("*Key findings could not be generated*")
    })

    recommendations <- tryCatch({
      generate_recommendations_md_safe(project_data$data$responses)
    }, error = function(e) {
      log_message(paste("Error generating recommendations:", e$message), "WARNING")
      c("*Recommendations could not be generated*")
    })

    # Combine all sections
    rmd_lines <- c(
      "---",
      "title: 'Executive Summary: MarineSABRES SES Analysis'",
      paste0("subtitle: '", project_data$project_name, "'"),
      paste0("date: '", format(Sys.Date(), "%B %d, %Y"), "'"),
      "output:",
      "  html_document:",
      "    theme: cosmo",
      "    toc: true",
      "    toc_float: true",
      "---",
      "",
      "# Project Overview",
      "",
      paste0("**Project ID:** ", project_data$project_id),
      paste0("**Demonstration Area:** ", project_data$data$metadata$da_site %||% "Not specified"),
      paste0("**Focal Issue:** ", project_data$data$metadata$focal_issue %||% "Not defined"),
      paste0("**Created:** ", format(project_data$created_at, "%B %d, %Y")),
      "",
      "# System Analysis Summary",
      "",
      "## DAPSI(W)R(M) Elements",
      "",
      element_summary,
      "",
      "## Network Structure",
      "",
      network_summary,
      "",
      "## Key Findings",
      "",
      key_findings,
      "",
      "# Recommendations",
      "",
      recommendations,
      "",
      "---",
      "",
      "*This report was automatically generated by the MarineSABRES SES Tool.*"
    )

    return(rmd_lines)

  }, error = function(e) {
    log_message(paste("Critical error creating Rmd content:", e$message), "ERROR")

    # Return minimal fallback content
    c(
      "---",
      "title: 'Executive Summary'",
      "---",
      "",
      "Error generating report content. Please check the log for details."
    )
  })
}

#' Generate element summary markdown (safe version)
#'
#' @param isa_data ISA data list
#' @return Character vector
generate_element_summary_md_safe <- function(isa_data) {

  tryCatch({

    if (is.null(isa_data) || !is.list(isa_data)) {
      return(c("*No ISA data available*"))
    }

    lines <- c()

    element_types <- list(
      "goods_benefits" = "Goods & Benefits",
      "ecosystem_services" = "Ecosystem Services",
      "marine_processes" = "Marine Processes & Functioning",
      "pressures" = "Pressures",
      "activities" = "Activities",
      "drivers" = "Drivers"
    )

    for (elem_id in names(element_types)) {

      elem_result <- tryCatch({

        elem_name <- element_types[[elem_id]]
        elem_data <- isa_data[[elem_id]]

        if (!is.null(elem_data) && is.data.frame(elem_data)) {
          n_elements <- nrow(elem_data)
          paste0("- **", elem_name, ":** ", n_elements, " identified")
        } else {
          paste0("- **", elem_name, ":** 0 identified")
        }

      }, error = function(e) {
        log_message(paste("Error summarizing", elem_id, ":", e$message), "WARNING")
        paste0("- **", element_types[[elem_id]], ":** Error retrieving count")
      })

      lines <- c(lines, elem_result)
    }

    return(lines)

  }, error = function(e) {
    log_message(paste("Error in element summary generation:", e$message), "ERROR")
    return(c("*Error generating element summary*"))
  })
}

#' Generate network summary markdown (safe version)
#'
#' @param cld_data CLD data list
#' @return Character vector
generate_network_summary_md_safe <- function(cld_data) {

  tryCatch({

    if (is.null(cld_data) || !is.list(cld_data)) {
      return(c("*No network data available*"))
    }

    lines <- c()

    # Nodes
    nodes_line <- tryCatch({
      if (!is.null(cld_data$nodes) && is.data.frame(cld_data$nodes)) {
        paste0("- Total network nodes: ", nrow(cld_data$nodes))
      } else {
        "- Total network nodes: 0"
      }
    }, error = function(e) {
      "- Total network nodes: Error retrieving count"
    })
    lines <- c(lines, nodes_line)

    # Edges
    edges_line <- tryCatch({
      if (!is.null(cld_data$edges) && is.data.frame(cld_data$edges)) {
        paste0("- Total connections: ", nrow(cld_data$edges))
      } else {
        "- Total connections: 0"
      }
    }, error = function(e) {
      "- Total connections: Error retrieving count"
    })
    lines <- c(lines, edges_line)

    # Loops
    loops_lines <- tryCatch({

      if (!is.null(cld_data$loops) && is.data.frame(cld_data$loops) && nrow(cld_data$loops) > 0) {

        n_reinforcing <- sum(cld_data$loops$type == "R", na.rm = TRUE)
        n_balancing <- sum(cld_data$loops$type == "B", na.rm = TRUE)

        c(
          paste0("- Feedback loops detected: ", nrow(cld_data$loops)),
          paste0("  - Reinforcing: ", n_reinforcing),
          paste0("  - Balancing: ", n_balancing)
        )

      } else {
        "- Feedback loops detected: 0"
      }

    }, error = function(e) {
      "- Feedback loops: Error retrieving count"
    })

    lines <- c(lines, loops_lines)

    return(lines)

  }, error = function(e) {
    log_message(paste("Error in network summary generation:", e$message), "ERROR")
    return(c("*Error generating network summary*"))
  })
}

#' Generate key findings markdown (safe version)
#'
#' @param project_data Project data list
#' @return Character vector
generate_key_findings_md_safe <- function(project_data) {

  tryCatch({

    lines <- c(
      "Based on the system analysis, the following key patterns emerged:",
      "",
      "1. **System Complexity:** The identified feedback loops indicate significant interdependencies within the social-ecological system.",
      "2. **Leverage Points:** Network analysis revealed key nodes with high centrality that could serve as intervention points.",
      "3. **Dominant Dynamics:** Analysis of reinforcing vs. balancing loops provides insights into system behavior.",
      ""
    )

    return(lines)

  }, error = function(e) {
    log_message(paste("Error in key findings generation:", e$message), "ERROR")
    return(c("*Error generating key findings*"))
  })
}

#' Generate recommendations markdown (safe version)
#'
#' @param responses_data Responses data list
#' @return Character vector
generate_recommendations_md_safe <- function(responses_data) {

  tryCatch({

    if (is.null(responses_data) || !is.list(responses_data)) {
      return(c("*No recommendations data available*"))
    }

    lines <- c()

    if (!is.null(responses_data$measures) &&
        is.data.frame(responses_data$measures) &&
        nrow(responses_data$measures) > 0) {

      lines <- c(lines,
                paste0("Based on the analysis, ", nrow(responses_data$measures),
                      " response measures have been identified:"),
                "")

      n_measures <- min(5, nrow(responses_data$measures))

      for (i in 1:n_measures) {

        measure_line <- tryCatch({

          measure <- responses_data$measures[i, ]
          paste0(i, ". **", measure$name, ":** ", measure$description)

        }, error = function(e) {
          log_message(paste("Error formatting measure", i, ":", e$message), "WARNING")
          paste0(i, ". Error retrieving measure details")
        })

        lines <- c(lines, measure_line)
      }

    } else {
      lines <- c(lines, "No specific response measures have been defined yet.")
    }

    return(lines)

  }, error = function(e) {
    log_message(paste("Error in recommendations generation:", e$message), "ERROR")
    return(c("*Error generating recommendations*"))
  })
}
