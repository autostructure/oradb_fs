#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_restore_df.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:51:00
#  VERSION:  1.4
#  DATE:  04/26/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Perform datafile recovery

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

program="rman_restore_df.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export LOG1=$LOG_DIR/$program.1.$$.log

function usage_exit
{
   echo "Usage:  $program {-o[ORACLE_SID]} -n[datafile_number]"
   echo "          Restores a database datafile."
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -n [datafile_number] datafile number to restore"
   exit 1
}

while getopts ho:n: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      n) export DFILE="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi
if [[ -z "$DFILE" ]]; then
   usage_exit
fi

echo -e "Did you ensure the '$DFILE' datafile was 
offline or that the database is merely mounted: (y[n])\c "
read resp
if [[ $resp != @(y|Y|yes|YES) ]]; then
   echo "Please take it off line first"
   exit 1
fi



umask 077
function func_main {
   # Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
   . /home/oracle/system/rman/build_SEND_cmd.sh
   export ALLOCATE_SBT_CHANNELS="
         allocate channel t1 type 'sbt_tape';
         allocate channel t2 type 'sbt_tape';
         $send_cmd
         "
   echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"

   export connection="$connection"
   export DFILE="$DFILE"

   echo "connnection=$connection"
   echo "DFILE=$DFILE"

   export ORACLE_SID=$ORACLE_SID
   echo "ORACLE_SID=$ORACLE_SID"

   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
   # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
   . /home/oracle/system/oraenv.usfs
   PATH=$ORACLE_HOME/bin:$PATH
   export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

   # RMAN-06403 was being caused by starting in rman's run{} command.
   # Problem appeared in RDBMS 9.2.0.6.
   echo "startup mount;" | sqlplus "/ as sysdba"

   echo "
      run {
         allocate channel d1 type disk;
         allocate channel d2 type disk;
         $ALLOCATE_SBT_CHANNELS

         restore datafile $DFILE;
         recover datafile $DFILE;

         release channel d1;
         release channel d2;
         release channel t1;
         release channel t2;
      }
      " > $RAO1_1
      rman target / catalog /@$RMAN_CATALOG cmdfile=$RAO1_1 2>&1
}

func_main 2>&1 | tee -a $LOG1

if grep -E "ORA-|RMAN-" $LOG1; then
   exit 1
fi
echo "SCRIPT SUCCESSFULLY COMPLETED." | tee -a $LOG1
exit 0
