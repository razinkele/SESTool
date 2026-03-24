# KB-Enhanced Reports with Local Context — Design Spec

## Goal

Connect the existing Knowledge Base (32+ regional contexts with scientific citations, rationale, confidence) into report generation, and persist regional context (regional sea + ecosystem type) in project metadata so reports can be tailored to the user's geographic and ecological setting. Add governance framework references from the country governance DB.

## 1. Persist Regional Context in Project Metadata

### Metadata Fields

Add two new fields to project metadata, stored as **short keys** (lowercase, underscore-separated) matching the KB and governance DB key format:
- `regional_sea` — string, short key format (e.g., `"baltic"`, `"north_sea"`, `"mediterranean"`). This matches the KB context keys in `data/ses_knowledge_db.json` and `data/country_governance_db.json`.
- `ecosystem_type` — string, short key format (e.g., `"lagoon"`, `"estuary"`, `"coral_reef"`). Derived from `ECOSYSTEM_TYPE_CHOICES_DETAILED` via `tolower()` + `gsub(" ", "_", ...)`.

Default: `NULL` (not set). Both optional — reports degrade gracefully without them.

**Key format mapping:** The AI ISA flow already stores short keys in `rv$context$regional_sea` (e.g., `"baltic"`). The Dashboard dropdowns must also store short keys, using named choices: `setNames(c("baltic", "north_sea", ...), c("Baltic Sea", "North Sea", ...))` so the display name is human-readable but the stored value is the short key. The KB API functions (`get_context_elements()`, `get_context_connections()`) expect short keys.

### Entry Point 1: AI ISA Flow

In `modules/ai_isa_assistant_module.R`, persist context to project-level metadata in BOTH save paths:

**Auto-save path (`.do_finish_and_save()`, ~line 979):** After `save_to_project_format(rv, current_data, ...)` returns, add:
```r
current_data$data$metadata$regional_sea <- rv$context$regional_sea
current_data$data$metadata$ecosystem_type <- rv$context$ecosystem_type
```

**Manual save path (`input$save_to_isa` observer, ~line 2513):** Same two lines after the existing metadata writes.

Note: `rv$context` is accessible at both save points since it's a reactiveValues in the module scope.

### Entry Point 2: Manual Setting on Dashboard

In the Dashboard project overview section (`server/dashboard.R` or equivalent), add two dropdown selectors using named choices (display name → short key):
```r
selectInput("regional_sea_select",
  i18n$t("modules.report_context.regional_sea_label"),
  choices = c("Not set" = "", setNames(
    c("baltic", "north_sea", "celtic_seas", "bay_of_biscay", "western_mediterranean",
      "adriatic", "ionian", "aegean_levantine", "black_sea", "macaronesia",
      "arctic", "caribbean"),
    REGIONAL_SEA_CHOICES
  )),
  selected = project_data$data$metadata$regional_sea %||% ""
)
```

Similarly for ecosystem_type. These update `project_data$data$metadata$regional_sea` on change.

### Data Structure Change

In `functions/data_structure.R`, the `create_empty_project()` function (line 27) that creates the default project metadata structure (lines 38-48) should include:
```r
metadata = list(
  ...,
  regional_sea = NULL,
  ecosystem_type = NULL
)
```

Adding `NULL` fields is safe for existing saved projects — `data$data$metadata$regional_sea` returns `NULL` for old projects, which is the intended "not set" default. No migration needed.

## 2. KB Context Section in Reports

### New Report Section: "Regional Context"

Position: after Executive Summary, before Technical Analysis (ISA Details).

**Content structure:**

#### 2a. Site Description
- Query KB via `get_context_elements(regional_sea, habitat)` using the project's metadata
- Include the KB context `description` field (1-2 sentences describing the regional ecosystem)
- List top relevant elements per DAPSI(W)R(M) category (relevance > 0.8) as context for the user's analysis

