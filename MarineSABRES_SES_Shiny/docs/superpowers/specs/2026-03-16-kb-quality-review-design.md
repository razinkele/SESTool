# Knowledge Base Quality Review — Design Spec

**Date**: 2026-03-16
**Version**: 1.0
**Status**: Approved
**Scope**: Full quality review of DAPSI(W)R(M) Knowledge Base, governance DB, keyword DB, and cross-ecosystem links

---

## 1. Problem Statement

A deep audit of the MarineSABRES DAPSI(W)R(M) knowledge base revealed 68 element misclassifications (6.3% error rate), 16 governance/SE misclassifications, ~310 orphan elements, keyword coverage of only 52-66%, and sparse cross-ecosystem links. While the connection network is structurally sound (0 flow errors, 0 polarity errors, 0 duplicates), the element classification and completeness issues degrade suggestion quality for users.

## 2. Audit Findings Summary

### 2.1 Element Misclassifications (68 total across ses_knowledge_db.json)

**Pattern A — Activities classified as Drivers (17 elements):**
These describe human actions, not root needs. Per the Word doc definition, Drivers are "basic human needs which require activities."

| Element | Context(s) | Fix |
|---------|-----------|-----|
| Agricultural intensification in catchment | baltic_lagoon | Rename to "Agricultural production demand in catchment" |
| Agricultural intensification in surrounding plains | mediterranean_lagoon | Rename to "Agricultural production demand" |
| Agricultural production in Danube basin | black_sea_open_coast | Rename to "Food production demand from Danube basin" |
| Climate change and ocean warming | multiple | Reclassify to Pressure |
| Climate change impacts | generic_fallback | Reclassify to Pressure |
| Climate warming of shallow Baltic bays | baltic_archipelago | Reclassify to Pressure |
| Climate-driven Arctic warming and glacial retreat | arctic_fjord | Reclassify to Pressure |
| Coastal population growth and urbanisation | multiple | Rename to "Coastal population growth and housing demand" |
| Coastal urbanisation pressure | mediterranean_open_coast | Rename to "Coastal housing and infrastructure demand" |
| Coastal urbanisation and second-home demand | baltic_archipelago | Keep (demand framing is acceptable) |
| Green turtle population recovery | caribbean_seagrass | Reclassify to State |
| Seal population recovery concerns | baltic_open_coast | Reclassify to State |
| Watershed land-use intensification | atlantic_estuary | Rename to "Agricultural land-use demand in watershed" |
| Coastal resort and marina development | mediterranean_rocky_shore | Rename to "Coastal resort and marina demand" |
| Coastal tourism and resort development | caribbean_coral_reef | Rename to "Coastal tourism demand" |
| Coastal development for resort infrastructure | indian_ocean_coral_reef | Rename to "Tourism infrastructure demand" |
| Industrial and urban development along coast | atlantic_open_coast | Rename to "Industrial and urban land demand on coast" |

**Pattern B — States classified as Pressures (23 elements):**
These describe ecosystem conditions/states, not mechanisms of change. Per the framework, Pressures are "mechanisms of change" while States are "measurable ecosystem conditions."

Invasive species presence (should be States):
- Crown-of-thorns starfish (Acanthaster planci) outbreaks
- Crown-of-thorns starfish (Acanthaster) outbreaks (near-duplicate)
- Invasive comb jelly (Mnemiopsis leidyi)
- Invasive round goby altering nearshore food webs
- Invasive Manila clam (Ruditapes philippinarum) spread
- Chinese mitten crab and Pacific oyster invasion
- Round goby and Chinese mitten crab invasion
- Pacific oyster (Magallana gigas) reef expansion displacing native beds
- Invasive Caulerpa cylindracea displacement of native habitats
- Invasive algae colonisation of volcanic substrates
- Invasive tropical species establishment
- Invasive species threatening endemic island biota

Environmental conditions (should be States):
- Deep-water hypoxia (dead zones)
- Hypoxia and hydrogen sulphide in deep waters
- Stony coral tissue loss disease (SCTLD)
- Sargassum inundation events
- Sargassum mass inundation events (near-duplicate)
- Overgrazing by recovering green turtle populations
- Grey seal predation on coastal fish stocks and gear damage
- Coastal erosion and sediment deficit
- Coastal erosion of limestone and glacial till shores

**Note on invasive species:** The *introduction vector* (ballast water discharge, aquaculture escape) is the Pressure. The *established population* is a State. The KB should keep the introduction mechanism as Pressure and move the species-presence elements to States.

**Pattern C — Welfare items classified as Impacts (12 elements):**
These are human economic/infrastructure outputs, not ecosystem services.

