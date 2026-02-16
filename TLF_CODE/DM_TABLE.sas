/*TLF'S*/
/* Demographic Table 14-1.1: Demographic Characteristics - Safety Population */
/* Create base dataset with safety population only */
data proj.adsl_safety;
length trta $10;
  set proj.adsl_final;
  where saffl = "Y";/* Safety population only */
  output;
  trta="overall";
  output;
run;

/* 1. Age Summary (Continuous) */
proc means data=proj.adsl_safety nway;
  class trta;
  var age;
  output out=proj.age_stats n= N min= MIN max= MAX median=MEDIAN std= STD;
run;
data proj.age_table;
  set proj.age_stats;
N_=put(N,3.);
MEDIAN_SD=put(median,3.2)||"("||put(std,3.2)||")";
MIN_=put(min, 3.);
MAX_=put(max,3.);
run;
proc transpose data=proj.age_table out=proj.trans_stat;
var N_ MEDIAN_SD MIN_ MAX_;
id trta;
run;
data proj.age1;
length stats $25;
  set proj.trans_stat;
if _name_= "N_" then stats="N"; 
else if _name_= "MEDIAN_SD" then stats= "Med(std)";
else if _name_= "MIN_" then stats= "MIN";
else if _name_= "MAX_" then stats= "MAX";
else stats="";
run;
data proj.age2;
length stats $25 ;
stats="AGE (Years)";
run;
data proj.agef;
length  A1 $15 A2 $15 overall $15 ;
set proj.age2 proj.age1 ;
if _N_ > 1 then stats="  "||stats;
order=1;
run;
proc sort data= proj.agef; by order; run;


/* 3. Sex */
proc freq data=proj.adsl_safety ;
  tables sex*trta / out=proj.gen_freq outpct;
run;
proc sql; select count(distinct(usubjid)) into :a1c from proj.adsl_safety  where trta= "A1"; quit;
proc sql; select count(distinct(usubjid)) into :a2c from proj.adsl_safety  where trta= "A2"; quit;
proc sql; select count(distinct(usubjid)) into :overc from proj.adsl_safety  where trta= "overall"; quit;
data proj.gen_table;
length values $15;
set proj.gen_freq;
if trta="A1" then denom=&a1c;
else if trta="A2" then denom=&a2c;
else if trta="overall" then denom=&overc;
/*count1=put(count,3.);*/
/*pc=put(count/denom*100, 6.2);*/
values=put(count,3.)||"("||put(count/denom*100, 6.2)||"%"||")";
run;
proc sort data= proj.gen_table; by sex; run;
proc transpose data=proj.gen_table out=proj.gen_stats ;
by sex;
var values;
id trta;
run;
data proj.gen1;
length stats $25 ;
set proj.gen_stats;
if _name_="VALUES" then stats="n(%)";
if sex="M" then order=2;
else order=3;
if sex="F" then stats=sex||"  "||stats;
else if sex="M" then stats=sex||"  "||stats;
else _name_="";
run;
data proj.gen2;
length stats $25 ;
stats="GENDER";
order=2;
run;
data proj.genf;
length  A1 $15 A2 $15 overall $15 ;
set proj.gen2 proj.gen1 ;
if _N_ > 1 then stats="  "||stats;
run;
proc sort data= proj.genf; by order; run;

/* 4. Race */
proc freq data=proj.adsl_safety ;
  tables race*trta / out=proj.race_freq outpct;
run;
data proj.race_table;
set proj.race_freq;
if trta="A1" then denom=&a1c;
else if trta="A2" then denom=&a2c;
else if trta="overall" then denom=&overc;
values=put(count,3.)||"("||put(count/denom*100, 6.2)||"%"||")";
run;
proc sort data= proj.race_table; by race; run;
proc transpose data=proj.race_table out=proj.race_stats ;
by race;
var values;
id trta;
run;
data proj.race1;
length stats $25 ;
set proj.race_stats;
if race="ASIAN" then stats=strip(race)||"  "||"n,(%)";
Else stats="";
run;
data proj.race2;
length stats $25 ;
stats="RACE";
run;
data proj.racef;
length A1 $15 A2 $15 overall $15 ;
set proj.race2 proj.race1 ;
if _N_ > 1 then stats="  "||stats;
order=4;
run;
proc sort data= proj.racef; by order; run;


/* 5. Ethnicity */
proc freq data=proj.adsl_safety ;
  tables ethnic*trta / out=proj.ethnic_freq outpct;
