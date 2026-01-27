# tests/shinytest2/setup.R
# Setup file for shinytest2 tests

# Load required packages
library(shinytest2)

# Set timeout for tests (60 seconds for operations)
options(shinytest2.timeout = 60000)

# Set load timeout (app startup can take >15s due to many packages)
options(shinytest2.load_timeout = 45000)  # 45 seconds for app to start

# Configure Chrome options for headless testing
chrome_options <- list(
  args = c(
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--window-size=1200,800"
  )
)

# Set default AppDriver options
options(shinytest2.chromote = chrome_options)
