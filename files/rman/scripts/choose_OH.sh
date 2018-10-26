#!/bin/ksh
#  File: choose_OH.sh
#  VERSION:
#  DATE:  
#
# Warning: Do NOT run this from a sub-shell or ORACLE_HOME will 
#          disappear with the sub-shell.
#          Do a ". choose_OH.sh" instead.
#

FS615_ORATAB=/etc/oratab
[[ $(uname) == "SunOS" ]] && FS615_ORATAB=/var/opt/oracle/oratab

LIST_AGENT=$(sed '/^[# ][# ]*/d;/^[^:][^:]*:[^:][^:]*:[^:]/!d;/MGMTDB/d;/ASM[0-9]*:/d;s|.*:\(.*\):.*|\1|' $FS615_ORATAB | sort -u | grep -i '/[^/]*agent[^/]*$')
#DEBUG echo "LIST_AGENT=$LIST_AGENT"
LIST_AGENT_wc=$(echo "$LIST_AGENT"| wc -l)
#DEBUG echo LIST_AGENT_wc=$LIST_AGENT_wc
LIST_OH=$(sed '/^[# ][# ]*/d;/^[^:][^:]*:[^:][^:]*:[^:]/!d;/MGMTDB/d;/ASM[0-9]*:/d;s|.*:\(.*\):.*|\1|' $FS615_ORATAB | sort -u | grep -vi '/[^/]*agent[^/]*$')
#echo "LIST_OH=$LIST_OH"
LIST_OH_wc=$(echo "$LIST_OH"| wc -l)
#DEBUG echo LIST_OH_wc=$LIST_OH_wc
LISTS=$(sed '/^[# ][# ]*/d;/^[^:][^:]*:[^:][^:]*:[^:]/!d;/MGMTDB/d;/ASM[0-9]*:/d;s|.*:\(.*\):.*|\1|' $FS615_ORATAB | sort -u)

count=$(echo $LISTS | wc -w | sed 's| *||')
if (( $count > 1 )); then
   echo "********* Please Select an Oracle Home Directory *********"
   echo "         (Agent directories are usually not desired)"
   echo
   echo
   echo "List of ORACLE_HOME Directory:"
   sleep 1
   PS3="Please enter a number: "
   # Using "set --" in combination with "$@" will not interpret
   # asterisk.  (Otherwise asterisk decodes to every file in the
   # current directory.
   set $LIST_AGENT $LIST_OH
   select ORACLE_HOME in $@
   do
      if [[ ${#ORACLE_HOME} -eq 0 ]]; then
         echo -e "Please enter a number from 1 to $count.\n";
      else
         break;
      fi
   done
   ORACLE_HOME=$(echo "$ORACLE_HOME"|sed "s|'||g")
else
   eval ORACLE_HOME="$LISTS"
fi
