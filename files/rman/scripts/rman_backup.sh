#!/usr/bin/env ksh
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #3/13/2012   v12.2.1
#  DATE:  %G%:%U%
#
#
#  (C) COPYRIGHT International Business Machines Corp. 2003 2004, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Perform a full backup.
#    See usage below.
#
# Changes:
#    03/03/2011 Getting this error
#          RMAN-00571: ===========================================================
#          RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
#          RMAN-00571: ===========================================================
#          RMAN-03009: failure of backup command on t4 channel at 03/03/2011 00:00:53
#          ORA-19506: failed to create sequential file, name="l4_FILEDB_2205681967_48107_1_2__vbm5qppl_1_2__ip=165.221.42.87_dbid=2205681967", parms=""
#          ORA-27028: skgfqcre: sbtbackup returned error
#          ORA-19511: Error received from media manager layer, error text:
#            ANU2503E Backup object '/oracle_fs_10.2.0.4//l4_FILEDB_2205681967_48107_1_2__vbm5qppl_1_2__ip=165.221.42.87_dbid=2205681967' already exists on backup Server.
#       I found this file in TSM: 
#            4. |  02/28/2011  23:45:14    3,004.77GB     /oracle_fs_10.2.0.4//l4_FILEDB_2205681967_48107_1_2__vbm5qppl_1_2__ip=165.221.42.87_dbid=2205681967^M
#       The unque number (%U) in the format statements is failing.
#       Therefore, the RMAN reference (b14194) says %s and %t are unque as well.
#       It already has %s, so I'm adding both %T and %t.
#       The %T would have solved this case sufficiently, and %t is documented to solve it by the manual.
#    03/09/2012 
#       Added configuration files for allocating and release channels to support Image Copy.
#       Non Image Copy machines can ignore these files and the default configuration will still work.
#       These are the configuration files:      
#          /home/oracle/system/rman/fs615_allocate_sbt.ora
#          /home/oracle/system/rman/fs615_allocate_disk.ora
#          /home/oracle/system/rman/fs615_release_disk.ora
#
#       The following suggestions are based on 10g nodes, which will change in 11g.
#       MCI: 
#          SUGGESTED ALLOCATE SBT
#             cat > /home/oracle/system/rman/fs615_allocate_sbt.ora <<\EOF
#                     allocate channel t1 type 'sbt_tape' connect /@filedb6 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                     allocate channel t2 type 'sbt_tape' connect /@filedb5 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                     allocate channel t3 type 'sbt_tape' connect /@filedb6 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                     allocate channel t4 type 'sbt_tape' connect /@filedb5 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                     allocate channel t5 type 'sbt_tape' connect /@filedb6 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#             EOF
#          SUGGESTED ALLOCATE DISK CHANNELS
#             cat > /home/oracle/system/rman/fs615_allocate_disk.ora <<\EOF
#                  allocate channel d1 type disk connect /@filedb5;
#                  allocate channel d2 type disk connect /@filedb5;
#                  allocate channel d3 type disk connect /@filedb6;
#                  allocate channel d4 type disk connect /@filedb6;
#             EOF
#          SUGGESTED RELEASE DISK CHANNELS
#             cat > /home/oracle/system/rman/fs615_release_disk.ora <<\EOF
#                  release channel d1;
#                  release channel d2;
#                  release channel d3;
#                  release channel d4;
#             EOF
#
#       PRP: 
#          SUGGESTED ALLOCATE SBT
#             cat > /home/oracle/system/rman/fs615_allocate_sbt.ora <<\EOF
#                allocate channel t1 type 'sbt_tape' connect /@filedb1 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                allocate channel t2 type 'sbt_tape' connect /@filedb2 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                allocate channel t3 type 'sbt_tape' connect /@filedb2 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#                allocate channel t4 type 'sbt_tape' connect /@filedb1 parms 'ENV=(TDPO_OPTFILE=/opt/tivoli/tsm/client/oracle/bin64/tdpo.opt)';
#             EOF
#          SUGGESTED ALLOCATE DISK CHANNELS
#             cat > /home/oracle/system/rman/fs615_allocate_disk.ora <<\EOF
#                  allocate channel d1 type disk connect /@filedb1;
#                  allocate channel d2 type disk connect /@filedb1;
#                  allocate channel d3 type disk connect /@filedb2;
#                  allocate channel d4 type disk connect /@filedb2;
#             EOF
#          SUGGESTED RELEASE DISK CHANNELS
#             cat > /home/oracle/system/rman/fs615_release_disk.ora <<\EOF
#                  release channel d1;
#                  release channel d2;
#                  release channel d3;
#                  release channel d4;
#             EOF
#9/12/13 - Place %t at the end of peice names for Veritas performance, see https://www.veritas.com/support/en_US/article.000087057




# The below error stack shows the group of errors that can be safely
# ignored:
# RMAN-00571: ===========================================================
# RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
# RMAN-00571: ===========================================================
# RMAN-03002: failure during compilation of command
# RMAN-03013: command type: backup
# RMAN-06004: ORACLE error from recovery catalog database: RMAN-20242: specification does not match any archivelog in the recovery catalog

alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile

export NLS_LANG=american
export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'


#############################################################################
print "Step 32.1.1 - Verify user ID is oracle"
#############################################################################
export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle"
   exit 1
fi

