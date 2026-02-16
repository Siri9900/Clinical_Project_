/*EX*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.ex short varnum; run;
/*SUBJID EXKITID EXLOT EXDOSE EXDOSU EXROUTE EXSTDT EXENDT*/
proc sort data=proj.ex out=proj.ex1; by SUBJID exstdt exdose; run;

data proj.ex2;
set proj.ex1;
by subjid exstdt;
studyid="cps111";
domain="EX";
EXTRT=strip(EXKITID);
EXDOSU=strip(EXDOSU);
EXDOSE=EXDOSE;
EXROUTE=strip(EXROUTE);
EXSTDTC=put(EXSTDT, yymmdd10.); 
EXENDTC=put(EXENDT, yymmdd10.); 
/*seq*/
retain exseq;
if first.subjid then exseq=1;
else exseq = exseq+1;
/*days calculation*/
if first.subjid then rfstdt=EXSTDT;
if last.subjid then rfendt=EXENDT;
/*EXSTDY*/
if EXSTDT ne . and rfstdt ne . then do;
  if EXSTDT ge RFSTDT then EXSTDY=(EXSTDT-RFSTDT)+1;
  else if EXSTDT lt RFSTDT then EXSTDY=(EXSTDT-RFSTDT);
end;
/*EXENDY*/
if EXENDT ne . and rfstdt ne . then do;
   if EXENDT ge RFSTDT then EXENDY=(EXENDT-RFSTDT)+1;
   else if EXENDT lt RFSTDT then EXENDY=(EXENDT-RFSTDT);
end;
/*DUR*/
if EXSTDY ne . and EXENDY ne . then EXdur1=(EXENDY-EXSTDY)+1;
else EXdur1= . ;
EXDUR=PUT(EXDUR1, BEST12.);
run;
proc sort data=proj.ex2; by subjid; run;
data proj.ex_template;

attrib
    STUDYID  length=$20  label="Study Identifier"
    DOMAIN   length=$2   label="Domain Abbreviation"
    USUBJID  length=$20  label="Unique Subject Identifier"
    SITEID   length=$10  label="Study Site Identifier"

    EXSEQ    length=8    label="Sequence Number"

    EXTRT    length=$20 label="Name of Treatment"
    EXDOSE   length=8    label="Dose per Administration"
    EXDOSU   length=$20  label="Dose Units"
    EXROUTE  length=$20  label="Route of Administration"

    EXSTDTC  length=$20  label="Start Date/Time of Exposure"
    EXENDTC  length=$20  label="End Date/Time of Exposure"

    EXSTDY   length=8    label="Study Day of Start of Exposure"
    EXENDY   length=8    label="Study Day of End of Exposure"
    EXDUR    length=$12   label="Duration of Exposure"
;
stop;
run;

data proj.ex3;
if 0 then set proj.ex_template;
merge proj.ex2(in=a)  proj.dm(in=b keep=subjid siteid);
by subjid;
if a;
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 

keep STUDYID DOMAIN USUBJID SITEID EXSEQ EXTRT EXDOSE EXDOSU EXROUTE EXSTDTC EXENDTC 
EXSTDY EXENDY EXDUR;

run;
proc sort data=proj.ex3 ; by studyid usubjid; run;
