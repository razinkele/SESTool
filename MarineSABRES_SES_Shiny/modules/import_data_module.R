# modules/import_data_module.R
# Import Data Module
# Purpose: Import Excel files with Elements (nodes) and Connections (edges) sheets

library(shiny)
library(shinyjs)
library(readxl)

# Source the tabbed connection review module (organized by DAPSI(W)R(M) stages)
source("modules/connection_review_tabbed.R", local = TRUE)

# ============================================================================
# UI FUNCTION
# ============================================================================

import_data_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .import-container {
          padding: 20px;
          background: white;
          border-radius: 10px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin: 20px 0;
        }
        .import-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
          max-height: 400px;
          overflow-y: auto;
        }
      "))
    ),

    # Header
    create_module_header(ns, "import_data_title", "import_data_subtitle", "import_data_help", i18n),

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

        # Check sheets
        sheets <- readxl::excel_sheets(file_path)

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
        cat("[IMPORT] Approved connections:", paste(approved_idx, collapse = ", "), "\n")
      },
      on_reject = function(rejected_idx) {
        cat("[IMPORT] Rejected connections:", paste(rejected_idx, collapse = ", "), "\n")
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

        cat(sprintf("[IMPORT] Importing %d of %d connections (rejected: %d)\n",
                    nrow(connections_to_import), nrow(rv$connections_data), length(rejected)))

        # Convert to ISA structure
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
        # Convert to ISA structure
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
      cat("[IMPORT] Adjacency matrices created:\n")
      cat("[IMPORT]   Matrix names:", paste(names(isa_data$adjacency_matrices), collapse = ", "), "\n")
      total_matrix_connections <- 0
      for (matrix_name in names(isa_data$adjacency_matrices)) {
        mat <- isa_data$adjacency_matrices[[matrix_name]]
        non_empty <- sum(mat != "")
        total_matrix_connections <- total_matrix_connections + non_empty
        cat(sprintf("[IMPORT]   %s: %d connections\n", matrix_name, non_empty))
      }
      cat(sprintf("[IMPORT] Total connections in all matrices: %d\n", total_matrix_connections))

      # Get current project data
      project_data <- project_data_reactive()

      # Update ISA data
      project_data$data$isa_data <- isa_data

      # Generate CLD from imported ISA data
      cat("[IMPORT] Generating CLD from imported data...\n")
      cld_nodes <- create_nodes_df(isa_data)
      cld_edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
      cat(sprintf("[IMPORT] Generated CLD: %d nodes, %d edges\n", nrow(cld_nodes), nrow(cld_edges)))

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
        cat("[IMPORT] Emitted ISA change event with skip_cld_regen flag\n")
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

#' Convert Excel data to ISA framework structure
convert_excel_to_isa <- function(elements, connections) {

  # Get type column name
  type_col <- if ("type...2" %in% names(elements)) "type...2" else "type"

  # Initialize ISA data structure
  isa_data <- list(
    drivers = NULL,
    activities = NULL,
    pressures = NULL,
    marine_processes = NULL,
    ecosystem_services = NULL,
    goods_benefits = NULL,
    responses = NULL,
    adjacency_matrices = list()
  )

  # Map element types to ISA categories
  type_mapping <- list(
    "Driver" = "drivers",
    "Activity" = "activities",
    "Pressure" = "pressures",
    "Marine Process and Function" = "marine_processes",
    "Ecosystem Service" = "ecosystem_services",
    "Good and Benefit" = "goods_benefits",
    "Response" = "responses",
    "Measure" = "responses"  # Measures are now merged with responses
  )

  # Process each element type
  for (type_name in names(type_mapping)) {
    isa_key <- type_mapping[[type_name]]

    # Filter elements by type
    type_elements <- elements[elements[[type_col]] == type_name, ]

    if (nrow(type_elements) > 0) {
      # Create dataframe with ID, Name, Description
      df <- data.frame(
        ID = paste0(substr(isa_key, 1, 1), 1:nrow(type_elements)),
        Name = type_elements$Label,
        Description = "", # Excel file doesn't have descriptions
        stringsAsFactors = FALSE
      )

      isa_data[[isa_key]] <- df
    }
  }

  # Build adjacency matrices from connections
  isa_data$adjacency_matrices <- build_adjacency_matrices_from_connections(
    elements, connections, type_col, type_mapping
  )

  return(isa_data)
}

#' Build adjacency matrices from connections data
build_adjacency_matrices_from_connections <- function(elements, connections, type_col, type_mapping) {

  # Create mapping from label to type
  label_to_type <- setNames(elements[[type_col]], elements$Label)

  # Map to ISA categories
  label_to_isa <- sapply(label_to_type, function(type) {
    if (type %in% names(type_mapping)) {
      return(type_mapping[[type]])
    } else {
      return(NA)
    }
  })

  # Category abbreviation mapping
  category_abbrev <- list(
    "drivers" = "d",
    "activities" = "a",
    "pressures" = "p",
    "marine_processes" = "mpf",
    "ecosystem_services" = "es",
    "goods_benefits" = "gb",
    "responses" = "r"
  )

  # Find all unique category pairs that exist in the connections
  connection_pairs <- list()

  for (j in 1:nrow(connections)) {
    from_label <- connections$From[j]
    to_label <- connections$To[j]

    from_cat <- label_to_isa[from_label]
    to_cat <- label_to_isa[to_label]

    if (!is.na(from_cat) && !is.na(to_cat)) {
      pair_key <- paste(from_cat, to_cat, sep = "->")
      if (!(pair_key %in% names(connection_pairs))) {
        connection_pairs[[pair_key]] <- list(from = from_cat, to = to_cat)
      }
    }
  }

  # Build adjacency matrices for all unique connection pairs
  adjacency_matrices <- list()

  for (pair in connection_pairs) {
    from_category <- pair$from
    to_category <- pair$to

    # Get elements in each category
    from_elements <- elements$Label[label_to_isa == from_category]
    to_elements <- elements$Label[label_to_isa == to_category]

    if (length(from_elements) > 0 && length(to_elements) > 0) {
      # MATRIX CONVENTION: Create matrix in SOURCE×TARGET format
      # - Matrix will be named: from_to (e.g., "es_gb" for ES→GB connections)
      # - Matrix structure: rows=FROM elements (source), cols=TO elements (target)
      # - Cell [i,j]: Connection from FROM[i] to TO[j]
      mat <- matrix("", nrow = length(from_elements), ncol = length(to_elements))
      rownames(mat) <- from_elements
      colnames(mat) <- to_elements

      # Fill matrix with connections
      for (j in 1:nrow(connections)) {
        from_label <- connections$From[j]
        to_label <- connections$To[j]
        polarity <- connections$Label[j]

        # Check if this connection is between the current categories
        if (from_label %in% from_elements && to_label %in% to_elements) {
          # Determine strength
          strength <- "medium"
          if ("Strength" %in% names(connections)) {
            strength_val <- tolower(as.character(connections$Strength[j]))
            if (grepl("strong", strength_val)) strength <- "strong"
            else if (grepl("weak", strength_val)) strength <- "weak"
          }

          # Determine confidence
          confidence <- 3
          if ("Confidence" %in% names(connections)) {
            conf_val <- connections$Confidence[j]
            if (!is.na(conf_val) && is.numeric(conf_val)) {
              confidence <- as.integer(conf_val)
            }
          }

          # Format: +strength:confidence or -strength:confidence
          polarity_sign <- if (polarity == "+") "+" else "-"
          cell_value <- paste0(polarity_sign, strength, ":", confidence)

          # Matrix is SOURCE×TARGET, so indexing is [from, to]
          mat[from_label, to_label] <- cell_value
        }
      }

      # Add matrix to list with appropriate key using standard abbreviations
      # Matrix structure: rows=FROM elements (source), cols=TO elements (target)
      # Matrix name: FROM_TO (matches structure)
      # Example: Driver→Activity connection
      #   - Excel: From=Driver, To=Activity
      #   - Matrix name: "d_a" (driver_activity)
      #   - Matrix structure: rows=Drivers, cols=Activities (D×A)
      from_abbrev <- category_abbrev[[from_category]]
      to_abbrev <- category_abbrev[[to_category]]
      matrix_key <- paste0(from_abbrev, "_", to_abbrev)  # FROM_TO naming
      adjacency_matrices[[matrix_key]] <- mat
    }
  }

  return(adjacency_matrices)
}

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
