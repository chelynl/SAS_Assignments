/* Logistic Regression Homework 2: Variable Selection and Model Building */

/* Homework 1 uncovered significant and potentially helpful variables. Bank has now strategically
binned ALL variables so all variables now can be treated as categorical variables. Imputation is much 
easier now since we can create a "missing" level for each variable. This also takes care of the assumptions
since they only apply to continuous variables, which we no longer have. */

/* See which variables have missing values */
proc format;
	value $missfmt ' '='Missing' other='Not Missing';
	value missfmt .='Missing' other='Not Missing';
run;

proc freq data=hw2.insurance_t_bin;
	format _CHAR_ $missfmt.;
	tables _CHAR_ / missing missprint nocum nopercent;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum nopercent;
run;

/* Variables with missing values: HMOWN, CCPURC, CC, INV */
/* Impute missing values with "MISS" */
data insurance_t_bin;
	set hw2.insurance_t_bin;

	HMOWN_BIN = put(HMOWN, 4.);
	if HMOWN_BIN = . then HMOWN_BIN = 'MISS';

	CC_BIN = put(CC, 4.);
	if CC_BIN = . then CC_BIN = 'MISS';
	
	CCPURC_BIN = put(CCPURC, 4.);
	if CCPURC_BIN = . then CCPURC_BIN = 'MISS';

	INV_BIN = put(INV, 4.);
	if INV_BIN = . then INV_BIN = 'MISS';

run;

* Verify changes with proc freq;
proc freq data = insurance_t_bin;
	table HMOWN_BIN CC_BIN CCPURC_BIN INV_BIN;
run;
quit;

/* Now we can move on to the modeling phase -- Define macro variables by variable type */
%let binary = DDA DIRDEP NSF SAV ATM CD IRA LOC ILS MM MTG SDB MOVED INAREA;
%let ordinal = CASHBK MMCRED;
%let nominal = RES BRANCH;
%let binned = ACCTAGE_BIN DDABAL_BIN DEPAMT_BIN CHECKS_BIN NSFAMT_BIN PHONE_BIN TELLER_BIN 
					SAVBAL_BIN ATMAMT_BIN POSAMT_BIN CDBAL_BIN IRABAL_BIN LOCBAL_BIN INVBAL_BIN 
					ILSBAL_BIN MMBAL_BIN MTGBAL_BIN CCBAL_BIN INCOME_BIN LORES_BIN HMVAL_BIN AGE_BIN
					CRSCORE_BIN INV_BIN CC_BIN HMOWN_BIN CCPURC_BIN LORES_BIN HMVAL_BIN AGE_BIN CRSCORE_BIN;

/* Create a binned dataset with no more continuous variables */
data insurance_t_bin;
	set insurance_t_bin;
	keep INS &binary &ordinal &nominal &binned;
run;

/* Look for Linear Separation Concerns: Quasi- or Complete- Linear Separation */
/* Address linear separation concerns for numeric variables */

* Go through the frequency table and look at relationships between all potential predictors and target variable;
* Make a long dataset that lists variable name along with value (per obs) as new columns;
data insurance_t_bin_long_numeric;
	set insurance_t_bin;
	array x [*] _NUMERIC_;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run;
* Sort table by variable name;
proc sort data=insurance_t_bin_long_numeric;
	by VarName;
run;
* Get frequency count for each variable (however missing values will not be shown in report);
proc freq data=insurance_t_bin_long_numeric nlevels;
	by VarName;
	table Value*INS / list missing out=SepEval;
run;
quit;
* Create a variable called one that takes value of 1 for every obs in dataset;
data insurance_t_bin_long_numeric;
	set insurance_t_bin_long_numeric;
	one = 1;
run;
* Do proc means by VarName and see how many obs are in Value and INS for variable 'one';
* Shows number of obs in every level per variable regardless if it exists or not;
ods output summary = SepEval;
proc means data = insurance_t_bin_long_numeric n completetypes;
	by VarName;
	class Value INS;
	var one;
run;

* Create dataset with summary results from proc means and filter to only show variables with separation issues;
data SepEval;
	set SepEval;
	if NObs ~= 0 then delete;
run;

proc print data=SepEval;
run;

/* CASHBK, MMCRED have separation issues - fix by collapsing levels */
data insurance_t_bin;
	set insurance_t_bin;

	CASHBK_BIN = put(CASHBK, 4.);
	if CASHBK_BIN = 2 then CASHBK_BIN = 1;
	if CASHBK_BIN = 1 then CASHBK_BIN = '1+'; *create new bin 1+ that contains 1 or 2;

	MMCRED_BIN = put(MMCRED, 4.);
	if MMCRED_BIN = 5 then MMCRED_BIN = 3;
	if MMCRED_BIN = 3 then MMCRED_BIN = '3+'; *create new bin 3+ that contains 3, 4, or 5;

