#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/show_max_archived_log_scn.sh, ora, build6_1, build6_1a,1.4:10/13/11:15:51:02
#  VERSION:  1.5
#  DATE:  04/24/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Shows the last system change number (scn) in the RMAN catalog.


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

program="show_max_log_scn.sh"
export RAO1=$TMP/$program.1.sh
export RAO1_1=$TMP/$program.1_1.sh
export LOG1=$LOG_DIR/$program.1.$$.log
export RAO2=$TMP/$program.2.sh
export LOG2=$LOG_DIR/$program.2.$$.log

function usage_exit
{
   echo "Usage:  show_max_log_scn.sh -i[DBID]"
   echo "          -i, specifies the database id (required)"
   echo "          (Determine the DBID with /home/oracle/system/rman/extrapolate_dbid.sh)"
   exit 1
}

function func_find_last_scn
{
   umask 077
   cat > $RAO2 <<EOF2
      export ORACLE_SID=$ORACLE_SID
      echo "ORACLE_SID=\$ORACLE_SID"
      export NLS_LANG=american
      export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'

      # Set $RMAN_SCHEMA
      alias shopt=': '; UID=\$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile #BASH
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=\$ORACLE_HOME/bin:\$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet

      MAX_SCN_QUERY="
         set serveroutput on size 1000000
         connect /@\$RMAN_CATALOG
         select 'orig_redo_scn='|| (max(log.NEXT_CHANGE#)-1)
         from \$RMAN_SCHEMA.RC_DATABASE db, 
              \$RMAN_SCHEMA.RC_DATABASE_INCARNATION carn, 
              \$RMAN_SCHEMA.RC_BACKUP_REDOLOG log 
         where 
            db.dbid=$DBID and
            db.DB_KEY=carn.DB_KEY and
            carn.CURRENT_INCARNATION='YES' and
            carn.DBINC_KEY=log.DBINC_KEY and
            carn.DB_KEY=log.DB_KEY 
         order by NEXT_CHANGE#;

         DECLARE
         ret_val varchar2(256);
         max_cf_scn varchar2(256);
         max_redo_scn varchar2(256);
         BEGIN
         select (max(log.NEXT_CHANGE#)-1) into max_redo_scn
         from \$RMAN_SCHEMA.RC_DATABASE db,
              \$RMAN_SCHEMA.RC_DATABASE_INCARNATION carn,
              \$RMAN_SCHEMA.RC_BACKUP_REDOLOG log
         where
            db.dbid=$DBID and
            db.DB_KEY=carn.DB_KEY and
            carn.CURRENT_INCARNATION='YES' and
            carn.DBINC_KEY=log.DBINC_KEY and
            carn.DB_KEY=log.DB_KEY
         order by NEXT_CHANGE#;
         select 'max_redo_scn='|| (max(log.NEXT_CHANGE#)-1) into ret_val
         from \$RMAN_SCHEMA.RC_DATABASE db,
              \$RMAN_SCHEMA.RC_DATABASE_INCARNATION carn,
              \$RMAN_SCHEMA.RC_BACKUP_REDOLOG log
         where
            db.dbid=$DBID and
            db.DB_KEY=carn.DB_KEY and
            carn.CURRENT_INCARNATION='YES' and
            carn.DBINC_KEY=log.DBINC_KEY and
            carn.DB_KEY=log.DB_KEY
         order by NEXT_CHANGE#;
         select 'max_cf_scn='|| (max(log.CHECKPOINT_CHANGE#)-1) into max_cf_scn
         from \$RMAN_SCHEMA.RC_DATABASE db,
              \$RMAN_SCHEMA.RC_DATABASE_INCARNATION carn,
              \$RMAN_SCHEMA.RC_BACKUP_CONTROLFILE log
         where
            db.dbid=$DBID and
            db.DB_KEY=carn.DB_KEY and
            carn.CURRENT_INCARNATION='YES' and
            carn.DBINC_KEY=log.DBINC_KEY and
            carn.DB_KEY=log.DB_KEY and  log.CHECKPOINT_CHANGE#< max_redo_scn
         order by CHECKPOINT_CHANGE#;
         DBMS_OUTPUT.Put_Line(chr(10)||chr(10));
         DBMS_OUTPUT.Put_Line('ret_val='||ret_val);
         DBMS_OUTPUT.Put_Line('max_cf_scn='||max_cf_scn);
         DBMS_OUTPUT.Put_Line('max_redo_scn='||max_redo_scn);
         END;
/
         "
   echo "\$MAX_SCN_QUERY" | grep -v connect
   echo "\$MAX_SCN_QUERY" | sqlplus /nolog > $LOG2
EOF2

   chmod 700 $RAO2
   chown oracle:dba $RAO2
   ksh $RAO2
   cat $LOG2
   MAX_SCN_0=$(grep "max_redo_scn=[0-9]" $LOG2 )
   export MAX_SCN=${MAX_SCN_0#max_redo_scn=}
   echo "MAX_REDO_SCN=$MAX_SCN"

   MAX_CF_0=$(grep "max_cf_scn=[0-9]" $LOG2 )
   export MAX_CF=${MAX_CF_0#max_cf_scn=}
   echo "MAX_CF_SCN that is less than max redo=$MAX_CF"
}

while getopts ho:i: option
do
   case "$option"
   in
      h) usage_exit;;
      i) export DBID="$OPTARG";;
      o) export ORACLE_SID="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$ORACLE_SID" ]]; then
   . /home/oracle/system/rman/choose_a_sid.sh
fi
if [[ -z "$DBID" ]]; then
   usage_exit
fi

alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile #BASH

func_find_last_scn
#echo "outside the function  MAX_SCN=$MAX_SCN"
exit 
