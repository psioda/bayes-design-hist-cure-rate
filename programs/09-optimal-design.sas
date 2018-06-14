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


data results; 
 set rs.pwr:;
run;

proc means data = results  noprint nway;
 class nsp asp n a0;
 var rejRate;
 freq nStudy;
  output out = results n=nStudy mean=rejRate;
run;

data temp;
 set results;
 by nsp asp n a0;

  imputed = 0;
  output;

  if last.asp;

  imputed = 1;
  rejRate = .;
  a0      = .;

  do n = 560 to 860 by 10;
   output;
  end;
run; proc sort; by nsp asp n a0 imputed; run;


proc glm data = temp noprint;
 by nsp asp ;
 model rejRate = n|n|n;
 output out = smoothed_rr p=smooth_rejRate;
run;

proc glm data = temp noprint;
 by nsp asp ;
 model a0 = n|n|n;
 output out = smoothed_a0 p=smoothed_a0;
run;

data smoothed;
 merge smoothed_rr smoothed_a0;
 by nsp asp n a0 imputed;
run;

/*data max_error;*/
/* set smoothed;*/
/* where rejRate > .;*/
/*  error1 = rejRate-smooth_rejRate;*/
/*  error2 = a0-smoothed_a0;*/
/*run;*/
/**/
/*ods html newfile=proc;*/
/*proc sgplot data = max_error;*/
/* histogram error1;*/
/* histogram error2;*/
/*run;*/

proc sort data = smoothed nodupkey;
 by nsp asp n imputed a0 ;
run;

proc sort data = smoothed nodupkey;
 by nsp asp n;
run;

data data rs.stage_two_optimal;
 set smoothed;

 drop _: a0;
 rename smoothed_a0 = a0;
run;






/*ods html newfile=proc;*/
/*proc sgpanel data = rs.stage_two_optimal;*/
/* where asp = 'BN';;*/
/* panelby asp;*/
/**/
/* series  x=n y = smooth_rejRate /  group = nsp;*/
/* scatter x=n y = rejRate / group = nsp markerattrs=(symbol=circlefilled);*/
/* rowaxis values = (0.0 to 0.06 by 0.01) grid;*/
/* colaxis grid;*/
/*run;*/


data table_designs;
 set rs.stage_two_optimal;

      if nsp = 'BN' then col = 10;
 else if nsp = 'EN' then col = 20;
 else if nsp = 'TN' then col = 30;
 else if nsp = 'DN' then col = 40;
 else delete;


 colval = a0;
 if asp = 'DA' then output;

      if asp = 'DA' then col = col + 1;
 else if asp = 'TA' then col = col + 2;
 else if asp = 'PM' then col = col + 3;
 else delete;

 colVal = smooth_rejRate;
 output;

run; 

proc sort data = table_designs; 
 by n col; 
run;

proc transpose data = table_designs out = table_designs(drop=_:) prefix=c;
 by n;
 id col;
 var colVal;
run;

data rs.table_designs(keep=n c:) 
     rs.latex_table_designs(keep=n v: rename=(
        v10 = BN_a0
        v11 = BN_DA
		v12 = BN_TA
		v13 = BN_PM

        v20 = EN_a0
        v21 = EN_DA
		v22 = EN_TA
		v23 = EN_PM

        v30 = TN_a0
        v31 = TN_DA
		v32 = TN_TA
		v33 = TN_PM

        v40 = DN_a0
        v41 = DN_DA
		v42 = DN_TA
		v43 = DN_PM));
 set table_designs;

 array c[*] c10 c11 c12 c13  c20 c21 c22 c23  c30 c31 c32 c33  c40 c41 c42 c43;
 array v[*] $40. v10 v11 v12 v13  v20 v21 v22 v23  v30 v31 v32 v33  v40 v41 v42 v43;

 do j = 1 to dim(c);
  if substr(vname(c[j]),3,1) = '0' then v[j] = tranwrd(put(c[j],4.2),' ','~');
  else do;
      c[j] = round(c[j],0.01);
      v[j] = tranwrd(put(c[j],4.2),' ','~');
	       if c[j] < 0.70 then v[j] = '\cl{1.0}'||strip(v[j]);
	  else if c[j] < 0.80 then v[j] = '\cl{0.9}'||strip(v[j]);
	  else if c[j] < 0.90 then v[j] = '\cl{0.8}'||strip(v[j]);
	  else                     v[j] = '\cl{0.7}'||strip(v[j]);

  end;
 end;

