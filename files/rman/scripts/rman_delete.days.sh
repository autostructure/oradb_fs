#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_delete.days.sh, ora, build6_1, build6_1a,1.2:10/13/11:15:51:03
#  VERSION:  1.3
#  DATE:  05/01/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2003, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Delete an old backup.
# 
# Changes:
#    4/28/2008 - Checking for errors when cross checking archived logs in $LOG1_4
#              - as well as the resync in $LOG1_4_1

export NLS_LANG=american
export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

#############################################################################
print "Step 32.1.1 - Verify user ID is oracle $(date)"
#############################################################################
export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle $(date)"
   exit 1
fi

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

program="rman_delete.days.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_0=$TMP/$program.1_0.sh
export RAO1_1=$TMP/$program.1_1.sh
export RAO1_2=$TMP/$program.1_2.sh
export RAO1_3=$TMP/$program.1_3.sh
export RAO1_4=$TMP/$program.1_4.sh
export RAO1_4_1=$TMP/$program.1_4_1.sh
export RAO1_5=$TMP/$program.1_5.sh
export RAO1_6=$TMP/$program.1_6.sh
export RAO1_7=$TMP/$program.1_7.sh
export LOG1=$LOG_DIR/$program.1.$$.log
export LOG1_0=$LOG_DIR/$program.1_0.$$.log
export LOG1_1=$LOG_DIR/$program.1_1.$$.log
export LOG1_2=$LOG_DIR/$program.1_2.$$.log
export LOG1_3=$LOG_DIR/$program.1_3.$$.log
export LOG1_4=$LOG_DIR/$program.1_4.$$.log
export LOG1_4_1=$LOG_DIR/$program.1_4_1.$$.log
export LOG1_5=$LOG_DIR/$program.1_5.$$.log
export LOG1_6=$LOG_DIR/$program.1_6.$$.log
export LOG1_7=$LOG_DIR/$program.1_7.$$.log


if [[ -z "$LONG_TERM_FULL_BU_KEEP_DAYS" ]]; then
   #Number of days a long term (monthly) backup is not deleted.
   #One long term backup is kept per month.  A long term backup
   #is kept for 30 days by default.
   export LONG_TERM_FULL_BU_KEEP_DAYS=30
fi
if [[ -z "$FULL_BU_KEEP_DAYS" ]]; then
   export FULL_BU_KEEP_DAYS=30  #Number of days a backup is not deleted.
fi
if [[ -z "$INCREMENTAL_KEEP_DAYS" ]]; then
   export  INCREMENTAL_KEEP_DAYS=30  #Number of days a backup is not deleted.
fi
if [[ -z "$ARCHIVE_KEEP_DAYS" ]]; then
   export ARCHIVE_KEEP_DAYS=30  #Number of days a backup is not deleted.
fi
if [[ -z "$VOTING_DISK_KEEP_DAYS" ]]; then
   export VOTING_DISK_KEEP_DAYS=7  #Number of days a voting disk backup is not deleted.
fi
echo "   export ARCHIVE_KEEP_DAYS=$ARCHIVE_KEEP_DAYS
   export  INCREMENTAL_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
   export FULL_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
   export LONG_TERM_FULL_BU_KEEP_DAYS=$LONG_TERM_FULL_BU_KEEP_DAYS
   export VOTING_DISK_KEEP_DAYS=$VOTING_DISK_KEEP_DAYS" | tee -a $LOG1
chown oracle:dba $LOG1


function usage_exit
{
   echo "Usage:  rman_delete.sh {-o[ORACLE_SID]} -bN {-p}" | tee -a $LOG1
   echo "        Removes full backups more than        $FULL_BU_KEEP_DAYS days old." | tee -a $LOG1
   echo "                incremental backups more than $INCREMENTAL_KEEP_DAYS days old." | tee -a $LOG1
   echo "                archive logs more than         $ARCHIVE_KEEP_DAYS days old." | tee -a $LOG1
   echo "          -o, Value for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]" | tee -a $LOG1
   echo "          -p preview, no backup sets removed" | tee -a $LOG1
   echo "          -e delete expired backups" | tee -a $LOG1
   exit 1
}
unset ORACLE_SID
while getopts hepo: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      p) export preview="-p";;
      e) export delete_expired="-e";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

