# server/project_io.R
# Project save/load handlers for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# PROJECT SAVE/LOAD HANDLERS
# ============================================================================

#' Setup Project Save/Load Handlers
#'
#' Sets up handlers for saving and loading project files (.rds format)
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param project_data reactiveVal containing project data
#' @param i18n shiny.i18n translator object
setup_project_io_handlers <- function(input, output, session, project_data, i18n) {

  # ========== SAVE PROJECT ==========

  observeEvent(input$save_project, {
    showModal(modalDialog(
      title = "Save Project",
      textInput("save_project_name", "Project Name:",
               value = project_data()$project_id),
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        downloadButton("confirm_save", "Save")
      )
    ))
  })

  output$confirm_save <- downloadHandler(
    filename = function() {
      # Sanitize filename to prevent path traversal
      safe_name <- sanitize_filename(input$save_project_name)
      paste0(safe_name, "_", Sys.Date(), ".rds")
    },
    content = function(file) {
      tryCatch({
        # Validate data structure before saving
        data <- project_data()
        if (!is.list(data) || !all(c("project_id", "data") %in% names(data))) {
          showNotification(i18n$t("common.messages.error_invalid_project_data_structure"),
                          type = "error", duration = 10)
          return(NULL)
        }

        # Save with error handling
        saveRDS(data, file)

        # Verify saved file
        if (!file.exists(file) || file.size(file) == 0) {
          showNotification(i18n$t("common.messages.error_file_save_failed_or_file_is_empty"),
                          type = "error", duration = 10)
          return(NULL)
        }

        removeModal()
        showNotification(i18n$t("common.messages.project_saved_successfully"), type = "message")

      }, error = function(e) {
        showNotification(
          paste(i18n$t("common.misc.error_saving_project"), e$message),
          type = "error",
          duration = 10
        )
      })
    }
  )

  # ========== LOAD PROJECT ==========

  observeEvent(input$load_project, {
    showModal(modalDialog(
      title = i18n$t("common.buttons.load_project"),
      fileInput("load_project_file", i18n$t("common.misc.choose_rds_file"),
               accept = ".rds"),
      footer = tagList(
        modalButton(i18n$t("common.buttons.cancel")),
        actionButton("confirm_load", i18n$t("common.buttons.load"))
      )
    ))
  })

  observeEvent(input$confirm_load, {
    req(input$load_project_file)

    tryCatch({
      # Load RDS file
      loaded_data <- readRDS(input$load_project_file$datapath)

      # Validate project structure
      if (!validate_project_structure(loaded_data)) {
        showNotification(
          i18n$t("common.messages.error_invalid_proj_file_structure_this_may_not_be_"),
          type = "error",
          duration = 10
        )
        return()
      }

      # Load validated data
      project_data(loaded_data)

      removeModal()
      showNotification(i18n$t("common.messages.project_loaded_successfully"), type = "message")

    }, error = function(e) {
      showNotification(
        paste(i18n$t("common.misc.error_loading_project"), e$message),
        type = "error",
        duration = 10
      )
    })
  })

}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Sanitize filename to prevent path traversal
#'
#' @param filename Character string to sanitize
#' @return Sanitized filename safe for filesystem
sanitize_filename <- function(filename) {
  # Remove any path separators and special characters
  safe <- gsub("[/\\\\:*?\"<>|]", "_", filename)
  # Remove leading/trailing whitespace and dots
  safe <- trimws(safe)
  safe <- gsub("^\\.*|\\.*$", "", safe)
  # Ensure non-empty
  if (nchar(safe) == 0) safe <- "project"
  safe
}

#' Validate project structure
#'
#' @param data Project data list
#' @return Logical TRUE if valid, FALSE otherwise
validate_project_structure <- function(data) {
  if (is.null(data) || !is.list(data)) return(FALSE)

  required_fields <- c("project_id", "project_name", "data")
  if (!all(required_fields %in% names(data))) return(FALSE)

  TRUE
}
