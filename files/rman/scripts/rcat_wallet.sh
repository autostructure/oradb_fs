#!/usr/bin/env ksh
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
#

#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function usage_exit {
   echo "
    ./rcat_wallet.sh"
    exit 1
}

#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function error_exit {
   echo "ERROR $2" | tee -a $LOG
   exit $1
}

#================================================================
# Set envars
#================================================================
function set_envars {
   echo "== Setting initial envars"
   mkdir /var/tmp/rman
   chmod 777 /var/tmp/rman
   export LOG=/var/tmp/rman/rcat_wallet.sh.log
   touch $LOG
   chown oracle:dba $LOG
   export DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')
   echo DOMAIN=$DOMAIN 2>&1 | tee -a $LOG
}

#================================================================
# Find all the ORACLE_HOME valuse
#================================================================
function find_all_OH {
   # Input: usfs_local_sids script
   # Output: $ALL_OH
   echo "== Find all values for ORACLE_HOME" 2>&1 | tee -a $LOG
   SIDS=$(/home/oracle/system/rman/usfs_local_sids)
   echo "SIDS=$SIDS" >> $LOG
   export ALL_OH=$(for ORACLE_SID in $SIDS; do
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
      . /home/oracle/system/oraenv.usfs > /dev/null
      echo $ORACLE_HOME
   done | sort -u)
   echo "ALL_OH=$ALL_OH" 2>&1 | tee -a $LOG
   if [[ ${#ALL_OH} == 0 ]]; then
      error_exit 1 "could not determine all of the ORACLE_HOME values"
   fi
}

#================================================================
# Find the maximum version from an Oracle Home
#================================================================
function find_max_oracle_SW_version {
   # INPUT: $ALL_OH
   # OUTPUT:  Envars of   MAX_OH and MAX_VER
   echo "== Find Maximum Oracle Software version" | tee -a $LOG
   MAX_COMPVER=0.0
   for ORACLE_HOME in $ALL_OH; do
      VER=$(
         export ORACLE_HOME=$ORACLE_HOME
         export PATH=$ORACLE_HOME/bin:$PATH
         export LD_LIBRARY_PATH=$ORACLE_HOME/lib
         echo | sqlplus /nolog 2>&1 | tee /var/tmp/rman/rcat.sqlplus.version.$$.log | sed '/ Release /!d;s|.*Release.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*|\1|' | tail -1 )
      echo "VER=$VER" >> $LOG
      # Remove all but the left most decimal point, i.e. change 10.2.0.2 to 10.202
      COMPVER=$( echo $VER | sed 'h;s|^[0-9][0-9]*\.\(.*\)|\1|;s|\.||g;x;s|^\([0-9][0-9]*\.\).*|\1|;G;s|\.[^[0-9]|.|g' )
      echo "COMPVER=$COMPVER" >> $LOG
      if (( $(expr $MAX_COMPVER '<' $COMPVER) == 1 )); then # was bc
         MAX_OH=$ORACLE_HOME
         MAX_VER=$VER
         MAX_COMPVER=$COMPVER
      fi
      echo "MAX_VER=$MAX_VER" >> $LOG
      echo "MAX_OH=$MAX_OH" >> $LOG
   done
   export MAX_OH=$(sed '/MAX_OH=/!d;s|.*=||' $LOG | tail -1)
   export MAX_VER=$(sed '/MAX_VER=/!d;s|.*=||' $LOG | tail -1)
   echo "MAX_OH=$MAX_OH" | tee -a $LOG
   echo "MAX_VER=$MAX_VER" | tee -a $LOG
   echo "MAX_COMPVER=$MAX_COMPVER" >> $LOG
   if [[ ! -d $MAX_OH ]]; then
      error_exit 2 "ORACLE_HOME with max version is not a real directory"
   fi
}

#================================================================
# Check if any backup process are currently running
# For Oracle servers, the database must be up
#================================================================
function check_running_processes
{
   echo "== Precheck for running processes " | tee -a $LOG
   XX=$(ps -ef | grep "[r]man_" | wc -l)
   (( $XX > 0 )) && error_exit 4 "RMAN backups are currently active"

   XX=$(ps -ef | grep "[l]inux_incremental_backup" | wc -l)
   (( $XX > 0 )) && error_exit 5 "TSM backups are currently active"

   XX=$(ps -ef | grep "[o]ra_pmon" | wc -l)
   (( $XX < 1 )) && error_exit 6 "Oracle must be running for this update"
   echo ".. no running processes precheck passed" | tee -a $LOG
}

#================================================================
# Check the Oracle configuration
#================================================================
function check_oracle_software
{
   echo "== Checking for Oracle software" | tee -a $LOG
   [[ -f /etc/oratab ]] || error_exit 7 "expected /etc/oratab to exist"
   echo ".. /etc/oratab file found" | tee -a $LOG
}

#================================================================
# Check the software version
#================================================================
function check_SW_version {
   # INPUT: $MAX_COMPVER - 6 point integer decimal representation
   #        $MAX_VER     - human readable version
   # OUTPUT: sometimes $MIN_ACCEPTALE_VER and $MIN_ACCEPTABLE_COMPVER
   echo "== Checking Oracle software version" | tee -a $LOG
   if [[ -z $MIN_ACCEPTALE_VER || -z $MIN_ACCEPTABLE_COMPVER ]]; then
      MIN_ACCEPTALE_VER=12.2.0.1
      MIN_ACCEPTABLE_COMPVER=12.201
   fi
   echo "== Check software minimal requirements" | tee -a $LOG
   if (( $(expr $MAX_COMPVER '<' $MIN_ACCEPTABLE_COMPVER) == 1 )); then # was bc
      error_exit 3 "Oracle software found to be $MAX_VER but needs to be at least $MIN_ACCEPTALE_VER"
   fi
   echo ".. Pass" | tee -a $LOG
}

#================================================================
# Check for dsmc schedules
#================================================================
function check_dsmc_schedules
{
   echo "== Checking for TSM schedules for Oracle jobs" | tee -a $LOG
   dsmc q sched >> $LOG 2>&1
   num=$(dsmc q sched | grep ORA | wc -l)
   [[ -z "$MAX_TSM_SCHED" ]] && export MAX_TSM_SCHED=3
   ((num<MAX_TSM_SCHED)) && error_exit 9 "dsmc has fewer than $MAX_TSM_SCHED Oracle TSM schedules."
}

#================================================================
# Prompt user for RMAN catalog password
#================================================================
function test_rcat_password {
   echo '== Test catalog password in $RMAN_PWD' | tee -a $LOG
   crypt_pwd=$(echo "$RMAN_PWD" | openssl dgst -sha256)
   if [[ $crypt_pwd != "(stdin)= ab71ed7742a6c8a4b351b6354757434bad3732eb0a60084a79e7335fb62418b3" ]]; then
      echo "catalog password for RMAN repository to connect to database." | tee -a $LOG
      error_exit 27 'set the catalog password to a valid password in $RMAN_PWD'
   else
      echo "catalog password for RMAN repository is correct" | tee -a $LOG
      echo "" | tee -a $LOG
      echo "" | tee -a $LOG
   fi
}
#================================================================
#
#================================================================
function tnsping_RMAN_CATALOG_POOL {
   #INPUT RMAN_CATALOG RMAN_CATALOG_POOL (from ~oracle/.bash_profile)
   echo "== Trying to contact the RMAN repositories with tnsping" | tee -a $LOG
   for tnsalias in $( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u); do 
      echo "tnsping $tnsalias}" >> $LOG
      (  export TNS_ADMIN=/home/oracle/system/rman/admin
         export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH
         tnsping $tnsalias) 2>&1 | tee -a $LOG | grep -- TNS-[0-9]
      rc=$?
      echo "rc=$rc" >> $LOG
      ((rc==0)) && error_exit 15 "As user oracle (ORACLE_HOME=$ORACLE_HOME), this command failed:  tnsping $tnsalias"
      echo >> $LOG
   done
   echo ".. all tnsping commands succeeded" | tee -a $LOG
}

#================================================================
#
#================================================================
function connect_RMAN_CATALOG_POOL {
   #INPUT RMAN_CATALOG RMAN_CATALOG_POOL (from ~oracle/.bash_profile)
   echo "== Trying to conect to the RMAN repositories schemas" | tee -a $LOG
   for tnsalias in $( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u); do 
      echo "sqlplus -L \$RMAN_SCHEMA@$tnsalias}" >> $LOG
      echo "sqlplus -L "echo $RMAN_SCHEMA")@$tnsalias" >> $LOG
      (  export TNS_ADMIN=/home/oracle/system/rman/admin
         export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:\$PATH
         (sleep 1; echo "$RMAN_PWD"; sleep 1; echo exit) \
            | sqlplus -L $RMAN_SCHEMA@$tnsalias) 2>&1 | tee -a $LOG | grep -- -[0-9]
      rc=$?
      echo "rc=$rc" >> $LOG
      ((rc==0)) && error_exit 17 "As user oracle (ORACLE_HOME=$ORACLE_HOME), this command failed:  sqlplus -L $RMAN_SCHEMA@$tnsalias"
   done
   echo ".. all sqlplus commands succeeded" | tee -a $LOG
}

#================================================================
# Create the RMAN directory for TNS files
#================================================================
function conditionally_create_rman_admin_wallet_directory
{
   echo "== Create the RMAN wallet directory for TNS files" | tee -a $LOG
   export ORACLE_HOME=$MAX_OH
   export TNS_ADMIN=$ORACLE_HOME/network/admin
   mkdir /home/oracle/system/ 2> /dev/null
   chown oracle:dba /home/oracle/system/
   mkdir /home/oracle/system/rman/ 2> /dev/null
   chown oracle:dba /home/oracle/system/rman/
   [[ ! -d $TNS_ADMIN ]] && error_exit 7 "'\$TNS_ADMIN' ($TNS_ADMIN) is not a directory"
   if [[ ! -d /home/oracle/system/rman/admin.wallet ]]; then
      mkdir /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g
      touch /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g/.previously_empty
   fi
   if [[ ! -d /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g ]]; then
      cp -rp /home/oracle/system/rman/admin.wallet /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g
   fi
   if [[ ! -d /home/oracle/system/rman/admin.wallet ]]; then
      mkdir /home/oracle/system/rman/admin.wallet
      cd /home/oracle/system/rman/admin.wallet
      ln -sf $TNS_ADMIN/tnsnames.ora /home/oracle/system/rman/admin.wallet
      echo "WALLET_LOCATION =
         (SOURCE =
           (METHOD = FILE)
           (METHOD_DATA = (DIRECTORY = /home/oracle/system/rman/admin.wallet))
         )
SQLNET.WALLET_OVERRIDE = TRUE" > /home/oracle/system/rman/admin.wallet/sqlnet.ora
   fi
   chown -R oracle:dba /home/oracle/system/rman/admin.wallet
}

#================================================================
#
#================================================================
function conditionally_rename_previous_wallets {
   echo "== Rename previous wallets, if any" | tee -a $LOG
   chmod 700 /home/oracle/system/rman/admin.wallet || error_exit 18 "chmod failed"
   if [[ -f /home/oracle/system/rman/admin.wallet/ewallet.p12 ]]; then
      if [[ ! -f /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet ]]; then
         echo "cp -p /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet" >> $LOG
         mv /home/oracle/system/rman/admin.wallet/ewallet.p12 /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet || error_exit 19 "rename p12 wallet failed."
      else
         rm -f /home/oracle/system/rman/admin.wallet/ewallet.p12 || error_exit 20 "rename p12 wallet failed."
      fi
   fi
   if [[ -f /home/oracle/system/rman/admin.wallet/cwallet.sso ]]; then
      if [[ ! -f /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet ]]; then
         echo "cp -p /home/oracle/system/rman/admin.wallet/cwallet.sso /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet" >> $LOG
         mv /home/oracle/system/rman/admin.wallet/cwallet.sso /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet || error_exit 25 "rename sso wallet failed."
      else
         rm -f /home/oracle/system/rman/admin.wallet/cwallet.sso || error_exit 26 "rename sso wallet failed."
      fi
   fi
} 

#================================================================
#
#================================================================
function backout_conditionally_rename_previous_wallets {
   echo "== Backout previous wallets, if any" | tee -a $LOG
   if [[ -f /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet ]]; then
      echo "cp -p /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/ewallet.p12" >> $LOG
      cp -p /home/oracle/system/rman/admin.wallet/ewallet.p12.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/ewallet.p12 || error_exit 21 "restore p12 wallet failed."
   fi
   if [[ -f /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet ]]; then
      echo "cp -p /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/cwallet.sso" >> $LOG
      cp -p /home/oracle/system/rman/admin.wallet/cwallet.sso.pre_rcat_wallet /home/oracle/system/rman/admin.wallet/cwallet.sso || error_exit 22 "restore sso wallet failed."
   fi
}

#================================================================
#
#================================================================
function func_randpass {
   echo "== Generate wallet password" | tee -a $LOG
   export randpass=a$(dd if=/dev/urandom  count=14 bs=1 2>/dev/null | \
                      od -h | head -1 | sed 's|^00* ||;s| ||g')
   echo "This password is wallet password.  It is not recorded anywhere else."
   echo "Please record it in the password database now:   $randpass"
}


#================================================================
#
#================================================================
function create_wallet {
   echo "== Create wallet" | tee -a $LOG
   echo "ls -al /home/oracle/system/rman/admin.wallet/" >> $LOG
   ls -al /home/oracle/system/rman/admin.wallet/ >> $LOG
   (  cd /home/oracle/system/rman/admin.wallet/
      export TNS_ADMIN=/home/oracle/system/rman/admin
      export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH
      (sleep 1; echo -e "$randpass\n$randpass") | mkstore -wrl $PWD -create 
    ) 2>&1 | strings | tee -a $LOG | grep -- -[0-9]
    rc=$?
    ((rc==0)) && error_exit 24 "wallet creation failed"
}

#================================================================
#
#================================================================
function add_credentials_to_wallet {
   echo "== Add credentials to the wallet" | tee -a $LOG
   for tnsalias in $( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u); do
      echo "mkstore creadCredential" >> $LOG
      (
         cd /home/oracle/system/rman/admin.wallet/
          export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
          export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH
          echo mkstore -wrl $PWD -createCredential $tnsalias $RMAN_SCHEMA \$RMAN_PWD
          (sleep 1; echo "$randpass") | \
             mkstore -wrl $PWD -createCredential $tnsalias $RMAN_SCHEMA $RMAN_PWD
      ) 2>&1 | strings | tee -a $LOG | grep -- -[0-9]
      rc=$?
      [[ $rc == 0 ]] && error_exit 24 "failed: mkstore -wrl /home/oracle/system/rman/admin.wallet -createCredential $tnsalias $RMAN_SCHEMA \$RMAN_PWD"
      echo >> $LOG
   done
   chmod 600 -R /home/oracle/system/rman/admin.wallet/
}

#================================================================
# Determine list of TNS aliases comprising the pool of remote servers
#================================================================
function remove_rman_cron {
   echo "== Disable catalog sync in cron" | tee -a $LOG
   if crontab -l | grep -q 'rman_cron_resync.sh'; then
      if [[ ! -f /var/tmp/rman/crontab.rcat_wallet.before.tmp ]]; then
         crontab -l > /var/tmp/rman/crontab.rcat_wallet.before.tmp
      fi
      crontab -l | grep -v 'rman_cron_resync.sh' > /var/tmp/rman/crontab.rcat_wallet.no_sync.tmp
      crontab /var/tmp/rman/crontab.rcat_wallet.no_sync.tmp
      echo ".. Disabled the catalog sync in cron" | tee -a $LOG
   else
      echo ".. Disabling the catalog sync in cron not needed" | tee -a $LOG
   fi
}

#================================================================
# Determine list of TNS aliases comprising the pool of remote servers
#================================================================
function restore_cron {
   echo "== Restore catalog sync in cron" | tee -a $LOG
   if [[ -f /var/tmp/rman/crontab.rcat_wallet.before.tmp ]]; then
      crontab /var/tmp/rman/crontab.rcat_wallet.before.tmp
      echo "== Restored the catalog sync in cron" | tee -a $LOG
   else
      echo ".. catalog restore not needed." | tee -a $LOG
   fi
}

#================================================================
#
#================================================================
function kill_dsmcad {
   echo "== Kill dsmcad daemon" | tee -a $LOG
   if ps -ef | grep [d]smcad >> $LOG; then
      kill $(ps -ef | grep [d]smcad | awk '{print $2}') 2>&1 | tee -a $LOG
   fi
}

#================================================================
#
#================================================================
function start_dsmcad {
   echo "== Start dsmcad daemon" | tee -a $LOG
   /usr/bin/dsmcad 2>&1 | tee -a $LOG
}

#================================================================
# Install the Inventory signature file
#================================================================
function install_signature_file
{
#HACK
   echo "== Installing signature file" | tee -a $LOG
   SIGDIR="/home/oracle/system/signatures"
   SIGFILE="private_rman_catalog_12.2.0.sig"

   mkdir -p $SIGDIR
   [[ $? != 0 ]] && error_exit 11 "Unable to create signature directory"

   echo "private_rman_catalog_12.2.0.sig,129,RMAN Private Catalog 12.2.0,/var/lpp/private_rman_catalog_12.2.0.sig,Linux" > $SIGDIR/$SIGFILE

   [[ $? != 0 ]] && error_exit 12 "Unable to create signature file"
   chmod 755 $SIGDIR/$SIGFILE
   echo ".. done" | tee -a $LOG
}

#================================================================
# Remove the Inventory signature file
#================================================================
function remove_signature_file
{
#HACK
   echo "== Removing signature file" | tee -a $LOG
   SIGDIR="/home/oracle/system/signatures"
   SIGFILE="private_rman_catalog_12.2.0.sig"

   if [[ -f $SIGDIR/$SIGFILE ]]; then
      rm $SIGDIR/$SIGFILE
      [[ $? != 0 ]] && error_exit 13 "Unable to remove signature file"
      echo ".. Removed signature file" | tee -a $LOG
   fi
   echo ".. done" | tee -a $LOG
}

#================================================================
# Backout
#================================================================
function backout {
   remove_signature_file
   restore_cron
   backout_conditionally_rename_previous_wallets
   # backout conditionally_create_rman_admin_wallet_directory
      if [[ -f /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g/.previously_empty ]]; then
         rm -rf /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g/
         rm -rf /home/oracle/system/rman/admin.wallet/
      fi
      if [[ -d /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g ]]; then
         rm -rf /home/oracle/system/rman/admin.wallet
         mv /home/oracle/system/rman/admin.wallet.pre_private_rcat_12g /home/oracle/system/rman/admin.wallet
      fi

   echo "$(date) SUCCESSFULLY COMPLETED BACKOUT PROCEDURE" | tee -a $LOG
   exit 0
#HACK
start_dsmcad
}

################################################################
# MAIN
################################################################
set_envars {
echo "$(date) Begin $0 'RMAN priviate catalog'" >> $LOG
MYID=$(id -u -n)
[[ $MYID != oracle ]] && error_exit 15 "This script must be executed as oracle"
if [[ "$1" != "-b" && -n "$1" ]]; then
   script_usage
   error_exit 16 "unknown commandline option"
   exit 16
fi
if [[ "$1" == "-b" ]]; then
   backout
fi

find_all_OH 
find_max_oracle_SW_version
check_oracle_software
check_SW_version
check_dsmc_schedules
kill_dsmcad
check_running_processes
test_rcat_password
tnsping_RMAN_CATALOG_POOL
connect_RMAN_CATALOG_POOL
conditionally_create_rman_admin_wallet_directory
conditionally_rename_previous_wallets
func_randpass
create_wallet
add_credentials_to_wallet
start_dsmcad
echo early exit; exit 99; # HACK
remove_rman_cron
install_signature_file
