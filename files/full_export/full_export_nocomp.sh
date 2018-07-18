#!/bin/bash
#---------------------------------------------------------------------------
# FILE: full_export.sh
#
# Date:  04/14/2015 
# Updated for NITC Redhat:  Jane Reyling/Oracle Engineering
#
# Description: Script to run a full database export to the datapump dir /fslink/orapriv/ora_exports.
#
# It is recommended that this script be executed on a daily basis (Monday
# to Friday). To automate the process through cron, execute the "crontab -e"
# command from the AIX prompt and add the following entry:
#
# 30 22 * * 1-5 /home/oracle/system/full_export.sh -o ALL 2>&1
#
# (Remove the pound sign ("#") from the entry, otherwise script will not
#  run automatically.)
#
#
# To execute the script manually, the following are the different options:
#   full_export.sh             ( performs export , prompts for instance name )
#   full_export.sh -o db777a   ( exports the current instance for db777a database )
#   full_export.sh -o all      ( exports all databases )
#   full_export.sh -o ALL      ( exports all databases )
#
#
#---------------------------------------------------------------------------
#******************************************************************************
#---------------------------------------------------------------------------
#----------------------------------------------------------------------------

function func_usage
{
   echo "Usage for the full_export.sh script"
   echo "full_export_nocomp.sh [-o <instance_name> -o all ] [ -o <instance_name> ]"
   echo "full_export_nocomp.sh -o db7777a<n>	# exports database instance db777a1 or db777a2, etc."
   echo "full_export_nocomp.sh             	# performs export , prompts for instance name"
   echo "full_export_nocomp.sh -o all    	# exports all databases"
   echo "full_export_nocomp.sh -o ALL    	# exports all databases"
   exit 1
}

. /fslink/sysinfra/oracle/common/db/oraenv.usfs
export expdir=/home/oracle/system/oraexport

main_program ()
{
echo " Exporting  Database $DBNAME *************************"

echo
sdate=$(date)
echo SCRIPT started at $sdate
ext="_`date +%w_`$DBNAME"
expfname=orclfulbkup$ext.exp
exppath=/fslink/orapriv/ora_exports
rm -f $exppath/${expfname}
rm -f $exppath/orclfulbkup$ext.exp.log

#Perform the export.
echo "/ as sysdba" | $ORACLE_HOME/bin/expdp dumpfile=${expfname} logfile=orclfulbkup$ext.exp.log full=yes 
#echo $ORACLE_HOME/bin
#echo "Main Program:  $ORACLE_SID"
edate=$(date)
echo "#############################"
echo SCRIPT ended at $edate
echo
echo " Export Ended for Database $DBNAME"
echo "======================================================================"
}

convert_sid_to_dbname ()
{
export DBNAME=${ORACLE_SID}

##### Check if the database instance is up.
RUN_FLAG=$(ps -ef | grep [p]mon_$ORACLE_SID$ | wc -l)
  if [ $RUN_FLAG != 0 ]
       then
       echo " The database instance $ORACLE_SID is running."
  else
       echo "The database ${ORACLE_SID} is not running or is not a valid database instance."
       exit 1
  fi 
}

case $# in
  0)
        /usr/bin/clear
        # echo "                                    " # 1/2
        echo "======================================================================"
        echo "                         DATABASE FULL EXPORT"
        echo
        echo

        # Prompt the user for the database name (aka sid) they want.

        typeset -l y_or_n  # Make variable always lowercase
           sid_list=$(${expdir}/get_sid.ksh)
           echo
           count=$(echo $sid_list|wc -w|sed 's| *||')
           echo "********* Please Select an Oracle Database Name *********"
           echo "         (some selections may not be a valid sid)"
           echo
           echo
           echo "List of Databases:"
           PS3="Please enter a number: "
           # Using "set --" in combination with "$@" will not interpret
           # asterisk.  (Otherwise asterisk decodes to every file in the
           # current directory.
           set ${sid_list}
           select ORACLE_SID in $@
           do
              if [ ${#ORACLE_SID} -eq 0 ]; then
                 echo "Please enter a number from 1 to $count.\n";
              else
                 break;
              fi
           done
	   export ORACLE_SID=$(echo "$ORACLE_SID"|sed "s|'||g")

        if [[ -z "$ORACLE_SID" ]]; then
           echo "ERROR: ORACLE_SID not set"
           exit 1
        fi

        convert_sid_to_dbname ${ORACLE_SID}
        main_program ${ORACLE_SID}
        echo
          ;;

   2)
     if [[ $1 = "-o" ]]; then
         SECOND_ARG=$2
         if [[ $SECOND_ARG =~ (all|ALL) ]];then
            # Get the lists of sids using get_sid.ksh script 
               sids=$(${expdir}/get_sid.ksh)
#echo "get_sid $sids"
                    for i in $sids 
                      do
                        export ORACLE_SID=${i}
                        convert_sid_to_dbname ${ORACLE_SID}
                        main_program ${ORACLE_SID}
                      done
             else
#echo "else ORACLE_SID=$ORACLE_SID"
                   ORACLE_SID=${SECOND_ARG}
                   convert_sid_to_dbname ${ORACLE_SID}
                   main_program ${ORACLE_SID}
          fi
       else
          func_usage
     fi
     ;;
   *)
     func_usage
     ;;
esac

