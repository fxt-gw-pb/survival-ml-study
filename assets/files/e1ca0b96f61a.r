#!/usr/bin/env Rscript

# Dependency-free input audit for censored survival modeling.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || args[[1]] %in% c("-h", "--help")) {
  cat("Usage: Rscript preflight_survival_ml.R DATA.csv [REPORT.txt]\n")
  quit(status = if (length(args) < 1L) 2L else 0L)
}

input <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
report_path <- if (length(args) >= 2L) args[[2]] else NA_character_

read_attempts <- list(
  function() read.csv(input, check.names = FALSE, stringsAsFactors = FALSE),
  function() read.csv(input, check.names = FALSE, stringsAsFactors = FALSE,
                      fileEncoding = "UTF-8-BOM"),
  function() read.csv(input, check.names = FALSE, stringsAsFactors = FALSE,
                      fileEncoding = "GB18030")
)

dat <- NULL
last_error <- NULL
for (reader in read_attempts) {
  candidate <- tryCatch(reader(), error = function(e) e)
  if (!inherits(candidate, "error")) {
    dat <- candidate
    break
  }
  last_error <- conditionMessage(candidate)
}
if (is.null(dat)) stop("Unable to read CSV: ", last_error)

critical <- character()
warnings <- character()
lines <- character()
emit <- function(...) lines <<- c(lines, paste0(...))

emit("SURVIVAL ML PREFLIGHT")
emit("Input: ", input)
emit("Rows: ", nrow(dat), " | Columns: ", ncol(dat))

required <- c("Time", "Event")
missing_required <- setdiff(required, names(dat))
if (length(missing_required)) {
  critical <- c(critical, paste("Missing required columns:",
                                paste(missing_required, collapse = ", ")))
} else {
  if (!is.numeric(dat$Time)) critical <- c(critical, "Time must be numeric.")
  if (!is.numeric(dat$Event)) critical <- c(critical, "Event must be numeric/integer.")

  if (is.numeric(dat$Time)) {
    bad_time <- sum(!is.finite(dat$Time) | dat$Time <= 0, na.rm = TRUE)
    missing_time <- sum(is.na(dat$Time))
    emit("Time: min=", signif(min(dat$Time, na.rm = TRUE), 5),
         " median=", signif(median(dat$Time, na.rm = TRUE), 5),
         " max=", signif(max(dat$Time, na.rm = TRUE), 5),
         " | missing=", missing_time, " | nonpositive/nonfinite=", bad_time)
    if (missing_time > 0 || bad_time > 0) {
      critical <- c(critical, "Time contains missing, nonpositive, or nonfinite values.")
    }
  }

  if (is.numeric(dat$Event)) {
    event_values <- sort(unique(dat$Event[!is.na(dat$Event)]))
    invalid_event <- setdiff(event_values, c(0, 1))
    events <- sum(dat$Event == 1, na.rm = TRUE)
    emit("Event values: ", paste(event_values, collapse = ", "),
         " | events=", events,
         " | event rate=", sprintf("%.1f%%", 100 * events / nrow(dat)),
         " | missing=", sum(is.na(dat$Event)))
    if (length(invalid_event) || anyNA(dat$Event)) {
      critical <- c(critical, "Event must contain only complete 0/1 values.")
    }
    if (events < 20) warnings <- c(warnings, "Fewer than 20 observed events; complex modeling is unlikely to be reliable.")
  }
}

predictor_names <- setdiff(names(dat), required)
if (!length(predictor_names)) {
  critical <- c(critical, "No predictor columns found.")
} else {
  nonnumeric <- predictor_names[!vapply(dat[predictor_names], is.numeric, logical(1))]
  zero_var <- predictor_names[vapply(dat[predictor_names], function(x) {
    length(unique(x[!is.na(x)])) <= 1L
  }, logical(1))]
  miss_pct <- sort(vapply(dat[predictor_names], function(x) mean(is.na(x)) * 100,
                         numeric(1)), decreasing = TRUE)
  emit("Predictors: ", length(predictor_names),
       " | nonnumeric=", length(nonnumeric),
       " | zero variance=", length(zero_var))
  if (length(nonnumeric)) emit("Nonnumeric predictors: ", paste(nonnumeric, collapse = ", "))
  if (length(zero_var)) warnings <- c(warnings, paste("Zero-variance predictors:", paste(zero_var, collapse = ", ")))
  if (any(miss_pct > 0)) {
    emit("Missingness (%; top): ", paste(names(head(miss_pct, 10)),
         sprintf("%.1f", head(miss_pct, 10)), sep = "=", collapse = ", "))
  } else {
    emit("Predictor missingness: none detected")
  }
  if (any(miss_pct >= 40)) warnings <- c(warnings, "At least one predictor has >=40% missingness.")
}

id_candidates <- intersect(tolower(names(dat)), c("id", "patient_id", "subject_id", "stay_id"))
if (length(id_candidates)) {
  actual <- names(dat)[match(id_candidates[[1]], tolower(names(dat)))]
  duplicates <- sum(duplicated(dat[[actual]]) & !is.na(dat[[actual]]))
  emit("ID audit: ", actual, " | duplicated nonmissing IDs=", duplicates)
  if (duplicates > 0) warnings <- c(warnings, "Duplicated IDs detected; confirm the analysis unit and dependence structure.")
}

if (all(required %in% names(dat)) && is.numeric(dat$Time) && is.numeric(dat$Event)) {
  event_times <- dat$Time[dat$Event == 1 & is.finite(dat$Time) & dat$Time > 0]
  if (length(event_times)) {
    qs <- unique(as.numeric(stats::quantile(event_times, c(.25, .5, .75), na.rm = TRUE)))
    emit("Event-time quartiles (candidate horizon context): ",
         paste(signif(qs, 5), collapse = ", "))
  }
}

emit("")
emit("CRITICAL: ", if (length(critical)) length(critical) else 0)
if (length(critical)) for (x in critical) emit("- ", x)
emit("WARNINGS: ", if (length(warnings)) length(warnings) else 0)
if (length(warnings)) for (x in warnings) emit("- ", x)
emit("STATUS: ", if (length(critical)) "FAIL" else "STRUCTURALLY READY FOR DESIGN REVIEW")

cat(paste(lines, collapse = "\n"), "\n")
if (!is.na(report_path)) writeLines(lines, report_path, useBytes = TRUE)
quit(status = if (length(critical)) 2L else 0L)
