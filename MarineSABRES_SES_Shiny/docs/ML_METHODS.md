# ML Methods — MarineSABRES SES Toolbox

This document is the paper-ready summary of the machine-learning pipeline shipped with the MarineSABRES SES Toolbox, intended to back the methods section of the ESP 2026 abstract and presentation. It describes the components actually present in the v1.14.0+ codebase — not aspirational targets.

## Pipeline overview

```
KB connections + element attrs
        │
        ▼
[ Feature Engineering ]    ── functions/ml_feature_engineering.R
        │   (358-dim vectors per (source, target) pair:
        │    element-name tokens, DAPSIWRM type one-hot,
        │    context one-hot, polarity priors, strength priors)
        ▼
[ Graph Feature Augmentation ]   ── functions/ml_graph_features.R
        │   (+8 dims: degree centrality, betweenness, shortest-path
        │    distance, DAPSIWRM framework-compliance flag)
        ▼
[ Connection Predictor (deep NN) ]   ── functions/ml_models.R + scripts/train_connection_predictor.R
        │   Multi-task head:
        │     • existence (binary)
        │     • strength (3-way: weak/medium/strong)
        │     • confidence (1-5)
        │     • polarity (+/-)
        ▼
[ Ensemble + Active Learning ]   ── functions/ml_ensemble.R + scripts/train_ensemble_models.R
            (N models with different seeds; mean prediction;
             inter-model disagreement → active-learning sample selection)
```

## Component-by-component

### 1. Feature engineering (`functions/ml_feature_engineering.R`)

Each candidate connection between two SES elements is encoded as a 358-dimension vector covering:

- **Element-name embedding** (~128 dims) — currently vocabulary-based marine-domain matching, with optional transformer embeddings via the `text` package (added in v1.14.0). Strategy is selectable via `MARINESABRES_EMBEDDING_STRATEGY` env var; defaults to `"transformer"` when the `text` package and a sentence-transformer model are available, otherwise falls back to vocabulary matching.
- **DAPSIWRM type one-hot** (14 dims, source + target) — categorical encoding of which framework category each element belongs to.
- **Context one-hot** (encoded; expanded with learned context embeddings in `ml_context_embeddings.R` for Phase 2 — 88-dim raw → 36-dim learned).
- **Polarity prior, strength prior, temporal-lag prior, reversibility prior** — derived from the connections in the KB that share the same source/target type pair.

### 2. Graph-structural features (`functions/ml_graph_features.R`)

For each candidate connection in the context of the user's in-progress SES model, eight additional features are extracted via `igraph`:

