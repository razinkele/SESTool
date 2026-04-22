# Close Deferred Review Items Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the 3 actionable deferred items from the 6-iteration review loop on main: the Greek translation anomaly, the remaining hardcoded English in `import_data_module`, and the 0%-to-baseline jump in module unit-test coverage for 3 untested modules.

**Architecture:** Three independent workstreams that can land as separate commits:
1. One-string translation fix (JSON-only).
2. Seven i18n wrapping edits with 7 new translation keys × 9 languages = 63 new translation strings.
3. Three new testthat files that establish the reusable Shiny-module test pattern for follow-on coverage work.

**Tech Stack:** R 4.4.1, testthat 3+, shiny.i18n (JSON-driven session translator), jsonlite. Python used only for JSON manipulation (micromamba `shiny` env per project CLAUDE.md).

**Not in scope (investigated, no action needed):** `server/modals.R:78-98` "Changing Language" modal. Iter-1 flagged this as a bypass-i18n issue, but the file already has an 5-line explanatory comment (lines 78-82) stating the hardcoded per-language `loading_messages` list is **intentional** — the overlay runs during a language switch and must display the TARGET language before i18n re-initializes. Using `i18n$t()` would show the OLD language. Verified during planning. Leaving as-is.

---

## File Structure

**Files created:**
- `tests/testthat/test-feedback-admin-module.R` — unit tests for `feedback_admin_server`
- `tests/testthat/test-entry-point-module.R` — unit tests for `entry_point_server`
- `tests/testthat/test-local-storage-module.R` — unit tests for `local_storage_server`

**Files modified:**
- `translations/modules/ses_creation.json` — fix Greek value for `modules.ses.creation.new_to_ses_modeling`
- `translations/modules/import_data.json` — add 6 new keys (× 9 languages each)
- `modules/import_data_module.R:78-79, 83-88` — wrap 6 hardcoded strings in `i18n$t()`

**Pattern reference:** New test files follow the structure in existing `tests/testthat/test-create-ses-module.R`: mock `i18n <- list(t = function(key) key)`, use `skip_if_not(exists("name", mode = "function"))` to guard against load-order issues, test UI return type + namespaced IDs + server signature via `formals()`.

---

## Task 1: Fix Greek Translation Anomaly

**Problem:** `translations/modules/ses_creation.json` key `modules.ses.creation.new_to_ses_modeling` has Greek value `"Νέο to SES modeling?"` — the suffix is English. All 8 other languages are fully translated.

**Files:**
- Test: `tests/testthat/test-i18n-enforcement.R` (append test)
- Modify: `translations/modules/ses_creation.json`

- [ ] **Step 1: Write the failing test**

Append this block to the end of `tests/testthat/test-i18n-enforcement.R`:

```r
test_that("Greek translation for new_to_ses_modeling is pure Greek", {
  # Absolute path pattern matches tests/testthat/test-create-ses-module.R:133-135
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fp <- file.path(root, "translations", "modules", "ses_creation.json")
  skip_if_not(file.exists(fp), "ses_creation.json not found")
  d <- jsonlite::fromJSON(fp, simplifyVector = FALSE)
  el_value <- d$translation$`modules.ses.creation.new_to_ses_modeling`$el
  expect_false(
    grepl("to SES modeling", el_value, fixed = TRUE),
    info = paste0("Greek value still contains English substring: '", el_value, "'")
  )
  expect_false(
    grepl("modeling", el_value, fixed = TRUE),
    info = "Greek value should not contain English word 'modeling'"
  )
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
```
Expected: **FAIL** on the new test with message `"Greek value still contains English substring: 'Νέο to SES modeling?'"`.

- [ ] **Step 3: Fix the Greek value**

Run this Python one-liner (the codebase uses jsonlite from R but Python handles non-BMP UTF-8 more reliably in this project per CLAUDE.md):

```bash
python -c "
import sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
fp = r'translations/modules/ses_creation.json'
with open(fp, encoding='utf-8') as f: d = json.load(f)
d['translation']['modules.ses.creation.new_to_ses_modeling']['el'] = 'Νέοι στη μοντελοποίηση SES;'
with open(fp, 'w', encoding='utf-8') as f:
    json.dump(d, f, ensure_ascii=False, indent=2); f.write('\n')
print('OK')
"
```

Note: The Greek question mark is `;` (U+037E, visually identical to Latin `;`). The phrase translates as "New to SES modeling?" where "Νέοι" = "New [ones]" (plural, matching inclusive plural pattern used elsewhere in the file).

