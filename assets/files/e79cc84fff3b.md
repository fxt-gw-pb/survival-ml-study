# Source result

The source uses `autoReg(..., uni=TRUE, milti=TRUE, threshold=0.05)` and manually sets eight variables: Age, Race, Grade, Surgery, Chemotherapy, Marital, SEER_stage and Tumor_size. The saved 41-row table contains an invalid multivariable entry for M-stage (`NA (NA-NA)`), consistent with collinearity or instability. Do not copy this variable list or threshold to new data without a declared selection strategy.
