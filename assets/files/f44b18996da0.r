#!/usr/bin/env Rscript

# Eight publication-style examples for the survival ML skill suite.
# All numbers are synthetic and must not be interpreted as study results.

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(patchwork))
source("../../journal-ggplot-stylebook/assets/journal-style.R")
set.seed(20260818)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

cols <- c(CoxPH="#E64B35", RSF="#0072B5", GBM="#4DBBD5", CoxBoost="#00A087",
          `Survival-SVM`="#F39B7F", XGBoost="#DC0000", SuperPC="#F7C530", plsRcox="#E377C2")
finish <- function(p, title, subtitle="Synthetic demonstration data") p +
  labs(title=title, subtitle=subtitle) + theme_journal(base_size=10, base_family="sans") +
  theme(plot.title=element_text(face="bold", size=12),
        plot.subtitle=element_text(size=8.5, color="grey40", margin=margin(b=6)),
        legend.position="top", legend.title=element_blank())

# 1. Cohort split ----------------------------------------------------------
d1 <- data.frame(set=rep(c("Development","Validation"), each=2),
                 status=rep(c("Censored","Event"), 2), n=c(569,856,245,368))
p1 <- ggplot(d1, aes(set,n,fill=status)) + geom_col(width=.62,color="white") +
  geom_text(aes(label=n),position=position_stack(vjust=.5),size=4) +
  scale_fill_manual(values=c("#C6CDF7","#F98400")) + labs(x=NULL,y="Participants")
p1 <- finish(p1,"Cohort allocation","Stratified 70/30 split | n = 2,038")

# 2. LASSO coefficient paths ----------------------------------------------
lambda <- seq(-6,1,length.out=70)
d2 <- do.call(rbind,lapply(1:10,function(i)data.frame(
  log_lambda=lambda,coef=(runif(1,-1.4,1.4))*(1-plogis((lambda-runif(1,-2,0))*2)),
  variable=paste0("X",i))))
p2 <- ggplot(d2,aes(log_lambda,coef,color=variable))+geom_line(linewidth=.75)+
  geom_vline(xintercept=-2.4,linetype="dashed",color="grey35")+
  annotate("text",x=-2.3,y=1.25,label="lambda.min",hjust=0,size=3)+
  scale_color_manual(values=rep(pal_soft,length.out=10))+labs(x="log(lambda)",y="Coefficient")
p2 <- finish(p2,"LASSO-Cox coefficient paths")

# 3. Time-dependent AUC ----------------------------------------------------
d3 <- expand.grid(month=seq(6,60,6),model=names(cols))
base <- c(.72,.79,.76,.75,.73,.78,.70,.71); names(base)<-names(cols)
d3$auc <- pmin(.92,pmax(.58,base[d3$model]+.025*sin(d3$month/13)+rnorm(nrow(d3),0,.008)))
p3 <- ggplot(d3,aes(month,auc,color=model))+geom_hline(yintercept=.70,linetype="dashed",color="grey60")+
  geom_line(linewidth=.8)+geom_point(size=1.5)+scale_color_manual(values=cols)+
  scale_y_continuous(limits=c(.6,.9),breaks=seq(.6,.9,.1))+labs(x="Months",y="Time-dependent AUC")
p3 <- finish(p3,"Validation discrimination over time")

# 4. ROC -------------------------------------------------------------------
fpr <- seq(0,1,length.out=101)
d4 <- do.call(rbind,lapply(seq_along(cols),function(i){power<-c(3.0,4.2,3.5,3.3,2.8,3.8,2.5,2.7)[i];
  data.frame(fpr=fpr,tpr=1-(1-fpr)^power,model=names(cols)[i])}))
p4 <- ggplot(d4,aes(fpr,tpr,color=model))+geom_abline(linetype="dashed",color="grey65")+
  geom_line(linewidth=.9)+scale_color_manual(values=cols)+coord_equal()+
  labs(x="1 - Specificity",y="Sensitivity")
p4 <- finish(p4,"36-month ROC curves")

# 5. Calibration -----------------------------------------------------------
d5 <- expand.grid(pred=seq(.05,.75,length.out=8),model=c("RSF","CoxPH","XGBoost"))
offset <- c(RSF=.01,CoxPH=.035,XGBoost=-.025)
d5$obs <- pmin(.9,pmax(0,d5$pred+offset[d5$model]+rnorm(nrow(d5),0,.025)))
p5 <- ggplot(d5,aes(pred,obs,color=model))+geom_abline(linetype="dashed",color="grey55")+
  geom_line(linewidth=.8)+geom_point(size=2)+scale_color_manual(values=cols[c("RSF","CoxPH","XGBoost")])+
  coord_equal(xlim=c(0,.8),ylim=c(0,.8))+labs(x="Predicted risk",y="Observed risk")
