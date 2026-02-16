proc copy inlib=psoriasi outlib=proj;
run;
/*relation between CM,AE*/
/*suppcm*/
data proj.cmsupp;
set proj.cm1;
studyid=strip(studyid);
/*usubjid=strip(usubjid);*/
domain= strip(domain);
idvar="cmseq";
idvarval = strip(put(cmseq, best.));
cmrelid= strip(subjid)||"-"||substr(cmtrt,1,2);
run;
proc sort data=proj.cmsupp ; by subjid idvarval  ; run;


/*suppae*/
data proj.aesupp;
set proj.ae1;
studyid=strip(studyid);
/*usubjid=strip(usubjid);*/
domain= strip(domain);
idvar="aeseq";
idvarval = strip(put(aeseq, best.));
aerelid= strip(subjid)||"-"||substr(CMTRT_LINKED,1,2);
run;
proc sort data=proj.aesupp ; by subjid idvarval ; run;

proc sql;
  create table proj.link_base as
  select
      a.subjid,
      a.idvarval as cmseq,
      a.cmtrt,
	  a.cmrelid,
      b.idvarval as aeseq,
      b.cmtrt_linked,
	  b.aerelid
  from proj.cmsupp as a
       inner join proj.aesupp as b
on a.subjid = b.subjid
and STRIP(UPCASE(A.CMTRT)) = STRIP(UPCASE(B.CMTRT_LINKED))
  where a.idvar = 'cmseq'
    and b.idvar = 'aeseq';
quit;

proc sql;
  create table proj.relrec as

  /* CM rows */
  select
      subjid,
      'CM'    as rdomain length=2,
      'cmseq' as idvar length=5,
      cmseq   as idvarval,
      cmtrt as trt,
	  cmrelid as relid,
	  'One' as reltype
/*      cmtrt_linked*/
  from proj.link_base

  union all

  /* AE rows */
  select
      subjid,
      'AE'    as rdomain length=2,
      'aeseq' as idvar length=5,
      aeseq   as idvarval,
	  cmtrt_linked as trt,
	  aerelid as relid,
	  'ONE' as reltype

/*      ''      as cmtrt,*/
/*      cmtrt_linked*/
  from proj.link_base;
quit;

/*data proj.rel;*/
/*merge proj.cmsupp (in=a keep= subjid domain cmtrt cmseq idvar idvarval cmrelid)*/
/*      proj.aesupp(in=b keep= subjid domain aeseq idvar idvarval CMTRT_LINKED aerelid) ;*/
/*by subjid  ;*/
/*if a and b;*/
/*run;*/
/*data proj.rel1;*/
/*set proj.rel;*/
/*where cmrelid=aerelid;*/
/*run;*/
/**/
/*data proj.rel;*/
/*set proj.cmsupp (in=a keep= subjid domain cmtrt cmseq idvar idvarval cmrelid)*/
/*      proj.aesupp(in=b keep= subjid domain aeseq idvar idvarval CMTRT_LINKED aerelid) ;*/
/*by subjid  ;*/
/*run;*/
