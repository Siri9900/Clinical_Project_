/*QS fig*/
proc sgpanel data=proj.adqst ;
panelby paramcd;
styleattrs datacontrastcolors=(navy gold); 
  series x=adt y=aval/ group=trta;
title color= green "fig: 14.4.4: POST-BASELINE values over time";
run;
proc sgpanel data=proj.adqst ;
panelby paramcd;
styleattrs datacontrastcolors=(navy gold); 
  series x=adt y=base/ group=trta;
title color=red "fig: 14.4.5: BASELINE values over time";
run;
