# functions/isa_export_helpers.R
# Extracted from modules/isa_data_entry_module.R
# Export logic for ISA data (Excel workbook, Kumu CSV)

# ============================================================================
# EXCEL EXPORT
# ============================================================================

#' Write ISA element data to an openxlsx workbook
#'
#' Creates worksheets for each element type and writes the data frames.
#'
#' @param wb An openxlsx workbook object
#' @param isa_data Reactive values or list containing ISA element data frames
#' @param include_adjacency Logical; if TRUE, also write adjacency matrix sheets
#' @return The workbook object (invisibly), modified in place
write_isa_element_sheets <- function(wb, isa_data, include_adjacency = TRUE) {
  sheet_map <- list(
    "Goods_Benefits"     = isa_data$goods_benefits,
    "Ecosystem_Services" = isa_data$ecosystem_services,
    "Marine_Processes"   = isa_data$marine_processes,
    "Pressures"          = isa_data$pressures,
    "Activities"         = isa_data$activities,
    "Drivers"            = isa_data$drivers
  )

  for (sheet_name in names(sheet_map)) {
    addWorksheet(wb, sheet_name)
    writeData(wb, sheet_name, sheet_map[[sheet_name]])
  }

  if (include_adjacency && !is.null(isa_data$adjacency_matrices)) {
    for (mat_name in names(isa_data$adjacency_matrices)) {
      mat <- isa_data$adjacency_matrices[[mat_name]]
      if (!is.null(mat) && is.matrix(mat)) {
        sheet_name <- substr(paste0("Matrix_", mat_name), 1, 31)
        addWorksheet(wb, sheet_name)
        writeData(wb, sheet_name, as.data.frame(mat), rowNames = TRUE)
      }
    }
  }

  invisible(wb)
}

#' Create a complete ISA analysis Excel workbook
#'
#' @param isa_data Reactive values or list containing all ISA data
#' @return An openxlsx workbook ready to save
create_isa_analysis_workbook <- function(isa_data) {
  wb <- createWorkbook()

  addWorksheet(wb, "Case_Info")
  addWorksheet(wb, "Goods_Benefits")
  addWorksheet(wb, "Ecosystem_Services")
  addWorksheet(wb, "Marine_Processes")
  addWorksheet(wb, "Pressures")
  addWorksheet(wb, "Activities")
  addWorksheet(wb, "Drivers")
  addWorksheet(wb, "BOT_Data")

  writeData(wb, "Goods_Benefits", isa_data$goods_benefits)
  writeData(wb, "Ecosystem_Services", isa_data$ecosystem_services)
  writeData(wb, "Marine_Processes", isa_data$marine_processes)
  writeData(wb, "Pressures", isa_data$pressures)
  writeData(wb, "Activities", isa_data$activities)
  writeData(wb, "Drivers", isa_data$drivers)
  writeData(wb, "BOT_Data", isa_data$bot_data)

  wb
}

# ============================================================================
# KUMU CSV EXPORT
# ============================================================================

#' Build a combined elements data.frame for Kumu export
#'
#' @param isa_data Reactive values or list containing ISA element data frames
#' @return A data.frame with Label, Type, and ID columns
build_kumu_elements <- function(isa_data) {
  dfs <- list(
    data.frame(Label = isa_data$goods_benefits$Name,     Type = "Goods & Benefits",  ID = isa_data$goods_benefits$ID),
    data.frame(Label = isa_data$ecosystem_services$Name,  Type = "Ecosystem Service", ID = isa_data$ecosystem_services$ID),
    data.frame(Label = isa_data$marine_processes$Name,    Type = "Marine Process",    ID = isa_data$marine_processes$ID),
    data.frame(Label = isa_data$pressures$Name,           Type = "Pressure",          ID = isa_data$pressures$ID),
    data.frame(Label = isa_data$activities$Name,          Type = "Activity",          ID = isa_data$activities$ID),
    data.frame(Label = isa_data$drivers$Name,             Type = "Driver",            ID = isa_data$drivers$ID)
  )
  do.call(rbind, dfs)
}

#' Create Kumu export zip file from ISA data
#'
#' Writes elements.csv and connections.csv to a temp directory, then zips them.
#'
#' @param isa_data Reactive values or list containing ISA element data
#' @param output_file Path to write the zip file
create_kumu_export_zip <- function(isa_data, output_file) {
  temp_dir <- tempdir()

  all_elements <- build_kumu_elements(isa_data)
  write.csv(all_elements, file.path(temp_dir, "elements.csv"), row.names = FALSE)

  # Connections file (to be built from adjacency matrices)
  connections <- data.frame(
    From = character(),
    To = character(),
    Type = character(),
    Strength = character(),
    Confidence = integer(),
    Delay = character(),
    `Delay (years)` = numeric(),
    check.names = FALSE
  )
  write.csv(connections, file.path(temp_dir, "connections.csv"), row.names = FALSE)

  csv_files <- c(file.path(temp_dir, "elements.csv"), file.path(temp_dir, "connections.csv"))
  zip(output_file, files = csv_files)
  unlink(csv_files)
}
