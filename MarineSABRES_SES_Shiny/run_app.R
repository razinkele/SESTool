# run_app.R
# Quick launcher script for MarineSABRES SES Shiny Application

cat("================================================================================\n")
cat("MarineSABRES Social-Ecological Systems Analysis Tool\n")
cat("================================================================================\n\n")

# Check if we're in the right directory
if (!file.exists("app.R")) {
  stop("Error: app.R not found. Please ensure you're in the MarineSABRES_SES_Shiny directory.")
}

if (!file.exists("global.R")) {
  stop("Error: global.R not found. Please ensure all files are present.")
}

# Check for required packages
cat("Checking required packages...\n")
required_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "shinyjs",
  "tidyverse", "DT", "igraph", "visNetwork"
)

missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  cat("\n⚠ WARNING: Missing required packages:\n")
  for (pkg in missing_packages) {
    cat("  - ", pkg, "\n")
  }
  cat("\nWould you like to install missing packages? (y/n): ")
  response <- readline()
  
  if (tolower(response) == "y") {
    cat("\nInstalling packages...\n")
    source("install_packages.R")
  } else {
    stop("Cannot run application without required packages.")
  }
}

cat("✓ All required packages are available\n\n")

# Display application info
cat("Application Information:\n")
cat("  Version: 1.0.0\n")
cat("  R Version:", R.version.string, "\n")
cat("  Working Directory:", getwd(), "\n\n")

# Launch options
cat("Launch Options:\n")
cat("  1. Default (opens in browser)\n")
cat("  2. Specify port\n")
cat("  3. Display mode (fullscreen)\n")
cat("  4. Cancel\n\n")

cat("Select option (1-4): ")
option <- readline()

if (option == "1") {
  cat("\nLaunching application in default browser...\n")
  cat("Press Ctrl+C or Cmd+C to stop the application\n\n")
  shiny::runApp(launch.browser = TRUE)
  
} else if (option == "2") {
  cat("Enter port number (e.g., 3838): ")
  port <- as.integer(readline())
  
  if (is.na(port) || port < 1024 || port > 65535) {
    cat("Invalid port number. Using default port.\n")
    shiny::runApp(launch.browser = TRUE)
  } else {
    cat(paste0("\nLaunching application on port ", port, "...\n"))
    cat("Access at: http://localhost:", port, "\n")
    cat("Press Ctrl+C or Cmd+C to stop the application\n\n")
    shiny::runApp(port = port, launch.browser = TRUE)
  }
  
} else if (option == "3") {
  cat("\nLaunching application in display mode...\n")
  cat("Press Ctrl+C or Cmd+C to stop the application\n\n")
  shiny::runApp(launch.browser = TRUE, display.mode = "showcase")
  
} else {
  cat("Launch cancelled.\n")
  cat("\nTo launch manually, use: shiny::runApp()\n")
}

# Error handling
tryCatch({
  # Application runs in above code
}, error = function(e) {
  cat("\n\n================================================================================\n")
  cat("ERROR: Application failed to start\n")
  cat("================================================================================\n\n")
  cat("Error message:", e$message, "\n\n")
  cat("Troubleshooting:\n")
  cat("  1. Check that all files are present\n")
  cat("  2. Verify package installations: source('install_packages.R')\n")
  cat("  3. Check R version (requires 4.0.0+): R.version.string\n")
  cat("  4. Review error message above for specific issues\n")
  cat("  5. See docs/INSTALLATION.md for detailed help\n\n")
}, interrupt = function(e) {
  cat("\n\nApplication stopped by user.\n")
})
