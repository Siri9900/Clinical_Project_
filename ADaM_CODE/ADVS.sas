proc copy inlib=psoriasi outlib=proj;
run;
/*BDS: ADVS*/
data proj.advs_template;
attrib
    STUDYID   length=$20  label="Study Identifier"
    DOMAIN    length=$2   label="Domain Abbreviation"
    USUBJID   length=$20  label="Unique Subject Identifier"
    SITEID    length=$10  label="Study Site Identifier"
    VSSEQ     length=8   label="Sequence Number"
    VISIT     length=$40 label="Visit Name"
    VSBLFL    length=$1   label="Baseline Flag"
    PARAM     length=$40 label='TEST NAME DESCRIPTION'
	PARAMCD   length=$10 label='TEST NAME CODE'
	AVAL      length=8 label='NUMERIC STANDARD RESULTS'
    BASE      length=8 label='BASE LINE VALUE'
    CHG       length=8 label='CHANGE FROM BASE LINE'
	PCHG      length=8 label='% CHANGE FROM BASE LINE'
	ALBLFL    length=$1 label='ANALYSIS BASE LINE FLAG'
    AVISIT    length=$20 label='ANALYSIS VISIT'
    AVISITN   length=8 label='ANALYSIS VISIT NUMERIC'
	APHASE    length=$20 label='ANALYSIS PHASE'    
    APHASEN   length=8  label='ANALYSIS PHASE NUMERIC'
    AWLO      length=8  label='ANALYSIS WINDOW LOWER LIMIT'
    AWHI      length=8  label='ANALYSIS WINDOW HIGHER LIMIT'
    AWTARGET  length=8  label='ANALYSIS TARGET'
    AWTDIFF   length=8  label='ANALYSIS WINDOW DIFFERENCE'
    ANL01FL   length=$1  label='ANALYSIS FLAG'
    ADT       format=yymmdd10.    label='Analysis  Date'
    ADY       label='ANALYSIS DAY'
    
    TRTSDT     label='Date of First Exposure to Treatment'
    TRTEDT     label='Date of Last Exposure to Treatment'
    TRTA       label='Actual Treatment'
    TRTAN      label='Actual Treatment (N)'
    SAFFL      label='Safety Population Flag'
	RFICDT     label='ICF DATE'
    RANDDT     label='RANDOMIZATION DATE'

  ; 
stop;
run;

proc sort data=proj.VS4;by studyid usubjid; run;
proc sort data=proj.adsl_f;by studyid usubjid; run;
DATA PROJ.ADVS1; 
length aphase $20 aphasen 8 param $40 paramcd $10 AVAL 8 alblfl $1;
MERGE proj.VS4 (IN=A) proj.adsl_f (IN=B);
BY studyid usubjid; 
if a;
/*ANALYSIS PHASE*/  
IF lowcase(VISIT)= "screening" THEN DO; 
  APHASE="SCREENING"; 
  APHASEN=1;
END;
ELSE IF lowcase(VISIT) IN("trt wk1", "trt wk2", "trt wk3", "trt wk4", "trt wk5", 
"trt wk6", "trt wk7", "trt wk8", "trt wk9", "trt wk10", "trt wk11" ) THEN DO ;
  APHASE="TREATMENT"; APHASEN=2;
END;
ELSE IF lowcase(VISIT)= "follow-up" THEN DO;
  APHASE="FOLLOW-UP"; APHASEN=3;
END;
ELSE DO;
  APHASE=""; APHASEN=.;
END;

/* Convert character dates to numeric for analysis: ANALYSIS DATE, Analysis day*/
  ADY=VSDY;
  if VSDTC ne "" then ADT= input(scan(VSDTC,1,"T"), yymmdd10.);
  format ADT yymmdd10. AVAL 8.2;
/*PARAM PARAMCD*/
  PARAM= VSTEST;
  PARAMCD= VSTESTCD;
  AVAL=VSSTRESN; 
