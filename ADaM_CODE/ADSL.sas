proc copy inlib=psoriasi outlib=proj;
run;
/*ADaM*/
/*ADSL*/
/*TEMPLATE*/
data proj.adsl_template;

attrib
    STUDYID   length=$20  label="Study Identifier"
    USUBJID   length=$20  label="Unique Subject Identifier"
    SITEID    length=$10  label="Study Site Identifier"
    SITEID   Label="Site Identifier" Length= $10
    SEX      Label="SEX" Length= $1
    AGE      Label="Age" Length= 3
    AGEU     Label="Age units" Length= $10
	SITEGRy   length=$8    label='Site Group'
    AGEGRy    length=$8    label='Age Group'
	    /* Numeric Variables */
    SITEGRyN  label='Site Group (N)'
    AGE       label='Age' Length= 8
    AGEGRyN   label='Age Group (N)'
    SEXN      label='Sex (N)'
    TRTPN     label='Planned Treatment (N)'
    TRTAN     label='Actual Treatment (N)'
	    /* Treatment Information - Character */

    TRTP      length=$10   label='Planned Treatment'
    TRTA      length=$10   label='Actual Treatment'

    RACE     Label="Race" Length= $15
    ETHNIC   Label="Ethnic" Length= $15
    COUNTRY  Label="Country" Length= $5
    ARM      Label="Planned Arm" Length= $10
    ARMCD    Label="Planned Arm description" Length= $10 
    ACTARM   Label="Actual Arm" Length= $10
    ACTARMCD Label="Actual Arm Description" Length= $10 
    DTHFL    Label="Death flag" Length= $1
	    /* Flags - Character */
    ITTFL     length=$1     label='Intent-To-Treat Population Flag'
    SAFFL     length=$1     label='Safety Population Flag'
    ENRLFL    length=$1     label='Enrolled Population Flag'
    RANDFL    length=$1     label='Randomized Population Flag'
    COMPLFL   length=$1     label='Completed Study Flag'
    PPROTFL   length=$1     label='Per Protocol Population Flag'
    DTHDTF    length=$1     label='Death Flag'
	    /* Dates - Numeric with format */
    RFICDT    format=yymmdd10.   label='Date of Informed Consent'
    RANDDT    format=yymmdd10.   label='Randomization Date'
    DSSDT    format=yymmdd10.   label='Disposition Start Date'
    EOSDT     format=yymmdd10.   label='End of Study Date'
    TRTSDT    format=yymmdd10.   label='Date of First Exposure'
    TRTEDT    format=yymmdd10.   label='Date of Last Exposure'
    EOSTDT    format=yymmdd10.   label='End of Study Treatment Date'
    FVISDT    format=yymmdd10.   label='First Visit Date'
    LVISDT    format=yymmdd10.   label='Last Visit Date'
	DTHDT     format=yymmdd10.   label='Death date'
	    /* Treatment Details - Character */
    DOSEU       label='Dose Units'
    
	    /* Treatment Details - Numeric */
    DOSEP     label='Planned Dose'
    DOSEA     label='Actual Dose'
    
    /* Duration - Numeric */
    TRDURD    label='Treatment Duration (Days)'
    TRDURM    label='Treatment Duration (Months)'
    TRDURY    label='Treatment Duration (Years)'
    
    /* Compliance - Numeric */
    TRTCMP    label='Treatment Compliance (%)'
	    
    /* Study Status - Character */
    EOSTT        label='End of Study Status'
    EOSTREAS    label='Reason for End of Study'
;
stop;
run;

/*format for grouping sites*/
proc sql; select distinct(siteid) from proj.dm2;run;
/*S01 
S02 
S03 
S04 
S05 
S06 
*/
proc format;
  value $sitegryf
    'S01'  = 'GRP-A'
    'S02'    = 'GRP-B'
    'S03' = 'GRP-C'
    'S04'    = 'GRP-D'
	'S05'    = 'GRP-E'
	'S06'    = 'GRP-F';
run;
proc format;
  value $sitegryn
    'GRP-A'= 1
    'GRP-B'=2
    'GRP-C'=3
    'GRP-D'=4
	'GRP-E'=5
	'GRP-F'=6;
run;
proc format;
  value $sitegrynn
    'S01'= 1
    'S02'=2
    'S03'=3
    'S04'=4
	'S05'=5
	'S06'=6;
run;

