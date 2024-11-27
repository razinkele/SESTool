# optimize the code below and compare it with the snippets above
# list snippets
# 1. Required packages
# 2. Check and install missing packages
# 3. Load required packages
# 4. Include the R file containing the R6 class SES
# 5. Define UI
# 6. Define server
# 7. Disable action buttons
# 8. Internal storage for column names of the uploaded data
# 9. Internal storage for loaded data (connections) and elements
# 10. Add a Bootstrap tooltip to the selectInput
# 11. Observe the button click to change the dataframe
# 12. Create dynamic dropdown menus based on dataframe column names
# 13. Render the file input dynamically based on the selected file type
# 14. Function to validate and load data based on file type
# 15. Reactive values for graph data
# 16. Create network
# 17. Create graph
# 18. Render the network plot
# 19. Render connections data table
# 20. Render elements data table
# 21. Update links_data when the connections table is edited
# 22. Update elements_data when the elements table is edited
# 23. Download handler for the plot
# 24. Run the app

# List of required packages
required_packages <- c("shiny", "shinyBS", "visNetwork", "readsdr", "readr", "igraph", "dplyr", "htmlwidgets", "colourpicker", "shinyjs", "DT", "markdown")

# Function to check and install packages
install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cat(paste0("Installing package: ", package, "\n"))
    install.packages(package, dependencies = TRUE)
  } else {
    cat(paste0("Package already installed: ", package, "\n"))
  }
}

# Check and install missing packages
cat("Checking and installing required packages...\n")
sapply(required_packages, install_if_missing)

# Load the packages
cat("\nLoading required packages...\n")
sapply(required_packages, library, character.only = TRUE)

cat("\nAll required packages are installed and loaded.\n")

# include the R file containing the R6 clas SES
source("classes.R")



# Define UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; }
      .container-fluid { padding-top: 20px; }
      .well { background-color: #f8f9fa; border: none; box-shadow: none; }
      .btn { border-radius: 0; }
      .left-align { float: left;}
      .form-control { border-radius: 0; }
      .nav-tabs { border-bottom: 2px solid #dee2e6; }
      .nav-tabs > li.active > a, .nav-tabs > li.active > a:focus, .nav-tabs > li.active > a:hover {
        border: none;
        border-bottom: 2px solid #007bff;
      }
      .network-container { border: 1px solid #dee2e6; border-radius: 4px; padding: 15px; }
      #colorPickers .shiny-input-container { display: inline-block; margin-right: 10px; margin-bottom: 10px; }
    "))
  ),
  titlePanel(div(
    style = "display: flex; align-items: center; gap: 3px;",
    img(
      # src = "file:///C:/Users/arturas.baziukas/OneDrive%20-%20ku.lt/HORIZON%20EUROPE/Marine-SABRES/BowTie/MSabres.png",
      # src = "https://raw.githubusercontent.com/rstudio/hex-stickers/master/PNG/shiny.png",
      # src = "https://raw.githubusercontent.com/razinkele/SESTool/main/images/MSabres.png",
      src = "https://raw.githubusercontent.com/razinkele/SESTool/main/images/01%20marinesabres_logo_transparent.png",
      height = "70px",
      style = "margin-left: 3px;"
    ),
    "SES Tool"
  )),
  # Sidebar ----
  sidebarLayout(
    sidebarPanel(
      width = 3,
      # Groups & links strength field selection button

      # actionButton("change_df", "Change groups & links", title = "Group and links width field selection", style = "float: left;"),

      # File upload button

      # Dropdown list for selecting file format
      selectInput("fileType", "Select File Format:",
        choices = c("XLSX" = "xlsx", "CSV" = "csv", "GraphML" = "graphml")
      ),
      # Dynamic file upload button based on dropdown selection
      uiOutput("dynamicUploadButton"),
      actionButton("change_df", "Change groups & links", title = "Group and links width field selection", style = "float: left;", class = "btn-primary btn-block"),
      textOutput("selected_columns"),
      # dropdown menu to select column for width/strength
      uiOutput("strength"),
      uiOutput("groups", style = "float: left;"),
      # dropdown menu to select column for group
      uiOutput("group"),
      hr(),
      actionButton("createNetwork", "Create Network", title = "Create network from the uploaded links table", style = "margin-top: 35px;", class = "btn-primary btn-block"),
      actionButton("createGraph", "Create/Update Graph", class = "btn-primary btn-block"),
      hr(),
      # selectInput("shapes", "Select Category:", choices = NULL),

      # sliderInput("edgeWidth", "Edge Width", min = 1, max = 10, value = 1),
      checkboxInput("showLabels", "Show Labels", value = TRUE),
      checkboxInput("useGroupShapes", "Use Group Shapes", value = TRUE),
      checkboxInput("useEdgeWeight", "Use Edge Weights", value = TRUE),
      checkboxInput("useEdgeColor", "Use Edge Colors", value = TRUE),
      checkboxInput("showLegend", "Show Legend", value = TRUE),
      actionButton("Run analyses", "Run CLD loop analysis", class = "btn-primary btn-block"),
      hr(),
      downloadButton("downloadPlot", "Save Plot as HTML", class = "btn-success btn-block"),
      hr(),
      # h4("Group Colors"),
      # uiOutput("colorPickers")
    ),
    # Main panel ----
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Network Graph",
          div(
            class = "network-container",
            visNetworkOutput("network", height = "600px")
          )
        ),
        tabPanel(
          "Elemement Table",
          DTOutput("EldataTable")
        ),
        tabPanel(
          "Connections Table",
          DTOutput("dataTable")
        ),
        tabPanel(
          "Help",
          includeMarkdown("guidance.md")
        )
      )
    )
  )
)

