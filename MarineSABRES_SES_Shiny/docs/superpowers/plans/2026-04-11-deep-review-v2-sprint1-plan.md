# Deep Review v2 — Sprint 1 Critical Fixes Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Fix 5 critical issues + 2 minor doc fixes from Deep Review v2, plus add a "Recent Autosaves" UI for manual recovery.

**Architecture:** 8 independent tasks, each a single commit. No shared files between tasks (can run in parallel after Task 1).

**Tech Stack:** R, GitHub Actions YAML, JSON translations, JavaScript

**Source report:** `.claude/skills/scientific-validation-workspace/codebase-audit/DEEP-REVIEW-V2-MASTER.md`

---

## File Map

| Task | Issue | File | Effort |
|------|-------|------|--------|
| 1 | C1 | `.github/workflows/i18n-validation.yml` | 15 min |
| 2 | C2 | `modules/ai_isa_assistant_module.R` + `translations/modules/isa_data_entry.json` | 15 min |
| 3 | C3 | `modules/local_storage_module.R` | 30 min |
| 4 | C4 | `DESCRIPTION` | 5 min |
| 5 | C5 | 8 files — replace bare `readRDS` with `safe_readRDS` or add NULL checks | 45 min |
| 6 | I5d | `functions/network_analysis.R` roxygen comment | 2 min |
| 7 | I5f | `.claude/skills/scientific-validation/SKILL.md` | 10 min |
| 8 | Feature | Recent Autosaves UI (sidebar button + modal + handler) | ~60 min |

---

### Task 1: Fix broken CI workflow (C1)

**Files:**
- Modify: `.github/workflows/i18n-validation.yml`

The workflow references `scripts/report_missing_keys.R` and `scripts/check_loader_missing.R` which don't exist. Replace with our new `scripts/_i18n_audit.py`.

- [ ] **Step 0: Pre-check — confirm `translation-reports` artifact name isn't referenced elsewhere**

```bash
grep -rn "translation-reports" .github/ docs/ scripts/ 2>/dev/null
```

Expected: only one hit — `.github/workflows/i18n-validation.yml` itself. If other files reference this artifact name, update them to `i18n-audit-report` (the new artifact name) as part of this task.

- [ ] **Step 1: Replace the R-specific steps with the Python audit**

In `.github/workflows/i18n-validation.yml`, replace **lines 22-64** inclusive — from `- name: Setup R` through the end of `- name: Fail on missing keys`. Do NOT touch lines 1-21 (header, concurrency, job/env setup, and `actions/checkout@v4`) or the `i18n-tests` job at lines 66+. Also remove the top-level `env: R_LIBS_USER: ...` block at lines 17-18 from the `validate-translations` job, since it's no longer needed.

The new block uses Python instead of R for the audit, and fails if missing/hardcoded keys > 0:

```yaml
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Run i18n audit
        run: |
          set -e
          python scripts/_i18n_audit.py

      - name: Upload audit report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: i18n-audit-report
          path: .claude/skills/scientific-validation-workspace/codebase-audit/i18n-audit-report.md

      - name: Fail on missing or hardcoded keys
        run: |
          set -e
          REPORT=".claude/skills/scientific-validation-workspace/codebase-audit/i18n-audit-report.md"
          if [ ! -f "$REPORT" ]; then
            echo "Audit report not found"
            exit 1
          fi
          TOTALS=$(grep -E "^Totals:" "$REPORT" | head -1)
          echo "$TOTALS"
          if echo "$TOTALS" | grep -qE "missing=[1-9][0-9]*"; then
            echo "ERROR: Missing i18n keys detected"
            cat "$REPORT"
            exit 1
          fi
          if echo "$TOTALS" | grep -qE "hardcoded=[1-9][0-9]*"; then
            echo "ERROR: Hardcoded strings detected"
            cat "$REPORT"
            exit 1
          fi
          echo "i18n audit passed: $TOTALS"
```

Remove the R setup steps (Setup R, Cache R packages, Install required R packages) from the `validate-translations` job since we're using Python now. Keep the `i18n-tests` job unchanged (it runs testthat and is a separate concern).

Also remove the cache step since Python audit is fast without caching.

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/i18n-validation.yml
git commit -m "$(cat <<'EOF'
fix: replace broken CI i18n validation with Python audit (C1)

The workflow referenced scripts/report_missing_keys.R and
scripts/check_loader_missing.R which never existed in the repo —
CI has been silently failing on every push since the workflow
was introduced.

Replace with the new scripts/_i18n_audit.py added in this session.
The Python script scans all i18n\$t() calls + validate_translation_
completeness critical keys, then fails the build if missing or
hardcoded > 0.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Wrap missed hardcoded strings in ai_isa (C2)

**Files:**
- Modify: `modules/ai_isa_assistant_module.R:1405,1411`
- Modify: `translations/modules/isa_data_entry.json`

- [ ] **Step 1: Wrap the 2 section headers**

In `modules/ai_isa_assistant_module.R`, lines 1405 and 1411, replace:

```r
                  h6(style = "font-weight: 600; color: #28a745; margin-top: 10px;", "EU Member States"),
```

with:

```r
                  h6(style = "font-weight: 600; color: #28a745; margin-top: 10px;", i18n$t("modules.isa.ai_assistant.eu_member_states")),
```