function usage_exit
{
   echo "Usage:  rman_backup.sh {-l[0|1|2|3|4]} {-o[list of ORACLE_SID]} -t <tag> {-a} {-i image copy lag [hour] }"
   echo "        -l, Where 0 is a full backup and 4 is incremental, and archived logs."
   echo "        -l, Omitting the 0-4 backs up only archive logs."
   echo "        -o, Values for ORACLE_SID i.e. -oa, -oddb, -o\"admin a tdb\", -oall"
   echo "        -t <tag> backup tag, i.e. -t weeekly_full_bu"
   echo "        -a only backup archive logs."
   echo "        -c cold backup with database in mount state"
   echo "        -i <lag time [hours]> recover image copy backup, keep specified lag between the DB and the copy"
   echo "        -i specify 0 lag time, to keep image copy as close as possible to the database"
   echo "        -i recovering the Image Copy with is done in the background."
   echo "        -r <lag time [hours]> recover image copy backup, keep specified lag between the DB and the copy"
   echo "        -r specify 0 lag time, to keep image copy as close as possible to the database"
   exit 1
}

export SWITCH_LOGFILES="
        run {
           sql \"alter system switch logfile\";
           sql \"alter system switch logfile\";
           sql \"alter system switch logfile\";
           sql \"alter system switch logfile\";
           sql \"alter system switch logfile\";
           sql \"alter system switch logfile\";
        }
"
# HACK, SWITCH_LOGFILES is suspected of causing this error
# RMAN-01009: syntax error: found "at": expecting one of: "double-quoted-string, equal, identifier, single-quoted-string"
unset SWITCH_LOGFILES  #HACK this is a workaround for RMAN-01009

if [[ -s /home/oracle/system/rman/fs615_allocate_sbt.ora ]]; then
   export ALLOCATE_SBT_CHANNELS=$(cat /home/oracle/system/rman/fs615_allocate_sbt.ora)
else
   export ALLOCATE_SBT_CHANNELS="
                   allocate channel t1 type 'sbt_tape';
                   allocate channel t2 type 'sbt_tape';"
fi
if [[ -s /home/oracle/system/rman/fs615_allocate_disk.ora ]]; then
   export ALLOCATE_DISK_CHANNELS=$(cat /home/oracle/system/rman/fs615_allocate_disk.ora)
else
   export ALLOCATE_DISK_CHANNELS="
                   allocate channel d1 type disk;
                   "
fi
if [[ -s /home/oracle/system/rman/fs615_release_disk.ora ]]; then
   export RELEASE_DISK_CHANNELS=$(cat /home/oracle/system/rman/fs615_release_disk.ora)
else
   export RELEASE_DISK_CHANNELS="
                   release channel d1;
                   "
fi
# Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
. /home/oracle/system/rman/build_SEND_cmd.sh
export ALLOCATE_SBT_CHANNELS="$ALLOCATE_SBT_CHANNELS
                   $send_cmd
                   "
echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"

################################################################################
function func_compute_img_cp_end_time {
   # Input: 
   # Output: $DURATION_HR is the hours until 6:00AM the next day
   #         $DURATION_MI is the minutes until 6:00AM the next day

   # The !d in bash will fail.  Only use ksh!
   export DURATION_HR=$(
      echo "select 'hours='||trunc(24*(trunc(sysdate +18/24)+6/24-sysdate)) from dual;" | sqlplus / as sysdba | sed "/^hours=/!d;s|hours=||"
   )
   echo DURATION_HR=$DURATION_HR
   if [[ $(echo "$DURATION_HR" | sed 's/^[0-9][0-9]*//') != "" ]]; then
      echo "ERROR: could not compute duration endtime DURATION_HR='$DURATION_HR'"
      exit 1
   fi

   # The !d in bash will fail.  Only use ksh!
   export DURATION_MI=$(
      echo " select 'mins='||trunc(60*(24*(trunc(sysdate +18/24)+6/24-sysdate)-trunc(24*(trunc(sysdate +18/24)+6/24-sysdate)) )) from dual;" | sqlplus / as sysdba | sed "/^mins=/!d;s|mins=||"
   )
   echo DURATION_MI=$DURATION_MI
   if [[ $(echo "$DURATION_MI" | sed 's/^[0-9][0-9]*//') != "" ]]; then
      echo "ERROR: could not compute duration endtime DURATION_MI='$DURATION_MI'"
      exit 1
   fi
}
################################################################################

unset bu_lev
unset tag
unset IMGCP_CMD
unset IMGCP_FLAG
unset IMGCP_RECOVER

while getopts hLl:o:t:aci:r: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export SIDS="$OPTARG";;
      l) export bu_lev="$OPTARG";;
      t) export tag="tag='$OPTARG'";;  #Used in rman_backup.sh
      a) export archive_only="YES";;
      c) unset SWITCH_LOGFILES; export COLDBU="YES";;
      L) export LONG_T=_LongT;;
      i) export IMGCP_FLAG="ImgCpIncToFRA";
         export imgcp_lag="$OPTARG";;
      r) export IMGCP_FLAG="ImgCpRecover";
         export imgcp_lag="$OPTARG";
         export IMGCP_RECOVER="
                   recover copy of database with tag 'imgcp_update' until time 'trunc(sysdate)+1';

                   $RELEASE_DISK_CHANNELS

                   # Write incremental backups from SATA to tape now the Image Copy was recovered
                   backup format 'spfile_%d_%T-%s_%p_%t' (spfile);
                   backup format 'cf_%d_%T-%s_%p_%t'  (current controlfile);
                   backup backupset all
                      format 'l${bu_lev}_%d_%T-%I_%s_%p_${LONG_T}_%U__ip=$(host $(hostname)|sed 's|,.*||;s|.* ||')_dbid=@DBID@_%t';
                   backup format 'spfile_%d_%T-%s_%p_%t' (spfile);
                   backup format 'cf_%d_%T-%s_%p_%t'  (current controlfile);
                   " 
         ;;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

