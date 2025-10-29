# Contributing to MarineSABRES SES Toolbox

## Code Style and Standards

### General Principles
- Follow the Tidyverse Style Guide for R code
- Write clear, self-documenting code
- Prefer clarity over cleverness
- Add comments for complex logic, not obvious operations

### Naming Conventions

#### Functions
- **Use snake_case** for all function names
- Use descriptive, verb-based names
- Examples: `create_nodes_df()`, `calculate_network_metrics()`, `export_visnetwork_html()`

#### Variables
- **Use snake_case** for all variable names
- Use descriptive nouns
- Examples: `project_data`, `isa_data`, `filtered_nodes`

#### Module IDs
- Use lowercase with underscores
- Examples: `"isa_module"`, `"cld_viz"`, `"analysis_loops"`

#### Constants
- Use SCREAMING_SNAKE_CASE
- Examples: `DAPSIWRM_ELEMENTS`, `ELEMENT_COLORS`, `CONFIDENCE_DEFAULT`

### Package Loading

#### In Production Code
**DO:**
```r
# In global.R only
library(shiny)
library(igraph)
library(dplyr)
```

**DON'T:**
```r
# In individual function files
library(igraph)  # ❌ Already loaded in global.R
```

#### Optional Dependencies
```r
# Use requireNamespace() for optional packages
if (!requireNamespace("webshot", quietly = TRUE)) {
  stop("Package 'webshot' is required. Install with: install.packages('webshot')")
}
```

#### In Tests
```r
# tests/testthat/setup.R loads everything
# Individual test files should NOT reload packages
```

### Error Handling

#### Always Add Error Handling For:
- User-facing functions
- Data processing functions
- Network analysis functions
- Export functions
- Functions that interact with external systems

#### Error Handling Pattern
```r
my_function <- function(data, parameter) {
  tryCatch({
    # Input validation
    if (is.null(data) || nrow(data) == 0) {
      stop("Data is empty or NULL")
    }
    if (!is.numeric(parameter) || parameter <= 0) {
      stop("Parameter must be a positive number")
    }

    # Main logic
    result <- process_data(data, parameter)

    # Success feedback
    message("Processing completed successfully")
    return(result)

  }, error = function(e) {
    stop(paste("Error in my_function:", e$message))
  })
}
```

### Documentation

#### Roxygen2 Standards
All exported functions must have complete documentation:

```r
#' Function Title (One Line Summary)
#'
#' Detailed description of what the function does.
#' Can span multiple lines.
#'
#' @param parameter_name Description of the parameter.
#'   Include expected type and structure.
#' @param another_param Description. Use indentation
#'   for multi-line descriptions.
#'
#' @return Description of return value and its structure.
#'
#' @details
#' Additional details about:
#' \itemize{
#'   \item Implementation approach
#'   \item Performance considerations
#'   \item Important behaviors
#' }
#'
#' @examples
#' \dontrun{
#' result <- my_function(data, parameter = 10)
#' }
#'
#' @export
my_function <- function(parameter_name, another_param) {
  # Implementation
}
```

### Shiny Modules

#### Module Structure
```r
#' Module UI
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
module_ui <- function(id) {
  ns <- NS(id)
  # UI definition
}

#' Module Server
#'
#' @param id Module namespace ID
#' @param reactive_data Reactive expression with data
#' @return Server module
#' @export
module_server <- function(id, reactive_data) {
  moduleServer(id, function(input, output, session) {
    # Server logic
  })
}
```

#### Module Naming
- UI function: `[module_name]_ui`
- Server function: `[module_name]_server`
- Examples: `cld_viz_ui`, `cld_viz_server`

### UI/UX Consistency

#### Button Classes
Use consistent button classes for common actions:

```r
# Primary actions (save, submit)
actionButton(..., class = "btn-primary")

# Success actions (add, create)
actionButton(..., class = "btn-success")

# Warning actions (import, modify)
actionButton(..., class = "btn-warning")

# Danger actions (delete, remove, reset)
actionButton(..., class = "btn-danger")

# Info/Help actions
actionButton(..., class = "btn-info btn-sm")

# Small buttons in lists
actionButton(..., class = "btn-danger btn-sm")

# Block-width buttons
actionButton(..., class = "btn-primary btn-block")
```

#### Icon Usage
```r
# Use Font Awesome icons consistently
icon("plus")         # Add/Create
icon("trash")        # Delete
icon("download")     # Export/Download
icon("upload")       # Import/Upload
icon("question-circle") # Help
icon("info-circle")  # Information
icon("filter")       # Filtering
icon("search")       # Search
```

### Performance Best Practices

#### Reactive Caching
```r
# Use signatures to detect changes
isa_signature <- paste(
  nrow(isa_data$drivers %||% data.frame()),
  nrow(isa_data$activities %||% data.frame()),
  # ... other tables
  sep = "-"
)

if (is.null(rv$cached_signature) || rv$cached_signature != isa_signature) {
  # Rebuild only when data changed
  rv$cached_data <- expensive_computation(isa_data)
  rv$cached_signature <- isa_signature
}
```

