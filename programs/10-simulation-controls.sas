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

%let number_of_nodes = 400; ** number of compute nodes on cluster;
%let nPerLoop        = 500; ** number of simulated datasets per simulation loop;
%let nLoops          = 100; ** number of simulation loops;

data controls_phi; 
 set rs.Stage_two_optimal;
 where nsp = 'DN' and asp = 'DA' and n in (560,660,760,860);

 sp = nsp;
 do phi = 0.9150 to 0.975 by 0.0025;
 do rep = 1 to 2;
  output;
 end;
 end;

 sp = asp;
 do phi = 0.9150 to 0.975 by 0.0025;
 do rep = 1 to 2;
  output;
 end;
 end;


 keep sp n a0 smooth_rejRate phi;

run;


data controls_phi2;
 retain sp;
 set controls_phi;
 node_idx+1;
 if node_idx > &number_of_nodes. then node_idx=1;
 rename smooth_rejRate = est_pwr_a0;
run;

data sc.controls_phi;
 retain node_idx inner_idx;
 set controls_phi2;
 call streaminit(64864);
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