if [[ -z "$tag" ]]; then
   if [[ -z $bu_lev ]] || (($bu_lev==0)); then
      export tag="tag='Full'"
   else
      export tag="tag='Incremental'"
   fi
   if [[ -n $LONG_T ]]; then
      export tag="tag='LongTerm'"
   fi
fi

# Strip off "tag=''" from $tag for the log file name
LOG_TAG=${tag%\'}
LOG_TAG=${LOG_TAG#tag=\'}
if [[ $archive_only="YES" ]]; then
  LOG_TAG="archive"
fi
echo LOG_TAG=$LOG_TAG
[[ -z $HOSTNAME ]] && HOSTNAME=$(hostname)

if [[ -n "$IMGCP_FLAG" && -z "$IMGCP_RECOVER" ]]; then
   export IMGCP_CMD="backup incremental level $bu_lev for recover of copy with tag 'imgcp_update' database;" ;
fi


if [[ -n "$IMGCP_FLAG" && -z "$bu_lev" ]]; then
   echo "ERROR: the -i and the -r flag modifies the behaviour of -l flag, it uses image copy. -l need to be specified"
   usage_exit
fi

if [[ -n "$IMGCP_FLAG" && "$bu_lev" == 0 ]]; then
   export IMGCP_FLAG=FcToSbt
fi

export LOGPRUNE=30   # In days
export BKP_LOG=/opt/oracle/diag/bkp/rman/log
if [[ ! -d $BKP_LOG ]]; then
  echo "ERROR: $BKP_LOG is required.  Please ask the sys admin team to create the /opt/oracle/diag NFS mountpoint from /nfsroot/<domain>/orapriv/<clustername>/db/diag ."
  echo "       Consult the 'DB Maintenance Release Notice'"
  exit 1
fi

# prune logs older than LOGPRUNE in days
[[ -d $BKP_LOG/tmp ]] || mkdir $BKP_LOG/tmp
find $BKP_LOG $BKP_LOG/tmp -name "*rman*" -type f -mtime +${LOGPRUNE} -exec rm -f {} \;
find $BKP_LOG $BKP_LOG/tmp -name "*ocr2tsm*" -type f -mtime +${LOGPRUNE} -exec rm -f {} \;
find /tmp/rman -type f -mtime +14 -exec rm -f {} \;
find /fslink/sysinfra/oracle/common/rman/$HOSTNAME -type f -mtime +${LOGPRUNE} -exec rm -f {} \;

# 11g default set
# CONFIGURE RETENTION POLICY TO REDUNDANCY 1; # default
# CONFIGURE BACKUP OPTIMIZATION OFF; # default
# CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
# CONFIGURE CONTROLFILE AUTOBACKUP OFF; # default
# CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F'; # default
# CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
# CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
# CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
# CONFIGURE MAXSETSIZE TO UNLIMITED; # default
# CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
# CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
# CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
# CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
# CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/var/lpp/oracle/product/12.2/db_1/dbs/snapcf_orcl1.f'; # default

CONFIGURE_SET="
        CONFIGURE BACKUP OPTIMIZATION ON;
        CONFIGURE CONTROLFILE AUTOBACKUP OFF;
        CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE sbt to 'cf_%d_%F_%T_%t';
        CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE disk to 'cf_%d_%F_%T-%t';
        CONFIGURE CHANNEL DEVICE TYPE sbt MAXPIECESIZE 1000G;
        CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
        CONFIGURE BACKUP OPTIMIZATION ON;
        CONFIGURE DEFAULT DEVICE TYPE TO DISK;
        CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET;
        CONFIGURE DATAFILE   BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
        CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
        CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT   'l${bu_lev}_%d_%T-%I_%s_%p_%c__%U_%t';
        CONFIGURE MAXSETSIZE TO UNLIMITED;
        CONFIGURE ENCRYPTION FOR DATABASE OFF;
        CONFIGURE ENCRYPTION ALGORITHM 'AES128';
        # 11g CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ;
        CONFIGURE ARCHIVELOG DELETION POLICY TO NONE;
        # Can't get set generally CONFIGURE SNAPSHOT CONTROLFILE NAME TO '$ORACLE_HOME/dbs/snapcf_$ORACLE_SID.f';
"

export ARCHIVE_BACKUP_CODE="
        $CONFIGURE_SET
        run {
           $ALLOCATE_SBT_CHANNELS

           backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
           backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);

           backup filesperset 20
                    format 'arc_%d_%T-%I_%s_%p_%c_%U__ip=$(host $(hostname)|sed 's|,.*||;s|.* ||')_dbid=@DBID@_%t'
                     archivelog from sequence 0 thread = 1 delete all input
                     archivelog from sequence 0 thread = 2 delete all input
                     archivelog from sequence 0 thread = 3 delete all input
                     archivelog from sequence 0 thread = 4 delete all input
                     archivelog from sequence 0 thread = 5 delete all input
                     archivelog from sequence 0 thread = 6 delete all input
                     archivelog from sequence 0 thread = 7 delete all input
                     archivelog from sequence 0 thread = 8 delete all input
                     archivelog from sequence 0 thread = 9 delete all input
                     archivelog from sequence 0 thread = 10 delete all input
                     archivelog from sequence 0 thread = 11 delete all input
                     archivelog from sequence 0 thread = 12 delete all input
                     archivelog from sequence 0 thread = 13 delete all input
                     archivelog from sequence 0 thread = 14 delete all input
                     archivelog from sequence 0 thread = 15 delete all input
                     archivelog from sequence 0 thread = 16 delete all input
                     archivelog from sequence 0 thread = 17 delete all input
                     archivelog from sequence 0 thread = 18 delete all input
                     archivelog from sequence 0 thread = 19 delete all input
                     archivelog from sequence 0 thread = 20 delete all input
                     archivelog from sequence 0 thread = 21 delete all input
                     archivelog from sequence 0 thread = 22 delete all input
                     archivelog from sequence 0 thread = 23 delete all input
                     archivelog from sequence 0 thread = 24 delete all input
                     archivelog from sequence 0 thread = 25 delete all input
                     archivelog from sequence 0 thread = 26 delete all input
                     archivelog from sequence 0 thread = 27 delete all input
                     archivelog from sequence 0 thread = 28 delete all input
                     archivelog from sequence 0 thread = 29 delete all input
                     archivelog from sequence 0 thread = 30 delete all input
                     archivelog from sequence 0 thread = 31 delete all input
                     archivelog from sequence 0 thread = 32 delete all input
                    ;
           backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
           backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);
         }"