#### 2b. Scientific References for User's Connections
- For each connection in the user's CLD, look up matching KB connections via `get_context_connections()`
- Match by: from_element name similarity AND to_element name similarity (fuzzy match using KB's existing synonym system)
- For matched connections, include:
  - `rationale` — scientific explanation text
  - `references` — citation list (e.g., "HELCOM 2018", "ICES 2020")
  - `temporal_lag` — e.g., "short-term", "medium-term", "long-term"
  - `reversibility` — e.g., "reversible", "partially_reversible", "irreversible"
- For unmatched connections (user's connections not in KB), flag as "User-defined, no KB reference available"

#### 2c. Confidence Assessment
- Compare KB confidence scores with user's confidence (if set) for matched connections
- Summary: "X of Y connections have KB scientific support"
- Highlight divergences: connections where user confidence differs significantly from KB confidence

## 3. Regional Recommendations

### Enhanced Strategic Recommendations

Enhance `generate_strategic_recommendations()` in `functions/report_generation.R`. The function already receives `data` as its first argument, which contains `data$data$metadata$regional_sea` and `data$data$metadata$ecosystem_type`. **Read the metadata from `data` internally — do not add new parameters to the function signature.** This avoids breaking existing callers and the propagation chain through content generators (`generate_executive_content(data)`, etc.) which only pass `data`.

#### 3a. Region-Specific Management Priorities
- From KB: elements with highest relevance scores for the regional context
- Framed as: "For [regional_sea] [ecosystem_type] systems, key management priorities include..."
- Based on top-scoring pressures and responses from KB

#### 3b. Governance Context
- Query `data/country_governance_db.json` via the existing `country_governance_loader.R`
- Include relevant governance frameworks based on regional sea:
  - Baltic → HELCOM, EU MSFD, Baltic Sea Action Plan
  - Mediterranean → Barcelona Convention, UNEP/MAP
  - North Sea → OSPAR
  - etc.
- Format as: "Relevant governance frameworks: ..."
- Include country-specific regulations if countries are set in metadata

#### 3c. KB-Informed Intervention Suggestions
- For each top leverage point identified in the analysis, check if KB has matching response elements
- Include KB-suggested responses with their relevance scores
- Framed as: "Published literature suggests the following responses for [leverage_point]..."

## 4. Core Functions: `functions/kb_report_helpers.R`

### `get_kb_context_for_report(regional_sea, ecosystem_type)`
- Input: `regional_sea` as short key (e.g., `"baltic"`), `ecosystem_type` as short key (e.g., `"lagoon"`)
- Passes directly to existing KB API which handles the key concatenation (`"baltic_lagoon"`) and fallback logic internally
- Returns list: `description`, `top_elements` (per category, relevance > 0.8), `available` (boolean)
- Returns `list(available = FALSE)` if no matching context

### `match_user_connections_to_kb(user_edges, regional_sea, ecosystem_type)`
- Input: user's edges data.frame (from create_edges_df), regional_sea, ecosystem_type
- Gets KB connections via `get_context_connections()`
- Fuzzy-matches user edge from/to labels against KB connection from/to names (case-insensitive, substring match)
- Returns data.frame: `user_from`, `user_to`, `kb_matched` (boolean), `rationale`, `references` (semicolon-separated), `temporal_lag`, `reversibility`, `kb_confidence`

### `get_governance_context(regional_sea, countries = NULL)`
- Input: `regional_sea` as short key (e.g., `"baltic"`), optional `countries` vector
- Implementation path through existing API (do NOT re-read JSON directly):
  1. Call `get_countries_for_sea(regional_sea)` → returns list of country records
  2. Extract `regional_conventions` from each country record → deduplicate → `frameworks` vector
  3. If `countries` provided, filter country records and extract country-specific policies
- Returns list: `frameworks` (character vector of relevant conventions/policies), `country_policies` (named list per country if countries provided), `available` (boolean)
- Returns `list(frameworks = character(), available = FALSE)` if governance DB unavailable or `get_countries_for_sea` returns empty

### `format_kb_section_for_report(kb_context, matched_connections, governance, i18n = NULL)`
- Assembles the Regional Context section as R Markdown text
- Includes: site description, connection references table, confidence summary, governance list
- All headings and labels via i18n keys when `i18n` is provided
- **Transitional i18n pattern:** The existing report generation system (`report_generation.R`) does not use i18n — all report content is currently English-only. The `i18n = NULL` fallback matches this existing limitation. Threading i18n through the entire report pipeline is a separate, larger effort documented as technical debt. When `i18n` IS provided (e.g., from the module server), use it; when not (e.g., from batch/CLI report generation), fall back to English.
- Returns character string (Markdown)

## 5. Report Module Changes

### Section Selector

In `modules/prepare_report_module.R`, add "Regional Context" as a toggleable section in the report configuration:
- `checkboxInput` "Include Regional Context" — default TRUE if regional_sea is set, FALSE if not
- Positioned between "Summary" and "ISA Details" in the section list

### Report Generation

In `functions/report_generation.R`, all 4 report types (executive, technical, presentation, full) should include the regional context section when enabled:
- `generate_executive_content()` — add brief context paragraph
- `generate_technical_content()` — add full KB references table
- `generate_presentation_content()` — add context slide
- `generate_full_content()` — add complete section

### Recommendation Enhancement

In `generate_strategic_recommendations()`:
- **No signature change** — read `data$data$metadata$regional_sea`, `data$data$metadata$ecosystem_type` internally from the existing `data` parameter (consistent with Section 3)
- When metadata fields are non-NULL, call `get_kb_context_for_report()` and `get_governance_context()`
- Append regional priorities and governance frameworks to existing recommendations

## 6. Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `functions/kb_report_helpers.R` | Create | `get_kb_context_for_report()`, `match_user_connections_to_kb()`, `get_governance_context()`, `format_kb_section_for_report()` |
| `functions/report_generation.R` | Modify | Add regional context section to all report types, enhance `generate_strategic_recommendations()` |
| `modules/prepare_report_module.R` | Modify | Add "Regional Context" checkbox, pass metadata to report generator |
| `functions/data_structure.R` | Modify | Add `regional_sea`, `ecosystem_type` to default metadata |
| `modules/ai_isa_assistant_module.R` | Modify | Persist context to project metadata on save |
| `app.R` or `server/dashboard.R` | Modify | Add regional_sea/ecosystem_type dropdowns to dashboard |
| `global.R` | Modify | Source `kb_report_helpers.R` |
| `translations/modules/report_context.json` | Create | i18n keys for report context section (9 languages) |
| `tests/testthat/test-kb-report-helpers.R` | Create | Unit tests |

## 7. i18n Keys (all 9 languages)

```
modules.report_context.section_title          — "Regional Context"
modules.report_context.site_description       — "Site Description"
modules.report_context.scientific_references  — "Scientific References"
modules.report_context.confidence_assessment  — "Confidence Assessment"
modules.report_context.governance_frameworks  — "Governance Frameworks"
modules.report_context.regional_priorities    — "Regional Management Priorities"
modules.report_context.kb_supported           — "connections have scientific literature support"
modules.report_context.user_defined           — "User-defined (no KB reference)"
modules.report_context.connection             — "Connection"
modules.report_context.rationale              — "Rationale"
modules.report_context.references             — "References"
modules.report_context.temporal_lag           — "Temporal Lag"
modules.report_context.reversibility          — "Reversibility"
modules.report_context.confidence             — "Confidence"
modules.report_context.relevant_policies      — "Relevant Policies"
modules.report_context.regional_sea_label     — "Regional Sea"
modules.report_context.ecosystem_type_label   — "Ecosystem Type"
modules.report_context.not_set               — "Not set"
modules.report_context.include_context        — "Include Regional Context"
modules.report_context.kb_match_summary       — "%d of %d connections have KB support"
modules.report_context.no_context_available   — "No regional context available. Set Regional Sea and Ecosystem Type in project settings."
modules.report_context.suggested_responses    — "KB-Suggested Responses"
```

## 8. Testing

- `test-kb-report-helpers.R`:
  - `get_kb_context_for_report()` returns valid structure for known context (e.g., "Baltic Sea", "Lagoon")
  - `get_kb_context_for_report()` returns `available = FALSE` for unknown context
  - `match_user_connections_to_kb()` matches known connection (e.g., "Overfishing" → "Stock Depletion")
  - `match_user_connections_to_kb()` returns `kb_matched = FALSE` for user-only connections
  - `get_governance_context()` returns frameworks for known regional sea
  - `get_governance_context()` returns empty for unknown sea
  - `format_kb_section_for_report()` returns non-empty Markdown string
  - `format_kb_section_for_report()` handles NULL/empty inputs gracefully
  - Regional context persisted in project metadata (check data_structure defaults)
  - Translation keys exist for all 9 languages

## 9. Graceful Degradation

- If `regional_sea` / `ecosystem_type` not set: regional context section omitted from report, recommendations remain generic
- If KB has no matching context: section shows "No regional context available" message
- If governance DB unavailable: governance subsection omitted
- If no user connections match KB: references table shows "No KB matches found"
- Existing reports without metadata continue to work unchanged

## 10. Out of Scope

- Editing KB content from within the app
- Multi-context reports (one regional sea/habitat per project)
- Automatic regional sea detection from user's location
- KB version management / update mechanism
