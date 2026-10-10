# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

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