- [ ] **Step 4: Run test to verify it passes**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
```
Expected: **PASS** (test now passes).

- [ ] **Step 5: Commit**

```bash
git add translations/modules/ses_creation.json tests/testthat/test-i18n-enforcement.R
git commit -m "$(cat <<'EOF'
fix(i18n): translate remaining English in Greek "new_to_ses_modeling"

Value was "Νέο to SES modeling?" - mixed Greek + English. Replaces with
"Νέοι στη μοντελοποίηση SES;" (fully Greek, using Greek question mark
U+037E).

Adds a regression test in test-i18n-enforcement.R that fails if any
English substring ("to SES modeling", "modeling") slips into the Greek
value again.
EOF
)"
```

---

## Task 2: Complete import_data_module i18n Coverage

**Problem:** `modules/import_data_module.R:78-79, 83-88` has 7 `tags$li(code("X"), " - English description")` pairs. The `code("...")` values are Excel column names (schema labels — must stay literal because `read_excel(sheet = "...")` at lines 155-156, 266-267 hard-codes them). The English suffix descriptions need i18n wrapping.

The "type" row (line 79) also contains an English list of DAPSIWRM element type names ("Driver, Activity, Pressure, ..."). Those names already have translations in `translations/common/labels.json` and `translations/modules/entry_point.json`, but pasting them dynamically at render time is more fragile than committing one translated string per language. This plan takes the latter approach.

**Files:**
- Test: `tests/testthat/test-i18n-enforcement.R` (append test)
- Modify: `translations/modules/import_data.json` (add 7 keys)
- Modify: `modules/import_data_module.R:78-79, 83-88`

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-i18n-enforcement.R`:

```r
test_that("import_data_module has no hardcoded English column descriptions", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fp <- file.path(root, "modules", "import_data_module.R")
  skip_if_not(file.exists(fp), "import_data_module.R not found")
  src <- paste(readLines(fp), collapse = "\n")

  # These specific English phrases were flagged by the iter-1 review and
  # should now be replaced with i18n$t() calls.
  forbidden <- c(
    " - Name of the element (required)",
    " - Element type: Driver, Activity",
    " - Source element label (required)",
    " - Target element label (required)",
    " - Connection polarity: + or - (required)",
    " - Optional: Weak/Medium/Strong",
    " - Optional: 1-5 scale"
  )
  for (phrase in forbidden) {
    expect_false(
      grepl(phrase, src, fixed = TRUE),
      info = paste0("Hardcoded English phrase still present: '", phrase, "'")
    )
  }
})

test_that("import_data.json has the 7 new column-description keys", {
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fp <- file.path(root, "translations", "modules", "import_data.json")
  skip_if_not(file.exists(fp), "import_data.json not found")
  d <- jsonlite::fromJSON(fp, simplifyVector = FALSE)
  required_keys <- c(
    "modules.import.data.elements_label_desc",
    "modules.import.data.elements_type_desc",
    "modules.import.data.connections_from_desc",
    "modules.import.data.connections_to_desc",
    "modules.import.data.connections_label_desc",
    "modules.import.data.connections_strength_desc",
    "modules.import.data.connections_confidence_desc"
  )
  expected_langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  for (k in required_keys) {
    expect_true(k %in% names(d$translation), info = paste0("Missing key: ", k))
    if (k %in% names(d$translation)) {
      langs_present <- names(d$translation[[k]])
      expect_true(
        all(expected_langs %in% langs_present),
        info = paste0("Key '", k, "' missing languages: ",
                      paste(setdiff(expected_langs, langs_present), collapse = ","))
      )
    }
  }
})
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
```
Expected: **FAIL** — forbidden phrases still in source; new keys missing from catalog.

- [ ] **Step 3: Add 7 new translation keys to `translations/modules/import_data.json`**

