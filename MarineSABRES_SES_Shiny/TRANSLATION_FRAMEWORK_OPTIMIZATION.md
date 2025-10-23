# Translation Framework Optimization & Restructuring Proposal
## MarineSABRES SES Toolbox

**Date**: 2025-10-22
**Status**: Proposal
**Author**: System Analysis

---

## Executive Summary

This document proposes a comprehensive optimization and restructuring of the translation framework for the MarineSABRES SES Toolbox to improve:
- **Maintainability**: Easier to add, update, and manage translations
- **Scalability**: Support for adding new languages and modules
- **Performance**: Faster load times and reduced memory footprint
- **Developer Experience**: Clearer organization and better tooling

---

## Current State Analysis

### ✅ Strengths
1. **shiny.i18n integration**: Proper use of industry-standard i18n library
2. **Modular approach**: Translations separated from code
3. **Good coverage**: Dashboard and Entry Point fully translated (75 entries)
4. **Six languages**: Comprehensive language support (en, es, fr, de, pt, it)

### ❌ Current Issues
1. **Flat structure**: All 105 translations in single flat array
2. **No namespacing**: Hard to identify which module uses which translations
3. **Maintenance burden**: Adding translations requires scrolling through entire file
4. **Corrupted data**: ~26 entries with encoding issues
5. **No validation**: Easy to create duplicate or missing keys
6. **Missing translations**: Major modules (PIMS, ISA, CLD) not translated
7. **Data structure translations**: EP0-EP4 data in global.R not translatable

---

## Proposed Architecture

### 1. **Hierarchical Namespace Structure**

#### Current (Flat):
```json
{
  "translation": [
    {"en": "Dashboard", "es": "Panel", ...},
    {"en": "Total Elements", "es": "Elementos Totales", ...},
    {"en": "Getting Started", "es": "Empezar", ...}
  ]
}
```

#### Proposed (Namespaced):
```json
{
  "translation": [
    {"en": "common.back", "es": "Atrás", ...},
    {"en": "common.continue", "es": "Continuar", ...},
    {"en": "dashboard.title", "es": "Panel", ...},
    {"en": "dashboard.total_elements", "es": "Elementos Totales", ...},
    {"en": "entry_point.title", "es": "Empezar", ...},
    {"en": "entry_point.ep0.title", "es": "Punto de Entrada 0", ...}
  ]
}
```

**Benefits**:
- Clear module ownership
- Prevents naming collisions
- Easy to find translations
- Auto-completion friendly

---

### 2. **Split into Multiple Files**

#### Proposed Structure:
```
translations/
├── common.json          # Shared UI elements (buttons, status, etc.)
├── dashboard.json       # Dashboard module translations
├── entry_point.json     # Entry Point system
├── pims.json           # PIMS module
│   ├── project.json
│   ├── stakeholders.json
│   ├── resources.json
│   ├── data.json
│   └── evaluation.json
├── isa.json            # ISA Data Entry
├── cld.json            # CLD Visualization
├── analysis.json       # Analysis Tools
├── response.json       # Response & Validation
├── export.json         # Export & Reports
└── validation_schema.json  # JSON schema for validation
```

**Benefits**:
- Smaller, manageable files
- Easier git diff/merge
- Module-level versioning
- Faster loading (lazy load per module)
- Parallel editing by multiple developers

---

### 3. **Translation Key Convention**

#### Standard Format:
```
<module>.<submodule?>.<component>.<element>
```

#### Examples:
```javascript
// Common elements
i18n$t("common.button.back")
i18n$t("common.button.continue")
i18n$t("common.button.save")
i18n$t("common.status.complete")
i18n$t("common.status.in_progress")

// Dashboard
i18n$t("dashboard.title")
i18n$t("dashboard.valuebox.total_elements")
i18n$t("dashboard.valuebox.connections")
i18n$t("dashboard.project_overview.title")

// Entry Point
i18n$t("entry_point.welcome.title")
i18n$t("entry_point.ep0.title")
i18n$t("entry_point.ep0.description")
i18n$t("entry_point.ep1.title")
i18n$t("entry_point.recommendations.title")

// PIMS
i18n$t("pims.project.title")
i18n$t("pims.stakeholders.add_button")
i18n$t("pims.stakeholders.table.name")

// ISA
i18n$t("isa.drivers.title")
i18n$t("isa.activities.add_button")
i18n$t("isa.adjacency_matrix.title")
```

