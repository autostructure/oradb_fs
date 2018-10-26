#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/insert_row1.sh, ora, build6_1, build6_1a,1.1:9/5/11:15:39:00
#  VERSION:  1.1
#  DATE:  9/5/11:15:39:00
#
#  (C) COPYRIGHT International Business Machines Corp. 2002
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Inserts one row into the tvoli.tsm_test table.


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

while getopts o: option
do
   case "$option"
   in
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
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $TMP"; exit 1; fi

export LOG_DIR=/home/oracle/system/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $LOG_DIR"; exit 1; fi

export RAO1=$TMP/insert_row1.1.sh
export LOG1=$LOG_DIR/insert_row1.1.$$.log

umask 077
cat > $RAO1 <<EOF2
  export ORACLE_SID=$ORACLE_SID
  # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
  . /home/oracle/system/oraenv.usfs
  PATH=\$ORACLE_HOME/bin:\$PATH
  export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
  sqlplus /nolog << EOF
     connect / as sysdba;
     -- shutdown immediate;
     -- shutdown abort;
     -- startup;
     drop table tsm_test;
     create table netbackup.tsm_test (my_col number);
     insert into netbackup.tsm_test values (1);
     select * from netbackup.tsm_test;
     commit;
EOF

   sleep 2
   date "+%Y-%m-%d:%H:%M:%S" | tee /tmp/time_stamp1.txt
EOF2

chmod 700 $RAO1
chown oracle:dba $RAO1
ksh $RAO1

echo "SCRIPT SUCCESSFULLY COMPLETED."
