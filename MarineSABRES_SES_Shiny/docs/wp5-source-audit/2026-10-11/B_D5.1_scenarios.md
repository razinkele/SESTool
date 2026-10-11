# B. D5.1 (Scenarios × Worldviews) — extraction for toolbox integration

Source abbreviations (all under `scratchpad/txt/`):
- **PDF** = `PDF_D5.1_final.txt` (D5.1 final, Bremner et al., Cefas/AZTI/LifeWatch, v2 26 Feb 2024)
- **V2** = `Task_5.1_..._D5.1_scenarios_report_v2_final.md` (same content as PDF, HTML tables)
- **RT** = `Task_5.1_..._SSP-RCP_regionalisation_table.md` (line numbers = the `<tr>` start line)
- **XM** = `SSP_Worldview_cross_matrix.xlsx.txt`; **RB** = `results_breakdown.xlsx.txt`; **WV** = `WORLDVIEWS_SCENARIOS_FOR_deliverable_5_1.xlsx.txt`
- **JD** = `..._Scenarios_vs_worldviews_paper_D5.1_Journal_draft.md`; **G1/G2** = `..._Re-worked_graph_5.1.md` / `_5.1_2.md`
- **MS** = `PDF_MS5.1.txt`
- App code: `MarineSABRES_SES_Shiny/functions/ses_dynamics.R`, `modules/scenario_builder_module.R`, `modules/analysis_simulation.R`

---

## 0. Bottom line / framing correction

**D5.1 is not a driver-trend scenario set.** It is a qualitative **congruence analysis** between
(a) four global SSP-RCP scenarios regionalised to **European** scale as PESTLE narratives, and
(b) three generic **cultural-theory worldviews** (Egalitarian, Individualist, Hierarchy), also expressed in PESTLE.
Its output is a map of *where transformation is needed* (WV × SSP × PESTLE element), not how drivers/pressures change.

- There is **no per-driver direction/magnitude vector** in any source file. The "SSP-RCP regionalisation table" (RT) is narrative text per PESTLE row per SSP, per sector slice — not trend arrows.
- There is **no DAPSIWRM mapping** of scenarios: D5.1 mentions DAPSI(W)R(M) only to say transformation pathway steps align with the "Responses" step (PDF L285–286), and that the Simple SES will later be used to find leverage points (PDF L1200–1206).
- **Regionalisation stops at Europe**, not at DAs. Per-DA regionalisation is listed as optional future work (PDF L1216–1218).
- **Results are identical for all three DAs** because worldviews were not personalised (PDF L1012–1014). The cross-matrix confirms: only Arctic rows contain text; Macaronesia and Tuscany blocks are empty (XM L4–21 filled vs L22–57 empty).
- The **worldview questionnaire** is only mentioned as "already started" (PDF L1190–1191; V2 L1678). No instrument, items, or results are in the corpus.

So any "apply scenario → perturb Drivers" feature needs a **curation step** (narrative → DAPSIWRM driver deltas) that WP5 did not do. The data that *is* tool-ready is the 72-cell congruence grid (RB).

---

## 1. Scenario framework

### 1.1 SSP-RCPs (IPCC Tier 1; SSP4 excluded)
PDF L426–441: five SSPs exist; the four IPCC Tier-1 SSP-RCP combinations are used (SSP4 "Inequality" dropped as lower priority).

| ID | Name | Global summary (PDF L195–201; RT L21–29) | Warming | EBM conduciveness (Box 1, PDF L448–470) |
|---|---|---|---|---|
| SSP1-RCP2.6 | Sustainability: taking the green road | Gradual pervasive shift to sustainable, inclusive path respecting environmental boundaries | ≤2 °C | Conducive ("well aligned") |
| SSP2-RCP4.5 | Middle of the road | Social/economic/tech trends don't shift markedly from history | ≤3 °C | Somewhat conducive |
| SSP3-RCP7.0 | Regional rivalry: a rocky road | Resurgent nationalism, security concerns, regional focus | ≤4 °C | Not conducive |
| SSP5-RCP8.5 | Fossil-fuelled development: taking the highway | Faith in markets/innovation; fossil-fuel exploitation, resource-intensive lifestyles | >4 °C | Not conducive |

