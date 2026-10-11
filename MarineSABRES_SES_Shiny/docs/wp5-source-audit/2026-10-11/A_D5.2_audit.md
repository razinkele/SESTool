# Audit A: WP5 integration plan vs the final D5.2

Audit date: 2026-10-11. Read-only research.

Files compared:
- Plan: `SP/txt/WP5_Integration_Analysis_2026-04-23.md`, written from Draftv3 and the April notes.
- Roadmap: `docs/superpowers/specs/2026-05-06-wp5-integration-roadmap-design.md`
- Shipped KB: `data/ses_knowledge_db_wp5_mechanisms.json` (`version 1.0.0`, `last_updated 2026-05-07`, `source_commit 1f636e8`, built from four April drafts)
- Final deliverable: `SP/txt/PDF_D5.2_Final.txt` (13,426 lines). It is called **FINAL** below, and every `Lnnnn` reference is a line in this file unless another file is named.

Text-extraction caveats:
- pdftotext dropped the € glyph and the arrow glyphs (↑ ↓ →). Cost-band symbols and direction arrows are missing in FINAL, so every EUR figure was cross-checked against `D5.2_MarineSABRES_Deliverable5.2_Draftv5.md` (called Draftv5 below; its tables have clean pipes).
- Figures 2, 5 and 6, Annex 3 and Figure A7.1 are images. Their content cannot be extracted from the text.

---

## 1. Which PDF is final

| File | Version table | Date | Lines | Authors |
|---|---|---|---|---|
| `PDF_D5.2_Submitted.txt` | v1 15/07/25, v2 07/08/25, **v3 08/08/25** | 08 Aug 2025 | 7,590 | Lago, Kroos, Fuchs, Maund |
| `PDF_D5.2_Final.txt` | v1–v3 as above + **v4 27/02/26** + **v5 23/06/26** (L9–L76) | **23 Jun 2026** | 13,426 | + Jenny Tröltzsch (L5) |

FINAL (v5, 23 June 2026) is the latest version. It is labelled "pending official approval by the European Commission" (L148).

Compared with the Submitted v3, FINAL adds:
- §4.9 Tuscan financial mechanisms (Table 20)
- Arctic financial mechanisms (Table 9, L2255–2440)
- a full rewrite of chapter 5: Macaronesia S1–S4, Tables 21–23 and Table 22, the toolkit
- Annex 7 (Macaronesia intervention selection) and Annex 8 (indicator fiches)

None of these are in Submitted v3 or Draftv3 (grep counts: "Table 22", "Annex 8", "Light Designation" and "Results-based" are all 0 in Submitted/Draftv3). The KB (May 2026) therefore predates FINAL by about seven weeks. The plan's source, Draftv3, is effectively the Submitted v3 text plus separate April notes.

---

## 2. Seven-step framework and five criteria

### 2.1 The seven steps (L683–736, §1.4): unchanged and matching the plan

| Step | FINAL wording (line) |
|---|---|
| 1 | Environmental, social, and economic characterization (L704) |
| 2 | Definition of baseline and management options (L709) |
| 3 | Scoping of potential impacts (L714) |
| 4 | Impact assessment using core evaluation criteria (L719) |
| 5 | Dealing with uncertainty: risk and sensitivity analysis (L723) |
| 6 | Reporting of results: trade-offs, synergies, distributional effects (L728) |
| 7 | Recommendations and advice (L733) |

FINAL also says: "IMPACT = the difference in performance between a given intervention and the baseline" (L609–611, Figure 1).

### 2.2 Five criteria (§1.5, L738–792): present, but labels drift inside FINAL itself

| Plan code | §1.5 body name (L740–773) | Footnote 19 (L3971) | Macaronesia Table 21 header (L4804) | Annex 8 fiches / indicator shortlist |
|---|---|---|---|---|
| EE | Environmental effectiveness | **Ecological** Effectiveness | Environmental effectiveness | EE |
| EC | Economic efficiency | Economic Efficiency | Economic efficiency | EC |
| EQ | Equity and fairness | **Equity** | Equity & fairness | EQ |
| PI | **Policy** implementability (L763) | **Political** Implementability | Political implementability | **PO** (e.g. L10869, L12432) |
| FF | Financial feasibility | Financial Feasibility | Financial feasibility | **FI** (e.g. L11089, L12480) |

The Arctic §3.5.4 heading is "Political implementability" (L2098). The Macaronesia §5.5.4 heading is "Governance and political implementability (PI)" (L5195).

**Recommendation:** use the canonical codes EE/EC/EQ/PI/FF and accept PO and FI as aliases, so that the fiche data can be imported.

FINAL refines two criteria (Macaronesia):
- EQ has three dimensions: **distributional**, **procedural** and **recognitional** (L5108–5112, citing Blythe et al. 2026).
- PI has three channels: **credibility**, **manageability** and **contestation risk** (L5203–5210).

