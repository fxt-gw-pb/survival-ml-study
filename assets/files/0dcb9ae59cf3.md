---
name: pang-survml-lasso-cox
description: Reproduce and modernize the legacy Lasso-Cox model visible in PDFs and RData but missing from the current main model block. Use when reconciling nine-model artifacts, fitting penalized Cox prediction, or generating Lasso-Cox predictions and SHAP outputs.
---

# Legacy Lasso-Cox model

This module is required for artifact fidelity even though the usage file says eight models. Run `scripts/train_lasso_cox.R <development.csv> <validation.csv> <output_dir> [predictors_csv] [seed]`. Select lambda in development CV, lock the matrix schema and export linear predictors. Read `references/version-discrepancy.md`.
