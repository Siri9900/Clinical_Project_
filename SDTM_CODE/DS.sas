/*DS*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.ds short varnum; run;
/*SUBJID DS_EVENT DS_CAT DSSTDT DS_REASON*/
proc sort data=proj.ds; by SUBJID DSSTDT; run;
data proj.ds1;
set proj.ds;
by subjid DSSTDT;
studyid="cps111";
domain="DS";
DSTERM=strip(DS_EVENT);
DSCAT= strip(DS_CAT);
/*seq*/
retain dsseq;
if first.subjid then dsseq=1;
else dsseq = dsseq+1;
/*DSSTDTC*/
DSSTDTC=put(DSSTDT, yymmdd10.);
/*decode*/
if DSCAT= upcase("Protocol Milestone")  then DSDECODE= "PROTMLST";
else if  DSCAT=upcase('Disposition event') then DSDECODE= "NCOMPLT";
else DSDECODE= "OTHEVENT";
run;
proc sort data=proj.ds1; by SUBJID ; run;
/*DS TEMPLATE*/
data proj.ds_template;

attrib
    STUDYID  length=$20  label="Study Identifier"
    DOMAIN   length=$2   label="Domain Abbreviation"
    USUBJID  length=$20  label="Unique Subject Identifier"
    SITEID   length=$10  label="Study Site Identifier"

    DSSEQ    length=8    label="Sequence Number"
    DSTERM   length=$40 label="Reported Term for the Disposition Event"
    DSDECOD  length=$20 label="Standardized Disposition Term"
    DSCAT    length=$40  label="Disposition Category"

    DSSTDTC  length=$20  label="Start Date/Time of Disposition Event" 
    DSSTDY   length=8    label="Study Day of Disposition Event";
stop;
run;

data proj.ds2;
if 0 then set proj.ds_template;
merge proj.ds1(in=a) 
      proj.rf_days(in=b) 
      proj.dm(in=c keep=subjid siteid);
by subjid;
if a;
/*DSSTDY*/
if DSSTDT ne . and rfstdt ne . then do;
     if DSSTDT ge RFSTDT then DSSTDY=(DSSTDT-RFSTDT)+1;
     else if DSSTDT lt RFSTDT then DSSTDY=(DSSTDT-RFSTDT);
end;
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
keep STUDYID DOMAIN USUBJID SITEID DSSEQ DSTERM DSDECODE DSCAT DSSTDTC DSSTDY;
run;
proc sort data=proj.ds2 ; by studyid usubjid; run;

