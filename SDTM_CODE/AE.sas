/*AE*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.ae short varnum; run;
/*SUBJID AETERM AESEV AEREL AEACN CMTRT_LINKED AESEQ AESTDT AEENDT SERIOUS LLT LLT_CODE PT */
/*PT_CODE HLT HLT_CODE HLGT HLGT_CODE SOC SOC_CODE BODYSYS BODYSYS_CODE MODIFIED_TERM AEOUT*/
proc sort data=proj.ae; by SUBJID AESTDT AETERM; run;
data proj.ae1;
set proj.ae;
by subjid;
studyid="cps111";
domain="AE";
AETERM=strip(AETERM);
AESEV=strip(AESEV);
AESTDTC=put(AESTDT, yymmdd10.); 
AEENDTC=put(AEENDT, yymmdd10.); 
/*seq*/
retain aeseq;
if first.subjid then aeseq=1;
else aeseq = aeseq+1;
/*relation*/
if aerel= "cm-Related" then aerel="Possibly related";
else if aerel="study-Related" then aerel="Probably related";
else if aerel="LRelated" then aerel="Likely related";
else aerel="Not related";
AEACN=strip(AEACN);
AELLT=strip(LLT);
AELLTCD= LLT_CODE;
AEPTCD =PT_CODE;
AEDECODE=strip(PT); 
AEHLT=strip(HLT); 
AEHLTCD= HLT_CODE;
AEHLGT= strip(HLGT);
AEHLGTCD=HLGT_CODE; 
AESOC= strip(SOC);
AESOCCD= SOC_CODE;
AEBODSYS= strip(BODYSYS);
AEBDSYCD= BODYSYS_CODE;
AEMODIFY= strip(MODIFIED_TERM);
AEOUT= strip(AEOUT);
/* Seriousness flag */
  if upcase(SERIOUS) = "YES" then AESER = "Y";
  else AESER = "N";
run;
proc sort data=proj.ae1; by SUBJID; run;

/*PROC CONTENTS DATA= PROJ.AE1 SHORT VARNUM; RUN;*/
/*AE_METADATA_TEMPLATE*/
data proj.ae_template;

attrib
    STUDYID    length=$20  label="Study Identifier"
    DOMAIN     length=$2   label="Domain Abbreviation"
    USUBJID    length=$20  label="Unique Subject Identifier"
    SITEID     length=$10  label="Study Site Identifier"
    AESEQ      length=8    label="Sequence Number"

    AETERM     length=$30 label="Reported Term for the Adverse Event"
    AEMODIFY   length=$30 label="Modified Reported Term"

    AESEV      length=$10   label="Severity/Intensity"
    AESER      length=$1   label="Serious Event"
    AEREL      length=$30  label="Causality"
    AEACN      length=$30  label="Action Taken with Study Treatment"

    AELLT      length=$20  label="Lowest Level Term"
    AELLTCD    length=8    label="Lowest Level Term Code"
    AEPTCD     length=8    label="Preferred Term Code"
    AEDECODE   length=$60  label="Dictionary-Derived Term"
    AEHLT      length=$60  label="High Level Term"
    AEHLTCD    length=8    label="High Level Term Code"
    AEHLGT     length=$60  label="High Level Group Term"
    AEHLGTCD   length=8    label="High Level Group Term Code"
    AESOC      length=$60  label="System Organ Class"
    AESOCCD    length=8    label="System Organ Class Code"
    AEBODSYS   length=$60  label="Body System or Organ Class"
    AEBDSYCD   length=8    label="Body System Code"

    AESTDTC    length=$20  label="Start Date/Time of Adverse Event" 
    AEENDTC    length=$20  label="End Date/Time of Adverse Event" 

    AESTDY     length=8    label="Study Day of Start of AE"
    AEENDY     length=8    label="Study Day of End of AE"
    AEDUR      length=$8   label="Duration of Adverse Event"
;

stop;
run;

data proj.ae2;
if 0 then set proj.ae_template;
merge proj.ae1(in=a) 
      proj.rf_days(in=b) 
      proj.dm(in=c keep=subjid siteid);
by subjid;
if a;
/*AESTDY*/
if aestdt ne . and rfstdt ne . then do;
        if AESTDT ge RFSTDT then AESTDY=(AESTDT-RFSTDT)+1;
        else if AESTDT lt RFSTDT then AESTDY=(AESTDT-RFSTDT);
end;
/*AEENDY*/
if aeendt ne . and rfstdt ne . then do;
        if AEENDT ge RFSTDT then AEENDY=(AEENDT-RFSTDT)+1;
        else if AEENDT lt RFSTDT then AEENDY=(AEENDT-RFSTDT);
end;
/*DUR*/
if AESTDY ne . and AEENDY ne . then aedur1=(AEENDY-AESTDY)+1;
else aedur1= . ;
if aedur1 ne . then AEDUR = strip(put(aedur1, best12.));
else AEDUR = ""; 
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid);
 
keep STUDYID DOMAIN USUBJID SITEID AESEQ AETERM AESEV AESER AEREL AEACN 
AELLT AELLTCD AEPTCD AEDECODE AEHLT AEHLTCD AEHLGT AEHLGTCD AESOC AESOCCD AEBODSYS 
AEBDSYCD AEMODIFY AESTDTC AEENDTC AESTDY AEENDY AEDUR;

run;
proc sort data=proj.ae2 ; by studyid usubjid; run;
