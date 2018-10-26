#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/voting_disk.sh, ora, build6_1, build6_1a,1.3:10/3/11:10:35:49
#  VERSION:  1.3
#  DATE:  10/3/11:10:35:49
#
#  (C) COPYRIGHT International Business Machines Corp. 2003
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Backup voting disk devices.
# 
# Note: The rman_delete.sh script purges the old voting disk backups!


alias shopt=': '; UID=$(id | sed 's|(.*||;s|.*=||'); . /home/oracle/.bash_profile #BASH

. /home/grid/.bash_profile

export LOG_DIR=/opt/oracle/diag/bkp/rman/vote_disk

CMDNAME="$(basename $0)"
PERCENT="%"             # This is a hack to prevent CMVC from gobbling things.
STAMP=$(date +${PERCENT}Y${PERCENT}m${PERCENT}d.${PERCENT}H${PERCENT}M${PERCENT}S)
export LOG_FILE=${LOG_DIR}/${CMDNAME}.${STAMP}

PERCENT="%"             # This is a hack to prevent CMVC from gobbling things.
STAMP=$(date +${PERCENT}Y${PERCENT}m${PERCENT}d.${PERCENT}H${PERCENT}M${PERCENT}S)
export LOG_FILE=${LOG_DIR}/${CMDNAME}.${STAMP}
export LOGPRUNE=7    # In days

export ID=$(id -u -n)
if [[ $ID != "grid" ]]; then
   echo "ERROR: must run as user grid"
   exit 1
fi
# prune logs older than LOGPRUNE in days
find $LOG_DIR -name "${CMDNAME}.*" -mtime +${LOGPRUNE} -exec rm {} \;

if [[ ! -d /opt/oracle/diag/bkp/rman/vote_disk ]]; then
   echo "ERROR: missing /opt/oracle/diag/bkp/rman"
   exit 1
fi
for dev in $(crsctl query css votedisk | sed '/[0-9]\. /!d;s|.*(/|/|; s|).*||')
   do
   echo dev=$dev

   dev2=$(echo $dev|sed 's|/|-|g')
   file=/opt/oracle/diag/bkp/rman/vote_disk/vote_disk__$dev2.$(date "+%Y-%m-%d:%H:%M:%S").dd.gz
   echo file=$file
   dd if=$dev bs=1048576 | gzip > $file
   echo rc=$?
done 2>&1 | tee -a $LOG_FILE
