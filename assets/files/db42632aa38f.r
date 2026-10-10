
#############################################################################
#######################小庞统计######################################
#微信公众号：小庞统计
#哔哩哔哩：小庞统计
#CSDN：小庞统计
#小红书：小庞统计
#闲鱼：R语言小庞统计



library(survival)
library(survminer)
library(foreign)
library(glmnet)
library(survival)
library(randomForestSRC)
#此包安装不上的，就查看压缩包中的文件
library(CoxBoost)
library(survivalsvm)
library(caret)
library(gbm)
library(randomForestSRC)
library(riskRegression)
library(pec)
library(tidyr)
library(dcurves)
#devtools::install_github('yikeshu0611/ggDCA')
library(ggDCA)
library(timeROC)
library(pROC)
library(survcomp)
library(survex)
library(ModelMetrics)
library(rms)
library(autoReg)
library(xgboost)
#devtools::install_github("jedazard/superpc")
library(superpc)
library(plsRcox)
library(plotROC)
library(ggplot2)
library(rms)
library(dplyr)
library(ggsci)


setwd("D:\\小庞统计文件\\小庞统计——启梦R课程\\小庞统计生存机器学习课程\\小庞统计——生存机器学习预测3.0版本")

###############################################################################################
#######训练集和测试集划分
data = read.csv("data.csv",check.names = F,encoding = "GBK")
table(is.na(data))  #检查数据是否有缺失值


table(data$Income)
#对变量进行因子化,注意不需要对生存结局因子化
data$Age = factor(data$Age,levels = c(0,1),labels = c('<65','>=65'))
data$Race = factor(data$Race,levels = c(1,2,3),labels = c('White','Black','Other'))
data$Gender = factor(data$Gender,levels = c(0,1),labels = c('Female','Male'))
data$Grade = factor(data$Grade,levels = c(1,2,3,4),labels = c('GreadI','GreadII','GreadIII','GreadIV'))
data$Surgery = factor(data$Surgery,levels = c(0,1),labels = c('No','Yes'))

data$Radiotherapy = factor(data$Radiotherapy,levels = c(0,1),labels = c('No/Unknown','Yes'))
data$Chemotherapy = factor(data$Chemotherapy,levels = c(0,1),labels = c('No/Unknown','Yes'))
data$Marital = factor(data$Marital,levels = c(0,1),labels = c('Married','Others'))
data$AJCC_stage = factor(data$AJCC_stage,levels = c(1,2,3,4),labels = c('I','II','III','IV'))
data$T_stage = factor(data$T_stage,levels = c(1,2,3,4),labels = c('T1','T2','T3','T4'))

data$N_stage = factor(data$N_stage,levels = c(0,1),labels = c('N0','N1'))
data$M_stage = factor(data$M_stage,levels = c(0,1),labels = c('M0','M1'))
data$SEER_stage = factor(data$SEER_stage,levels = c(1,2,3),labels = c('Localized','Regional','Distant'))
data$Fibrosis_score = factor(data$Fibrosis_score,levels = c(0,1),labels = c('No','Yes'))
data$Tumor_size = factor(data$Tumor_size,levels = c(0,1),labels = c('<50mm','>=50mm'))

data$Income = factor(data$Income,levels = c(1,2,3),labels = c('$<3500','$3500~4999','$>5000'))

#划分数据集
set.seed(123)#设置随机数
inTrain<-createDataPartition(y=data[,"Event"], p=0.7, list=F)#划分训练集,设置训练集的比例为0.7
traindata<-data[inTrain,]#提取训练集数据
testdata<-data[-inTrain,]#提取验证集数据
write.csv(traindata,"traindata.csv",row.names = F)#保存训练集数据
write.csv(testdata,"testdata.csv",row.names = F)#保存验证集数据



#################################################################
######对训练集数据进行单因素、多因素Cox筛选有意义的预后变量
rt=traindata
cox_fit = coxph(Surv(Time,Event)~.,data=rt)

