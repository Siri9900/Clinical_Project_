/*Figures*/
proc sgplot data=proj.adsl_final;
where saffl="Y";
vbar sex /  group=trta 
            groupdisplay=cluster
            datalabel
            stat=percent;
title "Figure 14-1.3";
title2 "Gender-wise Distribution by Treatment";
run;
proc sgpanel data=proj.adsl_final;
where saffl="Y";
panelby trta;
vbar sex / stat=percent datalabel categoryorder=respdesc;
title "Figure 14-1.3";
title2 "Gender Distribution by Treatment";
run;
/*category wise*/
data proj.dm_cat_demo;
set proj.adsl_final(where=(saffl="Y"));

length variable $10 value $40;

variable="SEX"; value=sex; output;
variable="RACE"; value=race; output;
variable="ETHNIC"; value=ethnic; output;
keep variable value trta;
run;

proc sgpanel data=proj.dm_cat_demo;
panelby variable / columns=3;

vbar value / group=trta
             stat=percent
             groupdisplay=cluster
             datalabel;

title "Categorical Demographics (Safety Population)";
run;
/*Age*/
proc sgplot data=proj.adsl_final;
where saffl="Y";
histogram age;
density age;
title "Age Distribution (Safety Population)";
run;
