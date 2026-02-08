# ==============================================================================
# Template Recommendation Module (Week 9)
# ==============================================================================
# Shiny module for creating new templates with ML bootstrap via transfer learning.
# Recommends best source template based on similarity and provides automated
# fine-tuning workflow.
#
# Features:
# - New template metadata input
# - Automatic source template recommendation
# - Similarity score visualization
# - Fine-tuning trigger and progress tracking
# - Template versioning
#
# Author: Phase 2 ML Enhancement - Week 9
# Date: 2026-01-01
# ==============================================================================

# Libraries loaded in global.R: shiny, shinyWidgets, DT

# ==============================================================================
# UI Function
# ==============================================================================

#' Template Recommendation UI
#'
#' @param id Namespace ID
#' @export
templateRecommendationUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        h3("Create Template with ML Bootstrap"),
        p("Create a new SES template with transfer learning assistance. The system will recommend
          the best pre-trained model to use based on template similarity.")
      )
    ),

    hr(),

    # Step 1: New Template Information
    fluidRow(
      column(12,
        h4("Step 1: New Template Information"),
        wellPanel(
          fluidRow(
            column(6,
              textInput(
                ns("template_name"),
                "Template Name",
                placeholder = "e.g., Baltic Sea Aquaculture"
              ),
              textInput(
                ns("template_author"),
                "Author",
                placeholder = "Your name"
              ),
              textAreaInput(
                ns("template_description"),
                "Description",
                placeholder = "Brief description of the template scope and objectives",
                rows = 3
              )
            ),
            column(6,
              selectInput(
                ns("regional_sea"),
                "Regional Sea",
                choices = c(
                  "Baltic Sea",
                  "North Sea",
                  "Celtic Seas",
                  "Bay of Biscay and Iberian Coast",
                  "Western Mediterranean Sea",
                  "Adriatic Sea",
                  "Ionian Sea and Central Mediterranean Sea",
                  "Aegean-Levantine Sea",
                  "Black Sea",
                  "Macaronesia",
                  "Caribbean Sea",
                  "Other"
                ),
                selected = "Baltic Sea"
              ),
              selectizeInput(
                ns("ecosystem_types"),
                "Ecosystem Types (multiple)",
                choices = c(
                  "Coastal", "Shelf", "Deep Sea", "Pelagic", "Benthic",
                  "Rocky Shore", "Sandy Shore", "Mudflat", "Saltmarsh",
                  "Seagrass", "Kelp Forest", "Coral Reef", "Mangrove",
                  "Estuary", "Lagoon", "Fjord", "Other"
                ),
                multiple = TRUE,
                options = list(placeholder = "Select ecosystem types")
              ),
              selectizeInput(
                ns("main_issues"),
                "Main Issues (multiple)",
                choices = c(
                  "Overfishing", "Pollution", "Climate Change", "Habitat Loss",
                  "Invasive Species", "Eutrophication", "Ocean Acidification",
                  "Biodiversity Loss", "Aquaculture", "Tourism", "Shipping",
                  "Offshore Energy", "Marine Litter", "Noise Pollution",
                  "Chemical Pollution", "Oil Spills", "Other"
                ),
                multiple = TRUE,
                options = list(placeholder = "Select main issues")
              )
            )
          ),

          fluidRow(
            column(12,
              actionButton(
                ns("analyze_similarity"),
                "Analyze Template Similarity",
                icon = icon("search"),
                class = "btn-primary"
              )
            )
          )
        )
      )
    ),

    # Step 2: Similarity Analysis Results
    conditionalPanel(
      condition = sprintf("output['%s']", ns("show_results")),
      ns = ns,

      fluidRow(
        column(12,
          h4("Step 2: Source Template Recommendation"),

          # Recommendation Card
          uiOutput(ns("recommendation_card")),

          # Similarity Details
          wellPanel(
            h5("Template Similarity Breakdown"),
            DTOutput(ns("similarity_table")),

            br(),

            h5("Similarity Component Details"),
            plotOutput(ns("similarity_plot"), height = PLOT_HEIGHT_SM)
          )
        )
      ),

      hr(),

      # Step 3: Transfer Learning Options
      fluidRow(
        column(12,
          h4("Step 3: Transfer Learning Strategy"),

          wellPanel(
            fluidRow(
              column(6,
                radioButtons(
                  ns("training_strategy"),
                  "Select Training Approach:",
                  choices = c(
                    "Fine-tune recommended model (Recommended)" = "finetune",
                    "Train from scratch" = "scratch",
                    "Use pre-trained model as-is" = "pretrained"
                  ),
                  selected = "finetune"
                ),

                conditionalPanel(
                  condition = "input.training_strategy == 'finetune'",
                  ns = ns,
                  selectizeInput(
                    ns("freeze_layers"),
                    "Layers to Freeze:",
                    choices = c("fc1", "fc2", "context_embeddings"),
                    selected = "fc1",
                    multiple = TRUE
                  ),
                  numericInput(
                    ns("finetune_epochs"),
                    "Fine-tuning Epochs:",
                    value = 30,
                    min = 10,
                    max = 100,
                    step = 10
                  ),
                  numericInput(
                    ns("finetune_lr"),
                    "Learning Rate:",
                    value = 0.0001,
                    min = 0.00001,
                    max = 0.001,
                    step = 0.00001
                  )
                )
              ),

              column(6,
                h5("Expected Performance"),
                uiOutput(ns("performance_estimate")),

                br(),

                h5("Training Information"),
                uiOutput(ns("training_info"))
              )
            ),

            hr(),

            fluidRow(
              column(12,
                actionButton(
                  ns("start_training"),
                  "Start Model Training",
                  icon = icon("play"),
                  class = "btn-success btn-lg"
                ),

                conditionalPanel(
                  condition = sprintf("output['%s']", ns("show_progress")),
                  ns = ns,
                  br(), br(),
                  progressBar(
                    id = ns("training_progress"),
                    value = 0,
                    display_pct = TRUE,
                    status = "info"
                  ),
                  verbatimTextOutput(ns("training_log"))
                )
              )
            )
          )
        )
      )
    ),

    hr(),

    # Template Version History
    fluidRow(
      column(12,
        h4("Template Version History"),
        DTOutput(ns("version_history_table")),

        br(),

        actionButton(
          ns("export_metadata"),
          "Export Template Metadata",
          icon = icon("download")
        )
      )
    )
  )
}

