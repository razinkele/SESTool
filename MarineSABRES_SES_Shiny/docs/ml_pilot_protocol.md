# ML Pilot Study Protocol — MarineSABRES SES Toolbox

**Version:** 1.0
**Date:** 2026-05-17
**PI:** Arturas Razinkovas-Baziukas (Marine Research Institute, Klaipeda University)
**Co-investigators:** Gemma Smith (IECS / Univ. Hull), Mike Elliott (IECS / Univ. Hull)

This protocol governs the small-N pilot study that backs the
ESP 2026 abstract claim:
> "non-experts can now generate scientifically robust SES models,
> identifying [X]% more relevant connections and achieving [Y]% greater
> consistency across users."

Until this protocol is executed and analyzed, the abstract's [X] and [Y]
numbers are placeholders. The pilot produces them.

## Research question

Does the v1.15.0 ML-augmented MarineSABRES SES Toolbox, compared to a
baseline version without ML suggestions, help a non-expert user produce a
more complete and more consistent SES model in a fixed time?

## Design

**Within-subjects crossover** with one-week washout, condition order
randomized 50/50 across participants.

- **Condition A (baseline):** toolbox with all UI features EXCEPT the
  ML-suggestion panel, the connection-prediction badges, and the
  collaborative-filtering "users also added" widget. Implemented via
  the `?pilot_condition=A` URL flag, which sets a session-level
  `pilot_ml_disabled = TRUE` reactive read by all ML-consuming modules.
- **Condition B (ML-augmented):** toolbox identical to the public
  v1.15.0+ release. URL flag `?pilot_condition=B`.

**Task per session.** Build a Mediterranean coastal-lagoon SES model
from scratch. Participants are given:

- A one-page problem description (provided as a PDF handed to them
  before the session — not loaded into the toolbox).
- A printed glossary of DAPSI(W)R(M) categories with one example each.
- 45 minutes wall-clock.
- The instruction: "produce as complete a model as you can, with the
  goal that another team could use it to start a stakeholder discussion."

**Participants.** N = 8 to 12. Recruited from:

- MarineSABRES / MARBEFES consortium early-career researchers (4-6)
- External researchers from EU marine-policy / ecosystem-services
  networks (4-6)

Eligibility: self-rated familiarity with DAPSI(W)R(M) of 1-3 on a 1-7
scale (i.e., non-expert). Background in ecology / environmental science /
marine policy. Comfortable working in English.

Exclusions: prior contributors to the KB; current employees of
Klaipeda University Marine Research Institute, IECS, or University of
Hull (to keep the sample independent).

## Primary and secondary outcomes

**Primary outcomes** (one number each per session):

1. `n_connections_final` — total connections in the saved final model.
2. `iou_with_reference` — intersection-over-union of the participant's
   element set against the consortium's pre-validated Mediterranean
   lagoon reference template. Tokenized matching on element names with
   fuzzy threshold 0.85 cosine similarity (sentence-transformer encoder).
3. `time_to_first_complete` — minutes from session start to the first
   save event where `n_elements ≥ 5 AND n_connections ≥ 3` (heuristic
   for "first usable draft").

**Secondary outcomes:**

4. `nasa_tlx_overall` — mean of the six TLX sub-scales (mental, physical,
   temporal, performance, effort, frustration), 0-100.
5. `n_element_categories_used` — count of distinct DAPSI(W)R(M)
   categories appearing in the final model (out of 7).
6. `polarity_balance` — ratio of positive vs. negative connection
   polarities (a proxy for nuanced modelling).

## Hypotheses

- **H1 (primary):** μ(n_connections_final | B) > μ(n_connections_final | A).
- **H2 (primary):** μ(iou_with_reference | B) > μ(iou_with_reference | A).
- **H3 (primary):** μ(time_to_first_complete | B) < μ(time_to_first_complete | A).

Two-sided paired Wilcoxon signed-rank tests with Bonferroni correction
across the three primary hypotheses (α_corrected = 0.0167).

Given expected N = 8-12 and a known small-sample limitation, results
are reported with 95% confidence intervals on the median paired
difference rather than as point-null significance only.

## Schedule

| Phase | Duration | Notes |
|---|---|---|
| Ethics clearance | 1-2 weeks | KU Bioethics + UH light-touch |
| Recruitment | 2 weeks | Consortium mailing + 2 external invitations |
| Sessions (per participant) | 2 × 60 min, 1 week apart | 45-min task + 15-min onboarding/TLX |
| Analysis + writeup | 1 week | `scripts/pilot_analysis.R` produces the numbers |

## Materials handed to participants

- Information sheet + consent form (see `docs/ml_pilot_consent_form.md`).
- Problem description PDF: "Coastal Lagoon X, Mediterranean — outline an
  SES model focusing on fisheries, tourism, and eutrophication."
- DAPSI(W)R(M) one-page glossary.
- URL with their pre-randomized condition and participant ID:
  `https://laguna.ku.lt/marinesabres/?pilot_condition=A&pid=<assigned id>`
  (or `=B`).

## Data captured

For each session, the `modules/pilot_study_module.R` module writes one
JSON file to `data/pilot/<participant_id_hash>__<condition>__<iso>.json`.
Schema:

```json
{
  "participant_id":           "<first 12 chars of sha256(pid)>",
  "condition":                "A" | "B",
  "t_session_start":          "ISO8601",
  "t_session_end":            "ISO8601",
  "t_first_save":             "ISO8601" | null,
  "n_first_save_elements":    integer,
  "n_first_save_connections": integer,
  "saves":                    [ {"t":"...","n_elements":int,"n_connections":int}, ... ],
  "nasa_tlx": {
    "mental": 0-100, "physical": 0-100, "temporal": 0-100,
    "performance": 0-100, "effort": 0-100, "frustration": 0-100
  },
  "toolbox_version":          "1.15.0+",
  "locale":                   "laguna.ku.lt"
}
```

The participant's saved-project JSON is also exported separately for the
IoU computation.

## Privacy

- The participant ID written to disk is **sha256-hashed** at the toolbox
  boundary; the raw ID never leaves the participant's URL.
- No email, name, or other PII is captured in the pilot file.
- Mapping from real participant identity to the hashed ID is kept in a
  separate password-protected spreadsheet by the PI and is destroyed
  after the analysis is complete.
- Aggregate statistics only are reported in the abstract / paper.
  Individual-participant data is not published.

## Analysis pipeline

Implemented in `scripts/pilot_analysis.R` (to be added):

1. Glob `data/pilot/*.json`.
2. Join each participant's two sessions on `participant_id`, verify
   both A and B are present.
3. Compute primary + secondary outcomes per session.
4. Compute paired differences (B - A) per participant.
5. Wilcoxon signed-rank tests with Bonferroni correction.
6. Bootstrap 95% CIs (10 000 resamples) on the median paired difference.
7. Produce `docs/PILOT_RESULTS.md` with a per-outcome table and
   per-participant scatter plots.

## Out of scope

- This pilot does NOT measure long-term retention or model quality over
  multiple stakeholder iterations.
- This pilot does NOT compare the toolbox to a paper-and-pencil
  baseline.
- This pilot does NOT generalize to ESP 2026 audience-sized populations.
  Results inform method development; large-N validation is future work.

## Authorship and reporting

Pilot results, including null and negative findings, will be reported
faithfully in the ESP 2026 abstract revision, the conference
presentation, and any subsequent paper. If primary hypotheses are not
supported, the abstract numbers will be corrected before the conference.
