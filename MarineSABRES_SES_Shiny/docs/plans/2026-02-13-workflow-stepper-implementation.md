# Workflow Stepper Overlay — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persistent horizontal stepper bar for beginner users that guides them through the 5-stage SES analysis pipeline (Get Started -> Create SES -> Visualize -> Analyze -> Report).

**Architecture:** A standalone Shiny module (`workflow_stepper_module.R`) renders a fixed bar above `bs4TabItems`. It observes shared reactives (`project_data`, `user_level`, sidebar tab) from the parent session to detect step completion, then triggers navigation nudges via `showNotification()` and tab switches via `updateTabItems()`.

**Tech Stack:** R Shiny, bs4Dash, shiny.i18n (existing stack, zero new packages)

**Design Doc:** `docs/plans/2026-02-13-workflow-stepper-design.md`

---

### Task 1: Create Translation File

**Files:**
- Create: `translations/modules/workflow_stepper.json`

**Step 1: Write the translation file**

```json
{
  "languages": ["en", "es", "fr", "de", "lt", "pt", "it", "no", "el"],
  "translation": {
    "modules.workflow_stepper.step_get_started": {
      "en": "Get Started",
      "lt": "Pradžia",
      "es": "Comenzar",
      "fr": "Commencer",
      "de": "Loslegen",
      "it": "Inizia",
      "pt": "Começar",
      "el": "Ξεκινήστε",
      "no": "Kom i gang"
    },
    "modules.workflow_stepper.step_create_ses": {
      "en": "Create SES",
      "lt": "Sukurti SES",
      "es": "Crear SES",
      "fr": "Créer SES",
      "de": "SES erstellen",
      "it": "Crea SES",
      "pt": "Criar SES",
      "el": "Δημιουργία SES",
      "no": "Opprett SES"
    },
    "modules.workflow_stepper.step_visualize": {
      "en": "Visualize",
      "lt": "Vizualizuoti",
      "es": "Visualizar",
      "fr": "Visualiser",
      "de": "Visualisieren",
      "it": "Visualizza",
      "pt": "Visualizar",
      "el": "Οπτικοποίηση",
      "no": "Visualiser"
    },
    "modules.workflow_stepper.step_analyze": {
      "en": "Analyze",
      "lt": "Analizuoti",
      "es": "Analizar",
      "fr": "Analyser",
      "de": "Analysieren",
      "it": "Analizza",
      "pt": "Analisar",
      "el": "Ανάλυση",
      "no": "Analyser"
    },
    "modules.workflow_stepper.step_report": {
      "en": "Report",
      "lt": "Ataskaita",
      "es": "Informe",
      "fr": "Rapport",
      "de": "Bericht",
      "it": "Report",
      "pt": "Relatório",
      "el": "Αναφορά",
      "no": "Rapport"
    },
    "modules.workflow_stepper.aria_label": {
      "en": "Workflow progress",
      "lt": "Darbo eigos progresas",
      "es": "Progreso del flujo de trabajo",
      "fr": "Progression du flux de travail",
      "de": "Workflow-Fortschritt",
      "it": "Progresso del flusso di lavoro",
      "pt": "Progresso do fluxo de trabalho",
      "el": "Πρόοδος ροής εργασίας",
      "no": "Arbeidsflytfremdrift"
    },
    "modules.workflow_stepper.locked_tooltip": {
      "en": "Create your SES first",
      "lt": "Pirmiausia sukurkite SES",
      "es": "Primero cree su SES",
      "fr": "Créez d'abord votre SES",
      "de": "Erstellen Sie zuerst Ihr SES",
      "it": "Prima crea il tuo SES",
      "pt": "Primeiro crie seu SES",
      "el": "Δημιουργήστε πρώτα το SES σας",
      "no": "Opprett SES først"
    },
    "modules.workflow_stepper.nudge_ses_created": {
      "en": "Your SES model has %s elements. Next: visualize it as a network diagram.",
      "lt": "Jūsų SES modelis turi %s elementų. Kitas žingsnis: vizualizuokite kaip tinklo diagramą.",
      "es": "Su modelo SES tiene %s elementos. Siguiente: visualícelo como un diagrama de red.",
      "fr": "Votre modèle SES contient %s éléments. Suivant : visualisez-le comme un diagramme de réseau.",
      "de": "Ihr SES-Modell hat %s Elemente. Nächster Schritt: als Netzwerkdiagramm visualisieren.",
      "it": "Il tuo modello SES ha %s elementi. Prossimo passo: visualizzalo come diagramma di rete.",
      "pt": "Seu modelo SES tem %s elementos. Próximo: visualize como um diagrama de rede.",
      "el": "Το μοντέλο SES σας έχει %s στοιχεία. Επόμενο: οπτικοποιήστε το ως διάγραμμα δικτύου.",
      "no": "Din SES-modell har %s elementer. Neste: visualiser det som et nettverksdiagram."
    },
    "modules.workflow_stepper.nudge_visualized": {
      "en": "Next: run Loop Detection to find feedback loops in your system.",
      "lt": "Kitas žingsnis: paleiskite ciklų aptikimą, kad rastumėte grįžtamojo ryšio ciklus.",
      "es": "Siguiente: ejecute la detección de bucles para encontrar ciclos de retroalimentación.",
      "fr": "Suivant : lancez la détection de boucles pour trouver les boucles de rétroaction.",
      "de": "Nächster Schritt: Schleifenerkennung durchführen, um Rückkopplungsschleifen zu finden.",
      "it": "Prossimo passo: esegui il rilevamento dei cicli per trovare i cicli di feedback.",
      "pt": "Próximo: execute a detecção de loops para encontrar ciclos de feedback.",
      "el": "Επόμενο: εκτελέστε ανίχνευση βρόχων για να βρείτε βρόχους ανατροφοδότησης.",
      "no": "Neste: kjør løkkedeteksjon for å finne tilbakekoblingsløkker."
    },
    "modules.workflow_stepper.nudge_analyzed": {
      "en": "Analysis complete! You can now generate a report.",
      "lt": "Analizė baigta! Dabar galite generuoti ataskaitą.",
      "es": "¡Análisis completo! Ahora puede generar un informe.",
      "fr": "Analyse terminée ! Vous pouvez maintenant générer un rapport.",
      "de": "Analyse abgeschlossen! Sie können jetzt einen Bericht erstellen.",
      "it": "Analisi completata! Ora puoi generare un report.",
      "pt": "Análise concluída! Agora você pode gerar um relatório.",
      "el": "Η ανάλυση ολοκληρώθηκε! Μπορείτε τώρα να δημιουργήσετε αναφορά.",
      "no": "Analyse fullført! Du kan nå generere en rapport."
    },
    "modules.workflow_stepper.nudge_complete": {
      "en": "Congratulations! You have completed the full SES analysis pipeline.",
      "lt": "Sveikiname! Jūs baigėte visą SES analizės procesą.",
      "es": "¡Felicidades! Ha completado todo el proceso de análisis SES.",
      "fr": "Félicitations ! Vous avez terminé le processus complet d'analyse SES.",
      "de": "Herzlichen Glückwunsch! Sie haben die vollständige SES-Analyse abgeschlossen.",
      "it": "Congratulazioni! Hai completato l'intero processo di analisi SES.",
      "pt": "Parabéns! Você completou todo o processo de análise SES.",
      "el": "Συγχαρητήρια! Ολοκληρώσατε πλήρως τη διαδικασία ανάλυσης SES.",
      "no": "Gratulerer! Du har fullført hele SES-analyseprosessen."
    },
    "modules.workflow_stepper.btn_go_visualization": {
      "en": "Go to Visualization",
      "lt": "Eiti į vizualizaciją",
      "es": "Ir a Visualización",
      "fr": "Aller à la Visualisation",
      "de": "Zur Visualisierung",
      "it": "Vai alla Visualizzazione",
      "pt": "Ir para Visualização",
      "el": "Μετάβαση στην Οπτικοποίηση",
      "no": "Gå til Visualisering"
    },
    "modules.workflow_stepper.btn_go_analysis": {
      "en": "Go to Loop Detection",
      "lt": "Eiti į ciklų aptikimą",
      "es": "Ir a Detección de Bucles",
      "fr": "Aller à la Détection de Boucles",
      "de": "Zur Schleifenerkennung",
      "it": "Vai al Rilevamento Cicli",
      "pt": "Ir para Detecção de Loops",
      "el": "Μετάβαση στην Ανίχνευση Βρόχων",
      "no": "Gå til Løkkedeteksjon"
    },
    "modules.workflow_stepper.btn_go_report": {
      "en": "Generate Report",
      "lt": "Generuoti ataskaitą",
      "es": "Generar Informe",
      "fr": "Générer un Rapport",
      "de": "Bericht erstellen",
      "it": "Genera Report",
      "pt": "Gerar Relatório",
      "el": "Δημιουργία Αναφοράς",
      "no": "Generer Rapport"
    }
  }
}
```