Note: Box 1 contains a typo "SSP1-RCP2.5" (PDF L450) — use 2.6. Expanded O'Neill et al. (2017) narratives: RT L41 and L398; PDF Appendix 1.

### 1.2 Regionalisation method (to Europe)
- DA "environmental foci" chosen from Grant Agreement + early stakeholder feedback: **fisheries → Arctic; (eco)tourism → Macaronesia; conservation → Tuscan Archipelago** (PDF L487–490).
- Narratives were **copied** from prior projects, not newly elicited (PDF L490–498; Table 1 PDF L500–540):

| Source project | Scale | Slice | Nominal RCP used in source |
|---|---|---|---|
| FutureMARES (H2020) | Europe | Seafood harvesting, habitat restoration, conservation | SSP1 as-is; SSP2 **not included**; SSP3 as SSP3-RCP8.5; SSP5 as-is |
| CERES (H2020) | Europe | General + fisheries (aquaculture text fills gaps for SSP2) | SSP1 as RCP4.5; SSP2 as RCP6.0; SSP3 as RCP8.5 |
| AFMEC (UK Gov) | UK | Tourism & leisure | Pre-SSP: Global commons / Local stewardship / Fortress Britain / World markets |

- Framework: **PESTLE** (Political, Economic, Social, Technological, Legal, Environmental), following Pinnegar et al. (2021) (PDF L541–551). Each PESTLE row carries a guiding question (RT L69–188).

### 1.3 The "SSP-RCP regionalisation table" (RT) — actual content
Structure (RT has three stacked blocks):
1. **Future MARES block** (RT L61–188): PESTLE rows × SSP1/SSP3/SSP5 (SSP2 column empty), each cell split into HABITAT RESTORATION / MARINE CONSERVATION / SEAFOOD HARVESTING.
2. **CERES generic + CERES fisheries + AFMEC tourism** (RT L203–322).
3. **Merged "EU narrative"** = D5.1 Table 2 (RT L433–588), cell sub-sections **HRMC** (habitat restoration & marine conservation), **SH** (seafood harvesting), **LH/TOURISM** (tourism & leisure). G2 is the same table re-worked with HRMC/SH/LH tags.

Condensed content of the merged EU narrative (RT L436–588), which is the most usable text:

| PESTLE | SSP1 Sustainability | SSP2 Middle of road | SSP3 Regional rivalry | SSP5 Fossil-fuelled |
|---|---|---|---|---|
| **P** (L436) | Strong UN/EU leadership; MPAs meet 2030 targets (>30%, >10% strict); trans-national MSP; cohesive trans-boundary fisheries treaties, balanced harvesting; heavy fuel taxes discourage overseas travel | NGOs/recreational groups in regional management; self-sufficiency; bottom-up local governance; "eat local seafood"; tourism on local identity | Inconsistent within-EEZ policy; restoration low priority vs energy; MPAs compete with energy/food; tensions over shared/migratory stocks; "cod wars"; import tariffs; national-identity tourism | EU falls apart; restoration abandoned unless profitable; MEY not MSY; Europe out-competed by Asia; low taxes; decommissioning subsidies cut; few travel constraints; cruise/marina expansion |
| **E** (L468) | Willingness to pay for restoration; green business norm; natural capital valuation not-for-profit; stock rebuilding reduces catches/profits; subsidies for alternative employment; wild fish price ↓, cultured ↑; high enforcement; ecotourism revenue ↑ | Small-scale regional economy; converging incomes; **HRMC: no source text**; **SH: no source text**; domestic tourism ↑, cooperatives | Investment shifts to job-creating sectors; restoration targeted to harvestable shellfish; less monitoring/enforcement funding; fish prices ↑ (trade barriers); subsidies to traditional fisheries | Restoration cost-effective for blue carbon; biodiversity banking; MPA entrance fees; multinationals source cheapest fish; no subsidies; low fuel prices → jet-ski/power-boating ↑ |
| **S** (L497) | High ocean literacy; natural capital priority; local/indigenous knowledge valued; demand for low-trophic seafood (seaweed, bivalves); lower meat/fish consumption; ecotourism, fewer powered activities | **HRMC: no source text**; equity/ownership; food-miles; sport fisheries ↑; domestic seaside tourism | Restoration only for iconic species/asset protection; mosaic of attitudes; strong support for traditional fisheries ("maximum social yield"); sport fisheries squeezed out | Support only for market-valuable ecosystems; "blue farms"; poor ocean literacy; loss of traditional knowledge; marginalisation of artisanal fishers; aquaculture reliance ↑; outbound tourism ↑ |
| **T** (L527) | Cheap monitoring (satellite, drones); biodegradable restoration; assisted evolution; low-bycatch gear; large-scale low-trophic aquaculture | Local/regional tech; many small locally-owned vessels; small-scale windfarms disrupt fisheries somewhat | Local tech only; little advancement; EEZ-infringement surveillance | Bio-engineering, artificial habitats; high-tech aquaculture; automation to cut labour; few high-tech boats; few technical restrictions |
| **L** (L556) | Paris/CBD/IPBES embedded in law; severe penalties; EIA for new fisheries | **HRMC: no source text**; mosaic of byelaws; sub-national quota allocation; ITQs; strict discard rules | UN commitments poorly implemented; transboundary legal disputes; weak conservation law; protectionism; ITQs | Environmental agreements abandoned; MSP conflicts; GATT-style trade over conservation; MEY management; private access rights / tradable permits |
| **E** (L588) | Less severe climate shifts; large-scale restoration ↑ ES (carbon); pollution ↓; stocks ↑ → top-predator recovery; ecolabels; fisheries displaced by windfarms/MPAs; blue-flag beaches | **HRMC: no source text**; MSY focus; inshore stocks improve, transnational stocks hard; some closed areas; eco-friendly tourism | Stronger climate shifts; food production areas → carrying capacity issues; biodiversity ↓ (little restoration); food security > MPAs | Continued warming; habitat suitability shifts; degradation from short-term profit; invasives compromise restoration; keystone loss; sequential stock depletion/collapse; warmer resorts more attractive |

