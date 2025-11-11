# Extract all labels and descriptions from global.R
library(jsonlite)

labels <- list()

# Read global.R
lines <- readLines("global.R")

# Simple extraction of label = "..." and description = "..."
for(i in seq_along(lines)) {
  line <- lines[i]
  
  # Extract label
  if(grepl('label\s*=\s*"', line)) {
    match <- regmatches(line, regexpr('"[^"]*"', line))
    if(length(match) > 0) {
      text <- gsub('"', '', match)
      labels[[length(labels) + 1]] <- list(type = "label", text = text, line = i)
    }
  }
  
  # Extract description
  if(grepl('description\s*=\s*"', line)) {
    match <- regmatches(line, regexpr('"[^"]*"', line))
    if(length(match) > 0) {
      text <- gsub('"', '', match)
      labels[[length(labels) + 1]] <- list(type = "description", text = text, line = i)
    }
  }
}

cat("Total labels/descriptions found:", length(labels), "\n\n")
cat("First 20 entries:\n")
for(i in 1:min(20, length(labels))) {
  cat(sprintf("[%3d] Line %4d %-12s: %s\n", i, labels[[i]]$line, 
              paste0("(", labels[[i]]$type, ")"), labels[[i]]$text))
}

# Save to file
write(toJSON(labels, pretty = TRUE, auto_unbox = TRUE), "entry_point_labels.json")
cat("\nFull list saved to: entry_point_labels.json\n")
cat("Total unique texts:", length(unique(sapply(labels, function(x) x$text))), "\n")
