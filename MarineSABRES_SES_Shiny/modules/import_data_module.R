# modules/import_data_module.R
# Import Data Module
# Purpose: Import Excel files with Elements (nodes) and Connections (edges) sheets

# Libraries loaded in global.R: shiny, shinyjs, readxl

# Source the tabbed connection review module (organized by DAPSI(W)R(M) stages)
source("modules/connection_review_tabbed.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

import_data_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),

    # Custom CSS (using constants from constants.R)
    tags$head(
      tags$style(HTML(sprintf("
        .import-container {
          padding: 20px;
          background: white;
          border-radius: 10px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin: 20px 0;
        }
        .import-header {
          background: linear-gradient(135deg, %s 0%%, %s 100%%);
          color: white;
          padding: 20px;
          border-radius: 10px;
          margin-bottom: 20px;
        }
        .import-instructions {
          background: #f0f7ff;
          border-left: 4px solid #2196f3;
          padding: 15px;
          margin: 15px 0;
          border-radius: 5px;
        }
        .file-format-box {
          background: #fff3cd;
          border: 1px solid #ffc107;
          padding: 15px;
          border-radius: 5px;
          margin: 15px 0;
        }
        .preview-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          padding: 15px;
          border-radius: 5px;
          margin-top: 20px;
          max-height: %s;
          overflow-y: auto;
        }
      ", IMPORT_MODULE_COLORS$gradient_start,
         IMPORT_MODULE_COLORS$gradient_end,
         UI_BOX_HEIGHT_DEFAULT)))
    ),

    # Header
    uiOutput(ns("module_header")),

    # Instructions
    div(class = "import-container",
      div(class = "import-instructions",
        h4(icon("info-circle"), " ", i18n$t("common.misc.required_excel_format")),
        tags$ul(
          tags$li(strong(i18n$t("common.misc.two_sheets_required")),
                  tags$ul(
                    tags$li(strong("Elements"), " - Contains all nodes/elements in your SES"),
                    tags$li(strong("Connections"), " - Contains all relationships/edges between elements")
                  )),
          tags$li(strong(i18n$t("common.misc.elements_sheet_columns")),
                  tags$ul(
                    tags$li(code("Label"), " - Name of the element (required)"),
                    tags$li(code("type"), " - Element type: Driver, Activity, Pressure, Marine Process and Function, Ecosystem Service, Good and Benefit, Response, or Measure (required)")
                  )),
          tags$li(strong(i18n$t("common.misc.connections_sheet_columns")),
                  tags$ul(
                    tags$li(code("From"), " - Source element label (required)"),
                    tags$li(code("To"), " - Target element label (required)"),
                    tags$li(code("Label"), " - Connection polarity: + or - (required)"),
                    tags$li(code("Strength"), " - Optional: Weak/Medium/Strong"),
                    tags$li(code("Confidence"), " - Optional: 1-5 scale")
                  ))
        )
      ),

      # File upload
      fluidRow(
        column(6,
          fileInput(ns("excel_file"),
                    "Choose Excel File (.xlsx)",
                    accept = c(".xlsx", ".xls"),
                    buttonLabel = "Browse...",
                    placeholder = "No file selected")
        ),
        column(6,
          br(),
          actionButton(ns("load_sample"),
                      "Load Sample (TuscanySES)",
                      icon = icon("upload"),
                      class = "btn-info",
                      style = "margin-top: 25px;")
        )
      ),

      # Status messages
      uiOutput(ns("import_status")),

      # Connection review panel (shown after data validation)
      uiOutput(ns("review_panel"))
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

import_data_server <- function(id, project_data_reactive, i18n, parent_session = NULL, event_bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      elements_data = NULL,
      connections_data = NULL,
      file_loaded = FALSE,
      validation_errors = NULL,
      import_success = FALSE,
      show_review = FALSE,
      parsed_connections = NULL
    )

    # === REACTIVE MODULE HEADER ===
    create_reactive_header(
      output = output,
      ns = session$ns,
      title_key = "modules.import.data.title",
      subtitle_key = "modules.import.data.subtitle",
      help_id = "import_data_help",
      i18n = i18n
    )

    # Load sample file
    observeEvent(input$load_sample, {
      sample_file <- "data/TuscanySES.xlsx"

      tryCatch({
        if (file.exists(sample_file)) {
          rv$elements_data <- readxl::read_excel(sample_file, sheet = "Elements")
          rv$connections_data <- readxl::read_excel(sample_file, sheet = "Connections")
          rv$file_loaded <- TRUE
          rv$validation_errors <- validate_import_data(rv$elements_data, rv$connections_data)

          showNotification(
            "Sample file loaded successfully!",
            type = "message",
            duration = 3
          )
        } else {
          showNotification(
            paste("Sample file not found at:", sample_file),
            type = "error",
            duration = 5
          )
        }
      }, error = function(e) {
        showNotification(
          paste("Error loading sample file:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Handle file upload
    observeEvent(input$excel_file, {
      req(input$excel_file)

      tryCatch({
        file_path <- input$excel_file$datapath
        file_name <- input$excel_file$name
        file_size <- input$excel_file$size

        # === VALIDATION 1: File extension check ===
        if (!grepl("\\.(xlsx|xls)$", tolower(file_name))) {
          showNotification(
            i18n$t("common.messages.invalid_file_type_please_upload_xlsx_or_xls"),
            type = "error",
            duration = 10
          )
          return(NULL)
        }

        # Validate MIME type (prevents renamed files from being processed)
        file_info <- input$excel_file
        expected_mimes <- c(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel",
          "application/octet-stream"  # Some browsers report this for xlsx
        )
        if (!is.null(file_info$type) && nchar(file_info$type) > 0 &&
            !file_info$type %in% expected_mimes) {
          showNotification(
            paste("Invalid file type detected:", file_info$type,
                  "- Expected an Excel file (.xlsx or .xls)"),
            type = "error", duration = 8
          )
          return()
        }

        # === VALIDATION 2: File size check (max 50MB) ===
        max_size_mb <- 50
        if (file_size > max_size_mb * 1024 * 1024) {
          showNotification(
            paste(i18n$t("common.messages.file_too_large_maximum_size_is"), max_size_mb, "MB"),
            type = "error",
            duration = 10
          )
          return(NULL)
        }

        # === VALIDATION 3: File exists and readable ===
        if (!file.exists(file_path)) {
          showNotification(
            i18n$t("common.messages.uploaded_file_not_found"),
            type = "error",
            duration = 10
          )
          return(NULL)
        }

        # === VALIDATION 4: Check sheets ===
        sheets <- tryCatch({
          readxl::excel_sheets(file_path)
        }, error = function(e) {
          showNotification(
            paste(i18n$t("common.messages.cannot_read_excel_file"), e$message),
            type = "error",
            duration = 10
          )
          return(NULL)
        })

        if (is.null(sheets)) return(NULL)

        if (!("Elements" %in% sheets) || !("Connections" %in% sheets)) {
          showNotification(
            "Error: Excel file must contain 'Elements' and 'Connections' sheets!",
            type = "error",
            duration = 10
          )
          return(NULL)
        }

        # Read sheets
        rv$elements_data <- readxl::read_excel(file_path, sheet = "Elements")
        rv$connections_data <- readxl::read_excel(file_path, sheet = "Connections")
        rv$file_loaded <- TRUE

        # Validate data
        rv$validation_errors <- validate_import_data(rv$elements_data, rv$connections_data)

        showNotification(
          "File uploaded successfully!",
          type = "message",
          duration = 3
        )

      }, error = function(e) {
        showNotification(
          paste("Error reading Excel file:", e$message),
          type = "error",
          duration = 10
        )
        rv$file_loaded <- FALSE
      })
    })

    # Status output
    output$import_status <- renderUI({
      if (!rv$file_loaded) return(NULL)
      if (rv$show_review) return(NULL)  # Hide when showing review panel

      if (!is.null(rv$validation_errors) && length(rv$validation_errors) > 0) {
        tagList(
          div(class = "alert alert-warning",
            icon("exclamation-triangle"), " ", strong("Validation Warnings:"),
            tags$ul(
              lapply(rv$validation_errors, function(err) tags$li(err))
            )
          ),
          br(),
          div(align = "center",
            actionButton(ns("review_btn"),
                        "Review Connections",
                        icon = icon("search"),
                        class = "btn-warning btn-lg",
                        style = "font-size: 18px; padding: 15px 30px;")
          )
        )
      } else {
        tagList(
          div(class = "alert alert-success",
            icon("check-circle"), " ",
            strong("Data validated successfully!"),
            br(),
            sprintf("Found %d elements and %d connections",
                    nrow(rv$elements_data),
                    nrow(rv$connections_data))
          ),
          br(),
          div(align = "center",
            actionButton(ns("review_btn"),
                        "Review Connections",
                        icon = icon("search"),
                        class = "btn-primary btn-lg",
                        style = "font-size: 18px; padding: 15px 30px; margin-right: 10px;"),
            actionButton(ns("import_direct_btn"),
                        "Import Without Review",
                        icon = icon("fast-forward"),
                        class = "btn-success btn-lg",
                        style = "font-size: 18px; padding: 15px 30px;")
          )
        )
      }
    })

    # Review panel (shown when user clicks review)
    output$review_panel <- renderUI({
      if (!rv$show_review) return(NULL)

      tagList(
        hr(),
        div(class = "import-container",
          h3(icon("check-square"), " Review Imported Connections"),
          p("Review and optionally edit the connections before importing. Connections are organized by DAPSI(W)R(M) stages for easier review."),

          connection_review_tabbed_ui(ns("conn_review"), i18n),

          br(),
          div(align = "center",
            actionButton(ns("finalize_import_btn"),
                        "Finalize Import",
                        icon = icon("check-circle"),
                        class = "btn-success btn-lg",
                        style = "font-size: 18px; padding: 15px 30px; margin-right: 10px;"),
            actionButton(ns("cancel_review_btn"),
                        "Cancel",
                        icon = icon("times"),
                        class = "btn-secondary btn-lg",
                        style = "font-size: 18px; padding: 15px 30px;")
          )
        )
      )
    })

    # Review button - parse connections and show review panel
    observeEvent(input$review_btn, {
      req(rv$file_loaded)

      tryCatch({
        # Parse connections into review format
        rv$parsed_connections <- parse_connections_for_review(rv$elements_data, rv$connections_data)
        rv$show_review <- TRUE

      }, error = function(e) {
        showNotification(
          paste("Error parsing connections:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Connection review module (tabbed by DAPSI(W)R(M) stages)
    review_status <- connection_review_tabbed_server(
      "conn_review",
      connections_reactive = reactive({ rv$parsed_connections }),
      i18n = i18n,
      on_approve = function(approved_idx) {
        debug_log(paste("Approved connections:", paste(approved_idx, collapse = ", ")), "IMPORT")
      },
      on_reject = function(rejected_idx) {
        debug_log(paste("Rejected connections:", paste(rejected_idx, collapse = ", ")), "IMPORT")
      }
    )

    # Cancel review button
    observeEvent(input$cancel_review_btn, {
      rv$show_review <- FALSE
      rv$parsed_connections <- NULL
    })

    # Finalize import after review
    observeEvent(input$finalize_import_btn, {
      req(rv$file_loaded, rv$parsed_connections)

      tryCatch({
        # Get review status
        status <- review_status()
        approved <- status$approved
        rejected <- status$rejected

        # Filter connections based on review
        if (length(rejected) > 0) {
          # Create filtered connections dataframe
          connections_to_import <- rv$connections_data[-rejected, ]
        } else {
          connections_to_import <- rv$connections_data
        }

        debug_log(sprintf("Importing %d of %d connections (rejected: %d)",
                    nrow(connections_to_import), nrow(rv$connections_data), length(rejected)), "IMPORT")

        # Verify shared function is available
        if (!exists("convert_excel_to_isa", mode = "function")) {
          stop("convert_excel_to_isa function not available. Ensure excel_import_helpers.R is sourced.")
        }

        # Convert to ISA structure (uses connection-first approach from excel_import_helpers.R)
        isa_data <- convert_excel_to_isa(rv$elements_data, connections_to_import)

        # Perform import
        perform_import(isa_data, nrow(rv$elements_data), nrow(connections_to_import))

      }, error = function(e) {
        showNotification(
          paste("Error importing data:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Direct import button (skip review)
    observeEvent(input$import_direct_btn, {
      req(rv$file_loaded)

      tryCatch({
        # Verify shared function is available
        if (!exists("convert_excel_to_isa", mode = "function")) {
          stop("convert_excel_to_isa function not available. Ensure excel_import_helpers.R is sourced.")
        }

        # Convert to ISA structure (uses connection-first approach from excel_import_helpers.R)
        isa_data <- convert_excel_to_isa(rv$elements_data, rv$connections_data)

        # Perform import
        perform_import(isa_data, nrow(rv$elements_data), nrow(rv$connections_data))

      }, error = function(e) {
        showNotification(
          paste("Error importing data:", e$message),
          type = "error",
          duration = 10
        )
      })
    })

    # Helper function to perform the actual import
    perform_import <- function(isa_data, num_elements, num_connections) {
      # Debug: Print adjacency matrices info
      debug_log("Adjacency matrices created", "IMPORT")
      debug_log(paste("Matrix names:", paste(names(isa_data$adjacency_matrices), collapse = ", ")), "IMPORT")
      total_matrix_connections <- 0
      for (matrix_name in names(isa_data$adjacency_matrices)) {
        mat <- isa_data$adjacency_matrices[[matrix_name]]
        non_empty <- sum(mat != "")
        total_matrix_connections <- total_matrix_connections + non_empty
        debug_log(sprintf("%s: %d connections", matrix_name, non_empty), "IMPORT")
      }
      debug_log(sprintf("Total connections in all matrices: %d", total_matrix_connections), "IMPORT")

      # Get current project data
      project_data <- project_data_reactive()

      # Update ISA data
      project_data$data$isa_data <- isa_data

      # Generate CLD from imported ISA data
      debug_log("Generating CLD from imported data", "IMPORT")
      cld_nodes <- create_nodes_df(isa_data)
      cld_edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
      debug_log(sprintf("Generated CLD: %d nodes, %d edges", nrow(cld_nodes), nrow(cld_edges)), "IMPORT")

      # Update CLD data
      project_data$data$cld <- list(
        nodes = cld_nodes,
        edges = cld_edges,
        loops = NULL,
        metrics = NULL,
        simplified = FALSE,
        simplification_history = list()
      )

      # Clear analysis data since we're importing new data
      project_data$data$analysis <- list(loops = NULL, metrics = NULL)

      # Update metadata
      file_name <- if (!is.null(input$excel_file)) input$excel_file$name else "TuscanySES.xlsx"
      project_data$data$metadata$imported_from <- file_name
      project_data$data$metadata$import_date <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      project_data$data$metadata$data_source <- "excel_import"  # Flag to prevent AI ISA from overwriting
      project_data$last_modified <- Sys.time()

      # Save back to reactive
      project_data_reactive(project_data)

      # Emit ISA change event (with skip flag since CLD is already generated from connections)
      if (!is.null(event_bus)) {
        event_bus$skip_next_cld_regen(TRUE)  # Skip CLD regen since we built it from connections
        event_bus$emit_isa_change()
        debug_log("Emitted ISA change event with skip_cld_regen flag", "IMPORT")
      }

      showNotification(
        paste("Data imported successfully!",
              num_elements, "elements and",
              num_connections, "connections imported."),
        type = "message",
        duration = 3
      )

      # Reset
      rv$file_loaded <- FALSE
      rv$elements_data <- NULL
      rv$connections_data <- NULL
      rv$show_review <- FALSE
      rv$parsed_connections <- NULL

      # Navigate to dashboard using parent session if provided
      if (!is.null(parent_session)) {
        updateTabItems(session = parent_session, "tabs", "dashboard")
      }
    }

    # ========== HELP MODAL ==========
    create_help_observer(
      input,
      "import_data_help",
      "import_data_help_title",
      tagList(p(i18n$t("common.misc.import_data_help_content"))),
      i18n
    )

  })
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Validate imported data
validate_import_data <- function(elements, connections) {
  errors <- character()

  # Check elements
  if (is.null(elements) || nrow(elements) == 0) {
    errors <- c(errors, "Elements sheet is empty")
    return(errors)
  }

  if (!("Label" %in% names(elements))) {
    errors <- c(errors, "Elements sheet must have 'Label' column")
  }

  # Check for type column (might be type...2 due to duplicate names)
  type_col <- NULL
  if ("type...2" %in% names(elements)) {
    type_col <- "type...2"
  } else if ("type" %in% names(elements)) {
    type_col <- "type"
  }

  if (is.null(type_col)) {
    errors <- c(errors, "Elements sheet must have 'type' column")
  }

  # Check connections
  if (is.null(connections) || nrow(connections) == 0) {
    errors <- c(errors, "Connections sheet is empty")
    return(errors)
  }

  required_conn_cols <- c("From", "To", "Label")
  missing_cols <- setdiff(required_conn_cols, names(connections))
  if (length(missing_cols) > 0) {
    errors <- c(errors, paste("Connections sheet missing columns:", paste(missing_cols, collapse = ", ")))
  }

  # Check that connection nodes exist in elements
  if (!is.null(type_col)) {
    element_labels <- elements$Label
    conn_from <- unique(connections$From)
    conn_to <- unique(connections$To)

    missing_from <- setdiff(conn_from, element_labels)
    missing_to <- setdiff(conn_to, element_labels)

    if (length(missing_from) > 0) {
      errors <- c(errors, paste("Connection 'From' nodes not found in Elements:",
                               paste(head(missing_from, 3), collapse = ", "),
                               if(length(missing_from) > 3) "..."))
    }

    if (length(missing_to) > 0) {
      errors <- c(errors, paste("Connection 'To' nodes not found in Elements:",
                               paste(head(missing_to, 3), collapse = ", "),
                               if(length(missing_to) > 3) "..."))
    }
  }

  return(if (length(errors) > 0) errors else NULL)
}

# NOTE: convert_excel_to_isa() and build_adjacency_matrices_from_connections_v2() functions
# are provided by the shared excel_import_helpers.R module.
# The shared functions use a connection-first approach:
# 1. Extract all nodes from connections (From/To values)
# 2. Look up types from elements sheet
# 3. Infer types for unmatched nodes using DAPSIWRM keyword matching
# 4. Build ISA categories from connection-derived nodes
# 5. Build adjacency matrices ensuring all connection edges are preserved
#
# If the shared function is not available, the import will fail with an error message.
# Ensure excel_import_helpers.R is sourced in global.R before this module.

#' Parse connections for review module
parse_connections_for_review <- function(elements, connections) {

  # Get type column name
  type_col <- if ("type...2" %in% names(elements)) "type...2" else "type"

  # Create mapping from label to type
  label_to_type <- setNames(elements[[type_col]], elements$Label)

  # Parse each connection
  parsed <- lapply(1:nrow(connections), function(i) {
    conn <- connections[i, ]

    from_label <- conn$From
    to_label <- conn$To
    polarity <- conn$Label

    # Get strength
    strength <- "medium"
    if ("Strength" %in% names(connections)) {
      strength_val <- tolower(as.character(conn$Strength))
      if (grepl("strong", strength_val)) strength <- "strong"
      else if (grepl("weak", strength_val)) strength <- "weak"
    }

    # Get confidence
    confidence <- 3
    if ("Confidence" %in% names(connections)) {
      conf_val <- conn$Confidence
      if (!is.na(conf_val) && is.numeric(conf_val)) {
        confidence <- as.integer(conf_val)
      }
    }

    # Create rationale
    from_type <- label_to_type[from_label]
    to_type <- label_to_type[to_label]

    rationale <- sprintf("From %s (%s) to %s (%s)",
                        from_label, from_type,
                        to_label, to_type)

    list(
      from_name = from_label,
      to_name = to_label,
      polarity = polarity,
      strength = strength,
      confidence = confidence,
      rationale = rationale
    )
  })

  return(parsed)
}
