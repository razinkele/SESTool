# Scenario Builder Module - Implementation Guide

**Priority:** ⭐⭐⭐ HIGH
**Estimated Effort:** 25 hours
**File:** `modules/scenario_builder_module.R`
**Current Status:** Placeholder stub in `modules/response_module.R` (lines 654-671)

---

## Overview

The Scenario Builder module enables users to create "what-if" scenarios by manipulating drivers and response measures, then visualizing the predicted impacts on the social-ecological system.

**Key Features:**
1. Scenario creation and management (CRUD)
2. Driver value manipulation
3. Response measure selection and combination
4. Impact prediction and visualization
5. Scenario comparison
6. Narrative generation
7. Excel export

---

## Module Structure

```r
# modules/scenario_builder_module.R

# ============================================================================
# UI FUNCTION
# ============================================================================
scenario_builder_ui <- function(id) {
  # Tab-based interface
  # Tab 1: Scenario Management
  # Tab 2: Configure Scenario
  # Tab 3: Predict Impacts
  # Tab 4: Compare Scenarios
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================
scenario_builder_server <- function(id, project_data) {
  # Scenario CRUD operations
  # Driver manipulation logic
  # Impact prediction algorithm
  # Comparison visualizations
}
```

---

## Detailed Implementation Plan

### Phase 1: Scenario Management (Day 1 - 8 hours)

#### Tab 1: Scenario Registry

**UI Components:**
```r
# Scenario list
DTOutput("scenarios_table")

# Action buttons
actionButton("add_scenario", "New Scenario", icon = icon("plus"))
actionButton("edit_scenario", "Edit", icon = icon("edit"))
actionButton("duplicate_scenario", "Duplicate", icon = icon("copy"))
actionButton("delete_scenario", "Delete", icon = icon("trash"))
```

**Data Structure:**
```r
scenario <- list(
  id = "SCN_001",
  name = "Business as Usual",
  description = "Current trajectory without interventions",
  created_at = Sys.time(),
  modified_at = Sys.time(),

  # Configuration
  drivers = list(
    "DRV_001" = list(id = "DRV_001", name = "Fishing effort", baseline = 100, scenario = 100),
    "DRV_002" = list(id = "DRV_002", name = "Tourism", baseline = 50, scenario = 75)
  ),

  responses = c("RSP_001", "RSP_003"),  # IDs of active response measures

  # Results
  impacts = data.frame(
    element_id = character(),
    element_name = character(),
    baseline_value = numeric(),
    scenario_value = numeric(),
    change_percent = numeric(),
    stringsAsFactors = FALSE
  ),

  notes = "Additional notes..."
)
```

**Server Logic:**
```r
# Reactive value for scenarios
scenarios <- reactiveVal(list())

# Load from project data
observe({
  data <- project_data()
  if (!is.null(data$data$scenarios)) {
    scenarios(data$data$scenarios)
  }
})

# Add scenario
observeEvent(input$add_scenario, {
  showModal(modalDialog(
    title = "Create New Scenario",
    textInput(ns("new_scenario_name"), "Scenario Name:", placeholder = "e.g., Reduced fishing"),
    textAreaInput(ns("new_scenario_desc"), "Description:", rows = 4),
    footer = tagList(
      modalButton("Cancel"),
      actionButton(ns("save_new_scenario"), "Create", class = "btn-primary")
    )
  ))
})

observeEvent(input$save_new_scenario, {
  new_scenario <- create_empty_scenario(
    name = input$new_scenario_name,
    description = input$new_scenario_desc,
    drivers = get_all_drivers(project_data()),
    responses = c()
  )

  current_scenarios <- scenarios()
  current_scenarios[[new_scenario$id]] <- new_scenario
  scenarios(current_scenarios)

  # Save to project data
  data <- project_data()
  data$data$scenarios <- scenarios()
  project_data(data)

  removeModal()
  showNotification("Scenario created successfully", type = "message")
})

# Helper function
create_empty_scenario <- function(name, description, drivers, responses) {
  list(
    id = paste0("SCN_", format(Sys.time(), "%Y%m%d%H%M%S")),
    name = name,
    description = description,
    created_at = Sys.time(),
    modified_at = Sys.time(),
    drivers = lapply(drivers, function(d) {
      list(
        id = d$id,
        name = d$name,
        baseline = 100,  # Normalized baseline
        scenario = 100   # Start at baseline
      )
    }),
    responses = responses,
    impacts = data.frame(),
    notes = ""
  )
}
```

---

### Phase 2: Configure Scenario (Day 2 - 8 hours)

#### Tab 2: Driver Manipulation & Response Selection

