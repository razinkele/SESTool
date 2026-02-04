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
      validation_errors <- validate_project_structure(loaded_data)
      if (length(validation_errors) > 0) {
        error_msg <- paste(
          i18n$t("common.messages.error_invalid_proj_file_structure_this_may_not_be_"),
          paste(validation_errors, collapse = "; ")
        )
        showNotification(
          error_msg,
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

  # ========== LOCAL STORAGE SAVE/LOAD ==========
  
  # Handle "Save to Local" button click from sidebar
  observeEvent(input$save_to_local, {
    # Trigger local save via JavaScript message
    session$sendCustomMessage("trigger_local_save", list())
  })
  
  # Handle "Load from Local" button click from sidebar
  observeEvent(input$load_from_local, {
    # Show modal with list of local files to load
    showModal(modalDialog(
      title = tags$h3(icon("folder-open"), " ", i18n$t("ui.modals.load_from_local")),
      size = "m",
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.cancel")),
      
      tags$div(
        style = "padding: 15px;",
        
        # Check if connected to local directory
        uiOutput("local_files_list_ui"),
        
        # JavaScript to populate the file list
        tags$script(HTML("
          $(document).ready(function() {
            function populateLocalFilesList() {
              var container = $('#local_files_list_container');
              
              if (!window.localStorageModule || !window.localStorageModule.directoryHandle) {
                container.html(
                  '<div class=\"alert alert-warning\">' +
                  '<i class=\"fa fa-exclamation-triangle\"></i> ' +
                  'No local folder connected. Please go to Settings → Application Settings to connect a local folder first.' +
                  '</div>'
                );
                return;
              }
              
              // Get files from directory
              (async () => {
                try {
                  const handle = window.localStorageModule.directoryHandle;
                  const files = [];
                  
                  for await (const entry of handle.values()) {
                    if (entry.kind === 'file' && (entry.name.endsWith('.json') || entry.name.endsWith('.rds'))) {
                      const file = await entry.getFile();
                      files.push({
                        name: entry.name,
                        size: file.size,
                        lastModified: file.lastModified
                      });
                    }
                  }
                  
                  // Sort by last modified (newest first)
                  files.sort((a, b) => b.lastModified - a.lastModified);
                  
                  if (files.length === 0) {
                    container.html(
                      '<div class=\"alert alert-info\">' +
                      '<i class=\"fa fa-info-circle\"></i> ' +
                      'No saved projects found in the local folder.' +
                      '</div>'
                    );
                    return;
                  }
                  
                  // Build file list HTML
                  var html = '<div class=\"local-files-list\">';
                  files.forEach(function(file) {
                    var date = new Date(file.lastModified);
                    var sizeKB = Math.round(file.size / 1024);
                    html += '<div class=\"local-file-item\" data-filename=\"' + file.name + '\">';
                    html += '<div class=\"local-file-info\">';
                    html += '<div class=\"local-file-name\"><i class=\"fa fa-file\"></i> ' + file.name + '</div>';
                    html += '<div class=\"local-file-meta\">' + sizeKB + ' KB • ' + date.toLocaleString() + '</div>';
                    html += '</div>';
                    html += '<div class=\"local-file-actions\">';
                    html += '<button class=\"btn btn-sm btn-primary load-local-file\" data-filename=\"' + file.name + '\">';
                    html += '<i class=\"fa fa-upload\"></i> Load</button>';
                    html += '</div>';
                    html += '</div>';
                  });
                  html += '</div>';
                  
                  container.html(html);
                  
                  // Add click handlers for load buttons
                  $('.load-local-file').on('click', function() {
                    var filename = $(this).data('filename');
                    Shiny.setInputValue('local_file_to_load', {filename: filename, timestamp: Date.now()}, {priority: 'event'});
                  });
                  
                } catch (error) {
                  console.error('[LOCAL-STORAGE] Error listing files:', error);
                  container.html(
                    '<div class=\"alert alert-danger\">' +
                    '<i class=\"fa fa-exclamation-circle\"></i> ' +
                    'Error listing files: ' + error.message +
                    '</div>'
                  );
                }
              })();
            }
            
            // Run on modal open
            populateLocalFilesList();
          });
        "))
      ),
      
      tags$div(
        id = "local_files_list_container",
        style = "min-height: 100px;",
        tags$div(
          class = "text-center",
          style = "padding: 40px;",
          icon("spinner", class = "fa-spin fa-2x"),
          tags$p(style = "margin-top: 10px;", "Loading files...")
        )
      )
    ))
  })
  
  # Handle file selection from local files modal
  observeEvent(input$local_file_to_load, {
    req(input$local_file_to_load$filename)
    
    filename <- input$local_file_to_load$filename
    
    # Close the modal
    removeModal()
    
    # Trigger load via JavaScript
    session$sendCustomMessage("load_from_local_directory", list(filename = filename))
  })

}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# NOTE: sanitize_filename() is defined in global.R
# NOTE: validate_project_structure() now defined in functions/data_structure.R
# (removed duplicate definitions to avoid function name conflicts)
