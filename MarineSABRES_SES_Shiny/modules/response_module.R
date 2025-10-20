# Response and Validation Module
# Implements Response (as Measures) for complete DAPSI(W)R(M) framework
# Includes: Response Measures, Scenario Builder, Validation

# ============================================================================
# RESPONSE MEASURES MODULE
# ============================================================================

response_measures_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          div(
            h3("Response Measures (R & M)"),
            p("Identify management interventions and policy responses to address system challenges.")
          ),
          div(style = "margin-top: 10px;",
            actionButton(ns("help_response"), "Response Guide",
                        icon = icon("question-circle"),
                        class = "btn btn-info btn-lg")
          )
        )
      )
    ),

    hr(),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("response_tabs"),

          # Tab 1: Identify Response Measures ----
          tabPanel("Response Register",
            h4("Management Measures and Policy Interventions"),
            p("Document responses to address pressures, activities, and drivers in your system."),

            wellPanel(
              h5("Add Response Measure"),
              fluidRow(
                column(3,
                  textInput(ns("rm_name"), "Response Name:",
                           placeholder = "e.g., Fishing quota reduction")
                ),
                column(3,
                  selectInput(ns("rm_type"), "Response Type:",
                             choices = c("", "Regulatory", "Economic", "Educational",
                                       "Technical", "Institutional", "Voluntary", "Mixed"))
                ),
                column(3,
                  selectInput(ns("rm_target"), "Targets:",
                             choices = c("", "Drivers", "Activities", "Pressures",
                                       "State", "Multiple Levels"))
                ),
                column(3,
                  selectInput(ns("rm_status"), "Implementation Status:",
                             choices = c("Proposed", "Planned", "Implemented",
                                       "Partially Implemented", "Abandoned"))
                )
              ),
              fluidRow(
                column(6,
                  textAreaInput(ns("rm_description"), "Description:",
                               placeholder = "What does this measure do?",
                               rows = 3)
                ),
                column(6,
                  textAreaInput(ns("rm_mechanism"), "Mechanism of Action:",
                               placeholder = "How will this intervention work?",
                               rows = 3)
                )
              ),
              fluidRow(
                column(3,
                  textInput(ns("rm_target_element"), "Target Element ID:",
                           placeholder = "e.g., A001, D002")
                ),
                column(3,
                  selectInput(ns("rm_effectiveness"), "Expected Effectiveness:",
                             choices = c("", "High", "Medium", "Low", "Unknown"))
                ),
                column(3,
                  selectInput(ns("rm_feasibility"), "Feasibility:",
                             choices = c("", "High", "Medium", "Low"))
                ),
                column(3,
                  numericInput(ns("rm_cost"), "Estimated Cost (relative):",
                              value = 5, min = 1, max = 10)
                )
              ),
              fluidRow(
                column(6,
                  textAreaInput(ns("rm_stakeholders"), "Responsible Stakeholders:",
                               placeholder = "Who implements this measure?",
                               rows = 2)
                ),
                column(6,
                  textAreaInput(ns("rm_barriers"), "Implementation Barriers:",
                               placeholder = "What obstacles exist?",
                               rows = 2)
                )
              ),
              actionButton(ns("add_response"), "Add Response Measure",
                          icon = icon("plus"), class = "btn-success")
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Response Measures Register"),
                DTOutput(ns("response_table")),
                br(),
                actionButton(ns("delete_response"), "Delete Selected",
                            icon = icon("trash"), class = "btn-danger")
              )
            )
          ),

          # Tab 2: Impact Matrix ----
          tabPanel("Impact Assessment",
            h4("Response Measure Impact Matrix"),
            p("Assess which measures address which problems in your system."),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Create Impact Linkage"),
                  fluidRow(
                    column(4,
                      selectInput(ns("impact_response"), "Select Response:",
                                 choices = NULL)
                    ),
                    column(4,
                      selectInput(ns("impact_problem"), "Addresses Problem:",
                                 choices = c("", "Specific Pressure", "Specific Activity",
                                           "Specific Driver", "System-wide Issue"))
                    ),
                    column(4,
                      textInput(ns("impact_element_id"), "Problem Element ID:",
                               placeholder = "e.g., P001, A002")
                    )
                  ),
                  fluidRow(
                    column(4,
                      selectInput(ns("impact_strength"), "Impact Strength:",
                                 choices = c("", "Strong", "Moderate", "Weak"))
                    ),
                    column(4,
                      selectInput(ns("impact_timeframe"), "Timeframe:",
                                 choices = c("", "Immediate", "Short-term (1-3y)",
                                           "Medium-term (3-10y)", "Long-term (>10y)"))
                    ),
                    column(4,
                      br(),
                      actionButton(ns("add_impact"), "Add Impact Link",
                                  icon = icon("link"), class = "btn-primary")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Impact Matrix"),
                DTOutput(ns("impact_matrix_table"))
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Visual Impact Matrix"),
                  plotOutput(ns("impact_heatmap"), height = "500px")
                )
              )
            )
          ),

          # Tab 3: Prioritization ----
          tabPanel("Prioritization",
            h4("Response Measure Prioritization"),
            p("Evaluate and rank measures based on effectiveness, feasibility, and cost."),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Prioritization Criteria Weighting"),
                  sliderInput(ns("weight_effectiveness"), "Effectiveness Weight:",
                             min = 0, max = 1, value = 0.4, step = 0.1),
                  sliderInput(ns("weight_feasibility"), "Feasibility Weight:",
                             min = 0, max = 1, value = 0.3, step = 0.1),
                  sliderInput(ns("weight_cost"), "Cost Weight (inverse):",
                             min = 0, max = 1, value = 0.3, step = 0.1),
                  actionButton(ns("calculate_priority"), "Calculate Priority Scores",
                              class = "btn-primary btn-block")
                )
              ),
              column(6,
                wellPanel(
                  h5("Priority Ranking"),
                  verbatimTextOutput(ns("priority_summary"))
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Prioritized Response Measures"),
                DTOutput(ns("priority_table"))
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Effectiveness vs. Feasibility"),
                  plotOutput(ns("ef_plot"), height = "400px")
                )
              ),
              column(6,
                wellPanel(
                  h5("Cost vs. Expected Impact"),
                  plotOutput(ns("cost_impact_plot"), height = "400px")
                )
              )
            )
          ),

          # Tab 4: Implementation Planning ----
          tabPanel("Implementation Plan",
            h4("Response Implementation Roadmap"),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Add Implementation Milestone"),
                  fluidRow(
                    column(4,
                      selectInput(ns("impl_response"), "Response Measure:",
                                 choices = NULL)
                    ),
                    column(4,
                      textInput(ns("impl_milestone"), "Milestone:",
                               placeholder = "e.g., Legislation passed")
                    ),
                    column(4,
                      dateInput(ns("impl_date"), "Target Date:",
                               value = Sys.Date() + 365)
                    )
                  ),
                  fluidRow(
                    column(8,
                      textAreaInput(ns("impl_notes"), "Notes/Actions Required:",
                                   rows = 2)
                    ),
                    column(4,
                      selectInput(ns("impl_status"), "Status:",
                                 choices = c("Pending", "In Progress", "Completed", "Delayed")),
                      br(),
                      actionButton(ns("add_milestone"), "Add Milestone",
                                  class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Implementation Timeline"),
                DTOutput(ns("implementation_table"))
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Gantt Chart (Simplified)"),
                  plotOutput(ns("gantt_plot"), height = "400px")
                )
              )
            )
          ),

          # Tab 5: Export ----
          tabPanel("Export",
            h4("Export Response Analysis"),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Download Response Documentation"),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_response_excel"),
                                    "Download Response Data (Excel)",
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_priority_report"),
                                    "Download Priority Report (PDF)",
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_implementation_plan"),
                                    "Download Implementation Plan",
                                    class = "btn-warning btn-block")
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

