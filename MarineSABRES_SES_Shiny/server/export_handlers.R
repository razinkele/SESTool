# server/export_handlers.R
# Data and visualization export handlers for the MarineSABRES SES Toolbox
# Extracted from app.R for better maintainability

# ============================================================================
# EXPORT HANDLERS
# ============================================================================

#' Setup Export Handlers
#'
#' Sets up handlers for exporting data and visualizations in various formats
#'
#' @param input Shiny input object
#' @param output Shiny output object
#' @param session Shiny session object
#' @param project_data reactiveVal containing project data
#' @param i18n shiny.i18n translator object
setup_export_handlers <- function(input, output, session, project_data, i18n) {

  # ========== DATA EXPORT ==========

  output$download_data <- downloadHandler(
    filename = function() {
      format <- input$export_data_format
      ext <- switch(format,
        "Excel (.xlsx)" = ".xlsx",
        "CSV (.csv)" = ".csv",
        "JSON (.json)" = ".json",
        "R Data (.RData)" = ".RData"
      )
      generate_export_filename("MarineSABRES_Data", ext)
    },
    content = function(file) {
      tryCatch({
        data <- project_data()
        components <- input$export_data_components

        # Validate data exists
        if (is.null(data)) {
          showNotification(i18n$t("common.messages.no_data_to_export"), type = "error")
          return(NULL)
        }

        # Prepare export data based on selected components
        export_list <- list()

      if("metadata" %in% components) {
        export_list$metadata <- data$data$metadata
        export_list$project_info <- list(
          project_id = data$project_id,
          project_name = data$project_name,
          created_at = data$created_at,
          last_modified = data$last_modified
        )
      }

      if("pims" %in% components) {
        export_list$pims <- data$data$pims
      }

      if("isa_data" %in% components) {
        export_list$goods_benefits <- data$data$isa_data$goods_benefits
        export_list$ecosystem_services <- data$data$isa_data$ecosystem_services
        export_list$marine_processes <- data$data$isa_data$marine_processes
        export_list$pressures <- data$data$isa_data$pressures
        export_list$activities <- data$data$isa_data$activities
        export_list$drivers <- data$data$isa_data$drivers
        export_list$bot_data <- data$data$isa_data$bot_data
      }

      if("cld" %in% components) {
        export_list$cld_nodes <- data$data$cld$nodes
        export_list$cld_edges <- data$data$cld$edges
        export_list$cld_loops <- data$data$cld$loops
      }

      if("analysis" %in% components) {
        export_list$analysis_results <- data$data$analysis
      }

      if("responses" %in% components) {
        export_list$response_measures <- data$data$responses
      }

      # Export based on format
      format <- input$export_data_format

      if(format == "Excel (.xlsx)") {
        wb <- createWorkbook()

        # Add each component as a worksheet
        for(name in names(export_list)) {
          item <- export_list[[name]]
          if(is.data.frame(item) && nrow(item) > 0) {
            addWorksheet(wb, name)
            writeData(wb, name, item)
          } else if(is.list(item) && !is.data.frame(item)) {
            # Convert list to data frame
            df <- as.data.frame(t(unlist(item)), stringsAsFactors = FALSE)
            addWorksheet(wb, name)
            writeData(wb, name, df)
          }
        }

        saveWorkbook(wb, file, overwrite = TRUE)

      } else if(format == "CSV (.csv)") {
        # For CSV, export the main ISA data
        if("isa_data" %in% components && !is.null(data$data$isa_data$goods_benefits)) {
          write.csv(data$data$isa_data$goods_benefits, file, row.names = FALSE)
        } else {
          write.csv(data.frame(message = "No data to export"), file, row.names = FALSE)
        }

      } else if(format == "JSON (.json)") {
        json_data <- toJSON(export_list, pretty = TRUE, auto_unbox = TRUE)
        writeLines(json_data, file)

      } else if(format == "R Data (.RData)") {
        save(export_list, file = file)
      }

        showNotification(i18n$t("common.messages.data_exported_successfully"), type = "message")
      }, error = function(e) {
        debug_log(paste("Data export error:", e$message), "EXPORT", "ERROR")
        showNotification(
          paste(i18n$t("common.messages.export_failed"), e$message),
          type = "error",
          duration = 10
        )
      })
    }
  )

  # ========== VISUALIZATION EXPORT ==========

  output$download_viz <- downloadHandler(
    filename = function() {
      format <- input$export_viz_format
      ext <- switch(format,
        "PNG (.png)" = ".png",
        "SVG (.svg)" = ".svg",
        "HTML (.html)" = ".html",
        "PDF (.pdf)" = ".pdf"
      )
      generate_export_filename("MarineSABRES_CLD", ext)
    },
    content = function(file) {
      tryCatch({
        data <- project_data()

        # Check if CLD data exists
        if(is.null(data$data$cld$nodes) || nrow(data$data$cld$nodes) == 0) {
          showNotification(i18n$t("common.misc.no_cld_data_to_export_please_create_a_cld_first"), type = "error")
          return(NULL)
        }

        nodes <- data$data$cld$nodes
        edges <- data$data$cld$edges
        if (is.null(edges) || !is.data.frame(edges) || nrow(edges) == 0) {
          edges <- data.frame(from = character(0), to = character(0),
                              stringsAsFactors = FALSE)
        }

      format <- input$export_viz_format
      width <- input$export_viz_width
      height <- input$export_viz_height

      if(format == "HTML (.html)") {
        # Create interactive HTML visualization
        viz <- visNetwork(nodes, edges, width = paste0(width, "px"), height = paste0(height, "px")) %>%
          visIgraphLayout(layout = "layout_with_fr") %>%
          visNodes(
            borderWidth = 2,
            font = list(size = 14)
          ) %>%
          visEdges(
            arrows = "to",
            smooth = list(enabled = TRUE, type = "curvedCW")
          ) %>%
          visOptions(
            highlightNearest = list(enabled = TRUE, hover = TRUE),
            nodesIdSelection = TRUE
          ) %>%
          visInteraction(
            navigationButtons = TRUE,
            hover = TRUE,
            zoomView = TRUE
          ) %>%
          visLegend(width = 0.1, position = "right")

        visSave(viz, file)

      } else if(format == "PNG (.png)" || format == "SVG (.svg)" || format == "PDF (.pdf)") {
        # For static exports, create an igraph object and plot
        # Create igraph object
        g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)

        # Set vertex attributes
        V(g)$label <- V(g)$label
        V(g)$color <- V(g)$color
        V(g)$size <- 15

        # Set edge attributes
        E(g)$color <- ifelse(edges$link_type == "positive", "#06D6A0", "#E63946")
        E(g)$arrow.size <- 0.5

        # Open appropriate device
        if(format == "PNG (.png)") {
          png(file, width = width, height = height, res = 150)
        } else if(format == "SVG (.svg)") {
          svg(file, width = width/100, height = height/100)
        } else if(format == "PDF (.pdf)") {
          pdf(file, width = width/100, height = height/100)
        }

        # Plot
        par(mar = PLOT_MARGINS)
        plot(g,
             layout = layout_with_fr(g),
             vertex.label.cex = 0.8,
             vertex.label.color = "black",
             vertex.frame.color = "gray",
             edge.curved = 0.2,
             main = "MarineSABRES Causal Loop Diagram")

        # Add legend
        legend("bottomright",
               legend = c("Positive link", "Negative link"),
               col = c("#06D6A0", "#E63946"),
               lty = 1, lwd = 2,
               bty = "n")

        dev.off()
      }

        showNotification(i18n$t("common.messages.visualization_exported_successfully"), type = "message")
      }, error = function(e) {
        debug_log(paste("Visualization export error:", e$message), "EXPORT", "ERROR")
        # Ensure graphics device is closed on error
        tryCatch(dev.off(), error = function(e2) NULL)
        showNotification(
          paste(i18n$t("common.messages.export_failed"), e$message),
          type = "error",
          duration = 10
        )
      })
    }
  )

}
