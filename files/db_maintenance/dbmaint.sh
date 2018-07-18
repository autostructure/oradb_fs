#!/bin/ksh
# @(#) RAC maintenance utility  
# Works for Redhat 
#---------------------------------------------------------------------------
# FILE: dbmaint.sh
#
# Date:  07/29/2014
# Author:  Jane Reyling/Oracle Engineering
#
# Description: Script to run db maintenance for all instances on database servers. 
#
#
# This script is called from dbmaint_start.job and should be executed on a daily basis
# (Monday through Saturday). 
#
#---------------------------------------------------------------------------
#******************************************************************************
#---------------------------------------------------------------------------

function func_usage
{
echo "func_usage" $1
   echo "dbmaint.sh -o [ all ] [ <instance_name> ]"
   echo "dbmaint.sh         	# Prompts for instance name"
   echo "dbmaint.sh -o oemor    # Performs maintenance on the database oemor"
   echo "dbmaint.sh -o all     	# Performs maintenance on all databases"
   echo "dbmaint.sh -o ALL  	# Performs maintenance on all databases"
   exit 1
}

main_program ()
{
echo " Performing maintenance on Database $DATABASE_NAME *************************"
echo "======================================================================"
echo "======================================================================"
echo

. /fslink/sysinfra/oracle/common/db/oraenv.usfs

edate=$(date)
ext="_$(date +%w)_$DATABASE_NAME"
logname=dbmaint$ext.log
logs=/home/oracle/dbcheck/logs
scripts=/home/oracle/dbcheck/scripts
sdate=$(date)
echo SCRIPT started at ${sdate}
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Begin DB Maintenance for ${DATABASE_NAME}.
    echo '##############################################################'
    echo '##############################################################'

    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Run all sql scripts for ${ORACLE_INST}.
    echo '##############################################################'
#    export ORACLE_SID=$ORACLE_INST; cd ${scripts}; ./rundbsql.sh
    ${scripts}/rundbsql.sh
    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Check FULL EXPORT logs for errors for ${ORACLE_INST}.
    echo '##############################################################'
        $scripts/ckexplogs.sh ${ORACLE_INST}
    
    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Check rman logs for errors for ${ORACLE_INST}.
    echo '##############################################################'
        $scripts/ckrmanlogs.sh ${ORACLE_INST}
 
    echo ' '
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)")  Check alert log for ORA-600 errors on ${ORACLE_INST}.
    echo '##############################################################'
        $scripts/ckalertlog.sh ${ORACLE_INST}

# Cleanup remaining files from script.
        rm -f $logs/reset_fsschema*
        rm -f $logs/find*
        rm -f $logs/chain.lst

echo ''
echo SCRIPT ended at $edate
echo
echo " Maintenance Ended for Database $DATABASE_NAME"
echo "======================================================================"
echo "======================================================================"
echo "======================================================================"    
echo
}

convert_sid_to_inst ()
{
    export ORACLE_INST=$ORACLE_SID
    export DATABASE_NAME=${s}
}

#######################################################################
# Set the PATH to let this ksh script run with the older AT&T functions
# and not as the newer POSIX type
#######################################################################
export PATH=/5bin:$PATH

#########################################################################
#######  Start of the Program
#########################################################################

sdate=$(date)
path=/home/oracle/dbcheck/logs
HOSTNAME=$(hostname)

#Check write permissions on log directory.
if [ ! -w ${path} ]
then
   echo " No Write permission on ${path} for Oracle !!"
   echo " Enable write permission "
   exit 1
fi

# Check script is being run as user oracle.
ID=$(id -u -n)
#echo "The user ID is $ID"
if [ $ID != 'oracle' ] 
then
   echo "Please run as user oracle"
   exit 1
fi

#---------------------------------------------------------------------------
# Oracle environments 

unset WARNING_MSG
export WARNING_MSG
export SUMMARY
trap "echo \"\$SUMMARY\n\$WARNING_MSG\";exit" 0 1 2 15
USER=SYSTEM
USER=SYS
export scripts=/home/oracle/dbcheck/scripts
      if [ $1 -eq "-o" ]; then
         SECOND_ARG=$2

         if [[ $SECOND_ARG == @(all|ALL) ]];then
	     sids=$(${scripts}/get_sid.ksh)
	     for s in $sids;  do
             export ORACLE_SID=$s
             export DATABASE_NAME=${s}
             RUN_FLAG=$(ps -ef | grep [p]mon_$s$ | wc -l)
             	if [ $RUN_FLAG != 0 ]
               	then 
		  echo ""
                  export ORACLE_SID=${s} 
                  convert_sid_to_inst ${ORACLE_SID}
                  main_program ${ORACLE_INST} 
                else
                  echo "The $i database is not running"
                fi
             done
      else
        SUCCESS=0
        sids=$(${scripts}/get_sid.ksh)
        for s in $sids;  do
        export ORACLE_SID=$s
        export DATABASE_NAME=${s}
               if [ "$s" = "$SECOND_ARG" ]
               then
                  RUN_FLAG=$(ps -ef | grep [p]mon_$s$ | wc -l)
                  if [ $RUN_FLAG != 0 ]
                  then 
                     export  ORACLE_SID=$s
                     convert_sid_to_inst ${ORACLE_SID}
                     main_program ${ORACLE_SID} 
                     SUCCESS=1
                  else
                     SUCCESS=1
                  fi
               fi
        done
            if [ ${SUCCESS} -eq 0 ]
            then
               echo "$SECOND_ARG is not a valid Database"
            fi
         fi
      else
         func_usage
      fi
   
#################  UNIVERSAL CODE HERE
    export logs=/home/oracle/dbcheck/logs
    export scripts=/home/oracle/dbcheck/scripts
    export ORACLE_BASE=/opt/oracle
    export grid1=/opt/grid/12.1.0/grid_1

    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Cleanup directory structures.
    echo '##############################################################'
    ${scripts}/cleanup.sh

    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Trim the listener.log on ${HOSTNAME}.
    echo '##############################################################'
          $scripts/trim_logs.sh

    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Report of filesystem sizes on ${HOSTNAME}.
    echo '##############################################################'
	df -k 

    echo ''
    echo ''
    echo '##############################################################'
    echo $(date "+%Y:%m:%d %H:%M:%S (%a)") Report number of CPUs on ${HOSTNAME}.
    echo '##############################################################'
        dmesg | grep "Brought up"| cut -c 27-
    echo ''

#######################################################
# Send log file to EDBA if one is specified in the emailto file.
#######################################################
ckemailto=$(grep noone ${scripts}/emailto|wc -l)
if [[ ${ckemailto} = 1 ]]; then
    echo 'The emailto file has no valid email recipient setup.'
    echo 'If you would like to receive the logfile in your Outlook inbox, enter a valid email address in the emailto file.';
else
MAILTO=$(tail -1 /home/oracle/dbcheck/scripts/emailto)
echo "Sending dbmaint log to " ${MAILTO}
echo ''
HOSTNAME=$(hostname)
SUBJECT="Database maintenance log for ${HOSTNAME}"
mail -s "$SUBJECT" $MAILTO < $logs/dbmaint.log
fi

########################################################
# Rename dbmaint.log file and delete old log files
########################################################
    mv $logs/dbmaint.log $logs/dbmaint.log.$(date +%Y%m%d%H%M)_${HOSTNAME}_${2}
    chmod 774 $logs/dbmaint.log*
    find $logs -name "dbmaint.log.*" -mtime +30 -exec rm {} \;
    
