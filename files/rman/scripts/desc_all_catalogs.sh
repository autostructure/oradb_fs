#!/usr/bin/env ksh 
# #  @(#)fs615/db/ora/rman/linux/rh/desc_all_catalogs.sh, ora, build6_1, build6_1a,1.5:10/13/11:15:50:50 #  VERSION:  1.6
#  DATE:  04/24/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2004, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
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
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $TMP"; exit 1; fi


export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir -p $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $LOG_DIR"; exit 1; fi

export RAO1=$TMP/$this.1.sh
export RAO1_1=$TMP/$this.1_1.sh
export LOG1=$LOG_DIR/$this.1.$$.log
export LOG2=$LOG_DIR/$this.2.$$.log

function usage_exit
{
   echo "Usage:  this"
   exit 1
}

unset DB_ID
while getopts h option
do
   case "$option"
   in
      h) usage_exit;;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done


alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile

cat > $RAO1 <<EOF2
#set -x
   export LOG1=$LOG1
   export LOG2=$LOG2
EOF2
 
cat >> $RAO1 <<\EOF2
   alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile
   echo "RMAN_SCHEMA=$RMAN_SCHEMA"
   echo "RMAN_CATALOG=$RMAN_CATALOG"
   echo "RMAN_CATALOG_POOL=$RMAN_CATALOG_POOL"
 
   export NLS_LANG=american
   export NLS_DATE_FORMAT='YYYY-MM-DD:HH24:MI:SS'
 
   
   good_date=false
   export max_CAT=""
   export max_date="0000-00-00:00:00:00"
   export FS615_ORATAB=/etc/oratab
   [[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

   echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
   for CAT in $(
               echo $RMAN_CATALOG $RMAN_CATALOG_POOL|tr ': ' '\n\n'|sort -ru)
   do
      echo "Trying repository '$CAT'"

      # Pick an arbirary ORACLE_SID which can be used to get an arbitrary ORACLE_HOME
      export ORACLE_SID=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+:[nN]|\+ASM|MGMTDB|/agent|\*" | cut -f1 -d: | head -1);

      # Set ORACLE_HOME, and on RDBMS servers, LD_LIBRARY_PATH
      . /home/oracle/system/oraenv.usfs
      PATH=$ORACLE_HOME/bin:$PATH
      export TNS_ADMIN=/home/oracle/system/rman/admin.wallet


      echo "
         connect /@$CAT
         select 'Trying repository "$CAT"' from dual;
         desc $RMAN_SCHEMA.rc_backup_set;
         " | sqlplus -s /nolog > $LOG1.$CAT
      if egrep "^SP[0-9]-|^ORA-[0-9][0-9][0-9][0-9][0-9]" $LOG1.$CAT || ! which sqlplus; then
         echo "WARNING: $RMAN_SCHEMA couldn't describe" \
              "$RMAN_SCHEMA.rc_backup_set@$CAT"
      else
         echo "FYI: $RMAN_SCHEMA described $RMAN_SCHEMA.rc_backup_set@$CAT" \
              "successfully" 
      fi
      echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
   done | tee $LOG2
EOF2

chmod 700 $RAO1
chown oracle:dba $RAO1
ksh $RAO1

if grep -q ^WARNING: $LOG2; then
   echo "ERROR: couldn't describe rc_backup_set in all catalogs"
   exit 1
fi
num_cats=$(
    echo "echo \$RMAN_CATALOG \$RMAN_CATALOG_POOL" | ksh | tr ' :' '\n' | sort -u | wc -l)

successes=$(grep successfully $LOG2 | wc -l)
echo num_cats=$num_cats
echo successes=$successes
if ((num_cats!=successes)); then
   echo "ERROR: Not enough catalogs described successfully."
   exit 1
fi
echo "SCRIPT SUCCESSFULLY COMPLETED$warnings"
exit 0