**Step 2: Verify JSON is valid**

Run: `python -c "import json; json.load(open('translations/modules/workflow_stepper.json', encoding='utf-8')); print('OK')"`
Expected: `OK`

**Step 3: Commit**

```bash
git add translations/modules/workflow_stepper.json
git commit -m "feat: add workflow stepper translation keys (9 languages)"
```

---

### Task 2: Create Stepper CSS

**Files:**
- Create: `www/workflow-stepper.css`

**Step 1: Write the CSS file**

The stepper bar sits above `bs4TabItems`. It uses flexbox for horizontal layout. Step states are driven by CSS classes: `.ws-completed`, `.ws-active`, `.ws-enabled`, `.ws-locked`.

```css
/* Workflow Stepper Bar */
.workflow-stepper-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 20px;
  margin: 0 0 15px 0;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 8px;
  border: 1px solid #dee2e6;
  position: relative;
}

.workflow-stepper-steps {
  display: flex;
  align-items: center;
  gap: 0;
  flex: 1;
  justify-content: center;
}

/* Individual step */
.ws-step {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: default;
  padding: 6px 12px;
  border-radius: 20px;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.ws-step-icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: bold;
  flex-shrink: 0;
  transition: all 0.3s ease;
}

.ws-step-label {
  font-size: 13px;
  font-weight: 500;
  transition: color 0.3s ease;
}

/* Connector line between steps */
.ws-connector {
  width: 40px;
  height: 2px;
  background: #dee2e6;
  flex-shrink: 0;
  transition: background 0.3s ease;
}

.ws-connector.ws-connector-done {
  background: #28a745;
}

/* Completed state */
.ws-step.ws-completed {
  cursor: pointer;
}

.ws-step.ws-completed .ws-step-icon {
  background: #28a745;
  color: #fff;
}

.ws-step.ws-completed .ws-step-label {
  color: #28a745;
}

.ws-step.ws-completed:hover {
  background: rgba(40, 167, 69, 0.1);
}

/* Active state */
.ws-step.ws-active .ws-step-icon {
  background: #667eea;
  color: #fff;
  animation: pulse-glow 2s infinite;
}

.ws-step.ws-active .ws-step-label {
  color: #667eea;
  font-weight: 600;
}

/* Enabled (clickable but not started) */
.ws-step.ws-enabled {
  cursor: pointer;
}

.ws-step.ws-enabled .ws-step-icon {
  background: #fff;
  border: 2px solid #6c757d;
  color: #6c757d;
}

.ws-step.ws-enabled .ws-step-label {
  color: #6c757d;
}

.ws-step.ws-enabled:hover {
  background: rgba(108, 117, 125, 0.1);
}

/* Locked state */
.ws-step.ws-locked .ws-step-icon {
  background: #e9ecef;
  border: 2px solid #dee2e6;
  color: #adb5bd;
}

.ws-step.ws-locked .ws-step-label {
  color: #adb5bd;
}

/* Dismiss button */
.ws-dismiss {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: #adb5bd;
  font-size: 16px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  line-height: 1;
}

.ws-dismiss:hover {
  color: #6c757d;
  background: rgba(0, 0, 0, 0.05);
}

/* Responsive: hide labels on small screens */
@media (max-width: 768px) {
  .ws-step-label {
    display: none;
  }
  .ws-connector {
    width: 20px;
  }
}
```

