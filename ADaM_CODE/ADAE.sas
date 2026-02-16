proc copy inlib=psoriasi outlib=proj;
run;
/*OCCD-ADAE*/
/* ADAE Creation - using existing SDTM AE and ADSL */

data proj.adae_template;
/* Label all variables */
  attrib
    STUDYID   length=$20 label='Study Identifier'
    USUBJID   length=$20 label='Unique Subject Identifier'
    DOMAIN    length=$2 label='Domain Abbreviation'
    AESEQ     length=8  label='Sequence Number'
    AETERM    length=$30 label='Reported Term for the Adverse Event'
    AEMODIFY  length=$30 label="Modified Reported Term"

    AESEV      length=$10   label="Severity/Intensity"
    AESER      length=$1   label="Serious Event"
    AEREL      length=$30  label="Causality"
    AEACN      length=$30  label="Action Taken with Study Treatment"

    AELLT      length=$20 label="Lowest Level Term"
    AELLTCD    length=8    label="Lowest Level Term Code"
    AEPTCD     length=8 label="Preferred Term Code"
    AEDECODE   length=$60 label="Dictionary-Derived Term"
    AEHLT      length=$60 label="High Level Term"
    AEHLTCD    length=8    label="High Level Term Code"
    AEHLGT     length=$60 label="High Level Group Term"
    AEHLGTCD   length=8    label="High Level Group Term Code"
    AESOC      length=$60 label="System Organ Class"
    AESOCCD    length=8    label="System Organ Class Code"
    AEBODSYS   length=$60 label="Body System or Organ Class"
    AEBDSYCD   length=8   label="Body System Code"


    ASTDT     format=yymmdd10. label='Analysis Start Date'
    AENDT     format=yymmdd10. label='Analysis End Date'
    AESTDY    length=8 label='Study Day of Start of Adverse Event'
    AEENDY    length=8 label='Study Day of End of Adverse Event'
    AEDUR     length=$8 label='Duration of Adverse Event Char'
	AEDURN    length=8 label='Duration of Adverse Event Numeric'
	AEDURU    length=$8 label='Duration of Adverse Event units'
	AESEVN    length=8 label='Severity/Intensity Numeric'
	AESERN    length=8 label='Serious Event Numeric'


	AERELN     length=8  label='Causality Numeric'

    TRTSDT     label='Date of First Exposure to Treatment'
    TRTEDT     label='Date of Last Exposure to Treatment'
    TRTA       length=$10 label='Actual Treatment'
    TRTAN      length=8 label='Actual Treatment (N)'
	TRTP       length=$10 label='Planned Treatment'
    TRTPN      length=8 label='Planned Treatment (N)'
	PRETRTFL   length=$1 label='Pre-Treatment flag'
	POSTRTFL   length=$1 label='Post-Treatment flag'
    SAFFL      length=$1 label='Safety Population Flag'
    TRTEMFL    length=$1 label='Treatment Emergent Analysis Flag'
	AOCCFL     length=$1 label='First EventOccurrence Flag'
    AOCCPFL    length=$1 label='Occurrence Within Preffered-term Flag'
	AOCCSFL    length=$1 label='Occurrence Within SOC Flag'
    AOCCIFL    length=$1 label='First Occurrence Within severity Flag'
	AOCCZZFL   length=$1 label='Analysis Flag'
  ; 
 stop;
run;

proc sort data=proj.ae2 out=proj.ae_sorted;by studyid usubjid; run;

/* Get ADSL variables needed for ADAE */
proc sql;
  create table proj.adsl_f as
  select 
    studyid,
    usubjid,
    siteid,
    TRTSDT,        /* Treatment start date */
    TRTEDT,        /* Treatment end date */
    TRTA,          /* Actual treatment */
    TRTAN,         /* Actual treatment numeric */
	TRTP,          /* Planned treatment */
    TRTPN, 
    SAFFL,         /* Safety population flag */
    RFICDT,        /* Informed consent date */
    RANDDT         /* Randomization date */
  from proj.adsl_final;
quit;
proc sort data=proj.adsl_f;by studyid usubjid; run;

/* Create ADAE by merging AE with ADSL */
data proj.adae1;
length  PRETRTFL $1 POSTRTFL $1 TRTEMFL $1 aereln 8 aesern 8 AOCCZZFL $1 AEDUR1 8;
merge proj.ae_sorted (in=inae) proj.adsl_f;
by studyid usubjid;
if inae;
  
  /* Convert character dates to numeric for analysis */
  if AESTDTC ne "" then ASTDT = input(AESTDTC, yymmdd10.);
  if AEENDTC ne "" then AENDT = input(AEENDTC, yymmdd10.);
  format ASTDT AENDT yymmdd10.;
  
  /* Seriousness flag */
  if AESER="Y" then AESERN=1;
  else if AESER="N" then AESERN=2;
  else AESERN=.;


  /* Severity flag */
  if  upcase(AESEV) = "MILD" then AESEVN=1;
  else if  upcase(AESEV) = "MODERATE" then AESEVN=2;
  else AESEVN=3;

  /* causality*/
    if upcase(aerel)="NOT RELATED" then AERELN = 1;
    else if upcase(aerel)="POSSIBLY RELATED" then AERELN = 2;
    else if upcase(aerel)="PROBABLY RELATED" then AERELN = 3;
    else if upcase(aerel)="LIKELY RELATED" then AERELN = 4;
    else AERELN = .;
  
  /* Analysis Flags - CRITICAL FOR ADAE */
  /* PreTreatment Emergent Flag */
 if not missing(astdt) and not missing(TRTSDT) then do;
     if astdt < TRTSDT then pretrtfl = "Y";
	 else pretrtfl = "N"; 
 end;
 else pretrtfl = "N"; 
  /* PostTreatment Emergent Flag */
 if not missing(astdt) and not missing(trtedt) and 
     (astdt > trtedt) then postrtfl = "Y";
  else postrtfl = "N";
  /* Treatment Emergent Flag */
  if not missing(ASTDT) and not missing(TRTSDT) then do; 
     if ASTDT ge TRTSDT and AENDT le TRTEDT then TRTEMFL = "Y";
	 else TRTEMFL = "N";
  end;
  else TRTEMFL = "N";
  
  /* 1-Day Adverse Event Flag */
  AEDUR1=input(AEDUR, 8.); format AEDUR1 best12.;
  if AEDUR1 < 0 then AOCCZZFL= "Y";
  else AOCCZZFL= "N";
  run;
