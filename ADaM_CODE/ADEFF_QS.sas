proc copy inlib=psoriasi outlib=proj;
run;
/*ADEFF - QS*/
proc sort data=proj.adqs_final out=proj.adqs_pb; by studyid usubjid paramcd avisitn;run;
data proj.adeff1;
set proj.adQS_pb;
BY studyid usubjid; 
if adt >= trtsdt and trtsdt ne . ;
format adt yymmdd10.;
run;
proc sort data=proj.adeff1; by usubjid paramcd;run;

data proj.ADEFF_qsF;
set proj.adeff1;
by usubjid paramcd;
/*worst & best post_baseline*/
/*can also take mean/avg*/
retain worst_pb best_pb;
if first.paramcd then do;
   worst_pb=.;
   best_pb=.;
end;

if not missing(aval) then do;
   if missing(worst_pb) then worst_pb=aval;
   else worst_pb=max(worst_pb,aval);

   if missing(best_pb) then best_pb=aval;
   else best_pb=min(best_pb,aval);
end;
/*efficacy flag*/
if best_pb ne . and worst_pb ne . and base ne . then do;
 if best_pb < base and worst_pb <= base then eff_fl= "Y";
 else eff_fl="N";
end;
/*trt response %*/
if best_pb ne  . and base > 0 then do;
   resp= int((base-best_pb)/base*100);
end;
/*PSAI75 golden point*/
if upcase(paramcd)= "PASI" and best_pb ne  . and base > 0 then do;
   PASI75= int((base-best_pb)/base*100);
   if PASI75 >= 75 then PASI75FL= 'Y';
   else PASI75FL= 'N';
end;
if last.paramcd then output;
run;
proc sort data=proj.ADEFF_qsF; by usubjid paramcd avisitn;;run;
data proj.adeff_qsfinal1;
merge proj.adqs_pb(in=a) proj.adeff_qsf(in=b);
by usubjid paramcd avisitn;
if a;
run;
proc sort data=proj.adeff_qsfinal1 out=proj.adeff_qsfinal; by studyid usubjid qsseq;run;
/*proc freq data=proj.adeff_qsfinal;*/
/*table visit;*/
/*run;*/

proc sort data=proj.adlb_final out=proj.adlb_pb; by studyid usubjid paramcd avisitn;run;
