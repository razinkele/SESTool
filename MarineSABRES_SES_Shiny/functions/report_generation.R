# functions/report_generation.R
# Report Generation Helper Functions
# Purpose: Centralized functions for generating various report types

# ============================================================================
# REPORT CONTENT GENERATION
# ============================================================================

#' Generate report content in R Markdown format
#'
#' @param data Project data object containing all SES information
#' @param report_type Type of report: "executive", "technical", "presentation", or "full"
#' @param include_viz Whether to include visualizations (currently unused)
#' @param include_data Whether to include raw data tables (currently unused)
#' @return Character string containing complete R Markdown document
generate_report_content <- function(data, report_type, include_viz = TRUE, include_data = FALSE) {

  cat("\n=== DEBUG: Report generation started ===\n")
  cat("Report type:", report_type, "\n")
  cat("Data structure check:\n")
  cat("  - is.list(data):", is.list(data), "\n")
  cat("  - names(data):", paste(names(data), collapse = ", "), "\n")
  flush.console()

  # ========== YAML HEADER ==========
  cat("Building YAML header...\n")

  # Ensure report_type is a character string, not a list
  report_type_safe <- as.character(report_type)[1]
  cat("  report_type class:", class(report_type), "value:", report_type_safe, "\n")
  flush.console()

  # Safely format the date
  report_date <- format(Sys.Date(), "%B %d, %Y")
  cat("  report_date class:", class(report_date), "value:", report_date, "\n")
  flush.console()

  header <- paste0(
    "---\n",
    "title: 'MarineSABRES SES Analysis Report'\n",
    "subtitle: '", report_type_safe, " Report'\n",
    "date: '", report_date, "'\n",
    "output:\n",
    "  html_document:\n",
    "    toc: true\n",
    "    toc_float: true\n",
    "---\n\n"
  )

  cat("YAML header built successfully\n")
  flush.console()

  # ========== PROJECT OVERVIEW SECTION ==========
  cat("Processing dates...\n")
  # Safely format dates (handle potential list/non-date values)
  created_date <- tryCatch({
    if (is.null(data$created_at)) {
      "Unknown"
    } else if (is.list(data$created_at)) {
      as.character(format(as.POSIXct(data$created_at[[1]]), "%Y-%m-%d"))
    } else {
      as.character(format(data$created_at, "%Y-%m-%d"))
    }
  }, error = function(e) "Unknown")

  modified_date <- tryCatch({
    if (is.null(data$last_modified)) {
      "Unknown"
    } else if (is.list(data$last_modified)) {
      as.character(format(as.POSIXct(data$last_modified[[1]]), "%Y-%m-%d"))
    } else {
      as.character(format(data$last_modified, "%Y-%m-%d"))
    }
  }, error = function(e) "Unknown")

  # Safely extract metadata fields (handle potential list values)
  da_site <- tryCatch({
    if (is.list(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site[[1]])
    } else if (!is.null(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site)
    } else {
      "Not specified"
    }
  }, error = function(e) "Not specified")

  focal_issue <- tryCatch({
    if (is.list(data$data$metadata$focal_issue)) {
      as.character(data$data$metadata$focal_issue[[1]])
    } else if (!is.null(data$data$metadata$focal_issue)) {
      as.character(data$data$metadata$focal_issue)
    } else {
      "Not defined"
    }
  }, error = function(e) "Not defined")

  cat("Dates processed:\n")
  cat("  - created_date:", created_date, "\n")
  cat("  - modified_date:", modified_date, "\n")
  cat("  - da_site:", da_site, "\n")
  cat("  - focal_issue:", focal_issue, "\n")

  cat("Building intro section...\n")

  # Safely extract project name to avoid list issues
  project_name <- if (!is.null(data$project_name)) {
    as.character(data$project_name)
  } else {
    "Unnamed Project"
  }

  intro <- paste0(
    "# Project Overview\n\n",
    "**Project:** ", project_name, "\n\n",
    "**Demonstration Area:** ", da_site, "\n\n",
    "**Focal Issue:** ", focal_issue, "\n\n",
    "**Created:** ", created_date, "\n\n",
    "**Last Modified:** ", modified_date, "\n\n"
  )
  cat("Intro section built successfully\n")

  # ========== REPORT TYPE-SPECIFIC CONTENT ==========
  cat("Generating report type-specific content for:", report_type_safe, "\n")
  flush.console()
  if (report_type_safe == "executive") {
    cat("Calling generate_executive_content()...\n")
    flush.console()
    content <- generate_executive_content(data)
  } else if (report_type_safe == "technical") {
    cat("Calling generate_technical_content()...\n")
    flush.console()
    content <- generate_technical_content(data)
  } else if (report_type_safe == "presentation") {
    cat("Calling generate_presentation_content()...\n")
    flush.console()
    content <- generate_presentation_content(data)
  } else {
    # Default to full report
    cat("Calling generate_full_content()...\n")
    flush.console()
    content <- generate_full_content(data)
  }
  cat("Type-specific content generated successfully\n")
  flush.console()

  # ========== FOOTER ==========
  cat("Building footer...\n")
  footer <- paste0(
    "\n\n---\n\n",
    "*Report generated by MarineSABRES SES Tool*\n\n",
    "*", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n"
  )
  cat("Footer built successfully\n")

  cat("Combining all sections...\n")
  result <- paste0(header, intro, content, footer)
  cat("Report content generated successfully!\n")
  cat("=== DEBUG: Report generation completed ===\n\n")

  return(result)
}

