# functions/export_functions.R
# Export and reporting functions
# Note: rmarkdown and htmlwidgets are loaded in global.R

# ============================================================================
# EXPORT FILENAME HELPER
# ============================================================================

#' Generate a standardized export filename with date stamp
#'
#' @param prefix Descriptive prefix (e.g., "Network_Metrics", "MarineSABRES_Data")
#' @param extension File extension including dot (e.g., ".xlsx", ".csv")
#' @return Character string like "Network_Metrics_20260208.xlsx"
generate_export_filename <- function(prefix, extension) {
  paste0(prefix, "_", format(Sys.Date(), EXPORT_DATE_FORMAT), extension)
}

# ============================================================================
# VISUALIZATION EXPORT FUNCTIONS
# ============================================================================

#' Export CLD as HTML
#' 
#' @param visnet visNetwork object
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_cld_html <- function(visnet, file_path) {
  
  htmlwidgets::saveWidget(
    visnet %>% visInteraction(navigationButtons = TRUE),
    file_path,
    selfcontained = TRUE
  )
  
  debug_log(paste("CLD exported as HTML:", file_path), "EXPORT")
}

# ============================================================================
# DATA EXPORT FUNCTIONS
# ============================================================================

#' Export all project data to Excel
#' 
#' @param project_data Project data list
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_project_excel <- function(project_data, file_path) {

  if (is.null(project_data)) {
    stop("No project data provided for export")
  }

  tryCatch({
    wb <- createWorkbook()

    # Project metadata sheet
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
    )
  )
  writeData(wb, "Project_Info", metadata_df)
  
  # Stakeholders
  if (!is.null(project_data$data$pims$stakeholders) && 
      nrow(project_data$data$pims$stakeholders) > 0) {
    addWorksheet(wb, "Stakeholders")
    writeData(wb, "Stakeholders", project_data$data$pims$stakeholders)
  }
  
  # Risks
  if (!is.null(project_data$data$pims$risks) && 
      nrow(project_data$data$pims$risks) > 0) {
    addWorksheet(wb, "Risks")
    writeData(wb, "Risks", project_data$data$pims$risks)
  }
  
  # ISA data
  if (!is.null(project_data$data$isa_data)) {
    export_isa_to_workbook(wb, project_data$data$isa_data)
  }
  
  # CLD Nodes
  if (!is.null(project_data$data$cld$nodes) &&
      is.data.frame(project_data$data$cld$nodes) &&
      nrow(project_data$data$cld$nodes) > 0) {
    addWorksheet(wb, "CLD_Nodes")
    writeData(wb, "CLD_Nodes", project_data$data$cld$nodes)
  }

  # CLD Edges (with confidence column)
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
  }

  # Loops
  if (!is.null(project_data$data$cld$loops) &&
      nrow(project_data$data$cld$loops) > 0) {
    addWorksheet(wb, "Feedback_Loops")
    writeData(wb, "Feedback_Loops", project_data$data$cld$loops)
  }

    saveWorkbook(wb, file_path, overwrite = TRUE)

    debug_log(paste("Project data exported to Excel:", file_path), "EXPORT")
  }, error = function(e) {
    stop(paste("Failed to export Excel file:", e$message))
  })
}

#' Helper function to export ISA data to existing workbook
#' 
#' @param wb Workbook object
#' @param isa_data ISA data list
#' @return NULL (side effect: modifies workbook)
export_isa_to_workbook <- function(wb, isa_data) {
  
  # Element sheets
  element_mapping <- list(
    "goods_benefits" = "Goods_Benefits",
    "ecosystem_services" = "Ecosystem_Services",
    "marine_processes" = "Marine_Processes",
    "pressures" = "Pressures",
    "activities" = "Activities",
    "drivers" = "Drivers",
    "responses" = "Responses"
  )
  
  for (elem_name in names(element_mapping)) {
    sheet_name <- element_mapping[[elem_name]]
    
    if (!is.null(isa_data[[elem_name]]) && nrow(isa_data[[elem_name]]) > 0) {
      addWorksheet(wb, sheet_name)
      writeData(wb, sheet_name, isa_data[[elem_name]])
    }
  }
  
  # Adjacency matrices
  adj_matrices <- isa_data$adjacency_matrices
  
  if (!is.null(adj_matrices)) {
    adj_mapping <- list(
      "d_a" = "Matrix_D_A",
      "a_p" = "Matrix_A_P",
      "p_mpf" = "Matrix_P_MPF",
      "mpf_es" = "Matrix_MPF_ES",
      "es_gb" = "Matrix_ES_GB",
      "gb_d" = "Matrix_GB_D",
      "gb_r" = "Matrix_GB_R",
      "r_d" = "Matrix_R_D",
      "r_a" = "Matrix_R_A",
      "r_p" = "Matrix_R_P"
    )
    
    for (adj_name in names(adj_mapping)) {
      sheet_name <- adj_mapping[[adj_name]]
      mat <- adj_matrices[[adj_name]]
      
      if (!is.null(mat) && length(mat) > 0) {
        addWorksheet(wb, sheet_name)
        writeData(wb, sheet_name, mat, rowNames = TRUE)
      }
    }
  }
}

