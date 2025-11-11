# AI ISA Assistant Module i18n Implementation Plan

## Overview
Implementing internationalization for the AI ISA Assistant module (178 strings across 7 languages)

## Critical Navigation Bug Fix Required FIRST
**Lines 777-806**: Navigation logic currently compares translated strings - WILL BREAK with language switching

### SOLUTION: Add `title_key` field to QUESTION_FLOW

#### Step 1: Update QUESTION_FLOW structure (Lines 319-413)
Add `title_key` field to each step for safe conditional logic:

```r
QUESTION_FLOW <- list(
  list(
    step = 0,
    title_key = "welcome",  # NEW - for conditional logic
    title = i18n$t("Welcome & Introduction"),  # Translated
    question = i18n$t("Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?"),
    type = "text",
    target = "project_name"
  ),
  list(
    step = 1,
    title_key = "ecosystem",  # NEW
    title = i18n$t("Ecosystem Context"),
    question = i18n$t("Great! Now, what type of marine ecosystem are you studying?"),
    type = "select_with_other",
    target = "ecosystem",
    quick_options = c(
      i18n$t("Coastal waters"),
      i18n$t("Open ocean"),
      i18n$t("Estuaries"),
      i18n$t("Coral reefs"),
      i18n$t("Mangroves"),
      i18n$t("Seagrass beds"),
      i18n$t("Deep sea"),
      i18n$t("Other")
    )
  ),
  list(
    step = 2,
    title_key = "main_issue",  # NEW
    title = i18n$t("Main Issue Identification"),
    question = i18n$t("What is the main environmental or management issue you're addressing?"),
    type = "text",
    target = "main_issue"
  ),
  list(
    step = 3,
    title_key = "drivers",  # NEW
    title = i18n$t("Drivers - Societal Needs"),
    question = i18n$t("Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs? (e.g., Food security, Economic development, Recreation, Energy needs)"),
    type = "add_to_list",
    target = "Drivers",
    quick_options = c(
      i18n$t("Food security"),
      i18n$t("Economic development"),
      i18n$t("Recreation and tourism"),
      i18n$t("Energy needs"),
      i18n$t("Coastal protection"),
      i18n$t("Cultural heritage")
    )
  ),
  list(
    step = 4,
    title_key = "activities",  # NEW
    title = i18n$t("Activities - Human Actions"),
    question = i18n$t("Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area? (e.g., Fishing, Aquaculture, Shipping, Tourism)"),
    type = "add_to_list",
    target = "Activities",
    quick_options = c(
      i18n$t("Commercial fishing"),
      i18n$t("Recreational fishing"),
      i18n$t("Aquaculture"),
      i18n$t("Shipping/Transport"),
      i18n$t("Tourism"),
      i18n$t("Coastal development"),
      i18n$t("Renewable energy (wind/wave)"),
      i18n$t("Oil & gas extraction")
    )
  ),
  list(
    step = 5,
    title_key = "pressures",  # NEW
    title = i18n$t("Pressures - Environmental Stressors"),
    question = i18n$t("What PRESSURES do these activities put on the marine environment? (e.g., Overfishing, Pollution, Habitat destruction)"),
    type = "add_to_list",
    target = "Pressures",
    quick_options = c(
      i18n$t("Overfishing"),
      i18n$t("Bycatch"),
      i18n$t("Physical habitat damage"),
      i18n$t("Pollution (nutrients, chemicals)"),
      i18n$t("Noise pollution"),
      i18n$t("Marine litter/plastics"),
      i18n$t("Temperature changes"),
      i18n$t("Ocean acidification")
    )
  ),
  list(
    step = 6,
    title_key = "state_changes",  # NEW
    title = i18n$t("State Changes - Ecosystem Effects"),
    question = i18n$t("How do these pressures change the STATE of the marine ecosystem? (e.g., Declining fish stocks, Loss of biodiversity, Degraded water quality)"),
    type = "add_to_list",
    target = "State Changes",
    quick_options = c(
      i18n$t("Declining fish stocks"),
      i18n$t("Loss of biodiversity"),
      i18n$t("Habitat degradation"),
      i18n$t("Water quality decline"),
      i18n$t("Altered food webs"),
      i18n$t("Invasive species"),
      i18n$t("Loss of ecosystem resilience")
    )
  ),
  list(
    step = 7,
    title_key = "impacts",  # NEW
    title = i18n$t("Impacts - Effects on Ecosystem Services"),
    question = i18n$t("What are the IMPACTS on ecosystem services and benefits? How do these changes affect what the ocean provides? (e.g., Reduced fish catch, Loss of tourism revenue)"),
    type = "add_to_list",
    target = "Impacts",
    quick_options = c(
      i18n$t("Reduced fish catch"),
      i18n$t("Loss of tourism revenue"),
      i18n$t("Reduced coastal protection"),
      i18n$t("Loss of biodiversity value"),
      i18n$t("Reduced water quality for recreation"),
      i18n$t("Loss of cultural services")
    )
  ),
  list(
    step = 8,
    title_key = "welfare",  # NEW
    title = i18n$t("Welfare - Human Well-being Effects"),
    question = i18n$t("How do these impacts affect human WELFARE and well-being? (e.g., Loss of livelihoods, Health impacts, Reduced quality of life)"),
    type = "add_to_list",
    target = "Welfare",
    quick_options = c(
      i18n$t("Loss of livelihoods"),
      i18n$t("Food insecurity"),
      i18n$t("Economic losses"),
      i18n$t("Health impacts"),
      i18n$t("Loss of cultural identity"),
      i18n$t("Reduced quality of life"),
      i18n$t("Social conflicts")
    )
  ),
  list(
    step = 9,
    title_key = "responses",  # NEW
    title = i18n$t("Responses - Management Actions"),
    question = i18n$t("What RESPONSES or management actions are being taken (or could be taken) to address these issues? (e.g., Marine protected areas, Fishing quotas, Pollution regulations)"),
    type = "add_to_list",
    target = "Responses",
    quick_options = c(
      i18n$t("Marine protected areas (MPAs)"),
      i18n$t("Fishing quotas/limits"),
      i18n$t("Pollution regulations"),
      i18n$t("Habitat restoration"),
      i18n$t("Sustainable fishing practices"),
      i18n$t("Ecosystem-based management"),
      i18n$t("Stakeholder engagement"),
      i18n$t("Monitoring programs")
    )
  ),
  list(
    step = 10,
    title_key = "measures",  # NEW
    title = i18n$t("Measures - Policy Instruments"),
    question = i18n$t("Finally, what specific MEASURES or policy instruments support these responses? (e.g., Laws, Economic incentives, Education programs)"),
    type = "add_to_list",
    target = "Measures",
    quick_options = c(
      i18n$t("Environmental legislation"),
      i18n$t("Marine spatial planning"),
      i18n$t("Economic incentives (subsidies, taxes)"),
      i18n$t("Education and awareness programs"),
      i18n$t("Certification schemes (MSC, etc.)"),
      i18n$t("International agreements"),
      i18n$t("Monitoring and enforcement"),
      i18n$t("Research funding")
    )
  ),
  list(
    step = 11,
    title_key = "connection_review",  # NEW
    title = i18n$t("Connection Review"),
    question = i18n$t("Great! Now I'll suggest logical connections between the elements you've identified. These connections represent causal relationships in your social-ecological system. You can review and approve/reject each suggestion."),
    type = "connection_review",
    target = "connections"
  )
)
```

