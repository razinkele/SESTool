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
      if (isTRUE(field$multiple)) {
        # Multi-select forward link (N:M): an element can pick many targets in
        # one panel. Drop the leading "" placeholder — an empty selection (no
        # picks) already means "no link", so a blank option is meaningless here.
        choices <- field$choices[nzchar(field$choices)]
        column(field$width,
               selectInput(input_id, field$label, choices = choices, multiple = TRUE))
      } else {
        column(field$width, selectInput(input_id, field$label, choices = field$choices))
      }
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
#' Removes the DOM panel and, if `isa_data` + `data_key` + `id_prefix` are
#' supplied, also deletes the matching row from the stored data.frame and
#' invokes the optional `on_remove` callback (e.g. for sync-to-project_data).
#' Without those arguments the function falls back to DOM-only removal
#' for backward compatibility with callers that don't yet persist.
#'
#' @param input Shiny input object
#' @param ns Shiny namespace function
#' @param prefix Element prefix (e.g. "gb", "es")
#' @param current_id Entry ID (numeric, matches the panel suffix)
#' @param i18n Translation object
#' @param isa_data Optional reactiveValues containing the stored data.frame
#' @param data_key Optional character — slot name in `isa_data` (e.g. "goods_benefits")
#' @param id_prefix Optional character — ELEMENT_ID_PREFIX value (e.g. "GB")
#' @param on_remove Optional function — called after row deletion (e.g. sync_to_project_data)
register_remove_observer <- function(input, ns, prefix, current_id, i18n,
                                     isa_data = NULL, data_key = NULL,
                                     id_prefix = NULL, on_remove = NULL) {
  observeEvent(input[[paste0(prefix, "_remove_", current_id)]], {
    removeUI(selector = paste0("#", ns(paste0(prefix, "_panel_", current_id))))

    # Drop the stable id from the ordered panel-id tracker (the single source of
    # truth for collection) so the survivor set no longer references it. Keeps
    # survivors' IDs stable — no positional renumber (fixes #2/#3/#4).
    if (!is.null(isa_data)) {
      tracker <- paste0(prefix, "_panel_ids")
      isa_data[[tracker]] <- setdiff(isa_data[[tracker]], current_id)
    }

    # If the row was already committed via Save Exercise, delete it from the
    # stored data.frame so the row doesn't ghost back on next render. current_id
    # is already the stable element ID (e.g. "ES001"), so match on it directly.
    if (!is.null(isa_data) && !is.null(data_key) && !is.null(id_prefix)) {
      df <- isa_data[[data_key]]
      if (is.data.frame(df) && nrow(df) > 0) {
        id_col <- if ("ID" %in% names(df)) "ID" else if ("id" %in% names(df)) "id" else NULL
        if (!is.null(id_col)) {
          isa_data[[data_key]] <- df[df[[id_col]] != current_id, , drop = FALSE]
        }
      }
    }

    if (is.function(on_remove)) on_remove()

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
         width = 3, choices = linked_choices, multiple = TRUE),
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
         width = 3, choices = linked_choices, multiple = TRUE),
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
         width = 3, choices = linked_choices, multiple = TRUE),
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
         width = 3, choices = linked_choices, multiple = TRUE),
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
         width = 3, choices = linked_choices, multiple = TRUE),
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
    if (is.data.frame(saved_df) && nrow(saved_df) > 0) {
      # Normalize column names to lowercase for consistency
      names(saved_df) <- tolower(names(saved_df))
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

  # Load loop connections (Exercise 6) if they exist — added in v1.13.0 alongside
  # the project_data round-trip fix.
  if (is.data.frame(isa_saved$loop_connections) && nrow(isa_saved$loop_connections) > 0) {
    debug_log(sprintf("Loading %d loop connections", nrow(isa_saved$loop_connections)), "ISA Module")
    isa_data$loop_connections <- isa_saved$loop_connections
  }

  # Load case_info (Exercise 0) if present
  if (!is.null(isa_saved$case_info) && length(isa_saved$case_info) > 0) {
    debug_log("Loading Exercise 0 case info", "ISA Module")
    isa_data$case_info <- isa_saved$case_info
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
#' @param panel_ids Ordered character vector of stable element IDs (the survivor
#'   set, e.g. isa_data$mpf_panel_ids). Field inputs are suffixed with these IDs
#'   and each row's ID is the panel id itself — never positional.
#' @param id_prefix Element ID prefix from ELEMENT_ID_PREFIX (retained for
#'   signature compatibility; no longer used to synthesize IDs).
#' @param field_ids Character vector of field ID suffixes to collect (e.g. c("name", "type", "desc"))
#' @param col_names Character vector of column names for the resulting data.frame (same order as field_ids)
#' @return A data.frame with an ID column plus columns for each field, or an empty data.frame
collect_element_entries <- function(input, prefix, panel_ids, id_prefix, field_ids, col_names) {
  if (length(panel_ids) == 0) return(data.frame())

  rows <- list()
  for (sid in panel_ids) {
    name_val <- input[[paste0(prefix, "_name_", sid)]]

    # Skip removed entries (NULL) and blank names
    if (is.null(name_val) || name_val == "") next

    # Collect all field values; the row ID is the stable panel id.
    vals <- list()
    vals[["ID"]] <- sid
    for (j in seq_along(field_ids)) {
      raw <- input[[paste0(prefix, "_", field_ids[j], "_", sid)]]
      val <- if (!is.null(raw)) raw else ""
      # LinkedX columns store bare element IDs for the reconciler; the select
      # value may be the legacy label form ("ES001: Fish") — normalize it.
      if (startsWith(col_names[j], "Linked")) val <- linked_select_to_ids(val)
      vals[[col_names[j]]] <- val
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
#' @param panel_ids Ordered character vector of stable element IDs (the survivor
#'   set tracked in isa_data$gb_panel_ids). Field inputs are suffixed with these
#'   IDs, and each collected row's ID is the panel id itself — never positional.
#' @param session Shiny session (for notifications)
#' @param i18n Translation object
#' @return List with \code{df} (data.frame or NULL on error) and \code{errors} (character vector)
validate_and_collect_gb <- function(input, panel_ids, session, i18n) {
  gb_rows <- list()
  validation_errors <- c()

  for (sid in panel_ids) {
    name_val <- input[[paste0("gb_name_", sid)]]
    type_val <- input[[paste0("gb_type_", sid)]]
    desc_val <- input[[paste0("gb_desc_", sid)]]
    stakeholder_val <- input[[paste0("gb_stakeholder_", sid)]]
    importance_val <- input[[paste0("gb_importance_", sid)]]
    trend_val <- input[[paste0("gb_trend_", sid)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("G&B ", sid, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("G&B ", sid, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("G&B ", sid, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(stakeholder_val, paste0("G&B ", sid, " Stakeholder"),
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
        ID = sid,
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
#' @param panel_ids Ordered character vector of stable element IDs
#'   (isa_data$es_panel_ids); each row's ID is the panel id, never positional.
#' @param session Shiny session
#' @param i18n Translation object
#' @return List with \code{df}, \code{errors}, \code{n_rows}
validate_and_collect_es <- function(input, panel_ids, session, i18n) {
  es_rows <- list()
  validation_errors <- c()

  for (sid in panel_ids) {
    name_val <- input[[paste0("es_name_", sid)]]
    type_val <- input[[paste0("es_type_", sid)]]
    desc_val <- input[[paste0("es_desc_", sid)]]
    linkedgb_val <- input[[paste0("es_linkedgb_", sid)]]
    mechanism_val <- input[[paste0("es_mechanism_", sid)]]
    confidence_val <- input[[paste0("es_confidence_", sid)]]

    if (is.null(name_val)) next
    if (name_val == "") next

    entry_validations <- list(
      validate_text_input(name_val, paste0("ES ", sid, " Name"),
                         required = TRUE, min_length = 2, max_length = 200,
                         session = NULL),
      validate_select_input(type_val, paste0("ES ", sid, " Type"),
                           required = TRUE,
                           valid_choices = c("Provisioning", "Regulating", "Cultural", "Supporting"),
                           session = NULL),
      validate_text_input(desc_val, paste0("ES ", sid, " Description"),
                         required = FALSE, max_length = 500,
                         session = NULL),
      validate_text_input(mechanism_val, paste0("ES ", sid, " Mechanism"),
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
        ID = sid,
        Name = entry_validations[[1]]$value,
        Type = entry_validations[[2]]$value,
        Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
        LinkedGB = linked_select_to_ids(linkedgb_val),
        Mechanism = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
        Confidence = confidence_val,
        stringsAsFactors = FALSE
      )
    }
  }

  df <- if (length(es_rows) > 0) do.call(rbind, es_rows) else data.frame()
  list(df = df, errors = validation_errors, n_rows = length(es_rows))
}

#' Build the four Responses-arm adjacency matrices from the responses element
#' rows' Linked* columns. Pure: no Shiny/reactives. Mirrors the forward-chain
#' rebuild but (a) builds 4 matrices, (b) seeds sign-aware lowercase/integer
#' defaults, (c) transposes gb_r to GB x R on store and on read so user edits
#' survive re-save. See docs/superpowers/specs/2026-06-06-responses-entry-design.md.
#'
#' @param isa list/reactiveValues with $responses (cols ID, LinkedGB/D/A/P),
#'   $goods_benefits, $drivers, $activities, $pressures, $adjacency_matrices,
#'   $user_edited_matrices.
#' @return list(adjacency_matrices, user_edited_matrices) updated copies.
#' @note Builds only gb_r / r_d / r_a / r_p (the in-scope R-arm). r_mpf / r_es
#'   are intentionally not built. Errors propagate to the caller by design
#'   (the Shiny save observer is the error boundary); we do not tryCatch here.
#'   stale_linked_ids / dropped_user_edits from rebuild_matrix_from_linked are
#'   not surfaced here — the save observer may report them if desired.
build_response_matrices <- function(isa) {
  am <- if (is.null(isa$adjacency_matrices)) list() else isa$adjacency_matrices
  ue <- if (is.null(isa$user_edited_matrices)) list() else isa$user_edited_matrices
  resp <- isa$responses
  # Need a data frame with rows AND an ID column to source edges from.
  if (!is.data.frame(resp) || nrow(resp) == 0 || !("ID" %in% names(resp))) {
    return(list(adjacency_matrices = am, user_edited_matrices = ue))
  }
  rid <- as.character(resp$ID)

  # Outgoing R -> target (negative polarity): r_d, r_a, r_p
  out_specs <- list(
    list(key = "r_d", col = "LinkedD", tgt = isa$drivers),
    list(key = "r_a", col = "LinkedA", tgt = isa$activities),
    list(key = "r_p", col = "LinkedP", tgt = isa$pressures)
  )
  for (s in out_specs) {
    tgt_ids <- if (is.data.frame(s$tgt)) as.character(s$tgt$ID) else character()
    if (length(tgt_ids) == 0 || !(s$col %in% names(resp))) next
    res <- rebuild_matrix_from_linked(
      element_df = resp, linked_col = s$col,
      source_ids = rid, target_ids = tgt_ids,
      # lowercase strength + integer confidence: required to key DYNAMICS_WEIGHT_MAP
      default_polarity = "-", default_strength = "medium", default_confidence = "3",
      existing_matrix    = am[[s$key]],
      user_edited_matrix = ue[[s$key]])
    am[[s$key]] <- res$matrix
    ue[[s$key]] <- res$user_edited
  }

  # Incoming GB -> R (positive). Built R x GB, then transposed to GB x R for
  # storage; existing/user_edited transposed on the way IN so projection aligns.
  gb_ids <- if (is.data.frame(isa$goods_benefits)) as.character(isa$goods_benefits$ID) else character()
  if (length(gb_ids) > 0 && "LinkedGB" %in% names(resp)) {
    res <- rebuild_matrix_from_linked(
      element_df = resp, linked_col = "LinkedGB",
      source_ids = rid, target_ids = gb_ids,
      # lowercase strength + integer confidence: required to key DYNAMICS_WEIGHT_MAP
      default_polarity = "+", default_strength = "medium", default_confidence = "3",
      existing_matrix    = if (!is.null(am$gb_r)) t(am$gb_r) else NULL,
      user_edited_matrix = if (!is.null(ue$gb_r)) t(ue$gb_r) else NULL)
    am$gb_r <- t(res$matrix)
    ue$gb_r <- t(res$user_edited)
  }

  list(adjacency_matrices = am, user_edited_matrices = ue)
}
