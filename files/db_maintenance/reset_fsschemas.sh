#!/bin/bash
#
#	Script:  reset_fsschemas.sh
#	Purpose:  Reset FS_appname application schemas on a nightly basis.
#	Works on 11g databases and Redhat.
#
#	Author:  Jane Reyling
#	Date:  July 29, 2014 
#
###################################################
#echo $1
export scripts=/home/oracle/dbcheck/scripts
export logs=/home/oracle/dbcheck/logs
. /fslink/sysinfra/oracle/common/db/oraenv.usfs
export ORACLE_SID=$1

RUN_FLAG=$(ps -ef | grep [p]mon_$1 | wc -l)
#echo $RUN_FLAG
	if [ $RUN_FLAG != 0 ]
        then
		export ORACLE_SID=$1
         	$ORACLE_HOME/bin/sqlplus /nolog @$scripts/cr_reset_fsschemas.sql 

        else
                echo "The ${ORACLE_SID} database is not running"
        fi

