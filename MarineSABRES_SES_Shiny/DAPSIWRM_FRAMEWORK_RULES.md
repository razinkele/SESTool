# DAPSIWRM Framework Rules for SES Analysis

## Framework Overview

The DAPSIWRM (Drivers-Activities-Pressures-State-Impacts-Welfare-Responses-Measures) framework extends the traditional DPSIR model to provide a more comprehensive socio-ecological systems analysis. This document defines the structural rules and connection logic for implementing DAPSIWRM-based SES templates.

## Component Categories

### 1. DRIVERS (D)
**Definition**: Root causes and fundamental needs that motivate human activities
**Examples**:
- Food security needs
- Economic development aspirations
- Tourism demand
- Climate change adaptation needs

**Characteristics**:
- Represent underlying societal needs and pressures
- Can be basic needs, economic goals, or policy objectives
- Often cyclical - can be reinforced by impacts/welfare outcomes

### 2. ACTIVITIES (A)
**Definition**: Human actions and operations undertaken to meet driver needs
**Examples**:
- Fishing (artisanal/commercial)
- Agricultural production
- Tourism operations
- Coastal development
- Waste management

**Characteristics**:
- Direct human interventions in the environment
- Sector-specific (fisheries, tourism, agriculture, etc.)
- Scale-dependent (artisanal, commercial, industrial)
- Multiple activities can address the same driver

### 3. PRESSURES (P)
**Definition**: Environmental stressors created by activities
**Examples**:
- Removal of fish biomass
- Chemical contamination
- Habitat destruction
- Nutrient enrichment
- Physical disturbance

**Characteristics**:
- Direct environmental impacts from activities
- Can be cumulative (multiple activities creating same pressure)
- Quantifiable where possible (extraction rates, pollution loads)

### 4. COMPONENTS (C) / STATE (S)
**Definition**: Elements of the ecosystem affected by pressures
**Examples**:
- Fish stocks
- Coral reef health
- Water quality
- Seagrass coverage
- Biodiversity indices

**Characteristics**:
- Measurable ecosystem elements
- Subject to state change
- Can be physical, chemical, or biological
- Have thresholds and tipping points

### 5. ECOSYSTEM SERVICES (ES) / IMPACTS (I)
**Definition**: Benefits and functions provided by ecosystem components
**Examples**:
- Provision of fish
- Coastal protection
- Water filtration
- Habitat for biodiversity
- Carbon sequestration

**Characteristics**:
- Flow from ecosystem state/components
- Can be provisioning, regulating, supporting, or cultural
- Link natural systems to human welfare

### 6. GOODS & BENEFITS (GB) / WELFARE (W)
**Definition**: Tangible products and human welfare outcomes derived from ecosystem services
**Examples**:
- Fish in the market
- Clean beaches
- Protected coastlines
- Tourism revenue
- Food security

**Characteristics**:
- Direct human welfare components
- Economic and social values
- Marketable and non-marketable benefits

### 7. HUMAN WELLBEING (HW) / IMPACTS ON WELFARE
**Definition**: Overall effects on human quality of life and societal welfare
**Examples**:
- Nutrition/malnutrition
- Economic prosperity
- Health outcomes
- Cultural identity
- Livelihood security

**Characteristics**:
- Aggregate effects on society
- Can be positive or negative
- Feed back to reinforce or modify drivers

### 8. RESPONSES (R)
**Definition**: Policy responses, regulations, and management interventions
**Examples**:
- Fishing quotas
- Marine protected areas
- Pollution regulations
- Monitoring programs
- Certification schemes

**Characteristics**:
- Policy and governance interventions
- Can target multiple points in the cycle
- Typically top-down management

### 9. MEASURES (M)
**Definition**: Specific actions, practices, and technologies implemented as solutions
**Examples**:
- Selective fishing gear
- Wastewater treatment facilities
- Coral restoration projects
- Alternative livelihoods
- Renewable energy adoption

