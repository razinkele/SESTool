# MarineSABRES SES Toolbox - Shiny Application

[![R Tests](https://github.com/YOUR_ORG/MarineSABRES_SES_Shiny/workflows/R%20Tests/badge.svg)](https://github.com/YOUR_ORG/MarineSABRES_SES_Shiny/actions)
[![Test Coverage](https://img.shields.io/badge/coverage-check%20CI-blue)](https://github.com/YOUR_ORG/MarineSABRES_SES_Shiny/actions)
[![R Version](https://img.shields.io/badge/R-%E2%89%A54.2-blue)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-check%20project-lightgrey)](LICENSE)

A comprehensive Shiny application for Social-Ecological Systems (SES) analysis and visualization, developed as part of the Marine-SABRES Horizon Europe project.

## Overview

The MarineSABRES SES Toolbox is an interactive web application that enables researchers, policymakers, and stakeholders to:

- **Create and manage SES frameworks** using the DAPSI(W)R(M) approach
- **Visualize complex relationships** through Causal Loop Diagrams (CLD)
- **Analyze system dynamics** with network analysis tools
- **Design response measures** and evaluate scenarios
- **Generate comprehensive reports** for decision-making

## Features

### 🎯 Core Functionality

- **Multi-language Support**: English, Spanish, French, and more (powered by shiny.i18n)
- **Template-based Creation**: Start quickly with pre-configured SES templates
- **AI-assisted Data Entry**: Intelligent suggestions for system elements
- **Interactive Visualizations**: Dynamic network diagrams with visNetwork
- **Comprehensive Analysis**: Network metrics, feedback loops, leverage points
- **Export Capabilities**: JSON, Excel, CSV, and PDF reports

### 🔬 Analysis Tools

- **Network Metrics**: Degree centrality, betweenness, closeness
- **Feedback Loop Detection**: Identify reinforcing and balancing loops
- **Leverage Point Analysis**: Find critical intervention points
- **Scenario Builder**: Test different response measures
- **BOT Analysis**: Boundaries of Tipping points

### 👥 Stakeholder Engagement

- **PIMS Framework**: Project Information Management System
- **User Experience Levels**: Beginner, Intermediate, Expert modes
- **Guided Workflows**: Step-by-step entry point system
- **Interactive Help**: Context-sensitive guidance

## Quick Start

### Prerequisites

- **R** ≥ 4.2
- **RStudio** (recommended)
- Required R packages (see Installation)

### Installation

```r
# Install required packages
install.packages(c(
  "shiny", "shinydashboard", "shinyWidgets", "shinyjs", "shinyBS",
  "tidyverse", "DT", "openxlsx", "jsonlite",
  "igraph", "visNetwork", "ggraph", "tidygraph",
  "ggplot2", "plotly", "dygraphs", "xts",
  "timevis", "rmarkdown", "htmlwidgets", "shiny.i18n",
  "R6"
))

# For testing (optional)
install.packages(c("testthat", "shinytest2", "covr"))
```

### Running the Application

```r
# From R console
shiny::runApp()

# Or from command line
Rscript -e "shiny::runApp()"
```

The application will open in your default web browser at `http://127.0.0.1:3838`

## Project Structure

```
MarineSABRES_SES_Shiny/
├── app.R                      # Main application file
├── global.R                   # Global environment and packages
├── constants.R                # Application constants
├── functions/                 # Core functionality
│   ├── data_structure.R      # Data structure management
│   ├── network_analysis.R    # Network analysis functions
│   ├── export_functions.R    # Export and reporting
│   └── ...
├── modules/                   # Shiny modules
│   ├── isa_data_entry_module.R
│   ├── cld_visualization_module.R
│   ├── analysis_tools_module.R
│   └── ...
├── server/                    # Server logic components
├── tests/                     # Testing framework
│   ├── testthat/             # Test suite
│   └── fixtures/             # Test data
├── translations/              # i18n translation files
├── data/                      # Template data
└── www/                       # Static assets (CSS, JS, images)
```

## Testing

The application includes a comprehensive testing framework:

- **348+ Unit Tests**: Individual function testing
- **Module Tests**: Shiny module validation
- **Integration Tests**: End-to-end workflows
- **E2E Tests**: Browser-based UI testing (shinytest2)
- **i18n Tests**: Translation compliance

### Running Tests

```r
# Run all tests
library(testthat)
test_dir("tests/testthat")

# Run specific test files
test_file("tests/testthat/test-data-structure.R")
test_file("tests/testthat/test-network-analysis.R")
test_file("tests/testthat/test-app-e2e.R")  # E2E tests (requires Chrome)

# Generate coverage report
source("tests/generate_coverage.R")
```

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Documentation

- **[Testing Guide](tests/README.md)**: Comprehensive testing documentation
- **[E2E Testing](tests/E2E_TESTING.md)**: Browser-based testing guide
- **[Translations](README_TRANSLATIONS.md)**: i18n system documentation
- **[Deployment](deployment/README.md)**: Deployment instructions

## Development

### Code Quality Standards

- **Coverage Threshold**: Minimum 70% test coverage required
- **Code Style**: Follow tidyverse style guide
- **Documentation**: Document all exported functions
- **Testing**: Write tests before/alongside code (TDD encouraged)

### Contributing

1. Create a feature branch
2. Write tests for new functionality
3. Ensure all tests pass
4. Update documentation
5. Submit pull request

### Git Workflow

```bash
git checkout -b feature/your-feature-name
# Make changes
git add .
git commit -m "Add feature description"
git push origin feature/your-feature-name
# Create pull request
```

## CI/CD

The project uses GitHub Actions for continuous integration:

- **Automated Testing**: Runs on every push/PR
- **Multi-platform**: Linux, macOS, Windows
- **Multiple R Versions**: 4.2, 4.3, 4.4
- **Coverage Tracking**: Automatic coverage report generation
- **E2E Testing**: Browser-based UI validation

See [.github/workflows/test.yml](.github/workflows/test.yml) for CI/CD configuration.

## Version History

### v1.5.2 (Current)
- ✅ Added comprehensive E2E testing with shinytest2
- ✅ Enhanced coverage tracking and reporting
- ✅ Fixed connection review module critical bugs
- ✅ Improved i18n enforcement testing

### v1.5.1
- Template-based SES creation
- AI-assisted ISA data entry
- Caribbean SES template

### v1.5.0
- Multi-language support (i18n)
- Enhanced CLD visualization
- Network analysis tools

## License

[Add license information]

## Acknowledgments

This project is developed as part of the **Marine-SABRES** (Marine Systems Approaches for Biodiversity Resilient European Seas) project, funded by the European Union's Horizon Europe research and innovation programme.

## Contact

For questions or support:
- Open an issue on GitHub
- Contact the Marine-SABRES development team
- See project website: [Add URL]

## Links

- **Project Repository**: [Add GitHub URL]
- **Documentation**: [Add docs URL]
- **Issue Tracker**: [Add issues URL]
- **Marine-SABRES Project**: [Add project URL]

---

**Note**: Update the badge URLs and repository links with your actual GitHub organization and repository name.
