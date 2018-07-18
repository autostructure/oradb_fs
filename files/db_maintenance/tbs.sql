CONNECT / AS SYSDBA
REM
REM Date:  06-AUG-2008
REM This script displays the tablespace name, the used space, the total space 
REM and the percent used.
REM Author  Jane Reyling

SET VERIFY off LINESIZE 250 PAGESIZE 49999 TRIM on TRIMSPOOL on FEEDBACK off HEAD on PAUSE off
BREAK ON tablespace ON used ON total ON pct_used
COL pct_used 	FORMAT 999.9 	       	HEAD 'PCT USED'   			  JUSTIFY LEFT
COL total	FORMAT 999999999999 	HEAD 'TOTAL' 				  JUSTIFY LEFT
COL used 	FORMAT 999999999999 	HEAD 'USED'    				  JUSTIFY LEFT
COL file_name 	FORMAT a70 		HEAD 'FILENAME under /opt/oracle/oradata' JUSTIFY LEFT
COL tablespace 	FORMAT a20 		HEAD 'TABLESPACE' 			  JUSTIFY LEFT
COL filesize 	FORMAT a15 		HEAD 'FILESIZE'   			  JUSTIFY LEFT 
PROMPT ~~~~~~ DATA TABLESPACES ~~~~~~
SELECT b.tablespace_name tablespace,
       DECODE(a.bytes,null,0,a.bytes) used,
       b.bytes total,
       DECODE(a.bytes/b.bytes*100,null,0,a.bytes/b.bytes*100) pct_used,
       regexp_replace(c.file_name, '^/opt/oracle/oradata/') file_name,
       c.bytes/(1024*1024)||' MB' filesize
  FROM sys.sm$ts_used a,sys.sm$ts_avail b, dba_data_files c
 WHERE a.tablespace_name (+) = b.tablespace_name 
   AND c.tablespace_name (+) = b.tablespace_name
ORDER BY b.tablespace_name;

PROMPT 
PROMPT ~~~~~~ TEMP TABLESPACES ~~~~~~
SET VERIFY off LINESIZE 250 PAGESIZE 49999 TRIM on TRIMSPOOL on FEEDBACK off HEAD on PAUSE off
BREAK ON ttablespace ON totaltemp ON tpct_used
COL totaltemp 	FORMAT 99999999999 	HEAD 'TOTAL'      JUSTIFY LEFT
COL tfile_name 	FORMAT a70 		HEAD 'FILENAME under /opt/oracle/oradata'   JUSTIFY LEFT
COL ttablespace	FORMAT a25 		HEAD 'TABLESPACE' JUSTIFY LEFT
COL tfilesize 	FORMAT a15 		HEAD 'FILESIZE'   JUSTIFY LEFT
COL tpct_used    FORMAT 999.9    	HEAD 'PCT USED'   JUSTIFY LEFT
SELECT b.tablespace_name ttablespace,
       b.bytes totaltemp,
       regexp_replace(b.file_name, '^/opt/oracle/oradata/') tfile_name,
       b.bytes/(1024*1024)||' MB' tfilesize,
       DECODE(a.bytes_used/b.bytes*100,null,0,a.bytes_used/b.bytes*100) tpct_used
  FROM dba_temp_files b, v$temp_space_header a
 WHERE a.tablespace_name = b.tablespace_name;
exit;
