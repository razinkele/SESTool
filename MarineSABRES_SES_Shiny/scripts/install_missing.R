lib <- file.path(Sys.getenv("USERPROFILE"), "R", "win-library", "4.4")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
cat("Library:", lib, "\n")

needed <- c("bs4Dash", "shinyWidgets", "shinyjs", "shinyBS", "shinyFiles",
            "DT", "openxlsx", "readxl", "httr", "jsonlite", "digest",
            "igraph", "visNetwork", "ggraph", "tidygraph", "ggplot2",
            "plotly", "dygraphs", "xts", "rmarkdown",
            "htmlwidgets", "shiny.i18n", "htmltools", "tidyverse",
            "shinydashboard")

installed <- rownames(installed.packages())
missing <- needed[!needed %in% installed]
cat("Missing:", length(missing), "\n")
if (length(missing) > 0) {
  cat(paste(missing, collapse = ", "), "\n")
  install.packages(missing, lib = lib, repos = "https://cran.r-project.org")
}
cat("Done.\n")
