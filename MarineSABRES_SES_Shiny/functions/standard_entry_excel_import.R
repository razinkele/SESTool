# functions/standard_entry_excel_import.R
# Reader for the Standard Entry Excel export (per-category element sheets +
# Matrix_* adjacency sheets, as written by write_isa_element_sheets()).
# Returns a list shaped like project$data$isa_data. Pure / non-reactive.

# Sheet name -> isa_data element key
.SE_ELEMENT_SHEETS <- c(
  Goods_Benefits     = "goods_benefits",
  Ecosystem_Services = "ecosystem_services",
  Marine_Processes   = "marine_processes",
  Pressures          = "pressures",
  Activities         = "activities",
  Drivers            = "drivers"
)

#' Read a Standard-Entry-exported .xlsx into an isa_data-shaped list.
#' @param path path to an .xlsx file written by write_isa_element_sheets().
#' @return list with the six element data frames (all columns character),
#'   adjacency_matrices (from Matrix_* sheets), and bot_data when present.
read_standard_entry_workbook <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("read_standard_entry_workbook: file not found")
  }
  sheets <- openxlsx::getSheetNames(path)

  out <- list()

  # Element sheets -> character data frames
  for (sheet in names(.SE_ELEMENT_SHEETS)) {
    if (sheet %in% sheets) {
      df <- openxlsx::read.xlsx(path, sheet = sheet)
      if (is.null(df)) df <- data.frame()
      df <- as.data.frame(df, stringsAsFactors = FALSE)
      if (ncol(df) > 0) df[] <- lapply(df, as.character)
      out[[.SE_ELEMENT_SHEETS[[sheet]]]] <- df
    }
  }

  # Matrix_* sheets -> adjacency_matrices (faithful edges)
  matrix_sheets <- sheets[startsWith(sheets, "Matrix_")]
  if (length(matrix_sheets) > 0) {
    am <- list()
    for (sheet in matrix_sheets) {
      key <- sub("^Matrix_", "", sheet)
      m <- openxlsx::read.xlsx(path, sheet = sheet, rowNames = TRUE)
      mat <- as.matrix(m)
      storage.mode(mat) <- "character"
      # NA replacement must follow the character coercion above (numeric NA -> NA_character_, never the string "NA")
      mat[is.na(mat)] <- ""            # in-app empty-cell convention
      am[[key]] <- mat
    }
    out$adjacency_matrices <- am
  }

  # Optional pass-through sheets
  if ("BOT_Data" %in% sheets) {
    bot <- openxlsx::read.xlsx(path, sheet = "BOT_Data")
    if (!is.null(bot)) out$bot_data <- as.data.frame(bot, stringsAsFactors = FALSE)
  }

  out
}