unset DATABASE_BACKUP_CODE
if [[ "$bu_lev" == @(0|1|2|3|4) ]]; then

  if [[ -z "$IMGCP_FLAG" ]]; then
   export DATABASE_BACKUP_CODE="
        $CONFIGURE_SET
        run {
           $ALLOCATE_SBT_CHANNELS

           backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
           backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);

           backup
                incremental level = $bu_lev
                $tag
                filesperset 3
                format 'l${bu_lev}_%d_%T-%I_%s_%p_%c_${LONG_T}_%U__ip=$(host $(hostname)|sed 's|,.*||;s|.* ||')_dbid=@DBID@_%t'
                (database) ;
           backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
           backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);
        }
        $SWITCH_LOGFILES
        "

   elif [[ "$bu_lev" == @(1|2|3|4) && -n "$IMGCP_FLAG" ]]; then

           export DATABASE_BACKUP_CODE="
                $CONFIGURE_SET

                run {
                   $ALLOCATE_DISK_CHANNELS

                   crosscheck backup;
                   crosscheck copy;

                   $IMGCP_CMD

                   $ALLOCATE_SBT_CHANNELS

                   $IMGCP_RECOVER
                }
                $SWITCH_LOGFILES
                "


   elif [[ "$bu_lev" == 0 && -n "$IMGCP_FLAG" ]]; then
           func_compute_img_cp_end_time;
           export DATABASE_BACKUP_CODE="
                $CONFIGURE_SET
                run {
                   $ALLOCATE_SBT_CHANNELS

                   backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
                   backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);

                   #4/21/2011 Need to backup from fiber channel for speed.
                   #4/21/2011 BACKUP COPY OF DATABASE
                   BACKUP
                      duration $DURATION_HR:$DURATION_MI partial
                      DATABASE
                      $tag
                      filesperset 1
                      not backed up since time 'SYSDATE-7'
                      format 'l${bu_lev}_%d_%T-%I_%s_%p_%c_${LONG_T}_%U__ip=$(host $(hostname)|sed 's|,.*||;s|.* ||')_dbid=@DBID@_%t';
                   backup format 'spfile_%d_%T-%s_%p_%c_%u_%t' (spfile);
                   backup format 'cf_%d_%T-%s_%p_%c_%u_%t'  (current controlfile);
                }
                $SWITCH_LOGFILES
                "
   fi

else
   if [[ $archive_only != "YES" ]]; then
      usage_exit
   fi
fi
if [[ $archive_only == "YES" ]]; then
   unset DATABASE_BACKUP_CODE
else
   if [[ -n $IMGCP_FLAG ]]; then
      unset ARCHIVE_BACKUP_CODE
   fi
fi

if [[ -z "$SIDS" ]]; then
   SIDS=all
fi
if [[ $SIDS == @(all|ALL) ]]; then
   # Set the SIDS envar
   . /home/oracle/system/rman/usfs_local_sids
   echo SIDS=$SIDS
fi

#set -x
#if ! ps -ef | grep -q ora_pmon[_]$ORACLE_SID;then
#   /home/oracle/system/start_oracle -o "$ORACLE_SID"
#   if ! ps -ef | grep -q ora_pmon[_]$ORACLE_SID;then
#      echo "ERROR: Could not start database."
#      exit 1
#   fi
#fi

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir -p $LOG_DIR $LOG_DIR/tmp 2> /dev/null
chown oracle:dba $LOG_DIR $LOG_DIR/tmp
chmod 700 $LOG_DIR $LOG_DIR/tmp


