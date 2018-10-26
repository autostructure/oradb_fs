#!/usr/bin/env ksh
#
#  %Z%%W%,%I%:%G%:%U%
#  VERSION:  %I%   #05/01/2013   v1.5
#  DATE:  %G%:%U%
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Perform database point in time recovery

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

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

export RAO1=$TMP/rman_restore_ptir.1.sh
export RAO1_1=$TMP/rman_restore_ptir.1_1.sh
export LOG1=$LOG_DIR/rman_restore_ptir.1.$$.log

function usage_exit
{
   echo "Usage:  rman_restore_pitr.sh {-o[ORACLE_SID]} [-tYYYY-MM-DD:HH:MI:SS|-sN]"
   echo "          Restores a database to a point in time."
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -t, time to restore to.  Note that HH is 24 hour time."
   echo "          -s N, restore until scn value of N."
   echo "          -p, preview the backup only"
   exit 1
}

export SHUTDOWN_IMMEDIATE='shutdown immediate;';
export ALLOCATE_DISK_CHANNELS='
        allocate channel d1 type disk;
        allocate channel d2 type disk;'
while getopts ho:t:s:p option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      t) export rec_time="$OPTARG";;
      s) export scn="$OPTARG";;
      p) export PREVIEW_COMMENT="#"; 
         export PREVIEW="preview";
         unset ALLOCATE_DISK_CHANNELS ;
         export LOG1=$LOG_DIR/rman_restore_ptir.preview.1.$$.log
         export SHUTDOWN_IMMEDIATE="" ;;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi
if [[ "$rec_time" != [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then
   if [[ $scn != [0-9][0-9]* ]]; then
      usage_exit
   else
      set_until="set until scn = $scn;"
   fi
else
   set_until="set until time = '$rec_time';"
fi

# Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
. /home/oracle/system/rman/build_SEND_cmd.sh
export ALLOCATE_SBT_CHANNELS="
        allocate channel t1 type 'sbt_tape';
        allocate channel t2 type 'sbt_tape';
        $send_cmd
        "
echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"


umask 077
cat > $RAO1 <<EOF2
  export rec_time="$rec_time"
  echo "rec_time=$rec_time"
  export ORACLE_SID=$ORACLE_SID
  echo "ORACLE_SID=\$ORACLE_SID"

  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  echo ORACLE_HOME=\$ORACLE_HOME
  PATH=\$ORACLE_HOME/bin:\$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

  export NLS_LANG=american
  export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
  echo "
     run {
        $SHUTDOWN_IMMEDIATE
        startup mount;
        $ALLOCATE_DISK_CHANNELS
        $ALLOCATE_SBT_CHANNELS

        $set_until

        restore database $PREVIEW;
	$PREVIEW_COMMENT recover database;
     }
     " > $RAO1_1
     rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_1
EOF2

chmod 700 $RAO1
ksh $RAO1 2>&1 | tee -a $LOG1

if egrep "RMAN-06052:|RMAN-06025:|RMAN-06054:" $LOG1; then
   echo "ERROR: not all archive logs present."
   exit 1
fi

if [[ -f $LOG1 ]] && grep -q "RMAN-08004: full resync complete" $LOG1; then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   echo "    !!! IT IS CRITICAL THAT A FULL BACKUP BE TAKEN NOW !!!"
fi
