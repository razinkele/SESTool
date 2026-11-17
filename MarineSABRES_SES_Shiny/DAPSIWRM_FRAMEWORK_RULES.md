# DAPSIWRM Framework Rules for SES Analysis

## Open Questions for Mike Elliott

1. **Responses and Measures: one category or two?** Gemma suggests a
   single category "Responses and Measures" for modelling: both act on
   drivers, activities or pressures in the same ways, the original SES
   guidance did not split them, and the split may confuse users. The
   distinction does make sense along the ecosystem-based management
   continuum. The toolbox already stores Measures as Responses.
2. **Can anything feed into an exogenic pressure?** Gemma's view is that
   nothing inside the SES should feed into the climate-change pressures
   (sea-level change, acidification, temperature change), because they
   come from outside the system and are included only because they act on
   it. The toolbox still accepts Driver → Pressure for older models that
   enter climate change as a Driver (see "Documented Exceptions").
3. **Ecosystem Service → Ecosystem Service links.** Should one service be
   allowed to affect another, as Component → Component links are?
4. **Can a Response reinforce a Driver (R → D with +)?** Gemma thinks it
   can. This version allows either sign.
5. **Drivers as policy objectives.** Gemma removed "policy objectives"
   from the Driver characteristics (policies are Responses, ruling 4).
   Your fuller answer to ruling 4 says a Driver can be an overall vision
   or strategy. This version keeps both: policies are Responses, and a
   vision or strategy can be a Driver. Please confirm.
6. **Still pending from 11–12 November:** how a monitoring Activity
   should be linked; which targets and goals count as a vision or
   strategy; whether to split "Climate change and ocean warming" into
   specific pressures and where greenhouse gas emissions belong; whether
   "Climate change adaptation" is a Driver; how to model pressures whose
   Activity lies outside the management area.

## Framework Overview

The DAPSI(W)R(M) (Drivers–Activities–Pressures–State changes–Impacts on
Welfare–Responses as Measures) framework extends the traditional DPSIR
model to give a more complete social-ecological systems analysis. This
document defines the structural rules and connection logic for building
DAPSI(W)R(M)-based SES models in the toolbox.

## Naming Elements

Two conventions from causal loop diagram (CLD) practice apply to every
element name:

- **No action words.** An element is a quantity that can go up or down;
  the connection carries the action and its direction. Write "Fishing
  quotas" →(−) "Fishing effort", not "Fishing quotas" → "Reduce fishing
  effort".
- **Neutral wording.** Avoid names that imply good or bad, so that no
  group of actors in the system is blamed for a pressure or impact. This
  matters most when stakeholders validate the model. Write "Fishing
  effort", not "Overfishing".

## Component Categories

### 1. DRIVERS (D)

**Definition**: Root causes and fundamental needs that motivate human
activities

**Examples**:

- Food security
- Economic development
- Livelihoods / Employment
- Climate change adaptation (pending: see Open Question 6)

**Characteristics**:

- Represent underlying societal needs
- Can be basic needs / economic goals, or an overall vision or strategy
  (stage A of the integrated assessment framework)
- Often cyclical — can be reinforced by impacts on welfare, and
  underpinned by existing management responses

### 2. ACTIVITIES (A)

**Definition**: Human actions and operations undertaken to meet driver
needs

**Examples**:

- Fishing (artisanal/commercial)
- Agricultural production
- Tourism operations
- Coastal development
- Waste management
- Research and monitoring (ruling 5)

**Characteristics**:

- Direct human actions in the environment
- Sector-specific (fisheries, tourism, agriculture, etc.)
- Scale-dependent (artisanal, commercial, industrial)
- Multiple activities can occur from the same driver

### 3. PRESSURES (P)

**Definition**: Environmental stressors created by activities

**Examples**:

- Removal of fish biomass
- Fishing effort
- Chemical contamination
- Habitat destruction
- Nutrient enrichment
- Physical disturbance

**Characteristics**:

- Direct environmental effects of activities
- Can be cumulative (multiple activities creating the same pressure)
- Quantifiable where possible (extraction rates, pollution loads)

