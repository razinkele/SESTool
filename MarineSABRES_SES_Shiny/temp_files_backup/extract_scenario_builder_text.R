# Extract all hardcoded English text from scenario_builder_module.R
# This script identifies all UI strings that need translation

library(stringr)

# Read the module file
module_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/modules/scenario_builder_module.R"
code <- readLines(module_file, warn = FALSE)

# Extract all text strings that appear in UI contexts
# Pattern: strings in quotes that are likely UI text

all_texts <- list()

# Patterns to extract
patterns <- list(
  # h2, h4, h5, h6, p text
  h_tags = 'h[2-6]\\([^)]*["\']([^"\']+)["\']',
  # p() function
  p_tags = 'p\\([^)]*["\']([^"\']+)["\']',
  # icon labels and titles
  titles = 'title\\s*=\\s*["\']([^"\']+)["\']',
  # actionButton labels
  action_btn = 'actionButton\\([^,]+,\\s*["\']([^"\']+)["\']',
  # Button text
  modal_btn = 'modalButton\\(["\']([^"\']+)["\']',
  # selectInput labels
  select_label = 'selectInput\\([^,]+,\\s*["\']([^"\']+)["\']',
  # textInput labels
  text_input = 'textInput\\([^,]+,\\s*["\']([^"\']+)["\']',
  # textAreaInput labels
  textarea = 'textAreaInput\\([^,]+,\\s*["\']([^"\']+)["\']',
  # tabPanel labels
  tab_panel = 'tabPanel\\(["\']([^"\']+)["\']',
  # tags$strong
  strong = 'tags\\$strong\\(["\']([^"\']+)["\']',
  # tags$p
  tags_p = 'tags\\$p\\(["\']([^"\']+)["\']',
  # Direct quoted strings in div/span
  div_text = 'div\\([^)]*,\\s*["\']([^"\']+)["\']',
  span_text = 'span\\([^)]*,\\s*["\']([^"\']+)["\']'
)

# Manually extracted texts from scenario_builder_module.R
texts <- c(
  # Main headers
  "Scenario Builder",
  "Create and analyze what-if scenarios by modifying your CLD network.",

  # Warning messages
  "No CLD Network Found",
  "You need to create a Causal Loop Diagram first before building scenarios.",
  "Please go to the CLD Visualization module to create your network.",

  # Scenarios panel
  "Scenarios",
  "New Scenario",
  "No scenarios yet. Create one to get started.",

  # Tab names
  "Configure",
  "Impact Analysis",
  "Compare Scenarios",

  # Info message
  "Select a scenario from the list or create a new one to get started.",

  # Scenario list metadata
  "changes",

  # Create scenario dialog
  "Create New Scenario",
  "Cancel",
  "Create",
  "Scenario Name:",
  "e.g., Increased Fishing Pressure",
  "Description:",
  "Describe what this scenario represents...",
  "Scenario created successfully",

  # Delete scenario
  "Confirm Delete",
  "Are you sure you want to delete this scenario? This action cannot be undone.",
  "Delete",
  "Scenario deleted",

  # Configure tab
  "Configure: ",
  "Add/Modify Nodes",
  "Add New Node",
  "Remove Nodes",
  "Select node to remove:",
  "Remove Node",
  "Add/Modify Links",
  "Add New Link",
  "Remove Links",
  "Select link to remove:",
  "Remove Link",
  "Preview Network",
  "Run Impact Analysis",
  "Select...",
  "No modifications yet",

  # Add node dialog
  "Add New Node",
  "Add",
  "Node Label:",
  "e.g., New fishing regulation",
  "DAPSI(W)R(M) Category:",
  "Driver",
  "Activity",
  "Pressure",
  "State",
  "Impact",
  "Welfare",
  "Response",
  "Management",
  "Description:",
  "Node added to scenario",
  "Node marked for removal",

  # Add link dialog
  "Add New Link",
  "From Node:",
  "To Node:",
  "Polarity:",
  "Positive (+)",
  "Negative (-)",
  "Cannot create self-loop",
  "Link added to scenario",
  "Link marked for removal",

  # Impact Analysis tab
  "Impact Analysis: ",
  "Impact Analysis Not Run Yet",
  "Click 'Run Impact Analysis' in the Configure tab to analyze this scenario.",

  # Summary metrics
  "Total Nodes",
  "Total Links",
  "Feedback Loops",
  "Changed Nodes",

  # Impact analysis sections
  "Network Topology Changes",
  "Affected Feedback Loops",
  "Predicted Impacts",

  # Impact analysis progress
  "Running impact analysis...",
  "Analyzing network topology...",
  "Detecting feedback loops...",
  "Predicting impacts...",
  "Complete!",
  "Impact analysis complete",

  # Topology table
  "Metric",
  "Baseline",
  "Scenario",
  "Change",
  "Nodes",
  "Links",
  "Feedback Loops",

  # Affected loops
  "No feedback loops detected in this scenario.",
  "Loop (",
  " nodes)",
  "... and ",
  " more loops",

  # Impact predictions columns
  "node",
  "impact_magnitude",
  "impact_direction",
  "reason",
  "positive",
  "negative",
  "neutral",
  "New node added",
  "Connected to new links",
  "Indirect effect",

  # Compare Scenarios tab
  "Compare Scenarios",
  "Not Enough Scenarios",
  "You need at least 2 scenarios to compare. Create more scenarios to use this feature.",
  "Scenarios Not Analyzed",
  "Run impact analysis on at least 2 scenarios to compare them.",
  "Scenario A:",
  "Scenario B:",
  "Please select two different scenarios to compare.",

  # Comparison results
  "Network Statistics Comparison",
  "Nodes: ",
  "Links: ",
  "Loops: ",
  "Impact Comparison",
  "Node",
  " Impact",
  " Direction"
)

# Remove duplicates and empty strings
texts <- unique(texts[nchar(texts) > 0])

# Sort alphabetically for easier review
texts <- sort(texts)

# Print count
cat("Extracted", length(texts), "unique text strings\n\n")

# Write to JSON format for easy processing
library(jsonlite)

# Create a list of text objects ready for translation
text_objects <- lapply(texts, function(text) {
  list(
    en = text,
    es = "",
    fr = "",
    de = "",
    lt = "",
    pt = "",
    it = ""
  )
})

# Save as JSON
output_file <- "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny/scenario_builder_texts_to_translate.json"
write(toJSON(text_objects, pretty = TRUE, auto_unbox = TRUE), output_file)

cat("Saved text list to:", output_file, "\n")
cat("\nFirst 10 texts:\n")
print(head(texts, 10))
