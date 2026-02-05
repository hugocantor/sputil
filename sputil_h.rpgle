**FREE

// Copy book for SPUTILM1
// Prototype for error logging procedure
//

dcl-s sputil_sqlErrorMsg varchar(5000) template;

dcl-pr sputilm1_logError extproc('SPUTILM1_LOGERROR');
  pSqlState char(5)  const options(*nopass:*omit);
  pSqlCode  int(10) const options(*nopass:*omit);
  pSqlErrorMsg like(sputil_sqlErrorMsg) const options(*nopass:*omit);
end-pr;


// Copy book for SPUTILM2

dcl-ds sputilds_stackEntry_t qualified template;
  pgm varchar(10);
  pgmlib varchar(10);
  module varchar(10);
  modulelib varchar(10);
  procedureName varchar(100);
  ControlBoundryActive ind;
  ActGrpName varchar(10);
  requestLevel int(10);
  line varchar(10);
end-ds;

dcl-ds sputilds_extraStackInfo_t qualified template;
  threadId char(8) pos(1);
  *n char(992);
end-ds;

// ********************************************************
//  PROTOTYPES
// ********************************************************

//----------------------------------------------------------------
//  gensrvm1_writeJobLog : write to job log
//
//   Parm            : Pupose
//   ---------------   -----------------
//   pmsg            : message to write
//   pEscape         : *on = Escape message, *off = information message
//   pCallStackCount :  optional. The call stack number to which to
//                      send the messaeg
//
//----------------------------------------------------------------
dcl-pr sputilm2_writeJobLog;
  pmsg varchar(32767) const options(*varsize);
  pEscape ind const;
  pCallStackCount int(10) const options(*nopass:*omit);
end-pr;

//-----------------------------------------------------------------
dcl-pr sputilm2_getCallStackEntry ind;
  pStackEntry likeds(sputilds_stackEntry_t);
  pWalkUpStack int(10) const options(*nopass:*omit);
  pExtraStackInfo likeds(sputilds_extraStackInfo_t)
    options(*nopass:*omit);
end-pr;

//-------------------------------------------------------------------
dcl-pr sputilm2_loadCallStack ind;
end-pr;

//-------------------------------------------------------------------
dcl-pr sputilm2_fetchNextStackEntry ind;
end-pr;

//-------------------------------------------------------------------
dcl-pr sputilm2_getStackValue varchar(100) rtnparm;
  fieldname varchar(50) value options(*trim);
end-pr;

//-------------------------------------------------------------------
dcl-pr sputilm2_unloadCallStack;
end-pr;

//-----------------------------------------------------------------