#在上面我们选择单因素里面P值小于0.05的进入多因素Cox回归分析
reuslt_cox = autoReg(cox_fit,uni=TRUE,milti=TRUE,threshold=0.05)
reuslt_cox
write.csv(reuslt_cox,"训练集单因素多因素Cox回归.csv",row.names = F)
##########################################################################
#########提取有意义的变量
colnames(traindata)

#修改定义有意义的变量(若多因素有意义结果较少，可以选择单因素有意义的变量放入)
sigvar=c("Age","Race","Grade","Surgery","Chemotherapy","Marital","SEER_stage","Tumor_size")



#构建Nomogram模型
library(regplot)
fmla = as.formula(paste("Surv(Time, Event)~", paste(sigvar, collapse= "+")))#使用有意义的变量构建模型
res.cox = coxph( fmla , data = traindata)
nom1 = regplot(res.cox,
             plots = c("density", "boxes"),
             clickable=F,
             title="",
             points=TRUE,
             droplines=TRUE,
             #observation=rttrain[20,],
             rank="sd",
             dencol="#00bdcd",boxcol="#f88421",
             failtime = c(1,3,5),
             prfail = F)

Nomo_train = traindata[,c(1,2)]
Nomo_test = testdata[,c(1,2)]
#列线图风险打分
Nomo_train$Nomogram = predict(res.cox, newdata=traindata, type="risk")
Nomo_test$Nomogram = predict(res.cox, newdata=testdata, type="risk")


########################################################################
#重新读入数据保证数据是编码格式
data = read.csv("data.csv",check.names = F,encoding = "GBK")

set.seed(123)#设置随机数
inTrain<-createDataPartition(y=data[,"Event"], p=0.7, list=F)#划分训练集,设置训练集的比例为0.7
traindata<-data[inTrain,]#提取训练集数据
testdata<-data[-inTrain,]#提取验证集数据


#再次进行lasso筛选
lasso_data=traindata[,c("Time","Event",sigvar)] #使用有意义的变量进行lasso筛选
lasso_data$Time[lasso_data$Time<=0]=0.003
x1 = as.matrix(lasso_data[,3:ncol(lasso_data)])
x2 = as.matrix(Surv(lasso_data$Time,lasso_data$Event))
set.seed(123)
fit=glmnet(x1, x2, family="cox",alpha=1 ,maxit=1000)
set.seed(123)
cvfit = cv.glmnet(x1, x2,family = "cox",alpha=1,maxit=1000)
coef.min = coef(cvfit, s = "lambda.min") 
active.min = which(as.numeric(coef.min)!=0)
rid = colnames(x1)[active.min]
#lasso筛选出来的变量
rid


x = coef(fit) 
tmp = as.data.frame(as.matrix(x)) 
tmp$coef = row.names(tmp) 
tmp = reshape::melt(tmp, id = "coef") 
tmp$variable = as.numeric(gsub("s", "", tmp$variable)) 
tmp$coef = gsub('_','-',tmp$coef) 
tmp$lambda = fit$lambda[tmp$variable+1] 
tmp$norm = apply(abs(x[-1,]), 2, sum)[tmp$variable+1] 
head(tmp)
label = sprintf("%0.4f",log(cvfit$lambda.min))
pdf("lasso.fit.plot.pdf",7,5,family = "serif")
ggplot(tmp,aes(log(lambda),value,color = coef)) + 
  geom_vline(xintercept = log(cvfit$lambda.min),
             size=0.8,color='grey60',
             alpha=0.8,linetype=2)+
  geom_line(size=1) + 
  xlab("Lambda (log scale)") + #xlab("L1 norm")+ 
  ylab('Coefficients')+ 
  theme_bw(base_rect_size = 2)+ 
  scale_color_manual(values= c(pal_npg()(10),
                               pal_d3()(10),
                               pal_jco()(9),
                               pal_lancet()(9),
                               pal_tron()(3),
                               pal_ucscgb("default")(26),
                               pal_aaas()(10),
                               pal_simpsons()(10),
                               pal_gsea()(10),
                               pal_jama()(7),
                               pal_locuszoom()(7),
                               pal_tron()(7),
                               pal_nejm()(8),
                               pal_startrek()(7),
                               pal_rickandmorty()(12)
                               
  ))+ 
  scale_x_continuous(expand = c(0.01,0.01))+ 
  scale_y_continuous(expand = c(0.01,0.01))+ 
  theme(panel.grid = element_blank(), 
        axis.title = element_text(size=12,color='black'), 
        axis.text = element_text(size=10,color='black'), 
        legend.title = element_blank(), 
        legend.text = element_text(size=10,color='black'), 
        legend.position = 'right')+ #'bottom',none
  annotate('text',x = log(cvfit$lambda.min)+1,#y=(max(tmp$value)-min(tmp$value))/2,
           y=0.1,
           label=paste0("Optimal Lambda =",label),
           color='black')+guides(col=guide_legend(ncol = 1))
