# AI ISA Assistant Module - Internationalization Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing internationalization in the AI ISA Assistant module after translations are generated.

## Pre-requisites
- ✅ 178 strings extracted
- ⏳ Translations generated (ai_isa_assistant_translations.json)
- ⏳ Translations merged into translation.json

## Implementation Steps

### Step 1: Update Function Signatures

**File:** `modules/ai_isa_assistant_module.R`

**Change 1 - UI Function (Line 9):**
```r
# Before:
ai_isa_assistant_ui <- function(id) {

# After:
ai_isa_assistant_ui <- function(id, i18n) {
```

**Change 2 - Server Function (Line 287):**
```r
# Before:
ai_isa_assistant_server <- function(id, project_data_reactive) {

# After:
ai_isa_assistant_server <- function(id, project_data_reactive, i18n) {
```

**Change 3 - Remove Global i18n Reference (Line 14):**
```r
# Remove or comment out:
shiny.i18n::usei18n(i18n)
# This line assumes global i18n object, which we're now passing as parameter
```

---

### Step 2: Update UI Section (Lines 178-280)

**Pattern:** Wrap all static text with `i18n$t()`

#### Headers (Lines 178-179):
```r
# Before:
h2(icon("robot"), " AI-Assisted ISA Creation"),
p(class = "lead", "Let me guide you step-by-step through building your DAPSI(W)R(M) model.")

# After:
h2(icon("robot"), paste0(" ", i18n$t("AI-Assisted ISA Creation"))),
p(class = "lead", i18n$t("Let me guide you step-by-step through building your DAPSI(W)R(M) model."))
```

#### Box Title (Line 211):
```r
# Before:
title = "Your SES Model Progress",

# After:
title = i18n$t("Your SES Model Progress"),
```

#### Progress Panel Labels (Lines 217-236):
```r
# Before:
h4(icon("chart-line"), " Elements Created:"),
h4(icon("sitemap"), " Framework Flow:"),
h4(icon("network-wired"), " Current Framework:"),
tags$li(strong("Drivers: "), textOutput(ns("count_drivers"), inline = TRUE)),
tags$li(strong("Activities: "), textOutput(ns("count_activities"), inline = TRUE)),
# ... etc

# After:
h4(icon("chart-line"), paste0(" ", i18n$t("Elements Created:"))),
h4(icon("sitemap"), paste0(" ", i18n$t("Framework Flow:"))),
h4(icon("network-wired"), paste0(" ", i18n$t("Current Framework:"))),
tags$li(strong(paste0(i18n$t("Drivers:"), " ")), textOutput(ns("count_drivers"), inline = TRUE)),
tags$li(strong(paste0(i18n$t("Activities:"), " ")), textOutput(ns("count_activities"), inline = TRUE)),
# ... repeat for all 8 framework elements
```

#### Session Management (Lines 241-276):
```r
# Before:
h5(icon("database"), " Session Management"),
actionButton(ns("manual_save"), "Save Progress",
            icon = icon("save"),
            title = "Save your current progress to browser storage"),
actionButton(ns("load_session"), "Load Saved",
            icon = icon("folder-open"),
            title = "Restore your last saved session"),
actionButton(ns("preview_model"), "Preview Model",
            icon = icon("eye")),
actionButton(ns("save_to_isa"), "Save to ISA Data Entry",
            icon = icon("save")),
actionButton(ns("load_template"), "Load Example Template",
            icon = icon("file-import")),
actionButton(ns("start_over"), "Start Over",
            icon = icon("redo"))

# After:
h5(icon("database"), paste0(" ", i18n$t("Session Management"))),
actionButton(ns("manual_save"), i18n$t("Save Progress"),
            icon = icon("save"),
            title = i18n$t("Save your current progress to browser storage")),
actionButton(ns("load_session"), i18n$t("Load Saved"),
            icon = icon("folder-open"),
            title = i18n$t("Restore your last saved session")),
actionButton(ns("preview_model"), i18n$t("Preview Model"),
            icon = icon("eye")),
actionButton(ns("save_to_isa"), i18n$t("Save to ISA Data Entry"),
            icon = icon("save")),
actionButton(ns("load_template"), i18n$t("Load Example Template"),
            icon = icon("file-import")),
actionButton(ns("start_over"), i18n$t("Start Over"),
            icon = icon("redo"))
```

