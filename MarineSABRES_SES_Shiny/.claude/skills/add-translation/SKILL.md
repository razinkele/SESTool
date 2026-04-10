---
name: add-translation
description: Add a new i18n translation key across all 9 languages (en, es, fr, de, lt, pt, it, no, el) to the correct translation file with validation
disable-model-invocation: true
---

# Add Translation Key

Add one or more i18n translation keys to the project's translation system.

## Arguments

- `key`: The translation key (e.g., `common.buttons.export_pdf` or `modules.analysis.title`)
- `en`: The English text (required). Other languages will be translated from this.

## Workflow

### 1. Determine the correct file

Translation keys follow a naming convention that maps to files:

| Key prefix | File location |
|------------|---------------|
| `common.buttons.*` | `translations/common/buttons.json` |
| `common.labels.*` | `translations/common/labels.json` |
| `common.messages.*` | `translations/common/messages.json` |
| `common.validation.*` | `translations/common/validation.json` |
| `common.navigation.*` | `translations/common/navigation.json` |
| `common.misc.*` | `translations/common/misc.json` |
| `modules.<module_name>.*` | `translations/modules/<module_name>.json` |
| `ui.<component>.*` | `translations/ui/<component>.json` |

If the target file doesn't exist, create it with the standard structure.

### 2. Check for duplicates

Read the target file and verify the key doesn't already exist. If it does, ask the user whether to update or skip.

### 3. Add the key with all 9 languages

Every key MUST have translations for all 9 languages: `en`, `es`, `fr`, `de`, `lt`, `pt`, `it`, `no`, `el`.

Use the English text to produce accurate translations. The JSON structure is:

```json
"key.name": {
  "en": "English text",
  "es": "Spanish text",
  "fr": "French text",
  "de": "German text",
  "lt": "Lithuanian text",
  "pt": "Portuguese text",
  "it": "Italian text",
  "no": "Norwegian text",
  "el": "Greek text"
}
```

### 4. Validate

After adding, run:

```bash
Rscript scripts/generate_translations.R
```

Report the result to the user. If validation fails, fix the issue.

### 5. Regenerate merged translations

Run:

```bash
Rscript scripts/generate_translations.R
```

This regenerates `translations/_merged_translations.json` from source files.

## Rules

- Never edit `translations/_merged_translations.json` directly
- Always provide all 9 languages — no placeholders or empty strings
- Keep translations contextually appropriate for a scientific SES analysis tool
- Use formal register for all languages
- For technical terms (DAPSIWRM, SES, CLD, ISA), keep them untranslated across all languages