### 4. COMPONENTS (C) / STATE (S)

**Definition**: Elements of the ecosystem affected by pressures

**Examples**:

- Fish biomass
- Coral reef health
- Water quality
- Seagrass coverage
- Biodiversity indices

**Characteristics**:

- Measurable ecosystem elements
- Subject to state change
- Can be physical, chemical, or biological
- Have thresholds and tipping points

### 5. ECOSYSTEM SERVICES (ES)

**Definition**: Benefits and functions provided by ecosystem components

**Examples**:

- Provision of fish
- Coastal protection
- Water filtration
- Habitat for biodiversity
- Carbon sequestration

**Characteristics**:

- Flow from ecosystem state/components
- Can be provisioning, regulating, supporting, or cultural; these are
  ecological elements, and no societal elements should appear here
- These elements link natural systems to human welfare

### 6. GOODS & BENEFITS (GB) / WELFARE (W)

**Definition**: Products and welfare outcomes that people derive from
ecosystem services. Impacts on welfare are not separate elements: they
are the direction and strength of the connections into and out of the
goods and benefits. For example: less seagrass → worse water quality →
less tourism revenue.

**Examples**:

- Fish in the market
- Fish for consumption
- Non-food marine products and their revenue (e.g. alginates used in
  cosmetics, sand used for glass)
- Clean beaches
- Protected coastlines
- Tourism revenue
- Economic benefits
- Cultural benefits (traditions / identity)

**Characteristics**:

- Direct human welfare components
- Economic and social values
- Marketable and non-marketable benefits
- Food security is a Driver, not a benefit; the benefit is the fish
  available for consumption

### 7. RESPONSES (R)

**Definition**: Policy responses, regulations, and management
interventions across scales of governance

**Examples**:

- Fishing quotas
- Marine protected areas
- Pollution regulations
- Certification schemes
- Litter-picking initiatives
- Marine Spatial Planning
- Community action plans

**Characteristics**:

- Policy and governance interventions
- Can target drivers, activities, and pressures (and, for restoration,
  state)
- Typically top-down management, but can be bottom-up depending on the
  management circumstance

### 8. MEASURES (M)

**Definition**: Specific actions, practices, and technologies
implemented as solutions

**Examples**:

- Selective fishing gear
- Wastewater treatment facilities
- Coral restoration projects
- Alternative livelihoods
- Renewable energy adoption

**Characteristics**:

- Concrete implementation actions
- Can be technological, behavioural, or structural
- Often bottom-up or participatory
- Stored as Responses in the toolbox; whether to present them as one
  category with Responses is Open Question 1

## Valid Connection Rules

### How Polarity Is Assigned

Most category pairs can carry either sign: the sign depends on the
system being modelled and on how each element is phrased. The toolbox
therefore follows this rule:

- Where a connection has evidenced polarity, the toolbox fills in that
  sign, and the user can change it. Evidence is exactly: an exact match
  with a link in the toolbox's knowledge base of published case studies
  that carries a source (shown as "from: <citation>"), a sign in a
  shipped template, a sign in an imported file, or the user's earlier
  choice.
- Where no evidenced polarity exists, the user must choose the sign
  before the connection is accepted. The toolbox does not guess a sign
  from the category pair, from keywords, or from synonym matches.

The "Polarity" lines below describe what is common, not a default the
toolbox applies. *(Agreed 17 November 2026; implemented in toolbox
version 1.36.0.)*

### Primary Causal Chain (Forward Connections)

1.  **D → A** (Drivers motivate Activities)
    - Polarity: Can be reinforcing (+) or opposing (−), depending on how
      the driver is phrased
    - Logic: Needs and demands drive specific activities
    - Example: "Food security" → "Commercial fishing" (−): less food
      security means more fishing to provide food; more food security
      means less fishing is needed
