# DTU Analytical Functions Integration Plan

## MarineSABRES SES Toolbox — Incorporating DTU Network Dynamics Analysis

**Document Version:** 1.0
**Date:** 2025-07-11
**Status:** Implementation Plan — Awaiting Review

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [DTU Capabilities Inventory](#2-dtu-capabilities-inventory)
3. [Gap Analysis: What the Main Tool Lacks](#3-gap-analysis)
4. [Data Format Mapping](#4-data-format-mapping)
5. [Architecture Design](#5-architecture-design)
6. [Implementation Plan](#6-implementation-plan)
   - 6.1 [Phase 1: Core Engine — functions/ses_dynamics.R](#61-phase-1-core-engine)
   - 6.2 [Phase 2: Boolean Network Module](#62-phase-2-boolean-network-module)
   - 6.3 [Phase 3: Dynamic Simulation Module](#63-phase-3-dynamic-simulation-module)
   - 6.4 [Phase 4: Intervention Analysis Module](#64-phase-4-intervention-analysis-module)
   - 6.5 [Phase 5: Random Forest / Variable Importance Module](#65-phase-5-random-forest-module)
7. [Data Structure Extensions](#7-data-structure-extensions)
8. [Translation Keys](#8-translation-keys)
9. [Package Dependencies](#9-package-dependencies)
10. [Risk Assessment & Mitigations](#10-risk-assessment)
11. [Testing Strategy](#11-testing-strategy)
12. [File Manifest](#12-file-manifest)

---

## 1. Executive Summary

The DTU subdirectory (`DTU/`) contains a standalone Shiny app built by DTU (Technical University of Denmark) that implements advanced network dynamics analysis for Social-Ecological Systems. It provides six analytical capabilities that the main SES Toolbox currently lacks:

| # | DTU Capability | Main Tool Status | Integration Priority |
|---|----------------|-----------------|---------------------|
| 1 | **Laplacian Eigenvalue Analysis** (system stability) | Not present | High |
| 2 | **Boolean Network Modeling** (attractor analysis) | Not present | High |
| 3 | **Deterministic Time-Series Simulation** (linear dynamics) | Not present | High |
| 4 | **Participation Ratio Analysis** (mode distribution) | Not present | Medium |
| 5 | **Monte Carlo State-Shift Analysis** (robustness testing) | Not present | High |
| 6 | **Intervention/Measure Simulation** (what-if analysis) | Partially present (Response Measures module exists but lacks simulation) | Medium |
| 7 | **Random Forest Variable Importance** (ML driver identification) | Not present (ML infra exists but unused) | Low |

The main tool already has:
- Network metrics (centrality, degree, betweenness, PageRank, eigenvector)
- Loop detection and classification (reinforcing/balancing)
- Leverage point identification (composite centrality score)
- MICMAC analysis (influence × exposure quadrants)
- Network simplification (exogenous removal, SISO encapsulation)
- Community detection (Louvain, walktrap, etc.)
- Path analysis (shortest paths, all paths)

**The DTU functions are complementary, not overlapping.** They add *dynamic/temporal* analysis to what is currently a *static/structural* analysis toolkit.

**Estimated effort:** 3–4 weeks across 5 phases.

---

## 2. DTU Capabilities Inventory

### 2.1 Qualitative Analysis Functions

#### `SES.laplacian(SES.mat, from)`
- **Purpose:** Computes eigenvalues of the graph Laplacian matrix to characterize structural stability.
- **Inputs:** Square numeric adjacency matrix, direction parameter ("rows" or "cols").
- **Outputs:** Named numeric vector of eigenvalues (one per node).
- **Interpretation:** A zero eigenvalue indicates a connected component. The smallest non-zero eigenvalue (algebraic connectivity / Fiedler value) indicates how easily the system can be disconnected. Larger eigenvalues indicate faster perturbation decay in those modes.

#### `boolean.file.creation(SES.mat, folder, filename)`
- **Purpose:** Converts the signed adjacency matrix into a BoolNet-compatible CSV specification.
- **Logic:** For each target node, collects positive regulators (kept as-is) and negative regulators (prefixed with `!`), joined with `|` (OR logic). Nodes with no regulators get self-referencing rules.
- **Outputs:** Two-column CSV file (`targets, factors`), returns the data frame.

#### `boolean.analyses(boolean.net, folder, filename)`
- **Purpose:** Runs full Boolean attractor analysis using BoolNet.
- **Computes:**
  - All attractors (stable states and limit cycles) via `BoolNet::getAttractors()`
  - Basin sizes for each attractor
  - State transition graph (exported as GraphML)
- **Outputs:** List with `$states` (2^n), `$N_attractors`, `$basins`, `$attractors`.
- **Scalability concern:** Exhaustive attractor search is O(2^n). For n > ~25 nodes, this becomes prohibitive. Need to add heuristic/sampling modes.

### 2.2 Quantitative Analysis Functions

#### `SES.simulate(SES.mat, iter, save.fig, ...)`
- **Purpose:** Deterministic linear dynamics simulation.
- **Algorithm:** `state[t] = t(SES.mat) %*% state[t-1]`, starting from random uniform initial conditions.
- **Outputs:** Matrix (rows = nodes, columns = timesteps). Visualized as log-scale time series.

#### `participation_ratio(SES, folder, filename, title)`
- **Purpose:** Computes how distributed each dynamical mode is across nodes.
- **Algorithm:** Eigendecomposition of the Jacobian (transposed SES matrix), then: `PR = (sum(|v_i|^2))^2 / (n * sum(|v_i|^4))` per eigenvector.
- **Interpretation:** PR ≈ 1/n means the mode is localized to one node; PR ≈ 1 means all nodes participate equally.
- **Outputs:** Data frame with `components` and `PR` columns.

#### `state.shift(mat, greed, iter, type, folder, file)`
- **Purpose:** Monte Carlo robustness analysis.
- **Algorithm:** Runs `greed` independent simulations with randomized matrix magnitudes (preserving sign structure). Collects final-state vectors. Computes which parameterizations yield "desirable" outcomes.
- **Randomization modes:** `"uniform"` (continuous [0,1]) or `"ordinal"` (discrete: 0, 0.25, 0.5, 0.75, 1).
- **Outputs:** List with `$state.sim` (final states matrix), `$all.mats` (all randomized matrices).

#### `simulate.mat(mat, type)`
- **Purpose:** Generates a single randomized adjacency matrix preserving the sign structure.
- **Used by:** `state.shift()`.

### 2.3 Intervention Analysis Functions

#### `simulate.measure(mat, measure, affected, indicators, lower, upper)`
- **Purpose:** Adds an intervention node to the adjacency matrix.
- **Algorithm:** Creates a new row (outgoing effects on affected nodes) and column (incoming effects from indicator nodes) with random weights sampled within `[lower, upper]`.
- **Outputs:** Extended adjacency matrix with the intervention node appended.

### 2.4 Machine Learning Functions (Currently Unused in DTU UI)

#### `random.forest(sim.outcomes, ntree, folder, file)`
- **Purpose:** Trains a random forest classifier on state-shift simulation outcomes to identify which connection weights most influence desirable outcomes.

#### `random.forest.res(forest, folder, filename1, filename2)`
- **Purpose:** Extracts and visualizes variable importance from trained random forest.

---

## 3. Gap Analysis

### What the Main Tool Has (Static/Structural)

| Existing Analysis | Location | Description |
|-------------------|----------|-------------|
| Network metrics | `functions/network_analysis.R` | Degree, betweenness, closeness, eigenvector, PageRank, density, diameter |
| Loop detection | `functions/network_analysis.R` | DFS-based cycle detection with DAPSIRWRM validation |
| Leverage points | `functions/network_analysis.R` | Composite score: betweenness + eigenvector + PageRank |
| MICMAC | `functions/network_analysis.R` | Influence × exposure quadrant classification |
| Community detection | `functions/network_analysis.R` | Louvain, walktrap, edge betweenness, fast greedy |
| Network simplification | `functions/network_analysis.R` | Exogenous removal, SISO encapsulation |
| Path analysis | `functions/network_analysis.R` | Shortest paths, all simple paths |

### What DTU Adds (Dynamic/Temporal) — NEW capabilities

| New Analysis | DTU Source | What It Adds |
|--------------|-----------|--------------|
| **Laplacian stability** | `utils.R::SES.laplacian()` | Eigenvalue-based structural stability characterization |
| **Boolean modeling** | `utils.R::boolean.*()` | Attractor analysis — what stable states can the system reach? |
| **Time-series simulation** | `utils.R::SES.simulate()` | How does the system evolve over time under linear dynamics? |
| **Participation ratio** | `utils.R::participation_ratio()` | Which nodes dominate which dynamical modes? |
| **State-shift Monte Carlo** | `utils.R::state.shift()` | How robust are outcomes to parameter uncertainty? |
| **Intervention modeling** | `utils.R::simulate.measure()` | What-if analysis for management measures |
| **ML driver identification** | `utils.R::random.forest*()` | Which connections most determine desirable outcomes? |

### Overlap Assessment

There is **zero functional overlap**. The main tool's existing analyses are all *structural* (graph-theoretic), while DTU's analyses are all *dynamical* (matrix algebra, simulation, Boolean logic, ML). They are fully complementary.

The only shared code patterns are:
- Both use `igraph` for graph construction
- Both work with adjacency matrices
- Both produce interactive visualizations (plotly/visNetwork)

---

## 4. Data Format Mapping

### 4.1 The Critical Bridge: CLD → Numeric Adjacency Matrix

The DTU functions all operate on a **square numeric adjacency matrix** where:
- Rows and columns are node names
- Cell values are numeric weights: +1, +0.5, -0.5, -1 (or continuous)

The main SES Tool stores data differently:
- **ISA adjacency matrices:** 10 separate segment-pair matrices (`d_a`, `a_p`, etc.) with string-encoded values like `"+strong:4"`, `"-medium:3"`
- **CLD edges:** Data frame with `from`, `to`, `polarity` ("+"/"-"), `strength` ("strong"/"medium"/"weak"), `confidence` (1-5)

**The bridge function must:**
1. Take CLD nodes + edges (or ISA adjacency matrices)
2. Map polarity × strength to numeric weights
3. Produce a single square numeric adjacency matrix suitable for DTU functions

### 4.2 Proposed Weight Mapping

| Polarity | Strength | Numeric Weight | DTU Equivalent |
|----------|----------|---------------|----------------|
| + | strong | +1.0 | Strong Positive |
| + | medium | +0.5 | Medium Positive |
| + | weak | +0.25 | *(new — DTU maps to +1 by default, which is a known bug)* |
| - | strong | -1.0 | Strong Negative |
| - | medium | -0.5 | Medium Negative |
| - | weak | -0.25 | *(new — DTU maps to +1 by default, which is a known bug)* |

### 4.3 Bridge Function: `cld_to_numeric_matrix()`

```r
#' Convert CLD data to a square numeric adjacency matrix
#'
#' @param nodes Data frame with at least 'id' and 'label' columns
#' @param edges Data frame with 'from', 'to', 'polarity', 'strength', 'confidence' columns
#' @param use_labels Logical — use labels (human-readable) or IDs as row/col names
#' @param weight_map Named list mapping polarity+strength combos to numeric values
#' @param include_confidence Logical — scale weights by confidence level
#' @return Named square numeric matrix
cld_to_numeric_matrix <- function(nodes, edges,
                                   use_labels = TRUE,
                                   weight_map = NULL,
                                   include_confidence = FALSE) {

  if (is.null(weight_map)) {
    weight_map <- list(
      "+strong"  =  1.0,
      "+medium"  =  0.5,
      "+weak"    =  0.25,
      "-strong"  = -1.0,
      "-medium"  = -0.5,
      "-weak"    = -0.25
    )
  }

  # Build node name vector
  node_names <- if (use_labels && "label" %in% names(nodes)) {
    ifelse(is.na(nodes$label) | nodes$label == "", nodes$id, nodes$label)
  } else {
    nodes$id
  }
  names(node_names) <- nodes$id

  n <- length(node_names)
  mat <- matrix(0, nrow = n, ncol = n)
  rownames(mat) <- node_names
  colnames(mat) <- node_names

  # Build edge index for O(1) lookup
  id_to_idx <- setNames(seq_along(nodes$id), nodes$id)

  for (i in seq_len(nrow(edges))) {
    from_idx <- id_to_idx[edges$from[i]]
    to_idx   <- id_to_idx[edges$to[i]]
    if (is.na(from_idx) || is.na(to_idx)) next

    key <- paste0(edges$polarity[i], edges$strength[i])
    w <- weight_map[[key]]
    if (is.null(w)) w <- ifelse(edges$polarity[i] == "+", 0.5, -0.5)  # fallback

    if (include_confidence && "confidence" %in% names(edges)) {
      conf <- as.numeric(edges$confidence[i])
      if (!is.na(conf)) w <- w * (conf / 5)
    }

    mat[from_idx, to_idx] <- w
  }

  return(mat)
}
```

### 4.4 Alternative Bridge: ISA Adjacency Matrices → Numeric Matrix

```r
#' Assemble ISA segment-pair matrices into a single numeric matrix
#'
#' @param isa_data The isa_data list from project_data
#' @return Named square numeric matrix (NULL if no data)
isa_to_numeric_matrix <- function(isa_data) {
  # Collect all element names across all types
  types <- c("drivers", "activities", "pressures", "marine_processes",
             "ecosystem_services", "goods_benefits", "responses")
  all_names <- character(0)
  for (type in types) {
    df <- isa_data[[type]]
    if (!is.null(df) && nrow(df) > 0) {
      all_names <- c(all_names, setNames(df$name, df$id))
    }
  }
  if (length(all_names) == 0) return(NULL)

  n <- length(all_names)
  mat <- matrix(0, nrow = n, ncol = n)
  rownames(mat) <- all_names
  colnames(mat) <- all_names

  # Map each segment-pair matrix
  pairs <- names(isa_data$adjacency_matrices)
  id_to_name <- all_names  # named by id

  for (pair_name in pairs) {
    seg_mat <- isa_data$adjacency_matrices[[pair_name]]
    if (is.null(seg_mat) || !is.matrix(seg_mat)) next

    for (r in seq_len(nrow(seg_mat))) {
      for (c in seq_len(ncol(seg_mat))) {
        val <- seg_mat[r, c]
        if (is.na(val) || val == "") next
        parsed <- parse_connection_value(val)
        weight <- switch(paste0(parsed$polarity, parsed$strength),
          "+strong" = 1.0, "+medium" = 0.5, "+weak" = 0.25,
          "-strong" = -1.0, "-medium" = -0.5, "-weak" = -0.25,
          0.5)  # fallback

        from_name <- id_to_name[rownames(seg_mat)[r]]
        to_name   <- id_to_name[colnames(seg_mat)[c]]
        if (!is.na(from_name) && !is.na(to_name)) {
          mat[from_name, to_name] <- weight
        }
      }
    }
  }

  return(mat)
}
```

---

## 5. Architecture Design

### 5.1 Module Structure

```
MarineSABRES_SES_Shiny/
  functions/
    ses_dynamics.R              ← NEW: Core analytical engine (adapted from DTU/utils.R)
    network_analysis.R          ← EXISTING: Add cld_to_numeric_matrix(), isa_to_numeric_matrix()
  modules/
    analysis_boolean.R          ← NEW: Boolean Network & Laplacian Analysis module
    analysis_simulation.R       ← NEW: Dynamic Simulation & State-Shift module
    analysis_intervention.R     ← NEW: Intervention/Measure Simulation module
    analysis_rf_importance.R    ← NEW: Random Forest Variable Importance module (Phase 5)
  translations/
    modules/
      analysis_boolean.json     ← NEW
      analysis_simulation.json  ← NEW
      analysis_intervention.json← NEW
      analysis_rf_importance.json ← NEW
    ui/
      sidebar.json              ← MODIFIED: Add new menu entries
```

### 5.2 Module Dependencies

```
              ┌────────────────────────────────┐
              │      CLD / ISA Data             │
              │  (project_data$data$cld or isa) │
              └──────────┬─────────────────────┘
                         │
              ┌──────────▼──────────────────────┐
              │  cld_to_numeric_matrix()         │
              │  (functions/network_analysis.R)  │
              └──────────┬──────────────────────┘
                         │  numeric adjacency matrix
              ┌──────────▼──────────────────────┐
              │  functions/ses_dynamics.R         │
              │  (Core DTU engine, refactored)   │
              └──┬──────┬──────┬──────┬─────────┘
                 │      │      │      │
        ┌────────▼┐ ┌───▼───┐ ┌▼─────┐ ┌▼────────┐
        │Boolean  │ │Simul. │ │Interv│ │RF Import.│
        │Module   │ │Module │ │Module│ │Module    │
        └─────────┘ └───────┘ └──────┘ └──────────┘
```

### 5.3 Data Flow Through Analysis Pipeline

```
1. User builds SES (ISA data entry or AI assistant)
2. Reactive pipeline auto-generates CLD (nodes + edges)
3. User navigates to new analysis module
4. Module calls cld_to_numeric_matrix() to get numeric matrix
5. Module calls ses_dynamics.R functions for analysis
6. Results stored in project_data$data$analysis$dynamics (new slot)
7. Results available for export via existing export infrastructure
```

---

## 6. Implementation Plan

### 6.1 Phase 1: Core Engine — `functions/ses_dynamics.R`

**Goal:** Extract, refactor, and harden all DTU analytical functions into a standalone library file that follows the main tool's coding conventions.

**Key adaptations from DTU `utils.R`:**
1. **Remove file I/O:** DTU functions write PNGs, CSVs, and .Rdata files to disk. Refactored functions return data objects only; the Shiny modules handle visualization.
2. **Remove folder parameters:** No `folder`, `filename` parameters. Pure computation only.
3. **Fix the strength mapping bug:** DTU maps "Weak Positive/Negative" to +1 (default). Fix to +0.25/-0.25.
4. **Add input validation:** Use `safe_execute()` pattern from `error_handling.R`.
5. **Add scalability guards:** Boolean analysis is O(2^n). Add node-count limits and heuristic mode.
6. **Use `debug_log()`** instead of `cat()`.

**Functions to include in `ses_dynamics.R`:**

```r
# ── Stability Analysis ──────────────────────────────────────
ses_laplacian_eigenvalues(mat, direction = "cols")
  # Returns: named numeric vector of eigenvalues

# ── Boolean Network Analysis ────────────────────────────────
ses_create_boolean_rules(mat)
  # Returns: data frame with columns 'targets' and 'factors'
  # (No file I/O — returns the rules directly)

ses_boolean_attractors(boolean_rules, max_nodes = 25)
  # Returns: list($n_states, $n_attractors, $attractors, $basins, $transition_graph)
  # max_nodes guard: if n > max_nodes, returns error with message

# ── Deterministic Simulation ────────────────────────────────
ses_simulate(mat, n_iter = 500, initial_state = NULL)
  # Returns: matrix (rows = nodes, cols = timesteps)
  # If initial_state is NULL, uses random uniform [0,1]

# ── Participation Ratio ─────────────────────────────────────
ses_participation_ratio(mat)
  # Returns: data frame with columns 'node', 'participation_ratio'

# ── Monte Carlo State-Shift ─────────────────────────────────
ses_randomize_matrix(mat, type = "uniform")
  # Returns: randomized matrix (preserving sign structure)

ses_state_shift(mat, n_simulations = 100, n_iter = 500,
                type = "uniform", target_nodes = NULL)
  # Returns: list($final_states, $success_rate, $all_matrices,
  #               $target_success_matrix)
  # target_nodes: character vector of node names that should end positive

# ── Intervention Simulation ─────────────────────────────────
ses_add_intervention(mat, name, affected_nodes, indicator_nodes,
                     effect_range = c(-1, 1))
  # Returns: extended adjacency matrix with intervention node

ses_compare_interventions(mat_original, mat_intervention, n_iter = 500)
  # Returns: data frame with per-node state comparison

# ── Random Forest Analysis ──────────────────────────────────
ses_rf_importance(state_shift_results, n_trees = 1000)
  # Returns: list($model, $importance, $top_variables)
```

**Sourcing:** Add to `global.R`:
```r
source("functions/ses_dynamics.R", local = TRUE)
```

### 6.2 Phase 2: Boolean Network & Laplacian Module

**File:** `modules/analysis_boolean.R`

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ [Module Header: Boolean Network & Stability Analysis]       │
│ [Help button]                                               │
├─────────────────────────────────────────────────────────────┤
│ [CLD Data Validation Check]                                 │
├──────────────────────┬──────────────────────────────────────┤
│ Controls Panel       │ Results Panel                        │
│                      │                                      │
│ [Run Analysis]       │ Tab 1: Laplacian Eigenvalues         │
│                      │   - plotlyOutput (bar chart)         │
│ Options:             │   - Fiedler value interpretation     │
│ ○ Laplacian dir:     │   - DataTable of all eigenvalues     │
│   rows / cols        │                                      │
│                      │ Tab 2: Boolean Network               │
│ ○ Max nodes for      │   - Status: n genes, n interactions  │
│   Boolean: [25]      │   - Boolean rules table (DT)         │
│                      │   - Number of attractors              │
│ [Download Results]   │   - Basin sizes bar chart (plotly)    │
│                      │   - Attractor state table             │
│                      │                                      │
│                      │ Tab 3: Stability Summary              │
│                      │   - Combined interpretation text      │
│                      │   - Key findings cards                │
└──────────────────────┴──────────────────────────────────────┘
```

**Server logic:**
```r
analysis_boolean_server <- function(id, project_data_reactive, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Standard header + help
    create_reactive_header(output, ns, ...)
    create_help_observer(input, ...)

    # Local reactive values
    rv <- reactiveValues(
      numeric_matrix = NULL,
      laplacian_results = NULL,
      boolean_rules = NULL,
      boolean_results = NULL
    )

    # CLD validation gate
    output$cld_check_ui <- renderUI({ ... })

    # Run analysis
    observeEvent(input$run_analysis, {
      data <- project_data_reactive()
      req(has_valid_cld(data))

      # Convert CLD to numeric matrix
      rv$numeric_matrix <- cld_to_numeric_matrix(
        data$data$cld$nodes, data$data$cld$edges
      )

      # Laplacian
      withProgress(message = i18n$t("..."), {
        rv$laplacian_results <- ses_laplacian_eigenvalues(
          rv$numeric_matrix, direction = input$laplacian_direction
        )
        incProgress(0.5)

        # Boolean (with node count guard)
        rv$boolean_rules <- ses_create_boolean_rules(rv$numeric_matrix)
        n_nodes <- nrow(rv$numeric_matrix)
        if (n_nodes <= input$max_boolean_nodes) {
          rv$boolean_results <- ses_boolean_attractors(rv$boolean_rules)
        }
        incProgress(0.5)
      })

      # Store in project data
      data$data$analysis$dynamics$laplacian <- rv$laplacian_results
      data$data$analysis$dynamics$boolean <- rv$boolean_results
      data$last_modified <- Sys.time()
      project_data_reactive(data)
    })
  })
}
```

**Registration (4 touch points):**
1. `app.R` module_files: `"modules/analysis_boolean.R"`
2. `app.R` bs4TabItems: `bs4TabItem(tabName = "analysis_boolean", analysis_boolean_ui("analysis_bool", i18n))`
3. `app.R` server: `analysis_boolean_server("analysis_bool", project_data, session_i18n)`
4. `ui_sidebar.R`: Add under Analysis Tools → `tabName = "analysis_boolean"`

### 6.3 Phase 3: Dynamic Simulation Module

**File:** `modules/analysis_simulation.R`

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ [Module Header: Dynamic Simulation & State Analysis]        │
├─────────────────────────────────────────────────────────────┤
│ [CLD Data Validation Check]                                 │
├──────────────────────┬──────────────────────────────────────┤
│ Controls             │ Results                              │
│                      │                                      │
│ -- Simulation --     │ Tab 1: Time Series                   │
│ Iterations: [500]    │   - plotlyOutput (log-scale lines)   │
│ [Run Simulation]     │   - Node selection filter            │
│                      │                                      │
│ -- State Shift --    │ Tab 2: Phase Space (PCA)             │
│ N simulations: [100] │   - plotlyOutput (2D trajectory)     │
│ Randomization:       │                                      │
│   ○ Uniform          │ Tab 3: Participation Ratio           │
│   ○ Ordinal          │   - plotlyOutput (bar chart)         │
│ Target nodes:        │   - Interpretation text              │
│   [multi-select]     │                                      │
│ [Run State Shift]    │ Tab 4: State-Shift Results           │
│                      │   - Success rate display             │
│ [Download Results]   │   - Final states heatmap (plotly)    │
│                      │   - Per-node outcome distribution    │
│                      │   - Summary statistics table         │
└──────────────────────┴──────────────────────────────────────┘
```

**Key implementation notes:**
- Time-series simulation can run synchronously (fast — pure matrix multiplication).
- State-shift Monte Carlo should use `shiny::withProgress()` for the outer loop, updating progress after each simulation.
- For large `greed` values (>500), consider `future::future()` with the async helpers already present in `functions/async_helpers.R`.
- PCA visualization uses `prcomp()` on the transposed simulation matrix.

### 6.4 Phase 4: Intervention Analysis Module

**File:** `modules/analysis_intervention.R`

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ [Module Header: Intervention & Measure Simulation]          │
├─────────────────────────────────────────────────────────────┤
│ [CLD + Simulation Data Validation Check]                    │
├──────────────────────┬──────────────────────────────────────┤
│ Intervention Design  │ Results                              │
│                      │                                      │
│ Name: [text input]   │ Tab 1: Modified Network              │
│                      │   - visNetworkOutput (intervention   │
│ Affected nodes:      │     node highlighted in red)         │
│   [multi-select]     │                                      │
│                      │ Tab 2: State Comparison              │
│ Indicator nodes:     │   - Grouped bar chart (original vs   │
│   [multi-select]     │     intervention final states)       │
│                      │   - Delta table (per-node change)    │
│ Effect range:        │                                      │
│   [-1 ———|——— 1]     │ Tab 3: Multiple Interventions        │
│                      │   - Compare up to 5 scenarios        │
│ [Add Intervention]   │   - Radar/spider chart comparison    │
│ [Run Analysis]       │                                      │
│                      │ Tab 4: Intervention History          │
│ Saved interventions: │   - Table of all tested interventions│
│   [list]             │   - Best intervention recommendation │
└──────────────────────┴──────────────────────────────────────┘
```

**Integration with existing Response Measures module:**
The main tool already has `modules/response_measures_module.R` where users define management responses. The intervention module should:
1. Auto-populate intervention candidates from `project_data$data$isa_data$responses`
2. Allow manual definition of new interventions
3. Link results back to the response measures data

### 6.5 Phase 5: Random Forest Variable Importance Module

**File:** `modules/analysis_rf_importance.R`

**Prerequisites:** State-shift analysis must be completed first (it provides the training data).

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ [Module Header: Connection Importance Analysis (ML)]        │
├─────────────────────────────────────────────────────────────┤
│ [State-Shift Results Validation Check]                      │
├──────────────────────┬──────────────────────────────────────┤
│ Controls             │ Results                              │
│                      │                                      │
│ Target definition:   │ Tab 1: Variable Importance           │
│   [select target     │   - Horizontal bar chart (plotly)    │
│    nodes from        │   - Top 20 most important            │
│    state-shift]      │     connections                      │
│                      │                                      │
│ Trees: [1000]        │ Tab 2: Partial Dependence            │
│                      │   - PDP plots for top 5 connections  │
│ [Train Model]        │                                      │
│                      │ Tab 3: Model Performance             │
│                      │   - OOB error rate                   │
│                      │   - Confusion matrix                 │
│                      │   - Success prediction accuracy      │
└──────────────────────┴──────────────────────────────────────┘
```

**Note:** This uses the `randomForest` package. The main tool already has ML infrastructure (`functions/ml_*.R` files and optional torch support). The RF module is simpler and doesn't require torch.

---

## 7. Data Structure Extensions

### 7.1 New Slot in `create_empty_project()`

Add to `functions/data_structure.R` inside `create_empty_project()` → `data$analysis`:

```r
analysis = list(
  loops = NULL,
  leverage_points = NULL,
  scenarios = list(),

  # NEW: DTU-derived dynamics analysis results
  dynamics = list(
    # Numeric adjacency matrix used for all analyses
    numeric_matrix = NULL,         # matrix
    matrix_params = list(          # parameters used to build it
      source = NULL,               # "cld" or "isa"
      weight_map = NULL,           # the weight mapping used
      include_confidence = FALSE,
      timestamp = NULL
    ),

    # Qualitative analysis
    laplacian = list(
      eigenvalues = NULL,          # named numeric vector
      direction = NULL,            # "rows" or "cols"
      fiedler_value = NULL,        # smallest non-zero eigenvalue
      timestamp = NULL
    ),
    boolean = list(
      rules = NULL,                # data frame (targets, factors)
      n_states = NULL,             # integer (2^n)
      n_attractors = NULL,         # integer
      attractors = NULL,           # list of data frames
      basins = NULL,               # numeric vector
      timestamp = NULL
    ),

    # Quantitative analysis
    simulation = list(
      time_series = NULL,          # matrix (nodes × timesteps)
      n_iter = NULL,
      initial_state = NULL,
      timestamp = NULL
    ),
    participation_ratio = NULL,     # data frame (node, PR)

    state_shift = list(
      final_states = NULL,         # matrix (nodes × simulations)
      n_simulations = NULL,
      randomization_type = NULL,   # "uniform" or "ordinal"
      target_nodes = NULL,
      success_rate = NULL,
      timestamp = NULL
    ),

    # Interventions
    interventions = list(),        # list of intervention results

    # ML analysis
    rf_importance = list(
      model = NULL,                # randomForest object
      importance = NULL,           # data frame
      top_variables = NULL,
      timestamp = NULL
    )
  )
)
```

### 7.2 Backward Compatibility

Since `create_empty_project()` is only called for new projects, existing saved projects won't have the `dynamics` slot. All modules must use `safe_get_nested()` to access this data:

```r
# Safe access pattern
sim_results <- safe_get_nested(data, "data", "analysis", "dynamics", "simulation",
                                default = list())
```

---

## 8. Translation Keys

### 8.1 New Translation File: `translations/modules/analysis_boolean.json`

Key namespace: `modules.analysis_boolean.*`

Required keys (minimum):
```
modules.analysis_boolean.title
modules.analysis_boolean.subtitle
modules.analysis_boolean.help_title
modules.analysis_boolean.help_text
modules.analysis_boolean.run_analysis
modules.analysis_boolean.laplacian_tab
modules.analysis_boolean.boolean_tab
modules.analysis_boolean.stability_tab
modules.analysis_boolean.laplacian_direction
modules.analysis_boolean.max_nodes
modules.analysis_boolean.max_nodes_warning
modules.analysis_boolean.eigenvalues_chart_title
modules.analysis_boolean.fiedler_value
modules.analysis_boolean.n_attractors
modules.analysis_boolean.basin_sizes
modules.analysis_boolean.attractor_states
modules.analysis_boolean.boolean_rules
modules.analysis_boolean.no_cld_data
```

### 8.2 New Translation File: `translations/modules/analysis_simulation.json`

Key namespace: `modules.analysis_simulation.*`

### 8.3 New Translation File: `translations/modules/analysis_intervention.json`

Key namespace: `modules.analysis_intervention.*`

### 8.4 New Translation File: `translations/modules/analysis_rf_importance.json`

Key namespace: `modules.analysis_rf_importance.*`

### 8.5 Sidebar Keys (add to `translations/ui/sidebar.json`)

```
ui.sidebar.boolean_analysis
ui.sidebar.tooltip.boolean_analysis
ui.sidebar.dynamic_simulation
ui.sidebar.tooltip.dynamic_simulation
ui.sidebar.intervention_analysis
ui.sidebar.tooltip.intervention_analysis
ui.sidebar.rf_importance
ui.sidebar.tooltip.rf_importance
```

---

## 9. Package Dependencies

### 9.1 New Required Packages

| Package | Used By | Purpose | CRAN | Already in Main Tool? |
|---------|---------|---------|------|----------------------|
| `BoolNet` | Phase 2 | Boolean network attractor analysis | Yes | **No — must add** |
| `randomForest` | Phase 5 | Variable importance analysis | Yes | **No — must add** |
| `reshape2` | Phase 3 | Matrix melting for state-shift | Yes | **No — must add** (or use `tidyr::pivot_longer`) |

### 9.2 Already Available Packages

| Package | Used By | Already Loaded In |
|---------|---------|-------------------|
| `igraph` | All phases | `global.R` |
| `plotly` | All phases (visualization) | `global.R` |
| `visNetwork` | Phase 4 (intervention network) | `global.R` |
| `DT` | All phases (data tables) | `global.R` |
| `ggplot2` | Phases 3, 5 (via plotly) | `global.R` (tidyverse) |
| `shinyWidgets` | All phases (UI controls) | `global.R` |

### 9.3 Installation Strategy

Add to `install_packages.R`:
```r
# DTU dynamics analysis packages
install.packages("BoolNet")        # Boolean network analysis
install.packages("randomForest")   # ML variable importance (Phase 5)
```

Add conditional loading to `global.R` (like ML modules):
```r
# Boolean/dynamics packages (optional - graceful degradation)
DYNAMICS_AVAILABLE <- tryCatch({
  library(BoolNet)
  TRUE
}, error = function(e) {
  warning("BoolNet not installed. Boolean analysis will be unavailable.")
  FALSE
})
```

---

## 10. Risk Assessment

### 10.1 Scalability — Boolean Analysis O(2^n)

**Risk:** Boolean attractor search enumerates all 2^n states. For n=20 nodes, that's 1M states. For n=25, it's 33M. For n=30, it's 1B — system will hang or crash.

**Mitigation:**
- Hard limit: `max_nodes = 25` (configurable, default 25)
- If CLD has > 25 nodes, show warning and offer:
  1. Use simplified CLD (existing simplification tools)
  2. Skip Boolean analysis
  3. Use heuristic mode (random sampling of initial states instead of exhaustive search)
- Display estimated computation time before running

### 10.2 Simulation Divergence

**Risk:** Linear dynamics `state[t] = A^T * state[t-1]` can diverge to ±∞ if the spectral radius of A^T is > 1 (which it often is for real SES matrices).

**Mitigation:**
- Monitor for NaN/Inf during simulation; stop early if detected
- Offer normalized simulation mode: `state[t] = A^T * state[t-1] / ||A^T * state[t-1]||`
- Display warning if eigenvalues suggest divergence
- Cap displayed values at a reasonable range in plots

### 10.3 Memory — State-Shift Monte Carlo

**Risk:** Running 1000 simulations × 500 iterations × 50 nodes creates large matrices in memory.

**Mitigation:**
- Only store final states (not full time series) for Monte Carlo runs
- Limit default to n_simulations=100, allow up to 1000
- Show memory estimate before running large analyses
- Use `gc()` between batches

### 10.4 Package Availability

**Risk:** `BoolNet` or `randomForest` may not be installed on user's machine.

**Mitigation:**
- Graceful degradation: modules check for package availability at load time
- Show "Package not installed" message with installation instructions
- Boolean module and RF module are independent — one can work without the other
- Core simulation functions (Phases 1, 3) only need base R + igraph (already available)

### 10.5 Data Quality — Weak Strength Bug

**Risk:** DTU's `data.load()` maps unrecognized strength values (including "Weak Positive/Negative") to +1. If we import DTU sample data, results may differ from what DTU users expect.

**Mitigation:**
- Our `cld_to_numeric_matrix()` properly maps weak strengths to ±0.25
- Document the difference
- When importing DTU CSV data, apply our corrected mapping
- Add a "DTU compatibility mode" toggle that replicates the original +1 default for comparison

---

## 11. Testing Strategy

### 11.1 Unit Tests (functions/ses_dynamics.R)

Create `tests/test_ses_dynamics.R`:

```r
# Test 1: cld_to_numeric_matrix produces correct dimensions
test_that("cld_to_numeric_matrix creates NxN matrix", { ... })

# Test 2: Weight mapping is correct
test_that("polarity × strength maps to correct numeric weights", { ... })

# Test 3: Laplacian eigenvalues are real
test_that("ses_laplacian_eigenvalues returns real values", { ... })

# Test 4: Boolean rules generation handles edge cases
test_that("ses_create_boolean_rules handles isolated nodes", { ... })

# Test 5: Simulation does not crash on small networks
test_that("ses_simulate runs without error on 3-node network", { ... })

# Test 6: State-shift returns correct dimensions
test_that("ses_state_shift returns matrix of correct size", { ... })

# Test 7: Intervention adds exactly one row and one column
test_that("ses_add_intervention extends matrix correctly", { ... })

# Test 8: Divergence detection works
test_that("ses_simulate detects and handles divergence", { ... })
```

### 11.2 Integration Tests

Use DTU's sample data (`DTU/data/macaronesia_isa5_May2024.csv`) as a golden test:

```r
# Load DTU sample data, convert to CLD format, run all analyses
# Compare key metrics with known DTU outputs:
# - Number of eigenvalues should equal number of unique nodes (18)
# - Boolean attractors should be deterministic for same input
# - Simulation matrix should have dimensions 18 × n_iter
```

### 11.3 Manual UI Testing

For each module:
1. Navigate to module with no data → verify warning message
2. Create sample SES via AI assistant or template
3. Run analysis → verify all outputs render
4. Export results → verify download works
5. Change language → verify all labels update
6. Resize browser → verify responsive layout

---

## 12. File Manifest

### New Files

| File | Phase | Type | Description |
|------|-------|------|-------------|
| `functions/ses_dynamics.R` | 1 | Core engine | All DTU analytical functions, refactored |
| `modules/analysis_boolean.R` | 2 | Shiny module | Boolean network & Laplacian UI + server |
| `modules/analysis_simulation.R` | 3 | Shiny module | Dynamic simulation & state-shift UI + server |
| `modules/analysis_intervention.R` | 4 | Shiny module | Intervention analysis UI + server |
| `modules/analysis_rf_importance.R` | 5 | Shiny module | Random forest importance UI + server |
| `translations/modules/analysis_boolean.json` | 2 | i18n | Translations for Boolean module |
| `translations/modules/analysis_simulation.json` | 3 | i18n | Translations for simulation module |
| `translations/modules/analysis_intervention.json` | 4 | i18n | Translations for intervention module |
| `translations/modules/analysis_rf_importance.json` | 5 | i18n | Translations for RF module |
| `tests/test_ses_dynamics.R` | 1 | Tests | Unit tests for core engine |

### Modified Files

| File | Phase | Changes |
|------|-------|---------|
| `functions/data_structure.R` | 1 | Add `dynamics` slot to `create_empty_project()` |
| `functions/network_analysis.R` | 1 | Add `cld_to_numeric_matrix()`, `isa_to_numeric_matrix()` |
| `global.R` | 1 | Source `ses_dynamics.R`, conditional load of BoolNet/randomForest |
| `app.R` | 2-5 | Register new modules (module_files, bs4TabItems, server calls) |
| `functions/ui_sidebar.R` | 2-5 | Add sidebar menu entries for new modules |
| `translations/ui/sidebar.json` | 2-5 | Add sidebar translation keys |
| `install_packages.R` | 1 | Add BoolNet, randomForest |
| `constants.R` | 1 | Add `DYNAMICS_MAX_BOOLEAN_NODES`, `DYNAMICS_DEFAULT_ITER`, etc. |

### Files NOT Modified (preserved as reference)

| File | Reason |
|------|--------|
| `DTU/app.r` | Preserved as reference implementation |
| `DTU/utils.R` | Preserved as reference — we create `ses_dynamics.R` instead |
| `DTU/data/` | Preserved as test data |

---

## Appendix A: DTU Sample Data Column Mapping

| DTU CSV Column | Main Tool Equivalent | Notes |
|---------------|---------------------|-------|
| `from` | CLD `edges$from` | Node name (not ID) |
| `to` | CLD `edges$to` | Node name (not ID) |
| `strength` | CLD `edges$polarity` + `edges$strength` | Must split: "Strong Positive" → polarity="+", strength="strong" |
| `type` | CLD `nodes$group` | DAPSIWRM type |
| `label` | CLD `edges$title` | Edge label/description |
| `connection type` | Not directly mapped | "within"/"between" — could map to edge metadata |

---

## Appendix B: Constants to Add to `constants.R`

```r
# ── DTU Dynamics Analysis Constants ──────────────────────────
DYNAMICS_MAX_BOOLEAN_NODES   <- 25L     # Hard limit for exhaustive Boolean analysis
DYNAMICS_DEFAULT_ITER        <- 500L    # Default simulation iterations
DYNAMICS_MIN_ITER            <- 50L     # Minimum iterations
DYNAMICS_MAX_ITER            <- 5000L   # Maximum iterations
DYNAMICS_DEFAULT_GREED       <- 100L    # Default Monte Carlo simulations
DYNAMICS_MAX_GREED           <- 2000L   # Maximum Monte Carlo simulations
DYNAMICS_DEFAULT_RF_TREES    <- 1000L   # Default random forest trees
DYNAMICS_DIVERGENCE_THRESHOLD <- 1e10   # Value above which simulation is considered diverged

# Weight mapping: polarity + strength → numeric
DYNAMICS_WEIGHT_MAP <- list(
  "+strong"  =  1.00,
  "+medium"  =  0.50,
  "+weak"    =  0.25,
  "-strong"  = -1.00,
  "-medium"  = -0.50,
  "-weak"    = -0.25
)
```
