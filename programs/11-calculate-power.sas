
%macro setup;
proc datasets library=work noprint kill; run; quit;
%global root rawpath filepath filecsv;

%if &SYSSCP = WIN %then %do;
  %let root     = C:\Users\psioda\Documents\Research Papers Temp\bayesDesignCureRate\sas_program_GitHub;
  %let rawpath  = &root.\data\raw_data;
  %let filepath = &rawPath.\mina-e1684-e1690.txt;
  %let filecsv  = &rawPath.\e1690.txt;

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


%macro loop;
%if &debug=1 %then %let node_id=1;
data time_track;
 start_time = time();
run;

data _null_;
 call symput('dsLabel',put(&node_id.,z5.));
run;

%** read in design parameters for simulation;
data work.__controls__;
 set sc.controls_phi;
 where node_idx = &node_id.;

 if &debug = 1 then do;
  if _n_> 5 then delete;
  nPerLoop = 100;
 end;

 row_idx = _n_;
 call symput('nSimSettings',strip(put(_n_,best.)));
 call symput('nPerLoop',strip(put(nPerLoop,best.)));

run;

** read in covariate data;
data hist;
 set raw.E1690(drop=case );
 replicate = .; delete;
run; proc sort; by replicate; run;

** read in covariate data;
data Cov;
 set raw.E1690;
 keep stratum x: z:;
run;
%let cov = work.cov;


%** loop over different design parameters settings for simulations;
%do loop     = 1 %to &nSimSettings.;
%if %sysfunc(mod(&loop,10))=1 %then %put loop &loop of &nSimSettings.;

  %** create macro variables needed for %SIMULATE_STUDY macro and %FIT_APPROX macro;
  data _null_;
   set work.__controls__(drop=inner_idx);
   where row_idx = &loop.;
   call symput('a0',strip(put(a0,best.)));
   call symput('n',strip(put(n,best.)));

   call symput('nsp',strip(nsp));
   call symput('sp','sp.'||strip(sp));
   call symput('numSimulations',strip(put(nPerLoop,best.)));
   call symput('simSeed',strip(put(seed,30.)));
   call symput('parmSampleSeed',strip(put(parmSampleSeed,30.)));
   call symput('covSampleSeed',strip(put(covSampleSeed,30.)));
   call symput('phi',strip(put(phi,30.20)));
   call symput('est_pwr_a0',strip(put(est_pwr_a0,best.)));
  run;

  %simStudy;

  %fitApprox(phiValue=&phi.);

  data work.parmestgamma;
   length asp $10.;
   set work.parmestgamma;
	asp = strip(sp);
	est_pwr_a0 = &est_pwr_a0.;
	phi = &phi.;
	drop sp;
  run;

  proc append data = work.parmestgamma base = results; run; quit;

  proc means data = results noprint nway;
   class asp a0 n est_pwr_a0 phi;
   freq nStudy;
   var rejRate;
   output out = results(drop=_:) n=nStudy mean=rejRate;
  run;

  proc datasets library=work noprint;
   save results __controls__ hist cov;
  run;
  quit;
%end;

data rs.phi_results_%sysfunc(putn(&node_id.,z4.));
 set results;
run;



%mend;


%let eDist    = rand('uniform')*3;
%let cDist    = 100000;
%let maxDur   = 6.5;


%let node_id = %scan("&sysparm", 1, " ");
%put &=node_id;

** indicator for whether to use debug mode. If debug mode is on then
   at most five design parameter settigs will be evaluated and 
   nPerLoop will be set to 100;
%let debug=0;
option nonotes;
%loop;
option notes;