run;
data proj.ethnic_table;
set proj.ethnic_freq;
if trta="A1" then denom=&a1c;
else if trta="A2" then denom=&a2c;
else if trta="overall" then denom=&overc;
values=put(count,3.)||"("||put(count/denom*100, 6.2)||"%"||")";
run;
proc sort data= proj.ethnic_table; by ethnic; run;
proc transpose data=proj.ethnic_table out=proj.ethnic_stats ;
by ethnic;
var values;
id trta;
run;
data proj.ethnic1;
length stats $25 ;
set proj.ethnic_stats;
if _name_="VALUES" then stats="n,(%)";
if ethnic="NOT HISPANIC" then stats=strip(ethnic)||"  "||stats;
Else stats="";
run;
data proj.ethnic2;
length stats $25 ;
stats="ETHNIC";
run;
data proj.ethnicf;
length  A1 $15 A2 $15 overall $15 ;
set proj.ethnic2 proj.ethnic1 ;
if _N_ > 1 then stats="  "||stats;
order=5;
run;
proc sort data= proj.ethnicf; by order; run;

/* 6. Combine all tables */
data proj.demo_table;  
  set proj.agef (in=a)
      proj.genf (in=b)
      proj.racef (in=c)
      proj.ethnicf (in=d);
drop _name_ ;
/*by order; */
/*if stats="  n,(%)" then stats= "  n,(%)";*/
run;
proc sql; select count(distinct(usubjid)) into : Subj from proj.adsl_final; quit;
proc sql; select count(distinct(usubjid)) into : Subj_Saf from proj.adsl_safety; quit;
proc sql; select count(distinct(usubjid)) into : Subj_SF from proj.adsl_final where eostt="Screen Failure"; quit;
proc sql; select count(distinct(usubjid)) into : Subj_D from proj.adsl_final where eostt="Death"; quit;
proc sql; select count(distinct(usubjid)) into : Subj_RNT from proj.adsl_final where eostt="Randomized but Not Treated"; quit;
proc sql; select count(distinct(usubjid)) into : Subj_LTF from proj.adsl_final where eostt="Lost to Follow-up"; quit;
proc sql; select count(distinct(usubjid)) into : Subj_Comp from proj.adsl_final where eostt="Completed Study"; quit;
proc sql; select count(distinct(usubjid)) into : Subj_RND from proj.adsl_final where RANDFL="Y"; quit;


/* Create final table with PROC REPORT */
ods pdf file="C:\Users\admin\Desktop\Psoriasis_demog_table.pdf";
ods escapechar="~";
proc report data=proj.demo_table nowd headline headskip spacing=2 
  style(report)=[frame=void rules=none]
  style(header)=[background=cx003366 foreground=white font_weight=bold]
  style(column)=[background=white foreground=black]
  style(summary)=[background=red foreground=black font_weight=bold];
  columns  stats A1  A2 overall  order;
  define order / display noprint;
  define stats / display  flow;
  define A1 / display "Treatment A ~{super &a1c}" "(A1 drug)" flow;
  define A2 / display "Treatment B ~{super &a2c}"  "(A2 drug)" flow;
  define overall / display "OVERALL ~{super &overc}" flow;
  
  compute after;
    line @1 120*'-';
  endcomp;
  
  compute after _page_;
    line @1 " ";
    line @2 "[ACTUAL TREATMENT A NAME is A1]";
    line @2 "[ACTUAL TREATMENT B NAME is A2]";
	line @10 "med(std)=MEDIAN(STD)"  "n,(%)= number of subjects(percentage)";
   endcomp;
title1 justify=center height=17pt color=cx003366 "Table 14-1.1";
title2 justify=center height=0.5in color=black "Demographic Characteristics";
title3 justify=center height=15pt color=gray "(Safety Population)";

footnote1 justify=center height=7pt color=cx003366 "Total Number of Subjects: &Subj";
footnote2 " ";
footnote3 justify=center height=10pt color=cx003366 "Subjects with SAFFL=Y:" height=10pt color=green"&Subj_Saf";
footnote4 " ";
footnote5 justify=center height=7pt color=cx003366 "Number of Subjects Screen failure: &Subj_SF";
footnote6 justify=center height=7pt color=cx003366 "Number of Subjects Randomised but treated: &Subj_RNT";
footnote7 justify=center height=7pt color=cx003366 "Number of Subjects Died:" height=7pt color=red " &Subj_D"; 
run;
ods pdf close;