2.  **A → P** (Activities cause Pressures)
    - Polarity: Can be reinforcing (+) or opposing (−)
    - Logic: Activities create environmental stressors; some activities
      reduce a pressure
    - Example: "Commercial fishing" → "Removal of fish biomass" (+)
    - Example: "Use of mooring buoys" → "Anchor damage to seagrass" (−)
      (Tuscany case)
    - Note: Multiple activities can create the same pressure (cumulative)
3.  **P → C/S** (Pressures affect Components/State)
    - Polarity: Can be reinforcing (+) or opposing (−)
    - Logic: Pressures alter ecosystem state
    - Example: "Fishing effort" → "Fish stock biomass" (−)
4.  **C/S → ES** (Components provide Ecosystem Services)
    - Polarity: Can be reinforcing (+) or opposing (−); an increase in a
      component occasionally decreases a service, typically past a
      threshold
    - Logic: Ecosystem state determines service provision
    - Example: "Fish stock biomass" → "Provision of fish" (+)
    - Example: "Phytoplankton biomass" → "Seagrass coverage" (−), past
      the threshold where persistent algal blooms form
    - Note: This represents the STATE CHANGE transition
5.  **ES → GB/W** (Services supply Goods & Benefits)
    - Polarity: Can be reinforcing (+) or opposing (−), depending on the
      circumstances of the SES
    - Logic: Services translate to tangible benefits
    - Example: "Provision of fish" → "Fish in the market" (+)
    - Example: "Seaweed growth" → "Recreational use of the sea" (−), where
      people avoid swimming at a site with a lot of seaweed
6.  **GB/W → D** (Goods & Benefits feed back to Drivers)
    - Polarity: Reinforcing (+) typically; can be opposing (−) in some
      contexts
    - Logic: Welfare outcomes reinforce or modify needs
    - Example: "Fish for consumption" → "Food security" (+)
    - Note: This completes a FEEDBACK LOOP

### Response/Measure Intervention Connections

7.  **GB/W → R/M** (Welfare outcomes trigger Responses)
    - Polarity: Varies
    - Logic: Problems or benefits motivate policy responses
    - Example: "Fish in the market" → "Fishing quotas" (−): fewer fish
      reaching the market leads to tighter quotas
8.  **R/M → D** (Responses influence Drivers)
    - Polarity: Can be opposing (−) or reinforcing (+) (Open Question 4)
    - Logic: Policies can reduce demand, shift priorities, or secure a
      need
    - Example: "Alternative protein programmes" → "Demand for fish" (−)
    - Example: "Fishing quotas" → "Food security" (+), by ensuring
      sustainable catches
9.  **R/M → A** (Responses regulate Activities)
    - Polarity: Opposing (−) for restrictive, Reinforcing (+) for
      incentives
    - Logic: Direct regulation or promotion of activities
    - Example: "Fishing quotas" → "Commercial fishing" (−)
    - Example: "Subsidies for sustainable fishing" → "Sustainable fishing
      practices" (+)
10. **R/M → P** (Responses mitigate Pressures, if they work as intended)
    - Polarity: Opposing (−) typically, but occasionally reinforcing (+)
    - Logic: Interventions reduce environmental stressors. Some responses
      accept an increase in one pressure as a trade-off for decreasing
      another.
    - Example: "Pollution control regulations" → "Chemical discharge" (−)
    - Example: "Fishing quotas" → "Fishing effort" (−)
11. **R/M → C/S** (Responses restore/protect State)
    - Polarity: Reinforcing (+) for restoration
    - Logic: Direct intervention to improve ecosystem state
    - Example: "Marine protected areas" → "Fish stock biomass" (+)
    - Example: "Coral restoration" → "Coral reef health" (+)
12. **M → R** (Measures enable Responses)
    - Polarity: Reinforcing (+)
    - Logic: Implementation tools support policy objectives
    - Example: "Selective fishing gear" → "Quota compliance" (+)
13. **R → R** (Responses interact with each other)
    - Polarity: Varies
    - Logic: Policies can reinforce or conflict
    - Example: "Marine Spatial Planning" → "Marine protected areas" (+)

### Special Connections

