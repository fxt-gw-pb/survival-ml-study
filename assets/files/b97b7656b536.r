#!/usr/bin/env Rscript
pkgs <- c("survival","survminer","glmnet","randomForestSRC","CoxBoost","survivalsvm",
          "caret","gbm","riskRegression","pec","dcurves","ggDCA","timeROC","pROC",
          "survcomp","survex","ModelMetrics","rms","autoReg","regplot","xgboost",
          "superpc","plsRcox","plotROC","fastshap","shapviz","gridExtra","ggplot2",
          "dplyr","tidyr","ggsci","reshape")
ok <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
ver <- vapply(pkgs, function(p) if (requireNamespace(p, quietly=TRUE)) as.character(packageVersion(p)) else "-", character(1))
out <- data.frame(package=pkgs, installed=ok, version=ver)
print(out, row.names=FALSE)
cat("\nR:", R.version.string, "\n")
cat("Installed:", sum(ok), "/", length(ok), "\n")
quit(status=if(all(ok)) 0L else 2L)
