   SET SERVEROUTPUT ON;

SET DEFINE OFF;

declare
   long_running    number := 0;
   p_smtp_host     varchar2(30) := 'your_smtp_server.yourcompany.com'; --< Provide the SMTP Host name here
   p_smtp_port     number := 25;
   v_db_name       varchar(20);
   v_alert_time    varchar(20);
   v_alert_message varchar(2000);
   p_from          varchar2(30) := 'noreply@your_company.com'; --< Provide the sender's e-mail address here. This must be one e-mail address only
   p_recipients    varchar2(500) := 'Support_DL_1@your_company.com, Support_DL_2@your_company.com'; --< Provide comma separated list of recipients.
   p_subject       varchar2(100);
   p_message       varchar2(4000);
   l_mail_conn     utl_smtp.connection;
begin
   select count(*)
     into long_running
     from (
      select originating_timestamp,
             message_text
        from v$diag_alert_ext
       where originating_timestamp > cast(sysdate - 0.25 / 24 as timestamp)
         and message_text like '%Global Enqueue Services Deadlock detected%'
   )
    where rownum = 1;
   dbms_output.put_line('Number of Deadlock occurances in last 15 mins: ' || long_running);
   if long_running > 0 then
 
        --dbms_output.put_line('Let us send email');
      declare
         my_recipients varchar2(32000);
         location      number := 0;
         my_index      number := 1;
      begin
         select *
           into
            v_db_name,
            v_alert_time,
            v_alert_message
           from (
            select b.instance_name,
                   to_char(
                      a.originating_timestamp,
                      'DD-MON-YYYY HH24:MI:SS'
                   ) alert_time,
                   a.message_text alert_message
              from v$diag_alert_ext a,
                   v$instance b
             where a.originating_timestamp > cast(sysdate - 0.25 / 24 as timestamp)
               and a.message_text like '%Global Enqueue Services Deadlock detected%'
         )
          where rownum = 1;
         dbms_output.put_line('Number of Deadlock occurances in last 15 mins: ' || long_running);
         p_subject := 'Deadlock Alert'
                      || '-'
                      || v_db_name;
         p_message := 'A deadlock has been detected in '
                      || v_db_name
                      || '. '
                      || 'Please see below details and take appropriate action: '
                      || chr(10)
                      || chr(10)
                      || ' ============================================= '
                      || chr(10)
                      || ' Deadlock Occurred at: '
                      || v_alert_time
                      || chr(10)
                      || chr(10)
                      || ' Alert Message: '
                      || v_alert_message
                      || chr(10)
                      || ' ============================================= '
                      || chr(10)
                      || chr(10)
                      || 'Regards,'
                      || chr(10)
                      || 'OEM Monitoring-Your Team';
         l_mail_conn := utl_smtp.open_connection(
            p_smtp_host,
            p_smtp_port
         );
         utl_smtp.helo(
            l_mail_conn,
            p_smtp_host
         );
         utl_smtp.mail(
            l_mail_conn,
            p_from
         );
         my_recipients := rtrim(
            p_recipients,
            ',; '
         );
         my_index := 1;
         while my_index < length(my_recipients) loop
            location := instr(
               my_recipients,
               ',',
               my_index,
               1
            );
            if location = 0 then
               location := instr(
                  my_recipients,
                  ';',
                  my_index,
                  1
               );
            end if;

            if location <> 0 then
               utl_smtp.rcpt(
                  l_mail_conn,
                  trim(substr(
                     my_recipients,
                     my_index,
                     location - my_index
                  ))
               );
               my_index := location + 1;
            else
               utl_smtp.rcpt(
                  l_mail_conn,
                  trim(substr(
                     my_recipients,
                     my_index,
                     length(my_recipients)
                  ))
               );
               my_index := length(my_recipients);
            end if;
         end loop;

         my_recipients := replace(
            my_recipients,
            ';',
            ','
         );
         utl_smtp.open_data(l_mail_conn);
         utl_smtp.write_data(
            l_mail_conn,
            'Date: '
            || to_char(
               sysdate,
               'DD-MON-YYYY HH24:MI:SS'
            )
            || utl_tcp.crlf
         );
         utl_smtp.write_data(
            l_mail_conn,
            'To: '
            || my_recipients
            || utl_tcp.crlf
         );
         utl_smtp.write_data(
            l_mail_conn,
            'From: '
            || p_from
            || utl_tcp.crlf
         );
         utl_smtp.write_data(
            l_mail_conn,
            'Subject: '
            || p_subject
            || utl_tcp.crlf
         );
         utl_smtp.write_data(
            l_mail_conn,
            'Reply-To: '
            || p_from
            || utl_tcp.crlf
            || utl_tcp.crlf
         );
         utl_smtp.write_data(
            l_mail_conn,
            p_message
            || utl_tcp.crlf
            || utl_tcp.crlf
         );
         utl_smtp.close_data(l_mail_conn);
         utl_smtp.quit(l_mail_conn);
      end;
   end if;
end;
/