14. **D → GB/W** — REMOVED (non-canonical, 2026-06-05)
    - **The toolbox does not accept this connection.**
    - Rationale: Elliott, Burdon & Atkins (2017,
      doi:10.1016/j.marpolbul.2017.03.049) state that Drivers reach human
      welfare ONLY via the full A → P → S → ES → GB cascade; there is no
      direct Driver → Goods & Benefits forward edge in canonical
      DAPSI(W)R(M).
    - Climate change is not a D → GB case: under the 2026-11-11 ruling it
      is a suite of Pressures, so its effects are modelled as P → P or
      P → C/S (see "Documented Exceptions").
    - Existing connections of this type in a project are flagged as
      invalid, and loops containing them are treated as non-canonical.
15. **C/S → C/S** (State-to-State interactions)
    - Polarity: Varies
    - Logic: Ecosystem components affect each other
    - Example: "Coral reef health" → "Fish habitat availability" (+)
    - ES → ES interactions: Open Question 3
16. **P → P** (Pressure cascading/cumulative effects)
    - Polarity: Varies (typically reinforcing)
    - Logic: One pressure can trigger or amplify another pressure
    - Example: "Nutrient enrichment" → "Cyanobacteria blooms" (+)
    - References: Halpern et al. 2008 Science; Crain et al. 2008 Ecology
      Letters
    - Note: Common in eutrophication chains and cumulative impact
      scenarios
17. **A → A** (Activity interactions)
    - Polarity: Varies (competition/−, facilitation/+)
    - Logic: Human activities compete with, displace, or facilitate other
      activities
    - Example: "Guided tidal flat walking" → "Bait digging for lugworm"
      (+)
    - Reference: Knights et al. 2013 "A step-wise approach for the
      identification and management of cumulative effects"
    - Note: Extension rule for Maritime Spatial Planning and cumulative
      effects analysis. Not part of core Elliott 2014 DAPSI(W)R(M);
      reserved for MSP contexts.

### Documented Exceptions

**D → P (Exogenic Unmanaged Pressures)**

Some pressures arise outside the system and cannot be managed locally
(Elliott 2011, "exogenic unmanaged pressures"). Climate change is the
main case. Since the 2026-11-11 ruling, climate change is classified as
**Pressures**, so its effects are modelled as P → P or P → C/S. Example:
"Sea temperature" → "Marine heatwaves" (P → P).

The toolbox still accepts D → P, so older user models that list climate
change as a Driver keep working. Whether anything inside the system may
feed into an exogenic pressure is Open Question 2.

- Accepted: "Climate change" (entered as a Driver) → "Ocean warming"
- Invalid use: "Population growth" → "Coastal urbanisation"
  (urbanisation is an Activity, not a Pressure)
- The toolbox's knowledge base has no D → P connections: its three
  climate drivers were reclassified as pressures on 2026-11-11.

### Classification Rulings (marine-science expert, 2026-11-11)

These settle the category questions raised by user feedback on the
toolbox's AI-assisted suggestions.

1.  **Climate change is a Pressure.** It is exogenous and cannot be
    managed locally; management mitigates its impacts. No element within
    the system should feed into the climate-change pressures (sea-level
    change, acidification, temperature change): they are external to the
    SES and included because they act on it (Gemma Smith, 2026-11-12;
    see Open Question 2).
2.  **"X discharge":** the act of discharging is an **Activity**; the
    substance X put into the system is the **Pressure**. Example:
    "Deballasting" (A) → "Number of invasive species" (P) (+).
3.  **Hypoxia, algal blooms and coastal erosion are Pressures.** They act
    on State components: "Coastal erosion" → "Area of coastal land" (−);
    "Hypoxia" → "Species abundance" (−); "Algal blooms" → "Seagrass
    area" (−).
4.  **Policies are Responses (Measures), not Drivers.** In modelling,
    existing responses are included first; new ones are then tested as
    what-if scenarios.
5.  **Research and monitoring are Activities**, not Measures.

**Fuller answers (2026-11-12).** The same expert expanded each ruling:

1.  Climate change is better treated as **a suite of pressures**, not
    one: increased storminess, increased temperatures, sea-level rise,
    ocean acidification, species distribution changes.
2.  The ship discharging ballast water is the Activity; the material
    entering the sea is the Pressure. This shows how DAPSI(W)R(M)
    categories can blur.
3.  Hypoxia, algal blooms and coastal erosion are Pressures, and **an
    Activity is needed to create them**. The expert is also considering
    whether pressures should be marked exogenic or endogenic, and
    activities as inside or outside the management area.
4.  The whole management framework (the "pyramid" and its footprint)
    makes up the Responses. **A Driver can be an overall vision or
    strategy** (stage A of the integrated assessment framework).
5.  Monitoring is not a management measure: it **indicates which
    measures are needed or whether they have worked**. Research informs
    every DAPSI(W)R(M) element in the same way (the expert's paper in
    revision in MPB).

Applied so far:

- A Water Framework Directive "compliance pressure" Driver that
  duplicated the WFD Response was removed. Its only link had been
  generated automatically.
- "Invasive species monitoring and removal programmes" became the
  Response "Invasive species removal programmes". The monitoring part
  will be added as an Activity once the expert says how monitoring is
  linked.

## Polarity Rules

### Reinforcing (+) Connections

- Same direction causality
- "More of A leads to more of B"
- "Less of A leads to less of B"
- Example: "Deballasting" (A) → "Number of invasive species" (P) (+)

### Opposing (−) Connections

- Inverse causality
- "More of A leads to less of B"
- "Less of A leads to more of B"
- Example: "Pollution control regulations" → "Chemical discharge" (−)

### Bidirectional (±) Connections

- Can work in both directions depending on context
- Should be split into two separate connections if possible

## Strength Rules

Strength values (1–5):

- **1**: Very weak influence
- **2**: Weak influence
- **3**: Moderate influence (default)
- **4**: Strong influence
- **5**: Very strong/dominant influence

## Confidence Rules

Confidence values (1–5):

- **1**: Speculative/hypothesised
- **2**: Low confidence (limited evidence)
- **3**: Moderate confidence (some evidence)
- **4**: High confidence (strong evidence)
- **5**: Very high confidence (well-established)

## Feedback Loop Classification

### Primary Behaviour Loop (Red pathway in diagram)

The main feedback loop of the social-ecological system:

    D → A → P → C → ES → GB → D

It can be a cycle where human needs drive activities that may degrade
ecosystems, reducing welfare and reinforcing needs. Or it can show a
virtuous cycle, where the use is sustainable.

### Response/Solution Loops (Blue pathways)

Balancing feedback loops through interventions:

    GB → R → [D/A/P/C] (typically opposing at the intervention point)

These aim to change the behaviour loop by intervening at strategic
points. Existing responses belong in the loop itself (see the example
below); new ones are tested as what-if scenarios.

### Combined System Loops

Real systems contain multiple interacting loops creating complex dynamics
with:

- Reinforcing loops (amplify change)
- Balancing loops (stabilise or reverse change)
- Delays (time lags between cause and effect)
- Thresholds (tipping points)

## Differences from Traditional DPSIR

| Aspect | DPSIR | DAPSI(W)R(M) |
|---|---|---|
| **Drivers** | Merged with activities (D → P) | Explicit category |
| **Activities** | Merged into D → P | Explicit category |
| **State** | Single category | Separated into Components & Services |
| **Impacts** | On both ecological and social elements | Focused on societal goods and benefits (ecological impacts are expressed as state change) |
| **Measures** | In Responses | Subtype of Responses (Open Question 1) |
| **Feedback** | I → D only | Multiple feedback pathways |
| **Resolution** | Lower | Higher (more categories) |

## Key Advantages

1.  **Explicit Activities**: Separates root causes (drivers) from actions
    (activities)
2.  **STATE CHANGE Distinction**: Separates ecosystem state from service
    provision
3.  **Welfare Focus**: Tracks the goods and benefits people receive, with
    impacts on welfare carried by the connections
