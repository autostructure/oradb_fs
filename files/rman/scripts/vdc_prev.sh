#!/usr/bin/env ksh
#
# Puspose: 

{
set -x
   . /home/oracle/.bash_profile
   [[ -z $HOSTNAME ]] && HOSTNAME=$(hostname)
   for ORACLE_SID in $(/home/oracle/system/rman/usfs_local_sids); do
   set -x
      /home/oracle/system/rman/rman_cf_scn.sh -q -o $ORACLE_SID
      eval $(cat /opt/oracle/diag/bkp/rman/log/rman_cf_scn.sh.log.for_preview)
      set | grep -E 'MAX_ARC|ORACLE_SID|DBID|CKPT_NEXT_TIME|CF_CKPT_SCN'
      echo sleeping 5
      sleep 5
      /home/oracle/system/rman/rman_restore_pitr.preview.3.sh -o $ORACLE_SID -s $CF_CKPT_SCN -g # -g to ignore teh scn gap query
    
      if [[ -d /fslink/sysinfra/oracle/common/rman ]]; then 
         mkdir /fslink/sysinfra/oracle/common/rman/$HOSTNAME
         cp /opt/oracle/diag/bkp/rman/log/rman_restore_pitr.preview.3.sh.log /fslink/sysinfra/oracle/common/rman/$HOSTNAME/rman_restore_pitr.preview.3.sh.log.$ORACLE_SID.1.$$
         cat /opt/oracle/diag/bkp/rman/log/rman_cf_scn.sh.log.for_preview >> /fslink/sysinfra/oracle/common/rman/$HOSTNAME/rman_restore_pitr.preview.3.sh.log.$ORACLE_SID.1.$$
      fi
   done
} > /tmp/vdc_prev.log 2>&1 