dev.off()
xx = data.frame(lambda=cvfit[["lambda"]],
                cvm=cvfit[["cvm"]],
                cvsd=cvfit[["cvsd"]], 
                cvup=cvfit[["cvup"]],
                cvlo=cvfit[["cvlo"]],
                nozezo=cvfit[["nzero"]]) 
xx$ll = log(xx$lambda) 
xx$NZERO = paste0(xx$nozezo,' vars')

pdf("cvlasso.plot.pdf",7,5,family = "serif")
ggplot(xx,aes(ll,cvm,color=NZERO))+ 
  geom_errorbar(aes(x=ll,ymin=cvlo,ymax=cvup),
                width=0.05,size=1)+ 
  geom_vline(xintercept = xx$ll[which.min(xx$cvm)],
             size=0.8,color='grey60',alpha=0.8,
             linetype=2)+ 
  geom_point(size=2)+ 
  xlab("Log Lambda")+
  ylab('Partial Likelihood Deviance')+ 
  theme_bw(base_rect_size = 1.5)+ 
  scale_color_manual(values= c(pal_npg()(10),
                               pal_d3()(10),
                               pal_jco()(9),
                               pal_lancet()(9),
                               pal_tron()(2),
                               pal_aaas()(10),
                               pal_simpsons()(10)
  ))+ 
  scale_x_continuous(expand = c(0.02,0.02))+ 
  scale_y_continuous(expand = c(0.02,0.02))+ 
  theme(panel.grid = element_blank(), 
        axis.title = element_text(size=12,
                                  color='black'), 
        axis.text = element_text(size=10,
                                 color='black'), 
        legend.title = element_blank(), 
        legend.text = element_text(size=10,
                                   color='black'), 
        legend.position = 'right')+ 
  annotate('text',x = log(cvfit$lambda.min)+1,y=min(xx$cvm)+(max(xx$cvm)-min(xx$cvm))/2,
           label=paste0("Optimal Lambda =",label),
           color='black')+ 
  guides(col=guide_legend(ncol = 1))
dev.off()


#lasso筛选出来的变量
rid

traindata = traindata[,c("Time","Event",sigvar)]#如果选择使用lasso筛选的变量将这里的sigvar改为rid
testdata = testdata[,c("Time","Event",sigvar)]#如果选择使用lasso筛选的变量将这里的sigvar改为rid



#######构建生存机器学习模型
#############################################################
#1.RSF
set.seed(123)
RSF = rfsrc(Surv(Time,Event)~.,data = traindata,
             ntree = 1000,nodesize = 3,##该值建议多调整  
             mtry =2,
             splitrule = 'logrank',
             importance = T,
             proximity = T,
             forest = T,
             seed = 123)
train_plot_data_rsf = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(RSF, traindata)$predicted))
test_plot_data_rsf = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(RSF, testdata)$predicted))


