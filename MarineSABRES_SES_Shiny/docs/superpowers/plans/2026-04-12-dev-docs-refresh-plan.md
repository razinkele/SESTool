# Dev Docs Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix verified stale content in 3 developer-facing docs: README.md (test count), CONTRIBUTING.md (7→9 languages, wrong module signature), translations/README.md (7/5→9 languages, old monolithic workflow references).

**Architecture:** 3 independent tasks, each a single commit. Tasks touch disjoint files. All edits are mechanical text corrections — no code changes, no new features, no judgment calls.

**Tech Stack:** Markdown

**Spec source:** `docs/superpowers/specs/2026-04-12-dev-docs-refresh-design.md` (revision 2, verified by adversarial review)

---

## File Map

| Task | File | Edits | Effort |
|------|------|-------|--------|
| 1 | `README.md` | 1 line (test count 56→75) | 5 min |
| 2 | `CONTRIBUTING.md` | 7 edits (4× language count, 1× JSON example, 1× signature, 1× footer) | 15 min |
| 3 | `translations/README.md` | ~10 edits (2× language count, 7× monolithic→modular workflow, 1× version history) | 30 min |

---

### Task 1: Fix README.md test count

**Files:**
- Modify: `README.md:150`

- [ ] **Step 1: Update test count**

**Old:**
```
├── tests/                      # Test suite (56 test files, 4,094+ tests)
```

**New:**
```
├── tests/                      # Test suite (75 test files)
```

Drop the "4,094+ tests" claim — it's unverified and decays on every test addition. The file count (75) was verified via `ls tests/testthat/test-*.R | wc -l` on 2026-04-12.

- [ ] **Step 2: Verify**

```bash
grep -n "56 test" README.md
```
Expected: 0 hits.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: fix README.md test file count 56 → 75

Sprint 2 Task 7 updated CLAUDE.md but missed README.md. Sprint 5
added test-session-logger.R (75th file). Also drops the unverified
"4,094+ tests" assertion count which decays on every test addition.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Fix CONTRIBUTING.md language count + module signature

**Files:**
- Modify: `CONTRIBUTING.md:56, 242-253, 332-346, 468, 643-644`

- [ ] **Step 1: Fix line 56 — "7 languages" → "9 languages"**

**Old:**
```
**CRITICAL**: This application supports 7 languages (English, Spanish, French, German, Lithuanian, Portuguese, Italian). All user-facing text MUST be internationalized.
```

**New:**
```
**CRITICAL**: This application supports 9 languages (English, Spanish, French, German, Lithuanian, Portuguese, Italian, Norwegian, Greek). All user-facing text MUST be internationalized.
```

- [ ] **Step 2: Fix line 242 — "all 7 languages"**

**Old:**
```
4. **Ensure all 7 languages are present**:
```

**New:**
```
4. **Ensure all 9 languages are present**:
```

- [ ] **Step 3: Fix lines 244-253 — JSON example missing `no` and `el` keys**

**Old:**
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

**New:**
```json
   {
     "key": "Please enter a valid email address",
     "en": "Please enter a valid email address",
     "es": "Please enter a valid email address",
     "fr": "Please enter a valid email address",
     "de": "Please enter a valid email address",
     "lt": "Please enter a valid email address",
     "pt": "Please enter a valid email address",
     "it": "Please enter a valid email address",
     "no": "Please enter a valid email address",
     "el": "Please enter a valid email address"
   }
```

- [ ] **Step 4: Fix lines 331-346 — wrong module server signature + parameter order**

**Old:**
```
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
```

**New:**
```
   # Server Function - Standard Pattern
   module_name_server <- function(id, project_data_reactive, i18n,
                                   event_bus = NULL, ...) {
     moduleServer(id, function(input, output, session) {
       # Module logic here
     })
   }
   ```

   **Parameter Order** (in order of importance):
   1. `id` - Module namespace ID (required)
   2. `project_data_reactive` - Reactive project data (required for data modules)
   3. `i18n` - Translation object (required for UI text)
   4. `event_bus` - Event bus for inter-module communication (optional, default NULL)
   5. Additional optional parameters with defaults
