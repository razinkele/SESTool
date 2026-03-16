# KB Quality Review Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 68 element misclassifications, 16 governance/SE errors, ~310 orphan elements, and expand keyword/cross-link coverage across the DAPSI(W)R(M) knowledge base.

**Architecture:** All changes are data-only (JSON + R data files). A Python helper script performs bulk edits to `ses_knowledge_db.json` and `country_governance_db.json`, followed by manual R file edits for keyword and connection pattern databases. A validation script verifies all changes after each phase.

**Tech Stack:** Python 3 (json module) for JSON manipulation, R for keyword/pattern files, existing testthat suite for regression testing.

**Spec:** `docs/superpowers/specs/2026-03-16-kb-quality-review-design.md`

---

## Chunk 1: Validation Script + Phase 1 Misclassifications

### Task 1: Create KB validation script

**Files:**
- Create: `scripts/validate_kb.py`

This script is used after every phase to verify KB integrity. It checks: cross-category conflicts, connection flow validity, orphan rates, reversibility vocabulary, temporal_lag format, and confidence distribution.

- [ ] **Step 1: Create validation script**

```python
#!/usr/bin/env python3
"""Validate DAPSI(W)R(M) knowledge base integrity."""
import json, sys
from collections import defaultdict, Counter

def load_kb(path="data/ses_knowledge_db.json"):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def check_cross_category_conflicts(kb):
    """Elements appearing in multiple DAPSI(W)R(M) categories."""
    cats = ["drivers","activities","pressures","states","impacts","welfare","responses"]
    elem_cats = defaultdict(set)
    for ctx_name, ctx in kb["contexts"].items():
        for cat in cats:
            for elem in ctx.get(cat, []):
                elem_cats[elem["name"]].add(cat)
    conflicts = {n: c for n, c in elem_cats.items() if len(c) > 1}
    return conflicts

def check_connection_flows(kb):
    """Verify all connections follow valid DAPSI(W)R(M) flows."""
    valid = {
        ("drivers","activities"), ("activities","pressures"), ("pressures","states"),
        ("states","impacts"), ("impacts","welfare"), ("welfare","drivers"),
        ("responses","activities"), ("responses","pressures"), ("responses","drivers"),
        ("states","states"), ("pressures","pressures"), ("activities","activities"),
    }
    bad = []
    for ctx_name, ctx in kb["contexts"].items():
        for c in ctx.get("connections", []):
            flow = (c["from_type"], c["to_type"])
            if flow not in valid:
                bad.append(f'{ctx_name}: {c["from"]} ({c["from_type"]}) -> {c["to"]} ({c["to_type"]})')
    return bad

def check_orphans(kb):
    """Find elements not used in any connection per context."""
    cats = ["drivers","activities","pressures","states","impacts","welfare","responses"]
    results = {}
    for ctx_name, ctx in kb["contexts"].items():
        all_names = set()
        for cat in cats:
            for elem in ctx.get(cat, []):
                all_names.add(elem["name"])
        connected = set()
        for c in ctx.get("connections", []):
            connected.add(c["from"])
            connected.add(c["to"])
        orphans = all_names - connected
        total = len(all_names)
        results[ctx_name] = {"orphans": len(orphans), "total": total,
                             "rate": len(orphans)/total if total else 0,
                             "names": sorted(orphans)}
    return results

def check_reversibility(kb):
    """Check reversibility vocabulary consistency."""
    terms = Counter()
    for ctx_name, ctx in kb["contexts"].items():
        for c in ctx.get("connections", []):
            if "reversibility" in c:
                terms[c["reversibility"]] += 1
    return terms

def check_temporal_lag(kb):
    """Find non-categorical temporal_lag values."""
    valid_cats = {"immediate", "short-term", "medium-term", "long-term"}
    bad = []
    for ctx_name, ctx in kb["contexts"].items():
        for c in ctx.get("connections", []):
            lag = c.get("temporal_lag")
            if lag is not None and str(lag) not in valid_cats:
                bad.append(f'{ctx_name}: {c["from"]} -> {c["to"]}: temporal_lag={lag}')
    return bad

def check_confidence_distribution(kb):
    """Report confidence score distribution."""
    dist = Counter()
    for ctx_name, ctx in kb["contexts"].items():
        for c in ctx.get("connections", []):
            dist[c.get("confidence", "?")] += 1
    return dist

def main():
    kb = load_kb()
    errors = 0

    # 1. Cross-category conflicts
    conflicts = check_cross_category_conflicts(kb)
    if conflicts:
        print(f"FAIL: {len(conflicts)} cross-category conflicts")
        for n, c in conflicts.items():
            print(f"  {n}: {c}")
        errors += len(conflicts)
    else:
        print("OK: No cross-category conflicts")

    # 2. Connection flows
    bad_flows = check_connection_flows(kb)
    if bad_flows:
        print(f"FAIL: {len(bad_flows)} invalid connection flows")
        for b in bad_flows[:10]:
            print(f"  {b}")
        errors += len(bad_flows)
    else:
        print("OK: All connection flows valid")

    # 3. Orphans
    orphans = check_orphans(kb)
    high_orphan = {k: v for k, v in orphans.items() if v["rate"] > 0.15}
    total_orphans = sum(v["orphans"] for v in orphans.values())
    print(f"INFO: {total_orphans} total orphan elements across {len(orphans)} contexts")
    if high_orphan:
        print(f"WARN: {len(high_orphan)} contexts with >15% orphan rate:")
        for k, v in sorted(high_orphan.items(), key=lambda x: -x[1]["rate"]):
            print(f"  {k}: {v['orphans']}/{v['total']} ({v['rate']:.0%})")

    # 4. Reversibility
    rev_terms = check_reversibility(kb)
    valid_rev = {"reversible", "partially_reversible", "irreversible"}
    bad_rev = {t: c for t, c in rev_terms.items() if t not in valid_rev}
    if bad_rev:
        print(f"WARN: Non-standard reversibility terms: {bad_rev}")
    else:
        print("OK: Reversibility vocabulary standardized")

    # 5. Temporal lag
    bad_lag = check_temporal_lag(kb)
    if bad_lag:
        print(f"WARN: {len(bad_lag)} non-categorical temporal_lag values")
        for b in bad_lag:
            print(f"  {b}")
    else:
        print("OK: All temporal_lag values categorical")

    # 6. Confidence distribution
    conf = check_confidence_distribution(kb)
    total_conn = sum(conf.values())
    print(f"INFO: Confidence distribution (n={total_conn}):")
    for k in sorted(conf.keys()):
        pct = conf[k] / total_conn * 100
        print(f"  {k}: {conf[k]} ({pct:.0f}%)")

    if errors:
        print(f"\nFAILED: {errors} errors found")
        sys.exit(1)
    else:
        print("\nPASSED: All checks OK")

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run validation against current KB to get baseline**

Run: `cd MarineSABRES_SES_Shiny && python scripts/validate_kb.py`

Expected: 0 cross-category conflicts (we fixed the 1 earlier), 0 invalid flows, ~310 orphans, non-standard reversibility terms flagged, 2 numeric temporal_lag values flagged.

- [ ] **Step 3: Commit**

```bash
git add scripts/validate_kb.py
git commit -m "chore: add KB validation script for quality review"
```

---

### Task 2: Fix Pattern A — Activities classified as Drivers (17 elements)

**Files:**
- Modify: `data/ses_knowledge_db.json`

These Driver elements describe human actions, not needs. Fix by renaming to emphasize the underlying demand, or reclassifying to the correct category. Climate/natural process elements get reclassified to Pressures. State-like elements get reclassified to States.

- [ ] **Step 1: Write Python fix script for Pattern A**

Create `scripts/fix_pattern_a.py` that:
1. Renames activity-phrased drivers to demand-phrased drivers
2. Moves climate-process drivers to pressures (adding replacement driver if needed)
3. Moves ecological-state drivers to states (adding replacement driver if needed)
4. Updates all connection `from`/`to` and `from_type`/`to_type` references

The script must handle:
- Renaming elements in both element lists and connection references
- Moving elements between categories (remove from old, add to new)
- Adding replacement drivers when an element is moved out of drivers
- Updating connection types when an element changes category

- [ ] **Step 2: Run fix script**

Run: `python scripts/fix_pattern_a.py`

- [ ] **Step 3: Run validation**

Run: `python scripts/validate_kb.py`
Expected: 0 cross-category conflicts, 0 invalid flows

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/fix_pattern_a.py
git commit -m "fix(kb): reclassify 17 activity/process elements from Drivers (Pattern A)"
```

