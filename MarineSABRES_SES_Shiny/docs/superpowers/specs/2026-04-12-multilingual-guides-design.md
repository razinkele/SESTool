# Multilingual User Guides Design (revision 2 — verified)

**Status**: Revision 2, 2026-04-12 (after adversarial review caught word-count error, encoding gap, PDF engine gap)
**Scope**: Subsystem D — translate the guidebook Rmd and ISA User Guide markdown into 8 additional languages using Claude-generated drafts with a machine-translation disclaimer.

## Problem

The app supports 9 UI languages but all user-facing documentation is English-only:
- `guidebook/guidebook.Rmd` (436 words) — primary in-app guide rendered as HTML/PDF
- `www/ISA_User_Guide.md` (5,224 words) — exercise-by-exercise walkthrough linked from ISA help button

## Approach

Hybrid translation: Claude generates 8 translations per file. Each non-English version gets a Bootstrap-styled disclaimer banner. Review tracking via checklist.

## Important: Language Change = Page Reload

The in-app language selector (`server/modals.R:102-127`) forces a **full page reload** via `saveLanguageAndReload`. This means:
- Every language change creates a **new Shiny session**
- The `guidebook_module.R` `once = TRUE` cache fires fresh for each language (no stale-language issue)
- The ISA help button's static `tags$a(href = ...)` rebuilds with the new `i18n` at UI construction time (no `uiOutput`/`renderUI` needed)

This simplifies the module wiring: just read `i18n$get_translation_language()` at render time and pick the right file.

## File Structure

### Guidebook Rmd (436 words — small file)

```
guidebook/
├── guidebook_en.Rmd       (rename of existing guidebook.Rmd)
├── guidebook_es.Rmd       (Spanish — Claude draft)
├── guidebook_fr.Rmd       ... (one per language)
├── guidebook_de.Rmd
├── guidebook_lt.Rmd
├── guidebook_pt.Rmd
├── guidebook_it.Rmd
├── guidebook_no.Rmd
└── guidebook_el.Rmd
```

The existing `guidebook/guidebook.Rmd` is **renamed** to `guidebook_en.Rmd` (not copied). The module's fallback logic handles any code that referenced the old name.

### ISA User Guide (5,224 words — bulk of the translation work)

```
www/
├── ISA_User_Guide_en.md   (rename of existing ISA_User_Guide.md)
├── ISA_User_Guide_es.md   ... (one per language)
├── ISA_User_Guide_fr.md
├── ISA_User_Guide_de.md
├── ISA_User_Guide_lt.md
├── ISA_User_Guide_pt.md
├── ISA_User_Guide_it.md
├── ISA_User_Guide_no.md
└── ISA_User_Guide_el.md
```

Same rename-not-copy strategy. Old filename references fall through to the English fallback.

## Module Wiring

### guidebook_module.R (3 render calls to update)

**Render call pattern** (applied to lines 39, 66, 79):

```r
lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
rmd_file <- file.path("guidebook", paste0("guidebook_", lang, ".Rmd"))
if (!file.exists(rmd_file)) rmd_file <- file.path("guidebook", "guidebook_en.Rmd")
```

**Additional fixes** discovered by the review:

1. **Add `encoding = "UTF-8"` to all 3 `rmarkdown::render()` calls** — without it, Greek and Lithuanian characters garble on Windows with non-UTF-8 system locale.

2. **PDF engine for Greek**: The default `pdflatex` cannot render Greek characters. Add `latex_engine: xelatex` to the YAML front matter of `guidebook_el.Rmd` (and ideally all translated Rmd files for consistency). Alternatively, pass `output_format = rmarkdown::pdf_document(latex_engine = "xelatex")` at render time — this is more robust because it doesn't require the Rmd file itself to specify the engine. Use this approach.

3. **Download handler messages**: Lines 65 and 78 have hardcoded English `"Generating PDF..."` and `"Generating HTML..."`. Wrap in `i18n$t()` using existing keys or add 2 new keys.

