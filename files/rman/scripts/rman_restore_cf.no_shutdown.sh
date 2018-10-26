#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_restore_cf.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:59
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
#    Restore the control file from the current incarnation to /tmp/cf.tmp.


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

export TMP=/tmp/rman/
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

program="rman_restore_cf.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export LOG1=$LOG_DIR/$program.$$.log

function usage_exit
{
   echo "Usage:  rman_restore_cf.sh {-o[ORACLE_SID]} {-r} {-i[DBID]}"
   echo "          Restores the last backed up controlfile to /tmp/cf.tmp"
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   echo "          -r, replicate restored file to /idb/dbms*"
   echo "          -i, specifies DBID to remove ambiguity."
   exit 1
}

unset DB_ID
while getopts ho:ri: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export ORACLE_SID="$OPTARG";;
      r) export replicate_to_dest="          replicate controlfile from '/tmp/cf.tmp';"
         dash_r_option='-r';;
      i) export DBID_CMD="set DBID=$OPTARG";;
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
export ALLOCATE_SBT_CHANNELS="
        allocate channel t1 type 'sbt_tape';
        $send_cmd
        "
echo "ALLOCATE_SBT_CHANNELS=$ALLOCATE_SBT_CHANNELS"

umask 077
cat > $RAO1 <<EOF2
  export ORACLE_SID=$ORACLE_SID
  echo "ORACLE_SID=\$ORACLE_SID"

  export TBS="$TBS"
  echo "TBS=\$TBS"
  export replicate_to_dest="$replicate_to_dest"
  echo "replicate_to_dest=\$replicate_to_DESt"
  export NLS_LANG=american
  export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  PATH=\$ORACLE_HOME/bin:\$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  echo "
     $DBID_CMD
     connect target /
     run {
        allocate channel d1 type disk;
        $ALLOCATE_SBT_CHANNELS

        restore controlfile to '/tmp/cf.tmp';
        $replicate_to_dest
        release channel d1;
        release channel t1;
     }
     " > $RAO1_1
     rman catalog /@$RMAN_CATALOG cmdfile=$RAO1_1 2>&1 | tee -a $LOG1
EOF2

chmod 700 $RAO1
chown oracle:dba $RAO1
ksh $RAO1

if egrep "RMAN-20005: target database name is ambiguous|ORA-00210: cannot open the specified controlfile" $LOG1 > /dev/null; then
   echo "ERROR: The database ID must be specified."
   echo "       This grep command shows DBID's for database $ORACLE_SID with the latest"
   echo "       being at the bottom.:"
   echo "          grep DBID= \$(ls -tr $LOG_DIR/rman_backup.$ORACLE_SID.*)"
   echo "       The last number is _likely_ to be the DBID for database '$ORACLE_SID':"
   grep DBID= $(ls -tr $LOG_DIR/rman/rman_backup.$ORACLE_SID.*)|\
      sed 's|.*DBID=||;s|).*||;s|^|          |'|sort -u
   candidate=$(grep DBID= $(ls -tr $LOG_DIR/rman_backup.$ORACLE_SID.*)|\
      sed 's|.*DBID=||;s|).*||;'|sort -u|tail -1)
   echo "       Then run this script again with the -i option, i.e.:"
   echo "          rman_restore_cf.sh -o$ORACLE_SID $dash_r_option -i$candidate"
   echo "       where $candidate is _probably_ the DBID of database '$ORACLE_SID'"
   echo "       Please inspect the rman_backup.$ORACLE_SID.* logs with the above grep"
   echo "       command to determine the true DBID now, then rerun rman_restore_cf.sh"
   echo "       with the -i option."
   exit 1
elif grep -q "RMAN-06024: no backup or copy of the controlfile found to resto" \
     $LOG1; then
   echo "ERROR: No backup of controlfile found.  Please manualy check"
   echo "       for an old copy of another incarnation in RMAN."
   exit 1
elif ! grep -q "ERROR MESSAGE STACK FOLLOWS" $LOG1; then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
fi
