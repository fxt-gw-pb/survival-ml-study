# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

#############################################################################
######Train K-M curve
if(!dir.exists("KM_Result")){
  dir.create("KM_Result")
}
km_data=trainplot_data

colnames(km_data)
Coxph_Median=median(km_data$Coxph)
CoxBoost_Median=median(km_data$CoxBoost)
Survivalsvm_Median=median(km_data$Survivalsvm)
RSF_Median = median(km_data$RSF)
GBM_Median = median(km_data$GBM)
xgboost_Median = median(km_data$xgboost)
superpc_Median = median(km_data$superpc)
plsRcox_Median = median(km_data$plsRcox)



model_names = c("Coxph", "CoxBoost", "RSF", "GBM", "Survivalsvm","xgboost", "superpc", "plsRcox")
formula_list = lapply(model_names, function(col) {
  as.formula(paste("Surv(Time, Event) ~", col))
})
names(formula_list) = model_names

for (cal_models in names(formula_list)) {
  predictor = km_data[,cal_models]
  km_data$RiskGroup = ifelse(predictor > median(predictor, na.rm = TRUE), "high", "low")
  newdata = km_data[,c(1,2,ncol(km_data))]
  fit = survfit(Surv(Time, Event) ~ RiskGroup, data = newdata)
  plot=ggsurvplot(fit, data = newdata,
                  #title = paste0(cal_models),
                  surv.median.line = "hv", # 添加中位数生存时间线
                  legend.title = "Risk", # 设置图例标题
                  legend.labs = c("high", "low"), # 指定图例分组标签
                  legend=c(0.9, 0.9),
                  pval = TRUE, # 设置添加P值
                  pval.method = TRUE, #设置添加P值计算方法
                  conf.int = TRUE, # 设置添加置信区间
                  risk.table = T, # 设置添加风险因子表
                  tables.height = 0.25, # 设置风险表的高度
                  tables.theme = theme_classic(), # 设置风险表的主题
                  palette = c("#ED0000FF",  "#0099B4FF"), # 设置颜色画板
                  ggtheme = theme_classic() 
  )
  pdf(paste0("KM_Result/Train_",cal_models,"_survival.pdf"),5,5,family = "serif")
  print(plot,newpage = FALSE)
  dev.off()
}


#############################################################################
#############################################################################
######Test K-M curve
testkm_data=testplot_data
#colnames(testkm_data)
#Coxph_Median=median(testkm_data$Coxph)
#CoxBoost_Median=median(testkm_data$CoxBoost)
#Survivalsvm_Median=median(testkm_data$Survivalsvm)
#GBM_Median=median(testkm_data$GBM)
#RSF_Median=median(testkm_data$RSF)
#Deepsurv_Median=median(testkm_data$Deepsurv)
#xgboost_Median = median(testkm_data$xgboost)
#superpc_Median = median(testkm_data$superpc)
#plsRcox_Median = median(testkm_data$plsRcox)



for (cal_models in names(formula_list)) {
  predictor = testkm_data[,cal_models]
  testkm_data$RiskGroup = ifelse(predictor > median(predictor, na.rm = TRUE), "high", "low")
  newdata = testkm_data[,c(1,2,ncol(testkm_data))]
  fit = survfit(Surv(Time, Event) ~ RiskGroup, data = newdata)
  plot=ggsurvplot(fit, data = newdata,
                  #title = paste0(cal_models),
                  surv.median.line = "hv", # 添加中位数生存时间线
                  legend.title = "Risk", # 设置图例标题
                  legend.labs = c("high", "low"), # 指定图例分组标签
                  legend=c(0.9, 0.9),
                  pval = TRUE, # 设置添加P值
                  pval.method = TRUE, #设置添加P值计算方法
                  conf.int = TRUE, # 设置添加置信区间
                  risk.table = T, # 设置添加风险因子表
                  tables.height = 0.25, # 设置风险表的高度
                  tables.theme = theme_classic(), # 设置风险表的主题
                  palette = c("#ED0000FF",  "#0099B4FF"), # 设置颜色画板
                  ggtheme = theme_classic() 
  )
  pdf(paste0("KM_Result/Test_",cal_models,"_survival.pdf"),5,5,family = "serif")
  print(plot,newpage = FALSE)
  dev.off()
}