**Step 2: Commit**

```bash
git add www/workflow-stepper.css
git commit -m "feat: add workflow stepper CSS styles"
```

---

### Task 3: Create Stepper Module

**Files:**
- Create: `modules/workflow_stepper_module.R`

**Context needed:**
- This R Shiny app uses `moduleServer()` pattern for modules
- All modules receive `i18n` for translations (a session-local wrapper around `shiny.i18n`)
- `project_data` is a `reactiveVal()` containing a list with `$data$isa_data` (named sublists: `drivers`, `activities`, `pressures`, `marine_processes`, `ecosystem_services`, `goods_benefits`)
- `user_level` is a `reactiveVal()` returning `"beginner"`, `"intermediate"`, or `"expert"`
- Loop detection results live at `project_data()$data$analysis$loops`
- Tab navigation uses `updateTabItems(parent_session, "sidebar_menu", tab_name)`
- Sidebar tab names: `"entry_point"`, `"cld_visualization"`, `"loop_detection"`, `"prepare_report"`
- Use `debug_log(msg, context)` for logging (not `cat()` or `print()`)
- The stepper is an overlay above tab content, not a tab itself

**Step 1: Write the module file**

```r
# =============================================================================
# WORKFLOW STEPPER MODULE
# Displays a horizontal stepper bar for beginner users showing the 5-stage
# SES analysis pipeline: Get Started -> Create SES -> Visualize -> Analyze -> Report
# =============================================================================

# --- UI ---
workflow_stepper_ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("stepper_bar"))
}

# --- Server ---
workflow_stepper_server <- function(id, project_data_reactive, i18n,
                                    parent_session, user_level_reactive,
                                    sidebar_input) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Step definitions: label key and target sidebar tab
    STEPS <- list(
      list(key = "step_get_started", tab = "entry_point"),
      list(key = "step_create_ses",  tab = "isa_data_entry"),
      list(key = "step_visualize",   tab = "cld_visualization"),
      list(key = "step_analyze",     tab = "loop_detection"),
      list(key = "step_report",      tab = "prepare_report")
    )

    # Workflow state
    wf <- reactiveValues(
      completed = c(FALSE, FALSE, FALSE, FALSE, FALSE),
      enabled   = c(TRUE,  TRUE,  FALSE, FALSE, FALSE),
      visible   = TRUE,
      user_modified_ses = FALSE,
      notified  = c(FALSE, FALSE, FALSE, FALSE, FALSE),
      viz_enter_time = NULL
    )

    # --- Count total ISA elements ---
    count_isa_elements <- function(data) {
      isa <- data$data$isa_data
      if (is.null(isa)) return(0)
      categories <- c("drivers", "activities", "pressures",
                       "marine_processes", "ecosystem_services", "goods_benefits")
      total <- 0
      for (cat in categories) {
        if (!is.null(isa[[cat]]) && is.data.frame(isa[[cat]])) {
          total <- total + nrow(isa[[cat]])
        }
      }
      total
    }

    # --- Determine current step (highest non-completed enabled step) ---
    current_step <- reactive({
      for (i in seq_along(wf$completed)) {
        if (!wf$completed[i] && wf$enabled[i]) return(i)
      }
      # All completed — stay on last
      5
    })

    # --- COMPLETION OBSERVERS ---

    # Step 1: Entry Point — mark complete when sidebar leaves entry_point
    # (user has gone through getting started and moved on)
    observe({
      req(sidebar_input())
      if (sidebar_input() != "entry_point" && !wf$completed[1]) {
        wf$completed[1] <- TRUE
        debug_log("Workflow step 1 (Get Started) completed", "STEPPER")
      }
    })

    # Track user modification of SES data
    observe({
      req(project_data_reactive())
      # Skip the initial load — only flag as modified after first change
      if (!wf$user_modified_ses) {
        invalidateLater(2000)  # wait 2s after app start before enabling tracking
        wf$user_modified_ses <- TRUE
        debug_log("SES data modification tracking enabled", "STEPPER")
      }
    }) |> bindEvent(project_data_reactive(), ignoreInit = TRUE)

    # Step 2: Create SES — when elements >= 2 and user has modified data
    observe({
      req(project_data_reactive())
      if (wf$completed[2]) return()
      if (!wf$user_modified_ses) return()
      n <- count_isa_elements(project_data_reactive())
      if (n >= 2) {
        wf$completed[2] <- TRUE
        wf$enabled[3] <- TRUE
        wf$enabled[4] <- TRUE
        wf$enabled[5] <- TRUE
        debug_log(sprintf("Workflow step 2 (Create SES) completed with %d elements", n), "STEPPER")

        if (!wf$notified[2]) {
          wf$notified[2] <- TRUE
          msg <- sprintf(i18n$t("modules.workflow_stepper.nudge_ses_created"), n)
          showNotification(
            tagList(
              msg, tags$br(),
              actionButton(ns("go_viz"), i18n$t("modules.workflow_stepper.btn_go_visualization"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 3: Visualize — when CLD tab visited with data for 3 seconds
    observe({
      req(sidebar_input())
      if (wf$completed[3]) return()
      if (!wf$enabled[3]) return()

      if (sidebar_input() == "cld_visualization") {
        n <- count_isa_elements(project_data_reactive())
        if (n >= 2 && is.null(wf$viz_enter_time)) {
          wf$viz_enter_time <- Sys.time()
        }
      } else {
        wf$viz_enter_time <- NULL
      }
    })

    observe({
      req(wf$viz_enter_time)
      if (wf$completed[3]) return()
      invalidateLater(3000)
      if (!is.null(wf$viz_enter_time) && difftime(Sys.time(), wf$viz_enter_time, units = "secs") >= 3) {
        wf$completed[3] <- TRUE
        debug_log("Workflow step 3 (Visualize) completed", "STEPPER")

        if (!wf$notified[3]) {
          wf$notified[3] <- TRUE
          showNotification(
            tagList(
              i18n$t("modules.workflow_stepper.nudge_visualized"), tags$br(),
              actionButton(ns("go_analysis"), i18n$t("modules.workflow_stepper.btn_go_analysis"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 4: Analyze — when loop detection results exist
    observe({
      req(project_data_reactive())
      if (wf$completed[4]) return()
      if (!wf$enabled[4]) return()
      loops <- project_data_reactive()$data$analysis$loops
      if (!is.null(loops)) {
        wf$completed[4] <- TRUE
        debug_log("Workflow step 4 (Analyze) completed", "STEPPER")

        if (!wf$notified[4]) {
          wf$notified[4] <- TRUE
          showNotification(
            tagList(
              i18n$t("modules.workflow_stepper.nudge_analyzed"), tags$br(),
              actionButton(ns("go_report"), i18n$t("modules.workflow_stepper.btn_go_report"),
                           class = "btn-sm btn-primary mt-2")
            ),
            type = "message", duration = 15
          )
        }
      }
    })

    # Step 5: Report — when report results exist in project data
    # We check for the prepare_report tab being visited AND having completed steps 1-4
    observe({
      req(sidebar_input())
      if (wf$completed[5]) return()
      if (!wf$enabled[5]) return()
      # Mark complete when user visits report tab with all prior steps done
      if (sidebar_input() == "prepare_report" && all(wf$completed[1:4])) {
        wf$completed[5] <- TRUE
        debug_log("Workflow step 5 (Report) completed", "STEPPER")

        if (!wf$notified[5]) {
          wf$notified[5] <- TRUE
          showNotification(
            i18n$t("modules.workflow_stepper.nudge_complete"),
            type = "message", duration = 10
          )
        }
      }
    })

    # --- Handle imported/restored projects ---
    observe({
      req(project_data_reactive())
      data <- project_data_reactive()
      n <- count_isa_elements(data)
      has_loops <- !is.null(data$data$analysis$loops)

      # If project already has elements, auto-complete steps 1-2
      if (n >= 2 && !wf$completed[2]) {
        wf$completed[1] <- TRUE
        wf$completed[2] <- TRUE
        wf$enabled[3] <- TRUE
        wf$enabled[4] <- TRUE
        wf$enabled[5] <- TRUE
        wf$user_modified_ses <- TRUE
        debug_log("Imported project detected — steps 1-2 auto-completed", "STEPPER")
      }

      # If project already has loop results, auto-complete step 4
      if (has_loops && !wf$completed[4] && wf$completed[2]) {
        wf$completed[3] <- TRUE
        wf$completed[4] <- TRUE
        debug_log("Imported project with loops — steps 3-4 auto-completed", "STEPPER")
      }
    }) |> bindEvent(project_data_reactive(), ignoreInit = TRUE)

    # --- Handle element deletion (revert) ---
    observe({
      req(project_data_reactive())
      if (!wf$completed[2]) return()
      n <- count_isa_elements(project_data_reactive())
      if (n < 2) {
        wf$completed[2] <- FALSE
        wf$completed[3] <- FALSE
        wf$completed[4] <- FALSE
        wf$completed[5] <- FALSE
        wf$enabled[3] <- FALSE
        wf$enabled[4] <- FALSE
        wf$enabled[5] <- FALSE
        wf$notified[2] <- FALSE
        wf$notified[3] <- FALSE
        wf$notified[4] <- FALSE
        wf$notified[5] <- FALSE
        debug_log("Elements deleted below threshold — steps 2-5 reverted", "STEPPER")
      }
    })

    # --- NAVIGATION BUTTON HANDLERS ---
    observeEvent(input$go_viz, {
      updateTabItems(parent_session, "sidebar_menu", "cld_visualization")
    })

    observeEvent(input$go_analysis, {
      updateTabItems(parent_session, "sidebar_menu", "loop_detection")
    })

    observeEvent(input$go_report, {
      updateTabItems(parent_session, "sidebar_menu", "prepare_report")
    })

    observeEvent(input$dismiss_stepper, {
      wf$visible <- FALSE
      debug_log("Stepper dismissed by user", "STEPPER")
    })

    # Step click handlers
    lapply(seq_along(STEPS), function(i) {
      observeEvent(input[[paste0("step_click_", i)]], {
        if (wf$enabled[i] || wf$completed[i]) {
          updateTabItems(parent_session, "sidebar_menu", STEPS[[i]]$tab)
        }
      })
    })

    # --- RENDER STEPPER BAR ---
    output$stepper_bar <- renderUI({
      # Only show for beginners
      req(user_level_reactive() == "beginner")
      req(wf$visible)

      cur <- current_step()

      step_items <- lapply(seq_along(STEPS), function(i) {
        step <- STEPS[[i]]
        label <- i18n$t(paste0("modules.workflow_stepper.", step$key))

        # Determine CSS class
        css_class <- if (wf$completed[i]) {
          "ws-step ws-completed"
        } else if (i == cur) {
          "ws-step ws-active"
        } else if (wf$enabled[i]) {
          "ws-step ws-enabled"
        } else {
          "ws-step ws-locked"
        }

        # Icon content
        icon_content <- if (wf$completed[i]) {
          icon("check")
        } else {
          as.character(i)
        }

        # Tooltip for locked
        tooltip <- if (!wf$enabled[i] && !wf$completed[i]) {
          i18n$t("modules.workflow_stepper.locked_tooltip")
        } else {
          NULL
        }

        # Accessibility attributes
        aria <- list()
        if (i == cur) aria[["aria-current"]] <- "step"
        if (!wf$enabled[i] && !wf$completed[i]) aria[["aria-disabled"]] <- "true"

        step_tag <- tags$div(
          class = css_class,
          title = tooltip,
          `aria-current` = aria[["aria-current"]],
          `aria-disabled` = aria[["aria-disabled"]],
          if (wf$enabled[i] || wf$completed[i]) {
            actionLink(ns(paste0("step_click_", i)), label = NULL,
              class = "ws-step-clickable",
              style = "text-decoration: none; color: inherit; display: flex; align-items: center; gap: 8px;",
              tags$span(class = "ws-step-icon", icon_content),
              tags$span(class = "ws-step-label", label)
            )
          } else {
            tagList(
              tags$span(class = "ws-step-icon", icon_content),
              tags$span(class = "ws-step-label", label)
            )
          }
        )

        # Add connector line after all steps except the last
        if (i < length(STEPS)) {
          connector_class <- if (wf$completed[i] && (wf$completed[i + 1] || i + 1 == cur)) {
            "ws-connector ws-connector-done"
          } else {
            "ws-connector"
          }
          tagList(step_tag, tags$div(class = connector_class))
        } else {
          step_tag
        }
      })

      tags$nav(
        class = "workflow-stepper-bar",
        role = "navigation",
        `aria-label` = i18n$t("modules.workflow_stepper.aria_label"),
        tags$div(class = "workflow-stepper-steps", step_items),
        actionLink(ns("dismiss_stepper"), label = NULL,
          class = "ws-dismiss",
          title = "Dismiss",
          icon("times")
        )
      )
    })
  })
}
```

