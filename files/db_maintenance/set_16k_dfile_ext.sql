connect / as sysdba
set linesize 200 head off pagesize 200 feedback off

create table dbfilename
as select file_name,autoextensible,increment_by,maxbytes
from dba_data_files
where file_name NOT LIKE '%sde%'
and file_name NOT LIKE '%datim%'
and file_name NOT LIKE '%encry%';
commit;

create table tempfilename
as select file_name,autoextensible,increment_by,maxbytes
from dba_temp_files
where file_name NOT LIKE '%sde%'
and file_name NOT LIKE '%datim%'
and file_name NOT LIKE '%encry%';
commit;

spool /home/oracle/dbcheck/logs/datafile_extent_$ORACLE_SID.sql

select 'ALTER DATABASE DATAFILE '|| '''' ||file_name|| '''' ||' AUTOEXTEND ON NEXT 100M  MAXSIZE  65535M;'
from dbfilename
where autoextensible <> 'YES'
or increment_by <> 6400
or maxbytes/1024/1024 <> 65535
order by file_name;

select 'ALTER DATABASE TEMPFILE '|| '''' ||file_name|| '''' ||' AUTOEXTEND ON NEXT 100M  MAXSIZE  65535M;'
from tempfilename
where file_name like '%temp%'
and autoextensible <> 'YES'
or increment_by <> 6400
or maxbytes/1024/1024 <> 65535
order by file_name;

spool off;

drop table dbfilename purge;
drop table tempfilename purge;
set feedback on

@/home/oracle/dbcheck/logs/datafile_extent_$ORACLE_SID.sql

exit;

