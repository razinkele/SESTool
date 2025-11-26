# PIMS Stakeholder Management Module
# Process and Information Management System - Stakeholder Identification and Engagement
# Based on MarineSABRES Simple SES DRAFT Guidance

library(shiny)
library(DT)
library(openxlsx)

# Module UI ----
pimsStakeholderUI <- function(id, i18n) {
  shiny.i18n::usei18n(i18n)
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        create_module_header(ns, "pims_stakeholder_title", "pims_stakeholder_subtitle", "pims_stakeholder_help", i18n)
      )
    ),

    hr(),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("stakeholder_tabs"),

          # Tab 1: Stakeholder Register ----
          tabPanel(i18n$t("Stakeholder Register"),
            h4(i18n$t("Stakeholder Identification")),
            p(i18n$t("Identify all stakeholders relevant to your marine case study. Stakeholders include anyone affected by or who can affect the system.")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Add New Stakeholder")),
                  fluidRow(
                    column(3,
                      textInput(ns("sh_name"), i18n$t("Stakeholder Name/Organization:"),
                               placeholder = i18n$t("e.g., Local Fishers Association"))
                    ),
                    column(3,
                      selectInput(ns("sh_type"), i18n$t("Stakeholder Type:"),
                                 choices = c("", i18n$t("Resource Users"), i18n$t("Industry/Business"),
                                           i18n$t("Government/Regulators"), i18n$t("NGO/Civil Society"),
                                           i18n$t("Scientific/Academic"), i18n$t("Local Communities"),
                                           i18n$t("Indigenous Groups"), i18n$t("Other")))
                    ),
                    column(3,
                      selectInput(ns("sh_sector"), i18n$t("Primary Sector:"),
                                 choices = c("", i18n$t("Fisheries"), i18n$t("Aquaculture"), i18n$t("Tourism"),
                                           i18n$t("Shipping"), i18n$t("Energy"), i18n$t("Conservation"),
                                           i18n$t("Research"), i18n$t("Policy/Management"), i18n$t("Multiple"), i18n$t("Other")))
                    ),
                    column(3,
                      textInput(ns("sh_contact"), i18n$t("Contact Person/Details:"),
                               placeholder = i18n$t("Name, email, phone"))
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("sh_interests"), i18n$t("Key Interests/Concerns:"),
                                   placeholder = i18n$t("What does this stakeholder care about in the marine system?"),
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("sh_role"), i18n$t("Role in System:"),
                                   placeholder = i18n$t("What is their role? Decision-maker, user, affected party, etc."),
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(3,
                      selectInput(ns("sh_power"), i18n$t("Power/Influence:"),
                                 choices = c("", i18n$t("High"), i18n$t("Medium"), i18n$t("Low")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_interest"), i18n$t("Interest/Impact:"),
                                 choices = c("", i18n$t("High"), i18n$t("Medium"), i18n$t("Low")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_attitude"), i18n$t("Current Attitude:"),
                                 choices = c("", i18n$t("Supportive"), i18n$t("Neutral"), i18n$t("Resistant"), i18n$t("Unknown")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_engagement_level"), i18n$t("Engagement Level:"),
                                 choices = c("", i18n$t("Inform"), i18n$t("Consult"), i18n$t("Involve"), i18n$t("Collaborate"), i18n$t("Empower")),
                                 selected = "")
                    )
                  ),
                  actionButton(ns("add_stakeholder"), i18n$t("Add Stakeholder"),
                              icon = icon("plus"), class = "btn-success")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Stakeholder Register")),
                DTOutput(ns("stakeholder_table")),
                br(),
                actionButton(ns("delete_selected"), i18n$t("Delete Selected"),
                            icon = icon("trash"), class = "btn-danger")
              )
            )
          ),

          # Tab 2: Power-Interest Grid ----
          tabPanel(i18n$t("Power-Interest Analysis"),
            h4(i18n$t("Stakeholder Power-Interest Grid")),
            p(i18n$t("Visualize stakeholders based on their power/influence and level of interest/impact. This helps prioritize engagement strategies.")),

            wellPanel(
              h5(i18n$t("Power-Interest Grid Classification")),
              tags$ul(
                tags$li(strong(i18n$t("High Power, High Interest (Key Players):")),
                       i18n$t("Engage closely and make greatest efforts to satisfy")),
                tags$li(strong(i18n$t("High Power, Low Interest (Keep Satisfied):")),
                       i18n$t("Keep satisfied but avoid excessive communication")),
                tags$li(strong(i18n$t("Low Power, High Interest (Keep Informed):")),
                       i18n$t("Keep informed and talk to regarding their interests")),
                tags$li(strong(i18n$t("Low Power, Low Interest (Monitor):")),
                       i18n$t("Monitor with minimum effort"))
              )
            ),

            fluidRow(
              column(8,
                plotOutput(ns("power_interest_plot"), height = "600px", click = ns("plot_click"))
              ),
              column(4,
                wellPanel(
                  h5(i18n$t("Grid Summary")),
                  verbatimTextOutput(ns("grid_summary")),
                  hr(),
                  h5(i18n$t("Clicked Stakeholder")),
                  verbatimTextOutput(ns("clicked_stakeholder"))
                )
              )
            )
          ),

          # Tab 3: Engagement Planning ----
          tabPanel(i18n$t("Engagement Planning"),
            h4(i18n$t("Stakeholder Engagement Strategy")),
            p(i18n$t("Plan how to engage with each stakeholder group based on their power-interest classification.")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Define Engagement Activities")),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_stakeholder"), i18n$t("Select Stakeholder:"),
                                 choices = NULL)
                    ),
                    column(4,
                      selectInput(ns("eng_method"), i18n$t("Engagement Method:"),
                                 choices = c("", i18n$t("Workshop"), i18n$t("Interview"), i18n$t("Survey"), i18n$t("Focus Group"),
                                           i18n$t("Public Meeting"), i18n$t("Advisory Committee"), i18n$t("Email/Newsletter"),
                                           i18n$t("One-on-One Meeting"), i18n$t("Site Visit"), i18n$t("Other")))
                    ),
                    column(4,
                      dateInput(ns("eng_date"), i18n$t("Planned/Completed Date:"),
                               value = Sys.Date())
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("eng_objectives"), i18n$t("Engagement Objectives:"),
                                   placeholder = i18n$t("What do you want to achieve?"),
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("eng_outcomes"), i18n$t("Outcomes/Notes:"),
                                   placeholder = i18n$t("What was achieved or learned?"),
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_status"), i18n$t("Status:"),
                                 choices = c(i18n$t("Planned"), i18n$t("Completed"), i18n$t("Cancelled"), i18n$t("Ongoing")))
                    ),
                    column(4,
                      textInput(ns("eng_facilitator"), i18n$t("Facilitator/Contact:"),
                               placeholder = i18n$t("Who is leading this?"))
                    ),
                    column(4,
                      br(),
                      actionButton(ns("add_engagement"), i18n$t("Add Activity"),
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Engagement Activities Log")),
                DTOutput(ns("engagement_table"))
              )
            )
          ),

          # Tab 4: Communication Plan ----
          tabPanel(i18n$t("Communication Plan"),
            h4(i18n$t("Stakeholder Communication and Impact Management")),
            p(i18n$t("Plan and track communications with stakeholders to ensure effective information flow.")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Add Communication Item")),
                  fluidRow(
                    column(3,
                      selectInput(ns("comm_audience"), i18n$t("Target Audience:"),
                                 choices = c("", i18n$t("All Stakeholders"), i18n$t("Key Players"), i18n$t("Government"),
                                           i18n$t("Industry"), i18n$t("NGOs"), i18n$t("Local Communities"), i18n$t("Scientific Community"),
                                           i18n$t("Specific Stakeholder")))
                    ),
                    column(3,
                      selectInput(ns("comm_type"), i18n$t("Communication Type:"),
                                 choices = c("", i18n$t("Report"), i18n$t("Newsletter"), i18n$t("Presentation"), i18n$t("Website Update"),
                                           i18n$t("Press Release"), i18n$t("Social Media"), i18n$t("Email"), i18n$t("Meeting Notes"), i18n$t("Other")))
                    ),
                    column(3,
                      dateInput(ns("comm_date"), i18n$t("Date:"),
                               value = Sys.Date())
                    ),
                    column(3,
                      selectInput(ns("comm_frequency"), i18n$t("Frequency:"),
                                 choices = c(i18n$t("One-time"), i18n$t("Weekly"), i18n$t("Monthly"), i18n$t("Quarterly"), i18n$t("Annual"), i18n$t("As Needed")))
                    )
                  ),
                  fluidRow(
                    column(8,
                      textAreaInput(ns("comm_message"), i18n$t("Key Message/Content:"),
                                   placeholder = i18n$t("What information is being communicated?"),
                                   rows = 3)
                    ),
                    column(4,
                      textInput(ns("comm_responsible"), i18n$t("Responsible Person:")),
                      br(),
                      actionButton(ns("add_communication"), i18n$t("Add Communication"),
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("Communications Log")),
                DTOutput(ns("communication_table"))
              )
            )
          ),

          # Tab 5: Analysis & Reports ----
          tabPanel(i18n$t("Analysis & Reports"),
            h4(i18n$t("Stakeholder Analysis Summary")),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("Stakeholder Statistics")),
                  verbatimTextOutput(ns("stakeholder_stats"))
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("Engagement Coverage")),
                  plotOutput(ns("engagement_coverage"), height = "250px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("Stakeholder Types Distribution")),
                  plotOutput(ns("type_distribution"), height = "300px")
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("Sector Distribution")),
                  plotOutput(ns("sector_distribution"), height = "300px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("Export Stakeholder Data")),
                  p(i18n$t("Download stakeholder information for reporting and documentation.")),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_stakeholder_report"), i18n$t("Download Full Report (Excel)"),
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_power_interest"), i18n$t("Download Power-Interest Grid (PNG)"),
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_summary"), i18n$t("Download Summary (PDF)"),
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
pimsStakeholderServer <- function(id, global_data, i18n) {
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

      showNotification(i18n$t("Stakeholder added successfully!"), type = "message")
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
        showNotification(paste(i18n$t("Deleted"), length(selected_rows), i18n$t("stakeholder(s)")), type = "warning")
      } else {
        showNotification(i18n$t("No stakeholders selected"), type = "error")
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
        plot(1, 1, type = "n", xlab = i18n$t("Interest/Impact"), ylab = i18n$t("Power/Influence"),
             main = i18n$t("Power-Interest Grid\n(Add stakeholders with Power and Interest ratings to see visualization)"),
             xlim = c(0.5, 3.5), ylim = c(0.5, 3.5))
        return()
      }

      # Add jitter to avoid overlap
      df$PowerNum <- jitter(df$PowerNum, amount = 0.15)
      df$InterestNum <- jitter(df$InterestNum, amount = 0.15)

      plot(df$InterestNum, df$PowerNum,
           xlim = c(0.5, 3.5), ylim = c(0.5, 3.5),
           xlab = paste0(i18n$t("Interest/Impact"), " →"),
           ylab = paste0(i18n$t("Power/Influence"), " →"),
           main = i18n$t("Stakeholder Power-Interest Grid"),
           pch = 19, cex = 2, col = "#2E86AB",
           xaxt = "n", yaxt = "n",
           cex.lab = 1.2, cex.main = 1.5)

      # Grid lines
      abline(h = 2, v = 2, col = "gray30", lwd = 2, lty = 2)

      # Quadrant labels
      text(1.25, 2.75, paste0(i18n$t("Keep Satisfied"), "\n(", i18n$t("High Power, Low Interest"), ")"), cex = 1.1, col = "gray30")
      text(2.75, 2.75, paste0(i18n$t("Key Players"), "\n(", i18n$t("High Power, High Interest"), ")"), cex = 1.1, col = "gray30", font = 2)
      text(1.25, 1.25, paste0(i18n$t("Monitor"), "\n(", i18n$t("Low Power, Low Interest"), ")"), cex = 1.1, col = "gray30")
      text(2.75, 1.25, paste0(i18n$t("Keep Informed"), "\n(", i18n$t("Low Power, High Interest"), ")"), cex = 1.1, col = "gray30")

      # Axes
      axis(1, at = 1:3, labels = c(i18n$t("Low"), i18n$t("Medium"), i18n$t("High")))
      axis(2, at = 1:3, labels = c(i18n$t("Low"), i18n$t("Medium"), i18n$t("High")))

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
        i18n$t("Total Stakeholders:"), " ", nrow(df), "\n\n",
        i18n$t("Key Players:"), " ", key_players, "\n",
        i18n$t("Keep Satisfied:"), " ", keep_satisfied, "\n",
        i18n$t("Keep Informed:"), " ", keep_informed, "\n",
        i18n$t("Monitor:"), " ", monitor
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

      if(nrow(df) == 0) return(i18n$t("No data"))

      # Find nearest point
      distances <- sqrt((df$InterestNum - input$plot_click$x)^2 +
                       (df$PowerNum - input$plot_click$y)^2)
      nearest <- which.min(distances)

      if(distances[nearest] > 0.5) return(i18n$t("Click on a point"))

      sh <- df[nearest, ]
      paste0(
        i18n$t("Name:"), " ", sh$Name, "\n",
        i18n$t("Type:"), " ", sh$Type, "\n",
        i18n$t("Sector:"), " ", sh$Sector, "\n",
        i18n$t("Power:"), " ", sh$Power, "\n",
        i18n$t("Interest:"), " ", sh$Interest, "\n",
        i18n$t("Attitude:"), " ", sh$Attitude, "\n\n",
        i18n$t("Key Interests:"), "\n", sh$Interests
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

      showNotification(i18n$t("Engagement activity added!"), type = "message")
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

      showNotification(i18n$t("Communication added!"), type = "message")
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
      if(nrow(df) == 0) return(i18n$t("No stakeholders added yet"))

      paste0(
        i18n$t("Total Stakeholders:"), " ", nrow(df), "\n",
        i18n$t("Stakeholder Types:"), " ", length(unique(df$Type)), "\n",
        i18n$t("Sectors Represented:"), " ", length(unique(df$Sector)), "\n",
        i18n$t("High Power Stakeholders:"), " ", sum(df$Power == "High", na.rm = TRUE), "\n",
        i18n$t("High Interest Stakeholders:"), " ", sum(df$Interest == "High", na.rm = TRUE), "\n",
        i18n$t("Total Engagements:"), " ", nrow(stakeholder_data$engagements), "\n",
        i18n$t("Total Communications:"), " ", nrow(stakeholder_data$communications)
      )
    })

    # Engagement Coverage Plot ----
    output$engagement_coverage <- renderPlot({
      df_sh <- stakeholder_data$stakeholders
      df_eng <- stakeholder_data$engagements

      if(nrow(df_sh) == 0) {
        plot(1, 1, type = "n", main = i18n$t("Add stakeholders to see coverage"))
        return()
      }

      engaged_ids <- unique(df_eng$StakeholderID)
      coverage <- sum(df_sh$ID %in% engaged_ids) / nrow(df_sh) * 100

      barplot(c(coverage, 100 - coverage),
              names.arg = c(i18n$t("Engaged"), i18n$t("Not Engaged")),
              col = c("#2E86AB", "#CCCCCC"),
              main = paste0(i18n$t("Stakeholder Engagement Coverage"), " (", round(coverage, 1), "%)"),
              ylab = i18n$t("Percentage"),
              ylim = c(0, 100))
    })

    # Type Distribution ----
    output$type_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = i18n$t("Add stakeholders to see distribution"))
        return()
      }

      type_counts <- table(df$Type)
      barplot(type_counts,
              main = i18n$t("Stakeholders by Type"),
              ylab = i18n$t("Count"),
              col = "#A23B72",
              las = 2,
              cex.names = 0.8)
    })

    # Sector Distribution ----
    output$sector_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = i18n$t("Add stakeholders to see distribution"))
        return()
      }

      sector_counts <- table(df$Sector)
      barplot(sector_counts,
              main = i18n$t("Stakeholders by Sector"),
              ylab = i18n$t("Count"),
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
    create_help_observer(
      input,
      "pims_stakeholder_help",
      "pims_stakeholder_help_title",
      tagList(p(i18n$t("pims_stakeholder_help_content"))),
      i18n
    )

    # Return reactive data
    return(reactive({ stakeholder_data }))
  })
}
