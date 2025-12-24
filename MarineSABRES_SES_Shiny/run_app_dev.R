# run_app_dev.R
# Quick launcher for development - uses port 3839 to avoid conflicts with Shiny Server

cat("================================================================================\n")
cat("MarineSABRES SES Tool - Development Mode\n")
cat("================================================================================\n\n")

# Check if we're in the right directory
if (!file.exists("app.R")) {
  stop("Error: app.R not found. Please ensure you're in the MarineSABRES_SES_Shiny directory.")
}

# Read version info
version_info <- tryCatch({
  jsonlite::fromJSON("VERSION_INFO.json")
}, error = function(e) {
  list(version = "Unknown", version_name = "", status = "")
})

cat("Version:", version_info$version, "-", version_info$version_name, "\n")
cat("Port: 3839 (avoiding conflict with Shiny Server on 3838)\n")
cat("URL: http://localhost:3839\n\n")

cat("Launching application...\n")
cat("Press Ctrl+C or Cmd+C to stop\n\n")

# Launch on port 3839
shiny::runApp(port = 3839, launch.browser = TRUE, host = "0.0.0.0")
