#!/usr/bin/env ksh
# File: rpm_before-remove_wrapper.sh
# Version: 1.0
# Purpose: Backout Oracle Auditing RPM if the file exists

file=/home/oracle/system/rman/meta_rpm_before-remove_4real.sh
[[ -f $file ]] && (ksh $file; exit $?)
exit 0