# ============================================================================
# REPORT TYPE-SPECIFIC CONTENT GENERATORS
# ============================================================================

#' Generate executive summary content
#'
#' @param data Project data object
#' @return Character string with executive summary content
generate_executive_content <- function(data) {
  cat("  [Executive] Counting ISA elements...\n")
  # Count elements correctly by summing rows in each dataframe
  # Safely count each component
  count_rows <- function(df) {
    if (is.null(df)) return(0)
    if (is.data.frame(df)) return(nrow(df))
    return(0)
  }

  n_elements <- sum(
    count_rows(data$data$isa_data$drivers),
    count_rows(data$data$isa_data$activities),
    count_rows(data$data$isa_data$pressures),
    count_rows(data$data$isa_data$marine_processes),
    count_rows(data$data$isa_data$ecosystem_services),
    count_rows(data$data$isa_data$goods_benefits),
    count_rows(data$data$isa_data$responses),
    count_rows(data$data$isa_data$measures)
  )
  cat("  [Executive] Total elements:", n_elements, "\n")

  # Safely extract metadata fields
  da_site <- tryCatch({
    if (is.list(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site[[1]])
    } else if (!is.null(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site)
    } else {
      "the study area"
    }
  }, error = function(e) "the study area")

  focal_issue <- tryCatch({
    if (is.list(data$data$metadata$focal_issue)) {
      as.character(data$data$metadata$focal_issue[[1]])
    } else if (!is.null(data$data$metadata$focal_issue)) {
      as.character(data$data$metadata$focal_issue)
    } else {
      "key system issues"
    }
  }, error = function(e) "key system issues")

  cat("  [Executive] Building content with n_elements:", n_elements, "\n")
  cat("  [Executive] da_site:", da_site, "class:", class(da_site), "\n")
  cat("  [Executive] focal_issue:", focal_issue, "class:", class(focal_issue), "\n")

  # Safely count loops and stakeholders to avoid list issues
  n_loops <- if (!is.null(data$data$cld$loops) && is.data.frame(data$data$cld$loops)) {
    as.integer(nrow(data$data$cld$loops))
  } else {
    0L
  }

  n_stakeholders <- if (!is.null(data$data$pims$stakeholders) && is.data.frame(data$data$pims$stakeholders)) {
    as.integer(nrow(data$data$pims$stakeholders))
  } else {
    0L
  }

  content <- paste0(
    "# Executive Summary\n\n",
    "This report provides a high-level overview of the social-ecological system analysis.\n\n",
    "## Key Findings\n\n",
    "- **System elements identified:** ", as.character(n_elements), "\n",
    "- **Feedback loops detected:** ", as.character(n_loops), "\n",
    "- **Stakeholders involved:** ", as.character(n_stakeholders), "\n\n",
    "## System Overview\n\n",
    "The analysis focuses on ", da_site,
    " with particular attention to ", focal_issue, ".\n\n"
  )

  cat("  [Executive] Content generated successfully\n")
  return(content)
}

