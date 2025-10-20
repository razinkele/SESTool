# Changelog
All notable changes to the MarineSABRES SES Shiny Application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- Full ISA data entry module with form validation
- Stakeholder power-interest grid with drag-and-drop
- Interactive BOT graph editor
- Scenario comparison tool
- AI-assisted analysis suggestions
- Real-time collaborative editing
- Mobile-responsive interface
- Integration with external modeling tools (Vensim, Stella)

---

## [1.0.0] - 2024-10-19

### Added

#### Core Framework
- Initial release of MarineSABRES SES Shiny Application
- Modular architecture with separation of UI and server logic
- Comprehensive data structure for ISA and PIMS data
- Project save/load functionality (RDS format)

#### PIMS Module
- Project setup and metadata management
- Stakeholder identification framework (placeholder UI)
- Risk management template
- Resource allocation tracking
- Data management plan template
- Process and outcome evaluation framework

#### ISA Data Entry
- Structured workflow through DAPSI(W)R(M) framework
- Data entry forms for all element types:
  - Goods & Benefits
  - Ecosystem Services
  - Marine Processes & Functioning
  - Pressures
  - Activities
  - Drivers
- Adjacency matrix system for defining connections
- BOT (Behavior Over Time) data structure
- Data validation functions

#### CLD Visualization (visNetwork)
- Interactive network visualization
- Multiple layout algorithms:
  - Hierarchical (DAPSI(W)R(M) levels)
  - Physics-based (Force Atlas 2)
  - Circular
  - Manual positioning
- Element filtering by type, polarity, and strength
- Search and highlight functionality
- Focus mode for neighborhood exploration
- Dynamic node sizing by network metrics
- Color-coded DAPSI(W)R(M) elements
- Interactive tooltips with element details

#### Network Analysis
- Automated feedback loop detection
- Loop classification (Reinforcing/Balancing)
- Centrality metrics calculation:
  - Degree (in/out/total)
  - Betweenness centrality
  - Closeness centrality
  - Eigenvector centrality
- MICMAC analysis framework
- Simplification tools:
  - Endogenization (exogenous variable removal)
  - Encapsulation (SISO variable bridging)

#### Export & Reporting
- CLD export formats:
  - PNG (via webshot)
  - HTML (interactive)
  - SVG (planned)
- Data export formats:
  - Excel workbook
  - CSV (zipped collection)
  - JSON
  - RDS (native R format)
- Report generation:
  - Executive summary (R Markdown)
  - Technical report (planned)
  - Stakeholder presentation (planned)

#### Documentation
- Comprehensive README
- Quick Start Guide (5-minute setup)
- Installation Guide (all platforms)
- Technical Framework Documentation
- User Guide (in progress)
- In-code documentation and comments

#### Example Data
- Complete example ISA dataset
- Pre-configured adjacency matrices
- Sample DAPSI(W)R(M) structure

### Technical Details
- **R Version**: Requires 4.0.0+
- **Key Dependencies**: 
  - shiny, shinydashboard, visNetwork, igraph
  - tidyverse, DT, plotly
  - rmarkdown, htmlwidgets
- **Lines of Code**: ~8,000+
- **Modules**: 4 main modules
- **Helper Functions**: 50+ utility functions

### Known Limitations
- ISA data entry modules are placeholder implementations
- PIMS modules (stakeholders, risks, resources) have basic UI only
- Response measures module not fully implemented
- Scenario builder is placeholder
- No authentication/user management
- Limited error handling in some areas
- Performance not optimized for very large networks (>1000 nodes)

---

## [0.9.0] - 2024-10-15 (Beta)

### Added
- Initial beta release for internal testing
- Basic CLD visualization with visNetwork
- Core data structures
- Project save/load functionality

### Fixed
- Loop detection algorithm optimization
- Memory leaks in network rendering
- Data validation issues

---

## [0.5.0] - 2024-10-01 (Alpha)

### Added
- Proof of concept implementation
- Basic Shiny UI framework
- Simple network visualization
- Manual data entry

---

## Version History Summary

| Version | Date | Status | Key Features |
|---------|------|--------|--------------|
| 1.0.0 | 2024-10-19 | Release | Full CLD visualization, Loop detection, Export |
| 0.9.0 | 2024-10-15 | Beta | Internal testing |
| 0.5.0 | 2024-10-01 | Alpha | Proof of concept |

---

## Upgrade Guide

### From 0.9.0 to 1.0.0
- Data structure is compatible, no migration needed
- New export formats available
- Enhanced loop detection algorithm
- Updated visNetwork styling

---

## Contributing

To report bugs or request features:
1. Check existing issues
2. Create detailed bug report with reproducible example
3. For features, describe use case and expected behavior

Contact: gemma.smith@iecs.ltd

---

## License

[Specify License - e.g., GPL-3, MIT, etc.]

---

**Maintained by**: IECS Ltd for the MarineSABRES Project
**Project**: EU Horizon Europe MarineSABRES
**Website**: [Project Website]
