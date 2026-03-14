# Analysis script for SES Model Excel files
# Generates a comprehensive report of structure and inconsistencies

library(readxl)
library(dplyr)

# Get all Excel files
base_dir <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/SESModels"
files <- list.files(base_dir, pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)

cat("=" , rep("=", 79), "\n", sep = "")
cat("SES MODEL EXCEL FILES ANALYSIS REPORT\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=" , rep("=", 79), "\n\n", sep = "")

# Store analysis results
all_results <- list()

for (file_path in files) {
  file_name <- basename(file_path)
  rel_path <- gsub(paste0(base_dir, "/"), "", file_path)

  cat("\n", rep("-", 80), "\n", sep = "")
  cat("FILE:", rel_path, "\n")
  cat(rep("-", 80), "\n", sep = "")

  result <- list(
    file = rel_path,
    sheets = list(),
    errors = character()
  )

  # Get sheet names
  sheets <- tryCatch({
    excel_sheets(file_path)
  }, error = function(e) {
    result$errors <<- c(result$errors, paste("Cannot read file:", e$message))
    character()
  })

  cat("Sheets:", paste(sheets, collapse = ", "), "\n\n")

  for (sheet in sheets) {
    cat("  SHEET:", sheet, "\n")

    sheet_info <- list(
      name = sheet,
      columns = character(),
      row_count = 0,
      has_label = FALSE,
      has_type = FALSE,
      has_from = FALSE,
      has_to = FALSE,
      unique_types = character(),
      sample_labels = character(),
      na_counts = list()
    )

    # Read sheet
    data <- tryCatch({
      read_excel(file_path, sheet = sheet)
    }, error = function(e) {
      cat("    ERROR reading sheet:", e$message, "\n")
      NULL
    })

    if (!is.null(data) && nrow(data) > 0) {
      cols <- names(data)
      cols_lower <- tolower(cols)

      sheet_info$columns <- cols
      sheet_info$row_count <- nrow(data)
      sheet_info$has_label <- any(cols_lower == "label")
      sheet_info$has_type <- any(grepl("type", cols_lower))
      sheet_info$has_from <- any(cols_lower == "from")
      sheet_info$has_to <- any(cols_lower == "to")

      cat("    Columns:", paste(cols, collapse = ", "), "\n")
      cat("    Rows:", nrow(data), "\n")

      # Check for Label column
      if (sheet_info$has_label) {
        label_col <- cols[cols_lower == "label"][1]
        labels <- data[[label_col]]
        na_count <- sum(is.na(labels))
        empty_count <- sum(!is.na(labels) & nchar(trimws(as.character(labels))) == 0)
        sheet_info$sample_labels <- head(na.omit(labels), 5)
        sheet_info$na_counts$label <- na_count
        cat("    Label column: ", label_col, " (NA:", na_count, ", Empty:", empty_count, ")\n")
        cat("    Sample labels:", paste(head(na.omit(labels), 3), collapse = ", "), "\n")
      }

      # Check for Type column
      type_cols <- cols[grepl("type", cols_lower)]
      if (length(type_cols) > 0) {
        for (tc in type_cols) {
          types <- data[[tc]]
          unique_types <- unique(na.omit(types))
          na_count <- sum(is.na(types))
          sheet_info$unique_types <- c(sheet_info$unique_types, as.character(unique_types))
          sheet_info$na_counts[[tc]] <- na_count
          cat("    Type column '", tc, "':\n", sep = "")
          cat("      Unique values:", paste(unique_types, collapse = ", "), "\n")
          cat("      NA count:", na_count, "of", nrow(data), "\n")
        }
      }

      # Check for From/To columns
      if (sheet_info$has_from && sheet_info$has_to) {
        from_col <- cols[cols_lower == "from"][1]
        to_col <- cols[cols_lower == "to"][1]
        from_vals <- data[[from_col]]
        to_vals <- data[[to_col]]

        from_na <- sum(is.na(from_vals))
        to_na <- sum(is.na(to_vals))
        sheet_info$na_counts$from <- from_na
        sheet_info$na_counts$to <- to_na

        cat("    From column:", from_col, "(NA:", from_na, ")\n")
        cat("    To column:", to_col, "(NA:", to_na, ")\n")

        # Check for unique nodes referenced
        all_nodes <- unique(c(as.character(from_vals), as.character(to_vals)))
        all_nodes <- all_nodes[!is.na(all_nodes) & nchar(trimws(all_nodes)) > 0]
        cat("    Unique nodes in edges:", length(all_nodes), "\n")
      }

      # Check for other potentially useful columns
      other_cols <- setdiff(cols_lower, c("label", "type", "from", "to"))
      interesting_cols <- c("description", "tags", "notes", "strength", "confidence",
                           "direction", "polarity", "weight", "color", "shape")
      found_interesting <- cols[cols_lower %in% interesting_cols]
      if (length(found_interesting) > 0) {
        cat("    Other columns:", paste(found_interesting, collapse = ", "), "\n")
      }
    } else {
      cat("    (Empty or unreadable sheet)\n")
    }

    result$sheets[[sheet]] <- sheet_info
    cat("\n")
  }

  all_results[[rel_path]] <- result
}

