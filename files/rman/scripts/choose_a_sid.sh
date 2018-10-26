#!/bin/ksh
#  @(#)fs615/db/ora/rman/linux/rh/choose_a_sid.sh, ora, build6_1, build6_1a,1.2:10/3/11:10:35:36
#  VERSION:  1.2
#  DATE:  10/3/11:10:35:36
#
# Warning: Do NOT run this from a sub-shell or ORACLE_SID will 
#          disappear with the sub-shell.
#          Do a ". choose_a_sid.sh" instead.
#

# Set the SIDS envar by calling this script
. /home/oracle/system/rman/usfs_local_sids

count=$(echo $SIDS|wc -w|sed 's| *||')
if (( $count > 1 )); then
   echo "********* Please Select an Oracle Database Name *********"
   echo "         (some selections may not be a valid sid)"
   echo
   echo
   echo "List of Databases:"
   sleep 1
   PS3="Please enter a number: "
   # Using "set --" in combination with "$@" will not interpret
   # asterisk.  (Otherwise asterisk decodes to every file in the
   # current directory.
   set ${SIDS}
   select ORACLE_SID in $@
   do
      if [ ${#ORACLE_SID} -eq 0 ]; then
         echo -e "Please enter a number from 1 to $count.\n";
      else
         break;
      fi
   done
   ORACLE_SID=$(echo "$ORACLE_SID"|sed "s|'||g")
else
   eval ORACLE_SID="$SIDS"
fi