#================================================================
# Capture ASM Devices
#================================================================
function func_capture_ASM_devs
{
   # Requires: $LOG1
   echo "..Capture ASM Devices" | tee -a $LOG1

   cmd='
      set feedback off
      set pages 50
      set lines 95
      column name format a21
      column "Group Name" format a21
      column value format a57
      column Disk format a21
      column path format a30
      column Group format a21
      column compatibility format a15
      select name "Group Name",state,type,total_mb,free_mb,compatibility
      from   v$asm_diskgroup 
      order by name

      l
      r
      select b.name "Group Name", a.path, a.name "Disk"
      from   v$asm_disk a, v$asm_diskgroup b
      where  a.group_number = b.group_number
        and  a.group_number != 0
      order by b.name, a.name

      l
      r
      quit'
    echo "cmd=$cmd" >> $LOG1
   (sleep 1; echo "$cmd") | sqlplus -S / as sysdba 2>&1 | tee -a $LOG1 | tee $LOG1.func_capture_ASM_devs
   if egrep 'ORA-|SP[0-9]-' $LOG1.func_capture_ASM_devs; then
      echo "ERROR: ORA-00000 Unable to query ASM device to diskgroup mappings" | tee -a $LOG1
   fi
   rm $LOG1.func_capture_ASM_devs >> $LOG1 2>&1
}

