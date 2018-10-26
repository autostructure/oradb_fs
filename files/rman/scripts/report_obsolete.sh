#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/report_obsolete.sh, ora, build6_1, build6_1a,1.1:10/13/11:15:55:10
#  VERSION:  1.2
#  DATE:  04/24/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Delete an old backup.


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

program="report_obsolete.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export RAO1_2=$TMP/$program.1_2.sh
export LOG1=$LOG_DIR/$program.1.$$.log

function usage_exit
{
   echo "Usage:  rman_oldest_filename.sh {-o[ORACLE_SID]}"
   echo "        Finds the oldest file in the backup server."
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   exit 1
}

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
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi

if [[ -z "$RMAN_REDUNDANCY" ]]; then
   # Number of copies of a backup.
   # 4 weekly full backups equates to 1 month of backups
   export RMAN_REDUNDANCY=4
   if [[ $(hostname) == "slmciordb025" || $(hostname) == "slprpordb009" ]]; then
      export RMAN_REDUNDANCY=2
   fi
fi

function func_main {
  echo "ORACLE_SID=$ORACLE_SID"

  export NLS_LANG=american
  export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  PATH=$ORACLE_HOME/bin:$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  echo "
     report obsolete redundancy=$RMAN_REDUNDANCY;
  " > $RAO1_1
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  rman target / catalog /@$RMAN_CATALOG cmdfile=$RAO1_1 2>&1 | tee -a $LOG1
  # Set these envars:   key date file
  eval $(grep '^Backup Set' $LOG1 | head -1 | \
     awk '{print "export key="$3"; export date="$4"; export file="$5}' )
  echo -e "Write down filename: \c"; 
     grep "^Backup Piece.*$date" $LOG1 | awk '{print $5}'
  echo "Write down key:      $key"
}

func_main

echo "SCRIPT SUCCESSFULLY COMPLETED."
