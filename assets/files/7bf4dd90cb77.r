args <- commandArgs(trailingOnly=TRUE)
if(length(args)<2L) stop("Usage: Rscript inventory_source.R <source_dir> <output_dir>")
src <- normalizePath(args[[1]],mustWork=TRUE); out <- args[[2]]; dir.create(out,recursive=TRUE,showWarnings=FALSE)
f <- list.files(src,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE)
fi <- file.info(f); keep <- !fi$isdir
manifest <- data.frame(relative=sub(paste0("^",gsub("([.|()\\^{}+$*?]|\\[|\\])","\\\\\\1",src),"[/\\\\]?"),"",f[keep]),
                       extension=tolower(tools::file_ext(f[keep])),bytes=fi$size[keep],modified=as.character(fi$mtime[keep]),
                       md5=unname(tools::md5sum(f[keep])),stringsAsFactors=FALSE)
assign_skill <- function(x) {
  y <- gsub("\\\\", "/", x)
  if (grepl("包的安装/|CoxBoost-master|distr6", y, ignore.case=TRUE)) return("pang-survml-environment")
  if (grepl("训练集单因素多因素Cox回归", y)) return("pang-survml-cox-screen")
  if (grepl("(^|/)(data|traindata|testdata)[.]csv$", y, ignore.case=TRUE)) return("pang-survml-data")
  if (grepl("(Train|Test)_plot_data[.]csv$", y, ignore.case=TRUE)) return("pang-survml-predictions")
  if (grepl("AUC_Result/.+C_index", y, ignore.case=TRUE)) return("pang-survml-cindex")
  if (grepl("AUC_Result/", y, ignore.case=TRUE)) return("pang-survml-time-auc")
  if (grepl("Calibrate_Result/", y, ignore.case=TRUE)) return("pang-survml-calibration")
  if (grepl("DCA_Result/", y, ignore.case=TRUE)) return("pang-survml-dca")
  if (grepl("KM_Result/", y, ignore.case=TRUE)) return("pang-survml-km")
  if (grepl("ROC_Result/", y, ignore.case=TRUE)) return("pang-survml-roc")
  if (grepl("SHAP_Result/", y, ignore.case=TRUE)) return("pang-survml-shap")
  if (grepl("lasso.*[.]pdf$", y, ignore.case=TRUE)) return("pang-survml-lasso")
  if (grepl("Nomogram[.]pdf$", y, ignore.case=TRUE)) return("pang-survml-nomogram")
  if (grepl("Survival_ML_model_SHAP[.]RData$", y, ignore.case=TRUE)) return("pang-survml-artifact-audit|pang-survml-individual-predictor|pang-survml-shap")
  if (grepl("[.]RData$", y, ignore.case=TRUE)) return("pang-survml-artifact-audit")
  if (grepl("生存机器学习模型3[.]0版本[.]R$", y)) return("pang-survml (line-level routing in source-coverage.md)")
  if (grepl("使用说明|[.]Rhistory$", y, ignore.case=TRUE)) return("pang-survml")
  "pang-survml-source-audit"
}
manifest$assigned_skill <- vapply(manifest$relative, assign_skill, character(1))
write.csv(manifest,file.path(out,"source_file_manifest.csv"),row.names=FALSE,fileEncoding="UTF-8")
rdata <- manifest$relative[grepl("\\.RData$",manifest$relative,ignore.case=TRUE)]
objects <- list()
for(rel in rdata){e<-new.env(parent=emptyenv()); n<-load(file.path(src,rel),envir=e); objects[[rel]]<-do.call(rbind,lapply(sort(n),function(x){o<-e[[x]];data.frame(file=rel,object=x,class=paste(class(o),collapse="/"),bytes=as.numeric(object.size(o)),dimensions=paste(dim(o),collapse="x"))}))}
if(length(objects)) write.csv(do.call(rbind,objects),file.path(out,"rdata_object_manifest.csv"),row.names=FALSE,fileEncoding="UTF-8")
print(table(manifest$extension,useNA="ifany"))
