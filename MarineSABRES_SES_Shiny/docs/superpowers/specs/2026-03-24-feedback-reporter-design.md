# Bug & Suggestion Report Facility — Design Spec

## Goal

Add in-app bug reporting and improvement suggestion submission. Reports are created as GitHub Issues (primary) and logged to a local file (fallback/audit).

## Entry Point

A standalone icon button in the top navbar, positioned between the "About" and "Help" items (around line 137 in `functions/ui_header.R`). Uses `comment-dots` Font Awesome icon. Label: "Feedback" (i18n).

**File:** `functions/ui_header.R` — add a new `tags$li` in the navbar right section, same pattern as Bookmark/App Info buttons. Trigger: `onclick = "Shiny.setInputValue('show_feedback_modal', Math.random()); return false;"` (note the `return false;` to match existing pattern).

## Modal Dialog

Triggered by `input$show_feedback_modal`. Handler in `server/modals.R` via `setup_feedback_modal_handlers(input, output, session, i18n, project_data = NULL)`.

Since the modal handler lives in `server/modals.R` (root session scope, not a module), `conditionalPanel` conditions use `input.feedback_type` (JS dot notation) without namespace prefix. Alternatively, use `shinyjs::toggle()` server-side for the steps-to-reproduce field.

### Form Fields

| Field | Type | Required | Visibility | Limits |
|-------|------|----------|------------|--------|
| Report type | Radio buttons: Bug Report / Improvement Suggestion / General Feedback | Yes | Always | — |
| Title | Text input | Yes | Always | maxlength=200 |
| Description | Textarea, 5 rows | Yes | Always | maxlength=5000 |
| Steps to reproduce | Textarea, 3 rows | No | Bug Report only | maxlength=2000 |
| Auto-context | Read-only info block | N/A | Always (collapsed by default) | — |

Modal footer uses existing `common.buttons.cancel` key for the Cancel button (no new key needed).

### Auto-Collected Context

Gathered at modal open time, displayed as a collapsible "System Information" block at the bottom:

- `app_version` — from VERSION file
- `user_level` — beginner/intermediate/expert
- `current_tab` — active sidebar tab ID
- `browser_info` — collected via inline JS: `Shiny.setInputValue('feedback_browser_info', navigator.userAgent)` triggered on modal open (add as `tags$script` inside the modal body)
- `language` — current i18n language code
- `element_count` — total ISA elements (number only, no names)
- `connection_count` — total connections (number only)
- `timestamp` — ISO 8601 UTC

No personal data (no usernames, no project names, no element content).

## Submission Flow

```
User clicks Submit
  → Disable submit button immediately (prevent double-click)
  → Server-side rate limit check (reactiveVal stores last submit time, reject if < 30s)
  → Validate: title and description non-empty, within length limits
  → Build payload (form fields + auto-context)
  → Save to local NDJSON file (always, first, wrapped in tryCatch)
    → If local save fails: log via debug_log(), continue to GitHub attempt
  → Attempt GitHub Issue creation (if token configured)
    → Success: show notification with issue URL
    → Failure: show notification "Feedback saved locally, thank you!"
  → Update last_submit_time reactiveVal
  → Close modal
  → Re-enable submit button after 30s (via shinyjs::delay) for if user reopens modal
```

## GitHub Issues Integration

**Function:** `create_github_issue(title, body, labels)` in `functions/feedback_reporter.R`

- **API:** `POST https://api.github.com/repos/{owner}/{repo}/issues`
- **Auth:** Fine-grained PAT via env var `MARINESABRES_GITHUB_TOKEN`
- **Repo:** Configured via env var `MARINESABRES_GITHUB_REPO` (default: `marinesabres/SESToolbox`)
- **Labels:** Auto-assigned based on report type:
  - Bug Report → `["bug", "user-reported"]`
  - Improvement Suggestion → `["enhancement", "user-reported"]`
  - General Feedback → `["feedback", "user-reported"]`
- **Body format:** Markdown with title, description, steps (if bug), and a collapsible `<details>` block for system context
- **HTTP library:** `httr` — must be added to `DESCRIPTION` Imports and loaded in `global.R`
- **Timeout:** 10 seconds via `httr::timeout(10)`. On timeout or error, fall through to local-only.

If `MARINESABRES_GITHUB_TOKEN` is not set, GitHub submission is silently skipped (local-only mode).

## Local File Logging

**Function:** `save_feedback_local(payload)` in `functions/feedback_reporter.R`

