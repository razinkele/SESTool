#!/usr/bin/env python3
"""Build the WP5 financial-mechanism knowledge base from D5.2 source extracts.

Reads markdown extracts of the four WP5 source documents and emits
data/ses_knowledge_db_wp5_mechanisms.json. Mirrors the offshore-wind KB build
script's style and manual-edit guard.

Usage:
    micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py

Source extracts (regenerate via python-docx if missing):
    ~/AppData/Local/Temp/wp5_extract/D5.2_main.md
    ~/AppData/Local/Temp/wp5_extract/D5.2_macaronesia.md
    ~/AppData/Local/Temp/wp5_extract/blue_corridor.md
    ~/AppData/Local/Temp/wp5_extract/tuscan.md
    ~/AppData/Local/Temp/wp5_extract/arctic.md

NOTE ON MANUAL POST-GENERATION EDITS
------------------------------------
data/ses_knowledge_db_wp5_mechanisms.json may be hand-edited after generation
during partner-review cycles. Rerunning this script REGENERATES from the
in-script mechanism definitions (below) and will drop any manual additions
not mirrored here. Before rebuilding:
  1. git diff data/ses_knowledge_db_wp5_mechanisms.json against last commit
  2. confirm whether the JSON state is authoritative (keep) or this script
     is (overwrite)
  3. if the JSON is authoritative, mirror manual changes into the in-script
     definitions below before rebuilding
"""

import json
from datetime import date
from pathlib import Path

OUT_PATH = Path("data/ses_knowledge_db_wp5_mechanisms.json")
SOURCE_COMMIT = "1f636e8"
SOURCE_DOCS = [
    "Blue_corridor_financial toolkit_17_04_2026.docx",
    "Draft financial mechanisms_Tuscan DA.docx",
    "Draft text financial mechanisms_Arctic DA.docx",
    "MarineSABRES_Deliverable5.2_Draftv3.docx",
]

# ============================================================================
# MECHANISM DEFINITIONS
# ============================================================================
# Each mechanism MUST carry all 13 attributes:
#   id, name, cost_profile, what_it_funds, finance_flow, design_parameters,
#   evidence_base, transferable_lessons, applies_to_DAs, success_metrics,
#   risks_and_guardrails, use_in_impact_assessment, references
# Of these, 9 are subject to the audit's ≥8/9 completeness floor (`id` is
# the 10th required field but is always populated by construction).
# `success_metrics` may legitimately be empty if no Phase 3 indicator covers
# the mechanism yet.