**Gap**: SSP2 has no conservation/restoration narrative at all ("SSP not featured in Future MARES, no specific lines in CERES", RT L468–588). This matters most for the **Tuscan Archipelago (conservation focus)** under middle-of-the-road. Tourism has no T/L lines for any SSP ("No specific lines in AFMEC", RT L527, L556) and tourism is UK-derived (PDF L496–498).

### 1.4 Worldviews (cultural theory; Ney & Thompson 2000, Rayner 2006)
PDF L755–775 (rationale), Table 3 PDF L780–960; same text in WV L3–13. Fatalist (4th cultural-theory type) not used.

| | Individualist | Hierarchy | Egalitarian |
|---|---|---|---|
| Keywords (WV L4) | Rapid change, tech innovation, no limits, cultural diversity, individual quality of life | Sustainability, managerialism, targets, steering, scientific expertise, international negotiation, control, optimisation | Prevention, urgency, fragility, participation, new relationship with nature, decentralisation, community, spirituality |
| Problem (WV L5) | Global systems resilient; obstacles to innovation/growth | Global env. & economic systems not under control | Society overshot natural limits (bureaucrats + free markets) |
| Solution (WV L6) | Free markets, growth, innovation | Better control systems & institutions | Rebuild community, drastically reduce human intervention in ecosystems |
| Justice principle (WV L12) | **Priority** (first in time, first in right) | **Proportionality** (by rank, contribution or need) | **Parity** (equal shares) |
| Environment (WV L13) | Low climate sensitivity; nature preserved by markets via scarcity value; aquaculture/restocking | Emissions controlled via UNFCCC protocols; large-scale engineered solutions; managed top-down | Environmental problems truly serious; undisturbed nature has spiritual value |

### 1.5 How they are crossed
- 4 SSP × 3 WV × 6 PESTLE = 72 binary judgements (align / diverge; no partial allowed) by group consensus of Bremner, Oliveira, Mynott, Pinnegar (PDF L971–982).
- XM sheet "Individual matching" (XM L115–135) holds **per-analyst** judgements (Julie, Frances, Bruno), a **Decision** column and **Justification** (e.g. "Julie and Bruno disagree; majority view") — usable as rationale text and as an inter-rater uncertainty flag.
- Four outcome classes (PDF L984–999):
  - **a** match, both conducive → no transformation, incremental change;
  - **b** match, neither conducive → transformation needed but Europe-scale (out of scope);
  - **c** mismatch, WV more conducive than SSP → Europe-scale transformation (out of scope);
  - **d** mismatch, WV less conducive than SSP → **DA-level transformation (project focus)**.
