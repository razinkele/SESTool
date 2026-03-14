# MarineSABRES SES Toolbox - Improvement Plan

**Version:** 3.0
**Date:** 2026-03-14
**Analysis:** Full codebase deep-dive (architecture, modules, functions, i18n, tests, domain model, security)
**Status:** Active

---

## Executive Summary

| Metric | Value |
|--------|-------|
| R source files | 100+ |
| Lines of code | ~60,000+ |
| Shiny modules | 43 (28 primary + 15 helpers) |
| Helper functions | 200+ across 41 files |
| ML files | 14 (torch-based, optional) |
| Languages | 9 (en, es, fr, de, lt, pt, it, no, el) |
| Translation files | 37 modular JSON |
| Test files | 61 (~1,191 test cases) |
| Coverage | ~68-70% (target 85%) |

**Quality Grade:** B+ (production-ready, improvement areas identified)

---

## Priority Matrix

| Priority | Issues | Timeframe | Theme |
|----------|--------|-----------|-------|
| **P0 Critical** | 8 | Immediate (this sprint) | Security, data integrity, session safety |
| **P1 High** | 10 | 1-2 sprints | Testing gaps, consistency, event bus |
| **P2 Medium** | 12 | 2-4 sprints | Performance, UX, code quality |
| **P3 Low** | 8 | Backlog | Documentation, polish, future features |

---

## P0 - Critical (Fix Immediately)

### 1. HTML Injection / XSS via HTML() function
**Category:** Security | **Effort:** Medium
**Risk:** User-supplied data passed unsanitized to `HTML()` in 25+ files.

**Locations (highest risk):**
- `server/project_io.R:220-224` - Filename interpolated into HTML button
- `modules/ai_isa_assistant_module.R` - Element names rendered as HTML
- `modules/connection_review_tabbed.R` - User text in HTML tables
- `modules/cld_visualization_module.R` - Node labels in tooltips
- `server/modals.R` - User project names in modal content

**Fix:** Audit all `HTML()` calls. Sanitize user input with `htmltools::htmlEscape()` before interpolation.

```r
# Before (vulnerable):
HTML(paste0('<span>', user_input, '</span>'))

# After (safe):
HTML(paste0('<span>', htmltools::htmlEscape(user_input), '</span>'))
```

**Acceptance:**
- [ ] All 25 files audited for HTML injection
- [ ] User-supplied strings escaped before `HTML()` calls
- [ ] Test: `test-xss-prevention.R` with malicious payloads

---

### 2. Missing JSON Schema Validation
**Category:** Security | **Effort:** Medium
**Risk:** `jsonlite::fromJSON()` called on user-provided data without validation. Malformed JSON crashes app.

**Locations:**
- `app.R:685` - Project restore from language change
- `functions/persistent_storage.R` - Project save/load
- `modules/import_data_module.R` - Data import

**Fix:** Add `validate_project_json()` wrapper with structure checks.

```r
validate_project_json <- function(json_str) {
  tryCatch({
    data <- jsonlite::fromJSON(json_str)
    stopifnot(is.list(data), !is.null(data$data))
    data
  }, error = function(e) {
    debug_log(paste("Invalid JSON:", e$message), "ERROR")
    NULL
  })
}
```

**Acceptance:**
- [ ] All `fromJSON()` calls wrapped with validation
- [ ] Graceful error handling for invalid JSON
- [ ] User-friendly notification on bad input

---

### 3. ML Model Loading Without Verification
**Category:** Security | **Effort:** Medium
**Risk:** `torch_load()` can execute arbitrary code. No verification of `.pt` model files.

**Location:** `functions/ml_inference.R`

**Fix:** Add checksum verification before loading models.

```r
load_ml_model <- function(model_path, expected_hash = NULL) {
  if (!is.null(expected_hash)) {
    actual_hash <- digest::digest(file = model_path, algo = "sha256")
    if (actual_hash != expected_hash) {
      stop("Model file integrity check failed")
    }
  }
  torch::torch_load(model_path)
}
```

**Acceptance:**
- [ ] Model files have SHA-256 checksums in registry
- [ ] Verification before `torch_load()`
- [ ] Log warning if checksum not available

---

### 4. Event Bus Metadata Not Session-Scoped
**Category:** Architecture | **Effort:** Low
**Risk:** Shared environment for metadata causes race conditions in multi-user deployments.

**Location:** `server/event_bus_setup.R:32-34`

**Fix:** Move metadata into the per-session event_bus list.

**Acceptance:**
- [ ] Each session has isolated event metadata
- [ ] Event counts accurate per session
- [ ] Test: `test-event-bus-isolation.R`

---