| Element | Fix |
|---------|-----|
| Tuna export revenue and processing employment | Move to Welfare |
| Renewable energy generation capacity | Move to Welfare |
| Renewable energy generation from offshore wind | Move to Welfare |
| Shipping and trade route services | Move to Welfare |
| Transatlantic shipping corridor services | Move to Welfare |
| Shipping route provision | Move to Welfare |
| Shipping route accessibility in summer | Move to Welfare |
| Port and navigation accessibility | Move to Welfare |
| Navigation and port accessibility | Move to Welfare (near-dup of above) |
| Seabird population sustainability | Move to State |
| Coastal food web integrity | Move to State |
| Shellfish aquaculture production | Move to Welfare |

**Pattern D — Non-activities classified as Activities (7 elements):**

| Element | Fix |
|---------|-----|
| Hurricane formation and intensification | Move to Pressure |
| Green turtle foraging on seagrass beds | Move to Pressure (biological) |
| Global greenhouse gas emissions | Move to Pressure |
| Agricultural and urban watershed runoff | Move to Pressure |
| Danube-origin nutrient and pollutant loading | Move to Pressure |
| Military munition dumping legacy | Move to Pressure |
| Coastal farmland drainage to nearshore waters | Move to Pressure (borderline) |

**Pattern E — Ecosystem services classified as Welfare (7 elements):**

| Element | Fix |
|---------|-----|
| Climate mitigation value of blue carbon storage | Move to Impacts |
| Climate regulation benefits (carbon sink) | Move to Impacts |
| Global climate stability benefit | Move to Impacts |
| Seabird conservation value (public concern) | Move to Impacts |
| Shorebird conservation as international heritage value | Move to Impacts |
| Marine scientific knowledge advancement | Move to Impacts (cultural ES) |
| Scientific and educational value | Move to Impacts (cultural ES) |

### 2.2 Governance/SE Misclassifications (16 total in country_governance_db.json)

**EU governance group (6 issues):**
- Driver "EU Green Deal regulatory compliance pressure" → Response
- Driver "EU farm-to-fork strategy effects on coastal agriculture" → Response
- Driver "EU renewable energy targets driving offshore wind development" → split: Driver "Energy transition demand" + keep Response "EU renewable energy targets"
- Driver "Cohesion Fund investments in coastal infrastructure" → Response
- Welfare "EU structural fund employment in maritime sectors" → Response
- Welfare "Common Agricultural Policy impacts on coastal communities" → rephrase to actual welfare outcome

**High-income SE (6 issues):**
- 5 of 6 drivers are Activities (R&D, development, bioprospecting, industry growth, philanthropy)
- Welfare "Ocean literacy and marine environmental education" → Response

**Upper-middle SE (4 issues):**
- All 4 drivers are Activities (resort development, aquaculture expansion, port expansion, industrialization)

### 2.3 Connection Network (622 connections)

- **0 invalid flow directions** — all follow valid DAPSI(W)R(M) paths
- **0 polarity errors** — all scientifically defensible
- **0 duplicates**
- **~310 orphan elements** — 25-46% per context unconnected
- **1 broken context** — baltic_open_coast missing A→P connections
- **Confidence inflation** — 80% rated 4-5 (should be bell-curved around 3-4)
- **Reversibility vocabulary** — 7 terms used, should be 3 (reversible, partially_reversible, irreversible)
- **2 numeric temporal_lag values** ("0.5") instead of categorical

### 2.4 Keyword Database (dapsiwrm_element_keywords.R)

- **Match rate**: 52-66% across categories (Pressures worst at 52%)
- **Missing ~100 keyword stems** across all categories
- **11 ambiguous cross-category keywords** (population, security, regulation, protection, health, income, livelihood, employment, recreation, heritage, identity)
- **Context boost coverage**: Only 3 of ~10 needed contexts covered per category

### 2.5 Completeness Gaps

**Governance DB:**
- non_eu_european: no Drivers, no Welfare
- latin_american: no Drivers, no Welfare
- african_coastal: no Welfare
- asia_pacific: no Welfare
- Missing conventions: SPREP/Noumea (Pacific, 14 countries), Abidjan (West Africa, 4 countries)

**KB contexts:**
- Impacts and Welfare fixed at 4 elements per context (thin)
- Cross-ecosystem links: 11 unique pairs, ~20 more needed
- Generic fallback: Impacts (3) and Welfare (3) too thin, relevance scores undifferentiated

**R Connection KB:**
- Feedback patterns thin: W→R (3), W→D (3), R→D (2)
- Probability range compressed: 0.70-0.95 (should be 0.3-0.95)
- Missing pathways: mineral extraction, offshore wind, invasive species management, Arctic-specific

