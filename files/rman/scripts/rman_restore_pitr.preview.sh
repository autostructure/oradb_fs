#!/usr/bin/env ksh
#
#  @(#)fs615/db/ora/rman/linux/rh/rman_restore_pitr.preview.sh, ora, build6_1, build6_1a,1.1:9/5/11:15:57:18
#  VERSION:  1.1
#  DATE:  9/5/11:15:57:18
#
#  (C) COPYRIGHT International Business Machines Corp. 2002
#  All Rights Reserved
#  Licensed Materials - Property of IBM
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Purpose:
#    Preview a database point in time recovery

/home/oracle/system/rman/rman_restore_pitr.sh -p "$@"