- RB L17–22 restates six decision rules (SSP conducive/not × match × WV more/less conducive).

---

## 2. Relation to DAPSIWRM

- **No explicit mapping** of scenarios to DAPSIWRM elements or CLD nodes in any source. The only link is conceptual: pathway steps = Responses/Measures (PDF L282–293); WP5 intends to use the Simple SES (CLD) to identify leverage points for pathways (PDF L1200–1206, L1220–1223).
- What *can* be inferred (curation, not source data): the PESTLE narratives implicitly describe changes in DAPSIWRM categories. Suggested crosswalk for a curated library:
  - **Drivers** ← S (consumption, diets, ocean literacy), E (prices, willingness to pay, subsidies), P (international cooperation level);
  - **Activities** ← SH/LH text (fishing effort, aquaculture, cruise/marina, powered leisure, domestic vs overseas tourism, windfarms);
  - **Pressures** ← E-environmental (warming level from RCP, invasives, pollution, habitat degradation);
  - **State/ES** ← E-environmental (stock status, top predators, carbon capture);
  - **Responses/Measures** ← P + L (MPA coverage targets, MSY vs MEY, ITQs, EIA, penalties, discard rules).
  This is a curation task requiring domain sign-off (scientific-validation skill), not extraction.
- **Climate forcing** is the one quantitative axis available: RCP warming caps (2/3/4/>4 °C by 2100; RT L29). A "Climate change" driver/pressure node could be scaled by RCP.
- **Stakeholder perceptions**: worldviews are the stakeholder-perception layer, but only as generic archetypes. No per-DA stakeholder data.

---

## 3. Stakeholder method

- **Done in D5.1**: desk-based, team-consensus matrix (PDF L971–982); no stakeholder workshop yet. "This process will be validated by the stakeholders later in 2024" (PDF L1001).
- **Planned** (PDF L1179–1223):
  - (a) a **worldview questionnaire** in each DA to show the relevance of each worldview ("already started", PDF L1190–1191);
  - (b) validation with WP2 using the D4.1 "presumed utility" protocol: workshops, world cafés, serious games (PDF L1195–1198);
  - (c) personalise worldviews to DAs; optionally regionalise SSPs to DA level; refine transformation points (PDF L1211–1220);
  - (d) Simple SES → leverage points → feed D5.2 (CBA), D5.3 (behaviour), D5.4 (governance), D4.2/D4.3, and **Task 6.3 decision-support systems** (PDF L1222–1236). The toolbox is plausibly that DSS host.
- **Can the tool host it?** Yes in principle, but the **questionnaire instrument is not in the corpus**. A self-assessment would have to be built from the cultural-theory literature (Ney & Thompson 2000; grid-group survey items, e.g. Dake/Wildavsky-style scales). Request the actual WP5 questionnaire from Bremner/Oliveira before building, so outputs are comparable with the project data.
- `results_breakdown.xlsx` is **not survey results** — it is the analyst congruence grid (RB L1–38).

---

## 4. Results (generic; identical for all DAs)

### 4.1 Congruence grid (RB L5–16; reconciles with PDF L1083–1152 notation)
Notation: PESTLE letters = elements where WV and SSP **match**, `_` = mismatch.

| WV \ SSP | SSP1 (conducive) | SSP2 (somewhat) | SSP3 (not) | SSP5 (not) |
|---|---|---|---|---|
| Egalitarian | `_ES___` | `PES__E` | `______` | `___T__` |
| Individualist | `______` | `___TL_` | `_____E` | `PESTLE` |
| Hierarchy | `PE_TLE` | `____LE` | `_EST__` | `______` |

"WV more conducive to EBM" flags (RB L7, L11, L15): Egalitarian = Y on every mismatch; Individualist = N on every mismatch; Hierarchy = N on SSP1-S and SSP2-PEST, Y on SSP3-P and all SSP5, SSP3-L = N, SSP3-E(nv) = "?".

### 4.2 Transformation needed at DA level (class **d**) — the project-relevant output
"Transformation needed?" row uses Wingdings glyphs: `ü` = ✓ needed, `ý` = ✗ not needed (RB L8, L12, L16).

