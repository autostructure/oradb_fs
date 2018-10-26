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
# Changes:

#post ===========================================================
function error_exit {
   echo "ERROR $2" | tee -a $LOG
   exit $1
}
#post ===========================================================
function set_envars {
   echo "== %post: Setting initial envars"
   mkdir /var/tmp/rman 2> /dev/null
   chmod 777 /var/tmp/rman
   export LOG=/var/tmp/rman/FS615.rman.backup.scripts-12.2-6.noarch.rpm.log
   export LOG=/var/tmp/rman/private_rcat.log
   touch $LOG
   chown oracle:dba $LOG
   . /home/oracle/system/rman/rman_parameters.sh  # $SYSINFRA
   echo DOMAIN=$DOMAIN 2>&1 | tee -a $LOG
   echo HOSTNAME=$HOSTNAME 2>&1 | tee -a $LOG
   echo "SHELL=$SHELL" >> $LOG
   echo "SHELL_dollar_dollar=$(ps $$)" >> $LOG
   echo "SHELL_ps_ef=$(ps -ef | grep "$ID  *$$" )" >> $LOG
   echo "CEMUTLO=$CEMUTLO" >> $LOG
   echo "OLSNODES=$OLSNODES" >> $LOG
   [[ ! -d $SYSINFRA/oracle/common/db/ ]] &&
      error_exit 1 "missing $SYSINFRA/oracle/common/db. Run the db maintenance RN"
}
#post ===========================================================
function find_all_OH {
   # Input: usfs_local_sids script
   # Output: $ALL_OH
   echo "== %post: Find all values for ORACLE_HOME" 2>&1 | tee -a $LOG
   export SIDS=$(/home/oracle/system/rman/usfs_local_sids)
   echo "SIDS=$SIDS" >> $LOG
   export ALL_OH=$(
      if [[ -f ~oracle/.bash_profile ]]; then
         alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . ~oracle/.bash_profile >> $LOG 2>&1; 
      fi
      for ORACLE_SID in $SIDS; do
         export ORACLE_SID
         # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
         # TRICKY CODE! Its not installed so dont use $SYSINFRA/oracle/common/db/oraenv.usfs
         . /home/oracle/system/rman/oraenv.usfs >> $LOG
         echo $ORACLE_HOME
      done | sort -u
   )
   echo "ALL_OH=$ALL_OH" 2>&1 | tee -a $LOG
   if [[ ${#ALL_OH} == 0 ]]; then
      error_exit 1 "could not determine all of the ORACLE_HOME values"
   fi
}
#post ===========================================================
function find_max_oracle_SW_version {
   # INPUT: $ALL_OH
   # OUTPUT:  Envars of   MAX_OH and MAX_VER
   echo "== %post: Find Maximum Oracle Software version" | tee -a $LOG
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
function install_oraenv_usfs__to_sysinfra__home_oracle {
   echo "== %post: Install oraenv.usfs to $SYSINFRA/oracle/common/db/" | tee -a $LOG
#
   mkdir $SYSINFRA/oracle/common/db/ 2> /dev/null
   if [[ -d $SYSINFRA/oracle/common/db/ ]]; then
      echo "install_oraenv_usfs__to_sysinfra_001" >> $LOG
      if [[ -f $SYSINFRA/oracle/common/db/oraenv.usfs ]]; then
         echo "install_oraenv_usfs__to_sysinfra_002" >> $LOG
         if [[ /home/oracle/system/rman/oraenv.usfs -nt $SYSINFRA/oracle/common/db/oraenv.usfs ]]; then
            echo "install_oraenv_usfs__to_sysinfra_003" >> $LOG
            if [[ ! -f $SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname).pre_private_rcat_12g ]]; then
               echo ".. backing up $SYSINFRA/oracle/common/db/oraenv.usfs" | tee -a $LOG
               cp -p $SYSINFRA/oracle/common/db/oraenv.usfs $SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname).pre_private_rcat_12g 2>> $LOG
            fi
         fi
      fi
      echo ".. updating $SYSINFRA/oracle/common/db/oraenv.usfs" | tee -a $LOG
      cp -p /home/oracle/system/rman/oraenv.usfs $SYSINFRA/oracle/common/db/oraenv.usfs 2>> $LOG || error_exit 34 "couldn't install oraenv.usfs in sysinfra"
      cp -p /home/oracle/system/rman/oraenv.usfs $SYSINFRA/oracle/common/db/oraenv.usfs.$(hostname) 2>> $LOG || error_exit 34 "couldn't install oraenv.usfs reference from this server"

      # Copy usfs_local_sids 
      echo "install_usfs_local_sids_001" >> $LOG
      if [[ -f $SYSINFRA/oracle/common/db/usfs_local_sids ]]; then
         echo "install_usfs_local_sids_002"  >> $LOG
         if [[ /home/oracle/system/rman/usfs_local_sids -nt $SYSINFRA/oracle/common/db/usfs_local_sids ]]; then
            echo "install_usfs_local_sids_003"  >> $LOG
            if [[ ! -f $SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname).pre_private_rcat_12g ]]; then
               echo ".. backing up $SYSINFRA/oracle/common/db/usfs_local_sids" | tee -a $LOG
               cp -p $SYSINFRA/oracle/common/db/usfs_local_sids $SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname).pre_private_rcat_12g 2>> $LOG
            fi
         fi
      fi
      echo ".. updating $SYSINFRA/oracle/common/db/usfs_local_sids" | tee -a $LOG
      cp -p /home/oracle/system/rman/usfs_local_sids $SYSINFRA/oracle/common/db/usfs_local_sids 2>> $LOG || error_exit 34 "couldn't install oraenv.usfs in sysinfra"
      cp -p /home/oracle/system/rman/usfs_local_sids $SYSINFRA/oracle/common/db/usfs_local_sids.$(hostname) 2>> $LOG || error_exit 34 "couldn't install usfs_local_sids from this server"
   fi
   echo ".. copy to home /home/oracle/system"
   cp -p /home/oracle/system/rman/oraenv.usfs /home/oracle/system/oraenv.usfs 2>> $LOG || error_exit 36 "couldn't copy oraenv.usfs to /home/oracle/system"
}
#post ===========================================================
#function test_rcat_password {
#   echo '== %post: Test catalog password in $RMAN_PWD' | tee -a $LOG
#
#  (
#     export TNS_ADMIN=/home/oracle/system/admin.no_krb;
#      export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
#      (sleep 1; echo "$RMAN_PWD"; sleep 1; echo exit) \
#     | sqlplus -L rcat10204@asdb.mci.fs.fed.us) 2>&1 | tee -a $LOG | grep -- -[0-9]
#  if [[ $? == 0 ]]; then
#     echo "catalog password for rcat10204@asdb.mci.fs.fed.us fails to connect to database." | tee -a $LOG
#     error_exit 27 'set the catalog password to a valid password in $RMAN_PWD'
#  else
#     echo "catalog password for rcat10204@asdb.mci.fs.fed.us is correct" | tee -a $LOG
#     echo "" | tee -a $LOG
#     echo "" | tee -a $LOG
#  fi
#
#post ===========================================================
function tnsping_RMAN_CATALOG_POOL {
   #INPUT RMAN_CATALOG RMAN_CATALOG_POOL (from ~oracle/.bash_profile)
   echo "== %post: Trying to contact the RMAN repositories with tnsping" | tee -a $LOG
   loc_aliases=$( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u)
   echo "loc_aliases=$loc_aliases" >> $LOG
   [[ -z "$loc_aliases" ]] && error_exit 33 "$ RMAN_CATALOG and $ RMAN_CATALOG_POOL appear to be blank for user oracle"
   for tnsalias in $loc_aliases; do 
      echo "tnsping $tnsalias}" >> $LOG
      (  export TNS_ADMIN=/home/oracle/system/admin.no_krb;
         export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
         tnsping $tnsalias) 2>&1 | tee -a $LOG | grep -- TNS-[0-9]
      rc=$?
      echo "rc=$rc" >> $LOG
      [[ $rc == "0" ]] && error_exit 15 "As user oracle (ORACLE_HOME=$ORACLE_HOME), this command failed:  tnsping $tnsalias"
      echo >> $LOG
   done
   echo ".. all tnsping commands succeeded" | tee -a $LOG
}
#post ===========================================================
#post ===========================================================
function connect_RMAN_CATALOG_POOL {
   #INPUT RMAN_CATALOG RMAN_CATALOG_POOL (from ~oracle/.bash_profile)
   echo "== %post: Trying to conect to the RMAN repositories schemas" | tee -a $LOG
   echo "RMAN_SCHEMA=$RMAN_SCHEMA" >> $LOG
   for tnsalias in $( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u); do 
      echo "sqlplus -L $RMAN_SCHEMA@$tnsalias}" >> $LOG
      (  export TNS_ADMIN=/home/oracle/system/admin.no_krb; 
         export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH; 
         (sleep 1; echo "$RMAN_PWD"; sleep 1; echo exit) \
         | sqlplus -L $RMAN_SCHEMA@$tnsalias) 2>&1 | tee -a $LOG | grep -- -[0-9]
      rc=$?
      echo "rc=$rc" >> $LOG
      [[ $rc == "0" ]] && error_exit 17 "As user oracle (ORACLE_HOME=$ORACLE_HOME), this command failed:  sqlplus -L $RMAN_SCHEMA@$tnsalias"
   done
   echo ".. all sqlplus commands succeeded" | tee -a $LOG
}
#post ===========================================================
function conditionally_create_rman_admin_wallet_directory
{
   echo "== %post: Create the RMAN wallet directory for TNS files" | tee -a $LOG
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
   fi
   cd /home/oracle/system/rman/admin.wallet || error_exit 1 "couldn't cd to /home/oracle/system/rman/admin.wallet"
   ln -sf $TNS_ADMIN/tnsnames.ora /home/oracle/system/rman/admin.wallet
   # TRICKY CODE!!! No spaces can be before SQLNET.WALLET_OVERRIDE !!!
   echo "WALLET_LOCATION =
      (SOURCE =
        (METHOD = FILE)
        (METHOD_DATA = (DIRECTORY = /home/oracle/system/rman/admin.wallet))
      )
SQLNET.WALLET_OVERRIDE = TRUE" > /home/oracle/system/rman/admin.wallet/sqlnet.ora
   echo "chown oracle:dba /home/oracle/system/rman/admin.wallet/*" >> $LOG
   chown oracle:dba /home/oracle/system/rman/admin.wallet/* >> $LOG 2>&1
   echo "chmod 700 /home/oracle/system/rman/admin.wallet" >> $LOG 2>&1
   chmod 700 /home/oracle/system/rman/admin.wallet >> $LOG 2>&1
}
#post ===========================================================
function conditionally_rename_previous_wallets {
   echo "== %post: Rename previous wallets, if any" | tee -a $LOG
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
#post ===========================================================
function func_randpass {
   echo "== %post: Generate wallet password" | tee -a $LOG
   if [[ -z $randpass ]]; then
      echo ".. randpass not set, so setting it"
      export randpass=a$(dd if=/dev/urandom  count=14 bs=1 2>/dev/null | \
                         od -tx | head -1 | sed 's|^00* ||;s| ||g')
   fi
   echo "This password is wallet password.  It is not recorded anywhere else." | tee -a $LOG
   echo "A new password is generated at every install attempt." | tee -a $LGO
   echo "Please record it in the password database now:" >> $LOG
   echo "Please record it in the password database now:   $randpass"
   sleep 05
}
#post ===========================================================
function create_wallet {
   echo "== %post:  Create wallet" | tee -a $LOG
   echo "ls -al /home/oracle/system/rman/admin.wallet/" >> $LOG
   ls -al /home/oracle/system/rman/admin.wallet/ >> $LOG
   (  cd /home/oracle/system/rman/admin.wallet/;
      export TNS_ADMIN=/home/oracle/system/rman/admin;
      export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
      (sleep 1; echo -e "$randpass\n$randpass") | mkstore -wrl $PWD -create 
   ) 2>&1 | strings | tee -a $LOG | grep -- -[0-9]
   rc=$?
   [[ $rc == 0 ]] && error_exit 24 "wallet creation failed"
}
#post ===========================================================
function add_credentials_to_wallet {
   echo "== %post:  Add credentials to the wallet" | tee -a $LOG
   if [[ -z $BYPASS_RMAN_PWD ]]; then
      loc_aliases=$( (echo $RMAN_CATALOG; echo $RMAN_CATALOG_POOL) | tr ":" "\n" | sort -u)
      echo "loc_aliases=$loc_aliases" >> $LOG
      [[ -z "$loc_aliases" ]] && error_exit 33 "$ RMAN_CATALOG and $ RMAN_CATALOG_POOL appear to be blank for user oracle"
      for tnsalias in $loc_aliases; do
         echo "mkstore creadCredential" >> $LOG
         (  cd /home/oracle/system/rman/admin.wallet/;
            export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
            export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
            echo "mkstore -wrl $PWD -createCredential $tnsalias $RMAN_SCHEMA ********";
            (sleep 1; echo "$randpass") | \
                mkstore -wrl $PWD -createCredential $tnsalias $RMAN_SCHEMA $RMAN_PWD
                ) 2>&1 | strings | tee -a $LOG | grep -- -[0-9]
         rc=$?
         [[ $rc == 0 ]] && error_exit 24 "failed: mkstore -wrl /home/oracle/system/rman/admin.wallet -createCredential $tnsalias $RMAN_SCHEMA \$RMAN_PWD"
         echo >> $LOG
      done
   else
      echo ".. %post: since \$BYPASS_RMAN_PWD is set, bypassing creating SYS credentials in wallet" | tee -a $LOG
   fi

   if [[ -n $CDB_NAME ]]; then
      echo ".. %post: Add SYS credentials to the wallet" | tee -a $LOG
      echo "TODO:  ALTER USER SYS IDENTIFIED BY $SYS_PWD;
            This must occur so the orawp$CDB_NAME file matches the wallet!"
      sleep 30
      [[ -z $SYS_PWD ]] && error_exit 1 "$SYS_PWD is empty.  It needs to be the password for SYS for database $CDB_NAME"
      export maxcnt=$(ksh $OLSNODES | wc -l)
      export cnt=1
      while ((cnt<=maxcnt)); do 
         (  cd /home/oracle/system/rman/admin.wallet/;
            export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
            export ORACLE_HOME=$MAX_OH;PATH=$MAX_OH/bin:$PATH;
            echo 'mkstore -wrl $PWD -createCredential $CDB_NAME$cnt SYS ********';
            (sleep 1; echo "$randpass") | \
               mkstore -wrl $PWD -createCredential $CDB_NAME$cnt SYS $SYS_PWD   
         ) 2>&1 | strings | tee -a $LOG | grep -- -[0-9]
         rc=$?
         [[ $rc == 0 ]] && error_exit 30 "failed: mkstore -wrl /home/oracle/system/rman/admin.wallet -createCredential $tnsalias $RMAN_SCHEMA \$RMAN_PWD"
         echo >> $LOG
         ((cnt=cnt+1))
      done
   else
      echo ".. %post: since \$CDB_NAME is not set, bypassing creating SYS credentials in wallet" | tee -a $LOG
   fi
   chmod 600 /home/oracle/system/rman/admin.wallet/*
}
#post ===========================================================
function perms_and_bash_profile {
   echo "Post install for /home/oracle/system/rman/post_install.sh" 2>&1 | tee -a $LOG
   echo "Backing up /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
   cp /home/oracle/.bash_profile /home/oracle/.bash_profile.$(date "+%Y-%m-%d:%H:%M:%S") 2>&1 | tee -a $LOG
   echo "Adding NLS_DATE_FORMAT, NLS_LANG envars, an adding aliases 'sql', 'no_krb'
         to /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
   if ! grep 'NLS_DATE_FORMAT=YYYY-MM-DD:HH24:MI:SS' /home/oracle/.bash_profile; then
      echo "Appending NLS_DATE_FORMAT to /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
      echo 'export NLS_DATE_FORMAT=YYYY-MM-DD:HH24:MI:SS' >> /home/oracle/.bash_profile
   fi
   if ! grep 'NLS_LANG=american' /home/oracle/.bash_profile; then 
      echo "Appending NLS_LANG to /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
      echo 'export NLS_LANG=american' >> /home/oracle/.bash_profile
   fi
   if ! grep 'alias sql=' /home/oracle/.bash_profile; then
      echo "Appending 'alias sql' to /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
      echo "alias sql='sqlplus / as sysdba'" >> /home/oracle/.bash_profile
   fi
   if ! grep 'alias no_krb="export TNS_ADMIN=/home/oracle/system/admin.no_krb"' \
      /home/oracle/.bash_profile
   then
      echo "Appending 'alias no_krb' to /home/oracle/.bash_profile" 2>&1 | tee -a $LOG
      echo 'alias no_krb="export TNS_ADMIN=/home/oracle/system/admin.no_krb"' >> \
         /home/oracle/.bash_profile
   fi
   if [[ ! -d /home/oracle/system/admin.no_krb ]]; then
      echo "Making directory: /home/oracle/system/admin.no_krb" 2>&1 | tee -a $LOG
      mkdir /home/oracle/system/admin.no_krb   2>&1 | tee -a $LOG
   fi
   chmod 755 /home/oracle/system/admin.no_krb 2>&1 | tee -a $LOG
   touch /home/oracle/system/admin.no_krb/sqlnet.ora 2>&1 | tee -a $LOG
   chmod 644 /home/oracle/system/admin.no_krb/sqlnet.ora  2>&1 | tee -a $LOG
   export FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab
   export ORACLE_HOME=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+:[nN]|MGMTDB|+ASM" | cut -f2 -d: | sort -u | head -1)
   echo ORACLE_HOME=$ORACLE_HOME 2>&1 | tee -a $LOG
   ln -sf $ORACLE_HOME/network/admin/tnsnames.ora \
          /home/oracle/system/admin.no_krb/tnsnames.ora 2>&1 | tee -a $LOG
   chown oracle:dba /home/oracle/system/admin.no_krb/ /home/oracle/system/admin.no_krb/* 2>&1 | tee -a $LOG
   echo "/home/oracle/.bash_profile modified" 2>&1 | tee -a $LOG
   echo "Copying usfs_local_sids and oraenv.usfs to /home/oracle/system" 2>&1 | tee -a $LOG
   [[ -s /home/oracle/system/usfs_local_sids ]] && rm -f /home/oracle/system/usfs_local_sids | tee -a $LOG
   [[ -s /home/oracle/system/oraenv.usfs ]] && rm -f /home/oracle/system/oraenv.usfs
   chmod 755 /home/oracle/system/rman/usfs_local_sids 2>&1 | tee -a $LOG
   chmod 755 /home/oracle/system/rman/oraenv.usfs 2>&1 | tee -a $LOG
   cp -p /home/oracle/system/rman/usfs_local_sids /home/oracle/system/ 2>&1 | tee -a $LOG
   cp -p /home/oracle/system/rman/oraenv.usfs /home/oracle/system/ 2>&1 | tee -a $LOG
   chown oracle:dba /home/oracle/system/usfs_local_sids 2>&1 | tee -a $LOG
   chown oracle:dba /home/oracle/system/oraenv.usfs 2>&1 | tee -a $LOG
   
   echo '##############################################################' 2>&1 | tee -a $LOG
   echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Verify /opt/oracle/diag exists. 2>&1 | tee -a $LOG
   echo '##############################################################' 2>&1 | tee -a $LOG
   
   echo "RPM install complete $(date)" 2>&1 | tee -a $LOG
}
#post ===========================================================
function restore_cron_add_bu {
   echo "== %post:  Restore catalog sync in cron, add archive backup 9AM 6PM" | tee -a $LOG
   if [[ -f /var/tmp/rman/crontab.rcat_wallet.before.tmp ]]; then
      crontab /var/tmp/rman/crontab.rcat_wallet.before.tmp
      echo ".. Restored the catalog sync in cron" | tee -a $LOG
   else
      crontab -l > /var/tmp/rman/crontab.rcat_wallet.before.tmp
      echo ".. catalog restore not needed." | tee -a $LOG
   fi
   if ! grep "rman_backup.sh.*-a" /var/tmp/rman/crontab.rcat_wallet.new >> $LOG 2>&1; then
      if [[ -z "$CDB_NAME" ]]; then
         echo ".. adding backup of archive logs for 9AM and 6PM" >> $LOG
         #HACK OLD echo "0 9,18 * * 1-6 /home/oracle/system/rman/rman_backup.sh -a >/dev/null 2>&1" >> /var/tmp/rman/crontab.rcat_wallet.new
         /home/oracle/system/rman/install_shield_cron.sh || error_exit 11 'failed calling /home/oracle/system/rman/install_shield_cron.sh'
      else
         echo ".. '\$ CDB_NAME' is set.  Not setting rman_backup.sh in crontab." | tee -a $LOG
      fi
   else
      echo ".. skipping, not adding backup of archive logs for 9AM and 6PM since rman_backup.sh found in crontab" >> $LOG
   fi
}
#post ===========================================================
function copy_scripts_to_stage4grid_and_cron {
   echo "== %post:  Copying scripts to ~grid/system/rman" | tee -a $LOG
   if [[ $(echo 'echo ORACLE_HOME=$ORACLE_HOME' | sudo -iu grid 2>/dev/null) == ORACLE_HOME=/opt* ]]; then
      echo ".. user grid does exist..." | tee -a $LOG
      chmod g+rx /tmp/rcat_12.2.0/* 2>> $LOG
#TODO 10/4/2016--Test the next two lines
      echo  "alias shopt=': '; UID=\$(id | sed 's|(.*||;s|.*=||'); . ~/.bash_profile; mkdir ~/system ~/system/rman; cp -rp /tmp/rcat_12.2.0/* ~/system/rman; /home/grid/system/rman/install_shield_cron.grid.sh; echo rc=\$?; touch /tmp/qg"  | (cd /tmp; sudo -u grid ksh) 2>&1 | tee /var/tmp/rman/rpm.grid.log 2>&1
      ls -l /tmp/qg | grep 'grid oinstall' >> $LOG || error_exit 1 "couldn't sudo to user grid"
#OLD      echo "Please do this in another window as your administrative user, and do this command" | tee -a $LOG
#old      echo '    echo  "' "alias shopt=': '; UID=\\\$(id | sed 's|(.*||;s|.*=||');" '. ~/.bash_profile; mkdir ~/system ~/system/rman; cp -rp /tmp/rcat_12.2.0/* ~/system/rman; /home/grid/system/rman/install_shield_cron.grid.sh; echo rc=\$?"  | (cd /tmp; sudo -u grid ksh) 2>&1 | tee /var/tmp/rman/rpm.grid.log 2>&1; chmod 777 /var/tmp/rman/rpm.grid.log' | tee -a $LOG
#old      echo  | tee -a $LOG
#old      echo "After doing the above, press the Enter key to continue: "; 
#old      read pause

      grep '^rc=' /var/tmp/rman/rpm.grid.log || error_exit 41 "no return code found in the log.  (Did you hit Enter before doing the above commands?)"
      grep '^rc=0$' /var/tmp/rman/rpm.grid.log || error_exit 40 "please resolve grid's errors in /var/tmp/rman/rpm.grid.log"
      rm -rf /tmp/system_rman/ 2>> $LOG
   else
      echo ".. ORACLE_HOME for user grid not set.  Not copying scripts" | tee -a $LOG
   fi
}
#post ===========================================================
function call_cf_snapshot_in_recovery_sh {
   (. /home/oracle/system/rman/cf_snapshot_in_recovery.sh
      echo $? > /var/tmp/rman/rcat.semiphore2) | tee -a $LOG
   rc=$(cat /var/tmp/rman/rcat.semiphore2)
   rm -f /var/tmp/rman/rcat.semiphore2
   [[ $rc == "0" ]] || error_exit 30 "failed /home/oracle/system/rman/post_install.sh"
}
#post ===========================================================
function install_fs615_allocate_flat_files {
   echo "== Install FS615 custom channel allocation files" | tee -a $LOG
   echo "CDB_NAME=$CDB_NAME" >> $LOG
   export dir=/home/oracle/system/rman
   if [[ -n "$CDB_NAME" ]]; then
      if ps -ef | grep "pmon.*$CDB_NAME" >> $LOG; then
         echo ".. found process like 'pmon.*$CDB_NAME' running, so configuring." | tee -a $LOG
         # TRICKY CODE !!! rpmbuild can't handle <back_slash><dollar_sign> in quotes 
         # without a space between <back_slash><dollar_sign>!
         echo "\$ (hostname)=$(hostname)" >> $LOG
         echo "DOMAIN=$DOMAIN" >> $LOG
         # slmciordb020/024/025 in MCI is in cluster:  crsrac6 
         # slmciordb026/027/028 in MCI is in cluster:  crsrac7
         export CLUSTER_NAME=$(ksh "$CEMUTLO -n" | tr '-' '_')
         echo "CLUSTER_NAME=$CLUSTER_NAME" >> $LOG
         for file in fs615_allocate_disk.ora fs615_allocate_sbt.ora fs615_release_disk.ora; do
            if [[ -f $dir/$file.$DOMAIN.$CLUSTER_NAME ]]; then
               sour_file=$dir/$file.$DOMAIN.$CLUSTER_NAME
            elif [[ -f $dir/$file.$DOMAIN ]]; then
               sour_file=$dir/$file.$DOMAIN
            else
               error_exit 11 "missing alloaction file: $file.$DOMAIN or $file.$DOMAIN.$CLUSTER_NAME"
            fi
            if [[ ! -f $sour_file ]]; then
               error_exit 12 "expected fs615_allocation file to exist: '$sour_file'"
            fi
            sed "s/%CDB%/$CDB_NAME/" $sour_file > $dir/$file
         done
      else
         echo ".. did NOT find process like 'pmon.*$CDB_NAME' running, so NOT configuring." | tee -a $LOG
         echo ".. removing empty flat files" | tee -a $LOG
         rm -f $dir/fs615_allocate_disk.ora $dir/fs615_allocate_sbt.ora $dir/fs615_release_disk.ora
      fi
   else
      echo ".. \$CDB_NAME is not set, so not installing FS615 custom channel allocation files" | tee -a $LOG
      echo ".. removing empty flat files" | tee -a $LOG
      rm -f $dir/fs615_allocate_disk.ora $dir/fs615_allocate_sbt.ora $dir/fs615_release_disk.ora
   fi
}
#post ===========================================================
function mkdir_diag {
   echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Verify /opt/oracle/diag exists. 2>&1 | tee -a $LOG
   if [[ -z $SKIP_NFS_MOUNT_CHECK && ! -L /opt/oracle/diag ]]; then
      error_exit 37 "Please ask the sys admin team to create the /opt/oracle/diag NFS mountpoint from /nfsroot/<domain>/orapriv/<clustername>/db/diag ."
   else
      echo "The directory /opt/oracle/diag exists." 2>&1 | tee -a $LOG
   fi
   touch /var/tmp/rman/rman_backout_mkdir_diag.sh
   if [[ ! -d /opt/oracle/diag/bkp/rman/vote_disk/ ]]; then
      mkdir /opt/oracle/diag/bkp/rman/vote_disk/ || error_exit 38 "failed mkdir /opt/oracle/diag/bkp/rman/vote_disk/"
      echo "rm -rf /opt/oracle/diag/bkp/rman/vote_disk/"  > /var/tmp/rman/rman_backout_mkdir_diag.sh
   fi
   chmod 777 /opt/oracle/diag/bkp/rman/vote_disk/ || error_exit 39 "failed chmod 777 /opt/oracle/diag/bkp/rman/vote_disk/"
}
#post ===========================================================
function install_fs615_signature_file {
   echo "== %post:  Installing installation signature file" | tee -a $LOG
   SIGDIR="/home/oracle/system/signatures"
   SIGFILE="FS615.rman.backup.scripts.12.2-6.sig"

   mkdir -p $SIGDIR >> $LOG 2>&1
   [[ $? != 0 ]] && error_exit 11 "Unable to create signature directory"

   echo "wallet_rman_catalog_12.2.0.sig,126,RMAN Private Catalog 12.2.0,/home/oracle/system/signatures/wallet_rman_catalog_12.2.0.sig,Linux" > $SIGDIR/$SIGFILE

   [[ $? != 0 ]] && error_exit 12 "Unable to create signature file"
   chmod 755 $SIGDIR/$SIGFILE >> $LOG 2>&1
   echo ".. done" | tee -a $LOG
}
#================================================================
# Update the control file records for each Oracle instance
#================================================================
function update_oracle_control_file_records {
   echo "== Updating Oracle control file records" | tee -a $LOG

   cat >/var/tmp/rman/tmp.sql  <<\EOF
      set pages 50
      alter system set control_file_record_keep_time=365 scope=both

      l
      r
      select * from v$instance

      l
      r
      show parameter control_file_record_keep_time

      l
      r
      exit
EOF
   . /home/oracle/system/rman/usfs_local_sids
   echo SIDS=$SIDS | tee -a $LOG

   for S in $SIDS; do
      echo ".. Updating Oracle instance $S" | tee -a $LOG
      (  export ORACLE_SID=$S; 
         . /home/oracle/system/oraenv.usfs; 
         PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/rman/tmp.sql 2>&1 ) \
         | tee -a $LOG | tee /var/tmp/rman/$S.log | grep -- -[0-9]
      [[ $? != 0 ]] && error_exit 14 "Unable to set Oracle control file record for instance $S"
   
      XX=$(grep "^control_file_record_keep_time" /var/tmp/rman/$S.log | awk '{print $3}')
      echo "Controlfile keeptime=$XX" | tee -a $LOG
      [[ $XX != 365 ]] && error_exit 15 "Unable to set Oracle control file record for instance $S"
   done
}
################################################################
# MAIN
################################################################
set_envars
[[ -z "$RMAN_SCHEMA" ]] && error_exit 1 "expected non null \$RMAN_SCHEMA"
[[ -z "$RMAN_PWD" ]] && error_exit 1 "expected non null \$RMAN_PWD"
echo "$(date) Begin $0 'RMAN priviate catalog'" >> $LOG
echo "\$SHELL=$SHELL" >> $LOG
MYID=$(id -u -n)
[[ $MYID != oracle ]] && error_exit 15 "This script must be executed as oracle"

if [[ -n "$FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS" ]]; then
   echo ".. \$ FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS is set, no configuration, just files installed" | tee -a $LOG
   install_oraenv_usfs__to_sysinfra__home_oracle
else
   echo ".. \$ FS615_BACKUP_SCRIPT_BACKOUT_OR_JUST_SCRIPTS is not set, continuing" | tee -a $LOG
   find_all_OH
   find_max_oracle_SW_version
   #test_rcat_password
   tnsping_RMAN_CATALOG_POOL
   connect_RMAN_CATALOG_POOL
   conditionally_create_rman_admin_wallet_directory
   conditionally_rename_previous_wallets
   func_randpass
   create_wallet
   add_credentials_to_wallet
   perms_and_bash_profile
   update_oracle_control_file_records
   #RAC only call_cf_snapshot_in_recovery_sh
   copy_scripts_to_stage4grid_and_cron
   restore_cron_add_bu
   install_fs615_allocate_flat_files
   mkdir_diag
   install_fs615_signature_file
fi
echo "$(date) SUCCESSFULLY COMPLETED rpm_post_install.sh" | tee -a $LOG
exit 0
