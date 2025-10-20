# Example SES Dataset: Baltic Sea Commercial Fisheries

## Overview

This folder contains a comprehensive example Social-Ecological System (SES) dataset demonstrating the full capabilities of the MarineSABRES SES Analysis Tool.

**Case Study:** Baltic Sea Commercial Fisheries
**Primary Issue:** Declining cod stocks and ecosystem-based fisheries management
**Geographic Scope:** Baltic Sea (ICES subdivisions 24-32)
**Temporal Scope:** 2000-2024

## Files Included

### 1. `example_baltic_sea_fisheries.rds`
- **Format:** R Data Structure (RDS)
- **Use:** Can be loaded directly into R/Shiny application
- **Content:** Complete SES dataset as R list object

### 2. `example_baltic_sea_fisheries.xlsx`
- **Format:** Microsoft Excel Workbook
- **Use:** Human-readable, can be imported via the app's Data Management tab
- **Content:** All data organized into multiple sheets

### 3. `example_baltic_sea_fisheries.R`
- **Format:** R Script
- **Use:** Source code to regenerate the example files
- **Content:** Complete data generation script with documentation

## Dataset Contents

### ISA (Integrated Systems Analysis) Components

| Component | Count | Description |
|-----------|-------|-------------|
| **Goods & Benefits** | 6 | Marine ecosystem benefits (fish catch, tourism, culture, food security) |
| **Ecosystem Services** | 6 | Ecosystem capacities (stock productivity, water quality, biodiversity) |
| **Marine Processes** | 6 | Ecological processes (spawning, food webs, habitat, oxygen dynamics) |
| **Pressures** | 6 | Environmental stressors (overfishing, trawling, eutrophication, hypoxia) |
| **Activities** | 6 | Human activities (fishing, agriculture, wastewater, development) |
| **Drivers** | 7 | Underlying forces (demand, policy, climate change, demographics) |

### PIMS (Process & Information Management) Components

| Component | Count | Description |
|-----------|-------|-------------|
| **Stakeholders** | 8 | Key actors (fishers, NGOs, regulators, scientists, communities) |
| **Engagements** | 4 | Stakeholder engagement activities (workshops, interviews, meetings) |
| **Communications** | 3 | Project communications (newsletters, reports, presentations) |

### Temporal Data

| Component | Count | Description |
|-----------|-------|-------------|
| **BOT Data Points** | 40 | Behaviour Over Time data for 4 elements over 10 years |
| **Loop Connections** | 3 | Feedback loop closures linking drivers back to goods/benefits |

## How to Use This Example

### Method 1: Load RDS File in R

```r
# Load the example data
baltic_example <- readRDS("data/example_baltic_sea_fisheries.rds")

# Explore the structure
names(baltic_example)
# [1] "case_info"         "goods_benefits"    "ecosystem_services"
# [4] "marine_processes"  "pressures"         "activities"
# [7] "drivers"           "stakeholders"      "engagements"
# [10] "communications"    "bot_data"          "loop_connections"
# [13] "metadata"

# View goods and benefits
View(baltic_example$goods_benefits)

# View stakeholders
View(baltic_example$stakeholders)
```

### Method 2: Import Excel File via Application

1. Launch the MarineSABRES SES Tool
2. Navigate to **ISA Data Entry → Data Management** tab
3. Click **"Choose Excel File"**
4. Select `example_baltic_sea_fisheries.xlsx`
5. Click **"Import Data"**
6. All exercises will be populated with example data

### Method 3: Load via Global Environment

The example can be pre-loaded when the application starts by modifying `global.R`:

```r
# In global.R, add:
if(file.exists("data/example_baltic_sea_fisheries.rds")) {
  example_data <- readRDS("data/example_baltic_sea_fisheries.rds")
  message("Example Baltic Sea dataset loaded")
}
```

## Example Data Description

### Case Study Context

**Problem Statement:**
The Baltic Sea has experienced significant declines in cod stocks over the past two decades due to a combination of overfishing, eutrophication, and climate change. This case study examines the complex social-ecological system dynamics affecting commercial fisheries and coastal communities.

**Key Issues:**
- Declining cod stocks threatening fishing livelihoods
- Nutrient pollution from agriculture and urban areas
- Bottom trawling impacts on benthic habitats
- Climate change affecting salinity and oxygen levels
- Socioeconomic impacts on coastal communities
- Trade-offs between fishing and conservation

