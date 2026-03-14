# config/tutorial_content.R
# Tutorial content definitions for all features
# Centralized location for managing tutorial messages

#' Get Tutorial Content
#'
#' Returns tutorial configuration for a specific feature
#'
#' @param feature_id Feature identifier
#' @param i18n Optional i18n translator for localization
#' @return List with title, message, and other tutorial parameters
get_tutorial_content <- function(feature_id, i18n = NULL) {

  # Helper function to get translated text or default
  t <- function(key, default) {
    if (!is.null(i18n)) {
      tryCatch(i18n$t(key), error = function(e) default)
    } else {
      default
    }
  }

  tutorials <- list(

    # ========== ISA DATA ENTRY ==========
    isa_data_entry = list(
      title = "Welcome to ISA Data Entry!",
      message = paste(
        "<p><strong>Impact-Drivers-Activities-Pressures-State-Impact-Welfare-Response (ISA)</strong> ",
        "is a framework for analyzing social-ecological systems.</p>",
        "<p>📝 <strong>Getting Started:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>Add <strong>Drivers</strong> (economic, social forces)</li>",
        "<li>Define <strong>Activities</strong> (human actions)</li>",
        "<li>Identify <strong>Pressures</strong> (impacts on environment)</li>",
        "<li>Describe <strong>State changes</strong> (ecosystem effects)</li>",
        "</ul>",
        "<p>💡 <strong>Tip:</strong> Start simple and refine as you go!</p>"
      ),
      position = "center",
      auto_dismiss_ms = 15000
    ),

    # ========== AI ISA ASSISTANT ==========
    ai_assistant = list(
      title = "AI ISA Assistant",
      message = paste(
        "<p>🤖 Your <strong>AI-powered assistant</strong> helps you build ISA frameworks quickly!</p>",
        "<p><strong>What it can do:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>Suggest relevant Drivers, Activities, and Pressures</li>",
        "<li>Auto-fill descriptions based on your focal issue</li>",
        "<li>Generate complete ISA structures from your input</li>",
        "</ul>",
        "<p>⚙️ <strong>Auto-save:</strong> Enable in <em>Settings → Application Settings</em> ",
        "to automatically save AI-generated content.</p>",
        "<p>⚠️ <strong>Note:</strong> Always review and edit AI suggestions!</p>"
      ),
      position = "center",
      auto_dismiss_ms = 18000
    ),

    # ========== CLD GENERATION ==========
    cld_generation = list(
      title = "Causal Loop Diagram Generated!",
      message = paste(
        "<p>🕸️ Your ISA data has been converted into a <strong>Causal Loop Diagram (CLD)</strong>!</p>",
        "<p><strong>What you can do:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Explore connections</strong> between elements</li>",
        "<li><strong>Detect feedback loops</strong> (reinforcing & balancing)</li>",
        "<li><strong>Identify leverage points</strong> for intervention</li>",
        "<li><strong>Export</strong> for presentations or reports</li>",
        "</ul>",
        "<p>💡 <strong>Tip:</strong> Click nodes to see details and connections!</p>"
      ),
      position = "top",
      auto_dismiss_ms = 16000,
      show_confetti = TRUE
    ),

    # ========== NETWORK ANALYSIS ==========
    network_analysis = list(
      title = "Network Analysis Tools",
      message = paste(
        "<p>📈 Powerful tools to analyze your social-ecological network!</p>",
        "<p><strong>Available analyses:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Centrality measures</strong> - Find most influential nodes</li>",
        "<li><strong>Loop detection</strong> - Identify feedback mechanisms</li>",
        "<li><strong>Structural analysis</strong> - Understand network topology</li>",
        "<li><strong>Leverage points</strong> - Discover intervention opportunities</li>",
        "</ul>",
        "<p>🎯 <strong>Pro tip:</strong> Compare different scenarios to see impacts!</p>"
      ),
      position = "center",
      auto_dismiss_ms = 14000
    ),

    # ========== LOOP DETECTION ==========
    loop_detection = list(
      title = "Feedback Loops Detected!",
      message = paste(
        "<p>🔄 Feedback loops are <strong>critical</strong> for understanding system behavior!</p>",
        "<p><strong>Types of loops:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Reinforcing loops</strong> (➕) - Amplify changes (growth/decline)</li>",
        "<li><strong>Balancing loops</strong> (➖) - Stabilize the system</li>",
        "</ul>",
        "<p>📊 <strong>What to look for:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>Short loops (2-4 nodes) - Immediate effects</li>",
        "<li>Long loops (5+ nodes) - Complex interactions</li>",
        "<li>Nested loops - Multiple feedback mechanisms</li>",
        "</ul>"
      ),
      position = "center",
      auto_dismiss_ms = 16000
    ),

    # ========== TEMPLATE IMPORT ==========
    template_import = list(
      title = "Import Pre-built Templates",
      message = paste(
        "<p>📥 Load example SES frameworks to <strong>jump-start</strong> your analysis!</p>",
        "<p><strong>Available templates:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Marine fisheries</strong> - Coastal fishing systems</li>",
        "<li><strong>Aquaculture</strong> - Fish farming operations</li>",
        "<li><strong>Coastal tourism</strong> - Recreation and development</li>",
        "<li><strong>Generic marine SES</strong> - Customizable starting point</li>",
        "</ul>",
        "<p>✏️ <strong>Customize:</strong> Edit any template to match your specific case!</p>"
      ),
      position = "center",
      auto_dismiss_ms = 14000
    ),

    # ========== FILE UPLOAD ==========
    file_upload = list(
      title = "Upload Your Own Data",
      message = paste(
        "<p>📤 Import data from <strong>Excel or JSON</strong> files!</p>",
        "<p><strong>Supported formats:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Excel (.xlsx)</strong> - Structured ISA data tables</li>",
        "<li><strong>JSON (.json)</strong> - Full project exports</li>",
        "<li><strong>Network data</strong> - Edge lists and node attributes</li>",
        "</ul>",
        "<p>📋 <strong>Required columns:</strong> ID, Label, Category (see manual for details)</p>",
        "<p>⚠️ Files must be under 100 MB</p>"
      ),
      position = "center",
      auto_dismiss_ms = 13000
    ),

    # ========== AUTO-SAVE MODE BADGE ==========
    mode_badge = list(
      title = "Adaptive Auto-Save",
      message = paste(
        "<p>💾 The badge shows the <strong>current auto-save mode</strong>!</p>",
        "<p><strong>Click to toggle</strong> between:</p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>Compact view</strong> - 💤 2 or ⚡ 5</li>",
        "<li><strong>Detailed view</strong> - Shows mode, delay, and edit count</li>",
        "</ul>",
        "<p><strong>Modes explained:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>💤 <strong>Casual</strong> - Saves 2 seconds after last edit</li>",
        "<li>⚡ <strong>Rapid</strong> - Saves 5 seconds after last edit (3+ quick edits)</li>",
        "</ul>",
        "<p>Your preference is saved across sessions!</p>"
      ),
      position = "bottom",
      auto_dismiss_ms = 12000
    ),

    # ========== SES CREATION ==========
    ses_creation = list(
      title = "Create Your SES Network",
      message = paste(
        "<p>🌊 Build a <strong>Social-Ecological System</strong> from scratch!</p>",
        "<p><strong>Three ways to create:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>🎨 <strong>Visual editor</strong> - Click and drag to build</li>",
        "<li>📊 <strong>ISA data entry</strong> - Structured framework approach</li>",
        "<li>📥 <strong>Import template</strong> - Start from example</li>",
        "</ul>",
        "<p>💡 <strong>Best practice:</strong> Define your focal issue first!</p>"
      ),
      position = "top",
      auto_dismiss_ms = 14000
    ),

    # ========== EXPORT REPORT ==========
    export_report = list(
      title = "Export Your Analysis",
      message = paste(
        "<p>📄 Generate comprehensive reports for stakeholders!</p>",
        "<p><strong>Export formats:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li><strong>PDF</strong> - Full report with visualizations</li>",
        "<li><strong>HTML</strong> - Interactive web report</li>",
        "<li><strong>JSON</strong> - Data for reuse/collaboration</li>",
        "<li><strong>Excel</strong> - Tables and matrices</li>",
        "</ul>",
        "<p>📸 <strong>Includes:</strong> Network diagrams, loop analysis, centrality measures</p>"
      ),
      position = "center",
      auto_dismiss_ms = 13000
    ),

    # ========== GRAPHICAL SES CREATOR ==========
    graphical_ses_creator = list(
      title = "Graphical SES Creator",
      message = paste(
        "<p>✨ <strong>Build your SES network step-by-step</strong> with AI guidance!</p>",
        "<p><strong>How it works:</strong></p>",
        "<ul style='margin: 10px 0; padding-left: 20px;'>",
        "<li>🧭 <strong>Context Wizard</strong> - Set regional sea, ecosystem, and issue</li>",
        "<li>🤖 <strong>AI Classification</strong> - AI suggests element types (DAPSIWRM)</li>",
        "<li>🕸️ <strong>Graphical Building</strong> - Click nodes to expand network</li>",
        "<li>👻 <strong>Ghost Nodes</strong> - Preview suggestions before adding</li>",
        "<li>💾 <strong>Export to ISA</strong> - Convert to standard ISA format</li>",
        "</ul>",
        "<p>💡 <strong>Tip:</strong> Start with your most important element, then expand!</p>",
        "<p>⚡ <strong>Features:</strong> Undo/redo, auto-suggestions, context-aware AI</p>"
      ),
      position = "center",
      auto_dismiss_ms = 18000
    )
  )

  # Return tutorial config for requested feature
  if (feature_id %in% names(tutorials)) {
    return(tutorials[[feature_id]])
  } else {
    # Default tutorial if feature not found
    return(list(
      title = "Welcome!",
      message = "<p>Explore this feature to learn more.</p>",
      position = "center",
      auto_dismiss_ms = 10000
    ))
  }
}

#' List All Available Tutorials
#'
#' Returns a vector of all feature IDs that have tutorials
#'
#' @return Character vector of feature IDs
list_available_tutorials <- function() {
  c(
    "isa_data_entry",
    "ai_assistant",
    "cld_generation",
    "network_analysis",
    "loop_detection",
    "template_import",
    "file_upload",
    "mode_badge",
    "ses_creation",
    "export_report",
    "graphical_ses_creator"
  )
}
