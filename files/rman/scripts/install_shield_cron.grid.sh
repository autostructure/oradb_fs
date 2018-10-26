#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/install_shield_cron.sh, ora, build6_1, build6_1a,1.2:11/12/11:21:04:56
#  VERSION:  1.2
#  DATE:  11/12/11:21:04:56
#
#  (C) COPYRIGHT International Business Machines Corp. 2003
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose: 
#

function set_env {
   mkdir /var/tmp/rman 2> /dev/null
   chmod 777 /var/tmp/rman 2> /dev/null
   export file_backout=/var/tmp/rman/.fs615_tsm_ora_client_cron.grid.backout
}
function func_modify_crontab {
   #INPUT:  shell_name
   print "Remove old temp file"
   if [[ ! -f $file_backout ]]; then crontab -l > $file_backout; fi
   file=/var/tmp/rman/.fs615_tsm_ora_client_cron.grid
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
      crontab $file || exit 1
   else
      echo "No change needed.  $shell_name already in cron table. (no error.)"
   fi
   
}

function func_main {
   # Voting disk
   export shell_name="0 5 * * * /home/grid/system/rman/voting_disk.sh"
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
if [[ $ID != grid ]]; then
   echo "Please log in as user grid"
   exit 1
fi

set_env
if [[ $1 == "-b" ]]; then # backout
   func_backout
else
   func_main   
fi

echo "SCRIPT COMPLETED SUCCESSFULLY"
