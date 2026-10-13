# WS-6b code map (explored 2026-10-13 at 80c61f6)

Companion to `2026-10-13-wp5-ws6b-handoff.md`. Paths are relative to `MarineSABRES_SES_Shiny/`. Line numbers are as of `80c61f6`.

## 1. Module pattern to copy: `modules/valuation_calculator_module.R` (WS-5)

**UI** `valuation_calculator_ui(id, i18n)` (L7):
- The first line is `tryCatch(shiny.i18n::usei18n(i18n$translator %||% i18n), error = function(e) NULL)`, then `ns <- NS(id)`.
- Header: `create_module_header(ns, "<mod>.title", "<mod>.subtitle", "help_<x>", i18n)`.
- Layout: inputs in `column(4, wellPanel(...))`, results in `column(8, uiOutput(...))`.

**Server** `valuation_calculator_server(id, project_data_reactive, i18n, event_bus = NULL)` (L49), using `moduleServer`:
- Ends with `create_help_observer(input, "help_<x>", "<mod>.help_title", tagList(...), i18n)`.
- Download pattern: `tryCatch(build_x(...), error = function(e) { debug_log(...); showNotification(paste0(i18n$t("common.messages.excel_export_failed"), " (", e$message, ")"), type = "error", duration = NULL); stop(e) })`.

**Wiring:**
- `app.R`:
  - L99: the module path goes in the explicit module source list.
  - L509: `bs4TabItem(tabName = "response_valuation", valuation_calculator_ui("valuation_calc", i18n))`.
  - L1053: `valuation_calculator_server("valuation_calc", project_data, session_i18n)`.
- `global.R` L707-714 sources the pure `functions/*.R` files (`impact_reference.R` at 713, `impact_assessment_model.R` at 714).
- Sidebar: `functions/ui_sidebar.R:403`, `bs4SidebarMenuSubItem(safe_t("ui.sidebar.valuation_calculator", i18n_obj = i18n), tabName = "response_valuation")`. The label key lives in `translations/ui/sidebar.json`.

**i18n:**
- File format `translations/modules/<mod>.json` = `{"languages":[en,es,fr,de,lt,pt,it,no,el], "translation":{"modules.<mod>.<key>":{"en":..,...}}}`. Files are auto-discovered (`functions/translation_loader.R:19-28`). Never edit `_merged_translations.json`.
- Dynamic keys need `# i18n-ref: <full.key>` sentinel lines.

**Tests** (`tests/testthat/test-valuation-calculator-module.R`):
- `source_for_test(c(...))`, then re-bind `x_server <- get("x_server", envir = .GlobalEnv)` to beat the `helper-stubs.R` shadowing.
- UI: assert namespaced ids and keys in `as.character(ui)`.
- Signature: `names(formals(server)) == c("id","project_data_reactive","i18n","event_bus")`.
- `testServer(server, args = list(project_data_reactive = shiny::reactiveVal(...), i18n = make_test_i18n(), event_bus = NULL), {...})`. `make_test_i18n()` returns keys verbatim.
- Wiring: a source-text regex over `app.R` and `ui_sidebar.R`.
- i18n: every `modules.<mod>.*` key in the source exists in all 9 languages and is non-empty, and `%1$` placeholders are checked per language.

## 2. Writing project data

- `app.R:603` declares `project_data <- reactiveVal(init_session_data())`. A module does read-modify-write: `project_data_reactive(set_impact_assessment(project_data_reactive(), ia))`. Both functions are pure.
- An example of a plain write is `scenario_builder_module.R:1167-1175`. Autosave observes `project_data_reactive()` (`auto_save_module.R:961`), so no event is needed.
- **Do NOT** emit `emit_isa_change` or `emit_cld_update` for impact writes. They trigger CLD regeneration, and `cld_update` triggers analysis invalidation (see §3).
- Event bus methods (`server/event_bus_setup.R`, created at `app.R:660`):
  - `emit_`/`on_` pairs for: `isa_change`, `cld_update`, `analysis_request`, `template_loaded`, `project_saved`, `project_loaded`, `navigation_request(target_tab)`, `language_changed`;
  - safe helpers: `safe_emit_isa_change`, `safe_emit_cld_update`, `setup_navigation_handler`.

## 3. Wholesale `data$analysis` wipes (WS-6b Task 1)

