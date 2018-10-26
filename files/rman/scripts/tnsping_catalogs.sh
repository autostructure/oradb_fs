#  %Z%%W%,%I%:%G%:%U%    # File: tnsping_catalogs.sh
#  VERSION:  %I%   #4/30/2012   v1.1
#  DATE:  %G%:%U%


export LOG_DIR=/opt/oracle/diag/bkp/rman/log/
function error_exit {
   echo "  ERROR $2" | tee -a $LOG
   exit $1
}

function tnsping_catalogs {
   CATS=$(echo $RMAN_CATALOG $RMAN_CATALOG_POOL|tr ': ' '\n\n'|sort -u)
   echo "CATS=$CATS"
   for CAT in $CATS; do
      echo "Doing: tnsping $CAT" >> $LOG_DIR/tnsping_catalogs.sh.$CAT.log
      tnsping $CAT >> $LOG_DIR/tnsping_catalogs.sh.$CAT.log
      # Look for output like "OK (80 msec)"
      tail -1 $LOG_DIR/tnsping_catalogs.sh.$CAT.log | grep '^OK ([0-9][0-9]* [^0-9]*)' || error_exit 1 "failed to tsnping $CAT"
      echo "Pass catalog '$CAT'"
   done
}
tnsping_catalogs
