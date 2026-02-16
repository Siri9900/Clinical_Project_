/*SV*/
proc copy inlib=psoriasi outlib=proj;
run;
proc contents data =proj.sv short varnum; run;
/*SUBJID VISIT VISITTYPE REASON VISITNUM VISITDT*/
proc sort data=proj.sv; by SUBJID visitdt; run;

data proj.sv1 (drop= visitnum rename=(new_visitnum= visitnum));
set proj.sv;
by subjid;
studyid="cps111";
domain="SV";
visit=visit;
/*handling visitnum for unplanned visits*/
if first.subjid then do;
        last_planned_num = .;
    end;

    if VISITTYPE = 'Planned' then do;
        new_visitnum = VISITNUM;       /* Keep the original planned number */
        last_planned_num = VISITNUM;   /* Update the base for future unscheduled visits */                   
    end;
    else if VISITTYPE = 'Unplanned' then do;
        /* Formula: Base + (Counter * 0.1) */
	    retain new_visitnum;
	    if ~missing (last_planned_num) then new_visitnum = last_planned_num ; 
		else new_visitnum = (new_visitnum)+0.1 ; 
    end;
/*visit unplanned description*/
if VISITTYPE="Unplanned" then SVUPDES=REASON;
/*dates*/
vsdt=visitdt;
vendt=visitdt;
svstdtc = strip(put(visitdt,yymmdd10.));
svendtc=strip(put(visitdt,yymmdd10.)); 
run;
proc sort data=proj.sv1; by subjid; run;
data proj.sv_template;

attrib
    STUDYID  length=$20  label="Study Identifier"
    DOMAIN   length=$2   label="Domain Abbreviation"
    USUBJID  length=$20  label="Unique Subject Identifier"
    SITEID   length=$10  label="Study Site Identifier"

    VISIT    length=$40 label="Visit Name"
    VISITNUM length=8    label="Visit Number"
    SVUPDES  length=$40 label="Description of Unplanned Visit"

    SVSTDTC  length=$20  label="Start Date/Time of Visit" 
    SVENDTC  length=$20  label="End Date/Time of Visit" 

    SVSTDY   length=8    label="Study Day of Visit Start"
    SVENDY   length=8    label="Study Day of Visit End"
    SVDUR    length=$8   label="Duration of Visit"
;
stop;
run;

data proj.sv2;
if 0 then set proj.sv_template;
merge proj.sv1(in=a) 
      proj.dm (in=b keep= subjid siteid) 
      proj.rf_days(in=c);
by subjid;
if a;
/*STDY*/
if vsdt ne . and rfstdt ne . then do;
    if vsdt ge RFSTDT then SVSTDY=(vsdt-RFSTDT)+1;
    else if vsdt lt RFSTDT then SVSTDY=(vsdt-RFSTDT);
end;
/*ENDY*/
if vendt ne . and rfstdt ne . then do;
   if vendt ge RFSTDT then SVENDY=(vendt-RFSTDT)+1;
   else if vendt lt RFSTDT then SVENDY=(vendt-RFSTDT);
end;
/*DUR*/
if SVSTDY ne . and SVENDY ne . then SVdur1=(SVENDY-SVSTDY)+1;
else SVdur1= . ;
SVDUR=put(SVDUR1, best12.);
/*usubjid*/
usubjid=strip(studyid)||"-"||strip(subjid)||"-"||strip(siteid); 
keep STUDYID DOMAIN USUBJID SITEID   VISIT VISITNUM SVUPDES  SVSTDTC SVENDTC 
SVSTDY SVENDY SVDUR
;
run;
proc sort data=proj.sv2 ; by studyid usubjid; run;
