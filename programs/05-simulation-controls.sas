
%macro setup;
%global root rawpath filepath filecsv;

%if &SYSSCP = WIN %then %do;
  %let root     = C:\Users\psioda\Documents\Research Papers Temp\bayesDesignCureRate\sas_program_GitHub;
  %let rawpath  = &root.\data\raw_data;
  %let filepath = &rawPath.\mina-e1684-e1690.txt;
  %let filecsv  = &rawPath.\e1690.txt;

  libname raw "&root.\data\raw_data";
  libname sp "&root.\data\sampling_priors";
  libname sc "&root.\data\simulation_controls";

  option noxwait;
  x "cd &root.\data\sampling_priors";
  filename txt pipe "dir *.prior*.dat /on/s/b";

%end;
%else %do;
  %let root     = /nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate;
  %let rawpath  = &root./data/raw_data;
  %let filepath = &rawPath./mina-e1684-e1690.txt;
  %let filecsv  = &rawPath./e1690.txt;

  libname raw "&root./data/raw_data";
  libname sp "&root./data/sampling_priors";
  libname sc "&root./data/simulation_controls";
%end;

%mend setup;
%setup;


%let number_of_nodes = 700; ** number of compute nodes on cluster;
%let nPerLoop        = 500; ** number of simulated datasets per simulation loop;
%let nLoops          = 200; ** number of simulation loops;

data controls1;
 nPerLoop = &nPerLoop.;
 nLoops   = &nLoops.;
 idx      = 1;

 length sp $30.;
 do sp        = "BN","DN","TN","EN";                                    ** null sampling priors to explore;
 do n         = 560 to 860 by 10;                                       ** possible sample size (number of events);
 do a0        = 0.00,0.01,0.02,0.03,0.04,0.05,0.075 to 1.00 by 0.025;   ** possible values for a_0;

  output;  idx + 1; 

 end;
 end;
 end;
run;

data controls2;
 set controls1;
 node_idx+1;
 if node_idx > &number_of_nodes. then node_idx=1;
run;

data sc.controls_null;
 retain node_idx inner_idx;
 set controls2;

 do inner_idx = 1 to nLoops;
    seed           = round(1 + rand('uniform')*2**30);
    covSampleSeed  = round(1 + rand('uniform')*2**30);
    parmSampleSeed = round(1 + rand('uniform')*2**30);
    output;
 end;
 drop nLoops;
run;
