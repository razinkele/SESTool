# Multilingual User Guides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the guidebook Rmd (436 words) and ISA User Guide markdown (5,224 words) into 8 languages (es, fr, de, lt, pt, it, no, el) with Claude-generated drafts, wire `guidebook_module.R` and the ISA help button to select by language, and add a machine-translation disclaimer banner.

**Architecture:** 6 tasks executed sequentially. Task 1 renames files. Task 2 wires the module. Tasks 3-5 generate translations. Task 6 creates the review status file. Translation subagents receive the full source text, the translation rules, and the disclaimer banner — they generate the translated file contents at execution time.

**Tech Stack:** R/Shiny (module wiring), Markdown/Rmd (content), rmarkdown (rendering)

**Spec source:** `docs/superpowers/specs/2026-04-12-multilingual-guides-design.md` (revision 2)

**Source file stats (verified 2026-04-12)**:
- `guidebook/guidebook.Rmd` — 90 lines, 436 words, YAML front matter + 4 H1 sections
- `www/ISA_User_Guide.md` — 1,118 lines, 5,224 words, 10 major sections, 13 exercises

---

## File Map

| Task | Action | Files | Effort |
|------|--------|-------|--------|
| 1 | Rename | `guidebook/guidebook.Rmd` → `guidebook_en.Rmd` + `www/ISA_User_Guide.md` → `ISA_User_Guide_en.md` | 5 min |
| 2 | Modify | `modules/guidebook_module.R` + `modules/isa_data_entry_module.R` + 2 i18n keys | 30 min |
| 3 | Create | `guidebook/guidebook_{es,fr,de,lt,pt,it,no,el}.Rmd` (8 files) | 30 min |
| 4 | Create | `www/ISA_User_Guide_{es,fr,de,lt}.md` (4 files) | 60 min |
| 5 | Create | `www/ISA_User_Guide_{pt,it,no,el}.md` (4 files) | 60 min |
| 6 | Create | `translations/guides/REVIEW_STATUS.md` | 5 min |

---

### Task 1: Rename source files to _en suffix

**Files:**
- Rename: `guidebook/guidebook.Rmd` → `guidebook/guidebook_en.Rmd`
- Rename: `www/ISA_User_Guide.md` → `www/ISA_User_Guide_en.md`

- [ ] **Step 1: Rename guidebook Rmd**

```bash
git mv guidebook/guidebook.Rmd guidebook/guidebook_en.Rmd
```

- [ ] **Step 2: Rename ISA User Guide**

```bash
git mv www/ISA_User_Guide.md www/ISA_User_Guide_en.md
```

- [ ] **Step 3: Verify**

```bash
ls guidebook/guidebook_en.Rmd www/ISA_User_Guide_en.md
ls guidebook/guidebook.Rmd www/ISA_User_Guide.md 2>&1
```
Expected: first `ls` succeeds (both _en files exist), second `ls` fails (old names gone).

- [ ] **Step 4: Commit**

```bash
git add -A guidebook/ www/
git commit -m "$(cat <<'EOF'
refactor: rename guidebook.Rmd and ISA_User_Guide.md to _en suffix

Preparation for multilingual guides: rename the English source
files from guidebook.Rmd to guidebook_en.Rmd and ISA_User_Guide.md
to ISA_User_Guide_en.md. The module wiring (Task 2) will add
language-aware file selection with English fallback.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Wire language-aware file selection

**Files:**
- Modify: `modules/guidebook_module.R` (3 render calls + encoding + download messages)
- Modify: `modules/isa_data_entry_module.R:781` (ISA help link)
- Modify: `translations/modules/guidebook.json` (2 new i18n keys for download progress)

**Background**: After Task 1, the English files are at `guidebook_en.Rmd` and `ISA_User_Guide_en.md`. The module must now select the file matching the user's language, with English fallback. Language change forces page reload (modals.R:127), so `once = TRUE` is correct and static UI links work.

- [ ] **Step 1: Add a helper function at the top of `guidebook_module.R`**

Read the file first. After the initial comment block (line 2) and before `guidebook_ui`, insert:

```r
# Resolve language-specific guidebook Rmd path with English fallback
resolve_guidebook_rmd <- function(i18n) {
  lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
  rmd_file <- file.path("guidebook", paste0("guidebook_", lang, ".Rmd"))
  if (!file.exists(rmd_file)) {
    rmd_file <- file.path("guidebook", "guidebook_en.Rmd")
  }
  rmd_file
}
```

- [ ] **Step 2: Update the session-start render call (line 39)**

**Old:**
```r
        rmarkdown::render("guidebook/guidebook.Rmd",
                         output_format = "html_fragment",
                         output_dir = tempdir(),
                         intermediates_dir = tempdir(),
                         quiet = TRUE)
