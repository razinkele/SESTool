# C. D5.3 (Societal behaviour change / interventions) and how to integrate it into the SES Toolbox

Source abbreviations (all in `scratchpad/txt/`):
- **FIN** = `Task_5.3_Societal_Behaviour_Change_MarineSABRES_5_3_final.md` (final D5.3 text; line numbers cited as FIN:nnn)
- **PDF** = `PDF_D5.3_Submitted.txt`
- **MTX** = `WP5_matrix_of_changes_to_SES_graph_associated_with_interventions.xlsx.txt`
- **EBM** = `Task_5.3_..._intervention_to_SES_modification_Framework_for_EBM_link_added.md`
- **GUID** = `EBM_Framework_EBM_framework_EBM_framework_and_implementation_guidance.md`
- **UCC** = `Task_5.3_..._UCC_Observations_DA_CLD.md`
- **SYN** = `Task_5.3_..._behavioural_intervention_synthesis_...md`

## 0. Source caveats (read first)

1. **D5.3 Table 4 (policy instruments) is an image.** FIN:797-809 is empty; in PDF:1413-1420 pages 36-38 have only headers/page numbers. The *only* text source for the hierarchical instrument codes (1.1 ... 4.3) is **EBM** (lines 98-266), mirrored by GUID:10-91. Code **3.5 is missing** in both (3.4 jumps to 3.6: EBM:220-228, GUID:75-78).
2. **The xlsx-to-txt export lost cell colour.** The CBG sheet instructs reviewers to use a *red x* for additions and a *red "n"* for removals (MTX:68).
   - A red "n" would have survived the export as the character `n`, and none appear. The CBG row set also equals the master's (MTX:69-95). So CBG made **no deletions and added no new rows**.
   - Only red-x *additions* would be indistinguishable from the original x's. The only open question for a re-export with colour is "are any x's red?". Only the CBG comments survive as text (MTX:82, MTX:84).
   - The green/orange colour coding of D5.3 Table 2 (FIN:549) is also lost.
5. **EBM table parsing assumption.** In the EBM instrument-type table, the `(---)` header is `colspan="2"` over a zero-width phantom column (EBM:85, 94). Each row's third mark-cell is also `colspan="2"`. I read a mark in that third cell as **(o)**, consistent with the 0% width. The "unusual marks" and the conflict table in §1.4 rest on this reading.
3. **The matrix rows have no definitions in D5.3.** D5.3 defines the umbrella terms (behavioural intervention FIN:433; management strategy/plan/measure/policy instrument/management intervention FIN:771-785), four behavioural sub-types (eco-labelling FIN:520-524, nudges FIN:526-530, education FIN:532-534, social norms FIN:536-540) and the Table 1 repertoire (FIN:437-513). But several matrix rows (*data valuing, cascade creation, remote market access, one-off / ongoing recosting*) are **defined nowhere**. FIN:618 only hints at them ("data ... has added value of its own", "sustainability cascades along the value chain"). This is exactly what CBG complains about (MTX:84). Any row-to-code mapping below marked **[proposal]** is mine, not D5.3's.
4. **The DA "before" graphs exist only as figures** (FIN Fig. 15, 26, 42). The worked examples in section 4 list the edges D5.3 *describes in text*, so the before-state is partial.

---

## 1. Intervention typology and graph-change operations

### 1.1 Graph-change operation legend (MTX:3-5)
| Code | Operation |
|---|---|
| `(+/-)` | Change sign AND/OR weight of an existing edge in the SES graph |
| `(---)` | Introduce a new edge in the SES graph |
| `(o)`   | Introduce a new node in the SES graph |

### 1.2 Master sheet (MTX:1-29), with definitions where available

