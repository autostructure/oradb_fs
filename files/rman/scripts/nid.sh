#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/nid.sh, ora, build6_1, build6_1a,1.2:10/13/11:15:50:51
#  VERSION:  1.2
#  DATE:  10/13/11:15:50:51
#
#  (C) COPYRIGHT International Business Machines Corp. 2003, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose: 
#    Give the database a new DBID.
this=${0##*/}
echo "START||$this|$(date "+%Y-%m-%d:%H:%M:%S")"

if [[ $USER != "oracle" ]]; then
   echo "ERROR: please run as oracle"
   exit 1
fi

function usage_exit {
   echo "$0 [-h] [-o ORACLE_SID]"
   echo "   -h help"
   echo "   -o database name"
   exit 1
}

unset ORACLE_SID
while getopts ho: option
do
   case "$option"
   in
      h) usage_exit 1;;
      o) export ORACLE_SID="$OPTARG";;
     \?)
         eval print -- "ERROR:" '$'$( echo $OPTIND - 1 | bs ) \
                       "option is not a supported switch."
         usage_exit 1;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi

export TMP=/tmp/rman
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $TMP"; exit 1; fi

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR $LOG_DIR/tmp 2> /dev/null
chown oracle:dba $LOG_DIR $LOG_DIR/tmp
chmod 700 $LOG_DIR $LOG_DIR/tmp
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $LOG_DIR"; exit 1; fi

export RAO1=$TMP/roa1_nid.sh
export LOG1=$LOG_DIR/roa1_nid.sh.log
export LOG1_output=$LOG_DIR/roa1_nid.sh.output.log
umask 077
cat > $RAO1 <<EOF
   export ORACLE_SID=$ORACLE_SID
   # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
   . /home/oracle/system/oraenv.usfs
   export PATH=\$ORACLE_HOME/bin:\$PATH
   export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
   
   echo Working...
   output=\$(
      echo "
         show user
         select 'Database name is '||chr(34)||name||chr(34) from v\\\$database
         
         l
         r

         startup
         show user
         select dbid from v\\\$database

         l
         r

         shutdown immediate
         startup mount
         select value from v\\\$parameter where name='cluster_database'

         l
         r

         select status from v\\\$instance

         l
         r

         exit" \
         | sqlplus "/ as sysdba"
   )
   echo "output=\$output" | tee $LOG1_output
   if [[ \$output == *TRUE* ]]; then
      echo "ERROR: database parameter cluster_database=TRUE."
      exit 1
   fi
   if [[ \$output != *MOUNTED* ]]; then
      echo "ERROR: database instance able to be put in MOUNT state"
      exit 2
   fi

   echo Y|nid target=sys/sys
   
   echo ORACLE_SID=\$ORACLE_SID
   
   echo "
      spool $LOG1
      --shutdown immediate
      startup mount
      select dbid from v\\\$database;
      alter database open resetlogs;
      exit" \
   | sqlplus "/ as sysdba"
EOF
chown oracle:dba $RAO1
chmod 700 $RAO1
ksh $RAO1
if [[ ! -s $LOG1 ]]; then
   echo "ERROR log file missing ($LOG1)"
   exit 1
fi
if grep ORA- $LOG1|grep -v 'ORA-01109: database not open'; then
   echo "ERROR: nid failed."
   exit 1
fi
echo "SCRIPT SUCCESSFULLY COMPLETED|$ORACLE_SID|$this|$(date "+%Y-%m-%d:%H:%M:%S")"
