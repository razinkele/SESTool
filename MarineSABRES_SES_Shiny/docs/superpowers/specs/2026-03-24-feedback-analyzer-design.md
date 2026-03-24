# Feedback Analysis Utility with Duplicate Detection — Design Spec

## Goal

Admin-only in-app utility to browse, filter, and analyze user feedback submissions, with semantic duplicate detection using TF-IDF cosine similarity.

## Access Control

Enabled by env var `MARINESABRES_ADMIN_MODE=TRUE`. When set, an "Admin" menu item (lock icon) appears in the sidebar. When not set, the menu item and module are completely hidden.

**Check pattern:** Define `ADMIN_MODE <- Sys.getenv("MARINESABRES_ADMIN_MODE", "FALSE") == "TRUE"` in `global.R` (alongside the existing `DEBUG_MODE` pattern). This global flag is read by `generate_sidebar_menu()` in `ui_sidebar.R` and by the module registration in `app.R`.

## Module: `modules/feedback_admin_module.R`

Standard module pattern: `feedback_admin_ui(id, i18n)` + `feedback_admin_server(id, i18n)`.

**UI must start with:** `shiny.i18n::usei18n(i18n)` as required by project conventions.

**Server signature:** `feedback_admin_server(id, i18n)` — omits `project_data_reactive` since this module only reads the feedback log, not ISA data. This is acceptable for admin-only utilities.

**Tab name:** `"feedback_admin"` — used in `bs4TabItem(tabName = "feedback_admin", ...)` and the sidebar `menuItem(tabName = "feedback_admin", ...)`.

**Module loading:** Add to `OPTIONAL_MODULES` in `app.R` (not CRITICAL — app must start even if admin module has issues). Only register the `tabItem` and call the server function when `ADMIN_MODE == TRUE`.

### Tab 1: Feedback Dashboard

- **Data source:** Reads `data/user_feedback_log.ndjson` via `load_feedback_log()`.
- **Summary cards** (valueBox pattern):
  - Total reports count
  - Bugs / Suggestions / General breakdown
  - Reports in last 7 days
  - GitHub-submitted vs local-only count (derived: `github_submitted = !is.na(github_url) & github_url != ""`)
- **Filterable table:** DT::datatable with i18n-translated column headers via `colnames = c(i18n$t(...), ...)`. Columns: Date, Type (colored badge), Title, Description (truncated to 100 chars), GitHub Status (icon). Filters on type and date range.
- **Detail modal:** Click a row → modal shows full description, steps to reproduce, system context, GitHub issue URL (if any).

### Tab 2: Duplicate Detection

- **Similarity engine:** TF-IDF cosine similarity on concatenated `title + " " + description` text.
- **Scale cap:** Process at most the last 500 entries to prevent O(N^2) memory issues. If log exceeds 500 entries, show a note and analyze only the most recent 500.
- **Threshold slider:** `sliderInput` from 0.5 to 0.95, default 0.7, step 0.05.
- **Results table:** DT with i18n-translated column headers. Columns: Report A (title + date), Report B (title + date), Similarity (percentage, color-coded), Action.
- **Mark duplicate button:** Per-row actionButton. Writes `duplicate_of` field to the newer entry via atomic temp-file-then-rename.
- **Recalculate button:** Re-runs similarity after marking duplicates (excludes already-marked pairs).

## Core Functions: `functions/feedback_analyzer.R`