| Group | Intervention | (+/-) | (---) | (o) | Definition / source |
|---|---|:-:|:-:|:-:|---|
| **Mainly behavioural** | Nudge | x | | | Change of choice architecture "without prohibiting any choices or changing economic incentive" (FIN:528, Thaler & Sunstein). Main techniques are defaults and social influence. |
| | Certification | x | | | EBM 2.2: "programs that evaluate and endorse products, processes, or organizations based on specific criteria" (EBM:165). MSC example. |
| | Traceability | x | | | Not defined. Mentioned at FIN:618 as "increased monitoring and traceability" producing data value. |
| | Norms influence | x | x | | Social norms: "the way in which our behaviour is affected by what other people do or think" (FIN:538, Abrahamse & Steg). |
| | Data valuing | | x | x | **Undefined** (CBG flags it, MTX:84). Closest hint is FIN:618. |
| | Change in accessibility | x | | | Undefined. |
| | Change in participation in governance | | x | x | Undefined. Closest is Table 1 "Participatory and co-management approaches" (FIN:502-506). |
| | Cascade creation | | x | | Undefined. FIN:618 says "eco-labelling might lead to sustainability cascades along the value chain". |
| | Remote market access | | x | | Undefined. |
| | Change in practices | x | | | Undefined. |
| **Mainly management** | quota/license | | x | | CBG notes the meaning is ambiguous (MTX:84). UCC says a quota is a policy instrument (1.1) *or* an Output Control measure (UCC:3, UCC:11). |
| | mpa/oecm | | x | x | Spatial (distribution) control (FIN:836; GUID:113-117 "OECMs fall in this category"). |
| **Mainly economic** | subsidies | x | | | EBM 3.1 Subsidies and grants (EBM:196-198). |
| | incentives | x | x | | General economic incentive-based instruments, EBM category 3 (EBM:58-61). |
| | trade agreements | x | | x | Closest is EBM 3.2 Tariffs (EBM:204-206) or 1.3 Treaties (EBM:122-124). |
| | payment for goods and services | x | x | | Undefined. |
| | payment for non-market goods and services | | x | | Undefined (PES-like). |
| | introduce externalities in prices | x | x | | EBM 3.4 Taxes (relief) and charges: "internalize the associated costs" (EBM:221). |
| | one-off recosting | | x | | **Undefined.** |
| | ongoing recosting | x | | | **Undefined.** |
| **Mainly governance** | introduce multi-level governance | | x | x | Undefined. Governance is defined generically at FIN:763. |
| | change power dynamics | x | x | | Undefined. |
| | introduce cross-sector coordination | | x | | Undefined. |

Umbrella definitions:
- **Behavioural intervention** (FIN:433): "An intervention causing a behavioural response which is not triggered by economic considerations ... nor dependent on formal regulations or enforcement ... negotiated and agreed upon voluntarily".
- **Management measures** "operate solely in the ecological system", while **policy instruments** "operate solely in the social system" (FIN:779-783).
- A **management intervention** applies either one "in response to an impact observed directly ... or as the result of a change in marine functioning, ecosystem service or good and benefit provision" (FIN:785).
- D5.3 has no separate definitions for the "economic" and "governance" groups. They map onto EBM categories 3 and 1/governance (FIN:763, FIN:793).

### 1.2b D5.3 Table 1: behavioural intervention repertoire (FIN:437-513)
This is the only D5.3 typology that comes with descriptions, target actors and entry points (LB = "lightning bolt" in the D5.3 Fig. 2 behaviour model). `Target` is a candidate `target_actor` field.

| Intervention | Description (examples) | Target | Entry point |
|---|---|---|---|
| Educational | Environmental education, awareness campaigns, workshops/training, interpretive programs | Consumers/Users/Operators | LB1, LB3 |
| Social norms and community engagement | Social norm campaigns, community-based social marketing, peer influence, citizen science | Users | LB3 |
| Regulatory and policy | Legislation/regulations, protected areas and zoning, codes/standards, compliance and enforcement | Operators/Users | LB1, LB5 |
| Technological and structural | Infrastructure, green technology, planning/design, resource management systems | Consumers/Users/Operators | LB1, LB4, LB5 |
| Behavioural science and nudging | Defaults, feedback/monitoring, commitment devices, choice architecture | Consumers/Users/Operators | LB1, LB2, LB4 |
| Communication and media | Social/mass media, storytelling, behavioural cues | Consumers | LB2, LB3 |
| Institutional and organisational | CSR, green certification, workplace initiatives, partnerships | Consumers/Users/Operators | LB4, LB5 |
| Participatory and co-management | Stakeholder engagement, co-management, collaborative planning, participatory budgeting | Operators | LB3, LB4, LB5 |
| Health and wellbeing | Nature-based therapies, green exercise, healthy eating, stress reduction | Users | LB4 |

### 1.3 Per-sheet differences
- **Task 5.4 sheet (MTX:30-66).** Same x-pattern as the master for all 22 rows (MTX:32-58), plus **7 "preliminary proposals from 5.4 for mainly governance interventions"** (MTX:59-66):

| Governance intervention (T5.4) | (+/-) | (---) | (o) |
|---|:-:|:-:|:-:|
| enhance governance capacity | x | | |
| incorporate society values in decision-making | | x | |
| enhance trust between actors | | x | |
| reduce conflicts among stakeholders | x | x | |
| increase collaboration between stakeholders including sectors | x | | |
| increase participation in decision-making | x | | |
| enhance compliance and monitoring | x | x | |

  None of the 5.4 additions uses `(o)`: they act on existing edges or add edges.
