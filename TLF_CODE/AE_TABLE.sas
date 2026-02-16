/*AE Tables*/
data proj.adaetab;
length trta $10;
set proj.adae_final;
output;
trta="overall";
output;
run;
proc freq data=proj.adaetab;
  where trtemfl='Y';
  tables aesoc*aehlt*aellt*aedecode*trta / list out=proj.ae_counts;
run;
data proj.aetab1;
set proj.ae_counts;
count_P=put(count,3.)||"("||strip(put(percent,3.2))||"%"||")";
run;
proc sort data=proj.aetab1; by aesoc aehlt aellt aedecode; run;

proc transpose data=proj.aetab1 out=proj.aetab2 (drop=_name_);
id trta;
by aesoc aehlt aellt aedecode;
  var count_P ;
run;


proc print data=proj.aetab2 noobs;
  title1 justify=center height=17pt color=cx003366  "Table 14-3.1:" color=red "ADVERSE EVENTS LISITING" ;
  title2 justify=center height=10pt "(where trtemfl="Y")";
  title3 justify=right height=10pt color=cx003366  "&sysdate9..";
  footnote "";
run;

/* Create AE table with SOC, HLT, LLT, PT*/
/*safety denom*/
proc sql;
create table proj.denom as
select trta,
       count(distinct usubjid) as N
from proj.adaetab
where trtemfl='Y'
group by trta;
quit;
proc sql;
create table proj.ae_decode as
select aesoc,
       aehlt,
       aellt,
       aedecode,
       trta,
       count(distinct usubjid) as n
from proj.adaetab
where trtemfl='Y'
group by aesoc, aehlt, aellt, aedecode, trta;
quit;
proc sql;
create table proj.ae_llt as
select aesoc,
       aehlt,
       aellt,
       '' as aedecode length=200,
       trta,
       count(distinct usubjid) as n
from proj.adaetab
where trtemfl='Y'
group by aesoc, aehlt, aellt, trta;
quit;
proc sql;
create table proj.ae_hlt as
select aesoc,
       aehlt,
       '' as aellt length=200,
       '' as aedecode length=200,
       trta,
       count(distinct usubjid) as n
from proj.adaetab
where trtemfl='Y'
group by aesoc, aehlt, trta;
quit;
proc sql;
create table proj.ae_soc as
select aesoc,
       '' as aehlt length=200,
       '' as aellt length=200,
       '' as aedecode length=200,
       trta,
       count(distinct usubjid) as n
from proj.adaetab
where trtemfl='Y'
group by aesoc, trta;
quit;
data proj.ae_all;
set proj.ae_soc proj.ae_hlt proj.ae_llt proj.ae_decode;
run;
proc sql;
create table proj.ae_pct as
select a.*,
       b.N,
       (a.n / b.N) * 100 as pct
from proj.ae_all as a
left join proj.denom as b
on a.trta=b.trta;
quit;
data proj.ae_fmt;
set proj.ae_pct;
length value $20;

if n>0 then
   value = cats(put(n,3.),' (',put(pct,5.1),'%)');
else
   value='0';
run;
data proj.ae_label;
set proj.ae_fmt;
length row_label $300;

if aehlt='' then 
   row_label = aesoc;

else if aellt='' then 
   row_label = cats('  ',aehlt);

else if aedecode='' then 
   row_label = cats('    ',aellt);

else 
   row_label = cats('      ',aedecode);

run;
proc sort data=proj.ae_label;
by  aesoc aehlt aellt aedecode row_label ;
run;
proc transpose data=proj.ae_label out=proj.ae_final_tab(drop=_name_);
by  aesoc aehlt aellt aedecode row_label;
id trta;
var value;
run;
data proj.ae_final2;
set proj.ae_final_tab;
array trtcols {*} _character_;

do i=1 to dim(trtcols);
   if missing(trtcols{i}) then trtcols{i}='0 (0.0%)';
end;

drop i aesoc aehlt aellt aedecode;
run;
proc print data=proj.ae_final2 noobs;
title1 justify=center 
"Table 14-3.1: Adverse Events by SOC and decode";
title2 "(Treatment Emergent)";
run;


                           /*          or                */

/* Create AE table with SOC, HLT, LLT, PT*/
proc sql; select count(distinct(usubjid)) into : N_trt1
from proj.adae_final where trtemfl="Y"  group by trta;run;
proc sql;
  create table proj.ae_ as
  select 
    aesoc, aehlt, aellt, aedecode, trta,
    count(*) as n,
    count(distinct usubjid) as n_subj
  from proj.adaetab
  where trtemfl='Y'
  group by aesoc,  aehlt, aellt, aedecode, trta;
quit;
proc sort data=proj.ae_; by aesoc  aehlt aellt aedecode  trta; run;

/* Create hierarchy with indentation */
data proj.ae_hierarchy;
  length row_label $50;
  set proj.ae_;
  by aesoc  aehlt aellt aedecode ;  
  /* SOC (Level 1 - no indent) */
  if first.aesoc then do;
    row_label = 'SOC: '|| aesoc;
    output;
  end;
  
  /* HLT (Level 2 - 2 spaces indent) */
  if first.aehlt then do;
    row_label = "  "||'HLT: '||aehlt;
    output;
  end;
  
  /* LLT (Level 3 - 4 spaces indent) */
  if first.aellt then do;
    row_label = "    "||'LLT: '||aellt;
    output;
  end;
  
  /* PT (Level 4 - 6 spaces indent) with counts */
  row_label = "     "||'decode: '||aedecode;
  output;
  
  keep row_label trta n n_subj;