#2.GBM
set.seed(123)
GBM = gbm(formula = Surv(Time,Event)~.,data = traindata,distribution = 'coxph',
           n.trees = 1000,
           interaction.depth = 5,
           n.minobsinnode = 3,
           shrinkage = 0.01,
           cv.folds = 10,n.cores = 6)
train_plot_data_gbm = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(GBM,traindata,n.trees = 1000,type = 'link')))
test_plot_data_gbm = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(GBM,testdata,n.trees = 1000,type = 'link')))




#3.Coxph
Coxph = coxph(Surv(Time,Event)~.,traindata)
train_plot_data_Coxph = data.frame(traindata[,c("Time","Event")],predicted=predict(Coxph,type = 'risk',newdata = traindata))
test_plot_data_Coxph = data.frame(testdata[,c("Time","Event")],predicted=predict(Coxph,type = 'risk',newdata = testdata))



#4.CoxBoost
set.seed(123)
pen = optimCoxBoostPenalty(traindata[,'Time'],traindata[,'Event'],as.matrix(traindata[,-c(1,2)]),
                            trace=TRUE,start.penalty=200,parallel = T)
cv.res = cv.CoxBoost(traindata[,'Time'],traindata[,'Event'],as.matrix(traindata[,-c(1,2)]),
                      maxstepno=200,K=3,type="verweij",penalty=pen$penalty)
CoxBoost = CoxBoost(traindata[,'Time'],traindata[,'Event'],as.matrix(traindata[,-c(1,2)]),
                stepno=cv.res$optimal.step,penalty=pen$penalty)

train_plot_data_CoxBoost = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(CoxBoost,newdata=traindata[,-c(1,2)], newtime=traindata[,1], newstatus=traindata[,2], type="lp")))
test_plot_data_CoxBoost = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(CoxBoost,newdata=testdata[,-c(1,2)], newtime=testdata[,1], newstatus=testdata[,2], type="lp")))





#5.survivalsvm
set.seed(123)
survivalsvm = survivalsvm(Surv(Time,Event)~., data= traindata, gamma.mu = 0.5,
                          opt.meth = "quadprog",
                          diff.meth = "makediff3",
                          kernel = "lin_kernel",
                          sgf.sv = 5,
                          sigf = 7,
                          maxiter = 100,
                          margin = 0.1, bound = 10)
train_plot_data_survivalsvm = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(survivalsvm, traindata)$predicted))
test_plot_data_survivalsvm = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(survivalsvm, testdata)$predicted))




#6.xgboost
set.seed(123)
xgb_param = list(objective = "survival:cox",
              booster = "gbtree",
              eval_metric = "cox-nloglik",
              eta = 0.03,
              max_depth = 3,
              subsample = 1,
              colsample_bytree = 1,
              gamma = 0.5)
traindata_y = ifelse(traindata$Event == 1, traindata$Time, -traindata$Time)
traindata_matrix= xgb.DMatrix(data = as.matrix(traindata[,3:ncol(traindata)]), label = traindata_y)

xgboost = xgb.train(params = xgb_param, data = traindata_matrix, nrounds = 100, watchlist = list(val2 = traindata_matrix),
                     early_stopping_rounds = 50)


train_plot_data_xgboost = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(xgboost, newdata = as.matrix(traindata[,3:ncol(traindata)]), type = "risk")))
test_plot_data_xgboost = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(xgboost, newdata = as.matrix(testdata[,3:ncol(testdata)]), type = "risk")))


