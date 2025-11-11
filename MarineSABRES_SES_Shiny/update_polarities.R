# Script to update connection polarity assignments in ai_isa_assistant_module.R
file_path <- "modules/ai_isa_assistant_module.R"
content <- readLines(file_path)

# Find and update D → A connections (around line 1994)
for (i in seq_along(content)) {
  # D → A
  if (grepl("polarity = \"\\+\",.*# D → A", content[i]) ||
      (i > 1990 && i < 2010 && grepl("polarity = \"\\+\",", content[i]) && grepl("drivers.*activities", content[i-5]))) {
    content[i] <- sub('polarity = "\\+"',
                      'polarity = detect_polarity(elements$drivers[[i]]$name, elements$activities[[j]]$name, "drivers", "activities")',
                      content[i])
  }

  # A → P
  if (grepl("polarity = \"\\+\",.*# A → P", content[i]) ||
      (i > 2005 && i < 2025 && grepl("polarity = \"\\+\",", content[i]) && grepl("activities.*pressures", content[i-5]))) {
    content[i] <- sub('polarity = "\\+"',
                      'polarity = detect_polarity(elements$activities[[i]]$name, elements$pressures[[j]]$name, "activities", "pressures")',
                      content[i])
  }

  # P → S
  if (grepl("polarity = \"-\",.*# P → S", content[i]) ||
      (i > 2025 && i < 2045 && grepl("polarity = \"-\",", content[i]) && grepl("pressures.*states", content[i-5]))) {
    content[i] <- sub('polarity = "-"',
                      'polarity = detect_polarity(elements$pressures[[i]]$name, elements$states[[j]]$name, "pressures", "states")',
                      content[i])
  }

  # S → I
  if (grepl("polarity = \"-\",.*# S → I", content[i]) ||
      (i > 2045 && i < 2065 && grepl("polarity = \"-\",", content[i]) && grepl("states.*impacts", content[i-5]))) {
    content[i] <- sub('polarity = "-"',
                      'polarity = detect_polarity(elements$states[[i]]$name, elements$impacts[[j]]$name, "states", "impacts")',
                      content[i])
  }

  # I → W
  if (grepl("polarity = \"-\",.*# I → W", content[i]) ||
      (i > 2065 && i < 2085 && grepl("polarity = \"-\",", content[i]) && grepl("impacts.*welfare", content[i-5]))) {
    content[i] <- sub('polarity = "-"',
                      'polarity = detect_polarity(elements$impacts[[i]]$name, elements$welfare[[j]]$name, "impacts", "welfare")',
                      content[i])
  }

  # R → P
  if (grepl("polarity = \"-\",.*# R → P", content[i]) ||
      (i > 2085 && i < 2105 && grepl("polarity = \"-\",", content[i]) && grepl("responses.*pressures", content[i-5]))) {
    content[i] <- sub('polarity = "-"',
                      'polarity = detect_polarity(elements$responses[[i]]$name, elements$pressures[[j]]$name, "responses", "pressures")',
                      content[i])
  }

  # M → R
  if (grepl("polarity = \"\\+\",.*# M → R", content[i]) ||
      (i > 2105 && i < 2125 && grepl("polarity = \"\\+\",", content[i]) && grepl("measures.*responses", content[i-5]))) {
    content[i] <- sub('polarity = "\\+"',
                      'polarity = detect_polarity(elements$measures[[i]]$name, elements$responses[[j]]$name, "measures", "responses")',
                      content[i])
  }
}

writeLines(content, file_path)
cat("Updated polarity assignments in", file_path, "\n")
