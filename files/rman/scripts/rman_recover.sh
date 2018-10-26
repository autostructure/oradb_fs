#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_recover.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:57
#  VERSION:  1.4
#  DATE:  05/01/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Performs a database recovery while connected to the RMAN repository
#    and the NetBackup server.  This will cause any needed redo logs that are 
#    not on local storage to be pulled in from NetBackup automatically.


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
   echo "Usage:  rman_recover.sh {-o[ORACLE_SID]} -bN"
   echo "        -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   exit 1
}

while getopts h:o: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi

#echo "ORACLE_SID=$ORACLE_SID"
#echo "B_KEY=$B_KEY"
#exit


export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

export RAO1=$TMP/rman_recover.sh.1.sh
export RAO1_1=$TMP/rman_recover.sh.1_1.sh
export RAO1_2=$TMP/rman_recover.sh.1_2.sh
export LOG1=$LOG_DIR/rman_recover.1.$$.log

{
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
     export ORACLE_SID=$ORACLE_SID
     echo "ORACLE_SID=\$ORACLE_SID"
     export sub_dir=$sub_dir
     echo "ORACLE_SID=\$ORACLE_SID"
     echo "sub_dir=\$sub_dir"
     export NLS_LANG=american
     export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
   
     # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
     . /home/oracle/system/oraenv.usfs
     PATH=\$ORACLE_HOME/bin:\$PATH
     export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
   
     echo "
        run {
           $ALLOCATE_SBT_CHANNELS
           allocate channel d1 type disk;
   
           startup force mount;
   
           recover database;
   
           release channel t2;
           release channel t1;
        }
     " > $RAO1_2
     rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_2 2>&1
EOF2

   chmod 700 $RAO1
   chown oracle.dba $RAO1
   ksh $RAO1

} 2>&1 | tee -a $LOG1
if egrep "ERROR MESSAGE STACK FOLLOWS" $LOG1 > /dev/null
then
   egrep 'ERROR MESSAGE STACK FOLLOWS|RMAN-|ORA-' $LOG1
   exit 1
fi
echo "SCRIPT SUCCESSFULLY COMPLETED." | tee -a $LOG1
exit 0