MACARONESIA_MECHANISMS = [
    # ----- mac_01: Blue Corridor Facility -----
    {
        "id": "mac_01_blue_corridor_facility",
        "name": "Blue Corridor Facility",
        "cost_profile": "recurring",
        "what_it_funds": "A regional financing facility funding coordinated monitoring, enforcement, scientific assessment, and stakeholder engagement across the Azores-Madeira-Canary Islands EEZ + ABNJ Blue Corridor.",
        "finance_flow": {
            "payer": [
                "EU (Horizon Europe successor + EMFAF)",
                "national governments (PT, ES)",
                "philanthropic foundations",
            ],
            "receiver": "regional secretariat (proposed: hosted by an existing IGO or jointly by national MPA agencies)",
            "type": "blended",
        },
        "design_parameters": [
            "Narrow corridor-delivery mandate to prevent mission creep",
            "Eligible cost categories defined in the founding charter (monitoring, enforcement, science, engagement; not general MPA operations)",
            "Three-jurisdiction governing board with rotating chair",
            "Annual operating budget €5–15M, with multi-year commitment cycles",
        ],
        "evidence_base": [
            "MSP4BIO D3.2 (regional financing analogues)",
            "OSPAR Coordinated Environmental Monitoring Programme (governance precedent)",
            "Mediterranean MedPAN Fund (operational precedent for regional MPA financing)",
        ],
        "transferable_lessons": [
            "Regional secretariat must have legal personality; informal coordination collapses under fiscal stress",
            "Multi-year commitment cycles essential — annual renewals create activity gaps that erode trust",
            "Co-funding from national governments (not just EU) increases political durability",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_01", "C_02", "M_01"],
        "risks_and_guardrails": [
            {"risk": "Mandate creep — facility becomes a generic MPA funding pot",
             "guardrail": "Founding charter narrows eligible activities to corridor-delivery; annual board review of out-of-scope requests"},
            {"risk": "Free-riding by one jurisdiction",
             "guardrail": "Co-funding share required as condition of voting rights"},
            {"risk": "Political withdrawal during national election cycles",
             "guardrail": "Multi-year commitments + treaty-level codification (where feasible)"},
        ],
        "use_in_impact_assessment": "Use this mechanism when scoring a Macaronesia scenario where regional coordination capacity is the binding constraint (S3 Coordinated EEZ or S4 Integrated EEZ+ABNJ). Score it positively on EE (enables monitoring) and negatively on PI (requires multi-state agreement). Pair with M_01 vessel-movement indicator for measurable success.",
        "references": [
            "MarineSABRES D5.2 §5.x Blue Corridor financial toolkit",
            "MSP4BIO Deliverable 3.2",
        ],
    },
    # ----- mac_02: MPA tourism-levy fund (partner-pickable default) -----
    {
        "id": "mac_02_tourism_levy_fund",
        "name": "MPA tourism-levy fund",
        "cost_profile": "recurring",
        "what_it_funds": "Conservation actions and visitor-management infrastructure in Macaronesian MPAs, financed by a small per-visitor or per-vessel levy on marine tourism operators.",
        "finance_flow": {
            "payer": ["marine tourism operators (whale-watching, dive boats, charter vessels)"],
            "receiver": "MPA management body",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Levy collected at point of sale (not at the dock) for compliance",
            "Earmarked spending plan published annually",
            "Levy adjusts inversely with visitor numbers to smooth revenue",
        ],
        "evidence_base": [
            "Galápagos visitor entry fee (operational precedent)",
            "Bonaire dive tag programme",
        ],
        "transferable_lessons": [
            "Visible reinvestment in infrastructure (mooring buoys, signage) sustains operator buy-in",
            "Online point-of-sale collection has lower leakage than on-water enforcement",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["T_02"],
        "risks_and_guardrails": [
            {"risk": "Levy passed entirely to visitors with no operator engagement",
             "guardrail": "Operator co-governance seat on the spending plan"},
        ],
        "use_in_impact_assessment": "Use for any Macaronesia scenario with active marine tourism. Score positively on FF and EC.",
        "references": ["MarineSABRES D5.2 Blue Corridor toolkit, §x.x"],
    },
    # ----- mac_03: Multi-year Delivery & Shared-Services Facility -----
    {
        "id": "mac_03_multi_year_delivery_facility",
        "name": "Multi-year Delivery & Shared-Services Facility",
        "cost_profile": "recurring",
        "what_it_funds": "A ring-fenced multi-year facility funding the recurring delivery functions corridor scenarios depend on but cannot sustain through one-off projects: core delivery staff, joint procurement of training and shared tools, maintenance of shared SOPs and reporting templates, indicator-pipeline support, and an optional small contingency window. Disburses against milestones rather than ad-hoc annual allocations.",
        "finance_flow": {
            "payer": [
                "EU seed funding (Horizon Europe successor + EMFAF)",
                "national governments (PT, ES)",
                "regional co-finance",
            ],
            "receiver": "ring-fenced delivery facility / host entity / contracted implementing partners",
            "type": "blended",
        },
        "design_parameters": [
            "Ring-fencing + multi-annual commitment (3–5 years) — not annually renewable",
            "Window structure with explicit % allocations across coordination, monitoring, training, implementation",
            "Disbursement rule: milestone/KPI-gated rather than block grants",
            "Narrow corridor-delivery mandate + eligibility rules to prevent mission creep",
            "Overhead caps and stop/go gates on IT/consultancy spend (MVP-only for shared tools)",
        ],
        "evidence_base": [
            "Conservation trust fund / ring-fenced facility models in protected-area finance guidance",
            "OECD ocean-finance literature on recurrent delivery needs and financing gaps",
            "MSP4BIO planning support logic for biodiversity mainstreaming in recurring cycles",
            "CMAR-style regional cooperation practice on delivery beyond pilot phases",
        ],
        "transferable_lessons": [
            "Pooled finance works best when the facility has a narrow, explicit mandate with transparent allocation rules",
            "Multi-year commitments are essential — short project cycles destroy delivery continuity",
            "Distinguish core delivery funding from optional co-financing for rollout to avoid pot-of-money optics",
            "Tie disbursement to delivered outputs and documented user uptake, not budget execution",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "M_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Facility becomes too broad and turns into a generic funding pot",
             "guardrail": "Define narrow corridor-delivery mandate + eligible cost categories at the founding charter"},
            {"risk": "Unstable or politically contestable replenishment",
             "guardrail": "Set multi-year commitments and renewal rules in advance; tie to treaty-level codification where feasible"},
            {"risk": "Co-financing window rewards opportunistic projects rather than corridor priorities",
             "guardrail": "Tie any rollout support to agreed corridor work-programme priorities and reporting"},
            {"risk": "Administrative overhead crowds out delivery",
             "guardrail": "Cap management costs, require annual public reporting on allocations and outputs, run independent annual audit"},
            {"risk": "IT/consultancy budget sink",
             "guardrail": "MVP-only IT scope with stop/go gate tied to delivered outputs and documented uptake"},
        ],
        "use_in_impact_assessment": "Use this mechanism when scoring Macaronesia scenarios where delivery continuity is the binding constraint (S3 Coordinated and S4 Integrated). Score positively on FF (sustained funding) and PI (translates declarations into operational delivery); pair with C_02 monitoring-capacity indicator and corridor-wide implementation outputs. Without this mechanism, S3/S4 are paper exercises — with it, sustained capacity becomes plausible.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #2",
            "OECD ocean-finance literature on biodiversity finance",
            "MSP4BIO Deliverable 3.2",
        ],
    },
    # ----- mac_04: Shared evidence & decision-products layer -----
    {
        "id": "mac_04_shared_evidence_services",
        "name": "Shared evidence & decision-products layer",
        "cost_profile": "recurring",
        "what_it_funds": "Production of usable shared corridor evidence rather than raw data dumps: indicator briefs, operator-facing summaries (\"what this means for you\"), harmonised reporting templates, plain-language syntheses, simple dashboards, and translation/layout. The aim is to make corridor evidence operationally usable by authorities, operators, and stakeholders across the Azores–Madeira–Canary Islands rather than letting data sit unused.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "EU technical-assistance line",
                "facility/shared-services budget",
            ],
            "receiver": "designated technical unit / contracted comms+data product team",
            "type": "public",
        },
        "design_parameters": [
            "Define a minimum viable product set per year (briefs, decision notes, templates) with named owners and sign-off",
            "Each product must declare its decision use-case before publication",
            "Update cadence and version control with documented method changes",
            "Accessibility: multilingual layout, plain-language operator summary (≤2 pages) plus glossary",
            "5–10 user test before public release of any new product",
        ],
        "evidence_base": [
            "MSP4BIO Baltic Sea brief on turning cumulative-impact and biodiversity data into planning-relevant outputs",
            "Marine corridor / connectivity literature reviewed by Podda & Porporato on bridging fragmented data",
            "MSP / biodiversity planning literature on integrating evidence into decision cycles",
        ],
        "transferable_lessons": [
            "Data availability alone is insufficient — the bottleneck is converting data into audience-specific products that fit decision cycles",
            "Connectivity-related products gain durability when embedded in formal MSP/MPA cycles, not left as project outputs",
            "Decision-note format alongside dashboards prevents technical showcase syndrome",
            "Common metadata + version control across archipelagos is what makes products comparable",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_01", "C_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Product layer becomes a technical showcase with no operational uptake",
             "guardrail": "Define target users and required use-cases at the outset; track adoption metrics"},
            {"risk": "Over-complex dashboards displace usable decisions",
             "guardrail": "Require a short decision-note format alongside any dashboard"},
            {"risk": "Inconsistent definitions undermine cross-archipelago comparability",
             "guardrail": "Adopt common metadata, update rules and version control"},
            {"risk": "Shared products are not trusted",
             "guardrail": "Make methods transparent and link each product to named data sources and update dates"},
            {"risk": "Too technical to apply",
             "guardrail": "Enforce a 2-page operator summary + glossary, plus a 5–10 user test before release"},
        ],
        "use_in_impact_assessment": "Use whenever scoring requires consistent cross-archipelago evidence interpretation (any S2–S4 scenario). Score positively on C_02 and as an enabler for C_01 connectivity scoring. Treat as an enabling layer underpinning multiple indicators rather than a standalone delivery mechanism. Without this layer, the rest of the toolkit's reporting becomes archipelago-by-archipelago and uninterpretable.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #3",
            "MSP4BIO Baltic Sea brief",
            "Podda & Porporato — marine corridor connectivity review",
        ],
    },
    # ----- mac_05: Integrated monitoring & data pipeline -----
    {
        "id": "mac_05_integrated_monitoring",
        "name": "Integrated monitoring & data pipeline",
        "cost_profile": "recurring",
        "what_it_funds": "A repeatable corridor-scale annual monitoring pipeline producing harmonised indicator outputs: AIS-derived vessel-flow products (M_01), sensitive-area overlap/proximity products (M_02), method documentation, QA/QC routines, and recurring updates of pressure/activity datasets. Moves the DA from fragmented project monitoring to a stable, year-on-year comparable indicator pipeline that feeds the impact assessment.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "ring-fenced facility share",
                "service contracts (analytics provider or public agency)",
            ],
            "receiver": "designated technical unit / monitoring consortium / contracted analytical support",
            "type": "public",
        },
        "design_parameters": [
            "Define minimum core indicator set first, extended set later",
            "Adopt one fixed method per reporting year; freeze definitions and publish a method note",
            "Data access/rights resolved upfront (AIS sources, confidentiality)",
            "Definition set for sensitive areas + buffers documented and version-controlled",
            "Reporting calendar fixed and named delivery owners assigned",
            "Include implementation/process indicators alongside ecological/pressure metrics",
        ],
        "evidence_base": [
            "MSP4BIO Baltic Sea — strongest cumulative-pressure/impact analogue",
            "Monitoring and biodiversity-assessment literature on repeatable indicator systems",
            "Marine corridor literature (Podda & Porporato) on integrated monitoring approaches",
            "Regional MSP/MPA practice on harmonised monitoring under fragmented competences",
        ],
        "transferable_lessons": [
            "Monitoring becomes management-useful only when method-stable, repeatable, QA'd, and linked to decision cycles",
            "One-off analyses or project dashboards do not survive into reporting cycles",
            "Pressure/impact tools work best embedded in planning and review cycles",
            "Add implementation/process indicators alongside ecological metrics — otherwise the system tracks pressures but not whether measures are happening",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "M_02", "F_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Monitoring system becomes too broad and collapses under data demands",
             "guardrail": "Define a minimum core indicator set first; expand only after stable annual delivery"},
            {"risk": "Indicators are updated inconsistently across archipelagos",
             "guardrail": "Adopt common metadata, version control and QA/QC procedures"},
            {"risk": "Annual outputs are delayed and lose management value",
             "guardrail": "Fix reporting calendar and assign delivery owners"},
            {"risk": "System tracks pressures but not whether measures are implemented",
             "guardrail": "Include implementation/process indicators alongside ecological/pressure metrics"},
            {"risk": "Outputs misread as enforcement proof",
             "guardrail": "Label as risk/pressure indicators and include coverage/limitations on each release"},
            {"risk": "Method disputes undermine comparability",
             "guardrail": "Adopt one fixed method per year; publish method note with definitions frozen for the reporting year"},
        ],
        "use_in_impact_assessment": "This is the indicator-engine row. It underpins C_02 (monitoring capacity exists and is repeatable), conditions the credibility of S3 and S4, and supports interpretation of M_01/M_02. Without an integrated monitoring pipeline, scenario-level indicator claims default to one-off project artefacts. Score positively on EE (enables enforcement targeting) and PI; pair with M_01 vessel-flows + M_02 sensitive-area overlap as primary indicator outputs.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #4",
            "MSP4BIO Baltic Sea cumulative-impact assessment work",
            "Podda & Porporato — marine corridor connectivity review",
        ],
    },
    # ----- mac_06: Compliance enablement service ("single front door") -----
    {
        "id": "mac_06_compliance_support",
        "name": "Compliance enablement service (\"single front door\")",
        "cost_profile": "recurring",
        "what_it_funds": "A visible operator-facing support function that reduces administrative friction and improves implementation consistency: helpdesk staffing, port-side support days, multilingual templates, training sessions, ticketing/CRM, and a living decision tree. One set of templates and interpretations across the three archipelagos, plus onboarding support and rule clarification — focused on making compliance navigable, not on replacing enforcement.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "facility core services line",
                "sector support budgets where applicable",
            ],
            "receiver": "designated host entity / coordination platform / contracted support provider",
            "type": "public",
        },
        "design_parameters": [
            "Service scope explicitly bounded (information + case-handling support; not enforcement substitute)",
            "Service levels defined upfront (response times, port presence schedule)",
            "One named interpretation owner across archipelagos to prevent conflicting guidance",
            "Versioned templates with change log",
            "Multilingual coverage and dedicated outreach to small/dispersed operators",
            "Feedback loop from helpdesk issues into rule clarification and simplification",
            "\"No net new burden\" rule: any new step must replace/simplify an old one",
        ],
        "evidence_base": [
            "Compliance and implementation literature on reducing administrative burden",
            "Whale-watching regulatory guidance and operator handbooks",
            "Fisheries MCS / reporting guidance and EM/observer rollout practice",
            "Interreg-style shared-governance projects (e.g. ARGOS) for cross-border operational guidance",
        ],
        "transferable_lessons": [
            "Compliance improves when rules are not only enforceable but also legible, predictable, and usable for operators",
            "Clear templates + multilingual support + rapid clarification channels reduce rework and low-grade conflict",
            "Service is most effective when tied to formal authorities and real reporting obligations — not soft outreach",
            "Track time-to-comply as a service KPI, not just helpdesk volume",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Service becomes an informal helpdesk with no authority or uptake",
             "guardrail": "Anchor it formally to the coordination platform and competent authorities"},
            {"risk": "Operators receive advice that differs from formal enforcement expectations",
             "guardrail": "Maintain validated templates and written guidance cleared by relevant authorities"},
            {"risk": "Support is captured by better-organized actors while small/dispersed users remain excluded",
             "guardrail": "Include targeted outreach days, multilingual formats, and low-barrier access channels"},
            {"risk": "Service substitutes for enforcement and weakens credibility",
             "guardrail": "Define clearly that it supports compliance but does not replace inspection, follow-up, or sanctions"},
            {"risk": "Adds bureaucracy",
             "guardrail": "\"No net new burden\" rule + track time-to-comply"},
            {"risk": "Conflicting guidance across archipelagos",
             "guardrail": "Appoint one interpretation owner, use versioned templates, and maintain a change log"},
        ],
        "use_in_impact_assessment": "Use whenever scoring scenarios that tighten reporting/compliance obligations (S3, S4). Score positively on PI (implementation friction lowered), EQ (small operators not pushed to the back of the queue), and FF (efficiency dividend on existing budgets). It conditions whether registry/reporting indicator improvements (F_03, T_03) are plausible. Without this layer, stronger rules under S3/S4 generate conflict rather than compliance.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #5",
            "FAO MCS / fisheries-reporting guidance",
            "ARGOS Interreg cross-border governance project",
        ],
    },
    # ----- mac_07: Adaptive contingency reserve -----
    {
        "id": "mac_07_adaptive_contingency_reserve",
        "name": "Adaptive contingency reserve (displacement / substitution response)",
        "cost_profile": "contingent",
        "what_it_funds": "A small ring-fenced trigger-based reserve within the delivery facility, activated only when predefined evidence indicates corridor measures may be displacing rather than reducing pressure. Funds rapid-response monitoring deployments, short analytical work, temporary mitigation pilots, targeted communication, and stakeholder follow-up. Designed as a safety valve, not a standing programme.",
        "finance_flow": {
            "payer": [
                "ring-fenced share of delivery facility / public implementation budget",
                "philanthropic match (optional, for rapid response)",
            ],
            "receiver": "host entity / monitoring team / contracted technical support, activated only when triggers met",
            "type": "blended",
        },
        "design_parameters": [
            "Pre-defined quantitative triggers (e.g. effort displacement detected via M_01 / F_01)",
            "Capped maximum drawdown per event; reserve sized as small % of total facility",
            "Activation authority and decision deadline named in advance",
            "Mandatory 30-day rapid assessment + 90-day decision (stop/extend/scale)",
            "Mandatory after-action note published for each activation",
            "Sunset rule: reserve auto-expires unless renewed",
            "Stakeholder follow-up and communication included as eligible response costs",
        ],
        "evidence_base": [
            "Adaptive management and implementation literature on dynamic ocean management",
            "Marine corridor / dynamic management literature on shifting use patterns",
            "WWF blue-corridor material on displacement/leakage in connectivity conservation",
            "MSP4BIO-style cumulative-impact and trade-off tools for hotspot identification",
        ],
        "transferable_lessons": [
            "Corridor implementation should not assume that pressure reductions in one place equal net gains overall — pressures shift",
            "A modest, rule-based reserve activated by triggers prevents \"displacement denial\" while avoiding slush-fund optics",
            "Communication and stakeholder follow-up must be funded explicitly, not tacked on",
            "Repeated activation should trigger review of the underlying measure package — not just be paid out repeatedly",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "F_01", "F_03"],
        "risks_and_guardrails": [
            {"risk": "Reserve becomes a discretionary \"miscellaneous\" fund",
             "guardrail": "Publish strict trigger criteria, eligible uses, and maximum drawdown rules"},
            {"risk": "Activation is politically delayed until impacts entrench",
             "guardrail": "Assign a clear activation authority and a deadline for response"},
            {"risk": "Reserve is used repeatedly because core measures are poorly designed",
             "guardrail": "Require each activation to produce a short lessons-learned note; if repeated, trigger review of the underlying measure package"},
            {"risk": "Responses remain technical and do not reach affected actors",
             "guardrail": "Include communication and stakeholder follow-up as eligible response costs"},
            {"risk": "Seen as a slush fund",
             "guardrail": "Activate only via pre-defined triggers, set max spend per event, and publish an activation note (why/what/outcome)"},
        ],
        "use_in_impact_assessment": "Use when assessing scenarios where pressure displacement / leakage is plausible (Macaronesia S3+ — fisheries effort transfer, vessel re-routing, tourism pressure shifts). Score positively on EE (handles displacement explicitly), EC (efficient use of small reserves), and PI (operationalises adaptive feedback). Pair with M_01 (port/routing shifts) and F_01 (tuna share shifts). Distinguishes scenarios that merely assume adaptation from those that include a funded mechanism to respond.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #6",
            "WWF blue-corridor material on dynamic management",
            "Marine connectivity literature on displacement and substitution effects",
        ],
    },
    # ----- mac_08: Due-process & appeals handling capacity -----
    {
        "id": "mac_08_due_process_appeals",
        "name": "Due-process & appeals handling capacity",
        "cost_profile": "recurring",
        "what_it_funds": "A formal procedural layer for handling objections, clarification requests, reviews, and appeals linked to corridor-relevant measures: case-management staff, additional admin/legal FTE, standardised procedures, published timelines, record-keeping, translation, and response coordination. The aim is procedural fairness and predictability — not creating a judicial system, but preventing administrative disputes from escalating into political blockage.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "facility-eligible administrative budget line",
            ],
            "receiver": "designated host authority / secretariat support unit / formally mandated administrative body linked to corridor governance",
            "type": "public",
        },
        "design_parameters": [
            "Service standards: published median resolution time and backlog thresholds",
            "Transparency: anonymised performance statistics published periodically",
            "Independence safeguards (review options, ombudsperson route)",
            "Clear separation from enforcement incentives",
            "Multilingual, low-threshold access for affected actors",
            "Procedural feedback into coordination and measure revision processes",
            "Defined boundary between corridor-level review and national/regional competences",
        ],
        "evidence_base": [
            "Environmental governance and legitimacy literature",
            "Marine governance / MSP literature on procedural justice and stakeholder acceptance",
            "MSP4BIO planning-governance work on co-development and stakeholder dialogue",
            "IUCN ecological corridor governance guidance as a normative anchor",
        ],
        "transferable_lessons": [
            "Ambitious governance measures stay implementable when actors can see how decisions are made, how objections are handled, and what happens when rules are contested",
            "Procedural clarity does not remove distributional conflict — but it prevents friction from hardening into distrust or selective non-compliance",
            "Due-process in corridor terms is a stability mechanism, not a legalism — focus is on legitimacy, not litigation",
            "Periodic synthesis of cases must feed back into coordination, or procedures become hollow",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02"],
        "risks_and_guardrails": [
            {"risk": "Mechanism becomes opaque or inaccessible and increases frustration rather than trust",
             "guardrail": "Publish simple procedures, timelines and contact points"},
            {"risk": "Duplicates existing national procedures and creates institutional confusion",
             "guardrail": "Define clearly where corridor-level review stops and national/regional competence begins"},
            {"risk": "Only well-organised actors use it",
             "guardrail": "Keep access low-threshold, multilingual, and procedurally simple"},
            {"risk": "Becomes purely formal with no feedback into implementation",
             "guardrail": "Require periodic synthesis of cases/issues and formal discussion in corridor coordination bodies"},
            {"risk": "Perceived as state capacity used against operators",
             "guardrail": "Publish service standards (resolution time targets) and anonymised performance stats"},
            {"risk": "Procedural bias concerns",
             "guardrail": "Provide an independent review/ombudsperson route for procedural complaints"},
        ],
        "use_in_impact_assessment": "Use when scoring S3+ scenarios where corridor measures create visible winners/losers or visible distributional tension across archipelagos. Strengthens PI (procedural credibility) and EQ (perceived fairness when measures tighten). It is not a financing pillar — it is a procedural safeguard that prevents technical coordination from collapsing under political contestation. Without this, ambitious measures remain politically reversible.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #7",
            "MSP4BIO planning-governance analogue",
            "IUCN ecological corridor governance guidance",
        ],
    },
    # ----- mac_09: Results-based financing (RBF) for verified behaviours -----
    {
        "id": "mac_09_results_based_payments",
        "name": "Results-based financing (RBF) for verified behaviours",
        "cost_profile": "time_limited",
        "what_it_funds": "A small-to-moderate performance payment pool funding verified positive behaviours that support corridor delivery — uptake of mitigation practices, completion of required training/accreditation, complete and timely reporting, participation in shared monitoring — rather than paying for ecological end-states. Auditable, simple proofs are paid out via a tiered ladder; designed as a temporary uptake lever, not a permanent subsidy.",
        "finance_flow": {
            "payer": [
                "public programme funds",
                "philanthropic donors",
                "blended-finance sponsors",
                "corporate contributions (where allowable)",
            ],
            "receiver": "verified participating operators, cooperatives, community groups, or service providers via a managing facility / contracted administrator",
            "type": "blended",
        },
        "design_parameters": [
            "Pay for clearly specified, auditable behaviours or intermediate performance — never claim ecological outcomes",
            "Simple, risk-tiered verification with random audit sampling (e.g. 5–10%)",
            "Tiered payment ladder (initial adoption → sustained compliance)",
            "Eligibility floor + assisted onboarding so small operators can participate",
            "Anti-gaming rules: repayment + temporary ineligibility for confirmed violations",
            "Administration burden ceiling (max paperwork per € paid)",
            "Sunset/phase-out rule: defined exit once behaviour normalises",
        ],
        "evidence_base": [
            "Indonesia Coral Bond — clearest marine RBF analogue",
            "Ocean-finance and biodiversity-finance literature on outcome-/performance-based instruments",
            "OECD literature on direct payment schemes and biodiversity-positive incentives",
            "World Bank blue-finance practice on outcome-based instruments",
        ],
        "transferable_lessons": [
            "RBF works only when paying for behaviours/intermediate performance — not for ecological outcomes that cannot be cleanly attributed",
            "The harder the verification, the more important it is to avoid promising direct biodiversity recovery",
            "Should be used selectively and time-bound — long-term RBF without exit becomes dependency",
            "Small-operator inclusion is the equity gate: tech-heavy verification regimes exclude exactly the actors most worth incentivising",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Overclaiming ecological outcomes from behaviour payments",
             "guardrail": "Pay for auditable implementation behaviours or intermediate performance signals — not recovery claims"},
            {"risk": "Verification costs exceed programme value",
             "guardrail": "Use simple, risk-tiered verification and random sampling"},
            {"risk": "Incentives reward actors who would have complied anyway",
             "guardrail": "Target behaviours with genuine uptake barriers and require baseline checks"},
            {"risk": "Gaming or false claims",
             "guardrail": "Random audits + repayment + temporary ineligibility for violations"},
            {"risk": "Dependency on payments after sunset",
             "guardrail": "Define sunset/phase-out rules and use RBF only as a temporary uptake lever"},
            {"risk": "Inequitable access — small operators excluded",
             "guardrail": "No expensive-tech prerequisite + assisted onboarding option"},
        ],
        "use_in_impact_assessment": "Use under S3–S4 only, and only where target behaviours are clearly observable and verifiable. Score positively on PI (accelerates uptake) and FF (efficient incentive delivery); use with caution on EQ/EC. Treat as an optional, scenario-dependent support mechanism — not a baseline assumption. The instrument's value is in accelerating compliance behaviours, not in claiming ecological recovery.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #9",
            "Indonesia Coral Bond — marine outcome-based instrument analogue",
            "OECD biodiversity-finance literature",
            "World Bank blue-finance stocktake materials",
        ],
    },
    # ----- mac_10: Fisheries interaction-risk reduction package fund -----
    {
        "id": "mac_10_fisheries_mitigation",
        "name": "Fisheries interaction-risk reduction package fund",
        "cost_profile": "recurring",
        "what_it_funds": "A package fund supporting the operational rollout of fisheries measure families that reduce harmful interactions with corridor-relevant taxa (cetaceans, seabirds, elasmobranchs): mitigation gear/devices, handling/release protocols, training, hotspot/season pilots, gear/practice trials, uptake of reporting tools, fisher co-design processes, and stakeholder engagement. Measures are funded as a package — technical, spatial/seasonal, monitoring, engagement together — not as isolated technology purchases.",
        "finance_flow": {
            "payer": [
                "public fisheries / corridor implementation budgets",
                "EU/regional co-financing (EMFAF)",
                "optional sector co-finance",
            ],
            "receiver": "fishers / cooperatives / producer organisations / implementing partners / monitoring providers / contracted rollout teams via the delivery facility",
            "type": "blended",
        },
        "design_parameters": [
            "Tiering by fleet segment and risk; \"equivalent measures\" option for different gear types",
            "Eligibility scoped by gear type and port, not blanket coverage",
            "Linkage to monitoring expectations: minimum reporting/verification requirement built in",
            "Hotspot definition and seasonal focus negotiated with fishers, not imposed",
            "Dedicated access routes for small-scale fleets and simple application procedures",
            "3–5 implementation KPIs (training/adoption/coverage/audit-pass) reported alongside indicators",
            "Safeguards against perverse substitution (explicit exclusions; monitoring)",
        ],
        "evidence_base": [
            "FAO bycatch/discards guidance — normative backbone",
            "REDUCE — strong EU analogue for bycatch-reduction/selectivity solutions",
            "RFMO and fisheries monitoring/compliance literature",
            "Peer-reviewed bycatch mitigation and selective fishing literature",
        ],
        "transferable_lessons": [
            "Fisheries interaction-risk reduction works as a bundle — gear/practice changes alone fail without monitoring, fisher buy-in, operational guidance, and spatial/seasonal targeting",
            "Uptake improves when fishers are involved early; one-size-fits-all gear mandates fail",
            "Mitigation support is most effective when it funds rollout capacity (training, testing, support), not just technology purchase",
            "Tie funding to simple implementation and reporting requirements — otherwise learning is weak",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "F_01", "F_03"],
        "risks_and_guardrails": [
            {"risk": "Funding isolated technical fixes that are poorly matched to fleet realities",
             "guardrail": "Require fisher co-design and gear/fleet-specific tailoring"},
            {"risk": "Rollout support is not linked to reporting or monitoring, so learning is weak",
             "guardrail": "Tie funding to simple implementation and reporting requirements"},
            {"risk": "Benefits captured by better-organised fleets while smaller actors are excluded",
             "guardrail": "Include dedicated access routes for small-scale fleets and simple application procedures"},
            {"risk": "Package fund is treated as a substitute for necessary spatial/seasonal management",
             "guardrail": "Frame it explicitly as complementary to, not a replacement for, broader fisheries governance measures"},
            {"risk": "One-size-fits-all requirements",
             "guardrail": "Tiering by fleet/risk + \"equivalent measures\" option for different gear types"},
            {"risk": "Success not visible in core indicators",
             "guardrail": "Require 3–5 implementation KPIs (training/adoption/coverage/audit-pass) reported alongside the indicator set"},
        ],
        "use_in_impact_assessment": "Strongly relevant for S3 and S4 Macaronesia scenarios. Score positively on EE (reduces interaction risk), PI (concrete rollout pathway), EQ (only if small-fleet access is real), and FF (sectoral co-financing efficient). Pair with F_01 fishing-effort indicators; treat F_02 cautiously as a downstream signal, not a near-term outcome. Distinguishes \"corridor on paper\" scenarios from those with a funded fisheries activation.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #10",
            "FAO bycatch/discards guidance",
            "REDUCE EU project on bycatch reduction",
        ],
    },
    # ----- mac_11: Fisheries monitoring coverage uplift window -----
    {
        "id": "mac_11_fisheries_monitoring",
        "name": "Fisheries monitoring coverage uplift window (observer / EM / reporting support)",
        "cost_profile": "time_limited",
        "what_it_funds": "A targeted, time-bound monitoring-coverage uplift focused on corridor-relevant fisheries interactions: human observer placements, electronic monitoring (EM) hardware and installation, onboard cameras, reporting tools, QA/audit functions, training, data-review capacity, and risk-tiered deployment focused on fleets/gears/seasons of highest corridor relevance. Improves credibility and interpretability of fisheries indicators — not blanket surveillance.",
        "finance_flow": {
            "payer": [
                "public fisheries / biodiversity / corridor implementation budgets",
                "EU/regional support (EMFAF, control programmes)",
                "phased operator co-payment (tapering subsidy)",
            ],
            "receiver": "observer providers, EM service providers, monitoring authorities, contracted analysts, and participating operators for installation/support",
            "type": "blended",
        },
        "design_parameters": [
            "Risk-tiered coverage criteria tied to corridor-relevant fleets/gears/areas (not flat coverage)",
            "Observer/EM mix selected per fleet segment",
            "QA/audit procedures defined upfront with documented review cycle",
            "Data ownership, access, privacy, and retention rules agreed before rollout",
            "Proportionate treatment of small-scale fleets with dedicated support pathways",
            "Subsidy tapering schedule with later phased operator co-payment",
            "Disbursement tied to coverage/timeliness/QA outputs (not ecological outcomes)",
            "Exit/integration pathway from outset so support does not become permanent subsidy",
        ],
        "evidence_base": [
            "FAO electronic monitoring guidance",
            "REDUCE — EU analogue for bycatch-reduction implementation environments",
            "RFMO fisheries control and reporting literature",
            "Peer-reviewed and applied monitoring literature on observer and EM governance",
        ],
        "transferable_lessons": [
            "Monitoring coverage improves credibility only when targeted, reviewable, and governable — technology alone is not enough",
            "Risk-based deployment + clear QA/audit + proportionate treatment of fleet segments = uptake",
            "Without explicit data-access/privacy rules, monitoring schemes stall politically",
            "Fund data review, QA and feedback capacity alongside hardware/coverage — otherwise data is collected but not used",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "F_02", "F_03"],
        "risks_and_guardrails": [
            {"risk": "High-cost monitoring deployed without clear priority logic",
             "guardrail": "Use risk-tiered coverage criteria tied to corridor-relevant fleets/gears/areas"},
            {"risk": "Data governance disputes undermine uptake",
             "guardrail": "Define clear rules for data access, privacy, review and use before rollout"},
            {"risk": "Small-scale fleets excluded or overburdened",
             "guardrail": "Use proportionate requirements and dedicated support pathways"},
            {"risk": "Monitoring installed but not reviewed in time",
             "guardrail": "Fund data review, QA and feedback capacity alongside hardware/coverage"},
            {"risk": "Support becomes a permanent subsidy without integration into regular systems",
             "guardrail": "Define tapering or integration pathways from the outset"},
            {"risk": "Privacy/acceptability resistance",
             "guardrail": "Data minimisation + retention limits + restricted access + plain-language privacy note"},
        ],
        "use_in_impact_assessment": "Use under S3 and S4 where indicator interpretation depends on better fisheries coverage; may also support S2 pilots. Score positively on EE (verifiable implementation), PI (credible reporting), and FF (sustainability via tapering co-payment). Differentiates scenarios that rely on weak self-reporting from those with funded verification. Pair with F_02 CPUE — but interpret cautiously as a coverage/QA signal, not a stock-recovery claim.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #11",
            "FAO electronic monitoring guidance",
            "REDUCE EU project",
        ],
    },
    # ----- mac_12: Seasonal enforcement surge ("tuna season package") -----
    {
        "id": "mac_12_seasonal_enforcement",
        "name": "Seasonal enforcement surge (\"tuna season package\")",
        "cost_profile": "time_limited",
        "what_it_funds": "A pre-planned peak-season implementation window for periods when corridor-relevant fisheries activity and associated risks intensify: temporary staffing/overtime, mobile port teams, joint port days, targeted checks, short-notice coordination, anomaly follow-up, seasonal communication to fleets, and minimal seasonal reporting outputs. Activated during defined high-activity windows to stabilise implementation, not to create year-round maximum enforcement.",
        "finance_flow": {
            "payer": [
                "public corridor / fisheries-control budgets",
                "delivery-facility ops surge window",
                "regional/national budget contributions",
            ],
            "receiver": "competent authorities / port teams / contracted support staff / joint implementation units activated during defined seasonal windows",
            "type": "public",
        },
        "design_parameters": [
            "Surge window: fixed (tuna season) vs trigger-based",
            "Risk-based targeting protocol published before the season",
            "Geographic focus (priority ports / hotspots) named in advance",
            "Staffing model (mobile team vs local uplift) agreed upfront",
            "Minimum output logs and standard inspection protocols",
            "Proportionality safeguards and complaints channel with response time",
            "End-of-season evaluation and post-season review of repeated needs",
        ],
        "evidence_base": [
            "FAO MCS guidance — main methodological anchor",
            "ICCAT bluefin compliance and reporting frameworks (tuna-relevant operational analogue)",
            "ARGOS regional cooperation analogue for shared seasonal control",
            "Fisheries monitoring/compliance reviews on targeted control efforts",
        ],
        "transferable_lessons": [
            "Fisheries control is more effective when risk- and season-sensitive than when spread thinly across the calendar",
            "Surges work best when pre-planned, communicated, tied to reporting needs, and embedded in a broader MCS framework — not ad-hoc crackdowns",
            "Repeated surge needs should be treated as evidence of chronic under-capacity, not a substitute for fixing it",
            "Standard protocols + short briefings + minimal output templates = repeatability without bureaucracy",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "F_01", "F_03"],
        "risks_and_guardrails": [
            {"risk": "Surge is used as a symbolic show of control with little analytical targeting",
             "guardrail": "Define priority fleets, ports, periods and expected outputs in advance"},
            {"risk": "Activation creates resentment if perceived as selective or punitive",
             "guardrail": "Communicate clearly that surge is tied to predictable seasonal risk and data demands, not arbitrary scrutiny"},
            {"risk": "Temporary staff or mobile teams lack consistency",
             "guardrail": "Use standard protocols, short briefings and minimal output templates"},
            {"risk": "Seasonal surge compensates for chronic under-capacity without fixing it",
             "guardrail": "Require post-season review and use repeated surge needs as evidence for wider system adjustment"},
            {"risk": "Perceived harassment",
             "guardrail": "Publish targeting rules, apply proportionality safeguards, and provide a complaints channel with response time"},
            {"risk": "\"Random crackdowns\" narrative",
             "guardrail": "Written risk-based protocol + minimum output log (checks/findings/resolution times)"},
        ],
        "use_in_impact_assessment": "Use under S3 and S4 where corridor scenarios assume more operational fisheries measures and credible peak-period follow-up. Score positively on PI (operational evidence of S3/S4 \"effective implementation\" claims), EE (peak-period gap closure), and EC (efficient seasonal use of capacity). Pair with F_01 (peak-season tuna landings context) and F_03 (capacity/participation). Distinguishes scenarios with funded season-sensitive delivery from those that assume year-round generic enforcement.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #12",
            "FAO MCS guidance",
            "ICCAT compliance/reporting frameworks",
        ],
    },
    # ----- mac_13: Managed transition & shock buffering -----
    {
        "id": "mac_13_managed_transition_just_transition",
        "name": "Managed transition & shock buffering (phasing, optional exit, diversification, limited buffering)",
        "cost_profile": "time_limited",
        "what_it_funds": "A targeted, time-limited transition package for actors disproportionately affected by stronger corridor measures: phased implementation, optional licence/effort retirement and buy-back, diversification grants, training, business adaptation, temporary income/risk buffering, and limited insurance-style or mutual-scheme pilots for defined \"rule shocks\". The aim is not permanent compensation but reducing rule shock and making higher-ambition corridor measures socially and politically workable.",
        "finance_flow": {
            "payer": [
                "time-limited public budgets (national / regional / EU)",
                "EU programme support",
                "donor or philanthropic blending where applicable",
                "later operator contributions to mutual schemes (phase-out)",
            ],
            "receiver": "affected operators, cooperatives, workers, community actors, designated transition-support intermediaries",
            "type": "blended",
        },
        "design_parameters": [
            "Strict eligibility tied to demonstrated vulnerability and adjustment need",
            "Sunset clauses + caps on individual / vessel / business support",
            "Anti-speculation and anti-rebound rules; buy-back valuation method published",
            "Diversification guardrails: no incentives that channel effort into already-stressed fisheries",
            "Phasing rules tied to corridor measure timelines",
            "Insurance triggers + co-pay + caps where mutual schemes are piloted",
            "Continued eligibility conditional on monitoring of displacement effects",
        ],
        "evidence_base": [
            "FAO fisheries-capacity and transition guidance",
            "World Bank social-protection / fisheries-capacity work on capacity-reduction logic",
            "FAO long-standing capacity-reduction / buyback experience",
            "OECD fisheries and ocean-finance literature on capacity reduction and transition design",
        ],
        "transferable_lessons": [
            "Transition support works only when targeted, temporary, and tightly linked to management reform — not when it becomes an indefinite, politically diffuse compensation pot",
            "Capacity reduction must be fishery-specific and explicitly connected to management goals — generic buy-backs cause effort transfer",
            "Social-protection instruments improve rule acceptance when tied to actual vulnerability and adjustment need",
            "Resilience/insurance tools should reinforce, not weaken, sustainable management incentives",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["F_01", "F_03", "T_02", "T_04"],
        "risks_and_guardrails": [
            {"risk": "Becomes open-ended compensation or untargeted subsidy",
             "guardrail": "Set strict eligibility, time limits and phase-out rules"},
            {"risk": "Capacity-reduction support leads to effort re-entry or transfer without net adjustment",
             "guardrail": "Link any retirement/buyback to strong re-entry and transfer rules"},
            {"risk": "Support rewards actors who are not materially affected or undermines incentives for adaptation",
             "guardrail": "Require vulnerability and adjustment criteria before disbursement"},
            {"risk": "Insurance/buffering weakens management discipline",
             "guardrail": "Only pilot such tools where they reinforce compliance and are tied to corridor objectives"},
            {"risk": "Transition support is promised without delivery financing",
             "guardrail": "Fund it explicitly and separately from core corridor operations"},
            {"risk": "Harmful substitution/displacement",
             "guardrail": "Explicit exclusion list + monitoring condition for continued eligibility"},
            {"risk": "Moral hazard / repeated bailouts",
             "guardrail": "Strict triggers + caps + sunset clauses (and co-pay where feasible)"},
        ],
        "use_in_impact_assessment": "Use under S3 and S4 where corridor measures impose concentrated short-term burdens on tuna-dependent fisheries, place-bound tourism segments, or specific island communities. Score positively on EQ (just-transition support reduces opposition) and PI (politically feasible implementation), with cautious EC scoring (transition is a cost, not an efficiency gain). Treat as a conditional acceptability safeguard, not a baseline assumption.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #13",
            "FAO fisheries-capacity / transition guidance",
            "World Bank social protection + fisheries capacity work",
            "OECD fisheries / ocean-finance work on transition design",
        ],
    },
    # ----- mac_14: Traceability & market access pathway (conditional) -----
    {
        "id": "mac_14_traceability_certification",
        "name": "Traceability & market access pathway (conditional)",
        "cost_profile": "conditional",
        "what_it_funds": "A conditional, optional pathway through which corridor-relevant fisheries or tourism-related products/services can strengthen market credibility, buyer acceptance, or sustainability-sensitive market access through traceability, chain-of-custody verification, or corridor-linked sustainability claims. Funds traceability infrastructure, verification protocols, documentation support, limited chain-of-custody preparation, audits, and buyer engagement — without assuming price premiums.",
        "finance_flow": {
            "payer": [
                "public seed funding / corridor implementation support (initially)",
                "operators / supply-chain partners (later, if commercially viable)",
            ],
            "receiver": "participating operators, cooperatives, verification providers, digital-service providers, managing entities",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Activation checklist: credible buyer pull + practical standard + costed pathway must exist before launch (\"buyer-pull gate\")",
            "Independent third-party audits and anti-greenwash criteria",
            "Documented buyer pull and costed uptake plan as a precondition for public seed funding",
            "Scope boundaries: which products/fleets covered; reporting outputs (verified lots, rejection rates) rather than premium promises",
            "Treatment of small-scale operators with proportionate requirements and shared support tools",
            "Alignment with existing legal and buyer requirements first to avoid duplication",
            "Separation of communication claims from auditable verification standards",
        ],
        "evidence_base": [
            "FAO national seafood traceability guidance — strongest practical analogue",
            "OECD fisheries/aquaculture certification, chain-of-custody and seafood market literature",
            "World Bank seafood value-chain and traceability materials",
            "Trade/ecolabelling literature on opportunities and exclusion risks of certification",
        ],
        "transferable_lessons": [
            "Traceability pathways work only where there is real buyer pull, manageable verification costs, and a credible chain of custody — assumed price premiums are a red flag",
            "Sources consistently warn against assuming automatic premiums; pathways are stronger on access/reputational security than on revenue",
            "Poorly designed schemes exclude smaller operators and impose high compliance costs",
            "Pathway should be conditional and pilot-scale — not a default corridor finance pillar",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["F_03"],
        "risks_and_guardrails": [
            {"risk": "Overpromising premiums or access benefits",
             "guardrail": "Treat market upside as conditional and evidence-based, not assumed"},
            {"risk": "Excluding small-scale operators through high documentation costs",
             "guardrail": "Use proportionate requirements and shared support tools"},
            {"risk": "Corridor branding used without credible verification",
             "guardrail": "Separate communication claims from auditable standards"},
            {"risk": "Duplicating existing traceability/reporting systems",
             "guardrail": "Align with existing legal and buyer requirements first"},
            {"risk": "High verification costs with little market payoff",
             "guardrail": "Only proceed where buyer pull and product/service fit are demonstrable"},
            {"risk": "Greenwashing",
             "guardrail": "Independent auditing + published criteria + revocation rules on non-compliance"},
            {"risk": "Burden with no payoff",
             "guardrail": "Launch only with documented buyer pull and a costed uptake plan (\"buyer-pull gate\")"},
        ],
        "use_in_impact_assessment": "Use under S4 (or as a very targeted S3 pilot) only where actual buyer demand and administrative feasibility can be demonstrated. Score modestly positive on EC (market-access option) and PI (formal pathway exists), with caution on FF (revenue claims unreliable). Treat as an optional, scenario-dependent enhancement — not a baseline assumption. Keep traceability outputs as process metrics (verified lots, rejection rates), separate from ecological-outcome indicators.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #14",
            "FAO national seafood traceability guidance",
            "OECD seafood certification literature",
            "World Bank blue-economy / seafood value-chain materials",
        ],
    },
    # ----- mac_15: Maritime transport risk-reduction implementation support -----
    {
        "id": "mac_15_maritime_transport_routing",
        "name": "Maritime transport risk-reduction implementation support",
        "cost_profile": "recurring",
        "what_it_funds": "Operational rollout of corridor-relevant shipping risk-reduction measures: risk zoning, traffic analysis, AIS-based monitoring, routeing/speed feasibility work, stakeholder consultation with maritime authorities and operators, communication products, mariner guidance, seasonal bulletins, and coordination with competent maritime authorities. Aim is making traffic safer, more predictable, and more targeted in high-risk areas — not stopping traffic.",
        "finance_flow": {
            "payer": [
                "public maritime / biodiversity / corridor implementation budgets",
                "service contracts (analytics + AIS providers)",
                "optional regional/EU support",
            ],
            "receiver": "competent maritime authorities, contracted technical teams, AIS/monitoring providers, corridor coordination bodies supporting maritime implementation",
            "type": "public",
        },
        "design_parameters": [
            "Sensitive area definition and buffers agreed for the reporting year",
            "Instrument choice (recommended vs formal pursuit) made in coordination with competent maritime authorities",
            "Spatial focus: persistent hotspot vs seasonal risk zone, justified analytically",
            "Linkage to AIS monitoring built in from the start",
            "Treatment of different vessel classes proportionate to risk",
            "Compatibility with IMO-recognised instruments where formal pathway is pursued",
            "Update governance: how zones change and who signs off",
            "Separate feasibility track from implementation track to manage IMO expectations",
        ],
        "evidence_base": [
            "IMO guidance and resolutions on minimising ship strikes (routeing, reporting, speed-related operational measures)",
            "NW Mediterranean PSSA and Strait of Bonifacio PSSA — strong PSSA/routeing analogues",
            "IWC vessel-strike strategy and guidance",
            "Whale blue-corridor literature and WWF blue-corridor material on migration vs shipping risk",
        ],
        "transferable_lessons": [
            "Maritime risk-reduction works when spatially targeted, operationally feasible, and channelled through recognised maritime governance tools — not as generic environmental restriction",
            "Three practical ingredients repeat across analogues: identify recurrent high-risk overlap zones; choose proportionate routeing/reporting/speed measures; communicate via channels mariners actually use",
            "Broad untargeted slowdowns are less persuasive than targeted measures in clearly justified risk areas",
            "Awareness products without AIS-linked monitoring or formal review cycles are not used operationally",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "M_02"],
        "risks_and_guardrails": [
            {"risk": "Measures proposed without maritime governance fit or operator buy-in",
             "guardrail": "Design them with competent maritime authorities and standard maritime communication channels from the outset"},
            {"risk": "Rules are too broad and create unnecessary friction",
             "guardrail": "Target recurrent high-risk zones and use proportionate measures"},
            {"risk": "Awareness products produced but not used operationally",
             "guardrail": "Link products to AIS monitoring, seasonal bulletins, and formal review cycles"},
            {"risk": "Corridor claims outrun legal feasibility",
             "guardrail": "Distinguish clearly between voluntary guidance, national/regional operational measures, and IMO-facing instruments"},
            {"risk": "Overpromising formal IMO outcomes",
             "guardrail": "Separate feasibility track from implementation track (implementation only with competent-body agreement)"},
            {"risk": "Inconsistent/contestable zone definitions",
             "guardrail": "Agree sensitive-area sets and buffers for the reporting year + publish method note"},
        ],
        "use_in_impact_assessment": "Use under S3 and S4 where corridor scenarios assume more operational maritime measures, and under S2 in lighter form (shared risk maps + voluntary guidance). Score positively on EE (concrete risk-reduction), PI (operational implementation), and EC (efficient targeting). Pair with M_01 vessel-flows and M_02 sensitive-area overlap as primary indicator outputs. Grounds the maritime-transport component of the corridor in concrete implementation logic.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #15",
            "IMO ship-strike reduction guidance",
            "NW Mediterranean / Bonifacio PSSA examples",
            "IWC vessel-strike strategy",
        ],
    },
    # ----- mac_16: Tourism & wildlife-use standards + oversight coherence -----
    {
        "id": "mac_16_tourism_wildlife_standards",
        "name": "Tourism & wildlife-use standards + oversight coherence",
        "cost_profile": "recurring",
        "what_it_funds": "Operational layer that turns corridor-compatible tourism from soft aspiration into managed practice: codes of conduct, operator training, accreditation/certification support, harmonised reporting templates, observer or self-reporting protocols, compliance checks, shared signage/materials, and alignment of minimum oversight standards across the three archipelagos. Pairs standards with training, clear operating rules, reporting, and oversight or incentive structure.",
        "finance_flow": {
            "payer": [
                "public tourism / biodiversity / corridor implementation budgets",
                "optional earmarked tourism fees",
                "operator contributions where licensed",
            ],
            "receiver": "competent authorities, accredited training providers, oversight bodies, corridor coordination platform, contracted support providers",
            "type": "blended",
        },
        "design_parameters": [
            "Minimum standard set (distances/time, approach rules) agreed across archipelagos",
            "Voluntary vs licence-linked uptake: graduated system, not single licensing regime",
            "Species/interaction focus and training requirements clearly scoped",
            "Inspection cadence and reporting expectations using simple templates",
            "Co-design with operators to avoid backlash; phase-in timeline published with rationale",
            "Cross-archipelago consistency rules (so a Madeira operator and an Azores operator use the same minimum)",
            "Treatment of small operators with proportionate entry-level requirements + uptake support",
            "Clear separation between communication claims (corridor branding) and verified practice tiers",
        ],
        "evidence_base": [
            "ACCOBAMS whale-watching guidelines",
            "IWC whale-watching handbooks/guidance",
            "Portugal/Azores dolphin- and whale-watching rules and operator handbooks",
            "Wildlife-watching and tourism governance / certification literature",
        ],
        "transferable_lessons": [
            "Tourism standards become effective only when paired with training, clear operating rules, reporting, and some oversight or incentive — codes of conduct alone are rarely enough",
            "Uptake improves when operators see commercial or reputational value, but credibility depends on follow-up and not just branding",
            "Most transferable model is a graduated system: shared minimum rules first, then stronger accreditation/oversight where feasible",
            "Inconsistent application across archipelagos undermines credibility — adopt shared minimum standards even if licensing remains local",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "T_02", "T_03", "T_04"],
        "risks_and_guardrails": [
            {"risk": "Standards remain symbolic and are used mainly for branding",
             "guardrail": "Link them to training, reporting and at least minimum oversight"},
            {"risk": "Inconsistent application across archipelagos undermines credibility",
             "guardrail": "Adopt shared minimum standards and a common reporting core, even if licensing remains local"},
            {"risk": "Small/local operators are excluded by costly accreditation",
             "guardrail": "Keep entry-level requirements proportionate and provide support for uptake"},
            {"risk": "Corridor branding outpaces actual performance",
             "guardrail": "Separate communication claims from verified practice tiers"},
            {"risk": "\"Soft aspiration\" without teeth",
             "guardrail": "Link standards to licensing/accreditation and fund a minimum oversight cadence plus reporting"},
            {"risk": "Operator backlash to new standards",
             "guardrail": "Co-design + phase-in timeline + publish \"why this rule exists\" guidance"},
        ],
        "use_in_impact_assessment": "Use across all scenarios, escalating intensity from S2 (shared guidance) → S3 (harmonised standards + reporting) → S4 (consistent regional practice with clearer oversight linkages). Score positively on EE (reduces wildlife disturbance), PI (concrete implementation pathway), EQ (small-operator inclusion), and EC (efficient industry-aligned delivery). Pair with T_03 wildlife-watch participation and T_02/T_04 carefully — tourism mechanism changes operator practice, not directly revenue/jobs.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #16",
            "ACCOBAMS whale-watching guidelines",
            "IWC whale-watching guidance",
            "Portugal/Azores dolphin- and whale-watching rules",
        ],
    },
    # Additional Macaronesia mechanisms appended by Task D1
]

