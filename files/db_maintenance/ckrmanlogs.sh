#!/bin/bash
#---------------------------------------------------------------------------
# FILE: ckrmanlogs.sh
# Updated to work on Solaris
# Date:  07/29/2014
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script to check for errors in the /opt/oracle/diag/bkp/rman/log/*back*.log (rman backup logfiles).
#              If an error is found an email is sent to the email address listed in the emailto file.
#
# This script is called from the database maintenance scripts.
#
#----------------------------------------------------------------------------

ORACLE_SID=$1
MAILTO=$(tail -1 /home/oracle/dbcheck/scripts/emailto)
rmanlogdir='/opt/oracle/diag/bkp/rman/log'
rmanlogs=$(ls ${rmanlogdir}/*backup*${ORACLE_SID}*.log 2>/dev/null|wc -l)

   if [[ "${rmanlogs}" -ne 0 ]]; then
      logfiles=$(ls -rt ${rmanlogdir}/*backup*${ORACLE_SID}*.log | sed '$!d')
      errcount=$(egrep "ORA-|ERROR" ${logfiles}|wc -l)
          if [ $errcount -gt 0 ]; then
              echo "Errors found in rman logfiles under ${rmanlogdir} for ${ORACLE_SID}."
              ckemailto=$(grep noone ${scripts}/emailto|wc -l)
              if [[ ${ckemailto} = 1 ]]; then
                  echo 'The emailto file has no valid email recipient setup.'
                  echo 'If you would like to receive this alert in your Outlook inbox, enter a valid email address in the emailto file.';
              else
                  echo "Sending email to" ${MAILTO}
                  sendlog=/tmp/rman_errors_${ORACLE_SID}.log
                  egrep 'ORA-|ERROR'  ${logfiles} > ${sendlog}
                  SUBJECT="Errors found in rman logfiles for "$ORACLE_SID
                  mail -s "$SUBJECT" $MAILTO < $sendlog
                  rm -f ${sendlog}
              fi
          else
              echo 'No errors found in rman logfiles'
          fi
  else
      echo 'No rman logs found'
  fi