---

### 4. **Helper Functions for Common Patterns**

Create translation helper functions in `functions/translation_helpers.R`:

```r
# Translation helper functions

#' Translate with module prefix
#' @param key Translation key (will be prefixed with module name)
#' @param module Module name
#' @param ... Additional parameters for interpolation
t_module <- function(key, module, ...) {
  full_key <- paste0(module, ".", key)
  i18n$t(full_key, ...)
}

#' Translate common element (button, status, etc.)
#' @param category Category (button, status, message, etc.)
#' @param key Element key
t_common <- function(category, key) {
  i18n$t(paste0("common.", category, ".", key))
}

#' Translate with fallback
#' @param key Translation key
#' @param fallback Fallback text if translation missing
t_safe <- function(key, fallback = key) {
  tryCatch({
    result <- i18n$t(key)
    if (is.null(result) || result == key) fallback else result
  }, error = function(e) fallback)
}

#' Translate with parameters (string interpolation)
#' @param key Translation key
#' @param ... Named parameters for interpolation
t_params <- function(key, ...) {
  template <- i18n$t(key)
  params <- list(...)

  for (name in names(params)) {
    placeholder <- paste0("{", name, "}")
    template <- gsub(placeholder, params[[name]], template, fixed = TRUE)
  }

  template
}

#' Pluralization helper
#' @param count Number
#' @param key_singular Singular form key
#' @param key_plural Plural form key
t_plural <- function(count, key_singular, key_plural) {
  key <- if (count == 1) key_singular else key_plural
  t_params(key, count = count)
}

# Usage examples:
# t_module("title", "dashboard")  → "dashboard.title"
# t_common("button", "save")      → "common.button.save"
# t_safe("missing.key", "Default Text")
# t_params("welcome.message", user = "John") → uses translation with {user} placeholder
# t_plural(5, "item.singular", "item.plural") → "5 items"
```

---

### 5. **Data Structure Translations**

For translating data structures like EP0-EP4 in global.R:

#### Current Problem:
```r
EP0_MANAGER_ROLES <- list(
  list(
    id = "policy_creator",
    label = "Policy Creator",  # Hardcoded English
    description = "Someone creating marine management policies"
  )
)
```

#### Solution A: Translation Keys in Data
```r
EP0_MANAGER_ROLES <- list(
  list(
    id = "policy_creator",
    label_key = "entry_point.ep0.roles.policy_creator.label",
    description_key = "entry_point.ep0.roles.policy_creator.description"
  )
)

# Then in UI:
lapply(EP0_MANAGER_ROLES, function(role) {
  div(
    h4(i18n$t(role$label_key)),
    p(i18n$t(role$description_key))
  )
})
```

#### Solution B: Separate Translation Files
```json
// translations/data/ep0_roles.json
{
  "policy_creator": {
    "en": {"label": "Policy Creator", "description": "..."},
    "es": {"label": "Creador de Políticas", "description": "..."},
    ...
  }
}
```

```r
# Load data translations
load_data_translations <- function(file, lang = "en") {
  data <- fromJSON(file)
  lapply(data, function(item) item[[lang]])
}

EP0_ROLES_TRANSLATIONS <- load_data_translations("translations/data/ep0_roles.json", session$userData$language)
```

---

### 6. **Translation Validation System**

Create `functions/translation_validator.R`:

```r
#' Validate translation completeness
#' @param translation_files Vector of translation file paths
#' @return List of validation results
validate_translations <- function(translation_files) {
  results <- list(
    missing = list(),
    duplicates = list(),
    encoding_issues = list(),
    orphaned = list()
  )

  all_translations <- list()

  for (file in translation_files) {
    module_name <- tools::file_path_sans_ext(basename(file))
    trans <- fromJSON(file)

    # Check for missing translations
    languages <- trans$languages
    for (entry in trans$translation) {
      key <- entry$en  # Use English as reference

      for (lang in languages) {
        if (is.null(entry[[lang]]) || entry[[lang]] == "") {
          results$missing[[lang]] <- c(results$missing[[lang]],
                                      paste0(module_name, ":", key))
        }

        # Check for encoding issues (Lithuanian characters in pt/it)
        if (lang %in% c("pt", "it")) {
          if (grepl("[ĄČĖŠįųž]", entry[[lang]])) {
            results$encoding_issues[[lang]] <- c(results$encoding_issues[[lang]],
                                                paste0(module_name, ":", key))
          }
        }
      }

      # Check for duplicates
      if (key %in% names(all_translations)) {
        results$duplicates <- c(results$duplicates, key)
      }
      all_translations[[key]] <- TRUE
    }
  }

  # Find orphaned translations (defined but never used in code)
  used_keys <- find_used_translation_keys()
  defined_keys <- names(all_translations)
  results$orphaned <- setdiff(defined_keys, used_keys)

  results
}

#' Find all translation keys used in code
#' @return Vector of translation keys found in R files
find_used_translation_keys <- function() {
  r_files <- list.files(c(".", "modules", "functions"), pattern = "\\.R$",
                       full.names = TRUE, recursive = TRUE)

  all_keys <- character()

  for (file in r_files) {
    content <- readLines(file, warn = FALSE)
    # Find patterns like i18n$t("key") or i18n$t('key')
    matches <- regmatches(content, gregexpr('i18n\\$t\\(["\']([^"\']+)["\']', content, perl = TRUE))
    keys <- unlist(lapply(matches, function(m) {
      if (length(m) > 0) {
        sub('i18n\\$t\\(["\']([^"\']+)["\'].*', '\\1', m)
      } else {
        character()
      }
    }))
    all_keys <- c(all_keys, keys)
  }

  unique(all_keys)
}

#' Generate validation report
#' @param results Validation results from validate_translations()
generate_validation_report <- function(results) {
  report <- c(
    "# Translation Validation Report",
    paste("Date:", Sys.time()),
    "",
    "## Summary",
    paste("- Missing translations:", sum(sapply(results$missing, length))),
    paste("- Duplicate keys:", length(results$duplicates)),
    paste("- Encoding issues:", sum(sapply(results$encoding_issues, length))),
    paste("- Orphaned translations:", length(results$orphaned)),
    ""
  )

  if (length(results$missing) > 0) {
    report <- c(report, "## Missing Translations", "")
    for (lang in names(results$missing)) {
      report <- c(report, paste("###", lang), "")
      report <- c(report, paste("-", results$missing[[lang]]), "")
    }
  }

  if (length(results$duplicates) > 0) {
    report <- c(report, "## Duplicate Keys", "")
    report <- c(report, paste("-", results$duplicates), "")
  }

  if (length(results$encoding_issues) > 0) {
    report <- c(report, "## Encoding Issues", "")
    for (lang in names(results$encoding_issues)) {
      report <- c(report, paste("###", lang), "")
      report <- c(report, paste("-", results$encoding_issues[[lang]]), "")
    }
  }

  if (length(results$orphaned) > 0) {
    report <- c(report, "## Orphaned Translations (defined but not used)", "")
    report <- c(report, paste("-", head(results$orphaned, 50)), "")
    if (length(results$orphaned) > 50) {
      report <- c(report, paste("... and", length(results$orphaned) - 50, "more"))
    }
  }

  paste(report, collapse = "\n")
}
```

---

### 7. **Translation Management UI** (Advanced)

Create a Shiny module for managing translations (for developers/translators):