4.  **Response Diversity**: Covers responses across scales of governance,
    from policy to on-the-ground measures
5.  **Multiple Intervention Points**: Shows where responses can act (D,
    A, P, C)
6.  **Feedback Clarity**: Shows how welfare outcomes feed back to drivers
7.  **Solution Pathways**: Clear visualisation of how interventions
    change the behaviour loop

## Example Application: Fishing

### Primary Behaviour Loop

The loop includes the existing management response (fishing quotas):

    D: Food security
      ↓ (−) motivates (less food security = more fishing needed)
    A: Commercial fishing
      ↓ (+) increases
    P: Fishing effort
      ↓ (−) reduces
    C: Fish stock biomass
      ↓ (+) supports
    ES: Provision of fish
      ↓ (+) supplies
    GB: Fish in the market
      ↓ (−) requires
    R: Fishing quotas (existing)
      ↓ (+) secures, by ensuring sustainable catches
    D: Food security (LOOP CLOSES)

The same loop with a loaded pressure name and no existing response
("Overfishing" instead of "Fishing effort", and Fish in the market →
Food security directly) puts the blame on one group of actors and hides
the management already in place. Prefer the framing above.

### Response Interventions

    R1: Fishing quotas
      - R1 → A: Commercial fishing (−)
      - R1 → P: Fishing effort (−)

    R2: Marine protected area
      - R2 → C: Fish stock biomass (+)
      - R2 → A: Commercial fishing (−)

    M1: Selective fishing gear (Measure)
      - M1 → P: Bycatch (−)
      - M1 → R1: Quota compliance (+)

    M2: Alternative protein programmes (Measure)
      - M2 → D: Demand for fish (−)
      - M2 → GB: Fish for consumption (+)

## Toolbox Implementation Notes

These sections describe how the toolbox stores and checks models. They are
left out of the experts' version of this document.

### Categories in code

`DAPSIWRM_ELEMENTS` in `constants.R` has seven categories: Drivers,
Activities, Pressures, Marine Processes & Functioning (Components/State),
Ecosystem Services, Goods & Benefits, Responses. There is no separate Human
Wellbeing category, and Measures are stored as Responses.

### Connection Matrices

The framework uses these adjacency matrices (keyed source_target, e.g. `d_a`):

- Forward: **d_a**, **a_p**, **p_mpf**, **mpf_es** (STATE CHANGE), **es_gb**
- Feedback: **gb_d**
- Response intervention: **gb_r**, **r_d**, **r_a**, **r_p**, **r_mpf**, **r_r**

Measures are rows of the response matrices. Rule 14 (D → GB) is rejected by
`is_valid_dapsirwrm_transition()` in `functions/network_analysis.R`.

### Polarity evidence

The rule table decides only which transitions are valid; its sign fields
no longer seed any connection. Since version 1.36.0 the "How Polarity Is
Assigned" rule is implemented as follows:

- The sign is evidenced only by an exact knowledge-base match with a
  source (shown as "from: <citation>"), or by a template sign, a file
  sign, or the user's earlier choice.
- Otherwise the user picks the sign in a two-button picker (positive or
  negative) in the AI assistant review, the import review, the Standard
  Entry dialog, the graphical creator and the CLD editor.
- Saved data never holds an unsigned connection: no empty, `NA` or
  invented `+` in connections, adjacency-matrix cells or CLD edges.
- A shipped template connection without an explicit sign is a load error.
  Saved projects from earlier versions are loaded as they are.

### Implementation Guidelines

1. Template creation: define the components in each category; start with
   the primary causal chain (D→A→P→C→ES→GB); add feedback (GB→D); layer in
   response interventions; validate every connection against the rules.
2. Connection validation: transition types follow the rules; polarities
   are evidenced or chosen by the user; strengths reflect relative
   importance; confidence reflects evidence quality; no orphaned nodes.
3. Matrix construction: one adjacency matrix per valid connection type,
   consistent row/column names, measures as rows of response matrices,
   empty cells for absent connections.