#================================================================
#
#================================================================
function backup_sid {
   #echo "bu_lev=$bu_lev="
   #echo "ORACLE_SID=$ORACLE_SID"

   unset MODE

   export TMP=/tmp/rman
   mkdir $TMP 2> /dev/null
   chown oracle:dba $TMP
   chmod 700 $TMP

   export RAO1=$TMP/rman_backup.$ORACLE_SID.$$.1.sh
   export RAO1_1=$TMP/rman_backup.$ORACLE_SID.$$.1_1.rman
   export RAO1_1_1=$TMP/rman_backup.$ORACLE_SID.$$.1_1_1.rman
   export RAO1_2=$TMP/rman_backup.$ORACLE_SID.$$.1_2.rman
   export RAO1_3=$TMP/rman_backup.$ORACLE_SID.$$.1_3.rman
   export RAO1_3_1=$TMP/rman_backup.$ORACLE_SID.$$.1_3_1.rman
   export RAO1_4=$TMP/rman_backup.$ORACLE_SID.$$.1_4.rman
   export RAO1_5=$TMP/rman_backup.$ORACLE_SID.$$.1_5.sql
   export LOG1=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1.$$.log
   export LOG1_1=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1_1.$$.log
   export LOG1_2=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1_2.$$.log
   export LOG1_3=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1_3.$$.log
   export LOG1_4=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1_4.$$.log
   export LOG1_5=$LOG_DIR/rman_backup.$HOSTNAME.$LOG_TAG.$IMGCP_FLAG.$ORACLE_SID.1_5.$$.log

   echo "$LOG1" > $TMP/LOG1_path.$$.txt

   umask 077
   # Note: Tried this.  It did not work.
   #        backup
   #                maxsetsize = 100M
   #                format '%d_%s_%p_%c'
   #                archivelog all delete all input;

   # BACKUP MAXSETSIZE = 100M ARCHIVELOG ALL;

   #  export bu_lev="$bu_lev"
   #  export MODE="$MODE"
   #  echo "bu_lev=$bu_lev"
   #  echo "


   # This copy seems to solve this error stack:
   #   RMAN-00571: ===========================================================
   #   RMAN-00569: =============== ERROR MESSAGE STACK FOLLOWS ===============
   #   RMAN-00571: ===========================================================
   #   RMAN-03007: retryable error occurred during execution of command: backup
   #   RMAN-07004: unhandled exception during command execution on channel t1
   #   RMAN-10035: exception raised in RPC: ORA-19506: failed to create
   #                        sequential file, name="arc_A_259_1_1", parms=""
   #   ORA-27028: skgfqcre: sbtbackup returned error
   #   RMAN-10031: ORA-19624 occurred during call to
   #                         DBMS_BACKUP_RESTORE.BACKUPPIECECREATE

   # Uncomment these lines if necessary.  Otherwise, they erase the
   # virtual mount points the DFS backup needs.
   #   cp /usr/tivoli/tsm/client/ba/bin/dsm.sys.base \
   #      /usr/tivoli/tsm/client/ba/bin/dsm.sys


   cat > $RAO1_1 <<EOF2
        # Note: The below archivelog backup won't work unless the database is
        #       started.
        $ARCHIVE_BACKUP_CODE
EOF2
   chmod 700 $RAO1_1

   cat > $RAO1_3 <<EOF2
        # Note: The archivelog backup below won't work unless the database is
        #       started.
        $DATABASE_BACKUP_CODE
EOF2
   chmod 700 $RAO1_3

   cat > $RAO1_4 <<EOF2
      resync catalog;
EOF2
   chmod 700 $RAO1_4


   cat > $RAO1 <<EOF2
        #set -x
        export ORACLE_SID=$ORACLE_SID
        export archive_only=$archive_only
        export INSTANCE_ROOT=$INSTANCE_ROOT
        echo "ORACLE_SID=\$ORACLE_SID" | tee -a $LOG1
        echo "archive_only=\$archive_only" | tee -a $LOG1
        echo "INSTANCE_ROOT=\$INSTANCE_ROOT" | tee -a $LOG1

        # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH, etc
        . /home/oracle/system/oraenv.usfs
        PATH=\$ORACLE_HOME/bin:\$PATH
        export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

        bdump=\$(echo 'select '\'val=\''||value from v\$parameter where name='\''background_dump_dest'\'';' | sqlplus '/ as sysdba' | grep ^val=)
        bdump=\${bdump#*=}
        echo "bdump=\$bdump"

        export bin_cf=/opt/oracle/diag/bkp/rman/ctlfile/${ORACLE_SID}_$(date "+%a")_backup_controlfile.dbf
        echo "alter database backup controlfile to '\$bin_cf';
              alter database backup controlfile to trace;
              exit" > $RAO1_5
        chmod 700 $RAO1_5
        chown oracle:dba $RAO1_5

        echo "RUNNING RAO1_1 \$(date)" |tee -a $LOG1
        echo "   Try to start in mount mode." |tee -a $LOG1
        if ps -ef | grep -q [o]ra_pmon_${ORACLE_SID}; then
           :
        else
           echo "startup $MODE;" | sqlplus "/ as sysdba"| tee -a $LOG1
        fi
        DBID=\$(echo exit | rman target / | sed '/DBID/!d;s|.*=||;s|[^0-9]*)||')
        if [[ \$DBID != [0-9][0-9]*[0-9][0-9] ]]; then
           echo "ERROR: ORA-00000 FS615 RMAN script couldn't determine DBID"
           exit 1
        fi
        cp -p $RAO1_1 $RAO1_1_1
        sed "s|@DBID@|\$DBID|" $RAO1_1 > $RAO1_1_1

        rman target / nocatalog 2>&1 cmdfile=$RAO1_1_1| tee -a $LOG1
        export dest

        # Ignore the errors in $LOG1_1.  It may be that there are no
        # archived redo logs.  Don't need to report that one in any case.
        # That is why no output appended to $LOG1
        dest=\$(echo "
           set sqlprompt \\\"--\\\"
           set feed off
           set head off

           select 'path' || '=' || redo_path.value || '/' ||
              substr(vp.value,1,instr(vp.value,'%S')-1) ||
              '*' || substr(vp.value,instr(vp.value, '%S')+2)
           from v\\\$parameter vp,
                (select vp2.value from v\\\$parameter vp2
                 where vp2.name='log_archive_dest') redo_path
           where vp.name='log_archive_format';" | \
              sqlplus "/ as sysdba" | grep path= | sed 's|^path=||' )
        echo "dest=\$dest" | tee -a $LOG1_1

        # Ignore the errors in $LOG1_2.  This script only tries to find
        # old archived logs that were once deleted and now restored.
        # That is why no output appended to $LOG1
        echo "RUNNING RAO1_2 \$(date)" |tee -a $LOG1 | tee -a $LOG1_2
        echo "   Catalog any files in the archive directory." |tee -a $LOG1 | tee -a $LOG1_2
        if [[ -n "$dest" ]] && /bin/ls \$dest 2> /dev/null > /dev/null; then
           /bin/ls \$dest | sed "s|^|catalog archivelog '|;s|$|';|">$RAO1_2
           rman target / nocatalog 2>&1 cmdfile=$RAO1_2| tee -a $LOG1_2
           recataloged_some=YES
        fi

        DATABASE=\$(echo "$ORACLE_SID"|sed 's|.$||')
        echo "DATABASE=\$DATABASE      \$(date)" | tee -a $LOG1

        if [[ "$COLDBU" == "YES" ]]; then
           mount_state=\$(echo "
              set sqlprompt \\\"--\\\"
              set feed off
              set head off

              select 'mount_state' || '=' || status
              from v\\\$instance;" | \
                 sqlplus "/ as sysdba" | grep mount_state= | \
                    sed 's|^mount_state=||'
           )
           echo "Before stop mount_state=\$mount_state \$(date)" | tee -a $LOG1
           srvctl stop database -d \$DATABASE 2>&1 | tee -a $LOG1
           while ps -ef|grep [o]ra_pmon_$ORACLE_SID;do
              sleep 3;
              echo -e ".\c" | tee -a $LOG1
           done
           echo "Sleeping 30 seconds to allow pmon to stablize and close DB" \
               | tee -a $LOG1
           sleep 30
           echo "Starting database, mount" | tee -a $LOG1
           srvctl start database -d \$DATABASE -o mount 2>&1 | tee -a $LOG1
           echo "Before backup, waiting for database to start in MOUNT state \
                \$(date)" 2>&1 | tee -a $LOG1
           cnt=0
           while ((cnt<360)); do  # 360=1800/5, i.e. half an hour
              if ps -ef | grep [o]ra_pmon_$ORACLE_SID; then
                 break
              fi
              echo -e ".\c" 2>&1 | tee -a $LOG1
              sleep 5
              ((cnt=cnt+1))
           done
           echo "Sleeping 30 seconds to allow pmon to stablize and MOUNT DB" \
               | tee -a $LOG1
           sleep 30 # Give pmon 30 seconds to slablize
           mount_state=\$(echo "
              set sqlprompt \\\"--\\\"
              set feed off
              set head off

              select 'mount_state' || '=' || status
              from v\\\$instance;" | \
                 sqlplus "/ as sysdba" | grep mount_state= | \
                    sed 's|^mount_state=||'
           )
           echo "1:Before backup mount_state=\$mount_state    \$(date)" \
              | tee -a $LOG1_1
        fi

        if [[ "\$archive_only" != "YES" || "\$recataloged_some" == "YES" ]]; then
           echo "RUNNING RAO1_3 \$(date)" |tee -a $LOG1
           echo "   Backup the database" |tee -a $LOG1
           cp -p $RAO1_3 $RAO1_3_1
           sed "s|@DBID@|\$DBID|" $RAO1_3 > $RAO1_3_1
           export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
           rman target / nocatalog 2>&1 cmdfile=$RAO1_3_1| tee -a $LOG1 | \
                tee -a $LOG1_3
           #echo "Sleeping 60 seconds starting \$(date)."|tee -a $LOG1
           #sleep 60
           rman target / nocatalog 2>&1 cmdfile=$RAO1_1_1| tee -a $LOG1 | \
                tee -a $LOG1_3
        fi
        echo "==Resync the catalog" | tee -a $LOG1
        rman target / \
           catalog /@\$RMAN_CATALOG cmdfile=$RAO1_4 2>&1 \
           | tee -a $LOG1 | tee -a $LOG1_4

        #3/10/2012 11g RAC gives ORA-00245
        #3/10/2012 # Backup the control file to a local hard disk
        #3/10/2012 mkdir /var/lpp/oracle/diag/bkp/rman/ctlfile 2> /dev/null
        #3/10/2012 mv \$bin_cf \$bin_cf.previous 2> /dev/null
        #3/10/2012 sqlplus "/ as sysdba" @$RAO1_5 2>&1 | tee -a $LOG1 | tee -a $LOG1_5
        #3/10/2012 rm -f \$bin_cf.previous

        DATABASE=\$(echo "$ORACLE_SID"|sed 's|.$||')
        echo "DATABASE=\$DATABASE    \$(date)" | tee -a $LOG1
        if [[ "$COLDBU" == "YES" ]]; then
           mount_state=\$(echo "
              set sqlprompt \\\"--\\\"
              set feed off
              set head off

              select 'mount_state' || '=' || status
              from v\\\$instance;" | \
                 sqlplus "/ as sysdba" | grep mount_state= | \
                    sed 's|^mount_state=||'
           )
           echo "After backup, stop backup mount_state=\$mount_state \$(date)" \
              | tee -a $LOG1
           srvctl stop database -d \$DATABASE 2>&1 | tee -a $LOG1
           while ps -ef|grep [o]ra_pmon_$ORACLE_SID;do
              sleep 3;
              echo -e ".\c" | tee -a $LOG1
           done
           echo "Sleeping 30 seconds to allow pmon to stablize and close DB" \
               | tee -a $LOG1
           sleep 30
           # Start to OPEN it
           srvctl start database -d \$DATABASE 2>&1 | tee -a $LOG1
           cnt=0
           while ((cnt<360)); do  # 360=1800/5, i.e. half an hour
              if ps -ef | grep [o]ra_pmon_$ORACLE_SID; then
                 break
              fi
              echo -e ".\c" 2>&1 | tee -a $LOG1
              sleep 5
              ((cnt=cnt+1))
           done
           echo "Sleeping 30 seconds to allow pmon to stablize and OPEN DB" \
               | tee -a $LOG1
           sleep 30 # Give pmon 30 seconds to slablize
           mount_state=\$(echo "
              set sqlprompt \\\"--\\\"
              set feed off
              set head off

              select 'mount_state' || '=' || status
              from v\\\$instance;" | \
                 sqlplus "/ as sysdba" | grep mount_state= | \
                 sed 's|^mount_state=||'
           )
           echo "After backup,  mount_state=\$mount_state \$(date)" \
              | tee -a $LOG1
        fi
EOF2

   #set -x
   chmod 700 $RAO1
   chown oracle:dba $RAO1
   ksh $RAO1

   func_capture_ASM_devs

   if [[ -d /fslink/sysinfra/oracle/common/rman ]]; then
      mkdir /fslink/sysinfra/oracle/common/rman/$HOSTNAME/
      rsync -av $BKP_LOG/*$HOSTNAME*.1.* /fslink/sysinfra/oracle/common/rman/$HOSTNAME/
   fi
   if grep -q "RMAN-06089: " $LOG1; then
      #Next RMAN-06089: archived log %s not found or out of sync with catalog
      #echo "ERROR: missing an archivelog.  To force the backup, do"
      #echo "          ./rman_change_archivelog_all_crosscheck.sh"
      #echo "          ./rman_backup -l 0"
      #echo "       It is very important to do the level 0 backup."
      return 1
   elif [[ -f $LOG1_3 ]] && \
         egrep "ERROR MESSAGE STACK FOLLOWS|ORA-" $LOG1_3 > /dev/null; then
      return 2
   elif [[ -f $LOG1_4 ]] && \
         egrep "ERROR MESSAGE STACK FOLLOWS|ORA-" $LOG1_4 > /dev/null; then
      echo "ERROR: could not synchronize with remote catalog.  This needs to "
      echo "       be corrected within one day.  At a minimum, verify that"
      echo "       rman_cron_resync.sh is executed three times a day in"
      echo "       'crontab -l'.  Continuing."
      return 3
   elif [[ -f $LOG1_5 ]] && grep -q ORA- $LOG1_5; then
      echo "ERROR: could not make binary backup of controlfile"
      return 4
   elif [[ -f $LOG1_1 ]] && grep -q ORA- $LOG1_1; then
      return 5
   elif [[ -f $LOG1_2 ]] && grep -q ORA- $LOG1_2; then
      return 6
   elif grep ORA-00245 $LOG1; then
      # ORA-00245: control file backup failed; target is likely on a local file system
      # rman target / catalog $RMAN_SCHEMA@$RMAN_CATALOG
      # CONFIGURE SNAPSHOT CONTROLFILE NAME TO '+BZDB02AFRAGRP/snapcf_bzdb02.f';
      echo "ERROR ORA-00245 encoutered.  Please run 'cf_snapshot_in_recovery.sh -o $ORACLE_SID' to fix it."
      return 7
   elif grep ORA- $LOG1 | grep -qv 'RMAN-11001.*ORA-01109'; then
      return 8
   fi
   echo "SCRIPT SUCCESSFULLY COMPLETED. $(date)" | tee -a $LOG1
   return 0
}
#echo "Checking for incremental backup to kill" | tee -a $LOG_DIR/kill_incremenal.$$.log
#if [[ "$bu_lev" == 0 && -n "$IMGCP_FLAG" ]]; then
#   ps -ef | grep [r]man | grep -q -v -- '-l *0' >> $LOG_DIR/kill_incremenal.$$.log
#   if [[ $? == 0 ]]; then
#      echo "Killing any incremental backups" | tee -a $LOG_DIR/kill_incremenal.$$.log
#      ps -ef | grep rman | tee -a $LOG_DIR/kill_incremenal.$$
#      kill    $(ps -ef | grep [r]man | grep -v -- '-l *0' | awk '{print $2}' )
#      sleep 1
#      kill -9 $(ps -ef | grep [r]man | grep -v -- '-l *0' | awk '{print $2}' )
#      sleep 1
#      echo "Remaining RMAN processes" | tee -a $LOG_DIR/kill_incremenal.$$.log
#      ps -ef | grep rman | tee -a $LOG_DIR/kill_incremenal.$$.log
#   else
#      echo "No 'rman' processes found to kill" | tee -a $LOG_DIR/kill_incremenal.$$.log
#   fi
#fi

# Set permissions on logfiles so user oracle cannot write 

export rc=0
export hit_one=0;
# Backup All
for ORACLE_SID in $SIDS; do
   (backup_sid)
   imm_rc=$?
   if ((imm_rc==1)); then
      hit_one=1;
   fi
   (( rc = rc + imm_rc ))
done
set -x
if [[ $LOG_TAG == "archive" ]]; then
   if ! ps -ef | grep -v grep | grep [v]dc_prev.sh; then
      /home/oracle/system/rman/vdc_prev.sh
   fi
fi
set +x
export TMP=/tmp/rman
export LOG1=$(cat $TMP/LOG1_path.$$.txt)

export LOG1_6=$TMP/rman_backup.$ORACLE_SID.1_6.$$.log
/home/oracle/system/rman/rman_cron_resync.sh | tee $LOG1_6 | \
   grep -v "^SCRIPT SUCCESSFULLY COMPLETED"
grep -q "^SCRIPT SUCCESSFULLY COMPLETED" $LOG1_6
imm_rc=$?
(( rc = rc + imm_rc ))
echo "Only check the last log if this is 1) an Image Copy backup and 2) it is NOT a "recovery" of the Image Copy (SATA to SATA) $(date)" | tee -a $LOG1
if [[ -n "$IMGCP_FLAG" ]]; then 
   echo "Image Copy backup detected $(date)" | tee -a $LOG1
   if [[ -n "$IMGCP_CMD" && "$bu_lev" != 0 ]]; then #HACK testme 6/2/13
      echo "Check for errors in the last incremental backup $(date)" | tee -a $LOG1
      echo "\${#LOG_DIR}=${#LOG_DIR}" | tee -a $LOG1
      file=$(/bin/ls -1 -tr $LOG_DIR/rman_backup*ImgCpRecover*.1.*log | tail -1)
      if [[ $bu_lev != 0 ]]; then
         echo "Starting  (nohup /home/oracle/system/rman/rman_backup.sh -r \"$imgcp_lag\" -l${bu_lev} -o \"$SIDS\" & )    $(date) " | tee -a $LOG1
         (nohup /home/oracle/system/rman/rman_backup.sh -r "$imgcp_lag" -l${bu_lev} -o "$SIDS" & )
      fi
      if [[ -n $file ]]; then
         grep -v 'RMAN-20242' $file | egrep 'RMAN-|ORA-'
         if [[ $? == 0 ]]; then
            echo "ERROR: ORA-00000 RMAN-00000: last USFS incremntal backup failed. $(date)"  | tee -a $LOG1
            echo "See file $file"  | tee -a $LOG1
            exit 1
         else
            echo "Last incremntal backup applied to Image Copy suceeded. $(date)"  | tee -a $LOG1
         fi
      fi
   fi
fi

if ((hit_one==1)); then
   #Next RMAN-06089: archived log %s not found or out of sync with catalog
   echo "ERROR: missing an archivelog.  To force the backup, do $(date)" | tee -a $LOG1
   echo "          ./rman_change_archivelog_all_crosscheck.sh" | tee -a $LOG1
   echo "          ./rman_backup -l 0" | tee -a $LOG1
fi
if ((rc==0)); then
   echo "SCRIPT SUCCESSFULLY COMPLETED. $(date)" | tee -a $LOG1
else
   echo "ERROR: one or more backups or resynchronizations failed." | tee -a $LOG1
   echo "       Please wait 30 seconds before retrying." | tee -a $LOG1
   date
fi
exit $rc
