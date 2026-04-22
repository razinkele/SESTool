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

# ===========================================================================
# Helper: source_for_test()
# ---------------------------------------------------------------------------
# Sources one or more project files into .GlobalEnv, using an absolute path
# derived from the current working directory (handles both "testthat" cwd
# when run via test_file() and project-root cwd when run via other entry
# points). Silently skips missing files and logs any source errors without
# failing the entire test file.
#
# Used by module/feature test files whose targets are NOT in global.R's
# auto-load chain (e.g., modules/*.R, server/event_bus_setup.R,
# functions/reactive_pipeline.R).
#
# Example:
#   source_for_test(c(
#     "modules/entry_point_module.R",
#     "server/event_bus_setup.R"
#   ))
# ===========================================================================
source_for_test <- function(relative_paths) {
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  for (rel in relative_paths) {
    full <- file.path(root, rel)
    if (file.exists(full)) {
      tryCatch(
        sys.source(full, envir = .GlobalEnv),
        error = function(e) message("source_for_test: could not source ", rel, ": ", e$message)
      )
    }
  }
  invisible(NULL)
}