### 5. eval() Usage in Error Handling
**Category:** Security | **Effort:** Low
**Risk:** 21 `eval()` instances in `functions/error_handling.R`. If user-controlled expressions reach these, code injection is possible.

**Locations:** `functions/error_handling.R:297, 324`

**Fix:** Add strict type validation on inputs to `safe_render*()` wrappers. Document that these must NEVER receive user input. Consider replacing with direct function calls where possible.

**Acceptance:**
- [ ] Guard clauses validate expression types
- [ ] Documentation: "INTERNAL ONLY - never pass user input"
- [ ] Reduce eval() count where alternatives exist

---

### 6. Session Isolation Untested
**Category:** Testing | **Effort:** Medium
**Risk:** `functions/session_isolation.R` has zero test coverage but handles user data separation.

**Fix:** Create `test-session-isolation.R` with 10+ tests covering:
- Unique directory creation per session
- Concurrent session data separation
- Cleanup on disconnect
- Temp file isolation

**Acceptance:**
- [ ] 10+ tests passing
- [ ] Coverage > 80% for session_isolation.R

---

### 7. Reactive Pipeline Untested
**Category:** Testing | **Effort:** Medium
**Risk:** `functions/reactive_pipeline.R` manages ISA→CLD→Analysis flow with zero test coverage.

**Fix:** Create `test-reactive-pipeline.R` covering:
- Debouncing behavior
- Signature-based change detection
- CLD regeneration triggers
- Analysis invalidation cascade

**Acceptance:**
- [ ] Pipeline stages individually tested
- [ ] Debounce timing verified
- [ ] False-positive regeneration prevented

---

### 8. Auto-Save Module Untested
**Category:** Testing | **Effort:** Medium
**Risk:** 1,123-line data persistence feature with zero tests. Silent failure = user data loss.

**Fix:** Create `test-auto-save-module.R` covering:
- Save trigger conditions
- Session-scoped storage keys
- Recovery file creation/restoration
- Adaptive debouncing behavior

**Acceptance:**
- [ ] Core save/restore logic tested
- [ ] Session key isolation verified
- [ ] Error recovery path tested

---

## P1 - High Priority (1-2 Sprints)

### 9. 21 Modules Completely Untested
**Category:** Testing | **Effort:** High
**Impact:** 14,594 lines without any test coverage.

**Critical untested modules (implement first):**

| Module | Lines | Risk |
|--------|-------|------|
| `graphical_ses_network_builder.R` | 1,191 | Core feature |
| `prepare_report_module.R` | 1,254 | Data aggregation |
| `local_storage_module.R` | 824 | Data persistence |
| `analysis_loops.R` | 974 | Core analysis |

**Acceptance:**
- [ ] Critical 4 modules: 5+ tests each
- [ ] Remaining 17 modules: 3+ tests each
- [ ] Coverage reaches 80%+

---

### 10. Inconsistent Module Server Signatures
**Category:** Consistency | **Effort:** Medium
**Impact:** 12 of 42 modules (29%) deviate from the standard signature.

**Standard:** `module_name_server(id, project_data_reactive, i18n, session = NULL, event_bus = NULL, ...)`

**Non-conforming modules need audit and alignment.**

**Acceptance:**
- [ ] All modules follow standard signature order
- [ ] `test-module-signatures.R` enforces compliance
- [ ] CLAUDE.md updated if standard changes

---

### 11. ISA Data Entry Missing i18n Parameter
**Category:** i18n | **Effort:** Low
**Impact:** Language switching doesn't update the main data entry form.

**Location:** `modules/isa_data_entry_module.R:7`

**Fix:** Add `i18n` parameter, call `shiny.i18n::usei18n(i18n)`, wrap all text in `i18n$t()`.

**Acceptance:**
- [ ] UI function accepts i18n
- [ ] All labels translated
- [ ] Language switching updates form

---

### 12. Event Bus Adoption Fragmented
**Category:** Architecture | **Effort:** Medium
**Impact:** Only 26% of modules (11/42) use the event bus. Analysis modules don't subscribe to ISA changes.

**Modules that SHOULD use event_bus but don't:**
- All 8 analysis modules (loops, metrics, leverage, boolean, bot, simulation, intervention, simplify)
- response_module, scenario_builder
- PIMS modules

**Fix:** Wire event_bus into analysis modules so they auto-invalidate when ISA data changes.

**Acceptance:**
- [ ] Analysis modules subscribe to `isa_changed` events
- [ ] Stale analysis results show warning badge
- [ ] Event bus adoption > 60%

---

### 13. Fix 10 Failing ML Tests
**Category:** Testing | **Effort:** Medium
**Impact:** 9 context-embedding tests + 1 ensemble test in `tests/testthat/_problems/`.