**Characteristics**:
- Concrete implementation actions
- Can be technological, behavioral, or structural
- Often bottom-up or participatory
- Treated as a subtype of responses in the model

## Valid Connection Rules

### Primary Causal Chain (Forward Connections)

1. **D → A** (Drivers motivate Activities)
   - Polarity: Typically reinforcing (+)
   - Logic: Needs and demands drive specific activities
   - Example: "Food security needs" → "Fishing activity"

2. **A → P** (Activities cause Pressures)
   - Polarity: Reinforcing (+)
   - Logic: Activities create environmental stressors
   - Example: "Fishing activity" → "Removal of fish biomass"
   - Note: Multiple activities can create the same pressure (cumulative)

3. **P → C/S** (Pressures affect Components/State)
   - Polarity: Can be reinforcing (+) or opposing (-)
   - Logic: Pressures alter ecosystem state
   - Example: "Removal of fish" → "Declining fish stocks" (-)

4. **C/S → ES/I** (Components provide Ecosystem Services)
   - Polarity: Reinforcing (+)
   - Logic: Ecosystem state determines service provision
   - Example: "Fish stocks" → "Provision of fish in the sea" (+)
   - Note: This represents STATE CHANGE transition

5. **ES/I → GB/W** (Services supply Goods & Benefits)
   - Polarity: Reinforcing (+)
   - Logic: Services translate to tangible benefits
   - Example: "Provision of fish" → "Fish in the market" (+)

6. **GB/W → HW** (Goods contribute to Human Wellbeing)
   - Polarity: Can be reinforcing (+) or opposing (-)
   - Logic: Benefits affect welfare outcomes
   - Example: "Fish in market" → "Nutrition" (+)
   - Example: "Contaminated fish" → "Health problems" (-)

7. **HW → D** (Wellbeing impacts feed back to Drivers)
   - Polarity: Reinforcing (+) typically
   - Logic: Welfare outcomes reinforce or modify needs
   - Example: "Malnutrition" → "Food security needs" (+)
   - Note: This completes the REINFORCING FEEDBACK LOOP

### Response/Measure Intervention Connections

8. **GB/W → R/M** (Welfare outcomes trigger Responses)
   - Polarity: Varies
   - Logic: Problems or benefits motivate policy responses
   - Example: "Declining fish catches" → "Implement fishing quotas"

9. **R/M → D** (Responses influence Drivers)
   - Polarity: Opposing (-) typically
   - Logic: Policies can reduce demand or shift priorities
   - Example: "Alternative protein programs" → "Reduce fishing pressure demand" (-)

10. **R/M → A** (Responses regulate Activities)
    - Polarity: Opposing (-) for restrictive, Reinforcing (+) for incentives
    - Logic: Direct regulation or promotion of activities
    - Example: "Fishing quotas" → "Reduce fishing effort" (-)
    - Example: "Subsidies for sustainable fishing" → "Increase sustainable practices" (+)

11. **R/M → P** (Responses mitigate Pressures)
    - Polarity: Opposing (-) typically
    - Logic: Interventions directly reduce environmental stressors
    - Example: "Pollution control regulations" → "Reduce chemical discharge" (-)

12. **R/M → C/S** (Responses restore/protect State)
    - Polarity: Reinforcing (+) for restoration
    - Logic: Direct intervention to improve ecosystem state
    - Example: "Marine protected areas" → "Increase fish stocks" (+)
    - Example: "Coral restoration" → "Improve reef health" (+)

13. **M → R** (Measures enable Responses)
    - Polarity: Reinforcing (+)
    - Logic: Implementation tools support policy objectives
    - Example: "Monitoring technology" → "Enable enforcement" (+)

14. **R → R** (Responses interact with each other)
    - Polarity: Varies
    - Logic: Policies can reinforce or conflict
    - Example: "MPA establishment" → "Requires monitoring programs" (+)

### Special Connections