**Step 2: Verify syntax**

Run: `"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "parse('modules/workflow_stepper_module.R'); cat('Syntax OK\n')"`
Expected: `Syntax OK`

**Step 3: Commit**

```bash
git add modules/workflow_stepper_module.R
git commit -m "feat: add workflow stepper module (UI + server logic)"
```

---

### Task 4: Wire Stepper into App

**Files:**
- Modify: `global.R` (line 389, add source)
- Modify: `app.R` (line 271, add stepper UI; ~line 868, add server wiring)

**Step 1: Add source in global.R**

After line 389 (`source("modules/connection_review_tabbed.R", local = TRUE)`), add:

```r
source("modules/workflow_stepper_module.R", local = TRUE)
```

**Step 2: Add stepper UI in app.R**

After line 271 (`tutorial_ui(),`), before line 273 (`bs4TabItems(`), add:

```r
    # Workflow stepper bar (beginner guidance)
    workflow_stepper_ui("workflow_stepper"),
```

**Step 3: Add CSS link in app.R**

Inside the existing `tags$head(...)` block (around line 211-213), after the `isa-forms.css` link, add:

```r
    tags$link(rel = "stylesheet", type = "text/css", href = "workflow-stepper.css"),
```

**Step 4: Wire stepper server in app.R**