### 2.3 Scoring rubric (Macaronesia only; L3987–3996, "Phase 3 – Score scenario responses")

- **Direction:** increase / decrease / no material change / uncertain
- **Relative magnitude:** incremental / moderate / substantial, defined per indicator. This is ordinal, not numeric.
- **Timing:** short / medium / longer term
- **Confidence:** high / medium / low
- **Evidence tag:** dataset / literature / stakeholder elicitation / DA judgement / triangulation
- **Dominant uncertainty driver** (recorded when confidence is low): data gap / contested assumption / weak causal link / implementation dependency
- **Indicator role tag per criterion:** primary vs supporting (or secondary). This avoids double counting (L3967–3969).
- **Pathway segment tag:** pressure / state / benefit / governance capacity (L3969–3975)

Other scales in FINAL:
- C_01 uses its own ordinal legend: `0` no material change; `+` procedural gain; `++` operational gain within EEZs; `+++` end-to-end gain including ABNJ (L10732–10733).
- Time horizons: short 1–3 yr, medium 4–7 yr, long 8–15 yr (Table 12 L2533; Table 23 L5512–5515).

**Discrepancies:**
- **Roadmap §8.4** defines `magnitude (0–10)` and `governance_ambition (0–4)`. FINAL uses ordinal magnitude, so a 0–10 scale is not a reproduction of D5.2.
- The roadmap's C_01 schema sketch ("dimensionless index (0–1)", "satellite tracking", baseline 2020–2024) contradicts FINAL. FINAL reports C_01 as "a structured, evidence-based connectivity profile, **rather than a single numeric index**" (L10273), based on recurrence classes and MONICET/CETUS/GBIF data.
- The Arctic and Tuscan chapters do **not** use this rubric.
  - Arctic: narrative per criterion plus one ordinal rating table (Table 8, political feasibility).
  - Tuscan: a valuation chapter with no criterion scoring.

---

## 3. Scenarios per DA (reference data for an impact-assessment module)

### 3.1 Arctic NEA: 3 scenarios (L1438–1516; §3.5 L1767–2548)

The scenarios are **Scenario 1: No Agreement**, **Scenario 2: Partial Agreement** ("this is the status quo", L1745) and **Scenario 3: Full Agreement**.

Key features (L1716–1763):

| | No Agreement | Partial Agreement | Full Agreement |
|---|---|---|---|
| Quota setting | Unilateral, far above ICES | TAC aligned with ICES, but sum of national quotas exceeds it | TAC = ICES advice (2025: mackerel 576,958 t; herring 401,794 t; blue whiting 1,447,054 t) |
| Certification | None possible | MSC suspended | MSC reinstated |
| Fishing mortality | Above precautionary limits | Above FMSY | Below FMSY |
| Stock outlook | Accelerated depletion | Gradual decline | Stabilization / rebuilding |

Criterion results:

- **EE (§3.5.1):** narrative only. Overshoot of ICES advice in 2023: mackerel 35%, herring 33%, blue whiting 28% (L1788).
- **EC (§3.5.2): revenue by scenario, in USD millions, using retail midpoint prices** (Tables 2–7, L1869–2050):

| Country | Species | Baseline (2024; Greenland 2023) | Full | Partial (= baseline) | No |
|---|---|---|---|---|---|
| Faroe | Mackerel | 332.85 | 285.6 | 332.9 | 183.9 |
| Faroe | Herring | 1,050 | 1,190 | 1,050 | 760.4 |
| Faroe | Blue whiting | 2,610 | 2,710 | 2,610 | 1,660 |
| Greenland | Mackerel | 88.32 | 97.1 | 88.3 | 56.4 |
| Greenland | Herring | 129.28 | 146.5 | 129.3 | 93.4 |
| Greenland | Blue whiting | 156.39 | 162.7 | 156.4 | 99.7 |
| Iceland | Mackerel | 807.88 | 693.2 | 807.9 | 446.4 |
| Iceland | Herring | 822.79 | 932.2 | 822.8 | 594.5 |
| Iceland | Blue whiting | 1,610 | 1,670 | 1,610 | 1,020 |

Inputs:
- Landings: Faroe 2024 69,489 / 59,426 / 433,281 t; Greenland 2023 29,100 / 7,300 / 26,000 t; Iceland 2024 89,615 / 134,552 / 321,047 t.
- Prices (USD/t): Faroe 4,790 / 17,710 / 6,015; Greenland 3,035 / 17,710 / 6,015; Iceland 9,017 / 6,114 / 5,000.
- Stated assumptions: Full Agreement = ICES 2025 TAC change (−22% / +3% / −5.4%) and a +10% MSC premium. No Agreement = −20% landings (Faroe) or −35% for mackerel (Greenland and Iceland), and −15% price. Annex 6 (L10034–10065) instead gives Full Agreement +5% landings (medium term) and +10% price, and No Agreement −20% landings and −15% price.