TUSCAN_MECHANISMS = [
    # ----- tus_01: Payment for Ecosystem Services (PES) for Posidonia conservation -----
    {
        "id": "tus_01_pes_posidonia",
        "name": "Payment for Ecosystem Services (PES) for Posidonia conservation",
        "cost_profile": "recurring",
        "what_it_funds": "Direct compensation to fishers, dive operators, and coastal landowners for verifiable conservation actions protecting Posidonia oceanica meadows (e.g., gear modifications, anchoring restrictions, no-take agreements).",
        "finance_flow": {
            "payer": ["regional MPA authority", "EU LIFE / EMFAF co-funding", "tourism operator levies"],
            "receiver": "individual fishers / cooperatives / landowners",
            "type": "blended",
        },
        "design_parameters": [
            "Verifiable on-water actions tied to monitoring data (not self-reported)",
            "Annual payment cycle aligned with fishing season",
            "Eligibility floor: minimum patch area protected per recipient",
            "Sunset clause: 5-year cycle with renewal contingent on biophysical outcomes",
        ],
        "evidence_base": [
            "Costa Rica Pago por Servicios Ambientales (operational precedent)",
            "Mediterranean Posidonia restoration trials (Boudouresque et al., site-specific)",
        ],
        "transferable_lessons": [
            "Self-reported actions reduce political cost but degrade outcomes; tie payments to monitoring data",
            "Cooperatives administer payments more efficiently than per-vessel transfers",
            "Tourism levy tolerated when receipts are visibly earmarked for marine conservation",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Adverse selection — only low-effort fishers enroll",
             "guardrail": "Eligibility floor + onboarding workshop on actions required"},
            {"risk": "Greenwashing if monitoring is weak",
             "guardrail": "Independent verification by MPA scientific staff or contracted institute"},
        ],
        "use_in_impact_assessment": "Use when scoring a Tuscan scenario that depends on voluntary fisher cooperation (S2 Light or S3 Coordinated). Score positively on EQ (compensates affected fishers) and EE (when monitoring is robust). Pair with POS_density biophysical indicator.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x Financial mechanisms"],
    },
    # ----- tus_02: Mooring-buoy permit fee (partner-pickable default) -----
    {
        "id": "tus_02_mooring_buoy_permit",
        "name": "Mooring-buoy permit fee",
        "cost_profile": "recurring",
        "what_it_funds": "Installation, maintenance, and enforcement of mooring buoys protecting Posidonia meadows from anchor damage, financed by per-vessel permit fees.",
        "finance_flow": {
            "payer": ["recreational and commercial vessels operating in Tuscan MPA waters"],
            "receiver": "MPA management body / contracted maintenance operator",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Mandatory mooring (anchoring banned) inside designated meadow zones",
            "Permit price covers maintenance cost + 20% reserve",
            "Online permit purchase with automated boundary enforcement via AIS",
        ],
        "evidence_base": [
            "Mediterranean MPA mooring-buoy systems (multiple operational precedents)",
        ],
        "transferable_lessons": [
            "Mandatory mooring works only with credible enforcement; voluntary systems fail",
            "AIS-based boundary enforcement is cheaper than patrol vessels for small MPAs",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Insufficient buoy density forces anchoring outside designated zones",
             "guardrail": "Capacity sized to peak summer demand × 1.2"},
        ],
        "use_in_impact_assessment": "Use for any Tuscan scenario protecting Posidonia. Score strongly positive on EE.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x"],
    },
    # Additional Tuscan mechanisms appended by Task D2
    # ----- tus_03: Public funding and grants (baseline financing) -----
    {
        "id": "tus_03_public_grants",
        "name": "Public funding and grants (EU / national / regional)",
        "cost_profile": "time_limited",
        "what_it_funds": "Capital expenditure for restoration works, eco-mooring installation, mapping and monitoring infrastructure, and pilot interventions in the Tuscan DA. Drawn from EU programmes (LIFE, EMFAF, Horizon, Interreg), Italian national environmental ministries, and Tuscany regional administrations. Acts as the baseline financing layer for initial investments but does not cover long-term operational costs.",
        "finance_flow": {
            "payer": ["EU funding programmes (LIFE, EMFAF, Horizon, Interreg)", "Italian Ministry of Environment", "Tuscany Regional Government"],
            "receiver": "Tuscan Archipelago National Park / MPA management bodies / partner research institutes",
            "type": "public",
        },
        "design_parameters": [
            "Project-cycle financing (typically 3-5 years) requiring co-financing from beneficiaries",
            "Earmarked for capital expenditure (restoration works, eco-moorings, monitoring infrastructure) rather than recurrent O&M",
            "Competitive call-based access requiring multi-partner consortia and technical proposals",
            "Reporting and audit obligations aligned to funder rules (cost eligibility, public procurement)",
        ],
        "evidence_base": [
            "RESTORE4Cs D1.2 (Kampa et al., 2025): EU and national public funds identified as primary source of restoration finance across Europe",
            "Ciravegna (2025) RESTORE4Cs Policy Brief: documents short funding cycles and limited coverage of long-term operational costs",
        ],
        "transferable_lessons": [
            "Public grants reliably finance capital outlays but leave a financing gap once project ends — design exit strategy at proposal stage",
            "Stacking multiple grant cycles creates administrative overhead that can exceed staff capacity in small MPAs",
            "Co-financing requirements push partner authorities to commit budget early, anchoring political ownership",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Funding cliff at project end leaves restored assets unmaintained",
             "guardrail": "Mandate operational financing plan (fees / PES / PPP) as deliverable in grant proposal"},
            {"risk": "Mismatch between funder reporting cycles and ecosystem recovery timescales",
             "guardrail": "Negotiate multi-phase funding or chain successive grants with explicit hand-over"},
        ],
        "use_in_impact_assessment": "Use as baseline financing layer for any Tuscan scenario requiring capital investment (S1 BAU, S2 Light, S3 Coordinated). Score positively on EE for the investment phase but neutral-to-negative on long-run sustainability unless paired with a recurring mechanism (tus_01, tus_02, tus_04). Critical for kicking off any restoration intervention.",
        "references": ["MarineSABRES D5.2 Tuscan DA, mechanism #3", "RESTORE4Cs D1.2 (Kampa et al., 2025)", "Ciravegna (2025) RESTORE4Cs Policy Brief"],
    },
    # ----- tus_04: Concession fees for commercial operators -----
    {
        "id": "tus_04_concession_fees",
        "name": "Concession fees for commercial operators (diving, excursion, tourism services)",
        "cost_profile": "recurring",
        "what_it_funds": "Annual or seasonal concession charges paid by commercial operators (diving schools, excursion boats, marina concessionaires, guided tour providers) for the right to operate within the protected area. Revenue funds monitoring, enforcement, visitor management, and maintenance activities by the MPA management body.",
        "finance_flow": {
            "payer": ["diving and snorkelling operators", "excursion and ferry operators", "marina concessionaires", "guided tourism providers"],
            "receiver": "Tuscan Archipelago National Park / MPA management body",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Tiered pricing by operator type and intensity of use (vessel size, passenger capacity, dive frequency)",
            "Multi-year concession contracts with annual fee indexation linked to inflation or visitor pressure",
            "Revenue earmarking clause channelling fees back to MPA monitoring and enforcement budget",
            "Performance conditions (training, code of conduct, reporting of incidents) tied to renewal",
        ],
        "evidence_base": [
            "RESTORE4Cs D1.2 (Kampa et al., 2025): user fees and charges identified as key tool for long-term maintenance of restored ecosystems where pressures are linked to specific user groups",
            "Lago (2025) RESTORE4Cs presentation: concession fees provide stable revenue streams in European MPAs",
        ],
        "transferable_lessons": [
            "Fee acceptance hinges on perceived fairness — link price to visitor pressure or vessel capacity, not flat rates",
            "Revenue earmarking is essential; fees that disappear into general treasury lose operator support",
            "Tying renewal to performance (e.g., code of conduct compliance) leverages fees beyond pure revenue",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Italian / Tuscan legal constraints prevent revenue earmarking back to the MPA",
             "guardrail": "Confirm legal basis for earmarking before launch; structure as park-managed concession contracts where direct fee earmarking is prohibited"},
            {"risk": "High fees displace small operators in favour of large incumbents, narrowing local economic base",
             "guardrail": "Differentiated pricing tiers and reduced rates for small / artisanal operators"},
        ],
        "use_in_impact_assessment": "Use for any Tuscan scenario where commercial tourism operators are present (S2 Light, S3 Coordinated). Score positive on EE (recurrent funding for management) and mixed on EQ (depends on whether small operators are protected via tier structure). Complement to tus_02 mooring fees by capturing commercial use distinct from individual recreational vessels.",
        "references": ["MarineSABRES D5.2 Tuscan DA, mechanism #4", "RESTORE4Cs D1.2 (Kampa et al., 2025)", "Lago (2025) RESTORE4Cs EU Policy Workshop presentation"],
    },
]

