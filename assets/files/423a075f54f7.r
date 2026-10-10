# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

########################################################
#绘制训练集AUC图
number_max_time_train = subset(trainplot_data,trainplot_data$Event==1)
number_max_time_train = max(number_max_time_train$Time)
number_max_time_train

RSF = coxph(Surv(Time,Event) ~ RSF,trainplot_data,x=TRUE,y=TRUE)
GBM = coxph(Surv(Time,Event) ~ GBM,trainplot_data,x=TRUE,y=TRUE)
Coxph = coxph(Surv(Time,Event) ~ Coxph,trainplot_data,x=TRUE,y=TRUE)
CoxBoost = coxph(Surv(Time,Event) ~ CoxBoost,trainplot_data,x=TRUE,y=TRUE)
Survivalsvm = coxph(Surv(Time,Event) ~ Survivalsvm,trainplot_data,x=TRUE,y=TRUE)
xgboost = coxph(Surv(Time,Event) ~ xgboost,trainplot_data,x=TRUE,y=TRUE)
superpc = coxph(Surv(Time,Event) ~ superpc,trainplot_data,x=TRUE,y=TRUE)
plsRcox = coxph(Surv(Time,Event) ~ plsRcox,trainplot_data,x=TRUE,y=TRUE)

AUCplot =riskRegression::Score(list("Coxph"=Coxph,"GBM"=GBM,"RSF"=RSF,
                               "CoxBoost"=CoxBoost,"Survivalsvm"=Survivalsvm,
                               "xgboost" = xgboost,"superpc" = superpc,"plsRcox"=plsRcox),
                           formula=Surv(Time,Event)~1,
                           data=trainplot_data,
                           metrics="AUC",
                           null.model=F,
                           times=seq(0,70,5))
auc = plotAUC(AUCplot)
pdf("AUC_Result/Train_AUC.pdf",7,5,family = "serif")
ggplot()+geom_line(data=auc, aes(times,AUC,group=model,col=model),linewidth=0.8)+
  geom_point(data=auc, aes(times,AUC,group=model,col=model),shape = 16,size = 1)+
  geom_hline(yintercept=0.7, linetype=2,size=0.8,colour = "grey")+theme_classic()+ 
  labs(title = " ", x="Times", y="AUC")+
  ylim(0.5,1)+
  theme_classic()+
  scale_color_manual(values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
                              "RSF"="#0072B5FF","Survivalsvm"="#F39B7FFF","xgboost"="#DC0000FF",
                              "superpc"="#F7C530FF","plsRcox"="#E377C2FF"))+
  theme(
    plot.title = element_text(hjust = 0.5,size = 15),
    axis.text=element_text(size=12),
    legend.title = element_blank(),
    legend.text = element_text(size=12),
    legend.background = element_blank(),
    axis.title.y = element_text(size=12),#element_blank()
    axis.title.x = element_text(size=12)
  )
dev.off()

########################################################################
#绘制测试集AUC图
number_max_time_test = subset(testplot_data,testplot_data$Event==1)
number_max_time_test = max(number_max_time_test$Time)
number_max_time_test

testRSF = coxph(Surv(Time,Event) ~ RSF,testplot_data,x=TRUE,y=TRUE)
testGBM = coxph(Surv(Time,Event) ~ GBM,testplot_data,x=TRUE,y=TRUE)
testCoxph = coxph(Surv(Time,Event) ~ Coxph,testplot_data,x=TRUE,y=TRUE)
testCoxBoost = coxph(Surv(Time,Event) ~ CoxBoost,testplot_data,x=TRUE,y=TRUE)
testSurvivalsvm = coxph(Surv(Time,Event) ~ Survivalsvm,testplot_data,x=TRUE,y=TRUE)
xgboost = coxph(Surv(Time,Event) ~ xgboost,testplot_data,x=TRUE,y=TRUE)
superpc = coxph(Surv(Time,Event) ~ superpc,testplot_data,x=TRUE,y=TRUE)
plsRcox = coxph(Surv(Time,Event) ~ plsRcox,testplot_data,x=TRUE,y=TRUE)

