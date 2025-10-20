# functions/export_functions.R
# Export and reporting functions

library(rmarkdown)
library(htmlwidgets)

# ============================================================================
# VISUALIZATION EXPORT FUNCTIONS
# ============================================================================

#' Export CLD as PNG
#' 
#' @param visnet visNetwork object
#' @param file_path Output file path
#' @param width Image width in pixels
#' @param height Image height in pixels
#' @return NULL (side effect: saves file)
export_cld_png <- function(visnet, file_path, width = 1200, height = 900) {
  
  if (!requireNamespace("webshot", quietly = TRUE)) {
    stop("Package 'webshot' is required for PNG export. Install with: webshot::install_phantomjs()")
  }
  
  # Save as HTML first
  temp_html <- tempfile(fileext = ".html")
  htmlwidgets::saveWidget(visnet, temp_html, selfcontained = TRUE)
  
  # Convert to PNG
  webshot::webshot(temp_html, file_path, vwidth = width, vheight = height)
  
  # Clean up
  unlink(temp_html)
  
  message("CLD exported as PNG: ", file_path)
}

#' Export CLD as SVG
#' 
#' @param visnet visNetwork object
#' @param file_path Output file path
#' @return NULL (side effect: saves file)
export_cld_svg <- function(visnet, file_path) {
  
  # SVG export requires additional tools
  # This is a placeholder - full implementation would need additional packages
  
  warning("SVG export not yet fully implemented. Use HTML or PNG export instead.")
}

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
  
  message("CLD exported as HTML: ", file_path)
}

#' Export BOT graphs as PDF
#' 
#' @param bot_data_list List of BOT data for different elements
#' @param file_path Output file path
#' @param width PDF width in inches
#' @param height PDF height in inches
#' @return NULL (side effect: saves file)
export_bot_pdf <- function(bot_data_list, file_path, width = 11, height = 8.5) {
  
  pdf(file_path, width = width, height = height)
  
  for (element_name in names(bot_data_list)) {
    bot_data <- bot_data_list[[element_name]]
    
    if (nrow(bot_data) > 0) {
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
    }
  }
  
  dev.off()
  
  message("BOT graphs exported as PDF: ", file_path)
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
  
  # Loops
  if (!is.null(project_data$data$cld$loops) && 
      nrow(project_data$data$cld$loops) > 0) {
    addWorksheet(wb, "Feedback_Loops")
    writeData(wb, "Feedback_Loops", project_data$data$cld$loops)
  }
  
  # Response measures
  if (!is.null(project_data$data$responses$measures) && 
      nrow(project_data$data$responses$measures) > 0) {
    addWorksheet(wb, "Response_Measures")
    writeData(wb, "Response_Measures", project_data$data$responses$measures)
  }
  
  saveWorkbook(wb, file_path, overwrite = TRUE)
  
  message("Project data exported to Excel: ", file_path)
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
    "drivers" = "Drivers"
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
      "gb_es" = "Matrix_GB_ES",
      "es_mpf" = "Matrix_ES_MPF",
      "mpf_p" = "Matrix_MPF_P",
      "p_a" = "Matrix_P_A",
      "a_d" = "Matrix_A_D",
      "d_gb" = "Matrix_D_GB"
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
  
  message("Project data exported as JSON: ", file_path)
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
  
  # Export ISA data
  isa_data <- project_data$data$isa_data
  element_names <- c("goods_benefits", "ecosystem_services", "marine_processes",
                    "pressures", "activities", "drivers")
  
  for (elem_name in element_names) {
    if (!is.null(isa_data[[elem_name]]) && nrow(isa_data[[elem_name]]) > 0) {
      write.csv(isa_data[[elem_name]], 
               file.path(temp_dir, paste0(elem_name, ".csv")), 
               row.names = FALSE)
    }
  }
  
  # Export loops
  if (!is.null(project_data$data$cld$loops)) {
    write.csv(project_data$data$cld$loops, 
             file.path(temp_dir, "loops.csv"), row.names = FALSE)
  }
  
  # Create zip file
  current_dir <- getwd()
  setwd(temp_dir)
  zip(file_path, list.files())
  setwd(current_dir)
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
  
  message("Project data exported as CSV zip: ", file_path)
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
  
  message("Executive summary generated: ", output_file)
}

#' Create executive summary Rmd content
#' 
#' @param project_data Project data list
#' @return Character vector of Rmd lines
create_executive_summary_rmd <- function(project_data) {
  
  c(
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
    generate_element_summary_md(project_data$data$isa_data),
    "",
    "## Network Structure",
    "",
    generate_network_summary_md(project_data$data$cld),
    "",
    "## Key Findings",
    "",
    generate_key_findings_md(project_data),
    "",
    "# Recommendations",
    "",
    generate_recommendations_md(project_data$data$responses),
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
#' @param responses_data Responses data list
#' @return Character vector
generate_recommendations_md <- function(responses_data) {
  
  lines <- c()
  
  if (!is.null(responses_data$measures) && nrow(responses_data$measures) > 0) {
    lines <- c(lines, 
              paste0("Based on the analysis, ", nrow(responses_data$measures), 
                    " response measures have been identified:"),
              "")
    
    for (i in 1:min(5, nrow(responses_data$measures))) {
      measure <- responses_data$measures[i, ]
      lines <- c(lines, paste0(i, ". **", measure$name, ":** ", measure$description))
    }
  } else {
    lines <- c(lines, "No specific response measures have been defined yet.")
  }
  
  return(lines)
}

#' Generate technical report
#' 
#' @param project_data Project data list
#' @param output_file Output file path
#' @param include_visualizations Include CLD and BOT graphs
#' @return NULL (side effect: generates report)
generate_technical_report <- function(project_data, output_file, 
                                     include_visualizations = TRUE) {
  
  # More detailed report implementation
  # This would include full data tables, detailed analysis, etc.
  
  message("Technical report generation not yet fully implemented")
}

#' Generate stakeholder presentation
#' 
#' @param project_data Project data list
#' @param output_file Output file path (PPT or HTML)
#' @return NULL (side effect: generates presentation)
generate_stakeholder_presentation <- function(project_data, output_file) {
  
  # Presentation generation implementation
  # This would create slides suitable for stakeholder meetings
  
  message("Presentation generation not yet fully implemented")
}
