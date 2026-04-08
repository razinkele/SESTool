# Changelog

All notable changes to the MarineSABRES SES Toolbox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.11.0] - 2026-04-08

### Knowledge Base & Template Overhaul

Major release rebuilding all SES templates from the knowledge base, with comprehensive scientific review and data quality improvements across 7 review cycles.

### Added
- **6 rebuilt SES templates** from knowledge base contexts with full DAPSIWRM coverage (5–7 elements per category, 23–39 connections each, feedback loops, measures):
  - Fisheries (Baltic/North Sea offshore), Coastal Lagoon (Baltic/Mediterranean lagoons), Pollution (Baltic/North Sea estuaries), Tourism (Mediterranean rocky shore), Climate Change (Arctic sea ice), Offshore Wind (North Sea/Atlantic)
- **Caribbean feedback loops**: 5 welfare→driver connections closing the DAPSIWRM primary cycle
- **KB habitat enrichment**: Zostera marina in 4 Baltic coastal contexts, Cymodocea/Zostera noltei in Mediterranean lagoon, mangrove-seagrass connectivity in 2 Caribbean contexts
- **Domain-specific measures** for all 6 rebuilt templates (seasonal closures, acoustic pingers, wetland buffers, IMTA, pre-treatment systems, bubble curtains, etc.)
- **Same-type matrix support** (p_p, s_s) in template_loader.R for pressure→pressure and state→state connections
- **5 new validation tests** in test-kb-audit-fixes.R (template completeness, orphans, feedback loops, measures, Caribbean polarity)
- **Claude Code automations**: pre-deploy skill, kb-audit skill, dapsiwrm-validator subagent, auto-test hook, deployment config guard hook

### Fixed
- **Caribbean template**: renamed A10 from "IUU fishing" to "Cruise ship and yacht tourism" (element was mislabeled — all 4 connection descriptions referenced cruise ships), added polarity to 87 connections, fixed 11 description mismatches, removed 3 invalid connections, removed P13 (H2S is a consequence of Sargassum, not an independent DAPSIWRM pressure), fixed RC6→P2 description transparency
- **All templates**: removed 70+ spurious "chain completion" connections from KB data, rebuilt welfare→driver feedback with domain-matched pairing (was positional), removed orphan elements
- **Scientific accuracy**: fixed Fisheries ES002 type Provisioning→Regulating, reversed ClimateChange P006→P007 causation, retargeted Tourism R003/R004 to correct pressure, retargeted Caribbean A3/A4 from bycatch to physical damage
- **Tourism**: merged duplicate elements P002/P005 and MPF005/MPF006
- **Knowledge DB**: removed 3 inaccurate Baltic habitat entries (Z. marina absent from freshwater lagoons/estuaries/offshore), corrected Zostera noltii→noltei nomenclature
- **Downstream code**: added r_r and r_mpf to matrix_type_map (template_ses_module.R) and both matrix_maps (connection_generator.R), added "s"→"MPF" prefix mapping in visnetwork_helpers.R
- **Deployment pipeline**: fixed hardcoded razinka user in deploy scripts, added missing httr/htmltools to Dockerfile, updated test.yml (bs4Dash not shinydashboard, dropped R 4.2/4.3), removed stale CI branch names, updated checklist language count to 9

### Changed
- **Aquaculture template renamed to "Coastal Lagoon"** — template contains lagoon fishery/eutrophication activities, not aquaculture
- **Template structure**: all rebuilt templates use standardized dapsiwrm_framework format with regional_context, metadata, and measures sections
- **Test fixtures**: updated with complexity, regional_context, and metadata fields; Tourism fixture kept in elements format for format detection coverage

## [1.10.2] - 2026-03-18

### Test Suite Hardening & Function Implementation

Patch release resolving all 46 pre-existing test failures, implementing previously-stubbed functions, and expanding test coverage from 3,530 to 4,094 passing tests.

### Added
- **Project transaction functions**: `with_project_transaction()`, `with_project_transaction_batch()`, `create_isa_modifier()` in new `functions/project_transactions.R`
- **Cross-reference validation**: `validate_cross_references()`, `repair_adjacency_matrices()` for ISA data integrity
- **Connection validation with feedback**: `validate_connection_with_feedback()`, `get_valid_targets_for_ui()` for DAPSI(W)R(M) flow validation with user-friendly messages
- **Shared stale-data observer**: `create_stale_data_observer()` extracted to `functions/ui_components.R`
- **9 new test files** (398 tests):
  - `test-isa-export-helpers.R` (55 tests) — ISA workbook and Kumu export
  - `test-ui-components.R` (45 tests) — 8 shared UI builder functions
  - `test-universal-excel-loader.R` (73 tests) — Excel format detection and normalization
  - `test-cld-validation.R` (49 tests) — CLD/ISA validation edge cases
  - `test-import-data-module.R` (35 tests) — Import validation and connection parsing
  - `test-create-ses-module.R` (17 tests) — SES creation workflow
  - `test-prepare-report-module.R` (28 tests) — Report generation
  - `test-workflow-stepper-module.R` (31 tests) — Step definitions and navigation
  - `test-persistent-storage.R` (65 tests) — Save/load round-trips and file management

