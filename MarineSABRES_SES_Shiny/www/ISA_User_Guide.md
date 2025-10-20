# ISA Data Entry Module - User Guide

## MarineSABRES Social-Ecological Systems Analysis Tool

**Version:** 1.0
**Last Updated:** October 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [The DAPSI(W)R(M) Framework](#the-dapsiwrm-framework)
4. [Step-by-Step Workflow](#step-by-step-workflow)
5. [Exercise-by-Exercise Guide](#exercise-by-exercise-guide)
6. [Working with Kumu](#working-with-kumu)
7. [Data Management](#data-management)
8. [Tips and Best Practices](#tips-and-best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Glossary](#glossary)

---

## Introduction

### What is the ISA Module?

The Integrated Systems Analysis (ISA) Data Entry module is a comprehensive tool for analyzing marine social-ecological systems using the DAPSI(W)R(M) framework. It guides you through a systematic 13-exercise process to:

- Map the structure of your marine social-ecological system
- Identify causal relationships between human activities and ecosystem changes
- Understand feedback loops and system dynamics
- Identify leverage points for policy interventions
- Create visual Causal Loop Diagrams (CLDs)
- Validate findings with stakeholders

### Who Should Use This Tool?

- Marine ecosystem managers and policy makers
- Environmental scientists and researchers
- Coastal zone planners
- Conservation practitioners
- Stakeholder groups engaged in marine management
- Students studying marine social-ecological systems

### Key Features

- **Structured workflow:** 13 exercises guide you systematically through the analysis
- **Built-in help:** Context-sensitive help for every exercise
- **Data export:** Export to Excel and Kumu visualization software
- **BOT graphs:** Visualize temporal dynamics with Behaviour Over Time graphs
- **Flexible:** Import/export data, save progress, collaborate with teams

---

## Getting Started

### Accessing the ISA Module

1. Launch the MarineSABRES Shiny application
2. From the sidebar menu, select **"ISA Data Entry"**
3. You'll see the main ISA interface with exercise tabs

### Interface Overview

The ISA module interface consists of:

- **Header:** Title and framework description with main help button
- **Exercise Tabs:** 13 exercises plus BOT graphs and Data Management
- **Help Buttons:** Click the help icon (?) on any exercise for detailed guidance
- **Input Forms:** Dynamic forms for entering data
- **Data Tables:** View your entered data in sortable, searchable tables
- **Save Buttons:** Save your work after completing each exercise

### Getting Help

**Main Framework Guide:** Click the "ISA Framework Guide" button at the top for an overview of DAPSI(W)R(M).

**Exercise-Specific Help:** Click the "Help" button within each exercise tab for detailed instructions, examples, and tips.

---

## The DAPSI(W)R(M) Framework

### Overview

DAPSI(W)R(M) is a causal framework for analyzing marine social-ecological systems:

- **D** - **Drivers:** Underlying forces motivating human activities (economic, social, technological, political)
- **A** - **Activities:** Human uses of marine and coastal environments
- **P** - **Pressures:** Direct stressors on the marine environment
- **S** - **State Changes:** Changes in ecosystem condition, represented through:
  - **W** - **(Impact on) Welfare:** Goods and Benefits derived from the ecosystem
  - **ES** - **Ecosystem Services:** Benefits ecosystems provide to people
  - **MPF** - **Marine Processes & Functioning:** Biological, chemical, physical processes
- **R** - **Responses:** Societal actions to address problems
- **M** - **Measures:** Policy interventions and management actions

### The Causal Chain

The framework represents a causal chain:

```
Drivers → Activities → Pressures → State Changes (MPF → ES → Welfare) → Responses
    ↑                                                                         ↓
    └─────────────────────── Feedback Loop ───────────────────────────────────┘
```

### Why DAPSI(W)R(M)?

- **Systematic:** Ensures comprehensive coverage of all system components
- **Causal:** Makes explicit links between human actions and ecosystem changes
- **Circular:** Captures feedback loops between ecosystem and society
- **Policy-relevant:** Links directly to intervention points (Responses/Measures)
- **Widely used:** Standard framework in European marine policy (MSFD, WFD)

---

## Step-by-Step Workflow

### Recommended Sequence

Follow the exercises in order for best results:

**Phase 1: Scoping (Exercise 0)**
- Define your case study boundaries and context

**Phase 2: Building the Causal Chain (Exercises 1-5)**
- Work backwards from welfare impacts to root drivers
- Exercise 1: Goods & Benefits (what people value)
- Exercise 2a: Ecosystem Services (how ecosystems provide benefits)
- Exercise 2b: Marine Processes (underlying ecological functions)
- Exercise 3: Pressures (stressors on the ecosystem)
- Exercise 4: Activities (human uses of the marine environment)
- Exercise 5: Drivers (forces motivating activities)

**Phase 3: Closing the Loop (Exercise 6)**
- Connect drivers back to goods & benefits to create feedback loops

**Phase 4: Visualization (Exercises 7-9)**
- Create Causal Loop Diagrams in Kumu
- Export and refine your visual model

**Phase 5: Analysis and Validation (Exercises 10-12)**
- Refine your model (clarifying)
- Identify leverage points
- Validate with stakeholders

**Ongoing: BOT Graphs**
- Add temporal data whenever available
- Use to validate causal hypotheses

### Time Requirements

**Quick analysis:** 4-8 hours (simplified case study, small team)

**Comprehensive analysis:** 2-4 days (complex case study, stakeholder engagement)

**Full participatory process:** 1-2 weeks (multiple workshops, extensive validation)

### Working with Teams

**Individual work:**
- One person enters data based on literature review and expert knowledge

**Collaborative work:**
- Export/import Excel files to share data
- Use Kumu's collaborative features for CLD development
- Conduct workshops to gather input for exercises

---

## Exercise-by-Exercise Guide

### Exercise 0: Unfolding Complexity and Impacts on Welfare

**Purpose:** Set the context and boundaries for your analysis.

**What to Enter:**
- Case Study Name
- Brief Description
- Geographic Scope (e.g., "Baltic Sea", "North Atlantic coast")
- Temporal Scope (e.g., "2000-2024")
- Welfare Impacts (initial observations)
- Key Stakeholders

**Tips:**
- Be comprehensive but concise
- Consider diverse perspectives (environmental, economic, social, cultural)
- Include both benefits and costs
- List all affected and decision-making stakeholders

**Example:**
```
Case: Baltic Sea Commercial Fisheries
Geographic Scope: Baltic Sea basin
Temporal Scope: 2000-2024
Welfare Impacts: Fish catch income, employment, food security,
                 cultural heritage, declining stocks
Stakeholders: Commercial fishers, coastal communities, processors,
              consumers, NGOs, fisheries managers, EU policy makers
```

---

### Exercise 1: Specifying Goods and Benefits (G&B)

**Purpose:** Identify what people value from the marine ecosystem.

**What to Enter for Each Good/Benefit:**
- **Name:** Clear, specific name (e.g., "Commercial cod catch")
- **Type:** Provisioning / Regulating / Cultural / Supporting
- **Description:** What this benefit provides
- **Stakeholder:** Who benefits?
- **Importance:** High / Medium / Low
- **Trend:** Increasing / Stable / Decreasing / Unknown

**How to Use:**
1. Click "Add Good/Benefit"
2. Fill in all fields
3. Click "Save Exercise 1" to update the table
4. Each G&B automatically gets a unique ID (GB001, GB002, etc.)

**Examples:**

| Name | Type | Stakeholder | Importance |
|------|------|------------|------------|
| Commercial fish landings | Provisioning | Fishers, consumers | High |
| Coastal recreation | Cultural | Tourists, residents | High |
| Storm surge protection | Regulating | Coastal property owners | High |
| Carbon sequestration | Regulating | Global society | Medium |

**Tips:**
- Be specific: "Commercial cod fishery" not just "fishing"
- Include both marketed (fish sales) and non-marketed (recreation) benefits
- Consider benefits to different stakeholder groups
- Think about synergies and trade-offs

---

### Exercise 2a: Ecosystem Services (ES) affecting Goods and Benefits

**Purpose:** Identify the ecosystem's capacity to generate benefits.

**What to Enter for Each Ecosystem Service:**
- **Name:** Name of the service
- **Type:** Service classification
- **Description:** How it functions
- **Linked to G&B:** Select from dropdown (goods/benefits from Ex. 1)
- **Mechanism:** How does this service produce the benefit?
- **Confidence:** High / Medium / Low

**Understanding ES vs G&B:**
- **Ecosystem Service:** The potential/capacity (e.g., "Fish stock productivity")
- **Good/Benefit:** The realized benefit (e.g., "Commercial fish catch")

**How to Use:**
1. Click "Add Ecosystem Service"
2. Fill in fields
3. Select which G&B this ES supports (dropdown shows all G&Bs from Exercise 1)
4. Click "Save Exercise 2a"

**Examples:**

| ES Name | Linked to G&B | Mechanism |
|---------|--------------|-----------|
| Fish stock recruitment | Commercial fish catch | Spawning success → fishable biomass |
| Shellfish filtration | Water quality for tourism | Mussels filter particles → clear water |
| Seagrass habitat | Nursery for commercial species | Shelter for juveniles → adult fish stock |

**Tips:**
- One G&B may be supported by multiple ES
- One ES may support multiple G&B
- Clearly describe the mechanism (helps validation)
- Use scientific knowledge and stakeholder input

---

### Exercise 2b: Marine Processes and Functioning (MPF)

**Purpose:** Identify the fundamental ecological processes supporting ecosystem services.

**What to Enter for Each Marine Process:**
- **Name:** Name of the process
- **Type:** Biological / Chemical / Physical / Ecological
- **Description:** What this process does
- **Linked to ES:** Select from dropdown (ES from Ex. 2a)
- **Mechanism:** How does this process generate the service?
- **Spatial Scale:** Where it occurs (local/regional/basin-wide)

**Types of Marine Processes:**
- **Biological:** Primary production, predation, reproduction, migration
- **Chemical:** Nutrient cycling, carbon sequestration, pH regulation
- **Physical:** Water circulation, sediment transport, wave action
- **Ecological:** Habitat structure, food web dynamics, biodiversity

**How to Use:**
1. Click "Add Marine Process"
2. Fill in fields
3. Select which ES this MPF supports
4. Click "Save Exercise 2b"

**Examples:**

| MPF Name | Type | Linked to ES | Mechanism |
|----------|------|--------------|-----------|
| Phytoplankton primary production | Biological | Fish stock productivity | Light + nutrients → biomass → food web |
| Seagrass photosynthesis | Biological | Carbon storage | CO2 uptake → organic matter → sediment burial |
| Mussel bed filtration | Ecological | Water clarity | Filter feeding removes particles |

**Tips:**
- Focus on processes relevant to your ES
- Use scientific expertise
- Consider spatial and temporal scales
- Multiple processes may contribute to one ES

---

### Exercise 3: Specifying Pressures on State Changes

**Purpose:** Identify stressors affecting marine processes.

**What to Enter for Each Pressure:**
- **Name:** Clear name of the pressure
- **Type:** Physical / Chemical / Biological / Multiple
- **Description:** Nature of the stressor
- **Linked to MPF:** Select from dropdown (MPF from Ex. 2b)
- **Intensity:** High / Medium / Low / Unknown
- **Spatial:** Where it occurs
- **Temporal:** When/how often (continuous/seasonal/episodic)

**Types of Pressures:**
- **Physical:** Seabed abrasion, habitat loss, noise, heat
- **Chemical:** Nutrient enrichment, contaminants, acidification
- **Biological:** Species removal, invasive species, pathogens
- **Multiple:** Combined effects

**How to Use:**
1. Click "Add Pressure"
2. Fill in fields
3. Select which MPF this pressure affects
4. Rate intensity and describe spatial/temporal patterns
5. Click "Save Exercise 3"

**Examples:**

| Pressure Name | Type | Linked to MPF | Intensity |
|---------------|------|--------------|-----------|
| Nutrient enrichment | Chemical | Phytoplankton composition | High |
| Bottom trawling | Physical | Benthic habitat structure | High |
| Overfishing | Biological | Food web dynamics | Medium |

**Tips:**
- One pressure can affect multiple processes
- Specify the direct mechanism
- Consider cumulative effects
- Include both chronic and acute pressures
- Use scientific evidence for intensity ratings

---

### Exercise 4: Specifying Activities affecting Pressures

**Purpose:** Identify human activities generating pressures.

**What to Enter for Each Activity:**
- **Name:** Clear name
- **Sector:** Fisheries / Aquaculture / Tourism / Shipping / Energy / Mining / Other
- **Description:** What the activity involves
- **Linked to Pressure:** Select from dropdown (pressures from Ex. 3)
- **Scale:** Local / Regional / National / International
- **Frequency:** Continuous / Seasonal / Occasional / One-time

**Common Marine Activities:**
- **Fisheries:** Commercial/recreational/subsistence fishing
- **Aquaculture:** Fish/shellfish farming
- **Tourism:** Beach tourism, wildlife watching, diving
- **Shipping:** Cargo, cruises, ferries
- **Energy:** Offshore wind, oil & gas, tidal/wave
- **Infrastructure:** Ports, coastal construction
- **Agriculture:** Nutrient runoff (land-based but marine impact)

**How to Use:**
1. Click "Add Activity"
2. Fill in fields
3. Select which pressure(s) this activity generates
4. Specify scale and frequency
5. Click "Save Exercise 4"

**Examples:**

| Activity Name | Sector | Linked to Pressure | Scale |
|---------------|--------|-------------------|-------|
| Bottom trawl fishing | Fisheries | Seabed abrasion | Regional |
| Coastal wastewater discharge | Waste | Nutrient enrichment | Local |
| Shipping traffic | Shipping | Underwater noise, oil pollution | International |

**Tips:**
- Be specific: "Bottom trawling" not just "Fishing"
- One activity often generates multiple pressures
- Consider both direct and indirect pathways
- Include seasonal patterns

---

### Exercise 5: Drivers giving rise to Activities

**Purpose:** Identify underlying forces motivating activities.

**What to Enter for Each Driver:**
- **Name:** Clear name
- **Type:** Economic / Social / Technological / Political / Environmental / Demographic
- **Description:** What this force is and how it works
- **Linked to Activity:** Select from dropdown (activities from Ex. 4)
- **Trend:** Increasing / Stable / Decreasing / Cyclical / Uncertain
- **Controllability:** High / Medium / Low / None

**Types of Drivers:**
- **Economic:** Market demand, prices, subsidies, economic growth
- **Social:** Cultural traditions, consumer preferences, social norms
- **Technological:** Gear innovation, vessel efficiency, new techniques
- **Political:** Regulations, governance, international agreements
- **Environmental:** Climate change, extreme weather (as adaptation drivers)
- **Demographic:** Population growth, urbanization, migration

**How to Use:**
1. Click "Add Driver"
2. Fill in fields
3. Select which activity(ies) this driver motivates
4. Assess trend and controllability
5. Click "Save Exercise 5"

**Examples:**

| Driver Name | Type | Linked to Activity | Controllability |
|-------------|------|-------------------|----------------|
| Global seafood demand | Economic | Commercial fishing expansion | Low |
| EU renewable energy targets | Political | Offshore wind development | High |
| Coastal tourism demand | Social/Economic | Coastal development | Medium |

**Tips:**
- Think about WHY people engage in activities
- Consider both push and pull factors
- Drivers often interact (economic + technological + political)
- Assess controllability honestly
- Drivers are often best intervention points

---

### Exercise 6: Closing the Loop - Drivers to Goods & Benefits

**Purpose:** Create feedback loops by connecting drivers back to goods & benefits.

**What to Identify:**
- How do changes in Goods & Benefits influence Drivers?
- How do Drivers respond to ecosystem conditions?
- Which feedbacks are reinforcing (amplifying)?
- Which are balancing (stabilizing)?

**Types of Feedback Loops:**

**Reinforcing Loops (R):** Changes amplify themselves
- Example: Declining fish stocks → Lower profits → More fishing effort to maintain income → Further decline

**Balancing Loops (B):** Changes trigger counteracting responses
- Example: Declining water quality → Reduced tourism → Economic pressure for cleanup → Improved quality

**How to Use:**
1. Review the loop connections interface
2. Select driver-to-G&B connections that create meaningful feedbacks
3. Document whether feedbacks are reinforcing or balancing
4. Click "Save Exercise 6"

**Examples:**

| From (G&B) | To (Driver) | Type | Explanation |
|------------|------------|------|-------------|
| Declining fish catch | Reduced fishing capacity | Balancing | Low profits drive fishers out of industry |
| Improved water quality | Political support for conservation | Reinforcing | Success breeds more conservation policy |
| Coastal storm damage | Ecosystem restoration policy | Balancing | Losses trigger protective measures |

**Tips:**
- Not all drivers need to connect back
- Consider time lags (years to manifest)
- Stakeholder knowledge is crucial
- Document loop type (R or B)

---

### Exercises 7-9: Causal Loop Diagram Creation and Export

**Purpose:** Visualize your system structure in Kumu software.

#### Exercise 7: Creating Impact-based CLD in Kumu

**Steps:**
1. Click "Download Kumu CSV Files" to export your data
2. Go to [kumu.io](https://kumu.io) and create a free account
3. Create a new project (choose "Causal Loop Diagram" template)
4. Import your CSV files:
   - `elements.csv` → contains all nodes
   - `connections.csv` → contains all edges
5. Apply the Kumu styling code from `Documents/Kumu_Code_Style.txt`
6. Arrange elements to show clear causal flows

**Kumu Color Scheme:**
- Goods & Benefits: Yellow triangles
- Ecosystem Services: Blue squares
- Marine Processes: Light blue pills
- Pressures: Orange diamonds
- Activities: Green hexagons
- Drivers: Purple octagons

#### Exercise 8: Moving from Causal Logic Chains to Causal Loops

**Steps:**
1. In Kumu, identify closed loops in your diagram
2. Trace paths from an element back to itself
3. Classify loops as reinforcing (R) or balancing (B)
4. Add loop identifiers in Kumu (use labels or tags)
5. Focus on the most important loops driving system behavior

**Identifying Loop Type:**
- Count the number of negative (-) links in the loop
- Even number of (-) links = Reinforcing (R)
- Odd number of (-) links = Balancing (B)

#### Exercise 9: Exporting CLD for Further Analysis

**Steps:**
1. Export high-resolution images from Kumu:
   - Click Share → Export → PNG/PDF
2. Download complete Excel workbook from ISA module
3. Review adjacency matrices to verify all connections
4. Create different views:
   - Full system view
   - Sub-system views (e.g., just fisheries)
   - Key loop views
5. Document key loops with narrative descriptions

**Click "Save Exercises 7-9" when complete.**

---

### Exercises 10-12: Clarifying, Metrics, and Validation

#### Exercise 10: Clarifying - Endogenisation and Encapsulation

**Endogenisation:** Bringing external factors inside the system boundary

**What to Do:**
1. Review external drivers
2. Can any be explained by factors within your system?
3. Add these internal feedbacks
4. Document in "Endogenisation Notes"

**Example:** "Market demand" might be influenced by "product quality" within your system

**Encapsulation:** Grouping detailed processes into higher-level concepts

**What to Do:**
1. Identify overly complex sub-systems
2. Group related elements (e.g., multiple nutrient processes → "Eutrophication dynamics")
3. Keep detailed version for technical work
4. Create simplified version for policy communication
5. Document in "Encapsulation Notes"

#### Exercise 11: Metrics, Root Causes, and Leverage Points

**Root Cause Analysis:**
1. Use the "Root Causes" interface
2. Identify elements with many outgoing links
3. Trace backward from problems to ultimate causes
4. Focus on drivers and activities

**Leverage Point Identification:**
1. Use the "Leverage Points" interface
2. Look for:
   - Loop control points
   - High-centrality nodes (many connections)
   - Convergence points (multiple pathways meet)
3. Consider feasibility and controllability
4. Prioritize actionable leverage points

**Meadows' Hierarchy:**
- Weakest: Parameters (numbers, rates)
- Stronger: Feedback loops
- Very strong: System design/structure
- Strongest: Paradigms (mindsets, goals)

#### Exercise 12: Presenting and Validating Results

**Validation Approaches:**
- ✓ Internal team review
- ✓ Stakeholder workshop
- ✓ Expert peer review
- ✓ Final approval

**What to Do:**
1. Conduct validation activities
2. Record feedback in "Validation Notes"
3. Check boxes for completed validation types
4. Update your model based on feedback
5. Prepare presentations for different audiences

**Presentation Tips:**
- Tailor complexity to audience
- Use visual CLD for overview
- Tell stories about key loops
- Show BOT graphs for evidence
- Link to policy recommendations
- Be transparent about uncertainties

**Click "Save Exercises 10-12" when complete.**

---

### BOT Graphs: Behaviour Over Time

**Purpose:** Visualize temporal dynamics to validate your causal model.

**How to Create BOT Graphs:**

1. **Select Element Type:** Choose from dropdown (Goods & Benefits / ES / MPF / Pressures / Activities / Drivers)
2. **Select Specific Element:** Choose which element to graph
3. **Add Data Points:**
   - Year
   - Value
   - Unit (e.g., "tonnes", "%", "index")
   - Click "Add Data Point"
4. **View Plot:** Time series appears automatically
5. **Repeat** for other elements

**Patterns to Look For:**
- **Trends:** Steady increase/decrease
- **Cycles:** Regular oscillations
- **Steps:** Sudden changes (policy shifts)
- **Delays:** Time lags
- **Thresholds:** Tipping points
- **Plateaus:** Stability

**Using BOT Graphs:**
- Compare patterns to CLD predictions
- Identify feedback loop evidence
- Measure time delays
- Evaluate policy interventions
- Project future scenarios

**Data Sources:**
- Official statistics
- Environmental monitoring
- Scientific surveys
- Stakeholder observations
- Historical records

**Click "Save BOT Data" to preserve your work.**

---

## Working with Kumu

### Getting Started with Kumu

**1. Create Account:**
- Go to [kumu.io](https://kumu.io)
- Sign up for free account
- Public projects are free; private projects require subscription

**2. Create New Project:**
- Click "New Project"
- Choose "Causal Loop Diagram" template
- Name your project

**3. Import Data:**
- From ISA module, download Kumu CSV files
- In Kumu, click Import
- Upload `elements.csv` and `connections.csv`

### Applying Custom Styling

**Copy the Kumu Code:**
- Open `Documents/Kumu_Code_Style.txt`
- Copy all contents

**Apply to Your Map:**
1. In Kumu, click the Settings icon
2. Go to "Advanced Editor"
3. Paste the code
4. Click "Save"

**Result:** Your elements will be color-coded and shaped by type:
- Goods & Benefits: Yellow triangles
- Ecosystem Services: Blue squares
- Marine Processes: Light blue pills
- Pressures: Orange diamonds
- Activities: Green hexagons
- Drivers: Purple octagons

### Working with the Diagram

**Layout Options:**
- Auto-layout: Let Kumu arrange elements
- Manual: Drag elements to preferred positions
- Circular: Emphasize loop structure
- Hierarchical: Show causal flow from drivers to welfare

**Adding Information:**
- Click any element to edit properties
- Add descriptions, tags, custom fields
- Include data sources, confidence levels

**Highlighting Loops:**
1. Identify a closed loop path
2. Add a "Loop" tag to all elements in the loop
3. Use Kumu's filter to show/hide loops
4. Label loops (e.g., "R1: Overfishing Spiral", "B1: Quality Recovery")

**Filters and Views:**
- Filter by element type (show only Drivers)
- Filter by importance, confidence, etc.
- Create multiple views (full system, key loops, sub-systems)
- Save views for presentations

### Collaboration

**Sharing:**
- Share view-only link with stakeholders
- Export screenshots for reports
- Embed in websites/presentations

**Team Editing:**
- Add collaborators (paid feature)
- Multiple people can edit simultaneously
- Version control available

### Export Options

**From Kumu:**
- **PNG:** High-resolution image for reports
- **PDF:** Vector format for publications
- **JSON:** Raw data for archiving
- **Share link:** Interactive web view

**From ISA Module:**
- **Excel workbook:** Complete data with all sheets
- **Kumu CSV:** Elements and connections
- **Adjacency matrices:** Connection matrices for analysis

---

## Data Management

### Saving Your Work

**Auto-save:**
- Data is stored in the app's reactive state during your session
- Use "Save" buttons after completing each exercise

**Export to Excel:**
1. Go to "Data Management" tab
2. Enter filename (e.g., "MyCase_ISA_2024")
3. Click "Export to Excel"
4. Downloads complete workbook with all data

### Importing Existing Data

**From Excel:**
1. Go to "Data Management" tab
2. Click "Choose Excel File"
3. Select your previously exported .xlsx file
4. Click "Import Data"
5. Data populates all exercises

**Excel File Structure:**
- Sheet: Case_Info
- Sheet: Goods_Benefits
- Sheet: Ecosystem_Services
- Sheet: Marine_Processes
- Sheet: Pressures
- Sheet: Activities
- Sheet: Drivers
- Sheet: BOT_Data

### Resetting Data

**Warning:** This clears ALL data and cannot be undone.

1. Go to "Data Management" tab
2. Click "Reset All Data" (red button)
3. Confirm the action
4. All exercises return to blank state

**When to Reset:**
- Starting a completely new case study
- Discarding a practice run
- After exporting data you want to keep

### Collaboration Workflows

**Individual Work:**
- One person enters all data
- Export Excel when done
- Share file with team for review

**Sequential Work:**
- Person A: Exercises 0-3 → Export
- Person B: Import → Exercises 4-6 → Export
- Person C: Import → Exercises 7-12 → Final export

**Parallel Work:**
- Multiple people work on different exercises in separate sessions
- Consolidate in Excel (manually merge sheets)
- Import consolidated file

**Workshop-Based:**
- Facilitate group discussions for each exercise
- One person operates the tool and enters consensus data
- Export after each exercise for record-keeping

---

## Tips and Best Practices

### General Workflow Tips

**1. Work systematically:**
- Complete exercises in order
- Don't skip ahead (later exercises build on earlier ones)
- Save after each exercise

**2. Engage stakeholders:**
- Conduct workshops for Exercises 1-6
- Validate CLD with those who know the system
- Use diverse perspectives (users, managers, scientists)

**3. Use scientific evidence:**
- Base linkages on peer-reviewed studies
- Cite sources in descriptions
- Note confidence levels

**4. Start simple, add detail:**
- First pass: Major elements only
- Second pass: Add nuances and details
- Keep a simplified version for communication

**5. Document everything:**
- Use description fields generously
- Record data sources
- Note assumptions and uncertainties

### Data Quality Tips

**Be Specific:**
- ❌ "Fishing" → ✅ "Bottom trawl commercial fishing for demersal species"
- ❌ "Pollution" → ✅ "Nutrient enrichment from agricultural runoff"

**Be Comprehensive:**
- Include positive and negative impacts
- Consider all stakeholder groups
- Cover all sectors using the marine area

**Be Realistic:**
- Focus on important elements (top 80%)
- Don't try to include everything
- Complexity should match available knowledge

**Be Consistent:**
- Use consistent terminology
- Maintain consistent level of detail across exercises
- Follow naming conventions (e.g., element IDs)

### CLD Development Tips

**Layout:**
- Arrange in causal flow: Drivers → Activities → Pressures → State → Welfare
- Put feedback loops prominently
- Minimize edge crossings for readability

**Loops:**
- Identify and label key loops (R1, R2, B1, B2)
- Focus on loops that drive problematic behavior
- Document loop narratives (what story does each loop tell?)

**Validation:**
- Does the CLD explain observed system behavior?
- Do stakeholders recognize the structure?
- Can you trace specific historical events through the diagram?

### BOT Graph Tips

**Data Collection:**
- Use longest time series available
- Be consistent with units and scales
- Document data sources clearly

**Comparison:**
- Plot related variables on same time axis
- Look for correlations (do they match your CLD?)
- Identify time delays between cause and effect

**Communication:**
- Annotate with key events (policy changes, disasters)
- Use consistent color schemes
- Include error bars or uncertainty ranges if available

### Common Pitfalls to Avoid

**1. Too much detail too soon:**
- Start with major elements
- Add detail in iterations
- Keep a simplified version

**2. Skipping stakeholder input:**
- Local knowledge is invaluable
- Legitimacy requires participation
- Blind spots emerge without diverse perspectives

**3. Confusing ES and G&B:**
- ES = ecosystem's capacity/potential
- G&B = realized benefits people obtain
- Example: "Fish stock" (ES) vs. "Fish catch" (G&B)

**4. Weak linkages:**
- Always specify mechanism
- Avoid vague connections
- Test: Can you explain this link to a stakeholder?

**5. Ignoring time:**
- Delays are crucial
- Some effects take years to manifest
- BOT graphs reveal temporal patterns

**6. No feedback loops:**
- Exercise 6 is critical
- Systems are circular, not linear
- Feedbacks drive dynamics

**7. Skipping validation:**
- Your model is a hypothesis
- Test against data and stakeholder knowledge
- Iterate based on feedback

---

## Troubleshooting

### Common Issues and Solutions

**Problem: "My data didn't save"**
- **Solution:** Always click the "Save Exercise X" button after entering data
- Check that the data table updates after saving
- Export to Excel frequently as backup

**Problem: "Dropdown lists are empty"**
- **Cause:** You haven't completed the previous exercise
- **Solution:** Complete exercises in order. Ex. 2a needs data from Ex. 1, etc.

**Problem: "I made a mistake in a previous exercise"**
- **Solution:** Go back to that exercise tab
- The data is still there and editable
- Make corrections and click Save again

**Problem: "Excel export isn't working"**
- **Check:** Browser's download settings
- **Check:** File permissions in download folder
- **Try:** Different browser

**Problem: "Kumu import fails"**
- **Check:** CSV file format (must be comma-separated)
- **Check:** Column headers match Kumu expectations
- **Try:** Import elements first, then connections

**Problem: "App is slow with large datasets"**
- **Normal:** 100+ elements can slow rendering
- **Solution:** Work on sub-systems separately
- **Solution:** Use Excel for data management, app for structure

**Problem: "I can't find the help content"**
- **Location:** Click the "?" Help button on each exercise tab
- **Main guide:** Click "ISA Framework Guide" at top of module

### Getting Additional Help

**Documentation:**
- This User Guide
- MarineSABRES Simple SES DRAFT Guidance (Documents folder)
- Kumu documentation: [docs.kumu.io](https://docs.kumu.io)

**Technical Support:**
- Check app version and browser compatibility
- Contact MarineSABRES project team
- Report bugs via GitHub (if applicable)

**Scientific Support:**
- Consult the guidance document for methodological questions
- Engage domain experts for your specific case study
- Participate in ISA training workshops

---

## Glossary

**Activities (A):** Human uses of marine and coastal environments (fishing, shipping, tourism, etc.)

**Adjacency Matrix:** Table showing which elements are connected to which other elements

**Balancing Loop (B):** Feedback loop that counteracts change and stabilizes the system

**BOT (Behaviour Over Time) Graph:** Time series plot showing how an indicator changes over time

**Causal Chain:** Linear sequence of cause-effect relationships (e.g., Drivers → Activities → Pressures)

**Causal Loop Diagram (CLD):** Visual network showing elements and their causal relationships, including feedback loops

**DAPSI(W)R(M):** Drivers-Activities-Pressures-State(Welfare)-Responses(Measures) framework

**Drivers (D):** Underlying forces that motivate activities (economic, social, political, technological)

**Ecosystem Services (ES):** The capacity of ecosystems to generate benefits for people

**Encapsulation:** Grouping detailed elements into higher-level concepts for simplification

**Endogenisation:** Bringing external factors inside the system boundary by adding internal feedbacks

**Feedback Loop:** Circular causal pathway where an element influences itself through a chain of other elements

**Goods and Benefits (G&B):** Realized benefits that people obtain from marine ecosystems (welfare impacts)

**ISA (Integrated Systems Analysis):** Systematic framework for analyzing social-ecological systems

**Kumu:** Free online network visualization software (kumu.io)

**Leverage Point:** Location in system where small intervention can produce large change

**Marine Processes and Functioning (MPF):** Biological, chemical, physical, and ecological processes that support ecosystem services

**Measures (M):** Policy interventions and management actions (responses)

**Polarity:** Direction of causal influence (+ same direction, - opposite direction)

**Pressures (P):** Direct stressors on the marine environment (pollution, habitat destruction, species removal)

**Reinforcing Loop (R):** Feedback loop that amplifies change (can be virtuous or vicious cycle)

**Responses (R):** Societal actions to address problems

**Root Cause:** Fundamental driver or activity at the origin of a causal chain

**Social-Ecological System (SES):** Integrated system of people and nature, with reciprocal feedbacks

**State Changes (S):** Changes in ecosystem condition (represented through W, ES, and MPF)

**Welfare (W):** Human well-being, represented through goods and benefits from ecosystems

---

## Appendix: Quick Reference Card

### Exercise Checklist

- [ ] Exercise 0: Define case study scope
- [ ] Exercise 1: List all Goods & Benefits
- [ ] Exercise 2a: Identify Ecosystem Services
- [ ] Exercise 2b: Identify Marine Processes & Functioning
- [ ] Exercise 3: Identify Pressures
- [ ] Exercise 4: Identify Activities
- [ ] Exercise 5: Identify Drivers
- [ ] Exercise 6: Close feedback loops
- [ ] Exercise 7: Create CLD in Kumu
- [ ] Exercise 8: Identify causal loops
- [ ] Exercise 9: Export and document CLD
- [ ] Exercise 10: Clarify model (endogenisation, encapsulation)
- [ ] Exercise 11: Identify leverage points
- [ ] Exercise 12: Validate with stakeholders
- [ ] BOT Graphs: Add temporal data
- [ ] Export final Excel workbook

### Keyboard Shortcuts

- **Tab:** Move between form fields
- **Enter:** Submit/Save form
- **Ctrl+F / Cmd+F:** Search within tables

### File Locations

- **User Guide:** `Documents/ISA_User_Guide.md`
- **Guidance Document:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Kumu Styling:** `Documents/Kumu_Code_Style.txt`
- **Excel Template:** `Documents/ISA Excel Workbook.xlsx`

### Useful Links

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Kumu Docs:** [https://docs.kumu.io](https://docs.kumu.io)
- **DAPSI(W)R Framework:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Document Information

**Document:** ISA Data Entry Module - User Guide
**Project:** MarineSABRES Social-Ecological Systems Toolbox
**Version:** 1.0
**Date:** October 2025
**Status:** Final

**Citation:**
> MarineSABRES Project (2025). ISA Data Entry Module - User Guide.
> MarineSABRES Social-Ecological Systems Analysis Tool, Version 1.0.

**License:** This guide is provided for use with the MarineSABRES SES Toolbox.

---

**For questions, feedback, or support, please contact the MarineSABRES project team.**

**Happy analyzing!**
