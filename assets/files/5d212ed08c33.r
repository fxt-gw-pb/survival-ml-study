# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

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
