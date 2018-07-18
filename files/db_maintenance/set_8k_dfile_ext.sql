connect / as sysdba
set linesize 200 head off pagesize 200 feedback off

spool /home/oracle/dbcheck/logs/datafile_extent_$ORACLE_SID.sql

select 'ALTER DATABASE DATAFILE '|| '''' ||file_name|| '''' ||' AUTOEXTEND ON NEXT 100M  MAXSIZE  32767M;'
from dba_data_files
where tablespace_name NOT LIKE '%SDE%'
and autoextensible <> 'YES'
or increment_by <> 12800
or maxbytes/1024/1024 <> 32767
order by file_name;

select 'ALTER DATABASE TEMPFILE '|| '''' ||file_name|| '''' ||' AUTOEXTEND ON NEXT 100M  MAXSIZE  32767M;'
from dba_temp_files
where file_name like '%temp%'
and tablespace_name NOT LIKE '%SDE%'
and autoextensible <> 'YES'
or increment_by <> 12800 
or maxbytes/1024/1024 <> 32767 
order by file_name;

spool off;
set feedback on
@/home/oracle/dbcheck/logs/datafile_extent_$ORACLE_SID.sql
exit;