```

Note: `session` is NOT a parameter of the server function — it's provided implicitly by Shiny's `moduleServer(id, function(input, output, session) {...})` wrapper. This matches CLAUDE.md's "Module Conventions" section and the actual codebase convention.

- [ ] **Step 5: Fix line 468 — i18n checklist**

**Old:**
```
- [ ] All 7 languages have entries
```

**New:**
```
- [ ] All 9 languages have entries
```

- [ ] **Step 6: Fix lines 643-644 — footer**

**Old:**
```
*Last updated: 2025-11-25*
*i18n Phase 1 Complete - 7 languages supported: en, es, fr, de, lt, pt, it*
```

**New:**
```
*Last updated: 2026-04-12*
*i18n Phase 2 Complete - 9 languages supported: en, es, fr, de, lt, pt, it, no, el*
```

- [ ] **Step 7: Verify all "7 languages" references are gone**

```bash
grep -n "7 languages" CONTRIBUTING.md
```
Expected: 0 hits.

```bash
grep -n "project_data, session, i18n" CONTRIBUTING.md
```
Expected: 0 hits.

- [ ] **Step 8: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "$(cat <<'EOF'
docs: fix CONTRIBUTING.md — 7→9 languages + module signature (I5e)

Four places said "7 languages" — Norwegian and Greek were added
in v1.1 but CONTRIBUTING.md was never updated. Also the JSON
example was missing "no" and "el" keys.

Module server function signature showed (id, project_data, session,
i18n, event_bus) — incorrect: session is implicit via moduleServer,
and the parameter is project_data_reactive (not project_data).
Matches CLAUDE.md "Module Conventions" and actual code convention.

Footer date updated from 2025-11-25 to 2026-04-12.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Fix translations/README.md — language counts + monolithic workflow

**Files:**
- Modify: `translations/README.md` (lines 58, 157, 187, 294, 302, 320, 322, 327, 359, 397)

**Background**: This file extensively references the old monolithic `translations/translation.json` workflow. The app now uses a modular system with 34+ files in `translations/common/`, `translations/modules/`, and `translations/ui/`. The references need to point at the correct modular structure. Also has stale language counts ("7" and "5").

- [ ] **Step 1: Fix line 58 — "7 languages" → "9 languages"**

**Old:**
```
- Prompt for all 7 languages
```

**New:**
```
- Prompt for all 9 languages
```

- [ ] **Step 2: Fix line 157 — "Adding New Translations" step**

**Old:**
```
1. Open `translations/translation.json`
2. Add a new object to the `translation` array:
```

**New:**
```
1. Open the appropriate modular translation file in `translations/common/`, `translations/modules/`, or `translations/ui/`
2. Add a new key inside the `"translation"` object:
```

- [ ] **Step 3: Fix line 187 — "Adding a New Language" header**

**Old:**
```
### Step 1: Update translation.json
```

**New:**
```
### Step 1: Update all modular translation files
```

- [ ] **Step 4: Fix line 294 — troubleshooting**

**Old:**
```
- Verify the translation key exists in `translation.json`
```

**New:**
```
- Verify the translation key exists in the appropriate `translations/**/*.json` file
```

- [ ] **Step 5: Fix line 302 — encoding troubleshooting**

**Old:**
```
- Ensure `translation.json` is saved with UTF-8 encoding
```

**New:**
```
- Ensure all translation JSON files are saved with UTF-8 encoding
```

- [ ] **Step 6: Fix lines 318-322 — developer workflow**

**Old:**
```
1. Write UI/Server code in English
2. Wrap all user-facing text in `i18n$t()`
3. Add English text to `translation.json`
4. Request translations from language experts
5. Update `translation.json` with translations
```

**New:**
```
1. Write UI/Server code in English
2. Wrap all user-facing text in `i18n$t()`
3. Add keys to the appropriate modular file in `translations/common/`, `translations/modules/`, or `translations/ui/`
4. Add all 9 language values (en, es, fr, de, lt, pt, it, no, el)
5. Run `micromamba run -n shiny python scripts/_i18n_audit.py` to verify no missing keys
```

- [ ] **Step 7: Fix lines 327-330 — translator workflow**

**Old:**
```
1. Open `translations/translation.json`
2. Find entries where your language is missing or incorrect
3. Add/update translations
4. Test in the application
```

**New:**
```
1. Open the modular translation files in `translations/common/`, `translations/modules/`, and `translations/ui/`
2. Find entries where your language is missing or incorrect
3. Add/update translations for all 9 languages (en, es, fr, de, lt, pt, it, no, el)
4. Test in the application
```

- [ ] **Step 8: Fix line 359 — files to update reference**

**Old:**
```
- `translations/translation.json` - Translation strings
```

**New:**
```
- `translations/common/*.json`, `translations/modules/*.json`, `translations/ui/*.json` - Modular translation files
```

- [ ] **Step 9: Fix lines 393-397 — version history (remove stale v1.0 line that contradicts v1.1)**

The version history has overlapping/contradictory entries. Line 395 says "9 languages" (correct, v1.1) but line 397 says "5 languages" (stale, v1.0 leftovers that weren't cleaned up when v1.1 was added).

**Old:**
```
- **v1.0** (2025-10-21): Initial internationalization implementation
- **v1.1** (2026-03-15): Added Norwegian and Greek support
  - 9 languages supported (en, es, fr, de, lt, pt, it, no, el)
  - Updated documentation to reflect all supported languages
  - 5 languages supported (en, es, fr, de, pt)
  - Entry Point module fully translated
  - Language selector in header