- Source and target degree centrality
- Source and target betweenness centrality
- Shortest-path distance between source and target in the current partial graph
- Component-connectivity flag (1 if currently in the same connected component)
- DAPSIWRM framework-compliance flag (1 if the proposed source-type → target-type edge is one of the framework's permitted transitions; 0 otherwise)
- Reciprocity flag (1 if a reverse edge already exists in the current graph)

These features let the model reason about the topology of the user's current model rather than only the names of the two elements. They are concatenated onto the 358-dim base vector for the Phase 2 enhanced model (314-dim trimmed input + 8 graph dims = 322-dim effective). This is **graph-structural feature engineering** — not a graph neural network in the GNN-architecture sense.

### 3. Connection predictor neural network (`functions/ml_models.R`)

A torch (>= 0.17) multi-task feedforward network:

- **Input:** 358 dims (Phase 1) or 314 dims (Phase 2 with learned context embeddings)
- **Hidden:** 256 units, dropout 0.3
- **Output heads (4):**
  1. **Existence** — sigmoid over a single unit; binary cross-entropy loss
  2. **Strength** — softmax over 3 classes (weak/medium/strong); cross-entropy
  3. **Confidence** — single regression output (1-5); mean-squared-error
  4. **Polarity** — sigmoid over a single unit (-/+); binary cross-entropy

Training uses Adam (lr=1e-3), batch size 32, max 100 epochs with patience-10 early stopping on validation loss.

The v1.14.0 base checkpoint (`models/connection_predictor_best.pt`) was trained on 569 examples derived from the 7 production SES templates (Coastal Lagoon, Caribbean Island, Climate Change, Fisheries, Offshore Wind Energy, Pollution, Tourism). Stratified 70/15/15 train/val/test split, 301 positive examples (existing connections), 268 negative (random non-connected element pairs).

### 4. Ensemble + active learning (`functions/ml_ensemble.R`)

The ensemble is `N` (default 5; v1.14.0 ships 3) base models trained from different random seeds and saved as `models/ensemble/model_<i>_seed<S>.pt`. At inference time, predictions are averaged across the ensemble. Disagreement (max-prob minus mean-prob across models for each candidate) is used as an uncertainty signal:

- **For users:** the UI shows a "low confidence" badge on ML-suggested connections with high inter-model disagreement.
- **For active learning:** `ml_active_learning.R` consumes the disagreement signal to rank unlabeled candidate connections by expected information gain; the top-k are surfaced to the human-in-the-loop interface for explicit confirmation/rejection.

### 5. Transfer learning (`functions/ml_template_matching.R` + `scripts/fine_tune_for_template.R`)

When a user starts a new SES from a template, the system:

1. Scores the new template's regional and ecosystem context against existing templates via `ml_template_matching.R` (regional overlap, ecosystem overlap, focal-issue overlap, vocabulary overlap, size similarity, DAPSIWRM-type distribution similarity).
2. Picks the most similar template's fine-tuned model as the starting checkpoint.
3. Fine-tunes on the new template's known connections at a reduced learning rate (similarity-guided: high similarity → larger LR + fewer frozen layers, low similarity → smaller LR + more frozen layers).

`models/fine_tuned/<template_name>.pt` checkpoints ship for each of the three abstract-named demonstration regions (Macaronesia, Arctic, Mediterranean).

### 6. Vocabulary/transformer text embeddings (`functions/ml_text_embeddings.R`)

Three swappable strategies for encoding element-name strings:

| Strategy | Source | When chosen |
|---|---|---|
| `vocabulary` (legacy default) | Marine-domain vocabulary lookup with subword tokens for OOV | Fallback; used when no transformer model is available |
| `fasttext` | Pretrained FastText embeddings (300-dim) | When `fastTextR` is installed and an embedding file is loaded |
| `transformer` (v1.14.0 default) | Sentence-transformer encoder via R `text` package (e.g., `all-MiniLM-L6-v2`, 384-dim) | When `text` package is available |

Strategy selected via `MARINESABRES_EMBEDDING_STRATEGY` env var; resolved at startup in `global.R`. Caching layer in `ml_feature_cache.R` memoizes per-element vectors so the transformer is only called once per unique element name.

## Validation

Two evaluation paths:

### Retrospective precision@k on existing templates

For each of the 7 production templates, mask 10% of the known connections, run the pipeline on the remaining structure, and measure recall@k for the masked connections among the top-k predicted candidates per element. Implementation: `scripts/retrospective_validation.R` (v1.14.0).

### Pilot study (in preparation)

Small N=5-10 user study comparing baseline (no ML suggestions) vs. v1.14.0 (with ML suggestions) on a fixed task: build a Mediterranean lagoon SES model from scratch. Metrics:

- Time to first complete model
- Number of connections in final model
- Overlap (intersection-over-union) with a reference model built by a domain expert
- User self-reported workload (NASA-TLX)

Pilot protocol and consent forms in `docs/ml_pilot_protocol.md`.

## Reproducibility

- Training data extraction: `Rscript scripts/extract_training_data.R` — produces `data/ml_training_data.rds` from the 7 templates.
- Base model training: `Rscript scripts/train_connection_predictor.R` — produces `models/connection_predictor_best.pt`, `connection_predictor_final.pt`, and `training_history.rds`.
- Ensemble training: `Rscript scripts/train_ensemble_models.R N` — produces `models/ensemble/model_*.pt`.
- Fine-tuning: `Rscript scripts/fine_tune_for_template.R <template_name>` — produces `models/fine_tuned/<template_name>.pt`.
- Checksum regeneration: `Rscript scripts/generate_model_checksums.R` — updates `models/checksums.json` so production integrity verification (`MARINESABRES_VERIFY_MODELS=TRUE`) passes.

All scripts are deterministic with `set.seed(42)` + `torch_manual_seed(42)` (or seed list for the ensemble). The exact training data split is reproducible from the same seed.

## Where the pipeline is consumed in the UI

- `modules/graphical_ses_creator_module.R` — "AI Group Assignment" auto-classifier + ML-enhanced connection suggestions for the visual graph builder.
- `modules/ai_isa_assistant_module.R` — connection suggestions in the AI-assisted ISA workflow (predictions surface as "AI-suggested" rows with disagreement-derived confidence badges).
- `modules/scenario_builder_module.R` — leverage point ranking uses ensemble disagreement to surface uncertain regions where additional stakeholder input would be most valuable.

## What this is NOT (honest scope)

For transparency, the pipeline does **not** include:

- A graph neural network (in the GNN sense — graph convolutions, message passing). The graph features are hand-engineered scalars (centrality, distance, framework compliance), not learned message-passing representations.
- BERT-style transformer-from-scratch training. The transformer embeddings strategy uses **pretrained** sentence-transformer encoders via the `text` package and treats them as a frozen embedding lookup, not a fine-tuned BERT model.
- Reinforcement learning. No environment, no reward function, no policy network. Response-measure prioritization is rule-based + ensemble scoring.
- Collaborative filtering. No user-item matrix; "recommendations" are ML-driven connection predictions, not user-similarity-based.

Future-work candidates (not in v1.14.0): graph convolutional encoder for partial-model features; fine-tuning of the transformer on marine-domain corpora; RL formulation for response-portfolio optimization.

---

*Document last updated: 2026-05-17 — corresponds to MarineSABRES SES Toolbox v1.14.0.*
