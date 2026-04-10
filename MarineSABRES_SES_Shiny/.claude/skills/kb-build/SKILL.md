---
name: kb-build
description: Rebuild knowledge base JSON files from source data — parses BibTeX/literature, builds DAPSIWRM elements and connections, validates transitions, reports changes
disable-model-invocation: true
---

# Knowledge Base Builder

Rebuild the SES knowledge base JSON files from their source data.

## Arguments

- `offshore-wind` — Rebuild the offshore wind KB from BibTeX (default)
- `--validate-only` — Skip rebuild, just validate existing KB files
- `--diff` — Show what changed compared to current version

## Available KBs

| KB | Source | Build Script | Output |
|----|--------|-------------|--------|
| Offshore Wind | `.playwright-mcp/export-2026-4-9.bib` (187 papers) | `scripts/build_offshore_wind_kb.py` | `data/ses_knowledge_db_offshore_wind.json` |
| Main KB | Manual curation | N/A (hand-edited) | `data/ses_knowledge_db.json` |

## Workflow

### 1. Rebuild (unless --validate-only)

For offshore-wind:

```bash
micromamba run -n shiny python scripts/build_offshore_wind_kb.py
```

Report:
- Number of papers parsed
- Tag distribution (top 20)
- Elements and connections per context

### 2. Validate DAPSIWRM transitions

For each KB JSON file (`data/ses_knowledge_db*.json`), validate:

**Valid transitions** (matching main KB pattern):
- `drivers->activities`, `activities->pressures`, `pressures->states`
- `states->impacts`, `impacts->welfare`, `welfare->drivers`
- `pressures->pressures`, `states->states` (interactions)
- `responses->activities`, `responses->pressures`, `responses->drivers`, `responses->states` (interventions)

**Check for each context**:
- All connection endpoints exist in the element lists (no dangling references)
- Complete causal chain: D→A→P→C→ES→W→D present
- Response interventions target both activities and pressures
- No invalid transition types

### 3. Check orphans

Report elements with no connections (neither from nor to). Orphans are acceptable as enrichment elements, but flag any that seem like they should be connected.

### 4. Diff (if --diff or after rebuild)

Compare the newly built KB against the existing file:

```bash
git diff --stat data/ses_knowledge_db_offshore_wind.json
```

Report added/removed elements and connections.

### 5. Report

```
## KB Build Report

### Build
- Papers parsed: N
- Contexts: [list]

### Validation
| Context | Elements | Connections | Chain | Transitions | Orphans |
|---------|----------|-------------|-------|-------------|---------|
| name    | N        | N           | OK/FAIL | OK/FAIL   | N       |

### Issues
- [list any invalid transitions, missing chains, or dangling references]

### Diff (vs previous)
- Elements added: N, removed: N
- Connections added: N, removed: N
```

## Rules

- The BibTeX file must exist at the expected path — if not, report and stop
- micromamba environment `shiny` must be available — if not, report and stop
- Do NOT edit KB JSON files directly — always rebuild from the script
- Validation should work on both the offshore wind KB and the main KB