#' Generate technical analysis content
#'
#' @param data Project data object
#' @return Character string with technical analysis content
generate_technical_content <- function(data) {
  cat("  [Technical] Building sections...\n")
  # Build sections separately to avoid if-else list issues in paste0
  drivers_section <- if (!is.null(data$data$isa_data$drivers) && nrow(data$data$isa_data$drivers) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$drivers), " drivers in the system.\n\n")
  } else {
    "No drivers data available.\n\n"
  }
  cat("  [Technical] drivers_section class:", class(drivers_section), "\n")

  activities_section <- if (!is.null(data$data$isa_data$activities) && nrow(data$data$isa_data$activities) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$activities), " activities.\n\n")
  } else {
    "No activities data available.\n\n"
  }
  cat("  [Technical] activities_section class:", class(activities_section), "\n")

  pressures_section <- if (!is.null(data$data$isa_data$pressures) && nrow(data$data$isa_data$pressures) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$pressures), " pressures.\n\n")
  } else {
    "No pressures data available.\n\n"
  }
  cat("  [Technical] pressures_section class:", class(pressures_section), "\n")

  states_section <- if (!is.null(data$data$isa_data$marine_processes) && nrow(data$data$isa_data$marine_processes) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$marine_processes), " state changes (marine processes/impacts).\n\n")
  } else {
    "No state changes data available.\n\n"
  }
  cat("  [Technical] states_section class:", class(states_section), "\n")

  services_section <- if (!is.null(data$data$isa_data$ecosystem_services) && nrow(data$data$isa_data$ecosystem_services) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$ecosystem_services), " ecosystem services.\n\n")
  } else {
    "No ecosystem services data available.\n\n"
  }
  cat("  [Technical] services_section class:", class(services_section), "\n")

  benefits_section <- if (!is.null(data$data$isa_data$goods_benefits) && nrow(data$data$isa_data$goods_benefits) > 0) {
    paste0("Identified ", nrow(data$data$isa_data$goods_benefits), " goods and benefits.\n\n")
  } else {
    "No goods and benefits data available.\n\n"
  }
  cat("  [Technical] benefits_section class:", class(benefits_section), "\n")

  cat("  [Technical] Combining sections with paste0...\n")
  content <- paste0(
    "# Technical Analysis\n\n",
    "## DAPSI(W)R(M) Framework Elements\n\n",
    "### Drivers (D)\n\n",
    drivers_section,
    "### Activities (A)\n\n",
    activities_section,
    "### Pressures (P)\n\n",
    pressures_section,
    "### State Changes (S/I)\n\n",
    states_section,
    "### Ecosystem Services (W)\n\n",
    services_section,
    "### Goods & Benefits (R)\n\n",
    benefits_section
  )

  cat("  [Technical] Content generated successfully\n")
  return(content)
}

#' Generate stakeholder presentation content
#'
#' @param data Project data object
#' @return Character string with presentation content
generate_presentation_content <- function(data) {
  # Safely extract metadata field
  da_site <- tryCatch({
    if (is.list(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site[[1]])
    } else if (!is.null(data$data$metadata$da_site)) {
      as.character(data$data$metadata$da_site)
    } else {
      "the study area"
    }
  }, error = function(e) "the study area")

  content <- paste0(
    "# Stakeholder Presentation\n\n",
    "## System Overview\n\n",
    "This analysis examines the social-ecological system in ",
    da_site, ".\n\n",
    "## Key Insights\n\n",
    "- Multiple interconnected system components\n",
    "- Feedback loops influencing system behavior\n",
    "- Management opportunities identified\n\n",
    "## Next Steps\n\n",
    "This presentation provides a foundation for stakeholder discussions on:\n\n",
    "- System understanding and mental model alignment\n",
    "- Identification of key leverage points\n",
    "- Development of response strategies\n\n"
  )

  return(content)
}

