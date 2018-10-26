#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_change_archivelog_all_crosscheck.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:54
#  VERSION:  1.4
#  DATE:  04/26/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2003, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Remove information in the recovery catalog that doesn't exist on disk,
#    pertaining to archive logs.
#
#    This is useful if the file on disk was accidentally deleted and
#    RMAN won't back it up unless it is resolved.



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

function usage_exit {
   echo "Usage:  rman_change_archivelog_all_crosscheck.sh -o <SID>"
   echo "        Remove information in the recovery catalog that doesn't exist on disk."
   echo "        pertaining to archive logs.  Use when rman_backup.sh gets"
   echo "        an error that a archive file is missing from disk (RMAN-6089)"

   exit 1
}

unset bu_lev
while getopts ho: option
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

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

program="crosscheck_backup.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export LOG1=$LOG_DIR/$program.1.$$.log

{
   # Set  $NB_ORA_CLIENT  $NB_ORA_SERV  $NB_ORA_POLICY  and  $send_cmd,  log /opt/oracle/diag/bkp/rman/log/build_SEND_cmd.sh.log
   . /home/oracle/system/rman/build_SEND_cmd.sh
   export ALLOCATE_SBT_CHANNELS="allocate channel t1 type 'sbt_tape';
                      $send_cmd
                      "
   echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"

   if [[ -z "$ORACLE_SID" ]]; then
      . /home/oracle/system/rman/choose_a_sid.sh
   fi
   
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
           $ALLOCATE_SBT_CHANNELS
   
           crosscheck backup;
   
           release channel t1;
        }
        " > $RAO1_1
        rman target / catalog /@\$RMAN_CATALOG cmdfile=$RAO1_1 2>&1
EOF2
   
   chmod 700 $RAO1
   chown oracle:dba $RAO1
   ksh $RAO1
} 2>&1 | tee -a $LOG1

if grep -q "RMAN-08004: full resync complete" $LOG1; then
   echo "SCRIPT SUCCESSFULLY COMPLETED." | tee -a $LOG1
else
   exit 1
fi
exit 0