**Data-quality findings (my recomputation):**
- The tables actually imply species-specific No Agreement landings cuts of mackerel −35%, herring −15% and blue whiting −25%. This holds for the Faroe Islands and Iceland, which contradicts the stated "−20%" for the Faroe Islands.
- Greenland mackerel No Agreement implies −25%, not the stated −35%.
- Greenland mackerel Full Agreement (97.1) applies only the +10% premium. With the stated −22% TAC change it would be about 75.8.
- Annex 6 (+5% landings) is inconsistent with the tables. A module must store the published table values, not recompute them from the stated assumptions. These inconsistencies should be raised with the partners.

The remaining Arctic criteria:

- **EQ (§3.5.3):** narrative only.
- **PI (§3.5.4), Table 8 (L2166–2180):** political feasibility is **Full = Low to moderate; Partial = Moderate; No = High**.
- **FF (§3.5.5):** narrative only. MSC price premium of 10–15% (L2245).
- **Synthesis tables:** Table 10 (comparison of outcomes, L2469), Table 11 (impact areas: stock status, revenues, certification, fuel/emissions, quota fairness, political feasibility; L2511–2531) and Table 12 (impacts over time, L2533–2547). All three are qualitative text cells.

### 3.2 Tuscan Archipelago: no scenarios in FINAL

Chapter 4 is a **valuation and benefit-transfer chapter**. It states that Task 4.3 field data was not yet available, so it supports "future ex-ante impact assessment" (L2784–2793).

- No scenario set and no criterion-by-scenario assessment exist. The only scenario framing is the qualitative "preventive protection vs costly restoration" argument (L3348–3375).
- The plan's "pathways around restoration and preventive protection" is a reasonable paraphrase, but there is **nothing to score**.
- The KB's Tuscan entries refer to "S1 BAU / S2 Light / S3 Coordinated" scenarios (tus_01, tus_03–tus_06). These are Macaronesia labels and do not exist for Tuscany.

### 3.3 Macaronesia: 4 scenarios, renamed in FINAL (§5.4 L4505–4767)

| Code | FINAL section heading | FINAL short label (Tables 21 and 23) | Plan / KB label |
|---|---|---|---|
| S1 | Business-as-usual (No Corridor) (L4537) | S1 BAU | S1 Business-as-usual |
| S2 | **Corridor – Light Designation (Voluntary coordination)** (L4581) | S2 Light coordination | S2 Light |
| S3 | **Corridor – Effective Designation (Operational corridor within EEZs)** (L4631) | S3 Coordinated EEZ corridor | S3 Coordinated EEZ |
| S4 | **Corridor + Sectoral Alignment (EEZ + ABNJ linkages)** (L4691) | S4 Integrated EEZ + ABNJ corridor | S4 Integrated EEZ + ABNJ |

FINAL describes the scenarios as "governance escalation pathways rather than alternative futures" (L4533–4535).

Scenarios vary along four levers (L4235–4241, L4516–4521): (i) institutionalization, (ii) spatial scope, (iii) sectoral alignment and (iv) delivery credibility (staffing, financing, monitoring and compliance).

Each scenario is described along six dimensions: governance form, spatial scope, sectoral activation, monitoring and data, compliance credibility, and financing/capacity. Each also ends with a working hypothesis. The Figure 5 scenario specification matrix (L4529) is an image.

**Table 21: cross-scenario assessment (L4798–4851), the core reference data:**

| | EE | EC | EQ | PI | FF | Confidence |
|---|---|---|---|---|---|---|
| S1 | No additional impact beyond existing MPAs | High short-term efficiency; long-term inefficiencies | Uneven outcomes persist | **High** | **High** (no added cost) | **High** |
| S2 | Minor improvements | High (low implementation costs) | Slight improvement | **High** | **High**, low additional cost | **Medium–High** |
| S3 | Clear ecological gains | **Moderate** (higher costs need offsetting) | More balanced if safeguards exist | **Medium** | **Moderate** | **Medium** |
| S4 | **High** effectiveness | High long-term efficiency; significant short-term adjustment costs | High potential if redistribution and compensation exist | **Lower to medium** | **Challenging** (high costs) | **Low–Medium** |

Table 23 (L5517–5554) gives qualitative impacts over time for S1–S4 at 1–3, 4–7 and 8–15 years.

**Indicator-level scenario data in Annex 8:**
- **C_01, Table 3 (L10730–10820)**, with columns near-island / transit / cross-jurisdiction continuity / confidence:
  - S1: `0 / 0 / 0`, confidence High
  - S2: `0/+ / 0/+ / +`, confidence Medium–High
  - S3: `++ / 0/+ / ++`, confidence Medium
  - S4: `++/+++ / +++ / +++`, confidence Medium