- **CBG sheet (MTX:67-95).** The visible x-pattern is the same as the master (see caveat 0.2). The critique comments are:
  - MTX:82: "wouldn't the matrix be different according to each DA? ... we would need **three matrices, one for each DA**".
  - MTX:84: asks for **definitions** of every intervention, and for the **management problem each addresses** (D vs A vs P). Notes that **no intervention targets ecosystem restoration (State)** and asks "are standards and regulations not part of the analysis?"
  
  The EBM framework answers the last point: it has Restoration (EBM:356-363) and 1.1 Standards (EBM:100-106), but these are absent from the xlsx.

### 1.4 A second change-matrix exists, and it conflicts with the xlsx
EBM carries its own `(+/-)/(---)/(o)` columns for every instrument type and measure (EBM:31-33, 93-95, 290-292). Conflicts with the xlsx:

| Item | xlsx (MTX) | EBM framework |
|---|---|---|
| Nudge vs 2.5 Nudging | (+/-) (MTX:4) | (+/-) **and (---)** (EBM:191-192) |
| Certification vs 2.2 | (+/-) | (+/-) (agrees, EBM:167) |
| mpa/oecm vs Spatial control | (---), (o) (MTX:16) | **all three** (EBM:301-303, 307-309) |
| quota/license vs 1.1 Standards/limits (TAC) | (---) (MTX:15) | **(+/-)** only (EBM:107) |
| quota vs Output control (TAC/Quota) | (---) | **(+/-)** only (EBM:341) |
| quota vs 3.7 ITQ/cap-and-trade | (---) | all three (EBM:239-241) |
| subsidies vs 3.1 | (+/-) | (+/-) (agrees, EBM:199) |
| externalities in prices vs 3.4 Taxes | (+/-), (---) | (+/-) only (EBM:223) |

Category-level EBM marks: 1 Legal = (o) only (EBM:43); 2 Voluntary/info = (+/-) (EBM:53); 3 Economic = (+/-), (---) (EBM:63-64); 4 R&D = (+/-) (EBM:71).

Unusual EBM marks:
- 1.5 Monitoring = (o) only (EBM:145)
- 2.4 Labelling = (o) only (EBM:185)
- 3.3 Deposit-refund = (+/-), (o) (EBM:215-217)
- 4.3 Evaluation = (+/-), (---) (EBM:263-264)
- Remediation = (---), (o) (EBM:352-353)
- Restoration = (o) only (EBM:363)
- Technical measures = all three (EBM:331-333)

**Implication:** the tool needs one authoritative vocabulary-to-operations table. The two sources must be reconciled by WP5. Until then, keep both and show the union of allowed operations, tagged with their source.

---

## 2. EBM framework: Response/Measure controlled vocabulary (exact)

### 2.1 Policy instruments, i.e. DAPSIWRM **R** (EBM:28-266; GUID:10-91)
Category definitions come from EBM:38-69.

- **1. Legal and regulatory instruments.** "Tools used by governments and other regulatory bodies to establish and enforce laws, rules, standards, and requirements".
  - 1.1 Standards / limits / requirements (TACs, mesh size, minimum landing sizes)
  - 1.2 Supervision / enforcement (EFCA)
  - 1.3 Treaties (OSPAR)
  - 1.4 Targets / policy development (MSFD GES)
  - 1.5 Monitoring systems / supervision (EMSA VMS)
  - 1.6 Bans (drift nets)
- **2. Voluntary agreements and information instruments.** "non-coercive ... without relying on formal regulations or enforcement".
  - 2.1 Codes of Conduct
  - 2.2 Certification schemes (MSC)
  - 2.3 Awareness campaigns / education
  - 2.4 Labelling (EU Ecolabel)
  - 2.5 Nudging (shaping public opinion). The example is "Praising fishermen ... ?" (EBM:190), which is still a placeholder.
- **3. Economic incentive-based instruments (including market-based instruments).**
  - 3.1 Subsidies and grants (EMFF)
  - 3.2 Tariffs
  - 3.3 Deposit-refund schemes
  - 3.4 Taxes (relief) and charges
  - *(3.5 missing)*
  - 3.6 Liability schemes (Environmental Liability Directive)
  - 3.7 Individual Tradeable Quota / cap-and-trade
- **4. Research and development (knowledge base).** "Tools that provide information to citizens and other actors attempting to influence collective action".
  - 4.1 Research (monitoring / investments / programmes) (EMODnet)
  - 4.2 Impact assessments (EIA)
  - 4.3 Evaluation

### 2.2 Management measures, i.e. DAPSIWRM **M** (GUID:105-168, more complete than EBM:285-364 and FIN:820-874)
D5.3 text names **six** categories (FIN:815): Spatio-temporal distribution control, Input control, Output control, Remediation, Restoration, NBS. FIN Table 5 and EBM list only five, because NBS is missing. GUID has all six with sub-types:

