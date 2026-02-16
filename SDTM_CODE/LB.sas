/*lb*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.lb short varnum; run;
/*SUBJID LBTESTCD LBTEST LBCAT LBORRES VISIT LBORRESU LBDT LBSTRESN */
proc sort data=proj.LB out=proj.LB1; by subjid LBdt; run;
data proj.LB2;
merge proj.LB1(in=a) proj.dm (in=b keep= subjid siteid) proj.rf_days(in=c keep= subjid rfstdt);
by subjid;
if a;
studyid="cps111";
domain="LB";
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
LBTESTCD=strip(LBTESTCD);
LBTEST=strip(LBTEST);
LBVISIT=strip(VISIT);
LBORRES=strip(LBORRES);
LBORRESU=LBORRESU;
LBSTRESN=LBSTRESN;
/*seq*/
retain LBseq;
if first.subjid then LBseq=1;
else LBseq = LBseq+1;
/*date in char format*/
LBDTC=strip(put(LBdt,yymmdd10.));
/*end_day*/
if LBdt ne . and rfstdt ne . then do;
   if LBdt ge RFSTDT then LBDY=(LBdt-RFSTDT)+1;
   else if LBdt lt RFSTDT then LBDY=(LBdt-RFSTDT);
end;
format LBSTRESN best12. ;
run;
proc sort data=proj.LB2; by subjid LBseq; run;

/*baseline flag*/
data proj.LB22;
set proj.LB2;
if LBdt le rfstdt;
run;
proc sort data=proj.LB22; by subjid LBTESTCD descending LBdt; run;

data proj.LB3;
set proj.LB22;
by subjid LBTESTCD descending LBdt;
/*baseline flag*/
if first.LBtestcd then LBBLFL="Y";
run;
proc sort data=proj.LB3; by subjid LBseq; run;
data proj.LB_template;

attrib
    STUDYID   length=$20  label="Study Identifier"
    DOMAIN    length=$2   label="Domain Abbreviation"
    USUBJID   length=$20  label="Unique Subject Identifier"
    SITEID    length=$10  label="Study Site Identifier"
    LBSEQ     length=8   label="Sequence Number"
    LBTESTCD  length=$10   label="Vital Signs Test Short Name"
    LBTEST    length=$40  label="Vital Signs Test Name"
    QSCAT     length=$8   label="Test Category"

    VISIT     length=$40 label="Visit Name"
    LBDTC     length=$20  label="Date/Time of Lab tests" 
    LBDY      length=8    label="Study Day of Lab test"

    LBORRES   length=$40  label="Original Result"
    LBORRESU  length=$20  label="Original Units"
    LBSTRESN  length=8    label="Numeric Result in Standard Units"
    LBBLFL    length=$1   label="Baseline Flag"
;
stop;
run;

data proj.LB4;
if 0 then set proj.LB_template;
merge proj.LB2(in=a) 
      proj.LB3(in=b);
by subjid LBseq;
if a;
keep STUDYID DOMAIN USUBJID SITEID LBSEQ LBTESTCD LBTEST LBCAT LBORRES VISIT 
LBORRESU LBDTC LBSTRESN LBDY LBBLFL
;
run;
proc sort data=proj.LB4 ; by studyid usubjid; run;