- **F_02 (pelagic landing share), Table 1 (L11268–11320)**, as tuna landings / non-tuna landings / tuna value vs baseline:
  - S1: 0 / 0 / 0
  - S2: −2..+2% / 0..+3% / 0%
  - S3: −5..+5% / 0..+5% / 0..+1%
  - S4: −5..+10% / 0..+7% / 0..+2%, only if the mechanism is evidenced
  - Baselines for 2022–24, tuna share: Madeira 37.77%, Azores 45.48%, Canaries 51.24% (L11139–11160).
- **Vessel movements (L12729–12750), total visitors (L13016–13035) and tourism companies (L13284–13305):** Direction/Magnitude tables whose arrow glyphs are lost in the text extraction. Direction is in the PDF but not extractable.
- **Baselines:**
  - Visitors (Table 7, L12917):
    - Azores 1,031,090 / 1,176,645 / 1,282,081
    - Madeira 1,772,776 / 2,090,849 / 2,231,584
    - Canaries 12,449,338 / 13,564,375 (2022 / 2023; 2024 not available)
  - Operators (Table 9, L13217): Azores 166 / 188 / 201; Madeira 130 / 153 / 173
  - Vessels Azores↔Madeira/Canaries: 71 (2023), 64 (2024) (L12662–12668; the caption mislabels this as "marine tourism companies")

---

## 4. Posidonia valuation (Table 19, L3287–3325) and other values

| Service | FINAL €/ha/yr | Method | Plan | KB |
|---|---|---|---|---|
| Coastal protection | 3,500–17,200 | Avoided cost | same | same |
| Carbon sequestration | 40–240 | Market price / social cost of carbon | same | same |
| Recreation & tourism | 400–4,600 | Travel cost, WTP, direct revenue | same | same |
| Food provision | 150–1,800 | Market pricing (nursery function) | same | same |
| Water purification | 350–2,000 | Replacement cost | same | same |
| **Total** | **4,440–25,840** | | same | – |

Sources: Stamatiadou et al. 2025, Pascal et al. 2014, Luisetti et al. 2013 (L3325).

- **Restoration cost and survival:** €100,000–500,000/ha and early survival 38–60% (REE 2022; Bayraktarov et al. 2016) (L3351–3356). These match the plan and KB.
- **20-year cumulative:** "€88,800 to over €500,000 per hectare" (L3360–3361). This is simply 20 × the annual value. **It is undiscounted.**
- **No discount rate, no NPV and no B/C ratio appear in FINAL for any DA.** The only "benefit cost ratio" is a quoted UK figure (L2996). The roadmap's NPV at 0/3/5/7% is an **addition by the toolbox, not a D5.2 method**. It should be labelled as such.
- **KB "central" values** (10,350; 140; 2,500; 975; 1,175) are arithmetic midpoints added by the KB, not D5.2 values.

Other monetary or biophysical values in FINAL:

- **Arctic fisheries:** the revenue tables in §3.1 above (USD, retail prices; ex-vessel price is 30–50% of retail, L1864).
- **Literature values (Tuscan §4.3.3):**
  - Spain blue carbon €8,634M (227 Mt CO2e) at a carbon price of €38→121/t (L2940–2945)
  - UK Zostera £3,360/ha average (£24/t) (L2950–2952)
  - Mediterranean seagrass-associated fisheries contribution €58–91M/yr commercial and €112M recreational (L2964–2967)
  - Tables 13, 14 and 15 are images or partly extracted.
- **Table 18 (L3205–3279): biophysical reference values for the registry:**
  - shoot density ~400–700 shoots/m²
  - canopy 30–100 cm
  - root/rhizome biomass up to ~1,500 g/m²
  - nutrient uptake up to ~60 g N and ~10 g P per m²/yr
  - denitrification ~1.8 mg N/m²/h
  - fish/invertebrate biomass 500–1,000 g/m²
  - carbon sequestration 83–150 g C/m²/yr
  - sediment organic C up to ~10 Mg C/ha
- **Macaronesia:** no monetary valuation. Tourism revenue appears only in the source spreadsheet (`Indicators_Data_ALL.xlsx.txt`, e.g. Azores tourism revenue €129.2M / €160.6M / €189.4M for 2022–24), not as a valuation.
- **Macaronesia cost bands (Table 22):** four bands: € (<€0.25m/yr), €€ (€0.25–1m), €€€ (€1–5m), €€€€ (>€5m) (L5354; glyphs from Draftv5 L2557). The band per mechanism is listed in §6.

---

## 5. Indicator set

### 5.1 Resolving the numbering

The main text uses the **renumbered (canonical)** codes in §5.5 (L4793 Figure 6 caption, L4993–5002, L5122–5129) and in the Table 22 legend (L5355–5356):

| Code | Name in FINAL main text |
|---|---|
| C_01 | Connectivity (Index, migratory species) |
| C_02 | Monitoring / implementation capacity |
| F_01 | Pelagic (tuna) landing share |
| F_02 | CPUE |
| F_03 | Fleet + charter capacity (fishing participation & fleet capacity) |
| M_01 | Vessel movements |
| M_02 | Traffic / vessel interaction with sensitive areas |
| T_01 | Total visitors |
| T_02 | Marine tourism revenue |
| T_03 | Plan/shortlist: wildlife-watch participation. **Annex 8 fiche: "Number of marine tourism companies" (operators)**, L13148 |
| T_04 | Marine tourism employment |