After the entry_point_server call (line 868), add:

```r
  # Workflow stepper (beginner guidance bar)
  workflow_stepper_server(
    "workflow_stepper",
    project_data_reactive = project_data,
    i18n = session_i18n,
    parent_session = session,
    user_level_reactive = user_level,
    sidebar_input = reactive(input$sidebar_menu)
  )
```

**Step 5: Register translation file**

Find where translation JSON files are loaded in `global.R`. The i18n translator needs to include the new file. Search for existing `workflow_stepper.json` registration or the pattern used to load translation files.

Check: `grep -n "workflow_stepper\|merge_json\|add_translation" global.R`

If translations are auto-discovered from the `translations/` directory, no change needed. If they're explicitly listed, add `"translations/modules/workflow_stepper.json"` to the list.

**Step 6: Verify the app starts without errors**

Run: `"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "source('global.R'); cat('global.R loaded OK\n')"`
Expected: `global.R loaded OK`

**Step 7: Commit**

```bash
git add global.R app.R
git commit -m "feat: wire workflow stepper into app shell"
```

---

### Task 5: Manual Verification

**Step 1: Start the app**

Run: `"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" -e "shiny::runApp('.', port = 3838, launch.browser = TRUE)"`

**Step 2: Verify stepper appears for beginners**