run;

/* Format counts as XX (XX.X%) */
data proj.ae_format;
  length fmt_value $20;
  set proj.ae_hierarchy;  
  if not missing(n) then 
    fmt_value = cats(put(n, 3.), ' (', put(n_subj/&N_trt1*100, 8.1), '%)');
  else fmt_value = '';
  
  keep row_label trta fmt_value;
run;

/* Transpose for treatment columns */
proc transpose data=proj.ae_format out=proj.ae_fi;
  by row_label notsorted;
  id trta;
  var fmt_value;
run;

/* final  */
data proj.ae_table;
  set proj.ae_fi;
  if overall= "" then overall= "00(00)";
  if A1= "" then A1= "00(00)";
  if A2= "" then A2= "00(00)";
  drop _name_;
run;

proc print data=proj.ae_table noobs;
  title1 justify=center height=17pt color=cx003366  "Table 14-3.1:" color=red "ADVERSE EVENTS (SOC, HLT, LLT, PT)" ;
  title2 justify=center height=10pt "(where trtemfl="Y")";
  title3 justify=right height=10pt color=cx003366  "&sysdate9..";
  footnote "";
run;

/*AE SEVERITY, SERIOUSNESS, RELATION, ACN TAKEN TABLE*/
%macro aesev (in=, ae=, out=);
proc sort data=proj.adaetab out=proj.adaetab1; by usubjid aeterm aesev; run;
proc sort data=proj.adaetab out=proj.adaetab2; by usubjid aeterm aeser; run;
proc sort data=proj.adaetab out=proj.adaetab3; by usubjid aeterm aerel; run;
proc sort data=proj.adaetab out=proj.adaetab4; by usubjid aeterm aeacn; run;
proc freq data= proj.&in;
where trtemfl='Y';
table &ae*trta/ list out= proj.&out;
run;
%mend aesev;
%aesev (in=adaetab1, ae= aesev, out=a);
%aesev (in=adaetab1, ae= aeser, out=aser);
%aesev (in=adaetab1, ae= aerel, out=arel);
%aesev (in=adaetab1, ae= aeacn, out=aacn);

proc sql; select count(distinct usubjid) into :ae from proj.adaetab where trtemfl="Y"; quit;
%macro char (dsn=, len=,ot=);
data proj.&ot;
length &len $50.;
set proj.&dsn;
count_P=put(count,8.)||"/"||"("||put((count/&ae*100),3.)||"%"||")";
run;
%mend char;
%char (dsn= a, len=aesev, ot=a1);
%char (dsn= aser, len=aeser, ot=aser1);
%char (dsn= arel,len=aerel,  ot=arel1);
%char (dsn= aacn,len=aeacn,  ot=aacn1);

proc sort data=proj.a1; by aesev; run;
proc sort data=proj.aser1; by aeser; run;
proc sort data=proj.arel1; by aerel; run;
proc sort data=proj.aacn1; by aeacn; run;

%macro transp (tran=, by=, trans=, x=, y=);
proc transpose data=proj.&tran 
               out=proj.&trans (rename=(&x= &y));
by &by;
id trta;
var count_P ;
run;
%mend transp;
%transp (tran= a1, by=aesev ,trans=a2, x= aesev, y= AE_RESULTS);
%transp (tran= aser1,by=aeser , trans=aser2, x=aeser, y= AE_RESULTS);
%transp (tran= arel1, by=aerel ,trans=arel2, x=aerel, y= AE_RESULTS);
%transp (tran= aacn1, by=aeacn ,trans=aacn2, x=aeacn, y=AE_RESULTS);

%macro name (nm=, title=, all=);
data proj.&nm;
length  AE_RESULTS $50.; format &all 50.;
AE_RESULTS="&title";
run;
%mend name;
%name (nm=sevnm, title=AESEVERITY, all=AE_RESULTS);
%name (nm=sernm, title=AESERIOUSNESS, all=AE_RESULTS);
%name (nm=relnm, title=CAUSALITY, all=AE_RESULTS);
%name (nm=acnnm, title=ACTION_TAKEN, all=AE_RESULTS);

data proj.aemerg (drop=_name_);
set proj.sevnm proj.a2 proj.sernm proj.aser2 proj.relnm proj.arel2 proj.acnnm proj.aacn2;
if A1 = "" then A1="0";
if A2 = "" then A2="0";
if OVERALL= "" then OVERALL="0";
A1 =strip(A1);
A2 =strip(A2);
OVERALL =strip(OVERALL);
if AE_RESULTS not in ("AESEVERITY","AESERIOUSNESS",
                      "CAUSALITY","ACTION_TAKEN")
then AE_RESULTS="  "||AE_RESULTS;

Stats=_name_;
if Stats="COUNT_P" then Stats="N";
run;

proc print data=proj.aemerg noobs;
  title1 justify=center height=17pt color=cx003366  "Table 14-3.3:" color=blue "ADVERSE EVENTS" ;
  title2 justify=center height=10pt color=red  "((SEVERITY, SERIOUSNESS, CAUSALITY, ACTION_TAKEN))";
  title3 justify=right height=10pt color=cx003366  "&sysdate9..";
  footnote "";
run;