The **Annex 8 fiches still carry the pre-renumbering codes:**
- F_02 = Pelagic landing share (L10986)
- F_03 = CPUE (L11591)
- F_04 = Fishing participation & fleet capacity, split into F_04a commercial and F_04b charter (L11893–11912)
- a stray "M_03 vessel–sensitive area interactions" (L11067)

The main text also slips once: "F_04" at L5288 (FF section).

`Indicator_Shortlist.md` confirms that the F_01–F_03 renumbering happened after an indicator was "DELETED AS SUBSUMED UNDER F_04", and an M indicator was "subsumed under C_02" (lines 78 and 152 of that file).

**Conclusion:** the plan's codes match the FINAL main text. The annex filenames (F02/F03/F04) are stale. Map them as Annex F_02→F_01, F_03→F_02, F_04→F_03 and M_03→M_02.

Copy-paste errors in the fiche headers:
- The M_01 fiche's criteria table header says "Use of T_03" (L12615).
- The T_01 fiche header says "Use of F_04" (L12880).

### 5.2 Fiche coverage (Annex 8, L10260–13426): only 7 of 11 indicators have fiches

- C_01 (L10262)
- landing share (L10986)
- CPUE (L11591)
- fleet/charter (L11893)
- vessel movements (L12584, "Indicator: Number of vessel movements between islands", no code)
- total visitors (L12850)
- marine tourism companies (L13148)

**No fiche exists for C_02, M_02, T_02 or T_04.** They are cited in the text without definitions or baselines. The roadmap's "11 Macaronesia registry entries" therefore assumes fiche content that does not exist for four indicators.

### 5.3 Fiche fields

Each fiche contains:
- Definition / purpose
- "Why this indicator matters / relevance" (connectivity, pressure redistribution, governance)
- **Primary assessment criteria table:** each criterion with role Primary / Secondary / Supporting and a rationale
- Limits of the indicator
- **Step 1:** baseline construction, with baseline data table and interpretation
- **Step 2:** scenario-based translation, with a Direction/Magnitude synthesis table per S1–S4
- **Step 3:** impact interpretation
- **Step 4:** assessment against criteria
- **Step 5:** cross-scenario synthesis
- Corridor design / adaptive-management implications (e.g. L12520–12580: lever → why → what to monitor early → trigger response)
- Uncertainties

The plan's list (definition, unit, spatial scope, baseline period, sources, stakeholders, criteria role, pathway segment) comes from L3966–3975 and is accurate as a summary. The fiches themselves are long-form prose, not uniform tables.

### 5.4 Tuscan biophysical indicators (Table 17, L3116–3194; values in Table 18)

| Ecosystem service | Indicators |
|---|---|
| Coastal protection | meadow density (shoots/m²), canopy height (cm), root & rhizome biomass (g/m²), wave energy reduction (%), sediment accretion (cm/yr) |
| Water purification | nutrient retention N, P (kg/ha/yr), water clarity (Secchi m, NTU), denitrification (mg N/m²/h), bacterial/pathogen filtration (%) |
| Food provision | fish & invertebrate biomass, juvenile fish density, species richness, leaf area index, organic matter export |
| Climate regulation | C sequestration rate, sediment organic C (Mg C/ha), NPP, blue-carbon burial, decomposition rate |
| Recreation & tourism | transparency, seagrass cover (%), biodiversity index, charismatic species observations |
| Life-cycle maintenance | juvenile recruitment, epiphyte biomass, stable isotopes, meadow extent (ha) |
| Biotic materials | biomass production, cellulose/lignin, decomposability |
| Cognitive / cultural | endemic/Red-List species, banquettes (m²), meadow longevity |

The plan's examples (density, canopy, below-ground biomass, denitrification, C sequestration) all match. There are no codes; the KB's `POS_density` code is invented.

### 5.5 Arctic indicators

There is no formal indicator set. The text uses:
- landings (t) and prices (USD/t) per species and country
- TAC vs ICES advice and the % overshoot
- SSB vs MSY Btrigger/Bpa/Blim, and F vs FMSY/Fpa (L1791–1812)
- MSC certification status
- the WP3 qualitative indicator "Agreements on Quotas" (L1123–1128)

The **KB's Arctic `success_metrics` are all empty**, consistent with this.

### 5.6 Annex 1 DAPSIWRM-typed indicator tables (missed by the plan)