Run:
```bash
python << 'PY'
import sys, io, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
fp = r'translations/modules/import_data.json'
with open(fp, encoding='utf-8') as f: d = json.load(f)
tr = d['translation']

new_keys = {
    'modules.import.data.elements_label_desc': {
        'en': ' - Name of the element (required)',
        'es': ' - Nombre del elemento (obligatorio)',
        'fr': " - Nom de l'élément (obligatoire)",
        'de': ' - Name des Elements (Pflichtfeld)',
        'lt': ' - Elemento pavadinimas (privalomas)',
        'pt': ' - Nome do elemento (obrigatório)',
        'it': " - Nome dell'elemento (obbligatorio)",
        'no': ' - Navn på elementet (påkrevd)',
        'el': ' - Όνομα του στοιχείου (υποχρεωτικό)'
    },
    'modules.import.data.elements_type_desc': {
        # Element-type names use CANONICAL translations from translations/common/labels.json
        # (Drivers/Activities/Pressures/Ecosystem Services) to avoid terminology drift.
        # Singular forms derived from the plural canonicals there.
        'en': ' - Element type: Driver, Activity, Pressure, Marine Process and Function, Ecosystem Service, Good and Benefit, Response, or Measure (required)',
        'es': ' - Tipo de elemento: Impulsor, Actividad, Presión, Proceso y Función Marina, Servicio Ecosistémico, Bien y Beneficio, Respuesta o Medida (obligatorio)',
        'fr': " - Type d'élément : Facteur, Activité, Pression, Processus et Fonction Marine, Service Écosystémique, Bien et Bénéfice, Réponse ou Mesure (obligatoire)",
        'de': ' - Elementtyp: Treiber, Aktivität, Belastung, Mariner Prozess und Funktion, Ökosystemleistung, Gut und Nutzen, Reaktion oder Maßnahme (Pflichtfeld)',
        'lt': ' - Elemento tipas: Varomoji jėga, Veikla, Spaudimas, Jūros procesas ir funkcija, Ekosistemos paslauga, Gėrybė ir nauda, Atsakas arba Priemonė (privalomas)',
        'pt': ' - Tipo de elemento: Fator, Atividade, Pressão, Processo e Função Marinha, Serviço Ecossistêmico, Bem e Benefício, Resposta ou Medida (obrigatório)',
        'it': " - Tipo di elemento: Fattore, Attività, Pressione, Processo e Funzione Marina, Servizio Ecosistemico, Bene e Beneficio, Risposta o Misura (obbligatorio)",
        'no': ' - Elementtype: Drivkraft, Aktivitet, Belastning, Marin prosess og funksjon, Økosystemtjeneste, Gode og nytte, Respons eller Tiltak (påkrevd)',
        'el': ' - Τύπος στοιχείου: Κινητήρια δύναμη, Δραστηριότητα, Πίεση, Θαλάσσια διεργασία και λειτουργία, Υπηρεσία οικοσυστήματος, Αγαθό και όφελος, Απόκριση ή Μέτρο (υποχρεωτικό)'
    },
    'modules.import.data.connections_from_desc': {
        'en': ' - Source element label (required)',
        'es': ' - Etiqueta del elemento de origen (obligatorio)',
        'fr': " - Étiquette de l'élément source (obligatoire)",
        'de': ' - Bezeichnung des Quellelements (Pflichtfeld)',
        'lt': ' - Šaltinio elemento žymė (privaloma)',
        'pt': ' - Rótulo do elemento de origem (obrigatório)',
        'it': " - Etichetta dell'elemento di origine (obbligatorio)",
        'no': ' - Kildeelementets etikett (påkrevd)',
        'el': ' - Ετικέτα στοιχείου προέλευσης (υποχρεωτικό)'
    },
    'modules.import.data.connections_to_desc': {
        'en': ' - Target element label (required)',
        'es': ' - Etiqueta del elemento de destino (obligatorio)',
        'fr': " - Étiquette de l'élément cible (obligatoire)",
        'de': ' - Bezeichnung des Zielelements (Pflichtfeld)',
        'lt': ' - Tikslo elemento žymė (privaloma)',
        'pt': ' - Rótulo do elemento de destino (obrigatório)',
        'it': " - Etichetta dell'elemento di destinazione (obbligatorio)",
        'no': ' - Målelementets etikett (påkrevd)',
        'el': ' - Ετικέτα στοιχείου προορισμού (υποχρεωτικό)'
    },
    'modules.import.data.connections_label_desc': {
        'en': ' - Connection polarity: + or - (required)',
        'es': ' - Polaridad de la conexión: + o - (obligatorio)',
        'fr': ' - Polarité de la connexion : + ou - (obligatoire)',
        'de': ' - Polarität der Verbindung: + oder - (Pflichtfeld)',
        'lt': ' - Ryšio poliškumas: + arba - (privalomas)',
        'pt': ' - Polaridade da conexão: + ou - (obrigatório)',
        'it': ' - Polarità della connessione: + o - (obbligatorio)',
        'no': ' - Forbindelsens polaritet: + eller - (påkrevd)',
        'el': ' - Πολικότητα σύνδεσης: + ή - (υποχρεωτικό)'
    },
    'modules.import.data.connections_strength_desc': {
        'en': ' - Optional: Weak/Medium/Strong',
        'es': ' - Opcional: Débil/Medio/Fuerte',
        'fr': ' - Facultatif : Faible/Moyen/Fort',
        'de': ' - Optional: Schwach/Mittel/Stark',
        'lt': ' - Neprivaloma: Silpnas/Vidutinis/Stiprus',
        'pt': ' - Opcional: Fraco/Médio/Forte',
        'it': ' - Opzionale: Debole/Medio/Forte',
        'no': ' - Valgfritt: Svak/Middels/Sterk',
        'el': ' - Προαιρετικό: Αδύναμο/Μέτριο/Ισχυρό'
    },
    'modules.import.data.connections_confidence_desc': {
        'en': ' - Optional: 1-5 scale',
        'es': ' - Opcional: escala 1-5',
        'fr': ' - Facultatif : échelle 1-5',
        'de': ' - Optional: Skala 1-5',
        'lt': ' - Neprivaloma: skalė 1-5',
        'pt': ' - Opcional: escala 1-5',
        'it': ' - Opzionale: scala 1-5',
        'no': ' - Valgfritt: skala 1-5',
        'el': ' - Προαιρετικό: κλίμακα 1-5'
    },
}
for k, v in new_keys.items():
    tr[k] = v
with open(fp, 'w', encoding='utf-8') as f:
    json.dump(d, f, ensure_ascii=False, indent=2); f.write('\n')
print(f'Added {len(new_keys)} keys; total {len(tr)}')
PY
```