#' Export project data as JSON
#' 
#' @param project_data Project data list
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_project_json <- function(project_data, file_path) {
  
  # Convert dates to character for JSON compatibility
  project_json <- project_data
  project_json$created_at <- as.character(project_data$created_at)
  project_json$last_modified <- as.character(project_data$last_modified)
  
  # Write JSON
  json_text <- toJSON(project_json, pretty = TRUE, auto_unbox = TRUE)
  write(json_text, file_path)
  
  debug_log(paste("Project data exported as JSON:", file_path), "EXPORT")
}

#' Export project data as CSV (multiple files in zip)
#' 
#' @param project_data Project data list
#' @param file_path Output zip file path
#' @return NULL (side effect: saves file)
export_project_csv_zip <- function(project_data, file_path) {
  
  # Create temporary directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  
  # Export metadata
  metadata_df <- data.frame(
    field = c("project_id", "project_name", "created_at", "last_modified"),
    value = c(
      project_data$project_id,
      project_data$project_name,
      as.character(project_data$created_at),
      as.character(project_data$last_modified)
    )
  )
  write.csv(metadata_df, file.path(temp_dir, "metadata.csv"), row.names = FALSE)
  
  # Export PIMS data
  if (!is.null(project_data$data$pims$stakeholders)) {
    write.csv(project_data$data$pims$stakeholders, 
             file.path(temp_dir, "stakeholders.csv"), row.names = FALSE)
  }
  
  if (!is.null(project_data$data$pims$risks)) {
    write.csv(project_data$data$pims$risks, 
             file.path(temp_dir, "risks.csv"), row.names = FALSE)
  }
  
  # Export ISA data (use safe_get_nested for defensive access)
  isa_data <- safe_get_nested(project_data, "data", "isa_data", default = list())
  element_names <- c("goods_benefits", "ecosystem_services", "marine_processes",
                    "pressures", "activities", "drivers")

  for (elem_name in element_names) {
    elem_data <- isa_data[[elem_name]]
    if (!is.null(elem_data) && is.data.frame(elem_data) && nrow(elem_data) > 0) {
      write.csv(elem_data,
               file.path(temp_dir, paste0(elem_name, ".csv")),
               row.names = FALSE)
    }
  }
  
  # Export loops
  if (!is.null(project_data$data$cld$loops)) {
    write.csv(project_data$data$cld$loops, 
             file.path(temp_dir, "loops.csv"), row.names = FALSE)
  }
  
  # Create zip file (use full paths to avoid setwd which is unsafe on error)
  files_to_zip <- list.files(temp_dir, full.names = TRUE)
  zip(file_path, files = files_to_zip, flags = "-j")  # -j strips directory paths
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
  
  debug_log(paste("Project data exported as CSV zip:", file_path), "EXPORT")
}

# ============================================================================
# REPORT GENERATION FUNCTIONS
# ============================================================================

#' Generate executive summary report
#' 
#' @param project_data Project data list
#' @param output_file Output file path (HTML or PDF)
#' @return NULL (side effect: generates report)
generate_executive_summary <- function(project_data, output_file) {
  
  # Create temporary Rmd file
  temp_rmd <- tempfile(fileext = ".Rmd")
  
  # Write Rmd content
  rmd_content <- create_executive_summary_rmd(project_data)
  writeLines(rmd_content, temp_rmd)
  
  # Render
  output_format <- ifelse(grepl("\\.pdf$", output_file), "pdf_document", "html_document")
  
  rmarkdown::render(
    temp_rmd,
    output_format = output_format,
    output_file = output_file,
    quiet = TRUE
  )
  
  # Clean up
  unlink(temp_rmd)
  
  debug_log(paste("Executive summary generated:", output_file), "EXPORT")
}