response_measures_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for response data
    response_data <- reactiveValues(
      measures = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Target = character(),
        Description = character(),
        Mechanism = character(),
        TargetElement = character(),
        Effectiveness = character(),
        Feasibility = character(),
        Cost = numeric(),
        Status = character(),
        Stakeholders = character(),
        Barriers = character(),
        DateAdded = character(),
        stringsAsFactors = FALSE
      ),
      impacts = data.frame(
        ResponseID = character(),
        ProblemType = character(),
        ProblemElementID = character(),
        ImpactStrength = character(),
        Timeframe = character(),
        stringsAsFactors = FALSE
      ),
      milestones = data.frame(
        ResponseID = character(),
        Milestone = character(),
        TargetDate = character(),
        Status = character(),
        Notes = character(),
        stringsAsFactors = FALSE
      ),
      counter = 0
    )

    # Add Response Measure ----
    observeEvent(input$add_response, {
      req(input$rm_name, input$rm_type)

      response_data$counter <- response_data$counter + 1
      new_id <- paste0("RM", sprintf("%03d", response_data$counter))

      new_row <- data.frame(
        ID = new_id,
        Name = input$rm_name,
        Type = input$rm_type,
        Target = input$rm_target,
        Description = input$rm_description,
        Mechanism = input$rm_mechanism,
        TargetElement = input$rm_target_element,
        Effectiveness = input$rm_effectiveness,
        Feasibility = input$rm_feasibility,
        Cost = input$rm_cost,
        Status = input$rm_status,
        Stakeholders = input$rm_stakeholders,
        Barriers = input$rm_barriers,
        DateAdded = as.character(Sys.Date()),
        stringsAsFactors = FALSE
      )

      response_data$measures <- rbind(response_data$measures, new_row)

      # Clear inputs
      updateTextInput(session, "rm_name", value = "")
      updateTextAreaInput(session, "rm_description", value = "")
      updateTextAreaInput(session, "rm_mechanism", value = "")
      updateTextInput(session, "rm_target_element", value = "")
      updateTextAreaInput(session, "rm_stakeholders", value = "")
      updateTextAreaInput(session, "rm_barriers", value = "")

      showNotification("Response measure added!", type = "message")
    })

    # Response Table ----
    output$response_table <- renderDT({
      datatable(response_data$measures,
               selection = 'multiple',
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Delete Response ----
    observeEvent(input$delete_response, {
      selected <- input$response_table_rows_selected
      if(!is.null(selected) && length(selected) > 0) {
        response_data$measures <- response_data$measures[-selected, ]
        showNotification("Deleted response measure(s)", type = "warning")
      }
    })

    # Update dropdowns ----
    observe({
      req(response_data$measures)
      if(nrow(response_data$measures) > 0) {
        choices <- setNames(response_data$measures$ID,
                           paste0(response_data$measures$ID, ": ", response_data$measures$Name))
        updateSelectInput(session, "impact_response", choices = c("", choices))
        updateSelectInput(session, "impl_response", choices = c("", choices))
      } else {
        updateSelectInput(session, "impact_response", choices = c(""))
        updateSelectInput(session, "impl_response", choices = c(""))
      }
    })

    # Add Impact Linkage ----
    observeEvent(input$add_impact, {
      req(input$impact_response, input$impact_problem)

      new_row <- data.frame(
        ResponseID = input$impact_response,
        ProblemType = input$impact_problem,
        ProblemElementID = input$impact_element_id,
        ImpactStrength = input$impact_strength,
        Timeframe = input$impact_timeframe,
        stringsAsFactors = FALSE
      )

      response_data$impacts <- rbind(response_data$impacts, new_row)
      showNotification("Impact linkage added!", type = "message")
    })

    # Impact Matrix Table ----
    output$impact_matrix_table <- renderDT({
      datatable(response_data$impacts,
               options = list(pageLength = 10),
               rownames = FALSE)
    })

    # Priority Table with Scoring ----
    output$priority_table <- renderDT({
      req(response_data$measures)

      measures <- response_data$measures

      # Convert to numeric scores
      measures$EffScore <- ifelse(measures$Effectiveness == "High", 3,
                                  ifelse(measures$Effectiveness == "Medium", 2,
                                        ifelse(measures$Effectiveness == "Low", 1, 0)))

      measures$FeasScore <- ifelse(measures$Feasibility == "High", 3,
                                   ifelse(measures$Feasibility == "Medium", 2,
                                         ifelse(measures$Feasibility == "Low", 1, 0)))

      measures$CostScore <- (11 - measures$Cost) / 10  # Inverse cost

      # Calculate weighted priority
      w_e <- input$weight_effectiveness
      w_f <- input$weight_feasibility
      w_c <- input$weight_cost

      measures$PriorityScore <- (w_e * measures$EffScore / 3) +
                                (w_f * measures$FeasScore / 3) +
                                (w_c * measures$CostScore)

      measures <- measures[order(-measures$PriorityScore), ]
      measures$Rank <- 1:nrow(measures)

      datatable(measures[, c("Rank", "ID", "Name", "Type", "Target",
                            "Effectiveness", "Feasibility", "Cost",
                            "PriorityScore", "Status")],
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE) %>%
        formatRound("PriorityScore", 3)
    })

    # Effectiveness vs Feasibility Plot ----
    output$ef_plot <- renderPlot({
      req(nrow(response_data$measures) > 0)

      measures <- response_data$measures

      eff_num <- ifelse(measures$Effectiveness == "High", 3,
                       ifelse(measures$Effectiveness == "Medium", 2,
                             ifelse(measures$Effectiveness == "Low", 1, NA)))

      feas_num <- ifelse(measures$Feasibility == "High", 3,
                        ifelse(measures$Feasibility == "Medium", 2,
                              ifelse(measures$Feasibility == "Low", 1, NA)))

      valid <- !is.na(eff_num) & !is.na(feas_num)

      if(sum(valid) == 0) {
        plot(1, 1, type = "n", main = "Add effectiveness and feasibility ratings")
        return()
      }

      plot(feas_num[valid], eff_num[valid],
           xlim = c(0.5, 3.5), ylim = c(0.5, 3.5),
           xlab = "Feasibility", ylab = "Effectiveness",
           main = "Response Measure Prioritization Matrix",
           pch = 19, cex = 2, col = "#457B9D",
           xaxt = "n", yaxt = "n")

      axis(1, at = 1:3, labels = c("Low", "Medium", "High"))
      axis(2, at = 1:3, labels = c("Low", "Medium", "High"))

      abline(h = 2, v = 2, col = "gray", lty = 2)

      # Add labels
      text(feas_num[valid], eff_num[valid],
           measures$ID[valid], pos = 3, cex = 0.7)

      # Quadrant labels
      text(2.5, 2.5, "High Priority\n(Effective & Feasible)", cex = 0.9, col = "darkgreen")
      text(1.25, 2.5, "Effective but\nDifficult", cex = 0.9, col = "darkorange")
      text(2.5, 1.25, "Easy but\nLimited Impact", cex = 0.9, col = "darkorange")
      text(1.25, 1.25, "Low Priority", cex = 0.9, col = "darkred")
    })

    # Add Milestone ----
    observeEvent(input$add_milestone, {
      req(input$impl_response, input$impl_milestone)

      new_row <- data.frame(
        ResponseID = input$impl_response,
        Milestone = input$impl_milestone,
        TargetDate = as.character(input$impl_date),
        Status = input$impl_status,
        Notes = input$impl_notes,
        stringsAsFactors = FALSE
      )

      response_data$milestones <- rbind(response_data$milestones, new_row)

      updateTextInput(session, "impl_milestone", value = "")
      updateTextAreaInput(session, "impl_notes", value = "")

      showNotification("Milestone added!", type = "message")
    })

    # Implementation Table ----
    output$implementation_table <- renderDT({
      datatable(response_data$milestones,
               options = list(pageLength = 10),
               rownames = FALSE)
    })

    # Download Handler ----
    output$download_response_excel <- downloadHandler(
      filename = function() {
        paste0("Response_Measures_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        wb <- createWorkbook()
        addWorksheet(wb, "Response_Measures")
        addWorksheet(wb, "Impact_Matrix")
        addWorksheet(wb, "Implementation")

        writeData(wb, "Response_Measures", response_data$measures)
        writeData(wb, "Impact_Matrix", response_data$impacts)
        writeData(wb, "Implementation", response_data$milestones)

        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    # Help Modal ----
    observeEvent(input$help_response, {
      showModal(modalDialog(
        title = "Response Measures Guide",
        size = "l",
        easyClose = TRUE,

        h4("Completing DAPSI(W)R(M)"),
        p("Response measures (R) and Management measures (M) complete the DAPSI(W)R(M) framework by identifying interventions to address system problems."),

        hr(),
        h5("Types of Response Measures"),

        tags$ul(
          tags$li(strong("Regulatory:"), "Laws, quotas, protected areas, bans"),
          tags$li(strong("Economic:"), "Taxes, subsidies, payments for ecosystem services"),
          tags$li(strong("Educational:"), "Awareness campaigns, training, capacity building"),
          tags$li(strong("Technical:"), "New technologies, best practices, innovation"),
          tags$li(strong("Institutional:"), "Governance reforms, co-management, partnerships"),
          tags$li(strong("Voluntary:"), "Certification, codes of conduct, stewardship")
        ),

        hr(),
        h5("Intervention Points"),

        tags$ul(
          tags$li(strong("Drivers:"), "Address root causes (most leverage but hardest)"),
          tags$li(strong("Activities:"), "Regulate what people do (direct but may face resistance)"),
          tags$li(strong("Pressures:"), "Mitigate impacts (symptomatic treatment)"),
          tags$li(strong("State:"), "Restore ecosystems (expensive, slow)")
        ),

        hr(),
        h5("Prioritization Criteria"),

        tags$ul(
          tags$li(strong("Effectiveness:"), "Will it solve the problem?"),
          tags$li(strong("Feasibility:"), "Can it be implemented (political, social, technical)?"),
          tags$li(strong("Cost:"), "What resources are required?"),
          tags$li(strong("Timeframe:"), "How quickly will it have effects?"),
          tags$li(strong("Co-benefits:"), "Does it address multiple issues?")
        ),

        hr(),
        p(em("Effective responses address feedback loops and leverage points identified in your ISA analysis.")),

        footer = modalButton("Close")
      ))
    })

    return(reactive({ response_data }))
  })
}

# ============================================================================
# SCENARIO BUILDER MODULE (Placeholder)
# ============================================================================

response_scenarios_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("Scenario Builder"),
    p("Create 'what-if' scenarios to explore effects of different response measures."),
    p(strong("Status:"), "Implementation in progress. Requires Response Measures module to be populated first.")
  )
}

response_scenarios_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    # Placeholder
  })
}

# ============================================================================
# VALIDATION MODULE (Placeholder - basic validation in ISA Exercise 12)
# ============================================================================

response_validation_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("Model Validation"),
    p("Track validation activities and model confidence assessment."),
    p(strong("Status:"), "Basic validation tracking available in ISA Exercise 12. Advanced features coming soon.")
  )
}

response_validation_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    # Placeholder
  })
}
