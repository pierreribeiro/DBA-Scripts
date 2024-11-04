   set echo off
set pagesize 0
set feedback off

select 'TIMESTAMP: '
       || originating_timestamp
       || ' ---- INSTANCE_NAME: '
       || (
   select instance_name
     from v1tp4instance
)
       || ' ---- HOST_NAME: '
       || host_id
       || ' ---- MESSAGE: '
       || message_text
  from v$diag_alert_ext
 where 1 = 1
   and cast(substr(
   originating_timestamp,
   1,
   length(originating_timestamp) - 7
) as timestamp) > cast(sysdate - interval '5' minute as timestamp)
   and ( message_text like '%ORA-00060%' );

quit;
/