if [[ -z "$ORACLE_SID" ]]; then
   # Set the SIDS envar
   . /home/oracle/system/rman/usfs_local_sids

  number_of_sids=$(print $SIDS | wc -w )
  if (( number_of_sids > 1 )); then
    for ORACLE_SID in $SIDS
    do
      /home/oracle/system/rman/rman_delete.sh -o $ORACLE_SID $delete_expired \
         $preview
    done
    exit
  else
    ORACLE_SID=$(print $SIDS)
  fi
fi

echo "ORACLE_SID=$ORACLE_SID" | tee -a $LOG1
#echo "B_KEY=$B_KEY" | tee -a $LOG1
#exit

# Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
. /home/oracle/system/rman/build_SEND_cmd.sh
export ALLOCATE_SBT_CHANNELS_MAINT="$ALLOCATE_SBT_CHANNELS_MAINT
      allocate channel for maintenance device type 'sbt_tape';
      $send_cmd
      "
echo "ALLOCATE_SBT_CHANNELS_MAINT=$ALLOCATE_SBT_CHANNELS_MAINT"


umask 077
cat > $RAO1 <<EOF2
   export ORACLE_SID=$ORACLE_SID
   export preview=$preview

   export delete_expired=$delete_expired
   echo "ORACLE_SID=\$ORACLE_SID" | tee -a $LOG1
   echo "B_KEY=\$B_KEY" | tee -a $LOG1
   echo "delete_expired=$delete_expired" | tee -a $LOG1
   echo "SHELL=\$SHELL" | tee -a $LOG1
   echo "RMAN_SCHEMA=\$RMAN_SCHEMA" | tee -a $LOG1
   echo "preview=\$preview" | tee -a $LOG1

   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
 
   export date_pattern='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]'

   # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
   . /home/oracle/system/oraenv.usfs
   PATH=\$ORACLE_HOME/bin:\$PATH
   export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

   echo "\\$\\$=\$\$" | tee -a $LOG1
   ps -ef|grep \$\$ | tee -a $LOG1
   env | grep RMAN | tee -a $LOG1

   rm -f $LOG1_0
   echo "
      allocate channel for maintenance device type disk;
      $ALLOCATE_SBT_CHANNELS_MAINT
 
      delete expired backup;
      #list backup of database completed before '\$full_bu_cutoff_date';
      delete expired backup of archivelog all;
      #list backup of archivelog until time '\$archive_cutoff_date';

      release channel;
   " > $RAO1_0
   # rman target / \
   #   nocatalog cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
   if [[ "\$preview" != "-p" ]]; then
      if [[ -n "\$delete_expired" ]]; then
         SCHEMA=\$(echo \$RMAN_SCHEMA | tr [:lower:] [:upper:])
         echo SCHEMA=\$SCHEMA | tee -a $LOG1
         echo "
    Deleting expired backups can take hours.  The TCP connection to NetBackup 
    can time out, which is one to four hours.  This delay is especially long if
    the repository at '\$RMAN_CATALOG' hasn't done this:
       execute dbms_utility.analyze_schema('\$SCHEMA', 'COMPUTE');" | tee -a $LOG1
         echo "Deleting expired backups. \$(date)" | tee -a $LOG1
         rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_0 2>&1 | tee $LOG1_0 | tee -a $LOG1

         # This nocatalog command gets an ORA-00235
         # rman target / nocatalog \
         #    cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
         exit 0
      fi
   fi

   echo "HACK1 Crosschecking old backups. \$(date)" | tee -a $LOG1
   echo "
      allocate channel for maintenance device type disk;
      $ALLOCATE_SBT_CHANNELS_MAINT

      crosscheck backup of controlfile database spfile archivelog all;
      release channel;
   " > $RAO1_4
   rman target / catalog /@\$RMAN_CATALOG \
      cmdfile=$RAO1_4 2>&1 | tee -a $LOG1_4 | tee -a $LOG1

   echo "HACK2 == Resync \$(date)" | tee -a $LOG1
   echo "resync catalog;" > $RAO1_4_1
   rman target / catalog /@\$RMAN_CATALOG \
      cmdfile=$RAO1_4_1 2>&1 | tee -a $LOG1_4_1 | tee -a $LOG1

   if [[ "\$preview" == "-p" ]]; then
     echo "Preview mode only, not deleting anything." | tee $LOG1_7 | tee -a $LOG1
     exit 1
   fi
   export MAX_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
   if ((MAX_BU_KEEP_DAYS>INCREMENTAL_KEEP_DAYS)); then
      MAX_BU_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
   fi
   echo "Deleting full backups more than        $FULL_BU_KEEP_DAYS days old. \$(date)" | tee -a $LOG1
   echo "         incremental backups more than $INCREMENTAL_KEEP_DAYS days old." | tee -a $LOG1
   echo "         archive logs more than         $ARCHIVE_KEEP_DAYS days old." | tee -a $LOG1

   echo "
      CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF \$MAX_BU_KEEP_DAYS DAYS;

      allocate channel for maintenance device type disk;
      $ALLOCATE_SBT_CHANNELS_MAINT

      delete backupset of database tag='Incremental' 
         completed before 'sysdate-$INCREMENTAL_KEEP_DAYS';
      delete backupset of database tag='Full' 
         completed before 'sysdate-$FULL_BU_KEEP_DAYS';
      delete backupset of database tag='LongTerm' 
         completed before 'sysdate-$LONG_TERM_FULL_BU_KEEP_DAYS';
      # Delete oldest backups
      delete backupset of database spfile controlfile 
         completed before 'sysdate-\$MAX_BU_KEEP_DAYS';
      delete backupset of archivelog 
         until time 'sysdate-$ARCHIVE_KEEP_DAYS';
      release channel;
    " > $RAO1_7
    echo "HACK3 == Deleting from NetBackup \$(date)" | tee -a $LOG1
    cat $RAO1_7
    rman target / catalog /@\$RMAN_CATALOG \
          cmdfile=$RAO1_7 2>&1 | \
          tee -a $LOG1_7 | tee -a $LOG1
