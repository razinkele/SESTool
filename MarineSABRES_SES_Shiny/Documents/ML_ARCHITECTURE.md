# ML Architecture - MarineSABRES SES Toolbox

## Overview

The ML system provides intelligent connection prediction for DAPSIWRM elements using neural networks. It supports both single-model inference and ensemble predictions for improved accuracy.

## System Components

```
functions/
├── ml_inference.R           # Main inference API
├── ml_models.R              # PyTorch model definitions
├── ml_feature_engineering.R # Feature extraction
├── ml_ensemble.R            # Ensemble management
├── ml_explainability.R      # Prediction explanations
├── ml_feature_cache.R       # Performance caching
├── ml_text_embeddings.R     # Text vectorization
├── ml_context_embeddings.R  # Contextual features
├── ml_graph_features.R      # Graph-based features
├── ml_active_learning.R     # Active learning
└── ml_model_registry.R      # Model versioning
```

## Feature Architecture

### Phase 1 Features (358-dim)
- Element embeddings: 256 dims (128 × 2 elements)
- Type encodings: 14 dims (7 × 2 one-hot)
- Context features: 88 dims

### Phase 2 Features (314-dim)
- Learned embeddings: 270 dims
- Context embeddings: 36 dims
- Graph features: 8 dims

## Model Architecture

```
ConnectionPredictor (nn.Module)
├── Element Embedding Layer
├── Shared Backbone
│   └── Linear(hidden) → LayerNorm → ReLU → Dropout
├── Prediction Heads
│   ├── Existence: Linear → Sigmoid (binary)
│   ├── Polarity: Linear → Sigmoid (binary)
│   ├── Strength: Linear → Softmax (3-class)
│   └── Confidence: Linear → Sigmoid (scalar)
```

## Usage

### Single Prediction
```r
source("functions/ml_inference.R")

# Load model
load_ml_model("models/connection_predictor_best.pt")

# Predict
result <- predict_connection_ml(
  elem1 = list(type = "D", label = "Climate Change"),
  elem2 = list(type = "A", label = "Fishing Activity")
)
# Returns: list(exists, polarity, strength, confidence)
```

### Ensemble Prediction
```r
source("functions/ml_ensemble.R")

# Load ensemble
load_ensemble("models/ensemble/")

# Predict with uncertainty
result <- predict_connection_ensemble(elem1, elem2, aggregation = "mean")
# Returns: aggregated predictions + disagreement scores
```

### Explainability
```r
source("functions/ml_explainability.R")

explanation <- explain_connection_prediction(model, elem1, elem2)
print(explanation)
# Shows: probability, reasoning, feature importance
```

## Training

### Single Model
```bash
Rscript scripts/train_connection_predictor.R
```

### Ensemble (5 models)
```bash
Rscript scripts/train_ensemble_models.R
```

## Configuration

See `constants.R` for ML configuration:
- `ML_ENSEMBLE_DEFAULT_SIZE`: Number of ensemble models (default: 5)
- `ML_DEFAULT_EPOCHS`: Training epochs (default: 100)
- `ML_DROPOUT_RATE`: Regularization (default: 0.3)

## Model Registry

Models are versioned in `models/`:
```
models/
├── connection_predictor_best.pt    # Best single model
├── ensemble/
│   ├── ensemble_metadata.rds
│   ├── model_1_seed42.pt
│   ├── model_2_seed123.pt
│   └── ...
└── signatures/                      # Security signatures
```

## Performance

- Single prediction: ~5-10ms
- Batch (100 pairs): ~50-100ms
- Feature caching: 80-90% speedup for repeated elements

## Security

- Model signatures verified on load
- See `functions/ml_model_registry.R` for signature validation
