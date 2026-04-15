# Grey Literature Sources for Marine SES Validation

Use Claude's WebSearch tool for these sources. Grey literature fills gaps where peer-reviewed papers lag behind policy, provide regional specificity, or cover management effectiveness.

## Priority Sources by Domain

### Marine Policy & Governance
| Source | Domain | What it covers |
|--------|--------|---------------|
| HELCOM | `helcom.fi` | Baltic Sea environmental assessments, BSAP targets, indicator reports |
| OSPAR | `ospar.org` | NE Atlantic quality status reports, MSFD implementation |
| ICES | `ices.dk` | Fisheries advice, ecosystem overviews, working group reports |
| EU MSFD | `ec.europa.eu` | Marine Strategy Framework Directive guidance, GES descriptors |
| Barcelona Convention | `unepmap.org` | Mediterranean marine environment assessments |

### Ecosystem & Biodiversity
| Source | Domain | What it covers |
|--------|--------|---------------|
| IPBES | `ipbes.net` | Global/regional biodiversity assessments |
| IUCN | `iucn.org` | Species status, MPA guidelines, nature-based solutions |
| EMODnet | `emodnet.ec.europa.eu` | European marine observation data, habitat maps |
| EEA | `eea.europa.eu` | State of Europe's Seas, environmental indicators |

### Climate & Pressures
| Source | Domain | What it covers |
|--------|--------|---------------|
| IPCC | `ipcc.ch` | Climate change impacts on marine systems |
| WMO | `wmo.int` | Ocean state reports, climate indicators |
| IOC-UNESCO | `ioc.unesco.org` | Ocean science, harmful algal blooms |

### Fisheries & Food Security
| Source | Domain | What it covers |
|--------|--------|---------------|
| FAO | `fao.org` | State of World Fisheries, fisheries management |
| STECF | `stecf.jrc.ec.europa.eu` | EU fisheries science committee assessments |

### Offshore Wind
| Source | Domain | What it covers |
|--------|--------|---------------|
| WISER | `wiserenergy.eu` | Wind energy environmental impacts |
| 4COffshore | `4coffshore.com` | Offshore wind farm data |
| Crown Estate | `thecrownestate.co.uk` | UK offshore wind environmental monitoring |
| BSH | `bsh.de` | German marine spatial planning, offshore wind EIA |

## Search Patterns

### Regional specificity
```
WebSearch(query="eutrophication threshold [region] [year]",
          allowed_domains=["helcom.fi", "ospar.org", "eea.europa.eu"])
```

### Management effectiveness
```
WebSearch(query="MPA effectiveness [species/habitat] [region]",
          allowed_domains=["iucn.org", "eea.europa.eu"])
```

### Current policy targets
```
WebSearch(query="[policy name] targets [year] marine",
          allowed_domains=["ec.europa.eu", "helcom.fi", "ospar.org"])
```

### Indicator thresholds
```
WebSearch(query="Good Environmental Status [descriptor] [region] threshold",
          allowed_domains=["ec.europa.eu", "ices.dk"])
```

## When to Prefer Grey Literature Over Peer-Reviewed

- **Current policy targets**: EU/HELCOM/OSPAR targets change faster than papers can track
- **Regional thresholds**: GES descriptors vary by region and are defined in policy docs, not papers
- **Management effectiveness**: MPA monitoring reports are often published as grey literature first
- **Indicator methodology**: ICES/HELCOM methodological standards are in technical reports
- **Offshore wind impacts**: EIA reports and monitoring data are often non-peer-reviewed