# Define server ----
server <- function(input, output, session) {
  disable("Run analyses")
  disable("change_df")
  disable("createNetwork")
  disable("createGraph")
  # internal storage for column names of the uploaded data
  current_df <- reactiveVal(NULL)
  # Internal storage for loaded data (connections) and elements
  links_data <- reactiveVal(NULL)
  elements_data <- reactiveVal(NULL)
  excel <- reactiveVal(NULL)
  # Add a Bootstrap tooltip to the selectInput
  bsTooltip("fileType", "Select an option from the dropdown", placement = "right", trigger = "hover")
  # Observe the button click to change the dataframe
  observeEvent(input$change_df, {
    # the connections table should be present
    req(links_data())
    # current connections table
    req(current_df)
    df <- current_df() # current connection table
    df1 <- links_data() # new connections table
    if (identical(current_df(), df1)) {
      current_df(df)
    } else {
      # uploaded connection table is different from the current one
      current_df(df1)
    }
  })
  # Create dynamic dropdown menus based on dataframe column names
  output$strength <- renderUI({
    req(current_df())
    df <- current_df()
    selectInput("strength", "Strength variable:", choices = names(df))
    # print(input$strength)
  })

  output$group <- renderUI({
    req(current_df())
    df <- current_df()
    selectInput("group", "Group variable:", choices = names(df))
    # print(input$group)
  })
  # populate the shapes selectInput
  # observe({
  #   req(links_data())
  #   df <- links_data()
  #   updateSelectInput(session, "shape", choices = colnames(df))
  # })
  # Render the file input dynamically based on the selected file type
  # Dynamic input button based on file type selection ----
  output$dynamicUploadButton <- renderUI({
    req(input$fileType) # Ensure file type is selected

    # Display a file input button accepting only the selected file type
    title <- "Load a file containing at least connections ('from' and 'to' columns)"
    fileInput("file", paste("Upload", toupper(input$fileType), "File"),
      accept = switch(input$fileType,
        "xlsx" = ".xlsx",
        "csv" = ".csv",
        "graphml" = ".graphml"
      )
    )
  })



  # Alternative Reactive function to load the file based on file type
  # links_data <- reactive({
  # fileData <- reactive({
  #   req(input$file) # Ensure a file is uploaded
  #   # Load the file based on the selected file format
  #   switch(input$fileType,
  #          "xlsx" = {
  #            # Read EXCEL file
  #            nodes <- read_excel(file_path, sheet = "Elements")
  #            edges <- read_excel(file_path, sheet = "Connections")
  #          },
  #          "csv" = {
  #            # Read CSV file
  #            df <- read_csv(input$file$datapath, col_types = cols(
  #             from = col_character(),
  #             to = col_character(),
  #             group = col_character(),
  #             weight = col_double(),
  #             edge_color = col_character()
  #             ))
  #            head(df) # Show first few rows of the CSV file
  #           if (all(c("from", "to", "group") %in% colnames(df)))
  #             {
  #               links_data(df)
  #             } else
  #             {
  #               showNotification("Uploaded file must contain 'from', 'to', and 'group' columns.", type = "error")
  #             }
  #                },
  #                error = function(e) {
  #                  showNotification("Error reading the file. Please ensure it's a valid CSV.", type = "error")
  #                }
  #              )
  #            })
  #            # csv_data <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
  #            head(df) # Show first few rows of the CSV file
  #          })
  # Reactive value to store uploaded data




  # Function to validate and load data based on file type ---
  # File load button event ----
  observeEvent(input$file, {
    req(input$file)
    file <- input$file$datapath
    print(file)
    print("-------File type selected:")
    file_type <- input$fileType
    print(file_type)

    # Initialize status message
    status <- NULL
    df <- NULL

    # Load and validate data based on file type ----
    #Read KUMU csv file ----
    if (file_type == "csv") {
      # Attempt to load CSV data
      print("-------Trying to load connections CSV data-------------------------------------")
      df <- tryCatch(read.csv(file), error = function(e) NULL)
      status <- if (is.null(df)) {
        "Invalid CSV file"
      } else {
        "CSV file loaded successfully"
        excel(FALSE)
      }
    } else if (file_type == "xlsx") {
      #Read excel file ----
      print("-------Trying to load connections XLSX data initialising the SES object--------")
      # Attempt to load XLSX data
      ses <- SES$new(file)
      nodes <- ses$nodes
      print(nodes)
      df <- ses$edges
      ## status message
      status <- if (is.null(df)) "Invalid XLSX file" else "XLSX file loaded successfully"
      if (!is.null(df)) {
        excel(TRUE)
        xl <- excel()
        print(nodes)
        print(df)
        print("Excel file loaded successfully nodes and edges printed above")
      }
    }
    else if (file_type == "graphml") {
    # Read GraphML data as an igraph object ----
      df <- tryCatch(read_graph(file, format = "graphml"), error = function(e) NULL)
      ## status message
      status <- if (is.null(df)) "Invalid GraphML file" else "GraphML file loaded successfully"
    }
    # Update status message and store links and elements data if valid
    output$statusMessage <- renderText(status)
    links_data(if (is.null(df)) NULL else df)
    # if excel file is loaded, store the nodes data from ses object
    if (xl) elements_data(if (is.null(nodes)) NULL else nodes)


    # enable action buttons if SES is loaded
    enable("change_df")
    enable("createNetwork")
    enable("createGraph")
    enable("Run analyses")
    observe({
      req(links_data())
      df <- links_data()
      updateSelectInput(session, "shape", choices = colnames(df))
    })
  })

  # Reactive values for graph data
  graph_data <- reactiveVal(NULL)
  # Create network ------
  # Create network object  when button is clicked if data is loaded
  # It also creates the nodes and edges dataframes from the uploaded data
  observeEvent(input$createNetwork, {
    req(links_data())
    data <- links_data()
    xl <- excel()
    if (xl) {
      print("--------excel links data below --------------------------------------")
      print(data)
    } else
    { 
      # change first column name to 'from' and second to 'to'
      colnames(data)[1:2] <- c("from", "to")
      # Create nodes dataframe using the unique values in 'from' and 'to' columns if not from ses
      nodes <- data.frame(id = unique(c(data$from, data$to))) # ,
      # group = data$group[match(unique(c(data$from, data$to)), data$from)]
      # Save the created nodes into the elements_data reactive variable
      elements_data(nodes)
    }
  })

  # Create graph ----
  # Create/Update graph when button is clicked if data is loaded
  # It also creates the nodes and edges dataframes from the uploaded data
  observeEvent(input$createGraph, {
    req(links_data())
    data <- links_data()
    xl <- excel()
    # populate the shapes select Input
    strength <- input$strength
    if (is.null(strength)) {
      print("    --------------------- no strength column selected")
    } else {
      print("     ---------Strength column selected:")
      print(input$strength)
    }
    # if excel is true all data coming from ses object
    if (xl) {
      nodes <- elements_data()
      edges <- links_data()
    } else
      {
      # change first column name to 'from' and second to 'to'
      colnames(data)[1:2] <- c("from", "to")
      # Create nodes dataframe using the unique values in 'from' and 'to' columns
      nodes <- data.frame(
        id = unique(c(data$from, data$to)) # ,
        # group = data$group[match(unique(c(data$from, data$to)), data$from)]
      )
      print("-----------------------Dealing with groups-------------------------")
      # check whether the group column exists in the data
      if ("group" %in% names(data)) {
        nodes$group <- data$group[match(unique(c(data$from, data$to)), data$from)]
      } else { # if no group column is found, set all edges to group value no group
        print("assingning no group value")
        nodes$group <- "no group"
      }
      # Add labels to nodes if requested
      # use labels from 'id' column if 'showLabels' is TRUE
      nodes$Name <- if (input$showLabels) as.character(nodes$id) else ""
      nodes$shape <- input$nodeShape
      # Save the nodes into the elements_data reactive variable
      # only needed if without ses object
      elements_data(nodes)
    }
    if (xl) {
      print("------------Creating edges and nodes dataframes from ses -------------------")
      edges <- links_data()
      nodes <- elements_data()
      # edges$arrows <- input$edgeStyle
      edges$arrows <- "to"
      # edges$color <- if (input$useEdgeColor && "edge_color" %in% names(data)) data$edge_color else NULL
    } else
    { 
      print("----------------Creating edges dataframe from read CSV file -------------------")
      # Create edges dataframe from the uploaded data
      edges <- data.frame(from = data$from, to = data$to)
      # Set the edge attributes according to the checkbox selection
      # and data available in the uploaded file
      edges$width <- if (input$useEdgeWeight && "weight" %in% names(data)) data$weight else input$edgeWidth
      edges$arrows <- input$edgeStyle
      edges$arrows <- "to"
      edges$color <- if (input$useEdgeColor && "edge_color" %in% names(data)) data$edge_color else NULL
      edges$Confidence <- 0.2
    }
    # common for both excel & csv ----
    # Add tooltips to nodes and edges


    # Save the edges into the links_data reactive variable
    links_data(edges)
    # Calculate the number of nodes and edges
    nrow(edges)
    nrow(nodes)
    # tooltip (html or character), when the mouse is above
    print("Creating tooltips for nodes and edges")

    edges$title <- paste0("<p><b>", edges$Frequency, "</b><br>Frequency</p>")
    nodes$title <- paste0("<p><b>", nodes$group, "</b><br>Group</p>")
    print("Nodes column names:")
    print(colnames(nodes))
    print("edges column names:")
    print(colnames(edges))
    graph_data(list(nodes = nodes, edges = edges))
  }) # end observe event

  # Render the network plot ------
  output$network <- renderVisNetwork({
    req(graph_data())

    data <- graph_data()

    # Create the network plot from the nodes and edges dataframes
    print("Nodes and edges dataframes before plotting:")
    print(data$nodes)
    print(data$edges)
    net <- visNetwork(nodes = data$nodes, edges = data$edges) %>%
      visOptions(manipulation = list(
        enabled = TRUE,
        editEdgeCols = c("Strength", "Confidence"),
        editNodeCols = c("Name", "group"),
        addNodeCols = c("id", "label")
      ), highlightNearest = list(enabled = TRUE, degree = 2), selectedBy = "group") %>%
      visLayout(randomSeed = 123) %>%
      visPhysics(stabilization = TRUE) %>%
      set_VisGroups() %>%
      visInteraction(navigationButtons = TRUE, hover = TRUE) %>%
      visEvents(
        hoverNode = "function(nodes) {
                Shiny.onInputChange('label', nodes);
                ;}",
        hoverEdge = "function(edges) {
                Shiny.onInputChange('strength', edges);
                ;}"
      )

    # Add groups with custom colors using the unique values in 'group' column
    # groups <- unique(data$nodes$group)
    # for (group in groups) {
    #   color_input <- input[[paste0("color_", group)]]
    #   if (!is.null(color_input)) {
    #     net <- net %>% visGroups(groupname = group, color = color_input)
    #   }
    # }

    # Add legend if requested
    if (input$showLegend) {
      net <- net %>% visLegend(width = 0.2, position = "right", main = "Groups")
    }

    net
  })
  # here go the two tabs with 2 tables  (elements and connections)
  # Render connections data  table ------
  output$dataTable <- renderDT({
    req(links_data())
    datatable(links_data(), editable = TRUE)
  })

  # Render elements data table ------
  output$EldataTable <- renderDT({
    req(elements_data())
    datatable(elements_data(), editable = TRUE)
  })

  # Update links_data when the connections table is edited ------
  observeEvent(input$dataTable_cell_edit, {
    info <- input$dataTable_cell_edit
    updated_data <- editData(links_data(), info)
    links_data(updated_data)
  })

  # Update elements_data when the elements table is edited ------
  observeEvent(input$EldataTable_cell_edit, {
    info <- input$EldataTable_cell_edit
    updated_data <- editData(elements_data(), info)
    elements_data(updated_data)
  })

  # Download handler for the plot ------
  output$downloadPlot <- downloadHandler(
    filename = function() {
      "network_plot.html"
    },
    content = function(file) {
      net <- visNetwork(nodes = graph_data()$nodes, edges = graph_data()$edges) %>%
        visOptions(manipulation = TRUE, highlightNearest = list(enabled = TRUE, degree = 2), selectedBy = "group") %>%
        visLayout(randomSeed = 123) %>%
        visPhysics(stabilization = FALSE) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE) %>%
        set_VisGroups() %>%
        visEvents(hoverNode = "function(nodes) {
        Shiny.onInputChange('label', nodes);
        ;}", hoverEdge = "function(edges) {
                Shiny.onInputChange('strength', edges);
                  ;}")

      # groups <- unique(graph_data()$nodes$group)
      # for (group in groups) {
      #   color_input <- input[[paste0("color_", group)]]
      #   if (!is.null(color_input)) {
      #     net <- net %>% visGroups(groupname = group, color = color_input)
      #   }
      # }

      if (input$showLegend) {
        net <- net %>% visLegend(width = 0.1, position = "right", main = "Element groups")
      }

      saveWidget(net, file)
    }
  )
}

# Run the app ----
shinyApp(ui = ui, server = server)
