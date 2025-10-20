# MarineSABRES SES Tool - Complete User Guide

**Version:** 1.0
**Last Updated:** October 20, 2025
**Project:** Marine Social-Ecological Systems Analysis Tool

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Dashboard Overview](#3-dashboard-overview)
4. [PIMS Module](#4-pims-module)
5. [ISA Data Entry](#5-isa-data-entry)
6. [CLD Visualization](#6-cld-visualization)
7. [Analysis Tools](#7-analysis-tools)
8. [Response & Validation](#8-response--validation)
9. [Export & Reports](#9-export--reports)
10. [Workflows & Best Practices](#10-workflows--best-practices)
11. [Troubleshooting](#11-troubleshooting)
12. [Glossary](#12-glossary)

---

## 1. Introduction

### 1.1 What is the MarineSABRES SES Tool?

The MarineSABRES Social-Ecological Systems (SES) Analysis Tool is a comprehensive Shiny application designed to support participatory analysis of marine social-ecological systems. It implements the **DAPSI(W)R(M) framework** (Drivers-Activities-Pressures-State changes-(Welfare impacts)-Responses-(Measures)) and Integrated Systems Analysis (ISA) methodology.

### 1.2 Key Features

- **Project Information Management System (PIMS)**: Manage project metadata, stakeholders, resources, and evaluation
- **Integrated Systems Analysis (ISA)**: 13-exercise structured approach to SES analysis
- **Causal Loop Diagram (CLD)**: Interactive visualization of system dynamics
- **Loop Detection**: Automatic identification of reinforcing and balancing feedback loops
- **Response Planning**: Prioritize and plan management interventions
- **Stakeholder Management**: Power-Interest analysis and engagement planning
- **Export & Reports**: Comprehensive data export and report generation

### 1.3 Target Users

- Marine resource managers
- Policy analysts
- Environmental consultants
- Researchers in marine social-ecological systems
- Stakeholder engagement facilitators

### 1.4 System Requirements

- R (version 4.0 or higher)
- Modern web browser (Chrome, Firefox, Edge, Safari)
- Internet connection (for initial setup only)

---

## 2. Getting Started

### 2.1 Launching the Application

**Option 1: Using run_app.R**
```r
cd /path/to/MarineSABRES_SES_Shiny
Rscript run_app.R
```

**Option 2: Direct launch**
```r
setwd("/path/to/MarineSABRES_SES_Shiny")
shiny::runApp()
```

**Option 3: RStudio**
- Open `app.R` in RStudio
- Click "Run App" button

### 2.2 First-Time Setup

1. **Create a New Project:**
   - Navigate to PIMS → Project Setup
   - Enter project name
   - Select demonstration area
   - Define focal issue
   - Save project information

2. **Load Example Data (Optional):**
   - Use "Load Project" button in sidebar
   - Select `data/example_baltic_sea_fisheries.rds`
   - Explore pre-populated data

3. **Save Your Work:**
   - Use "Save Project" button regularly
   - Files are saved as `.rds` format
   - Include project name and date in filename

### 2.3 User Interface Overview

**Header:**
- MarineSABRES logo and title
- Help button (opens user guide)
- User information

**Sidebar Menu:**
- Dashboard
- PIMS Module (5 sub-menus)
- ISA Data Entry
- CLD Visualization
- Analysis Tools (4 sub-menus)
- Response & Validation (3 sub-menus)
- Export & Reports
- Quick Actions (Save/Load)
- Progress indicator

**Main Panel:**
- Content area for selected module
- Interactive tables, plots, and forms

---

## 3. Dashboard Overview

### 3.1 Dashboard Components

**Value Boxes (Top Row):**
- **Total Elements**: Count of all DAPSI(W)R(M) elements
- **Connections**: Number of causal links in CLD
- **Loops Detected**: Feedback loops identified
- **Completion**: Overall project progress percentage

**Project Overview Box:**
- Project ID
- Creation and modification dates
- Demonstration area
- Focal issue
- Status summary

**Quick Access Box:**
- Recent activities
- Shortcuts to incomplete tasks

**CLD Preview:**
- Mini network visualization
- Quick view of system structure

### 3.2 Navigation Tips

- Click sidebar items to navigate between modules
- Use browser back button with caution (may cause data loss)
- Save work before switching major modules
- Use breadcrumbs in help modals

---

## 4. PIMS Module

The Process & Information Management System (PIMS) provides project-level management functions.

### 4.1 Project Setup

**Purpose:** Initialize project metadata and scope

**How to Use:**
1. Navigate to PIMS → Project Setup
2. Complete all fields:
   - **Project Name**: Descriptive title
   - **Demonstration Area**: Select from predefined list or enter custom
   - **Focal Issue**: Main problem/opportunity being addressed
   - **Definition Statement**: Project objectives and scope
   - **Temporal Scale**: Time period of analysis
   - **Spatial Scale**: Geographic extent
   - **System in Focus**: System boundaries description
3. Click "Save" button
4. Verify in "Current Status" panel

**Best Practices:**
- Be specific in focal issue description
- Define clear system boundaries
- Include stakeholder perspectives in definition

### 4.2 Stakeholder Management

**Purpose:** Identify, analyze, and manage project stakeholders

#### 4.2.1 Stakeholder Register

**Adding Stakeholders:**
1. Navigate to PIMS → Stakeholders → Stakeholder Register tab
2. Fill in form:
   - **Stakeholder ID**: Unique identifier (auto-generated)
   - **Name**: Organization or individual name
   - **Type**: Government / NGO / Private / Community / Research
   - **Power**: High / Medium / Low
   - **Interest**: High / Medium / Low
   - **Attitude**: Supportive / Neutral / Opposed
   - **Contact**: Email or phone
   - **Notes**: Additional information
3. Click "Add Stakeholder"
4. View in table below

**Editing/Deleting:**
- Select row(s) in table
- Click "Edit Selected" or "Delete Selected"
- Confirm changes

#### 4.2.2 Power-Interest Analysis

**Purpose:** Visualize stakeholder influence and engagement needs

**How to Read the Grid:**
- **Top Right (Key Players)**: High power, high interest → Engage closely, collaborate
- **Top Left (Keep Satisfied)**: High power, low interest → Keep informed of progress
- **Bottom Right (Keep Informed)**: Low power, high interest → Consult regularly
- **Bottom Left (Monitor)**: Low power, low interest → Monitor passively

**Interactive Features:**
- Click on points to view stakeholder details
- Colored by attitude (green=supportive, gray=neutral, red=opposed)
- Sized by importance

**Strategic Actions:**
- Focus resources on Key Players
- Don't overburden low-priority stakeholders
- Plan engagement appropriate to quadrant

#### 4.2.3 Engagement Planning

**Purpose:** Plan stakeholder engagement activities

**IAP2 Engagement Spectrum:**
1. **Inform**: One-way communication
2. **Consult**: Get feedback
3. **Involve**: Work directly with stakeholders
4. **Collaborate**: Partner in decision-making
5. **Empower**: Place final decision-making in stakeholder hands

**Adding Activities:**
1. Go to Engagement Planning tab
2. Select stakeholder from dropdown
3. Choose engagement level
4. Set planned/actual dates
5. Describe activity
6. Track outcomes
7. Click "Add Activity"

**Monitoring:**
- View engagement history table
- Check completion rates
- Identify gaps in engagement

#### 4.2.4 Communication Plan

**Purpose:** Log and track stakeholder communications

**Recording Communications:**
1. Go to Communication Plan tab
2. Select stakeholder
3. Choose communication type (Meeting / Email / Phone / Workshop / Report)
4. Set date
5. Add notes and outcomes
6. Click "Add Communication"

**Uses:**
- Maintain audit trail
- Track information sharing
- Plan follow-up actions

#### 4.2.5 Analysis & Reports

**Purpose:** Generate stakeholder analysis insights

**Features:**
- Stakeholder statistics by type, power, interest
- Engagement activity counts
- Communication frequency charts
- Excel export of all stakeholder data

**Exporting:**
- Click "Export to Excel" button
- Multi-sheet workbook includes:
  - Stakeholder register
  - Engagement activities
  - Communication log
  - Summary statistics

### 4.3 Resources & Risks

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- Resource allocation tracking
- Budget management
- Risk register
- Risk mitigation planning

### 4.4 Data Management

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- Data provenance tracking
- Version control
- Data quality checks
- Import/export history
- Metadata management

### 4.5 Evaluation

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- Process evaluation framework
- Outcome tracking
- Success indicators
- Lessons learned documentation

---

## 5. ISA Data Entry

The Integrated Systems Analysis (ISA) module implements a 13-exercise structured approach to mapping social-ecological systems using the DAPSI(W)R(M) framework.

### 5.1 Overview of 13 Exercises

| Exercise | Name | Purpose |
|----------|------|---------|
| Ex 0 | Case Study Scoping | Define system boundaries |
| Ex 1 | Goods & Benefits | Identify ecosystem services benefits |
| Ex 2a | Ecosystem Services | Link services to benefits |
| Ex 2b | Marine Processes & Functioning | Identify ecological processes |
| Ex 3 | Pressures | Identify human-induced pressures |
| Ex 4 | Activities | Identify human activities |
| Ex 5 | Drivers | Identify underlying drivers |
| Ex 6 | Loop Closure | Connect benefits back to activities |
| Ex 7-9 | CLD Creation | Build causal loop diagram |
| Ex 10 | System Dynamics | Analyze behavior over time |
| Ex 11 | BOT Graphs | Visualize trends |
| Ex 12 | Validation | Verify with stakeholders |

### 5.2 Getting Help

Each exercise tab has a **Help button** (question mark icon) that opens detailed guidance including:
- Purpose and objectives
- What to include
- Examples
- Tips for success
- Links to further resources

### 5.3 Exercise 0: Case Study Scoping

**Purpose:** Define the geographic, temporal, and thematic scope of your analysis

**Key Questions:**
1. What is the focal issue or management question?
2. What are the spatial boundaries?
3. What is the time period of analysis?
4. Who are the key stakeholders?

**How to Complete:**
1. Navigate to ISA Data Entry → Exercise 0
2. Read the scoping questions
3. Write responses in text areas
4. Click "Save Scoping"
5. Review summary

**Tips:**
- Be specific about boundaries
- Consider stakeholder perspectives
- Align with PIMS Project Setup

### 5.4 Exercise 1: Goods & Benefits

**Purpose:** Identify and classify the goods and benefits that people derive from the marine ecosystem

**CRUD Operations:**
- **Create**: Click "Add" button, fill form, save
- **Read**: View table below form
- **Update**: Select row, click "Edit", modify, save
- **Delete**: Select row(s), click "Delete", confirm

**Fields:**
- **ID**: Auto-generated (e.g., GB001)
- **Name**: Clear, specific name (e.g., "Commercial cod catch")
- **Type**: Provisioning / Regulating / Cultural / Supporting
- **Stakeholder**: Who benefits?
- **Importance**: High / Medium / Low
- **Trend**: Increasing / Stable / Decreasing
- **Description**: Additional details

**Examples:**
- **Provisioning**: Fish catch, seaweed harvest, genetic resources
- **Regulating**: Storm protection, water purification, climate regulation
- **Cultural**: Recreation, aesthetic value, cultural heritage
- **Supporting**: Nutrient cycling, habitat provision, biodiversity

**Tips:**
- Start with obvious benefits
- Consider multiple stakeholder perspectives
- Be specific (e.g., "Cod catch" not "Fish")
- Include both market and non-market values

### 5.5 Exercise 2a: Ecosystem Services

**Purpose:** Identify the ecosystem services that provide the goods and benefits

**Relationship:** Services (Ex 2a) → Benefits (Ex 1)

**Examples:**
- Fish stock biomass → Commercial fish catch
- Coastal wetlands → Storm surge protection
- Water clarity → Recreational diving

**Fields:**
- **ID**: Auto-generated (e.g., ES001)
- **Name**: Ecosystem service name
- **Type**: Provisioning / Regulating / Cultural / Supporting
- **Linked to G&B**: Which benefit does this support?
- **Description**: How the service provides the benefit

**Tips:**
- One service can support multiple benefits
- Think about ecological functions
- Consider service condition and trends

### 5.6 Exercise 2b: Marine Processes & Functioning

**Purpose:** Identify the underlying ecological processes that generate ecosystem services

**Relationship:** Processes (Ex 2b) → Services (Ex 2a) → Benefits (Ex 1)

**Examples:**
- Primary production → Fish stock biomass
- Sediment stabilization → Water quality
- Nutrient cycling → Primary production

**Fields:**
- **ID**: Auto-generated (e.g., MP001)
- **Name**: Process name
- **Type**: Biological / Chemical / Physical
- **Linked to ES**: Which service does this support?
- **Sensitivity**: High / Medium / Low (to disturbance)
- **Description**: Process details

**Tips:**
- Focus on key processes
- Consider process interactions
- Note sensitivity to changes

### 5.7 Exercise 3: Pressures

**Purpose:** Identify human-induced pressures that affect marine processes and functioning

**Relationship:** Pressures (Ex 3) affect Processes (Ex 2b)

**Examples:**
- Overfishing → Reduced fish biomass
- Nutrient pollution → Eutrophication
- Physical disturbance → Habitat degradation
- Climate change → Temperature increase

**Fields:**
- **ID**: Auto-generated (e.g., P001)
- **Name**: Pressure name
- **Type**: Physical / Chemical / Biological / Other
- **Intensity**: High / Medium / Low
- **Affected Element**: Which process is impacted?
- **Impact Type**: Positive / Negative
- **Description**: Pressure details

**Pressure Categories (MSFD):**
- Biological (e.g., removal of species, introduction of pathogens)
- Physical loss (e.g., sealing, coastal defense)
- Physical disturbance (e.g., abrasion, noise)
- Input of substances (e.g., nutrients, contaminants)
- Input of litter
- Input of energy (e.g., heat, light, noise)
- Changes in hydrological conditions

**Tips:**
- Be specific about pressure source
- Quantify intensity if possible
- Consider cumulative effects
- Note spatial and temporal patterns

### 5.8 Exercise 4: Activities

**Purpose:** Identify human activities that generate pressures

**Relationship:** Activities (Ex 4) → Pressures (Ex 3)

**Examples:**
- Commercial fishing → Overfishing pressure
- Urban wastewater → Nutrient pollution
- Shipping → Oil pollution, noise, strikes
- Coastal development → Habitat loss

**Fields:**
- **ID**: Auto-generated (e.g., A001)
- **Name**: Activity name
- **Sector**: Fisheries / Tourism / Shipping / Industry / Other
- **Scale**: Local / Regional / National / International
- **Generates Pressure**: Link to pressure(s)
- **Description**: Activity details

**Activity Sectors:**
- Capture fisheries (commercial, recreational)
- Aquaculture
- Tourism and recreation
- Shipping and transport
- Energy (renewables, oil & gas)
- Urban development
- Agriculture (coastal runoff)
- Industry and manufacturing

**Tips:**
- One activity can generate multiple pressures
- Consider activity intensity and frequency
- Note seasonal patterns
- Include both direct and indirect activities

### 5.9 Exercise 5: Drivers

**Purpose:** Identify underlying socio-economic drivers that motivate activities

**Relationship:** Drivers (Ex 5) → Activities (Ex 4)

**Examples:**
- Economic growth → Increased fishing effort
- Population growth → Coastal development
- Climate change → Changing fish distributions
- Policy/regulations → Activity changes
- Market demand → Harvest intensity
- Technological innovation → New activities

**Fields:**
- **ID**: Auto-generated (e.g., D001)
- **Name**: Driver name
- **Type**: Economic / Social / Technological / Environmental / Policy
- **Trend**: Increasing / Stable / Decreasing
- **Influences Activity**: Link to activity(ies)
- **Description**: Driver details

**Driver Categories:**
- **Economic**: Market prices, subsidies, economic growth
- **Social**: Population, demographics, cultural values
- **Technological**: Efficiency, innovation, access
- **Environmental**: Climate change, extreme events
- **Policy**: Regulations, governance, enforcement
- **Institutional**: Property rights, management systems

**Tips:**
- Think about root causes
- Consider global vs local drivers
- Note driver interactions
- Include enabling and constraining factors

### 5.10 Exercise 6: Loop Closure

**Purpose:** Identify feedback loops where ecosystem changes influence human activities

**Relationship:** Benefits (Ex 1) → Activities (Ex 4) [feedback]

**Examples:**
- Reduced fish catch → Increased fishing effort (compensatory behavior)
- Improved water quality → Increased tourism
- Habitat degradation → Reduced fishing (adaptive behavior)

**Fields:**
- **From**: Starting element
- **To**: Destination element
- **Link Type**: Positive (+) / Negative (-)
- **Lag Time**: Immediate / Short / Medium / Long
- **Description**: Explain the causal mechanism

**Link Types:**
- **Positive (+)**: Both move in same direction
  - Fish abundance ↑ → Fishing effort ↑
- **Negative (-)**: Move in opposite directions
  - Fish abundance ↓ → Fishing effort ↑ (compensation)

**Tips:**
- Focus on significant feedbacks
- Consider time lags
- Note adaptive vs maladaptive responses
- Include management responses

### 5.11 Exercises 7-9: CLD Creation

**Purpose:** Compile all elements and connections into a Causal Loop Diagram

**Exercise 7: Compile All Elements**
- Review all entered data
- Check for completeness
- Identify missing links
- Verify element names and IDs

**Exercise 8: Define Additional Connections**
- Add connections not captured in previous exercises
- Consider indirect relationships
- Note connection strength and certainty

**Exercise 9: Export to Kumu**
- Generate Kumu-compatible JSON
- Copy export code
- Import to kumu.io for advanced visualization
- Apply styling (see Kumu Code Style guide)

**Using Kumu:**
1. Go to kumu.io and create account (free)
2. Create new project
3. Import → JSON
4. Paste export code
5. Apply template styling
6. Customize colors, layout, filters
7. Share with stakeholders

**Tips:**
- Start simple, add complexity gradually
- Use consistent element naming
- Color-code by element type
- Add connection labels
- Create views for different audiences

### 5.12 Exercise 10: System Dynamics

**Purpose:** Analyze system behavior and identify leverage points

**Key Questions:**
1. What are the dominant feedback loops?
2. Which loops are reinforcing (R) vs balancing (B)?
3. Where are the delays?
4. What are the leverage points for intervention?

**Leverage Points (Meadows):**
1. Constants, parameters (weak)
2. Size of buffers
3. Structure of material stocks and flows
4. Length of delays
5. Strength of balancing loops
6. Strength of reinforcing loops (strong)

**Tips:**
- Use Loop Detection tool (Analysis Tools)
- Identify tipping points
- Consider unintended consequences
- Map temporal dynamics

### 5.13 Exercise 11: BOT Graphs

**Purpose:** Visualize Behavior Over Time for key indicators

**Creating BOT Graphs:**
1. Navigate to Exercise 11 tab
2. Click "Add BOT Graph"
3. Select indicator (from any element)
4. Enter time series data:
   - Year
   - Value
   - (Optional) Uncertainty range
5. Choose graph type:
   - Line plot (trends)
   - Bar chart (comparisons)
   - Area chart (cumulative)
6. Add annotations for events
7. Click "Create Graph"

**Graph Interpretation:**
- **Linear trends**: Steady change
- **Exponential growth**: Reinforcing loop dominance
- **S-curves**: Growth then stabilization
- **Oscillations**: Balancing loop with delays
- **Decline**: Resource depletion, overshoot

**Tips:**
- Use historical data when available
- Include multiple indicators
- Note data quality and gaps
- Connect trends to system structure
- Identify regime shifts

### 5.14 Exercise 12: Validation

**Purpose:** Verify system representation with stakeholders and experts

**Validation Methods:**
1. **Face validity**: Does it "look right" to experts?
2. **Stakeholder review**: Do stakeholders recognize their reality?
3. **Structural validity**: Are relationships correct?
4. **Behavioral validity**: Do trends match observations?

**Validation Process:**
1. Prepare presentation materials:
   - CLD visualization
   - Key feedback loops
   - BOT graphs
   - System narrative
2. Conduct validation workshop:
   - Present system diagram
   - Walk through causal chains
   - Solicit feedback
   - Document concerns and corrections
3. Revise based on input
4. Document validation steps

**Documentation Fields:**
- **Validation Method**: Workshop / Interview / Review
- **Date**: When conducted
- **Participants**: Who provided input
- **Findings**: What was validated or questioned
- **Changes Made**: How diagram was revised

**Tips:**
- Use non-technical language
- Start with familiar parts of system
- Encourage critical feedback
- Note areas of uncertainty
- Iterate as needed

### 5.15 Data Management Tab

**Purpose:** Import, export, and manage ISA data

**Features:**

**Import Data:**
- Upload Excel workbook with ISA data
- Template available for download
- Validates data structure
- Merges with existing data

**Export Data:**
- Download all ISA data as Excel
- Multi-sheet workbook (one per element type)
- Includes metadata and timestamp
- Compatible with re-import

**Clear Data:**
- Reset all ISA data
- Confirmation required
- Cannot be undone (save project first!)

**Quick Actions:**
- View data summary
- Check for orphaned elements
- Verify linkages
- Export to Kumu

**Tips:**
- Export data regularly
- Use consistent naming conventions
- Validate before sharing
- Keep backup copies

---

## 6. CLD Visualization

### 6.1 Purpose

The CLD Visualization module provides an interactive network visualization of your Causal Loop Diagram, allowing you to explore system structure and dynamics.

### 6.2 Generating the CLD

**Prerequisites:**
- Complete ISA Exercises 1-6
- Define connections between elements

**Steps:**
1. Navigate to ISA Data Entry → Exercise 9 OR go directly to CLD Visualization
2. Click "Generate CLD" button
3. Wait for network to render (may take a few seconds for large systems)

### 6.3 Viewing the Network

**Network Components:**
- **Nodes**: System elements (circles)
- **Edges**: Causal relationships (arrows)
- **Colors**: Element types (Drivers=purple, Activities=blue, Pressures=red, etc.)
- **Arrow colors**: Positive links=green, Negative links=red

**Interaction:**
- **Hover**: View node details
- **Click node**: Highlight connections
- **Click edge**: View link details
- **Drag**: Move nodes manually
- **Scroll**: Zoom in/out
- **Click-drag background**: Pan view

### 6.4 Layout Algorithms

**Fruchterman-Reingold (Default):**
- Force-directed layout
- Minimizes edge crossing
- Good for general structure

**Hierarchical:**
- Top-to-bottom organization
- Shows flow from drivers to benefits
- Good for presenting DAPSI(W)R(M) sequence

**Circular:**
- Nodes arranged in circle
- Good for showing feedback loops
- Equal emphasis on all elements

**Changing Layout:**
1. Use layout dropdown menu
2. Select desired algorithm
3. Click "Apply Layout"
4. Network will rearrange

### 6.5 Filtering and Highlighting

**Filter by Element Type:**
- Check/uncheck boxes in legend
- Hide/show element categories
- Simplify complex diagrams

**Highlight Neighbors:**
- Click on node
- Connected nodes highlighted
- Indirect connections dimmed
- Reset by clicking background

**Search:**
- Type element name in search box
- Matching nodes highlighted
- Use to locate specific elements quickly

### 6.6 Network Statistics

**Displayed Metrics:**
- **Nodes**: Total element count
- **Edges**: Total connection count
- **Density**: Proportion of possible connections
- **Average Degree**: Mean connections per node
- **Components**: Number of disconnected sub-networks

**Interpreting Metrics:**
- High density: Highly interconnected system
- Low density: Sparse connections, consider missing links
- Multiple components: Disconnected subsystems
- High degree nodes: Key leverage points

### 6.7 Exporting the CLD

**Export to Image:**
- Go to Export & Reports module
- Select "Export Visualization"
- Choose format (PNG, SVG, PDF, HTML)
- Set dimensions
- Download

**Export to Kumu:**
- Click "Export to Kumu" button
- Copy generated JSON code
- Go to kumu.io
- Create new project and import JSON
- Apply styling (see Kumu Code Style guide in www folder)

---

## 7. Analysis Tools

### 7.1 Loop Detection

**Purpose:** Automatically identify and classify feedback loops in your system

#### 7.1.1 Detecting Loops

**Steps:**
1. Navigate to Analysis Tools → Loop Detection
2. Go to "Detect Loops" tab
3. Set parameters:
   - **Max Loop Length**: 3-8 elements (start with 4-5)
   - **Min Loop Length**: Usually 2-3
4. Click "Detect Loops" button
5. Wait for analysis to complete

**What Happens:**
- Algorithm searches for all closed paths
- Each path returning to start = one loop
- Loops classified by polarity (R or B)
- Results displayed in table

**Tips:**
- Start with shorter max length (4-5)
- Longer loops take more time to compute
- Large systems may have hundreds of loops
- Focus on dominant loops (covered in tab 4)

#### 7.1.2 Loop Classification

**Purpose:** View distribution of reinforcing vs balancing loops

**Reinforcing Loops (R):**
- Amplify change
- Even number of negative links (0, 2, 4...)
- Drive growth or collapse
- Can lead to runaway dynamics
- Examples:
  - Population growth
  - Fish stock collapse (overfishing)
  - Economic growth

**Balancing Loops (B):**
- Seek equilibrium
- Odd number of negative links (1, 3, 5...)
- Stabilize system
- Goal-seeking behavior
- Examples:
  - Predator-prey regulation
  - Price-demand adjustment
  - Homeostasis

**Bar Chart:**
- Green = Reinforcing loops
- Red = Balancing loops
- Shows count of each type

**Interpretation:**
- R-dominated: System prone to growth/collapse
- B-dominated: System seeks stability
- Balanced: Complex dynamics, potential for surprises

#### 7.1.3 Loop Details

**Purpose:** Examine specific loops in detail

**Loop Table Columns:**
- **Loop ID**: Unique identifier
- **Type**: R or B
- **Length**: Number of elements
- **Elements**: Element IDs in loop
- **Polarity Count**: Number of negative links

**Viewing Details:**
1. Select loop from dropdown
2. View loop properties:
   - Element sequence
   - Link polarities
   - Total polarity
3. See loop path description

**Loop Narrative:**
- Read the causal chain
- Identify the "story" of the loop
- Consider time lags
- Think about intervention points

#### 7.1.4 Dominant Loops

**Purpose:** Identify the most influential loops

**Dominance Metrics:**
- **Loop Occurrence**: How many times each loop appears
- **Element Participation**: How many loops each element participates in

**Most Influential Loops:**
- Sorted by occurrence
- These loops have strongest effect on system behavior
- Target for management interventions

**Most Connected Elements:**
- Sorted by participation count
- Elements in many loops = leverage points
- Changes here ripple through system

**Strategic Implications:**
- Focus interventions on dominant loops
- Target highly connected elements
- Consider multiplier effects
- Anticipate unintended consequences

#### 7.1.5 Export Loops

**Purpose:** Export loop analysis results

**Excel Export Includes:**
- Loop inventory (all detected loops)
- Loop classification (R vs B)
- Dominance rankings
- Element participation
- Summary statistics

**Uses:**
- Share with stakeholders
- Include in reports
- Further analysis in Excel/R
- Archive analysis results

### 7.2 Network Metrics

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- Centrality measures (degree, betweenness, closeness)
- Network density and clustering
- Key node identification
- Structural importance metrics
- Community detection

### 7.3 BOT Analysis

**Status:** Placeholder (basic functionality exists in ISA Exercise 11)

**Planned Features:**
- Advanced time series analysis
- Trend detection
- Regime shift identification
- Cross-correlation analysis
- Forecasting tools

### 7.4 Simplification Tools

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- CLD simplification algorithms
- Aggregation of similar nodes
- Edge filtering by strength
- Core loop extraction
- Modular decomposition

---

## 8. Response & Validation

### 8.1 Response Measures

**Purpose:** Document, prioritize, and plan management interventions

#### 8.1.1 Response Register

**Purpose:** Maintain inventory of potential management responses

**Adding Response Measures:**
1. Navigate to Response & Validation → Response Measures
2. Go to "Response Register" tab
3. Fill in form:
   - **Measure ID**: Auto-generated (e.g., RM001)
   - **Name**: Short descriptive name
   - **Type**: Regulatory / Economic / Advisory / Technical
   - **Description**: What does this measure do?
   - **Mechanism**: How will it work?
   - **Target Element**: Which system element does it address?
   - **Effectiveness**: High / Medium / Low / Unknown
   - **Feasibility**: High / Medium / Low
   - **Cost**: Scale 1-10 (1=very low, 10=very high)
   - **Responsible Party**: Who implements?
   - **Barriers**: What obstacles exist?
   - **Notes**: Additional information
4. Click "Add Measure"

**Response Types:**
- **Regulatory**: Laws, regulations, permits, zoning
- **Economic**: Taxes, subsidies, payments, incentives
- **Advisory**: Education, guidance, voluntary agreements
- **Technical**: Research, monitoring, technology

**Examples:**
- Catch quotas (Regulatory)
- Marine protected areas (Regulatory)
- Ecosystem service payments (Economic)
- Gear restrictions (Technical/Regulatory)
- Stakeholder forums (Advisory)
- Best practice guidelines (Advisory)

**CRUD Operations:**
- **View**: Table displays all measures
- **Edit**: Select row, modify form, click "Update"
- **Delete**: Select row(s), click "Delete", confirm

#### 8.1.2 Impact Assessment

**Purpose:** Link response measures to system problems they address

**Adding Impact Linkages:**
1. Go to "Impact Assessment" tab
2. Select response measure from dropdown
3. Select target problem (pressure, activity, driver)
4. Choose expected impact:
   - Eliminates
   - Significantly reduces
   - Moderately reduces
   - Slightly reduces
   - No effect
   - Increases (unintended)
5. Add supporting evidence
6. Click "Add Impact Linkage"

**Impact Assessment Matrix:**
- Rows = Response measures
- Columns = Problems addressed
- Cells = Impact level

**Uses:**
- Identify most effective measures
- Reveal measures with multiple benefits
- Spot potential conflicts
- Prioritize based on impact

#### 8.1.3 Prioritization

**Purpose:** Rank response measures using multi-criteria analysis

**Criteria:**
- **Effectiveness**: Expected impact on target problem
- **Feasibility**: Technical, political, social feasibility
- **Cost**: Financial and resource requirements

**Setting Criteria Weights:**
1. Go to "Prioritization" tab
2. Adjust sliders:
   - Effectiveness weight (0-100%)
   - Feasibility weight (0-100%)
   - Cost weight (0-100%)
3. Weights must sum to 100%
4. Click "Recalculate Priorities"

**Priority Score Calculation:**
```
Priority Score = (w_eff × Effectiveness/3) + (w_feas × Feasibility/3) + (w_cost × Cost/10)
```

Where:
- w_eff, w_feas, w_cost = user-defined weights
- Effectiveness, Feasibility: High=3, Medium=2, Low=1
- Cost: inverse scale (low cost = high score)

**Interpreting Scores:**
- Score range: 0-100
- Higher = higher priority
- Ranked in descending order

**Priority Categories:**
- **High Priority**: Score > 70
- **Medium Priority**: Score 40-70
- **Low Priority**: Score < 40

**Prioritization Matrix:**
- Scatter plot: Effectiveness vs Feasibility
- Point size: Cost (larger = more expensive)
- Color: Priority level
- Quadrant interpretation:
  - Top-right: "Quick wins" (high effectiveness, high feasibility)
  - Top-left: "Major projects" (high effectiveness, low feasibility)
  - Bottom-right: "Fill-ins" (low effectiveness, high feasibility)
  - Bottom-left: "Avoid" (low effectiveness, low feasibility)

**Sensitivity Analysis:**
- Adjust weights to test robustness
- See which measures remain high priority
- Identify measures sensitive to criteria

#### 8.1.4 Implementation Plan

**Purpose:** Schedule and track implementation of priority measures

**Adding Milestones:**
1. Go to "Implementation Plan" tab
2. Select response measure
3. Add milestone:
   - **Description**: What needs to happen (e.g., "Draft regulation")
   - **Target Date**: Planned completion
   - **Status**: Not Started / In Progress / Completed / Delayed
   - **Notes**: Progress updates
4. Click "Add Milestone"

**Timeline View:**
- Gantt-style visualization
- Measures on y-axis
- Time on x-axis
- Color-coded by status

**Tracking Progress:**
- Update milestone status regularly
- Add actual completion dates
- Note delays and reasons
- Adjust subsequent milestones

**Implementation Checklist:**
- [ ] Secure funding
- [ ] Obtain approvals
- [ ] Engage stakeholders
- [ ] Develop detailed design
- [ ] Pilot test
- [ ] Full implementation
- [ ] Monitor and evaluate
- [ ] Adapt based on results

#### 8.1.5 Export Response Data

**Purpose:** Export response measures analysis

**Excel Export Includes:**
- Response measure register
- Impact assessment matrix
- Priority scores
- Implementation plan
- Summary statistics

**Uses:**
- Management plan documentation
- Stakeholder reporting
- Decision support
- Archive analysis

### 8.2 Scenario Builder

**Status:** Placeholder (not yet implemented)

**Planned Features:**
- What-if scenario creation
- Driver manipulation
- Response combination testing
- Scenario comparison
- Impact prediction
- Uncertainty analysis

**Use Cases:**
- Test policy combinations
- Explore climate change impacts
- Assess adaptive strategies
- Communicate trade-offs

### 8.3 Validation

**Status:** Placeholder (basic functionality exists in ISA Exercise 12)

**Planned Features:**
- Structured validation protocols
- Stakeholder feedback forms
- Expert elicitation tools
- Confidence scoring
- Validation documentation
- Version control

---

## 9. Export & Reports

### 9.1 Data Export

**Purpose:** Export project data in various formats for external use

#### 9.1.1 Export Formats

**Excel (.xlsx):**
- **Best for:** Data analysis, sharing with non-R users
- **Structure:** Multi-sheet workbook
  - Each sheet = one data component
  - Formatted tables with headers
  - Includes metadata
- **Sheets:**
  - Project info
  - Metadata
  - Goods & Benefits
  - Ecosystem Services
  - Marine Processes
  - Pressures
  - Activities
  - Drivers
  - CLD Nodes
  - CLD Edges
  - CLD Loops
  - BOT Data
  - Stakeholders
  - Response Measures
  - Analysis Results

**CSV (.csv):**
- **Best for:** Simple data tables, import to other tools
- **Limitation:** Exports only one main table (Goods & Benefits by default)
- **Uses:** GIS integration, statistical software, database import

**JSON (.json):**
- **Best for:** Web applications, APIs, structured data
- **Structure:** Hierarchical nested format
- **Uses:** Integration with other software, archiving, version control

**R Data (.RData):**
- **Best for:** Re-opening in R, preserving data structures
- **Structure:** Complete R object with all list structures
- **Uses:** Continuing analysis in R, sharing with R users

#### 9.1.2 Selecting Components

**Available Components:**
- [ ] Project Metadata
- [ ] PIMS Data
- [ ] ISA Data
- [ ] CLD Data
- [ ] Analysis Results
- [ ] Response Measures

**Tips:**
- Select only needed components to reduce file size
- Include metadata for context
- Export regularly as backup

#### 9.1.3 Export Process

1. Navigate to Export & Reports
2. Go to "Export Data" box
3. Select format from dropdown
4. Check components to include
5. Click "Download Data" button
6. Save file with descriptive name (include date)

### 9.2 Visualization Export

**Purpose:** Export CLD visualizations in various formats

#### 9.2.1 Export Formats

**HTML (.html):**
- **Best for:** Interactive sharing, web embedding
- **Features:**
  - Fully interactive (zoom, pan, hover)
  - Works in any browser
  - Self-contained file
  - Navigation buttons
  - Legend included
- **Uses:** Presentations, websites, stakeholder review

**PNG (.png):**
- **Best for:** Reports, presentations, publications
- **Features:**
  - Raster image (resolution-dependent)
  - Transparent background option
  - High resolution (150 dpi)
- **Uses:** Documents, slides, quick sharing

**SVG (.svg):**
- **Best for:** Publications, posters, scalable graphics
- **Features:**
  - Vector format (infinite zoom)
  - Small file size
  - Editable in Illustrator/Inkscape
  - Crisp at any size
- **Uses:** Scientific publications, high-quality prints

**PDF (.pdf):**
- **Best for:** Formal reports, printing
- **Features:**
  - Vector format
  - Universal compatibility
  - Embeds in documents
- **Uses:** Report appendices, archival

#### 9.2.2 Setting Dimensions

**Width & Height:**
- Default: 1200 × 900 pixels
- Range: 400-4000 pixels
- **Tips:**
  - Larger = higher quality but bigger files
  - Square (1:1) for social media
  - Widescreen (16:9) for presentations
  - Portrait (9:16) for posters

**Recommended Sizes:**
- Presentation slide: 1920 × 1080 (HD)
- Full-page report: 2400 × 1800
- Social media: 1200 × 1200
- Poster: 3600 × 2700

#### 9.2.3 Export Process

1. Navigate to Export & Reports
2. Go to "Export Visualizations" box
3. Select format
4. Set width and height
5. Click "Download Visualization"
6. Wait for rendering (may take 5-10 seconds)
7. Save file

**Troubleshooting:**
- If export fails, try smaller dimensions
- Ensure CLD has been generated first
- Check browser doesn't block downloads
- For HTML, open in browser to test

### 9.3 Report Generation

**Purpose:** Generate comprehensive analysis reports

#### 9.3.1 Report Types

**Executive Summary:**
- **Length:** 2-3 pages
- **Audience:** Decision-makers, managers
- **Content:**
  - Project overview
  - Key findings (bullet points)
  - System statistics
  - High-priority recommendations
- **Use:** Board presentations, policy briefs

**Technical Report:**
- **Length:** 10-15 pages
- **Audience:** Analysts, researchers
- **Content:**
  - Detailed DAPSI(W)R(M) analysis
  - Element counts by type
  - Network metrics
  - Feedback loop analysis
  - Data tables
- **Use:** Scientific documentation, peer review

**Stakeholder Presentation:**
- **Length:** 5-7 pages
- **Audience:** Community, stakeholders
- **Content:**
  - System overview (plain language)
  - Key insights (visual)
  - Opportunities for action
  - Engagement opportunities
- **Use:** Community meetings, workshops

**Full Project Report:**
- **Length:** 20-30 pages
- **Audience:** Project team, funders
- **Content:**
  - Complete project documentation
  - All data tables
  - All analyses
  - Visualizations
  - Recommendations
  - Appendices
- **Use:** Final deliverables, archiving

#### 9.3.2 Report Formats

**HTML:**
- **Best for:** Online viewing, interactive
- **Features:**
  - Table of contents
  - Floating TOC navigation
  - Embedded plots
  - Hyperlinks
- **Opens in:** Web browser

**PDF:**
- **Best for:** Printing, formal distribution
- **Features:**
  - Professional formatting
  - Page numbers
  - Bookmarks
- **Requires:** Pandoc + LaTeX installation

**Word (.docx):**
- **Best for:** Editing, collaboration
- **Features:**
  - Editable text and tables
  - Compatible with MS Word
  - Easy formatting changes
- **Requires:** Pandoc installation

#### 9.3.3 Report Options

**Include Visualizations:**
- [x] Checked: Embeds CLD images
- [ ] Unchecked: Text and tables only
- **Note:** Increases file size and generation time

**Include Data Tables:**
- [x] Checked: Includes data tables in report
- [ ] Unchecked: Summary statistics only
- **Note:** Full tables make report longer but more complete

#### 9.3.4 Generation Process

1. Navigate to Export & Reports
2. Go to "Generate Report" box
3. Select report type
4. Select format (HTML/PDF/Word)
5. Check options (visualizations, data tables)
6. Click "Generate Report" button
7. Wait for generation (10-30 seconds)
   - Progress modal shows "Generating..."
8. When complete, modal shows "Download Report" button
9. Click to download report file
10. Close modal

**Requirements:**
- R package `rmarkdown` (installed with app)
- For PDF: Pandoc + LaTeX (tinytex)
- For Word: Pandoc

**Troubleshooting:**
- If generation fails, try simpler report type
- Check error message in notification
- Try HTML format first (most reliable)
- For PDF errors, install tinytex: `tinytex::install_tinytex()`

---

## 10. Workflows & Best Practices

### 10.1 Recommended Workflow

**Phase 1: Project Setup (Days 1-2)**
1. Create project in PIMS
2. Define focal issue and scope
3. Add stakeholders
4. Set up engagement plan

**Phase 2: ISA Data Entry (Days 3-10)**
1. Complete Exercise 0 (Scoping)
2. Identify Goods & Benefits (Ex 1)
3. Map Ecosystem Services (Ex 2a)
4. Identify Marine Processes (Ex 2b)
5. Document Pressures (Ex 3)
6. List Activities (Ex 4)
7. Identify Drivers (Ex 5)
8. Close loops (Ex 6)
9. Generate CLD (Ex 7-9)

**Phase 3: Analysis (Days 11-15)**
1. Visualize CLD
2. Detect feedback loops
3. Identify dominant loops
4. Create BOT graphs (Ex 10-11)
5. Analyze system dynamics

**Phase 4: Validation (Days 16-18)**
1. Prepare validation materials
2. Conduct stakeholder workshop (Ex 12)
3. Revise based on feedback
4. Finalize CLD

**Phase 5: Response Planning (Days 19-22)**
1. Brainstorm response measures
2. Add to Response Register
3. Assess impacts
4. Prioritize measures
5. Create implementation plan

**Phase 6: Reporting (Days 23-25)**
1. Export data and visualizations
2. Generate reports
3. Prepare presentations
4. Share with stakeholders

### 10.2 Participatory Approach

**Pre-Workshop:**
- Gather background data
- Identify key stakeholders
- Pre-populate some elements (optional)

**Workshop Day 1: System Mapping**
- Exercise 0: Define scope together
- Exercises 1-5: Brainstorm elements
  - Use sticky notes or digital whiteboard
  - Group by element type
  - Prioritize most important
- Enter data in tool during breaks

**Workshop Day 2: Connections**
- Exercise 6-8: Define connections
  - Draw links between elements
  - Discuss causal mechanisms
  - Agree on polarity
- Generate CLD
- Review and refine

**Workshop Day 3: Analysis & Response**
- Present loop detection results
- Discuss system behavior
- Identify leverage points
- Brainstorm response measures
- Prioritize as group

**Post-Workshop:**
- Finalize documentation
- Generate validation report
- Circulate for final review
- Prepare final outputs

### 10.3 Data Quality Tips

**Element Naming:**
- Be specific and concrete
- Use consistent terminology
- Avoid jargon (or define in notes)
- Keep names short (3-5 words)

**Connection Quality:**
- Only include direct causal relationships
- Specify time lags in notes
- Note uncertainty levels
- Cite evidence where possible

**Completeness:**
- Balance breadth and depth
- 20-50 elements often sufficient
- Focus on focal issue
- Can always add more later

**Documentation:**
- Use Description fields liberally
- Note data sources
- Record assumptions
- Document stakeholder input

### 10.4 Common Pitfalls to Avoid

**Scope Creep:**
- Keep focused on focal issue
- Don't try to map entire ecosystem
- Can create multiple projects if needed

**Over-Connection:**
- Not every element connects to every other
- Focus on strong, direct relationships
- Too many weak links obscure structure

**Under-Connection:**
- Don't miss important feedbacks
- Consider indirect pathways
- Ask "what else influences this?"

**Biased Perspective:**
- Include diverse stakeholders
- Check for missing voices
- Challenge assumptions
- Seek contrary evidence

**Analysis Paralysis:**
- Start simple, add complexity
- Iterate rather than perfect
- Use tool to facilitate discussion
- Accept uncertainty

**Forgetting the Goal:**
- Keep focal issue central
- Prioritize actionable insights
- Connect to decision needs
- Communicate clearly

### 10.5 Saving and Version Control

**Regular Saving:**
- Save after each major data entry session
- Use descriptive filenames: `ProjectName_YYYYMMDD.rds`
- Keep previous versions (don't overwrite)

**Backup Strategy:**
- Save to multiple locations
- Cloud storage (Dropbox, OneDrive)
- Email to self after workshops
- Export to Excel as backup

**Version Naming:**
- Use semantic versioning: v1.0, v1.1, v2.0
- Or date-based: 2025-10-20
- Add suffix for milestones: "pre-validation", "final"

**Change Log:**
- Keep text file documenting changes
- Note what was added/modified/deleted
- Record reason for changes
- Track stakeholder feedback

---

## 11. Troubleshooting

### 11.1 Common Issues

#### Issue: App Won't Start

**Symptoms:**
- Error messages on startup
- R console shows error
- Browser doesn't open

**Solutions:**
1. Check R version (need 4.0+): `R.version.string`
2. Update packages: `update.packages()`
3. Reinstall required packages (see global.R)
4. Check for port conflicts (try different port)
5. Clear R workspace: `rm(list=ls())`
6. Restart R session

#### Issue: Data Not Saving

**Symptoms:**
- Click "Save" but data disappears on reload
- Load project button shows old data

**Solutions:**
1. Check you clicked "Save" in form (not just filled fields)
2. Verify project data reactive is updating
3. Check R console for error messages
4. Use "Save Project" in sidebar (not browser save)
5. Try exporting to Excel as workaround

#### Issue: CLD Won't Generate

**Symptoms:**
- "Generate CLD" button does nothing
- Error message appears
- Network viewer stays empty

**Solutions:**
1. Ensure you have elements in Ex 1-5
2. Check you have defined connections (Ex 6-8)
3. Look for orphaned elements (no connections)
4. Verify element IDs are unique
5. Check R console for error details
6. Try simplifying (remove some elements temporarily)

#### Issue: Loop Detection Fails

**Symptoms:**
- "Detect Loops" button does nothing
- Analysis takes forever
- Error: "out of memory"

**Solutions:**
1. Reduce max loop length to 4 or 5
2. Simplify CLD (reduce elements/connections)
3. Increase R memory: `memory.limit(size=8000)` (Windows)
4. Run on more powerful computer
5. Focus on subsystem of interest

#### Issue: Export Fails

**Symptoms:**
- Download button does nothing
- Error message on export
- File is empty or corrupt

**Solutions:**
1. Check browser allows downloads
2. Try different export format
3. Reduce data size (uncheck some components)
4. For reports, try HTML first (most robust)
5. Check PDF prerequisites (Pandoc, LaTeX)
6. Check R console for error messages

#### Issue: Visualization Too Slow

**Symptoms:**
- CLD rendering very slow
- Browser becomes unresponsive
- Interactions laggy

**Solutions:**
1. Reduce number of elements in view
2. Use filters to show subset
3. Export to static image instead
4. Use simpler layout algorithm
5. Close other browser tabs
6. Try different browser (Chrome usually faster)

### 11.2 Error Messages

**"'names' attribute must be same length as vector"**
- **Cause:** Empty data frame passed to setNames()
- **Solution:** Ensure data exists before exporting/analyzing
- **Fixed in:** October 20, 2025 update

**"Object not found"**
- **Cause:** Reactive value not yet initialized
- **Solution:** Check prerequisites (e.g., generate CLD before loop detection)

**"Argument is of length zero"**
- **Cause:** Operation on empty vector
- **Solution:** Add data before running analysis

**"Cannot open file"**
- **Cause:** File path issue or permissions
- **Solution:** Check file path, ensure write permissions

### 11.3 Performance Optimization

**For Large Systems (>100 elements):**
- Use filters to view subsets
- Export to Kumu for complex visualization
- Limit max loop length (≤5)
- Close other applications
- Run overnight batch jobs for intensive analyses

**For Workshops:**
- Pre-load example data for demos
- Test all features before workshop
- Have backup (PDF printouts)
- Use stable internet connection
- Save frequently during data entry

### 11.4 Getting Help

**In-App Help:**
- Click ? icon on any exercise tab
- View tooltips (hover over labels)
- Check Data Management tab documentation

**External Resources:**
- User Guide (this document): www/ISA_User_Guide.md
- Kumu Code Style: www/Kumu_Code_Style.txt
- Module Status: MODULE_STATUS.md
- Example Data: data/EXAMPLE_README.md

**Technical Support:**
- Check GitHub issues
- Contact MarineSABRES team
- Consult R Shiny documentation
- Review package documentation

---

## 12. Glossary

### A

**Activity**
Human actions that generate pressures on marine systems (e.g., fishing, shipping, coastal development).

**Adjacency Matrix**
Mathematical representation of network connections; rows and columns are nodes, cells indicate edges.

### B

**Balancing Loop (B)**
Feedback loop that seeks equilibrium and resists change. Characterized by odd number of negative links. Also called negative feedback loop.

**BOT (Behaviour Over Time)**
Graphs showing how system variables change over time. Used to identify trends, cycles, and regime shifts.

### C

**Causal Loop Diagram (CLD)**
Visual representation of system structure showing elements (nodes) and causal relationships (edges) with polarity.

**Centrality**
Measure of node importance in network. Types include degree (number of connections), betweenness (bridging position), closeness (average distance to others).

### D

**DAPSI(W)R(M) Framework**
Drivers-Activities-Pressures-State changes-(Welfare impacts)-Responses-(Measures). Causal chain framework for analyzing human impacts on marine ecosystems and management responses.

**Driver**
Underlying socio-economic factors that motivate human activities (e.g., economic growth, population, technology, policy).

### E

**Ecosystem Service**
Benefits people obtain from ecosystems. Categories: Provisioning (food, water), Regulating (climate, water quality), Cultural (recreation, aesthetic), Supporting (nutrient cycling, habitat).

**Edge**
Connection or link between two nodes in a network. In CLD, represents causal relationship with polarity (+ or -).

### F

**Feedback Loop**
Closed path in CLD where a change propagates through system and returns to affect original variable. Can be reinforcing (R) or balancing (B).

**Focal Issue**
Main management question or problem being addressed in the SES analysis.

### G

**Goods and Benefits**
Specific benefits that people derive from ecosystem services (e.g., fish catch, storm protection, recreation).

### I

**IAP2 Spectrum**
International Association for Public Participation spectrum of engagement levels: Inform, Consult, Involve, Collaborate, Empower.

**ISA (Integrated Systems Analysis)**
Structured participatory method for mapping social-ecological systems using 13 exercises following DAPSI(W)R(M) framework.

### K

**Kumu**
Web-based platform (kumu.io) for creating interactive visualizations of networks and systems maps. Used for advanced CLD visualization.

### L

**Leverage Point**
Place in system where small intervention can produce large change. High-leverage points often involve system structure, delays, or feedback loops.

**Link**
See Edge.

**Loop Dominance**
Relative strength or influence of different feedback loops. Dominant loops drive overall system behavior.

### M

**Marine Process**
Ecological processes and functions that generate ecosystem services (e.g., primary production, nutrient cycling, habitat provision).

**MSFD**
Marine Strategy Framework Directive (EU). Provides standardized pressure categories.

### N

**Negative Link (-)**
Causal relationship where variables move in opposite directions. If A increases, B decreases (all else equal).

**Node**
Element or variable in a network or CLD. Represents measurable quantity or concept.

### P

**PIMS**
Process & Information Management System. Project management component including stakeholder management, resources, data, and evaluation.

**Polarity**
Sign of causal relationship: Positive (+) means variables move together; Negative (-) means they move in opposite directions.

**Positive Link (+)**
Causal relationship where variables move in same direction. If A increases, B increases (all else equal).

**Power-Interest Grid**
Stakeholder analysis matrix classifying stakeholders by power (influence) and interest (stake) to guide engagement strategy.

**Pressure**
Direct human-induced stress on marine system (e.g., fishing mortality, nutrient input, habitat disturbance).

### R

**Reinforcing Loop (R)**
Feedback loop that amplifies change. Characterized by even number of negative links (0, 2, 4...). Also called positive feedback loop.

**Response (Measure)**
Management intervention designed to address drivers, activities, or pressures. Part of DAPSI(W)R(M) framework.

### S

**SES (Social-Ecological System)**
Integrated system of people and nature, emphasizing human-environment interactions and feedbacks.

**State (Change)**
Condition of ecosystem or its components (e.g., water quality, species abundance, habitat extent). In DAPSI(W)R(M), changes result from pressures.

**Stakeholder**
Individual or organization with interest or stake in the system. May be affected by or able to affect outcomes.

### T

**Time Lag**
Delay between cause and effect in causal relationship. Important for understanding system dynamics.

### V

**Validation**
Process of verifying system representation with stakeholders, experts, and empirical data.

**Variable**
See Node.

### W

**Welfare (Impact)**
Effects of state changes on human well-being (e.g., income, health, cultural values). In DAPSI(W)R(M), connects ecosystem state to human benefits.

**Workflow**
Recommended sequence of steps for conducting SES analysis from project setup through reporting.

---

## Appendix A: Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Save Project | Ctrl+S (if implemented) |
| Zoom In (CLD) | Scroll up / + |
| Zoom Out (CLD) | Scroll down / - |
| Reset Zoom | Double-click background |
| Pan View | Click and drag background |
| Select Multiple Rows | Shift+Click |

---

## Appendix B: File Formats

### RDS Format (.rds)
- Native R data format
- Preserves all data structures
- Compact file size
- Can only be opened in R

### Excel Format (.xlsx)
- Multi-sheet workbook
- Each sheet = one data table
- Can be edited in Excel
- Compatible with re-import

### JSON Format (.json)
- Text-based structured data
- Hierarchical organization
- Human-readable
- Web-compatible

### CSV Format (.csv)
- Plain text comma-separated
- Simple table format
- Universal compatibility
- No metadata preservation

---

## Appendix C: Color Schemes

### Element Type Colors (CLD):
- **Drivers**: Purple (#9B59B6)
- **Activities**: Blue (#3498DB)
- **Pressures**: Red (#E74C3C)
- **State**: Yellow (#F39C12)
- **Welfare**: Orange (#E67E22)
- **Responses**: Green (#27AE60)

### Link Polarity Colors:
- **Positive (+)**: Green (#06D6A0)
- **Negative (-)**: Red (#E63946)

### Loop Type Colors:
- **Reinforcing**: Green (#06D6A0)
- **Balancing**: Red (#E63946)

### Priority Colors:
- **High**: Green
- **Medium**: Yellow
- **Low**: Orange

---

## Appendix D: Quick Reference Card

### Essential Steps:
1. **Setup**: PIMS → Project Setup
2. **Stakeholders**: PIMS → Stakeholders → Add
3. **Elements**: ISA → Ex 1-5 → Add elements
4. **Connections**: ISA → Ex 6-8 → Define links
5. **Visualize**: CLD Visualization → Generate
6. **Analyze**: Analysis Tools → Loop Detection
7. **Respond**: Response Measures → Add measures → Prioritize
8. **Export**: Export & Reports → Download

### Critical Buttons:
- **Save Project**: Sidebar (bottom)
- **Add** (element): Form in each ISA exercise
- **Generate CLD**: CLD Visualization module
- **Detect Loops**: Analysis Tools → Loop Detection
- **Export to Excel**: Various modules
- **Download Data**: Export & Reports

### Key Concepts:
- **R loop**: Amplifies change (growth/collapse)
- **B loop**: Seeks balance (stability)
- **+ link**: Variables move together
- **- link**: Variables move opposite

---

## Document Information

**Document Title:** MarineSABRES SES Tool - Complete User Guide
**Version:** 1.0
**Date:** October 20, 2025
**Authors:** MarineSABRES Development Team
**Contact:** [Your contact information]
**License:** [Your license]

**Revision History:**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-10-20 | Initial comprehensive guide | MarineSABRES Team |

**Acknowledgments:**
This tool and guide were developed as part of the MarineSABRES Horizon Europe project. We acknowledge contributions from domain experts, stakeholders, and the R Shiny community.

**Citation:**
If using this tool in research or reports, please cite as:
```
MarineSABRES Team (2025). MarineSABRES Social-Ecological Systems Analysis Tool: User Guide. Version 1.0.
```

---

**End of User Guide**