#' Create executive summary Rmd content
#'
#' @param project_data Project data list
#' @return Character vector of Rmd lines
create_executive_summary_rmd <- function(project_data) {

  # Use safe_get_nested for defensive data access
  metadata <- safe_get_nested(project_data, "data", "metadata", default = list())
  isa_data <- safe_get_nested(project_data, "data", "isa_data", default = list())
  cld_data <- safe_get_nested(project_data, "data", "cld", default = list())
  responses <- safe_get_nested(project_data, "data", "responses", default = list())

  c(
    "---",
    "title: 'Executive Summary: MarineSABRES SES Analysis'",
    paste0("subtitle: '", project_data$project_name %||% "Untitled", "'"),
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
    paste0("**Project ID:** ", project_data$project_id %||% "N/A"),
    paste0("**Demonstration Area:** ", metadata$da_site %||% "Not specified"),
    paste0("**Focal Issue:** ", metadata$focal_issue %||% "Not defined"),
    paste0("**Created:** ", format(project_data$created_at %||% Sys.Date(), "%B %d, %Y")),
    "",
    "# System Analysis Summary",
    "",
    "## DAPSI(W)R(M) Elements",
    "",
    generate_element_summary_md(isa_data),
    "",
    "## Network Structure",
    "",
    generate_network_summary_md(cld_data),
    "",
    "## Key Findings",
    "",
    generate_key_findings_md(project_data),
    "",
    "# Recommendations",
    "",
    generate_recommendations_md(responses),
    "",
    "---",
    "",
    "*This report was automatically generated by the MarineSABRES SES Tool.*"
  )
}

#' Generate element summary markdown
#' 
#' @param isa_data ISA data list
#' @return Character vector
generate_element_summary_md <- function(isa_data) {
  
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
    elem_name <- element_types[[elem_id]]
    elem_data <- isa_data[[elem_id]]
    
    if (!is.null(elem_data)) {
      n_elements <- nrow(elem_data)
      lines <- c(lines, paste0("- **", elem_name, ":** ", n_elements, " identified"))
    }
  }
  
  return(lines)
}

#' Generate network summary markdown
#' 
#' @param cld_data CLD data list
#' @return Character vector
generate_network_summary_md <- function(cld_data) {
  
  lines <- c()
  
  if (!is.null(cld_data$nodes)) {
    lines <- c(lines, paste0("- Total network nodes: ", nrow(cld_data$nodes)))
  }
  
  if (!is.null(cld_data$edges)) {
    lines <- c(lines, paste0("- Total connections: ", nrow(cld_data$edges)))
  }
  
  if (!is.null(cld_data$loops)) {
    n_reinforcing <- sum(cld_data$loops$type == "R", na.rm = TRUE)
    n_balancing <- sum(cld_data$loops$type == "B", na.rm = TRUE)
    
    lines <- c(lines, 
              paste0("- Feedback loops detected: ", nrow(cld_data$loops)),
              paste0("  - Reinforcing: ", n_reinforcing),
              paste0("  - Balancing: ", n_balancing))
  }
  
  return(lines)
}

#' Generate key findings markdown
#' 
#' @param project_data Project data list
#' @return Character vector
generate_key_findings_md <- function(project_data) {
  
  lines <- c(
    "Based on the system analysis, the following key patterns emerged:",
    "",
    "1. **System Complexity:** The identified feedback loops indicate significant interdependencies within the social-ecological system.",
    "2. **Leverage Points:** Network analysis revealed key nodes with high centrality that could serve as intervention points.",
    "3. **Dominant Dynamics:** [Analysis of reinforcing vs. balancing loops would be inserted here]",
    ""
  )
  
  return(lines)
}

#' Generate recommendations markdown
#'
#' @param responses_data Responses data (dataframe)
#' @return Character vector
generate_recommendations_md <- function(responses_data) {

  lines <- c()

  # Responses are now consolidated (responses and measures merged)
  responses <- if (is.data.frame(responses_data)) responses_data else NULL

  if (!is.null(responses) && nrow(responses) > 0) {
    lines <- c(lines,
              paste0("Based on the analysis, ", nrow(responses),
                    " response measures have been identified:"),
              "")

    for (i in 1:min(5, nrow(responses))) {
      response <- responses[i, ]
      lines <- c(lines, paste0(i, ". **", response$name, ":** ", response$description))
    }
  } else {
    lines <- c(lines, "No specific response measures have been defined yet.")
  }

  return(lines)
}