```

**New:**
```
- **v1.0** (2025-10-21): Initial internationalization implementation
  - 5 languages supported (en, es, fr, de, pt)
  - Entry Point module fully translated
  - Language selector in header
- **v1.1** (2026-03-15): Added Norwegian and Greek support
  - 9 languages supported (en, es, fr, de, lt, pt, it, no, el)
  - Updated documentation to reflect all supported languages
- **v1.2** (2026-04-12): Migrated to modular translation system
  - 34+ modular JSON files in common/, modules/, ui/ subdirectories
  - Automated i18n audit via scripts/_i18n_audit.py
  - All developer/translator workflow docs updated
```

- [ ] **Step 10: Verify no stale references remain**

```bash
grep -n "7 languages" translations/README.md
```
Expected: 0 hits.

```bash
grep -n "5 languages" translations/README.md
```
Expected: 1 hit — the v1.0 version history entry (intentional historical reference).

```bash
grep -n "translation\.json" translations/README.md | grep -v backup | grep -v "v1\.0"
```
Expected: 0 hits (only the backup reference at line 30 and historical v1.0 mention remain).

- [ ] **Step 11: Commit**

```bash
git add translations/README.md
git commit -m "$(cat <<'EOF'
docs: fix translations/README.md — modular workflow + language counts

The translations README extensively referenced the old monolithic
translations/translation.json workflow, which was replaced by the
modular system (34+ files in common/, modules/, ui/) months ago.

Updated:
- "7 languages" → "9 languages" (line 58)
- "5 languages" stale v1.0 entry separated from v1.1 in version history
- All developer/translator workflow instructions now reference the
  modular file structure instead of translation.json
- Added v1.2 entry documenting the modular migration and i18n audit
- Troubleshooting references point at translations/**/*.json files

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final Verification

- [ ] **Step 1: Confirm 3 new commits**

```bash
git log --oneline origin/main..HEAD | wc -l
```
Expected: `3`.

- [ ] **Step 2: Run all verification greps**

```bash
grep -c "56 test" README.md
grep -c "7 languages" CONTRIBUTING.md
grep -c "project_data, session, i18n" CONTRIBUTING.md
grep -c "7 languages" translations/README.md
```
Expected: all `0`.

- [ ] **Step 3: Push**

```bash
git push
```

No deploy needed — these are developer-facing docs, not runtime code.
