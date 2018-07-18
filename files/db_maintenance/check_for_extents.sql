CONNECT / AS sysdba
SET ECHO OFF
SET VERIFY on
SET LINESIZE 250
SET PAGESIZE 49999
SET TRIM on
SET TRIMSPOOL on
SET FEEDBACK on
SET HEAD on
SET PAUSE off

COLUMN ownr             FORMAT a25           HEAD 'Owner'
COLUMN sname            FORMAT a20           HEAD 'Segment Name'
COLUMN xtent            FORMAT 9,999,999     HEAD 'Number of Extents'


SELECT owner ownr, segment_name sname, extents xtent
  FROM dba_segments
 WHERE extents > 2000                 
   AND segment_type != 'TEMPORARY'
ORDER BY segment_name;
exit;
