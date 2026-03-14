# functions/isa_form_builders.R
# Extracted from modules/isa_data_entry_module.R
# Reusable form builders and entry collection helpers for ISA DAPSI(W)R(M) elements

# ============================================================================
# ELEMENT ENTRY FORM PANEL BUILDERS
# ============================================================================

#' Build a dynamic ISA entry panel for insertUI
#'
#' Each element type (GB, ES, MPF, P, A, D) follows the same structure:
#' a styled div with two fluidRows of form inputs and a remove button.
#'
#' @param ns Shiny namespace function
#' @param prefix Short prefix for input IDs (e.g. "gb", "es", "mpf", "p", "a", "d")
#' @param current_id Numeric counter for this entry
#' @param fields List of field definitions. Each is a list with:
#'   \itemize{
#'     \item \code{id} - suffix for the input ID (appended to prefix)
#'     \item \code{type} - "text" or "select"
#'     \item \code{label} - translated label string
#'     \item \code{width} - column width (1-12)
#'     \item \code{choices} - (for select) vector of choices
#'     \item \code{placeholder} - (for text) placeholder string
#'   }
#' @param i18n Translation object (used for remove button label)
#' @return A shiny div tag suitable for insertUI
build_entry_panel_ui <- function(ns, prefix, current_id, fields, i18n) {
  # Split fields into two rows roughly evenly
  # First row: first 3 fields, Second row: remaining fields + remove button
  row1_fields <- fields[seq_len(min(3, length(fields)))]
  row2_fields <- if (length(fields) > 3) fields[4:length(fields)] else list()

  build_field <- function(field) {
    input_id <- ns(paste0(prefix, "_", field$id, "_", current_id))
    if (identical(field$type, "select")) {
      column(field$width, selectInput(input_id, field$label, choices = field$choices))
    } else {
      column(field$width, textInput(input_id, field$label,
                                     placeholder = if (!is.null(field$placeholder)) field$placeholder else ""))
    }
  }

  row1_cols <- lapply(row1_fields, build_field)
  row2_cols <- lapply(row2_fields, build_field)

  # Calculate remaining width for remove button in row 2
  used_width <- sum(sapply(row2_fields, function(f) f$width))
  remove_width <- max(1, 12 - used_width)

  row2_cols[[length(row2_cols) + 1]] <- column(
    remove_width,
    actionButton(
      ns(paste0(prefix, "_remove_", current_id)),
      i18n$t("common.buttons.remove"),
      class = "btn-danger btn-sm"
    )
  )

  div(
    id = ns(paste0(prefix, "_panel_", current_id)),
    class = "isa-entry-panel",
    style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
    do.call(fluidRow, row1_cols),
    do.call(fluidRow, row2_cols)
  )
}

#' Register a remove-button observer for an ISA entry panel
#'
#' @param input Shiny input object
#' @param ns Shiny namespace function
#' @param prefix Element prefix
#' @param current_id Entry ID
#' @param i18n Translation object
register_remove_observer <- function(input, ns, prefix, current_id, i18n) {
  observeEvent(input[[paste0(prefix, "_remove_", current_id)]], {
    removeUI(selector = paste0("#", ns(paste0(prefix, "_panel_", current_id))))
    showNotification(i18n$t("modules.isa.data_entry.common.entry_removed"), type = "message", duration = 2)
  }, ignoreInit = TRUE, once = TRUE)
}

# ============================================================================
# FIELD DEFINITIONS PER ELEMENT TYPE
# ============================================================================

#' Get field definitions for Goods & Benefits entry form
#' @param i18n Translation object
#' @return List of field definitions
isa_fields_gb <- function(i18n) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_fish_catch")),
    list(id = "type", type = "select", label = i18n$t("common.labels.type"),
         width = 3, choices = c("Provisioning", "Regulating", "Cultural", "Supporting")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "stakeholder", type = "text", label = i18n$t("modules.isa.data_entry.common.stakeholder"),
         width = 3),
    list(id = "importance", type = "select", label = i18n$t("modules.isa.data_entry.common.importance"),
         width = 3, choices = c("High", "Medium", "Low")),
    list(id = "trend", type = "select", label = i18n$t("modules.isa.data_entry.common.trend"),
         width = 3, choices = c("Increasing", "Stable", "Decreasing", "Unknown"))
  )
}

