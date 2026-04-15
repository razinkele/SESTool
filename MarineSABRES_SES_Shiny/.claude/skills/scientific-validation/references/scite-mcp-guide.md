# Scite MCP Tool Reference

## Setup

The scite MCP server provides access to 1.4B+ scientific citations with Smart Citation classification.

**URL**: `https://api.scite.ai/mcp`

**Add to Claude Code**:
```bash
claude mcp add scite --url https://api.scite.ai/mcp
```

## Primary Tool: search_literature

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `term` | string | Search query keywords |
| `doi` | string | Look up a specific paper by DOI |
| `author` | string | Filter by author name |
| `journal` | string | Filter by journal name |
| `topic` | string | Filter by topic/field |
| `affiliation` | string | Filter by institution |
| `date_from` | string | Start date (YYYY-MM-DD) |
| `date_to` | string | End date (YYYY-MM-DD) |
| `publication_type` | string | Filter by type (article, review, etc.) |
| `citing_publications_from` | int | Minimum total citations |
| `supporting_from` | int | Minimum supporting citations |
| `contrasting_from` | int | Minimum contrasting citations (useful for finding contested claims) |
| `mentioning_from` | int | Minimum mentioning citations |
| `limit` | int | Max results (default 10) |
| `sort` | string | Sort order |

### Result Fields

Each result contains:
- **Standard metadata**: title, authors, journal, year, DOI, abstract
- **Smart Citations**: classified as Supporting, Contrasting, or Mentioning — the actual text of how other papers cite this one
- **Citation counts**: total, supporting, contrasting, mentioning
- **editorialNotices**: retractions, corrections, expressions of concern
- **fulltextExcerpts**: relevant passages from open access papers
- **Access links**: URLs to the full paper

### Query Patterns for SES Validation

**Check a specific DPSIR transition:**
```
search_literature(term="DPSIR response measure ecosystem state recovery marine", 
                  topic="marine ecology", limit=10)
```

**Verify a causal claim in the KB:**
```
search_literature(term="[cause element] [effect element] [ecosystem type]",
                  topic="[relevant topic]", limit=10)
```

**Find contrasting evidence for a contested claim:**
```
search_literature(term="[claim keywords]", contrasting_from=1, limit=10)
```

**Check if a cited paper has been retracted:**
```
search_literature(doi="10.1016/j.marpolbul.2023.xxxxx")
# Check editorialNotices in the result
```

**Review framework methodology papers:**
```
search_literature(term="DPSIR DAPSIWRM social ecological system framework",
                  author="Elliott", topic="marine policy", limit=10)
```

## Interpreting Smart Citations

| Type | Meaning | Use for |
|------|---------|---------|
| **Supporting** | The citing paper agrees with or builds on the claim | Confirming ecological relationships |
| **Contrasting** | The citing paper disagrees or presents conflicting evidence | Finding contested claims |
| **Mentioning** | The citing paper references without evaluating | Context only |

A high supporting:contrasting ratio (>10:1) indicates strong consensus.
A low ratio (<3:1) indicates active scientific debate — flag for domain expert review.

## Fallback When Scite MCP Unavailable

If the scite MCP server is not configured or returns errors, use WebSearch with academic domains:

```
WebSearch(query="[search terms]", 
          allowed_domains=["scholar.google.com", "pubmed.ncbi.nlm.nih.gov", 
                          "doi.org", "scopus.com", "sciencedirect.com",
                          "springer.com", "mdpi.com", "wiley.com"])
```

This provides less structured results (no Smart Citation classification), but still accesses peer-reviewed literature.