15. **D → GB/W** (Direct Driver-Welfare shortcuts)
    - Polarity: Varies
    - Logic: Some drivers directly affect welfare without intermediate steps
    - Example: "Climate change" → "Coastal flooding impacts" (-)
    - Note: Use sparingly, only for truly direct relationships

16. **C/S → C/S** (State-to-State interactions)
    - Polarity: Varies
    - Logic: Ecosystem components affect each other
    - Example: "Coral health" → "Fish habitat availability" (+)

## Connection Matrices

The framework uses adjacency matrices to represent connections:

### Primary Forward Matrices
- **d_a**: Drivers → Activities
- **a_p**: Activities → Pressures
- **p_mpf**: Pressures → Marine Processes/Components (State)
- **mpf_es**: Marine Processes → Ecosystem Services (STATE CHANGE)
- **es_gb**: Ecosystem Services → Goods & Benefits
- **gb_hw**: Goods & Benefits → Human Wellbeing (if HW treated separately)

### Feedback Matrices
- **hw_d** or **gb_d**: Wellbeing/Goods → Drivers (completes main cycle)

### Response Intervention Matrices
- **gb_r**: Goods & Benefits → Responses (what triggers responses)
- **r_d**: Responses → Drivers (policy influences on needs)
- **r_a**: Responses → Activities (regulation of actions)
- **r_p**: Responses → Pressures (mitigation interventions)
- **r_mpf**: Responses → State (restoration/protection)
- **r_r**: Responses → Responses (policy interactions)

### Measure Matrices (as subset of Responses)
- **m_d**: Measures → Drivers
- **m_a**: Measures → Activities
- **m_p**: Measures → Pressures
- **m_mpf**: Measures → State
- **m_r**: Measures → Responses

Note: In implementation, measures are typically merged into the response matrices as the last rows.

## Polarity Rules

### Reinforcing (+) Connections
- Same direction causality
- "More of A leads to more of B"
- "Less of A leads to less of B"
- Examples: D→A, A→P, C→ES (typically)

### Opposing (-) Connections
- Inverse causality
- "More of A leads to less of B"
- "Less of A leads to more of B"
- Examples: P→C (degradation), R→P (mitigation)

### Bidirectional (±) Connections
- Can work in both directions depending on context
- Should be split into two separate connections if possible

## Strength Rules

Strength values (1-5):
- **1**: Very weak influence
- **2**: Weak influence
- **3**: Moderate influence (default)
- **4**: Strong influence
- **5**: Very strong/dominant influence

## Confidence Rules

Confidence values (1-5):
- **1**: Speculative/hypothesized
- **2**: Low confidence (limited evidence)
- **3**: Moderate confidence (some evidence)
- **4**: High confidence (strong evidence)
- **5**: Very high confidence (well-established)

## Feedback Loop Classification

### Primary Problem Loop (Red pathway in diagram)
The reinforcing feedback loop that represents the socio-ecological problem:
```
D → A → P → C → ES → GB → HW → D (reinforcing)
```
This creates a vicious cycle where human needs drive activities that degrade ecosystems, reducing welfare and reinforcing needs.

### Response/Solution Loops (Blue pathways)
Balancing feedback loops through interventions:
```
GB/HW → R → [D/A/P/C] (opposing at intervention point)
```
These aim to break the problem loop by intervening at strategic points.

### Combined System Loops
Real systems contain multiple interacting loops creating complex dynamics with:
- Reinforcing loops (amplify change)
- Balancing loops (stabilize or reverse change)
- Delays (time lags between cause and effect)
- Thresholds (tipping points)

## Implementation Guidelines

### 1. Template Creation
- Define all components in each category
- Start with the primary causal chain (D→A→P→C→ES→GB)
- Add feedback connections (GB→D or HW→D)
- Layer in response/measure interventions
- Validate all connections against rules above

### 2. Connection Validation
Check that:
- Connection types follow valid transition rules
- Polarities match expected causality
- Strengths reflect relative importance
- Confidence reflects evidence quality
- No orphaned nodes (all connected to main cycle)