| Category | Definition | Sub-types (GUID) | DAPSIWRM target (FIN:817) |
|---|---|---|---|
| Spatial distribution control | "Mitigation of the spatial extent of a selection of activities and/or pressures" (GUID:114) | Year-round restriction (strict MPA, no-take, **OECMs**, incl. real-time closures); Seasonal closure/restriction (GUID:115-121) | any of A-P-S, spatially/seasonally |
| Input control | "Mitigation of the activity" (GUID:125) | Capacity (decommissioning); Effort (days-at-sea) (GUID:126-131). EBM adds **Technical measures** (gear modification, pingers) (EBM:329-330) | **A** |
| Output control | "Mitigation of the pressure" without interfering with the activity (GUID:135; EBM:337-338) | Output control (TAC/Quota, Fish Guide, ban on littering) | **P** |
| Remediation | "reduce the pressure from past activities" (GUID:141) | Remediation (Fishing for Litter, lost gear retrieval) | **P** (legacy) |
| Restoration | "enhance the state of the ecosystem component(s), i.e. biotic or abiotic" (GUID:148) | Species (stock) restoration; Habitat restoration (greening grey infrastructure) (GUID:149-154) | **S** (C in toolbox) |
| Nature-based solutions | "Introduction novel (combinations of) activities" (GUID:158) | Enhance ecosystem state (artificial reefs); Multi-use (co-location, symbiotic use); Replace existing activities (low-trophic aquaculture, wind-powered shipping) (GUID:159-168) | A / S |

GUID:1 cites the NBS categories to Riisager-Simonsen et al. and multi-use to Tamis et al. 2024.

Key nomenclature (FIN:771-785):
- **management strategy** = policy instrument + management measure
- **management plan** = an internally consistent set of strategies

FIN:893 gives worked pairings: labelling + spatial control (tour operator outside MPAs), and labelling + input control-technical (electric low-noise engine).

### 2.3 Proposed mapping from matrix rows to EBM codes **[proposal, not in D5.3]**
| Matrix row | EBM R code | EBM M category |
|---|---|---|
| Nudge | 2.5 | (via target) |
| Certification | 2.2 | |
| Traceability | 1.5 / 2.4 | |
| Norms influence | 2.3 / 2.5 | |
| Data valuing | 4.1 | |
| quota/license | 1.1 or 3.7 | Output control (quota); Input control-Capacity (licence) |
| mpa/oecm | 1.1 | Spatial distribution control |
| subsidies | 3.1 | |
| incentives | 3 (generic) | |
| trade agreements | 1.3 / 3.2 | |
| introduce externalities in prices | 3.4 | |
| enhance compliance and monitoring (T5.4) | 1.2 / 1.5 | |

---

## 3. Evidence on effectiveness (for weights and confidence)

The evidence is **thin and mostly negative or highly variable**. D5.3 concludes behavioural measures "remain poor choices in the toolkit" (FIN:546).

### 3.1 By intervention type
- **Nudges.**
  - About one third of reported effects are insignificant (Hummel & Maedche 2019) (FIN:530).
  - After correcting for publication bias there is "no meta-analytic support for an effect of nudges" (Maier et al. 2022) (FIN:530).
  - Effects can be short-lived, reversed, or counter-nudged (Sunstein 2016) (FIN:530).
  - Social-norm nudges reduce recreational-fisheries non-compliance, but responses are heterogeneous (Mackay et al. 2020) (FIN:528).
- **Eco-labels.**
  - Effective only for consumers who are already aware and willing to pay. Effect depends on label awareness, region and sociodemography (FIN:522-524).
  - The effect of losing MSC certification in the N. Atlantic is "at best unclear" (Bronnmann 2023) (FIN:524).
  - Best combined with bans, taxes or subsidies (FIN:522).
- **Education.** Inflated positive findings have been reported (Ardoin et al.) (FIN:534). It is expensive when sustained (FIN:574).
- **Social norms.**
  - Effects taper or vanish after discontinuation (FIN:540).
  - There is a boomerang effect: households already at the norm increased energy use (FIN:540).
  - Norms work best for "visible" behaviours (FIN:538).
- **Plastic-bag charge** (the best-studied case). Success is highly variable and the effect dampens over years (Adeyanju 2021) (FIN:628). Periodically increasing the intensity can sustain the change (SYN:11, FIN:614).
- **General points.**
  - Effect size is "extremely variable and highly dependent on social-ecological context" (FIN:569, FIN:616).
  - Most studies measure intention, not behaviour (FIN:616, FIN:624).
  - There is a latency/durability problem (FIN:614).
  - Spill-over is possible (FIN:616).

### 3.2 Ten-tenets appraisal of eco-labelling, nudges, social norms and education (FIN:549-609, Table 2)
Positive on:
- economically viable (except education)
- technologically feasible
- legally permissible
- politically expedient

