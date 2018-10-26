#!/usr/bin/env ksh
#
#  File: rman_restore_pitr.preview.3.sh
#  Version: 1.1
#  Date: 04/29/13
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

export LOG_DIR=/opt/oracle/diag/bkp/rman/log 
mkdir $LOG_DIR 2>/dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR
export LOG=$LOG_DIR/rman_restore_pitr.preview.3.sh.log.$(date "+%Y-%m-%d:%H:%M:%S")
export LOG=/opt/oracle/diag/bkp/rman/log/rman_restore_pitr.preview.3.sh.log
> $LOG
chown oracle:dba $LOG
chmod 700 $LOG

{
#================================================================
# Issue an error message and exit with the specified return code
#================================================================
function usage_exit {
   echo "./rman_cf_scn.sh -o <sid> { -i <dbid>  |  -q }"
   echo "Usage:  rman_restore_pitr.sh {-o[ORACLE_SID]} [-tYYYY-MM-DD:HH:MI:SS|-sN]"
   echo "          Restores a database to a point in time."
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -t, time to restore to.  Note that HH is 24 hour time."
   echo "          -s N, restore until scn value of N."
   echo "          -p, preview the backup only"
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
   # For extrapolating a DBID from logs
   export ALLOCATE_DISK_CHANNELS="
        allocate channel d1 type disk;"
   #unset ALLOCATE_DISK_CHANNELS ; #Preview unsets the disks

   # Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
   . /home/oracle/system/rman/build_SEND_cmd.sh
   export ALLOCATE_SBT_CHANNELS="
        allocate channel t1 type 'sbt_tape';
        $send_cmd
        "
   echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"
   export FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab
   export OLSNODES=$(find $(find /opt/grid -type d -name bin 2> /dev/null) -name olsnodes 2> /dev/null | head -1)
   echo "OLSNODES=$OLSNODES" >> $LOG

   mkdir /var/tmp/rman
   chmod 777 /var/tmp/rman
}
#================================================================
#
#================================================================
function quality_check_envars {
   echo "==Quality check envars"
   echo "ORACLE_SID=$ORACLE_SID"
   if [[ -z "$ORACLE_SID" ]]; then
      usage_exit
   fi
   echo "rec_time=$rec_time" >> $LOG
   if [[ "$rec_time" != [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then
      if [[ $scn != [0-9][0-9]* ]]; then
         usage_exit
      else
         export set_until="set until scn = $scn;"
      fi
   else
      export set_until="set until time = '$rec_time';"
   fi
}
#================================================================
# Check required files
#================================================================
function check_required_files {
   echo "== Check required files"
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

TAB="	"
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
   echo ".. Pass"
}
#================================================================
#
#================================================================
function check_ORA_backup_node {
   echo "==Check Oracle for Oracle Backup Node"
   if grep -q '^+ASM[0-9]' $FS615_ORATAB; then
      # RAC server
      NODE=$(for node in $(ksh $OLSNODES); do echo "node=$node" >> $LOG; ssh $node ls $ORACLE_HOME/lib/libobk.so >> $LOG 2>&1 && echo $node; done)
      echo "NODE=$NODE" >> $LOG
      if [[ $(echo $NODE | wc -w) == 0 ]]; then
         error_exit 11 "couldn't determin nodes in the cluster"
      fi
      echo "\$(echo $NODE | wc -w | sed 's| ||g')=$(echo $NODE | wc -w | sed 's| ||g')" >> $LOG
      if [[ $(echo $NODE | wc -w | sed 's| ||g') != 1 ]]; then
         error_exit 9 "too many nodes in the cluster doing Oracle backups (libobk.so): $NODE"
      fi
      echo "\$(hostname) != $NODE   IS   $(hostname) != $NODE" >> $LOG
      if [[ $(hostname) != $NODE ]]; then
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
   echo "==Check user oracle environmental variables" 
   rman_schema=$RMAN_SCHEMA
   echo "rman_schema=$rman_schema" >> $LOG
   [[ -z $rman_schema ]] && error_exit 12 'user oracle doesnt have $RMAN_SCHEMA set'
   rman_catalog=$RMAN_CATALOG
   echo "rman_catalog=$rman_catalog" >> $LOG
   [[ -z $rman_catalog ]] && error_exit 13 'user oracle doesnt have $RMAN_CATALOG set'
}
#================================================================
#
#================================================================
function tnsping_db_names {
   echo "== tnsping db_names"
   export ORACLE_SID
   echo "ORACLE_SID=$ORACLE_SID" >> $LOG
   ORACLE_HOME=$(. /home/oracle/system/oraenv.usfs >/dev/null 2>/dev/null; \
      echo $ORACLE_HOME)
   echo ORACLE_HOME=$ORACLE_HOME >> $LOG
   [[ ! -d $ORACLE_HOME ]] && error_exit 4 "couldn't determine ORACLE_HOME for ORACLE_SID=$ORACLE_SID"
   if grep -q '^+ASM[0-9]' $FS615_ORATAB || ps -ef  | grep -q asm_pmon_+ASM; then
      # Set the DB_NAME for RAC
      export DB_NAME=${ORACLE_SID%[0-9]}
   else
      # Set the DB_NAME for Stand Alone servers
      export DB_NAME=$ORACLE_SID
   fi
   echo "   DB_NAME=$DB_NAME"
   ( . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      tnsping $DB_NAME > $LOG.tnsping_db_names.$ORACLE_SID.log 2>&1 )
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
   echo "== Find all values for ORACLE_HOME"
   SIDS=$(/home/oracle/system/rman/usfs_local_sids)
   echo SIDS=$SIDS >> $LOG
   export ALL_OH=$(for ORACLE_SID in $SIDS; do
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
      . /home/oracle/system/oraenv.usfs > /dev/null
      echo $ORACLE_HOME
   done | sort -u)
   echo ALL_OH=$ALL_OH
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
   echo "== Find Maximum Oracle Software version"
   MAX_COMPVER=0.0
   for ORACLE_HOME in $ALL_OH; do
      VER=$( 
         export PATH=$ORACLE_HOME/bin:$PATH
         export LD_LIBRARY_PATH=$ORACLE_HOME/lib
         echo | sqlplus /nolog 2>&1 | tee /var/tmp/rcat.sqlplus.version.$$.log | sed '/ Release /!d;s|.*Release.\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*|\1|' | tail -1 )
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
   if [[ ! -d $MAX_OH ]]; then
      error_exit 40 "ORACLE_HOME with max version is not a real directory"
   fi
}
#================================================================
#
#================================================================
function query_dbid {
   # Input: $ORACLE_HOME
   # Output: $DBID
   echo "== Query DBID"
   export SQLFILE=$LOG.query_dbid.sql
   export ORACLE_SID
   cat > $SQLFILE <<\EOF
      select 'dbid='|| DBID from v$database

      l
      r
      exit
EOF
   chmod 700        $SQLFILE
   chown oracle:dba $SQLFILE
   (  export ORACLE_SID=$ORACLE_SID;
      . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      sqlplus '/ as sysdba' @$SQLFILE 
   ) > $LOG.query_dbid.$ORACLE_SID.log 2>&1 
   cat $LOG.query_dbid.$ORACLE_SID.log >> $LOG
   grep ORA-[0-9][0-9][0-9][0-9][0-9] $LOG.query_dbid.$ORACLE_SID.log \
      | egrep -v '^ORA-00000|^ORA-01918' && \
      error_exit 5 "ERROR running test query_dbid"
   export DBID=$(sed '/^dbid=/!d; s|^dbid=||' $LOG.query_dbid.$ORACLE_SID.log)
   echo "DBID=$DBID"
   [[ -z $DBID ]] && error_exit 16 "blank dbid"
}
#================================================================
#
#================================================================
function restore_preview {
   echo "== Restore preview"
   export ORACLE_SID
   echo "ORACLE_SID=$ORACLE_SID"
   export CMDFILE=$LOG.restore_preview.rmn
   cat > $CMDFILE <<EOF
      list backup of controlfile;
      list backup;
      run {
         $ALLOCATE_DISK_CHANNELS
         $ALLOCATE_SBT_CHANNELS
 
         $set_until
         restore database preview check readonly;
         release channel d1;
         release channel t1;
      }
EOF
   chmod 700        $CMDFILE
   chown oracle:dba $CMDFILE
   (  export ORACLE_SID=$ORACLE_SID;
      . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
      rman target / catalog /@$RMAN_CATALOG cmdfile=$CMDFILE 2>&1 
   ) | tee $LOG.restore_preview.$ORACLE_SID.log >> $LOG
   grep RMAN-[0-9][0-9][0-9][0-9][0-9] $LOG.restore_preview.$ORACLE_SID.log && \
      error_exit 5 "ERROR running test restore_preview"
   grep ORA-[0-9][0-9][0-9][0-9][0-9] $LOG.restore_preview.$ORACLE_SID.log && \
      error_exit 15 "ERROR running test restore_preview"
   egrep -v ' Nov|Compressed: NO  Tag:|not open|^no files cataloged$|[^ ][^ ]*no ' \
      $LOG.restore_preview.$ORACLE_SID.log | egrep -i 'no | not ' \
         && error_exit 16 \
         "ERROR pattern ' no' found in restore preview for instance '$ORACLE_SID' 
         in file '$LOG.restore_preview.$ORACLE_SID.log'"
   echo "Restore preview log='$LOG.restore_preview.$ORACLE_SID.log'"
}
#================================================================
#
#================================================================
function query_scn_gaps {
   #  
   #  #!/usr/bin/env ksh
   # These are the different paterns. One for archived logs, full backups, and incremental.
   #    List of Archived Logs in backup set 1652
   #    Thrd Seq     Low SCN    Low Time            Next SCN   Next Time
   #    ---- ------- ---------- ------------------- ---------- ---------
   #    1    589     1945561    2014-04-17:12:51:43 1946270    2014-04-17:13:04:14
   #  <snip>
   #  
   #  BS Key  Type LV Size       Device Type Elapsed Time Completion Time
   #  ------- ---- -- ---------- ----------- ------------ -------------------
   #  697     Full    499.75M    SBT_TAPE    00:00:40     2014-03-27:13:28:14
   #          BP Key: 713   Status: AVAILABLE  Compressed: NO  Tag: TAG20140327T132733
   #          Handle: 03p47ra6_1_1   Media: @aaaae
   #    List of Datafiles in backup set 697
   #    File LV Type Ckp SCN    Ckp Time            Name
   #    ---- -- ---- ---------- ------------------- ----
   #    1       Full 953377     2014-03-27:13:26:39 +SD04ADATAGRP/sd04a/datafile/system.256.845557627
   #  <snip>
   #  
   #    List of Datafiles in backup set 1684
   #    File LV Type Ckp SCN    Ckp Time            Name
   #    ---- -- ---- ---------- ------------------- ----
   #    1    0  Incr 1946818    2014-04-17:13:11:19 +SD04ADATAGRP/sd04a/datafile/system.256.845557627
   #  <snip>
   #  
   #  BS Key  Type LV Size       Device Type Elapsed Time Completion Time
   #  ------- ---- -- ---------- ----------- ------------ -------------------
   #  696     Full    18.00M     SBT_TAPE    00:00:32     2014-03-27:13:25:41
   #          BP Key: 712   Status: AVAILABLE  Compressed: NO  Tag: TAG20140327T132509
   #          Handle: 02p47r5l_1_1   Media: @aaaae
   #    Control File Included: Ckp SCN: 953286       Ckp time: 2014-03-27:13:25:09
   #  <snip>
   #  
   #  BS Key  Type LV Size       Device Type Elapsed Time Completion Time
   #  ------- ---- -- ---------- ----------- ------------ -------------------
   #  702     Full    256.00K    SBT_TAPE    00:00:23     2014-04-10:16:23:27
   #          BP Key: 718   Status: AVAILABLE  Compressed: NO  Tag: TAG20140410T162304
   #          Handle: spfile_SD04A_20140410-844532584_9_1_1_09p5d2r8   Media: @aaaae
   #    SPFILE Included: Modification time: 2014-04-02:12:06:58
   #    SPFILE db_unique_name: SD04A
   #  <snip>
   #  
   # I tried finding the max integer with this awk trial
   #    (echo; echo; echo) |awk 'BEGIN {i=1; while (1==1) { print i; i*=2 } } {prt "here" }' | head -67 | tail
   #    144115188075855872
   #    288230376151711744
   #    576460752303423488
   #    1152921504606846976
   #    2305843009213693952
   #    4611686018427387904
   #    9223372036854775808
   #    1.84467e+19
   #    3.68935e+19
   #    7.3787e+19
   # So it seems integers are limited to 64-bits
   # 9223372036854775808
   #DEBUG LOG=/opt/oracle/diag/bkp/rman/log/rman_restore_pitr.preview.3.sh.log
   #DEBUG LOG=/tmp/list_backup.cdb.2014-04-23.log
   MIN_AWK=$LOG.min.awk
   # TRICKY CODE: The awk code is catted to $LOG, then $LOG is parsed.
   #    It works because a line is only parsed if $1 is numeric ([0-9][0-9]*) and none of the awk code has $1 numeric
   cat > $MIN_AWK <<\EOF
     BEGIN {MIN_SCN=9223372036854775808; dbg=1; skip_header=1}
      {
         if ( $0 ~ /^List of Backup Sets/ ) skip_header=0
         if ( skip_header == 0 ) {
            # Section to set live_data_follows
               # live_data_follows is a state var.  Zero means its to ignore lines (no SCNs.)
               # Blank lines and ones without leading whitespace mark the end of a section.
               if ( length($0) == 0 ) live_data_follows=0
               if ( $0 !~ /^ / ) live_data_follows=0
               if ( $0 ~ /^  Thrd/ ) { live_data_follows=1; getline; getline; } # Arc log header
               if ( $0 ~ /^  File LV Type Ckp SCN/ ) { live_data_follows=2; getline; getline; } # Full BU header

            # Section to print per live_data_follows
               SCN=9223372036854775808
               if ( live_data_follows == 1 && $1 ~ /^[0-9][0-9]*$/ && $3 ~ /^[0-9][0-9]*$/ ) {SCN=$3; if (dbg) print $0}
               if ( live_data_follows == 2 ) {
                  if ( $1 ~ /^[0-9][0-9]*$/ && $2 == "Full" && $3 ~ /^[0-9][0-9]*$/ ) {SCN=$3; if (dbg) print $0}
                  # So far, Ive only seen $2=="0"
                  if ( $1 ~ /^[0-9][0-9]*$/ && $3 == "Incr" && $4 ~ /^[0-9][0-9]*$/ ) {SCN=$4; if (dbg) print $0}
               }
               if (MIN_SCN>SCN) {MIN_SCN=SCN; if (dbg) print SCN}
               #print "live_data_follows==" live_data_follows ": " $0
         }
      }
      END {print "MIN_SCN=" MIN_SCN}
EOF
   echo "cat $MIN_AWK" >> $LOG
   cat $MIN_AWK >> $LOG
   MIN_SCN=$(awk  -f $MIN_AWK $LOG | tail -1)
   export MIN_SCN=${MIN_SCN#MIN_SCN=}
   echo "Ddebug this with:  MIN_SCN=\$(awk -v dbg=1 -f $MIN_AWK $LOG )" >> $LOG
   echo "Result was: MIN_SCN=$MIN_SCN" >> $LOG
}
#================================================================
#
#================================================================
function query_catalog_for_gaps {
   echo "== Query catalog for gaps" 2>&1
   export ORACLE_SID
   echo "ORACLE_SID=$ORACLE_SID" 2>&1
   export CMDFILE=$LOG.query_catalog_for_gaps.sql
   cat > $CMDFILE <<EOF
      set sqlprompt "--"
      set feed off
      set head off
      select 'Next_Change#='||next_change# from (
         select next_change# from rc_backup_archivelog_details arc where db_name=upper('$DB_NAME')
         minus
         select arc.next_change# from rc_backup_archivelog_details arc,
            (select first_change# as fscn from rc_backup_archivelog_details arc 
               where db_name=upper('$DB_NAME') ) b
            where arc.next_change# = b.fscn
            and db_name=upper('$DB_NAME')
         minus
         select max(next_change#) from rc_backup_archivelog_details arc where db_name=upper('$DB_NAME')
      )

      l
      r
      exit
EOF
   chmod 700        $CMDFILE
   chown oracle:dba $CMDFILE
   (  export ORACLE_SID=$ORACLE_SID;
      . /home/oracle/system/oraenv.usfs;
      PATH=$ORACLE_HOME/bin:$PATH;
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet;
      sqlplus /@$RMAN_CATALOG @$CMDFILE 2>&1 
   ) | tee $LOG.query_catalog_for_gaps.$ORACLE_SID.log >> $LOG
   grep ORA-[0-9][0-9][0-9][0-9][0-9] $LOG.query_catalog_for_gaps.$ORACLE_SID.log && \
      error_exit 16 "ERROR running test restore_preview"
   NEXT_CHANGE=$(sed '/^Next_Change#=/!d; s|^Next_Change#=||' $LOG.query_catalog_for_gaps.$ORACLE_SID.log)
   echo "NEXT_CHANGE=$NEXT_CHANGE" >> $LOG
   [[ -n "$NEXT_CHANGE" ]] && error_exit 17 "gap(s) in the System Change Number (SCN) found at: $NEXT_CHANGE
      See the seq number with:
         select * from v\$loghist where  FIRST_CHANGE# <= $NEXT_CHANGE and $NEXT_CHANGE <= SWITCH_CHANGE#;
      See the 'list backup' in $LOG
      If there are no errors with 'no' in the text, the restore will likely succeed.
      Do a case insensitive search for 'no' now in $LOG."
   echo "No gaps found in archivelog System Change Numbers (SCNs)"
set -x
}

#================================================================
### MAIN
set_envars
# getops can't be done in a function
   unset DB_ID
   while getopts ho:t:s:pg option
   do
      case "$option"
      in
         h) usage_exit;;
         o) export ORACLE_SID="$OPTARG";;
         t) export rec_time="$OPTARG";;
         s) export scn="$OPTARG";;
         p) export PREVIEW_COMMENT="#";
            export PREVIEW="preview";;
         g) export SKIP_GAP_TEST="YES";;
        \?)
            eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
            usage_exit;;
      esac
   done
quality_check_envars
check_required_files

#check_ORA_backup_node
check_user_oracle_envars
tnsping_db_names
find_all_OH 
find_max_oracle_SW_version 
query_dbid
restore_preview
query_scn_gaps
set -x
[[ -z $SKIP_GAP_TEST ]] && query_catalog_for_gaps
echo "SCRIPT COMPLETED SUCCESSFULLY $(date)"
} 2>&1 | tee -a $LOG
grep -q "^SCRIPT COMPLETED SUCCESSFULLY" $LOG || exit 1
exit 0