- **File:** `data/user_feedback_log.ndjson`
- **Format:** NDJSON (one JSON object per line, append-only). No read-modify-write needed — just `cat(jsonlite::toJSON(payload, auto_unbox = TRUE), "\n", file = path, append = TRUE)`.
- **Fields:** All form fields + auto-context + `github_issue_url` (if created) + `github_success` (boolean)
- **Concurrency:** Shiny Server runs single-threaded per process. The append-only NDJSON format is safe for sequential writes. For multi-worker deployments, the append-only pattern provides best-effort safety (atomic `cat` + `\n`).
- **Error handling:** Wrapped in `tryCatch`. On failure (disk full, permissions), log via `debug_log()` and continue to GitHub attempt.

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `functions/feedback_reporter.R` | Create | `submit_feedback(title, description, type, steps, context)`, `save_feedback_local(payload)`, `create_github_issue(title, body, labels)`, `collect_system_context(session, input, project_data)` |
| `server/modals.R` | Modify | Add `setup_feedback_modal_handlers(input, output, session, i18n, project_data)` at end |
| `functions/ui_header.R` | Modify | Add feedback icon button to navbar (between About and Help) |
| `global.R` | Modify | Source `feedback_reporter.R`, add `library(httr)` |
| `DESCRIPTION` | Modify | Add `httr` to Imports |
| `app.R` | Modify | Call `setup_feedback_modal_handlers()` in server, passing `project_data` |
| `translations/ui/modals.json` | Modify | Add `ui.modals.feedback.*` keys for 9 languages |
| `.gitignore` | Modify | Add `data/user_feedback_log.ndjson` |
| `tests/testthat/test-feedback-reporter.R` | Create | Unit tests |

## i18n Keys (all 9 languages)

```
ui.modals.feedback.button_label        — "Feedback"
ui.modals.feedback.modal_title         — "Send Feedback"
ui.modals.feedback.type_label          — "Report Type"
ui.modals.feedback.type_bug            — "Bug Report"
ui.modals.feedback.type_suggestion     — "Improvement Suggestion"
ui.modals.feedback.type_general        — "General Feedback"
ui.modals.feedback.title_label         — "Title"
ui.modals.feedback.title_placeholder   — "Brief summary of your feedback"
ui.modals.feedback.description_label   — "Description"
ui.modals.feedback.description_placeholder — "Please describe in detail..."
ui.modals.feedback.steps_label         — "Steps to Reproduce"
ui.modals.feedback.steps_placeholder   — "1. Go to...\n2. Click on...\n3. See error..."
ui.modals.feedback.context_label       — "System Information"
ui.modals.feedback.submit              — "Submit Feedback"
ui.modals.feedback.success_github      — "Thank you! Your feedback has been submitted."
ui.modals.feedback.success_local       — "Thank you! Your feedback has been saved."
ui.modals.feedback.error_empty_title   — "Please enter a title."
ui.modals.feedback.error_empty_desc    — "Please enter a description."
ui.modals.feedback.rate_limited        — "Please wait before submitting again."
```

Modal Cancel button uses existing `common.buttons.cancel` key.

## Testing

- `test-feedback-reporter.R`:
  - `save_feedback_local()` writes valid NDJSON, appends without corrupting existing entries
  - `save_feedback_local()` handles write errors gracefully (tryCatch, returns FALSE)
  - `create_github_issue()` builds correct API payload structure (mock HTTP, don't hit real API)
  - `collect_system_context()` returns all expected fields
  - `submit_feedback()` falls back to local when GitHub token is missing
  - `submit_feedback()` validates required fields (rejects empty title/description)
  - Translation keys exist in modals.json for all 9 languages
  - Navbar feedback button exists in ui_header.R source
  - `httr` is listed in DESCRIPTION Imports

## Security Considerations

- GitHub PAT stored as server-side env var, never exposed to client
- No user-submitted content is evaluated as code (all strings)
- Input length limits enforced both client-side (`maxlength` attr) and server-side validation
- **Server-side rate limit:** `reactiveVal` stores last submission timestamp; submissions within 30s are rejected with notification (not bypassable from browser console)
- **Client-side UX:** Submit button disabled for 30s after submission via `shinyjs::disable`/`enable`
- Auto-context contains no PII — only aggregate counts and technical metadata

## Out of Scope

- File/screenshot attachments (can be added later)
- Email notifications
- Admin dashboard for reviewing feedback
- User authentication for submissions