#' Get field definitions for Ecosystem Services entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked GB choices
#' @return List of field definitions
isa_fields_es <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_fish_production")),
    list(id = "type", type = "select", label = i18n$t("common.labels.es_type"),
         width = 3, choices = c("Provisioning", "Regulating", "Cultural", "Supporting")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedgb", type = "select", label = i18n$t("modules.isa.data_entry.common.linked_to_gb"),
         width = 3, choices = linked_choices),
    list(id = "mechanism", type = "text", label = i18n$t("modules.isa.data_entry.common.mechanism"),
         width = 3),
    list(id = "confidence", type = "select", label = i18n$t("modules.isa.data_entry.common.confidence"),
         width = 4, choices = c("High", "Medium", "Low"))
  )
}

#' Get field definitions for Marine Processes entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked ES choices
#' @return List of field definitions
isa_fields_mpf <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_primary_production")),
    list(id = "type", type = "select", label = i18n$t("common.labels.process_type"),
         width = 3, choices = c("Biological", "Chemical", "Physical", "Ecological")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedes", type = "select", label = i18n$t("modules.isa.data_entry.common.linked_to_es"),
         width = 3, choices = linked_choices),
    list(id = "mechanism", type = "text", label = i18n$t("modules.isa.data_entry.common.mechanism"),
         width = 3),
    list(id = "spatial", type = "text", label = i18n$t("modules.isa.data_entry.common.spatial_scale"),
         width = 4)
  )
}

#' Get field definitions for Pressures entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked MPF choices
#' @return List of field definitions
isa_fields_p <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_nutrient_enrichment")),
    list(id = "type", type = "select", label = i18n$t("common.labels.pressure_type"),
         width = 3, choices = c("Physical", "Chemical", "Biological", "Multiple")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedmpf", type = "select", label = i18n$t("modules.isa.data_entry.common.linked_to_mpf"),
         width = 3, choices = linked_choices),
    list(id = "intensity", type = "select", label = i18n$t("modules.isa.data_entry.common.intensity"),
         width = 3, choices = c("High", "Medium", "Low", "Unknown")),
    list(id = "spatial", type = "text", label = i18n$t("modules.isa.data_entry.common.spatial"),
         width = 2),
    list(id = "temporal", type = "text", label = i18n$t("modules.isa.data_entry.common.temporal"),
         width = 2)
  )
}

#' Get field definitions for Activities entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked Pressure choices
#' @return List of field definitions
isa_fields_a <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_commercial_fishing")),
    list(id = "sector", type = "select", label = i18n$t("modules.isa.data_entry.common.sector"),
         width = 3, choices = c("Fisheries", "Aquaculture", "Tourism", "Shipping", "Energy", "Mining", "Other")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkedp", type = "select", label = i18n$t("modules.isa.data_entry.common.linked_to_pressure"),
         width = 3, choices = linked_choices),
    list(id = "scale", type = "select", label = i18n$t("modules.isa.data_entry.common.scale"),
         width = 3, choices = c("Local", "Regional", "National", "International")),
    list(id = "frequency", type = "select", label = i18n$t("modules.isa.data_entry.common.frequency"),
         width = 4, choices = c("Continuous", "Seasonal", "Occasional", "One-time"))
  )
}