Expected: `Added 7 keys; total <N>`.

- [ ] **Step 4: Replace the 7 hardcoded strings in `modules/import_data_module.R`**

Current lines 78-79 and 83-88 (verify via `head -n 89 modules/import_data_module.R | tail -n 15`):
```r
                    tags$li(code("Label"), " - Name of the element (required)"),
                    tags$li(code("type"), " - Element type: Driver, Activity, Pressure, Marine Process and Function, Ecosystem Service, Good and Benefit, Response, or Measure (required)")
                  )),
          tags$li(strong(i18n$t("common.misc.connections_sheet_columns")),
                  tags$ul(
                    tags$li(code("From"), " - Source element label (required)"),
                    tags$li(code("To"), " - Target element label (required)"),
                    tags$li(code("Label"), " - Connection polarity: + or - (required)"),
                    tags$li(code("Strength"), " - Optional: Weak/Medium/Strong"),
                    tags$li(code("Confidence"), " - Optional: 1-5 scale")
                  ))
```

Replace with:
```r
                    tags$li(code("Label"), i18n$t("modules.import.data.elements_label_desc")),
                    tags$li(code("type"), i18n$t("modules.import.data.elements_type_desc"))
                  )),
          tags$li(strong(i18n$t("common.misc.connections_sheet_columns")),
                  tags$ul(
                    tags$li(code("From"), i18n$t("modules.import.data.connections_from_desc")),
                    tags$li(code("To"), i18n$t("modules.import.data.connections_to_desc")),
                    tags$li(code("Label"), i18n$t("modules.import.data.connections_label_desc")),
                    tags$li(code("Strength"), i18n$t("modules.import.data.connections_strength_desc")),
                    tags$li(code("Confidence"), i18n$t("modules.import.data.connections_confidence_desc"))
                  ))
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
```
Expected: **PASS** — no forbidden phrases, all 7 keys present with 9 languages each.

- [ ] **Step 6: Commit**

```bash
git add translations/modules/import_data.json modules/import_data_module.R tests/testthat/test-i18n-enforcement.R
git commit -m "$(cat <<'EOF'
chore(i18n): complete import_data module column-description coverage

Wraps 7 hardcoded English suffixes in the Excel-import help panel in
i18n$t() calls. Keeps the code("Label"), code("type"), code("From"),
etc. contents literal - those are Excel column/sheet names the import
pipeline (read_excel(sheet = "...") at lines 155-156, 266-267) requires
users to name literally in their workbooks.

Adds 7 new keys x 9 languages = 63 translation strings, including the
full DAPSIWRM element-type enumeration for the "type" column description.
Adds regression tests that fail if the English phrases reappear or if
any of the 7 keys drops a language.
EOF
)"
```

---

## Task 3: Establish Module Test Pattern — `feedback_admin_module`

**Problem:** 13 of 21 `*_module.R` files have no matching test file. This task creates the first of 3 pattern-establishing module test files. Choosing `feedback_admin_module.R` first because it's small (148 lines), has no `project_data_reactive` dependency, and was just refactored (commit `ff3a282` added `event_bus = NULL`), so a test locks in that contract.

