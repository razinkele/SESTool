# Inspect auto-save data structure
library(jsonlite)

# Read the latest auto-save file
latest_file <- "C:/Users/DELL/AppData/Local/Temp/Rtmpy2KTak/marinesabres_autosave/latest_autosave.rds"

if (file.exists(latest_file)) {
  cat("=== Reading auto-save file ===\n")
  data <- readRDS(latest_file)

  cat("\n=== Top-level structure ===\n")
  cat("Names:", paste(names(data), collapse=", "), "\n")
  cat("Length:", length(data), "\n")

  cat("\n=== Checking for ISA data ===\n")
  if ("data" %in% names(data)) {
    cat("Found 'data' element\n")
    cat("  Names in data:", paste(names(data$data), collapse=", "), "\n")

    if ("isa_data" %in% names(data$data)) {
      cat("  Found 'isa_data' element\n")
      cat("    Names in isa_data:", paste(names(data$data$isa_data), collapse=", "), "\n")

      # Check each ISA component
      if ("drivers" %in% names(data$data$isa_data)) {
        cat("    Drivers count:", length(data$data$isa_data$drivers %||% list()), "\n")
      }
      if ("activities" %in% names(data$data$isa_data)) {
        cat("    Activities count:", length(data$data$isa_data$activities %||% list()), "\n")
      }
      if ("pressures" %in% names(data$data$isa_data)) {
        cat("    Pressures count:", length(data$data$isa_data$pressures %||% list()), "\n")
      }
      if ("state_changes" %in% names(data$data$isa_data)) {
        cat("    State changes count:", length(data$data$isa_data$state_changes %||% list()), "\n")
      }
      if ("impacts" %in% names(data$data$isa_data)) {
        cat("    Impacts count:", length(data$data$isa_data$impacts %||% list()), "\n")
      }
      if ("responses" %in% names(data$data$isa_data)) {
        cat("    Responses count:", length(data$data$isa_data$responses %||% list()), "\n")
      }
    } else {
      cat("  NO 'isa_data' element found!\n")
    }
  } else {
    cat("NO 'data' element found!\n")
  }

  cat("\n=== Full structure (JSON) ===\n")
  cat(toJSON(data, auto_unbox = TRUE, pretty = TRUE, null = "null"))

} else {
  cat("No auto-save file found at:", latest_file, "\n")
}
