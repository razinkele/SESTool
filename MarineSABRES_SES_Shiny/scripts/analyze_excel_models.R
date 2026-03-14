# Analyze SESModels Excel file structures
library(readxl)

# Find all Excel files
files <- list.files("SESModels", pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)

cat("Found", length(files), "Excel files\n\n")

results <- list()

for (f in files) {
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("FILE:", basename(f), "\n")
  cat("PATH:", f, "\n")

  sheets <- tryCatch(excel_sheets(f), error = function(e) character())
  cat("SHEETS (", length(sheets), "):", paste(sheets, collapse = ", "), "\n\n")

  file_result <- list(
    file = basename(f),
    path = f,
    sheets = sheets,
    sheet_details = list()
  )

  # Read all sheets to understand structure
  for (sheet in sheets) {
    cat("  Sheet:", sheet, "\n")
    sheet_data <- tryCatch({
      data <- read_excel(f, sheet = sheet, n_max = 10)
      list(
        columns = names(data),
        ncol = ncol(data),
        nrow_preview = nrow(data)
      )
    }, error = function(e) {
      list(error = e$message)
    })

    if (is.null(sheet_data$error)) {
      cat("    Columns (", sheet_data$ncol, "):", paste(sheet_data$columns, collapse = ", "), "\n")

      # Identify sheet type based on columns
      cols_lower <- tolower(sheet_data$columns)
      has_from_to <- any(grepl("^from$", cols_lower)) && any(grepl("^to$", cols_lower))
      has_label_type <- any(grepl("^label$", cols_lower)) && any(grepl("^type", cols_lower))
      has_source_target <- any(grepl("source", cols_lower)) && any(grepl("target", cols_lower))

      if (has_from_to) {
        cat("    -> LIKELY EDGES/CONNECTIONS (has From/To columns)\n")
      } else if (has_label_type) {
        cat("    -> LIKELY NODES/ELEMENTS (has Label/Type columns)\n")
      } else if (has_source_target) {
        cat("    -> LIKELY EDGES (has Source/Target columns)\n")
      }
    } else {
      cat("    ERROR:", sheet_data$error, "\n")
    }

    file_result$sheet_details[[sheet]] <- sheet_data
    cat("\n")
  }

  results[[basename(f)]] <- file_result
}

# Summary
cat("\n\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("SUMMARY OF FILE STRUCTURES\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

for (name in names(results)) {
  r <- results[[name]]
  cat(name, ":\n")

  # Identify potential node and edge sheets
  node_sheets <- c()
  edge_sheets <- c()

  for (sheet in names(r$sheet_details)) {
    d <- r$sheet_details[[sheet]]
    if (!is.null(d$columns)) {
      cols_lower <- tolower(d$columns)
      if (any(grepl("^from$", cols_lower)) && any(grepl("^to$", cols_lower))) {
        edge_sheets <- c(edge_sheets, sheet)
      } else if (any(grepl("source", cols_lower)) && any(grepl("target", cols_lower))) {
        edge_sheets <- c(edge_sheets, sheet)
      } else if (any(grepl("^label$", cols_lower)) || any(grepl("node", tolower(sheet)))) {
        node_sheets <- c(node_sheets, sheet)
      } else if (any(grepl("edge", tolower(sheet)))) {
        edge_sheets <- c(edge_sheets, sheet)
      }
    }
  }

  cat("  Potential NODE sheets:", if(length(node_sheets) > 0) paste(node_sheets, collapse = ", ") else "None detected", "\n")
  cat("  Potential EDGE sheets:", if(length(edge_sheets) > 0) paste(edge_sheets, collapse = ", ") else "None detected", "\n")
  cat("\n")
}
