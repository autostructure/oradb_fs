#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_cron_resync.sh, ora, build6_1, build6_1a,1.4:10/13/11:15:50:56
#  VERSION:  1.5
#  DATE:  04/21/13
#
#  (C) COPYRIGHT International Business Machines Corp. 2002-2007, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Using RMAN, the database used the backup server to do a backup without connecting
#    to the remote catalog.


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
if [[ $SIDS == all ]] || [[ $SIDS == ALL ]]; then
   # Set the SIDS envar
   . /home/oracle/system/rman/usfs_local_sids
   echo SIDS=$SIDS
fi


export TMP_0=/home/oracle/system/rman/temp
mkdir $TMP_0 2> /dev/null
chown oracle:dba $TMP_0
chmod 700 $TMP_0
touch $TMP_0

export LOGPRUNE=2    # In days
# prune logs older than LOGPRUNE in days
find $TMP_0 -mtime +${LOGPRUNE} -exec rm -rf {} \; 2> /dev/null

export TMP=$TMP_0/$$
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP

export LOG_DIR=/opt/oracle/diag/bkp/rman/log
mkdir $LOG_DIR 2> /dev/null
chown oracle:dba $LOG_DIR
chmod 700 $LOG_DIR



function resync_sid {
   program="rman_cron_resync.sh"
   export RAO1=$TMP/$program.1.$ORACLE_SID.sh
   export RAO1_1=$TMP/$program.1.rmn
   export LOG1=$LOG_DIR/$program.1.$ORACLE_SID.$$.log
   
   #if [[ -z "$RMAN_CATALOG" ]]; then
   #   echo "FYI: catalog not configured, exiting."
   #   exit 1
   #fi
   
   umask 077
   cat > $RAO1 <<EOF2
     echo \#####################################################################
     export ORACLE_SID=$ORACLE_SID
     echo "ORACLE_SID=\$ORACLE_SID"
     echo "RMAN_CATALOG=\$RMAN_CATALOG"
     echo "RMAN_CATALOG_POOL=\$RMAN_CATALOG_POOL"
     . /home/oracle/system/oraenv.usfs
     PATH=\$ORACLE_HOME/bin:\$PATH
     export TNS_ADMIN=/home/oracle/system/rman/admin.wallet
     for CAT in \$(
               echo \$RMAN_CATALOG \$RMAN_CATALOG_POOL|tr ': ' '\n\n'|sort -u)
     do
        echo "Trying repository '\$CAT'"
        ( rman target / catalog /@\$CAT cmdfile=$RAO1_1 )
        echo \------------------------------------------------------------------
     done
EOF2
   echo "resync catalog;" > $RAO1_1
   
   chmod 700 $RAO1 $RAO1_1
   chown oracle.dba $RAO1 $RAO1_1
   ksh $RAO1 | tee $LOG1
   
   #PRE-MULITPLE REPOS if grep -q "RMAN-08004: full resync complete" $LOG1; then
   if ! grep -q "ERROR MESSAGE STACK FOLLOWS" $LOG1; then
      echo "FYI: '$ORACLE_SID' successfully resynchronized."
      return 0
   else
      echo "ERROR: could not resync '$ORACLE_SID' with a remote catalog."
      return 1
   fi
}

export rc=0
export hit_one=0;
# Backup All
for ORACLE_SID in $SIDS; do
   (resync_sid)
   imm_rc=$?
   (( rc = rc + imm_rc ))
done

if ((rc==0)); then
   echo "SCRIPT SUCCESSFULLY COMPLETED."
   exit 0
else
   echo "ERROR: one or more resynchronizations failed."
   exit $rc
fi
exit 1

