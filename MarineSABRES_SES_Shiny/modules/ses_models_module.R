# modules/ses_models_module.R
# SES Models Module
# Purpose: Load pre-built SES models from Excel files in the SESModels directory

# ============================================================================
# UI FUNCTION
# ============================================================================

ses_models_ui <- function(id, i18n) {
  ns <- NS(id)

  fluidPage(
    # Custom CSS
    tags$head(
      tags$style(HTML("
        .ses-models-container {
          padding: 20px;
          background: white;
          border-radius: 10px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin: 20px 0;
        }
        .ses-models-header {
          background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
          color: white;
          padding: 20px;
          border-radius: 10px;
          margin-bottom: 20px;
        }
        .model-preview-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          padding: 15px;
          border-radius: 8px;
          margin-top: 15px;
        }
        .model-info-item {
          display: flex;
          justify-content: space-between;
          padding: 8px 0;
          border-bottom: 1px solid #eee;
        }
        .model-info-item:last-child {
          border-bottom: none;
        }
        .model-info-label {
          font-weight: 600;
          color: #666;
        }
        .model-info-value {
          color: #333;
        }
        .element-type-badge {
          display: inline-block;
          padding: 2px 8px;
          margin: 2px;
          background: #e9ecef;
          border-radius: 12px;
          font-size: 12px;
        }
        .model-actions {
          margin-top: 20px;
          display: flex;
          gap: 10px;
          justify-content: center;
        }
      "))
    ),

    # Header
    div(class = "ses-models-header",
      h2(icon("database"), " ", i18n$t("modules.ses_models.title")),
      p(i18n$t("modules.ses_models.subtitle"))
    ),

    # Main content
    div(class = "ses-models-container",
      fluidRow(
        column(8,
          # Model selection dropdown with optgroups
          selectInput(
            ns("model_select"),
            label = i18n$t("modules.ses_models.select_model"),
            choices = NULL,
            width = "100%"
          ),
          # Variant selector (shown conditionally when model has multiple variants)
          uiOutput(ns("variant_selector"))
        ),
        column(4,
          br(),
          actionButton(
            ns("reload_btn"),
            i18n$t("modules.ses_models.load_models"),
            icon = icon("folder-open"),
            class = "btn-primary",
            style = "margin-top: 5px;"
          ),
          tags$small(
            class = "text-muted d-block mt-2",
            i18n$t("modules.ses_models.click_to_scan")
          )
        )
      ),

      # Model preview section
      uiOutput(ns("model_preview")),

      # Action buttons
      div(class = "model-actions",
        actionButton(
          ns("load_btn"),
          i18n$t("modules.ses_models.load_model"),
          icon = icon("upload"),
          class = "btn-success btn-lg",
          style = "font-size: 16px; padding: 12px 30px;"
        )
      ),

      # Status messages
      uiOutput(ns("status_message"))
    ),

    # Confirmation modal
    bsModal(
      id = ns("confirm_modal"),
      title = i18n$t("modules.ses_models.confirm_title"),
      trigger = NULL,
      size = "medium",
      tags$div(
        class = "text-center",
        icon("exclamation-triangle", style = "font-size: 48px; color: #ffc107;"),
        h4(style = "margin-top: 15px;", i18n$t("modules.ses_models.confirm_message")),
        p(class = "text-muted", uiOutput(ns("confirm_model_name"))),
        br(),
        div(
          actionButton(ns("confirm_yes"), i18n$t("common.buttons.yes"),
                      class = "btn-success", style = "margin-right: 10px;"),
          actionButton(ns("confirm_no"), i18n$t("common.buttons.no"),
                      class = "btn-secondary")
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

ses_models_server <- function(id, project_data_reactive, i18n, parent_session = NULL, event_bus = NULL,
                               ses_models_directory = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      models_list = NULL,
      models_grouped = NULL,  # Full model info including variants
      selected_model_path = NULL,
      selected_model_info = NULL,  # Full model info for selected model
      selected_variant = NULL,  # Currently selected variant name
      preview_data = NULL,
      loading = FALSE
    )

    # Helper function to get the current SES models directory
    get_models_dir <- function() {
      if (!is.null(ses_models_directory) && is.function(ses_models_directory)) {
        custom_dir <- ses_models_directory()
        if (!is.null(custom_dir) && nzchar(custom_dir) && dir.exists(custom_dir)) {
          return(custom_dir)
        }
      }
      return("SESModels")  # Default directory
    }

    # Flag to track if models have been loaded (on-demand loading for faster startup)
    rv$models_loaded <- FALSE

    # Function to load models on demand
    load_models_on_demand <- function() {
      if (!rv$models_loaded) {
        debug_log("Loading models on demand", "SES_MODELS")
        models_dir <- get_models_dir()

        # Check if directory exists
        if (!dir.exists(models_dir)) {
          debug_log(paste("WARNING: SESModels directory not found:", models_dir), "SES_MODELS")
          rv$models_list <- list()
          rv$models_grouped <- list()
          rv$models_loaded <- TRUE
          return()
        }

        # Scan models
        rv$models_grouped <- scan_ses_models(base_dir = models_dir, use_cache = TRUE)
        rv$models_list <- get_models_for_select(base_dir = models_dir)
        rv$models_loaded <- TRUE

        # Update selectInput choices
        if (length(rv$models_list) > 0) {
          updateSelectInput(
            session,
            "model_select",
            choices = rv$models_list
          )
          debug_log(paste("Loaded", length(rv$models_list), "models"), "SES_MODELS")
        } else {
          debug_log(paste("No models found in:", models_dir), "SES_MODELS")
        }
      }
    }

    # Load models when user clicks on the model selector (on-demand)
    observeEvent(input$model_select, {
      load_models_on_demand()
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

    # Also load when refresh button is clicked
    observeEvent(input$refresh_models, {
      rv$models_loaded <- FALSE  # Force reload
      load_models_on_demand()
    })

    # Watch for changes to the SES models directory setting
    observeEvent(if (!is.null(ses_models_directory)) ses_models_directory() else NULL, {
      # Only react if directory setting actually changed and module has been used
      if (rv$models_loaded) {
        models_dir <- get_models_dir()
        debug_log(paste("Directory setting changed, reloading from:", models_dir), "SES_MODELS")

        # Force reload from new directory
        rv$models_loaded <- FALSE
        rv$models_grouped <- scan_ses_models(base_dir = models_dir, use_cache = FALSE)
        rv$models_list <- get_models_for_select(base_dir = models_dir)
        rv$models_loaded <- TRUE
        rv$selected_model_path <- NULL
        rv$selected_model_info <- NULL
        rv$preview_data <- NULL

        # Update selectInput
        if (length(rv$models_list) > 0) {
          updateSelectInput(
            session,
            "model_select",
            choices = rv$models_list
          )
          showNotification(
            paste(i18n$t("modules.ses_models.models_reloaded"), "-", models_dir),
            type = "message",
            duration = 3
          )
        } else {
          updateSelectInput(
            session,
            "model_select",
            choices = list()
          )
          showNotification(
            i18n$t("modules.ses_models.no_models_found"),
            type = "warning",
            duration = 5
          )
        }
      }
    }, ignoreInit = TRUE, ignoreNULL = FALSE)

    # Reload models list (also serves as initial load button)
    observeEvent(input$reload_btn, {
      debug_log("Reload/Load button clicked", "SES_MODELS")
      rv$models_loaded <- FALSE  # Force reload
      rv$models_list <- NULL

      # Force reload using current directory
      models_dir <- get_models_dir()

      # Check directory exists
      if (!dir.exists(models_dir)) {
        showNotification(
          paste("SESModels directory not found:", models_dir),
          type = "error",
          duration = 5
        )
        return()
      }

      models <- reload_ses_models(base_dir = models_dir)
      rv$models_grouped <- models
      rv$models_list <- get_models_for_select(base_dir = models_dir)
      rv$models_loaded <- TRUE

      # Update selectInput
      if (length(rv$models_list) > 0) {
        updateSelectInput(
          session,
          "model_select",
          choices = rv$models_list
        )
        showNotification(
          paste(i18n$t("modules.ses_models.models_reloaded"), "-", length(rv$models_list), "models"),
          type = "message",
          duration = 3
        )
      } else {
        showNotification(
          i18n$t("modules.ses_models.no_models_found"),
          type = "warning",
          duration = 5
        )
      }
    })

    # Update preview when selection changes
    observeEvent(input$model_select, {
      req(input$model_select)
      rv$selected_model_path <- input$model_select
      rv$selected_variant <- NULL  # Reset variant selection

      # Find full model info from grouped models
      model_info <- NULL
      if (!is.null(rv$models_grouped)) {
        for (group in rv$models_grouped) {
          for (model in group) {
            if (model$file_path == input$model_select) {
              model_info <- model
              break
            }
          }
          if (!is.null(model_info)) break
        }
      }
      rv$selected_model_info <- model_info

      # Set default variant if model has variants
      if (!is.null(model_info) && model_info$variant_count > 0) {
        rv$selected_variant <- model_info$variants[[1]]$name
      }

      # Get preview (using first variant if multiple)
      rv$preview_data <- get_model_preview(input$model_select)
    })

    # Handle variant selection change
    observeEvent(input$variant_select, {
      req(input$variant_select)
      rv$selected_variant <- input$variant_select
      # Could update preview here for specific variant if needed
    })

    # Render variant selector (only shown if model has multiple variants)
    output$variant_selector <- renderUI({
      model_info <- rv$selected_model_info

      if (is.null(model_info) || model_info$variant_count <= 1) {
        return(NULL)
      }

      # Build choices from variants
      variant_choices <- setNames(
        lapply(model_info$variants, function(v) v$name),
        sapply(model_info$variants, function(v) {
          if (!is.null(v$node_sheet)) {
            paste0(v$name, " (", v$node_sheet, " + ", v$edge_sheet, ")")
          } else {
            paste0(v$name, " (edges only)")
          }
        })
      )

      div(style = "margin-top: 10px;",
        selectInput(
          ns("variant_select"),
          label = tags$span(
            i18n$t("modules.ses_models.select_variant"),
            tags$small(class = "text-muted",
              paste0(" (", model_info$variant_count, " ", i18n$t("modules.ses_models.variants_available"), ")"))
          ),
          choices = variant_choices,
          selected = rv$selected_variant,
          width = "100%"
        ),
        div(class = "alert alert-info", style = "padding: 8px; margin-top: 5px;",
          icon("info-circle"), " ",
          i18n$t("modules.ses_models.variant_info")
        )
      )
    })

    # Render model preview
    output$model_preview <- renderUI({
      req(rv$preview_data)
      preview <- rv$preview_data

      if (!preview$is_valid) {
        return(
          div(class = "model-preview-box",
            div(class = "alert alert-warning",
              icon("exclamation-triangle"), " ",
              strong(i18n$t("modules.ses_models.invalid_model")),
              tags$ul(
                lapply(preview$errors, function(err) tags$li(err))
              )
            )
          )
        )
      }

      # Build element type badges
      type_badges <- NULL
      if (length(preview$element_types) > 0) {
        type_badges <- lapply(names(preview$element_types), function(type_name) {
          count <- preview$element_types[[type_name]]
          span(class = "element-type-badge",
               paste0(type_name, ": ", count))
        })
      }

      div(class = "model-preview-box",
        h5(icon("info-circle"), " ", i18n$t("modules.ses_models.model_info")),

        div(class = "model-info-item",
          span(class = "model-info-label", i18n$t("modules.ses_models.file_name")),
          span(class = "model-info-value", preview$file_name)
        ),

        div(class = "model-info-item",
          span(class = "model-info-label", i18n$t("modules.ses_models.elements_count")),
          span(class = "model-info-value", preview$elements_count)
        ),

        div(class = "model-info-item",
          span(class = "model-info-label", i18n$t("modules.ses_models.connections_count")),
          span(class = "model-info-value", preview$connections_count)
        ),

        div(class = "model-info-item",
          span(class = "model-info-label", i18n$t("modules.ses_models.file_size")),
          span(class = "model-info-value", paste0(preview$size_kb, " KB"))
        ),

        div(class = "model-info-item",
          span(class = "model-info-label", i18n$t("modules.ses_models.last_modified")),
          span(class = "model-info-value", format(preview$modified_time, "%Y-%m-%d %H:%M"))
        ),

        if (length(type_badges) > 0) {
          div(class = "model-info-item",
            span(class = "model-info-label", i18n$t("modules.ses_models.element_types")),
            div(class = "model-info-value", type_badges)
          )
        }
      )
    })

    # Load button - show confirmation
    observeEvent(input$load_btn, {
      req(rv$selected_model_path, rv$preview_data)

      if (!rv$preview_data$is_valid) {
        showNotification(
          i18n$t("modules.ses_models.cannot_load_invalid"),
          type = "error",
          duration = 5
        )
        return()
      }

      # Show confirmation modal
      toggleModal(session, "confirm_modal", toggle = "open")
    })

    # Confirmation model name display
    output$confirm_model_name <- renderUI({
      req(rv$preview_data)
      strong(rv$preview_data$file_name)
    })

    # Confirm No - close modal
    observeEvent(input$confirm_no, {
      toggleModal(session, "confirm_modal", toggle = "close")
    })

    # Confirm Yes - load the model
    observeEvent(input$confirm_yes, {
      req(rv$selected_model_path)

      # Close modal
      toggleModal(session, "confirm_modal", toggle = "close")

      # Load the model
      rv$loading <- TRUE

      variant_name <- rv$selected_variant
      debug_log(paste("Starting model load for:", rv$selected_model_path), "SES_MODELS")
      if (!is.null(variant_name)) {
        debug_log(paste("Using variant:", variant_name), "SES_MODELS")
      }

      tryCatch({
        # Load model file with selected variant
        debug_log("Loading model file", "SES_MODELS")
        model_data <- load_ses_model_file(rv$selected_model_path, validate = TRUE, variant_name = variant_name)

        if (length(model_data$errors) > 0) {
          debug_log(paste("Model has errors:", paste(model_data$errors, collapse = "; ")), "SES_MODELS")
          showNotification(
            paste(i18n$t("modules.ses_models.load_error"), paste(model_data$errors, collapse = "; ")),
            type = "error",
            duration = 10
          )
          rv$loading <- FALSE
          return()
        }

        # Convert to ISA structure using shared function from excel_import_helpers.R
        debug_log("Converting to ISA structure", "SES_MODELS")

        # Check if convert_excel_to_isa is available
        if (!exists("convert_excel_to_isa", mode = "function")) {
          showNotification(
            "convert_excel_to_isa function not found. Make sure excel_import_helpers.R is sourced.",
            type = "error",
            duration = 10
          )
          rv$loading <- FALSE
          return()
        }

        isa_data <- convert_excel_to_isa(model_data$elements, model_data$connections)
        debug_log("ISA conversion complete", "SES_MODELS")

        # Perform import (similar to import_data_module.R)
        debug_log("Performing import", "SES_MODELS")
        perform_ses_model_import(
          isa_data,
          model_data$elements,
          model_data$connections,
          model_data$file_name,
          project_data_reactive,
          event_bus,
          parent_session,
          i18n
        )

        rv$loading <- FALSE
        debug_log("Model load complete", "SES_MODELS")

      }, error = function(e) {
        debug_log(paste("ERROR:", e$message), "SES_MODELS")
        debug_log(paste("Error call:", deparse(e$call)), "SES_MODELS")
        # Capture full traceback
        tb <- sys.calls()
        if (length(tb) > 0) {
          tb_lines <- vapply(seq_along(tb), function(i) paste0("  ", i, ": ", deparse(tb[[i]])[1]), character(1))
          debug_log(paste("Traceback:", paste(tb_lines, collapse = "\n")), "SES_MODELS")
        }
        showNotification(
          paste(i18n$t("modules.ses_models.load_error"), e$message),
          type = "error",
          duration = 10
        )
        rv$loading <- FALSE
      })
    })

    # Status message output
    output$status_message <- renderUI({
      if (rv$loading) {
        div(class = "text-center", style = "margin-top: 20px;",
          icon("spinner", class = "fa-spin fa-2x"),
          p(i18n$t("modules.ses_models.loading"))
        )
      }
    })

  })
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Perform SES model import
#'
#' Imports the converted ISA data into the project
#'
#' @param isa_data ISA data structure
#' @param elements Original elements dataframe
#' @param connections Original connections dataframe
#' @param file_name Source file name
#' @param project_data_reactive Reactive value for project data
#' @param event_bus Event bus for reactive pipeline
#' @param parent_session Parent Shiny session for navigation
#' @param i18n Translation object
perform_ses_model_import <- function(isa_data, elements, connections,
                                      file_name, project_data_reactive,
                                      event_bus, parent_session, i18n) {

  num_elements <- nrow(elements)
  num_connections <- nrow(connections)

  debug_log(paste("Importing model:", file_name), "SES_MODELS")
  debug_log(paste("Elements:", num_elements, ", Connections:", num_connections), "SES_MODELS")

  # Get current project data
  project_data <- project_data_reactive()

  # Update ISA data
  project_data$data$isa_data <- isa_data

  # Generate CLD from imported ISA data
  debug_log("Generating CLD from imported data", "SES_MODELS")
  cld_nodes <- create_nodes_df(isa_data)
  cld_edges <- create_edges_df(isa_data, isa_data$adjacency_matrices)
  debug_log(sprintf("Generated CLD: %d nodes, %d edges", nrow(cld_nodes), nrow(cld_edges)), "SES_MODELS")

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
  project_data$data$metadata$imported_from <- file_name
  project_data$data$metadata$import_date <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  project_data$data$metadata$data_source <- "ses_models"
  project_data$last_modified <- Sys.time()

  # Save back to reactive
  project_data_reactive(project_data)

  # Emit ISA change event (with skip flag since CLD is already generated)
  if (!is.null(event_bus)) {
    event_bus$skip_next_cld_regen(TRUE)
    event_bus$emit_isa_change()
    debug_log("Emitted ISA change event with skip_cld_regen flag", "SES_MODELS")
  }

  showNotification(
    paste(i18n$t("modules.ses_models.load_success"),
          num_elements, i18n$t("modules.ses_models.elements_and"),
          num_connections, i18n$t("modules.ses_models.connections_imported")),
    type = "message",
    duration = 5
  )

  # Navigate to dashboard
  if (!is.null(parent_session)) {
    updateTabItems(session = parent_session, "tabs", "dashboard")
  }
}
