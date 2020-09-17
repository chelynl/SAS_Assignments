/* After obtaining final models of only the main effects and main effects with interactions,
we are now going to compare the ROC curves for both models to see which is better. */

/* Comparing ROC Curves for Interaction and Main Effect Models */
proc logistic data=hw2.insurance_t_bin_FINALMODEL plots(only)=ROC;
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN
							DDA*IRA MM*DDABAL_BIN DDABAL_BIN*SAVBAL_BIN / clodds=pl clparm=pl;
	ROC 'Omit Interactions' DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN;
	ROCCONTRAST / estimate = allpairs;
	title 'Comparing ROC Curves';
run;
quit;

/* The model with interactions has a statistically better AUC value.  */

/* Calculate Discrimination Slope for the models and plot it using proc ttest */
proc logistic data=hw2.insurance_t_bin_FINALMODEL plots(only)=ROC;
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN
							DDA*IRA MM*DDABAL_BIN DDABAL_BIN*SAVBAL_BIN / clodds=pl clparm=pl;
	title 'Interaction Model for Insurance Product';
	output out=predprobs p=phat;
run;
quit;

proc sort data=predprobs;
	by descending INS;
run;

proc ttest data=predprobs order=data;
	ods select statistics summarypanel;
	class INS;
	var phat;
	title 'Coefficient of Discrimination and Plots';
run;

/* From the plots, we see that the 0s lean heavily towards the left-side making it distinguishable.
However, the 1s are distributed pretty even. */

/* Calculate the K-S Statistic: looks at cumulative distributions of 1s and 0s and determine
what the maximum distance is between these 2 cumulative distributions */
proc logistic data=hw2.insurance_t_bin_FINALMODEL plots(only)=ROC;
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN
							DDA*IRA MM*DDABAL_BIN DDABAL_BIN*SAVBAL_BIN / clodds=pl clparm=pl;
	title 'Interaction Model for Insurance Product';
	output out=predprobs p=phat;
run;
quit;

proc npar1way data=predprobs d plot=edfplot;
	class INS;
	var phat;
run;
* K-S statistic = 0.4822;
* Value of phat at Maximum = 0.299877 (threshold);

/* Validation Data Cleaning to Match Training Data */
data insurance_v_bin;
	set hw2.insurance_v_bin;

	HMOWN_BIN = put(HMOWN, 4.);
	if HMOWN_BIN = . then HMOWN_BIN = 'MISS';

	CC_BIN = put(CC, 4.);
	if CC_BIN = . then CC_BIN = 'MISS';
	
	CCPURC_BIN = put(CCPURC, 4.);
	if CCPURC_BIN = . then CCPURC_BIN = 'MISS';

	INV_BIN = put(INV, 4.);
	if INV_BIN = . then INV_BIN = 'MISS';

run;

/* Validation Data Results - build model with training data and score on validation data */
proc logistic data=hw2.insurance_t_bin_FINALMODEL plots(only)=ROC;
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN
							DDA*IRA MM*DDABAL_BIN DDABAL_BIN*SAVBAL_BIN / clodds=pl clparm=pl;
	score data = insurance_v_bin fitstat out=scored outroc=roc;
	title 'Interaction Model for Insurance Product';
run;
quit;

/* Using the scored data, assign anything predicted above the threshold ~0.3 as a 1 and 
anything below the threshold as a 0 */
data scored;
	set scored;
	if P_1 >= 0.3 then Pred_class = 1;
	else Pred_class = 0;
run;

/* See frequency count */
proc freq data=scored;
	table INS*Pred_class;
run;
quit;

/* Make Lift Chart on Validation Data */
data work.roc;
	set work.roc;
	cutoff = _PROB_;
	specif = 1 - _1MSPEC_;
	depth = (_POS_ + _FALPOS_)/2124*100;
	precision = _POS_ / (_POS_ + _FALPOS_);
	acc = _POS_ + _NEG_;
	lift = precision/0.3435;
run;

proc sgplot data=work.roc;
	*where 0.005 <= depth <= 0.50;
	series y = lift x = depth;
	refline 1.0 / axis = y;
	title1 "Lift Chart for Validation Data";
	xaxis label = "Depth (%)";
	yaxis label="Lift";
run;
quit;

/* If you look at the top 20% of predicted customers who would buy the product, the model gets
twice as much response in buying the product. Another way to interpret is: in the top 20% of my
predicted observations, I'm having around 67% of people actually buying the product. I know that 
33% of people overall buy the product and if my model is twice as good, then I'm roughly 67%. */