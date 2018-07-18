#!/bin/ksh
#---------------------------------------------------------------------------
# FILE: dbmaint_daily.sh
#
# Date:  03/24/2016 
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script to run 11g Single Instance daily db maintenance. 
#
#----------------------------------------------------------------------------
scripts=/home/oracle/dbcheck/scripts
logs=/home/oracle/dbcheck/logs

if [[ $1 == @(all|ALL) ]];then
    sids=$(${scripts}/get_sid.ksh)

    for s in $sids;  do
      export ORACLE_SID=$s
      export DATABASE_NAME=${s}

	echo ' '
	echo '############################################################'
	echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check FULL EXPORT logs for errors for ${ORACLE_SID}.
	echo '##############################################################'
        $scripts/ckexplogs.sh ${ORACLE_SID}

      echo ' '
      echo '##############################################################'
      echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check RMAN logs for errors for ${ORACLE_SID}.
      echo '##############################################################'
      $scripts/ckrmanlogs.sh ${ORACLE_SID}

      echo ' '
      echo '##############################################################'
      echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Check alert log for ORA-600 errors on ${ORACLE_SID}.
      echo '##############################################################'
      ${scripts}/ckalertlog.sh ${ORACLE_SID}

      echo ' '
      echo '##############################################################'
      echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Reset FS_schema passwords and lock the accounts on ${ORACLE_SID}.
      echo '##############################################################'
      ${scripts}/reset_fsschemas.sh ${ORACLE_SID}

    done

else
    export ORACLE_SID=$1

        echo ' '
        echo '##############################################################'
        echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check FULL EXPORT logs for errors for ${ORACLE_SID}.
        echo '##############################################################'
        $scripts/ckexplogs.sh ${ORACLE_SID}

    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check RMAN logs for errors for ${ORACLE_SID}.
    echo '##############################################################'
    $scripts/ckrmanlogs.sh ${ORACLE_SID}

    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Check alert log for ORA-600 errors on ${ORACLE_SID}.
    echo '##############################################################'
    ${scripts}/ckalertlog.sh ${ORACLE_SID}

    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Reset FS_schema passwords and lock the accounts on ${ORACLE_SID}.
    echo '##############################################################'
     ${scripts}/reset_fsschemas.sh ${ORACLE_SID} 
    echo '##############################################################'
    echo ' '
fi

echo ' '
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Cleanup directory structures.
echo '##############################################################'
${scripts}/cleanup.sh

echo ' '
echo '##############################################################'
echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Trim the listener.log  on $(hostname).
echo '##############################################################'
      $scripts/trim_logs.sh