- **Tuscan Table 6 (L8291–8420, from WP4 / Borja et al. 2024):** Type (Human needs, Activity, Pressures, Marine processes & functions, Ecosystem services, Goods & benefits) → Element → Indicator → Description → Data source. Examples: "Vessel anchorages → potential anchorages (EMODnet)" and "Disturbance → area of P. oceanica disturbed (km², data gap)". This is directly mappable to D/A/P/C/ES/GB/HW.
- **Tuscan Table 5 (L8265):** PIMS stakeholder typology: Extractors, Inputters, Beneficiaries, Affectees, Regulators, Influencers.
- **Macaronesia Table 7 (L9020–9080+):** typed tourism-pressure indicators (Needs, Activities, Dominant pressures, ...) with sources (ISTAC, DRPM, OTA, ...).

---

## 6. Financial mechanisms: FINAL vs the shipped KB

### 6.1 Counts

| DA | FINAL | KB | Delta |
|---|---|---|---|
| Arctic | **8** (Table 9, L2261–2319) | 6 | −2 |
| Tuscan | **7** (Table 20, L3402–3438) | 6 | −1 net (2 missing, 1 split into 2) |
| Macaronesia | **16** (Table 22, L5352–5464) | 16 | 2 replaced by untraceable entries |
| **Total** | **31** | **28** | |

### 6.2 Arctic (Table 9; clean copy in Draftv5 L1535)

| # | FINAL mechanism | Applicability under scenarios | KB |
|---|---|---|---|
| 1 | Shared public financing of scientific advice | All scenarios; more effective under coordinated agreements | arc_02 (ok) |
| 2 | National financing of monitoring, control and surveillance (MCS) | Essential in all; efficiencies strongest under Full | arc_03, named "National financing of **NEAFC governance** and enforcement" (drift) |
| 3 | Rights-based quota allocation systems | Most effective under Full | arc_04 (ok) |
| 4 | Quota leasing and trading | Most effective under Full; fragmented under No/Partial | arc_05. Its `use_in_impact_assessment` says use "particularly S1/S2", which **contradicts FINAL** |
| 5 | Cost-recovery instruments (licence and fishing fees) | Mainly under Full and stable RBM | arc_01 |
| 6 | Market-based certification incentives (MSC) | Strongest under Full | arc_06 (ok) |
| 7 | **Fisheries research and innovation funds** | Complementary across scenarios | **MISSING** |
| 8 | **Public–private and CSR-linked sustainability funding** | Complementary, currently limited | **MISSING** |

The KB stores no "who pays / governance interface / applicability under scenarios" columns. Those columns are the natural link data for a scenario module.

### 6.3 Tuscan (Table 20; clean copy in Draftv5 L2054)

| FINAL mechanism | Applicability | KB |
|---|---|---|
| Public grants and subsidies | High | tus_03 (ok, RESTORE4Cs references traceable) |
| User fees and service charges | High | **split** into tus_02 mooring-buoy permit fee and tus_04 concession fees |
| Public–private partnerships (PPPs) | Medium–High | tus_05 (ok) |
| Payments for Ecosystem Services (PES) | Medium (long-term potential) | tus_01, but with **different content** (see §6.5) |
| **Biodiversity / blue-carbon credits** | Low–Medium | **MISSING** |
| Blended finance and de-risking | Medium | tus_06 (ok) |
| **Certification and branding** | Complementary | **MISSING** |

The April Tuscan draft already listed all 7 of these (`Draft_financial_mechanisms_Tuscan_DA.md` lines 7–19), so the KB omitted two mechanisms that were in its own source.

### 6.4 Macaronesia (Table 22, with cost bands from Draftv5 L2560–2577)

| # | FINAL / toolkit mechanism | Cost band | KB id |
|---|---|---|---|
| 1 | **Corridor coordination & platform resourcing (MoU → steering → secretariat)** | €€ | **mac_01 "Blue Corridor Facility": substituted, untraceable** |
| 2 | Multi-year Delivery & Shared-Services Facility (ring-fenced) | €€€ | mac_03 |
| 3 | Shared evidence & decision-products layer | € | mac_04 |
| 4 | Integrated monitoring & annual indicator pipeline (pressure + activity) | €€–€€€ | mac_05 (name shortened to "data pipeline") |
| 5 | Compliance enablement service ("single front door") | €€ | mac_06 |
| 6 | Adaptive contingency reserve | €–€€* | mac_07 |
| 7 | Due process & appeals handling capacity | € | mac_08 |
| 8 | **Local stewardship contributions & benefit-sharing (port/landing levy + tourism fee + microgrants)** | €–€€ | **MISSING; mac_02 "MPA tourism-levy fund" is untraceable** |
| 9 | Results-based financing for verified behaviours | €–€€ | mac_09 |
| 10 | Fisheries interaction-risk reduction package fund | €€–€€€ | mac_10 |
| 11 | Fisheries monitoring coverage uplift window | €€€ | mac_11 |
| 12 | Seasonal enforcement surge ("tuna season package") | € | mac_12 |
| 13 | Managed transition & shock buffering | €€–€€€* | mac_13 |
| 14 | Traceability & market access pathway (conditional) | € | mac_14 |
| 15 | Maritime transport risk-reduction implementation support | €–€€ | mac_15 |
| 16 | Tourism & wildlife-use standards + oversight coherence | € | mac_16 |

