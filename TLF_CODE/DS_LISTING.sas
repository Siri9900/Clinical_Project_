/*Disposition Listing*/
ods listing close;
ods escapechar="~";
proc report data= proj.adsl_final nowd headline headskip spacing=2 
  style(report)=[frame=void rules=none]
  style(header)=[background=cx003366 foreground=white font_weight=bold]
  style(column)=[background=librgr foreground=black]
  style(summary)=[background=red foreground=black font_weight=bold];
  columns  usubjid eostt eosdt trta;
  define usubjid / display "USUBJID" order=internal;
  define eostt / display "EOSTT" ;
  define eosdt / display "EOSDT" ;
  define trta / display "TREATMENT ~{super &overc}" ;
  
compute eostt;
    if upcase(eostt) in (
        "SCREEN FAILURE",
        "DEATH",
        "LOST TO FOLLOW-UP",
        "RANDOMIZED BUT NOT TREATED"
    )
    then call define (_row_,'style',"STYLE=[foreground=red]");
endcomp;

title1 justify=center height=17pt color=cx003366  "Listing 14-2.2:" color=Green "Subject Disposition";
title2 justify=center height=10pt color=cx003366 "Subjects:%sysevalf(%sysfunc(compress(&Subj)) - (
    %sysfunc(compress(&Subj_SF)) + 
    %sysfunc(compress(&Subj_D)) + 
    %sysfunc(compress(&Subj_RNT)) + 
    %sysfunc(compress(&Subj_LTF))
)) completed study";      /*or*/

/*%let completed = %eval(&Subj - (&Subj_SF + &Subj_D + &Subj_RNT + &Subj_LTF));
%put &completed;*/

/*or*/

/*&Subj_Comp*/
title3 justify=right height=10pt color=cx003366  "&sysdate9..";
run;
