-- File: restore_redo_2_local_disk_after_ckpt.sql
-- Input:
-- Output: /tmp/restore_redo_2_local_disk_after_ckpt.rmn
-- Purpose: When recovering a database, it may throw these errors:
-- RMAN-06004: ORACLE error from recovery catalog database: RMAN-20011: target database incarnation is not current in recovery catalog
--    then the recovery needs to be attempted manually from sqlplus because of an apparent bug manifested in earlier versions.  
--    Also, this error stack applies
--    RMAN-03002: failure of recover command at 09/09/2009 08:56:29
--    ORA-00283: recovery session canceled due to errors
--    RMAN-11003: failure during parse/execution of SQL statement: alter database recover logfile '/ordb048/arch_ordb048/1_108_695461018.dbf'
--    ORA-00283: recovery session canceled due to errors
--    ORA-00600: internal error code, arguments: [krhpfh_03-1209], [1], [696435662], [696522973], [542662], [0], [0], [0]
--    ORA-01110: data file 1: '/ordb048/dbms01/system01.dbf'
--
-- The archived redo logs need to be restored to a local disk.  The datafiles and control file have been recovered to possibly different checkpoint SCNs.  The lowest checkpoint is needed.  Then, the archived log just before the checkpoint, the archived log containing that checkpoint, and every archived log after that need to be restored to local disk.  
-- 
-- The current version of the script will query for the lowest checkpoint, then generate a restore script for putting the local redologs onto disk.
-------------------------------------------------------------------------------
-- Earlier versions of the script (provided incase a manual sanity check is needed):
-- SQL> col FIRST_CHANGE# format 99999999999999999999
-- SQL> col SWITCH_CHANGE# format 99999999999999999999
-- SQL> select * from (select ckpt.ckmin, THREAD#, SEQUENCE#, FIRST_CHANGE#, SWITCH_CHANGE# 
--    from v$loghist lh, 
--         (select min(CHECKPOINT_CHANGE#) ckmin from 
--            (select CHECKPOINT_CHANGE# from v$database where CHECKPOINT_CHANGE# <> 0 
--             union select CHECKPOINT_CHANGE# from v$datafile where CHECKPOINT_CHANGE# <> 0)) ckpt 
--    where lh.FIRST_CHANGE# < ckpt.ckmin order by lh.FIRST_CHANGE# desc) rn
--    where rownum<4 order by rn.first_change#;
-- SQL> exit -- Become OS user oracle again
-- 
-- Expected results will show a SWITCH_CHANGE# SCN like 5041009
-- 
--      CKMIN    THREAD#  SEQUENCE# FIRST_CHANGE# SWITCH_CHANGE#
-- ---------- ---------- ---------- ------------- --------------
--   23918546          1        520      23885210       23894078
--   23918546          1        521      23894078       23894538
--   23918546          1        522      23894538       23934604
-- 
-- (CKMIN is the lowest ckeckpoint of any datafile or controlfile.  If it isn't between FIRST_CHANGE# and SWITCH_CHANGE# of the last row, then something is wrong.)
-- 
-- The recovery may require more than just the last log. Therefore, restore to the next oldest.
-- Record the SWITCH_CHANGE# of the second to last row here: __________
-- (In the above example, 23894538.) 
-- Create a script to restore the archived logfiles starting from the returned SCN until the end.  (Don't use 5041009 since it is an example. Use the actual number from the results of the last "select" statement.)
-- $ cat > /home/oracle/arch.rmn <<EOF
-- run {
--    allocate channel t1 type 'sbt_tape' parms
--    'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
--    restore archivelog from scn   5041099;
--    release channel t1 ;
-- }
-- EOF
-- $ ./fs-rman.sh target / catalog $RMAN_SCHEMA@$RMAN_CATALOG cmdfile=/home/oracle/arch.rmn 
--  Expected results will look something like this:
-- <snip>
-- channel t1: restoring archive log
-- archive log thread=1 sequence=56
-- channel t1: restoring archive log
-- archive log thread=1 sequence=57
-- channel t1: reading from backup piece arc_ORDB048_1412781210_58_1_1_1qkng29l_1_1__ip=170.144.133.39_dbid=1412781210
-- channel t1: restored backup piece 1
-- piece handle=arc_ORDB048_1412781210_58_1_1_1qkng29l_1_1__ip=170.144.133.39_dbid=1412781210
-- <snip>
-- Do not continue if any RMAN-xxxxx errors or ORA-xxxxx errors occur.
-- Attempt to manually recover the database in sqlplus
-- $ sqlplus / as sysdba
-- SQL> recover database using BACKUP CONTROLFILE;
-- -- Enter "auto" when prompted below
-- ORA-00279: change 538544 generated at 08/25/2009 12:22:30 needed for thread 1
-- ORA-00289: suggestion :
-- /opt/oracle/admin/ordb04/arch_ordb04/1_94_695461018.dbf
-- ORA-00280: change 538544 for thread 1 is in sequence #94
-- Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
-- auto
-- 
-- If a log is request that has not be restored, then modify the /home/oracle/arch.rmn sript to retrieve the requested log and try again.
-- 
-- The logs names will scroll by until one cannot be found, which will be given in a message like this:
-- ORA-00308: cannot open archived log
-- '/opt/oracle/admin/ordb04/arch_ordb04/1_1_696435662.dbf'
-- ORA-27037: unable to obtain file status
-- Linux-x86_64 Error: 2: No such file or directory
-- Additional information: 3
-- 
-- If at least one log has successfully been applied, then attempt to open the database in sqlplus with "alter database open resetlogs" as given in step 1.11
-- 

set feed off
set head off
set sqlprompt '-- '
set lines 80
spool /home/oracle/system/rman/restore_redo_2_local_disk_after_ckpt.rmn
-- TODO, may need to build a SEND command with build_SEND_cmd.sh
-- Run build_SEND_cmd.sh  to set the envars ($NB_ORA_CLIENT, $NB_ORA_SERV, and $NB_ORA_POLICY)
-- Manually replace these values in this script
--            send 'NB_ORA_CLIENT=$NB_ORA_CLIENT, NB_ORA_SERV=$NB_ORA_SERV, NB_ORA_POLICY=$NB_ORA_POLICY';

select 'run {' || chr(10) ||
   '   allocate channel t1 type '||chr(39)||'sbt_tape'||chr(39)|| ';' || chr(10) ||
   '   restore archivelog from scn '||FIRST_CHANGE#||';'|| chr(10) ||
   '   release channel t1;' || chr(10) ||
    '}' || chr(10) 
from (
   select * from (select ckpt.ckmin, THREAD#, SEQUENCE#, FIRST_CHANGE#, SWITCH_CHANGE# 
   from v$loghist lh, 
        (select min(CHECKPOINT_CHANGE#) ckmin from 
           (select CHECKPOINT_CHANGE# from v$database where CHECKPOINT_CHANGE# <> 0 
            union select CHECKPOINT_CHANGE# from v$datafile where CHECKPOINT_CHANGE# <> 0)) ckpt 
   where lh.FIRST_CHANGE# < ckpt.ckmin order by lh.FIRST_CHANGE# desc) rn
   where rownum<3 order by rn.first_change#) a
where
   rownum=1 order by a.first_change#;
spool off
prompt Output: /home/oracle/system/rman/restore_redo_2_local_disk_after_ckpt.rmn
exit;