Negative on:
- ecologically sustainable (unknown effect size)
- administratively achievable
- ethically defensible ("low documented impact")
- culturally inclusive (research is WEIRD-centric)
- effectively communicable

### 3.3 Usable rubric for a confidence/feasibility score (GUID:182-265)
For each tenet, GUID gives normative **minimal / (intermediate) / full compliance** definitions:
- Management measures are scored on: Ecologically effective (3 levels, GUID:191-194), Technologically feasible, and Economically efficient.
- The whole intervention (instrument + measure) is scored on: Economically viable, Socially desirable/tolerable, Ethically defensible, Culturally inclusive, Legally permissible, Administratively achievable, Effectively communicable, and Politically expedient (GUID:225-265).

This maps directly to an ordinal 0/0.5/1 per-tenet field on an R/M node.

### 3.4 Quantitative outputs from the DA analyses (success rates of exhaustive ordinal grids)
- **Arctic integrative model.**
  - Quota intervention: 0/1792, and 0/7168 with the catch edges added (FIN:1186, 1200, 1203-1214).
  - Ecolabelling: 0/4096 (FIN:1227, 1243).
  - Weight-change ("sustainability transition"): 9,491,922/~1.16e9 = **0.82%** (FIN:1251-1255).
- **Arctic Boolean.**
  - Integrative model: 17 attractors, 4 meet the objective, covering 89% of the state space; only attractor 8 (22.5%) also sustains all drivers (FIN:1101-1103).
  - Unified model: 142 attractors, 64 meet the objective, but G&B are sustained only in Greenland (FIN:1291, 1306).
- **Tuscany "additional moorings"** (50,176 combinations, FIN:1509), share of sets meeting the objective:
  - original model: **~7%** (FIN:1513)
  - [slow] model: **~11.5%** (FIN:1533)
  - [fast] model: **~37.5%** (FIN:1558)
  - Stable attractors (all Laplacian eigenvalues real): **0** in every case (FIN:1517, 1535, 1560).
- **Macaronesia "MPA in ABNJ".**
  - Boolean: 25/49 topologies meet the objective (FIN:1762).
  - Ordinal 0/0.25/0.5/1: 0/4096 (FIN:1773-1775).

- **Section 3 PESTLE fuzzy cognitive maps (FCM) by worldview** (weight-only changes, signs kept; 1M greedy simulations): desirable outcome rates were 23.4% / 15.1% / 9.6% / 22.6% for groups 1-4 (FIN:1013). Increasing absolute weights raised the probability of reaching SSP1 (FIN:1024). Economic -> Environment is the key lever for fatalist/individualist maps (FIN:1053). The topological skeleton alone reaches SSP1 for all groups (FIN:1051).

**Takeaway for parameterisation.** The only defensible default for behavioural-intervention edges is **low weight + low confidence**, with wide uncertainty ranges. Weight/sign should be *sampled over a grid*, not fixed. Intrinsic biology (self-loops on stocks/habitats) materially changes intervention success (FIN:1581).

---

## 4. Worked examples from the DA CLDs (before to after)

### 4.1 Arctic: reclassification + "Agreements on Quotas" as a new node (FIN:1089-1216)
- **Before:**
  - "Agreements on quotas" and "Ecolabelling" were typed as **Activities**. They were affected by Drivers and Pressures and affected Drivers (FIN:1091).
  - There was no Reproductive success <-> Fish occurrence feedback.
- **Pre-step, biological realism (---) (the edges were originally absent).** Add Reproductive success -> Fish occurrence (+) and Fish occurrence -> Reproductive success (+), as strong [fast], weak [slow] or none [original] (FIN:1079-1085, Table 6).
- **(o) new node "Agreements on Quotas" (Measure)**, after removing the Activity node (FIN:1173, 1179-1196):
  - Identity -> AoQ: strong- ... strong+ (7 levels)
  - Reproductive success -> AoQ: strong- ... none (indicator; it rises as the stock falls)
  - Fish occurrence -> AoQ: strong- ... none (indicator)
  - AoQ -> Pelagic fishing: strong- ... none
  - AoQ -> Sustainable marketing: none ... strong+
  - That gives 1792 sets, 0 of which succeed (FIN:1200).
- **Phase 2 (---):** add AoQ -> Catch [mackerel, blue whiting, herring, capelin] (strong- ... none). The rationale is that catches depended only on fish occurrence, not on fishing mortality (FIN:1202-1206). That gives 7168 sets, 0 of which succeed.
- **Weight-change alternative (+/-) that worked:** 5 of the 31 sensitivity-selected edges must change (FIN:1255-1267):
  - Pelagic fishing -> Fishing mortality: weak+
  - Pelagic fishing -> GHG emissions: weak/medium+
  - Employment (D) -> Pelagic fishing: weak+
  - Social Services -> Pelagic fishing: weak+
  - Global food security -> Pelagic fishing: weak+
  
  This is interpreted as "stocks well above MSY + economic diversification" (FIN:1273). Edge selection was guided by participation ratio (FIN:1251).
