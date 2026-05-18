# Research Outputs — MarineSABRES SES Toolbox

This file indexes the publications, conference materials, validation
documents, and reproducibility scripts that report on or back the
MarineSABRES SES Toolbox. It is updated as outputs land.

---

## Currently active

### ESP 2026 conference submission (May 2026)

**Title:** *Machine Learning from Stakeholder Knowledge: AI-Enhanced
Social-Ecological Systems Modelling for Marine Ecosystem Services.*

**Authors:** Arturas Razinkovas-Baziukas (KU), Gemma Smith (IECS/Hull),
Mike Elliott (IECS/Hull).

**Status:** v3 abstract submitted; presentation deck in preparation.

**Submission files** (in the `MARBEFES/ESP2026/` companion folder
outside this repo):

| File | Purpose |
|---|---|
| `abstract_Razinkovas_et_al_v3.docx` | Submitted abstract (389 words, 8 ML components, in silico numbers) |
| `abstract_Razinkovas_et_al_v3.md` | Markdown source |
| `presentation_content_v3.md/.docx` | Slide-by-slide content for the deck |
| `presentation_numbers_quickref.md/.docx` | One-page numerical cheat-sheet |
| `demo_storyboard.md/.docx` | 5-minute live-demo script |
| `slides_outline.md/.docx` | Earlier outline draft (superseded by content pack) |
| `qa_prep.md/.docx` | Anticipated Q&A by audience type |
| `AI_SES_ModellingV4.pptx` | pandoc-generated skeleton deck (build on top) |

**Earlier abstract revisions** (kept as historical record):

| File | Notes |
|---|---|
| `abstract_Razinkovas_et_al.docx` | Original v1 (the one ESP first received) |
| `abstract_Razinkovas_et_al_v2.md/.docx` | Conservative 5-component rewrite (kept as fallback) |
| `Machine leaning abstract_Razinkovas_et_al.docx` | Initial draft (predecessor to v1) |

### Numbers in the submission and where they come from

| Claim in the v3 abstract | Source file in this repo |
|---|---|
| 3 demo regions, 11 contexts, 412 connections, 33 contexts / 1185 connections | `scripts/count_kb_demo_regions.py` (Python; reads `data/ses_knowledge_db.json`) |
| Connection-recovery lift +100% (mean 0.031 → 0.100) | `scripts/simulate_non_expert_users.R` → `data/in_silico_user_simulation.rds` |
| Consistency lift +396% (Jaccard 0.110 → 0.502) | `scripts/cross_template_consistency.R` → `data/in_silico_consistency.rds` |
| Spearman ρ = 0.054, p = 0.039 | `scripts/bibliometric_validation.R` → `data/in_silico_bibliometric.rds` |
| Methods paragraph (the 8 components) | `docs/ML_METHODS.md` |
| Retrospective precision@k (back-pocket only) | `docs/RETROSPECTIVE_VALIDATION.md`, `data/retrospective_validation_gnn_results.rds` |

---

## Validation documents

| Doc | What it contains |
|---|---|
| [`ML_METHODS.md`](ML_METHODS.md) | Paper-ready description of the 8 ML components with honest "what this is NOT" section |
| [`RETROSPECTIVE_VALIDATION.md`](RETROSPECTIVE_VALIDATION.md) | precision@k / recall@k for v1.14.0 base vs v1.15.0 GNN |
| [`IN_SILICO_VALIDATION.md`](IN_SILICO_VALIDATION.md) | Three in silico analyses (recovery, consistency, bibliometric) backing the ESP 2026 abstract numbers |
| [`ml_pilot_protocol.md`](ml_pilot_protocol.md) | Pilot study design — primary/secondary outcomes, hypotheses, analysis plan |
| [`ml_pilot_consent_form.md`](ml_pilot_consent_form.md) | Participant information sheet + consent |

---

## Reproducibility recipes

All training, validation, and analysis is reproducible from this repo
with deterministic seeds (`set.seed(42)`):

```bash
# Knowledge base summary numbers
micromamba run -n shiny python scripts/count_kb_demo_regions.py

# ML training (v1.14.0 + v1.15.0)
Rscript scripts/train_connection_predictor.R
Rscript scripts/train_connection_predictor_gnn.R
Rscript scripts/train_ensemble_models.R
Rscript scripts/fine_tune_for_template.R "Macaronesia"

# BERT element classifier
micromamba run -n shiny python scripts/extract_classifier_training_data.py
Rscript scripts/train_element_classifier.R

# Warm-start bandit + CF
Rscript scripts/warm_start_response_bandit.R
Rscript scripts/warm_start_cf.R

# Validation (numbers for the abstract)
Rscript scripts/retrospective_validation.R          # v1.14.0 base only
Rscript scripts/retrospective_validation_gnn.R      # base vs GNN
Rscript scripts/simulate_non_expert_users.R         # recovery lift
Rscript scripts/cross_template_consistency.R        # consistency lift
Rscript scripts/bibliometric_validation.R           # literature calibration

# Re-checksum shipped weights
Rscript scripts/generate_model_checksums.R
```

Each script writes its output to `data/` or `models/` and an updated
Markdown summary to `docs/`. The RDS output files are committed and
loadable directly into R for reviewer inspection.

---

## Pilot study (instrumented, not yet executed)

The toolbox is instrumented to capture pilot-study session data via
`modules/pilot_study_module.R`, which activates on
`?pilot_condition=A|B` URL parameters. Per-session payloads are
written to `data/pilot/<hashed_pid>__<condition>__<iso>.json` and can
be analysed with `scripts/pilot_analysis.R`. No PII is captured.

Execution gate: ethics clearance (KU Bioethics + UH light-touch),
recruitment of 8-12 non-expert participants, two sessions per
participant with 1-week washout. See
[`ml_pilot_protocol.md`](ml_pilot_protocol.md) for the full design.

---

## Earlier outputs

- v1.13.x reliability and i18n hardening — internal release notes only.
- v1.11.0 KB & template overhaul — referenced from `CHANGELOG.md`.
- v1.10.0 KB quality review (213 scientific corrections) — referenced
  from `CHANGELOG.md`.

---

## How to cite the toolbox

When citing the toolbox in academic work, please use:

> Razinkovas-Baziukas, A., Smith, G., & Elliott, M. (2026). *MarineSABRES
> SES Toolbox v1.15.0: Machine Learning from Stakeholder Knowledge for
> Marine Social-Ecological Systems.* Klaipeda University / IECS Ltd /
> University of Hull. https://github.com/razinkele/SESTool

For the ESP 2026 abstract specifically:

> Razinkovas-Baziukas, A., Smith, G., & Elliott, M. (2026). Machine
> Learning from Stakeholder Knowledge: AI-Enhanced Social-Ecological
> Systems Modelling for Marine Ecosystem Services. *Proceedings of the
> Ecosystem Services Partnership 2026 Conference* (forthcoming).