### 3. Matrix Construction
- Build adjacency matrices for each valid connection type
- Ensure row/column naming consistency
- Include measures as extended rows in response matrices
- Preserve empty cells for non-existent connections

### 4. Visualization
- Show primary cycle prominently
- Highlight problem loop (reinforcing, red)
- Show response interventions (balancing, blue)
- Use node colors to distinguish categories
- Edge opacity based on confidence levels

## Differences from Traditional DPSIR

| Aspect | DPSIR | DAPSIWRM |
|--------|-------|----------|
| **Activities** | Implicit in D→P | Explicit category |
| **State** | Single category | Separated into Components & Services |
| **Impacts** | Generic | Split into Goods, Wellbeing, Impacts |
| **Welfare** | In Impacts | Explicit category |
| **Measures** | In Responses | Distinct subtype |
| **Feedback** | I→D only | Multiple feedback pathways |
| **Resolution** | Lower | Higher (more categories) |

## Key Advantages

1. **Explicit Activities**: Separates root causes (drivers) from actions (activities)
2. **STATE CHANGE Distinction**: Separates ecosystem state from service provision
3. **Welfare Focus**: Explicitly tracks human wellbeing outcomes
4. **Response Diversity**: Distinguishes policy (responses) from implementation (measures)
5. **Multiple Intervention Points**: Shows where responses can act (D, A, P, C)
6. **Feedback Clarity**: Shows how impacts reinforce drivers (problem loop)
7. **Solution Pathways**: Clear visualization of how interventions break problem loops

## Example Application: Overfishing

### Primary Problem Loop
```
D: Food security needs
  ↓ (+) motivates
A: Intensive fishing
  ↓ (+) causes
P: Fish removal pressure
  ↓ (-) degrades
C: Fish stock biomass
  ↓ (+) provides
ES: Provision of fish in sea
  ↓ (+) supplies
GB: Fish in market (declining)
  ↓ (-) impacts
HW: Food insecurity (worsening)
  ↓ (+) reinforces
D: Food security needs (LOOP CLOSES)
```

### Response Interventions
```
R1: Fishing quotas
  - R1 → A: Reduce fishing effort (-)
  - R1 → P: Reduce extraction pressure (-)

R2: Marine Protected Area
  - R2 → C: Protect fish stocks (+)
  - R2 → A: Restrict fishing areas (-)

M1: Selective fishing gear (Measure)
  - M1 → P: Reduce bycatch pressure (-)
  - M1 → R1: Enable sustainable quota fishing (+)

M2: Alternative protein programs (Measure)
  - M2 → D: Reduce fish demand (-)
  - M2 → HW: Maintain nutrition (+)
```

## Validation Checklist

When creating or validating a DAPSIWRM template:

- [ ] All nine categories represented (D, A, P, C, ES, GB, HW/I, R, M)
- [ ] Primary causal chain complete (D→A→P→C→ES→GB→HW)
- [ ] Feedback loop present (HW→D or GB→D)
- [ ] Responses connected to welfare/goods (what triggers them)
- [ ] Responses have intervention targets (D, A, P, or C)
- [ ] Measures linked to responses they support
- [ ] All connections follow valid transition rules
- [ ] Polarities correctly assigned
- [ ] Strengths and confidence values set
- [ ] No orphaned nodes
- [ ] Problem loop identified (reinforcing)
- [ ] Solution loops identified (balancing)
- [ ] State change explicitly modeled (C→ES)

## References

This framework integrates:
- DPSIR (Drivers-Pressures-State-Impact-Response) framework
- DAPSI(W)(R)(M) extension for marine systems
- Causal Loop Diagram (CLD) methodology
- Social-Ecological Systems (SES) theory
- Ecosystem Services cascade model

---

**Document Version**: 1.0
**Date**: 2025-11-22
**Based on**: DAPSIWRM.png diagram analysis and MarineSABRES codebase structure
