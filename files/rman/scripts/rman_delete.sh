#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_delete.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:56
#  VERSION:  1.4
#  DATE:  04/24/13
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
# . /etc/profile.d/oracle.sh
alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
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
#export LOG1_1=$LOG_DIR/$program.1_1.$$.log
#export LOG1_2=$LOG_DIR/$program.1_2.$$.log
#export LOG1_3=$LOG_DIR/$program.1_3.$$.log
#export LOG1_4=$LOG_DIR/$program.1_4.$$.log
export LOG1_4_1=$LOG_DIR/$program.1_4_1.$$.log
#export LOG1_5=$LOG_DIR/$program.1_5.$$.log
#export LOG1_6=$LOG_DIR/$program.1_6.$$.log
export LOG1_7=$LOG_DIR/$program.1_7.$$.log


if [[ -z "$RMAN_REDUNDANCY" ]]; then
   # Number of copies of a backup.
   # 4 weekly full backups equates to 1 month of backups
   export RMAN_REDUNDANCY=4
   if [[ $(hostname) == "slmciordb025" || $(hostname) == "slprpordb009" ]]; then
      export RMAN_REDUNDANCY=2
   fi
fi

if [[ -z "$VOTING_DISK_KEEP_DAYS" ]]; then
   export VOTING_DISK_KEEP_DAYS=7  #Number of days a voting disk backup is not deleted.
fi


function usage_exit
{
   echo "Usage:  rman_delete.obsolete.sh {-o[ORACLE_SID]} -bN {-p} -rM"
   echo "        Default removes full backups more with more than $RMAN_REDUNDANCY copies."
   echo "          -rM sets redundnace to M copies"
   echo "          -o, Value for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -p preview, no backup sets removed"
   echo "          -e delete expired backups"
   exit 1
}
unset ORACLE_SID
while getopts hepo:r: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      p) export preview="-p";;
      e) export delete_expired="-e";;
      r) export RMAN_REDUNDANCY="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

{
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
   chown oracle:dba $LOG1
   #exit
   
   # Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
   . /home/oracle/system/rman/build_SEND_cmd.sh
   export ALLOCATE_SBT_CHANNELS="
       allocate channel for maintenance device type 'sbt_tape';
       $send_cmd
       "
   echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"
   
   umask 077
   cat > $RAO1 <<EOF2
      export ORACLE_SID=$ORACLE_SID
      export preview=$preview
      export ALLOCATE_SBT_CHANNELS="$ALLOCATE_SBT_CHANNELS"
   
      export delete_expired=$delete_expired
      echo "ORACLE_SID=\$ORACLE_SID"
      echo "delete_expired=$delete_expired"
      echo "SHELL=\$SHELL"
      echo "RMAN_SCHEMA=\$RMAN_SCHEMA"
      echo "preview=\$preview"
      echo "ALLOCATE_SBT_CHANNELS=\$ALLOCATE_SBT_CHANNELS"

      export NLS_LANG=american
      export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
    
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=\$ORACLE_HOME/bin:$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
   
      echo "\\$\\$=\$\$"
      ps -ef|grep \$\$
      env | grep RMAN
   
      rm -f $LOG1_0
      echo "
         allocate channel for maintenance device type disk;
         $ALLOCATE_SBT_CHANNELS
    
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
            echo SCHEMA=\$SCHEMA
            echo "
       Deleting expired backups can take hours.  The TCP connection to NetBackup 
       can time out, which is one to four hours.  This delay is especially long if
       the repository at '\$RMAN_CATALOG' hasn't done this:
          execute dbms_utility.analyze_schema('\$SCHEMA', 'COMPUTE');"
            echo "Deleting expired backups. \$(date)"
            rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
   
            # This nocatalog command gets an ORA-00235
            # rman target / nocatalog \
            #    cmdfile=$RAO1_0 2>&1 | tee $LOG1_0
            exit 0
         fi
      fi
   
      #echo "Crosschecking old backups. \$(date)"
      #echo "
      #   allocate channel for maintenance device type disk;
      #   \$ALLOCATE_SBT_CHANNELS
      #
      #   crosscheck backup of controlfile database spfile archivelog all;
      #   crosscheck copy;
      #   release channel;
      #" > $RAO1_4
      #   rman targetcatalog \$RMAN_SCHEMA@\$RMAN_CATALOG \
      #   cmdfile=$RAO1_4 2>&1 | tee -a $LOG1_4
   
      echo "resync catalog;" > $RAO1_4_1
      rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_4_1 2>&1 | tee -a $LOG1_4_1
      if [[ "\$preview" == "-p" ]]; then
        echo "Preview mode only, not deleting anything." | tee $LOG1_7
        exit 1
      fi
   
      echo "
         allocate channel for maintenance device type disk;
         $ALLOCATE_SBT_CHANNELS
            delete obsolete redundancy=$RMAN_REDUNDANCY;
       " > $RAO1_7
       cat $RAO1_7
       rman target / catalog /@$RMAN_CATALOG \
             cmdfile=$RAO1_7 2>&1 | \
             tee -a $LOG1_7
EOF2
   
   chmod 700 $RAO1
   chown oracle.dba $RAO1
   ksh $RAO1
   if [[ -s $LOG1_0 ]]; then
      if grep ^ORA- $LOG1_0; then
         echo "ERROR: Deleting expired backups from RMAN failed. $(date)"
         exit 1
      fi
      echo "SCRIPT SUCCESSFULLY COMPLETED. $(date)"
      exit 0
   else
      echo "Removing old voting disk backups $(date)"
echo sleep 5; sleep 5 #TODO
      echo "Doing: find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime +$VOTING_DISK_KEEP_DAYS -name \"vote_disk__*\""
      find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$VOTING_DISK_KEEP_DAYS" -name "vote_disk__*"
      echo "Removing the above voting disk files"
      rm -f $(find /opt/oracle/diag/bkp/rman/vote_disk/ -mtime "+$VOTING_DISK_KEEP_DAYS" -name "vote_disk__*")
      
      echo
      echo
   
      /home/oracle/system/rman/rman_cron_resync.sh
      rc=$?
      if [[ $rc != 0 ]]; then
         echo "ERROR: one or more resynchronizations failed."
         date
         exit $rc
      fi
      
      touch $LOG1_7 $LOG1_4 $LOG1_4_1
      # Ignore RMAN-20215
      if ! grep ORA- $LOG1_7 $LOG1_4 $LOG1_4_1
      then
         echo "SCRIPT SUCCESSFULLY COMPLETED. (rman_delete.sh) $(date)"
         exit 0
      elif egrep RMAN-20503 $LOG1_7 > /dev/null; then
         echo "    Objects were crosschecked previously.  To delete expired  $(date)"
         echo "    backups, run"
         echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID -e"
         echo "    and"
         echo "       /home/oracle/system/rman/rman_delete.sh -o$ORACLE_SID"
      fi
      echo "Exiting with error code = 1 $(date)"
      exit 1
   fi
} 2>&1 | tee -a $LOG1
tail $LOG1 | grep -q "SCRIPT SUCCESSFULLY COMPLETED." || exit 1
exit 0
