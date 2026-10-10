# Source parameters

The original RSF uses 1,000 trees, `nodesize=3`, `mtry=2`, log-rank splitting, importance, proximity and seed 123. Saved prediction scores range from 12.173 to 156.98. The source later overwrites the object name `RSF` with a univariable Cox model on the RSF score; revised workflows must keep distinct names such as `rsf_fit` and `rsf_score_calibrator`.