**Fix:** Investigate root causes, fix or remove broken tests. Don't leave known failures in the repo.

**Acceptance:**
- [ ] All `_problems/` tests either fixed and moved back, or deleted with rationale
- [ ] `_problems/` directory empty or removed
- [ ] CI green on ML test suite

---

### 14. Norwegian & Greek Translations Incomplete
**Category:** i18n | **Effort:** Medium
**Impact:** `no` and `el` languages show English fallback for many strings.

**Fix:** Either complete translations or formally declare these as "partial support" with documented fallback behavior.

**Acceptance:**
- [ ] Decision documented: complete vs. partial support
- [ ] If completing: all keys translated
- [ ] If partial: UI indicator shows "some content in English"

---

### 15. Hardcoded English in JS & Modals
**Category:** i18n | **Effort:** Low
**Impact:** Bypasses translation system.

**Locations:**
- `server/modals.R:78-87` - Loading messages hardcoded per-language
- `www/custom.js:161` - "Beginner's Guide"
- `www/custom.js:818,823` - "Exit", "Fullscreen"

**Fix:** Move to translation files or use `sessionStorage` i18n bridge.

**Acceptance:**
- [ ] All user-facing JS strings use translation system
- [ ] Modal loading messages from translation files

---

### 16. Dependency Pinning Missing
**Category:** DevOps | **Effort:** Low
**Impact:** No `renv.lock`, no `DESCRIPTION` file. Package versions not reproducible.

**Fix:**
```bash
# Initialize renv
Rscript -e "renv::init()"
# Commit renv.lock
```

**Acceptance:**
- [ ] `renv.lock` committed to git
- [ ] CI uses `renv::restore()` for reproducible builds

---

### 17. Inconsistent Error Message Patterns
**Category:** Code Quality | **Effort:** Low
**Impact:** Some `tryCatch` blocks use `i18n$t("Error:")`, others hardcode English "Error:".

**Fix:** Create standardized `format_user_error(error, i18n, context)` utility.

**Acceptance:**
- [ ] All error messages use consistent pattern
- [ ] Technical details logged, not shown to users

---

### 18. Accessibility: ARIA Attributes Missing
**Category:** Accessibility | **Effort:** Medium
**Impact:** Only ~6% ARIA coverage. Screen reader users excluded.

**Priority targets:**
- Icon-only buttons: add `aria-label`
- Network visualization: add `aria-label` describing structure
- Tooltips: add `aria-describedby` relationships
- Form inputs: add `aria-required`, `aria-invalid`
- Modals: add `aria-modal`, `role="dialog"`

**Acceptance:**
- [ ] All interactive elements have ARIA attributes
- [ ] Keyboard navigation works for all major features
- [ ] WCAG 2.1 AA compliance for critical paths

---

## P2 - Medium Priority (2-4 Sprints)

### 19. Decompose Oversized Modules
**Impact:** Testability, maintainability.

| Module | Lines | Action |
|--------|-------|--------|
| `ai_isa_assistant_module.R` | 3,666 | Already has ai_isa/ subdir - extract more |
| `isa_data_entry_module.R` | 1,808 | Split by DAPSIWRM element type |
| `cld_visualization_module.R` | 1,817 | Extract layout/physics/interaction logic |
| `scenario_builder_module.R` | 1,395 | Split scenario creation vs. comparison |

---

### 20. Clean Up Debug Logging
**Impact:** Code clarity, production readiness.

- `functions/report_generation.R`: ~50 verbose `debug_log("DEBUG: ...")` lines
- 835 `cat()`/`print()` calls vs 512 `debug_log()` calls - standardize to `debug_log()` only

---

### 21. Color Contrast WCAG Compliance
- `--salt-gray: #b8c9d9` fails (1.2:1 ratio, need 4.5:1)
- `--stone-gray: #6b8299` marginal (4.5:1)
- Element colors (e.g., `#FFD700` gold) need dark backgrounds

---

### 22. CLD Regeneration Loading Feedback
- No visual indicator during ISA→CLD regeneration
- Add spinner/progress for large networks (100+ nodes)
- Consider adaptive debouncing based on network size

---

### 23. Remove Dead Code & Archives
- `scripts/_archive/` - 6 files, unclear if needed
- Commented-out code blocks in modules
- `stringsAsFactors = FALSE` (default since R 4.0)
- jQuery `$._data()` internal API usage in custom.js

---

### 24. Create Shared UI Component Library
- ISA entry patterns duplicated across 10+ modules
- Create `functions/ui_components.R` with reusable builders
- Form groups, result cards, action button rows, styled tables

---

### 25. ML Model Versioning System
- 43 MB of `.pt` files without versioning metadata
- No rollback capability
- Need: model cards, version tags, performance history