**Files:**
- Create: `tests/testthat/test-feedback-admin-module.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-feedback-admin-module.R`:

```r
# test-feedback-admin-module.R
# Unit tests for modules/feedback_admin_module.R

library(testthat)
library(shiny)

# Mock i18n
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("feedback_admin_ui function exists", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  expect_true(is.function(feedback_admin_ui))
})

test_that("feedback_admin_ui returns valid shiny tags", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  params <- names(formals(feedback_admin_ui))
  ui <- if ("i18n" %in% params) feedback_admin_ui("test_fb", i18n) else feedback_admin_ui("test_fb")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "feedback_admin_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("feedback_admin_ui uses namespaced IDs", {
  skip_if_not(exists("feedback_admin_ui", mode = "function"),
              "feedback_admin_ui not available")
  params <- names(formals(feedback_admin_ui))
  ui <- if ("i18n" %in% params) feedback_admin_ui("test_fb", i18n) else feedback_admin_ui("test_fb")
  ui_html <- as.character(ui)
  expect_true(grepl("test_fb", ui_html), info = "UI must namespace IDs with the module id")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("feedback_admin_server function exists", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  expect_true(is.function(feedback_admin_server))
})

test_that("feedback_admin_server signature includes id, i18n, event_bus", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  params <- names(formals(feedback_admin_server))
  # These three params are required by the module-signature convention
  # (see docs/MODULE_SIGNATURE_STANDARD.md). Specifically event_bus = NULL
  # was added in commit ff3a282 to align with the analysis-module pattern.
  expect_true("id" %in% params, info = "Missing 'id' parameter")
  expect_true("i18n" %in% params, info = "Missing 'i18n' parameter")
  expect_true("event_bus" %in% params,
              info = "Missing 'event_bus' parameter (convention requires trailing event_bus = NULL)")
})

test_that("feedback_admin_server event_bus defaults to NULL", {
  skip_if_not(exists("feedback_admin_server", mode = "function"),
              "feedback_admin_server not available")
  default <- formals(feedback_admin_server)$event_bus
  # In R, a NULL default is represented as symbol 'NULL' when retrieved via formals()
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})
```

- [ ] **Step 2: Run test to verify it passes**

Note: because the module already exists and has the correct signature (from commit `ff3a282`), this test should PASS on first run. The value is **regression prevention**: if someone removes `event_bus` from the signature, the test catches it.

Run:
```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-feedback-admin-module.R')"
```
Expected: **PASS** — 6 tests pass.

- [ ] **Step 3: Verify test actually protects against regression**

Temporarily break the signature to confirm the test catches it. Run:
```bash
# Temporarily remove event_bus from the signature
sed -i.bak 's/feedback_admin_server <- function(id, i18n, event_bus = NULL)/feedback_admin_server <- function(id, i18n)/' modules/feedback_admin_module.R

# Verify the mutation actually applied (some sed builds silently no-op on Windows)
grep -n "feedback_admin_server <- function" modules/feedback_admin_module.R
# Expected: one line that does NOT contain "event_bus"

# Rerun tests
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-feedback-admin-module.R')"
```
Expected: **FAIL** on the signature test ("Missing 'event_bus' parameter").

Now restore:
```bash
mv modules/feedback_admin_module.R.bak modules/feedback_admin_module.R
grep -n "feedback_admin_server <- function" modules/feedback_admin_module.R
# Expected: one line that CONTAINS "event_bus = NULL"

"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-feedback-admin-module.R')"
```
Expected: **PASS** again.

- [ ] **Step 4: Commit**

```bash
git add tests/testthat/test-feedback-admin-module.R
git commit -m "$(cat <<'EOF'
test: add unit tests for feedback_admin_module

Covers the standard module contract: UI returns shiny tags, UI
namespaces IDs with the module id, server signature includes id, i18n,
and event_bus params with event_bus defaulting to NULL (convention
added in ff3a282).

First of three pattern-establishing module tests - the follow-on
coverage for entry_point_module and local_storage_module in this PR
series uses the same structure.
EOF
)"
```

---

## Task 4: Module Test Pattern — `entry_point_module`

**Problem:** `entry_point_module.R` is user-facing first-run experience and had its signature touched in commit `ff3a282`. Same test pattern as Task 3, adapted to its larger parameter list.

**Files:**
- Create: `tests/testthat/test-entry-point-module.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-entry-point-module.R`:

```r
# test-entry-point-module.R
# Unit tests for modules/entry_point_module.R

library(testthat)
library(shiny)

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("entry_point_ui function exists", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  expect_true(is.function(entry_point_ui))
})

test_that("entry_point_ui returns valid shiny tags", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  params <- names(formals(entry_point_ui))
  ui <- if ("i18n" %in% params) entry_point_ui("test_ep", i18n) else entry_point_ui("test_ep")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "entry_point_ui must return shiny.tag or shiny.tag.list"
  )
})

test_that("entry_point_ui uses namespaced IDs", {
  skip_if_not(exists("entry_point_ui", mode = "function"),
              "entry_point_ui not available")
  params <- names(formals(entry_point_ui))
  ui <- if ("i18n" %in% params) entry_point_ui("test_ep", i18n) else entry_point_ui("test_ep")
  ui_html <- as.character(ui)
  expect_true(grepl("test_ep", ui_html), info = "UI must namespace IDs")
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("entry_point_server function exists", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  expect_true(is.function(entry_point_server))
})

test_that("entry_point_server signature includes all required params", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  params <- names(formals(entry_point_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("entry_point_server event_bus defaults to NULL", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  default <- formals(entry_point_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL")
})

test_that("entry_point_server parent_session and user_level_reactive default to NULL", {
  skip_if_not(exists("entry_point_server", mode = "function"),
              "entry_point_server not available")
  fmls <- formals(entry_point_server)
  for (p in c("parent_session", "user_level_reactive")) {
    if (p %in% names(fmls)) {
      default <- fmls[[p]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0(p, " should default to NULL for optional use"))
    }
  }
})
```

- [ ] **Step 2: Run test to verify it passes**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-entry-point-module.R')"
```
Expected: **PASS** — 7 tests pass.

- [ ] **Step 3: Verify test protects against regression**

```bash
# Break the signature
sed -i.bak 's/entry_point_server <- function(id, project_data_reactive, i18n, parent_session = NULL, user_level_reactive = NULL, event_bus = NULL)/entry_point_server <- function(id, project_data_reactive, i18n, parent_session = NULL, user_level_reactive = NULL)/' modules/entry_point_module.R

# Verify the mutation actually applied
grep -n "entry_point_server <- function" modules/entry_point_module.R
# Expected: one line that does NOT end in "event_bus = NULL)"

"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-entry-point-module.R')"
```
Expected: **FAIL** on "Missing parameter: event_bus".

Restore:
```bash
mv modules/entry_point_module.R.bak modules/entry_point_module.R
grep -n "entry_point_server <- function" modules/entry_point_module.R
# Expected: one line that contains "event_bus = NULL"

"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-entry-point-module.R')"
```
Expected: **PASS** again.

- [ ] **Step 4: Commit**

```bash
git add tests/testthat/test-entry-point-module.R
git commit -m "$(cat <<'EOF'
test: add unit tests for entry_point_module

Covers UI return type, namespaced IDs, and server signature
(id + project_data_reactive + i18n + parent_session + user_level_reactive
+ event_bus with NULL defaults on the optional ones).

Second of three pattern-establishing module tests.
EOF
)"
```

---

## Task 5: Module Test Pattern — `local_storage_module`

**Problem:** `local_storage_module.R` handles sessionStorage/localStorage integration for project-data persistence. No current test file. Pattern shows how to cover modules with JS-bridged state.

**Files:**
- Create: `tests/testthat/test-local-storage-module.R`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-local-storage-module.R`:

```r
# test-local-storage-module.R
# Unit tests for modules/local_storage_module.R

library(testthat)
library(shiny)

i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("local_storage_ui function exists", {
  skip_if_not(exists("local_storage_ui", mode = "function"),
              "local_storage_ui not available")
  expect_true(is.function(local_storage_ui))
})

test_that("local_storage_ui returns valid shiny tags", {
  skip_if_not(exists("local_storage_ui", mode = "function"),
              "local_storage_ui not available")
  params <- names(formals(local_storage_ui))
  ui <- if ("i18n" %in% params) local_storage_ui("test_ls", i18n) else local_storage_ui("test_ls")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "local_storage_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("local_storage_server function exists", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  expect_true(is.function(local_storage_server))
})

test_that("local_storage_server signature includes all 4 required params", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  params <- names(formals(local_storage_server))
  # Actual signature at modules/local_storage_module.R:461 is
  #   local_storage_server(id, project_data_reactive, i18n, event_bus = NULL)
  # All 4 are load-bearing: id for namespacing, project_data_reactive for the
  # data pipeline, i18n for translator, event_bus for cross-module notification.
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("local_storage_server event_bus defaults to NULL", {
  skip_if_not(exists("local_storage_server", mode = "function"),
              "local_storage_server not available")
  default <- formals(local_storage_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL")
})

# ============================================================================
# JS BRIDGE CONTRACT TESTS
# ============================================================================

test_that("local_storage_module wires session custom message handlers", {
  # This module communicates with the browser via session$sendCustomMessage.
  # Verify the SERVER source contains at least one sendCustomMessage call
  # (if it doesn't, the JS bridge is broken).
  test_dir <- getwd()
  root <- if (basename(test_dir) == "testthat") dirname(dirname(test_dir)) else test_dir
  fp <- file.path(root, "modules", "local_storage_module.R")
  skip_if_not(file.exists(fp), "local_storage_module.R not found")
  src <- paste(readLines(fp), collapse = "\n")
  expect_true(
    grepl("sendCustomMessage", src, fixed = TRUE),
    info = "local_storage_module must use session$sendCustomMessage for JS bridge"
  )
})
```