---

### Task 3: Fix Pattern B — States classified as Pressures (23 elements)

**Files:**
- Modify: `data/ses_knowledge_db.json`

Invasive species presence and environmental conditions are ecosystem states, not pressure mechanisms. Move from pressures to states, merging near-duplicates (Crown-of-thorns x2, Sargassum x2). Update all connection references.

- [ ] **Step 1: Write Python fix script for Pattern B**

Create `scripts/fix_pattern_b.py` that:
1. Moves 23 elements from pressures to states in their respective contexts
2. Merges near-duplicates (keep canonical name, update connections pointing to alternate name)
3. Updates all connection `from_type`/`to_type` references
4. Verifies no P→S connections become S→S (which is valid) or S→S→S chains

- [ ] **Step 2: Run fix script**

Run: `python scripts/fix_pattern_b.py`

- [ ] **Step 3: Run validation**

Run: `python scripts/validate_kb.py`
Expected: 0 cross-category conflicts, 0 invalid flows

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/fix_pattern_b.py
git commit -m "fix(kb): reclassify 23 state/condition elements from Pressures (Pattern B)"
```

---

### Task 4: Fix Patterns C, D, E — Impacts↔Welfare and Activities↔Pressures (26 elements)

**Files:**
- Modify: `data/ses_knowledge_db.json`

Pattern C: Move 12 welfare items from impacts to welfare (shipping, energy, aquaculture outputs) + 2 to states.
Pattern D: Move 7 non-activities from activities to pressures (natural processes, legacy contamination).
Pattern E: Move 7 ecosystem services from welfare to impacts (carbon regulation, conservation value).

- [ ] **Step 1: Write Python fix script for Patterns C/D/E**

Create `scripts/fix_patterns_cde.py` that handles all three patterns:
1. Pattern C: Move 12 elements from impacts to welfare, 2 to states. Merge near-duplicate (Navigation/Port).
2. Pattern D: Move 7 elements from activities to pressures.
3. Pattern E: Move 7 elements from welfare to impacts.
4. Update all connection references for each moved element.

- [ ] **Step 2: Run fix script**

Run: `python scripts/fix_patterns_cde.py`

- [ ] **Step 3: Run validation**

Run: `python scripts/validate_kb.py`
Expected: 0 cross-category conflicts, 0 invalid flows

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/fix_patterns_cde.py
git commit -m "fix(kb): reclassify 26 elements across Impacts/Welfare/Activities (Patterns C/D/E)"
```

