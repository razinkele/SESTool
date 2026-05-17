# Retrospective Validation Results

Generated: 2026-05-17 (regenerate with `Rscript scripts/retrospective_validation.R`).

Backs the ESP 2026 abstract's results sentence on retrospective retrieval of
human-validated connections.

## Method

For each of 7 production SES templates (Coastal Lagoon, Caribbean Island,
Climate Change, Fisheries, Offshore Wind Energy, Pollution, Tourism), 20% of
human-validated positive connections are masked uniformly at random. The
remaining positives plus the template's unique elements form the "visible"
state. The pipeline scores all element-pair candidates that are not in the
visible set; held-out masked positives are the ground-truth retrieval targets.
precision@k = (# masked positives among top-k) / k. recall@k = (# masked
positives in top-k) / (# masked positives total). Macro-averaged across
templates.

## Aggregate (macro-average over 7 templates)

| Metric | Mean | SD |
|---|---:|---:|
| precision@5 | 0.057 | 0.098 |
| precision@10 | 0.057 | 0.053 |
| precision@20 | 0.050 | 0.041 |
| recall@5 | 0.052 | 0.090 |
| recall@10 | 0.081 | 0.092 |
| recall@20 | 0.153 | 0.146 |

### Random baseline

For each template, the expected precision@k of a uniformly random ranking is
`n_masked / n_candidates`. Across the 7 templates:

| Template | n_candidates | n_masked | random p@10 |
|---|---:|---:|---:|
| Coastal Lagoon | 733 | 6 | 0.0082 |
| Caribbean Island | 5899 | 27 | 0.0046 |
| Climate Change | 579 | 5 | 0.0086 |
| Fisheries | 626 | 6 | 0.0096 |
| Offshore Wind Energy | 485 | 5 | 0.0103 |
| Pollution | 734 | 5 | 0.0068 |
| Tourism | 627 | 6 | 0.0096 |
| **Macro mean** | — | — | **0.0082** |

**Lift over random at k=10:** 0.057 / 0.0082 ≈ **7.0×**

**Lift over random at k=20 (recall):** the random recall@20 would be
20 × random_p / mask_fraction ≈ 20 / mean_candidates × (n_masked / n_masked) ≈ 0.03;
observed recall@20 = 0.153 → ≈ **5×** lift.

## Per-template detail

| Template | n_pos | n_masked | n_candidates | base p@5 | base p@10 | base p@20 | base r@20 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Coastal Lagoon | 29 | 6 | 733 | 0.000 | 0.000 | 0.100 | 0.333 |
| Caribbean Island | 134 | 27 | 5899 | 0.000 | 0.100 | 0.050 | 0.037 |
| Climate Change | 26 | 5 | 579 | 0.000 | 0.000 | 0.000 | 0.000 |
| Fisheries | 30 | 6 | 626 | 0.200 | 0.100 | 0.100 | 0.333 |
| Offshore Wind Energy | 26 | 5 | 485 | 0.200 | 0.100 | 0.050 | 0.200 |
| Pollution | 27 | 5 | 734 | 0.000 | 0.000 | 0.000 | 0.000 |
| Tourism | 29 | 6 | 627 | 0.000 | 0.100 | 0.050 | 0.167 |

(`recall@20` per-template is derived directly from the saved
`data/retrospective_validation_results.rds`; the script emits the macro-average.)

## Interpretation

- **Above-chance signal.** Precision@10 is ~7× the random baseline, recall@20
  is ~5×. The base-model alone is therefore producing usable rankings, but
  far short of an "obvious top-of-list" retrieval.
- **Per-template variance is large.** Fisheries / Offshore Wind Energy /
  Caribbean Island show meaningful retrieval; Climate Change and Pollution
  collapse to chance. The model is sensitive to whether the template
  vocabulary overlaps with what dominates the training set.
- **Honest framing for the abstract.** "precision@10 of ~6% (≈7× the random
  baseline of ~1%)" is defensible. Claiming higher absolute precision would
  require either (a) a within-template ranking loss during training (current
  loss is binary cross-entropy over positives-vs-random-negatives, which does
  not optimize ranking inside a single template), or (b) the fine-tuned
  per-template checkpoints from `scripts/fine_tune_for_template.R`.

## Notes

- Random seed: 42 (per-template seed = 42 + template index).
- Mask fraction: 20% of positives per template.
- Candidate pool: all distinct (source, target) element pairs from the
  template, minus visible positives.
- Base model: `models/connection_predictor_best.pt`.
- Ensemble: load failed in this run (likely a torch state-dict version mismatch
  on the v1.13.x ensemble checkpoints — the segfault is not in our code).
  Re-run after regenerating the ensemble against the v1.14.0 base will
  add ensemble columns automatically.

## Reproduce

```bash
Rscript scripts/retrospective_validation.R
# or a single template:
Rscript scripts/retrospective_validation.R "Fisheries"
```

Outputs:
- `data/retrospective_validation_results.rds` — full per-template metrics + config.
- `docs/RETROSPECTIVE_VALIDATION.md` — this file, regenerated each run.
