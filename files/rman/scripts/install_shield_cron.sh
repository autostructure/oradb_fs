#!/usr/bin/env ksh
#
#  install_shield_cron.sh
#  VERSION:  1.3
#  DATE:  01/13/16
#
#  (C) COPYRIGHT
#  All Rights Reserved
#  Licensed Materials
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA
#
# Purpose: 
#

while getopts ho:c: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export SIDS_NON_IMGCP="$OPTARG";;
      c) export SIDS_IMGCP="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
echo "SIDS_IMGCP=$SIDS_IMGCP"
echo "SIDS_NON_IMGCP=$SIDS_NON_IMGCP"
LOG=/opt/oracle/diag/bkp/rman/log/install_shield_cron.fix_full_sched.sh.log
{
   function set_env {
      mkdir /var/tmp/rman 2> /dev/null
      chmod 777 /var/tmp/rman
      export file_backout=/var/tmp/rman/.fs615_tsm_ora_client_cron.backout
   }
   function func_modify_crontab {
      #INPUT:  shell_name
      print "Remove old temp file"
      if [[ ! -f $file_backout ]]; then crontab -l > $file_backout; fi
      file=/var/tmp/rman/.fs615_tsm_ora_client_cron
      trap "rm -f $file 2> /dev/null" 0 1 2 15
      if [[ -f $file ]]; then
         rm -f $file 2> /dev/null
         if [[ $? != 0 ]]; then
            echo "ERROR: Couldn't remove file: $file"
            exit 1
         fi
      fi
   
      print "Conditionally adding this to crontab: '$shell_name'"
      crontab -l > $file
      cnt=$(grep "^[^#]*$(echo "$shell_name"|sed 's|\*|.|g')" $file | wc -l)
      if (( cnt < 1 )); then
         print "Append the file with the new entry"
         echo "$shell_name" >> $file
         print "Write the crontab"
         column -t $file | sed '/^#/{ s|  *| |g; }' > $file.column
         crontab $file.column || exit 1
      else
         echo "No change needed.  $shell_name already in cron table. (no error.)"
      fi
   }
   function build_backup_commands {
      echo "== Build backup commands"
      #export INCR_BU_CMD='/home/oracle/system/rman/rman_backup.sh -l4'
      #export FULL_BU_CMD='/home/oracle/system/rman/rman_backup.sh -l0'
      # If imgcp and nonimgcp are required, then build both varieties
      # If just one, then do just it
      FULL_BU_CMD=""
      INCR_BU_CMD=""
      if [[ -n $SIDS_NON_IMGCP ]]; then
         FULL_BU_CMD="$FULL_BU_CMD$SEMI/home/oracle/system/rman/rman_backup.sh -l0 -o '$SIDS_NON_IMGCP'"
         INCR_BU_CMD="$INCR_BU_CMD$SEMI/home/oracle/system/rman/rman_backup.sh -l4 -o '$SIDS_NON_IMGCP'"
         SEMI="; "
      fi
      if [[ -n $SIDS_IMGCP ]]; then
         FULL_BU_CMD="$FULL_BU_CMD$SEMI/home/oracle/system/rman/rman_backup.sh -i0 -l0 -o '$SIDS_IMGCP'"
         INCR_BU_CMD="$INCR_BU_CMD$SEMI/home/oracle/system/rman/rman_backup.sh -i0 -l4 -o '$SIDS_IMGCP'"
         SEMI="; "
      fi
      if [[ -z $FULL_BU_CMD ]]; then
         FULL_BU_CMD="/home/oracle/system/rman/rman_backup.sh -l0"
         INCR_BU_CMD="/home/oracle/system/rman/rman_backup.sh -l4"
      fi
   }
   function build_run_times {
      echo "== Build run times"
      delta_h=$(dd if=/dev/urandom  count=1 bs=1 2> /dev/null | od -i | head -1 | awk '{print $2 %  2 " "}')
      delta_m=$(dd if=/dev/urandom  count=1 bs=1 2> /dev/null | od -i | head -1 | awk '{print $2 % 60 " "}')
      #Do nightly (incremental) backups at 19:00
      #Do this archived logs backups at 5:00, 7:00...17:00
      arc_hours=$(comma=''; for base_hr in 5 7 9 11 13 15 17; do
              echo -e "$comma$((base_hr+delta_h))\c"
              comma=','
           done)
      arc_min=$delta_m
      echo "arc_min=$arc_min   arc_hours=$arc_hours"
   
      incr_hour=$((19+delta_h))
      incr_min=$delta_m
      echo "incr_min=$incr_min   incr_hour=$incr_hour"
   
      if [[ $SIDS_IMGCP == *filedb* ]]; then
         full_hr=10
      else
         full_hr=$((10 + $(dd if=/dev/urandom  count=1 bs=1 2> /dev/null | od -i | head -1 | awk '{print $2 % 14 " "}') ))
      fi
      full_min=$delta_m
      echo "full_min=$full_min   full_hr=$full_hr"
   }
   function purge_all_rman_jobs {
      echo "== Purge all rman jobs"
      file=/var/tmp/rman/.fs615_tsm_ora_client_cron_purge
      crontab -l > $file
      grep -Ev '^[^#]*/home/oracle/system/rman/|/var/spool/mail/oracle' $file > $file.tmp
      crontab $file.tmp
   }
   function add_comment_about_hourly_backups_are_as_needed {
      echo "== Add comment about hourly backups are as needed"
      file=/var/tmp/rman/.fs615_tsm_ora_client_cron.2
      crontab -l > $file
      if ! grep -q "#UNCOMMENT AS NEEDED .* /home/oracle/system/rman/rman_backup.sh -a" $file; then
         cp $file $file.tmp
         echo "#UNCOMMENT AS NEEDED $arc_min$arc_hours * * 1,2,3,4,5 /home/oracle/system/rman/rman_backup.sh -a" >> $file.tmp
         crontab $file.tmp
      else
         echo '.. found "#UNCOMMENT AS NEEDED"... so skipping the adding of a new comment'
      fi
   }
   
   function func_main {
      # Conditionally archive during the day
      export shell_name="10 * * * * /home/oracle/system/rman/oracle_cron_conditional_arch_backup.sh"
      func_modify_crontab

      ## Bihourly archives
      #export shell_name="$arc_min$arc_hours * * 1,2,3,4,5 /home/oracle/system/rman/rman_backup.sh -a"
      #func_modify_crontab
      add_comment_about_hourly_backups_are_as_needed
      
      # Nightly incremental
      export shell_name="$incr_min$incr_hour * * 1,2,3,4,5 $INCR_BU_CMD"
      func_modify_crontab
      
      # Weekend full
      export shell_name="$full_min $full_hr * * 6 $FULL_BU_CMD"
      func_modify_crontab
      
      # Delete
      export shell_name="0 16 * * 1 /home/oracle/system/rman/rman_delete.sh"
      func_modify_crontab
      
      # Delete mail messages
      export shell_name="0 0 * * 0  >/var/spool/mail/oracle"
      func_modify_crontab
   }
   function func_backout {
      if ! crontab $file_backout; then
        echo "ERROR: install_shield_cron.sh failed to backout"
        exit 1
      fi
   }
   export ID=$(id -u -n)
   if [[ $ID != oracle ]]; then
      echo "Please log in as user oracle"
      exit 1
   fi
   
   set_env
   if [[ $1 == "-b" ]]; then # backout
      func_backout
   else
      build_run_times
      purge_all_rman_jobs
      build_backup_commands
      func_main   
   fi
   echo "SCRIPT COMPLETED SUCCESSFULLY" >> $LOG
} 2>&1 | tee -a $LOG
if ! tail $LOG | grep "SCRIPT COMPLETED SUCCESSFULLY"; then
   echo "ERRORS occured.  Refer to above"
   exit 1
fi
exit 0
   
