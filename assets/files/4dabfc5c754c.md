# Code map

`assets/legacy-section.R` corresponds to original lines 409-657.

- 417-435: RSF prediction wrapper and SHAP.
- 437-459: GBM wrapper and SHAP.
- 461-477: CoxPH wrapper and SHAP.
- 478-500: CoxBoost wrapper and SHAP.
- 501-522: survival-SVM wrapper and SHAP.
- 523-532: native XGBoost `shapviz` path.
- 533-562: SuperPC wrapper and SHAP.
- 563-582: plsRcox wrapper and SHAP.
- 583-657: force, beeswarm, bar, waterfall, and dependence plots.

Test each wrapper on at least two rows before `fastshap::explain()`. Record whether the output is relative risk, linear predictor, or another ranking score.
