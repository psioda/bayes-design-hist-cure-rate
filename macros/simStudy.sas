
%macro simStudy;
  
proc surveyselect data = &sp.  out = SP_selected  method=urs sampsize=&nPerLoop. outhits noprint                 seed = &parmSampleSeed.;  run; quit;
proc surveyselect data = &cov. out = COV_selected method=urs sampsize=&n.        outhits noprint reps=&nPerLoop. seed = &covSampleSeed.;   run; quit; 

data SP_selected;
 retain replicate;
 set SP_selected(drop=numberHits);
  replicate+1;
  
  alpha1 = exp(alpha1);
  alpha2 = exp(alpha2);
  lambda1 = exp(lambda1);
  lambda2 = exp(lambda2);
run;

data sim;
 merge COV_selected(drop=NumberHits) SP_selected;
 by replicate;
 call streaminit(&simSeed.);

  array beta[*] beta:;
  array alpha[*] alpha:;
  array lambda[*] lambda:;

  array x[*] x:;

  censTime   = &cDist.;
  enrollTime = &eDist.;

  event = 1;

  logTheta = z*gamma + beta1;
  do j = 1 to dim(x);
   logTheta = logTheta + x[j]*beta[j+1];
  end;
  theta = exp(logTheta);

  ni = rand('Poisson',theta);

   obsTime = 1e10;
   do j = 1 to ni;
    obsTime = min(obsTime,rand('weibull',alpha[stratum],1/Lambda[stratum]));
   end;

   if obsTime > censTime then do;
    obsTime = censTime;
	event   = 0;
   end;

   drop beta: gamma alpha: lambda: theta logTheta: censTime  ni j;
run;

proc datasets library=work noprint;
 delete COV_selected;
run;
quit;

proc means data = sim noprint nway;
 class replicate;
 var enrollTime;
 output out = minEnr(keep = replicate minEnrTime) min=minEnrTime;
run;

data sim;
 merge sim minEnr;
 by replicate;
  enrollTime = enrollTime - minEnrTime;

  elapsedTime = enrollTime + obsTime;
  if elapsedTime > &maxDur. then do;
   obsTime =  &maxDur. - enrollTime;
   event   = 0;
  end;

  drop elapsedTime enrollTime minEnrTime;
run;

proc datasets library=work noprint;
 delete minEnr;
run;
quit;


proc transpose data = SP_selected out = SP_selected(rename=( _name_=parameter col1=estimate )) ;
 by replicate;
 var gamma beta: alpha: lambda:;
run;

data SP_selected;
 length parameter $50.;
 set SP_selected;
  if find(parameter,'alpha','i') or find(parameter,'lambda','i') then do;
   parameter = 'log'||strip(parameter);
   estimate = log(estimate);
  end;
run;

data sim;
 set sim hist(in=b);
 by replicate;
  if b then weight = &a0.;
  else weight = 1;

  if b then study = 1;
  else study = 2;

  length lastobs 3.;
  if last.replicate then lastObs = 1;
  else lastObs = 0;
run;

%mend simStudy;