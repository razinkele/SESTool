# Project File Index
## MarineSABRES SES Shiny Application

Complete listing of all files in the project with descriptions.

---

## Root Directory

| File | Description | Status |
|------|-------------|--------|
| `README.md` | Main project documentation and overview | ✓ Complete |
| `CHANGELOG.md` | Version history and release notes | ✓ Complete |
| `app.R` | Main Shiny application entry point | ✓ Complete |
| `global.R` | Global environment, packages, constants | ✓ Complete |
| `install_packages.R` | Automated package installation script | ✓ Complete |
| `run_app.R` | Quick launcher with options | ✓ Complete |
| `.gitignore` | Git version control ignore rules | ✓ Complete |

---

## `/modules/` - Shiny Modules

Modular UI and server components for different sections of the application.

| File | Description | Status |
|------|-------------|--------|
| `pims_module.R` | PIMS (Project & Information Management System) modules | ⚠ Partial |
| `isa_data_entry_module.R` | ISA data entry exercises (placeholder) | ⚠ Stub |
| `cld_visualization_module.R` | Main CLD visualization using visNetwork | ✓ Complete |
| `response_validation_module.R` | Response measures and validation (placeholder) | ⚠ Stub |

### Module Status Legend
- ✓ Complete: Fully implemented and functional
- ⚠ Partial: Core functionality present, needs expansion
- ⚠ Stub: Basic structure only, needs implementation

---

## `/functions/` - Helper Functions

Reusable functions for data manipulation, analysis, and export.

| File | Description | Status |
|------|-------------|--------|
| `data_structure.R` | Data models, validation, import/export | ✓ Complete |
| `network_analysis.R` | Network metrics, loop detection, simplification | ✓ Complete |
| `visnetwork_helpers.R` | visNetwork creation and manipulation utilities | ✓ Complete |
| `export_functions.R` | Export visualizations and generate reports | ✓ Complete |

### Key Functions by File

#### `data_structure.R`
- `create_empty_project()` - Initialize project structure
- `create_empty_element_df()` - Create element dataframes
- `validate_project_data()` - Validate complete project
- `import_project_rds()` / `export_project_rds()` - Save/load projects
- `import_isa_excel()` / `export_isa_excel()` - Excel import/export

#### `network_analysis.R`
- `calculate_network_metrics()` - All centrality metrics
- `find_all_cycles()` - Loop detection algorithm
- `classify_loop_type()` - R/B loop classification
- `calculate_micmac()` - Influence/exposure analysis
- `identify_exogenous_variables()` - Endogenization
- `identify_siso_variables()` - Encapsulation

#### `visnetwork_helpers.R`
- `create_nodes_df()` - Build nodes from ISA data
- `create_edges_df()` - Build edges from adjacency matrices
- `apply_standard_styling()` - Apply DAPSI(W)R(M) styling
- `apply_hierarchical_layout()` - Hierarchical positioning
- `filter_by_element_type()` - Network filtering

#### `export_functions.R`
- `export_cld_png()` - PNG export with webshot
- `export_cld_html()` - Interactive HTML export
- `export_project_excel()` - Complete data export
- `generate_executive_summary()` - R Markdown report

---

## `/data/` - Data Files

Example data and data templates.

| File | Description | Status |
|------|-------------|--------|
| `example_isa_data.R` | Complete example ISA dataset | ✓ Complete |

### Example Data Contents
- 3 Goods & Benefits elements
- 4 Ecosystem Services elements
- 4 Marine Processes & Functioning elements
- 4 Pressures elements
- 4 Activities elements
- 4 Drivers elements
- All 6 adjacency matrices populated
- Represents a seagrass restoration scenario

---

## `/www/` - Static Assets

CSS, images, and other static files for the web interface.

| File | Description | Status |
|------|-------------|--------|
| `custom.css` | Custom styling for the application | ✓ Complete |

### CSS Features
- DAPSI(W)R(M) element color coding
- Button hover effects
- Value box animations
- Table styling
- Form controls
- Responsive design elements
- Print-friendly styles

---

## `/docs/` - Documentation

Comprehensive documentation for users and developers.

| File | Description | Status |
|------|-------------|--------|
| `QUICK_START.md` | 5-minute getting started guide | ✓ Complete |
| `INSTALLATION.md` | Complete installation instructions | ✓ Complete |
| `framework_documentation.md` | Technical architecture and API | ✓ Complete |
| `user_guide.md` | Detailed user manual | ⚠ Planned |

### Documentation Contents

#### `QUICK_START.md`
- 5-step quick start
- Installation (2 min)
- First project creation
- Basic workflow
- Common tasks
- Example workflow

