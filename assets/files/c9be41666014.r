args <- commandArgs(trailingOnly = TRUE)
out <- if(length(args)) args[[1]] else "package_audit.csv"
pkgs <- c("survival","survminer","glmnet","randomForestSRC","CoxBoost","survivalsvm",
          "caret","gbm","riskRegression","pec","tidyr","dcurves","ggDCA","timeROC",
          "pROC","survcomp","survex","ModelMetrics","rms","autoReg","regplot","xgboost",
          "superpc","plsRcox","plotROC","ggplot2","dplyr","ggsci","fastshap","shapviz",
          "gridExtra","scales","devtools","BiocManager")
z <- data.frame(package=pkgs, installed=vapply(pkgs, requireNamespace, logical(1), quietly=TRUE),
                version=vapply(pkgs, function(x) if(requireNamespace(x,quietly=TRUE)) as.character(packageVersion(x)) else NA_character_, character(1)))
write.csv(z,out,row.names=FALSE); print(z,row.names=FALSE)
if(any(!z$installed)) quit(status=2L)