And:

```r
                  h6(style = "font-weight: 600; color: #6c757d; margin-top: 10px;", "Non-EU Countries"),
```

with:

```r
                  h6(style = "font-weight: 600; color: #6c757d; margin-top: 10px;", i18n$t("modules.isa.ai_assistant.non_eu_countries")),
```

- [ ] **Step 2: Add 2 translation keys**

In `translations/modules/isa_data_entry.json`, add these two keys inside the `"translation"` object. Find a safe insertion point (near other `modules.isa.ai_assistant.*` keys) and add with proper comma placement:

```json
    "modules.isa.ai_assistant.eu_member_states": {
      "en": "EU Member States",
      "es": "Estados miembros de la UE",
      "fr": "États membres de l'UE",
      "de": "EU-Mitgliedstaaten",
      "lt": "ES valstybės narės",
      "pt": "Estados-Membros da UE",
      "it": "Stati membri dell'UE",
      "no": "EU-medlemsland",
      "el": "Κράτη μέλη της ΕΕ"
    },
    "modules.isa.ai_assistant.non_eu_countries": {
      "en": "Non-EU Countries",
      "es": "Países no pertenecientes a la UE",
      "fr": "Pays hors UE",
      "de": "Nicht-EU-Länder",
      "lt": "Ne ES šalys",
      "pt": "Países não-UE",
      "it": "Paesi non UE",
      "no": "Ikke-EU-land",
      "el": "Χώρες εκτός ΕΕ"
    },
```

- [ ] **Step 3: Verify JSON is valid**

```bash
micromamba run -n shiny python -c "import json; json.load(open('translations/modules/isa_data_entry.json')); print('Valid')"
```

Expected: `Valid`

- [ ] **Step 4: Run i18n audit to verify no regressions**

```bash
micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```

Expected: `missing=0  unused=... incomplete=0  hardcoded=0`

- [ ] **Step 5: Commit**

```bash
git add modules/ai_isa_assistant_module.R translations/modules/isa_data_entry.json
git commit -m "$(cat <<'EOF'
fix: wrap 2 missed hardcoded strings in country selector (C2)

"EU Member States" and "Non-EU Countries" section headers at lines
1405 and 1411 were hardcoded English. The previous Quick Wins plan
caught the tooltip at line 1357 but missed these display headers.

Adds 2 translation keys in all 9 languages.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Fix IndexedDB cross-session handle leak (C3)

**Files:**
- Modify: `modules/local_storage_module.R`

The File System Access API handle is stored in IndexedDB under a fixed key `"projectDirectory"`. If multiple users share a browser profile, User B could retrieve User A's saved handle. The fix: always verify the handle permission is still granted before use, and clear it if not.

Note: The browser's FSA API already requires user re-consent on most operations, so this isn't a silent leak in the strict sense — but verifying permission state explicitly makes the security model visible and prevents using a stale handle.

- [ ] **Step 1: Add permission verification to `getSavedDirectoryHandle`**

In `modules/local_storage_module.R`, find the `getSavedDirectoryHandle` function (around line 287-312). Replace the entire function with:

```javascript
      // Helper: Get saved directory handle from IndexedDB.
      // Verifies permission is still granted before returning — this prevents
      // silently reusing a handle from a previous user on a shared browser.
      async function getSavedDirectoryHandle() {
        return new Promise((resolve, reject) => {
          const request = indexedDB.open("MarineSABRES_LocalStorage", 1);

          request.onupgradeneeded = (event) => {
            const db = event.target.result;
            if (!db.objectStoreNames.contains("handles")) {
              db.createObjectStore("handles", {keyPath: "id"});
            }
          };

          request.onsuccess = async (event) => {
            const db = event.target.result;
            const tx = db.transaction("handles", "readonly");
            const store = tx.objectStore("handles");
            const getRequest = store.get("projectDirectory");

            getRequest.onsuccess = async () => {
              const handle = getRequest.result ? getRequest.result.handle : null;
              if (!handle) {
                resolve(null);
                return;
              }
              // Verify permission is still granted (non-silent)
              try {
                const perm = await handle.queryPermission({mode: "readwrite"});
                if (perm === "granted") {
                  resolve(handle);
                } else {
                  // Permission revoked or not granted — clear stale handle
                  // and force the user to re-select the directory
                  console.log("[local_storage] Stored handle permission not granted, clearing");
                  const clearTx = db.transaction("handles", "readwrite");
                  const clearStore = clearTx.objectStore("handles");
                  clearStore.delete("projectDirectory");
                  resolve(null);
                }
              } catch (err) {
                console.error("[local_storage] Permission check failed:", err);
                resolve(null);
              }
            };
            getRequest.onerror = () => resolve(null);
          };

          request.onerror = () => resolve(null);
        });
      }
```

- [ ] **Step 2: Commit**

```bash
git add modules/local_storage_module.R
git commit -m "$(cat <<'EOF'
fix: verify FSA handle permission before reuse (C3)

The File System Access API directory handle was retrieved from
IndexedDB without verifying its permission state. On shared browsers
this could result in using a stale handle from a previous user.

Fix: call handle.queryPermission({mode: 'readwrite'}) before returning
from getSavedDirectoryHandle(). If permission is not granted (revoked,
expired, or from another user session), clear the stored handle and
force re-selection.

