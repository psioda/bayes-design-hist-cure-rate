# bayes-design-historical-cure-rate
SAS programs used for SIM manuscript "Bayesian Design of a Survival Trial with a Cured Fraction using Historical Data".

SAS programs are setup to be executed on a Linux computing cluster using both R (3.3.1) and SAS (9.4). The root paths referenced in all programs in the "programs" folder will need to be updated for the code to work. For SAS programs, the root path is set via a SAS macro variable in a SAS macro named SETUP that is placed at the top of each program. See below:

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

The SETUP macro is designed to allow the code to be run in windows for debugging and on linux for array job submission. For the R programs, a similar technique is used. See below:

if (.Platform$OS.type == "windows") {
           root = "C:/Users/psioda/Documents/Research Papers Temp/bayesDesignCureRate/sas_program_GitHub";
 } else {  root = "/nas/longleaf/home/psioda/stat-projects/bayesDesignCureRate";
 } 
 
Once all paths are executed, one can use the SLURM scheduler shell scripts to submit the required jobs on a SLURM-based computing cluster. For example, one would first submit the command "sbatch batch-00.sh" (assuming the current directory is the "cluster-scripts" directory). Each batch script should be run after the previous script completes.
 
