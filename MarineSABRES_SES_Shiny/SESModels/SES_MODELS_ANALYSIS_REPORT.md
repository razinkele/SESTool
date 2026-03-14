# SES Model Excel Files Analysis Report

**Generated:** 2026-01-12
**Total Files Analyzed:** 10 Excel files across 3 Demonstration Areas

---

## Executive Summary

The SES model Excel files exhibit significant structural inconsistencies that cause loading failures. The main issues are:

1. **Missing DAPSIWRM types** - Tuscan DA files have 100% NA values in type columns
2. **Confusing sheet naming** - Arctic files use "Edge Labels" for nodes and "Node Data" for edges
3. **Inconsistent type values** - "Marine Process and Functioning" vs "Marine Process and Function"
4. **Missing data** - Multiple files have NA values in critical Label columns

---

## File Inventory

| File | DA | Format | Status |
|------|-----|--------|--------|
| AdjacencyMatriciesReversed_200125.xlsx | Arctic | Confusing naming | Partial |
| Arctic Model edge and node data 20.02.2025V3.xlsx | Arctic | Multi-variant | OK |
| Arctic_Kumu_07012025_V2.xlsx | Arctic | Edges-only | Requires inference |
| Artic DA_Edges_and_Nodes_12.2024.xlsx | Arctic | Confusing naming | Partial |
| LeveragePoint_Organorgam_Arctic DA.xlsx | Arctic | Unsupported | Unsupported |
| Final Simple SES model_MDA.xlsx | Macronesia | KUMU Standard | OK |
| KUMU_TA_Full model CLD.xlsx | Tuscan | KUMU Standard | **BROKEN - No types** |
| Simplified final map SES.xlsx | Tuscan | KUMU Standard | **BROKEN - No types** |
| Simplified final map SES_MPASimplified.xlsx | Tuscan | KUMU Standard | **BROKEN - No types** |
| Simplified final map SES_TurismSimplified.xlsx | Tuscan | KUMU Standard | **BROKEN - No types** |

---

## Detailed Findings

### 1. Format Classification

#### Format A: KUMU Standard (Elements + Connections)
- **Files:** 5 (all Tuscan DA + Macronesia)
- **Structure:** Two sheets named "Elements" and "Connections"
- **Expected columns:**
  - Elements: Label, Type, Description
  - Connections: From, To, Label, Direction, Type

#### Format B: Multi-variant (Node Labels + Edges pattern)
- **Files:** 2 (Arctic DA)
- **Structure:** Multiple sheet pairs like "Arctic Node Labels" + "Arctic Kumu Edges"
- **Contains multiple regional variants** (Arctic, Iceland, Greenland, Faroes)

#### Format C: Confusing Naming ("Edge Labels" = nodes, "Node Data" = edges)
- **Files:** 2 (Arctic DA)
- **Structure:** Sheet names are backwards from what they contain
- **"Edge Labels"** sheets contain node data (Label, Type)
- **"Node Data"** sheets contain edge data (From, To, Direction)

#### Format D: Edges-only (single sheet)
- **Files:** 1 (Arctic_Kumu_07012025_V2.xlsx)
- **Structure:** Single "Sheet2" with From, To columns
- **Requires:** Node inference from edge data

#### Format E: Unsupported
- **Files:** 1 (LeveragePoint_Organorgam_Arctic DA.xlsx)
- **Structure:** Organogram/Horrendogram layout - not a node/edge model

---

### 2. Critical Data Quality Issues

#### TUSCAN DA - Missing DAPSIWRM Types (CRITICAL)

All 4 Tuscan DA files have **100% NA values** in the Elements Type column:

| File | Elements | Type NA Count |
|------|----------|---------------|
| KUMU_TA_Full model CLD.xlsx | 34 | 34 (100%) |
| Simplified final map SES.xlsx | 28 | 28 (100%) |
| Simplified final map SES_MPASimplified.xlsx | 28 | 28 (100%) |
| Simplified final map SES_TurismSimplified.xlsx | 28 | 28 (100%) |

**Impact:** These files cannot be loaded because the DAPSIWRM framework requires element types (Driver, Activity, Pressure, etc.) to build adjacency matrices.

**Root Cause:** The KUMU export did not include type information, or types were stored in a different column/format.

#### ARCTIC DA - NA Values in Label Columns

| File | Sheet | NA in Label |
|------|-------|-------------|
| AdjacencyMatriciesReversed_200125.xlsx | Arctic Node Data | 29 |
| Artic DA_Edges_and_Nodes_12.2024.xlsx | Greenland Node Data | 16 |
| Artic DA_Edges_and_Nodes_12.2024.xlsx | Iceland Node Data | 16 |
| Artic DA_Edges_and_Nodes_12.2024.xlsx | Faroes Node Data | 22 |

**Impact:** These NA values in connection Label columns cause "missing value where TRUE/FALSE needed" errors during polarity detection.

---

### 3. Type Value Inconsistencies

