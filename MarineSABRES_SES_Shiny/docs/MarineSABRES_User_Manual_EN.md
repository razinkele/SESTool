---
title: "MarineSABRES SES Toolbox - User Manual"
subtitle: "Social-Ecological Systems Analysis Platform"
author: "MarineSABRES Project"
date: "Version 1.10.0 - March 2026"
lang: en
toc: true
toc-depth: 3
numbersections: true
geometry: margin=2.5cm
fontsize: 11pt
documentclass: article
papersize: a4
---

\newpage

# Introduction

## About MarineSABRES SES Toolbox

The **MarineSABRES Social-Ecological Systems (SES) Toolbox** is a comprehensive web-based application designed to support participatory analysis and management of marine social-ecological systems. It implements the **DAPSI(W)R(M) framework** (Drivers-Activities-Pressures-State changes-Welfare impacts-Response Measures) to analyze complex interactions between marine ecosystems and human activities.

> **Note on Framework Terminology:** In DAPSI(W)R(M), "R" and "M" refer to policy/management Responses and implementing Measures. This tool treats them as a unified "Response Measures" category to represent management interventions comprehensively.

### Key Capabilities

- **Integrated Systems Analysis (ISA)**: Structured 13-exercise approach to map cause-effect relationships
- **AI-Assisted Creation**: Conversational interface for rapid system mapping
- **Interactive Visualization**: Dynamic Causal Loop Diagrams (CLD) with advanced network layouts
- **Feedback Loop Detection**: Automatic identification of reinforcing and balancing loops
- **Network Analysis**: Centrality metrics, leverage points, and MICMAC analysis
- **Response Planning**: Prioritization and impact assessment of management interventions
- **Stakeholder Management**: Power-Interest analysis and engagement planning
- **Context-Specific Recommendations**: Data-driven strategic and management guidance
- **Multilingual Support**: Available in 9 languages (EN, ES, FR, DE, LT, PT, IT, NO, EL)
- **Temporal Delay Attributes**: Capture time-lag relationships between connections
- **Knowledge Base**: 1,120 scientifically validated connections across 30 marine ecosystem contexts
- **Country Governance**: 97 countries with governance and socio-economic element suggestions
- **Template System**: 7 pre-built SES templates for common marine scenarios

## Target Users

- **Marine Resource Managers**: Plan and evaluate management interventions
- **Policy Analysts**: Assess policy impacts on marine systems
- **Environmental Consultants**: Support marine spatial planning and impact assessments
- **Researchers**: Study marine social-ecological system dynamics
- **Stakeholder Facilitators**: Guide participatory system mapping workshops

## System Requirements

### Software Requirements
- **R** version 4.4.1 or higher
- **Modern Web Browser**: Chrome (recommended), Firefox, Edge, or Safari
- **Optional**: Pandoc (for PDF/Word report generation)

### Hardware Requirements
- **Processor**: Dual-core 2.0 GHz or faster
- **RAM**: 4 GB minimum, 8 GB recommended
- **Storage**: 500 MB free disk space
- **Display**: 1366x768 minimum resolution, 1920x1080 recommended

### Internet Connection
- Required for initial R package installation only
- Offline operation supported after installation

\newpage

# What's New

## Version 1.10.0 (March 2026)

### Knowledge Base Quality Review & Scientific Validation
- 68 element misclassifications corrected across the DAPSI(W)R(M) knowledge base
- 213 connection attributes scientifically validated against published literature (HELCOM, ICES, OSPAR, UNEP-MAP, GCRMN, IPCC AR6, AMAP)
- 1,120 total connections across 30 marine ecosystem contexts (up from 622)
- Zero orphan elements — every element connected to at least one other
- Confidence distribution recalibrated to evidence-based levels
- KB References accessible from Help menu in the topbar

### Governance & Socio-Economic Enhancements
- 2 new regional conventions: SPREP/Noumea (Pacific) and Abidjan (West Africa)
- Governance gaps filled for 4 groups (non-EU European, Latin American, African Coastal, Asia-Pacific)
- 16 governance/SE element reclassifications for accuracy

### Connection Review Improvements
- New W→D, P→P, and S→S connection batch tabs for feedback loops and cascading effects
- Delay toggle persistence across tab changes
- Internationalized strength/confidence labels and tooltips

## Version 1.9.0 (March 2026)

### Temporal Delay Attributes
- Delay categories for connections: immediate, short-term, medium-term, long-term
- Visual dash patterns on network edges showing delay
- Connection review cards with delay toggle, dropdown, and numeric input
- Full Excel/Kumu import and export support for delay columns
- Backward-compatible with older project files

## Version 1.8.1 (March 2026)

### Codebase Audit & Cleanup
- 12 critical bug fixes across 20 files
- Dead code removal and test strengthening

## Version 1.8.0 (March 2026)

### Knowledge Base & Country Governance
- Country governance database with 97 countries across 11 regional seas
- Graphical SES network builder module
- Tutorial system with guided walkthroughs
- Universal Excel loader for flexible SES model import
- ML model registry and text embeddings infrastructure

\newpage

# Getting Started

## Installation

### Step 1: Install R and RStudio