testAUCplot =riskRegression::Score(list("Coxph"=testCoxph,"GBM"=testGBM,"RSF"=testRSF,
                                    "CoxBoost"=testCoxBoost,"Survivalsvm"=testSurvivalsvm,
                                    "xgboost" = xgboost,"superpc" = superpc,"plsRcox"=plsRcox),
                               formula=Surv(Time,Event)~1,
                               data=testplot_data,
                               metrics="AUC",
                               null.model=F,
                               times=seq(0,70,5))
testauc = plotAUC(testAUCplot)
pdf("AUC_Result/Test_AUC.pdf",7,5,family = "serif")
ggplot()+geom_line(data=testauc, aes(times,AUC,group=model,col=model),linewidth=0.8)+
  geom_point(data=testauc, aes(times,AUC,group=model,col=model),shape = 16,size = 1)+
  #geom_ribbon(data=auc, aes(times,ymin = lower, ymax = upper,fill=model),alpha = 0.1)+
  geom_hline(yintercept=0.7, linetype=2,size=0.8,colour = "grey")+theme_classic()+ 
  labs(title = " ", x="Times", y="AUC")+
  ylim(0.5,1)+
  scale_color_manual(values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
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
dev.off()

###################################################################################

#绘制训练集C-index
C_index = pec::cindex(list("Coxph"=Coxph,"GBM"=GBM,"RSF"=RSF,
                           "CoxBoost"=CoxBoost,"Survivalsvm"=Survivalsvm,
                           "xgboost" = xgboost,"superpc" = superpc,"plsRcox"=plsRcox),
                formula=Surv(Time,Event)~1,
                data=trainplot_data,
                eval.times=seq(0,70,5))
cindex=data.frame(times=seq(0,70,5),C_index$AppCindex)
cindex = gather(cindex,key=Model,value = Cindex,-c(times))
pdf("AUC_Result/Train_C_index.pdf",7,5,family = "serif")
ggplot()+geom_line(data=cindex, aes(times,Cindex,group=Model,col=Model),linewidth=0.8)+
  geom_point(data=cindex, aes(times,Cindex,group=Model,col=Model),shape = 16,size = 1)+
  #geom_ribbon(data=cindex, aes(times,ymin = lower, ymax = upper,fill=Model),alpha = 0.1)+
  geom_hline(yintercept=0.7, linetype=2,size=0.8,colour = "grey")+theme_classic()+ 
  labs(title = " ", x="Times", y="C-index")+
  ylim(0.5,1)+
  scale_color_manual(values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
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
dev.off()

#################################################################

#绘制测试集Cindex
testC_index = pec::cindex(list("Coxph"=Coxph,"GBM"=GBM,"RSF" = RSF,
                               "CoxBoost"=CoxBoost,"Survivalsvm"=Survivalsvm,
                               "xgboost" = xgboost,"superpc" = superpc,"plsRcox"=plsRcox),
                          formula=Surv(Time,Event)~1,
                          data=testplot_data,
                          eval.times=seq(0,70,5))
testcindex=data.frame(times=seq(0,70,5),testC_index$AppCindex)
testcindex = gather(testcindex,key=Model,value = Cindex,-c(times))

pdf("AUC_Result/Test_C_index.pdf",7,5,family = "serif")
ggplot()+geom_line(data=testcindex, aes(times,Cindex,group=Model,col=Model),linewidth=0.8)+
  geom_point(data=testcindex, aes(times,Cindex,group=Model,col=Model),shape = 16,size = 1)+
  #geom_ribbon(data=cindex, aes(times,ymin = lower, ymax = upper,fill=Model),alpha = 0.1)+
  geom_hline(yintercept=0.7, linetype=2,size=0.8,colour = "grey")+theme_classic()+ 
  labs(title = " ", x="Times", y="C-index")+
  ylim(0.5,1)+
  scale_color_manual(values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
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
dev.off()

#############################################################


## ---- second source segment ----

###训练集ROC
dead=subset(trainplot_data,trainplot_data$Event==1)
survival=subset(trainplot_data,trainplot_data$Event==0)
for (time in c(12, 36, 60)) {
  time=time   ##指定绘制ROC的时间节点
  dead$Result=ifelse(dead$Time>time,0,1)
  survival$Result=0
  ROC_data=rbind(dead,survival)
  ######################################################
  ######################################################################
  RSFROC=roc(response=ROC_data$Result,predictor=ROC_data$RSF)
  GBMROC=roc(response=ROC_data$Result,predictor=ROC_data$GBM)
  CoxphROC=roc(response=ROC_data$Result,predictor=ROC_data$Coxph)
  CoxBoostROC=roc(response=ROC_data$Result,predictor=ROC_data$CoxBoost)
  SurvivalsvmROC=roc(response=ROC_data$Result,predictor=ROC_data$Survivalsvm)
  xgboostROC=roc(response=ROC_data$Result,predictor=ROC_data$xgboost)
  superpcROC=roc(response=ROC_data$Result,predictor=ROC_data$superpc)
  plsRcoxROC=roc(response=ROC_data$Result,predictor=ROC_data$plsRcox)
  
  #将各模型的ROC一起打包
  allroc=list(RSF = RSFROC,
              GBM=GBMROC,
              Coxph=CoxphROC,
              CoxBoost=CoxBoostROC,
              Survivalsvm=SurvivalsvmROC,
              xgboost=xgboostROC,
              superpc=superpcROC,
              plsRcox=plsRcoxROC)
  
  #计算各个模型ROC曲线下面积AUC
  RSFAUC=round(pROC::auc(RSFROC),3)
  GBMAUC=round(pROC::auc(GBMROC),3)
  CoxphAUC=round(pROC::auc(CoxphROC),3)
  CoxBoostAUC=round(pROC::auc(CoxBoostROC),3)
  SurvivalsvmAUC=round(pROC::auc(SurvivalsvmROC),3)
  xgboostAUC=round(pROC::auc(xgboostROC),3)
  superpcAUC=round(pROC::auc(superpcROC),3)
  plsRcoxAUC=round(pROC::auc(plsRcoxROC),3)
  
  
  #计算AUC的95%置信区间CI
  RSFCI=ci.auc(RSFROC)
  GBMCI=ci.auc(GBMROC)
  CoxphCI=ci.auc(CoxphROC)
  CoxBoostCI=ci.auc(CoxBoostROC)
  SurvivalsvmCI=ci.auc(SurvivalsvmROC)
  xgboostCI=ci.auc(xgboostROC)
  superpcCI=ci.auc(superpcROC)
  plsRcoxCI=ci.auc(plsRcoxROC)
  
  plotroc = pROC::ggroc(allroc,
                        size=1,
                        legacy.axes = T)+
    theme_classic()+
    # theme_bw()+
    labs(title = 'Trainset ROC curve')+
    theme(
      plot.title = element_text(hjust = 0.5,size = 15),
      axis.text=element_text(size=12),
      legend.title = element_blank(),
      legend.text = element_text(size=10),
      legend.position=c(0.65,0.25),
      legend.background = element_blank(),
      axis.title.y = element_text(size=12),#element_blank()
      axis.title.x = element_text(size=12),
      #panel.border = element_rect(color="black",size=1),
      panel.background = element_blank())+
    geom_segment(aes(x = 0, y = 0, xend = 1, yend = 1),        # 绘制对角线
                 colour='grey', 
                 linetype = 'dotdash')+
    scale_colour_manual(
      breaks=c("GBM","RSF","Coxph","CoxBoost","Survivalsvm", "xgboost", "superpc", "plsRcox"),#
      labels=c(paste0("GBM(AUC=",sprintf("%0.3f", GBMAUC),",95%CI(",
                      sprintf("%0.3f", GBMCI[1]),"-",sprintf("%0.3f", GBMCI[3]),")"),
               paste0("RSF(AUC=",sprintf("%0.3f", RSFAUC),",95%CI(",
                      sprintf("%0.3f", RSFCI[1]),"-",sprintf("%0.3f", RSFCI[3]),")"),
               paste0("Coxph(AUC=",sprintf("%0.3f", CoxphAUC),",95%CI(",
                      sprintf("%0.3f", CoxphCI[1]),"-",sprintf("%0.3f", CoxphCI[3]),")"),
               paste0("CoxBoost(AUC=",sprintf("%0.3f", CoxBoostAUC),",95%CI(",
                      sprintf("%0.3f", CoxBoostCI[1]),"-",sprintf("%0.3f", CoxBoostCI[3]),")"),
               paste0("Survivalsvm(AUC=",sprintf("%0.3f", SurvivalsvmAUC),",95%CI(",
                      sprintf("%0.3f", SurvivalsvmCI[1]),"-",sprintf("%0.3f", SurvivalsvmCI[3]),")"),
               paste0("xgboost(AUC=",sprintf("%0.3f", xgboostAUC),",95%CI(",
                      sprintf("%0.3f", xgboostCI[1]),"-",sprintf("%0.3f", xgboostCI[3]),")"),
               paste0("superpc(AUC=",sprintf("%0.3f", superpcAUC),",95%CI(",
                      sprintf("%0.3f", superpcCI[1]),"-",sprintf("%0.3f", superpcCI[3]),")"),
               paste0("plsRcox(AUC=",sprintf("%0.3f", plsRcoxAUC),",95%CI(",
                      sprintf("%0.3f", plsRcoxCI[1]),"-",sprintf("%0.3f", plsRcoxCI[3]),")")
      ),
      values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
               "RSF"="#0072B5FF","Survivalsvm"="#F39B7FFF","xgboost"="#DC0000FF",
               "superpc"="#F7C530FF","plsRcox"="#E377C2FF"))
  pdf(paste0("ROC_Result/Train_ROC_", time, ".pdf"),5,5,family = "serif")
  print(plotroc)
  dev.off()
}


###################################################


################################################################################################
####################################################################################################
###测试集ROC
dead=subset(testplot_data,testplot_data$Event==1)
survival=subset(testplot_data,testplot_data$Event==0)
for (time in c(12, 36, 60)) {
  time=time   ##指定绘制ROC的时间节点
  dead$Result=ifelse(dead$Time>time,0,1)
  survival$Result=0
  ROC_data=rbind(dead,survival)
  ######################################################
  ######################################################################
  RSFROC=roc(response=ROC_data$Result,predictor=ROC_data$RSF)
  GBMROC=roc(response=ROC_data$Result,predictor=ROC_data$GBM)
  CoxphROC=roc(response=ROC_data$Result,predictor=ROC_data$Coxph)
  CoxBoostROC=roc(response=ROC_data$Result,predictor=ROC_data$CoxBoost)
  SurvivalsvmROC=roc(response=ROC_data$Result,predictor=ROC_data$Survivalsvm)
  xgboostROC=roc(response=ROC_data$Result,predictor=ROC_data$xgboost)
  superpcROC=roc(response=ROC_data$Result,predictor=ROC_data$superpc)
  plsRcoxROC=roc(response=ROC_data$Result,predictor=ROC_data$plsRcox)
  
  #将各模型的ROC一起打包
  allroc=list(RSF = RSFROC,
              GBM=GBMROC,
              Coxph=CoxphROC,
              CoxBoost=CoxBoostROC,
              Survivalsvm=SurvivalsvmROC,
              xgboost=xgboostROC,
              superpc=superpcROC,
              plsRcox=plsRcoxROC)
  
  #计算各个模型ROC曲线下面积AUC
  RSFAUC=round(pROC::auc(RSFROC),3)
  GBMAUC=round(pROC::auc(GBMROC),3)
  CoxphAUC=round(pROC::auc(CoxphROC),3)
  CoxBoostAUC=round(pROC::auc(CoxBoostROC),3)
  SurvivalsvmAUC=round(pROC::auc(SurvivalsvmROC),3)
  xgboostAUC=round(pROC::auc(xgboostROC),3)
  superpcAUC=round(pROC::auc(superpcROC),3)
  plsRcoxAUC=round(pROC::auc(plsRcoxROC),3)
  
  
  #计算AUC的95%置信区间CI
  RSFCI=ci.auc(RSFROC)
  GBMCI=ci.auc(GBMROC)
  CoxphCI=ci.auc(CoxphROC)
  CoxBoostCI=ci.auc(CoxBoostROC)
  SurvivalsvmCI=ci.auc(SurvivalsvmROC)
  xgboostCI=ci.auc(xgboostROC)
  superpcCI=ci.auc(superpcROC)
  plsRcoxCI=ci.auc(plsRcoxROC)
  
  plotroc = pROC::ggroc(allroc,
                        size=1,
                        legacy.axes = T)+
    theme_classic()+
    # theme_bw()+
    labs(title = 'Testset ROC curve')+
    theme(
      plot.title = element_text(hjust = 0.5,size = 15),
      axis.text=element_text(size=12),
      legend.title = element_blank(),
      legend.text = element_text(size=10),
      legend.position=c(0.6,0.25),
      legend.background = element_blank(),
      axis.title.y = element_text(size=12),#element_blank()
      axis.title.x = element_text(size=12),
      #panel.border = element_rect(color="black",size=1),
      panel.background = element_blank())+
    geom_segment(aes(x = 0, y = 0, xend = 1, yend = 1),        # 绘制对角线
                 colour='grey', 
                 linetype = 'dotdash')+
    scale_colour_manual(
      breaks=c("GBM","RSF","Coxph","CoxBoost","Survivalsvm","xgboost", "superpc", "plsRcox"),#
      labels=c(paste0("GBM(AUC=",sprintf("%0.3f", GBMAUC),",95%CI(",
                      sprintf("%0.3f", GBMCI[1]),"-",sprintf("%0.3f", GBMCI[3]),")"),
               paste0("RSF(AUC=",sprintf("%0.3f", RSFAUC),",95%CI(",
                      sprintf("%0.3f", RSFCI[1]),"-",sprintf("%0.3f", RSFCI[3]),")"),
               paste0("Coxph(AUC=",sprintf("%0.3f", CoxphAUC),",95%CI(",
                      sprintf("%0.3f", CoxphCI[1]),"-",sprintf("%0.3f", CoxphCI[3]),")"),
               paste0("CoxBoost(AUC=",sprintf("%0.3f", CoxBoostAUC),",95%CI(",
                      sprintf("%0.3f", CoxBoostCI[1]),"-",sprintf("%0.3f", CoxBoostCI[3]),")"),
               paste0("Survivalsvm(AUC=",sprintf("%0.3f", SurvivalsvmAUC),",95%CI(",
                      sprintf("%0.3f", SurvivalsvmCI[1]),"-",sprintf("%0.3f", SurvivalsvmCI[3]),")"),
               paste0("xgboost(AUC=",sprintf("%0.3f", xgboostAUC),",95%CI(",
                      sprintf("%0.3f", xgboostCI[1]),"-",sprintf("%0.3f", xgboostCI[3]),")"),
               paste0("superpc(AUC=",sprintf("%0.3f", superpcAUC),",95%CI(",
                      sprintf("%0.3f", superpcCI[1]),"-",sprintf("%0.3f", superpcCI[3]),")"),
               paste0("plsRcox(AUC=",sprintf("%0.3f", plsRcoxAUC),",95%CI(",
                      sprintf("%0.3f", plsRcoxCI[1]),"-",sprintf("%0.3f", plsRcoxCI[3]),")")
      ),
      values=c("Coxph"="#E64B35FF","GBM"="#4DBBD5FF","CoxBoost"="#00A087FF",
               "RSF"="#0072B5FF","Survivalsvm"="#F39B7FFF","xgboost"="#DC0000FF",
               "superpc"="#F7C530FF","plsRcox"="#E377C2FF"))
  pdf(paste0("ROC_Result/Test_ROC_", time, ".pdf"),5,5,family = "serif")
  print(plotroc)
  dev.off()
}
#############################################################################
