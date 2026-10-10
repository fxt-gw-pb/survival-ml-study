# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

plot_calibration_gg <- function(data, model_name, dataset_name){
  formula_cox = as.formula(paste("Surv(Time, Event) ~", model_name))
  cal_list = list()
  time_points = c(12,36,60)
  time_names = c("1-year","3-year","5-year")
  for(i in seq_along(time_points)){
    f = cph(formula_cox,x=T,y=T,surv=T,
            data=data,time.inc=time_points[i])
    cal = rms::calibrate(
      f,
      cmethod="KM",
      method="boot",
      u=time_points[i],
      m=nrow(data)/3,
      B=1000)
    cal_df = data.frame(
      Predicted = cal[, "mean.predicted"],
      Observed = cal[, "KM.corrected"],
      SE = cal[, "std.err"])

    cal_df$Lower95 <- cal_df$Observed - 1.96 * cal_df$SE
    cal_df$Upper95 <- cal_df$Observed + 1.96 * cal_df$SE
    cal_df$Lower95[cal_df$Lower95 < 0] <- 0
    cal_df$Upper95[cal_df$Upper95 > 1] <- 1
    cal_df$Time <- time_names[i]
    cal_list[[i]] <- cal_df
    }
  calibration_data = dplyr::bind_rows(cal_list)
  p = ggplot(
    calibration_data,
    aes(x=Predicted,y=Observed,color=Time))+
    geom_line(linewidth=1)+
    geom_point(size=1.2)+
    geom_errorbar(aes(ymin=Lower95,ymax=Upper95),
      width=0.02,
      linewidth=0.7)+
    geom_abline(intercept=0,slope=1,linetype="dashed",linewidth=0.8)+
    scale_x_continuous(limits=c(0,1),labels=scales::percent)+
    scale_y_continuous(limits=c(0,1),labels=scales::percent)+
    scale_color_manual(
      values=c("1-year"="#E64B35FF",
               "3-year"="#4DBBD5FF",
               "5-year"="#00A087FF"))+
    labs(
      title=paste0(dataset_name,"-",model_name),
      x=paste0(model_name," predicted OS"),
      y="Observed OS",
      color=NULL)+
    theme_classic()+
    theme(
      text=element_text(family="serif",size=12),
      legend.position=c(0.8,0.2),
      plot.title=element_text(hjust=0.5))
  return(p)
}

if(!dir.exists("Calibrate_Result")){
  dir.create("Calibrate_Result")
}
train_cal_data <- trainplot_data
model_names <- c("Coxph","CoxBoost","RSF","GBM","Survivalsvm","xgboost","superpc","plsRcox")
for(model in model_names){
  p = plot_calibration_gg(
    data=train_cal_data,
    model_name=model,
    dataset_name="Train")
  ggsave(filename=paste0("Calibrate_Result/Train_",model,"_calibration_ggplot.pdf"),plot=p,width=5,height=5)
}

test_cal_data <- testplot_data
model_names <- c("Coxph","CoxBoost","RSF","GBM","Survivalsvm","xgboost","superpc","plsRcox")
for(model in model_names){
  p = plot_calibration_gg(
    data=test_cal_data,
    model_name=model,
    dataset_name="Test")
  ggsave(filename=paste0("Calibrate_Result/Test_",model,"_calibration.pdf"),plot=p,width=5,height=5)
}