1. **Download R** from [https://cran.r-project.org/](https://cran.r-project.org/)
2. **Download RStudio** (optional but recommended) from [https://posit.co/downloads/](https://posit.co/downloads/)
3. Install both applications following standard procedures

### Step 2: Install Required Packages

Open R or RStudio and run:

```r
# Install required packages
install.packages(c(
  "shiny", "shinydashboard", "shinyjs", "shiny.i18n",
  "DT", "dplyr", "tidyr", "ggplot2", "plotly",
  "visNetwork", "igraph", "DiagrammeR",
  "openxlsx", "jsonlite", "rmarkdown", "knitr",
  "digest", "htmlwidgets"
))
```

### Step 3: Launch the Application

```r
# Set working directory
setwd("/path/to/MarineSABRES_SES_Shiny")

# Run the application
shiny::runApp()
```

**Alternative using run_app.R:**

```bash
cd /path/to/MarineSABRES_SES_Shiny
Rscript run_app.R
```

## First Launch

### Interface Overview

Upon launching, you'll see the **Dashboard** with:

**Header Bar:**
- Application title and logo
- Language selector (9 languages available)
- User level selector (Beginner/Intermediate/Expert)
- Help button

**Sidebar Menu:**
- Navigation to all modules
- Save/Load project buttons
- Auto-save indicator

**Main Panel:**
- Summary value boxes (elements, connections, loops, completion %)
- Project status overview
- Quick action buttons

### Creating Your First Project

1. **Navigate to Entry Point** (Getting Started)
   - Choose "Guided Pathway" or "Quick Access"
   - Answer contextual questions about your role and objectives
   - Receive personalized tool recommendations

2. **Set Up Project Information** (PIMS → Project Setup)
   - Enter project name
   - Select demonstration area
   - Define focal issue
   - Specify system boundaries

3. **Choose Your Workflow**
   - **Standard ISA**: Structured 13-exercise approach (recommended for thorough analysis)
   - **AI-Assisted**: Conversational 11-step interview (fast track for experienced users)
   - **Template-Based**: Pre-configured models for common scenarios
   - **Import Data**: Load existing ISA data from Excel

4. **Save Your Work**
   - Click "Save Project" in sidebar
   - Choose filename (e.g., `my_project_2025-11-16.rds`)
   - Save regularly throughout your session

\newpage

# Core Modules

## PIMS (Project Information Management System)

### Project Setup

Define the scope and context of your analysis.

**Fields to Complete:**

- **Project Name**: Unique identifier for your project
- **Project ID**: Auto-generated or custom code
- **Demonstration Area**: Geographic focus
  - Tuscan Archipelago
  - Arctic NE Atlantic
  - Macaronesia
  - Custom (specify)

- **Focal Issue**: Primary management question or concern
- **Temporal Scale**: Time horizon (years/decades/centuries)
- **Spatial Scale**: Geographic extent (local/regional/national/international)
- **System Boundaries**: What's included/excluded from analysis

**Best Practices:**
- Be specific about focal issue (e.g., "Decline in seagrass meadows due to nutrient pollution" vs. "Water quality")
- Define boundaries clearly to scope your analysis
- Consider multiple temporal scales for different system components

### Stakeholder Management

Identify and categorize stakeholders in your marine system.

**Stakeholder Register:**

Create entries with:
- **Name**: Organization or group name
- **Type**:
  - Inputters (provide resources/inputs)
  - Extractors (harvest/remove resources)
  - Regulators (set rules/policies)
  - Affectees (experience impacts)
  - Beneficiaries (receive benefits)
  - Influencers (shape decisions)
- **Contact Information**: Email, phone, address
- **Power**: Influence level (High/Medium/Low)
- **Interest**: Stake in outcomes (High/Medium/Low)
- **Engagement Level**: Current participation (IAP2 spectrum)
  - Inform
  - Consult
  - Involve
  - Collaborate
  - Empower
- **Notes**: Additional context

**Power-Interest Grid:**

Visual matrix automatically plots stakeholders by power and interest:
- **High Power, High Interest**: Key players - collaborate closely
- **High Power, Low Interest**: Keep satisfied - regular updates
- **Low Power, High Interest**: Keep informed - engage actively
- **Low Power, Low Interest**: Monitor - minimum effort

**Export:** Download stakeholder register as Excel for external sharing

\newpage

## Create SES (Social-Ecological System)

### Method 1: Standard ISA Data Entry

Comprehensive 13-exercise structured approach following DAPSI(W)R(M) framework.

#### Exercise 0: Complexity Scoping

Establish the context for your analysis.

**Key Questions:**
1. What is the case study area?
2. What is the geographic and temporal scope?
3. What welfare impacts are of concern?
4. Who are the key stakeholders?

**Output:** Contextual foundation for subsequent exercises

#### Exercise 1: Goods & Benefits (G&B)

Identify valued outputs from the marine system.

**Data Entry Form:**
- **ID**: Auto-generated unique identifier
- **Name**: Descriptive name (e.g., "Commercial fish catch")
- **Type**:
  - Provisioning (food, materials)
  - Regulating (climate, water quality)
  - Cultural (recreation, heritage)
  - Supporting (nutrient cycling, habitat)
- **Description**: Detailed explanation
- **Stakeholder**: Who benefits?
- **Importance**: Socio-economic significance (High/Medium/Low)
- **Trend**: Historical trajectory (Increasing/Stable/Decreasing/Unknown)

**Interactive Table:**
- Add, edit, delete entries
- Sort and filter by any column
- Search functionality
- Export to Excel

**Example Entries:**
```
Name: Recreational fishing opportunities
Type: Cultural
Stakeholder: Local fishing community, tourists
Importance: High
Trend: Decreasing
```

#### Exercise 2a: Ecosystem Services (ES)

Map services that support goods and benefits.

**Fields:**
- **Name**: Service description (e.g., "Fish stock replenishment")
- **Type**: Provisioning/Regulating/Cultural/Supporting
- **Linked G&B**: Select which goods/benefits this service supports
- **Mechanism**: How the service provides the benefit
- **Confidence**: Evidence quality (High/Medium/Low)

**Adjacency Matrix:**
- Rows: Ecosystem Services
- Columns: Goods & Benefits
- Cells: Relationship strength
  - `+strong`, `+medium`, `+weak` (positive contributions)
  - Empty (no relationship)

#### Exercise 2b: Marine Processes & Functioning (MPF)

Identify ecological processes that enable services.

**Additional Fields:**
- **Process Type**: Biological/Chemical/Physical
- **Sensitivity**: Vulnerability to change (High/Medium/Low)
- **Spatial Scale**: Geographic extent (m²/km²/regional)

**Examples:**
- Biological: "Seagrass photosynthesis"
- Chemical: "Nutrient uptake by macroalgae"
- Physical: "Sediment stabilization by roots"

#### Exercise 3: Pressures (P)

Document stressors affecting marine processes.

**Pressure Categories (aligned with MSFD):**
- Physical: Smothering, abrasion, habitat loss
- Chemical: Contaminants, nutrients, acidification
- Biological: Introduction of species, pathogens
- Other: Noise, light, electromagnetic fields

**Fields:**
- **Intensity**: Magnitude of pressure (High/Medium/Low/Unknown)
- **Spatial Pattern**: Point source/Diffuse/Regional
- **Temporal Pattern**: Continuous/Seasonal/Episodic/Permanent

#### Exercise 4: Activities (A)

Identify human actions that generate pressures.

**Activity Sectors:**
- Fisheries (Commercial/Recreational)
- Aquaculture
- Tourism and Recreation
- Shipping and Navigation
- Energy Production
- Coastal Development
- Agriculture and Forestry
- Industry and Mining
- Waste Disposal
- Research and Monitoring

**Fields:**
- **Scale**: Operational extent (Local/Regional/National/International)
- **Frequency**: How often (Daily/Weekly/Seasonal/Annual/Irregular)

#### Exercise 5: Drivers (D)

Analyze root causes behind activities.

**Driver Types:**
- **Economic**: Market demand, prices, subsidies, trade
- **Social**: Population, demographics, lifestyle, traditions
- **Technological**: Innovation, efficiency, capacity
- **Environmental**: Climate, resources availability
- **Policy/Institutional**: Regulations, governance, property rights

**Fields:**
- **Trend**: Direction of change (Increasing/Stable/Decreasing/Cyclical)
- **Controllability**: Can it be managed? (High/Medium/Low/None)

#### Exercise 6: Loop Closure (Feedback)

Complete the causal chain with responses from welfare back to drivers.

**Feedback Connections:**
- Select G&B (starting point)
- Select Driver (endpoint)
- Specify:
  - **Effect Type**: Positive (amplifying) / Negative (dampening)
  - **Strength**: Strong/Medium/Weak
  - **Confidence**: High/Medium/Low
  - **Mechanism**: Explanatory pathway

**Example:**
```
G&B: "Declining fish catch" →
Driver: "Market demand for fish"
Effect: Negative (reduced demand as less fish available)
Strength: Medium
Delay: short-term
Mechanism: "Lower catches reduce market supply, potentially
           decreasing consumer demand for locally caught fish"
```

**Temporal Delay Attributes:**

Each connection can optionally include a delay attribute to capture time-lag relationships:

- **Immediate**: Effect occurs within days
- **Short-term**: Effect occurs within weeks to months
- **Medium-term**: Effect occurs within months to a year
- **Long-term**: Effect occurs over years

Delay values are shown as dash patterns on CLD edges and can be toggled on connection review cards. Delay columns are preserved during Excel and Kumu import/export.

#### Exercise 7-9: CLD Creation

**Exercise 7**: Review all elements and connections (including delay attributes and new W→D, P→P, S→S batch tabs for feedback loops)
**Exercise 8**: Generate Causal Loop Diagram
**Exercise 9**: Export to visualization platforms (Kumu.io)

**Automatic Features:**
- Element compilation from all exercises
- Adjacency matrix conversion to edges
- DAPSI(W)R(M) color coding
- Kumu-compatible JSON export

#### Exercise 10-12: Analysis & Documentation

**Exercise 10**: System dynamics analysis
**Exercise 11**: Behavior Over Time (BOT) graphs
**Exercise 12**: Validation documentation

**BOT Graph Features:**
- Time series data entry
- Multiple indicators on same plot
- Trend lines and annotations
- Export as PNG/PDF

#### Data Management Tab

**Import from Excel:**
1. Download template (button provided)
2. Fill template with your data
3. Upload completed Excel file
4. Review import preview
5. Confirm import (merge or replace existing data)

**Export to Excel:**
- Multi-sheet workbook
- All ISA tables included
- Adjacency matrices
- Connection attributes including Delay columns (has_delay, delay_type, delay_value, delay_units)
- Ready for external analysis

**Clear All Data:**
- Reset entire ISA dataset
- Confirmation required
- Cannot be undone

\newpage

### Method 2: AI-Assisted ISA Creation

Conversational step-by-step guidance for rapid system mapping.

**11-Step Interview Process:**

**Step 1: Introduction**
- Welcome and overview
- Explanation of process
- Estimated time: 30-60 minutes

**Step 2: Project Context**
- Project name and description
- Primary objectives
- Expected outcomes

**Step 3: Regional Sea Selection**
Choose from 13 regional seas:
- Baltic Sea
- Mediterranean Sea
- Black Sea
- Northeast Atlantic
- Arctic Ocean
- And 8 others...

**Step 4: Ecosystem Type**
12 ecosystem categories:
- Seagrass meadows
- Coral reefs
- Kelp forests
- Rocky reefs
- Sandy beaches
- Mudflats
- Estuaries
- Deep sea
- And 4 others...

**Step 5: Ecosystem Subtype**
Context-specific refinement based on Step 4 selection

**Step 6: Main Issues**
Select from 25+ pre-defined issues or specify custom:
- Overfishing
- Pollution (nutrients, plastics, chemicals)
- Habitat degradation
- Climate change impacts
- Invasive species
- Coastal development
- Tourism pressure
- And many others...

**Steps 7-11: Element Definition**
For each DAPSI(W)R(M) level:
- Pre-populated suggestions based on your context
- Free-text entry option
- Multiple elements can be added
- Real-time preview of created elements

**Session Features:**
- **Auto-save**: Progress saved to browser localStorage
- **Session Recovery**: Resume if interrupted
- **Chat Interface**: Conversational prompts
- **Context-Aware**: Suggestions adapt to previous answers
- **Direct Integration**: Saves to main project data

**When to Use:**
- Time-limited projects (rapid assessment)
- Initial scoping phase
- Experienced users familiar with DAPSI(W)R(M)
- When expert knowledge can fill gaps quickly

**Advantages:**
- Faster than standard ISA (10x speed improvement)
- Context-aware suggestions reduce errors
- Natural conversation flow
- Immediate results

**Limitations:**
- Less detailed than standard ISA
- May miss complex relationships
- Requires user expertise to evaluate suggestions

\newpage

### Method 3: Template-Based SES Creation

Quick start with pre-configured models for common scenarios.

**Available Templates:**
- Baltic Sea Fisheries
- Mediterranean Tourism
- Atlantic Aquaculture
- Arctic Shipping
- (More templates in development)

**How to Use:**
1. Select template from dropdown
2. Review pre-populated elements
3. Customize to your specific context
4. Add/remove/modify elements as needed
5. Proceed to analysis

**When to Use:**
- Similar case to existing template
- Teaching and training scenarios
- Benchmarking against known systems
- Rapid prototyping

### Method 4: Import Data from Excel

Load existing ISA data from spreadsheet.

**Process:**
1. Download Excel template
2. Complete all required sheets:
   - Goods_Benefits
   - Ecosystem_Services
   - Marine_Processes
   - Pressures
   - Activities
   - Drivers
   - (Adjacency matrices sheets)
3. Upload filled template
4. Review validation report
5. Confirm import

**Data Validation:**
- Column name checking
- Data type verification
- Required field validation
- Relationship integrity
- Delay columns recognized automatically (backward-compatible with older files without Delay columns)

**Import Options:**
- **Merge**: Add to existing data
- **Replace**: Overwrite all data

\newpage

## CLD Visualization

Interactive network visualization of your social-ecological system.

### Network Display

**Visual Encoding:**

**Node Colors (DAPSI(W)R(M) levels):**
- Purple: Drivers
- Green: Activities
- Orange: Pressures
- Light Blue: Marine Processes
- Dark Blue: Ecosystem Services
- Light Yellow: Goods & Benefits

**Node Shapes:**
- Star: Drivers
- Hexagon: Activities
- Diamond: Pressures
- Dot: Marine Processes
- Square: Ecosystem Services
- Triangle: Goods & Benefits

**Edge Colors:**
- Light Blue: Positive/reinforcing connections
- Red: Negative/opposing connections

**Edge Styles:**
- Solid line: Direct causal link
- Line thickness: Relationship strength (strong/medium/weak)

### Layout Algorithms

**1. Hierarchical Layout (Recommended)**
- **Direction**: Down-Up (shows DAPSI flow), Up-Down, Left-Right, Right-Left
- **Level Separation**: Adjust spacing (50-300px)
- **Best for**: Understanding DAPSI structure, presentations

**2. Physics-Based (Force Atlas 2)**
- **Gravity**: Attraction strength between connected nodes
- **Spring Length**: Ideal edge length
- **Best for**: Discovering clusters, identifying central nodes

**3. Circular Layout**
- Nodes arranged in circle
- **Best for**: Small networks, pattern recognition

**4. Manual Positioning**
- Drag nodes to desired positions
- Positions saved with project
- **Best for**: Custom arrangements, final presentations

### Interactive Controls

**Navigation:**
- **Zoom**: Mouse wheel or pinch gesture
- **Pan**: Click and drag background
- **Reset View**: Button to restore initial view
- **Fit to Screen**: Auto-zoom to show all nodes

**Node Interactions:**
- **Click**: Select node (highlights neighbors)
- **Double-click**: Center view on node
- **Hover**: Show tooltip with details

**Edge Interactions:**
- **Hover**: Show relationship details
- **Click**: Highlight connection

**Search:**
- Type node name to find and highlight
- Dropdown list of all nodes
- Auto-center on selected node

### Highlighting Features

**Leverage Points:**
- Highlight high-influence nodes
- Based on centrality metrics
- Toggle on/off

**Loop Highlighting:**
- Select loop from dropdown
- All nodes and edges in loop highlighted
- Other elements faded
- Useful for loop-specific discussions

**Interactive Legend:**
- Shows color/shape coding
- Clickable to filter display
- Toggle element types on/off

### Export Options

**PNG Export:**
- High-resolution raster image (150 dpi)
- Custom dimensions (400-4000px)
- Transparent background option
- **Use for**: Reports, presentations, publications

**SVG Export:**
- Scalable vector graphics
- Editable in Illustrator, Inkscape
- No quality loss at any size
- **Use for**: Professional publications, posters

**HTML Export:**
- Fully interactive standalone file
- Share with stakeholders
- No server required
- **Use for**: Stakeholder sharing, web embedding

**PDF Export:**
- Print-ready document
- Requires Pandoc installation
- **Use for**: Formal reports, archiving

\newpage

## Analysis Tools

### Loop Detection

Identify feedback loops in your system automatically.

**How Feedback Loops Work:**

- **Reinforcing Loops (R)**: Amplify change (even number of negative links)
  - Example: More fish → More fishing effort → Fewer fish → Less fishing effort → More fish
  - Leads to exponential growth or decline

- **Balancing Loops (B)**: Stabilize system (odd number of negative links)
  - Example: Overfishing → Depleted stocks → Regulations → Reduced fishing → Stock recovery
  - Leads to equilibrium or oscillation

**Detection Parameters:**

- **Maximum Loop Length**: 3-15 elements (default: 8)
  - Shorter: Find tight feedback cycles
  - Longer: Discover complex multi-step loops

- **Maximum Cycles**: 50-2000 (default: 500)
  - Limits computation time
  - More cycles = longer processing but more complete results

- **Include Self-Loops**: Yes/No
  - Self-loop: Element influences itself directly

- **Filter Trivial Loops**: Yes (recommended)
  - Removes simple 2-node loops
  - Focuses on complex feedback

**Detection Process:**

1. Click "Detect Loops" button
2. Algorithm runs (may take 10-60 seconds for large networks)
3. Progress indicator shows status
4. Results appear in 5 tabs

**Tab 1: Detect Loops**
- Detection controls
- Summary statistics
  - Total loops found
  - Reinforcing count
  - Balancing count
- Loops data table (ID, Type, Length, Elements, Link polarities)

**Tab 2: Loop Classification**
- Distribution charts (R vs. B)
- Separate tables for each type
- Statistical summary

**Tab 3: Loop Details**
- Select specific loop from dropdown
- View loop properties:
  - Type (R/B)
  - Length (number of elements)
  - Path (element sequence)
  - Link polarities
- Narrative description (auto-generated causal chain)
- Loop highlighted in CLD visualization

**Tab 4: Dominant Loops**
- Ranking by:
  - **Occurrence**: How many times elements appear in loops
  - **Participation**: Percentage of loops involving element
- Most influential loops table
- Element participation charts
- **Strategic value**: Identifies intervention points

**Tab 5: Export Results**
- **Excel Export**: Multi-sheet workbook
  - All loops
  - R loops only
  - B loops only
  - Summary statistics
- **Loop Report**: PDF document with analysis
- **Loop Diagrams**: ZIP file of individual loop visualizations

**Interpretation Guidance:**

**High proportion of R loops (>70%):**
- System prone to rapid changes
- Tipping points likely
- High management urgency
- Focus: Strengthen balancing mechanisms

**High proportion of B loops (>70%):**
- System highly stable/resistant to change
- Interventions may face resistance
- Persistent effort required
- Focus: Shift equilibrium points

**Balanced mix (30-70% each):**
- Moderate stability
- Both change potential and self-regulation
- Focus: Leverage R loops for desired changes, use B loops to stabilize

\newpage

### Network Metrics

Quantify node importance and network structure.

**Centrality Measures:**

**1. Degree Centrality**
- **In-Degree**: Number of incoming connections
  - High in-degree = heavily influenced by other elements
  - Good indicators of system state

- **Out-Degree**: Number of outgoing connections
  - High out-degree = influences many other elements
  - Good intervention targets

**2. Betweenness Centrality**
- Measures how often a node lies on shortest paths
- High betweenness = bridges different parts of system
- Critical for information/influence flow
- Removal disconnects system

**3. Closeness Centrality**
- Average distance to all other nodes
- High closeness = quick influence propagation
- Important for rapid system responses

**4. Eigenvector Centrality**
- Importance based on importance of neighbors
- High eigenvector = connected to other important nodes
- Identifies truly influential elements

**5. PageRank**
- Google's algorithm adapted to networks
- Weighted importance score
- Good overall influence measure

**Network-Level Metrics:**

- **Density**: Proportion of possible connections that exist
  - Low (<0.1): Sparse, modular system
  - Medium (0.1-0.3): Moderately connected
  - High (>0.3): Tightly coupled system

- **Diameter**: Longest shortest path between any two nodes
  - Measures how "wide" the system is

- **Average Path Length**: Mean shortest path
  - Measures how quickly influence spreads

**MICMAC Analysis:**

Classifies nodes by influence and dependency:

**Four Quadrants:**

1. **Relay Variables** (High influence, High dependency)
   - Unstable, transmit effects
   - Complex interdependencies
   - Require careful management

2. **Influential Variables** (High influence, Low dependency)
   - Strong drivers of system
   - Independent of other elements
   - Prime intervention targets

3. **Dependent Variables** (Low influence, High dependency)
   - Outcomes/indicators
   - Sensitive to changes
   - Good monitoring points

4. **Autonomous Variables** (Low influence, Low dependency)
   - Weakly connected
   - Limited role in dynamics
   - May be removed to simplify

**Leverage Point Analysis:**

Identifies high-impact intervention points using composite score:

```
Leverage Score = Betweenness + Eigenvector + PageRank
```

**Top 10 Leverage Points** ranked by score

**Categories:**
- **Drivers**: High out-degree nodes → Cascading interventions
- **Receivers**: High in-degree nodes → Monitoring indicators
- **Connectors**: High betweenness nodes → Critical for resilience

**Strategic Recommendations Section:**

Based on analysis outputs, generates context-specific guidance:

1. **Priority Intervention Points**: Names top 3 leverage nodes with scores
2. **Cascading Strategy**: Driver nodes with average influence counts
3. **Early Warning System**: Receiver nodes as monitoring indicators
4. **System Dynamics Alerts**: Loop-based warnings (tipping points vs. resistance)
5. **Resilience Protection**: Connector nodes to preserve

\newpage

### Simplification Tools

Reduce network complexity while preserving essential dynamics.

**Techniques:**

**1. Endogenization**
- Remove exogenous variables (no incoming connections)
- Focuses on internally-driven dynamics
- **Use when**: External drivers are outside scope

**2. Encapsulation**
- Remove SISO nodes (Single Input, Single Output)
- Merges upstream and downstream connections
- **Use when**: Simplifying intermediate steps

**3. Edge Filtering**
- Remove weak connections
- Keep only strong/medium relationships
- **Use when**: Reducing visual clutter

**4. Core Loop Extraction**
- Extract dominant feedback loops only
- Remove elements not in key loops
- **Use when**: Focusing on feedback dynamics

**Workflow:**
1. Select simplification method
2. Set parameters (e.g., minimum strength for edge filtering)
3. Preview simplified network
4. Apply or revert
5. Save simplified version as new project

\newpage

## Response & Validation

### Response Measures

Document and prioritize management interventions.

**Tab 1: Response Register**

Create intervention entries with:

- **ID**: Auto-generated
- **Name**: Intervention description
- **Type**:
  - Regulatory: Laws, quotas, closures
  - Economic: Subsidies, taxes, market-based
  - Educational: Awareness, training
  - Technical: Infrastructure, technology
  - Institutional: Governance reforms
  - Voluntary: Codes of conduct, certification
  - Mixed: Combination

- **Description**: Detailed explanation
- **Target Level**: Which DAPSI(W)R(M) level?
  - Drivers
  - Activities
  - Pressures
  - State
  - Multiple

- **Target Element**: Specific node ID
- **Effectiveness**: Expected impact (High/Medium/Low/Unknown)
- **Feasibility**: Implementation ease (High/Medium/Low)
- **Cost**: 1-10 scale (1=minimal, 10=very expensive)
- **Responsible Stakeholders**: Who implements?
- **Implementation Barriers**: Challenges anticipated
- **Status**:
  - Proposed
  - Planned
  - Implemented
  - Partially Implemented
  - Abandoned

**Interactive Table:**
- CRUD operations (Create, Read, Update, Delete)
- Sort, filter, search
- Export to Excel

**Tab 2: Impact Assessment**

Map responses to problems they address.

**Create Impact Links:**
- Select Response measure
- Select Problem (Pressure/Activity/Driver)
- Specify:
  - **Impact Strength**: Strong/Moderate/Weak
  - **Timeframe**: Immediate/Short-term (1-2y)/Medium-term (3-5y)/Long-term (>5y)
  - **Confidence**: Evidence quality

**Impact Matrix Table:**
- Rows: Responses
- Columns: Problems
- Cells: Strength + timeframe

**Visual Heatmap:**
- Color-coded impact strength
- Quick identification of multi-benefit responses

**Tab 3: Prioritization**

Multi-criteria ranking of responses.

**Weighting Sliders:**
- **Effectiveness Weight** (0-1): How important is impact magnitude?
- **Feasibility Weight** (0-1): How important is ease of implementation?
- **Cost Weight** (0-1, inverse): How sensitive are we to cost?

**Priority Score Calculation:**
```
Priority = (Effectiveness × W_eff) +
           (Feasibility × W_feas) -
           (Cost/10 × W_cost)
```

**Ranked Table:**
- Responses sorted by priority score
- Shows all input values and weights
- Identify top candidates

**Scatter Plots:**
- **Effectiveness vs. Feasibility**: Identify "quick wins" (high both)
- **Cost vs. Impact**: Assess cost-effectiveness

**Sensitivity Analysis:**
- Adjust weights to test robustness
- See how rankings change
- Identify stable top choices

**Tab 4: Implementation Plan**

Track response deployment over time.

**Milestones:**
- **Milestone Name**: Key deliverable/checkpoint
- **Response ID**: Which measure?
- **Target Date**: Planned completion
- **Status**: Pending/In Progress/Completed/Delayed
- **Notes**: Progress updates

**Gantt Chart:**
- Timeline visualization
- Milestone dependencies
- Critical path highlighted
- Export as PNG

**Implementation Checklist:**
- Pre-implementation: Stakeholder buy-in, budget secured, regulations approved
- During implementation: Monitoring protocols, adaptive management triggers
- Post-implementation: Evaluation plan, reporting schedule

**Tab 5: Export**

Download response planning documentation:
- Excel workbook (all tabs)
- PDF summary report
- Implementation timeline chart

\newpage

### Scenario Builder

Explore "what-if" alternatives and compare scenarios.

**Scenario Management:**

**Create New Scenario:**
1. Click "New Scenario"
2. Enter name and description
3. Scenario card appears in gallery

**Scenario Cards Display:**
- Thumbnail preview
- Scenario name
- Creation date
- Number of modifications
- Active status indicator

**Configure Tab:**

Make changes to network for scenario:

**Add Nodes:**
- New elements to represent alternative states
- Example: "Marine Protected Area established"

**Remove Nodes:**
- Simulate element removal
- Example: Remove "Bottom trawling" activity

**Modify Nodes:**
- Change properties (importance, trend, etc.)
- Example: Increase "Tourism" intensity

**Add Links:**
- New causal connections
- Example: "MPA" → "Fish biomass" (+strong)

**Remove Links:**
- Break existing connections
- Example: Remove "Fishing effort" → "Fish stock"

**Modify Links:**
- Change polarity or strength
- Example: Weaken "Pollution" → "Seagrass health"

**Modification Tracker:**
- Lists all changes made
- Undo individual modifications
- Reset scenario to baseline

**Impact Analysis Tab:**

Assess scenario effects on:

**Network Metrics:**
- Compare density, centrality, etc. to baseline
- Identify structural changes

**Loop Dynamics:**
- Re-run loop detection for scenario
- Compare R/B distribution
- Identify new/removed loops

**Leverage Points:**
- Recalculate top nodes
- See how intervention points shift

**Impact Propagation:**
- Trace effects of changes
- Identify cascading consequences

**Compare Tab:**

Side-by-side comparison of scenarios:

**Table View:**
- Metric-by-metric comparison
- Baseline vs. Scenario A vs. Scenario B
- Difference columns (Δ)

**Chart View:**
- Radar charts for multi-metric comparison
- Bar charts for key indicators
- Network structure comparison

**Report Generation:**
- Scenario comparison PDF
- Includes all metrics, charts, and narratives
- Export for stakeholder presentation

**When to Use Scenarios:**

- **Policy Analysis**: Compare regulatory alternatives
- **Climate Futures**: Explore different climate scenarios
- **Intervention Testing**: Assess management options before implementation
- **Stakeholder Engagement**: Facilitate participatory visioning

\newpage

### Validation

Document evidence quality and expert review.

**Validation Protocols:**

**Element-Level Validation:**
- For each ISA element:
  - **Evidence Source**: Literature, data, expert judgment
  - **Evidence Quality**: Strong/Moderate/Weak
  - **Confidence**: High/Medium/Low
  - **Uncertainty**: Known limitations

**Relationship Validation:**
- For each causal link:
  - **Mechanism**: Explanatory pathway
  - **Evidence**: Supporting studies/data
  - **Strength**: Quantitative if available
  - **Temporal Lag**: Time delay in effect

**Expert Elicitation:**
- **Expert Name**: Who provided input?
- **Affiliation**: Organization/role
- **Date**: When consulted?
- **Comments**: Expert feedback

**Stakeholder Review:**
- **Workshop Date**: When was CLD reviewed?
- **Participants**: List of attendees
- **Feedback**: Suggested modifications
- **Resolution**: How feedback was addressed

**Validation Checklist:**
- [ ] All elements have descriptions
- [ ] All links have mechanisms documented
- [ ] Confidence scores assigned
- [ ] Expert review completed
- [ ] Stakeholder feedback incorporated
- [ ] Validation report generated

**Version Control:**
- Track changes over time
- Document who made changes and when
- Maintain change log
- Enable rollback if needed

\newpage

## Export & Reports

### Data Export

Export your project data in multiple formats.

**Excel Export (.xlsx)**

Multi-sheet workbook containing:
- Project metadata
- All ISA tables (G&B, ES, MPF, P, A, D)
- Adjacency matrices
- CLD nodes and edges
- Loop detection results
- Network metrics
- Stakeholder register
- Response measures
- Scenario comparisons

**Component Selection:**
- Choose which datasets to include
- Customize export for specific uses

**CSV Export (.csv)**
- Single table export
- Choose specific dataset
- Compatible with any spreadsheet software

**JSON Export (.json)**
- Hierarchical structured data
- Complete project including nested structures
- Compatible with web applications, databases
- Kumu.io compatible (with styling)

**R Data Export (.RData)**
- Native R format
- Preserves all object types
- Load directly in R for custom analysis

### Visualization Export

Export CLD visualizations in multiple formats.

**HTML (Interactive)**
- Fully interactive network
- Standalone file (no server needed)
- Share via email or web
- Recipients can explore, zoom, pan
- **File size**: 500KB - 2MB typical
- **Best for**: Stakeholder sharing, website embedding

**PNG (Raster Image)**
- High-resolution bitmap (150 dpi default)
- Custom dimensions (400-4000px width/height)
- Transparent background option
- **File size**: 100KB - 5MB
- **Best for**: Reports, presentations, posters

**SVG (Vector Graphics)**
- Scalable to any size without quality loss
- Editable in vector graphics software
- Small file size
- **Best for**: Publications, professional design, large-format printing

**PDF (Print-Ready)**
- Publication quality
- Embeddable in documents
- Requires Pandoc + LaTeX installation
- **Best for**: Formal reports, archiving

**Export Settings:**

- **Dimensions**: Width and height in pixels
- **Resolution**: DPI for raster formats
- **Background**: Transparent or white
- **Quality**: Compression level

**Recommended Sizes:**
- Presentation slide: 1920 x 1080 px
- Report figure: 2400 x 1800 px (8" x 6" at 300 dpi)
- Poster: 4000 x 3000 px
- Web: 1200 x 900 px

\newpage

### Report Generation

Create comprehensive analysis reports automatically.

**Report Types:**

**1. Executive Summary (2-3 pages)**

Target audience: Decision-makers, policy-makers

Contents:
- Project overview (1 paragraph)
- Key findings (bullet points):
  - Number of elements and connections
  - Feedback loops detected (R vs. B count)
  - Top 3 leverage points
  - Critical management challenges
- High-priority recommendations (3-5 items)
- Visual: Simplified CLD diagram

**2. Technical Report (10-15 pages)**

Target audience: Researchers, technical analysts

Contents:
- Complete DAPSI(W)R(M) analysis
- Element counts by type (table)
- Network metrics (density, centrality, etc.)
- Detailed loop analysis:
  - Loop classification
  - Dominant loops
  - System implications
- Leverage point analysis (top 10)
- Data tables (all ISA exercises)

**3. Stakeholder Presentation (5-7 pages)**

Target audience: General stakeholders, community groups

Contents:
- Plain language system description
- Visual-heavy (CLD, charts, infographics)
- System overview:
  - Main drivers identified
  - Key pressures
  - Ecosystem impacts
  - Welfare consequences
- Opportunities for action
- Engagement opportunities
- Discussion questions

**4. Full Project Report (20-30 pages)**

Target audience: Comprehensive documentation for all audiences

Contents:
- All above sections combined
- Complete methodology
- All data tables
- All visualizations
- Detailed recommendations (context-specific):

  **Strategic Recommendations:**
  - Priority intervention points (named, with scores)
  - Cascading intervention strategy (specific Driver nodes)
  - Early warning monitoring system (specific Receiver nodes)
  - System dynamics alerts (based on loop composition)
  - Resilience protection (specific Connector nodes)

  **Management Recommendations:**
  - Intervention design (network density-specific advice)
  - Monitoring strategy (data-driven indicator selection)
  - Adaptive management (loop-informed strategy with timing)
  - Stakeholder engagement (strategic alignment to leverage points)
  - Immediate next steps (5 detailed action plans)

- Appendices:
  - Glossary
  - Data sources
  - Validation documentation
  - References

**Report Options:**

**Include Visualizations:**
- [x] CLD network diagram
- [x] Loop distribution charts
- [x] Leverage point rankings
- [x] Network metrics plots

**Include Data Tables:**
- [x] All ISA element tables
- [x] Adjacency matrices
- [x] Loop details table
- [x] Metrics summary

**Custom Branding:**
- Add your logo
- Custom color scheme
- Organization footer

**Report Formats:**

**HTML (Web Version)**
- Interactive table of contents (floating sidebar)
- Collapsible sections
- Hyperlinked cross-references
- Embedded interactive visualizations
- **File size**: 1-5 MB
- **Best for**: Sharing via email, web publishing, screen viewing

**PDF (Print Version)**
- Professional formatting
- Page numbers and headers
- Print-ready quality
- Requires Pandoc + LaTeX/TinyTeX
- **File size**: 2-10 MB
- **Best for**: Formal distribution, archiving, printing

**Word (.docx)**
- Editable document
- Tables and figures
- Requires Pandoc installation
- **File size**: 1-5 MB
- **Best for**: Collaborative editing, custom formatting

**Generation Process:**

1. Navigate to "Prepare Report" module
2. Select report type
3. Choose options (visualizations, data tables)
4. Click "Generate Report"
5. Processing (10-30 seconds)
6. Download button appears
7. Open/save report file

**Troubleshooting:**

- **PDF generation fails**: Install Pandoc and TinyTeX
  ```r
  install.packages("tinytex")
  tinytex::install_tinytex()
  ```

- **Report is empty**: Ensure you've completed ISA data entry and run analyses

- **Charts not appearing**: Check that analysis modules have been executed

\newpage

# Workflows & Best Practices

## Recommended Workflows

### Standard Participatory Workshop (3 days)

**Day 1: System Mapping (6 hours)**
- Morning: Introduction and project setup (1h)
  - Present DAPSI(W)R(M) framework
  - Define focal issue and boundaries
  - Identify stakeholders

- Late morning: Goods & Benefits (1.5h)
  - Brainstorm valued outcomes (Exercise 1)
  - Prioritize by importance

- Afternoon: Working backwards (3.5h)
  - Ecosystem Services (Exercise 2a)
  - Marine Processes (Exercise 2b)
  - Break
  - Pressures (Exercise 3)

**Day 2: Causal Chains and Visualization (6 hours)**
- Morning: Drivers and Activities (2h)
  - Activities generating pressures (Exercise 4)
  - Root cause drivers (Exercise 5)

- Late morning: Loop closure (1.5h)
  - Feedback connections (Exercise 6)
  - Validate connections

- Afternoon: CLD creation and exploration (2.5h)
  - Generate network (Exercise 7-8)
  - Interactive exploration
  - Identify patterns

**Day 3: Analysis and Planning (6 hours)**
- Morning: Analysis (2h)
  - Loop detection
  - Network metrics
  - Leverage points

- Late morning: Response planning (2h)
  - Brainstorm interventions
  - Multi-criteria prioritization

- Afternoon: Synthesis (2h)
  - Report generation
  - Action planning
  - Next steps agreement

### Solo/Research Workflow (25 days)

**Week 1: Foundation (5 days)**
- Day 1-2: Project setup, literature review
- Day 3-4: ISA data entry (Exercises 0-3)
- Day 5: ISA data entry (Exercises 4-6)

**Week 2: Analysis (5 days)**
- Day 6: CLD generation and exploration
- Day 7-8: Loop detection and interpretation
- Day 9: Network metrics calculation
- Day 10: Leverage point analysis

**Week 3: Validation (5 days)**
- Day 11-13: Expert consultation
- Day 14-15: Stakeholder review and revision

**Week 4: Response Planning (5 days)**
- Day 16-17: Response measure identification
- Day 18-19: Impact assessment and prioritization
- Day 20: Implementation planning

**Week 5: Documentation (5 days)**
- Day 21-22: Scenario analysis
- Day 23-24: Report generation
- Day 25: Final review and submission

### Rapid Assessment (AI-Assisted, 1 day)

**Morning (3 hours)**
- 0-30min: Project setup
- 30-90min: AI-Assisted ISA interview (11 steps)
- 90-120min: Review and refine generated elements
- 120-180min: CLD visualization and exploration

**Afternoon (3 hours)**
- 180-240min: Loop detection and analysis
- 240-300min: Response brainstorming
- 300-360min: Report generation and next steps

## Best Practices

### Data Quality

**1. Clear Naming Conventions**
- Use descriptive, specific names
- Avoid jargon or acronyms (or define them)
- Be consistent across similar elements

**Examples:**
- Good: "Commercial bottom trawl fishing"
- Poor: "Fishing" (too vague)
- Poor: "CBT" (acronym unclear)

**2. Complete Descriptions**
- Provide context for each element
- Explain mechanisms for relationships
- Document evidence sources

**3. Appropriate Granularity**
- Not too broad: "Pollution" → "Nutrient pollution from agriculture"
- Not too narrow: "Nitrogen runoff from Field 23A" → "Agricultural nutrient runoff"
- Match analysis scale to decision context

**4. Validation**
- Assign confidence scores honestly
- Document uncertainties
- Seek expert review
- Incorporate stakeholder feedback

### Network Design

**1. Optimal Network Size**
- Sweet spot: 20-60 nodes
- Too small (<15): Misses important dynamics
- Too large (>100): Difficult to analyze and communicate
- Focus on most important elements

**2. Balance Across DAPSI Levels**
- Aim for similar numbers at each level
- Avoid overrepresenting one level
- Example distribution: 5D, 8A, 10P, 8S, 6W, 5R

**3. Connection Density**
- Target: 1.5-3 connections per node average
- Too sparse: May miss key feedbacks
- Too dense: Hard to interpret, less useful

**4. Feedback Loops**
- Deliberately design some feedback
- Every D should ultimately connect back to a G&B
- Look for unintended consequences

### Stakeholder Engagement

**1. Participatory Mapping**
- Involve diverse stakeholders
- Use visualization to facilitate discussion
- Capture local/traditional knowledge
- Validate expert knowledge

**2. Power-Interest Management**
- Engage high power/high interest closely (collaborate)
- Keep high power/low interest satisfied (inform regularly)
- Keep low power/high interest informed (consult)
- Monitor low power/low interest (minimum effort)

**3. Transparent Process**
- Document all assumptions
- Make data sources explicit
- Explain uncertainties
- Share preliminary results for feedback

**4. Actionable Outputs**
- Link analysis to management questions
- Prioritize practical recommendations
- Develop clear next steps
- Assign responsibilities

### Technical Tips

**1. Save Often**
- Use Auto-save feature
- Manual save every 15-30 minutes
- Use descriptive filenames with dates
- Keep backup copies

**2. Incremental Development**
- Start simple, add complexity gradually
- Test small sections before building full network
- Validate frequently during development

**3. Use Templates**
- Leverage existing templates when applicable
- Customize rather than starting from scratch
- Document your own templates for reuse

**4. Export Regularly**
- Export to Excel for external backup
- Export visualizations at key milestones
- Generate reports periodically to check completeness

**5. Browser Recommendations**
- Chrome (best performance)
- Firefox (good alternative)
- Avoid Internet Explorer
- Keep browser updated

**6. Performance**
- Close other browser tabs/applications
- Clear browser cache if slow
- Reduce network size if >100 nodes causing lag
- Use hierarchical layout for large networks

\newpage

# Troubleshooting

## Common Issues

### Installation Problems

**Issue: Package installation fails**

Solution:
```r
# Try installing from different CRAN mirror
options(repos = "https://cloud.r-project.org/")
install.packages("package_name")

# Or use RStudio's package installer (Tools > Install Packages)
```

**Issue: Application won't start**

Solutions:
1. Check R version (must be 4.0+)
   ```r
   R.version.string
   ```
2. Verify all packages installed
   ```r
   required_packages <- c("shiny", "shinydashboard", "shinyjs", ...)
   missing <- required_packages[!required_packages %in% installed.packages()]
   if(length(missing) > 0) install.packages(missing)
   ```
3. Check for error messages in R console

**Issue: Port already in use**

Solution:
```r
# Use different port
shiny::runApp(port = 8080)
```

### Data Entry Issues

**Issue: Cannot add new elements**

Solutions:
- Ensure all required fields completed
- Check for duplicate IDs
- Verify data type (numeric vs. text)
- Clear browser cache

**Issue: Adjacency matrix not saving**

Solutions:
- Fill at least one cell in matrix
- Use correct format: `+strong`, `+medium`, `+weak`, `-strong`, etc.
- Save exercise before moving to next

**Issue: Data disappears after reload**

Solutions:
- Always save project before closing
- Check Auto-save indicator is active
- Verify save file exists in expected location

### Visualization Issues

**Issue: CLD not displaying**

Solutions:
- Ensure ISA data entered (Exercises 1-6)
- Check browser JavaScript enabled
- Try refreshing page (F5)
- Check browser console for errors (F12 → Console tab)

**Issue: Nodes overlapping/messy layout**

Solutions:
- Use Hierarchical layout (Down-Up direction)
- Increase level separation (150-200px)
- Try Physics layout with higher gravity
- Manually reposition nodes and save

**Issue: Cannot export visualization**

Solutions:
- **PNG**: Allow popup windows in browser
- **HTML**: Check download folder permissions
- **PDF**: Install Pandoc and LaTeX
  ```r
  install.packages("tinytex")
  tinytex::install_tinytex()
  ```

### Analysis Issues

**Issue: Loop detection hangs**

Solutions:
- Network too large (>100 nodes)
- Reduce max loop length (try 6-8)
- Reduce max cycles (try 200-500)
- Filter trivial loops: Yes
- Simplify network (remove low-importance elements)

**Issue: No loops detected**

Solutions:
- Check that Exercise 6 (Loop Closure) completed
- Verify feedback connections exist (D → G&B links)
- Increase max loop length (try 10-12)
- Check network is fully connected

**Issue: Network metrics fail**

Solutions:
- Ensure CLD generated
- Check for disconnected components
- Remove self-loops if present
- Verify edge polarity values valid

### Report Generation Issues

**Issue: Report generation fails**

Solutions:
- Complete minimum data entry first
- Run required analyses before report
- Check available disk space
- Try HTML format first (most compatible)

**Issue: PDF generation fails**

Solutions:
```r
# Install required tools
install.packages("tinytex")
tinytex::install_tinytex()

# Verify installation
tinytex:::is_tinytex()  # Should return TRUE
```

**Issue: Report missing sections**

Solutions:
- Run all analyses before generating report
- Check that data exists for missing sections
- Try different report type
- Generate Full Report for all content

### Performance Issues

**Issue: Application slow/laggy**

Solutions:
- Close other applications
- Reduce network size (<60 nodes ideal)
- Use hierarchical layout instead of physics
- Disable loop highlighting when not needed
- Clear browser cache
- Restart R session

**Issue: Browser crashes**

Solutions:
- Use Chrome or Firefox (most stable)
- Increase browser memory allocation
- Reduce visualization complexity
- Export data and reload project

### File Issues

**Issue: Cannot load saved project**

Solutions:
- Verify file extension is `.rds`
- Check file not corrupted (size >0 bytes)
- Try loading in fresh R session
- Restore from backup if available

**Issue: Excel import fails**

Solutions:
- Use provided template exactly
- Check column names match template
- Verify data types (numbers, text, dates)
- Remove empty rows
- Check file not open in Excel

**Issue: Cannot export to Excel**

Solutions:
- Check write permissions in target folder
- Close Excel if file open
- Try different filename
- Verify `openxlsx` package installed

## Getting Help

### In-App Help

- **Module Help Buttons**: Click (?) icon for context-sensitive help
- **Tooltips**: Hover over fields for descriptions
- **User Guide**: Accessible from Help menu

### Documentation

- **Quick Start Guide**: `/docs/QUICK_START.md`
- **Installation Guide**: `/docs/INSTALLATION.md`
- **Framework Documentation**: `/docs/framework_documentation.md`
- **Complete User Guide**: `/Documents/MarineSABRES_Complete_User_Guide.md`

### Online Resources

- **GitHub Repository**: [github.com/marinesabres/SESToolbox](https://github.com/marinesabres)
- **Issue Tracker**: Report bugs and request features
- **Wiki**: Community-contributed guides and examples

### Contact Support

For technical issues not resolved by troubleshooting:
- Email: support@marinesabres.eu
- Include:
  - Error messages (exact text or screenshot)
  - Steps to reproduce
  - R and package versions
  - Operating system

\newpage

# Glossary

**Activity (A)**: Human actions that generate pressures on marine systems (e.g., fishing, shipping, tourism)

**Adjacency Matrix**: Table showing connections between two sets of elements; rows and columns represent elements, cells contain relationship information

**Balancing Loop (B)**: Feedback loop with odd number of negative links; stabilizes system toward equilibrium

**Betweenness Centrality**: Network measure of how often a node lies on shortest paths between other nodes; indicates bridging importance

**Causal Loop Diagram (CLD)**: Network visualization showing cause-effect relationships and feedback loops

**Centrality**: Family of metrics quantifying node importance in networks (degree, betweenness, closeness, eigenvector)

**CRUD**: Create, Read, Update, Delete - basic data operations

**DAPSI(W)R(M)**: Drivers-Activities-Pressures-State changes-Welfare impacts-Response Measures framework for SES analysis. The "R/M" represents management interventions, combining policy responses and implementing measures into one unified category.

**Degree Centrality**: Count of connections; in-degree (incoming), out-degree (outgoing)

**Driver (D)**: Root causes behind activities (economic, social, technological, environmental, policy factors)

**Ecosystem Service (ES/W)**: Benefits ecosystems provide to humans (provisioning, regulating, cultural, supporting)

**Edge**: Connection/link between nodes in network; represents causal relationship

**Eigenvector Centrality**: Importance based on importance of neighbors; high score = connected to other important nodes

**Feedback Loop**: Circular pathway in network where element influences itself through chain of other elements

**Goods & Benefits (G&B/R)**: Valued outputs from marine systems received by stakeholders

**Hierarchical Layout**: Network visualization algorithm organizing nodes in levels/layers

**ISA**: Integrated Systems Analysis - structured methodology for SES analysis

**Kumu.io**: Online network visualization platform compatible with tool's JSON exports

**Leverage Point**: High-impact intervention location identified through centrality metrics

**Marine Process/Functioning (MPF/S/I)**: Ecological processes and state changes in marine environment

**MICMAC**: Matrix of Crossed Impacts - analysis classifying nodes by influence and dependency

**Network Density**: Proportion of possible connections that actually exist; measure of connectivity

**Network Metrics**: Quantitative measures of network structure (density, centrality, diameter, etc.)

**Node**: Element in network diagram representing system component

**PageRank**: Google's algorithm for ranking importance; adapted for network analysis

**PIMS**: Project Information Management System - module for project metadata and stakeholders

**Polarity**: Sign of causal relationship - positive (+) or negative (-)

**Pressure (P)**: Direct stressors on marine environment (physical, chemical, biological)

**Reinforcing Loop (R)**: Feedback loop with even number of negative links; amplifies change

**Response/Measure (R/M)**: Management interventions addressing drivers, activities, or pressures

**SES**: Social-Ecological System - coupled human-natural system

**Stakeholder**: Individual or group with interest or stake in system outcomes

**Strongly Connected Component (SCC)**: Subset of network where every node can reach every other node

**Tooltip**: Hover text providing additional information about interface element

**visNetwork**: R package for interactive network visualization using vis.js library

\newpage

# Appendix A: Keyboard Shortcuts

| Action | Shortcut | Context |
|--------|----------|---------|
| Save project | Ctrl+S | Global |
| Zoom in | Ctrl + Plus | CLD Visualization |
| Zoom out | Ctrl + Minus | CLD Visualization |
| Fit to screen | Ctrl+0 | CLD Visualization |
| Select all | Ctrl+A | Data tables |
| Search | Ctrl+F | Data tables |
| Export | Ctrl+E | Most modules |
| Refresh | F5 | Global |
| Help | F1 | Module-specific |

# Appendix B: File Formats

## Native Format (.rds)

**Structure:**
```
project_data <- list(
  project_id = "unique_id",
  project_name = "My Project",
  created_at = timestamp,
  last_modified = timestamp,
  user = "username",
  version = "1.5.0",
  data = list(
    metadata = list(...),
    pims = list(...),
    isa_data = list(...),
    cld = list(nodes, edges, loops),
    responses = list(...),
    scenarios = list(...)
  )
)
```

## Excel Import Template

**Sheets:**
1. Goods_Benefits: ID, Name, Type, Description, Stakeholder, Importance, Trend
2. Ecosystem_Services: ID, Name, Type, Description, LinkedGB, Mechanism, Confidence
3. Marine_Processes: ID, Name, Type, Description, LinkedES, Mechanism, Sensitivity, SpatialScale
4. Pressures: ID, Name, Type, Description, LinkedMPF, Intensity, SpatialPattern, TemporalPattern
5. Activities: ID, Name, Sector, Description, LinkedP, Scale, Frequency
6. Drivers: ID, Name, Type, Description, LinkedA, Trend, Controllability
7. GB_ES_Matrix: Rows=G&B, Cols=ES, Cells=relationship
8. ES_MPF_Matrix: Rows=ES, Cols=MPF, Cells=relationship
9. MPF_P_Matrix: Rows=MPF, Cols=P, Cells=relationship
10. P_A_Matrix: Rows=P, Cols=A, Cells=relationship
11. A_D_Matrix: Rows=A, Cols=D, Cells=relationship
12. D_GB_Matrix: Rows=D, Cols=G&B, Cells=relationship (feedback)

# Appendix C: DAPSI(W)R(M) Framework Details

**Framework Levels:**

**Level 1: Drivers (D)**
- Economic: Market forces, globalization, economic growth
- Social: Demographics, cultural values, migration
- Technological: Innovation, efficiency improvements
- Environmental: Climate, natural resource availability
- Policy/Institutional: Regulations, governance structures

**Level 2: Activities (A)**
- Primary: Resource extraction (fishing, mining)
- Secondary: Processing, manufacturing
- Tertiary: Services (tourism, shipping)
- Infrastructure: Ports, energy, coastal development

**Level 3: Pressures (P)**
- Physical: Habitat loss, sealing, abrasion, noise
- Chemical: Contaminants, nutrients, pH changes
- Biological: Extraction, introduction of species, pathogens

**Level 4: State Changes (S/I)**
- Ecosystem structure: Species composition, biomass
- Ecosystem functioning: Primary production, nutrient cycling
- Habitat condition: Extent, quality, connectivity

**Level 5: Welfare Impacts (W)**
- Ecosystem services affected
- Social impacts: Livelihoods, culture, health
- Economic impacts: Income, employment, market value

**Level 6: Responses (R)**
- Regulatory: Laws, quotas, protected areas
- Economic: Taxes, subsidies, markets
- Technical: Infrastructure, monitoring
- Educational: Awareness, capacity building

**Level 7: Measures (M)**
- Preventive: Reduce drivers
- Mitigative: Reduce pressures
- Restorative: Recover state
- Adaptive: Adjust management

---

**Document Version:** 1.5.0
**Last Updated:** November 2025
**License:** CC BY 4.0
**Contact:** support@marinesabres.eu
**Website:** www.marinesabres.eu

---
