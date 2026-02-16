/*CM*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data=proj.cm short varnum; run;
/*SUBJID CMTRT CMDOSU CMROUTE CMREAS CMDISCONT CMSEQ CMDOS CMSTDT CMENDT*/
proc sort data=proj.cm; by subjid CMSTDT cmtrt; run;
data proj.cm1;
length  cmstrtpt $20. cmenrtpt $20. cmsttpt $20 cmentpt $20 cmindc $20;
set proj.cm;
by subjid CMSTDT cmtrt;
studyid="cps111";
Domain="CM";
cmindc=CMREAS;
CMTRT=CMTRT;
CMDOSE=CMDOS;
CMDOSU=CMDOSU;
CMROUTE=CMROUTE;
/*seq*/
if first.subjid then cmseq=1;
else cmseq+1;
/*cmtrt dates*/
CMSTDTC=strip(put(CMSTDT, yymmdd10.));
CMENDTC=strip(put(CMENDT, yymmdd10.));
/*reference dates*/
cmsttpt= strip("2018-01-01");
cmentpt= strip("2020-12-28");

if CMSTDTC ne "" then do;
    if CMSTDTC > cmsttpt then CMSTRTPT = 'after';
    else if CMSTDTC < cmsttpt then CMSTRTPT = 'before';
    else CMSTRTPT = 'coincidence';
end;
else CMSTRTPT = 'unknown';
/* For end date time point */
if CMENDTC ne "" then do;
    if CMENDTC gt cmentpt then CMENRTPT = 'after';
    else if CMENDTC lt cmentpt then CMENRTPT = 'before';
    else CMENRTPT = 'coincidence';
end;
else if CMSTDTC ne "" and CMENDTC eq "" then CMENRTPT = 'ongoing';  /* Started but no end date */
else CMENRTPT = 'unknown';  /* Never started */
run;
proc sort data=proj.cm1; by SUBJID; run;

/*days and duration*/
proc sort data=proj.ex out=proj.ex1; by SUBJID exstdt exdose; run;
data proj.rf_days (keep= SUBJID rfstdt rfendt) ;
set proj.ex1 (keep= SUBJID EXDOSE EXSTDT EXENDT);
by SUBJID exstdt exdose; 
if first.subjid then rfstdt= EXSTDT;
if last.subjid then rfendt=EXENDT;
format rfstdt rfendt yymmdd10.;
run;
proc sort data=proj.rf_days; by SUBJID; run;

data proj.cm_template;
attrib
 studyid  length=$20 label="Study Identifier"
 usubjid  length=$20 label="Unique Subject Identifier"
 domain   length=$2  label="Domain Abbreviation"
 siteid   length=$10 label="Study Site Identifier"

 cmseq    length=8   label="Sequence Number"

 cmindc   length=$20 label="Indication"
 cmtrt    length=$20 label="Concomitant Medication"
 cmdose   length=8  label="Dose per Administration"
 cmdosu   length=$20  label="Dose Units"
 cmroute  length=$40  label="Route of Administration"

 cmstdtc  length=$20 label="Start Date/Time of Medication" 
 cmendtc  length=$20 label="End Date/Time of Medication" 

 cmstdy   length=8   label="Study Day of Start of Medication"
 cmendy   length=8   label="Study Day of End of Medication"
 cmdur    length=$8   label="Duration of Medication"

 cmsttpt  length=$20 label="Start Reference Time Point" 
 cmstrtpt length=$20 label="Start Relative Reference Time Point" 
 cmentpt  length=$20 label="End Reference Time Point" 
 cmenrtpt length=$20 label="End Relative to Reference Time Point"
;
stop;
run;
data proj.cm2;
if 0 then set proj.cm_template;
merge proj.cm1(in=a) 
      proj.rf_days(in=b) 
      proj.dm1(in=c keep=subjid siteid);
by SUBJID;
if a;
/*CMSTDY*/
if cmstdt ne . and rfstdt ne . then do;
     if CMSTDT ge rfstdt then CMSTDY=(CMSTDT-rfstdt)+1;
     else if CMSTDT lt rfstdt then CMSTDY=(CMSTDT-rfstdt);
end;
/*CMENDY*/
if cmendt ne . and rfstdt ne . then do;
     if CMENDT ge rfstdt then CMENDY=(CMENDT-rfstdt)+1;
     else if CMENDT lt rfstdt then CMENDY=(CMENDT-rfstdt);
end;
/*DUR*/
if nmiss(CMSTDY, CMENDY)=0 then cmdur1=(CMENDY-CMSTDY)+1;
else cmdur1= . ;
CMDUR=PUT(CMDUR1, BEST12.);
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 

keep STUDYID DOMAIN USUBJID SITEID CMSEQ CMINDC CMTRT CMDOSE CMDOSU CMROUTE 
CMSTDTC CMENDTC CMSTDY CMENDY CMDUR CMSTTPT CMSTRTPT CMENTPT CMENRTPT;
run;
/*Validations*/
/*check existence of day 0*/
/*if cmstdt = rfstdt then put days=cmstdy; */
/*if not missing (cmendt) then do;*/
/*   if cmstdt > cmendt then put issue="enddt is before strtdt"; */
/*end;*/
/*run;*/
proc sort data=proj.cm2 ; by studyid usubjid; run;
