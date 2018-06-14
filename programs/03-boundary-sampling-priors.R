
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


set.seed(37823);
a0       = 1.00;
seed.vec = round(runif(5000,1,2^20));

   
y = raw.data$obsTime;
v = raw.data$event;
s = raw.data$stratum;
z = raw.data$z;
x = as.matrix(raw.data[,c("x1","x2")]);
w = rep(a0,length(y));

numMCMC = 1;
numThin = 1;
nbi     = 250;
debug   = 0;
nSamp   = 4000;

set.seed(seed.vec[node.idx]);
fixGamma = rep(0,nSamp);


##hist(fixGamma,freq=F,breaks=100 );
for (i in (1:nSamp))
{
  samples = cureRateFit(y,v,s,z,x,w,fixGamma[i],numMCMC,numThin,nbi,debug);

  if (i==1) { all.samples = samples;                    }
  if (i>1)  { all.samples = rbind(samples,all.samples); }
}

samples = all.samples;
rm(all.samples);




 c1 = grep("alpha",  colnames(samples), value=TRUE)
 c2 = grep("lambda", colnames(samples), value=TRUE)
 colnames(samples) <- c("gamma", "beta1", "beta2", "beta3", "alpha1", "alpha2", "lambda1", "lambda2");

 samples[,c(c1,c2)] = exp(samples[,c(c1,c2)]);

 elicited.null.prior = samples; 
 ##hist( elicited.null.prior[,1],freq=F,breaks=100);
 write.table(elicited.null.prior,file=paste(sp.path,paste("boundary.null.prior.",node.idx,".dat",sep=""),sep="/"));