This is belt-and-suspenders — the browser's FSA security model
typically prompts for re-consent anyway — but makes the check
explicit and handles the edge case cleanly.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Add `officer` and `flextable` to DESCRIPTION (C4)

**Files:**
- Modify: `DESCRIPTION`

- [ ] **Step 1: Add imports**

In `DESCRIPTION`, find the `Imports:` section (starts at line 12). Add `officer` and `flextable` alphabetically in the list. The current section ends with `htmltools` on line 38. Replace lines 12-38 with:

```
Imports:
    shiny,
    bs4Dash,
    shinyWidgets,
    shinyjs,
    shinyBS,
    shinyFiles,
    tidyverse,
    DT,
    openxlsx,
    readxl,
    httr,
    jsonlite,
    digest,
    igraph,
    visNetwork,
    ggraph,
    tidygraph,
    ggplot2,
    plotly,
    dygraphs,
    xts,
    timevis,
    rmarkdown,
    htmlwidgets,
    shiny.i18n,
    htmltools,
    officer,
    flextable
```

- [ ] **Step 2: Commit**

```bash
git add DESCRIPTION
git commit -m "$(cat <<'EOF'
chore: add officer and flextable to DESCRIPTION Imports (C4)

These packages are used in 129 places across response_module.R,
prepare_report_module.R, pims_stakeholder_module.R, and analysis_loops.R
for Word/PowerPoint export and rich table formatting. They were
declared in install_dependencies.R and Dockerfile but missing from
DESCRIPTION, which would cause devtools::check() and pkgload validation
to fail in clean environments.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Replace unsafe readRDS calls with safe_readRDS (C5)

**Files:**
- Modify: `functions/template_versioning.R`
- Modify: `functions/ml_feedback_logger.R`
- Modify: `functions/ml_ensemble.R`
- Modify: `functions/persistent_storage.R`
- Modify: `modules/auto_save_module.R`

The project has a `safe_readRDS` helper in `functions/utils.R:440` (signature: `safe_readRDS(file, max_size_mb = 50)`) that returns NULL on error instead of crashing. 8 places still use bare `readRDS` followed by immediate field access, which crashes with "$ operator is invalid for atomic vectors" or "NULL subset" errors when files are corrupt/missing.

The fix pattern: replace `readRDS(path)` with `safe_readRDS(path)` AND add an explicit NULL check before accessing fields. `safe_readRDS` is sourced via `functions/utils.R` (already loaded by `global.R`).

**NOTE on context**: Not all affected functions run inside Shiny reactive contexts. `delete_version()` in template_versioning.R is a plain CLI helper using `message()`/`readline()` — it has NO `i18n` parameter and cannot call `showNotification()`. For non-Shiny contexts, use `warning()` + `return(FALSE)` instead.

- [ ] **Step 1: Fix `functions/template_versioning.R:135`**

Read the file around line 135 to see the context. It should be `metadata <- readRDS(filepath)` followed by `if (!inherits(metadata, "template_version"))`. Replace with:

```r
  metadata <- safe_readRDS(filepath)
  if (is.null(metadata)) return(NULL)
  if (!inherits(metadata, "template_version")) {
```

- [ ] **Step 2: Fix `functions/template_versioning.R:188`**

Line 188 is inside a `for (file in files)` loop wrapped in `tryCatch`. **Do NOT use `return(NULL)`** — that would abort the entire `get_version_history()` function on the first bad file, skipping all remaining files. Use `next` to skip the iteration instead.

```r
# BEFORE (line 188):
      meta <- readRDS(file)

# AFTER:
      meta <- safe_readRDS(file)
      if (is.null(meta)) next
```

The existing `tryCatch` error handler remains as a safety net for parser errors. The `safe_readRDS` + `next` adds a non-crashing path for NULL/missing files.

- [ ] **Step 3: Fix `functions/template_versioning.R:372`**

Line 372 is inside `delete_version(version_path, confirm = TRUE)` — a plain R helper function used in CLI context, NOT Shiny. It uses `message()` and `readline()` for interaction. There is no `i18n` in scope and no `showNotification` available. Use `warning()` + `return(FALSE)` to match the existing function's style (see line 367-368 which already uses this pattern for the "file not found" case).

```r
# BEFORE (line 372):
    meta <- readRDS(version_path)

# AFTER:
    meta <- safe_readRDS(version_path)
    if (is.null(meta)) {
      warning("Version file could not be read: ", version_path)
      return(FALSE)
    }
```

- [ ] **Step 4: Fix `functions/ml_feedback_logger.R:457`**

The `feedback_log <- read_feedback_cached()` call can return NULL. Add a guard:

```r
  feedback_log <- read_feedback_cached()
  if (is.null(feedback_log) || nrow(feedback_log) == 0) {
    return(list(retrain_needed = FALSE, reason = "no feedback data"))
  }
```

- [ ] **Step 5: Fix `functions/ml_ensemble.R:54`**

```r
# BEFORE:
ensemble_env$metadata <- readRDS(metadata_path)
n_models <- ensemble_env$metadata$n_models

# AFTER:
ensemble_env$metadata <- safe_readRDS(metadata_path)
if (is.null(ensemble_env$metadata)) {
  warning("ML ensemble metadata could not be loaded from ", metadata_path)
  return(NULL)
}
n_models <- ensemble_env$metadata$n_models
```

- [ ] **Step 6: Fix `functions/persistent_storage.R:171,449`**

Both lines are `readRDS` calls inside tryCatch blocks. The tryCatch already handles failures, but if readRDS succeeds with a corrupt file (returns unexpected type), field access can still fail. Add explicit validation after each `readRDS`:

At line 171 (config_path):
```r
      config <- readRDS(config_path)
      if (!is.list(config)) {
        debug_log("Invalid config file format, ignoring", "PERSISTENT_STORAGE")
        return(NULL)
      }
```

At line 449 (project file):
```r
      project_data <- readRDS(file_path)
      if (!is.list(project_data)) {
        debug_log(paste("Invalid project file format:", file_path), "PERSISTENT_STORAGE")
        return(NULL)
      }
```

- [ ] **Step 7: Fix `modules/auto_save_module.R:1002`**

```r
# BEFORE:
recovered_data <- safe_readRDS(latest_file)
recovered_data$autosave_metadata <- NULL
# ... access recovered_data$data$isa_data etc.

# AFTER:
recovered_data <- safe_readRDS(latest_file)
if (is.null(recovered_data) || !is.list(recovered_data)) {
  showNotification(
    i18n$t("common.messages.error"),
    type = "error"
  )
  debug_log(paste("Auto-save recovery failed: could not read", latest_file), "AUTO_SAVE")
  return()
}
recovered_data$autosave_metadata <- NULL
```

- [ ] **Step 8: Verify nothing broke**

```bash
Rscript -e "source('functions/utils.R'); source('functions/template_versioning.R'); source('functions/ml_feedback_logger.R'); source('functions/ml_ensemble.R'); source('functions/persistent_storage.R'); cat('OK\n')" 2>&1 | tail -5
```

Note: `functions/utils.R` (not `error_handling.R`) is where `safe_readRDS` is defined. It must be sourced first so the other files can reference it.

Expected: `OK` (may have harmless package warnings).

- [ ] **Step 9: Commit**

```bash
git add functions/template_versioning.R functions/ml_feedback_logger.R functions/ml_ensemble.R functions/persistent_storage.R modules/auto_save_module.R
git commit -m "$(cat <<'EOF'
fix: guard against NULL returns from readRDS (C5)

8 places called readRDS() and immediately accessed fields on the
result. If the file is missing, corrupt, or wrong type, the code
crashes with "NULL is not subsettable" or "invalid for atomic
vectors".

Fix pattern: use safe_readRDS() (returns NULL on error) and add
explicit NULL checks before field access. For readRDS() calls
already inside tryCatch, added is.list() validation to catch wrong
types.

Affected files:
- functions/template_versioning.R (3 sites)
- functions/ml_feedback_logger.R (1 site)
- functions/ml_ensemble.R (1 site)
- functions/persistent_storage.R (2 sites)
- modules/auto_save_module.R (1 site)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Update roxygen comment "17 rules" → "18 rules" (I5d)

**Files:**
- Modify: `functions/network_analysis.R`

- [ ] **Step 1: Update the comment**

In `functions/network_analysis.R`, find the roxygen comment block for `is_valid_dapsirwrm_transition` (around line 340). The current line says "Implements all 17 rules from DAPSIWRM_FRAMEWORK_RULES.md." Replace with:

```r
#' Implements all 18 rules from DAPSIWRM_FRAMEWORK_RULES.md plus the ExUP
#' exception (D → P for exogenic unmanaged pressures like climate change).
```

- [ ] **Step 2: Commit**

```bash
git add functions/network_analysis.R
git commit -m "$(cat <<'EOF'
docs: correct roxygen comment — 17 rules → 18 rules + ExUP (I5d)

The comment block on is_valid_dapsirwrm_transition said "all 17 rules"
but Rule 18 (A→A) was added earlier in this session. The ExUP
exception (D→P) is also not a numbered rule but is implemented.
Clarify both.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Update scientific-validation SKILL.md Known Gaps (I5f)

**Files:**
- Modify: `.claude/skills/scientific-validation/SKILL.md`

The skill's "Known Gaps as of 2026-04-10" section lists 5 transitions as "documented, not yet fixed" that ARE now fixed. Update to reflect current state.

- [ ] **Step 1: Update the Known Gaps section**

Read `.claude/skills/scientific-validation/SKILL.md` and find the "Known Gaps" table (around line 188). Replace the entire table with:

```markdown
## Known Gaps (as of 2026-04-11)

The following gaps from earlier reviews have been **RESOLVED**:

| Gap | Status | Resolution |
|-----|--------|-----------|
| R→C/S (Rule 12) | ✅ Fixed | Added to validator 2026-04-10 |
| C/S→C/S (Rule 16) | ✅ Fixed | Added 2026-04-10 |
| R→R (Rule 14) | ✅ Fixed | Added 2026-04-10 |
| P→P (Rule 17) | ✅ Fixed | Added 2026-04-10 (cumulative effects) |
| M→R (Rule 13) | ✅ Fixed | Added 2026-04-10 |
| A→A (Rule 18) | ✅ Fixed | Added 2026-04-11 (MSP extension) |
| D→P (ExUP exception) | ✅ Fixed | Added 2026-04-11 (climate change) |

The validator now has **23 valid transitions** covering Rules 1-18 + ExUP. Full polarity scan on both KBs shows 0 invalid transitions.

### Remaining Gaps

- **HW collapsed into GB in 7-element model** (`constants.R:129-137`). By design — the toolbox uses a 7-element simplification of the 9-element framework. HW→R and HW→D pathways are represented via GB.
- **11 research/monitoring elements flagged** as Activities may belong as Responses (domain expert review needed). See `scripts/kb_audit/output/ses_knowledge_db_audit.md`.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scientific-validation/SKILL.md
git commit -m "$(cat <<'EOF'
docs: update SKILL.md Known Gaps — all 5 transitions now fixed (I5f)

The Known Gaps section listed R→C/S, C/S→C/S, R→R, P→P, M→R as
"documented, not yet fixed" — but they were all added to the validator
on 2026-04-10 and A→A + ExUP exception were added 2026-04-11. Update
to reflect current state (23 valid transitions).

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Recent Autosaves UI

**Files:**
- Modify: `functions/ui_sidebar.R` (add sidebar button)
- Modify: `server/project_io.R` (add modal + handler)
- Modify: `translations/common/buttons.json` (add button label)
- Modify: `translations/modules/auto_save.json` (add modal text)
- Modify: `translations/ui/sidebar.json` (add tooltip text)

**Background**: Autosave files live at `~/Documents/MarineSABRES_Projects/.autosave/autosave_<session_id>.rds` (local mode) or in `tempdir()/marinesabres_autosave/<session_id>/` (session-scoped). The existing automatic recovery modal only offers the most recent file within 72 hours, and there's no UI to browse older autosaves or select a specific one. This task adds a browsable list.

**Scope (minimal)**:
- New "Recent Autosaves" button next to "Load Project" in the sidebar
- Click opens a modal showing files from `.autosave/` folder sorted by modification time (newest first)
- Each row shows: relative time (e.g., "2 hours ago"), filename, size, [Load] button
- Clicking [Load] calls the same load logic as "Load Project" and closes the modal
- If no autosaves found, modal shows "No recoverable autosaves found" message
- Uses existing `find_recoverable_autosaves()` helper with extended age window

**NOT in scope** (keep it YAGNI):
- Delete/rename operations
- Preview of autosave contents
- Multi-file selection
- Cross-machine sync

- [ ] **Step 1: Add the sidebar button**

In `functions/ui_sidebar.R`, find the block of 4 quick-action buttons (around line 480). After the `load_project` button (ends around line 496), insert a new button:

```r
        actionButton(
          inputId = "recent_autosaves",
          label = tagList(icon("history"), tags$span(class = "btn-text", safe_t("common.buttons.recent_autosaves", i18n_obj = i18n))),
          class = "btn-outline-primary quick-action-btn",
          title = safe_t("ui.sidebar.recent_autosaves_tooltip", i18n_obj = i18n)
        ),
```

**Note**: Using `icon("history")` instead of `clock-rotate-left` because `history` is an alias that works in both Font Awesome 5 and 6. Avoids version-specific dependency.

Place it between `load_project` and the `tags$div(id = "local_storage_buttons", ...)` block.

- [ ] **Step 2: Add the modal + handler in server/project_io.R**

**IMPORTANT scope notes** (verified against current code):
- The `observeEvent` blocks live inside the `setup_project_io_handlers <- function(input, output, session, project_data, i18n) { ... }` function body (around line 18 start, line 288 end). The new handler must be added INSIDE this function, before the closing brace.
- `event_bus` is **NOT in scope** in this function — do NOT call `event_bus$emit_isa_change()`. The existing `confirm_load` handler at lines ~119-131 works without an emit because downstream modules observe `project_data()` directly. Match that pattern.
- `project_data` is a reactive passed as a parameter — use `project_data(loaded_data)` to write.

In `server/project_io.R`, find the end of the existing `observeEvent(input$load_project, {...})` handler. After it (still inside `setup_project_io_handlers`), add a new handler for the recent autosaves button:

```r
  # Recent Autosaves browser — show list of persistent autosave files
  observeEvent(input$recent_autosaves, {
    # Use existing helper with extended window (30 days) to show older files too
    autosaves <- tryCatch(
      find_recoverable_autosaves(max_age_hours = 24 * 30),
      error = function(e) data.frame()
    )

    if (nrow(autosaves) == 0) {
      showModal(modalDialog(
        title = i18n$t("modules.auto_save.recent_autosaves_title"),
        i18n$t("modules.auto_save.no_recent_autosaves"),
        easyClose = TRUE,
        footer = modalButton(i18n$t("common.buttons.close"))
      ))
      return()
    }

    # Sort newest first
    autosaves <- autosaves[order(autosaves$modified, decreasing = TRUE), ]

    # Build the list of entries
    entries <- lapply(seq_len(nrow(autosaves)), function(i) {
      row <- autosaves[i, ]
      age_secs <- as.numeric(difftime(Sys.time(), row$modified, units = "secs"))
      age_text <- if (age_secs < 3600) {
        sprintf(i18n$t("modules.auto_save.minutes_ago"), round(age_secs / 60))
      } else if (age_secs < 86400) {
        sprintf(i18n$t("modules.auto_save.hours_ago"), round(age_secs / 3600))
      } else {
        sprintf(i18n$t("modules.auto_save.days_ago"), round(age_secs / 86400))
      }
      filename <- basename(row$path)
      size_text <- sprintf("%.1f KB", row$size_kb)
      # Use jsonlite to produce a properly-escaped JS string literal —
      # handles backslashes, quotes, and unicode correctly
      js_path <- jsonlite::toJSON(row$path, auto_unbox = TRUE)

      div(
        class = "autosave-entry",
        style = "padding: 8px; margin-bottom: 4px; border: 1px solid #ddd; border-radius: 4px; display: flex; justify-content: space-between; align-items: center;",
        div(
          tags$strong(age_text),
          tags$br(),
          tags$small(style = "color: #666;", paste(filename, "·", size_text))
        ),
        tags$button(
          type = "button",
          class = "btn btn-sm btn-primary",
          onclick = sprintf("Shiny.setInputValue('selected_autosave_path', %s, {priority: 'event'})", js_path),
          i18n$t("common.buttons.load")
        )
      )
    })

    showModal(modalDialog(
      title = i18n$t("modules.auto_save.recent_autosaves_title"),
      size = "l",
      div(
        p(i18n$t("modules.auto_save.recent_autosaves_description")),
        do.call(tagList, entries)
      ),
      easyClose = TRUE,
      footer = modalButton(i18n$t("common.buttons.close"))
    ))
  })

  # Handle loading a selected autosave file
  observeEvent(input$selected_autosave_path, {
    file_path <- input$selected_autosave_path
    if (is.null(file_path) || !file.exists(file_path)) {
      showNotification(
        i18n$t("modules.auto_save.autosave_not_found"),
        type = "error"
      )
      return()
    }

    tryCatch({
      # Reuse safe_readRDS with size limit
      loaded_data <- safe_readRDS(file_path, max_size_mb = 50)
      if (is.null(loaded_data)) {
        showNotification(
          i18n$t("modules.auto_save.autosave_load_failed"),
          type = "error"
        )
        return()
      }

      # Strip autosave_metadata before applying (it's internal state)
      if (is.list(loaded_data) && !is.null(loaded_data$autosave_metadata)) {
        loaded_data$autosave_metadata <- NULL
      }

      # Apply to project_data reactive.
      # Note: downstream modules observe project_data() directly, so no
      # explicit event_bus emit is needed (matches confirm_load handler).
      # event_bus is not in scope in setup_project_io_handlers anyway.
      project_data(loaded_data)

      removeModal()
      showNotification(
        i18n$t("modules.auto_save.autosave_loaded_successfully"),
        type = "message"
      )
    }, error = function(e) {
      showNotification(
        format_user_error(e, i18n = i18n, context = "loading autosave"),
        type = "error"
      )
    })
  })
```

**Note**: `project_data` is in the enclosing `setup_project_io_handlers` scope (same as the existing `observeEvent(input$load_project, ...)` handler). `event_bus` is intentionally not used here — see the scope note at the top of Step 2.

- [ ] **Step 3: Add translation keys**

Add to `translations/common/buttons.json` inside the `"translation"` object. **Only 1 new key** — `common.buttons.close` (line 69) and `common.buttons.load` (line 201) already exist, do NOT re-add:

```json
    "common.buttons.recent_autosaves": {
      "en": "Recent Autosaves",
      "es": "Autoguardados recientes",
      "fr": "Sauvegardes automatiques récentes",
      "de": "Letzte automatische Speicherungen",
      "lt": "Naujausi automatiniai išsaugojimai",
      "pt": "Salvamentos automáticos recentes",
      "it": "Salvataggi automatici recenti",
      "no": "Nylige autolagringer",
      "el": "Πρόσφατες αυτόματες αποθηκεύσεις"
    },
```

Add to `translations/modules/auto_save.json` inside the `"translation"` object:

```json
    "modules.auto_save.recent_autosaves_title": {
      "en": "Recent Autosaves",
      "es": "Autoguardados recientes",
      "fr": "Sauvegardes automatiques récentes",
      "de": "Letzte automatische Speicherungen",
      "lt": "Naujausi automatiniai išsaugojimai",
      "pt": "Salvamentos automáticos recentes",
      "it": "Salvataggi automatici recenti",
      "no": "Nylige autolagringer",
      "el": "Πρόσφατες αυτόματες αποθηκεύσεις"
    },
    "modules.auto_save.recent_autosaves_description": {
      "en": "Select an autosave to restore. Files are sorted newest first.",
      "es": "Selecciona un autoguardado para restaurar. Los archivos se ordenan del más reciente al más antiguo.",
      "fr": "Sélectionnez une sauvegarde automatique à restaurer. Les fichiers sont triés du plus récent au plus ancien.",
      "de": "Wählen Sie eine automatische Speicherung zum Wiederherstellen. Dateien sind nach Neuheit sortiert.",
      "lt": "Pasirinkite automatinį išsaugojimą atkūrimui. Failai rūšiuojami nuo naujausio.",
      "pt": "Selecione um salvamento automático para restaurar. Os arquivos são ordenados do mais recente ao mais antigo.",
      "it": "Seleziona un salvataggio automatico da ripristinare. I file sono ordinati dal più recente al più vecchio.",
      "no": "Velg en autolagring å gjenopprette. Filer er sortert etter nyeste først.",
      "el": "Επιλέξτε μια αυτόματη αποθήκευση για επαναφορά. Τα αρχεία ταξινομούνται από τα νεότερα προς τα παλαιότερα."
    },
    "modules.auto_save.no_recent_autosaves": {
      "en": "No recoverable autosaves found. Autosaves are stored in your projects folder's .autosave subdirectory and are only available in local mode.",
      "es": "No se encontraron autoguardados recuperables. Los autoguardados se almacenan en el subdirectorio .autosave de tu carpeta de proyectos y solo están disponibles en modo local.",
      "fr": "Aucune sauvegarde automatique récupérable trouvée. Les sauvegardes automatiques sont stockées dans le sous-répertoire .autosave de votre dossier de projets et ne sont disponibles qu'en mode local.",
      "de": "Keine wiederherstellbaren automatischen Speicherungen gefunden. Autospeicherungen werden im Unterverzeichnis .autosave Ihres Projektordners gespeichert und sind nur im lokalen Modus verfügbar.",
      "lt": "Atkuriamų automatinių išsaugojimų nerasta. Automatiniai išsaugojimai saugomi jūsų projektų aplanko .autosave pakatalogyje ir galimi tik vietiniu režimu.",
      "pt": "Nenhum salvamento automático recuperável encontrado. Os salvamentos automáticos são armazenados no subdiretório .autosave da sua pasta de projetos e estão disponíveis apenas no modo local.",
      "it": "Nessun salvataggio automatico recuperabile trovato. I salvataggi automatici sono archiviati nella sottodirectory .autosave della cartella dei progetti e sono disponibili solo in modalità locale.",
      "no": "Ingen gjenopprettelige autolagringer funnet. Autolagringer lagres i .autosave-underkatalogen til prosjektmappen din og er bare tilgjengelige i lokal modus.",
      "el": "Δεν βρέθηκαν ανακτήσιμες αυτόματες αποθηκεύσεις. Οι αυτόματες αποθηκεύσεις αποθηκεύονται στον υποκατάλογο .autosave του φακέλου έργων σας και είναι διαθέσιμες μόνο σε τοπική λειτουργία."
    },
    "modules.auto_save.minutes_ago": {
      "en": "%d minutes ago",
      "es": "hace %d minutos",
      "fr": "il y a %d minutes",
      "de": "vor %d Minuten",
      "lt": "prieš %d min.",
      "pt": "há %d minutos",
      "it": "%d minuti fa",
      "no": "for %d minutter siden",
      "el": "%d λεπτά πριν"
    },
    "modules.auto_save.hours_ago": {
      "en": "%d hours ago",
      "es": "hace %d horas",
      "fr": "il y a %d heures",
      "de": "vor %d Stunden",
      "lt": "prieš %d val.",
      "pt": "há %d horas",
      "it": "%d ore fa",
      "no": "for %d timer siden",
      "el": "%d ώρες πριν"
    },
    "modules.auto_save.days_ago": {
      "en": "%d days ago",
      "es": "hace %d días",
      "fr": "il y a %d jours",
      "de": "vor %d Tagen",
      "lt": "prieš %d d.",
      "pt": "há %d dias",
      "it": "%d giorni fa",
      "no": "for %d dager siden",
      "el": "%d ημέρες πριν"
    },
    "modules.auto_save.autosave_not_found": {
      "en": "Autosave file no longer exists.",
      "es": "El archivo de autoguardado ya no existe.",
      "fr": "Le fichier de sauvegarde automatique n'existe plus.",
      "de": "Die automatische Speicherungsdatei existiert nicht mehr.",
      "lt": "Automatinio išsaugojimo failas nebeegzistuoja.",
      "pt": "O arquivo de salvamento automático não existe mais.",
      "it": "Il file di salvataggio automatico non esiste più.",
      "no": "Autolagringsfilen eksisterer ikke lenger.",
      "el": "Το αρχείο αυτόματης αποθήκευσης δεν υπάρχει πλέον."
    },
    "modules.auto_save.autosave_load_failed": {
      "en": "Could not load autosave file. It may be corrupted or incompatible.",
      "es": "No se pudo cargar el archivo de autoguardado. Puede estar dañado o ser incompatible.",
      "fr": "Impossible de charger le fichier de sauvegarde automatique. Il peut être corrompu ou incompatible.",
      "de": "Die automatische Speicherungsdatei konnte nicht geladen werden. Sie ist möglicherweise beschädigt oder inkompatibel.",
      "lt": "Nepavyko įkelti automatinio išsaugojimo failo. Jis gali būti sugadintas arba nesuderinamas.",
      "pt": "Não foi possível carregar o arquivo de salvamento automático. Pode estar corrompido ou incompatível.",
      "it": "Impossibile caricare il file di salvataggio automatico. Potrebbe essere danneggiato o incompatibile.",
      "no": "Kunne ikke laste autolagringsfilen. Den kan være ødelagt eller inkompatibel.",
      "el": "Αδυναμία φόρτωσης αρχείου αυτόματης αποθήκευσης. Μπορεί να έχει καταστραφεί ή να μην είναι συμβατό."
    },
    "modules.auto_save.autosave_loaded_successfully": {
      "en": "Autosave loaded successfully.",
      "es": "Autoguardado cargado correctamente.",
      "fr": "Sauvegarde automatique chargée avec succès.",
      "de": "Automatische Speicherung erfolgreich geladen.",
      "lt": "Automatinis išsaugojimas sėkmingai įkeltas.",
      "pt": "Salvamento automático carregado com sucesso.",
      "it": "Salvataggio automatico caricato con successo.",
      "no": "Autolagring lastet inn.",
      "el": "Η αυτόματη αποθήκευση φορτώθηκε επιτυχώς."
    },
```

Add to `translations/ui/sidebar.json` inside the `"translation"` object:

```json
    "ui.sidebar.recent_autosaves_tooltip": {
      "en": "Browse and restore recent automatic saves",
      "es": "Explorar y restaurar autoguardados recientes",
      "fr": "Parcourir et restaurer les sauvegardes automatiques récentes",
      "de": "Aktuelle automatische Speicherungen durchsuchen und wiederherstellen",
      "lt": "Naršyti ir atkurti naujausius automatinius išsaugojimus",
      "pt": "Navegar e restaurar salvamentos automáticos recentes",
      "it": "Sfoglia e ripristina i salvataggi automatici recenti",
      "no": "Bla gjennom og gjenopprett nylige autolagringer",
      "el": "Περιήγηση και επαναφορά πρόσφατων αυτόματων αποθηκεύσεων"
    },
```

- [ ] **Step 4: Verify JSON validity**

```bash
micromamba run -n shiny python -c "import json; [json.load(open(f'translations/{f}')) for f in ['common/buttons.json', 'modules/auto_save.json', 'ui/sidebar.json']]; print('All valid')"
```

Expected: `All valid`

- [ ] **Step 5: Run i18n audit to check for missing keys**

```bash
micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```

Expected: `missing=0 ... hardcoded=0`

- [ ] **Step 6: Commit**

```bash
git add functions/ui_sidebar.R server/project_io.R translations/common/buttons.json translations/modules/auto_save.json translations/ui/sidebar.json
git commit -m "$(cat <<'EOF'
feat: add Recent Autosaves browsable UI

Users can now browse and manually restore any autosave from the
persistent .autosave folder (not just the most recent one). The
existing automatic recovery modal only surfaces the top hit within
72 hours; this adds a new sidebar button opening a list modal with
all persistent autosaves sorted by modification time.

Implementation reuses the existing find_recoverable_autosaves() helper
from functions/persistent_storage.R with an extended 30-day window,
and writes loaded data directly to the project_data() reactive
(downstream modules observe it), matching the existing confirm_load
handler pattern.

Known limitation: persistent autosaves only exist in local mode. On
shiny-server deployments, this modal will show "No recoverable
autosaves found" because session-temp files die with the session.

11 new translation keys across 3 translation files (buttons.json, auto_save.json, sidebar.json) in 9 languages.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final Verification

- [ ] **Step 0: Confirm all 8 tasks produced commits**

```bash
git log --oneline origin/main..HEAD | wc -l
```

Expected: `8` (one commit per task). If fewer, a task was skipped — identify which and complete it before proceeding.

```bash
git log --oneline origin/main..HEAD
```

Expected subjects (order-independent): one each mentioning C1 (CI), C2 (ai_isa), C3 (IndexedDB), C4 (DESCRIPTION), C5 (readRDS), I5d (roxygen), I5f (SKILL.md), and Recent Autosaves UI.

- [ ] **Step 0b: Verify new button + handler are wired together**

```bash
grep -n "recent_autosaves" functions/ui_sidebar.R
grep -n "input\$recent_autosaves\|input\$selected_autosave_path" server/project_io.R
grep -n "recent_autosaves\|autosave_loaded_successfully" translations/common/buttons.json translations/modules/auto_save.json translations/ui/sidebar.json
```

Expected: `recent_autosaves` input ID appears in both `ui_sidebar.R` (actionButton) and `project_io.R` (observeEvent); all 11 translation keys resolve to at least one JSON file.

- [ ] **Step 1: Run i18n audit — confirm still clean**

```bash
cd "$PROJECT_ROOT" && micromamba run -n shiny python scripts/_i18n_audit.py 2>&1 | grep Totals
```

Expected: `missing=0 ... incomplete=0 ... hardcoded=0`

- [ ] **Step 2: Run KB audit — confirm no regressions**

```bash
micromamba run -n shiny python scripts/kb_audit/audit_kb_quality.py 2>&1 | grep -E "Total connections|Non-framework"
```

Expected: Main KB 1146 connections, 0 non-framework transitions

- [ ] **Step 3: Push and deploy**

```bash
git push
bash deployment/remote-deploy.sh --force
```

Then restart Shiny Server via `! ssh -t razinka@laguna.ku.lt "sudo systemctl restart shiny-server"`.

- [ ] **Step 4: Verify app is live**

```bash
curl -sSL -o /dev/null -w "HTTP: %{http_code}\n" --max-time 30 "https://laguna.ku.lt/marinesabres/"
```

Expected: `HTTP: 200`
