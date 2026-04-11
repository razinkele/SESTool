---
name: scientific-validation
description: Validate scientific claims, framework rules, and ecological relationships in SES code and knowledge bases against peer-reviewed literature. Use this skill whenever code touches DAPSIWRM transition rules, loop detection, knowledge base connections, element classification, polarity logic, or any ecological/marine science assertion. Also use when the user asks to verify scientific accuracy, check references, validate framework compliance, or review whether KB entries match current literature. Triggers on phrases like "is this scientifically correct", "check the literature", "validate the framework", "are these transitions valid", "review the KB science", or any mention of DAPSIWRM rules vs actual ecological pathways.
---

# Scientific Validation

Validate scientific claims in code and knowledge bases against peer-reviewed literature using a two-source strategy: **scite MCP** for peer-reviewed citations and **Claude WebSearch** for grey literature, reports, and policy documents.

## Why This Skill Exists

The MarineSABRES SES Toolbox encodes ecological relationships as code — transition rules, polarity defaults, connection strengths. These are scientific claims that can become stale or incorrect. During a recent review, we discovered the code's DAPSIWRM transition validator was missing 5 transitions that both the framework document and the knowledge base (built from 187 peer-reviewed papers) explicitly define. Silent filtering removed valid ecological feedback loops. This skill prevents such gaps by providing a systematic process for validating scientific claims against literature.

## Prerequisites

### Scite MCP Server

The scite MCP provides access to 1.4B+ scientific citations with Smart Citation classification (supporting/contrasting/mentioning). Connect it before using this skill:

**If not configured**, add to Claude Code settings:
```bash
claude mcp add scite --url https://api.scite.ai/mcp
```

Or add manually to `.claude/settings.json`:
```json
{
  "mcpServers": {
    "scite": {
      "url": "https://api.scite.ai/mcp"
    }
  }
}
```

**If scite MCP is unavailable**, fall back to WebSearch with `allowed_domains: ["scholar.google.com", "pubmed.ncbi.nlm.nih.gov", "doi.org", "scopus.com"]`.

### Grey Literature via WebSearch

Use Claude's built-in WebSearch tool for:
- ICES/HELCOM/OSPAR technical reports and advice
- EU Marine Strategy Framework Directive (MSFD) guidance
- FAO fisheries reports
- IPCC/IPBES assessment chapters
- EMODnet data products and technical documents
- National marine monitoring programme reports

Grey literature fills gaps where peer-reviewed papers lag behind policy or where regional specificity matters (e.g., Baltic Sea eutrophication thresholds, Mediterranean MPA effectiveness).

## Validation Process

### Phase 1: Identify Claims

Read the code or KB entries under review and extract every implicit scientific claim:

```
Claim: "Pressures cannot connect to Pressures"
Source: functions/network_analysis.R:347-384 (is_valid_dapsirwrm_transition)
Type: Framework rule (restrictive)

Claim: "Response → State connections are invalid"
Source: functions/network_analysis.R:347-384
Type: Framework rule (omission)

Claim: "Nutrient enrichment → Cyanobacteria blooms (polarity: +, strength: strong)"
Source: data/ses_knowledge_db.json, baltic_lagoon context
Type: Ecological relationship
```

**Claim types to look for:**
- **Framework rules**: Valid/invalid transition types, polarity defaults, loop classification
- **Ecological relationships**: Cause-effect links, strength, direction, delay
- **Classification decisions**: Which DAPSIWRM category an element belongs to
- **Quantitative assertions**: Thresholds, rates, magnitudes

### Phase 2: Literature Search (Dual-Source)

For each claim, search both sources in parallel:

#### Scite MCP (peer-reviewed)

Use `search_literature` with targeted queries:

```
# For transition rules
search_literature(term="DPSIR DAPSIWRM feedback loop response ecosystem state", 
                  topic="marine ecology", limit=10)

# For specific ecological claims
search_literature(term="nutrient enrichment cyanobacteria bloom Baltic", 
                  topic="eutrophication", limit=10)

# For checking existing citations in the KB
search_literature(doi="10.1016/j.marpolbul.2023.xxxxx")
```

**Key scite features to use:**
- `editorialNotices`: Check if cited papers have been retracted or corrected
- Smart Citation classification: Count supporting vs contrasting evidence
- `fulltextExcerpts`: Read the actual cited text for context
- `contrasting_from`: Find papers that disagree (minimum 1 for controversial claims)

#### WebSearch (grey literature)

```
# For regional policy context
WebSearch(query="HELCOM nutrient reduction targets Baltic Sea 2025",
          allowed_domains=["helcom.fi", "ices.dk", "eea.europa.eu"])

# For framework methodology
WebSearch(query="DPSIR DAPSIWRM framework marine SES feedback loops",
          allowed_domains=["sciencedirect.com", "springer.com", "mdpi.com"])

# For management effectiveness evidence
WebSearch(query="MPA effectiveness Mediterranean fish stock recovery")
```

### Phase 3: Cross-Reference and Assess