```

**New:**
```r
        rmarkdown::render(resolve_guidebook_rmd(i18n),
                         output_format = "html_fragment",
                         output_dir = tempdir(),
                         intermediates_dir = tempdir(),
                         encoding = "UTF-8",
                         quiet = TRUE)
```

- [ ] **Step 3: Update the PDF download handler (line 66)**

**Old:**
```r
        withProgress(message = "Generating PDF...", {
          rmarkdown::render("guidebook/guidebook.Rmd",
                           output_format = "pdf_document",
                           output_file = file,
                           intermediates_dir = tempdir(),
                           quiet = TRUE)
        })
```

**New:**
```r
        withProgress(message = i18n$t("modules.guidebook.generating_pdf"), {
          rmarkdown::render(resolve_guidebook_rmd(i18n),
                           output_format = rmarkdown::pdf_document(latex_engine = "xelatex"),
                           output_file = file,
                           intermediates_dir = tempdir(),
                           encoding = "UTF-8",
                           quiet = TRUE)
        })
```

- [ ] **Step 4: Update the HTML download handler (line 78)**

**Old:**
```r
        withProgress(message = "Generating HTML...", {
          rmarkdown::render("guidebook/guidebook.Rmd",
                           output_format = "html_document",
                           output_file = file,
                           intermediates_dir = tempdir(),
                           quiet = TRUE)
        })
```

**New:**
```r
        withProgress(message = i18n$t("modules.guidebook.generating_html"), {
          rmarkdown::render(resolve_guidebook_rmd(i18n),
                           output_format = "html_document",
                           output_file = file,
                           intermediates_dir = tempdir(),
                           encoding = "UTF-8",
                           quiet = TRUE)
        })
```

- [ ] **Step 5: Update the ISA help link in `isa_data_entry_module.R:781`**

Read around line 779-785. The current link is:

**Old:**
```r
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = "ISA_User_Guide.md",
                    target = "_blank",
