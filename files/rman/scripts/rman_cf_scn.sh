#!/usr/bin/env ksh
#
#  rman_cf_scn.sh
#  VERSION:  1.3
#  DATE:  11/29/13
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
   echo "./rman_cf_scn.sh -o <sid> { -i <dbid>  |  -q }"
   echo "   -q assumes the last DBID is in the latest log for the given SID"
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
   export LOG=/opt/oracle/diag/bkp/rman/log/rman_cf_scn.sh.log
   touch $LOG
   chown oracle:dba $LOG
   chmod 700 $LOG
   export wc_LOG=$(cat $LOG | wc -l)

   export DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')
   echo DOMAIN=$DOMAIN 2>&1 | tee -a $LOG
   # For extrapolating a DBID from logs
   export LOG_DIR=/opt/oracle/diag/bkp/rman/log 
   export FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab
   export OLSNODES=$(find $(find /opt/grid -type d -name bin 2> /dev/null) -name olsnodes 2> /dev/null | head -1)

   mkdir /var/tmp/rman
   chmod 777 /var/tmp/rman
}
#================================================================
# Set envars
#================================================================
function conditionally_extrapolate_DBID_CMD {
   # If DBID_CMD is blank, extrapolate it from LOGS
   [[ -z "$ORACLE_SID" ]] && usage_exit
   [[ -z $DBID && -z $EXTRAPOLOTE ]] && usage_exit
   if [[ -z $DBID ]]; then
      grep DBID= $(ls -tr $LOG_DIR/rman_backup.*.$ORACLE_SID.*)|\
            sed 's|.*DBID=||;s|).*||;s|^|          |'|sort -u | tee -a $LOG
      DBID=$(grep DBID= $(ls -tr $LOG_DIR/rman_backup.*.$ORACLE_SID.*)| \
               sed 's|.*DBID=||;s|[,)].*||;'|sort -u|tail -1)
   fi
   echo "DBID=$DBID" | tee -a $LOG
   export DBID_CMD="set DBID=$DBID"
   echo "DBID_CMD=$DBID_CMD" | tee -a $LOG
}
#================================================================
# Check required files
#================================================================
function check_required_files {
   echo "== Check required files" 2>&1 | tee -a $LOG
   [[ -s /home/oracle/system/rman/rman_restore_pitr.sh ]] || \
      error_exit 13 "missing file /home/oracle/system/rman/rman_restore_pitr.sh"
   if [[ ! -s /home/oracle/system/rman/usfs_local_sids ]]; then
      cat >   /home/oracle/system/rman/usfs_local_sids <<\EOF
#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/usfs_local_sids, ora, build6_1, build6_1a,1.2:10/3/11:10:35:48
#  VERSION:  1.3
#  DATE:  10/3/11:10:35:48
# 
# Purpose:  List instance names on local host.
#
# Attention: Test any changes in bash, pdksh, and ksh93.
#
# Requires:
#    /etc/oratab
# Results:
#    Found ORACLE_SIDs are echoed to stdout
# 
# Suggested client invocation:   SIDS=$(fs_local_sids)

TAB=$(echo -e "\t")
# Turn off shell history subsititution for exclamation point
ps $$ | grep -q bash && set +H

export FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

# Check for local host being a RAC server
INSTNBR=$( ps -ef | sed "/asm_pmon_+AS[M]/!d;s|.*asm_pmon_+AS[M]||" )
if [[ -z "$INSTNBR" ]]; then
   INSTNBR=$( sed "/^[ $TAB]*#/d; /^+ASM[0-9]:/!d; s|+ASM\([0-9]*\):.*|\1|" $FS615_ORATAB)
fi
if [[ -n "$INSTNBR" ]]; then
   # This server is a RAC node
   # It is an error if a dbname ends with a numeral in oratab
   SIDS=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+|ASM|\*|MGMTDB" | cut -f1 -d: | \
      sed "s|$|$INSTNBR|")
else
   # This server is a Stand-Alone server
   SIDS=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+|ASM|\*|MGMTDB" | cut -f1 -d:)
fi
# Set $SID_EXCLUDE_LIST
eval $(sed "/^[ $TAB]*#/d; /export  *SID_EXCLUDE_LIST=/!d" rman_parameters.sh)
SIDS=$(echo "$SIDS" | egrep -v "$SID_EXCLUDE_LIST")
echo "$SIDS"
EOF
      chown oracle:dba /home/oracle/system/rman/usfs_local_sids 
      chmod 755        /home/oracle/system/rman/usfs_local_sids 
   fi
   if [[ ! -s /home/oracle/system/oraenv.usfs ]]; then
      cat >   /home/oracle/system/oraenv.usfs <<\EOF
#  @(#)fs615/db/ora/rman/linux/rh/oraenv.usfs, ora, build6_1, build6_1a,1.3:11/12/11:21:03:28
#  VERSION:  1.3
#  DATE:  11/12/11:21:03:28
#
# 
# Purpose: Source this file to get an ORACLE_HOME by looking up ORACLE_SID in /etc/oratab
#          Sets ORACLE_HOME regardless of RAC or stand-alone
#          Calls the standard /usr/local/bin/oraenv
#
# Attention: Test any changes in bash, pdksh, and ksh93.
#
# Requires:
#   ORACLE_SID
#
# Results:
#   Sets envars based on ORACLE_SID:
#     ORACLE_HOME, PATH, LD_LIBRARY_PATH, etc.
#   Setting TNS_ADMIN and/or modifying PATH is left to the user

TAB="	" #SunOS
TAB=$(echo -e "\t")
# For bash, turn off shell history substitution for exclamation point
ps $$ | grep -q bash && set +H

# Determine node/instance number for RAC nodes
INSTNBR=$( ps -ef | sed "/asm_pmon_+AS[M]/!d;s|.*asm_pmon_+AS[M]||" )
if [[ -z "$INSTNBR" ]]; then
   FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && FS615_ORATAB=/var/opt/oracle/oratab
   INSTNBR=$( sed "/^[ $TAB]*#/d; /^+ASM[0-9]:/!d; s|+ASM\([0-9]*\):.*|\1|" $FS615_ORATAB )
fi

# Preserve current value of ORACLE_SID
orig_ORACLE_SID=$ORACLE_SID

# If this server is a RAC node, strip instance number
# from ORACLE_SID before calling oraenv
if [[ -n "$INSTNBR" ]]; then
   export ORACLE_SID=${ORACLE_SID%${INSTNBR}}
fi

orig_ORACLE_BASE=$ORACLE_BASE
# Call oraenv to set PATH, ORACLE_HOME,
#  LD_LIBRARY_PATH (for RDBMS servers), etc.
# Setting TNS_ADMIN and/or modifying PATH is left to the user
which dbhome > /dev/null 2>&1 || PATH=$PATH:/usr/local/bin/
ORAENV_ASK=NO
. /usr/local/bin/oraenv < /dev/null

# Restore original value of ORACLE_SID
export ORACLE_SID=$orig_ORACLE_SID

# If ORACLE_HOME was set to the ~oracle default, then oraenv failed;
#  try again with original value of ORACLE_SID as restored above
if [[ "$ORACLE_HOME" == ~oracle ]]; then
   . /usr/local/bin/oraenv
fi
ORACLE_BASE=$orig_ORACLE_BASE
EOF
      chown oracle:dba /home/oracle/system/oraenv.usfs
      chmod 700        /home/oracle/system/oraenv.usfs
   fi
   echo ".. Pass" | tee -a $LOG
}
#================================================================
#  Put System name and Oracle ID in Log
#================================================================
function func_Log_Start {
   echo "== Log_Start ==" 2>&1 | tee -a $LOG
   Uname=$(uname -a)
   export DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')
   export ORACLE_SID
   echo "== Log_Start ==" >> $LOG.$ORACLE_SID
   echo "$(date "+%Y%m%d") Uname=$Uname  ORACLE_SID=$ORACLE_SID" 2>&1 | tee -a $LOG.$ORACLE_SID
   echo DOMAIN=$DOMAIN 2>&1 | tee -a $LOG.$ORACLE_SID
   echo "$(date "+%Y%m%d") Uname=$Uname  ORACLE_SID=$ORACLE_SID" >> $LOG.$ORACLE_SID 
}
#================================================================
#
#================================================================
function check_ORA_backup_node {
   echo "== Checking for crontab schedules for Oracle jobs" | tee -a $LOG
   crontab -l >> $LOG 2>&1

   echo "==Check Oracle for Oracle Backup Node" | tee -a $LOG
   if grep -q '^+ASM[0-9]' $FS615_ORATAB; then
      # RAC server
      # HACK this NODE code is not tested 4/9/14
      NODE=$(for node in $(ksh $OLSNODES); do echo node=$node >> /dev/tty; (( $(ssh $node crontab -l | grep -q /home/oracle/system/rman/rman_backup.sh | wc -l) > 2 )) && echo $node; done)
      echo "NODE=$NODE:" >> $LOG
      echo "echo \$NODE | wc -w =$(echo $NODE | wc -w):" >> $LOG
      # TRICKY CODE! Normally there would be one node, but the formal FS restore procedure
      # zeros out cron in one of the first steps.
      if (( $(echo $NODE | wc -w) != 0 )); then
         error_exit 9 "too many nodes (with crontab) in the cluster doing Oracle backups: $NODE"
      fi
      if [[ -n $NODE && $(hostname) != $NODE ]]; then
         error_exit 10 "wrong node for backups.  Please run on '$NODE' instead"
      fi
   else
      # Stand Alone server
      :
   fi
}
#================================================================
#
#================================================================
function check_user_oracle_envars {
   echo "==Check user oracle environmental variables" | tee -a $LOG
   rman_schema=$RMAN_SCHEMA
   echo "rman_schema=$rman_schema" >> $LOG
   [[ -z $rman_schema ]] && error_exit 12 'user oracle doesnt have $RMAN_SCHEMA set'
   rman_catalog=$RMAN_CATALOG
   echo "rman_catalog=$rman_catalog" >> $LOG
   [[ -z $rman_catalog ]] && error_exit 12 'user oracle doesnt have $RMAN_CATALOG set'
}
#================================================================
#
#================================================================
function tnsping_db_names {
   echo "== tnsping db_names" 2>&1 | tee -a $LOG
   export ORACLE_SID
   echo "ORACLE_SID=$ORACLE_SID" >> $LOG
   ORACLE_HOME=$(. /home/oracle/system/oraenv.usfs >/dev/null 2>/dev/null; \
      echo $ORACLE_HOME)
   echo ORACLE_HOME=$ORACLE_HOME >> $LOG
   [[ ! -d $ORACLE_HOME ]] && error_exit 4 "couldn't determine ORACLE_HOME for ORACLE_SID=$ORACLE_SID"
   if grep -q '^+ASM[0-9]' $FS615_ORATAB || ps -ef  | grep -q asm_pmon_+ASM ; then
      # Set the DB_NAME for RAC
      export DB_NAME=${ORACLE_SID%[0-9]}
   else
      # Set the DB_NAME for Stand Alone servers
      export DB_NAME=$ORACLE_SID
   fi
   echo "   DB_NAME=$DB_NAME" | tee -a $LOG
   (  export ORACLE_SID=$ORACLE_SID;
      . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      tnsping $DB_NAME
   ) > $LOG.tnsping_db_names.$ORACLE_SID.log 2>&1
   cat $LOG.tnsping_db_names.$ORACLE_SID.log >> $LOG
   grep TNS-[0-9][0-9][0-9][0-9][0-9] $LOG.tnsping_db_names.$ORACLE_SID.log \
      && error_exit 5 "ERROR running test tnsping_db_names"
}