The KB references "mechanism #2…#16" but skips #8, which confirms that toolkit #1 and #8 were replaced. The KB also lacks the cost band, the "what success looks like (linked to indicators)" text, and the S2/S3/S4 activation notes that the toolkit gives for #1.

### 6.5 KB entries that look invented or untraceable

Sources grepped: the toolkit, both April DA notes, Draftv3/v5 and FINAL.

| KB entry | Problem |
|---|---|
| **mac_01** Blue Corridor Facility | Name, "annual operating budget €5–15M", "three-jurisdiction board, rotating chair", "MedPAN Fund", "OSPAR CEMP" and "philanthropic foundations" **appear in no WP5 source**. MedPAN occurs only in D5.4. Reference "D5.2 §5.x" is a placeholder. Replaces toolkit #1. |
| **mac_02** MPA tourism-levy fund | Galápagos entry fee and Bonaire dive tag are **not in any source**. Reference "Blue Corridor toolkit, §x.x" is a placeholder. Replaces toolkit #8. |
| **tus_01** PES | "Costa Rica PSA", "Boudouresque et al." and payments to "coastal landowners" are **not in sources**. FINAL's PES is beneficiaries paying for protection (L3505–3524). Uses `POS_density` and "S2 Light or S3 Coordinated". Reference "§x.x". |
| **tus_02** Mooring-buoy permit fee | Evidence is generic; reference is "§x.x"; uses `POS_density`. It is a sub-case of "user fees", not a D5.2 mechanism. |
| tus_03–tus_06 | RESTORE4Cs citations are traceable, but the `use_in_impact_assessment` text references **non-existent Tuscan S1/S2/S3 scenarios**. All use the invented code `POS_density`. |
| **arc_01** Cost-recovery fees | "Iceland fisheries fee (operational precedent since 2012)" and "OECD Sustainable Fisheries (2022)" are **not in FINAL**, which cites Althingi 2025 for veiðigjald and OECD 2024 FSE (L2384–2389). Payer/receiver list "NO, IS, FO, RU" excludes Greenland and includes Norway and Russia, which are not DA states. Reference "§x.x". |
| arc_03 | Payer list includes RU; the name drifts from FINAL's "MCS". |
| arc_02, arc_04, arc_06 | Traceable (ICES 2020, NEAFC 2014, Abbott et al. 2022, WWF, MSC). |
| All Arctic | `success_metrics: []`. Scenario labels "S1 No Agreement / S2 Partial / S3 Full" are acceptable (FINAL says Scenario 1/2/3). |

**Success-metric codes:**
- Macaronesia entries use F_01–F_03, which is consistent with canonical numbering.
- mac_01 lists C_01, C_02 and M_01. This is invented: toolkit #1 uses C_02 → M_01/M_02, F_03 and T_03.
- `POS_density` is not a D5.2 code.

**`use_in_impact_assessment` text** (e.g. "score positively on EE, negatively on PI") is authored by the KB builder throughout. D5.2 contains no per-mechanism criterion scores. It should be flagged as toolbox guidance, not D5.2 content.

---

## 7. Stakeholder ranking and the Elliott 10+1 tenets

The plan conflates **two instruments**.

### 7.1 Intervention prioritization ranking

- **Arctic:** "on a scale from -5 to +5, reflecting their perceived importance" (L1068–1070; also L807–810).
  - Mentimeter workshop, 6 Nov 2023, Iceland, with WGINOR. 17 participants (11 stakeholders + 6 scientists).
  - 14 candidate interventions in 5 groups (L1406–1433).
  - Results are in **Annex 3** (L9258), which contains **images only** (pages 208–211).
- **Macaronesia:** Mentimeter ranking on a **1–4 scale** (1 = low importance to 4 = high importance) (Figure A7.1, L10181–10185). It ranked by importance, feasibility and long-term impact.
  - Top-ranked: expanding/enhancing MPAs (L10169).
  - The figure is an image.
  - A separate migratory-species survey had six workshops, n=58: 86.2% / 63.8% / 83% / 70% (L3848–3856).

### 7.2 Tenet assessment

- Labelled "10+1" in §1.6 (L812–816) and Macaronesia (L3832–3843), but "ten tenets" in the Arctic text (L1103).
- Citations drift: Elliott 2013 (L812), "Elliot, 2013" (L1103, L10186), Elliott 2025 (L3840).
- The 11 tenets are: ecological effectiveness, technological feasibility, economic efficiency, economic viability, social desirability, ethical defensibility, cultural inclusivity, legal permissibility, administrative achievability, communicability, political expediency.
- **Scale:** a 5-point Likert, "Completely Disagree – Neutral – Completely Agree", per tenet, with a guiding question for each (Annex 4 form, L9455–9550). Examples:
  - Ecologically Effective: "contribute to achieving environmental targets…"
  - Administratively Achievable: "administrative processes and transaction costs manageable…"
  - Politically Expedient: "align with the prevailing political climate…"
