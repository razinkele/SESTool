# Internationalization (i18n) Guide for MarineSABRES SES Toolbox

## Overview

The MarineSABRES SES Shiny application supports multiple languages using the `shiny.i18n` package with a **modular translation system**. This guide explains how the internationalization system works and how to add or modify translations.

> 📖 **For detailed workflow instructions**, see [`TRANSLATION_WORKFLOW_GUIDE.md`](../TRANSLATION_WORKFLOW_GUIDE.md) in the project root.

## Supported Languages

Currently supported languages:
- **English (en)** 🇬🇧 - Default language
- **Spanish (es)** 🇪🇸
- **French (fr)** 🇫🇷
- **German (de)** 🇩🇪
- **Lithuanian (lt)** 🇱🇹
- **Portuguese (pt)** 🇵🇹
- **Italian (it)** 🇮🇹

## File Structure (Modular System)

```
translations/
├── _framework.json              # DAPSIWR framework terms (30 entries)
├── _glossary.json               # Common glossary (9 terms)
├── TEMPLATE.json                # Template for new files
├── README.md                    # This documentation file
├── translation.json.backup      # Legacy monolithic file (11,892 lines)
├── common/                      # Common UI elements
│   ├── buttons.json             # Button labels
│   ├── labels.json              # Form labels
│   ├── messages.json            # User messages
│   ├── navigation.json          # Navigation items
│   └── validation.json          # Validation messages
├── ui/                          # UI component translations
│   ├── header.json              # Header elements
│   ├── modals.json              # Modal dialogs
│   └── sidebar.json             # Sidebar elements
├── data/                        # Data-specific translations
│   └── node_types.json          # Node type definitions
└── modules/                     # Module-specific translations
    └── (future module files)
```

## 🚀 Quick Start

### Adding a New Translation

**Use the interactive tool** (recommended):
```bash
Rscript scripts/add_translation.R
```

This tool will:
- Guide you through selecting/creating a file
- Prompt for all 7 languages
- Validate before saving
- Check for duplicates

### Validating Before Commit

**Always run validation**:
```bash
Rscript scripts/translation_workflow.R check
```

This runs:
- JSON syntax validation
- Language completeness check
- Automated tests
- Encoding validation

### See All Available Commands

```bash
Rscript scripts/translation_workflow.R help
```

---

## Translation File Format

Modular translation files follow this structure:

```json
{
  "languages": ["en", "es", "fr", "de", "lt", "pt", "it"],
  "translation": [
    {
      "key": "common.buttons.save",
      "en": "Save",
      "es": "Guardar",
      "fr": "Enregistrer",
      "de": "Speichern",
      "lt": "Išsaugoti",
      "pt": "Salvar",
      "it": "Salva"
    }
  ]
}
```

**Key points**:
- All 7 languages required
- `key` field is optional but recommended for new translations
- Use namespaced keys: `category.subcategory.name`

## How to Use Translations in Code

### 1. In UI Functions

Use `i18n$t()` to wrap any text that needs translation:

```r
# Before (hardcoded English):
h1("Welcome to the MarineSABRES Toolbox")

# After (translatable):
h1(i18n$t("Welcome to the MarineSABRES Toolbox"))
```

### 2. In Server Functions

The `i18n` object is available globally, so you can use it the same way:

```r
output$message <- renderText({
  i18n$t("Your data has been saved successfully")
})
```

### 3. Dynamic Text with Variables

For text with variables, use placeholders in the translation file:

```json
{
  "en": "You selected {count} items",
  "es": "Seleccionaste {count} elementos"
}
```

Then interpolate in code:

```r
i18n$t("You selected {count} items", count = length(selected_items))
```

## Adding New Translations

### Step 1: Add the Translation Key

1. Open `translations/translation.json`
2. Add a new object to the `translation` array:

```json
{
  "en": "New text to translate",
  "es": "Nuevo texto a traducir",
  "fr": "Nouveau texte à traduire",
  "de": "Neuer zu übersetzender Text",
  "pt": "Novo texto para traduzir"
}
```

### Step 2: Use in Code

Replace hardcoded text with `i18n$t()`:

```r
# In your module or UI
h2(i18n$t("New text to translate"))
```

### Step 3: Test

1. Run the application
2. Use the language selector in the header
3. Verify all translations display correctly

## Adding a New Language

### Step 1: Update translation.json

1. Add the language code to the `languages` array:

```json
"languages": ["en", "es", "fr", "de", "pt", "it"]
```

2. Add translations for all existing keys:

```json
{
  "en": "Welcome",
  "es": "Bienvenida",
  "fr": "Bienvenue",
  "de": "Willkommen",
  "pt": "Bem-vindo",
  "it": "Benvenuto"  // New language
}
```

