#!/bin/bash
###############################################################
# This script is to modify the sqlnet.ora and comment out
# the sqlnet.authentication_services line. The filesetup was
# originally setup to handle for all the Enterprise User
# settings out of the gate but until the kerberos setup
# is actually complete with the Enterprise Users Manual
# RN this line must be commented out.
###############################################################
oracle_homes=`cat /etc/oratab | grep -v "#" | cat /etc/oratab | grep -v "#" | sed 's/ //g' | awk '{$1=$1}1' | awk 'NF > 0' | awk -F: '{ print $2 }' | sort | uniq`

oracle_homes_arr=$(echo $oracle_homes | tr " " "\n")

for x in $oracle_homes_arr
do
  if [[ -e $x/network/admin/sqlnet.ora ]]; then
    if [[ `cat $x/network/admin/sqlnet.ora | grep -v "#" | grep sqlnet.authentication_services | wc -l` = 1 ]]; then
      cp $x/network/admin/sqlnet.ora $x/network/admin/sqlnet.ora.bu
      cat $x/network/admin/sqlnet.ora | awk '/sqlnet.authentication_services/{gsub (/^/,"#")}1' > $x/network/admin/sqlnet.ora.new
      mv -f $x/network/admin/sqlnet.ora.new $x/network/admin/sqlnet.ora
    fi
  fi
done

