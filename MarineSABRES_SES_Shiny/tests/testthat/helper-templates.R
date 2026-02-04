# tests/testthat/helper-templates.R
# Load SES templates for integration tests
# This file is automatically loaded by testthat before running tests

# Determine project root
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

#' Get test templates - loads templates on demand if not already loaded
#' This function ensures templates are available in any test environment
#' @return List of SES templates
get_test_templates <- function() {
  # Check if templates already loaded in calling environment
  calling_env <- parent.frame()

  if (exists("ses_templates", envir = calling_env, inherits = FALSE)) {
    templates <- get("ses_templates", envir = calling_env)
    if (length(templates) > 0) {
      return(templates)
    }
  }

  # Check global environment
  if (exists("ses_templates", envir = .GlobalEnv, inherits = FALSE)) {
    templates <- get("ses_templates", envir = .GlobalEnv)
    if (length(templates) > 0) {
      # Also assign to calling environment for future use
      assign("ses_templates", templates, envir = calling_env)
      return(templates)
    }
  }

  # Templates not loaded - load them now
  template_loader_path <- file.path(project_root, "functions/template_loader.R")
  if (file.exists(template_loader_path)) {
    source(template_loader_path, local = FALSE)

    old_wd <- getwd()
    setwd(project_root)
    templates <- load_all_templates("data")
    setwd(old_wd)

    # Assign to both environments
    assign("ses_templates", templates, envir = .GlobalEnv)
    assign("ses_templates", templates, envir = calling_env)

    if (length(templates) > 0) {
      message("Loaded ", length(templates), " templates on demand")
    }

    return(templates)
  }

  # Could not load - return empty list
  return(list())
}

# Try to preload templates at helper load time
template_loader_path <- file.path(project_root, "functions/template_loader.R")
if (file.exists(template_loader_path)) {
  tryCatch({
    source(template_loader_path, local = FALSE)

    old_wd <- getwd()
    setwd(project_root)
    templates_loaded <- load_all_templates("data")
    setwd(old_wd)

    # Assign to global environment
    assign("ses_templates", templates_loaded, envir = .GlobalEnv)
    ses_templates <<- templates_loaded

    if (length(templates_loaded) > 0) {
      message("Test helper preloaded ", length(templates_loaded),
              " SES templates: ", paste(names(templates_loaded), collapse = ", "))
    }
  }, error = function(e) {
    message("Warning: Could not preload SES templates: ", e$message)
    assign("ses_templates", list(), envir = .GlobalEnv)
  })
}