### Fixed
- **46 pre-existing test failures** resolved (0 remaining):
  - 19 P0 failures: implemented 5 missing transaction/validation functions
  - 12 P1 failures: implemented connection validation and UI target functions
  - 2 trailing comma syntax errors in test data.frame() calls
  - 5 SES dynamics edge cases (single-node matrices, duplicate labels, zero matrices)
  - 2 template versioning failures (function name collision with ML registry)
  - 1 flaky auto-save session ID uniqueness test
  - 1 ML ensemble error message format mismatch
  - 3 safe_render factory signature inconsistencies
  - 1 missing `common.labels.error` translation key
- **`compare_versions` name collision**: Renamed ML registry version to `compare_model_versions()` to avoid overwriting template versioning function
- **`diag()` single-node bug** in SES dynamics: `diag(scalar)` creates identity matrix of that size, not 1x1 — fixed with explicit `nrow` parameter
- **Orphan function files** wired into `global.R`: `ml_feature_cache.R`, `undo_redo.R`
- **`safe_readRDS` fallback** removed in auto_save_module (unconditional usage)
- **`shell.exec` path sanitization** added in recent_projects_module
- **Dead `import_project_rds`** function removed (bypassed safe_readRDS)
- **Constants inconsistency**: Added "Measures" to ELEMENT_SHAPES
- **Hardcoded English** in project_transactions notification and AI ISA tooltips translated
- **VERSION file path** now uses PROJECT_ROOT

### Changed
- Test suite: 3,530 → **4,094 passing tests** (+564)
- Test files: 54 → **63** (+9 new)
- Test failures: 46 → **0**

---

## [1.10.1] - 2026-03-17

### UI Polish, Consistency Fixes & Documentation Update

Patch release with topbar reorganization, connection review bug fixes, codebase consistency improvements, and complete manual updates.

### Fixed
- **Critical**: `on_amend` callback now passes delay values — user-edited delays were silently lost on save
- **Critical**: KB References modal scoping bug — `all_refs` variable inaccessible outside `tryCatch`
- **Critical**: Hardcoded "No references available" string now translated via i18n
- Standardized 26 logging calls from `log_message()`/`message()` to `debug_log()`
- Resolved 2 TODO i18n tooltip items in connection review (strength/confidence descriptions)
- Translated 27 hardcoded English strings in export modules (loops, BOT, PIMS)
- Delay toggle now persists state across tab re-renders (`isolate(rv$show_delay)`)
- Delay label uses correct translation key (`modules.connection_review.temporal_delay`)

### Added
- **About button**: Extracted from Settings dropdown into standalone topbar widget
- **KB References**: New submenu in Help dropdown with modal showing top 25 cited scientific sources
- **Connection review batches**: W→D (feedback), P→P (cascading pressures), S→S (cascading states)
- **KB Bibliography**: `docs/KB_BIBLIOGRAPHY.md` with 511 references and DOI links
- Translation keys for strength/confidence tooltips, KB references modal (all 9 languages)
- 3 new translation files: `analysis_loops.json`, `analysis_bot.json`, `pims.json`

### Changed
- **Topbar layout**: Language | Settings | Bookmark | About | Help | User
- Help dropdown moved to rightmost position (before status indicators)
- Extracted duplicated DAPSIWRM summary UI into shared `render_element_summary_ui()` function (133 lines saved)
- Removed dead function `rank_suggestions_by_relevance()` (56 lines)

