#!/usr/bin/env Rscript
# Test loading each module individually to find the error

library(shiny)

cat("Testing module loading...\n\n")

# Create a mock i18n object for testing
i18n <- list(
  t = function(key) key  # Just return the key itself
)

modules <- c(
  "modules/pims_module.R",
  "modules/pims_stakeholder_module.R",
  "modules/ai_isa_assistant_module.R",
  "modules/cld_visualization_module.R"
)

for (mod in modules) {
  cat("Testing:", mod, "\n")
  tryCatch({
    source(mod, local = TRUE)
    cat("  ✓ SUCCESS\n")
  }, error = function(e) {
    cat("  ✗ ERROR:", conditionMessage(e), "\n")
  })
  cat("\n")
}

cat("Done.\n")