#### Efficient Reactives
```r
# DON'T rebuild everything
observe({
  rv$full_network <- create_network(data())  # ❌ Runs on every change
})

# DO use targeted updates
observe({
  req(data_changed())
  rv$full_network <- create_network(data())  # ✅ Only when needed
})

# Use visNetworkProxy for updates
observe({
  req(rv$filters_changed)
  visNetworkProxy("network") %>%
    visUpdateNodes(filtered_nodes())  # ✅ Proxy update, no re-render
})
```

### CSS and Styling

#### Custom CSS Classes
```r
# Use descriptive, namespaced class names
.module-name-component {
  /* styles */
}

# Example
.cld-sidebar {
  position: fixed;
  /* ... */
}

.cld-toggle-btn {
  /* ... */
}
```

#### Transitions
```r
# Use consistent transition durations
transition: property 0.3s;  /* Standard: 300ms */
transition: property 0.5s;  /* Slow: 500ms */
transition: property 0.15s; /* Fast: 150ms */
```

### Testing

#### Test File Structure
```r
# tests/testthat/test-module-name.R

# DON'T load packages (already in setup.R)
# library(testthat)  # ❌

test_that("function does X correctly", {
  # Arrange
  input_data <- create_mock_data()

  # Act
  result <- my_function(input_data)

  # Assert
  expect_equal(result$status, "success")
  expect_gt(nrow(result$data), 0)
})
```

#### Test Coverage Goals
- All exported functions: 100%
- Data processing functions: 100%
- UI logic: 80%+
- Error handling paths: 100%

### Git Commit Messages

#### Format
```
Brief summary (50 chars or less)

More detailed explanation (wrapped at 72 characters):
- What changed
- Why the change was needed
- How it affects the system

Technical details:
- Implementation notes
- Performance impact
- Breaking changes (if any)

Testing:
- What was tested
- Test results

Status: Production ready / Needs testing / WIP

Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### Commit Message Guidelines
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Fix bug" not "Fixes bug")
- Be specific and descriptive
- Reference issue numbers when applicable

### Code Review Checklist

Before submitting code for review:

- [ ] All functions have roxygen documentation
- [ ] Error handling added for user-facing functions
- [ ] No redundant library() calls
- [ ] No debug code (cat, print statements)
- [ ] Consistent naming conventions
- [ ] Tests written and passing
- [ ] No performance regressions
- [ ] UI follows button/icon conventions
- [ ] Git commit message is clear and detailed

### Common Pitfalls to Avoid

#### ❌ DON'T
```r
# Redundant library loading
library(igraph)  # Already in global.R

# Using require() instead of library()
require(dplyr)  # Masks errors

# Missing error handling
result <- risky_operation()  # No tryCatch

# Debug code in production
cat("DEBUG:", value)
print(data)

# Inconsistent naming
CreateNodes <- function()  # Wrong case
create.nodes <- function() # Wrong separator

# Magic numbers
nodes$size <- value * 20  # What is 20?

# No documentation
my_function <- function(x, y) { }
```

#### ✅ DO
```r
# Packages loaded in global.R only
# (nothing here)

# Use library() consistently
library(shiny)  # In global.R

# Add error handling
result <- tryCatch({
  risky_operation()
}, error = function(e) {
  stop(paste("Error:", e$message))
})

# Remove debug code before commit
# (no debug statements)

# Consistent naming
create_nodes <- function()  # ✅

# Use constants
BASE_NODE_SIZE <- 20
nodes$size <- value * BASE_NODE_SIZE

# Add documentation
#' Create nodes dataframe
#' @param data ISA data
#' @return Nodes dataframe
create_nodes <- function(data) { }
```

### Performance Guidelines

#### Optimization Priority
1. **First**: Make it work (correctness)
2. **Second**: Make it clear (readability)
3. **Third**: Make it fast (optimization)

#### When to Optimize
- Loops over large datasets (>10,000 rows)
- Reactive chains that update frequently
- Network rendering with many nodes (>1,000)
- Export operations

#### How to Optimize
- Cache expensive computations
- Use vectorized operations
- Implement signature-based change detection
- Use proxy updates instead of full re-renders
- Profile before optimizing (don't guess)

### Accessibility

#### Always Provide
- Alt text for images
- Labels for form inputs
- Keyboard navigation support
- Clear error messages
- Loading indicators for slow operations

### Security

#### Always Validate
- User file uploads
- User text inputs
- File paths (prevent traversal)
- SQL queries (use parameterized queries)

#### Never
- Store sensitive data in plain text
- Trust user input without validation
- Execute arbitrary user code
- Expose internal paths/structure

### Questions?

If you have questions about coding standards or best practices:
1. Check this document first
2. Look at existing well-documented modules (e.g., `cld_visualization_module.R`)
3. Ask the team lead
4. Refer to the Tidyverse Style Guide

### Resources

- [Tidyverse Style Guide](https://style.tidyverse.org/)
- [Shiny Module Best Practices](https://shiny.rstudio.com/articles/modules.html)
- [R Packages Book](https://r-pkgs.org/)
- [Advanced R](https://adv-r.hadley.nz/)

---

**Last Updated:** October 29, 2025
**Version:** 1.0
**Status:** Living document - will be updated as standards evolve