#### Valid DAPSIWRM Types
```
Driver, Activity, Pressure, State, Marine Process and Function,
Impact, Ecosystem Service, Good and Benefit, Welfare, Response, Measure
```

#### Non-Standard Values Found

| Value | Issue | Occurrences |
|-------|-------|-------------|
| `Marine Process and Functioning` | Should be "Marine Process and Function" | 9 |
| `causal loop` | Edge type, not element type | 23 |
| `+` | Polarity value, not type | 5 |

**The "causal loop" value** appears in the Type column of Connections sheets - this is correct for edges but causes confusion when the same column name is used in Elements sheets.

---

### 4. Column Naming Inconsistencies

#### Case Variations
- `Type` vs `type` - Both appear, sometimes in same file
- `Strength` vs `strength` - Inconsistent casing
- `Confidence` - Consistent

#### Duplicate Columns
Some files have both `Type` and `type` columns with different data:
- Elements: `Type` = DAPSIWRM type, `type` = same or empty
- Connections: `Type` = "causal loop", `type` = same

---

### 5. Sheet Structure by File

#### Arctic DA Files (Complex Multi-variant)

**AdjacencyMatriciesReversed_200125.xlsx** (19 sheets)
- Contains raw adjacency matrices (not useful for import)
- Regional variants: Greenland, Iceland, Faroes, Arctic (combined)
- Sub-variants: C (compact), C Eco (compact ecological)

**Arctic Model edge and node data 20.02.2025V3.xlsx** (6 sheets)
- Best structured Arctic file
- 3 variants: Arctic, Arctic C, Arctic C Eco
- Each has Node Labels + Kumu Edges pair

**Arctic_Kumu_07012025_V2.xlsx** (1 sheet)
- Single sheet "Sheet2" with 96 edges
- No separate node sheet - nodes must be inferred
- 26 unique nodes referenced in edges

**Artic DA_Edges_and_Nodes_12.2024.xlsx** (6 sheets)
- 3 regional variants: Greenland, Iceland, Faroes
- **Problem:** "Edge Labels" sheets have NO Type column
- Only has Label and Description for nodes

#### Macronesia DA (Simple)

**Final Simple SES model_MDA.xlsx** (2 sheets)
- Clean KUMU Standard format
- 17 elements, 45 connections
- All types populated correctly

#### Tuscan DA (Type Problem)

All 4 files follow KUMU Standard format but have:
- Empty Type columns in Elements sheet
- Valid structure otherwise (28-34 elements, 35-97 connections)

---

## Recommendations

### Immediate Fixes Required

1. **Tuscan DA files need type assignment**
   - Add DAPSIWRM types to all 4 files' Elements sheets
   - Types can potentially be inferred from element names/descriptions

2. **Handle "Marine Process and Functioning" variant**
   - Add to type mapping as alias for "Marine Process and Function"

3. **Arctic files with missing types in node sheets**
   - `Artic DA_Edges_and_Nodes_12.2024.xlsx` - Edge Labels sheets have no Type column
   - Need to add Type column or merge with other Arctic file data

### Code Improvements

1. **Type inference from element names**
   - Use keyword matching to guess DAPSIWRM types
   - Keywords: "fishing" → Activity, "pollution" → Pressure, etc.

2. **Better NA handling**
   - Already fixed in `excel_import_helpers.R`
   - Skip rows with NA From/To values
   - Default polarity to "+" when Label is NA

3. **Type value normalization**
   ```r
   type_aliases <- list(
     "Marine Process and Functioning" = "Marine Process and Function",
     "State" = "Marine Process and Function",
     "Impact" = "Ecosystem Service",
     "Welfare" = "Good and Benefit"
   )
   ```

---

## Appendix: Column Frequency Analysis

| Column | Occurrences | Notes |
|--------|-------------|-------|
| Label | 36 | Present in all node/edge sheets |
| Type | 29 | Sometimes empty |
| Direction | 19 | Edge direction |
| From | 19 | Edge source |
| To | 19 | Edge target |
| Confidence | 14 | 1-5 scale |
| strength | 14 | strong/medium/weak |
| type | 13 | Duplicate of Type |
| Description | 12 | Element descriptions |
| Strength | 10 | Case variant |
| betweenness | 9 | Network metric |
| closeness | 9 | Network metric |
| degree | 9 | Network metric |

---

## Files That Should Load Successfully

After the NA handling fixes:

1. **Macronesia DA/Final Simple SES model_MDA.xlsx** - Full support
2. **Arctic DA/Arctic Model edge and node data 20.02.2025V3.xlsx** - Multi-variant support

## Files That Need Data Fixes

1. **All Tuscan DA files** - Need DAPSIWRM types added to Elements
2. **Arctic DA/Artic DA_Edges_and_Nodes_12.2024.xlsx** - Need Type column in Edge Labels sheets
3. **Arctic DA/Arctic_Kumu_07012025_V2.xlsx** - Needs node type inference (no node sheet)

## Unsupported Files

1. **Arctic DA/Leverage points/LeveragePoint_Organorgam_Arctic DA.xlsx** - Not a node/edge model
