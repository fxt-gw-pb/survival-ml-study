#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript check_prediction_table.R PREDICTIONS.csv")
d <- read.csv(args[[1]], check.names = FALSE)
if (!all(c("Time","Event") %in% names(d))) stop("Missing Time/Event")
models <- setdiff(names(d), c("Time","Event"))
bad <- models[!vapply(d[models], function(x) is.numeric(x) && all(is.finite(x)), logical(1))]
cat("Rows:", nrow(d), " Events:", sum(d$Event==1), " Models:", paste(models, collapse=", "), "\n")
if (length(bad)) stop("Invalid model score columns: ", paste(bad, collapse=", "))