- **Not −5..+5.** The form numbering has quirks: "3." appears twice and "7." is missing.
- **Procedure:** a paper exercise done only by Arctic DA experts. Each respondent named their top 3 interventions, gave expected positive and negative impacts, policy changes and country challenges, then rated each intervention on the 11 tenets. Results are in Annex 4 (L9266–9969), organised by country (Faroe, Greenland, Iceland).
- **Results exist only as tick marks** (x among five O's) in the form layout, e.g. L9469, L9509, L9542. A per-country × intervention × tenet matrix could be decoded from the column positions, but this must be verified against the PDF.
- **No aggregated results table exists** for any DA. For Macaronesia the text gives only qualitative findings (L10186–10208).

**Implication for plan §4.7:** a workshop module should support:
- (a) an intervention-ranking poll with a configurable scale (−5..+5 or 1–4)
- (b) an 11-tenet 5-point Likert per intervention, using the guiding questions above

The Annex 4 tick marks could be imported later as demonstration data.

---

## 8. Integrable content the plan missed

1. **Intervention typology (§1.3 L650–682, list at L661–667).**
   - 6 management categories: spatial controls, temporal controls, input controls, output controls, remediation, restoration / nature-based solutions.
   - Policy-instrument types: regulatory, incentive, voluntary, knowledge-based.
   - This is a ready vocabulary for classifying **Responses vs Measures** in DAPSIWRM.
2. **Corridor component toolbox (§5.3.4 L4336–4503) and Figure 5 activation matrix.** Component families (governance, spatial scope, fisheries / maritime / tourism sector packages, monitoring/data, compliance credibility, financing/capacity) are activated at increasing strength from S1 to S4. Each can be modelled as a Measure node with an activation level per scenario. This is the generic "same intervention, different ambition" axis. Box 1 (L4296–4333) lists precedents: CMAR, OSPAR–NEAFC, Papahānaumokuākea, Pelagos/PSSA.
3. **Mechanism-to-scenario applicability links.** Arctic Table 9 gives an "applicability under scenarios" column, and Macaronesia Table 22 gives cost bands and indicator-linked success statements. These are better link data than the KB's authored scoring advice.
4. **Displacement/leakage as an explicit cross-criterion risk** (L4778–4780, C_01, F_02, fleet fiches). It maps to a DAPSIWRM pattern: a Measure on Activity A in area X raises Pressure in area Y. Adaptive "lever → early-warning metric → trigger response" tables exist per fiche (e.g. L12550–12580).
5. **Time-horizon layer** (1–3 / 4–7 / 8–15 years, Tables 12 and 23), usable as per-cell timing.
6. **EQ and PI sub-dimensions** (distributional / procedural / recognitional; credibility / manageability / contestation) as sub-prompts in the criterion matrix.
7. **Evidence tags and indicator-role tags** (primary / supporting, plus pathway segment pressure / state / benefit / governance capacity). These map directly onto ISA element types (P / C / GB / R).
8. **Annex 1 DAPSIWRM-typed indicator tables** (Tuscan Table 6, Macaronesia Table 7) and the PIMS stakeholder typology (Table 5). These are usable as DA template seeds and indicator suggestions.
9. **Arctic fisheries economics as a second valuation case:** landings × price × scenario multipliers, with a MSC premium of 10–15% and ex-vessel price at 30–50% of retail. Store the published table values, given the inconsistencies in §3.1.
10. **Cross-DA synthesis (ch. 6, L5723–5882):** lessons on institutional readiness and the limitations of the multi-criteria framework (L5882–5900). Usable as report boilerplate.

---

## 9. Summary of corrections needed

### Plan
- Arctic = 8 mechanisms, Tuscan = 7, total 31.
- Tuscan has no scenarios.
- The ranking scale is −5..+5 for Arctic intervention ranking and 1–4 for Macaronesia; the tenets use a 5-point Likert.
- Macaronesia scenario names were updated in FINAL.
- Criterion label variants: PI = Policy/Political, and PO/FI in the fiches.
- Only 7 of 11 Macaronesia indicators have fiches.

### Roadmap
- Magnitude should be an ordinal scale (incremental / moderate / substantial), not 0–10.
- Redefine the C_01 schema.
- NPV and discounting are a toolbox extension, not from D5.2.
- "S1–S4 load as defaults from the KB": the KB has no scenario data.

### KB
- Rebuild from FINAL Tables 9, 20 and 22.
- Replace mac_01 and mac_02 with toolkit #1 and #8.
- Add arc #7 and #8, and the Tuscan credits and certification mechanisms.
- Drop `POS_density`, the Tuscan S-labels and the §x.x placeholders.
- Fix the arc_01 and arc_03 country lists.
- Add cost band and scenario-applicability fields.
- Bump `source_documents` to FINAL v5.