- **Lesson.** An (o) intervention adds a *one-step delay* (monitor, then adjust), and that delay destabilises the model (FIN:1273).

### 4.2 Arctic: Ecolabelling as a new node (FIN:1218-1245, unified FIN:1310-1318)
- **Before:** the Activity "Sustainability marketing" was driven by the Driver "Consumer preferences". AoQ was an Activity.
- **After:**
  - Remove AoQ.
  - **Rename** "Sustainability marketing" to "Consumer purchasing".
  - (o) Ecolabelling node:
    - Reproductive success -> Eco: strong- ... none
    - Fish occurrence -> Eco: strong- ... none
    - Eco -> Pelagic fishing: strong- ... none
    - Eco -> Consumer purchasing: none ... strong+
    - Eco -> Consumer preferences (D): none ... strong+
    - Eco -> Climate mitigation (D): none ... strong+
  - That gives 4096 sets, 0 of which succeed.
  - Note that the intervention node feeds **Drivers**, which turns the exogenous drivers "Climate mitigation" and "Consumer preferences" into endogenous ones (FIN:1175).
- **Unified 3-country model.** AoQ becomes a single shared node, with Identity from each country feeding it (FIN:1304). Recommendations (FIN:1324-1330):
  - per-species SSB nodes with **self-loops**
  - country-specific weights
  - shared SSB and intervention nodes
  - explicit "agreement-process" nodes

### 4.3 Tuscany: "Additional moorings" (FIN:1336, 1461-1585)
- **Before:**
  - 29 components.
  - Existing instruments ("Boat moorings", "Licenses for diving access to MPA", "Spatial planning (MPA)") are typed as **Activities** with **no feedback from P. oceanica extension** (FIN:1336, 1372-1383).
  - Anchoring -> P. oceanica (-) and Boat moorings -> P. oceanica (-) (FIN:1505).
  - Laplacian shows Boat moorings antagonistic to P. oceanica and clustered with Anchoring (FIN:1447).
- **Pre-step:** add the **self-loop** P. oceanica extension -> itself, strong+ [fast], weak+ [slow] or none (FIN:1465-1469, Table 10).
- **(o) "Additional moorings"** (FIN:1503-1509):
  - Incoming (indicators, +): Extension of natural habitats (G&B) -> AM; P. oceanica extension (MPF) -> AM
  - Outgoing:
    - AM -> Anchoring (-)
    - AM -> Boat moorings (-)
    - AM -> Spatial planning (+)
    - optional: AM -> Marine traffic (-) and AM -> Artisanal fishing (-)
  - That gives 50,176 combinations.
  
  D5.3 notes this is *not* the same as up-weighting the existing "Boat moorings" edges. It is a qualitatively new intervention (FIN:1507).
- **Recommended "after"** ([slow], the realistic case for long-lived Posidonia, FIN:1585):
  - P. oceanica extension -> AM (medium or strong +)
  - AM -> Anchoring (**strong -**) only
  - plus the self-loop
  
  Result: the objective is met and all G&B stay positive, but the attractor is not stable (FIN:1533-1551). The policy implication is to pair it with tightly controlled no-anchoring zones (FIN:1585).

### 4.4 Macaronesia: "MPA in ABNJ" (FIN:1589-1783)
- **Before:**
  - 17 components.
  - **MPA mistyped as an Ecosystem Service** (FIN:1589).
  - Boolean: 1 cyclic attractor (4 states) in which pelagic biodiversity and MPA deteriorate (FIN:1600).
- **After:**
  - (o) "MPA in ABNJ", tested over all 49 source/target link combinations (Fig. 43), with ≥1 source and ≥1 target (FIN:1756).
  - Biodiversity-measure -> MPA-ABNJ is negative (degradation raises designation pressure). Biodiversity-service -> MPA-ABNJ is positive (support grows with success) (FIN:1756).
  - 25/49 topologies meet the objectives, and all of those also keep G&B (FIN:1762).
  - Simplest chosen topology: Biodiversity (ES) -> MPA-ABNJ (+) and MPA-ABNJ -> MPA (+) (FIN:1764).
  - Ordinal grid {0, 0.25, 0.5, 1}: 0/4096. MPA nodes are antagonistic to biodiversity, so the 51 existing weights need rethinking (FIN:1773-1783).

