/*Time-to-event*/
/*AE Onset-time*/
/* Step 1: Create time-to-first AE dataset */

proc sql;
create table proj.time_to_ae_event as
select 
    usubjid,
    trta,
    min(aestdy) as time format=8.,
    1 as event
from proj.adae_final
where trtemfl='Y'
group by usubjid, trta;
quit;

proc sql;
create table proj.time_cens as
select 
    a.usubjid,
    a.trta,
    (a.trtedt - a.trtsdt + 1) as time format=8.,
    0 as event
from proj.adsl_final as a
left join proj.time_to_ae_event as b
on a.usubjid = b.usubjid
where b.usubjid is null
      and a.trtedt ne .
      and a.trtsdt ne .;
quit;
data proj.time_1;
set proj.time_to_ae_event
    proj.time_cens;
run;
proc lifetest data=proj.time_1 ;
time time*event(0);
strata trta;
run;
proc lifetest data=proj.time_1;
   time time * event(1); 
   strata trta; /* This line triggers the log-rank test */
run;

/**/
proc sgplot data=proj.time_to_ae1 noautolegend;
styleattrs datacontrastcolors=(firebrick navy gold); 
  vbar trta / response=event group= trta 
                     stat=percent   datalabel datalabelattrs=(size=10pt)
                      barwidth=0.2 fillattrs=(color=lightblue);
  yaxis label='Total Events % by Treatment';
  title "Total AE by treatment (where trtemfl="Y")";
/*  keylegend / noborder;  *//*to remove default border for legend*/
run;

proc sgplot data=proj.time_to_ae1 ;
        styleattrs datacontrastcolors=(black red); 
scatter x=time_to_ae y=usubjid  /group= trta 
        markerattrs=(size=10 symbol=diamondfilled)
        datalabel=time_to_ae
        datalabelposition=top
        datalabelattrs=(size=8);
        xaxis min=0 max=50 minor minorcount=5 grid ; 
        yaxis label='Event onset time for each subject by trt';
title "AE onset timeline";
/*  keylegend / noborder;  *//*to remove default border for legend*/
run;