data proj.adsl1 (Keep= studyid usubjid SITEID SITEGRy SITEGRyN AGE AGEU AGEGRy AGEGRyN
SEX SEXN RACE ETHNIC ARM ARMCD ACTARM ACTARMCD TRTP TRTPN TRTA TRTAN dthdt dthdtf country);
length  SITEGRy $8   AGEGRy $8 SITEGRyN 8   AGEGRyN 8;
set proj.dm2;
/*group similar sites*/
SITEGRy=strip(put(siteid, $sitegryf.)); 
SITEGRyN=input(put(siteid, $sitegrynn.), best.);
/*group age*/
if 18 <= age <= 28 then do;
     AGEGRy="AG1";
     AGEGRyN=1;
end;
if 29 <= age <= 39 then do;
     AGEGRy="AG2";
     AGEGRyN=2;
end;
if 40 <= age <= 50 then do;
     AGEGRy="AG3";
     AGEGRyN=3;
end;
if age ge 51 then do;
     AGEGRy="AG4";
     AGEGRyN=4;
end;
/*numeric sex*/
if upcase(sex)="M" then SEXN=1;
else if upcase(sex)="F" then SEXN=2;
else SEXN=.;
/*trtp, trta*/
trtp=arm;
trta=actarm;
if arm = "A1" then trtpn = 1;
else if arm = "A2" then trtpn = 2;
if actarm = "A1" then trtan= 1;
else if actarm = "A2" then trtan = 2;

/*death date variables in numeric*/
dthdt = input(scan(dthdtc,1,'T'), yymmdd10.); format dthdt yymmdd10.;
dthdtf= dthfl;
run; 
proc sort data= proj.adsl1; by studyid usubjid; run;
/*validate*/
/*proc freq data=proj.adsl1;*/
/*tables arm*trtpn actarm*trtan / missing;*/
/*run;*/

proc sort data=proj.ds2 out=proj.ds_sorted; by studyid usubjid DSSTDTC; run;
data proj.adsl2;
  length ENRLFL $1 RANDFL $1 COMPLFL $1 
         EOSTT $100 EOSTREAS $100;
  retain RFICDT RANDDT ENRLFL RANDFL COMPLFL EOSTT EOSTREAS EOSDT;
  set proj.ds_sorted;
  by studyid usubjid DSSTDTC;
  
  format RFICDT RANDDT EOSDT yymmdd10.;
  dssdt= input(DSSTDTC, yymmdd10.); format DSSDT yymmdd10.;
  
  /* Keep values from appropriate records */
  if first.usubjid then do;
    call missing(RFICDT, RANDDT, ENRLFL, RANDFL, COMPLFL, EOSTT, EOSTREAS, EOSDT);
  end;
  
  /* RFICDT from Informed Consent */
  if DSSTDTC ne "" and upcase(dsterm)="INFORMED CONSENT SIGNED" and missing(RFICDT)
  then RFICDT = dssdt;
  
  /* RANDDT from Randomized */
  if DSSTDTC ne "" and upcase(dsterm)="RANDOMIZED" and missing(RANDDT) 
  then RANDDT = dssdt;;
  
  /* ENRLFL */
  if upcase(dscat)="PROTOCOL MILESTONE" and upcase(dsterm)="INFORMED CONSENT SIGNED" 
     and DSSTDTC ne "" then ENRLFL = "Y";
  
  /* RANDFL */
  if upcase(dscat)="PROTOCOL MILESTONE" and upcase(dsterm)="RANDOMIZED" 
     and DSSTDTC ne "" then RANDFL = "Y";
  /*intent to treat flag*/
  if RANDFL = "Y" then ITTFL="Y";
  else ITTFL="N";
  /* COMPLFL - check if Completed Study exists */
  if upcase(dsterm)="COMPLETED STUDY" and DSSTDTC ne "" then 
    COMPLFL = "Y";
  
  /* End of Study info from last record */
  if last.usubjid then do;
    EOSTT = dsterm; /* End of Study status*/
    EOSTREAS = dsterm; /* End of Study status reason */
    if dssdt ne . then EOSDT = dssdt; /* End of Study date */
	 if missing(RANDFL) then RANDFL="N";
     if missing(ENRLFL) then ENRLFL="N";
     if missing(COMPLFL) then COMPLFL="N";
    output;
  end;
  
  keep studyid usubjid RFICDT dssdt RANDDT ENRLFL RANDFL ITTFL COMPLFL EOSTT EOSTREAS EOSDT;
run;