proc sort data=proj.adae1;by studyid usubjid aeseq;run;

/*AOCCFL (First AE per Subject)*/
proc sort data=proj.ae2 out=proj.ae_s1;by studyid usubjid aestdtc aeseq;run;
data proj.flag_aoccfl(keep=studyid usubjid aeseq aoccfl);
length aoccfl $1;
set proj.ae_s1;
by studyid usubjid aestdtc;
if first.usubjid then aoccfl="Y";
else aoccfl="N";
run;
proc sort data=proj.flag_aoccfl;by studyid usubjid aeseq;run;
/*AOCCPFL (First per Preferred Term)*/
proc sort data=proj.ae2 out=proj.ae_s2;by studyid usubjid aedecode aestdtc aeseq;run;
data proj.flag_aoccpfl(keep=studyid usubjid aeseq aoccpfl);
length aoccpfl $1;
set proj.ae_s2;
by studyid usubjid aedecode;
if first.aedecode then aoccpfl="Y";
else aoccpfl="N";
run;
proc sort data=proj.flag_aoccpfl;by studyid usubjid aeseq;run;
/*AOCCSFL (First per SOC)*/
proc sort data=proj.ae2 out=proj.ae_s3;by studyid usubjid aesoc aestdtc aeseq;run;
data proj.flag_aoccsfl(keep=studyid usubjid aeseq aoccsfl);
length aoccsfl $1;
set proj.ae_s3;
by studyid usubjid aesoc;
if first.aesoc then aoccsfl="Y";
else aoccsfl="N";
run;
proc sort data=proj.flag_aoccsfl;by studyid usubjid aeseq;run;
/*AOCCIFL (First per Severity)*/
proc sort data=proj.ae2 out=proj.ae_s4;by studyid usubjid aesev aestdtc aeseq;run;
data proj.flag_aoccifl(keep=studyid usubjid aeseq aoccifl);
length aoccifl $1;
set proj.ae_s4;
by studyid usubjid aesev;
if first.aesev then aoccifl="Y";
else aoccifl="N";
run;
proc sort data=proj.flag_aoccifl;by studyid usubjid aeseq;run;

data proj.adae_final;
if 0 then set proj.adae_template;
length aedurn 8 aeduru $8 aoccfl $1 aoccpfl $1 aoccsfl $1 aoccifl $1;
merge proj.adae1 (in=a) 
      proj.flag_aoccfl (in=b)
      proj.flag_aoccpfl (in=c)
      proj.flag_aoccsfl (in=d)
      proj.flag_aoccifl (in=e);
by studyid usubjid aeseq;
if a;
aedurn=aedur1;
aeduru="days"; 
/* Keep only ADAE variables */
  keep STUDYID USUBJID DOMAIN AESEQ
       AETERM AESTDTC AEENDTC ASTDT AENDT AESTDY AEENDY AEDUR AEDURU
       AESEV AESEVN AESER AESERN AEACN AEREL AERELN
       AELLT AELLTCD AEDECODE AEPTCD AEHLT AEHLTCD 
       AEHLGT AEHLGTCD AESOC AESOCCD AEBODSYS AEBDSYCD AEMODIFY
       TRTSDT TRTEDT TRTA TRTAN TRTP TRTPN
       SAFFL PRETRTFL POSTRTFL TRTEMFL AOCCFL AOCCPFL AOCCSFL AOCCIFL AOCCZZFL;
run;
proc sort data=proj.adae_final;by STUDYID USUBJID ;run;


/* Summary statistics */
proc freq data=proj.adae_final;
  tables TRTA*TRTEMFL AESER*AESEV / norow nocol nopercent;
  where TRTEMFL="Y";
  title "ADAEs by Treatment and Severity";
run;

/* Count AEs per subject */
proc sql;
  create table proj.ae_counts as
  select TRTA,
         count(distinct USUBJID) as N_subjects,
         count(*) as Total_AEs,
         sum(case when TRTEMFL='Y' then 1 else 0 end) as Treatment_Emergent_AEs,
         sum(case when AESER='Y' then 1 else 0 end) as Serious_AEs
  from proj.adae_final
  group by TRTA
  order by TRTA;
  quit;