ARCTIC_MECHANISMS = [
    # ----- arc_01: Cost-recovery fees on quota holders -----
    {
        "id": "arc_01_cost_recovery_fees",
        "name": "Cost-recovery fees on quota holders",
        "cost_profile": "recurring",
        "what_it_funds": "Enforcement, observer programmes, and stock-assessment science in the Arctic Northeast Atlantic, financed by per-tonne or per-vessel fees levied on quota holders.",
        "finance_flow": {
            "payer": ["quota holders (commercial fishing operators)"],
            "receiver": "national fisheries authorities (NO, IS, FO, RU); ICES/NEAFC scientific programmes",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Fee scaled by landed value, not landed tonnage (better tracks effort to value)",
            "Earmarked use: science + enforcement; not general treasury",
            "Annual fee adjustment via published methodology to avoid political volatility",
            "Reduced fee for vessels carrying observers / electronic monitoring",
        ],
        "evidence_base": [
            "Iceland fisheries fee (operational precedent since 2012)",
            "OECD Sustainable Fisheries report (2022) on cost-recovery best practice",
        ],
        "transferable_lessons": [
            "Public earmark builds quota-holder political tolerance",
            "Per-value (not per-tonne) fees survive price-shock years better",
            "Fee discount for monitoring-equipped vessels accelerates adoption",
        ],
        "applies_to_DAs": ["arctic"],
        "success_metrics": [],
        "risks_and_guardrails": [
            {"risk": "Fees become a general revenue grab",
             "guardrail": "Earmarked use legislated, not just administrative"},
            {"risk": "Race-to-the-bottom across jurisdictions",
             "guardrail": "Coordinated minimum fee floor under NEAFC framework"},
        ],
        "use_in_impact_assessment": "Use when scoring an Arctic scenario where enforcement and science capacity are the binding constraint (Partial or Full Agreement). Score positively on EC (efficient cost recovery) and FF (sustained funding). Pair with stock-status indicators in later phases.",
        "references": ["MarineSABRES D5.2 Arctic DA, §x.x Financial mechanisms", "OECD Sustainable Fisheries (2022)"],
    },
    # Additional Arctic mechanisms appended by Task D3
]

