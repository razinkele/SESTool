# Contributing to MarineSABRES SES Toolbox

Thank you for your interest in contributing to the MarineSABRES Social-Ecological Systems (SES) Toolbox! This document provides guidelines for contributing to the project, with a strong focus on maintaining our internationalization (i18n) standards.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Internationalization (i18n) Requirements](#internationalization-i18n-requirements)
4. [Development Guidelines](#development-guidelines)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Additional Resources](#additional-resources)

---

## Code of Conduct

This project is part of the Marine-SABRES initiative focused on marine ecosystem research and stakeholder engagement. We expect all contributors to:

- Be respectful and inclusive
- Focus on constructive collaboration
- Prioritize scientific rigor and accessibility
- Support multilingual and international participation

---

## Getting Started

### Prerequisites

```r
# Required R packages
install.packages(c(
  "shiny",
  "shiny.i18n",
  "jsonlite",
  "DT",
  "igraph",
  "openxlsx",
  "testthat"
))
```

### Development Setup

1. Fork and clone the repository
2. Review existing code structure
3. Read the translation documentation (see [Additional Resources](#additional-resources))
4. Run the test suite to ensure everything works: `Rscript -e "testthat::test_dir('tests/testthat')"`

---

## Internationalization (i18n) Requirements

**CRITICAL**: This application supports 7 languages (English, Spanish, French, German, Lithuanian, Portuguese, Italian). All user-facing text MUST be internationalized.

### Core Principles

1. **NO HARDCODED STRINGS**: Never use hardcoded English (or any language) strings in user-facing code
2. **ALWAYS USE i18n$t()**: Wrap ALL user-visible text with the translation function
3. **USE usei18n()**: Every module UI function must call `shiny.i18n::usei18n(i18n)` to enable reactive translations
4. **MAINTAIN CONSISTENCY**: Follow established patterns throughout the codebase

### Required i18n Patterns

#### 1. Module UI Functions

**REQUIRED**: Add `usei18n(i18n)` at the start of every module UI function:

```r
# ✅ CORRECT
myModuleUI <- function(id, i18n) {
  shiny.i18n::usei18n(i18n)  # REQUIRED - enables reactive translations
  ns <- NS(id)

  tagList(
    h4(i18n$t("Module Title")),
    p(i18n$t("Description text"))
  )
}

# ❌ WRONG - Missing usei18n()
myModuleUI <- function(id, i18n) {
  ns <- NS(id)
  tagList(
    h4("Module Title"),  # Also wrong - hardcoded string
    p("Description text")
  )
}
```

#### 2. UI Elements

**All UI elements must use i18n$t():**

```r
# ✅ CORRECT
textInput(ns("field"), i18n$t("Field Label:"),
         placeholder = i18n$t("Enter value here"))

selectInput(ns("type"), i18n$t("Select Type:"),
           choices = c("", i18n$t("Option 1"), i18n$t("Option 2")))

actionButton(ns("save"), i18n$t("Save"), icon = icon("save"))

h4(i18n$t("Section Header"))
p(i18n$t("Explanatory paragraph text"))

# ❌ WRONG
textInput(ns("field"), "Field Label:", placeholder = "Enter value here")
selectInput(ns("type"), "Select Type:", choices = c("", "Option 1", "Option 2"))
actionButton(ns("save"), "Save")
h4("Section Header")
```

#### 3. Notifications and Messages

**All showNotification calls must use i18n$t():**

```r
# ✅ CORRECT - Simple message
showNotification(i18n$t("Data saved successfully!"), type = "message")

# ✅ CORRECT - Message with dynamic content
showNotification(
  paste(i18n$t("Saved"), nrow(data), i18n$t("records")),
  type = "message"
)

# ✅ CORRECT - Error message with details
showNotification(
  paste(i18n$t("Error:"), error_message),
  type = "error"
)

# ❌ WRONG
showNotification("Data saved successfully!", type = "message")
showNotification(paste("Saved", nrow(data), "records"))
```

#### 4. Validation and Error Messages

```r
# ✅ CORRECT - Modal dialog
showModal(modalDialog(
  title = tags$div(icon("warning"), i18n$t(" Validation Errors")),
  tags$div(
    tags$p(strong(i18n$t("Please fix the following issues:"))),
    tags$ul(lapply(errors, function(e) tags$li(e)))
  ),
  footer = modalButton(i18n$t("OK"))
))

# ✅ CORRECT - Validation warning
if (invalid) {
  showNotification(
    i18n$t("Please add at least one valid entry."),
    type = "warning"
  )
}

# ❌ WRONG
showModal(modalDialog(
  title = "Validation Errors",
  tags$p("Please fix the following issues:"),
  footer = modalButton("OK")
))
```

#### 5. renderText and Plot Labels

```r
# ✅ CORRECT - RenderText
output$status <- renderText({
  paste(i18n$t("Total records:"), nrow(data))
})

# ✅ CORRECT - Plot labels
plot(x, y,
     main = i18n$t("Scatter Plot"),
     xlab = i18n$t("X Axis Label"),
     ylab = i18n$t("Y Axis Label"))

barplot(values,
        names.arg = c(i18n$t("Category 1"), i18n$t("Category 2")),
        main = i18n$t("Bar Chart Title"))

# ❌ WRONG
output$status <- renderText(paste("Total records:", nrow(data)))
plot(x, y, main = "Scatter Plot", xlab = "X Axis", ylab = "Y Axis")
```

### Translation File Organization

#### File Structure

```
translations/
├── _framework.json       # Framework-level configuration
├── _glossary.json        # Project glossary
├── common/
│   ├── buttons.json      # Common button labels
│   ├── labels.json       # General labels and terms
│   ├── messages.json     # User feedback messages
│   ├── navigation.json   # Navigation elements
│   └── validation.json   # Validation messages
├── ui/
│   ├── header.json       # App header elements
│   ├── modals.json       # Modal dialog text
│   └── sidebar.json      # Sidebar navigation
├── data/
│   └── node_types.json   # Data type classifications
└── modules/
    └── [module_name].json # Module-specific translations
```

#### Adding Translation Keys

**When adding new user-facing text:**

1. **Use descriptive English text as the key**:
   ```r
   i18n$t("Please enter a valid email address")
   ```

2. **Add the key to the appropriate translation file**:
   - **Common messages**: `translations/common/messages.json`
   - **Validation errors**: `translations/common/validation.json`
   - **UI labels**: `translations/common/labels.json`
   - **Module-specific**: `translations/modules/[module_name].json`

3. **Use the translation workflow tools**:
   ```bash
   # Interactive mode
   Rscript scripts/add_translation.R

   # Or use workflow manager
   Rscript scripts/translation_workflow.R add
   ```

4. **Ensure all 7 languages are present**:
   ```json
   {
     "key": "Please enter a valid email address",
     "en": "Please enter a valid email address",
     "es": "Please enter a valid email address",
     "fr": "Please enter a valid email address",
     "de": "Please enter a valid email address",
     "lt": "Please enter a valid email address",
     "pt": "Please enter a valid email address",
     "it": "Please enter a valid email address"
   }
   ```
   *Note: Initially, all languages can have the English text - professional translation comes later*

### What NOT to Translate

**DO NOT wrap these with i18n$t():**

1. **Technical IDs and keys**: `ns("field_id")`, column names in data frames
2. **File paths**: `"data/file.csv"`
3. **Log messages**: `cat("[DEBUG] Processing data\n")`
4. **Internal variable names**: Internal R object names
5. **Code comments**: R comments are not user-facing
6. **API endpoints**: URLs and API paths
7. **Technical error details**: R error messages for debugging (but DO translate the user-facing prefix)

```r
# ✅ CORRECT - Technical details not translated
showNotification(
  paste(i18n$t("Error loading data:"), e$message),  # Prefix translated, R error preserved
  type = "error"
)

log_message(paste("Data loaded:", nrow(df), "rows"), "INFO")  # Log not translated

# ✅ CORRECT - Internal IDs not translated
textInput(ns("email_field"), i18n$t("Email Address:"))
```

### i18n Testing Requirements

**Before submitting a pull request:**

1. **Run i18n enforcement tests**:
   ```r
   # R
   testthat::test_file("tests/testthat/test-i18n-enforcement.R")
   ```

2. **Check for hardcoded strings**:
   The enforcement tests will automatically detect:
   - Missing `usei18n(i18n)` calls
   - Hardcoded strings in `showNotification()`
   - Non-internationalized UI elements
   - Missing translation keys

3. **Verify in multiple languages**:
   - Test your feature in at least 2 languages
   - Use the language selector in the app
   - Confirm reactive translations work (UI updates without page reload)

---

## Development Guidelines

### Code Style

1. **Consistent Formatting**:
   - Use 2-space indentation
   - Clear, descriptive variable names
   - Add comments for complex logic

2. **Modular Code**:
   - Use Shiny modules for all major features
   - Keep functions focused and single-purpose
   - Follow the module pattern: `moduleUI()` and `moduleServer()`

3. **Standard Module Signatures**:
   To ensure consistency across all modules, follow this standard signature pattern:

   ```r
   # UI Function - Standard Pattern
   module_name_ui <- function(id, i18n) {
     ns <- NS(id)
     # Use snake_case for function names
     # Always accept i18n for translations
   }

   # Server Function - Standard Pattern
   module_name_server <- function(id, project_data, session, i18n,
                                   event_bus = NULL, ...) {
     moduleServer(id, function(input, output, session) {
       # Module logic here
     })
   }
   ```

   **Parameter Order** (in order of importance):
   1. `id` - Module namespace ID (required)
   2. `project_data` - Reactive project data (required for data modules)
   3. `session` - Parent session for navigation (when needed)
   4. `i18n` - Translation object (required for UI text)
   5. `event_bus` - Event bus for inter-module communication (optional)
   6. Additional optional parameters with defaults

   **Naming Conventions**:
   - Use `snake_case` for all function names: `module_name_server()`
   - Avoid `camelCase`: ~~`moduleNameServer()`~~
   - UI suffix: `_ui`, Server suffix: `_server`

4. **Error Handling**:
   - Always use `tryCatch()` for operations that might fail
   - Provide clear, internationalized error messages to users
   - Log technical details for debugging

### File Organization

- **modules/**: Shiny module files (`*_module.R`)
- **functions/**: Utility functions and helpers
- **translations/**: All translation JSON files
- **tests/testthat/**: Test files (`test-*.R`)
- **scripts/**: Standalone scripts for workflows

### Documentation

1. **Code Comments**:
   - Document function purposes and parameters
   - Explain complex algorithms
   - Note any known limitations

2. **User-Facing Help**:
   - All help text must be internationalized
   - Use the `create_help_observer()` helper
   - Provide clear, concise guidance

---

## Testing Requirements

### Required Tests

All contributions must include appropriate tests:

1. **Functionality Tests**:
   ```r
   test_that("feature works correctly", {
     # Your test code
     expect_equal(result, expected)
   })
   ```

2. **i18n Enforcement Tests**:
   - Automatically run when you test
   - Will fail if hardcoded strings are found
   - Ensures translation key existence

3. **Integration Tests**:
   - Test module interactions
   - Verify data flow between components

### Running Tests

```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test file
testthat::test_file("tests/testthat/test-i18n-enforcement.R")

# Run translation validation
source("scripts/translation_workflow.R")
validate_all_translations()
```

### Expected Test Results

- ✅ All tests should pass
- ✅ 0 hardcoded strings detected
- ✅ All translation keys exist
- ✅ No JSON parsing errors

---

## Pull Request Process

### Before Submitting

1. **Update your fork**:
   ```bash
   git fetch upstream
   git merge upstream/main
   ```

2. **Run all tests**:
   ```r
   testthat::test_dir("tests/testthat")
   ```

3. **Check i18n compliance**:
   ```r
   testthat::test_file("tests/testthat/test-i18n-enforcement.R")
   ```

4. **Validate translations**:
   ```bash
   Rscript scripts/translation_workflow.R check
   ```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] i18n/Translation update

## i18n Checklist
- [ ] All user-facing text uses i18n$t()
- [ ] usei18n(i18n) added to new UI functions
- [ ] Translation keys added to appropriate files
- [ ] All 7 languages have entries
- [ ] i18n enforcement tests pass

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new features
- [ ] Tested in at least 2 languages
- [ ] No console errors or warnings

## Screenshots (if applicable)
Attach screenshots showing the feature in different languages
```

### Review Process

1. **Automated Checks**: CI/CD will run tests automatically
2. **i18n Review**: Maintainers will verify internationalization
3. **Code Review**: Technical review of implementation
4. **Translation Review**: Check translation key appropriateness
5. **Approval**: At least one maintainer approval required

---

## Common i18n Mistakes to Avoid

### ❌ Mistake 1: Hardcoded Strings
```r
# WRONG
h4("Welcome to the Application")
showNotification("Data saved successfully")
```

### ✅ Correct:
```r
h4(i18n$t("Welcome to the Application"))
showNotification(i18n$t("Data saved successfully"))
```

---

### ❌ Mistake 2: Missing usei18n()
```r
# WRONG - UI won't update when language changes
myModuleUI <- function(id, i18n) {
  ns <- NS(id)
  tagList(h4(i18n$t("Title")))
}
```

### ✅ Correct:
```r
myModuleUI <- function(id, i18n) {
  shiny.i18n::usei18n(i18n)  # CRITICAL - must be first
  ns <- NS(id)
  tagList(h4(i18n$t("Title")))
}
```

---

### ❌ Mistake 3: Translating Technical Content
```r
# WRONG - Don't translate IDs, file paths, or R errors
textInput(ns(i18n$t("email")), i18n$t("Email:"))
read.csv(i18n$t("data/file.csv"))
log_message(i18n$t("[DEBUG] Processing"), "INFO")
```

### ✅ Correct:
```r
textInput(ns("email"), i18n$t("Email:"))  # Only label translated
read.csv("data/file.csv")  # File path not translated
log_message("[DEBUG] Processing", "INFO")  # Logs not translated
```

---

### ❌ Mistake 4: Incomplete Dynamic Messages
```r
# WRONG - Only part of the message is translated
paste(i18n$t("Found"), total, "errors")  # "errors" not translated!
```

### ✅ Correct:
```r
paste(i18n$t("Found"), total, i18n$t("errors"))
# or better:
paste0(i18n$t("Found"), " ", total, " ", i18n$t("errors"))
```

---

### ❌ Mistake 5: Missing Translation Keys
```r
# WRONG - Using i18n$t() without adding key to translation files
showNotification(i18n$t("This key doesn't exist in translation files"))
# Will display: "This key doesn't exist in translation files" (fallback to key)
# BUT enforcement tests will FAIL
```

### ✅ Correct:
```r
# 1. Add key to appropriate translation file first
# 2. Then use it in code
showNotification(i18n$t("This key exists in translation files"))
```

---

## Additional Resources

### Translation Documentation
- **[TRANSLATION_WORKFLOW_GUIDE.md](TRANSLATION_WORKFLOW_GUIDE.md)**: Complete guide to translation workflows
- **[QUICK_START_TRANSLATIONS.md](QUICK_START_TRANSLATIONS.md)**: Fast start guide (2 minutes)
- **[AUTOMATED_TRANSLATION_SYSTEM.md](AUTOMATED_TRANSLATION_SYSTEM.md)**: Automation tools documentation

### Implementation Guides
- **Phase 1 Completion Docs**: See `I18N_PHASE1_TASK*_COMPLETE.md` files for examples
- **Module Examples**:
  - `modules/pims_stakeholder_module.R` - Full module example
  - `modules/isa_data_entry_module.R` - Data entry patterns
  - `modules/analysis_tools_module.R` - Error handling patterns

### Translation Tools
Located in `scripts/`:
- `add_translation.R` - Interactive translation adding
- `translation_workflow.R` - Complete workflow manager
- `validate_translations.R` - Validation tools

### Testing
- `tests/testthat/test-i18n-enforcement.R` - i18n enforcement suite
- `tests/testthat/test-translations.R` - Translation structure tests

---

## Quick Reference

### Essential i18n Commands

```r
# In module UI
shiny.i18n::usei18n(i18n)  # First line of every module UI

# Wrapping text
i18n$t("Text to translate")

# Dynamic text
paste(i18n$t("Prefix"), variable, i18n$t("Suffix"))

# Check your work
testthat::test_file("tests/testthat/test-i18n-enforcement.R")
```

### When in Doubt

1. **Check existing code**: Look at `modules/pims_stakeholder_module.R` for patterns
2. **Run enforcement tests**: They will tell you what's wrong
3. **Review this document**: All common patterns are documented
4. **Ask in PR**: Maintainers are happy to help with i18n questions

---

## Questions or Issues?

- **Translation questions**: Check [TRANSLATION_WORKFLOW_GUIDE.md](TRANSLATION_WORKFLOW_GUIDE.md)
- **Technical issues**: Open an issue on GitHub
- **i18n patterns**: Review the Phase 1 completion documents
- **General contributions**: Follow this guide and the PR template

---

**Thank you for contributing to MarineSABRES SES Toolbox and helping make marine ecosystem research accessible worldwide! 🌊🌍**

---

*Last updated: 2025-11-25*
*i18n Phase 1 Complete - 7 languages supported: en, es, fr, de, lt, pt, it*
