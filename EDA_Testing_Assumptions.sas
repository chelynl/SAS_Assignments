/* Logistic Regression Homework 1: Exploring Data and Testing Assumptions */

* Look at num of levels for each variable (both categorical and continuous) ;
* We can see which variables are binary, ordinal, nominal, continuous, etc. ;
proc freq data=hw.insurance_t nlevels;
	tables _ALL_;
	ods output NLevels = NLevels;
run;
quit;

proc sort data=NLevels;
	by NLevels;
run;

proc print data=NLevels;
run;

/* Define Macro variables */
%let binary = DDA DIRDEP NSF SAV ATM CD IRA LOC ILS MM MTG SDB MOVED INAREA INV CC HMOWN;
%let ordinal = CASHBK MMCRED CCPURC;
%let nominal = RES BRANCH;
%let continuous = ACCTAGE DDABAL DEP DEPAMT CHECKS NSFAMT PHONE TELLER SAVBAL ATMAMT 
					POSAMT CDBAL IRABAL LOCBAL INVBAL ILSBAL MMBAL MTGBAL CCBAL INCOME
					LORES HMVAL AGE CRSCORE;

/* Look at relationship with all predictor variables with target variable INS - by var type*/
* Binary variables by INS and save chisq table as dataset MH_B, relrisk (for odds ratios) table as dataset OR;
proc freq data=hw.insurance_t nlevels;
	tables (&binary)*INS / chisq relrisk;
	ods output ChiSq=MH_B RelativeRisks=OR;
run;
quit;

* Since we're dealing with binary variables, only show Mantel-Haenszel Chi-Square Test results;
data MH_B;
	set MH_B;
	if Statistic ne "Mantel-Haenszel Chi-Square" then delete;
run;

proc sort data=MH_B;
	by Prob; *Prob is variable name for p-value in the table;
run;

proc print data=MH_B;
run;

* Do the same for OR table since all we care about is odds ratios for binary variables;
data OR;
	set OR;
	if Statistic ne "Odds Ratio" then delete;
	if Value < 1 then OR = 1/Value; else OR = Value;
run;

proc sort data=OR;
	by descending OR;
run;

proc print data=OR;
run;

/* Variable relationships with INS - Ordinal */
proc freq data=hw.insurance_t nlevels;
	tables (&ordinal)*INS / chisq measures;
	ods output ChiSq=MH_O Measures=Spearman; *Measures table contains Spearman statistic;
run;
quit;

data MH_O;
	set MH_O;
	if Statistic ne "Mantel-Haenszel Chi-Square" then delete;
run;

proc sort data=MH_O;
	by Prob;
run;

proc print data=MH_O;
run;

/* Variable relationships with INS - Nominal */
proc freq data=hw.insurance_t nlevels;
	tables (&nominal)*INS / chisq;
	ods output ChiSq=ChiSq;
run;
quit;

data ChiSq_Test;
	set ChiSq;
	if Statistic ne "Chi-Square" then delete; *for nominal vars, we're only interested in Pearson Chisq statistic;
run;

proc sort data=ChiSq_Test;
	by Prob;
run;

proc print data=ChiSq_Test;
run;

/* Sample Size requirements for categorical tests (expected count should be above 5) */
/* This is a harder to code but there are some nice SAS tricks to help */
/* PROC FREQ can output many table cell counts across a BY variable */
/* You just need the BY variable to essentially be your variables in different rows. */
/* Time to convert our wide data set to a long one for categorical */
data Insurance_T_Bin_Long_Binary;
	set hw.insurance_t;
	array x [*] &binary; * make array of all binary vars ;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run; * first 17 rows represent the first obs in dataset and so on so forth;

proc sort data= Insurance_T_Bin_Long_Binary;
	by VarName;
run;

proc freq data=Insurance_T_Bin_Long_Binary nlevels;
	by VarName;
	table Value*INS / outexpect expected nopercent nocol norow out=SampleSize;
run;
quit;

*do same thing for ordinal and nominal vars;
data Insurance_T_Bin_long_Ordinal;
	set hw.insurance_t;
	array x [*] &ordinal;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run;

proc sort data=Insurance_T_Bin_long_Ordinal;
	by VarName;
run;

proc freq data=Insurance_T_Bin_long_Ordinal nlevels;
	by VarName;
	table Value*INS / outexpect expected nopercent nocol norow out=SampleSize;
run;
quit;

* Addressing sample size issue with Exact Chisq statement;
proc freq data=hw.insurance_t;
	table (&ordinal)*INS / chisq expected;
	exact chisq; * Do Exact Chisq test that do not have sample size requirements but more computationally intensive;
run;
quit;

data Insurance_T_Bin_Long_Nominal;
	set hw.insurance_t;
	array x [*] &nominal;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run;

proc sort data=Insurance_T_Bin_Long_Nominal;
	by VarName;
run;

proc freq data=Insurance_T_Bin_Long_Nominal nlevels;
	by VarName;
	table Value*INS / outexpect expected nopercent nocol norow out=SampleSize;
run;
quit;

/* Variable relationship with INS - continuous */
* convert wide data set to a long one for continuous vars;
data Insurance_T_Long;
	set hw.insurance_t;
	array x [*] &continuous;
	do varNum = 1 to dim(x);
		VarName = vname(x[varNum]);
		Value = x[varNum];
		output;
	end;
run;

* only works if data is sorted;
proc sort data=Insurance_T_Long;
	by VarName;
run;

* BY statements run much faster with macros;
proc logistic data=Insurance_T_Long;
	by VarName;
	model INS(event='1') = Value;
	ods output ParameterEstimates = Param;
run;
quit;

data Param;
	set Param;
	if Variable ne "Value" then delete;
run;

proc sort data=Param;
	by ProbChiSq;
run;

proc print data=Param;
run;

/* Checking Assumptions for Continuous Variables - Box Tidwell */
data Insurance_T_Long;
	set Insurance_T_Long;
	vlogv = Value*log(Value); * do transformation for every continuous var;
run;
* if there are 0 or negative values, then SAS deletes those observations-- not best approach;

proc logistic data=Insurance_T_Long;
	by VarName;
	model INS(event='1') = Value vlogv;
	ods output ParameterEstimates = Param;
run;
quit;

data Param;
	set Param;
	if Variable ne 'vlogv' then delete;
run;

proc sort data = Param;
	by ProbChiSq;
run;

proc print data = Param;
run;

/* Missing Values Per Variable */
proc format;
	value $missfmt ' '='Missing' other='Not Missing';
	value missfmt .='Missing' other='Not Missing';
run;

proc freq data=hw.insurance_t;
	format _CHAR_ $missfmt.;
	tables _CHAR_ / missing missprint nocum nopercent;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum nopercent;
run;
