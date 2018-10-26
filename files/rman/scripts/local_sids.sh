#!/usr/bin/env ksh
# 
#  @(#)fs615/db/ora/rman/linux/rh/local_sids.sh, ora, build6_1, build6_1a,1.2:10/3/11:10:35:38
#  VERSION:  1.2
#  DATE:  10/3/11:10:35:38
#
# Purpose:  List instance names on local host.
#
# Attention: Test any changes in bash, pdksh, and ksh93.
#
# Requires:
# Results:
#    SIDS envar
# 

# Check for local host being a RAC server
TAB=$(echo -e "\t")
ps $$ | grep -q bash && set +H # turn off shell history subsititution for exclaimation point !
FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && FS615_ORATAB=/var/opt/oracle/oratab

INSTNBR=$( ps -ef | sed "/asm_pmon_+AS[M]/!d;s|.*asm_pmon_+AS[M]||" )
if [[ -z $INSTNBR ]]; then
   INSTNBR=$( sed "/^[ $TAB]*#/d; /^+ASM[0-9]:/!d; s|+ASM\([0-9]*\):.*|\1|" $FS615_ORATAB )
fi
if [[ -n $INSTNBR ]]; then
   # RAC case
   # It is an error if a dbname ends with a numberal in oratab
   if egrep -v "^[ $TAB]*#|\+ASM|MGMTDB" $FS615_ORATAB | grep '^[^:]*[0-9]:'; then
      echo "Error: found a db_name that ended with a numeral in $FS615_ORATAB"
      exit 1
   fi
   SIDS=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+:[nN]|ASM|\*|MGMTDB" | cut -f1 -d: | \
      sed "s|$|$INSTNBR|")
else
   # Stand-alone case
   SIDS=$(cat $FS615_ORATAB | egrep -v "^[  ]*$|^#|^\+:[nN]|ASM|\*|MGMTDB" | cut -f1 -d:)
fi
# Set $SID_EXCLUDE_LIST
eval $(sed "/^[ $TAB]*#/d; /export  *SID_EXCLUDE_LIST=/!d" rman_parameters.sh)
SIDS=$(echo "$SIDS" | egrep -v "$SID_EXCLUDE_LIST")
export SIDS="$SIDS "
echo "SIDS=$SIDS:"
