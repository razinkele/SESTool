---
name: kb-audit
description: Audit knowledge base integrity — find orphan nodes, cross-region data leaks, missing habitats, invalid DAPSIWRM connections, and connection rule violations
disable-model-invocation: true
---

# Knowledge Base Integrity Audit

Audit the MarineSABRES SES Toolbox knowledge base for data quality issues.

## Data Sources

The KB consists of:
- `data/ses_knowledge_db.json` — main knowledge database
- `data/ses_connection_knowledge_base.R` — connection rules and patterns
- `data/*_SES_Template.json` — regional SES templates (Fisheries, Tourism, Aquaculture, etc.)
- `data/country_governance_db.json` — governance data

## Workflow

### 1. Load and parse KB data

Read `data/ses_knowledge_db.json` and all `*_SES_Template.json` files. Parse their structure.

### 2. Check for orphan nodes

For each template, verify every element (node) has at least one connection:
- Incoming OR outgoing connection required
- Report orphans grouped by template and element type (D, A, P, C, ES, GB, HW, R, M)

```
Orphan: "Coral bleaching" (type: P) in Caribbean_SES_Template — no incoming or outgoing connections
```

### 3. Validate DAPSIWRM connection rules

Check all connections against the valid transition rules in `DAPSIWRM_FRAMEWORK_RULES.md`:

**Valid forward connections**: D→A, A→P, P→C, C→ES, ES→GB, GB→HW, HW→D
**Valid response connections**: GB→R, R→D, R→A, R→P, R→C, R→R, M→R
**Valid special connections**: D→GB (direct shortcut), C→C (state interactions)

Flag any connection that doesn't match a valid pattern:
```
Invalid: A→ES in Fisheries_SES_Template — Activities cannot connect directly to Ecosystem Services
```

### 4. Check polarity consistency

For each connection, verify polarity matches expected direction:
- D→A should be reinforcing (+)
- A→P should be reinforcing (+)
- P→C should typically be opposing (-)
- R→A should typically be opposing (-)

Flag unexpected polarities:
```
Unusual polarity: P→C "Nutrient enrichment" → "Water quality" is (+) — expected (-). Verify this is intentional.
```

### 5. Cross-region data leak check

This was a past bug: North Sea queries returning Black Sea data.

For each template, verify:
- All elements reference the correct region/sub-region
- No element names or IDs appear in a template they don't belong to
- Connection source and target both exist in the same template

```
Cross-region leak: "Black Sea currents" (id: bs_c_01) found in North_Sea template connections
```

### 6. Missing habitat patterns

Check that each regional template includes the expected habitat/ecosystem types for its geography:
- **Baltic Sea**: Brackish water, seagrass beds, coastal wetlands
- **Mediterranean**: Posidonia meadows, rocky shores, deep sea
- **Caribbean**: Coral reefs, mangroves, seagrass
- **Macaronesia**: Volcanic shores, deep ocean, cetacean habitats
- **North Sea**: Sandy shores, mudflats, cold-water reefs

Flag templates missing expected habitat types for their region.

### 7. Completeness check

For each template, verify the primary causal chain is complete:
- At least 1 element of each type: D, A, P, C, ES, GB
- At least 1 R or M element (response/measure)
- Primary chain D→A→P→C→ES→GB has at least one complete path
- Feedback loop exists (HW→D or GB→D)

### 8. Report

Output a structured report:

```
## KB Integrity Audit Report

### Orphan Nodes
- [template]: [count] orphans
  - [element name] (type: [X])

### Invalid Connections
- [count] connections violating DAPSIWRM rules
  - [source] → [target] in [template]

### Polarity Warnings
- [count] unexpected polarities

### Cross-Region Leaks
- [count] elements in wrong templates

### Missing Habitats
- [template]: missing [habitat types]

### Completeness
- [template]: [missing element types or chain gaps]

### Summary
- Templates checked: N
- Total elements: N
- Total connections: N
- Orphans: N | Invalid connections: N | Cross-region: N | Incomplete: N
```

## Rules

- This is a READ-ONLY audit — do NOT modify any data files
- Report findings for the user to review and decide on fixes
- If a template file can't be parsed, report the parse error and continue with others
- Group issues by severity: Critical (invalid connections, cross-region), Warning (orphans, polarity), Info (missing habitats, completeness)
