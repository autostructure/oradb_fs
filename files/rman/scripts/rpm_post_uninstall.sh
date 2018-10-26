#!/usr/bin/env ksh
#
#  file: /home/oracle/system/rman/rpm_post_uninstall.sh
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #3/13/2012   v12.2.1
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT
#  All Rights Reserved
#
#  US Government Users Restricted Rights - Use, duplication or
#
# Purpose:

#postun =========================================================
function error_exit {
   echo "ERROR $2" | tee -a $LOG
   exit $1
}
#postun =========================================================
function set_envars {
   echo "== %postun: Setting initial envars"
   mkdir /var/tmp/rman
   chmod 777 /var/tmp/rman
   export LOG=/var/tmp/rman/FS615.rman.backup.scripts-12.2-6.noarch.rpm.log
   touch $LOG
   chown oracle:dba $LOG
   . /tmp/rcat_12.2.0/rman_parameters.sh  # $SYSINFRA
   echo DOMAIN=$DOMAIN 2>&1 | tee -a $LOG
   echo "SHELL=$SHELL" >> $LOG
   echo "SHELL_ps_ef=$(ps -ef | grep $$)" >> $LOG
}
#postun =========================================================
function remove_signature_file {
   echo "== %postun Removing installation signature file" | tee -a $LOG
   SIGDIR="/home/oracle/system/signatures"
   SIGFILE="FS615.rman.backup.scripts.12.2-6.sig"

   if [[ -f $SIGDIR/$SIGFILE ]]; then
      rm $SIGDIR/$SIGFILE
      [[ $? != 0 ]] && error_exit 13 "Unable to remove installation signature file"
      echo ".. Removed installation signature file" | tee -a $LOG
   fi
   echo ".. done" | tee -a $LOG
}
function backout_mkdir_diag {
   echo "== %postun: backout the mkdir ORACLE_BASE/diag/bkp/rman/vote_disk" | tee -a $LOG
   if [[ -s /var/tmp/rman/rman_backout_mkdir_diag.sh ]]; then
      . /var/tmp/rman/rman_backout_mkdir_diag.sh 2>&1 | tee -a $LOG
   else
     echo ".. skipping empty backout file /var/tmp/rman/rman_backout_mkdir_diag.sh" | tee -a $LOG
   fi
   echo "rm -rf /home/grid/system/rman/" >> /var/tmp/rman/rman_backout_mkdir_diag.sh
   echo ".. %postun: as grid, backout the mkdir ORACLE_BASE/diag/bkp/rman/vote_disk" | tee -a $LOG
   chmod g+rx /tmp/rcat_12.2.0/* 2>> $LOG
   #OLD echo "Please do this in another window as your administrative user, and do this command" | tee -a $LOG
   #OLD echo '   echo ". ~/.bash_profile; ksh /var/tmp/rman/rman_backout_mkdir_diag.sh; /tmp/rcat_12.2.0/install_shield_cron.grid.sh -b" | (cd /tmp; sudo -u grid ksh) ' | tee -a $LOG
   echo ". ~/.bash_profile; ksh /var/tmp/rman/rman_backout_mkdir_diag.sh; /tmp/rcat_12.2.0/install_shield_cron.grid.sh -b" | (cd /tmp; sudo -u grid ksh) 
   echo  | tee -a $LOG
   #OLD echo "Press the Enter key to continue: "; read pause
}
#postun =========================================================
function restore_cron {
   echo "== %postun:  Restore catalog sync in cron" | tee -a $LOG
   if [[ -f /var/tmp/rman/crontab.rcat_wallet.before.tmp ]]; then
      crontab /var/tmp/rman/crontab.rcat_wallet.before.tmp
      echo ".. Restored the catalog sync in cron" | tee -a $LOG
   else
      echo ".. catalog restore not needed." | tee -a $LOG
   fi
}
#postun =========================================================
function backout_conditionally_rename_previous_wallets {
   echo "== %postun: Backout previous wallets, if any" | tee -a $LOG
   if [[ -f /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet ]]; then
      echo "cp -p /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/ewallet.p12" >> $LOG
      cp -p /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/ewallet.p12 || error_exit 21 "restore p12 wallet failed."
   fi
   if [[ -f /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet ]]; then
      echo "cp -p /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/cwallet.sso" >> $LOG
      cp -p /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/cwallet.sso || error_exit 22 "restore sso wallet failed."
   fi
}
#postun =========================================================
function backout_conditionally_create_rman_admin_wallet_directory {
   echo "== %postun: Backout rman admin wallet directory" | tee -a $LOG
   if [[ -f /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g/.previously_empty ]]; then
      rm -rf /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g/
      rm -rf /home/oracle/system/rman/admin.wallet/
   fi
   if [[ -d /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g ]]; then
      rm -rf /home/oracle/system/rman/admin.wallet
      mv /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g /home/oracle/system/rman/admin.wallet
   fi
}
#postun =========================================================
function backout_install_oraenv_usfs__to_sysinfra {
   echo "== %postun: Backout oraenv.usfs from sysinfra" | tee -a $LOG
   if [[ -f $SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname).pre_private_rcat_12g ]]; then
      file=$SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname)
      CKSUM_RMAN=$(cksum < $file)
      echo "CKSUM_RMAN=$CKSUM_RMAN" >> $LOG
      CKSUM_SYSINFRA=$(cksum < $SYSINFRA/oracle/common/db/oraenv.usfs)
      echo "CKSUM_SYSINFRA=$CKSUM_SYSINFRA" >> $LOG
      if [[ $CKSUM_RMAN == $CKSUM_SYSINFRA ]]; then
         echo ".. oraenv.usfs still matches cksum from /home/oracle, so restoring file" | tee -a $LOG
         cp -p $SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname).pre_private_rcat_12g $SYSINFRA/oracle/common/db/oraenv.usfs 2>> $LOG || error_exit 23 "couldn't restore oraenv.usfs in sysinfra"
      fi
   fi

   if [[ -f $SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname).pre_private_rcat_12g ]]; then
      file=$SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname)
      CKSUM_RMAN=$(cksum < $file)
      echo "CKSUM_RMAN=$CKSUM_RMAN" >> $LOG
      CKSUM_SYSINFRA=$(cksum < $SYSINFRA/oracle/common/db/usfs_local_sids)
      echo "CKSUM_SYSINFRA=$CKSUM_SYSINFRA" >> $LOG
      if [[ $CKSUM_RMAN == $CKSUM_SYSINFRA ]]; then
         echo ".. usfs_local_sids still matches cksum from /home/oracle, so restoring file" | tee -a $LOG
         cp -p $SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname).pre_private_rcat_12g $SYSINFRA/oracle/common/db/usfs_local_sids 2>> $LOG || error_exit 23 "couldn't restore usfs_local_sidsin sysinfra"
      fi
   fi
}
################################################################
# Main
################################################################
set_envars
#install_signature_file
   remove_signature_file
#copy_scripts_to_grid
   backout_mkdir_diag
#remove_rman_cron
   restore_cron
#conditionally_rename_previous_wallets
   backout_conditionally_rename_previous_wallets
#conditionally_create_rman_admin_wallet_directory
   backout_conditionally_create_rman_admin_wallet_directory
#install_oraenv_usfs__to_sysinfra
   backout_install_oraenv_usfs__to_sysinfra
echo "$(date) SUCCESSFULLY COMPLETED BACKOUT PROCEDURE" | tee -a $LOG
exit 0

