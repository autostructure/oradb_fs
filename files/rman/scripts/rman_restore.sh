#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_restore.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:58
#  VERSION:  1.4
#  DATE:  04/29/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Perform database restore


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

program="rman_restore.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export LOG1=$LOG_DIR/$program.1.$$.log
export RAO2=$TMP/$program.2.sh
export LOG2=$LOG_DIR/$program.2.$$.log

function usage_exit
{
   echo "Usage:  rman_restore.sh {-o[ORACLE_SID]}"
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   exit 1
}

while getopts ho:p option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      p) export PREVIEW_COMMENT="#"; export PREVIEW="preview" ;;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi

# Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
. /home/oracle/system/rman/build_SEND_cmd.sh
export ALLOCATE_SBT_CHANNELS="$ALLOCATE_SBT_CHANNELS
        allocate channel t1 type 'sbt_tape';
        allocate channel t2 type 'sbt_tape';
        $send_cmd
        "
echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"

umask 077
cat > $RAO1 <<EOF2
   export ORACLE_SID=$ORACLE_SID
   echo "ORACLE_SID=\$ORACLE_SID"
   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
   # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
   . /home/oracle/system/oraenv.usfs
   PATH=\$ORACLE_HOME/bin:\$PATH
   export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
   echo "
     run {
        startup mount;
        allocate channel d1 type disk;
        allocate channel d2 type disk;
        $ALLOCATE_SBT_CHANNELS


        restore database $PREVIEW;
        $PREVIEW_COMMENT recover database;

        release channel d1;
        release channel d2;
        release channel t1;
        release channel t2;
     }
     " > $RAO1_1
     rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_1
EOF2

chmod 700 $RAO1 2>&1 | tee -a $LOG1
ksh $RAO1

if egrep "RMAN-06025|RMAN-06054" $LOG1; then
   echo "ERROR: recovery failed to find all logs."
   exit 1
fi
if egrep "ORA-00205: error in identifying controlfile, check alert log for more info|ORA-00210: cannot open the specified controlfile" $LOG1 > /dev/null; then 
   # Look for any controlfile
   file=/idb/dbs/config$ORACLE_SID.ora
   if [[ ! -f $file ]]; then
      echo "ERROR: could not file $file."
      exit 1
   fi

   missing=0
   present=0
   for cf in $(( tr '\n' ' ' < $file; echo)| \
        sed "s|.*control_files[ ${TAB}]*=[ ${TAB}]*(||;s|).*||;s|,||g"); do
     if [[ -f $cf ]]; then
        (( present = present + 1 ))
     else
        (( missing = missing + 1 ))
     fi
   done
   echo "missing=$missing"
   echo "present=$present"

   if (( present > 0 )); then
      echo "ERROR: some control files present, some missing."
      echo "       You must decided whether to try to use them or"
      echo "       to restore them.  Use /home/oracle/system/reccon.sh to "
      echo "       use them as is.  Run"
      echo "          extrapolate_dbid.sh -o$ORACLE_SID"
      echo "          rman_restore_cf.sh -o$ORACLE_SID -r -i<dbid>"
      echo "             (where <dbid> is from extrapolate_dbid.sh)"
      echo "       to overwrite the ones that already exist."
      exit 1
   fi
   echo "ERROR: control file missing.  To restore a backup controlfile, run:"
   echo "          extrapolate_dbid.sh -o$ORACLE_SID"
   echo "          rman_restore_cf.sh -o$ORACLE_SID -r -i<dbid>"
   echo "             (where <dbid> is from extrapolate_dbid.sh)"
   exit 1
fi

if [[ -f $LOG1 ]] && ! grep -q "ERROR MESSAGE STACK FOLLOWS" $LOG1; then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
fi