4. Visualisation: primary cycle prominent; behaviour loop red; response
   interventions blue; node colours by category; edge opacity by
   confidence.

### Validation Checklist

- [ ] All seven categories represented (D, A, P, C, ES, GB, R; measures as responses)
- [ ] Primary causal chain complete (D→A→P→C→ES→GB)
- [ ] Feedback loop present (GB→D)
- [ ] Responses connected to goods and benefits (what triggers them)
- [ ] Responses have intervention targets (D, A, P, or C)
- [ ] Measures linked to the responses they support
- [ ] All connections follow valid transition rules
- [ ] Every polarity evidenced or chosen by the user
- [ ] Element names neutral and free of action words
- [ ] Strengths and confidence values set
- [ ] No orphaned nodes
- [ ] Behaviour loop and solution loops identified
- [ ] State change explicitly modelled (C→ES)

## References

This framework integrates:

- DPSIR (Drivers-Pressures-State-Impact-Response) framework
- DAPSI(W)R(M) extension for marine systems
- Causal Loop Diagram (CLD) methodology
- Social-Ecological Systems (SES) theory
- Ecosystem Services cascade model

## How the Version 1.1 Comments Were Handled

| Comment or change (Gemma Smith, 12 November) | Version 1.2 |
|---|---|
| Wording edits throughout (Drivers, Activities, Components, Ecosystem Services, Responses, loop text) | Accepted as written. |
| Remove action words from element names | New section "Naming Elements"; every example rewritten without verbs. |
| Neutral, non-blaming terminology (Fishing effort, not Overfishing) | New section "Naming Elements"; the fishing example uses neutral names and includes the existing management response. |
| Goods & Benefits and Human Wellbeing are one category; impacts are the connections | Human Wellbeing removed as a category; its rule (GB → HW) and examples removed; the Goods & Benefits definition now says impacts are carried by the connections. The toolbox already had no separate Human Wellbeing category. |
| Non-consumable products (alginate, sand) | Added as "Non-food marine products and their revenue". |
| Food security is a Driver; the benefit is fish for consumption | Food security removed from Goods & Benefits; "Fish for consumption" added. |
| Splitting Responses and Measures may add confusion | Open Question 1 for Mike. Measures remain a Response subtype, as stored in the toolbox. |
| Automatic polarity is context dependent | New section "How Polarity Is Assigned": evidenced signs are filled in and editable; otherwise the user must choose. Agreed, and implemented in toolbox version 1.36.0. |
| A → P can be opposing (mooring vs anchoring, Tuscany) | Rule 2 now allows either sign, with the Tuscany example. |
| C/S → ES can be opposing (phytoplankton past a threshold) | Rule 4 now allows either sign, with the example. |
| ES → GB polarity must be flexible (seaweed and recreation) | Rule 5 now allows either sign, with the example. |
| GB → D can be opposing | Rule 6 says so. |
| Responses may reinforce Drivers | Rule 8 allows either sign; Open Question 4 for Mike. |
| Responses may increase one pressure as a trade-off | Rule 10 says so. |
| ES → ES interactions | Open Question 3 for Mike. |
| Nothing should feed into exogenic (climate-change) pressures | Added to ruling 1; Open Question 2 for Mike, because the toolbox still accepts D → P for older models. |
| Drivers: delete "policy objectives" | Deleted; "overall vision or strategy" added from Mike's fuller answer to ruling 4 (Open Question 5). |
| Overfishing example: D → A (−), existing quota in the loop | Adopted, with the polarity explanation. |
| DPSIR comparison table | Accepted (Drivers row added, Welfare row removed, Impacts row reworded). |

------------------------------------------------------------------------

**Document Version**: 1.2. **Date**: 2026-11-17 (first version
2025-11-22; rule on D → GB removed 2026-06-05; expert classification
rulings added 2026-11-11 and 2026-11-12; Gemma Smith's review taken in
2026-11-17). **Based on**: the MarineSABRES DAPSI(W)R(M) diagram and the
rules used in the SES Toolbox.
