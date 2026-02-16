/*AE Listing*/
proc sql; select count(distinct usubjid) into :trtemfl from proj.adae_final where trtemfl="Y"; quit;
ods escapechar="~";
proc report data= proj.adae_final
 nowd headline headskip spacing=2 
  style(report)=[frame=void rules=none]
  style(header)=[background=cx003366 foreground=white font_weight=bold]
  style(column)=[background=librgr foreground=black]
  style(summary)=[background=red foreground=black font_weight=bold];
where trtemfl="Y";
  columns  usubjid aesev aeser aebodysys aedecode astdt aendt trta;
  define usubjid / display "USUBJID" ;
  define aesev / display "AESEV" ;
  define aeser / display "AESER" ;
  define aebodysys / display "AEBODYSYS" ;
  define aedecode / display "AEDECODE" ;
  define astdt / display "AESTDT" ;
  define aendt / display "AEENDT" ;
  define trta / display "TREATMENT ~{super &overc}" ;
  
compute aeser;
    if aeser='Y'
then call define (_row_,'style',"STYLE=[foreground=red]");
endcomp;

title1 justify=center height=17pt color=cx003366  "Listing 14-2.2:" color=Green "AE Listing";
title2 justify=center height=10pt color=cx003366 "Subjects (TRTEMFL: &trtemfl)";
title3 justify=right height=10pt color=cx003366  "&sysdate9..";
run;