### Step 2: Update global.R

Add the language to `AVAILABLE_LANGUAGES`:

```r
AVAILABLE_LANGUAGES <- list(
  "en" = list(name = "English", flag = "🇬🇧"),
  "es" = list(name = "Español", flag = "🇪🇸"),
  "fr" = list(name = "Français", flag = "🇫🇷"),
  "de" = list(name = "Deutsch", flag = "🇩🇪"),
  "pt" = list(name = "Português", flag = "🇵🇹"),
  "it" = list(name = "Italiano", flag = "🇮🇹")  // New language
)
```

### Step 3: Test the New Language

1. Restart the application
2. Check that the new language appears in the language selector
3. Switch to the new language and verify all translations

## Translation Best Practices

### 1. Keep Keys in English

Always use the English text as the "key" in `i18n$t()`:

```r
# Good
i18n$t("Welcome to the application")

# Bad (using language codes)
i18n$t("app.welcome.title")
```

### 2. Maintain Consistency

Use the same English phrasing across the application for consistency:

```r
# Good - consistent
i18n$t("Save")
i18n$t("Save")

# Bad - inconsistent
i18n$t("Save")
i18n$t("Save changes")
```

### 3. Consider Context

Some words translate differently based on context. Add context if needed:

```json
{
  "en": "Close",
  "es": "Cerrar"  // Close a window
}
{
  "en": "Close (relationship)",
  "es": "Cercano"  // Close proximity
}
```

### 4. Test All Languages

Before committing changes:
- Switch to each language
- Navigate through all screens
- Check for:
  - Missing translations (English fallback)
  - Text overflow issues
  - Grammatical errors

## Common Issues and Solutions

### Issue 1: Text Not Translating

**Problem**: Text remains in English even after switching languages

**Solution**:
- Check that the text is wrapped in `i18n$t()`
- Verify the translation key exists in `translation.json`
- Restart the application to reload translations

### Issue 2: Special Characters Not Displaying

**Problem**: Accented characters (é, ñ, ü) show as symbols

**Solution**:
- Ensure `translation.json` is saved with UTF-8 encoding
- Check console for JSON parsing errors

### Issue 3: Language Selector Not Updating UI

**Problem**: Changing language doesn't update visible text

**Solution**:
- Ensure `shiny.i18n::usei18n(i18n)` is called in the module UI
- Check that `observeEvent(input$language_selector, ...)` is in server function
- Use `shiny.i18n::update_lang()` in the observer

## Translation Workflow

### For Developers:

1. Write UI/Server code in English
2. Wrap all user-facing text in `i18n$t()`
3. Add English text to `translation.json`
4. Request translations from language experts
5. Update `translation.json` with translations
6. Test in all languages

### For Translators:

1. Open `translations/translation.json`
2. Find entries where your language is missing or incorrect
3. Add/update translations
4. Test in the application
5. Submit changes via pull request

## Testing Checklist

Before releasing translations:

- [ ] All UI elements translate correctly
- [ ] No text overflow in any language
- [ ] Tooltips and help text are translated
- [ ] Error messages are translated
- [ ] Date/time formats are locale-appropriate
- [ ] Numbers are formatted correctly (e.g., 1,000 vs 1.000)
- [ ] Right-to-left languages work (if applicable)

## Module-Specific Translation Notes

### Entry Point Module

The Entry Point module (`modules/entry_point_module.R`) is fully internationalized:

- Welcome screen
- All entry point titles and descriptions
- Button labels
- Progress indicators
- Recommendation screen

**Files to update**:
- `modules/entry_point_module.R` - UI rendering functions
- `translations/translation.json` - Translation strings

### Data Entry Modules (Future Work)

The following modules need internationalization:

- [ ] PIMS Module
- [ ] ISA Data Entry Module
- [ ] CLD Visualization Module
- [ ] Analysis Tools Module
- [ ] Response Module

## Resources

### shiny.i18n Package Documentation
- GitHub: https://github.com/Appsilon/shiny.i18n
- Examples: https://appsilon.github.io/shiny.i18n/

### ISO Language Codes
- ISO 639-1: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

### Unicode Flags
- Emoji flags: https://emojipedia.org/flags/

## Support

For questions or issues with translations:
1. Check this documentation first
2. Review the `shiny.i18n` package documentation
3. Contact the development team
4. Submit an issue on the project repository

## Version History

- **v1.0** (2025-10-21): Initial internationalization implementation
  - 5 languages supported (en, es, fr, de, pt)
  - Entry Point module fully translated
  - Language selector in header

---

**Last Updated**: 2025-10-21
**Maintained by**: MarineSABRES Development Team
