# Dev Docs Refresh Design (revision 2 — verified)

**Status**: Revision 2, 2026-04-12 (after adversarial review found 3 phantom fixes and 5 missed items)
**Scope**: Subsystem A — fix verified stale content in 3 developer-facing docs.

## Problem

After 5 sprints of code changes, three developer-facing documents have drifted:

1. **README.md** — test file count is stale (says 56, actual 74).
2. **CONTRIBUTING.md** — says "7 languages" in 4 places (actual: 9), shows wrong module server signature and parameter order, JSON example missing 2 language keys.
3. **translations/README.md** — extensively references the old monolithic `translation.json` workflow (replaced by the modular 34-file system months ago), says "5 languages" in footer, says "7 languages" in one place.

### What is NOT stale (confirmed by review)

- README.md "7 pre-built templates" — **correct** (7 template JSON files exist, names match).
- README.md `timevis` — **already removed** in Sprint 3 Task 2.
- translations/README.md line 395 — **already says "9 languages"**. But line 397 says "5 languages" (stale from v1.0).

## Changes (all verified by grep on 2026-04-12)

### README.md — 1 fix

| Line | Current | Correct | Source |
|------|---------|---------|--------|
| 150 | `tests/ # Test suite (56 test files, 4,094+ tests)` | `tests/ # Test suite (75 test files)` | `ls tests/testthat/test-*.R \| wc -l` = 75 (Sprint 5 added test-session-logger.R; Sprint 2 Task 7 updated CLAUDE.md to 74 but not README.md) |

### CONTRIBUTING.md — 7 fixes

| Line(s) | Current | Correct | Source |
|---------|---------|---------|--------|
| 56 | "supports 7 languages (English, Spanish, French, German, Lithuanian, Portuguese, Italian)" | "supports 9 languages (English, Spanish, French, German, Lithuanian, Portuguese, Italian, Norwegian, Greek)" | CLAUDE.md; global.R i18n setup |
| 242 | "Ensure all 7 languages are present" | "Ensure all 9 languages are present" | same |
| 245-252 | JSON example has 7 keys: en, es, fr, de, lt, pt, it | Add `"no"` and `"el"` keys | same |
| 332-333 | `module_name_server <- function(id, project_data, session, i18n, event_bus = NULL, ...)` | `module_name_server <- function(id, project_data_reactive, i18n, event_bus = NULL, ...)` | CLAUDE.md "Module Conventions"; `session` is implicit via `moduleServer(id, function(input, output, session) {...})` |
| 340-346 | Parameter order lists `session` as #3 | Remove `session` from the list; rename `project_data` → `project_data_reactive` | Same; verified against actual modules |
| 468 | "All 7 languages have entries" | "All 9 languages have entries" | same |
| 643-644 | "Last updated: 2025-11-25" + "7 languages supported: en, es, fr, de, lt, pt, it" | Update date to 2026-04-12 + "9 languages supported: en, es, fr, de, lt, pt, it, no, el" | same |

### translations/README.md — many fixes (2 categories)

**Category 1: Language count fixes (3 lines)**

| Line | Current | Correct |
|------|---------|---------|
| 58 | "Prompt for all 7 languages" | "Prompt for all 9 languages" |
| 397 | "5 languages supported (en, es, fr, de, pt)" | "9 languages supported (en, es, fr, de, lt, pt, it, no, el)" |

**Category 2: Monolithic `translation.json` references (8+ lines)**

Lines 157, 187, 294, 302, 320, 322, 327, 359 all reference `translations/translation.json` — the old monolithic file that was replaced by the modular system (`translations/common/*.json`, `translations/modules/*.json`, `translations/ui/*.json`). These appear in the "Adding New Translations," "Adding a New Language," "For Translators," and troubleshooting sections.

**Approach**: Replace each `translation.json` reference with the correct modular workflow: "add the key to the appropriate file in `translations/common/`, `translations/modules/`, or `translations/ui/`." For the "Adding New Translations" walkthrough (lines 157+), rewrite the steps to reflect the current process (which is also documented in CLAUDE.md and `scripts/add_translation.R`).

Do NOT rewrite the entire README from scratch — only update the sections that reference the old monolithic workflow. Preserve structure, headings, and any content that is still accurate.

## Verification

After all edits:

```bash
grep -n "7 languages" CONTRIBUTING.md                    # expect: 0 hits
grep -n "5 languages" translations/README.md              # expect: 0 hits
grep -n "56 test" README.md                               # expect: 0 hits
grep -n "translation\.json" translations/README.md        # expect: only line 30 (backup reference, intentional)
grep -n "project_data, session, i18n" CONTRIBUTING.md     # expect: 0 hits (old wrong signature)
```

## Effort estimate

- README.md: 5 min (1 line edit)
- CONTRIBUTING.md: 15 min (7 targeted edits)
- translations/README.md: 30 min (language count fixes + monolithic workflow rewrite)
- Total: ~50 min

## Non-goals

- No changes to CLAUDE.md (refreshed in Sprint 2 Task 7)
- No changes to DAPSIWRM_FRAMEWORK_RULES.md (current per audit)
- No changes to tests/README.md (current per audit)
- No CONTRIBUTING.md style guide rewrites (camelCase examples at lines 73, 84 are out of scope — cosmetic, not factually wrong)
- No new content creation — this is pure drift correction