#7.superpc
set.seed(123)
traindata_superpc = list(x=t(traindata[,-c(1,2)]),y=traindata$Time,censoring.status=traindata$Event,featurenames=colnames(traindata)[-c(1,2)])
testdata_superpc = list(x=t(testdata[,-c(1,2)]),y=testdata$Time,censoring.status=testdata$Event,featurenames=colnames(testdata)[-c(1,2)])
superpc_fit = superpc.train(data = traindata_superpc,type = 'survival',s0.perc = 0.5) #default
superpc = superpc.cv(superpc_fit,traindata_superpc,n.threshold = 20,#default 
                     n.fold = 10,
                     n.components=3,
                     min.features=5,
                     max.features=nrow(traindata_superpc$x),
                     compute.fullcv= TRUE,
                     compute.preval=TRUE)
superpc_ff_train = superpc.predict(superpc_fit,traindata_superpc,traindata_superpc,threshold = superpc$thresholds[which.max(superpc[["scor"]][1,])],n.components = 1)
train_plot_data_superpc = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(superpc_ff_train$v.pred))
  

superpc_ff_test = superpc.predict(superpc_fit,traindata_superpc,testdata_superpc,threshold = superpc$thresholds[which.max(superpc[["scor"]][1,])],n.components = 1)
test_plot_data_superpc = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(superpc_ff_test$v.pred))


#8.plsRcox
set.seed(123)
cv.plsRcox.res=cv.plsRcox(list(x=traindata[,3:ncol(traindata)],time=traindata$Time,status=traindata$Event),nt=10,nfold = 10,verbose = F)
plsRcox = plsRcox(traindata[,3:ncol(traindata)],time=traindata$Time,event=traindata$Event,nt=3)
train_plot_data_plsRcox = data.frame(traindata[,c("Time","Event")],predicted=as.numeric(predict(plsRcox, newdata = as.matrix(traindata[,3:ncol(traindata)]), type="risk")))
test_plot_data_plsRcox = data.frame(testdata[,c("Time","Event")],predicted=as.numeric(predict(plsRcox, newdata = as.matrix(testdata[,3:ncol(testdata)]), type = "risk")))



########################################################


########################################################
#整理训练集预测值
trainplot_data1=cbind(train_plot_data_Coxph[,c(1,2)],Coxph=train_plot_data_Coxph$predicted)
trainplot_data2=cbind(trainplot_data1,CoxBoost=train_plot_data_CoxBoost$predicted)
trainplot_data3=cbind(trainplot_data2,RSF=train_plot_data_rsf$predicted)
trainplot_data4=cbind(trainplot_data3,GBM=train_plot_data_gbm$predicted)
trainplot_data5=cbind(trainplot_data4,Survivalsvm=train_plot_data_survivalsvm$predicted)
trainplot_data6=cbind(trainplot_data5,xgboost=train_plot_data_xgboost$predicted)
trainplot_data7=cbind(trainplot_data6,superpc=train_plot_data_superpc$predicted)
trainplot_data=cbind(trainplot_data7,plsRcox=train_plot_data_plsRcox$predicted)
write.csv(trainplot_data,"Train_plot_data.csv",row.names = F,quote = F)

#整理测试机预测值
testplot_data1=cbind(test_plot_data_Coxph[,c(1,2)],Coxph=test_plot_data_Coxph$predicted)
testplot_data2=cbind(testplot_data1,CoxBoost=test_plot_data_CoxBoost$predicted)
testplot_data3=cbind(testplot_data2,RSF=test_plot_data_rsf$predicted)
testplot_data4=cbind(testplot_data3,GBM=test_plot_data_gbm$predicted)
testplot_data5=cbind(testplot_data4,Survivalsvm=test_plot_data_survivalsvm$predicted)
testplot_data6=cbind(testplot_data5,xgboost=test_plot_data_xgboost$predicted)
testplot_data7=cbind(testplot_data6,superpc=test_plot_data_superpc$predicted)
testplot_data=cbind(testplot_data7,plsRcox=test_plot_data_plsRcox$predicted)
write.csv(testplot_data,"Test_plot_data.csv",row.names = F,quote = F)




if(!dir.exists("SHAP_Result")){
  dir.create("SHAP_Result")
}
library(fastshap)
library(shapviz)
library(ggplot2)
#提取训练集数据
X_train <- traindata[,3:ncol(traindata)]
#对各个模型进行shap解释

