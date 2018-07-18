#! /bin/ksh
#  Script:  trim_logs.sh
#  Purpose:  Trim listener log and alert log Single Instance databases.
#
#  Author:  Jane Reyling
#  Date:  03/24/2016 
#
##########################################
export logs=/home/oracle/dbcheck/logs

#  /opt/oracle/diag/tnslsnr/$(hostname)/listener/trace/listener.log
export TNS_log_dir=/opt/oracle/diag/tnslsnr/$(hostname)/listener/trace
export TNS_log=listener.log

name="Trim log:" #label
trim_listener_log ()
{
if [ -f ${TNS_log_dir}/${TNS_log} ]
   then
      echo ${name}  ${TNS_log_dir}/${TNS_log}
      Line_count_listener=$(wc -l ${TNS_log_dir}/${TNS_log} |awk ' { print $1 }')
      if [ $Line_count_listener -gt 90000 ]
         then
           tail  -90000  ${TNS_log_dir}/${TNS_log} > $logs/listener.tmp
           > ${TNS_log_dir}/${TNS_log}
           cat $logs/listener.tmp >> ${TNS_log_dir}/${TNS_log}
           rm -f $logs/listener.tmp
	   chown oracle:oinstall ${TNS_log_dir}/${TNS_log}
      fi
   else
      echo "${TNS_log_dir}/${TNS_log} does not exist!"
fi
}
trim_listener_log

