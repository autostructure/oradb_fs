#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/cold.sh, ora, build6_1, build6_1a,1.2:10/3/11:10:35:37
#  VERSION:  1.2
#  DATE:  10/3/11:10:35:37
#
#  (C) COPYRIGHT International Business Machines Corp. 2007
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#

db_name=$1
if which srvctl >2 /dev/null; then
   srvctl stop database -d $db_name
   srvctl start database -d $db_name -o mount
else
   echo "shutdown immediate;
         startup mount" | sqlplus / as sysdba
fi

# cold.rmn will leave the DB in the "open" state
$ORACLE_HOME/bin/rman target / \
   nocatalog cmdfile=/home/oracle/system/rman/cold.rmn
if which srvctl >2 /dev/null; then
   srvctl status database -d $db_name
else
   echo 'select status from v$instance;' | sqlplus / as sysdba
fi
