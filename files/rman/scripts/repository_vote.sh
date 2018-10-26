#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/repository_vote.sh, ora, build6_1, build6_1a,1.4:10/13/11:15:50:52
#  VERSION:  1.5
#  DATE:  04/24/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2004, 2011
#  All Rights Reserved
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Choose the best RMAN repository from the ones in oracle's
#    RMAN_CATALOG_POOL envar.
this=${0##*/}


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

export LOG1=$LOG_DIR/$this.1.$$.log
export LOG2=$LOG_DIR/$this.2.$$.log

export FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

function usage_exit
{
   echo "Usage:  repository_vote.sh {-i[DBID]}"
   echo "          Restores the last backed up controlfile to /tmp/cf.tmp"
   echo "          -i, specifies DBID of database of interest."
   exit 1
}


unset DB_ID
while getopts hi: option
do
   case "$option"
   in
      h) usage_exit;;
      i) export DBID="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done
if [[ -z "$DBID" ]]; then 
   echo "ERROR: the -i <DBID> command line option is required."
   exit 1
fi

alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile

function func_main {
   echo "RMAN_SCHEMA=$RMAN_SCHEMA"
   echo "RMAN_CATALOG=$RMAN_CATALOG"
   echo "RMAN_CATALOG_POOL=$RMAN_CATALOG_POOL"
 
   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
 
   
   good_date=false
   export max_CAT=""
   export max_date="0000-00-00:00:00:00"
   echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
   for CAT in $(
               echo $RMAN_CATALOG $RMAN_CATALOG_POOL|tr ': ' '\n\n'|sort -ru)
   do
      echo "Trying repository '$CAT'"

      # Pick an arbirary ORACLE_SID which can be used to get an arbitrary ORACLE_HOME
      export ORACLE_SID=$(/home/oracle/system/rman/usfs_local_sids | head -1)
      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=$ORACLE_HOME/bin:$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet


      echo "
         select 'Trying repository "$CAT"' from dual;
         connect /@$CAT
         desc $RMAN_SCHEMA.rc_backup_set
         select 'repos_date='||to_char(max(completion_time), 
                                       'YYYY-MM-DD:HH24:MI:SS')
            from $RMAN_SCHEMA.rc_backup_set
            where db_id=$DBID

         l
         r
         " | sqlplus -s /nolog > $LOG1.$CAT
      if grep -q "^ORA-[0-9][0-9][0-9][0-9][0-9]" $LOG1.$CAT; then
         echo -e "WARNING: $RMAN_SCHEMA couldn't select $RMAN_SCHEMA.rc_backup_set\n" \
              "      Verify database and listener are running\n" \
              "      Verify rc_grant_all.sql was executed against" \
              "$RMAN_SCHEMA@$CAT" 
      fi
      repos_date=$(grep "^repos_date=[0-9]" $LOG1.$CAT)
      repos_date=${repos_date#repos_date=}
      if [[ "$repos_date" != *-*-*:*:*:* ]]; then
         repos_date="0000-00-00:00:00:00"
      else
         good_date=true
      fi
      echo "repos_date=$repos_date"
      if [[ $repos_date > $max_date ]]; then
         max_date=$repos_date
         max_CAT=$CAT
      fi
      echo "max_date=$max_date" | tee -a $LOG1
      echo "max_CAT=$max_CAT" | tee -a $LOG1
      echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
   done | tee $LOG2
}

func_main

. $LOG1
if [[ $max_date == "0000-00-00:00:00:00" ]]; then
   echo "ERROR: no good repository found." | tee $LOG2
   exit 1
fi

exit_code=0
if grep -q ^WARNING: $LOG2; then
   warnings=", with warnings."
   exit_code=2
fi

# Modify RMAN_CATALOG in oracle's .bash_profile
max_CAT=$(grep ^max_CAT= $LOG2 | tail -1)
max_CAT=${max_CAT#max_CAT=}
if [[ -z $max_CAT ]]; then
   echo "ERROR: couldn't find dbid=$DBID in any catalog."
   echo "       Double check the password."
   exit 1
fi
file=/home/oracle/.bash_profile
file_bu=$file.$(date "+%Y-%m-%d:%H:%M:%S")
cp -p $file $file_bu
grep -v "^[^#]*export.*RMAN_CATALOG[^_].*" $file_bu > $file
echo "export RMAN_CATALOG=$max_CAT" >> $file

echo "Placed   export RMAN_CATALOG=$max_CAT    in ~oracle/.bash_profile"
echo "SCRIPT SUCCESSFULLY COMPLETED$warnings"
exit $exit_code
