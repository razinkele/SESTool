library(shiny)

# Response and Validation Module
# Implements Response (as Measures) for complete DAPSI(W)R(M) framework
# Includes: Response Measures, Scenario Builder, Validation

# ============================================================================
# RESPONSE MEASURES MODULE
# ============================================================================

response_measures_ui <- function(id, i18n) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        create_module_header(ns, "Response Measures (R & M)", "Identify management interventions and policy responses to address system challenges.", "help_response", i18n)
      )
    ),

    hr(),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("response_tabs"),

          # Tab 1: Identify Response Measures ----
          tabPanel(i18n$t("Response Register"),
            h4(i18n$t("Management Measures and Policy Interventions")),
            p(i18n$t("Document responses to address pressures, activities, and drivers in your system.")),

            wellPanel(
              h5(i18n$t("Add Response Measure")),
              fluidRow(
                column(3,
                  textInput(ns("rm_name"), i18n$t("Response Name:"),
                           placeholder = i18n$t("e.g., Fishing quota reduction"))
                ),
                column(3,
                  selectInput(ns("rm_type"), i18n$t("Response Type:"),
                             choices = c("", i18n$t("Regulatory"), i18n$t("Economic"), i18n$t("Educational"),
                                       i18n$t("Technical"), i18n$t("Institutional"), i18n$t("Voluntary"), i18n$t("Mixed")))
                ),
                column(3,
                  selectInput(ns("rm_target"), i18n$t("Targets:"),
                             choices = c("", i18n$t("Drivers"), i18n$t("Activities"), i18n$t("Pressures"),
                                       i18n$t("State"), i18n$t("Multiple Levels")))
                ),
                column(3,
                  selectInput(ns("rm_status"), i18n$t("Implementation Status:"),
                             choices = c(i18n$t("Proposed"), i18n$t("Planned"), i18n$t("Implemented"),
                                       i18n$t("Partially Implemented"), i18n$t("Abandoned")))
                )
              ),
              fluidRow(
                column(6,
                  textAreaInput(ns("rm_description"), i18n$t("Description:"),
                               placeholder = i18n$t("What does this measure do?"),
                               rows = 3)
                ),
                column(6,
                  textAreaInput(ns("rm_mechanism"), i18n$t("Mechanism of Action:"),
                               placeholder = i18n$t("How will this intervention work?"),
                               rows = 3)
                )
              ),
              fluidRow(
                column(3,
                  textInput(ns("rm_target_element"), i18n$t("Target Element ID:"),
                           placeholder = "e.g., A001, D002")
                ),
                column(3,
                  selectInput(ns("rm_effectiveness"), i18n$t("Expected Effectiveness:"),
                             choices = c("", i18n$t("High"), i18n$t("Medium"), i18n$t("Low"), i18n$t("Unknown")))
                ),
                column(3,
                  selectInput(ns("rm_feasibility"), i18n$t("Feasibility:"),
                             choices = c("", i18n$t("High"), i18n$t("Medium"), i18n$t("Low")))
                ),
                column(3,
                  numericInput(ns("rm_cost"), i18n$t("Estimated Cost (relative):"),
                              value = 5, min = 1, max = 10)
                )
              ),
              fluidRow(
                column(6,
                  textAreaInput(ns("rm_stakeholders"), i18n$t("Responsible Stakeholders:"),
                               placeholder = i18n$t("Who implements this measure?"),
                               rows = 2)
                ),
                column(6,
                  textAreaInput(ns("rm_barriers"), i18n$t("Implementation Barriers:"),
                               placeholder = i18n$t("What obstacles exist?"),
                               rows = 2)
                )
              ),
              actionButton(ns("add_response"), i18n$t("Add Response Measure"),
                          icon = icon("plus"), class = "btn-success")
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Response Measures Register")),
                DTOutput(ns("response_table")),
                br(),
                actionButton(ns("delete_response"), i18n$t("Delete Selected"),
                            icon = icon("trash"), class = "btn-danger")
              )
            )
          ),

          # Tab 2: Impact Matrix ----
          tabPanel(i18n$t("Impact Assessment"),
            h4(i18n$t("Response Measure Impact Matrix")),
            p(i18n$t("Assess which measures address which problems in your system.")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Create Impact Linkage")),
                  fluidRow(
                    column(4,
                      selectInput(ns("impact_response"), i18n$t("Select Response:"),
                                 choices = NULL)
                    ),
                    column(4,
                      selectInput(ns("impact_problem"), i18n$t("Addresses Problem:"),
                                 choices = c("", i18n$t("Specific Pressure"), i18n$t("Specific Activity"),
                                           i18n$t("Specific Driver"), i18n$t("System-wide Issue")))
                    ),
                    column(4,
                      textInput(ns("impact_element_id"), i18n$t("Problem Element ID:"),
                               placeholder = "e.g., P001, A002")
                    )
                  ),
                  fluidRow(
                    column(4,
                      selectInput(ns("impact_strength"), i18n$t("Impact Strength:"),
                                 choices = c("", i18n$t("Strong"), i18n$t("Moderate"), i18n$t("Weak")))
                    ),
                    column(4,
                      selectInput(ns("impact_timeframe"), i18n$t("Timeframe:"),
                                 choices = c("", i18n$t("Immediate"), i18n$t("Short-term (1-3y)"),
                                           i18n$t("Medium-term (3-10y)"), i18n$t("Long-term (>10y)")))
                    ),
                    column(4,
                      br(),
                      actionButton(ns("add_impact"), i18n$t("Add Impact Link"),
                                  icon = icon("link"), class = "btn-primary")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Impact Matrix")),
                DTOutput(ns("impact_matrix_table"))
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Visual Impact Matrix")),
                  plotOutput(ns("impact_heatmap"), height = "500px")
                )
              )
            )
          ),

          # Tab 3: Prioritization ----
          tabPanel(i18n$t("Prioritization"),
            h4(i18n$t("Response Measure Prioritization")),
            p(i18n$t("Evaluate and rank measures based on effectiveness, feasibility, and cost.")),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("Prioritization Criteria Weighting")),
                  sliderInput(ns("weight_effectiveness"), i18n$t("Effectiveness Weight:"),
                             min = 0, max = 1, value = 0.4, step = 0.1),
                  sliderInput(ns("weight_feasibility"), i18n$t("Feasibility Weight:"),
                             min = 0, max = 1, value = 0.3, step = 0.1),
                  sliderInput(ns("weight_cost"), i18n$t("Cost Weight (inverse):"),
                             min = 0, max = 1, value = 0.3, step = 0.1),
                  actionButton(ns("calculate_priority"), i18n$t("Calculate Priority Scores"),
                              class = "btn-primary btn-block")
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("Priority Ranking")),
                  verbatimTextOutput(ns("priority_summary"))
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Prioritized Response Measures")),
                DTOutput(ns("priority_table"))
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("Effectiveness vs. Feasibility")),
                  plotOutput(ns("ef_plot"), height = "400px")
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("Cost vs. Expected Impact")),
                  plotOutput(ns("cost_impact_plot"), height = "400px")
                )
              )
            )
          ),

          # Tab 4: Implementation Planning ----
          tabPanel(i18n$t("Implementation Plan"),
            h4(i18n$t("Response Implementation Roadmap")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Add Implementation Milestone")),
                  fluidRow(
                    column(4,
                      selectInput(ns("impl_response"), i18n$t("Response Measure:"),
                                 choices = NULL)
                    ),
                    column(4,
                      textInput(ns("impl_milestone"), i18n$t("Milestone:"),
                               placeholder = i18n$t("e.g., Legislation passed"))
                    ),
                    column(4,
                      dateInput(ns("impl_date"), i18n$t("Target Date:"),
                               value = Sys.Date() + 365)
                    )
                  ),
                  fluidRow(
                    column(8,
                      textAreaInput(ns("impl_notes"), i18n$t("Notes/Actions Required:"),
                                   rows = 2)
                    ),
                    column(4,
                      selectInput(ns("impl_status"), i18n$t("Status:"),
                                 choices = c(i18n$t("Pending"), i18n$t("In Progress"), i18n$t("Completed"), i18n$t("Delayed"))),
                      br(),
                      actionButton(ns("add_milestone"), i18n$t("Add Milestone"),
                                  class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Implementation Timeline")),
                DTOutput(ns("implementation_table"))
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Gantt Chart (Simplified)")),
                  plotOutput(ns("gantt_plot"), height = "400px")
                )
              )
            )
          ),

          # Tab 5: Export ----
          tabPanel(i18n$t("Export"),
            h4(i18n$t("Export Response Analysis")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Download Response Documentation")),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_response_excel"),
                                    i18n$t("Download Response Data (Excel)"),
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_priority_report"),
                                    i18n$t("Download Priority Report (PDF)"),
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_implementation_plan"),
                                    i18n$t("Download Implementation Plan"),
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

response_measures_server <- function(id, project_data_reactive, i18n) {
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

      showNotification(i18n$t("Response measure added!"), type = "message")
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
        showNotification(i18n$t("Deleted response measure(s)"), type = "warning")
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
      showNotification(i18n$t("Impact linkage added!"), type = "message")
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
        plot(1, 1, type = "n", main = i18n$t("Add effectiveness and feasibility ratings"))
        return()
      }

      plot(feas_num[valid], eff_num[valid],
           xlim = c(0.5, 3.5), ylim = c(0.5, 3.5),
           xlab = i18n$t("Feasibility"), ylab = i18n$t("Effectiveness"),
           main = i18n$t("Response Measure Prioritization Matrix"),
           pch = 19, cex = 2, col = "#457B9D",
           xaxt = "n", yaxt = "n")

      axis(1, at = 1:3, labels = c(i18n$t("Low"), i18n$t("Medium"), i18n$t("High")))
      axis(2, at = 1:3, labels = c(i18n$t("Low"), i18n$t("Medium"), i18n$t("High")))

      abline(h = 2, v = 2, col = "gray", lty = 2)

      # Add labels
      text(feas_num[valid], eff_num[valid],
           measures$ID[valid], pos = 3, cex = 0.7)

      # Quadrant labels
      text(2.5, 2.5, i18n$t("High Priority\n(Effective & Feasible)"), cex = 0.9, col = "darkgreen")
      text(1.25, 2.5, i18n$t("Effective but\nDifficult"), cex = 0.9, col = "darkorange")
      text(2.5, 1.25, i18n$t("Easy but\nLimited Impact"), cex = 0.9, col = "darkorange")
      text(1.25, 1.25, i18n$t("Low Priority"), cex = 0.9, col = "darkred")
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

      showNotification(i18n$t("Milestone added!"), type = "message")
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

    create_help_observer(input, "help_response", "response_measures_help_title",
      tagList(
        h4(i18n$t("Completing DAPSI(W)R(M)")),
        p(i18n$t("Response measures (R) and Management measures (M) complete the DAPSI(W)R(M) framework by identifying interventions to address system problems.")),
        hr(),
        h5(i18n$t("Types of Response Measures")),
        tags$ul(
          tags$li(strong(i18n$t("Regulatory:")), i18n$t("Laws, quotas, protected areas, bans")),
          tags$li(strong(i18n$t("Economic:")), i18n$t("Taxes, subsidies, payments for ecosystem services")),
          tags$li(strong(i18n$t("Educational:")), i18n$t("Awareness campaigns, training, capacity building")),
          tags$li(strong(i18n$t("Technical:")), i18n$t("New technologies, best practices, innovation")),
          tags$li(strong(i18n$t("Institutional:")), i18n$t("Governance reforms, co-management, partnerships")),
          tags$li(strong(i18n$t("Voluntary:")), i18n$t("Certification, codes of conduct, stewardship"))
        ),
        hr(),
        h5(i18n$t("Intervention Points")),
        tags$ul(
          tags$li(strong(i18n$t("Drivers:")), i18n$t("Address root causes (most leverage but hardest)")),
          tags$li(strong(i18n$t("Activities:")), i18n$t("Regulate what people do (direct but may face resistance)")),
          tags$li(strong(i18n$t("Pressures:")), i18n$t("Mitigate impacts (symptomatic treatment)")),
          tags$li(strong(i18n$t("State:")), i18n$t("Restore ecosystems (expensive, slow)"))
        ),
        hr(),
        h5(i18n$t("Prioritization Criteria")),
        tags$ul(
          tags$li(strong(i18n$t("Effectiveness:")), i18n$t("Will it solve the problem?")),
          tags$li(strong(i18n$t("Feasibility:")), i18n$t("Can it be implemented (political, social, technical)?")),
          tags$li(strong(i18n$t("Cost:")), i18n$t("What resources are required?")),
          tags$li(strong(i18n$t("Timeframe:")), i18n$t("How quickly will it have effects?")),
          tags$li(strong(i18n$t("Co-benefits:")), i18n$t("Does it address multiple issues?"))
        ),
        hr(),
        p(em(i18n$t("Effective responses address feedback loops and leverage points identified in your ISA analysis.")))
      ), i18n)

    return(reactive({ response_data }))
  })
}

# ============================================================================
# SCENARIO BUILDER MODULE
# ============================================================================
# NOTE: Scenario Builder has been moved to dedicated file:
#       modules/scenario_builder_module.R
#
# The scenario_builder_ui() and scenario_builder_server() functions are now
# in that file and provide full implementation of:
# - Scenario management (create, edit, delete)
# - Network modifications (add/remove nodes and links)
# - Impact prediction and analysis
# - Scenario comparison
# ============================================================================

# ============================================================================
# VALIDATION MODULE (Placeholder - basic validation in ISA Exercise 12)
# ============================================================================

response_validation_ui <- function(id, i18n) {
  ns <- NS(id)
  fluidPage(
    h2(i18n$t("Model Validation")),
    p(i18n$t("Track validation activities and model confidence assessment.")),
    p(strong(i18n$t("Status:")), i18n$t("Basic validation tracking available in ISA Exercise 12. Advanced features coming soon."))
  )
}

response_validation_server <- function(id, project_data_reactive) {
  moduleServer(id, function(input, output, session) {
    # Placeholder
  })
}
