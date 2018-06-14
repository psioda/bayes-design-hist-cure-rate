
%macro setup;
%global root rawpath filepath filecsv;

%if &SYSSCP = WIN %then %do;
  %let root     = C:\Users\psioda\Documents\Research Papers Temp\bayesDesignCureRate\sas_program_GitHub;
  %let rawpath  = &root.\data\raw_data;
  %let filepath = &rawPath.\mina-e1684-e1690.txt;
  %let filecsv  = &rawPath.\e1690.txt;

  libname raw "&root.\data\raw_data";
  libname sp "&root.\data\sampling_priors";



%end;
%else %do;
  %let root     = /nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate;
  %let rawpath  = &root./data/raw_data;
  %let filepath = &rawPath./mina-e1684-e1690.txt;
  %let filecsv  = &rawPath./e1690.txt;

  libname raw "&root./data/raw_data";
  libname sp "&root./data/sampling_priors";
%end;

%mend setup;
%setup;




data raw.E1684_E1690;
 infile "&filePath." firstobs=3;
 input case study age trt sex perform nodes breslow stage failtime rfscens survtime scens;
run;


data raw.E1690;
 set raw.E1684_E1690;
 where stage ^= -2 and nodes > . and study = 1690;
 if failtime = 0 then failtime = 0.5 / 365;

 stratum = 1+(stage>2);

 x1 = (nodes=3);
 x2 = (nodes=4);
 
 z  = trt;

 event   = rfscens;
 obsTime = failtime;

 keep case z x1-x2 stratum event obsTime;

run;

proc export data = raw.E1690 outfile="&filecsv." replace dbms=DLM LABEL; run; quit;

