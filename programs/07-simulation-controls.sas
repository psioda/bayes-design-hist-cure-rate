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

%let number_of_nodes = 651; ** number of compute nodes on cluster;
%let nPerLoop        = 500; ** number of simulated datasets per simulation loop;
%let nLoops          = 200; ** number of simulation loops;

data results; 
 set rs.t1e:;
 rename sp = nsp;
run;

proc means data = results  noprint nway;
 class nsp n a0;
 var rejRate;
 freq nStudy;
  output out = results n=nStudy mean=rejRate;
run;

data temp;
 set results;
 by nsp n a0;

  imputed = 0;
  output;

  if last.n;
  imputed = 1;
  rejRate = .;
  do a0 = 0.0 to 1.0 by 0.01;
   output;
  end;
run; proc sort; by nsp n; run;

ods select none;
ods output FitStatistics = FIT;
proc glm data = temp;
 by nsp ;
 model rejRate = a0|a0|a0|n|n|n;
 output out = smoothed_a0 p=smooth_rejRate;
run;
ods select all;


/*data max_error;*/
/* set smoothed_a0;*/
/* where rejRate > .;*/
/*  error = rejRate-smooth_rejRate;*/
/*run;*/
/**/
/*ods html newfile=proc;*/
/*proc sgplot data = max_error;*/
/* histogram error;*/
/*run;*/

proc sort data = smoothed_a0 nodupkey;
 by nsp n a0 imputed;
run;

proc sort data = smoothed_a0 nodupkey;
 by nsp n a0;
run;


/*ods html newfile=proc;*/
/*proc sgpanel data = smoothed_a0;*/
/* where n in (580,800) and smooth_rejRate <= 0.20;*/
/* panelby n;*/
/* series  x=a0 y = smooth_rejRate /  group = nsp;*/
/* scatter x=a0 y = rejRate / group = nsp markerattrs=(symbol=circlefilled);*/
/* rowaxis values = (0.0 to 0.20 by 0.02) grid;*/
/* colaxis grid;*/
/*run;*/

** calculate the optimal value of a0 for each simulation setting;
data selected;
 set smoothed_a0;
 by nsp n;

  alpha_targ = 0.025;

  diff  = abs(alpha_targ-smooth_rejRate);
  above = (smooth_rejRate>alpha_targ);
run;

proc sort data = selected  out = selected_2 nodupkey dupout=dup;
 by nsp n alpha_targ diff above;
run;

proc sort data = selected_2 out = selected_2(keep = nsp n alpha_targ alpha_targ a0 rejRate smooth_rejRate) nodupkey;
 by nsp n alpha_targ;
run;

data rs.stage_one_optimal;
 set selected_2;
run;



data myattrmap;
length id value $20 MARKERCOLOR linecolor markersymbol $ 20 linepattern $ 9;


input id $ value $ linecolor $ linepattern $ markersymbol;

MARKERCOLOR = linecolor;

datalines;
id LN gray 1 circleFilled
id EN black 1 squareFilled
id TN gray 2 diamondFilled
id DN black 2 triangleFilled
;
run;


data temp;
 set selected;
 where imputed = 0;
  if nsp  = 'BN' then nsp = 'LN';
run;

ods noresults;
options Papersize=("7in","4in") nodate nonumber;
ods pdf file = "&outpath.a0plot.pdf" dpi=400;
ods escapechar='^';
ods html close;
ods graphics / height=4in width=7in noborder;
proc sgpanel data = temp dattrmap=myattrmap ;
 where n in (580,800) and  nsp in ("EN" "TN" "DN" "LN");
 styleattrs datacontrastcolors=(black gray);
 panelby n / rows=1 ;
  scatter x=a0 y=rejRate / group = nsp markerattrs=(size=7 ) attrid=id;
  series x=a0  y=smooth_rejRate / group = nsp lineattrs=(thickness=2) attrid=id;

 *highlow x=a0 low=lower high=upper / group = samplingPrior lineattrs=(thickness=0.8);
 refline 0.025 0.05 / axis=y lineattrs=(pattern=2);
 rowaxis grid values = (0.0 to 0.18 by 0.02) ;
 colaxis grid values = (0 to 1 by 0.2);

  label nsp = 'Sampling Prior' n = 'Number of Subjects' rejRate = 'Bayesian Type I Error Rate';
run; 
ods pdf close;


data controls_alt;
 set rs.stage_one_optimal;


 length asp $5.;
 asp = 'DA'; output;
 asp = 'TA'; output;
 asp = 'PM'; output;

 asp = 'BN';   if nsp in ('BN' 'DN' 'EN') then output;

 asp = 'S1BN'; if nsp in ('DN') then output;
 asp = 'S2BN'; if nsp in ('DN') then output;
 asp = 'S3BN'; if nsp in ('DN') then output;

 asp = 'S1BN'; if nsp in ('BN') then output;
 asp = 'S2BN'; if nsp in ('BN') then output;
 asp = 'S3BN'; if nsp in ('BN') then output;

run;


data controls_alt2;
 retain nsp asp;
 set controls_alt;
 node_idx+1;
 if node_idx > &number_of_nodes. then node_idx=1;
 rename smooth_rejRate = est_t1e;
run;

data sc.controls_alt;
 retain node_idx inner_idx;
 set controls_alt2;
 call streaminit(315125);
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