## 3. Implementation Plan

### Phase 1: Fix Misclassifications (Priority 1)

**Step 1.1**: Fix 68 element misclassifications in ses_knowledge_db.json
- Reclassify elements per patterns A-E above
- For elements moved between categories: update the element lists AND all connection from_type/to_type references
- For renamed elements: update both element lists and connection from/to fields
- Merge near-duplicates (Crown-of-thorns x2, Sargassum x2, Navigation/Port x2)

**Step 1.2**: Fix 16 governance/SE misclassifications in country_governance_db.json
- Reclassify EU governance drivers/welfare as Responses
- Replace high-income and upper-middle SE Activity-drivers with proper need/demand phrasing
- Fix remaining issues per Section 2.2

**Step 1.3**: Fix baltic_open_coast missing A→P connections
- Add 3-4 Activity→Pressure connections to complete the causal chain

### Phase 2: Fill Completeness Gaps (Priority 2)

**Step 2.1**: Fill empty governance categories
- Add 3-4 drivers + 2-3 welfare for non_eu_european
- Add 3-4 drivers + 3-4 welfare for latin_american
- Add 4-5 welfare for african_coastal
- Add 3-4 welfare for asia_pacific

**Step 2.2**: Add missing regional conventions
- Add SPREP/Noumea Convention with member codes and 4-5 responses
- Add Abidjan Convention with member codes and 4-5 responses
- Add convention references to affected country records

**Step 2.3**: Connect orphan elements
- For each context: add connections for disconnected elements OR remove elements that don't fit the context
- Target: reduce orphan rate from 25-46% to under 15%

### Phase 3: Improve Quality (Priority 3)

**Step 3.1**: Standardize reversibility vocabulary
- Replace "poorly_reversible" and "slowly_reversible" with "partially_reversible"
- Replace "moderate" and "slow" with "partially_reversible"

**Step 3.2**: Fix temporal_lag inconsistencies
- Convert 2 numeric values to categorical strings

**Step 3.3**: Recalibrate confidence scores
- Review connections rated 5 — downgrade speculative ones to 3-4
- Target distribution: ~10% conf=5, ~30% conf=4, ~35% conf=3, ~20% conf=2, ~5% conf=1

**Step 3.4**: Expand Impacts and Welfare elements
- Add 1-3 elements per context to bring Impacts and Welfare to 5-6 each

**Step 3.5**: Expand cross-ecosystem links
- Add ~15-20 missing pairs (North Sea, Mediterranean, Arctic, Indian Ocean)
- Remove 2 duplicate cross-links

**Step 3.6**: Improve generic fallback
- Add 2-3 Impacts and 2-3 Welfare elements
- Differentiate relevance scores (0.5-0.9 range)

### Phase 4: Keyword & Pattern DB (Priority 3)

**Step 4.1**: Expand keyword database
- Add ~100 missing keyword stems identified in audit
- Add disambiguation logic for 11 ambiguous cross-category keywords
- Add context boosts for: aquaculture, shipping, coastal development, pollution, climate, invasive species, Arctic

**Step 4.2**: Expand R Connection KB
- Add 5-10 feedback patterns (W→R, W→D, R→D)
- Add pathways for: mineral extraction, offshore wind, invasive species management, Arctic
- Widen probability range to 0.3-0.95

### Phase 5: Validation (all phases)

**Step 5.1**: Run automated validation after each phase
- 0 cross-category conflicts
- All connection flows valid
- All elements connected (orphan rate < 15%)
- All reversibility terms standardized
- All temporal_lag values categorical

**Step 5.2**: Run existing tests
- `testthat::test_dir("tests/testthat")` — all tests pass
- Specifically: test-excel-import-helpers.R, test-old-excel-backward-compat.R

## 4. Files Modified

| File | Changes |
|------|---------|
| `data/ses_knowledge_db.json` | Element reclassifications, connection updates, orphan resolution, cross-links, fallback expansion |
| `data/country_governance_db.json` | Governance/SE reclassifications, empty category fills, convention additions |
| `data/dapsiwrm_element_keywords.R` | Keyword expansion, disambiguation, context boosts |
| `data/ses_connection_knowledge_base.R` | New patterns, feedback loops, probability recalibration |

## 5. Success Criteria

- Element classification accuracy: ≥99% (from 93.7%)
- Keyword match rate: ≥85% per category (from 52-66%)
- Orphan element rate: ≤15% per context (from 25-46%)
- Cross-ecosystem link pairs: ≥25 (from 11)
- All governance groups have Drivers + Welfare entries
- All connection flows valid, all polarities correct
- Reversibility vocabulary: exactly 3 terms
- Confidence distribution: bell-curved around 3-4