---

### Step 3: Update QUESTION_FLOW (Lines 319-413)

**Critical:** This section needs careful handling as titles are used for conditional navigation logic.

#### Add title_key field for safer navigation:
```r
# Pattern:
list(
  step = 0,
  title_key = "welcome_intro",  # NEW: Use for navigation logic
  title = i18n$t("Welcome & Introduction"),
  question = i18n$t("Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?"),
  type = "text",
  target = "project_name"
)
```

#### Full QUESTION_FLOW update:
```r
QUESTION_FLOW <- list(
  list(
    step = 0,
    title_key = "welcome_intro",
    title = i18n$t("Welcome & Introduction"),
    question = i18n$t("Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?"),
    type = "text",
    target = "project_name"
  ),
  list(
    step = 1,
    title_key = "ecosystem_context",
    title = i18n$t("Ecosystem Context"),
    question = i18n$t("Great! Now, what type of marine ecosystem are you studying?"),
    type = "choice",
    options = c(
      i18n$t("Coastal waters"),
      i18n$t("Open ocean"),
      i18n$t("Estuaries"),
      i18n$t("Coral reefs"),
      i18n$t("Mangroves"),
      i18n$t("Seagrass beds"),
      i18n$t("Deep sea"),
      i18n$t("Other")
    ),
    target = "ecosystem_type"
  ),
  list(
    step = 2,
    title_key = "main_issue",
    title = i18n$t("Main Issue Identification"),
    question = i18n$t("What is the main environmental or management issue you're addressing?"),
    type = "text",
    target = "main_issue"
  ),
  list(
    step = 3,
    title_key = "drivers",
    title = i18n$t("Drivers - Societal Needs"),
    question = i18n$t("Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs? (e.g., Food security, Economic development, Recreation, Energy needs)"),
    type = "multiple",
    target = "drivers",
    examples = c(
      i18n$t("Food security"),
      i18n$t("Economic development"),
      i18n$t("Recreation and tourism"),
      i18n$t("Energy needs"),
      i18n$t("Coastal protection"),
      i18n$t("Cultural heritage")
    )
  ),
  # ... Continue for all 12 steps
  # Use title_key values: "activities", "pressures", "states", "impacts", "welfare", "responses", "measures", "connection_review"
)
```

---

### Step 4: Update Navigation Logic (Lines 777-806)

**Critical Fix:** Use title_key instead of translated title for comparisons

```r
# Before:
if (next_step$title == "Activities - Human Actions") {
  button_label <- "Continue to Activities"
  button_icon <- icon("arrow-right")
} else if (next_step$title == "Pressures - Environmental Stressors") {
  button_label <- "Continue to Pressures"
  # ... etc

# After:
if (next_step$title_key == "activities") {
  button_label <- i18n$t("Continue to Activities")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "pressures") {
  button_label <- i18n$t("Continue to Pressures")
  button_icon <- icon("arrow-right")
} else if (next_step$title_key == "states") {
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
} else {
  button_label <- i18n$t("Continue")
  button_icon <- icon("arrow-right")
}
# Default for last step
button_label <- i18n$t("Skip This Question")
button_label <- i18n$t("Finish")
```

---

### Step 5: Update Server Messages (Lines 456-2003)

