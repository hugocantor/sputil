**FREE

// -----------------------------------------------------------
//  SPUTILM2 : Call stack Procedures
//
// -----------------------------------------------------------

ctl-opt nomain;
ctl-opt option(*srcstmt);
ctl-opt thread(*concurrent);
ctl-opt srtseq(*langidshr);
ctl-opt altseq(*ext);

/define SPUTIL
/copy *libl/source,sputil_h

dcl-s buffer_t char(16773104) template;

dcl-ds jobidInfo_t qualified template;
  jobname char(10) inz('*');
  user char(10);
  job# char(6);
  jobIdentifier char(16);
  *n char(2) inz(*allx'00');
  threadIndicator int(10) inz(1);
  threadIdentifier char(8) inz(*allx'00');
end-ds;

dcl-ds apierror_t qualified template;
  bytesp int(10) inz(%size(apierror_t));
  bytesa int(10) inz(0);
  exception char(7);
  *n char(1);
  data char(50);
end-ds;

// QWVRCSTK : Retrieve Call Stack API
dcl-pr QWVRCSTK extpgm('QWVRCSTK');
  recv like(buffer_t) options(*varsize);
  recvlen int(10) const;
  format char(8) const;
  jobidInfo likeds(jobidInfo_t);
  jobIdFormat char(8) const;
  error likeds(apierror_t);
end-pr;

dcl-pr memset pointer extproc('__memset');
  ptr pointer value;
  value int(10) value;
  size uns(10) value;
end-pr;

dcl-ds header_t qualified template;
  bytesr int(10);
  bytesa int(10);
  threadStackEntries int(10);
  stackEntryOffset int(10);
  numStackEntries int(10);
  threadIdentifier char(8);
  infoStatus char(1);
end-ds;

dcl-ds callStack_t qualified template;
  entryLen int(10);
  stmtIdentifiersDisp int(10);
  numStmtIdentifiers int(10);
  procNameDisp int(10);
  procNameLen int(10);
  requestLevel int(10);
  pgmName char(10);
  pgmLib char(10);
  *n int(10);
  moduleName char(10);
  moduleLib char(10);
  controlBndActive char(1);
  *n char(3);
  ActGrp# uns(10);
  ActGrpName char(10);
end-ds;

dcl-ds header likeds(header_t) based(stackBufferp);
dcl-ds stack likeds(callStack_t) based(stackp);
dcl-s stackbuffer like(buffer_t) based(stackbufferp);
dcl-s stackBufferp pointer;
dcl-s stackEntriesPos int(10);

dcl-ds msgfile_t template qualified;
  file char(10) inz('QCPFMSG');
  lib char(10) inz('*LIBL');
end-ds;

dcl-pr SendPgmMessage extpgm('QMHSNDPM');
  msgid          char(7) const;
  msgFile        likeds(msgfile_t);
  msgtxt         char(32767)   const options(*varsize);
  msgtxtLen      int(10) const;
  msgType        char(10)const;
  callStack      char(10) const;
  callStackCount int(10) const;
  msgKey   char(4);
  error  likeds(apierror_t);
 end-pr;

// -----------------------------------------------------------
dcl-proc sputilm2_getCallStackEntry export;
  dcl-pi *n ind;
    pStackEntry likeds(sputilds_stackEntry_t);
    pWalkUpStack int(10) const options(*nopass:*omit);
    pExtraStackInfo likeds(sputilds_extraStackInfo_t)
      options(*nopass:*omit);
  end-pi;

  dcl-ds jobidInfo likeds(jobidInfo_t) inz(*likeds);
  dcl-ds apierror likeds(apierror_t) inz(*likeds);
  dcl-s bufferp pointer;
  dcl-s buffer like(buffer_t) based(bufferp);
  dcl-ds header likeds(header_t) based(bufferp);
  dcl-ds callStack likeds(callStack_t) based(callStackp);
  dcl-s i int(10);
  dcl-s walkUpCallStack int(10) inz(0);
  dcl-s rtnval ind;
  dcl-s procname char(100) based(procnamep);
  dcl-s statementIdentifier char(10) based(statementIdentifierp);

  bufferp = %alloc(%size(stackbuffer));
  buffer = *allx'00';
  QWVRCSTK(buffer
          :%size(buffer)
          :'CSTK0100'
          :jobidInfo
          :'JIDF0100'
          :apierror
          );

  if apierror.bytesa > 0; // error occurred
    sputilm2_writeJobLog('ERROR calling QWVRCSTK "Retrieve Call Stack ' +
                         ' API". Exception = ' + apierror.exception
                        :*on
                        );
    rtnval = *off;
  else; // No error calling QWVRCSTK

    // -------------------------------------------
    //  Calculate how many entries up the call stack
    //   to walk up. At least one because we want to
    //   this procedure.
    // -------------------------------------------

    if %parms() >= %parmnum(pWalkUpStack)
                    and %addr(pWalkUpStack) <> *null;
      walkUpCallStack = pWalkUpStack + 1;
    else;
      walkUpCallStack = 1;
    endif;

    if walkUpCallStack > header.numStackEntries;
      sputilm2_writeJobLog('ERROR calling sputilm2_getCallStackEntry ' +
                           ' Calling program requested walking up the ' +
                           'call stack beyond the number of call stack ' +
                           'entries. walkUpCallStack = '
                           + %char(walkUpCallStack) + ' header.numStackEntries = '
                           + %char(header.numStackEntries)
                          :*off
                          :1
                          );
      rtnval = *off;
      dealloc(n) bufferp;
      return rtnval;
    endif;

    if %parms() >= %parmnum(pExtraStackInfo)
                   and %addr(pExtraStackInfo) <> *null;
      pExtraStackInfo.threadId = header.threadIdentifier;
    endif;

    callStackp = bufferp + header.stackEntryOffset;
    for i = 1 to walkUpCallStack;
      callStackp = callStackp + callStack.entryLen;
    endfor;

    pStackEntry.pgm = %trim(callStack.pgmName);
    pStackEntry.pgmlib = %trim(callStack.pgmLib);
    pStackEntry.module = %trim(callStack.moduleName);
    pStackEntry.moduleLib = %trim(callStack.moduleLib);

    if callStack.procNameLen > 0;
      procnamep = callStackp + callStack.procNameDisp;
      pStackEntry.procedureName = %subst(procname:1:callStack.procNameLen);
    else;
      pStackEntry.procedureName = '';
    endif;

    if callStack.numStmtIdentifiers > 0;
      statementIdentifierp = callStackp + callStack.stmtIdentifiersDisp;
      pStackEntry.line = %trim(statementIdentifier);
    else;
      pStackEntry.line = '';
    endif;

    pStackEntry.ControlBoundryActive = (callStack.controlBndActive = '1');
    pStackEntry.ActGrpName = %trim(callStack.ActGrpName);
    pStackEntry.requestLevel = callStack.requestLevel;

    rtnval = *on;
  endif;

  dealloc(n) bufferp;
  return rtnval;

