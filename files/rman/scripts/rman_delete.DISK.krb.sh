#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_delete.DISK.krb.sh, ora, build6_1, build6_1a,1.3:10/3/11:10:35:43
#  VERSION:  1.4
#  DATE:  04/25/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2003
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Delete an old backup.

export NLS_LANG=american
export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

if [[ -z "$LONG_TERM_FULL_BU_KEEP_DAYS" ]]; then
   #Number of days a long term (monthly) backup is not deleted.
   #One long term backup is kept per month.  A long term backup
   #is kept for 365 days by default.
   export LONG_TERM_FULL_BU_KEEP_DAYS=365
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
echo "   export ARCHIVE_KEEP_DAYS=$ARCHIVE_KEEP_DAYS
   export  INCREMENTAL_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
   export FULL_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
   export LONG_TERM_FULL_BU_KEEP_DAYS=$LONG_TERM_FULL_BU_KEEP_DAYS"

#############################################################################
echo "Step 32.1.1 - Verify user ID is oracle"
#############################################################################
export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle"
   exit 1
fi

function usage_exit
{
   echo "Usage:  rman_delete.sh {-o[ORACLE_SID]} -bN {-p}"
   echo "        Removes full backups more than        $FULL_BU_KEEP_DAYS days old."
   echo "                incremental backups more than $INCREMENTAL_KEEP_DAYS days old."
   echo "                archive logs more than         $ARCHIVE_KEEP_DAYS days old."
   echo "          -o, Value for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -p preview, no backup sets removed"
   echo "          -e delete expired backups"
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
      /home/oracle/system/rman/rman_delete.DISK.krb.sh -o $ORACLE_SID $delete_expired \
         $preview
    done
    exit
  else
    ORACLE_SID=$(echo $SIDS)
  fi
fi

echo "ORACLE_SID=$ORACLE_SID"
#echo "B_KEY=$B_KEY"
#exit

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/home/oracle/system/rman/temp
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

program="rman_delete.sh"
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



umask 077
cat > $RAO1 <<EOF2
   alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile
   export B_KEY="$B_KEY"
   export ORACLE_SID=$ORACLE_SID
   export delete_expired=$delete_expired
   echo "ORACLE_SID=\$ORACLE_SID"
   echo "B_KEY=\$B_KEY"
   echo "delete_expired=\$delete_expired"
   echo "SHELL=\$SHELL"
   echo "RMAN_SCHEMA=\$RMAN_SCHEMA"
   echo "RMAN_CATALOG=\$RMAN_CATALOG"

   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
 
   export date_pattern='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]'

   # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
   . /home/oracle/system/oraenv.usfs
   PATH=\$ORACLE_HOME/bin:\$PATH
   export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

   echo "\\$\\$=\$\$"
   ps -ef|grep \$\$
   env | grep RMAN

   rm -f $LOG1_0
   echo "
 
     delete expired backup;
     #list backup of database completed before '\$full_bu_cutoff_date';
     delete expired backup of archivelog all;
     #list backup of archivelog until time '\$archive_cutoff_date';

   " > $RAO1_0
   #/home/oracle/system/rman/fs-rman target / \
   #   nocatalog cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
   if [[ "$preview" != "-p" ]]; then
      if [[ -n "$delete_expired" ]]; then
         typeset -u SCHEMA
         SCHEMA=\$RMAN_SCHEMA
         echo "
    Deleting expired backups can take hours.  The TCP connection to NetBackup 
    can time out, which is one to four hours.  This delay is especially long if
    the repository at '\$RMAN_CATALOG' hasn't done this:
       execute dbms_utility.analyze_schema('\$SCHEMA', 'COMPUTE');"
         echo "Deleting expired backups."
         rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_0 2>&1 | tee $LOG1_0

         # This nocatalog command gets an ORA-00235
         #  /home/oracle/system/rman/fs-rman target / nocatalog \
         #    cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
         exit 0
      fi
   fi

   echo "Crosschecking old backups."
   echo "
     crosscheck backup of controlfile database spfile archivelog all;
   " > $RAO1_4
   rman target / nocatalog cmdfile=$RAO1_4 2>&1 | tee -a $LOG1_4

   echo "resyncing catalog" 
   echo "resync catalog;" > $RAO1_4_1
   rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_4_1 2>&1 | tee -a $LOG1_4_1

   if [[ "$preview" == "-p" ]]; then
     echo "Preview mode only, not deleting anything." | tee $LOG1_7
     exit 1
   fi
   export MAX_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
   if ((MAX_BU_KEEP_DAYS>INCREMENTAL_KEEP_DAYS)); then
      MAX_BU_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
   fi
   echo "Deleting full backups more than        $FULL_BU_KEEP_DAYS days old."
   echo "         incremental backups more than $INCREMENTAL_KEEP_DAYS days old."
   echo "         archive logs more than         $ARCHIVE_KEEP_DAYS days old."

   echo "
      delete backup of database tag='Incremental' 
         completed before 'sysdate-$INCREMENTAL_KEEP_DAYS';
      delete backup of database tag='Full' 
         completed before 'sysdate-$FULL_BU_KEEP_DAYS';
      # Delete oldest backups
      delete backup 
         completed before 'sysdate-\$MAX_BU_KEEP_DAYS';
      delete backup of archivelog 
         until time 'sysdate-$ARCHIVE_KEEP_DAYS';
    " > $RAO1_7
    cat $RAO1_7
    echo "delete the old backups in rman"
    rman target / catalog /@\$RMAN_CATALOG \
          cmdfile=$RAO1_7 2>&1 | \
          tee -a $LOG1_7
EOF2

chmod 700 $RAO1
chown oracle.dba $RAO1
ksh $RAO1
if [[ -s $LOG1_0 ]]; then
   if grep ^ORA- $LOG1_0; then
      echo "ERROR: Deleting expired backups from RMAN failed."
      exit 1
   fi
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   exit 0
fi 

echo "Removing old voting disk backups"
export MAX_BU_KEEP_DAYS=$FULL_BU_KEEP_DAYS
if ((MAX_BU_KEEP_DAYS>INCREMENTAL_KEEP_DAYS)); then
   MAX_BU_KEEP_DAYS=$INCREMENTAL_KEEP_DAYS
fi
find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$MAX_BU_KEEP_DAYS" -name "vote_disk__*"
rm -f $(find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$MAX_BU_KEEP_DAYS" -name "vote_disk__*")

echo
echo

/home/oracle/system/rman/rman_cron_resync.sh
rc=$?
echo rc=$rc
if [[ $rc != 0 ]]; then
   echo "ERROR: one or more resynchronizations failed."
   date
   exit $rc
fi

touch $LOG1_7
# Ignore RMAN-20215
log_list=$(/bin/ls $LOG1 $LOG1_0 $LOG1_4 $LOG1_4_1 $LOG1_7 2> /dev/null)
if ! egrep 'ORA-|TNS-' $log_list
then
   echo "SCRIPT SUCCESSFULLY COMPLETED. (rman_delete.sh)"
   exit 0
elif egrep RMAN-20503 $LOG1_7 > /dev/null; then
   echo "    Objects were crosschecked previously.  To delete expired "
   echo "    backups, run"
   echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID -e"
   echo "    and"
   echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID"
fi
echo "Exiting with error code = 1"
exit 1
