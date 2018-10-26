#!/usr/bin/env ksh
#
#  File: cf_snapshot_in_recovery.sh
#  Version: 1.1
#  Date: 04/10/14
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT 2012
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by USDA Forest Service
#
# Purpose:
#    In a restore preview, look for these historically significant errors:
#       no backup of log thread 1 seq 9 lowscn 546716 found to restore
#    and
#       archive logs generated after SCN 3593698 not found in repository
#

#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function usage_exit {
   echo "./cf_snapshot_in_recovery.sh -o <sid>"
   echo "Usage:  rman_restore_pitr.sh {-o[ORACLE_SID]}"
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   exit 1
}
#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function error_exit {
   echo "  ERROR $2" | tee -a $LOG
   exit $1
}
#================================================================
# Set envars
#================================================================
function set_envars {
   echo "==Setting initial envars"
   # $PATH $LOG_DIR $LOG $FS615_ORATAB $DB_NAME $DOMAIN $OLSNODES $CEMUTLO $HOSTNAME $SYSINFRA
   # Only need $FS615_ORATAB $DB_NAME
   unset LOG
   . /home/oracle/system/rman/rman_parameters.sh
}
#================================================================
# Check required files
#================================================================
function check_required_files {
   echo "== Check required files" 2>&1 | tee -a $LOG
   [[ -s /home/oracle/system/rman/rman_restore_pitr.sh ]] || \
      error_exit 13 "missing file /home/oracle/system/rman/rman_restore_pitr.sh"
   if [[ ! -s /home/oracle/system/rman/usfs_local_sids ]]; then
      error_exit 13 "missing /home/oracle/system/rman/usfs_local_sids"
   fi
   if [[ ! -s /home/oracle/system/oraenv.usfs ]]; then
      error_exit 13 "/home/oracle/system/oraenv.usfs"
   fi
   echo ".. Pass" | tee -a $LOG
}
#================================================================
#
#================================================================
   function sub_query_db_recovery_file_dest {
      # Input: $ORACLE_HOME
      # Output: $DBID
      echo "   == Query recovery area" 2>&1 | tee -a $LOG
      export ORACLE_SID
      echo "ORACLE_SID=$ORACLE_SID" >> $LOG 2>&1
      output=$(
         # export ORACLE_SID=$ORACLE_SID;
         . /home/oracle/system/oraenv.usfs;
         PATH=$ORACLE_HOME/bin:$PATH;
         echo "SELECT 'db_recovery_file_dest='||value FROM v\$parameter WHERE name = 'db_recovery_file_dest'
   
         l
         r
         exit" | sqlplus / as sysdba 2>&1 | tee -a $LOG;
      echo "ending output" | tee -a $LOG )
      echo "$output" | grep -- [A-Z][A-Z][A-Z0-9]-[0-9];
      if echo "$output" | grep -q -- [A-Z][A-Z][A-Z0-9]-[0-9]; then
         error_exit 16 "could not query db_recovery_file_dest"
      fi
      parm__db_recovery_file_dest=$(echo "$output" | sed '/^db_recovery_file_dest=/!d; s|^db_recovery_file_dest=||')
      echo "   .. db_recovery_file_dest=$parm__db_recovery_file_dest"
   }
   function sub_func_configure {
      echo "   == Change controlfile snapshot destination" 2>&1 | tee -a $LOG
      export ORACLE_SID
      echo "ORACLE_SID=$ORACLE_SID" >> $LOG 2>&1
      export CMDFILE=$LOG.configure.rmn
      cat > $CMDFILE <<EOF
         CONFIGURE SNAPSHOT CONTROLFILE NAME TO '$parm__db_recovery_file_dest/snapcf_$DB_NAME.f';
EOF
      chmod 700        $CMDFILE
      echo "   .. Running $(cat $CMDFILE)" | tee -a $LOG
      (  export ORACLE_SID=$ORACLE_SID;
         . /home/oracle/system/oraenv.usfs;
         PATH=$ORACLE_HOME/bin:$PATH;
         export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
         rman target / cmdfile=$CMDFILE
      ) | tee $LOG.func_configure.$ORACLE_SID.log >> $LOG
      grep RMAN-[0-9][0-9][0-9][0-9][0-9] $LOG.func_configure.$ORACLE_SID.log && \
         error_exit 5 "RMAN ERROR setting CONFIGURE SNAPSHOT CONTROLFILE NAME (is the database fully OPEN)"
      grep ORA-[0-9][0-9][0-9][0-9][0-9] $LOG.func_configure.$ORACLE_SID.log && \
         error_exit 15 "ORA ERROR setting CONFIGURE SNAPSHOT CONTROLFILE NAME"
      echo "   Configure snapshot log='$LOG.func_configure.$ORACLE_SID.log'"
   }
function loop_every_SID {
   for ORACLE_SID in $SIDS; do
      export ORACLE_SID
      echo "ORACLE_SID=$ORACLE_SID" | tee -a $LOG
      sub_query_db_recovery_file_dest
      sub_func_configure
   done
}
#================================================================
#================================================================
### MAIN
set_envars
check_required_files
# getops can't be done in a function
   unset ORACLE_SID
   while getopts o:h option
   do
      case "$option"
      in
         h) usage_exit;;
         o) export SIDS="$OPTARG";;
        \?)
            eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
            usage_exit;;
      esac
   done
   if [[ -z $SIDS ]]; then SIDS=$(/home/oracle/system/rman/usfs_local_sids); fi
loop_every_SID
echo "SCRIPT COMPLETED SUCCESSFULLY $(date)" | tee -a $LOG