#' Get field definitions for Drivers entry form
#' @param i18n Translation object
#' @param linked_choices Character vector of linked Activity choices
#' @return List of field definitions
isa_fields_d <- function(i18n, linked_choices) {
  list(
    list(id = "name", type = "text", label = i18n$t("common.labels.name"),
         width = 3, placeholder = i18n$t("modules.isa.data_entry.common.eg_economic_growth")),
    list(id = "type", type = "select", label = i18n$t("common.labels.driver_type"),
         width = 3, choices = c("Economic", "Social", "Technological", "Political", "Environmental", "Demographic")),
    list(id = "desc", type = "text", label = i18n$t("common.labels.description"),
         width = 6),
    list(id = "linkeda", type = "select", label = i18n$t("modules.isa.data_entry.common.linked_to_activity"),
         width = 3, choices = linked_choices),
    list(id = "trend", type = "select", label = i18n$t("modules.isa.data_entry.common.trend"),
         width = 3, choices = c("Increasing", "Stable", "Decreasing", "Cyclical", "Uncertain")),
    list(id = "control", type = "select", label = i18n$t("modules.isa.data_entry.common.controllability"),
         width = 4, choices = c("High", "Medium", "Low", "None"))
  )
}

# ============================================================================
# DATA LOADING HELPERS
# ============================================================================

#' Load saved ISA data from a project into module reactive values
#'
#' Transfers element data frames and counters from a saved project structure
#' into the module's reactiveValues, logging each step.
#'
#' @param isa_data Module reactiveValues to populate
#' @param isa_saved Saved ISA data list from project$data$isa_data
#' @return Invisible NULL; modifies isa_data by side effect
load_isa_elements_from_saved <- function(isa_data, isa_saved) {
  # Map of element key -> (counter field, display label)
  element_map <- list(
    drivers            = list(counter = "d_counter",   label = "drivers"),
    activities         = list(counter = "a_counter",   label = "activities"),
    pressures          = list(counter = "p_counter",   label = "pressures"),
    marine_processes   = list(counter = "mpf_counter", label = "marine processes"),
    ecosystem_services = list(counter = "es_counter",  label = "ecosystem services"),
    goods_benefits     = list(counter = "gb_counter",  label = "goods/benefits")
  )

  for (key in names(element_map)) {
    saved_df <- isa_saved[[key]]
    if (!is.null(saved_df) && nrow(saved_df) > 0) {
      debug_log(sprintf("Loading %d %s", nrow(saved_df), element_map[[key]]$label), "ISA Module")
      isa_data[[key]] <- saved_df
      isa_data[[element_map[[key]]$counter]] <- nrow(saved_df)
    }
  }

  # Load adjacency matrices if they exist
  if (!is.null(isa_saved$adjacency_matrices)) {
    debug_log("Loading adjacency matrices", "ISA Module")
    isa_data$adjacency_matrices <- isa_saved$adjacency_matrices

    n_connections <- 0
    for (matrix_name in names(isa_saved$adjacency_matrices)) {
      mat <- isa_saved$adjacency_matrices[[matrix_name]]
      if (!is.null(mat) && is.matrix(mat)) {
        n_connections <- n_connections + sum(mat != "", na.rm = TRUE)
      }
    }
    debug_log(sprintf("Loaded %d connections from adjacency matrices", n_connections), "ISA Module")
  }

  invisible(NULL)
}

# ============================================================================
# ENTRY COLLECTION HELPERS
# ============================================================================