---

### Task 5: Fix Governance/SE misclassifications (16 elements)

**Files:**
- Modify: `data/country_governance_db.json`

Fix EU governance drivers (→ Responses), high-income SE drivers (Activities → proper Drivers), upper-middle SE drivers (Activities → proper Drivers), and miscellaneous welfare reclassifications.

- [ ] **Step 1: Write Python fix script for governance DB**

Create `scripts/fix_governance.py` that:
1. EU group: Move 4 drivers to responses, move 1 welfare to responses, rephrase 1 welfare
2. High-income SE: Replace 5 activity-drivers with need/demand phrasing, move 1 welfare to responses
3. Upper-middle SE: Replace all 4 activity-drivers with need/demand phrasing
4. African coastal: Fix "Artisanal fishing as major employment sector" → "Food security and livelihood needs from artisanal fishing"
5. Asia-Pacific: Fix both drivers from activities to demands
6. Lower-middle SE: Fix "Foreign fishing fleet access agreements" → "Government revenue needs from marine resource licensing"

- [ ] **Step 2: Run fix script**

Run: `python scripts/fix_governance.py`

- [ ] **Step 3: Verify structure**

Run: `python -c "import json; db=json.load(open('data/country_governance_db.json')); [print(f'{g}: D={len(db[\"governance_elements\"][g].get(\"drivers\",[]))}, R={len(db[\"governance_elements\"][g].get(\"responses\",[]))}, W={len(db[\"governance_elements\"][g].get(\"welfare\",[]))}') for g in db['governance_elements']]"`