#### `INSTALLATION.md`
- Prerequisites (R, RStudio)
- Package installation (automatic & manual)
- Platform-specific instructions (Windows, macOS, Linux)
- Troubleshooting guide
- Deployment options
- Verification checklist

#### `framework_documentation.md`
- Architecture overview
- Data structure specifications
- visNetwork implementation details
- Network analysis algorithms
- Module system explanation
- Export system
- Extension guide
- Performance optimization

---

## Project Statistics

### Code Metrics
- **Total Files**: 20+
- **R Code Files**: 12
- **Documentation Files**: 5
- **Lines of Code**: ~8,000+
- **Functions**: 50+
- **Modules**: 4

### File Size Breakdown
| Category | Files | Approximate Size |
|----------|-------|-----------------|
| Core Application | 3 | ~2,500 lines |
| Modules | 4 | ~2,000 lines |
| Helper Functions | 4 | ~2,500 lines |
| Data | 1 | ~500 lines |
| Documentation | 5 | ~3,000 lines |
| Configuration | 3 | ~500 lines |

---

## Directory Tree

```
MarineSABRES_SES_Shiny/
│
├── README.md                          ✓ Main documentation
├── CHANGELOG.md                       ✓ Version history
├── app.R                              ✓ Main application
├── global.R                           ✓ Global environment
├── install_packages.R                 ✓ Package installer
├── run_app.R                          ✓ Quick launcher
├── .gitignore                         ✓ Git ignore rules
│
├── modules/                           Shiny modules
│   ├── pims_module.R                 ⚠ PIMS functionality
│   ├── isa_data_entry_module.R       ⚠ Data entry (stub)
│   ├── cld_visualization_module.R    ✓ CLD visualization
│   └── response_validation_module.R  ⚠ Responses (stub)
│
├── functions/                         Helper functions
│   ├── data_structure.R              ✓ Data models
│   ├── network_analysis.R            ✓ Network analysis
│   ├── visnetwork_helpers.R          ✓ visNetwork utils
│   └── export_functions.R            ✓ Export & reports
│
├── data/                              Data files
│   └── example_isa_data.R            ✓ Example dataset
│
├── www/                               Static assets
│   └── custom.css                    ✓ Custom styling
│
└── docs/                              Documentation
    ├── QUICK_START.md                ✓ Quick start guide
    ├── INSTALLATION.md               ✓ Installation guide
    ├── framework_documentation.md    ✓ Technical docs
    └── user_guide.md                 ⚠ Planned
```

---

## Quick Navigation Guide

### For Users

**Getting Started**:
1. Start with `README.md` for overview
2. Follow `docs/INSTALLATION.md` for setup
3. Use `docs/QUICK_START.md` for first use
4. Reference `docs/user_guide.md` for detailed instructions

**Running the Application**:
- Use `run_app.R` for easy launch
- Or directly: `shiny::runApp()`

### For Developers

**Understanding Architecture**:
1. Read `docs/framework_documentation.md`
2. Review `global.R` for constants and setup
3. Examine `app.R` for application structure
4. Study modules in `/modules/` directory

**Extending the Application**:
1. Add functions to appropriate `/functions/` file
2. Create new modules in `/modules/` directory
3. Update `global.R` if adding constants
4. Document changes in `CHANGELOG.md`

**Key Files to Modify**:
- **New visualization**: `modules/cld_visualization_module.R`
- **New analysis**: `functions/network_analysis.R`
- **New export format**: `functions/export_functions.R`
- **New styling**: `www/custom.css`

---

## Dependencies

### R Package Dependencies

**Core** (required):
- shiny, shinydashboard, shinyWidgets, shinyjs
- tidyverse (dplyr, tidyr, ggplot2, etc.)
- DT, openxlsx, jsonlite

**Network** (required):
- igraph, visNetwork, ggraph, tidygraph

**Visualization** (required):
- plotly, dygraphs, timevis

**Export** (optional but recommended):
- webshot (for PNG export)
- rmarkdown, knitr (for reports)

See `install_packages.R` for complete list and automated installation.

---

## Version Information

- **Current Version**: 1.0.0
- **Release Date**: 2024-10-19
- **R Version Required**: 4.0.0+
- **License**: [To be specified]
- **Maintained by**: IECS Ltd
- **Project**: EU Horizon Europe MarineSABRES

---

## Contributing

To contribute to the project:
1. Review `docs/framework_documentation.md` for architecture
2. Follow existing code style and conventions
3. Add tests for new functionality
4. Update documentation as needed
5. Update `CHANGELOG.md` with your changes

---

## Support and Contact

- **Email**: gemma.smith@iecs.ltd
- **Documentation**: See `/docs/` directory
- **Issues**: [Project Repository]
- **Project Website**: [MarineSABRES Website]

---

**File Index Version**: 1.0.0
**Last Updated**: 2024-10-19