```

**New:**
```r
                  tags$a(
                    class = "btn btn-info btn-block",
                    href = local({
                      lang <- tryCatch(i18n$get_translation_language(), error = function(e) "en")
                      gf <- paste0("ISA_User_Guide_", lang, ".md")
                      if (!file.exists(file.path("www", gf))) gf <- "ISA_User_Guide_en.md"
                      gf
                    }),
                    target = "_blank",
```

`local({...})` evaluates immediately at UI build time and returns the resolved filename. Since language change = page reload, this runs fresh each session.

- [ ] **Step 6: Add 2 i18n keys to `translations/modules/guidebook.json`**

Read the file first to find the insertion point. Add inside the `"translation"` object:

```json
    "modules.guidebook.generating_pdf": {
      "en": "Generating PDF...",
      "es": "Generando PDF...",
      "fr": "Génération du PDF...",
      "de": "PDF wird erstellt...",
      "lt": "Generuojamas PDF...",
      "pt": "Gerando PDF...",
      "it": "Generazione PDF...",
      "no": "Genererer PDF...",
      "el": "Δημιουργία PDF..."
    },
    "modules.guidebook.generating_html": {
      "en": "Generating HTML...",
      "es": "Generando HTML...",
      "fr": "Génération du HTML...",
      "de": "HTML wird erstellt...",
      "lt": "Generuojamas HTML...",
      "pt": "Gerando HTML...",
      "it": "Generazione HTML...",
      "no": "Genererer HTML...",
      "el": "Δημιουργία HTML..."
    },
```

- [ ] **Step 7: Verify JSON + R parse**

```bash
micromamba run -n shiny python -c "import json; json.load(open('translations/modules/guidebook.json')); print('OK')"
Rscript -e "parse('modules/guidebook_module.R'); parse('modules/isa_data_entry_module.R'); cat('OK\n')"
```
Expected: both `OK`.

- [ ] **Step 8: Run i18n audit**

```bash
micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```
Expected: `missing=0 ... hardcoded=0`

- [ ] **Step 9: Commit**

```bash
git add modules/guidebook_module.R modules/isa_data_entry_module.R translations/modules/guidebook.json
git commit -m "$(cat <<'EOF'
feat: wire language-aware guidebook + ISA guide selection

guidebook_module.R: resolve_guidebook_rmd() helper picks
guidebook_<lang>.Rmd with English fallback. All 3 rmarkdown::render
calls updated: language-aware path, encoding="UTF-8", xelatex for
PDF (Greek/Lithuanian Unicode support). Download progress messages
wrapped in i18n$t() with 2 new keys.

isa_data_entry_module.R: ISA help button href now resolves to
ISA_User_Guide_<lang>.md with English fallback via local({}).
Language change = page reload, so the static tags$a rebuilds
correctly each session.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Translate guidebook.Rmd × 8 languages

**Files:**
- Create: `guidebook/guidebook_es.Rmd`, `guidebook_fr.Rmd`, `guidebook_de.Rmd`, `guidebook_lt.Rmd`, `guidebook_pt.Rmd`, `guidebook_it.Rmd`, `guidebook_no.Rmd`, `guidebook_el.Rmd`

**Source**: `guidebook/guidebook_en.Rmd` (90 lines, 436 words)

**Instructions for the executing subagent**:

For each of the 8 languages, create a translated copy of `guidebook/guidebook_en.Rmd`. Read the source file first, then produce the translation following these rules:

**Translation rules** (from spec):
- Preserve ALL Rmd structure: YAML front matter, headings, bullet lists, bold/italic formatting, code blocks
- Translate the YAML `title:` and `subtitle:` values. Keep `author:`, `date:`, and `output:` block untouched
- Keep these terms UNTRANSLATED: DAPSI(W)R(M), SES, CLD, ISA, Kumu, HELCOM, OSPAR, MSFD, MPA, MarineSABRES
- Keep R inline code (`` `r Sys.Date()` ``) untouched
- Use established marine ecology terms where they exist (e.g., "ecosystem services" → "servicios ecosistémicos")
- Where no standard translation exists, keep English in parentheses

**Disclaimer banner**: Insert this block immediately after the YAML `---` closing delimiter and before the first `# Quick Start Guide` heading:

```html
<div class="alert alert-info" role="alert">
<strong>Note:</strong> This guide was machine-translated from English using Claude AI.
If you notice errors, please report them to the MarineSABRES project team.
<em>Translation status: Draft (machine-translated, pending review)</em>
</div>
```

Translate the banner text itself into the target language (the "Note:", the body text, and the "Translation status:" line).

**Language codes and names**: es (Spanish), fr (French), de (German), lt (Lithuanian), pt (Portuguese), it (Italian), no (Norwegian Bokmål), el (Greek)

- [ ] **Step 1: Read the source file**

```bash
cat guidebook/guidebook_en.Rmd
```

- [ ] **Step 2: Create all 8 translated files**

Use the Write tool to create each file. Each file should be a complete standalone Rmd file — NOT a diff or partial replacement. Translate ALL user-facing text, keep structure identical.

Files to create (in this order):
1. `guidebook/guidebook_es.Rmd`
2. `guidebook/guidebook_fr.Rmd`
3. `guidebook/guidebook_de.Rmd`
4. `guidebook/guidebook_lt.Rmd`
5. `guidebook/guidebook_pt.Rmd`
6. `guidebook/guidebook_it.Rmd`
7. `guidebook/guidebook_no.Rmd`
8. `guidebook/guidebook_el.Rmd`

- [ ] **Step 3: Verify all 9 files exist (8 translated + 1 English)**

```bash
ls guidebook/guidebook_*.Rmd | wc -l
```
Expected: `9`

- [ ] **Step 4: Spot-check one file for structure integrity**

```bash
head -20 guidebook/guidebook_es.Rmd
```
Expected: YAML front matter with translated title/subtitle, then the disclaimer banner, then `# ` heading in Spanish.

- [ ] **Step 5: Commit**

```bash
git add guidebook/guidebook_*.Rmd
git commit -m "$(cat <<'EOF'
feat: translate guidebook.Rmd into 8 languages

Claude-generated draft translations of guidebook/guidebook_en.Rmd
(436 words) into es, fr, de, lt, pt, it, no, el. Each file includes
a machine-translation disclaimer banner (<div class="alert alert-info">)
to be removed when a domain expert reviews and approves.

Technical terms (DAPSI(W)R(M), SES, CLD, ISA, Kumu) kept in English.
Domain terms use standard equivalents where established.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Translate ISA_User_Guide.md — first batch (es, fr, de, lt)

**Files:**
- Create: `www/ISA_User_Guide_es.md`, `www/ISA_User_Guide_fr.md`, `www/ISA_User_Guide_de.md`, `www/ISA_User_Guide_lt.md`

**Source**: `www/ISA_User_Guide_en.md` (1,118 lines, 5,224 words)

**Instructions for the executing subagent**:

For each of the 4 languages in this batch, create a translated copy of `www/ISA_User_Guide_en.md`. Read the source file first (it's 1,118 lines), then produce the translation.

**Translation rules**: Same as Task 3 (see above). Additionally:
- The ISA guide has a Table of Contents with anchor links (`[Introduction](#introduction)`) — translate the display text but keep the anchor IDs in English (they must match the heading IDs which Markdown auto-generates from heading text). For translated headings, add explicit anchor IDs: `## Introducción {#introduction}` (this ensures the ToC links still work).
- Exercise names ("Exercise 0: Unfolding Complexity...") — translate the exercise description but keep "Exercise N:" numbering.
- Markdown tables — translate cell content, preserve table structure (`|...|...|`)
- The guide references "Kumu" — keep as-is (it's a product name)

**Disclaimer banner**: Same as Task 3 — insert at the very top of the file (line 1), before the `# ISA Data Entry Module - User Guide` heading. Translate the banner into the target language.

**Version/date header**: Update `**Version:** 1.0` to `**Version:** 1.0` (keep as-is) and `**Last Updated:** October 2025` to the translated equivalent of "April 2026" (since the translation IS the update).

- [ ] **Step 1: Read the source**

Read `www/ISA_User_Guide_en.md` fully — all 1,118 lines.

- [ ] **Step 2: Create 4 translated files**

Use Write tool for each:
1. `www/ISA_User_Guide_es.md` (Spanish)
2. `www/ISA_User_Guide_fr.md` (French)
3. `www/ISA_User_Guide_de.md` (German)
4. `www/ISA_User_Guide_lt.md` (Lithuanian)

Each must be a COMPLETE file — all 10 sections, all exercises, full glossary.

- [ ] **Step 3: Verify file count and approximate sizes**

```bash
wc -l www/ISA_User_Guide_es.md www/ISA_User_Guide_fr.md www/ISA_User_Guide_de.md www/ISA_User_Guide_lt.md
```
Expected: each file ~1,100-1,300 lines (within 20% of English source).

- [ ] **Step 4: Spot-check structure preserved**

```bash
grep -c "^## " www/ISA_User_Guide_es.md
grep -c "^### " www/ISA_User_Guide_es.md
```
Expected: section count close to English (10 H2, ~30 H3).

- [ ] **Step 5: Commit**

```bash
git add www/ISA_User_Guide_es.md www/ISA_User_Guide_fr.md www/ISA_User_Guide_de.md www/ISA_User_Guide_lt.md
git commit -m "$(cat <<'EOF'
feat: translate ISA User Guide — batch 1 (es, fr, de, lt)

Claude-generated draft translations of www/ISA_User_Guide_en.md
(5,224 words, 1,118 lines) into Spanish, French, German, Lithuanian.

Each file includes a translated machine-translation disclaimer
banner. Anchor IDs preserved for ToC links. Technical terms
(DAPSI(W)R(M), SES, CLD, ISA, Kumu) kept in English.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Translate ISA_User_Guide.md — second batch (pt, it, no, el)

**Files:**
- Create: `www/ISA_User_Guide_pt.md`, `www/ISA_User_Guide_it.md`, `www/ISA_User_Guide_no.md`, `www/ISA_User_Guide_el.md`

**Source**: `www/ISA_User_Guide_en.md` (same as Task 4)

**Instructions**: Identical to Task 4 — read the full source, translate following the same rules, add the disclaimer banner (translated), preserve anchor IDs for ToC.

- [ ] **Step 1: Read the source**

Read `www/ISA_User_Guide_en.md` fully.

- [ ] **Step 2: Create 4 translated files**

Use Write tool for each:
1. `www/ISA_User_Guide_pt.md` (Portuguese)
2. `www/ISA_User_Guide_it.md` (Italian)
3. `www/ISA_User_Guide_no.md` (Norwegian Bokmål)
4. `www/ISA_User_Guide_el.md` (Greek)

Each must be a COMPLETE file — all sections, all exercises, full glossary.

- [ ] **Step 3: Verify file count and sizes**

```bash
wc -l www/ISA_User_Guide_pt.md www/ISA_User_Guide_it.md www/ISA_User_Guide_no.md www/ISA_User_Guide_el.md
```
Expected: each ~1,100-1,300 lines.

- [ ] **Step 4: Verify all 9 ISA guide files now exist**

```bash
ls www/ISA_User_Guide_*.md | wc -l
```
Expected: `9` (1 English + 8 translated).

- [ ] **Step 5: Commit**

```bash
git add www/ISA_User_Guide_pt.md www/ISA_User_Guide_it.md www/ISA_User_Guide_no.md www/ISA_User_Guide_el.md
git commit -m "$(cat <<'EOF'
feat: translate ISA User Guide — batch 2 (pt, it, no, el)

Claude-generated draft translations of www/ISA_User_Guide_en.md
(5,224 words) into Portuguese, Italian, Norwegian, Greek.

Same approach as batch 1: disclaimer banner, anchor IDs preserved,
technical terms kept in English.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Create review status file

**Files:**
- Create: `translations/guides/REVIEW_STATUS.md`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p translations/guides
```

Then use Write tool to create `translations/guides/REVIEW_STATUS.md`:

```markdown
# User Guide Translation Review Status

All translations were generated by Claude AI on 2026-04-12 and are pending review by domain experts.

Each translated file includes a machine-translation disclaimer banner (`<div class="alert alert-info">`) that should be removed once reviewed and approved.

## Guidebook (guidebook/guidebook_*.Rmd — 436 words)

| Language | Code | File | Status | Reviewer | Date |
|----------|------|------|--------|----------|------|
| English | en | guidebook_en.Rmd | Source | — | — |
| Spanish | es | guidebook_es.Rmd | Draft | — | Pending |
| French | fr | guidebook_fr.Rmd | Draft | — | Pending |
| German | de | guidebook_de.Rmd | Draft | — | Pending |
| Lithuanian | lt | guidebook_lt.Rmd | Draft | — | Pending |
| Portuguese | pt | guidebook_pt.Rmd | Draft | — | Pending |
| Italian | it | guidebook_it.Rmd | Draft | — | Pending |
| Norwegian | no | guidebook_no.Rmd | Draft | — | Pending |
| Greek | el | guidebook_el.Rmd | Draft | — | Pending |

## ISA User Guide (www/ISA_User_Guide_*.md — 5,224 words)

| Language | Code | File | Status | Reviewer | Date |
|----------|------|------|--------|----------|------|
| English | en | ISA_User_Guide_en.md | Source | — | — |
| Spanish | es | ISA_User_Guide_es.md | Draft | — | Pending |
| French | fr | ISA_User_Guide_fr.md | Draft | — | Pending |
| German | de | ISA_User_Guide_de.md | Draft | — | Pending |
| Lithuanian | lt | ISA_User_Guide_lt.md | Draft | — | Pending |
| Portuguese | pt | ISA_User_Guide_pt.md | Draft | — | Pending |
| Italian | it | ISA_User_Guide_it.md | Draft | — | Pending |
| Norwegian | no | ISA_User_Guide_no.md | Draft | — | Pending |
| Greek | el | ISA_User_Guide_el.md | Draft | — | Pending |

## Status Values

- **Source** — English original (no review needed)
- **Draft** — Machine-translated by Claude AI, disclaimer banner present, pending domain expert review
- **Reviewed** — Domain expert has reviewed and approved, disclaimer banner removed

## How to Review

1. Open the translated file and compare against the English source
2. Check domain-specific terms (DAPSI(W)R(M) framework, marine ecology vocabulary)
3. Fix any translation errors directly in the file
4. Remove the `<div class="alert alert-info">` disclaimer banner
5. Update this table: change Status to "Reviewed", add your name and date
6. Commit and push
```

- [ ] **Step 2: Commit**

```bash
git add translations/guides/REVIEW_STATUS.md
git commit -m "$(cat <<'EOF'
docs: add translation review status checklist

Tracks which user guide translations have been reviewed by domain
experts. All 16 translations (2 files × 8 languages) currently at
Draft status (machine-translated by Claude, disclaimer banner
present). Includes instructions for reviewers.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final Verification

- [ ] **Step 1: Confirm 6 commits**

```bash
git log --oneline origin/main..HEAD | wc -l
```
Expected: `6`.

- [ ] **Step 2: File count check**

```bash
echo "Guidebook Rmd:"; ls guidebook/guidebook_*.Rmd | wc -l
echo "ISA Guide:"; ls www/ISA_User_Guide_*.md | wc -l
echo "Review status:"; ls translations/guides/REVIEW_STATUS.md
```
Expected: `9`, `9`, file exists.

- [ ] **Step 3: i18n audit**

```bash
micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```
Expected: `missing=0 ... hardcoded=0`

- [ ] **Step 4: R syntax check**

```bash
Rscript -e "parse('modules/guidebook_module.R'); parse('modules/isa_data_entry_module.R'); cat('OK\n')"
```
Expected: `OK`

- [ ] **Step 5: Push**

```bash
git push
```

- [ ] **Step 6: Deploy + restart**

```bash
bash deployment/remote-deploy.sh --force
```

Then: `! ssh -t razinka@laguna.ku.lt "sudo systemctl restart shiny-server"`

- [ ] **Step 7: Verify app + guidebook renders (MANUAL)**

Open `https://laguna.ku.lt/marinesabres/` in a browser. Navigate to the Guidebook tab. Confirm:
1. English guidebook renders (default language)
2. Switch language to Spanish (or any translated language) via the language selector
3. After reload, guidebook content is in the selected language
4. The disclaimer banner is visible at the top

- [ ] **Step 8: Verify ISA guide link (MANUAL)**

Navigate to ISA Data Entry → Help button. Confirm the opened `.md` file matches the active language.
