#!/bin/ksh
#
#  /fsapps/fsprod/Prod_build_env/oracleRdbms/64bit/11Gdbmaint/SA/upgrade/get_sid.ksh
#
#  VERSION:  1.4
#  DATE:  8/23/12 16:49:16
#
# Purpose:  List instance names on local host.
#
# Attention: Test any changes in pdksh and ksh93
#
# Requires:
#    /etc/oratab
# Results:
#    Found ORACLE_SIDs are echoed to stdout
#
# Suggested client invocation:   SIDS=$(fs_local_sids)
#

############################################################################
#       Process command line options
############################################################################

DBONLY=""

USAGE="
Usage: ${0##*/} [-d]

Returns list of database instances on this server.

-d      return database names only, no instance number suffix
"


while getopts d optc
do
        case $optc in
                d)      DBONLY=true ;;
                *)      echo "$USAGE" >&2
                        exit 1
                        ;;
        esac
done
shift $(( $OPTIND - 1 ))
############################################################################


TAB="   "
# Turn off shell history subsititution for exclamation point
ps h -p $$ | grep -q bash && set +H


if [ "$DBONLY" ]
then
        INSTNBR=""
else
        # Check for local host being a RAC server
        INSTNBR=$( ps -ef | sed "/asm_pmon_+AS[M]/!d;s|.*asm_pmon_+AS[M]||" )
        if [[ -z "$INSTNBR" ]]; then
           INSTNBR=$( sed "/^[ $TAB]*#/d; /^+ASM[0-9]:/!d; s|+ASM\([0-9]*\):.*|\1|" /etc/oratab )
        fi
fi

#
# Output list of SIDs from /etc/oratab, appending instance number
#
cat /etc/oratab |
        grep -E -v "^[${TAB} ]*#|^[${TAB} ]*$|^\+|^ASM|^\*" |
        cut -f1 -d: |
        sed "s|$|$INSTNBR|"

