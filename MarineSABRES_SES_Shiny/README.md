# MarineSABRES SES Shiny Application

## Computer-Assisted Social-Ecological Systems (SES) Analysis Tool

This R Shiny application digitizes and streamlines the Integrated Systems Analysis (ISA) process from the MarineSABRES project, providing an interactive interface for creating, analyzing, and visualizing Causal Loop Diagrams (CLDs) based on the DAPSI(W)R(M) framework.

## Features

### 1. PIMS Module (Process & Information Management System)
- Project initialization and definition
- Interactive stakeholder management with power-interest grid
- Risk and resource management tracking
- Data management planning
- Process and outcome evaluation

### 2. ISA Data Entry Module
- Guided workflow through DAPSI(W)R(M) framework:
  - **Exercise 0**: Unfolding complexity and impacts
  - **Exercise 1**: Goods & Benefits specification
  - **Exercise 2**: Ecosystem Services and Marine Processes & Functioning
  - **Exercise 3**: Pressures identification
  - **Exercise 4**: Activities mapping
  - **Exercise 5**: Drivers analysis
  - **Exercise 6-7**: Closing loops and CLD generation
- Real-time Behavior Over Time (BOT) graph generation
- Interactive adjacency matrix completion

### 3. Analysis & Visualization Module (using visNetwork)
- Interactive network visualization with:
  - Hierarchical, physics-based, circular, and manual layouts
  - Element type filtering
  - Search and highlight functionality
  - Focus mode for neighborhood exploration
  - Dynamic node sizing by network metrics
- Automated loop detection (reinforcing and balancing)
- Network analysis metrics:
  - Degree, betweenness, closeness centrality
  - Eigenvector centrality
  - MICMAC analysis
- Simplification tools (endogenization and encapsulation)

### 4. Response & Validation Module
- Response measure library
- Scenario building and "what-if" analysis
- Theory of change articulation
- Stakeholder presentation generator
- Validation questionnaire and feedback collection

## Installation

### Prerequisites

```r
# Install required R packages
install.packages(c(
  # Core Shiny
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "shinyjs",
  
  # Data management
  "DT",
  "tidyverse",
  "openxlsx",
  "jsonlite",
  
  # Network visualization and analysis
  "igraph",
  "visNetwork",
  "ggraph",
  "tidygraph",
  
  # Plotting
  "ggplot2",
  "plotly",
  "dygraphs",
  
  # Project management
  "timevis",
  
  # Export/Reporting
  "rmarkdown",
  "htmlwidgets",
  "webshot"
))

# For webshot (screenshot functionality)
webshot::install_phantomjs()
```

### Setup

1. Clone or download this repository
2. Open R/RStudio
3. Set working directory to the project folder:
   ```r
   setwd("path/to/MarineSABRES_SES_Shiny")
   ```
4. Run the application:
   ```r
   shiny::runApp()
   ```

## Project Structure

```
MarineSABRES_SES_Shiny/
├── app.R                          # Main application file
├── global.R                       # Global variables and package loading
├── README.md                      # This file
├── modules/
│   ├── pims_module.R             # PIMS module UI and server
│   ├── isa_data_entry_module.R   # ISA data entry module
│   ├── cld_visualization_module.R # CLD visualization with visNetwork
│   └── response_validation_module.R # Response and validation module
├── functions/
│   ├── data_structure.R          # Data structure definitions
│   ├── network_analysis.R        # Network metrics and loop detection
│   ├── visnetwork_helpers.R      # visNetwork helper functions
│   └── export_functions.R        # Export and reporting functions
├── data/
│   └── example_isa_data.R        # Example data structure
├── www/
│   └── custom.css                # Custom CSS styling
└── docs/
    ├── framework_documentation.md # Detailed technical documentation
    └── user_guide.md              # Step-by-step user guide
```

## Usage

### Quick Start

1. **Create a new project**: Navigate to the PIMS module and initialize your project with basic information
2. **Define stakeholders**: Add stakeholders and map them on the power-interest grid
3. **Enter ISA data**: Progress through Exercises 1-7, entering data for each DAPSI(W)R(M) element
4. **Visualize CLD**: The application automatically generates your Causal Loop Diagram
5. **Analyze**: Use the Analysis module to detect loops, calculate metrics, and identify leverage points
6. **Design responses**: Define response measures and test scenarios
7. **Export**: Generate reports and presentations for stakeholder validation