### 4.5 UCC review of the DA CLDs (UCC)
**Proposed additions:**
- Arctic: add **Stocks of fish -> National Economy (+)** (UCC:19).
  - The quota -> economy (-) edge is timescale-dependent: positive in the long term (UCC:15).
  - Seasonal/temporal measures are missing (UCC:23).
- Tuscany:
  - add **Restoration -> economy / eco-tourism / "Ideal size of tourism"** (UCC:41-45)
  - add **Restoration -> closed MPA** (new node), which reduces anchoring and boat traffic (UCC:47)
  - add **Erosion protection -> beach availability/tourism** (UCC:57)
- Macaronesia: add **Political consensus for the corridor -> Level of Protection (+)** (UCC:85). "Control measures" is too vague to wire (UCC:73).

**Proposed classifications:**
- Agreements on Quotas = instrument **1.1** (or Output Control) (UCC:3, UCC:11)
- Maximum Sustainable Yield = instrument (UCC:29)
- Spatial limits for anchoring = Spatial Control (UCC:35)
- Regulation of boat-distance / land-distance discharge = Spatial Control (UCC:49-51)
- Erosion protection ~ Remediation (UCC:53)
- Tourism limitations = instrument (UCC:61)
- Blue Flags = voluntary certification? (UCC:63)
- Use of electric boats is ambiguous (incentive vs mandate) (UCC:65)
- Extended holiday season = instrument (UCC:67)
- Ecological corridor = Spatial Control (UCC:75)
- Level of protection = 1.1 (UCC:79)

---

## 5. Integration opportunities in the Toolbox

### 5.1 What already exists (DTU pipeline is ported)
`functions/ses_dynamics.R` has:
- `ses_create_boolean_rules`/`ses_boolean_attractors`/`boolean_model` (l.455-618)
- `simulate_dynamics` (681)
- `participation_ratio` (776)
- `laplacian_eigenvalues`/`laplacian_stability` (322, 381)
- `state_shift_monte_carlo` (897)
- `ses_add_intervention(mat, name, affected_nodes, indicator_nodes, effect_range=c(-1,1))` (1012)
- `ses_compare_interventions` (1092)
- `intervention_simulation` (1175)
- `random_forest_importance` (1262)

Modules `analysis_intervention.R`, `analysis_boolean.R`, `analysis_simulation.R` and `analysis_leverage.R` exist.

**Gaps:**
- `ses_add_intervention` implements only the **(o)** operation, with *random uniform* weights.
- `modules/response_module.R:40-42` `rm_type` uses an ad-hoc list (regulatory/economic/educational/technical/institutional/voluntary/mixed) and **stores translated labels as values**, which is locale-dependent data.
- `constants.R` has no R/M vocabulary constant (only a "Measures" colour at l.248).

### 5.2 Intervention designer: three modes, matching D5.3
D5.3 records a consortium decision that *all* measures are introduced as **new nodes** triggered by impact or indicator nodes and acting on targets (FIN:673, FIN:953). The weight-change route is a separate "sustainability transition" mode (FIN:935-945, FIN:1249). Hence:

| Mode | Matrix op | D5.3 basis | Existing code | To add |
|---|---|---|---|---|
| **A. New intervention node** | (o) | FIN:673, 953; all DA examples | `ses_add_intervention` | Exhaustive ordinal grid (e.g. {-1, -0.5, -0.25, 0, 0.25, 0.5, 1}, with per-edge sign constraints such as "indicator edges <=0"), not uniform random |
| **B. New edge between existing nodes** | (---) | Reproductive success <-> Fish occurrence (FIN:1079-1085); P. oceanica self-loop (FIN:1463-1469); UCC additions (UCC:19, 47, 57, 85). Note: AoQ -> Catch (FIN:1202) is an extra *outgoing edge of the new node*, so it belongs to mode A. | none | `ses_add_edges(mat, edges_df)` + validation against DAPSIWRM transition rules |
| **C. Re-weight / re-sign existing edges** | (+/-) | FIN:1249-1267 | `state_shift_monte_carlo`, `random_forest_importance`, `participation_ratio` | PR-guided edge preselection (FIN:1251), then exhaustive or greedy search, then posterior-vs-prior weight densities (FIN:945) |

**Workflow (D5.3 Section 4 pipeline, FIN:1787):**
1. The user picks the intervention type from the vocabulary.
2. The tool reads the allowed ops from the vocabulary-to-operations table (MTX ∪ EBM, tagged by source) and pre-fills a suggested source/target pattern:
   - M categories target A (Input), P (Output/Remediation), C (Restoration), or any (Spatial) (FIN:817)
   - indicator edges come from the C/ES/GB nodes named as policy objective
