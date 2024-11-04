set echo off
set linesize 150
set pagesize 0
set feedback off

SELECT
    'Warning: Blocking Sessions on '
    || (
        SELECT
            INSTANCE_NAME
        FROM
            V$INSTANCE
    )
    || '@'
    ||(
        SELECT
            HOST_NAME
        FROM
            V$INSTANCE
            ||'!!! '
        FROM
            GV$SESSION
        WHERE
            ROWNUM = 1
            AND SECONDS_IN_WAIT > 600;

SELECT
    'Blocked Session: '
    || ' LOGON: '
    || TO_CHAR(H.LOGON_TIME, 'YYYY/MM/DD HH:MI:SS')
       || ' ---- SID: '
       || H.SID
       || ' ---- SERIAL: '
       || H.SERIAL#
       || ' ---- PROCESS: '
       || P.SPID
       || ' ---- USERNAME: '
       || U.USERNAME
       || ' ---- OSUSER: '
       || H.OSUSER
       || ' ---- MACHINE: '
       || H.MACHINE
       || ' ---- PROGRAM: '
       || H.PROGRAM
       || ' ---- MODULE: '
       || H.MODULE
       || ' ---- BLOCKING SESSION STATUS: '
       || H.BLOCKING_SESSION_STATUS
       || ' ---- BLOCKING INSTANCE: '
       || H.BLOCKING_INSTANCE
       || ' ---- BLOCKING SESSION: '
       || H.BLOCKING_SESSION
       || ' ---- BLOCKING TIME: '
       || H.SECONDS_IN_WAIT
       || ' ---- BLOCKING OBJECT: '
       || O.OWNER
       ||'.'
       ||O.OBJECT_NAME
       || ' ----                  SQL TEXT: '
       || S.SQL_TEXT
       || '                                                                                                                              '
       || 'Blocker''s Session: '
       || ' LOGON: '
       || TO_CHAR(H2.LOGON_TIME, 'YYYY/MM/DD HH:MI:SS')
          || ' ---- SID: '
          || H2.SID
          || ' ---- SERIAL: '
          || H2.SERIAL#
          || ' ---- PROCESS: '
          || P2.SPID
          || ' ---- STATUS: '
          || H2.STATUS
          || ' ---- USERNAME: '
          || U.USERNAME
          || ' ---- OSUSER: '
          || H2.OSUSER
          || ' ---- MACHINE: '
          || H2.MACHINE
          || ' ---- PROGRAM: '
          || H2.PROGRAM
          || ' ---- MODULE: '
          || H2.MODULE
          || ' ----                  SQL TEXT: '
          || S2.SQL_TEXT
FROM
    GV$SESSION  H
    INNER JOIN GV$SESSION H2
    ON (H.BLOCKING_INSTANCE=H2.INST_ID
    AND H.BLOCKING_SESSION=H2.SID)
    LEFT JOIN GV$SQLAREA S
    ON H.SQL_HASH_VALUE = S.HASH_VALUE
    AND H.SQL_ADDRESS = S.ADDRESS
    AND H.INST_ID = S.INST_ID
    LEFT JOIN GV$SQLAREA S2
    ON H2.SQL_HASH_VALUE = S2.HASH_VALUE
    AND H2.SQL_ADDRESS = S2.ADDRESS
    AND H2.INST_ID = S2.INST_ID
    LEFT JOIN DBA_USERS U
    ON H.USER# = U.USER_ID
    LEFT JOIN GV$PROCESS P
    ON P.ADDR = H.PADDR
    AND P.INST_ID = H.INST_ID
    LEFT JOIN GV$PROCESS P2
    ON P2.ADDR = H2.PADDR
    AND P2.INST_ID = H2.INST_ID
    LEFT JOIN DBA_OBJECTS O
    ON O.OBJECT_ID = H.ROW_WAIT_OBJ#
WHERE
    1=1
    AND H.SECONDS_IN_WAIT > 600
    AND H.BLOCKING_SESSION_STATUS = 'VALID';

SELECT
    'Kill Commands: '
    || 'KILL FROM DB: " alter system kill session '''
    ||SID
    ||', '
    ||H.SERIAL#
    ||', @'
    ||H.INST_ID
    ||''' immediate; "'
    ||' ---- KILL FROM OS: " kill -9 '
    ||P.SPID
    || ' "'
FROM
    GV$SESSION H
    LEFT JOIN GV$SQLAREA S
    ON H.SQL_HASH_VALUE = S.HASH_VALUE
    AND H.SQL_ADDRESS = S.ADDRESS
    AND H.INST_ID = S.INST_ID
    LEFT JOIN GV$PROCESS P
    ON P.ADDR = H.PADDR
    AND P.INST_ID = H.INST_ID
WHERE
    1=1
    AND H.SID = (
        SELECT
            BLOCKING_SESSION
        FROM
            GV$SESSION
        WHERE
            SECONDS_IN_WAIT > 600
            AND BLOCKING_SESSION_STATUS = 'VALID'
            AND ROWNUM=1
    );

exit;