/*ALBLFL*/
  ALBLFL=vsblfl;   
run;
proc sort data=proj.advs1; by studyid usubjid paramcd ADT; run;

data proj.advs2;
length BASE 8 CHG 8 PCHG 8 ;
set proj.advs1;
by studyid usubjid paramcd ADT; 
/*   or   by usubjid paramcd;*/
/*    if ady <= 1 and aval ne . then ablfl = "Y";*/
/* Retain only the last one before dose */
/*    if last.paramcd and ablfl = "Y"; */
/* BASE */
retain base;
if first.paramcd then base = .;
/*   or   by usubjid paramcd;*/
/*    if ady <= 1 and aval ne . then ablfl = "Y";*/
/* Retain only the last one before dose */
/*    if last.paramcd and ablfl = "Y"; */
/* BASE */
  if ALBLFL="Y" then base= aval; 
/*change*/
  if not missing(aval) and not missing(base) then
  CHG= aval-base;
/*percentage change*/
  if not missing(chg) and base ne 0 then PCHG= CHG/base*100;
format base 8.2 chg 8.2 pchg 8.2;
run;

/* create a lookup table based on  SAP */
data proj.visit_ref;
  length AVISIT $20.;
  input AVISIT & $ AVISITN AWLO AWHI AWTARGET;
  datalines;
Screening      0  -10    0    0
trt wk1        1    1    9    7
trt wk2        2   10   16   14
trt wk3        3   17   23   21
trt wk4        4   24   30   28
trt wk5        5   31   37   35
trt wk6        6   38   44   42
trt wk7        7   45   51   49
trt wk8        8   52   58   56
trt wk9        9   59   65   63
trt wk10       10   66   72   70
trt wk11       11   73   85   79
Follow-up      12   86   93   90
;
run;

 

/* Step A: Assign every record to a window based on ADY */
proc sql;
    create table proj.advs_windowed as
    select a.*, b.AVISIT, b.AVISITN, b.AWLO, b.AWHI, b.AWTARGET
    from proj.ADVS2 a
    left join proj.visit_ref b
    on not missing(a.ADY) 
    and a.ADY between b.AWLO and b.AWHI; /* This captures unplanned visits too! */
quit;
/*proc freq data=proj.advs_windowed;*/
/*table usubjid*paramcd*avisit / list missing;*/
/*run;*/


/* Step B: Calculate Distance (AWTDIFF) and Flag the Best Record (ANL01FL) */
data PROJ.advs_flg;
    set PROJ.advs_windowed;
    /* 1. Calculate how far from target */
	if ADY NE . AND AWTARGET NE . then do;
    AWTDIFF = abs(ADY - AWTARGET);
	end;
	else do;AWTDIFF=.;end;
run;

/* 2. Sort by 'Best Match' criteria: Closest to target, then latest day */
proc sort data=PROJ.advs_flg ;by studyid  usubjid PARAMCD AVISITN AWTDIFF descending ADY;run;

/* VSBLFL    
 ALBLFL AVISIT AVISITN AWLO AWHI AWTARGET AWTDIFF ANL01FL*/
data proj.advs_final1;
length ANL01FL $1;
if 0 then set proj.advs_template; 
    set proj.advs_flg;
    by studyid usubjid paramcd AVISITN;
    /* 3. Flag only the first (best) record per visit */
    if first.AVISITN and not missing(AVISITN) then ANL01FL = "Y";
	else ANL01FL="";
keep STUDYID DOMAIN USUBJID SITEID VSSEQ VISIT VSBLFL
TRTSDT TRTEDT TRTA TRTAN SAFFL RFICDT RANDDT APHASE APHASEN ADY ADT AVAL BASE
CHG PCHG PARAM PARAMCD ALBLFL AVISIT AVISITN AWLO AWHI AWTARGET AWTDIFF ANL01FL
;
run;
proc sort data=proj.advs_final1 out=proj.advs_final; by studyid usubjid vsseq;run;
