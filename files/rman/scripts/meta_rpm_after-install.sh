function error_exit
{
  echo "  ERROR $2"
  exit $1
}
echo "RMAN RPM: Hit after install."
[[ -z $SYSpwd_rcat01p ]] && error_exit 1 "SYSpwd_rcat01p not set"
[[ -z $SYSpwd_rcat02p ]] && error_exit 1 "SYSpwd_rcat02p not set"
[[ -z $RMAN_PWD        ]] && error_exit 1 "RMAN_PWD not set"
export SYSpwd_rcat01p
export SYSpwd_rcat02p
export RMAN_PWD
cd /tmp/rcat_12.2.0/ || exit $?
#find . | tr '\n' ' '
chown -R oracle.oinstall .
ls -l ./rcat_12.2.0.sh
su oracle -c "cd /tmp/rcat_12.2.0/; ./rcat_12.2.0.sh -f" || exit $?  # -f forces databases to shutdown
cd /home/oracle/system/rman/
su oracle -c /home/oracle/system/rman/desc_all_catalogs.sh || exit $?
cd /usr/openv/netbackup/bin
./bpclntcmd -clear_host_cache
/etc/init.d/netbackup stop; sleep 5; /etc/init.d/netbackup start
