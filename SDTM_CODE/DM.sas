proc copy inlib=psoriasi outlib=proj;
run;

proc contents data=proj.dm short varnum;
run;
/*SUBJID SITEID SEX AGE AGEU RACE ETHNIC COUNTRY*/

options validvarname= 'upcase';
data proj.dm1;
length usubjid $20;
set proj.dm;
studyid="cps111";
subjid=subjid;
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
siteid=siteid;
sex=sex;
race=race;
ethnic=ethnic;
run;
proc sort data=proj.dm1; by SUBJID; run;

/*RFICDTC*/
proc contents data=proj.ds short varnum;run;
proc sort data=proj.ds out=proj.dssort; by SUBJID DSSTDT; run;
/*SUBJID DS_EVENT DS_CAT DSSTDTC DS_REASON*/
data proj.consent (keep=SUBJID RFICDTC where= (rficdtc ne ''));
set proj.ds (keep=SUBJID DS_EVENT DSSTDT);
if DSSTDT ne . and DS_EVENT="Informed Consent Signed" then 
RFICDTC=strip(put(DSSTDT, yymmdd10.));
run;
proc sort data=proj.consent ; by SUBJID; run;


/*RFSTDTC, RFENDTC*/
proc contents data=proj.ex short varnum;
run;
/*SUBJID EXKITID EXLOT EXDOSE EXDOSU EXROUTE EXSTDT EXENDT*/
proc sort data=proj.ex out=proj.ex1; by SUBJID EXSTDT exdose; run;
data proj.trtdt (keep= SUBJID  rfstdtc rfendtc where= (rfstdtc ne '' and rfendtc ne '')) ;
set proj.ex1 (keep= SUBJID EXDOSE EXSTDT EXENDT);
by SUBJID EXSTDT; 
if first.subjid then rfstdtc=strip(put(EXSTDT, yymmdd10.));
if last.subjid then rfendtc=strip(put(EXENDT, yymmdd10.));
run;
proc sort data=proj.trtdt; by SUBJID; run;

/*ARM*/
/*Actual Arm from first exposure*/
proc sort data=proj.ex (rename= (EXSTDT=dt)) out=proj.ex1 ; by SUBJID dt exkitid ; run;
data proj.arm1;
set proj.ex1;
by SUBJID dt exkitid ;
if first.subjid;
   actarm=exkitid;
   actarmcd="PS"||"-"||exkitid;
run;
proc sort data=proj.arm1; by SUBJID; run;
/*Planned Arm from Randomization*/
proc sort data=proj.raand (rename= (randdt=dt))out=proj.rand1; by SUBJID dt randcode; run;
data proj.rand2;
set proj.rand1;
by SUBJID dt randcode ;
if first.subjid;
   arm=randcode;
   armcd="PS"||"-"||randcode;
run;
proc sort data=proj.rand2; by SUBJID; run;
/*ARM, ACTUAL ARM*/
data proj.arm (keep= SUBJID arm dt armcd actarm actarmcd);
merge proj.arm1 (in=c) proj.rand2(in=e);
by SUBJID;
run;
proc sort data=proj.arm ; by SUBJID; run;

/*RFPENDTC*/
data proj.study_end (keep= SUBJID  rfpendtc where= (rfpendtc ne '')) ;
set proj.dssort (keep=SUBJID DS_EVENT DSSTDT);
by subjid dsstdt;
if last.subjid then rfpendtc=strip(put(DSSTDT, yymmdd10.));
run;
proc sort data=proj.study_end; by SUBJID; run;

/*DTHDTC*/
data proj.death (keep=SUBJID dthdtc dthfl where= (dthdtc ne ''));
length dthfl $1;
set proj.dssort (keep=SUBJID DS_EVENT DSSTDT);
if DSSTDT ne . and DS_EVENT="Death" then do;
   dthdtc= strip(put(DSSTDT, yymmdd10.));
   dthfl="Y";
end;
else do;
   dthdtc= "";
   dthfl="";
end;
run;
proc sort data=proj.death ; by SUBJID; run;
data proj.dm_template;
ATTRIB
    STUDYID Label="Study-Identifier" Length= $20 
    DOMAIN  Label="Domain" Length= $2
    USUBJID Label="Unique Subject Identifier" Length= $20
    SUBJID  Label="Subject Identifier" Length= $15
    RFICDTC Label="Informed Consent date"  Length= $10
    RFSTDTC Label="Study Reference start date"   Length= $10
    RFENDTC Label="Study Reference end date"   Length= $10
    RFXSTDTC Label="Study Exposure start date"  Length= $10
    RFXENDTC Label="Study Exposure end date"   Length= $10
    RFPENDTC Label="Study Participation date"  Length= $10
    SITEID   Label="Site Identifier" Length= $10
    SEX      Label="SEX" Length= $1
    AGE      Label="Age" Length= 3
    AGEU     Label="Age units" Length= $10
    RACE     Label="Race" Length= $15
    ETHNIC   Label="Ethnic" Length= $15
    COUNTRY  Label="Country" Length= $3
    ARM      Label="Planned Arm" Length= $10
    ARMCD    Label="Planned Arm description" Length= $10 
    ACTARM   Label="Actual Arm" Length= $10
    ACTARMCD Label="Actual Arm Description" Length= $10 
    ARMNRS   Label="Reason for ARM/ACTARM null" Length= $20
    DTHDTC   Label="Death date" 
    DTHFL    Label="Death flag" Length= $1;
stop;
run;


/*merge all*/
data proj.dm2;
length age 8 country $5;
      merge proj.dm_template (in=temp)
            proj.dm1 (in=a) 
            proj.consent (in=b) 
            proj.trtdt (in=c) 
            proj.arm (in=d)
            proj.study_end (in=e) 
            proj.death (in=f);
by subjid ;
if a;
domain="DM";
/*not planned reason*/
if arm eq "" and actarm eq "" then armnrs="screen-failure";
else if not missing (arm) and missing(actarm) then armnrs="Randomised not treated";
/*RFXSTDTC, RFXENDTC*/
RFXSTDTC=RFSTDTC;
RFXENDTC=RFENDTC;
country=strip(country);
age=age;
ageu=ageu;
/*AGE*/
/*Calculate from date of birth and rfstdtc (both should be same datatype, date/time /both format)
           If ~ missing (birth) then Dob=input(birth,yymmdd10.);
           If ~ missing (trstsdt) then Trtsdt=input(rfstdtc,is8601da.);  
	age=intck('year', dob,rfstdt )-(mdy(month(dob),day(dob),year(rfstdt)) > rfstdt); (use round/ integer function to get int value)
(or) use yeardiff */
keep STUDYID DOMAIN USUBJID SUBJID RFICDTC RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFPENDTC
SITEID SEX AGE AGEU RACE ETHNIC COUNTRY ARM  ARMCD ACTARM ACTARMCD ARMNRS DTHDTC DTHFL;
run;
proc sort data=proj.dm2 ; by studyid USUBJID; run;

/*validation*/
proc sql;
create table proj.dm_validation as
select count(*) as tot_subj
from proj.dm2
group by studyid, usubjid
having tot_subj>1;
quit;
/*other than controlled terminology or out of range values*/
data proj.dm_vad1;
set proj.dm2;
where SEX not in ("F","M");
if age < 18 or age > 70;
run;