```r
# modules/translation_manager_module.R

translation_manager_ui <- function(id) {
  ns <- NS(id)

  tagList(
    h2("Translation Manager"),

    fluidRow(
      column(4,
        selectInput(ns("module_select"), "Module:",
                   choices = c("common", "dashboard", "entry_point", "pims", "isa"))
      ),
      column(4,
        selectInput(ns("language_select"), "Language:",
                   choices = c("en", "es", "fr", "de", "pt", "it"))
      ),
      column(4,
        actionButton(ns("validate"), "Validate Translations", icon = icon("check-circle"))
      )
    ),

    fluidRow(
      column(12,
        DTOutput(ns("translation_table"))
      )
    ),

    fluidRow(
      column(12,
        h4("Add/Edit Translation"),
        textInput(ns("new_key"), "Key:"),
        textInput(ns("new_value"), "Value:"),
        actionButton(ns("save_translation"), "Save", class = "btn-primary")
      )
    ),

    fluidRow(
      column(12,
        h4("Validation Results"),
        verbatimTextOutput(ns("validation_output"))
      )
    )
  )
}

translation_manager_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Implementation for translation CRUD operations
    # This would allow non-developers to manage translations
  })
}
```

---

### 8. **Migration Strategy**

#### Phase 1: Preparation (Week 1)
1. Create new directory structure
2. Set up validation tools
3. Create helper functions
4. Document migration process

#### Phase 2: Common Translations (Week 1)
1. Extract common elements (buttons, status, messages)
2. Create `common.json` with namespaced keys
3. Update code to use new keys
4. Test all modules

#### Phase 3: Module-by-Module Migration (Weeks 2-3)
1. **Dashboard** (Day 1)
   - Extract to `dashboard.json`
   - Update `app.R` with namespaced keys
   - Test

2. **Entry Point** (Days 2-3)
   - Extract to `entry_point.json`
   - Update `modules/entry_point_module.R`
   - Handle data structure translations (EP0-EP4)
   - Test

3. **PIMS Modules** (Days 4-8)
   - Create `pims/*.json` files
   - Add translations for all 5 submodules
   - Update module code
   - Test

4. **Remaining Modules** (Days 9-15)
   - ISA, CLD, Analysis, Response, Export
   - Follow same pattern

#### Phase 4: Validation & Polish (Week 4)
1. Run validation suite
2. Fix encoding issues
3. Complete missing translations
4. Generate coverage report
5. Documentation

---

### 9. **Performance Optimizations**

#### Lazy Loading
```r
# global.R

# Instead of loading all translations at startup:
i18n <- Translator$new(translation_json_path = "translations/translation.json")

# Load only common + active module:
i18n_lazy <- function(module = NULL) {
  files <- c("translations/common.json")

  if (!is.null(module)) {
    module_file <- paste0("translations/", module, ".json")
    if (file.exists(module_file)) {
      files <- c(files, module_file)
    }
  }

  Translator$new(translation_json_path = files)
}
```

#### Caching
```r
# Cache translated strings to avoid repeated lookups
translation_cache <- new.env()

t_cached <- function(key, ...) {
  cache_key <- paste(key, i18n$get_translation_language(), sep = "_")

  if (exists(cache_key, envir = translation_cache)) {
    return(get(cache_key, envir = translation_cache))
  }

  result <- i18n$t(key, ...)
  assign(cache_key, result, envir = translation_cache)
  result
}

# Clear cache when language changes
observeEvent(input$language_selector, {
  rm(list = ls(translation_cache), envir = translation_cache)
})
```

---

### 10. **Translation Coverage Tracking**

Create a dashboard to track translation progress:

```r
# functions/translation_coverage.R

get_translation_coverage <- function() {
  modules <- c("common", "dashboard", "entry_point", "pims", "isa",
               "cld", "analysis", "response", "export")

  coverage <- data.frame(
    module = character(),
    total_keys = integer(),
    en = integer(),
    es = integer(),
    fr = integer(),
    de = integer(),
    pt = integer(),
    it = integer(),
    stringsAsFactors = FALSE
  )

  for (module in modules) {
    file <- paste0("translations/", module, ".json")

    if (file.exists(file)) {
      trans <- fromJSON(file)
      total <- length(trans$translation)

      row <- data.frame(
        module = module,
        total_keys = total,
        en = sum(!is.na(sapply(trans$translation, function(t) t$en))),
        es = sum(!is.na(sapply(trans$translation, function(t) t$es))),
        fr = sum(!is.na(sapply(trans$translation, function(t) t$fr))),
        de = sum(!is.na(sapply(trans$translation, function(t) t$de))),
        pt = sum(!is.na(sapply(trans$translation, function(t) t$pt))),
        it = sum(!is.na(sapply(trans$translation, function(t) t$it)))
      )

      coverage <- rbind(coverage, row)
    }
  }

  coverage
}

plot_translation_coverage <- function(coverage) {
  library(ggplot2)
  library(tidyr)

  coverage_long <- coverage %>%
    pivot_longer(cols = c(en, es, fr, de, pt, it),
                names_to = "language",
                values_to = "count") %>%
    mutate(percentage = count / total_keys * 100)

  ggplot(coverage_long, aes(x = module, y = percentage, fill = language)) +
    geom_col(position = "dodge") +
    labs(title = "Translation Coverage by Module",
         x = "Module",
         y = "Coverage (%)") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set2")
}
```

---

## Benefits Summary

### Maintainability
- ✅ Clear module ownership
- ✅ Easy to find and update translations
- ✅ Prevents accidental deletions
- ✅ Better git history

### Scalability
- ✅ Easy to add new modules
- ✅ Easy to add new languages
- ✅ Parallel development possible
- ✅ Lazy loading for large apps

### Performance
- ✅ Faster load times
- ✅ Lower memory footprint
- ✅ Caching support
- ✅ On-demand module loading

### Developer Experience
- ✅ Auto-completion in IDEs
- ✅ Type-safe keys (with helpers)
- ✅ Validation tooling
- ✅ Coverage tracking
- ✅ Better documentation

### Translation Management
- ✅ Non-developers can contribute
- ✅ Professional translator friendly
- ✅ Quality assurance built-in
- ✅ Progress tracking

---

## Estimated Effort

| Phase | Task | Effort |
|-------|------|--------|
| 1 | Setup & Tools | 2 days |
| 2 | Common Translations | 1 day |
| 3 | Dashboard Migration | 0.5 days |
| 3 | Entry Point Migration | 1 day |
| 3 | PIMS Translation & Migration | 3 days |
| 3 | ISA, CLD, Analysis, Response | 4 days |
| 3 | Export Section | 1 day |
| 4 | Validation & Polish | 2 days |
| 4 | Documentation | 1 day |
| **TOTAL** | | **15-16 days** |

---

## Next Steps

1. **Review this proposal** with the team
2. **Prioritize features** (can implement incrementally)
3. **Set up development environment** for translation work
4. **Start with Phase 1** (preparation and tooling)
5. **Pilot with one module** (e.g., Dashboard) to validate approach
6. **Roll out to remaining modules**

---

## Quick Wins (Can Implement Immediately)

1. **Fix remaining 26 corrupted translations** (2 hours)
2. **Add missing packages to install_dependencies.R** (15 minutes)
3. **Create translation helper functions** (1 hour)
4. **Set up validation script** (2 hours)
5. **Document current translation keys** (1 hour)

These can be done while planning the full restructuring.

---

## Appendix: Translation Statistics

### Current State
- **Total entries**: 105
- **Languages**: 6 (en, es, fr, de, pt, it)
- **Translated modules**: 2 (Dashboard, Entry Point)
- **Untranslated modules**: 6 (PIMS, ISA, CLD, Analysis, Response, Export)
- **Corrupted entries**: ~26 (pt/it with Lithuanian text)
- **Estimated total needed**: 500-700 entries for full coverage

### Target State
- **Total entries**: 600-700
- **Structure**: 10+ module files
- **Coverage**: 100% for all 6 languages
- **Validation**: Automated quality checks
- **Tooling**: Developer and translator UIs
- **Documentation**: Complete key reference

---

**End of Proposal**
