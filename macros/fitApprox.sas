%macro fitApprox(phiValue=0.975);

ods output ParameterEstimates = ParmEst;
proc nlmixed data = sim(rename=(weight=w event=v obsTime=y stratum=s)) MAXFUNC=5000 MAXIT=1000 gconv=0 rest=500;
 by replicate;
  parms  / bydata data=SP_selected;

  ** setup covariates;
  x0 = 1;
  array x[3] x0 x1 x2;

    dimBeta  = 3;
    dimAlpha = 2;

  ** array for parameters;
   array beta[1,3]      beta1 beta2 beta3;

   array logAlpha[1,2]  logAlpha1 logAlpha2;

   array logLambda[1,2] loglambda1 loglambda2;

   study    = 1;
   maxStudy = 1;


   logTheta = z*gamma;
   do p = 1 to dimBeta;
    logTheta = logTheta + x[p]*beta[study,p];
   end;
   theta = exp(logTheta);

   f = w*(  v * ( logTheta + logPDF('weibull',y,exp(logAlpha[study,s]),1/exp(logLambda[study,s])))
            - theta * CDF('weibull',y,exp(logAlpha[study,s]),1/exp(logLambda[study,s]))  );

   ** accounting for initial prior;
   if lastobs then do;

     f = f - 0.5/1e5*gamma**2;

     do k = 1 to maxStudy;
     do j = 1 to dimBeta;
       ** normal prior;
       f = f - 0.5/1e5*beta[k,j]**2;
     end;
     do j = 1 to dimAlpha;
       ** gamma prior + transformation to the log-scale;
       f = f + 0.0001*logAlpha[k,j] - 0.0001*exp(logAlpha[k,j]);
	   f = f + 0.0001*logLambda[k,j] - 0.0001*exp(logLambda[k,j]);
     end;
	 end;

   end; 

   model y ~ general(f);
quit;

data ParmEstGamma;
 set ParmEst end=last;
 where upcase(Parameter) = 'GAMMA';

  retain rejRate 0 nStudy 0;
  

  postProbApprox = 1 - cdf('normal',estimate/StandardError,0,1);

  nStudy  + 1;
  rejRate + (postProbApprox>=&phiValue.);

  if last;
   rejRate = rejRate / nStudy;

   length sp $35.;

   a0 = &a0;
   n  = &n.;
   sp = scan("&sp.",2,'.');
   keep sp n a0 rejRate nStudy;
run;


%mend fitApprox;
