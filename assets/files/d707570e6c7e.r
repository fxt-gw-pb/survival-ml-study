#!/usr/bin/env Rscript
pkgs <- c("survival","randomForestSRC","gbm","CoxBoost","survivalsvm","xgboost","superpc","plsRcox")
ok <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
cat(paste(sprintf("%-18s %s", pkgs, ifelse(ok, "OK", "MISSING")), collapse = "\n"), "\n")
quit(status = if (all(ok)) 0L else 2L)