- Open `http://localhost:3838` (defaults to beginner level)
- Confirm: horizontal stepper bar visible above content
- Confirm: step 1 "Get Started" is active (blue dot, pulsing)
- Confirm: steps 3-5 are locked (grey, not clickable)

**Step 3: Verify step 1 completion**

- Navigate away from "Getting Started" (click any other sidebar item)
- Confirm: step 1 shows green checkmark
- Confirm: step 2 "Create SES" becomes active

**Step 4: Verify step 2 completion**

- Go to Create SES -> AI Assistant or Standard Entry
- Add at least 2 elements (e.g., a driver and an activity)
- Confirm: notification appears with "Go to Visualization" button
- Confirm: steps 3-5 unlock (grey dots, clickable)

**Step 5: Verify dismiss**

- Click the x button on the stepper bar
- Confirm: stepper disappears
- Confirm: stepper does NOT reappear when navigating tabs

**Step 6: Verify hidden for intermediate/expert**

- Open `http://localhost:3838?user_level=intermediate`
- Confirm: stepper bar is NOT visible

**Step 7: Verify language switching**

- Switch to Lithuanian or Spanish
- Confirm: stepper labels update to the target language

**Step 8: Commit final state**

If any fixes were needed during verification, commit them:

```bash
git add -A
git commit -m "fix: workflow stepper adjustments from manual testing"
```
