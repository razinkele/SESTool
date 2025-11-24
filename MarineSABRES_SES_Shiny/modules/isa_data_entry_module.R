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

    # Navigation: Breadcrumb and Progress Bar
    fluidRow(
      column(12,
        uiOutput(ns("navigation_ui"))
      )
    ),

    fluidRow(
      column(12,
        uiOutput(ns("isa_tabs_ui"))
      )
    ),

    # Navigation: Previous/Next Buttons
    fluidRow(
      column(12,
        uiOutput(ns("nav_buttons_ui"))
      )
    )
  )
}

# Module Server ----
isaDataEntryServer <- function(id, global_data, event_bus = NULL, i18n) {
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

    # Navigation state ----
    # Define tab structure for navigation
    tab_names <- c(
      "Exercise 0: Complexity",
      "Exercise 1: Goods & Benefits",
      "Exercise 2a: Ecosystem Services",
      "Exercise 2b: Marine Processes",
      "Exercise 3: Pressures",
      "Exercise 4: Activities",
      "Exercise 5: Drivers",
      "Exercise 6: Closing Loop",
      "Exercises 7-9: CLD",
      "Exercises 10-12: Analysis",
      "BOT Graphs",
      "Data Management"
    )

    # Track current exercise (1-indexed, 1 = Exercise 0)
    current_exercise <- reactiveVal(1)

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

        # Load adjacency matrices if they exist
        if (!is.null(isa_saved$adjacency_matrices)) {
          cat("[ISA Module] Loading adjacency matrices\n")
          isa_data$adjacency_matrices <- isa_saved$adjacency_matrices

          # Count non-empty connections
          n_connections <- 0
          for (matrix_name in names(isa_saved$adjacency_matrices)) {
            mat <- isa_saved$adjacency_matrices[[matrix_name]]
            if (!is.null(mat) && is.matrix(mat)) {
              n_connections <- n_connections + sum(mat != "", na.rm = TRUE)
            }
          }
          cat(sprintf("[ISA Module] Loaded %d connections from adjacency matrices\n", n_connections))
        }

        # Note: responses from AI Assistant don't map to ISA Data Entry
        # They would need to be handled separately or shown in a different section

        cat("[ISA Module] Data loading complete\n")
        data_initialized(TRUE)
      } else {
        cat("[ISA Module] No saved ISA data found - starting fresh\n")
      }
    })

    # Render ISA header ----
    output$isa_header <- renderUI({
      create_module_header(
        ns = ns,
        title_key = "Integrated Systems Analysis (ISA) Data Entry",
        subtitle_key = "Follow the structured exercises to build your marine Social-Ecological System analysis.",
        help_id = "help_main",
        i18n = i18n
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

    # Render Navigation UI (breadcrumb + progress bar) ----
    output$navigation_ui <- renderUI({
      current <- current_exercise()
      total <- length(tab_names)

      tagList(
        # Breadcrumb
        create_breadcrumb(
          items = list(
            list(label = "Home", icon = "home"),
            list(label = "ISA Data Entry", icon = "clipboard"),
            list(label = tab_names[current])
          ),
          i18n = i18n
        ),

        # Progress Bar
        create_progress_bar(
          current = current,
          total = total,
          title = "Exercise Progress",
          i18n = i18n
        )
      )
    })

    # Render Navigation Buttons ----
    output$nav_buttons_ui <- renderUI({
      current <- current_exercise()
      total <- length(tab_names)

      create_nav_buttons(
        ns = ns,
        show_back = current > 1,
        show_next = current < total,
        back_enabled = current > 1,
        next_enabled = current < total,
        next_label = if (current == total - 1) "Finish" else "Next",
        i18n = i18n
      )
    })

    # Navigation Observers ----
    # Handle Back button click
    observeEvent(input$nav_back, {
      current <- current_exercise()
      if (current > 1) {
        new_index <- current - 1
        current_exercise(new_index)

        # Update tabsetPanel to show previous tab
        updateTabsetPanel(
          session = session,
          inputId = "isa_tabs",
          selected = i18n$t(tab_names[new_index])
        )
      }
    })

    # Handle Next button click
    observeEvent(input$nav_next, {
      current <- current_exercise()
      total <- length(tab_names)
      if (current < total) {
        new_index <- current + 1
        current_exercise(new_index)

        # Update tabsetPanel to show next tab
        updateTabsetPanel(
          session = session,
          inputId = "isa_tabs",
          selected = i18n$t(tab_names[new_index])
        )
      }
    })

    # Sync current_exercise when user manually clicks tabs
    observe({
      tab <- input$isa_tabs
      if (!is.null(tab)) {
        # Find which tab is selected based on translated name
        translated_names <- sapply(tab_names, function(name) i18n$t(name))
        index <- which(translated_names == tab)

        if (length(index) > 0) {
          current_exercise(index[1])
        }
      }
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

      isa_data$loop_connections <- rbind(isa_data$loop_connections, new_connection)
      showNotification("Loop connection added", type = "message")
    })

    # Display loop connections table ----
    output$loop_connections_table <- renderDT({
      if (nrow(isa_data$loop_connections) == 0) {
        return(data.frame(Message = "No loop connections yet"))
      }

      isa_data$loop_connections %>%
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
      # loop_connections already in isa_data (no need to copy from rv)

      # Convert loop_connections to gb_d adjacency matrix (NEW: forward causal flow)
      # GB→D represents how welfare perceptions feed back to drive societal drivers
      if (nrow(isa_data$loop_connections) > 0) {
        n_drivers <- nrow(isa_data$drivers)
        n_gb <- nrow(isa_data$goods_benefits)

        # Initialize empty matrix (SOURCE×TARGET: rows=GB, cols=Drivers)
        gb_d_matrix <- matrix("", nrow = n_gb, ncol = n_drivers)
        rownames(gb_d_matrix) <- isa_data$goods_benefits$ID
        colnames(gb_d_matrix) <- isa_data$drivers$ID

        # Fill matrix with connections
        for (i in 1:nrow(isa_data$loop_connections)) {
          conn <- isa_data$loop_connections[i, ]
          gb_idx <- which(isa_data$goods_benefits$ID == conn$GBID)
          d_idx <- which(isa_data$drivers$ID == conn$DriverID)

          if (length(gb_idx) > 0 && length(d_idx) > 0) {
            # Format: "effect+strength:confidence"
            value <- paste0(conn$Effect, conn$Strength, ":", conn$Confidence)
            gb_d_matrix[gb_idx, d_idx] <- value
          }
        }

        # Store in adjacency_matrices
        if (is.null(isa_data$adjacency_matrices)) {
          isa_data$adjacency_matrices <- list()
        }
        isa_data$adjacency_matrices$gb_d <- gb_d_matrix
      }

      showNotification(paste("Exercise 6 saved:", nrow(isa_data$loop_connections), "loop connections"),
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
    create_help_observer(
      input, "help_main", "isa_framework_guide_title",
      tagList(
        h4(i18n$t("isa_guide_what_is_isa_title")),
        p(i18n$t("isa_guide_what_is_isa_p1")),
        p(i18n$t("isa_guide_what_is_isa_p2")),
        hr(),
        h4(i18n$t("isa_guide_dapsiwr_title")),
        p(i18n$t("isa_guide_dapsiwr_p1")),
        tags$ul(
          tags$li(strong(i18n$t("drivers_label")), i18n$t("isa_guide_dapsiwr_drivers")),
          tags$li(strong(i18n$t("activities_label")), i18n$t("isa_guide_dapsiwr_activities")),
          tags$li(strong(i18n$t("pressures_label")), i18n$t("isa_guide_dapsiwr_pressures")),
          tags$li(strong(i18n$t("state_label")), i18n$t("isa_guide_dapsiwr_state")),
          tags$li(strong(i18n$t("impacts_label")), i18n$t("isa_guide_dapsiwr_impacts")),
          tags$li(strong(i18n$t("responses_label")), i18n$t("isa_guide_dapsiwr_responses"))
        ),
        hr(),
        h4(i18n$t("isa_guide_how_to_use_title")),
        p(i18n$t("isa_guide_how_to_use_p1"))
      ),
      i18n
    )

    create_help_observer(input, "help_ex0", "ex0_help_title", p(i18n$t("ex0_help_text")), i18n)
    create_help_observer(input, "help_ex1", "ex1_help_title", p(i18n$t("ex1_help_text")), i18n)
    create_help_observer(input, "help_ex2a", "ex2a_help_title", p(i18n$t("ex2a_help_text")), i18n)
    create_help_observer(input, "help_ex2b", "ex2b_help_title", p(i18n$t("ex2b_help_text")), i18n)
    create_help_observer(input, "help_ex3", "ex3_help_title", p(i18n$t("ex3_help_text")), i18n)
    create_help_observer(input, "help_ex4", "ex4_help_title", p(i18n$t("ex4_help_text")), i18n)
    create_help_observer(input, "help_ex5", "ex5_help_title", p(i18n$t("ex5_help_text")), i18n)
    create_help_observer(input, "help_ex6", "ex6_help_title", p(i18n$t("ex6_help_text")), i18n)
    create_help_observer(input, "help_ex789", "ex789_help_title", p(i18n$t("ex789_help_text")), i18n)
    create_help_observer(input, "help_ex101112", "ex101112_help_title", p(i18n$t("ex101112_help_text")), i18n)
    create_help_observer(input, "help_bot", "bot_help_title", p(i18n$t("bot_help_text")), i18n)

    # Return reactive data for use by other modules
    return(reactive({ isa_data }))
  })
}
