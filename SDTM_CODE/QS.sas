/*qs*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.qs short varnum; run;
/*SUBJID QSTESTCD QSTEST QSCAT QSORRES VISIT QSDT QSSTRESN */
proc sort data=proj.QS out=proj.QS1; by subjid QSdt; run;
data proj.QS2;
merge proj.QS1(in=a) proj.dm (in=b keep= subjid siteid) proj.rf_days(in=c keep= subjid rfstdt);
by subjid;
if a;
studyid="cps111";
domain="QS";
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
QSTESTCD=strip(QSTESTCD);
QSTEST=strip(QSTEST);
QSVISIT=strip(VISIT);
QSORRES=strip(QSORRES);
QSSTRESN=QSSTRESN;
/*seq*/
retain QSseq;
if first.subjid then QSseq=1;
else QSseq = QSseq+1;
/*date in char format*/
QSDTC=strip(put(QSdt,yymmdd10.));
/*end_day*/
if QSdt ne . and rfstdt ne . then do;
   if QSdt ge RFSTDT then QSDY=(QSdt-RFSTDT)+1;
   else if QSdt lt RFSTDT then QSDY=(QSdt-RFSTDT);
end;
format QSSTRESN best12. ;
run;
proc sort data=proj.QS2; by subjid QSseq; run;

/*baseline flag*/
data proj.QS22;
set proj.QS2;
if QSdt le rfstdt;
run;
proc sort data=proj.QS22; by subjid QSTESTCD descending QSdt; run;

data proj.QS3;
set proj.QS22;
by subjid QSTESTCD descending QSdt;
/*baseline flag*/
if first.QStestcd then QSBLFL="Y";
run;
proc sort data=proj.QS3; by subjid QSseq; run;
data proj.QS_template;

attrib
    STUDYID   length=$20  label="Study Identifier"
    DOMAIN    length=$2   label="Domain Abbreviation"
    USUBJID   length=$20  label="Unique Subject Identifier"
    SITEID    length=$10  label="Study Site Identifier"
    QSSEQ     length=8   label="Sequence Number"
	QSCAT     length=$10   label="Test Category"
    QSTESTCD  length=$10   label="Vital Signs Test Short Name"
    QSTEST    length=$40  label="Vital Signs Test Name"

    VISIT     length=$40 label="Visit Name"

    QSDTC     length=$20  label="Date/Time of test collected" 
    QSDY      length=8    label="Study Day of test collected"

    QSORRES   length=$40  label="Original Result"

    QSSTRESN  length=8    label="Numeric Result in Standard Units"

    QSBLFL    length=$1   label="Baseline Flag"
;
stop;
run;

data proj.QS4;
if 0 then set proj.QS_template;
merge proj.QS2(in=a) 
      proj.QS3(in=b);
by subjid QSseq;
if a;
keep STUDYID DOMAIN USUBJID SITEID QSSEQ QSTESTCD QSTEST QSCAT QSORRES VISIT 
QSDTC QSSTRESN QSDY QSBLFL
;
run;
proc sort data=proj.QS4 ; by studyid usubjid; run;