#### Step 2: Fix Navigation Logic (Lines 777-806)
Replace string comparisons with key comparisons:

```r
# BEFORE (BROKEN):
if (next_step$title == "Activities - Human Actions") {
  button_label <- "Continue to Activities"
  button_icon <- icon("arrow-right")
}

# AFTER (FIXED):
if (next_step$title_key == "activities") {
  button_label <- i18n$t("Continue to Activities")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "pressures") {
  button_label <- i18n$t("Continue to Pressures")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "state_changes") {
  button_label <- i18n$t("Continue to State Changes")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "impacts") {
  button_label <- i18n$t("Continue to Impacts")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "welfare") {
  button_label <- i18n$t("Continue to Welfare")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "responses") {
  button_label <- i18n$t("Continue to Responses")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "measures") {
  button_label <- i18n$t("Continue to Measures")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "connection_review") {
  button_label <- i18n$t("Finish")
  button_icon <- icon("check")
} else {
  button_label <- i18n$t("Continue")
  button_icon <- icon("arrow-right")
}
```

## Function Signature Updates

### Line 9: UI Function
```r
# BEFORE:
ai_isa_assistant_ui <- function(id) {

# AFTER:
ai_isa_assistant_ui <- function(id, i18n) {
```

### Line 287: Server Function
```r
# BEFORE:
ai_isa_assistant_server <- function(id, project_data_reactive) {

# AFTER:
ai_isa_assistant_server <- function(id, project_data_reactive, i18n) {
```

