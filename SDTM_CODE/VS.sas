/*VS*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.VS short varnum; run;
/*SUBJID VSTESTCD VSTEST VSPOS VSORRES VISIT VSORRESU VSDTC VSSTRESN*/
proc sort data=proj.VS out=proj.VS1; by subjid VSdtc; run;
data proj.VS2;
merge proj.VS1(in=a rename= (VSDTC=VSDT)) proj.dm (in=b keep= subjid siteid) proj.rf_days(in=c keep= subjid rfstdt);
by subjid;
if a;
studyid="cps111";
domain="VS";
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
VSTESTCD=strip(VSTESTCD);
VSTEST=strip(VSTEST);
VSPOS=strip(VSPOS);
VSVISIT=strip(VISIT);
VSORRES=strip(VSORRES);
VSORRESU=VSORRESU;
VSSTRESN=VSSTRESN;
/*seq*/
retain vsseq;
if first.subjid then vsseq=1;
else vsseq = vsseq+1;
/*date in char format*/
VSDTC=strip(put(VSdt,yymmdd10.));
/*end_day*/
if VSdt ne . and rfstdt ne . then do;
   if VSdt ge RFSTDT then VSDY=(VSdt-RFSTDT)+1;
   else if VSdt lt RFSTDT then VSDY=(VSdt-RFSTDT);
end;
run;
proc sort data=proj.VS2; by subjid vsseq; run;

/*baseline flag*/
data proj.VS22;
set proj.VS2;
if VSdt le rfstdt;
run;
proc sort data=proj.VS22; by subjid VSTESTCD descending VSdt; run;

data proj.VS3;
set proj.VS22;
by subjid VSTESTCD descending VSdt;
/*baseline flag*/
if first.VStestcd then VSBLFL="Y";
run;
proc sort data=proj.vs3 nodupkey dupout=dup;by subjid vsseq;run;
data proj.vs_template;

attrib
    STUDYID   length=$20  label="Study Identifier"
    DOMAIN    length=$2   label="Domain Abbreviation"
    USUBJID   length=$20  label="Unique Subject Identifier"
    SITEID    length=$10  label="Study Site Identifier"
    VSSEQ     length=8   label="Sequence Number"
    VSTESTCD  length=$10   label="Vital Signs Test Short Name"
    VSTEST    length=$40  label="Vital Signs Test Name"

    VISIT     length=$40 label="Visit Name"

    VSDTC     length=$20  label="Date/Time of Vital Signs" 
    VSDY      length=8    label="Study Day of Vital Signs"

    VSPOS     length=$20  label="Position of Subject During Measurement"

    VSORRES   length=$40  label="Original Result"
    VSORRESU  length=$20  label="Original Units"

    VSSTRESN    label="Numeric Result in Standard Units" length=8

    VSBLFL    length=$1   label="Baseline Flag"
;
stop;
run;
/*final vs*/
data proj.VS4;
if 0 then set proj.vs_template;
merge proj.VS2(in=a) 
      proj.VS3(in=b);
by subjid vsseq;
if a;
keep STUDYID DOMAIN USUBJID SITEID VSSEQ VSTESTCD VSTEST VSPOS VSORRES VISIT 
VSORRESU VSDTC VSSTRESN VSDY VSBLFL
;
run;
/*validation*/
proc sql;    /*count before/ after merge*/
select count(*) from proj.vs2;
select count(*) from proj.vs3;
quit;
proc sql;
select count(*) from proj.vs4;
quit;

/*validate one base-line flag per test per subject*/
proc freq data=proj.vs4;
where usubjid="cps111-P001-S01";
tables usubjid*VSTESTCD*VSBLFL;
run;
/*required variables should not miss: Missing Value Checks*/
data proj.vs_val;
set proj.vs4;
where vstestcd="" or vstest=""; 
run;
proc means data=proj.vs4 n nmiss;
var vsseq;
run;
proc contents data=proj.vs4;   /*check the datatypes: char/ numeric*/
run;
proc means data=proj.vs4 n min max;
class VSTESTCD;                      /*check the range checks: if sysbp > 5000*/
var VSSTRESN;
run;
