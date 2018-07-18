#!/bin/ksh
#---------------------------------------------------------------------------
# FILE:  rundbsql.sh
#
# Date:  02/09/2015
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script that runs sql scripts on the FIRST NODE of a RAC.
#              It is called from the db maintenance scripts.
#
#----------------------------------------------------------------------------
. /fslink/sysinfra/oracle/common/db/oraenv.usfs
export logs=/home/oracle/dbcheck/logs
export scripts=/home/oracle/dbcheck/scripts

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Show the global name for ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/global_name.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Show archive log list for ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/archloglist.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Show the data pump directory for ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/data_pump_dir.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") List total, allocated, freespace, pct used for tablespaces on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/dbsize.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") List datafiles by tablespaces on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/tbs.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") List non-SYS users with dba privs ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/list_user_privs.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Switch logfiles on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/logswitch.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Display if licensed parameters are enabled on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/parms.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Display usage summary of Oracle options on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/FSoptions.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Set dfile parms autoextend on, next and max extents based on db_block_size ${ORACLE_SID}.
echo '##############################################################'
blk_size=`sqlplus -s /nolog << !
connect / as sysdba
SET HEAD OFF;
select value from v\\\$parameter where name='db_block_size';
EXIT
!`
if [ ${blk_size} = 8192 ] ; then 
echo 'Database block size is 8k.  Datafile parms:'
echo 'NEXT EXTENT 100M, MAX EXENT SIZE 32767M.'
echo ''
    $ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/set_8k_dfile_ext.sql
else
echo 'Database block size is 16k.  Datafile parms:'
echo 'NEXT EXTENT 100M, MAX EXENT SIZE 65535M.'
echo ''
    $ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/set_16k_dfile_ext.sql
fi

rm -f $logs/datafile_extent_$ORACLE_SID.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Compile invalid objects in  ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/FSutlrp.sql

echo ''
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check Segments that has more than 2000 extents - ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/check_for_extents.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Count number of roles granted to fsdba on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/count_fsdba_privs.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Tables that has more then 500 chained rows -  ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/chained_rows.sql
rm -f $logs/chain.lst

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check to see if instance started with SPFILE on ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/db_start.sql

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Reset password/Account Lock the FS_Schema ${ORACLE_SID}.
echo '##############################################################'
$ORACLE_HOME/bin/sqlplus -S /nolog @$scripts/cr_reset_fsschemas.sql
rm -f $logs/reset_fsschemas_$ORACLE_SID.sql

exit;
