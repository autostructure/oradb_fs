set verify off
set heading off
set pagesize 0
set feedback off
spool /opt/oracle/sw/working_dir/rmanschema_list&1
select username from dba_users where username like 'RCAT_%';
spool off
exit

