# Extracted verbatim from 小庞统计——生存机器学习预测3.0版本
## Preserve for provenance; adapt a working copy before execution.

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