# ==============================================================================
# Server Function
# ==============================================================================

#' Template Recommendation Server
#'
#' @param id Namespace ID
#' @param training_data Reactive containing training data
#' @param similarity_matrix Reactive containing pre-calculated similarities (optional)
#' @export
templateRecommendationServer <- function(id, training_data, similarity_matrix = NULL) {
  moduleServer(id, function(input, output, session) {

    # Reactive values
    rv <- reactiveValues(
      show_results = FALSE,
      show_progress = FALSE,
      recommendation = NULL,
      similarities = NULL,
      training_active = FALSE,
      training_result = NULL
    )

    # ==============================================================================
    # Step 1: Analyze Similarity
    # ==============================================================================

    observeEvent(input$analyze_similarity, {
      req(input$template_name, input$regional_sea)

      # Create target template metadata
      target_template <- list(
        name = input$template_name,
        regional_sea = input$regional_sea,
        ecosystem_types = paste(input$ecosystem_types, collapse = "; "),
        main_issues = paste(input$main_issues, collapse = "; ")
      )

      # Calculate similarity to all existing templates
      withProgress(message = "Calculating template similarities...", {

        # Load or use provided similarity functions
        if (!exists("calculate_template_similarity")) {
          if (file.exists("functions/ml_template_matching.R")) {
            source("functions/ml_template_matching.R", local = TRUE)
          } else {
            showNotification(
              "Template matching module not available",
              type = "error"
            )
            return()
          }
        }

        # Get training data
        data <- training_data()
        if (is.null(data)) {
          showNotification(i18n$t("common.messages.training_data_not_available"), type = "error")
          return()
        }

        # Get unique templates from training data
        if ("train" %in% names(data)) {
          train_df <- data$train
        } else {
          train_df <- data
        }

        template_names <- unique(train_df$template)

        # Calculate similarity to each template
        similarities <- data.frame(
          template = character(),
          overall_similarity = numeric(),
          regional_sim = numeric(),
          ecosystem_sim = numeric(),
          issue_sim = numeric(),
          vocabulary_sim = numeric(),
          type_dist_sim = numeric(),
          size_sim = numeric(),
          stringsAsFactors = FALSE
        )

        for (i in seq_along(template_names)) {
          incProgress(1 / length(template_names),
                     detail = sprintf("Analyzing %s...", template_names[i]))

          # Get source template data
          source_data <- train_df[train_df$template == template_names[i], ]

          # Calculate similarity
          sim <- calculate_template_similarity(source_data, target_template)

          similarities <- rbind(similarities, data.frame(
            template = template_names[i],
            overall_similarity = sim$overall,
            regional_sim = sim$components$regional_context,
            ecosystem_sim = sim$components$ecosystem,
            issue_sim = sim$components$focal_issue,
            vocabulary_sim = sim$components$vocabulary,
            type_dist_sim = sim$components$type_distribution,
            size_sim = sim$components$size,
            stringsAsFactors = FALSE
          ))
        }

        # Sort by overall similarity
        similarities <- similarities[order(similarities$overall_similarity, decreasing = TRUE), ]

        rv$similarities <- similarities

        # Get top recommendation
        if (nrow(similarities) > 0) {
          top <- similarities[1, ]

          rv$recommendation <- list(
            source_template = top$template,
            similarity = top$overall_similarity,
            category = if (top$overall_similarity >= 0.7) {
              "high_similarity"
            } else if (top$overall_similarity >= 0.4) {
              "medium_similarity"
            } else {
              "low_similarity"
            },
            recommend_transfer = top$overall_similarity >= 0.3
          )
        }

        rv$show_results <- TRUE
      })
    })

    # Show results flag
    output$show_results <- reactive({
      rv$show_results
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)

    # ==============================================================================
    # Step 2: Display Recommendation
    # ==============================================================================

    output$recommendation_card <- renderUI({
      req(rv$recommendation)

      rec <- rv$recommendation

      # Color based on similarity
      color <- if (rec$category == "high_similarity") {
        "success"
      } else if (rec$category == "medium_similarity") {
        "warning"
      } else {
        "danger"
      }

      # Icon
      icon_name <- if (rec$category == "high_similarity") {
        "check-circle"
      } else if (rec$category == "medium_similarity") {
        "exclamation-circle"
      } else {
        "times-circle"
      }

      # Recommendation text
      rec_text <- if (rec$recommend_transfer) {
        sprintf(
          "We recommend using transfer learning with the '%s' template as the source.
          Similarity score: %.2f (%.0f%% match)",
          rec$source_template,
          rec$similarity,
          rec$similarity * 100
        )
      } else {
        sprintf(
          "Low similarity to existing templates (best match: '%s' at %.2f).
          We recommend training from scratch for this unique template.",
          rec$source_template,
          rec$similarity
        )
      }

      div(
        class = sprintf("alert alert-%s", color),
        style = "font-size: 16px;",
        icon(icon_name, class = "fa-2x"),
        " ",
        strong("Recommendation: "),
        rec_text
      )
    })

    # Similarity table
    output$similarity_table <- renderDT({
      req(rv$similarities)

      # Format for display
      display_df <- rv$similarities
      display_df$overall_similarity <- sprintf("%.3f", display_df$overall_similarity)
      display_df$regional_sim <- sprintf("%.3f", display_df$regional_sim)
      display_df$ecosystem_sim <- sprintf("%.3f", display_df$ecosystem_sim)
      display_df$issue_sim <- sprintf("%.3f", display_df$issue_sim)

      colnames(display_df) <- c(
        "Template", "Overall", "Regional", "Ecosystem",
        "Issue", "Vocabulary", "Type Dist", "Size"
      )

      datatable(
        display_df,
        options = list(
          pageLength = 5,
          dom = 'tip',
          ordering = TRUE,
          columnDefs = list(
            list(className = 'dt-center', targets = 1:7)
          )
        ),
        rownames = FALSE
      )
    })

    # Similarity plot
    output$similarity_plot <- renderPlot({
      req(rv$recommendation, rv$similarities)

      # Get top template components
      top_sim <- rv$similarities[1, ]

      components <- data.frame(
        Component = c("Regional", "Ecosystem", "Issue", "Vocabulary", "Type Dist", "Size"),
        Similarity = c(
          top_sim$regional_sim,
          top_sim$ecosystem_sim,
          top_sim$issue_sim,
          top_sim$vocabulary_sim,
          top_sim$type_dist_sim,
          top_sim$size_sim
        )
      )

      # Bar plot
      par(mar = c(5, 10, 3, 2))
      barplot(
        components$Similarity,
        names.arg = components$Component,
        horiz = TRUE,
        las = 1,
        col = ifelse(components$Similarity >= 0.5, "#5cb85c",
                    ifelse(components$Similarity >= 0.3, "#f0ad4e", "#d9534f")),
        xlim = c(0, 1),
        main = sprintf("Similarity to '%s'", rv$recommendation$source_template),
        xlab = "Similarity Score (0-1)"
      )
      abline(v = c(0.3, 0.5, 0.7), lty = 2, col = "gray")
      legend("bottomright",
             legend = c("High (>0.5)", "Medium (0.3-0.5)", "Low (<0.3)"),
             fill = c("#5cb85c", "#f0ad4e", "#d9534f"),
             bty = "n")
    })

    # ==============================================================================
    # Step 3: Training Strategy
    # ==============================================================================

    output$performance_estimate <- renderUI({
      req(rv$recommendation)

      rec <- rv$recommendation

      # Estimate based on similarity
      if (input$training_strategy == "finetune" && rec$recommend_transfer) {
        estimated_improvement <- if (rec$similarity >= 0.7) {
          "5-8%"
        } else if (rec$similarity >= 0.5) {
          "3-5%"
        } else {
          "1-3%"
        }

        tagList(
          p(strong("Expected Accuracy Improvement:"), estimated_improvement),
          p(strong("Compared to:"), "Training from scratch"),
          p(strong("Confidence:"),
            if (rec$similarity >= 0.7) "High" else if (rec$similarity >= 0.5) "Medium" else "Low")
        )
      } else if (input$training_strategy == "pretrained") {
        tagList(
          p(strong("Zero-shot Performance:"), "May be lower than fine-tuned"),
          p(strong("No Training Required:"), "Instant deployment"),
          p(strong("Recommendation:"), "Use for prototyping only")
        )
      } else {
        tagList(
          p(strong("Training Strategy:"), "From scratch"),
          p(strong("Data Requirement:"), "Need sufficient labeled examples"),
          p(strong("Training Time:"), "~30-60 minutes")
        )
      }
    })

    output$training_info <- renderUI({
      if (input$training_strategy == "finetune") {
        freeze_count <- length(input$freeze_layers)
        total_layers <- 3  # fc1, fc2, context_embeddings
        trainable_pct <- ((total_layers - freeze_count) / total_layers) * 100

        tagList(
          p(strong("Frozen Layers:"), paste(input$freeze_layers, collapse = ", ")),
          p(strong("Trainable Parameters:"), sprintf("~%.0f%%", trainable_pct)),
          p(strong("Epochs:"), input$finetune_epochs),
          p(strong("Learning Rate:"), format(input$finetune_lr, scientific = TRUE)),
          p(strong("Estimated Time:"), sprintf("~%.0f minutes", input$finetune_epochs * 0.3))
        )
      } else if (input$training_strategy == "scratch") {
        tagList(
          p(strong("All Layers:"), "Trained from random initialization"),
          p(strong("Trainable Parameters:"), "100%"),
          p(strong("Epochs:"), "100 (with early stopping)"),
          p(strong("Learning Rate:"), "0.001"),
          p(strong("Estimated Time:"), "~30-60 minutes")
        )
      } else {
        tagList(
          p(strong("No Training:"), "Using pre-trained model as-is"),
          p(strong("Deployment:"), "Immediate"),
          p(strong("Note:"), "Performance may be suboptimal for target template")
        )
      }
    })

    # ==============================================================================
    # Training Execution (Placeholder)
    # ==============================================================================

    observeEvent(input$start_training, {
      req(rv$recommendation)

      # Show confirmation dialog
      showModal(modalDialog(
        title = "Start Model Training",
        sprintf(
          "This will start %s for template '%s'. Training may take several minutes. Continue?",
          if (input$training_strategy == "finetune") "fine-tuning" else "training from scratch",
          input$template_name
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(session$ns("confirm_training"), "Start Training", class = "btn-success")
        )
      ))
    })

    observeEvent(input$confirm_training, {
      removeModal()

      rv$show_progress <- TRUE

      # Update progress bar (simulated)
      updateProgressBar(
        session = session,
        id = "training_progress",
        value = 0,
        status = "info"
      )

      # Placeholder: In production, this would trigger actual training script
      showNotification(
        "Training pipeline integration not yet implemented.
        Please use scripts/finetune_template.R or scripts/compare_training_approaches.R manually.",
        type = "warning",
        duration = 10
      )

      # Simulate progress (for demonstration)
      # In production, this would track actual training progress
      observe({
        invalidateLater(1000)

        if (rv$training_active && rv$show_progress) {
          current_value <- input$training_progress
          if (is.null(current_value)) current_value <- 0

          new_value <- min(current_value + 5, 100)

          updateProgressBar(
            session = session,
            id = "training_progress",
            value = new_value
          )

          if (new_value >= 100) {
            rv$training_active <- FALSE
            showNotification(i18n$t("common.messages.training_complete"), type = "success")
          }
        }
      })
    })

    # Show progress flag
    output$show_progress <- reactive({
      rv$show_progress
    })
    outputOptions(output, "show_progress", suspendWhenHidden = FALSE)

    # Training log output
    output$training_log <- renderText({
      if (rv$show_progress) {
        "Training log would appear here in production implementation.\nUse scripts/finetune_template.R for actual training."
      } else {
        ""
      }
    })

    # ==============================================================================
    # Version History
    # ==============================================================================

    output$version_history_table <- renderDT({
      # Placeholder: Would load from template metadata file
      version_history <- data.frame(
        Version = c("1.0"),
        Date = c(as.character(Sys.Date())),
        Source = c("New Template"),
        Accuracy = c("N/A"),
        Notes = c("Initial version"),
        stringsAsFactors = FALSE
      )

      datatable(
        version_history,
        options = list(
          pageLength = 5,
          dom = 'tip'
        ),
        rownames = FALSE
      )
    })

    # Export metadata
    observeEvent(input$export_metadata, {
      req(input$template_name)

      metadata <- list(
        template_name = input$template_name,
        author = input$template_author,
        description = input$template_description,
        regional_sea = input$regional_sea,
        ecosystem_types = input$ecosystem_types,
        main_issues = input$main_issues,
        created_date = Sys.time(),
        recommendation = rv$recommendation,
        training_strategy = input$training_strategy,
        version = "1.0"
      )

      # Save to file
      filename <- generate_export_filename(
        paste0("template_metadata_", gsub(" ", "_", input$template_name)), ".rds"
      )

      saveRDS(metadata, filename)

      showNotification(
        sprintf("Metadata exported to: %s", filename),
        type = "message"
      )
    })

  })
}

# ==============================================================================
# Startup Message
# ==============================================================================

cat("✓ Template Recommendation module loaded\n")
cat("  - templateRecommendationUI(): UI for ML bootstrap workflow\n")
cat("  - templateRecommendationServer(): Server logic for template creation\n")
cat("  - Automatic source template recommendation\n")
cat("  - Transfer learning strategy selection\n")
cat("  - Template versioning support\n")
