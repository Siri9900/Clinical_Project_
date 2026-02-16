/*Demographics Listing*/
ods escapechar="~";

proc report data=proj.adsl_final nowd headline headskip spacing=2 
  style(report)=[frame=void rules=none]
  style(header)=[background=cx003366 foreground=white font_weight=bold]
  style(column)=[background=White foreground=black]
  style(summary)=[background=red foreground=black font_weight=bold];
where saffl="Y";
  columns  studyid usubjid siteid age sex  race  ethnic  trta trtsdt trtedt eostt;
  define studyid / display "Study ID";
  define usubjid / display "USUBJID";
  define siteid / display "SITE";
  define age / display "AGE" flow;
  define sex / display "SEX" ;
  define race / display  "RACE ";
  define ethnic / display  "ETHNIC ";
  define trtsdt / display "Treatment Start";
  define trtedt / display "Treatment End";
  define trta / display "Actual Treatment";
  define eostt / display "End of Study Status";  
compute before _page_;
    line @10 100*'-';
  endcomp;
  compute after;
    line @1 120*'-';
  endcomp;
title1 justify=center height=17pt color=cx003366 "Listing 14-1.2";
title2 justify=center height=0.5in color=black "Demographic and Baseline Characteristics Listing";
title3 justify=center height=15pt color=green "(Safety Population: &overc)";
footnote "";
run;  
