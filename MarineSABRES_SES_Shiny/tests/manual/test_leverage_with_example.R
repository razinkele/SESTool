# Test leverage point analysis with example data
library(jsonlite)

# Load example project
example_data <- readRDS("data/example_baltic_sea_fisheries.rds")

# Check structure
cat("Project structure:\n")
cat("Names:", paste(names(example_data), collapse=", "), "\n\n")

if (!is.null(example_data$data)) {
  cat("Data structure:\n")
  cat("Names:", paste(names(example_data$data), collapse=", "), "\n\n")

  if (!is.null(example_data$data$isa_data)) {
    cat("ISA data exists\n")
    cat("ISA elements:\n")
    cat("  Drivers:", if(!is.null(example_data$data$isa_data$drivers)) nrow(example_data$data$isa_data$drivers) else 0, "\n")
    cat("  Activities:", if(!is.null(example_data$data$isa_data$activities)) nrow(example_data$data$isa_data$activities) else 0, "\n")
    cat("  Pressures:", if(!is.null(example_data$data$isa_data$pressures)) nrow(example_data$data$isa_data$pressures) else 0, "\n")
  }

  if (!is.null(example_data$data$cld)) {
    cat("\nCLD data exists\n")
    cat("  Nodes:", if(!is.null(example_data$data$cld$nodes)) nrow(example_data$data$cld$nodes) else 0, "\n")
    cat("  Edges:", if(!is.null(example_data$data$cld$edges)) nrow(example_data$data$cld$edges) else 0, "\n")
  } else {
    cat("\nNo CLD data found\n")
  }
}