#' Generate full analysis content
#'
#' @param data Project data object
#' @return Character string with complete analysis content
generate_full_content <- function(data) {
  cat("  [Full] Building enhanced sections...\n")

  # ========== SYSTEM OVERVIEW ==========
  n_nodes <- if (!is.null(data$data$cld$nodes) && is.data.frame(data$data$cld$nodes)) {
    as.integer(nrow(data$data$cld$nodes))
  } else {
    0L
  }

  n_edges <- if (!is.null(data$data$cld$edges) && is.data.frame(data$data$cld$edges)) {
    as.integer(nrow(data$data$cld$edges))
  } else {
    0L
  }

  n_loops <- if (!is.null(data$data$cld$loops) && is.data.frame(data$data$cld$loops)) {
    as.integer(nrow(data$data$cld$loops))
  } else {
    0L
  }

  # Calculate network density separately to avoid if-else in paste0
  network_density <- if (n_nodes > 1) {
    as.character(round(n_edges / (n_nodes * (n_nodes - 1)), 3))
  } else {
    "0"
  }

  # DEBUG: Check all variables before paste0
  cat("  [Full] DEBUG - Before overview_section paste0:\n")
  cat("    n_nodes class:", class(n_nodes), "value:", n_nodes, "\n")
  cat("    n_edges class:", class(n_edges), "value:", n_edges, "\n")
  cat("    n_loops class:", class(n_loops), "value:", n_loops, "\n")
  cat("    network_density class:", class(network_density), "value:", network_density, "\n")
  flush.console()

  overview_section <- paste0(
    "# Complete SES Analysis Report\n\n",
    "## Executive Summary\n\n",
    "This report presents a comprehensive analysis of the social-ecological system, including:\n\n",
    "- **Network Structure**: ", as.character(n_nodes), " system elements with ", as.character(n_edges), " causal connections\n",
    "- **Feedback Dynamics**: ", as.character(n_loops), " feedback loops identified\n",
    "- **System Complexity**: Network density of ", network_density, "\n\n"
  )
  cat("  [Full] overview_section created successfully, class:", class(overview_section), "\n")

  # ========== DETAILED LOOP ANALYSIS ==========
  cat("  [Full] DEBUG - Starting loop analysis section...\n")
  loops_section <- if (!is.null(data$data$cld$loops) && nrow(data$data$cld$loops) > 0) {
    cat("  [Full] DEBUG - Loops data exists, processing...\n")
    loops <- data$data$cld$loops
    cat("  [Full] DEBUG - loops is.data.frame:", is.data.frame(loops), "nrow:", nrow(loops), "\n")

    n_reinforcing <- sum(loops$Type == "Reinforcing", na.rm = TRUE)
    n_balancing <- sum(loops$Type == "Balancing", na.rm = TRUE)
    cat("  [Full] DEBUG - n_reinforcing:", n_reinforcing, "class:", class(n_reinforcing), "\n")
    cat("  [Full] DEBUG - n_balancing:", n_balancing, "class:", class(n_balancing), "\n")

    # Analyze loop lengths
    loop_lengths <- nchar(gsub("[^→]", "", loops$Path)) + 1
    avg_length <- round(mean(loop_lengths, na.rm = TRUE), 1)
    max_length <- max(loop_lengths, na.rm = TRUE)
    min_length <- min(loop_lengths, na.rm = TRUE)
    cat("  [Full] DEBUG - avg_length:", avg_length, "class:", class(avg_length), "\n")
    cat("  [Full] DEBUG - max_length:", max_length, "class:", class(max_length), "\n")
    cat("  [Full] DEBUG - min_length:", min_length, "class:", class(min_length), "\n")

    # Get top loops by length
    top_loops_idx <- head(order(loop_lengths, decreasing = TRUE), min(5, nrow(loops)))
    cat("  [Full] DEBUG - top_loops_idx:", paste(top_loops_idx, collapse=", "), "\n")

    cat("  [Full] DEBUG - Building top_loops_text with sapply...\n")
    top_loops_text <- paste(sapply(top_loops_idx, function(i) {
      # Calculate ellipsis separately to avoid if-else in paste0
      path_ellipsis <- if(nchar(loops$Path[i]) > 80) "..." else ""
      cat("    [sapply iter] Loop", i, "Type:", loops$Type[i], "class:", class(loops$Type[i]), "\n")
      cat("    [sapply iter] loop_lengths[", i, "]:", loop_lengths[i], "class:", class(loop_lengths[i]), "\n")
      cat("    [sapply iter] path_ellipsis class:", class(path_ellipsis), "\n")
      paste0("   - **Loop ", i, "** (", loops$Type[i], ", ", loop_lengths[i], " nodes): ",
             substr(loops$Path[i], 1, 80), path_ellipsis, "\n")
    }), collapse = "")
    cat("  [Full] DEBUG - top_loops_text created, class:", class(top_loops_text), "\n")

    # Calculate system implications separately to avoid if-else in paste0
    cat("  [Full] DEBUG - Building system_implications_text...\n")
    system_implications_text <- if (n_reinforcing > n_balancing) {
      paste0("⚠️ **High proportion of reinforcing loops** (", round(n_reinforcing/nrow(loops)*100, 1),
             "%) suggests the system may be prone to rapid changes and potential instability. ",
             "Management interventions should focus on:\n",
             "1. Monitoring for early warning signals of tipping points\n",
             "2. Strengthening balancing mechanisms\n",
             "3. Managing reinforcing loops to prevent runaway dynamics\n\n")
    } else if (n_balancing > n_reinforcing) {
      paste0("✓ **High proportion of balancing loops** (", round(n_balancing/nrow(loops)*100, 1),
             "%) suggests the system has strong self-regulating capacity and resilience. ",
             "However, this may also indicate:\n",
             "1. Resistance to change and management interventions\n",
             "2. Need for persistent effort to achieve desired outcomes\n",
             "3. Importance of identifying leverage points to overcome system inertia\n\n")
    } else {
      "The balanced mix of reinforcing and balancing loops suggests moderate system stability with capacity for both change and self-regulation.\n\n"
    }

    # Convert all numeric values to characters for safe paste0
    total_loops <- as.character(as.integer(nrow(loops)))
    pct_reinforcing <- as.character(round(n_reinforcing/nrow(loops)*100, 1))
    pct_balancing <- as.character(round(n_balancing/nrow(loops)*100, 1))

    cat("  [Full] DEBUG - Before final loops paste0:\n")
    cat("    total_loops:", total_loops, "class:", class(total_loops), "\n")
    cat("    n_reinforcing:", n_reinforcing, "class:", class(n_reinforcing), "\n")
    cat("    pct_reinforcing:", pct_reinforcing, "class:", class(pct_reinforcing), "\n")
    cat("    n_balancing:", n_balancing, "class:", class(n_balancing), "\n")
    cat("    pct_balancing:", pct_balancing, "class:", class(pct_balancing), "\n")
    cat("    avg_length:", avg_length, "class:", class(avg_length), "\n")
    cat("    min_length:", min_length, "class:", class(min_length), "\n")
    cat("    max_length:", max_length, "class:", class(max_length), "\n")
    cat("    top_loops_text class:", class(top_loops_text), "\n")
    cat("    system_implications_text class:", class(system_implications_text), "\n")

    cat("  [Full] DEBUG - Calling paste0 for loops section...\n")
    result <- paste0(
      "## Feedback Loop Analysis\n\n",
      "### Loop Discovery\n\n",
      "Detected **", total_loops, " feedback loops** in the system:\n\n",
      "- **", as.character(n_reinforcing), " Reinforcing loops** (", pct_reinforcing, "%) - These amplify changes and can lead to exponential growth or decline\n",
      "- **", as.character(n_balancing), " Balancing loops** (", pct_balancing, "%) - These stabilize the system and resist change\n\n",
      "### Loop Characteristics\n\n",
      "- **Average loop length**: ", as.character(avg_length), " nodes\n",
      "- **Shortest loop**: ", as.character(min_length), " nodes\n",
      "- **Longest loop**: ", as.character(max_length), " nodes\n\n",
      "### Key Feedback Loops\n\n",
      "The following loops represent the most complex feedback structures:\n\n",
      top_loops_text, "\n",
      "### System Implications\n\n",
      system_implications_text
    )
    cat("  [Full] DEBUG - Loops section paste0 completed successfully!\n")
    result
  } else {
    cat("  [Full] DEBUG - No loops data, using default message\n")
    "## Feedback Loop Analysis\n\n⚠️ No feedback loops detected yet. Run loop detection analysis to identify circular causality in the system.\n\n"
  }
  cat("  [Full] loops_section class:", class(loops_section), "\n")

  # ========== LEVERAGE POINT ANALYSIS ==========
  leverage_section <- if (!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
    nodes <- data$data$cld$nodes

    # Check if leverage scores exist
    if ("leverage_score" %in% names(nodes) && any(nodes$leverage_score > 0, na.rm = TRUE)) {
      leverage_nodes <- nodes[nodes$leverage_score > 0, ]
      leverage_nodes <- leverage_nodes[order(-leverage_nodes$leverage_score), ]

      top_n <- min(10, nrow(leverage_nodes))
      top_leverage <- leverage_nodes[1:top_n, ]

      # Categorize by influence type
      high_in <- top_leverage[top_leverage$in_degree >= quantile(nodes$in_degree, 0.75, na.rm = TRUE), ]
      high_out <- top_leverage[top_leverage$out_degree >= quantile(nodes$out_degree, 0.75, na.rm = TRUE), ]
      high_between <- if ("betweenness" %in% names(top_leverage)) {
        top_leverage[top_leverage$betweenness >= quantile(nodes$betweenness, 0.75, na.rm = TRUE), ]
      } else { data.frame() }

      top_leverage_text <- paste(sapply(1:top_n, function(i) {
        node <- top_leverage[i, ]
        # Calculate betweenness text separately to avoid if-else in paste0
        betweenness_text <- if ("betweenness" %in% names(node)) paste0(" | Betweenness: ", round(node$betweenness, 2)) else ""
        paste0("   ", i, ". **", node$label, "** (Score: ", round(node$leverage_score, 2), ")\n",
               "      - In-degree: ", node$in_degree, " | Out-degree: ", node$out_degree,
               betweenness_text, "\n")
      }), collapse = "")

      # Calculate category examples separately to avoid if-else in paste0
      receivers_text <- if (nrow(high_in) > 0) paste0(":\n   ", paste(head(high_in$label, 3), collapse = ", "), "\n") else "\n"
      drivers_text <- if (nrow(high_out) > 0) paste0(":\n   ", paste(head(high_out$label, 3), collapse = ", "), "\n") else "\n"
      connectors_text <- if (nrow(high_between) > 0) paste0(":\n   ", paste(head(high_between$label, 3), collapse = ", "), "\n") else "\n"

      paste0(
        "## Leverage Point Analysis\n\n",
        "### Overview\n\n",
        "Identified **", nrow(leverage_nodes), " nodes with leverage potential** based on network centrality metrics.\n\n",
        "### Top 10 Leverage Points\n\n",
        top_leverage_text, "\n",
        "### Leverage Point Categories\n\n",
        "**Receivers** (High in-degree, ", nrow(high_in), " nodes): These are affected by many system components", receivers_text,
        "   → *Management implication*: Monitor as indicators of system state\n\n",
        "**Drivers** (High out-degree, ", nrow(high_out), " nodes): These influence many system components", drivers_text,
        "   → *Management implication*: Target for interventions to create cascading effects\n\n",
        "**Connectors** (High betweenness, ", nrow(high_between), " nodes): These bridge different system parts", connectors_text,
        "   → *Management implication*: Critical for maintaining system connectivity\n\n",
        "### Strategic Recommendations\n\n",
        "1. **Priority interventions**: Focus on top 3-5 leverage points for maximum impact\n",
        "2. **Monitoring network**: Track Receiver nodes as early warning indicators\n",
        "3. **Intervention targets**: Use Driver nodes to initiate desired changes\n",
        "4. **System coherence**: Protect Connector nodes to maintain system integrity\n\n"
      )
    } else {
      "## Leverage Point Analysis\n\n⚠️ No leverage point analysis performed yet. Run leverage point detection to identify high-impact intervention points.\n\n"
    }
  } else {
    "## Leverage Point Analysis\n\n⚠️ No CLD nodes available for leverage analysis.\n\n"
  }
  cat("  [Full] leverage_section class:", class(leverage_section), "\n")

  # ========== NETWORK METRICS ==========
  network_section <- if (!is.null(data$data$cld$nodes) && nrow(data$data$cld$nodes) > 0) {
    nodes <- data$data$cld$nodes
    # Safely get edges to avoid list issues
    edges <- if (!is.null(data$data$cld$edges)) data$data$cld$edges else data.frame()

    n_nodes <- nrow(nodes)
    n_edges <- nrow(edges)
    density <- if (n_nodes > 1) n_edges / (n_nodes * (n_nodes - 1)) else 0

    avg_in <- mean(nodes$in_degree, na.rm = TRUE)
    avg_out <- mean(nodes$out_degree, na.rm = TRUE)

    # Calculate interpretation separately to avoid if-else in paste0
    interpretation_text <- if (density < 0.1) {
      "**Sparse network**: Low connectivity suggests modular structure with distinct subsystems. Management can focus on specific components with limited spillover effects.\n\n"
    } else if (density < 0.3) {
      "**Moderate connectivity**: Balanced structure with some interconnections. Interventions will have localized effects with some system-wide implications.\n\n"
    } else {
      "**Highly connected network**: Dense interconnections mean interventions will have widespread effects. Requires careful analysis of cascading impacts.\n\n"
    }

    paste0(
      "## Network Structure Metrics\n\n",
      "### Basic Metrics\n\n",
      "- **Nodes**: ", n_nodes, " system elements\n",
      "- **Edges**: ", n_edges, " causal connections\n",
      "- **Density**: ", round(density, 3), " (", round(density * 100, 1), "% of possible connections)\n",
      "- **Average in-degree**: ", round(avg_in, 2), " connections per node\n",
      "- **Average out-degree**: ", round(avg_out, 2), " connections per node\n\n",
      "### Interpretation\n\n",
      interpretation_text
    )
  } else {
    "## Network Structure\n\n⚠️ No CLD network available for analysis.\n\n"
  }
  cat("  [Full] network_section class:", class(network_section), "\n")

  # ========== STAKEHOLDER ANALYSIS ==========
  stakeholder_section <- if (!is.null(data$data$pims$stakeholders) && nrow(data$data$pims$stakeholders) > 0) {
    n_stakeholders <- nrow(data$data$pims$stakeholders)
    paste0(
      "## Stakeholder Analysis\n\n",
      "Identified **", n_stakeholders, " stakeholders** in the system.\n\n",
      "Key considerations for stakeholder engagement:\n\n",
      "1. Align stakeholder interests with leverage point interventions\n",
      "2. Engage stakeholders affected by high-impact feedback loops\n",
      "3. Build coalitions around shared system goals\n",
      "4. Communicate system complexity and interconnections\n\n"
    )
  } else {
    "## Stakeholder Analysis\n\n⚠️ No stakeholder data available.\n\n"
  }
  cat("  [Full] stakeholder_section class:", class(stakeholder_section), "\n")

  # ========== MANAGEMENT RECOMMENDATIONS ==========
  recommendations_section <- paste0(
    "## Management Recommendations\n\n",
    "### Strategic Priorities\n\n",
    "Based on the system analysis, the following management priorities are recommended:\n\n",
    "1. **Intervention Design**\n",
    "   - Target top leverage points identified in the analysis\n",
    "   - Consider feedback loop dynamics when designing interventions\n",
    "   - Account for system density and interconnectedness\n\n",
    "2. **Monitoring Strategy**\n",
    "   - Track nodes with high in-degree as system state indicators\n",
    "   - Monitor reinforcing loops for early warning signals\n",
    "   - Measure network connectivity changes over time\n\n",
    "3. **Adaptive Management**\n",
    "   - Use balancing loops to stabilize desired outcomes\n",
    "   - Manage reinforcing loops to prevent unintended amplification\n",
    "   - Maintain system connector nodes to preserve resilience\n\n",
    "4. **Stakeholder Engagement**\n",
    "   - Involve stakeholders linked to high-leverage nodes\n",
    "   - Communicate system feedback dynamics\n",
    "   - Build shared understanding of system behavior\n\n",
    "### Next Steps\n\n",
    "1. Validate loop and leverage point analyses with domain experts\n",
    "2. Develop detailed intervention strategies for priority leverage points\n",
    "3. Establish monitoring protocols for key indicators\n",
    "4. Design adaptive management experiments to test interventions\n",
    "5. Engage stakeholders in participatory scenario planning\n\n"
  )

  # ========== COMBINE ALL SECTIONS ==========
  cat("  [Full] Combining all sections...\n")
  cat("  [Full] DEBUG - Before final combination paste0:\n")
  cat("    overview_section class:", class(overview_section), "\n")
  cat("    loops_section class:", class(loops_section), "\n")
  cat("    leverage_section class:", class(leverage_section), "\n")
  cat("    network_section class:", class(network_section), "\n")
  cat("    stakeholder_section class:", class(stakeholder_section), "\n")
  cat("    recommendations_section class:", class(recommendations_section), "\n")

  content <- paste0(
    overview_section,
    loops_section,
    leverage_section,
    network_section,
    stakeholder_section,
    recommendations_section
  )

  cat("  [Full] Enhanced content generated successfully\n")
  cat("  [Full] Final content class:", class(content), "\n")
  return(content)
}