---

### 26. Error Messages Expose Internals
- `paste(i18n$t("Error:"), e$message)` shows raw R error text to users
- Map error types to user-friendly messages
- Log technical details server-side only

---

### 27. Tooltip Complexity Reduction
- `www/custom.js:224-354` - 130+ lines of tooltip workarounds
- BS4Dash auto-creates tooltips + custom code creates duplicates
- Consolidate or replace with simpler tooltip library

---

### 28. Data Accessor Adoption
- 27 direct `project_data()$data$isa_data$...` accesses found
- Should use `get_isa_data()`, `get_isa_elements()`, etc.
- Reduces breakage when data structure changes

---

### 29. Mobile/Responsive UX
- Tooltip hover doesn't work on touch devices
- Button sizes too small for touch targets (44px minimum)
- Tables not horizontally scrollable on narrow screens

---

### 30. Performance: Startup Metrics
- No timing data for startup phases
- Add `system.time()` tracking for package loading, file sourcing, i18n init

---

## P3 - Low Priority (Backlog)

### 31. DTU Integration (5 Phases)
Detailed plan exists in `Documents/DTU_Integration_Plan.md`. Adds:
- Laplacian stability analysis
- Boolean network dynamics
- Dynamic simulation
- Intervention analysis
- Random forest variable importance

Estimated: 3-4 weeks. Source code available in `DTU/` directory.

---

### 32. Architecture Decision Records
Create `/docs/ARCHITECTURE.md` documenting:
- Why dual i18n system (multi-user safety)
- Why event bus over direct module coupling
- Why debounced reactive pipeline
- Why RDS format for project files

---

### 33. ML Phase 2 Completion
Phase 2 designed but incomplete:
- Context embeddings: partially integrated
- Graph features: code exists but not wired
- Ensemble: 3 models (should be 5-10)
- Active learning: query strategies coded but no UI

Decision needed: complete Phase 2 or simplify to Phase 1 + rules.

---

### 34. Visual Regression Testing
No screenshot comparison for UI changes. Consider:
- `shinytest2` screenshot mode
- Percy or BackstopJS for visual diffing

---

### 35. In-App Translation Management
Currently: edit JSON files manually. Could add:
- Admin UI for translation editing
- Community translation portal
- Export/import for external translators

---

### 36. Production ML Monitoring
Missing:
- Prediction latency tracking
- Drift detection metrics
- Alert thresholds for degraded accuracy

---

### 37. Load Testing
No concurrent session testing. Need:
- Simulate 10-50 concurrent users
- Memory usage profiling
- Response time under load

---

### 38. Roxygen2 Documentation
35+ functions in `data_structure.R` lack proper documentation. Add `@param`, `@return`, `@examples` for all exported functions.

---

## Implementation Roadmap

```
Sprint 1 (Current)     Sprint 2              Sprint 3              Sprint 4+
─────────────────      ─────────────────     ─────────────────     ─────────────
P0: Security fixes     P1: Test coverage     P2: Code quality      P3: DTU integration
 #1 HTML injection      #9 Untested modules   #19 Decompose modules  #31 DTU phases
 #2 JSON validation     #10 Module sigs       #20 Debug cleanup      #33 ML Phase 2
 #3 ML model verify     #12 Event bus wiring  #21 Color contrast     #34 Visual regression
 #5 eval() guards       #13 Fix ML tests      #22 Loading feedback   #37 Load testing
                        #14 NO/EL translations #24 UI components
P0: Testing gaps        #15 Hardcoded i18n     #25 Model versioning
 #4 Event bus tests     #16 renv lock
 #6 Session isolation   #17 Error patterns
 #7 Reactive pipeline   #18 Accessibility
 #8 Auto-save tests

Est: 1 week            Est: 2 weeks          Est: 2-3 weeks        Est: 3-4 weeks
```

---

## Quick Wins (< 1 hour each)

1. **Escape HTML in `server/project_io.R:220-224`** - 15 min
2. **Add `i18n` param to `isa_data_entry_ui()`** - 20 min
3. **Move `server/modals.R:78-87` strings to translation files** - 30 min
4. **Add `aria-label` to icon-only buttons** - 30 min
5. **Initialize `renv` and commit lock file** - 15 min
6. **Remove `stringsAsFactors = FALSE` (R 4.0+ default)** - 10 min
7. **Add `aria-describedby` to tooltip creation in custom.js** - 20 min

---

## Tracking

Each issue should be tracked as a commit or PR referencing this plan:
```
fix(security): #1 sanitize HTML() inputs against XSS
test(session): #6 add session isolation test coverage
refactor(i18n): #15 move hardcoded JS strings to translations
```

Progress updates: check off acceptance criteria as completed.