**UI Components:**
```r
# Driver manipulation
fluidRow(
  column(6,
    h4("Driver Adjustments"),
    p("Adjust driver levels to create your scenario (100 = baseline)"),

    # Dynamic driver sliders
    uiOutput("driver_sliders")
  ),

  column(6,
    h4("Response Measures"),
    p("Select response measures to include in this scenario"),

    # Checkboxes for responses
    uiOutput("response_checkboxes"),

    br(),
    actionButton("apply_scenario_config", "Apply Configuration", class = "btn-primary")
  )
)

# Preview
fluidRow(
  column(12,
    h4("Scenario Configuration Summary"),
    verbatimTextOutput("scenario_config_summary")
  )
)
```

**Server Logic:**
```r
# Current scenario selection
current_scenario <- reactiveVal(NULL)

observeEvent(input$scenarios_table_rows_selected, {
  idx <- input$scenarios_table_rows_selected
  if (length(idx) > 0) {
    scenario_list <- scenarios()
    current_scenario(scenario_list[[idx]])
  }
})

# Render driver sliders
output$driver_sliders <- renderUI({
  scenario <- current_scenario()
  req(scenario)

  lapply(scenario$drivers, function(driver) {
    sliderInput(
      ns(paste0("driver_", driver$id)),
      label = driver$name,
      min = 0,
      max = 200,
      value = driver$scenario,
      step = 5,
      post = "%"
    )
  })
})

# Render response checkboxes
output$response_checkboxes <- renderUI({
  scenario <- current_scenario()
  req(scenario)

  all_responses <- project_data()$data$responses$measures

  checkboxGroupInput(
    ns("selected_responses"),
    label = NULL,
    choices = setNames(
      sapply(all_responses, function(r) r$id),
      sapply(all_responses, function(r) r$name)
    ),
    selected = scenario$responses
  )
})

# Apply configuration
observeEvent(input$apply_scenario_config, {
  scenario <- current_scenario()
  req(scenario)

  # Update driver values
  for (driver in scenario$drivers) {
    driver_input_id <- paste0("driver_", driver$id)
    if (!is.null(input[[driver_input_id]])) {
      scenario$drivers[[driver$id]]$scenario <- input[[driver_input_id]]
    }
  }

  # Update responses
  scenario$responses <- input$selected_responses
  scenario$modified_at <- Sys.time()

  # Save
  scenario_list <- scenarios()
  scenario_list[[scenario$id]] <- scenario
  scenarios(scenario_list)
  current_scenario(scenario)

  # Update project data
  data <- project_data()
  data$data$scenarios <- scenarios()
  project_data(data)

  showNotification("Scenario configuration updated", type = "message")
})

# Configuration summary
output$scenario_config_summary <- renderPrint({
  scenario <- current_scenario()
  req(scenario)

  cat("Scenario:", scenario$name, "\n\n")

  cat("Driver Changes from Baseline:\n")
  for (driver in scenario$drivers) {
    change <- driver$scenario - driver$baseline
    cat(sprintf("  %s: %+d%%\n", driver$name, change))
  }

  cat("\nActive Response Measures:\n")
  if (length(scenario$responses) > 0) {
    for (resp_id in scenario$responses) {
      # Look up response name
      cat(sprintf("  - %s\n", resp_id))
    }
  } else {
    cat("  (None)\n")
  }
})
```

---

### Phase 3: Impact Prediction (Day 3 - 6 hours)

#### Tab 3: Predict & Visualize Impacts

**Impact Prediction Algorithm:**

