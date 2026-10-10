#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: Rscript check_shap_inputs.R MODEL.RData FEATURES.csv")
env <- new.env(parent = emptyenv()); loaded <- load(args[[1]], envir = env)
x <- read.csv(args[[2]], check.names = FALSE)
cat("Objects:", paste(loaded, collapse = ", "), "\n")
cat("Feature rows:", nrow(x), " columns:", ncol(x), " nonnumeric:", sum(!vapply(x, is.numeric, logical(1))), "\n")
cat("fastshap:", requireNamespace("fastshap", quietly=TRUE), " shapviz:", requireNamespace("shapviz", quietly=TRUE), "\n")
