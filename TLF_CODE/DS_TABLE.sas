/*Disposition Table*/
/* Create base dataset with safety population only */
/*template*/
data proj.shell_dispo;
length roword 8 POPULATION $30 ;
roword=1; POPULATION="Total_enrolled_subj"; output;
roword=2; POPULATION="Completed";output;
roword=3; POPULATION="  Completed_Study"; output;
roword=4; POPULATION="Not_completed"; output;
roword=5; POPULATION="  Screen_Failure_Subj"; output;
roword=6; POPULATION="  Randomized_Not_Treated_Subj"; output;
roword=7; POPULATION="  Death_"; output;
roword=8; POPULATION="  Lost_to_Followup_Subj"; output;
run;

data proj.adsl_safety1;
length trta $10;
  set proj.adsl_final;
  output;
  trta="overall";
  output;
run;

/* Create disposition table with counts by treatment */
proc sql;
/* Get counts by treatment */
  create table proj.disp_count as
  select 
    trta,
	"  " as Completed,
	"  " as Not_completed,
    count(distinct case when eostt="Screen Failure" then usubjid end) as Screen_Failure,
    count(distinct case when eostt="Randomized but Not Treated" then usubjid end) as Randomized_Not_Treated,
    count(distinct case when eostt="Completed Study" then usubjid end) as Comp,
    count(distinct case when eostt="Death" then usubjid end) as Death,
    count(distinct case when eostt="Lost to Follow-up" then usubjid end) as Lost_to_Followup,
    count(distinct usubjid) as Total_subj_enrolled
from proj.adsl_safety1
  group by trta;
  quit;

/* Format as XX(XX%) */
data proj.disp1;
  set proj.disp_count ;
  length Completed $50 Completed_Study $50 Not_completed $50 Screen_Failure_Subj $50 Randomized_Not_Treated_Subj $50
       Completed_Study $50 Death_ $50 Lost_to_Followup_Subj $50 Total_enrolled_subj $50;
  completed=completed;
  completed=Not_completed;   
  Screen_Failure_Subj = put(Screen_Failure, 3.)||'('||strip(
                           put(Screen_Failure/Total_subj_enrolled*100, 8.1))||'%)';
						     
  Randomized_Not_Treated_Subj = put(Randomized_Not_Treated, 3.)||'('||strip(
                           put(Randomized_Not_Treated/Total_subj_enrolled*100, 8.1))||'%)';
						 
  Completed_Study = put(Comp, 3.)||'('||strip(
                           put(Comp/Total_subj_enrolled*100, 8.1))||'%)';
						  
  Death_ = put(Death, 3.)||'('||strip(
                           put(Death/Total_subj_enrolled*100, 8.1))||'%)';
						
  Lost_to_Followup_Subj = put(Lost_to_Followup, 3.)||'('||strip(
                           put(Lost_to_Followup/Total_subj_enrolled*100, 8.1))||'%)';
						   
  Total_enrolled_subj = put(Total_subj_enrolled, 3.)||'('||"100"||"%"||")";
  
  
  keep trta Not_completed Completed Screen_Failure_Subj Randomized_Not_Treated_Subj 
       Completed_Study Death_ Lost_to_Followup_Subj Total_enrolled_subj;
run;

/* Transpose for table format */
proc transpose data=proj.disp1 out=proj.disp2 (rename=(_name_=POPULATION));
  id trta;
  var Not_completed Completed Screen_Failure_Subj Randomized_Not_Treated_Subj 
       Completed_Study Death_ Lost_to_Followup_Subj Total_enrolled_subj;
run;

/*merge template shell and final ds*/
proc sql;
create table proj.disp_ready as
select a.roword,
       a.population,
       b.A1      as A1,
       b.A2      as A2,
       b.OVERALL as OVERALL
from proj.shell_dispo a
left join proj.disp2 b
on strip(upcase(a.population)) = strip(upcase(b.population))
order by roword;
quit;

proc print data=proj.disp_ready noobs;
  var POPULATION A1 A2 OVERALL;
  title1 justify=center height=17pt color=cx003366  "Table 14-2.1:" color=Green "Subject Disposition";
  title2 justify=right height=10pt color=cx003366  "&sysdate9..";
  footnote "";
run;

ods escapechar="~";
proc report data= proj.disp_ready nowd headline headskip spacing=2 
  style(report)=[frame=void rules=none]
  style(header)=[background=cx003366 foreground=white font_weight=bold]
  style(column)=[background=librgr foreground=black]
  style(summary)=[background=red foreground=black font_weight=bold];
  columns  POPULATION A1 A2 OVERALL;
  define POPULATION / display "POPULATION" ;
  define A1 / display "Treatment A ~{super &a1c}" "(A1 drug)" flow;
  define A2 / display "Treatment B ~{super &a2c}"  "(A2 drug)" flow;
  define overall / display "OVERALL ~{super &overc}" flow;
  
compute POPULATION;
    if upcase(POPULATION)='TOTAL_ENROLLED_SUBJ'
then call define (_row_,'style',"STYLE=[BACKGROUND=white foreground=green]");
    else if strip(upcase(POPULATION))='DEATH_'
then call define (_row_,'style',"STYLE=[BACKGROUND=white foreground=red]");
    else call define (_col_,'style',"STYLE=[BACKGROUND=white]");
endcomp;
title1 justify=center height=17pt color=cx003366  "Table 14-2.1:" color=Green "Subject Disposition";
run;