For each claim, produce a verdict:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **CONFIRMED** | 3+ supporting citations, 0 contrasting, no retractions | No change needed |
| **SUPPORTED** | 1-2 supporting citations, 0 contrasting | Acceptable, note limited evidence |
| **CONTESTED** | Both supporting and contrasting citations exist | Flag for domain expert review; add nuance to code comments |
| **UNSUPPORTED** | No citations found | Flag; may be valid but undocumented, or may be incorrect |
| **CONTRADICTED** | Contrasting citations outweigh supporting | Must fix; the code encodes incorrect science |
| **RETRACTED** | Source paper retracted or corrected | Must fix; remove or replace the citation |

### Phase 4: Report

Generate a structured report:

```markdown
# Scientific Validation Report

**Scope**: [what was reviewed]
**Date**: [date]
**Sources**: scite MCP (N papers), WebSearch (N grey literature sources)

## Summary
- Claims reviewed: N
- Confirmed: N | Supported: N | Contested: N | Unsupported: N | Contradicted: N

## Findings

### [CONTRADICTED] Response → State transitions missing from validator
**Claim**: `is_valid_dapsirwrm_transition()` rejects R→C/S connections
**Evidence**: 
- Framework doc Rule 12 explicitly allows R/M → C/S
- KB contains 12 R→C/S connections across 4 contexts
- scite: Elliott et al. (2017) DOI:10.1016/xxx — "Response measures directly affect ecosystem state" [supporting]
- scite: Borja et al. (2016) DOI:10.1016/xxx — DPSIR framework review confirms R→S pathway [supporting]
- Grey: HELCOM BSAP (2021) — nutrient reduction targets directly linked to ecosystem state indicators
**Recommendation**: Add `responses → states` to valid transitions in `network_analysis.R:347-384`

### [CONFIRMED] Nutrient enrichment → Cyanobacteria bloom (Baltic lagoon)
**Claim**: Positive causal link, strong strength
**Evidence**:
- scite: Paerl & Otten (2013) — 847 supporting citations [supporting]
- scite: Scheffer et al. (1993) — regime shift model [supporting]
- Grey: HELCOM eutrophication assessment 2023 — confirmed for Baltic lagoons
**Recommendation**: No change needed
```

## Validation Targets

### Code Validation Targets
| File | What to validate |
|------|-----------------|
| `functions/network_analysis.R:347-384` | `is_valid_dapsirwrm_transition()` — are all allowed transitions scientifically valid? Are any valid transitions missing? |
| `functions/network_analysis.R:749-793` | `classify_loop_type()` — is reinforcing/balancing classification correct? |
| `constants.R:129-148` | `DAPSIWRM_ELEMENTS` — are all 9 element types represented? Is the HW/M collapse justified? |
| `modules/analysis_loops.R` | Loop detection parameters — are defaults (max_length=8, density thresholds) ecologically sound? |

### KB Validation Targets
| File | What to validate |
|------|-----------------|
| `data/ses_knowledge_db.json` | Connection polarity, strength, confidence — do they match current literature? |
| `data/ses_knowledge_db_offshore_wind.json` | Same checks; also verify regional specificity (North Sea vs Baltic vs Atlantic vs Med) |

### Framework Document
| File | What to validate |
|------|-----------------|
| `DAPSIWRM_FRAMEWORK_RULES.md` | Are the 16 rules up to date with current SES literature (Elliott 2002, 2011, 2014; Patricio et al. 2016)? |

## Known Gaps (as of 2026-04-11)

The following gaps from earlier reviews have been **RESOLVED**:

| Gap | Status | Resolution |
|-----|--------|-----------|
| R→C/S (Rule 12) | ✅ Fixed | Added to validator 2026-04-10 |
| C/S→C/S (Rule 16) | ✅ Fixed | Added 2026-04-10 |
| R→R (Rule 14) | ✅ Fixed | Added 2026-04-10 |
| P→P (Rule 17) | ✅ Fixed | Added 2026-04-10 (cumulative effects) |
| M→R (Rule 13) | ✅ Fixed | Added 2026-04-10 |
| A→A (Rule 18) | ✅ Fixed | Added 2026-04-11 (MSP extension) |
| D→P (ExUP exception) | ✅ Fixed | Added 2026-04-11 (climate change) |

The validator now has **23 valid transitions** covering Rules 1-18 + ExUP. Full polarity scan on both KBs shows 0 invalid transitions.

### Remaining Gaps

- **HW collapsed into GB in 7-element model** (`constants.R:129-137`). By design — the toolbox uses a 7-element simplification of the 9-element framework. HW→R and HW→D pathways are represented via GB.
- **11 research/monitoring elements flagged** as Activities may belong as Responses (domain expert review needed). See `scripts/kb_audit/output/ses_knowledge_db_audit.md`.

## Integration with Existing Agents

This skill complements (does not replace) two existing subagents:

- **`dapsiwrm-validator`** — structural code validation (correct types, matrix names, polarity). Does NOT check scientific accuracy of the rules themselves.
- **`kb-connection-reviewer`** — reviews KB connection quality against framework rules. Does NOT verify the rules against literature.

**This skill fills the gap**: it validates that the framework rules encoded in code actually match current scientific understanding. Use it when changing rules, adding KB entries, or when a tester/stakeholder questions the science.

## When NOT to Use This Skill

- Pure code refactoring that doesn't change scientific logic
- UI/UX bugs with no ecological component
- Translation/i18n work
- Performance optimization