- [ ] **Step 4: Commit**

```bash
git add data/country_governance_db.json scripts/fix_governance.py
git commit -m "fix(kb): reclassify 16 governance/SE elements in country_governance_db"
```

---

### Task 6: Fix baltic_open_coast missing A→P connections

**Files:**
- Modify: `data/ses_knowledge_db.json`

This context has no Activity→Pressure connections, breaking the DAPSI(W)R(M) causal chain.

- [ ] **Step 1: Inspect baltic_open_coast activities and pressures**

Run: `python -c "import json; kb=json.load(open('data/ses_knowledge_db.json')); ctx=kb['contexts']['baltic_open_coast']; print('Activities:'); [print(f'  {a[\"name\"]}') for a in ctx['activities']]; print('Pressures:'); [print(f'  {p[\"name\"]}') for p in ctx['pressures']]"`

- [ ] **Step 2: Add 3-4 A→P connections based on existing elements**

Write a Python script `scripts/fix_baltic_open_coast.py` that adds scientifically appropriate Activity→Pressure connections based on the elements present.

- [ ] **Step 3: Run validation**

Run: `python scripts/validate_kb.py`
Expected: 0 invalid flows, baltic_open_coast chain now complete

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/fix_baltic_open_coast.py
git commit -m "fix(kb): add missing A→P connections in baltic_open_coast context"
```

---

## Chunk 2: Phase 2 — Completeness Gaps

### Task 7: Fill empty governance categories

**Files:**
- Modify: `data/country_governance_db.json`

Add missing drivers and welfare elements for governance groups that have empty arrays.

- [ ] **Step 1: Write Python script to add governance elements**

Create `scripts/fill_governance_gaps.py` that adds:

**non_eu_european** (GB, NO, IS, TR, etc.):
- Drivers: "Post-Brexit fisheries sovereignty and quota access", "Petroleum export revenue and energy transition", "Arctic resource access and Northern Sea Route development", "Coastal tourism and recreation demand"
- Welfare: "Fishing community livelihoods outside CFP framework", "Coastal community resilience to climate change", "Maritime industry employment and port revenue"

**latin_american** (BR, MX, CO, CL, etc.):
- Drivers: "Coastal urbanization and population growth pressure", "Artisanal fishing and food security demand", "Export fisheries and aquaculture market demand", "Coastal tourism development demand"
- Welfare: "Artisanal fisher household food security", "Coastal community displacement from development", "Tourism-dependent community livelihoods", "Marine pollution health impacts on coastal populations"

**african_coastal** (add welfare only):
- Welfare: "Artisanal fisher income and food access", "Coastal community vulnerability to storm damage", "Marine protein contribution to child nutrition", "Fishing community cultural identity and traditions", "Public health impacts from marine pollution"

**asia_pacific** (add welfare only):
- Welfare: "Aquaculture worker livelihoods and working conditions", "Coastal community displacement from sea level rise", "Small-scale fisher income stability", "Maritime cultural heritage preservation"

- [ ] **Step 2: Run fill script**

Run: `python scripts/fill_governance_gaps.py`

- [ ] **Step 3: Verify all groups now have entries**

Run: `python -c "import json; db=json.load(open('data/country_governance_db.json')); [print(f'{g}: D={len(db[\"governance_elements\"][g].get(\"drivers\",[]))}, W={len(db[\"governance_elements\"][g].get(\"welfare\",[]))}') for g in db['governance_elements']]"`

Expected: All groups show D≥2, W≥2

- [ ] **Step 4: Commit**

```bash
git add data/country_governance_db.json scripts/fill_governance_gaps.py
git commit -m "feat(kb): add missing drivers and welfare for 4 governance groups"
```

---

### Task 8: Add missing regional conventions

**Files:**
- Modify: `data/country_governance_db.json`

Add SPREP/Noumea Convention (Pacific) and Abidjan Convention (West Africa), plus update affected country records.

- [ ] **Step 1: Write Python script to add conventions**

Create `scripts/add_conventions.py` that adds:

**SPREP/Noumea Convention:**
```json
{
  "name": "sprep",
  "full_name": "Noumea Convention (SPREP) for Protection of the Natural Resources and Environment of the South Pacific Region",
  "member_codes": ["AU","NZ","FJ","WS","TO","KI","MH","PW","PG","SB","VU","FM","NR","TV"],
  "responses": [
    "SPREP Strategic Plan for biodiversity and ecosystem management",
    "Pacific Islands Regional Marine Species Programme",
    "Pacific Regional Environment Programme waste management",
    "Noumea Convention pollution prevention protocols",
    "Pacific Islands Framework for Nature Conservation"
  ]
}
```

**Abidjan Convention:**
```json
{
  "name": "abidjan",
  "full_name": "Abidjan Convention for Cooperation in the Protection, Management and Development of the Marine and Coastal Environment of the Atlantic Coast of the West, Central and Southern Africa Region",
  "member_codes": ["SN","GM","GW","MR","CI","GH","TG","BJ","NG","CM","GA","CG","CD","AO","NA","ZA"],
  "responses": [
    "Abidjan Convention Protocol on sustainable mangrove management",
    "West African Regional Fisheries Commission (CSRP) measures",
    "Abidjan Convention ICZM Protocol for coastal zone management",
    "Large Marine Ecosystem programmes (Guinea Current, Canary Current)",
    "Abidjan Convention Protocol on environmental standards from seabed activities"
  ]
}
```

Also update affected country records to include convention references.

- [ ] **Step 2: Run script**

Run: `python scripts/add_conventions.py`

- [ ] **Step 3: Verify conventions added**

Run: `python -c "import json; db=json.load(open('data/country_governance_db.json')); print([c['name'] for c in db['regional_conventions']])"`

Expected: List includes "sprep" and "abidjan"

- [ ] **Step 4: Commit**

```bash
git add data/country_governance_db.json scripts/add_conventions.py
git commit -m "feat(kb): add SPREP/Noumea and Abidjan regional conventions"
```

---

### Task 9: Reduce orphan elements

**Files:**
- Modify: `data/ses_knowledge_db.json`

For each context, either add connections for orphan elements or remove elements that don't fit. Target: orphan rate ≤15%.

- [ ] **Step 1: Generate orphan report**

Run: `python -c "import json; kb=json.load(open('data/ses_knowledge_db.json')); ...` (use the orphan check from validate_kb.py) to identify which elements are orphaned per context.