The three sites:
- `functions/reactive_pipeline.R:239`, Observer 2 (L199-255). It fires on `event_bus$on_cld_update()` from non-analysis sources, when `analysis$loops` or `analysis$metrics` is non-empty: `data$data$analysis <- list(loops = NULL, metrics = NULL, cleared_at = Sys.time(), reason = "Data changed")`, then `project_data(data)` and `emit_analysis_request("invalidation", ...)`. This is the most dangerous of the three, because it fires on any ISA-driven CLD regeneration once loops or metrics exist.
- `modules/import_data_module.R:573`, in `perform_import` (L537, Excel import): `project_data$data$analysis <- list(loops = NULL, metrics = NULL)`.
- `modules/ses_models_module.R:777`, in `perform_ses_model_import()` (L744): the same one-liner.

What they destroy: all three silently remove `analysis$scenarios` (WS-0 canonical storage; the bug is already on main) and `analysis$impact_assessment`.

The fix: keep the other keys, e.g. set `data$data$analysis$loops <- NULL; ...$metrics <- NULL` (plus `cleared_at` and `reason` where used) on a list guarded by `is.list()`. Decide whether an Excel or SES-model import should keep the scenarios and assessment. They reference elements of the old network, but they are user work, so keeping them is the safer default.

Tests: no test covers these sites today (no hits for `cleared_at`, "Data changed" or `perform_ses_model_import` in tests/). `test-reactive-pipeline.R` checks only the bus API. Add regression tests showing the scenarios and the impact assessment survive.

Other `$analysis <-` sites are guarded or non-wholesale:
- `analysis_loops.R:489,558`;
- `data_structure.R:1193` and `966-971`;
- `impact_assessment_model.R:400`;
- `scenario_builder_module.R:1170`.

## 4. DA detection (no shared helper yet)

- Stored in `project$data$metadata$da_site`, set by the PIMS module `modules/pims_module.R:25,115`. The values are in `DA_SITES` (`constants.R:528`): "Tuscan Archipelago", "Arctic Northeast Atlantic", "Macaronesia". The field can also be free text or a list.
- `WP5_DA_CONTEXTS` (`constants.R:743`) is `macaronesia`, `tuscan`, `arctic`.
- An inline mapping exists in `modules/response_module.R:987-1000`: `pd$data$metadata$da_site %||% pd$metadata$da_site`, lowercased, then `grepl("macaron")` gives macaronesia, `grepl("tuscan|toscan")` gives tuscan, `grepl("arctic|nordic|northeast atlantic")` gives arctic, and anything else gives NULL.
- Recommendation: factor this into a pure `wp5_da_for_project(project)` that returns "" or a `WP5_DA_CONTEXTS` value. Reuse it in `response_module.R`, and test it.

## 5. ISA elements

- `project$data$isa_data` holds `drivers`, `activities`, `pressures`, `marine_processes`, `ecosystem_services`, `goods_benefits` and `responses`.
- ID prefixes come from `ELEMENT_ID_PREFIX` (`constants.R:140`): D, A, P, MPF, ES, GB, R. Its names are `states` for marine_processes and `impacts` for ecosystem_services.
- **Column case:** the ISA module uses canonical `ID`, `Name`, `Type`, ... (`ISA_CANONICAL_COLUMNS`, `data_structure.R:1735`; `canonicalize_element_columns(df)` at L1753). JSON loads lowercase them. The accessors in `functions/data_accessors.R` expect lowercase:
  - `get_isa_elements(pd, type)` L43;
  - `get_all_isa_elements(pd)` L65, which adds `element_type`;
  - `get_element_by_id(pd, id)` L106.

  Handle both cases.
- Adding a P element:
  - `add_isa_element(project_data, element_type, element, event_bus)` (`data_accessors.R:406`) assumes lowercase and allocates no ID.
  - `add_element_safe` (`data_structure.R:1510`) is a poor fit.
  - Stable IDs: `generate_stable_element_id(prefix, store)`, `new_stable_id_store()` and `seed_stable_id_counter("P", existing_ids, store)` (`data_structure.R:13-80`). Calling without a session store warns inside Shiny.
  - Pressures columns (ISA module `isa_data_entry_module.R:147-156`): `ID, Name, Type, Description, LinkedMPF, Intensity, Spatial, Temporal`.