3. The user defines **policy-objective nodes** and **"also-sustain" nodes** (G&B).
4. Run Boolean attractors on the signed graph. If no desirable attractor exists, stop and suggest topology changes (Macaronesia logic, FIN:1756).
5. Run the ordinal grid simulation.
6. Rank results:
   - (a) objective met = targets >0 for the last 100 of 1000 steps (FIN:1198)
   - (b) all G&B also >0 (FIN:1515)
   - (c) stable = all Laplacian eigenvalues real (FIN:1517)
   - (d) **simplest** = fewest non-zero intervention edges (FIN:1515, 1533)
7. Compare before and after: loops, leverage/PR, attractors, phase portrait.

**Helpers to add:**
- `ses_intervention_grid(mat, spec, levels)`
- `ses_success_criterion(traj, targets, last_n=100)`
- `ses_is_stable_attractor(mat)`
- `rank_simplest(results)`
- `ses_add_edges()`
- a **biological self-loop helper** (FIN:1079, 1463), offered as an optional pre-step for living-resource C nodes

### 5.3 Controlled vocabulary for R and M nodes
Proposed `constants.R`:
```r
EBM_POLICY_INSTRUMENTS <- data.frame(
  code      = c("1","1.1",...,"4.3"),              # store CODE, not label
  category  = c("legal_regulatory", ...),
  i18n_key  = "ebm.instrument.1_1",                 # label/definition via i18n x 9 langs
  ops_xlsx  = c("", "+/-", ...),                    # from MTX
  ops_ebm   = c("o", "+/-", ...),                   # from EBM
  example   = ...)
EBM_MANAGEMENT_MEASURES <- data.frame(
  code = c("spatial.year_round","spatial.seasonal","input.capacity","input.effort",
           "input.technical","output","remediation","restoration.species",
           "restoration.habitat","nbs.enhance","nbs.multi_use","nbs.replace"),
  dapsiwrm_target = c("A|P|C","A|P|C","A","A","A","P","P","C","C","C","A","A"), ...)
INTERVENTION_MATRIX <- data.frame(row, group = c("behavioural","management","economic","governance"),
  plus_minus, new_edge, new_node, source = c("master","T5.4"), ebm_code_proposal)
```

Element-level fields on R/M nodes:
- `ebm_code`
- `instrument_or_measure`
- `paired_with` (to build a **management strategy** = R+M pair, FIN:771)
- `implementation_status` (exists)
- `tenet_scores` (10 × {0, 0.5, 1}, GUID:182-265)
- `evidence_confidence`

Migrate `rm_type` to store codes, with i18n on display only.

### 5.4 Typing lint (cheap, grounded)
All three DAs had instruments mistyped:
- Arctic: AoQ and Ecolabelling as **Activities** (FIN:1091)
- Tuscany: moorings, licences and spatial planning as **Activities** with no feedback (FIN:1336)
- Macaronesia: MPA as an **Ecosystem Service** (FIN:1589)

Add a lint: an element typed D/A/ES whose label matches a vocabulary synonym (quota, licence, MPA, OECM, label, certification, mooring, subsidy, tax, ban, closure, restoration, ...) triggers "Reclassify as R/M?". A second warning fires for an R/M node with **no incoming edge** from C/ES/GB/HW ("no feedback: intervention cannot respond to management target", FIN:1336).

### 5.5 Evidence cards
For each vocabulary entry, show:
- the definition (EBM/GUID)
- example(s)
- allowed graph ops (both sources)
- the D5.3 effectiveness summary (§3.1)
- the ten-tenet appraisal (FIN Table 2)
- DA worked-example outcomes (§4)

Default weight priors:
- behavioural (2.x) edges: **weak, low confidence, sampled**
- legal/regulatory and output/spatial controls: medium
- always shown as a sampled range, never as a point

### 5.6 Gaps and open items
1. **No definitions** for ~12 matrix rows, which CBG requested (MTX:84). The vocabulary must ship with WP5-agreed definitions or mark them "provisional".
2. **Per-DA matrices** were requested by CBG (MTX:82). Support a `context` (DA) column in `INTERVENTION_MATRIX` with a master fallback.
3. **xlsx vs EBM op conflicts** (§1.4) and the **missing code 3.5** need a WP5 decision.
4. **NBS** is absent from D5.3 Table 5 but present in GUID. Use GUID.
5. **No State/restoration row in the xlsx** (CBG, MTX:84). Restoration exists in EBM, so add it.
6. **Colour-coded CBG edits and the Table 2 colours were lost.** Re-export.
7. **The (o) mode has a time-delay problem** (FIN:1273). Consider offering a "same-step" option, or document the limitation.
8. **Arctic country-specific (multi-layer) graphs** need shared nodes across sub-graphs (FIN:1324-1330). This is not supported by the current single-graph ISA model.
9. FIN:912 says the DTU code repository link is blank, so provenance of the port should be documented.