### Line 14: Remove Global i18n Reference
```r
# REMOVE this line (after adding i18n parameter):
shiny.i18n::usei18n(i18n)
```

## UI String Wrapping (Lines 178-280)

All static UI strings need i18n$t() wrapper:

```r
# Headers (Lines 178-179)
h3(i18n$t("AI-Assisted ISA Creation")),
p(i18n$t("Let me guide you step-by-step through building your DAPSI(W)R(M) model.")),

# Progress Panel (Lines 211-236)
h4(i18n$t("Your SES Model Progress")),
strong(i18n$t("Elements Created:")),
strong(i18n$t("Framework Flow:")),
strong(i18n$t("Current Framework:")),
tags$li(i18n$t("Drivers:"), textOutput(ns("drivers_count_display"), inline = TRUE)),
tags$li(i18n$t("Activities:"), textOutput(ns("activities_count_display"), inline = TRUE)),
tags$li(i18n$t("Pressures:"), textOutput(ns("pressures_count_display"), inline = TRUE)),
tags$li(i18n$t("State Changes:"), textOutput(ns("state_count_display"), inline = TRUE)),
tags$li(i18n$t("Impacts:"), textOutput(ns("impacts_count_display"), inline = TRUE)),
tags$li(i18n$t("Welfare:"), textOutput(ns("welfare_count_display"), inline = TRUE)),
tags$li(i18n$t("Responses:"), textOutput(ns("responses_count_display"), inline = TRUE)),
tags$li(i18n$t("Measures:"), textOutput(ns("measures_count_display"), inline = TRUE)),
p(strong(i18n$t("Total elements created")), ...)

# Session Management (Lines 241-276)
h4(i18n$t("Session Management")),
actionButton(ns("save_session"), i18n$t("Save Progress"), ...),
p(i18n$t("Save your current progress to browser storage"), ...),
actionButton(ns("load_session"), i18n$t("Load Saved"), ...),
p(i18n$t("Restore your last saved session"), ...),

# Main Buttons (Lines 262-276)
actionButton(ns("preview_model"), i18n$t("Preview Model"), ...),
actionButton(ns("save_to_isa"), i18n$t("Save to ISA Data Entry"), ...),
actionButton(ns("load_template"), i18n$t("Load Example Template"), ...),
actionButton(ns("start_over"), i18n$t("Start Over"), ...)
```

## Server Message Updates

### Dynamic Messages (Lines 456-2003)

#### Session Status Messages (Lines ~1200-1250)
```r
output$session_status <- renderUI({
  if (!is.null(input$last_saved)) {
    time_diff <- as.numeric(difftime(Sys.time(), input$last_saved, units = "secs"))
    if (time_diff < 60) {
      p(style = "color: green;",
        i18n$t("Auto-saved"), " ", round(time_diff), " ", i18n$t("seconds ago"))
    } else {
      p(style = "color: green;",
        i18n$t("Auto-saved"), " ", round(time_diff/60), " ", i18n$t("minutes ago"))
    }
  } else {
    p(style = "color: #999;", i18n$t("Not yet saved"))
  }
})
```

#### Notification Messages
```r
# Line ~1292
showNotification(i18n$t("Session saved successfully!"), type = "message")

# Line ~1439
showNotification(i18n$t("Session restored successfully!"), type = "message")

# Line ~1528
showNotification(i18n$t("No saved session found."), type = "warning")

# Lines ~1998-2000
showNotification(
  paste0(i18n$t("Model saved successfully!"), " ",
         total_elements, " ", i18n$t("elements and"), " ",
         total_connections, " ", i18n$t("connections transferred to ISA Data Entry.")),
  type = "message",
  duration = 5
)
```

#### AI Response Messages (Lines 755-757, 893, 905, 1081-1097)
```r
# Line 755-757
ai_message(i18n$t("Thank you! Moving to the next question..."))

# Lines 893, 905
ai_message(i18n$t("Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module."))

# Lines 1081-1097
paste0(
  i18n$t("I've identified"), " ", num_suggested, " ",
  i18n$t("potential connections based on the DAPSI(W)R(M) framework logic. Review each connection below and approve or reject them.")
)
```