- [ ] **Step 2: Run test to verify it passes**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-local-storage-module.R')"
```
Expected: **PASS** — 6 tests pass (UI existence, UI tags, UI namespace absent → only server signature + defaults + JS-bridge tests).

- [ ] **Step 3: Verify test protects against regression**

Break the signature and confirm the test catches it:

```bash
sed -i.bak 's/local_storage_server <- function(id, project_data_reactive, i18n, event_bus = NULL)/local_storage_server <- function(id, i18n)/' modules/local_storage_module.R

# Verify the mutation actually applied (sed silently no-ops on some platforms)
grep -n "local_storage_server <- function" modules/local_storage_module.R
# Expected output must NOT contain "project_data_reactive" or "event_bus"

"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-local-storage-module.R')"
```
Expected: **FAIL** on "Missing parameter: project_data_reactive" and "Missing parameter: event_bus".

Restore:
```bash
mv modules/local_storage_module.R.bak modules/local_storage_module.R
grep -n "local_storage_server <- function" modules/local_storage_module.R
# Expected output must contain "project_data_reactive" and "event_bus = NULL"

"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('tests/testthat/test-local-storage-module.R')"
```
Expected: **PASS** again.

- [ ] **Step 4: Commit**

```bash
git add tests/testthat/test-local-storage-module.R
git commit -m "$(cat <<'EOF'
test: add unit tests for local_storage_module

Third pattern-establishing module test. Adds a JS-bridge contract
check: asserts the module source contains session$sendCustomMessage
(breaking the JS communication would be invisible at type level but
is caught by this string-level assertion).

With feedback_admin, entry_point, and local_storage tests now in place,
follow-on coverage work (the remaining 10 untested *_module.R files)
has a validated pattern to clone.
EOF
)"
```

---

## Task 6: Final Verification

**Goal:** Confirm the full test suite still passes (no regressions from edits in tasks 1-2), then push.

- [ ] **Step 1: Run the full testthat suite**

```bash
"C:/Program Files/R/R-4.4.1/bin/Rscript.exe" tests/run_testthat_summary.R
cat tests/testthat_results.txt
```
Expected: Summary shows a count of passed tests equal to previous baseline PLUS new tests added in this plan (3 tests in test-i18n-enforcement additions + 6 + 7 + 6 in the 3 new module files = 22 new passing tests). No new failures.

Note: if `Rscript.exe` segfaults (known Windows flakiness with some testthat versions), fall back to running test files individually:
```bash
for f in tests/testthat/test-feedback-admin-module.R tests/testthat/test-entry-point-module.R tests/testthat/test-local-storage-module.R tests/testthat/test-i18n-enforcement.R; do
  "C:/Program Files/R/R-4.4.1/bin/Rscript.exe" -e "testthat::test_file('$f')"
