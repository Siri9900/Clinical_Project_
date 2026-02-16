/*QS table*/
/*BASELINE, POST-BASELINE TABLE*/
data proj.adqs_tab1;
length trta $ 20.;
set proj.ADEFF_qsFINAL1;
output;
trta="overall";
output;
run;

proc sql; create table proj.c1 as
select trta,paramcd, 
    max(base) AS MAX_BASE_LINE, 
    max(resp)AS MAX_RESPONSE, 
    max(pasi75) AS MAX_pasi75
from  proj.adqs_tab1
where aqslfl="Y"
group by trta, paramcd;
run;

data proj.c2;
set proj.c1;
BASE_LINE=put(MAX_BASE_LINE,12.3);
RESPONSE=put(MAX_RESPONSE,12.2);
if MAX_pasi75 ne . then pasi75_=put(MAX_pasi75,best12.);
run;
proc sort data=proj.c2; by  paramcd; run;

proc transpose data=proj.c2 out=proj.c3 ;
by  paramcd;
id trta;
  var  BASE_LINE RESPONSE pasi75_;
run;


proc sql; create table proj.c11 as
select trta,paramcd, 
   min(best_pb) as PBL,
   max(resp)AS MAX_RESPONSE, max(pasi75) AS MAX_pasi75
from  proj.adqs_tab1
group by paramcd, trta;
run;

data proj.c21;
set proj.c11;
POST_BASE_LINE=put(PBL,best12.3);
RESPONSE=put(MAX_RESPONSE,best12.);
if MAX_pasi75 ne . then pasi75_=put(MAX_pasi75,best12.);
run;
proc sort data=proj.c21; by  paramcd; run;

proc transpose data=proj.c21 out=proj.c31 ;
by  paramcd;
id trta;
  var  POST_BASE_LINE RESPONSE pasi75_;
run;

data proj.base;
_name_="BASELINE_RESULTS";
run;
data proj.postbase;
_name_="POST_TREATMENT_RESULTS";
run;

data proj.bas_pt_tab (rename= (_name_=stats));
length _name_ $ 50;
set proj.base proj.c3 proj.postbase proj.c31;
if _N_>1 and _N_<10 then _name_="  "||_name_;
else if _N_>11 then  _name_="  "||_name_;
else _name_="  "||_name_;
run;

proc print data=proj.bas_pt_tab noobs;
  title1 justify=center height=17pt color=cx003366  "Table 14-4.1:" color=red "Baseline and Post-Baseline Summary" ;
  title2 justify=right height=10pt color=cx003366  "&sysdate9..";
  footnote "";
run;

/**/
/*Comparing aval vs base on follow-up*/
proc sort data=proj.adqs_final out=proj.adqst; by studyid usubjid paramcd adt;
data proj.trteff;
set proj.adqst;
by usubjid paramcd adt;
if last.paramcd and avisit="Follow-up";
run;
proc sql;
create table proj.trteff1 as
 select paramcd, trta, aval, base, 
 count(case when aval >= base then usubjid end)as worsening,
 count (case when aval < base then usubjid end)as improving
from proj.trteff
group by paramcd, trta;
quit; 
proc freq data= proj.trteff1;
     table paramcd*improving*worsening*trta/ list nofreq  nopercent nocum out=proj.response;
run;
proc transpose data=proj.response out=proj.temp ;
by paramcd;
id trta;
var improving worsening;
title1 justify=center height=17pt color=cx003366  "Table 14-4.3:" color=red "Baseline and Post-Baseline table during followup" ;
title2 justify=right height=10pt color=cx003366  "&sysdate9..";
footnote "";
run;
