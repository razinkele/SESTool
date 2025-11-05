# ISA Data Entry Module
# Implements the Integrated Systems Analysis (ISA) framework
# Based on MarineSABRES Simple SES DRAFT Guidance
# Follows the DAPSI(W)R(M) framework for marine ecosystem analysis

# Module UI ----
isaDataEntryUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        uiOutput(ns("isa_header"))
      )
    ),

    fluidRow(
      column(12,
        uiOutput(ns("isa_tabs_ui"))
      )
    )
  )
}

# Module Server ----
isaDataEntryServer <- function(id, global_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Note: Module validation helpers are loaded in global.R

    # Reactive values to store all ISA data ----
    isa_data <- reactiveValues(
      # Exercise 0
      case_info = list(),

      # Exercise 1: Goods & Benefits
      goods_benefits = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        Stakeholder = character(),
        Importance = character(),
        Trend = character(),
        stringsAsFactors = FALSE
      ),
      gb_counter = 0,

      # Exercise 2a: Ecosystem Services
      ecosystem_services = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedGB = character(),
        Mechanism = character(),
        Confidence = character(),
        stringsAsFactors = FALSE
      ),
      es_counter = 0,

      # Exercise 2b: Marine Processes
      marine_processes = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedES = character(),
        Mechanism = character(),
        Spatial = character(),
        stringsAsFactors = FALSE
      ),
      mpf_counter = 0,

      # Exercise 3: Pressures
      pressures = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedMPF = character(),
        Intensity = character(),
        Spatial = character(),
        Temporal = character(),
        stringsAsFactors = FALSE
      ),
      p_counter = 0,

      # Exercise 4: Activities
      activities = data.frame(
        ID = character(),
        Name = character(),
        Sector = character(),
        Description = character(),
        LinkedP = character(),
        Scale = character(),
        Frequency = character(),
        stringsAsFactors = FALSE
      ),
      a_counter = 0,

      # Exercise 5: Drivers
      drivers = data.frame(
        ID = character(),
        Name = character(),
        Type = character(),
        Description = character(),
        LinkedA = character(),
        Trend = character(),
        Controllability = character(),
        stringsAsFactors = FALSE
      ),
      d_counter = 0,

      # Exercise 6: Loop closure
      loop_connections = data.frame(
        DriverID = character(),
        GBID = character(),
        Effect = character(),
        Strength = character(),
        Confidence = integer(),
        Mechanism = character(),
        stringsAsFactors = FALSE
      ),

      # BOT data
      bot_data = data.frame(
        ElementType = character(),
        ElementID = character(),
        Year = numeric(),
        Value = numeric(),
        Unit = character(),
        stringsAsFactors = FALSE
      ),

      # Exercises 10-12
      clarification = list(),
      validation = list()
    )

    # Initialize ISA data from project_data if it exists (e.g., from AI Assistant) ----
    # This observer loads saved data when the module starts or when project_data changes
    data_initialized <- reactiveVal(FALSE)

    observe({
      cat("[ISA Module] Checking for existing project data...\n")

      project <- global_data()

      if (!is.null(project) && !is.null(project$data) && !is.null(project$data$isa_data)) {
        isa_saved <- project$data$isa_data
        cat("[ISA Module] Found saved ISA data in project\n")

        # Load Drivers
        if (!is.null(isa_saved$drivers) && nrow(isa_saved$drivers) > 0) {
          cat(sprintf("[ISA Module] Loading %d drivers\n", nrow(isa_saved$drivers)))
          isa_data$drivers <- isa_saved$drivers
          isa_data$d_counter <- nrow(isa_saved$drivers)
        }

        # Load Activities
        if (!is.null(isa_saved$activities) && nrow(isa_saved$activities) > 0) {
          cat(sprintf("[ISA Module] Loading %d activities\n", nrow(isa_saved$activities)))
          isa_data$activities <- isa_saved$activities
          isa_data$a_counter <- nrow(isa_saved$activities)
        }

        # Load Pressures
        if (!is.null(isa_saved$pressures) && nrow(isa_saved$pressures) > 0) {
          cat(sprintf("[ISA Module] Loading %d pressures\n", nrow(isa_saved$pressures)))
          isa_data$pressures <- isa_saved$pressures
          isa_data$p_counter <- nrow(isa_saved$pressures)
        }

        # Load Marine Processes
        if (!is.null(isa_saved$marine_processes) && nrow(isa_saved$marine_processes) > 0) {
          cat(sprintf("[ISA Module] Loading %d marine processes\n", nrow(isa_saved$marine_processes)))
          isa_data$marine_processes <- isa_saved$marine_processes
          isa_data$mpf_counter <- nrow(isa_saved$marine_processes)
        }

        # Load Ecosystem Services
        if (!is.null(isa_saved$ecosystem_services) && nrow(isa_saved$ecosystem_services) > 0) {
          cat(sprintf("[ISA Module] Loading %d ecosystem services\n", nrow(isa_saved$ecosystem_services)))
          isa_data$ecosystem_services <- isa_saved$ecosystem_services
          isa_data$es_counter <- nrow(isa_saved$ecosystem_services)
        }

        # Load Goods & Benefits
        if (!is.null(isa_saved$goods_benefits) && nrow(isa_saved$goods_benefits) > 0) {
          cat(sprintf("[ISA Module] Loading %d goods/benefits\n", nrow(isa_saved$goods_benefits)))
          isa_data$goods_benefits <- isa_saved$goods_benefits
          isa_data$gb_counter <- nrow(isa_saved$goods_benefits)
        }

        # Note: responses and measures from AI Assistant don't map to ISA Data Entry
        # They would need to be handled separately or shown in a different section

        cat("[ISA Module] Data loading complete\n")
        data_initialized(TRUE)
      } else {
        cat("[ISA Module] No saved ISA data found - starting fresh\n")
      }
    })

    # Render ISA header ----
    output$isa_header <- renderUI({
      div(style = "display: flex; justify-content: space-between; align-items: center;",
        div(
          h3(i18n$t("Integrated Systems Analysis (ISA) Data Entry")),
          p(i18n$t("Follow the structured exercises to build your marine Social-Ecological System analysis.")),
          p(strong(i18n$t("Framework:")), " ", i18n$t("DAPSI(W)R(M) - Drivers, Activities, Pressures, State (Impact on Welfare), Responses (as Measures)"))
        ),
        div(style = "margin-top: 10px;",
          actionButton(ns("help_main"), i18n$t("ISA Framework Guide"),
                      icon = icon("question-circle"),
                      class = "btn btn-info btn-lg")
        )
      )
    })

    # Render tab panel UI with translated titles ----
    output$isa_tabs_ui <- renderUI({
      tabsetPanel(id = ns("isa_tabs"),
        tabPanel(i18n$t("Exercise 0: Complexity"),
          uiOutput(ns("exercise_0_content"))
        ),
        tabPanel(i18n$t("Exercise 1: Goods & Benefits"),
          uiOutput(ns("exercise_1_content"))
        ),
        tabPanel(i18n$t("Exercise 2a: Ecosystem Services"),
          uiOutput(ns("exercise_2a_content"))
        ),
        tabPanel(i18n$t("Exercise 2b: Marine Processes"),
          uiOutput(ns("exercise_2b_content"))
        ),
        tabPanel(i18n$t("Exercise 3: Pressures"),
          uiOutput(ns("exercise_3_content"))
        ),
        tabPanel(i18n$t("Exercise 4: Activities"),
          uiOutput(ns("exercise_4_content"))
        ),
        tabPanel(i18n$t("Exercise 5: Drivers"),
          uiOutput(ns("exercise_5_content"))
        ),
        tabPanel(i18n$t("Exercise 6: Closing Loop"),
          uiOutput(ns("exercise_6_content"))
        ),
        tabPanel(i18n$t("Exercises 7-9: CLD"),
          uiOutput(ns("exercise_789_content"))
        ),
        tabPanel(i18n$t("Exercises 10-12: Analysis"),
          uiOutput(ns("exercise_101112_content"))
        ),
        tabPanel(i18n$t("BOT Graphs"),
          uiOutput(ns("bot_graphs_content"))
        ),
        tabPanel(i18n$t("Data Management"),
          uiOutput(ns("data_management_content"))
        )
      )
    })

    # Render Exercise 0 content ----
    output$exercise_0_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Unfolding Complexity and Impacts on Welfare")),
          actionButton(ns("help_ex0"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Understand the complexity of your case study and identify impacts on human welfare.")),
          p(i18n$t("This preliminary exercise helps you explore the full scope of your system before detailed analysis."))
        ),

        fluidRow(
          column(6,
            h5(i18n$t("Case Study Context")),
            textInput(ns("case_name"), i18n$t("Case Study Name:"), placeholder = i18n$t("e.g., Baltic Sea fisheries")),
            textAreaInput(ns("case_description"), i18n$t("Brief Description:"),
                         placeholder = i18n$t("Describe your marine case study context..."),
                         rows = 4),
            textInput(ns("geographic_scope"), i18n$t("Geographic Scope:"), placeholder = i18n$t("e.g., Baltic Sea, North Atlantic")),
            textInput(ns("temporal_scope"), i18n$t("Temporal Scope:"), placeholder = i18n$t("e.g., 2000-2024"))
          ),
          column(6,
            h5(i18n$t("Initial Complexity Mapping")),
            textAreaInput(ns("welfare_impacts"), i18n$t("Identified Welfare Impacts:"),
                         placeholder = i18n$t("List key impacts on human welfare you've observed..."),
                         rows = 4),
            textAreaInput(ns("key_stakeholders"), i18n$t("Key Stakeholders:"),
                         placeholder = i18n$t("Who is affected? Who makes decisions?"),
                         rows = 4)
          )
        ),

        actionButton(ns("save_ex0"), i18n$t("Save Exercise 0"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 1 content ----
    output$exercise_1_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Specifying Goods and Benefits (G&B)")),
          actionButton(ns("help_ex1"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify and classify the goods and benefits derived from marine ecosystems.")),
          p(i18n$t("Complete columns B-H in the Master Data Sheet. Each Good/Benefit should have a unique ID and classification."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Goods and Benefits")),
            actionButton(ns("add_gb"), i18n$t("Add Good/Benefit"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("gb_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Goods and Benefits")),
            DTOutput(ns("gb_table"))
          )
        ),

        actionButton(ns("save_ex1"), i18n$t("Save Exercise 1"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 2a content ----
    output$exercise_2a_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Ecosystem Services (ES) affecting Goods and Benefits")),
          actionButton(ns("help_ex2a"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify ecosystem services that contribute to each Good/Benefit.")),
          p(i18n$t("Complete columns L-R in the Master Data Sheet. Link ES to the G&B identified in Exercise 1."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Ecosystem Services")),
            actionButton(ns("add_es"), i18n$t("Add Ecosystem Service"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("es_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Ecosystem Services")),
            DTOutput(ns("es_table"))
          )
        ),

        actionButton(ns("save_ex2a"), i18n$t("Save Exercise 2a"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 2b content ----
    output$exercise_2b_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Marine Processes and Functioning (MPF)")),
          actionButton(ns("help_ex2b"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify marine processes that support ecosystem services.")),
          p(i18n$t("Complete columns U-AA in the Master Data Sheet. Link MPF to ES from Exercise 2a."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Marine Processes and Functioning")),
            actionButton(ns("add_mpf"), i18n$t("Add Marine Process"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("mpf_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Marine Processes")),
            DTOutput(ns("mpf_table"))
          )
        ),

        actionButton(ns("save_ex2b"), i18n$t("Save Exercise 2b"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 3 content ----
    output$exercise_3_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Specifying Pressures on State Changes")),
          actionButton(ns("help_ex3"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify pressures that affect marine processes and ecosystem state.")),
          p(i18n$t("Complete columns AC-AM in the Master Data Sheet. Link Pressures to MPF from Exercise 2b."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Pressures")),
            actionButton(ns("add_p"), i18n$t("Add Pressure"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("p_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Pressures")),
            DTOutput(ns("p_table"))
          )
        ),

        actionButton(ns("save_ex3"), i18n$t("Save Exercise 3"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 4 content ----
    output$exercise_4_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Specifying Activities affecting Pressures")),
          actionButton(ns("help_ex4"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify human activities that generate pressures on the marine environment.")),
          p(i18n$t("Complete columns AO-AY in the Master Data Sheet. Link Activities to Pressures from Exercise 3."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Activities")),
            actionButton(ns("add_a"), i18n$t("Add Activity"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("a_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Activities")),
            DTOutput(ns("a_table"))
          )
        ),

        actionButton(ns("save_ex4"), i18n$t("Save Exercise 4"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 5 content ----
    output$exercise_5_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Drivers giving rise to Activities")),
          actionButton(ns("help_ex5"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Identify the underlying drivers that motivate human activities.")),
          p(i18n$t("Complete columns BC-BK in the Master Data Sheet. Link Drivers to Activities from Exercise 4."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Add Drivers")),
            actionButton(ns("add_d"), i18n$t("Add Driver"), icon = icon("plus"), class = "btn-success"),
            hr(),
            uiOutput(ns("d_entries"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Current Drivers")),
            DTOutput(ns("d_table"))
          )
        ),

        actionButton(ns("save_ex5"), i18n$t("Save Exercise 5"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercise 6 content ----
    output$exercise_6_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Closing the Loop: Drivers to Goods & Benefits")),
          actionButton(ns("help_ex6"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Complete the feedback loop by linking Drivers back to Goods & Benefits.")),
          p(i18n$t("This creates the circular DAPSI(W)R(M) framework showing how drivers ultimately affect welfare."))
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Driver to Goods/Benefits Connections")),
            p(i18n$t("Select drivers and the goods/benefits they influence (positively or negatively):")),
            uiOutput(ns("loop_connections"))
          )
        ),

        fluidRow(
          column(12,
            h5(i18n$t("Loop Closure Summary")),
            plotOutput(ns("loop_diagram"), height = "400px")
          )
        ),

        actionButton(ns("save_ex6"), i18n$t("Save Exercise 6"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercises 7-9 content ----
    output$exercise_789_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Causal Loop Diagram Creation and Export")),
          actionButton(ns("help_ex789"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Exercise 7:")), " ", i18n$t("Creating Impact-based CLD in Kumu")),
          p(strong(i18n$t("Exercise 8:")), " ", i18n$t("Moving from Causal Logic Chains to Causal Loops")),
          p(strong(i18n$t("Exercise 9:")), " ", i18n$t("Exporting CLD for further analysis"))
        ),

        fluidRow(
          column(6,
            h5(i18n$t("Adjacency Matrix Review")),
            p(i18n$t("Review the connections between DAPSI(W)R(M) elements:")),
            selectInput(ns("adj_matrix_select"), i18n$t("Select Matrix Type:"),
                       choices = c("Goods/Benefits to ES" = "gb_es",
                                 "ES to MPF" = "es_mpf",
                                 "MPF to Pressures" = "mpf_p",
                                 "Pressures to Activities" = "p_a",
                                 "Activities to Drivers" = "a_d",
                                 "Drivers to Goods/Benefits" = "d_gb")),
            DTOutput(ns("adj_matrix_view"))
          ),
          column(6,
            h5(i18n$t("Kumu Export Options")),
            p(i18n$t("Prepare data for import into Kumu visualization software:")),
            checkboxGroupInput(ns("export_options"), i18n$t("Include in Export:"),
                              choices = c("Elements (nodes)" = "elements",
                                        "Connections (edges)" = "connections",
                                        "Element attributes" = "attributes",
                                        "Loop identifiers" = "loops"),
                              selected = c("elements", "connections")),
            br(),
            downloadButton(ns("download_kumu"), i18n$t("Download Kumu CSV Files"), class = "btn-info"),
            br(), br(),
            downloadButton(ns("download_excel"), i18n$t("Download Complete Excel Workbook"), class = "btn-success")
          )
        ),

        actionButton(ns("save_ex789"), i18n$t("Save Exercises 7-9"), class = "btn-primary"),
        hr()
      )
    })

    # Render Exercises 10-12 content ----
    output$exercise_101112_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Clarifying, Metrics, and Validation")),
          actionButton(ns("help_ex101112"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Exercise 10:")), " ", i18n$t("Clarifying - Endogenisation and Encapsulation")),
          p(strong(i18n$t("Exercise 11:")), " ", i18n$t("Metrics, Root Causes, and Leverage Points")),
          p(strong(i18n$t("Exercise 12:")), " ", i18n$t("Presenting and Validating Results"))
        ),

        # Exercise 10: Clarifying
        h5(i18n$t("Exercise 10: Clarifying the CLD")),
        fluidRow(
          column(6,
            textAreaInput(ns("endogenisation_notes"), i18n$t("Endogenisation Notes:"),
                         placeholder = i18n$t("What external factors should be brought inside the system boundary?"),
                         rows = 4)
          ),
          column(6,
            textAreaInput(ns("encapsulation_notes"), i18n$t("Encapsulation Notes:"),
                         placeholder = i18n$t("What detailed processes can be simplified or grouped?"),
                         rows = 4)
          )
        ),

        hr(),

        # Exercise 11: Metrics and Leverage
        h5(i18n$t("Exercise 11: Metrics and Leverage Points")),
        fluidRow(
          column(6,
            h6(i18n$t("Root Causes Identified")),
            uiOutput(ns("root_causes_ui"))
          ),
          column(6,
            h6(i18n$t("Leverage Points")),
            uiOutput(ns("leverage_points_ui"))
          )
        ),

        hr(),

        # Exercise 12: Validation
        h5(i18n$t("Exercise 12: Presenting and Validating")),
        fluidRow(
          column(12,
            textAreaInput(ns("validation_notes"), i18n$t("Validation Notes:"),
                         placeholder = i18n$t("Record stakeholder feedback, validation workshop results, expert reviews..."),
                         rows = 6),
            checkboxGroupInput(ns("validation_status"), i18n$t("Validation Completed:"),
                              choices = c("Internal team review" = "internal",
                                        "Stakeholder workshop" = "stakeholder",
                                        "Expert peer review" = "expert",
                                        "Final approval" = "final"))
          )
        ),

        actionButton(ns("save_ex101112"), i18n$t("Save Exercises 10-12"), class = "btn-primary"),
        hr()
      )
    })

    # Render BOT Graphs content ----
    output$bot_graphs_content <- renderUI({
      tagList(
        div(style = "display: flex; justify-content: space-between; align-items: center;",
          h4(i18n$t("Behaviour Over Time (BOT) Graphs")),
          actionButton(ns("help_bot"), i18n$t("Help"), icon = icon("question-circle"), class = "btn-info btn-sm")
        ),
        wellPanel(
          p(strong(i18n$t("Purpose:")), " ", i18n$t("Visualize how indicators change over time to understand system dynamics."))
        ),

        fluidRow(
          column(4,
            selectInput(ns("bot_element_type"), i18n$t("Element Type:"),
                       choices = c("Goods & Benefits" = "gb",
                                 "Ecosystem Services" = "es",
                                 "Marine Processes" = "mpf",
                                 "Pressures" = "p",
                                 "Activities" = "a",
                                 "Drivers" = "d")),
            uiOutput(ns("bot_element_select")),
            br(),
            h6(i18n$t("Add Time Series Data")),
            numericInput(ns("bot_year"), i18n$t("Year:"), value = 2024, min = 1900, max = 2100),
            numericInput(ns("bot_value"), i18n$t("Value:"), value = 0),
            textInput(ns("bot_unit"), i18n$t("Unit:"), placeholder = i18n$t("e.g., tonnes, %, index")),
            actionButton(ns("add_bot_point"), i18n$t("Add Data Point"), icon = icon("plus"))
          ),
          column(8,
            h5(i18n$t("Time Series Plot")),
            plotOutput(ns("bot_plot"), height = "400px"),
            br(),
            h6(i18n$t("Current Data")),
            DTOutput(ns("bot_data_table"))
          )
        ),

        actionButton(ns("save_bot"), i18n$t("Save BOT Data"), class = "btn-primary"),
        hr()
      )
    })

    # Render Data Management content ----
    output$data_management_content <- renderUI({
      tagList(
        h4(i18n$t("Import/Export and Data Management")),

        fluidRow(
          column(12,
            wellPanel(
              h5(i18n$t("Documentation")),
              p(i18n$t("Comprehensive guides for using the ISA Data Entry module:")),
              fluidRow(
                column(4,
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = "ISA_User_Guide.md",
                    target = "_blank",
                    icon("book"),
                    " ", i18n$t("Open User Guide")
                  )
                ),
                column(4,
                  downloadButton(ns("download_guidance_pdf"), i18n$t("ISA Guidance Document (PDF)"), class = "btn-info btn-block")
                ),
                column(4,
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = "Kumu_Code_Style.txt",
                    target = "_blank",
                    icon("code"),
                    " ", i18n$t("Kumu Styling Code")
                  )
                )
              )
            )
          )
        ),

        hr(),

        fluidRow(
          column(6,
            wellPanel(
              h5(i18n$t("Import Data")),
              p(i18n$t("Load existing ISA data from Excel workbook:")),
              fileInput(ns("import_file"), i18n$t("Choose Excel File (.xlsx):"),
                       accept = c(".xlsx")),
              actionButton(ns("import_data"), i18n$t("Import Data"), class = "btn-warning")
            )
          ),
          column(6,
            wellPanel(
              h5(i18n$t("Export Data")),
              p(i18n$t("Save current ISA analysis to Excel workbook:")),
              textInput(ns("export_filename"), i18n$t("Filename:"), value = "ISA_Export"),
              downloadButton(ns("export_data"), i18n$t("Export to Excel"), class = "btn-success")
            )
          )
        ),

        hr(),

        fluidRow(
          column(12,
            wellPanel(
              h5(i18n$t("Reset Data")),
              p(strong(i18n$t("Warning:")), " ", i18n$t("This will clear all entered data. This action cannot be undone.")),
              actionButton(ns("reset_confirm"), i18n$t("Reset All Data"), class = "btn-danger")
            )
          )
        )
      )
    })

    # Exercise 0: Save case information ----
    observeEvent(input$save_ex0, {
      # Validate all Exercise 0 inputs
      validations <- list(
        validate_text_input(input$case_name, "Case Study Name",
                           required = TRUE, min_length = 3, max_length = 200,
                           session = session),
        validate_text_input(input$case_description, "Case Description",
                           required = TRUE, min_length = 10, max_length = 1000,
                           session = session),
        validate_text_input(input$geographic_scope, "Geographic Scope",
                           required = TRUE, min_length = 3,
                           session = session),
        validate_text_input(input$temporal_scope, "Temporal Scope",
                           required = TRUE, min_length = 3,
                           session = session),
        validate_text_input(input$welfare_impacts, "Welfare Impacts",
                           required = FALSE, max_length = 2000,
                           session = session),
        validate_text_input(input$key_stakeholders, "Key Stakeholders",
                           required = FALSE, max_length = 1000,
                           session = session)
      )

      # Check all validations
      if (!validate_all(validations, session)) {
        return()  # Stop if validation fails
      }

      # All valid - save data with cleaned values
      isa_data$case_info <- list(
        name = validations[[1]]$value,
        description = validations[[2]]$value,
        geographic_scope = validations[[3]]$value,
        temporal_scope = validations[[4]]$value,
        welfare_impacts = if (!is.null(validations[[5]]$value)) validations[[5]]$value else "",
        key_stakeholders = if (!is.null(validations[[6]]$value)) validations[[6]]$value else ""
      )

      showNotification("Exercise 0 saved successfully!", type = "message")
      log_message("Exercise 0 case information saved", "INFO")
    })

    # Exercise 1: Goods & Benefits ----
    observeEvent(input$add_gb, {
      isa_data$gb_counter <- isa_data$gb_counter + 1
      current_id <- isa_data$gb_counter

      insertUI(
        selector = paste0("#", ns("gb_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("gb_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("gb_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Fish catch"))),
            column(3, selectInput(ns(paste0("gb_type_", current_id)), i18n$t("Type:"),
                                 choices = c("Provisioning", "Regulating", "Cultural", "Supporting"))),
            column(6, textInput(ns(paste0("gb_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, textInput(ns(paste0("gb_stakeholder_", current_id)), i18n$t("Stakeholder:"))),
            column(3, selectInput(ns(paste0("gb_importance_", current_id)), i18n$t("Importance:"),
                                 choices = c("High", "Medium", "Low"))),
            column(3, selectInput(ns(paste0("gb_trend_", current_id)), i18n$t("Trend:"),
                                 choices = c("Increasing", "Stable", "Decreasing", "Unknown"))),
            column(3, actionButton(ns(paste0("gb_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("gb_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("gb_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$gb_table <- renderDT({
      datatable(isa_data$goods_benefits, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex1, {
      # Check if at least one entry exists
      if (isa_data$gb_counter == 0) {
        showNotification("Please add at least one Good/Benefit entry before saving.",
                        type = "warning", session = session)
        return()
      }

      # Collect and validate all GB entries
      gb_df <- data.frame()
      validation_errors <- c()

      for(i in 1:isa_data$gb_counter) {
        name_val <- input[[paste0("gb_name_", i)]]
        type_val <- input[[paste0("gb_type_", i)]]
        desc_val <- input[[paste0("gb_desc_", i)]]
        stakeholder_val <- input[[paste0("gb_stakeholder_", i)]]
        importance_val <- input[[paste0("gb_importance_", i)]]
        trend_val <- input[[paste0("gb_trend_", i)]]

        # Skip removed entries (where name is NULL)
        if(is.null(name_val)) next

        # Only validate and include entries with a name
        if(name_val != "") {
          # Validate this entry
          entry_validations <- list(
            validate_text_input(name_val, paste0("G&B ", i, " Name"),
                               required = TRUE, min_length = 2, max_length = 200,
                               session = NULL),  # Don't show notification per entry
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

          # Collect validation errors
          for (v in entry_validations) {
            if (!v$valid) {
              validation_errors <- c(validation_errors, v$message)
            }
          }

          # Add to data frame if individual validations pass
          if (all(sapply(entry_validations, function(v) v$valid))) {
            gb_df <- rbind(gb_df, data.frame(
              ID = paste0("GB", sprintf("%03d", i)),
              Name = entry_validations[[1]]$value,
              Type = entry_validations[[2]]$value,
              Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
              Stakeholder = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
              Importance = importance_val,
              Trend = trend_val,
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # Show validation errors if any
      if (length(validation_errors) > 0) {
        showModal(modalDialog(
          title = tags$div(icon("exclamation-triangle"), " Validation Errors"),
          tags$div(
            tags$p(strong("Please fix the following issues before saving:")),
            tags$ul(
              lapply(validation_errors, function(err) tags$li(err))
            )
          ),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }

      # Check if we have at least one valid entry
      if (nrow(gb_df) == 0) {
        showNotification("Please add at least one valid Good/Benefit entry.",
                        type = "warning", session = session)
        return()
      }

      # Save if all validations pass
      isa_data$goods_benefits <- gb_df
      showNotification(paste("Exercise 1 saved:", nrow(gb_df), "Goods & Benefits"),
                      type = "message", session = session)
      log_message(paste("Exercise 1 saved with", nrow(gb_df), "entries"), "INFO")
    })

    # Exercise 2a: Ecosystem Services ----
    observeEvent(input$add_es, {
      isa_data$es_counter <- isa_data$es_counter + 1
      current_id <- isa_data$es_counter

      insertUI(
        selector = paste0("#", ns("es_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("es_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("es_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Fish production"))),
            column(3, selectInput(ns(paste0("es_type_", current_id)), i18n$t("ES Type:"),
                                 choices = c("Provisioning", "Regulating", "Cultural", "Supporting"))),
            column(6, textInput(ns(paste0("es_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, selectInput(ns(paste0("es_linkedgb_", current_id)), i18n$t("Linked to G&B:"),
                                 choices = c("", paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name)))),
            column(3, textInput(ns(paste0("es_mechanism_", current_id)), i18n$t("Mechanism:"))),
            column(4, selectInput(ns(paste0("es_confidence_", current_id)), i18n$t("Confidence:"),
                                 choices = c("High", "Medium", "Low"))),
            column(2, actionButton(ns(paste0("es_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("es_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("es_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$es_table <- renderDT({
      datatable(isa_data$ecosystem_services, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex2a, {
      # Check if at least one entry exists
      if (isa_data$es_counter == 0) {
        showNotification("Please add at least one Ecosystem Service entry before saving.",
                        type = "warning", session = session)
        return()
      }

      # Collect and validate all ES entries
      es_df <- data.frame()
      validation_errors <- c()

      for(i in 1:isa_data$es_counter) {
        name_val <- input[[paste0("es_name_", i)]]
        type_val <- input[[paste0("es_type_", i)]]
        desc_val <- input[[paste0("es_desc_", i)]]
        linkedgb_val <- input[[paste0("es_linkedgb_", i)]]
        mechanism_val <- input[[paste0("es_mechanism_", i)]]
        confidence_val <- input[[paste0("es_confidence_", i)]]

        # Skip removed entries
        if(is.null(name_val)) next

        # Only validate and include entries with a name
        if(name_val != "") {
          # Validate this entry
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

          # Collect validation errors
          for (v in entry_validations) {
            if (!v$valid) {
              validation_errors <- c(validation_errors, v$message)
            }
          }

          # Add to data frame if validations pass
          if (all(sapply(entry_validations, function(v) v$valid))) {
            es_df <- rbind(es_df, data.frame(
              ID = paste0("ES", sprintf("%03d", i)),
              Name = entry_validations[[1]]$value,
              Type = entry_validations[[2]]$value,
              Description = if (!is.null(entry_validations[[3]]$value)) entry_validations[[3]]$value else "",
              LinkedGB = linkedgb_val,
              Mechanism = if (!is.null(entry_validations[[4]]$value)) entry_validations[[4]]$value else "",
              Confidence = confidence_val,
              stringsAsFactors = FALSE
            ))
          }
        }
      }

      # Show validation errors if any
      if (length(validation_errors) > 0) {
        showModal(modalDialog(
          title = tags$div(icon("exclamation-triangle"), " Validation Errors"),
          tags$div(
            tags$p(strong("Please fix the following issues before saving:")),
            tags$ul(
              lapply(validation_errors, function(err) tags$li(err))
            )
          ),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }

      # Check if we have at least one valid entry
      if (nrow(es_df) == 0) {
        showNotification("Please add at least one valid Ecosystem Service entry.",
                        type = "warning", session = session)
        return()
      }

      # Save if all validations pass
      isa_data$ecosystem_services <- es_df
      showNotification(paste("Exercise 2a saved:", nrow(es_df), "Ecosystem Services"),
                      type = "message", session = session)
      log_message(paste("Exercise 2a saved with", nrow(es_df), "entries"), "INFO")
    })

    # Exercise 2b: Marine Processes and Functioning ----
    observeEvent(input$add_mpf, {
      current_id <- isa_data$mpf_counter + 1
      isa_data$mpf_counter <- current_id

      insertUI(
        selector = paste0("#", ns("mpf_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("mpf_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("mpf_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Primary production"))),
            column(3, selectInput(ns(paste0("mpf_type_", current_id)), i18n$t("Process Type:"),
                                 choices = c("Biological", "Chemical", "Physical", "Ecological"))),
            column(6, textInput(ns(paste0("mpf_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, selectInput(ns(paste0("mpf_linkedes_", current_id)), i18n$t("Linked to ES:"),
                                 choices = c("", paste0(isa_data$ecosystem_services$ID, ": ", isa_data$ecosystem_services$Name)))),
            column(3, textInput(ns(paste0("mpf_mechanism_", current_id)), i18n$t("Mechanism:"))),
            column(4, textInput(ns(paste0("mpf_spatial_", current_id)), i18n$t("Spatial Scale:"))),
            column(2, actionButton(ns(paste0("mpf_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("mpf_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("mpf_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$mpf_table <- renderDT({
      datatable(isa_data$marine_processes, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex2b, {
      mpf_df <- data.frame()
      for(i in 1:isa_data$mpf_counter) {
        name_val <- input[[paste0("mpf_name_", i)]]
        if(!is.null(name_val) && name_val != "") {
          mpf_df <- rbind(mpf_df, data.frame(
            ID = paste0("MPF", sprintf("%03d", i)),
            Name = name_val,
            Type = input[[paste0("mpf_type_", i)]],
            Description = input[[paste0("mpf_desc_", i)]],
            LinkedES = input[[paste0("mpf_linkedes_", i)]],
            Mechanism = input[[paste0("mpf_mechanism_", i)]],
            Spatial = input[[paste0("mpf_spatial_", i)]],
            stringsAsFactors = FALSE
          ))
        }
      }
      isa_data$marine_processes <- mpf_df
      showNotification(paste("Exercise 2b saved:", nrow(mpf_df), "Marine Processes"), type = "message")
    })

    # Exercise 3: Pressures ----
    observeEvent(input$add_p, {
      current_id <- isa_data$p_counter + 1
      isa_data$p_counter <- current_id

      insertUI(
        selector = paste0("#", ns("p_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("p_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("p_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Nutrient enrichment"))),
            column(3, selectInput(ns(paste0("p_type_", current_id)), i18n$t("Pressure Type:"),
                                 choices = c("Physical", "Chemical", "Biological", "Multiple"))),
            column(6, textInput(ns(paste0("p_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, selectInput(ns(paste0("p_linkedmpf_", current_id)), i18n$t("Linked to MPF:"),
                                 choices = c("", paste0(isa_data$marine_processes$ID, ": ", isa_data$marine_processes$Name)))),
            column(3, selectInput(ns(paste0("p_intensity_", current_id)), i18n$t("Intensity:"),
                                 choices = c("High", "Medium", "Low", "Unknown"))),
            column(2, textInput(ns(paste0("p_spatial_", current_id)), i18n$t("Spatial:"))),
            column(2, textInput(ns(paste0("p_temporal_", current_id)), i18n$t("Temporal:"))),
            column(2, actionButton(ns(paste0("p_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("p_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("p_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$p_table <- renderDT({
      datatable(isa_data$pressures, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex3, {
      p_df <- data.frame()
      for(i in 1:isa_data$p_counter) {
        name_val <- input[[paste0("p_name_", i)]]
        if(!is.null(name_val) && name_val != "") {
          p_df <- rbind(p_df, data.frame(
            ID = paste0("P", sprintf("%03d", i)),
            Name = name_val,
            Type = input[[paste0("p_type_", i)]],
            Description = input[[paste0("p_desc_", i)]],
            LinkedMPF = input[[paste0("p_linkedmpf_", i)]],
            Intensity = input[[paste0("p_intensity_", i)]],
            Spatial = input[[paste0("p_spatial_", i)]],
            Temporal = input[[paste0("p_temporal_", i)]],
            stringsAsFactors = FALSE
          ))
        }
      }
      isa_data$pressures <- p_df
      showNotification(paste("Exercise 3 saved:", nrow(p_df), "Pressures"), type = "message")
    })

    # Exercise 4: Activities ----
    observeEvent(input$add_a, {
      current_id <- isa_data$a_counter + 1
      isa_data$a_counter <- current_id

      insertUI(
        selector = paste0("#", ns("a_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("a_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("a_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Commercial fishing"))),
            column(3, selectInput(ns(paste0("a_sector_", current_id)), i18n$t("Sector:"),
                                 choices = c("Fisheries", "Aquaculture", "Tourism", "Shipping", "Energy", "Mining", "Other"))),
            column(6, textInput(ns(paste0("a_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, selectInput(ns(paste0("a_linkedp_", current_id)), i18n$t("Linked to Pressure:"),
                                 choices = c("", paste0(isa_data$pressures$ID, ": ", isa_data$pressures$Name)))),
            column(3, selectInput(ns(paste0("a_scale_", current_id)), i18n$t("Scale:"),
                                 choices = c("Local", "Regional", "National", "International"))),
            column(4, selectInput(ns(paste0("a_frequency_", current_id)), i18n$t("Frequency:"),
                                 choices = c("Continuous", "Seasonal", "Occasional", "One-time"))),
            column(2, actionButton(ns(paste0("a_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("a_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("a_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$a_table <- renderDT({
      datatable(isa_data$activities, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex4, {
      a_df <- data.frame()
      for(i in 1:isa_data$a_counter) {
        name_val <- input[[paste0("a_name_", i)]]
        if(!is.null(name_val) && name_val != "") {
          a_df <- rbind(a_df, data.frame(
            ID = paste0("A", sprintf("%03d", i)),
            Name = name_val,
            Sector = input[[paste0("a_sector_", i)]],
            Description = input[[paste0("a_desc_", i)]],
            LinkedP = input[[paste0("a_linkedp_", i)]],
            Scale = input[[paste0("a_scale_", i)]],
            Frequency = input[[paste0("a_frequency_", i)]],
            stringsAsFactors = FALSE
          ))
        }
      }
      isa_data$activities <- a_df
      showNotification(paste("Exercise 4 saved:", nrow(a_df), "Activities"), type = "message")
    })

    # Exercise 5: Drivers ----
    observeEvent(input$add_d, {
      current_id <- isa_data$d_counter + 1
      isa_data$d_counter <- current_id

      insertUI(
        selector = paste0("#", ns("d_entries")),
        where = "beforeEnd",
        ui = div(
          id = ns(paste0("d_panel_", current_id)),
          class = "isa-entry-panel",
          style = "background-color: #ffffff !important; border: 1px solid #dee2e6 !important; border-radius: 8px; padding: 20px; margin-bottom: 15px;",
          fluidRow(
            column(3, textInput(ns(paste0("d_name_", current_id)), i18n$t("Name:"), placeholder = i18n$t("e.g., Economic growth"))),
            column(3, selectInput(ns(paste0("d_type_", current_id)), i18n$t("Driver Type:"),
                                 choices = c("Economic", "Social", "Technological", "Political", "Environmental", "Demographic"))),
            column(6, textInput(ns(paste0("d_desc_", current_id)), i18n$t("Description:")))
          ),
          fluidRow(
            column(3, selectInput(ns(paste0("d_linkeda_", current_id)), i18n$t("Linked to Activity:"),
                                 choices = c("", paste0(isa_data$activities$ID, ": ", isa_data$activities$Name)))),
            column(3, selectInput(ns(paste0("d_trend_", current_id)), i18n$t("Trend:"),
                                 choices = c("Increasing", "Stable", "Decreasing", "Cyclical", "Uncertain"))),
            column(4, selectInput(ns(paste0("d_control_", current_id)), i18n$t("Controllability:"),
                                 choices = c("High", "Medium", "Low", "None"))),
            column(2, actionButton(ns(paste0("d_remove_", current_id)), i18n$t("Remove"), class = "btn-danger btn-sm"))
          )
        )
      )

      # Add remove button handler for this entry
      observeEvent(input[[paste0("d_remove_", current_id)]], {
        removeUI(selector = paste0("#", ns(paste0("d_panel_", current_id))))
        showNotification("Entry removed", type = "message", duration = 2)
      }, ignoreInit = TRUE, once = TRUE)
    })

    output$d_table <- renderDT({
      datatable(isa_data$drivers, options = list(pageLength = 10), rownames = FALSE)
    })

    observeEvent(input$save_ex5, {
      d_df <- data.frame()
      for(i in 1:isa_data$d_counter) {
        name_val <- input[[paste0("d_name_", i)]]
        if(!is.null(name_val) && name_val != "") {
          d_df <- rbind(d_df, data.frame(
            ID = paste0("D", sprintf("%03d", i)),
            Name = name_val,
            Type = input[[paste0("d_type_", i)]],
            Description = input[[paste0("d_desc_", i)]],
            LinkedA = input[[paste0("d_linkeda_", i)]],
            Trend = input[[paste0("d_trend_", i)]],
            Controllability = input[[paste0("d_control_", i)]],
            stringsAsFactors = FALSE
          ))
        }
      }
      isa_data$drivers <- d_df
      showNotification(paste("Exercise 5 saved:", nrow(d_df), "Drivers"), type = "message")
    })

    # Exercise 6: Loop connections UI ----
    output$loop_connections <- renderUI({
      req(isa_data$drivers, isa_data$goods_benefits)

      if (nrow(isa_data$drivers) == 0 || nrow(isa_data$goods_benefits) == 0) {
        return(p(i18n$t("Please complete Exercises 1 and 5 first to create Goods & Benefits and Drivers.")))
      }

      driver_choices <- setNames(isa_data$drivers$ID,
                                 paste0(isa_data$drivers$ID, ": ", isa_data$drivers$Name))
      gb_choices <- setNames(isa_data$goods_benefits$ID,
                            paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name))

      tagList(
        fluidRow(
          column(3,
            selectInput(ns("loop_driver"), i18n$t("Driver:"), choices = driver_choices)
          ),
          column(1,
            div(style = "text-align: center; padding-top: 25px;", "→")
          ),
          column(3,
            selectInput(ns("loop_gb"), i18n$t("Goods/Benefit:"), choices = gb_choices)
          ),
          column(2,
            selectInput(ns("loop_effect"), i18n$t("Effect:"),
                       choices = c("Positive" = "+", "Negative" = "-"))
          ),
          column(2,
            selectInput(ns("loop_strength"), i18n$t("Strength:"),
                       choices = c("Weak" = "weak", "Medium" = "medium", "Strong" = "strong"))
          ),
          column(1,
            br(),
            actionButton(ns("add_loop"), i18n$t("Add"), icon = icon("plus"), class = "btn-success btn-sm")
          )
        ),
        fluidRow(
          column(12,
            sliderInput(ns("loop_confidence"), i18n$t("Confidence Level:"),
                       min = 1, max = 5, value = 3, step = 1,
                       ticks = TRUE,
                       post = c(" - Very Low", " - Low", " - Medium", " - High", " - Very High")[3])
          )
        ),
        hr(),
        fluidRow(
          column(12,
            h5(i18n$t("Current Loop Connections:")),
            DTOutput(ns("loop_connections_table"))
          )
        )
      )
    })

    # Exercise 6: Loop closure visualization ----
    output$loop_diagram <- renderPlot({
      # Placeholder for loop closure diagram
      plot(1:10, 1:10, main = "DAPSI(W)R(M) Loop Closure Diagram",
           xlab = "System Components", ylab = "Connections",
           type = "n")
      text(5, 5, "Loop diagram will be generated\nfrom your data entries", cex = 1.5)
    })

    # Add loop connection ----
    observeEvent(input$add_loop, {
      req(input$loop_driver, input$loop_gb, input$loop_effect, input$loop_strength, input$loop_confidence)

      new_connection <- data.frame(
        DriverID = input$loop_driver,
        GBID = input$loop_gb,
        Effect = input$loop_effect,
        Strength = input$loop_strength,
        Confidence = input$loop_confidence,
        Mechanism = "",
        stringsAsFactors = FALSE
      )

      rv$loop_connections <- rbind(rv$loop_connections, new_connection)
      showNotification("Loop connection added", type = "message")
    })

    # Display loop connections table ----
    output$loop_connections_table <- renderDT({
      if (nrow(rv$loop_connections) == 0) {
        return(data.frame(Message = "No loop connections yet"))
      }

      rv$loop_connections %>%
        mutate(
          Connection = paste0(DriverID, " → ", GBID),
          Polarity = ifelse(Effect == "+", "Positive", "Negative"),
          ConfidenceLabel = c("Very Low", "Low", "Medium", "High", "Very High")[Confidence]
        ) %>%
        select(Connection, Polarity, Strength, ConfidenceLabel) %>%
        rename(`Confidence` = ConfidenceLabel)
    }, options = list(pageLength = 5, dom = 't'), rownames = FALSE)

    # Save Exercise 6 ----
    observeEvent(input$save_ex6, {
      isa_data$loop_connections <- rv$loop_connections

      # Convert loop_connections to d_gb adjacency matrix
      if (nrow(rv$loop_connections) > 0) {
        n_drivers <- nrow(isa_data$drivers)
        n_gb <- nrow(isa_data$goods_benefits)

        # Initialize empty matrix
        d_gb_matrix <- matrix("", nrow = n_gb, ncol = n_drivers)
        rownames(d_gb_matrix) <- isa_data$goods_benefits$ID
        colnames(d_gb_matrix) <- isa_data$drivers$ID

        # Fill matrix with connections
        for (i in 1:nrow(rv$loop_connections)) {
          conn <- rv$loop_connections[i, ]
          gb_idx <- which(isa_data$goods_benefits$ID == conn$GBID)
          d_idx <- which(isa_data$drivers$ID == conn$DriverID)

          if (length(gb_idx) > 0 && length(d_idx) > 0) {
            # Format: "effect+strength:confidence"
            value <- paste0(conn$Effect, conn$Strength, ":", conn$Confidence)
            d_gb_matrix[gb_idx, d_idx] <- value
          }
        }

        # Store in adjacency_matrices
        if (is.null(isa_data$adjacency_matrices)) {
          isa_data$adjacency_matrices <- list()
        }
        isa_data$adjacency_matrices$d_gb <- d_gb_matrix
      }

      showNotification(paste("Exercise 6 saved:", nrow(rv$loop_connections), "loop connections"),
                      type = "message")
    })

    # BOT Graphs ----
    output$bot_element_select <- renderUI({
      element_type <- input$bot_element_type
      choices <- switch(element_type,
        "gb" = paste0(isa_data$goods_benefits$ID, ": ", isa_data$goods_benefits$Name),
        "es" = paste0(isa_data$ecosystem_services$ID, ": ", isa_data$ecosystem_services$Name),
        "mpf" = paste0(isa_data$marine_processes$ID, ": ", isa_data$marine_processes$Name),
        "p" = paste0(isa_data$pressures$ID, ": ", isa_data$pressures$Name),
        "a" = paste0(isa_data$activities$ID, ": ", isa_data$activities$Name),
        "d" = paste0(isa_data$drivers$ID, ": ", isa_data$drivers$Name),
        character(0)
      )
      selectInput(ns("bot_element"), i18n$t("Select Element:"), choices = choices)
    })

    # Exercise 11: Root Causes UI ----
    output$root_causes_ui <- renderUI({
      p(i18n$t("Root causes analysis will be displayed here based on your CLD structure."))
    })

    # Exercise 11: Leverage Points UI ----
    output$leverage_points_ui <- renderUI({
      p(i18n$t("Leverage points analysis will be displayed here based on your system dynamics."))
    })

    output$bot_plot <- renderPlot({
      if(nrow(isa_data$bot_data) == 0) {
        plot(1, 1, type = "n", main = "No BOT data available", xlab = "Year", ylab = "Value")
        return()
      }
      # Plot BOT data
      plot(1, 1, type = "n", main = "Behaviour Over Time", xlab = "Year", ylab = "Value")
      text(1, 1, "BOT plot will show time series\nof selected element", cex = 1.2)
    })

    output$bot_data_table <- renderDT({
      datatable(isa_data$bot_data, options = list(pageLength = 5), rownames = FALSE)
    })

    # Data export handlers ----
    output$download_excel <- downloadHandler(
      filename = function() {
        paste0("ISA_Analysis_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        # Create Excel workbook with all ISA data
        wb <- createWorkbook()

        # Add sheets for each exercise
        addWorksheet(wb, "Case_Info")
        addWorksheet(wb, "Goods_Benefits")
        addWorksheet(wb, "Ecosystem_Services")
        addWorksheet(wb, "Marine_Processes")
        addWorksheet(wb, "Pressures")
        addWorksheet(wb, "Activities")
        addWorksheet(wb, "Drivers")
        addWorksheet(wb, "BOT_Data")

        # Write data
        writeData(wb, "Goods_Benefits", isa_data$goods_benefits)
        writeData(wb, "Ecosystem_Services", isa_data$ecosystem_services)
        writeData(wb, "Marine_Processes", isa_data$marine_processes)
        writeData(wb, "Pressures", isa_data$pressures)
        writeData(wb, "Activities", isa_data$activities)
        writeData(wb, "Drivers", isa_data$drivers)
        writeData(wb, "BOT_Data", isa_data$bot_data)

        saveWorkbook(wb, file, overwrite = TRUE)
      }
    )

    output$download_kumu <- downloadHandler(
      filename = function() {
        paste0("Kumu_Export_", Sys.Date(), ".zip")
      },
      content = function(file) {
        # Create Kumu-compatible CSV files
        temp_dir <- tempdir()

        # Elements file
        all_elements <- rbind(
          data.frame(Label = isa_data$goods_benefits$Name, Type = "Goods & Benefits", ID = isa_data$goods_benefits$ID),
          data.frame(Label = isa_data$ecosystem_services$Name, Type = "Ecosystem Service", ID = isa_data$ecosystem_services$ID),
          data.frame(Label = isa_data$marine_processes$Name, Type = "Marine Process", ID = isa_data$marine_processes$ID),
          data.frame(Label = isa_data$pressures$Name, Type = "Pressure", ID = isa_data$pressures$ID),
          data.frame(Label = isa_data$activities$Name, Type = "Activity", ID = isa_data$activities$ID),
          data.frame(Label = isa_data$drivers$Name, Type = "Driver", ID = isa_data$drivers$ID)
        )
        write.csv(all_elements, file.path(temp_dir, "elements.csv"), row.names = FALSE)

        # Connections file (to be built from adjacency matrices)
        connections <- data.frame(From = character(), To = character(), Type = character())
        write.csv(connections, file.path(temp_dir, "connections.csv"), row.names = FALSE)

        # Create zip file
        zip(file, files = c(file.path(temp_dir, "elements.csv"), file.path(temp_dir, "connections.csv")))
      }
    )

    # Download PDF guidance document
    output$download_guidance_pdf <- downloadHandler(
      filename = function() {
        "MarineSABRES_Simple_SES_DRAFT_Guidance.pdf"
      },
      content = function(file) {
        file.copy("Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf", file)
      }
    )

    # Help Modals ----

    # Main ISA Framework Guide
    observeEvent(input$help_main, {
      showModal(modalDialog(
        title = "ISA Framework Guide - DAPSI(W)R(M)",
        size = "l",
        easyClose = TRUE,

        h4("Overview of the Integrated Systems Analysis Framework"),
        p("The ISA framework uses the", strong("DAPSI(W)R(M)"), "approach to analyze marine social-ecological systems:"),

        tags$ul(
          tags$li(strong("D - Drivers:"), "Underlying social, economic, and policy forces that motivate human activities
                  (e.g., population growth, economic development, technological change)"),
          tags$li(strong("A - Activities:"), "Human uses of marine and coastal environments
                  (e.g., fishing, aquaculture, shipping, tourism)"),
          tags$li(strong("P - Pressures:"), "Direct stressors on the marine environment resulting from activities
                  (e.g., nutrient enrichment, physical disturbance, chemical pollution)"),
          tags$li(strong("S - State Changes:"), "Changes in ecosystem condition and functioning, represented through:"),
          tags$ul(
            tags$li(strong("W - (Impact on) Welfare:"), "Goods and Benefits derived from the ecosystem"),
            tags$li(strong("MPF - Marine Processes & Functioning:"), "Biological, chemical, and physical processes"),
            tags$li(strong("ES - Ecosystem Services:"), "Benefits that ecosystems provide to people")
          ),
          tags$li(strong("R - Responses:"), "Societal actions to address problems (as Measures)"),
          tags$li(strong("M - Measures:"), "Policy interventions and management actions")
        ),

        hr(),
        h5("The ISA Process"),
        p("This tool guides you through a systematic 13-exercise process:"),
        tags$ol(
          tags$li(strong("Exercise 0:"), "Understand the complexity and scope of your case study"),
          tags$li(strong("Exercises 1-5:"), "Build the causal chain from Drivers → Activities → Pressures → State → Welfare"),
          tags$li(strong("Exercise 6:"), "Close the feedback loop connecting Drivers back to Goods & Benefits"),
          tags$li(strong("Exercises 7-9:"), "Create and export Causal Loop Diagrams (CLD) using Kumu"),
          tags$li(strong("Exercises 10-12:"), "Analyze, validate, and present your findings")
        ),

        hr(),
        h5("Key Principles"),
        tags$ul(
          tags$li("Work systematically through each exercise in sequence"),
          tags$li("Engage with stakeholders to ensure comprehensive coverage"),
          tags$li("Link elements explicitly to show causal relationships"),
          tags$li("Use Behaviour Over Time (BOT) graphs to show temporal dynamics"),
          tags$li("Validate your analysis with domain experts and stakeholders")
        ),

        hr(),
        h5("Additional Resources"),
        p(strong("Complete User Guide:"), "For comprehensive step-by-step instructions, examples, and troubleshooting:"),
        tags$div(
          style = "text-align: center; margin: 15px 0;",
          tags$a(
            class = "btn btn-success btn-lg",
            href = "ISA_User_Guide.md",
            target = "_blank",
            icon("book"),
            " Open Complete User Guide"
          )
        ),
        p(em("For quick help on each exercise, click the Help button within that exercise tab.")),

        footer = modalButton("Close")
      ))
    })

    # Exercise 0: Complexity Help
    observeEvent(input$help_ex0, {
      showModal(modalDialog(
        title = "Exercise 0: Unfolding Complexity and Impacts on Welfare",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("This preliminary exercise helps you understand the full complexity of your marine social-ecological system
          before diving into detailed analysis. It sets the context and boundaries for your ISA."),

        hr(),
        h5("What to Do"),
        tags$ol(
          tags$li(strong("Define Your Case Study:"), "Clearly name and describe your marine system of interest"),
          tags$li(strong("Set Geographic Scope:"), "Define the spatial boundaries (e.g., Baltic Sea, coastal region, marine protected area)"),
          tags$li(strong("Set Temporal Scope:"), "Define the time period under consideration"),
          tags$li(strong("Identify Welfare Impacts:"), "List the main ways the marine system affects human well-being -
                  both positive (benefits) and negative (costs, risks, losses)"),
          tags$li(strong("Identify Key Stakeholders:"), "List who is affected by the system and who makes decisions about it")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Be comprehensive but concise - you'll develop details in later exercises"),
          tags$li("Include diverse perspectives: environmental, economic, social, cultural"),
          tags$li("Consider both obvious and subtle impacts on welfare"),
          tags$li("Think about who benefits and who bears costs"),
          tags$li("Consider different stakeholder groups: resource users, managers, NGOs, scientists, communities")
        ),

        hr(),
        h5("Example"),
        p(strong("Case:"), "Baltic Sea Commercial Fisheries"),
        p(strong("Welfare Impacts:"), "Income from fish sales, employment in fishing industry, food security,
          cultural heritage, declining fish stocks affecting livelihoods, ecosystem degradation"),
        p(strong("Stakeholders:"), "Commercial fishers, coastal communities, fish processors, consumers,
          environmental NGOs, fisheries managers, EU policy makers"),

        footer = modalButton("Close")
      ))
    })

    # Exercise 1: Goods & Benefits Help
    observeEvent(input$help_ex1, {
      showModal(modalDialog(
        title = "Exercise 1: Specifying Goods and Benefits (G&B)",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify and classify the goods and benefits that people derive from the marine ecosystem.
          These represent the 'W' (Welfare) component of DAPSI(W)R(M)."),

        hr(),
        h5("What to Include"),
        p("For each Good/Benefit, specify:"),
        tags$ul(
          tags$li(strong("Name:"), "Clear, concise name (e.g., 'Commercial fish catch', 'Beach recreation')"),
          tags$li(strong("Type:"), "Classification - Provisioning, Regulating, Cultural, or Supporting"),
          tags$li(strong("Description:"), "Brief explanation of what this benefit provides"),
          tags$li(strong("Stakeholder:"), "Who benefits from this?"),
          tags$li(strong("Importance:"), "How critical is this benefit? (High/Medium/Low)"),
          tags$li(strong("Trend:"), "Is this benefit increasing, stable, or decreasing?")
        ),

        hr(),
        h5("Types of Goods & Benefits"),
        tags$ul(
          tags$li(strong("Provisioning:"), "Material outputs - fish, shellfish, seaweed, minerals, energy"),
          tags$li(strong("Regulating:"), "Ecosystem regulation - climate regulation, water purification, coastal protection"),
          tags$li(strong("Cultural:"), "Non-material benefits - recreation, tourism, aesthetic values, cultural heritage, education"),
          tags$li(strong("Supporting:"), "Fundamental processes - nutrient cycling, primary production (note: often captured as Marine Processes)")
        ),

        hr(),
        h5("Examples"),
        tags$ul(
          tags$li("Commercial fish landings (Provisioning)"),
          tags$li("Recreational fishing opportunities (Cultural)"),
          tags$li("Coastal tourism revenue (Cultural)"),
          tags$li("Storm surge protection by coastal wetlands (Regulating)"),
          tags$li("Carbon sequestration in seagrass beds (Regulating)"),
          tags$li("Marine biodiversity for pharmaceutical research (Provisioning)")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Be specific - 'Commercial cod fishery' is better than just 'Fishing'"),
          tags$li("Include both marketed and non-marketed benefits"),
          tags$li("Consider benefits to different stakeholder groups"),
          tags$li("Think about synergies and trade-offs between different benefits"),
          tags$li("Each G&B will receive a unique ID automatically (GB001, GB002, etc.)")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 2a: Ecosystem Services Help
    observeEvent(input$help_ex2a, {
      showModal(modalDialog(
        title = "Exercise 2a: Ecosystem Services (ES) affecting Goods and Benefits",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify the ecosystem services that underpin and contribute to each Good/Benefit identified in Exercise 1.
          This establishes the link between ecosystem functioning and human welfare."),

        hr(),
        h5("What to Include"),
        tags$ul(
          tags$li(strong("Name:"), "Clear name of the ecosystem service"),
          tags$li(strong("Type:"), "Service classification"),
          tags$li(strong("Description:"), "How this service functions"),
          tags$li(strong("Linked to G&B:"), "Which Good/Benefit does this service support?"),
          tags$li(strong("Mechanism:"), "How does this service produce the benefit?"),
          tags$li(strong("Confidence:"), "How certain are you about this linkage? (High/Medium/Low)")
        ),

        hr(),
        h5("Ecosystem Services vs Goods & Benefits"),
        p("Understanding the distinction:"),
        tags$ul(
          tags$li(strong("Ecosystem Service:"), "The capacity of the ecosystem to generate benefits - the potential"),
          tags$li(strong("Good/Benefit:"), "The realized benefit that people actually obtain and value"),
          tags$li(strong("Example:"), "ES = 'Fish stock productivity' → G&B = 'Commercial fish catch'")
        ),

        hr(),
        h5("Examples of ES → G&B Links"),
        tags$ul(
          tags$li("Fish stock recruitment → Commercial fish catch"),
          tags$li("Shellfish filtration → Water quality for tourism"),
          tags$li("Seagrass habitat provision → Nursery function for commercial species"),
          tags$li("Coastal wetland buffering → Storm protection for coastal property"),
          tags$li("Marine scenic beauty → Coastal tourism revenue")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("One G&B may be supported by multiple ES"),
          tags$li("One ES may support multiple G&B"),
          tags$li("Describe the mechanism clearly - this helps validate the linkage"),
          tags$li("Use scientific knowledge and stakeholder input to identify services"),
          tags$li("Consider both direct and indirect linkages")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 2b: Marine Processes Help
    observeEvent(input$help_ex2b, {
      showModal(modalDialog(
        title = "Exercise 2b: Marine Processes and Functioning (MPF)",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify the fundamental marine ecological processes and functions that support ecosystem services.
          This digs deeper into the biophysical system that underpins human benefits."),

        hr(),
        h5("What to Include"),
        tags$ul(
          tags$li(strong("Name:"), "Name of the marine process or ecological function"),
          tags$li(strong("Type:"), "Biological, Chemical, Physical, or Ecological"),
          tags$li(strong("Description:"), "What this process does"),
          tags$li(strong("Linked to ES:"), "Which Ecosystem Service does this process support?"),
          tags$li(strong("Mechanism:"), "How does this process generate the service?"),
          tags$li(strong("Spatial Scale:"), "Where does this occur? (local, regional, basin-wide)")
        ),

        hr(),
        h5("Types of Marine Processes"),
        tags$ul(
          tags$li(strong("Biological:"), "Primary production, predator-prey dynamics, reproduction, migration, species composition"),
          tags$li(strong("Chemical:"), "Nutrient cycling, carbon sequestration, oxygen production, pH regulation"),
          tags$li(strong("Physical:"), "Water circulation, sediment transport, wave action, temperature regulation"),
          tags$li(strong("Ecological:"), "Habitat structure, food web dynamics, biodiversity, resilience")
        ),

        hr(),
        h5("Examples of MPF → ES Links"),
        tags$ul(
          tags$li("Primary production by phytoplankton → Fish stock productivity"),
          tags$li("Seagrass photosynthesis → Oxygen production and carbon storage"),
          tags$li("Mussel bed filtration → Water clarity improvement"),
          tags$li("Coastal wetland vegetation → Wave energy dissipation"),
          tags$li("Fish spawning aggregations → Recruitment to fishable stocks"),
          tags$li("Nutrient uptake by macroalgae → Eutrophication mitigation")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Focus on processes that are relevant to your Ecosystem Services"),
          tags$li("Use scientific knowledge to identify key ecological functions"),
          tags$li("Consider both autogenic (internal) and allogenic (external) processes"),
          tags$li("Think about spatial and temporal scales"),
          tags$li("Multiple processes may contribute to a single ES"),
          tags$li("This is where ecological expertise is most valuable")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 3: Pressures Help
    observeEvent(input$help_ex3, {
      showModal(modalDialog(
        title = "Exercise 3: Specifying Pressures on State Changes",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify the pressures (direct stressors) that affect marine processes and functioning.
          Pressures are the mechanism through which human activities impact the ecosystem state."),

        hr(),
        h5("What to Include"),
        tags$ul(
          tags$li(strong("Name:"), "Clear name of the pressure"),
          tags$li(strong("Type:"), "Physical, Chemical, Biological, or Multiple"),
          tags$li(strong("Description:"), "What is the nature of this stressor?"),
          tags$li(strong("Linked to MPF:"), "Which Marine Process does this pressure affect?"),
          tags$li(strong("Intensity:"), "How strong is this pressure? (High/Medium/Low)"),
          tags$li(strong("Spatial:"), "Where does this pressure occur?"),
          tags$li(strong("Temporal:"), "When/how often? (continuous, seasonal, episodic)")
        ),

        hr(),
        h5("Types of Pressures"),
        tags$ul(
          tags$li(strong("Physical:"), "Seabed abrasion, habitat loss, noise, light, heat, physical disturbance"),
          tags$li(strong("Chemical:"), "Nutrient enrichment, contaminants, acidification, hypoxia, pollutants"),
          tags$li(strong("Biological:"), "Removal of target/non-target species, introduction of non-indigenous species, pathogens"),
          tags$li(strong("Multiple:"), "Pressures with combined physical, chemical, and biological components")
        ),

        hr(),
        h5("Examples of Pressure → MPF Links"),
        tags$ul(
          tags$li("Nutrient enrichment → Altered phytoplankton composition and excessive algal blooms"),
          tags$li("Bottom trawling → Destruction of benthic habitat structure"),
          tags$li("Overfishing → Removal of top predators and altered food web dynamics"),
          tags$li("Coastal development → Loss of coastal wetland area"),
          tags$li("Marine debris → Entanglement and ingestion affecting marine life"),
          tags$li("Underwater noise → Disruption of marine mammal communication and navigation")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("One pressure can affect multiple marine processes"),
          tags$li("Specify the direct mechanism - how exactly does the pressure affect the process?"),
          tags$li("Consider cumulative effects of multiple pressures"),
          tags$li("Include both chronic (ongoing) and acute (episodic) pressures"),
          tags$li("Rate intensity based on scientific evidence and expert judgment"),
          tags$li("Spatial and temporal characteristics help prioritize management actions")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 4: Activities Help
    observeEvent(input$help_ex4, {
      showModal(modalDialog(
        title = "Exercise 4: Specifying Activities affecting Pressures",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify the human activities that generate the pressures on the marine environment.
          Activities are what people actually DO in the marine system."),

        hr(),
        h5("What to Include"),
        tags$ul(
          tags$li(strong("Name:"), "Clear name of the activity"),
          tags$li(strong("Sector:"), "Economic or social sector (Fisheries, Aquaculture, Tourism, Shipping, Energy, etc.)"),
          tags$li(strong("Description:"), "What does this activity involve?"),
          tags$li(strong("Linked to Pressure:"), "Which Pressure(s) does this activity generate?"),
          tags$li(strong("Scale:"), "Geographic extent (Local, Regional, National, International)"),
          tags$li(strong("Frequency:"), "How often? (Continuous, Seasonal, Occasional, One-time)")
        ),

        hr(),
        h5("Categories of Marine Activities"),
        tags$ul(
          tags$li(strong("Fisheries:"), "Commercial fishing, recreational fishing, subsistence fishing"),
          tags$li(strong("Aquaculture:"), "Fish farming, shellfish cultivation, seaweed farming"),
          tags$li(strong("Tourism & Recreation:"), "Beach tourism, wildlife watching, diving, boating"),
          tags$li(strong("Shipping:"), "Cargo transport, cruise ships, ferry services"),
          tags$li(strong("Energy:"), "Offshore wind, oil & gas extraction, tidal/wave energy"),
          tags$li(strong("Mining:"), "Aggregate extraction, deep-sea mining"),
          tags$li(strong("Infrastructure:"), "Port development, coastal construction, cable laying"),
          tags$li(strong("Agriculture:"), "Coastal farming causing nutrient runoff"),
          tags$li(strong("Waste:"), "Sewage discharge, industrial effluent, dumping")
        ),

        hr(),
        h5("Examples of Activity → Pressure Links"),
        tags$ul(
          tags$li("Bottom trawl fishing → Seabed abrasion and habitat disturbance"),
          tags$li("Coastal wastewater discharge → Nutrient enrichment and contamination"),
          tags$li("Shipping traffic → Underwater noise, oil pollution, ballast water introductions"),
          tags$li("Offshore wind farm construction → Underwater noise, habitat loss"),
          tags$li("Coastal tourism → Physical disturbance of sensitive habitats, litter"),
          tags$li("Agricultural runoff → Nutrient and pesticide pollution")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Be specific about the type of activity - 'Bottom trawling' not just 'Fishing'"),
          tags$li("One activity often generates multiple pressures"),
          tags$li("Consider both direct and indirect pathways (e.g., agriculture is land-based but affects marine systems)"),
          tags$li("Include the intensity and spatial extent"),
          tags$li("Think about seasonal patterns"),
          tags$li("Consider both authorized and unauthorized activities")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 5: Drivers Help
    observeEvent(input$help_ex5, {
      showModal(modalDialog(
        title = "Exercise 5: Drivers giving rise to Activities",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Identify the underlying drivers - the fundamental social, economic, technological, and policy forces
          that motivate and enable human activities. Understanding drivers is key to identifying leverage points for change."),

        hr(),
        h5("What to Include"),
        tags$ul(
          tags$li(strong("Name:"), "Clear name of the driver"),
          tags$li(strong("Type:"), "Economic, Social, Technological, Political, Environmental, or Demographic"),
          tags$li(strong("Description:"), "What is this force and how does it work?"),
          tags$li(strong("Linked to Activity:"), "Which Activity(ies) does this driver motivate?"),
          tags$li(strong("Trend:"), "Is this driver Increasing, Stable, Decreasing, Cyclical, or Uncertain?"),
          tags$li(strong("Controllability:"), "Can this be influenced by policy? (High/Medium/Low/None)")
        ),

        hr(),
        h5("Types of Drivers"),
        tags$ul(
          tags$li(strong("Economic:"), "Market demand, prices, profitability, economic growth, trade policies, subsidies"),
          tags$li(strong("Social:"), "Cultural traditions, consumer preferences, lifestyle changes, social norms"),
          tags$li(strong("Technological:"), "Fishing gear innovation, vessel efficiency, aquaculture technology, renewable energy tech"),
          tags$li(strong("Political:"), "Regulations, governance structures, international agreements, property rights"),
          tags$li(strong("Environmental:"), "Climate change, extreme weather, ocean acidification (as drivers of adaptation)"),
          tags$li(strong("Demographic:"), "Population growth, urbanization, aging, migration")
        ),

        hr(),
        h5("Examples of Driver → Activity Links"),
        tags$ul(
          tags$li("Global seafood demand → Expansion of commercial fishing"),
          tags$li("EU renewable energy targets → Offshore wind farm development"),
          tags$li("Rising coastal tourism demand → Increased coastal development"),
          tags$li("Economic subsidies for fisheries → Maintenance of fishing effort despite low profitability"),
          tags$li("Climate change impacts on agriculture → Increased nutrient runoff"),
          tags$li("Technological advances in aquaculture → Growth of fish farming"),
          tags$li("Urbanization of coastal areas → Increased sewage discharge")
        ),

        hr(),
        h5("Direct vs Indirect Drivers"),
        tags$ul(
          tags$li(strong("Indirect drivers:"), "Broad-scale forces (economic growth, population, technology)"),
          tags$li(strong("Direct drivers:"), "Specific mechanisms (price of fish, specific subsidy, particular regulation)"),
          tags$li("Both are important - indirect drivers shape the context, direct drivers are more actionable")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Think about WHY people engage in activities - what motivates them?"),
          tags$li("Consider both push and pull factors"),
          tags$li("Drivers often interact - economic + technological + political"),
          tags$li("Assess controllability honestly - some drivers are beyond local management"),
          tags$li("Trend analysis helps anticipate future pressures"),
          tags$li("Drivers are often where policy interventions are most effective")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercise 6: Closing the Loop Help
    observeEvent(input$help_ex6, {
      showModal(modalDialog(
        title = "Exercise 6: Closing the Loop - Drivers to Goods & Benefits",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("Complete the DAPSI(W)R(M) feedback loop by identifying how Drivers are influenced by or respond to
          changes in Goods & Benefits. This creates the circular causality that characterizes social-ecological systems."),

        hr(),
        h5("What to Do"),
        p("Identify connections where:"),
        tags$ul(
          tags$li("Changes in Goods & Benefits influence Drivers"),
          tags$li("Drivers respond to the availability or scarcity of Goods & Benefits"),
          tags$li("Economic, social, or policy drivers are shaped by ecosystem conditions")
        ),

        hr(),
        h5("Types of Feedback Loops"),
        tags$ul(
          tags$li(strong("Reinforcing (Positive) Loops:"), "Changes amplify themselves"),
          tags$ul(
            tags$li("Example: Declining fish stocks → Lower fishery profits → Increased fishing effort to maintain income →
                    Further stock decline (a 'vicious cycle')"),
            tags$li("Example: Successful ecotourism → More demand for conservation → Better habitat protection →
                    More wildlife → More tourism (a 'virtuous cycle')")
          ),
          tags$li(strong("Balancing (Negative) Loops:"), "Changes trigger counteracting responses"),
          tags$ul(
            tags$li("Example: Declining water quality → Reduced tourism → Economic pressure for cleanup →
                    Improved water quality → Increased tourism")
          )
        ),

        hr(),
        h5("Examples of Loop Closures"),
        tags$ul(
          tags$li("Declining fish catch (G&B) → Reduced profitability drives fishers out of business →
                  Reduction in fishing capacity (Driver)"),
          tags$li("Improved water quality from management (G&B) → Increased coastal property values →
                  Stronger political support for conservation policies (Driver)"),
          tags$li("Loss of coastal storm protection (G&B) → Increased flood damages →
                  Policy shift toward ecosystem restoration (Driver)"),
          tags$li("Degraded coral reef recreation (G&B) → Decline in dive tourism →
                  Reduced economic driver for tourism development (Driver)")
        ),

        hr(),
        h5("Why Loop Closure Matters"),
        tags$ul(
          tags$li("Reveals feedback dynamics that can amplify or dampen changes"),
          tags$li("Identifies potential tipping points and thresholds"),
          tags$li("Shows how ecosystem changes affect human behavior and policy"),
          tags$li("Essential for understanding system resilience and adaptation"),
          tags$li("Helps identify where to intervene to shift system behavior")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Not all Drivers need to connect back - focus on meaningful feedbacks"),
          tags$li("Consider time lags - feedbacks may take years to manifest"),
          tags$li("Think about both intended and unintended feedbacks"),
          tags$li("Stakeholder knowledge is crucial - they experience these feedbacks"),
          tags$li("Document whether feedbacks are reinforcing or balancing")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercises 7-9: CLD Help
    observeEvent(input$help_ex789, {
      showModal(modalDialog(
        title = "Exercises 7-9: Causal Loop Diagram Creation and Export",
        size = "l",
        easyClose = TRUE,

        h4("Overview"),
        p("These exercises guide you through creating, refining, and exporting Causal Loop Diagrams (CLDs)
          that visualize the structure and dynamics of your social-ecological system."),

        hr(),
        h5("Exercise 7: Creating Impact-based CLD in Kumu"),
        p(strong("Purpose:"), "Build a visual network diagram showing all DAPSI(W)R(M) elements and their connections."),
        tags$ul(
          tags$li("Export your data to Kumu-compatible CSV files using the download buttons"),
          tags$li("Import into Kumu (kumu.io) - a free online network visualization tool"),
          tags$li("Elements become nodes, connections become edges"),
          tags$li("Use color coding to distinguish element types (Drivers, Activities, Pressures, etc.)"),
          tags$li("Arrange the diagram to show clear causal flows")
        ),

        hr(),
        h5("Exercise 8: Moving from Causal Logic Chains to Causal Loops"),
        p(strong("Purpose:"), "Transform linear chains into circular feedback loops."),
        tags$ul(
          tags$li("Identify closed loops in your diagram"),
          tags$li("Trace paths from an element back to itself through the network"),
          tags$li("Classify loops as reinforcing (amplifying) or balancing (stabilizing)"),
          tags$li("Add loop identifiers and labels in Kumu"),
          tags$li("Focus on the most important loops that drive system behavior"),
          tags$li("Consider time delays in feedback loops")
        ),

        hr(),
        h5("Exercise 9: Exporting CLD for Further Analysis"),
        p(strong("Purpose:"), "Prepare your CLD for documentation, presentation, and deeper analysis."),
        tags$ul(
          tags$li("Export high-resolution images of your CLD from Kumu"),
          tags$li("Download the complete Excel workbook with all your data"),
          tags$li("Export adjacency matrices showing all connections"),
          tags$li("Prepare different views: full system, sub-systems, key loops"),
          tags$li("Document loop polarities (+ or -) and important delays"),
          tags$li("Create narrative descriptions of key loops and their behavior")
        ),

        hr(),
        h5("Understanding Causal Loop Diagrams"),
        tags$ul(
          tags$li(strong("Nodes:"), "Represent variables that change (elements in your DAPSI(W)R(M) framework)"),
          tags$li(strong("Edges:"), "Represent causal influences between variables"),
          tags$li(strong("Polarity:"), "+ means same direction change, - means opposite direction change"),
          tags$li(strong("Loops:"), "Closed circular paths of causation"),
          tags$li(strong("Loop type:"), "Even number of - links = reinforcing loop (R), odd number = balancing loop (B)")
        ),

        hr(),
        h5("Tips for Effective CLDs"),
        tags$ul(
          tags$li("Keep diagrams readable - consider creating multiple views for complex systems"),
          tags$li("Use consistent naming conventions"),
          tags$li("Label important loops with descriptive names"),
          tags$li("Highlight key feedback loops that drive system behavior"),
          tags$li("Use the adjacency matrix viewer to verify all intended connections"),
          tags$li("Validate your CLD with stakeholders and domain experts"),
          tags$li("Kumu allows collaborative editing - useful for team-based work")
        ),

        footer = modalButton("Close")
      ))
    })

    # Exercises 10-12: Analysis Help
    observeEvent(input$help_ex101112, {
      showModal(modalDialog(
        title = "Exercises 10-12: Clarifying, Metrics, and Validation",
        size = "l",
        easyClose = TRUE,

        h4("Overview"),
        p("These final exercises focus on refining your analysis, identifying leverage points for intervention,
          and validating your findings with stakeholders and experts."),

        hr(),
        h5("Exercise 10: Clarifying - Endogenisation and Encapsulation"),

        p(strong("Endogenisation:"), "Bringing external factors inside the system boundary"),
        tags$ul(
          tags$li("Review elements you've marked as exogenous (outside drivers)"),
          tags$li("Can any be explained by factors within your system?"),
          tags$li("Example: 'Market demand' might be influenced by 'product quality' within your system"),
          tags$li("Adding these feedbacks reveals hidden leverage points"),
          tags$li("Don't overdo it - some things are genuinely external")
        ),

        p(strong("Encapsulation:"), "Grouping detailed processes into higher-level concepts"),
        tags$ul(
          tags$li("Simplify overly complex sub-systems for clarity"),
          tags$li("Example: Multiple nutrient-related processes → 'Eutrophication dynamics'"),
          tags$li("Keep detailed version for technical analysis"),
          tags$li("Create simplified version for communication and policy"),
          tags$li("Document what's inside each encapsulated element")
        ),

        hr(),
        h5("Exercise 11: Metrics, Root Causes, and Leverage Points"),

        p(strong("Root Cause Analysis:")),
        tags$ul(
          tags$li("Identify elements with many outgoing links (strong influences on other variables)"),
          tags$li("Trace backward from problem symptoms to ultimate causes"),
          tags$li("Look for elements early in causal chains"),
          tags$li("These are often drivers or activities")
        ),

        p(strong("Leverage Point Identification:")),
        tags$ul(
          tags$li("Points where small interventions can produce large system changes"),
          tags$li("Often found at loop control points"),
          tags$li("Elements with high centrality (many connections)"),
          tags$li("Nodes where multiple pathways converge"),
          tags$li("Consider feasibility and controllability"),
          tags$li(strong("Meadows' Leverage Points:"), "Parameters < Feedbacks < System Design < Paradigms")
        ),

        p(strong("Metrics and Indicators:")),
        tags$ul(
          tags$li("How will you measure changes in key elements?"),
          tags$li("Link to available data sources where possible"),
          tags$li("Identify data gaps requiring new monitoring"),
          tags$li("Choose SMART indicators (Specific, Measurable, Achievable, Relevant, Time-bound)")
        ),

        hr(),
        h5("Exercise 12: Presenting and Validating Results"),

        p(strong("Validation Approaches:")),
        tags$ul(
          tags$li(strong("Internal Review:"), "Team verification of logic and completeness"),
          tags$li(strong("Expert Review:"), "Scientific peer review of ecological and social components"),
          tags$li(strong("Stakeholder Workshops:"), "Participatory validation with people who know the system"),
          tags$li(strong("Data Validation:"), "Compare with empirical evidence and quantitative data"),
          tags$li(strong("Historical Validation:"), "Does the model explain past system behavior?")
        ),

        p(strong("Presentation Tips:")),
        tags$ul(
          tags$li("Tailor complexity to your audience"),
          tags$li("Use visual CLD for system overview"),
          tags$li("Tell stories about key feedback loops"),
          tags$li("Show BOT graphs to illustrate dynamics"),
          tags$li("Clearly link analysis to policy recommendations"),
          tags$li("Be transparent about uncertainties and limitations"),
          tags$li("Provide both technical documentation and policy briefs")
        ),

        hr(),
        h5("Validation Checklist"),
        tags$ul(
          tags$li("Are all major causal relationships included?"),
          tags$li("Are the connections logically sound?"),
          tags$li("Do stakeholders recognize the system structure?"),
          tags$li("Does it explain observed system behavior?"),
          tags$li("Are feedback loops correctly identified?"),
          tags$li("Are leverage points plausible and actionable?"),
          tags$li("Have expert reviewers provided feedback?")
        ),

        footer = modalButton("Close")
      ))
    })

    # BOT Graphs Help
    observeEvent(input$help_bot, {
      showModal(modalDialog(
        title = "Behaviour Over Time (BOT) Graphs",
        size = "l",
        easyClose = TRUE,

        h4("Purpose"),
        p("BOT graphs show how key indicators change over time, revealing important dynamics like trends,
          cycles, delays, and tipping points in your social-ecological system."),

        hr(),
        h5("What to Create"),
        tags$ul(
          tags$li("Select an element from your DAPSI(W)R(M) framework"),
          tags$li("Add time series data points (year, value, unit)"),
          tags$li("Create graphs showing temporal patterns"),
          tags$li("Annotate with important events or policy changes"),
          tags$li("Compare multiple elements to see relationships")
        ),

        hr(),
        h5("Types of Patterns to Look For"),
        tags$ul(
          tags$li(strong("Trends:"), "Steady increase or decrease over time"),
          tags$li(strong("Cycles:"), "Regular oscillations or boom-bust patterns"),
          tags$li(strong("Steps:"), "Sudden changes following events or policy shifts"),
          tags$li(strong("Delays:"), "Time lags between cause and effect"),
          tags$li(strong("Thresholds:"), "Tipping points where system behavior changes"),
          tags$li(strong("Plateaus:"), "Periods of stability despite changing inputs")
        ),

        hr(),
        h5("Examples of Useful BOT Graphs"),
        tags$ul(
          tags$li("Fish stock biomass over decades"),
          tags$li("Fishing effort trends"),
          tags$li("Coastal water quality indicators"),
          tags$li("Tourism visitor numbers"),
          tags$li("Aquaculture production growth"),
          tags$li("Policy implementation timeline"),
          tags$li("Economic value of ecosystem services"),
          tags$li("Pressure intensity over time")
        ),

        hr(),
        h5("Using BOT Graphs in Analysis"),
        tags$ul(
          tags$li(strong("Hypothesis Testing:"), "Do observed patterns match your CLD predictions?"),
          tags$li(strong("Feedback Loop Evidence:"), "Look for characteristic reinforcing or balancing patterns"),
          tags$li(strong("Delay Estimation:"), "Measure time lags between related variables"),
          tags$li(strong("Policy Evaluation:"), "Did interventions have the intended effect?"),
          tags$li(strong("Scenario Exploration:"), "Project future trends under different assumptions"),
          tags$li(strong("Communication:"), "Show stakeholders concrete evidence of system changes")
        ),

        hr(),
        h5("Data Sources"),
        tags$ul(
          tags$li("Official statistics (fisheries, tourism, economic data)"),
          tags$li("Environmental monitoring programs"),
          tags$li("Scientific surveys and assessments"),
          tags$li("Stakeholder knowledge and observations"),
          tags$li("Historical records and archives"),
          tags$li("Proxy indicators when direct data unavailable")
        ),

        hr(),
        h5("Tips"),
        tags$ul(
          tags$li("Use consistent units and scales"),
          tags$li("Clearly label axes and provide legends"),
          tags$li("Annotate graphs with contextual information (policies, events)"),
          tags$li("Compare multiple variables on the same time axis to see relationships"),
          tags$li("Be transparent about data quality and gaps"),
          tags$li("Consider normalizing or indexing for comparability"),
          tags$li("Update BOT graphs as new data becomes available")
        ),

        footer = modalButton("Close")
      ))
    })

    # Return reactive data for use by other modules
    return(reactive({ isa_data }))
  })
}