done
```

- [ ] **Step 2: Push all commits**

```bash
git log --oneline origin/main..HEAD
# Expected: 5 new commits (Task 1, Task 2, Tasks 3-5 each 1 commit)
git push origin main
```

---

## Self-Review Checklist

Verifying the plan against the deferred-items spec before handing off:

**Spec coverage:**
- ✅ Greek translation anomaly → Task 1
- ✅ Import data i18n gaps → Task 2
- ✅ Changing Language modal → cleared in preamble (intentional pattern, no fix)
- ✅ Module unit-test coverage baseline → Tasks 3-5 (pattern + 3 modules)

**Placeholder scan:** No "TBD", "implement later", or "handle edge cases". All code blocks show complete content. All commands show expected output.

**Type consistency:** All translation key names and test function names defined in early tasks match usage in later tasks:
- `modules.ses.creation.new_to_ses_modeling` (Task 1) — one key, used once.
- 7 new keys in Task 2 — each referenced in both the JSON addition step and the R replacement step with identical names.
- `i18n <- list(t = function(key) key)` mock defined consistently in all three new test files.
- `event_bus` parameter referenced in Tasks 3 and 4 matches the actual R code in `modules/feedback_admin_module.R` and `modules/entry_point_module.R` (added in commit `ff3a282`).

**Expected final state:** 5 commits on `main`, ~300 lines of new code/translation content, no regressions, 22 new passing tests. Branch pushed to `origin/main`.

**Follow-on work not in this plan (should become its own plan if prioritized):**
- Coverage for the remaining 10 untested `*_module.R` files: `ai_isa_assistant`, `cld_visualization`, `export_reports`, `graphical_ses_creator`, `isa_data_entry`, `pims_stakeholder`, `recent_projects`, and 3 others.
- End-to-end browser tests via `shinytest2` for user flows — orthogonal to the unit-test pattern established here.
- Deeper i18n sweeps in other modules flagged during prior reviews.

---

## Execution Record (added after plan was shipped)

Plan executed 2026-04-22. 6 commits landed on `origin/main`:

```
f93135a test: align helper-stubs signatures with current module contracts  (Priority 1 post-exec)
fb5a562 test: add unit tests for local_storage_module                      (Task 5)
2757e05 test: add unit tests for entry_point_module                        (Task 4)
d36dd9e test: add unit tests for feedback_admin_module                     (Task 3)
c82e3ff chore(i18n): complete import_data module column-description coverage (Task 2)
a9061f5 fix(i18n): translate remaining English in Greek "new_to_ses_modeling" (Task 1)
```

### Divergences from the Plan

Two gotchas the plan did not anticipate, both surfaced during Task 4 and
addressed in-session:

**1. `helper-stubs.R` overrode the real module signature.**
Task 4's plan said to `source()` the real `modules/entry_point_module.R`
at the top of the test file to populate `entry_point_server` into
`.GlobalEnv`. In practice, `helper-stubs.R` (loaded before the test file)
had a 3-arg stub `entry_point_server(id, project_data, parent_session)`
that kept winning over the real 6-arg signature. Fix: update the stub to
match the real signature. This unlocked one test case per module with a
similar stub — done comprehensively in Priority 1 post-execution
(commit `f93135a`) for all 7 affected stubs.

**2. `local({ source(file, local = FALSE) })` didn't reliably bind to `.GlobalEnv`.**
The plan's test-file pattern used `local()` wrapping. Switched to
`sys.source(file, envir = .GlobalEnv)` which makes the target
environment explicit. All 3 new test files use this pattern.

### Priority 2 Regression Verification (post-exec)

`sed`-break-then-restore verified Tasks 3 and 5 tests genuinely catch
signature regressions:

- **Task 3 (`feedback_admin`):** removing `event_bus` from the real
  module signature triggered `"Expected event_bus %in% params to be TRUE"`.
  Test is working as designed.
- **Task 5 (`local_storage`):** removing `project_data_reactive` and
  `event_bus` triggered `"Missing parameter: project_data_reactive"` and
  `"Missing parameter: event_bus"`. Test is working as designed.

### Additional Change — helper-stubs Alignment (Priority 1)

In commit `f93135a`, 6 other stubs in `helper-stubs.R` were aligned
with their real module signatures, and 5 caller sites in
`tests/testthat/test-modules.R` were renamed from `project_data = ...`
to `project_data_reactive = ...`. This removes a latent bug: the
existing `testServer()` calls only worked because the old stubs
accepted the wrong arg name — if `global.R` ever loaded cleanly in
CI, those tests would silently fail with unused-argument errors.

### Final Test Scorecard

```
test-feedback-admin-module  : 6  pass, 0 fail, 0 skip
test-entry-point-module     : 7  pass, 0 fail, 0 skip
test-local-storage-module   : 6  pass, 0 fail, 0 skip
test-i18n-enforcement       : 13 pass, 0 fail, 0 skip (3 new blocks from Tasks 1-2)
test-modules                : 28 pass, 0 fail, 0 skip (no regression from stub rename)
test-integration            : 12 pass, 0 fail, 0 skip
test-create-ses-module      : 13 pass, 0 fail, 0 skip

Total: 85 tests, 0 failures, 0 skips
```
