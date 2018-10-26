#!/usr/bin/env ksh

mkdir /var/tmp/rman 2> /dev/null
export LOG=/var/tmp/rman/archivelog_mode.sh.log
while getopts hbyf option; do
   case "$option"
   in
      h) usage_exit;;
      b) export BACKOUT_SCRIPT="TRUE";;
      y) export TRACK_CHANGES="TRUE";;
      f) export AUTO_SHUTDOWN="-f";;  # "-f" instead of "YES" is slightly more effecitent for calling scrits
     \?)
         eval print -- "ERROR:" \$$(( OPTIND - 1 )) "option is not a supported switch."
         usage_exit;;
   esac
done

{
   function error_exit {
      echo "ERROR $2"
      exit $1
   }
   function query_archivelog_mode {
      echo "== Updating Oracle control file records"
   
      cat >/var/tmp/rman/tmp.sql  <<\EOF
         set pages 50
         select log_mode from v$database
   
         l
         r
         exit
EOF
      . /home/oracle/system/rman/usfs_local_sids
      echo SIDS=$SIDS
   
      for S in $SIDS; do
         echo ".. Querying Oracle instance $S"
         (  export ORACLE_SID=$S;
            . /home/oracle/system/oraenv.usfs;
            PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/rman/tmp.sql 2>&1 ) \
            | tee -a $LOG | tee /var/tmp/rman/$S.log | grep ARCHIVELOG # -- -[0-9]
         [[ $? != 0 ]] && error_exit 14 "Unable to query v$database.LOG_MOE for instance $S"
   
         XX=$(grep "LOG$" /var/tmp/rman/$S.log)
         echo XX=$XX
         # [[ $XX != 365 ]] && error_exit 15 "Unable to set Oracle control file record for instance $S"
      done
   }
   function set_archivelog_mode {
      #Input:  $1 = { "ARCHIVELOG", "NOARCHIVELOG")  #Case sensitive
      echo "== Setting archivelog mode"
      LOG_MODE=$1
      OPPOSITE_MODE="NOARCHIVELOG"
      if [[ $LOG_MODE == "NOARCHIVELOG" ]]; then 
         OPPOSITE_MODE="ARCHIVELOG"
      fi
      echo LOG_MODE=$LOG_MODE: >> $LOG
      echo OPPOSITE_MODE=$OPPOSITE_MODE: >> $LOG
   
      cat >/var/tmp/rman/tmp.sql  <<\EOF
         set pages 50
         select log_mode from v$database
   
         l
         r
         exit
EOF
      . /home/oracle/system/rman/usfs_local_sids
      echo SIDS=$SIDS
   
      for S in $SIDS; do
         echo ".. Querying Oracle instance $S"
         export ORACLE_SID=$S;
         . /home/oracle/system/oraenv.usfs; #Output: INSTNBR
         DB_NAME=${ORACLE_SID%%$INSTNBR}
         echo ".. starting database $DB_NAME"
         if [[ $ORACLE_SID == $DB_NAME ]]; then
            echo "startup" | sqlplus / as sysdba
         else
set -x
            srvctl start database -d $DB_NAME >> $LOG 2>&1
echo TODO exit 88; exit 88
         fi
         (PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/rman/tmp.sql 2>&1) \
            | tee -a $LOG | tee /var/tmp/rman/$S.log | grep ARCHIVELOG # -- -[0-9]
         [[ $? != 0 ]] && error_exit 14 "Unable to query sys.v$database.log_mode from instance $S"
         XX=$(grep "LOG$" /var/tmp/rman/$S.log)
         echo XX=$XX >> $LOG
         if [[ $XX == $OPPOSITE_MODE ]]; then
            if [[ -n $TRACK_CHANGES ]]; then 
               if [[ $LOG_MODE == "ARCHIVELOG" ]]; then 
                  echo ".. recording backout information"
                  echo $S > /home/oracle/system/rman/backout_archivedlog_mode.$S.txt; 
               else
                  if [[ -f /home/oracle/system/rman/backout_archivedlog_mode.$S.txt ]]; then
                     echo ".. found backout record, so backing instance '$S'"
                  else
                     echo ".. missing backout record for instance '$S', so skipping.."
                     continue
                  fi
               fi
            fi
            if [[ $AUTO_SHUTDOWN != "-f" ]]; then
               echo ".. shutdown of database $DB_NAME is required"
               echo -e "Press enter to continue with shutdown: \c"; read q
            else
               echo ".. automatically shutting down without prompting"
            fi
            if [[ $ORACLE_SID == $DB_NAME ]]; then
               echo "shutdown immediate" | sqlplus / as sysdba
            else
               srvctl stop database -d $DB_NAME -o immediate >> $LOG 2>&1
            fi
            cat >/var/tmp/rman/tmp_2.sql  <<EOF
               set pages 50
               startup mount
               alter database $LOG_MODE
         
               l
               r
               alter database open
   
               l
               r
               select 'log_mode='||log_mode from v\$database
   
               l
               r
               exit
EOF
            (PATH=$ORACLE_HOME/bin:$PATH; sqlplus / AS SYSDBA @/var/tmp/rman/tmp_2.sql 2>&1) \
               | tee -a $LOG | tee /var/tmp/rman/$S.log | grep -- -[0-9]
            results=$(grep '^log_mode=' /var/tmp/rman/$S.log)
            echo results=$results
            [[ $results != "log_mode=$LOG_MODE" ]] && error_exit 1 "couldn't put ORACLE_SID=$ORACLE_SID in '$LOG_MODE' mode"
            echo ".. started database $DB_NAME"
            if [[ $ORACLE_SID == $DB_NAME ]]; then
               echo "startup" | sqlplus / as sysdba
            else
               srvctl start database -d $DB_NAME >> $LOG 2>&1
            fi
         else
            echo ".. database $DB_NAME is already in log_mode="$LOG_MODE", skipping..."
         fi
         # [[ $XX != 365 ]] && error_exit 15 "Unable to set Oracle control file record for instance $S"
      done
   }
   #query_archivelog_mode
   if [[ -n $BACKOUT_SCRIPT ]]; then
      echo "== Backing out ARCIVELOG"
      set_archivelog_mode NOARCHIVELOG
   else
      echo "== Setting ARCIVELOG"
      set_archivelog_mode ARCHIVELOG
   fi
   echo "SCRIPT SUCCESSFULLY COMPLETED. $(date) LOG=$LOG" 
} | tee $LOG

