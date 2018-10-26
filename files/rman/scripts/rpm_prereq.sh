#!/usr/bin/env ksh
#
#  file: /home/oracle/system/rman/rpm_post_install.sh
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #7/13/2013  v12.2.7
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT
#  All Rights Reserved
#
#  US Government Users Restricted Rights - Use, duplication or
#
# Purpose:
#    Summary: RMAN Backup scripts for Oracle 12g in the US Forest Service
#    This package contains custom RMAN backup scripts for Oracle 12g 
#    servers in the USDA Forest Service environment.
#
# Changes:
#          Release 3.  find_as.sh updated.  Minor oratab grep update to repository_vote.sh.
# 2/25/13--Release 4.  Added device-to-diskgroup query into rman_backup.sh
# 5/02/13--Release 5.  Added wallet capabilities and a directory with the wallet.  Needs $RMAN_PWD
# 5/20/13--Release 6.  A. Normal envars
#                         $RMAN_PWD: RMAN catalog password
#                         $SYS_PWD: if filedb is running, then this is SYS's password
#                         $CDB_NAME: default is filedb, if found in `ps`, then alloc channel flat files installed
#                      B. Adding flow control envars
#                         $BYPASS_RMAN_PWD: if set, won't test $RMAN_PWD nore put in wallet
#                      C. Adding these files to /home/oracle/system/rman
#                            fs615_allocate_disk.ora
#                            fs615_allocate_sbt.ora
#                            fs615_release_disk.ora
#                         The 3 above are copied from these, depending on the environment
#                            fs615_allocate_disk.ora.MCI
#                            fs615_allocate_sbt.ora.MCI
#                            fs615_release_disk.ora.MCI
#                            fs615_allocate_disk.ora.PRP
#                            fs615_allocate_sbt.ora.PRP
#                            fs615_release_disk.ora.PRP
#                      D. Moved post and postun sections to external scripts due to unpredeictable envar resolutions.
# 12/10/13--Release 7. Fixed cold backups such that archived logs are not attempted to be backed up.