#### Session Management (Lines 456, 492, 496, 508, 539, 559):
```r
# Line 456:
showNotification(i18n$t("Session restored successfully!"), type = "message", duration = 3)

# Lines 486-493:
time_text <- if (time_diff < 60) {
  paste0(round(time_diff), " ", i18n$t("seconds ago"))
} else {
  paste0(round(time_diff / 60), " ", i18n$t("minutes ago"))
}
div(class = "save-status",
  icon("check-circle"), paste0(" ", i18n$t("Auto-saved"), " ", time_text)
)

# Line 496:
icon("exclamation-triangle"), paste0(" ", i18n$t("Not yet saved"))

# Line 508:
showNotification(i18n$t("Session saved successfully!"), type = "message", duration = 3)

# Line 539:
showNotification(i18n$t("No saved session found."), type = "warning", duration = 3)

# Lines 558-559:
showNotification(
  i18n$t("A previous session was found. Click 'Load Saved' to restore it."),
  type = "message", duration = 5
)
```

#### Step Navigation (Lines 570, 572):
```r
# Line 570:
HTML(paste0("<h4>", i18n$t("Step"), " ", rv$current_step + 1, " ", i18n$t("of"), " ", length(QUESTION_FLOW), ": ", step_info$title, "</h4>"))

# Line 572:
HTML(paste0("<h4>", i18n$t("Complete! Review your model"), "</h4>"))
```

#### Connection Review UI (Lines 616-747):
```r
# Lines 616-617:
h4(icon("link"), paste0(" ", i18n$t("Review Suggested Connections"))),
p(i18n$t("Approve or reject each connection. You can modify the strength and polarity if needed.")),

# Lines 622, 627:
actionButton(session$ns("approve_all_connections"), i18n$t("Approve All"),
actionButton(session$ns("finish_connections"), i18n$t("Finish & Continue"),

# Lines 638, 643:
placeholder = i18n$t("Type your answer here..."),
actionButton(session$ns("submit_answer"), i18n$t("Submit Answer"),

# Line 663:
return(p(i18n$t("No connections to review.")))

# Lines 692, 697:
i18n$t("Reject")
i18n$t("Approve")

# Line 747:
showNotification(i18n$t("All connections approved!"), type = "message")
```

#### Quick Options (Line 821):
```r
# Line 821:
h5(i18n$t("Quick options (click to add):"))
```

#### Modal Dialogs (Lines 526-534, 1300-1353):
```r
# Lines 526-534:
showModal(modalDialog(
  title = i18n$t("Restore Previous Session?"),
  paste0(i18n$t("Found a saved session from"), " ",
         format(as.POSIXct(input$loaded_session_data$timestamp), "%Y-%m-%d %H:%M:%S"),
         ". ", i18n$t("Do you want to restore it?")),
  footer = tagList(
    actionButton(session$ns("confirm_load"), i18n$t("Yes, Restore"), class = "btn-primary"),
    modalButton(i18n$t("Cancel"))
  )
))

# Lines 1300-1307:
showModal(modalDialog(
  title = i18n$t("Confirm Start Over"),
  i18n$t("Are you sure you want to start over? All current progress will be lost."),
  footer = tagList(
    modalButton(i18n$t("Cancel")),
    actionButton(session$ns("confirm_start_over"), i18n$t("Yes, Start Over"), class = "btn-danger")
  )
))

# Lines 1329-1353:
showModal(modalDialog(
  title = i18n$t("Load Example Template"),
  h4(i18n$t("Choose a pre-built scenario:")),
  fluidRow(
    column(6, actionButton(session$ns("template_overfishing"),
           i18n$t("Overfishing in Coastal Waters"),
           class = "btn-primary btn-block", style = "margin: 5px;")),
    column(6, actionButton(session$ns("template_pollution"),
           i18n$t("Marine Pollution & Plastics"),
           class = "btn-primary btn-block", style = "margin: 5px;"))
  ),
  fluidRow(
    column(6, actionButton(session$ns("template_tourism"),
           i18n$t("Coastal Tourism Impacts"),
           class = "btn-primary btn-block", style = "margin: 5px;")),
    column(6, actionButton(session$ns("template_climate"),
           i18n$t("Climate Change & Coral Reefs"),
           class = "btn-primary btn-block", style = "margin: 5px;"))
  ),
  footer = modalButton(i18n$t("Cancel"))
))
```

#### Total Elements Display (Line 1123):
```r
# Line 1123:
p(style = "text-align: center;", i18n$t("Total elements created"))
```

