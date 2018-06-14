
options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
node.idx = as.numeric(args[1]);

if (.Platform$OS.type == "windows") { node.idx = 1 }


if (.Platform$OS.type == "windows") {
           root = "C:/Users/psioda/Documents/Research Papers Temp/bayesDesignCureRate/sas_program_GitHub";
 } else {  root = "/nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate";
 } 


 raw.path = paste(root,"data/raw_data",sep="/");
 src.path = paste(root,"programs/R",sep="/"); 
 raw.data <- read.table(file=paste(raw.path,"e1690.txt",sep="/"),head=T);
 sp.path = paste(root,"data/sampling_priors",sep="/");

 source(paste(src.path,"slice_cr_cpp.R",sep="/"));


set.seed(986965);
a0       = 1.00;
seed.vec = round(runif(5000,1,2^20));

   
y = raw.data$obsTime;
v = raw.data$event;
s = raw.data$stratum;
z = raw.data$z;
x = as.matrix(raw.data[,c("x1","x2")]);
w = rep(a0,length(y));

numMCMC  = 1000000;
numThin  = 2;
nbi      = 1000;
debug    = 0;
fixGamma = NA;

set.seed(seed.vec[node.idx]);
samples = cureRateFit(y,v,s,z,x,w,fixGamma,numMCMC,numThin,nbi,debug);




 c1 = grep("alpha",  colnames(samples), value=TRUE)
 c2 = grep("lambda", colnames(samples), value=TRUE)
 colnames(samples) <- c("gamma", "beta1", "beta2", "beta3", "alpha1", "alpha2", "lambda1", "lambda2");
 samples[,c(c1,c2)] = exp(samples[,c(c1,c2)]);

 write.table(samples,file=paste(sp.path,paste("hist.posterior.",node.idx,".dat",sep=""),sep="/"));

 
 def.null.prior = samples[(samples[,1]>=0),]; 
 ##hist( def.null.prior[,1],freq=F,breaks=100);
 write.table(def.null.prior,file=paste(sp.path,paste("def.null.prior.",node.idx,".dat",sep=""),sep="/"));

 def.alt.prior  = samples[(samples[,1]<0),];  
 ##hist( def.alt.prior[,1],freq=F,breaks=100);
 write.table(def.alt.prior,file=paste(sp.path,paste("def.alt.prior.",node.idx,".dat",sep=""),sep="/"));

 trn.null.prior = samples[(samples[,1]>=0 & samples[,1]<=0.15),];      
 ##hist( trn.null.prior[,1],freq=F,breaks=100);
 write.table(trn.null.prior,file=paste(sp.path,paste("trn.null.prior.",node.idx,".dat",sep=""),sep="/"));

 trn.alt.prior  = samples[(samples[,1]<=-0.14 & samples[,1]>=-0.41),]; 
 ##hist( trn.alt.prior[,1],freq=F,breaks=100);
 write.table(trn.alt.prior,file=paste(sp.path,paste("trn.alt.prior.",node.idx,".dat",sep=""),sep="/"));


