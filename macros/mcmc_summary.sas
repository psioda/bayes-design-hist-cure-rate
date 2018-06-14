%macro mcmc_summary(ds=,varList=);
data __temp__;
 set &ds.(keep=&varList.) end=last;



 array x[*] &varList.;
 call symput('p',strip(put(dim(x),best.)));
 call symput('nSamp',strip(put(_n_+2,best.)));
 order = 1;
 output;
 if last;
  do j = 1 to dim(x);
   x[j] = .;
  end;
  order = 0;
  output;
  output;
run; 


proc sort data = __temp__ out = __temp__(drop=order j);
   by order;
run;

data y; run;

ods select none;
ods output PostSumInt = PSI;
proc mcmc data = y monitor=(&varList.) nmc=&nSamp. nthin=1 nbi=0 postout=post plots=(none) ntu=0;
 
parm u ;
prior u ~ uniform(0,1);

array y[1] / nosymbols;
array z[&p.] &varList.;

begincnst;
  n  = 0;
  rc = read_array("__temp__", y);
endcnst;

beginnodata;
  n=n+1;
  do p = 1 to &p.;
    z[p]=y[n,p];
  end;
endnodata;

  model general(0);
run; 
ods select all;


option ls = 150;
data psi;
 set psi;

  c1 = tranwrd(put(mean,5.2)||' ('||put(stdDev,5.2)||')',' ','~');
  c2 = tranwrd('('||put(HPDLower,5.2)||','||put(HPDUpper,5.2)||')',' ','~');

  put c1 " & " c2 ;
run;

%mend mcmc_summary;
