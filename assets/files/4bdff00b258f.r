args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: Rscript preflight.R <data.csv> <output_dir>")
input <- args[[1]]; out <- args[[2]]
d <- read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
required <- c("Time", "Event")
missing_required <- setdiff(required, names(d))
if (length(missing_required)) stop("Missing columns: ", paste(missing_required, collapse = ", "))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
event_values <- sort(unique(d$Event[!is.na(d$Event)]))
report <- data.frame(
  check = c("rows", "columns", "missing_cells", "duplicate_rows", "time_le_zero",
            "event_values", "events", "censored", "predictors"),
  value = c(nrow(d), ncol(d), sum(is.na(d)), sum(duplicated(d)), sum(d$Time <= 0, na.rm = TRUE),
            paste(event_values, collapse = "|"), sum(d$Event == 1, na.rm = TRUE),
            sum(d$Event == 0, na.rm = TRUE), ncol(d) - 2L),
  severity = c("info", "info", if(sum(is.na(d))) "review" else "ok",
               if(anyDuplicated(d)) "review" else "ok",
               if(any(d$Time <= 0, na.rm = TRUE)) "critical" else "ok",
               if(!setequal(as.numeric(event_values), c(0, 1))) "critical" else "ok",
               "info", "info", if(ncol(d) <= 2L) "critical" else "ok"),
  stringsAsFactors = FALSE
)
write.csv(report, file.path(out, "preflight_report.csv"), row.names = FALSE, fileEncoding = "UTF-8")
writeLines(capture.output(sessionInfo()), file.path(out, "session_info.txt"), useBytes = TRUE)
print(report, row.names = FALSE)
if (any(report$severity == "critical")) quit(status = 2L)