#### Dynamic Feedback Messages
```r
# Success message after adding element
paste0(
  i18n$t("✓ Added"), " '", answer, "' (",
  element_count, " ", i18n$t(step_info$target), " ", i18n$t("total"), ")"
)

# Approval count message
paste0(
  i18n$t("Great! You've approved"), " ", approved_count, " ",
  i18n$t("connections out of"), " ", total_suggested, " ",
  i18n$t("suggested connections"), ". ",
  i18n$t("These connections will be included in your saved ISA data.")
)
```

### Modal Dialogs

#### Start Over Modal (Lines ~526-534)
```r
showModal(modalDialog(
  title = i18n$t("Confirm Start Over"),
  i18n$t("Are you sure you want to start over? All current progress will be lost."),
  footer = tagList(
    modalButton(i18n$t("Cancel")),
    actionButton(ns("confirm_start_over"), i18n$t("Yes, Start Over"),
                 class = "btn-danger")
  )
))
```

#### Load Template Modal (Lines ~1300-1353)
```r
showModal(modalDialog(
  title = i18n$t("Load Example Template"),
  p(i18n$t("Choose a pre-built scenario:")),
  actionButton(ns("load_overfishing"), i18n$t("Overfishing in Coastal Waters"), ...),
  actionButton(ns("load_pollution"), i18n$t("Marine Pollution & Plastics"), ...),
  actionButton(ns("load_tourism"), i18n$t("Coastal Tourism Impacts"), ...),
  actionButton(ns("load_climate"), i18n$t("Climate Change & Coral Reefs"), ...),
  footer = modalButton(i18n$t("Cancel"))
))
```

### Step Display (Lines ~663)
```r
output$step_display <- renderUI({
  if (current_step$step < length(QUESTION_FLOW)) {
    p(strong(paste0(i18n$t("Step"), " ", current_step$step, " ", i18n$t("of"), " ", length(QUESTION_FLOW) - 1)))
  } else {
    p(strong(i18n$t("Complete! Review your model")), style = "color: green;")
  }
})
```

### Connection Review UI (Lines ~616-627)
```r
h4(i18n$t("Review Suggested Connections")),
p(i18n$t("Approve or reject each connection. You can modify the strength and polarity if needed.")),
actionButton(ns("approve_all_connections"), i18n$t("Approve All"), ...),
actionButton(ns("finish_connections"), i18n$t("Finish & Continue"), ...),
p(i18n$t("No connections to review.")),
actionButton(ns("reject_connection"), i18n$t("Reject"), ...),
actionButton(ns("approve_connection"), i18n$t("Approve"), ...),
p(strong(i18n$t("All connections approved!")), ...)
```

### Input UI (Lines ~643, 692, 697)
```r
textInput(ns("user_input"), NULL,
          placeholder = i18n$t("Type your answer here...")),
actionButton(ns("submit_answer"), i18n$t("Submit Answer"), ...),
p(strong(i18n$t("Quick options (click to add):")))
```

### Navigation Button (Lines ~779-805)
```r
actionButton(ns("skip_question"), i18n$t("Skip This Question"), ...)
```

## App.R Updates

### UI Call (Find tabItem with tabName = "create_ses_ai")
```r
# BEFORE:
tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod"))

# AFTER:
tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod", i18n))
```

### Server Call (Find ai_isa_assistant_server call)
```r
# BEFORE:
ai_isa_assistant_server("ai_isa_mod", project_data)

# AFTER:
ai_isa_assistant_server("ai_isa_mod", project_data, i18n)
```

## Testing Checklist

After implementation:

1. [ ] Module loads without errors
2. [ ] Test language switching (all 7 languages)
3. [ ] Test QUESTION_FLOW progression through all steps
4. [ ] Test quick options in all languages
5. [ ] Test template loading (all 4 templates)
6. [ ] Test session save/restore
7. [ ] Test connection review UI
8. [ ] Verify dynamic messages display correctly
9. [ ] Test navigation logic doesn't break with language changes
10. [ ] Verify all 178 strings are translated properly

## Summary

- **Total Changes**: 178 i18n$t() wrappers + 2 function signatures + 1 critical bug fix
- **Critical Fix**: Add title_key field to prevent navigation logic breaking
- **Estimated Time**: 3-4 hours of implementation + 1 hour testing
- **Risk Level**: MEDIUM (navigation logic bug is critical, must be fixed first)
