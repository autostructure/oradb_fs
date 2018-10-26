#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/reregister_dbs.sh, ora, build6_1, build6_1a,1.2:10/13/11:15:50:53
#  VERSION:  1.3
#  DATE:  04/21/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Using RMAN, register databases in all the remote catalogs.
export this=${0##*/}


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
   echo "Usage:  rman_cron_resync.sh {-o[list of ORACLE_SID]} "
   echo "        -o, Values for ORACLE_SID i.e. -oa, -oddb, -o\"admin a tdb\", -oall"
   exit 1
}

unset bu_lev
while getopts ho: option
do
   case "$option"
   in
      h) usage_exit;;
      o) export SIDS="$OPTARG";;
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported s
witch."
         usage_exit;;
   esac
done
if [[ -z "$SIDS" ]]; then
   SIDS=all
fi
if [[ $SIDS == @(all|ALL) ]]; then
   . /home/oracle/system/rman/usfs_local_sids
   echo SIDS=$SIDS
fi

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir -p $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR

function func_register_db {
   export RAO1_1=$LOG_DIR/$this.1.rmn
   export LOG1_1=$LOG_DIR/$this.1_1.$ORACLE_SID.$$.log
   export LOG1_2=$LOG_DIR/$this.1_2.$ORACLE_SID.$$.log

   #if [[ -z "$RMAN_CATALOG" ]]; then
   #   echo "FYI: catalog not configured, exiting."
   #   exit 1
   #fi
   
   echo "register database;" > $RAO1_1
   chmod 700 $RAO1_1
   chown oracle:dba $RAO1_1

   (
     echo #####################################################################
     export ORACLE_SID=$ORACLE_SID
     echo "ORACLE_SID=$ORACLE_SID"
     echo "RMAN_CATALOG=$RMAN_CATALOG"
     echo "RMAN_CATALOG_POOL=$RMAN_CATALOG_POOL"
     # Set ORACLE_HOME, PATH, TNS_ADMIN
     . /home/oracle/system/oraenv.usfs
     PATH=$ORACLE_HOME/bin:$PATH
     export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
   
     rc1=0
     for CAT in $(
               echo $RMAN_CATALOG $RMAN_CATALOG_POOL|tr ': ' '\n\n'|sort -u)
     do
        echo "Trying repository '$CAT'"
        echo "startup" | sqlplus "/ as sysdba" | tee $LOG1_1
        rman target / catalog /@$CAT cmdfile=$RAO1_1 | \
           tee -a $LOG1_1
        if grep -q "ERROR MESSAGE STACK FOLLOWS" $LOG1_1; then
           if ! grep -q \
          "RMAN-20002: target database already registered in recovery catalog" \
              $LOG1_1
                then
              (( rc1 = rc1 + 1 ))
           fi
        fi
        echo \------------------------------------------------------------------
     done
     if ((rc1!=0)); then
        # TRICKY CODE!!!
        # The exact spelling of this error message is a semaphore for the 
        # caller.  DON'T change this text without changing it below too!!!!
        echo "ERROR: one (or more) registations failed." 
     fi
   ) | tee $LOG1_2
   
   if ! grep -q "ERROR: one (or more) registations failed." $LOG1_2; then
      echo "FYI: '$ORACLE_SID' successfully resynchronized."
      return 0
   else
      echo "ERROR: could not registerd '$ORACLE_SID' with a remote catalog."
      return 1
   fi
}

export rc=0
export hit_one=0;
# Backup All
for ORACLE_SID in $SIDS; do
   (func_register_db)
   imm_rc=$?
   (( rc = rc + imm_rc ))
   echo "rc=$rc"
done

if [[ $rc == 0 ]]; then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   exit 0
else
   echo "ERROR: one or more reregistering failed."
   exit $rc
fi
exit 1

