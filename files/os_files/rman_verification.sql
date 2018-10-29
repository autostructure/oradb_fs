set verify off
set heading off
set pagesize 0
set feedback off
spool /opt/oracle/sw/working_dir/rman_reg_db_list&1
SELECT reg_db_unique_name from db;
spool off
exit

