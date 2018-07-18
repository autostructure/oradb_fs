#!/bin/ksh
# Works for Redhati 7
#---------------------------------------------------------------------------
# FILE: rotate_alertlogs.sh
#
# Date:  05/08/2017
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script move alert logs to /opt/oracle/diag/bkp/alertlogs,
#	       then creates a new alert log, and then tars of the old alert logs.
#	       The old alert logs are kept for 90 days.  
#
# This script is setup as a cron job to run on the first of every month. 
#
#---------------------------------------------------------------------------
#******************************************************************************
#---------------------------------------------------------------------------
export scripts=/home/oracle/dbcheck/scripts
export logs=/home/oracle/dbcheck/logs
export tarpath=/opt/oracle/diag/bkp/alertlogs
export alertdir=/opt/oracle/diag/rdbms
export edate=$(date)
ext="_$(date +%m-%d-%y)_$ORACLE_SID"

    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Rotate alert log on the first of each month for ${db}.
    echo '##############################################################'
    echo "Move and recreate the alert log."
    dbs=$(${scripts}/get_sid.ksh)

    for s in $dbs;  do
        db=${s}
        ORACLE_SID=${s}
        siddir=${alertdir}/${db}/${ORACLE_SID}
#echo ${siddir}

        mv ${alertdir}/${db}/${db}/trace/alert*log ${tarpath}
        touch ${alertdir}/${db}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
        chown oracle:oinstall ${alertdir}/${db}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
        chmod 640 ${alertdir}/${db}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log
    done

############ FINAL CLEANUP ##############

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Tar up all alert log files for all databases under /ora_exports/alertlogs.
echo '##############################################################'
tarext="_$(date +%Y%m%d%H%M_)$(hostname)"

echo "Tar up all the alert logs on this server to ${tarpath}/alert${tarext}.tar"

cd ${tarpath}
#echo ${tarpath}
tar -cvf ${tarpath}/alert${tarext}.tar ./alert*log
rm -f ${tarpath}/alert*log

echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Remove all alert log tar files over 120 days old.
echo '##############################################################'
find /${tarpath} -name "alert*.tar" -mtime +120|xargs rm -rf

########################################################
# Rename alert.log file and delete old log files
########################################################
    mv $logs/alert.log $logs/alert.log.$(date +%Y%m%d%H%M)_$(hostname)
    chmod 774 $logs/alert.log*
    find $logs -name "alert.log.*" -mtime +90 -exec rm {} \;