if(!dir.exists("DCA_Result")){
  dir.create("DCA_Result")
}
############################################################
####Train DCA
#定义时间节点分别为12个月(1年)/36个月(3年)/60个月(5年)
for (time in c(12, 36, 60)) {  
  traindca_data=traindata[,c(1,2)]
  traindca_data$RSF = c(1-summary(survfit(RSF,newdata = trainplot_data),times=time)$surv)
  traindca_data$GBM = c(1-summary(survfit(GBM,newdata = trainplot_data),times=time)$surv)
  traindca_data$Coxph = c(1-summary(survfit(Coxph,newdata = trainplot_data),times=time)$surv)
  traindca_data$CoxBoost = c(1-summary(survfit(CoxBoost,newdata = trainplot_data),times=time)$surv)
  traindca_data$Survivalsvm = c(1-summary(survfit(Survivalsvm,newdata = trainplot_data),times=time)$surv)
  traindca_data$xgboost = c(1-summary(survfit(xgboost,newdata = trainplot_data),times=time)$surv)
  traindca_data$superpc = c(1-summary(survfit(superpc,newdata = trainplot_data),times=time)$surv)
  traindca_data$plsRcox = c(1-summary(survfit(plsRcox,newdata = trainplot_data),times=time)$surv)
  traindca = dcurves::dca(Surv(Time, Event) ~ Coxph+CoxBoost+Survivalsvm+GBM+RSF+xgboost+superpc+plsRcox,
                          data = traindca_data, time = time)
  dca_filtered = as_tibble(traindca) %>%
    dplyr::filter(!is.na(net_benefit))
  dcaplot = ggplot(dca_filtered, aes(x = threshold, y = net_benefit, color = label)) +
    geom_line(lwd = 0.7) +
    coord_cartesian(ylim = c(-0.05, max(dca_filtered$net_benefit)+0.05),
                    xlim = c(0, max(dca_filtered$threshold)+0.05)) +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    labs(x = "Threshold Probability", y = "Net Benefit", color = "") +
    scale_color_manual(values=c("Treat All"="black","Treat None"="grey",
                                "Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
                                "RSF"="#0072B5FF","Survivalsvm"="#F39B7FFF","xgboost"="#DC0000FF",
                                "superpc"="#F7C530FF","plsRcox"="#E377C2FF"))+
    theme_classic()+
    theme(
      plot.title = element_text(hjust = 0.5,size = 15),
      axis.text=element_text(size=12),
      legend.title = element_blank(),
      legend.text = element_text(size=11),
      legend.background = element_blank(),
      axis.title.y = element_text(size=12),#element_blank()
      axis.title.x = element_text(size=12)
      )
  
  pdf(paste0("DCA_Result/train_DCA_", time, ".pdf"), 6, 5.5, family = "serif")
  print(dcaplot) 
  dev.off()
}


############################################################################
##############################################################################
###test DCA

for (time in c(12, 36, 60)) {  
  testdca_data=testdata[,c(1,2)]
  testdca_data$RSF = c(1-summary(survfit(RSF,newdata = testplot_data),times=time)$surv)
  testdca_data$GBM = c(1-summary(survfit(GBM,newdata = testplot_data),times=time)$surv)
  testdca_data$Coxph = c(1-summary(survfit(Coxph,newdata = testplot_data),times=time)$surv)
  testdca_data$CoxBoost = c(1-summary(survfit(CoxBoost,newdata = testplot_data),times=time)$surv)
  testdca_data$Survivalsvm = c(1-summary(survfit(Survivalsvm,newdata = testplot_data),times=time)$surv)
  testdca_data$xgboost = c(1-summary(survfit(xgboost,newdata = testplot_data),times=time)$surv)
  testdca_data$superpc = c(1-summary(survfit(superpc,newdata = testplot_data),times=time)$surv)
  testdca_data$plsRcox = c(1-summary(survfit(plsRcox,newdata = testplot_data),times=time)$surv)
  testdca=dcurves::dca(Surv(Time, Event) ~ Coxph+CoxBoost+Survivalsvm+GBM+RSF+xgboost+superpc+plsRcox,
                       data = testdca_data,time = time)
  dca_filtered = as_tibble(testdca) %>%
    dplyr::filter(!is.na(net_benefit))
  dcaplot = ggplot(dca_filtered, aes(x = threshold, y = net_benefit, color = label)) +
    geom_line(lwd = 0.7) +
    coord_cartesian(ylim = c(-0.05, max(dca_filtered$net_benefit)+0.05),
                    xlim = c(0, max(dca_filtered$threshold)+0.05)) +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    labs(x = "Threshold Probability", y = "Net Benefit", color = "") +
    scale_color_manual(values=c("Treat All"="black","Treat None"="grey",
                                "Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
                                "RSF"="#0072B5FF","Survivalsvm"="#F39B7FFF","xgboost"="#DC0000FF",
                                "superpc"="#F7C530FF","plsRcox"="#E377C2FF"))+
    theme_classic()+
    theme(
      plot.title = element_text(hjust = 0.5,size = 15),
      axis.text=element_text(size=12),
      legend.title = element_blank(),
      legend.text = element_text(size=11),
      legend.background = element_blank(),
      axis.title.y = element_text(size=12),#element_blank()
      axis.title.x = element_text(size=12)
    )
  pdf(paste0("DCA_Result/Test_DCA_", time, ".pdf"), 6, 5.5, family = "serif")
  print(dcaplot) 
  dev.off()
}

if(!dir.exists("ROC_Result")){
  dir.create("ROC_Result")
}
###############################################################