#######################################################################
#RSF模型shap解释
#############################################################
pred_RSF=function(object,newdata){
  predict(
    object,
    newdata=newdata
  )$predicted
}
shap_RSF <- fastshap::explain(
  object=RSF,
  X=traindata[,3:ncol(traindata)],
  pred_wrapper=pred_RSF,
  nsim=100
)
shapviz_RSF=shapviz(
  shap_RSF,
  X=traindata[,3:ncol(traindata)]
)

#######################################################################
#GBM模型shap解释
#############################################################
pred_GBM=function(object,newdata){
  predict(
    object,
    newdata,
    n.trees=1000,
    type="link"
  )
  }
shap_GBM <- fastshap::explain(
  GBM,
  X=traindata[,3:ncol(traindata)],
  pred_wrapper=pred_GBM,
  nsim=100
)
shapviz_GBM <- shapviz(
  shap_GBM,
  X=traindata[,3:ncol(traindata)]
)



##################################################
#Coxph模型
####################################################
pred_Coxph <- function(object,newdata){
  predict(object,newdata=newdata,type="risk")
  }
set.seed(123)
shap_Coxph <- fastshap::explain(
  object=Coxph,
  X=X_train,
  pred_wrapper=pred_Coxph,
  nsim=100
)
shapviz_Coxph <- shapviz(
  shap_Coxph,
  X_train
)
#######################################################################
#CoxBoost模型shap解释
#############################################################
pred_CoxBoost=function(object,newdata){
  res <- predict(
    object,
    newdata=as.matrix(newdata),
    newtime=rep(1,nrow(newdata)),
    newstatus=rep(1,nrow(newdata)),
    type="lp"
  )
  as.numeric(res)}
shap_CoxBoost <- fastshap::explain(
  object = CoxBoost,
  X = traindata[,3:ncol(traindata)],
  pred_wrapper = pred_CoxBoost,
  nsim = 100
)
shapviz_CoxBoost <- shapviz(
  shap_CoxBoost,
  X=traindata[,3:ncol(traindata)]
)

#######################################################################
#Survivalsvm模型shap解释
#############################################################
pred_Survivalsvm=function(object,newdata){
  res <- predict(
    object,
    newdata
  )
  as.numeric(res$predicted)
}

shap_Survivalsvm <- fastshap::explain(
  survivalsvm,
  X=traindata[,3:ncol(traindata)],
  pred_wrapper=pred_Survivalsvm,
  nsim=100
)
shapviz_Survivalsvm <- shapviz(
  shap_Survivalsvm,
  X=traindata[,3:ncol(traindata)]
)

#######################################################################
#Xgboost模型shap解释
#############################################################
X_train_matrix=as.matrix(traindata[,3:ncol(traindata)])
shapviz_Xgboost=
  shapviz(
    xgboost,
    X_pred=X_train_matrix
  )

#######################################################################
#Superpc模型shap解释
#############################################################
pred_Superpc=function(object,newdata){
  data=list(
    x=t(as.matrix(newdata)),
    y=rep(1,nrow(newdata)),
    censoring.status=rep(1,nrow(newdata)),
    featurenames=colnames(newdata)
  )
  as.numeric(
    superpc.predict(
      superpc_fit,
      traindata_superpc,
      data,
      threshold=superpc$thresholds[which.max(superpc[["scor"]][1,])],
      n.components=1
    )$v.pred
  )}
shap_Superpc = explain(
  superpc_fit,
  X=traindata[,3:ncol(traindata)],
  pred_wrapper=pred_Superpc,
  nsim=100
)
shapviz_Superpc <- shapviz(
  shap_Superpc,
  X=traindata[,3:ncol(traindata)]
)