# Summary section
cat("\n\n")
cat("=" , rep("=", 79), "\n", sep = "")
cat("SUMMARY AND INCONSISTENCIES\n")
cat("=" , rep("=", 79), "\n\n", sep = "")

# 1. Sheet naming patterns
cat("1. SHEET NAMING PATTERNS\n")
cat(rep("-", 40), "\n", sep = "")
all_sheets <- unlist(lapply(all_results, function(r) names(r$sheets)))
sheet_counts <- table(all_sheets)
cat("Unique sheet names across all files:\n")
for (s in names(sort(sheet_counts, decreasing = TRUE))) {
  cat("  ", s, ": ", sheet_counts[s], " files\n", sep = "")
}

# 2. Type values found
cat("\n2. DAPSIWRM TYPE VALUES FOUND\n")
cat(rep("-", 40), "\n", sep = "")
all_types <- character()
for (r in all_results) {
  for (s in r$sheets) {
    all_types <- c(all_types, s$unique_types)
  }
}
type_counts <- table(all_types)
cat("All type values (with frequency):\n")
for (t in names(sort(type_counts, decreasing = TRUE))) {
  cat("  ", t, ": ", type_counts[t], "\n", sep = "")
}

# Expected DAPSIWRM types
expected_types <- c("Driver", "Activity", "Pressure", "State",
                    "Marine Process and Function", "Impact",
                    "Ecosystem Service", "Good and Benefit", "Welfare",
                    "Response", "Measure")
found_types <- names(type_counts)
unexpected <- setdiff(found_types, expected_types)
if (length(unexpected) > 0) {
  cat("\nNon-standard type values:\n")
  for (t in unexpected) {
    cat("  - '", t, "'\n", sep = "")
  }
}

# 3. File format classification
cat("\n3. FILE FORMAT CLASSIFICATION\n")
cat(rep("-", 40), "\n", sep = "")

for (file_name in names(all_results)) {
  r <- all_results[[file_name]]
  sheet_names <- names(r$sheets)

  format_type <- "Unknown"

  if ("Elements" %in% sheet_names && "Connections" %in% sheet_names) {
    format_type <- "KUMU Standard (Elements + Connections)"
  } else if (any(grepl("node.*label", tolower(sheet_names))) &&
             any(grepl("edge|kumu", tolower(sheet_names)))) {
    format_type <- "Multi-variant (Node Labels + Edges pattern)"
  } else if (any(grepl("edge.*label", tolower(sheet_names))) &&
             any(grepl("node.*data", tolower(sheet_names)))) {
    format_type <- "Confusing naming (Edge Labels=nodes, Node Data=edges)"
  } else {
    # Check if any sheet has From/To but no Label column
    has_edges_only <- FALSE
    for (s in r$sheets) {
      if (s$has_from && s$has_to && !s$has_label) {
        has_edges_only <- TRUE
        break
      }
    }
    if (has_edges_only) {
      format_type <- "Edges-only (nodes must be inferred)"
    }
  }

  cat("  ", file_name, "\n    -> ", format_type, "\n", sep = "")
}

# 4. Data quality issues
cat("\n4. DATA QUALITY ISSUES\n")
cat(rep("-", 40), "\n", sep = "")

for (file_name in names(all_results)) {
  r <- all_results[[file_name]]
  issues <- character()

  for (sheet_name in names(r$sheets)) {
    s <- r$sheets[[sheet_name]]

    # Check for high NA counts
    if (!is.null(s$na_counts$label) && s$na_counts$label > 0) {
      issues <- c(issues, paste0("Sheet '", sheet_name, "': ", s$na_counts$label, " NA values in Label column"))
    }

    for (tc in names(s$na_counts)) {
      if (grepl("type", tc, ignore.case = TRUE) && s$na_counts[[tc]] > 0) {
        pct <- round(100 * s$na_counts[[tc]] / s$row_count, 1)
        if (pct > 10) {
          issues <- c(issues, paste0("Sheet '", sheet_name, "': ", pct, "% NA values in type column '", tc, "'"))
        }
      }
    }

    if (!is.null(s$na_counts$from) && s$na_counts$from > 0) {
      issues <- c(issues, paste0("Sheet '", sheet_name, "': ", s$na_counts$from, " NA values in From column"))
    }

    if (!is.null(s$na_counts$to) && s$na_counts$to > 0) {
      issues <- c(issues, paste0("Sheet '", sheet_name, "': ", s$na_counts$to, " NA values in To column"))
    }
  }

  if (length(issues) > 0) {
    cat("  ", file_name, ":\n", sep = "")
    for (issue in issues) {
      cat("    - ", issue, "\n", sep = "")
    }
  }
}

# 5. Column naming inconsistencies
cat("\n5. COLUMN NAMING PATTERNS\n")
cat(rep("-", 40), "\n", sep = "")

all_cols <- character()
for (r in all_results) {
  for (s in r$sheets) {
    all_cols <- c(all_cols, s$columns)
  }
}
col_counts <- table(all_cols)
cat("Most common columns:\n")
for (c in names(sort(col_counts, decreasing = TRUE))[1:min(20, length(col_counts))]) {
  cat("  ", c, ": ", col_counts[c], " occurrences\n", sep = "")
}

cat("\n\nAnalysis complete.\n")
