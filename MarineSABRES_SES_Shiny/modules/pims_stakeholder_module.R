# PIMS Stakeholder Management Module
# Process and Information Management System - Stakeholder Identification and Engagement
# Based on MarineSABRES Simple SES DRAFT Guidance

# Module UI ----
pimsStakeholderUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          div(
            h3("PIMS: Stakeholder Identification and Engagement"),
            p("Identify, analyze, and manage stakeholders for your marine social-ecological system project.")
          ),
          div(style = "margin-top: 10px;",
            actionButton(ns("help_stakeholder"), "Stakeholder Guide",
                        icon = icon("question-circle"),
                        class = "btn btn-info btn-lg")
          )
        )
      )
    ),

    hr(),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("stakeholder_tabs"),

          # Tab 1: Stakeholder Register ----
          tabPanel("Stakeholder Register",
            h4("Stakeholder Identification"),
            p("Identify all stakeholders relevant to your marine case study. Stakeholders include anyone affected by or who can affect the system."),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Add New Stakeholder"),
                  fluidRow(
                    column(3,
                      textInput(ns("sh_name"), "Stakeholder Name/Organization:",
                               placeholder = "e.g., Local Fishers Association")
                    ),
                    column(3,
                      selectInput(ns("sh_type"), "Stakeholder Type:",
                                 choices = c("", "Resource Users", "Industry/Business",
                                           "Government/Regulators", "NGO/Civil Society",
                                           "Scientific/Academic", "Local Communities",
                                           "Indigenous Groups", "Other"))
                    ),
                    column(3,
                      selectInput(ns("sh_sector"), "Primary Sector:",
                                 choices = c("", "Fisheries", "Aquaculture", "Tourism",
                                           "Shipping", "Energy", "Conservation",
                                           "Research", "Policy/Management", "Multiple", "Other"))
                    ),
                    column(3,
                      textInput(ns("sh_contact"), "Contact Person/Details:",
                               placeholder = "Name, email, phone")
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("sh_interests"), "Key Interests/Concerns:",
                                   placeholder = "What does this stakeholder care about in the marine system?",
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("sh_role"), "Role in System:",
                                   placeholder = "What is their role? Decision-maker, user, affected party, etc.",
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(3,
                      selectInput(ns("sh_power"), "Power/Influence:",
                                 choices = c("", "High", "Medium", "Low"),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_interest"), "Interest/Impact:",
                                 choices = c("", "High", "Medium", "Low"),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_attitude"), "Current Attitude:",
                                 choices = c("", "Supportive", "Neutral", "Resistant", "Unknown"),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_engagement_level"), "Engagement Level:",
                                 choices = c("", "Inform", "Consult", "Involve", "Collaborate", "Empower"),
                                 selected = "")
                    )
                  ),
                  actionButton(ns("add_stakeholder"), "Add Stakeholder",
                              icon = icon("plus"), class = "btn-success")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Stakeholder Register"),
                DTOutput(ns("stakeholder_table")),
                br(),
                actionButton(ns("delete_selected"), "Delete Selected",
                            icon = icon("trash"), class = "btn-danger")
              )
            )
          ),

          # Tab 2: Power-Interest Grid ----
          tabPanel("Power-Interest Analysis",
            h4("Stakeholder Power-Interest Grid"),
            p("Visualize stakeholders based on their power/influence and level of interest/impact. This helps prioritize engagement strategies."),

            wellPanel(
              h5("Power-Interest Grid Classification"),
              tags$ul(
                tags$li(strong("High Power, High Interest (Key Players):"),
                       "Engage closely and make greatest efforts to satisfy"),
                tags$li(strong("High Power, Low Interest (Keep Satisfied):"),
                       "Keep satisfied but avoid excessive communication"),
                tags$li(strong("Low Power, High Interest (Keep Informed):"),
                       "Keep informed and talk to regarding their interests"),
                tags$li(strong("Low Power, Low Interest (Monitor):"),
                       "Monitor with minimum effort")
              )
            ),

            fluidRow(
              column(8,
                plotOutput(ns("power_interest_plot"), height = "600px", click = ns("plot_click"))
              ),
              column(4,
                wellPanel(
                  h5("Grid Summary"),
                  verbatimTextOutput(ns("grid_summary")),
                  hr(),
                  h5("Clicked Stakeholder"),
                  verbatimTextOutput(ns("clicked_stakeholder"))
                )
              )
            )
          ),

          # Tab 3: Engagement Planning ----
          tabPanel("Engagement Planning",
            h4("Stakeholder Engagement Strategy"),
            p("Plan how to engage with each stakeholder group based on their power-interest classification."),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Define Engagement Activities"),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_stakeholder"), "Select Stakeholder:",
                                 choices = NULL)
                    ),
                    column(4,
                      selectInput(ns("eng_method"), "Engagement Method:",
                                 choices = c("", "Workshop", "Interview", "Survey", "Focus Group",
                                           "Public Meeting", "Advisory Committee", "Email/Newsletter",
                                           "One-on-One Meeting", "Site Visit", "Other"))
                    ),
                    column(4,
                      dateInput(ns("eng_date"), "Planned/Completed Date:",
                               value = Sys.Date())
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("eng_objectives"), "Engagement Objectives:",
                                   placeholder = "What do you want to achieve?",
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("eng_outcomes"), "Outcomes/Notes:",
                                   placeholder = "What was achieved or learned?",
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_status"), "Status:",
                                 choices = c("Planned", "Completed", "Cancelled", "Ongoing"))
                    ),
                    column(4,
                      textInput(ns("eng_facilitator"), "Facilitator/Contact:",
                               placeholder = "Who is leading this?")
                    ),
                    column(4,
                      br(),
                      actionButton(ns("add_engagement"), "Add Activity",
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Engagement Activities Log"),
                DTOutput(ns("engagement_table"))
              )
            )
          ),

          # Tab 4: Communication Plan ----
          tabPanel("Communication Plan",
            h4("Stakeholder Communication and Impact Management"),
            p("Plan and track communications with stakeholders to ensure effective information flow."),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Add Communication Item"),
                  fluidRow(
                    column(3,
                      selectInput(ns("comm_audience"), "Target Audience:",
                                 choices = c("", "All Stakeholders", "Key Players", "Government",
                                           "Industry", "NGOs", "Local Communities", "Scientific Community",
                                           "Specific Stakeholder"))
                    ),
                    column(3,
                      selectInput(ns("comm_type"), "Communication Type:",
                                 choices = c("", "Report", "Newsletter", "Presentation", "Website Update",
                                           "Press Release", "Social Media", "Email", "Meeting Notes", "Other"))
                    ),
                    column(3,
                      dateInput(ns("comm_date"), "Date:",
                               value = Sys.Date())
                    ),
                    column(3,
                      selectInput(ns("comm_frequency"), "Frequency:",
                                 choices = c("One-time", "Weekly", "Monthly", "Quarterly", "Annual", "As Needed"))
                    )
                  ),
                  fluidRow(
                    column(8,
                      textAreaInput(ns("comm_message"), "Key Message/Content:",
                                   placeholder = "What information is being communicated?",
                                   rows = 3)
                    ),
                    column(4,
                      textInput(ns("comm_responsible"), "Responsible Person:"),
                      br(),
                      actionButton(ns("add_communication"), "Add Communication",
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5("Communications Log"),
                DTOutput(ns("communication_table"))
              )
            )
          ),

          # Tab 5: Analysis & Reports ----
          tabPanel("Analysis & Reports",
            h4("Stakeholder Analysis Summary"),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Stakeholder Statistics"),
                  verbatimTextOutput(ns("stakeholder_stats"))
                )
              ),
              column(6,
                wellPanel(
                  h5("Engagement Coverage"),
                  plotOutput(ns("engagement_coverage"), height = "250px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5("Stakeholder Types Distribution"),
                  plotOutput(ns("type_distribution"), height = "300px")
                )
              ),
              column(6,
                wellPanel(
                  h5("Sector Distribution"),
                  plotOutput(ns("sector_distribution"), height = "300px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5("Export Stakeholder Data"),
                  p("Download stakeholder information for reporting and documentation."),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_stakeholder_report"), "Download Full Report (Excel)",
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_power_interest"), "Download Power-Interest Grid (PNG)",
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_summary"), "Download Summary (PDF)",
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

# Module Server ----
pimsStakeholderServer <- function(id, global_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values to store stakeholder data ----
    stakeholder_data <- reactiveValues(
      stakeholders = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Sector = character(),
        Contact = character(),
        Interests = character(),
        Role = character(),
        Power = character(),
        Interest = character(),
        Attitude = character(),
        EngagementLevel = character(),
        DateAdded = character(),
        stringsAsFactors = FALSE
      ),

      engagements = data.frame(
        ID = character(),
        StakeholderID = character(),
        StakeholderName = character(),
        Method = character(),
        Date = character(),
        Objectives = character(),
        Outcomes = character(),
        Status = character(),
        Facilitator = character(),
        stringsAsFactors = FALSE
      ),

      communications = data.frame(
        ID = character(),
        Audience = character(),
        Type = character(),
        Date = character(),
        Frequency = character(),
        Message = character(),
        Responsible = character(),
        stringsAsFactors = FALSE
      ),

      stakeholder_counter = 0,
      engagement_counter = 0,
      communication_counter = 0
    )

    # Add Stakeholder ----
    observeEvent(input$add_stakeholder, {
      req(input$sh_name, input$sh_type)

      stakeholder_data$stakeholder_counter <- stakeholder_data$stakeholder_counter + 1
      new_id <- paste0("SH", sprintf("%03d", stakeholder_data$stakeholder_counter))

      new_row <- data.frame(
        ID = new_id,
        Name = input$sh_name,
        Type = input$sh_type,
        Sector = input$sh_sector,
        Contact = input$sh_contact,
        Interests = input$sh_interests,
        Role = input$sh_role,
        Power = input$sh_power,
        Interest = input$sh_interest,
        Attitude = input$sh_attitude,
        EngagementLevel = input$sh_engagement_level,
        DateAdded = as.character(Sys.Date()),
        stringsAsFactors = FALSE
      )

      stakeholder_data$stakeholders <- rbind(stakeholder_data$stakeholders, new_row)

      # Clear inputs
      updateTextInput(session, "sh_name", value = "")
      updateSelectInput(session, "sh_type", selected = "")
      updateSelectInput(session, "sh_sector", selected = "")
      updateTextInput(session, "sh_contact", value = "")
      updateTextAreaInput(session, "sh_interests", value = "")
      updateTextAreaInput(session, "sh_role", value = "")
      updateSelectInput(session, "sh_power", selected = "")
      updateSelectInput(session, "sh_interest", selected = "")
      updateSelectInput(session, "sh_attitude", selected = "")
      updateSelectInput(session, "sh_engagement_level", selected = "")

      showNotification("Stakeholder added successfully!", type = "message")
    })

    # Stakeholder Table ----
    output$stakeholder_table <- renderDT({
      datatable(stakeholder_data$stakeholders,
               selection = 'multiple',
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Delete Selected Stakeholders ----
    observeEvent(input$delete_selected, {
      selected_rows <- input$stakeholder_table_rows_selected
      if (!is.null(selected_rows) && length(selected_rows) > 0) {
        stakeholder_data$stakeholders <- stakeholder_data$stakeholders[-selected_rows, ]
        showNotification(paste("Deleted", length(selected_rows), "stakeholder(s)"), type = "warning")
      } else {
        showNotification("No stakeholders selected", type = "error")
      }
    })

    # Update Stakeholder Dropdown ----
    observe({
      choices <- c("", setNames(stakeholder_data$stakeholders$ID,
                                stakeholder_data$stakeholders$Name))
      updateSelectInput(session, "eng_stakeholder", choices = choices)
    })

    # Power-Interest Grid Plot ----
    output$power_interest_plot <- renderPlot({
      req(nrow(stakeholder_data$stakeholders) > 0)

      df <- stakeholder_data$stakeholders
      df$PowerNum <- ifelse(df$Power == "High", 3,
                           ifelse(df$Power == "Medium", 2,
                                 ifelse(df$Power == "Low", 1, NA)))
      df$InterestNum <- ifelse(df$Interest == "High", 3,
                              ifelse(df$Interest == "Medium", 2,
                                    ifelse(df$Interest == "Low", 1, NA)))

      df <- df[!is.na(df$PowerNum) & !is.na(df$InterestNum), ]

      if(nrow(df) == 0) {
        plot(1, 1, type = "n", xlab = "Interest/Impact", ylab = "Power/Influence",
             main = "Power-Interest Grid\n(Add stakeholders with Power and Interest ratings to see visualization)",
             xlim = c(0.5, 3.5), ylim = c(0.5, 3.5))
        return()
      }

      # Add jitter to avoid overlap
      df$PowerNum <- jitter(df$PowerNum, amount = 0.15)
      df$InterestNum <- jitter(df$InterestNum, amount = 0.15)

      plot(df$InterestNum, df$PowerNum,
           xlim = c(0.5, 3.5), ylim = c(0.5, 3.5),
           xlab = "Interest/Impact →",
           ylab = "Power/Influence →",
           main = "Stakeholder Power-Interest Grid",
           pch = 19, cex = 2, col = "#2E86AB",
           xaxt = "n", yaxt = "n",
           cex.lab = 1.2, cex.main = 1.5)

      # Grid lines
      abline(h = 2, v = 2, col = "gray30", lwd = 2, lty = 2)

      # Quadrant labels
      text(1.25, 2.75, "Keep Satisfied\n(High Power, Low Interest)", cex = 1.1, col = "gray30")
      text(2.75, 2.75, "Key Players\n(High Power, High Interest)", cex = 1.1, col = "gray30", font = 2)
      text(1.25, 1.25, "Monitor\n(Low Power, Low Interest)", cex = 1.1, col = "gray30")
      text(2.75, 1.25, "Keep Informed\n(Low Power, High Interest)", cex = 1.1, col = "gray30")

      # Axes
      axis(1, at = 1:3, labels = c("Low", "Medium", "High"))
      axis(2, at = 1:3, labels = c("Low", "Medium", "High"))

      # Add stakeholder labels
      text(df$InterestNum, df$PowerNum, df$Name, pos = 3, cex = 0.8, offset = 0.5)

      # Add grid background
      rect(0.5, 0.5, 2, 2, col = rgb(0.9, 0.9, 0.9, 0.3), border = NA)
      rect(2, 0.5, 3.5, 2, col = rgb(0.8, 0.9, 1, 0.3), border = NA)
      rect(0.5, 2, 2, 3.5, col = rgb(1, 0.95, 0.8, 0.3), border = NA)
      rect(2, 2, 3.5, 3.5, col = rgb(0.8, 1, 0.8, 0.3), border = NA)

      # Redraw points on top
      points(df$InterestNum, df$PowerNum, pch = 19, cex = 2, col = "#2E86AB")
      text(df$InterestNum, df$PowerNum, df$Name, pos = 3, cex = 0.8, offset = 0.5)
    })

    # Grid Summary ----
    output$grid_summary <- renderText({
      req(nrow(stakeholder_data$stakeholders) > 0)

      df <- stakeholder_data$stakeholders
      key_players <- sum(df$Power == "High" & df$Interest == "High", na.rm = TRUE)
      keep_satisfied <- sum(df$Power == "High" & df$Interest == "Low", na.rm = TRUE)
      keep_informed <- sum(df$Power == "Low" & df$Interest == "High", na.rm = TRUE)
      monitor <- sum(df$Power == "Low" & df$Interest == "Low", na.rm = TRUE)

      paste0(
        "Total Stakeholders: ", nrow(df), "\n\n",
        "Key Players: ", key_players, "\n",
        "Keep Satisfied: ", keep_satisfied, "\n",
        "Keep Informed: ", keep_informed, "\n",
        "Monitor: ", monitor
      )
    })

    # Clicked Stakeholder Info ----
    output$clicked_stakeholder <- renderText({
      req(input$plot_click, nrow(stakeholder_data$stakeholders) > 0)

      df <- stakeholder_data$stakeholders
      df$PowerNum <- ifelse(df$Power == "High", 3,
                           ifelse(df$Power == "Medium", 2,
                                 ifelse(df$Power == "Low", 1, NA)))
      df$InterestNum <- ifelse(df$Interest == "High", 3,
                              ifelse(df$Interest == "Medium", 2,
                                    ifelse(df$Interest == "Low", 1, NA)))

      df <- df[!is.na(df$PowerNum) & !is.na(df$InterestNum), ]

      if(nrow(df) == 0) return("No data")

      # Find nearest point
      distances <- sqrt((df$InterestNum - input$plot_click$x)^2 +
                       (df$PowerNum - input$plot_click$y)^2)
      nearest <- which.min(distances)

      if(distances[nearest] > 0.5) return("Click on a point")

      sh <- df[nearest, ]
      paste0(
        "Name: ", sh$Name, "\n",
        "Type: ", sh$Type, "\n",
        "Sector: ", sh$Sector, "\n",
        "Power: ", sh$Power, "\n",
        "Interest: ", sh$Interest, "\n",
        "Attitude: ", sh$Attitude, "\n\n",
        "Key Interests:\n", sh$Interests
      )
    })

    # Add Engagement Activity ----
    observeEvent(input$add_engagement, {
      req(input$eng_stakeholder, input$eng_method)

      stakeholder_data$engagement_counter <- stakeholder_data$engagement_counter + 1
      new_id <- paste0("ENG", sprintf("%03d", stakeholder_data$engagement_counter))

      sh_name <- stakeholder_data$stakeholders$Name[stakeholder_data$stakeholders$ID == input$eng_stakeholder]

      new_row <- data.frame(
        ID = new_id,
        StakeholderID = input$eng_stakeholder,
        StakeholderName = sh_name,
        Method = input$eng_method,
        Date = as.character(input$eng_date),
        Objectives = input$eng_objectives,
        Outcomes = input$eng_outcomes,
        Status = input$eng_status,
        Facilitator = input$eng_facilitator,
        stringsAsFactors = FALSE
      )

      stakeholder_data$engagements <- rbind(stakeholder_data$engagements, new_row)

      # Clear inputs
      updateTextAreaInput(session, "eng_objectives", value = "")
      updateTextAreaInput(session, "eng_outcomes", value = "")
      updateTextInput(session, "eng_facilitator", value = "")

      showNotification("Engagement activity added!", type = "message")
    })

    # Engagement Table ----
    output$engagement_table <- renderDT({
      datatable(stakeholder_data$engagements,
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Add Communication ----
    observeEvent(input$add_communication, {
      req(input$comm_audience, input$comm_type)

      stakeholder_data$communication_counter <- stakeholder_data$communication_counter + 1
      new_id <- paste0("COMM", sprintf("%03d", stakeholder_data$communication_counter))

      new_row <- data.frame(
        ID = new_id,
        Audience = input$comm_audience,
        Type = input$comm_type,
        Date = as.character(input$comm_date),
        Frequency = input$comm_frequency,
        Message = input$comm_message,
        Responsible = input$comm_responsible,
        stringsAsFactors = FALSE
      )

      stakeholder_data$communications <- rbind(stakeholder_data$communications, new_row)

      # Clear inputs
      updateTextAreaInput(session, "comm_message", value = "")
      updateTextInput(session, "comm_responsible", value = "")

      showNotification("Communication added!", type = "message")
    })

    # Communication Table ----
    output$communication_table <- renderDT({
      datatable(stakeholder_data$communications,
               options = list(pageLength = 10, scrollX = TRUE),
               rownames = FALSE)
    })

    # Statistics ----
    output$stakeholder_stats <- renderText({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) return("No stakeholders added yet")

      paste0(
        "Total Stakeholders: ", nrow(df), "\n",
        "Stakeholder Types: ", length(unique(df$Type)), "\n",
        "Sectors Represented: ", length(unique(df$Sector)), "\n",
        "High Power Stakeholders: ", sum(df$Power == "High", na.rm = TRUE), "\n",
        "High Interest Stakeholders: ", sum(df$Interest == "High", na.rm = TRUE), "\n",
        "Total Engagements: ", nrow(stakeholder_data$engagements), "\n",
        "Total Communications: ", nrow(stakeholder_data$communications)
      )
    })

    # Engagement Coverage Plot ----
    output$engagement_coverage <- renderPlot({
      df_sh <- stakeholder_data$stakeholders
      df_eng <- stakeholder_data$engagements

      if(nrow(df_sh) == 0) {
        plot(1, 1, type = "n", main = "Add stakeholders to see coverage")
        return()
      }

      engaged_ids <- unique(df_eng$StakeholderID)
      coverage <- sum(df_sh$ID %in% engaged_ids) / nrow(df_sh) * 100

      barplot(c(coverage, 100 - coverage),
              names.arg = c("Engaged", "Not Engaged"),
              col = c("#2E86AB", "#CCCCCC"),
              main = paste0("Stakeholder Engagement Coverage (", round(coverage, 1), "%)"),
              ylab = "Percentage",
              ylim = c(0, 100))
    })

    # Type Distribution ----
    output$type_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = "Add stakeholders to see distribution")
        return()
      }

      type_counts <- table(df$Type)
      barplot(type_counts,
              main = "Stakeholders by Type",
              ylab = "Count",
              col = "#A23B72",
              las = 2,
              cex.names = 0.8)
    })

    # Sector Distribution ----
    output$sector_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = "Add stakeholders to see distribution")
        return()
      }

      sector_counts <- table(df$Sector)
      barplot(sector_counts,
              main = "Stakeholders by Sector",
              ylab = "Count",
              col = "#F18F01",
              las = 2,
              cex.names = 0.8)
    })

    # Download Handlers ----
    output$download_stakeholder_report <- downloadHandler(
      filename = function() {
        paste0("Stakeholder_Report_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        wb <- createWorkbook()

        addWorksheet(wb, "Stakeholders")
        addWorksheet(wb, "Engagements")
        addWorksheet(wb, "Communications")

        writeData(wb, "Stakeholders", stakeholder_data$stakeholders)
        writeData(wb, "Engagements", stakeholder_data$engagements)
        writeData(wb, "Communications", stakeholder_data$communications)

        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    # Help Modal ----
    observeEvent(input$help_stakeholder, {
      showModal(modalDialog(
        title = "PIMS: Stakeholder Identification and Engagement Guide",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Effective stakeholder engagement is critical for marine ecosystem management. No single stakeholder has a complete view of the system - only by bringing diverse stakeholders together can we approach a holistic understanding."),

        hr(),
        h5("Key Concepts"),

        tags$ul(
          tags$li(strong("Stakeholder:"), "Anyone affected by or who can affect the marine social-ecological system"),
          tags$li(strong("Power:"), "Ability to influence decisions and outcomes"),
          tags$li(strong("Interest:"), "Level of concern or impact from the system"),
          tags$li(strong("Engagement Level:"), "How deeply stakeholders should be involved")
        ),

        hr(),
        h5("Using the Power-Interest Grid"),

        tags$ul(
          tags$li(strong("Key Players (High Power, High Interest):"), "Engage closely, involve in decision-making"),
          tags$li(strong("Keep Satisfied (High Power, Low Interest):"), "Keep satisfied but don't overwhelm with communication"),
          tags$li(strong("Keep Informed (Low Power, High Interest):"), "Keep informed and consult regarding their interests"),
          tags$li(strong("Monitor (Low Power, Low Interest):"), "Monitor with minimum effort, inform via general communications")
        ),

        hr(),
        h5("Engagement Levels (IAP2 Spectrum)"),

        tags$ul(
          tags$li(strong("Inform:"), "Provide information to stakeholders"),
          tags$li(strong("Consult:"), "Obtain feedback on analysis, alternatives, decisions"),
          tags$li(strong("Involve:"), "Work with stakeholders to ensure concerns are understood"),
          tags$li(strong("Collaborate:"), "Partner with stakeholders in decision-making"),
          tags$li(strong("Empower:"), "Place final decision-making in hands of stakeholders")
        ),

        hr(),
        h5("Workflow"),

        tags$ol(
          tags$li(strong("Identify:"), "Add all relevant stakeholders to the register"),
          tags$li(strong("Analyze:"), "Assess power and interest, visualize on grid"),
          tags$li(strong("Plan:"), "Develop engagement strategy based on classification"),
          tags$li(strong("Engage:"), "Conduct and document engagement activities"),
          tags$li(strong("Communicate:"), "Maintain ongoing communication"),
          tags$li(strong("Review:"), "Analyze coverage and adjust strategy")
        ),

        hr(),
        p(em("Remember: Stakeholder engagement is an ongoing process, not a one-time activity.")),

        footer = modalButton("Close")
      ))
    })

    # Return reactive data
    return(reactive({ stakeholder_data }))
  })
}