#### Notifications (Lines 1292, 1439, 1528, 1614, 1702, 1998-2000):
```r
# Line 1292:
showNotification(i18n$t("Model saved! Navigate to 'ISA Data Entry' to see your elements."),
                 type = "message", duration = 5)

# Line 1439:
showNotification(i18n$t("Overfishing template loaded with example connections! You can now preview or modify it."),
                 type = "message", duration = 5)

# Lines 1998-2000:
showNotification(
  paste0(i18n$t("Model saved successfully!"), " ", total_elements, " ",
         i18n$t("elements and"), " ", n_connections, " ",
         i18n$t("connections transferred to ISA Data Entry.")),
  type = "message", duration = 5
)
```

#### Dynamic AI Messages (Lines 755-757, 893, 905, 1081-1097):
```r
# Lines 755-757:
message = paste0(i18n$t("Great! You've approved"), " ", approved_count, " ",
                 i18n$t("connections out of"), " ", length(rv$suggested_connections), " ",
                 i18n$t("suggested connections"), ". ",
                 i18n$t("These connections will be included in your saved ISA data."))

# Line 893:
ai_response <- paste0("✓ ", i18n$t("Added"), " '", answer, "' (", element_count, " ",
                      step_info$target, " ", i18n$t("total"), "). ",
                      i18n$t("Click quick options to add more, or click the green button to continue."))

# Line 905:
list(type = "ai", message = i18n$t("Thank you! Moving to the next question..."), timestamp = Sys.time())

# Lines 1081-1086:
message <- paste0(next_step$question, " ", i18n$t("I've identified"), " ", conn_count, " ",
                  i18n$t("potential connections based on the DAPSI(W)R(M) framework logic. Review each connection below and approve or reject them."))

# Line 1097:
message = i18n$t("Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module.")
```

---

### Step 6: Update app.R

**File:** `app.R`

**Change 1 - UI Call (around line 350):**
```r
# Find the line that calls ai_isa_assistant_ui
# Before:
tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod"))

# After:
tabItem(tabName = "create_ses_ai", ai_isa_assistant_ui("ai_isa_mod", i18n))
```

**Change 2 - Server Call (around line 980):**
```r
# Find the line that calls ai_isa_assistant_server
# Before:
ai_isa_assistant_server("ai_isa_mod", project_data)

# After:
ai_isa_assistant_server("ai_isa_mod", project_data, i18n)
```

---

## Testing Checklist

After implementation, test the following:

### Module Loading
- [ ] Module loads without errors
- [ ] No missing translation warnings
- [ ] UI renders correctly

### Language Switching
- [ ] Test English
- [ ] Test Spanish
- [ ] Test French
- [ ] Test German
- [ ] Test Lithuanian
- [ ] Test Portuguese
- [ ] Test Italian

### Functionality
- [ ] Question flow works
- [ ] Quick options display correctly
- [ ] Step navigation works
- [ ] Session save/restore works
- [ ] Template loading works (all 4 templates)
- [ ] Connection review works
- [ ] Save to ISA Data Entry works

### Edge Cases
- [ ] Long questions display properly in all languages
- [ ] Dynamic messages with variables work
- [ ] Modal dialogs display correctly
- [ ] Notifications appear in correct language

---

## Troubleshooting

### Issue: Missing translations warning
**Solution:** Check that all strings in the code match exactly with translation keys in translation.json

### Issue: Broken navigation logic
**Solution:** Verify title_key comparisons instead of translated title comparisons (Lines 777-806)

### Issue: selectInput errors
**Solution:** Ensure options arrays are properly translated with i18n$t() wrapping each option

### Issue: Dynamic messages incomplete
**Solution:** Check paste0() calls include all i18n$t() wrappers for text fragments

---

## Summary

- **Total Changes:** ~200+ i18n$t() calls
- **Files Modified:** 2 (ai_isa_assistant_module.R, app.R)
- **Critical Sections:** QUESTION_FLOW structure, navigation logic
- **Estimated Time:** 2-3 hours for implementation + 1 hour testing
