# install_packages.R
# Automated package installation script for MarineSABRES SES Shiny Application

cat("================================================================================\n")
cat("MarineSABRES SES Shiny Application - Package Installer\n")
cat("================================================================================\n\n")

# Function to install packages if not already installed
install_if_missing <- function(packages, repo = "CRAN") {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat(paste0("Installing ", pkg, " from ", repo, "...\n"))
      tryCatch({
        install.packages(pkg, dependencies = TRUE)
        cat(paste0("  ✓ ", pkg, " installed successfully\n"))
      }, error = function(e) {
        cat(paste0("  ✗ Error installing ", pkg, ": ", e$message, "\n"))
      })
    } else {
      cat(paste0("  ✓ ", pkg, " already installed\n"))
    }
  }
}

# Check R version
r_version <- as.numeric(paste0(R.version$major, ".", R.version$minor))
if (r_version < 4.0) {
  warning("R version 4.0.0 or higher is recommended. Current version: ", R.version.string)
}

cat("\nStep 1/5: Installing Core Shiny Packages...\n")
cat("------------------------------------------------------------\n")
core_packages <- c(
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "shinyjs"
)
install_if_missing(core_packages)

cat("\nStep 2/5: Installing Data Manipulation Packages...\n")
cat("------------------------------------------------------------\n")
data_packages <- c(
  "tidyverse",
  "dplyr",
  "tidyr",
  "purrr",
  "readr",
  "DT",
  "openxlsx",
  "jsonlite"
)
install_if_missing(data_packages)

cat("\nStep 3/5: Installing Network Analysis Packages...\n")
cat("------------------------------------------------------------\n")
network_packages <- c(
  "igraph",
  "visNetwork",
  "ggraph",
  "tidygraph"
)
install_if_missing(network_packages)

cat("\nStep 4/5: Installing Visualization Packages...\n")
cat("------------------------------------------------------------\n")
viz_packages <- c(
  "ggplot2",
  "plotly",
  "dygraphs",
  "timevis"
)
install_if_missing(viz_packages)

cat("\nStep 5/5: Installing Export and Reporting Packages...\n")
cat("------------------------------------------------------------\n")
export_packages <- c(
  "rmarkdown",
  "knitr",
  "htmlwidgets",
  "htmltools"
)
install_if_missing(export_packages)

# Install webshot and phantomjs for PNG export
cat("\nInstalling webshot for PNG export functionality...\n")
cat("------------------------------------------------------------\n")
if (!requireNamespace("webshot", quietly = TRUE)) {
  install.packages("webshot")
  cat("  ✓ webshot installed\n")
} else {
  cat("  ✓ webshot already installed\n")
}

cat("\nInstalling phantomjs...\n")
if (!webshot::is_phantomjs_installed()) {
  cat("  Installing phantomjs (this may take a few minutes)...\n")
  tryCatch({
    webshot::install_phantomjs()
    cat("  ✓ phantomjs installed successfully\n")
  }, error = function(e) {
    cat("  ✗ Error installing phantomjs: ", e$message, "\n")
    cat("  You can try installing manually with: webshot::install_phantomjs()\n")
  })
} else {
  cat("  ✓ phantomjs already installed\n")
}

# Verification
cat("\n================================================================================\n")
cat("Installation Verification\n")
cat("================================================================================\n\n")

all_packages <- c(core_packages, data_packages, network_packages, viz_packages, export_packages, "webshot")
missing_packages <- c()

for (pkg in all_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) == 0) {
  cat("✓ SUCCESS: All required packages are installed!\n\n")
  cat("Next steps:\n")
  cat("1. Verify your working directory: getwd()\n")
  cat("2. Set working directory if needed: setwd('path/to/MarineSABRES_SES_Shiny')\n")
  cat("3. Launch the application: shiny::runApp()\n\n")
} else {
  cat("✗ WARNING: The following packages failed to install:\n")
  for (pkg in missing_packages) {
    cat("  - ", pkg, "\n")
  }
  cat("\nPlease try installing these packages manually:\n")
  cat("install.packages(c(", paste0("'", missing_packages, "'", collapse = ", "), "))\n\n")
}

# Check phantomjs
if (!webshot::is_phantomjs_installed()) {
  cat("⚠ WARNING: phantomjs is not installed. PNG export will not work.\n")
  cat("Install with: webshot::install_phantomjs()\n\n")
}

# Save installation log
log_file <- "installation_log.txt"
sink(log_file, append = FALSE)
cat("MarineSABRES SES Shiny Application - Installation Log\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("R Version:", R.version.string, "\n\n")
cat("Installed Packages:\n")
for (pkg in all_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(pkg, "-", as.character(packageVersion(pkg)), "\n")
  }
}
sink()

cat("Installation log saved to:", log_file, "\n")
cat("\n================================================================================\n")
cat("Installation Complete!\n")
cat("================================================================================\n")