p5 <- finish(p5,"36-month calibration")

# 6. DCA -------------------------------------------------------------------
thr <- seq(.05,.65,length.out=80)
d6 <- rbind(data.frame(threshold=thr,benefit=pmax(0,.12-.10*thr),strategy="RSF"),
            data.frame(threshold=thr,benefit=pmax(0,.105-.095*thr),strategy="CoxPH"),
            data.frame(threshold=thr,benefit=pmax(-.02,.11-.18*thr),strategy="Treat all"),
            data.frame(threshold=thr,benefit=0,strategy="Treat none"))
p6 <- ggplot(d6,aes(threshold,benefit,color=strategy))+geom_line(linewidth=.9)+
  scale_color_manual(values=c(RSF=unname(cols["RSF"]),CoxPH=unname(cols["CoxPH"]),`Treat all`="grey45",`Treat none`="black"))+
  labs(x="Threshold probability",y="Net benefit")
p6 <- finish(p6,"Decision curve analysis")

# 7. Kaplan-Meier ----------------------------------------------------------
n <- 260; risk <- rep(c("Low risk","High risk"),each=n/2)
event_time <- c(rexp(n/2,.025),rexp(n/2,.055)); censor <- runif(n,8,60)
time <- pmin(event_time,censor,60); event <- as.integer(event_time<=censor & event_time<=60)
fit <- survival::survfit(survival::Surv(time,event)~risk)
s <- summary(fit); d7 <- data.frame(time=s$time,surv=s$surv,lower=s$lower,upper=s$upper,
                                    risk=sub("risk=","",s$strata))
p7 <- ggplot(d7,aes(time,surv,color=risk,fill=risk))+geom_ribbon(aes(ymin=lower,ymax=upper),alpha=.12,color=NA)+
  geom_step(linewidth=.9)+scale_color_manual(values=c("#7294D4","#F98400"))+
  scale_fill_manual(values=c("#7294D4","#F98400"))+scale_y_continuous(labels=scales::percent)+
  annotate("text",x=4,y=.18,label="Log-rank p < 0.001",hjust=0,size=3.3)+
  labs(x="Months",y="Survival probability")
p7 <- finish(p7,"Training-derived risk groups")

# 8. SHAP beeswarm ---------------------------------------------------------
features <- c("SOFA","Lactate","Age","Creatinine","NLR","MAP","Platelets","Albumin")
d8 <- do.call(rbind,lapply(seq_along(features),function(i){v<-rnorm(80); data.frame(
  feature=features[i],value=v,shap=v*runif(1,.08,.32)*ifelse(i%%3==0,-1,1)+rnorm(80,0,.08))}))
d8$feature <- factor(d8$feature,levels=rev(features))
p8 <- ggplot(d8,aes(shap,feature,color=value))+geom_vline(xintercept=0,color="grey75")+
  geom_point(position=position_jitter(height=.18),size=1.5,alpha=.75)+
  scale_color_gradient2(low="#3B9AB2",mid="grey90",high="#D45590")+
  labs(x="SHAP value (model risk score)",y=NULL,color="Feature value")
p8 <- finish(p8,"RSF global SHAP explanation")

plots <- list(p1,p2,p3,p4,p5,p6,p7,p8)
ids <- c("01_cohort_split","02_lasso_paths","03_time_auc","04_roc","05_calibration","06_dca","07_kaplan_meier","08_shap")
for(i in seq_along(plots)) ggsave_journal(file.path("figures",paste0(ids[i],".png")),plots[[i]],6.4,4.8,300)
gallery <- wrap_plots(lapply(plots,function(x)x+theme(legend.position="none",plot.subtitle=element_blank(),plot.title=element_text(size=9))),ncol=2)+
  plot_annotation(title="Survival Machine Learning — Example Figure Set",
                  subtitle="Eight synthetic demonstrations; replace with audited study data",
                  theme=theme(plot.title=element_text(face="bold",size=18),plot.subtitle=element_text(size=11,color="grey40")))
ggsave("00_example_gallery.png",gallery,width=13,height=19,units="in",dpi=180)
write.csv(data.frame(file=paste0(ids,".png"),type=c("Cohort split","LASSO paths","Time-dependent AUC","ROC","Calibration","DCA","Kaplan-Meier","SHAP")),
          "figure_manifest.csv",row.names=FALSE)
cat("Created 8 example figures and gallery in",normalizePath(getwd(),winslash="/"),"\n")
