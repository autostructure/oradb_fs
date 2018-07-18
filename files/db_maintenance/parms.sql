connect / as sysdba
SET ECHO OFF
SET VERIFY on
SET LINESIZE 50
SET PAGESIZE 250
SET TRIM on
SET TRIMSPOOL on
SET FEEDBACK off
SET HEAD on
SET PAUSE off

COLUMN parm       FORMAT a20        HEAD 'Parameter'
COLUMN pval       FORMAT a20        HEAD 'Value'

select o.parameter parm, o.value pval  
from v$option o 
where o.parameter in (
	'Partitioning',
	'Advanced Compression')
order by parameter;

column c1 heading "SPATIAL Installed?"   format a20
SELECT CASE WHEN MAX(username) IS NULL THEN 'FALSE' ELSE 'TRUE' END c1
  FROM dba_users
 WHERE username = 'MDDATA';

exit;
