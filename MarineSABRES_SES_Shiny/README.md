# MarineSABRES SES Toolbox

[![R Version](https://img.shields.io/badge/R-%E2%89%A54.4.1-blue)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-EU%20Horizon%20Europe-lightgrey)](LICENSE)

A comprehensive Shiny application for Social-Ecological Systems (SES) analysis and visualization, developed as part of the [Marine-SABRES](https://marinesabres.eu/) Horizon Europe project.

**Live deployment**: [laguna.ku.lt:3838/marinesabres](http://laguna.ku.lt:3838/marinesabres/)

## Overview

The MarineSABRES SES Toolbox enables researchers, policymakers, and stakeholders to model and analyze marine social-ecological systems using the **DAPSI(W)R(M)** framework (Drivers, Activities, Pressures, State changes, Impacts on human Welfare, Responses as Measures).

Key capabilities:

- **Build SES models** from scratch or pre-configured templates (Fisheries, Tourism, Aquaculture, Pollution, Climate Change, Caribbean, Offshore Wind)
- **Visualize causal relationships** through interactive Causal Loop Diagrams (CLD)
- **Analyze system dynamics** — network metrics, feedback loops, leverage points, Boolean stability
- **Design response measures** and evaluate intervention scenarios
- **Generate reports** in HTML, Word, PowerPoint, and PDF formats
- **9-language support**: English, Spanish, French, German, Lithuanian, Portuguese, Italian, Norwegian, Greek

## Features

### Core Workflow

- **Template-based creation** — 7 pre-built SES templates for common marine contexts
- **ISA Data Entry** — structured input for all DAPSI(W)R(M) elements with connection matrices
- **AI-assisted classification** — intelligent suggestions for element categorization
- **Connection review** — tabbed interface for reviewing and approving element relationships
- **CLD Visualization** — interactive network diagrams powered by visNetwork/igraph

### Analysis Tools

| Tool | Description | Export |
|------|-------------|--------|
| **Network Metrics** | Degree, betweenness, closeness, eigenvector centrality, PageRank | Excel, PNG |
| **Feedback Loops** | Detect and classify reinforcing/balancing loops with dominance analysis | Excel, Word, ZIP |
| **Leverage Points** | Composite scoring to identify key intervention nodes | Excel, PNG |
| **Boolean Stability** | Attractor analysis for system state stability | CSV |
| **BOT Analysis** | Boundaries of Tipping points | CSV |
| **Scenario Builder** | Test response measures and evaluate outcomes | — |
| **Network Simplification** | Reduce complexity while preserving key dynamics | — |
| **Intervention Analysis** | Model targeted interventions on specific nodes | — |

### Stakeholder Engagement

- **PIMS Framework** — Project Information Management System for stakeholder tracking
- **Guided workflows** — step-by-step entry point system with workflow stepper
- **User experience levels** — Beginner, Intermediate, Expert modes
- **Context-sensitive help** — modal-based guidance throughout the application

### Internationalization

34 modular JSON translation files organized into `common/`, `modules/`, `ui/`, and `data/` subdirectories. Powered by `shiny.i18n` with session-local language to prevent cross-user bleeding.

## Quick Start

### Prerequisites

- **R** >= 4.4.1
- **RStudio** (recommended) or any R environment

### Installation

```r
# Core packages
install.packages(c(
  "shiny", "bs4Dash", "shinyWidgets", "shinyjs", "shinyBS",
  "shiny.i18n", "DT", "jsonlite", "openxlsx", "readxl",
  "igraph", "visNetwork", "ggplot2", "plotly",
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "htmltools", "htmlwidgets", "rmarkdown", "knitr",
  "officer", "flextable", "tinytex"
))

# Install TinyTeX for PDF export
tinytex::install_tinytex()
```

### Running the Application

```r
shiny::runApp()
```

The application opens at `http://127.0.0.1:3838`.

## Project Structure

```
MarineSABRES_SES_Shiny/
├── app.R                       # Main entry point, bs4DashPage UI
├── global.R                    # Package loading, source() calls, startup
├── constants.R                 # 280+ constants, single source of truth
├── io.R                        # File I/O utilities
├── utils.R                     # Core utility functions
├── VERSION                     # Current version (1.6.1)
├── VERSION_INFO.json           # Detailed version metadata
│
├── modules/                    # 33 Shiny modules
│   ├── isa_data_entry_module.R       # ISA data entry with matrices
│   ├── cld_visualization_module.R    # CLD network visualization
│   ├── analysis_metrics.R           # Network centrality metrics
│   ├── analysis_loops.R            # Feedback loop detection
│   ├── analysis_leverage.R         # Leverage point analysis
│   ├── analysis_boolean.R          # Boolean stability analysis
│   ├── analysis_bot.R              # BOT analysis
│   ├── analysis_simulation.R       # System simulation
│   ├── export_reports_module.R     # Report generation
│   ├── scenario_builder_module.R   # Scenario evaluation
│   └── ...                         # 23 more modules
│
├── functions/                  # 32 utility/helper files
│   ├── data_structure.R            # Data model management
│   ├── network_analysis.R          # igraph-based analysis
│   ├── export_functions.R          # Export formatting
│   └── ...
│
├── server/                     # 5 extracted server handlers
│   ├── dashboard.R                 # Dashboard rendering
│   ├── export_handlers.R           # Download handlers
│   ├── modals.R                    # Modal dialogs
│   ├── project_io.R                # Project save/load
│   └── bookmarking.R               # URL bookmarking
│
├── translations/               # 34 modular JSON files, 9 languages
│   ├── common/                     # Shared keys (messages, validation, labels)
│   ├── modules/                    # Module-specific keys
│   ├── ui/                         # UI chrome keys
│   └── data/                       # Data-related keys
│
├── data/                       # 7 SES template JSON files
├── config/                     # App configuration
├── www/                        # Static assets (CSS, JS, images)
├── deployment/                 # Deployment scripts and docs
├── tests/                      # Test framework
└── SESModels/                  # Pre-built Excel SES models
```

## Deployment

The application deploys to a Shiny Server instance via `tar` + `scp` + `ssh` using native tools (no WSL or rsync required).

```powershell
# Windows (PowerShell)
.\deployment\deploy-remote.ps1 -DryRun    # Preview
.\deployment\deploy-remote.ps1             # Deploy

# Linux/Mac
bash deployment/remote-deploy.sh --dry-run
bash deployment/remote-deploy.sh
```

**Target**: `razinka@laguna.ku.lt:/srv/shiny-server/marinesabres/` (ownership `razinka:shiny`)

Pre-deployment validation:
```r
Rscript deployment/pre-deploy-check-remote.R
```

Post-deployment validation:
```bash
sudo ./deployment/validate-deployment.sh
```

Docker is also supported:
```bash
docker build -f deployment/Dockerfile -t marinesabres .
docker run -p 3838:3838 marinesabres
```

See [deployment/REMOTE_DEPLOYMENT_README.md](deployment/REMOTE_DEPLOYMENT_README.md) for full instructions.

## Development

### Code Conventions

- Constants in `constants.R`, not scattered across files
- `debug_log(msg, context)` for logging (not `cat()` or `print()`)
- `*_safe()` wrapper functions add NULL checks before calling core functions
- Session-local i18n via `shiny.i18n` to prevent cross-user language bleeding
- Matrix naming: SOURCE x TARGET convention (`d_a`, `a_p`, `p_mpf`, `mpf_es`, `es_gb`, `gb_d`)
- All user-facing strings use `i18n$t()` keys

### Contributing

1. Create a feature branch from `main`
2. Make changes following the conventions above
3. Validate R syntax: `Rscript -e "parse('your_file.R')"`
4. Validate JSON: ensure all translation files are valid JSON
5. Run pre-deploy check: `Rscript deployment/pre-deploy-check-remote.R`
6. Submit a pull request

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

| Version | Date | Highlights |
|---------|------|------------|
| **1.6.1** | 2026-01-06 | Stability fixes, constants consolidation, i18n completion |
| 1.6.0 | 2025-12 | Modular translations, AI ISA assistant, deployment framework |
| 1.5.x | 2025-11 | Template system, Caribbean template, multi-language support |

## Acknowledgments

This project is developed as part of **Marine-SABRES** (Marine Systems Approaches for Biodiversity Resilient European Seas), funded by the European Union's Horizon Europe research and innovation programme under Grant Agreement No. 101136352.

## Links

- **Repository**: [github.com/razinkele/SESTool](https://github.com/razinkele/SESTool)
- **Marine-SABRES Project**: [marinesabres.eu](https://marinesabres.eu/)