#######################################################################
#plsRcox模型shap解释
#############################################################
pred_plsRcox=function(object,newdata){
  predict(
    object,
    newdata=as.matrix(newdata),
    type="risk"
  )}
shap_plsRcox <- explain(
  plsRcox,
  X=traindata[,3:ncol(traindata)],
  pred_wrapper=pred_plsRcox,
  nsim=100
)
shapviz_plsRcox <- shapviz(
  shap_plsRcox,
  X=traindata[,3:ncol(traindata)]
)

save.image("Survival_ML_model_SHAP.RData")
load("Survival_ML_model_SHAP.RData")
##############################################################
#####SHAP绘图可视化
#单样本特征
pdf(paste0("SHAP_Result/SHAP_Survivalsvm_sv_force.pdf"),7,5,family = "serif")
sv_force(shapviz_Survivalsvm, row_id = 12,size = 9)+
  ggtitle(label = "Survival Survivalsvm")+
  theme(plot.title = element_text(hjust = 0.5,face = "bold",color = "black"),
        axis.title = element_text(color = "black"))
dev.off()
#特征重要性蜂群图
pdf(paste0("SHAP_Result/SHAP_Survivalsvm_importance_beeswarm.pdf"),7,5,family = "serif")
sv_importance(shapviz_Survivalsvm, kind = "beeswarm", 
              viridis_args = list(begin = 0.25, end = 0.85, option = "B"),#A-H
              show_numbers = F)+
  ggtitle(label = "Survival Survivalsvm")+
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5,face = "bold",color = "black"),
        axis.title = element_text(color = "black"))
dev.off()

#特征重要性条形图
pdf(paste0("SHAP_Result/SHAP_Survivalsvm_importance_bar.pdf"),7,5,family = "serif")
sv_importance(shapviz_Survivalsvm, kind = "bar", show_numbers = F,
              fill = "#fca50a")+
  theme_classic()+
  ggtitle(label = "Survival Survivalsvm")+
  theme(plot.title = element_text(hjust = 0.5,face = "bold",color = "black"),
        axis.title = element_text(color = "black"))
dev.off()

#瀑布图
pdf(paste0("SHAP_Result/SHAP_Survivalsvm_waterfall.pdf"),5,5)
sv_waterfall(shapviz_Survivalsvm, row_id = 2,
             fill_colors = c("#f7d13d", "#a52c60"))+
  theme_bw()+
  ggtitle(label = "Survival Survivalsvm")+
  theme(plot.title = element_text(hjust = 0.5,face = "bold",color = "black"),
        axis.title = element_text(color = "black"))
dev.off()

# #偏相关依赖图
library(ggplot2)
library(gridExtra)
#提取数据计算得出的shap值
shap_value = data.frame(shap_Survivalsvm)
colnames(shap_value) = paste0(colnames(shap_value),"_shap")
orign_data = traindata[,3:ncol(traindata)]
plot_data = cbind(orign_data,shap_value)
shap_vars = grep("_shap$", colnames(plot_data), value = TRUE)
feature_vars = gsub("_shap$", "", shap_vars)

# 创建所有 SHAP 偏依赖图的列表
plot_list = lapply(seq_along(shap_vars), function(i) {
  feature = feature_vars[i]
  shap = shap_vars[i]
  
  ggplot(plot_data, aes_string(x = feature, y = shap)) +
    geom_point(alpha = 0.6, color = "#a52c60", size = 2) +
    geom_smooth(method = "loess", se = TRUE, color = "#f7d13d") +
    theme_classic(base_family = "serif") +
    labs(
      x = feature,
      y = paste("SHAP value for", feature),
      title = paste("Partial Dependence: SHAP vs", feature)
    )
})
pdf("SHAP_Result/SHAP_Survivalsvm_Partial_Dependence_plot.pdf",16,16,family = "serif")
grid.arrange(grobs = plot_list, ncol = 4)
dev.off()


if(!dir.exists("AUC_Result")){
  dir.create("AUC_Result")
}
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
