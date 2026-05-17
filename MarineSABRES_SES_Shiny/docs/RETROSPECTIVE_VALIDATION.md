# Retrospective Validation Results

Generated: 2026-05-17 22:39:13

Compares the v1.14.0 base classifier against the v1.15.0 GraphSAGE-augmented
model on the same precision@k retrieval task.

## Method

For each of 7 production SES templates, 20% of human-validated positive connections are masked uniformly at random. The remaining positives + the template's elements form the 'visible' state. Each model scores all element-pair candidates that are NOT in the visible set; held-out masked positives are the retrieval targets. Macro-average across templates.

## Aggregate (macro-average)

| Metric | Mean | SD |
|---|---:|---:|
| base_p@5 | 0.057 | 0.098 |
| base_r@5 | 0.052 | 0.090 |
| gnn_p@5 | 0.086 | 0.157 |
| gnn_r@5 | 0.071 | 0.131 |
| base_p@10 | 0.057 | 0.053 |
| base_r@10 | 0.081 | 0.092 |
| gnn_p@10 | 0.057 | 0.079 |
| gnn_r@10 | 0.100 | 0.135 |
| base_p@20 | 0.050 | 0.041 |
| base_r@20 | 0.153 | 0.146 |
| gnn_p@20 | 0.043 | 0.045 |
| gnn_r@20 | 0.157 | 0.166 |

### Random baseline reference

Mean random precision@10 across templates ≈ 0.008 (computed as `n_masked / n_candidates` per template, then averaged).

Lift over random:

- Base v1.14.0  precision@10: 0.057 → **7.1× random**
- GNN  v1.15.0  precision@10: 0.057 → **7.1× random**
- Base v1.14.0  recall@20:    0.153
- GNN  v1.15.0  recall@20:    0.157

## Per-template detail

| Template | n_pos | n_masked | n_cand | base p@10 | gnn p@10 | base r@20 | gnn r@20 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Coastal Lagoon | 29 | 6 | 733 | 0.000 | 0.100 | 0.333 | 0.167 |
| Caribbean Island - Comprehensive SES Template | 134 | 27 | 5899 | 0.100 | 0.000 | 0.037 | 0.000 |
| Climate Change | 26 | 5 | 579 | 0.000 | 0.100 | 0.000 | 0.400 |
| Fisheries | 30 | 6 | 626 | 0.100 | 0.200 | 0.333 | 0.333 |
| Offshore Wind Energy | 26 | 5 | 485 | 0.100 | 0.000 | 0.200 | 0.000 |
| Pollution | 27 | 5 | 734 | 0.000 | 0.000 | 0.000 | 0.200 |
| Tourism | 29 | 6 | 627 | 0.100 | 0.000 | 0.167 | 0.000 |

## Notes

- Random seed: 42 (per-template seed = 42 + template index).
- Mask fraction: 20% of positives per template.
- Base model: `models/connection_predictor_best.pt` (v1.14.0 multi-task NN over 358-dim features).
- GNN model: `models/connection_predictor_gnn_best.pt` (v1.15.0 GraphSAGE encoder + multi-task heads).

## Reproduce

```bash
Rscript scripts/retrospective_validation_gnn.R
```