proc sort data=proj.ex3 out=proj.ex_sorted; by studyid usubjid exstdtc; run;
data proj.adsl3;
length SAFFL $1 DOSEU $10;
  retain SAFFL TRTSDT TRTEDT EOSTDT DOSEP DOSEA DOSEU TRDURD TRDURM TRDURY;
  set proj.ex_sorted;
  by studyid usubjid exstdtc;
  format TRTSDT TRTEDT EOSTDT yymmdd10.;
  if first.usubjid then do;
  call missing(SAFFL, TRTSDT, TRTEDT, EOSTDT,
               DOSEP, DOSEA, DOSEU,
               TRDURD, TRDURM, TRDURY);
  end;
  
  if not missing(EXSTDTC) then do;
    /* First exposure */
    SAFFL = "Y";
    TRTSDT = input(scan(EXSTDTC,1,'T'), yymmdd10.);
    DOSEP = exdose;
    DOSEA = exdose;
    DOSEU = exdosu;
  end;
  
  if last.usubjid then do;
    /* Last exposure */
    TRTEDT = input(EXENDTC, yymmdd10.);
    EOSTDT = input(EXENDTC, yymmdd10.); /* End of Study treatment date */
    
    /* Calculate durations */
    if not missing(TRTSDT) and not missing(TRTEDT) then do;
      TRDURD = intck('day', TRTSDT, TRTEDT) + 1;  /* +1 to include start day */
      TRDURM = intck('month', TRTSDT, TRTEDT); /* or int(TRDURD/30.4375);*/
      TRDURY = intck('year', TRTSDT, TRTEDT);  /* or int(TRDURD/365.25);*/
    end;
    
    output;
  end;
  
  keep studyid usubjid SAFFL TRTSDT TRTEDT EOSTDT DOSEP DOSEA DOSEU TRDURD TRDURM TRDURY;
run;
proc sort data= proj.adsl3; by studyid usubjid; run;


proc sort data= proj.sv2 out= proj.sv22; by studyid usubjid svstdtc; run;
data proj.adsl4 (keep= studyid usubjid FVISDT LVISDT);
set proj.sv22;
by studyid usubjid svstdtc;
retain FVISDT LVISDT;
format FVISDT LVISDT yymmdd10.;
/*first visit and last visit*/
  if first.usubjid then do;
    FVISDT = input(svstdtc, yymmdd10.);
    LVISDT = .;  /* Will be updated on last record */
  end;
  
  /* Update LVISDT on every record (will end with last value) */
  if not missing(svendtc) then 
    LVISDT = input(svendtc, yymmdd10.);
  
  /* Output only on last record of each subject */
  if last.usubjid then output;
run;
proc sort data= proj.adsl4; by studyid usubjid; run;

/*per protocol*/
/*compliance flag*/
/* Create compliance flags directly from SV */
data proj.adsl_comp;
length PPROTFL $1;
  set proj.sv22;
  by studyid usubjid svstdtc;
  retain trt_wks;
  
  /* Count treatment weeks per subject */
  if index(upcase(visit), 'TREATMENT') > 0 then trt_wks + 1;  /* Increment counter */
  /* Keep only treatment visits */
  if first.usubjid then trt_wks = 0;
  
  /* Output one record per subject */
  if last.usubjid ;
  /* Set compliance flags */  
     if trt_wks >= 4 then do;
     PPROTFL = "Y";
     TRTCMP = 100;
  end;
  else if trt_wks = 3 or trt_wks =2 then do;
     PPROTFL = "N";
     TRTCMP = 50;
  end;
  else if trt_wks = 1 then do;
     PPROTFL = "N";
     TRTCMP = 25;
  end;
  else do;  /* No treatment visits */
     PPROTFL = "N";
     TRTCMP = 0;
  end;
  output;

  keep studyid usubjid trt_wks PPROTFL TRTCMP;
run;
proc sort data= proj.adsl_comp; by studyid usubjid; run;


/* Now merge all datasets - should have 25 observations each */
data proj.adsl_final;
  merge proj.adsl_template (in=temp)
        proj.adsl1 (in=a)
        proj.adsl2 (in=b)
        proj.adsl3 (in=c)
        proj.adsl4 (in=d)
        proj.adsl_comp (in=e);
  by studyid usubjid;
  if a;
keep SITEGRY AGEGRY SITEGRYN AGEGRYN STUDYID SITEID SEX AGE AGEU RACE ETHNIC COUNTRY ARM ARMCD
ACTARM ACTARMCD USUBJID SEXN TRTP TRTA TRTPN TRTAN DTHDT DTHDTF ENRLFL RANDFL COMPLFL
EOSTT EOSTREAS RFICDT RANDDT EOSDT DSSDT ITTFL SAFFL DOSEU TRTSDT TRTEDT EOSTDT DOSEP
DOSEA TRDURD TRDURM TRDURY FVISDT LVISDT PPROTFL TRTCMP;

run;
proc contents data= proj.adsl_final short varnum; run;



/* Verify */
/*proc freq data=proj.adsl_final;*/
/*  tables studyid;*/
/*run;*/
