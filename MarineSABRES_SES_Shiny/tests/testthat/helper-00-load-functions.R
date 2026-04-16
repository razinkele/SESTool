# tests/testthat/helper-00-load-functions.R
# Load real functions BEFORE helper-stubs.R (alphabetically first)
# This ensures stubs don't override real implementations

# Ensure user library is on the search path (packages like shinyFiles live here)
user_lib <- Sys.getenv("R_LIBS_USER")
if (nzchar(user_lib) && dir.exists(user_lib)) {
  .libPaths(c(user_lib, .libPaths()))
}

# Determine project root
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

# Store current directory
old_wd <- getwd()

# Change to project root for sourcing
setwd(project_root)

# Load global.R (this loads most functions)
tryCatch({
  if (file.exists("global.R")) {
    source("global.R", local = FALSE)
  }
}, error = function(e) {
  message("Warning: Could not load global.R: ", e$message)
})

# Load DAPSIWRM connection rules explicitly
tryCatch({
  if (file.exists("functions/dapsiwrm_connection_rules.R")) {
    source("functions/dapsiwrm_connection_rules.R", local = FALSE)
  }
}, error = function(e) {
  message("Warning: Could not load dapsiwrm_connection_rules.R")
})

# Load graphical SES AI classifier
tryCatch({
  if (file.exists("modules/graphical_ses_ai_classifier.R")) {
    source("modules/graphical_ses_ai_classifier.R", local = FALSE)
  }
}, error = function(e) {
  message("Warning: Could not load graphical_ses_ai_classifier.R")
})

# Restore working directory
setwd(old_wd)
