# i18n Developer Quick Reference

**Fast reference for internationalization in MarineSABRES SES Toolbox**

---

## The Three Golden Rules

1. **✅ ALWAYS use `i18n$t()` for user-facing text**
2. **✅ ALWAYS add `usei18n(i18n)` to module UI functions**
3. **✅ ALWAYS run i18n tests before committing**

---

## Essential Patterns

### Module UI Setup
```r
myModuleUI <- function(id, i18n) {
  shiny.i18n::usei18n(i18n)  # ← REQUIRED FIRST LINE
  ns <- NS(id)
  # ... rest of UI
}
```

### UI Elements
```r
# Headers
h4(i18n$t("Section Title"))

# Text inputs
textInput(ns("field"), i18n$t("Label:"),
         placeholder = i18n$t("Hint text"))

# Select inputs
selectInput(ns("type"), i18n$t("Choose:"),
           choices = c("", i18n$t("Option 1"), i18n$t("Option 2")))

# Buttons
actionButton(ns("save"), i18n$t("Save"))

# Paragraphs
p(i18n$t("Explanation text here."))
```

### Notifications
```r
# Simple
showNotification(i18n$t("Success message"), type = "message")

# With dynamic content
showNotification(
  paste(i18n$t("Saved"), n, i18n$t("items")),
  type = "message"
)

# Error with details
showNotification(
  paste(i18n$t("Error:"), error_msg),
  type = "error"
)
```

### Modals
```r
showModal(modalDialog(
  title = i18n$t("Dialog Title"),
  p(i18n$t("Message text")),
  footer = modalButton(i18n$t("OK"))
))
```

### Plots
```r
plot(x, y,
     main = i18n$t("Chart Title"),
     xlab = i18n$t("X Label"),
     ylab = i18n$t("Y Label"))

barplot(data,
        names.arg = c(i18n$t("Cat 1"), i18n$t("Cat 2")))
```

### RenderText
```r
output$status <- renderText({
  paste(i18n$t("Total:"), count)
})
```

---

## What NOT to Translate

```r
# ❌ DON'T translate these:

# IDs
ns("field_id")  # Keep as-is

# File paths
"data/file.csv"  # Keep as-is

# Log messages
log_message("[DEBUG] Info", "INFO")  # Keep as-is

# Column names (internal data)
df$column_name  # Keep as-is

# Technical R errors (but DO translate the prefix!)
paste(i18n$t("Error:"), e$message)  # ← Prefix i18n, error not
```

---

## Adding Translation Keys

### 1. Choose the right file:
- **Common messages**: `translations/common/messages.json`
- **Validation**: `translations/common/validation.json`
- **Labels**: `translations/common/labels.json`
- **Module-specific**: `translations/modules/[name].json`

### 2. Use the tool:
```bash
Rscript scripts/add_translation.R
```

### 3. Format (all 7 languages):
```json
{
  "key": "Your text here",
  "en": "Your text here",
  "es": "Your text here",
  "fr": "Your text here",
  "de": "Your text here",
  "lt": "Your text here",
  "pt": "Your text here",
  "it": "Your text here"
}
```

---

## Testing

### Before committing:
```r
# Run i18n enforcement tests
testthat::test_file("tests/testthat/test-i18n-enforcement.R")
```

### Tests will catch:
- ✅ Missing `usei18n(i18n)` calls
- ✅ Hardcoded strings
- ✅ Missing translation keys
- ✅ Malformed JSON

---

## Common Mistakes

### ❌ Mistake: No usei18n()
```r
myModuleUI <- function(id, i18n) {
  ns <- NS(id)  # ← Missing usei18n(i18n)!
  ...
}
```

### ✅ Fix:
```r
myModuleUI <- function(id, i18n) {
  shiny.i18n::usei18n(i18n)  # ← Add this!
  ns <- NS(id)
  ...
}
```

---

### ❌ Mistake: Hardcoded string
```r
h4("My Title")  # ← Hardcoded!
```

### ✅ Fix:
```r
h4(i18n$t("My Title"))  # ← Wrapped in i18n$t()
```

---

### ❌ Mistake: Partial translation
```r
paste(i18n$t("Found"), n, "errors")  # ← "errors" not translated!
```

### ✅ Fix:
```r
paste(i18n$t("Found"), n, i18n$t("errors"))  # ← All parts translated
```

---

## Quick Checklist

Before submitting code:

- [ ] Added `usei18n(i18n)` to new UI functions?
- [ ] All user-visible text wrapped in `i18n$t()`?
- [ ] Translation keys added to appropriate JSON files?
- [ ] All 7 languages have entries?
- [ ] i18n enforcement tests pass?
- [ ] Tested in at least 2 languages?

---

## Help

- **Full guide**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Translation workflow**: See [TRANSLATION_WORKFLOW_GUIDE.md](TRANSLATION_WORKFLOW_GUIDE.md)
- **Examples**: Check `modules/pims_stakeholder_module.R`

---

**7 Languages Supported**: en, es, fr, de, lt, pt, it 🌍