### ISA help button (isa_data_entry_module.R:781)

Current: `href = "ISA_User_Guide.md"` (hardcoded in UI function).

Change to:
```r
lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
guide_file <- paste0("ISA_User_Guide_", lang, ".md")
if (!file.exists(file.path("www", guide_file))) guide_file <- "ISA_User_Guide_en.md"
```

Since `i18n` is a parameter of `isa_data_entry_ui(id, i18n)`, this runs at UI construction time. Language change triggers page reload → UI re-renders → link updates. No `uiOutput`/`renderUI` wrapper needed.

**Note**: `file.exists(file.path("www", guide_file))` checks at UI build time whether the translated file exists on disk. If it doesn't (e.g., a 10th language is added but the guide isn't translated yet), English falls through.

## Machine-Translation Disclaimer

Each non-English file gets a **Bootstrap alert** banner (not a Markdown blockquote — matches the app's visual style):

For Rmd files:
```html
<div class="alert alert-info" role="alert">
<strong>Note:</strong> This guide was machine-translated from English using Claude AI.
If you notice errors, please report them to the MarineSABRES project team.
<em>Translation status: Draft (machine-translated, pending review)</em>
</div>
```

For .md files (same content, rendered by the browser):
```html
<div class="alert alert-info" role="alert">
<strong>Note:</strong> This guide was machine-translated from English using Claude AI.
If you notice errors, please report them to the MarineSABRES project team.
<em>Translation status: Draft (machine-translated, pending review)</em>
</div>
```

Removed per-language when a domain expert signs off.

## Review Tracking

`translations/guides/REVIEW_STATUS.md`:

```markdown
# User Guide Translation Review Status

| Language | Code | Guidebook Rmd | ISA User Guide | Reviewer | Date |
|----------|------|---------------|----------------|----------|------|
| English | en | Source | Source | — | — |
| Spanish | es | Draft | Draft | — | Pending |
| French | fr | Draft | Draft | — | Pending |
| German | de | Draft | Draft | — | Pending |
| Lithuanian | lt | Draft | Draft | — | Pending |
| Portuguese | pt | Draft | Draft | — | Pending |
| Italian | it | Draft | Draft | — | Pending |
| Norwegian | no | Draft | Draft | — | Pending |
| Greek | el | Draft | Draft | — | Pending |

**Status values**: Source, Draft (machine-translated), Reviewed (expert approved, banner removed)
```

## Translation Rules

Preserve:
- All Markdown/Rmd structure (headings, code blocks, YAML front matter, bullet lists)
- Technical terms untranslated: DAPSIWRM, DAPSI(W)R(M), ISA, SES, CLD, Kumu, HELCOM, OSPAR, MSFD, MPA
- R code blocks — completely untouched
- URLs, links, image references — preserved as-is
- YAML front matter keys — preserved (only human-readable values like `title:` translated)

Domain terms use standard equivalents:
- "ecosystem services" → "servicios ecosistémicos" (es), "services écosystémiques" (fr), etc.
- "stakeholders" → "partes interesadas" (es), "parties prenantes" (fr), etc.
- Where no established translation exists, keep English in parentheses

## Effort Estimate (corrected from revision 1)

| Item | Effort |
|------|--------|
| Module wiring (guidebook_module.R + ISA help button + encoding + i18n messages) | 45 min |
| Translate guidebook.Rmd × 8 languages (436 words each) | 30 min |
| Translate ISA_User_Guide.md × 8 languages (5,224 words each) | 2 hrs |
| Review status file + disclaimer banners | 10 min |
| **Total** | **~3.5 hours** |

## Non-goals

- No English content updates (subsystem C)
- No pre-rendered PDFs (on-demand via existing pipeline, with xelatex for Greek)
- No translation memory tooling (YAGNI for 2 files × 9 languages)
- No automated quality checking (disclaimer + review checklist)
- No `guidebook.Rmd` backward-compat copy (renamed to `_en`, module fallback handles old references)
