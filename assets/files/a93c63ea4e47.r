args<-commandArgs(trailingOnly=TRUE); if(length(args)<2L)stop("Usage: prepare_split.R <input.csv> <out> [seed] [fraction] [zero_policy]")
input<-args[1];out<-args[2];seed<-if(length(args)>=3)as.integer(args[3])else 123L;frac<-if(length(args)>=4)as.numeric(args[4])else .7;policy<-if(length(args)>=5)args[5]else "error"
d<-read.csv(input,check.names=FALSE,stringsAsFactors=FALSE); if(!all(c("Time","Event")%in%names(d)))stop("Require Time and Event")
if(any(!d$Event%in%c(0,1),na.rm=TRUE))stop("Event must be 0/1"); if(anyNA(d[,c("Time","Event")]))stop("Missing Time/Event")
bad<-which(d$Time<=0); exclusions<-data.frame(row=integer(),reason=character())
if(length(bad)){if(policy=="error")stop(length(bad)," rows have Time <= 0");if(policy=="exclude"){exclusions<-data.frame(row=bad,reason="Time <= 0");d<-d[-bad,,drop=FALSE]}else if(startsWith(policy,"epsilon:")){v<-as.numeric(sub("epsilon:","",policy));if(!is.finite(v)||v<=0)stop("Invalid epsilon");d$Time[bad]<-v}else stop("Unknown zero policy")}
set.seed(seed); idx<-unlist(lapply(split(seq_len(nrow(d)),d$Event),function(ii)sample(ii,ceiling(length(ii)*frac))),use.names=FALSE);idx<-sort(unique(idx))
dir.create(out,recursive=TRUE,showWarnings=FALSE);d$.split<-ifelse(seq_len(nrow(d))%in%idx,"development","validation")
write.csv(d[d$.split=="development",setdiff(names(d),".split"),drop=FALSE],file.path(out,"development.csv"),row.names=FALSE)
write.csv(d[d$.split=="validation",setdiff(names(d),".split"),drop=FALSE],file.path(out,"validation.csv"),row.names=FALSE)
write.csv(data.frame(row=seq_len(nrow(d)),split=d$.split),file.path(out,"split_manifest.csv"),row.names=FALSE);write.csv(exclusions,file.path(out,"exclusions.csv"),row.names=FALSE)
