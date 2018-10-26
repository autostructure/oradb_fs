echo "FS615 RMAN RPM: Before removal"
pids=$(ps -ef | grep [r]man | awk '{print $2}')
[[ -n "$pid" ]] && kill $pids
sleep 3; ps -ef | grep [r]man | wc -l
cp -rp /home/oracle/system/rman/* /tmp/rcat_12.2.0/
cd /tmp/rcat_12.2.0
set -x
ls -l rcat_12.2.0.sh
su oracle -c "./rcat_12.2.0.sh -b" || exit $?
[[ -z $RM_RPM_SW_DIR  ]] && rm -rf /home/oracle/system/rman
[[ -z $RM_RPM_LOG_DIR ]] && rm -rf  /var/tmp/rman 
#rm -rf /tmp/rcat_12.2.0   NOTE:  /bin/rpm -e   will remove this
