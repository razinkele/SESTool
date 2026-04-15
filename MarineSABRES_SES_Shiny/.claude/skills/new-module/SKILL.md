---
name: new-module
description: Scaffold a new Shiny module following project conventions (i18n, event_bus, snake_case naming, standard header)
disable-model-invocation: true
---

# New Module Scaffold

Create a new Shiny module following all MarineSABRES SES Toolbox conventions.

## Arguments

- `name`: Module name in snake_case (e.g., `data_summary`)
- `purpose`: Brief description of what the module does
- `type`: One of `standard`, `analysis`, `visualization` (default: `standard`)

## Workflow

### 1. Validate naming

- Name must be `snake_case` (no camelCase, no hyphens)
- UI function: `{name}_ui(id, i18n)`
- Server function: `{name}_server(id, project_data, i18n, event_bus = NULL)`
- File: `modules/{name}.R` if standard, `modules/analysis_{name}.R` if analysis type

### 2. Create the module file

Use the template from `modules/_module_template.R` as the base. Fill in:

- Module header comment block with name, file path, purpose, exports
- UI function with `shiny.i18n::usei18n(i18n$translator %||% i18n)` and `ns <- NS(id)`
- Server function with `moduleServer`, `rv <- reactiveValues()`, and section separators
- For `analysis` type: include the stale data observer pattern:

```r
observe({
  req(!is.null(event_bus))
  event_bus$on_isa_change()
  if (isolate(rv$analysis_complete)) {
    showNotification(i18n$t("modules.analysis.common.data_changed_rerun"),
                     type = "warning", duration = 8)
  }
})
```

### 3. Create translation file

Create `translations/modules/{name}.json` with the standard structure:

```json
{
  "languages": ["en", "es", "fr", "de", "lt", "pt", "it", "no", "el"],
  "translation": {
    "modules.{name}.title": {
      "en": "...",
      ...all 9 languages...
    }
  }
}
```

Include at minimum a `.title` key. Add other keys based on the module's purpose.

### 4. Register in app.R

Inform the user where to add `source()` and module calls in `app.R`. Do NOT auto-edit `app.R` — the user should decide placement.

### 5. Validate

Run the i18n enforcement test to verify the new module passes:

```bash
Rscript -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
```

## Rules

- All user-facing text must use `i18n$t("key")`
- Use `debug_log()` not `cat()` for debug output
- Use `format_user_error()` for user-facing errors
- Error handling: `tryCatch` with translated error prefix
- Parameter order: `id, project_data, i18n, event_bus = NULL, ...`
- Always include `ns <- session$ns` inside `moduleServer`
