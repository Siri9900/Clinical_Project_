/*Disposition Figure*/

proc sgplot data=proj.adsl_final;
/* highlow y=variable_on_side low=start_date high=end_date */
    highlow y=usubjid 
            low=rficdt high=eosdt / 
            group=trta 
            highcap=filledarrow /* Adds an arrow to the end */
            type=bar            /* Makes the connection look like a bar */
            barwidth=0.8;
            
    yaxis type=discrete;
    xaxis label="Study Timeline" interval=month;
	keylegend / location=outside position=bottomleft;
title1 justify=center height=17pt color=cx003366  "Fig 14-2.3:" color=Green "Subject level Study Duration by Treatment";
run;

/*Study Discontinuation Reasons*/
proc sgplot data=proj.adsl_final;
where strip(upcase(eostt)) in (
        "SCREEN FAILURE",
        "DEATH",
        "LOST TO FOLLOW-UP",
        "RANDOMIZED BUT NOT TREATED"
    );

vbar eostt /stat=percent
/*              groupdisplay=cluster*/
                datalabel
                barwidth=0.5;
xaxis discreteorder=data  fitpolicy=none;
title "Study Discontinuation Reasons";
run;
/*Study Discontinuation Reasons by treatment*/
proc sgplot data=proj.adsl_final;
where strip(upcase(eostt)) in (
        "SCREEN FAILURE",
        "DEATH",
        "LOST TO FOLLOW-UP",
        "RANDOMIZED BUT NOT TREATED"
    );

vbar eostt / group=trta stat=percent
                datalabel
                barwidth=0.5;
title "Study Discontinuation Reasons by Treatment";
run;
/*Time to Discontinuation Distribution*/
data proj.ds_duration;
set proj.adsl_final;
time_on_study = eosdt - rficdt;
keep time_on_study trta;
run;
proc sgplot data=proj.ds_duration;
histogram time_on_study;
density time_on_study;
title "Time to Discontinuation Distribution";
run;
/*Boxplot of Study Duration by Treatment*/
proc sgplot data=proj.ds_duration;
vbox time_on_study / category=trta;
title "Study Duration by Treatment";
run;



/*Disposition Flow*/
data proj.dispo_flow;
length text $200 y 8;
text = "Screened (N=&Subj)"; y=8; output;
text = "Randomized (N=&Subj_RND)"; y=7; output;
text = "Safety Population (N=&Subj_Saf)"; y=6; output;
text = "Completed (N=&Subj_Comp)"; y=5; output;
text = "Screen Failure (N=&Subj_SF)"; y=4; output;
text = "Randomized not treated (N=&Subj_RNT)"; y=3; output;
text = "Lost to followup (N=&Subj_LTF)"; y=2; output;
text = "Death (N=&Subj_D)"; y=1; output;
run;
proc sgplot data=proj.dispo_flow noautolegend;
scatter x=y y=y / markerchar=text;
yaxis display=none;
xaxis display=none;
title "Fig: 1:Subject Disposition Flow";
run;

data proj.dispo_flow1;
length text $200 y 8;
text = "Screened"; z=&Subj;y=8; output;
text = "Randomized";z=&Subj_RND; y=7; output;
text = "Safety Population"; z=&Subj_Saf; y=6; output;
text = "Completed";z=&Subj_Comp; y=5; output;
text = "Screen Failure"; z=&Subj_SF; y=4; output;
text = "Randomized not treated"; z=&Subj_RNT; y=3; output;
text = "Lost to followup"; z=&Subj_LTF; y=2; output;
text = "Death"; z=&Subj_D; y=1; output;
run;
proc sgplot data=proj.dispo_flow1 noautolegend;
scatter x=text y=z / markerattrs=(symbol=diamond size=10px color=blue);
xaxis label="disp events";
yaxis label="subjects" values=(1 to 25 by 1);
title "Fig: 2 :Subject Disposition Flow";
run;