EOF2

chmod 700 $RAO1
chown oracle.dba $RAO1
ksh $RAO1
if [[ -s $LOG1_0 ]]; then
   if grep ^ORA- $LOG1_0; then
      echo "ERROR: Deleting expired backups from RMAN failed. $(date)" | tee -a $LOG1
      exit 1
   fi
   echo "SCRIPT SUCCESSFULLY COMPLETED. $(date)" | tee -a $LOG1
   exit 0
fi 

echo "Removing old voting disk backups $(date)" | tee -a $LOG1
export MAX_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
if ((MAX_BU_KEEP_DAYS>INCREMENTAL_KEEP_DAYS)); then
   MAX_BU_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
fi
mkdir /opt/oracle/diag/bkp/rman/vote_disk/ 2>&1 | tee -a $LOG1
echo "Doing: find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime +$VOTING_DISK_KEEP_DAYS -name \"vote_disk__*\"" | tee -a $LOG1
find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$VOTING_DISK_KEEP_DAYS" -name "vote_disk__*" 2>&1 | tee -a $LOG1
echo "Removing the above voting disk files" | tee -a $LOG1
rm -f $(find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$VOTING_DISK_KEEP_DAYS" -name "vote_disk__*") 2>&1 | tee -a $LOG1

echo | tee -a $LOG1
echo | tee -a $LOG1

/home/oracle/system/rman/rman_cron_resync.sh
rc=$?
if [[ $rc != 0 ]]; then
   echo "ERROR: one or more resynchronizations failed." | tee -a $LOG1
   date | tee -a $LOG1
   exit $rc
fi

touch $LOG1_7 $LOG1_4 $LOG1_4_1
# Ignore RMAN-20215
if ! grep ORA- $LOG1_7 $LOG1_4 $LOG1_4_1
then
   echo "SCRIPT SUCCESSFULLY COMPLETED. (rman_delete.sh) $(date)" | tee -a $LOG1
   exit 0
elif egrep RMAN-20503 $LOG1_7 > /dev/null; then
   echo "    Objects were crosschecked previously.  To delete expired  $(date)" | tee -a $LOG1
   echo "    backups, run" | tee -a $LOG1
   echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID -e" | tee -a $LOG1
   echo "    and" | tee -a $LOG1
   echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID" | tee -a $LOG1
fi
echo "Exiting with error code = 1 $(date)" | tee -a $LOG1
exit 1