run;

* Verify changes with proc freq;
proc freq data=insurance_t_bin;
	table CASHBK_BIN MMCRED_BIN;
run;
quit;

/* Address linear separation concerns for character variables */
data insurance_t_bin_long_char;
	set insurance_t_bin;
	array x [*] _CHARACTER_;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run;

proc sort data=insurance_t_bin_long_char;
	by VarName;
run;

data insurance_t_bin_long_char;
	set insurance_t_bin_long_char;
	one = 1;
run;

ods output summary = SepEval;
proc means data=insurance_t_bin_long_char n completetypes;
	by VarName;
	class Value INS;
	var one;
run;

data SepEval;
	set SepEval;
	if NObs ~= 0 then delete;
run;

proc print data=SepEval;
run;

/* There are no Quasi-Complete separation concerns for character variables */

/* Do Backwards selection to determine main effects */
* Go through first model and find important main effects variables and then build up interactions;
* Don't want to do backwards selection on all interactions bc interactions cause linear separation issues;
%let binary = DDA DIRDEP NSF SAV ATM CD IRA LOC ILS MM MTG SDB MOVED INAREA;
%let nominal = RES BRANCH;
%let binned = ACCTAGE_BIN DDABAL_BIN DEPAMT_BIN CHECKS_BIN NSFAMT_BIN PHONE_BIN TELLER_BIN SAVBAL_BIN
 				ATMAMT_BIN POSAMT_BIN CDBAL_BIN IRABAL_BIN LOCBAL_BIN INVBAL_BIN ILSBAL_BIN MMBAL_BIN 
				MTGBAL_BIN CCBAL_BIN INCOME_BIN LORES_BIN HMVAL_BIN AGE_BIN CRSCORE_BIN INV_BIN CC_BIN 
				HMOWN_BIN CCPURC_BIN LORES_BIN HMVAL_BIN AGE_BIN CRSCORE_BIN CASHBK_BIN MMCRED_BIN;

proc logistic data=insurance_t_bin plots(only)=(oddsratio);
	class &binary &nominal &binned / param=ref;
	model INS(event='1') = &binary &nominal &binned / selection=backward slstay=0.002 clodds=pl clparm=pl;
	title "Main Effects Model of Insurance Data";
run;
quit;

/* 14 main effects variables were detected and we see that credit card (CC) and investment account (INV) 
are a linear combination of each other (perfect multicollinearity). This tells us that certain people of
certain branches have not been offered all the products. Thus, when I predict individuals for those branches,
I don't need all pieces of information bc they don't have it. */

/* Main Effects model */
proc logistic data=insurance_t_bin plots(only)=(oddsratio);
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN
							ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN / clodds=pl clparm=pl;
	title "Main Effects Model of Insurance Data";
run;
quit;

/* Forward selection to check for significant 2-way interactions and include 14 main effects variables*/
proc logistic data=insurance_t_bin plots(only)=(oddsratio);
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN 
							DDA|NSF|IRA|ILS|MM|BRANCH|DDABAL_BIN|CHECKS_BIN|TELLER_BIN|SAVBAL_BIN|ATMAMT_BIN|CDBAL_BIN|INV_BIN|CC_BIN @2  
							/ include=14 slentry=0.002 selection=forward clodds=pl clparm=pl;
	title "Modeling Interactions in Insurance Data";
run;
quit;

/* Significant interactions: DDA*IRA, MM*DDABAL_BIN, DDABAL_BIN*SAVBAL_BIN */

/* Final Model with interactions */
proc logistic data=insurance_t_bin plots(only)=(oddsratio);
	class DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN
			CDBAL_BIN INV_BIN CC_BIN / param=ref;
	model INS(event='1') = DDA NSF IRA ILS MM BRANCH DDABAL_BIN CHECKS_BIN TELLER_BIN SAVBAL_BIN ATMAMT_BIN CDBAL_BIN INV_BIN CC_BIN
							DDA*IRA MM*DDABAL_BIN DDABAL_BIN*SAVBAL_BIN / clodds=pl clparm=pl;
	title "Final Model for Insurance Data";
run;
quit;

/* Save final model as own dataset to use later */
data hw2.insurance_t_bin_FINALMODEL;
	set insurance_t_bin;
run;
