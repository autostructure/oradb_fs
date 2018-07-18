#!/bin/ksh
#---------------------------------------------------------------------------
# FILE:  ckexplogs.sh 
#
# Date:  07/29/2014
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script to check for errors in the /ora_exports/orcl*.log (export logfile).
# 	       If an error is found an email is sent to the email address listed in the emailto file.  
#
# This script is called from the database maintenance scripts.
#
#----------------------------------------------------------------------------
export scripts=/home/oracle/dbcheck/scripts
MAILTO=$(tail -1 ${scripts}/emailto)
export ORACLE_SID=$1

expdir=/fslink/orapriv/ora_exports
#echo ${expdir}/orclfulbkup_*_${ORACLE_SID}*.log
explogs=$(ls ${expdir}/orclfulbkup_*_${ORACLE_SID}*.log 2>/dev/null|wc -l)

 if [[ "${explogs}" -ne 0 ]]; then
      logfiles=$(ls -rt ${expdir}/orclfulbkup_*_${ORACLE_SID}*.log | sed '$!d')
      errcount=$(egrep "ORA-|ERROR-" ${logfiles}|wc -l)
          if [ $errcount -gt 0 ]; then
              echo "Errors found in export logfile: " ${logfiles} 
              ckemailto=$(grep noone ${scripts}/emailto|wc -l)
              if [[ ${ckemailto} = 1 ]]; then
                  echo 'The emailto file has no valid email recipient setup.'
                  echo 'If you would like to receive this alert in your Outlook inbox, enter a valid email address in the emailto file.';
              else
                  echo "Sending email to" ${MAILTO}
                  sendlog=/tmp/exp_errors_${ORACLE_SID}.log
                  egrep 'ORA-|ERROR'  ${logfiles} > ${sendlog}
                  SUBJECT="Errors found in exp logfiles for "$ORACLE_SID
                  mail -s "$SUBJECT" $MAILTO < $sendlog
                  rm -f ${sendlog}
              fi
          else
              echo "No errors found in export logfile: " ${logfiles}
          fi
  else
      echo "No export logs found under ${expdir}"
  fi

