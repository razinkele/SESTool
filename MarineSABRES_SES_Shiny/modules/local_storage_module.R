# modules/local_storage_module.R
# Local storage functionality for saving/loading projects to user's local computer
# Uses the File System Access API for modern browsers with download/upload fallback

# UI Component - Local Storage Controls
local_storage_ui <- function(id, i18n) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  # Build JavaScript using paste0 to avoid sprintf 8192 character limit
  js_code <- paste0('
      // SESSION-SCOPED state for local storage module
      // CRITICAL: Each session gets its own storage namespace to prevent cross-session interference
      // in multi-user shiny-server deployments

      // Initialize session-scoped storage namespace
      window._localStorageSessions = window._localStorageSessions || {};
      var _ls_session_id = null;

      // Get session-scoped module state
      function getLocalStorageModule() {
        if (!_ls_session_id) {
          console.warn("[LOCAL-STORAGE] Session ID not initialized, using temporary state");
          return {
            directoryHandle: null,
            hasFileSystemAccess: "showDirectoryPicker" in window,
            savedFiles: [],
            autoSaveEnabled: false
          };
        }
        if (!window._localStorageSessions[_ls_session_id]) {
          window._localStorageSessions[_ls_session_id] = {
            directoryHandle: null,
            hasFileSystemAccess: "showDirectoryPicker" in window,
            savedFiles: [],
            autoSaveEnabled: false
          };
        }
        return window._localStorageSessions[_ls_session_id];
      }

      // Initialize session ID for scoped state
      Shiny.addCustomMessageHandler("init_local_storage_session", function(message) {
        _ls_session_id = message.session_id;
        console.log("[LOCAL-STORAGE] Session initialized:", _ls_session_id);
        // Initialize state for this session
        getLocalStorageModule();
      });

      // Legacy compatibility: also expose as window.localStorageModule (points to current session)
      Object.defineProperty(window, "localStorageModule", {
        get: function() { return getLocalStorageModule(); }
      });

      // Check if File System Access API is available
      Shiny.addCustomMessageHandler("check_filesystem_api", function(message) {
        Shiny.setInputValue("', ns("filesystem_api_check"), '", getLocalStorageModule().hasFileSystemAccess, {priority: "event"});
      });

      // Request directory access from user
      Shiny.addCustomMessageHandler("request_directory_access", function(message) {
        var lsModule = getLocalStorageModule();
        if (!lsModule.hasFileSystemAccess) {
          Shiny.setInputValue("', ns("directory_access_result"), '", {success: false, error: "File System Access API not supported"}, {priority: "event"});
          return;
        }

        (async () => {
          try {
            const handle = await window.showDirectoryPicker({
              mode: "readwrite",
              startIn: "documents"
            });

            getLocalStorageModule().directoryHandle = handle;

            // Verify write permission
            const permissionStatus = await handle.queryPermission({mode: "readwrite"});
            if (permissionStatus !== "granted") {
              const requestResult = await handle.requestPermission({mode: "readwrite"});
              if (requestResult !== "granted") {
                throw new Error("Write permission denied");
              }
            }

            // Save handle to IndexedDB for persistence (handles cannot be stored in localStorage)
            await saveDirectoryHandle(handle);

            // List existing files
            const files = await listProjectFiles(handle);

            Shiny.setInputValue("', ns("directory_access_result"), '", {
              success: true,
              directoryName: handle.name,
              files: files
            }, {priority: "event"});

          } catch (error) {
            console.error("[LOCAL-STORAGE] Directory access error:", error);
            Shiny.setInputValue("', ns("directory_access_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Save project to local directory
      Shiny.addCustomMessageHandler("save_to_local_directory", function(message) {
        (async () => {
          try {
            const handle = getLocalStorageModule().directoryHandle;
            if (!handle) {
              throw new Error("No directory selected");
            }

            // Create or overwrite file
            const fileName = message.filename || "project_" + new Date().toISOString().replace(/[:.]/g, "-") + ".json";
            const fileHandle = await handle.getFileHandle(fileName, {create: true});
            const writable = await fileHandle.createWritable();
            await writable.write(message.data);
            await writable.close();

            console.log("[LOCAL-STORAGE] Saved to:", fileName);

            Shiny.setInputValue("', ns("save_result"), '", {
              success: true,
              filename: fileName,
              timestamp: new Date().toISOString()
            }, {priority: "event"});

          } catch (error) {
            console.error("[LOCAL-STORAGE] Save error:", error);
            Shiny.setInputValue("', ns("save_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Load project from local directory
      Shiny.addCustomMessageHandler("load_from_local_directory", function(message) {
        (async () => {
          try {
            const handle = getLocalStorageModule().directoryHandle;
            if (!handle) {
              throw new Error("No directory selected");
            }

            const fileHandle = await handle.getFileHandle(message.filename);
            const file = await fileHandle.getFile();
            const content = await file.text();

            console.log("[LOCAL-STORAGE] Loaded:", message.filename);

            Shiny.setInputValue("', ns("load_result"), '", {
              success: true,
              filename: message.filename,
              data: content
            }, {priority: "event"});

          } catch (error) {
            console.error("[LOCAL-STORAGE] Load error:", error);
            Shiny.setInputValue("', ns("load_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Delete project from local directory
      Shiny.addCustomMessageHandler("delete_from_local_directory", function(message) {
        (async () => {
          try {
            const handle = getLocalStorageModule().directoryHandle;
            if (!handle) {
              throw new Error("No directory selected");
            }

            await handle.removeEntry(message.filename);

            console.log("[LOCAL-STORAGE] Deleted:", message.filename);

            Shiny.setInputValue("', ns("delete_result"), '", {
              success: true,
              filename: message.filename
            }, {priority: "event"});

          } catch (error) {
            console.error("[LOCAL-STORAGE] Delete error:", error);
            Shiny.setInputValue("', ns("delete_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Refresh file list from local directory
      Shiny.addCustomMessageHandler("refresh_local_files", function(message) {
        (async () => {
          try {
            const handle = getLocalStorageModule().directoryHandle;
            if (!handle) {
              Shiny.setInputValue("', ns("refresh_result"), '", {success: false, files: []}, {priority: "event"});
              return;
            }

            const files = await listProjectFiles(handle);

            Shiny.setInputValue("', ns("refresh_result"), '", {
              success: true,
              files: files
            }, {priority: "event"});

          } catch (error) {
            console.error("[LOCAL-STORAGE] Refresh error:", error);
            Shiny.setInputValue("', ns("refresh_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Restore saved directory handle on page load
      Shiny.addCustomMessageHandler("restore_directory_handle", function(message) {
        (async () => {
          try {
            const handle = await getSavedDirectoryHandle();
            if (handle) {
              // Verify permission is still granted
              const permissionStatus = await handle.queryPermission({mode: "readwrite"});
              if (permissionStatus === "granted") {
                getLocalStorageModule().directoryHandle = handle;
                const files = await listProjectFiles(handle);

                Shiny.setInputValue("', ns("directory_access_result"), '", {
                  success: true,
                  directoryName: handle.name,
                  files: files,
                  restored: true
                }, {priority: "event"});
                return;
              }
            }
            Shiny.setInputValue("', ns("directory_access_result"), '", {success: false, noSavedHandle: true}, {priority: "event"});
          } catch (error) {
            console.error("[LOCAL-STORAGE] Restore error:", error);
            Shiny.setInputValue("', ns("directory_access_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Helper: List project files in directory
      async function listProjectFiles(handle) {
        const files = [];
        for await (const entry of handle.values()) {
          if (entry.kind === "file" && (entry.name.endsWith(".json") || entry.name.endsWith(".rds"))) {
            const file = await entry.getFile();
            files.push({
              name: entry.name,
              size: file.size,
              lastModified: file.lastModified,
              type: entry.name.endsWith(".json") ? "json" : "rds"
            });
          }
        }
        // Sort by last modified (newest first)
        files.sort((a, b) => b.lastModified - a.lastModified);
        return files;
      }

      // Helper: Save directory handle to IndexedDB
      async function saveDirectoryHandle(handle) {
        return new Promise((resolve, reject) => {
          const request = indexedDB.open("MarineSABRES_LocalStorage", 1);

          request.onupgradeneeded = (event) => {
            const db = event.target.result;
            if (!db.objectStoreNames.contains("handles")) {
              db.createObjectStore("handles", {keyPath: "id"});
            }
          };

          request.onsuccess = (event) => {
            const db = event.target.result;
            const tx = db.transaction("handles", "readwrite");
            const store = tx.objectStore("handles");
            store.put({id: "projectDirectory", handle: handle});
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
          };

          request.onerror = () => reject(request.error);
        });
      }

      // Helper: Get saved directory handle from IndexedDB
      async function getSavedDirectoryHandle() {
        return new Promise((resolve, reject) => {
          const request = indexedDB.open("MarineSABRES_LocalStorage", 1);

          request.onupgradeneeded = (event) => {
            const db = event.target.result;
            if (!db.objectStoreNames.contains("handles")) {
              db.createObjectStore("handles", {keyPath: "id"});
            }
          };

          request.onsuccess = (event) => {
            const db = event.target.result;
            const tx = db.transaction("handles", "readonly");
            const store = tx.objectStore("handles");
            const getRequest = store.get("projectDirectory");

            getRequest.onsuccess = () => {
              resolve(getRequest.result ? getRequest.result.handle : null);
            };
            getRequest.onerror = () => resolve(null);
          };

          request.onerror = () => resolve(null);
        });
      }

      // Clear saved directory handle
      Shiny.addCustomMessageHandler("clear_directory_handle", function(message) {
        (async () => {
          try {
            getLocalStorageModule().directoryHandle = null;

            const request = indexedDB.open("MarineSABRES_LocalStorage", 1);
            request.onsuccess = (event) => {
              const db = event.target.result;
              const tx = db.transaction("handles", "readwrite");
              const store = tx.objectStore("handles");
              store.delete("projectDirectory");
            };

            Shiny.setInputValue("', ns("clear_result"), '", {success: true}, {priority: "event"});
          } catch (error) {
            Shiny.setInputValue("', ns("clear_result"), '", {success: false, error: error.message}, {priority: "event"});
          }
        })();
      });

      // Trigger local save from settings modal (notify module to perform save)
      Shiny.addCustomMessageHandler("trigger_local_save", function(message) {
        Shiny.setInputValue("', ns("trigger_save"), '", Date.now(), {priority: "event"});
      });
      ')

  tagList(
    # JavaScript for File System Access API
    tags$script(HTML(js_code)),
    
    # CSS for local storage components
    tags$style(HTML("
      .local-storage-panel {
        padding: 15px;
        border-radius: 8px;
        background: #f8f9fa;
        margin-bottom: 15px;
      }
      
      .local-storage-panel.connected {
        background: #d4edda;
        border: 1px solid #c3e6cb;
      }
      
      .local-storage-panel.not-supported {
        background: #fff3cd;
        border: 1px solid #ffeaa7;
      }
      
      .local-files-list {
        max-height: 300px;
        overflow-y: auto;
        border: 1px solid #ddd;
        border-radius: 6px;
        background: white;
      }
      
      .local-file-item {
        padding: 10px 15px;
        border-bottom: 1px solid #eee;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .local-file-item:last-child {
        border-bottom: none;
      }
      
      .local-file-item:hover {
        background: #f0f7ff;
      }
      
      .local-file-info {
        flex: 1;
      }
      
      .local-file-name {
        font-weight: 600;
        color: #333;
      }
      
      .local-file-meta {
        font-size: 12px;
        color: #666;
      }
      
      .local-file-actions {
        display: flex;
        gap: 5px;
      }
      
      .directory-status {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 10px;
        background: #e8f4f8;
        border-radius: 6px;
        margin-bottom: 15px;
      }
      
      .directory-status.connected {
        background: #d4edda;
      }
      
      .directory-status-icon {
        font-size: 24px;
      }
      
      .fallback-warning {
        padding: 15px;
        background: #fff3cd;
        border: 1px solid #ffeaa7;
        border-radius: 8px;
        margin-bottom: 15px;
      }
    "))
  )
}

# Server Function
local_storage_server <- function(id, project_data_reactive, i18n, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values for local storage state
    local_state <- reactiveValues(
      has_api = FALSE,              # File System Access API available
      connected = FALSE,            # Directory selected and accessible
      directory_name = NULL,        # Name of selected directory
      files = list(),               # List of project files in directory
      last_save_time = NULL,        # Last save timestamp
      auto_save_enabled = FALSE     # Auto-save to local directory
    )

    # ========================================================================
    # SESSION-SCOPED INITIALIZATION
    # ========================================================================
    # CRITICAL: Send session ID to JavaScript for session-scoped state management
    # This prevents cross-session directory handle sharing in multi-user deployments
    session_id <- session$userData$session_id %||%
                  paste0("local_storage_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(1000:9999, 1))

    session$sendCustomMessage(
      type = "init_local_storage_session",
      message = list(session_id = session_id)
    )
    debug_log(sprintf("Initialized local storage with session ID: %s", session_id), "LOCAL-STORAGE")

    # Check File System API availability on startup
    observe({
      session$sendCustomMessage("check_filesystem_api", list())
    })
    
    observeEvent(input$filesystem_api_check, {
      local_state$has_api <- isTRUE(input$filesystem_api_check)
      debug_log(sprintf("File System Access API available: %s", local_state$has_api), "LOCAL-STORAGE")
      
      # Try to restore saved directory handle
      if (local_state$has_api) {
        session$sendCustomMessage("restore_directory_handle", list())
      }
    })
    
    # Handle directory access result
    observeEvent(input$directory_access_result, {
      result <- input$directory_access_result
      
      if (isTRUE(result$success)) {
        local_state$connected <- TRUE
        local_state$directory_name <- result$directoryName
        local_state$files <- result$files %||% list()
        
        if (isTRUE(result$restored)) {
          showNotification(
            sprintf(i18n$t("common.messages.local_directory_restored"), result$directoryName),
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            sprintf(i18n$t("common.messages.local_directory_connected"), result$directoryName),
            type = "message",
            duration = 3
          )
        }
        
        debug_log(sprintf("Connected to local directory: %s (%d files)", 
                   result$directoryName, length(result$files)), "LOCAL-STORAGE")
        
      } else if (!isTRUE(result$noSavedHandle)) {
        local_state$connected <- FALSE
        local_state$directory_name <- NULL
        local_state$files <- list()
        
        if (!is.null(result$error)) {
          showNotification(
            paste(i18n$t("common.messages.directory_access_failed"), result$error),
            type = "error",
            duration = 5
          )
        }
      }
    })
    
    # Handle save result
    observeEvent(input$save_result, {
      result <- input$save_result
      
      if (isTRUE(result$success)) {
        local_state$last_save_time <- Sys.time()
        
        showNotification(
          sprintf(i18n$t("common.messages.saved_to_local_file"), result$filename),
          type = "message",
          duration = 3
        )
        
        # Refresh file list
        session$sendCustomMessage("refresh_local_files", list())
        
      } else {
        showNotification(
          paste(i18n$t("common.messages.local_save_failed"), result$error),
          type = "error",
          duration = 5
        )
      }
    })
    
    # Handle load result
    observeEvent(input$load_result, {
      result <- input$load_result
      
      if (isTRUE(result$success)) {
        tryCatch({
          # Parse JSON data safely
          loaded_data <- safe_parse_json(result$data)

          if (is.null(loaded_data)) {
            showNotification(
              i18n$t("common.messages.error_parsing_file"),
              type = "error",
              duration = 5
            )
            return()
          }

          # Validate and load
          project_data_reactive(loaded_data)

          showNotification(
            sprintf(i18n$t("common.messages.loaded_from_local_file"), result$filename),
            type = "message",
            duration = 3
          )
          
          # Emit event if bus available
          if (!is.null(event_bus)) {
            event_bus$emit_isa_change("local_storage")
          }
          
        }, error = function(e) {
          showNotification(
            format_user_error(e, i18n = i18n, context = "parsing project file", show_details = TRUE),
            type = "error",
            duration = 5
          )
        })
        
      } else {
        showNotification(
          paste(i18n$t("common.messages.local_load_failed"), result$error),
          type = "error",
          duration = 5
        )
      }
    })
    
    # Handle delete result
    observeEvent(input$delete_result, {
      result <- input$delete_result
      
      if (isTRUE(result$success)) {
        showNotification(
          sprintf(i18n$t("common.messages.deleted_local_file"), result$filename),
          type = "warning",
          duration = 3
        )
        
        # Refresh file list
        session$sendCustomMessage("refresh_local_files", list())
        
      } else {
        showNotification(
          paste(i18n$t("common.messages.local_delete_failed"), result$error),
          type = "error",
          duration = 5
        )
      }
    })
    
    # Handle refresh result
    observeEvent(input$refresh_result, {
      result <- input$refresh_result
      
      if (isTRUE(result$success)) {
        local_state$files <- result$files %||% list()
      }
    })
    
    # Handle clear result
    observeEvent(input$clear_result, {
      result <- input$clear_result
      
      if (isTRUE(result$success)) {
        local_state$connected <- FALSE
        local_state$directory_name <- NULL
        local_state$files <- list()
        
        showNotification(
          i18n$t("common.messages.local_directory_disconnected"),
          type = "message",
          duration = 3
        )
      }
    })
    
    # Handle trigger save from settings modal
    observeEvent(input$trigger_save, {
      # Call the save_project function
      if (local_state$connected) {
        data <- project_data_reactive()
        if (!is.null(data)) {
          # Generate filename
          project_name <- data$project_id %||% "project"
          project_name <- gsub("[^a-zA-Z0-9_-]", "_", project_name)
          filename <- sprintf("%s_%s.json", project_name, format(Sys.time(), "%Y%m%d_%H%M%S"))
          
          # Convert to JSON
          json_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null", pretty = TRUE)
          
          session$sendCustomMessage("save_to_local_directory", list(
            filename = filename,
            data = as.character(json_data)
          ))
        } else {
          showNotification(
            i18n$t("common.messages.no_data_to_save"),
            type = "warning",
            duration = 3
          )
        }
      } else {
        showNotification(
          i18n$t("common.messages.no_local_directory_selected"),
          type = "warning",
          duration = 3
        )
      }
    })
    
    # Return control functions for use by other modules
    list(
      # Check if local storage is connected
      is_connected = reactive({ local_state$connected }),
      
      # Get directory name
      get_directory_name = reactive({ local_state$directory_name }),
      
      # Get list of files
      get_files = reactive({ local_state$files }),
      
      # Has File System Access API
      has_api = reactive({ local_state$has_api }),
      
      # Request directory access
      request_access = function() {
        session$sendCustomMessage("request_directory_access", list())
      },
      
      # Save project to local directory
      save_project = function(filename = NULL) {
        if (!local_state$connected) {
          showNotification(
            i18n$t("common.messages.no_local_directory_selected"),
            type = "warning",
            duration = 3
          )
          return(FALSE)
        }
        
        data <- project_data_reactive()
        if (is.null(data)) {
          showNotification(
            i18n$t("common.messages.no_data_to_save"),
            type = "warning",
            duration = 3
          )
          return(FALSE)
        }
        
        # Generate filename if not provided
        if (is.null(filename)) {
          project_name <- data$project_id %||% "project"
          project_name <- gsub("[^a-zA-Z0-9_-]", "_", project_name)
          filename <- sprintf("%s_%s.json", project_name, format(Sys.time(), "%Y%m%d_%H%M%S"))
        }
        
        # Convert to JSON
        json_data <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null", pretty = TRUE)
        
        session$sendCustomMessage("save_to_local_directory", list(
          filename = filename,
          data = as.character(json_data)
        ))
        
        return(TRUE)
      },
      
      # Load project from local directory
      load_project = function(filename) {
        if (!local_state$connected) {
          showNotification(
            i18n$t("common.messages.no_local_directory_selected"),
            type = "warning",
            duration = 3
          )
          return(FALSE)
        }
        
        session$sendCustomMessage("load_from_local_directory", list(
          filename = filename
        ))
        
        return(TRUE)
      },
      
      # Delete project from local directory
      delete_project = function(filename) {
        if (!local_state$connected) {
          return(FALSE)
        }
        
        session$sendCustomMessage("delete_from_local_directory", list(
          filename = filename
        ))
        
        return(TRUE)
      },
      
      # Disconnect from local directory
      disconnect = function() {
        session$sendCustomMessage("clear_directory_handle", list())
      },
      
      # Refresh file list
      refresh_files = function() {
        session$sendCustomMessage("refresh_local_files", list())
      }
    )
  })
}


#' Create Local Storage Settings UI
#' 
#' Creates the UI for local storage settings in the settings modal
#' 
#' @param id Module namespace ID
#' @param i18n Translation object
#' @param is_connected Reactive indicating if connected to local directory
#' @param directory_name Reactive containing directory name
#' @param has_api Reactive indicating if File System Access API is available
#' @return Shiny UI elements
local_storage_settings_ui <- function(id, i18n, is_connected, directory_name, has_api) {
  ns <- NS(id)
  tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)  # Enable reactive translation updates

  tagList(
    tags$h4(icon("folder-open"), " ", i18n$t("ui.modals.local_storage_settings")),
    
    tags$p(
      style = "color: #666; margin-bottom: 15px;",
      i18n$t("ui.modals.local_storage_description")
    ),
    
    # API not supported warning
    conditionalPanel(
      condition = sprintf("!window.localStorageModule.hasFileSystemAccess"),
      tags$div(
        class = "fallback-warning",
        icon("exclamation-triangle"),
        tags$strong(" ", i18n$t("ui.modals.local_storage_not_supported_title")),
        tags$p(
          style = "margin: 10px 0 0 0;",
          i18n$t("ui.modals.local_storage_not_supported_message")
        ),
        tags$p(
          style = "margin: 5px 0 0 0; font-size: 12px;",
          i18n$t("ui.modals.local_storage_fallback_message")
        )
      )
    ),
    
    # API supported - show connection status and controls
    conditionalPanel(
      condition = sprintf("window.localStorageModule.hasFileSystemAccess"),
      
      # Connection status
      uiOutput(ns("connection_status")),
      
      # Connect/Disconnect button
      uiOutput(ns("connection_button")),
      
      # File list when connected
      uiOutput(ns("file_list"))
    )
  )
}
