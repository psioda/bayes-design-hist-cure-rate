 require(Rcpp);
 require(RcppArmadillo);
 
 
 sourceCpp(code='
 
   // [[Rcpp::depends(RcppArmadillo)]]
   #include <RcppArmadillo.h>
 
   using namespace Rcpp;
   
   class datObj {
   
    public:
   
      int S,N,Preg;
	
      arma::vec y;
 	  arma::vec v; 
	  arma::vec s; 
	  arma::vec z; 
	  arma::mat x;
   	  arma::vec w; 
   };
   
   class parmObj {
   
    public:
	
      int P;
      arma::vec parm;
	  
	  datObj d;
	
	  void slice(int);
	  
	private: 
	
	  double logPost(arma::vec parm0);
   
   };
   

   // [[Rcpp::export]]
   NumericMatrix cureRateFit (NumericVector y, NumericVector v, NumericVector s, NumericVector z, NumericMatrix x, NumericVector w, double fixGamma, int numMCMC, int numThin, int numBurn, int debug)
   {
 
    // initialize random number generator;
    RNGScope scope; 

	// declare data/parameter objects and load;
	datObj d;
    parmObj pm;	
	
	d.S    = (int) max(s);
	d.N    = y.size();
	d.Preg = x.cols() + 1;
	
	d.y.resize(d.N); 		d.y = as<arma::vec>(y);
	d.v.resize(d.N); 		d.v = as<arma::vec>(v);
	d.s.resize(d.N); 		d.s = as<arma::vec>(s);	
	d.z.resize(d.N); 		d.z = as<arma::vec>(z);
	d.x.resize(d.N,d.Preg); d.x = as<arma::mat>(x);
	d.w.resize(d.N); 		d.w = as<arma::vec>(w);

	
	pm.P   = 2*d.S + d.Preg + 1;
	pm.parm.resize(pm.P);
	pm.parm.zeros();
	pm.d = d;
	
	
	
	pm.parm(0) = -0.254110918;
	
	pm.parm(1) = -0.114936327;
	pm.parm(2) =  0.2473767869;
	pm.parm(3) =  0.7867003645;	
	
	pm.parm(4) =  0.2179570381;
	pm.parm(5) =  0.073752143;	

	pm.parm(6) = -0.670010785;
	pm.parm(7) = -0.380979177;	

	int parmSkip = 1 - R_IsNA(fixGamma);
	
    if (parmSkip==1)    { pm.parm(0) = fixGamma; } //Rcpp::Rcout << "Gamma is fixed in this analysis! " << parmSkip << std::endl; }
    else                {                        } //Rcpp::Rcout << "Gamma Treated as a random variable! " << parmSkip << std::endl; }	
	

	int numTotalSamp = numMCMC*numThin + numBurn;
	NumericMatrix mcmcSamples(numMCMC,pm.P);
	
	int cnt = 0;
	int row = 0;
	for (int i=0;i<numTotalSamp;i++)
	{
		// update parameter vector;
		pm.slice(parmSkip);
		
		// store parameter vector;
		if (i >=numBurn) { cnt++; }
		
		if (cnt==numThin) {
		
		  for(int p=0;p<pm.P;p++)
		  {
			mcmcSamples(row,p) = pm.parm(p);
		  }
		  row++;
		  cnt=0;	
		}
	}
	 
	//Rcpp::Rcout << "S=" << d.S << " N=" << d.N << " Preg=" << d.Preg << std::endl;
	//Rcpp::Rcout << "parm=" << pm.parm.t() << std::endl; 
	 
    return mcmcSamples;

   }
 
   double logPDF(double y, double logAlpha, double alpha, double logLambda, double lambda)
   {
        return logAlpha + logLambda + (alpha-1)*log(y) + (alpha-1)*logLambda - pow(y*lambda,alpha);
   }
 
   double CDF(double y, double logAlpha, double alpha, double logLambda, double lambda)
   {
        return 1-exp(-pow(y*lambda,alpha));
   } 
 
   double parmObj::logPost(arma::vec parm0)
   {
		int spot       = 0;
		
		// treatment effect;
		double gamma   = parm0(spot); spot++;
		
		// regression parameters;
		arma::vec beta(d.Preg);
		for (int p=0;p<d.Preg;p++)
		{
			beta(p) = parm0(spot); 
			spot++;
		}
		
		// shape paramters;
		arma::vec logAlpha(2);
		arma::vec alpha(2);
		for (int s=0;s<d.S;s++)
		{
			logAlpha(s) = parm0(spot); 
			alpha(s)    = exp(logAlpha(s));
			spot++;
		}		

		// rate paramters;
		arma::vec logLambda(2);
		arma::vec lambda(2);
		for (int s=0;s<d.S;s++)
		{
			logLambda(s) = parm0(spot); 
			lambda(s)    = exp(logLambda(s));
			spot++;
		}	
		
		double logPost = 0;
		for (int n=0;n<d.N;n++)
		{
		   int si = (int) d.s(n)-1;
		   
           double logTheta = d.z(n)*gamma + beta(0);
		   for(int p=1;p<d.Preg;p++)
		   {
		       logTheta += d.x(n,p-1)*beta(p);
		   }
		   double theta = exp(logTheta);
		   
		   double p1 = logPDF(d.y(n),logAlpha(si),alpha(si),logLambda(si),lambda(si));
		   double c1 = CDF(d.y(n),logAlpha(si),alpha(si),logLambda(si),lambda(si));
		   
		   double logPostComp = d.w(n)*(  d.v(n)*( logTheta + p1 ) - theta * c1	);
						
           logPost += logPostComp;
		}				 
	
		
		
		// account for prior;
		logPost -= 0.5/1e4*pow(gamma,2);
		
		for(int p=0;p<d.Preg;p++)
		{
		    logPost -= 0.5/1e4*pow(beta(p),2);
		}
		for(int s=0;s<d.S;s++)
		{
		    logPost += 0.01*logAlpha(s)  - 0.02*alpha(s);
			logPost += 0.01*logLambda(s) - 0.02*lambda(s);
		}		
		
		
		return logPost;
   
   } 
 

   void parmObj::slice(int parmSkip)
   {
        double w = 0.20;
		int    m = 50;
		
		// loop over parameters to update;
		for(int p=parmSkip;p<P;p++)
		{
		    // create vector of parameters to modify for slice sampling;
		    arma::vec parm0 = parm;
		
			// current value of the parameter in question;
			double curParm = parm0(p);
			
		    // calculate current full conditional value;
            double f0 = logPost(parm0);
		
            // calculate height of the horizontal slice;
            double h0 = f0 - ::Rf_rexp(1.0);		

            // Calculate initial horizontal interval;
            double L = parm0(p) - ::Rf_runif(0.0,1.0)*w,
	               R = L+w;

     	    // Step out;
	        double V = ::Rf_runif(0.0,1.0),
	               J = floor(m*V),
	               K = (m-1)-J;	

			parm0(p) = L; double f0_L = logPost(parm0);
			parm0(p) = R; double f0_R = logPost(parm0);	   

			while(J>0 and h0<f0_L and L>-6)
			{
				L        = L-w; if (L<=-6) {L=-6;}
				J        = J-1;
				parm0(p) = L; 
				f0_L     = logPost(parm0);
			}
			while(K>0 and h0<f0_R and R<6)
			{
				R        = R+w; if (R>=6) {R=6;}
				K        = K-1;
				parm0(p) = R; 
				f0_R     = logPost(parm0);
			}			

		    // perform rejection sampling;
		    int stop  = 0;
		    while(stop == 0)
		    {
				
				parm0(p)     = L + ::Rf_runif(0.0,1.0)*(R-L);
				double f0_x1 = logPost(parm0);

				if      ( h0 <  f0_x1           ) { parm(p) = parm0(p); stop = 1;     }
				else if ( parm0(p) <  curParm   ) { L = parm0(p);                     }
				else if ( parm0(p) >= curParm   ) { R = parm0(p);                     }
				
				if (-0.0000000001 <= L-R and L-R <= 0.0000000001)
				{
					parm(p)= 0.5*(L+R);
					stop      = 1;
				}
			}		
		}

   }   
   
   
    '
)
