#!/usr/bin/env ksh
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #05/29/2013   v1.9
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT International Business Machines Corp. 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA 
#
#  Purpose:
#    Configures Image Copy backups in NITC
#
#

mkdir /var/tmp/imgcp 2> /dev/null
chmod 777 /var/tmp/imgcp 
export LOG=/var/tmp/imgcp/imgcp.log
{
   function set_envars {
      echo "== Set envars"
      TAB=$(echo -e "\t")
      if [[ -f /home/oracle/system/rman/imgcp_parameters.sh ]]; then
         . /home/oracle/system/rman/imgcp_parameters.sh
         [[ "$IMG_SID_EXCLUDE_LIST" == *" "* || "$IMG_SID_EXCLUDE_LIST" == *"$TAB"* ]] && error_exit 1 "space or tab found in IMG_SID_EXCLUDE_LIST in /home/oracle/system/rman/imgcp_parameters.sh"
      else
         . /tmp/rcat_12.2.0/imgcp_parameters.sh
         [[ "$IMG_SID_EXCLUDE_LIST" == *" "* || "$IMG_SID_EXCLUDE_LIST" == *"$TAB"* ]] && error_exit 1 "space or tab found in IMG_SID_EXCLUDE_LIST in /tmp/rcat_12.2.0/imgcp_parameters.sh"
      fi
      MYID=$(id -u -n)
      [[ $MYID != "oracle" ]] && error_exit 29 "This script must be executed as oracle"
      SIDS=$(/tmp/rcat_12.2.0/usfs_local_sids_imgcp | sort)
      echo SIDS=$SIDS >> $LOG
   }
   function error_exit {
      echo "  ERROR $2"
      exit $1
   }
   function script_usage {
      echo "imgcp.sh [-b]"
      echo "   -b  backout the changes made during install"
   }
   function check_freespace {
      REQSP=$1
      FS=$2
      FREE=$(df -Pk $FS | tail -1 | awk '{print $4}')
      ((FREE<REQSP)) && error_exit 1 "Insufficient free space in $FS"
   }
   function check_oracle_software {
      echo "== Checking Oracle software"
      [[ -f $FS615_ORATAB ]] || error_exit 32 "expected \$FS615_ORATAB ($FS615_ORATAB) to exist"
      [[ -f /home/oracle/system/rman/archivelog_mode.sh ]] || error_exit 1 "missing /home/oracle/system/rman/archivelog_mode.sh"
      echo "..  \$FS615_ORATAB ($FS615_ORATAB) file found"
   }
   function check_running_processes {
      echo "== Precheck for running processes "
      XX=$(ps -ef | grep "[r]man_backup" | wc -l)
      ((XX>0)) && error_exit 2 "RMAN backups are currently active"
   
      for ORACLE_SID in $SIDS; do 
         ps -ef | grep -q "[o]ra_pmon_$ORACLE_SID" || error_exit 4 "Oracle must be running for this ORACLE_SID=$ORACLE_SID"
         echo ".. pmon running for ORACLE_SID=$ORACLE_SID"
      done
   }
   function check_sysinfra_symlink {
      echo "== Check for symlink $SYSINFRA"
      if [[ -z "$IGNORE_NFS_CLIENT_TEST" ]]; then
         [[ -L $SYSINFRA ]] || error_exit 37 "missing symbolic link for $SYSINFRA"
         ls $SYSINFRA/oracle/* > /dev/null || error_exit 38 "ls $SYSINFRA/oracle/* failed"
         echo ".. NFS mount found"
      else
         echo "IGNORE_GPFS_CLIENT_TEST is set, ignoring thist test."
      fi
   }
   function check_required_files {
      echo "== Checking for required installation files (archivelog_mode.sh is from RN2015-211c)"
      REQUIRED="/home/oracle/system/rman/oraenv.usfs"
      REQUIRED="/tmp/rcat_12.2.0/oraenv.usfs /tmp/rcat_12.2.0/usfs_local_sids_imgcp /home/oracle/system/rman/rman_backup.sh /home/oracle/system/rman/archivelog_mode.sh /tmp/rcat_12.2.0/install_shield_cron.sh /tmp/rcat_12.2.0/create_rcat.sql /tmp/rcat_12.2.0/rman_backup.sh /tmp/rcat_12.2.0/rman_restore_pitr_spfile_cf.sh"
   
      for FILE in $REQUIRED; do
         [[ ! -f $FILE ]] && error_exit 5 "Required file $FILE not found. Verify untar."
      done
      [[ -d /tmp/rcat_12.2.0/ ]] || error_exit 5 "Expected /tmp/rcat_12.2.0 to exist"
      echo ".. All required files found"
   }
   function cp_scripts {
      echo "== Copy scrirpts"
      if [[ ! -d /home/oracle/system/ ]]; then
         mkdir /home/oracle/system/ 2>&1
      fi
      for file in install_shield_cron.sh archivelog_mode.sh create_rcat.sql rman_backup.sh rman_restore_pitr_spfile_cf.sh; do
         if [[ ! -f /home/oracle/system/rman/$file.pre_imgcp ]]; then
            cp -p /home/oracle/system/rman/$file /home/oracle/system/rman/$file.pre_imgcp || error_exit 1 "couldn't backup file $file"
         fi
      done
      for file in imgcp_parameters.sh imgcp.sh install_shield_cron.sh archivelog_mode.sh create_rcat.sql rman_backup.sh rman_restore_pitr_spfile_cf.sh; do
         if [[ ! -f /home/oracle/system/rman/$file ]]; then
            cp -p /tmp/rcat_12.2.0/$file /home/oracle/system/rman/ || error_exit 1 "couldn't copy software"
         else
            if [[ /tmp/rcat_12.2.0/$file -nt /home/oracle/system/rman/$file ]]; then
               cp -p /tmp/rcat_12.2.0/$file /home/oracle/system/rman/ || error_exit 1 "couldn't overwrite software"
            else 
               echo ".. /home/oracle/system/rman/$file is newer, not overwriting"
            fi
         fi
      done
   }
   function find_all_OH {
      # INPUT:  /tmp/rcat_12.2.0/usfs_local_sids_imgcp
      #         /tmp/rcat_12.2.0/oraenv.usfs
      # OUTPUT: $ALL_OH
      echo "== Find all values for ORACLE_HOME"
      echo SIDS=$SIDS >> $LOG
      [[ ${#SIDS} == 0 ]] && error_exit 1 "no SIDS to find"
      export ALL_OH=$(for ORACLE_SID in $SIDS; do
         # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
         . /tmp/rcat_12.2.0/oraenv.usfs > /dev/null
         echo $ORACLE_HOME
      done | sort -u)
      echo ALL_OH=$ALL_OH
      [[ ${#ALL_OH} == 0 ]] && error_exit 39 "could not determine all of the ORACLE_HOME values"
   }
   function find_max_oracle_SW_version {
      # INPUT:  $ALL_OH
      # OUTPUT:  Envars of   MAX_OH and MAX_VER
      echo "== Find Maximum Oracle Software version"
      MAX_COMPVER=0.0
      for ORACLE_HOME in $ALL_OH; do
         VER=$( 
            export ORACLE_HOME=$ORACLE_HOME
            export PATH=$ORACLE_HOME/bin:$PATH
            export LD_LIBRARY_PATH=$ORACLE_HOME/lib
            echo | sqlplus /nolog 2>&1 | tee /var/tmp/imgcp/rcat.sqlplus.version.$$.log | sed '/ Release /!d;s|.*Release.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*|\1|' | tail -1 )
         echo VER=$VER >> $LOG
         # Remove all but the left most decimal point, i.e. change 10.2.0.2 to 10.202
         COMPVER=$( echo $VER | sed 'h;s|^[0-9][0-9]*\.\(.*\)|\1|;s|\.||g;x;s|^\([0-9][0-9]*\.\).*|\1|;G;s|\.[^[0-9]|.|g' )
         echo COMPVER=$COMPVER >> $LOG
         if (( $(expr $MAX_COMPVER '<' $COMPVER) == 1 )); then # was bc
            MAX_OH=$ORACLE_HOME
            MAX_VER=$VER 
            MAX_COMPVER=$COMPVER
         fi
         echo MAX_VER=$MAX_VER >> $LOG
         echo MAX_OH=$MAX_OH >> $LOG
      done 
      export MAX_OH=$(sed '/MAX_OH=/!d;s|.*=||' $LOG | tail -1)
      export MAX_VER=$(sed '/MAX_VER=/!d;s|.*=||' $LOG | tail -1)
      echo MAX_OH=$MAX_OH
      echo MAX_VER=$MAX_VER
      [[ ! -d $MAX_OH ]] && error_exit 40 "ORACLE_HOME with max version is not a real directory"
   }
   function remove_rman_cron {
      echo "== Disable catalog sync in cron"
      if [[ ! -f /var/tmp/imgcp/crontab.rcat.before.tmp ]]; then
         crontab -l > /var/tmp/imgcp/crontab.rcat.before.tmp
      fi
      crontab /dev/null
      echo ".. Disabled the catalog sync in cron"
   }
   function restore_cron {
set -x
      echo "== Restore catalog sync in cron"
      if [[ -f /var/tmp/imgcp/crontab.rcat.before.tmp ]]; then
         crontab /var/tmp/imgcp/crontab.rcat.before.tmp
         echo "== Restored the catalog sync in cron"
      else
         echo ".. catalog restore not needed."
      fi
   }
   function call_imgcp_archivelog_mode_sh {
      # $1 - commandline options
      CMD_OPTS=$*
      echo "Running /home/oracle/system/rman/archivelog_mode.sh $CMD_OPTS"
      /home/oracle/system/rman/archivelog_mode.sh $CMD_OPTS || error_exit 1 "couldn't call archivelog_mode.sh successfully"
   }
   function check_catalog_connection {
      echo "== Check that the RMAN catalog can connect"
      
      if [[ -z $ORACLE_SID ]]; then
         export ORACLE_SID=$(echo $SIDS | tr ' ' '\n' | head -1)
      fi
      [[ -z $ORACLE_SID ]] && error_exit 1 "expected envar ORACLE_SID"

      echo ".. Querying Oracle instance $ORACLE_SID"
      (
         . /home/oracle/system/oraenv.usfs;
         PATH=$ORACLE_HOME/bin:$PATH; 
         export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
         echo "select 'cnt='||count(*) from user_users;" | sqlplus /@$RMAN_CATALOG
      ) > /var/tmp/imgcp/check_cataog_connection.log 2>&1
      [[ $? != 0 ]] && error_exit 14 "Unable to connect to RMAN catalog"

      cnt=$(sed "/^cnt=/!d; s|^cnt=||" /var/tmp/imgcp/check_cataog_connection.log)
      echo cnt=$cnt
      [[ $cnt != '1' ]] && error_exit 1 "Couldn't connect to RMAN catalog"
   }
   ############################################################################
      function sub_query_dbid {
         echo "   == (SID=$ORACLE_SID) Query DBID"
         (
            . /home/oracle/system/oraenv.usfs;
            PATH=$ORACLE_HOME/bin:$PATH;
            echo "select 'dbid='||dbid from v\$database;" | sqlplus / as sysdba 2>&1 > /var/tmp/imgcp/sub_query_dbid.$ORACLE_SID.lst)
         DBID=$(sed '/^dbid=/!d; s|dbid=||;' /var/tmp/imgcp/sub_query_dbid.$ORACLE_SID.lst)
      }
      function sub_db_recovery_file_dest {
         echo "   == (SID=$ORACLE_SID) Query db_recovery_file_dest"
         (
            . /home/oracle/system/oraenv.usfs;
            PATH=$ORACLE_HOME/bin:$PATH;
            echo "select 'db_recovery_file_dest='||value from v\$parameter where name='db_recovery_file_dest';" | sqlplus / as sysdba 2>&1 > /var/tmp/imgcp/db_recovery_file_dest.$ORACLE_SID.lst)
         db_recovery_file_dest=$(sed '/^db_recovery_file_dest=/!d; s|db_recovery_file_dest=||;' /var/tmp/imgcp/db_recovery_file_dest.$ORACLE_SID.lst)
         [[ -z $db_recovery_file_dest ]] && error_exit 1 "couldn't query db_recovery_file_dest"
      }
      function sub_sum_dg_output_bytes {
         echo "  == For existing datafile copies, sum output_bytes by diskgroup (DBID=$DBID"
         ( . /home/oracle/system/oraenv.usfs;
           PATH=$ORACLE_HOME/bin:$PATH;
           # define qdbid=3157461439
           export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
           echo "
              set pages 50
              set lines 150
              col dg format a40
              col rcbcd_ob format 9999999999999999999
              define qdbid=$DBID
              select rcbcd.dg, sum(rcbcd.ob) rcbcd_ob from
                 (select 'dg='||substr(name, 1, instr(NAME, '/')-1 ) dg, OUTPUT_BYTES ob from RC_BACKUP_COPY_DETAILS
                     where DB_KEY=(
                        select db_key from rc_database rc where
                           dbid=&qdbid and rc.RESETLOGS_TIME=(select max(duprc.RESETLOGS_TIME) from
                           rc_database duprc where dbid=&qdbid)
                     )
                 ) rcbcd
              group by rcbcd.dg;
              " | sqlplus /@$RMAN_CATALOG 2>&1 > /var/tmp/imgcp/sub_sum_dg_output_bytes.$ORACLE_SID.lst )
         grep -E 'ORA-|RMAN-' /var/tmp/imgcp/sub_sum_dg_output_bytes.$ORACLE_SID.lst && error_exit 1 'couldn t size the copies already in diskgroups'
         cnt=$(grep -c '^dg=' /var/tmp/imgcp/sub_sum_dg_output_bytes.$ORACLE_SID.lst)
         dg=$(sed "/^dg=$db_recovery_file_dest/!d; s/^dg=//; s/[ $TAB].*//" /var/tmp/imgcp/sub_sum_dg_output_bytes.$ORACLE_SID.lst)
         copy_size_in_fra=$(( $(sed "/^dg=$db_recovery_file_dest/!d; s/^dg=.* //" /var/tmp/imgcp/sub_sum_dg_output_bytes.$ORACLE_SID.lst) ))
         echo "dg=$dg:"
         echo "copy_size_in_fra=$copy_size_in_fra"
      }
      function sub_compare_FRA_with_db_size {
         echo "== Compare FRA with db size"
         ( . /home/oracle/system/oraenv.usfs;
           PATH=$ORACLE_HOME/bin:$PATH;
           # define qdbid=3157461439
           export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
           echo "define copy_size_in_fra=$copy_size_in_fra" > /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.sql
           cat >> /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.sql <<\EOF
              set head off echo off
              select 'Database name:                         '|| (select name from v$database ) || chr(10)||
                     'db_recovery_file_dest_size:      '|| to_char(p.VALUE/1024/1024/1024, '999999.99') ||' GB'|| chr(10)||
                     'Total space in FRA disk group:   '|| to_char(dg.TOTAL_MB/1024, '999999.99') ||' GB'|| chr(10)||
                     'Free space in FRA disk group:    '|| to_char(dg.FREE_MB/1024, '999999.99') ||' GB'|| chr(10)||
                     'Current df copies in FRA:        '|| to_char(&copy_size_in_fra/1024/1024/1024, '999999.99') ||' GB' || chr(10) ||
                     'Database size:                   '|| (select to_char(sum(bytes)/1024/1024/1024, '999999.99') from v$datafile) ||' GB' || chr(10)||
               (
              CASE
               WHEN p.VALUE/1024/1024 >= dg.TOTAL_MB*0.99 THEN 'CHECK FAILED: db_recovery_file_dest_size parameter must be set to less than 99% of FLASH diskgroup size'
               WHEN (select sum(bytes)/1024/1024 from v$datafile) > dg.FREE_MB+&copy_size_in_fra/1024/1024 THEN 'CHECK FAILED: Insufficient space in FLASH diskgroup'
               WHEN (select sum(bytes)/1024/1024*1.4 from v$datafile) > dg.TOTAL_MB THEN 'CHECK FAILED: Flash recovery area size must be at least 1.4 x database size'
               WHEN (select sum(bytes)*1.4 from v$datafile) > p.VALUE THEN 'CHECK FAILED: db_recovery_file_dest_size must be at least 1.4 x database size'
               ELSE 'CHECK SUCCEEDED: Flash recovery area space allocation is sufficient'
              END)
               from v$parameter p, v$asm_diskgroup dg
              where p.name='db_recovery_file_dest_size'
              and dg.NAME = (select REPLACE(value,'+') from v$parameter  where name='db_recovery_file_dest');
              exit;
EOF
         sqlplus -S / as sysdba @/var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.sql 2>&1 > /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.lst )
         grep -E 'ORA-|RMAN-' /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.lst && error_exit 1 'couldn t query db_recovery_file_dest, etc'
         grep '^Database name:' /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.lst         
         sed '1,/^Database name:/d' /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.lst         
         grep -q 'CHECK SUCCEEDED: Flash recovery area space allocation is sufficient' /var/tmp/imgcp/sub_compare_FRA_with_db_size.$ORACLE_SID.lst || error_exit 1 \
            "FRA has insufficent space.  See above error.  If appropriate, at '$ORACLE_SID' in the exclude list (IMG_SID_EXCLUDE_LIST) in /tmp/rcat_12.2.0/imgcp_parameters.sh"
      }
      function sub_enable_bct {
         echo "== Query block change tracking"
         [[ -z $ORACLE_SID ]] && error_exit 1 "expected envar ORACLE_SID"
         cat >/var/tmp/imgcp/sub_query_bct.sql  <<\EOF
            set pages 50
            select 'status='||status from V$BLOCK_CHANGE_TRACKING

            l
            r
            exit
EOF
         echo SIDS=$SIDS

         echo ".. Querying Oracle instance $ORACLE_SID"
         (
            . /home/oracle/system/oraenv.usfs;
            PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/imgcp/sub_query_bct.sql 2>&1 ) \
            > /var/tmp/imgcp/sub_query_bct.$ORACLE_SID.log
         grep -E 'ORA-|RMAN-' /var/tmp/imgcp/sub_query_bct.$ORACLE_SID.log && error_exit 1 "Unable to query v\$BLOCK_CHANGE_TRACKING for status in $ORACLE_SID"
         bct_status=$(sed "/^status=/!d; s|^status=||" /var/tmp/imgcp/sub_query_bct.$ORACLE_SID.log)
         echo bct_status=$bct_status
         if [[ $bct_status == 'DISABLED' ]]; then
            echo ".. Enabling Block Change Tracking for database $ORACLE_SID"
            if [[ ! -f /var/tmp/imgcp/backout_bct.sql ]]; then
               echo "ALTER DATABASE disable BLOCK CHANGE TRACKING;" > /var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.sql
               echo "exit;"                                        >> /var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.sql
            fi
            echo "ALTER DATABASE ENABLE BLOCK CHANGE TRACKING;" > /var/tmp/imgcp/bct_enable.sql
            echo "exit;"                                       >> /var/tmp/imgcp/bct_enable.sql
            (
               . /home/oracle/system/oraenv.usfs;
               PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/imgcp/bct_enable.sql 2>&1 ) \
               > /var/tmp/imgcp/bct_enable.$ORACLE_SID.log
            grep -E 'ORA-|RMAN-' /var/tmp/imgcp/bct_enable.$ORACLE_SID.log && error_exit 1 "Unable to enable Block Change Tracking in $ORACLE_SID"
            echo ".. Block Change Tracking enabled for database '$ORACLE_SID'"
         else
            echo ".. Block Change Tracking already enabled for database '$ORACLE_SID', skipping..."
         fi
      }
   function process_all_SIDS {
      [[ -z $SIDS ]] && error_exit 1 "expected envar SIDS"
      for ORACLE_SID in $SIDS; do
         export ORACLE_SID
         sub_query_dbid
         sub_db_recovery_file_dest
         sub_sum_dg_output_bytes
         sub_compare_FRA_with_db_size
         sub_enable_bct
      done
   }
   function call_install_shield_cron_sh {
      echo "== Call install_shield_cron.sh to set crontab"
      # If all SIDS are non image copy, send no arguments
      # If all SIDS are image copy, send -c "$SIDS"
      # If there are some of each, send -c and -o 
      IMGCP_SIDS=$(echo -e "$SIDS\c" | tr '\n' ' ')
      NON_IMGCP_SIDS=$(echo "$IMG_SID_EXCLUDE_LIST" | sed 's/|/ /g')
      if [[ -z $IMGCP_SIDS ]]; then
         args=""
      elif [[ -z $NON_IMGCP_SIDS ]]; then
         args="-c \"$IMGCP_SIDS\""
      else
         args="-o \"$NON_IMGCP_SIDS\" -c \"$IMGCP_SIDS\""
      fi
      eval /home/oracle/system/rman/install_shield_cron.sh $args || error_exit 1 'couldn t run /home/oracle/system/rman/install_shield_cron.sh'
      crontab -l > /var/tmp/imgcp/crontab-l.txt
      echo ".. Wrote new cron (for reference see /var/tmp/imgcp/crontab-l.txt)"
   }

   #================================================================
   # Install the Inventory signature file
   #================================================================
   function install_signature_file
   {
      echo "== Installing signature file"
      SIGDIR="/home/oracle/system/signatures"
      SIGFILE="imgcp.sh.vdc"
   
      mkdir -p $SIGDIR
      [[ $? != 0 ]] && error_exit 25 "Unable to create signature directory"
   
      echo "imgcp.sh.vdc,129,RMAN Private Catalog 12.2.0,/home/oracle/system/signatures/imgcp.sh.vdc,Solaris" > $SIGDIR/$SIGFILE
   
      [[ $? != 0 ]] && error_exit 26 "Unable to create signature file"
      chmod 755 $SIGDIR/$SIGFILE
      echo ".. done"
   }
   #================================================================
   # Remove the Inventory signature file
   #================================================================
   function remove_signature_file
   {
      echo "== Removing signature file"
      SIGDIR="/home/oracle/system/signatures"
      SIGFILE="imgcp.sh.vdc"

      if [[ -f $SIGDIR/$SIGFILE ]]; then
         rm $SIGDIR/$SIGFILE
         [[ $? != 0 ]] && error_exit 27 "Unable to remove signature file"
         echo ".. Removed signature file"
      fi
      echo ".. done"
   }
   #================================================================
   # Backout the changes, if any
   #================================================================
   function backout_bct {
      echo "== Backout "
      echo ".. Backout Block Change Tracking"
      [[ -z $SIDS ]] && error_exit 1 "expected envar SIDS"
      for ORACLE_SID in $SIDS; do
         export ORACLE_SID
         if [[ -f /var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.sql ]]; then
            echo ".. Runnin backout file for SID '$ORACLE_SID'"
            (
               . /home/oracle/system/oraenv.usfs;
               PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.sql 2>&1 ) \
               > /var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.log
            grep -v ORA-19759 /var/tmp/imgcp/bct_enable.backout.$ORACLE_SID.log | grep -E 'ORA-|RMAN-' && error_exit 1 "Unable to backout Block Change Tracking in $ORACLE_SID"
            echo ".. Block Change Tracking enabled for database '$ORACLE_SID'"
         else
            echo ".. No backout file found for SID '$ORACLE_SID', skipping..."
         fi
      done
      echo ".. Done with backing out Block Change Tracking"
      echo ".. Backout crontab"
   }
   function backout_files {
      echo "== Backout files"
      for file in install_shield_cron.sh archivelog_mode.sh create_rcat.sql rman_backup.sh rman_restore_pitr_spfile_cf.sh; do
         if [[ -f /home/oracle/system/rman/$file.pre_imgcp ]]; then
            cp -p /home/oracle/system/rman/$file.pre_imgcp /home/oracle/system/rman/$file || error_exit 1 "couldn't backout file $file"
         fi
      done
   }
   
   
   ################################################################
   # MAIN
   ################################################################
   set_envars
   echo "$(date) Begin $0 'RMAN priviate catalog'"
   if [[ "$1" != "-b" && -n "$1" ]]; then
      script_usage
      error_exit 30 "unknown commandline option"
      exit 16
   fi

   # Check available free space in Kbytes
   check_freespace  5000 /tmp
   echo ".. free space prerequisite passed"
   
   # Check to make sure no backups are currently running
   check_oracle_software
   check_running_processes
   check_running_processes
   check_sysinfra_symlink
   
   # Verify required files are present
   check_required_files
   cp_scripts
   find_all_OH
   find_max_oracle_SW_version
   check_catalog_connection
   
   remove_rman_cron
   if [[ "$1" == "-b" ]]; then
      # Backout the Release Notice
      echo "== Begining backout"
      call_imgcp_archivelog_mode_sh -y -b
      backout_bct
      restore_cron
      backout_files
      remove_signature_file
      echo "$(date) SUCCESSFULLY COMPLETED BACKOUT PROCEDURE"
      exit 0
   fi
   call_imgcp_archivelog_mode_sh -y
   process_all_SIDS
   call_install_shield_cron_sh
   #restore_cron
   install_signature_file
   echo "$(date) SCRIPT COMPLETED SUCCESSFULLY"
} 2>&1 | tee $LOG
echo "Log is $LOG"
exit 0
