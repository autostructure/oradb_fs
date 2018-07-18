#!/bin/ksh
#---------------------------------------------------------------------------
# FILE:  ckalertlog.sh 
#
# Date:  07/29/2014
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script to check for ORA-600 errors in the alert.log.
# 	       If an error is found an email is sent to the email address listed in the emailto file.  
#
# This script is called from the database maintenance scripts.
# For example:  ckalertlog.sh $ORACLE_SID
#
#----------------------------------------------------------------------------

export scripts=/home/oracle/dbcheck/scripts

MAILTO=$(tail -1 /home/oracle/dbcheck/scripts/emailto)

export ORACLE_SID=${1}
export DATABASE_NAME=${1}
export ORACLE_BASE=/opt/oracle
export alertdir=$ORACLE_BASE/diag/rdbms

alertlog=$(ls ${alertdir}/${DATABASE_NAME}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log)

  if [[ -f ${alertlog} ]]; then
      errck=$(tail -15000 ${alertlog} |grep ORA-600|wc -l)
	if [ $errck == 0 ]; then
       	    echo "No errors found in the alert log file:  "${alertlog}
	else
            # Send email to the EDBAs if one is specified in the emailto file.
            ckemailto=$(grep noone ${scripts}/emailto|wc -l)
            if [[ ${ckemailto} = 1 ]]; then
                echo 'The emailto file has no valid email recipient setup.'
                echo 'If you would like to receive this alert in your Outlook inbox, enter a valid email address in the emailto file.';
            else
	        MAILTO=$(tail -1 /home/oracle/dbcheck/scripts/emailto)
       	        echo "ORA-600 errors found in the last 15000 lines of the alertlog file ${alertlog}."
	        echo "Sending email to" $MAILTO
	        errlog=/tmp/alert_errors_${ORACLE_SID}.log
	        tail -15000 ${alertlog} |grep 'ORA-600'  > ${errlog}
	        SUBJECT="Errors found in alert logfile for ${ORACLE_SID} on $(hostname)."
                mail -s "$SUBJECT" $MAILTO < $errlog
                rm -f /tmp/alert_errors_${ORACLE_SID}.log
 	    fi
          fi
  else
    echo "No alert log file found under ${alertdir}."
  fi

