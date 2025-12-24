# functions/module_stubs.R
# Minimal stubs for module UIs/servers and helper utilities used in tests

library(shiny)

# Generic minimal UI function
minimal_ui <- function(id) {
  ns <- NS(id)
  tags$div(class = "stub-module", id = ns("root"), "Stub UI")
}

# Generic minimal server function
minimal_server <- function(input, output, session, ...) {
  # no-op
  reactiveValues()
}

# Module stubs
isaDataEntryUI <- function(id) minimal_ui(id)
isaDataEntryServer <- function(id, project_data = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

pims_project_ui <- function(id) minimal_ui(id)
pims_project_server <- function(id, project_data = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

cld_viz_ui <- function(id) minimal_ui(id)
cld_viz_server <- function(id, project_data = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

analysis_metrics_ui <- function(id) minimal_ui(id)
analysis_loops_ui <- function(id) minimal_ui(id)

entry_point_ui <- function(id) minimal_ui(id)
entry_point_server <- function(id, project_data = NULL, parent_session = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

ai_isa_assistant_ui <- function(id) minimal_ui(id)
ai_isa_assistant_server <- function(id, project_data = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

response_measures_ui <- function(id) minimal_ui(id)
scenario_builder_ui <- function(id) minimal_ui(id)

create_ses_ui <- function(id) {
  ns <- NS(id)
  tags$div(
    id = ns("create_ses_root"),
    tags$div(class = "card_standard", "Standard Entry"),
    tags$div(class = "card_ai", "AI Assistant"),
    tags$div(class = "card_template", "Template-Based"),
    tags$button(id = ns("proceed"), class = "proceed", "Proceed"),
    tags$table(id = ns("comparison_table"))
  )
}
create_ses_server <- function(id, project_data_reactive = NULL, parent_session = NULL) {
  moduleServer(id, function(input, output, session) minimal_server(input, output, session))
}

# Small UI helpers
create_action_button_with_tooltip <- function(id, label, tooltip = NULL) {
  ns <- NS(NULL)
  tags$button(id = id, class = "action-button", label)
}

create_collapsible_section <- function(title, content) {
  tags$div(class = "collapsible", tags$h3(title), tags$div(content))
}

create_data_tables <- function(...) {
  # Return a list with a datatable placeholder
  tags$div(class = "data-tables", "data tables")
}

create_empty_isa_data <- function() {
  list(elements = list(), connections = list())
}

create_help_text <- function(text) {
  tags$p(class = "help-text", text)
}

create_info_box <- function(title, value) {
  tags$div(class = "info-box", tags$strong(title), tags$div(value))
}

create_notification_box <- function(id, message) {
  tags$div(id = id, class = "notification", message)
}

create_progress_indicator <- function(id) {
  tags$div(id = id, class = "progress-indicator")
}

create_tooltip <- function(text) {
  tags$span(class = "tooltip", text)
}

create_value_card <- function(title, value) {
  tags$div(class = "value-card", tags$h4(title), tags$p(value))
}

# Network & export helpers (minimal behavior)
build_network_from_isa <- function(isa) {
  list(nodes = character(0), edges = data.frame())
}
calculate_centrality <- function(graph) {
  numeric(0)
}
convert_to_network_format <- function(x) {
  x
}
export_network_viz <- function(graph, path) {
  TRUE
}
export_to_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE)
  TRUE
}
export_to_excel <- function(data, path) {
  # minimal: write.csv with .xlsx name
  write.csv(data, sub("\.xlsx$", ".csv", path), row.names = FALSE)
  TRUE
}
export_to_json <- function(data, path) {
  jsonlite::write_json(data, path)
  TRUE
}

find_pathways <- function(graph, from, to) {
  list()
}

format_number_display <- function(x) as.character(x)
format_percentage <- function(x) paste0(round(x * 100, 1), "%")
format_report_data <- function(data) data

generate_summary_statistics <- function(data) list()
isa_to_dataframe <- function(isa) data.frame()
merge_isa_elements <- function(a, b) c(a, b)
rank_node_importance <- function(graph) numeric(0)

detect_feedback_loops <- function(graph) list()
simplify_network <- function(graph) graph
validate_export_data <- function(data) TRUE

# SES templates placeholder
ses_templates <- function() list()

# so that `exists()` checks work
utils::globalVariables(c("isaDataEntryUI", "isaDataEntryServer"))
