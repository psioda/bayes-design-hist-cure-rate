
%macro setup;
%global root rawpath filepath filecsv;

%if &SYSSCP = WIN %then %do;
  %let root     = C:\Users\psioda\Documents\Research Papers Temp\bayesDesignCureRate\sas_program_GitHub;
  %let rawpath  = &root.\data\raw_data;
  %let filepath = &rawPath.\mina-e1684-e1690.txt;
  %let filecsv  = &rawPath.\e1690.txt;

  libname raw "&root.\data\raw_data";
  libname sp "&root.\data\sampling_priors";

  option noxwait;
  x "cd &root.\data\sampling_priors";
  filename txt pipe "dir *.dat /on/s/b";

%end;
%else %do;
  %let root     = /nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate;
  %let rawpath  = &root./data/raw_data;
  %let filepath = &rawPath./mina-e1684-e1690.txt;
  %let filecsv  = &rawPath./e1690.txt;

  libname raw "&root./data/raw_data";
  libname sp "&root./data/sampling_priors";

  filename txt pipe "ls &root./data/sampling_priors/*.dat";

%end;

%mend setup;
%setup;


%macro read;

proc datasets library=work noprint kill; run; quit;

data files;
 length fileName $500;
 infile txt dlmstr="3820232905";
 input fileName;
run;


data _null_;
 set files;
 call symput('file'||strip(put(_n_,best.)),strip(fileName));
 call symput('nFiles',strip(put(_n_,best.)));
run;

%do i = 1 %to &nFiles.;
  data temp;
   infile "&&file&i." dlm=' ' firstobs=2  dsd;
   input obs gamma beta1 beta2 beta3 alpha1 alpha2 lambda1 lambda2;
  run; 

  %if %index(%upcase(&&file&i.),DEF.ALT) %then %do;
   proc append data = temp base = DA force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),TRN.ALT) %then %do;
   proc append data = temp base = TA force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),DEF.NULL) %then %do;
   proc append data = temp base = DN force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),TRN.NULL) %then %do;
   proc append data = temp base = TN force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),ELICITED) %then %do;
   proc append data = temp base = EN force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),BOUNDARY) %then %do;
   proc append data = temp base = BN force; run; quit;
  %end;

  %if %index(%upcase(&&file&i.),HIST) %then %do;
   proc append data = temp base = HIST force; run; quit;
  %end;

%end;

%macro wrt(A);
 data sp.&A.;
  set &A.(drop=obs obs=200000);
 run;

 proc means data = sp.&A. noprint;
  var _all_;
  output out = sp.&A._post_means n(gamma)= mean= std= / autoname;
 run;
%mend;

%if %sysfunc(exist(DA)) %then %wrt(DA);
%if %sysfunc(exist(DN)) %then %wrt(DN);
%if %sysfunc(exist(TA)) %then %wrt(TA);
%if %sysfunc(exist(TN)) %then %wrt(TN);
%if %sysfunc(exist(EN)) %then %wrt(EN);
%if %sysfunc(exist(BN)) %then %wrt(BN);
%if %sysfunc(exist(HIST)) %then %wrt(HIST);
%mend read;
%read;

%macro sp(sp,s);
data sp.S&s.&sp.;
 set sp.&sp.; if _n_ = 1 then set sp.&sp._post_means(keep=beta1_StdDev);
 beta1 = beta1 - &s.*beta1_StdDev;
 drop beta1_StdDev;
run;
 proc means data = sp.S&s.&sp. noprint;
  var _all_;
  output out = sp.S&s.&sp._post_means n(gamma)= mean= std= / autoname;
 run;

%mend;
%sp(DN,1);
%sp(DN,2);
%sp(DN,3);

%sp(BN,1);
%sp(BN,2);
%sp(BN,3);

data sp.PM;
 set sp.DA_post_means;
 keep gamma_mean beta1_mean beta2_mean beta3_mean lambda1_mean lambda2_mean alpha1_mean alpha2_mean;
 rename gamma_mean    = gamma  
        beta1_mean    = beta1   
        beta2_mean    = beta2   
		beta3_mean    = beta3   
        lambda1_mean  = lambda1 
        lambda2_mean  = lambda2 
        alpha1_mean   = alpha1 
        alpha2_mean   = alpha2;  
run;