```r
# Predict impacts based on network propagation
predict_scenario_impacts <- function(scenario, cld_data) {
  # 1. Get adjacency matrix
  adj_matrix <- cld_data$adjacency_matrix

  # 2. Initialize impact vector (all elements start at baseline = 100)
  n_elements <- nrow(adj_matrix)
  element_names <- rownames(adj_matrix)
  impacts <- rep(100, n_elements)
  names(impacts) <- element_names

  # 3. Apply driver changes
  for (driver in scenario$drivers) {
    driver_idx <- which(element_names == driver$name)
    if (length(driver_idx) > 0) {
      impacts[driver_idx] <- driver$scenario
    }
  }

  # 4. Propagate through network (iterative)
  max_iterations <- 10
  convergence_threshold <- 1  # Stop if changes < 1%

  for (iter in 1:max_iterations) {
    old_impacts <- impacts

    # For each element, calculate influence from incoming connections
    for (i in 1:n_elements) {
      incoming <- adj_matrix[, i]  # Column i = incoming edges

      if (sum(incoming != 0) > 0) {
        # Weighted average of influencing elements
        influence <- sum(impacts * incoming) / sum(abs(incoming))

        # Damping factor (0.5 = 50% of influence propagates)
        impacts[i] <- 0.5 * impacts[i] + 0.5 * influence
      }
    }

    # Check convergence
    max_change <- max(abs(impacts - old_impacts))
    if (max_change < convergence_threshold) {
      break
    }
  }

  # 5. Apply response measure effects
  for (resp_id in scenario$responses) {
    response <- get_response_by_id(resp_id)

    # Apply response impacts (from impact assessment matrix)
    for (impact in response$impacts) {
      element_idx <- which(element_names == impact$element)
      if (length(element_idx) > 0) {
        # Multiply by effectiveness factor
        effectiveness_factor <- switch(
          impact$effect,
          "High Positive" = 1.2,
          "Medium Positive" = 1.1,
          "Low Positive" = 1.05,
          "Neutral" = 1.0,
          "Low Negative" = 0.95,
          "Medium Negative" = 0.9,
          "High Negative" = 0.8,
          1.0
        )

        impacts[element_idx] <- impacts[element_idx] * effectiveness_factor
      }
    }
  }

  # 6. Create results dataframe
  results <- data.frame(
    element_id = names(impacts),
    element_name = element_names,
    baseline_value = rep(100, n_elements),
    scenario_value = impacts,
    change_percent = impacts - 100,
    stringsAsFactors = FALSE
  )

  return(results)
}
```

**UI for Results:**

```r
# Run prediction button
actionButton("run_prediction", "Predict Impacts", class = "btn-success btn-lg", icon = icon("play"))

# Results tabs
tabsetPanel(
  tabPanel("Impact Table",
    DTOutput("impact_results_table")
  ),

  tabPanel("Impact Visualization",
    plotlyOutput("impact_bar_chart")
  ),

  tabPanel("Network View",
    visNetworkOutput("impact_network", height = "600px")
  )
)
```

**Server Logic:**

```r
observeEvent(input$run_prediction, {
  scenario <- current_scenario()
  req(scenario)

  # Show progress
  showNotification("Predicting impacts...", id = "prediction", duration = NULL, type = "message")

  # Run prediction
  cld_data <- project_data()$data$cld
  impacts <- predict_scenario_impacts(scenario, cld_data)

  # Save to scenario
  scenario$impacts <- impacts
  scenario$modified_at <- Sys.time()

  scenario_list <- scenarios()
  scenario_list[[scenario$id]] <- scenario
  scenarios(scenario_list)
  current_scenario(scenario)

  # Update project data
  data <- project_data()
  data$data$scenarios <- scenarios()
  project_data(data)

  removeNotification("prediction")
  showNotification("Impact prediction complete", type = "message")
})

# Display results table
output$impact_results_table <- renderDT({
  scenario <- current_scenario()
  req(scenario, nrow(scenario$impacts) > 0)

  datatable(
    scenario$impacts,
    options = list(
      pageLength = 15,
      order = list(list(4, 'desc'))  # Sort by change %
    )
  ) %>%
    formatRound(columns = c("baseline_value", "scenario_value", "change_percent"), digits = 1) %>%
    formatStyle(
      "change_percent",
      backgroundColor = styleInterval(c(-10, 10), c("#f8d7da", "#fff", "#d4edda")),
      color = styleInterval(c(-5, 5), c("#721c24", "#000", "#155724"))
    )
})

# Impact bar chart
output$impact_bar_chart <- renderPlotly({
  scenario <- current_scenario()
  req(scenario, nrow(scenario$impacts) > 0)

  plot_ly(
    data = scenario$impacts,
    x = ~change_percent,
    y = ~reorder(element_name, change_percent),
    type = "bar",
    marker = list(
      color = ~change_percent,
      colorscale = list(c(0, "red"), c(0.5, "white"), c(1, "green")),
      cmin = -50,
      cmax = 50
    ),
    hovertemplate = paste(
      "<b>%{y}</b><br>",
      "Change: %{x:.1f}%<br>",
      "<extra></extra>"
    )
  ) %>%
    layout(
      title = paste("Scenario Impacts:", scenario$name),
      xaxis = list(title = "Change from Baseline (%)"),
      yaxis = list(title = ""),
      height = 600
    )
})

# Network visualization with impacts
output$impact_network <- renderVisNetwork({
  scenario <- current_scenario()
  req(scenario, nrow(scenario$impacts) > 0)

  cld_data <- project_data()$data$cld

  # Color nodes by impact
  nodes <- cld_data$nodes
  nodes <- merge(nodes, scenario$impacts[, c("element_id", "change_percent")],
                 by.x = "id", by.y = "element_id", all.x = TRUE)

  nodes$color.background <- sapply(nodes$change_percent, function(change) {
    if (is.na(change)) return("#CCCCCC")
    if (change > 10) return("#28a745")
    if (change < -10) return("#dc3545")
    return("#ffc107")
  })

  visNetwork(nodes, cld_data$edges) %>%
    visOptions(highlightNearest = TRUE) %>%
    visLegend()
})
```