#================================================================
# Find all the ORACLE_HOME valuse
#================================================================
function find_all_OH {
   # INPUT:  /home/oracle/system/rman/usfs_local_sids
   #         /home/oracle/system/oraenv.usfs
   # OUTPUT: $ALL_OH
   echo "== Find all values for ORACLE_HOME" | tee -a $LOG
   SIDS=$(/home/oracle/system/rman/usfs_local_sids)
   echo SIDS=$SIDS >> $LOG
   export ALL_OH=$(for ORACLE_SID in $SIDS; do
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
      . /home/oracle/system/oraenv.usfs > /dev/null
      echo $ORACLE_HOME
   done | sort -u)
   echo ALL_OH=$ALL_OH | tee -a $LOG
   if [[ ${#ALL_OH} == 0 ]]; then
      error_exit 39 "could not determine all of the ORACLE_HOME values"
   fi
}
#================================================================
# Find the maximum version from an Oracle Home
#================================================================
function find_max_oracle_SW_version {
   # INPUT:  $ALL_OH
   # OUTPUT:  Envars of   MAX_OH and MAX_VER
   echo "== Find Maximum Oracle Software version" | tee -a $LOG
   MAX_COMPVER=0.0
   for ORACLE_HOME in $ALL_OH; do
      VER=$( 
         export ORACLE_HOME=$ORACLE_HOME
         export PATH=$ORACLE_HOME/bin:$PATH
         export LD_LIBRARY_PATH=$ORACLE_HOME/lib
         echo | sqlplus /nolog 2>&1 | tee /var/tmp/rman/rcat.sqlplus.version.$$.log | sed '/ Release /!d;s|.*Release.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*|\1|' | tail -1 )
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
   echo MAX_OH=$MAX_OH | tee -a $LOG
   echo MAX_VER=$MAX_VER | tee -a $LOG
   if [[ ! -d $MAX_OH ]]; then
      error_exit 40 "ORACLE_HOME with max version is not a real directory"
   fi
}

#================================================================
#
#================================================================
function query_cf_scn {
   # Input: ORACLE_HOME
   # Output: $LOG.query_cf_scn.$ORACLE_SID.log
   echo "== Query control SCN" 2>&1 | tee -a $LOG
   echo "   SIDS=$SIDS" >> $LOG
   export SQLFILE=/home/oracle/system/query_cf_scn.sql
   export ORACLE_SID
   echo "DBID=$DBID" >> $LOG
   >$SQLFILE
   chmod 700        $SQLFILE
   cat > $SQLFILE <<EOF
      select 'cold_max_datafile_scn='||max(CHECKPOINT_CHANGE#) from RC_BACKUP_DATAFILE where db_key=(select db_key from rc_database where DBID=$DBID)

      l
      r
      select 'cold_cf_ckpt_scn='||max(CHECKPOINT_CHANGE#) 
         from RC_BACKUP_CONTROLFILE_DETAILS 
         where CHECKPOINT_CHANGE# <=
            (select max(CHECKPOINT_CHANGE#) from RC_BACKUP_DATAFILE where db_key=(select db_key from rc_database where DBID=$DBID) )

      l
      r
      alter session set NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

      l
      r
      select distinct 'cold_cf_ckpt_time='||CHECKPOINT_TIME from RC_BACKUP_CONTROLFILE_DETAILS 
         where CHECKPOINT_CHANGE#=
            (select max(CHECKPOINT_CHANGE#) 
                from RC_BACKUP_CONTROLFILE_DETAILS 
                where CHECKPOINT_CHANGE# <=
                  (select max(CHECKPOINT_CHANGE#) from RC_BACKUP_DATAFILE where db_key=(select db_key from rc_database where DBID=$DBID) ) )

      l
      r

      -- end of cold queries
      -- Begin 'regular' queries
      select 'max_arch_scn='|| max(NEXT_CHANGE#) 
         from RC_BACKUP_ARCHIVELOG_DETAILS 
         where db_key=(select DB_KEY from rc_database where DBID=$DBID)

      l
      r
      select 'ckpt='||max(CHECKPOINT_CHANGE#) 
         from RC_BACKUP_CONTROLFILE_DETAILS 
         where CHECKPOINT_CHANGE# < 
            (select max(NEXT_CHANGE#) 
             from RC_BACKUP_ARCHIVELOG_DETAILS 
             where db_key=(select DB_KEY from rc_database where DBID=$DBID) )

      l
      r
      alter session set NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

      l
      r
      select 'next_time='||NEXT_TIME from RC_BACKUP_ARCHIVELOG_DETAILS 
         where NEXT_CHANGE#=
            (select max(NEXT_CHANGE#) from RC_BACKUP_ARCHIVELOG_DETAILS 
             where db_key=(select DB_KEY from rc_database 
                           where DBID=$DBID) )

      l
      r
      exit
EOF
   ( export ORACLE_SID=$ORACLE_SID;
      . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
      sqlplus /@$RMAN_CATALOG @ $SQLFILE) > $LOG.query_cf_scn.$ORACLE_SID.log 2>&1
   cat $LOG.query_cf_scn.$ORACLE_SID.log >> $LOG
   grep ORA-[0-9][0-9][0-9][0-9][0-9] $LOG.query_cf_scn.$ORACLE_SID.log \
      | egrep -v '^ORA-00000|^ORA-01918' && \
      error_exit 5 "ERROR running test query_cf_scn"
   echo "" | tee -a $LOG
   echo "   ============== COLD BACKUP QUERIES =============" | tee -a $LOG
   COLD_MAX_DATAFILE_SCN=$(sed '/^cold_max_datafile_scn/!d; s|^cold_max_datafile_scn=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   COLD_MAX_DATAFILE_SCN=$COLD_MAX_DATAFILE_SCN" | tee -a $LOG
   echo "   ORACLE_SID=$ORACLE_SID" 2>&1 | tee -a $LOG
   echo "   DBID=$DBID" | tee -a $LOG
   COLD_CF_CKPT_TIME=$(sed '/^cold_cf_ckpt_time=/!d; s|^cold_cf_ckpt_time=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   COLD_CF_CKPT_TIME=$COLD_CF_CKPT_TIME" | tee -a $LOG
   COLD_CF_CKPT_SCN=$(sed '/^cold_cf_ckpt_scn=/!d; s|^cold_cf_ckpt_scn=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   COLD_CF_CKPT_SCN=$COLD_CF_CKPT_SCN" | tee -a $LOG
   echo "" | tee -a $LOG
   echo "   =============== ARC BASED QUERIES ==============" | tee -a $LOG
   MAX_ARC=$(sed '/^max_arch_scn=/!d; s|^max_arch_scn=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   MAX ARC=$MAX_ARC" | tee -a $LOG
   echo "   ORACLE_SID=$ORACLE_SID" 2>&1 | tee -a $LOG
   echo "   DBID=$DBID" | tee -a $LOG
   TS=$(sed '/^next_time=/!d; s|^next_time=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   CKPT NEXT_TIME=$TS" | tee -a $LOG
   SCN=$(sed '/^ckpt=/!d; s|^ckpt=||' $LOG.query_cf_scn.$ORACLE_SID.log)
   echo "   CF CKPT SCN=$SCN" | tee -a $LOG
   [[ -z "$SCN" && -z "$COLD_CF_CKPT_SCN" ]] && error_exit 16 "blank scn and 'cold' scn"
   echo "   ================================================" | tee -a $LOG
   > $LOG.for_preview
   echo "export MAX_ARC=$MAX_ARC;" >> $LOG.for_preview
   echo "export ORACLE_SID=$ORACLE_SID;" >> $LOG.for_preview
   echo "export DBID=$DBID;" >> $LOG.for_preview
   echo "export CKPT_NEXT_TIME=$TS;" >> $LOG.for_preview
   echo "export CF_CKPT_SCN=$SCN;" >> $LOG.for_preview
   rm -f $SQLFILE
}

#================================================================
#================================================================
### MAIN
set_envars
# getops can't be done in a function
   unset DB_ID
   while getopts ho:i:q option
   do
      case "$option"
      in
         h) usage_exit;;
         o) export ORACLE_SID="$OPTARG"; export SIDS=$ORACLE_SID;;
         i) export DBID="$OPTARG";;
         q) export EXTRAPOLOTE="YES";;
        \?)
            eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
            usage_exit;;
      esac
   done
conditionally_extrapolate_DBID_CMD
check_required_files
#10/21/2016  check_ORA_backup_node
check_user_oracle_envars
#RAC only   tnsping_db_names
func_Log_Start
find_all_OH 
find_max_oracle_SW_version 
query_cf_scn
echo "SCRIPT COMPLETED SUCCESSFULLY $(date)" | tee -a $LOG
