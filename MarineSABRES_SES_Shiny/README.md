# MarineSABRES SES Toolbox

[![R Version](https://img.shields.io/badge/R-%E2%89%A54.4.1-blue)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-bs4Dash-green)](https://bs4dash.rinterface.com/)
[![Version](https://img.shields.io/badge/version-1.15.0-brightgreen)](CHANGELOG.md)
[![Languages](https://img.shields.io/badge/languages-9-orange)](translations/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

An R Shiny application for **Social-Ecological Systems (SES) modelling** in marine ecosystems, with an integrated 8-component machine-learning pipeline that learns from the [Marine-SABRES](https://marinesabres.eu/) Horizon Europe participatory knowledge base.

**Live deployment:** [laguna.ku.lt/marinesabres](https://laguna.ku.lt/marinesabres/) (v1.15.0+)

---

## What's new in v1.15.0

The v1.15.0 release closes the implementation gap to the original ESP 2026 abstract's claim of "eight complementary machine-learning approaches". All eight are now live, trained, and documented:

| # | ML approach | What it does | Where |
|---|---|---|---|
| 1 | Multi-task neural network | Predicts existence + strength + confidence + polarity of candidate connections | `functions/ml_models.R` |
| 2 | GraphSAGE graph NN | Learned node embeddings from the partial-model topology | `functions/ml_models.R` |
| 3 | Similarity-guided transfer learning | Per-template fine-tuning with adaptive learning rate | `scripts/fine_tune_for_template.R` |
| 4 | BERT chunk-classification | Maps free text to one of 7 DAPSI(W)R(M) categories | `functions/ml_element_classifier.R` |
| 5 | LinUCB contextual bandit | Prioritizes response measures from user feedback | `functions/ml_response_bandit.R` |
| 6 | Ensemble + active learning | Inter-model disagreement surfaces high-uncertainty candidates | `functions/ml_ensemble.R` |
| 7 | Collaborative filtering | SVD-based element recommendations across saved projects | `functions/ml_collaborative_filter.R` |
| 8 | Transformer text embeddings | Sentence-transformer encoder for semantic name matching | `functions/ml_text_embeddings.R` |

**Methods overview:** [`docs/ML_METHODS.md`](docs/ML_METHODS.md)
**In silico validation results:** [`docs/IN_SILICO_VALIDATION.md`](docs/IN_SILICO_VALIDATION.md)
**Pilot study protocol:** [`docs/ml_pilot_protocol.md`](docs/ml_pilot_protocol.md)

### In silico validation — headline numbers

In silico evaluation across the seven production SES templates:

- **Connection recovery:** ML-augmented simulated non-experts recover validated connections at **median +100% relative lift** vs. uniformly random framework-valid picks (0.031 → 0.100, +6.9 percentage points absolute).
- **Cross-user consistency:** Pairwise Jaccard similarity of five simulated users' final models is **+396% higher** with ML scaffolding (0.110 → 0.502). A substantial share of this is the determinism floor of ML scoring; real-user gains will be measured by the planned pilot.
- **Literature calibration:** Model existence probability correlates positively with KB reference count (Spearman ρ = +0.054, p = 0.039) and with consortium expert-confidence ratings (mean probability rises monotonically from 0.880 at confidence-level 2 to 0.925 at confidence-level 5).

A small-N human-subject pilot (`modules/pilot_study_module.R`) is instrumented and ready to deploy; protocol and consent forms are in `docs/`.

---

## Screenshots

> Captured from the live application at v1.13.1; v1.15.0 UI is visually similar.

### Home Page — Guided Workflow
![Home Page](docs/images/screenshot-home.png)
*Workflow stepper (Get Started → Create SES → Visualize → Analyze → Report), guided-pathway entry card with "Start Guided Journey" CTA, and a built-in FAQ section. Sidebar gives one-click access to every tool.*

### SES Creation
![SES Creation](docs/images/screenshot-visualization.png)
*Three paths to build a model: Templates (pre-configured marine SES like Fisheries, Caribbean, Offshore Wind), AI-guided creation, and Standard Entry. The same workflow stepper at the top shows progress through the 5-stage analysis pipeline.*

### Network Visualization & Layout Controls
![Visualization Layout](docs/images/screenshot-layout.png)
*Causal Loop Diagram view with hierarchical (DAPSI(W)R(M)-aware) and physics-based layouts, on-screen editing toggle, leverage-point highlighting, and loop highlighting. Auto-save indicator confirms persistence.*

---

## Overview

The MarineSABRES SES Toolbox enables researchers, policymakers, and stakeholders to model and analyze marine social-ecological systems using the **DAPSI(W)R(M)** framework:

| Component | Description |
|---|---|
| **D**rivers | Root causes (food security, economic needs) |
| **A**ctivities | Human actions (fishing, tourism) |
| **P**ressures | Environmental stressors |
| **S**tates (Marine Processes & Functioning) | Ecosystem state |
| **I**mpacts (Ecosystem Services) | Benefits flowing from the ecosystem |
| **(W)elfare** (Goods & Benefits) | Human-welfare outcomes |
| **R**esponses | Policy interventions |
| **(M)easures** | Implementation actions |

Connections follow the sequential framework D → A → P → MPF → ES → G&B → R, with explicit feedback loops from R back to D / A / P / MPF. See [`DAPSIWRM_FRAMEWORK_RULES.md`](DAPSIWRM_FRAMEWORK_RULES.md) for the complete typed-transition table.

### Key capabilities

- **Build SES models** from scratch, from one of 7 production templates, or with AI assistance.
- **Visualize causal relationships** as interactive Causal Loop Diagrams (visNetwork).
- **Analyze system dynamics** — network metrics, feedback loops, leverage points, Boolean stability, BOT.
- **Design response measures** with ML-ranked priority suggestions (LinUCB bandit).
- **Generate reports** in HTML, Word, PowerPoint, and PDF.
- **9 languages** with locale-stable internal categorical keys: English, Spanish, French, German, Lithuanian, Portuguese, Italian, Norwegian, Greek.

---

## The knowledge base

The ML pipeline learns from MarineSABRES's participatory knowledge base:

| Layer | Contexts | Connections | Unique elements |
|---|---:|---:|---:|
| 3 demonstration regions (training) | 11 | **412** | 400+ |
| Full repository | **33** | **1,185** | — |
| 7 production templates (Toolbox ships) | 7 | 300 | 285 |
| Offshore-wind KB add-on | 4 | 217 | — |

Every connection is annotated with polarity (+/−), strength (weak/medium/strong), confidence (1-5), temporal lag, reversibility, and literature references. The reference list is in [`docs/KB_BIBLIOGRAPHY.md`](docs/KB_BIBLIOGRAPHY.md).

---

## Quick start

### Prerequisites
- R >= 4.4.1
- RStudio recommended

### Installation

```r
install.packages(c(
  "shiny", "bs4Dash", "shinyWidgets", "shinyjs", "shinyBS", "shinyFiles",
  "shiny.i18n", "DT", "jsonlite", "openxlsx", "readxl", "httr", "digest",
  "igraph", "visNetwork", "ggraph", "tidygraph", "ggplot2", "plotly",
  "dygraphs", "xts", "tidyverse",
  "htmltools", "htmlwidgets", "rmarkdown", "knitr",
  "officer", "flextable", "tinytex"
))

# Optional: ML pipeline
install.packages(c("torch", "coro", "sortable"))
# Optional: PDF export
tinytex::install_tinytex()
```

### Running the app

```r
shiny::runApp()
```

Opens at `http://127.0.0.1:3838`.

### Reproducing the ML training + validation

```bash
# Connection-predictor base model (v1.14.0)
Rscript scripts/train_connection_predictor.R

# GraphSAGE GNN (v1.15.0)
Rscript scripts/train_connection_predictor_gnn.R

# BERT element classifier
Rscript scripts/extract_classifier_training_data.py   # produces data/element_classifier_training.json
Rscript scripts/train_element_classifier.R

# Warm-start bandit + CF
Rscript scripts/warm_start_response_bandit.R
Rscript scripts/warm_start_cf.R

# Retrospective + in silico validation
Rscript scripts/retrospective_validation_gnn.R
Rscript scripts/simulate_non_expert_users.R
Rscript scripts/cross_template_consistency.R
Rscript scripts/bibliometric_validation.R
```

All scripts are deterministic with `set.seed(42)` and write outputs to `data/` + `models/`. Reproducibility checksums for shipped model weights are in `models/checksums.json`.

---

## Project structure

```
MarineSABRES_SES_Shiny/
├── app.R                     # Main entry point
├── global.R                  # Package loading, startup
├── constants.R               # DAPSI(W)R(M) elements, colors, shapes
├── VERSION, VERSION_INFO.json
├── DESCRIPTION               # Package manifest
├── modules/                  # 45 Shiny modules (incl. pilot_study_module.R)
├── functions/                # Helpers
│   ├── ml_models.R                  # Base predictor + GraphSAGE
│   ├── ml_text_embeddings.R         # 5 embedding strategies
│   ├── ml_element_classifier.R      # BERT chunk classifier
│   ├── ml_response_bandit.R         # LinUCB
│   ├── ml_collaborative_filter.R    # SVD CF
│   ├── ml_ensemble.R / ml_active_learning.R / ml_template_matching.R
│   ├── ml_feature_engineering.R / ml_graph_features.R
│   ├── network_analysis.R           # igraph operations
│   └── data_structure.R / error_handling.R / ui_components.R / ...
├── server/                   # Bookmarking, event bus, exports, modals, project I/O
├── scripts/                  # Training, fine-tuning, validation, deployment
├── translations/             # 9 languages × 30+ modular JSON files
├── data/                     # KB JSONs, training data, model state, in-silico results
├── models/                   # Trained PyTorch checkpoints (gitignored except checksums)
├── docs/                     # Architecture, methods, validation, pilot, KB bibliography
├── www/                      # Static assets (CSS, images, user-facing markdown guides)
├── tests/testthat/           # 56+ test files
└── deployment/               # Deploy scripts, Dockerfile, pre-deploy guard
```

---

## Documentation

| Document | Description |
|---|---|
| [`CHANGELOG.md`](CHANGELOG.md) | Release notes (v1.5 → v1.15.0) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guidelines, code conventions |
| [`CLAUDE.md`](CLAUDE.md) | Project conventions and AI-assistant guidance |
| [`DAPSIWRM_FRAMEWORK_RULES.md`](DAPSIWRM_FRAMEWORK_RULES.md) | Framework connection rules and polarity logic |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Architecture Decision Records (17 ADRs) |
| [`docs/RESEARCH_OUTPUTS.md`](docs/RESEARCH_OUTPUTS.md) | Index of conference materials, validation docs, citation guidance |
| [`docs/ML_METHODS.md`](docs/ML_METHODS.md) | Paper-ready ML pipeline description |
| [`docs/IN_SILICO_VALIDATION.md`](docs/IN_SILICO_VALIDATION.md) | In silico validation results with caveats |
| [`docs/RETROSPECTIVE_VALIDATION.md`](docs/RETROSPECTIVE_VALIDATION.md) | precision@k base vs GNN comparison |
| [`docs/ml_pilot_protocol.md`](docs/ml_pilot_protocol.md) | Pilot study design, primary/secondary outcomes |
| [`docs/ml_pilot_consent_form.md`](docs/ml_pilot_consent_form.md) | Participant information + consent |
| [`docs/IMPLEMENTATION_PLAN_FROM_ORIGINAL_ABSTRACT.md`](docs/IMPLEMENTATION_PLAN_FROM_ORIGINAL_ABSTRACT.md) | Planning document for v1.15.0 |
| [`docs/KB_BIBLIOGRAPHY.md`](docs/KB_BIBLIOGRAPHY.md) | Literature references underlying the KB |
| [`Documents/ML_ARCHITECTURE.md`](Documents/ML_ARCHITECTURE.md) | Pre-v1.14 ML architecture notes |
| [`Documents/ISA_User_Guide.md`](Documents/ISA_User_Guide.md) | End-user ISA workflow guide |
| [`translations/README.md`](translations/README.md) | i18n system guide |
| [`tests/README.md`](tests/README.md) | Test framework documentation |
| [`deployment/REMOTE_DEPLOYMENT_README.md`](deployment/REMOTE_DEPLOYMENT_README.md) | Production deploy guide |

---

## Deployment

### Production (laguna.ku.lt)

```powershell
# Windows
.\deployment\deploy-remote.ps1 -DryRun    # preview
.\deployment\deploy-remote.ps1            # deploy
```

```bash
# Linux/Mac
bash deployment/remote-deploy.sh --dry-run
bash deployment/remote-deploy.sh
```

A pre-deploy guard (`Rscript deployment/pre-deploy-check.R`) verifies `VERSION` ↔ `VERSION_INFO.json` consistency and checks all required packages before deploy. 39 checks total.

### Docker

```bash
docker build -f deployment/Dockerfile -t marinesabres .
docker run -p 3838:3838 marinesabres
```

---

## Development

### Running tests

```bash
Rscript tests/run_all_tests.R                                # all
Rscript -e "testthat::test_dir('tests/testthat')"            # testthat suite
Rscript -e "testthat::test_file('tests/testthat/test-i18n-enforcement.R')"
Rscript tests/run_json_loading_tests.R                       # standalone JSON loader tests
```

56+ test files including i18n enforcement (CI), module signature contracts, network analysis, JSON loading, integration, visual regression, and load tests.

### Code conventions

- Constants in `constants.R`, not scattered.
- `debug_log(msg, context)` for logging — never `cat()` or `print()`.
- All user-facing strings use `i18n$t()` keys.
- Module pattern: `module_name_ui(id, i18n)` + `module_name_server(id, project_data_reactive, i18n, event_bus = NULL, ...)`.
- Stable categorical keys for localized `selectInput`s — see ADR-11.

---

## Version history

| Version | Date | Highlights |
|---|---|---|
| **1.15.0** | 2026-05-17 | **8-component ML pipeline complete**: GraphSAGE GNN, BERT chunk classifier, LinUCB bandit, SVD collaborative filter; pilot-study instrumentation; in silico validation (recovery +100%, consistency +396%, ρ = 0.054 vs literature). |
| **1.14.0** | 2026-05-17 | Transformer text embeddings (sentence-transformer), similarity-guided transfer-learning fine-tuning, retrospective validation pipeline (precision@10 ≈ 0.057, ~7× random). |
| 1.13.x | 2026-05-17 | PIMS-style persistence pattern, stable categorical keys (locale-stable Power/Interest, Effectiveness/Feasibility), event-bus `isolate()`, deploy script hardening. |
| 1.12.x | 2026-05 | Project save/load fixes, workflow-stepper i18n keys, ESP 2026 abstract preparation. |
| 1.11.0 | 2026-04-08 | KB & template overhaul: 6 templates rebuilt from KB, Caribbean polarity/feedback, scientific review. |
| 1.10.x | 2026-03 | KB quality review: 68 reclassifications, 213 corrections, 1120 connections; test hardening (46 → 0 failures, 4094 passing). |
| 1.9.0 | 2026-03-16 | Connection delay attribute (temporal lag). |
| 1.8.x | 2026-03-15 | Codebase audit, KB validation, graphical builder, country governance. |
| 1.7.0 | 2026-03-14 | Security hardening, DTU integration, accessibility, Norwegian/Greek translations. |
| 1.5–1.6.x | 2025-11 to 2026-01 | Template system, AI ISA assistant, modular translations, Caribbean template. |

Full notes in [`CHANGELOG.md`](CHANGELOG.md).

---

## Research outputs

The MarineSABRES SES Toolbox is the technical backbone of an ESP 2026 abstract on AI-enhanced participatory SES modelling. Submission-ready materials (in the `MARBEFES/ESP2026/` companion folder, outside this repo):

- `abstract_Razinkovas_et_al_v3.md/.docx` — submission version (8 components + in silico numbers)
- `presentation_content_v3.md/.docx` — slide-by-slide deck content
- `presentation_numbers_quickref.md/.docx` — printable numbers cheat-sheet
- `demo_storyboard.md/.docx` — 5-minute live-demo storyboard
- `qa_prep.md/.docx` — anticipated questions by audience type

Numbers in those materials trace back to RDS outputs in `data/in_silico_*.rds` and the methods document in [`docs/ML_METHODS.md`](docs/ML_METHODS.md).

---

## Acknowledgments

Funded by the European Union's Horizon Europe research and innovation programme under:

- **Marine-SABRES** (Marine Systems Approaches for Biodiversity Resilient European Seas), Grant 101059482.
- **MARBEFES** (Marine Biodiversity and Ecosystem Functioning leading to Ecosystem Services), Grant 101060937.

Code development was assisted by several AI coding tools (Claude Code, GitHub Copilot).

<p align="center">
  <a href="https://marinesabres.eu/">
    <img src="www/img/01 marinesabres_logo_transparent.png" alt="Marine-SABRES" height="60">
  </a>
</p>

---

## Links

- **Repository:** [github.com/razinkele/SESTool](https://github.com/razinkele/SESTool)
- **Live app:** [laguna.ku.lt/marinesabres](https://laguna.ku.lt/marinesabres/)
- **Marine-SABRES project:** [marinesabres.eu](https://marinesabres.eu/)
- **Contact:** arturas.razinkovas-baziukas@ku.lt
