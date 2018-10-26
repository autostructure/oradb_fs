#!/usr/bin/env ksh
#  
#  @(#)fs615/db/ora/rman/linux/rh/rman_report_need_backup.sh, ora, build6_1, build6_1a,1.4:10/13/11:15:50:58
#  VERSION:  1.5
#  DATE:  04/24/13
#
#
#  (C) COPYRIGHT International Business Machines Corp. 2005 2007, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:

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

unset bu_lev
while getopts ho: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export SIDS="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) \
           "option is not a supported switch."
         usage_exit;;
   esac
done

if [[ -z "$SIDS" ]]; then
   SIDS=all
fi
if [[ $SIDS == @(all|ALL) ]]; then
   # Set the SIDS envar
   . /home/oracle/system/rman/usfs_local_sids
   echo SIDS=$SIDS
fi

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export RMN1_1=$TMP/rman_report_need_backup.1_1.rman
export RMN1_2=$TMP/rman_report_need_backup.1_2.rman

cat > $RMN1_1 <<EOF
report need backup redundancy 1;
EOF

cat > $RMN1_2 <<EOF
report need backup incremental 6 database;
EOF

# Define RMAN_SCHEMA and  RMAN_CATALOG
alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile




function report_sid {
   echo \
\###############################################################################

   export LOG_DIR=/opt/oracle/diag/bkp/rman/log
   mkdir $LOG_DIR $LOG_DIR/tmp 2> /dev/null
   chown oracle:dba $LOG_DIR $LOG_DIR/tmp
   chmod 700 $LOG_DIR $LOG_DIR/tmp

   export RAO1_1=$TMP/rman_report_need_backup.$ORACLE_SID.1_1.sh
   export RAO1_2=$TMP/rman_report_need_backup.$ORACLE_SID.1_2.sh
   export LOG1_1=$LOG_DIR/rman_report_need_backup.$ORACLE_SID.1_1.$$.log
   export LOG1_2=$LOG_DIR/rman_report_need_backup.$ORACLE_SID.1_2.$$.log

   echo "
      export ORACLE_SID=$ORACLE_SID
      echo ORACLE_SID=\$ORACLE_SID
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=\$ORACLE_HOME/bin:\$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
      rman target / catalog /@$RMAN_CATALOG cmdfile=$RMN1_1 2>&1 \
         | tee $LOG1_1" > $RAO1_1
   chmod 700 $RAO1_1
   chown oracle:dba $RAO1_1
   ksh $RAO1_1

   lrc=0
   if [[ ! -s $LOG1_1 ]] || grep 'ERROR MESSAGE STACK FOLLOWS' $LOG1_1; then
      echo "ERROR: RMAN failed to query repository." | tee -a $LOG1_1
      ((lrc=lrc+100))
   elif grep '^[0-9]* *[0-9]* *[+/]' $LOG1_1; then
      echo "ERROR: one or more data file is missing a full backup" \
          |tee -a $LOG1_1
      ((lrc=lrc+100))
   else
      echo "FYI: All data files reported as present" | tee -a $LOG1_1
   fi

   echo "
      export ORACLE_SID=$ORACLE_SID
      echo ORACLE_SID=\$ORACLE_SID
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=\$ORACLE_HOME/bin:\$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
      rman target / catalog /@$RMAN_CATALOG cmdfile=$RMN1_2 2>&1 \
         | tee $LOG1_2" > $RAO1_2

   chmod 700 $RAO1_2
   chown oracle:dba $RAO1_2
   ksh $RAO1_2


   if [[ ! -s $LOG1_2 ]] || grep 'ERROR MESSAGE STACK FOLLOWS' $LOG1_2; then
      echo "ERROR: RMAN failed to query repository." | tee -a $LOG1_2
      ((lrc=lrc+1))
   elif grep '^[0-9]* *[0-9]* *[+/]' $LOG1_2; then
      echo "ERROR: one or more data file requires more than 6 incremental" \
         |tee -a $LOG1_2
      echo "       backups to restore"  |tee -a $LOG1_2
      ((lrc=lrc+1))
   else
      echo "FYI: All data files reported to require fewer than 7 incremental" \
           "restores"|tee -a $LOG1_2
   fi
   return $lrc
}


export rc=0
export hit_one=0;
# Backup All
for ORACLE_SID in $SIDS; do
   (report_sid)
   imm_rc=$?
   if ((imm_rc==1)); then
      hit_one=1;
   fi
   (( rc = rc + imm_rc ))
done

if ((rc==0)); then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   exit 0
else
   if (($rc>=100)); then
      echo "ERROR: one or more data files missing a full backup."
   fi
   if (($rc%100>0)); then
      echo "ERROR: one or more data files requires more than 6 " \
           "incremental backups to restore."
   fi
   exit $rc
fi
