# PIMS Stakeholder Management Module
# Process and Information Management System - Stakeholder Identification and Engagement
# Based on MarineSABRES Simple SES DRAFT Guidance

library(shiny)
library(DT)
library(openxlsx)

# Module UI ----
pimsStakeholderUI <- function(id, i18n) {
  # shiny.i18n::usei18n(i18n) removed - only call once in main UI
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        create_module_header(ns, "modules.pims.stakeholder.title", "modules.pims.stakeholder.subtitle", "pims_stakeholder_help", i18n)
      )
    ),

    hr(),

    fluidRow(
      column(12,
        tabsetPanel(id = ns("stakeholder_tabs"),

          # Tab 1: Stakeholder Register ----
          tabPanel(i18n$t("modules.pims.stakeholder.stakeholder_register"),
            h4(i18n$t("modules.pims.stakeholder.stakeholder_identification")),
            p(i18n$t("modules.pims.identify_all_stakeholders_relevant_to_your_marine_")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.add_new_stakeholder")),
                  fluidRow(
                    column(3,
                      textInput(ns("sh_name"), i18n$t("modules.pims.stakeholder.stakeholder_nameorganization"),
                               placeholder = i18n$t("modules.pims.stakeholder.eg_local_fishers_association"))
                    ),
                    column(3,
                      selectInput(ns("sh_type"), i18n$t("common.labels.stakeholder_type"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.resource_users"), i18n$t("modules.pims.stakeholder.industrybusiness"),
                                           i18n$t("modules.pims.stakeholder.governmentregulators"), i18n$t("modules.pims.stakeholder.ngocivil_society"),
                                           i18n$t("modules.pims.stakeholder.scientificacademic"), i18n$t("modules.pims.stakeholder.local_communities"),
                                           i18n$t("modules.pims.stakeholder.indigenous_groups"), i18n$t("modules.isa.ai_assistant.other")))
                    ),
                    column(3,
                      selectInput(ns("sh_sector"), i18n$t("modules.pims.stakeholder.primary_sector"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.fisheries"), i18n$t("modules.pims.stakeholder.aquaculture"), i18n$t("modules.pims.stakeholder.tourism"),
                                           i18n$t("modules.pims.stakeholder.shipping"), i18n$t("modules.pims.stakeholder.energy"), i18n$t("modules.pims.stakeholder.conservation"),
                                           i18n$t("modules.pims.stakeholder.research"), i18n$t("modules.pims.stakeholder.policymanagement"), i18n$t("modules.pims.stakeholder.multiple"), i18n$t("modules.isa.ai_assistant.other")))
                    ),
                    column(3,
                      textInput(ns("sh_contact"), i18n$t("common.labels.contact_persondetails"),
                               placeholder = i18n$t("modules.pims.stakeholder.name_email_phone"))
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("sh_interests"), i18n$t("modules.pims.stakeholder.key_interestsconcerns"),
                                   placeholder = i18n$t("modules.pims.what_does_this_stakeholder_care_about_in_the_marin"),
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("sh_role"), i18n$t("modules.pims.stakeholder.role_in_system"),
                                   placeholder = i18n$t("modules.pims.what_is_their_role_decision_maker_user_affected_pa"),
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(3,
                      selectInput(ns("sh_power"), i18n$t("modules.pims.stakeholder.powerinfluence"),
                                 choices = c("", i18n$t("modules.response.measures.high"), i18n$t("modules.response.measures.medium"), i18n$t("modules.response.measures.low")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_interest"), i18n$t("modules.pims.stakeholder.interestimpact"),
                                 choices = c("", i18n$t("modules.response.measures.high"), i18n$t("modules.response.measures.medium"), i18n$t("modules.response.measures.low")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_attitude"), i18n$t("modules.pims.stakeholder.current_attitude"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.supportive"), i18n$t("modules.pims.stakeholder.neutral"), i18n$t("modules.pims.stakeholder.resistant"), i18n$t("modules.response.measures.unknown")),
                                 selected = "")
                    ),
                    column(3,
                      selectInput(ns("sh_engagement_level"), i18n$t("modules.pims.stakeholder.engagement_level"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.inform"), i18n$t("modules.pims.stakeholder.consult"), i18n$t("modules.pims.stakeholder.involve"), i18n$t("modules.pims.stakeholder.collaborate"), i18n$t("modules.pims.stakeholder.empower")),
                                 selected = "")
                    )
                  ),
                  actionButton(ns("add_stakeholder"), i18n$t("modules.pims.stakeholder.add_stakeholder"),
                              icon = icon("plus"), class = "btn-success")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("modules.pims.stakeholder.stakeholder_register")),
                DTOutput(ns("stakeholder_table")),
                br(),
                actionButton(ns("delete_selected"), i18n$t("modules.response.measures.delete_selected"),
                            icon = icon("trash"), class = "btn-danger")
              )
            )
          ),

          # Tab 2: Power-Interest Grid ----
          tabPanel(i18n$t("modules.pims.stakeholder.power_interest_analysis"),
            h4(i18n$t("modules.pims.stakeholder.stakeholder_power_interest_grid")),
            p(i18n$t("modules.pims.visualize_stakeholders_based_on_their_powerinfluen")),

            wellPanel(
              h5(i18n$t("modules.pims.stakeholder.power_interest_grid_classification")),
              tags$ul(
                tags$li(strong(i18n$t("modules.pims.stakeholder.high_power_high_interest_key_players")),
                       i18n$t("modules.pims.stakeholder.engage_closely_and_make_greatest_efforts_to_satisfy")),
                tags$li(strong(i18n$t("modules.pims.stakeholder.high_power_low_interest_keep_satisfied")),
                       i18n$t("modules.pims.stakeholder.keep_satisfied_but_avoid_excessive_communication")),
                tags$li(strong(i18n$t("modules.pims.stakeholder.low_power_high_interest_keep_informed")),
                       i18n$t("modules.pims.stakeholder.keep_informed_and_talk_to_regarding_their_interests")),
                tags$li(strong(i18n$t("modules.pims.stakeholder.low_power_low_interest_monitor")),
                       i18n$t("modules.pims.stakeholder.monitor_with_minimum_effort"))
              )
            ),

            fluidRow(
              column(8,
                plotOutput(ns("power_interest_plot"), height = "600px", click = ns("plot_click"))
              ),
              column(4,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.grid_summary")),
                  verbatimTextOutput(ns("grid_summary")),
                  hr(),
                  h5(i18n$t("modules.pims.stakeholder.clicked_stakeholder")),
                  verbatimTextOutput(ns("clicked_stakeholder"))
                )
              )
            )
          ),

          # Tab 3: Engagement Planning ----
          tabPanel(i18n$t("modules.pims.stakeholder.engagement_planning"),
            h4(i18n$t("modules.pims.stakeholder.stakeholder_engagement_strategy")),
            p(i18n$t("modules.pims.plan_how_to_engage_with_each_stakeholder_group_bas")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.define_engagement_activities")),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_stakeholder"), i18n$t("modules.pims.stakeholder.select_stakeholder"),
                                 choices = NULL)
                    ),
                    column(4,
                      selectInput(ns("eng_method"), i18n$t("modules.pims.stakeholder.engagement_method"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.workshop"), i18n$t("modules.pims.stakeholder.interview"), i18n$t("modules.pims.stakeholder.survey"), i18n$t("modules.pims.stakeholder.focus_group"),
                                           i18n$t("modules.pims.stakeholder.public_meeting"), i18n$t("modules.pims.stakeholder.advisory_committee"), i18n$t("modules.pims.stakeholder.emailnewsletter"),
                                           i18n$t("modules.pims.stakeholder.one_on_one_meeting"), i18n$t("modules.pims.stakeholder.site_visit"), i18n$t("modules.isa.ai_assistant.other")))
                    ),
                    column(4,
                      dateInput(ns("eng_date"), i18n$t("common.labels.plannedcompleted_date"),
                               value = Sys.Date())
                    )
                  ),
                  fluidRow(
                    column(6,
                      textAreaInput(ns("eng_objectives"), i18n$t("modules.pims.stakeholder.engagement_objectives"),
                                   placeholder = i18n$t("modules.pims.stakeholder.what_do_you_want_to_achieve"),
                                   rows = 3)
                    ),
                    column(6,
                      textAreaInput(ns("eng_outcomes"), i18n$t("common.labels.outcomesnotes"),
                                   placeholder = i18n$t("modules.pims.stakeholder.what_was_achieved_or_learned"),
                                   rows = 3)
                    )
                  ),
                  fluidRow(
                    column(4,
                      selectInput(ns("eng_status"), i18n$t("common.labels.status"),
                                 choices = c(i18n$t("modules.response.measures.planned"), i18n$t("modules.response.measures.completed"), i18n$t("modules.pims.stakeholder.cancelled"), i18n$t("modules.pims.stakeholder.ongoing")))
                    ),
                    column(4,
                      textInput(ns("eng_facilitator"), i18n$t("modules.pims.stakeholder.facilitatorcontact"),
                               placeholder = i18n$t("modules.pims.stakeholder.who_is_leading_this"))
                    ),
                    column(4,
                      br(),
                      actionButton(ns("add_engagement"), i18n$t("modules.isa.data_entry.common.add_activity"),
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("modules.pims.stakeholder.engagement_activities_log")),
                DTOutput(ns("engagement_table"))
              )
            )
          ),

          # Tab 4: Communication Plan ----
          tabPanel(i18n$t("modules.pims.stakeholder.communication_plan"),
            h4(i18n$t("modules.pims.stakeholder.stakeholder_communication_and_impact_management")),
            p(i18n$t("modules.pims.plan_and_track_communications_with_stakeholders_to")),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.add_communication_item")),
                  fluidRow(
                    column(3,
                      selectInput(ns("comm_audience"), i18n$t("modules.pims.stakeholder.target_audience"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.all_stakeholders"), i18n$t("modules.pims.stakeholder.key_players"), i18n$t("modules.pims.stakeholder.government"),
                                           i18n$t("modules.pims.stakeholder.industry"), i18n$t("modules.pims.stakeholder.ngos"), i18n$t("modules.pims.stakeholder.local_communities"), i18n$t("modules.pims.stakeholder.scientific_community"),
                                           i18n$t("modules.pims.stakeholder.specific_stakeholder")))
                    ),
                    column(3,
                      selectInput(ns("comm_type"), i18n$t("common.labels.communication_type"),
                                 choices = c("", i18n$t("modules.pims.stakeholder.report"), i18n$t("modules.pims.stakeholder.newsletter"), i18n$t("modules.pims.stakeholder.presentation"), i18n$t("modules.pims.stakeholder.website_update"),
                                           i18n$t("modules.pims.stakeholder.press_release"), i18n$t("modules.pims.stakeholder.social_media"), i18n$t("modules.pims.stakeholder.email"), i18n$t("modules.pims.stakeholder.meeting_notes"), i18n$t("modules.isa.ai_assistant.other")))
                    ),
                    column(3,
                      dateInput(ns("comm_date"), i18n$t("common.labels.date"),
                               value = Sys.Date())
                    ),
                    column(3,
                      selectInput(ns("comm_frequency"), i18n$t("modules.isa.data_entry.common.frequency"),
                                 choices = c(i18n$t("modules.pims.stakeholder.one_time"), i18n$t("modules.pims.stakeholder.weekly"), i18n$t("modules.pims.stakeholder.monthly"), i18n$t("modules.pims.stakeholder.quarterly"), i18n$t("modules.pims.stakeholder.annual"), i18n$t("modules.pims.stakeholder.as_needed")))
                    )
                  ),
                  fluidRow(
                    column(8,
                      textAreaInput(ns("comm_message"), i18n$t("modules.pims.stakeholder.key_messagecontent"),
                                   placeholder = i18n$t("modules.pims.stakeholder.what_information_is_being_communicated"),
                                   rows = 3)
                    ),
                    column(4,
                      textInput(ns("comm_responsible"), i18n$t("modules.pims.stakeholder.responsible_person")),
                      br(),
                      actionButton(ns("add_communication"), i18n$t("modules.pims.stakeholder.add_communication"),
                                  icon = icon("plus"), class = "btn-success")
                    )
                  )
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                h5(i18n$t("modules.pims.stakeholder.communications_log")),
                DTOutput(ns("communication_table"))
              )
            )
          ),

          # Tab 5: Analysis & Reports ----
          tabPanel(i18n$t("modules.pims.stakeholder.analysis_reports"),
            h4(i18n$t("modules.pims.stakeholder.stakeholder_analysis_summary")),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.stakeholder_statistics")),
                  verbatimTextOutput(ns("stakeholder_stats"))
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.engagement_coverage")),
                  plotOutput(ns("engagement_coverage"), height = "250px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(6,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.stakeholder_types_distribution")),
                  plotOutput(ns("type_distribution"), height = "300px")
                )
              ),
              column(6,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.sector_distribution")),
                  plotOutput(ns("sector_distribution"), height = "300px")
                )
              )
            ),

            hr(),

            fluidRow(
              column(12,
                wellPanel(
                  h5(i18n$t("modules.pims.stakeholder.export_stakeholder_data")),
                  p(i18n$t("modules.pims.download_stakeholder_information_for_reporting_and")),
                  fluidRow(
                    column(4,
                      downloadButton(ns("download_stakeholder_report"), i18n$t("modules.pims.stakeholder.download_full_report_excel"),
                                    class = "btn-success btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_power_interest"), i18n$t("modules.pims.stakeholder.download_power_interest_grid_png"),
                                    class = "btn-info btn-block")
                    ),
                    column(4,
                      downloadButton(ns("download_summary"), i18n$t("modules.pims.stakeholder.download_summary_pdf"),
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

      showNotification(i18n$t("modules.pims.stakeholder.stakeholder_added_successfully"), type = "message")
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
        showNotification(paste(i18n$t("modules.pims.stakeholder.deleted"), length(selected_rows), i18n$t("modules.pims.stakeholder.stakeholders")), type = "warning")
      } else {
        showNotification(i18n$t("modules.pims.stakeholder.no_stakeholders_selected"), type = "error")
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
        plot(1, 1, type = "n", xlab = i18n$t("modules.pims.stakeholder.interestimpact"), ylab = i18n$t("modules.pims.stakeholder.powerinfluence"),
             main = i18n$t("modules.pims.power_interest_gridnadd_stakeholders_with_power_an"),
             xlim = c(0.5, 3.5), ylim = c(0.5, 3.5))
        return()
      }

      # Add jitter to avoid overlap
      df$PowerNum <- jitter(df$PowerNum, amount = 0.15)
      df$InterestNum <- jitter(df$InterestNum, amount = 0.15)

      plot(df$InterestNum, df$PowerNum,
           xlim = c(0.5, 3.5), ylim = c(0.5, 3.5),
           xlab = paste0(i18n$t("modules.pims.stakeholder.interestimpact"), " →"),
           ylab = paste0(i18n$t("modules.pims.stakeholder.powerinfluence"), " →"),
           main = i18n$t("modules.pims.stakeholder.stakeholder_power_interest_grid"),
           pch = 19, cex = 2, col = "#2E86AB",
           xaxt = "n", yaxt = "n",
           cex.lab = 1.2, cex.main = 1.5)

      # Grid lines
      abline(h = 2, v = 2, col = "gray30", lwd = 2, lty = 2)

      # Quadrant labels
      text(1.25, 2.75, paste0(i18n$t("modules.pims.stakeholder.keep_satisfied"), "\n(", i18n$t("modules.pims.stakeholder.high_power_low_interest"), ")"), cex = 1.1, col = "gray30")
      text(2.75, 2.75, paste0(i18n$t("modules.pims.stakeholder.key_players"), "\n(", i18n$t("modules.pims.stakeholder.high_power_high_interest"), ")"), cex = 1.1, col = "gray30", font = 2)
      text(1.25, 1.25, paste0(i18n$t("modules.pims.stakeholder.monitor"), "\n(", i18n$t("modules.pims.stakeholder.low_power_low_interest"), ")"), cex = 1.1, col = "gray30")
      text(2.75, 1.25, paste0(i18n$t("modules.pims.stakeholder.keep_informed"), "\n(", i18n$t("modules.pims.stakeholder.low_power_high_interest"), ")"), cex = 1.1, col = "gray30")

      # Axes
      axis(1, at = 1:3, labels = c(i18n$t("modules.response.measures.low"), i18n$t("modules.response.measures.medium"), i18n$t("modules.response.measures.high")))
      axis(2, at = 1:3, labels = c(i18n$t("modules.response.measures.low"), i18n$t("modules.response.measures.medium"), i18n$t("modules.response.measures.high")))

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
        i18n$t("modules.pims.stakeholder.total_stakeholders"), " ", nrow(df), "\n\n",
        i18n$t("modules.pims.stakeholder.key_players"), " ", key_players, "\n",
        i18n$t("modules.pims.stakeholder.keep_satisfied"), " ", keep_satisfied, "\n",
        i18n$t("modules.pims.stakeholder.keep_informed"), " ", keep_informed, "\n",
        i18n$t("modules.pims.stakeholder.monitor"), " ", monitor
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

      if(nrow(df) == 0) return(i18n$t("modules.pims.stakeholder.no_data"))

      # Find nearest point
      distances <- sqrt((df$InterestNum - input$plot_click$x)^2 +
                       (df$PowerNum - input$plot_click$y)^2)
      nearest <- which.min(distances)

      if(distances[nearest] > 0.5) return(i18n$t("modules.pims.stakeholder.click_on_a_point"))

      sh <- df[nearest, ]
      paste0(
        i18n$t("common.labels.name"), " ", sh$Name, "\n",
        i18n$t("common.labels.type"), " ", sh$Type, "\n",
        i18n$t("modules.isa.data_entry.common.sector"), " ", sh$Sector, "\n",
        i18n$t("modules.pims.stakeholder.power"), " ", sh$Power, "\n",
        i18n$t("modules.pims.stakeholder.interest"), " ", sh$Interest, "\n",
        i18n$t("modules.pims.stakeholder.attitude"), " ", sh$Attitude, "\n\n",
        i18n$t("modules.pims.stakeholder.key_interests"), "\n", sh$Interests
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

      showNotification(i18n$t("modules.pims.stakeholder.engagement_activity_added"), type = "message")
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

      showNotification(i18n$t("modules.pims.stakeholder.communication_added"), type = "message")
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
      if(nrow(df) == 0) return(i18n$t("modules.pims.stakeholder.no_stakeholders_added_yet"))

      paste0(
        i18n$t("modules.pims.stakeholder.total_stakeholders"), " ", nrow(df), "\n",
        i18n$t("modules.pims.stakeholder.stakeholder_types"), " ", length(unique(df$Type)), "\n",
        i18n$t("modules.pims.stakeholder.sectors_represented"), " ", length(unique(df$Sector)), "\n",
        i18n$t("modules.pims.stakeholder.high_power_stakeholders"), " ", sum(df$Power == "High", na.rm = TRUE), "\n",
        i18n$t("modules.pims.stakeholder.high_interest_stakeholders"), " ", sum(df$Interest == "High", na.rm = TRUE), "\n",
        i18n$t("modules.pims.stakeholder.total_engagements"), " ", nrow(stakeholder_data$engagements), "\n",
        i18n$t("modules.pims.stakeholder.total_communications"), " ", nrow(stakeholder_data$communications)
      )
    })

    # Engagement Coverage Plot ----
    output$engagement_coverage <- renderPlot({
      df_sh <- stakeholder_data$stakeholders
      df_eng <- stakeholder_data$engagements

      if(nrow(df_sh) == 0) {
        plot(1, 1, type = "n", main = i18n$t("modules.pims.stakeholder.add_stakeholders_to_see_coverage"))
        return()
      }

      engaged_ids <- unique(df_eng$StakeholderID)
      coverage <- sum(df_sh$ID %in% engaged_ids) / nrow(df_sh) * 100

      barplot(c(coverage, 100 - coverage),
              names.arg = c(i18n$t("modules.pims.stakeholder.engaged"), i18n$t("modules.pims.stakeholder.not_engaged")),
              col = c("#2E86AB", "#CCCCCC"),
              main = paste0(i18n$t("modules.pims.stakeholder.stakeholder_engagement_coverage"), " (", round(coverage, 1), "%)"),
              ylab = i18n$t("modules.pims.stakeholder.percentage"),
              ylim = c(0, 100))
    })

    # Type Distribution ----
    output$type_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = i18n$t("modules.pims.stakeholder.add_stakeholders_to_see_distribution"))
        return()
      }

      type_counts <- table(df$Type)
      barplot(type_counts,
              main = i18n$t("modules.pims.stakeholder.stakeholders_by_type"),
              ylab = i18n$t("modules.pims.stakeholder.count"),
              col = "#A23B72",
              las = 2,
              cex.names = 0.8)
    })

    # Sector Distribution ----
    output$sector_distribution <- renderPlot({
      df <- stakeholder_data$stakeholders
      if(nrow(df) == 0) {
        plot(1, 1, type = "n", main = i18n$t("modules.pims.stakeholder.add_stakeholders_to_see_distribution"))
        return()
      }

      sector_counts <- table(df$Sector)
      barplot(sector_counts,
              main = i18n$t("modules.pims.stakeholder.stakeholders_by_sector"),
              ylab = i18n$t("modules.pims.stakeholder.count"),
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
      tagList(p(i18n$t("modules.pims.stakeholder.pims_stakeholder_help_content"))),
      i18n
    )

    # Return reactive data
    return(reactive({ stakeholder_data }))
  })
}
