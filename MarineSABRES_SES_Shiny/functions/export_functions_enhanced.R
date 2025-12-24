# functions/export_functions_enhanced.R
# Enhanced export helpers with safer behavior

# Validate output path
validate_output_path <- function(path) {
  if (is.null(path)) stop("File path is NULL")
  if (!is.character(path) || nchar(trimws(path)) == 0) stop("File path cannot be empty")
  dir <- dirname(path)
  if (!dir.exists(dir)) stop("Directory does not exist")
  TRUE
}

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

    # Use existing exporter if available
    if (exists("export_project_excel")) {
      export_project_excel(project, file_path)
    } else {
      # fallback: write an empty workbook
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

# Add element safe uses wrapper from data_structure_enhanced
add_element_safe <- function(isa_data, elem_name, elem_row) {
  if (is.null(isa_data)) return(NULL)
  if (is.null(elem_row)) return(isa_data)
  if (is.null(isa_data[[elem_name]])) {
    isa_data[[elem_name]] <- create_empty_element_df(gsub("_", " ", elem_name))
  }
  if (!is.data.frame(elem_row)) elem_row <- as.data.frame(elem_row, stringsAsFactors = FALSE)
  isa_data[[elem_name]] <- rbind(isa_data[[elem_name]], elem_row)
  return(isa_data)
}

# ------------------------------------------------------------------
# Additional safe export helpers required by tests
# ------------------------------------------------------------------

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

# Markdown generation helpers
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
  # Include names of measures
  if (!is.null(responses_data$measures$name)) {
    lines <- c(lines, paste("Measures:", paste(head(responses_data$measures$name, 10), collapse = ", ")))
  }
  return(lines)
}