| WV | SSP1 | SSP2 | SSP3 | SSP5 |
|---|---|---|---|---|
| Egalitarian | none | none | none (class c) | none (class c) |
| Individualist | **P E S T L E** | **P E S _ _ E** | all (but Europe-scale, class b/d mixed — out of scope) | all (class b — out of scope) |
| Hierarchy | **S** | **P E S T** | E S T L flagged (Europe-scale also needed); Env "?" | none (class c) |

Headline conclusions (PDF L215–232, L1150–1177; JD L1224–1236):
- Egalitarians never need DA-level transformation (incremental change only).
- Project priority = Individualist and Hierarchy under SSP1/SSP2.
- Only fully congruent pair: Individualist × SSP5. Fully incongruent: Egalitarian × SSP3, Individualist × SSP1, Hierarchy × SSP5 (PDF L1107–1113).

**Source inconsistency to flag**: the D5.1 Summary says "four elements of PESTLE (PEST__) for Hierarchy in a Sustainability European society (SSP1-RCP2.6)" (PDF L229–230). The spreadsheet (RB L16) and the journal-draft Discussion (JD L1232) both put Hierarchy PEST under **SSP2**, and Hierarchy under SSP1 needs only **S**. The Summary is an error. Also PDF L1147 prints Hierarchy-SSP2 as `__LE` (missing two underscores).

### 4.3 Per-DA differentiation actually available
- None in the congruence results (PDF L1012–1014; XM empty for Macaronesia/Tuscany L22–57).
- Only the **sector slice**: Arctic = SH (fisheries), Macaronesia = LH (tourism, UK-derived AFMEC), Tuscany = HRMC (conservation) (PDF L487–490).
- Journal draft adds three **intervention strategies for non-aligned (Individualist) worldviews** not in D5.1 (JD L1236–1244): (1) behavioural interventions; (2) system changes via instruments the worldview accepts (e.g. tax incentives, not cooperative agreements); (3) changes kept within the worldview's "limit of acceptable change". Goal: facilitate SSP1, hinder SSP3/SSP5.

### 4.4 MS5.1 is something else
MS5.1 = **Baseline Report** for Task 5.2 economic assessment (Ecologic Institute, Dec 2024; MS L1–20, L90–100), not scenarios. Useful pieces:
- Per-DA objectives: Macaronesia = MPAs × tourism (MS L320–343); Arctic = pelagic fisheries (mackerel, herring, blue whiting, capelin) co-existing with conservation (MS L1063–1081); Tuscany = tourism vs *Posidonia oceanica* (mooring/anchoring), restoration (MS L2563–2614).
- **DAPSIWRM-typed indicator tables with data sources**: Macaronesia Table 5 (MS L777+), Tuscany Table 3 "from WP4" (MS L2895+; e.g. anchorages/EMODnet, marine heatwaves/NOAA, PREI index/ARPAT, *P. oceanica* area lost = data gap). Candidate node-attribute/indicator library per DA; noted data gaps are explicit.
- Tuscany CLD feedback loop: tourism → nutrients/anchoring/litter → *Posidonia* damage → tourism desirability ↓ (MS L2616–2625).

---

## 5. Integration opportunities for the toolbox

Existing app primitives (checked):
- `functions/ses_dynamics.R:681` `simulate_dynamics(mat, n_iter, initial_state = NULL, ...)` (aliased `ses_simulate`, L747) **already accepts an initial-state vector**, but `analysis_simulation.R` (L195–260) never passes one (defaults to `runif`). Note: this is an initial condition, not a sustained press; a persistent forcing term would be new.
- `ses_dynamics.R:1012` `ses_add_intervention(mat, name, affected_nodes, indicator_nodes, effect_range)` and `:1092` `ses_compare_interventions()` are existing perturb/compare primitives.
- `modules/scenario_builder_module.R` is **structural** what-if (add/remove nodes/links, L249–300), not parametric. Do not conflate with SSP scenarios.

