#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/extrapolate_dbid.sh, ora, build6_1, build6_1a,1.3:10/13/11:15:50:51
#  VERSION:  1.3
#  DATE:  10/13/11:15:50:51
#
#  (C) COPYRIGHT International Business Machines Corp. 2002, 2011
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Shows the DBIDs in the logs in order of oldest to newest.


#############################################################################
print "Step 32.1.1 - Verify user ID is oracle"
#############################################################################
export ID=$(id -u -n)
if [[ $ID != oracle ]]; then
   echo "Please log in as user oracle"
   exit 1
fi

export LOG_DIR=/opt/oracle/diag/bkp/rman/log

program="extrapolate_dbid.sh"

function usage_exit
{
   echo "Usage:    extrapolate_dbid.sh {-o[ORACLE_SID]}"
   echo "          -o, Values for ORACLE_SID i.e. [a|ddb|rdb|tdb|admin]"
   exit 1
}

unset DB_ID
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

ls $LOG_DIR/rman_backup.* | sed 's|.*rman_backup\.||;s|.*\.\([^\.]*\)\..*\..*\..*|\1|' | sort -u  | grep -v ^all$ > /tmp/extrapolate_dbid.tmp
if ! grep ^$ORACLE_SID$ /tmp/extrapolate_dbid.tmp; then
   echo "ERROR: ORACLE_SID of '$ORACLE_SID' not found in logs"
   echo "       valid SID log files are: $(echo $(cat /tmp/extrapolate_dbid.tmp))"
   exit 1
fi

echo "       This grep command shows DBID's for database $ORACLE_SID with the latest"
echo "       being at the bottom.:"
echo "          grep DBID= \$(ls -tr $LOG_DIR/rman_backup.*.$ORACLE_SID.*)"
echo "       The last number is the latest DBID for database '$ORACLE_SID':"
grep DBID= $(ls -tr $LOG_DIR/rman_backup.*.$ORACLE_SID.*)|\
   sed 's|.*DBID=||;s|).*||;s|^|          |'|sort -u
candidate=$(grep DBID= $(ls -tr $LOG_DIR/rman_backup.*.$ORACLE_SID.*)|\
   sed 's|.*DBID=||;s|).*||;'|sort -u|tail -1)
echo "       The dbid is most likely $candidate for database '$ORACLE_SID'"
echo "       Execute the above shown 'grep' command if there is any doubt."
