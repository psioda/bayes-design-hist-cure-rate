%macro setup;
%global root rawpath filepath filecsv outpath;

%if &SYSSCP = WIN %then %do;
  %let root     = C:\Users\psioda\Documents\Research Papers Temp\bayesDesignCureRate\sas_program_GitHub;
  %let rawpath  = &root.\data\raw_data;
  %let filepath = &rawPath.\mina-e1684-e1690.txt;
  %let filecsv  = &rawPath.\e1690.txt;
  %let outpath  = &root.\data\simulation_results\;

  libname raw "&root.\data\raw_data";
  libname sp  "&root.\data\sampling_priors";
  libname sc  "&root.\data\simulation_controls";
  libname rs  "&root.\data\simulation_results";

  %include "&root.\macros\simStudy.sas";
  %include "&root.\macros\fitApprox.sas";

  option noxwait;

  %let sysparm = 1;

%end;
%else %do;
  %let root     = /nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate;
  %let rawpath  = &root./data/raw_data;
  %let filepath = &rawPath./mina-e1684-e1690.txt;
  %let filecsv  = &rawPath./e1690.txt;
  %let outpath  = &root./data/simulation_results/;

  %include "&root./macros/simStudy.sas";
  %include "&root./macros/fitApprox.sas";

  libname raw "&root./data/raw_data";
  libname sp  "&root./data/sampling_priors";
  libname sc  "&root./data/simulation_controls";
  libname rs  "&root./data/simulation_results";
%end;


ods html close;
ods listing close;

%mend setup;
%setup;

%let number_of_nodes = 486; ** number of compute nodes on cluster;
%let nPerLoop        = 500; ** number of simulated datasets per simulation loop;
%let nLoops          = 100; ** number of simulation loops;

option notes;

data controls_bias; 
 set rs.stage_one_optimal;
 where nsp in ('DN') and n in (560,860);


 keep nsp n a0 smooth_rejRate;
  rename nsp = sp smooth_rejRate = est_t1e;
run;

data controls_bias;
 set controls_bias;

do b1p = -1.0 to 1.0  by 1;
do b2p = -1.0 to 1.0  by 1;
do b3p = -1.0 to 1.0  by 1;
do l1p = -1.0 to 1.0  by 1;
do l2p = -1.0 to 1.0  by 1;

 output;

end;
end;
end;
end;
end;

run;

data controls_bias2;
 retain sp;
 set controls_bias;
 node_idx+1;
 if node_idx > &number_of_nodes. then node_idx=1;
run;

data sc.controls_bias;
 retain node_idx inner_idx;
 set controls_bias2;
 call streaminit(694845);
 nPerLoop = &nPerLoop.;
 nLoops   = &nLoops.;

 do inner_idx = 1 to nLoops;
    seed           = round(1 + rand('uniform')*2**30);
    covSampleSeed  = round(1 + rand('uniform')*2**30);
    parmSampleSeed = round(1 + rand('uniform')*2**30);
    output;
 end;

 drop nLoops;
run;

data sp.perturb;
 set controls_bias;
  if _n_ = 1 then set sp.BN_post_means;

  array parm[5] beta1        beta2        beta3         lambda1        lambda2;
  array mn[5]   beta1_mean   beta2_mean   beta3_mean    lambda1_mean   lambda2_mean;
  array sd[5]   beta1_stdDev beta2_stdDev beta3_stdDev  lambda1_stdDev lambda2_stdDev;
  array pt[5]   b1p          b2p          b3p           l1p            l2p ;
  do j = 1 to dim(mn);
    parm[j] = mn[j] + pt[j]*sd[j];
  end;

  keep gamma_mean beta1-beta3 alpha1_mean alpha2_mean lambda1-lambda2;
      rename gamma_mean=gamma alpha1_mean = alpha1 alpha2_mean = alpha2;
run;

