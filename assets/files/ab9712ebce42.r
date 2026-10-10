#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: Rscript audit_split.R INPUT.csv OUTPUT_DIR [train_fraction=0.7] [seed=123]")
input <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
out <- args[[2]]
fraction <- if (length(args) >= 3L) as.numeric(args[[3]]) else 0.7
seed <- if (length(args) >= 4L) as.integer(args[[4]]) else 123L
if (!is.finite(fraction) || fraction <= 0 || fraction >= 1) stop("train_fraction must be between 0 and 1")
d <- read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
if (!all(c("Time", "Event") %in% names(d))) stop("Required columns: Time, Event")
if (!is.numeric(d$Time) || anyNA(d$Time) || any(!is.finite(d$Time)) || any(d$Time <= 0)) stop("Time must be complete, finite, numeric, and >0")
if (!is.numeric(d$Event) || anyNA(d$Event) || any(!d$Event %in% c(0, 1))) stop("Event must contain only 0/1")
set.seed(seed)
idx <- unlist(lapply(split(seq_len(nrow(d)), d$Event), function(z) sample(z, floor(length(z) * fraction))), use.names = FALSE)
train <- d[sort(idx), , drop = FALSE]
test <- d[setdiff(seq_len(nrow(d)), idx), , drop = FALSE]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write.csv(train, file.path(out, "traindata.csv"), row.names = FALSE)
write.csv(test, file.path(out, "testdata.csv"), row.names = FALSE)
writeLines(c(paste0("input=", input), paste0("seed=", seed), paste0("train_fraction=", fraction),
             paste0("train_n=", nrow(train)), paste0("test_n=", nrow(test)),
             paste0("train_events=", sum(train$Event)), paste0("test_events=", sum(test$Event))),
           file.path(out, "split_manifest.txt"))
cat("Created train/test split in", normalizePath(out, winslash = "/"), "\n")