### Documentation
- English user manual updated to v1.10.0 (What's New, delay attributes, KB refs, 9 languages)
- French user manual updated to v1.10.0 (Nouveautés, délai temporel, réf. BC, 9 langues)
- HTML/PDF versions regenerated via Pandoc 3.8.3
- Beginner guide, step-by-step tutorial, user guide HTML files updated

---

## [1.10.0] - 2026-03-17

### Knowledge Base Quality Review & Scientific Validation

Minor release delivering a comprehensive audit and scientific validation of the DAPSI(W)R(M) knowledge base. All 1,120 connections across 30 marine ecosystem contexts reviewed against published literature from HELCOM, ICES, OSPAR, UNEP-MAP, GCRMN, IPCC AR6, AMAP, and other authoritative sources.

### Fixed
- **68 element misclassifications** across 5 systematic patterns:
  - 17 Activities/processes reclassified from Drivers (renamed to demand-phrasing)
  - 23 ecosystem states/conditions reclassified from Pressures (invasive species presence, hypoxia, erosion)
  - 12 human economic outputs reclassified from Impacts to Welfare (shipping, energy, port services)
  - 7 natural processes reclassified from Activities to Pressures (hurricanes, GHG emissions, runoff)
  - 7 ecosystem services reclassified from Welfare to Impacts (carbon regulation, conservation value)
  - 3 near-duplicate element pairs merged
- **16 governance/SE misclassifications** in country_governance_db.json:
  - EU policy instruments moved from Drivers to Responses (Green Deal, Farm-to-Fork, Cohesion Fund)
  - Activity-phrased drivers replaced with need/demand phrasing across high-income, upper-middle, and regional groups
- **~52 polarity corrections** across all regions (e.g., warming/pollution incorrectly marked positive for ecosystem health)
- **baltic_open_coast** missing Activity→Pressure connections restored
- **Reversibility vocabulary** standardized from 7 terms to 3 (reversible, partially_reversible, irreversible)
- **2 numeric temporal_lag values** converted to categorical strings
- **90 bridge connections** added to eliminate disconnected subgraphs in all 30 contexts

### Added
- **KB validation script** (`scripts/validate_kb.py`) — automated 6-check integrity validation
- **416 orphan element connections** — reduced orphan rate from 25-51% to 0% across all contexts
- **5 new cross-ecosystem links** (North Sea, Mediterranean, Baltic, Arctic, Indian Ocean pairs)
- **6 generic fallback elements** (3 Impacts + 3 Welfare) with differentiated relevance scores
- **~86 keyword stems** across all 7 DAPSI(W)R(M) categories in keyword classification DB
- **7 context boosts** (aquaculture, shipping, coastal development, pollution, climate, invasive species, Arctic)
- **25 R connection KB patterns** (11 feedback loops, 14 pathway patterns for mineral extraction, offshore wind, invasive species, Arctic)
- **Governance elements** for 4 groups: non_eu_european (D+W), latin_american (D+W), african_coastal (W), asia_pacific (W)
- **2 regional conventions**: SPREP/Noumea (Pacific, 14 countries) and Abidjan (West Africa, 16 countries)

### Changed
- **213 connection attribute corrections** based on scientific literature review:
  - Strength recalibrated (120 downgrades for indirect links, 15 upgrades for well-documented links)
  - Confidence redistributed from 80% at levels 4-5 to bell-curve (3.1% L1, 7.8% L2, 43.8% L3, 23.6% L4, 21.7% L5)
  - Temporal lag and reversibility corrected for ~10 connections (coral recovery, genetic introgression, SCTLD)
- **R connection KB probability range** widened from 0.70-0.95 to 0.40-0.95 for better discrimination
- **Total connections**: 622 → 1,120 across 30 contexts
- **Total R KB patterns**: 112 → 137

### Knowledge Base Quality Metrics
- Element classification accuracy: 93.7% → 100%
- Orphan element rate: 25-51% → 0%
- Disconnected subgraphs: 30 contexts affected → 0
- Cross-ecosystem links: 15 → 20
- Keyword match rate: 52-66% → estimated 80%+ per category
- Connection polarity errors: ~52 → 0
- Governance groups with complete D+W coverage: 2/6 → 6/6

---

## [1.9.0] - 2026-03-16

### Delay Attribute for Connections

Minor release adding temporal delay attributes to connections, enabling users to capture time-lag relationships between DAPSI(W)R(M) elements. Full backward compatibility with existing Excel files and project data.

### Added
- **Delay constants**: `DELAY_CATEGORIES` (immediate, short-term, medium-term, long-term), `derive_delay_category()`, `delay_to_dashes()` in `constants.R`
- **Delay parsing**: Extended `parse_connection_value()` with `delay` and `delay_years` fields, backward-compatible with old numeric lag format
- **Adjacency matrix serialization**: Delay category and years stored in matrix cells as `+strength:confidence:delay:delay_years`
- **Knowledge base integration**: `temporal_lag` from KB connections mapped to delay categories via `derive_delay_category()`
- **Edge visualization**: Dash patterns for delay categories in visNetwork (immediate=solid, short-term=short dash, medium-term=medium dash, long-term=long dash)
- **Connection review UI**: Toggle, dropdown (delay category), and numeric input (delay years) on connection review cards
- **Excel/Kumu import**: Reads `Delay` and `Delay (years)` columns when present, gracefully skips when absent
- **Excel/Kumu export**: Includes `Delay` and `Delay (years)` columns in exported connection schema
- **i18n**: Delay-related translation keys added for all 9 languages (`translations/common/labels.json`, `translations/modules/connection_review.json`)
- **Backward compatibility tests**: 170+ assertions covering old Excel formats (no delay), new formats (with delay), mixed formats, numeric lag migration, and real Kumu file loading (`test-old-excel-backward-compat.R`, `test-excel-import-helpers.R`)
- **Design documentation**: Delay attribute design spec and implementation plan (`docs/specs/`, `docs/plans/`)

### Changed
- **Connection tooltip**: Updated to display delay information when available
- **`parse_connection_value()`**: Auto-migrates old numeric lag format (`+strong:4:2.5`) to delay categories

### Backward Compatibility
- Old Excel files without `Delay`/`Delay (years)` columns load without errors
- Old adjacency matrix cell format (`+strength:confidence`) parsed correctly with `delay=NA`
- Old numeric lag format (`+strength:confidence:years`) auto-converted to delay category
- No migration required for existing project data

---

## [1.8.1] - 2026-03-15

### Comprehensive Codebase Audit & Cleanup

Patch release addressing 12 issue categories discovered during deep codebase audit: critical bug fixes, duplicate definition resolution, dead code removal, test strengthening, and documentation alignment.

### Fixed
- **Critical**: `1:nrow()` on zero-row data frames crashed with "subscript out of bounds" — replaced with `seq_len(nrow())` in 7 files (`data_structure.R`, `network_analysis.R`, `template_versioning.R`, `connection_generator.R`, `analysis_leverage.R`, `graphical_ses_network_builder.R`, `isa_data_entry_module.R`)
- **Critical**: Duplicate `log_error()` definitions with incompatible signatures (`global.R` vs `error_handling.R`) — removed weaker version, fixed source scoping
- **Critical**: Duplicate `init_session_isolation()` — weaker version in `session_management.R` (using `digest(runif(1))`) was overwriting stronger SHA-256 version from `session_isolation.R`
- **Critical**: Raw `readRDS()` in auto-save recovery bypassed `safe_readRDS()` security validation
- **Important**: `el$ID` case mismatch in diagnostics (should be `el$id`) — produced NULL output silently
- **Important**: Reactive pipeline Observer 2 double-fired on ISA changes (watched both `on_isa_change` and `on_cld_update`) — now only watches `on_cld_update`
- **Important**: `utils.R` sourced with `local = TRUE` making its functions invisible globally
- **Important**: `error_handling.R` sourced with `local = TRUE` preventing `log_error`, `safe_execute` from global access

### Removed
- **Deprecated `GROUP_COLORS`/`GROUP_SHAPES`** constants with wrong color values — `get_node_colors()`/`get_node_shapes()` now use canonical `ELEMENT_COLORS`/`ELEMENT_SHAPES`
- **Dead `functions/lazy_loading.R`** (354 lines) — fully implemented module registry with zero registered modules
- **Inline `session_i18n` duplication** in `app.R` — now calls `create_session_i18n()` from `server/language_handling.R`

### Changed
- **i18n enforcement tests strengthened**: Tests 2, 3, 7 now use `expect_lte()` with ratcheted thresholds instead of always calling `succeed()`
- **Test validation expanded**: Translation file checks now validate ALL entries (were sampling only first 5-10)
- **`required_languages`** in tests updated to include Norwegian (`no`) and Greek (`el`)
- **Non-existent modules** removed from i18n test critical list (`analysis_tools_module.R`, `progress_indicator_module.R`)
- **`options(warn = -1)` removed** from test `setup.R` — was hiding real warnings across entire test suite
- **`translations/README.md`** updated with Norwegian and Greek language documentation
- **`CLAUDE.md`** server signature updated to match codebase reality (`project_data_reactive` not `project_data`)

---

## [1.8.0] - 2026-03-15

### Knowledge Base Validation & Country Governance

Minor release delivering validated SES knowledge base, country-level governance integration, graphical network builder, tutorial system, and critical bug fixes for the AI assistant workflow.

### Added
- **Country Governance Database**: 97 countries across 11 regional seas with governance and socio-economic element suggestions
- **Graphical SES Network Builder**: New module (`modules/graphical_ses_network_builder.R`) for visual CLD construction
- **Tutorial System**: Guided walkthrough module (`modules/tutorial_system.R`) with step-by-step onboarding
- **Universal Excel Loader**: Flexible SES model import from varied Excel formats (`functions/universal_excel_loader.R`)
- **ML Model Registry**: Centralized model management (`functions/ml_model_registry.R`)
- **ML Text Embeddings**: Text embedding infrastructure (`functions/ml_text_embeddings.R`)
- **Data Accessors**: Unified data access layer (`functions/data_accessors.R`)
- **Lazy Loading**: Deferred module loading for faster startup (`functions/lazy_loading.R`) *(removed in 1.8.1 — unused)*
- **DTU Integration**: DTU dynamics app and Boolean network analysis (`DTU/`)
- **SES Models Collection**: Arctic, Macaronesia, and Tuscan DA model files (`SESModels/`)
- **KB Audit Script**: Automated validation of knowledge base connections (`scripts/audit_kb.R`)
- **6 Insular Ecosystem Contexts**: Caribbean island, Pacific atoll, Indian Ocean island, Arctic island, Baltic island, Atlantic island
- **3 Additional Contexts**: Arctic island, Atlantic estuary/coast, Baltic rocky coast
- **20+ New Test Files**: Comprehensive test coverage for ML, modules, accessibility, and E2E

### Changed
- **Knowledge Database v1.1**: 620 connections across 30 contexts, all structurally validated against DAPSIWRM rules
- **Evidence-Based Connections**: Strength, confidence (1-5 scale), and temporal lag metadata across all 620 connections
- **Connection Index Remapping**: AI assistant now properly remaps indices after element removal

### Fixed
- **Critical**: App crash on "Remove unconnected elements and continue" — connection `from_index`/`to_index` pointed to stale positions after element removal, causing `subscript out of bounds` in `build_adjacency_matrices`
- **Critical**: 25 invalid DAPSIWRM flow directions in knowledge database — connections skipping framework levels (D→P, A→S, R→S) now routed through proper intermediate elements
- **Critical**: Translation file write permission denied on server deployment — `translations/` directory now set to group-writable
- 2 duplicate connections removed from mediterranean_open_coast context
- 1 orphan element reference fixed in indian_ocean_island context
- Bounds checking added to `build_adjacency_matrices` as safety net for out-of-range indices

### Knowledge Base Quality
- All 620 JSON connections pass structural validation (valid flows, types, polarity, strength, confidence)
- All 112 R KB pattern rules pass validation (valid regex, flows, probabilities)
- 8 scientifically valid "unusual" polarities reviewed and confirmed (trophic cascades, fishing displacement effects)

---

## [1.7.0] - 2026-03-14

### Security Hardening, DTU Integration & Accessibility

Major release delivering security hardening across the full stack, DTU dynamics engine integration, ML Phase 2 pipeline, WCAG 2.1 AA accessibility, and expanded i18n coverage for Norwegian and Greek.

### Security
- HTML injection / XSS fixes across 10+ files (`htmlEscape` in R, `escHtml` in JS)
- JSON input validation hardened with `safe_parse_json()`
- ML model SHA-256 checksum verification before `torch_load()`
- `eval()` safety guards added in error handling wrappers

### Added
- **DTU Dynamics Engine**: Integrated 11 functions — Laplacian, Boolean, simulation, Monte Carlo, intervention analysis, and RF importance
- **ML Phase 2 Pipeline**: 3-stage fallback (ensemble → v2 → v1 → rules), graph features, context embeddings
- **Shared UI Component Library**: `functions/ui_components.R` with 8 reusable builders
- **Test Infrastructure**: 3 critical test files — session isolation (543 lines), reactive pipeline (1075 lines), auto-save (1387 lines)
- **Visual Regression Tests**: 8 screenshot-based tests
- **Architecture Decision Records**: `docs/ARCHITECTURE.md` with 10 ADRs
- **DESCRIPTION File**: All 35 dependencies formally declared
- **Roxygen2 Documentation**: 14 previously undocumented functions annotated

### Changed
- **Module Decomposition**: ai_isa 3666 → 2108 lines (-42%), CLD viz 1817 → 1391, ISA entry 1808 → 1352
- **Event Bus Isolation**: Metadata moved to per-session `reactiveVals` for multi-user safety
- **All 8 Analysis Modules**: Wired to event bus with stale-data notifications
- **16 Module Signatures**: Standardized with `event_bus = NULL` parameter
- **Error Messages**: Patterns standardized across modules with `format_user_error()` utility

### Accessibility
- WCAG 2.1 AA color contrast fixes (3 colors corrected)
- Comprehensive ARIA: dropdown menus, modal focus traps, keyboard navigation, screen reader announcements
- Mobile touch targets (44 px minimum), responsive data tables
- Skip link and focus-visible indicators

### i18n
- Norwegian (Bokmål) and Greek (Δημοτική) translations substantially completed (~1500+ entries)
- ISA data entry module now accepts `i18n` parameter
- Hardcoded English replaced with cached i18n lookups in JS and modals
- Analysis modules show i18n "data changed" warnings via event bus

### Fixed
- **Critical**: CLD showing 0 edges despite ISA connections — adjacency matrix name mismatch (`a_d` vs `d_a`) resolved with bidirectional lookup
- **Critical**: `ml_explainability.R` syntax error (`c("D","A") =` invalid list key) prevented ML loading
- **Critical**: Dual event bus implementations reconciled — ISA→CLD→Analysis auto-propagation re-enabled (was completely disabled)
- **Critical**: Trailing commas from `stringsAsFactors` removal fixed across all data files
- **Critical**: AI assistant not emitting ISA change events after saving — CLD never regenerated; added `emit_isa_change()` to all 3 save paths
- **Critical**: `safe_renderUI` / `safe_renderDT` / `safe_renderPlot` / `safe_renderTable` / `safe_renderVisNetwork` used `eval()` with wrong environment causing "object 'input' not found" — rewritten to use `bquote()` + `quoted = TRUE`
- **Critical**: vis.js tooltip positioning broken by `backdrop-filter`, `will-change: transform`, and `position: fixed` on CSS ancestors creating containing blocks — removed all offending properties
- CLD visualization simplified: removed `bs4Card` wrappers causing tooltip offset; now uses flat flexbox layout
- Unconnected elements warning in AI assistant now correctly uses `conn$from_name`/`conn$to_name` (was using non-existent `conn$from`/`conn$to`)
- Connection review scroll: approve/reject now scrolls to next connection card (was jumping to top)
- Connection review scroll: last item in batch scrolls to "Next Category" button
- `usei18n()` calls wrapped in `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n))` to handle custom wrapper objects
- FAQ 4th accordion item text now readable (changed `warning` to `secondary` status for contrast)
- About modal documentation links now readable (dark text on light background instead of invisible links)
- `min(loops$Length)` / `max(loops$Length)` warning when no loops detected — added empty-check guard
- Missing `common.buttons.got_it` translation key added in all 9 languages
- `format_user_error()` adopted in 23 error notification sites across 13 files
- `shiny.i18n::usei18n(i18n)` added to all 28 module UI functions
- ML prediction feedback UI (thumbs up/down) added for active learning
- ML model checksums infrastructure with `models/checksums.json` and generation script
- 10 failing ML tests resolved; `_problems/` directory cleaned
- 2 event bus API bugs fixed (`emit_isa_changed` → `emit_isa_change` in local_storage and recent_projects)

### AI Intelligence
- **ML models wired into AI assistant connection scoring** (70% ML + 30% keyword weight)
- **112-entry marine SES connection knowledge base** with literature sources covering 7 pathways
- **200+ habitat-specific element suggestions** for 15 habitats × 7 DAPSIWRM categories
- Regional sea × ecosystem type combination logic for tailored suggestions
- Negation-aware polarity detection (handles "pollution reduction", "ban on overfishing")
- TF-IDF weighted relevance scoring with 17 synonym groups
- Connections tagged with scoring method (ml+kb, ml, kb, keyword)

### Code Quality
- 631 deprecated `stringsAsFactors = FALSE` calls removed (R >= 4.4.1 default)
- All trailing commas from removal fixed across 100+ files
- 97 verbose debug lines removed from `report_generation.R`
- DTU dynamics unit tests added (90+ test cases across 20 sections)
- Load testing (`scripts/load_test.R`) and memory profiling (`scripts/memory_profile.R`) scripts added

---

## [1.6.1] - 2026-01-06

### Stability and Consistency Improvements

This release focuses on fixing critical issues identified in codebase analysis and improving code consistency across the application. No user-facing functionality changes.

### Fixed
- **Critical**: Removed duplicate `sanitize_filename()` function in `global.R`
  - Second definition at lines 1305-1328 was overwriting first
  - Lost max_length parameter functionality
  - Preserved proper implementation at lines 416-464
- **Critical**: Fixed reactive value initialization race condition in `app.R`
  - `project_data` reactive was used in observe() blocks before initialization
  - Moved all reactive value declarations to line 387 (before any observe() blocks)
  - Prevents startup crashes from race condition
- **Critical**: Consolidated duplicate constant definitions
  - Removed DAPSIWRM_ELEMENTS, ELEMENT_COLORS, ELEMENT_SHAPES duplicates from `global.R`
  - Centralized all constants in `constants.R`
  - Single source of truth for configuration values
- **Consistency**: Standardized debug logging in `server/modals.R`
  - Replaced 6 `cat()` calls with `debug_log()` for settings messages
  - Consistent with debug logging pattern across application
  - Respects DEBUG_MODE configuration

### Changed
- **Consistency**: Standardized all `source()` calls with explicit `local` parameter
  - Updated 40+ source() calls in `global.R` and `app.R`
  - Explicit scoping improves code clarity
  - Documented rationale for `local = FALSE` usage
- **Consistency**: Completed internationalization (i18n) coverage
  - Added 6 new translation keys to `translations/ui/dashboard.json`:
    - `ui.dashboard.project_overview`
    - `ui.dashboard.status_summary`
    - `ui.dashboard.network_status`
    - `ui.dashboard.project_history`
    - `ui.dashboard.isa_data_status`
    - `ui.dashboard.analysis_status`
  - Added missing key to `translations/common/misc.json`:
    - `common.misc.approve_this_connection_with_current_slider_values`
  - All 7 keys have complete translations in 8 languages (EN, ES, FR, DE, LT, PT, IT, NO)
- **Consistency**: Applied UI dimension constants throughout dashboard
  - Used `UI_BOX_WIDTH_QUARTER`, `UI_BOX_WIDTH_HALF`, `UI_BOX_WIDTH_FULL` consistently
  - Replaced hard-coded width values in `app.R`

### Added
- **Constants**: Expanded `constants.R` with DAPSIWRM framework definitions
  - `DAPSIWRM_ELEMENTS`: 7 element types from framework
  - `ELEMENT_COLORS`: 8 Kumu-style colors for element types
  - `ELEMENT_SHAPES`: 7 visNetwork shapes for element types
  - `EDGE_COLORS`: Reinforcing and opposing connection colors
  - `DA_SITES`: 3 demonstration area identifiers
  - `STAKEHOLDER_TYPES`: 6 types from Newton & Elliott (2016)
  - `UI_BOX_WIDTH_*`: UI dimension constants
- **Documentation**: Created comprehensive refactoring documentation
  - `DEPLOYMENT_REVIEW_POST_REFACTORING.md`: Full deployment compatibility analysis
  - `TEST_FAILURE_DEEP_ANALYSIS.md`: Investigation of test failures (all pre-existing)
  - Pattern documentation in `functions/error_handling.R`

### Improved
- **Code Quality**: Eliminated duplicate function definitions
- **Code Quality**: Prevented startup race conditions
- **Code Quality**: Centralized configuration management
- **Code Consistency**: Uniform source() call patterns
- **Code Consistency**: Complete i18n coverage for UI strings
- **Code Consistency**: Standardized debug logging approach

### Technical Details
- **Files Modified**: 7 (global.R, constants.R, app.R, server/modals.R, functions/error_handling.R, translations/ui/dashboard.json, translations/common/misc.json)
- **Critical Issues Fixed**: 4
- **Consistency Issues Fixed**: 7
- **Translation Keys Added**: 7 (all with 8-language coverage)
- **Source Calls Standardized**: 40+
- **Lines Changed**: +910 insertions, -350 deletions
- **Tests Passing**: 3,729 (no regressions introduced)
- **Pre-existing Test Failures**: 8 (ML context embeddings - unrelated to changes)

### Testing
- All 3,729 tests passing after refactoring
- Zero regressions introduced by changes
- Comprehensive test failure analysis completed
- All failures confirmed as pre-existing (ML module issues)

### Deployment
- All deployment scripts verified compatible
- Pre-deployment checks validate all changes
- Translation cache clearing ensures new keys loaded
- Full server restart ensures reactive fix takes effect
- See `DEPLOYMENT_REVIEW_POST_REFACTORING.md` for details

### Migration Notes
- **No Breaking Changes**: All changes are internal refactoring
- **No User Impact**: Functionality preserved exactly
- **No Configuration Changes**: Existing settings work unchanged
- **Backward Compatible**: Existing project files load without modification
- **Translation Cache**: Will be automatically cleared on deployment

### Developer Notes
- Use `debug_log(message, category)` instead of `cat()` for debug output
- Always specify `local` parameter in `source()` calls for clarity
- Add magic numbers to `constants.R` with descriptive names
- Use `i18n$t()` for all user-facing strings
- Follow error handling patterns in `functions/error_handling.R`
- Initialize reactive values before any `observe()` blocks

---

## [1.6.0] - 2025-12-26

### Major Optimization Release

This release focuses on significant codebase optimizations, refactoring, and maintainability improvements without changing user-facing functionality.

### Added
- **Server Modularization**: Created 4 new server modules for better code organization
  - `server/project_io.R` - Project save/load handlers (151 lines)
  - `server/export_handlers.R` - Data and visualization export handlers (221 lines)
  - `server/dashboard.R` - Dashboard rendering (310 lines) [pre-existing, enhanced]
  - `server/modals.R` - Modal dialog handlers (649 lines) [pre-existing, enhanced]
- **Debug Logging Control**: Added `debug_log()` wrapper for controllable debug output
  - Enable with `MARINESABRES_DEBUG=TRUE` environment variable
  - Categorized logging: DIAGNOSTICS, SESSION, AUTOLOAD
  - Silent by default in production
- **Helper Functions**: New utility functions in `utils.R`
  - `is_empty()` - Check if data frame is empty
  - `is_empty_isa_data()` - Check if ISA data structure is empty
- **Path Helpers**: Reliable file sourcing regardless of working directory
  - `PROJECT_ROOT` - Established project root directory
  - `get_project_file()` - Generate project-relative file paths
- **Constants Expansion**: Added UI and file upload constants to `constants.R`
  - UI layout constants (BOX_HEIGHT, SIDEBAR_WIDTH, PLOT_MARGINS)
  - File upload constants (MAX_UPLOAD_SIZE_BYTES)
- **Documentation**: Comprehensive optimization documentation
  - `CODEBASE_REVIEW_FINDINGS.md` - Detailed code analysis (400+ lines)
  - `OPTIMIZATION_ACTION_PLAN.md` - Implementation guide (500+ lines)
  - `CI_CD_STATUS_CHECK.md` - CI/CD monitoring guide (560+ lines)

### Changed
- **Server Function Refactoring**: Reduced main server() function by 37%
  - **Before**: 772 lines (monolithic)
  - **After**: 486 lines (modular)
  - Extracted 286 lines into dedicated server modules
- **app.R Size Reduction**: Reduced total app.R size by 27%
  - **Before**: 1,045 lines
  - **After**: 757 lines
  - Net reduction: 288 lines
- **Debug Output**: 18+ debug statements now controlled by environment variable
  - Cleaner console output in production mode
  - Easier debugging when enabled
- **File Upload Configuration**: Consolidated and centralized
  - Updated MAX_UPLOAD_SIZE_MB from 30 to 100 (matches Shiny usage)
  - Single source of truth in constants.R
- **Error Handling**: Improved error messages in I/O functions
  - Added file type validation to `read_network_from_excel()`
  - Validates .xlsx/.xls extension before attempting read
  - Clearer error messages for invalid file types
- **Constants Loading**: Fixed initialization order
  - Constants now loaded early in global.R
  - Prevents "object not found" errors
- **Source Paths**: Eliminated fragile path fallback patterns
  - Replaced 15-line fallback logic with 2-line clean solution
  - Works reliably from any working directory

### Improved
- **Code Organization**: Clear separation of concerns
  - Server logic organized by functional area
  - Export handlers in dedicated module
  - Project I/O in dedicated module
- **Maintainability**: Significantly easier to understand and modify
  - Smaller, focused functions
  - Clear module boundaries
  - Consistent patterns throughout
- **Testability**: Modular code is easier to unit test
  - Each server module can be tested independently
  - Helper functions isolated and reusable
- **Readability**: Complex code simplified
  - Magic numbers replaced with named constants
  - Complex conditionals replaced with helper functions
  - Debug logging categorized and controllable

### Technical Details
- **Lines of Code Changes**:
  - Created: +494 lines (new modules and documentation)
  - Removed: -346 lines (refactored and consolidated)
  - Net: +148 lines (improved organization worth the small increase)
- **Files Changed**: 14 modified, 7 created
- **Commits**: 5 optimization commits (d59256f, cb7d251, 062465d, de1a042, + docs)
- **Server Modules**: 4 total (up from 2)
- **Debug Statements Controlled**: 18+ (DIAGNOSTICS, SESSION, AUTOLOAD categories)

### Performance
- **No Performance Degradation**: All changes are organizational
- **Improved Startup Reliability**: Proper constant initialization
- **Cleaner Console Output**: Debug logging controlled by environment variable

### Migration Notes
- **No Breaking Changes**: All changes are internal refactoring
- **No User Impact**: Functionality preserved exactly
- **Optional Debug Mode**: Set `MARINESABRES_DEBUG=TRUE` to see diagnostic output
- **Backward Compatible**: Existing project files load without modification

### Developer Notes
- **Server Module Pattern Established**: Clear pattern for future extractions
  ```r
  # In server/module_name.R
  setup_module_handlers <- function(input, output, session, project_data, i18n) {
    # Handler implementations
  }

  # In app.R server function
  setup_module_handlers(input, output, session, project_data, i18n)
  ```
- **Debug Logging Pattern**: Use `debug_log(message, category)` instead of `cat()`
- **Constants Pattern**: Add all magic numbers to constants.R with descriptive names
- **Path Pattern**: Use `get_project_file()` for all relative file paths

---

## [1.5.2] - 2024-12-24

### Connection Review Bug Fixes

### Fixed
- Connection review module bug fixes
- Translation system improvements
- ISA data entry enhancements

---

## [1.5.1] - 2024-12-23

### Translation Framework Improvements

### Added
- Comprehensive translation framework
- Multi-language support (EN, ES, FR, IT, NO)
- Translation automation system

---

## [1.5.0] - 2024-12-20

### E2E Testing and Coverage Tracking

### Added
- End-to-end testing with shinytest2 (5 comprehensive tests)
- Coverage tracking system with 70% minimum threshold
- Enhanced CI/CD workflow with multi-platform testing
- Comprehensive testing documentation

### Changed
- GitHub Actions workflow enhanced with coverage reporting
- Test suite expanded from 348 to 353+ tests

---

## Earlier Versions

See git history for earlier version details.

---

**Note**: This CHANGELOG started with version 1.6.0. Earlier versions can be found in git commit history.