#pre ============================================================
function error_exit {
   echo "ERROR $2" | tee -a $LOG
   exit $1
}
#pre ============================================================
function set_envars {
   echo "== %pre:  Setting initial envars"
   mkdir /var/tmp/rman
   chmod 777 /var/tmp/rman
   export LOG=/var/tmp/rman/FS615.rman.backup.scripts-12.2-6.noarch.rpm.log
   touch $LOG
   chown oracle.dba $LOG
   export DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')
   export FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab
   export OLSNODES=$(find $(find /opt/grid -type d -name bin 2> /dev/null) -name olsnodes 2> /dev/null | head -1)
   echo "DOMAIN=$DOMAIN" 2>&1 | tee -a $LOG
   echo "FS615_ORATAB=$FS615_ORATAB" 2>&1 | tee -a $LOG
   echo "OLSNODES=$OLSNODES" >> $LOG
}
#pre ============================================================
function set_perms {
   echo "== %pre:  Set file permissions in /home/oracle/system/rman/"
   chown oracle:dba /home/oracle/system/rman/*

   chmod 700        /home/oracle/system/rman/*[^h]
   chown oracle:dba /home/oracle/system/rman/*[^h]
   chmod 500        /home/oracle/system/rman/*.sh
   chown oracle:dba /home/oracle/system/rman/*.sh
   chmod 500        /home/oracle/system/rman/*.ksh
   chown oracle:dba /home/oracle/system/rman/*.ksh
   chmod 500        /home/oracle/system/rman/*.sql
   chown oracle:dba /home/oracle/system/rman/*.sql
}
#pre ============================================================
function check_running_processes {
   echo "== %pre:  Precheck for running processes " | tee -a $LOG
   ps -ef | grep "[r]man_backup"         >> $LOG
   ps -ef | grep "[r]man_backup" | wc -l >> $LOG
   XX=$(ps -ef | grep "[r]man_backup" | wc -l)
   (( XX > 0 )) && error_exit 4 "RMAN backups are currently active"

   ps -ef | grep "[o]ra_pmon"         >> $LOG
   ps -ef | grep "[o]ra_pmon" | wc -l >> $LOG
   XX=$(ps -ef | grep "[o]ra_pmon" | wc -l)
   (( XX < 1 )) && error_exit 6 "Oracle must be running for this update"
   echo ".. no running processes precheck passed" | tee -a $LOG
}
#pre ============================================================
function check_oracle_software {
   echo "== %pre:  Checking for Oracle software" | tee -a $LOG
   [[ -f $FS615_ORATAB ]] || error_exit 7 "expected oratab to exist"
   echo ".. $FS615_ORATAB file found" | tee -a $LOG
}
#pre ============================================================
function remove_rman_cron {
   echo "== %pre:  Disable catalog sync in cron" | tee -a $LOG
   crontab -l > /dev/null || error_exit 8 "failed 'crontab -l'"
   if crontab -l | grep -Eq '/home/oracle/system/rman/'; then
      if [[ ! -f /var/tmp/rman/crontab.rcat_wallet.before.tmp ]]; then
         crontab -l > /var/tmp/rman/crontab.rcat_wallet.before.tmp
      fi
      crontab -l | grep -Ev 'rman_cron_resync.sh|rman_backup.sh.*-a' > /var/tmp/rman/crontab.rcat_wallet.no_sync.tmp
      crontab /var/tmp/rman/crontab.rcat_wallet.no_sync.tmp
      echo ".. Disabled the catalog sync in cron" | tee -a $LOG
   else
      echo ".. Disabling the catalog sync in cron not needed" | tee -a $LOG
   fi
}
#pre ============================================================
function test_rcat_password {
   echo '== %pre: Test catalog password in envar RMAN_PWD' | tee -a $LOG
   if [[ -z $BYPASS_RMAN_PWD ]]; then 
      crypt_pwd=$(echo "$RMAN_PWD" | openssl dgst -sha256)
      if [[ $crypt_pwd != "(stdin)= ab71ed7742a6c8a4b351b6354757434bad3732eb0a60084a79e7335fb62418b3" ]]; then
         echo "catalog password for RMAN repository to connect to database." | tee -a $LOG
         error_exit 27 'set the catalog password to a valid password in $RMAN_PWD'
      else
         echo "catalog password for RMAN repository is correct" | tee -a $LOG
         echo "" | tee -a $LOG
         echo "" | tee -a $LOG
      fi
   else
      echo ".. bypassing sinc \$BYPASS_RMAN_PWD is set" | tee -a $LOG
   fi
}
#pre ============================================================
function test_sys_password {
   echo '== %pre: Test user SYS password in envar SYS_PWD' | tee -a $LOG
   echo "CDB_NAME=$CDB_NAME" >> $LOG
   if [[ -n $CDB_NAME ]]; then 
      [[ -z $SYS_PWD ]] && error_exit 31 "SYS_PWD is not set. Set it to user SYS's password"
      export maxcnt=$(ksh $OLSNODES | wc -l)
      echo "maxcnt=$maxcnt" >> $LOG
      export cnt=1
      while ((cnt<=maxcnt)); do 
         (  export TNS_ADMIN=/home/oracle/system/admin.no_krb;
            tnsping $CDB_NAME$cnt; 2>&1 | tee -a $LOG | grep -- ^[A-Z][A-Z].-[0-9] )
         if [[ $? == 0 ]]; then
            error_exit 32 "'$CDB_NAME$cnt' fails tnsping"
         else
            echo ".. '$CDB_NAME$cnt' successfully tnspings" | tee -a $LOG
         fi
         (  export TNS_ADMIN=/home/oracle/system/admin.no_krb;
            (sleep 1; echo 'set head off'; echo 'select INSTANCE_NAME from v\$instance;'; echo exit) | sqlplus -L sys/$SYS_PWD@$CDB_NAME$cnt as sysdba;
             2>&1 | tee -a $LOG | grep -- -[0-9] )
         if [[ $? == 0 ]]; then
            echo "password for user SYS fails to connect to database '$CDB_NAME$cnt'" | tee -a $LOG
            error_exit 27 "password for user SYS fails to connect to database '$CDB_NAME$cnt'.  Recommended to log on each instance one by one and do 'ALTER USER SYS IDENTIFIED BY <password>;'"
         else
            echo "SYS password for $CDB_NAME$cnt" | tee -a $LOG
         fi
         ((cnt=cnt+1));
      done
   else
      echo ".. bypassing since \$CDB_NAME is not set" | tee -a $LOG
   fi
}
################################################################
# Main
################################################################
if [[ -n "$FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS" ]]; then
   echo "== %pre: \$ FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS is set, no configuration, just files installed" | tee -a $LOG
else
   echo "== %pre: \$ FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS is not set, continuing" | tee -a $LOG

   set_envars
   set_perms
   check_running_processes
   check_oracle_software
   remove_rman_cron
   test_rcat_password
   test_sys_password
fi
echo "$(date) successfully completed preinstall procedure" | tee -a $LOG
exit 0
