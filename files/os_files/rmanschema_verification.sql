set verify off
set heading off
set pagesize 0
set feedback off
spool /opt/oracle/sw/working_dir/rmanschema_list&1
SELECT sys_context('USERENV', 'CURRENT_SCHEMA') FROM dual;
spool off
exit

