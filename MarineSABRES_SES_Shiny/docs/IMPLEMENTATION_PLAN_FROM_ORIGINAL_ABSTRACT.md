# Implementation Plan — Close the Gap to the Original ESP 2026 Abstract

**Status:** planning document, not a commitment.
**Updated:** 2026-05-17.
**Author of plan:** Claude (working session with Arturas Razinkovas-Baziukas).
**Background:** the *original* ESP 2026 abstract (`abstract_Razinkovas_et_al.docx`,
the one actually submitted) claims **eight** complementary ML approaches; the
*revised* abstract (`abstract_Razinkovas_et_al_v2.md`, prepared in this session)
honestly scopes that down to five. This plan exists if you want to close the gap
back toward the original eight rather than keep the revised version.

The eight claimed approaches and current state:

| # | Original-abstract claim | v1.14.0 state | Gap |
|---|---|---|---|
| 1 | Deep learning for connection prediction | ✅ Implemented (`functions/ml_models.R`, multi-task NN) | None |
| 2 | Graph neural networks for model completion | ⚠️ Graph **features** (centrality, paths, framework-compliance) — no message passing | Real GCN/GAT layer needed |
| 3 | Transfer learning for template matching | ✅ Implemented (v1.14.0, `scripts/fine_tune_for_template.R`) | None |
| 4 | BERT-based NLP for SES element extraction | ⚠️ Sentence-transformer **embeddings** of known element names — no extraction from free text | Token-classification or chunk-classification head |
| 5 | Reinforcement learning for response optimization | ❌ Rule-based + ensemble scoring only | Whole component missing |
| 6 | Ensemble feedback detection | 🟡 Ensemble + disagreement-driven active learning exist; "feedback detection" terminology is unclear | Either rename to match what exists, or build a distinct feedback-loop detector |
| 7 | Collaborative filtering for recommendations | ❌ Not started | Whole component missing |
| 8 | "23% more connections / 64% greater consistency" | ❌ Unsourced numbers | Pilot study needed |

---

## Top-level recommendation

**Do not try to ship all five missing components before ESP 2026.** The work
is at least 6-8 weeks of focused effort and several of the components (RL,
CF) are at high risk of degrading the user experience if shipped half-built
on a 569-example training set.

A pragmatic shape:

- **Tier A (do):** clarify and ship items already mostly there (#6 ensemble
  feedback detection, #2 GCN layer as a feature augmentation). Plus the
  pilot study (#8) which is what produces the 23%/64% — without it those
  numbers don't exist whatever architecture you ship.
- **Tier B (consider for v1.15 / v1.16):** #4 BERT element extraction, #7
  collaborative filtering — both can be useful but neither is
  presentation-blocking and both can fail quietly.
- **Tier C (descope or honest writeup):** #5 reinforcement learning. With
  the current data, an RL formulation will either overfit or collapse to a
  rule-based scorer. Either replace with a clearly-described bandit /
  multi-armed scoring formulation (which is closer to what the app
  actually does), or remove it from the abstract.

If you accept this shape, the **revised abstract you already submitted**
is closer to the truth than the original. The work below is for if you
specifically want the original-abstract architecture.

---

## Component plans

Each section: **scope** (what it would do in the app), **technical approach**,
**files touched**, **risks**, **effort**, **what success looks like**, **how
to validate**.

### #2 — Graph Neural Network for model completion

**Scope.** Replace (or augment) the hand-engineered graph features with a
learned graph encoder. The GCN takes the user's partial SES model as a
graph, produces node embeddings that capture multi-hop neighbourhood
structure, and feeds those embeddings into the existing connection-existence
head.

**Technical approach.**

- Use `torch` + a minimal in-repo `nn_module` implementation of a 2-layer
  GraphSAGE encoder (GraphSAGE handles dynamic-graph inference at prediction
  time better than vanilla GCN, which is important because the user's graph
  is partially built when we predict).
- Input: per-node DAPSI(W)R(M) one-hot (7 dims) + sentence-transformer text
  embedding (128 dims after PCA) + degree + betweenness = ~140-dim
  node-features.
- Aggregation: 2 hops, mean aggregator, ReLU, 64-dim node embedding output.
- For a candidate edge (s,t), concatenate `[h_s, h_t, h_s ⊙ h_t]` (192 dims),
  feed to existing existence/strength/confidence/polarity heads.
- Train end-to-end with the same multi-task loss as the v1.14.0 base.

**Files touched.**

- `functions/ml_models.R` — new `graph_sage_encoder` + `connection_predictor_gnn` nn_modules.
- `functions/ml_graph_features.R` — replaced by `functions/ml_graph_encoder.R`.
- `scripts/train_connection_predictor.R` — alternative training path with `--use-gnn` flag.
- `modules/graphical_ses_creator_module.R` — wire the GNN predictor into the suggestion panel behind a feature flag.

**Risks.**

- 412 connections across 33 contexts is small for a GNN. Likely to overfit
  without strong regularization (high dropout 0.5, weight decay, edge
  dropout during training).
- The current base model already gets only ~7× the random baseline; a GNN
  could realistically push that to 10-15× but absolute numbers will still
  be modest until #8 (more data / ranking loss) lands.

**Effort.** 5-8 working days, including writing tests, integrating into the
suggestion panel, and a retrospective comparison vs. the v1.14.0 base.

**Success looks like.** GNN-augmented retrospective precision@10 ≥ 1.5× the
v1.14.0 base, with no per-template regression below the v1.14.0 baseline.
Inference latency for one candidate batch < 2× the base.

**Validation.** Re-run `scripts/retrospective_validation.R` with a `--model
gnn` flag; report a side-by-side table in `docs/RETROSPECTIVE_VALIDATION.md`.

---

### #4 — BERT-based NLP for SES element extraction

**Scope.** Given free-text input (e.g. a paragraph from a stakeholder
interview, a policy document, or a meeting transcript), surface candidate
DAPSI(W)R(M) elements that the text seems to describe. Differs from what
v1.14.0 has, which only embeds known element names.

**Two operationally distinct features under this name:**

- **(a) Span-extraction.** Highlight candidate noun phrases in text that
  match a DAPSI(W)R(M) category. Useful for the existing "AI Group
  Assignment" workflow in `modules/graphical_ses_creator_module.R`.
- **(b) Chunk-classification.** Take a free-text paragraph, return the most
  likely DAPSI(W)R(M) category and a confidence score.

Recommend building (b) first — it's directly useful, simpler, and reuses the
sentence-transformer infrastructure.

**Technical approach for (b).**

- Take the 1,185 connection-level entries from `data/ses_knowledge_db.json`.
  Each connection has source and target elements with names and types.
  Treat the names as labelled text → category training data (~2,300 labelled
  text → DAPSIWRM-category pairs).
- Fine-tune a small classification head on top of the existing
  sentence-transformer encoder (the encoder stays frozen).
- 7-way softmax over DAPSI(W)R(M) categories.
- Calibrate confidence via a held-out validation set.

**Technical approach for (a)** (if you go further):

- Use spaCy's transformer pipeline (`en_core_web_trf`) or HuggingFace's
  `transformers` (via `reticulate`) for token-level NER fine-tuning.
- Annotated training data is the hard part — you'd need to label spans in
  the KB's "context" fields, or use Snorkel-style weak supervision keyed on
  element-name matches.

**Files touched.**

- `functions/ml_element_classifier.R` — new (chunk-classification).
- `scripts/train_element_classifier.R` — new.
- `modules/graphical_ses_creator_module.R` — new "paste text, get suggested
  elements" affordance behind a feature flag.
- `translations/modules/graphical_ses_creator.json` — UI strings × 9 languages.

**Risks.**

- Element names in the KB are short (typically 2-5 words). A classifier
  trained on names will not generalize well to full paragraphs without
  paragraph-level training data.
- Span extraction (a) without real annotated data is a research project,
  not an engineering one. Don't ship it without proper labels.

**Effort.** (b) alone: 5-7 days. (a) realistically 3-4 weeks if you want a
defensible model.

**Success looks like (b).** 7-way classification accuracy ≥ 75% on a held-out
test split of KB-derived element-category pairs; ≥ 65% on a small hand-labelled
test set of paragraphs from stakeholder interviews.

**Validation.** Add a chunk-classification accuracy figure to
`docs/RETROSPECTIVE_VALIDATION.md`.

---

### #5 — Reinforcement learning for response optimization

**Scope.** Given a (partial) SES model, recommend a *portfolio of response
measures* that the model predicts will most improve target ecosystem services
under constraints (cost, feasibility, time horizon).

**This is the riskiest item in the plan.** Reading carefully: the
*description* in the abstract is what the toolbox already does today via
rule-based ensemble scoring of response measures. Calling it "RL" suggests an
MDP with states, actions, transitions, and a learned policy — none of which
the toolbox actually has.

**Three honest paths forward, ordered by realism:**

**Path A: Rename, don't reimplement.** What the app does today is sequential
multi-criteria scoring with learned weights from the ensemble. That's a
*bandit / sequential decision* problem, not RL. Update the abstract to use
that more accurate terminology. Cost: 0.5 days; risk: zero; net effect:
removes a misleading claim. Recommended.

**Path B: Contextual bandit for response ordering.** Treat each user session
as a sequence of "show response measure i" decisions; reward = whether the
user accepts it. Train a Thompson-sampling or LinUCB contextual bandit on
the feedback log (`data/ml_feedback_log.csv`). This is a real "learns from
interaction" algorithm and is defensible as "RL-adjacent" in a paper. Cost:
4-6 days; risk: medium (small interaction log).

**Path C: Full RL with a simulated environment.** Define an MDP where state
is the partial SES model, actions are adding response-measure-element
edges, and reward is the predicted improvement in ecosystem services
according to the existing connection-predictor (used as a world model).
Train PPO via `torch` + a homegrown environment. Cost: 15-20 days; risk:
high (the world model is the connection predictor whose own precision@10
is ~6%; the RL policy will inherit and amplify those errors).

**Files touched (Path B).**

- `functions/ml_response_bandit.R` — new.
- `modules/response_module.R` — wire bandit predictions behind a feature
  flag for the priority ranking.
- `scripts/train_response_bandit.R` — new.

**Effort.** A: 0.5 days. B: 4-6 days. C: 15-20 days plus high risk of
degenerate behaviour.

**Success looks like (B).** Bandit-recommended response ordering converges
to the same top-3 as a held-out validation user's actual prioritization in
≥ 60% of held-out sessions.

**Validation.** Offline replay against `ml_feedback_log.csv`; report a
log-loss curve over training epochs.

---

### #6 — Ensemble feedback detection

**Scope (as the abstract uses the term).** "Detect feedback" is ambiguous in
the abstract. Two possible readings:

- **(a) Detect feedback loops in the user's SES graph** — i.e., cycles that
  cross between Drivers and Activities, between Pressures and Marine Processes,
  etc. The toolbox already has `analysis_loops_module.R` and
  `functions/network_analysis.R`. This is graph-cycle detection, not ML;
  describing it as "ensemble feedback detection" is misleading.
- **(b) Detect user feedback signal in the ensemble's predictions** — i.e.,
  use inter-model disagreement to identify candidates where the ensemble is
  "asking for feedback". This is what the v1.14.0 active-learning code does.

**Recommendation.** Already implemented under both readings. The fix here is
to rename the abstract bullet to one of:

- "Ensemble-based uncertainty quantification for active learning" (matches (b))
- "Graph-cycle detection for DAPSI(W)R(M) feedback-loop identification"
  (matches (a))

Both features already ship in v1.14.0. If you want a single coherent
"ensemble feedback detection" feature that fuses both, that's a 2-3 day
piece of UI work: show the cycle detection results next to the ensemble
disagreement badge, so the user sees both "this is a structural feedback
loop in your model" AND "the ensemble disagrees about whether this
particular edge should exist".

**Effort.** Renaming: 0.5 days. UI fusion: 2-3 days.

---

### #7 — Collaborative filtering for recommendations

**Scope.** Recommend SES elements / connections to a user based on what
similar users have built. "Similar" = users who built models with overlapping
sets of elements.

**Honest data question first.** As of v1.14.0, how many distinct user
sessions are in `data/ml_feedback_log.csv`? Below ~30 users, collaborative
filtering will return noise. Run this before committing:

```r
fl <- read.csv("data/ml_feedback_log.csv")
length(unique(fl$session_id))
```

If the answer is < 30, **don't build CF yet** — the cold-start problem is
crippling on small interaction data. Build the data-collection
infrastructure first; CF can come later when the log has 100+ users.

**Technical approach (when data is sufficient).**

- Build a user × element binary matrix from the feedback log + saved-project
  manifest. Factorize via implicit-ALS (`recosystem` package) into 32-dim
  user and item embeddings.
- At prediction time for a new user's partial model, compute the average of
  their selected elements' item embeddings, find the nearest items via
  cosine similarity, surface the top-k unseen ones as suggestions.
- Combine with the existing NN predictor via a weighted sum tuned on a
  validation split.

**Files touched.**

- `functions/ml_collaborative_filter.R` — new.
- `scripts/train_collaborative_filter.R` — new.
- `modules/graphical_ses_creator_module.R` — wire CF predictions behind a
  feature flag.
- `data/cf_user_item_matrix.rds` — new (regenerated nightly from the log).

**Risks.**

- Data sparsity. A 30-user × 400-element matrix is < 0.5% dense.
- Privacy. User session IDs in the feedback log may de-anonymize
  participants. Audit before shipping.

**Effort.** 3-5 days once data ≥ 30 users. Indefinite hold until then.

**Success looks like.** CF recommendations have ≥ 5% precision@10 on
held-out user-session test data (separate from the retrospective-validation
template-masking test).

---

### #8 — Pilot study to back the "23% / 64%" numbers

**Scope.** The original abstract's "23% more relevant connections / 64%
greater consistency" requires a pilot study. The current abstract notes the
pilot is "in preparation". Actually run it.

**Protocol (existing).** `docs/ml_pilot_protocol.md` if it exists; if not,
draft it.

**Design.**

- N = 8-12 non-expert users, recruited from MARBEFES / MarineSABRES
  consortium plus 4-5 outside the project for an honest comparison.
- Task: build a Mediterranean coastal-lagoon SES model from scratch with
  one of two conditions: (A) baseline toolbox without ML suggestions; (B)
  v1.14.0 toolbox with ML suggestions. Within-subjects design with a
  one-week washout between conditions, condition order randomized.
- Primary outcome: number of unique connections in the final model.
- Secondary outcomes: IoU with a reference expert model (the consortium's
  pre-validated Mediterranean lagoon template); time to first complete
  model; self-reported workload via NASA-TLX.
- Statistical analysis: paired t-tests on each outcome with
  Bonferroni correction.

**Files touched.**

- `docs/ml_pilot_protocol.md` — created or updated.
- `docs/ml_pilot_consent_form.md` — created (legal review by IECS).
- `scripts/pilot_analysis.R` — created for the eventual stats.
- `modules/feedback_reporter_module.R` — instrument time-to-first-model
  tracking + NASA-TLX prompt.

**Risks.**

- Recruitment. 8-12 users with the time to do two sessions is non-trivial.
- Ethics. Klaipeda University and / or University of Hull may require a
  written ethics waiver or approval for the workload-questionnaire (NASA-TLX).
- The pilot may produce results worse than the abstract's claims. That's a
  feature, not a bug — but plan how you'll handle that case in advance
  (revised numbers, or pilot becomes the "limitations" section).

**Effort.** 3-4 weeks calendar time (recruitment + sessions + analysis +
writeup). Active developer time: ~5 days for instrumentation + ~3 days for
analysis.

**Success looks like.** Effect-size estimates with confidence intervals for
both primary and secondary outcomes; abstract numbers replaced with the
measured ones.

---

## Recommended order if you do everything

### Phase A (immediate, 2-3 weeks): rename + plumb existing capabilities

1. Update the abstract terminology for #6 and #5 (recommended Path A) to
   match what the toolbox actually does. 1 day.
2. Build the **chunk-classification** version of #4 (BERT element-category
   classifier). 5-7 days.
3. Add the GNN encoder #2 as a feature-flagged alternative model. 5-8 days.
4. Re-run retrospective validation with both new models; update
   `docs/RETROSPECTIVE_VALIDATION.md`. 1-2 days.

Result: original abstract's *#1, #2 (real), #3, #4 (real), #6 (renamed)* all
genuinely live. That's five of the eight covered honestly.

### Phase B (4-6 weeks): pilot study #8

5. Instrument the toolbox for the pilot. 3-5 days.
6. Recruit. 2-3 weeks calendar.
7. Run sessions, analyze, write up. 1-2 weeks.

Result: the "23%/64%" numbers become real measurements. Even if they come in
lower, you have *defensible numbers* — that's more publishable than
unbacked claims.

### Phase C (post-ESP, if data justifies): #5 RL bandit + #7 CF

8. Once pilot data + a few months of production traffic accumulate
   (≥ 30 users in feedback log), build Path-B contextual bandit for #5.
   4-6 days.
9. Build CF for #7 if user counts continue to grow. 3-5 days.

---

## Decision points for the user

1. **Original or revised abstract?** The revised one (v2) is already in
   sync with what's deployed and honest about scope. The original needs
   1-2 months of work to be accurate. The presentation can succeed with
   either — the choice is about how much code you want to write before ESP.
2. **Do the pilot study or descope the 23%/64% claim?** Without the pilot,
   those numbers do not exist. The revised abstract already removes them.
3. **GNN or stay with graph features?** If you do *one* technical-depth
   item beyond v1.14.0, the GNN (#2) is the highest-leverage one — it
   plausibly improves precision@10 *and* matches an existing abstract claim
   *and* is intellectually defensible at ESP.
4. **Rename or rebuild RL/CF?** Renaming (Path A for #5; same logic for
   #7 if the user log is small) is honest and cheap. Rebuilding is real
   science but slow.

---

## What this plan deliberately does NOT include

- **A "complete the original abstract in 2 weeks" plan.** It can't be done
  without cutting corners that will show in the live demo and the Q&A.
- **A reinforcement-learning-from-human-feedback (RLHF) loop.** That's a
  separate paper and a separate engineering programme.
- **Multi-modal extensions** (e.g. ingesting GIS / satellite imagery as
  features). The MarineSABRES KB doesn't yet have aligned multi-modal data
  for the demonstration regions; building this is its own project.
- **A "model garden" of comparison baselines.** A boosted tree baseline
  would be useful for the methods section but is not abstract-claim-relevant.

---

## TL;DR for the impatient reader

- **Cheapest honest win:** rename #5 and #6 in the abstract. 0.5 days. Net
  effect: the abstract becomes accurate.
- **Highest-leverage real work:** GNN (#2) + chunk-classification BERT (#4).
  Two to three weeks of focused work to convert two claims from "feature
  engineering" into "real ML". Both also improve the precision@10 number.
- **Highest-impact real work:** pilot study (#8). Four weeks calendar time
  including recruitment, but it produces the only numbers the abstract
  has that aren't already measured.
- **Defer:** CF (#7) until user log ≥ 30; RL Path C (#5) ever.
