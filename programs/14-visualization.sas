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

/**** results for null sampling prior bias ***/
data results;
 set rs.bias: indsname=ds;
  node_idx = input(scan(ds,3,"_"),best.);
run; proc sort; by  n ; run;

data bias_controls;
 set sc.controls_bias:;
run; proc sort nodupkey; by  n node_idx b1p b2p b3p l1p l2p; run;

data combined;
 merge results(in=a) bias_controls(in=b);
 by  n node_idx ;
  if a and b;

  if first.n and n=560 then value = 0.051;
  if first.n and n=860 then value = 0.057;
run;

ods noresults;
options Papersize=("7in","4in") nodate nonumber;
ods pdf file = "&outpath.nsp_bias_hist.pdf" dpi=400;
ods escapechar='^';
ods html close;
ods graphics / height=4in width=7in noborder;
proc sgpanel data = combined;
 panelby n;
 histogram rejRate / nbins=50 fillattrs=(color=lightgray);
 refline value / axis=x lineattrs=(color=black pattern=2);
 colaxis values = (0.045 to 0.065 by 0.005);
 label rejRate = 'Estimated Type I Error Rate' n = 'Number of Subjects';
run; 
run;
ods pdf close;



/*** Results for modified critical value approach ***/
data results;
 set rs.phi_R: indsname=ds;
 by asp n;
  node_idx = input(scan(ds,3,"_"),best.);

  output;
  if last.n then do phi = 0.92 to 0.975 by 0.001;
   rejRate = .;
   output;
  end;
run; proc sort; by asp n; run;

proc glm data = results noprint;
 by asp n;
 model rejRate = phi|phi|phi;
 output out = smoothed_rr p=smooth_rejRate;
run;
quit;


** calculate the optimal value of a0 for each simulation setting;
data selected;
 set smoothed_rr;
 where asp = 'DN';
 by asp n;

  alpha_targ = 0.025;

  diff  = abs(alpha_targ-smooth_rejRate);
  above = (smooth_rejRate>alpha_targ);
run;

proc sort data = selected  out = selected_2 nodupkey dupout=dup;
 by n alpha_targ diff above;
run;

proc sort data = selected_2 out = selected_2(keep = n phi smooth_rejRate rename=(smooth_rejRate=est_t1e)) nodupkey;
 by n ;
run;

data power;
 set smoothed_rr;
 where asp = 'DA';
 by asp n;
run; proc sort nodupkey; by n phi; run;


data power;
 merge power(in=a) selected_2(in=b);
 by n phi;
  if a and b;
  rename smooth_rejRate = est_pwr; 
run;

data rs.phi_design;
 retain asp nsp n;
 set power;
 nsp = "DN";
 drop nStudy rejRate node_idx;
run;
