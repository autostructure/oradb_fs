#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/oracle_cron_conditional_arch_backup.sh, ora, build6_1, build6_1a,1.1:11/12/11:20:59:29
#  VERSION:  1.1
#  DATE:  11/12/11:20:59:29
#
#  (C) COPYRIGHT International Business Machines Corp. 2003, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:

export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle"
   exit 1
fi

alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile
export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $LOG_DIR"; exit 1; fi
program="oracle_cron_conditional_arch_backup.sh"
export LOG=$LOG_DIR/$program.1.$(date "+%a").log  # %e is the day of the month (1..31)
if ! touch $LOG; then
   echo "ERROR: couldn't touch log file $LOG"
   exit 1
fi

unset bu_lev
export THRESHOLD=10 # By default, do backups is less than 10% is free
while getopts ht: option
do
   case "$option"
   in
      h) usage_exit;;
      t) export THRESHOLD="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

{
   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

   #############################################################################
   print "Step 32.1.1 - Verify user ID is oracle"
   #############################################################################
   function usage_exit {
      echo "Usage: oracle_cron_conditional_arch_backup.sh -t <THREASHOLD>"
      echo "   This script queries the free space of the diskgroups named like"
      echo "   %FLASH%.  If any diskgroup has less than 10% free, then all of the"
      echo "   archived logs of all databases are backedup and removed.  The "
      echo "   purpose is to prevent a database hang.  The default is 10% free."
      echo "   Specifying '-t 20' for exaple, will change the threashold to 20%"
      exit 1
   }

   export TMP=/tmp/rman
   mkdir $TMP 2> /dev/null
   chown oracle:dba $TMP
   chmod 700 $TMP
   if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $TMP"; exit 1; fi

   export RAO1=$TMP/$program.1.sh
   export RAO1_1=$TMP/$program.1_1.sh
   export LOG1_1=$LOG_DIR/$program.sh.1_1.log
   export LOG1_1_1=$LOG_DIR/$program.sh.1_1_1.$(date "+%a").log

   if ps -ef | egrep '[r]man_backup|[r]man target' | grep -v $program; then
      ps -ef | egrep '[r]man_backup|[r]man target' | grep -v $program
      echo "WARNING: there is an rman process currently running."
      echo "         Therefore, this process will abort and archivelogs will not be backedup."
      exit 1
   fi

   if ! ps -ef | grep -q 'pmon_+AS[M]'; then
      ps -ef | grep 'pmon_+AS[M]'
      echo "WARNING: ASM is not running.  No attempt will be made to backup archived redo logs if an OS file system is too full. Although it could, doing so in the future is unlikely."
      exit 1
   fi

   umask 077
   cat > $RAO1 <<EOF
#!/usr/bin/env ksh
      # Get the ASM SID on this node
      echo "ORACLE_SID=\$ORACLE_SID"
      echo "
      select NAME, FREE_MB/TOTAL_MB*100 PCT_FREE from v\\\$asm_diskgroup

      l
      r
      select 'TooFullDG='||NAME from v\\\$asm_diskgroup where (NAME like '%FLASH%' or NAME like '%FRA%') and FREE_MB/TOTAL_MB*100 < $THRESHOLD

      l
      r" | \
         sqlplus "/ as sysdba"
EOF
   chmod 700 $RAO1
   > $LOG1_1_1.semiphore
   export rc=0
   for ORACLE_SID in $(ps -ef | sed '/[p]mon_/!d; /+ASM/d; /MGMTDB/d; s|.*[p]mon_||;'); do
      ksh $RAO1 | tee -a $LOG | tee -a $LOG1_1 | tee $LOG1_1_1

      if grep ORA- $LOG1_1_1; then
         echo "ERROR: see $LOG1_1_1"
         exit 1
      fi
      if grep -q "TooFullDG=[^']" $LOG1_1_1; then 
         /home/oracle/system/rman/rman_backup.sh -a
         ((rc=rc+$?))
      fi
      echo "$rc" >> $LOG1_1_1.semiphore
   done
   export rc=$(tail -1 $LOG1_1_1.semiphore)
   echo "rc=$rc" >> $LOG
   echo "SCRIPT COMPLETED SUCCESSFULLY $(date)"
} 2>&1 | tee -a $LOG
echo "Log file for this script is $LOG"
if tail $LOG | grep -q "^SCRIPT COMPLETED SUCCESSFULLY"; then
   exit 0
else
   echo "ERROR: inspect logs from 'rman_backup.sh -a' for error specifics"
fi
