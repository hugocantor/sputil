**FREE

ctl-opt option(*srcstmt:*nodebugio)
        srtseq(*langidshr)
        datfmt(*iso)
        timfmt(*iso)
        nomain;


      /copy *libl/source,sputil_h
// ------------------------------------------------------------------
// Procedure: sputilm1_logError
// Purpose:
// Log an error entry using call stack + job log info
// Requires table ERROR_LOG with columns matching the INSERT below.
// Uses QSYS2.CALL_STACK_INFO, QSYS2.JOB_INFO, QSYS2.JOBLOG_INFO.
// Optional parameters passed by value
// pSqlState and pSqlCode default to success if not passed.
dcl-proc sputilm1_logError export;
  dcl-pi *n;
    pSqlState char(5)   const options(*nopass:*omit);
    pSqlCode   int(10)  const options(*nopass:*omit);
    pSqlErrorMsg like(sputil_sqlErrorMsg) const options(*nopass:*omit);

  end-pi;

  dcl-s sqlState char(5) inz('00000');
  dcl-s sqlCode  int(10) inz(0);

  dcl-s programName    varchar(128) inz('');
  dcl-s procedureName  varchar(256) inz('');
  dcl-s sourceLine     varchar(20);

  dcl-s jobName        varchar(10)  inz('');
  dcl-s jobUser        varchar(10)  inz('');
  dcl-s jobNumber      char(6)      inz('');
  dcl-s jobCurrentUser varchar(10)  inz('');

  dcl-s messageId      varchar(7)   inz('');
  dcl-s severity       int(10)      inz(0);
  dcl-s description    like(sputil_sqlErrorMsg) inz('');
  dcl-c previousStackEntry 1;


  dcl-ds sputilds_stackEntry likeds(sputilds_stackEntry_t);

  exec sql
    set option COMMIT = *NONE,CLOSQLCSR = *ENDMOD, DATFMT = *ISO,
        TIMFMT = *ISO, DATSEP = *DASH,TIMSEP = *PERIOD,
        SRTSEQ = *LANGIDSHR, SQLPATH = *LIBL, NAMING = *SYS;


  if %parms >= %parmnum(pSqlState) and %addr(pSqlState) <> *null;
    sqlState = pSqlState;
  endif;
  if %parms >= %parmnum(pSqlCode) and %addr(pSqlCode) <> *null;
    sqlCode = pSqlCode;
  endif;

  sputilm2_getCallStackEntry(sputilds_stackEntry
                             : previousStackEntry);
  programName = sputilds_stackEntry.pgm;
  procedureName = sputilds_stackEntry.procedureName;
  sourceLine = sputilds_stackEntry.line;

  // Job info for current job
  exec sql
    select job_name_short,
           job_user,
           job_number,
           AUTHORIZATION_NAME
      into :jobName,
           :jobUser,
           :jobNumber,
           :jobCurrentUser
      from TABLE(QSYS2.ACTIVE_JOB_INFO(
            JOB_NAME_FILTER => '*')) AS X
     fetch first 1 row only;

  // Most recent job log message (use as description)
  if %parms >= %parmnum(pSqlErrorMsg) and %addr(pSqlErrorMsg) <> *null;
    description = pSqlErrorMsg;
  else;
   exec sql
      select message_id,
            severity,
            cast(coalesce(message_text, '') as varchar(5000) ccsid 37)
       into :messageId,
            :severity,
            :description
       from TABLE(QSYS2.JOBLOG_INFO('*')) AS X
       where from_procedure = :procedureName
        and from_program = :programName
      order by message_timestamp desc
      fetch first 1 row only;
  endif;


  // Insert into error log
  exec sql
    insert into errlg
      (program_name,
       procedure_name,
       description,
       sqlstate,
       sqlcode,
       message_id,
       severity,
       job_name,
       job_user,
       job_number,
       job_current_user,
       source_line)
    values
      (:programName,
       :procedureName,
       :description,
       :sqlState,
       :sqlCode,
       :messageId,
       :severity,
       :jobName,
       :jobUser,
       :jobNumber,
       :jobCurrentUser,
       :sourceLine);

end-proc;
// ------------------------------------------------------------------