end-proc;

// -----------------------------------------------------------
dcl-proc sputilm2_loadCallStack export;
  dcl-pi *n ind;
  end-pi;

  dcl-ds jobidInfo likeds(jobidInfo_t) inz(*likeds);
  dcl-s rtnval ind;
  dcl-ds apierror likeds(apierror_t) inz(*likeds);

  if stackBufferp <> *null;
    dealloc(n) stackBufferp;
  endif;

  stackBufferp = %alloc(%size(buffer_t));
  memset(stackBufferp:x'00':%size(buffer_t));

  QWVRCSTK(stackBuffer
          :%size(stackBuffer)
          :'CSTK0100'
          :jobidInfo
          :'JIDF0100'
          :apierror
          );

  if apierror.bytesa > 0; // error occurred
    sputilm2_writeJobLog('ERROR calling QWVRCSTK "Retrieve Call Stack ' +
                         ' API". Exception = ' + apierror.exception
                        :*on
                        );
    rtnval = *off;
  else; // No error calling QWVRCSTK
    stackp = stackBufferp + header.stackEntryOffset;
    rtnval = *on;
  endif;

  stackEntriesPos = 1;
  return rtnval;

end-proc;

// -----------------------------------------------------------
dcl-proc sputilm2_fetchNextStackEntry export;
  dcl-pi *n ind;
  end-pi;

  if stackBufferp = *null or stackEntriesPos >= header.numStackEntries;
    return *off;
  endif;

  stackp = stackp + stack.entryLen;
  stackEntriesPos += 1;
  return *on;

end-proc;

// -----------------------------------------------------------
dcl-proc sputilm2_getStackValue export;
  dcl-pi *n varchar(100) rtnparm;
    fieldname varchar(50) value options(*trim);
  end-pi;

  dcl-s procnamep pointer;
  dcl-s procname char(100) based(procnamep);
  dcl-s statementIdentifier char(10) based(statementIdentifierp);

  select;
    when fieldname = 'PROGRAMNAME';
      return %trim(stack.pgmName);

    when fieldname = 'PROGRAMLIB';
      return %trim(stack.pgmLib);

    when fieldname = 'PROCNAME';
      if stack.procNameLen > 0;
        procnamep = stackp + stack.procNameDisp;
        return %subst(procname:1:stack.procNameLen);
      else;
        return '';
      endif;

    when fieldname = 'LINE';
      if stack.numStmtIdentifiers > 0;
        statementIdentifierp = stackp + stack.stmtIdentifiersDisp;
        return %trim(statementIdentifier);
      else;
        return '';
      endif;

    when fieldname = 'ACTIVATIONGROUP';
      return %trim(stack.ActGrpName);

    when fieldname = 'MODULENAME';
      return %trim(stack.modulename);

    when fieldname = 'MODULELIB';
      return %trim(stack.modulelib);

  endsl;

  return '';

end-proc;

// -----------------------------------------------------------
dcl-proc sputilm2_unloadCallStack export;
  dcl-pi *n;
  end-pi;

  dealloc(n) stackBufferp;
  stackEntriesPos = 0;

end-proc;

// -----------------------------------------------------------
//----------------------------------------------------------------
//  sputilm2_writeJobLog : write to job log
//
//   Parm            : Pupose
//   ---------------   -----------------
//   pmsg            : message to write
//   pEscape         : *on = Escape message, *off = information message
//   pCallStackCount :  optional. The call stack number to which to
//                      send the messaeg
//
//----------------------------------------------------------------
dcl-proc sputilm2_writeJobLog export;
  dcl-pi *n;
    pmsg varchar(32767) const options(*varsize);
    pEscape ind const;
    pCallStackCount int(10) const options(*nopass:*omit);
  end-pi;

  dcl-s CallStackCount int(10) inz(1);
  dcl-s msgType char(10);
  dcl-ds msgfile likeds(msgfile_t) inz(*likeds);
  dcl-s msgKey char(4);
  dcl-ds apierror likeds(apierror_t);

  if %parms() >= %parmnum(pCallStackCount)
      and %addr(pCallStackCount) <> *null;
    CallStackCount += pCallStackCount;
  endif;

  if pEscape;
    msgType = '*ESCAPE';
  else;
    msgType = '*INFO';
  endif;

  SendPgmMessage('CPF9898'
                :msgfile
                :pmsg
                :%len(pmsg)
                :msgType
                :'*'
                :CallStackCount
                :msgKey
                :apierror);

  return;

end-proc;
//----------------------------------------------------------------