---

### Phase 4: Scenario Comparison (Day 4-5 - 7 hours)

#### Tab 4: Compare Multiple Scenarios

**UI:**
```r
# Scenario selector
selectInput("compare_scenarios",
            "Select scenarios to compare:",
            choices = NULL,
            multiple = TRUE,
            selected = NULL)

# Comparison views
tabsetPanel(
  tabPanel("Side-by-Side",
    DTOutput("comparison_table")
  ),

  tabPanel("Chart Comparison",
    plotlyOutput("comparison_chart")
  ),

  tabPanel("Radar Chart",
    plotlyOutput("radar_comparison")
  )
)

# Export
downloadButton("export_comparison", "Export Comparison", class = "btn-info")
```

**Server Logic:**

```r
# Update scenario choices
observe({
  scenario_list <- scenarios()
  choices <- setNames(
    names(scenario_list),
    sapply(scenario_list, function(s) s$name)
  )
  updateSelectInput(session, "compare_scenarios", choices = choices)
})

# Comparison table
output$comparison_table <- renderDT({
  req(input$compare_scenarios)

  # Get selected scenarios
  scenario_list <- scenarios()
  selected <- scenario_list[input$compare_scenarios]

  # Build comparison dataframe
  all_elements <- unique(unlist(lapply(selected, function(s) s$impacts$element_name)))

  comparison <- data.frame(
    Element = all_elements,
    stringsAsFactors = FALSE
  )

  for (scenario in selected) {
    col_name <- scenario$name
    values <- scenario$impacts$change_percent[match(all_elements, scenario$impacts$element_name)]
    comparison[[col_name]] <- values
  }

  datatable(comparison, options = list(pageLength = 20)) %>%
    formatRound(columns = 2:ncol(comparison), digits = 1)
})

# Comparison chart
output$comparison_chart <- renderPlotly({
  req(input$compare_scenarios)

  scenario_list <- scenarios()
  selected <- scenario_list[input$compare_scenarios]

  # Combine all impacts
  combined <- do.call(rbind, lapply(selected, function(s) {
    s$impacts$scenario_name <- s$name
    s$impacts
  }))

  plot_ly(data = combined,
          x = ~element_name,
          y = ~change_percent,
          color = ~scenario_name,
          type = "bar",
          hovertemplate = "%{y:.1f}%") %>%
    layout(
      barmode = "group",
      title = "Scenario Comparison",
      xaxis = list(title = ""),
      yaxis = list(title = "Change from Baseline (%)")
    )
})
```

---

## Integration with app.R

```r
# In app.R, add tab item:
tabItem(tabName = "response_scenarios",
        scenario_builder_ui("scenario_mod"))

# In server:
scenario_builder_server("scenario_mod", project_data)
```

---

## Testing Checklist

- [ ] Create new scenario
- [ ] Edit scenario name/description
- [ ] Duplicate scenario
- [ ] Delete scenario
- [ ] Adjust driver values
- [ ] Select response measures
- [ ] Run impact prediction
- [ ] View results in table
- [ ] View results in bar chart
- [ ] View results in network
- [ ] Compare 2+ scenarios
- [ ] Export comparison to Excel
- [ ] Save/load project with scenarios

---

## Dependencies

**R Packages:**
- `shiny`, `shinydashboard` - UI framework
- `DT` - Interactive tables
- `plotly` - Interactive charts
- `visNetwork` - Network visualization
- `openxlsx` - Excel export

**Data Requirements:**
- CLD adjacency matrix
- Driver list
- Response measures with impact assessments

---

## Next Steps

1. Create `modules/scenario_builder_module.R` file
2. Implement Phase 1 (Scenario Management)
3. Test CRUD operations
4. Implement Phase 2 (Configuration)
5. Test driver/response selection
6. Implement Phase 3 (Prediction)
7. Validate prediction algorithm
8. Implement Phase 4 (Comparison)
9. Integration testing
10. User acceptance testing

---

**Estimated Timeline:** 4-5 days (25 hours total)
**Priority:** HIGH - Critical for decision support use case
**Status:** Ready for implementation

This guide provides a complete roadmap for implementing the Scenario Builder module. Follow the phases sequentially for best results.