- **Stale-overwrite hazard:** the ISA module keeps its own `isa_data` reactiveValues, and `sync_to_project_data()` (L~273-305) overwrites `pd$data$isa_data$pressures` from that local copy. A P element written straight to project_data can be lost on the next ISA save. The local copy is re-read only when `data_initialized` resets on load (L246, 377, 635, 2028).
  - The displaced-pressure feature needs a safe path: e.g. navigate the user to ISA entry with a prefilled pressure, or have the ISA module re-read on an event. Decide this in the plan.
  - Alternative: descope the P-element creation and store only a reference to an existing P element picked from a list.

## 6. Plots and tables

- Loaded in global.R: ggplot2, plotly and DT. There is no `geom_tile` anywhere.
- Best heat-map precedent: `modules/analysis_simulation.R:383` (`plotlyOutput(ns("ss_heatmap"), height = PLOT_HEIGHT_LG)`), rendered at L547-566 with `plotly::plot_ly(z=, x=, y=, type = "heatmap", colorscale = list(...), hoverinfo = "text", text = ...) %>% plotly::layout(title = i18n$t(...))`.
- Plot heights: `PLOT_HEIGHT_*` (`constants.R:393-401`).
- Glyphs and hatching: plotly heatmaps have no hatching. Either use annotations (arrow glyph + "?" or pattern) or render an HTML/CSS table grid (CSS `repeating-linear-gradient` for hatching), which is simpler to test.
- DT pattern (`response_module.R:599-604`): `renderDT({ datatable(df, selection = 'multiple', options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) })`, with selected rows read from `input$<id>_rows_selected`.

## 7. UI helpers

`functions/ui_helpers.R`:
- `create_module_header(ns, title_key, subtitle_key, help_id, i18n)` L50
- `create_reactive_header` L86
- `create_help_observer(input, input_id, title_key, content, i18n)` L110
- `setup_cld_gate` L25

`functions/ui_components.R`:
- `ses_analysis_box` L39
- `ses_empty_state(message, subtitle, icon_name, status, i18n)` L90 (use it for the Tuscan empty state)
- `ses_action_buttons` L142
- `ses_status_badge` L197
- `ses_info_callout` L255
- `ses_well_section` L302
- `ses_download_buttons` L352
- `provenance_badge(provenance, i18n)` L506: NULL for `wp5_source`; otherwise a warning badge with key `modules.wp5_mechanisms.provenance.<p>`.

`functions/wp5_vocabulary.R`: `wp5_vocab_label(vocab, code, i18n)` gives the rubric labels (criteria, direction, magnitude, timing, confidence, evidence, uncertainty_driver, indicator_role, subdimension).

## 8. i18n tooling

- `scripts/_i18n_audit.py`:
  - Run: `micromamba run -n shiny python scripts/_i18n_audit.py`; it must report missing=0, hardcoded=0.
  - It scans `modules/`, `server/`, `functions/`, `app.R` and `global.R` for `i18n$t("k")`, `safe_t("k")`, `data-i18n="k"`, `context_key = "k"` and `# i18n-ref: k`.
  - Hardcoded patterns it flags: `showNotification("..."`, `actionButton(id, "Cap..."`, `tags$span("Cap")`, `h1-6("Cap")`, `p("Cap..."` (5+ chars), and `title=`/`label=`/`placeholder="Cap..."`.
  - `--allow-english-fallback=<prefix>` exists.
- Tests:
  - `test-i18n-enforcement.R`: usei18n present, showNotification literals, key existence, JSON shape, no empty values.
  - `test-i18n-english-fallback.R`: fails on a non-English value identical to its English for sentences of 30+ chars with a space.
  - `test-i18n-duplicate-keys.R`, `test-i18n-placeholders.R`, `test-i18n-key-arguments.R`.

## 9. Test fixtures available

- `test-impact-assessment-storage.R`: `build_ia()` and `project_with_ia()`.
- `test-impact-assessment-model.R`.
- For testServer: `shiny::reactiveVal(set_impact_assessment(create_empty_project("x"), ia))`.
- Never end a behaviour test in `expect_true(TRUE)`.

## 10. Menu

"Response & Validation" in `ui_sidebar.R:398-408` (intermediate and expert only; config `show_response_validation`):
- response_measures
- response_valuation
- response_scenarios
- response_validation

The natural slot is a new sub-item `ui.sidebar.impact_assessment`, `tabName = "response_impact"`, after `response_scenarios`, with a `bs4TabItem` near `app.R:509-511`.

"Analysis Tools" (`ui_sidebar.R:312-345`) has simplified and full variants that both need editing, plus `add_submenu_tooltip`. Beginners don't see the Response menu. `entry_point_module.R:952` links to `response_scenarios`.
