#!/bin/bash
#
# cleanup_audit.sh
#
# Jane Reyling
# version 2.0
# March 24, 2016
# Cleans out audit log files for single instance databases.
#
########################################

# Set variables
#NOW=$(date +"%m%d%y%H%M%S") #capture current time and date
name="CLEANUP_:" #label for activity related to cleanup
. /fslink/sysinfra/oracle/common/db/oraenv.usfs

export scripts=/home/oracle/dbcheck/scripts
export ORACLE_BASE=/opt/oracle
CLN_AUD ()
{
name="CLEANUP_audit files:"
    export auditdest=${ORACLE_BASE}/admin
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Delete .aud files over 5 days ${auditdest}.
    echo '##############################################################'
    sids=$(${scripts}/get_sid.ksh)
        for s in $sids; do
        db=${s}
        echo $name  ${auditdest}/${db}/adump
        find ${auditdest}/${db}/adump -name *.aud -mtime +5|xargs rm -rf
        find ${auditdest}/${db}/adump -type  f -size +90000k|xargs rm -f
    done
}

CLN_TRC ()
{
name="CLEANUP_trace files:"
    export dir=${ORACLE_HOME::-4}
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Delete .trc files under ${dir}*/rdbms/log.
    echo '##############################################################'
    trcdir=$(ls ${dir})
    for d in ${trcdir}; do
        dbdir=${dir}${d}
        if [ -d ${dbdir}/rdbms ]; then
          find ${dbdir}/rdbms/log -name *.trc -mtime +30|xargs rm -rf
	  echo $name  ${dbdir}/rdbms/log
        else
          echo 'No files exist under '${dbdir}'.'
        fi
    done
}

CLN_ORADIAG ()
{
name="CLEANUP_oradiag directories:"
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Delete oradiag_oracle over 30 days old under ${ORACLE_BASE}
    echo '##############################################################'
    find ${ORACLE_BASE}/oradiag_oracle -type d -mtime +10 2>/dev/null|xargs rm -Rf
    echo $name  ${ORACLE_BASE}/oradiag*
    find ~/oradiag_oracle -type d -mtime +10 2>/dev/null|xargs rm -Rf
    echo $name ~/oradiag*
}

CLN_DUMPDIR ()
{
name="CLEANUP_dumpdir files:"
    export dumpdir=${ORACLE_BASE}/diag/rdbms
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Delete .trm, .trc, .xml files and cdmp dirs under ${dumpdir}
    echo '##############################################################'
    dbs=$(${scripts}/get_sid.ksh)

    for s in $dbs;  do
        db=${s}
        siddir=${dumpdir}/${db}
#echo ${siddir}
        sids=$(ls ${siddir}|grep ${db})
          for d in ${sids}; do
            ORACLE_SID=${d}
            echo $name $siddir/${ORACLE_SID}/trace
            find ${siddir}/${ORACLE_SID}/trace -name *.tr* -mtime +15|xargs rm -f
            echo $name $siddir/${ORACLE_SID}/cdump/
            find ${siddir}/${ORACLE_SID}/cdump -name core* -mtime +15|xargs rm -rf
            echo $name ${siddir}/${ORACLE_SID}/incident/
            find ${siddir}/${ORACLE_SID}/incident -name incdir* -mtime +30|xargs rm -rf
            echo $name ${siddir}/${ORACLE_SID}/alert/
            find ${siddir}/${ORACLE_SID}/alert -name log_*.xml -mtime +30|xargs rm -f
          done
    done
}

CLN_LSNR ()
{
name="CLEANUP_tnslsnr files:"
    export lsnrxml=${ORACLE_BASE}/diag/tnslsnr/$(hostname)/listener
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Delete listener .xml files under ${lsnrxml} over 30 days old.
    echo '##############################################################'
    echo $name ${lsnrxml}/alert/
    find ${lsnrxml}/alert -name log_*.xml -mtime +30|xargs rm -f
}

echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo +++++++++++++++++++++++ Starting cleanup.sh +++++++++++++++++++++++++
CLN_AUD
CLN_TRC
CLN_ORADIAG
CLN_DUMPDIR
CLN_LSNR

echo ''
echo +++++++++++++++++++++++ End cleanup.sh +++++++++++++++++++++++++++++++