| # | Feature | Data source | Structured data that exists | Gaps / work needed | Effort / value |
|---|---|---|---|---|---|
| 1 | **Scenario library JSON** (`data/wp5_scenarios.json`): 4 SSP-RCP × PESTLE × sector slice (HRMC/SH/LH) narratives, warming cap, EBM-conduciveness | RT L433–588 (merged EU narrative), RT L21–41 (global), Box 1 PDF L448–470, Table 1 PDF L500–540 | Clean 4×6×3 text cells; conduciveness ordinal (yes/somewhat/no/no); warming 2/3/4/>4 °C | SSP2 HRMC empty; tourism T/L empty; text English only (9-lang i18n needed: narratives as long-form content, maybe EN-only with translated labels); `driver_mapping` must be curated | Low effort, medium value: reference panel in Scenario/Decision-Lens tabs |
| 2 | **Worldview × SSP congruence matrix** (`data/wp5_worldview_ssp_matrix.json`) with outcome class a–d per cell and rationale text | RB L5–16 (Y/N), RB L17–22 (rules), XM L115–135 (per-analyst rationale + decision), PDF Table 6 L1406+ | 72 cells fully determined; justifications exist (Arctic rows) | Wingdings glyph decoding; SSP3 Hierarchy Env = "?"; fix Summary inconsistency; generic (not DA-specific) | Low effort, high fidelity to deliverable: heat-map widget "where transformation is needed" |
| 3 | **Worldview self-assessment** → profile (E/I/H shares) → highlights relevant row of matrix (#2) and suggests intervention strategy (JD L1236–1244) | WV keywords/justice principles (WV L4–13); PDF Table 3 | Worldview descriptors only | **Questionnaire not in corpus** — obtain WP5 instrument; otherwise build from cultural-theory scales and label as non-WP5. Needs scoring rules, consent/privacy if stored | Medium effort; high stakeholder-workshop value |
| 4 | **"Apply scenario" to CLD**: map SSP narrative to deltas on user's Driver/Activity/Pressure nodes, run `simulate_dynamics(initial_state=…)` or `ses_add_intervention`, compare vs baseline | #1 library + user CLD | Only the RCP warming level is quantitative | **No driver trend vectors in WP5 data.** Requires curated crosswalk (Section 2) from narrative to DAPSIWRM node classes, with sign (+/−/0) only; user must confirm which of their nodes match (e.g. by keyword/KB element IDs). Needs scientific-validation sign-off; persistent forcing would require extending `simulate_dynamics` | High effort; risk of over-claiming. Recommend ordinal sign-only "scenario press" with user-editable mapping |
| 5 | **Scenario comparison / robustness of measures**: run a user's Response/Measure set under each of the 4 SSP presses; flag measures robust across scenarios | #4 + existing `ses_compare_interventions` | — | Depends on #4 | Medium, after #4 |
| 6 | **Transformation-pathway link to Leverage/Decision Lens**: for cells of class d, surface leverage points (existing leverage module) tagged by PESTLE domain (P/E/S/T/L/E → Responses/Measures categories) | PDF L1200–1206 (intended use); JD L1236–1244 | PESTLE gap pattern per WV×SSP | Needs a PESTLE tag on Response/Measure elements (new optional attribute) | Medium; directly matches WP5's stated next step |
| 7 | **DA baseline indicator library** (per-DA DAPSIWRM indicators with data sources) for node attributes | MS Table 5 (L777+), Table 3 (L2895+) | Typed rows: type, element, indicator, description, data source | Arctic table not checked here; some "Data gap" entries; overlaps with D5.2 integration plan | Low–medium |

Suggested JSON provenance fields per scenario cell: `ssp`, `rcp_nominal`, `rcp_in_source` (CERES SSP1 = 4.5, SSP2 = 6.0, SSP3 = 8.5; FutureMARES SSP3 = 8.5), `source_project` (FutureMARES/CERES/AFMEC/O'Neill2017), `source_geography` (Europe/UK), `sector_slice` (HRMC/SH/LH/general), `pestle`, `text`, `driver_mapping: null` (explicit curation placeholder), `source_ref` (file:line).

### Key gaps to raise with WP5 (Bremner/Oliveira/Pinnegar)
1. The worldview questionnaire instrument and any DA results (needed for #3).
2. Whether DA-level SSP regionalisation or worldview personalisation was done after Feb 2024 (would supply per-DA differentiation now missing).
3. Validation workshop outcomes (planned "later in 2024", PDF L1001).
4. Confirmation of the Summary error (Hierarchy PEST under SSP2, not SSP1).
5. Whether WP5 endorses an ordinal narrative → DAPSIWRM driver crosswalk for #4.