### `load_feedback_log(path = "data/user_feedback_log.ndjson")`
- Reads file line by line, parses each JSON line via `jsonlite::fromJSON()`
- Tracks physical line number during read (not data.frame row number) so that `mark_as_duplicate()` can reference the correct file line even when malformed lines are skipped
- Returns a data.frame with columns: `line_num` (physical file line), `type`, `title`, `description`, `steps`, `timestamp`, `github_url`, `duplicate_of`
- `github_url` comes directly from the NDJSON field (written by `feedback_reporter.R`). There is no `github_success` field in the log — derive it as `!is.na(github_url) & github_url != ""`
- **Deduplication of corrected entries:** `feedback_reporter.R` appends a second corrected entry with `github_url` when GitHub succeeds. `load_feedback_log()` deduplicates by keeping the LAST entry per unique `title + timestamp` combination
- Returns empty data.frame with correct columns if file doesn't exist or is empty
- If a parsed entry lacks a `duplicate_of` field, set it to `NA_character_` (most entries won't have it until marked)
- Wrapped in tryCatch — malformed lines are skipped with warning

### `compute_text_similarity(texts)`
- Input: character vector of texts
- **Guard:** If `length(texts) < 2`, return a matrix of appropriate size with 0s (no pairs possible)
- Tokenize: `tolower()` → split on non-alphanumeric → remove stopwords (minimal English set)
- Build term-frequency matrix, compute IDF, apply TF-IDF weighting
- Cosine similarity: `(A . B) / (||A|| * ||B||)` for all pairs
- **Zero-norm guard:** If a document has zero norm after stopword removal (e.g., all-stopword text), assign similarity of 0 with all other documents (avoid NaN from division by zero)
- Returns: N x N numeric matrix of similarity scores (0-1)
- No external dependencies — pure base R

### `find_duplicate_pairs(df, threshold = 0.7)`
- Input: data.frame from `load_feedback_log()`, threshold float
- **Guard:** If `nrow(df) < 2` after filtering out already-marked duplicates, return empty data.frame immediately
- Calls `compute_text_similarity()` on concatenated title+description
- Filters pairs where similarity >= threshold
- Excludes self-pairs and already-marked duplicates (`duplicate_of` not NA)
- Returns data.frame: `line_a`, `line_b`, `title_a`, `title_b`, `date_a`, `date_b`, `similarity`
- Sorted by similarity descending

### `mark_as_duplicate(log_path, line_num, duplicate_of_line)`
- Reads entire NDJSON file via `readLines()`
- Parses the entry at physical `line_num`, adds `duplicate_of` field with value `duplicate_of_line`
- The `duplicate_of` field stores the physical line number of the original report (integer). Line numbers remain stable within a session since `mark_as_duplicate()` modifies content of a line but does not add or remove lines.
- **Atomic write:** Reads all lines, modifies the target line in memory, writes to a temp file in the same directory, then uses `file.rename()` to replace the original. This prevents corruption from concurrent reads.
- Returns TRUE on success, FALSE on error (out-of-range line_num, file not found, write failure)

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `functions/feedback_analyzer.R` | Create | `load_feedback_log()`, `compute_text_similarity()`, `find_duplicate_pairs()`, `mark_as_duplicate()` |
| `modules/feedback_admin_module.R` | Create | `feedback_admin_ui()` + `feedback_admin_server()` |
| `functions/ui_sidebar.R` | Modify | Add conditional Admin menu item when `ADMIN_MODE == TRUE` |
| `app.R` | Modify | Add to OPTIONAL_MODULES, register tabItem + server when admin mode |
| `global.R` | Modify | Source `feedback_analyzer.R` with `local = FALSE` after `feedback_reporter.R` (~line 629). Define `ADMIN_MODE` flag alongside `DEBUG_MODE` (~line 422). Module file loaded via OPTIONAL_MODULES loop (no conditional source needed). |
| `translations/modules/feedback_admin.json` | Create | i18n keys for 9 languages |
| `tests/testthat/test-feedback-analyzer.R` | Create | Unit tests |

## i18n Keys (all 9 languages)

```
modules.feedback_admin.menu_label           — "Admin"
modules.feedback_admin.dashboard_tab        — "Feedback Dashboard"
modules.feedback_admin.duplicates_tab       — "Duplicate Detection"
modules.feedback_admin.total_reports        — "Total Reports"
modules.feedback_admin.bug_reports          — "Bug Reports"
modules.feedback_admin.suggestions          — "Suggestions"
modules.feedback_admin.general_feedback     — "General"
modules.feedback_admin.last_7_days          — "Last 7 Days"
modules.feedback_admin.github_submitted     — "GitHub Submitted"
modules.feedback_admin.local_only           — "Local Only"
modules.feedback_admin.no_feedback          — "No feedback submissions yet."
modules.feedback_admin.similarity_threshold — "Similarity Threshold"
modules.feedback_admin.find_duplicates      — "Find Duplicates"
modules.feedback_admin.no_duplicates        — "No duplicates found at this threshold."
modules.feedback_admin.mark_duplicate       — "Mark as Duplicate"
modules.feedback_admin.marked_duplicate     — "Marked as duplicate."
modules.feedback_admin.mark_error           — "Error marking duplicate."
modules.feedback_admin.detail_title         — "Feedback Details"
modules.feedback_admin.recalculate          — "Recalculate"
modules.feedback_admin.scale_note           — "Showing last 500 entries for analysis."
modules.feedback_admin.col_date             — "Date"
modules.feedback_admin.col_type             — "Type"
modules.feedback_admin.col_title            — "Title"
modules.feedback_admin.col_description      — "Description"
modules.feedback_admin.col_github           — "GitHub"
modules.feedback_admin.col_report_a         — "Report A"
modules.feedback_admin.col_report_b         — "Report B"
modules.feedback_admin.col_similarity       — "Similarity"
modules.feedback_admin.col_action           — "Action"
```

## Testing

- `test-feedback-analyzer.R`:
  - `load_feedback_log()` parses valid NDJSON into correct data.frame columns
  - `load_feedback_log()` returns empty data.frame for missing file
  - `load_feedback_log()` skips malformed lines gracefully (tracks physical line numbers)
  - `load_feedback_log()` deduplicates corrected entries (keeps last per title+timestamp)
  - `compute_text_similarity()` returns 1.0 for identical texts
  - `compute_text_similarity()` returns value near 0 for unrelated texts
  - `compute_text_similarity()` returns NxN matrix
  - `compute_text_similarity()` returns 0 matrix for single-entry input
  - `compute_text_similarity()` handles all-stopword text without NaN
  - `find_duplicate_pairs()` finds known duplicates above threshold
  - `find_duplicate_pairs()` returns empty data.frame when fewer than 2 entries
  - `find_duplicate_pairs()` returns empty data.frame when all entries already marked
  - `mark_as_duplicate()` adds duplicate_of field to correct physical line
  - `mark_as_duplicate()` returns FALSE for out-of-range line_num
  - Translation keys exist for all 9 languages
  - Admin sidebar item conditional on env var (use `Sys.setenv`/`Sys.unsetenv` in test)

## Security

- Module only renders when `ADMIN_MODE == TRUE` — no server-side data exposed otherwise
- Sidebar menu item not present at all when admin mode is off (not just hidden via CSS)
- `mark_as_duplicate()` only modifies the feedback log file, no other files
- Atomic file writes prevent corruption from concurrent access
- No PII in the feedback data (as enforced by the reporter)

## Out of Scope

- Multi-language duplicate detection (similarity works on raw text; non-English feedback may have lower accuracy)
- Feedback deletion from the admin panel
- Export/download of feedback data (can be added later)