# ============================================================================
# SAFE WRAPPER FUNCTIONS
# (Consolidated from export_functions_enhanced.R)
# These add input validation and error handling around the core export functions.
# ============================================================================

#' Validate output file path
validate_output_path <- function(path) {
  if (is.null(path)) stop("File path is NULL")
  if (!is.character(path) || nchar(trimws(path)) == 0) stop("File path cannot be empty")
  dir <- dirname(path)
  if (!dir.exists(dir)) stop("Directory does not exist")
  TRUE
}

#' Validate project data for export
validate_export_project <- function(project) {
  if (is.null(project)) stop("Project data is NULL")
  req <- c("project_id", "project_name", "data")
  if (!all(req %in% names(project))) stop("missing required fields")
  TRUE
}

export_project_excel_safe <- function(project, file_path) {
  tryCatch({
    if (is.null(project)) return(FALSE)
    validate_output_path(file_path)
    validate_export_project(project)
    if (exists("export_project_excel")) {
      export_project_excel(project, file_path)
    } else {
      wb <- openxlsx::createWorkbook()
      openxlsx::addWorksheet(wb, "Project_Info")
      openxlsx::writeData(wb, "Project_Info", data.frame(Field = "Project ID", Value = project$project_id))
      openxlsx::saveWorkbook(wb, file_path, overwrite = TRUE)
    }
    TRUE
  }, error = function(e) {
    warning("Export failed: ", e$message)
    FALSE
  })
}

export_project_json_safe <- function(project, file_path) {
  tryCatch({
    if (is.null(project)) return(FALSE)
    validate_output_path(file_path)
    validate_export_project(project)
    if (exists("export_project_json")) {
      export_project_json(project, file_path)
      return(TRUE)
    }
    return(FALSE)
  }, error = function(e) {
    warning("export_project_json_safe failed: ", e$message)
    FALSE
  })
}

export_project_csv_zip_safe <- function(project, file_path) {
  tryCatch({
    if (is.null(project)) return(FALSE)
    validate_output_path(file_path)
    validate_export_project(project)
    if (exists("export_project_csv_zip")) {
      export_project_csv_zip(project, file_path)
      return(TRUE)
    }
    return(FALSE)
  }, error = function(e) {
    warning("export_project_csv_zip_safe failed: ", e$message)
    FALSE
  })
}

generate_executive_summary_safe <- function(project, file_path) {
  tryCatch({
    if (is.null(project)) return(FALSE)
    validate_output_path(file_path)
    validate_export_project(project)
    if (exists("generate_executive_summary")) {
      generate_executive_summary(project, file_path)
      return(TRUE)
    }
    return(FALSE)
  }, error = function(e) {
    warning("generate_executive_summary_safe failed: ", e$message)
    FALSE
  })
}

generate_element_summary_md_safe <- function(isa_data) {
  if (is.null(isa_data)) return("No ISA data available")
  lines <- c("## Element Summary")
  for (name in names(isa_data)) {
    df <- isa_data[[name]]
    count <- if (is.data.frame(df)) nrow(df) else 0
    lines <- c(lines, sprintf("- %s: %d identified", name, count))
  }
  return(lines)
}

generate_network_summary_md_safe <- function(cld_data) {
  if (is.null(cld_data)) return("No network data available")
  nodes <- if (!is.null(cld_data$nodes) && is.data.frame(cld_data$nodes)) nrow(cld_data$nodes) else 0
  edges <- if (!is.null(cld_data$edges) && is.data.frame(cld_data$edges)) nrow(cld_data$edges) else 0
  loops <- if (!is.null(cld_data$loops) && is.data.frame(cld_data$loops)) nrow(cld_data$loops) else 0
  lines <- c(
    sprintf("Nodes: %d", nodes),
    sprintf("Edges: %d", edges),
    sprintf("Loops: %d", loops)
  )
  return(lines)
}

generate_recommendations_md_safe <- function(responses_data) {
  if (is.null(responses_data)) return("No recommendations available")
  measures <- if (!is.null(responses_data$measures) && is.data.frame(responses_data$measures)) nrow(responses_data$measures) else 0
  if (measures == 0) return("No specific response measures found")
  lines <- c(sprintf("%d response measures", measures))
  if (!is.null(responses_data$measures$name)) {
    lines <- c(lines, paste("Measures:", paste(head(responses_data$measures$name, 10), collapse = ", ")))
  }
  return(lines)
}