- [ ] **Step 2: Write Python script to add connections for orphans**

Create `scripts/reduce_orphans.py` that, for each context:
1. Identifies all orphan elements
2. For orphan drivers: adds D→A connection to an existing activity
3. For orphan activities: adds A→P connection to an existing pressure
4. For orphan pressures: adds P→S connection to an existing state
5. For orphan states: adds S→I connection to an existing impact
6. For orphan impacts: adds I→W connection to an existing welfare
7. For orphan welfare: adds W→D connection to an existing driver
8. For orphan responses: adds R→P or R→A connection

Uses reasonable defaults: polarity="+"/"-" based on category pair, strength="medium", confidence=3, temporal_lag="medium-term", reversibility="partially_reversible".

- [ ] **Step 3: Run script**

Run: `python scripts/reduce_orphans.py`

- [ ] **Step 4: Run validation**

Run: `python scripts/validate_kb.py`
Expected: All contexts have orphan rate ≤15%

- [ ] **Step 5: Commit**

```bash
git add data/ses_knowledge_db.json scripts/reduce_orphans.py
git commit -m "feat(kb): add connections for orphan elements, reduce orphan rate to <15%"
```

---

## Chunk 3: Phase 3 — Quality Improvements

### Task 10: Standardize reversibility and temporal_lag

**Files:**
- Modify: `data/ses_knowledge_db.json`

- [ ] **Step 1: Write Python script to standardize vocabulary**

Create `scripts/standardize_vocab.py` that:
1. Replaces "poorly_reversible" → "partially_reversible"
2. Replaces "slowly_reversible" → "partially_reversible"
3. Replaces "moderate" → "partially_reversible"
4. Replaces "slow" → "partially_reversible"
5. Converts numeric temporal_lag values to categorical (use derive_delay_category logic: <0.08yr → immediate, <0.5yr → short-term, <3yr → medium-term, ≥3yr → long-term)