VALUATION_UNIT_VALUES = {
    "posidonia_oceanica": {
        "coastal_protection":   {"low": 3500,  "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost"},
        "carbon_sequestration": {"low": 40,    "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon"},
        "recreation_tourism":   {"low": 400,   "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP"},
        "food_provision":       {"low": 150,   "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing"},
        "water_purification":   {"low": 350,   "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost"},
    },
    "restoration_costs": {
        "posidonia_oceanica": {"low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60},
    },
}

# ============================================================================
# BUILD
# ============================================================================

def build_kb():
    return {
        "version": "1.0.0",
        "description": "WP5 financial and implementation mechanisms catalogue (Marine SABRES Deliverable 5.2). Mechanisms are indexed by Demonstration Area; each mechanism follows a fixed 10-attribute structure mirroring the Blue Corridor toolkit annex. Bundled `valuation_unit_values` carries Tuscan Posidonia oceanica benefit-transfer estimates consumed by the Phase 2 valuation calculator.",
        "last_updated": str(date.today()),
        "source_documents": SOURCE_DOCS,
        "source_commit": SOURCE_COMMIT,
        "demonstration_areas": {
            "macaronesia": {
                "description": "Blue Corridor (EEZ + ABNJ); cross-jurisdictional MPA network spanning Azores-Madeira-Canary Islands, with mechanisms supporting coordinated monitoring, enforcement, and connectivity-preserving fisheries management.",
                "mechanisms": MACARONESIA_MECHANISMS,
            },
            "tuscan": {
                "description": "Tuscan Archipelago National Park; mechanisms supporting Posidonia oceanica meadow protection, restoration, and enforcement against anchoring and trawling damage.",
                "mechanisms": TUSCAN_MECHANISMS,
            },
            "arctic": {
                "description": "Arctic Northeast Atlantic; mechanisms supporting quota allocation, enforcement, and incentive design for sustainable fisheries under ICES/NEAFC governance.",
                "mechanisms": ARCTIC_MECHANISMS,
            },
        },
        "valuation_unit_values": VALUATION_UNIT_VALUES,
    }


def main():
    kb = build_kb()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(kb, f, ensure_ascii=False, indent=2)
    print(f"[build_wp5_mechanisms_kb] wrote {OUT_PATH} "
          f"(macaronesia={len(MACARONESIA_MECHANISMS)}, "
          f"tuscan={len(TUSCAN_MECHANISMS)}, "
          f"arctic={len(ARCTIC_MECHANISMS)})")


if __name__ == "__main__":
    main()
