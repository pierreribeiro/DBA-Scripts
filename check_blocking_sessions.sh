#!/bin/bash
sqlplus -S "/as sysdba" @/home/oracle/sessions_blocking.sql > /home/oracle/sessions_blocking.log
cnt=$(wc -l </home/oracle/sessions_blocking.log)
echo $cnt
if [ $cnt -ge "4" ]
then
#       /usr/bin/uuencode alert_$ORACLE_SID.log alert_$ORACLE_SID.log | \
        /usr/bin/mail -A gmail -s "Oracle DB Blocking on ORCL" \
                -r xxxx@dataplatform.gr \
                blablabla@gmail.com \
         < /home/oracle/sessions_blocking.log



fi