- [ ] **Step 2: Run script**

Run: `python scripts/standardize_vocab.py`

- [ ] **Step 3: Run validation**

Run: `python scripts/validate_kb.py`
Expected: "OK: Reversibility vocabulary standardized", "OK: All temporal_lag values categorical"

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/standardize_vocab.py
git commit -m "fix(kb): standardize reversibility vocabulary and temporal_lag values"
```

---

### Task 11: Expand cross-ecosystem links

**Files:**
- Modify: `data/ses_knowledge_db.json`

- [ ] **Step 1: Write Python script to add cross-links**

Create `scripts/expand_cross_links.py` that:
1. Removes 2 duplicate cross-links (caribbean_seagrass→caribbean_coral_reef duplicate)
2. Adds ~15-20 new cross-ecosystem links for missing pairs:
   - north_sea_tidal_flat ↔ north_sea_offshore (nursery function)
   - north_sea_tidal_flat ↔ north_sea_estuary (adjacent habitats)
   - north_sea_estuary ↔ north_sea_offshore (nutrient/larvae export)
   - mediterranean_seagrass ↔ mediterranean_rocky_shore (leaf litter subsidy)
   - mediterranean_open_coast ↔ mediterranean_rocky_shore (larval exchange)
   - baltic_lagoon ↔ baltic_estuary (transitional waters)
   - arctic_fjord ↔ arctic_sea_ice (ice dynamics)
   - indian_ocean_coral_reef ↔ indian_ocean_island (reef protection)
   - And others as identified in the audit

Each link includes: from_context, from_element, to_context, to_element, polarity, strength, rationale, temporal_lag, reversibility.

- [ ] **Step 2: Run script**

Run: `python scripts/expand_cross_links.py`

- [ ] **Step 3: Verify count**

Run: `python -c "import json; kb=json.load(open('data/ses_knowledge_db.json')); print(f'Cross-links: {len(kb[\"cross_ecosystem_links\"])}')`"

Expected: ≥25

- [ ] **Step 4: Commit**

```bash
git add data/ses_knowledge_db.json scripts/expand_cross_links.py
git commit -m "feat(kb): expand cross-ecosystem links from 11 to 25+ pairs"
```

---

### Task 12: Improve generic fallback

**Files:**
- Modify: `data/ses_knowledge_db.json`

- [ ] **Step 1: Edit generic_fallback section**

Add to impacts: "Carbon sequestration and climate regulation" (0.8), "Water purification and nutrient cycling" (0.75), "Nursery habitat for commercial species" (0.7).

Add to welfare: "Coastal community food security" (0.85), "Cultural identity and sense of place" (0.7), "Coastal property protection value" (0.65).

Differentiate existing relevance scores to range 0.5-0.9 instead of uniform 0.7-0.8.

- [ ] **Step 2: Run validation**

Run: `python scripts/validate_kb.py`

- [ ] **Step 3: Commit**

```bash
git add data/ses_knowledge_db.json
git commit -m "feat(kb): expand and differentiate generic fallback elements"
```

---

## Chunk 4: Phase 4 — Keyword & Pattern DB

### Task 13: Expand keyword database

**Files:**
- Modify: `data/dapsiwrm_element_keywords.R`

- [ ] **Step 1: Add missing keyword stems**

For each category, add the missing keyword stems identified in the audit. Key additions:

**Drivers:** "agricultural", "vulnerability", "blue economy", "diversification", "intensification"

**Activities:** "harvesting", "anchoring", "mooring", "remediation", "monitoring", "nourishment", "seismic", "cultivation"

**Pressures (worst at 52%):** "altered", "anoxic", "anoxia", "antifouling", "leaching", "bleaching", "heatwave", "accumulation", "overgrazing", "trampling", "sewage", "warming", "blocked", "migration barrier"

**States:** "migration success", "sediment budget", "clarity", "salinity gradient", "filamentous", "freshwater lens", "permafrost"

**Impacts:** "amenity", "blue carbon", "endemism", "pharmaceutical", "ecotourism", "filtration", "flyway", "food web"

**Welfare:** "safety", "flood damage", "avoided costs", "decommissioning", "drinking water", "pride", "viability"

