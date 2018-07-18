connect / as sysdba
set linesize 15
COLUMN dbinit             FORMAT a15           HEAD 'Init File Type'
SELECT DECODE(value, NULL, 'PFILE', 'SPFILE') dbinit
  FROM sys.v_$parameter WHERE name = 'spfile';
exit;
