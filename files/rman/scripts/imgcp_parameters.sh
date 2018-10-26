echo "..imgcp_parameters.sh"
# Separate ORACLE_SIDS by the pipe symbol, for example:  export SID_EXCLUDE_LIST="idb1|ddb1|rdb1"
export IMG_SID_EXCLUDE_LIST=

export TMP=/tmp/imgcp/
mkdir $TMP 2> /dev/null
chown oracle:dba $TMP
chmod 700 $TMP
if [[ $? != 0 ]]; then echo "ERROR: chmod 700 $TMP"; exit 1; fi

if [[ -z $LOG ]]; then
   export LOG=/var/tmp/${0##*/}.log.$(date "+%Y-%m-%d:%H:%M:%S")
fi
touch $LOG
chown oracle:dba $LOG
chmod 700 $LOG

export FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && export FS615_ORATAB=/var/opt/oracle/oratab

export DB_NAME=$ORACLE_SID
if grep -q '^+ASM[0-9]' $FS615_ORATAB; then # Set the DB_NAME for RAC
   export DB_NAME=${ORACLE_SID%[0-9]}
fi

export DOMAIN=$( host $(hostname) | sed 's|[^\.]*\.||;s|\..*||')
export OLSNODES=$(find $(find /opt/grid -maxdepth 4 -type d -name bin 2> /dev/null) -name olsnodes 2> /dev/null | head -1)
export CEMUTLO=$(find $(find /opt/grid -maxdepth 4 -type d -name bin 2> /dev/null) -name cemutlo 2> /dev/null | head -1)

export HOSTNAME=$(hostname)

export SYSINFRA=/fslink/sysinfra

echo "DB_NAME=$DB_NAME" | tee -a $LOG
echo "DOMAIN=$DOMAIN" 2>&1 | tee -a $LOG
echo "FS615_ORATAB=$FS615_ORATAB" 2>&1 | tee -a $LOG
echo "OLSNODES=$OLSNODES" >> $LOG
echo "CEMUTLO=$CEMUTLO" >> $LOG
echo "DOMAIN=$DOMAIN" 2>&1 | tee -a $LOG
echo "HOSTNAME=$HOSTNAME" 2>&1 | tee -a $LOG
echo "SHELL=$SHELL" >> $LOG
echo "SHELL_dollar_dollar=$(ps $$)" >> $LOG
echo "SHELL_ps_ef=$(ps -ef | grep "$ID  *$$" )" >> $LOG
echo "SYSINFRA=$SYSINFRA" >> $LOG