### Example DAPSI(W)R(M) Chain

**Full Causal Chain Example:**

```
DRIVER: Global seafood demand
    ↓
ACTIVITY: Commercial bottom trawl fishing
    ↓
PRESSURE: Overfishing of cod
    ↓
STATE CHANGE (Marine Process): Cod spawning aggregations reduced
    ↓
STATE CHANGE (Ecosystem Service): Cod stock productivity declines
    ↓
WELFARE IMPACT (Good/Benefit): Commercial cod catch decreases
    ↓
FEEDBACK: Declining catch revenues → Economic pressure → Overcapacity maintained
```

### Example Stakeholders

**Key Players (High Power, High Interest):**
- European Commission DG MARE (Policy maker)
- ICES (Scientific advisor)
- HELCOM (Regional coordination)

**Keep Satisfied (High Power, Low Interest):**
- Polish Ministry of Maritime Economy

**Keep Informed (Low Power, High Interest):**
- Baltic Sea Fishers Association
- WWF Baltic Sea Programme
- Local Fishing Communities

### Example BOT Trends

**Commercial Cod Catch (2014-2023):**
- Declining from 45,000 to 18,000 tonnes (-60%)
- Demonstrates impact of stock depletion

**Coastal Tourism Revenue (2014-2023):**
- Increasing from €120M to €270M (+125%)
- Shows shift in coastal economy

**Nutrient Loading (2014-2023):**
- Slowly declining from 650,000 to 585,000 tonnes N
- Reflects pollution reduction efforts

**Seafood Demand Index (2014-2023):**
- Increasing from 100 to 156 (+56%)
- Demonstrates ongoing pressure

## Learning Objectives

By exploring this example, users will learn:

1. **How to structure ISA data** - See complete DAPSI(W)R(M) framework in action
2. **How to identify stakeholders** - Power-interest analysis for marine management
3. **How to track engagements** - Document stakeholder participation
4. **How to use BOT graphs** - Visualize temporal dynamics
5. **How to identify feedback loops** - Understand circular causality
6. **How to analyze complex systems** - Navigate interconnected SES components

## Customizing the Example

To create your own example based on this template:

1. **Edit the R script:** Modify `example_baltic_sea_fisheries.R`
2. **Change case study details:** Update names, descriptions, and data
3. **Adjust element counts:** Add or remove elements as needed
4. **Update relationships:** Modify LinkedGB, LinkedES, etc. fields
5. **Regenerate files:** Run `Rscript data/example_baltic_sea_fisheries.R`

## Data Sources and Realism

This example is based on:
- Real Baltic Sea ecological conditions
- Actual policy frameworks (EU CFP, HELCOM)
- Peer-reviewed literature on Baltic Sea fisheries
- Realistic stakeholder types and power dynamics
- Simulated but plausible time-series data

**Note:** While realistic, this is **simulated data for demonstration purposes**. Real SES analyses should use actual data from stakeholder engagement, scientific monitoring, and official statistics.

## References

**Key Literature on Baltic Sea Fisheries:**
- Eero, M., et al. (2016). Eastern Baltic cod in distress: biological changes and challenges for stock assessment. ICES Journal of Marine Science.
- Österblom, H., et al. (2007). Human-induced trophic cascades and ecological regime shifts in the Baltic Sea. Ecosystems.
- Blenckner, T., et al. (2015). Climate and fishing steer ecosystem regeneration to uncertain economic futures. Proceedings of the Royal Society B.

**DAPSI(W)R(M) Framework:**
- Elliott, M., et al. (2017). "And DAPSI(W)R(M) drives policy." Marine Pollution Bulletin.

**Stakeholder Engagement:**
- Reed, M. S., et al. (2009). "Who's in and why? A typology of stakeholder analysis methods for natural resource management." Journal of Environmental Management.

## Support

For questions about using this example:
- Check the User Guide: `Documents/ISA_User_Guide.md`
- Review in-app help: Click help (?) buttons in each module
- Contact the MarineSABRES project team

## License

This example dataset is provided as part of the MarineSABRES project for educational and research purposes.

---

**Created:** 2024
**Version:** 1.0
**Contact:** MarineSABRES Project Team
**Project:** Marine Systems Approaches for Biodiversity Resilience and Ecosystem Sustainability