run;


option ls=175;
data _null_;
 set rs.latex_table_designs;
 put n     "& "
     BN_a0 "& " BN_DA "& " BN_TA "& " BN_PM "& & "
     EN_a0 "& " EN_DA "& " EN_TA "& " EN_PM "& & "
     DN_a0 "& " DN_DA "& " DN_TA "& " DN_PM "\\";

run;


data myattrmap;
length id value $20 MARKERCOLOR linecolor markersymbol $ 20 linepattern $ 9;

infile datalines dlm=',';
input id $ value $ linecolor $ linepattern $ markersymbol;

MARKERCOLOR = linecolor;

datalines;
id,EN,darkGray,1,squareFilled
id,DN,lightgray,2,triangleFilled
id,No Borrowing,black,1,diamondFilled
;
run;

proc format;
 value $ nspc
  'BN' = 'No Borrowing';
run;

data temp;
 set rs.stage_two_optimal;
 by nsp asp;

 if first.asp or last.asp then do;
   a0c = put(a0,4.2);
   rrc = put(smooth_rejRate,5.3);
 end;

 where imputed = 0;
run;



ods noresults;
options Papersize=("7in","4in") nodate nonumber;
ods pdf file = "&outpath.worst_case_performance.pdf" dpi=400;
ods escapechar='^';
ods html close;
ods graphics / height=4in width=7in noborder;
proc sgplot data = temp  dattrmap=myattrmap ;
 styleattrs datacontrastcolors=(black gray);
 where asp = 'BN';

  scatter x=n y=rejRate        / group = nsp markerattrs=(size=9 ) attrid=id datalabel = a0c datalabelpos=TOP;
  scatter x=n y=rejRate        / group = nsp markerattrs=(size=9 ) attrid=id datalabel = rrc datalabelpos=BOTTOM;
  series  x=n y=smooth_rejRate / group = nsp lineattrs=(thickness=2) attrid=id;

 *highlow x=a0 low=lower high=upper / group = samplingPrior lineattrs=(thickness=0.8);
 **refline 0.025 0.05 / axis=y lineattrs=(pattern=2);
 yaxis grid values = (0.0 to 0.06 by 0.01) ;
 xaxis grid values = (560 to 860 by 50);
  format nsp $nspc.;
  label nsp = 'Sampling Prior' n = 'Number of Subjects' rejRate = 'Supremum Bayesian Type I Error Rate';
run;
ods pdf close;


data myattrmap;
length id value $20 MARKERCOLOR linecolor markersymbol $ 20 linepattern $ 9;

infile datalines dlm=',';
input id $ value $ linecolor $ linepattern $ markersymbol;

MARKERCOLOR = linecolor;

datalines;
id,LN,lightgray,1,circleFilled
id,LN + 1.0 SD,gray     ,1,diamondFilled
id,LN + 2.0 SD,darkgray ,1,squareFilled
id,LN + 3.0 SD,black    ,1,starFilled
;
run;

data  temp;
 set rs.stage_two_optimal;
  where  nsp = 'DN' and asp in ('BN' 'S1BN' 'S2BN' 'S3BN');
 length asp2 $20;
 if asp = 'BN'   then asp2 = 'LN';
 if asp = 'S1BN' then asp2 = 'LN + 1.0 SD';
 if asp = 'S2BN' then asp2 = 'LN + 2.0 SD';
 if asp = 'S3BN' then asp2 = 'LN + 3.0 SD';
run;


ods noresults;
options Papersize=("7in","4in") nodate nonumber;
ods pdf file = "&outpath.nsp_bias.pdf" dpi=400;
ods escapechar='^';
ods html close;
ods graphics / height=4in width=7in noborder;

proc sgplot data = temp  dattrmap=myattrmap;

 label asp2 = 'Sampling Prior' n = 'Number of Subjects' rejRate = 'Bayesian Type I Error Rate';
 series  x=n y = smooth_rejRate / group = asp2 lineattrs=(thickness=2) attrid=id ;
 scatter x=n y = rejRate        / group = asp2  markerattrs=(size=9 ) attrid=id ;
 yaxis values = (0.000 to 0.070 by 0.01) grid;
 xaxis grid values = (560 to 860 by 50);
run;

ods pdf close; 