**Responses:** "buffer zone", "moratorium", "treaty", "convention", "clean-up", "pump-out", "community-based", "co-management", "nourishment", "decommissioning", "early warning"

- [ ] **Step 2: Add context boosts for missing contexts**

Add `context_boost` entries for: aquaculture, shipping, coastal_development, pollution, climate, invasive_species, arctic.

- [ ] **Step 3: Commit**

```bash
git add data/dapsiwrm_element_keywords.R
git commit -m "feat(kb): expand keyword database with ~100 missing stems and 7 context boosts"
```

---

### Task 14: Expand R Connection KB patterns

**Files:**
- Modify: `data/ses_connection_knowledge_base.R`

- [ ] **Step 1: Add feedback loop patterns**

Add 5-10 patterns for thin flow types:
- W→D: welfare outcomes reinforcing/dampening drivers (5 patterns)
- W→R: welfare outcomes triggering policy responses (3 patterns)
- R→D: responses modifying underlying drivers (3 patterns)

- [ ] **Step 2: Add missing pathway patterns**

Add patterns for:
- Mineral/aggregate extraction pathway (D→A→P→S)
- Offshore wind energy pathway (D→A→P→S→I→W)
- Invasive species management pathway (R→P, R→A)
- Arctic-specific patterns (ice, permafrost, polar species)

- [ ] **Step 3: Widen probability range**

Review existing patterns. Downgrade speculative connections from 0.70-0.75 to 0.40-0.55. Keep well-evidenced connections at 0.85-0.95.

- [ ] **Step 4: Commit**

```bash
git add data/ses_connection_knowledge_base.R
git commit -m "feat(kb): expand R connection patterns with feedback loops and new pathways"
```

---

## Chunk 5: Phase 5 — Final Validation & Cleanup

### Task 15: Run full validation suite

**Files:**
- Read: all modified data files
- Run: validation script + testthat suite

- [ ] **Step 1: Run KB validation**

Run: `python scripts/validate_kb.py`

Expected output:
```
OK: No cross-category conflicts
OK: All connection flows valid
INFO: ≤X total orphan elements (≤15% per context)
OK: Reversibility vocabulary standardized
OK: All temporal_lag values categorical
INFO: Confidence distribution (bell-curved)
PASSED: All checks OK
```

- [ ] **Step 2: Run R test suite**

Run: `cd MarineSABRES_SES_Shiny && Rscript -e "testthat::test_file('tests/testthat/test-old-excel-backward-compat.R')"`

Expected: All tests pass (KB changes don't affect Excel import logic)

Run: `Rscript -e "testthat::test_file('tests/testthat/test-excel-import-helpers.R')"`

Expected: All tests pass

- [ ] **Step 3: Run quick smoke test on KB loader**

Run: `Rscript -e "source('functions/utils.R'); source('constants.R'); source('functions/ses_knowledge_db_loader.R'); load_ses_knowledge_db('data/ses_knowledge_db.json'); cat('Contexts:', length(get_available_contexts()), '\n')"`

Expected: No errors, contexts count = 30

- [ ] **Step 4: Cleanup fix scripts**

Move all `scripts/fix_*.py` and `scripts/fill_*.py` and `scripts/add_*.py` and `scripts/reduce_*.py` and `scripts/standardize_*.py` and `scripts/expand_*.py` to `scripts/kb_audit/` for archival.

- [ ] **Step 5: Update version and commit**

```bash
git add -A
git commit -m "chore(kb): complete KB quality review — all validation checks pass"
```

---

## Summary

| Phase | Tasks | Elements Fixed | Commits |
|-------|-------|---------------|---------|
| 1: Misclassifications | Tasks 1-6 | 68 + 16 + A→P chain | 6 |
| 2: Completeness | Tasks 7-9 | ~30 governance + 2 conventions + ~200 connections | 3 |
| 3: Quality | Tasks 10-12 | Vocab + cross-links + fallback | 3 |
| 4: Keywords | Tasks 13-14 | ~100 keywords + ~20 patterns | 2 |
| 5: Validation | Task 15 | Verify all | 1 |
| **Total** | **15 tasks** | **~400 data changes** | **15 commits** |