### Data Entry Workflow

The application guides you through a clockwise progression through the DAPSI(W)R(M) framework:

```
Impacts on Welfare (Goods & Benefits)
    ↑                           ↓
Drivers                  Ecosystem Services
    ↑                           ↓
Activities          Marine Processes & Functioning
    ↑                           ↓
    ←←←← Pressures ←←←←←←
```

### Visualization Options

- **Hierarchical Layout**: Shows clear DAPSI(W)R(M) levels (recommended for initial view)
- **Physics-based Layout**: Nodes arrange based on connection forces
- **Circular Layout**: All nodes arranged in a circle
- **Manual Layout**: Drag nodes to custom positions (saved)

### Network Analysis

- **Loop Detection**: Automatically identifies all feedback loops up to specified length
- **Centrality Metrics**: Identifies most influential nodes
- **Focus Mode**: Explore neighborhoods of specific nodes
- **Filtering**: Show/hide elements by type, polarity, or strength

## Data Format

The application uses a structured list format for ISA data:

```r
isa_data <- list(
  metadata = list(...),
  goods_benefits = data.frame(id, name, indicator, source, ...),
  ecosystem_services = data.frame(...),
  marine_processes = data.frame(...),
  pressures = data.frame(...),
  activities = data.frame(...),
  drivers = data.frame(...),
  adjacency_matrices = list(
    gb_es = matrix(...),
    es_mpf = matrix(...),
    # etc.
  )
)
```

See `data/example_isa_data.R` for complete structure.

## Export Options

- **Visualizations**: PNG, SVG, PDF, HTML
- **Data**: Excel, CSV, JSON
- **Reports**: HTML, PDF, Word documents
- **Full project**: Zipped archive with all components

## Advanced Features

### Scenario Comparison
Compare baseline and intervention scenarios side-by-side

### Loop Highlighting
Interactive highlighting of feedback loops

### Temporal Animation
Show CLD evolution over time periods

### MICMAC Analysis
Identify influential, relay, dependent, and autonomous elements

## Troubleshooting

### Application won't start
- Ensure all required packages are installed
- Check that working directory is set correctly
- Verify R version (requires R ≥ 4.0)

### Slow performance with large networks
- Use filtering to reduce visible elements
- Enable clustering for networks >500 nodes
- Consider simplification tools (endogenization/encapsulation)

### Export issues
- For PNG export: ensure phantomjs is installed (`webshot::install_phantomjs()`)
- For PDF export: may require additional LaTeX installation

## Citation

If you use this application in your research, please cite:

```
MarineSABRES Project (2024). MarineSABRES SES Shiny Application: 
Computer-Assisted Social-Ecological Systems Analysis Tool. 
Version 1.0. EU Horizon Europe Project.
```

## References

- Elliott, M., Borja, Á. & Cormier, R. (2020). Managing marine resources sustainably: A proposed Integrated Systems Analysis approach. Ocean & Coastal Management, 197.
- Elliott, M.D., Burdon, D., Atkins, J.P., et al. (2017). "And DPSIR begat DAPSI(W)R(M)!" - A unifying framework for marine environmental management. Marine Pollution Bulletin, 118(1-2), 27-40.

## License

[Specify license - e.g., MIT, GPL-3, etc.]

## Contact

For questions, issues, or contributions:
- Email: gemma.smith@iecs.ltd
- Project website: [MarineSABRES website]

## Acknowledgments

This application was developed as part of the MarineSABRES project, funded by the EU Horizon Europe programme.

## Version History

### Version 1.0 (2024)
- Initial release
- Core PIMS functionality
- ISA data entry (Exercises 0-7)
- visNetwork-based visualization
- Loop detection and network analysis
- Export functionality

### Planned Features (Future Versions)
- AI-assisted analysis and pattern recognition
- Real-time collaborative editing
- Integration with external modeling tools (Vensim, Stella)
- Mobile-responsive interface
- Advanced scenario modeling with uncertainty analysis