#' Collect entries from dynamic form inputs for a given element type
#'
#' Reads all dynamically-created inputs for a given prefix/counter and
#' builds a data.frame. Skips removed entries (NULL name) and empty names.
#'
#' @param input Shiny input object
#' @param prefix Element prefix (e.g. "gb", "es", "mpf", "p", "a", "d")
#' @param counter Number of entries created (max ID)
#' @param id_prefix Element ID prefix from ELEMENT_ID_PREFIX (e.g. "GB", "ES")
#' @param field_ids Character vector of field ID suffixes to collect (e.g. c("name", "type", "desc"))
#' @param col_names Character vector of column names for the resulting data.frame (same order as field_ids)
#' @return A data.frame with an ID column plus columns for each field, or an empty data.frame
collect_element_entries <- function(input, prefix, counter, id_prefix, field_ids, col_names) {
  if (counter == 0) return(data.frame())

  rows <- list()
  for (i in seq_len(counter)) {
    name_val <- input[[paste0(prefix, "_name_", i)]]

    # Skip removed entries (NULL) and blank names
    if (is.null(name_val) || name_val == "") next

    # Collect all field values
    vals <- list()
    vals[["ID"]] <- generate_element_id(id_prefix, i)
    for (j in seq_along(field_ids)) {
      raw <- input[[paste0(prefix, "_", field_ids[j], "_", i)]]
      vals[[col_names[j]]] <- if (!is.null(raw)) raw else ""
    }
    rows[[length(rows) + 1]] <- as.data.frame(vals, stringsAsFactors = FALSE)
  }

  if (length(rows) == 0) return(data.frame())
  do.call(rbind, rows)
}

#' Show validation error modal for ISA entry save
#'
#' @param validation_errors Character vector of error messages
#' @param i18n Translation object
show_validation_error_modal <- function(validation_errors, i18n) {
  showModal(modalDialog(
    title = tags$div(icon("exclamation-triangle"), i18n$t("modules.isa.data_entry.common.validation_errors")),
    tags$div(
      tags$p(strong(i18n$t("modules.isa.data_entry.common.please_fix_the_following_issues_before_saving"))),
      tags$ul(
        lapply(validation_errors, function(err) tags$li(err))
      )
    ),
    easyClose = TRUE,
    footer = modalButton(i18n$t("common.buttons.ok"))
  ))
}

#' Validate and collect Goods & Benefits entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of GB entries created
#' @param session Shiny session (for notifications)
#' @param i18n Translation object
#' @return List with \code{df} (data.frame or NULL on error) and \code{errors} (character vector)
validate_and_collect_gb <- function(input, counter, session, i18n) {
  gb_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("gb_name_", i)]]
    type_val <- input[[paste0("gb_type_", i)]]
    desc_val <- input[[paste0("gb_desc_", i)]]
    stakeholder_val <- input[[paste0("gb_stakeholder_", i)]]
    importance_val <- input[[paste0("gb_importance_", i)]]
    trend_val <- input[[paste0("gb_trend_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("G&B ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("G&B ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("G&B ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(stakeholder_val, paste0("G&B ", i, " Stakeholder"),
                         required = FALSE, max_length = 200,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      gb_rows[[length(gb_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$welfare, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        Stakeholder = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Importance = importance_val,
        Trend = trend_val,
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(gb_rows) > 0) do.call(rbind, gb_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(gb_rows))
}

#' Validate and collect Ecosystem Services entries with full validation
#'
#' @param input Shiny input object
#' @param counter Number of ES entries created
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_es <- function(input, counter, session, i18n) {
  es_rows <- list()
  validation_errors <- c()

  for (i in seq_len(counter)) {
    name_val <- input[[paste0("es_name_", i)]]
    type_val <- input[[paste0("es_type_", i)]]
    desc_val <- input[[paste0("es_desc_", i)]]
    linkedgb_val <- input[[paste0("es_linkedgb_", i)]]
    mechanism_val <- input[[paste0("es_mechanism_", i)]]
    confidence_val <- input[[paste0("es_confidence_", i)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("ES ", i, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("ES ", i, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("ES ", i, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(mechanism_val, paste0("ES ", i, " Mechanism"),
                         required = FALSE, max_length = 300,
                         session = NULL)
    )

    for (v in entry_validations) {
      if (!v$valid) {
        validation_errors <- c(validation_errors, v$message)
      }
    }

    if (all(sapply(entry_validations, function(v) v$valid))) {
      es_rows[[length(es_rows) + 1]] <- data.frame(
        ID = generate_element_id(ELEMENT_ID_PREFIX$impacts, i),
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedGB = linkedgb_val,
        Mechanism = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Confidence = confidence_val,
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(es_rows) > 0) do.call(rbind, es_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(es_rows))
}
