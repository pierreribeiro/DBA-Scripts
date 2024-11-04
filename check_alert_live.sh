#!/bin/bash
sqlplus -S "/as sysdba" @/home/oracle/check_alertlog.sql > /home/oracle/alerts_formail.txt
cnt=$(wc -l </home/oracle/alerts_formail.txt)
echo $cnt
if [ $cnt -ge "4" ]
then
        /usr/bin/mail -A gmail -s "Oracle DB Alert ORCL" \
                -r xxxx@dominio.gr \
                blablabla@outlook.com, dokimi@outlook.com \
         < /home/oracle/alerts_formail.txt
fi